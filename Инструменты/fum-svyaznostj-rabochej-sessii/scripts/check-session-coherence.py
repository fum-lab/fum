#!/usr/bin/env python3
"""Check that a FUM working session is linked and publication-clean."""

from __future__ import annotations

import argparse
import ast
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from decimal import Decimal, localcontext
from pathlib import Path, PurePosixPath, PureWindowsPath
from urllib.parse import unquote


PROJECT_FILES_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-proyektnyiye-fajlyi"
    / "scripts"
)
if str(PROJECT_FILES_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(PROJECT_FILES_SCRIPTS))

REQUEST_FOLDER_LAYOUT_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-struktura-papok-zaprosov"
    / "scripts"
)
if str(REQUEST_FOLDER_LAYOUT_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(REQUEST_FOLDER_LAYOUT_SCRIPTS))

from project_files import (
    ProjectFilesError,
    is_structurally_excluded_path,
    project_markdown_paths,
)

try:
    from request_folder_layout import (
        LayoutError,
        МАРКЕР_НЕЗАПОЛНЕННОГО_ШАБЛОНА,
        validate_layout,
    )
except ModuleNotFoundError as exc:  # Keep isolated checker fixtures testable.
    if exc.name != "request_folder_layout":
        raise
    LayoutError = RuntimeError
    МАРКЕР_НЕЗАПОЛНЕННОГО_ШАБЛОНА = "<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->"
    validate_layout = None


REQUEST_STEM_RE = re.compile(
    r"^(?P<date>\d{4}-\d{2}-\d{2})_"
    r"(?P<hour>\d{2})-(?P<minute>\d{2})-(?P<second>\d{2})_MSK"
    r"(?:_(?P<title>[0-9A-Za-zА-Яа-яЁё][0-9A-Za-zА-Яа-яЁё-]*))?$"
)
JOURNAL_DIRECTORY = "Журнал"
REQUEST_FILENAME = "запрос.md"
REPORT_FILENAME = "отчёт.md"
REQUEST_TITLE_INFINITIVE_RULE_START = (2026, 7, 2, 23, 1, 25)
QUALIFIED_OPENAI_TOOL_VERSION_RULE_START = (2026, 7, 10, 5, 59, 58)
CODEX_THREAD_ID_RULE_START = (2026, 7, 14, 2, 31, 47)
SESSION_TIME_TOOL_RULE_START = (2026, 7, 17, 10, 25, 41)
JOURNAL_TIME_PROFILE_RULE_START = (2026, 7, 23, 14, 47, 43)
JOURNAL_DIRECT_CHECK_RUNS_RULE_START = (2026, 7, 27, 16, 12, 29)
RUSSIAN_INFINITIVE_ENDINGS = ("ться", "тись", "чься", "ть", "ти", "чь")
TITLE_TOKEN_REPLACEMENTS = {
    "api": "API",
    "chatgpt": "ChatGPT",
    "cli": "CLI",
    "codex": "Codex",
    "fum": "FUM",
    "git": "Git",
    "github": "GitHub",
    "json": "JSON",
    "llm": "LLM",
    "mcp": "MCP",
    "md": "MD",
    "msk": "MSK",
    "obsidian": "Obsidian",
    "tdd": "TDD",
    "url": "URL",
    "yaml": "YAML",
}
MARKDOWN_LINK_RE = re.compile(r"!?\[([^\]\n]+)\]\(([^)\n]+)\)")
HEADING_RE = re.compile(r"^## .+$", re.MULTILINE)
PROVENANCE_LABEL_RE = re.compile(
    r"^(?:##\s+)?(?:"
    r"Источники требований|Источники|Опорные документы|"
    r"Опорные материалы|Внешний материал|Затронутая документация"
    r")\s*:?\s*$"
)
USER_META_REQUEST_RE = re.compile(
    r"\b(?:"
    r"пользователь\s+"
    r"(?:спросил[аи]?|уточнил[аи]?|ответил[аи]?|попросил[аи]?|"
    r"проверил[аи]?|подтвердил[аи]?|указал[аи]?|сказал[аи]?|заметил[аи]?)"
    r"|(?:вопрос|уточнение|ответ|проверка)\s+пользователя"
    r")\b",
    re.IGNORECASE,
)
META_RULE_CONTEXT_RE = re.compile(
    r"(?:"
    r"мета-запрос\w*|правил\w*|поряд\w*|практик\w*|"
    r"памят[ьи]\s+FUM|рабоч\w*\s+сесси\w*|"
    r"Журнал/[^\s`]+/запрос\.md|папк\w*\s+запрос\w*|"
    r"AGENTS\.md|ведени\w*\s+памят\w*|ведени\w*\s+репозитори\w*|"
    r"хранени\w*\s+источник\w*|состав\w*\s+артефакт\w*"
    r")",
    re.IGNORECASE,
)
MERMAID_LABEL_MARKDOWN_LIST_RE = re.compile(
    r"""(?x)
    (?:^|[\s;])
    [A-Za-z][A-Za-z0-9_-]*
    (?:\s*@\{[^}\n]*\})?
    \s*
    (?:\[\[?|\(\(?|\{)
    \s*
    ["']?
    \s*
    (?:\d+[.)]|[-*+])\s+
    """
)
UNQUALIFIED_OPENAI_VERSION_FALLBACK_RE = re.compile(
    r"^\s*-\s+`?\s*(?:ChatGPT\s*/\s*Codex|ChatGPT|Codex)\s*`?\s*"
    r"[-–—]\s+"
    r"версия не раскрывается средой\b",
    re.IGNORECASE | re.MULTILINE,
)
DELETED_AFFECTED_PATH_RE = re.compile(
    r"^\s*-\s+Удалённый файл:\s+`([^`\n]+)`\s*$",
    re.MULTILINE,
)
DELETED_AFFECTED_SUBTREE_RE = re.compile(
    r"^\s*-\s+Удалённое поддерево:\s+`([^`\n]+)`\s*$",
    re.MULTILINE,
)
DELETED_DIRECT_FILES_DIRECTORY_RE = re.compile(
    r"^\s*-\s+Удалённые непосредственные файлы каталога:\s+`([^`\n]+)`\s*$",
    re.MULTILINE,
)
CODEX_THREAD_ID_LINE_RE = re.compile(
    r"^Codex-Thread-ID:[ \t]+(\S+)[ \t]*$",
)
CODEX_THREAD_ID_TRAILER_LINE_RE = re.compile(
    r"^Codex-Thread-ID:[ \t]+(\S+)[ \t]*$",
    re.IGNORECASE,
)
CANONICAL_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
)
TRAILER_LINE_RE = re.compile(
    r"^[A-Za-z0-9][A-Za-z0-9-]*:[ \t]+\S(?:.*\S)?[ \t]*$"
)
JOURNAL_TIME_PROFILE_HEADING = "Профиль времени выполнения"
JOURNAL_TIME_PROFILE_COLUMNS = (
    "Стадия",
    "Длительность",
    "Границы и способ измерения",
)
MARKDOWN_TABLE_SEPARATOR_RE = re.compile(r"^:?-{3,}:?$")
MARKDOWN_TILDE_FENCE_MARKER = chr(126)
JOURNAL_TIME_PROFILE_BOUNDARY_RE = re.compile(
    r"^Граница профиля:\s+\S.*$"
)
JOURNAL_DIRECT_CHECK_RUNS_HEADING = "Прямые запуски проверок"
JOURNAL_DIRECT_CHECK_RUN_COLUMNS = (
    "Вызов",
    "Длительность",
    "Результат",
)
JOURNAL_DIRECT_CHECK_RUN_SECONDS_RE = re.compile(
    r"^(?P<seconds>(?:0|[1-9]\d*)(?:[.,]\d+)?)\s+с$"
)
JOURNAL_DIRECT_CHECK_RUN_RESULT_RE = re.compile(
    r"^(?:успешно|неуспешно|прервано|не завершено)(?:\s+\S.*)?$"
)
JOURNAL_DIRECT_CHECK_RUN_TOTAL_PREFIX = (
    "Общее время прямых запусков проверок:"
)
JOURNAL_DIRECT_CHECK_RUN_TOTAL_RE = re.compile(
    rf"^{re.escape(JOURNAL_DIRECT_CHECK_RUN_TOTAL_PREFIX)}\s+"
    r"(?P<seconds>(?:0|[1-9]\d*)(?:[.,]\d+)?)\s+с\.?$"
)


@dataclass(frozen=True)
class MarkdownLink:
    source: Path
    line: int
    target: str


@dataclass(frozen=True)
class MarkdownFence:
    marker: str
    length: int
    info: str


class AffectedPaths(set[Path]):
    """Exact affected paths plus explicitly scoped directory permissions."""

    def __init__(self) -> None:
        super().__init__()
        self.existing_directories: set[Path] = set()
        self.deleted_direct_files_directories: set[Path] = set()
        self.deleted_subtrees: set[Path] = set()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--request",
        required=True,
        type=Path,
        help=(
            "Session request file Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_slug]>/"
            "запрос.md, relative to the repository root."
        ),
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--skip-git-status",
        action="store_true",
        help="Validate files and links without checking Git status.",
    )
    parser.add_argument(
        "--commit-message-file",
        type=Path,
        help=(
            "Commit message file to validate before git commit. "
            "The final body paragraph must contain the matching Codex-Thread-ID trailer."
        ),
    )
    parser.add_argument(
        "--codex-thread-id",
        help=(
            "Expected root Codex thread identifier. Pass the primary session's "
            "CODEX_THREAD_ID so a subagent identifier cannot be recorded by mistake."
        ),
    )
    return parser.parse_args()


def absolute_path(path: str | Path, repo_root: Path) -> Path:
    value = Path(path)
    if value.is_absolute():
        return value.resolve()
    return (repo_root / value).resolve()


def repo_relative(path: str | Path, repo_root: Path) -> str:
    absolute = absolute_path(path, repo_root)
    return absolute.relative_to(repo_root.resolve()).as_posix()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def request_match(path: Path) -> re.Match[str] | None:
    if path.name != REQUEST_FILENAME:
        return None
    return REQUEST_STEM_RE.fullmatch(path.parent.name)


def request_datetime_key(match: re.Match[str]) -> tuple[int, int, int, int, int, int]:
    year, month, day = (int(part) for part in match.group("date").split("-"))
    return (
        year,
        month,
        day,
        int(match.group("hour")),
        int(match.group("minute")),
        int(match.group("second")),
    )


def slug_starts_with_infinitive_verb(slug: str) -> bool:
    first_word = slug.split("-", 1)[0].lower()
    if not re.search(r"[А-Яа-яЁё]", first_word):
        return False
    return first_word.endswith(RUSSIAN_INFINITIVE_ENDINGS)


def validate_request_filename_title(path: Path) -> list[str]:
    match = request_match(path)
    if not match:
        return []

    slug = match.group("title")
    if not slug:
        return []

    if request_datetime_key(match) < REQUEST_TITLE_INFINITIVE_RULE_START:
        return []

    if slug_starts_with_infinitive_verb(slug):
        return []

    return [f"request folder title must start with an infinitive verb: {slug}"]


def is_request_file(path: Path, repo_root: Path) -> bool:
    try:
        relative = path.resolve().relative_to(repo_root.resolve())
    except ValueError:
        return False
    return (
        len(relative.parts) == 3
        and relative.parts[0] == JOURNAL_DIRECTORY
        and relative.parts[2] == REQUEST_FILENAME
        and REQUEST_STEM_RE.fullmatch(relative.parts[1]) is not None
    )


def request_label(path: Path) -> str:
    match = request_match(path)
    if not match:
        return path.name
    date = match.group("date")
    hour = match.group("hour")
    minute = match.group("minute")
    second = match.group("second")
    label = f"{date} {hour}:{minute}:{second} MSK"
    title = request_title(path)
    if title is not None:
        label = f"{label} - {title}"
    return label


def request_title(path: Path) -> str | None:
    match = request_match(path)
    if not match:
        return None

    slug = match.group("title")
    if not slug:
        return None

    words = [
        TITLE_TOKEN_REPLACEMENTS.get(word.lower(), word)
        for word in slug.split("-")
    ]
    title = " ".join(words)
    first_word = words[0] if words else ""
    if first_word.lower() not in TITLE_TOKEN_REPLACEMENTS and title:
        title = title[0].upper() + title[1:]
    return title


def expected_request_heading(path: Path) -> str:
    return f"# Исходный запрос {request_label(path)}"


def expected_journal_heading(path: Path) -> str:
    return f"# Отчёт {request_label(path)}"


def section_body(text: str, heading: str) -> str | None:
    pattern = re.compile(rf"^## {re.escape(heading)}\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return None
    start = match.end()
    next_heading = HEADING_RE.search(text, start)
    end = next_heading.start() if next_heading else len(text)
    return text[start:end]


def request_files(
    repo_root: Path,
    markdown_paths: set[Path] | None = None,
) -> list[Path]:
    journal_dir = repo_root / JOURNAL_DIRECTORY
    if not journal_dir.exists():
        return []
    candidates = markdown_paths
    if candidates is None:
        candidates = set(project_markdown_paths(repo_root))
    return sorted(
        (
            path
            for path in candidates
            if path.name == REQUEST_FILENAME
            if path.parent.parent == journal_dir.resolve()
            if REQUEST_STEM_RE.fullmatch(path.parent.name)
        ),
        key=lambda path: path.parent.name,
    )


def contains_request_link(
    section: str,
    label: str,
    target: Path,
    source: Path,
    repo_root: Path,
) -> bool:
    for line_number, line in enumerate(section.splitlines(), start=1):
        for match in MARKDOWN_LINK_RE.finditer(line):
            if label not in match.group(1):
                continue
            link = MarkdownLink(
                source=source,
                line=line_number,
                target=strip_link_title(match.group(2)),
            )
            resolved = resolve_markdown_target(link, repo_root)
            if resolved is not None and resolved == target.resolve():
                return True
    return False


def validate_navigation(
    repo_root: Path,
    request_path: Path,
    text: str,
    markdown_paths: set[Path] | None = None,
) -> list[str]:
    errors: list[str] = []
    navigation = section_body(text, "Навигация по запросам")
    if navigation is None:
        return ["missing section: Навигация по запросам"]

    files = request_files(repo_root, markdown_paths)
    try:
        index = [path.resolve() for path in files].index(request_path.resolve())
    except ValueError:
        return [
            "request file is not a canonical Journal session request: "
            f"{repo_relative(request_path, repo_root)}"
        ]

    previous_file = files[index - 1] if index > 0 else None
    next_file = files[index + 1] if index + 1 < len(files) else None

    if previous_file is None:
        if "Предыдущий запрос: нет" not in navigation:
            errors.append("request navigation must state previous request: нет")
    elif not contains_request_link(
        navigation,
        request_label(previous_file),
        previous_file,
        request_path,
        repo_root,
    ):
        errors.append(
            "missing previous request navigation link: "
            f"{previous_file.parent.name}/{previous_file.name}"
        )

    if next_file is None:
        if "Следующий запрос: нет" not in navigation:
            errors.append("request navigation must state next request: нет")
    elif not contains_request_link(
        navigation,
        request_label(next_file),
        next_file,
        request_path,
        repo_root,
    ):
        errors.append(
            "missing next request navigation link: "
            f"{next_file.parent.name}/{next_file.name}"
        )

    if previous_file is not None:
        previous_text = read_text(previous_file)
        previous_navigation = section_body(previous_text, "Навигация по запросам") or ""
        if not contains_request_link(
            previous_navigation,
            request_label(request_path),
            request_path,
            previous_file,
            repo_root,
        ):
            errors.append(
                "previous request does not link forward to current request: "
                f"{previous_file.parent.name}/{previous_file.name}"
            )

    if next_file is not None:
        next_text = read_text(next_file)
        next_navigation = section_body(next_text, "Навигация по запросам") or ""
        if not contains_request_link(
            next_navigation,
            request_label(request_path),
            request_path,
            next_file,
            repo_root,
        ):
            errors.append(
                "next request does not link back to current request: "
                f"{next_file.parent.name}/{next_file.name}"
            )

    return errors


def expected_journal_path(request_path: Path, repo_root: Path) -> Path:
    del repo_root
    return request_path.parent / REPORT_FILENAME


def relative_link(target: Path, source: Path, repo_root: Path) -> str:
    target_abs = absolute_path(target, repo_root)
    return Path(os.path.relpath(target_abs, source.parent)).as_posix()


def markdown_table_cells(line: str) -> tuple[str, ...] | None:
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        return None

    trailing_backslashes = 0
    for character in reversed(stripped[:-1]):
        if character != "\\":
            break
        trailing_backslashes += 1
    if trailing_backslashes % 2:
        return None

    cells: list[str] = []
    current: list[str] = []
    backslash_run = 0
    for character in stripped[1:-1]:
        if character == "|" and backslash_run % 2 == 0:
            cells.append("".join(current).strip())
            current = []
        else:
            current.append(character)
        backslash_run = backslash_run + 1 if character == "\\" else 0
    cells.append("".join(current).strip())
    return tuple(cells)


def strip_markdown_html_comments(
    line: str,
    in_comment: bool,
) -> tuple[str, bool]:
    visible: list[str] = []
    cursor = 0
    while cursor < len(line):
        if in_comment:
            comment_end = line.find("-->", cursor)
            if comment_end < 0:
                return "".join(visible), True
            cursor = comment_end + len("-->")
            in_comment = False
            continue

        comment_start = line.find("<!--", cursor)
        if comment_start < 0:
            visible.append(line[cursor:])
            break
        visible.append(line[cursor:comment_start])
        cursor = comment_start + len("<!--")
        in_comment = True
    return "".join(visible), in_comment


def markdown_structural_text(text: str) -> str:
    structural_lines: list[str] = []
    fence: MarkdownFence | None = None
    in_html_comment = False

    for raw_line in text.splitlines():
        if fence is not None:
            if closes_markdown_fence(raw_line, fence):
                fence = None
            structural_lines.append("")
            continue

        visible_line, in_html_comment = strip_markdown_html_comments(
            raw_line,
            in_html_comment,
        )
        fence = opening_markdown_fence(visible_line)
        if fence is not None:
            structural_lines.append("")
            continue
        structural_lines.append(visible_line)

    return "\n".join(structural_lines)


def validate_journal_time_profile(text: str) -> list[str]:
    profile = section_body(
        markdown_structural_text(text),
        JOURNAL_TIME_PROFILE_HEADING,
    )
    if profile is None:
        return [f"missing journal section: {JOURNAL_TIME_PROFILE_HEADING}"]

    lines = profile.splitlines()
    header_index: int | None = None
    for index, line in enumerate(lines):
        if markdown_table_cells(line) == JOURNAL_TIME_PROFILE_COLUMNS:
            header_index = index
            break

    columns = " | ".join(JOURNAL_TIME_PROFILE_COLUMNS)
    if header_index is None:
        return [f"journal time profile must contain table columns: {columns}"]
    if header_index + 1 >= len(lines):
        return ["journal time profile table is missing its separator row"]

    separator = markdown_table_cells(lines[header_index + 1])
    if (
        separator is None
        or len(separator) != len(JOURNAL_TIME_PROFILE_COLUMNS)
        or not all(MARKDOWN_TABLE_SEPARATOR_RE.fullmatch(cell) for cell in separator)
    ):
        return ["journal time profile table has an invalid separator row"]

    stage_rows: list[tuple[str, ...]] = []
    last_stage_index: int | None = None
    for line_index, line in enumerate(
        lines[header_index + 2 :],
        start=header_index + 2,
    ):
        cells = markdown_table_cells(line)
        if cells is None:
            if stage_rows and line.strip():
                break
            continue
        if len(cells) != len(JOURNAL_TIME_PROFILE_COLUMNS):
            continue
        stage_rows.append(cells)
        last_stage_index = line_index

    errors: list[str] = []
    if len(stage_rows) < 2:
        errors.append("journal time profile must contain at least two stage rows")
    for row_index, row in enumerate(stage_rows, start=1):
        if any(not cell for cell in row):
            errors.append(
                f"journal time profile stage row {row_index} contains an empty cell"
            )
    boundary_search_start = (
        last_stage_index + 1
        if last_stage_index is not None
        else header_index + 2
    )
    if not any(
        JOURNAL_TIME_PROFILE_BOUNDARY_RE.fullmatch(line.strip())
        for line in lines[boundary_search_start:]
    ):
        errors.append(
            "journal time profile must contain a non-empty boundary line "
            "after its table: Граница профиля:"
        )
    return errors


def journal_seconds(value: str) -> Decimal | None:
    match = JOURNAL_DIRECT_CHECK_RUN_SECONDS_RE.fullmatch(value)
    if match is None:
        return None
    return Decimal(match.group("seconds").replace(",", "."))


def format_journal_seconds(value: Decimal) -> str:
    rendered = format(value, "f")
    if "." in rendered:
        rendered = rendered.rstrip("0").rstrip(".")
    return "0" if rendered == "-0" else rendered


def sum_journal_seconds(values: list[Decimal]) -> Decimal:
    if not values:
        return Decimal(0)

    minimum_exponent = min(value.as_tuple().exponent for value in values)
    maximum_adjusted = max(value.adjusted() for value in values)
    integer_places = max(1, maximum_adjusted + 1)
    fractional_places = max(0, -minimum_exponent)
    carry_places = len(str(len(values)))
    with localcontext() as context:
        context.prec = integer_places + fractional_places + carry_places
        return sum(values, start=Decimal(0))


def validate_journal_direct_check_runs(text: str) -> list[str]:
    profile = section_body(
        markdown_structural_text(text),
        JOURNAL_TIME_PROFILE_HEADING,
    )
    if profile is None:
        return []

    lines = profile.splitlines()
    subsection_heading = f"### {JOURNAL_DIRECT_CHECK_RUNS_HEADING}"
    heading_indexes = [
        index
        for index, line in enumerate(lines)
        if line.strip() == subsection_heading
    ]
    if not heading_indexes:
        return [
            "missing journal time profile subsection: "
            f"{JOURNAL_DIRECT_CHECK_RUNS_HEADING}"
        ]
    if len(heading_indexes) != 1:
        return [
            "journal time profile must contain exactly one subsection: "
            f"{JOURNAL_DIRECT_CHECK_RUNS_HEADING}"
        ]

    subsection_start = heading_indexes[0] + 1
    subsection_end = len(lines)
    for index in range(subsection_start, len(lines)):
        if re.match(r"^#{2,3}\s+", lines[index].strip()):
            subsection_end = index
            break
    subsection = lines[subsection_start:subsection_end]

    table_header_indexes = [
        index
        for index, line in enumerate(subsection)
        if markdown_table_cells(line) == JOURNAL_DIRECT_CHECK_RUN_COLUMNS
    ]
    columns = " | ".join(JOURNAL_DIRECT_CHECK_RUN_COLUMNS)
    if not table_header_indexes:
        return [f"journal direct check runs must contain table columns: {columns}"]
    if len(table_header_indexes) != 1:
        return ["journal direct check runs must contain exactly one invocation table"]

    header_index = table_header_indexes[0]
    if header_index + 1 >= len(subsection):
        return ["journal direct check run table is missing its separator row"]
    separator = markdown_table_cells(subsection[header_index + 1])
    if (
        separator is None
        or len(separator) != len(JOURNAL_DIRECT_CHECK_RUN_COLUMNS)
        or not all(MARKDOWN_TABLE_SEPARATOR_RE.fullmatch(cell) for cell in separator)
    ):
        return ["journal direct check run table has an invalid separator row"]

    rows: list[tuple[str, ...]] = []
    table_end = header_index + 2
    for line_index in range(header_index + 2, len(subsection)):
        cells = markdown_table_cells(subsection[line_index])
        if cells is None:
            table_end = line_index
            break
        rows.append(cells)
        table_end = line_index + 1

    errors: list[str] = []
    if not rows:
        errors.append(
            "journal direct check run table must contain at least one invocation row"
        )

    durations: list[Decimal] = []
    all_durations_valid = True
    for row_index, row in enumerate(rows, start=1):
        if len(row) != len(JOURNAL_DIRECT_CHECK_RUN_COLUMNS):
            errors.append(
                f"journal direct check run row {row_index} must contain exactly "
                f"{len(JOURNAL_DIRECT_CHECK_RUN_COLUMNS)} cells"
            )
            all_durations_valid = False
            continue
        invocation, duration, result = row
        if not invocation:
            errors.append(
                f"journal direct check run row {row_index} has an empty invocation"
            )
        parsed_duration = journal_seconds(duration)
        if parsed_duration is None:
            errors.append(
                f"journal direct check run row {row_index} has invalid duration: "
                f"{duration}"
            )
            all_durations_valid = False
        else:
            durations.append(parsed_duration)
        if not JOURNAL_DIRECT_CHECK_RUN_RESULT_RE.fullmatch(result):
            errors.append(
                f"journal direct check run row {row_index} has invalid result status: "
                f"{result}"
            )

    total_lines = [
        line.strip()
        for line in subsection[table_end:]
        if line.strip().startswith(JOURNAL_DIRECT_CHECK_RUN_TOTAL_PREFIX)
    ]
    if len(total_lines) != 1:
        errors.append(
            "journal direct check runs must contain exactly one total line: "
            f"{JOURNAL_DIRECT_CHECK_RUN_TOTAL_PREFIX}"
        )
        return errors

    total_match = JOURNAL_DIRECT_CHECK_RUN_TOTAL_RE.fullmatch(total_lines[0])
    if total_match is None:
        errors.append(
            "journal direct check run total must use non-negative seconds: "
            f"{total_lines[0]}"
        )
        return errors

    total = Decimal(total_match.group("seconds").replace(",", "."))
    if rows and all_durations_valid:
        expected_total = sum_journal_seconds(durations)
        if total != expected_total:
            errors.append(
                "journal direct check run total must equal the sum of row durations: "
                f"expected {format_journal_seconds(expected_total)} с, "
                f"got {format_journal_seconds(total)} с"
            )
    return errors


def validate_journal(repo_root: Path, request_path: Path) -> list[str]:
    errors: list[str] = []
    report = expected_journal_path(request_path, repo_root)
    if not report.exists():
        return [f"missing sibling report file: {repo_relative(report, repo_root)}"]

    text = read_text(report)
    heading = expected_journal_heading(request_path)
    if not text.startswith(f"{heading}\n"):
        errors.append(f"report must start with heading: {heading}")

    request_link = relative_link(request_path, report, repo_root)
    if request_link not in text:
        errors.append(
            f"report does not link to sibling request: {repo_relative(request_path, repo_root)}"
        )
    match = request_match(request_path)
    if (
        match is not None
        and request_datetime_key(match) >= JOURNAL_TIME_PROFILE_RULE_START
    ):
        errors.extend(validate_journal_time_profile(text))
        if request_datetime_key(match) >= JOURNAL_DIRECT_CHECK_RUNS_RULE_START:
            errors.extend(validate_journal_direct_check_runs(text))
    return errors


def validate_request_folder_layout(repo_root: Path) -> list[str]:
    """Validate the global request layout, preferring its dedicated automation."""

    root = repo_root.resolve()
    if validate_layout is not None:
        try:
            validate_layout(root)
        except LayoutError as exc:
            return [f"request folder layout is invalid: {exc}"]
        return []

    errors: list[str] = []
    legacy_requests = root / "Запросы"
    if legacy_requests.exists():
        errors.append("legacy Запросы/ directory must be absent")

    journal = root / JOURNAL_DIRECTORY
    if not journal.is_dir():
        return errors + ["missing Журнал/ directory"]

    for top_level_markdown in sorted(journal.glob("*.md")):
        if top_level_markdown.name != "README.md":
            errors.append(
                "only Журнал/README.md may be a top-level Markdown file: "
                f"{top_level_markdown.name}"
            )

    for session_dir in sorted(path for path in journal.iterdir() if path.is_dir()):
        if REQUEST_STEM_RE.fullmatch(session_dir.name) is None:
            errors.append(
                "request folder must start with YYYY-MM-DD_HH-MM-SS_MSK: "
                f"{session_dir.name}"
            )
            continue
        for required_name in (REQUEST_FILENAME, REPORT_FILENAME):
            if not (session_dir / required_name).is_file():
                errors.append(
                    f"request folder is missing {required_name}: {session_dir.name}"
                )
        materials = session_dir / "материалы"
        if materials.exists() and not materials.is_dir():
            errors.append(
                f"request materials must be a directory: {session_dir.name}/материалы"
            )
    return errors


def validate_used_tools_section(
    text: str,
    request_path: Path | None = None,
) -> list[str]:
    used_tools = section_body(text, "Использованные инструменты")
    if used_tools is None:
        return ["missing section: Использованные инструменты"]

    errors: list[str] = []
    bullet_lines = [
        line for line in used_tools.splitlines() if line.lstrip().startswith("- ")
    ]
    if len(bullet_lines) < 2:
        errors.append("used tools section must contain at least two bullet items")
    if "реестр-системных-приложений-и-инструментов.md" not in used_tools:
        errors.append("used tools section must link to the tools registry")
    request_file_match = request_match(request_path) if request_path is not None else None
    if (
        request_file_match is not None
        and request_datetime_key(request_file_match)
        >= QUALIFIED_OPENAI_TOOL_VERSION_RULE_START
        and UNQUALIFIED_OPENAI_VERSION_FALLBACK_RE.search(used_tools)
    ):
        errors.append(
            "used tools section must qualify the ChatGPT or Codex layer "
            "instead of using the generic version fallback"
        )
    if (
        request_file_match is not None
        and request_datetime_key(request_file_match) >= SESSION_TIME_TOOL_RULE_START
        and "fum-moskovskoye-vremya-rabochej-sessii" not in used_tools
    ):
        errors.append(
            "used tools section must include fum-moskovskoye-vremya-rabochej-sessii for canonical MSK time"
        )
    return errors


def request_requires_codex_thread_id(request_path: Path) -> bool:
    match = request_match(request_path)
    return bool(
        match is not None
        and request_datetime_key(match) >= CODEX_THREAD_ID_RULE_START
    )


def codex_thread_id_from_request(text: str) -> tuple[str | None, list[str]]:
    heading_pattern = re.compile(
        r"^## Идентификатор сеанса Codex[ \t]*$",
        re.MULTILINE,
    )
    heading_count = len(heading_pattern.findall(text))
    if heading_count == 0:
        return None, ["missing section: Идентификатор сеанса Codex"]
    if heading_count != 1:
        return None, [
            "request must contain exactly one section: "
            "Идентификатор сеанса Codex"
        ]

    section = section_body(text, "Идентификатор сеанса Codex")
    if section is None:  # pragma: no cover - protected by heading_count
        return None, ["missing section: Идентификатор сеанса Codex"]

    content_lines = [line for line in section.splitlines() if line.strip()]
    if len(content_lines) != 1:
        return None, [
            "Codex session identifier section must contain exactly one "
            "non-empty Codex-Thread-ID line"
        ]

    line_match = CODEX_THREAD_ID_LINE_RE.fullmatch(content_lines[0])
    if line_match is None:
        return None, [
            "Codex session identifier section must contain exactly one "
            "Codex-Thread-ID line"
        ]

    value = line_match.group(1)
    if CANONICAL_UUID_RE.fullmatch(value) is None:
        return None, [f"Codex-Thread-ID must be a canonical lowercase UUID: {value}"]
    return value, []


def validate_codex_thread_id_section(
    text: str,
    request_path: Path,
    expected_codex_thread_id: str | None = None,
) -> list[str]:
    if not request_requires_codex_thread_id(request_path):
        return []

    value, errors = codex_thread_id_from_request(text)
    if errors:
        return errors
    if expected_codex_thread_id is not None and value != expected_codex_thread_id:
        return [
            "Codex-Thread-ID does not match the expected root Codex thread: "
            f"{value}"
        ]
    return []


def validate_codex_commit_context_requirements(
    request_path: Path,
    expected_codex_thread_id: str | None,
    commit_message: str | None,
) -> list[str]:
    if not request_requires_codex_thread_id(request_path):
        return []

    errors: list[str] = []
    if expected_codex_thread_id is None:
        errors.append("--codex-thread-id is required for this request")
    if commit_message is None:
        errors.append("--commit-message-file is required for this request")
    return errors


def commit_body_trailer_values(commit_message: str) -> list[str]:
    lines = commit_message.rstrip().splitlines()
    if len(lines) < 3 or lines[1].strip():
        return []

    body = "\n".join(lines[2:]).rstrip()
    if not body:
        return []
    trailer_block = re.split(r"\n[ \t]*\n", body)[-1]
    trailer_lines = trailer_block.splitlines()
    if not trailer_lines or any(
        TRAILER_LINE_RE.fullmatch(line) is None for line in trailer_lines
    ):
        return []
    if CODEX_THREAD_ID_LINE_RE.fullmatch(trailer_lines[-1]) is None:
        return []

    values: list[str] = []
    for line in trailer_lines:
        match = CODEX_THREAD_ID_TRAILER_LINE_RE.fullmatch(line)
        if match is not None:
            values.append(match.group(1))
    return values


def validate_commit_message_codex_thread_id(
    request_text: str,
    request_path: Path,
    commit_message: str,
) -> list[str]:
    if not request_requires_codex_thread_id(request_path):
        return []

    request_value, request_errors = codex_thread_id_from_request(request_text)
    if request_errors:
        return ["cannot validate commit Codex-Thread-ID until the request value is valid"]

    trailer_values = commit_body_trailer_values(commit_message)
    if len(trailer_values) != 1:
        return [
            "commit body must end with exactly one Codex-Thread-ID trailer"
        ]

    trailer_value = trailer_values[0]
    if CANONICAL_UUID_RE.fullmatch(trailer_value) is None:
        return [
            "commit Codex-Thread-ID must be a canonical lowercase UUID: "
            f"{trailer_value}"
        ]
    if trailer_value != request_value:
        return [
            "commit Codex-Thread-ID does not match the request: "
            f"{trailer_value}"
        ]
    return []


def strip_link_title(destination: str) -> str:
    value = destination.strip()
    if value.startswith("<") and ">" in value:
        return value[1 : value.index(">")]
    title_match = re.search(r"\s+['\"]", value)
    if title_match:
        return value[: title_match.start()]
    return value


def is_external_link(destination: str) -> bool:
    value = destination.strip()
    if is_absolute_local_markdown_link(value):
        return False
    return bool(re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", value)) or value.startswith("//")


def is_absolute_local_markdown_link(destination: str) -> bool:
    """Recognize local absolute forms before URL classification."""

    value = unquote(destination.strip())
    if not value:
        return False
    path_part = value.split("#", 1)[0].split("?", 1)[0]
    if path_part.lower().startswith("file:"):
        return True
    windows_path = PureWindowsPath(path_part)
    if windows_path.drive or windows_path.is_absolute():
        return True
    return PurePosixPath(path_part).is_absolute() and not path_part.startswith("//")


def opening_markdown_fence(line: str) -> MarkdownFence | None:
    stripped = line.lstrip()
    if not stripped or stripped[0] not in ("`", MARKDOWN_TILDE_FENCE_MARKER):
        return None

    marker = stripped[0]
    length = len(stripped) - len(stripped.lstrip(marker))
    if length < 3:
        return None

    return MarkdownFence(
        marker=marker,
        length=length,
        info=stripped[length:].strip(),
    )


def closes_markdown_fence(line: str, fence: MarkdownFence) -> bool:
    candidate = opening_markdown_fence(line)
    return bool(
        candidate is not None
        and candidate.marker == fence.marker
        and candidate.length >= fence.length
        and not candidate.info
    )


def iter_markdown_links(path: Path) -> list[MarkdownLink]:
    links: list[MarkdownLink] = []
    fence: MarkdownFence | None = None

    for line_number, line in enumerate(read_text(path).splitlines(), start=1):
        if fence is not None:
            if closes_markdown_fence(line, fence):
                fence = None
            continue

        fence = opening_markdown_fence(line)
        if fence is not None:
            continue

        for match in MARKDOWN_LINK_RE.finditer(line):
            links.append(
                MarkdownLink(
                    source=path,
                    line=line_number,
                    target=strip_link_title(match.group(2)),
                )
            )
    return links


def resolve_markdown_target(link: MarkdownLink, repo_root: Path) -> Path | None:
    target = unquote(link.target.strip())
    if not target or is_external_link(target) or is_absolute_local_markdown_link(target):
        return None

    path_part = target.split("#", 1)[0].split("?", 1)[0]
    if not path_part:
        return link.source
    return (link.source.parent / path_part).resolve()


def actual_case_path(path: Path, repo_root: Path) -> Path | None:
    root = repo_root.resolve()
    try:
        relative = path.relative_to(root)
    except ValueError:
        return path if path.exists() else None

    current = root
    for part in relative.parts:
        if not current.is_dir():
            return None

        try:
            children = list(current.iterdir())
        except OSError:
            return None

        exact = next((child for child in children if child.name == part), None)
        if exact is not None:
            current = exact
            continue

        folded = [
            child for child in children if child.name.casefold() == part.casefold()
        ]
        if len(folded) == 1:
            current = folded[0]
            continue

        return None

    return current


def all_markdown_files(repo_root: Path) -> set[Path]:
    return set(project_markdown_paths(repo_root))


def request_text_line_span(text: str) -> tuple[int, int] | None:
    lines = text.splitlines()
    headings = [
        index
        for index, line in enumerate(lines)
        if re.fullmatch(r"##[ \t]+Текст запроса[ \t]*", line)
    ]
    if len(headings) != 1:
        return None
    heading = headings[0]
    following = next(
        (
            index
            for index in range(heading + 1, len(lines))
            if re.match(r"^##[ \t]+", lines[index])
        ),
        len(lines),
    )
    return heading + 2, following + 1


def проверить_незаполненный_маркер_шаблона(
    текст: str,
    путь: Path,
    корень: Path,
) -> list[str]:
    игнорируемый_диапазон = (
        request_text_line_span(текст) if is_request_file(путь, корень) else None
    )
    ошибки: list[str] = []
    for номер, строка in enumerate(текст.splitlines(), start=1):
        if МАРКЕР_НЕЗАПОЛНЕННОГО_ШАБЛОНА not in строка:
            continue
        if (
            игнорируемый_диапазон is not None
            and игнорируемый_диапазон[0] <= номер < игнорируемый_диапазон[1]
        ):
            continue
        ошибки.append(
            "незаполненный маркер шаблона: "
            f"{repo_relative(путь, корень)}:{номер}"
        )
    return ошибки


def validate_markdown_links(paths: set[Path], repo_root: Path) -> list[str]:
    errors: list[str] = []
    for path in sorted(paths):
        if not path.exists() or path.suffix.lower() != ".md":
            continue
        ignored_request_span = None
        if is_request_file(path, repo_root):
            ignored_request_span = request_text_line_span(read_text(path))
        for link in iter_markdown_links(path):
            if (
                ignored_request_span is not None
                and ignored_request_span[0] <= link.line < ignored_request_span[1]
            ):
                continue
            source_rel = repo_relative(link.source, repo_root)
            if is_absolute_local_markdown_link(link.target):
                errors.append(
                    "absolute local Markdown link is forbidden in "
                    f"{source_rel}:{link.line}"
                )
                continue
            target = resolve_markdown_target(link, repo_root)
            if target is None:
                continue
            try:
                target.relative_to(repo_root.resolve())
            except ValueError:
                errors.append(
                    "local Markdown link escapes the repository in "
                    f"{source_rel}:{link.line}"
                )
                continue
            actual_target = None
            if not is_structurally_excluded_path(target, repo_root):
                actual_target = actual_case_path(target, repo_root)
            if actual_target is None:
                errors.append(
                    f"broken Markdown link in {source_rel}:{link.line}: {link.target}"
                )
                continue

            try:
                target_rel = target.relative_to(repo_root.resolve()).as_posix()
                actual_rel = actual_target.relative_to(repo_root.resolve()).as_posix()
            except ValueError:
                continue

            if target_rel != actual_rel:
                errors.append(
                    f"Markdown link case mismatch in {source_rel}:{link.line}: "
                    f"{link.target} points to {actual_rel}"
                )
    return errors


def iter_markdown_paragraphs(text: str) -> list[tuple[int, str]]:
    paragraphs: list[tuple[int, str]] = []
    current: list[str] = []
    start_line = 0
    fence: MarkdownFence | None = None

    def flush() -> None:
        nonlocal current, start_line
        if current:
            paragraphs.append((start_line, "\n".join(current)))
            current = []
            start_line = 0

    for line_number, line in enumerate(text.splitlines(), start=1):
        if fence is not None:
            if closes_markdown_fence(line, fence):
                fence = None
            continue

        fence = opening_markdown_fence(line)
        if fence is not None:
            flush()
            continue

        if not line.strip():
            flush()
            continue
        if not current:
            start_line = line_number
        current.append(line)

    flush()
    return paragraphs


def possible_meta_request_line(text: str) -> int | None:
    for line_number, paragraph in iter_markdown_paragraphs(text):
        if USER_META_REQUEST_RE.search(paragraph) and META_RULE_CONTEXT_RE.search(
            paragraph
        ):
            return line_number
    return None


def has_request_file_link(path: Path, repo_root: Path) -> bool:
    for link in iter_markdown_links(path):
        target = resolve_markdown_target(link, repo_root)
        if target is not None and is_request_file(target, repo_root):
            return True
    return False


def validate_meta_request_coverage(paths: set[Path], repo_root: Path) -> list[str]:
    errors: list[str] = []
    for path in sorted(paths):
        if (
            not path.exists()
            or path.suffix.lower() != ".md"
            or is_request_file(path, repo_root)
        ):
            continue

        text = read_text(path)
        line_number = possible_meta_request_line(text)
        if line_number is None or has_request_file_link(path, repo_root):
            continue

        source_rel = repo_relative(path, repo_root)
        errors.append(
            f"possible unregistered meta request in {source_rel}:{line_number}: "
            "add a link to a concrete Журнал/<session-stem>/запрос.md or create "
            "a separate request folder"
        )
    return errors


def validate_answered_question_files(
    repo_root: Path,
    markdown_paths: set[Path] | None = None,
) -> list[str]:
    directory = repo_root / "Вопросы и ответы"
    if not directory.exists():
        return []

    candidates = markdown_paths
    if candidates is None:
        candidates = set(project_markdown_paths(repo_root))

    errors: list[str] = []
    for path in sorted(
        path for path in candidates if path.parent == directory.resolve()
    ):
        if path.name == "README.md":
            continue

        question_section = section_body(read_text(path), "Вопрос")
        question_lines = []
        if question_section is not None:
            question_lines = [
                line.strip()
                for line in question_section.splitlines()
                if line.strip()
                and not line.lstrip().startswith(("```", "~~~"))
            ]
        question = "\n".join(question_lines).rstrip()
        if question.endswith("?"):
            continue

        source_rel = repo_relative(path, repo_root)
        errors.append(
            f"answered-question text must end with '?' in {source_rel}"
        )
    return errors


def top_provenance_line(text: str) -> tuple[int, str] | None:
    lines = text.splitlines()
    if not lines or not lines[0].startswith("# "):
        return None

    for index, line in enumerate(lines[1:], start=2):
        if not line.strip():
            continue
        if PROVENANCE_LABEL_RE.fullmatch(line.strip()):
            return index, line.strip()
        return None
    return None


def validate_provenance_section_position(
    paths: set[Path],
    repo_root: Path,
) -> list[str]:
    errors: list[str] = []
    for path in sorted(paths):
        if (
            not path.exists()
            or path.suffix.lower() != ".md"
            or is_request_file(path, repo_root)
        ):
            continue

        top_line = top_provenance_line(read_text(path))
        if top_line is None:
            continue

        line_number, label = top_line
        source_rel = repo_relative(path, repo_root)
        errors.append(
            f"provenance section must follow content in {source_rel}:{line_number}: "
            f"move '{label}' to the bottom of the file before FUM-MD-RECENCY"
        )
    return errors


def validate_mermaid_markdown_list_labels(
    paths: set[Path],
    repo_root: Path,
) -> list[str]:
    errors: list[str] = []
    for path in sorted(paths):
        if not path.exists() or path.suffix.lower() != ".md":
            continue

        fence: MarkdownFence | None = None
        in_mermaid = False
        for line_number, line in enumerate(read_text(path).splitlines(), start=1):
            if fence is not None:
                if closes_markdown_fence(line, fence):
                    fence = None
                    in_mermaid = False
                elif in_mermaid and MERMAID_LABEL_MARKDOWN_LIST_RE.search(line):
                    source_rel = repo_relative(path, repo_root)
                    errors.append(
                        "unsupported Mermaid Markdown list label in "
                        f"{source_rel}:{line_number}: use text like "
                        "'Этап 1 - ...' instead of '1. ...'"
                    )
                continue

            fence = opening_markdown_fence(line)
            if fence is not None:
                fence_info = fence.info.split(None, 1)
                in_mermaid = bool(
                    fence_info and fence_info[0].lower() == "mermaid"
                )
                continue

            if not in_mermaid:
                continue
    return errors


def affected_files_from_request(
    text: str,
    request_path: Path,
    repo_root: Path,
) -> tuple[AffectedPaths, list[str]]:
    affected = section_body(text, "Повлиял на файлы")
    if affected is None:
        return AffectedPaths(), ["missing section: Повлиял на файлы"]

    errors: list[str] = []
    files = AffectedPaths()
    pseudo_source = request_path
    for line in affected.splitlines():
        for match in MARKDOWN_LINK_RE.finditer(line):
            target = strip_link_title(match.group(2))
            if is_external_link(target):
                continue
            link = MarkdownLink(pseudo_source, 1, target)
            resolved = resolve_markdown_target(link, repo_root)
            if resolved is not None:
                if resolved.is_dir():
                    files.existing_directories.add(resolved)
                else:
                    files.add(resolved)

    for match in DELETED_AFFECTED_PATH_RE.finditer(affected):
        resolved = absolute_path(match.group(1), repo_root)
        try:
            resolved.relative_to(repo_root.resolve())
        except ValueError:
            errors.append(
                "deleted affected path must stay inside the repository: "
                f"{match.group(1)}"
            )
            continue
        if resolved.exists():
            errors.append(
                f"deleted affected path still exists: {match.group(1)}"
            )
            continue
        files.add(resolved)

    for match in DELETED_AFFECTED_SUBTREE_RE.finditer(affected):
        resolved = absolute_path(match.group(1), repo_root)
        try:
            resolved.relative_to(repo_root.resolve())
        except ValueError:
            errors.append(
                "deleted affected subtree must stay inside the repository: "
                f"{match.group(1)}"
            )
            continue
        if resolved.exists():
            errors.append(
                f"deleted affected subtree still exists: {match.group(1)}"
            )
            continue
        files.deleted_subtrees.add(resolved)

    for match in DELETED_DIRECT_FILES_DIRECTORY_RE.finditer(affected):
        resolved = absolute_path(match.group(1), repo_root)
        try:
            resolved.relative_to(repo_root.resolve())
        except ValueError:
            errors.append(
                "deleted direct-files directory must stay inside the repository: "
                f"{match.group(1)}"
            )
            continue
        if not resolved.is_dir():
            errors.append(
                f"deleted direct-files directory must exist: {match.group(1)}"
            )
            continue
        files.deleted_direct_files_directories.add(resolved)

    if (
        not files
        and not files.existing_directories
        and not files.deleted_direct_files_directories
        and not files.deleted_subtrees
        and not errors
    ):
        errors.append(
            "affected files section must contain local Markdown links, "
            "deleted-file markers, deleted-direct-files markers, or "
            "deleted-subtree markers"
        )
    return files, errors


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


def parse_git_status_paths(status_text: str) -> list[str]:
    paths: list[str] = []
    for line in status_text.splitlines():
        if not line.strip():
            continue
        path = line[3:] if len(line) > 3 else line
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(decode_git_path(path))
    return paths


def read_git_status(repo_root: Path) -> tuple[str, list[str]]:
    if not (repo_root / ".git").exists():
        return "", ["repository has no .git directory; Git status check is unavailable"]

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
        return "", [result.stderr.strip() or "git status failed"]
    return result.stdout, []


def validate_git_status(
    repo_root: Path,
    allowed_files: set[Path],
    git_status: str | None,
) -> list[str]:
    errors: list[str] = []
    status_text = git_status
    if status_text is None:
        status_text, status_errors = read_git_status(repo_root)
        errors.extend(status_errors)
    if errors:
        return errors

    root = repo_root.resolve()
    allowed = {repo_relative(path, root) for path in allowed_files}
    existing_directories = {
        path.resolve()
        for path in getattr(allowed_files, "existing_directories", set())
        if path.is_dir()
    }
    deleted_direct_files_directories = {
        path.resolve()
        for path in getattr(
            allowed_files,
            "deleted_direct_files_directories",
            set(),
        )
        if path.is_dir()
    }
    deleted_subtrees = {
        path.resolve()
        for path in getattr(allowed_files, "deleted_subtrees", set())
        if not path.exists()
    }
    for status_path in parse_git_status_paths(status_text or ""):
        normalized = Path(status_path).as_posix()
        if normalized in allowed:
            continue
        candidate = absolute_path(normalized, root)
        existing_descendant = candidate.exists() and any(
            directory != candidate and directory in candidate.parents
            for directory in existing_directories
        )
        deleted_direct_file = (
            not candidate.exists()
            and candidate.parent in deleted_direct_files_directories
        )
        deleted_descendant = any(
            subtree != candidate and subtree in candidate.parents
            for subtree in deleted_subtrees
        )
        if not existing_descendant and not deleted_direct_file and not deleted_descendant:
            errors.append(f"unexpected Git status path: {normalized}")
    return errors


def validate_md_recency(repo_root: Path) -> list[str]:
    script = repo_root / "Инструменты" / "fum-svezhestj-markdown" / "scripts" / "update-md-recency.py"
    if not script.exists():
        return []

    result = subprocess.run(
        [
            sys.executable,
            str(script),
            "--repo-root",
            str(repo_root),
            "--check",
        ],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode == 0:
        return []

    details = result.stderr.strip() or result.stdout.strip() or "unknown recency error"
    return [f"md recency check failed: {line}" for line in details.splitlines()]


def validate_session(
    repo_root: str | Path,
    request: str | Path,
    git_status: str | None = None,
    check_git_status: bool = True,
    expected_codex_thread_id: str | None = None,
    commit_message: str | None = None,
) -> list[str]:
    root = Path(repo_root).resolve()
    request_path = absolute_path(request, root)
    errors: list[str] = []

    if request_match(request_path) is None:
        errors.append(
            "request path must match "
            "Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_slug]>/запрос.md: "
            f"{repo_relative(request_path, root)}"
        )
    errors.extend(validate_request_filename_title(request_path))
    if not request_path.exists():
        return errors + [f"request file does not exist: {request}"]

    try:
        project_markdown = all_markdown_files(root)
    except ProjectFilesError as exc:
        return errors + [f"project Markdown inventory failed: {exc}"]

    errors.extend(validate_request_folder_layout(root))

    text = read_text(request_path)
    expected_heading = expected_request_heading(request_path)
    if not text.startswith(f"{expected_heading}\n"):
        errors.append(f"request must start with heading: {expected_heading}")

    errors.extend(
        validate_navigation(
            root,
            request_path,
            text,
            markdown_paths=project_markdown,
        )
    )
    errors.extend(validate_journal(root, request_path))
    errors.extend(
        проверить_незаполненный_маркер_шаблона(text, request_path, root)
    )
    путь_отчёта_шаблона = expected_journal_path(request_path, root)
    if путь_отчёта_шаблона.is_file():
        errors.extend(
            проверить_незаполненный_маркер_шаблона(
                read_text(путь_отчёта_шаблона),
                путь_отчёта_шаблона,
                root,
            )
        )
    errors.extend(validate_used_tools_section(text, request_path))
    errors.extend(
        validate_codex_commit_context_requirements(
            request_path,
            expected_codex_thread_id,
            commit_message,
        )
    )
    errors.extend(
        validate_codex_thread_id_section(
            text,
            request_path,
            expected_codex_thread_id=expected_codex_thread_id,
        )
    )
    if commit_message is not None:
        errors.extend(
            validate_commit_message_codex_thread_id(
                text,
                request_path,
                commit_message,
            )
        )

    affected_files, affected_errors = affected_files_from_request(
        text,
        request_path,
        root,
    )
    errors.extend(affected_errors)

    journal_path = expected_journal_path(request_path, root)
    expected_listed = {
        repo_relative(request_path, root): "current request",
        repo_relative(journal_path, root): "sibling report",
    }
    affected_relative = {repo_relative(path, root) for path in affected_files}
    for expected_path, label in expected_listed.items():
        if expected_path not in affected_relative:
            errors.append(f"affected files section must include {label}: {expected_path}")

    session_markdown_paths = set(affected_files)
    session_markdown_paths.add(request_path)
    session_markdown_paths.add(journal_path)
    session_markdown_paths.intersection_update(project_markdown)

    errors.extend(validate_markdown_links(project_markdown, root))
    errors.extend(validate_meta_request_coverage(session_markdown_paths, root))
    errors.extend(
        validate_answered_question_files(
            root,
            markdown_paths=project_markdown,
        )
    )
    errors.extend(validate_provenance_section_position(session_markdown_paths, root))
    errors.extend(validate_mermaid_markdown_list_labels(session_markdown_paths, root))
    errors.extend(validate_md_recency(root))

    if check_git_status:
        errors.extend(validate_git_status(root, affected_files, git_status))

    return errors


def main() -> int:
    args = parse_args()
    commit_message = None
    if args.commit_message_file is not None:
        try:
            commit_message = read_text(args.commit_message_file)
        except OSError as exc:
            print(f"cannot read commit message file: {exc}", file=sys.stderr)
            return 2
    errors = validate_session(
        args.repo_root,
        args.request,
        git_status="" if args.skip_git_status else None,
        check_git_status=not args.skip_git_status,
        expected_codex_thread_id=args.codex_thread_id,
        commit_message=commit_message,
    )
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("session coherence check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
