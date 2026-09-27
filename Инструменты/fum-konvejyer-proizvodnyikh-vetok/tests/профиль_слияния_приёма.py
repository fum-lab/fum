"""Отделить подготовку Git, первый эффект и повторное восстановление."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import sys
import tempfile
import time

from фикстура_слияния_приёма import ФикстураПриёма


def измерить():
    запуски = []
    исходники = [Path(__file__), Path(__file__).with_name('фикстура_слияния_приёма.py'),
        Path(__file__).parents[1] / 'scripts/слияние_приёма.py',
        Path(__file__).parents[1] / 'scripts/эпизод_приёма.py',
        Path(__file__).parents[2] / 'fum-reyestr-planirovaniya/scripts/обратная_доставка.py']
    отпечатки = {str(п.relative_to(Path(__file__).parents[3])): hashlib.sha256(п.read_bytes()).hexdigest() for п in исходники}
    for номер in range(3):
        with tempfile.TemporaryDirectory(prefix='fum-профиль-приёма-') as папка:
            начало = time.monotonic_ns()
            пример = ФикстураПриёма(папка)
            подготовка = time.monotonic_ns() - начало
            вызовы = []
            def перечитать():
                вызовы.append(1)
                return пример.основание
            начало = time.monotonic_ns()
            with пример.приём(перечитать=перечитать) as приём:
                конструктор = time.monotonic_ns() - начало
                начало = time.monotonic_ns()
                первый = приём.применить()
                применение = time.monotonic_ns() - начало
                assert первый['стадия'] == 'применено'
                метки_начала = list(приём.профиль)
                приём.профиль.clear()
                число_допусков = len(вызовы)
                повторы = []
                for _ in range(3):
                    начало = time.monotonic_ns()
                    assert приём.применить() == первый
                    повторы.append(time.monotonic_ns() - начало)
                assert len(вызовы) == число_допусков
                запуски.append({'номер': номер + 1, 'подготовка_нс': подготовка,
                    'конструктор_нс': конструктор, 'применение_нс': применение,
                    'повторы_нс': повторы, 'число_первых_допусков': число_допусков,
                    'метки_применения': метки_начала, 'метки_повторов': list(приём.профиль)})
    assert отпечатки == {str(п.relative_to(Path(__file__).parents[3])): hashlib.sha256(п.read_bytes()).hexdigest() for п in исходники}
    return {'схема': 'fum.профиль-слияния-приёма.1', 'Python': sys.version, 'исходники_sha256': отпечатки,
        'запуски': запуски, 'медиана_применения_нс': statistics.median(з['применение_нс'] for з in запуски),
        'медиана_повтора_нс': statistics.median(п for з in запуски for п in з['повторы_нс']),
        'граница': 'Три малых Git-репозитория, по одному merge и три повтора после импорта. '
            'Нативный допуск заменён синтетическим callback; его число сохранено. '
            'Подготовка и конструктор отдельно. Запуск Python, очистка и реальный JSONL не включены. '
            'Кэш ОС не очищен. Внутренние метки деталируют внешние интервалы и не суммируются с ними.'}


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True, type=Path)
    результат = измерить()
    with парсер.parse_args().выход.open('x') as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write('\n')
    print(json.dumps({к: з for к, з in результат.items() if к not in ('запуски', 'исходники_sha256')}, ensure_ascii=False))
