"""Один полный разбор файла для нескольких точных деклараций."""

import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import test_obnovitj_policy as основа


class ПроверкиПакетногоАнализа(unittest.TestCase):
    def setUp(сам):
        временный = tempfile.TemporaryDirectory()
        сам.addCleanup(временный.cleanup)
        сам.корень = Path(временный.name).resolve()
        сам.помощник = основа.PolicyUpdaterTests()
        сам.помощник.init_repo(сам.корень)
        сам.строка = "ROOT = '" + chr(47) + "private/example'"
        сам.другая = "SECOND = '" + chr(47) + "private/second'"
        сам.первый = сам.помощник.write_and_add(
            сам.корень, "tests/первый.py",
            сам.строка + "\n" + сам.другая + "\n" + сам.строка + "\n",
        )
        сам.второй = сам.помощник.write_and_add(
            сам.корень, "tests/второй.py", сам.строка + "\n",
        )
        сам.политика = сам.помощник.write_policy(сам.корень)
        сам.декларации = [
            сам.помощник.declaration(identifier="batch-first", path="tests/первый.py"),
            сам.помощник.declaration(identifier="batch-other", path="tests/второй.py"),
            сам.помощник.declaration(identifier="batch-second", path="tests/первый.py", line=2),
        ]

    def test_один_разбор_каждого_файла_с_полным_счётчиком_и_точным_повтором(сам):
        with mock.patch.object(
            основа.updater.scanner, "scan_text", wraps=основа.updater.scanner.scan_text,
        ) as разбор:
            сам.assertEqual(основа.updater.update_policy(
                сам.корень, сам.политика, сам.декларации,
            ), 3)
        исключения = json.loads(сам.политика.read_bytes())["exceptions"]
        сам.assertEqual([запись["id"] for запись in исключения], [
            "batch-first", "batch-other", "batch-second",
        ])
        сам.assertEqual([запись["count"] for запись in исключения], [2, 1, 1])
        сам.assertEqual(исключения[0]["line_sha256"],
                        "sha256:" + hashlib.sha256(сам.строка.encode()).hexdigest())
        сам.assertEqual([вызов.args[0] for вызов in разбор.call_args_list],
                        ["tests/первый.py", "tests/второй.py"])
        байты = сам.политика.read_bytes()
        метаданные = сам.политика.stat()
        сам.assertEqual(основа.updater.update_policy(
            сам.корень, сам.политика, сам.декларации,
        ), 0)
        сам.assertEqual(сам.политика.read_bytes(), байты)
        сам.assertEqual(сам.политика.stat().st_ino, метаданные.st_ino)
        сам.assertEqual(сам.политика.stat().st_mtime_ns, метаданные.st_mtime_ns)

    def test_неверная_поздняя_декларация_не_меняет_политику(сам):
        исходные = сам.политика.read_bytes()
        декларации = сам.декларации + [сам.помощник.declaration(
            identifier="batch-invalid", path="tests/первый.py", line=4,
        )]
        with сам.assertRaisesRegex(основа.updater.UpdateError, "outside the file"):
            основа.updater.update_policy(сам.корень, сам.политика, декларации)
        сам.assertEqual(сам.политика.read_bytes(), исходные)

    def test_следующий_вызов_заново_читает_изменённый_файл(сам):
        основа.updater.update_policy(сам.корень, сам.политика, сам.декларации)
        сам.первый.write_text(сам.строка + "\n" + сам.другая + "\n", encoding="utf-8")
        сам.assertEqual(основа.updater.update_policy(
            сам.корень, сам.политика, сам.декларации,
        ), 1)
        исключения = json.loads(сам.политика.read_bytes())["exceptions"]
        сам.assertEqual([запись["count"] for запись in исключения], [1, 1, 1])


if __name__ == "__main__":
    unittest.main()
