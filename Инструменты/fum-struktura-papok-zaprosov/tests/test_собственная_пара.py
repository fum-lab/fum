"""Собственная пара готовится без чтения и изменения общей навигации."""
import unittest
from unittest import mock

from test_план_начала import модуль, репозиторий, снимок, аргументы, основа


class ПроверкаСобственнойПары(unittest.TestCase):
    def test_только_два_файла_без_общего_сканирования_и_записи(self):
        with репозиторий() as фикс:
            до = снимок(фикс.root)
            with mock.patch.object(модуль, "_canonical_requests", side_effect=AssertionError("Общий проход не нужен")):
                файлы, сведения = модуль.подготовить_собственную_пару(фикс.root, *аргументы)
            self.assertEqual(до, снимок(фикс.root))
            self.assertEqual({x.path.as_posix() for x in файлы}, {
                f"Журнал/{основа}/запрос.md", f"Журнал/{основа}/отчёт.md"})
            запрос = next(x.data.decode() for x in файлы if x.path.name == "запрос.md")
            self.assertIn("Предыдущий запрос: отложен до передачи координатору", запрос)
            self.assertIn("Следующий запрос: отложен до передачи координатору", запрос)
            self.assertIn("Второе с {{полем}}.", запрос)
            self.assertTrue(сведения["deferred_navigation"])

    def test_точный_повтор_пуст_а_иной_текст_конфликтует(self):
        with репозиторий() as фикс:
            файлы, _ = модуль.подготовить_собственную_пару(фикс.root, *аргументы)
            for файл in файлы:
                фикс.write(файл.path.as_posix(), файл.data, файл.mode)
            до = снимок(фикс.root)
            повтор, сведения = модуль.подготовить_собственную_пару(фикс.root, *аргументы)
            self.assertEqual([], повтор)
            self.assertTrue(сведения["idempotent"])
            with self.assertRaises(модуль.LayoutError):
                модуль.подготовить_собственную_пару(фикс.root, *аргументы[:-1], ["Иная команда"])
            self.assertEqual(до, снимок(фикс.root))

    def test_общие_требования_каркаса_сохраняются(self):
        with репозиторий() as фикс:
            до = снимок(фикс.root)
            for сообщения in ([], [""], [None]):
                with self.subTest(сообщения=сообщения), self.assertRaises(модуль.LayoutError):
                    модуль.подготовить_собственную_пару(фикс.root, *аргументы[:-1], сообщения)
            self.assertEqual(до, снимок(фикс.root))


if __name__ == "__main__":
    unittest.main()
