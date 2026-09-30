"""Проверить совместимость и стоимость рендера после исправления пустой таблицы."""
from __future__ import annotations

import argparse
import hashlib
import json
import statistics
import time
from pathlib import Path

from профиль_контрольной_точки import (
    ПУТЬ_РЕАЛИЗАЦИИ, выполнить_git, загрузить_из_байтов,
)


def выполнить_профиль() -> int:
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", type=Path, required=True)
    разбор.add_argument("--база", required=True)
    разбор.add_argument("--выход", type=Path, required=True)
    аргументы = разбор.parse_args()
    корень = аргументы.корень.resolve(strict=True)
    база = выполнить_git(корень, "rev-parse", "--verify", аргументы.база + "^{commit}").decode().strip()
    if база != аргументы.база:
        raise ValueError("нужен точный полный OID базы")
    путь = корень / ПУТЬ_РЕАЛИЗАЦИИ
    исходные = выполнить_git(корень, "show", f"{база}:{ПУТЬ_РЕАЛИЗАЦИИ}")
    текущие = путь.read_bytes()
    до = загрузить_из_байтов("рендер_до", путь, исходные)
    после = загрузить_из_байтов("рендер_после", путь, текущие)
    try:
        до.сформировать_таблицу_запусков([])
    except TypeError:
        отказ = "TypeError"
    else:
        raise AssertionError("база не воспроизводит исследуемый отказ")
    пустая = после.сформировать_таблицу_запусков([])
    assert пустая[1] == "0" and len(пустая[0]) == 2
    записи = [(Path(f"{номер}.json"), {
        "исполнитель": "профиль", "вызов": f"проверка | {номер}",
        "состояние": "завершён", "длительность_наносекунды": 1_500_000,
        "статус": "успешно", "пояснение": None,
    }, b"") for номер in range(300)]
    ожидаемое = до.сформировать_таблицу_запусков(записи)
    assert после.сформировать_таблицу_запусков(записи) == ожидаемое
    времена = {"до": [], "после": []}
    for раунд in range(5):
        порядок = (("до", до), ("после", после))
        for имя, модуль in порядок if раунд % 2 == 0 else reversed(порядок):
            начало = time.perf_counter_ns()
            for _ in range(100):
                результат = модуль.сформировать_таблицу_запусков(записи)
            времена[имя].append(time.perf_counter_ns() - начало)
            assert результат == ожидаемое
    if путь.read_bytes() != текущие:
        raise RuntimeError("исходник изменился во время измерения")
    результат = {
        "схема": "fum.профиль-пустой-таблицы.1", "база": база,
        "до_sha256": hashlib.sha256(исходные).hexdigest(),
        "после_sha256": hashlib.sha256(текущие).hexdigest(),
        "граница": "Рендер таблицы; неизменённые зависимости текущего checkout; подготовка вне таймера",
        "пустая_до": отказ, "пустая_после": пустая,
        "совпадающий_вывод_sha256": hashlib.sha256(json.dumps(ожидаемое, ensure_ascii=False).encode()).hexdigest(),
        "записей": len(записи), "повторов_в_замере": 100,
        "времена_нс": времена,
        "медианы_нс": {имя: statistics.median(ряд) for имя, ряд in времена.items()},
    }
    with аргументы.выход.open("x", encoding="utf-8") as файл:
        json.dump(результат, файл, ensure_ascii=False, indent=2, sort_keys=True)
        файл.write("\n")
    print(json.dumps({"совместимость": True, "медианы_нс": результат["медианы_нс"]}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(выполнить_профиль())
