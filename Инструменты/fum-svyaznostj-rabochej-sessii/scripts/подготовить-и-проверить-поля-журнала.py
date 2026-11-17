#!/usr/bin/env python3
"""Обновить открытый служебный блок и проверить поля внутри учтённого запуска."""

import argparse
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] /
                       "fum-otchyotyi-o-zapuskakh-proverok/scripts"))
from отчёты_о_запусках_проверок import (
    ОшибкаОтчёта, выполнить_предпросмотр, _тестово_предпросмотреть_active_помощника,
)
from проверка_полей_журнала import проверить


def выполнить() -> int:
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", type=Path, required=True)
    разбор.add_argument("--запрос", type=Path, required=True)
    разбор.add_argument("--каталог-замка", type=Path)
    разбор.add_argument("--тестовый-каталог-нового-замка", type=Path)
    разбор.add_argument("--тестовый-active")
    разбор.add_argument("--тестовые-опоры", nargs=4, type=int)
    аргументы = разбор.parse_args()
    try:
        опытные = (аргументы.тестовый_каталог_нового_замка,
                   аргументы.тестовый_active, аргументы.тестовые_опоры)
        if any(значение is not None for значение in опытные):
            if аргументы.каталог_замка is None or any(значение is None for значение in опытные):
                raise ОшибкаОтчёта('опытный active требует все параметры опор')
            числа = аргументы.тестовые_опоры
            _тестово_предпросмотреть_active_помощника(
                аргументы.корень, аргументы.запрос, аргументы.каталог_замка,
                аргументы.тестовый_каталог_нового_замка, аргументы.тестовый_active,
                ((числа[0], числа[1]), (числа[2], числа[3])))
        else:
            выполнить_предпросмотр(аргументы.корень, аргументы.запрос,
                                 каталог_замка=аргументы.каталог_замка)
        результат = проверить(аргументы.корень, аргументы.запрос)
    except (ОшибкаОтчёта, OSError, ValueError, RuntimeError) as ошибка:
        print(json.dumps({"схема": "fum.поля-журнала.1", "полная_приёмка": False,
                          "ошибки": [str(ошибка)], "входы": []}, ensure_ascii=False))
        return 2
    print(json.dumps(результат, ensure_ascii=False))
    return 1 if результат["ошибки"] else 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
