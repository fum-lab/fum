"""Адресный набор и сохранение профиля холодной фикстуры одним запуском."""
import argparse
import contextlib
import io
import json
from pathlib import Path
import unittest


def главная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--профиль', type=Path, required=True)
    п = парсер.parse_args()
    набор = unittest.TestSuite(unittest.defaultTestLoader.loadTestsFromName(имя) for имя in (
        'test_конверта_приёма', 'test_нативного_приёма',
        'test_снимка_нативного_источника', 'test_обнаружения_приёма'))
    вывод = io.StringIO()
    with contextlib.redirect_stdout(вывод):
        результат = unittest.TextTestRunner(verbosity=1).run(набор)
    print(вывод.getvalue(), end='')
    if not результат.wasSuccessful():
        return 1
    профили = [json.loads(с.removeprefix('FUM-PROFILE ')) for с in вывод.getvalue().splitlines()
        if с.startswith('FUM-PROFILE ')]
    if len(профили) != 1:
        raise ValueError('Нужен единственный профиль холодного приёма')
    with п.профиль.open('x', encoding='utf-8') as файл:
        json.dump(профили[0], файл, ensure_ascii=False, indent=2)
        файл.write('\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
