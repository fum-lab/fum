"""Пять сопоставимых сборок с двумя допустимыми формами ссылки горизонта."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import sys
import tempfile
import time

import test_build_planning_registry as основа


def байты(данные):
    return (json.dumps(данные, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n').encode('utf-8')


def измерить():
    код = Path(__file__).resolve().parents[1]
    версии = {
        имя: hashlib.sha256((код / имя).read_bytes()).hexdigest()
        for имя in ('scripts/build-planning-registry.py', 'tests/test_build_planning_registry.py',
                    'tests/test_покрытие_ссылок_дорожной_карты.py', 'tests/измерить_ссылки_горизонтов.py')
    }
    результаты = []
    семантический_хэш = None
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный)
        основа.BuildPlanningRegistryTests().write_fixture(корень)
        карта = корень / 'Планирование/дорожная-карта.md'
        оригинал = карта.read_text(encoding='utf-8')
        if оригинал.count('](#горизонт-') != 9:
            raise ValueError('Фикстура должна содержать девять локальных якорей')
        for имя, текст in (
            ('локальный-якорь', оригинал),
            ('собственный-файл', оригинал.replace('](#горизонт-', '](дорожная-карта.md#горизонт-')),
        ):
            карта.write_text(текст, encoding='utf-8')
            исходные = hashlib.sha256(карта.read_bytes()).hexdigest()
            длительности, проверки = [], []
            точные_байты = None
            for _ in range(5):
                начало = time.monotonic_ns()
                реестр = основа.build_planning_registry.build_registry(корень)
                длительности.append(time.monotonic_ns() - начало)
                начало = time.monotonic_ns()
                ошибки = основа.build_planning_registry.validate_registry_object(реестр)
                проверки.append(time.monotonic_ns() - начало)
                if ошибки:
                    raise ValueError('\n'.join(ошибки))
                текущие = байты(реестр)
                if точные_байты is None:
                    точные_байты = текущие
                elif текущие != точные_байты:
                    raise ValueError('Повторная сборка изменила результат')
                хэш = hashlib.sha256(байты({к: з for к, з in реестр.items() if к != 'source_files'})).hexdigest()
                if семантический_хэш is None:
                    семантический_хэш = хэш
                elif хэш != семантический_хэш:
                    raise ValueError('Форма ссылки изменила содержательное покрытие')
                if hashlib.sha256(карта.read_bytes()).hexdigest() != исходные:
                    raise ValueError('Сборка записала исходную дорожную карту')
            результаты.append({'форма': имя, 'источник_sha256': исходные,
                'реестр_sha256': hashlib.sha256(точные_байты).hexdigest(),
                'сборки_нс': длительности, 'медиана_сборки_нс': int(statistics.median(длительности)),
                'валидации_нс': проверки})
    if any(hashlib.sha256((код / имя).read_bytes()).hexdigest() != хэш for имя, хэш in версии.items()):
        raise ValueError('Версия кода изменилась во время измерения')
    return {'схема': 'fum.профиль-ссылок-горизонтов.1', 'версия_питона': sys.version.split()[0],
        'версии': версии, 'повторов': 5, 'подготовка_включена': False,
        'содержательное_покрытие_sha256': семантический_хэш, 'результаты': результаты,
        'ограничения': 'Малая фикстура; хэши source_files закономерно различаются. Старый код отказал, '
                       'поэтому коэффициент ускорения не рассчитывается. Профиль не измеряет весь FUM.'}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выход', type=Path, required=True)
    аргументы = разбор.parse_args()
    результат = байты(измерить())
    with os.fdopen(os.open(аргументы.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'wb') as файл:
        файл.write(результат)
        файл.flush()
        os.fsync(файл.fileno())
    print(json.dumps({'схема': 'fum.профиль-ссылок-горизонтов.1', 'байтов': len(результат)}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
