#!/usr/bin/env python3
"""Шесть исходов настоящего guard из одного commit через подготовленный комплект."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import resource
import shutil
import statistics
import subprocess
import sys
import tempfile
import time

ПОДГОТОВКА = Path(__file__).with_name("подготовить-комплект-завершения.py")
ФИКСТУРЫ = "Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_обязательства_задачи.py"


def загрузить(путь, имя):
    описание = importlib.util.spec_from_file_location(имя, путь)
    модуль = importlib.util.module_from_spec(описание)
    описание.loader.exec_module(модуль)
    return модуль


def убрать(путь):
    for каталог, _, _ in os.walk(путь):
        Path(каталог).chmod(0o700)
    shutil.rmtree(путь)


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--источник", type=Path, required=True)
    парсер.add_argument("--commit", required=True)
    аргументы = парсер.parse_args()
    sys.dont_write_bytecode = True
    подготовка = загрузить(ПОДГОТОВКА, "подготовка_измерения")
    дерево, записи, исходники = подготовка.источник(аргументы.источник, аргументы.commit)
    идентификатор_фикстуры = подготовка.найти_объект(аргументы.источник, дерево, ФИКСТУРЫ)
    байты_фикстуры = подготовка.объект(аргументы.источник, "blob", идентификатор_фикстуры)
    временный = Path(tempfile.mkdtemp()).resolve()
    результаты = []
    try:
        # Это дерево только для загрузки проверенных синтетических фикстур, не native bundle.
        источник_фикстур = временный / "фикстуры"
        for имя, данные in {**исходники, ФИКСТУРЫ: байты_фикстуры}.items():
            путь = источник_фикстур / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_bytes(данные)
        модуль = загрузить(источник_фикстур / ФИКСТУРЫ, "точная_фикстура")
        хранилище = временный / "комплекты"
        хранилище.mkdir(mode=0o700)
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
                команда = [sys.executable, "-I", "-S", "-B", str(ПОДГОТОВКА),
                           "--источник", str(аргументы.источник), "--commit", аргументы.commit,
                           "--хранилище", str(хранилище), "--интерпретатор", sys.executable,
                           "--корень-репозитория", str(пример.корень), "--ожидаемый-cwd", str(пример.корень),
                           "--codex-thread-id", модуль.ИДЕНТИФИКАТОР,
                           "--каталог-состояния", str(временный / ("состояние-" + режим)),
                           "--файл-прогресса", "код.py"]
                времена_подготовки = []
                предыдущий = None
                for _ in range(2):
                    начало = time.perf_counter_ns()
                    процесс = subprocess.run(команда, capture_output=True, timeout=15)
                    времена_подготовки.append(time.perf_counter_ns() - начало)
                    if процесс.returncode or процесс.stderr:
                        raise RuntimeError("подготовка: " + процесс.stderr.decode())
                    результат = json.loads(процесс.stdout)
                    if предыдущий is not None and результат != предыдущий:
                        raise RuntimeError("подготовка не идемпотентна")
                    предыдущий = результат
                комплект = Path(результат["каталог"])
                проверка = subprocess.run([sys.executable, "-I", "-S", "-B", str(комплект / подготовка.ПУТИ[1]),
                                            "--корень-репозитория", str(пример.корень),
                                            "--codex-thread-id", модуль.ИДЕНТИФИКАТОР, "--перед-завершением"],
                                           capture_output=True, timeout=15, env={"PATH": "/usr/bin:/bin"})
                if режим in ("ошибка", "незакоммиченная-граница"):
                    if проверка.returncode != 2 or проверка.stdout or not проверка.stderr:
                        raise RuntimeError("неверный отказ guard")
                    решение = "ошибка"
                else:
                    решение = json.loads(проверка.stdout)["решение"]
                    ожидаемое = {"незавершённое-обязательство": "продолжить", "ожидание": "ожидать-ответа",
                                 "остановка": "остановлено-пользователем", "принятый-результат": "завершить"}[режим]
                    if решение != ожидаемое or проверка.returncode != (3 if решение == "продолжить" else 0):
                        raise RuntimeError("неверное решение guard")
                событие = {"session_id": модуль.ИДЕНТИФИКАТОР, "cwd": str(пример.корень),
                           "hook_event_name": "Stop", "turn_id": "синтетический-ход", "stop_hook_active": False}
                времена_вызова = []
                for _ in range(3):
                    начало = time.perf_counter_ns()
                    процесс = subprocess.run(["/bin/sh", "-c", результат["кандидат"]["hooks"]["Stop"][0]["hooks"][0]["command"]],
                                             input=json.dumps(событие).encode(), capture_output=True, timeout=15,
                                             env=dict(os.environ, PYTHONPATH=str(источник_фикстур), ПОСТОРОННЕЕ="не наследовать"))
                    времена_вызова.append(time.perf_counter_ns() - начало)
                    if процесс.returncode or процесс.stderr:
                        raise RuntimeError("процесс комплекта")
                    ответ = json.loads(процесс.stdout)
                    if режим == "незавершённое-обязательство":
                        верно = ответ.get("decision") == "block" and "восстанови" in ответ["reason"]
                    elif режим in ("ошибка", "незакоммиченная-граница"):
                        верно = ответ.get("decision") == "block" and "guard-код" in ответ["reason"]
                    elif режим == "остановка":
                        верно = ответ.get("continue") is False and "пользователем" in ответ["stopReason"]
                    else:
                        верно = ответ == {}
                    if not верно:
                        raise RuntimeError("ответ комплекта: " + режим + ": " + json.dumps(ответ, ensure_ascii=False))
                времена_проверки = []
                for _ in range(5):
                    начало = time.perf_counter_ns()
                    подготовка.ПРОВЕРКА["проверить"](комплект, результат["sha256"])
                    времена_проверки.append(time.perf_counter_ns() - начало)
                результаты.append({"сценарий": режим, "успешно": True, "guard_код": проверка.returncode,
                                    "guard_решение": решение, "подготовка_процесс_нс": времена_подготовки,
                                    "горячий_процесс_нс": времена_вызова,
                                    "горячая_проверка_нс": времена_проверки,
                                    "медиана_горячего_процесса_нс": int(statistics.median(времена_вызова))})
            finally:
                пример.doCleanups()
    finally:
        убрать(временный)
    print(json.dumps({"схема": "fum.интеграция-комплекта-Stop.1", "commit": аргументы.commit, "tree": дерево,
                      "файлы": записи, "фикстуры_sha256": hashlib.sha256(байты_фикстуры).hexdigest(),
                      "подготовка_sha256": hashlib.sha256(ПОДГОТОВКА.read_bytes()).hexdigest(),
                      "сценарии": результаты, "максимальная_память_дочерних_процессов": resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
                      "граница_памяти": "Нативная единица ОС; максимум всех дочерних процессов, не отдельного bootstrap.",
                      "граница_профиля": "Первая подготовка и идемпотентный повтор — целые процессы; три горячих вызова включают guard и состояние. Пять проверок целостности измерены отдельно в процессе измерителя."},
                     ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
