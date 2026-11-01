"""Физический архив, граница локального кеша и подмена на FIFO при открытии."""
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from test_запуска_слоёв import строка, ЗАДАЧА
import архивный_префикс_приёма as архивы


@contextmanager
def фикстура():
    with tempfile.TemporaryDirectory(prefix='fum-архив-') as временное:
        каталог = Path(временное).resolve()
        начало = строка({'type': 'session_meta', 'payload': {'id': ЗАДАЧА}})
        префикс = начало + строка({'type': 'event_msg', 'payload': {'type': 'token_count'}})
        полный = каталог / 'полный.jsonl'
        архив = каталог / 'архив.jsonl'
        полный.write_bytes(префикс + строка({'type': 'event_msg', 'payload': {'type': 'token_count'}}))
        архив.write_bytes(префикс)
        полный.chmod(0o400); архив.chmod(0o400)
        описание = {'путь': str(архив), 'начало': len(начало),
            'начало_sha256': hashlib.sha256(начало).hexdigest(), 'граница': len(префикс),
            'sha256': hashlib.sha256(префикс).hexdigest()}
        источник = dict(описание, путь=str(полный), граница=полный.stat().st_size,
            sha256=hashlib.sha256(полный.read_bytes()).hexdigest())
        yield описание, источник


class ПроверкаАрхивногоПрефикса(unittest.TestCase):
    def test_а_кеш_одного_плана_не_переходит_в_следующий_и_сверяет_байты(сам):
        with фикстура() as (описание, источник), \
                patch.object(архивы.нативные, 'прочитать', wraps=архивы.нативные.прочитать) as разбор:
            кеш = архивы.АрхивыПриёма(источник)
            первый = кеш.прочитать(описание, ЗАДАЧА, [])
            первый['ожидания'].append('подмена возврата')
            сам.assertEqual([], кеш.прочитать(описание, ЗАДАЧА, [])['ожидания'])
            сам.assertEqual(1, разбор.call_count)
            кеш.сверить()
            архивы.АрхивыПриёма(источник).прочитать(описание, ЗАДАЧА, [])
            сам.assertEqual(2, разбор.call_count)
            путь = Path(описание['путь']); путь.chmod(0o600)
            путь.write_bytes(путь.read_bytes().replace(b'token_count', b'token_counx'))
            with сам.assertRaises(ValueError): кеш.прочитать(описание, ЗАДАЧА, [])
            with сам.assertRaises(ValueError): архивы.АрхивыПриёма(источник).прочитать(описание, ЗАДАЧА, [])

    def test_б_точный_регистр_конечного_имени(сам):
        with фикстура() as (описание, источник):
            неверный = Path(описание['путь']).with_name('Архив.jsonl')
            if not неверный.exists(): сам.skipTest('Файловая система различает регистр')
            with сам.assertRaises(ValueError):
                архивы.АрхивыПриёма(источник).прочитать(dict(описание, путь=str(неверный)), ЗАДАЧА, [])

    def test_в_именованный_канал_после_проверки_пути_не_блокирует_нативный_разбор(сам):
        with фикстура() as (описание, _):
            программа = '''import json,os,sys
from pathlib import Path
from unittest.mock import patch
sys.path[:0]=[sys.argv[1],sys.argv[2]]
import нативные_вызовы
описание=json.loads(sys.argv[3]); открыть=os.open; заменён=False
def подменить(путь,флаги,*параметры,**именованные):
    global заменён
    if str(путь)==описание['путь'] and not заменён:
        Path(путь).unlink();os.mkfifo(путь,0o600);заменён=True
    return открыть(путь,флаги,*параметры,**именованные)
with patch.object(os,'open',side_effect=подменить):
    try: нативные_вызовы.прочитать(описание,sys.argv[4],интервалы=True,читать_создания=False)
    except ValueError: sys.exit(0)
    raise RuntimeError('FIFO принят как обычный источник')
'''
            инструменты = Path(__file__).resolve().parents[2]
            try:
                итог = subprocess.run([sys.executable, '-I', '-B', '-c', программа,
                    str(инструменты / 'fum-konvejyer-proizvodnyikh-vetok/scripts'),
                    str(инструменты / 'fum-reyestr-planirovaniya/scripts'),
                    json.dumps(описание, ensure_ascii=False), ЗАДАЧА],
                    timeout=2, capture_output=True, check=False)
            except subprocess.TimeoutExpired:
                сам.fail('Нативный читатель завис на FIFO после подмены при открытии')
            сам.assertEqual(0, итог.returncode, итог.stderr.decode())


if __name__ == '__main__': unittest.main()
