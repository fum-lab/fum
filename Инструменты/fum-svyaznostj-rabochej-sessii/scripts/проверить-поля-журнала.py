#!/usr/bin/env python3
"""Проверить обязательные поля двух документов до полного допуска сессии."""

import argparse
import json
from pathlib import Path

from проверка_полей_журнала import проверить


def выполнить() -> int:
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", type=Path, required=True)
    разбор.add_argument("--запрос", type=Path, required=True)
    аргументы = разбор.parse_args()
    try:
        результат = проверить(аргументы.корень, аргументы.запрос)
    except (OSError, ValueError, RuntimeError) as ошибка:
        print(json.dumps({"схема": "fum.поля-журнала.1", "полная_приёмка": False,
                          "ошибки": [str(ошибка)], "входы": []}, ensure_ascii=False))
        return 2
    print(json.dumps(результат, ensure_ascii=False))
    return 1 if результат["ошибки"] else 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
