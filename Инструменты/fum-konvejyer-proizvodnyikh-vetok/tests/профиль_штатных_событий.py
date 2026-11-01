"""Полное чтение синтетического потока: время и число разборов JSON отдельно."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time
from unittest import mock

import test_запуска_слоёв
import снимок_нативного_источника as снимок
import полный_поток_передачи as полный
import контроль_первичного_потока as контроль
from фикстура_нативного_приёма import РЕБЁНОК, строка
from фикстура_штатных_событий import начальные_события, изменение_файлов, обновление


def измерить(число, файлы):
    события = [{'type': 'session_meta', 'payload': {'id': РЕБЁНОК}}, *начальные_события()[:4]]
    граница = len(b''.join(map(строка, события[:4])))
    обычное = {'type': 'response_item', 'payload': {'type': 'custom_tool_call_output',
        'output': 'Открытый синтетический вывод с ё. ' * 8}}
    события += [изменение_файлов({'открытый.txt': обновление()}) if файлы else обычное] * число
    сырые = b''.join(map(строка, события))
    with mock.patch.object(снимок.хранение, 'разобрать', wraps=снимок.хранение.разобрать) as разбор:
        полный.проверить(сырые, граница)
        разборов = разбор.call_count
    длительности = []
    for _ in range(3):
        начало = time.perf_counter_ns()
        полный.проверить(сырые, граница)
        длительности.append(time.perf_counter_ns() - начало)
    return {'файлы': файлы, 'фоновых_строк': число, 'строк': len(события), 'байтов': len(сырые),
        'вход_sha256': hashlib.sha256(сырые).hexdigest(), 'разборов_json': разборов,
        'длительности_нс': длительности, 'медиана_нс': statistics.median(длительности)}


def главная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', type=Path, required=True)
    парсер.add_argument('--с-файлами', action='store_true')
    параметры = парсер.parse_args()
    результаты = [измерить(число, файлы) for файлы in ((False, True) if параметры.с_файлами else (False,))
                  for число in (0, 512, 4096)]
    пути = [Path(м.__file__) for м in (снимок, полный, контроль, контроль.происхождение)]
    пути.append(Path(__file__))
    код = {п.name: hashlib.sha256(п.read_bytes()).hexdigest() for п in пути}
    результат = {'схема': 'fum.профиль-штатных-событий.1', 'код': код, 'сценарии': результаты,
        'граница': 'Полный разбор синтетического потока в текущем процессе. Создание байтов и '
            'инструментальный счёт JSON исключены из времени; три повтора без очистки кэша ОС. '
            'Это не стоимость Desktop, большой истории корня, Git, сети или всей интеграции.'}
    with параметры.выход.open('x', encoding='utf-8') as файл:
        json.dump(результат, файл, ensure_ascii=False, indent=2); файл.write('\n')
    print(json.dumps(результат, ensure_ascii=False))


if __name__ == '__main__':
    главная()
