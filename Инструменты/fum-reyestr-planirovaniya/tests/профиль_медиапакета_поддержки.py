"""Воспроизводимые замеры v2; подготовка входа и запись профиля вне интервалов."""
import argparse
import hashlib
from pathlib import Path
import platform
import subprocess
import sys
import time

КОРЕНЬ_КОДА = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from медиапакет_поддержки import собрать, прочитать_вход
from реестр_поддержки import байты


def исходники():
    пути = {Path(__file__).resolve()}
    for модуль in tuple(sys.modules.values()):
        имя = getattr(модуль, "__file__", None)
        if имя is not None:
            путь = Path(имя).resolve()
            if путь.is_relative_to(КОРЕНЬ_КОДА) and путь.suffix == ".py":
                пути.add(путь)
    пути.update((КОРЕНЬ_КОДА / "Инструменты/fum-reyestr-planirovaniya/шаблоны").glob("*поддержки.шаблон.txt"))
    return {str(путь.relative_to(КОРЕНЬ_КОДА)): hashlib.sha256(путь.read_bytes()).hexdigest()
            for путь in sorted(пути)}


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", required=True)
    разбор.add_argument("--вход", required=True)
    разбор.add_argument("--выход", required=True)
    разбор.add_argument("--повторы", type=int, default=10)
    аргументы = разбор.parse_args()
    if not 2 <= аргументы.повторы <= 100:
        raise ValueError("Нужно от 2 до 100 повторов")
    корень = Path(аргументы.корень)
    сырой_вход = Path(аргументы.вход).read_bytes()
    данные = прочитать_вход(аргументы.вход)
    хэши_до = исходники()
    длительности = []
    хэши = []
    for номер in range(аргументы.повторы):
        начало = time.perf_counter_ns()
        результат = собрать(корень, данные)
        длительности.append(time.perf_counter_ns() - начало)
        хэши.append(hashlib.sha256(байты(результат)).hexdigest())
    if len(set(хэши)) != 1 or исходники() != хэши_до or Path(аргументы.вход).read_bytes() != сырой_вход:
        raise ValueError("Изменился вход, код или результат серии")
    профиль = {
        "схема": "fum.профиль-медиапакета.2", "python": platform.python_version(),
        "git": subprocess.check_output(["git", "--version"], text=True).strip(),
        "платформа": platform.system(), "архитектура": platform.machine(),
        "повторы": аргументы.повторы, "вход_sha256": hashlib.sha256(сырой_вход).hexdigest(),
        "исходники": хэши_до, "длительности_наносекунды": длительности,
        "результат_sha256": хэши[0], "измеряемая_граница": "собрать: Git-чтение, проверка, шаблоны",
        "подготовка_и_запись_исключены": True, "кэш_ОС": "не очищался",
        "критерий_оптимизации": "медиана более 500 мс требует исследования",
    }
    with Path(аргументы.выход).open("xb") as поток:
        поток.write(байты(профиль))
    print(байты(профиль).decode(), end="")


if __name__ == "__main__":
    выполнить()
