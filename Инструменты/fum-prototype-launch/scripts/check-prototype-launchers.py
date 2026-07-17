#!/usr/bin/env python3
"""Validate the standard launch script contract for FUM prototypes."""

from __future__ import annotations

import argparse
import stat
import subprocess
from pathlib import Path


PROTOTYPES_DIR = Path("Прототипы")
PROTOTYPE_README = "README.md"
LAUNCHER_NAME = "запустить.sh"
ROOT_LAUNCHER = Path("prototipyi.sh")
EXPECTED_SHEBANG = "#!/bin/sh"


def prototype_directories(repo_root: Path) -> list[Path]:
    prototypes_root = repo_root / PROTOTYPES_DIR
    if not prototypes_root.is_dir():
        return []
    return sorted(
        (
            path
            for path in prototypes_root.iterdir()
            if path.is_dir() and (path / PROTOTYPE_README).is_file()
        ),
        key=lambda path: path.name,
    )


def relative(path: Path, repo_root: Path) -> str:
    return path.relative_to(repo_root).as_posix()


def validate_launcher(launcher: Path, repo_root: Path) -> list[str]:
    display_path = relative(launcher, repo_root)
    if not launcher.exists():
        return [f"{display_path}: файл отсутствует"]
    if not launcher.is_file():
        return [f"{display_path}: ожидается обычный файл"]

    errors: list[str] = []
    mode = launcher.stat().st_mode
    if mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH) == 0:
        errors.append(f"{display_path}: не установлен исполняемый бит")

    first_line = launcher.read_text(encoding="utf-8").splitlines()[:1]
    if first_line != [EXPECTED_SHEBANG]:
        errors.append(
            f"{display_path}: первая строка должна быть {EXPECTED_SHEBANG}"
        )

    syntax = subprocess.run(
        ["/bin/sh", "-n", launcher.as_posix()],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if syntax.returncode != 0:
        detail = syntax.stderr.strip() or f"код {syntax.returncode}"
        errors.append(f"{display_path}: ошибка синтаксиса /bin/sh: {detail}")
    return errors


def validate_root_launcher(repo_root: str | Path) -> list[str]:
    root = Path(repo_root).resolve()
    return validate_launcher(root / ROOT_LAUNCHER, root)


def validate_prototype_launchers(repo_root: str | Path) -> list[str]:
    root = Path(repo_root).resolve()
    if not (root / PROTOTYPES_DIR).is_dir():
        return [f"{PROTOTYPES_DIR.as_posix()}: каталог отсутствует"]

    errors: list[str] = []
    for prototype in prototype_directories(root):
        errors.extend(validate_launcher(prototype / LAUNCHER_NAME, root))
    return errors


def validate_launch_contract(repo_root: str | Path) -> list[str]:
    root = Path(repo_root).resolve()
    return validate_root_launcher(root) + validate_prototype_launchers(root)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Корень репозитория; по умолчанию текущий каталог.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    errors = validate_launch_contract(args.repo_root)
    if errors:
        for error in errors:
            print(f"ОШИБКА: {error}")
        print(f"Проверка не пройдена: ошибок — {len(errors)}.")
        return 1

    count = len(prototype_directories(args.repo_root.resolve()))
    print(
        "Проверка пройдена: корневая панель — 1, "
        f"скриптов прототипов — {count}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
