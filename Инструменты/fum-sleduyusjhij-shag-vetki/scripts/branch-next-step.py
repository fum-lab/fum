#!/usr/bin/env python3
"""Validate, resolve and atomically claim the next step of the active Git branch."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import subprocess
import sys
import tempfile
import time
import tomllib
import unicodedata
import uuid
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote


RECORDS_DIRECTORY = Path("Планирование/следующие-шаги-веток")
CARDS_DIRECTORY = Path("Планирование/карточки-шагов")
CLAIM_REF_NAMESPACE = "refs/fum/worktree-next-step-claims"
QUEUE_REF_NAMESPACE = "refs/fum/worktree-task-queues"
ПРОСТРАНСТВО_ГРАНИЦ_ПРОСТОГО_СБРОСА = "refs/fum/границы-простого-сброса"
ПРОСТРАНСТВО_ОБЩИХ_РЕЗЕРВАЦИЙ = (
    "refs/fum/резервации-запусков-автоматизаций"
)
СХЕМА_ГРАНИЦЫ_ПРОСТОГО_СБРОСА = "fum.граница-простого-сброса.1"
ИДЕНТИФИКАТОР_ОБЩЕГО_ЗАДАНИЯ = "master.next-step"
ССЫЛКА_ВЕТКИ_ОБЩЕГО_ЗАДАНИЯ = "refs/heads/master"
СХЕМЫ_ЗАПИСИ_СБРОСА_ОЧЕРЕДИ = frozenset(
    {
        "fum.сброс-состояния-FIFO.1",
        "fum.простой-сброс-состояния-FIFO.1",
    }
)
ПОЛЯ_ГРАНИЦЫ_ПРОСТОГО_СБРОСА = frozenset(
    {
        "схема",
        "идентичность_рабочей_копии",
        "ссылка_ветки",
        "целевая_вершина",
        "идентификатор_сброса",
        "создано",
    }
)
ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_2 = frozenset(
    {
        "версия_схемы",
        "branch_ref",
        "selection_head",
        "идентификатор_реестра",
        "версия_схемы_реестра",
        "поколение_реестра",
        "хэш_реестра",
        "job_id",
        "spec_generation",
        "trigger_occurrence",
        "run_key",
        "идентификатор_попытки",
        "фаза",
        "исход",
        "идентификатор_созданной_задачи",
        "подтверждение_результата",
        "курсор_до",
        "task_id",
        "generation",
    }
)
ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_3 = ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_2 | {
    "свидетельство_среды"
}
ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_4 = ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_3 | {
    "возобновление"
}
ШАБЛОН_МОМЕНТА = re.compile(
    r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z$"
)
RECENCY_BLOCK_RE = re.compile(
    r"\n?<!-- FUM-MD-RECENCY:BEGIN -->.*?"
    r"<!-- FUM-MD-RECENCY:END -->\s*\Z",
    re.DOTALL,
)
STEP_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,127}$")
VERSIONED_STEP_ID_RE = re.compile(
    r"^(?P<stem>[a-z0-9][a-z0-9._-]*?)-v(?P<version>[1-9][0-9]*)$"
)
CARD_ID_RE = re.compile(r"^FUM-STEP-[0-9]{4}$")
CONTENT_SHA256_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
OBJECT_ID_RE = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
SELECTION_POLICY = "dynamic-readiness-source-history-first-parent-v2"
SELECTION_HISTORY_LIMIT = 16
MARKDOWN_LINK_RE = re.compile(
    r"(?<!!)\[[^\]\n]*\]\((?P<target><[^>\n]+>|[^)\n]+)\)"
)
URI_SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
SELECTOR_STATES = frozenset({"open", "done"})
CANDIDATE_DISPATCH_MODES = frozenset({"automatic", "blocked", "paused"})
CARD_STATUSES = frozenset({"active", "completed", "absorbed", "withdrawn"})
CARD_STATUS_EMOJIS = {
    "active": "🟡",
    "completed": "✅",
    "absorbed": "🧩",
    "withdrawn": "🗑️",
}
CARD_FILENAME_BODY_RE = re.compile(
    r"^(?P<card_id>FUM-STEP-[0-9]{4})(?:-(?P<description>.*))?$"
)
MAX_CARD_FILENAME_UTF8_BYTES = 255
CARD_FRONTMATTER_KEYS = frozenset({"schema_version", "card_id", "status"})
SELECTOR_FRONTMATTER_KEYS = frozenset(
    {
        "schema_version",
        "branch_ref",
        "state",
        "project_path",
        "candidates",
    }
)
CANDIDATE_FRONTMATTER_KEYS = frozenset(
    {
        "step_id",
        "dispatch",
        "card_id",
        "card_content_sha256",
        "requires_completed_card_ids",
    }
)
CANDIDATE_RESUME_FRONTMATTER_KEYS = frozenset({"resume_condition"})

EXIT_INVALID = 2
EXIT_NOT_READY = 3
EXIT_ALREADY_CLAIMED = 4
EXIT_MISMATCH = 5
MAX_CAS_ATTEMPTS = 200
UNCHANGED_REF_RETRY_ATTEMPTS = 8
REF_RETRY_BASE_SECONDS = 0.005
REF_RETRY_MAX_SECONDS = 0.1
GIT_COMMAND_TIMEOUT_SECONDS = 20.0
NON_FILE_URI_RE = re.compile(
    r"(?i)(?<![\w+.-])"
    r"(?P<scheme>[a-z][a-z0-9+.-]{1,})://\S+"
)
HOME_VARIABLE_NAME_PATTERN = (
    r"(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH|[A-Z][A-Z0-9_]*_HOME)"
)
FORBIDDEN_CHILD_PATH_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    (
        "file_uri",
        re.compile(r"(?i)(?<![\w+.-])file://"),
    ),
    (
        "windows_drive",
        re.compile(r"(?i)(?<![\w./\\:+-])[a-z]:[\\/]"),
    ),
    (
        "windows_unc",
        re.compile(r"(?<![\w:/\\])(?:\\\\|//)[^\\/\s]+[\\/]"),
    ),
    (
        "home_variable",
        re.compile(
            rf"(?ix)(?:"
            rf"\$(?:{HOME_VARIABLE_NAME_PATTERN})(?![A-Z0-9_])"
            rf"|\$\{{(?:{HOME_VARIABLE_NAME_PATTERN})(?::-[^}}]*)?\}}"
            rf"|\$env:(?:{HOME_VARIABLE_NAME_PATTERN})(?![A-Z0-9_])"
            rf"|%(?:{HOME_VARIABLE_NAME_PATTERN})%"
            rf"|\$\((?:{HOME_VARIABLE_NAME_PATTERN})\)"
            rf")"
        ),
    ),
    (
        "home_expansion",
        re.compile(
            r"(?<![\w./\\~-])"
            r"~(?:[A-Za-z0-9._-]+)?(?=$|[\\/])"
        ),
    ),
    (
        "posix_absolute",
        re.compile(r"(?<![\w.:/\\~])/(?!/)"),
    ),
)


class ContractError(RuntimeError):
    """Raised when the branch-next-step contract cannot be proven."""


class НесовпадениеОбщейРезервации(RuntimeError):
    """После сброса нет точной общей резервации запуска."""


def non_file_uri_spans(value: str) -> tuple[tuple[int, int], ...]:
    return tuple(
        (match.start(), match.end())
        for match in NON_FILE_URI_RE.finditer(value)
        if match.group("scheme").casefold() != "file"
    )


def find_forbidden_local_path(value: str) -> str | None:
    uri_spans = non_file_uri_spans(value)
    findings: list[tuple[int, int, str]] = []
    for category_order, (category, pattern) in enumerate(
        FORBIDDEN_CHILD_PATH_PATTERNS
    ):
        for match in pattern.finditer(value):
            if any(
                start <= match.start() < end
                for start, end in uri_spans
            ):
                continue
            findings.append((match.start(), category_order, category))
    if not findings:
        return None
    return min(findings)[2]


def child_prompt_text_values(
    value: object,
    field_path: str = "payload",
) -> tuple[tuple[str, str], ...]:
    if isinstance(value, str):
        return ((field_path, value),)
    if isinstance(value, dict):
        values: list[tuple[str, str]] = []
        for key in sorted(value, key=str):
            values.extend(
                child_prompt_text_values(
                    value[key],
                    f"{field_path}.{key}",
                )
            )
        return tuple(values)
    if isinstance(value, (list, tuple)):
        values = []
        for index, item in enumerate(value):
            values.extend(
                child_prompt_text_values(
                    item,
                    f"{field_path}[{index}]",
                )
            )
        return tuple(values)
    return ()


def validate_child_prompt_payload(payload: dict[str, object]) -> None:
    for field_path, value in child_prompt_text_values(payload):
        category = find_forbidden_local_path(value)
        if category is None:
            continue
        raise ContractError(
            "Динамическое поле дочернего prompt "
            f"{field_path} содержит запрещённую форму "
            f"локального пути ({category})."
        )


@dataclass(frozen=True)
class StepCard:
    card_id: str
    status: str
    card_path: str
    card_content_sha256: str
    title: str
    task: str
    criteria: tuple[str, ...]
    source_paths: tuple[str, ...]


@dataclass(frozen=True)
class CandidateSelection:
    step_id: str
    dispatch: str
    card_id: str
    card_content_sha256: str
    requires_completed_card_ids: tuple[str, ...]
    resume_condition: str | None = None


@dataclass(frozen=True)
class BranchSelection:
    branch_ref: str
    state: str
    project_path: str
    record_path: str
    record_content_sha256: str
    candidates: tuple[CandidateSelection, ...]


@dataclass(frozen=True)
class StepRecord:
    branch_ref: str
    step_id: str
    status: str
    dispatch: str
    project_path: str
    record_path: str
    card_id: str | None = None
    card_path: str | None = None
    card_content_sha256: str | None = None
    title: str | None = None
    task: str | None = None
    criteria: tuple[str, ...] = ()
    source_paths: tuple[str, ...] = ()
    completed_source_paths: tuple[str, ...] = ()
    requires_completed_card_ids: tuple[str, ...] = ()
    unmet_required_card_ids: tuple[str, ...] = ()
    readiness_facts: tuple[tuple[str, str, str, str], ...] = ()
    resume_condition: str | None = None

    def payload(self) -> dict[str, object]:
        result = {
            "branch_ref": self.branch_ref,
            "step_id": self.step_id,
            "status": self.status,
            "dispatch": self.dispatch,
            "project_path": self.project_path,
            "record_path": self.record_path,
            "requires_completed_card_ids": list(
                self.requires_completed_card_ids
            ),
            "unmet_required_card_ids": list(self.unmet_required_card_ids),
        }
        if self.card_id is not None:
            result.update(
                {
                    "card_id": self.card_id,
                    "card_path": self.card_path,
                    "card_content_sha256": self.card_content_sha256,
                    "title": self.title,
                    "task": self.task,
                    "criteria": list(self.criteria),
                }
            )
        if self.resume_condition is not None:
            result["resume_condition"] = self.resume_condition
        return result


@dataclass(frozen=True)
class BranchRecord:
    branch_ref: str
    state: str
    project_path: str
    record_path: str
    record_content_sha256: str
    candidates: tuple[StepRecord, ...]

    def ready_candidates(self) -> tuple[StepRecord, ...]:
        return tuple(
            candidate for candidate in self.candidates
            if candidate.status == "ready"
        )

    def summary_payload(self) -> dict[str, object]:
        return {
            "branch_ref": self.branch_ref,
            "selector_state": self.state,
            "project_path": self.project_path,
            "record_path": self.record_path,
            "candidate_count": len(self.candidates),
            "candidates": [
                candidate.payload() for candidate in self.candidates
            ],
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument(
        "command",
        choices=(
            "validate",
            "refresh-card-fences",
            "show",
            "claim",
            "bind-run",
            "verify-run",
            "rearm",
            "claim-status",
            "release",
        ),
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
        "--expected-selection-id",
        help="Ожидаемая детерминированная идентичность выбора.",
    )
    parser.add_argument(
        "--branch-ref",
        help="Полный ref для диагностики или fenced-восстановления claim.",
    )
    parser.add_argument(
        "--expected-lease-id",
        help="Ожидаемый lease_id для bind-run, verify-run, rearm или release.",
    )
    parser.add_argument(
        "--lease-id",
        help=(
            "Заранее созданный UUID логической попытки, обязательный для "
            "идемпотентного claim."
        ),
    )
    parser.add_argument(
        "--task-id",
        help="Точный корневой CODEX_THREAD_ID созданной задачи.",
    )
    parser.add_argument(
        "--generation",
        help="Точное поколение текущего FIFO-владельца.",
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
        "expected_selection_id": "--expected-selection-id",
        "branch_ref": "--branch-ref",
        "expected_lease_id": "--expected-lease-id",
        "lease_id": "--lease-id",
        "task_id": "--task-id",
        "generation": "--generation",
    }
    allowed_by_command = {
        "validate": frozenset(),
        "refresh-card-fences": frozenset(),
        "show": frozenset(
            {
                "expected_branch_ref",
                "expected_step_id",
                "expected_selection_id",
            }
        ),
        "claim": frozenset(
            {
                "expected_branch_ref",
                "expected_step_id",
                "expected_selection_id",
                "lease_id",
            }
        ),
        "bind-run": frozenset(
            {
                "expected_branch_ref",
                "expected_step_id",
                "expected_selection_id",
                "expected_lease_id",
                "task_id",
            }
        ),
        "verify-run": frozenset(
            {
                "expected_branch_ref",
                "expected_step_id",
                "expected_selection_id",
                "expected_lease_id",
                "task_id",
                "generation",
            }
        ),
        "rearm": frozenset(
            {
                "expected_branch_ref",
                "expected_step_id",
                "expected_selection_id",
                "expected_lease_id",
                "task_id",
                "generation",
            }
        ),
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


def clean_git_environment() -> dict[str, str]:
    environment = {
        key: value
        for key, value in os.environ.items()
        if not key.upper().startswith("GIT_")
    }
    environment["GIT_NO_REPLACE_OBJECTS"] = "1"
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    return environment


def run_git(
    repo_root: Path,
    *args: str,
    input_text: str | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "--no-replace-objects", "-C", str(repo_root), *args],
        check=False,
        capture_output=True,
        encoding="utf-8",
        errors="strict",
        env=clean_git_environment(),
        input=input_text,
        timeout=GIT_COMMAND_TIMEOUT_SECONDS,
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
    forbidden_category = find_forbidden_local_path(raw_project_path)
    if forbidden_category is not None:
        raise ContractError(
            f"{record_path}: project_path содержит запрещённую "
            "форму локального пути "
            f"({forbidden_category})."
        )
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


def content_without_recency(text: str) -> str:
    return RECENCY_BLOCK_RE.sub("", text).rstrip() + "\n"


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
    return frontmatter, body.rstrip() + "\n"


def validate_exact_frontmatter_keys(
    frontmatter: dict[str, object],
    expected_keys: frozenset[str],
    record_path: str,
) -> None:
    keys = frozenset(frontmatter)
    missing = expected_keys - keys
    unknown = keys - expected_keys
    if missing:
        raise ContractError(
            f"{record_path}: отсутствуют поля TOML: {', '.join(sorted(missing))}."
        )
    if unknown:
        raise ContractError(
            f"{record_path}: неизвестные поля TOML: {', '.join(sorted(unknown))}."
        )


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


def validate_required_sections(
    visible_sections: dict[str, str],
    required_sections: tuple[str, ...],
    record_path: str,
) -> None:
    for section in required_sections:
        if not visible_sections.get(section, "").strip():
            raise ContractError(
                f"{record_path}: обязателен непустой раздел «{section}»."
            )


def validate_sources(visible_sources: str, record_path: str) -> None:
    if not any(
        line.strip().startswith("- ")
        for line in visible_sources.splitlines()
    ):
        raise ContractError(
            f"{record_path}: раздел «Источники» должен содержать "
            "хотя бы один пункт."
        )


def exact_case_path(repo_root: Path, relative_path: str) -> bool:
    current = repo_root
    for part in Path(relative_path).parts:
        try:
            names = {entry.name for entry in current.iterdir()}
        except OSError:
            return False
        if part not in names:
            return False
        current /= part
    return True


def excluded_context_path(path: str, own_card_path: str) -> bool:
    return (
        path == own_card_path
        or path == "README.md"
        or path == "Планирование/README.md"
        or path == "Планирование/карточки-шагов/README.md"
        or path
        == "Планирование/реестр-требований-вариантов-и-кандидатов.json"
        or path.startswith(".obsidian/")
        or path.startswith("Индексы/")
        or path.startswith(f"{RECORDS_DIRECTORY.as_posix()}/")
    )


def source_link_target(raw_target: str) -> str | None:
    target = raw_target.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1].strip()
    else:
        # Markdown permits an optional quoted title after an unbracketed URL.
        target = re.split(r"\s+[\"']", target, maxsplit=1)[0].strip()
    target = unquote(target)
    if (
        not target
        or target.startswith("#")
        or target.startswith("//")
        or URI_SCHEME_RE.match(target) is not None
        or "\x00" in target
        or "\\" in target
    ):
        return None
    return target.split("#", 1)[0].split("?", 1)[0]


def parse_source_paths(
    visible_sources: str,
    card_path: str,
    repo_root: Path,
) -> tuple[str, ...]:
    paths: set[str] = set()
    card_directory = (repo_root / card_path).parent
    for match in MARKDOWN_LINK_RE.finditer(visible_sources):
        target = source_link_target(match.group("target"))
        if not target:
            continue
        raw_path = Path(target)
        if raw_path.is_absolute():
            continue
        absolute = (card_directory / raw_path).resolve()
        try:
            relative = repository_relative(absolute, repo_root)
        except ContractError:
            continue
        if not exact_case_path(repo_root, relative):
            raise ContractError(
                f"{card_path}: локальная Markdown-ссылка в разделе "
                "«Источники» не указывает на существующий файл "
                "с точным регистром пути."
            )
        if not absolute.is_file():
            raise ContractError(
                f"{card_path}: локальная Markdown-ссылка в разделе "
                "«Источники» должна указывать на файл."
            )
        if not excluded_context_path(relative, card_path):
            paths.add(relative)
    return tuple(sorted(paths))


def validate_card_filename(
    filename: str,
    card_id: str,
    status: str,
    record_path: str,
) -> None:
    filename_bytes = len(filename.encode("utf-8"))
    if filename_bytes > MAX_CARD_FILENAME_UTF8_BYTES:
        raise ContractError(
            f"{record_path}: имя файла карточки занимает {filename_bytes} "
            f"UTF-8 байт при максимуме {MAX_CARD_FILENAME_UTF8_BYTES}."
        )

    filename_status = next(
        (
            candidate_status
            for candidate_status, emoji in CARD_STATUS_EMOJIS.items()
            if filename.startswith(f"{emoji}-")
        ),
        None,
    )
    if filename_status is None:
        allowed_emojis = ", ".join(CARD_STATUS_EMOJIS.values())
        raise ContractError(
            f"{record_path}: имя файла карточки должно начинаться с эмодзи "
            f"статуса ({allowed_emojis}) и '-'."
        )

    filename_emoji = CARD_STATUS_EMOJIS[filename_status]
    filename_body = filename.removeprefix(f"{filename_emoji}-")
    if not filename_body.endswith(".md"):
        raise ContractError(
            f"{record_path}: имя файла карточки должно иметь расширение .md."
        )
    filename_stem = filename_body.removesuffix(".md")
    match = CARD_FILENAME_BODY_RE.fullmatch(filename_stem)
    if match is None:
        raise ContractError(
            f"{record_path}: имя файла карточки должно иметь вид "
            "<эмодзи>-FUM-STEP-NNNN-<краткое-название>.md."
        )

    filename_card_id = match.group("card_id")
    description = match.group("description")
    if not description:
        raise ContractError(
            f"{record_path}: имя файла карточки должно содержать непустое "
            "краткое название после FUM-STEP-NNNN-."
        )
    if filename_card_id != card_id:
        raise ContractError(
            f"{record_path}: card_id имени {filename_card_id} не совпадает "
            f"с card_id TOML {card_id}."
        )
    expected_emoji = CARD_STATUS_EMOJIS[status]
    if filename_emoji != expected_emoji:
        raise ContractError(
            f"{record_path}: эмодзи {filename_emoji} не соответствует "
            f"status={status}; ожидается {expected_emoji}."
        )

    normalized_description = unicodedata.normalize("NFC", description)
    description_parts = normalized_description.split("-")
    if any(
        not part
        or any(
            unicodedata.category(character)[0] not in {"L", "N"}
            for character in part
        )
        for part in description_parts
    ):
        raise ContractError(
            f"{record_path}: краткое название должно состоять из "
            "Unicode-букв и цифр, разделённых одиночными '-'."
        )


def parse_card(path: Path, repo_root: Path) -> StepCard:
    card_path = repository_relative(path, repo_root)
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise ContractError(f"Не удалось прочитать {card_path}: {error}.") from error
    canonical_content = content_without_recency(text)
    card_content_sha256 = (
        "sha256:"
        + hashlib.sha256(canonical_content.encode("utf-8")).hexdigest()
    )
    frontmatter, body = split_frontmatter(canonical_content, card_path)
    validate_exact_frontmatter_keys(
        frontmatter,
        CARD_FRONTMATTER_KEYS,
        card_path,
    )

    schema_version = frontmatter["schema_version"]
    if type(schema_version) is not int or schema_version != 1:
        raise ContractError(f"{card_path}: поддерживается только schema_version = 1.")

    card_id = frontmatter["card_id"]
    if not isinstance(card_id, str) or CARD_ID_RE.fullmatch(card_id) is None:
        raise ContractError(
            f"{card_path}: card_id должен иметь вид FUM-STEP-NNNN."
        )

    status = frontmatter["status"]
    if not isinstance(status, str) or status not in CARD_STATUSES:
        raise ContractError(
            f"{card_path}: status карточки должен быть одним из "
            f"{', '.join(sorted(CARD_STATUSES))}."
        )
    validate_card_filename(path.name, card_id, status, card_path)

    reject_hidden_html_comments(body, card_path)
    title, sections, visible_sections = markdown_sections(body, card_path)
    if status == "active":
        required_sections = (
            "Задача",
            "Почему сейчас",
            "Критерии завершения",
            "Источники",
        )
        validate_required_sections(
            visible_sections,
            required_sections,
            card_path,
        )
        criteria = parse_criteria(
            visible_sections["Критерии завершения"],
            card_path,
        )
    else:
        required_sections = ("Задача", "Результат", "Источники")
        validate_required_sections(
            visible_sections,
            required_sections,
            card_path,
        )
        criteria = ()
    validate_sources(visible_sections["Источники"], card_path)

    return StepCard(
        card_id=card_id,
        status=status,
        card_path=card_path,
        card_content_sha256=card_content_sha256,
        title=title,
        task=sections["Задача"].strip(),
        criteria=criteria,
        source_paths=parse_source_paths(
            visible_sections["Источники"],
            card_path,
            repo_root,
        ),
    )


def load_cards(repo_root: Path) -> tuple[StepCard, ...]:
    directory = repo_root / CARDS_DIRECTORY
    if not directory.exists():
        return ()
    if not directory.is_dir():
        raise ContractError(
            f"Путь карточек не является каталогом: {CARDS_DIRECTORY.as_posix()}."
        )
    index_path = directory / "README.md"
    paths = sorted(
        (
            path
            for path in directory.rglob("*")
            if path.suffix.casefold() == ".md" and path != index_path
        ),
        key=lambda path: repository_relative(path, repo_root),
    )
    for path in paths:
        if path.parent != directory:
            card_path = repository_relative(path, repo_root)
            raise ContractError(
                f"Каталог карточек должен быть плоским; "
                f"вложенный Markdown-файл запрещён: {card_path}."
            )
    cards = tuple(parse_card(path, repo_root) for path in paths)
    by_id: dict[str, list[str]] = {}
    for card in cards:
        by_id.setdefault(card.card_id, []).append(card.card_path)
    duplicates = {
        card_id: card_paths
        for card_id, card_paths in by_id.items()
        if len(card_paths) > 1
    }
    if duplicates:
        details = "; ".join(
            f"{card_id}: {', '.join(card_paths)}"
            for card_id, card_paths in sorted(duplicates.items())
        )
        raise ContractError(f"Найдены дубликаты card_id: {details}.")
    return cards


def parse_candidate(
    raw_candidate: object,
    record_path: str,
    index: int,
) -> CandidateSelection:
    candidate_path = f"{record_path}: candidates[{index}]"
    if not isinstance(raw_candidate, dict):
        raise ContractError(
            f"{candidate_path}: кандидат должен быть TOML-таблицей."
        )

    dispatch = raw_candidate.get("dispatch")
    if (
        not isinstance(dispatch, str)
        or dispatch not in CANDIDATE_DISPATCH_MODES
    ):
        raise ContractError(
            f"{candidate_path}: dispatch должен быть одним из "
            f"{', '.join(sorted(CANDIDATE_DISPATCH_MODES))}."
        )
    expected_keys = CANDIDATE_FRONTMATTER_KEYS
    if dispatch in {"paused", "blocked"}:
        expected_keys = expected_keys | CANDIDATE_RESUME_FRONTMATTER_KEYS
    validate_exact_frontmatter_keys(
        raw_candidate,
        expected_keys,
        candidate_path,
    )

    step_id = raw_candidate["step_id"]
    if not isinstance(step_id, str) or STEP_ID_RE.fullmatch(step_id) is None:
        raise ContractError(
            f"{candidate_path}: step_id должен быть устойчивым "
            "ASCII-идентификатором из строчных букв, цифр, '.', '_' и '-'."
        )

    card_id = raw_candidate["card_id"]
    if not isinstance(card_id, str) or CARD_ID_RE.fullmatch(card_id) is None:
        raise ContractError(
            f"{candidate_path}: card_id должен иметь вид FUM-STEP-NNNN."
        )

    card_content_sha256 = raw_candidate["card_content_sha256"]
    if (
        not isinstance(card_content_sha256, str)
        or CONTENT_SHA256_RE.fullmatch(card_content_sha256) is None
    ):
        raise ContractError(
            f"{candidate_path}: card_content_sha256 должен иметь вид "
            "sha256:<64 hex>."
        )

    raw_required_ids = raw_candidate["requires_completed_card_ids"]
    if not isinstance(raw_required_ids, list):
        raise ContractError(
            f"{candidate_path}: requires_completed_card_ids должен быть "
            "массивом card_id."
        )
    required_ids: list[str] = []
    for required_index, required_id in enumerate(raw_required_ids):
        if (
            not isinstance(required_id, str)
            or CARD_ID_RE.fullmatch(required_id) is None
        ):
            raise ContractError(
                f"{candidate_path}: requires_completed_card_ids["
                f"{required_index}] должен иметь вид FUM-STEP-NNNN."
            )
        required_ids.append(required_id)
    duplicate_required_ids = sorted(
        required_id
        for required_id in set(required_ids)
        if required_ids.count(required_id) > 1
    )
    if duplicate_required_ids:
        raise ContractError(
            f"{candidate_path}: requires_completed_card_ids не должен "
            "содержать дубликаты: "
            f"{', '.join(duplicate_required_ids)}."
        )
    if card_id in required_ids:
        raise ContractError(
            f"{candidate_path}: кандидат не может требовать завершения "
            "собственной карточки."
        )

    resume_condition: str | None = None
    if dispatch in {"paused", "blocked"}:
        raw_resume_condition = raw_candidate["resume_condition"]
        if (
            not isinstance(raw_resume_condition, str)
            or not raw_resume_condition.strip()
        ):
            raise ContractError(
                f"{candidate_path}: resume_condition должен быть "
                "непустой строкой для paused/blocked."
            )
        resume_condition = raw_resume_condition.strip()

    return CandidateSelection(
        step_id=step_id,
        dispatch=dispatch,
        card_id=card_id,
        card_content_sha256=card_content_sha256,
        requires_completed_card_ids=tuple(required_ids),
        resume_condition=resume_condition,
    )


def reject_duplicate_candidate_identities(
    candidates: tuple[CandidateSelection, ...],
    record_path: str,
) -> None:
    for field_name in ("card_id", "step_id"):
        by_value: dict[str, int] = {}
        for candidate in candidates:
            value = str(getattr(candidate, field_name))
            by_value[value] = by_value.get(value, 0) + 1
        duplicates = sorted(
            value for value, count in by_value.items() if count > 1
        )
        if duplicates:
            raise ContractError(
                f"{record_path}: значения {field_name} кандидатов должны быть "
                f"уникальны; дубликаты: {', '.join(duplicates)}."
            )


def reject_candidate_dependency_cycles(
    candidates: tuple[CandidateSelection, ...],
    record_path: str,
) -> None:
    candidate_ids = {candidate.card_id for candidate in candidates}
    dependencies = {
        candidate.card_id: tuple(
            required_id
            for required_id in candidate.requires_completed_card_ids
            if required_id in candidate_ids
        )
        for candidate in candidates
    }
    visiting: list[str] = []
    visited: set[str] = set()

    def visit(card_id: str) -> None:
        if card_id in visited:
            return
        if card_id in visiting:
            cycle_start = visiting.index(card_id)
            cycle = visiting[cycle_start:] + [card_id]
            raise ContractError(
                f"{record_path}: цикл requires_completed_card_ids: "
                f"{' -> '.join(cycle)}."
            )
        visiting.append(card_id)
        for required_id in dependencies[card_id]:
            visit(required_id)
        visiting.pop()
        visited.add(card_id)

    for candidate_id in sorted(candidate_ids):
        visit(candidate_id)


def parse_selector(path: Path, repo_root: Path) -> BranchSelection:
    record_path = repository_relative(path, repo_root)
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise ContractError(f"Не удалось прочитать {record_path}: {error}.") from error
    canonical_content = content_without_recency(text)
    record_content_sha256 = (
        "sha256:"
        + hashlib.sha256(canonical_content.encode("utf-8")).hexdigest()
    )
    frontmatter, body = split_frontmatter(canonical_content, record_path)

    schema_version = frontmatter.get("schema_version")
    if type(schema_version) is not int or schema_version != 5:
        raise ContractError(f"{record_path}: поддерживается только schema_version = 5.")
    validate_exact_frontmatter_keys(
        frontmatter,
        SELECTOR_FRONTMATTER_KEYS,
        record_path,
    )

    state = frontmatter["state"]
    if not isinstance(state, str) or state not in SELECTOR_STATES:
        raise ContractError(
            f"{record_path}: state должен быть одним из "
            f"{', '.join(sorted(SELECTOR_STATES))}."
        )

    branch_ref = frontmatter["branch_ref"]
    if not isinstance(branch_ref, str):
        raise ContractError(f"{record_path}: branch_ref должен быть строкой.")
    validate_record_branch_ref(repo_root, branch_ref, record_path)

    raw_candidates = frontmatter["candidates"]
    if not isinstance(raw_candidates, list):
        raise ContractError(
            f"{record_path}: candidates должен быть массивом TOML-таблиц."
        )
    if state == "open" and not raw_candidates:
        raise ContractError(
            f"{record_path}: state=open требует хотя бы одного кандидата."
        )
    if state == "done" and raw_candidates:
        raise ContractError(
            f"{record_path}: state=done требует пустой candidates."
        )
    candidates = tuple(
        parse_candidate(raw_candidate, record_path, index)
        for index, raw_candidate in enumerate(raw_candidates)
    )
    reject_duplicate_candidate_identities(candidates, record_path)
    reject_candidate_dependency_cycles(candidates, record_path)
    project_path = validate_project_path(
        repo_root,
        frontmatter["project_path"],
        record_path,
        branch_ref,
    )
    reject_hidden_html_comments(body, record_path)
    _title, _sections, visible_sections = markdown_sections(body, record_path)
    duplicated = sorted(
        {"Задача", "Критерии завершения"} & set(visible_sections)
    )
    if duplicated:
        raise ContractError(
            f"{record_path}: селектор не должен дублировать разделы "
            f"{', '.join(duplicated)} карточки."
        )

    return BranchSelection(
        branch_ref=branch_ref,
        state=state,
        project_path=project_path,
        record_path=record_path,
        record_content_sha256=record_content_sha256,
        candidates=candidates,
    )


def reject_refresh_symlink(path: Path, repo_root: Path, label: str) -> None:
    try:
        relative = path.absolute().relative_to(repo_root.absolute())
    except ValueError as error:
        raise ContractError(f"{label}: путь выходит за пределы репозитория.") from error
    current = repo_root
    for component in relative.parts:
        current = current / component
        if current.is_symlink():
            raise ContractError(
                f"{label}: символьная ссылка запрещена: "
                f"{relative.as_posix()}."
            )


def structurally_valid_selections(repo_root: Path) -> tuple[BranchSelection, ...]:
    directory = repo_root / RECORDS_DIRECTORY
    reject_refresh_symlink(directory, repo_root, RECORDS_DIRECTORY.as_posix())
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
        key=lambda path: path.relative_to(repo_root).as_posix(),
    )
    if not paths:
        raise ContractError(
            f"В {RECORDS_DIRECTORY.as_posix()} нет записей следующих шагов."
        )
    for path in paths:
        reject_refresh_symlink(path, repo_root, repository_relative(path, repo_root))
    selections = tuple(parse_selector(path, repo_root) for path in paths)
    by_branch: dict[str, list[str]] = {}
    for selection in selections:
        by_branch.setdefault(selection.branch_ref, []).append(selection.record_path)
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
    return selections


def refreshable_candidate_spans(
    text: str,
    selection: BranchSelection,
) -> tuple[dict[str, tuple[int, int]], ...]:
    closing = text.find("\n+++\n", 4)
    if not text.startswith("+++\n") or closing < 0:
        raise ContractError(
            f"{selection.record_path}: не удалось выделить TOML-блок для обновления."
        )
    frontmatter = text[4:closing]
    header_re = re.compile(r"(?m)^[ \t]*\[\[[ \t]*candidates[ \t]*\]\][ \t]*(?:#.*)?$")
    headers = tuple(header_re.finditer(frontmatter))
    if len(headers) != len(selection.candidates):
        raise ContractError(
            f"{selection.record_path}: неоднозначная текстовая структура candidates."
        )
    result: list[dict[str, tuple[int, int]]] = []
    for index, (header, candidate) in enumerate(zip(headers, selection.candidates)):
        block_start = header.end()
        block_end = headers[index + 1].start() if index + 1 < len(headers) else len(frontmatter)
        block = frontmatter[block_start:block_end]
        fields: dict[str, tuple[int, int]] = {}
        for key, expected in (
            ("step_id", candidate.step_id),
            ("card_content_sha256", candidate.card_content_sha256),
        ):
            field_re = re.compile(
                rf"(?m)^[ \t]*{re.escape(key)}[ \t]*=[ \t]*(?P<quote>[\"'])"
                rf"(?P<value>[^\"'\r\n]*)(?P=quote)[ \t]*(?:#.*)?$"
            )
            matches = tuple(field_re.finditer(block))
            if len(matches) != 1 or matches[0].group("value") != expected:
                raise ContractError(
                    f"{selection.record_path}: candidates[{index}].{key} "
                    "должен быть однозначной однострочной ASCII-строкой."
                )
            value_start = 4 + block_start + matches[0].start("value")
            value_end = 4 + block_start + matches[0].end("value")
            fields[key] = (value_start, value_end)
        result.append(fields)
    return tuple(result)


def atomically_replace_selector(
    path: Path,
    original: bytes,
    replacement: bytes,
    repo_root: Path,
) -> None:
    reject_refresh_symlink(path, repo_root, repository_relative(path, repo_root))
    try:
        original_stat = path.stat(follow_symlinks=False)
    except OSError as error:
        raise ContractError(f"Не удалось проверить селектор: {error}.") from error
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=path.parent,
            prefix=f".{path.name}.refresh-",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            temporary.write(replacement)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.chmod(temporary_path, original_stat.st_mode & 0o7777)
        reject_refresh_symlink(path, repo_root, repository_relative(path, repo_root))
        if path.read_bytes() != original:
            raise ContractError(
                "Селектор изменился конкурентно; обновление отменено."
            )
        try:
            os.replace(temporary_path, path)
        except OSError as error:
            raise ContractError(
                f"Атомарная замена селектора не выполнена: {error}."
            ) from error
        temporary_path = None
    finally:
        if temporary_path is not None:
            try:
                temporary_path.unlink()
            except FileNotFoundError:
                pass


def refresh_card_fences(repo_root: Path) -> dict[str, object]:
    branch_ref = active_branch_ref(repo_root)
    selections = structurally_valid_selections(repo_root)
    matching = [item for item in selections if item.branch_ref == branch_ref]
    if len(matching) != 1:
        raise ContractError(
            f"Для активной ветки {branch_ref} должна существовать ровно одна "
            f"запись в {RECORDS_DIRECTORY.as_posix()}."
        )
    selection = matching[0]
    cards_directory = repo_root / CARDS_DIRECTORY
    reject_refresh_symlink(cards_directory, repo_root, CARDS_DIRECTORY.as_posix())
    for path in cards_directory.rglob("*.md"):
        reject_refresh_symlink(path, repo_root, path.relative_to(repo_root).as_posix())
    cards = load_cards(repo_root)
    cards_by_id = {card.card_id: card for card in cards}
    for candidate in selection.candidates:
        version_match = VERSIONED_STEP_ID_RE.fullmatch(candidate.step_id)
        if version_match is None:
            raise ContractError(
                f"{selection.record_path}: step_id {candidate.step_id!r} "
                "должен заканчиваться каноническим -vN, где N > 0."
            )
        card = cards_by_id.get(candidate.card_id)
        if card is None:
            raise ContractError(
                f"{selection.record_path}: не найдена карточка {candidate.card_id}."
            )
        if card.status != "active":
            raise ContractError(
                f"{selection.record_path}: выбрать можно только карточку "
                f"status=active, но {candidate.card_id} имеет status={card.status}."
            )
        reject_refresh_symlink(repo_root / card.card_path, repo_root, card.card_path)
        for required_id in candidate.requires_completed_card_ids:
            if required_id not in cards_by_id:
                raise ContractError(
                    f"{selection.record_path}: для {candidate.card_id} не найдена "
                    f"обязательная карточка {required_id}."
                )

    selector_path = repo_root / selection.record_path
    original = selector_path.read_bytes()
    try:
        text = original.decode("utf-8")
    except UnicodeError as error:
        raise ContractError(f"Не удалось прочитать {selection.record_path}: {error}.") from error
    spans = refreshable_candidate_spans(text, selection)
    occupied_step_ids = {candidate.step_id for candidate in selection.candidates}
    replacements: list[tuple[int, int, str]] = []
    updated_card_ids: list[str] = []
    for candidate, candidate_spans in zip(selection.candidates, spans):
        card = cards_by_id[candidate.card_id]
        if candidate.card_content_sha256 == card.card_content_sha256:
            continue
        match = VERSIONED_STEP_ID_RE.fullmatch(candidate.step_id)
        if match is None:
            raise ContractError("Внутренняя ошибка формата step_id.")
        version = int(match.group("version")) + 1
        while True:
            next_step_id = f"{match.group('stem')}-v{version}"
            if STEP_ID_RE.fullmatch(next_step_id) is None:
                raise ContractError(
                    f"{selection.record_path}: невозможно выпустить корректный step_id для "
                    f"{candidate.card_id}."
                )
            if next_step_id not in occupied_step_ids:
                break
            version += 1
        occupied_step_ids.add(next_step_id)
        replacements.append((*candidate_spans["step_id"], next_step_id))
        replacements.append(
            (*candidate_spans["card_content_sha256"], card.card_content_sha256)
        )
        updated_card_ids.append(candidate.card_id)
    if not replacements:
        return {
            "state": "unchanged",
            "branch_ref": branch_ref,
            "record_path": selection.record_path,
            "updated_count": 0,
            "updated_card_ids": [],
        }
    replacement_text = text
    for start, end, value in sorted(replacements, reverse=True):
        replacement_text = replacement_text[:start] + value + replacement_text[end:]
    atomically_replace_selector(
        selector_path,
        original,
        replacement_text.encode("utf-8"),
        repo_root,
    )
    return {
        "state": "refreshed",
        "branch_ref": branch_ref,
        "record_path": selection.record_path,
        "updated_count": len(updated_card_ids),
        "updated_card_ids": updated_card_ids,
    }


def resolve_selection(
    selection: BranchSelection,
    cards_by_id: dict[str, StepCard],
) -> BranchRecord:
    cards_by_path = {card.card_path: card for card in cards_by_id.values()}
    resolved_candidates: list[StepRecord] = []
    for candidate in selection.candidates:
        card = cards_by_id.get(candidate.card_id)
        if card is None:
            raise ContractError(
                f"{selection.record_path}: не найдена карточка {candidate.card_id}."
            )
        if card.status != "active":
            raise ContractError(
                f"{selection.record_path}: выбрать можно только карточку "
                f"status=active, но {candidate.card_id} имеет status={card.status}."
            )
        if candidate.card_content_sha256 != card.card_content_sha256:
            raise ContractError(
                f"{selection.record_path}: card_content_sha256 карточки "
                f"{candidate.card_id} изменился; ожидался "
                f"{candidate.card_content_sha256}, обнаружен "
                f"{card.card_content_sha256}."
            )
        readiness_facts: list[tuple[str, str, str, str]] = []
        unmet_required_ids: list[str] = []
        for required_id in candidate.requires_completed_card_ids:
            required_card = cards_by_id.get(required_id)
            if required_card is None:
                raise ContractError(
                    f"{selection.record_path}: для {candidate.card_id} не "
                    "найдена обязательная карточка "
                    f"{required_id}."
                )
            readiness_facts.append(
                (
                    required_card.card_id,
                    required_card.status,
                    required_card.card_path,
                    required_card.card_content_sha256,
                )
            )
            if required_card.status != "completed":
                unmet_required_ids.append(required_id)
        if candidate.dispatch == "automatic":
            runtime_status = (
                "ready" if not unmet_required_ids else "paused"
            )
        else:
            runtime_status = candidate.dispatch
        resolved_candidates.append(
            StepRecord(
                branch_ref=selection.branch_ref,
                step_id=candidate.step_id,
                status=runtime_status,
                dispatch=candidate.dispatch,
                project_path=selection.project_path,
                record_path=selection.record_path,
                card_id=card.card_id,
                card_path=card.card_path,
                card_content_sha256=card.card_content_sha256,
                title=card.title,
                task=card.task,
                criteria=card.criteria,
                source_paths=card.source_paths,
                completed_source_paths=tuple(
                    source_path
                    for source_path in card.source_paths
                    if source_path in cards_by_path
                    and cards_by_path[source_path].status
                    in {"completed", "absorbed"}
                ),
                requires_completed_card_ids=(
                    candidate.requires_completed_card_ids
                ),
                unmet_required_card_ids=tuple(unmet_required_ids),
                readiness_facts=tuple(readiness_facts),
                resume_condition=candidate.resume_condition,
            )
        )
    return BranchRecord(
        branch_ref=selection.branch_ref,
        state=selection.state,
        project_path=selection.project_path,
        record_path=selection.record_path,
        record_content_sha256=selection.record_content_sha256,
        candidates=tuple(resolved_candidates),
    )


def load_records(
    repo_root: Path,
    cards: tuple[StepCard, ...] | None = None,
) -> tuple[BranchRecord, ...]:
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
    selections = tuple(parse_selector(path, repo_root) for path in paths)
    by_branch: dict[str, list[str]] = {}
    for selection in selections:
        by_branch.setdefault(selection.branch_ref, []).append(selection.record_path)
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
    available_cards = cards if cards is not None else load_cards(repo_root)
    cards_by_id = {card.card_id: card for card in available_cards}
    return tuple(
        resolve_selection(selection, cards_by_id)
        for selection in selections
    )


def active_record(
    repo_root: Path,
    records: tuple[BranchRecord, ...] | None = None,
) -> BranchRecord:
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


def validate_ready_pool(record: BranchRecord) -> tuple[StepRecord, ...]:
    ready = record.ready_candidates()
    for candidate in ready:
        validate_child_prompt_payload(
            {"state": "ready", **candidate.payload()}
        )
    return ready


def branch_head_oid(repo_root: Path, branch_ref: str) -> str:
    result = checked_git(
        repo_root,
        f"определить вершину {branch_ref}",
        "rev-parse",
        "--verify",
        f"{branch_ref}^{{commit}}",
    )
    oid = result.stdout.strip()
    if not oid:
        raise ContractError(f"Git не вернул вершину {branch_ref}.")
    return oid


def changed_paths_for_commit(
    repo_root: Path,
    commit_oid: str,
    first_parent_oid: str | None,
) -> frozenset[str]:
    if first_parent_oid is None:
        result = checked_git(
            repo_root,
            f"прочитать пути корневого коммита {commit_oid}",
            "diff-tree",
            "--root",
            "--no-commit-id",
            "--name-only",
            "--no-renames",
            "-r",
            "-z",
            commit_oid,
            "--",
        )
    else:
        result = checked_git(
            repo_root,
            f"прочитать first-parent diff коммита {commit_oid}",
            "diff",
            "--name-only",
            "--no-renames",
            "-z",
            first_parent_oid,
            commit_oid,
            "--",
        )
    return frozenset(path for path in result.stdout.split("\x00") if path)


def first_parent_history(
    repo_root: Path,
    head_oid: str,
) -> tuple[tuple[str, int, frozenset[str]], ...]:
    result = checked_git(
        repo_root,
        "прочитать окно first-parent истории",
        "rev-list",
        "--first-parent",
        f"--max-count={SELECTION_HISTORY_LIMIT}",
        "--parents",
        head_oid,
    )
    history: list[tuple[str, int, frozenset[str]]] = []
    for distance, line in enumerate(result.stdout.splitlines()):
        parts = line.split()
        if not parts:
            continue
        commit_oid = parts[0]
        first_parent_oid = parts[1] if len(parts) > 1 else None
        history.append(
            (
                commit_oid,
                distance,
                changed_paths_for_commit(
                    repo_root,
                    commit_oid,
                    first_parent_oid,
                ),
            )
        )
    return tuple(history)


def candidate_evidence(
    candidate: StepRecord,
    history: tuple[tuple[str, int, frozenset[str]], ...],
    *,
    completed_only: bool,
) -> tuple[int, int, str, tuple[str, ...]] | None:
    source_paths = (
        candidate.completed_source_paths
        if completed_only
        else candidate.source_paths
    )
    source_set = frozenset(source_paths)
    if not source_set:
        return None
    for commit_oid, distance, changed_paths in history:
        matched_paths = tuple(sorted(source_set & changed_paths))
        if matched_paths:
            return distance, -len(matched_paths), commit_oid, matched_paths
    return None


def canonical_selection_id(snapshot: dict[str, object]) -> str:
    encoded = json.dumps(
        snapshot,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(encoded).hexdigest()


def select_ready_candidate(
    repo_root: Path,
    record: BranchRecord,
) -> tuple[StepRecord | None, dict[str, object] | None]:
    ready = validate_ready_pool(record)
    if not ready:
        return None, None
    head_oid = branch_head_oid(repo_root, record.branch_ref)
    ordered_ready = tuple(
        sorted(ready, key=lambda item: (str(item.card_id), item.step_id))
    )
    winner = ordered_ready[0]
    reason = "only_ready" if len(ordered_ready) == 1 else "stable_fallback"
    commit_oid: str | None = None
    distance: int | None = None
    matched_paths: tuple[str, ...] = ()

    if len(ordered_ready) > 1:
        history = first_parent_history(repo_root, head_oid)
        ranked: list[
            tuple[
                tuple[int, int, str, str],
                StepRecord,
                tuple[int, int, str, tuple[str, ...]],
            ]
        ] = []
        for completed_only in (True, False):
            ranked.clear()
            for candidate in ordered_ready:
                evidence = candidate_evidence(
                    candidate,
                    history,
                    completed_only=completed_only,
                )
                if evidence is None:
                    continue
                evidence_distance, negative_count, evidence_commit, paths = evidence
                ranked.append(
                    (
                        (
                            evidence_distance,
                            negative_count,
                            str(candidate.card_id),
                            candidate.step_id,
                        ),
                        candidate,
                        evidence,
                    )
                )
            if ranked:
                _rank, winner, evidence = min(ranked, key=lambda item: item[0])
                distance, _negative_count, commit_oid, matched_paths = evidence
                reason = (
                    "completed_step_source"
                    if completed_only
                    else "changed_source"
                )
                break

    selection_without_id: dict[str, object] = {
        "policy": SELECTION_POLICY,
        "head": head_oid,
        "ready_count": len(ordered_ready),
        "reason": reason,
        "commit": commit_oid,
        "distance": distance,
        "matched_paths": list(matched_paths),
    }
    snapshot: dict[str, object] = {
        "policy": SELECTION_POLICY,
        "head": head_oid,
        "selector": {
            "record_path": record.record_path,
            "record_content_sha256": record.record_content_sha256,
        },
        "readiness": [
            {
                "card_id": candidate.card_id,
                "card_path": candidate.card_path,
                "card_content_sha256": candidate.card_content_sha256,
                "step_id": candidate.step_id,
                "dispatch": candidate.dispatch,
                "status": candidate.status,
                "resume_condition": candidate.resume_condition,
                "requires_completed_card_ids": list(
                    candidate.requires_completed_card_ids
                ),
                "unmet_required_card_ids": list(
                    candidate.unmet_required_card_ids
                ),
                "facts": [
                    {
                        "card_id": card_id,
                        "status": status,
                        "card_path": card_path,
                        "card_content_sha256": content_hash,
                    }
                    for card_id, status, card_path, content_hash
                    in candidate.readiness_facts
                ],
            }
            for candidate in sorted(
                record.candidates,
                key=lambda item: (str(item.card_id), item.step_id),
            )
        ],
        "ready": [
            {
                **candidate.payload(),
                "source_paths": list(candidate.source_paths),
                "completed_source_paths": list(
                    candidate.completed_source_paths
                ),
            }
            for candidate in ordered_ready
        ],
        "winner": {
            "card_id": winner.card_id,
            "step_id": winner.step_id,
        },
        "evidence": selection_without_id,
    }
    selection = {
        "id": canonical_selection_id(snapshot),
        **selection_without_id,
    }
    return winner, selection


def assert_expected_identity(
    record: BranchRecord,
    ready_candidate: StepRecord | None,
    selection: dict[str, object] | None,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
    expected_selection_id: str | None,
) -> None:
    if expected_branch_ref is not None and record.branch_ref != expected_branch_ref:
        raise ContractError(
            "Активная ветка изменилась: ожидалась "
            f"{expected_branch_ref}, обнаружена {record.branch_ref}."
        )
    if (
        expected_step_id is not None
        and (
            ready_candidate is None
            or ready_candidate.step_id != expected_step_id
        )
    ):
        discovered = (
            ready_candidate.step_id
            if ready_candidate is not None
            else "готовый шаг отсутствует"
        )
        raise ContractError(
            "Следующий готовый шаг изменился: ожидался "
            f"{expected_step_id}, обнаружен {discovered}."
        )
    if (
        expected_selection_id is not None
        and (
            selection is None
            or selection.get("id") != expected_selection_id
        )
    ):
        discovered_selection = (
            str(selection["id"])
            if selection is not None
            else "выбор отсутствует"
        )
        raise ContractError(
            "Selection изменился: ожидался "
            f"{expected_selection_id}, обнаружен {discovered_selection}."
        )


def checked_git(
    repo_root: Path,
    operation: str,
    *args: str,
    input_text: str | None = None,
) -> subprocess.CompletedProcess[str]:
    result = run_git(repo_root, *args, input_text=input_text)
    if result.returncode != 0:
        detail = result.stderr.strip() or "Git не вернул текст ошибки."
        raise ContractError(f"Не удалось {operation}: {detail}")
    return result


def checkout_identity(repo_root: Path) -> str:
    result = checked_git(
        repo_root,
        "определить Git-каталог физического checkout",
        "rev-parse",
        "--absolute-git-dir",
    )
    git_directory = Path(result.stdout.strip()).resolve()
    normalized = os.path.normcase(str(git_directory))
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def claim_ref(repo_root: Path, branch_ref: str) -> str:
    branch_digest = hashlib.sha256(branch_ref.encode("utf-8")).hexdigest()
    return f"{CLAIM_REF_NAMESPACE}/{checkout_identity(repo_root)}/{branch_digest}"


def queue_ref(repo_root: Path) -> str:
    return f"{QUEUE_REF_NAMESPACE}/{checkout_identity(repo_root)}"


def ensure_unique_branch_checkout(repo_root: Path, branch_ref: str) -> None:
    result = checked_git(
        repo_root,
        "проверить уникальность worktree ветки",
        "worktree",
        "list",
        "--porcelain",
        "-z",
    )
    worktrees: list[Path] = []
    for block in result.stdout.split("\x00\x00"):
        if not block:
            continue
        worktree: Path | None = None
        discovered_branch: str | None = None
        for field in block.split("\x00"):
            if field.startswith("worktree "):
                worktree = Path(field.removeprefix("worktree ")).resolve()
            elif field.startswith("branch "):
                discovered_branch = field.removeprefix("branch ")
        if worktree is not None and discovered_branch == branch_ref:
            worktrees.append(worktree)
    if worktrees != [repo_root.resolve()]:
        raise ContractError(
            "Run-fence требует, чтобы именованная ветка была открыта ровно в одном текущем worktree."
        )


def read_ref_oid(repo_root: Path, reference: str) -> str | None:
    symbolic = run_git(repo_root, "symbolic-ref", "--quiet", reference)
    if symbolic.returncode == 0:
        raise ContractError(
            "Служебная Git-ссылка не может быть символической."
        )
    if symbolic.returncode not in {1}:
        detail = symbolic.stderr.strip() or "Git не вернул текст ошибки."
        raise ContractError(
            f"Не удалось проверить вид служебной Git-ссылки: {detail}"
        )
    result = run_git(repo_root, "rev-parse", "--verify", "--quiet", reference)
    if result.returncode == 1:
        return None
    if result.returncode != 0:
        detail = result.stderr.strip() or "Git не вернул текст ошибки."
        raise ContractError(
            f"Не удалось прочитать служебную Git-ссылку: {detail}"
        )
    oid = result.stdout.strip()
    if not oid:
        raise ContractError("Служебная Git-ссылка не вернула object ID.")
    return oid


def собрать_объект_без_повторов(
    пары: list[tuple[str, object]],
) -> dict[str, object]:
    объект: dict[str, object] = {}
    for ключ, значение in пары:
        if ключ in объект:
            raise ContractError(
                f"Служебный Git blob содержит повторяющееся поле {ключ!r}."
            )
        объект[ключ] = значение
    return объект


def прочитать_канонический_служебный_объект(
    корень: Path,
    ссылка: str,
    объект: str,
    название: str,
) -> dict[str, object]:
    тип = checked_git(
        корень,
        f"проверить тип {название}",
        "cat-file",
        "-t",
        объект,
    ).stdout.strip()
    if тип != "blob":
        raise ContractError(f"{название} не указывает на Git blob.")
    сырой = checked_git(
        корень,
        f"прочитать {название}",
        "cat-file",
        "blob",
        объект,
    ).stdout
    try:
        значение = json.loads(
            сырой,
            object_pairs_hook=собрать_объект_без_повторов,
            parse_constant=reject_nonfinite_queue_number,
        )
    except (UnicodeError, json.JSONDecodeError) as ошибка:
        raise ContractError(f"{название} повреждён.") from ошибка
    if not isinstance(значение, dict):
        raise ContractError(f"{название} имеет неверный формат.")
    канонический = (
        json.dumps(
            значение,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    )
    if сырой != канонический:
        raise ContractError(f"{название} имеет неканонические байты.")
    return значение


def ссылка_границы_простого_сброса(
    корень: Path,
    ссылка_ветки: str,
) -> str:
    хэш_ветки = hashlib.sha256(ссылка_ветки.encode("utf-8")).hexdigest()
    return (
        f"{ПРОСТРАНСТВО_ГРАНИЦ_ПРОСТОГО_СБРОСА}/"
        f"{checkout_identity(корень)}/{хэш_ветки}"
    )


def прочитать_границу_простого_сброса(
    корень: Path,
    ссылка_ветки: str,
) -> str | None:
    ссылка = ссылка_границы_простого_сброса(корень, ссылка_ветки)
    объект = read_ref_oid(корень, ссылка)
    if объект is None:
        return None
    граница = прочитать_канонический_служебный_объект(
        корень,
        ссылка,
        объект,
        "граница простого сброса",
    )
    if (
        frozenset(граница) != ПОЛЯ_ГРАНИЦЫ_ПРОСТОГО_СБРОСА
        or граница.get("схема") != СХЕМА_ГРАНИЦЫ_ПРОСТОГО_СБРОСА
        or граница.get("идентичность_рабочей_копии")
        != checkout_identity(корень)
        or граница.get("ссылка_ветки") != ссылка_ветки
        or OBJECT_ID_RE.fullmatch(str(граница.get("целевая_вершина"))) is None
        or CONTENT_SHA256_RE.fullmatch(
            str(граница.get("идентификатор_сброса"))
        )
        is None
        or ШАБЛОН_МОМЕНТА.fullmatch(str(граница.get("создано"))) is None
    ):
        raise ContractError("Граница простого сброса имеет неверный контракт.")
    return объект


def ссылка_общей_резервации(
    корень: Path,
    ссылка_ветки: str,
) -> str:
    хэш_ветки = hashlib.sha256(ссылка_ветки.encode("utf-8")).hexdigest()
    хэш_задания = hashlib.sha256(
        ИДЕНТИФИКАТОР_ОБЩЕГО_ЗАДАНИЯ.encode("utf-8")
    ).hexdigest()
    return (
        f"{ПРОСТРАНСТВО_ОБЩИХ_РЕЗЕРВАЦИЙ}/"
        f"{checkout_identity(корень)}/{хэш_ветки}/{хэш_задания}"
    )


def потребовать_общую_резервацию(
    корень: Path,
    ссылка_ветки: str,
    вершина_выбора: str,
    идентификатор_аренды: str,
) -> tuple[str, str] | None:
    if ссылка_ветки != ССЫЛКА_ВЕТКИ_ОБЩЕГО_ЗАДАНИЯ:
        return None
    ссылка = ссылка_общей_резервации(корень, ссылка_ветки)
    объект = read_ref_oid(корень, ссылка)
    if объект is None:
        if прочитать_границу_простого_сброса(корень, ссылка_ветки) is None:
            return None
        raise НесовпадениеОбщейРезервации
    резервация = прочитать_канонический_служебный_объект(
        корень,
        ссылка,
        объект,
        "общая резервация",
    )
    версия = резервация.get("версия_схемы")
    ожидаемые_поля = {
        2: ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_2,
        3: ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_3,
        4: ПОЛЯ_ОБЩЕЙ_РЕЗЕРВАЦИИ_4,
    }.get(версия)
    if ожидаемые_поля is None or frozenset(резервация) != ожидаемые_поля:
        raise ContractError("Общая резервация имеет неверный контракт.")
    попытка = резервация.get("идентификатор_попытки")
    try:
        разобранная_попытка = uuid.UUID(str(попытка))
    except ValueError as ошибка:
        raise ContractError(
            "Общая резервация имеет неканонический UUID попытки."
        ) from ошибка
    if str(разобранная_попытка) != попытка:
        raise ContractError(
            "Общая резервация имеет неканонический UUID попытки."
        )
    if (
        резервация.get("branch_ref") != ссылка_ветки
        or резервация.get("selection_head") != вершина_выбора
        or резервация.get("job_id") != ИДЕНТИФИКАТОР_ОБЩЕГО_ЗАДАНИЯ
        or попытка != идентификатор_аренды
        or резервация.get("фаза") != "зарезервирован"
    ):
        raise НесовпадениеОбщейРезервации
    return ссылка, объект


def reject_duplicate_claim_keys(
    pairs: list[tuple[str, object]],
) -> dict[str, object]:
    payload: dict[str, object] = {}
    for key, value in pairs:
        if key in payload:
            raise ContractError(
                f"Git blob claim содержит повторяющееся поле {key!r}."
            )
        payload[key] = value
    return payload


def validate_claim(
    payload: object,
    expected_branch_ref: str,
) -> dict[str, object]:
    if not isinstance(payload, dict):
        raise ContractError("Git blob claim имеет неверный формат.")
    schema_version = payload.get("schema_version")
    if type(schema_version) is not int or schema_version not in {1, 2, 3, 4, 5}:
        raise ContractError("Git blob claim имеет неверный контракт.")
    ожидаемые_ключи = frozenset(
        {"schema_version", "branch_ref", "step_id", "lease_id"}
    )
    if schema_version in {2, 3, 4, 5}:
        ожидаемые_ключи |= {
            "selection_id",
            "selection_head",
        }
    if schema_version in {3, 4}:
        ожидаемые_ключи |= {"task_id"}
    if schema_version == 4:
        ожидаемые_ключи |= {"generation"}
    if schema_version == 5:
        ожидаемые_ключи |= {"card_id", "task_id", "generation"}
    if (
        frozenset(payload) != ожидаемые_ключи
        or payload.get("branch_ref") != expected_branch_ref
        or not isinstance(payload.get("step_id"), str)
        or STEP_ID_RE.fullmatch(str(payload.get("step_id"))) is None
        or not isinstance(payload.get("lease_id"), str)
    ):
        raise ContractError("Git blob claim имеет неверный контракт.")
    if schema_version in {2, 3, 4, 5} and (
        not isinstance(payload.get("selection_id"), str)
        or CONTENT_SHA256_RE.fullmatch(str(payload.get("selection_id"))) is None
        or not isinstance(payload.get("selection_head"), str)
        or OBJECT_ID_RE.fullmatch(str(payload.get("selection_head"))) is None
    ):
        raise ContractError("Git blob claim имеет неверный контракт.")
    if schema_version in {3, 4}:
        validate_runtime_identifier(payload.get("task_id"), "task_id")
    if schema_version == 4:
        validate_runtime_identifier(payload.get("generation"), "generation")
    if schema_version == 5:
        if (
            not isinstance(payload.get("card_id"), str)
            or CARD_ID_RE.fullmatch(str(payload.get("card_id"))) is None
        ):
            raise ContractError("Git blob claim содержит неверный card_id.")
        if payload.get("task_id") is not None:
            validate_runtime_identifier(payload.get("task_id"), "task_id")
        if payload.get("generation") is not None:
            validate_runtime_identifier(payload.get("generation"), "generation")
        if payload.get("generation") is not None and payload.get("task_id") is None:
            raise ContractError("Git blob claim не может иметь generation без task_id.")
    try:
        parsed_lease_id = uuid.UUID(str(payload["lease_id"]))
    except ValueError as error:
        raise ContractError("Git blob claim содержит неверный lease_id.") from error
    if str(parsed_lease_id) != payload["lease_id"]:
        raise ContractError("Git blob claim содержит неверный lease_id.")
    return payload


def validate_runtime_identifier(value: object, name: str) -> str:
    if (
        not isinstance(value, str)
        or not value.strip()
        or len(value) > 1_024
        or "\x00" in value
        or "\n" in value
        or "\r" in value
    ):
        raise ContractError(
            f"{name} должен быть непустой однострочной строкой."
        )
    return value


def load_claim(
    repo_root: Path,
    reference: str,
    expected_branch_ref: str,
) -> tuple[dict[str, object] | None, str | None]:
    oid = read_ref_oid(repo_root, reference)
    if oid is None:
        return None, None
    object_type = checked_git(
        repo_root,
        "определить тип Git-объекта claim",
        "cat-file",
        "-t",
        oid,
    ).stdout.strip()
    if object_type != "blob":
        raise ContractError("Служебная Git-ссылка claim не указывает на blob.")
    raw_payload = checked_git(
        repo_root,
        "прочитать Git blob claim",
        "cat-file",
        "blob",
        oid,
    ).stdout
    try:
        payload = json.loads(
            raw_payload,
            object_pairs_hook=reject_duplicate_claim_keys,
        )
    except (UnicodeError, json.JSONDecodeError) as error:
        raise ContractError(
            "Git blob claim повреждён и не может быть "
            "автоматически заменён."
        ) from error
    return validate_claim(payload, expected_branch_ref), oid


def reject_duplicate_queue_keys(
    pairs: list[tuple[str, object]],
) -> dict[str, object]:
    payload: dict[str, object] = {}
    for key, value in pairs:
        if key in payload:
            raise ContractError(
                f"Git blob очереди содержит повторяющееся поле {key!r}."
            )
        payload[key] = value
    return payload


def reject_nonfinite_queue_number(value: str) -> object:
    raise ContractError(
        f"Git blob очереди содержит неконечное число {value}."
    )


def validate_queue_ticket(ticket: object, *, owner: bool) -> dict[str, object]:
    common_keys = {"task_id", "ticket_id", "seq"}
    specific_keys = (
        {"generation", "base_head", "admitted_at", "admitted_at_epoch"}
        if owner
        else {
            "registered_at",
            "registered_at_epoch",
            "acknowledged_head",
        }
    )
    if not isinstance(ticket, dict) or frozenset(ticket) != common_keys | specific_keys:
        raise ContractError("Запись участника очереди имеет неверный контракт.")
    validate_runtime_identifier(ticket.get("task_id"), "task_id")
    validate_runtime_identifier(ticket.get("ticket_id"), "ticket_id")
    sequence = ticket.get("seq")
    if type(sequence) is not int or sequence < 1:
        raise ContractError("Запись участника очереди имеет неверный seq.")
    if owner:
        validate_runtime_identifier(ticket.get("generation"), "generation")
        oid = ticket.get("base_head")
        stamp = ticket.get("admitted_at")
        epoch = ticket.get("admitted_at_epoch")
    else:
        oid = ticket.get("acknowledged_head")
        stamp = ticket.get("registered_at")
        epoch = ticket.get("registered_at_epoch")
    if not isinstance(oid, str) or OBJECT_ID_RE.fullmatch(oid) is None:
        raise ContractError("Запись участника очереди имеет неверную вершину.")
    if not isinstance(stamp, str) or not stamp:
        raise ContractError("Запись участника очереди имеет неверную метку времени.")
    if type(epoch) not in {int, float} or (
        type(epoch) is float and not math.isfinite(epoch)
    ):
        raise ContractError("Запись участника очереди имеет неверный epoch.")
    return ticket


def validate_queue_completion(value: object) -> None:
    if value is None:
        return
    if not isinstance(value, dict):
        raise ContractError("Запись завершения очереди имеет неверный контракт.")
    kind = value.get("kind")
    expected_keys = {
        "kind",
        "task_id",
        "generation",
        "head",
        "completed_at",
    }
    if kind == "committed":
        expected_keys.add("base_head")
    elif kind == "reset":
        expected_keys.add("аннулированные_задачи")
    elif kind != "finished_clean":
        raise ContractError("Запись завершения очереди имеет неверный kind.")
    if frozenset(value) != expected_keys:
        raise ContractError("Запись завершения очереди имеет неверный набор полей.")
    validate_runtime_identifier(value.get("task_id"), "task_id")
    validate_runtime_identifier(value.get("generation"), "generation")
    if kind == "reset" and CONTENT_SHA256_RE.fullmatch(
        str(value["generation"]),
    ) is None:
        raise ContractError(
            "Запись завершения сброса имеет неверное поколение.",
        )
    for name in ("head", "base_head"):
        if name not in value:
            continue
        oid = value.get(name)
        if not isinstance(oid, str) or OBJECT_ID_RE.fullmatch(oid) is None:
            raise ContractError("Запись завершения очереди имеет неверную вершину.")
    if not isinstance(value.get("completed_at"), str) or not value["completed_at"]:
        raise ContractError("Запись завершения очереди имеет неверную метку времени.")
    if kind == "reset":
        аннулированные = value.get("аннулированные_задачи")
        if not isinstance(аннулированные, list):
            raise ContractError(
                "Запись завершения сброса не содержит список задач.",
            )
        for идентификатор in аннулированные:
            validate_runtime_identifier(
                идентификатор,
                "аннулированная задача",
            )
        if аннулированные != sorted(set(аннулированные)):
            raise ContractError(
                "Запись завершения сброса содержит неканонический список задач.",
            )


def validate_queue_state(
    state: object,
    expected_worktree_id: str,
    expected_branch_ref: str,
) -> dict[str, object]:
    expected_keys = {
        "schema_version",
        "worktree_id",
        "branch_ref",
        "next_seq",
        "owner",
        "waiting",
        "last_completion",
        "updated_at",
    }
    if not isinstance(state, dict) or frozenset(state) != expected_keys:
        raise ContractError("Git blob очереди имеет неверный набор полей.")
    if type(state.get("schema_version")) is not int or state["schema_version"] != 1:
        raise ContractError("Git blob очереди имеет неверную схему.")
    if (
        state.get("worktree_id") != expected_worktree_id
        or state.get("branch_ref") != expected_branch_ref
    ):
        raise ContractError("Git blob очереди принадлежит другому checkout или ветке.")
    next_seq = state.get("next_seq")
    if type(next_seq) is not int or next_seq < 1:
        raise ContractError("Git blob очереди имеет неверный next_seq.")
    owner = state.get("owner")
    validated_owner = (
        validate_queue_ticket(owner, owner=True)
        if owner is not None
        else None
    )
    waiting = state.get("waiting")
    if not isinstance(waiting, list):
        raise ContractError("Git blob очереди имеет неверный waiting.")
    validated_waiting = [
        validate_queue_ticket(ticket, owner=False) for ticket in waiting
    ]
    participants = (
        ([validated_owner] if validated_owner is not None else [])
        + validated_waiting
    )
    sequences = [int(ticket["seq"]) for ticket in participants]
    task_ids = [str(ticket["task_id"]) for ticket in participants]
    ticket_ids = [str(ticket["ticket_id"]) for ticket in participants]
    if (
        sequences != sorted(sequences)
        or len(sequences) != len(set(sequences))
        or len(task_ids) != len(set(task_ids))
        or len(ticket_ids) != len(set(ticket_ids))
        or (sequences and next_seq <= max(sequences))
    ):
        raise ContractError("Git blob очереди нарушает порядок или уникальность участников.")
    validate_queue_completion(state.get("last_completion"))
    if not isinstance(state.get("updated_at"), str) or not state["updated_at"]:
        raise ContractError("Git blob очереди имеет неверную метку времени.")
    return state


def load_queue_admission(
    repo_root: Path,
    expected_branch_ref: str,
    task_id: str,
    generation: str,
    selection_head: str,
) -> tuple[str, str] | None:
    reference = queue_ref(repo_root)
    oid = read_ref_oid(repo_root, reference)
    if oid is None:
        return None
    object_type = checked_git(
        repo_root,
        "определить тип Git-объекта очереди",
        "cat-file",
        "-t",
        oid,
    ).stdout.strip()
    if object_type != "blob":
        raise ContractError("Служебная Git-ссылка очереди не указывает на blob.")
    raw_payload = checked_git(
        repo_root,
        "прочитать Git blob очереди",
        "cat-file",
        "blob",
        oid,
    ).stdout
    try:
        state = json.loads(
            raw_payload,
            object_pairs_hook=reject_duplicate_queue_keys,
            parse_constant=reject_nonfinite_queue_number,
        )
    except (UnicodeError, json.JSONDecodeError) as error:
        raise ContractError(
            "Git blob очереди повреждён и не может подтвердить admission."
        ) from error
    state = validate_queue_state(
        state,
        checkout_identity(repo_root),
        expected_branch_ref,
    )
    owner = state.get("owner")
    if not isinstance(owner, dict):
        return None
    for name in ("task_id", "generation"):
        validate_runtime_identifier(owner.get(name), name)
    base_head = owner.get("base_head")
    if (
        not isinstance(base_head, str)
        or OBJECT_ID_RE.fullmatch(base_head) is None
    ):
        raise ContractError("Владелец очереди имеет неверный base_head.")
    if (
        owner["task_id"] != task_id
        or owner["generation"] != generation
        or base_head != selection_head
    ):
        return None
    return reference, oid


def canonical_claim_text(payload: dict[str, object]) -> str:
    return (
        json.dumps(
            payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    )


def write_claim_blob(
    repo_root: Path,
    payload: dict[str, object],
    expected_branch_ref: str,
) -> str:
    validate_claim(payload, expected_branch_ref)
    result = checked_git(
        repo_root,
        "записать Git blob claim",
        "hash-object",
        "-w",
        "--stdin",
        input_text=canonical_claim_text(payload),
    )
    oid = result.stdout.strip()
    if not oid:
        raise ContractError("Git не вернул object ID нового claim blob.")
    return oid


def ref_retry_delay(attempt: int) -> float:
    return min(REF_RETRY_BASE_SECONDS * (2**attempt), REF_RETRY_MAX_SECONDS)


def снимок_отсутствия_сброса(
    корень: Path,
    длина_объекта: int,
) -> tuple[bool, str, str | None]:
    ссылка = queue_ref(корень)
    объект = read_ref_oid(корень, ссылка)
    if объект is not None:
        тип = checked_git(
            корень,
            "проверить тип записи очереди перед claim",
            "cat-file",
            "-t",
            объект,
        ).stdout.strip()
        if тип != "blob":
            raise ContractError("Служебная очередь не указывает на Git blob.")
        сырой = checked_git(
            корень,
            "прочитать запись очереди перед claim",
            "cat-file",
            "blob",
            объект,
        ).stdout
        try:
            значение = json.loads(
                сырой,
                object_pairs_hook=reject_duplicate_queue_keys,
                parse_constant=reject_nonfinite_queue_number,
            )
        except (UnicodeError, json.JSONDecodeError) as ошибка:
            raise ContractError("Запись очереди повреждена.") from ошибка
        if (
            isinstance(значение, dict)
            and значение.get("схема") in СХЕМЫ_ЗАПИСИ_СБРОСА_ОЧЕРЕДИ
        ):
            return False, "", объект
    ожидаемый = объект or ("0" * длина_объекта)
    return True, f"verify {ссылка} {ожидаемый}\n", объект


def идёт_сброс_очереди(корень: Path) -> bool:
    допускается, _, _ = снимок_отсутствия_сброса(
        корень,
        len(branch_head_oid(корень, active_branch_ref(корень))),
    )
    return not допускается


def cas_claim_ref(
    repo_root: Path,
    reference: str,
    old_oid: str | None,
    new_oid: str | None,
    *,
    branch_ref: str | None = None,
    selection_head: str | None = None,
    ограждающая_ссылка: str | None = None,
    ожидаемый_объект_ограждения: str | None = None,
) -> bool:
    if new_oid is None and old_oid is None:
        raise ContractError("Нельзя удалить отсутствующее поколение claim.")
    if (branch_ref is None) != (selection_head is None):
        raise ContractError(
            "Проверка вершины claim требует branch_ref и selection_head."
        )
    if (ограждающая_ссылка is None) != (
        ожидаемый_объект_ограждения is None
    ):
        raise ContractError(
            "Дополнительное ограждение требует ссылку и object ID."
        )
    last_error = ""
    for attempt in range(UNCHANGED_REF_RETRY_ATTEMPTS):
        длина_объекта = len(selection_head or old_oid or new_oid or "")
        if длина_объекта not in {40, 64}:
            raise ContractError("Нельзя определить формат Git-объекта claim.")
        допускается, проверка_сброса, объект_очереди = снимок_отсутствия_сброса(
            repo_root,
            длина_объекта,
        )
        if not допускается:
            return False
        if new_oid is None:
            команда_претензии = f"delete {reference} {old_oid}\n"
        else:
            команда_претензии = (
                f"create {reference} {new_oid}\n"
                if old_oid is None
                else f"update {reference} {new_oid} {old_oid}\n"
            )
        проверка_ветки = (
            f"verify {branch_ref} {selection_head}\n"
            if branch_ref is not None and selection_head is not None
            else ""
        )
        проверка_ограждения = (
            f"verify {ограждающая_ссылка} "
            f"{ожидаемый_объект_ограждения}\n"
            if ограждающая_ссылка is not None
            and ожидаемый_объект_ограждения is not None
            else ""
        )
        transaction = (
            "start\n"
            f"{проверка_ветки}"
            f"{проверка_сброса}"
            f"{проверка_ограждения}"
            f"{команда_претензии}"
            "prepare\n"
            "commit\n"
        )
        result = run_git(
            repo_root,
            "update-ref",
            "--no-deref",
            "--stdin",
            input_text=transaction,
        )
        if result.returncode == 0:
            return True
        last_error = result.stderr.strip()
        if (
            branch_ref is not None
            and selection_head is not None
            and branch_head_oid(repo_root, branch_ref) != selection_head
        ):
            raise ContractError(
                "Вершина ветки изменилась до атомарной записи claim."
            )
        if read_ref_oid(repo_root, queue_ref(repo_root)) != объект_очереди:
            return False
        if (
            ограждающая_ссылка is not None
            and нарушено_ограждение_ссылки(
                repo_root,
                (
                    ограждающая_ссылка,
                    str(ожидаемый_объект_ограждения),
                ),
            )
        ):
            return False
        if read_ref_oid(repo_root, reference) != old_oid:
            return False
        if attempt + 1 < UNCHANGED_REF_RETRY_ATTEMPTS:
            time.sleep(ref_retry_delay(attempt))
    detail = last_error or "Git не вернул текст ошибки."
    raise ContractError(f"Не удалось атомарно обновить Git-ссылку claim: {detail}")


def cas_run_fence(
    repo_root: Path,
    claim_reference: str,
    claim_oid: str | None,
    queue_reference: str,
    queue_oid: str,
    branch_ref: str,
    selection_head: str,
    *,
    new_claim_oid: str | None = None,
    delete_claim: bool = False,
) -> bool:
    if delete_claim and new_claim_oid is not None:
        raise ContractError(
            "Run-fence не может одновременно обновлять и удалять claim."
        )
    if claim_oid is None:
        if delete_claim or new_claim_oid is not None:
            raise ContractError(
                "Отсутствующий claim можно только атомарно подтвердить."
            )
        claim_command = f"verify {claim_reference}\n"
    elif delete_claim:
        claim_command = f"delete {claim_reference} {claim_oid}\n"
    elif new_claim_oid is None:
        claim_command = f"verify {claim_reference} {claim_oid}\n"
    else:
        claim_command = (
            f"update {claim_reference} {new_claim_oid} {claim_oid}\n"
        )
    transaction = (
        "start\n"
        f"verify {queue_reference} {queue_oid}\n"
        f"verify {branch_ref} {selection_head}\n"
        f"{claim_command}"
        "prepare\n"
        "commit\n"
    )
    last_error = ""
    for attempt in range(UNCHANGED_REF_RETRY_ATTEMPTS):
        result = run_git(
            repo_root,
            "update-ref",
            "--no-deref",
            "--stdin",
            input_text=transaction,
        )
        if result.returncode == 0:
            return True
        last_error = result.stderr.strip()
        if branch_head_oid(repo_root, branch_ref) != selection_head:
            raise ContractError(
                "Вершина ветки изменилась до атомарной проверки run-fence."
            )
        if (
            read_ref_oid(repo_root, queue_reference) != queue_oid
            or read_ref_oid(repo_root, claim_reference) != claim_oid
        ):
            return False
        if attempt + 1 < UNCHANGED_REF_RETRY_ATTEMPTS:
            time.sleep(ref_retry_delay(attempt))
    detail = last_error or "Git не вернул текст ошибки."
    raise ContractError(f"Не удалось атомарно проверить run-fence: {detail}")


def claim_matches_current_selection(
    claim: dict[str, object] | None,
    ready_candidate: StepRecord,
    selection: dict[str, object],
) -> bool:
    if (
        claim is None
        or claim["schema_version"] not in {2, 3, 4, 5}
        or claim["selection_id"] != selection["id"]
    ):
        return False
    if (
        claim["step_id"] != ready_candidate.step_id
        or claim["selection_head"] != selection["head"]
        or (
            claim["schema_version"] == 5
            and claim["card_id"] != ready_candidate.card_id
        )
    ):
        raise ContractError(
            "Git blob claim противоречит текущему selection: "
            "step_id, card_id или selection_head не совпадает."
        )
    return True


def нарушено_ограждение_ссылки(
    корень: Path,
    ограждение: tuple[str, str] | None,
) -> bool:
    if ограждение is None:
        return False
    ссылка, ожидаемый_объект = ограждение
    текущий_объект = read_ref_oid(корень, ссылка)
    if ожидаемый_объект in {"0" * 40, "0" * 64}:
        return текущий_объект is not None
    return текущий_объект != ожидаемый_объект


def confirmed_existing_claim_response(
    repo_root: Path,
    reference: str,
    ready_candidate: StepRecord,
    selection: dict[str, object],
    lease_id: str,
    ограждение_ссылки: tuple[str, str] | None = None,
) -> tuple[
    dict[str, object] | None,
    str | None,
    tuple[dict[str, object], int] | None,
]:
    параметры_ограждения = (
        {
            "ограждающая_ссылка": ограждение_ссылки[0],
            "ожидаемый_объект_ограждения": ограждение_ссылки[1],
        }
        if ограждение_ссылки is not None
        else {}
    )
    for _attempt in range(MAX_CAS_ATTEMPTS):
        existing, old_oid = load_claim(
            repo_root,
            reference,
            ready_candidate.branch_ref,
        )
        if not claim_matches_current_selection(
            existing,
            ready_candidate,
            selection,
        ):
            return existing, old_oid, None
        if old_oid is None:
            raise ContractError(
                "Внутренняя ошибка: существующий claim не имеет object ID."
            )
        if not cas_claim_ref(
            repo_root,
            reference,
            old_oid,
            old_oid,
            branch_ref=ready_candidate.branch_ref,
            selection_head=str(selection["head"]),
            **параметры_ограждения,
        ):
            if идёт_сброс_очереди(repo_root):
                return (
                    existing,
                    old_oid,
                    ({"state": "mismatch"}, EXIT_MISMATCH),
                )
            if нарушено_ограждение_ссылки(
                repo_root,
                ограждение_ссылки,
            ):
                return (
                    existing,
                    old_oid,
                    ({"state": "mismatch"}, EXIT_MISMATCH),
                )
            continue
        if existing is None:
            raise ContractError(
                "Внутренняя ошибка: подтверждённый claim отсутствует."
            )
        if (
            (
                existing["schema_version"] == 2
                or (
                    existing["schema_version"] == 5
                    and existing["task_id"] is None
                    and existing["generation"] is None
                )
            )
            and existing["lease_id"] == lease_id
        ):
            return (
                existing,
                old_oid,
                (
                    {
                        "state": "claimed",
                        "ownership": "existing",
                        "branch_ref": ready_candidate.branch_ref,
                        "step_id": ready_candidate.step_id,
                        "selection_id": selection["id"],
                        "selection_head": selection["head"],
                        "lease_id": lease_id,
                        "record_path": ready_candidate.record_path,
                    },
                    0,
                ),
            )
        return (
            existing,
            old_oid,
            (
                {
                    "state": "already_claimed",
                    "branch_ref": ready_candidate.branch_ref,
                    "step_id": ready_candidate.step_id,
                    "selection_id": selection["id"],
                },
                EXIT_ALREADY_CLAIMED,
            ),
        )
    raise ContractError(
        "Claim изменялся конкурентно во время подтверждения текущего selection."
    )


def claim_step(
    repo_root: Path,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
    expected_selection_id: str | None,
    lease_id: str | None,
) -> tuple[dict[str, object], int]:
    if (
        expected_branch_ref is None
        or expected_step_id is None
        or expected_selection_id is None
        or lease_id is None
    ):
        raise ContractError(
            "claim требует --expected-branch-ref, --expected-step-id "
            "--expected-selection-id и --lease-id."
        )
    if CONTENT_SHA256_RE.fullmatch(expected_selection_id) is None:
        raise ContractError(
            "--expected-selection-id должен иметь вид sha256:<64 hex>."
        )
    try:
        parsed_lease_id = uuid.UUID(lease_id)
    except ValueError as error:
        raise ContractError("--lease-id должен быть каноническим UUID.") from error
    if str(parsed_lease_id) != lease_id:
        raise ContractError("--lease-id должен быть каноническим UUID.")
    if идёт_сброс_очереди(repo_root):
        return {"state": "mismatch"}, EXIT_MISMATCH
    record = active_record(repo_root)
    if record.branch_ref != expected_branch_ref:
        raise ContractError(
            "Активная ветка изменилась: ожидалась "
            f"{expected_branch_ref}, обнаружена {record.branch_ref}."
        )
    ready_candidate, selection = select_ready_candidate(repo_root, record)
    if ready_candidate is None:
        return (
            {"state": "not_ready", **record.summary_payload()},
            EXIT_NOT_READY,
        )
    if selection is None:
        raise ContractError("Внутренняя ошибка: готовый шаг не имеет selection.")
    assert_expected_identity(
        record,
        ready_candidate,
        selection,
        expected_branch_ref,
        expected_step_id,
        expected_selection_id,
    )
    try:
        ограждение_резервации = потребовать_общую_резервацию(
            repo_root,
            ready_candidate.branch_ref,
            str(selection["head"]),
            lease_id,
        )
    except НесовпадениеОбщейРезервации:
        return {"state": "mismatch"}, EXIT_MISMATCH
    ограждение_ссылки = ограждение_резервации
    if (
        ограждение_ссылки is None
        and ready_candidate.branch_ref == ССЫЛКА_ВЕТКИ_ОБЩЕГО_ЗАДАНИЯ
    ):
        ограждение_ссылки = (
            ссылка_границы_простого_сброса(
                repo_root,
                ready_candidate.branch_ref,
            ),
            "0" * len(str(selection["head"])),
        )
    параметры_ограждения = (
        {
            "ограждающая_ссылка": ограждение_ссылки[0],
            "ожидаемый_объект_ограждения": ограждение_ссылки[1],
        }
        if ограждение_ссылки is not None
        else {}
    )
    reference = claim_ref(repo_root, ready_candidate.branch_ref)
    existing, old_oid, existing_response = confirmed_existing_claim_response(
        repo_root,
        reference,
        ready_candidate,
        selection,
        lease_id,
        ограждение_ссылки,
    )
    if existing_response is not None:
        return existing_response
    if existing is not None and existing["lease_id"] == lease_id:
        raise ContractError(
            "--lease-id уже использован для другого поколения шага этой ветки; "
            "нужен свежий UUID попытки."
        )
    payload: dict[str, object] = {
        "schema_version": 5,
        "branch_ref": ready_candidate.branch_ref,
        "step_id": ready_candidate.step_id,
        "card_id": ready_candidate.card_id,
        "selection_id": selection["id"],
        "selection_head": selection["head"],
        "lease_id": lease_id,
        "task_id": None,
        "generation": None,
    }
    new_oid = write_claim_blob(repo_root, payload, ready_candidate.branch_ref)
    if cas_claim_ref(
        repo_root,
        reference,
        old_oid,
        new_oid,
        branch_ref=ready_candidate.branch_ref,
        selection_head=str(selection["head"]),
        **параметры_ограждения,
    ):
        return (
            {
                "state": "claimed",
                "ownership": "new",
                "branch_ref": ready_candidate.branch_ref,
                "step_id": ready_candidate.step_id,
                "selection_id": selection["id"],
                "selection_head": selection["head"],
                "lease_id": lease_id,
                "record_path": ready_candidate.record_path,
            },
            0,
        )
    if идёт_сброс_очереди(repo_root):
        return {"state": "mismatch"}, EXIT_MISMATCH
    if нарушено_ограждение_ссылки(
        repo_root,
        ограждение_ссылки,
    ):
        return {"state": "mismatch"}, EXIT_MISMATCH
    _concurrent, _concurrent_oid, concurrent_response = (
        confirmed_existing_claim_response(
            repo_root,
            reference,
            ready_candidate,
            selection,
            lease_id,
            ограждение_ссылки,
        )
    )
    if concurrent_response is not None:
        return concurrent_response
    raise ContractError(
        "Claim изменился конкурентно; нужны новая проверка "
        "branch_ref, step_id и selection_id и новый вызов claim."
    )


def validate_expected_run_identity(
    repo_root: Path,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
    expected_selection_id: str | None,
) -> tuple[str, str, str]:
    if (
        expected_branch_ref is None
        or expected_step_id is None
        or expected_selection_id is None
    ):
        raise ContractError(
            "Команда требует --expected-branch-ref, "
            "--expected-step-id и --expected-selection-id."
        )
    validate_branch_ref(repo_root, expected_branch_ref)
    if STEP_ID_RE.fullmatch(expected_step_id) is None:
        raise ContractError("Неверный --expected-step-id.")
    if CONTENT_SHA256_RE.fullmatch(expected_selection_id) is None:
        raise ContractError(
            "--expected-selection-id должен иметь вид sha256:<64 hex>."
        )
    return expected_branch_ref, expected_step_id, expected_selection_id


def validate_lease_id(value: str | None, option_name: str) -> str:
    if value is None:
        raise ContractError(f"Команда требует {option_name}.")
    try:
        parsed = uuid.UUID(value)
    except ValueError as error:
        raise ContractError(f"{option_name} должен быть каноническим UUID.") from error
    if str(parsed) != value:
        raise ContractError(f"{option_name} должен быть каноническим UUID.")
    return value


def expected_ready_selection(
    repo_root: Path,
    expected_branch_ref: str,
    expected_step_id: str,
    expected_selection_id: str,
) -> tuple[StepRecord, dict[str, object]] | None:
    ensure_unique_branch_checkout(repo_root, expected_branch_ref)
    record = active_record(repo_root)
    ready_candidate, selection = select_ready_candidate(repo_root, record)
    if (
        record.branch_ref != expected_branch_ref
        or ready_candidate is None
        or selection is None
        or ready_candidate.step_id != expected_step_id
        or selection.get("id") != expected_selection_id
    ):
        return None
    return ready_candidate, selection


def run_mismatch(
    reason: str,
    expected_branch_ref: str,
) -> tuple[dict[str, object], int]:
    return (
        {
            "state": "mismatch",
            "reason": reason,
            "branch_ref": expected_branch_ref,
        },
        EXIT_MISMATCH,
    )


def bind_run(
    repo_root: Path,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
    expected_selection_id: str | None,
    expected_lease_id: str | None,
    task_id: str | None,
) -> tuple[dict[str, object], int]:
    branch_ref, step_id, selection_id = validate_expected_run_identity(
        repo_root,
        expected_branch_ref,
        expected_step_id,
        expected_selection_id,
    )
    lease_id = validate_lease_id(expected_lease_id, "--expected-lease-id")
    exact_task_id = validate_runtime_identifier(task_id, "--task-id")
    for _attempt in range(MAX_CAS_ATTEMPTS):
        if идёт_сброс_очереди(repo_root):
            return run_mismatch("reset_in_progress", branch_ref)
        current = expected_ready_selection(
            repo_root,
            branch_ref,
            step_id,
            selection_id,
        )
        if current is None:
            return run_mismatch("selection_changed", branch_ref)
        ready_candidate, selection = current
        reference = claim_ref(repo_root, branch_ref)
        existing, old_oid = load_claim(repo_root, reference, branch_ref)
        if existing is None or old_oid is None:
            return run_mismatch("missing", branch_ref)
        if not claim_matches_current_selection(
            existing,
            ready_candidate,
            selection,
        ):
            return run_mismatch("claim_changed", branch_ref)
        if existing["lease_id"] != lease_id:
            return run_mismatch("lease_changed", branch_ref)
        schema_version = int(existing["schema_version"])
        if schema_version in {3, 4}:
            if existing.get("task_id") != exact_task_id:
                return run_mismatch("task_changed", branch_ref)
            if cas_claim_ref(
                repo_root,
                reference,
                old_oid,
                old_oid,
                branch_ref=branch_ref,
                selection_head=str(selection["head"]),
            ):
                return (
                    {
                        "state": "bound",
                        "ownership": "existing",
                        "branch_ref": branch_ref,
                        "step_id": step_id,
                        "selection_id": selection_id,
                        "selection_head": selection["head"],
                    },
                    0,
                )
            continue
        if schema_version == 5:
            связанная_задача = existing.get("task_id")
            if связанная_задача is not None:
                if связанная_задача != exact_task_id:
                    return run_mismatch("task_changed", branch_ref)
                if cas_claim_ref(
                    repo_root,
                    reference,
                    old_oid,
                    old_oid,
                    branch_ref=branch_ref,
                    selection_head=str(selection["head"]),
                ):
                    return (
                        {
                            "state": "bound",
                            "ownership": "existing",
                            "branch_ref": branch_ref,
                            "step_id": step_id,
                            "selection_id": selection_id,
                            "selection_head": selection["head"],
                        },
                        0,
                    )
                continue
            связанные_данные = {**existing, "task_id": exact_task_id}
            новый_объект = write_claim_blob(
                repo_root,
                связанные_данные,
                branch_ref,
            )
            if cas_claim_ref(
                repo_root,
                reference,
                old_oid,
                новый_объект,
                branch_ref=branch_ref,
                selection_head=str(selection["head"]),
            ):
                return (
                    {
                        "state": "bound",
                        "ownership": "new",
                        "branch_ref": branch_ref,
                        "step_id": step_id,
                        "selection_id": selection_id,
                        "selection_head": selection["head"],
                    },
                    0,
                )
            continue
        if schema_version != 2:
            return run_mismatch("claim_changed", branch_ref)
        bound_payload = {
            **existing,
            "schema_version": 3,
            "task_id": exact_task_id,
        }
        new_oid = write_claim_blob(repo_root, bound_payload, branch_ref)
        if cas_claim_ref(
            repo_root,
            reference,
            old_oid,
            new_oid,
            branch_ref=branch_ref,
            selection_head=str(selection["head"]),
        ):
            return (
                {
                    "state": "bound",
                    "ownership": "new",
                    "branch_ref": branch_ref,
                    "step_id": step_id,
                    "selection_id": selection_id,
                    "selection_head": selection["head"],
                },
                0,
            )
    raise ContractError("Claim изменялся конкурентно во время bind-run.")


def verify_run(
    repo_root: Path,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
    expected_selection_id: str | None,
    expected_lease_id: str | None,
    task_id: str | None,
    generation: str | None,
) -> tuple[dict[str, object], int]:
    branch_ref, step_id, selection_id = validate_expected_run_identity(
        repo_root,
        expected_branch_ref,
        expected_step_id,
        expected_selection_id,
    )
    lease_id = validate_lease_id(expected_lease_id, "--expected-lease-id")
    exact_task_id = validate_runtime_identifier(task_id, "--task-id")
    exact_generation = validate_runtime_identifier(generation, "--generation")
    for _attempt in range(MAX_CAS_ATTEMPTS):
        if идёт_сброс_очереди(repo_root):
            return run_mismatch("reset_in_progress", branch_ref)
        current = expected_ready_selection(
            repo_root,
            branch_ref,
            step_id,
            selection_id,
        )
        if current is None:
            return run_mismatch("selection_changed", branch_ref)
        ready_candidate, selection = current
        admission = load_queue_admission(
            repo_root,
            branch_ref,
            exact_task_id,
            exact_generation,
            str(selection["head"]),
        )
        if admission is None:
            return run_mismatch("not_owner", branch_ref)
        queue_reference, queue_oid = admission
        reference = claim_ref(repo_root, branch_ref)
        existing, old_oid = load_claim(repo_root, reference, branch_ref)
        if existing is None or old_oid is None:
            return run_mismatch("missing", branch_ref)
        if not claim_matches_current_selection(
            existing,
            ready_candidate,
            selection,
        ):
            return run_mismatch("claim_changed", branch_ref)
        schema_version = int(existing["schema_version"])
        if schema_version not in {3, 4, 5}:
            return run_mismatch("unbound", branch_ref)
        if existing.get("task_id") != exact_task_id:
            return run_mismatch("task_changed", branch_ref)
        if existing.get("lease_id") != lease_id:
            return run_mismatch("lease_changed", branch_ref)
        ensure_run_checkout_clean(repo_root)
        новый_объект: str | None = None
        if schema_version == 4:
            if existing.get("generation") != exact_generation:
                return run_mismatch("generation_changed", branch_ref)
        elif schema_version == 5:
            if existing.get("generation") is not None:
                if existing.get("generation") != exact_generation:
                    return run_mismatch("generation_changed", branch_ref)
            else:
                проверенные_данные = {
                    **existing,
                    "generation": exact_generation,
                }
                новый_объект = write_claim_blob(
                    repo_root,
                    проверенные_данные,
                    branch_ref,
                )
        else:
            проверенные_данные = {
                **existing,
                "schema_version": 4,
                "generation": exact_generation,
            }
            новый_объект = write_claim_blob(
                repo_root,
                проверенные_данные,
                branch_ref,
            )
        ensure_run_checkout_clean(repo_root)
        if cas_run_fence(
            repo_root,
            reference,
            old_oid,
            queue_reference,
            queue_oid,
            branch_ref,
            str(selection["head"]),
            new_claim_oid=новый_объект,
        ):
            return (
                {
                    "state": "verified",
                    **ready_candidate.payload(),
                    "selection": selection,
                },
                0,
            )
    raise ContractError("Run-fence изменялся конкурентно во время verify-run.")


def ensure_run_checkout_clean(repo_root: Path) -> None:
    staged = run_git(
        repo_root,
        "diff",
        "--cached",
        "--quiet",
        "--exit-code",
        "--",
    )
    if staged.returncode == 1:
        raise ContractError(
            "Run-fence требует пустой Git-индекс."
        )
    if staged.returncode != 0:
        detail = staged.stderr.strip() or "Git не вернул текст ошибки."
        raise ContractError(f"Не удалось проверить Git-индекс: {detail}")
    worktree = checked_git(
        repo_root,
        "проверить чистоту run-fence",
        "-c",
        "core.quotepath=false",
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
        "--ignore-submodules=none",
        "--",
        ".",
        ":(top,exclude).obsidian",
        ":(top,exclude).obsidian/**",
    )
    if worktree.stdout:
        raise ContractError(
            "Run-fence требует чистый checkout вне корневой .obsidian."
        )


def rearm_claim(
    repo_root: Path,
    expected_branch_ref: str | None,
    expected_step_id: str | None,
    expected_selection_id: str | None,
    expected_lease_id: str | None,
    task_id: str | None,
    generation: str | None,
) -> tuple[dict[str, object], int]:
    branch_ref, step_id, selection_id = validate_expected_run_identity(
        repo_root,
        expected_branch_ref,
        expected_step_id,
        expected_selection_id,
    )
    lease_id = validate_lease_id(expected_lease_id, "--expected-lease-id")
    exact_task_id = validate_runtime_identifier(task_id, "--task-id")
    exact_generation = validate_runtime_identifier(generation, "--generation")
    for _attempt in range(MAX_CAS_ATTEMPTS):
        if идёт_сброс_очереди(repo_root):
            return run_mismatch("reset_in_progress", branch_ref)
        current = expected_ready_selection(
            repo_root,
            branch_ref,
            step_id,
            selection_id,
        )
        if current is None:
            return run_mismatch("selection_changed", branch_ref)
        ready_candidate, selection = current
        admission = load_queue_admission(
            repo_root,
            branch_ref,
            exact_task_id,
            exact_generation,
            str(selection["head"]),
        )
        if admission is None:
            return run_mismatch("not_owner", branch_ref)
        queue_reference, queue_oid = admission
        reference = claim_ref(repo_root, branch_ref)
        existing, old_oid = load_claim(repo_root, reference, branch_ref)
        if existing is None or old_oid is None:
            return run_mismatch("missing", branch_ref)
        if not claim_matches_current_selection(
            existing,
            ready_candidate,
            selection,
        ):
            return run_mismatch("claim_changed", branch_ref)
        версия_претензии = int(existing["schema_version"])
        if версия_претензии not in {4, 5}:
            return run_mismatch("unverified", branch_ref)
        if existing.get("task_id") != exact_task_id:
            return run_mismatch("task_changed", branch_ref)
        if existing.get("lease_id") != lease_id:
            return run_mismatch("lease_changed", branch_ref)
        if existing.get("generation") != exact_generation:
            return run_mismatch("generation_changed", branch_ref)
        ensure_run_checkout_clean(repo_root)
        новый_объект = None
        владение = "existing"
        if версия_претензии == 4:
            новый_объект = write_claim_blob(
                repo_root,
                {
                    **existing,
                    "schema_version": 5,
                    "card_id": ready_candidate.card_id,
                },
                branch_ref,
            )
            владение = "new"
        if cas_run_fence(
            repo_root,
            reference,
            old_oid,
            queue_reference,
            queue_oid,
            branch_ref,
            str(selection["head"]),
            new_claim_oid=новый_объект,
        ):
            return (
                {
                    "state": "rearmed",
                    "ownership": владение,
                    "branch_ref": branch_ref,
                    "step_id": step_id,
                    "selection_id": selection_id,
                    "selection_head": selection["head"],
                },
                0,
            )
    raise ContractError("Run-fence изменялся конкурентно во время rearm.")


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
    reference = claim_ref(repo_root, branch_ref)
    existing, _oid = load_claim(repo_root, reference, branch_ref)
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
    reference = claim_ref(repo_root, branch_ref)
    for _attempt in range(MAX_CAS_ATTEMPTS):
        existing, old_oid = load_claim(repo_root, reference, branch_ref)
        if existing is None:
            return (
                {
                    "state": "unclaimed",
                    "branch_ref": branch_ref,
                },
                0,
            )
        if existing["lease_id"] != expected_lease_id:
            return (
                {
                    "state": "mismatch",
                    "reason": "lease_changed",
                    "branch_ref": branch_ref,
                },
                EXIT_MISMATCH,
            )
        ограждение_резервации: tuple[str, str] | None = None
        вершина_выбора = existing.get("selection_head")
        if isinstance(вершина_выбора, str):
            try:
                ограждение_резервации = потребовать_общую_резервацию(
                    repo_root,
                    branch_ref,
                    вершина_выбора,
                    expected_lease_id,
                )
            except НесовпадениеОбщейРезервации:
                return run_mismatch(
                    "general_reservation_changed",
                    branch_ref,
                )
        параметры_ограждения = (
            {
                "ограждающая_ссылка": ограждение_резервации[0],
                "ожидаемый_объект_ограждения": ограждение_резервации[1],
            }
            if ограждение_резервации is not None
            else {}
        )
        if cas_claim_ref(
            repo_root,
            reference,
            old_oid,
            None,
            **параметры_ограждения,
        ):
            return (
                {
                    "state": "released",
                    "branch_ref": branch_ref,
                    "step_id": existing["step_id"],
                    "lease_id": expected_lease_id,
                },
                0,
            )
        if идёт_сброс_очереди(repo_root):
            return run_mismatch("reset_in_progress", branch_ref)
        time.sleep(REF_RETRY_BASE_SECONDS)
    raise ContractError("Исчерпан лимит конкурентных удалений claim.")


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
            cards = load_cards(repo_root)
            records = load_records(repo_root, cards)
            current = active_record(repo_root, records)
            ready_candidates = validate_ready_pool(current)
            payload = {
                "state": "valid",
                "active_branch_ref": current.branch_ref,
                "record_path": current.record_path,
                "project_path": current.project_path,
                "candidate_count": len(current.candidates),
                "ready_count": len(ready_candidates),
                "paused_count": sum(
                    candidate.status == "paused"
                    for candidate in current.candidates
                ),
                "blocked_count": sum(
                    candidate.status == "blocked"
                    for candidate in current.candidates
                ),
            }
            exit_code = 0
        elif args.command == "refresh-card-fences":
            payload = refresh_card_fences(repo_root)
            exit_code = 0
        elif args.command == "show":
            record = active_record(repo_root)
            ready_candidate, selection = select_ready_candidate(
                repo_root,
                record,
            )
            assert_expected_identity(
                record,
                ready_candidate,
                selection,
                args.expected_branch_ref,
                args.expected_step_id,
                args.expected_selection_id,
            )
            if ready_candidate is not None:
                if selection is None:
                    raise ContractError(
                        "Внутренняя ошибка: готовый шаг не имеет selection."
                    )
                payload = {
                    "state": "ready",
                    **ready_candidate.payload(),
                    "selection": selection,
                }
                exit_code = 0
            else:
                payload = {"state": "not_ready", **record.summary_payload()}
                exit_code = EXIT_NOT_READY
        elif args.command == "claim":
            payload, exit_code = claim_step(
                repo_root,
                args.expected_branch_ref,
                args.expected_step_id,
                args.expected_selection_id,
                args.lease_id,
            )
        elif args.command == "bind-run":
            payload, exit_code = bind_run(
                repo_root,
                args.expected_branch_ref,
                args.expected_step_id,
                args.expected_selection_id,
                args.expected_lease_id,
                args.task_id,
            )
        elif args.command == "verify-run":
            payload, exit_code = verify_run(
                repo_root,
                args.expected_branch_ref,
                args.expected_step_id,
                args.expected_selection_id,
                args.expected_lease_id,
                args.task_id,
                args.generation,
            )
        elif args.command == "rearm":
            payload, exit_code = rearm_claim(
                repo_root,
                args.expected_branch_ref,
                args.expected_step_id,
                args.expected_selection_id,
                args.expected_lease_id,
                args.task_id,
                args.generation,
            )
        elif args.command == "claim-status":
            payload, exit_code = claim_status(repo_root, args.branch_ref)
        elif args.command == "release":
            payload, exit_code = release_claim(
                repo_root,
                args.branch_ref,
                args.expected_lease_id,
            )
        else:
            raise ContractError(f"Неизвестная команда: {args.command}.")
    except (ContractError, OSError, ValueError, subprocess.SubprocessError) as error:
        payload = {"state": "invalid", "error": str(error)}
        exit_code = EXIT_INVALID
    emit(payload, args.json)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
