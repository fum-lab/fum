"""Отказные фикстуры ограниченного проверяющего плановых входов."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ПУТЬ = Path(__file__).resolve().parents[1] / "контроль_манифеста.py"
СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location("контроль", ПУТЬ)
МОДУЛЬ = importlib.util.module_from_spec(СПЕЦИФИКАЦИЯ)
СПЕЦИФИКАЦИЯ.loader.exec_module(МОДУЛЬ)


class ПроверкаМанифеста(unittest.TestCase):
    def setUp(self):
        self.каталог = tempfile.TemporaryDirectory()
        self.addCleanup(self.каталог.cleanup)
        self.корень = Path(self.каталог.name)
        (self.корень / "Источники").mkdir()
        конфигурация = {"branch-schemes": {"release/6.1": {"repos": {"swift": "release/6.1", "llvm": "release/6.1"}}}}
        (self.корень / "Источники/config").write_text(json.dumps(конфигурация))
        (self.корень / "Источники/license").write_text("Полная лицензия фикстуры")
        наблюдения = {"репозитории": [{"имя": имя, "tag": "1", "oid": "a" * 40, "refs": {"refs/tags/1": "a" * 40}} for имя in ("swift", "llvm")]}
        пины = self.корень / "пины.json"
        пины.write_text(json.dumps(наблюдения))
        (self.корень / "профиль.ini").write_text("[preset: fixture]\n")
        self.данные = {
            "схема": "fum.план-комплекта-Swift.1",
            "схема_веток": "release/6.1",
            "закрепление_OID": {"путь": "пины.json", "sha256": hashlib.sha256(пины.read_bytes()).hexdigest()},
            "конфигурация": "Источники/config",
            "upstream_preset": "Источники/license",
            "профиль": {"путь": "профиль.ini", "sha256": hashlib.sha256((self.корень / "профиль.ini").read_bytes()).hexdigest()},
            "репозитории": [
                {"имя": имя, "oid": "a" * 40, "лицензии": ["Источники/license"], "ограничение_лицензии": None}
                for имя in ("swift", "llvm")
            ],
            "входы": [{"имя": имя, "sha256": None} for имя in sorted(МОДУЛЬ.ОБЯЗАТЕЛЬНЫЕ_ВХОДЫ)],
            "рёбра": [{"от": "swift", "к": "llvm", "условие": "всегда"}, {"от": "swift", "к": "SDK", "условие": "Darwin"}],
            "снимки": [{"путь": "Источники/" + имя, "sha256": hashlib.sha256((self.корень / "Источники" / имя).read_bytes()).hexdigest()}
                       for имя in ("config", "license")],
            "препятствия": ["Байты SDK не получены"],
            "полнота_исходников": False,
            "готовность_сборки": False,
        }

    def test_план_с_препятствием_не_готовность(self):
        МОДУЛЬ.проверить(self.данные, self.корень)
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень, требовать_готовность=True)

    def test_пропуск_репозитория(self):
        self.данные["репозитории"].pop()
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_неизвестное_ребро(self):
        self.данные["рёбра"][0]["к"] = "неучтённый"
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_дрейф_лицензии(self):
        (self.корень / "Источники/license").write_text("Подмена")
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_пропущенная_лицензия(self):
        self.данные["репозитории"][0]["лицензии"] = []
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_короткий_oid_и_дубликат(self):
        for изменение in ("короткий", "дубликат"):
            данные = copy.deepcopy(self.данные)
            if изменение == "короткий":
                данные["репозитории"][0]["oid"] = "a123"
            else:
                данные["репозитории"].append(данные["репозитории"][0])
            with self.assertRaises(ValueError):
                МОДУЛЬ.проверить(данные, self.корень)

    def test_символическая_ссылка_и_выход(self):
        (self.корень / "Источники/license").unlink()
        (self.корень / "Источники/license").symlink_to(self.корень / "Источники/config")
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)
        with self.assertRaises(ValueError):
            МОДУЛЬ.безопасный_путь(self.корень, "../вне")

    def test_ложная_готовность(self):
        self.данные["готовность_сборки"] = True
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_готовность_без_обязательных_входов(self):
        self.данные.update(входы=[], рёбра=[], полнота_исходников=True, препятствия=[], готовность_сборки=True)
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень, требовать_готовность=True)

    def test_подмена_полного_oid(self):
        self.данные["репозитории"][0]["oid"] = "b" * 40
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_готовность_при_неизвестной_лицензии(self):
        self.данные["репозитории"][0].update(лицензии=[], ограничение_лицензии="Не установлена")
        self.данные.update(полнота_исходников=True, препятствия=[], готовность_сборки=True)
        for вход in self.данные["входы"]:
            вход["sha256"] = "c" * 64
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень, требовать_готовность=True)

    def test_изменённый_профиль(self):
        (self.корень / "профиль.ini").write_text("Другой состав")
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_отсутствие_upstream_preset(self):
        self.данные["upstream_preset"] = "Источники/не-закреплён"
        with self.assertRaises(ValueError):
            МОДУЛЬ.проверить(self.данные, self.корень)

    def test_повтор_json_ключа(self):
        with self.assertRaises(ValueError):
            МОДУЛЬ.прочитать_json('{"oid": "a", "oid": "b"}')


if __name__ == "__main__":
    unittest.main()
