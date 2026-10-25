#!/usr/bin/env python3
"""Проверить область собственного слоя из первичного JSONL, без записи."""
import argparse
import json

from дочернее_назначение import прочитать


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", required=True)
    разбор.add_argument("--задача", required=True)
    разбор.add_argument("--источник", required=True)
    вход = разбор.parse_args()
    return прочитать(вход.корень_репозитория, вход.задача, вход.источник)


if __name__ == "__main__":
    try:
        print(json.dumps(выполнить(), ensure_ascii=False, sort_keys=True))
    except (ValueError, OSError) as ошибка:
        print(json.dumps({"схема": "fum.отказ-дочернего-назначения.1", "ошибка": str(ошибка)}, ensure_ascii=False))
        raise SystemExit(2)
