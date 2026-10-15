"""Три свежих процесса: прежний/новый consumer 0644 и новый 0600 на одном H/S.

Измеряется только читающий инвентарь малой Git-фикстуры. Подготовка, Git-коммиты
фикстуры, контроль отсутствия эффектов и запись результата исключены из замера.
Это не профиль производственного ROOT, Creator или холодного файлового кэша.
"""
import argparse
import hashlib
import json
from pathlib import Path
import resource
import statistics
import subprocess
import sys
import time
import tracemalloc
import types

import test_исторических_режимов_разметки as сценарии

КОРЕНЬ = Path(__file__).resolve().parents[3]
ИСХОДНИК = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/связность_независимого_журнала.py'
ОСНОВА = 'd709e84d40cf095e0c710e3542c6863f2304ab83'


def источники():
    пути = [ИСХОДНИК,
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/контракт_независимого_журнала.py',
        'Инструменты/fum-struktura-papok-zaprosov/scripts/независимый_журнал.py',
        Path(__file__).relative_to(КОРЕНЬ).as_posix(),
        Path(сценарии.__file__).relative_to(КОРЕНЬ).as_posix()]
    return {п: hashlib.sha256((КОРЕНЬ / п).read_bytes()).hexdigest() for п in пути}


def рабочий(номер):
    до_кода = источники()
    сырые = subprocess.check_output(['git', '--no-optional-locks', '-C', str(КОРЕНЬ),
        'show', ОСНОВА + ':' + ИСХОДНИК])
    # Исполняются точные принятые байты C, с теми же неизменёнными зависимостями.
    # __file__ сохраняет канонический адрес для разрешения импортов consumer.
    прежний = types.ModuleType('прежняя_связность_профиля')
    прежний.__file__ = str(КОРЕНЬ / ИСХОДНИК)
    exec(compile(сырые, прежний.__file__, 'exec'), прежний.__dict__)
    for путь in list(до_кода)[1:3]:
        принятые = subprocess.check_output(['git', '--no-optional-locks', '-C', str(КОРЕНЬ),
            'show', ОСНОВА + ':' + путь])
        assert hashlib.sha256(принятые).hexdigest() == до_кода[путь], 'изменена общая зависимость профиля'
    замеры = []
    for права in (0o644, 0o600):
        with сценарии.стенд(права) as (фикс, имя, файл, состав):
            снимок = сценарии.снимок_без_эффектов(фикс.root)
            варианты = [('новый', сценарии.связность)]
            if права == 0o644:
                варианты.insert(0, ('прежний', прежний))
                if номер % 2: варианты.reverse()
            ожидаемые = None
            for название, модуль in варианты:
                tracemalloc.start()
                начало_процессора = time.process_time_ns(); начало = time.perf_counter_ns()
                результат = модуль.инвентарь_разметки(фикс.root)
                длительность = time.perf_counter_ns() - начало
                процессорное_время = time.process_time_ns() - начало_процессора
                _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
                assert имя in результат
                имена = sorted(результат)
                if ожидаемые is None: ожидаемые = имена
                assert имена == ожидаемые, 'результаты сравниваемых инвентарей различаются'
                замеры.append({'вариант': название, 'права': oct(права),
                    'наносекунды': длительность, 'процессорные_наносекунды': процессорное_время,
                    'пик_памяти_интерпретатора_байты': пик, 'файлов_разметки': len(имена)})
            assert снимок == сценарии.снимок_без_эффектов(фикс.root), 'повтор изменил историю или Git'
    assert до_кода == источники(), 'исходники изменились во время профиля'
    return {'процесс': номер, 'замеры': замеры, 'без_исторических_эффектов': True,
        'прежний_коммит': ОСНОВА, 'хэш_прежнего_кода': hashlib.sha256(сырые).hexdigest(),
        'исходники': до_кода, 'пиковая_резидентная_память': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--рабочий', type=int)
    разбор.add_argument('--выход')
    параметры = разбор.parse_args()
    if параметры.рабочий is not None:
        print(json.dumps(рабочий(параметры.рабочий), ensure_ascii=False, sort_keys=True))
        return
    assert параметры.выход and not Path(параметры.выход).exists(), 'нужен новый файл результата'
    до = источники(); процессы = []
    for номер in range(3):
        ответ = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()),
            '--рабочий', str(номер)], capture_output=True, timeout=90)
        assert ответ.returncode == 0, ответ.stderr.decode()
        процессы.append(json.loads(ответ.stdout))
    assert до == источники() and all(п['исходники'] == до for п in процессы)
    медианы = {}
    for вариант, права in (('прежний', '0o644'), ('новый', '0o644'), ('новый', '0o600')):
        медианы[вариант + '_' + права] = statistics.median(
            з['наносекунды'] for п in процессы for з in п['замеры']
            if з['вариант'] == вариант and з['права'] == права)
    итог = {'схема': 'fum.профиль-исторических-режимов-разметки.1',
        'граница': 'Малый инвентарь H/S; без подготовки, Creator, ROOT и холодного кэша ОС',
        'процессы': процессы, 'медианы_наносекунды': медианы,
        'решение': 'Сохранить проверки identity и точного H/S; ускорение ROOT требует отдельного измерения'}
    with Path(параметры.выход).open('x') as файл:
        json.dump(итог, файл, ensure_ascii=False, sort_keys=True, indent=2); файл.write('\n')
    print(json.dumps({'процессов': len(процессы), 'медианы_наносекунды': медианы}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
