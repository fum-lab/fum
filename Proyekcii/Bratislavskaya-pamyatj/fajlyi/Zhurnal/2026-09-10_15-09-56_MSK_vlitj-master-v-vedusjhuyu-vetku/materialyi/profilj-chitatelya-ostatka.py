"""Сравнивает два полных CLI-читателя на одной неизменной Git-истории."""
import argparse
import hashlib
import json
from pathlib import Path
import resource
import subprocess
import sys
import time


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    for имя in ("до", "после", "вход", "вывод"):
        разбор.add_argument("--" + имя, type=Path, required=True)
    аргументы = разбор.parse_args()
    относительный = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обязательства_задачи.py"
    пути = [относительный, "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/история_пути_гита.py"]
    пути += ["Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/" + имя for имя in (
        "отчёты_о_запусках_проверок.py", "закрытый_отчёт_из_гита.py", "связь_отпечатка_с_коммитом.py")]
    def отпечатки():
        return {имя: {путь: hashlib.sha256((корень / путь).read_bytes()).hexdigest() for путь in пути}
                for имя, корень in (("до", аргументы.до), ("после", аргументы.после))}
    def вершина():
        return subprocess.run(["git", "--no-optional-locks", "-C", str(аргументы.вход),
                               "rev-parse", "HEAD"], capture_output=True, check=True).stdout.decode().strip()
    исходные = отпечатки()
    исходная_вершина = вершина()
    ответы = set()
    измерения = []
    for повтор in range(3):
        варианты = (("до", аргументы.до), ("после", аргументы.после))
        for имя, корень in варианты if повтор % 2 == 0 else reversed(варианты):
            ресурсы = resource.getrusage(resource.RUSAGE_CHILDREN)
            начало = time.perf_counter_ns()
            процесс = subprocess.run([sys.executable, "-S", "-B", str(корень / относительный),
                                      "--корень-репозитория", str(аргументы.вход)],
                                     capture_output=True, timeout=60)
            if процесс.returncode:
                raise ValueError("читатель завершился ошибкой: " + процесс.stderr.decode("utf-8"))
            длительность = time.perf_counter_ns() - начало
            после = resource.getrusage(resource.RUSAGE_CHILDREN)
            данные = json.loads(процесс.stdout)
            if данные["завершение_задачи_доказано"] or данные["вершина"] != исходная_вершина:
                raise ValueError("неверный результат чтения частичного остатка")
            ответы.add(процесс.stdout)
            измерения.append({"вариант": имя, "повтор": повтор + 1, "длительность_нс": длительность,
                              "процессорное_время_с": после.ru_utime + после.ru_stime - ресурсы.ru_utime - ресурсы.ru_stime})
    if len(ответы) != 1 or вершина() != исходная_вершина or отпечатки() != исходные:
        raise ValueError("вход изменился либо читатели дали разные результаты")
    результат = {"схема": "fum.профиль-слияния-читателей.1", "HEAD_входа": исходная_вершина,
                 "граница": "Три чередующиеся пары полных CLI с -S -B на одной принятой истории; прогрев кэша не контролируется. CPU — дочерние процессы, подготовка отсутствует. Смешанная история и изолированный запуск guard проверяются отдельно.",
                 "исходники": исходные, "измеритель_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                 "результаты_совпали": True, "sha256_ответа": hashlib.sha256(next(iter(ответы))).hexdigest(),
                 "измерения": измерения}
    with аргументы.вывод.open("x", encoding="utf-8") as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
    print(json.dumps(результат, ensure_ascii=False))


if __name__ == "__main__":
    главная()
