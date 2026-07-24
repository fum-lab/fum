#!/usr/bin/env python3
"""Rename one tracked FUM file and preserve supported local Markdown links."""

from __future__ import annotations

import argparse
import contextlib
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import unicodedata
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path, PurePosixPath, PureWindowsPath
from urllib.parse import unquote_to_bytes


PROJECT_FILES_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-proyektnyiye-fajlyi"
    / "scripts"
)
if str(PROJECT_FILES_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(PROJECT_FILES_SCRIPTS))

from project_files import (  # noqa: E402
    ProjectFilesError,
    normalized_project_relative_path,
    path_uses_symlink_component,
    project_markdown_paths,
)


STEP_CARDS_DIRECTORY = PurePosixPath("Планирование/карточки-шагов")
PROTECTED_SOURCES_DIRECTORY = "Источники"
REQUESTS_DIRECTORY = "Запросы"
REQUEST_TEXT_HEADING = "Текст запроса"

TILDE = chr(126)
FENCE_OPEN_RE = re.compile(
    r"^[ ]{0,3}(`{3,}|" + re.escape(TILDE) + r"{3,})(.*)$"
)
REQUEST_HEADING_RE = re.compile(
    r"^[ ]{0,3}##(?!#)[ \t]+(?P<title>.*?)[ \t]*$"
)
REFERENCE_PREFIX_RE = re.compile(
    r"^[ ]{0,3}\[(?:\\.|[^\]\\\n])+\]:[ \t]*"
)
SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
HEX_DIGITS = frozenset("0123456789abcdefABCDEF")
MARKDOWN_ESCAPABLE = frozenset(
    r"!\"#$%&'()*+,-./:;<=>?@[\]^_`{|}" + TILDE
)


class RenameError(RuntimeError):
    """A fail-closed preflight or transactional-apply error."""


class CliParser(argparse.ArgumentParser):
    """Use one stable non-zero code for invalid command arguments."""

    def error(self, message: str) -> None:
        self.print_usage(sys.stderr)
        self.exit(1, f"{self.prog}: error: {message}\n")


@dataclass(frozen=True)
class LinkToken:
    destination_start: int
    destination_end: int
    raw_destination: str
    angle_destination: bool
    kind: str
    line: int


@dataclass(frozen=True)
class WikiToken:
    start: int
    raw_target: str
    line: int


@dataclass(frozen=True)
class Destination:
    is_local: bool
    decoded_path: str
    suffix: str
    target: Path | None


@dataclass(frozen=True)
class FileSnapshot:
    relative: PurePosixPath
    absolute: Path
    data: bytes
    mode: int
    device: int
    inode: int
    size: int
    mtime_ns: int


@dataclass(frozen=True)
class DirectorySnapshot:
    relative: PurePosixPath
    absolute: Path
    mode: int
    device: int
    inode: int


@dataclass(frozen=True)
class Mutation:
    original: PurePosixPath
    output: PurePosixPath
    data: bytes
    mode: int


@dataclass(frozen=True)
class RenamePlan:
    root: Path
    source: PurePosixPath
    destination: PurePosixPath
    updated_links: int
    mutations: tuple[Mutation, ...]
    snapshots: tuple[FileSnapshot, ...]
    destination_directories: tuple[DirectorySnapshot, ...]
    markdown_inventory: tuple[PurePosixPath, ...]
    git_status: bytes
    git_index: bytes
    head: str


@dataclass(frozen=True)
class PreparedWrite:
    output: Path
    replacement: Path
    backup: Path


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = CliParser(description=__doc__)
    parser.add_argument("mode", choices=("plan", "apply"))
    parser.add_argument("--source", required=True)
    parser.add_argument("--destination", required=True)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    return parser.parse_args(argv)


def run_git(
    root: Path,
    *arguments: str,
    check: bool = True,
) -> subprocess.CompletedProcess[bytes]:
    environment = {
        key: value
        for key, value in os.environ.items()
        if not key.startswith("GIT_")
    }
    result = subprocess.run(
        [
            "git",
            "--no-replace-objects",
            "--literal-pathspecs",
            "--no-optional-locks",
            "-C",
            str(root),
            *arguments,
        ],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=environment,
    )
    if check and result.returncode != 0:
        detail = os.fsdecode(result.stderr).strip() or "unknown Git error"
        raise RenameError(f"git {' '.join(arguments)} failed: {detail}")
    return result


@contextlib.contextmanager
def without_inherited_git_environment() -> Iterator[None]:
    inherited = {
        key: value
        for key, value in os.environ.items()
        if key.startswith("GIT_")
    }
    for key in inherited:
        os.environ.pop(key, None)
    os.environ["GIT_OPTIONAL_LOCKS"] = "0"
    try:
        yield
    finally:
        os.environ.pop("GIT_OPTIONAL_LOCKS", None)
        os.environ.update(inherited)


def repository_root(value: Path) -> Path:
    root = value.expanduser().resolve()
    if not root.is_dir():
        raise RenameError(f"repository root is not a directory: {root}")
    result = run_git(root, "rev-parse", "--show-toplevel")
    discovered = Path(os.fsdecode(result.stdout).strip()).resolve()
    if discovered != root:
        raise RenameError(
            f"--repo-root must name the repository root: {root} != {discovered}"
        )
    return root


def portable_name_key(value: str) -> str:
    return unicodedata.normalize("NFC", value).casefold()


def ensure_portable_destination(
    root: Path,
    source: PurePosixPath,
    destination: PurePosixPath,
) -> None:
    current = root
    for part in destination.parts[:-1]:
        exact = current / part
        if not exact.exists() or not exact.is_dir() or exact.is_symlink():
            raise RenameError(
                f"destination parent does not exist as a real directory: "
                f"{destination.parent}"
            )
        collisions = [
            child.name
            for child in current.iterdir()
            if portable_name_key(child.name) == portable_name_key(part)
        ]
        if collisions != [part]:
            rendered = ", ".join(sorted(collisions)) or part
            raise RenameError(
                f"portable path collision in destination component {part!r}: "
                f"{rendered}"
            )
        current = exact

    children = list(current.iterdir())
    if any(child.name == destination.name for child in children):
        raise RenameError(f"destination already exists: {destination}")

    final_key = portable_name_key(destination.name)
    collisions = sorted(
        child.name
        for child in children
        if portable_name_key(child.name) == final_key
    )
    if collisions:
        rendered = ", ".join(collisions)
        raise RenameError(
            f"portable filename collision for {destination.name!r}: {rendered}"
        )
    if len(destination.name.encode("utf-8")) > 255:
        raise RenameError("destination filename exceeds 255 UTF-8 bytes")
    if source == destination:
        raise RenameError("source and destination paths are identical")


def snapshot_destination_directories(
    root: Path,
    destination: PurePosixPath,
) -> tuple[DirectorySnapshot, ...]:
    snapshots: list[DirectorySnapshot] = []
    current = root
    for index, part in enumerate(destination.parts[:-1], start=1):
        current /= part
        try:
            current_stat = current.stat(follow_symlinks=False)
        except OSError as error:
            raise RenameError(
                f"cannot inspect destination directory: {destination.parent}"
            ) from error
        if not stat.S_ISDIR(current_stat.st_mode) or stat.S_ISLNK(current_stat.st_mode):
            raise RenameError(
                f"destination parent is not a real directory: {destination.parent}"
            )
        snapshots.append(
            DirectorySnapshot(
                relative=PurePosixPath(*destination.parts[:index]),
                absolute=current,
                mode=current_stat.st_mode,
                device=current_stat.st_dev,
                inode=current_stat.st_ino,
            )
        )
    return tuple(snapshots)


def verify_destination_fence(plan: RenamePlan) -> None:
    ensure_portable_destination(plan.root, plan.source, plan.destination)
    destination_path = plan.root.joinpath(*plan.destination.parts)
    if path_uses_symlink_component(destination_path, plan.root):
        raise RenameError(
            f"snapshot fence found a symbolic-link destination component: "
            f"{plan.destination}"
        )
    current = snapshot_destination_directories(plan.root, plan.destination)
    if current != plan.destination_directories:
        raise RenameError("snapshot fence changed destination directory identity")


def git_index_state(root: Path) -> bytes:
    return run_git(
        root,
        "-c",
        "core.quotepath=false",
        "ls-files",
        "--stage",
        "-z",
        "--",
    ).stdout


def validate_paths(
    root: Path,
    raw_source: str,
    raw_destination: str,
) -> tuple[PurePosixPath, PurePosixPath]:
    try:
        source_value = normalized_project_relative_path(
            raw_source,
            root,
            field_name="source repository path",
            must_exist=True,
        )
        destination_value = normalized_project_relative_path(
            raw_destination,
            root,
            field_name="destination repository path",
            must_exist=False,
        )
    except ProjectFilesError as error:
        raise RenameError(str(error)) from error

    source = PurePosixPath(source_value)
    destination = PurePosixPath(destination_value)
    if source.parts[0] == PROTECTED_SOURCES_DIRECTORY:
        raise RenameError("защищённый каталог Источники/ нельзя переименовывать")
    if destination.parts[0] == PROTECTED_SOURCES_DIRECTORY:
        raise RenameError("нельзя переносить файл в защищённый каталог Источники/")
    if source.parent == STEP_CARDS_DIRECTORY or destination.parent == STEP_CARDS_DIRECTORY:
        raise RenameError(
            "step cards require the specialized rename-step-card.py command"
        )

    source_path = root.joinpath(*source.parts)
    destination_path = root.joinpath(*destination.parts)
    if path_uses_symlink_component(source_path, root):
        raise RenameError(f"source uses a symbolic-link component: {source}")
    if path_uses_symlink_component(destination_path, root):
        raise RenameError(f"destination uses a symbolic-link component: {destination}")

    tracked = run_git(
        root,
        "ls-files",
        "--cached",
        "--error-unmatch",
        "-z",
        "--",
        str(source),
        check=False,
    )
    tracked_paths = [
        os.fsdecode(value)
        for value in tracked.stdout.split(b"\0")
        if value
    ]
    if tracked.returncode != 0 or tracked_paths != [str(source)]:
        raise RenameError(f"source file is not tracked by Git: {source}")
    source_status = run_git(
        root,
        "-c",
        "core.quotepath=false",
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=no",
        "--",
        str(source),
    ).stdout
    if source_status:
        raise RenameError(
            "source must be clean in both the Git index and working tree before rename"
        )

    indexed = run_git(
        root,
        "ls-files",
        "--cached",
        "-z",
        "--",
    ).stdout
    destination_key = tuple(
        portable_name_key(part)
        for part in destination.parts
    )
    for raw_path in indexed.split(b"\0"):
        if not raw_path:
            continue
        indexed_path = PurePosixPath(os.fsdecode(raw_path))
        if indexed_path == destination:
            raise RenameError(f"destination already exists in the Git index: {destination}")
        indexed_key = tuple(portable_name_key(part) for part in indexed_path.parts)
        if indexed_key == destination_key:
            raise RenameError(
                f"portable destination collision in the Git index for {destination}: "
                f"{indexed_path}"
            )

    ensure_portable_destination(root, source, destination)
    return source, destination


def line_ranges(text: str) -> list[tuple[int, int, str]]:
    ranges: list[tuple[int, int, str]] = []
    offset = 0
    for line in text.splitlines(keepends=True):
        ranges.append((offset, offset + len(line), line))
        offset += len(line)
    if offset < len(text) or not ranges:
        ranges.append((offset, len(text), text[offset:]))
    return ranges


def mark(mask: bytearray, start: int, end: int) -> None:
    if end > start:
        mask[start:end] = b"\x01" * (end - start)


def markdown_container_content_start(content: str) -> int:
    """Return the offset after explicit blockquote/list container markers."""

    cursor = 0
    while cursor < len(content):
        probe = cursor
        spaces = 0
        while probe < len(content) and content[probe] == " " and spaces < 3:
            probe += 1
            spaces += 1
        if probe < len(content) and content[probe] == ">":
            probe += 1
            if probe < len(content) and content[probe] in " \t":
                probe += 1
            cursor = probe
            continue
        list_marker = re.match(
            r"(?:[*+-]|\d{1,9}[.)])(?:[ \t]+|$)",
            content[probe:],
        )
        if list_marker is not None:
            cursor = probe + list_marker.end()
            continue
        return cursor
    return cursor


def markdown_hidden_mask(text: str) -> bytearray:
    """Mask frontmatter, Markdown code, HTML comments, and code spans."""

    mask = bytearray(len(text))
    lines = line_ranges(text)
    frontmatter_end = 0
    if lines and lines[0][2].rstrip("\r\n") == "+++":
        for start, end, line in lines[1:]:
            if line.rstrip("\r\n") == "+++":
                frontmatter_end = end
                mark(mask, 0, end)
                break
        if frontmatter_end == 0:
            mark(mask, 0, len(text))
            return mask

    in_comment = False
    fence_marker: str | None = None
    fence_length = 0
    for start, end, line_with_ending in lines:
        if end <= frontmatter_end:
            continue
        content = line_with_ending.rstrip("\r\n")
        content_end = start + len(content)
        if fence_marker is not None:
            mark(mask, start, end)
            container_start = markdown_container_content_start(content)
            closing = re.match(
                rf"^[ ]{{0,3}}{re.escape(fence_marker)}{{{fence_length},}}[ \t]*$",
                content[container_start:],
            )
            if closing is not None:
                fence_marker = None
                fence_length = 0
            continue

        container_start = markdown_container_content_start(content)
        container_content = content[container_start:]
        if not in_comment and (
            container_content.startswith("    ")
            or container_content.startswith("\t")
        ):
            mark(mask, start, end)
            continue

        cursor = start
        while cursor < content_end:
            if in_comment:
                close = text.find("-->", cursor, content_end)
                if close < 0:
                    mark(mask, cursor, content_end)
                    cursor = content_end
                    break
                mark(mask, cursor, close + 3)
                cursor = close + 3
                in_comment = False
                continue
            opening = text.find("<!--", cursor, content_end)
            if opening < 0:
                break
            close = text.find("-->", opening + 4, content_end)
            if close < 0:
                mark(mask, opening, content_end)
                in_comment = True
                break
            mark(mask, opening, close + 3)
            cursor = close + 3

        visible = "".join(
            " " if mask[index] else text[index]
            for index in range(start, content_end)
        )
        container_start = markdown_container_content_start(visible)
        opening_match = FENCE_OPEN_RE.match(visible[container_start:])
        if opening_match is not None:
            marker = opening_match.group(1)
            mark(mask, start, end)
            fence_marker = marker[0]
            fence_length = len(marker)

    cursor = 0
    while cursor < len(text):
        if mask[cursor] or text[cursor] != "`":
            cursor += 1
            continue
        run_end = cursor
        while run_end < len(text) and not mask[run_end] and text[run_end] == "`":
            run_end += 1
        length = run_end - cursor
        candidate = run_end
        closing = -1
        while candidate < len(text):
            candidate = text.find("`", candidate)
            if candidate < 0:
                break
            if mask[candidate]:
                candidate += 1
                continue
            candidate_end = candidate
            while (
                candidate_end < len(text)
                and not mask[candidate_end]
                and text[candidate_end] == "`"
            ):
                candidate_end += 1
            if candidate_end - candidate == length:
                closing = candidate_end
                break
            candidate = candidate_end
        if closing < 0:
            cursor = run_end
            continue
        mark(mask, cursor, closing)
        cursor = closing
    return mask


def is_escaped(text: str, position: int) -> bool:
    backslashes = 0
    cursor = position - 1
    while cursor >= 0 and text[cursor] == "\\":
        backslashes += 1
        cursor -= 1
    return backslashes % 2 == 1


def range_is_visible(mask: bytearray, start: int, end: int) -> bool:
    return not any(mask[start:end])


def skip_markdown_space_and_one_line_ending(
    text: str,
    cursor: int,
    limit: int,
) -> int:
    """Skip spaces/tabs and at most one Markdown line ending."""

    while cursor < limit and text[cursor] in " \t":
        cursor += 1
    if cursor >= limit:
        return cursor
    if text.startswith("\r\n", cursor):
        cursor += 2
    elif text[cursor] in "\r\n":
        cursor += 1
    else:
        return cursor
    while cursor < limit and text[cursor] in " \t":
        cursor += 1
    return cursor


def physical_line_bounds(text: str, start: int) -> tuple[int, int]:
    """Return content end and following-line start for one physical line."""

    newline = text.find("\n", start)
    if newline < 0:
        return len(text), len(text)
    content_end = newline - 1 if newline > start and text[newline - 1] == "\r" else newline
    return content_end, newline + 1


def parse_title(text: str, cursor: int, limit: int) -> int | None:
    if cursor >= limit or text[cursor] not in ('"', "'", "("):
        return None
    opening = text[cursor]
    closing = ")" if opening == "(" else opening
    cursor += 1
    depth = 1
    while cursor < limit:
        if text[cursor] == "\\" and cursor + 1 < limit:
            cursor += 2
            continue
        if opening == "(" and text[cursor] == "(":
            depth += 1
        elif text[cursor] == closing:
            depth -= 1
            if depth == 0:
                return cursor + 1
        cursor += 1
    return None


def parse_inline_destination(
    text: str,
    opening_parenthesis: int,
    mask: bytearray,
) -> tuple[int, int, bool, int] | None:
    limit = len(text)
    cursor = opening_parenthesis + 1
    cursor = skip_markdown_space_and_one_line_ending(text, cursor, limit)
    if cursor < limit and text[cursor] == ")":
        token_end = cursor + 1
        if not range_is_visible(mask, opening_parenthesis, token_end):
            return None
        return cursor, cursor, False, token_end

    angle = cursor < limit and text[cursor] == "<"
    if angle:
        destination_start = cursor + 1
        cursor = destination_start
        while cursor < limit:
            if text[cursor] in "\r\n":
                return None
            if text[cursor] == "\\" and cursor + 1 < limit:
                cursor += 2
                continue
            if text[cursor] == ">":
                destination_end = cursor
                cursor += 1
                break
            if text[cursor] == "<":
                return None
            cursor += 1
        else:
            return None
    else:
        destination_start = cursor
        depth = 0
        while cursor < limit:
            character = text[cursor]
            if character == "\\" and cursor + 1 < limit:
                cursor += 2
                continue
            if character in " \t\r\n":
                if depth != 0:
                    return None
                break
            if character == "(":
                depth += 1
                cursor += 1
                continue
            if character == ")":
                if depth == 0:
                    destination_end = cursor
                    token_end = cursor + 1
                    if not range_is_visible(
                        mask,
                        opening_parenthesis,
                        token_end,
                    ):
                        return None
                    return destination_start, destination_end, False, token_end
                depth -= 1
            cursor += 1
        else:
            return None
        if depth != 0:
            return None
        destination_end = cursor

    separator_start = cursor
    cursor = skip_markdown_space_and_one_line_ending(text, cursor, limit)
    if cursor < limit and text[cursor] != ")":
        if cursor == separator_start:
            return None
        title_end = parse_title(text, cursor, limit)
        if title_end is None:
            return None
        cursor = title_end
        cursor = skip_markdown_space_and_one_line_ending(text, cursor, limit)
    if cursor >= limit or text[cursor] != ")":
        return None
    token_end = cursor + 1
    if not range_is_visible(mask, opening_parenthesis, token_end):
        return None
    return destination_start, destination_end, angle, token_end


def matching_label_bracket(
    text: str,
    opening: int,
    mask: bytearray,
) -> int | None:
    depth = 1
    cursor = opening + 1
    while cursor < len(text):
        if mask[cursor] or text[cursor] == "\n":
            return None
        if text[cursor] == "\\" and cursor + 1 < len(text):
            cursor += 2
            continue
        if text[cursor] == "[":
            depth += 1
        elif text[cursor] == "]":
            depth -= 1
            if depth == 0:
                return cursor
        cursor += 1
    return None


def reference_destination_on_line(
    text: str,
    line_start: int,
    line_end: int,
    mask: bytearray,
) -> tuple[int, int, bool] | None:
    content = text[line_start:line_end].rstrip("\r\n")
    content_end = line_start + len(content)
    visible = "".join(
        " " if mask[index] else text[index]
        for index in range(line_start, content_end)
    )
    container_start = markdown_container_content_start(visible)
    match = REFERENCE_PREFIX_RE.match(visible[container_start:])
    if match is None:
        return None
    cursor = line_start + container_start + match.end()
    destination_content_end = content_end
    destination_line_end = line_end
    if cursor >= content_end:
        if line_end >= len(text):
            return None
        destination_content_end, destination_line_end = physical_line_bounds(
            text,
            line_end,
        )
        destination_line = text[line_end:destination_content_end]
        cursor = line_end + markdown_container_content_start(destination_line)
        while cursor < destination_content_end and text[cursor] in " \t":
            cursor += 1
        if cursor >= destination_content_end:
            return None
    angle = text[cursor] == "<"
    if angle:
        destination_start = cursor + 1
        cursor = destination_start
        while cursor < destination_content_end:
            if text[cursor] == "\\" and cursor + 1 < destination_content_end:
                cursor += 2
                continue
            if text[cursor] == ">":
                destination_end = cursor
                cursor += 1
                break
            if text[cursor] == "<":
                return None
            cursor += 1
        else:
            return None
    else:
        destination_start = cursor
        depth = 0
        while cursor < destination_content_end and text[cursor] not in " \t":
            if text[cursor] == "\\" and cursor + 1 < destination_content_end:
                cursor += 2
                continue
            if text[cursor] == "(":
                depth += 1
            elif text[cursor] == ")":
                if depth == 0:
                    return None
                depth -= 1
            cursor += 1
        if depth != 0:
            return None
        destination_end = cursor
    if destination_end == destination_start:
        return None
    while cursor < destination_content_end and text[cursor] in " \t":
        cursor += 1
    title_limit = destination_content_end
    if cursor >= destination_content_end and destination_line_end < len(text):
        following_content_end, _following_line_end = physical_line_bounds(
            text,
            destination_line_end,
        )
        following_line = text[destination_line_end:following_content_end]
        title_cursor = (
            destination_line_end
            + markdown_container_content_start(following_line)
        )
        while title_cursor < following_content_end and text[title_cursor] in " \t":
            title_cursor += 1
        if (
            title_cursor < following_content_end
            and text[title_cursor] in ('"', "'", "(")
        ):
            cursor = title_cursor
            title_limit = following_content_end
    if cursor < title_limit:
        title_end = parse_title(text, cursor, title_limit)
        if title_end is None:
            return None
        cursor = title_end
        while cursor < title_limit and text[cursor] in " \t":
            cursor += 1
        if cursor != title_limit:
            return None
    if not range_is_visible(mask, line_start, max(destination_end, cursor)):
        return None
    return destination_start, destination_end, angle


def markdown_link_tokens(text: str, mask: bytearray) -> list[LinkToken]:
    tokens: list[LinkToken] = []
    occupied: set[tuple[int, int]] = set()
    for line_number, (start, end, _line) in enumerate(line_ranges(text), start=1):
        parsed = reference_destination_on_line(text, start, end, mask)
        if parsed is None:
            continue
        destination_start, destination_end, angle = parsed
        occupied.add((destination_start, destination_end))
        tokens.append(
            LinkToken(
                destination_start,
                destination_end,
                text[destination_start:destination_end],
                angle,
                "reference",
                line_number,
            )
        )

    cursor = 0
    while cursor < len(text):
        if mask[cursor]:
            cursor += 1
            continue
        image = (
            text[cursor] == "!"
            and cursor + 1 < len(text)
            and text[cursor + 1] == "["
            and not mask[cursor + 1]
        )
        opening = cursor + 1 if image else cursor
        if text[opening] != "[" or is_escaped(text, opening):
            cursor += 1
            continue
        if not image and opening > 0 and text[opening - 1] == "!" and not mask[opening - 1]:
            cursor += 1
            continue
        closing = matching_label_bracket(text, opening, mask)
        if closing is None or closing + 1 >= len(text) or text[closing + 1] != "(":
            cursor += 1
            continue
        parsed = parse_inline_destination(text, closing + 1, mask)
        if parsed is None:
            cursor += 1
            continue
        destination_start, destination_end, angle, token_end = parsed
        span = (destination_start, destination_end)
        if span not in occupied:
            tokens.append(
                LinkToken(
                    destination_start,
                    destination_end,
                    text[destination_start:destination_end],
                    angle,
                    "image" if image else "inline",
                    text.count("\n", 0, opening) + 1,
                )
            )
            occupied.add(span)
        cursor = token_end
    return sorted(tokens, key=lambda token: token.destination_start)


def request_text_spans(
    text: str,
    mask: bytearray,
    relative: PurePosixPath,
) -> tuple[tuple[int, int], ...]:
    headings: list[tuple[int, int, str]] = []
    for start, end, line in line_ranges(text):
        content = line.rstrip("\r\n")
        content_end = start + len(content)
        visible = "".join(
            " " if mask[index] else text[index]
            for index in range(start, content_end)
        )
        match = REQUEST_HEADING_RE.match(visible)
        if match is None:
            continue
        title = re.sub(r"[ \t]+#+[ \t]*$", "", match.group("title")).strip()
        headings.append((start, end, title))

    matches = [index for index, heading in enumerate(headings) if heading[2] == REQUEST_TEXT_HEADING]
    if len(matches) != 1:
        raise RenameError(
            f"{relative}: expected exactly one visible ## {REQUEST_TEXT_HEADING} section"
        )
    index = matches[0]
    body_start = headings[index][1]
    body_end = headings[index + 1][0] if index + 1 < len(headings) else len(text)
    return ((body_start, body_end),)


def position_in_spans(position: int, spans: tuple[tuple[int, int], ...]) -> bool:
    return any(start <= position < end for start, end in spans)


def visible_wikilinks(
    text: str,
    mask: bytearray,
) -> tuple[WikiToken, ...]:
    tokens: list[WikiToken] = []
    cursor = 0
    while True:
        cursor = text.find("[[", cursor)
        if cursor < 0:
            return tuple(tokens)
        if mask[cursor] or mask[cursor + 1] or is_escaped(text, cursor):
            cursor += 2
            continue
        line_end = text.find("\n", cursor + 2)
        if line_end < 0:
            line_end = len(text)
        closing = text.find("]]", cursor + 2, line_end)
        if closing < 0 or not range_is_visible(mask, cursor, closing + 2):
            cursor += 2
            continue
        tokens.append(
            WikiToken(
                start=cursor,
                raw_target=text[cursor + 2 : closing],
                line=text.count("\n", 0, cursor) + 1,
            )
        )
        cursor = closing + 2


def wikilink_targets_source(
    token: WikiToken,
    relative: PurePosixPath,
    source: PurePosixPath,
    root: Path,
) -> bool:
    raw_path = token.raw_target.split("|", 1)[0].split("#", 1)[0].strip()
    if not raw_path:
        return False
    unescaped = markdown_unescape(raw_path)
    decoded_variants = [unescaped]
    try:
        decoded = strict_percent_decode(
            unescaped,
            f"wikilink {relative}:{token.line}",
        )
    except RenameError:
        decoded = unescaped
    if decoded != unescaped:
        decoded_variants.append(decoded)

    source_path = root.joinpath(*source.parts)
    referrer = root.joinpath(*relative.parts)
    source_names = {
        portable_name_key(source.name),
        portable_name_key(source.stem),
    }
    for decoded_value in decoded_variants:
        candidate = PurePosixPath(decoded_value)
        explicit_path = len(candidate.parts) > 1 or "/" in decoded_value
        if not explicit_path:
            candidate_names = {portable_name_key(candidate.name)}
            if candidate.suffix.casefold() == ".md":
                candidate_names.add(portable_name_key(candidate.stem))
            if source_names & candidate_names:
                return True

        variants = [decoded_value]
        if not candidate.suffix and source.suffix.casefold() == ".md":
            variants.append(decoded_value + ".md")
        if decoded_value.startswith("/") or PureWindowsPath(decoded_value).drive:
            continue
        if "\\" in decoded_value:
            continue
        for value in variants:
            for base in (root, referrer.parent):
                resolved = Path(os.path.abspath(os.path.normpath(base / value)))
                if portable_name_key(os.fspath(resolved)) == portable_name_key(
                    os.fspath(source_path)
                ):
                    return True
    return False


def markdown_unescape(value: str) -> str:
    result: list[str] = []
    cursor = 0
    while cursor < len(value):
        if (
            value[cursor] == "\\"
            and cursor + 1 < len(value)
            and value[cursor + 1] in MARKDOWN_ESCAPABLE
        ):
            result.append(value[cursor + 1])
            cursor += 2
            continue
        result.append(value[cursor])
        cursor += 1
    return "".join(result)


def split_suffix(value: str) -> tuple[str, str]:
    for index, character in enumerate(value):
        if character in "?#" and not is_escaped(value, index):
            return value[:index], value[index:]
    return value, ""


def strict_percent_decode(value: str, context: str) -> str:
    cursor = 0
    while cursor < len(value):
        if value[cursor] != "%":
            cursor += 1
            continue
        if (
            cursor + 2 >= len(value)
            or value[cursor + 1] not in HEX_DIGITS
            or value[cursor + 2] not in HEX_DIGITS
        ):
            raise RenameError(f"invalid percent encoding in {context}: {value!r}")
        encoded_byte = int(value[cursor + 1 : cursor + 3], 16)
        if encoded_byte in (0x2F, 0x5C):
            raise RenameError(f"encoded path separator is forbidden in {context}")
        cursor += 3
    try:
        decoded = unquote_to_bytes(value).decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise RenameError(f"percent encoding is not valid UTF-8 in {context}") from error
    raw_parts = value.split("/")
    decoded_parts = decoded.split("/")
    for raw_part, decoded_part in zip(raw_parts, decoded_parts, strict=True):
        if "%" in raw_part and decoded_part in (".", ".."):
            raise RenameError(f"encoded dot segment is forbidden in {context}")
    if "\x00" in decoded or "\\" in decoded:
        raise RenameError(f"unsafe local path in {context}")
    return decoded


def resolve_destination(
    token: LinkToken,
    referrer: Path,
    root: Path,
    relative: PurePosixPath,
) -> Destination:
    raw_path, suffix = split_suffix(token.raw_destination)
    unescaped = markdown_unescape(raw_path)
    if unescaped.startswith("//"):
        return Destination(False, "", suffix, None)
    if SCHEME_RE.match(unescaped):
        if unescaped.casefold().startswith("file:"):
            raise RenameError(
                f"absolute file URI is forbidden in {relative}:{token.line}"
            )
        return Destination(False, "", suffix, None)
    decoded = strict_percent_decode(unescaped, f"{relative}:{token.line}")
    if decoded:
        windows = PureWindowsPath(decoded)
        if decoded.startswith("/") or windows.drive or windows.is_absolute():
            raise RenameError(
                f"absolute local Markdown path is forbidden in {relative}:{token.line}"
            )
        target = Path(os.path.abspath(os.path.normpath(referrer.parent / decoded)))
    else:
        target = referrer
    try:
        target.relative_to(root)
    except ValueError as error:
        raise RenameError(
            f"local Markdown link escapes repository in {relative}:{token.line}"
        ) from error
    return Destination(True, decoded, suffix, target)


def exact_existing_path(path: Path, root: Path) -> tuple[Path | None, bool]:
    try:
        relative = path.relative_to(root)
    except ValueError:
        return None, False
    current = root
    mismatch = False
    for part in relative.parts:
        if not current.is_dir():
            return None, mismatch
        children = list(current.iterdir())
        exact = next((child for child in children if child.name == part), None)
        if exact is not None:
            current = exact
            continue
        portable = [
            child
            for child in children
            if portable_name_key(child.name) == portable_name_key(part)
        ]
        if len(portable) != 1:
            return None, mismatch
        current = portable[0]
        mismatch = True
    return current, mismatch


def ensure_outgoing_target(
    destination: Destination,
    token: LinkToken,
    relative: PurePosixPath,
    root: Path,
) -> None:
    assert destination.target is not None
    actual, mismatch = exact_existing_path(destination.target, root)
    if actual is None or not actual.exists():
        raise RenameError(
            f"broken outgoing Markdown link in {relative}:{token.line}: "
            f"{token.raw_destination}"
        )
    if mismatch or actual != destination.target:
        raise RenameError(
            f"broken outgoing Markdown link has a case or Unicode mismatch in "
            f"{relative}:{token.line}: {token.raw_destination}"
        )
    if path_uses_symlink_component(actual, root):
        raise RenameError(
            f"outgoing Markdown link uses a symbolic link in {relative}:{token.line}"
        )


def percent_encoded(value: str) -> str:
    return "".join(f"%{byte:02X}" for byte in value.encode("utf-8"))


def encode_destination_path(value: str, *, angle: bool) -> str:
    safe_ascii = frozenset(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/-._~!$&'*+,;=:@"
    )
    result: list[str] = []
    for character in value:
        if character in safe_ascii or (not character.isascii() and not character.isspace()):
            result.append(character)
            continue
        if angle and character == " ":
            result.append(character)
            continue
        result.append(percent_encoded(character))
    return "".join(result)


def rewritten_destination(
    referrer_after: Path,
    target_after: Path,
    original: Destination,
    token: LinkToken,
) -> str:
    relative = os.path.relpath(target_after, referrer_after.parent).replace(os.sep, "/")
    return encode_destination_path(relative, angle=token.angle_destination) + original.suffix


def apply_text_replacements(
    text: str,
    replacements: list[tuple[int, int, str]],
) -> str:
    result = text
    for start, end, replacement in sorted(replacements, reverse=True):
        result = result[:start] + replacement + result[end:]
    return result


def snapshot_file(path: Path, root: Path) -> FileSnapshot:
    file_stat = path.stat(follow_symlinks=False)
    if not stat.S_ISREG(file_stat.st_mode):
        raise RenameError(f"project path stopped being a regular file: {path}")
    relative = PurePosixPath(path.relative_to(root).as_posix())
    return FileSnapshot(
        relative=relative,
        absolute=path,
        data=path.read_bytes(),
        mode=stat.S_IMODE(file_stat.st_mode),
        device=file_stat.st_dev,
        inode=file_stat.st_ino,
        size=file_stat.st_size,
        mtime_ns=file_stat.st_mtime_ns,
    )


def markdown_inventory(root: Path) -> tuple[tuple[PurePosixPath, ...], dict[PurePosixPath, FileSnapshot]]:
    try:
        paths = project_markdown_paths(root, use_git=True)
    except ProjectFilesError as error:
        raise RenameError(f"project Markdown inventory failed: {error}") from error
    snapshots: dict[PurePosixPath, FileSnapshot] = {}
    for path in paths:
        snapshot = snapshot_file(path, root)
        snapshots[snapshot.relative] = snapshot
    return tuple(sorted(snapshots, key=str)), snapshots


def build_plan(
    root: Path,
    source: PurePosixPath,
    destination: PurePosixPath,
) -> RenamePlan:
    source_path = root.joinpath(*source.parts)
    destination_path = root.joinpath(*destination.parts)
    ensure_portable_destination(root, source, destination)
    destination_directories = snapshot_destination_directories(root, destination)
    inventory, snapshots = markdown_inventory(root)
    if source not in snapshots:
        snapshots[source] = snapshot_file(source_path, root)

    mutations: list[Mutation] = []
    updated_links = 0
    for relative in inventory:
        snapshot = snapshots[relative]
        try:
            text = snapshot.data.decode("utf-8", errors="strict")
        except UnicodeDecodeError as error:
            raise RenameError(f"project Markdown is not UTF-8: {relative}") from error
        if "\x00" in text:
            raise RenameError(f"project Markdown contains NUL: {relative}")

        hidden = markdown_hidden_mask(text)
        protected: tuple[tuple[int, int], ...] = ()
        if relative.parts[0] == PROTECTED_SOURCES_DIRECTORY:
            protected = ((0, len(text)),)
        elif (
            relative.parts[0] == REQUESTS_DIRECTORY
            and len(relative.parts) == 2
            and relative.suffix.casefold() == ".md"
        ):
            protected = request_text_spans(text, hidden, relative)

        for wikilink in visible_wikilinks(text, hidden):
            if not wikilink_targets_source(
                wikilink,
                relative,
                source,
                root,
            ):
                continue
            if position_in_spans(wikilink.start, protected):
                raise RenameError(
                    f"защищённая wiki-ссылка блокирует переименование: "
                    f"{relative}:{wikilink.line}"
                )
            raise RenameError(
                f"unsupported wikilink candidate targets the source in "
                f"{relative}:{wikilink.line}"
            )

        replacements: list[tuple[int, int, str]] = []
        is_moved_markdown = relative == source
        referrer_before = snapshot.absolute
        referrer_after = destination_path if is_moved_markdown else referrer_before
        for token in markdown_link_tokens(text, hidden):
            resolved = resolve_destination(token, referrer_before, root, relative)
            if not resolved.is_local:
                continue
            assert resolved.target is not None
            protected_link = position_in_spans(token.destination_start, protected)

            if is_moved_markdown:
                ensure_outgoing_target(resolved, token, relative, root)
                target_after = (
                    destination_path if resolved.target == source_path else resolved.target
                )
                if not resolved.decoded_path:
                    replacement = token.raw_destination
                else:
                    replacement = rewritten_destination(
                        referrer_after,
                        target_after,
                        resolved,
                        token,
                    )
                if protected_link and replacement != token.raw_destination:
                    raise RenameError(
                        f"защищённая ссылка не может быть переписана: "
                        f"{relative}:{token.line}"
                    )
                if replacement != token.raw_destination:
                    updated_links += 1
                    replacements.append(
                        (
                            token.destination_start,
                            token.destination_end,
                            replacement,
                        )
                    )
                continue

            if resolved.target != source_path:
                if path_uses_symlink_component(resolved.target, root):
                    try:
                        resolved_through_symlink = resolved.target.resolve(strict=True)
                        source_resolved = source_path.resolve(strict=True)
                    except OSError:
                        resolved_through_symlink = None
                        source_resolved = None
                    if (
                        resolved_through_symlink is not None
                        and resolved_through_symlink == source_resolved
                    ):
                        raise RenameError(
                            f"incoming Markdown link resolves through a symbolic link "
                            f"to the source in {relative}:{token.line}: "
                            f"{token.raw_destination}"
                        )
                actual, mismatch = exact_existing_path(resolved.target, root)
                if mismatch and actual == source_path:
                    raise RenameError(
                        f"incoming Markdown link has a case or Unicode mismatch in "
                        f"{relative}:{token.line}: {token.raw_destination}"
                    )
                continue
            if protected_link:
                raise RenameError(
                    f"защищённая первичная ссылка блокирует переименование: "
                    f"{relative}:{token.line}"
                )
            replacement = rewritten_destination(
                referrer_after,
                destination_path,
                resolved,
                token,
            )
            updated_links += 1
            if replacement != token.raw_destination:
                replacements.append(
                    (token.destination_start, token.destination_end, replacement)
                )

        updated_text = apply_text_replacements(text, replacements)
        updated_data = updated_text.encode("utf-8")
        if updated_data != snapshot.data:
            output = destination if is_moved_markdown else relative
            mutations.append(
                Mutation(relative, output, updated_data, snapshot.mode)
            )

    ordered_snapshots = tuple(
        snapshots[path]
        for path in sorted(snapshots, key=str)
    )
    git_status = run_git(
        root,
        "-c",
        "core.quotepath=false",
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
    ).stdout
    head_result = run_git(root, "rev-parse", "--verify", "HEAD", check=False)
    head = os.fsdecode(head_result.stdout).strip() if head_result.returncode == 0 else ""
    git_index = git_index_state(root)
    return RenamePlan(
        root=root,
        source=source,
        destination=destination,
        updated_links=updated_links,
        mutations=tuple(sorted(mutations, key=lambda item: str(item.output))),
        snapshots=ordered_snapshots,
        destination_directories=destination_directories,
        markdown_inventory=inventory,
        git_status=git_status,
        git_index=git_index,
        head=head,
    )


def snapshot_matches(snapshot: FileSnapshot) -> bool:
    try:
        current_stat = snapshot.absolute.stat(follow_symlinks=False)
        current_data = snapshot.absolute.read_bytes()
    except OSError:
        return False
    return (
        stat.S_ISREG(current_stat.st_mode)
        and current_data == snapshot.data
        and stat.S_IMODE(current_stat.st_mode) == snapshot.mode
        and current_stat.st_dev == snapshot.device
        and current_stat.st_ino == snapshot.inode
        and current_stat.st_size == snapshot.size
        and current_stat.st_mtime_ns == snapshot.mtime_ns
    )


def snapshot_content_and_mode_matches(snapshot: FileSnapshot) -> bool:
    try:
        current_stat = snapshot.absolute.stat(follow_symlinks=False)
        current_data = snapshot.absolute.read_bytes()
    except OSError:
        return False
    return (
        stat.S_ISREG(current_stat.st_mode)
        and current_data == snapshot.data
        and stat.S_IMODE(current_stat.st_mode) == snapshot.mode
    )


def verify_snapshot_fence(plan: RenamePlan, *, include_status: bool) -> None:
    source_path = plan.root.joinpath(*plan.source.parts)
    destination_path = plan.root.joinpath(*plan.destination.parts)
    verify_destination_fence(plan)
    if not source_path.is_file() or destination_path.exists() or destination_path.is_symlink():
        raise RenameError("snapshot fence changed source or destination state")
    for snapshot in plan.snapshots:
        if not snapshot_matches(snapshot):
            raise RenameError(f"snapshot fence changed project file: {snapshot.relative}")
    current_head = run_git(plan.root, "rev-parse", "--verify", "HEAD", check=False)
    head = os.fsdecode(current_head.stdout).strip() if current_head.returncode == 0 else ""
    if head != plan.head:
        raise RenameError("snapshot fence changed Git HEAD")
    if git_index_state(plan.root) != plan.git_index:
        raise RenameError("snapshot fence changed the exact Git index")
    inventory, _snapshots = markdown_inventory(plan.root)
    if inventory != plan.markdown_inventory:
        raise RenameError("snapshot fence changed project Markdown inventory")
    if include_status:
        status = run_git(
            plan.root,
            "-c",
            "core.quotepath=false",
            "status",
            "--porcelain=v1",
            "-z",
            "--untracked-files=all",
        ).stdout
        if status != plan.git_status:
            raise RenameError("snapshot fence changed Git worktree or index")


def verify_rollback_state(plan: RenamePlan) -> None:
    source_path = plan.root.joinpath(*plan.source.parts)
    destination_path = plan.root.joinpath(*plan.destination.parts)
    verify_destination_fence(plan)
    if not source_path.is_file() or destination_path.exists() or destination_path.is_symlink():
        raise RenameError("rollback did not restore source and destination paths")
    for snapshot in plan.snapshots:
        if not snapshot_content_and_mode_matches(snapshot):
            raise RenameError(
                f"rollback did not restore project file bytes and mode: "
                f"{snapshot.relative}"
            )
    current_head = run_git(plan.root, "rev-parse", "--verify", "HEAD", check=False)
    head = os.fsdecode(current_head.stdout).strip() if current_head.returncode == 0 else ""
    if head != plan.head:
        raise RenameError("rollback did not restore Git HEAD")
    if git_index_state(plan.root) != plan.git_index:
        raise RenameError("rollback did not restore the exact Git index")
    inventory, _snapshots = markdown_inventory(plan.root)
    if inventory != plan.markdown_inventory:
        raise RenameError("rollback did not restore project Markdown inventory")
    status = run_git(
        plan.root,
        "-c",
        "core.quotepath=false",
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
    ).stdout
    if status != plan.git_status:
        raise RenameError("rollback did not restore Git worktree and index status")


def write_temporary_copy(directory: Path, data: bytes, mode: int, prefix: str) -> Path:
    descriptor, raw_path = tempfile.mkstemp(prefix=prefix, dir=directory)
    path = Path(raw_path)
    try:
        os.fchmod(descriptor, mode)
        remaining = memoryview(data)
        while remaining:
            written = os.write(descriptor, remaining)
            if written <= 0:
                raise OSError("temporary write made no progress")
            remaining = remaining[written:]
        os.fsync(descriptor)
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    finally:
        os.close(descriptor)
    return path


def cleanup_prepared(
    prepared: list[PreparedWrite],
    *,
    preserve: frozenset[Path] = frozenset(),
) -> tuple[str, ...]:
    errors: list[str] = []
    for item in prepared:
        for temporary in (item.replacement, item.backup):
            if temporary in preserve:
                continue
            try:
                temporary.unlink(missing_ok=True)
            except OSError as error:
                errors.append(f"remove temporary file {temporary}: {error}")
    return tuple(errors)


def prepare_writes(plan: RenamePlan) -> list[PreparedWrite]:
    verify_destination_fence(plan)
    snapshots = {snapshot.relative: snapshot for snapshot in plan.snapshots}
    prepared: list[PreparedWrite] = []
    try:
        for mutation in plan.mutations:
            snapshot = snapshots[mutation.original]
            output = plan.root.joinpath(*mutation.output.parts)
            replacement = write_temporary_copy(
                output.parent,
                mutation.data,
                mutation.mode,
                ".fum-rename-new-",
            )
            try:
                backup = write_temporary_copy(
                    output.parent,
                    snapshot.data,
                    snapshot.mode,
                    ".fum-rename-backup-",
                )
            except BaseException as error:
                try:
                    replacement.unlink(missing_ok=True)
                except OSError as cleanup_error:
                    raise RenameError(
                        f"prepare failed ({error}); cleanup incomplete: "
                        f"remove temporary file {replacement}: {cleanup_error}"
                    ) from error
                raise
            prepared.append(PreparedWrite(output, replacement, backup))
    except BaseException as error:
        cleanup_errors = cleanup_prepared(prepared)
        if cleanup_errors:
            raise RenameError(
                f"prepare failed ({error}); cleanup incomplete: "
                + "; ".join(cleanup_errors)
            ) from error
        raise
    return prepared


def apply_plan(plan: RenamePlan) -> None:
    verify_snapshot_fence(plan, include_status=True)
    prepared = prepare_writes(plan)
    try:
        verify_snapshot_fence(plan, include_status=False)
    except BaseException as error:
        cleanup_errors = cleanup_prepared(prepared)
        if cleanup_errors:
            raise RenameError(
                f"snapshot recheck failed ({error}); cleanup incomplete: "
                + "; ".join(cleanup_errors)
            ) from error
        raise

    source = str(plan.source)
    destination = str(plan.destination)
    moved = False
    installed: list[PreparedWrite] = []
    try:
        verify_destination_fence(plan)
        result = run_git(
            plan.root,
            "mv",
            "--",
            source,
            destination,
            check=False,
        )
        if result.returncode != 0:
            detail = os.fsdecode(result.stderr).strip() or "unknown Git error"
            raise RenameError(f"git mv failed: {detail}")
        moved = True
        for item in prepared:
            installed.append(item)
            os.replace(item.replacement, item.output)
    except BaseException as error:
        rollback_errors: list[str] = []
        preserved_backups: set[Path] = set()
        for item in reversed(installed):
            try:
                os.replace(item.backup, item.output)
            except BaseException as rollback_error:
                preserved_backups.add(item.backup)
                rollback_errors.append(
                    f"restore {item.output}: {rollback_error}; "
                    f"backup preserved at {item.backup}"
                )
        if moved:
            reverse = run_git(
                plan.root,
                "mv",
                "--",
                destination,
                source,
                check=False,
            )
            if reverse.returncode != 0:
                rollback_errors.append(
                    "restore git mv: "
                    + (os.fsdecode(reverse.stderr).strip() or "unknown Git error")
                )
        cleanup_errors = cleanup_prepared(
            prepared,
            preserve=frozenset(preserved_backups),
        )
        rollback_errors.extend(cleanup_errors)
        if not rollback_errors:
            try:
                verify_rollback_state(plan)
            except BaseException as rollback_error:
                rollback_errors.append(f"verify rollback state: {rollback_error}")
        if rollback_errors:
            detail = "; ".join(rollback_errors)
            raise RenameError(
                f"apply failed ({error}); rollback incomplete: {detail}"
            ) from error
        raise RenameError(f"apply failed and was rolled back: {error}") from error
    cleanup_errors = cleanup_prepared(prepared)
    if cleanup_errors:
        raise RenameError(
            "apply completed but temporary-file cleanup was incomplete: "
            + "; ".join(cleanup_errors)
        )


def public_payload(plan: RenamePlan, mode: str) -> dict[str, object]:
    rewritten_files = sorted(str(mutation.output) for mutation in plan.mutations)
    updated_files = sorted({str(plan.destination), *rewritten_files})
    return {
        "destination": str(plan.destination),
        "mode": mode,
        "renamed_file": {
            "destination": str(plan.destination),
            "source": str(plan.source),
        },
        "rewritten_files": rewritten_files,
        "source": str(plan.source),
        "updated_files": updated_files,
        "updated_links": plan.updated_links,
    }


def execute(args: argparse.Namespace) -> dict[str, object]:
    with without_inherited_git_environment():
        root = repository_root(args.repo_root)
        source, destination = validate_paths(root, args.source, args.destination)
        plan = build_plan(root, source, destination)
        if args.mode == "apply":
            apply_plan(plan)
        return public_payload(plan, args.mode)


def main(argv: list[str] | None = None) -> int:
    try:
        args = parse_args(argv)
        payload = execute(args)
    except (OSError, ProjectFilesError, RenameError, UnicodeError, subprocess.SubprocessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(
        json.dumps(
            payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
