"""Сравнимый профиль нейтрального хвоста и отдельная цена сверки сжатия."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import time
import types

import test_запуска_слоёв
import снимок_нативного_источника as снимок
import фикстура_сжатия as фикстура


def _измерить(действие, повторов):
    начало = time.perf_counter_ns()
    for _ in range(повторов):
        действие()
    return time.perf_counter_ns() - начало


def выполнить_профиль():
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--база', required=True)
    разбор.add_argument('--выход', type=Path, required=True)
    аргументы = разбор.parse_args()
    корень = Path(__file__).resolve().parents[3]
    путь = 'Инструменты/fum-konvejyer-proizvodnyikh-vetok/scripts/снимок_нативного_источника.py'
    база = subprocess.check_output(['git', '-C', str(корень), 'rev-parse', аргументы.база + '^{commit}']).decode().strip()
    if база != аргументы.база:
        raise ValueError('Нужен полный OID базовой версии')
    старые_байты = subprocess.check_output(['git', '-C', str(корень), 'show', база + ':' + путь])
    старый = types.ModuleType('базовый_снимок')
    старый.__file__ = str(корень / путь)
    exec(compile(старые_байты, старый.__file__, 'exec'), старый.__dict__)
    код = корень / путь
    зависимости = [код, код.with_name('копии_нативного_сжатия.py'),
        Path(фикстура.__file__), Path(__file__).resolve()]
    хэши = lambda: {str(файл.relative_to(корень)): hashlib.sha256(файл.read_bytes()).hexdigest()
        for файл in зависимости}
    до = хэши()
    хвост = фикстура.строка({'type': 'event_msg', 'payload': {'type': 'agent_message', 'message': 'Открытый ответ'}}) * 500
    префикс = фикстура.префикс('00000000-0000-0000-0000-000000000001')
    полный = префикс + фикстура.строка(фикстура.сжатие())
    измерения = []
    for номер in range(5):
        пара = {}
        порядок = [('до', старый.проверить_хвост), ('после', снимок.проверить_хвост)]
        if номер % 2:
            порядок.reverse()
        for имя, функция in порядок:
            пара[имя] = _измерить(lambda: функция(хвост), 20)
        пара['сжатие_с_первичным_контекстом'] = _измерить(lambda: снимок._история_сжатия(полный), 200)
        измерения.append(пара)
    после = хэши()
    if до != после:
        raise ValueError('Код изменился при профилировании')
    результат = {'схема': 'fum.профиль-копий-сжатия.1', 'база': база,
        'код_до_sha256': hashlib.sha256(старые_байты).hexdigest(), 'код_после_sha256': после[путь],
        'файлы_измерения_sha256': после,
        'условия': {'строк_хвоста': 500, 'повторов_хвоста': 20, 'повторов_сжатия': 200,
            'хвост_sha256': hashlib.sha256(хвост).hexdigest(), 'сжатие_sha256': hashlib.sha256(полный).hexdigest(),
            'единица': 'наносекунды', 'таймер': 'perf_counter_ns',
            'граница': 'Только разбор и проверка открытых байтов в памяти; без диска, Git и подготовки базы'},
        'измерения': измерения,
        'медианы': {ключ: int(statistics.median(пара[ключ] for пара in измерения)) for ключ in измерения[0]}}
    with аргументы.выход.open('x', encoding='utf-8') as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
    print(json.dumps(результат['медианы'], ensure_ascii=False))


if __name__ == '__main__':
    выполнить_профиль()
