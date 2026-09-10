"""Сравнить две версии адаптера на одной открытой синтетической Git-фикстуре."""
from __future__ import annotations
import argparse
import hashlib
import importlib.util
import json
import statistics
import subprocess
import sys
import time
from pathlib import Path
from unittest import mock


def загрузить(имя, путь):
    спецификация = importlib.util.spec_from_file_location(имя, путь)
    модуль = importlib.util.module_from_spec(спецификация)
    спецификация.loader.exec_module(модуль)
    return модуль


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, default=Path.cwd())
    разбор.add_argument("--результат", type=Path, required=True)
    разбор.add_argument("--повторов", type=int, default=7)
    параметры = разбор.parse_args()
    if параметры.повторов < 1:
        разбор.error("число повторов должно быть положительным")
    инструмент = параметры.корень_репозитория.resolve() / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok"
    sys.path[:0] = [str(инструмент / "tests"), str(инструмент / "scripts")]
    import test_свидетельство_слияния as фикстуры
    пути = {"до": Path(__file__).with_name("адаптер-до-оптимизации.py"),
            "после": инструмент / "scripts/связь_отпечатка_с_коммитом.py"}
    модули = {имя: загрузить("адаптер_" + имя, путь) for имя, путь in пути.items()}
    фикстура = фикстуры.ТестыСвидетельстваСлияния()
    начало_подготовки = time.perf_counter_ns()
    фикстура.setUp()
    подготовка = time.perf_counter_ns() - начало_подготовки
    try:
        вход = dict(корень_репозитория=фикстура.корень, сессия=str(Path(фикстуры.путь_запроса).parent),
                    коммит=фикстура.коммит, база=фикстура.база, присоединяемый=фикстура.присоединяемый,
                    дерево=фикстура.дерево, отпечаток_закрытия=фикстура.отпечаток, отпечаток_запуска=фикстура.отпечаток)
        измерения = []
        эталон = None
        for номер in range(параметры.повторов):
            for имя in (("до", "после") if номер % 2 == 0 else ("после", "до")):
                модуль = модули[имя]
                with mock.patch.object(модуль, "выполнить_чтение_репозитория", wraps=модуль.выполнить_чтение_репозитория) as чтение:
                    процессорное_начало = time.process_time_ns()
                    начало = time.perf_counter_ns()
                    результат = модуль.связать_отпечаток_со_слиянием(**вход)
                    длительность = time.perf_counter_ns() - начало
                    процессорное = time.process_time_ns() - процессорное_начало
                if эталон is None:
                    эталон = результат
                if результат != эталон or результат["состояние"] != "подтверждён":
                    raise AssertionError("результаты версий адаптера различаются")
                измерения.append({"повтор": номер + 1, "версия": имя, "наносекунды": длительность,
                                   "процессорное_время_python_наносекунды": процессорное, "процессов_git": чтение.call_count})
        итог = {"схема": "fum.профиль-адаптера-слияния.1", "вход": {к: з for к, з in вход.items() if к != "корень_репозитория"},
                "подготовка_фикстуры_наносекунды": подготовка, "измерения": измерения,
                "медианы_наносекунды": {имя: int(statistics.median(з["наносекунды"] for з in измерения if з["версия"] == имя)) for имя in пути},
                "хэши_версий": {имя: hashlib.sha256(путь.read_bytes()).hexdigest() for имя, путь in пути.items()},
                "ответы_совпали": True, "git": subprocess.check_output(["git", "--version"]).decode().strip(),
                "python": sys.version.split()[0],
                "границы": "Одна синтетическая фикстура; подготовка исключена из пар. Это тёплый кеш. CPU дочерних Git-процессов и память не измерены."}
        параметры.результат.write_text(json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + "\n")
        print(json.dumps({"медианы_наносекунды": итог["медианы_наносекунды"], "процессов_git": {имя: sorted({з["процессов_git"] for з in измерения if з["версия"] == имя}) for имя in пути}, "ответы_совпали": True}, ensure_ascii=False))
    finally:
        фикстура.doCleanups()


if __name__ == "__main__":
    главная()
