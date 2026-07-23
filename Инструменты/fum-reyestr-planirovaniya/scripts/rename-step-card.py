#!/usr/bin/env python3
"""Rename a FUM step card and update its live textual references."""

from __future__ import annotations

import argparse
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import tomllib
from dataclasses import dataclass
from pathlib import Path, PurePosixPath


CARDS_DIRECTORY = PurePosixPath("Планирование/карточки-шагов")
CARDS_INDEX = CARDS_DIRECTORY / "README.md"
BRANCH_STEPS_DIRECTORY = PurePosixPath(
    "Планирование/следующие-шаги-веток"
)

STATUS_EMOJI = {
    "active": "🟡",
    "completed": "✅",
    "absorbed": "🧩",
    "withdrawn": "🗑️",
}
STATUS_LABEL = {
    "active": "Актуально",
    "completed": "Выполнено",
    "absorbed": "Поглощено",
    "withdrawn": "Снято",
}
INDEX_STATUS = {
    status: f"{STATUS_EMOJI[status]} {label}"
    for status, label in STATUS_LABEL.items()
}
STATUS_BY_EMOJI = {emoji: status for status, emoji in STATUS_EMOJI.items()}

CARD_ID_RE = re.compile(r"^FUM-STEP-[0-9]{4}$")
CARD_NAME_RE = re.compile(
    rf"^({'|'.join(re.escape(value) for value in STATUS_BY_EMOJI)})-"
    r"(FUM-STEP-[0-9]{4})-(.+)\.md$"
)
DESCRIPTION_RE = re.compile(r"^[^-]+(?:-[^-]+)*$")
INDEX_HEADERS = ["Идентификатор", "Статус", "Карточка"]
SEPARATOR_RE = re.compile(r":?-{3,}:?")
FRONTMATTER_RE = re.compile(
    r"\A\+\+\+[ \t]*\r?\n(.*?)^\+\+\+[ \t]*(?:\r?\n|\Z)",
    re.MULTILINE | re.DOTALL,
)
STATUS_LINE_RE = re.compile(
    r'^(?P<prefix>[ \t]*status[ \t]*=[ \t]*)'
    r'(?P<quote>["\'])(?P<value>[^"\']*)(?P=quote)'
    r'(?P<suffix>[ \t]*(?:#.*)?)(?P<newline>\r?)$',
    re.MULTILINE,
)
CARD_ID_ASSIGNMENT_TEMPLATE = r"(?m)^[ \t]*card_id[ \t]*=[ \t]*(['\"])%s\1"
REQUEST_HEADING_RE = re.compile(
    r"^[ ]{0,3}##(?!#)[ \t]+(?P<title>.*?)[ \t]*$"
)
FENCE_OPEN_RE = re.compile(r"^[ ]{0,3}(?P<fence>`{3,}|\x7e{3,})")
CACHE_COMPONENTS = frozenset(
    {"__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".cache"}
)


class CliParser(argparse.ArgumentParser):
    """Use exit status 1 for invalid mutating-command arguments."""

    def error(self, message: str) -> None:
        self.print_usage(sys.stderr)
        self.exit(1, f"{self.prog}: error: {message}\n")


@dataclass(frozen=True)
class LiveFile:
    relative: PurePosixPath
    absolute: Path
    data: bytes
    text: str | None


@dataclass(frozen=True)
class PreparedWrite:
    output: Path
    replacement: Path
    backup: Path


def parse_args() -> argparse.Namespace:
    parser = CliParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path("."))
    parser.add_argument("--card-id", required=True)
    parser.add_argument("--status", choices=tuple(STATUS_EMOJI), required=True)
    parser.add_argument("--description")
    return parser.parse_args()


def run_git(
    repo_root: Path,
    *arguments: str,
    text: bool = False,
) -> subprocess.CompletedProcess[bytes] | subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "--no-replace-objects", *arguments],
        cwd=repo_root,
        check=True,
        capture_output=True,
        text=text,
    )


def repository_root(value: Path) -> Path:
    root = value.expanduser().resolve()
    if not root.is_dir():
        raise ValueError(f"repo root is not a directory: {root}")
    try:
        result = run_git(root, "rev-parse", "--show-toplevel", text=True)
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or "").strip()
        raise ValueError(f"repo root is not a Git worktree: {root}: {detail}") from error
    discovered = Path(result.stdout.strip()).resolve()
    if discovered != root:
        raise ValueError(
            f"--repo-root must name the Git worktree root: {root} != {discovered}"
        )
    return root


def git_paths(repo_root: Path, *arguments: str) -> set[PurePosixPath]:
    try:
        result = run_git(repo_root, "ls-files", *arguments, "-z", "--")
    except subprocess.CalledProcessError as error:
        detail = os.fsdecode(error.stderr or b"").strip()
        raise ValueError(f"git ls-files failed: {detail}") from error

    paths: set[PurePosixPath] = set()
    for raw_path in result.stdout.split(b"\0"):
        if not raw_path:
            continue
        path_text = os.fsdecode(raw_path)
        path = PurePosixPath(path_text)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"Git returned an unsafe repository path: {path_text!r}")
        paths.add(path)
    return paths


def is_cache_path(path: PurePosixPath) -> bool:
    return bool(CACHE_COMPONENTS.intersection(path.parts)) or path.suffix == ".pyc"


def load_live_files(
    repo_root: Path,
    paths: set[PurePosixPath],
) -> dict[PurePosixPath, LiveFile]:
    files: dict[PurePosixPath, LiveFile] = {}
    for relative in sorted(paths, key=str):
        absolute = repo_root.joinpath(*relative.parts)
        if is_cache_path(relative) or absolute.is_symlink() or not absolute.is_file():
            continue
        data = absolute.read_bytes()
        text: str | None
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            text = None
        if text is not None and "\0" in text:
            text = None
        files[relative] = LiveFile(relative, absolute, data, text)
    return files


def parse_frontmatter(text: str, source: PurePosixPath) -> tuple[dict[str, object], re.Match[str]]:
    match = FRONTMATTER_RE.search(text)
    if match is None:
        raise ValueError(f"step card has no closed TOML frontmatter: {source}")
    try:
        parsed = tomllib.loads(match.group(1))
    except tomllib.TOMLDecodeError as error:
        raise ValueError(f"invalid step card TOML in {source}: {error}") from error
    if not isinstance(parsed, dict):
        raise ValueError(f"step card TOML must be a table: {source}")
    return parsed, match


def filename_metadata(path: PurePosixPath) -> tuple[str, str, str]:
    if len(path.name.encode("utf-8")) > 255:
        raise ValueError(f"step card filename exceeds 255 UTF-8 bytes: {path.name}")
    match = CARD_NAME_RE.fullmatch(path.name)
    if match is None:
        raise ValueError(
            "invalid canonical step card filename; expected "
            f"<emoji>-FUM-STEP-NNNN-<description>.md: {path.name}"
        )
    emoji, card_id, description = match.groups()
    validate_description(description)
    return card_id, STATUS_BY_EMOJI[emoji], description


def validate_description(description: str) -> None:
    if (
        not description
        or DESCRIPTION_RE.fullmatch(description) is None
        or any(
            not all(character.isalnum() for character in part)
            for part in description.split("-")
        )
    ):
        raise ValueError(
            "invalid description; expected Unicode letters or digits separated "
            "by single hyphens"
        )


def locate_card(
    repo_root: Path,
    candidates: set[PurePosixPath],
    tracked: set[PurePosixPath],
    card_id: str,
) -> tuple[PurePosixPath, str, str, str]:
    possible: set[PurePosixPath] = set()
    for path in candidates:
        if path.parent != CARDS_DIRECTORY or path.suffix.casefold() != ".md":
            continue
        if path.name == CARDS_INDEX.name:
            continue

        name_match = CARD_NAME_RE.fullmatch(path.name)
        if name_match is not None and name_match.group(2) == card_id:
            possible.add(path)

        absolute = repo_root.joinpath(*path.parts)
        if absolute.is_symlink() or not absolute.is_file():
            continue
        try:
            text = absolute.read_bytes().decode("utf-8")
        except UnicodeDecodeError:
            continue
        frontmatter_match = FRONTMATTER_RE.search(text)
        if frontmatter_match is None:
            continue
        try:
            frontmatter = tomllib.loads(frontmatter_match.group(1))
        except tomllib.TOMLDecodeError:
            continue
        if frontmatter.get("card_id") == card_id:
            possible.add(path)

    if not possible:
        raise ValueError(f"tracked step card not found for card_id {card_id}")
    if len(possible) != 1:
        rendered = ", ".join(str(path) for path in sorted(possible, key=str))
        raise ValueError(f"multiple live step cards found for {card_id}: {rendered}")

    source = next(iter(possible))
    if source not in tracked:
        raise ValueError(f"tracked step card not found for card_id {card_id}")
    if source.parent != CARDS_DIRECTORY:
        raise ValueError(f"step card is outside the canonical directory: {source}")
    absolute = repo_root.joinpath(*source.parts)
    if absolute.is_symlink() or not absolute.is_file():
        raise ValueError(f"tracked step card is not a live regular file: {source}")
    try:
        text = absolute.read_bytes().decode("utf-8")
    except UnicodeDecodeError as error:
        raise ValueError(f"step card is not UTF-8: {source}") from error
    if "\0" in text:
        raise ValueError(f"step card is binary: {source}")

    filename_id, filename_status, description = filename_metadata(source)
    frontmatter, _match = parse_frontmatter(text, source)
    if filename_id != card_id or frontmatter.get("card_id") != card_id:
        raise ValueError(
            f"step card filename and TOML card_id do not agree in {source}"
        )
    old_status = frontmatter.get("status")
    if old_status not in STATUS_EMOJI:
        raise ValueError(f"invalid step card TOML status in {source}: {old_status!r}")
    if filename_status != old_status:
        raise ValueError(
            f"step card filename status does not match TOML status in {source}"
        )
    if frontmatter.get("schema_version") != 1:
        raise ValueError(f"step card supports only schema_version = 1: {source}")
    return source, text, old_status, description


def request_source_spans(text: str) -> list[tuple[int, int]]:
    """Return raw request-section spans while ignoring headings in fences."""

    spans: list[tuple[int, int]] = []
    section_start: int | None = None
    fence_character: str | None = None
    fence_length = 0
    offset = 0

    for line_with_ending in text.splitlines(keepends=True):
        line = line_with_ending.rstrip("\r\n")
        if fence_character is not None:
            closing = re.match(
                rf"^[ ]{{0,3}}{re.escape(fence_character)}{{{fence_length},}}[ \t]*$",
                line,
            )
            if closing is not None:
                fence_character = None
                fence_length = 0
            offset += len(line_with_ending)
            continue

        opening = FENCE_OPEN_RE.match(line)
        if opening is not None:
            fence = opening.group("fence")
            fence_character = fence[0]
            fence_length = len(fence)
            offset += len(line_with_ending)
            continue

        heading = REQUEST_HEADING_RE.match(line)
        if heading is not None:
            title = re.sub(r"[ \t]+#+[ \t]*$", "", heading.group("title")).strip()
            if section_start is not None:
                spans.append((section_start, offset))
                section_start = None
            if title == "Текст запроса":
                section_start = offset

        offset += len(line_with_ending)

    if section_start is not None:
        spans.append((section_start, len(text)))
    return spans


def replace_outside_spans(
    text: str,
    old: str,
    new: str,
    spans: list[tuple[int, int]],
) -> tuple[str, int, int]:
    parts: list[str] = []
    cursor = 0
    updated = 0
    preserved = 0
    for start, end in spans:
        live = text[cursor:start]
        updated += live.count(old)
        parts.append(live.replace(old, new))
        raw = text[start:end]
        preserved += raw.count(old)
        parts.append(raw)
        cursor = end
    live = text[cursor:]
    updated += live.count(old)
    parts.append(live.replace(old, new))
    return "".join(parts), updated, preserved


def split_table_row(line: str) -> list[str]:
    value = line.strip()
    if not value.startswith("|") or not value.endswith("|"):
        return []
    return [cell.strip() for cell in value[1:-1].split("|")]


def line_ending(line: str) -> str:
    if line.endswith("\r\n"):
        return "\r\n"
    if line.endswith("\n") or line.endswith("\r"):
        return line[-1]
    return ""


def update_index(
    text: str,
    card_id: str,
    old_status: str,
    new_status: str,
    old_name: str,
    new_name: str,
) -> str:
    lines = text.splitlines(keepends=True)
    header_indexes = [
        index
        for index, line in enumerate(lines)
        if split_table_row(line.rstrip("\r\n")) == INDEX_HEADERS
    ]
    if len(header_indexes) != 1:
        raise ValueError(
            "step card index must contain exactly one canonical index table"
        )
    header_index = header_indexes[0]
    separator_index = header_index + 1
    if separator_index >= len(lines):
        raise ValueError("step card index table has no separator")
    separator_cells = split_table_row(lines[separator_index].rstrip("\r\n"))
    if (
        len(separator_cells) != len(INDEX_HEADERS)
        or not all(SEPARATOR_RE.fullmatch(cell) for cell in separator_cells)
    ):
        raise ValueError("step card index table has an invalid separator")

    row_indexes: list[int] = []
    rows: list[list[str]] = []
    index = separator_index + 1
    while index < len(lines):
        cells = split_table_row(lines[index].rstrip("\r\n"))
        if not cells:
            break
        if len(cells) != len(INDEX_HEADERS):
            raise ValueError(f"malformed step card index row at line {index + 1}")
        row_indexes.append(index)
        rows.append(cells)
        index += 1
    if not rows:
        raise ValueError("step card index table is empty")

    matching_rows = [position for position, row in enumerate(rows) if row[0] == card_id]
    if len(matching_rows) != 1:
        raise ValueError(
            f"step card index must contain exactly one row for {card_id}"
        )
    target_position = matching_rows[0]
    target = rows[target_position]
    if target[1] != INDEX_STATUS[old_status]:
        raise ValueError(
            f"step card index status does not match the card for {card_id}"
        )
    if target[2].count(old_name) != 1:
        raise ValueError(
            f"step card index must link the exact old basename once for {card_id}"
        )
    target[1] = INDEX_STATUS[new_status]
    target[2] = target[2].replace(old_name, new_name)

    table_rows = [INDEX_HEADERS, *rows]
    widths = [
        max(3, max(len(row[column]) for row in table_rows))
        for column in range(len(INDEX_HEADERS))
    ]

    formatted: list[list[str]] = []
    formatted.append(INDEX_HEADERS)
    formatted.append(["-" * width for width in widths])
    formatted.extend(rows)
    target_line_indexes = [header_index, separator_index, *row_indexes]
    for line_index, cells in zip(target_line_indexes, formatted, strict=True):
        ending = line_ending(lines[line_index])
        lines[line_index] = (
            "| "
            + " | ".join(
                cell.ljust(width)
                for cell, width in zip(cells, widths, strict=True)
            )
            + " |"
            + ending
        )
    return "".join(lines)


def update_card_status(
    text: str,
    source: PurePosixPath,
    old_status: str,
    new_status: str,
) -> str:
    _frontmatter, frontmatter_match = parse_frontmatter(text, source)
    start, end = frontmatter_match.span(1)
    raw = text[start:end]
    matches = list(STATUS_LINE_RE.finditer(raw))
    if len(matches) != 1 or matches[0].group("value") != old_status:
        raise ValueError(f"step card must contain one exact TOML status line: {source}")

    match = matches[0]
    replacement = (
        f"{match.group('prefix')}{match.group('quote')}{new_status}"
        f"{match.group('quote')}{match.group('suffix')}{match.group('newline')}"
    )
    updated_raw = raw[: match.start()] + replacement + raw[match.end() :]
    return text[:start] + updated_raw + text[end:]


def guard_branch_step_records(
    live_paths: set[PurePosixPath],
    live_files: dict[PurePosixPath, LiveFile],
    card_id: str,
    old_name: str,
) -> None:
    conflicts: list[str] = []
    card_assignment = re.compile(CARD_ID_ASSIGNMENT_TEMPLATE % re.escape(card_id))
    record_paths = sorted(
        (
            path
            for path in live_paths
            if path.parent == BRANCH_STEPS_DIRECTORY
            and path.suffix.casefold() == ".md"
        ),
        key=str,
    )
    for path in record_paths:
        live_file = live_files.get(path)
        if live_file is None or live_file.text is None:
            raise ValueError(
                f"canonical branch-step record is not live UTF-8 text: {path}"
            )
        has_old_path = old_name in live_file.text
        has_candidate = path.name != "README.md" and card_assignment.search(live_file.text)
        if has_old_path or has_candidate:
            conflicts.append(str(path))
    if conflicts:
        rendered = ", ".join(sorted(conflicts))
        raise ValueError(
            "step card is still referenced by a canonical branch next-step "
            f"record ({rendered}); before renaming, manually remove the completed "
            "candidate or reissue the candidate with the new card_path and a fresh "
            "step_id"
        )


def build_mutation_plan(
    repo_root: Path,
    live_files: dict[PurePosixPath, LiveFile],
    source: PurePosixPath,
    destination: PurePosixPath,
    card_id: str,
    old_status: str,
    new_status: str,
) -> tuple[dict[PurePosixPath, bytes], int, int]:
    old_name = source.name
    new_name = destination.name
    plan: dict[PurePosixPath, bytes] = {}
    updated_occurrences = 0
    preserved_occurrences = 0

    for path, live_file in live_files.items():
        if live_file.text is None:
            continue
        # The canonical index needs its old row intact for structural
        # validation below. Its literal replacements are counted and applied
        # after the status cell has been checked.
        if path == CARDS_INDEX:
            continue
        if path.parts and path.parts[0] == "Источники":
            preserved_occurrences += live_file.text.count(old_name)
            continue

        spans: list[tuple[int, int]] = []
        if (
            path.parts
            and path.parts[0] == "Запросы"
            and path.suffix.casefold() == ".md"
        ):
            spans = request_source_spans(live_file.text)
        updated, replaced, preserved = replace_outside_spans(
            live_file.text,
            old_name,
            new_name,
            spans,
        )
        updated_occurrences += replaced
        preserved_occurrences += preserved
        if updated != live_file.text:
            plan[path] = updated.encode("utf-8")

    if source not in live_files or live_files[source].text is None:
        raise ValueError(f"step card is missing from the live UTF-8 file set: {source}")
    card_base = plan.get(source, live_files[source].data).decode("utf-8")
    updated_card = update_card_status(card_base, source, old_status, new_status)
    plan[source] = updated_card.encode("utf-8")

    index_file = live_files.get(CARDS_INDEX)
    if index_file is None or index_file.text is None:
        raise ValueError(f"step card index is not a live UTF-8 file: {CARDS_INDEX}")
    updated_occurrences += index_file.text.count(old_name)
    updated_index = update_index(
        index_file.text,
        card_id,
        old_status,
        new_status,
        old_name,
        new_name,
    )
    updated_index = updated_index.replace(old_name, new_name)
    plan[CARDS_INDEX] = updated_index.encode("utf-8")

    for path in plan:
        live_file = live_files[path]
        if not os.access(live_file.absolute, os.W_OK):
            raise ValueError(f"file is not writable: {path}")
    destination_parent = repo_root.joinpath(*destination.parent.parts)
    if not os.access(destination_parent, os.W_OK):
        raise ValueError(f"destination directory is not writable: {destination.parent}")
    return plan, updated_occurrences, preserved_occurrences


def write_temporary_copy(
    directory: Path,
    data: bytes,
    mode: int,
    prefix: str,
) -> Path:
    descriptor, raw_path = tempfile.mkstemp(prefix=prefix, dir=directory)
    path = Path(raw_path)
    try:
        os.fchmod(descriptor, stat.S_IMODE(mode))
        remaining = memoryview(data)
        while remaining:
            written = os.write(descriptor, remaining)
            if written <= 0:
                raise OSError("temporary file write made no progress")
            remaining = remaining[written:]
        os.fsync(descriptor)
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    finally:
        os.close(descriptor)
    return path


def cleanup_prepared_writes(
    prepared: list[PreparedWrite],
    *,
    preserve: frozenset[Path] = frozenset(),
) -> None:
    for item in prepared:
        for temporary in (item.replacement, item.backup):
            if temporary in preserve:
                continue
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                # The repository content is already restored or installed. A
                # failed cleanup must not turn that known state into another
                # partial rollback attempt.
                pass


def prepare_writes(
    repo_root: Path,
    plan: dict[PurePosixPath, bytes],
    live_files: dict[PurePosixPath, LiveFile],
    source: PurePosixPath,
    destination: PurePosixPath,
) -> list[PreparedWrite]:
    prepared: list[PreparedWrite] = []
    try:
        for original_path in sorted(plan, key=str):
            live_file = live_files[original_path]
            file_stat = live_file.absolute.stat(follow_symlinks=False)
            if not stat.S_ISREG(file_stat.st_mode):
                raise ValueError(f"file stopped being regular: {original_path}")
            output_path = destination if original_path == source else original_path
            output = repo_root.joinpath(*output_path.parts)
            replacement = write_temporary_copy(
                output.parent,
                plan[original_path],
                file_stat.st_mode,
                ".fum-step-card-new-",
            )
            try:
                backup = write_temporary_copy(
                    output.parent,
                    live_file.data,
                    file_stat.st_mode,
                    ".fum-step-card-backup-",
                )
            except BaseException:
                replacement.unlink(missing_ok=True)
                raise
            prepared.append(PreparedWrite(output, replacement, backup))
    except BaseException:
        cleanup_prepared_writes(prepared)
        raise
    return prepared


def apply_prepared_writes(
    repo_root: Path,
    prepared: list[PreparedWrite],
    source: PurePosixPath,
    destination: PurePosixPath,
) -> None:
    try:
        run_git(repo_root, "mv", "--", str(source), str(destination))
    except subprocess.CalledProcessError as error:
        cleanup_prepared_writes(prepared)
        detail = os.fsdecode(error.stderr or b"").strip()
        raise ValueError(f"git mv failed: {detail}") from error

    installed: list[PreparedWrite] = []
    try:
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
        try:
            run_git(repo_root, "mv", "--", str(destination), str(source))
        except BaseException as rollback_error:
            rollback_errors.append(f"restore git mv: {rollback_error}")
        cleanup_prepared_writes(
            prepared,
            preserve=frozenset(preserved_backups),
        )
        if rollback_errors:
            detail = "; ".join(rollback_errors)
            raise ValueError(
                f"failed to install prepared files ({error}); rollback incomplete: {detail}"
            ) from error
        if isinstance(error, OSError):
            raise ValueError(
                f"failed to install prepared files; operation rolled back: {error}"
            ) from error
        raise

    cleanup_prepared_writes(prepared)


def execute(args: argparse.Namespace) -> dict[str, object]:
    root = repository_root(args.repo_root)
    if CARD_ID_RE.fullmatch(args.card_id) is None:
        raise ValueError("invalid --card-id; expected FUM-STEP-NNNN")
    if args.description is not None:
        validate_description(args.description)

    tracked = git_paths(root, "--cached")
    live_paths = git_paths(root, "--cached", "--others", "--exclude-standard")
    source, _source_text, old_status, old_description = locate_card(
        root,
        live_paths,
        tracked,
        args.card_id,
    )
    description = args.description if args.description is not None else old_description
    new_name = (
        f"{STATUS_EMOJI[args.status]}-{args.card_id}-{description}.md"
    )
    if len(new_name.encode("utf-8")) > 255:
        raise ValueError("new step card filename exceeds 255 UTF-8 bytes")
    destination = CARDS_DIRECTORY / new_name
    if destination == source:
        raise ValueError("requested status and description leave the card path unchanged")
    if destination in live_paths or root.joinpath(*destination.parts).exists():
        raise ValueError(f"target step card path already exists: {destination}")
    if CARDS_INDEX not in tracked:
        raise ValueError(f"step card index is not tracked: {CARDS_INDEX}")

    live_files = load_live_files(root, live_paths)
    guard_branch_step_records(live_paths, live_files, args.card_id, source.name)
    plan, updated_occurrences, preserved_occurrences = build_mutation_plan(
        root,
        live_files,
        source,
        destination,
        args.card_id,
        old_status,
        args.status,
    )

    prepared = prepare_writes(root, plan, live_files, source, destination)
    apply_prepared_writes(root, prepared, source, destination)

    updated_files: set[str] = {str(destination)}
    for original_path in plan:
        output_path = destination if original_path == source else original_path
        updated_files.add(str(output_path))

    return {
        "old_path": str(source),
        "new_path": str(destination),
        "updated_files": sorted(updated_files),
        "updated_occurrences": updated_occurrences,
        "preserved_source_occurrences": preserved_occurrences,
    }


def main() -> int:
    try:
        payload = execute(parse_args())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
