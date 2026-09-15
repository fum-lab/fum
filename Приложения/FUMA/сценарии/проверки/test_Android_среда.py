import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest

спецификация = importlib.util.spec_from_file_location("среда", Path(__file__).resolve().parents[1] / "подготовить-Android-среду.py")
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)


class ПроверкиСреды(unittest.TestCase):
    def test_повреждённый_архив_отклоняется_до_распаковки(self):
        with tempfile.TemporaryDirectory() as каталог:
            путь = Path(каталог) / "архив"
            путь.write_bytes(b"broken")
            with self.assertRaises(ValueError):
                модуль.проверить_архив(путь, hashlib.sha256(b"original").hexdigest())

    def test_проверяется_полный_архив(self):
        with tempfile.TemporaryDirectory() as каталог:
            путь = Path(каталог) / "архив"
            данные = b"original" * 200000
            путь.write_bytes(данные)
            модуль.проверить_архив(путь, hashlib.sha256(данные).hexdigest())
