"""Синтетический контракт наблюдений; настоящие JSONL не требуются."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from история_модели import импортировать, подготовить_коммит
import история_модели as модуль


class ИсторияМодели(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.каталог = Path(self.временный.name).resolve()
        self.корень = self.каталог / "репозиторий"
        self.корень.mkdir()
        self.источник = self.каталог / "native.jsonl"
        self.кэш = self.каталог / "кэш.json"
        self.история = self.корень / "история.json"
        self.задача = "00000000-0000-0000-0000-000000000001"
        self.исходные = []
        self.добавить({"type": "session_meta", "payload": {"id": self.задача}})

    def добавить(self, запись):
        строка = (json.dumps(запись) + "\n").encode()
        with self.источник.open("ab") as поток:
            поток.write(строка)
        self.исходные.append(строка)

    def наблюдать(self, модель="gpt-6-astra", усилие="low"):
        self.добавить({"type": "turn_context", "timestamp": "2026-09-15T16:00:00Z",
                      "payload": {"model": модель, "effort": усилие}})

    def импорт(self, **параметры):
        return импортировать(self.источник, self.задача, корень_репозитория=self.корень,
                            кэш=self.кэш, история=self.история, **параметры)

    def test_первое_смены_повтор_и_происхождение(self):
        self.наблюдать()
        self.наблюдать()
        self.наблюдать(усилие="high")
        результат = self.импорт()
        история = json.loads(self.история.read_bytes())
        self.assertEqual(история["число_наблюдений"], 3)
        self.assertEqual(len(история["события"]), 2)
        первое = история["события"][0]
        self.assertEqual(первое["позиция"], {"начало": len(self.исходные[0]),
            "конец": len(self.исходные[0]) + len(self.исходные[1]),
            "sha256": hashlib.sha256(self.исходные[1]).hexdigest()})
        self.assertEqual(первое["причина"], "unknown")
        self.assertEqual(первое["инициатор"], "unknown")
        self.assertFalse(история["переключения_между_наблюдениями_известны"])
        байты = self.история.read_bytes()
        повтор = self.импорт(без_записи=True)
        self.assertEqual(повтор["новых_наблюдений"], 0)
        self.assertEqual(повтор["профиль"]["прочитано_байтов"], 0)
        self.assertEqual(self.история.read_bytes(), байты)
        self.наблюдать(модель="другая")
        self.assertEqual(self.импорт()["новых_наблюдений"], 1)

    def test_неполная_строка_и_пропуск(self):
        self.наблюдать()
        with self.источник.open("ab") as поток:
            поток.write(b'{bad}\n')
        self.добавить({"type": "turn_context", "payload": {"model": "x"}})
        with self.источник.open("ab") as поток:
            поток.write(b'{"type":')
        результат = self.импорт()
        self.assertEqual(результат["неполный_хвост"], 8)
        self.assertEqual(результат["пропусков"], 2)
        self.assertFalse(результат["полнота"])

    def test_усечение_замена_и_изменение_префикса(self):
        self.наблюдать()
        self.импорт()
        старое = self.история.read_bytes()
        self.источник.write_bytes(self.источник.read_bytes().replace(b'low', b'xxx'))
        with self.assertRaises(ValueError):
            self.импорт()
        self.assertEqual(self.история.read_bytes(), старое)
        self.источник.write_bytes(b'')
        with self.assertRaises(ValueError):
            self.импорт()

    def test_замена_даже_при_равных_байтах(self):
        self.наблюдать()
        self.импорт()
        новый = self.каталог / "новый"
        новый.write_bytes(self.источник.read_bytes())
        новый.replace(self.источник)
        with self.assertRaises(ValueError):
            self.импорт()

    def test_без_записи_не_создаёт_файлов(self):
        self.наблюдать()
        self.импорт(без_записи=True)
        self.assertFalse(self.кэш.exists())
        self.assertFalse(self.история.exists())
        self.assertFalse(Path(str(self.кэш) + '.lock').exists())

    def test_запрет_выхода_и_ссылки_в_пути(self):
        self.наблюдать()
        self.история = self.корень / '..' / 'вне.json'
        with self.assertRaises(ValueError):
            self.импорт()
        ссылка = self.каталог / 'ссылка'
        ссылка.symlink_to(self.корень, target_is_directory=True)
        with self.assertRaises(ValueError):
            модуль._путь(ссылка / 'сообщение.txt')

    def test_сбой_между_записями_и_рост_источника(self):
        self.наблюдать()
        self.импорт()
        self.наблюдать(усилие='high')
        установить = модуль.чтение._установить
        def отказ(путь, данные):
            if путь == self.кэш and not json.loads(данные)['данные']['подготовлено']:
                raise OSError('синтетический сбой фиксации курсора')
            установить(путь, данные)
        with patch.object(модуль.чтение, '_установить', side_effect=отказ):
            with self.assertRaises(OSError):
                self.импорт()
        self.наблюдать(усилие='low')
        self.импорт()
        история = json.loads(self.история.read_bytes())
        self.assertEqual(история['число_наблюдений'], 3)
        self.assertEqual(len(история['события']), 3)

    def test_подготовка_коммита_из_того_же_наблюдения(self):
        self.наблюдать()
        результат = self.импорт()
        основа = "Изменить инструмент\n\nИсходный запрос.\n\nCodex-Thread-ID: " + self.задача + "\n"
        текст = подготовить_коммит(основа, результат, self.задача)
        self.assertIn("model: gpt-6-astra\neffort: low\n", текст)
        self.assertTrue(текст.endswith("Codex-Thread-ID: " + self.задача + "\n"))
        self.assertEqual(подготовить_коммит(текст, результат, self.задача), текст)
        with self.assertRaises(ValueError):
            подготовить_коммит(основа.replace(self.задача, 'wrong'), результат, self.задача)


if __name__ == "__main__":
    unittest.main()
