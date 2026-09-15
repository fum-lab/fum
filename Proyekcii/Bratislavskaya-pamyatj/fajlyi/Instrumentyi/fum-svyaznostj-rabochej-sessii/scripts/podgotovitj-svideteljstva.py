"""Показать план структурирующего оператора либо применить закреплённый план."""
import argparse
import json
import os
import sys
from pathlib import Path

import устойчивые_свидетельства as свидетельства


def приватный_вход(путь):
    путь = свидетельства.читатель._путь(путь)
    свидетельства.обработка.требовать(not any(os.path.lexists(предок / ".git") for предок in путь.parents), "описание или план должны находиться вне Git")
    свидетельства.читатель._обычный(путь.stat(), приватный=True)
    return свидетельства.читатель._разобрать(свидетельства.обработка.прочитать_файл(путь))


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, required=True)
    разбор.add_argument("--исходник", type=Path, required=True)
    разбор.add_argument("--codex-thread-id", dest="задача", required=True)
    команды = разбор.add_subparsers(dest="действие", required=True)
    подготовка = команды.add_parser("план")
    подготовка.add_argument("--описание", type=Path, required=True)
    применение = команды.add_parser("применить")
    применение.add_argument("--план", type=Path, required=True)
    применение.add_argument("--ожидаемый-sha256", required=True)
    применение.add_argument("--кэш", type=Path, required=True)
    параметры = разбор.parse_args()
    try:
        общие = {"корень_репозитория": параметры.корень_репозитория}
        if параметры.действие == "план":
            описание = приватный_вход(параметры.описание)
            свидетельства.обработка.объект(описание, {"каталог", "решения"})
            план = свидетельства.подготовить(параметры.исходник, параметры.задача, **общие, **описание)
            результат = {"план": план, "sha256": свидетельства.обработка.хэш(свидетельства.читатель._байты(план))}
            код = 0
        else:
            план = приватный_вход(параметры.план)
            результат = свидетельства.применить(параметры.исходник, параметры.задача, **общие,
                кэш=параметры.кэш, план=план, ожидаемый_хэш=параметры.ожидаемый_sha256)
            код = 0 if результат["применено"] else 3
        print(json.dumps(результат, ensure_ascii=False, indent=2))
        return код
    except (OSError, ValueError, KeyError, TypeError) as ошибка:
        print(json.dumps({"ошибка": str(ошибка), "применено": False}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(выполнить())
