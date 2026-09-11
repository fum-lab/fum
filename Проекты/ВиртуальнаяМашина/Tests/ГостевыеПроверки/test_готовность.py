"""Гостевые контракты проверяются без VM, сети и внешних пакетов."""
import copy
import importlib.util
from pathlib import Path
import unittest

путь = Path(__file__).resolve().parents[2] / 'Sources/ЯдроМашины/Ресурсы/готовность.py'
спецификация = importlib.util.spec_from_file_location('гостевая_готовность', путь)
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)


def завершённый():
    данные = {'status': 'done', 'extended_status': 'done', 'stage': None,
              'boot_status_code': 'enabled-by-generator', 'datasource': 'nocloud',
              'errors': [], 'recoverable_errors': {}}
    for имя in ('init-local', 'init', 'modules-config', 'modules-final'):
        данные[имя] = {'start': 1.0, 'finished': 2.0, 'errors': [], 'recoverable_errors': {}}
    return данные


class ПроверкиГотовности(unittest.TestCase):
    def test_завершённый_cloud_init_принимается(сам):
        сам.assertIsNone(модуль.проверить_инициализацию(0, завершённый()))

    def test_нулевой_код_не_маскирует_неполную_или_ошибочную_инициализацию(сам):
        случаи = [('status', 'running'), ('status', 'not started'), ('status', 'disabled'),
                  ('extended_status', 'degraded done'), ('stage', 'init'),
                  ('errors', ['ошибка']), ('recoverable_errors', {'WARNING': ['ошибка']}),
                  ('datasource', 'none')]
        for поле, значение in случаи:
            with сам.subTest(поле=поле, значение=значение):
                данные = завершённый(); данные[поле] = значение
                with сам.assertRaises(ValueError): модуль.проверить_инициализацию(0, данные)
        for код in (1, 2, 255):
            with сам.assertRaises(ValueError): модуль.проверить_инициализацию(код, завершённый())

    def test_этапы_обязательны_и_типы_времени_строгие(сам):
        for имя in ('init-local', 'init', 'modules-config', 'modules-final'):
            данные = завершённый(); del данные[имя]
            with сам.assertRaises(ValueError): модуль.проверить_инициализацию(0, данные)
            for значение in (True, -1, float('nan'), float('inf'), '2'):
                данные = завершённый(); данные[имя]['finished'] = значение
                with сам.assertRaises(ValueError): модуль.проверить_инициализацию(0, данные)

    def test_нулевой_или_неполный_набор_не_даёт_успех(сам):
        данные = {'выполнено': 8, 'ошибки': 0, 'отказы': 0, 'пропущено': 0,
                  'ожидаемые_ошибки': 0, 'неожиданные_успехи': 0}
        сам.assertIsNone(модуль.проверить_счётчики(данные, 8))
        for поле in данные:
            изменённые = copy.deepcopy(данные); изменённые[поле] = 0 if поле == 'выполнено' else 1
            with сам.assertRaises(ValueError): модуль.проверить_счётчики(изменённые, 8)
        with сам.assertRaises(ValueError): модуль.проверить_счётчики({}, 8)


class ПроверкиГостевогоКаталога(unittest.TestCase):
    def setUp(сам):
        import tempfile
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve() / 'гость'
        сам.владелец = {'схема': 'открытая-фикстура.1', 'машина': 'открытая-фикстура'}

    def test_повтор_сохраняет_принадлежность_и_замок(сам):
        with модуль.область_гостя(сам.корень, сам.владелец):
            with сам.assertRaises((ValueError, BlockingIOError)):
                with модуль.область_гостя(сам.корень, сам.владелец): pass
        with модуль.область_гостя(сам.корень, сам.владелец): pass
        with сам.assertRaises(ValueError):
            with модуль.область_гостя(сам.корень, {'другой': 'план'}): pass

    def test_неизвестный_каталог_и_ссылки_не_присваиваются(сам):
        сам.корень.mkdir()
        with сам.assertRaises(ValueError):
            with модуль.область_гостя(сам.корень, сам.владелец): pass
        сам.assertEqual(list(сам.корень.iterdir()), [])
        ссылка = сам.корень.parent / 'ссылка'; ссылка.symlink_to(сам.корень, target_is_directory=True)
        with сам.assertRaises(ValueError):
            with модуль.область_гостя(ссылка, сам.владелец): pass

    def test_подмена_маркера_ссылкой_или_большим_файлом_отклоняется(сам):
        with модуль.область_гостя(сам.корень, сам.владелец): pass
        маркер = сам.корень / 'владелец.json'; маркер.unlink()
        чужой = сам.корень.parent / 'чужой'; чужой.write_text('{}')
        маркер.symlink_to(чужой)
        with сам.assertRaises(ValueError):
            with модуль.область_гостя(сам.корень, сам.владелец): pass
        сам.assertEqual(чужой.read_text(), '{}')
        маркер.unlink(); маркер.write_bytes(b'x' * (1024 * 1024 + 1)); маркер.chmod(0o600)
        with сам.assertRaises(ValueError):
            with модуль.область_гостя(сам.корень, сам.владелец): pass

    def test_прерывание_создания_не_оставляет_неизвестную_конечную_цель(сам):
        from unittest.mock import patch
        with patch.object(модуль, 'записать_новый_файл', side_effect=OSError('Наблюдаемое прерывание')):
            with сам.assertRaises(ValueError):
                with модуль.область_гостя(сам.корень, сам.владелец): pass
        сам.assertFalse(сам.корень.exists())
        with модуль.область_гостя(сам.корень, сам.владелец): pass
        сам.assertTrue(сам.корень.is_dir())


if __name__ == '__main__':
    unittest.main()
