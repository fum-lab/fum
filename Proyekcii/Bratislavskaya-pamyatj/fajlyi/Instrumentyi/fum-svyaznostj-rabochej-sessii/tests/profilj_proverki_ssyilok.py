"""Профиль повторных ссылок в широких каталогах без приватных входов."""

import argparse
import hashlib
import json
import platform
import sys
import tempfile
import time
from pathlib import Path
from unittest import mock

import test_check_session_coherence as основа


def отпечатки():
    корень = Path(__file__).resolve().parents[3]
    выбранный = основа.SCRIPT_PATH.resolve().parents[3]
    пути = {Path(__file__).resolve()}
    for модуль in tuple(sys.modules.values()):
        имя = getattr(модуль, "__file__", None)
        if имя:
            путь = Path(имя).resolve()
            if путь.is_file() and путь.suffix == ".py" and (
                путь.is_relative_to(корень) or путь.is_relative_to(выбранный)
            ):
                пути.add(путь)
    return {
        ("измеряемое/" if путь.is_relative_to(выбранный) else "профиль/")
        + путь.relative_to(выбранный if путь.is_relative_to(выбранный) else корень).as_posix():
        hashlib.sha256(путь.read_bytes()).hexdigest()
        for путь in sorted(пути)
    }


def измерить(записей, ссылок):
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный).resolve()
        цели = корень / "цели"
        цели.mkdir()
        цель = цели / "пример.md"
        цель.write_text("Содержимое цели.\n", encoding="utf-8")
        for номер in range(записей):
            (корень / f"папка-{номер:05}").mkdir()
            (цели / f"файл-{номер:05}.txt").write_bytes(b"")
        документ = корень / "источник.md"
        вход = ("[Цель](цели/пример.md)\n" * ссылок).encode()
        документ.write_bytes(вход)
        счётчики = {}
        интервалы = []
        исходное_перечисление = Path.iterdir

        def перечислить(путь):
            начало = time.perf_counter_ns()
            ключ = путь.relative_to(корень).as_posix()
            счётчики[ключ] = счётчики.get(ключ, 0) + 1
            try:
                yield from исходное_перечисление(путь)
            finally:
                интервалы.append(time.perf_counter_ns() - начало)

        начало = time.perf_counter_ns()
        with mock.patch.object(Path, "iterdir", перечислить):
            ошибки = основа.check_session_coherence.validate_markdown_links({документ}, корень)
        длительность = time.perf_counter_ns() - начало
        if ошибки or документ.read_bytes() != вход:
            raise RuntimeError("Результат проверки ссылок или исходный документ изменён")
        return {
            "ссылок": ссылок,
            "лишних_записей_в_каталоге": записей,
            "вход_sha256": hashlib.sha256(вход).hexdigest(),
            "вход_байт": len(вход),
            "длительность_нс": длительность,
            "перечисления": счётчики,
            "перечисление_сумма_нс": sum(интервалы),
            "ошибки": ошибки,
        }


def основная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    разбор.add_argument("--записей", type=int, default=1000)
    разбор.add_argument("--ссылок", type=int, default=1000)
    разбор.add_argument("--повторов", type=int, default=3)
    параметры = разбор.parse_args()
    if not (1 <= параметры.записей <= 5000 and 1 <= параметры.ссылок <= 5000
            and 1 <= параметры.повторов <= 5):
        разбор.error("Записей и ссылок: 1–5000; повторов: 1–5")
    исходники = отпечатки()
    замеры = [измерить(параметры.записей, параметры.ссылок)
              for _ in range(параметры.повторов)]
    if отпечатки() != исходники:
        raise RuntimeError("Исходники изменились во время измерений")
    данные = {
        "схема": "fum.профиль-проверки-ссылок.1",
        "версия_интерпретатора": platform.python_version(),
        "система": platform.system(),
        "архитектура": platform.machine(),
        "исходники_sha256": исходники,
        "граница": "Подготовка файлов исключена. Измеряется настоящая validate_markdown_links с метками перечисления каталогов; вложенное время не прибавляется к общему.",
        "замеры": замеры,
    }
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    параметры.выход.write_text(json.dumps(данные, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"замеров": len(замеры), "секунды": [запись["длительность_нс"] / 1e9 for запись in замеры],
                      "перечисления": [запись["перечисления"] for запись in замеры]}, ensure_ascii=False))


if __name__ == "__main__":
    основная()
