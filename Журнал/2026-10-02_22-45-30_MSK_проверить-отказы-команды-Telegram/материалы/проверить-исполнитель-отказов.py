"""Адресные проверки самого исполнителя A7; TDLib и прежний набор не запускаются."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


КОРЕНЬ = Path(__file__).resolve().parents[3]
ИСПОЛНИТЕЛЬ = КОРЕНЬ / 'Приложения/FUMA/Packages/КлиентTelegram/Проверки/проверить-команду.py'
СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location('проверка_отказов_команды', ИСПОЛНИТЕЛЬ)
МОДУЛЬ = importlib.util.module_from_spec(СПЕЦИФИКАЦИЯ)
СПЕЦИФИКАЦИЯ.loader.exec_module(МОДУЛЬ)


class ПроверкиИсполнителя(unittest.TestCase):
    def прогнать(сам, таймАут):
        with tempfile.TemporaryDirectory(prefix='fum-a7-harness-') as временный:
            каталог = Path(временный).resolve()
            бинарник = каталог / 'команда'
            бинарник.write_bytes('Тестовый вход'.encode())
            фикстуры = каталог / 'фикстуры'
            фикстуры.mkdir(mode=0o700)
            вывод, ошибки = io.StringIO(), io.StringIO()

            def процесс(аргументы, **параметры):
                if аргументы[0] == '/usr/bin/clang':
                    Path(аргументы[4]).write_bytes('Тестовая библиотека'.encode())
                    return subprocess.CompletedProcess(аргументы, 0, b'', b'')
                if таймАут:
                    raise subprocess.TimeoutExpired(аргументы, 45, output=b'partial stdout', stderr=b'partial stderr')
                отчёт = {'схема': 'fum.автономный-запуск-телеграма.1', 'библиотекаЗагружена': True,
                         'ошибка': 'требуется_разбор', 'ожиданиеОтветаСекунд': 5.1,
                         'закрытиеСекунд': 0.2, 'загрузкаСекунд': 0.3, 'связываниеСекунд': 0.4,
                         'закрытие': []}
                return subprocess.CompletedProcess(аргументы, 2, json.dumps(отчёт).encode(), b'')

            with patch.object(МОДУЛЬ.tempfile, 'mkdtemp', return_value=str(фикстуры)), \
                    patch.object(МОДУЛЬ.subprocess, 'run', side_effect=процесс), \
                    contextlib.redirect_stdout(вывод), contextlib.redirect_stderr(ошибки):
                код = МОДУЛЬ.проверитьОтказы(бинарник)
            профиль = json.loads(вывод.getvalue())
            сам.assertEqual(код, 2)
            сам.assertEqual(профиль['исход'], 'неуспех')
            измерение = профиль['измерения'][0]
            сам.assertEqual(измерение['фаза'], 'запуск')
            сам.assertGreaterEqual(измерение['процессНаносекунд'], 0)
            if таймАут:
                сам.assertEqual(профиль['ошибка'], 'внешний_тайм_аут')
                сам.assertEqual((фикстуры / 'неверная-корреляция/stdout.bin').read_bytes(), b'partial stdout')
                сам.assertEqual((фикстуры / 'неверная-корреляция/stderr.bin').read_bytes(), b'partial stderr')
                сам.assertIn(str(фикстуры), ошибки.getvalue())
            else:
                сам.assertEqual(профиль['ошибка'], 'неподтверждённая_проверка')
                сам.assertEqual(измерение['ожиданиеОтветаСекунд'], 5.1)
                сам.assertEqual(измерение['закрытиеСекунд'], 0.2)

    def test_таймАутСохраняетЧастичныйВывод(сам):
        сам.прогнать(True)

    def test_невернаяФормаСохраняетИзмерения(сам):
        сам.прогнать(False)

    def test_лишнийАргументНеЗапускаетПрежнийНабор(сам):
        with patch.object(sys, 'argv', [str(ИСПОЛНИТЕЛЬ), '/неиспользуемая-команда', '--проверить-отказы', 'лишний']), \
                patch.object(subprocess, 'run', side_effect=RuntimeError('Прежний набор запрещён')), \
                contextlib.redirect_stderr(io.StringIO()):
            with сам.assertRaises(SystemExit) as отказ:
                runpy.run_path(str(ИСПОЛНИТЕЛЬ), run_name='__main__')
            сам.assertEqual(отказ.exception.code, 2)


if __name__ == '__main__':
    unittest.main()
