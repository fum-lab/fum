"""Пакетное чтение деревьев сохраняет смысл отношения и закрытый отказ."""
import tempfile
import unittest
from unittest.mock import patch

from test_обратная_доставка import Фикстура, гит
import доставка_план as план
from приём_направления import ОшибкаПриёма


class СравнениеДеревьев(unittest.TestCase):
    def setUp(self):
        папка = tempfile.TemporaryDirectory(prefix="fum-деревья-")
        self.addCleanup(папка.cleanup)
        self.ф = Фикстура(папка.name)

    def test_равные_деревья_читаются_одним_вызовом(self):
        дерево = гит(self.ф.источник, "rev-parse", self.ф.срез + "^{tree}")
        другой = гит(self.ф.источник, "commit-tree", дерево, "-p", self.ф.база, "-m", "Другая история")
        with patch.object(план, "гит", wraps=план.гит) as вызовы:
            self.assertEqual(план.отношение(self.ф.источник, self.ф.срез, другой), ("равное дерево", []))
        пары = [c for c in вызовы.call_args_list if c.args[1] == "rev-parse"]
        self.assertEqual(len(пары), 1)
        self.assertEqual(пары[0].args[2:], (self.ф.срез + "^{tree}", другой + "^{tree}"))

    def test_предок_не_читает_деревья(self):
        with patch.object(план, "гит", wraps=план.гит) as вызовы:
            self.assertEqual(план.отношение(self.ф.источник, self.ф.база, self.ф.срез), ("в предках", []))
        self.assertEqual(вызовы.call_count, 0)

    def test_различия_сохраняют_проверку_патчей(self):
        with patch.object(план, "гит", wraps=план.гит) as вызовы:
            результат = план.отношение(self.ф.источник, self.ф.срез, self.ф.вершина)
        self.assertEqual(результат[0], "недоставленные коммиты")
        self.assertEqual([c.args[1] for c in вызовы.call_args_list], ["rev-parse", "cherry", "rev-list"])

    def test_повреждённый_ответ_не_становится_равенством(self):
        for ответ in ["a" * 40, "\n".join(["a" * 40] * 3), "bad\nbad"]:
            with self.subTest(ответ=ответ), patch.object(план, "гит", return_value=ответ):
                with self.assertRaises(ОшибкаПриёма):
                    план.отношение(self.ф.источник, self.ф.срез, self.ф.вершина)

    def test_неполная_цель_отклоняется_до_проверки_предка(self):
        for цель in ["HEAD", self.ф.вершина[:12], "--help", None]:
            with self.subTest(цель=цель), patch.object(план, "предок", side_effect=AssertionError("поздний отказ")):
                with self.assertRaises(ОшибкаПриёма):
                    план.отношение(self.ф.источник, self.ф.срез, цель)

    def test_неизвестный_полный_объект_отклоняется(self):
        with self.assertRaises(ОшибкаПриёма):
            план.отношение(self.ф.источник, self.ф.срез, "0" * 40)


if __name__ == "__main__":
    unittest.main()
