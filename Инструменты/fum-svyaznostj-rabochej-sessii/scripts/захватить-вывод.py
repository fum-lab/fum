#!/usr/bin/env python3
"""Общий локальный захват и адресное раскрытие сохранённых каналов."""
import argparse
from pathlib import Path
import sys

from захват_вывода import захватить_с_хэшем, представить_захват, прочитать_диапазон, записать


def выполнить(аргументы=None):
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--каталог', required=True, type=Path)
    разбор.add_argument('--бюджет', type=int, default=16000)
    режимы = разбор.add_subparsers(dest='режим', required=True)
    запуск = режимы.add_parser('запустить')
    запуск.add_argument('--корень', required=True, type=Path)
    запуск.add_argument('--задача', required=True)
    запуск.add_argument('--тайм-аут', type=float, default=60)
    запуск.add_argument('--предел-байтов', type=int, default=134217728)
    запуск.add_argument('--обработчик', choices=('общий', 'остаток'), default='общий')
    запуск.add_argument('команда', nargs=argparse.REMAINDER)
    обзор = режимы.add_parser('представить')
    обзор.add_argument('--sha256', required=True)
    чтение = режимы.add_parser('прочитать')
    чтение.add_argument('--sha256', required=True)
    чтение.add_argument('--канал', choices=('stdout', 'stderr'), required=True)
    чтение.add_argument('--начало', type=int, required=True)
    чтение.add_argument('--число', type=int, required=True)
    # Диагностика argparse относится только к ошибочному вызову до эффекта.
    параметры = разбор.parse_args(аргументы)
    try:
        if not 100 <= параметры.бюджет <= 1048576:
            raise ValueError('Недопустимый бюджет')
        if параметры.режим == 'запустить':
            команда = параметры.команда
            if команда and команда[0] == '--':
                команда = команда[1:]
            _, ожидаемый = захватить_с_хэшем(команда, параметры.каталог, параметры.корень, параметры.задача,
                тайм_аут=параметры.тайм_аут, предел_байтов=параметры.предел_байтов,
                обработчик=параметры.обработчик)
        else:
            ожидаемый = параметры.sha256
        if параметры.режим == 'прочитать':
            вывод = прочитать_диапазон(параметры.каталог, ожидаемый, параметры.канал,
                параметры.начало, параметры.число, параметры.бюджет)
        else:
            вывод = представить_захват(параметры.каталог, ожидаемый, параметры.бюджет)
    except (ValueError, OSError):
        # После возможного эффекта повторного запуска и длинной диагностики нет.
        вывод = b'{"error":"capture-or-representation-failed","retry":false}\n'
        try:
            записать(sys.stdout.fileno(), вывод)
        except OSError:
            pass
        return 2
    try:
        записать(sys.stdout.fileno(), вывод)
    except OSError:
        # Часть байтов могла уйти: нельзя добавлять вторую квитанцию/диагностику.
        return 2
    return 0


if __name__ == '__main__':
    raise SystemExit(выполнить())
