#!/usr/bin/env python3
"""Собрать Release и сохранить сравнение вместе с точным происхождением."""

import argparse
import hashlib
import json
from pathlib import Path
import platform
import subprocess
import time


def выполнить(аргументы, каталог):
    return subprocess.run(аргументы, cwd=каталог, check=True, capture_output=True, text=True)


def хэш(путь):
    return hashlib.sha256(путь.read_bytes()).hexdigest()


def исходники(прототип):
    пути = [прототип / "Package.swift", Path(__file__).resolve()]
    for каталог in ("Sources", "Tests"):
        пути.extend(путь for путь in (прототип / каталог).rglob("*") if путь.is_file())
    return {str(путь.relative_to(прототип)): хэш(путь) for путь in sorted(пути)}


def сохранить(путь, значение):
    путь.parent.mkdir(parents=True, exist_ok=True)
    путь.write_text(json.dumps(значение, ensure_ascii=False, indent=2) + "\n")


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("режим", choices=("подготовить", "проверить", "измерить"))
    разбор.add_argument("--каталог-сборки", type=Path, required=True)
    разбор.add_argument("--вывод", type=Path)
    параметры = разбор.parse_args()
    прототип = Path(__file__).resolve().parents[1]
    корень = прототип.parents[1]
    сборка = параметры.каталог_сборки.resolve()
    if сборка.is_relative_to(корень):
        разбор.error("Каталог сборки должен находиться вне checkout FUM")
    команда = ["swift", "build", "--package-path", str(прототип), "--scratch-path", str(сборка),
               "--configuration", "release", "--product", "СравнениеДекодирования"]
    квитанция = сборка / "происхождение-сборки.json"
    снимок = исходники(прототип)
    if параметры.режим == "подготовить":
        начало = time.perf_counter_ns()
        процесс = выполнить(команда, корень)
        длительность = time.perf_counter_ns() - начало
        print(процесс.stdout, end="")
        print(процесс.stderr, end="")
        каталог = Path(выполнить(команда + ["--show-bin-path"], корень).stdout.strip())
        бинарник = каталог / "СравнениеДекодирования"
        if снимок != исходники(прототип):
            raise RuntimeError("Исходники изменились во время сборки")
        версия = выполнить(["swift", "--version"], корень)
        данные = {"схема": "fum.сборка-сравнения-декодирования.1", "исходники": снимок,
                  "хэшБинарника": хэш(бинарник), "сборкаНс": длительность,
                  "версияSwift": (версия.stdout + версия.stderr).strip(),
                  "версияPython": platform.python_version(), "архитектура": platform.machine(),
                  "команда": "swift build --package-path <прототип> --scratch-path <вне-checkout> --configuration release --product СравнениеДекодирования"}
        сохранить(квитанция, данные)
        print("Сборка Release и происхождение сохранены")
        return
    if параметры.вывод is None:
        разбор.error("Для проверки или измерения нужен --вывод")
    происхождение = json.loads(квитанция.read_text())
    каталог = Path(выполнить(команда + ["--show-bin-path"], корень).stdout.strip())
    бинарник = каталог / "СравнениеДекодирования"
    if происхождение["исходники"] != снимок or происхождение["хэшБинарника"] != хэш(бинарник):
        raise RuntimeError("Сборка устарела; сначала подготовить")
    процессор = выполнить(["sysctl", "-n", "machdep.cpu.brand_string"], корень).stdout.strip()
    начало = time.perf_counter_ns()
    процесс = выполнить([str(бинарник), параметры.режим], корень)
    время = time.perf_counter_ns() - начало
    if снимок != исходники(прототип) or происхождение["хэшБинарника"] != хэш(бинарник):
        raise RuntimeError("Исходники или бинарник изменились во время выполнения")
    данные = json.loads(процесс.stdout)
    assert данные["схема"] == "fum.сравнение-декодирования.1"
    assert len(данные["положительные"]) == 46 and len(данные["ошибочные"]) == 14
    assert len(данные["наблюдения"]) == (432 if параметры.режим == "измерить" else 0)
    данные["происхождение"] = происхождение
    данные["процессор"] = процессор
    данные["процессВсегоНс"] = время
    данные["нагрузка"] = "Обычный пользовательский процесс без привязки к ядру. Конкурирующие задачи и согласованное окно фиксируются отдельно в отчёте. Частота CPU не закреплялась."
    сохранить(параметры.вывод, данные)
    print(f"Сохранено: положительных {len(данные['положительные'])}, ошибочных {len(данные['ошибочные'])}, пакетов {len(данные['наблюдения'])}")


if __name__ == "__main__":
    главная()
