"""Сравнимый профиль настоящего обновления политики на открытом входе."""

import argparse
import contextlib
import hashlib
import json
import platform
import tempfile
import time
from pathlib import Path
from unittest import mock

import test_obnovitj_policy as основа


def снять_отпечатки(пути):
    return {имя: hashlib.sha256(путь.read_bytes()).hexdigest()
            for имя, путь in пути.items()}


def подтвердить_неизменность(пути, исходные):
    if снять_отпечатки(пути) != исходные:
        raise RuntimeError("Исходники изменились во время измерений")


def измерить(мегабайт, деклараций):
    помощник = основа.PolicyUpdaterTests()
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный).resolve()
        помощник.init_repo(корень)
        строки = ["значение = '" + chr(47) + f"private/example-{номер}'"
                  for номер in range(деклараций)]
        текст = "\n".join(строки + [строки[0]]) + "\n"
        заполнение = "# " + "QUJD" * 1024 + "\n"
        текст += заполнение * ((мегабайт * 1024 * 1024 - len(текст)) // len(заполнение) + 1)
        исходник = помощник.write_and_add(корень, "tests/большой.py", текст)
        политика = помощник.write_policy(корень)
        указания = [помощник.declaration(
            identifier=f"profile-{номер}", path="tests/большой.py", line=номер + 1,
        ) for номер in range(деклараций)]
        для_сравнения = исходник.read_bytes()
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
                (основа.updater, "_read_target_text", "чтение"),
                (основа.updater.scanner, "scan_text", "полный_разбор"),
                (основа.updater, "_derive_exception", "вывод_исключения"),
                (основа.updater, "_atomic_write", "атомарная_запись"),
            ):
                стек.enter_context(mock.patch.object(
                    объект, имя, метка(стадия, getattr(объект, имя)),
                ))
            начало = time.perf_counter_ns()
            изменения = основа.updater.update_policy(корень, политика, указания)
            длительность = time.perf_counter_ns() - начало
        assert изменения == деклараций
        результат = json.loads(политика.read_bytes())
        assert [запись["count"] for запись in результат["exceptions"]] == [2] + [1] * (деклараций - 1)
        assert [запись["id"] for запись in результат["exceptions"]] == [f"profile-{номер}" for номер in range(деклараций)]
        байты = политика.read_bytes()
        свойства = политика.stat()
        начало = time.perf_counter_ns()
        повтор = основа.updater.update_policy(корень, политика, указания)
        повтор_нс = time.perf_counter_ns() - начало
        assert повтор == 0 and политика.read_bytes() == байты
        assert (политика.stat().st_ino, политика.stat().st_mtime_ns) == (свойства.st_ino, свойства.st_mtime_ns)
        assert исходник.read_bytes() == для_сравнения
        return {
            "вход_sha256": hashlib.sha256(для_сравнения).hexdigest(),
            "вход_байт": len(для_сравнения),
            "деклараций": деклараций,
            "обновление_нс": длительность,
            "повтор_нс": повтор_нс,
            "изменений": изменения,
            "интервалы_нс": интервалы,
            "политика_sha256": hashlib.sha256(байты).hexdigest(),
            "политика": результат,
            "точный_повтор": True,
            "исходник_неизменён": True,
        }


def основная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    разбор.add_argument("--мегабайт", type=int, default=4)
    разбор.add_argument("--деклараций", type=int, default=12)
    разбор.add_argument("--повторов", type=int, default=3)
    параметры = разбор.parse_args()
    if not (1 <= параметры.мегабайт <= 32 and 2 <= параметры.деклараций <= 100
            and 1 <= параметры.повторов <= 5):
        разбор.error("Размер: 1–32 МиБ; деклараций: 2–100; повторов: 1–5")
    пути = {путь.name: путь for путь in sorted(основа.SCRIPTS_DIR.glob("*.py"))}
    пути.update({
        "профилировщик": Path(__file__),
        "модуль_фикстуры": Path(основа.__file__),
        "структура_запросов": Path(основа.updater.scanner.REQUEST_LAYOUT_SCRIPTS) / "request_folder_layout.py",
    })
    исходники = снять_отпечатки(пути)
    замеры = [измерить(параметры.мегабайт, параметры.деклараций)
              for _ in range(параметры.повторов)]
    подтвердить_неизменность(пути, исходники)
    данные = {
        "схема": "fum.профиль-пакетного-анализа-политики.2",
        "версия_интерпретатора": platform.python_version(),
        "система": platform.system(),
        "архитектура": platform.machine(),
        "реализация": исходники,
        "профилировщик_sha256": исходники["профилировщик"],
        "исходники_неизменны": True,
        "граница": "Подготовка Git-фикстуры исключена; чтение и запись входят в обновление. Интервалы вложены и не суммируются с общим временем. Точный повтор измерен отдельно без вложенных меток.",
        "замеры": замеры,
    }
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    параметры.выход.write_text(json.dumps(данные, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"замеров": len(замеры), "политика_sha256": замеры[0]["политика_sha256"]}, ensure_ascii=False))


if __name__ == "__main__":
    основная()
