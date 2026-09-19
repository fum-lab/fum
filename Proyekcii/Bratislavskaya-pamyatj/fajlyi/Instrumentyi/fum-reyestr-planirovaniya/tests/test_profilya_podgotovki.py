"""Наблюдение сохраняет результат процесса и не публикует его аргументы."""
import json
import subprocess
import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch

from профиль_подготовки_доставки import НаблюдательПроцессов, измерить
import профиль_подготовки_доставки as профиль


class ПроверкиНаблюденияПроцессов(unittest.TestCase):
    def test_возвращает_тот_же_результат_и_скрывает_аргументы(сам):
        результат = subprocess.CompletedProcess([], 0, stdout=b"private-output")
        получено = []

        def запустить(*аргументы, **параметры):
            получено.append((аргументы, параметры))
            return результат

        наблюдатель = НаблюдательПроцессов(запустить)
        наблюдатель.стадия = "подготовка"
        команда = ["git", "-c", "commit.gpgSign=false", "commit", "-m", "private-message"]
        сам.assertIs(наблюдатель(команда, cwd="private-path"), результат)
        сам.assertEqual(получено, [((команда,), {"cwd": "private-path"})])
        сам.assertEqual(len(наблюдатель.записи), 1)
        запись = наблюдатель.записи[0]
        сам.assertEqual((запись["стадия"], запись["команда"], запись["исход"]),
                       ("подготовка", "commit", "успешно"))
        сам.assertGreaterEqual(запись["длительность_наносекунды"], 0)
        сам.assertNotIn("private", json.dumps(наблюдатель.записи))

    def test_сохраняет_исходное_исключение(сам):
        ошибка = subprocess.CalledProcessError(2, ["git", "commit"], stderr=b"private-error")

        def запустить(*аргументы, **параметры):
            raise ошибка

        наблюдатель = НаблюдательПроцессов(запустить)
        with сам.assertRaises(subprocess.CalledProcessError) as пойманная:
            наблюдатель(["git", "commit"])
        сам.assertIs(пойманная.exception, ошибка)
        сам.assertEqual(наблюдатель.записи[0]["исход"], "исключение")
        сам.assertEqual(наблюдатель.записи[0]["код"], 2)
        сам.assertNotIn("private", json.dumps(наблюдатель.записи))

    def test_ненулевой_код_не_превращается_в_успех(сам):
        результат = subprocess.CompletedProcess([], 7)
        наблюдатель = НаблюдательПроцессов(lambda *а, **п: результат)
        сам.assertIs(наблюдатель(["git", "config"]), результат)
        сам.assertEqual(наблюдатель.записи[0]["исход"], "отказ")
        сам.assertEqual(наблюдатель.записи[0]["код"], 7)

    def test_не_считает_чужую_программу_как_git(сам):
        результат = subprocess.CompletedProcess([], 0)
        наблюдатель = НаблюдательПроцессов(lambda *а, **п: результат)
        сам.assertIs(наблюдатель(["python3", "git"]), результат)
        сам.assertEqual(наблюдатель.записи, [])

    def test_очистка_не_скрывает_первичную_ошибку_подготовки(сам):
        папка = SimpleNamespace(name="private-path", cleanup=Mock(side_effect=RuntimeError("private-cleanup")))
        модуль = SimpleNamespace(Фикстура=Mock(side_effect=ValueError("private-setup")))
        with patch.object(профиль.importlib, "import_module", return_value=модуль), \
             patch.object(профиль.tempfile, "TemporaryDirectory", return_value=папка):
            результат = измерить(1)
        сам.assertEqual(результат["ошибка"], "ValueError")
        сам.assertEqual([(x["стадия"], x["тип"]) for x in результат["ошибки"]],
                       [("подготовка", "ValueError"), ("очистка", "RuntimeError")])
        папка.cleanup.assert_called_once()
        сам.assertNotIn("private", json.dumps(результат))

    def test_ошибка_только_очистки_остаётся_ошибкой(сам):
        папка = SimpleNamespace(name="private-path", cleanup=Mock(side_effect=RuntimeError("private-cleanup")))
        модуль = SimpleNamespace(Фикстура=Mock())
        with patch.object(профиль.importlib, "import_module", return_value=модуль), \
             patch.object(профиль.tempfile, "TemporaryDirectory", return_value=папка):
            результат = измерить(1)
        сам.assertEqual(результат["ошибка"], "RuntimeError")
        сам.assertEqual(len(результат["ошибки"]), 1)
