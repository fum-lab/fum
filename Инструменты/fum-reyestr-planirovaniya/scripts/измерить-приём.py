"""Открытый профиль выделения номеров и повторного входа."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import tempfile
import time

from приём_направления import Хранилище


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--выход", type=Path, required=True)
    параметры = парсер.parse_args()
    with tempfile.TemporaryDirectory() as имя:
        корень = Path(имя).resolve()
        def команда(*аргументы):
            subprocess.run(["git", *аргументы], cwd=корень, check=True, capture_output=True)
        команда("init", "-q", "-b", "codex/профиль")
        команда("config", "user.name", "Открытая фикстура")
        команда("config", "user.email", "fixture@example.invalid")
        (корень / "Требования").mkdir()
        for номер in range(1, 41):
            (корень / "Требования/пример.md").write_text(f"<!-- FUM-REQUIREMENT-ID: FUM-REQ-{номер:04d} -->\n" + "Открытый воспроизводимый текст.\n" * номер)
            команда("add", ".")
            команда("commit", "-qm", "Открытая история")
        хранилище = Хранилище(корень, "00000000-0000-0000-0000-000000000201")
        измерения = []
        for номер in range(12):
            начало = time.monotonic_ns()
            номера = хранилище.выделить(f"открытый-вход-{номер}", ["FUM-REQ", "FUM-STEP"], "открытая фикстура")
            измерения.append({"стадия": "выделение", "повтор": номер, "длительность_наносекунды": time.monotonic_ns() - начало, "номера": номера})
            начало = time.monotonic_ns()
            повтор = хранилище.выделить(f"открытый-вход-{номер}", ["FUM-REQ", "FUM-STEP"], "открытая фикстура")
            if повтор != номера:
                raise ValueError("Повтор не сохранил результат")
            измерения.append({"стадия": "повтор", "повтор": номер, "длительность_наносекунды": time.monotonic_ns() - начало})
        итог = {"схема": "fum.профиль-приёма.1", "Python": platform.python_version(), "исходник_sha256": hashlib.sha256(Path(__file__).with_name("приём_направления.py").read_bytes()).hexdigest(), "вход": "40 коммитов, 12 независимых входов и 12 повторов; подготовка не измеряется", "измерения": измерения, "метки": хранилище.профиль}
        итог["медианы_наносекунды"] = {стадия: statistics.median(запись["длительность_наносекунды"] for запись in измерения if запись["стадия"] == стадия) for стадия in ("выделение", "повтор")}
        параметры.выход.parent.mkdir(parents=True, exist_ok=True)
        параметры.выход.write_text(json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + "\n")
        print(json.dumps(итог["медианы_наносекунды"], ensure_ascii=False))


if __name__ == "__main__":
    выполнить()
