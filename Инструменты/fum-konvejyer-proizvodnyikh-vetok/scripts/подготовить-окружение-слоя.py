#!/usr/bin/env python3
"""Подготовить одну закреплённую зависимость до Журнала дочернего писателя."""
import argparse
import json
from окружение_слоя import подготовить


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--корень-репозитория', required=True)
    разбор.add_argument('--задача', required=True)
    разбор.add_argument('--источник', required=True)
    разбор.add_argument('--путь', required=True)
    вход = разбор.parse_args()
    return подготовить(вход.корень_репозитория, вход.задача, вход.источник, вход.путь)


if __name__ == '__main__':
    try:
        print(json.dumps(выполнить(), ensure_ascii=False, sort_keys=True))
    except (ValueError, OSError, RuntimeError) as ошибка:
        print(json.dumps({'схема': 'fum.отказ-подготовки-окружения.1', 'ошибка': str(ошибка)}, ensure_ascii=False))
        raise SystemExit(2)
