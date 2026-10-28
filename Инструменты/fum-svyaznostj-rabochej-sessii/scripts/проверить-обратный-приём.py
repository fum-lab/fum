#!/usr/bin/env python3
"""Проверить точные входы обратного приёма и вывести план без записи."""
import argparse
import json
from pathlib import Path
import sys

if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
from контракт_обратного_приёма import составить_план, _объект, _недопустимая_константа


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument("--заявка", required=True, type=Path)
    разбор.add_argument("--наблюдение", required=True, type=Path)
    разбор.add_argument("--ревью", required=True, type=Path)
    разбор.add_argument("--проверка", required=True, action="append", type=Path)
    параметры = разбор.parse_args()
    def прочитать(путь):
        return json.loads(путь.read_bytes().decode("utf-8"),
                          object_pairs_hook=_объект, parse_constant=_недопустимая_константа)
    return составить_план(прочитать(параметры.заявка), прочитать(параметры.наблюдение),
                         параметры.ревью.read_bytes(),
                         [путь.read_bytes() for путь in параметры.проверка])


if __name__ == "__main__":
    try:
        print(json.dumps(главная(), ensure_ascii=False, sort_keys=True))
    except (OSError, ValueError, TypeError, RecursionError) as ошибка:
        print(json.dumps({"ошибка": str(ошибка), "разрешение_записи": False},
                         ensure_ascii=False), file=sys.stderr)
        raise SystemExit(2)
