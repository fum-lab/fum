import importlib.util
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


путь = pathlib.Path(__file__).parents[1] / 'собрать.py'
описание = importlib.util.spec_from_file_location('сборка', путь)
сборка = importlib.util.module_from_spec(описание)
описание.loader.exec_module(сборка)


class ПроверкиСборки(unittest.TestCase):
    def test_командный_план_не_создаёт_каталоги(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = pathlib.Path(каталог)
            аргументы = [sys.executable, '-B', str(путь), '--пакет', str(корень / 'пакет'), '--кэш', str(корень / 'кэш'), '--выход', str(корень / 'выход'), '--контейнер', str(корень / 'контейнер'), '--определение', str(корень / 'определение'), '--вход', str(корень / 'вход'), '--продукт', 'сценарий-runtime', '--архитектура', 'arm64', '--коммит', '0' * 40, '--версия-компилятора', 'фикстура']
            ответ = subprocess.run(аргументы, capture_output=True, text=True, timeout=10, check=True)
            сам.assertFalse(json.loads(ответ.stdout)['исполнено'])
            сам.assertEqual(list(корень.iterdir()), [])

    def test_план_различает_архитектуры(сам):
        for архитектура, тройка in [('arm64', 'aarch64-unknown-windows-msvc'), ('x64', 'x86_64-unknown-windows-msvc')]:
            план = сборка.план('пакет', 'сборка', 'выход', 'сценарий-runtime', архитектура, 'определение.json', 'вход.bin', 'контейнер')
            сам.assertIn(тройка, план[0])
            сам.assertEqual(план[-1][-4:], ['определение.json', 'вход.bin', 'контейнер', 'выход'])

    def test_чужая_архитектура_отклоняется(сам):
        with сам.assertRaises(ValueError):
            сборка.план('пакет', 'сборка', 'выход', 'продукт', 'arm32', 'определение', 'вход', 'контейнер')

    def test_профиль_не_выдаёт_мак_за_Windows(сам):
        with сам.assertRaisesRegex(ValueError, 'Windows'):
            сборка.проверить_среду('Darwin', 'arm64', 'aarch64-unknown-windows-msvc', 'arm64')

    def test_эмуляция_не_выдаётся_за_нативность(сам):
        with сам.assertRaisesRegex(ValueError, 'архитектур'):
            сборка.проверить_среду('Windows', 'ARM64', 'x86_64-unknown-windows-msvc', 'arm64')
        сборка.проверить_среду('Windows', 'ARM64', 'aarch64-unknown-windows-msvc', 'arm64')

    def test_ошибка_команды_останавливает_цепочку(сам):
        вызовы = []
        def исполнитель(команда):
            вызовы.append(команда)
            if len(вызовы) == 2:
                raise RuntimeError('сборка отказала')
        with сам.assertRaises(RuntimeError):
            сборка.исполнить([['test'], ['build'], ['run']], исполнитель)
        сам.assertEqual(вызовы, [['test'], ['build']])

    def test_точный_выход_и_искажение(сам):
        with tempfile.TemporaryDirectory() as каталог:
            файл = pathlib.Path(каталог) / 'результат.bin'
            файл.write_bytes(b'abc')
            сам.assertEqual(сборка.сверить(файл, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'), 3)
            файл.write_bytes(b'abd')
            with сам.assertRaisesRegex(ValueError, 'SHA'):
                сборка.сверить(файл, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')


if __name__ == '__main__':
    unittest.main()
