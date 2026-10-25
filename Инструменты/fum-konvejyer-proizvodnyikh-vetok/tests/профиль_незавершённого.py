"""Профиль чтения Git и приватного сохранения на открытой фикстуре."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import tempfile
import time

from test_пакета_незавершённого import фикстура, пакет, гит, ЗАДАЧА, КАТАЛОГИ
import хранилище_незавершённого as хранилище


def измерить():
    измерения = []
    for объём in (4096, 1048576):
        времена = {имя: [] for имя in ('сбор', 'сохранение', 'чтение')}
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            путь = корень / 'Память/слой/данные'
            путь.write_bytes(b'a' * объём)
            гит(корень, 'add', '--', 'Память/слой/данные')
            путь.write_bytes(b'b' * объём)
            до = гит(корень, 'ls-files', '--stage', '-z')
            for номер in range(5):
                начало = time.perf_counter_ns()
                план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
                времена['сбор'].append(time.perf_counter_ns() - начало)
                цель = Path(временный).resolve() / str(номер)
                начало = time.perf_counter_ns()
                хранилище.сохранить(цель, план, данные)
                времена['сохранение'].append(time.perf_counter_ns() - начало)
                начало = time.perf_counter_ns()
                прочитано = хранилище.прочитать(цель, план['sha256'])
                времена['чтение'].append(time.perf_counter_ns() - начало)
                if прочитано != (план, данные) or гит(корень, 'ls-files', '--stage', '-z') != до:
                    raise AssertionError('Пакет или индекс изменились')
            измерения.append({'байтов_в_версии': объём, 'байтов_объектов': sum(map(len, данные.values())),
                'повторов': 5, 'байты_совпали': True,
                'стадии': {имя: {'медиана_наносекунды': statistics.median(замеры),
                    'минимум_наносекунды': min(замеры), 'максимум_наносекунды': max(замеры)}
                    for имя, замеры in времена.items()}})
    модули = {'пакет': пакет, 'хранилище': хранилище, 'снимок': пакет.снимок_области, 'git': пакет.хранение}
    return {'схема': 'fum.профиль-незавершённых-результатов.1', 'измерения': измерения,
        'исходники_sha256': {имя: hashlib.sha256(Path(модуль.__file__).read_bytes()).hexdigest()
                            for имя, модуль in модули.items()},
        'граница': 'Открытая Git-фикстура: сбор, запись с fsync и повторным чтением, отдельное чтение. '
                   'Создание фикстуры и импорт исключены; нативное назначение, остановка, Desktop и интеграция не измеряются.'}


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', type=Path, required=True)
    параметры = парсер.parse_args()
    итог = измерить()
    with параметры.выход.open('x', encoding='utf-8') as поток:
        поток.write(json.dumps(итог, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(итог, ensure_ascii=False))
