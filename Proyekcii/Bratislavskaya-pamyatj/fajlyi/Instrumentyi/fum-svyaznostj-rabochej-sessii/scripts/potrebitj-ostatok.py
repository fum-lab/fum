"""Применить локальный детектор; stdout — данные, stderr — квитанция."""
import argparse
import sys
from pathlib import Path

from детектор_вывода import потребить
from компактный_остаток import закодировать


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--результат', type=Path, required=True)
    разбор.add_argument('--sha256', required=True)
    разбор.add_argument('--код-производителя', type=int, required=True)
    разбор.add_argument('--бюджет-байтов', type=int, required=True)
    разбор.add_argument('--начало', type=int, default=0)
    разбор.add_argument('--число', type=int, default=1)
    параметры = разбор.parse_args()
    try:
        with параметры.результат.open('rb') as поток:
            данные = поток.read(128 * 1024 * 1024 + 1)
        вывод, квитанция = потребить(данные, параметры.sha256, параметры.бюджет_байтов,
            параметры.код_производителя, начало=параметры.начало, число=параметры.число)
        sys.stderr.buffer.write(закодировать(квитанция))
        sys.stdout.buffer.write(вывод)
        return 0
    except (OSError, ValueError) as ошибка:
        sys.stderr.buffer.write(закодировать({'схема': 'fum.отказ-чтения-остатка.1',
            'причина': str(ошибка) if isinstance(ошибка, ValueError) else 'файл недоступен',
            'вывод_выдан': False}))
        return 2


if __name__ == '__main__':
    sys.exit(выполнить())
