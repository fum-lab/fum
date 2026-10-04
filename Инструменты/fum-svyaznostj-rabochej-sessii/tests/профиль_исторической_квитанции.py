"""Адресный профиль чтения; подготовка реальной Git-фикстуры исключена из замеров."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import sys
import time

import test_исторической_квитанции as тесты


def измерить(выбор, повторов):
    модуль = тесты.загрузить()
    образцы = []
    for _ in range(повторов):
        профиль = {}
        результат = модуль.прочитать(выбор, профиль=профиль)
        if результат['результат']['коммит'] != выбор['исторический_коммит']:
            raise ValueError('профиль получил иной исторический результат')
        образцы.append(профиль)
    времена = [элемент['длительность_наносекунды'] for элемент in образцы]
    return {'коммит': выбор['исторический_коммит'], 'HEAD': выбор['ожидаемый_HEAD'],
        'образцы': образцы, 'медиана_наносекунды': int(statistics.median(времена)),
        'минимум_наносекунды': min(времена), 'максимум_наносекунды': max(времена)}


def main():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--повторов', type=int, default=5)
    парсер.add_argument('--выбор', action='append', default=[])
    парсер.add_argument('--sha256', action='append', default=[])
    аргументы = парсер.parse_args()
    if not 1 <= аргументы.повторов <= 100 or len(аргументы.выбор) != len(аргументы.sha256):
        raise ValueError('неверные параметры измерений')
    фикстура = None
    if аргументы.выбор:
        выборы = []
        for имя, ожидаемый in zip(аргументы.выбор, аргументы.sha256, strict=True):
            байты = Path(имя).read_bytes()
            if hashlib.sha256(байты).hexdigest() != ожидаемый:
                raise ValueError('SHA256 выбора для профиля отличается')
            выборы.append(тесты.загрузить().разобрать(байты))
    else:
        фикстура = тесты.ИсторическаяКвитанция()
        фикстура.setUp()
        выборы = [фикстура.выбор]
    try:
        результаты = [измерить(выбор, аргументы.повторов) for выбор in выборы]
        print(json.dumps({'схема': 'fum.профиль-исторического-чтения.1',
            'среда': {'Python': platform.python_version(), 'платформа': platform.system(),
                'машина': platform.machine()},
            'источник_sha256': hashlib.sha256(тесты.СКРИПТ.read_bytes()).hexdigest(),
            'граница': 'Только чтение .7/.9/receipt, native provenance и Git. Подготовка фикстуры исключена; '
                'файловый кэш ОС не очищается; Git без сети; экономия CPU/RSS и финансовая приёмка не заявляются.',
            'результаты': результаты}, ensure_ascii=False, sort_keys=True))
    finally:
        if фикстура is not None:
            фикстура.doCleanups()


if __name__ == '__main__':
    main()
