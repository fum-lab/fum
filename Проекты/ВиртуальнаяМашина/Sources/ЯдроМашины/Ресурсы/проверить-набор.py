"""Запустить один закреплённый unittest-набор и вернуть фактические счётчики."""
import contextlib
import json
from pathlib import Path
import sys
import unittest


def проверить(каталог, ожидается):
    if type(ожидается) is not int or ожидается <= 0:
        raise ValueError('Ожидаемое число тестов должно быть положительным целым')
    каталог = Path(каталог).resolve(strict=True)
    прежние_модули, прежний_путь = set(sys.modules), sys.path[:]
    try:
        with contextlib.redirect_stdout(sys.stderr):
            загрузчик = unittest.TestLoader()
            набор = загрузчик.discover(str(каталог), pattern='test_*.py')
            if загрузчик.errors or набор.countTestCases() != ожидается:
                raise ValueError('Обнаружен неполный набор или ошибка импорта тестов')
            результат = unittest.TextTestRunner(stream=sys.stderr, verbosity=1).run(набор)
        счётчики = {'выполнено': результат.testsRun, 'ошибки': len(результат.errors),
                    'отказы': len(результат.failures), 'пропущено': len(результат.skipped),
                    'ожидаемые_ошибки': len(результат.expectedFailures),
                    'неожиданные_успехи': len(результат.unexpectedSuccesses)}
        if счётчики['выполнено'] != ожидается or any(число for имя, число in счётчики.items() if имя != 'выполнено'):
            raise ValueError('Гостевой набор завершён неполно: ' + json.dumps(счётчики, ensure_ascii=False))
        return счётчики
    finally:
        # В поставке каждый набор запускается отдельным процессом. Эта граница
        # дополнительно изолирует последовательные автономные фикстуры модуля.
        sys.path[:] = прежний_путь
        for имя in set(sys.modules) - прежние_модули:
            файл = getattr(sys.modules[имя], '__file__', None)
            if файл is not None and Path(файл).resolve().is_relative_to(каталог):
                del sys.modules[имя]


if __name__ == '__main__':
    try:
        if len(sys.argv) != 3: raise ValueError('Нужны каталог тестов и ожидаемое число')
        print(json.dumps(проверить(Path(sys.argv[1]), int(sys.argv[2])), ensure_ascii=False, sort_keys=True))
    except (ValueError, OSError, ImportError) as ошибка:
        print(str(ошибка), file=sys.stderr)
        sys.exit(1)
