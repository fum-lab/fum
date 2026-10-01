import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import sys
import tarfile
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock


корень_зеркал = Path(__file__).resolve().parents[1]
путь_проектора = корень_зеркал / "Кандидат/Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py"
спецификация = importlib.util.spec_from_file_location("проектор_источник_обёртки", путь_проектора)
модуль = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = модуль
спецификация.loader.exec_module(модуль)
путь_зеркал = "Приложения/FUMA/Packages/ЛокальныйТоррент/Инструменты/Зеркала"
путь_пакета = "Инструменты/fum-proverka-nazvanij-avtomatizacij"
манифест = json.loads((корень_зеркал / "манифест-исходного-зеркала.json").read_text())
записи_пакета = [запись for запись in манифест["файлы"]
    if запись["исходный_путь"].startswith(путь_пакета + "/")]


class ТестыИсточникаЗеркальнойОбёртки(unittest.TestCase):
    def подготовить(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        сам.зеркала = сам.корень / путь_зеркал
        сам.зеркала.mkdir(parents=True)
        shutil.copyfile(корень_зеркал / "манифест-исходного-зеркала.json",
            сам.зеркала / "манифест-исходного-зеркала.json")
        for запись in записи_пакета:
            цель = сам.корень / запись["путь_зеркала"]
            цель.parent.mkdir(parents=True, exist_ok=True)
            источник = корень_зеркал.parents[5] / запись["путь_зеркала"]
            shutil.copyfile(источник, цель)
            цель.chmod(0o644)
        сам.пакет = (сам.корень / записи_пакета[0]["путь_зеркала"]).parent
        if сам.пакет.name != "fum-proverka-nazvanij-avtomatizacij":
            сам.пакет = сам.пакет.parents[1]

    def test_ВыбираетДваФайлаИСтроитДетерминированныйАрхив(сам):
        сам.подготовить()
        архив, сведения = модуль.архив_зеркальной_обёртки(сам.корень)
        повтор, повторные = модуль.архив_зеркальной_обёртки(сам.корень)
        сам.assertEqual((архив, сведения), (повтор, повторные))
        сам.assertRegex(сведения["дерево_обёртки"], r"^[0-9a-f]{40}$")
        сам.assertEqual(сведения["источник_обёртки"]["исходный_коммит"], манифест["исходный_коммит"])
        with tarfile.open(fileobj=io.BytesIO(архив)) as поток:
            сам.assertEqual({элемент.name for элемент in поток},
                {запись["исходный_путь"] for запись in записи_пакета})
            for элемент in поток.getmembers():
                сам.assertTrue(элемент.isfile())
                сам.assertEqual((элемент.mode, элемент.uid, элемент.gid, элемент.mtime), (0o644, 0, 0, 0))
                запись = next(запись for запись in записи_пакета if запись["исходный_путь"] == элемент.name)
                сам.assertEqual(поток.extractfile(элемент).read(),
                    (сам.корень / запись["путь_зеркала"]).read_bytes())

    def test_НеЧитаетИзменённуюКаноническуюОбёртку(сам):
        сам.подготовить()
        обычный = сам.корень / путь_пакета
        обычный.mkdir(parents=True)
        (обычный / "Package.swift").write_text("чужая обёртка")
        with mock.patch.object(модуль, "выполнить_команду_контроля_версий",
                side_effect=AssertionError("Выбор зеркала не должен читать HEAD")):
            архив, сведения = модуль.архив_зеркальной_обёртки(сам.корень)
        сам.assertNotIn(b"HEAD", архив)
        сам.assertEqual(сведения["источник_обёртки"]["исходный_путь"], путь_пакета)

    def test_ОтклоняетДополнительныйФайлИПустойКаталог(сам):
        сам.подготовить()
        for имя, каталог in (("лишний.swift", False), ("пустой", True)):
            with сам.subTest(имя=имя):
                лишний = сам.пакет / имя
                лишний.mkdir() if каталог else лишний.write_text("")
                try:
                    with сам.assertRaises(модуль.ОшибкаКонтракта):
                        модуль.архив_зеркальной_обёртки(сам.корень)
                finally:
                    лишний.rmdir() if каталог else лишний.unlink()

    def test_ОтклоняетПовреждениеБайтовИРежима(сам):
        сам.подготовить()
        файл = сам.пакет / "Package.swift"
        байты = файл.read_bytes()
        файл.write_bytes(байты + b"\n")
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.архив_зеркальной_обёртки(сам.корень)
        файл.write_bytes(байты)
        файл.chmod(0o755)
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.архив_зеркальной_обёртки(сам.корень)

    def test_ОтклоняетПовреждённыйМанифест(сам):
        сам.подготовить()
        (сам.зеркала / "манифест-исходного-зеркала.json").write_text("{}")
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.архив_зеркальной_обёртки(сам.корень)

    def test_ОтклоняетСсылкиИОтсутствующийФайл(сам):
        сам.подготовить()
        файл = сам.пакет / "Package.swift"
        байты = файл.read_bytes()
        файл.unlink()
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.архив_зеркальной_обёртки(сам.корень)
        цель = сам.корень / "внешний.swift"
        цель.write_bytes(байты)
        файл.symlink_to(цель)
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.архив_зеркальной_обёртки(сам.корень)
        файл.unlink()
        файл.write_bytes(байты)
        исходники = сам.пакет / "Sources"
        перенесённые = сам.корень / "перенесённые"
        исходники.rename(перенесённые)
        исходники.symlink_to(перенесённые, target_is_directory=True)
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.архив_зеркальной_обёртки(сам.корень)

    def test_ОтклоняетЗаменуФайлаВоВремяЧтения(сам):
        сам.подготовить()
        файл = сам.пакет / "Package.swift"
        чтение = модуль.os.read
        заменён = False
        def прочитать(дескриптор, число):
            nonlocal заменён
            данные = чтение(дескриптор, число)
            if данные and not заменён and данные == файл.read_bytes():
                заменён = True
                подмена = файл.with_name("подмена.swift")
                подмена.write_bytes(данные)
                os.replace(подмена, файл)
            return данные
        with mock.patch.object(модуль.os, "read", side_effect=прочитать):
            with сам.assertRaises(модуль.ОшибкаКонтракта):
                модуль.архив_зеркальной_обёртки(сам.корень)
        сам.assertTrue(заменён)

    def test_ПовторноПроверяетЗеркалоПослеТелаКонтекста(сам):
        сам.подготовить()
        буфер = io.BytesIO()
        with tarfile.open(fileobj=буфер, mode="w"):
            pass
        def команда(корень, *аргументы, **именованные):
            if аргументы == ("rev-parse", "HEAD"):
                return манифест["исходный_коммит"]
            if аргументы == ("archive", "--format=tar", модуль.РЕВИЗИЯ_ЗАВИСИМОСТИ):
                return буфер.getvalue()
            raise AssertionError("Неожиданное чтение Git: " + repr(аргументы))
        with mock.patch.object(модуль, "проверить_материализацию_зависимости"), \
                mock.patch.object(модуль, "прочитать_закреплённое_дерево_зависимости", return_value={}), \
                mock.patch.object(модуль, "проверить_файлы_по_дереву_зависимости"), \
                mock.patch.object(модуль, "выполнить_команду_контроля_версий", side_effect=команда):
            with сам.assertRaises(модуль.ОшибкаКонтракта):
                with модуль.подготовить_изолированный_преобразователь(сам.корень) as (вход, проверка):
                    сам.assertIn("--package-path", вход)
                    проверка()
                    файл = сам.пакет / "Package.swift"
                    файл.write_bytes(файл.read_bytes() + b" ")

    def test_КлючКешаСвязанСИсточникомЗеркала(сам):
        сам.подготовить()
        инструмент = сам.корень / "компилятор"
        инструмент.write_bytes(b"toolchain fixture")
        набор = сам.корень / "набор"
        набор.mkdir()
        def прочитать(команда, **именованные):
            if команда[0] == "xcrun" and "--find" in команда:
                return SimpleNamespace(stdout=str(инструмент))
            if "--show-sdk-path" in команда:
                return SimpleNamespace(stdout=str(набор))
            return SimpleNamespace(stdout="закреплённый инструмент")
        def гит(корень, *аргументы, **именованные):
            сам.assertEqual(аргументы, ("rev-parse", модуль.РЕВИЗИЯ_ЗАВИСИМОСТИ + "^{tree}"))
            return "0" * 40
        with mock.patch.object(модуль.subprocess, "run", side_effect=прочитать), \
                mock.patch.object(модуль, "выполнить_команду_контроля_версий", side_effect=гит):
            сведения, _ = модуль.сведения_для_повторной_сборки(сам.корень, "1" * 40, {})
        сам.assertEqual(сведения["источник_обёртки"]["хэш_манифеста"], модуль.хэш_манифеста_зеркала)
        сам.assertEqual(сведения["дерево_обёртки"],
            модуль.архив_зеркальной_обёртки(сам.корень)[1]["дерево_обёртки"])


if __name__ == "__main__":
    unittest.main()
