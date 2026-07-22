#!/usr/bin/env python3
"""Check reciprocal links from declared question targets back to active questions."""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote


QUESTIONS_INDEX = Path("Вопросы/README.md")
ACTIVE_SECTION_TITLES = {
    "Открытые вопросы",
    "Частично прояснённые вопросы",
}
TARGETS_SECTION_TITLE = "Затронутая документация"
HEADING_LINE_RE = re.compile(r"^## (.+?)\s*$")
FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[([^\]\n]+)\]\(([^)\n]+)\)")
INLINE_LINK_RE = re.compile(r"(?<!!)\[([^\]\n]+)\]\(([^)\n]+)\)")


@dataclass(frozen=True)
class MarkdownLink:
    source: Path
    line: int
    target: str


@dataclass(frozen=True)
class MarkdownSection:
    title: str
    body: str
    body_start_line: int


@dataclass(frozen=True)
class LocalTarget:
    requested: Path
    actual: Path | None
    case_mismatch: bool


@dataclass(frozen=True)
class ValidationResult:
    errors: tuple[str, ...]
    question_count: int
    target_count: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    return parser.parse_args()


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
    return (
        re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", value) is not None
        or value.startswith("//")
    )


def visible_heading_title(title: str) -> str:
    return INLINE_LINK_RE.sub(r"\1", title).strip()


def mask_inline_code(line: str) -> str:
    masked = list(line)
    cursor = 0
    while cursor < len(line):
        start = line.find("`", cursor)
        if start < 0:
            break
        delimiter_end = start
        while delimiter_end < len(line) and line[delimiter_end] == "`":
            delimiter_end += 1
        delimiter = line[start:delimiter_end]
        end = line.find(delimiter, delimiter_end)
        if end < 0:
            cursor = delimiter_end
            continue
        for index in range(start, end + len(delimiter)):
            masked[index] = " "
        cursor = end + len(delimiter)
    return "".join(masked)


def mask_html_comments(
    line: str,
    in_comment: bool,
) -> tuple[str, bool]:
    masked = list(line)
    cursor = 0
    while cursor < len(line):
        if in_comment:
            end = line.find("-->", cursor)
            if end < 0:
                for index in range(cursor, len(line)):
                    masked[index] = " "
                return "".join(masked), True
            for index in range(cursor, end + 3):
                masked[index] = " "
            cursor = end + 3
            in_comment = False
            continue

        start = line.find("<!--", cursor)
        if start < 0:
            break
        end = line.find("-->", start + 4)
        if end < 0:
            for index in range(start, len(line)):
                masked[index] = " "
            return "".join(masked), True
        for index in range(start, end + 3):
            masked[index] = " "
        cursor = end + 3

    return "".join(masked), in_comment


def visible_markdown_lines(text: str) -> list[str]:
    visible_lines: list[str] = []
    in_html_comment = False
    fence: tuple[str, int] | None = None

    for line in text.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        newline = line[len(content) :]

        if fence is not None:
            fence_match = FENCE_RE.match(content)
            if fence_match is not None:
                marker, remainder = fence_match.groups()
                if (
                    marker[0] == fence[0]
                    and len(marker) >= fence[1]
                    and not remainder.strip()
                ):
                    fence = None
            visible_lines.append(" " * len(content) + newline)
            continue

        visible, in_html_comment = mask_html_comments(
            mask_inline_code(content),
            in_html_comment,
        )
        fence_match = FENCE_RE.match(visible)
        if fence_match is not None:
            marker = fence_match.group(1)
            fence = (marker[0], len(marker))
            visible_lines.append(" " * len(content) + newline)
            continue

        visible_lines.append(visible + newline)

    return visible_lines


def markdown_sections(text: str) -> list[MarkdownSection]:
    source_lines = text.splitlines(keepends=True)
    visible_lines = visible_markdown_lines(text)
    headings: list[tuple[int, re.Match[str]]] = []
    for index, line in enumerate(visible_lines):
        match = HEADING_LINE_RE.match(line.rstrip("\r\n"))
        if match is not None:
            headings.append((index, match))

    sections: list[MarkdownSection] = []
    for index, (line_index, heading) in enumerate(headings):
        body_end_index = (
            headings[index + 1][0]
            if index + 1 < len(headings)
            else len(source_lines)
        )
        sections.append(
            MarkdownSection(
                title=visible_heading_title(heading.group(1)),
                body="".join(source_lines[line_index + 1 : body_end_index]),
                body_start_line=line_index + 2,
            )
        )
    return sections


def iter_links_in_text(
    text: str,
    source: Path,
    start_line: int = 1,
) -> list[MarkdownLink]:
    links: list[MarkdownLink] = []
    for offset, line in enumerate(visible_markdown_lines(text), start=0):
        line_number = start_line + offset
        for match in MARKDOWN_LINK_RE.finditer(line):
            backslashes = 0
            cursor = match.start() - 1
            while cursor >= 0 and line[cursor] == "\\":
                backslashes += 1
                cursor -= 1
            if backslashes % 2 == 1:
                continue
            links.append(
                MarkdownLink(
                    source=source,
                    line=line_number,
                    target=strip_link_title(match.group(2)),
                )
            )
    return links


def iter_markdown_links(path: Path) -> list[MarkdownLink]:
    return iter_links_in_text(
        path.read_text(encoding="utf-8"),
        source=path,
    )


def lexical_absolute(path: Path) -> Path:
    return Path(os.path.abspath(os.path.normpath(path)))


def actual_case_path(path: Path, repo_root: Path) -> Path | None:
    root = repo_root.resolve()
    try:
        relative = path.relative_to(root)
    except ValueError:
        return None

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
            child
            for child in children
            if child.name.casefold() == part.casefold()
        ]
        if len(folded) != 1:
            return None
        current = folded[0]

    return current


def resolve_local_target(
    link: MarkdownLink,
    repo_root: Path,
) -> LocalTarget | None:
    destination = unquote(link.target.strip())
    if not destination or is_external_link(destination):
        return None

    path_part = destination.split("#", 1)[0].split("?", 1)[0]
    if not path_part:
        return None
    requested = lexical_absolute(link.source.parent / path_part)
    root = repo_root.resolve()
    try:
        requested.relative_to(root)
    except ValueError:
        return LocalTarget(
            requested=requested,
            actual=None,
            case_mismatch=False,
        )

    actual = actual_case_path(requested, root)
    return LocalTarget(
        requested=requested,
        actual=actual,
        case_mismatch=actual is not None and requested != actual,
    )


def repo_relative(path: Path, repo_root: Path) -> str:
    return path.relative_to(repo_root.resolve()).as_posix()


def path_uses_symlink(path: Path, repo_root: Path) -> bool:
    root = repo_root.resolve()
    relative = path.relative_to(root)
    current = root
    for part in relative.parts:
        current /= part
        if current.is_symlink():
            return True
    return False


def source_location(link: MarkdownLink, repo_root: Path) -> str:
    return f"{repo_relative(link.source, repo_root)}:{link.line}"


def case_mismatch_error(
    link: MarkdownLink,
    target: LocalTarget,
    repo_root: Path,
) -> str:
    assert target.actual is not None
    return (
        f"path case mismatch in {source_location(link, repo_root)}: "
        f"{link.target} points to {repo_relative(target.actual, repo_root)}"
    )


def active_question_links(
    index_path: Path,
    repo_root: Path,
) -> tuple[list[tuple[MarkdownLink, Path]], list[str]]:
    errors: list[str] = []
    questions: list[tuple[MarkdownLink, Path]] = []
    seen: set[Path] = set()
    text = index_path.read_text(encoding="utf-8")
    sections = markdown_sections(text)

    active_sections: list[MarkdownSection] = []
    for title in sorted(ACTIVE_SECTION_TITLES):
        matches = [section for section in sections if section.title == title]
        if len(matches) != 1:
            errors.append(
                f"questions index must contain exactly one "
                f"'## {title}' section: found {len(matches)}"
            )
        active_sections.extend(matches)

    for section in active_sections:
        for link in iter_links_in_text(
            section.body,
            source=index_path,
            start_line=section.body_start_line,
        ):
            destination = unquote(link.target.strip())
            path_part = destination.split("#", 1)[0].split("?", 1)[0]
            if not path_part or is_external_link(destination):
                errors.append(
                    f"active question entry has no local file path in "
                    f"{source_location(link, repo_root)}: {link.target!r}"
                )
                continue
            target = resolve_local_target(link, repo_root)
            if target is None:
                continue
            if target.actual is None:
                errors.append(
                    f"target does not exist in "
                    f"{source_location(link, repo_root)}: {link.target}"
                )
                continue
            if target.case_mismatch:
                errors.append(case_mismatch_error(link, target, repo_root))

            actual = target.actual
            if path_uses_symlink(actual, repo_root):
                errors.append(
                    f"active question entry uses a symbolic link in "
                    f"{source_location(link, repo_root)}: {link.target}"
                )
                continue
            questions_dir = (repo_root / "Вопросы").resolve()
            try:
                relative = actual.relative_to(questions_dir)
            except ValueError:
                errors.append(
                    f"active question link leaves Вопросы/ in "
                    f"{source_location(link, repo_root)}: {link.target}"
                )
                continue
            if (
                len(relative.parts) != 1
                or relative.name == "README.md"
                or actual.suffix != ".md"
                or not actual.is_file()
            ):
                errors.append(
                    f"active question link is not a question Markdown file in "
                    f"{source_location(link, repo_root)}: {link.target}"
                )
                continue
            if actual in seen:
                errors.append(
                    f"active question is listed more than once: "
                    f"{repo_relative(actual, repo_root)}"
                )
                continue
            seen.add(actual)
            questions.append((link, actual))

    return questions, errors


def target_section(
    question: Path,
) -> MarkdownSection | None:
    matches = [
        section
        for section in markdown_sections(question.read_text(encoding="utf-8"))
        if section.title == TARGETS_SECTION_TITLE
    ]
    if len(matches) != 1:
        return None
    return matches[0]


def has_backlink(
    target_path: Path,
    question_path: Path,
    repo_root: Path,
) -> tuple[bool, list[str]]:
    errors: list[str] = []
    found = False
    for link in iter_markdown_links(target_path):
        target = resolve_local_target(link, repo_root)
        if target is None or target.actual != question_path:
            continue
        found = True
        if target.case_mismatch:
            errors.append(case_mismatch_error(link, target, repo_root))
    return found, errors


def audit_repository(repo_root: str | Path) -> ValidationResult:
    root = Path(repo_root).resolve()
    index_path = root / QUESTIONS_INDEX
    if not index_path.is_file():
        return ValidationResult(
            errors=(f"questions index does not exist: {QUESTIONS_INDEX}",),
            question_count=0,
            target_count=0,
        )

    questions, errors = active_question_links(index_path, root)
    target_count = 0

    for _, question_path in questions:
        section = target_section(question_path)
        question_relative = repo_relative(question_path, root)
        if section is None:
            errors.append(
                f"active question must contain exactly one "
                f"'## {TARGETS_SECTION_TITLE}' section: {question_relative}"
            )
            continue

        local_links = [
            link
            for link in iter_links_in_text(
                section.body,
                source=question_path,
                start_line=section.body_start_line,
            )
            if not is_external_link(link.target)
        ]
        if not local_links:
            errors.append(
                f"active question has no local targets in "
                f"'## {TARGETS_SECTION_TITLE}': {question_relative}"
            )
            continue

        seen_targets: set[Path] = set()
        for link in local_links:
            target_count += 1
            destination = unquote(link.target.strip())
            path_part = destination.split("#", 1)[0].split("?", 1)[0]
            if not path_part:
                errors.append(
                    f"declared target has no local file path in "
                    f"{source_location(link, root)}: {link.target!r}"
                )
                continue
            target = resolve_local_target(link, root)
            if target is None:
                continue
            if target.actual is None or not target.actual.is_file():
                errors.append(
                    f"target does not exist in "
                    f"{source_location(link, root)}: {link.target}"
                )
                continue
            if target.actual.suffix != ".md":
                errors.append(
                    f"declared target is not a Markdown file in "
                    f"{source_location(link, root)}: "
                    f"{repo_relative(target.actual, root)}"
                )
                continue
            if target.case_mismatch:
                errors.append(case_mismatch_error(link, target, root))

            actual = target.actual
            if path_uses_symlink(actual, root):
                errors.append(
                    f"declared target uses a symbolic link in "
                    f"{source_location(link, root)}: {link.target}"
                )
                continue
            if actual in seen_targets:
                errors.append(
                    f"duplicate declared target in {question_relative}: "
                    f"{repo_relative(actual, root)}"
                )
                continue
            seen_targets.add(actual)

            found, backlink_errors = has_backlink(
                actual,
                question_path,
                root,
            )
            errors.extend(backlink_errors)
            if not found:
                errors.append(
                    f"missing backlink: {repo_relative(actual, root)} "
                    f"must link to {question_relative}"
                )

    return ValidationResult(
        errors=tuple(errors),
        question_count=len(questions),
        target_count=target_count,
    )


def validate_repository(repo_root: str | Path) -> list[str]:
    return list(audit_repository(repo_root).errors)


def main() -> int:
    args = parse_args()
    result = audit_repository(args.repo_root)
    if result.errors:
        for error in result.errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(
        "Question backlink check passed: "
        f"{result.question_count} active questions, "
        f"{result.target_count} declared targets."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
