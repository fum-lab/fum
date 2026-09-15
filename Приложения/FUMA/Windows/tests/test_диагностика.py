import base64
import importlib.util
import pathlib
import subprocess
import unittest


описание = importlib.util.spec_from_file_location('диагностика', pathlib.Path(__file__).parents[1] / 'диагностика.py')
диагностика = importlib.util.module_from_spec(описание)
описание.loader.exec_module(диагностика)


class ПроверкиДиагностики(unittest.TestCase):
    def test_кавычки_и_кириллица_сохраняются(сам):
        запрос = "Test-Path 'каталог с пробелом (x86)'"
        команда = диагностика.команда('Моя VM', запрос)
        сам.assertEqual(команда[2], 'Моя VM')
        сам.assertEqual(base64.b64decode(команда[-1]).decode('utf-16le'), запрос)

    def test_отказ_и_пустое_наблюдение_не_означают_готовность(сам):
        def исполнитель(команда, **параметры):
            return subprocess.CompletedProcess(команда, 1, b'', b'private error')
        итог = диагностика.собрать('VM', исполнитель)
        сам.assertFalse(итог['сборка_подтверждена'])
        сам.assertFalse(итог['права_лицензии_подтверждены'])
        сам.assertTrue(all(строка['код'] == 1 and строка['значение'] is None for строка in итог['наблюдения'].values()))
        сам.assertNotIn('private error', str(итог))

    def test_тайм_аут_сохраняет_неизвестность(сам):
        def исполнитель(команда, **параметры):
            raise subprocess.TimeoutExpired(команда, 30)
        итог = диагностика.собрать('VM', исполнитель)
        сам.assertTrue(all(строка['ошибка'] == 'TimeoutExpired' for строка in итог['наблюдения'].values()))


if __name__ == '__main__':
    unittest.main()
