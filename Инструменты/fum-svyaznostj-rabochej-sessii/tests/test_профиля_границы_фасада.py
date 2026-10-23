"""Профиль проверяет исполняемый код, а не детали его marshal-сериализации."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import types
import unittest
from unittest import mock

import профиль_границы_фасада as профиль


class КодПрофиляГраницы(unittest.TestCase):
    def модуль(сам):
        модуль = профиль.открытый.независимые.связность
        return модуль, Path(модуль.__file__)

    def test_штатная_загруженная_функция_совпадает_с_повторной_компиляцией(сам):
        модуль, файл = сам.модуль()
        профиль.сверить_загруженный_код(модуль, файл, {'проверить_область_записей'})

    def test_подменённый_код_отвергается_при_том_же_globals(сам):
        модуль, файл = сам.модуль()
        код = compile('def проверить_область_записей(*a, **k): return None', str(файл), 'exec')
        функция = types.FunctionType(next(x for x in код.co_consts
            if isinstance(x, types.CodeType)), vars(модуль))
        with mock.patch.object(модуль, 'проверить_область_записей', функция):
            with сам.assertRaisesRegex(ValueError, 'загруженная функция отличается'):
                профиль.сверить_загруженный_код(модуль, файл, {'проверить_область_записей'})

    def test_иной_путь_модуля_отвергается(сам):
        модуль, файл = сам.модуль()
        with mock.patch.object(модуль, '__file__', str(файл.with_name('чужой-модуль.py'))):
            with сам.assertRaisesRegex(ValueError, 'из другого checkout'):
                профиль.сверить_загруженный_код(модуль, файл, {'проверить_область_записей'})

    def test_чужие_GIT_и_запуск_без_B_не_пишут_checkout(сам):
        файл = Path(профиль.__file__).resolve()
        инструменты = файл.parents[2]
        def кэш():
            return {str(п): hashlib.sha256(п.read_bytes()).hexdigest()
                for п in инструменты.rglob('*.pyc')}
        до = кэш()
        with tempfile.TemporaryDirectory() as каталог:
            папка = Path(каталог); индекс = папка / 'чужой-индекс'
            индекс.write_bytes(b'do not modify\n')
            среда = dict(os.environ, GIT_DIR=str(папка / 'нет-репозитория'),
                GIT_INDEX_FILE=str(индекс), GIT_CONFIG_COUNT='1',
                GIT_CONFIG_KEY_0='core.worktree', GIT_CONFIG_VALUE_0=str(папка))
            ответ = subprocess.run([sys.executable, '-E', '-s', '-S', str(файл),
                '--базис', 'e3aeb894e1b9a703173b17451622368af159dae3',
                '--число-пар', '1'], capture_output=True, env=среда, timeout=120)
            сам.assertEqual(0, ответ.returncode, ответ.stderr.decode())
            результат = json.loads(ответ.stdout)
            сам.assertTrue(результат['зависимости_неизменны'])
            сам.assertEqual(1, len(результат['пары']))
            сам.assertEqual(b'do not modify\n', индекс.read_bytes())
        сам.assertEqual(до, кэш())
