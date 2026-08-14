#!/usr/bin/env python3
"""Материализует и проверяет внешнюю Git-зависимость FUM через управляемый форк."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Sequence
from urllib.parse import urlsplit


REVISION_PATTERN = re.compile(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})\Z")
GITHUB_SCP_PATTERN = re.compile(
    r"(?:[^@]+@)?github\.com:(?P<owner>[^/]+)/(?P<name>[^/]+?)(?:\.git)?\Z"
)


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
            ["git", *arguments],
            cwd=cwd,
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

    части_пути = PurePosixPath(spec.path).parts
    if части_пути and части_пути[0] == "Ядра":
        if len(части_пути) != 2:
            errors.append(
                "дочерний fork должен находиться непосредственно в Ядра/<имя>"
            )
        if fum_origin.kind != fork.kind or fum_origin.kind != upstream.kind:
            errors.append(
                "дочерний fork, его upstream и origin родительского FUM "
                "должны использовать один тип Git-расположения"
            )
        else:
            if fork.kind == "github":
                владелец_совпадает = (
                    fum_origin.namespace.casefold() == fork.namespace.casefold()
                )
                основа_совпадает = (
                    normalized_github_location(fum_origin)
                    == normalized_github_location(upstream)
                )
                ребёнок_совпадает = (
                    normalized_github_location(fum_origin)
                    == normalized_github_location(fork)
                )
                имя_пути_совпадает = (
                    len(части_пути) == 2
                    and части_пути[1].casefold() == fork.name.casefold()
                )
            else:
                владелец_совпадает = fum_origin.namespace == fork.namespace
                основа_совпадает = (
                    fum_origin.namespace,
                    fum_origin.name,
                ) == (
                    upstream.namespace,
                    upstream.name,
                )
                ребёнок_совпадает = (
                    fum_origin.namespace,
                    fum_origin.name,
                ) == (
                    fork.namespace,
                    fork.name,
                )
                имя_пути_совпадает = (
                    len(части_пути) == 2 and части_пути[1] == fork.name
                )
            if not владелец_совпадает:
                errors.append(
                    "дочерний fork должен принадлежать владельцу origin "
                    f"родительского FUM {fum_origin.namespace!r}"
                )
            if not основа_совпадает:
                errors.append(
                    "upstream дочернего fork должен обозначать origin "
                    "родительского FUM"
                )
            if ребёнок_совпадает:
                errors.append(
                    "дочерний fork не должен обозначать сам родительский FUM"
                )
            if not имя_пути_совпадает:
                errors.append(
                    "имя каталога дочернего fork должно совпадать с именем "
                    "его репозитория"
                )
        if fork.kind == "github":
            errors.extend(validate_public_github_https_url(spec.fork_url, "форка"))
        if upstream.kind == "github":
            errors.extend(
                validate_public_github_https_url(spec.upstream_url, "upstream")
            )
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
    names_match = (
        fork.name.casefold() == upstream.name.casefold()
        if fork.kind == upstream.kind == "github"
        else fork.name == upstream.name
    )
    if not names_match:
        errors.append("имена репозиториев форка и upstream должны совпадать")
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
            "ls-files",
            "--stage",
            "--",
            path,
        )
    except RuntimeError as error:
        return None, [f"{path}: не удалось прочитать gitlink: {error}"]
    lines = [line for line in result.stdout.splitlines() if line]
    if len(lines) != 1:
        return None, [f"{path}: ожидается ровно один gitlink в индексе"]
    metadata, separator, _ = lines[0].partition("\t")
    fields = metadata.split()
    if not separator or len(fields) != 3:
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


def проверить_прямую_рекурсивную_композицию(
    зависимость: Path,
    спецификация: DependencySpec,
) -> list[str]:
    части_пути = PurePosixPath(спецификация.path).parts
    if not части_пути or части_пути[0] != "Ядра":
        return []
    try:
        результат = run_git(
            зависимость,
            "ls-tree",
            "--name-only",
            спецификация.revision,
            "--",
            "Ядра",
        )
    except RuntimeError as ошибка:
        return [
            f"{спецификация.path}: не удалось проверить дочерний коммит "
            f"на прямую рекурсивную композицию: {ошибка}"
        ]
    if результат.stdout:
        return [
            f"{спецификация.path}: закреплённый дочерний коммит "
            f"{спецификация.revision} содержит путь Ядра и создаёт "
            "прямую рекурсивную композицию"
        ]
    return []


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
    if Path(dependency_root).resolve() != dependency.resolve():
        errors.append(f"{spec.path}: Git-корень зависимости не совпадает с путём")
    git_marker = dependency / ".git"
    if not git_marker.is_file() or git_marker.is_symlink():
        errors.append(
            f"{spec.path}: submodule должен использовать связанный .git-файл "
            "без символической ссылки"
        )
    if section is not None:
        errors.extend(
            validate_submodule_git_directory(
                repo_root,
                dependency,
                spec.path,
                section,
            )
        )
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
        errors.extend(
            проверить_прямую_рекурсивную_композицию(dependency, spec)
        )
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
            run_git(
                repo_root,
                "-c",
                "protocol.file.allow=always",
                "submodule",
                "update",
                "--init",
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
        run_git(dependency, "fetch", "--prune", "origin")
        run_git(dependency, "fetch", "--prune", "upstream")
    except RuntimeError as error:
        return spec, [f"не удалось получить remote для {spec.path}: {error}"]
    try:
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


def preflight_dependency(spec: DependencySpec) -> list[str]:
    with tempfile.TemporaryDirectory(prefix="fum-git-dependency-") as tmp:
        temporary_root = Path(tmp)
        clone = temporary_root / "dependency"
        try:
            run_git(
                temporary_root,
                "-c",
                "protocol.file.allow=always",
                "clone",
                "--origin",
                "origin",
                "--no-checkout",
                "--",
                spec.fork_url,
                str(clone),
            )
            run_git(clone, "remote", "add", "upstream", spec.upstream_url)
            run_git(clone, "fetch", "origin")
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
        ошибки_композиции = проверить_прямую_рекурсивную_композицию(
            clone,
            spec,
        )
        if ошибки_композиции:
            return ошибки_композиции
    return []


def materialize_dependency(repo_root: Path, spec: DependencySpec) -> list[str]:
    repo_root = repo_root.resolve()
    errors = validate_spec(spec)
    errors.extend(validate_repo_root(repo_root))
    if errors:
        return errors
    errors.extend(validate_repository_topology(repo_root, spec))
    if errors:
        return errors

    target = dependency_path(repo_root, spec)
    if target.exists():
        return validate_dependency(repo_root, spec)
    errors.extend(validate_gitmodules_before_add(repo_root))
    if errors:
        return errors
    if (repo_root / ".gitmodules").exists():
        _, section_errors = find_submodule_section(repo_root, spec.path)
        if not section_errors:
            errors.append(f"{spec.path}: запись .gitmodules уже существует")
    existing_index = run_git(
        repo_root,
        "ls-files",
        "--stage",
        "--",
        spec.path,
    ).stdout
    if existing_index:
        errors.append(f"{spec.path}: путь уже присутствует в Git-индексе")
    git_dir_value = run_git(repo_root, "rev-parse", "--git-dir").stdout
    git_dir = Path(git_dir_value)
    if not git_dir.is_absolute():
        git_dir = repo_root / git_dir
    modules_residue = git_dir.joinpath(
        "modules",
        *PurePosixPath(spec.path).parts,
    )
    if modules_residue.exists():
        errors.append(f"{spec.path}: обнаружен остаточный Git-каталог submodule")
    if errors:
        return errors
    errors.extend(preflight_dependency(spec))
    if errors:
        return errors

    try:
        run_git(
            repo_root,
            "-c",
            "protocol.file.allow=always",
            "submodule",
            "add",
            "--",
            spec.fork_url,
            spec.path,
        )
        target = dependency_path(repo_root, spec)
        run_git(target, "remote", "add", "upstream", spec.upstream_url)
        run_git(target, "fetch", "origin")
        run_git(target, "fetch", "upstream")
        run_git(target, "checkout", "--detach", spec.revision)
        section, section_errors = find_submodule_section(repo_root, spec.path)
        if section_errors or section is None:
            return section_errors or ["не удалось найти новую запись .gitmodules"]
        run_git(
            repo_root,
            "config",
            "-f",
            ".gitmodules",
            f"{section}.fumUpstream",
            spec.upstream_url,
        )
        run_git(repo_root, "add", ".gitmodules", spec.path)
    except RuntimeError as error:
        return [f"не удалось материализовать {spec.path}: {error}"]
    return validate_dependency(repo_root, spec)


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
            errors = materialize_dependency(arguments.repo_root, dependency_spec)
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
