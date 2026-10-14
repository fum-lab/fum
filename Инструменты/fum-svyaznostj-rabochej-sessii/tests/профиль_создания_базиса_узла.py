"""Три свежих процесса читающей сверки на независимых Git-фикстурах."""
import argparse
import cProfile
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import pstats
import subprocess
import sys
import time


КОРЕНЬ = Path(__file__).resolve().parents[3]
ПРОФИЛЬ = Path(__file__).resolve()
ТЕСТЫ = ПРОФИЛЬ.with_name('test_создания_базиса_узла.py')
ДОПУСК = ПРОФИЛЬ.parent.parent / 'scripts/допуск_создания_базиса_узла.py'


def отпечатки_исходников():
    return {п.relative_to(КОРЕНЬ).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest()
            for п in (ПРОФИЛЬ, ТЕСТЫ, ДОПУСК)}


def один_процесс():
    исходники = отпечатки_исходников()
    начало = time.perf_counter_ns()
    описание = importlib.util.spec_from_file_location('фикстура_профиля_базиса', ТЕСТЫ)
    модуль = importlib.util.module_from_spec(описание)
    описание.loader.exec_module(модуль)
    загрузка = time.perf_counter_ns()
    фикстура = модуль.ФикстураБазиса()
    try:
        допуск = модуль.загрузить_допуск()
        до = фикстура.снимок()
        подготовка = time.perf_counter_ns()
        измеритель = cProfile.Profile()
        измеритель.enable()
        результат = допуск.сверить_индекс(фикстура.корень, фикстура.предмет)
        измеритель.disable()
        завершение = time.perf_counter_ns()
        assert результат['дерево'] == фикстура.дерево_фикстуры
        assert до == фикстура.снимок(), 'Читающая сверка изменила Git-фикстуру'
        assert исходники == отпечатки_исходников(), 'Исходники изменились в свежем процессе'
        проверка = time.perf_counter_ns()
        функции = []
        for (файл, строка, имя), (простые, вызовы, собственное, полное, _) in pstats.Stats(измеритель).stats.items():
            if файл == str(ДОПУСК):
                функции.append({'имя': имя, 'строка': строка, 'простые_вызовы': простые,
                                'вызовы': вызовы, 'собственное_с': собственное, 'полное_с': полное})
        return {'схема': 'fum.процесс-профиля-индекса-базиса.1', 'исходники': исходники,
                'предмет': фикстура.предмет, 'результат': результат,
                'стадии_нс': {'загрузка_фикстуры': загрузка - начало,
                              'подготовка_фикстуры': подготовка - загрузка,
                              'читающий_допуск': завершение - подготовка,
                              'проверка_неизменности': проверка - завершение},
                'функции': sorted(функции, key=lambda ф: (-ф['полное_с'], ф['имя'])),
                'состояние_фикстуры_сохранено': True, 'версия_интерпретатора': sys.version.split()[0],
                'версия_системы_контроля_версий': фикстура.гит('--version').strip()}
    finally:
        фикстура.закрыть()


def сохранить(путь, данные):
    путь = Path(путь)
    if (not путь.is_absolute() or путь != путь.resolve()
            or any((п / '.git').exists() for п in путь.parents)):
        raise ValueError('Профиль сохраняется по физическому адресу вне Git')
    дескриптор = os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(дескриптор, 'wb') as поток:
        поток.write(данные)
        поток.flush()
        os.fsync(поток.fileno())


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--дочерний', action='store_true')
    разбор.add_argument('--выход', type=Path)
    вход = разбор.parse_args()
    if вход.дочерний:
        if вход.выход is not None:
            разбор.error('Свежий процесс возвращает только stdout')
        print(json.dumps(один_процесс(), ensure_ascii=False, sort_keys=True))
        return
    if вход.выход is None:
        разбор.error('Нужен новый внешний файл профиля')
    исходники = отпечатки_исходников()
    среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
    среда.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull)
    процессы = []
    for номер in range(3):
        начало = time.perf_counter_ns()
        процесс = subprocess.run([sys.executable, '-I', '-S', '-B', str(ПРОФИЛЬ), '--дочерний'],
            env=среда, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60, check=True)
        длительность = time.perf_counter_ns() - начало
        результат = json.loads(процесс.stdout)
        assert результат['исходники'] == исходники == отпечатки_исходников()
        assert результат['состояние_фикстуры_сохранено'] is True
        assert процесс.stderr == b'', 'Неожиданный stderr свежего процесса'
        процессы.append({'номер': номер + 1, 'процесс_нс': длительность, 'измерение': результат})
    результат = {'схема': 'fum.профиль-индекса-базиса.1', 'исходники': исходники,
        'граница': 'Три независимых свежих процесса Python. Подготовка временного Git, читающий допуск '
                   'с cProfile и проверка неизменности измерены отдельно. Кэш ОС не очищается. '
                   'Создание B, typed-v4, intent/receipt и общая ODB не измеряются.',
        'процессы': процессы}
    данные = (json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    сохранить(вход.выход, данные)
    print(json.dumps({'процессов': 3, 'sha256': hashlib.sha256(данные).hexdigest(),
                     'допуск_нс': [п['измерение']['стадии_нс']['читающий_допуск'] for п in процессы]},
                    ensure_ascii=False))


if __name__ == '__main__':
    главная()
