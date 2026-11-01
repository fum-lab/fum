#!/usr/bin/env python3
"""Проверить отказы помощника при оптимизации Python и миграцию формата .2."""
from __future__ import annotations

import argparse
import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock


ПУТЬ_ПОМОЩНИКА = Path(__file__).with_name("проверить-корень-пакета.py")
КОРЕНЬ = Path(__file__).resolve().parents[5]


def загрузить(путь: Path):
    описание = importlib.util.spec_from_file_location("проверка_корня", путь)
    модуль = importlib.util.module_from_spec(описание)
    описание.loader.exec_module(модуль)
    return модуль


def данные_пакета(корень: Path, эталон: bool = True) -> dict:
    зависимости = [корень / "Прототипы/память-структурирующих-операторов"]
    продукты = ["FUMStructuringOperatorMemory"]
    if эталон:
        зависимости.append(корень / "Зависимости/LinguisticKit")
        продукты.append("LinguisticKit.static")
    return {
        "name": "ПроверкаТранслитерации",
        "dependencies": [{"fileSystem": [{"path": str(путь)}]} for путь in зависимости],
        "targets": [{
            "dependencies": [{"product": [имя]} for имя in продукты],
            "settings": ([{"kind": {"define": {"_0": "LINGUISTICKIT_ORACLE"}}}]
                         if эталон else []),
        }],
    }


class ПроверкиКонтрактов(unittest.TestCase):
    def setUp(сам):
        сам.модуль = загрузить(ПУТЬ_ПОМОЩНИКА)
        временный_корень = Path(tempfile.gettempdir()).resolve()
        if any((предок / ".git").exists() for предок in (временный_корень, *временный_корень.parents)):
            raise ValueError("Системный временный каталог должен находиться вне Git")
        сам.временный = tempfile.TemporaryDirectory(
            prefix="лингвистика-проверки-", dir=временный_корень)
        сам.addCleanup(сам.временный.cleanup)
        сам.каталог = Path(сам.временный.name)
        сам.корень = Path("корень-фикстуры")

    def test_положительный_пакет(сам):
        for эталон in (False, True):
            with сам.subTest(эталон=эталон):
                сам.assertIsNone(сам.модуль.проверить_пакет(
                    данные_пакета(сам.корень, эталон), сам.корень, эталон))

    def test_нет_разобранных_данных(сам):
        with сам.assertRaisesRegex(AssertionError, "не разобран"):
            сам.модуль.проверить_пакет(None, сам.корень, True)

    def test_ровно_одна_порча_пакета(сам):
        for вид in ("путь", "продукт", "определение"):
            данные = данные_пакета(сам.корень)
            if вид == "путь":
                данные["dependencies"][0]["fileSystem"][0]["path"] = "посторонняя-память"
            elif вид == "продукт":
                данные["targets"][0]["dependencies"][0]["product"][0] = "ПостороннийПродукт"
            else:
                данные["targets"][0]["settings"][0]["kind"]["define"]["_0"] = "НЕВЕРНО"
            with сам.subTest(вид=вид), сам.assertRaises(AssertionError):
                сам.модуль.проверить_пакет(данные, сам.корень, True)

    def выполнить_матрицу(сам, повреждения=None):
        номер = 0

        def выполнить(пакет, рабочий_каталог, каталог, компилятор, индекс):
            nonlocal номер
            номер += 1
            наблюдение = {"код": 0, "наносекунды": 1, "маркер_корня": False}
            if индекс < 4:
                корень = пакет.parents[4]
                эталон = ((КОРЕНЬ / "Зависимости/LinguisticKit/Package.swift").is_file()
                          if индекс < 2 else индекс == 3)
                return данные_пакета(корень, эталон), наблюдение
            наблюдение.update({"код": 1, "маркер_корня": индекс < 9})
            наблюдение.update((повреждения or {}).get(индекс, {}))
            return None, наблюдение

        каталог = сам.каталог / str(time.perf_counter_ns())
        каталог.mkdir()
        with mock.patch.object(сам.модуль, "выполнить", side_effect=выполнить):
            результат = сам.модуль.проверить(КОРЕНЬ, каталог, "компилятор-фикстуры")
        сам.assertEqual(номер, 10)
        return результат

    def test_оба_условия_каждого_отрицательного_случая(сам):
        сам.assertEqual(сам.выполнить_матрицу()["ошибки"], [])
        for номер in range(4, 9):
            for код, маркер in ((0, True), (1, False)):
                with сам.subTest(номер=номер, код=код, маркер=маркер):
                    результат = сам.выполнить_матрицу({номер: {"код": код, "маркер_корня": маркер}})
                    сам.assertEqual(len(результат["ошибки"]), 1)

    def test_отсутствующий_каталог_не_принимает_нулевой_код(сам):
        результат = сам.выполнить_матрицу({9: {"код": 0}})
        сам.assertEqual(len(результат["ошибки"]), 1)

    def выполнить_профиль(сам, различать=False):
        номер = 0

        def выполнить(пакет, рабочий_каталог, каталог, компилятор, индекс):
            nonlocal номер
            номер += 1
            данные = данные_пакета(пакет.parents[4])
            if различать and индекс == 1:
                данные["name"] = "ДругоеИмя"
            return данные, {"код": 0, "наносекунды": 1, "маркер_корня": False}

        каталог = сам.каталог / str(time.perf_counter_ns())
        каталог.mkdir()
        with mock.patch.object(сам.модуль, "выполнить", side_effect=выполнить), \
                mock.patch.object(subprocess, "check_output", return_value="версия-фикстуры"):
            результат = сам.модуль.профиль(
                КОРЕНЬ, каталог, "компилятор-фикстуры", ПУТЬ_ПОМОЩНИКА.with_name("Package.swift"))
        сам.assertEqual(номер, 14)
        return результат

    def test_профиль_различает_полные_данные(сам):
        with сам.assertRaisesRegex(AssertionError, "изменился"):
            сам.выполнить_профиль(различать=True)

    def test_две_схемы_и_собственные_имена(сам):
        проверка = сам.выполнить_матрицу()
        сам.assertEqual(проверка["схема"], "fum.проверка-корня-лингвистики.2")
        сам.assertEqual(set(проверка), {"схема", "хэш_манифеста", "случаи", "ошибки"})
        for случай in проверка["случаи"]:
            сам.assertNotRegex(случай["случай"], r"[A-Za-z]")
        профиль = сам.выполнить_профиль()
        сам.assertEqual(профиль["схема"], "fum.профиль-корня-лингвистики.2")
        сам.assertEqual(set(профиль), {
            "схема", "версия_компилятора", "вход", "аргументы_одинаковы",
            "рабочий_каталог_одинаков", "разобранные_данные_равны",
            "хэши_манифестов", "замеры", "медианы_наносекунды"})

    def test_точные_потоки_и_канонизация(сам):
        ошибки = b"\xff\xfe" + "FUM: неверный корень пакета".encode()
        ожидаемый_хэш = hashlib.sha256('{"а":"ё","б":2}'.encode()).hexdigest()
        for данные, отступ in (({"б": 2, "а": "ё"}, None), ({"а": "ё", "б": 2}, 2)):
            вывод = json.dumps(данные, ensure_ascii=False, indent=отступ).encode()
            процесс = subprocess.CompletedProcess([], 0, stdout=вывод, stderr=ошибки)
            with mock.patch.object(subprocess, "run", return_value=процесс):
                получено, наблюдение = сам.модуль.выполнить(
                    сам.корень, сам.корень, сам.каталог, "компилятор-фикстуры", 0)
            сам.assertEqual(получено, данные)
            сам.assertEqual(наблюдение["хэш_стандартного_вывода"], hashlib.sha256(вывод).hexdigest())
            сам.assertEqual(наблюдение["хэш_стандартных_ошибок"], hashlib.sha256(ошибки).hexdigest())
            сам.assertEqual((сам.каталог / "0.stderr").read_bytes(), ошибки)
            сам.assertEqual(наблюдение["хэш_канонических_данных"], ожидаемый_хэш)

    def test_оба_написания_флага(сам):
        for номер, флаг in enumerate(("--компилятор", "--компилятор-swift")):
            выход = сам.каталог / f"результат-{номер}.json"
            команда = [str(ПУТЬ_ПОМОЩНИКА), "проверить", "--корень-репозитория", str(КОРЕНЬ),
                       "--каталог-работы", str(сам.каталог / f"работа-{номер}"),
                       флаг, "один-компилятор", "--выход", str(выход)]
            with сам.subTest(флаг=флаг), mock.patch.object(sys, "argv", команда), \
                    mock.patch.object(сам.модуль, "проверить", return_value={
                        "схема": "fum.проверка-корня-лингвистики.2", "ошибки": []}) as проверка, \
                    contextlib.redirect_stdout(io.StringIO()) as поток:
                сам.assertEqual(сам.модуль.главная(), 0)
                сам.assertEqual(проверка.call_args.args[2], "один-компилятор")
                итог = json.loads(поток.getvalue())
                сам.assertEqual(итог["хэш_результата"], hashlib.sha256(выход.read_bytes()).hexdigest())


def профиль_проверки(исходный: Path, выход: Path, повторов: int) -> None:
    if sys.flags.optimize != 0 or повторов < 1:
        raise ValueError("Для парного профиля нужны оптимизация 0 и положительное число повторов")
    версии = {"до": загрузить(исходный), "после": загрузить(ПУТЬ_ПОМОЩНИКА)}
    корень = Path("корень-фикстуры")
    данные = данные_пакета(корень)
    исходные = json.dumps(данные, ensure_ascii=False, sort_keys=True).encode()
    записи = []
    порядок = [(имя, True) for имя in версии]
    порядок += [(имя, False) for номер in range(6)
                for имя in (("до", "после") if номер % 2 == 0 else ("после", "до"))]
    for имя, прогрев in порядок:
        функция = версии[имя].проверить_пакет
        начало = time.perf_counter_ns()
        for номер in range(повторов):
            результат = функция(данные, корень, True)
            if результат is not None:
                raise ValueError("Проверка изменила результат")
        записи.append({"версия": имя, "прогрев": прогрев,
                       "наносекунды": time.perf_counter_ns() - начало})
    конечные = json.dumps(данные, ensure_ascii=False, sort_keys=True).encode()
    if исходные != конечные:
        raise ValueError("Профиль изменил вход")
    итог = {
        "схема": "fum.профиль-контракта-проверок-лингвистики.1",
        "граница": "Реальная проверить_пакет двух версий; импорт вне замера, без запуска SwiftPM",
        "интерпретатор": sys.version, "платформа": platform.platform(),
        "уровень_оптимизации": sys.flags.optimize, "вызовов_в_замере": повторов,
        "процесс_один": True, "команда_одна": True, "рабочий_каталог_один": True,
        "результат": "None", "хэш_входа_до": hashlib.sha256(исходные).hexdigest(),
        "хэш_входа_после": hashlib.sha256(конечные).hexdigest(),
        "хэши_исходников": {"до": hashlib.sha256(исходный.read_bytes()).hexdigest(),
                             "после": hashlib.sha256(ПУТЬ_ПОМОЩНИКА.read_bytes()).hexdigest()},
        "хэш_сценария": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "замеры": записи,
        "медианы_наносекунды": {имя: statistics.median(
            запись["наносекунды"] for запись in записи
            if запись["версия"] == имя and not запись["прогрев"]) for имя in версии},
    }
    выход.write_text(json.dumps(итог, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"хэш_результата": hashlib.sha256(выход.read_bytes()).hexdigest()}, ensure_ascii=False))


if __name__ == "__main__":
    if sys.argv[1:2] == ["профиль"]:
        разбор = argparse.ArgumentParser(description=__doc__)
        разбор.add_argument("режим", choices=("профиль",))
        разбор.add_argument("--исходный-помощник", type=Path, required=True)
        разбор.add_argument("--выход", type=Path, required=True)
        разбор.add_argument("--повторов", type=int, default=10000)
        аргументы = разбор.parse_args()
        профиль_проверки(аргументы.исходный_помощник, аргументы.выход, аргументы.повторов)
    else:
        unittest.main()
