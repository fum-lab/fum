from __future__ import annotations

import copy
import importlib.util
import json
import pathlib
import unittest


КАТАЛОГ_ИНСТРУМЕНТА = pathlib.Path(__file__).resolve().parents[1]
ПУТЬ_МОДУЛЯ = КАТАЛОГ_ИНСТРУМЕНТА / "scripts" / "паспорт_конвейера.py"
СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location("паспорт_конвейера", ПУТЬ_МОДУЛЯ)
МОДУЛЬ = importlib.util.module_from_spec(СПЕЦИФИКАЦИЯ)
assert СПЕЦИФИКАЦИЯ.loader is not None
СПЕЦИФИКАЦИЯ.loader.exec_module(МОДУЛЬ)


class ТестПаспортаКонвейера(unittest.TestCase):
    def действительный_паспорт(self) -> dict:
        return {
            "schema": "fum.конвейер-производных-веток.v1",
            "pipeline_id": "контекст-fuma",
            "root_layer_id": "корень",
            "branch_naming": {
                "scheme": "bratislavskaya-path-slug.v2",
                "namespace": "fum",
            },
            "layers": [
                {
                    "layer_id": "корень",
                    "branch_ref": "refs/heads/fum/root",
                    "directory_path": "",
                    "parent_layer_id": None,
                    "worktree": "FUM-worktrees/fum/root",
                    "writer": "FUM Корень",
                    "lifecycle": "permanent",
                    "status": "active",
                    "depends_on": [],
                },
                {
                    "layer_id": "события",
                    "branch_ref": "refs/heads/fum/dir/pamyatj--sobyitiya",
                    "directory_path": "Память/события/",
                    "parent_layer_id": "корень",
                    "worktree": "FUM-worktrees/fum/dir/pamyatj--sobyitiya",
                    "writer": "FUM События",
                    "lifecycle": "temporary",
                    "status": "active",
                    "depends_on": [],
                },
                {
                    "layer_id": "значимые-сообщения",
                    "branch_ref": "refs/heads/fum/dir/pamyatj--sobyitiya--znachimyiye-soobsjheniya",
                    "directory_path": "Память/события/значимые-сообщения/",
                    "parent_layer_id": "события",
                    "worktree": "FUM-worktrees/fum/dir/pamyatj--sobyitiya--znachimyiye-soobsjheniya",
                    "writer": "FUM Сообщения",
                    "lifecycle": "temporary",
                    "status": "active",
                    "depends_on": ["события"],
                },
                {
                    "layer_id": "требования",
                    "branch_ref": "refs/heads/fum/dir/planirovaniye--trebovaniya",
                    "directory_path": "Планирование/требования/",
                    "parent_layer_id": "корень",
                    "worktree": "FUM-worktrees/fum/dir/planirovaniye--trebovaniya",
                    "writer": "FUM Требования",
                    "lifecycle": "permanent",
                    "status": "active",
                    "depends_on": ["значимые-сообщения"],
                },
            ],
            "path_owners": [
                {
                    "path": "Память/события/",
                    "kind": "directory",
                    "layer_id": "события",
                },
                {
                    "path": "Память/события/значимые-сообщения/",
                    "kind": "directory",
                    "layer_id": "значимые-сообщения",
                },
                {
                    "path": "Память/события/README.md",
                    "kind": "readme",
                    "inherits": "Память/события/",
                },
                {
                    "path": "Планирование/требования/",
                    "kind": "directory",
                    "layer_id": "требования",
                },
                {
                    "path": "Индексы/markdown-файлы-по-времени-редактирования.md",
                    "kind": "file",
                    "layer_id": "корень",
                },
            ],
            "storage_targets": [
                {
                    "target_id": "монорепо",
                    "kind": "git",
                    "path": "Память/события/",
                    "format": "tracked-files",
                    "status": "planned",
                },
                {
                    "target_id": "журнал",
                    "kind": "journal",
                    "path": "Журнал/",
                    "format": "jsonl",
                    "status": "planned",
                },
            ],
            "deliveries": [
                {
                    "delivery_id": "вперёд-1",
                    "direction": "forward",
                    "from_layer": "события",
                    "to_layer": "значимые-сообщения",
                    "base_oid": "a" * 40,
                    "result_oid": "b" * 40,
                    "status": "accepted",
                },
                {
                    "delivery_id": "обратно-1",
                    "direction": "reverse",
                    "from_layer": "требования",
                    "to_layer": "корень",
                    "base_oid": "c" * 40,
                    "result_oid": "d" * 40,
                    "status": "pending",
                    "accepted_paths": ["Планирование/требования/"],
                },
            ],
        }

    def проверить(self, паспорт: dict) -> dict:
        return МОДУЛЬ.проверить_паспорт(паспорт)

    def test_действительный_паспорт_возвращает_сводку_и_профиль(self) -> None:
        результат = self.проверить(self.действительный_паспорт())
        self.assertTrue(результат["valid"])
        self.assertEqual(результат["layers"], 4)
        self.assertEqual(результат["path_owners"], 5)
        self.assertEqual(результат["deliveries"], 2)
        self.assertEqual(результат["reverse_deliveries"], 1)
        self.assertEqual(результат["storage_targets"], 2)
        self.assertIn("profile", результат)
        self.assertGreaterEqual(результат["profile"]["duration_ns"], 0)

    def test_readme_обязан_наследовать_писателя_директории(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["path_owners"][2]["inherits"] = "Планирование/требования/"
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "README"):
            self.проверить(паспорт)

    def test_пересечение_владельцев_отклоняется(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["path_owners"].append(
            {
                "path": "Память/события/подкаталог/",
                "kind": "directory",
                "layer_id": "требования",
            }
        )
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "пересеч|каталог"):
            self.проверить(паспорт)

    def test_ref_fum_и_дочерний_ref_отклоняются(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["layers"][0]["branch_ref"] = "refs/heads/fum"
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "ref"):
            self.проверить(паспорт)

    def test_ветка_выводится_из_братиславского_пути_каталога(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["layers"][1]["branch_ref"] = "refs/heads/fum/sobytiya"
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "братислав|ветк"):
            self.проверить(паспорт)

    def test_братиславский_срез_совпадает_с_закреплённым_преобразователем(self) -> None:
        ожидаемые = {
            "Память": "Pamyatj",
            "события": "sobyitiya",
            "значимые-сообщения": "znachimyiye-soobsjheniya",
            "Планирование": "Planirovaniye",
            "требования": "trebovaniya",
            "конвейер производных веток": "konvejyer proizvodnyikh vetok",
        }
        for исходное, ожидаемое in ожидаемые.items():
            with self.subTest(исходное=исходное):
                self.assertEqual(МОДУЛЬ._братиславский_компонент(исходное), ожидаемое)

    def test_иерархический_дочерний_каталог_разрешён(self) -> None:
        паспорт = self.действительный_паспорт()
        self.assertTrue(self.проверить(паспорт)["valid"])

    def test_readme_может_идти_до_объявления_каталога(self) -> None:
        паспорт = self.действительный_паспорт()
        запись_файла_чтения = паспорт["path_owners"].pop(2)
        паспорт["path_owners"].insert(0, запись_файла_чтения)
        self.assertTrue(self.проверить(паспорт)["valid"])

    def test_повтор_worktree_или_писателя_отклоняется(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["layers"][3]["worktree"] = паспорт["layers"][2]["worktree"]
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "worktree"):
            self.проверить(паспорт)

        паспорт = self.действительный_паспорт()
        паспорт["layers"][3]["writer"] = паспорт["layers"][2]["writer"]
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "писател"):
            self.проверить(паспорт)

    def test_цикл_зависимостей_отклоняется(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["layers"][1]["depends_on"] = ["требования"]
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "цикл"):
            self.проверить(паспорт)

    def test_обратная_доставка_должна_возвращаться_в_корень(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["deliveries"][1]["to_layer"] = "события"
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "корень"):
            self.проверить(паспорт)

    def test_небезопасный_путь_отклоняется(self) -> None:
        паспорт = self.действительный_паспорт()
        паспорт["path_owners"][0]["path"] = "../секреты/"
        with self.assertRaisesRegex(МОДУЛЬ.ОшибкаПаспорта, "путь"):
            self.проверить(паспорт)

    def test_профиль_не_меняет_вход(self) -> None:
        паспорт = self.действительный_паспорт()
        исходный = copy.deepcopy(паспорт)
        self.проверить(паспорт)
        self.assertEqual(паспорт, исходный)


if __name__ == "__main__":
    unittest.main()
