#!/usr/bin/env python3
"""Select project Markdown files without reading ignored service directories."""

from __future__ import annotations

import os
import re
import stat
import subprocess
from pathlib import Path, PurePosixPath, PureWindowsPath


STRUCTURAL_EXCLUDED_DIRECTORY_NAMES = frozenset(
    {
        ".git",
        ".build",
        ".swiftpm",
        ".cache",
        "cache",
        "caches",
        "__pycache__",
        ".pytest_cache",
        ".mypy_cache",
        ".ruff_cache",
    }
)
CACHE_DIRECTORY_SUFFIXES = ("-cache", "_cache", ".cache")
STRUCTURAL_EXCLUDED_PATH_PREFIXES = (
    (".obsidian", "plugins"),
    (".obsidian", "themes"),
)


class ProjectFilesError(RuntimeError):
    """Raised when a Git-backed project inventory cannot be proven."""


HOME_PATH_PREFIX_RE = re.compile(
    r"(?i)^(?:"
    r"~[^/\\]*(?:[/\\]|$)|"
    r"\$(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)(?:[/\\]|$)|"
    r"\$\{(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)\}(?:[/\\]|$)|"
    r"%(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)%(?:[/\\]|$)|"
    r"\$env:(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)(?:[/\\]|$)"
    r")"
)
URI_PREFIX_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*://")


def is_excluded_directory_name(name: str) -> bool:
    folded = name.casefold()
    return (
        folded in STRUCTURAL_EXCLUDED_DIRECTORY_NAMES
        or folded.endswith(CACHE_DIRECTORY_SUFFIXES)
    )


def _directory_parts_are_excluded(parts: tuple[str, ...]) -> bool:
    folded = tuple(part.casefold() for part in parts)
    return any(is_excluded_directory_name(part) for part in folded) or any(
        folded[: len(prefix)] == prefix
        for prefix in STRUCTURAL_EXCLUDED_PATH_PREFIXES
    )


def is_structurally_excluded(relative_path: str | Path) -> bool:
    relative = Path(relative_path)
    return _directory_parts_are_excluded(relative.parts[:-1])


def _lexical_absolute(path: str | Path, repo_root: Path) -> Path:
    candidate = Path(path)
    if not candidate.is_absolute():
        candidate = repo_root / candidate
    return Path(os.path.abspath(os.fspath(candidate)))


def path_uses_symlink_component(path: str | Path, repo_root: str | Path) -> bool:
    root = Path(repo_root).resolve()
    candidate = _lexical_absolute(path, root)
    try:
        relative = candidate.relative_to(root)
    except ValueError as exc:
        raise ProjectFilesError(f"path escapes repository root: {candidate}") from exc

    current = root
    for part in relative.parts:
        current /= part
        try:
            mode = current.lstat().st_mode
        except FileNotFoundError:
            return False
        except OSError as exc:
            raise ProjectFilesError(f"cannot inspect path component {current}: {exc}") from exc
        if stat.S_ISLNK(mode):
            return True
    return False


def normalized_project_relative_path(
    value: object,
    repo_root: str | Path,
    *,
    field_name: str = "path",
    must_exist: bool = False,
) -> str:
    """Return an exact portable repository-relative path or fail closed."""

    if not isinstance(value, str) or not value or value != value.strip():
        raise ProjectFilesError(
            f"{field_name}: expected a non-empty path without edge whitespace"
        )
    if "\x00" in value:
        raise ProjectFilesError(f"{field_name}: NUL is forbidden")
    if URI_PREFIX_RE.match(value):
        raise ProjectFilesError(f"{field_name}: URI is not a project path")
    if HOME_PATH_PREFIX_RE.match(value):
        raise ProjectFilesError(
            f"{field_name}: home-relative and home-variable paths are forbidden"
        )
    if "\\" in value:
        raise ProjectFilesError(
            f"{field_name}: backslashes are not portable project separators"
        )

    windows_path = PureWindowsPath(value)
    if windows_path.drive or windows_path.is_absolute():
        raise ProjectFilesError(
            f"{field_name}: Windows drive and UNC paths are forbidden"
        )

    relative = PurePosixPath(value)
    if relative.is_absolute():
        raise ProjectFilesError(f"{field_name}: absolute paths are forbidden")
    if value != relative.as_posix() or any(
        part in {"", ".", ".."} for part in relative.parts
    ):
        raise ProjectFilesError(
            f"{field_name}: path must be normalized and stay inside the repository"
        )
    if not relative.parts:
        raise ProjectFilesError(f"{field_name}: empty project path is forbidden")
    if is_structurally_excluded(relative):
        raise ProjectFilesError(
            f"{field_name}: structurally excluded project path is forbidden"
        )

    root = Path(repo_root).resolve()
    candidate = root.joinpath(*relative.parts)
    if path_uses_symlink_component(candidate, root):
        raise ProjectFilesError(f"{field_name}: symlink path component is forbidden")
    try:
        resolved = candidate.resolve(strict=False)
        resolved.relative_to(root)
    except (OSError, ValueError) as exc:
        raise ProjectFilesError(
            f"{field_name}: path escapes the repository"
        ) from exc

    try:
        mode = candidate.lstat().st_mode
    except FileNotFoundError:
        if must_exist:
            raise ProjectFilesError(f"{field_name}: project file does not exist")
    except OSError as exc:
        raise ProjectFilesError(
            f"{field_name}: cannot inspect project path"
        ) from exc
    else:
        if not stat.S_ISREG(mode):
            raise ProjectFilesError(f"{field_name}: project path is not a regular file")

    return relative.as_posix()


def is_structurally_excluded_path(path: str | Path, repo_root: str | Path) -> bool:
    root = Path(repo_root).resolve()
    candidate = _lexical_absolute(path, root)
    try:
        lexical_relative = candidate.relative_to(root)
    except ValueError:
        return False
    if is_structurally_excluded(lexical_relative):
        return True
    try:
        resolved_relative = candidate.resolve().relative_to(root)
    except ValueError:
        return False
    return is_structurally_excluded(resolved_relative)


def safe_project_output_path(path: str | Path, repo_root: str | Path) -> Path:
    lexical_root = Path(os.path.abspath(os.fspath(repo_root)))
    root = lexical_root.resolve()
    lexical_candidate = _lexical_absolute(path, lexical_root)
    try:
        lexical_relative = lexical_candidate.relative_to(lexical_root)
    except ValueError:
        try:
            lexical_relative = lexical_candidate.resolve(strict=False).relative_to(root)
        except (OSError, ValueError) as exc:
            raise ProjectFilesError(
                f"project output path escapes repository: {lexical_candidate}"
            ) from exc
    candidate = root / lexical_relative

    if is_structurally_excluded(lexical_relative):
        raise ProjectFilesError(
            f"project output path is structurally excluded: {lexical_relative.as_posix()}"
        )
    if path_uses_symlink_component(candidate, root):
        raise ProjectFilesError(
            f"project output path uses a symlink: {lexical_relative.as_posix()}"
        )

    try:
        resolved = candidate.resolve(strict=False)
        resolved_relative = resolved.relative_to(root)
    except (OSError, ValueError) as exc:
        raise ProjectFilesError(f"cannot resolve project output path {candidate}: {exc}") from exc
    if is_structurally_excluded(resolved_relative):
        raise ProjectFilesError(
            f"project output path resolves into excluded storage: {resolved_relative.as_posix()}"
        )

    try:
        mode = candidate.lstat().st_mode
    except FileNotFoundError:
        return candidate
    except OSError as exc:
        raise ProjectFilesError(f"cannot inspect project output path {candidate}: {exc}") from exc
    if not stat.S_ISREG(mode):
        raise ProjectFilesError(
            f"project output path is not a regular file: {lexical_relative.as_posix()}"
        )
    return candidate


def _decode_nul_paths(data: bytes) -> list[str]:
    return [os.fsdecode(value) for value in data.split(b"\0") if value]


def _run_git(
    repo_root: Path,
    arguments: list[str],
) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo_root), *arguments],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        details = os.fsdecode(result.stderr).strip() or "unknown Git error"
        raise ProjectFilesError(f"{' '.join(arguments)} failed: {details}")
    return result.stdout


def _git_markdown_relpaths(repo_root: Path) -> tuple[list[Path], set[Path]]:
    tracked_output = _run_git(
        repo_root,
        [
            "-c",
            "core.quotepath=false",
            "ls-files",
            "--cached",
            "-z",
        ],
    )
    untracked_output = _run_git(
        repo_root,
        [
            "-c",
            "core.quotepath=false",
            "ls-files",
            "--others",
            "--exclude-standard",
            "-z",
        ],
    )
    tracked_values = _decode_nul_paths(tracked_output)
    candidate_values = dict.fromkeys(
        [
            *tracked_values,
            *_decode_nul_paths(untracked_output),
        ]
    )
    candidates = [
        Path(value)
        for value in candidate_values
        if Path(value).suffix == ".md"
        and not is_structurally_excluded(value)
    ]
    tracked = {
        Path(value)
        for value in tracked_values
        if Path(value).suffix == ".md"
        and not is_structurally_excluded(value)
    }
    return candidates, tracked


def _git_status_for_path(repo_root: Path, relative: Path) -> bytes:
    return _run_git(
        repo_root,
        [
            "-c",
            "core.quotepath=false",
            "status",
            "--short",
            "--untracked-files=all",
            "--",
            relative.as_posix(),
        ],
    )


def _filesystem_markdown_relpaths(repo_root: Path) -> list[Path]:
    relative_paths: list[Path] = []

    def raise_walk_error(error: OSError) -> None:
        raise ProjectFilesError(f"cannot walk project files: {error}") from error

    for current, directory_names, file_names in os.walk(
        repo_root,
        topdown=True,
        onerror=raise_walk_error,
        followlinks=False,
    ):
        current_path = Path(current)
        directory_names[:] = sorted(
            name
            for name in directory_names
            if not _directory_parts_are_excluded(
                (current_path / name).relative_to(repo_root).parts
            )
            and not (current_path / name).is_symlink()
        )
        for name in sorted(file_names):
            if not name.endswith(".md"):
                continue
            candidate = current_path / name
            relative_paths.append(candidate.relative_to(repo_root))
    return relative_paths


def project_markdown_paths(
    repo_root: str | Path,
    *,
    use_git: bool | None = None,
) -> list[Path]:
    """Return tracked and new non-ignored Markdown files under one policy."""

    root = Path(repo_root).resolve()
    git_available = (root / ".git").exists()
    if use_git is True and not git_available:
        raise ProjectFilesError(f"repository has no .git entry: {root}")
    should_use_git = git_available if use_git is None else use_git and git_available
    if should_use_git:
        relative_paths, tracked_paths = _git_markdown_relpaths(root)
    else:
        relative_paths = _filesystem_markdown_relpaths(root)
        tracked_paths = set()

    paths: set[Path] = set()
    for relative in relative_paths:
        candidate = root / relative
        if path_uses_symlink_component(candidate, root):
            raise ProjectFilesError(
                f"project Markdown path uses a symlink: {relative.as_posix()}"
            )
        try:
            mode = candidate.lstat().st_mode
        except FileNotFoundError:
            if relative in tracked_paths and not _git_status_for_path(root, relative).strip():
                raise ProjectFilesError(
                    "tracked Markdown is absent without a visible Git deletion: "
                    f"{relative.as_posix()}"
                )
            continue
        except OSError as exc:
            raise ProjectFilesError(f"cannot inspect project Markdown {candidate}: {exc}") from exc
        if not stat.S_ISREG(mode):
            continue
        try:
            resolved = candidate.resolve(strict=True)
        except OSError as exc:
            raise ProjectFilesError(f"cannot resolve project Markdown {candidate}: {exc}") from exc
        try:
            resolved_relative = resolved.relative_to(root)
        except ValueError:
            raise ProjectFilesError(f"project Markdown escapes repository: {relative.as_posix()}")
        if is_structurally_excluded(resolved_relative):
            raise ProjectFilesError(
                f"project Markdown resolves into excluded storage: {relative.as_posix()}"
            )
        paths.add(resolved)
    return sorted(paths)
