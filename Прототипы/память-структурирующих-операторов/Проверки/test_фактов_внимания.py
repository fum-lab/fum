"""Независимые проверки извлечения фактов; исполнитель не вызывается адаптером."""
import importlib.util
import hashlib
import os
from unittest.mock import patch
import sys
import tempfile
import unittest
from pathlib import Path


class ПроверкиФактов(unittest.TestCase):
    @classmethod
    def setUpClass(класс):
        путь = Path(__file__).resolve().parents[1] / "Сборщики" / "факты_внимания.py"
        описание = importlib.util.spec_from_file_location("факты_внимания", путь)
        класс.модуль = importlib.util.module_from_spec(описание)
        sys.modules[описание.name] = класс.модуль
        описание.loader.exec_module(класс.модуль)

    def test_ссылки_привязаны_к_сырым_байтам(сам):
        исходник = "# Ёж\n<!-- скрыто -->[FUMA](Приложения/FUMA/README.md)\n[Документы](Документация/README.md)\n".encode()
        ссылки = сам.модуль.извлечь_ссылки(исходник)
        сам.assertEqual([ссылка["цель"] for ссылка in ссылки], ["Приложения/FUMA/README.md", "Документация/README.md"])
        for ссылка in ссылки:
            байты = исходник[ссылка["начало"]:ссылка["конец"]]
            сам.assertEqual(hashlib.sha256(байты).hexdigest(), ссылка["хэшДиапазона"])
            сам.assertEqual(hashlib.sha256(исходник).hexdigest(), ссылка["хэшИсточника"])
            сам.assertIn(ссылка["цель"].encode(), байты)

    def test_невидимые_ссылки_не_становятся_фактами(сам):
        текст = "<!-- [а](a) -->\n```\n[б](b)\n```\n    [в](c)\n`[г](d)`\n![д](e)\n[ё](f)\n"
        сам.assertEqual([ссылка["цель"] for ссылка in сам.модуль.извлечь_ссылки(текст.encode())], ["f"])

    def test_адаптер_передаёт_факты_без_решения(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            (корень / "README.md").write_text("# Память\n[Документы](Документация/README.md)\n")
            (корень / "Приложения/FUMA").mkdir(parents=True)
            (корень / "Приложения/FUMA/README.md").write_text("# Приложение\n")
            вход = сам.модуль.собрать_readme(корень, "открытая-фикстура", "одна-задача", "2026-09-11T18:00:00Z")
            сам.assertEqual(вход["схема"], "fum.структурированный-вход.2")
            сам.assertNotIn("нужноОбновить", str(вход))
            сам.assertNotIn("устранено", str(вход))
            сам.assertEqual(вход["факты"]["readme"]["цели"], ["Документация/README.md"])
            сам.assertEqual(вход["факты"]["readme"]["доступность"], "доступен")
            (корень / "README.md").unlink()
            вход = сам.модуль.собрать_readme(корень, "открытая-фикстура", "одна-задача", "2026-09-11T18:00:00Z")
            сам.assertEqual(вход["факты"]["readme"]["доступность"], "недоступен")

    def test_ссылка_не_выходит_через_симлинк(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            (корень / "внешний").write_text("# Внешний\n")
            (корень / "README.md").symlink_to(корень / "внешний")
            вход = сам.модуль.собрать_readme(корень, "открытая-фикстура", "одна-задача", "2026-09-11T18:00:00Z")
            сам.assertEqual(вход["факты"]["readme"]["доступность"], "недоступен")

    def test_точный_регистр_и_тип_файла(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            (корень / "README.md").write_text("# Память\n")
            with сам.assertRaises((ValueError, OSError)):
                сам.модуль.прочитать_обычный(корень, "readme.md")
            (корень / "канал").mkdir()
            with сам.assertRaises(ValueError):
                сам.модуль.прочитать_обычный(корень, "канал")

    def test_явный_плохой_вход_не_заменяется_начальным(сам):
        with tempfile.TemporaryDirectory() as каталог:
            for значение in ({}, [], 0, False):
                with сам.assertRaises(ValueError):
                    сам.модуль.собрать_readme(каталог, "р", "з", "в", прежнее=значение)
            with сам.assertRaises(ValueError):
                сам.модуль.разобрать_json(b'{"a":1,"a":2}')

    def test_источники_содержат_байты_и_последнюю_сверку(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            (корень / "README.md").write_text("# Память\n[Д](Документация/README.md)\n")
            (корень / "Приложения/FUMA").mkdir(parents=True)
            (корень / "Приложения/FUMA/README.md").write_text("# Приложение\n")
            исход = сам.модуль.факт_файла
            вызовы = []
            def менять(корень, имя):
                if имя == "Приложения/FUMA/README.md":
                    вызовы.append(имя)
                    if len(вызовы) == 2:
                        (корень / имя).write_text("# Изменение\n")
                return исход(корень, имя)
            with patch.object(сам.модуль, "факт_файла", менять):
                вход = сам.модуль.собрать_readme(корень, "р", "з", "в")
            сам.assertEqual(вход["источники"]["README.md"]["текст"], (корень / "README.md").read_text())
            факт = вход["факты"]["зависимости"]["Приложения/FUMA/README.md"]
            сам.assertNotEqual(факт["хэш"], факт["текущийХэш"])
            сам.assertEqual(вход["источники"]["извлечение"]["хэш"], сам.модуль.хэш(сам.модуль.канонические_байты(вход["факты"]["readme"]["срез"])))

    def test_новая_проверка_читает_текущие_байты_и_связывает_причину(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            (корень / "README.md").write_text("# Память\n")
            (корень / "Приложения/FUMA").mkdir(parents=True)
            (корень / "Приложения/FUMA/README.md").write_text("# Приложение\n")
            прежнее = {"состояние":"активно", "причина":"Нет ссылки", "область":"открытая-область", "основания":{"readmeХэш":"старая-версия", "критерий":"прямая-ссылка"}}
            вход = сам.модуль.собрать_readme(корень, "р", "з", "в", прежнее)
            проверка = сам.модуль.проверить_ссылку(вход, "Приложения/FUMA/README.md")
            сам.assertEqual(проверка["исход"], "расхождение")
            (корень / "README.md").write_text("# Память\n[FUMA](Приложения/FUMA/README.md)\n")
            новый = сам.модуль.собрать_readme(корень, "р", "з", "в", прежнее)
            проверка = сам.модуль.проверить_ссылку(новый, "Приложения/FUMA/README.md")
            сам.assertEqual(проверка["исход"], "соответствует")
            сам.assertEqual(проверка["readmeХэш"], новый["факты"]["readme"]["хэш"])
            сам.assertEqual(проверка["прежнийХэш"], "старая-версия")
            новый["источники"]["README.md"]["текст"] += "подмена"
            with сам.assertRaises(ValueError):
                сам.модуль.проверить_ссылку(новый, "Приложения/FUMA/README.md")


if __name__ == "__main__":
    unittest.main()
