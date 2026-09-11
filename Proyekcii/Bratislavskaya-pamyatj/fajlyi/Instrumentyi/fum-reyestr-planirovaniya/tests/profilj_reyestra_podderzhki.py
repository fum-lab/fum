#!/usr/bin/env python3
"""Воспроизводимый профиль сохранённых 16 организаций без сети и мутации входа."""
import argparse
import hashlib
from pathlib import Path
import platform
import resource
import sys

КОРЕНЬ = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(КОРЕНЬ / "Инструменты/fum-reyestr-planirovaniya/scripts"))
import реестр_поддержки as реестр
sys.path.insert(0, str(КОРЕНЬ / "Инструменты/fum-snimki-indeksa/scripts"))
from профиль import Профиль


def главный():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--выход", type=Path, required=True)
    парсер.add_argument("--дата", default="2026-09-11")
    парсер.add_argument("--повторы", type=int, default=7)
    параметры = парсер.parse_args()
    реестр.требовать(1 <= параметры.повторы <= 100, "Число повторов вне границы")
    вход = КОРЕНЬ / "Планирование/финансирование-и-ресурсы/карточки.json"
    исследование = КОРЕНЬ / "Журнал/2026-09-11_13-39-59_MSK_принять-направление-финансирования-FUM/материалы/исследования/организации-поддержки-FUM.json"
    профиль = Профиль()
    образец = None
    for повтор in range(параметры.повторы):
        with профиль.стадия("Полный повтор"):
            with профиль.стадия("Чтение входных данных"):
                данные = реестр.разобрать(вход.read_bytes())
                исходник = реестр.разобрать(исследование.read_bytes())
            результат = реестр.сформировать(данные, исходник, параметры.дата, КОРЕНЬ, профиль)
            if образец is None:
                образец = результат
            реестр.требовать(образец == результат, "Профиль обнаружил недетерминированный результат")
    исходники = [Path(__file__).resolve(), Path(реестр.__file__), КОРЕНЬ / "Инструменты/fum-reyestr-planirovaniya/scripts/реестр-организаций-поддержки.py", КОРЕНЬ / "Инструменты/fum-reyestr-planirovaniya/шаблоны/список-поддержки.md.шаблон", КОРЕНЬ / "Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py", КОРЕНЬ / "Инструменты/fum-proyektnyiye-fajlyi/scripts/project_files.py", КОРЕНЬ / "Инструменты/fum-snimki-indeksa/scripts/профиль.py"]
    отчёт = {"схема": "fum.профиль-реестра-поддержки.1", "дата_расчёта": параметры.дата, "Python": platform.python_version(),
        "система": platform.system(), "архитектура": platform.machine(), "повторы": параметры.повторы,
        "организаций": len(данные["организации"]), "вход_sha256": hashlib.sha256(вход.read_bytes()).hexdigest(),
        "исходное_исследование_sha256": hashlib.sha256(исследование.read_bytes()).hexdigest(),
        "исходники": {путь.relative_to(КОРЕНЬ).as_posix(): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники},
        "измерения": профиль.записи, "максимальная_память_байты": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * (1 if sys.platform == "darwin" else 1024),
        "границы": "Прогретый процесс; чтение сохранённых файлов, проверка хэшей свидетельств, оценка и рендер. Сеть, старт Python и запись выпуска не измеряются. Вложенные интервалы не суммируются с полным повтором.",
        "результаты_sha256": {имя: hashlib.sha256(текст.encode()).hexdigest() for имя, текст in образец.items()}}
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    параметры.выход.write_bytes(реестр.байты(отчёт))
    print(реестр.байты({"повторы": параметры.повторы, "максимальный_повтор_мс": max(запись["длительность_наносекунды"] for запись in профиль.записи if запись["стадия"] == "Полный повтор") / 1e6}).decode(), end="")


if __name__ == "__main__":
    главный()
