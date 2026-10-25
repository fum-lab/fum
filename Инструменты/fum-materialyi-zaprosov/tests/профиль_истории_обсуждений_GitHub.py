import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import statistics
import tempfile
import time
import tracemalloc

путь = Path(__file__).resolve().parents[1] / 'scripts' / 'архив_обсуждений_GitHub.py'
парсер = argparse.ArgumentParser()
парсер.add_argument('--выход', type=Path, required=True)
парсер.add_argument('--исходник', type=Path, default=путь)
аргументы = парсер.parse_args()
путь = аргументы.исходник
спецификация = importlib.util.spec_from_file_location('архив_обсуждений', путь)
архив = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(архив)
записи = [{'id': к, 'number': к, 'body': 'Повторяемое обсуждение ' * 20,
           'title': str(к), 'state': 'open', 'updated_at': '2026-10-05T00:00:00Z',
           'html_url': f'https://github.com/fum-lab/fum/issues/{к}'}
          for к in range(1, 1001)]
байты = json.dumps(записи, ensure_ascii=False).encode()
измерения = []
with tempfile.TemporaryDirectory() as временный:
    корень = Path(временный)
    for номер in range(8):
        архив.импортировать(корень, 'fum-lab/fum', str(номер), [('issues', байты), ('comments', b'[]')], полнота=True)
    for номер in range(5):
        tracemalloc.start(); начало = time.monotonic_ns()
        результат = архив.прочитать(корень, 'fum-lab/fum')
        длительность = time.monotonic_ns() - начало
        пик = tracemalloc.get_traced_memory()[1]; tracemalloc.stop()
        assert len(результат['обращения']) == 1000
        assert all(len(к['версии']) == 1 for к in результат['обращения'].values())
        полезные = json.dumps(результат['обращения'], ensure_ascii=False, sort_keys=True).encode()
        измерения.append({'длительность_нс': длительность, 'пик_байт': пик,
                          'результат_sha256': hashlib.sha256(полезные).hexdigest()})
данные = {'схема': 'fum.профиль-истории-обсуждений.1', 'код_sha256': hashlib.sha256(путь.read_bytes()).hexdigest(),
          'вход_sha256': hashlib.sha256(байты).hexdigest(), 'обращений': 1000, 'наблюдений': 8,
          'повторы': измерения, 'медиана_нс': statistics.median(к['длительность_нс'] for к in измерения),
          'граница': 'Только полное автономное чтение; создание фикстуры вне таймера, tracemalloc включён.'}
assert len({к['результат_sha256'] for к in измерения}) == 1
with аргументы.выход.open('x') as выход:
    json.dump(данные, выход, ensure_ascii=False, indent=2); выход.write('\n')
print(json.dumps({'медиана_нс': данные['медиана_нс'], 'код_sha256': данные['код_sha256']}, ensure_ascii=False))
