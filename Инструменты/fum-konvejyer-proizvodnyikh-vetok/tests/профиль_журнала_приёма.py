"""Стоимость установки и повтора пары отдельно от нативного допуска и merge."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import sys
import tempfile
import time

from test_журнала_приёма import подготовить, журнал_приёма, гит


def измерить():
    корень = Path(__file__).resolve().parents[3]
    пути = {*журнал_приёма.КОД, Path(__file__).resolve(),
        Path(__file__).with_name('test_журнала_приёма.py').resolve(),
        Path(__file__).with_name('фикстура_слияния_приёма.py').resolve()}
    def отпечатки():
        return {п.relative_to(корень).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest() for п in sorted(пути)}
    исходники = отпечатки(); запуски = []
    for номер in range(3):
        with tempfile.TemporaryDirectory(prefix='fum-профиль-журнала-') as папка:
            начало = time.monotonic_ns(); пример = подготовить(папка)
            подготовка = time.monotonic_ns() - начало
            with пример.приём() as приём:
                начало = time.monotonic_ns(); приём.применить()
                слияние = time.monotonic_ns() - начало
                приём.профиль.clear(); исполнитель = журнал_приёма.ЖурналПриёма(приём)
                начало = time.monotonic_ns(); первый = исполнитель.установить()
                установка = time.monotonic_ns() - начало
                сам_журнал = пример.цель / пример.блок['журнал']
                файлы = {п.name: (hashlib.sha256(п.read_bytes()).hexdigest(), п.stat().st_mtime_ns)
                    for п in сам_журнал.iterdir()}
                повторы = []
                for _ in range(3):
                    начало = time.monotonic_ns()
                    assert исполнитель.установить() == первый
                    повторы.append(time.monotonic_ns() - начало)
                assert файлы == {п.name: (hashlib.sha256(п.read_bytes()).hexdigest(), п.stat().st_mtime_ns)
                    for п in сам_журнал.iterdir()}
                assert гит(пример.цель, 'write-tree') == пример.основание['дерево']
                assert гит(пример.цель, 'rev-parse', 'HEAD') == пример.вершина
                запуски.append({'номер': номер + 1, 'подготовка_нс': подготовка,
                    'слияние_нс': слияние, 'установка_нс': установка, 'повторы_нс': повторы,
                    'метки': list(приём.профиль)})
    assert исходники == отпечатки()
    return {'схема': 'fum.профиль-журнала-приёма.1', 'Python': sys.version,
        'исходники_sha256': исходники, 'запуски': запуски,
        'медиана_установки_нс': statistics.median(з['установка_нс'] for з in запуски),
        'медиана_повтора_нс': statistics.median(п for з in запуски for п in з['повторы_нс']),
        'граница': 'Три малых Git-репозитория, первая установка пары и три повтора в каждом. '
            'Нативный допуск и сверка загруженного кода из C явно заменены фикстурой. '
            'Это стоимость файлового/Git-протокола, не полного входа Desktop. '
            'Подготовка и merge измерены отдельно; импорт, очистка и реальный JSONL не включены. '
            'Кэш ОС не очищен; вложенные метки не суммируются с внешними интервалами.'}


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True, type=Path)
    параметры = парсер.parse_args(); результат = измерить()
    with параметры.выход.open('x') as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2); поток.write('\n')
    print(json.dumps({к: з for к, з in результат.items() if к not in ('запуски', 'исходники_sha256')}, ensure_ascii=False))
