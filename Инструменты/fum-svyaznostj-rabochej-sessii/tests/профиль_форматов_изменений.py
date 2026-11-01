"""Сравнить стоимость раннего охвата с проверкой форматов и без неё."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time
from test_форматы_раннего_охвата import ПроверкаФорматов, СКРИПТ


def измерить():
    случай = ПроверкаФорматов()
    случай.setUp()
    try:
        for номер in range(30):
            случай.записать(f'Данные/текст-{номер}.md', 'Открытые данные\n')
        случай.записать('Данные/неизвестный.cjs', 'const имя = 1;\n')
        def снимок():
            return {п.relative_to(случай.корень).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest()
                    for п in случай.корень.rglob('*') if п.is_file() and '.git' not in п.parts}
        исходный = снимок()
        статус = случай.гит('status', '--porcelain=v1', '-z', '--untracked-files=all')
        замеры = []
        for пара in range(3):
            for форматы in ((False, True) if пара % 2 == 0 else (True, False)):
                команда = [sys.executable, '-B', str(СКРИПТ), '--корень', str(случай.корень), '--запрос', случай.запрос]
                if форматы:
                    команда.append('--форматы')
                начало = time.perf_counter_ns()
                результат = subprocess.run(команда, capture_output=True, text=True)
                длительность = time.perf_counter_ns() - начало
                if результат.returncode != (1 if форматы else 0):
                    raise ValueError('Неожиданный результат профиля: ' + результат.stdout + результат.stderr)
                данные = json.loads(результат.stdout)
                if форматы and not any('Неизвестный формат' in о for о in данные['ошибки']):
                    raise ValueError('Отказ не связан с форматом')
                замеры.append({'пара': пара, 'проверка_форматов': форматы, 'длительность_наносекунды': длительность, 'код': результат.returncode})
        if снимок() != исходный or случай.гит('status', '--porcelain=v1', '-z', '--untracked-files=all') != статус:
            raise ValueError('Проверка изменила входы')
        return {'схема': 'fum.профиль-ранних-форматов.1', 'входы': исходный, 'входы_неизменны': True, 'замеры': замеры,
                'медианы_наносекунды': {имя: statistics.median(з['длительность_наносекунды'] for з in замеры if з['проверка_форматов'] == режим)
                                      for имя, режим in [('охват', False), ('охват_и_форматы', True)]},
                'граница': 'Три чередующиеся пары реального CLI на одной открытой Git-фикстуре. Старый охват пропускает неизвестный формат, новый отклоняет его. Это цена раннего допуска, не замер полной проекции или экономии токенов; подготовка и очистка вне таймера.'}
    finally:
        случай.doCleanups()


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', type=Path, required=True)
    параметры = парсер.parse_args()
    результат = измерить()
    with параметры.выход.open('x') as файл:
        json.dump(результат, файл, ensure_ascii=False, indent=2)
        файл.write('\n')
    print(json.dumps(результат['медианы_наносекунды'], ensure_ascii=False))
