"""Парные открытые входы; вложенные стадии не суммируются."""
import argparse
from contextlib import ExitStack
from dataclasses import fields, is_dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import sys
import tempfile
import time
import tracemalloc
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from test_check_session_coherence import check_session_coherence as прежняя
import снимок_связности as новая


def доступная_память():
    try:
        страницы = os.sysconf('SC_AVPHYS_PAGES')
        размер = os.sysconf('SC_PAGE_SIZE')
        return {'метод': 'sysconf SC_AVPHYS_PAGES * SC_PAGE_SIZE; свободные страницы', 'байты': страницы * размер}
    except (ValueError, OSError):
        if sys.platform != 'darwin': return {'метод': 'не доступен на этом host', 'байты': None}
    текст = subprocess.run(['vm_stat'], check=True, capture_output=True, text=True).stdout
    размер = int(re.search(r'page size of (\d+) bytes', текст).group(1))
    страницы = sum(int(re.search(re.escape(ключ) + r':\s+(\d+)', текст).group(1))
        for ключ in ('Pages free', 'Pages inactive', 'Pages speculative'))
    return {'метод': 'vm_stat: (free + inactive + speculative) * page size; оценка, не гарантия', 'байты': страницы * размер}


def состав_байтов(снимок):
    объекты = {}
    ссылочные = 0
    def пройти(значение):
        nonlocal ссылочные
        if type(значение) is bytes:
            ссылочные += len(значение);объекты[id(значение)] = len(значение)
        elif type(значение) is tuple:
            for часть in значение: пройти(часть)
        elif is_dataclass(значение):
            for поле in fields(значение): пройти(getattr(значение, поле.name))
    пройти(снимок)
    return {'по_ссылкам': ссылочные, 'уникальные_объекты': sum(объекты.values()),
        'граница': 'только payload bytes в snapshot; контейнеры и Python heap измерены tracemalloc отдельно'}


def измерить(функция):
    счётчики = {'каталоговые_обращения': 0, 'Git_вызовы': 0}
    исходный_каталог = Path.iterdir
    исходный_процесс = subprocess.run
    def каталог(путь):
        счётчики['каталоговые_обращения'] += 1
        return исходный_каталог(путь)
    def процесс(аргументы, *другие, **именованные):
        if аргументы and аргументы[0] == 'git': счётчики['Git_вызовы'] += 1
        return исходный_процесс(аргументы, *другие, **именованные)
    with ExitStack() as стек:
        стек.enter_context(mock.patch.object(Path, 'iterdir', каталог))
        стек.enter_context(mock.patch.object(subprocess, 'run', процесс))
        tracemalloc.start()
        начало = time.perf_counter_ns()
        результат = функция()
        длительность = time.perf_counter_ns() - начало
        текущая, пик = tracemalloc.get_traced_memory()
        tracemalloc.stop()
    return результат, {'наносекунды': длительность, **счётчики,
        'Python_текущая_память': текущая, 'Python_пиковая_память': пик}


def фикстура(корень, число):
    документы = корень / 'Docs';документы.mkdir()
    (документы/'цель.txt').write_text('цель')
    (корень/'внецелевой.md').write_text('вне целевого состава')
    выбранные = []
    for номер in range(число):
        путь = f'вход-{номер:04d}.md'
        (корень/путь).write_text('[да](Docs/цель.txt)\n[нет](Docs/отсутствует.txt)\n[URL](https://example.invalid)\n')
        выбранные.append(путь)
    for номер in range(число * 2): (документы/f'сосед-{номер:04d}.txt').write_text('сосед')
    subprocess.run(['git', '-C', str(корень), 'init', '--quiet'], check=True, capture_output=True)
    subprocess.run(['git', '-C', str(корень), 'add', '.'], check=True, capture_output=True)
    return tuple(выбранные)


def серия(число, повторы):
    with tempfile.TemporaryDirectory() as каталог:
        корень = Path(каталог).resolve()
        выбранные = фикстура(корень, число)
        пути = {корень/элемент for элемент in выбранные}
        ожидаемый = tuple(прежняя.validate_markdown_links(пути, корень))
        # Прогрев и подготовка исключены из таймеров обеих сторон.
        прогрев = новая.собрать(корень, выбранные)
        assert новая.проверить(прогрев) == ожидаемый
        def последовательность():
            снимок = новая.собрать(корень, выбранные)
            исход = новая.вычислить(снимок)
            assert новая.сверить(снимок, исход)
            return исход.ошибки
        строки = []
        for номер in range(повторы):
            прежний_замер = None
            if номер % 2 == 0:
                ответ, прежний_замер = измерить(lambda: tuple(прежняя.validate_markdown_links(пути, корень)))
                assert ответ == ожидаемый
            снимок, сбор = измерить(lambda: новая.собрать(корень, выбранные))
            исход, чистая = измерить(lambda: новая.вычислить(снимок))
            assert исход.ошибки == ожидаемый
            _, живая = измерить(lambda: новая.сверить(снимок, исход))
            ответ, полная = измерить(последовательность)
            assert ответ == ожидаемый
            if прежний_замер is None:
                ответ, прежний_замер = измерить(lambda: tuple(прежняя.validate_markdown_links(пути, корень)))
                assert ответ == ожидаемый
            строки.append({'сбор': сбор, 'чистая': чистая, 'живая': живая,
                'последовательность': полная, 'прежняя': прежний_замер})
        return {'число_Markdown': число + 1, 'выбранных': число,
            'ссылок': число * 3, 'повторы': повторы,
            'исход_sha256': hashlib.sha256(json.dumps(ожидаемый, ensure_ascii=False).encode()).hexdigest(),
            'удержанные_байты': состав_байтов(прогрев), 'измерения': строки,
            'медианы_наносекунд': {имя: int(statistics.median(элемент[имя]['наносекунды'] for элемент in строки))
                for имя in ('сбор', 'чистая', 'живая', 'последовательность', 'прежняя')}}


def исходники():
    пути = (*новая.ПУТИ_КОДА, str(Path(__file__).resolve().relative_to(новая.КОРЕНЬ)),
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_снимка_связности.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py')
    return {элемент: hashlib.sha256((новая.КОРЕНЬ/элемент).read_bytes()).hexdigest() for элемент in пути}


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выход', type=Path, required=True)
    разбор.add_argument('--повторы', type=int, default=3)
    параметры = разбор.parse_args()
    if параметры.повторы < 1: разбор.error('число повторов должно быть положительным')
    коды = исходники()
    память = доступная_память()
    результат = {'схема': 'fum.профиль-снимка-ссылок.1', 'память_до_серии': память,
        'метод': 'perf_counter_ns + локальные счётчики + tracemalloc; setup и прогрев исключены; каталоговые обращения=Path.iterdir (не системные вызовы); Git=вызовы subprocess.run git',
        'граница': 'сбор включает заключительную сверку; живая сверка с результатом включает чистую перепроверку; эти вложенные интервалы не суммируются. Полная последовательность измерена независимо. Нет вывода об ускорении ready/creator.',
        'малый': серия(4, параметры.повторы), 'широкий': серия(128, параметры.повторы),
        'исходники_sha256_до': коды, 'исходники_sha256_после': исходники()}
    assert результат['исходники_sha256_после'] == коды
    with параметры.выход.open('x', encoding='utf-8') as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
    print(json.dumps({элемент: результат[элемент]['медианы_наносекунд'] for элемент in ('малый', 'широкий')}, ensure_ascii=False))


if __name__ == '__main__': выполнить()
