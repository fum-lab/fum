"""Сравнить обычное чтение и чистую диагностику на одной Git-фикстуре."""
import argparse
import hashlib
import json
import platform
import statistics
import subprocess
import time
from pathlib import Path

from test_обязательства_задачи import ТестыОбязательств, машинные_байты


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument("--вывод", type=Path, required=True)
    параметры = разбор.parse_args()
    корень = Path(__file__).resolve().parents[3]
    пути = [Path(__file__), Path(__file__).with_name("test_обязательства_задачи.py")]
    for навык in ("fum-svyaznostj-rabochej-sessii", "fum-otchyotyi-o-zapuskakh-proverok", "fum-snimki-indeksa"):
        пути.extend(sorted((корень / "Инструменты" / навык / "scripts").glob("*.py")))
    исходники = {путь.relative_to(корень).as_posix(): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in пути}
    случай = ТестыОбязательств()
    try:
        случай.setUp()
        случай.создать_приёмку()
        случай.записать("результат.bin", b"changed result")
        вершина = случай.коммит()
        кандидат = машинные_байты(случай.основа)
        до = случай.гит("status", "--porcelain=v1")
        замеры = []
        эталон = None
        for _ in range(3):
            начало = time.perf_counter_ns()
            проверка = случай.модуль.ПроверкаОбязательств(случай.корень, случай.граница)
            остаток = проверка.остаток(кандидат)
            чтение = time.perf_counter_ns() - начало
            начало = time.perf_counter_ns()
            итог = случай.модуль.диагностика_приёмок(проверка.файлы, остаток)
            диагностика = time.perf_counter_ns() - начало
            байты = машинные_байты(итог)
            if эталон is None:
                эталон = байты
            assert байты == эталон
            assert остаток["схема"] == "fum.остаток-обязательств.1"
            замеры.append({"чтение_нс": чтение, "диагностика_нс": диагностика})
        assert до == случай.гит("status", "--porcelain=v1")
        assert исходники == {путь.relative_to(корень).as_posix(): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in пути}
        результат = {"схема": "fum.профиль-диагностики-приёмок.1", "python": platform.python_version(),
                     "условия": "Одна изолированная Git-история; подготовка исключена; три чтения и три чистых преобразования; файловый кэш не очищался.",
                     "вершина_фикстуры": вершина, "sha256_кандидата": hashlib.sha256(кандидат).hexdigest(),
                     "sha256_вывода": hashlib.sha256(эталон).hexdigest(), "байтов_вывода": len(эталон),
                     "код": исходники,
                     "git": subprocess.check_output(["git", "--version"], text=True).strip(),
                     "замеры": замеры, "медиана_чтения_нс": statistics.median(з["чтение_нс"] for з in замеры),
                     "медиана_диагностики_нс": statistics.median(з["диагностика_нс"] for з in замеры),
                     "порог_исследования_диагностики_нс": 10000000}
        параметры.вывод.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps({поле: результат[поле] for поле in ("медиана_чтения_нс", "медиана_диагностики_нс", "байтов_вывода")}, ensure_ascii=False))
    finally:
        случай.doCleanups()


if __name__ == "__main__":
    выполнить()
