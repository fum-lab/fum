"""Три адресных замера чтения одного конечного Git-снимка без установки."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import захват_зеркала

разбор = argparse.ArgumentParser()
разбор.add_argument("--корень", type=Path, required=True)
разбор.add_argument("--план", type=Path, required=True)
разбор.add_argument("--sha256", required=True)
разбор.add_argument("--выход", type=Path, required=True)
параметры = разбор.parse_args()
байты = параметры.план.read_bytes()
if hashlib.sha256(байты).hexdigest() != параметры.sha256:
    raise ValueError("ожидаемый план не совпал с независимым SHA256")
план = json.loads(байты)
код = Path(захват_зеркала.__file__)
хэш_кода = hashlib.sha256(код.read_bytes()).hexdigest()
длительности = []
for номер in range(3):
    начало = time.perf_counter_ns()
    результат = захват_зеркала.снять(параметры.корень, план["коммит"], [з["исходник"] for з in план["файлы"]])
    длительности.append(time.perf_counter_ns() - начало)
    if результат != план or hashlib.sha256(код.read_bytes()).hexdigest() != хэш_кода:
        raise ValueError("результат или версия кода изменились в серии")
итог = {"схема": "fum.профиль-захвата-зеркала.1", "коммит": план["коммит"],
        "вход_sha256": параметры.sha256, "код_sha256": хэш_кода,
        "файлов": len(план["файлы"]), "байтов": sum(з["байты"] for з in план["файлы"]),
        "длительности_нс": длительности, "Python": sys.version,
        "граница": "Только снять: Git-процессы и проверка байтов включены; установка и подготовка не включены"}
with параметры.выход.open("x") as поток:
    json.dump(итог, поток, ensure_ascii=False, indent=2)
    поток.write("\n")
print(json.dumps(итог, ensure_ascii=False))
