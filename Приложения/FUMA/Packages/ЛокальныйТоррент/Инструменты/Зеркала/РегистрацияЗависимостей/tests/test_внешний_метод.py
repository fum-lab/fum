"""Точный hook unittest в предметном зеркале инвентаризатора."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

путь = Path(__file__).resolve().parents[2] / "Кандидат/Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py"
описание = importlib.util.spec_from_file_location("проверяемое_зеркало_для_внешнего_метода", путь)
модуль = importlib.util.module_from_spec(описание)
sys.modules[описание.name] = модуль
описание.loader.exec_module(модуль)


class ВнешнийМетод(unittest.TestCase):
    def инвентарь(сам, текст):
        with tempfile.TemporaryDirectory() as имя:
            корень = Path(имя).resolve()
            (корень / "проба.py").write_text(текст)
            return модуль.построить_инвентарь(корень)["объявления"]

    def test_подготовка_точного_тестового_класса_является_внешней(сам):
        тексты = ["import unittest\nclass Проверка(unittest.TestCase):\n    def setUp(сам):\n        pass\n",
            "import unittest as проверки\nclass Проверка(проверки.TestCase):\n    def setUp(сам):\n        pass\n",
            "from unittest import TestCase as ПроверкаБазы\nclass Проверка(ПроверкаБазы):\n    def setUp(сам):\n        pass\n"]
        for текст in тексты:
            сам.assertEqual([], сам.инвентарь(текст), текст)

    def test_чужие_одноимённые_функции_не_получают_исключение(сам):
        тексты = ["def setUp():\n    pass\n", "class Чужой:\n    def setUp(сам):\n        pass\n",
            "import unittest\nunittest = object()\nclass Чужой(unittest.TestCase):\n    def setUp(сам):\n        pass\n",
            "import ast\nclass Чужой(ast.NodeVisitor):\n    def setUp(сам):\n        pass\n"]
        for текст in тексты:
            объявления = сам.инвентарь(текст)
            сам.assertTrue(any(з["имя"] == "setUp" for з in объявления), текст)

    def test_подмена_атрибута_модуля_не_даёт_внешний_метод(сам):
        тексты = [
            "import unittest\nclass Свой: pass\nunittest.TestCase = Свой\nclass Чужой(unittest.TestCase):\n    def setUp(сам): pass\n",
            "import unittest\nclass Свой: pass\nsetattr(unittest, 'TestCase', Свой)\nclass Чужой(unittest.TestCase):\n    def setUp(сам): pass\n",
            "import unittest as проверки\nclass Свой: pass\nsetattr(проверки, 'TestCase', Свой)\nclass Чужой(проверки.TestCase):\n    def setUp(сам): pass\n",
            "import unittest\nпсевдоним = unittest\nclass Свой: pass\nпсевдоним.TestCase = Свой\nclass Чужой(unittest.TestCase):\n    def setUp(сам): pass\n",
            "from unittest import TestCase as База\nclass Свой: pass\nБаза = Свой\nclass Чужой(База):\n    def setUp(сам): pass\n"]
        for текст in тексты:
            сам.assertTrue(any(з["имя"] == "setUp" for з in сам.инвентарь(текст)), текст)

    def test_имя_подготовки_допускается_только_как_синхронный_метод(сам):
        тексты = [
            "import unittest\nclass Проверка(unittest.TestCase):\n    class setUp: pass\n",
            "import unittest\nclass Проверка(unittest.TestCase):\n    setUp = 1\n",
            "import unittest\nclass Проверка(unittest.TestCase):\n    async def setUp(сам): pass\n"]
        for текст in тексты:
            сам.assertTrue(any(з["имя"] == "setUp" for з in сам.инвентарь(текст)), текст)

    def test_неизвестный_импорт_и_ранняя_подмена_не_дают_внешнюю_базу(сам):
        тексты = [
            "import unittest\nfrom чужой import *\nclass Проверка(unittest.TestCase):\n    def setUp(сам): pass\n",
            "from unittest import TestCase as База\nfrom чужой import *\nclass Проверка(База):\n    def setUp(сам): pass\n",
            "import unittest\nclass Свой: pass\nunittest.TestCase = Свой\nfrom unittest import TestCase as База\nclass Проверка(База):\n    def setUp(сам): pass\n",
            "import unittest as проверки\nclass Свой: pass\nsetattr(проверки, 'TestCase', Свой)\nfrom unittest import TestCase as База\nclass Проверка(База):\n    def setUp(сам): pass\n"]
        for текст in тексты:
            сам.assertTrue(any(з["имя"] == "setUp" for з in сам.инвентарь(текст)), текст)
