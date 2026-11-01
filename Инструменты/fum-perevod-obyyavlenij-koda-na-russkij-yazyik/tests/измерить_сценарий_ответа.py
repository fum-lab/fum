"""Малый профиль синтаксиса и плана; выбранные JS-источники не исполняются."""

import argparse
import hashlib
import importlib.util
import json
import platform
from pathlib import Path
import shutil
import statistics
import subprocess
import sys
import tempfile
from time import perf_counter_ns

корень = Path(__file__).resolve().parents[3]
каталог = корень / "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts"
sys.path.insert(0, str(каталог))
import разбор_сценария as сценарий

спецификация = importlib.util.spec_from_file_location("переводчик_профиля", каталог / "перевести-объявления-кода.py")
переводчик = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = переводчик
спецификация.loader.exec_module(переводчик)


def хэш(байты):
    return hashlib.sha256(байты).hexdigest()


def прочитать_без_ссылок(путь):
    путь = путь.absolute()
    if any(часть.is_symlink() for часть in (путь, *путь.parents)):
        raise ValueError("Ссылка во входе профиля")
    return путь.read_bytes()


def измерить(действие):
    замеры = []
    for _ in range(7):
        начало = perf_counter_ns()
        действие()
        замеры.append(perf_counter_ns() - начало)
    return {"замеры_нс": замеры, "медиана_нс": statistics.median(замеры)}


def профиль(манифест=None, отпечаток=None, карта=None):
    выбранные = манифест is not None
    if выбранные != (отпечаток is not None) or выбранные != (карта is not None):
        raise ValueError("Манифест, его SHA-256 и карта выбираются вместе")
    if выбранные:
        сырые = прочитать_без_ссылок(манифест)
        if хэш(сырые) != отпечаток:
            raise ValueError("SHA-256 манифеста не совпал")
        описание = json.loads(сырые)
        if описание.get("схема") != "fum.ROOT-выбранные-входы-языкового-допуска.1":
            raise ValueError("Неизвестная схема манифеста данных")
        входы = {}
        for запись in описание["данные"]:
            путь = запись["путь"]
            if путь in входы:
                raise ValueError("Повтор входа")
            байты = прочитать_без_ссылок(Path(запись["файл"]))
            if len(байты) != запись["байты"] or хэш(байты) != запись["sha256"]:
                raise ValueError("Изменился закреплённый вход")
            входы[путь] = байты
        if set(входы) != {сценарий.путь_живого_моста, переводчик.путь_живых_вставок}:
            raise ValueError("Ожидаются ровно мост и Python-хост")
        мост = входы[сценарий.путь_живого_моста].decode("utf-8")
        вставки = переводчик.живые_вставки(входы[переводчик.путь_живых_вставок].decode("utf-8"))
        тексты = {сценарий.путь_живого_моста: мост,
                  **{переводчик.методы_живых_вставок[н]: т for н, (_, _, т) in enumerate(вставки)}}
    else:
        входы = {п: (корень / п).read_bytes() for п in sorted(сценарий.пути_сценариев)
                 if п != сценарий.путь_живого_моста}
        тексты = {п: б.decode("utf-8") for п, б in входы.items()}

    def собственный_разбор():
        for текст in тексты.values():
            разбор = сценарий.Разбор(сценарий.токены(текст), живой=выбранные)
            while разбор.следующий():
                разбор.оператор()

    def полный_разбор():
        return {п: сценарий.разобрать(т, живой=выбранные) for п, т in тексты.items()}

    действия = {"лексика": lambda: [сценарий.токены(т) for т in тексты.values()],
                "собственный_разбор_с_лексикой": собственный_разбор,
                "полный_разбор_с_Node": полный_разбор}
    результат = {"схема": "fum.профиль-сценариев-ответа.2", "python": platform.python_version(),
        "node": subprocess.check_output([shutil.which("node"), "--version"], text=True,
                                         env={"LANG": "C", "LC_ALL": "C"}).strip(),
        "платформа": platform.system() + " " + platform.machine(),
        "граница": "Семь повторов каждой стадии в свежем процессе. Чтение, подготовка временного корпуса, импорт и запись вне замеров; стадии перекрываются и не суммируются. Node только проверяет синтаксис. Проектор и живые API не вызываются; ускорение и готовность узла не заявляются.",
        "манифест_sha256": отпечаток,
        "входы": {п: {"байты": len(б), "sha256": хэш(б)} for п, б in входы.items()},
        "сценарии": {п: {"байты": len(т.encode()), "sha256": хэш(т.encode())} for п, т in тексты.items()},
        "объявления": полный_разбор(),
        "реализация": {п.relative_to(корень).as_posix(): хэш(п.read_bytes()) for п in
                      (Path(__file__), Path(сценарий.__file__), Path(переводчик.__file__))}}
    with tempfile.TemporaryDirectory(prefix="fum-языковой-профиль-") as временный:
        данные = Path(временный)
        if выбранные:
            for путь, байты in входы.items():
                файл = данные / путь
                файл.parent.mkdir(parents=True, exist_ok=True)
                файл.write_bytes(байты)
            записи = переводчик.прочитать_карту(карта)
            if {з.путь for з in записи} != set(входы):
                raise ValueError("Карта не покрывает два входных файла")
            действия["план_перевода"] = lambda: переводчик.подготовить_изменения(данные, записи)
            изменения = действия["план_перевода"]()
            результат["карта_sha256"] = хэш(прочитать_без_ссылок(карта))
            результат["план"] = переводчик.описание_плана(изменения, "план")
        результат["измерения"] = {имя: измерить(действие) for имя, действие in действия.items()}
        if выбранные:
            if any((данные / п).read_bytes() != б for п, б in входы.items()):
                raise ValueError("План изменил источник")
            переводчик.атомарно_применить(изменения)
            результат["после_применения"] = {п: {"sha256": хэш((данные / п).read_bytes()),
                "остаток": [о.словарь() for о in переводчик.объявления_одного_файла(данные / п, п)]}
                for п in входы}
    return результат


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", required=True, type=Path)
    разбор.add_argument("--манифест", type=Path)
    разбор.add_argument("--sha256-манифеста")
    разбор.add_argument("--карта", type=Path)
    параметры = разбор.parse_args()
    результат = профиль(параметры.манифест, параметры.sha256_манифеста, параметры.карта)
    with параметры.выход.open("x", encoding="utf-8") as поток:
        поток.write(json.dumps(результат, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    print(json.dumps({и: з["медиана_нс"] for и, з in результат["измерения"].items()}, ensure_ascii=False))
