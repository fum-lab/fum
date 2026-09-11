#!/usr/bin/env python3
"""Измеряет выбор политики и один синтетический переход; Swift не вызывается."""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import statistics
from time import perf_counter_ns


def измерить(выход):
    путь = Path(__file__).resolve().parents[1] / "test_братиславская_проекция_памяти.py"
    спецификация = importlib.util.spec_from_file_location("проверки_перехода", путь)
    проверки = importlib.util.module_from_spec(спецификация)
    спецификация.loader.exec_module(проверки)
    модуль = проверки.модуль
    политика = модуль.загрузить_политику(проверки.СЦЕНАРИЙ.parent.parent / "контракт-v2.json")
    измерения = {}
    for название, хэш in (("действующая_политика", модуль.хэш_значения(политика)),
                          ("прежняя_политика", модуль.ХЭШ_ПОЛИТИКИ_ДО_ФОРМАТОВ_ПРИЛОЖЕНИЯ)):
        выборки = []
        for _повтор in range(5):
            начало = perf_counter_ns()
            for _вызов in range(1000):
                модуль.политика_для_доказательства_владения(политика, хэш)
            выборки.append((perf_counter_ns() - начало) / 1000)
        измерения[название] = {"выборки_нс_на_вызов": выборки, "медиана_нс": statistics.median(выборки)}
    переходы = []
    for _повтор in range(5):
        проверка = проверки.ПроверкаКонтрактаБратиславскойПроекции()
        проверка.подготовить_испытание()
        try:
            политика, _фикстура, преобразователь = проверка._установить_прежнее_поколение_v2()
            начало = perf_counter_ns()
            модуль.применить_поколение(проверка.корень, политика, преобразователь)
            переходы.append(perf_counter_ns() - начало)
        finally:
            проверка.завершить_испытание()
    результат = {"схема": "fum.профиль-перехода-прежнего-v2.1", "Python": platform.python_version(),
                 "платформа": platform.platform(), "хэш_кода": "sha256:" + hashlib.sha256(проверки.СЦЕНАРИЙ.read_bytes()).hexdigest(),
                 "хэш_политики": модуль.хэш_значения(политика), "выбор_политики": измерения,
                 "переход": {"выборки_нс": переходы, "медиана_нс": statistics.median(переходы)},
                 "граница": "5 × 1000 вызовов выбора, прогретая файловая система; 5 переходов одного .txt, без подготовки фикстуры и Swift"}
    выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"выбор_прежней_нс": измерения["прежняя_политика"]["медиана_нс"],
                      "переход_нс": statistics.median(переходы)}, ensure_ascii=False))


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    измерить(разбор.parse_args().выход)
