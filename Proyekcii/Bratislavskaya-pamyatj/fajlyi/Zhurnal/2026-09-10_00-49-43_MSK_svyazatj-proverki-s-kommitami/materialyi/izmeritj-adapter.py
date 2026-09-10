"""Воспроизводимый профиль чтения Git: небольшая и увеличенная фикстуры."""
import argparse
import hashlib
import importlib.util
import json
import os
import statistics
import sys
import time
from pathlib import Path
from unittest import mock


корень = Path(__file__).resolve().parents[3]
автоматизация = корень / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok"
sys.path[:0] = [str(автоматизация / "scripts"), str(автоматизация / "tests")]
from test_отчёты_о_запусках_проверок import ФикстураОтчётов, имя_сессии
import отчёты_о_запусках_проверок as отчёты


def измерить(путь: Path) -> dict:
    спецификация = importlib.util.spec_from_file_location("адаптер", путь)
    модуль = importlib.util.module_from_spec(спецификация)
    спецификация.loader.exec_module(модуль)
    серии = []
    for размер in (4, 500):
        фикстура = ФикстураОтчётов()
        try:
            for номер in range(размер):
                (фикстура.корень / f"файл-{номер:04}.bin").write_bytes(bytes(range(256)) * 4)
            отчёты.выполнить_чтение_репозитория(фикстура.корень, "add", ".")
            отпечаток = отчёты.вычислить_отпечаток_снимка(фикстура.корень, f"Журнал/{имя_сессии}")
            отчёты.выполнить_чтение_репозитория(фикстура.корень, "commit", "-qm", "Сохранить вход профиля")
            коммит = отчёты.выполнить_чтение_репозитория(фикстура.корень, "rev-parse", "HEAD").decode().strip()
            исходное_чтение = отчёты.выполнить_чтение_репозитория
            for режим in ("исторический", "после-коммита"):
                повторы = []
                for номер in range(7):
                    вызовы = []
                    def читать(корень, *аргументы):
                        начало = time.perf_counter_ns()
                        try:
                            return исходное_чтение(корень, *аргументы)
                        finally:
                            вызовы.append({"команда": аргументы[0], "наносекунды": time.perf_counter_ns() - начало})
                    with mock.patch.object(модуль, "выполнить_чтение_репозитория", читать), mock.patch.object(отчёты, "выполнить_чтение_репозитория", читать):
                        начало = time.perf_counter_ns()
                        результат = модуль.связать_отпечаток_с_коммитом(фикстура.корень, f"Журнал/{имя_сессии}", коммит, отпечаток, отпечаток, режим)
                        длительность = time.perf_counter_ns() - начало
                    if результат["состояние"] != "подтверждён":
                        raise AssertionError(результат)
                    повторы.append({"наносекунды": длительность, "вызовы": вызовы})
                серии.append({"файлов": размер, "режим": режим, "повторы": повторы, "медиана_наносекунды": statistics.median(элемент["наносекунды"] for элемент in повторы)})
        finally:
            фикстура.очистить()
    return {"sha256_реализации": hashlib.sha256(путь.read_bytes()).hexdigest(), "серии": серии}


if __name__ == "__main__":
    разбор = argparse.ArgumentParser()
    разбор.add_argument("--реализация", type=Path, required=True)
    разбор.add_argument("--вывод", type=Path, required=True)
    параметры = разбор.parse_args()
    with mock.patch.dict(os.environ, {"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull}):
        параметры.вывод.write_text(json.dumps(измерить(параметры.реализация), ensure_ascii=False, indent=2) + "\n")
