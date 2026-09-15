"""Профиль четырёх открытых CJS-файлов; исходники не исполняются."""

import argparse
import hashlib
import importlib.util
import json
import platform
from pathlib import Path
import statistics
import subprocess
import sys
from time import perf_counter_ns

корень = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(корень / "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts"))
import разбор_сценария as сценарий

путь_проекции = корень / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py"
спецификация = importlib.util.spec_from_file_location("проекция_для_профиля", путь_проекции)
проекция = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(проекция)


def измерить(действие):
    замеры = []
    for _ in range(7):
        начало = perf_counter_ns()
        действие()
        замеры.append(perf_counter_ns() - начало)
    return {"замеры_нс": замеры, "медиана_нс": statistics.median(замеры)}


def профиль():
    входы = {п: (корень / п).read_bytes() for п in sorted(сценарий.пути_сценариев)}
    тексты = {п: б.decode("utf-8") for п, б in входы.items()}
    политика = json.loads(путь_проекции.parents[1].joinpath("контракт-v2.json").read_bytes())

    def собственный_разбор():
        for текст in тексты.values():
            разбор = сценарий.Разбор(сценарий.токены(текст))
            while разбор.следующий():
                разбор.оператор()

    def полный_разбор():
        for текст in тексты.values():
            результат = сценарий.разобрать(текст)
            if any(з["класс"] == "собственное" and any("a" <= б.lower() <= "z" for б in з["имя"])
                   for з in результат["объявления"]):
                raise ValueError("Необоснованное собственное имя")

    def классификация():
        for путь, байты in входы.items():
            if проекция.классифицировать_содержимое(корень, путь, политика, байты)[1] != "сохранить_байты":
                raise ValueError("Изменилось действие формата")

    действия = {"лексика": lambda: [сценарий.токены(т) for т in тексты.values()],
                "собственный_разбор_с_лексикой": собственный_разбор,
                "полный_разбор_с_Node": полный_разбор, "классификация_проекции": классификация}
    измерения = {стадия: {имя: измерить(действие) for имя, действие in действия.items()}
                 for стадия in ("исходный_замер", "повтор_без_изменения_алгоритма")}
    источники = [Path(__file__), Path(сценарий.__file__), путь_проекции,
                 корень / "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py",
                 путь_проекции.parents[1] / "контракт-v2.json"]
    return {"схема": "fum.профиль-сценариев-ответа.1", "python": platform.python_version(),
            "node": subprocess.check_output(["node", "--version"], text=True).strip(),
            "платформа": platform.system() + " " + platform.machine(),
            "граница": "Один вызов стадии охватывает все четыре UTF-8-входа в памяти. Полный разбор и классификация включают отдельный процесс Node на файл. Чтение входов, импорт и запись профиля вне замеров; стадии перекрываются и не суммируются. Повтор проверяет ту же реализацию, ускорение не заявляется.",
            "критерий_полного_разбора_нс": 1000000000,
            "входы": {п: {"байты": len(б), "sha256": hashlib.sha256(б).hexdigest()} for п, б in входы.items()},
            "реализация": {п.relative_to(корень).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest() for п in источники},
            "измерения": измерения}


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", required=True, type=Path)
    параметры = разбор.parse_args()
    результат = профиль()
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    print(json.dumps({стадия: {имя: з["медиана_нс"] for имя, з in данные.items()}
                      for стадия, данные in результат["измерения"].items()}, ensure_ascii=False))
