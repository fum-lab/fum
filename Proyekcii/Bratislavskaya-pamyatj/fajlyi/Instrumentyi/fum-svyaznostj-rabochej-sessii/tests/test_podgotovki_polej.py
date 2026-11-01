"""Настоящий вложенный запуск готовит управляемый блок до проверки полей."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from фикстура_полей_журнала import создать_пару

корень_кода = Path(__file__).resolve().parents[3]
помощник = Path(__file__).resolve().parents[1] / "scripts/подготовить-и-проверить-поля-журнала.py"
обёртка = корень_кода / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py"
маркер = "<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->"


class ПроверкиПодготовкиПолей(unittest.TestCase):
    def setUp(сам):
        сам.корень = Path(сам.enterContext(tempfile.TemporaryDirectory())).resolve()
        сам.запрос = создать_пару(сам.корень)
        сам.отчёт = сам.запрос.with_name("отчёт.md")
        текст = сам.отчёт.read_text()
        начало = текст.index("| Вызов |")
        конец = текст.index("## Источники")
        сам.отчёт.write_text(текст[:начало] +
            "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->\n" +
            маркер + "\n<!-- FUM-CHECK-RUNS:END -->\n\n" + текст[конец:])
        сам.каталог = сам.запрос.parent / "материалы/запуски-проверок"
        for команда in (["init", "-q"], ["add", "."],
                        ["-c", "user.name=Фикстура", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "Фикстура"]):
            subprocess.run(["git", *команда], cwd=сам.корень, check=True, capture_output=True)

    def вызвать(сам, обернуть=False):
        команда = [sys.executable, "-B", str(помощник), "--корень", str(сам.корень), "--запрос", str(сам.запрос)]
        if обернуть:
            команда = [sys.executable, "-B", str(обёртка), "запустить",
                "--корень-репозитория", str(сам.корень), "--запрос", str(сам.запрос),
                "--название", "Подготовить поля", "--исполнитель", "Фикстура",
                "--класс-проверки", "адресная", "--приёмочные-раунды",
                "--тайм-аут-секунды", "20", "--", *команда]
        return subprocess.run(команда, cwd=сам.корень, capture_output=True, text=True, timeout=30)

    def test_первая_активная_запись_завершается_без_взаимной_блокировки(сам):
        сам.assertFalse(сам.каталог.exists())
        результат = сам.вызвать(True)
        сам.assertEqual(результат.returncode, 0, результат.stdout + результат.stderr)
        записи = list(сам.каталог.glob("*.json"))
        сам.assertEqual(len(записи), 1)
        запись = json.loads(записи[0].read_text())
        сам.assertEqual((запись["схема"], запись["состояние"], запись["статус"]),
                        ("fum.test-run.v4", "завершён", "успешно"))
        сам.assertNotIn(маркер, сам.отчёт.read_text())
        сам.assertIn("нет активных»: не выполнено", сам.отчёт.read_text())

    def test_маркер_вне_управляемого_блока_остаётся_ошибкой(сам):
        сам.отчёт.write_text(сам.отчёт.read_text() + "\n" + маркер + "\n")
        результат = сам.вызвать(True)
        сам.assertEqual(результат.returncode, 1, результат.stdout + результат.stderr)
        запись = json.loads(next(сам.каталог.glob("*.json")).read_text())
        сам.assertEqual(запись["статус"], "неуспешно")
        сам.assertEqual(сам.отчёт.read_text().count(маркер), 1)

    def test_отсутствующая_история_не_создаётся_помощником(сам):
        исходное = сам.отчёт.read_bytes()
        результат = сам.вызвать()
        сам.assertEqual(результат.returncode, 2)
        сам.assertTrue(json.loads(результат.stdout)["ошибки"])
        сам.assertFalse(сам.каталог.exists())
        сам.assertEqual(сам.отчёт.read_bytes(), исходное)

    def test_повреждённая_история_не_перезаписывает_отчёт(сам):
        сам.каталог.mkdir(parents=True)
        (сам.каталог / "повреждено.json").write_text("{}\n")
        исходное = сам.отчёт.read_bytes()
        результат = сам.вызвать()
        сам.assertEqual(результат.returncode, 2)
        сам.assertTrue(json.loads(результат.stdout)["ошибки"])
        сам.assertEqual(сам.отчёт.read_bytes(), исходное)

    def test_закрытие_и_возобновление_не_обходятся(сам):
        сам.каталог.mkdir(parents=True)
        for имя in ("снимок.json", "возобновление.json"):
            with сам.subTest(имя=имя):
                путь = сам.каталог / имя
                путь.write_text("{}\n")
                исходное = сам.отчёт.read_bytes()
                результат = сам.вызвать()
                сам.assertEqual(результат.returncode, 2)
                сам.assertTrue(json.loads(результат.stdout)["ошибки"])
                сам.assertEqual(сам.отчёт.read_bytes(), исходное)
                путь.unlink()

    def test_потерянная_ссылка_не_исправляется_предпросмотром(сам):
        сам.отчёт.write_text(сам.отчёт.read_text().replace("[Исходный запрос](запрос.md).", "Источник утрачен."))
        результат = сам.вызвать(True)
        сам.assertEqual(результат.returncode, 1, результат.stdout + результат.stderr)
        сам.assertIn("Нет прямой ссылки", результат.stdout)


if __name__ == "__main__":
    unittest.main()
