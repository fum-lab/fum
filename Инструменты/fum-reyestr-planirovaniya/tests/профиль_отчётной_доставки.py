"""Конечный профиль реальной обёртки, точной разницы и подтверждения индекса."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import time

from test_доставка_отчёта import ПроверкиОтчётнойДоставки
from test_обратная_доставка import гит
import доставка_отчёта


def измерить(повторы):
    папка = Path(__file__).resolve().parents[1]
    исходники = sorted((папка / "scripts").glob("*достав*.py")) + [Path(доставка_отчёта.отчёты.__file__), Path(__file__).resolve(), папка / "tests/test_доставка_отчёта.py"]
    хэши = {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}
    замеры = []
    for _ in range(повторы):
        фикстура = ПроверкиОтчётнойДоставки("test_настоящая_обёртка_и_явный_индекс")
        try:
            with фикстура.ф.владелец() as доставка:
                доставка.применить()
                начало = time.monotonic_ns()
                итог = фикстура.проверить(доставка)
                середина = time.monotonic_ns()
                assert итог["стадия"] == "ожидается индекс"
                гит(фикстура.ф.цель, "add", ".")
                assert доставка.подтвердить_индекс()["стадия"] == "проверено"
                замеры.append({"проверка_и_отчёт": середина - начало, "подготовка_и_сверка_индекса": time.monotonic_ns() - середина})
        finally:
            фикстура.doCleanups()
    assert хэши == {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}
    return {"схема": "fum.профиль-отчётной-доставки.1", "python": platform.python_version(), "git": гит(Path.cwd(), "--version"),
            "исходники_sha256": хэши, "повторы": повторы, "замеры": замеры,
            "медианы_наносекунды": {имя: int(statistics.median(замер[имя] for замер in замеры)) for имя in замеры[0]},
            "граница": "Три небольшие независимые Git-фикстуры; создание, план и merge исключены; кэш ОС тёплый; проверка — печать строки через настоящую обёртку; сеть и полный FUM не измеряются"}


if __name__ == "__main__":
    разбор = argparse.ArgumentParser()
    разбор.add_argument("--выход", required=True)
    разбор.add_argument("--повторы", type=int, default=3)
    аргументы = разбор.parse_args()
    результат = измерить(аргументы.повторы)
    Path(аргументы.выход).write_text(json.dumps(результат, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(результат["медианы_наносекунды"], ensure_ascii=False))
