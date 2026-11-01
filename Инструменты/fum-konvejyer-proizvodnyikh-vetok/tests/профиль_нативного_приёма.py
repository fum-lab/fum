"""Открытый профиль полного чтения адресного приёма на синтетическом JSONL."""
import argparse
import hashlib
import importlib
import json
from pathlib import Path
import statistics
import time

from фикстура_нативного_приёма import фикстура, граница, строка, ЗАДАЧА, РЕБЁНОК


def измерить(число, повторы):
    with фикстура() as данные:
        свидетельство = данные['свидетельство']
        остановка = Path(свидетельство['остановка']['путь'])
        строки = остановка.read_bytes().splitlines(keepends=True)
        фон = строка({'type': 'response_item', 'payload': {'type': 'message', 'role': 'assistant',
            'content': [{'type': 'output_text', 'text': 'Синтетический открытый вывод. ' * 10}]}})
        остановка.write_bytes(строки[0] + фон * число + b''.join(строки[1:]))
        свидетельство = данные['сохранить']()
        модуль = importlib.import_module('нативный_приём')
        результаты = []
        ожидаемое = None
        for _ in range(повторы):
            начало = time.perf_counter_ns()
            результат = модуль.прочитать(свидетельство, ЗАДАЧА, РЕБЁНОК,
                str(данные['корень']), данные['источник'], данные['текст'])
            результаты.append(time.perf_counter_ns() - начало)
            if ожидаемое is None:
                ожидаемое = результат
            assert результат == ожидаемое
        исходник = Path(модуль.__file__)
        return {'фоновых_записей': число, 'байтов_получателя': данные['источник'].stat().st_size,
            'длительности_нс': результаты, 'медиана_нс': statistics.median(результаты),
            'исходник_sha256': hashlib.sha256(исходник.read_bytes()).hexdigest()}


def главная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', type=Path, required=True)
    парсер.add_argument('--повторов', type=int, default=3)
    параметры = парсер.parse_args()
    if not 1 <= параметры.повторов <= 20:
        парсер.error('Нужно от 1 до 20 повторов')
    результат = {'схема': 'fum.профиль-нативного-приёма.1',
        'сценарии': [измерить(число, параметры.повторов) for число in (0, 2048)],
        'граница': 'Полное чтение двух синтетических источников; создание фикстуры исключено. '
            'Кэш ОС не очищается. Это не профиль большого живого JSONL координатора и не допуск записи.'}
    with параметры.выход.open('x', encoding='utf-8') as файл:
        json.dump(результат, файл, ensure_ascii=False, indent=2)
        файл.write('\n')
    print(json.dumps(результат, ensure_ascii=False))


if __name__ == '__main__':
    главная()
