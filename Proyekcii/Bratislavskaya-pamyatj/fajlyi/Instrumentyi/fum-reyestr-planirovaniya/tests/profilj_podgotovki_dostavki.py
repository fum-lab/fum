"""Импорт, конструирование и очистка открытой Git-фикстуры без тел тестов."""
import argparse
import hashlib
import importlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import tempfile
import time
from unittest.mock import patch

from наблюдение_процессов_фикстуры import НаблюдательПроцессов


def измерить(повторы):
    if not 1 <= повторы <= 20:
        raise ValueError("Число повторов должно быть от 1 до 20")
    каталог = Path(__file__).resolve().parent
    файлы = [Path(__file__), каталог / "наблюдение_процессов_фикстуры.py",
             каталог / "test_обратная_доставка.py", *sorted((каталог.parent / "scripts").glob("*.py"))]
    результат = {
        "схема": "fum.профиль-подготовки-доставки.1",
        "python": platform.python_version(),
        "модуль_уже_загружен": "test_обратная_доставка" in sys.modules,
        "git": subprocess.run(["git", "--version"], capture_output=True, text=True, check=True).stdout.strip(),
        "исходники_sha256": {str(путь.relative_to(каталог.parent)): hashlib.sha256(путь.read_bytes()).hexdigest()
                              for путь in файлы},
        "граница": "Импорт один раз на процесс; запуск Python и импорт измерителя исключены. "
                   "Создание временной папки исключено. Конструктор и cleanup измерены отдельно. "
                   "Метки включены в замер; их отдельная цена неизвестна. "
                   "Время Git вложено в стадии и не прибавляется к ним. Тела тестов не запускались.",
        "стадии": [], "процессы": [], "ошибка": None, "ошибки": [],
    }
    наблюдатель = НаблюдательПроцессов(subprocess.run)

    def стадия(имя, повтор, действие):
        наблюдатель.стадия = имя
        наблюдатель.повтор = повтор
        начало = time.monotonic_ns()
        исход = "исключение"
        try:
            значение = действие()
            исход = "успешно"
            return значение
        except Exception as ошибка:
            результат["ошибки"].append({"стадия": имя, "повтор": повтор, "тип": type(ошибка).__name__})
            raise
        finally:
            результат["стадии"].append({"стадия": имя, "повтор": повтор, "исход": исход,
                                        "длительность_наносекунды": time.monotonic_ns() - начало})

    try:
        with patch.object(subprocess, "run", наблюдатель):
            модуль = стадия("импорт", 0, lambda: importlib.import_module("test_обратная_доставка"))
            for номер in range(1, повторы + 1):
                папка = tempfile.TemporaryDirectory(prefix="fum-профиль-подготовки-")
                try:
                    стадия("подготовка", номер, lambda: модуль.Фикстура(папка.name))
                finally:
                    первичная = sys.exc_info()[1]
                    try:
                        стадия("очистка", номер, папка.cleanup)
                    except Exception:
                        if первичная is None:
                            raise
    except Exception as ошибка:
        результат["ошибка"] = type(ошибка).__name__
    результат["процессы"] = наблюдатель.записи
    результат["медианы_наносекунды"] = {
        имя: int(statistics.median(запись["длительность_наносекунды"] for запись in результат["стадии"]
                                  if запись["стадия"] == имя and запись["исход"] == "успешно"))
        for имя in ("подготовка", "очистка")
        if any(запись["стадия"] == имя and запись["исход"] == "успешно" for запись in результат["стадии"])
    }
    результат["git_по_командам"] = {
        имя: {"число": sum(запись["команда"] == имя for запись in наблюдатель.записи),
              "длительность_наносекунды": sum(запись["длительность_наносекунды"] for запись in наблюдатель.записи
                                               if запись["команда"] == имя)}
        for имя in sorted({запись["команда"] for запись in наблюдатель.записи})
    }
    return результат


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    разбор.add_argument("--повторы", type=int, choices=range(1, 21), default=3)
    аргументы = разбор.parse_args()
    результат = измерить(аргументы.повторы)
    аргументы.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"медианы_наносекунды": результат["медианы_наносекунды"],
                      "git_по_командам": результат["git_по_командам"], "ошибка": результат["ошибка"]}, ensure_ascii=False))
    raise SystemExit(1 if результат["ошибка"] else 0)
