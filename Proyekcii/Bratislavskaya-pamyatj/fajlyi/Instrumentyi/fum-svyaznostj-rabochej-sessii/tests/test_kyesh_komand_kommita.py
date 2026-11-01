"""Проверяемый курсор экономит разбор, не скрывая первичные команды."""
import contextlib
import io
import json
from pathlib import Path
import sys
import unittest
from unittest import mock

import test_создание_коммита as база


class КэшКомандКоммита(unittest.TestCase):
    def setUp(self):
        self.ф = база.СозданиеКоммита()
        self.ф.setUp()
        self.addCleanup(self.ф.doCleanups)
        self.кэш = self.ф.каталог / "индекс-команд.json"
        база.прочитать_сообщения(self.ф.источник, база.ЗАДАЧА,
            корень_репозитория=self.ф.корень, кэш=self.кэш)

    def включить(self):
        self.ф.параметры["источники"][0]["кэш"] = str(self.кэш)

    def test_новая_сессия_готовится_до_первой_проверки(self):
        self.включить()
        база.коммит.подготовить(self.ф.параметры)
        self.assertTrue(Path(self.ф.параметры["сообщение"]).is_file())
        self.assertFalse((self.ф.запрос.parent / "материалы/запуски-проверок").exists())

    def test_повреждённая_история_не_считается_отсутствующей(self):
        каталог = self.ф.запрос.parent / "материалы/запуски-проверок"
        for вид in ("файл", "оборванная ссылка"):
            with self.subTest(вид=вид):
                if вид == "файл":
                    каталог.write_text("не каталог")
                else:
                    каталог.symlink_to(self.ф.каталог / "отсутствует")
                try:
                    with mock.patch.object(база.коммит, "команды", side_effect=AssertionError("Достигнут JSONL")):
                        self.ф.отказ_без_коммита(lambda: база.коммит.подготовить(self.ф.параметры))
                finally:
                    каталог.unlink()

    def test_кэш_сохраняет_команды_и_не_перезаписывается(self):
        ожидаемое = база.коммит.команды(self.ф.параметры)
        self.включить()
        до = self.кэш.read_bytes()
        with mock.patch.object(база.коммит.сообщения, "прочитать_сообщения", wraps=база.прочитать_сообщения) as читать:
            self.assertEqual(база.коммит.команды(self.ф.параметры), ожидаемое)
        self.assertEqual(читать.call_args.kwargs["кэш"], str(self.кэш))
        self.assertTrue(читать.call_args.kwargs["без_записи"])
        self.assertEqual(self.кэш.read_bytes(), до)

    def test_позднее_сообщение_видно_со_старым_кэшем(self):
        self.включить()
        новое = json.loads(json.dumps(self.ф.события[-1]))
        новое["payload"]["content"][0]["text"] = "Уточнение после курсора.\n"
        with self.ф.источник.open("a") as f:
            f.write(json.dumps(новое, ensure_ascii=False) + "\n")
        свежий = база.прочитать_сообщения(self.ф.источник, база.ЗАДАЧА,
            корень_репозитория=self.ф.корень, без_записи=True)
        self.ф.параметры["источники"][0]["экземпляры"] = [m["экземпляр"] for m in свежий["сообщения"]]
        self.ф.запрос.write_text(self.ф.запрос.read_text().replace("## Идентификатор сеанса Codex",
            "````text\nУточнение после курсора.\n\n````\n\n## Идентификатор сеанса Codex"))
        до = self.кэш.read_bytes()
        результат = база.коммит.команды(self.ф.параметры)
        self.assertEqual([r["текст"] for r in результат], [база.КОМАНДА, "Уточнение после курсора.\n"])
        self.assertEqual(self.кэш.read_bytes(), до)

    def test_подмена_старого_префикса_отклоняется(self):
        self.включить()
        self.ф.события[-1]["payload"]["content"][0]["text"] = "Подменённая команда.\n"
        self.ф.записать_источник()
        with mock.patch.object(база.коммит.сообщения, "прочитать_сообщения", wraps=база.прочитать_сообщения) as читать:
            self.ф.отказ_без_коммита(lambda: база.коммит.подготовить(self.ф.параметры))
        читать.assert_called_once()
        self.assertFalse(Path(self.ф.параметры["сообщение"]).exists())

    def test_повреждённый_кэш_не_игнорируется(self):
        self.включить()
        self.кэш.write_text("{}\n")
        with mock.patch.object(база.коммит.сообщения, "прочитать_сообщения", wraps=база.прочитать_сообщения) as читать:
            self.ф.отказ_без_коммита(lambda: база.коммит.подготовить(self.ф.параметры))
        читать.assert_called_once()

    def test_v3_обнаруживается_до_чтения_источника(self):
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(0, self.ф.отчёты.выполнить_запуск(self.ф.корень, self.ф.запрос,
                "Историческая проверка", "фикстура", база.ЗАПУСК, 15,
                [sys.executable, "-c", "pass"], класс_проверки="адресная"))
        with mock.patch.object(база.коммит, "команды", side_effect=AssertionError("Достигнут дорогой JSONL")):
            with self.assertRaisesRegex(база.коммит.ОшибкаКоммита, "v4"):
                база.коммит.подготовить(self.ф.параметры)
        self.assertFalse(Path(self.ф.параметры["сообщение"]).exists())


if __name__ == "__main__":
    unittest.main()
