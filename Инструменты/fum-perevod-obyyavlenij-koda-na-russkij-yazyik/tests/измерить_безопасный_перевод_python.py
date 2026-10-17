"""Воспроизводимый профиль выбора привязок без исполнения входного кода."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import sys
import tempfile
import time

каталог = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(каталог))
from безопасные_привязки_python import подготовить_замены


def измерить(выход, количество):
    вход = 'import subprocess\n' + ''.join(
        f'def function_{номер}(value, env):\n    result = value + 1\n    return subprocess.run([str(result)], env=env)\n'
        for номер in range(количество)
    )
    карта = {'value': 'значение', 'env': 'среда', 'result': 'результат'}
    карта.update({f'function_{номер}': f'функция_{номер}' for номер in range(количество)})
    повторы = []
    ожидаемый = None
    for _ in range(5):
        стадии = []
        начало = time.perf_counter_ns()
        итог, план, _ = подготовить_замены(вход, карта, измерения=стадии)
        время = time.perf_counter_ns() - начало
        хэш = hashlib.sha256(итог.encode()).hexdigest()
        if ожидаемый is not None and хэш != ожидаемый:
            raise RuntimeError('Нестабильный результат повторов')
        ожидаемый = хэш
        повторы.append({'длительность_наносекунды': время, 'стадии': стадии, 'замен': len(план)})
    результат = {
        'схема': 'fum.профиль-перевода-python.1', 'Python': platform.python_version(),
        'функций': количество, 'повторов': повторы,
        'вход_sha256': hashlib.sha256(вход.encode()).hexdigest(),
        'результат_sha256': ожидаемый,
        'исполнитель_sha256': hashlib.sha256((каталог / 'безопасные_привязки_python.py').read_bytes()).hexdigest(),
        'сценарий_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'медиана_наносекунды': statistics.median(п['длительность_наносекунды'] for п in повторы),
        'условия': 'Один процесс, пять последовательных повторов, без сети и исполнения входного кода; стадии последовательны.'
    }
    выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2, sort_keys=True) + '\n')
    print(json.dumps({'функций': количество, 'медиана_наносекунды': результат['медиана_наносекунды'], 'замен': len(план)}, ensure_ascii=False))


def измерить_поля(выход):
    """Малый пакет runtime+test; исходники в замерах не исполняются."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from test_пакет_перевода_python import ПроверкаПолейДинамическогоМодуля
    from пакет_перевода_python import подготовить, описание
    повторы, ожидаемый = [], None
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный)
        исходники, карта = ПроверкаПолейДинамическогоМодуля().фикстура(корень)
        вход = hashlib.sha256(json.dumps(исходники, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
        for _ in range(5):
            стадии = []
            начало = time.perf_counter_ns()
            план = подготовить(корень, карта, измерения=стадии)
            длительность = time.perf_counter_ns() - начало
            результат = hashlib.sha256(json.dumps(описание(план), ensure_ascii=False, sort_keys=True).encode()).hexdigest()
            if ожидаемый is not None and результат != ожидаемый:
                raise ValueError('Не совпал результат малой пакетной фикстуры')
            ожидаемый = результат
            повторы.append({'длительность_наносекунды': длительность, 'стадии': стадии})
        if any((корень / п).read_text() != т for п, т in исходники.items()):
            raise ValueError('Профиль изменил исходную фикстуру')
    результат = {'схема': 'fum.профиль-полей-модулей.1', 'Python': platform.python_version(),
        'вход_sha256': вход, 'результат_sha256': ожидаемый, 'повторы': повторы,
        'медиана_наносекунды': statistics.median(п['длительность_наносекунды'] for п in повторы),
        'код': {и: hashlib.sha256((каталог / и).read_bytes()).hexdigest() for и in
            ('безопасные_привязки_python.py', 'пакет_перевода_python.py')},
        'сценарий_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'фикстура_sha256': hashlib.sha256(Path(__file__).with_name('test_пакет_перевода_python.py').read_bytes()).hexdigest(),
        'условия': 'Пять последовательных повторов одной малой пары runtime+test; подготовка и исполнение входного кода исключены. Весь пакет включает вложенные стадии, их времена не складываются.'}
    with выход.open('x') as поток:
        поток.write(json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2) + '\n')
    print(json.dumps({'медиана_наносекунды': результат['медиана_наносекунды'], 'вход_sha256': вход, 'результат_sha256': ожидаемый}, ensure_ascii=False))


if __name__ == '__main__':
    разборщик = argparse.ArgumentParser(description=__doc__)
    разборщик.add_argument('--выход', type=Path, required=True)
    разборщик.add_argument('--функций', type=int, default=400)
    разборщик.add_argument('--поля-модулей', action='store_true')
    аргументы = разборщик.parse_args()
    if аргументы.поля_модулей:
        измерить_поля(аргументы.выход)
    else:
        измерить(аргументы.выход, аргументы.функций)
