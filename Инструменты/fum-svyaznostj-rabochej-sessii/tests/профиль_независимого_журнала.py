"""Совместимость старого P.1 и три новых процесса чистого преобразования."""
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time
import tracemalloc
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_независимой_пары_и_индекса import пример, запись, состав, построить_пару, построить_индекс


def измерить():
    результаты = []
    for количество in (1, 100, 1000):
        tracemalloc.start(); начало = time.monotonic_ns()
        записи = []; файлы = {}
        for номер in range(количество):
            вход = пример('этап-' + str(номер)); пара = построить_пару(вход)
            записи.append(запись(пара, вход)); файлы.update({ф['путь']: ф['байты'] for ф in пара['файлы']})
        после_пар = time.monotonic_ns(); поколение, хэш = состав(записи)
        индекс = построить_индекс(поколение, файлы, ожидаемый_sha256=хэш)
        конец = time.monotonic_ns(); _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
        результаты.append({'записей': количество, 'пары_нс': после_пар - начало,
            'состав_и_индекс_нс': конец - после_пар, 'всего_нс': конец - начало,
            'пик_Python_байты': пик, 'индекс_байты': len(индекс['байты']),
            'sha256': индекс['sha256'], 'состав_sha256': хэш, 'API': 0, 'разборов_native': 0,
            'разрешение_установки': индекс['разрешение_установки']})
    return результаты


def главная():
    if sys.argv[1:] == ['--новый-процесс']:
        print(json.dumps(измерить(), ensure_ascii=False, sort_keys=True)); return
    if sys.argv[1:]: raise ValueError('неизвестные аргументы профиля')
    новые = unittest.defaultTestLoader.discover(str(Path(__file__).resolve().parent),
        pattern='test_независимой_пары_и_индекса.py')
    новый_итог = unittest.TextTestRunner().run(новые)
    if not новый_итог.wasSuccessful(): raise SystemExit(1)
    проверки = unittest.defaultTestLoader.discover(str(Path(__file__).resolve().parent),
        pattern='test_проверенного_плана_журнала_состояния.py')
    итог = unittest.TextTestRunner().run(проверки)
    if not итог.wasSuccessful(): raise SystemExit(1)
    повторы = []
    for _ in range(3):
        начало = time.monotonic_ns()
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--новый-процесс'],
            cwd=Path(__file__).resolve().parents[3], capture_output=True, check=True)
        повторы.append({'процесс_нс': time.monotonic_ns() - начало,
            'стадии': json.loads(процесс.stdout)})
    for номер in range(3):
        assert len({п['стадии'][номер]['sha256'] for п in повторы}) == 1
        assert len({п['стадии'][номер]['состав_sha256'] for п in повторы}) == 1
        assert all(not п['стадии'][номер]['разрешение_установки'] for п in повторы)
    print(json.dumps({'новый_формат_тестов': новый_итог.testsRun, 'старый_P1_тестов': итог.testsRun, 'повторы': повторы,
        'медиана_процесса_нс': statistics.median(п['процесс_нс'] for п in повторы),
        'граница': 'Пары и полный индекс в памяти, с tracemalloc и синтетическими входами; без Git/native/API/установки. Старый P.1 проверяется отдельно до измерения.'},
        ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    главная()
