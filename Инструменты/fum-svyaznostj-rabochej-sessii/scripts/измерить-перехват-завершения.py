#!/usr/bin/env python3
"""Воспроизводимый локальный профиль Stop: только синтетический ввод и временное состояние."""
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import time


КАТАЛОГ = Path(__file__).resolve().parents[1]
ТЕСТЫ = КАТАЛОГ / "tests/test_перехват_завершения.py"
АДАПТЕР = КАТАЛОГ / "scripts/перехватить-завершение.py"


def выполнить():
    описание = importlib.util.spec_from_file_location("фикстура", ТЕСТЫ)
    модуль = importlib.util.module_from_spec(описание)
    описание.loader.exec_module(модуль)
    сценарии = []
    for режим in ("чужая-задача", "обычный-ввод", "предельный-ввод", "большой-результат", "тайм-аут"):
        замеры = []
        for _ in range(5):
            пример = модуль.ПерехватЗавершения()
            пример.setUp()
            try:
                if режим == "чужая-задача":
                    пример.событие["session_id"] = модуль.ЧУЖАЯ
                if режим == "большой-результат":
                    (пример.корень / "результат.py").write_bytes(b"x" * (15 * 1024 * 1024))
                if режим == "тайм-аут":
                    (пример.корень / "режим").write_text("тайм-аут")
                вход = json.dumps(пример.событие).encode()
                if режим == "предельный-ввод":
                    вход += b" " * (65536 - len(вход))
                начало = time.perf_counter_ns()
                процесс = subprocess.run(пример.команда("--профиль"), input=вход, capture_output=True, timeout=5)
                длительность = time.perf_counter_ns() - начало
                if процесс.returncode != 0:
                    raise RuntimeError("неуспешный процесс профиля")
                ответ = json.loads(процесс.stdout)
                if режим != "чужая-задача" and ответ.get("decision") != "block":
                    raise RuntimeError("измерялся неуспешный сценарий")
                if режим == "чужая-задача" and ответ != {}:
                    raise RuntimeError("нарушена изоляция")
                профиль = json.loads(процесс.stderr.decode().removeprefix("FUM-PROFILE "))
                замеры.append(dict(профиль, процесс_нс=длительность))
            finally:
                пример.doCleanups()
        сценарии.append({"режим": режим, "повторов": len(замеры),
                         "медиана_процесса_нс": int(statistics.median(замер["процесс_нс"] for замер in замеры)),
                         "максимум_процесса_нс": max(замер["процесс_нс"] for замер in замеры),
                         "замеры": замеры})
    результат = {"схема": "fum.измерение-Stop.1", "python": platform.python_version(),
                 "платформа": platform.system(), "архитектура": platform.machine(),
                 "адаптер_sha256": hashlib.sha256(АДАПТЕР.read_bytes()).hexdigest(),
                 "тесты_sha256": hashlib.sha256(ТЕСТЫ.read_bytes()).hexdigest(),
                 "критерии": {"обычный_процесс_менее_нс": 1000000000,
                              "память_менее_байт": 134217728},
                 "сценарии": сценарии}
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(выполнить())

