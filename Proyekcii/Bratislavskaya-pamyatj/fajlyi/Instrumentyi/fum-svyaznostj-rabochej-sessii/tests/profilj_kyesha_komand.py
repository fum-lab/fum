"""Одинаковый открытый JSONL: полный разбор и проверяемый приватный индекс."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import time

import test_создание_коммита as база


def измерить(с_кэшем, с_хвостом=False):
    ф = база.СозданиеКоммита()
    ф.setUp()
    try:
        строка = json.dumps({"type": "response_item", "payload": {"type": "message",
            "role": "assistant", "content": [{"type": "output_text", "text": "x" * 512}]}}, separators=(",", ":")) + "\n"
        with ф.источник.open("a") as f:
            for _ in range(50000):
                f.write(строка)
        кэш = ф.каталог / "индекс-команд.json"
        база.прочитать_сообщения(ф.источник, база.ЗАДАЧА, корень_репозитория=ф.корень, кэш=кэш)
        if с_хвостом:
            with ф.источник.open("a") as f:
                f.write(строка)
        вход_sha = hashlib.sha256(ф.источник.read_bytes()).hexdigest()
        кэш_до = кэш.read_bytes()
        if с_кэшем:
            ф.параметры["источники"][0]["кэш"] = str(кэш)
        замеры = []
        результаты = []
        for _ in range(3):
            начало = time.perf_counter_ns()
            результат = база.коммит.команды(ф.параметры)
            замеры.append(time.perf_counter_ns() - начало)
            assert [r["текст"] for r in результат] == [база.КОМАНДА]
            результаты.append(hashlib.sha256(база.коммит.байты(результат)).hexdigest())
        assert len(set(результаты)) == 1
        assert кэш.read_bytes() == кэш_до
        assert hashlib.sha256(ф.источник.read_bytes()).hexdigest() == вход_sha
        скрипты = Path(__file__).resolve().parents[1] / "scripts"
        return {"схема": "fum.профиль-кэша-команд.1", "python": platform.python_version(),
            "кэш": с_кэшем, "хвост_после_индекса": с_хвостом,
            "измеритель_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "вход_sha256": вход_sha, "байтов": ф.источник.stat().st_size,
            "результат_sha256": результаты[0], "замеры_наносекунды": замеры,
            "медиана_наносекунды": int(statistics.median(замеры)),
            "исходники_sha256": {n: hashlib.sha256((скрипты / n).read_bytes()).hexdigest()
                for n in ["создание_коммита.py", "сообщения_задачи.py"]},
            "граница": "Три чтения открытого JSONL; подготовка фикстуры и индекса исключена; тёплый файловый кэш. При выборе хвоста одна строка дописана после индекса до замеров. Полный путь коммита не измеряется."}
    finally:
        ф.doCleanups()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--выход", type=Path, required=True)
    parser.add_argument("--с-кэшем", action="store_true")
    parser.add_argument("--с-хвостом", action="store_true")
    args = parser.parse_args()
    args.выход.write_text(json.dumps(измерить(args.с_кэшем, args.с_хвостом), ensure_ascii=False, indent=2) + "\n")
