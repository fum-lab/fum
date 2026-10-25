"""Цена преобразования сохранённой выгрузки и размер её ограниченного свидетельства."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import sys
import time

СКРИПТЫ = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(СКРИПТЫ))
from видимые_ответы import извлечь
from свидетельство_видимых_ответов import свидетельство


def измерить():
    задача = '00000000-0000-4000-8000-000000000001'
    начало = {'type': 'session_meta', 'payload': {'id': задача}}
    сообщение = {'type': 'response_item', 'payload': {'type': 'message', 'role': 'assistant',
        'phase': 'commentary', 'id': 'synthetic-only',
        'content': [{'type': 'output_text', 'text': 'Открытый синтетический текст. ' * 128}]}}
    измерения = []
    for число in (8, 64):
        native = b''.join((json.dumps(з, ensure_ascii=False) + '\n').encode() for з in [начало] + [сообщение] * число)
        оригинал = (json.dumps(извлечь(native, задача), ensure_ascii=False, indent=2) + '\n').encode()
        времена = []
        for _ in range(7):
            старт = time.monotonic_ns(); итог = свидетельство(оригинал, задача)
            времена.append(time.monotonic_ns() - старт)
        if len(итог['ответы']) != число or итог['содержимое_включено']:
            raise AssertionError('Неверное свидетельство')
        измерения.append({'ответов': число, 'выгрузка_байтов': len(оригинал),
            'выгрузка_sha256': hashlib.sha256(оригинал).hexdigest(),
            'свидетельство_байтов': len((json.dumps(итог, ensure_ascii=False, indent=2) + '\n').encode()),
            'монотонные_нс': времена, 'медиана_нс': int(statistics.median(времена))})
    return {'схема': 'fum.профиль-свидетельства-ответов.1', 'измерения': измерения,
        'исходник_sha256': hashlib.sha256((СКРИПТЫ / 'свидетельство_видимых_ответов.py').read_bytes()).hexdigest(),
        'граница': 'Байты уже в памяти, файловый ввод-вывод, Desktop и native-отбор исключены. Размер свидетельства уменьшается за счёт отсутствия содержимого, которое остаётся в приватном оригинале; это не замена самого текста.'}


if __name__ == '__main__':
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выход', type=Path, required=True)
    аргументы = разбор.parse_args(); итог = измерить()
    with аргументы.выход.open('x') as файл: файл.write(json.dumps(итог, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(итог, ensure_ascii=False))
