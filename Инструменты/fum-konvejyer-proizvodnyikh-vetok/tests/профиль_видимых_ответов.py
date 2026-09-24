"""Монотонный профиль одного прохода по открытым синтетическим событиям."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import sys
import time
import tracemalloc

СКРИПТЫ = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(СКРИПТЫ))
from видимые_ответы import извлечь

ЗАДАЧА = '00000000-0000-4000-8000-000000000001'


def main():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выход', required=True)
    параметры = разбор.parse_args()
    начало = (json.dumps({'type': 'session_meta', 'payload': {'id': ЗАДАЧА}}) + '\n').encode()
    событие = (json.dumps({'type': 'event_msg', 'payload': {'type': 'token_count', 'padding': 'x' * 512}}) + '\n').encode()
    ответ = (json.dumps({'type': 'response_item', 'payload': {'type': 'message', 'role': 'assistant',
        'phase': 'commentary', 'content': [{'type': 'output_text', 'text': 'Открытый ответ ё🙂'}]}},
        ensure_ascii=False) + '\n').encode()
    результаты = []
    for размер in (262144, 1048576):
        сырые = начало + событие * (размер // len(событие)) + ответ
        времена = []
        for _ in range(7):
            старт = time.monotonic_ns()
            итог = извлечь(сырые, ЗАДАЧА)
            времена.append(time.monotonic_ns() - старт)
            assert итог['состояние'] == 'сохранены' and len(итог['ответы']) == 1
        tracemalloc.start()
        извлечь(сырые, ЗАДАЧА)
        _, пик = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        результаты.append({'байтов': len(сырые), 'sha256': hashlib.sha256(сырые).hexdigest(),
            'повторов': len(времена), 'монотонные_нс': времена,
            'медиана_нс': int(statistics.median(времена)), 'пик_выделений_Python_байтов': пик})
    код = {имя: hashlib.sha256((СКРИПТЫ / имя).read_bytes()).hexdigest()
           for имя in ('видимые_ответы.py', 'извлечь-видимые-ответы.py', 'снимок_нативного_источника.py')}
    отчёт = {'схема': 'fum.профиль-видимых-ответов.1', 'хэши_кода': код,
        'граница': 'Чистый отбор из уже прочитанных байтов; ввод-вывод, Desktop и Git не измерены',
        'измерения': результаты,
        'оценка': 'Один проход без списка всех строк и без повторного разбора. Ускорение относительно прежней версии не заявляется.'}
    with Path(параметры.выход).open('x') as файл:
        json.dump(отчёт, файл, ensure_ascii=False, indent=2)
        файл.write('\n')
    print(json.dumps(отчёт, ensure_ascii=False))


if __name__ == '__main__':
    main()
