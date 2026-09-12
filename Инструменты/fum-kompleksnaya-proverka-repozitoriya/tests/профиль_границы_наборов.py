"""Три воспроизводимых замера выбора наборов без вызова Swift."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import tempfile
import time

import test_run_smoke_check as фикстуры


def измерить(имя, действие, события):
    начало = time.perf_counter_ns()
    исход = "неуспешно"
    try:
        результат = действие()
        исход = "успешно"
        return результат
    finally:
        события.append({"этап": имя, "длительность_наносекунды": time.perf_counter_ns() - начало,
                        "исход": исход, "вложенность": 0})


def главный():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--выход", required=True, type=Path)
    параметры = парсер.parse_args()
    исполнитель = фикстуры.run_smoke_check
    повторы = []
    for номер in range(3):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            помощник = фикстуры.RunSmokeCheckTests()
            помощник.write_script_fixture(корень)
            помощник.создать_фикстуры_документационных_тестов(корень)
            интеграционный = корень / "Инструменты/fum-kompleksnaya-proverka-repozitoriya/интеграционные-тесты"
            интеграционный.mkdir()
            (интеграционный / "test_композиция.py").write_text("import unittest\n")
            for индекс in range(100):
                каталог = корень / "Инструменты" / f"образец-{индекс:03d}" / "tests"
                каталог.mkdir(parents=True)
                (каталог / "test_образец.py").write_text("import unittest\n")
            события = []
            наборы = измерить("обнаружение", lambda: исполнитель.discover_test_dirs(корень), события)
            планы = {}
            for профиль in (исполнитель.ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ, исполнитель.ПОЛНЫЙ_ПРОФИЛЬ):
                планы[профиль] = измерить(профиль, lambda: исполнитель.build_steps(
                    корень, None, include_session=False, swift="недопустимый-процесс-профиля", профиль=профиль), события)
            assert len(наборы) == 114
            assert len(планы[исполнитель.ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ]) == 23
            ключ = интеграционный.relative_to(корень).as_posix()
            assert not any(шаг.аналитический_ключ == ключ for шаг in планы[исполнитель.ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ])
            assert sum(шаг.аналитический_ключ == ключ for шаг in планы[исполнитель.ПОЛНЫЙ_ПРОФИЛЬ]) == 1
            повторы.append({"повтор": номер + 1, "наборов": len(наборы), "события": события})
    корень_кода = Path(__file__).resolve().parents[3]
    пути = [Path(__file__), Path(исполнитель.__file__), Path(фикстуры.__file__),
            Path(__file__).resolve().parents[1] / "интеграционные-тесты/test_реальной_композиции.py"]
    результат = {"схема": "fum.профиль-границы-наборов.1", "python": platform.python_version(),
                 "код": {путь.resolve().relative_to(корень_кода).as_posix(): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in пути},
                 "граница": "Подготовка фикстур исключена. Swift-пакетов нет; процессы тестов, сборки и lint не запускаются.",
                 "повторы": повторы, "медианы_наносекунды": {имя: statistics.median(
                     событие["длительность_наносекунды"] for повтор in повторы for событие in повтор["события"] if событие["этап"] == имя)
                     for имя in ("обнаружение", исполнитель.ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ, исполнитель.ПОЛНЫЙ_ПРОФИЛЬ)}}
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(результат["медианы_наносекунды"], ensure_ascii=False))


if __name__ == "__main__":
    главный()
