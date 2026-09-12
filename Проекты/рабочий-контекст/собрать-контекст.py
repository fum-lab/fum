#!/usr/bin/env python3
"""Один переданный файл → один детерминированный JSON; без записи файлов."""
import argparse
import importlib.util
from pathlib import Path
import sys

sys.dont_write_bytecode = True
описание = importlib.util.spec_from_file_location('сборщик', Path(__file__).with_name('сборщик.py'))
сборщик = importlib.util.module_from_spec(описание)
описание.loader.exec_module(сборщик)


def основная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--снимок', required=True, type=Path)
    аргументы = разбор.parse_args()
    try:
        with аргументы.снимок.open('rb') as файл:
            сырьё = файл.read(сборщик.ПРЕДЕЛ_ВХОДА + 1)
        результат = сборщик.собрать(сырьё)
    except (OSError, ValueError, UnicodeError, RecursionError):
        sys.stderr.write('Снимок не принят: проверьте версию, границы, хэши и форму открытого входа.\n')
        return 2
    sys.stdout.buffer.write(сборщик.байты(результат))
    return 0


if __name__ == '__main__':
    raise SystemExit(основная())
