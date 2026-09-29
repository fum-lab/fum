"""Воспроизводимое измерение чистого селектора на открытой малой фикстуре."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import time

from test_ожиданий_обратного_приёма import H, S, последовательность, ожидания


def измерить(повторы=7, вызовы=1000):
    нативный = последовательность()
    номера = {H: 'wait-H', S: 'wait-S'}
    отправки = {H: 'send-H', S: 'send-S'}
    байты = json.dumps(нативный, ensure_ascii=False, sort_keys=True).encode()
    образец = ожидания.проверить(нативный, номера, отправки)
    интервалы = []
    for _ in range(повторы):
        начало = time.monotonic_ns()
        for _ in range(вызовы):
            результат = ожидания.проверить(нативный, номера, отправки)
            if результат != образец: raise ValueError('Изменился результат повторного выбора')
        интервалы.append(time.monotonic_ns() - начало)
        if json.dumps(нативный, ensure_ascii=False, sort_keys=True).encode() != байты:
            raise ValueError('Селектор изменил вход')
    return {'схема': 'fum.профиль-ожиданий-обратного-приёма.1',
            'часы': 'time.monotonic_ns', 'повторы': повторы, 'вызовов_в_повторе': вызовы,
            'длительности_нс': интервалы,
            'медиана_на_вызов_нс': statistics.median(интервалы) / вызовы,
            'вход_sha256': hashlib.sha256(байты).hexdigest(),
            'код_sha256': hashlib.sha256(Path(ожидания.__file__).read_bytes()).hexdigest(),
            'граница': 'Только чистый выбор на малой фикстуре; чтение JSONL, Git, замки, '
                       'подготовка фикстуры, расход LLM и весь конвейер не измерены.'}


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', type=Path, required=True)
    параметры = парсер.parse_args()
    результат = измерить()
    дескриптор = os.open(параметры.выход, os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_WRONLY, 0o600)
    with os.fdopen(дескриптор, 'wb') as поток:
        поток.write((json.dumps(результат, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode())
        поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'схема': результат['схема'],
                      'медиана_на_вызов_нс': результат['медиана_на_вызов_нс']}, ensure_ascii=False))


if __name__ == '__main__':
    выполнить()
