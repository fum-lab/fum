#!/usr/bin/env python3
"""Адресно прочитать выбранное планирование в неизменяемом Git-снимке."""
import argparse
import json
from pathlib import Path
import sys

from актуальный_срез import СрезГит, разобрать_json, собрать_срез, сериализовать


def главная():
    аргументы = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    аргументы.add_argument('--корень-репозитория', required=True, type=Path)
    аргументы.add_argument('--коммит', required=True)
    аргументы.add_argument('--выбор', required=True, type=Path)
    аргументы.add_argument('--момент', required=True)
    аргументы.add_argument('--предел-байтов', required=True, type=int)
    аргументы.add_argument('--профиль', action='store_true')
    вход = аргументы.parse_args()
    профиль = {}
    try:
        выбор = разобрать_json(вход.выбор.read_bytes())
        результат = собрать_срез(СрезГит(вход.корень_репозитория, вход.коммит), выбор,
            вход.момент, вход.предел_байтов, профиль=профиль)
        sys.stdout.buffer.write(сериализовать(результат))
        if вход.профиль:
            print(json.dumps(профиль, ensure_ascii=False, sort_keys=True), file=sys.stderr)
        return 0
    except (ValueError, OSError, TypeError, KeyError) as ошибка:
        print('Срез не построен: ' + str(ошибка), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(главная())
