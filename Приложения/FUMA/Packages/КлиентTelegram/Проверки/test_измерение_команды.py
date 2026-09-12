import contextlib
import io
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

спецификация = importlib.util.spec_from_file_location('команда_профиля', Path(__file__).with_name('проверить-команду.py'))
команда = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(команда)


class ПроверкиИзмерения(unittest.TestCase):
    def test_два_отдельных_ограниченных_процесса(self):
        with tempfile.TemporaryDirectory() as каталог:
            файл = Path(каталог) / 'команда'; файл.write_bytes(b'fixture')
            поток = {'схема': 'fum.профиль-клиента.1', 'сценарий': 'поток', 'измеряемыхКадров': 1000,
                     'получено': 1032, 'применено': 1032, 'неприменено': 0, 'байтыСохранены': True}
            отмена = {'схема': 'fum.профиль-клиента.1', 'сценарий': 'отмена', 'измеряемыхОтмен': 30,
                     'хвостовПроверено': 35, 'байтыСохранены': True}
            ответы = [subprocess.CompletedProcess([], 0, json.dumps(значение), '') for значение in [поток, отмена]]
            with patch.object(команда.subprocess, 'run', side_effect=ответы) as запуски:
                результат = команда.измерить(файл)
            self.assertEqual(len(результат['запуски']), 2)
            self.assertEqual(результат['запуски'][0]['результат'], поток)
            self.assertEqual(результат['запуски'][1]['результат'], отмена)
            self.assertEqual(len(результат['исполняемыйШа256']), 64)
            self.assertTrue(all(вызов.kwargs['timeout'] == 45 and вызов.kwargs['check'] for вызов in запуски.call_args_list))

    def проверить_отказ(self, ответы, сценарий, причина, завершено):
        with tempfile.TemporaryDirectory() as каталог:
            файл = Path(каталог) / 'команда'; файл.write_bytes(b'fixture')
            вывод, диагностика = io.StringIO(), io.StringIO()
            with patch.object(команда.subprocess, 'run', side_effect=ответы) as запуски:
                with contextlib.redirect_stdout(вывод), contextlib.redirect_stderr(диагностика):
                    код = команда.измерить_и_вывести(файл)
            отчёт = json.loads(вывод.getvalue())
            self.assertEqual(код, 2)
            self.assertEqual(отчёт['исход'], 'неуспех')
            self.assertEqual(отчёт['ошибка']['сценарий'], сценарий)
            self.assertEqual(отчёт['ошибка']['причина'], причина)
            self.assertGreaterEqual(отчёт['ошибка']['процессНаносекунд'], 0)
            self.assertEqual(len(отчёт['запуски']), завершено)
            self.assertEqual(запуски.call_count, завершено + 1)
            self.assertIn('частичный ответ', диагностика.getvalue())
            self.assertIn('/приватный/хвост', диагностика.getvalue())
            self.assertNotIn('/приватный/хвост', вывод.getvalue())
            return отчёт

    def test_ошибка_первого_процесса_не_скрывается_вторым(self):
        отказ = subprocess.CalledProcessError(2, ['профиль'], output='частичный ответ', stderr='/приватный/хвост')
        отчёт = self.проверить_отказ([отказ], 'поток', 'код_процесса', 0)
        self.assertEqual(отчёт['ошибка']['код'], 2)

    def test_отказ_второго_сохраняет_первый_результат_и_диагностику(self):
        поток = {'схема': 'fum.профиль-клиента.1', 'сценарий': 'поток', 'измеряемыхКадров': 1000,
                 'получено': 1032, 'применено': 1032, 'неприменено': 0, 'байтыСохранены': True}
        успех = subprocess.CompletedProcess([], 0, json.dumps(поток), '')
        отказ = subprocess.CalledProcessError(2, ['профиль'], output='частичный ответ', stderr='/приватный/хвост')
        отчёт = self.проверить_отказ([успех, отказ], 'отмена', 'код_процесса', 1)
        self.assertEqual(отчёт['запуски'][0]['результат'], поток)

    def test_тайм_аут_сохраняет_байтовую_диагностику(self):
        отказ = subprocess.TimeoutExpired(['профиль'], 45, output='частичный ответ'.encode(), stderr='/приватный/хвост'.encode())
        отчёт = self.проверить_отказ([отказ], 'поток', 'тайм_аут', 0)
        self.assertEqual(отчёт['ошибка']['пределСекунд'], 45)


if __name__ == '__main__':
    unittest.main()
