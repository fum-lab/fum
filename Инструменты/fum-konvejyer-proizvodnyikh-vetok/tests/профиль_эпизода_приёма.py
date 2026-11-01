"""Изолировать стоимость фикстуры, долговечной записи и повторного чтения."""
import argparse
import json
from pathlib import Path
import statistics
import time

from test_эпизода_приёма import ПроверкаЭпизодаПриёма, эпизод


def измерить():
    запуски = []
    for номер in range(5):
        пример = ПроверкаЭпизодаПриёма()
        начало = time.monotonic_ns()
        try:
            пример.setUp()
            подготовка = time.monotonic_ns() - начало
            начало = time.monotonic_ns()
            итог = эпизод.начать(пример.основание, lambda: пример.основание)
            запись = time.monotonic_ns() - начало
            чтения = []
            for _ in range(10):
                начало = time.monotonic_ns()
                assert эпизод.прочитать(пример.основание) == итог
                чтения.append(time.monotonic_ns() - начало)
            запуски.append({'номер': номер + 1, 'подготовка_нс': подготовка,
                'запись_нс': запись, 'чтение_нс': чтения})
        finally:
            пример.doCleanups()
    return {'схема': 'fum.профиль-эпизода-приёма.1', 'запуски': запуски,
        'медиана_записи_нс': statistics.median(з['запись_нс'] for з in запуски),
        'медиана_чтения_нс': statistics.median(ч for з in запуски for ч in з['чтение_нс']),
        'граница': 'Пять новых временных каталогов, один процесс после импорта; 50 чтений с тёплым кэшем. '
            'Допуск заменён синтетическим основанием. Время реального JSONL, Git, запуска процесса и очистки не включено.'}


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True, type=Path)
    параметры = парсер.parse_args()
    результат = измерить()
    with параметры.выход.open('x') as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write('\n')
    print(json.dumps({к: з for к, з in результат.items() if к != 'запуски'}, ensure_ascii=False))
