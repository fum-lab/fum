#!/usr/bin/env python3
"""Перенести проверенный курсор модели между папками Журнала."""
import argparse
import json

from перенести_историю_модели import перенести


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    for имя in ("корень-репозитория", "исходник", "задача-источника",
                "прежний-кэш", "прежняя-история", "кэш", "история"):
        разбор.add_argument("--" + имя, required=True)
    разбор.add_argument("--без-записи", action="store_true")
    параметры = разбор.parse_args()
    try:
        результат = перенести(параметры.исходник, параметры.задача_источника,
            корень_репозитория=параметры.корень_репозитория,
            прежний_кэш=параметры.прежний_кэш,
            прежняя_история=параметры.прежняя_история,
            кэш=параметры.кэш, история=параметры.история,
            без_записи=параметры.без_записи)
        print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
        return 0 if результат["полнота"] else 3
    except (ValueError, OSError, KeyError, TypeError) as ошибка:
        print(json.dumps({"схема": "fum.отказ-переноса-истории-модели.1",
            "полнота": False, "ошибка": str(ошибка)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    raise SystemExit(выполнить())
