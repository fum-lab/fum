"""Измерить чтение закреплённых v3-приёмок на одном неизменном HEAD."""

import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time


КОРЕНЬ = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(КОРЕНЬ / "Инструменты/fum-svyaznostj-rabochej-sessii/scripts"))
from обязательства_задачи import ГРАНИЦА_ЗАДАЧИ, проверить_остаток


def хэш_файла(путь):
    return hashlib.sha256(путь.read_bytes()).hexdigest()


def вершина():
    return subprocess.run(["git", "-C", str(КОРЕНЬ), "rev-parse", "HEAD"], check=True, capture_output=True, text=True).stdout.strip()


def главная():
    аргументы = argparse.ArgumentParser(description=__doc__)
    аргументы.add_argument("--ожидаемая-вершина", required=True)
    аргументы.add_argument("--повторов", type=int, default=3)
    аргументы.add_argument("--вывод", type=Path, required=True)
    параметры = аргументы.parse_args()
    if параметры.повторов < 1 or вершина() != параметры.ожидаемая_вершина:
        аргументы.error("нужны повторения и точно ожидаемый HEAD")
    источники = [
        КОРЕНЬ / "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обязательства_задачи.py",
        КОРЕНЬ / "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/исторические_неподтверждённые_приёмки.py",
        КОРЕНЬ / "Планирование/задачи/01a07d3d-d376-7ad2-aafc-67e4c25a67eb/обязательства.json",
    ]
    исходные = {путь.relative_to(КОРЕНЬ).as_posix(): хэш_файла(путь) for путь in источники}
    замеры = []
    for _ in range(параметры.повторов):
        начало = time.perf_counter_ns()
        итог = проверить_остаток(КОРЕНЬ, ГРАНИЦА_ЗАДАЧИ)
        длительность = time.perf_counter_ns() - начало
        неподтверждённые = [этап for этап in итог["подтверждённые_этапы"] if этап["состояние_проверки"] == "историческая-связь-не-подтверждена"]
        if len(неподтверждённые) != 6 or len(итог["подтверждённые_этапы"]) != 7 or any(этап["актуальна"] for этап in итог["подтверждённые_этапы"]):
            raise AssertionError("неожиданное состояние исторического остатка")
        замеры.append({"длительность_нс": длительность, "состояние": итог["состояние"], "неподтверждённых": len(неподтверждённые)})
    if вершина() != параметры.ожидаемая_вершина or исходные != {путь.relative_to(КОРЕНЬ).as_posix(): хэш_файла(путь) for путь in источники}:
        raise AssertionError("вход изменился во время измерения")
    результат = {"схема": "fum.профиль-исторических-приёмок.1", "вершина": параметры.ожидаемая_вершина,
                 "источники": исходные, "замеры": замеры,
                 "медиана_нс": statistics.median(замер["длительность_нс"] for замер in замеры),
                 "условия": "Три последовательных чтения на одном HEAD; кэш ОС не сбрасывался; включены Git и Python."}
    параметры.вывод.write_text(json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(f'Медиана: {результат["медиана_нс"] / 1e9:.6f} с')


if __name__ == "__main__":
    главная()
