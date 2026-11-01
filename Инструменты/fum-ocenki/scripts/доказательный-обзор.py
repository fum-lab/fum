#!/usr/bin/env python3
"""Восстановить приватный обзор по уже проверенной квитанции; создать новый C нельзя."""
import argparse
import json
from pathlib import Path
import sys

from доказательный_обзор import ОшибкаОбзора, применить


def главная():
    разборщик = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разборщик.add_argument('--подготовка', type=Path, required=True)
    разборщик.add_argument('--квитанция', type=Path, required=True)
    разборщик.add_argument('--кэш', type=Path)
    аргументы = разборщик.parse_args()
    try:
        результат_обзора = применить(аргументы.подготовка, аргументы.квитанция, кэш=аргументы.кэш)
        print(json.dumps(результат_обзора, ensure_ascii=False, sort_keys=True))
        return 0
    except ОшибкаОбзора as причина:
        print(json.dumps({'схема': 'fum.отказ-доказательного-обзора.1', 'ошибка': str(причина)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(главная())
