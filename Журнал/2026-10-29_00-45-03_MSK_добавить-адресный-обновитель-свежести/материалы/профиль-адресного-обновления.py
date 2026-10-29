"""Повторяемый wall-clock-профиль одного файла через собранный Swift CLI."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import statistics
import subprocess
import tempfile
import time
from pathlib import Path


def главная() -> int:
    разбор = argparse.ArgumentParser()
    разбор.add_argument("--двоичный-файл", required=True)
    разбор.add_argument("--выход", required=True)
    аргументы = разбор.parse_args()

    корень = Path(__file__).resolve().parents[3]
    двоичныйФайл = Path(аргументы.двоичный_файл).resolve(strict=True)
    библиотека = корень / "Инструменты/fum-svezhestj-markdown/swift/Sources/ОбновительСвежести/ОбновительСвежести.swift"
    тест = корень / "Инструменты/fum-svezhestj-markdown/swift/Tests/ОбновительСвежестиTests/ТестыОбновителяСвежести.swift"
    повторов = 3
    относительныйПуть = "образец.md"
    времяЗапуска = "2026-10-29 00:00:00 MSK"
    строкаСценария = "Профиль измеряет адресную запись служебной свежести одного Markdown-файла.\n"
    текстСценария = "# Однофайловый профиль\n\n" + строкаСценария * 2048
    байтыСценария = текстСценария.encode("utf-8")

    испытания = []
    for номер in range(1, повторов + 1):
        with tempfile.TemporaryDirectory(prefix="fum-md-single-file-profile-") as временныйКаталог:
            путьКорня = Path(временныйКаталог)
            путьФайла = путьКорня / относительныйПуть
            путьФайла.write_bytes(байтыСценария)
            команда = [
                str(двоичныйФайл),
                "--корень",
                str(путьКорня),
                "--путь",
                относительныйПуть,
                "--время",
                времяЗапуска,
            ]

            началоЗаписи = time.perf_counter_ns()
            запись = subprocess.run(команда, check=True, capture_output=True, text=True)
            времяЗаписи = time.perf_counter_ns() - началоЗаписи
            результатЗаписи = json.loads(запись.stdout)
            if результатЗаписи["изменён"] is not True:
                raise RuntimeError("Первый вызов не выполнил адресную запись")

            началоПовтора = time.perf_counter_ns()
            повтор = subprocess.run(команда, check=True, capture_output=True, text=True)
            времяПовтора = time.perf_counter_ns() - началоПовтора
            результатПовтора = json.loads(повтор.stdout)
            if результатПовтора["изменён"] is not False:
                raise RuntimeError("Идемпотентный повтор изменил файл")
            if результатПовтора["sha256"] != результатЗаписи["sha256"]:
                raise RuntimeError("Повтор изменил содержательный хэш")

            испытания.append(
                {
                    "номер": номер,
                    "запись_наносекунды": времяЗаписи,
                    "повтор_наносекунды": времяПовтора,
                    "хэш_содержимого": результатЗаписи["sha256"],
                }
            )

    записьНаносекунды = [элемент["запись_наносекунды"] for элемент in испытания]
    повторНаносекунды = [элемент["повтор_наносекунды"] for элемент in испытания]
    материал = {
        "схема": "fum.addressable-recency-profile.v1",
        "сеанс": "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
        "метод": "монотонное wall-clock-время процесса CLI от запуска до выхода; сборка исключена",
        "сценарий": {
            "файлов": 1,
            "относительный_путь": относительныйПуть,
            "повторов": повторов,
            "шаблон": "# Однофайловый профиль\\n\\n" + строкаСценария,
            "строк_шаблона": 2048,
            "размер_входа_байты": len(байтыСценария),
            "sha256_входа": hashlib.sha256(байтыСценария).hexdigest(),
            "время": времяЗапуска,
        },
        "исполняемый_файл": {
            "путь": str(двоичныйФайл),
            "sha256": hashlib.sha256(двоичныйФайл.read_bytes()).hexdigest(),
        },
        "версии": {
            "система": platform.platform(),
            "архитектура": platform.machine(),
            "swift": subprocess.run(["swift", "--version"], check=True, capture_output=True, text=True).stdout.splitlines()[0],
        },
        "исходники": {
            "библиотека_sha256": hashlib.sha256(библиотека.read_bytes()).hexdigest(),
            "тест_sha256": hashlib.sha256(тест.read_bytes()).hexdigest(),
            "скрипт_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        },
        "испытания": испытания,
        "сводка": {
            "медиана_записи_наносекунды": int(statistics.median(записьНаносекунды)),
            "медиана_повтора_наносекунды": int(statistics.median(повторНаносекунды)),
        },
        "решение": "профиль отдельного файла; вывод о превосходстве и ROOT-приёмке не делается",
    }
    выход = корень / аргументы.выход
    выход.write_text(json.dumps(материал, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(материал["сводка"], ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(главная())
