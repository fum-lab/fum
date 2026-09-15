#!/usr/bin/env python3
"""Открытый профиль полного допуска и адаптера: JSONL 70 МиБ, предел guard 3 с."""
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


НАВЫК = Path(__file__).resolve().parents[1]
КОРЕНЬ = НАВЫК.parents[1]
sys.dont_write_bytecode = True
sys.path.insert(0, str(НАВЫК / "tests"))
import test_обязательства_задачи_v2 as фикстуры


def строка(значение):
    return (json.dumps(значение, ensure_ascii=False, separators=(",", ":")) + "\n").encode()


def отпечатки():
    пути = ["scripts/измерить-допуск-сообщений.py", "tests/test_обязательства_задачи_v2.py",
            "tests/исходник_проверки.py"]
    пути += ["scripts/" + имя for имя in (
        "проверить-продолжение-задачи.py", "перехватить-завершение.py", "обязательства_задачи.py",
        "обязательства_задачи_v2.py", "история_пути_гита.py", "обработка_сообщений.py", "сообщения_задачи.py")]
    файлы = [НАВЫК / путь for путь in пути]
    файлы += [КОРЕНЬ / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts" / имя for имя in (
        "отчёты_о_запусках_проверок.py", "закрытый_отчёт_из_гита.py", "связь_отпечатка_с_коммитом.py")]
    файлы.append(КОРЕНЬ / "Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py")
    return {str(путь.relative_to(КОРЕНЬ)): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in файлы}


def измерить(повторов, выход):
    исходники = отпечатки()
    результаты = []
    for сценарий in ("полный-разбор", "остаток-сообщений", "остаток-обязательств"):
        пример = фикстуры.ОбязательстваЗадачи()
        try:
            пример.подготовить()
            if сценарий != "остаток-обязательств":
                пример.принять()
                пример.коммит()
            блок = строка({"type": "event_msg", "payload": {"type": "fixture", "text": "я" * 2048}})
            with пример.исходник.open("ab") as поток:
                for _ in range(70 * 1024 * 1024 // len(блок) + 1):
                    поток.write(блок)
                if сценарий == "остаток-сообщений":
                    поток.write(строка({"type": "response_item", "payload": {"type": "message", "role": "user",
                        "id": "msg_1", "content": [{"type": "input_text", "text": "Проверь позднее уточнение.\n"}],
                        "internal_chat_message_metadata_passthrough": {"content_item_kinds": ["user.text"]}}}))
            источник_sha = hashlib.sha256(пример.исходник.read_bytes()).hexdigest()
            источник_байтов = пример.исходник.stat().st_size
            ожидается_продолжение = сценарий != "полный-разбор"
            with tempfile.TemporaryDirectory() as каталог:
                временный = Path(каталог).resolve()
                кэш = временный / "не-создавать-кэш.json"
                общие = ["--корень-репозитория", str(пример.корень), "--codex-thread-id", фикстуры.ИДЕНТИФИКАТОР,
                         "--исходник", str(пример.исходник), "--кэш", str(кэш), "--профиль"]
                допуск = НАВЫК / "scripts/проверить-продолжение-задачи.py"
                for повтор in range(1, повторов + 1):
                    for вход in ("допуск", "адаптер"):
                        команда = [sys.executable, "-I", "-S", "-B"]
                        событие = None
                        if вход == "допуск":
                            команда += [str(допуск), *общие, "--перед-завершением"]
                        else:
                            команда += [str(НАВЫК / "scripts/перехватить-завершение.py"), *общие,
                                "--ожидаемый-cwd", str(пример.корень), "--guard", str(допуск),
                                "--каталог-состояния", str(временный / f"повтор-{повтор}"), "--файл-прогресса", "код.py"]
                            событие = строка({"session_id": фикстуры.ИДЕНТИФИКАТОР, "cwd": str(пример.корень),
                                "hook_event_name": "Stop", "turn_id": "открытая-проверка", "stop_hook_active": False})
                        начало = time.perf_counter_ns()
                        процесс = subprocess.run(команда, input=событие, capture_output=True, timeout=8)
                        длительность = time.perf_counter_ns() - начало
                        ответ = json.loads(процесс.stdout)
                        if вход == "допуск":
                            assert процесс.returncode == (3 if ожидается_продолжение else 0), процесс.stderr
                            assert ответ["схема"] == "fum.решение-продолжения.3"
                            assert ответ["решение"] == ("продолжить" if ожидается_продолжение else "завершить")
                            assert ответ["сообщения"]["остаток"] == (1 if сценарий == "остаток-сообщений" else 0)
                        else:
                            assert процесс.returncode == 0
                            if ожидается_продолжение:
                                assert ответ.get("decision") == "block"
                                assert "восстанови" in ответ["reason"] or "остаток сообщений" in ответ["reason"]
                            else:
                                assert ответ == {}, ответ
                        assert len(процесс.stdout) < 65536
                        assert str(пример.исходник).encode() not in процесс.stdout
                        профили = []
                        for запись in процесс.stderr.decode().splitlines():
                            assert запись.startswith("FUM-PROFILE "), запись
                            профили.append(json.loads(запись.removeprefix("FUM-PROFILE ")))
                        assert len(профили) == 1
                        результаты.append({"сценарий": сценарий, "вход": вход, "повтор": повтор,
                            "исходник_sha256": источник_sha, "исходник_байтов": источник_байтов,
                            "длительность_нс": длительность, "код": процесс.returncode,
                            "вывод_байтов": len(процесс.stdout), "профиль": профили[0]})
                assert not кэш.exists()
            assert hashlib.sha256(пример.исходник.read_bytes()).hexdigest() == источник_sha
        finally:
            пример.doCleanups()
    assert исходники == отпечатки()
    медианы = {сценарий: {вход: statistics.median(запись["длительность_нс"] for запись in результаты
                 if запись["сценарий"] == сценарий and запись["вход"] == вход)
                 for вход in ("допуск", "адаптер")} for сценарий in ("полный-разбор", "остаток-сообщений", "остаток-обязательств")}
    профиль = {"схема": "fum.профиль-допуска-сообщений.1", "python": platform.python_version(),
        "платформа": platform.system(), "git": subprocess.run(["git", "--version"], capture_output=True, check=True, text=True).stdout.strip(),
        "код_sha256": исходники, "предел_guard_секунды": 3, "предел_вывода_байты": 65536,
        "граница": "Включён запуск изолированного Python, полная проверка обязательств, чтение JSONL и заключительная сверка. Подготовка открытых фикстур исключена; кэш ФС не сбрасывался. Адаптер запускается с новым частным состоянием в каждом повторе и штатным пределом guard 3 с. Вложенные интервалы не суммируются.",
        "запуски": результаты, "медианы_нс": медианы}
    выход.write_text(json.dumps(профиль, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(медианы, ensure_ascii=False))


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--повторов", type=int, default=3)
    разбор.add_argument("--выход", type=Path, required=True)
    аргументы = разбор.parse_args()
    if not 1 <= аргументы.повторов <= 21:
        разбор.error("число повторов должно быть от 1 до 21")
    измерить(аргументы.повторов, аргументы.выход)
