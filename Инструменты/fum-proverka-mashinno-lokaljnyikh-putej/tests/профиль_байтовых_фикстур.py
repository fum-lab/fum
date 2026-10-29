"""Профиль точного обновления и сканирования байтовой политики v4."""

import argparse
import contextlib
import hashlib
import json
import os
import platform
import tempfile
import time
from pathlib import Path
from unittest import mock

import test_байтовых_фикстур as основа


def отпечатки(пути):
    return {имя: hashlib.sha256(путь.read_bytes()).hexdigest() for имя, путь in пути.items()}


def измерить(мегабайт: int):
    помощник = основа.ПроверкиБайтовыхФикстур()
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный).resolve()
        помощник.инициализировать_репозиторий(корень)
        строка = b"open fixture line\n"
        предел = мегабайт * 1024 * 1024
        префикс = (строка * (предел // len(строка) + 1))[:предел]
        данные = префикс + b"\xf0\x9f"
        исходник = помощник.записать_байты(корень, данные)
        политика = помощник.записать_политику(
            корень,
            [],
            схема="fum.machine-local-path-policy.v3",
        )
        заявка = помощник.заявка()
        исходные_байты = исходник.read_bytes()
        интервалы = {}

        def метка(имя, действие):
            def выполнить(*аргументы, **параметры):
                начало = time.perf_counter_ns()
                try:
                    return действие(*аргументы, **параметры)
                finally:
                    интервалы.setdefault(имя, []).append(time.perf_counter_ns() - начало)
            return выполнить

        with contextlib.ExitStack() as стек:
            for объект, имя, стадия in (
                (основа.обновитель, "_прочитать_байтовую_цель", "чтение_байтов"),
                (основа.обновитель, "_вывести_байтовую_фикстуру", "вывод_отпечатка"),
                (основа.обновитель, "_atomic_write", "атомарная_запись"),
            ):
                стек.enter_context(mock.patch.object(
                    объект,
                    имя,
                    метка(стадия, getattr(объект, имя)),
                ))
            начало = time.perf_counter_ns()
            изменений = основа.обновитель.update_policy(
                корень,
                политика,
                [],
                байтовые_фикстуры=[заявка],
            )
            обновление_нс = time.perf_counter_ns() - начало

        байты_политики = политика.read_bytes()
        свойства = политика.stat()
        начало = time.perf_counter_ns()
        повтор = основа.обновитель.update_policy(
            корень,
            политика,
            [],
            байтовые_фикстуры=[заявка],
        )
        повтор_нс = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        результат = основа.сканер.scan_repository(корень, политика)
        сканирование_нс = time.perf_counter_ns() - начало

        assert изменений == 1 and повтор == 0
        assert результат.exit_code == 0
        assert результат.rendered_lines() == (
            f"{помощник.ПУТЬ}:0:allow.test-fixture.неполный-хвост-UTF-8",
        )
        assert исходник.read_bytes() == исходные_байты
        assert политика.read_bytes() == байты_политики
        assert (политика.stat().st_ino, политика.stat().st_mtime_ns) == (
            свойства.st_ino,
            свойства.st_mtime_ns,
        )
        return {
            "вход_байт": len(исходные_байты),
            "хэш_входа": hashlib.sha256(исходные_байты).hexdigest(),
            "обновление_нс": обновление_нс,
            "повтор_нс": повтор_нс,
            "сканирование_нс": сканирование_нс,
            "интервалы_нс": интервалы,
            "изменений": изменений,
            "точный_повтор": True,
            "исходник_неизменён": True,
            "хэш_политики": hashlib.sha256(байты_политики).hexdigest(),
        }


def основная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    разбор.add_argument("--мегабайт", type=int, default=1)
    разбор.add_argument("--повторов", type=int, default=3)
    параметры = разбор.parse_args()
    if not (1 <= параметры.мегабайт <= 8 and 1 <= параметры.повторов <= 5):
        разбор.error("Размер: 1–8 МиБ; повторов: 1–5")
    if os.path.lexists(параметры.выход):
        разбор.error("Нужен новый файл --выход")
    пути = {путь.name: путь for путь in sorted(основа.СЦЕНАРИИ.glob("*.py"))}
    пути.update({
        "профилировщик": Path(__file__),
        "модуль_фикстуры": Path(основа.__file__),
        "структура_запросов": Path(основа.сканер.REQUEST_LAYOUT_SCRIPTS) / "request_folder_layout.py",
    })
    исходники = отпечатки(пути)
    замеры = [измерить(параметры.мегабайт) for _ in range(параметры.повторов)]
    if отпечатки(пути) != исходники:
        raise RuntimeError("исходники изменились во время измерений")
    данные = {
        "схема": "fum.профиль-байтовой-политики.1",
        "версия_интерпретатора": platform.python_version(),
        "система": platform.system(),
        "архитектура": platform.machine(),
        "реализация": исходники,
        "исходники_неизменны": True,
        "граница": (
            "Подготовка временного Git-репозитория исключена. Обновление, "
            "идемпотентный повтор и полное сканирование измерены отдельно; "
            "вложенные интервалы не суммируются с общим временем."
        ),
        "замеры": замеры,
    }
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    with параметры.выход.open("x", encoding="utf-8") as поток:
        json.dump(данные, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
    print(json.dumps({"замеров": len(замеры), "вход_байт": замеры[0]["вход_байт"]}, ensure_ascii=False))


if __name__ == "__main__":
    основная()
