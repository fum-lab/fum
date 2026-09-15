import importlib.util
from pathlib import Path
import unittest

путь = Path(__file__).resolve().parents[1] / "проверить-Android-runtime.py"
спецификация = importlib.util.spec_from_file_location("сценарий", путь)
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)


class ПроверкиСценария(unittest.TestCase):
    def test_точные_байты_включая_нулевой_скаляр(self):
        self.assertEqual(модуль.ожидаемые_байты(bytes.fromhex("0041d191f09f8ebb")),
                         bytes.fromhex("000000004100000051040000bbf30100"))

    def test_отказ_некорректного_utf8(self):
        for вход in (b"\xc0\xaf", b"\xed\xa0\x80", b"\xf4\x90\x80\x80", b"\xe2\x82"):
            with self.assertRaises(UnicodeDecodeError):
                модуль.ожидаемые_байты(вход)

    def test_повтор_обязан_совпадать_побайтово(self):
        with self.assertRaises(ValueError):
            модуль.проверить_байты(b"a\x00\x00\x00", b"a\x00\x00\x00", b"b\x00\x00\x00")
