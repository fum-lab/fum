#!/usr/bin/env python3
"""Реальный guard v2 на его синтетических Git-фикстурах, без записи в дерево guard."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


НАВЫК = Path(__file__).resolve().parents[1]
АДАПТЕР = НАВЫК / "scripts/перехватить-завершение.py"


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--корень-guard", type=Path, required=True)
    аргументы = парсер.parse_args()
    корень = аргументы.корень_guard.resolve(strict=True)
    навык = корень / "Инструменты/fum-svyaznostj-rabochej-sessii"
    сценарий = навык / "scripts/проверить-продолжение-задачи.py"
    фикстуры = навык / "tests/test_обязательства_задачи.py"
    исходники = [сценарий, навык / "scripts/обязательства_задачи.py", фикстуры]
    def отпечатки():
        return {str(путь.relative_to(корень)): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}
    до = отпечатки()
    sys.dont_write_bytecode = True
    описание = importlib.util.spec_from_file_location("синтетические_обязательства", фикстуры)
    модуль = importlib.util.module_from_spec(описание)
    описание.loader.exec_module(модуль)
    результаты = []
    for режим in ("незавершённое-обязательство", "ожидание", "ошибка", "остановка",
                  "принятый-результат", "незакоммиченная-граница"):
        пример = модуль.ОбязательстваЗадачи()
        try:
            пример.подготовить()
            if режим == "ожидание":
                пример.план["работы"][0].update(состояние="ожидает-ответа", свидетельство="Нужен выбор пользователя.")
            elif режим == "остановка":
                путь = пример.корень / пример.запрос
                путь.write_text(путь.read_text().replace("## Идентификатор", "~~~~text\nОстановись.\n~~~~\n\n## Идентификатор"))
                пример.план.update(остановка={"запрос": пример.запрос, "цитата": "Остановись."}, работы=[])
            elif режим in ("принятый-результат", "незакоммиченная-граница"):
                пример.принять()
                пример.коммит()
                if режим == "незакоммиченная-граница":
                    пример.план["работы"][0]["свидетельство"] += " Уточнена граница отчёта."
            пример.сохранить()
            if режим == "ошибка":
                (пример.корень / пример.путь_реестра).write_text("{")
            проверка = subprocess.run([sys.executable, "-B", str(сценарий),
                                      "--корень-репозитория", str(пример.корень),
                                      "--codex-thread-id", модуль.ИДЕНТИФИКАТОР, "--перед-завершением"],
                                     capture_output=True, timeout=15,
                                     env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
            if режим in ("ошибка", "незакоммиченная-граница"):
                if проверка.returncode != 2 or проверка.stdout or not проверка.stderr:
                    raise RuntimeError("guard не вернул ожидаемую ошибку: " + режим)
                решение = "ошибка"
            else:
                ожидаемое = {"незавершённое-обязательство": "продолжить", "ожидание": "ожидать-ответа",
                             "остановка": "остановлено-пользователем", "принятый-результат": "завершить"}[режим]
                решение = json.loads(проверка.stdout)["решение"]
                if решение != ожидаемое or проверка.returncode != (3 if решение == "продолжить" else 0):
                    raise RuntimeError("неверное решение самого guard: " + режим)
            with tempfile.TemporaryDirectory() as временный:
                состояние = Path(временный).resolve() / "повторы"
                команда = [sys.executable, "-B", str(АДАПТЕР), "--корень-репозитория", str(пример.корень),
                           "--codex-thread-id", модуль.ИДЕНТИФИКАТОР, "--ожидаемый-cwd", str(пример.корень),
                           "--guard", str(сценарий), "--каталог-состояния", str(состояние),
                           "--файл-прогресса", "код.py", "--тайм-аут-backend", "10"]
                событие = {"session_id": модуль.ИДЕНТИФИКАТОР, "cwd": str(пример.корень),
                           "hook_event_name": "Stop", "turn_id": "синтетический-ход", "stop_hook_active": False}
                процесс = subprocess.run(команда, input=json.dumps(событие).encode(),
                                         capture_output=True, timeout=15,
                                         env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
                if процесс.returncode != 0 or процесс.stderr:
                    raise RuntimeError("неверный процесс интеграции")
                ответ = json.loads(процесс.stdout)
                if режим == "незавершённое-обязательство":
                    совпадает = ответ.get("decision") == "block" and "восстанови" in ответ["reason"]
                elif режим in ("ошибка", "незакоммиченная-граница"):
                    совпадает = ответ.get("decision") == "block" and "guard-код" in ответ["reason"]
                elif режим == "остановка":
                    совпадает = ответ.get("continue") is False and "пользователем" in ответ["stopReason"]
                else:
                    совпадает = ответ == {}
                if not совпадает:
                    raise RuntimeError("неверное решение интеграции: " + режим)
                результаты.append({"сценарий": режим, "guard_решение": решение,
                                    "guard_код": проверка.returncode, "успешно": True})
        finally:
            пример.doCleanups()
    if до != отпечатки():
        raise RuntimeError("guard изменился во время интеграционного прогона")
    версия = subprocess.run(["git", "-C", str(корень), "rev-parse", "HEAD"], capture_output=True, check=True).stdout.decode().strip()
    состояние = subprocess.run(["git", "-C", str(корень), "status", "--porcelain", "--",
                                *(str(путь.relative_to(корень)) for путь in исходники)],
                               capture_output=True, check=True).stdout
    print(json.dumps({"схема": "fum.интеграция-Stop.1", "guard_HEAD": версия,
                      "guard_чистый": not bool(состояние), "guard_sha256": до,
                      "адаптер_sha256": hashlib.sha256(АДАПТЕР.read_bytes()).hexdigest(),
                      "сценарии": результаты}, ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
