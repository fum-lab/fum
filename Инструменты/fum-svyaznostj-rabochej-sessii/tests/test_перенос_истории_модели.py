"""Перенос подтверждённого курсора в историю следующего этапа."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import история_модели as модель
from перенести_историю_модели import перенести


class ПереносИсторииМодели(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.основа = Path(self.временный.name).resolve()
        self.корень = self.основа / "репозиторий"
        self.корень.mkdir()
        self.источник = self.основа / "native.jsonl"
        self.задача = "00000000-0000-0000-0000-000000000001"
        self.старый_кэш = self.основа / "старый-кэш.json"
        self.старый_отчёт = self.корень / "старый.json"
        self.новый_кэш = self.основа / "новый-кэш.json"
        self.новый_отчёт = self.корень / "новый.json"
        self.добавить({"type": "session_meta", "payload": {"id": self.задача}})
        self.наблюдать("gpt-6-astra", "ultra")
        модель.импортировать(self.источник, self.задача, корень_репозитория=self.корень,
            кэш=self.старый_кэш, история=self.старый_отчёт)

    def добавить(self, запись):
        with self.источник.open("ab") as поток:
            поток.write((json.dumps(запись) + "\n").encode())

    def наблюдать(self, имя, усилие):
        self.добавить({"type": "turn_context", "timestamp": "2026-10-02T02:00:00Z",
            "payload": {"model": имя, "effort": усилие}})

    def перенос(self, **параметры):
        return перенести(self.источник, self.задача,
            корень_репозитория=self.корень, прежний_кэш=self.старый_кэш,
            прежняя_история=self.старый_отчёт, кэш=self.новый_кэш,
            история=self.новый_отчёт, **параметры)

    def test_переиспользует_старую_историю_разбирает_только_хвост(self):
        старые_байты = self.старый_отчёт.read_bytes()
        self.наблюдать("gpt-6-sol", "ultra")
        результат = self.перенос()
        новая = json.loads(self.новый_отчёт.read_bytes())
        self.assertEqual(результат["новых_наблюдений"], 1)
        self.assertEqual(результат["профиль"]["разобрано_строк"], 1)
        self.assertEqual(новая["число_наблюдений"], 2)
        self.assertEqual(новая["последнее"]["модель"], "gpt-6-sol")
        self.assertEqual(self.старый_отчёт.read_bytes(), старые_байты)
        self.assertEqual(модель.импортировать(self.источник, self.задача,
            корень_репозитория=self.корень, кэш=self.новый_кэш,
            история=self.новый_отчёт, без_записи=True)["новых_наблюдений"], 0)
        полный_отчёт = self.корень / "полный.json"
        полный_кэш = self.основа / "полный-кэш.json"
        модель.импортировать(self.источник, self.задача,
            корень_репозитория=self.корень, кэш=полный_кэш, история=полный_отчёт)
        self.assertEqual(self.новый_отчёт.read_bytes(), полный_отчёт.read_bytes())

    def test_неизменный_префикс_обязателен_и_сухой_режим_не_пишет(self):
        результат = self.перенос(без_записи=True)
        self.assertTrue(результат["полнота"])
        self.assertFalse(self.новый_кэш.exists())
        self.assertFalse(self.новый_отчёт.exists())
        self.источник.write_bytes(self.источник.read_bytes().replace(b"gpt-6-astra", b"gpt-6-luna "))
        with self.assertRaisesRegex(ValueError, "префикс изменён"):
            self.перенос()
        self.assertFalse(self.новый_кэш.exists())
        self.assertFalse(self.новый_отчёт.exists())

    def test_повреждённая_или_неполная_предыдущая_история_отклоняется(self):
        self.старый_отчёт.write_bytes(b"{}\n")
        with self.assertRaisesRegex(ValueError, "история не совпадает"):
            self.перенос()
        self.assertFalse(self.новый_кэш.exists())

    def test_курсор_не_может_совпадать_с_замком_другого_курсора(self):
        with self.assertRaisesRegex(ValueError, "совпадающие пути данных и замков"):
            перенести(self.источник, self.задача,
                корень_репозитория=self.корень,
                прежний_кэш=self.старый_кэш,
                прежняя_история=self.старый_отчёт,
                кэш=Path(str(self.старый_кэш) + ".lock"),
                история=self.новый_отчёт)
        self.assertFalse(Path(str(self.старый_кэш) + ".lock.lock").exists())

    def test_последняя_пара_сверяется_с_исходной_строкой(self):
        оболочка = json.loads(self.старый_кэш.read_bytes())
        оболочка["данные"]["история"]["последнее"]["модель"] = "gpt-6-sol"
        данные = оболочка["данные"]
        оболочка["sha256"] = модель.чтение._хэш(модель.чтение._байты(данные))
        self.старый_кэш.write_bytes(модель.чтение._байты(оболочка))
        self.старый_отчёт.write_bytes(модель.чтение._байты(данные["история"]))
        with self.assertRaisesRegex(ValueError, "последнее наблюдение не совпадает"):
            self.перенос()
        self.assertFalse(self.новый_кэш.exists())

    def test_сбой_между_курсором_и_историей_восстанавливает_обычный_импорт(self):
        self.наблюдать("gpt-6-sol", "ultra")
        установить = модель.чтение._установить

        def отказ(путь, данные):
            if путь == self.новый_отчёт:
                raise OSError("синтетический сбой")
            установить(путь, данные)

        with patch.object(модель.чтение, "_установить", side_effect=отказ):
            with self.assertRaises(OSError):
                self.перенос()
        self.assertTrue(self.новый_кэш.exists())
        self.assertFalse(self.новый_отчёт.exists())
        модель.импортировать(self.источник, self.задача,
            корень_репозитория=self.корень, кэш=self.новый_кэш,
            история=self.новый_отчёт)
        новая = json.loads(self.новый_отчёт.read_bytes())
        self.assertEqual(новая["число_наблюдений"], 2)
        self.assertFalse(json.loads(self.новый_кэш.read_bytes())["данные"]["подготовлено"])

    def test_сбой_после_истории_и_новый_хвост_восстанавливаются(self):
        self.наблюдать("gpt-6-sol", "ultra")
        установить = модель.чтение._установить
        записи_курсора = 0

        def отказ(путь, данные):
            nonlocal записи_курсора
            if путь == self.новый_кэш:
                записи_курсора += 1
                if записи_курсора == 2:
                    raise OSError("сбой после новой истории")
            установить(путь, данные)

        with patch.object(модель.чтение, "_установить", side_effect=отказ):
            with self.assertRaises(OSError):
                self.перенос()
        self.assertTrue(self.новый_отчёт.exists())
        self.assertTrue(json.loads(self.новый_кэш.read_bytes())["данные"]["подготовлено"])
        self.наблюдать("gpt-6-luna", "low")
        результат = модель.импортировать(self.источник, self.задача,
            корень_репозитория=self.корень, кэш=self.новый_кэш,
            история=self.новый_отчёт)
        self.assertTrue(результат["полнота"])
        self.assertEqual(результат["новых_наблюдений"], 1)
        self.assertEqual(json.loads(self.новый_отчёт.read_bytes())["число_наблюдений"], 3)
        self.assertFalse(json.loads(self.новый_кэш.read_bytes())["данные"]["подготовлено"])


if __name__ == "__main__":
    unittest.main()
