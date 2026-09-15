"""Малый открытый профиль пакетного выпуска без сети и реальных карточек."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import time

from test_пакета_диагностики import ПакетДиагностики, ЗАДАЧА, сбой, шаг, выпуск


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--выход", type=Path, required=True)
    параметры = парсер.parse_args()
    измерения = []
    for повтор in range(5):
        фикстура = ПакетДиагностики()
        фикстура.setUp()
        try:
            пакет = {"схема": "fum.пакет-диагностики.1", "сбои": [сбой(номер, статус="устранена", основной=None) for номер in range(81, 86)], "шаги": [шаг(81), шаг(82)]}
            начало = time.monotonic_ns()
            план = выпуск.подготовить(фикстура.корень, ЗАДАЧА, пакет)
            измерения.append({"стадия": "план", "повтор": повтор, "наносекунды": time.monotonic_ns() - начало})
            начало = time.monotonic_ns()
            первый = выпуск.применить(фикстура.корень, ЗАДАЧА, план)
            измерения.append({"стадия": "применение", "повтор": повтор, "наносекунды": time.monotonic_ns() - начало})
            начало = time.monotonic_ns()
            второй = выпуск.применить(фикстура.корень, ЗАДАЧА, план)
            измерения.append({"стадия": "повтор", "повтор": повтор, "наносекунды": time.monotonic_ns() - начало})
            if первый != второй or len(первый) != 9:
                raise ValueError("Неполный либо изменённый повтор пакета")
        finally:
            фикстура.doCleanups()
    каталог = Path(__file__).resolve().parents[1]
    исходники = [Path(__file__), каталог / "tests/test_пакета_диагностики.py", каталог / "scripts/пакет_диагностики.py", каталог / "scripts/приём_направления.py", каталог / "scripts/вход_направления.py", каталог / "scripts/build-planning-registry.py"]
    итог = {"схема": "fum.профиль-пакета-диагностики.1", "версия_интерпретатора": platform.python_version(), "вход": "Пять отдельных открытых репозиториев; в каждом пять СБОЙ, два STEP, два индекса и повтор. Подготовка Git исключена; Git-наблюдение, чтение карточек, файловая синхронизация и замок включены.", "исходники": {str(путь.relative_to(каталог)): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}, "измерения": измерения, "медианы_наносекунды": {стадия: statistics.median(запись["наносекунды"] for запись in измерения if запись["стадия"] == стадия) for стадия in ("план", "применение", "повтор")}}
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    параметры.выход.write_text(json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(итог["медианы_наносекунды"], ensure_ascii=False))


if __name__ == "__main__":
    выполнить()
