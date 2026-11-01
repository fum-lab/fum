"""Три свежих процесса: прежний отказ и точный допуск на одинаковых байтах."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time


sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_метаданных_профилей as примеры


def измерить(повторов):
    if type(повторов) is not int or повторов < 3:
        raise ValueError("нужно не менее трёх повторов")
    исходники = [Path(__file__), Path(примеры.__file__), Path(примеры.метаданные.__file__),
        Path(примеры.сканер.__file__), Path(примеры.обновление.__file__),
        Path(sys.modules["path_forms"].__file__), Path(sys.modules["request_folder_layout"].__file__)]
    def снимок():
        return {п.name: hashlib.sha256(п.read_bytes()).hexdigest() for п in исходники}
    до = снимок(); сырые = примеры.байты(примеры.пример())
    декларация = примеры.заявка(сырые)
    результаты = {}; интервалы = {"прежний-отказ": [], "типизированный-допуск": []}
    процессор = {имя: [] for имя in интервалы}
    for _ in range(повторов):
        for имя in интервалы:
            начало = time.monotonic_ns(); цп = time.process_time_ns()
            находки = (примеры.сканер.scan_text(примеры.ПУТЬ, сырые.decode())
                if имя == "прежний-отказ" else примеры.классифицировать(сырые, декларация))
            процессор[имя].append(time.process_time_ns() - цп)
            интервалы[имя].append(time.monotonic_ns() - начало)
            результаты[имя] = {"кандидатов": len(находки),
                "ошибок": sum(к.category.startswith("error.") for к in находки)}
    if снимок() != до or результаты != {
            "прежний-отказ": {"кандидатов": 21, "ошибок": 21},
            "типизированный-допуск": {"кандидатов": 21, "ошибок": 0}}:
        raise ValueError("дрейф исходников либо неверная классификация")
    return {"исходники_sha256": до, "вход_sha256": hashlib.sha256(сырые).hexdigest(),
        "повторов": повторов, "результаты": результаты, "интервалы_нс": интервалы,
        "процессорные_нс": процессор,
        "медианы_нс": {имя: statistics.median(ряд) for имя, ряд in интервалы.items()}}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--повторов", type=int, default=9)
    разбор.add_argument("--дочерний", action="store_true")
    разбор.add_argument("--выход", type=Path)
    параметры = разбор.parse_args()
    if параметры.дочерний:
        print(json.dumps(измерить(параметры.повторов), ensure_ascii=False, sort_keys=True))
        return
    if параметры.выход is None or параметры.выход.exists():
        raise ValueError("нужен новый выход профиля")
    запуски = []
    for _ in range(3):
        начало = time.monotonic_ns()
        процесс = subprocess.run([sys.executable, "-I", "-S", "-B", str(Path(__file__).resolve()),
            "--дочерний", "--повторов", str(параметры.повторов)], capture_output=True, check=True)
        запуски.append({"полное_время_процесса_нс": time.monotonic_ns() - начало,
            "измерения": json.loads(процесс.stdout)})
    пины = запуски[0]["измерения"]["исходники_sha256"]
    if any(з["измерения"]["исходники_sha256"] != пины
            or з["измерения"]["вход_sha256"] != запуски[0]["измерения"]["вход_sha256"] for з in запуски):
        raise ValueError("различные входы свежих процессов")
    отчёт = {"схема": "fum.профиль-метаданных-профилей.1", "свежих_процессов": 3,
        "запуски": запуски, "граница": "Синтетический источник 21 позиции. Подготовка и загрузка исключены "
        "из внутренних интервалов; полное время процесса показано отдельно. Прежний отказ не эквивалентен "
        "новому допуску. Ускорение полного рабочего цикла не заявляется."}
    with параметры.выход.open("x", encoding="utf-8") as поток:
        поток.write(json.dumps(отчёт, ensure_ascii=False, sort_keys=True, indent=2) + "\n")
    print(json.dumps({"свежих_процессов": 3, "классификация_проверена": True}, ensure_ascii=False))


if __name__ == "__main__":
    главная()
