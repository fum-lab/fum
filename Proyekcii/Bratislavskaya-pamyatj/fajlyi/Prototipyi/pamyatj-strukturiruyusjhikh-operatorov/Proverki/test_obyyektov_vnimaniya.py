"""Открытые самодостаточные свидетельства Git, без локального хранилища Git."""
import base64
import hashlib
import json
import importlib.util
import sys
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace
from pathlib import Path


class ПроверкиОбъектов(unittest.TestCase):
    @classmethod
    def setUpClass(класс):
        путь = Path(__file__).resolve().parents[1] / "Сборщики/объекты_внимания.py"
        описание = importlib.util.spec_from_file_location("объекты_внимания", путь)
        класс.модуль = importlib.util.module_from_spec(описание)
        sys.modules[описание.name] = класс.модуль
        описание.loader.exec_module(класс.модуль)

    def добавить(сам, набор, тип, байты):
        номер = hashlib.sha1(тип.encode() + b" " + str(len(байты)).encode() + b"\0" + байты).hexdigest()
        набор[номер] = {"тип": тип, "байты": base64.b64encode(байты).decode()}
        return номер

    def фикстура(сам):
        набор = {}
        файл = сам.добавить(набор, "blob", "# Свидетельство\n".encode())
        дерево = сам.добавить(набор, "tree", b"100644 report.txt\0" + bytes.fromhex(файл))
        первый = сам.добавить(набор, "commit", f"tree {дерево}\nauthor Open Fixture <fixture@example.invalid> 0 +0000\ncommitter Open Fixture <fixture@example.invalid> 0 +0000\n\nПервый\n".encode())
        второй = сам.добавить(набор, "commit", f"tree {дерево}\nparent {первый}\nauthor Open Fixture <fixture@example.invalid> 1 +0000\ncommitter Open Fixture <fixture@example.invalid> 1 +0000\n\nВторой\n".encode())
        return набор, первый, второй, дерево, файл

    def test_привязка_файла_к_коммиту_и_полное_ancestry(сам):
        набор, первый, второй, дерево, файл = сам.фикстура()
        чтение = сам.модуль.НаборОбъектов(набор)
        сам.assertEqual(чтение.коммит(второй)["дерево"], дерево)
        сам.assertEqual(чтение.файл(второй, "report.txt"), (файл, "# Свидетельство\n".encode()))
        сам.assertEqual(чтение.ancestry(первый, второй)["предок"], "да")
        сам.assertEqual(чтение.ancestry(второй, первый)["предок"], "нет")
        сам.assertEqual(чтение.ancestry(второй, первый)["полнота"], "полная")

    def test_отсутствующий_родитель_не_доказывает_отрицание(сам):
        набор, первый, второй, _, _ = сам.фикстура()
        del набор[первый]
        with сам.assertRaises(ValueError):
            сам.модуль.НаборОбъектов(набор).ancestry(второй, второй)

    def test_повреждение_байтов_или_типа_отклоняется(сам):
        for поле, значение in [("байты", "AAAA"), ("тип", "tag")]:
            набор, _, _, _, файл = сам.фикстура()
            набор[файл][поле] = значение
            with сам.assertRaises(ValueError):
                сам.модуль.НаборОбъектов(набор).объект(файл, "blob")

    def test_симлинк_и_выход_за_дерево_отклоняются(сам):
        набор, первый, _, _, _ = сам.фикстура()
        with сам.assertRaises(ValueError):
            сам.модуль.НаборОбъектов(набор).файл(первый, "../report.txt")
        цель = сам.добавить(набор, "blob", b"report.txt")
        дерево = сам.добавить(набор, "tree", "120000 ссылка\0".encode() + bytes.fromhex(цель))
        коммит = сам.добавить(набор, "commit", f"tree {дерево}\n\nСсылка\n".encode())
        with сам.assertRaises(ValueError):
            сам.модуль.НаборОбъектов(набор).файл(коммит, "ссылка")

    def test_восстановление_v3_из_объектов_без_веток(сам):
        набор, первый, второй, _, _ = сам.фикстура()
        ожидаемый = hashlib.sha256()
        for метка, байты in [("вершина", первый.encode()), ("индекс", b""), ("рабочее_дерево", b"")]:
            код = метка.encode()
            ожидаемый.update(len(код).to_bytes(8, "big") + код + len(байты).to_bytes(8, "big") + байты)
        исход = сам.модуль.восстановить_отпечаток(
            сам.модуль.НаборОбъектов(набор), второй,
            "Журнал/2026-09-11_12-00-00_MSK_проверить-фикстуру", Path(__file__).resolve().parents[3])
        сам.assertEqual(исход["кандидат"], "sha256:" + ожидаемый.hexdigest())
        # Новый корректный Merkle-граф не переносит приёмку старых байтов.
        файл = сам.добавить(набор, "blob", b"changed\n")
        дерево = сам.добавить(набор, "tree", b"100644 report.txt\0" + bytes.fromhex(файл))
        изменённый = сам.добавить(набор, "commit", f"tree {дерево}\nparent {первый}\n\nИзменение\n".encode())
        другой = сам.модуль.восстановить_отпечаток(
            сам.модуль.НаборОбъектов(набор), изменённый,
            "Журнал/2026-09-11_12-00-00_MSK_проверить-фикстуру", Path(__file__).resolve().parents[3])
        сам.assertNotEqual(другой["кандидат"], исход["кандидат"])

    def test_отпечаток_не_требует_метаданных_принимающего_git(сам):
        набор, _, второй, _, _ = сам.фикстура()
        with tempfile.TemporaryDirectory() as каталог:
            исход = сам.модуль.восстановить_отпечаток(сам.модуль.НаборОбъектов(набор), второй,
                "Журнал/2026-09-11_12-00-00_MSK_проверить-фикстуру", Path(каталог))
            сам.assertTrue(исход["кандидат"].startswith("sha256:"))
            сам.assertEqual(list(Path(каталог).iterdir()), [])

    def test_архив_имеет_закрытую_оболочку_и_не_принимает_повторы(сам):
        правильный = {"схема":"fum.архив-объектов-внимания.1", "цель":"1" * 40, "примеры":[], "объекты":{}}
        сам.assertEqual(сам.модуль.разобрать_архив(json.dumps(правильный).encode())["объекты"], {})
        for байты in [b'{"a":1,"a":2}', b'[]', json.dumps({**правильный, "объекты":None}).encode(), json.dumps({**правильный, "схема":"неизвестная"}).encode(), json.dumps({**правильный, "лишнее":1}).encode()]:
            with сам.assertRaises(ValueError):
                сам.модуль.разобрать_архив(байты)

    def test_live_размер_проверяется_до_чтения_содержимого(сам):
        номер = "f" * 40
        ответ = SimpleNamespace(returncode=0, stdout=f"{номер} blob {8 * 1024 * 1024 + 1}\n".encode())
        with patch.object(сам.модуль, "выполнить_ограниченно", return_value=ответ) as вызов:
            with сам.assertRaises(ValueError):
                сам.модуль.НаборОбъектов(корень=Path(".")).объект(номер, "blob")
        сам.assertEqual(вызов.call_count, 1)
        сам.assertEqual(вызов.call_args.args[0][-1], "--batch-check")

    def test_live_не_перерастает_предел_набора(сам):
        набор = {f"{номер:040x}": {} for номер in range(8192)}
        with patch.object(сам.модуль, "выполнить_ограниченно", side_effect=AssertionError("Лишнее чтение")):
            with сам.assertRaises(ValueError):
                сам.модуль.НаборОбъектов(набор, корень=Path(".")).объект("f" * 40, "blob")

    def test_суммарный_кэш_ограничен_до_сохранения(сам):
        набор = {}
        а = сам.добавить(набор, "blob", b"1234")
        б = сам.добавить(набор, "blob", b"5678")
        чтение = сам.модуль.НаборОбъектов(набор)
        with patch.object(сам.модуль, "ПРЕДЕЛ_ПАМЯТИ", 7, create=True):
            сам.assertEqual(чтение.объект(а, "blob"), b"1234")
            with сам.assertRaises(ValueError):
                чтение.объект(б, "blob")
        сам.assertNotIn((б, "blob"), чтение.кэш)

    def test_глубина_и_развёрнутые_пути_ограничены(сам):
        набор = {}
        дерево = сам.добавить(набор, "tree", b"")
        for _ in range(6):
            дерево = сам.добавить(набор, "tree", b"40000 a\0" + bytes.fromhex(дерево) + b"40000 b\0" + bytes.fromhex(дерево))
        чтение = сам.модуль.НаборОбъектов(набор)
        with patch.object(сам.модуль, "ПРЕДЕЛ_ГЛУБИНЫ", 3):
            with сам.assertRaises(ValueError):
                чтение.замыкание_деревьев(дерево)
        with patch.object(сам.модуль, "ПРЕДЕЛ_ПУТЕЙ", 10):
            with сам.assertRaises(ValueError):
                чтение.собрать_разницу(None, дерево, "Журнал/фикстура")

    def test_вывод_процесса_останавливается_на_пределе(сам):
        with сам.assertRaises(ValueError):
            сам.модуль.выполнить_ограниченно([sys.executable, "-I", "-S", "-c", "print('x' * 4096)"], {}, предел=32)


if __name__ == "__main__":
    unittest.main()
