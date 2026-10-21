"""Приём из выбранной копии L после настоящей замены checkout на C."""
from pathlib import Path
import tempfile
import subprocess
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from лаборатория_полной_копии_фасада import выполнить_опыт, Наблюдатель
import лаборатория_полной_копии_фасада as лаборатория


class ПолнаяКопияФасада(unittest.TestCase):
    def test_эффект_и_свежий_повтор_используют_полную_копию_L(сам):
        with tempfile.TemporaryDirectory() as временный:
            результат = выполнить_опыт(3, Path(временный).resolve())
        сам.assertEqual(результат["предметных_запусков"], 1)
        сам.assertEqual(результат["родители"], [результат["L"], результат["C"]])
        сам.assertEqual(результат["дерево_M"], результат["дерево_C"])
        сам.assertEqual(результат["новых_коммитов"], 1)
        сам.assertEqual(результат["файлов_копии"], 30)
        сам.assertTrue(результат["checkout_заменён"])
        сам.assertTrue(результат["повтор_без_изменений"])
        сам.assertEqual(результат["первичный"]["результат"], результат["повтор"]["результат"])
        for запуск in ("первичный", "повтор"):
            сам.assertEqual(результат[запуск]["код_из_копии"], результат["исходники_L"])
            псевдонимы = результат[запуск]["псевдонимы"]
            сам.assertEqual(list(псевдонимы), ["сообщения_задачи._КЛАССИФИКАТОР"])
            запись = псевдонимы["сообщения_задачи._КЛАССИФИКАТОР"]
            сам.assertEqual(запись["sha256"], результат["исходники_L"][запись["путь"]])
            сам.assertEqual(запись["файл_функции"], запись["путь"])
            сам.assertGreater(результат[запуск]["процессов_гит"], 0)
            сам.assertTrue(all(type(элемент["код"]) is int for элемент in результат[запуск]["вызовы_гит"]))

    def test_наблюдатель_передаёт_аргументы_и_возвращает_тот_же_процесс(сам):
        процесс = SimpleNamespace(returncode=None)
        аргументы = ["git", "--version"]
        параметры = {"cwd": "каталог", "env": {"ПРИМЕР": "значение"}, "stdout": subprocess.PIPE}
        with patch("subprocess.Popen", return_value=процесс) as настоящий:
            with Наблюдатель() as след:
                сам.assertIs(subprocess.Popen(аргументы, **параметры), процесс)
        настоящий.assert_called_once_with(аргументы, **параметры)
        сам.assertEqual(след.вызовы_гит[0]["argv"], аргументы)
        сам.assertIsNone(след.вызовы_гит[0]["код"])

    def test_наблюдатель_повторно_бросает_исходное_исключение(сам):
        ошибка = OSError("Лабораторный отказ запуска")
        with patch("subprocess.Popen", side_effect=ошибка) as настоящий:
            with Наблюдатель() as след:
                with сам.assertRaises(OSError) as отказ:
                    subprocess.Popen(["git", "--version"])
        сам.assertIs(отказ.exception, ошибка)
        настоящий.assert_called_once_with(["git", "--version"])
        сам.assertEqual(след.вызовы_гит[0]["исключение"], "OSError")

    def test_незарегистрированный_псевдоним_вне_копии_отвергается(сам):
        with tempfile.TemporaryDirectory() as временный:
            код = Path(временный).resolve() / "копия"
            код.mkdir()
            чужой = SimpleNamespace(__file__=str(код.parent / "чужой.py"))
            владелец = SimpleNamespace(_КЛАССИФИКАТОР=чужой)
            with patch.object(лаборатория, "исходники", return_value={}):
                with patch.dict(лаборатория.sys.modules, {"сообщения_задачи": владелец}, clear=True):
                    with сам.assertRaisesRegex(AssertionError, "псевдоним"):
                        лаборатория.код_из_копии(код)


if __name__ == "__main__":
    unittest.main()
