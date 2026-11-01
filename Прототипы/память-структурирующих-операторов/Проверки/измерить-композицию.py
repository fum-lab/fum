#!/usr/bin/env python3
"""Проверить композицию на сохранённых входах и отдельно измерить стадии старого бинарника."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import time


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def главный():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--бинарник', required=True, type=Path)
    парсер.add_argument('--выход', required=True, type=Path)
    парсер.add_argument('--повторов', type=int, default=25)
    параметры = парсер.parse_args()
    assert 3 <= параметры.повторов <= 100
    assert not параметры.выход.exists(), 'Существующий профиль не заменяется'
    пакет = Path(__file__).resolve().parents[1]
    определение = пакет / 'Проверки/композиция/определение.json'
    вход = (пакет / 'Проверки/композиция/вход.json').read_bytes()
    бинарник = параметры.бинарник.resolve(strict=True)
    исходники = {str(путь.relative_to(пакет)): хэш(путь.read_bytes())
                 for путь in sorted((пакет / 'Sources').rglob('*.swift'))}
    повторы = []
    эталон = None
    for номер in range(параметры.повторов):
        начало = time.perf_counter_ns()
        процесс = subprocess.run([str(бинарник), 'исполнить', '--определение', str(определение),
                                  '--вход', 'текст', '--профиль'],
                                 input=вход, capture_output=True, timeout=30)
        длительность = time.perf_counter_ns() - начало
        assert процесс.returncode == 0, процесс.stderr.decode()
        наблюдение = json.loads(процесс.stdout)
        assert наблюдение['схема'] == 'fum.наблюдение-оператора.2'
        assert наблюдение['результат'] == {'тип': 'текст', 'значение': '{"пара":[6,8],"три":[2,4,6]}'}
        assert [запись['экземпляр'] for запись in наблюдение['применения']] == [2, 3, 1, 4, 5, 6]
        assert эталон is None or процесс.stdout == эталон
        эталон = процесс.stdout
        стадии = [json.loads(строка) for строка in процесс.stderr.splitlines()]
        assert [запись['стадия'] for запись in стадии] == [
            'загрузка', 'разбор', 'разрешение-определений', 'проверка-композиции',
            'проверка', 'исполнение', 'трасса']
        assert all(запись['исход'] == 'успешно' and запись['наносекунды'] >= 0 for запись in стадии)
        повторы.append({'номер': номер + 1, 'процесс_наносекунды': длительность, 'стадии': стадии})
    assert исходники == {str(путь.relative_to(пакет)): хэш(путь.read_bytes())
                        for путь in sorted((пакет / 'Sources').rglob('*.swift'))}
    результат = {'схема': 'fum.профиль-композиции.1', 'бинарник_sha256': хэш(бинарник.read_bytes()),
                 'исходники_sha256': исходники, 'вход_sha256': хэш(вход),
                 'определение_sha256': хэш(определение.read_bytes()), 'наблюдение_sha256': хэш(эталон),
                 'архитектура': platform.machine(), 'повторы': повторы,
                 'медианы_наносекунды': {запись['стадия']: int(statistics.median(
                     повтор['стадии'][номер]['наносекунды'] for повтор in повторы))
                     for номер, запись in enumerate(повторы[0]['стадии'])},
                 'граница': 'Debug; один процесс на повтор; сборка исключена; кэш ОС не очищен; стадии не перекрываются'}
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'повторов': len(повторы), 'медианы_наносекунды': результат['медианы_наносекунды']}, ensure_ascii=False))


if __name__ == '__main__':
    главный()
