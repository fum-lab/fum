"""Вернуть весь остаток либо сохранить проверенное решение об обработке."""
import argparse
import json
import sys
from pathlib import Path

from обработка_сообщений import ОшибкаОбработки, получить_остаток, сохранить_обработку
from сообщения_задачи import _разобрать


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, required=True)
    разбор.add_argument("--исходник", type=Path, required=True)
    разбор.add_argument("--codex-thread-id", dest="задача", required=True)
    разбор.add_argument("--кэш", type=Path)
    команды = разбор.add_subparsers(dest="действие", required=True)
    чтение = команды.add_parser("остаток", help="Показать сообщения без действительной актуальной обработки")
    чтение.add_argument("--перепроверить", action="store_true")
    чтение.add_argument("--без-записи", action="store_true", help="Не создавать и не обновлять кэш или замки; путь кэша можно опустить")
    запись = команды.add_parser("сохранить", help="Проверить и атомарно сохранить решение; не объявлять поручение выполненным")
    запись.add_argument("--решение", type=Path, required=True)
    запись.add_argument("--ожидаемая-история", required=True)
    параметры = разбор.parse_args()
    try:
        общие = {"корень_репозитория": параметры.корень_репозитория, "кэш": параметры.кэш}
        if параметры.действие == "остаток":
            результат = получить_остаток(параметры.исходник, параметры.задача, **общие, перепроверить=параметры.перепроверить, без_записи=параметры.без_записи)
            код = 0 if результат["разбор_сообщений_завершён"] else 3
        else:
            предложение = _разобрать(параметры.решение.read_bytes())
            результат = сохранить_обработку(параметры.исходник, параметры.задача, **общие,
                запись=предложение, ожидаемая_история=параметры.ожидаемая_история)
            код = 0
        print(json.dumps(результат, ensure_ascii=False, indent=2, allow_nan=False))
        return код
    except (ОшибкаОбработки, OSError, ValueError) as ошибка:
        print(str(ошибка), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(выполнить())
