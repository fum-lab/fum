"""Автономная проверка планового манифеста; не материализует зависимости."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
import time


def прочитать_json(текст):
    def уникальные(пары):
        результат = {}
        for ключ, значение in пары:
            if ключ in результат:
                raise ValueError("Повтор JSON-поля: " + ключ)
            результат[ключ] = значение
        return результат
    return json.loads(текст, object_pairs_hook=уникальные)


def безопасный_путь(корень, относительный):
    путь = Path(относительный)
    if путь.is_absolute() or not путь.parts or any(часть in (".", "..") for часть in путь.parts):
        raise ValueError("Недопустимый относительный путь")
    текущий = корень.resolve()
    for часть in путь.parts:
        текущий = текущий / часть
        if текущий.is_symlink():
            raise ValueError("Символическая ссылка в источнике")
    if not текущий.is_file():
        raise ValueError("Отсутствует обычный файл: " + относительный)
    return текущий


ОБЯЗАТЕЛЬНЫЕ_ВХОДЫ = frozenset(("macOS", "Xcode", "SDK", "bootstrap-Swift", "Python", "CMake", "SWIG", "Bison", "упаковка", "Python-установка"))


def проверить(данные, корень, требовать_готовность=False):
    if данные["схема"] != "fum.план-комплекта-Swift.1":
        raise ValueError("Неизвестная схема")
    снимки = {}
    for снимок in данные["снимки"]:
        путь = снимок["путь"]
        if путь in снимки or not путь.startswith("Источники/"):
            raise ValueError("Повтор либо неканонический источник")
        хэш = hashlib.sha256(безопасный_путь(корень, путь).read_bytes()).hexdigest()
        if хэш != снимок["sha256"]:
            raise ValueError("Изменились байты: " + путь)
        снимки[путь] = хэш
    профиль = данные["профиль"]
    if hashlib.sha256(безопасный_путь(корень, профиль["путь"]).read_bytes()).hexdigest() != профиль["sha256"]:
        raise ValueError("Изменился профиль")
    if данные["upstream_preset"] not in снимки:
        raise ValueError("Полный upstream preset не закреплён")
    if данные["конфигурация"] not in снимки:
        raise ValueError("Конфигурация не закреплена снимком")
    конфигурация = прочитать_json(безопасный_путь(корень, данные["конфигурация"]).read_text())
    ожидаемые = set(конфигурация["branch-schemes"][данные["схема_веток"]]["repos"])
    закрепление = данные["закрепление_OID"]
    байты = безопасный_путь(корень, закрепление["путь"]).read_bytes()
    if hashlib.sha256(байты).hexdigest() != закрепление["sha256"]:
        raise ValueError("Изменилось свидетельство OID")
    наблюдения = прочитать_json(байты.decode("utf-8"))["репозитории"]
    пины = {}
    for запись in наблюдения:
        if запись["имя"] in пины or not запись["refs"]:
            raise ValueError("Повтор либо пустое наблюдение refs")
        ссылка = "refs/tags/" + запись["tag"]
        oid = запись["refs"].get(ссылка + "^{}", запись["refs"].get(ссылка))
        if oid != запись["oid"]:
            raise ValueError("OID расходится с наблюдением ref")
        пины[запись["имя"]] = oid
    if set(пины) != ожидаемые:
        raise ValueError("Свидетельство не покрывает полную схему")
    имена = set()
    for репозиторий in данные["репозитории"]:
        имя = репозиторий["имя"]
        if имя in имена or not re.fullmatch("[0-9a-f]{40}", репозиторий["oid"]):
            raise ValueError("Повтор либо неполный OID: " + имя)
        if репозиторий["oid"] != пины[имя]:
            raise ValueError("OID расходится с закреплённым свидетельством: " + имя)
        имена.add(имя)
        if not репозиторий["лицензии"] and not репозиторий["ограничение_лицензии"]:
            raise ValueError("Отсутствует лицензия без явного препятствия: " + имя)
        if any(путь not in снимки for путь in репозиторий["лицензии"]):
            raise ValueError("Лицензия не закреплена: " + имя)
    if имена != ожидаемые:
        raise ValueError("Состав не совпадает с полной выбранной схемой update-checkout")
    if not ОБЯЗАТЕЛЬНЫЕ_ВХОДЫ <= {вход["имя"] for вход in данные["входы"]}:
        raise ValueError("Пропущен обязательный вход профиля")
    for вход in данные["входы"]:
        if вход["имя"] in имена:
            raise ValueError("Повтор имени входа")
        имена.add(вход["имя"])
        if вход["sha256"] is not None and not re.fullmatch("[0-9a-f]{64}", вход["sha256"]):
            raise ValueError("Неверный SHA-256 входа")
    for ребро in данные["рёбра"]:
        if ребро["от"] not in имена or ребро["к"] not in имена or not ребро["условие"]:
            raise ValueError("Неизвестная связь либо отсутствующее условие")
    # Плановая проверка не исполняет сборку и не может удостоверить её готовность.
    готов = False
    if данные["готовность_сборки"] is not False:
        raise ValueError("Плановый контракт не разрешает объявлять готовность сборки")
    if not данные["препятствия"] or данные["полнота_исходников"] is not False:
        raise ValueError("Непринятый профиль требует явных препятствий и незамкнутого статуса")
    if требовать_готовность:
        raise ValueError("Сборка закрыта явными препятствиями манифеста")
    return {"репозиториев": len(ожидаемые), "снимков": len(снимки), "рёбер": len(данные["рёбра"]), "готовность_сборки": готов}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", type=Path, required=True)
    разбор.add_argument("--манифест", type=Path, required=True)
    разбор.add_argument("--требовать-готовность", action="store_true")
    разбор.add_argument("--повторов", type=int, default=1)
    аргументы = разбор.parse_args()
    if not 1 <= аргументы.повторов <= 20:
        разбор.error("Число повторов должно быть от 1 до 20")
    try:
        данные = прочитать_json(аргументы.манифест.read_text())
        интервалы = []
        for _ in range(аргументы.повторов):
            начало = time.perf_counter_ns()
            результат = проверить(данные, аргументы.корень, аргументы.требовать_готовность)
            интервалы.append(time.perf_counter_ns() - начало)
        print(json.dumps({**результат, "проверка_наносекунды": интервалы}, ensure_ascii=False))
    except (OSError, ValueError, KeyError, TypeError) as ошибка:
        print(str(ошибка), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(главная())
