"""Адресные сценарии и фазы одного предпросмотра с разными источниками."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import unittest

КОРЕНЬ = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(КОРЕНЬ / 'tests'), str(КОРЕНЬ / 'scripts')]
from test_терминала_отказов import ПроверкаТерминалаОтказов


def сценарий(метод):
    return ПроверкаТерминалаОтказов(метод.__name__)


def выполнить(выход):
    путь = Path(выход).absolute()
    if путь.exists() or путь.is_symlink() or путь.parent != путь.parent.resolve():
        raise ValueError('Нужен новый файл профиля в физическом каталоге')
    измеряемый = сценарий(ПроверкаТерминалаОтказов.test_п_живой_источник_команды_отделён_от_пакета)
    набор = unittest.TestSuite([
        измеряемый,
        сценарий(ПроверкаТерминалаОтказов.test_р_пакет_не_подменяет_живой_локатор_команды),
        сценарий(ПроверкаТерминалаОтказов.test_я_терминал_записывается_один_раз_и_повтор_не_читает_живое),
    ])
    результат = unittest.TextTestRunner(verbosity=2).run(набор)
    if not результат.wasSuccessful():
        return 1
    источники = [
        КОРЕНЬ / 'scripts/завершение_отказавшего_приёма.py',
        КОРЕНЬ / 'scripts/прочитать_исторический_отказ.py',
        КОРЕНЬ / 'tests/фикстура_терминала_отказов.py',
        КОРЕНЬ / 'tests/test_терминала_отказов.py',
        Path(__file__).resolve(),
    ]
    данные = {
        'схема': 'fum.профиль-разделения-источников-приёма.1',
        'граница': 'Один успешный предпросмотр на открытой FS/Git-фикстуре; подготовка фикстуры, последующие тесты, реальный ROOT и Desktop исключены. Нет парного сравнения и заявления об ускорении.',
        'измерений': 1,
        'сценариев_успешно': результат.testsRun,
        'вход_sha256': измеряемый.хэш_входа,
        'терминал_sha256': измеряемый.хэш_терминала,
        'фазы_нс': измеряемый.профиль_источника,
        'код': {str(п.relative_to(КОРЕНЬ)): hashlib.sha256(п.read_bytes()).hexdigest() for п in источники},
    }
    сырые = (json.dumps(данные, ensure_ascii=False, sort_keys=True) + '\n').encode()
    дескриптор = os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(дескриптор, 'wb') as поток:
        поток.write(сырые)
        поток.flush()
        os.fsync(поток.fileno())
    print(json.dumps({'профиль_sha256': hashlib.sha256(сырые).hexdigest(), 'измерений': 1}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', required=True)
    аргументы = парсер.parse_args()
    raise SystemExit(выполнить(аргументы.выход))
