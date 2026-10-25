#!/usr/bin/env python3
"""Явно перепроверить и перепривязать полную историю модели к новому inode."""
import argparse
import json

from перепривязать_историю_модели import перепривязать


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    for имя in ("корень-репозитория", "исходник", "задача-источника", "кэш", "история"):
        разбор.add_argument("--" + имя, required=True)
    разбор.add_argument("--без-записи", action="store_true")
    параметры = разбор.parse_args()
    try:
        результат = перепривязать(параметры.исходник, параметры.задача_источника,
            корень_репозитория=параметры.корень_репозитория, кэш=параметры.кэш,
            история=параметры.история, без_записи=параметры.без_записи)
        print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
        return 0 if результат["полнота"] else 3
    except (ValueError, OSError, KeyError, TypeError) as ошибка:
        print(json.dumps({"схема": "fum.отказ-перепривязки-истории-модели.1",
            "полнота": False, "ошибка": str(ошибка)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    raise SystemExit(выполнить())
