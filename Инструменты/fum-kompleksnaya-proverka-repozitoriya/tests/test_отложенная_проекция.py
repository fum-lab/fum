import contextlib
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import test_run_smoke_check as исходный


class ТестыОтложеннойПроекции(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name)
        сам.фикстура = исходный.RunSmokeCheckTests()
        сам.фикстура.write_script_fixture(сам.корень)
        сам.фикстура.создать_фикстуры_документационных_тестов(сам.корень)
        сам.модуль = исходный.run_smoke_check

    def план(сам, **параметры):
        return сам.модуль.build_steps(сам.корень, None, include_session=False,
                                     python="python3", **параметры)

    def test_отложены_ровно_два_шага_остальной_план_сохранён(сам):
        обычный = сам.план()
        частичный = сам.план(проекция="отложена", основание_отложения_проекции="Пауза пользователя")
        сам.assertEqual(len(обычный), len(частичный))
        отложенные = []
        for до, после in zip(обычный, частичный):
            if "братиславской проекции памяти" in до.name:
                сам.assertEqual(до.name, после.name)
                сам.assertIsNone(после.command)
                сам.assertTrue(после.отложен)
                сам.assertIn("Пауза пользователя", после.detail)
                отложенные.append(после)
            else:
                сам.assertEqual(до, после)
        сам.assertEqual(len(отложенные), 2)

    def test_остальные_команды_исполнены_но_полного_успеха_нет(сам):
        шаги = сам.план(проекция="отложена", основание_отложения_проекции="Пауза пользователя")
        вывод = io.StringIO()
        with mock.patch.object(сам.модуль.subprocess, "run", return_value=
                               subprocess.CompletedProcess([], 0, "", "")) as процесс:
            with contextlib.redirect_stdout(вывод):
                код = сам.модуль.run_steps(шаги, сам.корень)
        сам.assertEqual(код, 4)
        сам.assertEqual([в.args[0] for в in процесс.call_args_list],
                        [ш.command for ш in шаги if ш.command is not None])
        сам.assertFalse(any("братиславская_проекция_памяти.py" in арг
                             for в in процесс.call_args_list for арг in в.args[0]))
        записи = [json.loads(строка.removeprefix("smoke-timing "))
                  for строка in вывод.getvalue().splitlines() if строка.startswith("smoke-timing ")]
        сам.assertEqual([з["result"] for з in записи if з["kind"] == "step"].count("отложено"), 2)
        сам.assertEqual(записи[-1]["result"], "отложено")
        сам.assertEqual(записи[-1]["exit_code"], 4)
        сам.assertNotIn("smoke-check passed", вывод.getvalue())

    def test_настоящий_отказ_после_отложения_сохраняет_код(сам):
        шаги = [сам.модуль.SmokeStep("Пауза", None, "Основание", отложен=True),
                сам.модуль.SmokeStep("Следующая проверка", ("python3", "проверка.py"))]
        for код_отказа in (9, 4):
            вывод = io.StringIO()
            with сам.subTest(код=код_отказа), mock.patch.object(сам.модуль.subprocess, "run", return_value=
                                   subprocess.CompletedProcess([], код_отказа, "", "отказ")):
                with contextlib.redirect_stdout(вывод), contextlib.redirect_stderr(io.StringIO()):
                    сам.assertEqual(сам.модуль.run_steps(шаги, сам.корень), код_отказа)
            записи = [json.loads(строка.removeprefix("smoke-timing "))
                      for строка in вывод.getvalue().splitlines() if строка.startswith("smoke-timing ")]
            сам.assertEqual(записи[-1]["result"], "failed")
            сам.assertEqual(записи[-1]["exit_code"], код_отказа)

    def test_неизвестный_режим_и_неполное_основание_отклонены(сам):
        for режим, основание in [("пропустить", "Пауза"), ("отложена", None),
                                 ("отложена", " \t"), ("активна", "Пауза")]:
            with сам.subTest(режим=режим, основание=основание):
                with сам.assertRaises(ValueError):
                    сам.план(проекция=режим, основание_отложения_проекции=основание)

    def test_контур_приёмки_не_принимает_отложенную_проекцию(сам):
        with сам.assertRaisesRegex(ValueError, "контур слияния"):
            сам.план(проекция="отложена", основание_отложения_проекции="Пауза",
                     корень_проверок=сам.корень)

    def test_отложенный_шаг_не_может_исполнять_команду(сам):
        with сам.assertRaises(ValueError):
            сам.модуль.SmokeStep("Противоречие", ("python3",), отложен=True)

    def test_неоднозначные_параметры_отклонены_до_плана(сам):
        for хвост in [("--проекция", "отложена", "--проекция", "активна"),
                      ("--проекция=активна", "--проекция=отложена"),
                      ("--прое", "отложена")]:
            with сам.subTest(хвост=хвост), mock.patch.object(sys, "argv", ["run-smoke-check.py", *хвост]):
                with contextlib.redirect_stderr(io.StringIO()), сам.assertRaises(SystemExit) as отказ:
                    сам.модуль.parse_args()
                сам.assertEqual(отказ.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
