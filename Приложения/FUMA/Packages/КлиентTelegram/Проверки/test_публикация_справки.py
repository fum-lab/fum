import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


описание = importlib.util.spec_from_file_location("публикационная_справка", Path(__file__).with_name("проверить-публикацию-справки.py"))
исполнитель = importlib.util.module_from_spec(описание)
описание.loader.exec_module(исполнитель)

СПРАВКА = """Автономная проверка TDLib без аккаунта:
проверить-telegram --библиотека <абсолютный-путь-к-библиотеке> [--простой-секунд 1..30]
проверить-telegram --профиль поток [--кадров 1..2048]
проверить-telegram --профиль отмена [--повторов 1..100]
проверить-telegram --сквозной-хвост подготовить|восстановить --каталог <приватный-каталог>
проверить-telegram --профиль-восстановления подготовить|восстановить --каталог <приватный-каталог> --попыток 16|256
Пути библиотеки и приватного каталога должны быть абсолютными.
""".encode()


class ПроверкиПубликацииСправки(unittest.TestCase):
    def вызвать(сам, ответы):
        with tempfile.TemporaryDirectory() as каталог:
            команда = Path(каталог) / "синтетическая-команда"
            команда.write_bytes(b"fixture")
            вывод, диагностика = io.StringIO(), io.StringIO()
            with patch.object(исполнитель.subprocess, "run", side_effect=ответы), contextlib.redirect_stdout(вывод), contextlib.redirect_stderr(диагностика):
                код = исполнитель.проверить(команда)
            return код, json.loads(вывод.getvalue()), диагностика.getvalue()

    def test_пустой_и_посторонний_вывод_не_являются_справкой(сам):
        for текст in (b"", b"ok"):
            with сам.subTest(текст=текст):
                код, отчёт, _ = сам.вызвать([subprocess.CompletedProcess([], 0, текст, b"")] * 5)
                сам.assertEqual(код, 2)
                сам.assertEqual(отчёт["ошибка"]["вид"], "неполная_справка")

    def test_отказ_процесса_сохраняет_длительность_и_диагностику(сам):
        код, отчёт, диагностика = сам.вызвать([subprocess.CompletedProcess([], 7, "частичный вывод".encode(), "причина отказа".encode())])
        сам.assertEqual(код, 2)
        сам.assertEqual(отчёт["ошибка"]["номерЗапуска"], 1)
        сам.assertEqual(отчёт["ошибка"]["кодПроцесса"], 7)
        сам.assertGreaterEqual(отчёт["ошибка"]["длительностьНаносекунд"], 0)
        сам.assertIn("частичный вывод", диагностика)
        сам.assertIn("причина отказа", диагностика)

    def test_тайм_аут_сохраняет_предыдущий_успех_и_байты(сам):
        код, отчёт, диагностика = сам.вызвать([
            subprocess.CompletedProcess([], 0, СПРАВКА, b""),
            subprocess.TimeoutExpired([], 5, output="частичный вывод".encode(), stderr="причина отказа".encode()),
        ])
        сам.assertEqual(код, 2)
        сам.assertEqual(отчёт["запусков"], 1)
        сам.assertEqual(len(отчёт["длительностиНаносекунд"]), 1)
        сам.assertEqual(отчёт["ошибка"]["номерЗапуска"], 2)
        сам.assertEqual(отчёт["ошибка"]["вид"], "тайм_аут")
        сам.assertIn("частичный вывод", диагностика)
        сам.assertIn("причина отказа", диагностика)

    def test_неизменная_полная_справка_имеет_происхождение(сам):
        код, отчёт, диагностика = сам.вызвать([subprocess.CompletedProcess([], 0, СПРАВКА, b"")] * 5)
        сам.assertEqual(код, 0)
        сам.assertEqual(отчёт["схема"], "fum.публикация-справки-телеграма.2")
        сам.assertEqual(отчёт["запусков"], 5)
        сам.assertEqual(отчёт["машинныхПутей"], 0)
        сам.assertIsNone(отчёт["ошибка"])
        сам.assertEqual(диагностика, "")
        for поле in ("исполнительШа256", "распознавательШа256"):
            сам.assertRegex(отчёт[поле], "^[0-9a-f]{64}$")


if __name__ == "__main__":
    unittest.main()
