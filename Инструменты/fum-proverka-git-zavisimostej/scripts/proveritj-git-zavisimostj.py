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
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RuntimeError(f"git {' '.join(arguments)}: {error}") from error
    if result.returncode not in allowed_returncodes:
        detail = result.stderr.strip() or result.stdout.strip() or "без диагностики"
        raise RuntimeError(
            f"git {' '.join(arguments)} завершился с кодом "
            f"{result.returncode}: {detail}"
        )
    return GitResult(
        returncode=result.returncode,
        stdout=result.stdout.strip(),
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

    path = PurePosixPath(spec.path)
    if (
        not spec.path
        or spec.path != spec.path.strip()
        or path.is_absolute()
        or spec.path.startswith("-")
        or "\\" in spec.path
        or any(part in {"", ".", "..", ".git"} for part in path.parts)
    ):
        errors.append(
            "путь зависимости должен быть безопасным относительным Git-путём "
            "без '.', '..', '.git' и обратных косых черт"
        )
    if REVISION_PATTERN.fullmatch(spec.revision) is None:
        errors.append("ревизия должна быть полным 40- или 64-символьным Git OID")
    return errors


def dependency_path(repo_root: Path, spec: DependencySpec) -> Path:
    posix_path = PurePosixPath(spec.path)
    return repo_root.joinpath(*posix_path.parts)


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
            "-f",
            ".gitmodules",
            "--get-regexp",
            r"^submodule\..*\.path$",
            allowed_returncodes=(0, 1),
        )
    except RuntimeError as error:
        return None, [f"не удалось прочитать .gitmodules: {error}"]

    matches: list[str] = []
    if result.returncode == 0:
        for line in result.stdout.splitlines():
            key, separator, value = line.partition(" ")
            if separator and value == path:
                matches.append(key.removesuffix(".path"))
    if len(matches) != 1:
        return None, [
            f".gitmodules должен содержать ровно одну запись path = {path!r}"
        ]
    return matches[0], []


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
    return []


def validate_dependency(repo_root: Path, spec: DependencySpec) -> list[str]:
    repo_root = repo_root.resolve()
    errors = validate_spec(spec)
    errors.extend(validate_repo_root(repo_root))
    if errors:
        return errors
    errors.extend(validate_repository_topology(repo_root, spec))

    section, section_errors = find_submodule_section(repo_root, spec.path)
    errors.extend(section_errors)
    if section is not None:
        try:
            configured_url = run_git(
                repo_root,
                "config",
                "-f",
                ".gitmodules",
                "--get",
                f"{section}.url",
            ).stdout
        except RuntimeError as error:
            errors.append(f"не удалось прочитать URL из .gitmodules: {error}")
        else:
            if configured_url != spec.fork_url:
                errors.append(
                    ".gitmodules должен использовать URL форка "
                    f"{spec.fork_url!r}, получено {configured_url!r}"
                )
        try:
            configured_upstream = run_git(
                repo_root,
                "config",
                "-f",
                ".gitmodules",
                "--get",
                f"{section}.fumUpstream",
            ).stdout
        except RuntimeError as error:
            errors.append(
                ".gitmodules должен сохранять fumUpstream для восстановления "
                f"remote upstream: {error}"
            )
        else:
            if configured_upstream != spec.upstream_url:
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
        working_gitmodules = (repo_root / ".gitmodules").read_text(encoding="utf-8").strip()
        if indexed_gitmodules != working_gitmodules:
            errors.append("рабочая .gitmodules не совпадает с записью в Git-индексе")

    dependency = dependency_path(repo_root, spec)
    if not dependency.is_dir():
        errors.append(f"{spec.path}: каталог зависимости отсутствует")
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
    if not git_marker.is_file():
        errors.append(f"{spec.path}: submodule должен использовать связанный .git-файл")
    try:
        superproject = run_git(
            dependency,
            "rev-parse",
            "--show-superproject-working-tree",
        ).stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось подтвердить связь с superproject: {error}")
    else:
        if Path(superproject).resolve() != repo_root:
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
        validate_remote_urls(
            dependency,
            spec.path,
            "upstream",
            spec.upstream_url,
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

    try:
        gitlink_result = run_git(
            repo_root,
            "ls-files",
            "--stage",
            "--",
            spec.path,
        ).stdout
    except RuntimeError as error:
        errors.append(f"{spec.path}: не удалось прочитать gitlink: {error}")
    else:
        lines = [line for line in gitlink_result.splitlines() if line]
        if len(lines) != 1:
            errors.append(f"{spec.path}: ожидается ровно один gitlink в индексе")
        else:
            metadata, separator, _ = lines[0].partition("\t")
            fields = metadata.split()
            if not separator or len(fields) != 3:
                errors.append(f"{spec.path}: некорректная запись gitlink")
            else:
                mode, revision, stage = fields
                if mode != "160000" or stage != "0":
                    errors.append(
                        f"{spec.path}: ожидается gitlink mode 160000 stage 0"
                    )
                if revision != spec.revision:
                    errors.append(
                        f"{spec.path}: gitlink должен быть {spec.revision}, "
                        f"получено {revision}"
                    )
    return errors


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


def add_common_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Корень основного Git-репозитория.",
    )
    parser.add_argument("--fork-url", required=True, help="URL управляемого форка.")
    parser.add_argument(
        "--upstream-url",
        required=True,
        help="URL исходного репозитория.",
    )
    parser.add_argument(
        "--path",
        required=True,
        help="Относительный путь submodule в основном репозитории.",
    )
    parser.add_argument(
        "--revision",
        required=True,
        help="Полный SHA-1 выбранного коммита.",
    )


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Добавить или проверить внешнюю Git-зависимость через управляемый форк."
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
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(argv)
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
    if errors:
        for error in errors:
            print(f"Ошибка: {error}", file=sys.stderr)
        return 1
    print(
        f"Проверена Git-зависимость: {dependency_spec.path} "
        f"@ {dependency_spec.revision}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
