#!/usr/bin/env python3
"""Update per-file Markdown recency metadata and the repository Markdown index."""

from __future__ import annotations

import argparse
import ast
import hashlib
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo


PROJECT_FILES_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-proyektnyiye-fajlyi"
    / "scripts"
)
if str(PROJECT_FILES_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(PROJECT_FILES_SCRIPTS))

from project_files import (
    ProjectFilesError,
    project_markdown_paths,
    safe_project_output_path,
)


MSK = ZoneInfo("Europe/Moscow")
INDEX_PATH = Path("Индексы/markdown-файлы-по-времени-редактирования.md")
RECENCY_BEGIN = "<!-- FUM-MD-RECENCY:BEGIN -->"
RECENCY_END = "<!-- FUM-MD-RECENCY:END -->"
RECENCY_BLOCK_RE = re.compile(
    r"\n?<!-- FUM-MD-RECENCY:BEGIN -->\n"
    r"<!-- last-content-edit: (?P<timestamp>[^>]+) -->\n"
    r"<!-- content-sha256: sha256:(?P<digest>[0-9a-f]{64}) -->\n"
    r"<!-- FUM-MD-RECENCY:END -->\n?$",
    re.MULTILINE,
)
DISPLAY_TIME_RE = re.compile(
    r"^(?P<date>\d{4}-\d{2}-\d{2}) "
    r"(?P<hour>\d{2}):(?P<minute>\d{2}):(?P<second>\d{2}) MSK$"
)
УПРАВЛЯЕМЫЙ_БЛОК_ЗАПУСКОВ = re.compile(
    r"^<!-- FUM-CHECK-RUNS:BEGIN "
    r"(?:состояние=открыт; каталог=материалы/запуски-проверок|"
    r"состояние=закрыт; снимок=материалы/запуски-проверок/снимок\.json; "
    r"sha256=sha256:[0-9a-f]{64}) -->\n"
    r".*?\n"
    r"<!-- FUM-CHECK-RUNS:END -->$",
    re.MULTILINE | re.DOTALL,
)
ЗАМЕСТИТЕЛЬ_УПРАВЛЯЕМОГО_БЛОКА_ЗАПУСКОВ = (
    "<!-- FUM-CHECK-RUNS:MANAGED -->"
)


@dataclass(frozen=True)
class RecencyMetadata:
    timestamp: str
    digest: str


@dataclass(frozen=True)
class MarkdownRecord:
    path: Path
    rel_path: str
    timestamp: str
    digest: str


@dataclass(frozen=True)
class RecencyResult:
    errors: list[str]
    changed_paths: list[Path]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Only validate metadata and index freshness without writing files.",
    )
    parser.add_argument(
        "--now",
        help="Override current time as an ISO-8601 timestamp. Mainly for tests.",
    )
    parser.add_argument(
        "--no-git",
        action="store_true",
        help="Do not use Git status or history while choosing initial timestamps.",
    )
    return parser.parse_args()


def parse_now(value: str | None = None) -> datetime:
    if value is None:
        return datetime.now(MSK)
    parsed = datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=MSK)
    return parsed.astimezone(MSK)


def format_msk(value: datetime) -> str:
    return value.astimezone(MSK).strftime("%Y-%m-%d %H:%M:%S MSK")


def parse_display_time(value: str) -> datetime:
    match = DISPLAY_TIME_RE.fullmatch(value)
    if not match:
        return datetime.min.replace(tzinfo=MSK)
    return datetime(
        int(match.group("date")[:4]),
        int(match.group("date")[5:7]),
        int(match.group("date")[8:10]),
        int(match.group("hour")),
        int(match.group("minute")),
        int(match.group("second")),
        tzinfo=MSK,
    )


def repo_relative(path: Path, repo_root: Path) -> str:
    return path.resolve().relative_to(repo_root.resolve()).as_posix()


def relative_link(target: Path, source: Path, repo_root: Path) -> str:
    return Path(os.path.relpath(target.resolve(), source.parent.resolve())).as_posix()


def canonical_content(text: str) -> str:
    return text if text.endswith("\n") else f"{text}\n"


def content_digest(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def split_recency_block(text: str) -> tuple[str, RecencyMetadata | None, bool]:
    match = RECENCY_BLOCK_RE.search(text)
    if not match:
        has_partial_block = RECENCY_BEGIN in text or RECENCY_END in text
        return text, None, has_partial_block

    content = text[: match.start()] + text[match.end() :]
    metadata = RecencyMetadata(
        timestamp=match.group("timestamp"),
        digest=match.group("digest"),
    )
    return content, metadata, False


def стабильное_содержание_отчёта(
    путь: Path,
    корень_репозитория: Path,
    содержание: str,
) -> tuple[str, bool]:
    части = Path(repo_relative(путь, корень_репозитория)).parts
    if not (
        len(части) == 3
        and части[0] == "Журнал"
        and части[-1] == "отчёт.md"
    ):
        return содержание, False
    число_начал = содержание.count("<!-- FUM-CHECK-RUNS:BEGIN ")
    число_концов = содержание.count("<!-- FUM-CHECK-RUNS:END -->")
    if число_начал == 0 and число_концов == 0:
        return содержание, False
    совпадение = УПРАВЛЯЕМЫЙ_БЛОК_ЗАПУСКОВ.search(содержание)
    if (
        число_начал != 1
        or число_концов != 1
        or совпадение is None
    ):
        return содержание, True
    стабильное = (
        содержание[: совпадение.start()]
        + ЗАМЕСТИТЕЛЬ_УПРАВЛЯЕМОГО_БЛОКА_ЗАПУСКОВ
        + содержание[совпадение.end() :]
    )
    return canonical_content(стабильное), False


def render_recency_block(timestamp: str, digest: str) -> str:
    return "\n".join(
        [
            RECENCY_BEGIN,
            f"<!-- last-content-edit: {timestamp} -->",
            f"<!-- content-sha256: sha256:{digest} -->",
            RECENCY_END,
            "",
        ]
    )


def attach_recency_block(content: str, timestamp: str, digest: str) -> str:
    return f"{canonical_content(content)}\n{render_recency_block(timestamp, digest)}"


def find_markdown_paths(repo_root: Path) -> list[Path]:
    paths = set(project_markdown_paths(repo_root))
    paths.add(safe_project_output_path(repo_root / INDEX_PATH, repo_root))
    return sorted(paths)


def decode_git_path(path: str) -> str:
    value = path.strip()
    if not (value.startswith('"') and value.endswith('"')):
        return value

    try:
        decoded = ast.literal_eval(value)
    except (SyntaxError, ValueError):
        return value.strip('"')

    try:
        return decoded.encode("latin-1").decode("utf-8")
    except UnicodeError:
        return decoded


def parse_git_status_paths(status_text: str) -> set[str]:
    paths: set[str] = set()
    for line in status_text.splitlines():
        if not line.strip():
            continue
        path = line[3:] if len(line) > 3 else line
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.add(Path(decode_git_path(path)).as_posix())
    return paths


def git_dirty_paths(repo_root: Path, use_git: bool) -> set[str]:
    if not use_git or not (repo_root / ".git").exists():
        return set()
    result = subprocess.run(
        [
            "git",
            "-C",
            str(repo_root),
            "-c",
            "core.quotepath=false",
            "status",
            "--short",
            "--untracked-files=all",
        ],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        return set()
    return parse_git_status_paths(result.stdout)


def git_last_commit_time(path: Path, repo_root: Path, use_git: bool) -> str | None:
    if not use_git or not (repo_root / ".git").exists():
        return None
    result = subprocess.run(
        [
            "git",
            "-C",
            str(repo_root),
            "log",
            "-1",
            "--format=%cI",
            "--",
            repo_relative(path, repo_root),
        ],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        return None
    value = result.stdout.strip()
    if not value:
        return None
    try:
        return format_msk(datetime.fromisoformat(value))
    except ValueError:
        return None


def choose_initial_timestamp(
    path: Path,
    repo_root: Path,
    dirty_paths: set[str],
    now_label: str,
    use_git: bool,
) -> str:
    rel_path = repo_relative(path, repo_root)
    if rel_path in dirty_paths:
        return now_label
    return git_last_commit_time(path, repo_root, use_git) or now_label


def process_markdown_file(
    path: Path,
    repo_root: Path,
    dirty_paths: set[str],
    now_label: str,
    check: bool,
    use_git: bool,
) -> tuple[MarkdownRecord | None, list[str], bool]:
    errors: list[str] = []
    if not path.exists():
        return None, errors, False

    original_text = read_text(path)
    content, metadata, malformed = split_recency_block(original_text)
    content = canonical_content(content)
    полный_хэш = content_digest(content)
    стабильное_содержание, повреждённый_блок_запусков = (
        стабильное_содержание_отчёта(path, repo_root, content)
    )
    стабильный_хэш = content_digest(стабильное_содержание)
    rel_path = repo_relative(path, repo_root)

    if malformed:
        errors.append(f"malformed recency metadata: {rel_path}")
    if повреждённый_блок_запусков:
        errors.append(f"malformed managed test-run block: {rel_path}")

    if metadata is None:
        if check:
            errors.append(f"missing recency metadata: {rel_path}")
        timestamp = choose_initial_timestamp(
            path,
            repo_root,
            dirty_paths,
            now_label,
            use_git,
        )
    elif metadata.digest not in {полный_хэш, стабильный_хэш}:
        if check:
            errors.append(f"stale recency metadata: {rel_path}")
        timestamp = now_label
    else:
        timestamp = metadata.timestamp

    digest = (
        полный_хэш
        if metadata is not None and metadata.digest == полный_хэш
        else стабильный_хэш
    )

    record = MarkdownRecord(path=path, rel_path=rel_path, timestamp=timestamp, digest=digest)
    expected_text = attach_recency_block(content, timestamp, digest)
    changed = expected_text != original_text
    if changed and not check:
        path.write_text(expected_text, encoding="utf-8")
    return record, errors, changed


def record_sort_key(record: MarkdownRecord) -> tuple[datetime, str]:
    return parse_display_time(record.timestamp), record.rel_path


def render_aligned_markdown_table(headers: list[str], rows: list[list[str]]) -> list[str]:
    widths = [
        max(3, len(header), *(len(row[index]) for row in rows))
        for index, header in enumerate(headers)
    ]

    def render_row(cells: list[str]) -> str:
        padded = [
            f"{cell:<{width}}"
            for cell, width in zip(cells, widths, strict=True)
        ]
        return f"| {' | '.join(padded)} |"

    separator = [("-" * width) for width in widths]
    return [render_row(headers), render_row(separator), *(render_row(row) for row in rows)]


def render_index_body(records: list[MarkdownRecord], index_path: Path, repo_root: Path) -> str:
    rows = []
    for record in sorted(records, key=record_sort_key, reverse=True):
        link = relative_link(record.path, index_path, repo_root)
        rows.append([f"[{record.rel_path}]({link})", record.timestamp])

    lines = [
        "# Markdown-файлы по времени редактирования",
        "",
        "Этот индекс строится локальной автоматизацией `fum-svezhestj-markdown`. Он перечисляет все Markdown-файлы [памяти FUM](../Глоссарий/память-FUM.md) от свежих к более старым по метке последнего содержательного редактирования.",
        "",
        "Служебная метка `FUM-MD-RECENCY` хранится в конце каждого `.md`-файла и не учитывается при расчёте хэша содержательного текста.",
        "В каноническом `Журнал/<сессия>/отчёт.md` единственный управляемый блок `FUM-CHECK-RUNS` тоже не изменяет метку свежести.",
        "",
        *render_aligned_markdown_table(
            ["Файл", "Последнее содержательное редактирование"],
            rows,
        ),
    ]
    return "\n".join(lines) + "\n"


def process_index_file(
    records_without_index: list[MarkdownRecord],
    repo_root: Path,
    now_label: str,
    check: bool,
) -> tuple[MarkdownRecord, list[str], bool]:
    index_path = safe_project_output_path(repo_root / INDEX_PATH, repo_root)
    rel_path = INDEX_PATH.as_posix()
    errors: list[str] = []
    original_text = read_text(index_path) if index_path.exists() else ""
    existing_content, metadata, malformed = split_recency_block(original_text)
    existing_content = canonical_content(existing_content) if original_text else ""

    if malformed:
        errors.append(f"malformed recency metadata: {rel_path}")

    placeholder_timestamp = metadata.timestamp if metadata else now_label
    placeholder = MarkdownRecord(
        path=index_path,
        rel_path=rel_path,
        timestamp=placeholder_timestamp,
        digest="",
    )
    body = render_index_body([*records_without_index, placeholder], index_path, repo_root)
    digest = content_digest(body)

    index_is_current = (
        metadata is not None
        and metadata.digest == digest
        and existing_content == body
    )
    if not index_is_current:
        if check:
            errors.append(f"stale recency index: {rel_path}")
        placeholder = MarkdownRecord(
            path=index_path,
            rel_path=rel_path,
            timestamp=now_label,
            digest="",
        )
        body = render_index_body([*records_without_index, placeholder], index_path, repo_root)
        digest = content_digest(body)

    record = MarkdownRecord(
        path=index_path,
        rel_path=rel_path,
        timestamp=placeholder.timestamp,
        digest=digest,
    )
    expected_text = attach_recency_block(body, record.timestamp, digest)
    changed = expected_text != original_text
    if changed and not check:
        index_path.parent.mkdir(parents=True, exist_ok=True)
        index_path.write_text(expected_text, encoding="utf-8")
    return record, errors, changed


def update_repository(
    repo_root: str | Path,
    now: datetime | None = None,
    check: bool = False,
    use_git: bool = True,
) -> RecencyResult:
    root = Path(repo_root).resolve()
    now_label = format_msk(now or parse_now())
    dirty_paths = git_dirty_paths(root, use_git)
    errors: list[str] = []
    changed_paths: list[Path] = []
    records: list[MarkdownRecord] = []
    try:
        markdown_paths = find_markdown_paths(root)
        index_path = safe_project_output_path(root / INDEX_PATH, root)
    except ProjectFilesError as exc:
        return RecencyResult(
            errors=[f"project Markdown inventory failed: {exc}"],
            changed_paths=[],
        )

    for path in markdown_paths:
        if path == index_path:
            continue
        record, file_errors, changed = process_markdown_file(
            path,
            root,
            dirty_paths,
            now_label,
            check,
            use_git,
        )
        errors.extend(file_errors)
        if record is not None:
            records.append(record)
        if changed:
            changed_paths.append(path)

    try:
        index_record, index_errors, index_changed = process_index_file(
            records,
            root,
            now_label,
            check,
        )
    except ProjectFilesError as exc:
        return RecencyResult(
            errors=[*errors, f"project output path check failed: {exc}"],
            changed_paths=sorted(changed_paths),
        )
    errors.extend(index_errors)
    if index_changed:
        changed_paths.append(index_record.path)

    return RecencyResult(errors=errors, changed_paths=sorted(changed_paths))


def main() -> int:
    args = parse_args()
    result = update_repository(
        args.repo_root,
        now=parse_now(args.now),
        check=args.check,
        use_git=not args.no_git,
    )
    if result.errors:
        for error in result.errors:
            print(error, file=sys.stderr)
        return 1
    if args.check:
        print("md recency check passed")
    else:
        print(f"md recency updated: {len(result.changed_paths)} file(s) changed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
