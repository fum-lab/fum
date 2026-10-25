#!/usr/bin/env python3
"""Обновить открытый служебный блок и проверить поля внутри учтённого запуска."""

import argparse
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] /
                       "fum-otchyotyi-o-zapuskakh-proverok/scripts"))
from отчёты_о_запусках_проверок import ОшибкаОтчёта, выполнить_предпросмотр
from проверка_полей_журнала import проверить


def выполнить() -> int:
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", type=Path, required=True)
    разбор.add_argument("--запрос", type=Path, required=True)
    аргументы = разбор.parse_args()
    try:
        выполнить_предпросмотр(аргументы.корень, аргументы.запрос)
        результат = проверить(аргументы.корень, аргументы.запрос)
    except (ОшибкаОтчёта, OSError, ValueError, RuntimeError) as ошибка:
        print(json.dumps({"схема": "fum.поля-журнала.1", "полная_приёмка": False,
                          "ошибки": [str(ошибка)], "входы": []}, ensure_ascii=False))
        return 2
    print(json.dumps(результат, ensure_ascii=False))
    return 1 if результат["ошибки"] else 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
