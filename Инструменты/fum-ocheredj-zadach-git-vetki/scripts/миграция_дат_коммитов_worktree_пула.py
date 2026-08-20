#!/usr/bin/env python3
"""Чистое ядро доказуемой миграции дат Git-коммитов worktree-пула.

Модуль не меняет Git refs и файлы: он доказывает даты, строит новые
байты commit-объектов и канонические данные для ограждённой транзакции.
"""

from __future__ import annotations

import copy
import hashlib
import json
import re
import shlex
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


СХЕМА_ДОКАЗАТЕЛЬСТВА = "fum.доказательство-миграции-даты-коммита-worktree-пула.1"
СХЕМА_ДОКАЗАТЕЛЬСТВА_ПОТОМКА = "fum.доказательство-перезаписи-потомка-миграции-дат-коммитов-worktree-пула.1"
СХЕМА_ПЛАНА = "fum.план-миграции-дат-коммитов-worktree-пула.1"
СХЕМА_МИГРИРОВАННОЙ_ПЕРЕДАЧИ = "fum.квитанция-commit-handoff-worktree-линии.4"
СХЕМА_МИГРИРОВАННОГО_РЕЗУЛЬТАТА = "fum.квитанция-результата-worktree-подузла.4"
ПРОСТРАНСТВО_АРХИВОВ = "refs/fum/архивы-миграции-дат-коммитов-worktree-подузлов"
ПРОСТРАНСТВО_АРХИВОВ_СОСТОЯНИЯ = "refs/fum/архивы-миграции-дат-состояния-worktree-подузлов"
ПРОСТРАНСТВО_КВИТАНЦИЙ = "refs/fum/квитанции-миграции-дат-коммитов-worktree-подузлов"
ФИКТИВНАЯ_ДАТА = "946684800 +0000"


class ОшибкаМиграцииДат(Exception):
    """Ограждённый отказ ядра миграции."""

    def __init__(сам, состояние: str, сообщение: str) -> None:
        super().__init__(сообщение)
        сам.состояние = состояние


def канонические_байты(значение: object) -> bytes:
    return (
        json.dumps(
            значение,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def хэш_канонического_объекта(значение: object) -> str:
    return "sha256:" + hashlib.sha256(канонические_байты(значение)).hexdigest()


def хэш_сырых_байтов(байты: bytes) -> str:
    return "sha256:" + hashlib.sha256(байты).hexdigest()


def _потребовать(условие: bool, состояние: str, сообщение: str) -> None:
    if not условие:
        raise ОшибкаМиграцииДат(состояние, сообщение)


def _прочитать_журнал(
    источник: str | Path,
) -> list[tuple[dict[str, Any], bytes, int, int]]:
    путь = Path(источник)
    try:
        сырые_данные = путь.read_bytes()
    except OSError as ошибка:
        raise ОшибкаМиграцииДат("migration_source_missing", "Журнал JSONL недоступен.") from ошибка
    результат: list[tuple[dict[str, Any], bytes, int, int]] = []
    смещение = 0
    for индекс, строка_с_разделителем in enumerate(сырые_данные.splitlines(keepends=True)):
        сырая_строка = строка_с_разделителем.rstrip(b"\r\n")
        текущее_смещение = смещение
        смещение += len(строка_с_разделителем)
        if not сырая_строка:
            continue
        try:
            запись = json.loads(сырая_строка)
        except (UnicodeDecodeError, json.JSONDecodeError) as ошибка:
            raise ОшибкаМиграцииДат("migration_source_mismatch", "Журнал JSONL повреждён.") from ошибка
        if not isinstance(запись, dict):
            raise ОшибкаМиграцииДат("migration_source_mismatch", "Запись JSONL имеет неверную форму.")
        результат.append((запись, сырая_строка, индекс, текущее_смещение))
    return результат


def _полезная_нагрузка(запись: dict[str, Any]) -> dict[str, Any] | None:
    нагрузка = запись.get("payload")
    if not isinstance(нагрузка, dict):
        return None
    if запись.get("type") == "response_item":
        return нагрузка
    if запись.get("type") in {"custom_tool_call", "custom_tool_call_output"}:
        return {"type": запись.get("type"), **нагрузка}
    return нагрузка


def _разобрать_метку_всемирного_времени(значение: object) -> int:
    if not isinstance(значение, str):
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Успешный ответ не имеет UTC timestamp.")
    нормализованное = значение[:-1] + "+00:00" if значение.endswith("Z") else значение
    try:
        метка = datetime.fromisoformat(нормализованное)
    except ValueError as ошибка:
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Timestamp ответа имеет неверный формат.") from ошибка
    if метка.tzinfo is None or метка.utcoffset() != timezone.utc.utcoffset(метка):
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Timestamp ответа должен быть UTC.")
    return int(метка.timestamp())


def _проверить_вызов_мутации(
    вход: object,
    идентификатор_задачи: str,
    идентификатор_назначения: str | None,
) -> str:
    """Связывает output с exact мутирующей командой, а не с посторонним exec."""
    раскрытый_вход: object = вход
    if isinstance(вход, str):
        try:
            раскрытый_вход = json.loads(вход)
        except json.JSONDecodeError:
            литералы_команды = re.findall(
                r"(?:^|[{,]\s*)(?:cmd|\"cmd\")\s*:\s*(\"(?:\\.|[^\"\\])*\")",
                вход,
            )
            if len(литералы_команды) > 1:
                raise ОшибкаМиграцииДат("migration_source_ambiguous", "Exact call содержит несколько cmd literals.")
            if литералы_команды:
                try:
                    раскрытый_вход = {"cmd": json.loads(литералы_команды[0])}
                except json.JSONDecodeError as ошибка:
                    raise ОшибкаМиграцииДат("migration_source_mismatch", "cmd literal в exact call невалиден.") from ошибка
            else:
                раскрытый_вход = вход
    if isinstance(раскрытый_вход, dict):
        команда = раскрытый_вход.get("cmd")
    else:
        команда = раскрытый_вход
    if not isinstance(команда, str):
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact call не содержит команды.")
    try:
        токены = shlex.split(команда)
    except ValueError as ошибка:
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact call содержит невалидную команду.") from ошибка
    операции = {"передать-линию", "зафиксировать-результат"}.intersection(токены)
    if len(операции) != 1:
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact call не является терминальной мутацией линии.")

    def имеет_точный_аргумент(флаг: str, значение: str) -> bool:
        return any(
            токен == f"{флаг}={значение}"
            or (токен == флаг and индекс + 1 < len(токены) and токены[индекс + 1] == значение)
            for индекс, токен in enumerate(токены)
        )

    if not имеет_точный_аргумент("--task-id", идентификатор_задачи):
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact call связан с иным task-id.")
    if идентификатор_назначения is not None and not имеет_точный_аргумент(
        "--идентификатор-назначения",
        идентификатор_назначения,
    ):
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact call связан с иным assignment.")
    return next(iter(операции))


def _терминальные_ответы(нагрузка: dict[str, Any]) -> list[dict[str, Any]]:
    вывод = нагрузка.get("output")
    тексты: list[str] = []
    if isinstance(вывод, str):
        тексты.append(вывод)
    elif isinstance(вывод, list):
        for часть in вывод:
            if isinstance(часть, dict) and isinstance(часть.get("text"), str):
                тексты.append(часть["text"])
    найденные_ответы: list[dict[str, Any]] = []
    for текст in тексты:
        try:
            значение = json.loads(текст)
        except json.JSONDecodeError:
            continue
        if isinstance(значение, dict) and "exit_code" in значение:
            if значение.get("exit_code") != 0 or not isinstance(значение.get("output"), str):
                continue
            for строка in значение["output"].splitlines():
                try:
                    внутреннее = json.loads(строка)
                except json.JSONDecodeError:
                    continue
                if isinstance(внутреннее, dict):
                    найденные_ответы.append(внутреннее)
        elif isinstance(значение, dict):
            найденные_ответы.append(значение)
    return [
        ответ
        for ответ in найденные_ответы
        if ответ.get("state") in {"result_frozen", "committed_handoff"}
    ]


def доказать_дату_коммита(
    источник_журнала: str | Path,
    источник_журнала_ссылки: bytes | str,
    *,
    идентификатор_задачи: str,
    идентификатор_вызова: str,
    идентификатор_коммита: str,
    хэш_квитанции: str,
    ссылка_ветки: str,
    идентификатор_назначения: str | None = None,
    вид_операции: str | None = None,
) -> dict[str, Any]:
    """Доказывает секунду commit только совпавшими output и branch reflog."""

    записи = _прочитать_журнал(источник_журнала)
    сессии = [
        (запись, сырые, индекс, смещение)
        for запись, сырые, индекс, смещение in записи
        if запись.get("type") == "session_meta"
    ]
    вызовы = [
        (запись, сырые, индекс, смещение)
        for запись, сырые, индекс, смещение in записи
        if (нагрузка := _полезная_нагрузка(запись)) is not None
        and нагрузка.get("type") == "custom_tool_call"
        and нагрузка.get("call_id") == идентификатор_вызова
        and нагрузка.get("name") == "exec"
    ]
    ответы_вызова = [
        (запись, сырые, индекс, смещение)
        for запись, сырые, индекс, смещение in записи
        if (нагрузка := _полезная_нагрузка(запись)) is not None
        and нагрузка.get("type") == "custom_tool_call_output"
        and нагрузка.get("call_id") == идентификатор_вызова
    ]
    if not сессии or not вызовы or not ответы_вызова:
        raise ОшибкаМиграцииДат("migration_source_missing", "Не найдено полное доказательство в JSONL.")
    for совпадения in (вызовы, ответы_вызова):
        if len(совпадения) != 1:
            raise ОшибкаМиграцииДат("migration_source_ambiguous", "Доказательство в JSONL неоднозначно.")
    for запись_сессии, _сырые, _индекс, _смещение in сессии:
        нагрузка_сессии = запись_сессии.get("payload")
        if not isinstance(нагрузка_сессии, dict) or нагрузка_сессии.get("id") != идентификатор_задачи:
            raise ОшибкаМиграцииДат("migration_source_mismatch", "session_meta относится к иной задаче.")
    сессии_до_вызова = [сессия for сессия in сессии if сессия[2] <= вызовы[0][2]]
    сессия_доказательства = (сессии_до_вызова or сессии)[-1]
    нагрузка_вызова = _полезная_нагрузка(вызовы[0][0])
    if нагрузка_вызова is None or нагрузка_вызова.get("status") not in (None, "completed"):
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact custom_tool_call не завершён.")
    операция = _проверить_вызов_мутации(
        нагрузка_вызова.get("input"),
        идентификатор_задачи,
        идентификатор_назначения,
    )
    if вид_операции is not None and операция != вид_операции:
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact call имеет иной вид мутирующей операции.")
    нагрузка_ответа = _полезная_нагрузка(ответы_вызова[0][0])
    if нагрузка_ответа is None:
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact output не имеет полезной нагрузки.")
    найденные_терминальные_ответы = _терминальные_ответы(нагрузка_ответа)
    if len(найденные_терминальные_ответы) > 1:
        raise ОшибкаМиграцииДат("migration_source_ambiguous", "Exact output содержит несколько терминальных ответов.")
    if not найденные_терминальные_ответы:
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Exact output не содержит терминального ответа.")
    терминальный_ответ = найденные_терминальные_ответы[0]
    ожидаемое_состояние = "result_frozen" if операция == "зафиксировать-результат" else "committed_handoff"
    поле_идентификатора_объекта = {
        терминальный_ответ.get(ключ)
        for ключ in ("вершина_результата", "вершина_резулта", "новая_вершина")
    }
    хэши_квитанций = {
        терминальный_ответ.get(ключ)
        for ключ in ("хэш_квитанции_результата", "хэш_квитанции_передачи")
    }
    if (
        терминальный_ответ.get("state") != ожидаемое_состояние
        or идентификатор_коммита not in поле_идентификатора_объекта
        or хэш_квитанции not in хэши_квитанций
        or (
            идентификатор_назначения is not None
            and терминальный_ответ.get("идентификатор_назначения", идентификатор_назначения)
            != идентификатор_назначения
        )
    ):
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Успешный output не совпадает с OID и квитанцией.")
    ответы = ответы_вызова

    сырые_журналы_ссылок = источник_журнала_ссылки.encode("utf-8") if isinstance(источник_журнала_ссылки, str) else источник_журнала_ссылки
    строки_журнала_ссылки = [строка for строка in сырые_журналы_ссылок.splitlines() if строка]
    if not строки_журнала_ссылки:
        raise ОшибкаМиграцииДат("migration_source_missing", "Exact branch reflog не найден.")
    шаблон = re.compile(
        rb"^(?P<oid>[0-9a-f]{40}|[0-9a-f]{64})\t(?P<ref>refs/[^\t]+)@\{(?P<epoch>[0-9]+) (?P<zone>[+-][0-9]{4})\}(?:\t.*)?$"
    )
    точные_записи: list[tuple[int, bytes]] = []
    for строка in строки_журнала_ссылки:
        совпадение = шаблон.fullmatch(строка)
        if совпадение is None:
            raise ОшибкаМиграцииДат("migration_source_mismatch", "Branch reflog содержит невалидную строку.")
        if (
            совпадение.group("oid").decode("ascii") == идентификатор_коммита
            and совпадение.group("ref").decode("utf-8") == ссылка_ветки
        ):
            точные_записи.append((int(совпадение.group("epoch")), строка))
    if not точные_записи:
        raise ОшибкаМиграцииДат("migration_source_missing", "Exact branch reflog не найден.")
    if len(точные_записи) != 1:
        raise ОшибкаМиграцииДат("migration_source_ambiguous", "Exact branch reflog неоднозначен.")
    эпоха_журнала_ссылки, сырая_строка_журнала_ссылки = точные_записи[0]
    эпоха_ответа = _разобрать_метку_всемирного_времени(ответы[0][0].get("timestamp"))
    if эпоха_журнала_ссылки != эпоха_ответа:
        raise ОшибкаМиграцииДат("migration_source_mismatch", "Секунды output и branch reflog расходятся.")
    return {
        "schema": СХЕМА_ДОКАЗАТЕЛЬСТВА,
        "task_id": идентификатор_задачи,
        "call_id": идентификатор_вызова,
        "assignment_id": идентификатор_назначения,
        "operation": операция,
        "old_oid": идентификатор_коммита,
        "branch_ref": ссылка_ветки,
        "receipt_hash": хэш_квитанции,
        "commit_timestamp": эпоха_ответа,
        "git_date": f"{эпоха_ответа} +0000",
        "source_records": {
            "session": {"index": сессия_доказательства[2], "offset": сессия_доказательства[3]},
            "call": {"index": вызовы[0][2], "offset": вызовы[0][3]},
            "output": {"index": ответы[0][2], "offset": ответы[0][3]},
        },
        "source_hashes": {
            "session_record_hash": хэш_сырых_байтов(сессия_доказательства[1]),
            "call_record_hash": хэш_сырых_байтов(вызовы[0][1]),
            "output_record_hash": хэш_сырых_байтов(ответы[0][1]),
            "reflog_record_hash": хэш_сырых_байтов(сырая_строка_журнала_ссылки),
        },
    }


def _идентификатор_коммита(сырые_байты: bytes, длина_идентификатора_объекта: int) -> str:
    заголовок = f"commit {len(сырые_байты)}\0".encode("ascii")
    if длина_идентификатора_объекта == 40:
        return hashlib.sha1(заголовок + сырые_байты).hexdigest()
    if длина_идентификатора_объекта == 64:
        return hashlib.sha256(заголовок + сырые_байты).hexdigest()
    raise ОшибкаМиграцииДат("migration_object_format_invalid", "Длина Git OID не поддерживается.")


def _разобрать_коммит(сырые_байты: bytes) -> tuple[list[bytes], bytes, list[str], str]:
    заголовок, разделитель, сообщение = сырые_байты.partition(b"\n\n")
    if разделитель != b"\n\n":
        raise ОшибкаМиграцииДат("migration_commit_invalid", "Commit не имеет границы сообщения.")
    строки = заголовок.splitlines()
    родители: list[str] = []
    даты: list[str] = []
    for строка in строки:
        if строка.startswith(b"parent "):
            try:
                родители.append(строка[7:].decode("ascii"))
            except UnicodeDecodeError as ошибка:
                raise ОшибкаМиграцииДат("migration_commit_invalid", "Parent OID повреждён.") from ошибка
        if строка.startswith((b"author ", b"committer ")):
            совпадение = re.fullmatch(rb"(?:author|committer) .+ <[^\n<>]+> ([0-9]+ [+-][0-9]{4})", строка)
            if совпадение is None:
                raise ОшибкаМиграцииДат("migration_commit_invalid", "Identity/date header повреждён.")
            даты.append(совпадение.group(1).decode("ascii"))
    if len(даты) != 2 or даты[0] != даты[1]:
        raise ОшибкаМиграцииДат("migration_commit_date_mismatch", "Author и committer dates неоднозначны.")
    return строки, сообщение, родители, даты[0]


def _заменить_коммит(
    строки: list[bytes],
    сообщение: bytes,
    соответствие_идентификаторов_объектов: Mapping[str, str],
    новая_дата: str | None,
) -> bytes:
    новые_строки: list[bytes] = []
    for строка in строки:
        if строка.startswith(b"parent "):
            родитель = строка[7:].decode("ascii")
            новые_строки.append(b"parent " + соответствие_идентификаторов_объектов.get(родитель, родитель).encode("ascii"))
        elif новая_дата is not None and строка.startswith((b"author ", b"committer ")):
            префикс, разделитель, _ = строка.rpartition(b" ")
            префикс, разделитель_эпохи, _ = префикс.rpartition(b" ")
            if not разделитель or not разделитель_эпохи:
                raise ОшибкаМиграцииДат("migration_commit_invalid", "Date header невозможно заменить.")
            новые_строки.append(префикс + b" " + новая_дата.encode("ascii"))
        else:
            новые_строки.append(строка)
    return b"\n".join(новые_строки) + b"\n\n" + сообщение


def переписать_цепочку_коммитов(
    объекты: Mapping[str, bytes],
    доказательства: Mapping[str, Mapping[str, Any]],
    *,
    длина_идентификатора_объекта: int | None = None,
) -> dict[str, Any]:
    """Топологически переписывает defect-seed и всех их потомков."""

    if not объекты or not доказательства:
        raise ОшибкаМиграцииДат("migration_inventory_empty", "Инвентарь миграции пуст.")
    длина = длина_идентификатора_объекта or len(next(iter(объекты)))
    разобранные: dict[str, tuple[list[bytes], bytes, list[str], str]] = {}
    for идентификатор_объекта_миграции, сырые_байты in объекты.items():
        _потребовать(_идентификатор_коммита(сырые_байты, длина) == идентификатор_объекта_миграции, "migration_commit_oid_mismatch", "Raw commit не совпадает с old OID.")
        разобранные[идентификатор_объекта_миграции] = _разобрать_коммит(сырые_байты)
    if not set(доказательства).issubset(объекты):
        raise ОшибкаМиграцииДат("migration_proof_object_missing", "Proof ссылается на отсутствующий commit.")
    порядок: list[str] = []
    оставшиеся = list(объекты)
    обработанные: set[str] = set()
    while оставшиеся:
        сдвиг = False
        for идентификатор_объекта_миграции in list(оставшиеся):
            родители = разобранные[идентификатор_объекта_миграции][2]
            if all(родитель not in объекты or родитель in обработанные for родитель in родители):
                порядок.append(идентификатор_объекта_миграции)
                обработанные.add(идентификатор_объекта_миграции)
                оставшиеся.remove(идентификатор_объекта_миграции)
                сдвиг = True
        if not сдвиг:
            raise ОшибкаМиграцииДат("migration_commit_graph_invalid", "Граф commits содержит цикл.")

    соответствие_идентификаторов_объектов: dict[str, str] = {}
    новые_объекты: dict[str, bytes] = {}
    записи_коммитов: list[dict[str, Any]] = []
    for прежний_идентификатор_объекта in порядок:
        строки, сообщение, родители, исходная_дата = разобранные[прежний_идентификатор_объекта]
        доказательство = доказательства.get(прежний_идентификатор_объекта)
        родитель_изменён = any(родитель in соответствие_идентификаторов_объектов for родитель in родители)
        if доказательство is None and not родитель_изменён:
            continue
        новая_дата: str | None = None
        причина = "изменён_родитель"
        if доказательство is not None:
            if доказательство.get("old_oid") != прежний_идентификатор_объекта:
                raise ОшибкаМиграцииДат("migration_proof_oid_mismatch", "Proof относится к иному commit.")
            новая_дата = доказательство.get("git_date")
            if not isinstance(новая_дата, str) or re.fullmatch(r"[0-9]+ \+0000", новая_дата) is None:
                raise ОшибкаМиграцииДат("migration_proof_date_invalid", "Proof содержит неверную Git date.")
            if исходная_дата != ФИКТИВНАЯ_ДАТА or новая_дата == ФИКТИВНАЯ_ДАТА:
                raise ОшибкаМиграцииДат("migration_seed_date_invalid", "Seed не имеет ожидаемой legacy-даты.")
            причина = "исправлена_дата"
        новые_байты = _заменить_коммит(строки, сообщение, соответствие_идентификаторов_объектов, новая_дата)
        новый_идентификатор_объекта = _идентификатор_коммита(новые_байты, длина)
        if новый_идентификатор_объекта == прежний_идентификатор_объекта:
            raise ОшибкаМиграцииДат("migration_commit_unchanged", "Затронутый commit не изменился.")
        соответствие_идентификаторов_объектов[прежний_идентификатор_объекта] = новый_идентификатор_объекта
        новые_объекты[новый_идентификатор_объекта] = новые_байты
        записи_коммитов.append(
            {
                "old_oid": прежний_идентификатор_объекта,
                "new_oid": новый_идентификатор_объекта,
                "причина": причина,
                "исходная_дата": исходная_дата,
                "новая_дата": новая_дата or исходная_дата,
                "старые_родители": list(родители),
                "новые_родители": [соответствие_идентификаторов_объектов.get(родитель, родитель) for родитель in родители],
            }
        )
    return {
        "порядок": [идентификатор_объекта_миграции for идентификатор_объекта_миграции in порядок if идентификатор_объекта_миграции in соответствие_идентификаторов_объектов],
        "соответствие_oid": соответствие_идентификаторов_объектов,
        "новые_объекты": новые_объекты,
        "коммиты": записи_коммитов,
    }


def построить_доказательство_перезаписи_потомка(
    запись_перезаписи: Mapping[str, Any],
    *,
    хэши_доказательств_семян: Mapping[str, str],
    хэш_плана: str,
) -> dict[str, Any]:
    """Строит closed proof хорошо датированного потомка, сменившего только parents."""
    прежний_идентификатор_объекта = запись_перезаписи.get("old_oid")
    новый_идентификатор_объекта = запись_перезаписи.get("new_oid")
    старые_родители = запись_перезаписи.get("старые_родители")
    новые_родители = запись_перезаписи.get("новые_родители")
    исходная_дата = запись_перезаписи.get("исходная_дата")
    новая_дата = запись_перезаписи.get("новая_дата")
    длина_идентификатора_объекта = len(прежний_идентификатор_объекта) if isinstance(прежний_идентификатор_объекта, str) else 0
    if (
        длина_идентификатора_объекта not in (40, 64)
        or not isinstance(новый_идентификатор_объекта, str)
        or len(новый_идентификатор_объекта) != длина_идентификатора_объекта
        or re.fullmatch(r"[0-9a-f]+", прежний_идентификатор_объекта) is None
        or re.fullmatch(r"[0-9a-f]+", новый_идентификатор_объекта) is None
        or прежний_идентификатор_объекта == новый_идентификатор_объекта
        or запись_перезаписи.get("причина") != "изменён_родитель"
        or not isinstance(старые_родители, list)
        or not isinstance(новые_родители, list)
        or len(старые_родители) != len(новые_родители)
        or старые_родители == новые_родители
        or исходная_дата != новая_дата
        or исходная_дата == ФИКТИВНАЯ_ДАТА
    ):
        raise ОшибкаМиграцииДат("migration_descendant_proof_invalid", "Запись не доказывает parent-only перезапись хорошо датированного потомка.")
    if re.fullmatch(r"sha256:[0-9a-f]{64}", хэш_плана) is None or not хэши_доказательств_семян:
        raise ОшибкаМиграцииДат("migration_descendant_proof_invalid", "План или seed proofs не связаны с потомком.")
    for идентификатор_семени, хэш_доказательства in хэши_доказательств_семян.items():
        if re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", идентификатор_семени) is None or re.fullmatch(r"sha256:[0-9a-f]{64}", хэш_доказательства) is None:
            raise ОшибкаМиграцииДат("migration_descendant_proof_invalid", "Хэш seed proof невалиден.")
    return {
        "schema": СХЕМА_ДОКАЗАТЕЛЬСТВА_ПОТОМКА,
        "old_oid": прежний_идентификатор_объекта,
        "new_oid": новый_идентификатор_объекта,
        "reason": "parent_only",
        "old_parents": copy.deepcopy(старые_родители),
        "new_parents": copy.deepcopy(новые_родители),
        "git_date": исходная_дата,
        "seed_proof_hashes": dict(sorted(хэши_доказательств_семян.items())),
        "plan_hash": хэш_плана,
    }


def построить_план_миграции(
    *,
    идентификатор_репозитория: str,
    идентификатор_пула: str,
    переписывание: Mapping[str, Any],
    доказательства: Mapping[str, Mapping[str, Any]],
    ссылки_веток: Mapping[str, str],
    ссылки_очередей: Mapping[str, str],
    ссылки_маршрутов: Mapping[str, str],
    преобразования_ссылок: Mapping[str, Mapping[str, str]] | None = None,
) -> dict[str, Any]:
    """Строит канонический dry-plan без raw objects и локальных путей."""

    соответствие = переписывание.get("соответствие_oid")
    коммиты = переписывание.get("коммиты")
    порядок = переписывание.get("порядок")
    if not isinstance(соответствие, dict) or not isinstance(коммиты, list) or not isinstance(порядок, list):
        raise ОшибкаМиграцииДат("migration_rewrite_invalid", "Результат перезаписи повреждён.")
    основа: dict[str, Any] = {
        "schema": СХЕМА_ПЛАНА,
        "repository_identity": идентификатор_репозитория,
        "pool_oid": идентификатор_пула,
        "порядок": copy.deepcopy(порядок),
        "соответствие_oid": copy.deepcopy(соответствие),
        "коммиты": copy.deepcopy(коммиты),
        "доказательства": copy.deepcopy(dict(доказательства)),
        "branch_refs": dict(sorted(ссылки_веток.items())),
        "queue_refs": dict(sorted(ссылки_очередей.items())),
        "route_refs": dict(sorted(ссылки_маршрутов.items())),
        "ref_updates": copy.deepcopy(dict(преобразования_ссылок or {})),
    }
    if set(основа["доказательства"]) != set(доказательства):
        raise ОшибкаМиграцииДат("migration_proof_invalid", "Набор proofs повреждён.")
    основа["хэш_плана"] = хэш_канонического_объекта(основа)
    return основа


def _построить_мигрированную_квитанцию(
    старая_квитанция: Mapping[str, Any],
    старые_байты: bytes,
    доказательство: Mapping[str, Any],
    соответствие_идентификаторов_объектов: Mapping[str, str],
    *,
    хэш_старой_квитанции: str,
    схема: str,
) -> dict[str, Any]:
    канонические_старые_байты = канонические_байты(старая_квитанция)
    if старые_байты != канонические_старые_байты or хэш_старой_квитанции != хэш_канонического_объекта(старая_квитанция):
        raise ОшибкаМиграцииДат("migration_receipt_previous_mismatch", "Legacy receipt bytes/hash не совпали с exact канонической квитанцией.")
    старая_голова = старая_квитанция.get("head_oid")
    if not isinstance(старая_голова, str) or старая_голова not in соответствие_идентификаторов_объектов:
        raise ОшибкаМиграцииДат("migration_receipt_head_mismatch", "Голова legacy receipt не имеет exact мигрированного OID.")
    новая_голова = соответствие_идентификаторов_объектов[старая_голова]
    схема_доказательства = доказательство.get("schema")
    if схема_доказательства == СХЕМА_ДОКАЗАТЕЛЬСТВА:
        доказана_голова = доказательство.get("old_oid") == старая_голова
    elif схема_доказательства == СХЕМА_ДОКАЗАТЕЛЬСТВА_ПОТОМКА:
        доказана_голова = (
            доказательство.get("old_oid") == старая_голова
            and доказательство.get("new_oid") == новая_голова
            and доказательство.get("reason") == "parent_only"
            and re.fullmatch(r"sha256:[0-9a-f]{64}", str(доказательство.get("plan_hash"))) is not None
        )
    else:
        доказана_голова = False
    if not доказана_голова:
        raise ОшибкаМиграцииДат("migration_receipt_proof_mismatch", "Proof не доказывает exact old/new head legacy receipt.")
    новая = copy.deepcopy(dict(старая_квитанция))
    новая["schema"] = схема
    новая["предыдущая_квитанция"] = copy.deepcopy(dict(старая_квитанция))
    новая["хэш_предыдущей_квитанции"] = хэш_старой_квитанции
    новая["хэш_байтов_предыдущей_квитанции"] = хэш_сырых_байтов(старые_байты)
    новая["замещает"] = хэш_старой_квитанции
    новая["доказательство_миграции"] = copy.deepcopy(dict(доказательство))
    новая["хэш_доказательства_миграции"] = хэш_канонического_объекта(доказательство)
    старая_база = старая_квитанция.get("base_oid")
    новая["old_base_oid"] = старая_база
    новая["old_head_oid"] = старая_голова
    if isinstance(старая_база, str):
        новая["base_oid"] = соответствие_идентификаторов_объектов.get(старая_база, старая_база)
    if isinstance(старая_голова, str):
        новая["head_oid"] = соответствие_идентификаторов_объектов.get(старая_голова, старая_голова)
    if isinstance(старая_квитанция.get("commits"), list):
        старые_коммиты = copy.deepcopy(старая_квитанция["commits"])
        новая["old_commits"] = старые_коммиты
        новая["commits"] = [
            соответствие_идентификаторов_объектов.get(идентификатор_объекта_миграции, идентификатор_объекта_миграции) if isinstance(идентификатор_объекта_миграции, str) else идентификатор_объекта_миграции
            for идентификатор_объекта_миграции in старые_коммиты
        ]
    return новая


def построить_квитанцию_мигрированной_передачи(
    старая_квитанция: Mapping[str, Any],
    старые_байты: bytes,
    доказательство: Mapping[str, Any],
    соответствие_идентификаторов_объектов: Mapping[str, str],
    *,
    хэш_старой_квитанции: str,
) -> dict[str, Any]:
    return _построить_мигрированную_квитанцию(
        старая_квитанция,
        старые_байты,
        доказательство,
        соответствие_идентификаторов_объектов,
        хэш_старой_квитанции=хэш_старой_квитанции,
        схема=СХЕМА_МИГРИРОВАННОЙ_ПЕРЕДАЧИ,
    )


def построить_квитанцию_мигрированного_результата(
    старая_квитанция: Mapping[str, Any],
    старые_байты: bytes,
    доказательство: Mapping[str, Any],
    соответствие_идентификаторов_объектов: Mapping[str, str],
    *,
    хэш_старой_квитанции: str,
) -> dict[str, Any]:
    return _построить_мигрированную_квитанцию(
        старая_квитанция,
        старые_байты,
        доказательство,
        соответствие_идентификаторов_объектов,
        хэш_старой_квитанции=хэш_старой_квитанции,
        схема=СХЕМА_МИГРИРОВАННОГО_РЕЗУЛЬТАТА,
    )


def ссылка_архива_коммита(идентификатор_репозитория: str, прежний_идентификатор_объекта: str) -> str:
    if re.fullmatch(r"[0-9a-f]{64}", идентификатор_репозитория) is None or re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", прежний_идентификатор_объекта) is None:
        raise ОшибкаМиграцииДат("migration_ref_identity_invalid", "Идентичность archive ref повреждена.")
    return f"{ПРОСТРАНСТВО_АРХИВОВ}/{идентификатор_репозитория}/{прежний_идентификатор_объекта}"


def ссылка_архива_состояния(идентификатор_репозитория: str, идентификатор_блоба: str) -> str:
    if re.fullmatch(r"[0-9a-f]{64}", идентификатор_репозитория) is None or re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", идентификатор_блоба) is None:
        raise ОшибкаМиграцииДат("migration_ref_identity_invalid", "Идентичность state archive ref повреждена.")
    return f"{ПРОСТРАНСТВО_АРХИВОВ_СОСТОЯНИЯ}/{идентификатор_репозитория}/{идентификатор_блоба}"


def ссылка_квитанции_миграции(идентификатор_репозитория: str, хэш_квитанции: str) -> str:
    if re.fullmatch(r"[0-9a-f]{64}", идентификатор_репозитория) is None or re.fullmatch(r"sha256:[0-9a-f]{64}", хэш_квитанции) is None:
        raise ОшибкаМиграцииДат("migration_ref_identity_invalid", "Идентичность receipt ref повреждена.")
    return f"{ПРОСТРАНСТВО_КВИТАНЦИЙ}/{идентификатор_репозитория}/{хэш_квитанции[7:]}"


def _форма_указателя(значение: object) -> object:
    if значение is None:
        return None
    if isinstance(значение, bool):
        return "логический-указатель"
    if isinstance(значение, str):
        if re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", значение):
            return f"oid:{len(значение)}"
        if re.fullmatch(r"sha256:[0-9a-f]{64}", значение):
            return "sha256"
        return "строковый-указатель"
    raise ОшибкаМиграцииДат(
        "migration_fifo_changed",
        "Указатель FIFO имеет недопустимую форму.",
    )


def _проверить_и_свернуть_квитанцию_4(квитанция: Mapping[str, Any]) -> dict[str, Any]:
    прежняя = квитанция.get("предыдущая_квитанция")
    if not isinstance(прежняя, dict):
        raise ОшибкаМиграцииДат("migration_fifo_changed", "Квитанция handoff .4 не хранит exact previous receipt.")
    хэш_прежней = хэш_канонического_объекта(прежняя)
    if (
        квитанция.get("хэш_предыдущей_квитанции") != хэш_прежней
        or квитанция.get("замещает") != хэш_прежней
        or квитанция.get("хэш_байтов_предыдущей_квитанции") != хэш_сырых_байтов(канонические_байты(прежняя))
        or квитанция.get("old_base_oid") != прежняя.get("base_oid")
        or квитанция.get("old_head_oid") != прежняя.get("head_oid")
    ):
        raise ОшибкаМиграцииДат("migration_fifo_changed", "Квитанция handoff .4 подменила previous receipt или его хэши.")
    если_коммиты = прежняя.get("commits")
    if если_коммиты is not None and квитанция.get("old_commits") != если_коммиты:
        raise ОшибкаМиграцииДат("migration_fifo_changed", "Квитанция handoff .4 подменила old commits.")
    изменяемые_поля = {"schema", "base_oid", "head_oid", "commits"}
    for ключ, значение in прежняя.items():
        if ключ not in изменяемые_поля and квитанция.get(ключ) != значение:
            raise ОшибкаМиграцииДат("migration_fifo_changed", "Квитанция handoff .4 изменила immutable поле previous receipt.")
    доказательство = квитанция.get("доказательство_миграции")
    if not isinstance(доказательство, dict) or квитанция.get("хэш_доказательства_миграции") != хэш_канонического_объекта(доказательство):
        raise ОшибкаМиграцииДат("migration_fifo_changed", "Квитанция handoff .4 не имеет exact migration proof.")
    return copy.deepcopy(прежняя)


def _поле_является_указателем_очереди(путь: tuple[str, ...], ключ: str) -> bool:
    if not путь:
        return ключ in {
            "base_oid", "head_oid", "last_result_hash", "result_hash",
            "protocol_oid", "effective_protocol_oid", "reload_required", "protocol_reload_required",
        }
    if путь == ("owner",):
        return ключ in {
            "base_oid", "head_oid", "acknowledged_head", "last_result_hash", "result_hash",
            "protocol_oid", "effective_protocol_oid", "reload_required", "protocol_reload_required",
        }
    if len(путь) == 2 and путь[0] == "continuation_intents":
        return ключ == "head_oid"
    return False


def _проекция_очереди(значение: object, путь: tuple[str, ...] = ()) -> object:
    if isinstance(значение, list):
        return [_проекция_очереди(элемент, (*путь, "[]")) for элемент in значение]
    if not isinstance(значение, dict):
        return copy.deepcopy(значение)
    if значение.get("schema") == СХЕМА_МИГРИРОВАННОЙ_ПЕРЕДАЧИ:
        return _проекция_очереди(_проверить_и_свернуть_квитанцию_4(значение), путь)
    квитанция = значение.get("handoff_receipt")
    хэш_квитанции = значение.get("handoff_receipt_hash")
    if квитанция is not None:
        if not isinstance(квитанция, dict) or хэш_квитанции != хэш_канонического_объекта(квитанция):
            raise ОшибкаМиграцииДат("migration_fifo_changed", "handoff receipt/hash в FIFO неканоничны.")
    проекция: dict[str, Any] = {}
    for ключ, элемент in значение.items():
        if ключ == "handoff_receipt_hash" and isinstance(квитанция, dict):
            проекция[ключ] = хэш_канонического_объекта(_проекция_очереди(квитанция, (*путь, "handoff_receipt")))
        elif _поле_является_указателем_очереди(путь, ключ):
            проекция[ключ] = _форма_указателя(элемент)
        else:
            проекция[ключ] = _проекция_очереди(элемент, (*путь, ключ))
    return проекция


def проверить_неизменность_очереди(
    старая_очередь: Mapping[str, Any],
    новая_очередь: Mapping[str, Any],
) -> None:
    старый_статус = старая_очередь.get("status")
    новый_статус = новая_очередь.get("status")
    допустимый_переход = (старый_статус, новый_статус) == ("active", "reload_required")
    if старый_статус != новый_статус and not допустимый_переход:
        raise ОшибкаМиграцииДат(
            "migration_fifo_changed",
            "Миграция изменила статус FIFO вне exact active→reload_required.",
        )
    старая_проекция = dict(старая_очередь)
    новая_проекция = dict(новая_очередь)
    if допустимый_переход:
        новая_проекция["status"] = старый_статус
    if _проекция_очереди(старая_проекция) != _проекция_очереди(новая_проекция):
        raise ОшибкаМиграцииДат(
            "migration_fifo_changed",
            "Миграция изменила FIFO, seq, continuation identity либо приоритет.",
        )
