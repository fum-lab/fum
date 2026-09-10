"""Измерить стоимость проверки происхождения на открытой Git-фикстуре."""
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


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, default=Path.cwd())
    разбор.add_argument("--результат", type=Path, required=True)
    разбор.add_argument("--повторов", type=int, default=7)
    параметры = разбор.parse_args()
    if параметры.повторов < 1:
        разбор.error("число повторов должно быть положительным")
    инструмент = параметры.корень_репозитория.resolve() / "Инструменты/fum-kompleksnaya-proverka-repozitoriya"
    путь = инструмент / "tests/test_контур_слияния.py"
    спецификация = importlib.util.spec_from_file_location("фикстура_происхождения", путь)
    модуль = importlib.util.module_from_spec(спецификация)
    спецификация.loader.exec_module(модуль)
    фикстура = модуль.КонтурСлияния()
    начало = time.perf_counter_ns()
    фикстура.setUp()
    подготовка = time.perf_counter_ns() - начало
    try:
        измерения = []
        эталон = None
        for номер in range(параметры.повторов):
            with mock.patch.object(фикстура.модуль, "прочитать_git", wraps=фикстура.модуль.прочитать_git) as чтение:
                процессорное_начало = time.process_time_ns()
                начало = time.perf_counter_ns()
                результат = фикстура.проверить()
                длительность = time.perf_counter_ns() - начало
                процессорное = time.process_time_ns() - процессорное_начало
            if эталон is None:
                эталон = результат
            if результат != эталон:
                raise AssertionError("происхождение изменилось между повторами")
            измерения.append({"повтор": номер + 1, "наносекунды": длительность,
                               "процессорное_время_python_наносекунды": процессорное,
                               "процессов_git": чтение.call_count})
        итог = {"схема": "fum.профиль-происхождения-контура.1", "вход": эталон,
                "подготовка_фикстуры_наносекунды": подготовка, "измерения": измерения,
                "медиана_наносекунды": int(statistics.median(з["наносекунды"] for з in измерения)),
                "хэши": {имя: hashlib.sha256((инструмент / имя).read_bytes()).hexdigest()
                          for имя in ("scripts/контур_слияния.py", "tests/test_контур_слияния.py")},
                "git": subprocess.check_output(["git", "--version"]).decode().strip(), "python": sys.version.split()[0],
                "ответы_совпали": True,
                "границы": "Тёплая синтетическая фикстура с двумя checkout и материализованной зависимостью. Подготовка исключена. Полный smoke, реальный объём FUM, CPU дочерних Git-процессов и память не измерены."}
        параметры.результат.write_text(json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + "\n")
        print(json.dumps({"медиана_наносекунды": итог["медиана_наносекунды"],
                          "процессов_git": sorted({з["процессов_git"] for з in измерения}), "ответы_совпали": True}, ensure_ascii=False))
    finally:
        фикстура.doCleanups()


if __name__ == "__main__":
    главная()
