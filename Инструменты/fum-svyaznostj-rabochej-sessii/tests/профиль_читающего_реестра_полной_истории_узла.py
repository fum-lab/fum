"""Три новых процесса на одной конечной открытой Git/native-фикстуре."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import statistics
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_читающего_реестра_полной_истории_узла as фикстуры


def сохранить(путь, данные):
    with os.fdopen(os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'wb') as файл:
        файл.write(данные)
        файл.flush()
        os.fsync(файл.fileno())


def код():
    корень = Path(__file__).resolve().parents[3]
    состав = {}
    for модуль in list(sys.modules.values()):
        имя = getattr(модуль, '__file__', None)
        if имя:
            путь = Path(имя).resolve()
            if путь.is_relative_to(корень) and путь.suffix == '.py':
                состав[str(путь.relative_to(корень))] = hashlib.sha256(путь.read_bytes()).hexdigest()
    состав[str(Path(__file__).resolve().relative_to(корень))] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    for путь in (Path(фикстуры.__file__).resolve(), Path(фикстуры.читатель.__file__).resolve(),
            Path(фикстуры.старый.__file__).resolve()):
        состав[str(путь.relative_to(корень))] = hashlib.sha256(путь.read_bytes()).hexdigest()
    return состав


def процесс(каталог):
    читатель = фикстуры.читатель
    вход = читатель._вход_джейсон(str(каталог / 'вход.json'))
    выбор = читатель._вход_джейсон(str(каталог / 'выбор.json'))
    результат, данные, замер = читатель.прочитать_с_байтами(каталог / 'фикстура', вход, выбор)
    память = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    замер.update(результат['профиль'])
    замер['максимум_резидентной_памяти_байтов'] = int(память if sys.platform == 'darwin' else память * 1024)
    замер['строк'] = sum(э['строк'] for э in результат['источники'])
    замер['рамок'] = sum(э['реестр']['рамок'] for э in результат['источники'])
    sys.stdout.buffer.write(данные)
    sys.stderr.buffer.write(фикстуры.старый.байты(замер))
    return 0


def измерить(каталог, рамок):
    каталог = Path(каталог)
    if not каталог.is_absolute() or каталог.parent != каталог.parent.resolve():
        raise ValueError('нужен новый физический приватный каталог')
    for предок in (каталог.parent, *каталог.parent.parents):
        if (предок / '.git').exists():
            raise ValueError('каталог профиля должен находиться вне Git')
    каталог.mkdir(mode=0o700)
    (каталог / 'фикстура').mkdir(mode=0o700)
    начало = time.perf_counter_ns()
    вход, выбор, _ = фикстуры.создать_фикстуру(каталог / 'фикстура',
        (фикстуры.нейтральная(н) for н in range(1, рамок + 1)), граница=рамок // 2)
    сохранить(каталог / 'вход.json', фикстуры.старый.байты(вход))
    сохранить(каталог / 'выбор.json', фикстуры.старый.байты(выбор))
    подготовка = time.perf_counter_ns() - начало
    источники = {э['путь']: (Path(э['путь']).stat().st_ino,
        Path(э['путь']).stat().st_mtime_ns, э['конец']['sha256']) for э in вход['источники']}
    исходники = код()
    результаты = []
    for номер in range(1, 4):
        начало = time.perf_counter_ns()
        команда = [sys.executable, '-B', str(Path(__file__).resolve()),
            '--процесс', '--каталог', str(каталог)]
        try:
            ответ = subprocess.run(команда, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, timeout=180)
        except subprocess.TimeoutExpired as ошибка:
            сохранить(каталог / f'{номер}-stdout.bin', ошибка.stdout or b'')
            сохранить(каталог / f'{номер}-stderr.bin', ошибка.stderr or b'')
            сохранить(каталог / f'{номер}-исход.json', фикстуры.старый.байты({
                'код': None, 'полнота_потоков_подтверждена': False,
                'внешнее_нс': time.perf_counter_ns() - начало, 'автоматический_повтор': False}))
            raise ValueError('тайм-аут профиля; доступный RAW сохранён без повтора') from ошибка
        внешнее = time.perf_counter_ns() - начало
        сохранить(каталог / f'{номер}-stdout.bin', ответ.stdout)
        сохранить(каталог / f'{номер}-stderr.bin', ответ.stderr)
        квитанция = {'код': ответ.returncode, 'внешнее_нс': внешнее,
            'хэш_стандартного_вывода': hashlib.sha256(ответ.stdout).hexdigest(),
            'хэш_потока_ошибок': hashlib.sha256(ответ.stderr).hexdigest()}
        сохранить(каталог / f'{номер}-исход.json', фикстуры.старый.байты(квитанция))
        if ответ.returncode != 0:
            raise ValueError('процесс профиля отказал; RAW сохранён, повтор не выполнен')
        доказательство = json.loads(ответ.stdout)
        замер = json.loads(ответ.stderr)
        if (not доказательство['полнота_выбранных_префиксов_доказана']
                or доказательство['разрешение_эффекта']
                or доказательство['источники'][0]['реестр']['рамок'] != рамок
                or замер['рамок'] != рамок + 1):
            raise ValueError('не подтверждён полный профиль конечной фикстуры')
        результаты.append(dict(замер, **квитанция))
    for путь, (номер_файла, время, ожидаемый) in источники.items():
        состояние = Path(путь).stat()
        if ((состояние.st_ino, состояние.st_mtime_ns) != (номер_файла, время)
                or hashlib.sha256(Path(путь).read_bytes()).hexdigest() != ожидаемый):
            raise ValueError('источник профиля изменился')
    if код() != исходники:
        raise ValueError('исходники профиля изменились')
    метрики = ['подготовка_нс', 'разбор_нс', 'учёт_нс', 'сериализация_нс',
        'повторное_чтение_нс', 'общая_нс', 'внешнее_нс', 'максимум_резидентной_памяти_байтов']
    итог = {'схема': 'fum.профиль-читающего-реестра-полной-истории-узла.1',
        'подготовка_фикстуры_нс': подготовка, 'повторов': 3, 'рамок_координатора': рамок,
        'одна_фикстура': True, 'источники_сохранены': True, 'код_сохранён': True,
        'кэш_ОС_не_сбрасывался': True, 'исходники': исходники, 'измерения': результаты,
        'область_повторного_чтения': 'сырые-выбранные-источники',
        'сохранённый_стандартный_вывод_перечитан_с_диска': False,
        'срок_библиотеки_включает_запись_стандартного_вывода': False,
        'медианы': {ключ: int(statistics.median(э[ключ] for э in результаты)) for ключ in метрики},
        'настоящий_ресурс_координатора_выбран': False, 'настоящий_ввод_координатора_прочитан': False,
        'разрешение_эффекта': False}
    сохранить(каталог / 'профиль.json', фикстуры.старый.байты(итог))
    return итог


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False, description=__doc__)
    разбор.add_argument('--каталог', required=True, type=Path)
    разбор.add_argument('--рамок', type=int, default=131073)
    разбор.add_argument('--процесс', action='store_true')
    аргументы = разбор.parse_args()
    if аргументы.процесс:
        return процесс(аргументы.каталог)
    if not 131072 < аргументы.рамок <= 180000:
        raise ValueError('профиль требует конечный поток от 131073 до 180000 рамок')
    sys.stdout.buffer.write(фикстуры.старый.байты(измерить(аргументы.каталог, аргументы.рамок)))
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
