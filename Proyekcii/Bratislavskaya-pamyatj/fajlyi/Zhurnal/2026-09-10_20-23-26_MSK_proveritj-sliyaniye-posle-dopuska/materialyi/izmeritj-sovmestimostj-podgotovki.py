"""Сравнить кэшированную подготовку C1 и совместимого API на синтетике."""
import importlib.util
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time
import types
from unittest import mock


КОРЕНЬ = Path(__file__).resolve().parents[3]
ПУТЬ = "Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py"
ОСНОВА = "436909208424595f7151f6febca75f89018c0bcb"


def загрузить(имя, данные):
    модуль = types.ModuleType(имя)
    модуль.__file__ = str(КОРЕНЬ / ПУТЬ)
    sys.modules[имя] = модуль
    exec(compile(данные, модуль.__file__, "exec"), модуль.__dict__)
    return модуль


def главная():
    до = загрузить("подготовка_до", subprocess.check_output(
        ["git", "-C", str(КОРЕНЬ), "show", ОСНОВА + ":" + ПУТЬ]))
    после = загрузить("подготовка_после", (КОРЕНЬ / ПУТЬ).read_bytes())
    путь_теста = КОРЕНЬ / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests/test_братиславская_проекция_памяти.py"
    spec = importlib.util.spec_from_file_location("фикстуры_подготовки", путь_теста)
    тесты = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(тесты)
    записи = []
    for пара in range(7):
        порядок = [("до", до, {}), ("после", после, {"использовать_кэш": True})]
        if пара % 2:
            порядок.reverse()
        for вариант, модуль, параметры in порядок:
            тесты.модуль = модуль
            пример = тесты.ПроверкаКонтрактаБратиславскойПроекции()
            пример.подготовить_испытание()
            try:
                пример._записать("Инструменты/fum-proverka-nazvanij-avtomatizacij/Package.swift",
                                "// swift-tools-version: 6.0\n")
                пример._зафиксировать()
                _, _, ревизия = пример._создать_репозиторий_зависимости()
                сборок = 0

                def собрать(пакет, каталог, граница, **kwargs):
                    nonlocal сборок
                    сборок += 1
                    граница()
                    каталог.mkdir()
                    for имя in модуль.ИМЕНА_ИСПОЛНЯЕМОЙ_СРЕДЫ:
                        файл = каталог / имя
                        файл.write_bytes(b"fixture")
                        файл.chmod(0o755)
                    граница()
                    return [str(каталог / "preobrazovatj-nazvaniya")]

                with mock.patch.object(модуль, "РЕВИЗИЯ_ЗАВИСИМОСТИ", ревизия), \
                     mock.patch.object(модуль, "собрать_изолированный_продукт", side_effect=собрать), \
                     mock.patch.object(модуль, "сведения_для_повторной_сборки", return_value=({}, "swift")):
                    for стадия in ("холодная", "повторная"):
                        начало = time.perf_counter_ns()
                        cpu = time.process_time_ns()
                        with модуль.подготовить_изолированный_преобразователь(пример.корень, **параметры) as (команда, граница):
                            assert len(команда) == 1
                            assert Path(команда[0]).read_bytes() == b"fixture"
                            assert Path(команда[0]).parent.name == "исполнение"
                            граница()
                        записи.append({"пара": пара, "вариант": вариант, "стадия": стадия,
                                       "wall_ns": time.perf_counter_ns() - начало,
                                       "cpu_родителя_ns": time.process_time_ns() - cpu,
                                       "всего_сборок": сборок})
                        assert сборок == 1
            finally:
                пример.завершить_испытание()
    медианы = {вариант: {стадия: statistics.median(
        x["wall_ns"] for x in записи if x["вариант"] == вариант and x["стадия"] == стадия)
        for стадия in ("холодная", "повторная")} for вариант in ("до", "после")}
    print(json.dumps({"схема": "fum.профиль-совместимости-подготовки.1", "основа": ОСНОВА,
                      "граница": "Семь чередующихся пар с отдельными временными Git-фикстурами; создание фикстур исключено. Продукт и сведения Swift синтетические: стоимость компилятора, CPU дочерних процессов и память не измерены. Проверены байты частной копии и одна сборка на два входа.",
                      "измерения": записи, "медианы_wall_ns": медианы}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    главная()
