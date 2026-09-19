"""Сравнить два последовательных CLI и общий процесс на одинаковой фикстуре."""

import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time

from test_подготовки_полей import ПроверкиПодготовкиПолей, обёртка, помощник


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    аргументы = разбор.parse_args()
    записи = []
    for повтор in range(3):
        for режим in (("два процесса", "общий процесс") if повтор % 2 == 0 else
                      ("общий процесс", "два процесса")):
            фикстура = ПроверкиПодготовкиПолей()
            try:
                фикстура.setUp()
                if режим == "общий процесс":
                    команда = [sys.executable, "-B", str(помощник), "--корень", str(фикстура.корень),
                               "--запрос", str(фикстура.запрос)]
                else:
                    предпросмотр = [sys.executable, "-B", str(обёртка), "предпросмотр",
                        "--корень-репозитория", str(фикстура.корень), "--запрос", str(фикстура.запрос)]
                    поля = [sys.executable, "-B", str(помощник.with_name("проверить-поля-журнала.py")),
                            "--корень", str(фикстура.корень), "--запрос", str(фикстура.запрос)]
                    код = "import subprocess\n" + "\n".join(
                        "subprocess.run(" + repr(часть) + ", check=True)" for часть in (предпросмотр, поля))
                    команда = [sys.executable, "-B", "-c", код]
                начало = time.monotonic_ns()
                результат = subprocess.run([sys.executable, "-B", str(обёртка), "запустить",
                    "--корень-репозитория", str(фикстура.корень), "--запрос", str(фикстура.запрос),
                    "--название", "Профиль подготовки", "--исполнитель", "Фикстура",
                    "--класс-проверки", "адресная", "--приёмочные-раунды", "--", *команда],
                    cwd=фикстура.корень, capture_output=True, text=True, timeout=30)
                длительность = time.monotonic_ns() - начало
                if результат.returncode:
                    raise RuntimeError(результат.stdout + результат.stderr)
                данные = json.loads(результат.stdout)
                if данные["ошибки"] or len(данные["входы"]) != 2:
                    raise RuntimeError("Не подтверждена корректная пара")
                записи.append({"повтор": повтор + 1, "режим": режим,
                               "наносекунды": длительность, "код": результат.returncode})
            finally:
                фикстура.doCleanups()
    данные = {"схема": "fum.профиль-подготовки-полей.1", "измерения": записи,
        "граница": "Настоящий родительский запуск целиком; подготовка Git-фикстуры исключена. Включены процессы, учёт и проверка. Это не время всего рабочего цикла.",
        "медианы_наносекунды": {режим: statistics.median(з["наносекунды"] for з in записи if з["режим"] == режим)
            for режим in ("два процесса", "общий процесс")},
        "python": sys.version.split()[0],
        "sha256": {п.name: hashlib.sha256(п.read_bytes()).hexdigest()
                   for п in (помощник, обёртка, Path(__file__), Path(__file__).with_name("test_подготовки_полей.py"))}}
    with аргументы.выход.open("x", encoding="utf-8") as выход:
        json.dump(данные, выход, ensure_ascii=False, indent=2)
        выход.write("\n")


if __name__ == "__main__":
    выполнить()
