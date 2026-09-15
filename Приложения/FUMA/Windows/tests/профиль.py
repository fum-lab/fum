"""Профиль подготовки команд; не измеряет Windows, компилятор или runtime."""
import hashlib
import importlib.util
import json
import pathlib
import platform
import statistics
import time

путь = pathlib.Path(__file__).parents[1] / 'собрать.py'
описание = importlib.util.spec_from_file_location('сборка', путь)
сборка = importlib.util.module_from_spec(описание)
описание.loader.exec_module(сборка)
хэш = hashlib.sha256(путь.read_bytes()).hexdigest()
замеры = []
for повтор in range(5):
    начало = time.perf_counter_ns()
    for номер in range(1000):
        команды = сборка.план('пакет', 'кэш', 'выход', 'сценарий-runtime', 'arm64', 'определение', 'вход', 'контейнер')
        assert len(команды) == 3
    замеры.append(time.perf_counter_ns() - начало)
assert hashlib.sha256(путь.read_bytes()).hexdigest() == хэш
print(json.dumps({'схема': 'fum.windows.профиль-плана.1', 'sha256': хэш, 'Python': platform.python_version(), 'ОС': platform.system(), 'повторов': 5, 'планов_на_повтор': 1000, 'замеры_нс': замеры, 'медиана_нс': statistics.median(замеры)}, ensure_ascii=False, indent=2))
