#!/usr/bin/env python3
import argparse
import importlib.util
import json
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path


def git(корень: Path, *аргументы: str) -> bytes:
    return subprocess.run(
        ["git", "-C", str(корень), *аргументы],
        check=True,
        stdout=subprocess.PIPE,
    ).stdout


def пути_из_nul(данные: bytes):
    return [часть.decode("utf-8") for часть in данные.split(b"\0") if часть]


def main() -> int:
    разбор = argparse.ArgumentParser()
    разбор.add_argument("--корень", type=Path, required=True)
    аргументы = разбор.parse_args()
    корень = аргументы.корень.resolve()
    удалённые = пути_из_nul(git(корень, "diff", "--name-only", "--diff-filter=D", "-z", "HEAD"))
    assert not удалённые
    пути = set(пути_из_nul(git(
        корень,
        "diff",
        "--name-only",
        "--diff-filter=ACMRTUXB",
        "-z",
        "HEAD",
    )))
    пути.update(пути_из_nul(git(корень, "ls-files", "--others", "--exclude-standard", "-z")))
    выбранные = tuple(sorted(пути))
    assert выбранные

    физический_временный_корень = Path(tempfile.gettempdir()).resolve()
    временный = Path(tempfile.mkdtemp(prefix="fum-observation-publication.", dir=физический_временный_корень))
    try:
        for относительный in выбранные:
            источник = корень / относительный
            assert источник.is_file() and not источник.is_symlink()
            цель = временный / относительный
            цель.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(источник, цель)
            цель.chmod(stat.S_IMODE(источник.stat().st_mode))
        subprocess.run(["git", "-C", str(временный), "init", "-q"], check=True)
        subprocess.run(["git", "-C", str(временный), "add", "--all"], check=True)

        сканер = корень / "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/proveritj-mashinno-lokaljnyiye-puti.py"
        политика = корень / "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy.json"
        sys.path.insert(0, str(сканер.parent))
        спецификация = importlib.util.spec_from_file_location("fum_publication_scanner", сканер)
        модуль = importlib.util.module_from_spec(спецификация)
        assert спецификация.loader is not None
        спецификация.loader.exec_module(модуль)
        полная = модуль.load_policy(политика)
        адресная = модуль.выбрать_политику(полная, выбранные)
        модуль.load_policy = lambda _путь: адресная
        результат = модуль.scan_repository(временный, политика)
        for строка in результат.rendered_lines():
            print(строка)
        print(json.dumps({
            "схема": "fum.адресная-публикационная-дельта.1",
            "путей": len(выбранные),
            "исключений_политики": len(адресная.exceptions),
            "метаданных_политики": len(адресная.метаданные),
            "находок": len(результат.findings),
            "код": результат.exit_code,
        }, ensure_ascii=False, sort_keys=True))
        return результат.exit_code
    finally:
        shutil.rmtree(временный)


if __name__ == "__main__":
    raise SystemExit(main())
