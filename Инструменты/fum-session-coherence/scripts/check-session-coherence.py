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
from pathlib import Path
from urllib.parse import unquote


REQUEST_FILENAME_RE = re.compile(
    r"^(?P<date>\d{4}-\d{2}-\d{2})_"
    r"(?P<hour>\d{2})-(?P<minute>\d{2})-(?P<second>\d{2})_MSK"
    r"(?:_(?P<title>[0-9A-Za-zА-Яа-яЁё][0-9A-Za-zА-Яа-яЁё-]*))?\.md$"
)
REQUEST_TITLE_INFINITIVE_RULE_START = (2026, 7, 2, 23, 1, 25)
QUALIFIED_OPENAI_TOOL_VERSION_RULE_START = (2026, 7, 10, 5, 59, 58)
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
    r"памят[ьи]\s+FUM|рабоч\w*\s+сесси\w*|Запросы/|"
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


@dataclass(frozen=True)
class MarkdownLink:
    source: Path
    line: int
    target: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--request",
        required=True,
        type=Path,
        help="Session request file, relative to the repository root.",
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
    return REQUEST_FILENAME_RE.fullmatch(path.name)


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

    return [f"request filename title must start with an infinitive verb: {slug}"]


def is_request_file(path: Path, repo_root: Path) -> bool:
    try:
        relative = path.resolve().relative_to(repo_root.resolve())
    except ValueError:
        return False
    return (
        len(relative.parts) == 2
        and relative.parts[0] == "Запросы"
        and REQUEST_FILENAME_RE.fullmatch(relative.name) is not None
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


def request_files(repo_root: Path) -> list[Path]:
    request_dir = repo_root / "Запросы"
    if not request_dir.exists():
        return []
    return sorted(
        path
        for path in request_dir.glob("*.md")
        if REQUEST_FILENAME_RE.fullmatch(path.name)
    )


def contains_request_link(section: str, label: str, filename: str) -> bool:
    return label in section and filename in section


def validate_navigation(repo_root: Path, request_path: Path, text: str) -> list[str]:
    errors: list[str] = []
    navigation = section_body(text, "Навигация по запросам")
    if navigation is None:
        return ["missing section: Навигация по запросам"]

    files = request_files(repo_root)
    try:
        index = [path.resolve() for path in files].index(request_path.resolve())
    except ValueError:
        return [f"request file is not in Запросы/: {repo_relative(request_path, repo_root)}"]

    previous_file = files[index - 1] if index > 0 else None
    next_file = files[index + 1] if index + 1 < len(files) else None

    if previous_file is None:
        if "Предыдущий запрос: нет" not in navigation:
            errors.append("request navigation must state previous request: нет")
    elif not contains_request_link(
        navigation,
        request_label(previous_file),
        previous_file.name,
    ):
        errors.append(f"missing previous request navigation link: {previous_file.name}")

    if next_file is None:
        if "Следующий запрос: нет" not in navigation:
            errors.append("request navigation must state next request: нет")
    elif not contains_request_link(navigation, request_label(next_file), next_file.name):
        errors.append(f"missing next request navigation link: {next_file.name}")

    if previous_file is not None:
        previous_text = read_text(previous_file)
        previous_navigation = section_body(previous_text, "Навигация по запросам") or ""
        if not contains_request_link(
            previous_navigation,
            request_label(request_path),
            request_path.name,
        ):
            errors.append(
                f"previous request does not link forward to current request: {previous_file.name}"
            )

    if next_file is not None:
        next_text = read_text(next_file)
        next_navigation = section_body(next_text, "Навигация по запросам") or ""
        if not contains_request_link(
            next_navigation,
            request_label(request_path),
            request_path.name,
        ):
            errors.append(
                f"next request does not link back to current request: {next_file.name}"
            )

    return errors


def expected_journal_path(request_path: Path, repo_root: Path) -> Path:
    return repo_root / "Журнал" / request_path.name


def relative_link(target: Path, source: Path, repo_root: Path) -> str:
    target_abs = absolute_path(target, repo_root)
    return Path(os.path.relpath(target_abs, source.parent)).as_posix()


def validate_journal(repo_root: Path, request_path: Path) -> list[str]:
    errors: list[str] = []
    journal = expected_journal_path(request_path, repo_root)
    if not journal.exists():
        return [f"missing journal file: {repo_relative(journal, repo_root)}"]

    text = read_text(journal)
    heading = expected_journal_heading(request_path)
    if not text.startswith(f"{heading}\n"):
        errors.append(f"journal must start with heading: {heading}")

    request_link = relative_link(request_path, journal, repo_root)
    if request_link not in text:
        errors.append(
            f"journal does not link to request: {repo_relative(request_path, repo_root)}"
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
    return errors


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
    return bool(re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", value)) or value.startswith("//")


def iter_markdown_links(path: Path) -> list[MarkdownLink]:
    links: list[MarkdownLink] = []
    in_fence = False

    for line_number, line in enumerate(read_text(path).splitlines(), start=1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
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
    if not target or is_external_link(target):
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
    root = repo_root.resolve()
    return {
        path
        for path in root.rglob("*.md")
        if ".git" not in path.relative_to(root).parts
    }


def validate_markdown_links(paths: set[Path], repo_root: Path) -> list[str]:
    errors: list[str] = []
    for path in sorted(paths):
        if not path.exists() or path.suffix.lower() != ".md":
            continue
        for link in iter_markdown_links(path):
            target = resolve_markdown_target(link, repo_root)
            if target is None:
                continue
            actual_target = actual_case_path(target, repo_root)
            if actual_target is None:
                source_rel = repo_relative(link.source, repo_root)
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
                source_rel = repo_relative(link.source, repo_root)
                errors.append(
                    f"Markdown link case mismatch in {source_rel}:{link.line}: "
                    f"{link.target} points to {actual_rel}"
                )
    return errors


def iter_markdown_paragraphs(text: str) -> list[tuple[int, str]]:
    paragraphs: list[tuple[int, str]] = []
    current: list[str] = []
    start_line = 0
    in_fence = False

    def flush() -> None:
        nonlocal current, start_line
        if current:
            paragraphs.append((start_line, "\n".join(current)))
            current = []
            start_line = 0

    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            flush()
            in_fence = not in_fence
            continue
        if in_fence:
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
            "add a link to a concrete request file in Запросы/ or create a separate request file"
        )
    return errors


def validate_answered_question_files(repo_root: Path) -> list[str]:
    directory = repo_root / "Вопросы и ответы"
    if not directory.exists():
        return []

    errors: list[str] = []
    for path in sorted(directory.glob("*.md")):
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

        in_fence = False
        in_mermaid = False
        for line_number, line in enumerate(read_text(path).splitlines(), start=1):
            stripped = line.strip()
            if stripped.startswith("```") or stripped.startswith("~~~"):
                if in_fence:
                    in_fence = False
                    in_mermaid = False
                else:
                    in_fence = True
                    fence_info = stripped[3:].strip().split(None, 1)
                    in_mermaid = bool(fence_info and fence_info[0].lower() == "mermaid")
                continue

            if not in_mermaid:
                continue

            if MERMAID_LABEL_MARKDOWN_LIST_RE.search(line):
                source_rel = repo_relative(path, repo_root)
                errors.append(
                    "unsupported Mermaid Markdown list label in "
                    f"{source_rel}:{line_number}: use text like "
                    "'Этап 1 - ...' instead of '1. ...'"
                )
    return errors


def affected_files_from_request(
    text: str,
    request_path: Path,
    repo_root: Path,
) -> tuple[set[Path], list[str]]:
    affected = section_body(text, "Повлиял на файлы")
    if affected is None:
        return set(), ["missing section: Повлиял на файлы"]

    errors: list[str] = []
    files: set[Path] = set()
    pseudo_source = request_path
    for line in affected.splitlines():
        for match in MARKDOWN_LINK_RE.finditer(line):
            target = strip_link_title(match.group(2))
            if is_external_link(target):
                continue
            link = MarkdownLink(pseudo_source, 1, target)
            resolved = resolve_markdown_target(link, repo_root)
            if resolved is not None:
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

    if not files and not errors:
        errors.append(
            "affected files section must contain local Markdown links "
            "or deleted-file path markers"
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

    allowed = {repo_relative(path, repo_root) for path in allowed_files}
    for status_path in parse_git_status_paths(status_text or ""):
        normalized = Path(status_path).as_posix()
        if normalized not in allowed:
            errors.append(f"unexpected Git status path: {normalized}")
    return errors


def validate_md_recency(repo_root: Path) -> list[str]:
    script = repo_root / "Инструменты" / "fum-md-recency" / "scripts" / "update-md-recency.py"
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
) -> list[str]:
    root = Path(repo_root).resolve()
    request_path = absolute_path(request, root)
    errors: list[str] = []

    if request_match(request_path) is None:
        errors.append(f"request filename does not match session format: {request_path.name}")
    errors.extend(validate_request_filename_title(request_path))
    if not request_path.exists():
        return errors + [f"request file does not exist: {request}"]

    text = read_text(request_path)
    expected_heading = expected_request_heading(request_path)
    if not text.startswith(f"{expected_heading}\n"):
        errors.append(f"request must start with heading: {expected_heading}")

    errors.extend(validate_navigation(root, request_path, text))
    errors.extend(validate_journal(root, request_path))
    errors.extend(validate_used_tools_section(text, request_path))

    affected_files, affected_errors = affected_files_from_request(
        text,
        request_path,
        root,
    )
    errors.extend(affected_errors)

    journal_path = expected_journal_path(request_path, root)
    expected_listed = {
        repo_relative(request_path, root): "current request",
        repo_relative(journal_path, root): "journal",
    }
    affected_relative = {repo_relative(path, root) for path in affected_files}
    for expected_path, label in expected_listed.items():
        if expected_path not in affected_relative:
            errors.append(f"affected files section must include {label}: {expected_path}")

    session_markdown_paths = set(affected_files)
    session_markdown_paths.add(request_path)
    session_markdown_paths.add(journal_path)

    link_paths = all_markdown_files(root)
    link_paths.update(session_markdown_paths)
    errors.extend(validate_markdown_links(link_paths, root))
    errors.extend(validate_meta_request_coverage(session_markdown_paths, root))
    errors.extend(validate_answered_question_files(root))
    errors.extend(validate_provenance_section_position(session_markdown_paths, root))
    errors.extend(validate_mermaid_markdown_list_labels(session_markdown_paths, root))
    errors.extend(validate_md_recency(root))

    if check_git_status:
        errors.extend(validate_git_status(root, affected_files, git_status))

    return errors


def main() -> int:
    args = parse_args()
    errors = validate_session(
        args.repo_root,
        args.request,
        git_status="" if args.skip_git_status else None,
        check_git_status=not args.skip_git_status,
    )
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("session coherence check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
