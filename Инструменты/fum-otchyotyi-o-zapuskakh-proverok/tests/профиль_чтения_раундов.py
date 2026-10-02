"""Повторяемый парный профиль чтения байтов закрытых v3/v4-свидетельств."""
from __future__ import annotations

import argparse
import hashlib
import json
import statistics
import time
from pathlib import Path

from test_закрытый_отчёт_из_гита import ТестыЧтенияЗакрытогоОтчёта


def измерить(выход: Path, повторы: int) -> dict:
    if повторы < 1:
        raise ValueError("нужен хотя бы один повтор")
    фикстура = ТестыЧтенияЗакрытогоОтчёта("test_действительный_отчёт_реальной_обёртки")
    фикстура.setUp()
    try:
        раунды, отчёт_раундов = фикстура.закрытые_раунды()
        случаи = {
            "v3": (фикстура.файлы, фикстура.отчёт),
            "v4": (раунды, отчёт_раундов),
        }
        времена = {имя: [] for имя in случаи}
        for имя, (файлы, отчёт) in случаи.items():
            for _ in range(5):
                фикстура.байты(файлы, отчёт)
        for номер in range(повторы):
            for имя in ("v3", "v4") if номер % 2 == 0 else ("v4", "v3"):
                файлы, отчёт = случаи[имя]
                начало = time.perf_counter_ns()
                результат = фикстура.байты(файлы, отчёт)
                времена[имя].append(time.perf_counter_ns() - начало)
                if результат["состояние"] != "проверен":
                    raise RuntimeError("профиль получил иной результат проверки")
        профиль = {
            "схема": "fum.профиль-чтения-раундов.1",
            "повторов": повторы,
            "граница": "только проверить_байты_закрытого_отчёта; фикстура и Git-команды не измеряются",
            "случаи": {
                имя: {
                    "медиана_наносекунды": int(statistics.median(значения)),
                    "минимум_наносекунды": min(значения),
                    "максимум_наносекунды": max(значения),
                    "sha256_отчёта": hashlib.sha256(случаи[имя][1]).hexdigest(),
                }
                for имя, значения in времена.items()
            },
        }
        выход.write_text(json.dumps(профиль, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        return профиль
    finally:
        фикстура.doCleanups()


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", required=True, type=Path)
    разбор.add_argument("--повторы", type=int, default=100)
    параметры = разбор.parse_args()
    print(json.dumps(измерить(параметры.выход, параметры.повторы), ensure_ascii=False, sort_keys=True))
