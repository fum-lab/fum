"""Малый профиль подготовки Markdown: два файла и 25 исторических ссылок."""

import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
from time import perf_counter_ns

import test_проекция_необязательного_графа as сценарий


def измерить():
    результаты = []
    for случай in ("граф отсутствует", "граф существует", "похожее имя"):
        испытание = сценарий.ПроверкаПроекцииНеобязательногоГрафа()
        испытание.setUp()
        try:
            испытание._подготовить()
            адрес = "../../.obsidian/graph.json.bak" if случай == "похожее имя" else "../../.obsidian/graph.json"
            текст = "# History\n\n" + f"[Граф]({адрес})\n" * 25
            испытание._записать(сценарий.исходный_путь, текст)
            граф = испытание.корень / ".obsidian/graph.json"
            if случай == "граф существует":
                испытание._записать(".obsidian/graph.json", b'{"scale": 1.234}\n')
                исходные = граф.read_bytes()
                состояние = граф.stat()
            план = сценарий.модуль.построить_план(
                испытание.корень, сценарий.политика(), испытание._преобразовать)

            def сформировать():
                try:
                    сценарий.модуль.сформировать_выходы(испытание.корень, план, испытание._преобразовать)
                    return "принят"
                except сценарий.модуль.ОшибкаКонтракта:
                    return "отказ"

            начало = perf_counter_ns()
            исход_прогрева = сформировать()
            прогрев = perf_counter_ns() - начало
            ожидаемый = "отказ" if случай == "похожее имя" else "принят"
            if исход_прогрева != ожидаемый:
                raise RuntimeError("Профиль получил неверный исход прогрева")
            замеры = []
            for _ in range(5):
                начало = perf_counter_ns()
                for _ in range(5):
                    if сформировать() != ожидаемый:
                        raise RuntimeError("Профиль получил неверный исход")
                замеры.append((perf_counter_ns() - начало) / 5)
            if случай == "граф существует":
                if граф.read_bytes() != исходные or (граф.stat().st_ino, граф.stat().st_mtime_ns) != (состояние.st_ino, состояние.st_mtime_ns):
                    raise RuntimeError("Изменилось пользовательское состояние")
            elif граф.exists():
                raise RuntimeError("Создан отсутствующий пользовательский граф")
            результаты.append({"случай": случай, "исход": ожидаемый,
                               "байтов_разметки": len(текст.encode()), "ссылок": 25,
                               "sha256_разметки": hashlib.sha256(текст.encode()).hexdigest(),
                               "первый_вызов_нс": прогрев, "серии_нс_на_вызов": замеры,
                               "медиана_нс": statistics.median(замеры)})
        finally:
            испытание.tearDown()
    предикат = сценарий.основа.СЦЕНАРИЙ.parents[2] / "fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py"
    return {"схема": "fum.профиль-необязательного-графа-проекции.1",
            "python": platform.python_version(), "система": platform.system(),
            "архитектура": platform.machine(), "серий": 5, "вызовов_в_серии": 5,
            "ориентир_решения_нс": 100000000,
            "граница": "Формирование двух выходов из готового плана с подставным преобразователем. Импорт сценария, Git-подготовка плана, установка и Swift вне замеров. Первый вызов отдельно от тёплых серий.",
            "sha256_реализации": hashlib.sha256(сценарий.основа.СЦЕНАРИЙ.read_bytes()).hexdigest(),
            "sha256_предиката": hashlib.sha256(предикат.read_bytes()).hexdigest(),
            "sha256_сценария": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "результаты": результаты}


if __name__ == "__main__":
    параметры = argparse.ArgumentParser()
    параметры.add_argument("--выход", type=Path, required=True)
    аргументы = параметры.parse_args()
    результат = измерить()
    текст = json.dumps(результат, ensure_ascii=False, indent=2) + "\n"
    аргументы.выход.write_text(текст)
    print(текст, end="")
