"""Холодный публичный вход: от нативного поручения до J и восстановления R."""
import hashlib
import json
from pathlib import Path
import time
import unittest
import test_коммита_приёма as сценарии


class ПроверкаВходаПриёма(unittest.TestCase):
    def test_нативный_вход_сохраняет_журнал_и_восстанавливает_коммит(сам):
        начало = time.perf_counter_ns()
        результат = сценарии.ПроверкаКоммитаПриёма().выполнить('публичный вход')
        сам.assertEqual(результат['созданий'], 1)
        сам.assertGreater(результат['вход_наносекунды'], 0)
        инструменты = Path(__file__).resolve().parents[2]
        код = {str(ф.relative_to(инструменты.parent)): hashlib.sha256(ф.read_bytes()).hexdigest()
            for имя in ('приём_получателя.py', 'вход_приёма.py', 'эпизод_приёма.py',
                'свежесть_приёма.py', 'область_журнала_приёма.py')
            for ф in [инструменты / 'fum-konvejyer-proizvodnyikh-vetok/scripts' / имя]}
        print('FUM-PROFILE ' + json.dumps({'схема': 'fum.профиль-входа-приёма.1',
            'весь_сценарий_наносекунды': time.perf_counter_ns() - начало,
            'код': код, 'результат': результат,
            'граница': 'Открытые JSONL и настоящий Git в холодном процессе из C; без Desktop и сети. '
                'Первый вход исполняет merge и J, повтор читает готовый J: времена разных операций.'}, ensure_ascii=False))


if __name__ == '__main__':
    unittest.main()
