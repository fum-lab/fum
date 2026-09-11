#!/usr/bin/env python3
"""Собрать неизменяемую поставку VM вне Git и проверить повтор без новой сборки."""
import argparse
import ctypes
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import uuid

ИМЯ_ПАКЕТА = 'ВиртуальнаяМашина_ЯдроМашины.bundle'


def кодировать(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()


def прочитать(путь, предел=64 * 1024**2):
    файл = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC)
    try:
        сведения = os.fstat(файл)
        if not stat.S_ISREG(сведения.st_mode) or сведения.st_nlink != 1 or сведения.st_size > предел:
            raise ValueError('Небезопасный тип или размер файла: ' + str(путь))
        with os.fdopen(файл, 'rb', closefd=False) as поток: байты = поток.read(предел + 1)
        if len(байты) > предел: raise ValueError('Файл вырос сверх предела')
        return байты
    finally: os.close(файл)


def инвентарь(корень, исключить=()):
    результат = {}
    def отказ(ошибка): raise ошибка
    for каталог, подпапки, файлы in os.walk(корень, followlinks=False, onerror=отказ):
        подпапки[:] = sorted(имя for имя in подпапки if имя not in исключить)
        for имя in подпапки + файлы:
            путь = Path(каталог) / имя
            if путь.is_symlink(): raise ValueError('Символическая ссылка в поставке или исходниках')
        for имя in sorted(файлы):
            if Path(каталог) == корень and имя in исключить: continue
            путь = Path(каталог) / имя
            байты = прочитать(путь)
            результат[путь.relative_to(корень).as_posix()] = {
                'sha256': hashlib.sha256(байты).hexdigest(), 'размер': len(байты), 'права': stat.S_IMODE(путь.stat().st_mode)}
    return результат


def физический_путь(путь):
    путь = Path(путь)
    if not путь.is_absolute() or '..' in путь.parts or путь.resolve() != путь:
        raise ValueError('Нужен абсолютный физический путь без символических ссылок')
    return путь


def вне_репозитория(путь):
    путь = физический_путь(путь)
    for предок in (путь, *путь.parents):
        if os.path.lexists(предок / '.git'): raise ValueError('Сборка и поставка запрещены внутри Git')
    return путь


def проверить_кэш(путь):
    путь = физический_путь(путь)
    try: сведения = путь.stat()
    except FileNotFoundError: return
    if not stat.S_ISDIR(сведения.st_mode): raise ValueError('Корень кэша не является каталогом')
    def отказ(ошибка): raise ошибка
    for каталог, подпапки, файлы in os.walk(путь, followlinks=False, onerror=отказ):
        for имя in подпапки + файлы:
            запись = Path(каталог) / имя
            if запись.is_symlink():
                цель = запись.resolve()
                if цель != путь and путь not in цель.parents:
                    raise ValueError('Ссылка выводит кэш сборки за собственную область')


def проверить_ресурсы(пакет, ожидаемые):
    файлы = инвентарь(пакет)
    префикс = 'Contents/Resources/' if (пакет / 'Contents/Resources').is_dir() else ''
    фактические = {}
    for имя, сведения in файлы.items():
        if имя in ('Contents/Info.plist', 'Info.plist') or имя.startswith(('Contents/_CodeSignature/', '_CodeSignature/')):
            continue
        if not имя.startswith(префикс): raise ValueError('Посторонний файл пакета ресурсов')
        фактические[имя[len(префикс):]] = сведения['sha256']
    if фактические != {имя: сведения['sha256'] for имя, сведения in ожидаемые.items()}:
        raise ValueError('Точный набор ресурсов поставки не совпал с исходниками')


def записать(путь, байты):
    файл = os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(файл, 'wb') as поток:
        поток.write(байты); поток.flush(); os.fsync(поток.fileno())


def установить_каталог(исходник, цель):
    библиотека = ctypes.CDLL(None, use_errno=True)
    функция = библиотека.renamex_np
    функция.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_uint]
    функция.restype = ctypes.c_int
    if функция(os.fsencode(исходник), os.fsencode(цель), 4) != 0:  # RENAME_EXCL в Darwin
        raise OSError(ctypes.get_errno(), 'Цель занята; собственный staging сохранён')
    дескриптор = os.open(цель.parent, os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC)
    try: os.fsync(дескриптор)
    finally: os.close(дескриптор)


def описать_python(путь=None):
    if sys.implementation.name != 'cpython' or sys.version_info[:2] < (3, 13):
        raise ValueError('Поставке нужен CPython не ниже 3.13')
    if not all(hasattr(os, имя) for имя in ('waitid', 'WNOWAIT')):
        raise ValueError('CPython не предоставляет waitid/WNOWAIT')
    путь = Path(sys.executable).resolve(strict=True) if путь is None else физический_путь(путь)
    if not os.access(путь, os.X_OK): raise ValueError('Выбранный CPython не исполняемый')
    return {'путь': str(путь), 'реализация': sys.implementation.name, 'версия': sys.version,
        'sha256': hashlib.sha256(прочитать(путь)).hexdigest(), 'возможности': ['waitid', 'WNOWAIT']}


def проверить_python(питон):
    if описать_python(питон['путь']) != питон:
        raise ValueError('Python изменился во время сборки; результат не подтверждён')


def создать_исполнителя(проект, каталог, замок, *, питон=None):
    питон = dict(описать_python() if питон is None else питон)
    проверить_python(питон)
    ресурсы = проект / 'Sources/ЯдроМашины/Ресурсы'
    try:
        наблюдатель = прочитать(ресурсы / 'наблюдатель.py', 512 * 1024)
        родитель = прочитать(ресурсы / 'родитель_наблюдателя.py', 512 * 1024)
    except OSError as ошибка:
        raise ValueError('Не найдены точные ресурсы наблюдателя сборки') from ошибка
    пространство = {'__name__': 'родитель_наблюдателя'}
    exec(compile(родитель.decode('utf-8'), 'родитель_наблюдателя.py', 'exec'), пространство)
    исполнить = пространство.get('исполнить_под_наблюдением')
    if not callable(исполнить): raise ValueError('Ресурс родителя наблюдателя не поддерживает нужный контракт')
    происхождение = hashlib.sha256(кодировать({'схема': 'fum.исходники-команды-сборки.1', 'файлы': {
        имя: hashlib.sha256(байты).hexdigest() for имя, байты in [
            ('собрать.py', прочитать(Path(__file__))), ('наблюдатель.py', наблюдатель), ('родитель_наблюдателя.py', родитель)]}})).hexdigest()
    проверка = str(uuid.uuid4()); корневое_измерение = str(uuid.uuid4())
    def выполнить(аргументы, *, предел=600):
        if type(предел) not in (int, float) or not math.isfinite(предел) or not 0 < предел <= 86400:
            raise ValueError('Неверный срок команды сборки')
        проверить_python(питон)
        try:
            результат = исполнить(наблюдатель=наблюдатель.decode('utf-8'), каталог=каталог, замок=замок,
                аргументы=аргументы, рабочий_каталог=str(проект), среда=dict(os.environ), вход=b'',
                родитель=корневое_измерение, проверка=проверка, исходник=происхождение,
                тайм_аут_нс=int(предел * 1e9), предел_вывода=32 * 1024**2, интерпретатор=питон['путь'])
        except RuntimeError as ошибка:
            raise ValueError('Наблюдатель не подтвердил сборочную команду: ' + str(ошибка)) from ошибка
        проверить_python(питон)
        if результат['исход'] != 'успех' or type(результат['код_команды']) is not int or результат['код_команды'] != 0:
            raise ValueError('Команда: ' + результат['причина'] + ', попытка ' + результат['идентификатор']
                + ', код ' + str(результат['код_команды']) + ': ' + результат['ошибки'][-4000:].decode(errors='replace'))
        return результат['вывод']
    return выполнить


def собрать(проект, сборка, поставка, свифт, *, система='xcode', выполнить=None):
    питон = описать_python()
    проект = физический_путь(проект)
    сборка, поставка = вне_репозитория(сборка), вне_репозитория(поставка)
    if система not in ('xcode', 'native') or сборка == поставка or сборка in поставка.parents or поставка in сборка.parents:
        raise ValueError('Нужны раздельные области и известная система сборки')
    владелец = {'схема': 'fum.область-сборки-VM.1', 'проект': str(проект)}
    if сборка.exists() and (not сборка.is_dir() or not (сборка / 'владелец.json').is_file() or
            json.loads(прочитать(сборка / 'владелец.json', 4096)) != владелец):
        raise ValueError('Каталог сборки неизвестен; выберите новый путь')
    if поставка.exists() and (not поставка.is_dir() or not (поставка / 'поставка.json').is_file()):
        raise ValueError('Каталог поставки неизвестен; прежние данные сохранены')
    сборка.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if not сборка.exists():
        временный = Path(tempfile.mkdtemp(prefix='.сборка-VM-', dir=сборка.parent))
        записать(временный / 'владелец.json', кодировать(владелец)); установить_каталог(временный, сборка)
    сведения = сборка.stat()
    if сведения.st_uid != os.getuid() or сведения.st_mode & 0o077:
        raise ValueError('Каталог сборки должен быть личным')
    замок = os.open(сборка / 'замок', os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC, 0o600)
    try:
        сведения = os.fstat(замок)
        if not stat.S_ISREG(сведения.st_mode) or сведения.st_nlink != 1 or сведения.st_uid != os.getuid() or сведения.st_mode & 0o077:
            raise ValueError('Небезопасный замок сборки')
        try: fcntl.flock(замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as ошибка: raise ValueError('Каталог сборки занят другим исполнителем') from ошибка
        каталог = os.open(сборка, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
        try: return собрать_под_замком(проект, сборка, поставка, свифт, система, выполнить, каталог, замок, питон)
        finally: os.close(каталог)
    finally: os.close(замок)


def собрать_под_замком(проект, сборка, поставка, свифт, система, выполнить, каталог, замок, питон):
    исходники = инвентарь(проект, ('.git', '.build', '.swiftpm', '__pycache__', 'Tests', 'ПереводИмён', 'README.md'))
    for имя in ('Package.swift', 'виртуализация.entitlements'):
        if имя not in исходники: raise ValueError('Не хватает обязательного входа: ' + имя)
    if выполнить is None: выполнить = создать_исполнителя(проект, каталог, замок, питон=питон)
    интервалы = []
    def команда(имя, аргументы, предел=600):
        начало = time.monotonic_ns(); исход = 'ошибка'
        try:
            ответ = выполнить([str(часть) for часть in аргументы], предел=предел); исход = 'успех'; return ответ
        finally: интервалы.append({'операция': имя, 'длительностьНс': time.monotonic_ns() - начало, 'исход': исход})
    версия = команда('Версия Swift', [свифт, '--version'], 30).decode().strip()
    набор_разработчика = {ключ: команда('Набор разработчика: ' + ключ,
        ['/usr/bin/xcrun', '--sdk', 'macosx', флаг], 30).decode().strip()
        for ключ, флаг in [('путь', '--show-sdk-path'), ('версия', '--show-sdk-version')]}
    вход = {'python': питон, 'исходники': исходники, 'упаковщик': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'свифт': str(свифт), 'версия': версия, 'система': система, 'платформа': sys.platform,
        'набор_разработчика': набор_разработчика,
        'выбор_среды': {имя: os.environ.get(имя) for имя in ('DEVELOPER_DIR', 'SDKROOT')}}
    if поставка.exists():
        прежняя = json.loads(прочитать(поставка / 'поставка.json', 4 * 1024**2))
        if (прежняя.get('схема') != 'fum.поставка-VM.1' or прежняя.get('вход') != вход or
                прежняя.get('файлы') != инвентарь(поставка, ('поставка.json',))):
            raise ValueError('Исходники или готовая поставка изменились; выберите новую цель')
        команда('Проверка подписи', ['/usr/bin/codesign', '--verify', '--strict', поставка / 'машина'], 30)
        проверить_python(питон)
        return {'состояние': 'проверена', 'исполняемый_файл': str(поставка / 'машина'), 'профиль': интервалы}
    поставка.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    аргументы = [свифт, 'build', '--package-path', проект, '--scratch-path', сборка / 'swift',
        '--jobs', '2', '-Xswiftc', '-j2']
    if система == 'xcode': аргументы += ['--build-system', 'xcode']
    проверить_кэш(сборка / 'swift')
    команда('Сборка продукта', аргументы + ['--product', 'машина'])
    продукты = физический_путь(команда('Каталог продуктов', аргументы + ['--show-bin-path'], 60).decode().strip())
    if сборка / 'swift' not in продукты.parents:
        raise ValueError('Каталог продуктов выходит из собственного кэша')
    пакет = продукты / ИМЯ_ПАКЕТА
    if not пакет.is_dir() or пакет.is_symlink(): raise ValueError('Не найден обычный пакет гостевых ресурсов')
    инвентарь(пакет)
    двоичные = прочитать(продукты / 'машина')
    ожидаемые_ресурсы = инвентарь(проект / 'Sources/ЯдроМашины/Ресурсы')
    проверить_ресурсы(пакет, ожидаемые_ресурсы)
    временный = Path(tempfile.mkdtemp(prefix='.поставка-VM-', dir=поставка.parent))
    записать(временный / 'машина', двоичные); (временный / 'машина').chmod(0o700)
    shutil.copytree(пакет, временный / ИМЯ_ПАКЕТА)
    команда('Подпись для виртуализации', ['/usr/bin/codesign', '--force', '--sign', '-', '--entitlements',
        проект / 'виртуализация.entitlements', временный / 'машина'], 30)
    команда('Проверка подписи', ['/usr/bin/codesign', '--verify', '--strict', временный / 'машина'], 30)
    проверить_ресурсы(временный / ИМЯ_ПАКЕТА, ожидаемые_ресурсы)
    if исходники != инвентарь(проект, ('.git', '.build', '.swiftpm', '__pycache__', 'Tests', 'ПереводИмён', 'README.md')):
        raise ValueError('Исходники изменились во время сборки; staging сохранён')
    проверить_python(питон)
    свидетельство = {'схема': 'fum.поставка-VM.1', 'вход': вход, 'файлы': инвентарь(временный), 'профиль': интервалы}
    записать(временный / 'поставка.json', кодировать(свидетельство))
    установить_каталог(временный, поставка)
    return {'состояние': 'собрана', 'исполняемый_файл': str(поставка / 'машина'), 'профиль': интервалы}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--описать-python', action='store_true', help='Вывести снимок текущего CPython без сборки')
    разбор.add_argument('--сборка', type=Path)
    разбор.add_argument('--поставка', type=Path)
    разбор.add_argument('--система', choices=('xcode', 'native'))
    аргументы = разбор.parse_args()
    if аргументы.описать_python:
        if any(значение is not None for значение in (аргументы.сборка, аргументы.поставка, аргументы.система)):
            разбор.error('Снимок Python не совмещается с параметрами сборки')
        try:
            sys.stdout.buffer.write(кодировать({'схема': 'fum.python-наблюдателя.1', 'python': описать_python()}))
        except (OSError, ValueError) as ошибка:
            print('Снимок Python не подтверждён: ' + str(ошибка), file=sys.stderr); return 1
        return 0
    if аргументы.сборка is None or аргументы.поставка is None:
        разбор.error('Для сборки нужны --сборка и --поставка')
    if sys.platform != 'darwin': разбор.error('Первая поставка поддерживает только macOS')
    свифт = shutil.which('swift')
    if not свифт: разбор.error('Swift не найден; выберите установленный Xcode')
    try:
        ответ = собрать(Path(__file__).resolve().parent, аргументы.сборка, аргументы.поставка, Path(свифт), система=аргументы.система or 'xcode')
        sys.stdout.buffer.write(кодировать(ответ))
    except (OSError, ValueError, subprocess.SubprocessError) as ошибка:
        print('Сборка не подтверждена: ' + str(ошибка), file=sys.stderr); return 1
    return 0


if __name__ == '__main__': raise SystemExit(главная())
