"""Профиль на трёх независимых открытых репозиториях; подготовка исключена."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import tempfile
import time
from unittest.mock import patch

from test_обратная_доставка import Фикстура, гит
from доставка_план import построить_план
import доставка_план


def измерить(повторы):
    исходники = Path(__file__).resolve().parents[1] / "scripts"
    хэши = {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest()
            for путь in sorted(исходники.glob("*доставка*.py"))}
    замеры = []
    чтения_деревьев = []
    исходный_гит = доставка_план.гит
    def считать(корень, *аргументы):
        if аргументы[0] == "rev-parse" and any(аргумент.endswith("^{tree}") for аргумент in аргументы[1:]):
            чтения_деревьев[-1] += 1
        return исходный_гит(корень, *аргументы)
    for _ in range(повторы):
        чтения_деревьев.append(0)
        with tempfile.TemporaryDirectory(prefix="fum-профиль-доставки-") as папка, patch.object(доставка_план, "гит", side_effect=считать):
            фикстура = Фикстура(папка)
            профиль = []
            план = построить_план(фикстура.описание, [str(фикстура.цель)], фикстура.владельцы, профиль=профиль)
            начало = time.monotonic_ns()
            with фикстура.владелец(план) as доставка:
                результат = доставка.применить()
            assert результат["стадия"] == "применено"
            профиль.append({"стадия": "применение", "длительность_наносекунды": time.monotonic_ns() - начало})
            замеры.append(профиль)
    return {"схема": "fum.профиль-обратной-доставки.1", "python": platform.python_version(), "git": гит(Path.cwd(), "--version"),
            "повторы": повторы, "исходники_sha256": хэши, "сценарий": "Два worktree, расходящиеся ветки, один принятый срез, один получатель; файлы по несколько байтов",
            "граница": "Подготовка Git исключена; тёплый файловый кэш; wall-clock включает процессы Git и устойчивую запись; нативная активация не измеряется",
            "чтения_деревьев_через_план": чтения_деревьев,
            "замеры": замеры, "медианы_наносекунды": {стадия: int(statistics.median(замер[номер]["длительность_наносекунды"] for замер in замеры))
                                                            for номер, стадия in enumerate(("наблюдение", "план", "применение"))}}


if __name__ == "__main__":
    разбор = argparse.ArgumentParser()
    разбор.add_argument("--выход", required=True)
    разбор.add_argument("--повторы", type=int, default=3)
    аргументы = разбор.parse_args()
    результат = измерить(аргументы.повторы)
    Path(аргументы.выход).write_text(json.dumps(результат, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(результат["медианы_наносекунды"], ensure_ascii=False))
