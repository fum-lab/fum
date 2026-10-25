"""Один полный приём и три чтения его квитанции; подготовка фикстуры выделена."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import time

from test_коммита_приёма import ПроверкаКоммитаПриёма


def главная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True)
    аргументы = парсер.parse_args()
    путь = Path(аргументы.выход)
    if путь.exists():
        парсер.error('Нужен новый выходной файл')
    начало = time.perf_counter_ns()
    результат = ПроверкаКоммитаПриёма().выполнить('обычный')
    длительность = time.perf_counter_ns() - начало
    инструменты = Path(__file__).resolve().parents[2]
    файлы = [инструменты / 'fum-konvejyer-proizvodnyikh-vetok/scripts' / имя
        for имя in ('коммит_приёма.py', 'связность_приёма.py')]
    файлы += [инструменты / 'fum-svyaznostj-rabochej-sessii/scripts' / имя
        for имя in ('создание_коммита.py', 'готовность_коммита.py')]
    итог = {'схема': 'fum.профиль-коммита-приёма.1', 'python': platform.python_version(),
        'платформа': platform.system(), 'архитектура': platform.machine(),
        'таймер': 'time.perf_counter_ns', 'весь_сценарий_наносекунды': длительность,
        'вход': 'Нативные открытые JSONL, H → S; четыре J, новая v4, один R, три повтора',
        'граница': 'Реальные локальные Git и холодный импорт из C; без настоящего Desktop и сети. '
            'Первый вызов создаёт R, повторы лишь проверяют квитанцию: это разные операции, не измерение ускорения одной операции.',
        'код': {ф.relative_to(инструменты.parent).as_posix(): hashlib.sha256(ф.read_bytes()).hexdigest() for ф in файлы},
        'результат': результат}
    with путь.open('x') as поток:
        json.dump(итог, поток, ensure_ascii=False, indent=2); поток.write('\n')
    print(json.dumps({'весь_сценарий_с': длительность / 1e9,
        'создание_с': результат['первый_вызов_наносекунды'] / 1e9,
        'повторы_с': [н / 1e9 for н in результат['повторы_наносекунды']]}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
