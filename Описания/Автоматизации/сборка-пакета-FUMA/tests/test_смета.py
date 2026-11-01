import importlib.util
from pathlib import Path
import unittest

путь = Path(__file__).resolve().parents[1] / "смета.py"
спецификация = importlib.util.spec_from_file_location("смета", путь)
смета = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(смета)


class ПроверкиСметы(unittest.TestCase):
    def test_неизвестная_активная_цена_не_становится_нулём(self):
        self.assertIsNone(смета.сумма_закупки([
            {"количество": 1, "цена": 100}, {"количество": 1, "цена": None}
        ]))

    def test_отключённая_альтернатива_не_блокирует_смету(self):
        self.assertEqual(смета.сумма_закупки([
            {"количество": 1, "цена": 100}, {"количество": 0, "цена": None}
        ]), 100)

    def test_ставка_ноль_и_полное_погашение(self):
        self.assertEqual(смета.аннуитет(1200, 0, 12), 100)
        платёж = смета.аннуитет(1200, 12, 12)
        остаток = 1200
        for _ in range(12):
            остаток = остаток * 1.01 - платёж
        self.assertAlmostEqual(остаток, 0, places=7)

    def test_неизвестный_курс_сохраняет_неизвестность(self):
        self.assertIsNone(смета.рубли(200, None))
        self.assertEqual(смета.рубли(200, 100), 20000)

    def test_недопустимые_числа_отклоняются(self):
        for значение in [-1, float("nan"), float("inf"), True]:
            with self.subTest(значение=значение), self.assertRaises(ValueError):
                смета.сумма_закупки([{"количество": 1, "цена": значение}])
        with self.assertRaises(ValueError):
            смета.аннуитет(100, 10, 0)

    def test_подтверждённый_ноль_отличается_от_пустого(self):
        self.assertEqual(смета.сумма_закупки([{"количество": 1, "цена": 0}]), 0)
        self.assertIsNone(смета.аннуитет(None, 12, 12))


if __name__ == "__main__":
    unittest.main()
