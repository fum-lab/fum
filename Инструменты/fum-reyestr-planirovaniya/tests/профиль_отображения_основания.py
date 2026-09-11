"""Три независимых Git-фикстуры: первая поправка и точный повтор без сети."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import time

from test_отображения_основания import связанное_основание, выполнить


def измерить(выход):
    стадии = {'первая поправка': [], 'точный повтор': []}
    for _ in range(3):
        with связанное_основание() as (корень, источник, решение, исполнитель, л, с0, запрос, поправка):
            начало = time.perf_counter_ns(); первый = выполнить(корень, поправка)
            стадии['первая поправка'].append(time.perf_counter_ns() - начало)
            начало = time.perf_counter_ns(); второй = выполнить(корень, поправка)
            стадии['точный повтор'].append(time.perf_counter_ns() - начало)
            assert первый == второй and первый['готов']
    папка = Path(__file__).resolve().parents[1]
    файлы = [папка / 'scripts/отображение_основания.py', папка / 'scripts/приём_направления.py',
             папка / 'scripts/принять-направление.py', Path(__file__), Path(__file__).with_name('test_отображения_основания.py')]
    результат = {'схема': 'fum.профиль-поправки-отображения.1', 'питон': platform.python_version(), 'система': platform.system(),
        'код': {путь.relative_to(папка).as_posix(): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in файлы},
        'стадии': {имя: {'наносекунды': замеры, 'медиана_мс': statistics.median(замеры) / 1e6} for имя, замеры in стадии.items()},
        'граница': 'Три независимых локальных Git-фикстуры с настоящими prepare, bind, C0, файловым fsync и повтором. Подготовка фикстуры исключена из адресных интервалов. Сеть, native и полная приёмка не выполняются. Интервалы последовательны; объём текущих историй в реальном репозитории отдельно влияет на стоимость.'}
    путь = Path(выход); путь.parent.mkdir(parents=True, exist_ok=True)
    путь.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({имя: значение['медиана_мс'] for имя, значение in результат['стадии'].items()}, ensure_ascii=False))


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True)
    измерить(парсер.parse_args().выход)
