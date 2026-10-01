import argparse
import ast
import hashlib
import json
import platform
import re
import statistics
import subprocess
import sys
import time
from pathlib import Path
from typing import Sequence

ПУТЬ = "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py"
ИСПОЛНИТЕЛЬ = "Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py"
БАЗА = "6a32d99426688da61ffa9014f11e2a90bb29d5b2"
ИМЕНА = {"индекс_канонического_исполнителя_проверок", "является_неполной_проверкой_проекции", "является_запуском_полной_проверки"}


def загрузить(байты):
    дерево = ast.parse(байты)
    дерево.body = [узел for узел in дерево.body if isinstance(узел, ast.FunctionDef) and узел.name in ИМЕНА]
    область = {"Path": Path, "Sequence": Sequence, "re": re,
               "ПУТЬ_ПОЛНОЙ_ПРОВЕРКИ": Path(ИСПОЛНИТЕЛЬ)}
    exec(compile(дерево, "извлечённые-классификаторы", "exec"), область)
    return область["является_запуском_полной_проверки"]


def измерить(функция, корень, команда, ожидается):
    assert функция(корень, команда) is ожидается
    начало = time.perf_counter_ns()
    for _ in range(200):
        assert функция(корень, команда) is ожидается
    return (time.perf_counter_ns() - начало) / 200


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--корень", type=Path, required=True)
    parser.add_argument("--выход", type=Path, required=True)
    args = parser.parse_args()
    корень = args.корень.resolve()
    старые = subprocess.run(["git", "show", БАЗА + ":" + ПУТЬ], cwd=корень,
                           check=True, capture_output=True).stdout
    новые = (корень / ПУТЬ).read_bytes()
    функции = [загрузить(старые), загрузить(новые)]
    сценарии = {"обычный": (["python3", "-B", ИСПОЛНИТЕЛЬ], (True, True)),
               "отложенный": (["python3", "-B", ИСПОЛНИТЕЛЬ, "--проекция", "отложена",
                               "--основание-отложения-проекции", "Пауза пользователя"], (True, False))}
    измерения = []
    for фаза in ("до-решения", "повтор-после-решения-сохранить-алгоритм"):
        for имя, (команда, ожидания) in сценарии.items():
            замеры = [[], []]
            for номер in range(3):
                for индекс in ((0, 1) if номер % 2 == 0 else (1, 0)):
                    замеры[индекс].append(измерить(функции[индекс], корень, команда, ожидания[индекс]))
            медианы = [statistics.median(ряд) for ряд in замеры]
            измерения.append({"фаза": фаза, "сценарий": имя, "команда": команда,
                              "ожидания_класса_полная": ожидания,
                              "на_вызов_нс": замеры, "медианы_нс": медианы,
                              "отношение_новый_к_старому": медианы[1]/медианы[0]})
    максимум = max(з["медианы_нс"][1] for з in измерения)
    assert максимум < 1_000_000, "стоимость требует отдельной оптимизации"
    данные = {"схема": "fum.профиль-отложенной-проекции.1", "база": БАЗА,
              "старый_sha256": hashlib.sha256(старые).hexdigest(),
              "новый_sha256": hashlib.sha256(новые).hexdigest(),
              "драйвер_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "python": platform.python_version(), "система": platform.system(),
              "архитектура": platform.machine(), "повторов": 3, "вызовов_в_замере": 200,
              "точка_измерения": "perf_counter_ns вокруг цикла классификации, без импорта и Git",
              "критерий_до_замера": "новая классификация дешевле 1 мс на один запуск; иначе отдельная оптимизация",
              "измерения": измерения,
              "решение": "Сохранить алгоритм: ограниченная обработка argv, стоимость менее 1 мс на запуск; усложнение кешированием не оправдано.",
              "граница": "Извлечённые AST-функции при реальном разрешении путей. Старый код не умеет откладывать проекцию; отношение не доказывает ускорение равнофункциональных реализаций. Полный smoke и генератор не запускаются."}
    args.выход.write_text(json.dumps(данные, ensure_ascii=False, sort_keys=True, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"максимум_медианы_нс": максимум, "измерения": измерения}, ensure_ascii=False))


if __name__ == "__main__":
    main()
