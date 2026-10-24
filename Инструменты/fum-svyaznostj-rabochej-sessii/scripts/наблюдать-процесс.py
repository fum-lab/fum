#!/usr/bin/env python3
"""Наблюдать один процесс через канонический захват либо прочитать свидетельства."""
import argparse
from pathlib import Path
import sys

from захват_вывода import (разобрать_JSON, наблюдать_процесс, прочитать_наблюдение,
    уложить, записать)


def выполнить(аргументы=None):
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('конфигурация', type=Path)
    разбор.add_argument('--задача')
    разбор.add_argument('--предметные-цели', type=Path)
    разбор.add_argument('--тайм-аут', type=float, default=60)
    разбор.add_argument('--предел-байтов', type=int, default=134217728)
    разбор.add_argument('--бюджет', type=int, default=16000)
    разбор.add_argument('--прочитать', action='store_true')
    разбор.add_argument('--sha256')
    п = разбор.parse_args(аргументы)
    try:
        if not 100 <= п.бюджет <= 1048576:
            raise ValueError('Недопустимый бюджет')
        конфигурация = разобрать_JSON(п.конфигурация.read_bytes())
        if п.прочитать:
            результат = прочитать_наблюдение(конфигурация, п.sha256)
        else:
            if п.задача is None or п.предметные_цели is None or п.sha256 is not None:
                raise ValueError('Запуску нужны задача и полный предметный план')
            цели = разобрать_JSON(п.предметные_цели.read_bytes())
            результат = наблюдать_процесс(конфигурация, п.задача,
                предметные_цели=цели, тайм_аут=п.тайм_аут, предел_байтов=п.предел_байтов)
        вывод = уложить(результат, п.бюджет)
    except (ValueError, OSError):
        вывод = b'{"error":"observation-or-representation-failed","retry":false}\n'
        try:
            записать(sys.stdout.fileno(), вывод)
        except OSError:
            pass
        return 2
    try:
        записать(sys.stdout.fileno(), вывод)
    except OSError:
        return 2
    return 0


if __name__ == '__main__':
    raise SystemExit(выполнить())
