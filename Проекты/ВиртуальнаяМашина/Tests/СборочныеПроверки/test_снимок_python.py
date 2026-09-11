"""Явный снимок текущего Python для Swift-тестов без запуска второго интерпретатора."""
import contextlib
import builtins
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ИСТОЧНИК = Path(__file__).resolve().parents[2] / 'собрать.py'
описание = importlib.util.spec_from_file_location('сборка_снимка', ИСТОЧНИК)
сборка = importlib.util.module_from_spec(описание)
описание.loader.exec_module(сборка)


class ПроверкиСнимкаPython(unittest.TestCase):
    def вызвать(сам, аргументы):
        вывод = io.BytesIO()
        ошибки = io.StringIO()
        настоящее_открытие = сборка.os.open
        настоящее_потоковое = io.open
        def только_чтение(путь, флаги, *позиционные, **именованные):
            сам.assertEqual(флаги & (сборка.os.O_WRONLY | сборка.os.O_RDWR | сборка.os.O_CREAT | сборка.os.O_TRUNC), 0)
            return настоящее_открытие(путь, флаги, *позиционные, **именованные)
        def поток_чтения(путь, режим='r', *позиционные, **именованные):
            сам.assertFalse(set(режим) & set('wax+'))
            return настоящее_потоковое(путь, режим, *позиционные, **именованные)
        with contextlib.ExitStack() as ограждения, \
             patch.object(сборка.sys, 'argv', ['собрать.py', *аргументы]), \
             patch.object(сборка.sys, 'stdout', SimpleNamespace(buffer=вывод)), \
             patch.object(сборка.shutil, 'which', side_effect=AssertionError('Снимок не ищет Swift')), \
             patch.object(сборка, 'собрать', side_effect=AssertionError('Снимок не собирает поставку')), \
             patch.object(сборка.os, 'open', side_effect=только_чтение), \
             patch.object(io, 'open', side_effect=поток_чтения), \
             patch.object(builtins, 'open', side_effect=поток_чтения), \
             patch.object(сборка.subprocess, 'Popen', side_effect=AssertionError('Снимок не запускает процессы')), \
             contextlib.redirect_stderr(ошибки):
            for имя in ('mkdir', 'unlink', 'remove', 'rmdir', 'rename', 'replace', 'chmod', 'link', 'symlink'):
                ограждения.enter_context(patch.object(сборка.os, имя, side_effect=AssertionError('Снимок не меняет файлы')))
            try:
                код = сборка.главная()
            except SystemExit:
                сам.assertEqual(вывод.getvalue(), b'')
                raise
        return код, вывод.getvalue(), ошибки.getvalue()

    def test_СнимокБезСборкиИЗаписи(сам):
        ожидаемый = сборка.описать_python()
        код, байты, ошибки = сам.вызвать(['--описать-python'])
        сам.assertEqual(код, 0)
        сам.assertEqual(ошибки, '')
        сам.assertEqual(json.loads(байты), {'схема': 'fum.python-наблюдателя.1', 'python': ожидаемый})
        сам.assertEqual(байты, сборка.кодировать(json.loads(байты)))

    def test_РежимыНеСмешиваются(сам):
        for аргументы in [[], ['--сборка', '/открытая-фикстура'],
                           ['--поставка', '/открытая-фикстура'],
                           ['--описать-python', '--сборка', '/открытая-фикстура'],
                           ['--описать-python', '--поставка', '/открытая-фикстура'],
                           ['--описать-python', '--сборка', '/фикстура/сборка', '--поставка', '/фикстура/поставка'],
                           ['--описать-python', '--система', 'xcode']]:
            with сам.subTest(аргументы=аргументы), сам.assertRaises(SystemExit) as ошибка:
                сам.вызвать(аргументы)
            сам.assertEqual(ошибка.exception.code, 2)

    def test_НепригодныйИнтерпретаторНеДаётСнимок(сам):
        with patch.object(сборка, 'описать_python', side_effect=ValueError('CPython не предоставляет waitid/WNOWAIT')):
            код, байты, ошибки = сам.вызвать(['--описать-python'])
        сам.assertEqual(код, 1)
        сам.assertEqual(байты, b'')
        сам.assertIn('waitid/WNOWAIT', ошибки)

    def test_ПрежнийРежимПередаётСборочныеПараметры(сам):
        for флаги, система in [([], 'xcode'), (['--система', 'native'], 'native')]:
            вывод = io.BytesIO()
            with patch.object(сборка.sys, 'argv', ['собрать.py', '--сборка', '/фикстура/сборка', '--поставка', '/фикстура/поставка', *флаги]), \
                 patch.object(сборка.sys, 'platform', 'darwin'), \
                 patch.object(сборка.sys, 'stdout', SimpleNamespace(buffer=вывод)), \
                 patch.object(сборка.shutil, 'which', return_value='/фикстура/swift'), \
                 patch.object(сборка, 'собрать', return_value={'состояние': 'открытый результат'}) as выполнить:
                сам.assertEqual(сборка.главная(), 0)
            выполнить.assert_called_once_with(ИСТОЧНИК.parent, Path('/фикстура/сборка'), Path('/фикстура/поставка'),
                                               Path('/фикстура/swift'), система=система)
            сам.assertEqual(json.loads(вывод.getvalue()), {'состояние': 'открытый результат'})

    def test_ТриПовтораОдногоИнтерпретатора(сам):
        интервалы, снимки = [], []
        for _ in range(3):
            начало = time.monotonic_ns()
            код, байты, ошибки = сам.вызвать(['--описать-python'])
            интервалы.append(time.monotonic_ns() - начало)
            сам.assertEqual((код, ошибки), (0, ''))
            снимки.append(байты)
        сам.assertEqual(снимки, [снимки[0]] * 3)
        медиана = sorted(интервалы)[1]
        сам.assertLess(медиана, 100_000_000)
        print('ПРОФИЛЬ_СНИМКА_PYTHON=' + json.dumps({
            'схема': 'fum.профиль-снимка-python.1', 'исходник_sha256': hashlib.sha256(ИСТОЧНИК.read_bytes()).hexdigest(),
            'снимок_sha256': hashlib.sha256(снимки[0]).hexdigest(), 'интервалы_нс': интервалы,
            'медиана_нс': медиана, 'предкритерий_нс': 100_000_000,
            'граница': 'Вызов CLI внутри текущего Python с фиксацией stdout и ограждением запуска/записи; новый процесс не создаётся. Абсолютный путь интерпретатора не печатается.'
        }, ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    unittest.main()
