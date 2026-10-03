#!/usr/bin/env python3
"""Материализует и проверяет внешнюю Git-зависимость FUM через управляемый форк."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Sequence
from urllib.parse import urlsplit


REVISION_PATTERN = re.compile(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})\Z")
GITHUB_SCP_PATTERN = re.compile(
    r"(?:[^@]+@)?github\.com:(?P<owner>[^/]+)/(?P<name>[^/]+?)(?:\.git)?\Z"
)
ПРОБРАСЫВАТЬ_ОШИБКИ_ЧТЕНИЯ = False
КОД_ДОПУСКА_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


@dataclass(frozen=True)
class DependencySpec:
    fork_url: str
    upstream_url: str
    path: str
    revision: str


@dataclass(frozen=True)
class GitResult:
    returncode: int
    stdout: str
    stderr: str


@dataclass(frozen=True)
class RepositoryLocation:
    kind: str
    namespace: str
    name: str


def run_git(
    cwd: Path,
    *arguments: str,
    allowed_returncodes: tuple[int, ...] = (0,),
    strip_output: bool = True,
) -> GitResult:
    try:
        result = subprocess.run(
            ["git", "--no-replace-objects", "--no-optional-locks", "--no-lazy-fetch",
             "-c", f"core.hooksPath={os.devnull}", "-c", "core.fsmonitor=false",
             "-c", "core.filemode=true", "-c", "submodule.recurse=false",
             "-c", "fetch.recurseSubmodules=false", *arguments],
            cwd=cwd,
            env={**{ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith("GIT_")},
                 "GIT_NO_LAZY_FETCH": "1"},
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=120,
        )
    except (OSError, subprocess.TimeoutExpired, UnicodeError) as error:
        raise RuntimeError(f"git {' '.join(arguments)}: {error}") from error
    if result.returncode not in allowed_returncodes:
        detail = result.stderr.strip() or result.stdout.strip() or "без диагностики"
        raise RuntimeError(
            f"git {' '.join(arguments)} завершился с кодом "
            f"{result.returncode}: {detail}"
        )
    return GitResult(
        returncode=result.returncode,
        stdout=result.stdout.strip() if strip_output else result.stdout,
        stderr=result.stderr.strip(),
    )


def validate_spec(spec: DependencySpec) -> list[str]:
    errors: list[str] = []
    if not spec.fork_url.strip():
        errors.append("URL форка не задан")
    if not spec.upstream_url.strip():
        errors.append("URL upstream не задан")
    if spec.fork_url == spec.upstream_url and spec.fork_url:
        errors.append("URL форка и upstream должны быть различными")

    errors.extend(validate_dependency_path(spec.path))
    if REVISION_PATTERN.fullmatch(spec.revision) is None:
        errors.append("ревизия должна быть полным 40- или 64-символьным Git OID")
    return errors


def validate_dependency_path(path_value: str) -> list[str]:
    path = PurePosixPath(path_value)
    if (
        not path_value
        or path_value != path_value.strip()
        or path.is_absolute()
        or path_value.startswith("-")
        or "\\" in path_value
        or any(part in {"", ".", "..", ".git"} for part in path.parts)
    ):
        return [
            "путь зависимости должен быть безопасным относительным Git-путём "
            "без '.', '..', '.git' и обратных косых черт"
        ]
    return []


def read_nul_config_values(
    cwd: Path,
    *arguments: str,
) -> tuple[list[str] | None, list[str]]:
    try:
        result = run_git(
            cwd,
            "config",
            "-z",
            *arguments,
            allowed_returncodes=(0, 1),
            strip_output=False,
        )
    except RuntimeError as error:
        return None, [f"не удалось прочитать Git-конфигурацию: {error}"]
    if result.returncode == 1:
        return [], []
    if not result.stdout.endswith("\0"):
        return None, ["Git-конфигурация вернула некорректный NUL-формат"]
    return result.stdout[:-1].split("\0"), []


def dependency_path(repo_root: Path, spec: DependencySpec) -> Path:
    posix_path = PurePosixPath(spec.path)
    return repo_root.joinpath(*posix_path.parts)


def expected_submodule_git_directory(
    repo_root: Path,
    path: str,
    section: str,
) -> tuple[Path | None, list[str]]:
    prefix = "submodule."
    if not section.startswith(prefix):
        return None, [f"{path}: некорректное имя раздела submodule {section!r}"]
    name = section.removeprefix(prefix)
    name_path = PurePosixPath(name)
    if (
        not name
        or name_path.is_absolute()
        or name.startswith("-")
        or "\\" in name
        or any(part in {"", ".", "..", ".git"} for part in name_path.parts)
    ):
        return None, [f"{path}: небезопасное имя submodule {name!r}"]
    try:
        superproject_git_dir = Path(
            run_git(repo_root, "rev-parse", "--absolute-git-dir").stdout
        ).resolve()
    except RuntimeError as error:
        return None, [
            f"{path}: не удалось определить Git-каталог superproject: {error}"
        ]
    expected_git_dir = superproject_git_dir.joinpath("modules", *name_path.parts)
    current = superproject_git_dir
    for component in ("modules", *name_path.parts):
        current = current / component
        if current.is_symlink():
            return None, [
                f"{path}: Git-каталог submodule не должен проходить через "
                f"символическую ссылку {current}"
            ]
        if current.exists() and not current.is_dir():
            return None, [f"{path}: компонент Git-каталога должен быть каталогом: {current}"]
    modules_root = (superproject_git_dir / "modules").resolve()
    expected_git_dir = expected_git_dir.resolve()
    try:
        expected_git_dir.relative_to(modules_root)
    except ValueError:
        return None, [
            f"{path}: Git-каталог submodule выходит за пределы {modules_root}"
        ]
    return expected_git_dir, []


def validate_submodule_git_directory(
    repo_root: Path,
    dependency: Path,
    path: str,
    section: str,
) -> list[str]:
    expected_git_dir, errors = expected_submodule_git_directory(
        repo_root,
        path,
        section,
    )
    if expected_git_dir is None or errors:
        return errors
    try:
        dependency_git_dir = Path(
            run_git(dependency, "rev-parse", "--absolute-git-dir").stdout
        ).resolve()
        dependency_common_dir = Path(
            run_git(
                dependency,
                "rev-parse",
                "--path-format=absolute",
                "--git-common-dir",
            ).stdout
        ).resolve()
    except RuntimeError as error:
        return [f"{path}: не удалось проверить Git-каталог submodule: {error}"]
    if (
        dependency_git_dir != expected_git_dir
        or dependency_common_dir != expected_git_dir
    ):
        return [
            f"{path}: Git-каталог submodule должен быть {expected_git_dir}, "
            f"получены git-dir {dependency_git_dir} и common-dir "
            f"{dependency_common_dir}"
        ]
    return []


def validate_dependency_worktree_location(
    repo_root: Path,
    dependency: Path,
    path: str,
) -> list[str]:
    current = repo_root
    for component in PurePosixPath(path).parts:
        current = current / component
        if current.is_symlink():
            return [
                f"{path}: путь зависимости не должен проходить через "
                f"символическую ссылку {current}"
            ]
        if current.exists() and not current.is_dir():
            return [
                f"{path}: существующий компонент пути зависимости должен "
                f"быть каталогом: {current}"
            ]
    resolved_dependency = dependency.resolve()
    try:
        resolved_dependency.relative_to(repo_root)
    except ValueError:
        return [f"{path}: путь зависимости выходит за пределы superproject"]
    if resolved_dependency != dependency.absolute():
        return [
            f"{path}: путь зависимости не должен проходить через "
            "символические ссылки"
        ]
    return []


def validate_repo_root(repo_root: Path) -> list[str]:
    try:
        actual = run_git(repo_root, "rev-parse", "--show-toplevel").stdout
    except RuntimeError as error:
        return [f"корень FUM не является Git-репозиторием: {error}"]
    if Path(actual).resolve() != repo_root.resolve():
        return [
            f"--repo-root должен указывать на корень Git-репозитория: {actual}"
        ]
    return []


def parse_repository_location(
    url: str,
) -> tuple[RepositoryLocation | None, list[str]]:
    scp_match = GITHUB_SCP_PATTERN.fullmatch(url)
    if scp_match is not None:
        return RepositoryLocation(
            kind="github",
            namespace=scp_match.group("owner"),
            name=scp_match.group("name"),
        ), []

    parsed = urlsplit(url)
    if parsed.scheme:
        if (
            parsed.scheme in {"https", "ssh"}
            and parsed.hostname == "github.com"
            and parsed.query == ""
            and parsed.fragment == ""
        ):
            parts = [part for part in parsed.path.split("/") if part]
            if len(parts) == 2:
                name = parts[1].removesuffix(".git")
                if name:
                    return RepositoryLocation(
                        kind="github",
                        namespace=parts[0],
                        name=name,
                    ), []
        return None, [f"неподдерживаемый или неоднозначный Git URL: {url!r}"]

    local_path = Path(url)
    if not local_path.is_absolute():
        return None, [
            f"локальный Git URL должен быть абсолютным путём: {url!r}"
        ]
    name = local_path.name.removesuffix(".git")
    if not name:
        return None, [f"Git URL не содержит имени репозитория: {url!r}"]
    return RepositoryLocation(
        kind="local",
        namespace=str(local_path.parent.resolve()),
        name=name,
    ), []


def validate_public_github_https_url(url: str, role: str) -> list[str]:
    parsed = urlsplit(url)
    try:
        port = parsed.port
    except ValueError:
        port = -1
    path_parts = parsed.path.split("/")
    valid_path = (
        len(path_parts) == 3
        and path_parts[0] == ""
        and bool(path_parts[1])
        and bool(path_parts[2].removesuffix(".git"))
    )
    if (
        parsed.scheme != "https"
        or parsed.hostname != "github.com"
        or port is not None
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or not valid_path
    ):
        return [
            f"URL {role} должен быть публичным HTTPS URL GitHub "
            "без учётных данных, порта, query и fragment"
        ]
    return []


def normalized_github_location(location: RepositoryLocation) -> tuple[str, str]:
    return location.namespace.casefold(), location.name.casefold()


def validate_repository_topology(repo_root: Path, spec: DependencySpec) -> list[str]:
    errors: list[str] = []
    try:
        fum_origin_url = run_git(
            repo_root,
            "remote",
            "get-url",
            "origin",
        ).stdout
    except RuntimeError as error:
        return [
            "не удалось определить актуальный GitHub-владелец FUM по remote origin: "
            f"{error}"
        ]

    fum_origin, location_errors = parse_repository_location(fum_origin_url)
    errors.extend(location_errors)
    fork, location_errors = parse_repository_location(spec.fork_url)
    errors.extend(location_errors)
    upstream, location_errors = parse_repository_location(spec.upstream_url)
    errors.extend(location_errors)
    if fum_origin is None or fork is None or upstream is None:
        return errors

    if fum_origin.kind != fork.kind:
        errors.append(
            "форк зависимости и актуальный origin FUM должны использовать "
            "один тип Git-расположения"
        )
    elif (
        fum_origin.namespace.casefold() != fork.namespace.casefold()
        if fork.kind == "github"
        else fum_origin.namespace != fork.namespace
    ):
        errors.append(
            "форк зависимости должен находиться рядом с актуальным "
            f"репозиторием FUM у владельца {fum_origin.namespace!r}"
        )
    if fork.kind != upstream.kind:
        errors.append("форк и upstream должны использовать один тип Git-расположения")
    if fork.kind == upstream.kind == "github":
        if normalized_github_location(fork) == normalized_github_location(upstream):
            errors.append(
                "форк и upstream не должны обозначать один GitHub-репозиторий"
            )
        if fork.namespace.casefold() == upstream.namespace.casefold():
            errors.append("владельцы GitHub-форка и upstream должны быть различными")
    if fork.kind == "github":
        errors.extend(validate_public_github_https_url(spec.fork_url, "форка"))
    if upstream.kind == "github":
        errors.extend(
            validate_public_github_https_url(spec.upstream_url, "upstream")
        )
    return errors


def find_submodule_section(repo_root: Path, path: str) -> tuple[str | None, list[str]]:
    gitmodules = repo_root / ".gitmodules"
    if not gitmodules.is_file():
        return None, [".gitmodules отсутствует"]
    try:
        result = run_git(
            repo_root,
            "config",
            "-z",
            "-f",
            ".gitmodules",
            "--get-regexp",
            r"^submodule\..*\.path$",
            allowed_returncodes=(0, 1),
            strip_output=False,
        )
    except RuntimeError as error:
        return None, [f"не удалось прочитать .gitmodules: {error}"]

    path_values_by_section: dict[str, list[str]] = {}
    if result.returncode == 0:
        if not result.stdout.endswith("\0"):
            return None, [".gitmodules вернул некорректный NUL-формат"]
        for record in result.stdout[:-1].split("\0"):
            key, separator, value = record.partition("\n")
            if not separator or not key.endswith(".path"):
                return None, [".gitmodules содержит некорректную запись path"]
            section = key.removesuffix(".path")
            path_values_by_section.setdefault(section, []).append(value)
    matches = [
        section
        for section, values in path_values_by_section.items()
        if path in values
    ]
    if len(matches) != 1:
        return None, [
            f".gitmodules должен содержать ровно одну запись path = {path!r}"
        ]
    section = matches[0]
    values = path_values_by_section[section]
    if values != [path]:
        return None, [
            f".gitmodules должен содержать ровно одно значение "
            f"{section}.path = {path!r}, получено {values!r}"
        ]
    return section, []


def read_single_gitmodules_value(
    repo_root: Path,
    section: str,
    name: str,
) -> tuple[str | None, list[str]]:
    values, config_errors = read_nul_config_values(
        repo_root,
        "-f",
        ".gitmodules",
        "--get-all",
        f"{section}.{name}",
    )
    if config_errors or values is None:
        return None, [
            f"не удалось прочитать {section}.{name}: {error}"
            for error in config_errors
        ]
    if len(values) != 1 or not values[0]:
        return None, [
            f".gitmodules должен содержать ровно одно непустое значение "
            f"{section}.{name}, получено {values!r}"
        ]
    return values[0], []


def read_index_gitlink_revision(
    repo_root: Path,
    path: str,
) -> tuple[str | None, list[str]]:
    try:
        result = run_git(
            repo_root,
            "--literal-pathspecs",
            "ls-files",
            "--stage",
            "-z",
            "--",
            path,
            strip_output=False,
        )
    except RuntimeError as error:
        return None, [f"{path}: не удалось прочитать gitlink: {error}"]
    lines = [line for line in result.stdout.split("\0") if line]
    if len(lines) != 1:
        return None, [f"{path}: ожидается ровно один gitlink в индексе"]
    metadata, separator, имя_записи = lines[0].partition("\t")
    fields = metadata.split()
    if not separator or len(fields) != 3 or имя_записи != path:
        return None, [f"{path}: некорректная запись gitlink"]
    mode, revision, stage = fields
    errors: list[str] = []
    if mode != "160000" or stage != "0":
        errors.append(f"{path}: ожидается gitlink mode 160000 stage 0")
    if REVISION_PATTERN.fullmatch(revision) is None:
        errors.append(f"{path}: gitlink не содержит полный Git OID")
    return (revision if not errors else None), errors


def remote_revision_is_reachable(
    dependency: Path,
    revision: str,
    remote: str,
) -> tuple[bool, list[str]]:
    try:
        refs_result = run_git(
            dependency,
            "for-each-ref",
            "--format=%(refname)",
            f"refs/remotes/{remote}",
        )
    except RuntimeError as error:
        return False, [f"не удалось прочитать refs remote {remote}: {error}"]
    refs = [value for value in refs_result.stdout.splitlines() if value]
    if not refs:
        return False, [f"remote {remote} не имеет локально полученных веток"]

    for ref in refs:
        try:
            result = run_git(
                dependency,
                "merge-base",
                "--is-ancestor",
                revision,
                ref,
                allowed_returncodes=(0, 1),
            )
        except RuntimeError as error:
            return False, [
                f"не удалось проверить достижимость {revision} из {ref}: {error}"
            ]
        if result.returncode == 0:
            return True, []
    return False, []


def validate_remote_urls(
    dependency: Path,
    dependency_label: str,
    remote: str,
    expected_url: str,
) -> list[str]:
    errors: list[str] = []
    for direction, arguments in (
        ("fetch", ("remote", "get-url", "--all", remote)),
        ("push", ("remote", "get-url", "--push", "--all", remote)),
    ):
        try:
            result = run_git(dependency, *arguments)
        except RuntimeError as error:
            errors.append(
                f"{dependency_label}: remote {remote} {direction} URL недоступен: "
                f"{error}"
            )
            continue
        urls = [url for url in result.stdout.splitlines() if url]
        if urls != [expected_url]:
            errors.append(
                f"{dependency_label}: remote {remote} {direction} URL должен "
                f"быть единственным {expected_url!r}, получено {urls!r}"
            )
    return errors


def validate_remote_fetch_refspec(
    dependency: Path,
    dependency_label: str,
    remote: str,
) -> list[str]:
    refspecs, config_errors = read_nul_config_values(
        dependency,
        "--get-all",
        f"remote.{remote}.fetch",
    )
    if config_errors or refspecs is None:
        return [
            f"{dependency_label}: не удалось прочитать fetch refspec remote "
            f"{remote}: {error}"
            for error in config_errors
        ]
    expected = [f"+refs/heads/*:refs/remotes/{remote}/*"]
    if refspecs != expected:
        return [
            f"{dependency_label}: remote {remote} fetch refspec должен быть "
            f"единственным {expected[0]!r}, получено {refspecs!r}"
        ]
    return []


def validate_remote_has_tracking_refs(
    dependency: Path,
    dependency_label: str,
    remote: str,
) -> list[str]:
    try:
        result = run_git(
            dependency,
            "for-each-ref",
            "--format=%(refname)",
            f"refs/remotes/{remote}",
        )
    except RuntimeError as error:
        return [
            f"{dependency_label}: не удалось прочитать refs remote {remote}: "
            f"{error}"
        ]
    if not [value for value in result.stdout.splitlines() if value]:
        return [
            f"{dependency_label}: remote {remote} не имеет локально полученных "
            "веток"
        ]
    return []


def validate_gitmodules_before_add(repo_root: Path) -> list[str]:
    gitmodules = repo_root / ".gitmodules"
    indexed = run_git(
        repo_root,
        "ls-files",
        "--error-unmatch",
        "--",
        ".gitmodules",
        allowed_returncodes=(0, 1),
    ).returncode == 0
    in_worktree = gitmodules.exists() or gitmodules.is_symlink()
    if indexed != in_worktree:
        return [
            "предшествующее состояние .gitmodules различается между "
            "Git-индексом и рабочим деревом"
        ]
    if not indexed:
        return []
    if not gitmodules.is_file() or gitmodules.is_symlink():
        return [
            ".gitmodules должен быть обычным отслеживаемым файлом без "
            "символической ссылки"
        ]
    difference = run_git(
        repo_root,
        "diff",
        "--quiet",
        "--no-ext-diff",
        "--",
        ".gitmodules",
        allowed_returncodes=(0, 1),
    )
    if difference.returncode == 1:
        return [
            "предшествующее состояние .gitmodules различается между "
            "Git-индексом и рабочим деревом"
        ]
    try:
        gitmodules.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        if ПРОБРАСЫВАТЬ_ОШИБКИ_ЧТЕНИЯ:
            raise
        return [f".gitmodules должен быть доступным UTF-8-файлом: {error}"]
    return []


def registered_dependency_spec(
    repo_root: Path,
    path: str,
) -> tuple[DependencySpec | None, list[str]]:
    repo_root = repo_root.resolve()
    errors = validate_dependency_path(path)
    errors.extend(validate_repo_root(repo_root))
    if errors:
        return None, errors
    errors.extend(validate_gitmodules_before_add(repo_root))
    if errors:
        return None, errors

    section, section_errors = find_submodule_section(repo_root, path)
    errors.extend(section_errors)
    if section is None:
        return None, errors
    fork_url, value_errors = read_single_gitmodules_value(
        repo_root,
        section,
        "url",
    )
    errors.extend(value_errors)
    upstream_url, value_errors = read_single_gitmodules_value(
        repo_root,
        section,
        "fumUpstream",
    )
    errors.extend(value_errors)
    branch_result = run_git(
        repo_root,
        "config",
        "-f",
        ".gitmodules",
        "--get-all",
        f"{section}.branch",
        allowed_returncodes=(0, 1),
    )
    if branch_result.returncode == 0:
        errors.append(f"{path}: .gitmodules не должен задавать следование ветке")
    revision, gitlink_errors = read_index_gitlink_revision(repo_root, path)
    errors.extend(gitlink_errors)
    if errors or fork_url is None or upstream_url is None or revision is None:
        return None, errors

    spec = DependencySpec(
        fork_url=fork_url,
        upstream_url=upstream_url,
        path=path,
        revision=revision.lower(),
    )
    errors.extend(validate_spec(spec))
    errors.extend(validate_repository_topology(repo_root, spec))
    if errors:
        return None, errors
    return spec, []


def проверить_флаги_индекса(корень: Path, путь: str) -> list[str]:
    """Читать каждый флаг до status, fetch или checkout."""
    записи = run_git(корень, "ls-files", "-v", "-z", strip_output=False).stdout
    if any(запись and not запись.startswith("H ") for запись in записи.split("\0")):
        return [f"{путь}: скрывающие изменения флаги индекса запрещены"]
    return []


def validate_dependency(repo_root: Path, spec: DependencySpec) -> list[str]:
    repo_root = repo_root.resolve()
    errors = validate_spec(spec)
    errors.extend(validate_repo_root(repo_root))
    if errors:
        return errors
    errors.extend(validate_repository_topology(repo_root, spec))
    errors.extend(validate_gitmodules_before_add(repo_root))

    section, section_errors = find_submodule_section(repo_root, spec.path)
    errors.extend(section_errors)
    if section is not None:
        configured_url, value_errors = read_single_gitmodules_value(
            repo_root,
            section,
            "url",
        )
        errors.extend(value_errors)
        if configured_url is not None and configured_url != spec.fork_url:
            errors.append(
                ".gitmodules должен использовать URL форка "
                f"{spec.fork_url!r}, получено {configured_url!r}"
            )
        configured_upstream, value_errors = read_single_gitmodules_value(
            repo_root,
            section,
            "fumUpstream",
        )
        errors.extend(value_errors)
        if (
            configured_upstream is not None
            and configured_upstream != spec.upstream_url
        ):
            errors.append(
                ".gitmodules fumUpstream должен быть "
                f"{spec.upstream_url!r}, получено {configured_upstream!r}"
            )
        branch_result = run_git(
            repo_root,
            "config",
            "-f",
            ".gitmodules",
            "--get",
            f"{section}.branch",
            allowed_returncodes=(0, 1),
        )
        if branch_result.returncode == 0:
            errors.append(
                f"{spec.path}: .gitmodules не должен задавать следование ветке"
            )

    try:
        indexed_gitmodules = run_git(
            repo_root,
            "show",
            ":.gitmodules",
        ).stdout
    except RuntimeError as error:
        errors.append(f".gitmodules отсутствует в Git-индексе: {error}")
    else:
        try:
            working_gitmodules = (repo_root / ".gitmodules").read_text(
                encoding="utf-8"
            ).strip()
        except (OSError, UnicodeError) as error:
            if ПРОБРАСЫВАТЬ_ОШИБКИ_ЧТЕНИЯ:
                raise
            errors.append(f"не удалось прочитать рабочую .gitmodules как UTF-8: {error}")
        else:
            if indexed_gitmodules != working_gitmodules:
                errors.append(
                    "рабочая .gitmodules не совпадает с записью в Git-индексе"
                )

    dependency = dependency_path(repo_root, spec)
    if not dependency.is_dir():
        errors.append(f"{spec.path}: каталог зависимости отсутствует")
        return errors
    location_errors = validate_dependency_worktree_location(
        repo_root,
        dependency,
        spec.path,
    )
    if location_errors:
        errors.extend(location_errors)
        return errors
    try:
        dependency_root = run_git(
            dependency,
            "rev-parse",
            "--show-toplevel",
        ).stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не является Git-клоном: {error}")
        return errors
    topology_errors = []
    if Path(dependency_root).resolve() != dependency.resolve():
        topology_errors.append(f"{spec.path}: Git-корень зависимости не совпадает с путём")
    git_marker = dependency / ".git"
    if not git_marker.is_file() or git_marker.is_symlink():
        topology_errors.append(
            f"{spec.path}: submodule должен использовать связанный .git-файл "
            "без символической ссылки"
        )
    if section is not None:
        topology_errors.extend(
            validate_submodule_git_directory(
                repo_root,
                dependency,
                spec.path,
                section,
            )
        )
    if topology_errors:
        return errors + topology_errors
    errors.extend(проверить_флаги_индекса(dependency, spec.path))
    try:
        superproject = run_git(
            dependency,
            "rev-parse",
            "--show-superproject-working-tree",
        ).stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось подтвердить связь с superproject: {error}")
    else:
        if not superproject:
            errors.append(f"{spec.path}: Git не подтвердил связь с superproject")
        elif Path(superproject).resolve() != repo_root:
            errors.append(f"{spec.path}: клон не связан с текущим superproject")

    errors.extend(
        validate_remote_urls(
            dependency,
            spec.path,
            "origin",
            spec.fork_url,
        )
    )
    errors.extend(
        validate_remote_fetch_refspec(
            dependency,
            spec.path,
            "origin",
        )
    )
    errors.extend(
        validate_remote_urls(
            dependency,
            spec.path,
            "upstream",
            spec.upstream_url,
        )
    )
    errors.extend(
        validate_remote_fetch_refspec(
            dependency,
            spec.path,
            "upstream",
        )
    )
    errors.extend(
        validate_remote_has_tracking_refs(
            dependency,
            spec.path,
            "upstream",
        )
    )
    try:
        remotes = set(run_git(dependency, "remote").stdout.splitlines())
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось прочитать список remote: {error}")
    else:
        if remotes != {"origin", "upstream"}:
            errors.append(
                f"{spec.path}: ожидаются только remote origin и upstream, "
                f"получено {sorted(remotes)!r}"
            )

    try:
        head = run_git(dependency, "rev-parse", "HEAD").stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось прочитать HEAD: {error}")
        head = None
    if head is not None and head != spec.revision:
        errors.append(
            f"{spec.path}: HEAD должен быть {spec.revision}, получено {head}"
        )
    symbolic_head = run_git(
        dependency,
        "symbolic-ref",
        "-q",
        "HEAD",
        allowed_returncodes=(0, 1),
    )
    if symbolic_head.returncode == 0:
        errors.append(f"{spec.path}: HEAD должен быть detached, а не веткой")
    try:
        shallow = run_git(
            dependency,
            "rev-parse",
            "--is-shallow-repository",
        ).stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось проверить shallow-состояние: {error}")
    else:
        if shallow != "false":
            errors.append(f"{spec.path}: shallow-клон не допускается")
    try:
        status = run_git(dependency, "status", "--porcelain=v1").stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось проверить чистоту: {error}")
    else:
        if status:
            errors.append(f"{spec.path}: локальный клон не чист")

    try:
        object_result = run_git(
            dependency,
            "cat-file",
            "-e",
            f"{spec.revision}^{{commit}}",
            allowed_returncodes=(0, 1),
        )
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось проверить ревизию: {error}")
        revision_exists = False
    else:
        revision_exists = object_result.returncode == 0
        if not revision_exists:
            errors.append(f"{spec.path}: ревизия {spec.revision} отсутствует")
    if revision_exists:
        reachable, reachability_errors = remote_revision_is_reachable(
            dependency,
            spec.revision,
            "origin",
        )
        errors.extend(reachability_errors)
        if not reachable and not reachability_errors:
            errors.append(
                f"{spec.path}: ревизия {spec.revision} не достижима из origin"
            )

    gitlink_revision, gitlink_errors = read_index_gitlink_revision(
        repo_root,
        spec.path,
    )
    errors.extend(gitlink_errors)
    if gitlink_revision is not None and gitlink_revision != spec.revision:
        errors.append(
            f"{spec.path}: gitlink должен быть {spec.revision}, "
            f"получено {gitlink_revision}"
        )
    return errors


def validate_initialization_target(
    repo_root: Path,
    spec: DependencySpec,
    section: str,
) -> list[str]:
    dependency = dependency_path(repo_root, spec)
    errors: list[str] = []
    if not dependency.is_dir():
        return [f"{spec.path}: каталог зависимости отсутствует"]
    location_errors = validate_dependency_worktree_location(
        repo_root,
        dependency,
        spec.path,
    )
    if location_errors:
        return location_errors
    try:
        dependency_root = run_git(
            dependency,
            "rev-parse",
            "--show-toplevel",
        ).stdout
    except RuntimeError as error:
        return [f"{spec.path}: не является Git-клоном: {error}"]
    if Path(dependency_root).resolve() != dependency.resolve():
        errors.append(f"{spec.path}: Git-корень зависимости не совпадает с путём")
    git_marker = dependency / ".git"
    if not git_marker.is_file() or git_marker.is_symlink():
        errors.append(
            f"{spec.path}: submodule должен использовать связанный .git-файл "
            "без символической ссылки"
        )
    errors.extend(
        validate_submodule_git_directory(
            repo_root,
            dependency,
            spec.path,
            section,
        )
    )
    errors.extend(проверить_флаги_индекса(dependency, spec.path))
    try:
        superproject = run_git(
            dependency,
            "rev-parse",
            "--show-superproject-working-tree",
        ).stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось подтвердить связь с superproject: {error}")
    else:
        if not superproject:
            errors.append(f"{spec.path}: Git не подтвердил связь с superproject")
        elif Path(superproject).resolve() != repo_root:
            errors.append(f"{spec.path}: клон не связан с текущим superproject")
    try:
        shallow = run_git(
            dependency,
            "rev-parse",
            "--is-shallow-repository",
        ).stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось проверить shallow-состояние: {error}")
    else:
        if shallow != "false":
            errors.append(f"{spec.path}: shallow-клон не допускается")
    try:
        status = run_git(dependency, "status", "--porcelain=v1").stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось проверить чистоту: {error}")
    else:
        if status:
            errors.append(f"{spec.path}: локальный клон не чист")

    try:
        remotes = set(run_git(dependency, "remote").stdout.splitlines())
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось прочитать список remote: {error}")
        return errors
    if not {"origin"}.issubset(remotes) or not remotes.issubset(
        {"origin", "upstream"}
    ):
        errors.append(
            f"{spec.path}: до инициализации допускаются только remote origin "
            f"и точный upstream, получено {sorted(remotes)!r}"
        )
        return errors
    errors.extend(
        validate_remote_urls(
            dependency,
            spec.path,
            "origin",
            spec.fork_url,
        )
    )
    errors.extend(
        validate_remote_fetch_refspec(
            dependency,
            spec.path,
            "origin",
        )
    )
    if "upstream" in remotes:
        errors.extend(
            validate_remote_urls(
                dependency,
                spec.path,
                "upstream",
                spec.upstream_url,
            )
        )
        errors.extend(
            validate_remote_fetch_refspec(
                dependency,
                spec.path,
                "upstream",
            )
        )
    return errors


def initialize_registered_dependency(
    repo_root: Path,
    path: str,
    *,
    перед_эффектом=None,
) -> tuple[DependencySpec | None, list[str]]:
    repo_root = repo_root.resolve()
    spec, errors = registered_dependency_spec(repo_root, path)
    if spec is None or errors:
        return None, errors

    section, section_errors = find_submodule_section(repo_root, spec.path)
    if section is None or section_errors:
        return spec, section_errors or [f"{spec.path}: запись submodule не найдена"]

    expected_module_git_dir, module_git_dir_errors = expected_submodule_git_directory(
        repo_root,
        spec.path,
        section,
    )
    if module_git_dir_errors:
        return spec, module_git_dir_errors

    dependency = dependency_path(repo_root, spec)
    location_errors = validate_dependency_worktree_location(
        repo_root,
        dependency,
        spec.path,
    )
    if location_errors:
        return spec, location_errors
    initialized = (dependency / ".git").is_file()
    if not initialized:
        if expected_module_git_dir is not None and (
            expected_module_git_dir.exists()
            or expected_module_git_dir.is_symlink()
        ):
            return spec, [
                f"{spec.path}: остаточный Git-каталог нематериализованного "
                f"submodule должен отсутствовать: {expected_module_git_dir}"
            ]
        local_urls, config_errors = read_nul_config_values(
            repo_root,
            "--get-all",
            f"{section}.url",
        )
        if config_errors or local_urls is None:
            return spec, [
                f"{spec.path}: не удалось проверить локальный URL submodule: "
                f"{error}"
                for error in config_errors
            ]
        if local_urls not in ([], [spec.fork_url]):
            return spec, [
                f"{spec.path}: локальный URL submodule должен быть единственным "
                f"{spec.fork_url!r}, получено {local_urls!r}"
            ]
        if dependency.exists() or dependency.is_symlink():
            if dependency.is_symlink() or not dependency.is_dir():
                return None, [
                    f"{spec.path}: путь нематериализованного submodule занят"
                ]
            if any(dependency.iterdir()):
                return None, [
                    f"{spec.path}: каталог нематериализованного submodule не пуст"
                ]
        try:
            if перед_эффектом is not None:
                перед_эффектом("материализация")
            run_git(
                repo_root,
                "-c",
                "protocol.file.allow=always",
                "-c",
                f"{section}.url={spec.fork_url}",
                "-c",
                f"{section}.active=true",
                "submodule",
                "update",
                "--checkout",
                "--no-recommend-shallow",
                "--",
                spec.path,
            )
        except RuntimeError as error:
            return spec, [
                f"не удалось материализовать зарегистрированный submodule "
                f"{spec.path}: {error}"
            ]

    errors = validate_initialization_target(repo_root, spec, section)
    if errors:
        return spec, errors
    dependency = dependency_path(repo_root, spec)
    try:
        remotes = set(run_git(dependency, "remote").stdout.splitlines())
    except RuntimeError as error:
        return spec, [
            f"{spec.path}: не удалось повторно прочитать список remote: {error}"
        ]
    if "upstream" not in remotes:
        try:
            if перед_эффектом is not None:
                перед_эффектом("добавление_источника_оригинала")
            run_git(
                dependency,
                "remote",
                "add",
                "upstream",
                spec.upstream_url,
            )
        except RuntimeError as error:
            return spec, [
                f"{spec.path}: не удалось восстановить remote upstream: {error}"
            ]

    try:
        if перед_эффектом is not None:
            перед_эффектом("получение_форка")
        run_git(dependency, "fetch", "--prune", "origin")
        if перед_эффектом is not None:
            перед_эффектом("получение_оригинала")
        run_git(dependency, "fetch", "--prune", "upstream")
    except RuntimeError as error:
        return spec, [f"не удалось получить remote для {spec.path}: {error}"]
    try:
        if перед_эффектом is not None:
            перед_эффектом("выбор_ревизии")
        run_git(
            dependency,
            "checkout",
            "--detach",
            "--no-overwrite-ignore",
            spec.revision,
        )
    except RuntimeError as error:
        return spec, [
            f"{spec.path}: не удалось безопасно выбрать gitlink без "
            f"перезаписи игнорируемого или другого локального состояния: {error}"
        ]
    return spec, validate_dependency(repo_root, spec)


def preflight_dependency(spec: DependencySpec, *, перед_эффектом=None) -> list[str]:
    if перед_эффектом is not None:
        перед_эффектом()
    with tempfile.TemporaryDirectory(prefix="fum-git-dependency-") as tmp:
        temporary_root = Path(tmp).resolve()
        clone = temporary_root / "dependency"
        try:
            if перед_эффектом is not None:
                перед_эффектом()
            run_git(
                temporary_root,
                "-c",
                "protocol.file.allow=always",
                "clone",
                "--origin",
                "origin",
                "--no-checkout",
                "--no-local",
                "--no-hardlinks",
                "--",
                spec.fork_url,
                str(clone),
            )
            run_git(clone, "remote", "add", "upstream", spec.upstream_url)
            if перед_эффектом is not None:
                перед_эффектом()
            for удалённый, адрес in (('origin', spec.fork_url), ('upstream', spec.upstream_url)):
                ошибки_источника = validate_remote_urls(clone, spec.path, удалённый, адрес)
                ошибки_источника += validate_remote_fetch_refspec(clone, spec.path, удалённый)
                if ошибки_источника:
                    raise RuntimeError('; '.join(ошибки_источника))
            run_git(clone, "fetch", "origin")
            if перед_эффектом is not None:
                перед_эффектом()
            ошибки_источника = validate_remote_urls(clone, spec.path, 'upstream', spec.upstream_url)
            ошибки_источника += validate_remote_fetch_refspec(clone, spec.path, 'upstream')
            if ошибки_источника:
                raise RuntimeError('; '.join(ошибки_источника))
            run_git(clone, "fetch", "upstream")
            object_result = run_git(
                clone,
                "cat-file",
                "-e",
                f"{spec.revision}^{{commit}}",
                allowed_returncodes=(0, 1),
            )
        except RuntimeError as error:
            return [f"предварительная проверка зависимости не прошла: {error}"]
        if object_result.returncode != 0:
            return [f"ревизия {spec.revision} отсутствует в доступных источниках"]
        reachable, reachability_errors = remote_revision_is_reachable(
            clone,
            spec.revision,
            "origin",
        )
        if reachability_errors:
            return reachability_errors
        if not reachable:
            return [f"ревизия {spec.revision} не достижима из origin форка"]
    return []


def разобрать_предварительный_допуск(байты):
    def пары(значения):
        результат = dict(значения)
        if len(результат) != len(значения):
            raise RuntimeError('повтор ключа предварительного допуска')
        return результат

    def константа(значение):
        raise RuntimeError('нечисловая константа предварительного допуска: ' + значение)

    return json.loads(байты, object_pairs_hook=пары, parse_constant=константа)


def загрузить_подготовку_для_допуска(ожидаемый_хэш):
    путь = Path(__file__).with_name('подготовка_зависимостей.py')
    байты = прочитать_закреплённые_байты({'путь': str(путь), 'хэш_байтов': ожидаемый_хэш})
    имя = 'подготовка_допуска_' + uuid.uuid4().hex
    описание = importlib.util.spec_from_file_location(имя, путь)
    if описание is None or описание.loader is None:
        raise RuntimeError('недоступен неизменённый helper подготовки')
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[имя] = модуль
    exec(compile(байты, str(путь), 'exec'), модуль.__dict__)
    if модуль.ОТПЕЧАТОК_КОДА[путь.name] != ожидаемый_хэш:
        raise RuntimeError('исходник подготовки изменился при свежей загрузке')
    прочитать_закреплённые_байты({'путь': str(путь), 'хэш_байтов': ожидаемый_хэш})
    return модуль


def прочитать_закреплённые_байты(ссылка):
    if (type(ссылка) is not dict or set(ссылка) != {'путь', 'хэш_байтов'}
            or type(ссылка['путь']) is not str or type(ссылка['хэш_байтов']) is not str
            or re.fullmatch('[0-9a-f]{64}', ссылка['хэш_байтов']) is None):
        raise RuntimeError('нужны закрытая ссылка на файл и независимо закреплённый SHA-256')
    путь = Path(ссылка['путь'])
    if not путь.is_absolute() or путь.resolve() != путь or not путь.is_file() or путь.is_symlink():
        raise RuntimeError('вход должен быть физическим абсолютным обычным файлом')
    свойства = путь.stat()
    if свойства.st_uid != os.geteuid() or свойства.st_mode & 0o022:
        raise RuntimeError('вход имеет чужого владельца или допускает чужую запись')
    with путь.open('rb') as поток:
        до = os.fstat(поток.fileno())
        if до.st_size > 134217728:
            raise RuntimeError('вход превышает объявленную границу 128 MiB')
        байты = поток.read()
        после = os.fstat(поток.fileno())
    if (до.st_dev, до.st_ino, до.st_size, до.st_mtime_ns, до.st_ctime_ns) != (
            после.st_dev, после.st_ino, после.st_size, после.st_mtime_ns, после.st_ctime_ns):
        raise RuntimeError('вход изменился во время чтения')
    if hashlib.sha256(байты).hexdigest() != ссылка['хэш_байтов']:
        raise RuntimeError('сырые байты входа не совпадают с независимо выбранным SHA-256')
    if путь.stat() != после:
        raise RuntimeError('файл заменён после чтения')
    return байты


def снимок_защищённого_пути(путь, *, исключить=()):
    """Читает байты, ссылки и метаданные, не следуя ссылкам каталогов."""
    путь = Path(путь)
    if not os.path.lexists(путь):
        return None
    результат = {}
    очередь = [путь]
    while очередь:
        текущий = очередь.pop()
        имя = текущий.relative_to(путь).as_posix()
        if имя != '.' and текущий.relative_to(путь).parts[0] in исключить:
            continue
        до = текущий.lstat()
        запись = {'режим': stat.S_IMODE(до.st_mode), 'устройство': до.st_dev,
                  'номер_узла': до.st_ino, 'изменён': до.st_mtime_ns}
        if stat.S_ISLNK(до.st_mode):
            запись['вид'], запись['ссылка'] = 'ссылка', os.readlink(текущий)
        elif stat.S_ISREG(до.st_mode):
            запись['вид'] = 'файл'
            вычисление = hashlib.sha256()
            with текущий.open('rb') as поток:
                for блок in iter(lambda: поток.read(1048576), b''):
                    вычисление.update(блок)
            запись['байты'] = вычисление.hexdigest()
        elif stat.S_ISDIR(до.st_mode):
            запись['вид'] = 'каталог'
            # Изменение mtime родителя при записи только своего Gitdir ожидаемо.
            запись.pop('изменён')
            очередь.extend(sorted(текущий.iterdir(), reverse=True))
        else:
            raise RuntimeError('неподдержанный защищаемый объект: ' + str(текущий))
        после = текущий.lstat()
        if not stat.S_ISDIR(до.st_mode) and (
                до.st_dev, до.st_ino, до.st_mode, до.st_size, до.st_mtime_ns, до.st_ctime_ns) != (
                после.st_dev, после.st_ino, после.st_mode, после.st_size, после.st_mtime_ns, после.st_ctime_ns):
            raise RuntimeError('защищаемый объект изменился при чтении')
        результат[имя] = запись
    return результат


def диагноз_дерева(корень, ссылка, каталог, причина):
    return RuntimeError(f'ранний допуск дерева: корень={корень}; ref={ссылка}; '
                        f'admin={каталог}; причина={причина}')


def метаданные_физического_каталога(путь):
    """Закрепляет идентичность компонентов, не обходя рабочие файлы."""
    if not путь.is_absolute():
        raise RuntimeError('каталог должен иметь абсолютный физический путь')
    результат = []
    for компонент in (*reversed(путь.parents), путь):
        свойства = компонент.lstat()
        if not stat.S_ISDIR(свойства.st_mode):
            raise RuntimeError('отсутствует обычный каталог либо обнаружена ссылка: ' + str(компонент))
        результат.append((str(компонент), свойства.st_dev, свойства.st_ino, свойства.st_mode))
    if путь.resolve() != путь:
        raise RuntimeError('нефизический путь каталога: ' + str(путь))
    return tuple(результат)


def физический_маршрут_указателя(путь):
    """Проверяет сырые компоненты, в том числе исчезающие после '..'."""
    if not путь.is_absolute():
        raise RuntimeError('нужен абсолютный служебный указатель')
    текущий = Path(путь.anchor)
    результат = []
    for имя in ('.', *путь.parts[1:]):
        if имя == '..':
            текущий = текущий.parent
        elif имя != '.':
            текущий = текущий / имя
        свойства = текущий.lstat()
        if not stat.S_ISDIR(свойства.st_mode):
            raise RuntimeError('нефизический компонент служебного указателя: ' + str(текущий))
        результат.append((str(текущий), свойства.st_dev, свойства.st_ino, свойства.st_mode))
    return текущий, tuple(результат)


def прочитать_метаданные_регистрации(путь):
    def признаки(свойства):
        return (свойства.st_dev, свойства.st_ino, свойства.st_mode, свойства.st_size,
                свойства.st_mtime_ns, свойства.st_ctime_ns)

    метаданные_физического_каталога(путь.parent)
    до = путь.lstat()
    if not stat.S_ISREG(до.st_mode) or до.st_size > 65536:
        raise RuntimeError('нужен обычный файл метаданных не больше 64 КиБ: ' + str(путь))
    with путь.open('rb') as поток:
        if признаки(os.fstat(поток.fileno())) != признаки(до):
            raise RuntimeError('файл метаданных подменён перед чтением: ' + str(путь))
        байты = поток.read(65537)
        после = os.fstat(поток.fileno())
    if признаки(после) != признаки(до) or признаки(путь.lstat()) != признаки(до):
        raise RuntimeError('файл метаданных изменился при чтении: ' + str(путь))
    текст = байты.decode('utf-8').removesuffix('\n')
    if not текст or '\n' in текст or '\r' in текст or '\0' in текст:
        raise RuntimeError('неоднозначные метаданные: ' + str(путь))
    return текст, признаки(до)


def метаданные_одного_дерева(дерево, запись, общий, обратный):
    каталог = обратный
    try:
        if not os.path.lexists(дерево):
            raise RuntimeError('рабочий корень отсутствует')
        идентичность = метаданные_физического_каталога(дерево)
        маркер = дерево / '.git'
        свойства = маркер.lstat()
        if stat.S_ISDIR(свойства.st_mode):
            каталог = маркер
            указатель = None
            маршрут_указателя = None
            if каталог != общий or обратный != 'неизвестен' and обратный != общий:
                raise RuntimeError('обычный Git-каталог не совпадает с общей регистрацией')
        else:
            указатель = прочитать_метаданные_регистрации(маркер)
            if not указатель[0].startswith('gitdir: '):
                raise RuntimeError('неверный прямой указатель .git')
            прямой = Path(указатель[0].removeprefix('gitdir: '))
            if not прямой.is_absolute():
                прямой = дерево / прямой
            прямой_каталог, маршрут_указателя = физический_маршрут_указателя(прямой)
            каталог = прямой_каталог
            if каталог == общий or обратный != каталог:
                raise RuntimeError('прямая и обратная регистрации не совпадают')
        административные = метаданные_физического_каталога(каталог)
        связность = обратный_указатель = маршрут_связности = None
        if каталог != общий:
            обратный_указатель = прочитать_метаданные_регистрации(каталог / 'gitdir')
            if обратный_указатель[0] != str(маркер):
                raise RuntimeError('обратный указатель gitdir не совпадает с корнем')
            связность = прочитать_метаданные_регистрации(каталог / 'commondir')
            общий_указатель = Path(связность[0])
            if not общий_указатель.is_absolute():
                общий_указатель = каталог / общий_указатель
            общий_каталог, маршрут_связности = физический_маршрут_указателя(общий_указатель)
            if общий_каталог != общий:
                raise RuntimeError('commondir указывает в другую Git-базу')
        голова = прочитать_метаданные_регистрации(каталог / 'HEAD')
        ожидаемая = запись['голова'] if запись['ссылка'] == 'detached' else 'ref: ' + запись['ссылка']
        if голова[0] != ожидаемая:
            raise RuntimeError('HEAD/ref не совпадают с перечнем')
        return {'ссылка': запись['ссылка'], 'голова': запись['голова'], 'каталог': каталог,
            'идентичность': идентичность, 'административные': административные,
            'указатель': указатель, 'обратный_указатель': обратный_указатель,
            'связность': связность, 'голова_файл': голова,
            'маршрут_указателя': маршрут_указателя, 'маршрут_связности': маршрут_связности}
    except (OSError, UnicodeError, RuntimeError) as ошибка:
        raise диагноз_дерева(дерево, запись['ссылка'], каталог, str(ошибка)) from ошибка


def метаданные_зарегистрированных_деревьев(корень, общий, перечень):
    """Полный ранний проход; читаются только указатели и служебный HEAD."""
    записи = {}
    for блок in перечень.split('\n\n'):
        строки = блок.splitlines()
        if not строки or not строки[0].startswith('worktree '):
            raise RuntimeError('неполный перечень рабочих деревьев')
        дерево = Path(строки[0].removeprefix('worktree '))
        ссылки = [строка.removeprefix('branch ') for строка in строки if строка.startswith('branch ')]
        головы = [строка.removeprefix('HEAD ') for строка in строки if строка.startswith('HEAD ')]
        ссылка = ссылки[0] if len(ссылки) == 1 else 'detached' if 'detached' in строки else 'неизвестен'
        if (дерево in записи or 'bare' in строки or len(головы) != 1
                or not REVISION_PATTERN.fullmatch(головы[0])
                or not (len(ссылки) == 1 and ссылки[0].startswith('refs/') and 'detached' not in строки
                        or not ссылки and строки.count('detached') == 1)):
            raise диагноз_дерева(дерево, ссылка, 'неизвестен', 'неоднозначная регистрация')
        записи[дерево] = {'ссылка': ссылка, 'голова': головы[0]}
    if корень not in записи:
        raise диагноз_дерева(корень, 'неизвестен', 'неизвестен', 'собственное дерево отсутствует в перечне')

    обратные = {}
    служебные = {}
    родитель = общий / 'worktrees'
    имена = ()
    if os.path.lexists(родитель):
        метаданные_физического_каталога(родитель)
        имена = tuple(sorted(путь.name for путь in родитель.iterdir()))
        for имя in имена:
            каталог = родитель / имя
            дерево, ссылка = 'неизвестен', 'неизвестен'
            try:
                идентичность = метаданные_физического_каталога(каталог)
                указатель = прочитать_метаданные_регистрации(каталог / 'gitdir')
                маркер = Path(указатель[0])
                if not маркер.is_absolute() or маркер.name != '.git':
                    raise RuntimeError('неоднозначный обратный указатель gitdir')
                дерево = маркер.parent
                ссылка = записи.get(дерево, {}).get('ссылка', 'неизвестен')
                if дерево not in записи:
                    raise RuntimeError('обратная регистрация отсутствует в перечне Git')
                if дерево in обратные:
                    raise RuntimeError('неоднозначная обратная регистрация; другой admin=' + str(обратные[дерево]))
                обратные[дерево] = каталог
                служебные[str(каталог)] = (идентичность, указатель)
            except (OSError, UnicodeError, RuntimeError) as ошибка:
                raise диагноз_дерева(дерево, ссылка, каталог, str(ошибка)) from ошибка

    результат = {}
    for дерево, запись in записи.items():
        результат[дерево] = метаданные_одного_дерева(
            дерево, запись, общий, обратные.get(дерево, 'неизвестен'))
    return результат, служебные, имена


def снять_защищённое_состояние(корень, *, новый_путь=None):
    """Самостоятельный читающий producer; checked add его вход не создаёт."""
    корень = Path(корень)
    if корень.resolve() != корень:
        raise RuntimeError('нужен физический корень защиты')
    собственный = Path(run_git(корень, 'rev-parse', '--absolute-git-dir').stdout)
    общий = Path(run_git(корень, 'rev-parse', '--path-format=absolute', '--git-common-dir').stdout)
    перечень = run_git(корень, 'worktree', 'list', '--porcelain').stdout
    метаданные = метаданные_зарегистрированных_деревьев(корень, общий, перечень)

    def сверить_метаданные():
        свежий = run_git(корень, 'worktree', 'list', '--porcelain').stdout
        if свежий != перечень:
            raise диагноз_дерева(корень, метаданные[0][корень]['ссылка'], собственный,
                                  'перечень регистраций изменился')
        текущие = метаданные_зарегистрированных_деревьев(корень, общий, свежий)
        if текущие != метаданные:
            for дерево, запись in метаданные[0].items():
                if текущие[0].get(дерево) != запись:
                    raise диагноз_дерева(дерево, запись['ссылка'], запись['каталог'],
                                          'root, маркер или admin подменён после раннего прохода')
            raise диагноз_дерева(корень, метаданные[0][корень]['ссылка'], собственный,
                                  'обратные регистрации подменены после раннего прохода')

    сверить_метаданные()

    def сверить_дерево(дерево, запись):
        текущая = метаданные_одного_дерева(дерево, запись, общий, запись['каталог'])
        if текущая != запись:
            raise диагноз_дерева(дерево, запись['ссылка'], запись['каталог'],
                                  'root, маркер или admin подменён после раннего прохода')

    деревья = {}
    for дерево, запись in метаданные[0].items():
        if дерево == корень:
            continue
        сверить_дерево(дерево, запись)
        try:
            каталог = Path(run_git(дерево, 'rev-parse', '--absolute-git-dir').stdout)
            if каталог != запись['каталог']:
                raise RuntimeError('Git-каталог перенаправлен в ' + str(каталог))
            деревья[str(дерево)] = {
                'рабочие_байты': снимок_защищённого_пути(дерево, исключить=('.git',)),
                'маркер': снимок_защищённого_пути(дерево / '.git') if (дерево / '.git').is_file() else None,
                'гит_каталог': str(каталог),
                'административные_байты': снимок_защищённого_пути(каталог) if каталог != общий else None,
            }
        except (OSError, UnicodeError, RuntimeError) as ошибка:
            raise диагноз_дерева(дерево, запись['ссылка'], запись['каталог'], str(ошибка)) from ошибка
        сверить_дерево(дерево, запись)
    собственные_копии = {}
    инвентарь = run_git(корень, 'ls-files', '--stage', '-v', '-z', strip_output=False).stdout
    for строка in инвентарь.split('\0')[:-1]:
        сведения, путь = строка.split('\t', 1)
        if сведения.startswith('H 160000 ') and сведения.endswith(' 0') and путь != новый_путь:
            раздел, ошибки = find_submodule_section(корень, путь)
            if ошибки or раздел is None:
                raise RuntimeError('неоднозначное описание прежней защищаемой копии')
            каталог, ошибки = expected_submodule_git_directory(корень, путь, раздел)
            if ошибки or каталог is None:
                raise RuntimeError('небезопасный каталог прежней защищаемой копии')
            собственные_копии[путь] = {'рабочие_байты': снимок_защищённого_пути(корень / путь),
                                     'административные_байты': снимок_защищённого_пути(каталог)}
    результат = {'схема': 'fum.защищённые-области-добавления.1', 'перечень_деревьев': перечень,
        'общий_гит_каталог': str(общий), 'собственный_гит_каталог': str(собственный),
        'общие_области': {имя: снимок_защищённого_пути(общий / имя)
                          for имя in ('config', 'config.worktree', 'index', 'HEAD', 'refs', 'packed-refs', 'modules')},
        'ссылки': run_git(корень, 'for-each-ref', '--format=%(refname) %(objectname)').stdout,
        'чужие_деревья': деревья, 'собственные_готовые_копии': собственные_копии}
    сверить_метаданные()
    return результат


def подготовить_описание_добавления(прежние_байты, описание):
    def значение(текст):
        if any(ord(символ) < 32 or ord(символ) == 127 for символ in текст):
            raise RuntimeError('управляющий символ в контракте регистрации')
        return '"' + текст.replace('\\', '\\\\').replace('"', '\\"') + '"'
    прежние_байты.decode('utf-8')
    разделитель = b'\n' if прежние_байты and not прежние_байты.endswith(b'\n') else b''
    запись = (f'[submodule {значение(описание.path)}]\n'
              f'\tpath = {значение(описание.path)}\n'
              f'\turl = {значение(описание.fork_url)}\n'
              f'\tfumUpstream = {значение(описание.upstream_url)}\n').encode()
    return прежние_байты + разделитель + запись


class ДопускДобавления:
    def __init__(сам, корень, описание, файл, ожидаемый_хэш):
        сам.корень, сам.описание = Path(корень), описание
        сам.ссылка = {'путь': str(файл), 'хэш_байтов': ожидаемый_хэш}
        байты_допуска = прочитать_закреплённые_байты(сам.ссылка)
        предварительные = разобрать_предварительный_допуск(байты_допуска)
        сам.подготовка = загрузить_подготовку_для_допуска(
            предварительные['снимок_до']['код']['подготовка_зависимостей.py'])
        сам.данные = сам.подготовка.разобрать_объект(байты_допуска)
        поля = {'схема', 'исполнитель', 'корневая_задача', 'зависимость', 'снимок_до',
                'готовая_квитанция', 'первичные_ответы', 'описание_подмодулей_после', 'защищённое_состояние'}
        if (type(сам.данные) is not dict or set(сам.данные) != поля
                or сам.данные['схема'] != 'fum.допуск-добавления-зависимости.1'):
            raise RuntimeError('неверная закрытая форма допуска добавления')
        ожидаемое = {'адрес_форка': описание.fork_url, 'адрес_оригинала': описание.upstream_url,
                     'путь': описание.path, 'ревизия': описание.revision}
        if сам.данные['зависимость'] != ожидаемое:
            raise RuntimeError('источник, путь или OID не совпадают с независимым выбором')
        сам.до = сам.данные['снимок_до']
        сам.подготовка.исторические_гитлинки(сам.до)
        сам.записи_до = сам.индексные_записи(сам.до)
        if '.gitmodules' in сам.записи_до:
            объект = сам.записи_до['.gitmodules'][1]
            прежние = run_git(сам.корень, 'cat-file', 'blob', объект, strip_output=False).stdout.encode()
        else:
            прежние = b''
        if (hashlib.sha256(прежние).hexdigest() if '.gitmodules' in сам.записи_до else None) != сам.до['описание_подмодулей']:
            raise RuntimeError('исходное описание не подтверждено индексным blob')
        сам.описание_после = прочитать_закреплённые_байты(сам.данные['описание_подмодулей_после'])
        if сам.описание_после != подготовить_описание_добавления(прежние, описание):
            raise RuntimeError('ожидаемое описание не является точным добавлением одной секции')
        алгоритм = run_git(сам.корень, 'rev-parse', '--show-object-format').stdout
        if алгоритм not in ('sha1', 'sha256'):
            raise RuntimeError('неподдержанный формат Git-объектов')
        объект = hashlib.new(алгоритм, b'blob ' + str(len(сам.описание_после)).encode() + b'\0' + сам.описание_после).hexdigest()
        сам.записи_после = сам.записи_до.copy()
        if описание.path in сам.записи_до:
            raise RuntimeError('новый путь уже присутствует в исходном индексе')
        сам.записи_после['.gitmodules'] = (сам.записи_до.get('.gitmodules', ('100644', ''))[0], объект)
        сам.записи_после[описание.path] = ('160000', описание.revision)
        сам.защита = сам.подготовка.разобрать_объект(прочитать_закреплённые_байты(сам.данные['защищённое_состояние']))
        сам.цель = dependency_path(сам.корень, описание)
        сам.каталог, ошибки = expected_submodule_git_directory(сам.корень, описание.path, 'submodule.' + описание.path)
        if ошибки or сам.каталог is None:
            raise RuntimeError('; '.join(ошибки))
        сам.путь_исхода = Path(сам.до['гит_каталог']) / ('fum-добавление-' + hashlib.sha256(описание.path.encode()).hexdigest() + '.json')
        сам.фаза = 'допуск'

    def индексные_записи(сам, снимок):
        сам.подготовка.исторические_гитлинки(снимок)
        результат = {}
        for строка in снимок['инвентарь_индекса'].split('\0')[:-1]:
            сведения, путь = строка.split('\t', 1)
            _, режим, объект, _ = сведения.split()
            результат[путь] = (режим, объект)
        return результат

    def проверить_родство(сам):
        ответы = сам.данные['первичные_ответы']
        if type(ответы) is not dict or set(ответы) != {'форк', 'оригинал'}:
            raise RuntimeError('нужна точная пара независимо выбранных первичных ответов')
        прочитанные = {}
        for роль, адрес in (('форк', сам.описание.fork_url), ('оригинал', сам.описание.upstream_url)):
            расположение, ошибки = parse_repository_location(адрес)
            if ошибки or расположение is None or расположение.kind != 'github':
                raise RuntimeError('мутирующий add требует публичные GitHub URL')
            ссылка = ответы[роль]
            if type(ссылка) is not dict or set(ссылка) != {'путь', 'хэш_байтов', 'адрес'}:
                raise RuntimeError('неверная форма первичного ответа')
            полное_имя = расположение.namespace + '/' + расположение.name
            if ссылка['адрес'] != 'https://api.github.com/repos/' + полное_имя:
                raise RuntimeError('первичный адрес не совпадает с выбранным источником')
            данные = сам.подготовка.разобрать_объект(прочитать_закреплённые_байты({
                ключ: ссылка[ключ] for ключ in ('путь', 'хэш_байтов')}))
            if (type(данные) is not dict or данные.get('full_name') != полное_имя
                    or type(данные.get('id')) is not int or данные['id'] <= 0
                    or данные.get('private') is not False or type(данные.get('fork')) is not bool):
                raise RuntimeError('неполный или противоречивый первичный ответ')
            прочитанные[роль] = данные
        форк, оригинал = прочитанные['форк'], прочитанные['оригинал']
        родитель = форк.get('parent')
        if (форк['fork'] is not True or type(родитель) is not dict
                or type(родитель.get('id')) is not int or родитель['id'] != оригинал['id']
                or родитель.get('full_name') != оригинал['full_name'] or форк['id'] == оригинал['id']):
            raise RuntimeError('не подтверждены fork=true и прямой parent.id/full_name')

    def проверить(сам, *, материализована=False, описание_установлено=False, результат=False):
        if hashlib.sha256(Path(__file__).read_bytes()).hexdigest() != КОД_ДОПУСКА_ПРИ_ЗАГРУЗКЕ:
            raise RuntimeError('исполняемые исходники add изменились')
        сам.подготовка.проверить_код()
        прочитать_закреплённые_байты(сам.ссылка)
        прочитать_закреплённые_байты(сам.данные['описание_подмодулей_после'])
        прочитать_закреплённые_байты(сам.данные['защищённое_состояние'])
        сам.проверить_родство()
        if сам.корень.resolve() != сам.корень or str(сам.корень) != сам.до['корень']:
            raise RuntimeError('чужой или перенаправленный физический корень')
        текущий = сам.подготовка.снять_снимок(сам.корень)
        if (сам.корень / '.gitmodules').exists() and (сам.корень / '.gitmodules').stat().st_nlink != 1:
            raise RuntimeError('общий inode описания через жёсткую ссылку запрещён до эффекта')
        сам.подготовка.проверить_владение(сам.корень, текущий, сам.данные['исполнитель'], сам.данные['корневая_задача'])
        if текущий['гит_каталог'] == текущий['общий_гит_каталог']:
            raise RuntimeError('регистрация требует собственного linked worktree')
        изменяемые = {'индекс', 'инвентарь_индекса', 'описание_подмодулей'}
        if any(текущий[ключ] != сам.до[ключ] for ключ in сам.до if ключ not in изменяемые):
            raise RuntimeError('HEAD/ref, топология, config или код отличаются от выбранного снимка')
        записи = сам.индексные_записи(текущий)
        хэш_описания = hashlib.sha256(сам.описание_после).hexdigest()
        готовый_результат = записи == сам.записи_после and текущий['описание_подмодулей'] == хэш_описания
        исходное = текущий == сам.до
        промежуточное = (описание_установлено and записи == сам.записи_до
                         and текущий['индекс'] == сам.до['индекс']
                         and текущий['описание_подмодулей'] == хэш_описания)
        if not (исходное or промежуточное or готовый_результат):
            raise RuntimeError('снимок не является исходным или точным ожидаемым delta')
        if результат and not готовый_результат:
            raise RuntimeError('конечный двухпутевой delta не подтверждён')
        ошибки = validate_spec(сам.описание) + validate_repository_topology(сам.корень, сам.описание)
        адрес_репозитория = run_git(сам.корень, 'remote', 'get-url', 'origin').stdout
        ошибки += validate_remote_urls(сам.корень, 'FUM', 'origin', адрес_репозитория)
        ошибки += validate_public_github_https_url(адрес_репозитория, 'origin FUM')
        переписывания = run_git(сам.корень, 'config', '--get-regexp',
                               r'^url\..*\.(insteadof|pushinsteadof)$', allowed_returncodes=(0, 1))
        if переписывания.returncode == 0:
            ошибки.append('необъявленная конфигурационная подмена Git URL запрещена')
        ошибки += validate_dependency_worktree_location(сам.корень, сам.цель, сам.описание.path)
        каталог, ошибки_каталога = expected_submodule_git_directory(сам.корень, сам.описание.path, 'submodule.' + сам.описание.path)
        ошибки += ошибки_каталога
        if каталог != сам.каталог:
            ошибки.append('канонический module-путь изменился')
        if ошибки:
            raise RuntimeError('; '.join(ошибки))
        for путь in сам.записи_до:
            if (путь.casefold() == сам.описание.path.casefold()
                    or путь.casefold().startswith(сам.описание.path.casefold() + '/')
                    or сам.описание.path.casefold().startswith(путь.casefold() + '/')):
                raise RuntimeError('новый путь накладывается на исходный индекс')
        if not (материализована or готовый_результат):
            if os.path.lexists(сам.цель) or os.path.lexists(сам.каталог):
                raise RuntimeError('занятый путь или остаточный module-каталог')
        else:
            сам.проверить_материализованную_топологию()
        ссылка = сам.данные['готовая_квитанция']
        if type(ссылка) is not dict or set(ссылка) != {'путь', 'хэш_байтов'}:
            raise RuntimeError('неверная ссылка выбранной подготовки')
        if ссылка['путь'] != str(Path(текущий['гит_каталог']) / 'fum-подготовка-зависимостей-v1.json'):
            raise RuntimeError('выбрана чужая активная квитанция')
        прочитать_закреплённые_байты(ссылка)
        квитанция, _ = сам.подготовка.прочитать_квитанцию(ссылка['путь'])
        сам.подготовка.проверить_цепочку(квитанция, Path(текущий['гит_каталог']), сам.данные['исполнитель'], сам.данные['корневая_задача'])
        if (квитанция['готова'] is not True or any(значение != 'готова' for значение in квитанция['состояния'].values())
                or сам.подготовка.группа_жива(квитанция['группа_процессов'])):
            raise RuntimeError('выбранная подготовка не финализирована или её группа жива')
        for поле in ('корень', 'гит_каталог', 'общий_гит_каталог', 'ссылка'):
            if квитанция['снимок'][поле] != текущий[поле]:
                raise RuntimeError('выбранная подготовка принадлежит иной топологии')
        прежние = сам.подготовка.исторические_гитлинки(квитанция['снимок'])
        текущие = сам.подготовка.исторические_гитлинки(текущий)
        if any(текущие.get(путь) != ревизия for путь, ревизия in прежние.items()):
            raise RuntimeError('историческая готовая зависимость или её OID утрачены')
        if not промежуточное and not сам.подготовка.проверить_зависимости(сам.корень)['готова']:
            raise RuntimeError('весь текущий stage0-инвентарь должен быть готов')
        if снять_защищённое_состояние(сам.корень, новый_путь=сам.описание.path) != сам.защита:
            raise RuntimeError('общие или чужие рабочие/Git-области изменились')
        return готовый_результат

    def проверить_материализованную_топологию(сам):
        маркер = сам.цель / '.git'
        if маркер.is_symlink() or not маркер.is_file():
            raise RuntimeError('у нового клона нужен обычный связанный .git-файл')
        ошибки = validate_submodule_git_directory(сам.корень, сам.цель, сам.описание.path, 'submodule.' + сам.описание.path)
        if ошибки or Path(run_git(сам.цель, 'rev-parse', '--show-toplevel').stdout) != сам.цель:
            raise RuntimeError('; '.join(ошибки) or 'новый клон обнаруживает чужой Git-корень')
        удалённые = run_git(сам.цель, 'remote').stdout.splitlines()
        ожидаемые = ['origin'] if сам.фаза in ('материализация', 'добавление_источника') else ['origin', 'upstream']
        if удалённые != ожидаемые:
            raise RuntimeError('поздняя подмена ролей remote нового клона')
        for удалённый in ожидаемые:
            адрес = сам.описание.fork_url if удалённый == 'origin' else сам.описание.upstream_url
            ошибки = validate_remote_urls(сам.цель, сам.описание.path, удалённый, адрес)
            ошибки += validate_remote_fetch_refspec(сам.цель, сам.описание.path, удалённый)
            if ошибки:
                raise RuntimeError('; '.join(ошибки))

    def сохранить_исход(сам, состояние, *, новый=False):
        данные = {'схема': 'fum.исход-добавления-зависимости.1', 'допуск_sha256': сам.ссылка['хэш_байтов'],
                  'путь': сам.описание.path, 'состояние': состояние, 'фаза': сам.фаза}
        байты = (json.dumps(данные, ensure_ascii=False, sort_keys=True) + '\n').encode()
        путь = сам.путь_исхода if новый else сам.путь_исхода.with_name(сам.путь_исхода.name + '.' + uuid.uuid4().hex + '.tmp')
        дескриптор = os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        with os.fdopen(дескриптор, 'wb') as файл:
            файл.write(байты); файл.flush(); os.fsync(файл.fileno())
        if not новый:
            os.replace(путь, сам.путь_исхода)
        сам.подготовка.синхронизировать_каталог(сам.путь_исхода.parent)

    def проверить_повтор(сам, готовый):
        if not os.path.lexists(сам.путь_исхода):
            if готовый:
                raise RuntimeError('результат существует без собственного завершённого намерения')
            return False
        данные, _ = сам.подготовка.прочитать_квитанцию(сам.путь_исхода)
        if (type(данные) is not dict or set(данные) != {'схема', 'допуск_sha256', 'путь', 'состояние', 'фаза'}
                or данные['схема'] != 'fum.исход-добавления-зависимости.1'
                or данные['допуск_sha256'] != сам.ссылка['хэш_байтов'] or данные['путь'] != сам.описание.path
                or данные['состояние'] != 'готова' or not готовый):
            raise RuntimeError('частичный или неизвестный исход: обычный повтор запрещён')
        return True


def materialize_dependency(repo_root: Path, spec: DependencySpec, *, допуск=None,
                           ожидаемый_хэш_допуска=None) -> list[str]:
    if допуск is None or ожидаемый_хэш_допуска is None:
        return ['add требует явный независимо закреплённый допуск до первого эффекта']
    разрешение = None
    намерение_сохранено = False
    try:
        ошибки = validate_spec(spec) + validate_repo_root(repo_root)
        if not ошибки:
            ошибки += validate_repository_topology(repo_root, spec)
        if ошибки:
            return ошибки
        ошибки = validate_gitmodules_before_add(repo_root)
        if ошибки:
            return ошибки
        разрешение = ДопускДобавления(repo_root, spec, допуск, ожидаемый_хэш_допуска)
        готовый = разрешение.проверить()
        if разрешение.проверить_повтор(готовый):
            намерение_сохранено = True
            ошибки = validate_dependency(repo_root, spec)
            if ошибки:
                raise RuntimeError('; '.join(ошибки))
            разрешение.проверить(материализована=True, результат=True)
            return []
        ошибки = validate_gitmodules_before_add(repo_root)
        if ошибки:
            return ошибки
        разрешение.сохранить_исход('намерение', новый=True)
        намерение_сохранено = True
        разрешение.фаза = 'предварительная_проверка'
        ошибки = preflight_dependency(spec, перед_эффектом=разрешение.проверить)
        if ошибки:
            raise RuntimeError('; '.join(ошибки))
        разрешение.проверить()
        разрешение.фаза = 'материализация'
        разрешение.каталог.parent.mkdir(parents=True, exist_ok=True)
        разрешение.цель.parent.mkdir(parents=True, exist_ok=True)
        разрешение.проверить()
        run_git(repo_root, '-c', 'protocol.file.allow=always', 'clone', '--origin', 'origin',
                '--no-checkout', '--no-local', '--no-hardlinks',
                '--separate-git-dir=' + str(разрешение.каталог), '--', spec.fork_url, str(разрешение.цель))
        разрешение.проверить_материализованную_топологию()
        параметры = ('--git-dir=' + str(разрешение.каталог), '--work-tree=' + str(разрешение.цель))
        for фаза, команда in [('добавление_источника', ('remote', 'add', 'upstream', spec.upstream_url)),
                              ('получение_форка', ('fetch', '--prune', 'origin')),
                              ('получение_оригинала', ('fetch', '--prune', 'upstream')),
                              ('выбор_ревизии', ('checkout', '--detach', '--no-overwrite-ignore', spec.revision))]:
            разрешение.фаза = фаза
            разрешение.проверить(материализована=True)
            run_git(repo_root, *параметры, *команда)
        достижим, ошибки = remote_revision_is_reachable(разрешение.цель, spec.revision, 'origin')
        if ошибки or not достижим:
            raise RuntimeError('; '.join(ошибки) or 'ревизия не достижима из выбранного origin')
        разрешение.фаза = 'описание_подмодулей'
        разрешение.проверить(материализована=True)
        временный = Path(разрешение.до['гит_каталог']) / ('.gitmodules-' + uuid.uuid4().hex + '.tmp')
        дескриптор = os.open(временный, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        with os.fdopen(дескриптор, 'wb') as поток:
            поток.write(разрешение.описание_после); поток.flush()
            os.fchmod(поток.fileno(), 0o755 if разрешение.записи_после['.gitmodules'][0] == '100755' else 0o644)
            os.fsync(поток.fileno())
        разрешение.проверить(материализована=True)
        корневой_дескриптор = os.open(repo_root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            свойства = os.fstat(корневой_дескриптор)
            if (свойства.st_dev, свойства.st_ino) != (Path(repo_root).stat().st_dev, Path(repo_root).stat().st_ino):
                raise RuntimeError('корень заменён перед установкой описания')
            os.replace(временный, '.gitmodules', dst_dir_fd=корневой_дескриптор)
            os.fsync(корневой_дескриптор)
        finally:
            os.close(корневой_дескриптор)
        разрешение.подготовка.синхронизировать_каталог(Path(repo_root))
        разрешение.фаза = 'индекс'
        разрешение.проверить(материализована=True, описание_установлено=True)
        run_git(repo_root, '--literal-pathspecs', 'add', '--', '.gitmodules', spec.path)
        разрешение.фаза = 'проверка_результата'
        разрешение.проверить(материализована=True, результат=True)
        ошибки = validate_dependency(repo_root, spec)
        if ошибки:
            raise RuntimeError('; '.join(ошибки))
        разрешение.проверить(материализована=True, результат=True)
        разрешение.сохранить_исход('готова')
        разрешение.проверить(материализована=True, результат=True)
        return []
    except (OSError, UnicodeError, ValueError, TypeError, KeyError, RuntimeError) as ошибка:
        if намерение_сохранено:
            try:
                разрешение.сохранить_исход('неизвестно')
            except (OSError, RuntimeError) as ошибка_записи:
                return ['неизвестный исход add; частичные результаты сохранены: ' + str(ошибка),
                        'исход не удалось устойчиво записать: ' + str(ошибка_записи)]
        return ['допуск add закрыт; частичные результаты сохраняются: ' + str(ошибка)]


def add_repo_root_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Корень основного Git-репозитория.",
    )


def add_path_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--path",
        required=True,
        help="Относительный путь submodule в основном репозитории.",
    )


def add_common_arguments(parser: argparse.ArgumentParser) -> None:
    add_repo_root_argument(parser)
    parser.add_argument("--fork-url", required=True, help="URL управляемого форка.")
    parser.add_argument(
        "--upstream-url",
        required=True,
        help="URL исходного репозитория.",
    )
    add_path_argument(parser)
    parser.add_argument(
        "--revision",
        required=True,
        help="Полный Git OID выбранного коммита.",
    )


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Добавить, инициализировать или проверить внешнюю Git-зависимость "
            "через управляемый форк."
        )
    )
    commands = parser.add_subparsers(dest="command", required=True)
    add_parser = commands.add_parser("add", help="Добавить новый Git submodule.")
    add_common_arguments(add_parser)
    add_parser.add_argument('--допуск', type=Path, required=True,
                            help='Самостоятельно подготовленный закрытый допуск.')
    add_parser.add_argument('--ожидаемый-хэш-допуска', required=True,
                            help='Независимо выбранный SHA-256 сырых байтов допуска.')
    check_parser = commands.add_parser(
        "check",
        help="Автономно проверить уже материализованную зависимость.",
    )
    add_common_arguments(check_parser)
    init_parser = commands.add_parser(
        "init",
        help="Инициализировать уже зарегистрированный Git submodule.",
    )
    add_repo_root_argument(init_parser)
    add_path_argument(init_parser)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(argv)
    if arguments.command == "init":
        dependency_spec, errors = initialize_registered_dependency(
            arguments.repo_root,
            arguments.path,
        )
        success_message = "Инициализирована и проверена Git-зависимость"
    else:
        dependency_spec = DependencySpec(
            fork_url=arguments.fork_url,
            upstream_url=arguments.upstream_url,
            path=arguments.path,
            revision=arguments.revision.lower(),
        )
        if arguments.command == "add":
            errors = materialize_dependency(arguments.repo_root, dependency_spec,
                допуск=arguments.допуск, ожидаемый_хэш_допуска=arguments.ожидаемый_хэш_допуска)
        else:
            errors = validate_dependency(arguments.repo_root, dependency_spec)
        success_message = "Проверена Git-зависимость"
    if errors:
        for error in errors:
            print(f"Ошибка: {error}", file=sys.stderr)
        return 1
    if dependency_spec is None:
        print("Ошибка: контракт зарегистрированной зависимости не определён", file=sys.stderr)
        return 1
    print(
        f"{success_message}: {dependency_spec.path} "
        f"@ {dependency_spec.revision}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
