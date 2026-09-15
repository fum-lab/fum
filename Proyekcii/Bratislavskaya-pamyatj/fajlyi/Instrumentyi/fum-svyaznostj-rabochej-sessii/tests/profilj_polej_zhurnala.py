"""Сравнить ранний отказ с полным обходом на одинаковом синтетическом входе."""

import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import tempfile
import time

from фикстура_полей_журнала import создать_пару
from публикуемый_профиль_полей import представить_профиль

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from проверка_полей_журнала import проверить, связность


def измерить(выход: Path) -> None:
    результаты = []
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный).resolve()
        subprocess.run(["git", "init", "--quiet", str(корень)], check=True)
        запрос = создать_пару(корень)
        фон = корень / "Примеры"
        фон.mkdir()
        for номер in range(1000):
            (фон / f"пример-{номер:04d}.md").write_text("# Пример\n\nОткрытый текст.\n")
        отчёт = запрос.with_name("отчёт.md")
        исходный = отчёт.read_text()
        for случай, текст in (
            ("правильные поля", исходный),
            ("неверная колонка", исходный.replace("Границы и способ измерения", "Граница")),
            ("нет границы", исходный.replace("Граница профиля: только синтетический пример.", "")),
        ):
            отчёт.write_text(текст)
            замеры = {"полный_обход": [], "ранние_поля": []}
            полные_ошибки = []
            ранние_ошибки = []
            входы = None
            for повтор in range(5):
                порядок = ("полный_обход", "ранние_поля") if повтор % 2 == 0 else ("ранние_поля", "полный_обход")
                for режим in порядок:
                    начало = time.perf_counter_ns()
                    if режим == "полный_обход":
                        полные_ошибки = связность.validate_session(
                            корень, запрос, check_git_status=False,
                            expected_codex_thread_id="00000000-0000-0000-0000-000000000000",
                            commit_message="Проверить поля.\n\nCodex-Thread-ID: 00000000-0000-0000-0000-000000000000\n",
                        )
                    else:
                        результат = проверить(корень, запрос)
                        ранние_ошибки = результат["ошибки"]
                        if входы is not None:
                            assert результат["входы"] == входы
                        входы = результат["входы"]
                    замеры[режим].append(time.perf_counter_ns() - начало)
                assert [ошибка for ошибка in полные_ошибки if "journal time profile" in ошибка] == ранние_ошибки
            результаты.append({
                "случай": случай, "входы": входы, "замеры_наносекунды": замеры,
                "медианы_наносекунды": {режим: statistics.median(значения) for режим, значения in замеры.items()},
                "ошибки_раннего_входа": ранние_ошибки,
                "ошибки_полного_входа": полные_ошибки,
            })
    исходники = [Path(__file__), Path(__file__).with_name("фикстура_полей_журнала.py"),
                 Path(связность.__file__), Path(__file__).resolve().parents[1] / "scripts/проверка_полей_журнала.py",
                 Path(__file__).resolve().parents[1] / "scripts/путь_пары_журнала.py",
                 Path(__file__).with_name("публикуемый_профиль_полей.py")]
    данные = {
        "схема": "fum.профиль-полей-журнала.1", "python": platform.python_version(),
        "платформа": platform.system(), "фоновых_документов": 1000,
        "исходники": {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники},
        "результаты": результаты,
        "граница": "Подготовка и импорт исключены; чередуются пять пар запусков. Сравниваются только ошибки профиля. Полный вход дополнительно отклоняет неполную синтетическую сессию. Ранний вход не заменяет полную приёмку. Это время функций, не токены LLM и не ускорение всей рабочей сессии.",
    }
    выход.write_text(json.dumps(представить_профиль(данные, корень), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    измерить(разбор.parse_args().выход)
