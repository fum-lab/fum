"""Три новых процесса: генерация .8 и читающий план; без живого писателя."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import stat
import subprocess
import sys
import time
from unittest import mock


КОРЕНЬ = Path(__file__).resolve().parents[3]
МЕТКИ = {
    'цели_ветки_состояния_узла.py': {'вывести_цели_состояния'},
    'подготовка_ветки_состояния_узла.py': {'расчёт_исполнителя', 'проверить_закреплённые'},
    'полномочия_ветки_состояния_узла.py': {'прочитать', 'проверить_акт', 'проверить_дерево'},
    'подготовка_дочернего_поручения.py': {'построить_план', 'технические_входы'},
}


def отпечатки_модулей():
    пути = {Path(__file__).resolve()}
    for модуль in list(sys.modules.values()):
        имя = getattr(модуль, '__file__', None)
        if имя and Path(имя).resolve().is_relative_to(КОРЕНЬ):
            пути.add(Path(имя).resolve())
    return {п.relative_to(КОРЕНЬ).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest()
            for п in sorted(пути) if п.is_file() and п.suffix == '.py'}


def снимок_выходов(каталог):
    """Конечный приватный каталог фикстуры; symlink не разыменовывается."""
    каталог = Path(каталог)
    итог = {}
    for путь in [каталог, *sorted(каталог.rglob('*'))]:
        режим = путь.lstat().st_mode
        if stat.S_ISREG(режим):
            значение = hashlib.sha256(путь.read_bytes()).hexdigest()
        elif stat.S_ISLNK(режим):
            значение = os.readlink(путь)
        elif stat.S_ISDIR(режим):
            значение = None
        else:
            raise ValueError('необычный тип приватного выхода')
        итог[путь.relative_to(каталог).as_posix()] = [режим, значение]
    return итог


def измерить():
    import test_подготовки_дочернего_поручения as проверки
    случай = проверки.ПодготовкаПоручения()
    начало = time.monotonic_ns()
    try:
        случай.setUp()
        вход, исходный_план, _ = случай.подготовить_генератор_состояния()
        подготовка = time.monotonic_ns() - начало
        корень = Path(вход['корень'])
        with mock.patch.dict(os.environ, CODEX_THREAD_ID=вход['писатель']):
            до = случай.м.собственное_дерево(вход)
        выходы_до = снимок_выходов(вход['каталог_выходов'])
        версии = отпечатки_модулей()
        интервалы = []; активные = {}; глубина = 0
        scripts = КОРЕНЬ / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts'
        коды = {id(vars(модуль)[имя].__code__): файл + ':' + имя
                for модуль in list(sys.modules.values())
                if getattr(модуль, '__file__', None)
                and (файл := Path(модуль.__file__).name) in МЕТКИ
                and Path(модуль.__file__).resolve() == scripts / файл
                for имя in МЕТКИ[файл] if имя in vars(модуль)}

        def отметка(кадр, событие, аргумент):
            nonlocal глубина
            if событие not in ('call', 'return'):
                return
            метка = коды.get(id(кадр.f_code))
            if метка is None:
                return
            if событие == 'call':
                активные[id(кадр)] = (time.monotonic_ns(), глубина)
                глубина += 1
            elif событие == 'return':
                начало_вызова, уровень = активные.pop(id(кадр))
                глубина -= 1
                интервалы.append({'метка': метка, 'глубина': уровень,
                    'наносекунды': time.monotonic_ns() - начало_вызова,
                    'возвращено_значение': аргумент is not None})

        прежний = sys.getprofile()
        with mock.patch.dict(os.environ, CODEX_THREAD_ID=вход['писатель']):
            sys.setprofile(отметка)
            начало = time.monotonic_ns()
            try:
                план = случай.м.построить_план(вход)
            finally:
                план_нс = time.monotonic_ns() - начало
                sys.setprofile(прежний)
        with mock.patch.dict(os.environ, CODEX_THREAD_ID=вход['писатель']):
            после = случай.м.собственное_дерево(вход)
        if (план != исходный_план or после != до
                or снимок_выходов(вход['каталог_выходов']) != выходы_до
                or отпечатки_модулей() != версии or активные or глубина != 0):
            raise ValueError('план, HEAD/ref/индекс, приватные выходы или исходники изменились при замере')
        return {'подготовка_фикстуры_нс': подготовка, 'план_нс': план_нс,
                'интервалы': интервалы, 'исходники': версии, 'живые_эффекты': 0}
    finally:
        случай.doCleanups()


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--дочерний', action='store_true')
    разбор.add_argument('--выход')
    вход = разбор.parse_args()
    if вход.дочерний:
        if вход.выход is not None:
            raise ValueError('дочерний замер не пишет выход')
        print(json.dumps(измерить(), ensure_ascii=False, sort_keys=True))
        return
    if вход.выход is None:
        raise ValueError('нужен отдельный новый выход профиля')
    серии = []
    for _ in range(3):
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--дочерний'],
            cwd=КОРЕНЬ, capture_output=True, check=True, timeout=180)
        if процесс.stderr:
            raise ValueError('неожиданный stderr нового процесса')
        серии.append(json.loads(процесс.stdout))
    версии = серии[0]['исходники']
    if (any(с['исходники'] != версии for с in серии)
            or any(hashlib.sha256((КОРЕНЬ / имя).read_bytes()).hexdigest() != sha
                   for имя, sha in версии.items())):
        raise ValueError('версии исходников различаются между процессами')
    итог = {'схема': 'fum.профиль-генератора-состояния.1', 'серии': серии,
        'медиана_плана_нс': int(statistics.median(с['план_нс'] for с in серии)),
        'граница': 'Открытая Git-фикстура A → ACT2 → .8; setup отдельно. '
            'Таймер включает диагностический callback. Вложенные интервалы не суммируются. '
            'Хэши наблюдают файлы загруженных модулей, а не доказывают import-песочницу. '
            'Полный фасад, публикация и живое восстановление здесь не измеряются.'}
    данные = (json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    with os.fdopen(os.open(вход.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'wb') as поток:
        поток.write(данные); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'схема': итог['схема'], 'серий': len(серии),
        'медиана_плана_нс': итог['медиана_плана_нс'], 'живые_эффекты': 0}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
