import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

спецификация = importlib.util.spec_from_file_location('восстановление', Path(__file__).with_name('проверить-восстановление.py'))
команда = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(команда)


class ПроверкиСохранения(unittest.TestCase):
    def test_отказ_хэша_до_очистки_сохраняет_реальное_состояние(self):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог).resolve() / 'профиль'; корень.mkdir(mode=0o700)
            бинарник = Path(каталог).resolve() / 'команда'; бинарник.write_bytes(b'fixture')
            счётчик = 0
            def запустить(аргументы, **параметры):
                nonlocal счётчик
                счётчик += 1
                if счётчик > 2:
                    return subprocess.CompletedProcess(аргументы, 2, '{}', аргументы[-1])
                (корень / 'журнал/сегмент.fumobs').write_bytes(b'ciphertext')
                результат = {'схема': 'fum.сквозной-хвост.1', 'фаза': аргументы[2], 'байтыСохранены': True,
                    'закрытие': {'потокиЗавершены': True, 'всеЗакрыты': False, 'требуетсяРазбор': True, 'неприменённыхКадров': 1},
                    'повторЗакрытияСовпадает': True, 'разрывов': 1, 'неприменённыхКадров': 1, 'чужойКлючОтклонён': True,
                    'разрывВхода': True, 'создано': 0, 'отправлено': 0, 'приёмов': 0, 'сообщений': 0,
                    'сегментНеИзменён': True, 'фикстураШа256': 'fixture', 'процесс': счётчик}
                return subprocess.CompletedProcess(аргументы, 0, json.dumps(результат), '')
            читать = Path.read_bytes
            def прочитать(путь):
                if путь == бинарник: raise PermissionError('Отказ чтения бинарника после процессов')
                return читать(путь)
            stderr = io.StringIO()
            with patch.object(команда.tempfile, 'mkdtemp', return_value=str(корень)), patch.object(команда.subprocess, 'run', side_effect=запустить):
                with patch.object(Path, 'read_bytes', прочитать), contextlib.redirect_stderr(stderr):
                    with self.assertRaises(PermissionError): команда.проверить(бинарник)
            self.assertEqual(счётчик, 4)
            self.assertIn(str(корень), stderr.getvalue())
            self.assertTrue((корень / 'журнал/сегмент.fumobs').is_file())
            self.assertTrue((корень / 'ключ').is_file())


    def test_отказ_сохранения_байтов_не_отключается_оптимизацией(self):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог).resolve() / 'профиль'; корень.mkdir(mode=0o700)
            бинарник = Path(каталог) / 'команда'; бинарник.write_bytes(b'fixture')
            def запустить(аргументы, **параметры):
                (корень / 'журнал/сегмент.fumobs').write_bytes(b'ciphertext')
                результат = {'схема': 'fum.сквозной-хвост.1', 'фаза': аргументы[2], 'байтыСохранены': False}
                return subprocess.CompletedProcess(аргументы, 0, json.dumps(результат), 'Исходная диагностика хвоста')
            stderr = io.StringIO()
            with patch.object(команда.tempfile, 'mkdtemp', return_value=str(корень)), patch.object(команда.subprocess, 'run', side_effect=запустить) as вызов:
                with contextlib.redirect_stderr(stderr):
                    with self.assertRaises(ValueError): команда.проверить(бинарник)
            self.assertEqual(вызов.call_count, 1)
            self.assertIn('Исходная диагностика хвоста', stderr.getvalue())
            self.assertIn('false', stderr.getvalue())
            self.assertTrue((корень / 'ключ').is_file())
            self.assertTrue((корень / 'журнал/сегмент.fumobs').is_file())


if __name__ == '__main__':
    unittest.main()
