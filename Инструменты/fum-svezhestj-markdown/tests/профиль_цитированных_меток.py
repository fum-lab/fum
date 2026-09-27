"""Стоимость чтения меток и наблюдаемая сохранность открытых цитат."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time

from test_меток_в_цитатах import цитата, свежесть


def измерить():
    результаты = []
    for объём in (0, 262144):
        тело = цитата() + 'я' * объём + '\n'
        текст = свежесть.attach_recency_block(тело, '2026-09-23 12:00:00 MSK',
            свежесть.content_digest(тело))
        длительности = []
        сохранность = True
        for _ in range(25):
            начало = time.perf_counter_ns()
            прочитано, метка, повреждение = свежесть.split_recency_block(текст)
            длительности.append(time.perf_counter_ns() - начало)
            сохранность = сохранность and прочитано == тело and not повреждение
        результаты.append({'байтов': len(текст.encode()), 'повторов': len(длительности),
            'медиана_наносекунды': statistics.median(длительности),
            'минимум_наносекунды': min(длительности), 'максимум_наносекунды': max(длительности),
            'исходные_цитаты_сохранены': сохранность})
    return {'схема': 'fum.профиль-цитированных-меток.1',
        'исходник_sha256': hashlib.sha256(Path(свежесть.__file__).read_bytes()).hexdigest(),
        'маска_sha256': hashlib.sha256(Path(свежесть.ограды_цитат.__file__).read_bytes()).hexdigest(),
        'архив_sha256': hashlib.sha256(Path(свежесть.маска_архива.__file__).read_bytes()).hexdigest(),
        'фикстуры': результаты,
        'граница': 'Чтение строк в памяти; без диска, Git, индекса и запуска Desktop. Сравнение корректности и стоимости, не всего цикла.'}


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True, type=Path)
    параметры = парсер.parse_args()
    итог = измерить()
    with параметры.выход.open('x', encoding='utf-8') as файл:
        файл.write(json.dumps(итог, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(итог, ensure_ascii=False))
