#!/usr/bin/env python3
"""Check that README indexes every numbered documentation entrypoint."""

from __future__ import annotations

import argparse
import posixpath
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlsplit


PROJECT_FILES_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-proyektnyiye-fajlyi"
    / "scripts"
)
if str(PROJECT_FILES_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(PROJECT_FILES_SCRIPTS))

from project_files import ProjectFilesError, project_markdown_paths


ROOT_README = Path("README.md")
DOCUMENTATION_DIRECTORY = "Документация"
THEMATIC_SECTION_TITLE = "Документация по темам"
NUMBERED_DOCUMENT_RE = re.compile(r"^\d{2}-.+\.md$")
NUMBERED_DIRECTORY_RE = re.compile(r"^\d{2}-.+$")
LEVEL_TWO_HEADING_RE = re.compile(
    r"^ {0,3}##(?!#)[ \t]+(.+?)(?:[ \t]+#+[ \t]*)?$"
)
SECTION_BOUNDARY_RE = re.compile(r"^ {0,3}#{1,2}(?!#)(?:[ \t]+|$)")
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[[^\]\n]+\]\(([^)\n]+)\)")
FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")


@dataclass(frozen=True)
class ValidationResult:
    errors: tuple[str, ...]
    required_count: int
    indexed_count: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    return parser.parse_args()


def required_documentation_entrypoints(repo_root: Path) -> tuple[str, ...]:
    root = repo_root.resolve()
    required: set[str] = set()
    for path in project_markdown_paths(root):
        relative = path.relative_to(root)
        parts = relative.parts
        if (
            len(parts) == 2
            and parts[0] == DOCUMENTATION_DIRECTORY
            and NUMBERED_DOCUMENT_RE.fullmatch(parts[1]) is not None
        ):
            required.add(relative.as_posix())
            continue
        if (
            len(parts) == 3
            and parts[0] == DOCUMENTATION_DIRECTORY
            and NUMBERED_DIRECTORY_RE.fullmatch(parts[1]) is not None
            and parts[2] == "README.md"
        ):
            required.add(relative.as_posix())
    return tuple(sorted(required))


def mask_invisible_markdown(text: str) -> list[str]:
    visible_lines: list[str] = []
    fence: tuple[str, int] | None = None
    in_comment = False

    for source_line in text.splitlines():
        line = source_line
        if fence is not None:
            match = FENCE_RE.match(line)
            if match is not None:
                marker, remainder = match.groups()
                if (
                    marker[0] == fence[0]
                    and len(marker) >= fence[1]
                    and not remainder.strip()
                ):
                    fence = None
            visible_lines.append("")
            continue

        masked: list[str] = []
        cursor = 0
        while cursor < len(line):
            if in_comment:
                end = line.find("-->", cursor)
                if end < 0:
                    cursor = len(line)
                    break
                cursor = end + 3
                in_comment = False
                continue
            start = line.find("<!--", cursor)
            if start < 0:
                masked.append(line[cursor:])
                break
            masked.append(line[cursor:start])
            cursor = start + 4
            in_comment = True

        visible = "".join(masked)
        if visible.startswith("    ") or visible.startswith("\t"):
            visible_lines.append("")
            continue
        match = FENCE_RE.match(visible)
        if match is not None:
            marker = match.group(1)
            fence = (marker[0], len(marker))
            visible_lines.append("")
            continue

        visible_lines.append(visible)
    return mask_inline_code("\n".join(visible_lines)).split("\n")


def mask_inline_code(text: str) -> str:
    masked = list(text)
    cursor = 0
    while cursor < len(text):
        start = text.find("`", cursor)
        if start < 0:
            break
        delimiter_end = start
        while delimiter_end < len(text) and text[delimiter_end] == "`":
            delimiter_end += 1
        delimiter_length = delimiter_end - start
        end = matching_backtick_run(text, delimiter_end, delimiter_length)
        if end < 0:
            cursor = delimiter_end
            continue
        for index in range(start, end + delimiter_length):
            if masked[index] != "\n":
                masked[index] = " "
        cursor = end + delimiter_length
    return "".join(masked)


def matching_backtick_run(text: str, cursor: int, length: int) -> int:
    while cursor < len(text):
        start = text.find("`", cursor)
        if start < 0:
            return -1
        end = start
        while end < len(text) and text[end] == "`":
            end += 1
        if end - start == length:
            return start
        cursor = end
    return -1


def thematic_section_lines(text: str) -> tuple[list[str] | None, str | None]:
    lines = mask_invisible_markdown(text)
    section_starts = [
        index
        for index, line in enumerate(lines)
        if (match := LEVEL_TWO_HEADING_RE.fullmatch(line)) is not None
        and match.group(1).strip() == THEMATIC_SECTION_TITLE
    ]
    if not section_starts:
        return None, f"README.md is missing section: {THEMATIC_SECTION_TITLE}"
    if len(section_starts) != 1:
        return None, f"README.md has duplicate section: {THEMATIC_SECTION_TITLE}"

    start = section_starts[0] + 1
    end = len(lines)
    for index in range(start, len(lines)):
        if SECTION_BOUNDARY_RE.match(lines[index]) is not None:
            end = index
            break
    return lines[start:end], None


def strip_link_title(destination: str) -> str:
    value = destination.strip()
    if value.startswith("<") and ">" in value:
        return value[1 : value.index(">")]
    title = re.search(r"\s+['\"]", value)
    return value[: title.start()] if title is not None else value


def normalized_root_target(destination: str) -> str | None:
    value = strip_link_title(destination)
    if value.startswith("//"):
        return None
    parsed = urlsplit(value)
    if parsed.scheme or parsed.netloc:
        return None
    decoded = unquote(parsed.path)
    if not decoded or decoded.startswith("/"):
        return None
    normalized = posixpath.normpath(decoded)
    if normalized == ".." or normalized.startswith("../"):
        return None
    return normalized.removeprefix("./")


def indexed_targets(section_lines: list[str]) -> set[str]:
    targets: set[str] = set()
    for line in section_lines:
        for match in MARKDOWN_LINK_RE.finditer(line):
            target = normalized_root_target(match.group(1))
            if target is not None:
                targets.add(target)
    return targets


def validate_repository(repo_root: str | Path) -> ValidationResult:
    root = Path(repo_root).resolve()
    required = required_documentation_entrypoints(root)
    readme = root / ROOT_README
    if not readme.is_file():
        return ValidationResult(
            errors=("README.md is missing",),
            required_count=len(required),
            indexed_count=0,
        )

    section, section_error = thematic_section_lines(
        readme.read_text(encoding="utf-8")
    )
    if section_error is not None:
        return ValidationResult(
            errors=(section_error,),
            required_count=len(required),
            indexed_count=0,
        )
    assert section is not None

    targets = indexed_targets(section)
    required_set = set(required)
    missing = sorted(required_set - targets)
    return ValidationResult(
        errors=tuple(
            f"missing README thematic-index link: {path}"
            for path in missing
        ),
        required_count=len(required),
        indexed_count=len(required_set & targets),
    )


def main() -> int:
    args = parse_args()
    try:
        result = validate_repository(args.repo_root)
    except (OSError, ProjectFilesError, UnicodeError) as exc:
        print(f"README index check failed: {exc}", file=sys.stderr)
        return 1

    if result.errors:
        for error in result.errors:
            print(error, file=sys.stderr)
        print(
            "README documentation index is incomplete: "
            f"required={result.required_count} "
            f"indexed={result.indexed_count} "
            f"missing={len(result.errors)}",
            file=sys.stderr,
        )
        return 1

    print(
        "README documentation index is complete: "
        f"required={result.required_count} indexed={result.indexed_count}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
