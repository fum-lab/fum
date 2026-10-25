"""Три неизменных RO-допуска малой фикстуры; это не профиль runtime ROOT."""
import argparse
import cProfile
import hashlib
import json
import marshal
import os
from pathlib import Path
import platform
import sys
import time

from test_назначения_текущего_этапа import НазначениеЭтапа, байты


def хэш(байты_хэша):
    return hashlib.sha256(байты_хэша).hexdigest()


def главная():
    разборщик = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разборщик.add_argument('--выход', type=Path, required=True)
    параметры_профиля = разборщик.parse_args()
    выходной_файл = параметры_профиля.выход
    if not выходной_файл.is_absolute() or выходной_файл.parent.resolve() != выходной_файл.parent or not выходной_файл.parent.is_dir():
        raise ValueError('нужен физический частный адрес профиля')
    if any((элемент_снимка / '.git').exists() for элемент_снимка in выходной_файл.parents):
        raise ValueError('профиль должен находиться вне Git')
    сырой_профиль = выходной_файл.with_suffix('.pstats')
    if os.path.lexists(выходной_файл) or os.path.lexists(сырой_профиль):
        raise ValueError('оба результата должны отсутствовать')
    стенд = НазначениеЭтапа()
    try:
        стенд.setUp()
        файл_допуска = Path(стенд.модуль.__file__).resolve()
        код_допуска = файл_допуска.read_bytes()
        def снимок():
            return {'HEAD': стенд.гит_стенда('rev-parse', 'HEAD'),
                'индекс': хэш((стенд.корень_стенда / '.git/index').read_bytes()),
                'файлы': {элемент_снимка.relative_to(стенд.основа).as_posix(): хэш(элемент_снимка.read_bytes())
                    for элемент_снимка in стенд.основа.rglob('*') if элемент_снимка.is_file()}}
        исходный_снимок = снимок(); профилировщик = cProfile.Profile(); длительности = []; результаты = []
        for _ in range(3):
            начало = time.perf_counter_ns(); профилировщик.enable()
            результат = стенд.проверить_назначение()
            профилировщик.disable(); длительность = time.perf_counter_ns() - начало
            длительности.append(длительность); результаты.append(результат)
        if результаты[1:] != результаты[:-1] or снимок() != исходный_снимок or файл_допуска.read_bytes() != код_допуска:
            raise ValueError('результаты или исходное состояние изменились')
        профилировщик.create_stats()
        with os.fdopen(os.open(сырой_профиль, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'wb') as поток:
            marshal.dump(профилировщик.stats, поток); поток.flush(); os.fsync(поток.fileno())
        функции = []
        for (имя_файла, строка, имя_функции), (первичных_вызовов, всего_вызовов, своё_время, накопленное_время, вызывающие) in профилировщик.stats.items():
            if имя_файла == str(файл_допуска) or имя_функции == '_гит':
                функции.append({'функция': имя_функции, 'строка': строка, 'вызовов': всего_вызовов,
                    'своё_время': своё_время, 'накопленное_время': накопленное_время})
        результат = {'схема': 'fum.профиль-назначения-текущего-этапа.2',
            'граница': 'Три последовательных RO-проверки одного G/C/native в одном процессе; подготовка, снимки и сериализация исключены; cProfile включён; кэш ОС не очищался.',
            'интерпретатор': {'путь': sys.executable, 'версия': platform.python_version(), 'флаги': str(sys.flags)},
            'код_sha256': хэш(код_допуска), 'вход_sha256': хэш(байты(стенд.параметры)),
            'повторов': 3, 'длительности_наносекунды': длительности,
            'одинаковые_результаты': True, 'без_эффектов': True,
            'сырой_профиль': {'путь': str(сырой_профиль), 'sha256': хэш(сырой_профиль.read_bytes())},
            'функции': sorted(функции, key=lambda строка_профиля: строка_профиля['накопленное_время'], reverse=True)}
        данные_профиля = байты(результат)
        with os.fdopen(os.open(выходной_файл, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'wb') as поток:
            поток.write(данные_профиля); поток.flush(); os.fsync(поток.fileno())
        print(json.dumps({'путь': str(выходной_файл), 'sha256': хэш(данные_профиля),
            'длительности_наносекунды': длительности, 'код_sha256': хэш(код_допуска)}, ensure_ascii=False))
    finally:
        стенд.doCleanups()


if __name__ == '__main__':
    главная()
