#!/usr/bin/env python3
"""Парно запустить сохранённые release-тесты без сборки внутри замеров."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile


def выполнить(параметры):
    корень = Path(параметры.корень).resolve(strict=True)
    выход = Path(параметры.выход).resolve()
    if выход.exists():
        raise ValueError("Выход уже существует")
    связи = json.loads(Path(параметры.связь_сборок).read_bytes())
    сборки = {сторона: Path(getattr(параметры, сторона)).resolve(strict=True)
              for сторона in ("до", "после")}
    for сторона in ("до", "после"):
        ожидаемый = сборки[сторона] / "out/Products/Release/FUMStructuringOperatorMemoryTests.xctest/Contents/MacOS/FUMStructuringOperatorMemoryTests"
        объявленный = Path(связи[сторона]["исполняемый"]).resolve(strict=True)
        if объявленный != ожидаемый.resolve(strict=True):
            raise ValueError("Бинарник не совпадает с выбранной сборкой")
    хэши = {сторона: hashlib.sha256(Path(связи[сторона]["исполняемый"]).read_bytes()).hexdigest()
            for сторона in ("до", "после")}
    for сторона in ("до", "после"):
        if хэши[сторона] != связи[сторона]["sha256_исполняемого"]:
            raise ValueError("Сборка не совпадает со свидетельством")
    пары = []
    контроль = None
    with tempfile.TemporaryDirectory(prefix="fum-скаляры-пары-", dir=выход.parent) as временный:
        for номер in range(параметры.повторы):
            пара = {}
            for сторона in (["до", "после"] if номер % 2 == 0 else ["после", "до"]):
                файл = Path(временный) / (str(номер) + "-" + сторона + ".json")
                среда = os.environ.copy()
                среда["ФУМ_ВЫХОД_ПРОФИЛЯ_СКАЛЯРОВ"] = str(файл)
                команда = ["swift", "test", "--package-path", str(корень / "Прототипы/память-структурирующих-операторов"),
                           "--scratch-path", str(сборки[сторона]), "-c", "release", "--skip-build",
                           "--filter", "ПроверкиСкалярногоТекста.test_ПрофильСкалярногоТекста"]
                процесс = subprocess.run(команда, cwd=корень, env=среда, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                if процесс.returncode:
                    raise RuntimeError(процесс.stdout.decode("utf-8", "replace"))
                образец = json.loads(файл.read_bytes())
                ожидания = {"схема": "fum.профиль-скалярного-текста.1", "скаляров": 32768,
                            "байтов_входа": 131072, "байтов_выхода": 73728, "операций": 32769}
                if any(образец.get(поле) != значение for поле, значение in ожидания.items()):
                    raise ValueError("Неверный профиль или образец")
                ряды = образец.get("ряды")
                if not isinstance(ряды, list) or len(ряды) != 7:
                    raise ValueError("Нужны семь рядов")
                for ряд in ряды:
                    if set(ряд) != {"проверка", "исполнение", "трасса"} or any(
                        type(значение) is not int or значение < 0 for значение in ряд.values()):
                        raise ValueError("Неверные стадии или длительности")
                детерминированное = {поле: значение for поле, значение in образец.items() if поле != "ряды"}
                if контроль is None:
                    контроль = детерминированное
                elif контроль != детерминированное:
                    raise ValueError("Изменился результат между парами")
                пара[сторона] = образец
            поля = ["схема", "скаляров", "байтов_входа", "байтов_выхода", "операций", "хэш_наблюдения"]
            if any(пара["до"][поле] != пара["после"][поле] for поле in поля):
                raise ValueError("Разные детерминированные результаты")
            пары.append(пара)
    for сторона in ("до", "после"):
        if hashlib.sha256(Path(связи[сторона]["исполняемый"]).read_bytes()).hexdigest() != хэши[сторона]:
            raise ValueError("Исполняемый файл изменился в серии")
    сводка = {}
    for сторона in ("до", "после"):
        сводка[сторона] = {стадия: statistics.median(
            ряд[стадия] for пара in пары for ряд in пара[сторона]["ряды"])
            for стадия in пары[0][сторона]["ряды"][0]}
    документ = {"схема": "fum.парный-профиль-скалярного-текста.1", "пары": пары, "медианы_нс": сводка,
                 "связь_сборок": {сторона: {поле: значение for поле, значение in связи[сторона].items() if поле != "исполняемый"} for сторона in ("до", "после")},
                 "граница": "Внутренние стадии общего исполнителя; сборка, подготовка, XCTest и сравнение вне замера",
                 "sha256_профилировщика": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    if getattr(параметры, "предыдущий_профиль", None):
        прежние = Path(параметры.предыдущий_профиль).read_bytes()
        прежний = json.loads(прежние)
        if прежний.get("схема") != "fum.парный-профиль-скалярного-текста.1":
            raise ValueError("Неизвестная предыдущая серия")
        документ["предыдущая_серия"] = прежний
        документ["sha256_предыдущей_серии"] = hashlib.sha256(прежние).hexdigest()
    with выход.open("x", encoding="utf-8") as файл:
        json.dump(документ, файл, ensure_ascii=False, indent=2, sort_keys=True)
        файл.write("\n")
    print(json.dumps({"пары": len(пары), "медианы_нс": сводка}, ensure_ascii=False))


def проверить_связь():
    """Несовпадающая карта не должна доходить до внешнего Swift-процесса."""
    from unittest.mock import patch

    with tempfile.TemporaryDirectory(prefix="fum-проверка-связи-") as временный:
        корень = Path(временный).resolve()
        связи = {}
        for сторона in ("до", "после"):
            исполняемый = корень / сторона / "out/Products/Release/FUMStructuringOperatorMemoryTests.xctest/Contents/MacOS/FUMStructuringOperatorMemoryTests"
            исполняемый.parent.mkdir(parents=True)
            исполняемый.write_bytes(сторона.encode())
            связи[сторона] = {"исполняемый": str(исполняемый),
                              "sha256_исполняемого": hashlib.sha256(исполняемый.read_bytes()).hexdigest()}
        карта = корень / "карта.json"
        карта.write_text(json.dumps(связи))
        параметры = argparse.Namespace(корень=str(корень), до=str(корень / "после"),
                                       после=str(корень / "после"), выход=str(корень / "результат.json"),
                                       связь_сборок=str(карта), повторы=5)
        with patch.object(subprocess, "run", side_effect=AssertionError("Недопустимый внешний запуск")) as запуск:
            try:
                выполнить(параметры)
            except ValueError as ошибка:
                if "не совпадает с выбранной сборкой" not in str(ошибка):
                    raise
            else:
                raise AssertionError("Несовпадающая карта принята")
            запуск.assert_not_called()
        if Path(параметры.выход).exists():
            raise AssertionError("Отказ создал результат")
    print("Связь бинарника и scratch: неверная карта отклонена до запуска")


if __name__ == "__main__":
    if sys.argv[1:] == ["--проверить-связь"]:
        проверить_связь()
        sys.exit(0)
    разбор = argparse.ArgumentParser(description=__doc__)
    for имя in ("корень", "до", "после", "выход", "связь-сборок"):
        разбор.add_argument("--" + имя, required=True)
    разбор.add_argument("--повторы", type=int, default=5)
    разбор.add_argument("--предыдущий-профиль")
    параметры = разбор.parse_args()
    if параметры.повторы < 5:
        разбор.error("Нужно не менее пяти пар")
    выполнить(параметры)
