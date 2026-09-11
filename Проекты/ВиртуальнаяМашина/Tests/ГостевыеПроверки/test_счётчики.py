"""Фактический unittest result, включая пропуски и ошибку обнаружения."""
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest

путь = Path(__file__).resolve().parents[2] / 'Sources/ЯдроМашины/Ресурсы/проверить-набор.py'
спецификация = importlib.util.spec_from_file_location('счётчики_гостевого_набора', путь)
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)


class ПроверкиСчётчиков(unittest.TestCase):
    def испытать(сам, тело, ожидается):
        with tempfile.TemporaryDirectory() as имя:
            корень = Path(имя)
            (корень / 'test_открытая_фикстура.py').write_text('import unittest\nclass Случай(unittest.TestCase):\n' + тело)
            return модуль.проверить(корень, ожидается)

    def test_успех_требует_полного_числа_тестов(сам):
        результат = сам.испытать('    def test_проверка(сам): сам.assertEqual(2+2, 4)\n', 1)
        сам.assertEqual(результат['выполнено'], 1)
        with сам.assertRaises(ValueError): сам.испытать('    pass\n', 1)

    def test_пропуск_не_маскируется_успехом_набора(сам):
        with сам.assertRaises(ValueError):
            сам.испытать('    @unittest.skip("Открытая фикстура")\n    def test_проверка(сам): pass\n', 1)

    def test_ошибка_обнаружения_отклоняется(сам):
        with сам.assertRaises(ValueError): сам.испытать('    неверный синтаксис!\n', 1)


if __name__ == '__main__': unittest.main()
