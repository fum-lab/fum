"""Два новых процесса: подготовка, архив, публичная пара, сверка и повтор."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def сценарий(корень_кода):
    os.environ['FUM_КОД_ЧАСТНОГО_АРХИВА'] = корень_кода
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import test_частного_архива_этапа as проверка
    ф = проверка.АрхивЭтапа('runTest')
    начало = time.perf_counter_ns()
    try:
        ф.setUp()
        подготовка = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        план = ф.план()
        сухой = time.perf_counter_ns() - начало
        выбор = ф.выбор(план)
        профиль = {}
        начало = time.perf_counter_ns()
        итог = проверка.модуль.применить(ф.вход, план, выбор, профиль=профиль)
        применение = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        ф.assertEqual(проверка.модуль.проверить(ф.вход, план, выбор), итог)
        проверка_архива = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        ф.assertEqual(ф.этап.каркас.validate_layout(ф.корень)['mode'], 'validate')
        _, _, генератор, _ = проверка.модуль.код(ф.вход['код'])
        файлы = {э['путь']: (ф.корень / э['путь']).read_bytes() for э in план['публичные_файлы']}
        генератор.публикация(ф.корень, файлы)
        навигация = time.perf_counter_ns() - начало
        for имя, данные in [('вход', ф.вход), ('план', план), ('выбор', выбор)]:
            путь = ф.частный / (имя + '.json')
            with os.fdopen(os.open(путь, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600), 'wb') as поток:
                поток.write(проверка.модуль.байты(данные))
        начало = time.perf_counter_ns()
        процесс = subprocess.run([sys.executable, '-I', '-S', '-B', str(проверка.СКРИПТ), 'применить',
            '--вход', str(ф.частный / 'вход.json'), '--план', str(ф.частный / 'план.json'),
            '--выбор', str(ф.частный / 'выбор.json')], capture_output=True, check=True, timeout=60)
        повтор = time.perf_counter_ns() - начало
        ф.assertEqual(json.loads(процесс.stdout), итог)
        ф.assertEqual(ф.гит('rev-parse', 'HEAD'), план['снимок']['HEAD'])
        return {'фикстура_наносекунды': подготовка, 'сухой_план_наносекунды': сухой,
            'применение_наносекунды': применение, 'границы_применения': профиль,
            'проверка_архива_наносекунды': проверка_архива,
            'навигация_и_публикация_наносекунды': навигация,
            'повтор_новый_процесс_наносекунды': повтор,
            'файлов_архива': sum(э['тип'] == 'файл' for э in план['состав']),
            'байтов_архива': sum(э.get('байтов', 0) for э in план['состав']),
            'объектов_архива': len(план['состав']), 'файлов_публичного_плана': len(файлы),
            'повтор': итог['состояние'], 'повторного_переноса': итог['повторного_переноса'],
            'коммит_создан': итог['коммит_создан'], 'код': план['код']}
    finally:
        ф.doCleanups()


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--корень-кода', required=True)
    разбор.add_argument('--сценарий', action='store_true')
    разбор.add_argument('--выход')
    параметры = разбор.parse_args()
    if параметры.сценарий:
        print(json.dumps(сценарий(параметры.корень_кода), ensure_ascii=False, sort_keys=True))
        return
    корень = Path(__file__).resolve().parents[3]
    имена = ['Инструменты/fum-struktura-papok-zaprosov/scripts/частный_архив_этапа.py',
        'Инструменты/fum-struktura-papok-zaprosov/tests/test_частного_архива_этапа.py',
        'Инструменты/fum-struktura-papok-zaprosov/tests/профиль_частного_архива_этапа.py']
    хэши = {имя: hashlib.sha256((корень / имя).read_bytes()).hexdigest() for имя in имена}
    серия = []
    for номер in range(2):
        процесс = subprocess.run([sys.executable, '-I', '-S', '-B', str(Path(__file__).resolve()),
            '--сценарий', '--корень-кода', параметры.корень_кода], capture_output=True, check=True, timeout=60)
        серия.append({'номер': номер + 1, **json.loads(процесс.stdout)})
    if хэши != {имя: hashlib.sha256((корень / имя).read_bytes()).hexdigest() for имя in имена}:
        raise ValueError('исходники изменились во время профиля')
    итог = {'схема': 'fum.профиль-частного-архива.1', 'исходники': хэши, 'серия': серия,
        'условия': 'Два новых изолированных процесса, одинаковый сценарий, кэш ФС не очищался; подготовка измерена отдельно.',
        'граница': 'Сумма вложенных стадий не прибавляется к применению. Чужие живые этапы не переносятся.',
        'решение_оптимизации': 'Сохранить алгоритм полного чтения и повторной сверки: ослабление состава, SHA или fsync не обосновано этим компактным профилем.',
        'ускорение_не_заявлено': True}
    данные = (json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    if параметры.выход:
        with os.fdopen(os.open(параметры.выход, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644), 'wb') as поток:
            поток.write(данные)
    print(данные.decode(), end='')


if __name__ == '__main__':
    главная()
