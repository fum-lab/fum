import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

from test_братиславская_проекция_памяти import модуль


class ПроверкаСборкиПреобразователя(unittest.TestCase):
    def test_одна_релизная_сборка_и_два_независимых_преобразования(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            пакет = корень / "пакет"
            сборка = корень / "сборка"
            каталог = сборка / "архитектура" / "release"
            каталог.mkdir(parents=True)
            продукт = каталог / "preobrazovatj-nazvaniya"
            продукт.write_text(
                "#!" + sys.executable + "\n"
                "import json,sys\n"
                "print(json.dumps(json.load(sys.stdin),ensure_ascii=False))\n",
                encoding="utf-8",
            )
            продукт.chmod(0o755)
            граница = mock.Mock()
            поток = io.StringIO()
            with mock.patch.object(
                модуль.subprocess, "run",
                side_effect=[
                    subprocess.CompletedProcess([], 0, "сборка\n", ""),
                    subprocess.CompletedProcess([], 0, str(каталог) + "\n", ""),
                ],
            ) as запуск, mock.patch.object(модуль.sys, "stderr", поток), модуль.сеанс_профилирования(True):
                команда = модуль.собрать_изолированный_продукт(пакет, сборка, граница)
            сам.assertEqual(команда, [str(продукт.resolve())])
            сам.assertEqual(запуск.call_count, 2)
            for вызов in запуск.call_args_list:
                аргументы = вызов.args[0]
                сам.assertEqual(аргументы[:2], ["swift", "build"])
                сам.assertEqual(аргументы[аргументы.index("--configuration") + 1], "release")
                сам.assertEqual(аргументы[аргументы.index("--scratch-path") + 1], str(сборка))
            сам.assertIn("--product", запуск.call_args_list[0].args[0])
            сам.assertIn("--show-bin-path", запуск.call_args_list[1].args[0])
            сам.assertEqual(граница.call_count, 2)
            метки = [json.loads(строка.removeprefix("FUM-PROFILE "))
                     for строка in поток.getvalue().splitlines()]
            сам.assertEqual(
                {запись["метка"] for запись in метки},
                {"сборка Swift Release", "определение каталога продукта Swift"},
            )
            преобразовать = модуль.преобразователь_процесса(команда, граница)
            сам.assertEqual(преобразовать(["ё Ж"]), ["ё Ж"])
            сам.assertEqual(преобразовать(["другой вход"]), ["другой вход"])
            сам.assertEqual(граница.call_count, 6)

    def test_отказ_сборки_сохраняет_проверку_границы(сам):
        граница = mock.Mock()
        with mock.patch.object(модуль.subprocess, "run",
                               side_effect=subprocess.CalledProcessError(1, [], stderr="ошибка компиляции")) as запуск:
            with сам.assertRaisesRegex(модуль.ОшибкаКонтракта, "ошибка компиляции"):
                модуль.собрать_изолированный_продукт(Path("пакет"), Path("сборка"), граница)
        сам.assertEqual(граница.call_count, 2)
        сам.assertEqual(запуск.call_count, 1)

    def test_изменение_границы_при_сборке_не_выдаёт_продукт(сам):
        граница = mock.Mock(side_effect=[None, модуль.ОшибкаКонтракта("дрейф исходников")])
        with tempfile.TemporaryDirectory() as временный:
            with mock.patch.object(модуль.subprocess, "run",
                                   return_value=subprocess.CompletedProcess([], 0, временный + "\n", "")):
                with сам.assertRaisesRegex(модуль.ОшибкаКонтракта, "дрейф исходников"):
                    модуль.собрать_изолированный_продукт(Path(временный), Path(временный), граница)

    def test_непригодный_или_внешний_продукт_отклоняется(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сборка = корень / "сборка"
            сборка.mkdir()
            внешний = корень / "внешний"
            внешний.mkdir()
            for случай in ("нет", "каталог", "неисполняемый", "ссылка", "внешний"):
                with сам.subTest(случай=случай):
                    каталог = (внешний if случай == "внешний" else сборка) / случай
                    каталог.mkdir()
                    продукт = каталог / "preobrazovatj-nazvaniya"
                    if случай == "каталог":
                        продукт.mkdir()
                    elif случай == "ссылка":
                        продукт.symlink_to(sys.executable)
                    elif случай != "нет":
                        продукт.write_text("данные", encoding="utf-8")
                        продукт.chmod(0o755 if случай == "внешний" else 0o644)
                    with mock.patch.object(модуль.subprocess, "run",
                                           return_value=subprocess.CompletedProcess([], 0, str(каталог) + "\n", "")):
                        with сам.assertRaises(модуль.ОшибкаКонтракта):
                            модуль.собрать_изолированный_продукт(корень, сборка, lambda: None)
