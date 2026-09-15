#!/usr/bin/env python3
"""Точное извлечение собственного кода из закреплённых Git-объектов."""
import argparse
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import time
import unicodedata


def git(источник, *аргументы):
    return subprocess.check_output(['git', '--no-replace-objects', '--literal-pathspecs', '-C', str(источник), *аргументы])


def относительный_путь(значение):
    if not isinstance(значение, str) or not значение or '\\' in значение:
        raise ValueError('Неверный относительный путь')
    путь = pathlib.PurePosixPath(значение)
    if путь.is_absolute() or any(часть in ('', '.', '..') for часть in значение.split('/')):
        raise ValueError('Выход за корень или неканонический путь')
    return путь


def прочитать_blob(источник, запись):
    if not re.fullmatch('[0-9a-f]{40}', запись['blob']):
        raise ValueError('Неверный OID')
    байты = git(источник, 'cat-file', 'blob', запись['blob'])
    if hashlib.sha1(b'blob ' + str(len(байты)).encode() + b'\0' + байты).hexdigest() != запись['blob']:
        raise ValueError('Подмена Git-объекта')
    if hashlib.sha256(байты).hexdigest() != запись['sha256'] or len(байты) != запись['размер']:
        raise ValueError('Подмена содержимого манифеста')
    return байты


def построить_план(источник, выбор, назначение):
    относительный_путь(назначение)
    файлы = {}
    источники = []
    for коммит, префикс in выбор:
        if not re.fullmatch('[0-9a-f]{40}', коммит):
            raise ValueError('Требуется полный неизменяемый commit OID')
        if git(источник, 'cat-file', '-t', коммит).strip() != b'commit':
            raise ValueError('Источник не является коммитом')
        относительный_путь(префикс) if префикс != '.' else None
        дерево = git(источник, 'rev-parse', коммит + '^{tree}').decode().strip()
        источники.append({'коммит': коммит, 'дерево': дерево, 'префикс': префикс})
        строки = git(источник, 'ls-tree', '-r', '-z', коммит, '--', префикс).split(b'\0')
        if строки == [b'']:
            raise ValueError('Пустой исходный набор')
        for строка in filter(None, строки):
            мета, сырой_путь = строка.split(b'\t', 1)
            режим, вид, blob = мета.decode().split()
            if вид != 'blob' or режим not in ('100644', '100755'):
                raise ValueError('Разрешены только обычные исходные файлы')
            путь = сырой_путь.decode('utf-8')
            относительный_путь(путь)
            байты = git(источник, 'cat-file', 'blob', blob)
            запись = {'источник': путь, 'назначение': назначение+'/'+путь, 'коммит': коммит,
                      'blob': blob, 'режим': режим, 'sha256': hashlib.sha256(байты).hexdigest(), 'размер': len(байты)}
            if путь in файлы and (файлы[путь]['blob'], файлы[путь]['режим']) != (blob, режим):
                raise ValueError('Несовместимые исходные версии общего пути')
            файлы.setdefault(путь, запись)
    return {'схема': 'fum.перенос-исходников.1', 'источники': источники, 'файлы': [файлы[путь] for путь in sorted(файлы)]}


def применить(источник, корень, план):
    if план.get('схема') != 'fum.перенос-исходников.1' or not план.get('файлы'):
        raise ValueError('Неизвестная схема или пустой план')
    корень = pathlib.Path(корень).resolve(strict=True)
    источники = план.get('источники', [])
    if not источники:
        raise ValueError('Не указано происхождение')
    for исходный in источники:
        if not re.fullmatch('[0-9a-f]{40}', исходный['коммит']):
            raise ValueError('Неверный commit источника')
        if исходный['префикс'] != '.':
            относительный_путь(исходный['префикс'])
        try:
            if git(источник, 'cat-file', '-t', исходный['коммит']).strip() != b'commit':
                raise ValueError('Источник не является коммитом')
            дерево = git(источник, 'rev-parse', исходный['коммит'] + '^{tree}').decode().strip()
        except subprocess.CalledProcessError as ошибка:
            raise ValueError('Недоступный исходный commit') from ошибка
        if дерево != исходный['дерево']:
            raise ValueError('Подмена исходного дерева')
    подготовленные = []
    имена = set()
    for запись in план['файлы']:
        относительный_путь(запись['источник'])
        if not any(запись['коммит'] == исходный['коммит'] and
                   (исходный['префикс'] == '.' or запись['источник'] == исходный['префикс'] or
                    запись['источник'].startswith(исходный['префикс'] + '/')) for исходный in источники):
            raise ValueError('Файл не принадлежит выбранному источнику')
        относительный = относительный_путь(запись['назначение'])
        ключ = unicodedata.normalize('NFC', str(относительный)).casefold()
        if ключ in имена:
            raise ValueError('Коллизия назначения')
        имена.add(ключ)
        цель = корень / относительный
        for часть in [цель, *цель.parents]:
            if часть == корень:
                break
            if часть.is_symlink():
                raise ValueError('Символическая ссылка в назначении')
        if цель.exists() or any(часть.exists() and not часть.is_dir() for часть in цель.parents):
            raise ValueError('Назначение уже занято')
        if запись['режим'] not in ('100644', '100755'):
            raise ValueError('Недопустимый режим')
        # Повторная сверка происхождения защищает от подмены пути в сохранённом плане.
        мета = git(источник, 'ls-tree', '-z', запись['коммит'], '--', запись['источник'])
        if мета != (запись['режим']+' blob '+запись['blob']+'\t'+запись['источник']+'\0').encode():
            raise ValueError('Путь не соответствует исходному объекту')
        подготовленные.append((цель, прочитать_blob(источник, запись), int(запись['режим'][-3:], 8)))
    созданные = []
    try:
        for цель, байты, режим in подготовленные:
            цель.parent.mkdir(parents=True, exist_ok=True)
            with цель.open('xb') as поток:
                созданные.append(цель)
                поток.write(байты)
            цель.chmod(режим)
    except BaseException:
        for цель in reversed(созданные):
            цель.unlink()
        raise


def main():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--источник', required=True)
    разбор.add_argument('--корень', required=True)
    разбор.add_argument('--выбор', action='append', required=True, help='Полный commit:путь; . для всего дерева')
    разбор.add_argument('--назначение', default='Приложения/FUMA')
    разбор.add_argument('--применить', action='store_true')
    параметры = разбор.parse_args()
    начало = time.monotonic_ns()
    план = построить_план(параметры.источник, [элемент.split(':', 1) for элемент in параметры.выбор], параметры.назначение)
    граница = time.monotonic_ns()
    if параметры.применить:
        применить(параметры.источник, параметры.корень, план)
    конец = time.monotonic_ns()
    print(json.dumps(план, ensure_ascii=False, sort_keys=True, indent=2))
    print(json.dumps({'план_нс': граница-начало, 'применение_нс': конец-граница, 'файлы': len(план['файлы']), 'байты': sum(запись['размер'] for запись in план['файлы'])}, ensure_ascii=False), file=sys.stderr)


if __name__ == '__main__':
    main()
