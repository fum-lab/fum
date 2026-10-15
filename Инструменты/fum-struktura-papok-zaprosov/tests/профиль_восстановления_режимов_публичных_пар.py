"""Три новых процесса; Git-фикстуры исключены, apply и repeat в разных PID."""
import argparse
import cProfile
import hashlib
import json
import os
from pathlib import Path
import pstats
import statistics
import subprocess
import sys
import time
from unittest.mock import patch

from test_восстановления_режимов_публичных_пар import Фикстура, ИСХОДНИКИ, КОРЕНЬ, наблюдение


def состав():
    имена = (*ИСХОДНИКИ,
        'Инструменты/fum-struktura-papok-zaprosov/tests/test_request_folder_layout.py',
        'Инструменты/fum-struktura-papok-zaprosov/tests/test_установки_принятого_состава_журнала.py',
        'Инструменты/fum-struktura-papok-zaprosov/tests/test_восстановления_режимов_публичных_пар.py',
        'Инструменты/fum-struktura-papok-zaprosov/tests/профиль_восстановления_режимов_публичных_пар.py')
    return {имя: hashlib.sha256((КОРЕНЬ / имя).read_bytes()).hexdigest() for имя in имена}


def работник():
    до = состав()
    подготовка = time.perf_counter_ns()
    with patch.dict(os.environ, {'CODEX_THREAD_ID': '00000000-0000-0000-0000-000000000001'}):
        ф = Фикстура()
        подготовка = time.perf_counter_ns() - подготовка
        try:
            замеры = {}
            профилировщик = cProfile.Profile()
            начало = time.perf_counter_ns()
            профилировщик.enable(); план = ф.план(); профилировщик.disable()
            замеры['план_нс'] = time.perf_counter_ns() - начало
            начало = time.perf_counter_ns()
            первый = ф.работник(план)
            вывод, ошибка = первый.communicate(timeout=60)
            замеры['применение_процесс_нс'] = time.perf_counter_ns() - начало
            if первый.returncode != 0:
                raise RuntimeError(ошибка)
            применение = json.loads(вывод)
            завершение = ф.завершение(первый)
            дерево, приватное = наблюдение(ф.корень), наблюдение(ф.каталог)
            начало = time.perf_counter_ns()
            второй = ф.работник(план, режим='повтор', завершение=завершение)
            вывод, ошибка = второй.communicate(timeout=60)
            замеры['повтор_процесс_нс'] = time.perf_counter_ns() - начало
            if второй.returncode != 0:
                raise RuntimeError(ошибка)
            повтор = json.loads(вывод)
            assert применение['записей'] == 8 and повтор['повтор'] and повтор['записей'] == 0
            assert len({первый.pid, второй.pid, os.getpid()}) == 3
            assert наблюдение(ф.корень) == дерево and наблюдение(ф.каталог) == приватное and состав() == до
            строки = []
            for (путь, номер, имя), (_, вызовы, _, полное, _) in pstats.Stats(профилировщик).stats.items():
                if Path(путь).is_absolute() and Path(путь).is_relative_to(КОРЕНЬ):
                    строки.append({'путь': Path(путь).relative_to(КОРЕНЬ).as_posix(), 'строка': номер,
                        'функция': имя, 'вызовы': вызовы, 'полное_нс': round(полное * 1_000_000_000)})
            return {'процесс': os.getpid(), 'писатель': первый.pid, 'повторитель': второй.pid,
                'подготовка_нс_исключена': подготовка, 'замеры': замеры,
                'применение': применение, 'повтор': повтор,
                'план_профиль': sorted(строки, key=lambda з: з['полное_нс'], reverse=True)[:12],
                'исходники_до': до, 'исходники_после': состав(), 'сохранено_без_эффектов_повтора': True}
        finally:
            ф.закрыть()


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--работник', action='store_true')
    разбор.add_argument('--выход', type=Path)
    параметры = разбор.parse_args()
    if параметры.работник:
        print(json.dumps(работник(), ensure_ascii=False, sort_keys=True)); return
    if параметры.выход is None:
        разбор.error('нужен новый файл --выход')
    до = состав()
    результаты = []
    for _ in range(3):
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--работник'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=120, check=True)
        результаты.append(json.loads(процесс.stdout))
    assert len({з['процесс'] for з in результаты}) == 3 and состав() == до
    итог = {'схема': 'fum.профиль-восстановления-режимов-пар.1',
        'граница': 'Три новых процесса на восьми tracked600 в малых Git-историях. Подготовка и запись профиля исключены. '
            'План включает cProfile; применение и повтор включают запуск и wait новых процессов. '
            'Внешнее завершение сохраняется вне замера повтора. Живой ROOT не изменяется.',
        'наблюдения': результаты, 'медианы_нс': {имя: statistics.median(з['замеры'][имя] for з in результаты)
            for имя in результаты[0]['замеры']}, 'исходники_до': до, 'исходники_после': состав()}
    with параметры.выход.open('xb') as файл:
        файл.write((json.dumps(итог, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode())
    print(json.dumps({'схема': итог['схема'], 'медианы_нс': итог['медианы_нс']}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
