"""Малый профиль общего кодирования и проверенного переноса снимка."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import tempfile
import time

from test_перенос_снимков import ПереносСнимков
from test_служебные_имена_Git import ОПАСНЫЕ
import source_archive


def главная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True, type=Path)
    аргументы = парсер.parse_args()
    имена = ОПАСНЫЕ + ('.github', '.gitmodules.txt', 'имя-с-ё')
    измерения = []
    for повтор in range(3):
        начало = time.perf_counter_ns()
        for проход in range(1000):
            результат = [source_archive.source_path_segment(имя) for имя in имена]
        измерения.append({'стадия': 'кодирование', 'повтор': повтор, 'вызовов': 1000 * len(имена), 'наносекунды': time.perf_counter_ns() - начало})
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            модуль, старый, запрос, манифест, вход = ПереносСнимков().подготовить(корень)
            байты = {п.name: п.read_bytes() for п in старый.iterdir()}
            начало = time.perf_counter_ns()
            план = модуль.построить_план(корень, вход)
            граница = time.perf_counter_ns()
            модуль.применить(корень, вход, план)
            конец = time.perf_counter_ns()
            новый = source_archive.url_output_dir(корень, 'https://example.org/.gitmodules')
            assert байты == {п.name: п.read_bytes() for п in новый.iterdir()}
            source_archive.validate_snapshot_manifest(новый)
            измерения.extend([{'стадия': 'план', 'повтор': повтор, 'наносекунды': граница - начало}, {'стадия': 'применение с повторной проверкой входа', 'повтор': повтор, 'наносекунды': конец - граница}])
    база = Path(__file__).parents[1]
    файлы = ['scripts/source_archive.py', 'scripts/archive-chatgpt-share.py', 'scripts/перенести_снимки.py', 'tests/профиль_служебных_имён.py', 'tests/test_перенос_снимков.py', 'tests/test_служебные_имена_Git.py']
    данные = {'схема': 'fum.профиль-служебных-URL-имён.2', 'Python': platform.python_version(),
              'вход_кодовые_точки': [[ord(символ) for символ in имя] for имя in имена],
              'вход_sha256': hashlib.sha256(json.dumps(имена, ensure_ascii=False).encode()).hexdigest(),
              'код_sha256': {п: hashlib.sha256((база / п).read_bytes()).hexdigest() for п in файлы},
              'измерения': измерения, 'граница': 'Монотонные интервалы не перекрываются; подготовка временной фикстуры исключена. Никакой сети и Swift-сборки.',
              'критерий': 'Сохранность байтов, путей и числа вызовов; алгоритмическое изменение оправдано только наблюдаемой доминирующей стоимостью.'}
    аргументы.выход.parent.mkdir(parents=True, exist_ok=True)
    аргументы.выход.write_text(json.dumps(данные, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(измерения, ensure_ascii=False))


if __name__ == '__main__':
    главная()
