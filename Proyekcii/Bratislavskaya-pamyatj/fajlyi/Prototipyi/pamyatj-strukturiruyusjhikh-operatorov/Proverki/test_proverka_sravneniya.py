import copy
import json
from pathlib import Path
import runpy
import shutil
import tempfile
import unittest

модуль = runpy.run_path(str(Path(__file__).with_name("проверить-сравнение.py")))


class ПроверкиСвидетельстваСравнения(unittest.TestCase):
    @classmethod
    def setUpClass(класс):
        исходный = Path(__file__).resolve().parents[1]
        путь = исходный.parents[1] / "Журнал/2026-09-11_12-00-09_MSK_сравнить-декодирование-UTF-8/материалы/сравнение-Release.json"
        класс.данные = json.loads(путь.read_text())
        класс.каталог = tempfile.TemporaryDirectory()
        класс.addClassCleanup(класс.каталог.cleanup)
        класс.прототип = Path(класс.каталог.name)
        for имя in ("Sources", "Tests"):
            shutil.copytree(исходный / имя, класс.прототип / имя)
        for имя in ("Package.swift", "Проверки/сравнить-декодирование.py"):
            цель = класс.прототип / имя
            цель.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(исходный / имя, цель)
        shutil.copyfile(
            исходный / "Проверки/эталоны-профиля/тест-сравнения-до-переименования.swift.txt",
            класс.прототип / "Tests/FUMStructuringOperatorMemoryTests/ПроверкиСравненияДекодирования.swift")

    def test_исходныйПрофиль(сам):
        модуль["проверить"](сам.данные, сам.прототип)

    def test_подменаМедианыОтклоняется(сам):
        данные = copy.deepcopy(сам.данные)
        данные["итоги"][0]["Swift"]["медианаНс"] *= 2
        with сам.assertRaises(ValueError):
            модуль["проверить"](данные, сам.прототип)

    def test_потеряПарыОтклоняется(сам):
        данные = copy.deepcopy(сам.данные)
        данные["наблюдения"].pop()
        with сам.assertRaises(ValueError):
            модуль["проверить"](данные, сам.прототип)

    def test_подменаПроисхожденияОтклоняется(сам):
        данные = copy.deepcopy(сам.данные)
        данные["происхождение"]["исходники"]["Package.swift"] = "0" * 64
        with сам.assertRaises(ValueError):
            модуль["проверить"](данные, сам.прототип)

    def test_пустоеИНеполноеПроисхождениеОтклоняется(сам):
        for пустое in (True, False):
            данные = copy.deepcopy(сам.данные)
            if пустое:
                данные["происхождение"]["исходники"] = {}
            else:
                данные["происхождение"]["исходники"].pop("Package.swift")
            with сам.assertRaises(ValueError):
                модуль["проверить"](данные, сам.прототип)

    def test_дубликатыИтоговОтклоняются(сам):
        данные = copy.deepcopy(сам.данные)
        данные["итоги"] = [copy.deepcopy(данные["итоги"][0]) for _ in range(24)]
        with сам.assertRaises(ValueError):
            модуль["проверить"](данные, сам.прототип)

    def test_потеряФайлаВместеСЗаписьюОтклоняется(сам):
        данные = copy.deepcopy(сам.данные)
        имя = "Tests/FUMStructuringOperatorMemoryTests/ПроверкиСравненияДекодирования.swift"
        данные["происхождение"]["исходники"].pop(имя)
        with tempfile.TemporaryDirectory() as каталог:
            снимок = Path(каталог) / "снимок"
            shutil.copytree(сам.прототип, снимок)
            (снимок / имя).unlink()
            with сам.assertRaises(ValueError):
                модуль["проверить"](данные, снимок)


if __name__ == "__main__":
    unittest.main()
