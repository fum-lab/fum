"""Три свежие пары одного удержанного малого корпуса, без живого ROOT."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time

from test_строгий_индекс_путей import вызвать


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--основа', type=Path, required=True)
    разбор.add_argument('--код', type=Path, required=True)
    разбор.add_argument('--выход', type=Path, required=True)
    разбор.add_argument('--файлов', type=int, default=128)
    параметры = разбор.parse_args()
    if параметры.файлов < 2 or параметры.файлов > 256:
        raise ValueError('LAB-корпус ограничен 2–256 файлами')
    начало = time.perf_counter_ns()
    пары = []
    вход = None
    for номер in range(3):
        пара = {}
        порядок = ('прежний', 'новый') if номер % 2 == 0 else ('новый', 'прежний')
        for вариант in порядок:
            код = параметры.основа if вариант == 'прежний' else параметры.код
            измерение = вызвать(параметры.основа, код, файлов=параметры.файлов)
            if измерение['исход'] != 'успех':
                raise ValueError('профиль получил отказ проверяемого поведения')
            вход = вход or измерение['вход_sha256']
            if измерение['вход_sha256'] != вход:
                raise ValueError('несопоставимый корпус')
            if измерение['вход_после_sha256'] != вход:
                raise ValueError('корпус изменился при измерении')
            пара[вариант] = измерение
        пара['порядок'] = порядок
        пары.append(пара)
    сбор = time.perf_counter_ns() - начало
    исходники = {имя.name: hashlib.sha256(имя.read_bytes()).hexdigest() for имя in (
        Path(__file__).resolve(), Path(__file__).with_name('test_строгий_индекс_путей.py'))}
    итог = {'схема': 'fum.LAB-профиль-строгого-индекса.1', 'файлов': параметры.файлов,
        'вход_sha256': вход, 'исходники_стенда': исходники, 'пары': пары,
        'сбор_всего_ns': сбор, 'отношение_медиан_wall': statistics.median(п['прежний']['wall_ns'] for п in пары)
            / statistics.median(п['новый']['wall_ns'] for п in пары),
        'границы': ['Каждое измерение — новый процесс и новая собственная Git-фикстура.',
            'Setup и сбор указаны отдельно от измеряемого полного прохода; интервалы не складываются.',
            'listing считает os.scandir, включая Path.iterdir и os.walk; bytes — прочитанные Path.read_bytes байты.',
            'normalization считает unicodedata.normalize; ключей отдельно считает NFC/casefold lookup.',
            'stat считает os.stat и os.lstat; Git и байтов_Git считают вызовы _гит и их полные ответы.',
            'Python peak измерен tracemalloc только внутри прохода; maxRSS включает подготовку процесса.',
            'Метки и tracemalloc входят во время обоих вариантов; кэш ОС не сбрасывается.',
            'Это малый открытый корпус; выигрыша полного ROOT apply или smoke-check он не доказывает.']}
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    with параметры.выход.open('x') as поток:
        json.dump(итог, поток, ensure_ascii=False, sort_keys=True, indent=2); поток.write('\n')
    print(json.dumps({'пар': len(пары), 'вход_sha256': вход, 'отношение_медиан_wall': итог['отношение_медиан_wall']}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
