"""Ранний получатель, приватный native и реальное восстановление R из C."""
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

from фикстура_приёма_интеграции import фикстура, приём, хранение
import приватный_вход_приёма


class ПроверкаОбнаруженияПриёма(unittest.TestCase):
    def test_холодный_путь_восстанавливает_R_после_позднего_управления(сам):
        with фикстура() as ф:
            текст = приём.сформировать(ф['блок'])
            свидетельство = ф['отправить'](текст)
            корень = ф['корень']
            вход = корень.parent / 'сценарий-обнаружения.json'
            вход.write_bytes(хранение.байты({'задача': ф['задача'], 'источник': str(ф['источник']),
                'план': ф['план'], 'свидетельство': свидетельство, 'текст': текст,
                'владельцы': {str(корень): {'задача': ф['задача'], 'ref': ф['блок']['ref']}}}))
            процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).with_name('сценарий_обнаружения_приёма.py')),
                str(вход)], cwd=корень, env={**os.environ, 'CODEX_THREAD_ID': ф['задача']},
                capture_output=True, text=True, timeout=240)
            сам.assertEqual(0, процесс.returncode, процесс.stdout + процесс.stderr)
            итог = json.loads(процесс.stdout)
            сам.assertEqual(1, итог['созданий'])
            сам.assertTrue(итог['позднее_управление_закрыло_новые_действия'])
            print('FUM-PROFILE ' + json.dumps(итог, ensure_ascii=False))


if __name__ == '__main__':
    unittest.main()
