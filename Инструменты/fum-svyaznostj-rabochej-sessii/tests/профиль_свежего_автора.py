"""Три свежих процесса: новый Codex, ранний отказ и буквальный replay."""
import argparse
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time

import test_создание_коммита as база
import test_свежего_автора as проверки


def образец():
    ф = база.СозданиеКоммита(); ф.setUp()
    стадии = {}
    def измерить(имя, действие):
        начало = time.perf_counter_ns()
        try: return действие()
        finally: стадии[имя] = time.perf_counter_ns() - начало
    try:
        измерить('подготовка', lambda: база.коммит.подготовить(ф.параметры))
        # Индекс и настоящая v4 фикстуры подготовлены вне внутренних таймеров.
        ф.гит('add', '.')
        with contextlib.redirect_stdout(io.StringIO()):
            код = ф.отчёты.выполнить_запуск(ф.корень, ф.запрос, 'Байты профиля автора', 'фикстура', база.ЗАПУСК, 15,
                [sys.executable, '-c', "from pathlib import Path; assert Path('данные.txt').read_text() == 'проверено\\n'"],
                класс_проверки='адресная', приёмочные_раунды=True)
            assert код == 0
            ф.отчёты.выполнить_предпросмотр(ф.корень, ф.запрос)
        ф.гит('add', str(Path(база.ЗАПРОС).parent))
        измерить('готовность', lambda: база.коммит.объявить_готовность(Path(ф.параметры['подготовка']), [база.ЗАПУСК], 600))
        итог = измерить('создание', ф.создать)
        assert итог['автор'].startswith('FUM Codex [gpt-6-astra; effort=ultra] <')
        проверка = проверки.СвежийАвтор()
        исторический = проверка.исторический_результат(ф, созданный=итог)
        до = проверка.снимок(ф)
        файл = Path(ф.параметры['квитанция']); ст = файл.stat(); сырые = файл.read_bytes()
        повтор = измерить('исторический_повтор', ф.создать)
        assert исторический == повтор and до == проверка.снимок(ф)
        после = файл.stat()
        assert (ст.st_mode, ст.st_mtime_ns, ст.st_ino, сырые) == (после.st_mode, после.st_mtime_ns, после.st_ino, файл.read_bytes())
        # Новый процесс для буквального повтора прежнего автора.
        начало = time.perf_counter_ns()
        процесс = subprocess.run(ф.команда_CLI('создать', '--подготовка', ф.параметры['подготовка'], '--проверка', база.ЗАПУСК), capture_output=True, text=True, check=True)
        стадии['повтор_отдельным_процессом'] = time.perf_counter_ns() - начало
        assert json.loads(процесс.stdout) == повтор and до == проверка.снимок(ф)
        параметры = dict(ф.параметры, имя_автора='FUM Разработчик')
        def отказ():
            try: база.коммит.подготовить(параметры)
            except база.коммит.ОшибкаКоммита as ошибка:
                assert 'FUM Codex' in str(ошибка)
            else: raise AssertionError('Новая старая роль допущена')
        измерить('ранний_отказ', отказ)
        assert до == проверка.снимок(ф)
        import test_подготовки_дочернего_поручения as генератор
        стенд = генератор.ПодготовкаПоручения(); стенд.setUp()
        try:
            план = измерить('генератор_поручения', lambda: стенд.м.построить_план(стенд.вход))
            вход = план['технические_входы']['коммит']
            assert вход['имя_автора'] == 'FUM Codex' and 'Специализация: Интегратор.' in вход['описание']
        finally: стенд.doCleanups()
        каталог_нормы = Path(__file__).resolve().parents[2] / 'fum-dekompoziciya-pravil-agentov/tests'
        sys.path.insert(0, str(каталог_нормы))
        import test_имени_агентского_автора as нормы
        стенд_нормы = нормы.ИмяАгентскогоАвтора(); стенд_нормы.setUp()
        try:
            стенд_нормы.включить()
            допуск = измерить('семантическая_норма', lambda: стенд_нормы.стенд.запустить('проверить'))
            assert допуск.returncode == 0, допуск.stderr
        finally: стенд_нормы.doCleanups()
        return {'процесс': os.getpid(), 'стадии_нс': стадии, 'автор': итог['автор'],
            'исторический_автор': повтор['автор'], 'повтор_неизменен': True,
            'квитанция_sha256': hashlib.sha256(сырые).hexdigest(),
            'индекс_sha256': hashlib.sha256(до['индекс']).hexdigest(),
            'отказ_без_эффектов': True}
    finally: ф.doCleanups()


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--образец', action='store_true')
    разбор.add_argument('--выход', type=Path)
    аргументы = разбор.parse_args()
    if аргументы.образец:
        print(json.dumps(образец(), ensure_ascii=False)); return
    if аргументы.выход is None or not аргументы.выход.is_absolute() or аргументы.выход != аргументы.выход.resolve():
        разбор.error('Нужен новый абсолютный физический выход вне Git')
    if any(os.path.lexists(п / '.git') for п in аргументы.выход.parents): разбор.error('Профиль сохраняется вне Git')
    корень = Path(__file__).resolve().parents[3]
    пути = ['Инструменты/fum-svyaznostj-rabochej-sessii/scripts/' + п for п in
        ('автор_коммита.py', 'создание_коммита.py', 'подготовка_дочернего_поручения.py')]
    пути += [str(Path(__file__).resolve().relative_to(корень)),
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_свежего_автора.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_создание_коммита.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_подготовки_дочернего_поручения.py',
        'Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py',
        'Инструменты/fum-dekompoziciya-pravil-agentov/scripts/ветка_состояния_узла.py',
        'Инструменты/fum-dekompoziciya-pravil-agentov/tests/test_имени_агентского_автора.py']
    хэши = {п: hashlib.sha256((корень / п).read_bytes()).hexdigest() for п in пути}
    измерения = [json.loads(subprocess.check_output([sys.executable, '-B', str(Path(__file__).resolve()), '--образец'], text=True)) for _ in range(3)]
    assert len({и.pop('процесс') for и in измерения}) == 3
    assert хэши == {п: hashlib.sha256((корень / п).read_bytes()).hexdigest() for п in пути}
    результат = {'схема': 'fum.профиль-свежего-автора.1', 'процессов': 3,
        'граница': 'Три независимых процесса; setup, v4 фикстуры, индекс и преобразование исторического объекта исключены из внутренних таймеров. Кэш ОС не сбрасывается.',
        'ограничения': 'Синтетический native и малый Git; профиль не измеряет ROOT, полный smoke или production-приёмку.',
        'исходники_sha256': хэши, 'измерения': измерения,
        'медианы_нс': {к: int(statistics.median(и['стадии_нс'][к] for и in измерения)) for к in измерения[0]['стадии_нс']}}
    with os.fdopen(os.open(аргументы.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'w') as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2); поток.write('\n'); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'процессов': 3, 'медианы_нс': результат['медианы_нс']}, ensure_ascii=False))


if __name__ == '__main__': главная()
