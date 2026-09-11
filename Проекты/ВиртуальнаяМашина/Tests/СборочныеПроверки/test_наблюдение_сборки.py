"""Настоящая связка фабрики упаковщика и принятого ресурса наблюдателя."""
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import statistics
import sys
import tempfile
import time
import unittest
from unittest import mock


проект = Path(__file__).resolve().parents[2]


class ПроверкиНаблюденияСборки(unittest.TestCase):
    def setUp(сам):
        временный = tempfile.TemporaryDirectory(); сам.addCleanup(временный.cleanup)
        сам.корень = Path(временный.name).resolve()
        сам.каталог = os.open(сам.корень, os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC)
        сам.замок = os.open(сам.корень / 'замок', os.O_CREAT | os.O_RDWR | os.O_CLOEXEC, 0o600)
        сам.addCleanup(os.close, сам.каталог); сам.addCleanup(os.close, сам.замок)
        fcntl.flock(сам.замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
        описание = importlib.util.spec_from_file_location('упаковщик_наблюдения', проект / 'собрать.py')
        сам.модуль = importlib.util.module_from_spec(описание); описание.loader.exec_module(сам.модуль)
        сам.выполнить = сам.модуль.создать_исполнителя(проект, сам.каталог, сам.замок)

    def квитанции(сам):
        return [json.loads(п.read_bytes()) for п in сам.корень.glob('наблюдатель-*-конец.json')]

    def замок_сохранён(сам):
        with (сам.корень / 'замок').open('rb') as иной:
            with сам.assertRaises(BlockingIOError): fcntl.flock(иной.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        os.fstat(сам.каталог); os.fstat(сам.замок)

    def test_настоящая_команда_с_манифестом_и_повтором(сам):
        интервалы = []; сохранённые = {}
        предкритерий = 500_000_000
        for _ in range(3):
            начало = time.monotonic_ns()
            ответ = сам.выполнить([sys.executable, '-I', '-S', '-B', '-c', 'import sys; sys.stdout.buffer.write(sys.argv[1].encode())', 'аргумент с ё'], предел=3)
            интервалы.append(time.monotonic_ns() - начало)
            сам.assertEqual(ответ, 'аргумент с ё'.encode())
            сам.замок_сохранён()
            for имя, байты in сохранённые.items(): сам.assertEqual((сам.корень / имя).read_bytes(), байты)
            сохранённые = {п.name: п.read_bytes() for п in сам.корень.iterdir() if п.name != 'замок'}
        сам.assertEqual(len(сам.квитанции()), 3)
        манифесты = [json.loads(п.read_bytes()) for п in сам.корень.glob('отправка-наблюдателя-*.json')]
        сам.assertEqual(len(манифесты), 3)
        for манифест in манифесты:
            описание = json.loads(манифест['описание'])
            сам.assertEqual(описание['каталог'], str(проект))
            сам.assertEqual(манифест['наблюдатель_sha256'], hashlib.sha256((проект / 'Sources/ЯдроМашины/Ресурсы/наблюдатель.py').read_bytes()).hexdigest())
            сам.assertEqual((сам.корень / манифест['файлы']['вход']).read_bytes(), b'')
        сам.assertEqual(len({json.loads(м['описание'])['исходник'] for м in манифесты}), 1)
        print('ПРОФИЛЬ_ФАБРИКИ_СБОРКИ ' + json.dumps({'схема': 'fum.профиль-фабрики-сборки.1', 'интервалы_нс': интервалы,
            'медиана_нс': statistics.median(интервалы), 'предкритерий_нс': предкритерий}, sort_keys=True))

    def test_отказ_и_срок_не_становятся_успешной_сборкой(сам):
        with сам.assertRaisesRegex(ValueError, '17.*открытый отказ'):
            сам.выполнить([sys.executable, '-c', 'import sys; sys.stderr.write("открытый отказ"); sys.exit(17)'], предел=3)
        пульс = сам.корень / 'пульс'
        команда = 'import pathlib,time,sys; p=pathlib.Path(sys.argv[1]);\nwhile True:\n p.write_text(str(time.monotonic_ns())); time.sleep(0.01)'
        with сам.assertRaisesRegex(ValueError, 'срок.*попытка'): сам.выполнить([sys.executable, '-c', команда, str(пульс)], предел=0.6)
        квитанции = сам.квитанции()
        сам.assertEqual({к['причина'] for к in квитанции}, {'завершение', 'срок'})
        сам.assertTrue(all(к['исход'] == 'ошибка' and к['группа_исчезла'] is True for к in квитанции))
        сам.assertTrue(пульс.is_file())
        байты = пульс.read_bytes(); time.sleep(0.1); сам.assertEqual(пульс.read_bytes(), байты)
        сам.замок_сохранён()


    def test_снимок_python_задаёт_фактическую_программу_наблюдателя(сам):
        питон = сам.модуль.описать_python()
        with mock.patch.object(сам.модуль.sys, 'executable', '/usr/bin/false'):
            ответ = сам.выполнить([питон['путь'], '-c', 'print("закреплённый runtime")'], предел=3)
        сам.assertEqual(ответ, 'закреплённый runtime\n'.encode())
        манифест = json.loads(next(сам.корень.glob('отправка-наблюдателя-*.json')).read_bytes())
        сам.assertEqual(манифест['аргументы'][0], питон['путь'])

    def test_отказ_самого_наблюдателя_имеет_ошибку_упаковщика(сам):
        иной = сам.корень / 'проект'; ресурсы = иной / 'Sources/ЯдроМашины/Ресурсы'; ресурсы.mkdir(parents=True)
        (ресурсы / 'наблюдатель.py').write_text('raise SystemExit(7)\n')
        (ресурсы / 'родитель_наблюдателя.py').write_bytes((проект / 'Sources/ЯдроМашины/Ресурсы/родитель_наблюдателя.py').read_bytes())
        выполнить = сам.модуль.создать_исполнителя(иной, сам.каталог, сам.замок)
        with сам.assertRaisesRegex(ValueError, 'Наблюдатель'):
            выполнить([sys.executable, '-c', 'raise SystemExit(0)'], предел=3)
        сам.замок_сохранён()

if __name__ == '__main__': unittest.main()
