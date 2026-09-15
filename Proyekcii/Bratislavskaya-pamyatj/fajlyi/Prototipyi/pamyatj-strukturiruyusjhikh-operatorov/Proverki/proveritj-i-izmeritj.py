#!/usr/bin/env python3
"""Сквозные ожидания CLI и профиль открытых входов; сборка выполняется отдельно."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import tempfile
import time


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def выполнить(бинарник, определение, тип, вход, профиль=False):
    команда = [str(бинарник), 'исполнить', '--определение', str(определение), '--вход', тип]
    if профиль:
        команда.append('--профиль')
    начало = time.perf_counter_ns()
    процесс = subprocess.run(команда, input=вход, capture_output=True, timeout=60)
    длительность = time.perf_counter_ns() - начало
    return процесс, длительность


def главный():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--бинарник', required=True, type=Path)
    парсер.add_argument('--выход', required=True, type=Path)
    параметры = парсер.parse_args()
    пакет = Path(__file__).resolve().parents[1]
    определения = пакет / 'Sources/FUMStructuringOperatorMemory/Определения'
    исходное = определения / 'UTF-8-в-UTF-32LE.json'
    нормализация = определения / 'нормализация.json'
    бинарник = параметры.бинарник.resolve(strict=True)
    процесс, _ = выполнить(бинарник, исходное, 'байты', bytes.fromhex('D1 91'))
    assert процесс.returncode == 0, процесс.stderr.decode()
    результат = json.loads(процесс.stdout)
    assert результат['результат'] == {'тип': 'байты', 'значение': [81, 4, 0, 0]}
    assert результат['скаляры'] == [1105]
    for вход, позиция in [(bytes.fromhex('41 C0 AF'), 1), (bytes.fromhex('D1'), 1)]:
        отказ, _ = выполнить(бинарник, исходное, 'байты', вход)
        assert отказ.returncode != 0 and отказ.stdout == b''
        assert json.loads(отказ.stderr)['позицияБайта'] == позиция
    отказ, _ = выполнить(бинарник, исходное, 'байты', b'A' * 262145)
    assert отказ.returncode != 0 and отказ.stdout == b''
    неверный = subprocess.run([str(бинарник), 'исполнить', '--код', 'нет'], capture_output=True, timeout=5)
    assert неверный.returncode != 0 and неверный.stdout == b''
    замеры = []
    with tempfile.TemporaryDirectory(prefix='fum-operator-profile-') as временный:
        каталог = Path(временный)
        другойПорядок = json.loads(исходное.read_bytes())
        другойПорядок['шаги'][1]['аргументы']['порядок'] = 'BE'
        старшие = каталог / 'старшие.json'
        старшие.write_text(json.dumps(другойПорядок, ensure_ascii=False))
        процесс, _ = выполнить(бинарник, старшие, 'байты', bytes.fromhex('D1 91'))
        assert процесс.returncode == 0
        assert json.loads(процесс.stdout)['результат']['значение'] == [0, 0, 4, 81]
        замена = json.loads(нормализация.read_bytes())
        замена['шаги'] = [{'идентификатор': 'замена', 'оператор': 'заменить', 'аргументы': {'старое': 'ё', 'новое': 'я'}}]
        путьЗамены = каталог / 'замена.json'
        путьЗамены.write_text(json.dumps(замена, ensure_ascii=False))
        сценарии = [
            ('байты-смешанные', исходное, 'байты', bytes.fromhex('41 D1 91 E2 82 AC F0 9F 99 82') * 2048, None),
            ('байты-ASCII-предел', исходное, 'байты', b'A' * 262144, None),
            ('пробелы-ASCII', нормализация, 'текст', b' A   B ' * 4096, ('a b ' * 4096).strip()),
            ('пробелы-кириллица', нормализация, 'текст', (' Ё   Я ' * 4096).encode(), ('ё я ' * 4096).strip()),
            ('замена-кириллица', путьЗамены, 'текст', ('ё ' * 4096).encode(), 'я ' * 4096),
            ('графема', нормализация, 'текст', ('а' + '\u0301' * 16384).encode(), 'а' + '\u0301' * 16384),
        ]
        for имя, определение, тип, вход, ожидаемый in сценарии:
            повторы = []
            эталон = None
            for номер in range(5):
                процесс, длительность = выполнить(бинарник, определение, тип, вход, профиль=True)
                assert процесс.returncode == 0, процесс.stderr.decode()
                результат = json.loads(процесс.stdout)
                if ожидаемый is not None:
                    assert результат['результат'] == {'тип': 'текст', 'значение': ожидаемый}
                else:
                    независимые = [ord(символ) for символ in вход.decode('utf-8', errors='strict')]
                    assert результат['скаляры'] == независимые
                    # Внешний стандартный кодек используется только как независимая проверка профиля.
                    assert bytes(результат['результат']['значение']) == вход.decode('utf-8').encode('utf-32le')
                текущийХэш = хэш(процесс.stdout)
                assert эталон is None or эталон == текущийХэш
                эталон = текущийХэш
                стадии = [json.loads(строка) for строка in процесс.stderr.splitlines()]
                assert [стадия['стадия'] for стадия in стадии] == ['загрузка', 'разбор', 'проверка', 'исполнение', 'трасса']
                assert all(стадия['исход'] == 'успешно' and type(стадия['наносекунды']) is int and стадия['наносекунды'] >= 0 for стадия in стадии)
                повторы.append({'номер': номер + 1, 'процесс_наносекунды': длительность, 'стадии': стадии})
            замеры.append({'сценарий': имя, 'байтов_входа': len(вход), 'вход_sha256': хэш(вход),
                'определение_sha256': хэш(определение.read_bytes()), 'наблюдение_sha256': эталон,
                'медианы_наносекунды': {стадия: int(statistics.median(int(запись['стадии'][номер]['наносекунды']) for запись in повторы)) for номер, стадия in enumerate(['загрузка', 'разбор', 'проверка', 'исполнение', 'трасса'])}, 'повторы': повторы})
    исходники = {str(путь.relative_to(пакет)): хэш(путь.read_bytes()) for путь in sorted((пакет / 'Sources').rglob('*.swift'))}
    отчёт = {'схема': 'fum.профиль-операторов.1', 'бинарник_sha256': хэш(бинарник.read_bytes()),
        'исходники_sha256': исходники, 'сценарий_sha256': хэш(Path(__file__).read_bytes()),
        'Python': platform.python_version(), 'платформа': platform.system(), 'архитектура': platform.machine(),
        'Swift': subprocess.check_output(['swift', '--version'], text=True).strip(),
        'режим_сборки': 'переданный бинарник; команда сборки фиксируется отдельно в отчёте',
        'граница': 'Загрузка и разбор CLI раздельны; проверка библиотеки повторно защищает типизированный API. Время трассы исключено из исполнения. Сборка не включена; процесс включает запуск и сериализацию stdout.',
        'сквозной_контракт': 'успешно', 'замеры': замеры}
    параметры.выход.write_text(json.dumps(отчёт, ensure_ascii=False, sort_keys=True, indent=2) + '\n')
    print(json.dumps({'сквозной_контракт': 'успешно', 'медианы': {запись['сценарий']: запись['медианы_наносекунды'] for запись in замеры}}, ensure_ascii=False))


if __name__ == '__main__':
    главный()
