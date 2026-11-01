"""Профиль потокового содержательного кандидата на неизменяемом коммите Git."""
from __future__ import annotations

import argparse
import json
import statistics
import subprocess
import sys
import time
import tracemalloc
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from закрытый_отчёт_из_гита import кандидат_содержимого_коммита


def измерить(корень: Path, коммит: str, запрос: str, повторы: int, выход: Path) -> dict:
    if повторы < 1:
        raise ValueError("нужен хотя бы один повтор")
    дерево = subprocess.check_output(["git", "-C", str(корень), "ls-tree", "-rlz", коммит])
    объём = 0
    исключённый = 0
    число = 0
    for запись in дерево.split(b"\0"):
        if not запись:
            continue
        описание, имя = запись.split(b"\t", 1)
        поля = описание.split()
        if поля[1] != b"blob":
            continue
        размер = int(поля[3])
        объём += размер
        число += 1
        if имя.startswith(b"Proyekcii/"):
            исключённый += размер
    времена = []
    пики = []
    кандидаты = set()
    for _ in range(повторы):
        tracemalloc.start()
        начало = time.perf_counter_ns()
        try:
            кандидаты.add(кандидат_содержимого_коммита(корень, коммит, запрос))
            времена.append(time.perf_counter_ns() - начало)
            пики.append(tracemalloc.get_traced_memory()[1])
        finally:
            tracemalloc.stop()
    if len(кандидаты) != 1:
        raise RuntimeError("повторы дали разные отпечатки")
    результат = {
        "схема": "fum.профиль-связи-содержимого.1",
        "коммит": коммит,
        "запрос": запрос,
        "повторов": повторы,
        "кандидат": кандидаты.pop(),
        "медиана_наносекунды": int(statistics.median(времена)),
        "максимум_памяти_Python_байты": max(пики),
        "blob_файлов_в_дереве": число,
        "blob_байтов_в_дереве": объём,
        "blob_байтов_исключённой_проекции": исключённый,
        "граница": "измерен вызов кандидата; Git-процесс и дисковый кэш не профилировались",
    }
    выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return результат


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, required=True)
    разбор.add_argument("--коммит", required=True)
    разбор.add_argument("--запрос", required=True)
    разбор.add_argument("--повторы", type=int, default=3)
    разбор.add_argument("--выход", type=Path, required=True)
    параметры = разбор.parse_args()
    print(json.dumps(измерить(параметры.корень_репозитория.resolve(), параметры.коммит, параметры.запрос, параметры.повторы, параметры.выход), ensure_ascii=False))
