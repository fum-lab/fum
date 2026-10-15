#!/usr/bin/env python3
"""Парный профиль старого полного и нового отложенного нормативного набора."""
from __future__ import annotations
import argparse
import hashlib
import json
import resource
import statistics
import subprocess
import sys
import time
from pathlib import Path
from test_декомпозиция_правил_агентов import ПроверкаОтложеннойНормативнойГраницы, СЦЕНАРИЙ


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выход', type=Path, required=True)
    арг = разбор.parse_args()
    if арг.выход.exists(): разбор.error('выход уже существует')
    класс = ПроверкаОтложеннойНормативнойГраницы
    класс.setUpClass()
    тест = класс()
    try:
        старый, _ = тест.стенд(новый=False)
        новый, _ = тест.стенд()
        выборки = {'исторический': [], 'отложенный': []}
        for раунд in range(5):
            порядок = [('исторический', старый), ('отложенный', новый)]
            if раунд % 2: порядок.reverse()
            for имя, корень in порядок:
                начало = time.perf_counter_ns()
                п = subprocess.run([sys.executable, '-B', str(СЦЕНАРИЙ),
                    '--корень-репозитория', str(корень), 'проверить'], capture_output=True)
                длительность = time.perf_counter_ns() - начало
                if п.returncode: raise RuntimeError(п.stderr.decode())
                выборки[имя].append(длительность)
        итог = {'схема': 'fum.профиль-отложенной-нормативной-границы.1',
            'метод': 'Пять пар с чередованием порядка, отдельный процесс на каждый полный набор.',
            'выборки_наносекунды': выборки,
            'медианы_наносекунды': {и: int(statistics.median(в)) for и, в in выборки.items()},
            'пиковая_память_дочерних_процессов_байты': resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss * (1 if sys.platform == 'darwin' else 1024),
            'граница_памяти': 'Совокупный максимум дочерних процессов; не разность двух профилей.',
            'sha256_проверителя': hashlib.sha256(СЦЕНАРИЙ.read_bytes()).hexdigest(),
            'sha256_фикстур': hashlib.sha256(Path(__file__).with_name('test_декомпозиция_правил_агентов.py').read_bytes()).hexdigest(),
            'коммит_основы': 'e31409e0c538cd133f8cd76f39a8d9f2c61f7800',
            'пины_помощников': {ф.name: hashlib.sha256(ф.read_bytes()).hexdigest() for ф in sorted(СЦЕНАРИЙ.parent.glob('*.py'))},
            'решение': 'Сохранить полную семантическую проверку. Оптимизация не выполнялась.'}
        with арг.выход.open('x', encoding='utf-8') as ф:
            json.dump(итог, ф, ensure_ascii=False, indent=2); ф.write('\n')
        print(json.dumps(итог, ensure_ascii=False))
    finally:
        тест.doCleanups()
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
