#!/usr/bin/env python3
"""Повторить две программы в новых процессах FUMA при неизменном бинарнике."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def главный():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--бинарник', required=True, type=Path)
    парсер.add_argument('--выход', required=True, type=Path)
    параметры = парсер.parse_args()
    assert not параметры.выход.exists(), 'Существующее свидетельство не заменяется'
    бинарник = параметры.бинарник.resolve(strict=True)
    отпечаток = хэш(бинарник.read_bytes())
    пакет = Path(__file__).resolve().parents[1]
    данные = (пакет / 'Проверки/композиция/определение.json').read_bytes()
    новая = json.loads(данные)
    новая['идентификатор'] = 'внешний-три'
    новая['определения'][0]['идентификатор'] = 'утроение'
    новая['определения'][0]['граф']['результат'][2] = 3

    def заменить(узел):
        if isinstance(узел, dict):
            for значение in узел.values():
                заменить(значение)
        elif isinstance(узел, list):
            if len(узел) == 5 and узел[0] == 'вызвать' and узел[2] == 'удвоение':
                узел[2] = 'утроение'
            for значение in узел:
                заменить(значение)
    заменить(новая)
    программы = [(данные, '{"пара":[6,8],"три":[2,4,6]}'),
                 (json.dumps(новая, ensure_ascii=False).encode(), '{"пара":[9,12],"три":[3,6,9]}')]
    свидетельства = []
    for определение, ожидаемое in программы:
        with tempfile.TemporaryDirectory(prefix='fum-composition-') as временный:
            каталог = Path(временный).resolve(strict=True)
            os.chmod(каталог, 0o700)
            память = каталог / 'память'
            память.mkdir(mode=0o700)
            исходники = каталог / 'определения'
            исходники.mkdir()
            for номер, чистое in enumerate(json.loads(определение)['определения']):
                (исходники / f'чистое-{номер}.json').write_text(json.dumps(чистое, ensure_ascii=False))
            путь = исходники / 'замыкание.json'
            путь.write_bytes(определение)
            вход = каталог / 'вход.json'
            вход.write_bytes(b'{}')

            def исполнить(аргументы):
                assert хэш(бинарник.read_bytes()) == отпечаток
                процесс = subprocess.run([str(бинарник), *аргументы, '--журнал', str(память)],
                                         capture_output=True, timeout=30)
                assert процесс.returncode == 0, процесс.stderr.decode()
                return json.loads(процесс.stdout)

            первый = исполнить(['--выполнить-оператор', '--определение', str(путь),
                                '--вход', str(вход), '--тип-входа', 'текст'])
            shutil.rmtree(исходники)
            вход.unlink()
            assert not исходники.exists() and not вход.exists()
            второй = исполнить(['--повторить-оператор', первый['квитанция']['описание']['идентификатор']])
            наблюдение = первый['наблюдение']
            assert наблюдение == второй['наблюдение']
            assert наблюдение['результат'] == {'тип': 'текст', 'значение': ожидаемое}
            assert [след['экземпляр'] for след in наблюдение['применения']] == [2, 3, 1, 4, 5, 6]
            свидетельства.append({'определение_sha256': хэш(определение),
                                  'хэш_наблюдения': наблюдение['хэшНаблюдения'],
                                  'результат': ожидаемое, 'все_исходные_файлы_удалены': True,
                                  'новый_процесс_для_повтора': True})
    assert хэш(бинарник.read_bytes()) == отпечаток
    результат = {'схема': 'fum.повтор-композиции.1', 'бинарник_sha256': отпечаток,
                 'число_процессов': 4, 'программы': свидетельства}
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(результат, ensure_ascii=False))


if __name__ == '__main__':
    главный()
