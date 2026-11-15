"""Чистые функции имени роли и загрузочный отпечаток проверяемого исходника."""
import hashlib
from pathlib import Path
import re

КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


РОЛЬ = r"FUM (?:Codex|[А-ЯЁ][А-Яа-яЁё]*(?:[ -][А-Яа-яЁё]+)*)"
ТОКЕН = r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}"
НЕИЗВЕСТНО = frozenset({"unknown", "unavailable", "unset", "null"})
ПОЛНОЕ_ИМЯ = re.compile(rf"({РОЛЬ}) \[({ТОКЕН}); effort=({ТОКЕН})\]")


def проверить_роль(роль):
    return isinstance(роль, str) and re.fullmatch(РОЛЬ, роль) is not None


def проверить_свежую_роль(роль):
    """Новый эффект Codex; исторический parser сохраняет прежние роли."""
    return isinstance(роль, str) and роль == "FUM Codex"


def проверить_назначение_автора(назначение, запрос):
    """Сверяет поля; доверенный выбор назначения проверяет вызывающий допуск."""
    поля = {"исполнитель", "ветка", "основа", "роль"}
    if (type(назначение) is not dict or set(назначение) != поля | {"схема"}
            or назначение.get("схема") != "fum.назначение-автора.1"
            or type(запрос) is not dict or set(запрос) != поля):
        return False
    if any(type(назначение.get(поле)) is not str or not назначение[поле]
           or назначение[поле] != запрос[поле] for поле in поля):
        return False
    роль = назначение["роль"]
    return (re.fullmatch(r"[A-Z][A-Za-z]*(?: [A-Za-z]+)*", роль) is not None
            and роль.lower() not in НЕИЗВЕСТНО
            and роль not in {"Root", "FUM Codex"}
            and назначение["ветка"].startswith("refs/heads/")
            and re.fullmatch(r"[0-9a-f]{40}", назначение["основа"]) is not None)


def проверить_токен(значение):
    return (isinstance(значение, str) and re.fullmatch(ТОКЕН, значение) is not None
            and значение.lower() not in НЕИЗВЕСТНО)


def составить_имя(роль, наблюдение):
    """Происхождение наблюдения проверяет вызывающий импортёр native JSONL."""
    if not проверить_роль(роль):
        raise ValueError("неверный формат роли автора")
    if not isinstance(наблюдение, dict):
        raise ValueError("нужно подтверждённое наблюдение модели и усилия")
    модель, усилие = наблюдение.get("модель"), наблюдение.get("усилие")
    if not проверить_токен(модель) or not проверить_токен(усилие):
        raise ValueError("модель и усилие автора должны быть известными безопасными токенами")
    return f"{роль} [{модель}; effort={усилие}]"


def проверить_формат(имя):
    """Историческая роль допустима для чтения; сравнение identity остаётся точным."""
    if проверить_роль(имя):
        return True
    совпадение = ПОЛНОЕ_ИМЯ.fullmatch(имя) if isinstance(имя, str) else None
    return (совпадение is not None and проверить_токен(совпадение[2])
            and проверить_токен(совпадение[3]))
