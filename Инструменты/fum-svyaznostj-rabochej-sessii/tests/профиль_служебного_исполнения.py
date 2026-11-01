"""Три новых bound subprocess: исходники, захват и импорт пяти настоящих dataclass."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time

from test_служебного_исполнения import СлужебноеИсполнение


def главная():
    п = argparse.ArgumentParser(description=__doc__)
    п.add_argument('--выход', type=Path, required=True)
    а = п.parse_args()
    assert not а.выход.exists()
    корень = Path(__file__).resolve().parents[3]
    пути = [Path(__file__).relative_to(корень).as_posix(),
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_служебного_исполнения.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_поздней_привязки_журнала.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/исполнение_принятого_кода.py',
        'Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py']
    хэши = {путь: hashlib.sha256((корень / путь).read_bytes()).hexdigest() for путь in пути}
    образцы = []
    for _ in range(3):
        ф = СлужебноеИсполнение('runTest'); ф.setUp()
        исходный = ф.ф.запуск
        def запустить(**аргументы):
            начало = time.perf_counter_ns()
            р = исходный(**аргументы)
            образцы.append({'процесс_с_захватом_нс': time.perf_counter_ns()-начало,
                **json.loads(р.stdout)['профиль']})
            return р
        ф.ф.запуск = запустить
        try:
            ф.test_пять_настоящих_dataclass_каркаса_из_принятых_байтов()
        finally:
            ф.doCleanups()
    assert хэши == {п: hashlib.sha256((корень / п).read_bytes()).hexdigest() for п in пути}
    результат = {'схема': 'fum.профиль-native-stdlib.1', 'образцы': образцы,
        'медианы_нс': {к: statistics.median(о[к] for о in образцы) for к in образцы[0]},
        'хэши_исходников': хэши,
        'граница': 'Три новых процесса -I -S -B с настоящими Git-репозиториями фикстуры. Setup и commits вне таймера. Захват включает Git и байты, исполнение включает hooks и импорт пяти dataclass. Кэш ОС не сбрасывался; это не рабочий цикл узла.',
        'решение_об_оптимизации': 'Одноразовый конечный pending, без повторного импорта проекта, без кэша непроверенного кода и без обхода guards. Исходная версия отказывает; коэффициент ускорения не выводится.'}
    а.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2)+'\n')
    а.выход.chmod(0o600)
    print(json.dumps({'образцов': len(образцы), 'медианы_нс': результат['медианы_нс']}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
