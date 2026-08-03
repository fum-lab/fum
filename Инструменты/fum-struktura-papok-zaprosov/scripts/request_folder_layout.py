#!/usr/bin/env python3
"""Deterministic migration and validation of request-owned journal folders."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import importlib.util
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Iterator, Sequence


SCHEMA_VERSION = 1
REQUESTS = PurePosixPath("Запросы")
JOURNAL = PurePosixPath("Журнал")
REQUEST_FILE = "запрос.md"
REPORT_FILE = "отчёт.md"
SESSION_PATTERN = re.compile(
    r"^(?P<prefix>\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_MSK)(?:_(?P<label>.+))?$"
)
SESSION_STEM_RE = SESSION_PATTERN
TIME_TOKEN_PATTERN = re.compile(r"\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_MSK")
ACTIVE_JSON_KEYS = frozenset({"request_file", "report_file", "config_file"})
HASH_PATTERN = re.compile(r"^(?:sha256:)?[0-9a-f]{40,64}$", re.IGNORECASE)
GIT_STATE_PATTERN = re.compile(r"^git:commit:[0-9a-f]{40,64}$", re.IGNORECASE)
FULL_GIT_OID_PATTERN = re.compile(r"^[0-9a-f]{40,64}$")


class LayoutError(RuntimeError):
    """A fail-closed layout or ownership error."""


@dataclass(frozen=True)
class Move:
    source: PurePosixPath
    destination: PurePosixPath


@dataclass(frozen=True)
class ProvenLinkRepair:
    angle: bool
    expected: str
    accepted: frozenset[str]


@dataclass(frozen=True)
class PreparedFile:
    path: PurePosixPath
    data: bytes
    mode: int


@dataclass(frozen=True)
class PathSnapshot:
    kind: str
    data: bytes | str | None
    mode: int | None


@dataclass(frozen=True)
class IndexSection:
    heading_start: int
    body_start: int
    end: int
    title: str


def is_valid_session_stem(stem: str) -> bool:
    match = SESSION_PATTERN.fullmatch(stem)
    if match is None:
        return False
    try:
        dt.datetime.strptime(match.group("prefix"), "%Y-%m-%d_%H-%M-%S_MSK")
    except ValueError:
        return False
    return "/" not in stem and "\\" not in stem and stem not in {".", ".."}


def session_stem_for_request_path(path: str | PurePosixPath) -> str | None:
    value = PurePosixPath(path)
    if len(value.parts) == 3 and value.parts[0] == str(JOURNAL) and value.name == REQUEST_FILE:
        stem = value.parts[1]
        return stem if is_valid_session_stem(stem) else None
    return None


def canonical_request_path(stem: str) -> PurePosixPath:
    return JOURNAL / stem / REQUEST_FILE


def canonical_report_path(stem: str) -> PurePosixPath:
    return JOURNAL / stem / REPORT_FILE


def _relative(root: Path, path: Path) -> PurePosixPath:
    try:
        return PurePosixPath(path.relative_to(root).as_posix())
    except ValueError as error:
        raise LayoutError(f"path escapes repository root: {path}") from error


def _iter_files(root: Path) -> Iterator[Path]:
    for directory, names, filenames in os.walk(root, topdown=True, followlinks=False):
        base = Path(directory)
        names[:] = sorted(name for name in names if name != ".git")
        for name in names:
            candidate = base / name
            if candidate.is_symlink():
                yield candidate
        for name in sorted(filenames):
            yield base / name


def _project_relative_files(repo_root: Path) -> tuple[PurePosixPath, ...]:
    environment = os.environ.copy()
    for name in (
        "GIT_DIR",
        "GIT_WORK_TREE",
        "GIT_INDEX_FILE",
        "GIT_NAMESPACE",
        "GIT_OBJECT_DIRECTORY",
        "GIT_ALTERNATE_OBJECT_DIRECTORIES",
        "GIT_COMMON_DIR",
        "GIT_CEILING_DIRECTORIES",
    ):
        environment.pop(name, None)
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    result = subprocess.run(
        [
            "git",
            "-c",
            "core.quotepath=false",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "-z",
        ],
        cwd=repo_root,
        env=environment,
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        detail = os.fsdecode(result.stderr).strip() or "git ls-files failed"
        raise LayoutError(f"cannot inventory publishable project files: {detail}")
    paths: list[PurePosixPath] = []
    for raw in result.stdout.split(b"\0"):
        if not raw:
            continue
        relative = PurePosixPath(os.fsdecode(raw))
        if relative.is_absolute() or ".." in relative.parts:
            raise LayoutError(f"unsafe project inventory path: {relative}")
        absolute = repo_root.joinpath(*relative.parts)
        if absolute.is_file() or absolute.is_symlink():
            paths.append(relative)
    return tuple(sorted(set(paths), key=lambda path: path.as_posix()))


def _project_files(repo_root: Path) -> Iterator[Path]:
    for relative in _project_relative_files(repo_root):
        yield repo_root.joinpath(*relative.parts)


def _assert_no_symlinks(repo_root: Path, roots: Iterable[str]) -> None:
    publishable = _project_relative_files(repo_root)
    for root_name in roots:
        path = repo_root / root_name
        if path.is_symlink():
            raise LayoutError(f"symbolic link is forbidden in managed layout: {root_name}")
        if not path.exists():
            continue
        for relative in publishable:
            if not relative.parts or relative.parts[0] != root_name:
                continue
            candidate = repo_root
            for part in relative.parts:
                candidate /= part
                if candidate.is_symlink():
                    rel = _relative(repo_root, candidate)
                    raise LayoutError(f"symbolic link is forbidden in managed layout: {rel}")


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError) as error:
        raise LayoutError(f"cannot read UTF-8 file: {path}") from error


def _validate_stem(stem: str, context: str) -> None:
    if not is_valid_session_stem(stem):
        raise LayoutError(f"invalid session stem in {context}: {stem}")


def _legacy_requests(repo_root: Path) -> dict[str, PurePosixPath]:
    directory = repo_root / str(REQUESTS)
    if not directory.exists():
        return {}
    if not directory.is_dir():
        raise LayoutError("Запросы must be a directory")
    publishable = set(_project_relative_files(repo_root))
    result: dict[str, PurePosixPath] = {}
    for path in sorted(directory.iterdir(), key=lambda item: item.name):
        relative = _relative(repo_root, path)
        if relative not in publishable:
            continue
        if not path.is_file() or path.suffix != ".md":
            raise LayoutError(f"unexpected entry in legacy requests: {relative}")
        _validate_stem(path.stem, "legacy request")
        result[path.stem] = relative
    return result


def _canonical_requests(repo_root: Path) -> dict[str, PurePosixPath]:
    directory = repo_root / str(JOURNAL)
    if not directory.exists():
        return {}
    result: dict[str, PurePosixPath] = {}
    for relative in _project_relative_files(repo_root):
        if len(relative.parts) != 3 or relative.parts[0] != str(JOURNAL) or relative.name != REQUEST_FILE:
            continue
        stem = relative.parts[1]
        _validate_stem(stem, "journal request folder")
        result[stem] = relative
    return result


def _legacy_reports(repo_root: Path, request_stems: set[str]) -> dict[str, PurePosixPath]:
    directory = repo_root / str(JOURNAL)
    if not directory.exists() or not directory.is_dir():
        raise LayoutError("Журнал must be a directory")
    result: dict[str, PurePosixPath] = {}
    publishable = set(_project_relative_files(repo_root))
    for path in sorted(directory.glob("*.md"), key=lambda item: item.name):
        relative = _relative(repo_root, path)
        if path.name == "README.md" or relative not in publishable:
            continue
        _validate_stem(path.stem, "legacy report")
        if path.stem not in request_stems:
            raise LayoutError(f"orphan report has no request: {relative}")
        result[path.stem] = relative
    return result


_LINK_TOOLS: Any | None = None


def _link_tools() -> Any:
    global _LINK_TOOLS
    if _LINK_TOOLS is not None:
        return _LINK_TOOLS
    script = (
        Path(__file__).resolve().parents[2]
        / "fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok"
        / "scripts"
        / "pereimenovatj-fajl-s-obnovleniyem-ssyilok.py"
    )
    spec = importlib.util.spec_from_file_location("fum_request_layout_link_tools", script)
    if spec is None or spec.loader is None:
        raise LayoutError(f"cannot load Markdown link engine: {script}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    _LINK_TOOLS = module
    return module


def _matching_label_bracket_with_inline_code(
    text: str,
    opening: int,
    hidden: bytearray,
) -> int | None:
    """Match a visible link label while admitting only masked inline-code spans."""

    depth = 1
    cursor = opening + 1
    while cursor < len(text):
        if text[cursor] == "\n":
            return None
        if hidden[cursor]:
            masked_end = cursor + 1
            while masked_end < len(text) and hidden[masked_end]:
                masked_end += 1
            masked = text[cursor:masked_end]
            opening_ticks = len(masked) - len(masked.lstrip("`"))
            closing_ticks = len(masked) - len(masked.rstrip("`"))
            if opening_ticks == 0 or opening_ticks != closing_ticks:
                return None
            cursor = masked_end
            continue
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


def _markdown_link_tokens(text: str) -> tuple[bytearray, list[Any]]:
    """Return semantic link tokens, including labels that contain inline code."""

    tools = _link_tools()
    hidden = tools.markdown_hidden_mask(text)
    tokens = list(tools.markdown_link_tokens(text, hidden))
    occupied = {
        (token.destination_start, token.destination_end)
        for token in tokens
    }
    cursor = 0
    while cursor < len(text):
        if hidden[cursor]:
            cursor += 1
            continue
        image = (
            text[cursor] == "!"
            and cursor + 1 < len(text)
            and text[cursor + 1] == "["
            and not hidden[cursor + 1]
        )
        opening = cursor + 1 if image else cursor
        if text[opening] != "[" or tools.is_escaped(text, opening):
            cursor += 1
            continue
        if (
            not image
            and opening > 0
            and text[opening - 1] == "!"
            and not hidden[opening - 1]
        ):
            cursor += 1
            continue
        closing = _matching_label_bracket_with_inline_code(
            text,
            opening,
            hidden,
        )
        if closing is None or closing + 1 >= len(text) or text[closing + 1] != "(":
            cursor += 1
            continue
        parsed = tools.parse_inline_destination(text, closing + 1, hidden)
        if parsed is None:
            cursor += 1
            continue
        destination_start, destination_end, angle, token_end = parsed
        span = (destination_start, destination_end)
        if span not in occupied:
            tokens.append(
                tools.LinkToken(
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
    return hidden, sorted(tokens, key=lambda token: token.destination_start)


def _markdown_targets(
    text: str,
    source: PurePosixPath,
    repo_root: Path,
) -> set[PurePosixPath]:
    tools = _link_tools()
    targets: set[PurePosixPath] = set()
    _hidden, tokens = _markdown_link_tokens(text)
    source_path = repo_root.joinpath(*source.parts)
    try:
        for token in tokens:
            destination = tools.resolve_destination(token, source_path, repo_root, source)
            if destination.is_local and destination.target is not None:
                targets.add(_relative(repo_root, destination.target))
    except tools.RenameError as error:
        raise LayoutError(str(error)) from error
    return targets


def _owners_from_json(value: Any, request_paths: dict[PurePosixPath, str]) -> set[str]:
    owners: set[str] = set()
    if isinstance(value, dict):
        for key, nested in value.items():
            if key == "request_file" and isinstance(nested, str):
                candidate = PurePosixPath(nested.split("#", 1)[0])
                if candidate in request_paths:
                    owners.add(request_paths[candidate])
            owners.update(_owners_from_json(nested, request_paths))
    elif isinstance(value, list):
        for nested in value:
            owners.update(_owners_from_json(nested, request_paths))
    return owners


def _single_owner(owners: set[str], context: PurePosixPath) -> str:
    if len(owners) != 1:
        detail = "no explicit owner" if not owners else "conflicting owners"
        raise LayoutError(f"{detail} for request-owned artifact: {context}")
    return next(iter(owners))


def _collect_owned_outputs(
    repo_root: Path,
    area: str,
    material_name: str,
    request_paths: dict[PurePosixPath, str],
) -> list[Move]:
    root = repo_root / area
    if not root.exists():
        return []
    publishable = set(_project_relative_files(repo_root))
    markdown: dict[str, Path] = {
        path.stem: path
        for path in sorted(root.glob("*.md"), key=lambda item: item.name)
        if path.name != "README.md" and _relative(repo_root, path) in publishable
    }
    configs_root = root / "Автоматизации"
    configs = {
        path.stem: path
        for path in sorted(configs_root.glob("*.json"), key=lambda item: item.name)
        if _relative(repo_root, path) in publishable
    } if configs_root.is_dir() else {}
    moves: list[Move] = []
    for name in sorted(set(markdown) | set(configs)):
        markdown_owners: set[str] = set()
        config_owners: set[str] = set()
        md_path = markdown.get(name)
        config_path = configs.get(name)
        if md_path is not None:
            rel = _relative(repo_root, md_path)
            targets = _markdown_targets(_read_text(md_path), rel, repo_root)
            markdown_owners.update(request_paths[target] for target in targets if target in request_paths)
        if config_path is not None:
            rel = _relative(repo_root, config_path)
            try:
                payload = json.loads(_read_text(config_path))
            except json.JSONDecodeError as error:
                raise LayoutError(f"invalid JSON owner config: {rel}") from error
            config_owners.update(_owners_from_json(payload, request_paths))
        context = _relative(repo_root, md_path or config_path)
        if config_path is not None:
            owner = _single_owner(config_owners, context)
            if md_path is not None and owner not in markdown_owners:
                raise LayoutError(f"Markdown artifact does not link its configured owner: {context}")
        else:
            owner = _single_owner(markdown_owners, context)
        base = JOURNAL / owner / "материалы" / material_name
        if md_path is not None:
            moves.append(Move(_relative(repo_root, md_path), base / md_path.name))
        if config_path is not None:
            moves.append(Move(_relative(repo_root, config_path), base / config_path.name))
    return moves


def _collect_source_packages(
    repo_root: Path,
    request_paths: dict[PurePosixPath, str],
) -> list[Move]:
    sources = repo_root / "Источники"
    if not sources.exists():
        return []
    publishable = _project_relative_files(repo_root)
    package_names = sorted(
        {
            relative.parts[1]
            for relative in publishable
            if len(relative.parts) >= 3
            and relative.parts[0] == "Источники"
            and relative.parts[1] != "URL"
        }
    )
    moves: list[Move] = []
    for package_name in package_names:
        package = sources / package_name
        if not package.is_dir():
            raise LayoutError(f"unexpected non-URL source artifact: {_relative(repo_root, package)}")
        package_rel = _relative(repo_root, package)
        package_files = [
            repo_root.joinpath(*relative.parts)
            for relative in publishable
            if package_rel in relative.parents
        ]
        if not package_files:
            raise LayoutError(f"empty non-URL source package: {package_rel}")
        owners_from_package: set[str] = set()
        for path in package_files:
            if path.suffix.lower() != ".md":
                continue
            rel = _relative(repo_root, path)
            targets = _markdown_targets(_read_text(path), rel, repo_root)
            owners_from_package.update(
                request_paths[target] for target in targets if target in request_paths
            )
        owner = _single_owner(owners_from_package, package_rel)
        owner_request = repo_root / request_paths_inv(request_paths)[owner]
        outbound = _markdown_targets(
            _read_text(owner_request), request_paths_inv(request_paths)[owner], repo_root
        )
        if not any(target == package_rel or package_rel in target.parents for target in outbound):
            raise LayoutError(f"source package lacks bidirectional owner link: {package_rel}")
        suffix = package.name
        prefix = owner + "_"
        if suffix.startswith(prefix) and len(suffix) > len(prefix):
            suffix = suffix[len(prefix) :]
        destination_root = JOURNAL / owner / "материалы" / "источники" / suffix
        for path in package_files:
            within = PurePosixPath(path.relative_to(package).as_posix())
            moves.append(Move(_relative(repo_root, path), destination_root / within))
    return moves


def request_paths_inv(request_paths: dict[PurePosixPath, str]) -> dict[str, PurePosixPath]:
    return {stem: path for path, stem in request_paths.items()}


def _existing_relative_paths(repo_root: Path) -> list[PurePosixPath]:
    result: list[PurePosixPath] = []
    for directory, names, files in os.walk(repo_root, topdown=True, followlinks=False):
        base = Path(directory)
        names[:] = sorted(name for name in names if name != ".git")
        if base != repo_root:
            result.append(_relative(repo_root, base))
        for name in sorted(files):
            result.append(_relative(repo_root, base / name))
    return result


def _portable_key(path: PurePosixPath) -> str:
    return unicodedata.normalize("NFC", path.as_posix()).casefold()


def _check_move_collisions(repo_root: Path, moves: Sequence[Move]) -> None:
    sources = {_portable_key(move.source) for move in moves}
    destinations: dict[str, PurePosixPath] = {}
    for move in moves:
        key = _portable_key(move.destination)
        previous = destinations.get(key)
        if previous is not None and previous != move.destination:
            raise LayoutError(f"portable destination collision: {previous} and {move.destination}")
        destinations[key] = move.destination

    existing = {_portable_key(path): path for path in _existing_relative_paths(repo_root)}
    for move in moves:
        destination = move.destination
        for candidate in (destination, *destination.parents):
            if candidate == PurePosixPath("."):
                continue
            key = _portable_key(candidate)
            if key not in existing:
                continue
            actual = existing[key]
            if key in sources:
                continue
            if candidate == destination and actual == destination and move.source == destination:
                continue
            if candidate == destination or (repo_root / actual).is_file():
                raise LayoutError(
                    f"destination collision for {destination}: existing {actual}"
                )


def _legacy_move_in_string(value: str, moves: Sequence[Move]) -> bool:
    return any(move.source.as_posix() in value for move in moves)


def _classify_json_node(
    value: Any,
    moves: Sequence[Move],
    file: PurePosixPath,
    path: tuple[str, ...],
    output: list[dict[str, str]],
    inherited_reason: str | None = None,
) -> None:
    reason = inherited_reason
    if reason is None and isinstance(value, dict):
        if _is_pinned_object(value):
            reason = "pinned_git_commit"
        elif _is_immutable_hashed_package(value):
            reason = "immutable_hashed_package"
    if isinstance(value, dict):
        for key in sorted(value):
            _classify_json_node(value[key], moves, file, path + (key,), output, reason)
        return
    if isinstance(value, list):
        for index, nested in enumerate(value):
            _classify_json_node(nested, moves, file, path + (str(index),), output, reason)
        return
    if not isinstance(value, str) or not _legacy_move_in_string(value, moves):
        return
    classification = "rewrite" if reason is None and _active_json_path(path) else "preserve"
    if reason is None:
        reason = "active_field" if classification == "rewrite" else "non_active_or_historical_field"
    output.append(
        {
            "file": file.as_posix(),
            "pointer": "/" + "/".join(part.replace("~", "~0").replace("/", "~1") for part in path),
            "classification": classification,
            "reason": reason,
        }
    )


def _json_classification(
    repo_root: Path,
    moves: Sequence[Move],
) -> list[dict[str, str]]:
    output: list[dict[str, str]] = []
    for path in _project_files(repo_root):
        if path.is_symlink() or not path.is_file() or path.suffix.casefold() != ".json":
            continue
        relative = _relative(repo_root, path)
        if relative.parts[:2] == ("Источники", "URL"):
            continue
        try:
            payload = json.loads(_read_text(path))
        except json.JSONDecodeError as error:
            raise LayoutError(f"invalid JSON during migration planning: {relative}") from error
        _classify_json_node(payload, moves, relative, (), output)
    return sorted(output, key=lambda item: (item["file"], item["pointer"]))


def build_plan(repo_root: Path) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    _assert_no_symlinks(
        repo_root,
        ("Запросы", "Журнал", "Ревью", "Оценки", "Источники"),
    )
    legacy = _legacy_requests(repo_root)
    canonical = _canonical_requests(repo_root)
    overlap = set(legacy) & set(canonical)
    if overlap:
        raise LayoutError(f"request exists in both layouts: {sorted(overlap)[0]}")
    all_requests = {**canonical, **legacy}
    request_paths = {path: stem for stem, path in all_requests.items()}
    reports = _legacy_reports(repo_root, set(all_requests))

    moves: list[Move] = []
    for stem, source in sorted(legacy.items()):
        moves.append(Move(source, canonical_request_path(stem)))
    for stem, source in sorted(reports.items()):
        moves.append(Move(source, canonical_report_path(stem)))
    moves.extend(_collect_owned_outputs(repo_root, "Ревью", "ревью", request_paths))
    moves.extend(_collect_owned_outputs(repo_root, "Оценки", "оценки", request_paths))
    moves.extend(_collect_source_packages(repo_root, request_paths))
    moves.sort(key=lambda item: (item.source.as_posix(), item.destination.as_posix()))
    _check_move_collisions(repo_root, moves)

    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "plan",
        "sessions": len(all_requests),
        "reports": len(reports)
        + sum(1 for stem in canonical if (repo_root / canonical_report_path(stem)).is_file()),
        "request_only": sum(
            1
            for stem in all_requests
            if stem not in reports and not (repo_root / canonical_report_path(stem)).is_file()
        ),
        "moves": [
            {"source": move.source.as_posix(), "destination": move.destination.as_posix()}
            for move in moves
        ],
        "json_references": _json_classification(repo_root, moves),
    }


def _moves_from_plan(plan: dict[str, Any]) -> list[Move]:
    if plan.get("schema_version") != SCHEMA_VERSION:
        raise LayoutError("unsupported migration plan schema")
    result: list[Move] = []
    for item in plan.get("moves", []):
        source = PurePosixPath(item["source"])
        destination = PurePosixPath(item["destination"])
        if source.is_absolute() or destination.is_absolute() or ".." in source.parts or ".." in destination.parts:
            raise LayoutError("migration plan contains an unsafe path")
        result.append(Move(source, destination))
    return result


def _path_maps(moves: Sequence[Move]) -> tuple[dict[PurePosixPath, PurePosixPath], list[tuple[PurePosixPath, PurePosixPath]]]:
    exact = {move.source: move.destination for move in moves}
    prefixes: dict[PurePosixPath, PurePosixPath] = {REQUESTS: JOURNAL}
    for move in moves:
        source_parts = move.source.parts
        if len(source_parts) >= 3 and source_parts[0] == "Источники":
            source_root = PurePosixPath(*source_parts[:2])
            destination_parts = move.destination.parts
            offset = len(source_parts) - 2
            destination_root = PurePosixPath(*destination_parts[:-offset]) if offset else move.destination
            prefixes[source_root] = destination_root
    ordered = sorted(prefixes.items(), key=lambda item: len(item[0].parts), reverse=True)
    return exact, ordered


def _mapped_path(
    value: PurePosixPath,
    exact: dict[PurePosixPath, PurePosixPath],
    prefixes: Sequence[tuple[PurePosixPath, PurePosixPath]],
) -> PurePosixPath:
    if value in exact:
        return exact[value]
    for source, destination in prefixes:
        if value == source:
            return destination
        if source in value.parents:
            return destination / value.relative_to(source)
    return value


def _request_body_span(text: str) -> tuple[int, int] | None:
    headings = list(re.finditer(r"(?m)^##[ \t]+Текст запроса[ \t]*\r?$", text))
    if not headings:
        return None
    if len(headings) != 1:
        raise LayoutError("request must contain exactly one ## Текст запроса section")
    heading = headings[0]
    start = text.find("\n", heading.end())
    start = len(text) if start < 0 else start + 1
    following = re.search(r"(?m)^##[ \t]+", text[start:])
    end = len(text) if following is None else start + following.start()
    return start, end


def _rewrite_markdown_links(
    text: str,
    source: PurePosixPath,
    destination: PurePosixPath,
    repo_root: Path,
    exact: dict[PurePosixPath, PurePosixPath],
    prefixes: Sequence[tuple[PurePosixPath, PurePosixPath]],
    protected: tuple[int, int] | None,
) -> str:
    tools = _link_tools()
    _hidden, tokens = _markdown_link_tokens(text)
    source_path = repo_root.joinpath(*source.parts)
    destination_path = repo_root.joinpath(*destination.parts)
    replacements: list[tuple[int, int, str]] = []
    try:
        for token in tokens:
            if protected is not None and protected[0] <= token.destination_start < protected[1]:
                continue
            resolved = tools.resolve_destination(token, source_path, repo_root, source)
            if not resolved.is_local or resolved.target is None:
                continue
            target_before = _relative(repo_root, resolved.target)
            target_after = _mapped_path(target_before, exact, prefixes)
            if destination == source and target_after == target_before:
                continue
            rendered_path = os.path.relpath(
                repo_root.joinpath(*target_after.parts), destination_path.parent
            ).replace(os.sep, "/")
            if resolved.decoded_path.endswith("/") and not rendered_path.endswith("/"):
                rendered_path += "/"
            replacement = tools.encode_destination_path(
                rendered_path, angle=token.angle_destination
            ) + resolved.suffix
            if replacement != token.raw_destination:
                replacements.append(
                    (token.destination_start, token.destination_end, replacement)
                )
    except tools.RenameError as error:
        raise LayoutError(str(error)) from error
    return tools.apply_text_replacements(text, replacements)


def _rewrite_exact_paths(text: str, moves: Sequence[Move]) -> str:
    result = text
    for move in sorted(moves, key=lambda item: len(item.source.as_posix()), reverse=True):
        result = result.replace(move.source.as_posix(), move.destination.as_posix())
    return result


def _rewrite_markdown(
    data: bytes,
    source: PurePosixPath,
    destination: PurePosixPath,
    repo_root: Path,
    moves: Sequence[Move],
    exact: dict[PurePosixPath, PurePosixPath],
    prefixes: Sequence[tuple[PurePosixPath, PurePosixPath]],
) -> bytes:
    if (
        source.parts[:2] == ("Источники", "URL")
        and source.name != "source-index.md"
    ):
        return data
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as error:
        raise LayoutError(f"Markdown is not UTF-8: {source}") from error
    is_request = source.name == REQUEST_FILE or source.parent == REQUESTS
    protected = _request_body_span(text) if is_request else None
    if is_request and protected is None:
        raise LayoutError(f"request has no protected text section: {source}")
    return _rewrite_markdown_links(
        text,
        source,
        destination,
        repo_root,
        exact,
        prefixes,
        protected,
    ).encode("utf-8")


def _is_pinned_object(value: dict[str, Any]) -> bool:
    state_ref = value.get("state_ref")
    return isinstance(state_ref, str) and GIT_STATE_PATTERN.fullmatch(state_ref) is not None


def _is_immutable_hashed_package(value: Any) -> bool:
    if not isinstance(value, dict):
        return False
    inputs = value.get("inputs")
    if not isinstance(value.get("package_id"), str) or not isinstance(inputs, list):
        return False
    if not isinstance(value.get("change_scope"), dict) or not inputs:
        return False
    hashed = [
        item
        for item in inputs
        if isinstance(item, dict)
        and isinstance(item.get("path"), str)
        and isinstance(item.get("sha256"), str)
        and HASH_PATTERN.fullmatch(item["sha256"]) is not None
    ]
    return len(hashed) == len(inputs)


def _active_json_path(path: tuple[str, ...]) -> bool:
    if not path:
        return False
    key = path[-1]
    return (
        key in ACTIVE_JSON_KEYS
        or (key == "path" and "exceptions" in path)
        or "provenance_refs" in path
    )


def _rewrite_json_value(
    value: Any,
    moves: Sequence[Move],
    path: tuple[str, ...] = (),
    *,
    immutable: bool = False,
) -> Any:
    if immutable:
        return value
    if isinstance(value, dict):
        if _is_pinned_object(value):
            return value
        return {
            key: _rewrite_json_value(
                nested,
                moves,
                path + (key,),
                immutable=False,
            )
            for key, nested in value.items()
        }
    if isinstance(value, list):
        return [
            _rewrite_json_value(nested, moves, path + ("[]",), immutable=False)
            for nested in value
        ]
    if not isinstance(value, str) or not path:
        return value
    if not _active_json_path(path):
        return value
    return _rewrite_exact_paths(value, moves)


def _rewrite_json(data: bytes, source: PurePosixPath, moves: Sequence[Move]) -> bytes:
    if source.parts[:2] == ("Источники", "URL"):
        return data
    try:
        value = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise LayoutError(f"invalid UTF-8 JSON: {source}") from error
    if _is_immutable_hashed_package(value):
        return data
    updated = _rewrite_json_value(value, moves)
    if updated == value:
        return data
    return (json.dumps(updated, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _index_section(text: str, *, required: bool = True) -> IndexSection | None:
    headings = list(re.finditer(r"(?m)^##[ \t]+(?P<title>[^\r\n]+)[ \t]*\r?$", text))
    selected = [
        (index, match)
        for index, match in enumerate(headings)
        if match.group("title").strip() in {"Папки запросов", "Сессии", "Отчёты"}
    ]
    if not selected:
        if required:
            raise LayoutError("journal README has no request index section")
        return None
    if len(selected) != 1:
        raise LayoutError("journal README has multiple request index sections")
    index, heading = selected[0]
    line_end = text.find("\n", heading.end())
    body_start = len(text) if line_end < 0 else line_end + 1
    end = headings[index + 1].start() if index + 1 < len(headings) else len(text)
    return IndexSection(heading.start(), body_start, end, heading.group("title").strip())


def _stem_for_index_target(target: PurePosixPath) -> str | None:
    if (
        len(target.parts) == 2
        and target.parts[0] in {"Запросы", "Журнал"}
        and target.suffix == ".md"
    ):
        stem = target.stem
    elif (
        len(target.parts) == 3
        and target.parts[0] == "Журнал"
        and target.name in {REQUEST_FILE, REPORT_FILE}
    ):
        stem = target.parts[1]
    else:
        return None
    return stem if is_valid_session_stem(stem) else None


def _index_entries(
    text: str,
    repo_root: Path,
    report_stems: set[str],
) -> dict[str, str]:
    section = _index_section(text)
    assert section is not None
    tools = _link_tools()
    entries: dict[str, str] = {}
    for line in text[section.body_start : section.end].splitlines():
        if not line.startswith("- "):
            continue
        _hidden, tokens = _markdown_link_tokens(line)
        candidates: list[tuple[Any, str]] = []
        try:
            for token in tokens:
                resolved = tools.resolve_destination(
                    token,
                    repo_root / "Журнал/README.md",
                    repo_root,
                    PurePosixPath("Журнал/README.md"),
                )
                if not resolved.is_local or resolved.target is None:
                    continue
                stem = _stem_for_index_target(_relative(repo_root, resolved.target))
                if stem is not None:
                    candidates.append((token, stem))
        except tools.RenameError as error:
            raise LayoutError(str(error)) from error
        if not candidates:
            continue
        if len(candidates) != 1:
            raise LayoutError("journal index entry must contain exactly one session link")
        token, stem = candidates[0]
        if stem in entries:
            raise LayoutError(f"journal index contains duplicate session entry: {stem}")
        _raw_path, suffix = tools.split_suffix(token.raw_destination)
        target_name = REPORT_FILE if stem in report_stems else REQUEST_FILE
        replacement = tools.encode_destination_path(
            f"{stem}/{target_name}", angle=token.angle_destination
        ) + suffix
        entries[stem] = tools.apply_text_replacements(
            line,
            [(token.destination_start, token.destination_end, replacement)],
        )
    return entries


def _index_text(
    text: str,
    stems: Sequence[str],
    report_stems: set[str],
    labels: dict[str, str],
    repo_root: Path,
    preferred: dict[str, str] | None = None,
) -> str:
    index = _index_section(text, required=False)
    existing = _index_entries(text, repo_root, report_stems) if index is not None else {}
    preferred = preferred or {}
    entries: list[str] = []
    for stem in sorted(stems, reverse=True):
        if stem in preferred:
            entries.append(preferred[stem])
            continue
        if stem in existing:
            entries.append(existing[stem])
            continue
        target_name = REPORT_FILE if stem in report_stems else REQUEST_FILE
        label = labels.get(stem, stem)
        entries.append(f"- [{label}]({stem}/{target_name})")
    body = "\n".join(entries) + ("\n" if entries else "")
    if index is None:
        return text.rstrip() + "\n\n## Сессии\n\n" + body
    canonical_title = "Папки запросов" if index.title == "Папки запросов" else "Сессии"
    rendered = f"## {canonical_title}\n\n{body}"
    if index.end < len(text):
        rendered += "\n"
    return text[: index.heading_start] + rendered + text[index.end :]


def _future_sessions(
    repo_root: Path,
    moves: Sequence[Move],
) -> tuple[list[str], set[str], dict[str, str]]:
    requests = set(_canonical_requests(repo_root))
    reports = {
        path.parent.name
        for path in (repo_root / str(JOURNAL)).glob(f"*/{REPORT_FILE}")
        if path.is_file()
    }
    for move in moves:
        stem = session_stem_for_request_path(move.destination)
        if stem is not None:
            requests.add(stem)
        if move.destination.name == REPORT_FILE and len(move.destination.parts) == 3:
            reports.add(move.destination.parent.name)
    labels: dict[str, str] = {}
    request_sources = {
        move.destination.parent.name: repo_root.joinpath(*move.source.parts)
        for move in moves
        if move.destination.name == REQUEST_FILE
    }
    for stem in requests:
        path = request_sources.get(stem, repo_root / canonical_request_path(stem))
        if not path.is_file():
            continue
        first = _read_text(path).splitlines()
        if first and first[0].startswith("# "):
            label = re.sub(r"^#\s+Исходный запрос\s*(?:—\s*)?", "", first[0]).strip()
            labels[stem] = label or stem
    return sorted(requests), reports, labels


def _prepare_apply(repo_root: Path, plan: dict[str, Any]) -> tuple[list[PreparedFile], list[PurePosixPath]]:
    moves = _moves_from_plan(plan)
    exact, prefixes = _path_maps(moves)
    move_by_source = {move.source: move.destination for move in moves}
    prepared: dict[PurePosixPath, PreparedFile] = {}
    for absolute in _project_files(repo_root):
        if absolute.is_symlink() or not absolute.is_file():
            continue
        source = _relative(repo_root, absolute)
        if source.parts and source.parts[0] == ".git":
            continue
        destination = move_by_source.get(source, source)
        data = absolute.read_bytes()
        if source.suffix.casefold() == ".md":
            data = _rewrite_markdown(
                data, source, destination, repo_root, moves, exact, prefixes
            )
        elif source.suffix.casefold() == ".json":
            data = _rewrite_json(data, source, moves)
        mode = stat.S_IMODE(absolute.stat().st_mode)
        if destination != source or data != absolute.read_bytes():
            prepared[destination] = PreparedFile(destination, data, mode)

    index = PurePosixPath("Журнал/README.md")
    index_path = repo_root / index
    if not index_path.is_file():
        raise LayoutError("Журнал/README.md is required")
    base = prepared[index].data if index in prepared else index_path.read_bytes()
    try:
        index_before = base.decode("utf-8")
    except UnicodeDecodeError as error:
        raise LayoutError("Журнал/README.md is not UTF-8") from error
    stems, reports, labels = _future_sessions(repo_root, moves)
    index_after = _index_text(index_before, stems, reports, labels, repo_root).encode("utf-8")
    if index_after != index_path.read_bytes() or index in prepared:
        prepared[index] = PreparedFile(
            index,
            index_after,
            stat.S_IMODE(index_path.stat().st_mode),
        )

    # Every moved source is deleted after its independently prepared destination is installed.
    deletes = sorted(
        {move.source for move in moves if move.source != move.destination},
        key=lambda path: (len(path.parts), path.as_posix()),
        reverse=True,
    )
    return sorted(prepared.values(), key=lambda item: item.path.as_posix()), deletes


def _snapshot_path(path: Path) -> PathSnapshot:
    if path.is_symlink():
        return PathSnapshot("symlink", os.readlink(path), None)
    if path.is_file():
        return PathSnapshot("file", path.read_bytes(), stat.S_IMODE(path.stat().st_mode))
    if path.is_dir():
        return PathSnapshot("directory", None, stat.S_IMODE(path.stat().st_mode))
    return PathSnapshot("missing", None, None)


def _remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def _restore_path(path: Path, snapshot: PathSnapshot) -> None:
    if path.exists() or path.is_symlink():
        _remove_path(path)
    if snapshot.kind == "missing":
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if snapshot.kind == "symlink":
        assert isinstance(snapshot.data, str)
        path.symlink_to(snapshot.data)
    elif snapshot.kind == "directory":
        path.mkdir(parents=True, exist_ok=True)
        assert snapshot.mode is not None
        path.chmod(snapshot.mode)
    else:
        assert isinstance(snapshot.data, bytes) and snapshot.mode is not None
        path.write_bytes(snapshot.data)
        path.chmod(snapshot.mode)


def _install_prepared_file(repo_root: Path, prepared: PreparedFile) -> None:
    destination = repo_root.joinpath(*prepared.path.parts)
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.", suffix=".fum-layout", dir=destination.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(prepared.data)
            stream.flush()
            os.fsync(stream.fileno())
        temporary.chmod(prepared.mode)
        os.replace(temporary, destination)
    finally:
        if temporary.exists():
            temporary.unlink()


def _prune_empty_managed_directories(repo_root: Path) -> None:
    roots = [
        repo_root / "Запросы",
        repo_root / "Ревью" / "Автоматизации",
        repo_root / "Оценки" / "Автоматизации",
    ]
    sources = repo_root / "Источники"
    if sources.is_dir():
        roots.extend(
            path
            for path in sources.iterdir()
            if path.is_dir() and path.name != "URL"
        )
    for root in roots:
        if not root.exists() or not root.is_dir():
            continue
        for directory, _names, _files in os.walk(root, topdown=False):
            candidate = Path(directory)
            try:
                candidate.rmdir()
            except OSError:
                pass


def apply_plan(repo_root: Path, plan: dict[str, Any]) -> dict[str, Any]:
    prepared, deletes = _prepare_apply(repo_root, plan)
    touched = {item.path for item in prepared} | set(deletes)
    snapshots = {
        relative: _snapshot_path(repo_root.joinpath(*relative.parts))
        for relative in sorted(touched, key=str)
    }
    index = repo_root / ".git" / "index"
    index_before = index.read_bytes() if index.is_file() else None
    missing_parents: set[Path] = set()
    for item in prepared:
        parent = repo_root.joinpath(*item.path.parts).parent
        while parent != repo_root and not parent.exists():
            missing_parents.add(parent)
            parent = parent.parent
    backup_parent = repo_root / ".git" if (repo_root / ".git").is_dir() else repo_root
    backup_root = Path(tempfile.mkdtemp(prefix="fum-layout-rollback-", dir=backup_parent))
    staging_root = Path(tempfile.mkdtemp(prefix="fum-layout-staging-", dir=backup_parent))
    backups: dict[PurePosixPath, Path] = {}
    mutated: set[PurePosixPath] = set()

    def save_original(relative: PurePosixPath) -> None:
        path = repo_root.joinpath(*relative.parts)
        if relative in backups or not (path.exists() or path.is_symlink()):
            return
        backup = backup_root / str(len(backups))
        os.replace(path, backup)
        backups[relative] = backup
        mutated.add(relative)

    try:
        for item in prepared:
            _install_prepared_file(staging_root, item)
        for item in prepared:
            save_original(item.path)
        for item in prepared:
            destination = repo_root.joinpath(*item.path.parts)
            destination.parent.mkdir(parents=True, exist_ok=True)
            os.replace(staging_root.joinpath(*item.path.parts), destination)
            mutated.add(item.path)
        for relative in deletes:
            save_original(relative)
        _prune_empty_managed_directories(repo_root)
    except Exception as error:
        for relative in sorted(mutated, key=lambda path: len(path.parts), reverse=True):
            path = repo_root.joinpath(*relative.parts)
            if path.exists() or path.is_symlink():
                _remove_path(path)
            backup = backups.get(relative)
            if backup is not None and backup.exists():
                path.parent.mkdir(parents=True, exist_ok=True)
                os.replace(backup, path)
            elif snapshots[relative].kind != "missing":
                _restore_path(path, snapshots[relative])
        for directory in sorted(missing_parents, key=lambda path: len(path.parts), reverse=True):
            try:
                directory.rmdir()
            except OSError:
                pass
        if index_before is not None and index.read_bytes() != index_before:
            index.write_bytes(index_before)
        shutil.rmtree(backup_root, ignore_errors=True)
        shutil.rmtree(staging_root, ignore_errors=True)
        raise LayoutError(f"apply failed and was rolled back: {error}") from error
    shutil.rmtree(backup_root)
    shutil.rmtree(staging_root)
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "apply",
        "moves": len(_moves_from_plan(plan)),
        "written_files": len(prepared),
    }


def _expected_header_label(stem: str) -> str:
    match = SESSION_PATTERN.fullmatch(stem)
    assert match is not None
    prefix = match.group("prefix")
    label = dt.datetime.strptime(prefix, "%Y-%m-%d_%H-%M-%S_MSK").strftime(
        "%Y-%m-%d %H:%M:%S MSK"
    )
    return label


def _validate_request_header(path: Path, stem: str) -> None:
    text = _read_text(path)
    first = text.splitlines()[0] if text.splitlines() else ""
    expected = f"# Исходный запрос {_expected_header_label(stem)}"
    if not first.startswith(expected):
        raise LayoutError(f"request title prefix does not match folder {stem}: {path.name}")


def _validate_navigation(
    repo_root: Path,
    request: Path,
    previous: str | None,
    following: str | None,
) -> None:
    text = _read_text(request)
    relative = _relative(repo_root, request)
    for name, expected in (("Предыдущий", previous), ("Следующий", following)):
        match = re.search(rf"(?m)^-[ \t]+{name} запрос:[ \t]*(?P<value>.*)$", text)
        if match is None:
            raise LayoutError(f"request navigation lacks {name.casefold()} entry: {relative}")
        value = match.group("value").strip()
        if expected is None:
            if value != "нет":
                raise LayoutError(f"request navigation has unexpected {name.casefold()} link: {relative}")
            continue
        targets = _markdown_targets(value, relative, repo_root)
        if targets != {canonical_request_path(expected)}:
            raise LayoutError(f"request navigation has wrong {name.casefold()} link: {relative}")


def _is_raw_material(relative: PurePosixPath) -> bool:
    return (
        relative.parts[:2] == ("Источники", "URL")
        and relative.name != "source-index.md"
    ) or (
        len(relative.parts) >= 4
        and relative.parts[0] == "Журнал"
        and relative.parts[2:4] == ("материалы", "источники")
        and relative.suffix.casefold() != ".md"
    )


def _markdown_has_active_legacy_link(
    text: str,
    relative: PurePosixPath,
    repo_root: Path,
) -> bool:
    tools = _link_tools()
    _hidden, tokens = _markdown_link_tokens(text)
    protected = _request_body_span(text) if relative.name == REQUEST_FILE else None
    if relative.name == REQUEST_FILE and protected is None:
        raise LayoutError(f"request has no protected text section: {relative}")
    referrer = repo_root.joinpath(*relative.parts)
    try:
        for token in tokens:
            if protected is not None and protected[0] <= token.destination_start < protected[1]:
                continue
            destination = tools.resolve_destination(token, referrer, repo_root, relative)
            if not destination.is_local or destination.target is None:
                continue
            target = _relative(repo_root, destination.target)
            if target.parts and target.parts[0] == "Запросы":
                return True
            if (
                len(target.parts) == 2
                and target.parts[0] == "Журнал"
                and target.suffix == ".md"
                and target.name != "README.md"
            ):
                return True
    except tools.RenameError as error:
        raise LayoutError(str(error)) from error
    return False


def _json_active_legacy(value: Any, path: tuple[str, ...] = ()) -> bool:
    if isinstance(value, dict):
        if _is_pinned_object(value) or _is_immutable_hashed_package(value):
            return False
        return any(_json_active_legacy(nested, path + (key,)) for key, nested in value.items())
    if isinstance(value, list):
        return any(_json_active_legacy(nested, path + ("[]",)) for nested in value)
    if not isinstance(value, str) or not path:
        return False
    if not _active_json_path(path):
        return False
    return "Запросы/" in value or re.search(
        r"(?:^|[\s'\"])Журнал/\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_MSK[^/\s'\"]*\.md",
        value,
    ) is not None


def _validate_no_legacy_references(repo_root: Path) -> None:
    for path in _project_files(repo_root):
        if path.is_symlink() or not path.is_file():
            continue
        relative = _relative(repo_root, path)
        if _is_raw_material(relative):
            continue
        if path.suffix.casefold() == ".md":
            text = _read_text(path)
            if _markdown_has_active_legacy_link(text, relative, repo_root):
                raise LayoutError(f"active legacy Markdown link remains in {relative}")
        elif path.suffix.casefold() == ".json":
            try:
                payload = json.loads(_read_text(path))
            except json.JSONDecodeError as error:
                raise LayoutError(f"invalid JSON: {relative}") from error
            if _json_active_legacy(payload):
                raise LayoutError(f"active legacy JSON reference remains in {relative}")


def _validate_retired_owned_areas(repo_root: Path) -> None:
    publishable = _project_relative_files(repo_root)
    for area in ("Ревью", "Оценки"):
        leftovers = [
            repo_root.joinpath(*relative.parts)
            for relative in publishable
            if relative.parts
            and relative.parts[0] == area
            and relative.name != "README.md"
        ]
        if leftovers:
            raise LayoutError(f"request-owned artifact remains outside request folder: {_relative(repo_root, leftovers[0])}")
    non_url_sources = [
        relative
        for relative in publishable
        if len(relative.parts) >= 2
        and relative.parts[0] == "Источники"
        and relative.parts[1] not in {"URL", "README.md"}
    ]
    if non_url_sources:
        raise LayoutError(
            f"non-URL request source remains outside request folder: {non_url_sources[0]}"
        )


def validate_layout(repo_root: Path | str) -> dict[str, Any]:
    root = Path(repo_root).resolve()
    _assert_no_symlinks(root, ("Запросы", "Журнал", "Ревью", "Оценки", "Источники"))
    publishable = set(_project_relative_files(root))
    legacy = root / str(REQUESTS)
    if any(relative.parts and relative.parts[0] == str(REQUESTS) for relative in publishable):
        raise LayoutError("legacy Запросы directory still exists")
    journal = root / str(JOURNAL)
    if not journal.is_dir() or not (journal / "README.md").is_file():
        raise LayoutError("Журнал/README.md is required")

    stems: list[str] = []
    portable: dict[str, str] = {}
    reports: set[str] = set()
    for entry in sorted(journal.iterdir(), key=lambda item: item.name):
        entry_relative = _relative(root, entry)
        entry_is_publishable = entry_relative in publishable or any(
            entry_relative in relative.parents for relative in publishable
        )
        if not entry_is_publishable:
            continue
        if entry.name == "README.md":
            continue
        if not entry.is_dir():
            raise LayoutError(f"orphan legacy report or unexpected Journal entry: {entry.name}")
        _validate_stem(entry.name, "journal request folder")
        key = _portable_key(PurePosixPath(entry.name))
        if key in portable:
            raise LayoutError(f"portable collision between request folders: {portable[key]} and {entry.name}")
        portable[key] = entry.name
        request = entry / REQUEST_FILE
        request_relative = _relative(root, request)
        if request_relative not in publishable or not request.is_file():
            raise LayoutError(f"request folder has no {REQUEST_FILE}: {entry.name}")
        allowed = {REQUEST_FILE, REPORT_FILE, "материалы"}
        unexpected = sorted(
            child.name
            for child in entry.iterdir()
            if child.name not in allowed
            and (
                _relative(root, child) in publishable
                or any(_relative(root, child) in relative.parents for relative in publishable)
            )
        )
        if unexpected:
            raise LayoutError(f"unexpected top-level entry in request folder {entry.name}: {unexpected[0]}")
        materials = entry / "материалы"
        if materials.exists() and not materials.is_dir():
            raise LayoutError(f"request materials must be a directory: {entry.name}")
        report = entry / REPORT_FILE
        if report.exists() and not report.is_file():
            raise LayoutError(f"request report must be a file: {entry.name}")
        _validate_request_header(request, entry.name)
        stems.append(entry.name)
        if _relative(root, entry / REPORT_FILE) in publishable and (entry / REPORT_FILE).is_file():
            reports.add(entry.name)

    ordered_stems = sorted(stems)
    for position, stem in enumerate(ordered_stems):
        _validate_navigation(
            root,
            journal / stem / REQUEST_FILE,
            ordered_stems[position - 1] if position else None,
            ordered_stems[position + 1] if position + 1 < len(ordered_stems) else None,
        )

    index_text = _read_text(journal / "README.md")
    index_section = _index_section(index_text)
    assert index_section is not None
    index_body = index_text[index_section.body_start : index_section.end]
    indexed: list[str] = []
    index_link_pattern = re.compile(
        r"\((?:<)?(?P<stem>\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_MSK(?:_[^/)>]+)?)/(?P<name>запрос|отчёт)\.md(?:>)?\)"
    )
    for match in index_link_pattern.finditer(index_body):
        stem = match.group("stem")
        if stem not in stems:
            raise LayoutError(f"journal index contains unknown session: {stem}")
        expected_name = "отчёт" if stem in reports else "запрос"
        if match.group("name") != expected_name:
            raise LayoutError(f"journal index targets wrong file for session: {stem}")
        indexed.append(stem)
    for stem in stems:
        if indexed.count(stem) != 1:
            raise LayoutError(f"journal index must contain session exactly once: {stem}")
    _validate_retired_owned_areas(root)
    _validate_no_legacy_references(root)
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "validate",
        "sessions": len(stems),
        "reports": len(reports),
        "request_only": len(stems) - len(reports),
    }


def _request_heading_label(text: str, stem: str) -> str:
    first = text.splitlines()[0] if text.splitlines() else ""
    prefix = "# Исходный запрос "
    if not first.startswith(prefix):
        raise LayoutError(f"request heading cannot provide navigation label: {stem}")
    label = first[len(prefix) :].strip()
    expected = _expected_header_label(stem)
    if not label.startswith(expected):
        raise LayoutError(f"request heading label does not match session stem: {stem}")
    return label


def _navigation(
    previous: str | None,
    following: str | None,
    labels: dict[str, str],
) -> str:
    previous_value = (
        f"[{labels[previous]}](../{previous}/{REQUEST_FILE})"
        if previous
        else "нет"
    )
    following_value = (
        f"[{labels[following]}](../{following}/{REQUEST_FILE})"
        if following
        else "нет"
    )
    return (
        "## Навигация по запросам\n\n"
        f"- Предыдущий запрос: {previous_value}\n"
        f"- Следующий запрос: {following_value}\n"
    )


def _replace_navigation(
    text: str,
    previous: str | None,
    following: str | None,
    labels: dict[str, str],
) -> str:
    match = re.search(r"(?m)^##[ \t]+Навигация по запросам[ \t]*\r?$", text)
    if match is None:
        raise LayoutError("request has no navigation section")
    following_heading = re.search(r"(?m)^##[ \t]+", text[match.end() :])
    end = len(text) if following_heading is None else match.end() + following_heading.start()
    replacement = _navigation(previous, following, labels) + "\n"
    return text[: match.start()] + replacement + text[end:]


def _fence_for(message: str) -> str:
    longest = max((len(match.group(0)) for match in re.finditer(r"`+", message)), default=0)
    return "`" * max(4, longest + 1)


def _request_document(
    stem: str,
    title: str,
    previous: str | None,
    following: str | None,
    messages: Sequence[str],
    thread_id: str,
    labels: dict[str, str],
) -> str:
    blocks: list[str] = []
    for message in messages:
        fence = _fence_for(message)
        blocks.append(f"{fence}text\n{message}\n{fence}")
    raw = "\n\n".join(blocks)
    return (
        f"# Исходный запрос {_expected_header_label(stem)} - {title}\n\n"
        f"{_navigation(previous, following, labels)}\n"
        "## Текст запроса\n\n"
        f"{raw}\n\n"
        "## Идентификатор сеанса Codex\n\n"
        f"Codex-Thread-ID: {thread_id}\n"
    )


def _report_document(title: str) -> str:
    return (
        f"# Отчёт — {title}\n\n"
        "Результат рабочей сессии будет зафиксирован здесь.\n\n"
        "## Исходный запрос\n\n"
        f"- [запрос]({REQUEST_FILE})\n"
    )


def _apply_prepared_transaction(repo_root: Path, prepared: Sequence[PreparedFile]) -> None:
    touched = {item.path for item in prepared}
    snapshots = {
        relative: _snapshot_path(repo_root.joinpath(*relative.parts))
        for relative in touched
    }
    missing_parents: set[Path] = set()
    for item in prepared:
        parent = repo_root.joinpath(*item.path.parts).parent
        while parent != repo_root and not parent.exists():
            missing_parents.add(parent)
            parent = parent.parent
    try:
        for item in sorted(prepared, key=lambda value: value.path.as_posix()):
            _install_prepared_file(repo_root, item)
    except Exception as error:
        for relative in sorted(touched, key=lambda path: len(path.parts), reverse=True):
            _restore_path(repo_root.joinpath(*relative.parts), snapshots[relative])
        for directory in sorted(missing_parents, key=lambda path: len(path.parts), reverse=True):
            try:
                directory.rmdir()
            except OSError:
                pass
        raise LayoutError(f"start failed and was rolled back: {error}") from error


def start_session(
    repo_root: Path,
    stem: str,
    label: str,
    title: str,
    thread_id: str,
    messages: Sequence[str],
) -> dict[str, Any]:
    root = repo_root.resolve()
    _validate_stem(stem, "start session stem")
    match = SESSION_PATTERN.fullmatch(stem)
    assert match is not None
    if not match.group("label") or match.group("label") != label:
        raise LayoutError("start session stem label does not match --label")
    if not title.strip() or not thread_id.strip():
        raise LayoutError("start requires non-empty title and Codex thread id")
    if not all(isinstance(message, str) for message in messages):
        raise LayoutError("messages JSON must be an array of strings")
    current = _canonical_requests(root)
    if stem in current:
        others = sorted(value for value in current if value != stem)
    else:
        others = sorted(current)
    ordered = sorted([*others, stem])
    position = ordered.index(stem)
    previous = ordered[position - 1] if position else None
    following = ordered[position + 1] if position + 1 < len(ordered) else None
    labels = {
        existing_stem: _request_heading_label(
            _read_text(root / path),
            existing_stem,
        )
        for existing_stem, path in current.items()
    }
    labels[stem] = f"{_expected_header_label(stem)} - {title}"
    request_text = _request_document(
        stem,
        title,
        previous,
        following,
        messages,
        thread_id,
        labels,
    )
    report_text = _report_document(title)
    request_rel = canonical_request_path(stem)
    report_rel = canonical_report_path(stem)
    request_path = root / request_rel
    report_path = root / report_rel
    if request_path.exists() or report_path.exists():
        if (
            request_path.is_file()
            and report_path.is_file()
            and request_path.read_text(encoding="utf-8") == request_text
            and report_path.read_text(encoding="utf-8") == report_text
        ):
            return {
                "schema_version": SCHEMA_VERSION,
                "mode": "start",
                "session_stem": stem,
                "idempotent": True,
            }
        raise LayoutError(f"start conflict: request folder already exists for {stem}")

    prepared: list[PreparedFile] = [
        PreparedFile(request_rel, request_text.encode("utf-8"), 0o644),
        PreparedFile(report_rel, report_text.encode("utf-8"), 0o644),
    ]
    neighbours = [(previous, position - 1), (following, position + 1)]
    for neighbour, neighbour_position in neighbours:
        if neighbour is None:
            continue
        before = ordered[neighbour_position - 1] if neighbour_position else None
        after = ordered[neighbour_position + 1] if neighbour_position + 1 < len(ordered) else None
        relative = canonical_request_path(neighbour)
        path = root / relative
        updated = _replace_navigation(
            _read_text(path),
            before,
            after,
            labels,
        ).encode("utf-8")
        if updated != path.read_bytes():
            prepared.append(
                PreparedFile(relative, updated, stat.S_IMODE(path.stat().st_mode))
            )
    index_rel = PurePosixPath("Журнал/README.md")
    index_path = root / index_rel
    labels = {stem: f"{_expected_header_label(stem)} — {title}"}
    for existing_stem, path_rel in current.items():
        lines = _read_text(root / path_rel).splitlines()
        if lines:
            labels[existing_stem] = re.sub(
                r"^#\s+Исходный запрос\s*(?:—\s*)?", "", lines[0]
            ).strip() or existing_stem
    reports = {
        existing_stem
        for existing_stem in current
        if (root / canonical_report_path(existing_stem)).is_file()
    }
    reports.add(stem)
    index_updated = _index_text(
        _read_text(index_path), ordered, reports, labels, root
    ).encode("utf-8")
    if index_updated != index_path.read_bytes():
        prepared.append(
            PreparedFile(index_rel, index_updated, stat.S_IMODE(index_path.stat().st_mode))
        )
    _apply_prepared_transaction(root, prepared)
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "start",
        "session_stem": stem,
        "idempotent": False,
    }


def reindex_journal(repo_root: Path, baseline: str | None) -> dict[str, Any]:
    root = repo_root.resolve()
    stems, reports, labels = _future_sessions(root, ())
    preferred: dict[str, str] = {}
    if baseline is not None:
        preferred = {
            stem: line
            for stem, line in _index_entries(baseline, root, reports).items()
            if stem in stems
        }
    index_relative = PurePosixPath("Журнал/README.md")
    index_path = root / index_relative
    current = _read_text(index_path)
    updated = _index_text(
        current,
        stems,
        reports,
        labels,
        root,
        preferred=preferred,
    )
    if updated == current:
        return {
            "schema_version": SCHEMA_VERSION,
            "mode": "reindex",
            "sessions": len(stems),
            "preferred_entries": len(preferred),
            "idempotent": True,
        }
    _apply_prepared_transaction(
        root,
        [
            PreparedFile(
                index_relative,
                updated.encode("utf-8"),
                stat.S_IMODE(index_path.stat().st_mode),
            )
        ],
    )
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "reindex",
        "sessions": len(stems),
        "preferred_entries": len(preferred),
        "idempotent": False,
    }


def _git_environment() -> dict[str, str]:
    environment = os.environ.copy()
    for name in (
        "GIT_DIR",
        "GIT_WORK_TREE",
        "GIT_INDEX_FILE",
        "GIT_NAMESPACE",
        "GIT_OBJECT_DIRECTORY",
        "GIT_ALTERNATE_OBJECT_DIRECTORIES",
        "GIT_COMMON_DIR",
        "GIT_CEILING_DIRECTORIES",
    ):
        environment.pop(name, None)
    environment["GIT_NO_REPLACE_OBJECTS"] = "1"
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    return environment


def _exact_base_revision(repo_root: Path, value: str) -> str:
    if FULL_GIT_OID_PATTERN.fullmatch(value) is None:
        raise LayoutError("repair requires an exact full lowercase Git commit OID")
    result = subprocess.run(
        ["git", "--no-replace-objects", "rev-parse", "--verify", f"{value}^{{commit}}"],
        cwd=repo_root,
        env=_git_environment(),
        check=False,
        capture_output=True,
        text=True,
    )
    resolved = result.stdout.strip()
    if result.returncode != 0 or resolved != value:
        raise LayoutError("repair base revision is not the exact requested commit object")
    return resolved


def _extract_base_snapshot(repo_root: Path, revision: str, snapshot_root: Path) -> None:
    archive = snapshot_root.parent / "base.tar"
    result = subprocess.run(
        [
            "git",
            "--no-replace-objects",
            "archive",
            "--format=tar",
            f"--output={archive}",
            revision,
        ],
        cwd=repo_root,
        env=_git_environment(),
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        detail = os.fsdecode(result.stderr).strip() or "git archive failed"
        raise LayoutError(f"cannot materialize repair base revision: {detail}")
    snapshot_root.mkdir()
    try:
        with tarfile.open(archive, mode="r:") as stream:
            for member in stream.getmembers():
                relative = PurePosixPath(member.name)
                if relative.is_absolute() or ".." in relative.parts or not relative.parts:
                    raise LayoutError(f"unsafe path in repair base archive: {member.name}")
                destination = snapshot_root.joinpath(*relative.parts)
                if member.isdir():
                    destination.mkdir(parents=True, exist_ok=True)
                    destination.chmod(member.mode & 0o777)
                    continue
                if not member.isfile():
                    raise LayoutError(
                        f"repair base archive contains a non-regular entry: {member.name}"
                    )
                source = stream.extractfile(member)
                if source is None:
                    raise LayoutError(f"cannot read repair base archive entry: {member.name}")
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(source.read())
                destination.chmod(member.mode & 0o777)
    finally:
        archive.unlink(missing_ok=True)
    environment = _git_environment()
    for arguments in (("init", "-q"), ("add", "-f", "--all")):
        initialized = subprocess.run(
            ["git", *arguments],
            cwd=snapshot_root,
            env=environment,
            check=False,
            capture_output=True,
        )
        if initialized.returncode != 0:
            detail = os.fsdecode(initialized.stderr).strip() or "temporary Git setup failed"
            raise LayoutError(f"cannot inventory repair base revision: {detail}")


def _link_identities(
    text: str,
    tokens: Sequence[Any],
) -> dict[tuple[int, int], tuple[str, int, str, bool, int]]:
    """Identify a link by destination-free line structure and stable occurrence."""

    tools = _link_tools()
    identities: dict[tuple[int, int], tuple[str, int, str, bool, int]] = {}
    occurrences: dict[tuple[str, int, str, bool], int] = {}
    ordered = sorted(tokens, key=lambda token: token.destination_start)
    for line_start, line_end, _line in tools.line_ranges(text):
        line_tokens = [
            token
            for token in ordered
            if line_start <= token.destination_start
            and token.destination_end <= line_end
        ]
        if not line_tokens:
            continue
        pieces: list[str] = []
        cursor = line_start
        for token in line_tokens:
            pieces.append(text[cursor : token.destination_start])
            pieces.append("<FUM-LINK-DESTINATION>")
            cursor = token.destination_end
        pieces.append(text[cursor:line_end])
        normalized_line = "".join(pieces)
        for ordinal, token in enumerate(line_tokens):
            base = (
                normalized_line,
                ordinal,
                token.kind,
                token.angle_destination,
            )
            occurrence = occurrences.get(base, 0)
            occurrences[base] = occurrence + 1
            identities[(token.destination_start, token.destination_end)] = (
                *base,
                occurrence,
            )
    return identities


def _base_link_replacements(
    text: str,
    source: PurePosixPath,
    destination: PurePosixPath,
    snapshot_root: Path,
    current_root: Path,
    exact: dict[PurePosixPath, PurePosixPath],
    prefixes: Sequence[tuple[PurePosixPath, PurePosixPath]],
) -> dict[tuple[str, int, str, bool, int], ProvenLinkRepair]:
    if (
        source.parts[:2] == ("Источники", "URL")
        and source.name != "source-index.md"
    ):
        return {}
    tools = _link_tools()
    _hidden, tokens = _markdown_link_tokens(text)
    protected = _request_body_span(text) if source.parent == REQUESTS else None
    if source.parent == REQUESTS and protected is None:
        raise LayoutError(f"request has no protected text section in repair base: {source}")
    source_path = snapshot_root.joinpath(*source.parts)
    destination_path = current_root.joinpath(*destination.parts)
    active_tokens = [
        token
        for token in tokens
        if protected is None
        or not (protected[0] <= token.destination_start < protected[1])
    ]
    identities = _link_identities(text, active_tokens)
    rendered: dict[tuple[int, int], str] = {}
    transitions: dict[tuple[str, bool], str] = {}
    try:
        for token in active_tokens:
            resolved = tools.resolve_destination(
                token,
                source_path,
                snapshot_root,
                source,
            )
            if not resolved.is_local or resolved.target is None:
                continue
            target_before = _relative(snapshot_root, resolved.target)
            target_after = _mapped_path(target_before, exact, prefixes)
            rendered_path = os.path.relpath(
                current_root.joinpath(*target_after.parts),
                destination_path.parent,
            ).replace(os.sep, "/")
            if resolved.decoded_path.endswith("/") and not rendered_path.endswith("/"):
                rendered_path += "/"
            replacement = tools.encode_destination_path(
                rendered_path,
                angle=token.angle_destination,
            ) + resolved.suffix
            rendered[(token.destination_start, token.destination_end)] = replacement
            transition_key = (token.raw_destination, token.angle_destination)
            if replacement == token.raw_destination:
                continue
            previous = transitions.get(transition_key)
            if previous is not None and previous != replacement:
                raise LayoutError(
                    f"ambiguous repair mapping in {source}: {token.raw_destination}"
                )
            transitions[transition_key] = replacement
    except tools.RenameError as error:
        raise LayoutError(str(error)) from error
    replacements: dict[tuple[str, int, str, bool, int], ProvenLinkRepair] = {}
    for token in active_tokens:
        span = (token.destination_start, token.destination_end)
        identity = identities.get(span)
        expected = rendered.get(span)
        if identity is None or expected is None or expected == token.raw_destination:
            continue
        accepted = {token.raw_destination}
        cursor = token.raw_destination
        while True:
            following = transitions.get((cursor, token.angle_destination))
            if following is None or following in accepted:
                break
            accepted.add(following)
            cursor = following
        accepted.add(expected)
        replacements[identity] = ProvenLinkRepair(
            angle=token.angle_destination,
            expected=expected,
            accepted=frozenset(accepted),
        )
    return replacements


def _apply_proven_link_replacements(
    text: str,
    relative: PurePosixPath,
    replacements: dict[tuple[str, int, str, bool, int], ProvenLinkRepair],
) -> tuple[str, int]:
    if not replacements:
        return text, 0
    tools = _link_tools()
    _hidden, tokens = _markdown_link_tokens(text)
    protected = _request_body_span(text) if relative.name == REQUEST_FILE else None
    if relative.name == REQUEST_FILE and protected is None:
        raise LayoutError(f"request has no protected text section during repair: {relative}")
    active_tokens = [
        token
        for token in tokens
        if protected is None
        or not (protected[0] <= token.destination_start < protected[1])
    ]
    identities = _link_identities(text, active_tokens)
    edits: list[tuple[int, int, str]] = []
    for token in active_tokens:
        identity = identities.get((token.destination_start, token.destination_end))
        repair = replacements.get(identity) if identity is not None else None
        if (
            repair is not None
            and token.angle_destination == repair.angle
            and token.raw_destination in repair.accepted
            and token.raw_destination != repair.expected
        ):
            edits.append(
                (token.destination_start, token.destination_end, repair.expected)
            )
    return tools.apply_text_replacements(text, edits), len(edits)


def _protected_request_body(text: str, relative: PurePosixPath) -> bytes:
    span = _request_body_span(text)
    if span is None:
        raise LayoutError(f"request has no protected text section during repair: {relative}")
    return text[span[0] : span[1]].encode("utf-8")


def _prepare_repair(
    repo_root: Path,
    base_revision: str,
) -> tuple[list[PreparedFile], dict[str, Any]]:
    root = repo_root.resolve()
    revision = _exact_base_revision(root, base_revision)
    prepared: dict[PurePosixPath, PreparedFile] = {}
    semantic_files: set[PurePosixPath] = set()
    navigation_files: set[PurePosixPath] = set()
    semantic_links = 0
    with tempfile.TemporaryDirectory(prefix="fum-request-layout-base-") as temporary:
        snapshot_root = Path(temporary) / "checkout"
        _extract_base_snapshot(root, revision, snapshot_root)
        migration_plan = build_plan(snapshot_root)
        moves = _moves_from_plan(migration_plan)
        exact, prefixes = _path_maps(moves)
        current_publishable = set(_project_relative_files(root))
        for base_path in _project_files(snapshot_root):
            if base_path.suffix.casefold() != ".md" or base_path.is_symlink():
                continue
            source = _relative(snapshot_root, base_path)
            destination = exact.get(source, source)
            current_path = root.joinpath(*destination.parts)
            if destination not in current_publishable or not current_path.is_file():
                if source in exact:
                    raise LayoutError(f"moved repair target is missing: {destination}")
                continue
            try:
                base_text = base_path.read_text(encoding="utf-8")
                current_text = current_path.read_text(encoding="utf-8")
            except UnicodeDecodeError as error:
                raise LayoutError(f"Markdown is not UTF-8 during repair: {destination}") from error
            protected_before = (
                _protected_request_body(current_text, destination)
                if destination.name == REQUEST_FILE
                else None
            )
            link_replacements = _base_link_replacements(
                base_text,
                source,
                destination,
                snapshot_root,
                root,
                exact,
                prefixes,
            )
            updated, replacement_count = _apply_proven_link_replacements(
                current_text,
                destination,
                link_replacements,
            )
            if protected_before is not None and _protected_request_body(updated, destination) != protected_before:
                raise LayoutError(f"repair would modify protected request text: {destination}")
            if updated != current_text:
                prepared[destination] = PreparedFile(
                    destination,
                    updated.encode("utf-8"),
                    stat.S_IMODE(current_path.stat().st_mode),
                )
                semantic_files.add(destination)
                semantic_links += replacement_count

        requests = _canonical_requests(root)
        ordered = sorted(requests)
        request_texts: dict[str, str] = {}
        labels: dict[str, str] = {}
        for stem in ordered:
            relative = canonical_request_path(stem)
            path = root / relative
            current_data = prepared[relative].data if relative in prepared else path.read_bytes()
            try:
                current_text = current_data.decode("utf-8")
            except UnicodeDecodeError as error:
                raise LayoutError(f"request is not UTF-8 during repair: {relative}") from error
            request_texts[stem] = current_text
            labels[stem] = _request_heading_label(current_text, stem)
        for position, stem in enumerate(ordered):
            relative = canonical_request_path(stem)
            path = root / relative
            current_text = request_texts[stem]
            current_data = current_text.encode("utf-8")
            protected_before = _protected_request_body(current_text, relative)
            updated = _replace_navigation(
                current_text,
                ordered[position - 1] if position else None,
                ordered[position + 1] if position + 1 < len(ordered) else None,
                labels,
            )
            if _protected_request_body(updated, relative) != protected_before:
                raise LayoutError(f"navigation repair would modify protected request text: {relative}")
            if updated.encode("utf-8") != current_data:
                prepared[relative] = PreparedFile(
                    relative,
                    updated.encode("utf-8"),
                    stat.S_IMODE(path.stat().st_mode),
                )
                navigation_files.add(relative)

    ordered_prepared = sorted(prepared.values(), key=lambda item: item.path.as_posix())
    summary = {
        "schema_version": SCHEMA_VERSION,
        "base_revision": revision,
        "migration_moves": len(moves),
        "semantic_links": semantic_links,
        "semantic_files": len(semantic_files),
        "navigation_files": len(navigation_files),
        "files": [
            {
                "path": item.path.as_posix(),
                "before_sha256": hashlib.sha256(
                    root.joinpath(*item.path.parts).read_bytes()
                ).hexdigest(),
                "after_sha256": hashlib.sha256(item.data).hexdigest(),
            }
            for item in ordered_prepared
        ],
    }
    return ordered_prepared, summary


def plan_repair(repo_root: Path, base_revision: str) -> dict[str, Any]:
    _prepared, summary = _prepare_repair(repo_root, base_revision)
    return {**summary, "mode": "repair-plan"}


def repair_layout(repo_root: Path, base_revision: str) -> dict[str, Any]:
    prepared, summary = _prepare_repair(repo_root, base_revision)
    if prepared:
        _apply_prepared_transaction(repo_root.resolve(), prepared)
    return {
        **summary,
        "mode": "repair",
        "written_files": len(prepared),
        "idempotent": not prepared,
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="mode", required=True)
    for mode in ("plan", "apply", "validate"):
        command = commands.add_parser(mode)
        command.add_argument("--repo-root", type=Path, required=True)
    reindex = commands.add_parser("reindex")
    reindex.add_argument("--repo-root", type=Path, required=True)
    reindex.add_argument("--baseline-markdown")
    start = commands.add_parser("start")
    start.add_argument("--repo-root", type=Path, required=True)
    start.add_argument("--session-stem", required=True)
    start.add_argument("--label", required=True)
    start.add_argument("--title", required=True)
    start.add_argument("--codex-thread-id", required=True)
    start.add_argument("--messages-json", required=True)
    for mode in ("repair-plan", "repair"):
        repair = commands.add_parser(mode)
        repair.add_argument("--repo-root", type=Path, required=True)
        repair.add_argument("--base-revision", required=True)
    return parser


def _load_messages(argument: str) -> list[str]:
    try:
        text = sys.stdin.read() if argument == "-" else Path(argument).read_text(encoding="utf-8")
        payload = json.loads(text)
    except (OSError, json.JSONDecodeError) as error:
        raise LayoutError(f"cannot read messages JSON: {error}") from error
    if not isinstance(payload, list) or not all(isinstance(item, str) for item in payload):
        raise LayoutError("messages JSON must be an array of strings")
    return payload


def _load_optional_markdown(argument: str | None) -> str | None:
    if argument is None:
        return None
    try:
        return sys.stdin.read() if argument == "-" else Path(argument).read_text(encoding="utf-8")
    except OSError as error:
        raise LayoutError(f"cannot read baseline Markdown: {error}") from error


def _emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))


def main(argv: Sequence[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        root = arguments.repo_root.resolve()
        if arguments.mode == "plan":
            _emit(build_plan(root))
        elif arguments.mode == "apply":
            plan = build_plan(root)
            _emit(apply_plan(root, plan))
        elif arguments.mode == "validate":
            _emit(validate_layout(root))
        elif arguments.mode == "reindex":
            _emit(reindex_journal(root, _load_optional_markdown(arguments.baseline_markdown)))
        elif arguments.mode == "start":
            _emit(
                start_session(
                    root,
                    arguments.session_stem,
                    arguments.label,
                    arguments.title,
                    arguments.codex_thread_id,
                    _load_messages(arguments.messages_json),
                )
            )
        elif arguments.mode == "repair-plan":
            _emit(plan_repair(root, arguments.base_revision))
        else:
            _emit(repair_layout(root, arguments.base_revision))
    except LayoutError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
