#!/usr/bin/env python3
"""Validate, resolve and atomically claim the next step of the active Git branch."""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import tomllib
import uuid
from contextlib import contextmanager
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterator


RECORDS_DIRECTORY = Path("Планирование/следующие-шаги-веток")
CLAIMS_DIRECTORY_NAME = "fum-branch-next-step"
RECENCY_BLOCK_RE = re.compile(
    r"\n?<!-- FUM-MD-RECENCY:BEGIN -->.*?"
    r"<!-- FUM-MD-RECENCY:END -->\s*\Z",
    re.DOTALL,
)
STEP_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,127}$")
ALLOWED_STATUSES = frozenset({"ready", "blocked", "done", "paused"})
REQUIRED_FRONTMATTER_KEYS = frozenset(
    {
        "schema_version",
        "branch_ref",
        "step_id",
        "status",
        "project_path",
    }
)

EXIT_INVALID = 2
EXIT_NOT_READY = 3
EXIT_ALREADY_CLAIMED = 4
EXIT_MISMATCH = 5
LOCK_TIMEOUT_SECONDS = 5.0
LOCK_POLL_SECONDS = 0.05


class ContractError(RuntimeError):
    """Raised when the branch-next-step contract cannot be proven."""


@dataclass(frozen=True)
class StepRecord:
    branch_ref: str
    step_id: str
    status: str
    project_path: str
    record_path: str
    title: str
    task: str
    criteria: tuple[str, ...]

    def payload(self) -> dict[str, object]:
        result = asdict(self)
        result["criteria"] = list(self.criteria)
        return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command",
        choices=("validate", "show", "claim", "claim-status", "release"),
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Корень Git-репозитория. По умолчанию текущий каталог.",
    )
    parser.add_argument(
        "--expected-branch-ref",
        help="Ожидаемый полный ref для повторной проверки перед запуском.",
    )
    parser.add_argument(
        "--expected-step-id",
        help="Ожидаемый идентификатор шага для повторной проверки перед запуском.",
    )
    parser.add_argument(
        "--branch-ref",
        help="Полный ref для диагностики или fenced-восстановления claim.",
    )
    parser.add_argument(
        "--expected-lease-id",
        help="Наблюдённый lease_id, обязательный для release.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Напечатать машинно читаемый JSON.",
    )
    return parser.parse_args()


def validate_command_options(args: argparse.Namespace) -> None:
    option_flags = {
        "expected_branch_ref": "--expected-branch-ref",
        "expected_step_id": "--expected-step-id",
        "branch_ref": "--branch-ref",
        "expected_lease_id": "--expected-lease-id",
    }
    allowed_by_command = {
        "validate": frozenset(),
        "show": frozenset({"expected_branch_ref", "expected_step_id"}),
        "claim": frozenset({"expected_branch_ref", "expected_step_id"}),
        "claim-status": frozenset({"branch_ref"}),
        "release": frozenset({"branch_ref", "expected_lease_id"}),
    }
    invalid = [
        option_flags[name]
        for name in option_flags
        if getattr(args, name) is not None and name not in allowed_by_command[args.command]
    ]
    if invalid:
        raise ContractError(
            f"Команда {args.command} не принимает параметры: {', '.join(invalid)}."
        )


def run_git(repo_root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo_root), *args],
        check=False,
        capture_output=True,
        text=True,
        timeout=20,
    )


def resolve_repo_root(raw_root: Path) -> Path:
    requested = raw_root.resolve()
    result = run_git(requested, "rev-parse", "--show-toplevel")
    if result.returncode != 0:
        raise ContractError("Указанный каталог не является Git-репозиторием.")
    discovered = Path(result.stdout.strip()).resolve()
    if discovered != requested:
        raise ContractError(
            "Для проверки нужен корень Git-репозитория, а не вложенный каталог."
        )
    return discovered


def active_branch_ref(repo_root: Path) -> str:
    result = run_git(repo_root, "symbolic-ref", "--quiet", "HEAD")
    if result.returncode != 0:
        raise ContractError(
            "detached HEAD не задаёт устойчивую активную ветку для следующего шага."
        )
    branch_ref = result.stdout.strip()
    validate_branch_ref(repo_root, branch_ref)
    return branch_ref


def validate_branch_ref(repo_root: Path, branch_ref: str) -> None:
    if "\x00" in branch_ref:
        raise ContractError("branch_ref не может содержать нулевой байт.")
    if not branch_ref.startswith("refs/heads/"):
        raise ContractError(
            f"branch_ref должен начинаться с refs/heads/: {branch_ref!r}."
        )
    result = run_git(repo_root, "check-ref-format", branch_ref)
    if result.returncode != 0:
        raise ContractError(f"Некорректный полный ref Git-ветки: {branch_ref!r}.")


def validate_record_branch_ref(
    repo_root: Path,
    branch_ref: str,
    record_path: str,
) -> None:
    validate_branch_ref(repo_root, branch_ref)
    result = run_git(repo_root, "show-ref", "--verify", "--quiet", branch_ref)
    if result.returncode != 0:
        raise ContractError(
            f"{record_path}: локальная ветка {branch_ref} не существует."
        )


def repository_relative(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError as error:
        raise ContractError(f"Путь выходит за пределы репозитория: {path}.") from error


def validate_project_path(
    repo_root: Path,
    raw_project_path: object,
    record_path: str,
    branch_ref: str,
) -> str:
    if not isinstance(raw_project_path, str) or not raw_project_path:
        raise ContractError(f"{record_path}: project_path должен быть непустой строкой.")
    if "\x00" in raw_project_path:
        raise ContractError(f"{record_path}: project_path содержит нулевой байт.")
    path = Path(raw_project_path)
    if (
        path.is_absolute()
        or ".." in path.parts
        or path.as_posix() != raw_project_path
    ):
        raise ContractError(
            f"{record_path}: project_path должен быть нормализованным "
            "путём внутри репозитория."
        )
    absolute = (repo_root / path).resolve()
    repository_relative(absolute, repo_root)
    if not absolute.is_file():
        raise ContractError(
            f"{record_path}: project_path не существует как файл: "
            f"{raw_project_path}."
        )
    if branch_ref == "refs/heads/master" and raw_project_path != "README.md":
        raise ContractError(
            f"{record_path}: ветка master должна использовать корневой README.md."
        )
    project_prefix = "refs/heads/project/"
    if branch_ref.startswith(project_prefix):
        project_name = branch_ref.removeprefix(project_prefix)
        expected = (Path("Проекты") / project_name / "README.md").as_posix()
        if raw_project_path != expected:
            raise ContractError(
                f"{record_path}: ветка {branch_ref} должна использовать паспорт "
                f"{expected}."
            )
    return raw_project_path


def split_frontmatter(text: str, record_path: str) -> tuple[dict[str, object], str]:
    if not text.startswith("+++\n"):
        raise ContractError(
            f"{record_path}: запись должна начинаться TOML-блоком между +++."
        )
    closing = text.find("\n+++\n", 4)
    if closing < 0:
        raise ContractError(f"{record_path}: не закрыт TOML-блок +++.")
    frontmatter_text = text[4:closing]
    body = text[closing + 5 :]
    try:
        frontmatter = tomllib.loads(frontmatter_text)
    except tomllib.TOMLDecodeError as error:
        raise ContractError(f"{record_path}: некорректный TOML: {error}.") from error
    if not isinstance(frontmatter, dict):
        raise ContractError(f"{record_path}: TOML-блок должен быть таблицей.")
    keys = frozenset(frontmatter)
    missing = REQUIRED_FRONTMATTER_KEYS - keys
    unknown = keys - REQUIRED_FRONTMATTER_KEYS
    if missing:
        raise ContractError(
            f"{record_path}: отсутствуют поля TOML: {', '.join(sorted(missing))}."
        )
    if unknown:
        raise ContractError(
            f"{record_path}: неизвестные поля TOML: {', '.join(sorted(unknown))}."
        )
    return frontmatter, RECENCY_BLOCK_RE.sub("", body).rstrip() + "\n"


def mask_range(characters: list[str], start: int, end: int) -> None:
    for index in range(start, end):
        if characters[index] not in "\r\n":
            characters[index] = " "


def mask_html_comments(raw_line: str, in_comment: bool) -> tuple[str, bool]:
    characters = list(raw_line)
    position = 0
    if in_comment:
        closing = raw_line.find("-->")
        if closing < 0:
            mask_range(characters, 0, len(characters))
            return "".join(characters), True
        end = closing + 3
        mask_range(characters, 0, end)
        position = end
        in_comment = False
    while True:
        opening = raw_line.find("<!--", position)
        if opening < 0:
            break
        closing = raw_line.find("-->", opening + 4)
        if closing < 0:
            mask_range(characters, opening, len(characters))
            in_comment = True
            break
        end = closing + 3
        mask_range(characters, opening, end)
        position = end
    return "".join(characters), in_comment


def markdown_fence_opening(line: str) -> tuple[str, int] | None:
    fence_match = re.fullmatch(r" {0,3}(`{3,}|~{3,})(.*)", line)
    if fence_match is None:
        return None
    marker = fence_match.group(1)
    remainder = fence_match.group(2)
    if marker[0] == "`" and "`" in remainder:
        return None
    return marker[0], len(marker)


def is_markdown_fence_closing(
    line: str,
    fence_character: str,
    fence_length: int,
) -> bool:
    fence_match = re.fullmatch(r" {0,3}(`{3,}|~{3,})(.*)", line)
    if fence_match is None:
        return False
    marker = fence_match.group(1)
    remainder = fence_match.group(2)
    return (
        marker[0] == fence_character
        and len(marker) >= fence_length
        and not remainder.strip()
    )


def reject_hidden_html_comments(body: str, record_path: str) -> None:
    fence_character: str | None = None
    fence_length = 0
    for raw_line in body.splitlines(keepends=True):
        line = raw_line.rstrip("\r\n")
        if fence_character is not None:
            if is_markdown_fence_closing(
                line,
                fence_character,
                fence_length,
            ):
                fence_character = None
                fence_length = 0
            continue

        visible_raw_line, _ = mask_html_comments(raw_line, False)
        if visible_raw_line != raw_line:
            raise ContractError(
                f"{record_path}: HTML-комментарии вне fenced-кода запрещены "
                "в исполняемой записи."
            )
        opening = markdown_fence_opening(line)
        if opening is not None:
            fence_character, fence_length = opening


def mask_hidden_markdown(body: str) -> str:
    masked_lines: list[str] = []
    fence_character: str | None = None
    fence_length = 0
    in_html_comment = False
    for raw_line in body.splitlines(keepends=True):
        line = raw_line.rstrip("\r\n")
        if fence_character is not None:
            if is_markdown_fence_closing(
                line,
                fence_character,
                fence_length,
            ):
                fence_character = None
                fence_length = 0
            hidden_line = list(raw_line)
            mask_range(hidden_line, 0, len(hidden_line))
            masked_lines.append("".join(hidden_line))
            continue

        visible_raw_line, in_html_comment = mask_html_comments(
            raw_line,
            in_html_comment,
        )
        visible_line = visible_raw_line.rstrip("\r\n")

        opening = markdown_fence_opening(visible_line)
        if opening is not None:
            fence_character, fence_length = opening
            hidden_line = list(raw_line)
            mask_range(hidden_line, 0, len(hidden_line))
            masked_lines.append("".join(hidden_line))
            continue
        masked_lines.append(visible_raw_line)
    masked = "".join(masked_lines)
    if len(masked) != len(body):
        raise ContractError("Внутренняя ошибка маскирования Markdown.")
    return masked


def markdown_sections(
    body: str,
    record_path: str,
) -> tuple[str, dict[str, str], dict[str, str]]:
    visible_body = mask_hidden_markdown(body)
    h1_matches = list(re.finditer(r"(?m)^# ([^\n]+)$", visible_body))
    if len(h1_matches) != 1:
        raise ContractError(
            f"{record_path}: запись должна содержать ровно один заголовок первого уровня."
        )
    title = h1_matches[0].group(1).strip()
    if not title:
        raise ContractError(f"{record_path}: заголовок Markdown не может быть пустым.")
    h2_matches = list(re.finditer(r"(?m)^## ([^\n]+)\n", visible_body))
    sections: dict[str, str] = {}
    visible_sections: dict[str, str] = {}
    for index, match in enumerate(h2_matches):
        name = match.group(1).strip()
        if not name:
            raise ContractError(f"{record_path}: заголовок Markdown не может быть пустым.")
        if name in sections:
            raise ContractError(f"{record_path}: раздел {name!r} повторяется.")
        content_start = match.end()
        end = (
            h2_matches[index + 1].start()
            if index + 1 < len(h2_matches)
            else len(body)
        )
        sections[name] = body[content_start:end].strip()
        visible_sections[name] = visible_body[content_start:end].strip()
    return title, sections, visible_sections


def parse_criteria(raw: str, record_path: str) -> tuple[str, ...]:
    criteria: list[str] = []
    for line in raw.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if not stripped.startswith("- ") or len(stripped) <= 2:
            raise ContractError(
                f"{record_path}: каждый критерий завершения должен быть "
                "отдельным пунктом '- ...'."
            )
        criteria.append(stripped[2:].strip())
    if not criteria:
        raise ContractError(
            f"{record_path}: раздел «Критерии завершения» не может быть пустым."
        )
    return tuple(criteria)


def parse_record(path: Path, repo_root: Path) -> StepRecord:
    record_path = repository_relative(path, repo_root)
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise ContractError(f"Не удалось прочитать {record_path}: {error}.") from error
    frontmatter, body = split_frontmatter(text, record_path)

    schema_version = frontmatter["schema_version"]
    if type(schema_version) is not int or schema_version != 1:
        raise ContractError(f"{record_path}: поддерживается только schema_version = 1.")

    branch_ref = frontmatter["branch_ref"]
    if not isinstance(branch_ref, str):
        raise ContractError(f"{record_path}: branch_ref должен быть строкой.")
    validate_record_branch_ref(repo_root, branch_ref, record_path)

    step_id = frontmatter["step_id"]
    if not isinstance(step_id, str) or STEP_ID_RE.fullmatch(step_id) is None:
        raise ContractError(
            f"{record_path}: step_id должен быть устойчивым ASCII-идентификатором "
            "из строчных букв, цифр, '.', '_' и '-'."
        )

    status = frontmatter["status"]
    if not isinstance(status, str) or status not in ALLOWED_STATUSES:
        raise ContractError(
            f"{record_path}: status должен быть одним из "
            f"{', '.join(sorted(ALLOWED_STATUSES))}."
        )

    project_path = validate_project_path(
        repo_root,
        frontmatter["project_path"],
        record_path,
        branch_ref,
    )
    reject_hidden_html_comments(body, record_path)
    title, sections, visible_sections = markdown_sections(body, record_path)
    required_sections = ("Задача", "Критерии завершения", "Источники")
    for section in required_sections:
        if not visible_sections.get(section, "").strip():
            raise ContractError(
                f"{record_path}: обязателен непустой раздел «{section}»."
            )
    task = sections["Задача"].strip()
    criteria = parse_criteria(visible_sections["Критерии завершения"], record_path)
    if not any(
        line.strip().startswith("- ")
        for line in visible_sections["Источники"].splitlines()
    ):
        raise ContractError(
            f"{record_path}: раздел «Источники» должен содержать хотя бы один пункт."
        )

    return StepRecord(
        branch_ref=branch_ref,
        step_id=step_id,
        status=status,
        project_path=project_path,
        record_path=record_path,
        title=title,
        task=task,
        criteria=criteria,
    )


def load_records(repo_root: Path) -> tuple[StepRecord, ...]:
    directory = repo_root / RECORDS_DIRECTORY
    if not directory.is_dir():
        raise ContractError(
            f"Не найден каталог записей: {RECORDS_DIRECTORY.as_posix()}."
        )
    paths = sorted(
        (
            path
            for path in directory.rglob("*.md")
            if path.name.casefold() != "readme.md"
        ),
        key=lambda path: repository_relative(path, repo_root),
    )
    if not paths:
        raise ContractError(
            f"В {RECORDS_DIRECTORY.as_posix()} нет записей следующих шагов."
        )
    records = tuple(parse_record(path, repo_root) for path in paths)
    by_branch: dict[str, list[str]] = {}
    for record in records:
        by_branch.setdefault(record.branch_ref, []).append(record.record_path)
    duplicates = {
        branch_ref: record_paths
        for branch_ref, record_paths in by_branch.items()
        if len(record_paths) > 1
    }
    if duplicates:
        details = "; ".join(
            f"{branch_ref}: {', '.join(record_paths)}"
            for branch_ref, record_paths in sorted(duplicates.items())
        )
        raise ContractError(
            "Для каждой ветки должна существовать ровно одна запись; "
            f"найдены дубликаты: {details}."
        )
    return records


def active_record(
    repo_root: Path,
    records: tuple[StepRecord, ...] | None = None,
) -> StepRecord:
    branch_ref = active_branch_ref(repo_root)
    available_records = records if records is not None else load_records(repo_root)
    matching_records = [
        record for record in available_records if record.branch_ref == branch_ref
    ]
    if len(matching_records) != 1:
        raise ContractError(
            f"Для активной ветки {branch_ref} должна существовать ровно одна "
            f"запись в {RECORDS_DIRECTORY.as_posix()}."
        )
    return matching_records[0]


def assert_expected_identity(
    record: StepRecord,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
) -> None:
    if expected_branch_ref is not None and record.branch_ref != expected_branch_ref:
        raise ContractError(
            "Активная ветка изменилась: ожидалась "
            f"{expected_branch_ref}, обнаружена {record.branch_ref}."
        )
    if expected_step_id is not None and record.step_id != expected_step_id:
        raise ContractError(
            "Следующий шаг изменился: ожидался "
            f"{expected_step_id}, обнаружен {record.step_id}."
        )


def git_common_directory(repo_root: Path) -> Path:
    result = run_git(repo_root, "rev-parse", "--git-common-dir")
    if result.returncode != 0:
        raise ContractError("Не удалось определить общий Git-каталог.")
    raw = Path(result.stdout.strip())
    return (raw if raw.is_absolute() else repo_root / raw).resolve()


def claims_root(repo_root: Path) -> Path:
    root = git_common_directory(repo_root) / CLAIMS_DIRECTORY_NAME
    try:
        root.mkdir(mode=0o700)
    except FileExistsError:
        if root.is_symlink() or not root.is_dir():
            raise ContractError(f"Путь локальных claim не является каталогом: {root}.")
    fsync_directory(root.parent)
    return root


def existing_claims_root(repo_root: Path) -> Path | None:
    root = git_common_directory(repo_root) / CLAIMS_DIRECTORY_NAME
    if not root.exists():
        if root.is_symlink():
            raise ContractError(f"Путь локальных claim повреждён: {root}.")
        return None
    if root.is_symlink() or not root.is_dir():
        raise ContractError(f"Путь локальных claim не является каталогом: {root}.")
    return root


def claim_path(root: Path, branch_ref: str) -> Path:
    digest = hashlib.sha256(branch_ref.encode("utf-8")).hexdigest()
    return root / f"{digest}.json"


@contextmanager
def claim_lock(root: Path) -> Iterator[None]:
    lock_path = root / "claims.lock"
    with lock_path.open("a+", encoding="utf-8") as lock_file:
        deadline = time.monotonic() + LOCK_TIMEOUT_SECONDS
        while True:
            try:
                fcntl.flock(
                    lock_file.fileno(),
                    fcntl.LOCK_EX | fcntl.LOCK_NB,
                )
                break
            except BlockingIOError as error:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise ContractError(
                        "Истёк срок ожидания локальной блокировки claim."
                    ) from error
                time.sleep(min(LOCK_POLL_SECONDS, remaining))
        try:
            yield
        finally:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)


def load_claim(path: Path, expected_branch_ref: str) -> dict[str, object] | None:
    if path.is_symlink():
        raise ContractError(f"Локальный claim не может быть символической ссылкой: {path}.")
    if not path.exists():
        return None
    if not path.is_file():
        raise ContractError(f"Локальный claim не является обычным файлом: {path}.")

    def reject_duplicate_keys(
        pairs: list[tuple[str, object]],
    ) -> dict[str, object]:
        result: dict[str, object] = {}
        for key, value in pairs:
            if key in result:
                raise ContractError(
                    f"Локальный claim содержит повторяющееся поле {key!r}: {path}."
                )
            result[key] = value
        return result

    try:
        payload = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=reject_duplicate_keys,
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ContractError(
            f"Локальный claim повреждён и не может быть автоматически заменён: {path}."
        ) from error
    if not isinstance(payload, dict):
        raise ContractError(f"Локальный claim имеет неверный формат: {path}.")
    expected_keys = frozenset(
        {"schema_version", "branch_ref", "step_id", "lease_id"}
    )
    if (
        frozenset(payload) != expected_keys
        or type(payload.get("schema_version")) is not int
        or payload.get("schema_version") != 1
        or payload.get("branch_ref") != expected_branch_ref
        or not isinstance(payload.get("step_id"), str)
        or STEP_ID_RE.fullmatch(str(payload.get("step_id"))) is None
        or not isinstance(payload.get("lease_id"), str)
    ):
        raise ContractError(f"Локальный claim имеет неверный контракт: {path}.")
    try:
        parsed_lease_id = uuid.UUID(str(payload["lease_id"]))
    except ValueError as error:
        raise ContractError(f"Локальный claim содержит неверный lease_id: {path}.") from error
    if str(parsed_lease_id) != payload["lease_id"]:
        raise ContractError(f"Локальный claim содержит неверный lease_id: {path}.")
    return payload


def atomic_write_json(path: Path, payload: dict[str, object]) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.",
        suffix=".tmp",
        dir=path.parent,
        text=True,
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as temporary_file:
            json.dump(payload, temporary_file, ensure_ascii=False, sort_keys=True)
            temporary_file.write("\n")
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        os.replace(temporary_path, path)
        fsync_directory(path.parent)
    finally:
        temporary_path.unlink(missing_ok=True)


def fsync_directory(directory: Path) -> None:
    flags = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0)
    descriptor = os.open(directory, flags)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def claim_step(
    repo_root: Path,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
) -> tuple[dict[str, object], int]:
    if expected_branch_ref is None or expected_step_id is None:
        raise ContractError(
            "claim требует --expected-branch-ref и --expected-step-id."
        )
    root = claims_root(repo_root)
    with claim_lock(root):
        record = active_record(repo_root)
        assert_expected_identity(record, expected_branch_ref, expected_step_id)
        if record.status != "ready":
            return (
                {"state": "not_ready", **record.payload()},
                EXIT_NOT_READY,
            )
        path = claim_path(root, record.branch_ref)
        existing = load_claim(path, record.branch_ref)
        if existing is not None and existing["step_id"] == record.step_id:
            return (
                {
                    "state": "already_claimed",
                    "branch_ref": record.branch_ref,
                    "step_id": record.step_id,
                    "lease_id": existing["lease_id"],
                },
                EXIT_ALREADY_CLAIMED,
            )
        lease_id = str(uuid.uuid4())
        payload: dict[str, object] = {
            "schema_version": 1,
            "branch_ref": record.branch_ref,
            "step_id": record.step_id,
            "lease_id": lease_id,
        }
        atomic_write_json(path, payload)
        return (
            {
                "state": "claimed",
                "branch_ref": record.branch_ref,
                "step_id": record.step_id,
                "lease_id": lease_id,
                "record_path": record.record_path,
            },
            0,
        )


def selected_claim_branch(
    repo_root: Path,
    requested_branch_ref: str | None,
) -> str:
    if requested_branch_ref is None:
        return active_branch_ref(repo_root)
    validate_branch_ref(repo_root, requested_branch_ref)
    return requested_branch_ref


def claim_status(
    repo_root: Path,
    requested_branch_ref: str | None,
) -> tuple[dict[str, object], int]:
    branch_ref = selected_claim_branch(repo_root, requested_branch_ref)
    root = existing_claims_root(repo_root)
    if root is None:
        return {"state": "unclaimed", "branch_ref": branch_ref}, 0
    existing = load_claim(claim_path(root, branch_ref), branch_ref)
    if existing is None:
        return {"state": "unclaimed", "branch_ref": branch_ref}, 0
    return {**existing, "state": "claimed"}, 0


def release_claim(
    repo_root: Path,
    requested_branch_ref: str | None,
    expected_lease_id: str | None,
) -> tuple[dict[str, object], int]:
    if expected_lease_id is None:
        raise ContractError("release требует --expected-lease-id.")
    try:
        uuid.UUID(expected_lease_id)
    except ValueError as error:
        raise ContractError("--expected-lease-id должен быть UUID.") from error
    branch_ref = selected_claim_branch(repo_root, requested_branch_ref)
    root = existing_claims_root(repo_root)
    if root is None:
        return (
            {
                "state": "mismatch",
                "reason": "missing",
                "branch_ref": branch_ref,
            },
            EXIT_MISMATCH,
        )
    path = claim_path(root, branch_ref)
    with claim_lock(root):
        existing = load_claim(path, branch_ref)
        if existing is None:
            return (
                {
                    "state": "mismatch",
                    "reason": "missing",
                    "branch_ref": branch_ref,
                },
                EXIT_MISMATCH,
            )
        if existing["lease_id"] != expected_lease_id:
            return (
                {
                    "state": "mismatch",
                    "reason": "lease_changed",
                    "branch_ref": branch_ref,
                    "lease_id": existing["lease_id"],
                },
                EXIT_MISMATCH,
            )
        path.unlink()
        fsync_directory(path.parent)
    return (
        {
            "state": "released",
            "branch_ref": branch_ref,
            "step_id": existing["step_id"],
            "lease_id": expected_lease_id,
        },
        0,
    )


def emit(payload: dict[str, object], as_json: bool) -> None:
    if as_json:
        print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
        return
    for key, value in payload.items():
        if isinstance(value, list):
            print(f"{key}:")
            for item in value:
                print(f"- {item}")
        else:
            print(f"{key}: {value}")


def main() -> int:
    args = parse_args()
    try:
        validate_command_options(args)
        repo_root = resolve_repo_root(args.repo_root)
        if args.command == "validate":
            records = load_records(repo_root)
            current = active_record(repo_root, records)
            payload = {
                "state": "valid",
                "active_branch_ref": current.branch_ref,
                "active_step_id": current.step_id,
                "active_status": current.status,
                "record_count": len(records),
            }
            exit_code = 0
        elif args.command == "show":
            record = active_record(repo_root)
            assert_expected_identity(
                record,
                args.expected_branch_ref,
                args.expected_step_id,
            )
            if record.status == "ready":
                payload = {"state": "ready", **record.payload()}
                exit_code = 0
            else:
                payload = {"state": "not_ready", **record.payload()}
                exit_code = EXIT_NOT_READY
        elif args.command == "claim":
            payload, exit_code = claim_step(
                repo_root,
                args.expected_branch_ref,
                args.expected_step_id,
            )
        elif args.command == "claim-status":
            payload, exit_code = claim_status(repo_root, args.branch_ref)
        else:
            payload, exit_code = release_claim(
                repo_root,
                args.branch_ref,
                args.expected_lease_id,
            )
    except (ContractError, OSError, ValueError, subprocess.SubprocessError) as error:
        payload = {"state": "invalid", "error": str(error)}
        exit_code = EXIT_INVALID
    emit(payload, args.json)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
