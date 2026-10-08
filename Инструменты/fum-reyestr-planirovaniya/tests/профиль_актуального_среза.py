#!/usr/bin/env python3
"""Измерить чтение одного конечного состава; подготовка Git вне интервалов."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import tempfile
import time

from test_актуальный_срез import загрузить_модуль, подготовить_фикстуру, зафиксировать


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--выход', required=True, type=Path)
    разбор.add_argument('--повторы', type=int, default=7)
    вход = разбор.parse_args()
    if not 3 <= вход.повторы <= 15:
        разбор.error('нужно от 3 до 15 повторов')
    with os.fdopen(os.open(вход.выход, os.O_CREAT | os.O_EXCL | os.O_WRONLY | os.O_NOFOLLOW, 0o600),
                   'w', encoding='utf-8') as выход:
        профиль = измерить_профиль(вход)
        выход.write(json.dumps(профиль, ensure_ascii=False, sort_keys=True, indent=2) + '\n')
        print(json.dumps(профиль['медианы'], ensure_ascii=False, sort_keys=True))


def измерить_профиль(вход):
    пакет = Path(__file__).resolve().parents[1]
    имена_кода = ['scripts/актуальный_срез.py', 'scripts/актуальный-срез.py',
        'scripts/build-planning-registry.py', 'tests/фикстуры/актуальный-срез.json',
        'tests/профиль_актуального_среза.py', 'tests/test_актуальный_срез.py',
        '../fum-ocenki/scripts/срез_гит_обзора.py', '../fum-ocenki/scripts/контракт_обзора.py']
    код_до = {имя: hashlib.sha256((пакет / имя).read_bytes()).hexdigest() for имя in имена_кода}
    версия_гит = subprocess.check_output(['git', '--version']).decode().strip()
    модуль = загрузить_модуль()
    измерения = {имя: [] for имя in ('холодное', 'повтор_нового_среза', 'повтор_того_же_среза', 'один_изменённый_источник')}
    with tempfile.TemporaryDirectory() as каталог:
        корень = Path(каталог).resolve()
        данные, исходный = подготовить_фикстуру(корень)
        (корень / 'Планирование/цель.md').write_text('# Обновлённая цель\n', encoding='utf-8')
        изменённый = зафиксировать(корень)
        хэш_выдачи = None
        исходные_источники = None
        for _ in range(вход.повторы):
            срез = None
            for имя in измерения:
                начало = time.perf_counter_ns()
                if имя != 'повтор_того_же_среза':
                    срез = модуль.СрезГит(корень, изменённый if имя == 'один_изменённый_источник' else исходный)
                профиль = {}
                результат = модуль.собрать_срез(срез, данные['выбор'], данные['момент'], 65536, профиль=профиль)
                профиль['внешняя_длительность_наносекунды'] = time.perf_counter_ns() - начало
                байты = модуль.сериализовать(результат)
                текущий = hashlib.sha256(байты).hexdigest()
                if имя == 'один_изменённый_источник':
                    if [а['путь'] for а in исходные_источники] != [а['путь'] for а in результат['источники']]:
                        raise ValueError('изменился перечень источников')
                    различия = [а['путь'] for а, б in zip(исходные_источники, результат['источники']) if а != б]
                    if различия != ['Планирование/цель.md']:
                        raise ValueError('изменился состав помимо одного источника')
                elif хэш_выдачи is not None and текущий != хэш_выдачи:
                    raise ValueError('повтор изменил выдачу')
                else:
                    хэш_выдачи = текущий
                    исходные_источники = результат['источники']
                профиль['выдача_sha256'] = текущий
                измерения[имя].append(профиль)
        код_после = {имя: hashlib.sha256((пакет / имя).read_bytes()).hexdigest() for имя in имена_кода}
        if код_до != код_после:
            raise ValueError('изменился измеренный код')
        профиль = {'схема': 'fum.профиль-актуального-среза.1',
            'среда': {'версия_питона': platform.python_version(), 'платформа': platform.system(), 'версия_гит': версия_гит,
                      'файловый_кэш_ос_очищен': False},
            'границы': 'Git-фикстура и её коммиты вне измерений; интервалы вложены, не суммировать. Холодное означает новый СрезГит, а не очищенный кэш ОС. Долговременного кэша нет. Прочитанные байты означают байты Git-объектов, не stdout ls-tree.',
            'состав': {'источников': len(данные['выбор']['источники']), 'предел_байтов': 65536,
                       'исходный_коммит': исходный, 'изменённый_коммит': изменённый,
                       'фикстура_sha256': hashlib.sha256((пакет / 'tests/фикстуры/актуальный-срез.json').read_bytes()).hexdigest()},
            'код': код_до, 'байты_кода_до_после_равны': True,
            'измерения': измерения, 'медианы': {}, 'токены': None}
        for имя, строки in измерения.items():
            профиль['медианы'][имя] = {поле: statistics.median(ряд[поле] for ряд in строки)
                for поле in строки[0] if isinstance(строки[0][поле], int)}
        return профиль


if __name__ == '__main__':
    главная()
