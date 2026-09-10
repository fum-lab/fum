import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import time
from unittest import mock

разбор = argparse.ArgumentParser()
разбор.add_argument("--корень", type=Path, required=True)
разбор.add_argument("--вывод", type=Path, required=True)
аргументы = разбор.parse_args()
корень = аргументы.корень.resolve()
сценарий = корень / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests/test_братиславская_проекция_памяти.py"
спецификация = importlib.util.spec_from_file_location("профиль_Finder", сценарий)
испытания = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(испытания)
модуль = испытания.модуль
испытание = испытания.ПроверкаКонтрактаБратиславскойПроекции()
испытание.подготовить_испытание()
измерения = []
try:
    испытание._записать(".gitignore", ".DS_Store\n")
    испытание._записать("README.md", "# FUM\n")
    for номер in range(12):
        испытание._записать(f"Каталог{номер}/Образец.md", "# Образец\n")
    испытание._зафиксировать()
    политика = испытание._политика()
    преобразователь = испытание._преобразователь_подстрок({"Каталог": "Katalog", "Образец": "Obrazec"})
    модуль.применить_поколение(испытание.корень, политика, преобразователь)
    цель = испытание.корень / политика["целевая_область"]
    каталоги = [цель] + sorted(путь for путь in цель.rglob("*") if путь.is_dir())
    эталон = None
    for вариант in ("без_метаданных", "с_метаданными"):
        if вариант == "с_метаданными":
            for каталог in каталоги:
                (каталог / ".DS_Store").write_bytes(b"public-finder-profile")
        for повтор in range(3):
            with mock.patch.object(модуль, "путь_игнорируется_репозиторием", wraps=модуль.путь_игнорируется_репозиторием) as счётчик:
                начало = time.perf_counter_ns()
                снимок = модуль.снимок_целевого_дерева(испытание.корень)
                длительность = time.perf_counter_ns() - начало
            хэш = модуль.хэш_дерева(снимок)
            if эталон is None:
                эталон = хэш
            if хэш != эталон:
                raise RuntimeError("Метаданные изменили управляемый снимок")
            измерения.append({"вариант": вариант, "повтор": повтор, "длительность_нс": длительность, "вызовов_git_ignore": счётчик.call_count, "хэш_дерева": хэш})
    результат = {"генератор_sha256": hashlib.sha256(испытания.СЦЕНАРИЙ.read_bytes()).hexdigest(), "измеритель_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "каталогов": len(каталоги), "измерения": измерения, "снимки_совпали": True}
    with аргументы.вывод.open("x") as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
    print(json.dumps(результат, ensure_ascii=False))
finally:
    испытание.завершить_испытание()
