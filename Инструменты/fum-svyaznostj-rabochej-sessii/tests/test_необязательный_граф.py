"""Локальный граф не нужен клону; исключение не распространяется на другие пути."""
import tempfile
import unittest
from pathlib import Path

from test_check_session_coherence import check_session_coherence as связность


class ПроверкаНеобязательногоГрафа(unittest.TestCase):
    def setUp(сам):
        сам.каталог = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.каталог.cleanup)
        сам.корень = Path(сам.каталог.name).resolve()
        сам.источник = сам.корень / "Журнал/2026-08-01_12-00-00_MSK/отчёт.md"
        сам.источник.parent.mkdir(parents=True)

    def проверить_ссылку(сам, цель):
        сам.источник.write_text(f"# Исторический отчёт\n\n[Граф]({цель})\n", encoding="utf-8")
        return связность.validate_markdown_links({сам.источник}, сам.корень)

    def test_отсутствие_точного_локального_графа_допустимо(сам):
        for каталог_существует in (False, True):
            with сам.subTest(каталог_существует=каталог_существует):
                if каталог_существует:
                    (сам.корень / ".obsidian").mkdir()
                сам.assertEqual(сам.проверить_ссылку("../../.obsidian/graph.json"), [])
                сам.assertFalse((сам.корень / ".obsidian/graph.json").exists())
                сам.assertEqual((сам.корень / ".obsidian").exists(), каталог_существует)

    def test_существующий_пользовательский_граф_сохраняется(сам):
        граф = сам.корень / ".obsidian/graph.json"
        граф.parent.mkdir()
        исходные = b'{"search": "user selection", "scale": 1.234}\n'
        граф.write_bytes(исходные)
        состояние = граф.stat()
        сам.assertEqual(сам.проверить_ссылку("../../.obsidian/graph.json"), [])
        сам.assertEqual(граф.read_bytes(), исходные)
        сам.assertEqual((граф.stat().st_ino, граф.stat().st_mtime_ns),
                       (состояние.st_ino, состояние.st_mtime_ns))

    def test_неверный_регистр_существующего_предка_не_скрывается(сам):
        (сам.корень / ".Obsidian").mkdir()
        сам.assertTrue(сам.проверить_ссылку("../../.obsidian/graph.json"))
        сам.assertFalse((сам.корень / ".Obsidian/graph.json").exists())

    def test_похожие_имена_выходы_и_символические_ссылки_не_исключаются(сам):
        (сам.корень / ".obsidian").mkdir()
        (сам.корень / "псевдоним").symlink_to(".obsidian", target_is_directory=True)
        цели = (
            "../../.obsidian/Graph.json", "../../.Obsidian/graph.json",
            "../../.obsidian/graph.json.bak", "../../.obsidian/other.json",
            "../../другое/.obsidian/graph.json", "../../../.obsidian/graph.json",
            "../../псевдоним/graph.json", "../../нет-каталога/../.obsidian/graph.json",
            str(сам.корень / ".obsidian/graph.json"),
        )
        for цель in цели:
            with сам.subTest(цель=цель):
                сам.assertTrue(сам.проверить_ссылку(цель))
        граф = сам.корень / ".obsidian/graph.json"
        граф.symlink_to("утраченный.json")
        сам.assertTrue(сам.проверить_ссылку("../../.obsidian/graph.json"))
        сам.assertTrue(граф.is_symlink())


if __name__ == "__main__":
    unittest.main()
