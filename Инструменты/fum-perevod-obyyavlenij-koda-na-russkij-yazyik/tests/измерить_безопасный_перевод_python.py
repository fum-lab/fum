"""Воспроизводимый профиль выбора привязок без исполнения входного кода."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import sys
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


if __name__ == '__main__':
    разборщик = argparse.ArgumentParser(description=__doc__)
    разборщик.add_argument('--выход', type=Path, required=True)
    разборщик.add_argument('--функций', type=int, default=400)
    аргументы = разборщик.parse_args()
    измерить(аргументы.выход, аргументы.функций)
