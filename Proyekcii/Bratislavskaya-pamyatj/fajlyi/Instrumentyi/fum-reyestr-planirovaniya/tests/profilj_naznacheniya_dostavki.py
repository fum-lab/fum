"""Наблюдение назначения на трёх открытых Git-сценариях без доставки."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import tempfile
import time

from test_обратная_доставка import Фикстура, гит
from test_назначение_доставки import назначить
from доставка_план import построить_план, наблюдать_назначение


def измерить(повторы):
    if повторы < 1:
        raise ValueError("Нужен хотя бы один повтор")
    папка = Path(__file__).resolve().parents[1]
    исходники = sorted((папка / "scripts").glob("*достав*.py")) + [Path(__file__).resolve(),
                 папка / "tests/test_обратная_доставка.py", папка / "tests/test_назначение_доставки.py"]
    хэши = {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}
    замеры = []
    for сценарий in ("недоставленный срез", "уже в предках", "detached прежнего дерева"):
        for _ in range(повторы):
            with tempfile.TemporaryDirectory(prefix="fum-профиль-назначения-") as каталог:
                фикстура = Фикстура(каталог)
                назначение = назначить(фикстура)
                план = построить_план(фикстура.описание, [str(фикстура.цель)], фикстура.владельцы, назначение=назначение)
                if сценарий == "уже в предках":
                    гит(фикстура.цель, "merge", "--no-edit", фикстура.срез)
                elif сценарий == "detached прежнего дерева":
                    гит(фикстура.цель, "checkout", "--detach")
                    гит(фикстура.источник, "worktree", "add", str(фикстура.папка / "другое-дерево"), "fuma")
                начало = time.monotonic_ns()
                итог = наблюдать_назначение(план, фикстура.владельцы)
                длительность = time.monotonic_ns() - начало
                assert итог["получатели"][0]["отношение"] == {
                    "недоставленный срез": "недоставленные коммиты", "уже в предках": "в предках",
                    "detached прежнего дерева": "unknown"}[сценарий]
                замеры.append({"сценарий": сценарий, "наносекунды": длительность,
                               "байты_вывода": len((json.dumps(итог, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode())})
    assert хэши == {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}
    return {"схема": "fum.профиль-наблюдения-назначения.1", "python": platform.python_version(), "git": гит(Path.cwd(), "--version"),
            "исходники_sha256": хэши, "повторы_на_сценарий": повторы, "замеры": замеры,
            "медианы_наносекунды": {сценарий: int(statistics.median(замер["наносекунды"] for замер in замеры if замер["сценарий"] == сценарий))
                                     for сценарий in sorted({замер["сценарий"] for замер in замеры})},
            "граница": "Открытые небольшие Git-репозитории; создание и изменения истории исключены; тёплый кэш ОС; включены процессы Git; вывод измеряется в байтах, не токенах; ожидание, runtime выбора работы, сеть и полный FUM не измеряются"}


if __name__ == "__main__":
    разбор = argparse.ArgumentParser()
    разбор.add_argument("--выход", required=True)
    разбор.add_argument("--повторы", type=int, default=3)
    аргументы = разбор.parse_args()
    результат = измерить(аргументы.повторы)
    Path(аргументы.выход).write_text(json.dumps(результат, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(результат["медианы_наносекунды"], ensure_ascii=False))
