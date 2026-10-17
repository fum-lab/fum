"""Компактные пары K/candidate на одном W и в отдельных свежих процессах."""
import argparse
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import resource
import subprocess
import sys
import time
from unittest import mock


def помощник():
    путь = Path(__file__).with_name('test_свежести_внешнего_состава_ребёнка.py')
    описание = importlib.util.spec_from_file_location('сценарии_внешнего_состава', путь)
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = модуль; описание.loader.exec_module(модуль)
    return модуль


def измеренный_процесс(корень, файл):
    м = помощник(); фикстура, проверка = м.загрузить(корень)
    интервалы = []
    def метка(имя, настоящий):
        def вызов(*аргументы, **поля):
            начало = time.monotonic_ns()
            try:
                return настоящий(*аргументы, **поля)
            finally:
                интервалы.append({'стадия': имя,
                    'наносекунды': time.monotonic_ns() - начало})
        return вызов
    модуль = фикстура.связность
    for имя in ('проверить_контракт', 'проверить_свежесть',
            'проверить_слой_разметки', 'прочитать_состав'):
        setattr(модуль, имя, метка(имя, getattr(модуль, имя)))
    вывод = io.StringIO(); ошибки = io.StringIO()
    до = resource.getrusage(resource.RUSAGE_SELF); начало = time.monotonic_ns()
    with mock.patch.object(sys, 'argv', ['check-session-coherence.py',
            *json.loads(файл.read_bytes())]), contextlib.redirect_stdout(вывод), \
            contextlib.redirect_stderr(ошибки):
        код = проверка.main()
    длительность = time.monotonic_ns() - начало
    после = resource.getrusage(resource.RUSAGE_SELF)
    print(json.dumps({'код': код, 'API_наносекунды': длительность,
        'CPU_секунды': после.ru_utime + после.ru_stime - до.ru_utime - до.ru_stime,
        'максимальная_RSS_байтов': после.ru_maxrss if sys.platform == 'darwin'
            else после.ru_maxrss * 1024,
        'интервалы': интервалы, 'stdout': вывод.getvalue(), 'stderr': ошибки.getvalue()},
        ensure_ascii=False, sort_keys=True))
    return 0


def серии(параметры):
    м = помощник()
    with м.варианты(параметры.код_K, параметры.кандидат) as (корни, манифест):
        фикстура, _ = м.загрузить(корни['основа'])
        код_до = {имя: м.инвентарь(корень) for имя, корень in корни.items()}
        Git_до = {имя: м.граница_Git(корень) for имя, корень in корни.items()}
        исполнители_до = м.исходники_запуска()
        результаты = []
        for внешний in (False, True):
            with м.стенд(фикстура, внешний=внешний) as (р, писатель):
                файл = р.ф.каталог / 'равный-вход-профиля.json'
                файл.write_text(json.dumps(м.аргументы(р, писатель), ensure_ascii=False))
                внешние = [файл, р.ф.каталог / 'контракт-checker.json',
                    р.ф.каталог / 'выбор-checker.json', Path(р.п['сообщение'])]
                def внешняя_граница():
                    return {п.name: {'sha256': м.хэш(п.read_bytes()),
                        'режим': п.stat().st_mode & 0o777} for п in внешние}
                внешние_до = внешняя_граница()
                снимок = фикстура.снимок(р.ф.корень)
                сырые = (р.ф.корень / р.ж.ПУТЬ_СОСТАВА).read_bytes()
                вход = {'HEAD': р.ф.гит('rev-parse', 'HEAD').strip(),
                    'S': р.выбранный, 'raw_S_sha256': м.хэш(сырые),
                    'контракт_sha256': м.хэш((р.ф.каталог / 'контракт-checker.json').read_bytes()),
                    'сообщение_sha256': м.хэш(Path(р.п['сообщение']).read_bytes()),
                    'внешние_файлы': внешние_до,
                    'равные_байты_в_паре': True}
                пары = []
                for номер in range(параметры.пар):
                    порядок = ['основа', 'кандидат'] if номер % 2 == 0 else ['кандидат', 'основа']
                    пара = {'номер': номер + 1, 'порядок': порядок, 'измерения': {}}
                    for вариант in порядок:
                        if внешняя_граница() != внешние_до:
                            raise ValueError('дрейф внешних файлов перед вариантом')
                        начало = time.monotonic_ns()
                        процесс = subprocess.run([sys.executable, '-I', '-S', '-B',
                            str(Path(__file__).resolve()), '--измеренный-процесс', str(корни[вариант]),
                            '--аргументы', str(файл)], capture_output=True,
                            env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'}, timeout=60)
                        интервал_процесса = time.monotonic_ns() - начало
                        if процесс.returncode:
                            raise ValueError('отказ измерительного процесса: ' + процесс.stderr.decode())
                        замер = json.loads(процесс.stdout)
                        ожидаемый = 1 if внешний and вариант == 'основа' else 0
                        if замер['код'] != ожидаемый:
                            raise ValueError('неверный исход равного входа: ' + str(замер))
                        if фикстура.снимок(р.ф.корень) != снимок:
                            raise ValueError('измерение изменило вход W')
                        if внешняя_граница() != внешние_до:
                            raise ValueError('измерение изменило внешние файлы')
                        if any(м.инвентарь(путь) != код_до[имя]
                                for имя, путь in корни.items()):
                            raise ValueError('дрейф base/candidate исходников или зависимостей')
                        if м.исходники_запуска() != исполнители_до:
                            raise ValueError('дрейф исполнителей профиля')
                        if any(м.граница_Git(путь) != Git_до[имя]
                                for имя, путь in корни.items()):
                            raise ValueError('дрейф прочих данных или Git-состояния вариантов')
                        замер['процесс_wall_наносекунды'] = интервал_процесса
                        пара['измерения'][вариант] = замер
                    пары.append(пара)
                результаты.append({'сценарий': 'внешний raw S' if внешний else 'прежний S из HEAD',
                    'вход': вход, 'пары': пары})
        return {**манифест, 'схема': 'fum.профиль-свежести-внешнего-состава.1',
            'Python': sys.version.split()[0], 'платформа': sys.platform,
            'серии': результаты,
            'граница': 'Подготовка K/W исключена. Каждый вариант — отдельный -I -S -B процесс; '
                'wall включает запуск/импорты/main, API после импортов; вложенные интервалы не суммируются. '
                'Кэш ОС не очищается. RSS — максимум всего свежего процесса, CPU охватывает main.',
            'решение': 'Сохранить передачу ранее проверенного аргумента. Новый разбор S и ручное '
                'восстановление не нужны; число чтений состава проверяется по интервалам. '
                'Разный исход внешнего S запрещает трактовать разницу времени как ускорение.'}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--код-K', type=Path)
    разбор.add_argument('--кандидат', type=Path)
    разбор.add_argument('--выход', type=Path)
    разбор.add_argument('--пар', type=int, default=3)
    разбор.add_argument('--измеренный-процесс', type=Path)
    разбор.add_argument('--аргументы', type=Path)
    параметры = разбор.parse_args()
    if параметры.измеренный_процесс:
        if параметры.аргументы is None:
            разбор.error('нужны --аргументы')
        return измеренный_процесс(параметры.измеренный_процесс, параметры.аргументы)
    if параметры.код_K is None or параметры.кандидат is None or параметры.выход is None:
        разбор.error('нужны --код-K, --кандидат и --выход')
    if not 1 <= параметры.пар <= 7:
        разбор.error('нужно от одной до семи пар')
    итог = серии(параметры)
    параметры.выход.write_text(json.dumps(итог, ensure_ascii=False,
        sort_keys=True, indent=2) + '\n')
    print(json.dumps({'схема': итог['схема'], 'серий': len(итог['серии']),
        'пар_в_серии': параметры.пар, 'исход': 'успешно'}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
