import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import subprocess
import time

РАЗБОР = argparse.ArgumentParser()
РАЗБОР.add_argument("--корень", type=Path, required=True)
РАЗБОР.add_argument("--вывод", type=Path, required=True)
АРГУМЕНТЫ = РАЗБОР.parse_args()
КОРЕНЬ = АРГУМЕНТЫ.корень.resolve()
АРТЕФАКТЫ = АРГУМЕНТЫ.вывод.resolve()
АРТЕФАКТЫ.mkdir(parents=True, exist_ok=False)
if not __debug__:
    raise SystemExit("Проверки Python отключены")
СЦЕНАРИЙ = КОРЕНЬ / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py"
спецификация = importlib.util.spec_from_file_location("проекция", СЦЕНАРИЙ)
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)
снимок = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=КОРЕНЬ).decode().strip()
хэш_сценария = hashlib.sha256(СЦЕНАРИЙ.read_bytes()).hexdigest()
измерения = []
результат = {"исходный_HEAD": снимок, "зависимость": модуль.РЕВИЗИЯ_ЗАВИСИМОСТИ,
             "сценарий_sha256": хэш_сценария,
             "измеритель_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "машина": platform.machine(),
             "Swift": subprocess.check_output(["swift", "--version"]).decode().strip(),
             "измерения": измерения}
def сохранить():
    путь = АРТЕФАКТЫ / "сравнение-debug-release.json"
    with путь.open("w") as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
        поток.flush()
        os.fsync(поток.fileno())
def выполнить(метка, команда, вход=None):
    начало = time.perf_counter_ns()
    ответ = subprocess.run(команда, input=вход, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, timeout=180)
    длительность = time.perf_counter_ns() - начало
    запись = {"метка": метка, "длительность_нс": длительность, "код": ответ.returncode,
              "выход_sha256": hashlib.sha256(ответ.stdout).hexdigest()}
    if вход is not None:
        запись.update({"вход_sha256": hashlib.sha256(вход).hexdigest(), "вход_байты": len(вход)})
    измерения.append(запись)
    сохранить()
    print(метка, round(длительность / 1e9, 6), "с", flush=True)
    return ответ.stdout

with модуль.подготовить_изолированный_преобразователь(КОРЕНЬ) as (команда, граница):
    пакет = Path(команда[команда.index("--package-path") + 1])
    сборки = пакет.parents[1] / "сравнение"
    продукты = {}
    for конфигурация in ("debug", "release"):
        основа = ["swift", "build", "--quiet", "--configuration", конфигурация,
                  "--package-path", str(пакет), "--scratch-path", str(сборки / конфигурация)]
        граница()
        выполнить("сборка " + конфигурация, основа + ["--product", "preobrazovatj-nazvaniya"])
        граница()
        каталог = Path(выполнить("каталог " + конфигурация, основа + ["--show-bin-path"]).decode().strip())
        продукты[конфигурация] = [str(каталог / "preobrazovatj-nazvaniya")]
    набор = ["Ж", "Ж Ж", "Ж а АА", "а АА Ж а", "Ж АА Ж", "ЖЖ", "ё Ё е\u0308 Е\u0308",
             "Привет FUM! / Съешь ещё этих мягких французских булок."]
    набор += ["Ж " * размер for размер in (512, 1024, 2048)]
    пути = ["AGENTS.md", "Правила/агентов/проверки-коммит-и-публикация.md"]
    набор += [subprocess.check_output(["git", "show", снимок + ":" + путь], cwd=КОРЕНЬ).decode() for путь in пути]
    вход = (json.dumps(набор, ensure_ascii=False) + "\n").encode()
    (АРТЕФАКТЫ / "вход-сравнения-debug-release.json").write_bytes(вход)
    результат["набор"] = {"строк": len(набор), "целые_документы": пути,
                          "байты": len(вход), "sha256": hashlib.sha256(вход).hexdigest()}
    эталон = None
    for повтор in range(3):
        for конфигурация in (("debug", "release") if повтор % 2 == 0 else ("release", "debug")):
            граница()
            выход = выполнить("преобразование " + конфигурация + " " + str(повтор), продукты[конфигурация], вход)
            граница()
            строки = json.loads(выход)
            assert isinstance(строки, list) and len(строки) == len(набор)
            if эталон is None:
                эталон = строки
            assert [строка.encode() for строка in строки] == [строка.encode() for строка in эталон]
    результат["совпадение_всех_строк_UTF8"] = True
    сохранить()
assert hashlib.sha256(СЦЕНАРИЙ.read_bytes()).hexdigest() == хэш_сценария
print("Точное совпадение всех строк подтверждено.", flush=True)
