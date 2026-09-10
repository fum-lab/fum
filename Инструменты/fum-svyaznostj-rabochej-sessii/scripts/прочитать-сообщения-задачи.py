"""Вернуть полный приватный индекс JSONL; не подтверждать обработку команд."""
import argparse
import json
import sys
from pathlib import Path

from сообщения_задачи import ОшибкаСообщений, прочитать_сообщения


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, required=True)
    разбор.add_argument("--исходник", type=Path, required=True)
    разбор.add_argument("--codex-thread-id", dest="задача", required=True)
    разбор.add_argument("--кэш", type=Path)
    разбор.add_argument("--без-записи", action="store_true", help="Не создавать и не обновлять кэш или замки; путь кэша можно опустить")
    разбор.add_argument("--перепроверить", action="store_true")
    параметры = разбор.parse_args()
    try:
        результат = прочитать_сообщения(параметры.исходник, параметры.задача,
            корень_репозитория=параметры.корень_репозитория, кэш=параметры.кэш,
            перепроверить=параметры.перепроверить, без_записи=параметры.без_записи)
    except ОшибкаСообщений as ошибка:
        print(str(ошибка), file=sys.stderr)
        return 2
    print(json.dumps(результат, ensure_ascii=False, indent=2, allow_nan=False))
    return 0 if результат["полнота_подтверждена"] else 3


if __name__ == "__main__":
    sys.exit(выполнить())
