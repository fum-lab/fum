"""Три процесса: наполнение .2 через реальные CLI; только изолированные фикстуры."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time

КОРЕНЬ = Path(__file__).resolve().parents[3]


def sha(данные):
    return hashlib.sha256(данные).hexdigest()


def отпечатки_модулей():
    пути = {Path(__file__).resolve()}
    for модуль in list(sys.modules.values()):
        имя = getattr(модуль, '__file__', None)
        if имя and Path(имя).resolve().is_relative_to(КОРЕНЬ):
            пути.add(Path(имя).resolve())
    return {п.relative_to(КОРЕНЬ).as_posix(): sha(п.read_bytes())
            for п in sorted(пути) if п.is_file() and п.suffix == '.py'}


def измерить():
    import test_подготовки_этапа_коммита as проверки
    случай = проверки.ПодготовкаСостоянияЭтапа()
    начало = time.monotonic_ns()
    try:
        случай.setUp()
        параметры, _ = случай.подготовить_наполнение()
        READY = случай.штатный_путь_READY()
        if os.path.lexists(READY) or os.path.lexists(параметры['квитанция']):
            raise ValueError('фикстура уже готова')
        подготовка = time.monotonic_ns() - начало
        приватные = {имя: (Path(имя).read_bytes(), Path(имя).stat().st_mode) for имя in (
            случай.фасад['вход_коммита'], случай.фасад['поручение'],
            случай.фасад['наполнение'], случай.вход['источник_модели'])}
        HEAD = случай.м.поручения._гит(случай.корень, 'rev-parse', 'HEAD')
        ref = случай.м.поручения._гит(случай.корень, 'symbolic-ref', 'HEAD')
        исходная_пара, индекс = случай.пара_и_индекс(параметры)
        интервалы = {}; результаты = {}
        SHA = None
        for имя, режим in (('планирование', 'наполнение-план'),
                           ('применение', 'наполнение-применить'),
                           ('повтор', 'наполнение-применить')):
            начало = time.monotonic_ns()
            процесс = случай.fill_cli(режим, SHA)
            интервалы[имя + '_нс'] = time.monotonic_ns() - начало
            if процесс.returncode or процесс.stderr:
                raise ValueError('неуспешный CLI ' + имя + ': ' + процесс.stderr.decode())
            результаты[имя] = json.loads(процесс.stdout)
            if имя == 'планирование':
                SHA = результаты[имя]['план_sha256']
            elif имя == 'применение':
                новая_пара, новый_индекс = случай.пара_и_индекс(параметры)
                if новая_пара == исходная_пара or новый_индекс != индекс:
                    raise ValueError('эффект пары или неизменность индекса не подтверждены')
        if (not результаты['повтор']['повтор']
                or случай.пара_и_индекс(параметры) != (новая_пара, индекс)
                or случай.м.поручения._гит(случай.корень, 'rev-parse', 'HEAD') != HEAD
                or случай.м.поручения._гит(случай.корень, 'symbolic-ref', 'HEAD') != ref
                or any((Path(имя).read_bytes(), Path(имя).stat().st_mode) != сырые for имя, сырые in приватные.items())
                or os.path.lexists(READY) or os.path.lexists(параметры['квитанция'])):
            raise ValueError('повтор, HEAD/ref/индекс или приватные свидетели изменились')
        файл_плана = Path(случай.фасад['план_наполнения'])
        байты_плана = файл_плана.read_bytes()
        режим_плана = файл_плана.stat().st_mode
        if sha(байты_плана) != SHA or режим_плана & 0o777 != 0o400:
            raise ValueError('план не соответствует принятому SHA или режиму')
        план = json.loads(байты_плана)['план']
        версии = отпечатки_модулей()
        for карта in (план['зависимости']['допуск_состояния']['код'], план['зависимости']['исполнитель']):
            for имя, h in карта.items():
                if имя in версии and версии[имя] != h:
                    raise ValueError('загруженные версии различаются')
                версии[имя] = h
        if (файл_плана.read_bytes() != байты_плана
                or файл_плана.stat().st_mode != режим_плана):
            raise ValueError('байты или режим плана изменились до возврата измерения')
        return {'подготовка_фикстуры_нс': подготовка, **интервалы,
            'метки': {имя: значение['профиль'] for имя, значение in результаты.items()},
            'исходники': версии, 'живые_эффекты': 0}
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
        raise ValueError('нужен новый выход профиля')
    серии = []
    for _ in range(3):
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--дочерний'],
            cwd=КОРЕНЬ, capture_output=True, check=True, timeout=180)
        if процесс.stderr:
            raise ValueError('неожиданный stderr нового процесса')
        серии.append(json.loads(процесс.stdout))
    версии = серии[0]['исходники']
    if (any(с['исходники'] != версии for с in серии)
            or any(sha((КОРЕНЬ / имя).read_bytes()) != h for имя, h in версии.items())):
        raise ValueError('исходники различаются между замерами')
    итог = {'схема': 'fum.профиль-наполнения-состояния.1', 'серии': серии,
        'медианы_нс': {имя: int(statistics.median(с[имя] for с in серии))
            for имя in ('планирование_нс', 'применение_нс', 'повтор_нс')},
        'граница': 'Открытая Git-фикстура A → ACT2 → .8 → наполнение .2; setup отдельно. '
            'Каждая операция CLI — новый процесс. Вложенные интервалы не суммируются. '
            'Хэши наблюдают исходники модулей и отдельного допуска, а не import-песочницу. '
            'Живая запись, публикация и восстановление узла не измеряются.'}
    сырые = (json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    with os.fdopen(os.open(вход.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'wb') as поток:
        поток.write(сырые); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'схема': итог['схема'], 'серий': 3, 'медианы_нс': итог['медианы_нс'],
        'живые_эффекты': 0}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
