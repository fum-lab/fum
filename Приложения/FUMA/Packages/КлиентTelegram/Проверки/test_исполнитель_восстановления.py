import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

спецификация = importlib.util.spec_from_file_location('профиль_восстановления', Path(__file__).with_name('измерить-восстановление.py'))
команда = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(команда)


class ПроверкиИсполнителяВосстановления(unittest.TestCase):
    def проверить_отказ(self, вид):
        with tempfile.TemporaryDirectory() as каталог:
            корни = [Path(каталог).resolve() / str(номер) for номер in [1, 2]]
            for корень in корни: корень.mkdir(mode=0o700)
            бинарник = Path(каталог) / 'команда'; бинарник.write_bytes(b'fixture')
            вызовы = []
            def запустить(аргументы, **параметры):
                вызовы.append(аргументы)
                if len(вызовы) == 2 and вид == 'тайм-аут':
                    raise subprocess.TimeoutExpired(аргументы, 45, output=b'partial child output', stderr=b'child timeout diagnostic')
                количество = int(аргументы[-1]); фаза = аргументы[2]
                (Path(аргументы[4]) / 'журнал/сегмент.fumobs').write_bytes(b'ciphertext')
                результат = {'схема': 'fum.профиль-восстановления.1', 'фаза': фаза, 'попыток': количество,
                    'записей': 4 * количество, 'проверено': True, 'отправлено': 2 + 3 * количество if фаза == 'подготовить' else 0,
                    'создано': 1 if фаза == 'подготовить' else 0, 'приёмов': 0, 'процесс': len(вызовы),
                    'фикстурыШа256': 'a' * 64, 'сегментШа256': 'b' * 64, 'сегментБайтов': 128,
                    'требуютРазбора': количество, 'восстановлениеСекунд': .01, 'процессорноеВремяСекунд': .01,
                    'памятьДо': {'текущая': 1}, 'памятьПосле': {'текущая': 1}}
                if len(вызовы) == 2 and вид == 'инвариант': результат['проверено'] = False
                вывод = 'исходный повреждённый JSON' if len(вызовы) == 2 and вид == 'разбор' else json.dumps(результат)
                return subprocess.CompletedProcess(аргументы, 0, вывод, 'диагностика ребёнка')
            stderr = io.StringIO()
            каталоги = [str(корни[0]), OSError('Отказ второго каталога')] if вид == 'каталог' else list(map(str, корни))
            with patch.object(команда.tempfile, 'mkdtemp', side_effect=каталоги), patch.object(команда.subprocess, 'run', side_effect=запустить):
                with contextlib.redirect_stderr(stderr): код, итог = команда.измерить(бинарник)
            self.assertEqual(код, 2)
            self.assertEqual(len(вызовы), 2)
            self.assertEqual(len(итог['запуски']), 2 if вид == 'каталог' else 1)
            self.assertEqual(итог['исход'], 'неуспех')
            if вид != 'каталог':
                self.assertTrue((корни[0] / 'ключ').is_file())
                self.assertTrue((корни[0] / 'журнал/сегмент.fumobs').is_file())
                self.assertIn(str(корни[0]), stderr.getvalue())
                if вид == 'тайм-аут':
                    self.assertIn('child timeout diagnostic', stderr.getvalue())
                    self.assertIn('partial child output', stderr.getvalue())
                else:
                    self.assertIn('диагностика ребёнка', stderr.getvalue())
                    self.assertIn('исходный повреждённый JSON' if вид == 'разбор' else 'false', stderr.getvalue())
                self.assertNotIn(str(корни[0]), json.dumps(итог))
            else:
                self.assertFalse(корни[0].exists())

    def test_отказ_разбора_сохраняет_первый_результат_и_диагностику(self):
        self.проверить_отказ('разбор')

    def test_инварианты_обязательны_при_оптимизации_python(self):
        self.проверить_отказ('инвариант')

    def test_тайм_аут_сохраняет_частичный_вывод_и_журнал(self):
        self.проверить_отказ('тайм-аут')

    def test_отказ_следующего_каталога_не_теряет_первое_измерение(self):
        self.проверить_отказ('каталог')


if __name__ == '__main__':
    unittest.main()
