#!/usr/bin/env python3
"""Coordinate root Codex tasks in one Git worktree with a portable FIFO queue."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import os
import re
from signal import SIGKILL, SIGTERM
import stat
import subprocess
import sys
import tempfile
import time
import tomllib
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import NoReturn
from urllib.parse import urlsplit


SCHEMA_VERSION = 1
DEFAULT_WAIT_TIMEOUT_SECONDS = 300.0
WAIT_POLL_SECONDS = 2.0
GIT_COMMAND_TIMEOUT_SECONDS = 30.0
PUBLICATION_GIT_TIMEOUT_SECONDS = 120.0
PUBLICATION_TERMINATION_GRACE_SECONDS = 2.0
MAX_CAS_ATTEMPTS = 200
UNCHANGED_REF_RETRY_ATTEMPTS = 8
REF_RETRY_BASE_SECONDS = 0.005
REF_RETRY_MAX_SECONDS = 0.1
СХЕМА_ИНВЕНТАРЯ_БЛОКИРУЮЩИХ_ПУТЕЙ = 1
ЛИМИТ_БАЙТОВ_ГРЯЗНОГО_ОТВЕТА = 16_384
ЛИМИТ_ПУТЕЙ_В_ПРЕДПРОСМОТРЕ = 16
ДОМЕН_ОТПЕЧАТКА_БЛОКИРУЮЩИХ_ПУТЕЙ = (
    b"FUM\0queue-dirty-blocking-paths\0v1\0"
)

EXIT_WAITING = 10
EXIT_RELOAD_REQUIRED = 11
EXIT_CONTEXT = 12
EXIT_DIRTY = 13
EXIT_OWNERSHIP = 14
EXIT_HEAD_CHANGED = 15
EXIT_CAS = 16
EXIT_NOT_REGISTERED = 17
EXIT_NOTHING_STAGED = 18
EXIT_PUBLICATION_REJECTED = 19
EXIT_PUBLICATION_DIVERGED = 20
EXIT_PUBLICATION_UNCONFIRMED = 21
КОД_ИДЁТ_СБРОС = 22
КОД_НЕСОВПАДЕНИЯ_СЕССИЙ = 23
КОД_ИДЁТ_ПЕРЕХОД_НА_ЦЕПОЧКУ = 24
EXIT_CLI = 64
EXIT_INTERRUPTED = 130

СХЕМА_СБРОСА = "fum.сброс-состояния-FIFO.1"
СХЕМА_КВИТАНЦИИ_СБРОСА = "fum.квитанция-сброса-состояния-FIFO.1"
СХЕМА_ПРОСТОГО_СБРОСА = "fum.простой-сброс-состояния-FIFO.1"
СХЕМА_ПЛАНА_ПРОСТОГО_СБРОСА = "fum.план-простого-сброса-FIFO.1"
СХЕМА_СНИМКА_ПРОСТОГО_СБРОСА = "fum.снимок-простого-сброса-FIFO.1"
СХЕМА_КВИТАНЦИИ_ПРОСТОГО_СБРОСА = "fum.квитанция-простого-сброса-FIFO.1"
СХЕМА_ГРАНИЦЫ_ПРОСТОГО_СБРОСА = "fum.граница-простого-сброса.1"
СХЕМА_ГРАНИЦЫ_ЭПОХИ_ПРОСТОГО_СБРОСА = "fum.граница-эпохи-простого-сброса.1"
СХЕМА_АННУЛИРОВАННОЙ_ЗАДАЧИ = "fum.аннулированная-задача-простого-сброса.1"
СХЕМА_ПЕРЕХОДА_НА_ЦЕПОЧКУ = "fum.переход-на-цепочку.2"
СХЕМА_РЕЕСТРА_БАРЬЕРОВ_ПРЕДАКТИВАЦИИ = (
    "fum.реестр-барьеров-предактивации.2"
)
ПРЕЖНЯЯ_СХЕМА_РЕЕСТРА_БАРЬЕРОВ_ПРЕДАКТИВАЦИИ = (
    "fum.реестр-барьеров-предактивации.1"
)
СХЕМА_КВИТАНЦИИ_СВЯЗАННОГО_КОММИТА = (
    "fum.квитанция-связанного-коммита.1"
)
СХЕМА_КВИТАНЦИИ_ПРИНЯТОЙ_ИНТЕГРАЦИИ = (
    "fum.квитанция-принятой-интеграции-worktree-подузлов.1"
)
СХЕМА_ПУЛА_РАБОЧИХ_ДЕРЕВЬЕВ_ПОДУЗЛОВ = "fum.пул-worktree-подузлов.2"
СХЕМА_КВИТАНЦИИ_СРАВНЕНИЯ_И_ЗАМЕНЫ_ИНТЕГРАЦИИ_ПОДУЗЛОВ = (
    "fum.квитанция-CAS-интеграции-worktree-подузлов.1"
)
ПРЕЖНЯЯ_СХЕМА_КВИТАНЦИИ_ИНТЕГРАЦИОННОГО_КАНДИДАТА_ПОДУЗЛОВ = (
    "fum.квитанция-интеграционного-кандидата-worktree-подузлов.1"
)
СХЕМА_КВИТАНЦИИ_ИНТЕГРАЦИОННОГО_КАНДИДАТА_ПОДУЗЛОВ = (
    "fum.квитанция-интеграционного-кандидата-worktree-подузлов.2"
)
ПРЕЖНЯЯ_СХЕМА_КВИТАНЦИИ_РЕЗУЛЬТАТА_ПОДУЗЛА = (
    "fum.квитанция-результата-worktree-подузла.2"
)
СХЕМА_КВИТАНЦИИ_РЕЗУЛЬТАТА_ПОДУЗЛА = (
    "fum.квитанция-результата-worktree-подузла.3"
)
СХЕМА_КВИТАНЦИИ_РЕВЬЮ_ПОДУЗЛА = "fum.квитанция-агентского-ревью-worktree-подузла.1"
СХЕМА_НАМЕРЕНИЯ_ПУБЛИКАЦИИ_ИНТЕГРАЦИИ = (
    "fum.намерение-публикации-принятой-интеграции.1"
)
ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ = (
    "Требования/"
    "✅-обязательное-продолжение-Git-ветки-после-коммита.md"
)
ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ = (
    "обязательное_продолжение_активировано"
)
ПОЛЕ_ДОПУЩЕННОЙ_ЗАДАЧИ_БАРЬЕРА = "допущенная_задача_барьера"
ПРОСТРАНСТВО_КВИТАНЦИЙ_СБРОСА = (
    "refs/fum/квитанции-сброса-состояния-FIFO"
)
ПРОСТРАНСТВО_РЕЗЕРВАЦИЙ = "refs/fum/резервации-запусков-автоматизаций"
ПРОСТРАНСТВО_ЭПОХ_РЕЗЕРВАЦИЙ = (
    "refs/fum/эпохи-резерваций-запусков-автоматизаций"
)
ПРОСТРАНСТВО_УПРАВЛЕНИЯ = "refs/fum/управление-диспетчером"
ПРОСТРАНСТВО_ПРЕТЕНЗИЙ = "refs/fum/worktree-next-step-claims"
ПРОСТРАНСТВО_ПОЧИНКИ = "refs/fum/починка-автозапуска"
ПРОСТРАНСТВО_ЖУРНАЛА_ЗАВЕРШЕНИЙ = (
    "refs/fum/worktree-task-completion-ledgers"
)
ПРОСТРАНСТВО_АНАЛИТИКИ_ЗАВЕРШЕНИЙ = (
    "refs/fum/аналитика-завершённых-запусков"
)
СХЕМА_ЖУРНАЛА_ЗАВЕРШЕНИЙ = "fum.журнал-завершённых-запусков.1"
СХЕМА_ПРЕТЕНЗИИ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ = (
    "fum.претензия-аналитики-завершённых-запусков.1"
)
ИДЕНТИФИКАТОР_ЗАДАНИЯ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ = (
    "master.completed-step-analysis"
)
ПРОСТРАНСТВО_СНИМКОВ_ПРОСТОГО_СБРОСА = "refs/fum/снимки-простого-сброса"
ПРОСТРАНСТВО_КВИТАНЦИЙ_ПРОСТОГО_СБРОСА = "refs/fum/квитанции-простого-сброса"
ПРОСТРАНСТВО_ГРАНИЦ_ПРОСТОГО_СБРОСА = "refs/fum/границы-простого-сброса"
ПРОСТРАНСТВО_АННУЛИРОВАННЫХ_ЗАДАЧ = "refs/fum/аннулированные-задачи-простого-сброса"
ПРОСТРАНСТВО_КВИТАНЦИЙ_СВЯЗАННЫХ_КОММИТОВ = (
    "refs/fum/квитанции-связанных-коммитов"
)
ПРОСТРАНСТВО_КВИТАНЦИЙ_ПРИНЯТЫХ_ИНТЕГРАЦИЙ = (
    "refs/fum/квитанции-принятых-интеграций-worktree-подузлов"
)
ПРОСТРАНСТВО_МАРШРУТОВ_ЗАДАЧ = "refs/fum/task-runtime-routes"
ПРОСТРАНСТВО_РЕЕСТРОВ_БАРЬЕРОВ_ПРЕДАКТИВАЦИИ = (
    "refs/fum/реестры-барьеров-предактивации"
)
АРХИВНЫЕ_ПРОСТРАНСТВА_ПРОСТОГО_СБРОСА = frozenset(
    {
        "аварийные-снимки-состояния",
        "снимки-простого-сброса",
        "квитанции-простого-сброса",
        "границы-простого-сброса",
        "аннулированные-задачи-простого-сброса",
        "квитанции-связанных-коммитов",
    }
)
ФАЗЫ_СБРОСА = frozenset(
    {"подготовлен", "сессии_остановлены", "очистка_рабочей_копии"}
)
ПОЛЯ_ВОЗОБНОВЛЕНИЯ_РЕЗЕРВАЦИИ = frozenset(
    {
        "версия_схемы",
        "поколение",
        "состояние",
        "номер_попытки",
        "предел_попыток",
        "не_раньше",
        "ограждено",
        "подтверждено",
        "ключ",
        "хэш_сообщения",
        "причина",
        "класс_наблюдения",
        "ссылка_резервации",
        "исходный_объект_резервации",
        "ссылка_очереди",
        "объект_очереди",
        "ссылка_претензии",
        "объект_претензии",
        "наблюдение",
        "конверт",
    }
)
ПОЛЯ_НАБЛЮДЕНИЯ_РАЗРЫВА_РЕЗЕРВАЦИИ = frozenset(
    {
        "версия_схемы_среды",
        "состояние_задачи",
        "идентификатор_хода",
        "начат",
        "завершён",
        "длительность_миллисекунд",
        "сообщение_ошибки",
    }
)
ПОЛЯ_КОНВЕРТА_ВОЗОБНОВЛЕНИЯ_РЕЗЕРВАЦИИ = frozenset(
    {
        "версия_схемы",
        "ссылка_ветки",
        "вершина_выбора",
        "идентификатор_задания",
        "поколение_спецификации",
        "поколение_реестра",
        "ключ_запуска",
        "идентификатор_попытки",
        "идентификатор_задачи",
        "поколение_очереди",
        "ключ_возобновления",
    }
)
СООБЩЕНИЕ_РАЗРЫВА_ПОТОКА_ОТВЕТА = (
    "stream disconnected before completion: error sending request for url "
    "(https://chatgpt.com/backend-api/codex/responses)"
)


@dataclass(frozen=True)
class QueueContext:
    root: Path
    git_dir: Path
    worktree_id: str
    queue_ref: str
    branch_ref: str


@dataclass(frozen=True)
class ПереходЖурналаЗавершений:
    ссылка: str
    прежний_объект: str | None
    новый_объект: str
    ссылка_резервации: str
    объект_резервации: str
    ссылка_претензии: str
    объект_претензии: str
    новый_объект_претензии: str
    событие: dict[str, object]


@dataclass(frozen=True)
class ПереходПередачиАналитики:
    ссылка_резервации: str
    объект_резервации: str
    ссылка_претензии: str
    прежний_объект_претензии: str
    новый_объект_претензии: str
    свидетельство: dict[str, object]


@dataclass(frozen=True)
class ПереходЧистогоЗавершенияАналитики:
    ссылка_резервации: str
    объект_резервации: str
    ссылка_претензии: str
    прежний_объект_претензии: str
    новый_объект_претензии: str
    свидетельство: dict[str, object]


@dataclass(frozen=True)
class ПереходЧистогоЗавершенияСледующегоШага:
    ссылка_резервации: str
    объект_резервации: str
    ссылка_претензии: str
    прежний_объект_претензии: str
    новый_объект_претензии: str
    свидетельство: dict[str, object]


@dataclass(frozen=True)
class КарточкаЦепочки:
    идентификатор: str
    путь: str
    хэш: str
    ветка: str
    базовая_ветка: str


class QueueError(RuntimeError):
    def __init__(
        self,
        exit_code: int,
        state: str,
        message: str,
        *,
        данные_результата_операции: dict[str, object] | None = None,
    ) -> None:
        super().__init__(message)
        self.exit_code = exit_code
        self.state = state
        self.данные_результата_операции = данные_результата_операции or {}


def clean_git_environment() -> dict[str, str]:
    environment = {
        key: value
        for key, value in os.environ.items()
        if not key.upper().startswith("GIT_")
    }
    environment["GIT_NO_REPLACE_OBJECTS"] = "1"
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    return environment


def run_git(
    cwd: Path,
    args: list[str],
    *,
    input_bytes: bytes | None = None,
    check: bool = True,
    timeout_seconds: float = GIT_COMMAND_TIMEOUT_SECONDS,
    environment_updates: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[bytes]:
    environment = clean_git_environment()
    if environment_updates:
        environment.update(environment_updates)
    try:
        result = subprocess.run(
            ["git", "-C", str(cwd), *args],
            input=input_bytes,
            capture_output=True,
            check=False,
            env=environment,
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired as exc:
        raise QueueError(
            EXIT_CONTEXT,
            "git_timeout",
            f"Git не завершил команду за {timeout_seconds:g} секунд.",
        ) from exc
    except OSError as exc:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            f"Не удалось запустить Git: {exc}",
        ) from exc

    if check and result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        suffix = f": {detail}" if detail else ""
        raise QueueError(
            EXIT_CONTEXT,
            "git_error",
            f"Git-команда завершилась с ошибкой{suffix}",
        )
    return result


def decoded_stdout(result: subprocess.CompletedProcess[bytes]) -> str:
    return result.stdout.decode("utf-8", errors="strict").strip()


def validate_task_id(task_id: object) -> str:
    if (
        not isinstance(task_id, str)
        or not task_id.strip()
        or len(task_id) > 1_024
        or "\0" in task_id
        or "\n" in task_id
        or "\r" in task_id
    ):
        raise QueueError(
            EXIT_CLI,
            "invalid_task_id",
            "Идентификатор задачи должен быть непустой однострочной строкой.",
        )
    return task_id


def symbolic_branch(root: Path) -> str:
    result = run_git(root, ["symbolic-ref", "--quiet", "HEAD"], check=False)
    if result.returncode == 1:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Очередь требует именованную локальную Git-ветку; detached HEAD не поддерживается.",
        )
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            f"Не удалось определить текущую Git-ветку: {detail}",
        )
    branch_ref = decoded_stdout(result)
    if not branch_ref.startswith("refs/heads/"):
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            f"Неподдерживаемая ссылка HEAD: {branch_ref}",
        )
    return branch_ref


def current_head(root: Path) -> str:
    result = run_git(root, ["rev-parse", "--verify", "HEAD"])
    head = decoded_stdout(result)
    if not head:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Очередь требует хотя бы один коммит в текущей ветке.",
        )
    return head


def worktrees_for_branch(root: Path, branch_ref: str) -> list[Path]:
    result = run_git(root, ["worktree", "list", "--porcelain", "-z"])
    worktrees: list[Path] = []
    for block in result.stdout.split(b"\0\0"):
        if not block:
            continue
        worktree: Path | None = None
        branch: str | None = None
        for field in block.split(b"\0"):
            if field.startswith(b"worktree "):
                value = field[len(b"worktree ") :].decode(
                    "utf-8", errors="surrogateescape"
                )
                worktree = Path(value).resolve()
            elif field.startswith(b"branch "):
                branch = field[len(b"branch ") :].decode("utf-8", errors="strict")
        if worktree is not None and branch == branch_ref:
            worktrees.append(worktree)
    return worktrees


def ensure_unique_branch_worktree(root: Path, branch_ref: str) -> None:
    if len(worktrees_for_branch(root, branch_ref)) > 1:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Одна именованная ветка открыта сразу в нескольких worktree; "
            "единая локальная очередь не может считать такой checkout безопасным.",
        )


def resolve_context(repo_root: Path) -> QueueContext:
    candidate = repo_root.expanduser().resolve()
    top = run_git(candidate, ["rev-parse", "--show-toplevel"])
    root = Path(decoded_stdout(top)).resolve()
    git_dir_result = run_git(root, ["rev-parse", "--absolute-git-dir"])
    git_dir = Path(decoded_stdout(git_dir_result)).resolve()
    branch_ref = symbolic_branch(root)
    ensure_unique_branch_worktree(root, branch_ref)

    identity = os.path.normcase(str(git_dir))
    worktree_id = hashlib.sha256(identity.encode("utf-8")).hexdigest()
    queue_ref = f"refs/fum/worktree-task-queues/{worktree_id}"
    return QueueContext(
        root=root,
        git_dir=git_dir,
        worktree_id=worktree_id,
        queue_ref=queue_ref,
        branch_ref=branch_ref,
    )


def ensure_live_branch(контекст_очереди: QueueContext) -> None:
    live_branch = symbolic_branch(контекст_очереди.root)
    if live_branch != контекст_очереди.branch_ref:
        raise QueueError(
            EXIT_CONTEXT,
            "branch_changed",
            "Git-ветка была переключена после начала операции очереди.",
            данные_результата_операции={
                "expected_branch_ref": контекст_очереди.branch_ref,
                "current_branch_ref": live_branch,
            },
        )


def потребовать_поддержку_символьных_транзакций(
    контекст: QueueContext,
) -> None:
    ensure_live_branch(контекст)
    команды = (
        "start\n"
        f"symref-verify HEAD {контекст.branch_ref}\n"
        "abort\n"
    ).encode("utf-8")
    результат = run_git(
        контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=команды,
        check=False,
    )
    if результат.returncode != 0:
        raise QueueError(
            EXIT_CONTEXT,
            "unsupported_git_symref_transaction",
            "Безопасный переход HEAD требует Git с symref-командами update-ref.",
            данные_результата_операции={
                "git_stderr": результат.stderr.decode(
                    "utf-8",
                    errors="replace",
                ).strip(),
            },
        )


def маркер_обязательного_продолжения_есть_в_текущей_вершине(
    контекст_очереди: QueueContext,
) -> bool:
    результат = run_git(
        контекст_очереди.root,
        [
            "ls-tree",
            "-z",
            "--full-tree",
            "HEAD",
            "--",
            ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ,
        ],
    )
    части = результат.stdout.split(b"\t", 1)
    return (
        len(части) == 2
        and части[1]
        == ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ.encode("utf-8") + b"\0"
    )


def обязательное_продолжение_активно(
    контекст_очереди: QueueContext,
    состояние: dict[str, object],
) -> bool:
    return (
        состояние.get(ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ) is True
        or маркер_обязательного_продолжения_есть_в_текущей_вершине(
            контекст_очереди
        )
    )


def utc_values(now_epoch: float | None = None) -> tuple[str, float]:
    epoch = time.time() if now_epoch is None else now_epoch
    stamp = (
        datetime.fromtimestamp(epoch, tz=timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z")
    )
    return stamp, epoch


def new_state(контекст_очереди: QueueContext) -> dict[str, object]:
    stamp, _ = utc_values()
    return {
        "schema_version": SCHEMA_VERSION,
        "worktree_id": контекст_очереди.worktree_id,
        "branch_ref": контекст_очереди.branch_ref,
        "next_seq": 1,
        "owner": None,
        "waiting": [],
        "last_completion": None,
        "updated_at": stamp,
    }


def validate_ticket(ticket: object, *, owner: bool) -> dict[str, object]:
    if not isinstance(ticket, dict):
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждена запись участника очереди.")
    for key in ["task_id", "ticket_id", "seq"]:
        if key not in ticket:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                f"В записи участника очереди отсутствует поле {key}.",
            )
    validate_task_id(ticket["task_id"])
    if not isinstance(ticket["ticket_id"], str) or not ticket["ticket_id"]:
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждён ticket_id очереди.")
    if not isinstance(ticket["seq"], int) or ticket["seq"] < 1:
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждён seq очереди.")
    required = (
        ["generation", "base_head", "admitted_at", "admitted_at_epoch"]
        if owner
        else [
            "registered_at",
            "registered_at_epoch",
            "acknowledged_head",
        ]
    )
    for key in required:
        if key not in ticket:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                f"В записи участника очереди отсутствует поле {key}.",
            )
    обязательные_барьерные_поля = {
        "объект_реестра_барьеров",
        "идентификатор_назначения_барьера",
        "хэш_назначения_барьера",
        "идентификатор_ресурсной_попытки_барьера",
        "хэш_ресурсного_допуска_барьера",
    }
    присутствующие_барьерные_поля = обязательные_барьерные_поля.intersection(ticket)
    if (
        присутствующие_барьерные_поля
        and присутствующие_барьерные_поля != обязательные_барьерные_поля
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Барьерный билет содержит неполное ресурсное ограждение.",
        )
    for key in присутствующие_барьерные_поля:
        if not isinstance(ticket[key], str) or not ticket[key]:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "Первый барьерный билет содержит повреждённое ограждение.",
            )
    if "хэш_ресурсного_допуска_барьера" in ticket:
        проверить_хэш_sha256(
            ticket["хэш_назначения_барьера"],
            "Барьерный билет содержит неверный хэш назначения.",
            код_выхода=EXIT_CONTEXT,
            состояние="corrupt_queue",
        )
        проверить_хэш_sha256(
            ticket["хэш_ресурсного_допуска_барьера"],
            "Барьерный билет содержит неверный хэш ресурсного допуска.",
            код_выхода=EXIT_CONTEXT,
            состояние="corrupt_queue",
        )
    if "базовая_вершина_барьера" in ticket:
        if not обязательные_барьерные_поля.issubset(ticket):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "Первый барьерный билет не содержит полного ресурсного ограждения.",
            )
        проверить_полный_объект(
            ticket["базовая_вершина_барьера"],
            состояние_ошибки="corrupt_queue",
            сообщение="Первый барьерный билет содержит неверную базовую вершину.",
        )
    return ticket


def проверить_текущую_цепочку(
    значение: object,
    ссылка_ветки: str,
) -> dict[str, object]:
    ожидаемые_поля = {"идентификатор", "путь", "хэш", "ветка"}
    if not isinstance(значение, dict) or set(значение) != ожидаемые_поля:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Текущая цепочка очереди имеет неизвестный набор полей.",
        )
    идентификатор = значение["идентификатор"]
    if (
        not isinstance(идентификатор, str)
        or re.fullmatch(r"FUM-ЦЕПОЧКА-[0-9]{4}", идентификатор) is None
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Текущая цепочка очереди имеет неверный идентификатор.",
        )
    путь = значение["путь"]
    if (
        not isinstance(путь, str)
        or not путь
        or "\0" in путь
        or "\n" in путь
        or "\r" in путь
        or Path(путь).is_absolute()
        or ".." in Path(путь).parts
        or Path(путь).as_posix() != путь
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Текущая цепочка очереди имеет неверный путь карточки.",
        )
    хэш = значение["хэш"]
    if (
        not isinstance(хэш, str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", хэш) is None
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Текущая цепочка очереди имеет неверный хэш карточки.",
        )
    ветка = значение["ветка"]
    if (
        not isinstance(ветка, str)
        or not ветка.startswith("refs/heads/")
        or ветка != ссылка_ветки
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Текущая цепочка очереди не совпадает с веткой очереди.",
        )
    return значение


def validate_state(state: object) -> dict[str, object]:
    if not isinstance(state, dict) or state.get("schema_version") != SCHEMA_VERSION:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Git-ссылка очереди содержит неизвестную схему состояния.",
        )
    if (
        ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ in state
        and state[ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ] is not True
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Необратимая активация обязательного продолжения повреждена.",
        )
    if not isinstance(state.get("worktree_id"), str):
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждён worktree_id очереди.")
    branch_ref = state.get("branch_ref")
    if not isinstance(branch_ref, str) or not branch_ref.startswith("refs/heads/"):
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждён branch_ref очереди.")
    if "текущая_цепочка" in state:
        проверить_текущую_цепочку(state["текущая_цепочка"], branch_ref)
    next_seq = state.get("next_seq")
    if not isinstance(next_seq, int) or next_seq < 1:
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждён next_seq очереди.")
    допущенная_задача_барьера = state.get(ПОЛЕ_ДОПУЩЕННОЙ_ЗАДАЧИ_БАРЬЕРА)
    if допущенная_задача_барьера is not None:
        ожидаемые_поля = {
            "task_id",
            "ticket_id",
            "seq",
            "объект_реестра_барьеров",
        }
        if (
            not isinstance(допущенная_задача_барьера, dict)
            or set(допущенная_задача_барьера) != ожидаемые_поля
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "Свидетельство допуска задачи барьера имеет неизвестный контракт.",
            )
        validate_task_id(допущенная_задача_барьера["task_id"])
        if (
            not isinstance(допущенная_задача_барьера["ticket_id"], str)
            or not допущенная_задача_барьера["ticket_id"]
            or not isinstance(допущенная_задача_барьера["seq"], int)
            or допущенная_задача_барьера["seq"] < 1
            or not isinstance(
                допущенная_задача_барьера["объект_реестра_барьеров"],
                str,
            )
            or re.fullmatch(
                r"(?:[0-9a-f]{40}|[0-9a-f]{64})",
                допущенная_задача_барьера["объект_реестра_барьеров"],
            )
            is None
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "Свидетельство допуска задачи барьера повреждено.",
            )
    owner = state.get("owner")
    if owner is not None:
        validate_ticket(owner, owner=True)
    waiting = state.get("waiting")
    if not isinstance(waiting, list):
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждён список ожидания.")
    sequences: list[int] = []
    task_ids: set[str] = set()
    ticket_ids: set[str] = set()
    if isinstance(owner, dict):
        sequences.append(int(owner["seq"]))
        task_ids.add(str(owner["task_id"]))
        ticket_ids.add(str(owner["ticket_id"]))
    for ticket in waiting:
        validated = validate_ticket(ticket, owner=False)
        sequences.append(int(validated["seq"]))
        task_id = str(validated["task_id"])
        ticket_id = str(validated["ticket_id"])
        if task_id in task_ids or ticket_id in ticket_ids:
            raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Очередь содержит дубликат участника.")
        task_ids.add(task_id)
        ticket_ids.add(ticket_id)
    if sequences != sorted(sequences) or len(sequences) != len(set(sequences)):
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Нарушен порядок seq в очереди.")
    completion = state.get("last_completion")
    if completion is not None:
        if not isinstance(completion, dict):
            raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Повреждена запись завершения.")
        for key in ["kind", "task_id", "generation", "head", "completed_at"]:
            if not isinstance(completion.get(key), str) or not completion[key]:
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_queue",
                    f"В записи завершения отсутствует поле {key}.",
                )
        if completion["kind"] not in {"committed", "finished_clean", "reset"}:
            raise QueueError(EXIT_CONTEXT, "corrupt_queue", "Неизвестен вид завершения.")
        if completion["kind"] == "committed" and (
            not isinstance(completion.get("base_head"), str)
            or not completion["base_head"]
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "В записи коммита отсутствует base_head.",
            )
        if completion["kind"] == "committed" and "идентификатор_продолжения" in completion:
            идентификатор_продолжения = completion["идентификатор_продолжения"]
            if (
                not isinstance(идентификатор_продолжения, str)
                or not идентификатор_продолжения.strip()
                or len(идентификатор_продолжения) > 1_024
                or "\0" in идентификатор_продолжения
                or "\n" in идентификатор_продолжения
                or "\r" in идентификатор_продолжения
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_queue",
                    "Запись коммита содержит неверный идентификатор продолжения.",
                )
        if completion["kind"] == "reset":
            if set(completion) != {
                "kind",
                "task_id",
                "generation",
                "head",
                "completed_at",
                "аннулированные_задачи",
            }:
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_queue",
                    "Запись сброса содержит неизвестные поля.",
                )
            if re.fullmatch(r"sha256:[0-9a-f]{64}", completion["generation"]) is None:
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_queue",
                    "Запись сброса содержит неверное поколение.",
                )
            if (
                re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", completion["head"])
                is None
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_queue",
                    "Запись сброса содержит неверную вершину.",
                )
            аннулированные = completion.get("аннулированные_задачи")
            if not isinstance(аннулированные, list):
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_queue",
                    "В записи сброса отсутствует список аннулированных задач.",
                )
            for идентификатор in аннулированные:
                validate_task_id(идентификатор)
            if аннулированные != sorted(set(аннулированные)):
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_queue",
                    "Список аннулированных задач сброса неканоничен.",
                )
    return state


def canonical_state_bytes(state: dict[str, object]) -> bytes:
    return (
        json.dumps(
            state,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def ссылка_маршрута_задачи(идентификатор_задачи: str) -> str:
    отпечаток = hashlib.sha256(идентификатор_задачи.encode("utf-8")).hexdigest()
    return f"{ПРОСТРАНСТВО_МАРШРУТОВ_ЗАДАЧ}/{отпечаток}"


def хэш_идентичности_обычной_очереди(контекст: QueueContext) -> str:
    идентичность: dict[str, object] = {
        "schema": "fum.идентичность-ordinary-fifo.1",
        "worktree_id": контекст.worktree_id,
        "queue_ref": контекст.queue_ref,
        "branch_ref": контекст.branch_ref,
    }
    return "sha256:" + hashlib.sha256(
        canonical_state_bytes(идентичность)
    ).hexdigest()


def данные_маршрута_обычной_очереди(
    контекст: QueueContext,
    идентификатор_задачи: str,
) -> dict[str, object]:
    return {
        "schema": "fum.маршрут-задачи-runtime.1",
        "task_id": идентификатор_задачи,
        "route_kind": "ordinary_fifo",
        "route_identity": хэш_идентичности_обычной_очереди(контекст),
    }


def подготовить_маршрут_обычной_очереди(
    контекст: QueueContext,
    идентификатор_задачи: str,
) -> tuple[str, str, str | None]:
    нагрузка = данные_маршрута_обычной_очереди(
        контекст,
        идентификатор_задачи,
    )
    байты = canonical_state_bytes(нагрузка)
    ожидаемый_объект = decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "-w", "--stdin"],
            input_bytes=байты,
        )
    )
    ссылка = ссылка_маршрута_задачи(идентификатор_задачи)
    существующий_объект = read_ref_oid(контекст, ссылка)
    if существующий_объект is None:
        return ссылка, ожидаемый_объект, None
    сырые = run_git(контекст.root, ["cat-file", "blob", существующий_объект]).stdout
    try:
        существующий = json.loads(сырые.decode("utf-8", errors="strict"))
    except (UnicodeDecodeError, json.JSONDecodeError) as ошибка:
        raise QueueError(EXIT_CONTEXT, "corrupt_task_route", "Runtime-маршрут задачи повреждён.") from ошибка
    if (
        существующий != нагрузка
        or сырые != байты
        or существующий_объект != ожидаемый_объект
    ):
        raise QueueError(EXIT_OWNERSHIP, "task_route_already_reserved", "Задача уже необратимо связана с иным runtime-маршрутом.")
    return ссылка, ожидаемый_объект, существующий_объект


def команда_маршрута_задачи(ссылка: str, объект: str, прежний_объект: str | None) -> str:
    if прежний_объект is None:
        return f"create {ссылка} {объект}\n"
    return f"verify {ссылка} {прежний_объект}\n"


def дозаполнить_маршрут_существующего_участника(
    контекст: QueueContext,
    состояние: dict[str, object],
    прежний_объект_очереди: str | None,
    идентификатор_задачи: str,
    ссылка_маршрута: str,
    объект_маршрута: str,
) -> bool:
    if прежний_объект_очереди is None:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "У существующего участника отсутствует Git-ссылка очереди.",
        )
    ожидаемая_вершина = current_head(контекст.root)
    метка, _ = utc_values()
    обновлённое = copy.deepcopy(состояние)
    обновлённое["updated_at"] = метка
    новый_объект_очереди = write_state_blob(контекст, обновлённое)
    результат = update_queue_with_head_verification(
        контекст,
        expected_head=ожидаемая_вершина,
        old_queue_oid=прежний_объект_очереди,
        new_queue_oid=новый_объект_очереди,
        команда_внешнего_ограждения=(
            f"create {ссылка_маршрута} {объект_маршрута}\n"
        ),
    )
    if результат.returncode == 0:
        try:
            ensure_live_branch(контекст)
        except QueueError:
            восстановить_ссылку_очереди_после_смены_ветки(
                контекст,
                прежний_объект_очереди,
                новый_объект_очереди,
            )
            raise
        return True
    _, _, наблюдаемый_объект_маршрута = подготовить_маршрут_обычной_очереди(
        контекст,
        идентификатор_задачи,
    )
    if наблюдаемый_объект_маршрута is not None:
        return False
    if (
        current_head(контекст.root) != ожидаемая_вершина
        or read_ref_oid(контекст, контекст.queue_ref)
        != прежний_объект_очереди
    ):
        return False
    update_ref_error(
        "дозаполнить runtime-маршрут существующего участника",
        результат.stderr.decode("utf-8", errors="replace").strip(),
    )


def проверить_ссылку_ветки_цепочки(
    корень: Path,
    значение: object,
    *,
    код: int,
    состояние: str,
    пояснение: str,
) -> str:
    if (
        not isinstance(значение, str)
        or not значение.startswith("refs/heads/")
        or "\0" in значение
        or "\n" in значение
        or "\r" in значение
    ):
        raise QueueError(код, состояние, пояснение)
    проверка = run_git(
        корень,
        ["check-ref-format", значение],
        check=False,
    )
    if проверка.returncode != 0:
        raise QueueError(код, состояние, пояснение)
    return значение


def проверить_путь_внутри_репозитория(
    корень: Path,
    значение: object,
    *,
    состояние: str,
    пояснение: str,
) -> tuple[str, Path]:
    if (
        not isinstance(значение, str)
        or not значение
        or "\0" in значение
        or "\n" in значение
        or "\r" in значение
    ):
        raise QueueError(EXIT_CLI, состояние, пояснение)
    путь = Path(значение)
    if (
        путь.is_absolute()
        or ".." in путь.parts
        or путь.as_posix() != значение
    ):
        raise QueueError(EXIT_CLI, состояние, пояснение)
    полный_путь = корень / путь
    try:
        полный_путь.resolve().relative_to(корень.resolve())
    except (OSError, ValueError) as ошибка:
        raise QueueError(EXIT_CLI, состояние, пояснение) from ошибка
    return значение, полный_путь


def прочитать_карточку_цепочки(
    контекст: QueueContext,
    путь_карточки: str,
    ожидаемый_идентификатор: str,
    ожидаемый_хэш: str,
    ожидаемая_исходная_ветка: str,
    ожидаемая_исходная_вершина: str,
) -> КарточкаЦепочки:
    if re.fullmatch(r"FUM-ЦЕПОЧКА-[0-9]{4}", ожидаемый_идентификатор) is None:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_id",
            "--expected-chain-id должен иметь вид FUM-ЦЕПОЧКА-NNNN.",
        )
    if re.fullmatch(r"sha256:[0-9a-f]{64}", ожидаемый_хэш) is None:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card_hash",
            "--expected-card-sha256 должен иметь вид sha256:<64 hex>.",
        )
    проверить_ссылку_ветки_цепочки(
        контекст.root,
        ожидаемая_исходная_ветка,
        код=EXIT_CLI,
        состояние="invalid_source_branch_ref",
        пояснение="--expected-source-branch-ref должен быть полным ref локальной ветки.",
    )
    if (
        not isinstance(ожидаемая_исходная_вершина, str)
        or re.fullmatch(
            r"(?:[0-9a-f]{40}|[0-9a-f]{64})",
            ожидаемая_исходная_вершина,
        )
        is None
    ):
        raise QueueError(
            EXIT_CLI,
            "invalid_source_head",
            "--expected-source-head должен быть полным SHA-1 или SHA-256 Git OID.",
        )
    нормализованный_путь, полный_путь = проверить_путь_внутри_репозитория(
        контекст.root,
        путь_карточки,
        состояние="invalid_chain_card_path",
        пояснение="--chain-card должен быть нормализованным путём внутри репозитория.",
    )
    if not нормализованный_путь.startswith(
        "Планирование/карточки-цепочек-шагов/"
    ) or not нормализованный_путь.endswith(".md"):
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card_path",
            "--chain-card должен указывать Markdown-карточку цепочки шагов.",
        )
    try:
        режим = полный_путь.lstat().st_mode
        if not stat.S_ISREG(режим):
            raise QueueError(
                EXIT_CLI,
                "invalid_chain_card_path",
                "Карточка цепочки должна быть обычным файлом, а не ссылкой.",
            )
        сырые_байты = полный_путь.read_bytes()
    except QueueError:
        raise
    except OSError as ошибка:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card_path",
            f"Не удалось прочитать карточку цепочки: {ошибка}",
        ) from ошибка
    вычисленный_хэш = "sha256:" + hashlib.sha256(сырые_байты).hexdigest()
    if вычисленный_хэш != ожидаемый_хэш:
        raise QueueError(
            EXIT_CAS,
            "chain_card_changed",
            "Точные байты карточки цепочки не совпадают с ожидаемым SHA-256.",
        )
    объект_карточки = run_git(
        контекст.root,
        [
            "cat-file",
            "blob",
            f"{ожидаемая_исходная_вершина}:{нормализованный_путь}",
        ],
        check=False,
    )
    if объект_карточки.returncode != 0 or объект_карточки.stdout != сырые_байты:
        raise QueueError(
            EXIT_CAS,
            "chain_card_not_at_source_head",
            "Карточка checkout не совпадает с карточкой в ожидаемой исходной вершине.",
        )
    try:
        текст = сырые_байты.decode("utf-8", errors="strict")
    except UnicodeDecodeError as ошибка:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "Карточка цепочки должна быть корректным UTF-8.",
        ) from ошибка
    if not текст.startswith("+++\n"):
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "Карточка цепочки должна начинаться TOML-блоком между +++.",
        )
    конец_метаданных = текст.find("\n+++\n", 4)
    if конец_метаданных < 0:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "TOML-блок карточки цепочки не закрыт строкой +++.",
        )
    try:
        метаданные = tomllib.loads(текст[4:конец_метаданных])
    except tomllib.TOMLDecodeError as ошибка:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            f"Карточка цепочки содержит некорректный TOML: {ошибка}",
        ) from ошибка
    ожидаемые_поля = {
        "версия_схемы",
        "идентификатор_цепочки",
        "состояние",
        "ветка",
        "базовая_ветка",
        "путь_проекта",
        "карточки_шагов",
    }
    if not isinstance(метаданные, dict) or set(метаданные) != ожидаемые_поля:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "TOML карточки цепочки имеет неизвестный набор полей.",
        )
    if type(метаданные["версия_схемы"]) is not int or метаданные["версия_схемы"] != 1:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "Карточка цепочки поддерживает только версия_схемы = 1.",
        )
    идентификатор = метаданные["идентификатор_цепочки"]
    if идентификатор != ожидаемый_идентификатор:
        raise QueueError(
            EXIT_CAS,
            "chain_id_changed",
            "Идентификатор карточки не совпадает с --expected-chain-id.",
        )
    if метаданные["состояние"] != "активна":
        raise QueueError(
            EXIT_CLI,
            "inactive_chain_card",
            "Перейти можно только на активную карточку цепочки.",
        )
    целевая_ветка = проверить_ссылку_ветки_цепочки(
        контекст.root,
        метаданные["ветка"],
        код=EXIT_CLI,
        состояние="invalid_chain_card",
        пояснение="Поле ветка карточки должно быть полным ref локальной ветки.",
    )
    if not целевая_ветка.startswith("refs/heads/codex/"):
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "Целевая ветка карточки должна находиться в refs/heads/codex/.",
        )
    базовая_ветка = проверить_ссылку_ветки_цепочки(
        контекст.root,
        метаданные["базовая_ветка"],
        код=EXIT_CLI,
        состояние="invalid_chain_card",
        пояснение="Поле базовая_ветка карточки должно быть полным ref локальной ветки.",
    )
    if базовая_ветка != ожидаемая_исходная_ветка:
        raise QueueError(
            EXIT_CAS,
            "source_branch_changed",
            "Базовая ветка карточки не совпадает с ожидаемой исходной веткой.",
        )
    if целевая_ветка == базовая_ветка:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "Целевая и базовая ветки карточки цепочки должны различаться.",
        )
    путь_проекта, полный_путь_проекта = проверить_путь_внутри_репозитория(
        контекст.root,
        метаданные["путь_проекта"],
        состояние="invalid_chain_card",
        пояснение="Поле путь_проекта должно быть нормализованным путём репозитория.",
    )
    if not полный_путь_проекта.is_file() or not путь_проекта:
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "Поле путь_проекта должно указывать существующий файл.",
        )
    карточки_шагов = метаданные["карточки_шагов"]
    if (
        not isinstance(карточки_шагов, list)
        or not карточки_шагов
        or any(
            not isinstance(идентификатор_шага, str)
            or re.fullmatch(r"FUM-STEP-[0-9]{4}", идентификатор_шага) is None
            for идентификатор_шага in карточки_шагов
        )
        or len(set(карточки_шагов)) != len(карточки_шагов)
    ):
        raise QueueError(
            EXIT_CLI,
            "invalid_chain_card",
            "Поле карточки_шагов должно быть непустым списком уникальных FUM-STEP-NNNN.",
        )
    return КарточкаЦепочки(
        идентификатор=ожидаемый_идентификатор,
        путь=нормализованный_путь,
        хэш=вычисленный_хэш,
        ветка=целевая_ветка,
        базовая_ветка=базовая_ветка,
    )


def канонические_байты_перехода_на_цепочку(
    запись: dict[str, object],
) -> bytes:
    return (
        json.dumps(
            запись,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def проверить_запись_перехода_на_цепочку(
    значение: object,
    контекст: QueueContext,
    *,
    проверять_ссылки: bool = True,
) -> dict[str, object]:
    ожидаемые_поля = {
        "схема",
        "идентификатор_рабочей_копии",
        "исходная_ветка",
        "целевая_ветка",
        "исходная_вершина",
        "исходный_объект_очереди",
        "идентификатор_задачи",
        "ссылка_маршрута",
        "объект_маршрута",
        "идентификатор_цепочки",
        "путь_карточки",
        "хэш_карточки",
        "владелец",
        "итоговое_состояние_очереди",
        "итоговый_объект_очереди",
        "создано",
    }
    if (
        not isinstance(значение, dict)
        or set(значение) != ожидаемые_поля
        or значение.get("схема") != СХЕМА_ПЕРЕХОДА_НА_ЦЕПОЧКУ
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Запись перехода на цепочку имеет неизвестную схему или поля.",
        )
    if значение["идентификатор_рабочей_копии"] != контекст.worktree_id:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Запись перехода принадлежит другой рабочей копии.",
        )
    исходная_ветка = проверить_ссылку_ветки_цепочки(
        контекст.root,
        значение["исходная_ветка"],
        код=EXIT_CONTEXT,
        состояние="corrupt_chain_transition",
        пояснение="Запись перехода имеет неверную исходную ветку.",
    )
    целевая_ветка = проверить_ссылку_ветки_цепочки(
        контекст.root,
        значение["целевая_ветка"],
        код=EXIT_CONTEXT,
        состояние="corrupt_chain_transition",
        пояснение="Запись перехода имеет неверную целевую ветку.",
    )
    if (
        исходная_ветка == целевая_ветка
        or контекст.branch_ref not in {исходная_ветка, целевая_ветка}
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "HEAD не находится ни на исходной, ни на целевой ветке перехода.",
        )
    исходная_вершина = значение["исходная_вершина"]
    if (
        not isinstance(исходная_вершина, str)
        or re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", исходная_вершина)
        is None
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Запись перехода имеет неверную исходную вершину.",
        )
    длина_объекта = len(исходная_вершина)
    исходный_объект = значение["исходный_объект_очереди"]
    if исходный_объект is not None and (
        not isinstance(исходный_объект, str)
        or re.fullmatch(r"[0-9a-f]+", исходный_объект) is None
        or len(исходный_объект) != длина_объекта
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Запись перехода имеет неверный исходный объект очереди.",
        )
    идентификатор_задачи = значение["идентификатор_задачи"]
    if (
        not isinstance(идентификатор_задачи, str)
        or not идентификатор_задачи
        or len(идентификатор_задачи) > 1_024
        or any(символ in идентификатор_задачи for символ in "\0\n\r")
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Запись перехода имеет неверный идентификатор задачи.",
        )
    целевой_контекст = QueueContext(
        root=контекст.root,
        git_dir=контекст.git_dir,
        worktree_id=контекст.worktree_id,
        queue_ref=контекст.queue_ref,
        branch_ref=целевая_ветка,
    )
    ссылка_маршрута = значение["ссылка_маршрута"]
    объект_маршрута = значение["объект_маршрута"]
    ожидаемая_ссылка_маршрута = ссылка_маршрута_задачи(
        идентификатор_задачи
    )
    ожидаемый_объект_маршрута = decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "--stdin"],
            input_bytes=canonical_state_bytes(
                данные_маршрута_обычной_очереди(
                    целевой_контекст,
                    идентификатор_задачи,
                )
            ),
        )
    )
    if (
        ссылка_маршрута != ожидаемая_ссылка_маршрута
        or not isinstance(объект_маршрута, str)
        or re.fullmatch(r"[0-9a-f]+", объект_маршрута) is None
        or len(объект_маршрута) != длина_объекта
        or объект_маршрута != ожидаемый_объект_маршрута
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Запись перехода имеет неверный runtime-маршрут задачи.",
        )
    текущая_цепочка = проверить_текущую_цепочку(
        {
            "идентификатор": значение["идентификатор_цепочки"],
            "путь": значение["путь_карточки"],
            "хэш": значение["хэш_карточки"],
            "ветка": целевая_ветка,
        },
        целевая_ветка,
    )
    владелец = validate_ticket(значение["владелец"], owner=True)
    if (
        владелец["task_id"] != идентификатор_задачи
        or владелец["base_head"] != исходная_вершина
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Владелец перехода не совпадает с задачей или исходной вершиной.",
        )
    итоговое_состояние = validate_state(значение["итоговое_состояние_очереди"])
    if (
        итоговое_состояние["worktree_id"] != контекст.worktree_id
        or итоговое_состояние["branch_ref"] != целевая_ветка
        or итоговое_состояние["owner"] != владелец
        or итоговое_состояние["waiting"] != []
        or итоговое_состояние.get("текущая_цепочка") != текущая_цепочка
        or итоговое_состояние["next_seq"] != int(владелец["seq"]) + 1
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Итоговое состояние не воспроизводится из записи перехода.",
        )
    итоговый_объект = значение["итоговый_объект_очереди"]
    if (
        not isinstance(итоговый_объект, str)
        or re.fullmatch(r"[0-9a-f]+", итоговый_объект) is None
        or len(итоговый_объект) != длина_объекта
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Запись перехода имеет неверный итоговый объект очереди.",
        )
    вычисленный_объект = decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "--stdin"],
            input_bytes=canonical_state_bytes(итоговое_состояние),
        )
    )
    if вычисленный_объект != итоговый_объект:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Итоговый объект очереди не совпадает с сохранённым состоянием.",
        )
    if not isinstance(значение["создано"], str) or not значение["создано"]:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Запись перехода не имеет времени создания.",
        )
    if проверять_ссылки and (
        read_ref_oid(контекст, исходная_ветка) != исходная_вершина
        or read_ref_oid(контекст, целевая_ветка) != исходная_вершина
        or read_ref_oid(контекст, ссылка_маршрута) != объект_маршрута
        or current_head(контекст.root) != исходная_вершина
    ):
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "chain_transition_head_changed",
            "Ветки или HEAD изменились во время перехода на цепочку.",
        )
    return значение


def записать_объект_перехода_на_цепочку(
    контекст: QueueContext,
    запись: dict[str, object],
) -> str:
    проверить_запись_перехода_на_цепочку(
        запись,
        контекст,
        проверять_ссылки=False,
    )
    return decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "-w", "--stdin"],
            input_bytes=канонические_байты_перехода_на_цепочку(запись),
        )
    )


def проверить_снимок_отслеживаемого_пути(
    значение: object,
) -> dict[str, object]:
    if not isinstance(значение, dict) or not isinstance(
        значение.get("тип"),
        str,
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Снимок отслеживаемого пути повреждён.",
        )
    тип = значение["тип"]
    if тип in {"отсутствует", "каталог"}:
        ожидаемые = {"тип"}
    elif тип == "символическая_ссылка":
        ожидаемые = {"тип", "sha256"}
    elif тип == "обычный_файл":
        ожидаемые = {"тип", "исполняемый", "sha256"}
        if type(значение.get("исполняемый")) is not bool:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_reset",
                "Снимок отслеживаемого файла не имеет точного режима.",
            )
    else:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Снимок отслеживаемого пути имеет неизвестный тип.",
        )
    if set(значение) != ожидаемые:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Снимок отслеживаемого пути имеет неизвестные поля.",
        )
    if "sha256" in ожидаемые and (
        not isinstance(значение["sha256"], str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", значение["sha256"]) is None
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Снимок отслеживаемого пути имеет неверный отпечаток.",
        )
    return значение


def проверить_запись_сброса(
    значение: object,
    контекст: QueueContext,
    *,
    проверять_служебные_объекты: bool = True,
) -> dict[str, object]:
    if not isinstance(значение, dict):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Git-ссылка очереди содержит повреждённую запись сброса.",
        )
    ожидаемые_поля = {
        "схема",
        "фаза",
        "идентификатор_рабочей_копии",
        "ссылка_ветки",
        "целевая_вершина",
        "исходный_объект_очереди",
        "исходное_состояние_очереди",
        "идентификатор_сброса",
        "идентификатор_диспетчера",
        "участники",
        "связанные_задачи",
        "неактивные_задачи",
        "изменённые_пути_плана",
        "неотслеживаемые_пути_плана",
        "неотслеживаемые_объекты_плана",
        "отслеживаемые_объекты_плана",
        "отпечаток_индекса_плана",
        "отпечаток_изменений",
        "служебные_ограждения",
        "создано",
        "обновлено",
    }
    if set(значение) != ожидаемые_поля or значение.get("схема") != СХЕМА_СБРОСА:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Запись сброса имеет неизвестную схему или набор полей.",
        )
    if значение["фаза"] not in ФАЗЫ_СБРОСА:
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса имеет неизвестную фазу.")
    if (
        значение["идентификатор_рабочей_копии"] != контекст.worktree_id
        or значение["ссылка_ветки"] != контекст.branch_ref
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Запись сброса принадлежит другой рабочей копии или ветке.",
        )
    длина_объекта = len(current_head(контекст.root))
    целевая_вершина = значение["целевая_вершина"]
    if (
        not isinstance(целевая_вершина, str)
        or re.fullmatch(r"[0-9a-f]+", целевая_вершина) is None
        or len(целевая_вершина) != длина_объекта
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса имеет неверную вершину.")
    исходный_объект = значение["исходный_объект_очереди"]
    if исходный_объект is not None and (
        not isinstance(исходный_объект, str)
        or re.fullmatch(r"[0-9a-f]+", исходный_объект) is None
        or len(исходный_объект) != длина_объекта
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Запись сброса имеет неверный исходный объект очереди.",
        )
    исходное_состояние = validate_state(значение["исходное_состояние_очереди"])
    if исходное_состояние["worktree_id"] != контекст.worktree_id:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Исходное состояние сброса принадлежит другой рабочей копии.",
        )
    if (
        исходное_состояние["branch_ref"] != контекст.branch_ref
        and (исходное_состояние["owner"] is not None or исходное_состояние["waiting"])
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Непустое исходное состояние сброса принадлежит другой ветке.",
        )
    вычисленный_объект = decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "--stdin"],
            input_bytes=canonical_state_bytes(исходное_состояние),
        )
    )
    if исходный_объект is None:
        if (
            исходное_состояние["next_seq"] != 1
            or исходное_состояние["owner"] is not None
            or исходное_состояние["waiting"]
            or исходное_состояние["last_completion"] is not None
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_reset",
                "Отсутствующей очереди соответствует непустое исходное состояние.",
            )
    elif вычисленный_объект != исходный_объект:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Исходное состояние не воспроизводит исходный объект очереди.",
        )
    идентификатор_сброса = значение["идентификатор_сброса"]
    if (
        not isinstance(идентификатор_сброса, str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", идентификатор_сброса) is None
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Запись сброса имеет неверный идентификатор.",
        )
    validate_task_id(значение["идентификатор_диспетчера"])
    участники = значение["участники"]
    связанные = значение["связанные_задачи"]
    неактивные = значение["неактивные_задачи"]
    пути = значение["изменённые_пути_плана"]
    неотслеживаемые = значение["неотслеживаемые_пути_плана"]
    неотслеживаемые_объекты = значение["неотслеживаемые_объекты_плана"]
    отслеживаемые_объекты = значение["отслеживаемые_объекты_плана"]
    if (
        not isinstance(участники, list)
        or not isinstance(связанные, list)
        or not isinstance(неактивные, list)
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса имеет неверные списки задач.")
    for идентификатор in [*участники, *связанные, *неактивные]:
        validate_task_id(идентификатор)
    if (
        участники != sorted(set(участники))
        or связанные != sorted(set(связанные))
        or неактивные != sorted(set(неактивные))
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса дублирует задачу.")
    ожидаемые_участники = sorted(
        set(участники_очереди(исходное_состояние)) | set(связанные)
    )
    if участники != ожидаемые_участники:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Участники сброса не выведены из очереди и связанных ограждений.",
        )
    требуемые = set(участники) - {str(значение["идентификатор_диспетчера"])}
    if not set(неактивные).issubset(требуемые):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Запись сброса подтверждает постороннюю задачу.",
        )
    if значение["фаза"] != "подготовлен" and set(неактивные) != требуемые:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Поздняя фаза сброса не подтверждает всех участников.",
        )
    if (
        not isinstance(пути, list)
        or not isinstance(неотслеживаемые, list)
        or any(not isinstance(путь, str) for путь in [*пути, *неотслеживаемые])
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса имеет неверные пути.")
    if пути != sorted(set(пути)) or неотслеживаемые != sorted(set(неотслеживаемые)):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Пути сброса неканоничны.")
    if not isinstance(неотслеживаемые_объекты, list):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Снимки неотслеживаемых объектов повреждены.")
    проверенные_объекты: list[dict[str, str]] = []
    for объект in неотслеживаемые_объекты:
        if not isinstance(объект, dict) or set(объект) != {"путь", "тип", "sha256"}:
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Снимок неотслеживаемого объекта повреждён.")
        if (
            not isinstance(объект["путь"], str)
            or объект["тип"]
            not in {"обычный_файл", "символическая_ссылка", "вложенная_git_граница"}
            or not isinstance(объект["sha256"], str)
            or re.fullmatch(r"sha256:[0-9a-f]{64}", объект["sha256"]) is None
        ):
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Снимок неотслеживаемого объекта имеет неверные поля.")
        проверенные_объекты.append(объект)
    if (
        проверенные_объекты
        != sorted(проверенные_объекты, key=lambda объект: объект["путь"])
        or [объект["путь"] for объект in проверенные_объекты] != неотслеживаемые
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Снимки неотслеживаемых объектов не совпадают с путями.")
    if not isinstance(отслеживаемые_объекты, list):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Снимки отслеживаемых объектов повреждены.",
        )
    проверенные_отслеживаемые: list[dict[str, object]] = []
    for объект in отслеживаемые_объекты:
        if not isinstance(объект, dict) or set(объект) != {"путь", "до", "цель"}:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_reset",
                "Снимок отслеживаемого объекта повреждён.",
            )
        путь_объекта = объект["путь"]
        if (
            not isinstance(путь_объекта, str)
            or путь_объекта not in set(пути) - set(неотслеживаемые)
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_reset",
                "Снимок отслеживаемого объекта имеет неверный путь.",
            )
        проверить_снимок_отслеживаемого_пути(объект["до"])
        проверить_снимок_отслеживаемого_пути(объект["цель"])
        проверенные_отслеживаемые.append(объект)
    if проверенные_отслеживаемые != sorted(
        проверенные_отслеживаемые,
        key=lambda объект: str(объект["путь"]),
    ) or len({str(объект["путь"]) for объект in проверенные_отслеживаемые}) != len(
        проверенные_отслеживаемые
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Снимки отслеживаемых объектов неканоничны.",
        )
    отпечаток_индекса_плана = значение["отпечаток_индекса_плана"]
    if (
        not isinstance(отпечаток_индекса_плана, str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", отпечаток_индекса_плана)
        is None
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Запись сброса имеет неверный отпечаток индекса.",
        )
    отпечаток = значение["отпечаток_изменений"]
    if not isinstance(отпечаток, str) or re.fullmatch(r"sha256:[0-9a-f]{64}", отпечаток) is None:
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса имеет неверный отпечаток изменений.")
    ограждения = проверить_служебные_ограждения(
        значение["служебные_ограждения"], контекст
    )
    if (
        проверять_служебные_объекты
        and связанные != связанные_задачи_из_ограждений(контекст, ограждения)
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Связанные задачи не воспроизводятся из служебных ограждений.",
        )
    if идентификатор_подтверждения_сброса(
        данные_подтверждения_из_записи(значение)
    ) != идентификатор_сброса:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Идентификатор сброса не воспроизводится из сохранённого плана.",
        )
    for поле in ("создано", "обновлено"):
        if not isinstance(значение[поле], str) or not значение[поле]:
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса не имеет метки времени.")
    return значение


def канонические_байты_сброса(запись: dict[str, object]) -> bytes:
    return (
        json.dumps(
            запись,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def собрать_объект_без_повторов(
    пары: list[tuple[str, object]],
) -> dict[str, object]:
    значение: dict[str, object] = {}
    for ключ, элемент in пары:
        if ключ in значение:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                f"Git-ссылка очереди повторяет поле {ключ!r}.",
            )
        значение[ключ] = элемент
    return значение


def отклонить_неконечное_число(значение: str) -> NoReturn:
    raise QueueError(
        EXIT_CONTEXT,
        "corrupt_queue",
        f"Git-ссылка очереди содержит неконечное число {значение}.",
    )


def проверить_запись_простого_сброса(
    значение: object,
    контекст: QueueContext,
) -> dict[str, object]:
    ожидаемые_поля = {
        "схема",
        "фаза",
        "идентификатор_рабочей_копии",
        "ссылка_ветки",
        "целевая_вершина",
        "исходный_объект_очереди",
        "идентификатор_сброса",
        "идентификатор_диспетчера",
        "участники",
        "неактивные_задачи",
        "изменённые_пути_плана",
        "ссылка_снимка",
        "объект_снимка",
        "текущая_цепочка",
        "создано",
    }
    if (
        not isinstance(значение, dict)
        or set(значение) != ожидаемые_поля
        or значение.get("схема") != СХЕМА_ПРОСТОГО_СБРОСА
        or значение.get("фаза") != "очистка_рабочей_копии"
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_reset",
            "Запись простого сброса имеет неизвестную схему.",
        )
    if (
        значение["идентификатор_рабочей_копии"] != контекст.worktree_id
        or значение["ссылка_ветки"] != контекст.branch_ref
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Запись простого сброса принадлежит другой рабочей копии или ветке.",
        )
    длина_объекта = len(current_head(контекст.root))
    for поле in ("целевая_вершина", "объект_снимка"):
        объект = значение[поле]
        if (
            not isinstance(объект, str)
            or re.fullmatch(r"[0-9a-f]+", объект) is None
            or len(объект) != длина_объекта
        ):
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса имеет неверный Git-объект.")
    исходный_объект = значение["исходный_объект_очереди"]
    if исходный_объект != "absent" and (
        not isinstance(исходный_объект, str)
        or re.fullmatch(r"[0-9a-f]+", исходный_объект) is None
        or len(исходный_объект) != длина_объекта
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса имеет неверную исходную очередь.")
    идентификатор_сброса = значение["идентификатор_сброса"]
    if (
        not isinstance(идентификатор_сброса, str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", идентификатор_сброса) is None
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса имеет неверный идентификатор.")
    validate_task_id(значение["идентификатор_диспетчера"])
    участники = значение["участники"]
    if not isinstance(участники, list):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса не имеет списка участников.")
    for участник in участники:
        validate_task_id(участник)
    if участники != sorted(set(участники)) or значение["неактивные_задачи"] != []:
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса имеет неверный список участников.")
    пути = значение["изменённые_пути_плана"]
    if not isinstance(пути, list) or any(not isinstance(путь, str) for путь in пути) or пути != sorted(set(пути)):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса имеет неверные пути.")
    ссылка_снимка = значение["ссылка_снимка"]
    if not isinstance(ссылка_снимка, str) or not ссылка_снимка.startswith(f"{ПРОСТРАНСТВО_СНИМКОВ_ПРОСТОГО_СБРОСА}/"):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса имеет неверную ссылку снимка.")
    цепочка = значение["текущая_цепочка"]
    if цепочка is not None:
        проверить_текущую_цепочку(цепочка, контекст.branch_ref)
    if not isinstance(значение["создано"], str) or not значение["создано"]:
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись простого сброса не имеет метки времени.")
    return значение


def read_ref_oid(контекст_очереди: QueueContext, reference_name: str) -> str | None:
    reference = run_git(
        контекст_очереди.root,
        ["rev-parse", "--verify", "--quiet", reference_name],
        check=False,
    )
    if reference.returncode == 1:
        return None
    if reference.returncode != 0:
        detail = reference.stderr.decode("utf-8", errors="replace").strip()
        raise QueueError(
            EXIT_CONTEXT,
            "git_error",
            f"Не удалось прочитать Git-ссылку {reference_name}: {detail}",
        )
    return decoded_stdout(reference)


def ссылка_реестра_барьеров_предактивации(
    контекст: QueueContext,
) -> str:
    return (
        f"{ПРОСТРАНСТВО_РЕЕСТРОВ_БАРЬЕРОВ_ПРЕДАКТИВАЦИИ}/"
        f"{контекст.worktree_id}"
    )


def проверить_однострочное_значение(
    значение: object,
    название: str,
) -> str:
    if (
        not isinstance(значение, str)
        or not значение.strip()
        or len(значение) > 1_024
        or "\0" in значение
        or "\n" in значение
        or "\r" in значение
    ):
        raise QueueError(
            EXIT_CLI,
            "неверное_ограждение_предактивации",
            f"Поле «{название}» должно быть непустой однострочной строкой.",
        )
    return значение


def проверить_полный_объект(
    значение: object,
    *,
    состояние_ошибки: str,
    сообщение: str,
) -> str:
    if (
        not isinstance(значение, str)
        or re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", значение) is None
    ):
        raise QueueError(EXIT_CLI, состояние_ошибки, сообщение)
    return значение


def канонические_байты_реестра_барьеров(
    реестр: dict[str, object],
) -> bytes:
    return (
        json.dumps(
            реестр,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def хэш_канонического_объекта(значение: dict[str, object]) -> str:
    сырые = json.dumps(
        значение,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(сырые).hexdigest()


def проверить_хэш_sha256(
    значение: object,
    сообщение: str,
    *,
    код_выхода: int = EXIT_CLI,
    состояние: str = "неверное_ограждение_предактивации",
) -> str:
    if not isinstance(значение, str) or re.fullmatch(r"sha256:[0-9a-f]{64}", значение) is None:
        raise QueueError(код_выхода, состояние, сообщение)
    return значение


def вычислить_хэш_привязки_барьера(
    запись: dict[str, object],
    идентификатор_задачи: str,
    идентификатор_среды: str,
    хэш_конверта: str,
) -> str:
    return хэш_канонического_объекта({
        "схема": "корневая-привязка-задачи.2",
        "поколение": запись["поколение_запуска"],
        "исходная_вершина": запись["базовая_вершина"],
        "форк": запись["идентификатор_форка"],
        "попытка": запись["идентификатор_попытки_создания"],
        "идентификатор_назначения": запись["идентификатор_назначения"],
        "хэш_назначения": запись["хэш_назначения"],
        "идентификатор_ресурсной_попытки": запись[
            "идентификатор_ресурсной_попытки"
        ],
        "хэш_ресурсного_допуска": запись["хэш_ресурсного_допуска"],
        "threadId": идентификатор_задачи,
        "hostId": идентификатор_среды,
        "хэш_конверта": хэш_конверта,
    })


def вычислить_хэш_активации_барьера(
    поколение: str,
    хэш_предактивации: str,
    квитанция_активации: str,
    хэши_привязок: list[str],
) -> str:
    return хэш_канонического_объекта({
        "схема": "корневая-активация-пары.2",
        "поколение": поколение,
        "хэш_предактивации": хэш_предактивации,
        "хэш_квитанции": квитанция_активации,
        "хэши_привязок": хэши_привязок,
    })


def проверить_запись_барьера(
    запись: object,
) -> dict[str, object]:
    базовые_поля = {
        "ветка",
        "базовая_вершина",
        "идентификатор_форка",
        "поколение_запуска",
        "идентификатор_попытки_создания",
        "идентификатор_назначения",
        "хэш_назначения",
        "идентификатор_ресурсной_попытки",
        "хэш_ресурсного_допуска",
        "состояние",
    }
    if not isinstance(запись, dict):
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Запись барьера предактивации не является объектом.",
    )
    состояние = запись.get("состояние")
    ожидаемые_поля = set(базовые_поля)
    if состояние == "открыт":
        ожидаемые_поля.update(
            {
                "идентификатор_задачи",
                "идентификатор_среды",
                "хэш_конверта",
                "хэш_привязки",
                "связан_из_объекта",
                "квитанция_активации",
                "хэш_предактивации",
                "хэши_привязок_пары",
                "хэш_активации",
                "открыт_из_объекта",
            }
        )
    elif состояние == "связан":
        ожидаемые_поля.update(
            {
                "идентификатор_задачи",
                "идентификатор_среды",
                "хэш_конверта",
                "хэш_привязки",
                "связан_из_объекта",
            }
        )
    elif состояние != "не_связан":
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Запись барьера имеет неизвестное состояние.",
        )
    if set(запись) != ожидаемые_поля:
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Запись барьера имеет неизвестный набор полей.",
        )
    ветка = запись["ветка"]
    if not isinstance(ветка, str) or not ветка.startswith("refs/heads/"):
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Запись барьера имеет неверную ветку.",
        )
    if re.fullmatch(
        r"(?:[0-9a-f]{40}|[0-9a-f]{64})",
        str(запись["базовая_вершина"]),
    ) is None:
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Запись барьера имеет неверную базовую вершину.",
        )
    for поле in (
        "идентификатор_форка",
        "поколение_запуска",
        "идентификатор_попытки_создания",
        "идентификатор_назначения",
        "идентификатор_ресурсной_попытки",
    ):
        if (
            not isinstance(запись[поле], str)
            or not str(запись[поле]).strip()
            or len(str(запись[поле])) > 1_024
            or any(знак in str(запись[поле]) for знак in ("\0", "\n", "\r"))
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "повреждённый_реестр_барьеров",
                f"Запись барьера имеет неверное поле «{поле}».",
            )
    for поле, сообщение in (
        ("хэш_назначения", "Запись барьера имеет неверный хэш назначения."),
        (
            "хэш_ресурсного_допуска",
            "Запись барьера имеет неверный хэш ресурсного допуска.",
        ),
    ):
        проверить_хэш_sha256(
            запись[поле],
            сообщение,
            код_выхода=EXIT_CONTEXT,
            состояние="повреждённый_реестр_барьеров",
        )
    if состояние in {"связан", "открыт"}:
        validate_task_id(запись["идентификатор_задачи"])
        проверить_однострочное_значение(
            запись["идентификатор_среды"],
            "идентификатор среды барьера",
        )
        проверить_хэш_sha256(
            запись["хэш_конверта"],
            "Хэш конверта должен иметь вид sha256:<64 hex>.",
            код_выхода=EXIT_CONTEXT,
            состояние="повреждённый_реестр_барьеров",
        )
        проверить_хэш_sha256(
            запись["хэш_привязки"],
            "Хэш привязки должен иметь вид sha256:<64 hex>.",
            код_выхода=EXIT_CONTEXT,
            состояние="повреждённый_реестр_барьеров",
        )
        if запись["хэш_привязки"] != вычислить_хэш_привязки_барьера(
            запись,
            str(запись["идентификатор_задачи"]),
            str(запись["идентификатор_среды"]),
            str(запись["хэш_конверта"]),
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "повреждённый_реестр_барьеров",
                "Хэш привязки не соответствует exact task, host и конверту.",
            )
        проверить_полный_объект(
            запись["связан_из_объекта"],
            состояние_ошибки="повреждённый_реестр_барьеров",
            сообщение="Запись барьера имеет неверную CAS-основу привязки.",
        )
    if состояние == "открыт":
        for поле, сообщение in (
            ("квитанция_активации", "Квитанция активации имеет неверный хэш."),
            ("хэш_предактивации", "Хэш предактивации имеет неверный формат."),
            ("хэш_активации", "Доказательство активации имеет неверный хэш."),
        ):
            проверить_хэш_sha256(
                запись[поле],
                сообщение,
                код_выхода=EXIT_CONTEXT,
                состояние="повреждённый_реестр_барьеров",
            )
        хэши_пары = запись["хэши_привязок_пары"]
        if (
            not isinstance(хэши_пары, list)
            or len(хэши_пары) != 2
            or хэши_пары != sorted(set(хэши_пары))
            or запись["хэш_привязки"] not in хэши_пары
            or any(re.fullmatch(r"sha256:[0-9a-f]{64}", str(хэш)) is None for хэш in хэши_пары)
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "повреждённый_реестр_барьеров",
                "Запись барьера имеет неверную пару хэшей host-привязок.",
            )
        if запись["хэш_активации"] != вычислить_хэш_активации_барьера(
            str(запись["поколение_запуска"]),
            str(запись["хэш_предактивации"]),
            str(запись["квитанция_активации"]),
            [str(хэш) for хэш in хэши_пары],
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "повреждённый_реестр_барьеров",
                "Доказательство активации не коммитит exact-пару host-привязок.",
            )
        проверить_полный_объект(
            запись["открыт_из_объекта"],
            состояние_ошибки="повреждённый_реестр_барьеров",
            сообщение="Запись барьера имеет неверную CAS-основу открытия.",
        )
    return запись


def проверить_реестр_барьеров(
    значение: object,
    контекст: QueueContext,
) -> dict[str, object]:
    if (
        isinstance(значение, dict)
        and значение.get("схема")
        == ПРЕЖНЯЯ_СХЕМА_РЕЕСТРА_БАРЬЕРОВ_ПРЕДАКТИВАЦИИ
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "устаревшая_схема_реестра_барьеров",
            "Реестр барьеров версии 1 не коммитит хэш назначения и ресурсную попытку; автоматическая миграция запрещена.",
        )
    if (
        not isinstance(значение, dict)
        or set(значение) != {
            "схема",
            "идентификатор_рабочей_копии",
            "барьеры",
        }
        or значение["схема"]
        != СХЕМА_РЕЕСТРА_БАРЬЕРОВ_ПРЕДАКТИВАЦИИ
        or значение["идентификатор_рабочей_копии"] != контекст.worktree_id
        or not isinstance(значение["барьеры"], list)
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Git-ссылка реестра барьеров содержит неизвестный контракт.",
        )
    барьеры = [
        проверить_запись_барьера(запись)
        for запись in значение["барьеры"]
    ]
    ключи = [
        (
            str(запись["ветка"]),
            str(запись["идентификатор_форка"]),
            str(запись["идентификатор_попытки_создания"]),
        )
        for запись in барьеры
    ]
    if ключи != sorted(ключи) or len(ключи) != len(set(ключи)):
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Барьеры не имеют канонического порядка или содержат дубликат.",
        )
    if len(барьеры) > 1:
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Начальный профиль допускает одну постоянную веточную привязку checkout.",
        )
    for индекс, левый in enumerate(барьеры):
        for правый in барьеры[индекс + 1 :]:
            if any(
                левый[поле] == правый[поле]
                for поле in (
                    "ветка",
                    "идентификатор_форка",
                    "идентификатор_попытки_создания",
                )
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "повреждённый_реестр_барьеров",
                    "Реестр содержит дублирующего владельца барьера.",
                )
            if (
                левый.get("идентификатор_задачи") is not None
                and левый.get("идентификатор_задачи")
                == правый.get("идентификатор_задачи")
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "повреждённый_реестр_барьеров",
                    "Одна задача связана с двумя барьерами.",
                )
            if (
                левый.get("идентификатор_среды") is not None
                and левый.get("идентификатор_среды")
                == правый.get("идентификатор_среды")
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "повреждённый_реестр_барьеров",
                    "Одна среда связана с двумя барьерами.",
                )
    return значение


def новый_реестр_барьеров(контекст: QueueContext) -> dict[str, object]:
    return {
        "схема": СХЕМА_РЕЕСТРА_БАРЬЕРОВ_ПРЕДАКТИВАЦИИ,
        "идентификатор_рабочей_копии": контекст.worktree_id,
        "барьеры": [],
    }


def прочитать_реестр_барьеров(
    контекст: QueueContext,
) -> tuple[dict[str, object], str | None]:
    ссылка = ссылка_реестра_барьеров_предактивации(контекст)
    объект = read_ref_oid(контекст, ссылка)
    if объект is None:
        return новый_реестр_барьеров(контекст), None
    сырые = run_git(контекст.root, ["cat-file", "blob", объект]).stdout
    try:
        значение = json.loads(
            сырые.decode("utf-8", errors="strict"),
            object_pairs_hook=собрать_объект_без_повторов,
            parse_constant=отклонить_неконечное_число,
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as ошибка:
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Git-ссылка реестра барьеров не содержит корректный JSON.",
        ) from ошибка
    реестр = проверить_реестр_барьеров(значение, контекст)
    if сырые != канонические_байты_реестра_барьеров(реестр):
        raise QueueError(
            EXIT_CONTEXT,
            "повреждённый_реестр_барьеров",
            "Git-реестр барьеров неканоничен.",
        )
    return реестр, объект


def записать_реестр_барьеров(
    контекст: QueueContext,
    реестр: dict[str, object],
) -> str:
    проверить_реестр_барьеров(реестр, контекст)
    результат = run_git(
        контекст.root,
        ["hash-object", "-w", "--stdin"],
        input_bytes=канонические_байты_реестра_барьеров(реестр),
    )
    return decoded_stdout(результат)


def запись_барьера_из_аргументов(
    контекст: QueueContext,
    ветка: str,
    базовая_вершина: str,
    идентификатор_форка: str,
    поколение_запуска: str,
    идентификатор_попытки_создания: str,
    идентификатор_назначения: str,
    хэш_назначения: str,
    идентификатор_ресурсной_попытки: str,
    хэш_ресурсного_допуска: str,
) -> dict[str, object]:
    ensure_live_branch(контекст)
    if ветка != контекст.branch_ref:
        raise QueueError(
            EXIT_CONTEXT,
            "несовпавшая_ветка_барьера",
            "Ветка барьера не совпадает с текущим symbolic HEAD.",
        )
    текущая_вершина = current_head(контекст.root)
    if базовая_вершина != текущая_вершина:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "несовпавшая_вершина_барьера",
            "Базовая вершина барьера не совпадает с текущей вершиной.",
        )
    проверить_однострочное_значение(идентификатор_форка, "идентификатор форка")
    проверить_однострочное_значение(поколение_запуска, "поколение запуска")
    проверить_однострочное_значение(
        идентификатор_попытки_создания,
        "идентификатор попытки создания",
    )
    проверить_однострочное_значение(
        идентификатор_назначения,
        "идентификатор назначения",
    )
    проверить_хэш_sha256(
        хэш_назначения,
        "Хэш назначения должен иметь вид sha256:<64 hex>.",
    )
    проверить_однострочное_значение(
        идентификатор_ресурсной_попытки,
        "идентификатор ресурсной попытки",
    )
    проверить_хэш_sha256(
        хэш_ресурсного_допуска,
        "Хэш ресурсного допуска должен иметь вид sha256:<64 hex>.",
    )
    return {
        "ветка": ветка,
        "базовая_вершина": базовая_вершина,
        "идентификатор_форка": идентификатор_форка,
        "поколение_запуска": поколение_запуска,
        "идентификатор_попытки_создания": идентификатор_попытки_создания,
        "идентификатор_назначения": идентификатор_назначения,
        "хэш_назначения": хэш_назначения,
        "идентификатор_ресурсной_попытки": идентификатор_ресурсной_попытки,
        "хэш_ресурсного_допуска": хэш_ресурсного_допуска,
        "состояние": "не_связан",
    }


def совпадают_ограждения_барьера(
    левая: dict[str, object],
    правая: dict[str, object],
) -> bool:
    return all(
        левая[поле] == правая[поле]
        for поле in (
            "ветка",
            "базовая_вершина",
            "идентификатор_форка",
            "поколение_запуска",
            "идентификатор_попытки_создания",
            "идентификатор_назначения",
            "хэш_назначения",
            "идентификатор_ресурсной_попытки",
            "хэш_ресурсного_допуска",
        )
    )


def данные_реестра_барьеров(
    контекст: QueueContext,
    объект: str,
) -> dict[str, object]:
    return {
        "ссылка_реестра_барьеров": ссылка_реестра_барьеров_предактивации(контекст),
        "объект_реестра_барьеров": объект,
        **common_payload(контекст, read_ref_oid(контекст, контекст.queue_ref)),
    }


def найти_барьер_ветки(
    реестр: dict[str, object],
    ветка: str,
) -> dict[str, object] | None:
    for запись in реестр["барьеры"]:
        if запись["ветка"] == ветка:
            return запись
    return None


def установить_барьер_предактивации(
    контекст: QueueContext,
    ветка: str,
    базовая_вершина: str,
    идентификатор_форка: str,
    поколение_запуска: str,
    идентификатор_попытки_создания: str,
    идентификатор_назначения: str,
    хэш_назначения: str,
    идентификатор_ресурсной_попытки: str,
    хэш_ресурсного_допуска: str,
) -> tuple[int, dict[str, object]]:
    новая_запись = запись_барьера_из_аргументов(
        контекст,
        ветка,
        базовая_вершина,
        идентификатор_форка,
        поколение_запуска,
        идентификатор_попытки_создания,
        идентификатор_назначения,
        хэш_назначения,
        идентификатор_ресурсной_попытки,
        хэш_ресурсного_допуска,
    )
    ссылка_барьеров = ссылка_реестра_барьеров_предактивации(контекст)
    последняя_ошибка = ""
    for _ in range(MAX_CAS_ATTEMPTS):
        запись_барьера_из_аргументов(
            контекст,
            ветка,
            базовая_вершина,
            идентификатор_форка,
            поколение_запуска,
            идентификатор_попытки_создания,
            идентификатор_назначения,
            хэш_назначения,
            идентификатор_ресурсной_попытки,
            хэш_ресурсного_допуска,
        )
        состояние_очереди, объект_очереди = read_state(контекст)
        состояние_очереди = ensure_state_identity(
            контекст,
            состояние_очереди,
            allow_idle_rebind=True,
        )
        if (
            состояние_очереди["owner"] is not None
            or состояние_очереди["waiting"]
            or состояние_очереди["next_seq"] != 1
            or состояние_очереди["last_completion"] is not None
        ):
            raise QueueError(
                EXIT_OWNERSHIP,
                "очередь_занята_до_предактивации",
                "Барьер можно установить только в ни разу не использованной FIFO до первого билета живой ветки.",
            )
        реестр, прежний_объект = прочитать_реестр_барьеров(контекст)
        существующий = найти_барьер_ветки(реестр, ветка)
        if существующий is not None:
            if совпадают_ограждения_барьера(существующий, новая_запись):
                return 0, {
                    "state": "барьер_предактивации_уже_установлен",
                    "состояние_барьера": существующий["состояние"],
                    **данные_реестра_барьеров(контекст, str(прежний_объект)),
                }
            raise QueueError(
                EXIT_CONTEXT,
                "несовпавший_барьер_предактивации",
                "Существующий барьер имеет иные ограждения.",
            )
        if реестр["барьеры"]:
            raise QueueError(
                EXIT_OWNERSHIP,
                "рабочая_копия_связана_с_другой_веткой",
                "Физический checkout уже навсегда связан с другой начальной веткой.",
            )
        for запись in реестр["барьеры"]:
            if any(
                запись[поле] == новая_запись[поле]
                for поле in (
                    "идентификатор_форка",
                    "идентификатор_попытки_создания",
                )
            ):
                raise QueueError(
                    EXIT_OWNERSHIP,
                    "дублирующий_владелец_барьера",
                    "Форк или попытка создания уже владеют другим барьером.",
                )
        обновлённый = copy.deepcopy(реестр)
        обновлённый["барьеры"].append(новая_запись)
        обновлённый["барьеры"].sort(
            key=lambda запись: (
                запись["ветка"],
                запись["идентификатор_форка"],
                запись["идентификатор_попытки_создания"],
            )
        )
        новый_объект = записать_реестр_барьеров(контекст, обновлённый)
        нулевой_объект = "0" * len(базовая_вершина)
        команда_очереди = (
            f"verify {контекст.queue_ref} {объект_очереди or нулевой_объект}\n"
        )
        команда_барьера = (
            f"create {ссылка_барьеров} {новый_объект}\n"
            if прежний_объект is None
            else f"update {ссылка_барьеров} {новый_объект} {прежний_объект}\n"
        )
        команды = (
            "start\n"
            f"verify {ветка} {базовая_вершина}\n"
            f"{команда_очереди}"
            f"{команда_барьера}"
            "prepare\n"
            "commit\n"
        ).encode("utf-8")
        результат = run_git(
            контекст.root,
            ["update-ref", "--stdin"],
            input_bytes=команды,
            check=False,
        )
        if результат.returncode == 0:
            ensure_live_branch(контекст)
            return 0, {
                "state": "барьер_предактивации_установлен",
                **данные_реестра_барьеров(контекст, новый_объект),
            }
        последняя_ошибка = результат.stderr.decode("utf-8", errors="replace").strip()
        time.sleep(REF_RETRY_BASE_SECONDS)
    update_ref_error("атомарно установить барьер предактивации", последняя_ошибка)


def связать_задачу_барьера(
    контекст: QueueContext,
    идентификатор_задачи: str,
    идентификатор_среды: str,
    хэш_конверта: str,
    хэш_привязки: str,
    ветка: str,
    базовая_вершина: str,
    идентификатор_форка: str,
    поколение_запуска: str,
    идентификатор_попытки_создания: str,
    идентификатор_назначения: str,
    хэш_назначения: str,
    идентификатор_ресурсной_попытки: str,
    хэш_ресурсного_допуска: str,
    ожидаемый_объект_реестра: str,
) -> tuple[int, dict[str, object]]:
    идентификатор_задачи = validate_task_id(идентификатор_задачи)
    проверить_однострочное_значение(идентификатор_среды, "идентификатор среды")
    проверить_хэш_sha256(
        хэш_конверта,
        "Хэш конверта должен иметь вид sha256:<64 hex>.",
    )
    проверить_хэш_sha256(
        хэш_привязки,
        "Хэш привязки должен иметь вид sha256:<64 hex>.",
    )
    ожидаемая_запись = запись_барьера_из_аргументов(
        контекст,
        ветка,
        базовая_вершина,
        идентификатор_форка,
        поколение_запуска,
        идентификатор_попытки_создания,
        идентификатор_назначения,
        хэш_назначения,
        идентификатор_ресурсной_попытки,
        хэш_ресурсного_допуска,
    )
    проверить_полный_объект(
        ожидаемый_объект_реестра,
        состояние_ошибки="неверный_объект_реестра_барьеров",
        сообщение="Ожидаемый объект реестра имеет неверный формат.",
    )
    ссылка = ссылка_реестра_барьеров_предактивации(контекст)
    реестр, текущий_объект = прочитать_реестр_барьеров(контекст)
    if текущий_объект is None:
        raise QueueError(
            EXIT_NOT_REGISTERED,
            "барьер_предактивации_не_найден",
            "Реестр барьеров ещё не установлен.",
        )
    запись = найти_барьер_ветки(реестр, ветка)
    if запись is None:
        raise QueueError(
            EXIT_NOT_REGISTERED,
            "барьер_предактивации_не_найден",
            "Для точной ветки барьер не установлен.",
        )
    if not совпадают_ограждения_барьера(запись, ожидаемая_запись):
        raise QueueError(
            EXIT_CONTEXT,
            "несовпавший_барьер_предактивации",
            "Квитанция, хэш или ограждения не совпадают с установленным барьером.",
        )
    вычисленный_хэш_привязки = вычислить_хэш_привязки_барьера(
        запись,
        идентификатор_задачи,
        идентификатор_среды,
        хэш_конверта,
    )
    if хэш_привязки != вычисленный_хэш_привязки:
        raise QueueError(
            EXIT_CONTEXT,
            "несовпавший_хэш_привязки_барьера",
            "Хэш привязки не соответствует exact task, host и полному конверту.",
        )
    if запись["состояние"] in {"связан", "открыт"}:
        if any(
            запись[поле] != значение
            for поле, значение in (
                ("идентификатор_задачи", идентификатор_задачи),
                ("идентификатор_среды", идентификатор_среды),
                ("хэш_конверта", хэш_конверта),
                ("хэш_привязки", хэш_привязки),
            )
        ):
            raise QueueError(
                EXIT_OWNERSHIP,
                "дублирующая_привязка_задачи_барьера",
                "Барьер уже связан с другой точной задачей.",
            )
        if ожидаемый_объект_реестра not in {
            текущий_объект,
            запись["связан_из_объекта"],
        }:
            raise QueueError(
                EXIT_CAS,
                "устаревший_реестр_барьеров",
                "CAS-основа не совпадает ни с текущим снимком, ни с точной основой уже выполненной привязки.",
            )
        return 0, {
            "state": "задача_барьера_уже_связана",
            **данные_реестра_барьеров(контекст, текущий_объект),
        }
    if ожидаемый_объект_реестра != текущий_объект:
        raise QueueError(
            EXIT_CAS,
            "устаревший_реестр_барьеров",
            "CAS-основа не совпадает с текущим реестром барьеров.",
        )
    обновлённый = copy.deepcopy(реестр)
    обновляемая_запись = найти_барьер_ветки(обновлённый, ветка)
    if обновляемая_запись is None:  # pragma: no cover - deep copy preserves the record.
        raise AssertionError("Барьер исчез при копировании реестра.")
    for другая_запись in обновлённый["барьеры"]:
        if (
            другая_запись is not обновляемая_запись
            and другая_запись.get("идентификатор_задачи") == идентификатор_задачи
        ):
            raise QueueError(
                EXIT_OWNERSHIP,
                "дублирующая_привязка_задачи_барьера",
                "Задача уже связана с другим барьером.",
            )
        if (
            другая_запись is not обновляемая_запись
            and другая_запись.get("идентификатор_среды") == идентификатор_среды
        ):
            raise QueueError(
                EXIT_OWNERSHIP,
                "дублирующая_привязка_среды_барьера",
                "Среда уже связана с другим барьером.",
            )
    обновляемая_запись["состояние"] = "связан"
    обновляемая_запись["идентификатор_задачи"] = идентификатор_задачи
    обновляемая_запись["идентификатор_среды"] = идентификатор_среды
    обновляемая_запись["хэш_конверта"] = хэш_конверта
    обновляемая_запись["хэш_привязки"] = хэш_привязки
    обновляемая_запись["связан_из_объекта"] = текущий_объект
    новый_объект = записать_реестр_барьеров(контекст, обновлённый)
    команды = (
        "start\n"
        f"verify {ветка} {базовая_вершина}\n"
        f"update {ссылка} {новый_объект} {текущий_объект}\n"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    результат = run_git(
        контекст.root,
        ["update-ref", "--stdin"],
        input_bytes=команды,
        check=False,
    )
    if результат.returncode == 0:
        ensure_live_branch(контекст)
        return 0, {
            "state": "задача_барьера_связана",
            **данные_реестра_барьеров(контекст, новый_объект),
        }
    наблюдаемый_реестр, наблюдаемый_объект = прочитать_реестр_барьеров(контекст)
    наблюдаемая_запись = найти_барьер_ветки(наблюдаемый_реестр, ветка)
    if (
        наблюдаемая_запись is not None
        and совпадают_ограждения_барьера(наблюдаемая_запись, ожидаемая_запись)
        and наблюдаемая_запись["состояние"] in {"связан", "открыт"}
        and наблюдаемая_запись["идентификатор_задачи"] == идентификатор_задачи
        and наблюдаемая_запись["идентификатор_среды"] == идентификатор_среды
        and наблюдаемая_запись["хэш_конверта"] == хэш_конверта
        and наблюдаемая_запись["хэш_привязки"] == хэш_привязки
        and наблюдаемая_запись["связан_из_объекта"] == текущий_объект
    ):
        return 0, {
            "state": "задача_барьера_уже_связана",
            **данные_реестра_барьеров(контекст, str(наблюдаемый_объект)),
        }
    raise QueueError(
        EXIT_CAS,
        "устаревший_реестр_барьеров",
        "Реестр изменился до атомарной привязки задачи барьера.",
    )


def открыть_барьер_предактивации(
    контекст: QueueContext,
    идентификатор_задачи: str,
    ветка: str,
    базовая_вершина: str,
    идентификатор_форка: str,
    поколение_запуска: str,
    идентификатор_попытки_создания: str,
    идентификатор_назначения: str,
    хэш_назначения: str,
    идентификатор_ресурсной_попытки: str,
    хэш_ресурсного_допуска: str,
    квитанция_активации: str,
    хэш_предактивации: str,
    хэши_привязок_пары: list[str],
    хэш_активации: str,
    ожидаемый_объект_реестра: str,
) -> tuple[int, dict[str, object]]:
    идентификатор_задачи = validate_task_id(идентификатор_задачи)
    ожидаемая_запись = запись_барьера_из_аргументов(
        контекст,
        ветка,
        базовая_вершина,
        идентификатор_форка,
        поколение_запуска,
        идентификатор_попытки_создания,
        идентификатор_назначения,
        хэш_назначения,
        идентификатор_ресурсной_попытки,
        хэш_ресурсного_допуска,
    )
    проверить_хэш_sha256(
        квитанция_активации,
        "Квитанция активации должна иметь вид sha256:<64 hex>.",
    )
    проверить_хэш_sha256(
        хэш_предактивации,
        "Хэш предактивации должен иметь вид sha256:<64 hex>.",
    )
    проверить_хэш_sha256(
        хэш_активации,
        "Хэш активации должен иметь вид sha256:<64 hex>.",
    )
    if (
        len(хэши_привязок_пары) != 2
        or хэши_привязок_пары != sorted(set(хэши_привязок_пары))
        or any(re.fullmatch(r"sha256:[0-9a-f]{64}", хэш) is None for хэш in хэши_привязок_пары)
    ):
        raise QueueError(
            EXIT_CLI,
            "неверное_ограждение_предактивации",
            "Открытие требует ровно два разных сортированных хэша host-привязок.",
        )
    проверить_полный_объект(
        ожидаемый_объект_реестра,
        состояние_ошибки="неверный_объект_реестра_барьеров",
        сообщение="Ожидаемый объект реестра имеет неверный формат.",
    )
    ссылка = ссылка_реестра_барьеров_предактивации(контекст)
    реестр, текущий_объект = прочитать_реестр_барьеров(контекст)
    if текущий_объект is None:
        raise QueueError(
            EXIT_NOT_REGISTERED,
            "барьер_предактивации_не_найден",
            "Реестр барьеров ещё не установлен.",
        )
    запись = найти_барьер_ветки(реестр, ветка)
    if запись is None:
        raise QueueError(
            EXIT_NOT_REGISTERED,
            "барьер_предактивации_не_найден",
            "Для точной ветки барьер не установлен.",
        )
    if not совпадают_ограждения_барьера(запись, ожидаемая_запись):
        raise QueueError(
            EXIT_CONTEXT,
            "несовпавший_барьер_предактивации",
            "Квитанция, хэш или ограждения не совпадают с установленным барьером.",
        )
    if запись["состояние"] == "не_связан":
        raise QueueError(
            EXIT_OWNERSHIP,
            "задача_барьера_не_связана",
            "Барьер нельзя открыть до точной привязки результата host-вызова.",
        )
    if запись["идентификатор_задачи"] != идентификатор_задачи:
        raise QueueError(
            EXIT_OWNERSHIP,
            "несовпавшая_задача_барьера",
            "Открытие запрошено не для связанной задачи барьера.",
        )
    if запись["хэш_привязки"] not in хэши_привязок_пары:
        raise QueueError(
            EXIT_CONTEXT,
            "несовпавшая_пара_привязок_барьера",
            "Доказательство активации не содержит exact host-привязку этой ветви.",
        )
    вычисленный_хэш_активации = вычислить_хэш_активации_барьера(
        поколение_запуска,
        хэш_предактивации,
        квитанция_активации,
        хэши_привязок_пары,
    )
    if хэш_активации != вычисленный_хэш_активации:
        raise QueueError(
            EXIT_CONTEXT,
            "несовпавшее_доказательство_активации",
            "Хэш активации не коммитит exact поколение, квитанцию и обе host-привязки.",
        )
    if запись["состояние"] == "открыт":
        if (
            запись["квитанция_активации"] != квитанция_активации
            or запись["хэш_предактивации"] != хэш_предактивации
            or запись["хэши_привязок_пары"] != хэши_привязок_пары
            or запись["хэш_активации"] != хэш_активации
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "несовпавший_барьер_предактивации",
                "Фактическая квитанция или хэш активации не совпадают с открытым барьером.",
            )
        if ожидаемый_объект_реестра not in {
            текущий_объект,
            запись["открыт_из_объекта"],
        }:
            raise QueueError(
                EXIT_CAS,
                "устаревший_реестр_барьеров",
                "CAS-основа не совпадает ни с текущим снимком, ни с точной основой уже выполненного открытия.",
            )
        return 0, {
            "state": "барьер_предактивации_уже_открыт",
            **данные_реестра_барьеров(контекст, текущий_объект),
        }
    if ожидаемый_объект_реестра != текущий_объект:
        raise QueueError(
            EXIT_CAS,
            "устаревший_реестр_барьеров",
            "CAS-основа не совпадает с текущим реестром барьеров.",
        )
    обновлённый = copy.deepcopy(реестр)
    обновляемая_запись = найти_барьер_ветки(обновлённый, ветка)
    if обновляемая_запись is None:  # pragma: no cover - deep copy preserves the record.
        raise AssertionError("Барьер исчез при копировании реестра.")
    обновляемая_запись["состояние"] = "открыт"
    обновляемая_запись["квитанция_активации"] = квитанция_активации
    обновляемая_запись["хэш_предактивации"] = хэш_предактивации
    обновляемая_запись["хэши_привязок_пары"] = хэши_привязок_пары
    обновляемая_запись["хэш_активации"] = хэш_активации
    обновляемая_запись["открыт_из_объекта"] = текущий_объект
    новый_объект = записать_реестр_барьеров(контекст, обновлённый)
    команды = (
        "start\n"
        f"verify {ветка} {базовая_вершина}\n"
        f"update {ссылка} {новый_объект} {текущий_объект}\n"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    результат = run_git(
        контекст.root,
        ["update-ref", "--stdin"],
        input_bytes=команды,
        check=False,
    )
    if результат.returncode == 0:
        ensure_live_branch(контекст)
        return 0, {
            "state": "барьер_предактивации_открыт",
            **данные_реестра_барьеров(контекст, новый_объект),
        }
    наблюдаемый_реестр, наблюдаемый_объект = прочитать_реестр_барьеров(контекст)
    наблюдаемая_запись = найти_барьер_ветки(наблюдаемый_реестр, ветка)
    if (
        наблюдаемая_запись is not None
        and совпадают_ограждения_барьера(наблюдаемая_запись, ожидаемая_запись)
        and наблюдаемая_запись["состояние"] == "открыт"
        and наблюдаемая_запись["квитанция_активации"] == квитанция_активации
        and наблюдаемая_запись["хэш_предактивации"] == хэш_предактивации
        and наблюдаемая_запись["хэши_привязок_пары"] == хэши_привязок_пары
        and наблюдаемая_запись["хэш_активации"] == хэш_активации
        and наблюдаемая_запись["открыт_из_объекта"] == текущий_объект
    ):
        return 0, {
            "state": "барьер_предактивации_уже_открыт",
            **данные_реестра_барьеров(контекст, str(наблюдаемый_объект)),
        }
    raise QueueError(
        EXIT_CAS,
        "устаревший_реестр_барьеров",
        "Реестр изменился до атомарного открытия барьера.",
    )


def задача_барьера_уже_вошла_в_очередь(
    состояние_очереди: dict[str, object],
    идентификатор_задачи: str,
    объект_реестра_барьеров: str,
) -> bool:
    свидетельство = состояние_очереди.get(ПОЛЕ_ДОПУЩЕННОЙ_ЗАДАЧИ_БАРЬЕРА)
    return (
        isinstance(свидетельство, dict)
        and свидетельство["task_id"] == идентификатор_задачи
        and свидетельство["объект_реестра_барьеров"]
        == объект_реестра_барьеров
    )


def потребовать_открытый_барьер_предактивации(
    контекст: QueueContext,
    идентификатор_задачи: str,
    состояние_очереди: dict[str, object],
) -> tuple[
    str | None,
    str | None,
    str | None,
    str | None,
    str | None,
    str | None,
]:
    реестр, объект_реестра = прочитать_реестр_барьеров(контекст)
    if объект_реестра is None:
        return None, None, None, None, None, None
    барьер = найти_барьер_ветки(реестр, контекст.branch_ref)
    if барьер is None:
        raise QueueError(
            EXIT_OWNERSHIP,
            "рабочая_копия_связана_с_другой_веткой",
            "Checkout-scoped реестр закрывает join ветки без exact постоянной привязки.",
        )
    if барьер["состояние"] == "не_связан":
        raise QueueError(
            EXIT_OWNERSHIP,
            "задача_барьера_не_связана",
            "Ни одна задача не может войти в FIFO до привязки точного результата host-вызова.",
            данные_результата_операции={
                "ссылка_реестра_барьеров": ссылка_реестра_барьеров_предактивации(контекст),
                "объект_реестра_барьеров": объект_реестра,
            },
        )
    задача_барьера = str(барьер["идентификатор_задачи"])
    if идентификатор_задачи == задача_барьера:
        if барьер["состояние"] == "открыт":
            базовая_вершина = None
            if not задача_барьера_уже_вошла_в_очередь(
                состояние_очереди,
                задача_барьера,
                объект_реестра,
            ):
                базовая_вершина = str(барьер["базовая_вершина"])
            return (
                объект_реестра,
                базовая_вершина,
                str(барьер["идентификатор_назначения"]),
                str(барьер["хэш_назначения"]),
                str(барьер["идентификатор_ресурсной_попытки"]),
                str(барьер["хэш_ресурсного_допуска"]),
            )
        raise QueueError(
            EXIT_OWNERSHIP,
            "предактивация_не_подтверждена",
            "Точная задача не может войти в FIFO до открытия барьера глобальной квитанцией активации.",
            данные_результата_операции={
                "ссылка_реестра_барьеров": ссылка_реестра_барьеров_предактивации(контекст),
                "объект_реестра_барьеров": объект_реестра,
            },
        )
    if задача_барьера_уже_вошла_в_очередь(
        состояние_очереди,
        задача_барьера,
        объект_реестра,
    ):
        return (
            объект_реестра,
            None,
            str(барьер["идентификатор_назначения"]),
            str(барьер["хэш_назначения"]),
            str(барьер["идентификатор_ресурсной_попытки"]),
            str(барьер["хэш_ресурсного_допуска"]),
        )
    raise QueueError(
        EXIT_OWNERSHIP,
        "барьер_предактивации_занят",
        "Первым владельцем живой ветки может стать только точная задача открытого барьера.",
    )


def подготовить_внешнее_ограждение(
    контекст: QueueContext,
    ограждающая_ссылка: str | None,
    ожидаемый_объект: str | None,
) -> tuple[str, str | None]:
    if ограждающая_ссылка is None and ожидаемый_объект is None:
        return "", None
    if ограждающая_ссылка is None or ожидаемый_объект is None:
        raise QueueError(
            EXIT_CLI,
            "invalid_guard",
            "Guard требует одновременно ссылку и ожидаемый объект.",
        )
    if (
        not ограждающая_ссылка.startswith("refs/fum/")
        or "\n" in ограждающая_ссылка
        or "\0" in ограждающая_ссылка
    ):
        raise QueueError(
            EXIT_CLI,
            "invalid_guard",
            "Guard допускает только полную служебную ссылку refs/fum/....",
        )
    проверка_ссылки = run_git(
        контекст.root,
        ["check-ref-format", ограждающая_ссылка],
        check=False,
    )
    if проверка_ссылки.returncode != 0:
        raise QueueError(
            EXIT_CLI,
            "invalid_guard",
            "Guard содержит некорректную Git-ссылку.",
        )
    длина_объекта = len(current_head(контекст.root))
    if ожидаемый_объект == "absent":
        нормализованный_объект = None
        объект_для_проверки = "0" * длина_объекта
    else:
        if (
            re.fullmatch(r"[0-9a-f]+", ожидаемый_объект) is None
            or len(ожидаемый_объект) != длина_объекта
        ):
            raise QueueError(
                EXIT_CLI,
                "invalid_guard",
                "Guard содержит объект неверного формата.",
            )
        нормализованный_объект = ожидаемый_объект
        объект_для_проверки = ожидаемый_объект
    команда = f"verify {ограждающая_ссылка} {объект_для_проверки}\n"
    return команда, нормализованный_объект


def прочитать_запись_очереди(
    контекст_очереди: QueueContext,
    *,
    разрешить_переход_на_цепочку: bool = False,
) -> tuple[str, dict[str, object], str | None]:
    идентификатор_объекта_репозитория = read_ref_oid(контекст_очереди, контекст_очереди.queue_ref)
    if идентификатор_объекта_репозитория is None:
        return "очередь", new_state(контекст_очереди), None
    blob = run_git(контекст_очереди.root, ["cat-file", "blob", идентификатор_объекта_репозитория])
    try:
        значение = json.loads(
            blob.stdout.decode("utf-8", errors="strict"),
            object_pairs_hook=собрать_объект_без_повторов,
            parse_constant=отклонить_неконечное_число,
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Git-ссылка очереди не содержит корректный JSON blob.",
        ) from exc
    if isinstance(значение, dict) and значение.get("схема") == СХЕМА_СБРОСА:
        return "сброс", проверить_запись_сброса(значение, контекст_очереди), идентификатор_объекта_репозитория
    if (
        isinstance(значение, dict)
        and значение.get("схема") == СХЕМА_ПРОСТОГО_СБРОСА
    ):
        return (
            "сброс",
            проверить_запись_простого_сброса(значение, контекст_очереди),
            идентификатор_объекта_репозитория,
        )
    if (
        isinstance(значение, dict)
        and значение.get("схема") == СХЕМА_ПЕРЕХОДА_НА_ЦЕПОЧКУ
    ):
        переход = проверить_запись_перехода_на_цепочку(
            значение,
            контекст_очереди,
        )
        if not разрешить_переход_на_цепочку:
            raise QueueError(
                КОД_ИДЁТ_ПЕРЕХОД_НА_ЦЕПОЧКУ,
                "chain_transition_in_progress",
                "Обычная операция очереди запрещена во время перехода на цепочку.",
                данные_результата_операции={
                    "идентификатор_цепочки": переход["идентификатор_цепочки"],
                    "идентификатор_задачи": переход["идентификатор_задачи"],
                    "исходная_ветка": переход["исходная_ветка"],
                    "целевая_ветка": переход["целевая_ветка"],
                    **common_payload(
                        контекст_очереди,
                        идентификатор_объекта_репозитория,
                    ),
                },
            )
        return "переход", переход, идентификатор_объекта_репозитория
    return "очередь", validate_state(значение), идентификатор_объекта_репозитория


def read_state(контекст_очереди: QueueContext) -> tuple[dict[str, object], str | None]:
    вид, запись, идентификатор_объекта_репозитория = прочитать_запись_очереди(контекст_очереди)
    if вид == "сброс":
        raise QueueError(
            КОД_ИДЁТ_СБРОС,
            "reset_in_progress",
            "Обычная операция очереди запрещена во время штатного сброса.",
            данные_результата_операции={
                "идентификатор_сброса": запись["идентификатор_сброса"],
                "фаза": запись["фаза"],
                **common_payload(контекст_очереди, идентификатор_объекта_репозитория),
            },
        )
    return запись, идентификатор_объекта_репозитория


def ref_retry_delay(attempt: int) -> float:
    return min(REF_RETRY_BASE_SECONDS * (2**attempt), REF_RETRY_MAX_SECONDS)


def update_ref_error(operation: str, stderr: str) -> NoReturn:
    detail = stderr.strip() or "Git не вернул текст ошибки."
    raise QueueError(
        EXIT_CAS,
        "git_error",
        f"Не удалось {operation}: {detail}",
        данные_результата_операции={"git_stderr": detail},
    )


def write_state_blob(контекст_очереди: QueueContext, state: dict[str, object]) -> str:
    validate_state(state)
    result = run_git(
        контекст_очереди.root,
        ["hash-object", "-w", "--stdin"],
        input_bytes=canonical_state_bytes(state),
    )
    return decoded_stdout(result)


def записать_объект_сброса(
    контекст: QueueContext,
    запись: dict[str, object],
) -> str:
    проверить_запись_сброса(запись, контекст)
    результат = run_git(
        контекст.root,
        ["hash-object", "-w", "--stdin"],
        input_bytes=канонические_байты_сброса(запись),
    )
    return decoded_stdout(результат)


def ссылка_квитанции_сброса(
    контекст: QueueContext,
    идентификатор_сброса: str,
) -> str:
    if re.fullmatch(r"sha256:[0-9a-f]{64}", идентификатор_сброса) is None:
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Неверен идентификатор квитанции сброса.")
    ветка = hashlib.sha256(контекст.branch_ref.encode("utf-8")).hexdigest()
    return (
        f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_СБРОСА}/{контекст.worktree_id}/"
        f"{ветка}/{идентификатор_сброса.removeprefix('sha256:')}"
    )


def канонические_байты_квитанции_сброса(квитанция: dict[str, object]) -> bytes:
    return (
        json.dumps(
            квитанция,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def проверить_квитанцию_сброса(
    значение: object,
    контекст: QueueContext,
) -> dict[str, object]:
    поля = {
        "схема",
        "идентификатор_рабочей_копии",
        "ссылка_ветки",
        "идентификатор_сброса",
        "идентификатор_диспетчера",
        "целевая_вершина",
        "объект_записи_сброса",
        "запись_сброса",
        "исходный_объект_очереди",
        "объект_очереди_после",
        "состояние_очереди_после",
        "аннулированные_задачи",
        "неактивные_задачи",
        "предыдущее_завершение",
        "завершено",
    }
    if (
        not isinstance(значение, dict)
        or set(значение) != поля
        or значение.get("схема") != СХЕМА_КВИТАНЦИИ_СБРОСА
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Квитанция сброса имеет неизвестную схему.")
    if (
        значение["идентификатор_рабочей_копии"] != контекст.worktree_id
        or значение["ссылка_ветки"] != контекст.branch_ref
    ):
        raise QueueError(EXIT_CONTEXT, "invalid_context", "Квитанция сброса принадлежит другому checkout или ветке.")
    идентификатор_сброса = значение["идентификатор_сброса"]
    if not isinstance(идентификатор_сброса, str):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Квитанция сброса не имеет идентификатора.")
    ссылка_квитанции_сброса(контекст, идентификатор_сброса)
    validate_task_id(значение["идентификатор_диспетчера"])
    длина_объекта = len(current_head(контекст.root))
    for поле in ("целевая_вершина", "объект_записи_сброса", "объект_очереди_после"):
        объект = значение[поле]
        if not isinstance(объект, str) or re.fullmatch(r"[0-9a-f]+", объект) is None or len(объект) != длина_объекта:
            raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", f"Квитанция сброса имеет неверное поле {поле}.")
    исходный_объект = значение["исходный_объект_очереди"]
    if исходный_объект is not None and (
        not isinstance(исходный_объект, str)
        or re.fullmatch(r"[0-9a-f]+", исходный_объект) is None
        or len(исходный_объект) != длина_объекта
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Квитанция сброса имеет неверный исходный объект.")
    for поле in ("аннулированные_задачи", "неактивные_задачи"):
        задачи = значение[поле]
        if not isinstance(задачи, list):
            raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", f"Квитанция сброса не имеет списка {поле}.")
        for задача in задачи:
            validate_task_id(задача)
        if задачи != sorted(set(задачи)):
            raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", f"Список {поле} в квитанции неканоничен.")
    if not isinstance(значение["завершено"], str) or not значение["завершено"]:
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Квитанция сброса не имеет метки времени.")
    проверенный_сброс = проверить_запись_сброса(
        значение["запись_сброса"],
        контекст,
        проверять_служебные_объекты=False,
    )
    вычисленный_объект_сброса = decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "--stdin"],
            input_bytes=канонические_байты_сброса(проверенный_сброс),
        )
    )
    if (
        вычисленный_объект_сброса != значение["объект_записи_сброса"]
        or проверенный_сброс["фаза"] != "очистка_рабочей_копии"
        or проверенный_сброс["идентификатор_сброса"] != идентификатор_сброса
        or проверенный_сброс["идентификатор_диспетчера"] != значение["идентификатор_диспетчера"]
        or проверенный_сброс["целевая_вершина"] != значение["целевая_вершина"]
        or проверенный_сброс["исходный_объект_очереди"] != значение["исходный_объект_очереди"]
        or проверенный_сброс["участники"] != значение["аннулированные_задачи"]
        or проверенный_сброс["неактивные_задачи"] != значение["неактивные_задачи"]
        or проверенный_сброс["исходное_состояние_очереди"].get("last_completion") != значение["предыдущее_завершение"]
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Квитанция не воспроизводится из записи сброса.")
    проверенная_очередь = validate_state(значение["состояние_очереди_после"])
    вычисленный_объект_очереди = decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "--stdin"],
            input_bytes=canonical_state_bytes(проверенная_очередь),
        )
    )
    завершение = проверенная_очередь.get("last_completion")
    ожидаемое_завершение = {
        "kind": "reset",
        "task_id": значение["идентификатор_диспетчера"],
        "generation": идентификатор_сброса,
        "head": значение["целевая_вершина"],
        "completed_at": значение["завершено"],
        "аннулированные_задачи": значение["аннулированные_задачи"],
    }
    if (
        вычисленный_объект_очереди != значение["объект_очереди_после"]
        or проверенная_очередь["worktree_id"] != контекст.worktree_id
        or проверенная_очередь["branch_ref"] != контекст.branch_ref
        or проверенная_очередь["owner"] is not None
        or проверенная_очередь["waiting"] != []
        or проверенная_очередь["next_seq"]
        != проверенный_сброс["исходное_состояние_очереди"]["next_seq"]
        or завершение != ожидаемое_завершение
        or проверенная_очередь["updated_at"] != значение["завершено"]
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Квитанция не воспроизводит итоговую очередь.")
    return значение


def записать_объект_квитанции_сброса(
    контекст: QueueContext,
    квитанция: dict[str, object],
) -> str:
    проверить_квитанцию_сброса(квитанция, контекст)
    return decoded_stdout(
        run_git(
            контекст.root,
            ["hash-object", "-w", "--stdin"],
            input_bytes=канонические_байты_квитанции_сброса(квитанция),
        )
    )


def прочитать_квитанцию_сброса(
    контекст: QueueContext,
    идентификатор_сброса: str,
) -> tuple[dict[str, object] | None, str | None]:
    ссылка = ссылка_квитанции_сброса(контекст, идентификатор_сброса)
    объект = read_ref_oid(контекст, ссылка)
    if объект is None:
        return None, None
    сырые = run_git(контекст.root, ["cat-file", "blob", объект]).stdout
    try:
        значение = json.loads(сырые.decode("utf-8", errors="strict"), object_pairs_hook=собрать_объект_без_повторов, parse_constant=отклонить_неконечное_число)
    except (UnicodeDecodeError, json.JSONDecodeError) as ошибка:
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Git-квитанция сброса не содержит JSON.") from ошибка
    квитанция = проверить_квитанцию_сброса(значение, контекст)
    if сырые != канонические_байты_квитанции_сброса(квитанция):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset_receipt", "Git-квитанция сброса неканонична.")
    return квитанция, объект


def cas_state(
    контекст_очереди: QueueContext,
    old_oid: str | None,
    state: dict[str, object],
) -> tuple[bool, str]:
    new_oid = write_state_blob(контекст_очереди, state)
    last_stderr = ""
    for attempt in range(UNCHANGED_REF_RETRY_ATTEMPTS):
        result = run_git(
            контекст_очереди.root,
            ["update-ref", контекст_очереди.queue_ref, new_oid, old_oid or ""],
            check=False,
        )
        if result.returncode == 0:
            return True, new_oid
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        current_oid = read_ref_oid(контекст_очереди, контекст_очереди.queue_ref)
        if current_oid != old_oid:
            time.sleep(REF_RETRY_BASE_SECONDS)
            return False, new_oid
        if attempt + 1 < UNCHANGED_REF_RETRY_ATTEMPTS:
            time.sleep(ref_retry_delay(attempt))
    update_ref_error("обновить Git-ссылку очереди", last_stderr)


def update_queue_with_head_verification(
    контекст_очереди: QueueContext,
    *,
    expected_head: str,
    old_queue_oid: str,
    new_queue_oid: str,
    команда_внешнего_ограждения: str = "",
) -> subprocess.CompletedProcess[bytes]:
    transaction = (
        "start\n"
        f"verify {контекст_очереди.branch_ref} {expected_head}\n"
        f"{команда_внешнего_ограждения}"
        f"update {контекст_очереди.queue_ref} {new_queue_oid} {old_queue_oid}\n"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    return run_git(
        контекст_очереди.root,
        ["update-ref", "--stdin"],
        input_bytes=transaction,
        check=False,
    )


def восстановить_ссылку_очереди_после_смены_ветки(
    контекст: QueueContext,
    прежний_объект: str | None,
    записанный_объект: str,
) -> None:
    аргументы = ["update-ref"]
    if прежний_объект is None:
        аргументы.extend(["-d", контекст.queue_ref, записанный_объект])
    else:
        аргументы.extend(
            [контекст.queue_ref, прежний_объект, записанный_объект]
        )
    результат = run_git(
        контекст.root,
        аргументы,
        check=False,
    )
    if результат.returncode != 0:
        raise QueueError(
            EXIT_CAS,
            "branch_changed_queue_fenced",
            "Ветка переключилась; записанное состояние очереди осталось закрытым точным CAS-ограждением.",
        )


def восстановить_очередь_и_новый_маршрут_после_смены_ветки(
    контекст: QueueContext,
    прежний_объект_очереди: str | None,
    записанный_объект_очереди: str,
    ссылка_маршрута: str,
    объект_маршрута: str,
    прежний_объект_маршрута: str | None,
) -> None:
    команды = команда_замены_ссылки(
        контекст.queue_ref,
        записанный_объект_очереди,
        прежний_объект_очереди,
    )
    if прежний_объект_маршрута is None:
        команды += f"delete {ссылка_маршрута} {объект_маршрута}\n"
    else:
        команды += (
            f"verify {ссылка_маршрута} "
            f"{прежний_объект_маршрута}\n"
        )
    результат = run_git(
        контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=("start\n" + команды + "prepare\ncommit\n").encode("utf-8"),
        check=False,
    )
    if результат.returncode != 0:
        raise QueueError(
            EXIT_CAS,
            "branch_changed_queue_fenced",
            "Ветка переключилась; FIFO-билет и его runtime-маршрут остались закрыты единым CAS-ограждением.",
        )


def проверить_барьерное_ограждение_участника(
    контекст: QueueContext,
    участник: dict[str, object],
) -> None:
    базовая_вершина = участник.get("базовая_вершина_барьера")
    объект_барьера = участник.get("объект_реестра_барьеров")
    if объект_барьера is None:
        return
    if базовая_вершина is not None and current_head(контекст.root) != базовая_вершина:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "несовпавшая_вершина_барьера",
            "Первый барьерный участник привязан к активированной базовой вершине.",
        )
    if read_ref_oid(
        контекст,
        ссылка_реестра_барьеров_предактивации(контекст),
    ) != объект_барьера:
        raise QueueError(
            EXIT_CAS,
            "устаревший_реестр_барьеров",
            "Первый барьерный участник привязан к иному объекту реестра.",
        )
    реестр, прочитанный_объект = прочитать_реестр_барьеров(контекст)
    барьер = найти_барьер_ветки(реестр, контекст.branch_ref)
    if (
        прочитанный_объект != объект_барьера
        or барьер is None
        or барьер.get("состояние") != "открыт"
        or барьер.get("идентификатор_назначения")
        != участник.get("идентификатор_назначения_барьера")
        or барьер.get("хэш_назначения")
        != участник.get("хэш_назначения_барьера")
        or барьер.get("идентификатор_ресурсной_попытки")
        != участник.get("идентификатор_ресурсной_попытки_барьера")
        or барьер.get("хэш_ресурсного_допуска")
        != участник.get("хэш_ресурсного_допуска_барьера")
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "несовпавший_ресурсный_допуск_барьера",
            "Участник FIFO не подтверждает exact назначение и ресурсный допуск открытого барьера.",
        )


def ensure_state_identity(
    контекст_очереди: QueueContext,
    state: dict[str, object],
    *,
    allow_idle_rebind: bool,
) -> dict[str, object]:
    if state["worktree_id"] != контекст_очереди.worktree_id:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Git-ссылка очереди принадлежит другому worktree.",
        )
    if state["branch_ref"] == контекст_очереди.branch_ref:
        return state
    if allow_idle_rebind and state["owner"] is None and not state["waiting"]:
        rebound = copy.deepcopy(state)
        rebound["branch_ref"] = контекст_очереди.branch_ref
        rebound["updated_at"] = utc_values()[0]
        return rebound
    raise QueueError(
        EXIT_CONTEXT,
        "branch_changed",
        "В worktree переключена ветка при непустой очереди.",
        данные_результата_операции={
            "expected_branch_ref": state["branch_ref"],
            "current_branch_ref": контекст_очереди.branch_ref,
        },
    )


def status_records(
    root: Path,
    *,
    include_root_obsidian: bool = False,
) -> list[tuple[str, list[str]]]:
    arguments = [
        "-c",
        "core.quotepath=false",
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
        "--ignore-submodules=none",
    ]
    if not include_root_obsidian:
        arguments.extend(
            [
                "--",
                ".",
                ":(top,exclude).obsidian",
                ":(top,exclude).obsidian/**",
            ]
        )
    result = run_git(
        root,
        arguments,
    )
    raw_records = result.stdout.split(b"\0")
    parsed: list[tuple[str, list[str]]] = []
    index = 0
    while index < len(raw_records):
        raw = raw_records[index]
        index += 1
        if not raw:
            continue
        if len(raw) < 4 or raw[2:3] != b" ":
            raise QueueError(
                EXIT_CONTEXT,
                "git_error",
                "Git вернул неизвестный формат status --porcelain=v1 -z.",
            )
        status = raw[:2].decode("ascii", errors="strict")
        paths = [raw[3:].decode("utf-8", errors="surrogateescape")]
        if "R" in status or "C" in status:
            if index >= len(raw_records) or not raw_records[index]:
                raise QueueError(
                    EXIT_CONTEXT,
                    "git_error",
                    "Git вернул неполную запись переименования.",
                )
            paths.append(
                raw_records[index].decode("utf-8", errors="surrogateescape")
            )
            index += 1
        parsed.append((status, paths))
    return parsed


def all_changed_paths(root: Path) -> list[str]:
    return sorted({path for _, paths in status_records(root) for path in paths})


def staged_changed_paths(root: Path) -> list[str]:
    result = run_git(
        root,
        [
            "-c",
            "core.quotepath=false",
            "diff",
            "--cached",
            "--name-only",
            "-z",
            "--",
        ],
    )
    return sorted(
        path.decode("utf-8", errors="surrogateescape")
        for path in result.stdout.split(b"\0")
        if path
    )


def unsafe_commit_paths(root: Path) -> list[str]:
    unsafe: set[str] = set()
    conflict_codes = {"DD", "AU", "UD", "UA", "DU", "AA", "UU"}
    for status, paths in status_records(root):
        index_status, worktree_status = status
        if (
            status == "??"
            or status in conflict_codes
            or index_status == "U"
            or worktree_status == "U"
            or worktree_status != " "
        ):
            unsafe.update(paths)
    return sorted(unsafe)


def common_payload(
    контекст_очереди: QueueContext,
    state_oid: str | None,
) -> dict[str, object]:
    return {
        "queue_ref": контекст_очереди.queue_ref,
        "queue_oid": state_oid,
        "worktree_id": контекст_очереди.worktree_id,
        "branch_ref": контекст_очереди.branch_ref,
    }


def owner_result(
    контекст_очереди: QueueContext,
    owner: dict[str, object],
    state_oid: str | None,
    *,
    ownership: str,
) -> tuple[int, dict[str, object]]:
    return 0, {
        "state": "admitted",
        "ownership": ownership,
        **owner,
        **common_payload(контекст_очереди, state_oid),
    }


def waiting_result(
    контекст_очереди: QueueContext,
    state: dict[str, object],
    state_oid: str | None,
    task_id: str,
) -> tuple[int, dict[str, object]]:
    for index, ticket in enumerate(state["waiting"]):
        if ticket["task_id"] == task_id:
            return EXIT_WAITING, {
                "state": "waiting",
                "position": index + 1,
                **ticket,
                **common_payload(контекст_очереди, state_oid),
            }
    raise QueueError(
        EXIT_NOT_REGISTERED,
        "not_registered",
        "Задача не зарегистрирована в очереди.",
    )


def attempt_admit(
    контекст_очереди: QueueContext,
    task_id: str,
) -> tuple[int, dict[str, object]]:
    unchanged_ref_failures = 0
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(контекст_очереди)
        state, old_oid = read_state(контекст_очереди)
        state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
        owner = state["owner"]
        waiting = state["waiting"]
        target_index = next(
            (
                index
                for index, ticket in enumerate(waiting)
                if ticket["task_id"] == task_id
            ),
            None,
        )
        if isinstance(owner, dict) and owner["task_id"] == task_id:
            ссылка_маршрута, объект_маршрута, прежний_объект_маршрута = (
                подготовить_маршрут_обычной_очереди(контекст_очереди, task_id)
            )
            if прежний_объект_маршрута is None:
                дозаполнить_маршрут_существующего_участника(
                    контекст_очереди,
                    state,
                    old_oid,
                    task_id,
                    ссылка_маршрута,
                    объект_маршрута,
                )
                continue
            проверить_барьерное_ограждение_участника(
                контекст_очереди,
                owner,
            )
            return owner_result(
                контекст_очереди,
                owner,
                old_oid,
                ownership="existing",
            )
        if target_index is None:
            raise QueueError(
                EXIT_NOT_REGISTERED,
                "not_registered",
                "Задача не зарегистрирована в очереди.",
            )
        ссылка_маршрута, объект_маршрута, прежний_объект_маршрута = (
            подготовить_маршрут_обычной_очереди(контекст_очереди, task_id)
        )
        if isinstance(owner, dict) or target_index != 0:
            if прежний_объект_маршрута is None:
                дозаполнить_маршрут_существующего_участника(
                    контекст_очереди,
                    state,
                    old_oid,
                    task_id,
                    ссылка_маршрута,
                    объект_маршрута,
                )
                continue
            return waiting_result(контекст_очереди, state, old_oid, task_id)

        ticket = waiting[0]
        (
            _,
            ожидаемая_барьерная_база,
            _,
            _,
            _,
            _,
        ) = потребовать_открытый_барьер_предактивации(
            контекст_очереди,
            task_id,
            state,
        )
        head = current_head(контекст_очереди.root)
        барьерная_база = ticket.get("базовая_вершина_барьера")
        if барьерная_база != ожидаемая_барьерная_база:
            raise QueueError(
                EXIT_CONTEXT,
                "несовпавшая_вершина_барьера",
                "Билет не подтверждает требуемую фазу первого барьерного допуска.",
            )
        объект_барьера = ticket.get("объект_реестра_барьеров")
        идентификатор_назначения_барьера = ticket.get(
            "идентификатор_назначения_барьера"
        )
        хэш_назначения_барьера = ticket.get("хэш_назначения_барьера")
        идентификатор_ресурсной_попытки_барьера = ticket.get(
            "идентификатор_ресурсной_попытки_барьера"
        )
        хэш_ресурсного_допуска_барьера = ticket.get(
            "хэш_ресурсного_допуска_барьера"
        )
        if барьерная_база is not None and head != барьерная_база:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "несовпавшая_вершина_барьера",
                "Первый барьерный билет нельзя перепривязать к вершине после корневой активации.",
            )
        проверить_барьерное_ограждение_участника(
            контекст_очереди,
            ticket,
        )
        if ticket["acknowledged_head"] != head:
            if прежний_объект_маршрута is None:
                дозаполнить_маршрут_существующего_участника(
                    контекст_очереди,
                    state,
                    old_oid,
                    task_id,
                    ссылка_маршрута,
                    объект_маршрута,
                )
                continue
            return EXIT_RELOAD_REQUIRED, {
                "state": "reload_required",
                "position": 1,
                **ticket,
                "current_head": head,
                **common_payload(контекст_очереди, old_oid),
            }
        blocking = all_changed_paths(контекст_очереди.root)
        if blocking:
            if прежний_объект_маршрута is None:
                дозаполнить_маршрут_существующего_участника(
                    контекст_очереди,
                    state,
                    old_oid,
                    task_id,
                    ссылка_маршрута,
                    объект_маршрута,
                )
                continue
            return EXIT_DIRTY, {
                "state": "dirty",
                "position": 1,
                **ticket,
                "blocking_paths": blocking,
                **common_payload(контекст_очереди, old_oid),
            }

        stamp, epoch = utc_values()
        owner_record = {
            "task_id": ticket["task_id"],
            "ticket_id": ticket["ticket_id"],
            "seq": ticket["seq"],
            "generation": str(uuid.uuid4()),
            "base_head": head,
            "admitted_at": stamp,
            "admitted_at_epoch": epoch,
        }
        if объект_барьера is not None:
            owner_record["объект_реестра_барьеров"] = объект_барьера
            owner_record["идентификатор_назначения_барьера"] = (
                идентификатор_назначения_барьера
            )
            owner_record["хэш_назначения_барьера"] = хэш_назначения_барьера
            owner_record["идентификатор_ресурсной_попытки_барьера"] = (
                идентификатор_ресурсной_попытки_барьера
            )
            owner_record["хэш_ресурсного_допуска_барьера"] = (
                хэш_ресурсного_допуска_барьера
            )
        if барьерная_база is not None:
            owner_record["базовая_вершина_барьера"] = барьерная_база
        updated = copy.deepcopy(state)
        updated["owner"] = owner_record
        updated["waiting"] = updated["waiting"][1:]
        if барьерная_база is not None:
            updated[ПОЛЕ_ДОПУЩЕННОЙ_ЗАДАЧИ_БАРЬЕРА] = {
                "task_id": ticket["task_id"],
                "ticket_id": ticket["ticket_id"],
                "seq": ticket["seq"],
                "объект_реестра_барьеров": объект_барьера,
            }
        updated["updated_at"] = stamp
        if old_oid is None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "У ожидающего билета отсутствует Git-ссылка состояния очереди.",
            )
        new_oid = write_state_blob(контекст_очереди, updated)
        команда_барьерного_ограждения = ""
        if объект_барьера is not None:
            команда_барьерного_ограждения = (
                f"verify {ссылка_реестра_барьеров_предактивации(контекст_очереди)} "
                f"{объект_барьера}\n"
            )
        result = update_queue_with_head_verification(
            контекст_очереди,
            expected_head=head,
            old_queue_oid=old_oid,
            new_queue_oid=new_oid,
            команда_внешнего_ограждения=(
                команда_барьерного_ограждения
                + команда_маршрута_задачи(
                    ссылка_маршрута,
                    объект_маршрута,
                    прежний_объект_маршрута,
                )
            ),
        )
        if result.returncode == 0:
            try:
                ensure_live_branch(контекст_очереди)
            except QueueError:
                восстановить_ссылку_очереди_после_смены_ветки(
                    контекст_очереди,
                    old_oid,
                    new_oid,
                )
                raise
            return owner_result(
                контекст_очереди,
                owner_record,
                new_oid,
                ownership="new",
            )
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        _, _, наблюдаемый_объект_маршрута = подготовить_маршрут_обычной_очереди(
            контекст_очереди,
            task_id,
        )
        observed_head = current_head(контекст_очереди.root)
        _, observed_queue_oid = read_state(контекст_очереди)
        if (
            observed_head != head
            or observed_queue_oid != old_oid
            or наблюдаемый_объект_маршрута
            != прежний_объект_маршрута
        ):
            unchanged_ref_failures = 0
            time.sleep(REF_RETRY_BASE_SECONDS)
            continue
        unchanged_ref_failures += 1
        if unchanged_ref_failures >= UNCHANGED_REF_RETRY_ATTEMPTS:
            update_ref_error("атомарно допустить владельца очереди", last_stderr)
        time.sleep(ref_retry_delay(unchanged_ref_failures - 1))
    raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось получить место владельца.")


def join_queue(контекст_очереди: QueueContext, task_id: str) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    потребовать_неаннулированную_задачу(контекст_очереди, task_id)
    for _ in range(MAX_CAS_ATTEMPTS):
        потребовать_неаннулированную_задачу(контекст_очереди, task_id)
        ensure_live_branch(контекст_очереди)
        state, old_oid = read_state(контекст_очереди)
        identity_state = ensure_state_identity(
            контекст_очереди,
            state,
            allow_idle_rebind=True,
        )
        (
            объект_реестра_барьеров,
            ожидаемая_базовая_вершина_барьера,
            идентификатор_назначения_барьера,
            хэш_назначения_барьера,
            идентификатор_ресурсной_попытки_барьера,
            хэш_ресурсного_допуска_барьера,
        ) = потребовать_открытый_барьер_предактивации(
            контекст_очереди,
            task_id,
            identity_state,
        )
        ссылка_маршрута, объект_маршрута, прежний_объект_маршрута = (
            подготовить_маршрут_обычной_очереди(контекст_очереди, task_id)
        )
        owner = identity_state["owner"]
        if isinstance(owner, dict) and owner["task_id"] == task_id:
            return attempt_admit(контекст_очереди, task_id)

        existing: dict[str, object] | None = None
        for ticket in identity_state["waiting"]:
            if ticket["task_id"] == task_id:
                existing = ticket
                break
        if existing is not None:
            return attempt_admit(контекст_очереди, task_id)

        stamp, epoch = utc_values()
        updated = copy.deepcopy(identity_state)
        ticket = {
            "task_id": task_id,
            "ticket_id": str(uuid.uuid4()),
            "seq": updated["next_seq"],
            "registered_at": stamp,
            "registered_at_epoch": epoch,
            "acknowledged_head": current_head(контекст_очереди.root),
        }
        if объект_реестра_барьеров is not None:
            ticket["объект_реестра_барьеров"] = объект_реестра_барьеров
            ticket["идентификатор_назначения_барьера"] = идентификатор_назначения_барьера
            ticket["хэш_назначения_барьера"] = хэш_назначения_барьера
            ticket["идентификатор_ресурсной_попытки_барьера"] = (
                идентификатор_ресурсной_попытки_барьера
            )
            ticket["хэш_ресурсного_допуска_барьера"] = хэш_ресурсного_допуска_барьера
        if ожидаемая_базовая_вершина_барьера is not None:
            ticket["базовая_вершина_барьера"] = ожидаемая_базовая_вершина_барьера
        updated["next_seq"] = int(updated["next_seq"]) + 1
        updated["waiting"].append(ticket)
        updated["updated_at"] = stamp

        success, _ = сравнить_очередь_при_отсутствии_аннулирования(
            контекст_очереди,
            old_oid,
            updated,
            task_id,
            объект_реестра_барьеров,
            ожидаемая_базовая_вершина_барьера,
            ссылка_маршрута,
            объект_маршрута,
            прежний_объект_маршрута,
        )
        if success:
            break
    else:
        raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось зарегистрировать задачу.")
    return attempt_admit(контекст_очереди, task_id)


def контекст_для_ветки(
    контекст: QueueContext,
    ссылка_ветки: str,
) -> QueueContext:
    return QueueContext(
        root=контекст.root,
        git_dir=контекст.git_dir,
        worktree_id=контекст.worktree_id,
        queue_ref=контекст.queue_ref,
        branch_ref=ссылка_ветки,
    )


def данные_текущей_цепочки(
    карточка: КарточкаЦепочки,
) -> dict[str, object]:
    return {
        "идентификатор": карточка.идентификатор,
        "путь": карточка.путь,
        "хэш": карточка.хэш,
        "ветка": карточка.ветка,
    }


def потребовать_чистоту_для_перехода(контекст: QueueContext) -> None:
    изменённые_пути = sorted(
        {
            путь
            for _, пути in status_records(
                контекст.root,
                include_root_obsidian=True,
            )
            for путь in пути
        }
    )
    if изменённые_пути:
        raise QueueError(
            EXIT_DIRTY,
            "dirty",
            "Переход на цепочку требует полностью чистые index и worktree.",
            данные_результата_операции={
                "blocking_paths": изменённые_пути,
                **common_payload(
                    контекст,
                    read_ref_oid(контекст, контекст.queue_ref),
                ),
            },
        )


def переход_совпадает_с_вызовом(
    переход: dict[str, object],
    карточка: КарточкаЦепочки,
    идентификатор_задачи: str,
    исходная_ветка: str,
    исходная_вершина: str,
) -> bool:
    return (
        переход["идентификатор_задачи"] == идентификатор_задачи
        and переход["идентификатор_цепочки"] == карточка.идентификатор
        and переход["путь_карточки"] == карточка.путь
        and переход["хэш_карточки"] == карточка.хэш
        and переход["исходная_ветка"] == исходная_ветка
        and переход["целевая_ветка"] == карточка.ветка
        and переход["исходная_вершина"] == исходная_вершина
    )


def это_завершённый_повтор_перехода(
    контекст: QueueContext,
    состояние: dict[str, object],
    карточка: КарточкаЦепочки,
    идентификатор_задачи: str,
    исходная_ветка: str,
    исходная_вершина: str,
) -> dict[str, object] | None:
    владелец = состояние.get("owner")
    if not isinstance(владелец, dict):
        return None
    if (
        контекст.branch_ref != карточка.ветка
        or состояние["worktree_id"] != контекст.worktree_id
        or состояние["branch_ref"] != карточка.ветка
        or состояние["waiting"] != []
        or состояние.get("текущая_цепочка")
        != данные_текущей_цепочки(карточка)
        or владелец["task_id"] != идентификатор_задачи
        or владелец["base_head"] != исходная_вершина
        or read_ref_oid(контекст, исходная_ветка) != исходная_вершина
        or read_ref_oid(контекст, карточка.ветка) != исходная_вершина
        or current_head(контекст.root) != исходная_вершина
    ):
        return None
    return владелец


def установить_временную_запись_перехода(
    контекст: QueueContext,
    исходная_вершина: str,
    целевая_ветка: str,
    исходный_объект_очереди: str | None,
    объект_перехода: str,
    идентификатор_задачи: str,
    ссылка_маршрута: str,
    объект_маршрута: str,
) -> None:
    if (
        symbolic_branch(контекст.root) != контекст.branch_ref
        or current_head(контекст.root) != исходная_вершина
        or read_ref_oid(контекст, контекст.branch_ref) != исходная_вершина
    ):
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "Исходная ветка или HEAD изменились до подготовки перехода.",
        )
    команда_очереди = (
        f"create {контекст.queue_ref} {объект_перехода}\n"
        if исходный_объект_очереди is None
        else (
            f"update {контекст.queue_ref} {объект_перехода} "
            f"{исходный_объект_очереди}\n"
        )
    )
    ссылка_аннулирования = ссылка_аннулированной_задачи(
        контекст,
        идентификатор_задачи,
    )
    нулевой_объект = "0" * len(исходная_вершина)
    команды = (
        "start\n"
        f"verify {контекст.branch_ref} {исходная_вершина}\n"
        f"verify {ссылка_аннулирования} {нулевой_объект}\n"
        f"create {ссылка_маршрута} {объект_маршрута}\n"
        f"create {целевая_ветка} {исходная_вершина}\n"
        f"{команда_очереди}"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    результат = run_git(
        контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=команды,
        check=False,
    )
    if результат.returncode == 0:
        return
    текущий_объект_очереди = read_ref_oid(контекст, контекст.queue_ref)
    if текущий_объект_очереди == объект_перехода:
        if read_ref_oid(контекст, ссылка_маршрута) != объект_маршрута:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_chain_transition",
                "Переход сохранён без exact runtime-маршрута задачи.",
            )
        потребовать_неаннулированную_задачу(
            контекст,
            идентификатор_задачи,
        )
        return
    потребовать_неаннулированную_задачу(
        контекст,
        идентификатор_задачи,
    )
    if read_ref_oid(контекст, целевая_ветка) is not None:
        raise QueueError(
            EXIT_CONTEXT,
            "target_branch_exists",
            "Целевая ветка уже существует и не принадлежит этому переходу.",
        )
    if read_ref_oid(контекст, ссылка_маршрута) is not None:
        raise QueueError(
            EXIT_OWNERSHIP,
            "task_route_already_reserved",
            "Задача уже необратимо связана с иным runtime-маршрутом.",
        )
    подробности = результат.stderr.decode("utf-8", errors="replace").strip()
    update_ref_error("подготовить переход на цепочку", подробности)


def завершить_временную_запись_перехода(
    исходный_контекст: QueueContext,
    переход: dict[str, object],
    объект_перехода: str,
    *,
    новый_переход: bool,
) -> tuple[int, dict[str, object]]:
    исходная_ветка = str(переход["исходная_ветка"])
    целевая_ветка = str(переход["целевая_ветка"])
    исходная_вершина = str(переход["исходная_вершина"])
    идентификатор_задачи = validate_task_id(
        переход["идентификатор_задачи"]
    )
    ссылка_маршрута = str(переход["ссылка_маршрута"])
    объект_маршрута = str(переход["объект_маршрута"])
    потребовать_неаннулированную_задачу(
        исходный_контекст,
        идентификатор_задачи,
    )
    живая_ветка = symbolic_branch(исходный_контекст.root)
    if живая_ветка not in {исходная_ветка, целевая_ветка}:
        raise QueueError(
            EXIT_CONTEXT,
            "branch_changed",
            "HEAD покинул обе ветки активного перехода на цепочку.",
        )
    if current_head(исходный_контекст.root) != исходная_вершина:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "HEAD изменился до атомарного переключения на ветку цепочки.",
        )
    команда_головы = (
        f"symref-update HEAD {целевая_ветка} oid {исходная_вершина}\n"
        if живая_ветка == исходная_ветка
        else f"symref-verify HEAD {целевая_ветка}\n"
    )
    ensure_unique_branch_worktree(исходный_контекст.root, целевая_ветка)
    целевой_контекст = контекст_для_ветки(исходный_контекст, целевая_ветка)
    итоговое_состояние = validate_state(
        переход["итоговое_состояние_очереди"]
    )
    итоговый_объект = write_state_blob(
        целевой_контекст,
        итоговое_состояние,
    )
    if итоговый_объект != переход["итоговый_объект_очереди"]:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Итоговый объект перехода не воспроизводится перед завершением.",
        )
    текущий_объект = read_ref_oid(целевой_контекст, целевой_контекст.queue_ref)
    if текущий_объект == итоговый_объект:
        if (
            symbolic_branch(целевой_контекст.root) != целевая_ветка
            or read_ref_oid(целевой_контекст, ссылка_маршрута)
            != объект_маршрута
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_chain_transition",
                "Итоговая очередь перехода не совпадает с symbolic HEAD.",
            )
        потребовать_неаннулированную_задачу(
            целевой_контекст,
            идентификатор_задачи,
        )
        владелец = итоговое_состояние["owner"]
        if not isinstance(владелец, dict):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_chain_transition",
                "Итоговый объект перехода не имеет владельца.",
            )
        return owner_result(
            целевой_контекст,
            владелец,
            итоговый_объект,
            ownership="existing",
        )
    if текущий_объект != объект_перехода:
        raise QueueError(
            EXIT_CAS,
            "queue_changed",
            "Очередь изменилась во время перехода на цепочку.",
        )
    if (
        read_ref_oid(целевой_контекст, исходная_ветка)
        != исходная_вершина
        or read_ref_oid(целевой_контекст, целевая_ветка)
        != исходная_вершина
        or read_ref_oid(целевой_контекст, ссылка_маршрута)
        != объект_маршрута
    ):
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "Ветки перехода изменились до атомарного допуска.",
        )
    ссылка_аннулирования = ссылка_аннулированной_задачи(
        целевой_контекст,
        идентификатор_задачи,
    )
    нулевой_объект = "0" * len(исходная_вершина)
    команды = (
        "start\n"
        f"{команда_головы}"
        f"verify {ссылка_аннулирования} {нулевой_объект}\n"
        f"verify {ссылка_маршрута} {объект_маршрута}\n"
        f"update {целевой_контекст.queue_ref} {итоговый_объект} {объект_перехода}\n"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    результат = run_git(
        целевой_контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=команды,
        check=False,
    )
    if результат.returncode != 0:
        наблюдаемый_объект = read_ref_oid(
            целевой_контекст,
            целевой_контекст.queue_ref,
        )
        if (
            наблюдаемый_объект != итоговый_объект
            or symbolic_branch(целевой_контекст.root) != целевая_ветка
        ):
            потребовать_неаннулированную_задачу(
                целевой_контекст,
                идентификатор_задачи,
            )
            подробности = результат.stderr.decode("utf-8", errors="replace").strip()
            update_ref_error("завершить переход на цепочку", подробности)
        потребовать_неаннулированную_задачу(
            целевой_контекст,
            идентификатор_задачи,
        )
        новый_переход = False
    if (
        symbolic_branch(целевой_контекст.root) != целевая_ветка
        or current_head(целевой_контекст.root) != исходная_вершина
        or read_ref_oid(целевой_контекст, ссылка_маршрута)
        != объект_маршрута
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Атомарный переход не согласовал symbolic HEAD и очередь.",
        )
    владелец = итоговое_состояние["owner"]
    if not isinstance(владелец, dict):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_chain_transition",
            "Итоговое состояние перехода не имеет владельца.",
        )
    return owner_result(
        целевой_контекст,
        владелец,
        итоговый_объект,
        ownership="new" if новый_переход else "existing",
    )


def проверить_снимок_завершённого_перехода(
    контекст: QueueContext,
    идентификатор_задачи: str,
    исходная_ветка: str,
    целевая_ветка: str,
    исходная_вершина: str,
    объект_очереди: str,
    ссылка_маршрута: str,
    объект_маршрута: str,
) -> None:
    ссылка_аннулирования = ссылка_аннулированной_задачи(
        контекст,
        идентификатор_задачи,
    )
    нулевой_объект = "0" * len(исходная_вершина)
    команды = (
        "start\n"
        f"symref-verify HEAD {целевая_ветка}\n"
        f"verify {исходная_ветка} {исходная_вершина}\n"
        f"verify {контекст.queue_ref} {объект_очереди}\n"
        f"verify {ссылка_маршрута} {объект_маршрута}\n"
        f"verify {ссылка_аннулирования} {нулевой_объект}\n"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    результат = run_git(
        контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=команды,
        check=False,
    )
    if результат.returncode != 0:
        raise QueueError(
            EXIT_CAS,
            "completed_transition_snapshot_changed",
            "Exact снимок завершённого перехода изменился до ответа.",
        )


def перейти_на_цепочку(
    контекст: QueueContext,
    идентификатор_задачи: str,
    путь_карточки: str,
    ожидаемый_идентификатор_цепочки: str,
    ожидаемый_хэш_карточки: str,
    ожидаемая_исходная_ветка: str,
    ожидаемая_исходная_вершина: str,
) -> tuple[int, dict[str, object]]:
    идентификатор_задачи = validate_task_id(идентификатор_задачи)
    потребовать_неаннулированную_задачу(
        контекст,
        идентификатор_задачи,
    )
    карточка = прочитать_карточку_цепочки(
        контекст,
        путь_карточки,
        ожидаемый_идентификатор_цепочки,
        ожидаемый_хэш_карточки,
        ожидаемая_исходная_ветка,
        ожидаемая_исходная_вершина,
    )
    ensure_live_branch(контекст)
    потребовать_поддержку_символьных_транзакций(контекст)
    целевой_контекст = контекст_для_ветки(контекст, карточка.ветка)
    (
        ссылка_маршрута,
        объект_маршрута,
        прежний_объект_маршрута,
    ) = подготовить_маршрут_обычной_очереди(
        целевой_контекст,
        идентификатор_задачи,
    )
    вид, запись, объект_очереди = прочитать_запись_очереди(
        контекст,
        разрешить_переход_на_цепочку=True,
    )
    if вид == "сброс":
        raise QueueError(
            КОД_ИДЁТ_СБРОС,
            "reset_in_progress",
            "Переход на цепочку запрещён во время штатного сброса.",
        )
    if вид == "переход":
        if объект_очереди is None or not переход_совпадает_с_вызовом(
            запись,
            карточка,
            идентификатор_задачи,
            ожидаемая_исходная_ветка,
            ожидаемая_исходная_вершина,
        ):
            raise QueueError(
                КОД_ИДЁТ_ПЕРЕХОД_НА_ЦЕПОЧКУ,
                "chain_transition_in_progress",
                "Другая попытка перехода уже оградила очередь.",
            )
        if (
            запись.get("ссылка_маршрута") != ссылка_маршрута
            or запись.get("объект_маршрута") != объект_маршрута
            or прежний_объект_маршрута != объект_маршрута
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_chain_transition",
                "Переход не связан с exact runtime-маршрутом задачи.",
            )
        return завершить_временную_запись_перехода(
            контекст,
            запись,
            объект_очереди,
            новый_переход=False,
        )

    состояние = запись
    существующий_владелец = это_завершённый_повтор_перехода(
        контекст,
        состояние,
        карточка,
        идентификатор_задачи,
        ожидаемая_исходная_ветка,
        ожидаемая_исходная_вершина,
    )
    if существующий_владелец is not None:
        if прежний_объект_маршрута != объект_маршрута:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_task_route",
                "Завершённый переход потерял runtime-маршрут задачи.",
            )
        if объект_очереди is None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_chain_transition",
                "Завершённый переход потерял объект очереди.",
            )
        проверить_снимок_завершённого_перехода(
            контекст,
            идентификатор_задачи,
            ожидаемая_исходная_ветка,
            карточка.ветка,
            ожидаемая_исходная_вершина,
            объект_очереди,
            ссылка_маршрута,
            объект_маршрута,
        )
        return owner_result(
            контекст,
            существующий_владелец,
            объект_очереди,
            ownership="existing",
        )
    if прежний_объект_маршрута is not None:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_task_route",
            "Runtime-маршрут задачи существует без перехода или участника очереди.",
        )
    if состояние["owner"] is not None or состояние["waiting"]:
        raise QueueError(
            EXIT_WAITING,
            "queue_active",
            "Переход на цепочку разрешён только при пустой очереди.",
            данные_результата_операции={
                **common_payload(контекст, объект_очереди),
            },
        )
    if (
        контекст.branch_ref != ожидаемая_исходная_ветка
        or состояние["worktree_id"] != контекст.worktree_id
        or состояние["branch_ref"] != ожидаемая_исходная_ветка
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "source_branch_changed",
            "Текущая ветка или ветка пустой очереди не совпадает с ожидаемой исходной.",
        )
    if (
        current_head(контекст.root) != ожидаемая_исходная_вершина
        or read_ref_oid(контекст, ожидаемая_исходная_ветка)
        != ожидаемая_исходная_вершина
    ):
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "Исходная ветка или HEAD не совпадает с ожидаемой вершиной.",
        )
    if read_ref_oid(контекст, карточка.ветка) is not None:
        raise QueueError(
            EXIT_CONTEXT,
            "target_branch_exists",
            "V1 перехода разрешает только отсутствующую целевую ветку.",
        )
    потребовать_чистоту_для_перехода(контекст)

    метка, эпоха = utc_values()
    владелец = {
        "task_id": идентификатор_задачи,
        "ticket_id": str(uuid.uuid4()),
        "seq": состояние["next_seq"],
        "generation": str(uuid.uuid4()),
        "base_head": ожидаемая_исходная_вершина,
        "admitted_at": метка,
        "admitted_at_epoch": эпоха,
    }
    итоговое_состояние = copy.deepcopy(состояние)
    итоговое_состояние["branch_ref"] = карточка.ветка
    итоговое_состояние["next_seq"] = int(состояние["next_seq"]) + 1
    итоговое_состояние["owner"] = владелец
    итоговое_состояние["waiting"] = []
    итоговое_состояние["текущая_цепочка"] = данные_текущей_цепочки(карточка)
    итоговое_состояние["updated_at"] = метка
    итоговый_объект = write_state_blob(контекст, итоговое_состояние)
    переход = {
        "схема": СХЕМА_ПЕРЕХОДА_НА_ЦЕПОЧКУ,
        "идентификатор_рабочей_копии": контекст.worktree_id,
        "исходная_ветка": ожидаемая_исходная_ветка,
        "целевая_ветка": карточка.ветка,
        "исходная_вершина": ожидаемая_исходная_вершина,
        "исходный_объект_очереди": объект_очереди,
        "идентификатор_задачи": идентификатор_задачи,
        "ссылка_маршрута": ссылка_маршрута,
        "объект_маршрута": объект_маршрута,
        "идентификатор_цепочки": карточка.идентификатор,
        "путь_карточки": карточка.путь,
        "хэш_карточки": карточка.хэш,
        "владелец": владелец,
        "итоговое_состояние_очереди": итоговое_состояние,
        "итоговый_объект_очереди": итоговый_объект,
        "создано": метка,
    }
    объект_перехода = записать_объект_перехода_на_цепочку(
        контекст,
        переход,
    )
    потребовать_чистоту_для_перехода(контекст)
    if read_ref_oid(контекст, карточка.ветка) is not None:
        raise QueueError(
            EXIT_CONTEXT,
            "target_branch_exists",
            "Целевая ветка появилась до атомарной подготовки перехода.",
        )
    установить_временную_запись_перехода(
        контекст,
        ожидаемая_исходная_вершина,
        карточка.ветка,
        объект_очереди,
        объект_перехода,
        идентификатор_задачи,
        ссылка_маршрута,
        объект_маршрута,
    )
    проверенный_переход = проверить_запись_перехода_на_цепочку(
        переход,
        контекст,
    )
    return завершить_временную_запись_перехода(
        контекст,
        проверенный_переход,
        объект_перехода,
        новый_переход=True,
    )


def wait_queue(
    контекст_очереди: QueueContext,
    task_id: str,
    timeout_seconds: float,
) -> tuple[int, dict[str, object]]:
    if not math.isfinite(timeout_seconds) or timeout_seconds < 0:
        raise QueueError(
            EXIT_CLI,
            "invalid_timeout",
            "Время ожидания должно быть конечным неотрицательным числом.",
        )
    deadline = time.monotonic() + timeout_seconds
    while True:
        код_завершения_операции, данные_результата_операции = attempt_admit(контекст_очереди, task_id)
        if код_завершения_операции != EXIT_WAITING:
            return код_завершения_операции, данные_результата_операции
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return код_завершения_операции, данные_результата_операции
        time.sleep(min(WAIT_POLL_SECONDS, remaining))


def wait_until_actionable_queue(
    контекст_очереди: QueueContext,
    task_id: str,
) -> tuple[int, dict[str, object]]:
    while True:
        код_завершения_операции, данные_результата_операции = wait_queue(
            контекст_очереди,
            task_id,
            DEFAULT_WAIT_TIMEOUT_SECONDS,
        )
        if код_завершения_операции != EXIT_WAITING:
            return код_завершения_операции, данные_результата_операции


def acknowledge_head(
    контекст_очереди: QueueContext,
    task_id: str,
    acknowledged_head: str,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    live_head = current_head(контекст_очереди.root)
    if acknowledged_head != live_head:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_mismatch",
            "Подтверждаемая ревизия не совпадает с текущим HEAD.",
            данные_результата_операции={
                "expected_head": live_head,
                "provided_head": acknowledged_head,
            },
        )
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(контекст_очереди)
        state, old_oid = read_state(контекст_очереди)
        state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
        owner = state["owner"]
        if isinstance(owner, dict) and owner["task_id"] == task_id:
            raise QueueError(
                EXIT_OWNERSHIP,
                "not_waiting",
                "Текущий владелец уже допущен и не подтверждает HEAD повторно.",
            )
        stamp, _ = utc_values()
        updated = copy.deepcopy(state)
        target: dict[str, object] | None = None
        for ticket in updated["waiting"]:
            if ticket["task_id"] == task_id:
                target = ticket
                break
        if target is None:
            raise QueueError(
                EXIT_NOT_REGISTERED,
                "not_registered",
                "Задача не зарегистрирована в очереди.",
            )
        барьерная_база = target.get("базовая_вершина_барьера")
        if барьерная_база is not None and acknowledged_head != барьерная_база:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "несовпавшая_вершина_барьера",
                "Первый барьерный билет нельзя подтвердить на иной вершине.",
                данные_результата_операции={
                    "expected_head": барьерная_база,
                    "provided_head": acknowledged_head,
                },
            )
        target["acknowledged_head"] = acknowledged_head
        updated["updated_at"] = stamp
        ссылка_маршрута, объект_маршрута, прежний_объект_маршрута = (
            подготовить_маршрут_обычной_очереди(контекст_очереди, task_id)
        )
        if old_oid is None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "У ожидающего билета отсутствует Git-ссылка очереди.",
            )
        new_oid = write_state_blob(контекст_очереди, updated)
        результат = update_queue_with_head_verification(
            контекст_очереди,
            expected_head=acknowledged_head,
            old_queue_oid=old_oid,
            new_queue_oid=new_oid,
            команда_внешнего_ограждения=команда_маршрута_задачи(
                ссылка_маршрута,
                объект_маршрута,
                прежний_объект_маршрута,
            ),
        )
        if результат.returncode == 0:
            try:
                ensure_live_branch(контекст_очереди)
                if current_head(контекст_очереди.root) != acknowledged_head:
                    raise QueueError(
                        EXIT_HEAD_CHANGED,
                        "head_mismatch",
                        "HEAD изменился во время подтверждения ожидающего билета.",
                    )
            except QueueError:
                восстановить_ссылку_очереди_после_смены_ветки(
                    контекст_очереди,
                    old_oid,
                    new_oid,
                )
                raise
            return 0, {
                "state": "acknowledged",
                **target,
                **common_payload(контекст_очереди, new_oid),
            }
        _, _, наблюдаемый_объект_маршрута = подготовить_маршрут_обычной_очереди(
            контекст_очереди,
            task_id,
        )
        if current_head(контекст_очереди.root) != acknowledged_head:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_mismatch",
                "HEAD изменился во время подтверждения ожидающего билета.",
            )
        if (
            read_ref_oid(контекст_очереди, контекст_очереди.queue_ref) != old_oid
            or наблюдаемый_объект_маршрута
            != прежний_объект_маршрута
        ):
            continue
        update_ref_error(
            "атомарно подтвердить вершину ожидающего билета",
            результат.stderr.decode("utf-8", errors="replace").strip(),
        )
    raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось подтвердить новый HEAD.")


def cancel_waiter(
    контекст_очереди: QueueContext,
    task_id: str,
    ticket_id: str | None,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(контекст_очереди)
        state, old_oid = read_state(контекст_очереди)
        state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
        owner = state["owner"]
        if isinstance(owner, dict) and owner["task_id"] == task_id:
            raise QueueError(
                EXIT_OWNERSHIP,
                "owner_cannot_cancel",
                "Допущенный владелец не может покинуть очередь без атомарного коммита.",
            )
        if not ticket_id:
            raise QueueError(
                EXIT_CLI,
                "invalid_ticket_id",
                "Для отмены ожидающего билета нужен его точный ticket_id.",
            )
        target = next(
            (
                ticket
                for ticket in state["waiting"]
                if ticket["task_id"] == task_id and ticket["ticket_id"] == ticket_id
            ),
            None,
        )
        if target is None:
            raise QueueError(
                EXIT_NOT_REGISTERED,
                "not_registered",
                "Совпадающий ожидающий билет не найден.",
            )
        stamp, _ = utc_values()
        updated = copy.deepcopy(state)
        updated["waiting"] = [
            ticket
            for ticket in updated["waiting"]
            if not (
                ticket["task_id"] == task_id and ticket["ticket_id"] == ticket_id
            )
        ]
        updated["updated_at"] = stamp
        success, new_oid = cas_state(контекст_очереди, old_oid, updated)
        if success:
            return 0, {
                "state": "cancelled",
                "task_id": task_id,
                "ticket_id": ticket_id,
                **common_payload(контекст_очереди, new_oid),
            }
    raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось отменить ожидающий билет.")


def staged_changes_exist(root: Path) -> bool:
    result = run_git(
        root,
        ["diff", "--cached", "--quiet", "--exit-code", "--"],
        check=False,
    )
    if result.returncode == 0:
        return False
    if result.returncode == 1:
        return True
    detail = result.stderr.decode("utf-8", errors="replace").strip()
    raise QueueError(
        EXIT_CONTEXT,
        "git_error",
        f"Не удалось проверить staged-изменения: {detail}",
    )


def require_owner(
    контекст_очереди: QueueContext,
    state: dict[str, object],
    task_id: str,
    generation: str,
) -> dict[str, object]:
    state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
    owner = state["owner"]
    if (
        not isinstance(owner, dict)
        or owner["task_id"] != task_id
        or owner["generation"] != generation
    ):
        raise QueueError(
            EXIT_OWNERSHIP,
            "not_owner",
            "Задача и поколение не совпадают с текущим владельцем очереди.",
        )
    return owner


def matching_completion(
    state: dict[str, object],
    *,
    kind: str,
    task_id: str,
    generation: str,
) -> dict[str, object] | None:
    completion = state.get("last_completion")
    if (
        isinstance(completion, dict)
        and completion.get("kind") == kind
        and completion.get("task_id") == task_id
        and completion.get("generation") == generation
    ):
        return completion
    return None


def finished_clean_result(
    контекст_очереди: QueueContext,
    state_oid: str | None,
    completion: dict[str, object],
) -> tuple[int, dict[str, object]]:
    return 0, {
        "state": "finished_clean",
        **completion,
        **common_payload(контекст_очереди, state_oid),
    }


def committed_completion_result(
    контекст_очереди: QueueContext,
    state_oid: str | None,
    completion: dict[str, object],
) -> tuple[int, dict[str, object]]:
    ответ = {
        "state": "committed",
        "task_id": completion["task_id"],
        "generation": completion["generation"],
        "old_head": completion["base_head"],
        "new_head": completion["head"],
        **common_payload(контекст_очереди, state_oid),
    }
    if "идентификатор_продолжения" in completion:
        ответ["идентификатор_продолжения"] = completion[
            "идентификатор_продолжения"
        ]
    return 0, ответ


def ссылка_квитанции_связанного_коммита(
    контекст_очереди: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> str:
    хэш_ветки = hashlib.sha256(
        контекст_очереди.branch_ref.encode("utf-8")
    ).hexdigest()
    идентичность = {
        "идентификатор_рабочего_дерева": контекст_очереди.worktree_id,
        "ссылка_ветки": контекст_очереди.branch_ref,
        "идентификатор_задачи": идентификатор_задачи,
        "поколение": поколение,
    }
    отпечаток = hashlib.sha256(
        canonical_state_bytes(идентичность)
    ).hexdigest()
    return (
        f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_СВЯЗАННЫХ_КОММИТОВ}/"
        f"{контекст_очереди.worktree_id}/{хэш_ветки}/{отпечаток}"
    )


def данные_квитанции_связанного_коммита(
    контекст_очереди: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    исходная_вершина: str,
    новая_вершина: str,
    идентификатор_продолжения: str,
) -> dict[str, object]:
    return {
        "схема": СХЕМА_КВИТАНЦИИ_СВЯЗАННОГО_КОММИТА,
        "идентификатор_рабочего_дерева": контекст_очереди.worktree_id,
        "ссылка_ветки": контекст_очереди.branch_ref,
        "идентификатор_задачи": идентификатор_задачи,
        "поколение": поколение,
        "исходная_вершина": исходная_вершина,
        "новая_вершина": новая_вершина,
        "идентификатор_продолжения": идентификатор_продолжения,
    }


def проверить_квитанцию_связанного_коммита(
    контекст_очереди: QueueContext,
    квитанция: object,
    идентификатор_задачи: str,
    поколение: str,
    *,
    требовать_достижимость: bool,
) -> dict[str, object]:
    поля = {
        "схема",
        "идентификатор_рабочего_дерева",
        "ссылка_ветки",
        "идентификатор_задачи",
        "поколение",
        "исходная_вершина",
        "новая_вершина",
        "идентификатор_продолжения",
    }
    длина_объекта = len(current_head(контекст_очереди.root))
    if (
        not isinstance(квитанция, dict)
        or set(квитанция) != поля
        or квитанция.get("схема") != СХЕМА_КВИТАНЦИИ_СВЯЗАННОГО_КОММИТА
        or квитанция.get("идентификатор_рабочего_дерева")
        != контекст_очереди.worktree_id
        or квитанция.get("ссылка_ветки") != контекст_очереди.branch_ref
        or квитанция.get("идентификатор_задачи") != идентификатор_задачи
        or квитанция.get("поколение") != поколение
        or not isinstance(квитанция.get("идентификатор_продолжения"), str)
        or not str(квитанция["идентификатор_продолжения"]).strip()
        or len(str(квитанция["идентификатор_продолжения"])) > 1_024
        or any(
            символ in str(квитанция["идентификатор_продолжения"])
            for символ in ("\0", "\n", "\r")
        )
        or any(
            not isinstance(квитанция.get(поле), str)
            or re.fullmatch(r"[0-9a-f]+", str(квитанция[поле])) is None
            or len(str(квитанция[поле])) != длина_объекта
            for поле in ("исходная_вершина", "новая_вершина")
        )
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "повреждена_квитанция_связанного_коммита",
            "Квитанция связанного коммита повреждена.",
        )
    новая_вершина = str(квитанция["новая_вершина"])
    исходная_вершина = str(квитанция["исходная_вершина"])
    if требовать_достижимость:
        try:
            родители = decoded_stdout(
                run_git(
                    контекст_очереди.root,
                    ["rev-list", "--parents", "-n", "1", новая_вершина],
                )
            ).split()
            достижимость = run_git(
                контекст_очереди.root,
                ["merge-base", "--is-ancestor", новая_вершина, current_head(контекст_очереди.root)],
                check=False,
            )
        except QueueError as ошибка:
            raise QueueError(
                EXIT_CONTEXT,
                "повреждена_квитанция_связанного_коммита",
                "Квитанция не доказывает достижимый однородительский коммит.",
            ) from ошибка
        if родители != [новая_вершина, исходная_вершина] or достижимость.returncode != 0:
            raise QueueError(
                EXIT_CONTEXT,
                "повреждена_квитанция_связанного_коммита",
                "Квитанция не доказывает достижимый однородительский коммит.",
            )
    return квитанция


def прочитать_квитанцию_связанного_коммита(
    контекст_очереди: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> tuple[dict[str, object], str, str] | None:
    ссылка = ссылка_квитанции_связанного_коммита(
        контекст_очереди,
        идентификатор_задачи,
        поколение,
    )
    объект = read_ref_oid(контекст_очереди, ссылка)
    if объект is None:
        return None
    квитанция = прочитать_канонический_объект_данных(
        контекст_очереди,
        объект,
        состояние_ошибки="повреждена_квитанция_связанного_коммита",
        пояснение="Квитанция связанного коммита повреждена.",
    )
    return (
        проверить_квитанцию_связанного_коммита(
            контекст_очереди,
            квитанция,
            идентификатор_задачи,
            поколение,
            требовать_достижимость=True,
        ),
        объект,
        ссылка,
    )


def результат_квитанции_связанного_коммита(
    контекст_очереди: QueueContext,
    объект_очереди: str | None,
    квитанция: dict[str, object],
    объект_квитанции: str,
    ссылка_квитанции: str,
) -> tuple[int, dict[str, object]]:
    длина_объекта = len(str(квитанция["новая_вершина"]))
    if (
        not isinstance(объект_очереди, str)
        or re.fullmatch(r"[0-9a-f]+", объект_очереди) is None
        or len(объект_очереди) != длина_объекта
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "отсутствует_объект_очереди_связанного_коммита",
            "Точный повтор связанного коммита требует полный OID состояния очереди.",
        )
    _, ответ = committed_completion_result(
        контекст_очереди,
        объект_очереди,
        {
            "task_id": квитанция["идентификатор_задачи"],
            "generation": квитанция["поколение"],
            "base_head": квитанция["исходная_вершина"],
            "head": квитанция["новая_вершина"],
            "идентификатор_продолжения": квитанция["идентификатор_продолжения"],
        },
    )
    ответ["объект_квитанции"] = объект_квитанции
    ответ["ссылка_квитанции"] = ссылка_квитанции
    return 0, ответ


def потребовать_совпадение_продолжения(
    завершение: dict[str, object],
    идентификатор_продолжения: str | None,
) -> None:
    есть_связь = "идентификатор_продолжения" in завершение
    сохранённый = завершение.get("идентификатор_продолжения")
    if (
        есть_связь != (идентификатор_продолжения is not None)
        or (есть_связь and сохранённый != идентификатор_продолжения)
    ):
        raise QueueError(
            EXIT_OWNERSHIP,
            "несовпадение_продолжения",
            "Повтор коммита не совпадает с его сохранённым продолжением.",
        )


def потребовать_ожидающее_продолжение(
    состояние: dict[str, object],
    владелец: dict[str, object],
    идентификатор_продолжения: str | None,
) -> None:
    if идентификатор_продолжения is None:
        return
    if идентификатор_продолжения == владелец["task_id"]:
        raise QueueError(
            EXIT_OWNERSHIP,
            "продолжение_совпадает_с_владельцем",
            "Продолжение коммита должно быть другой корневой задачей.",
        )
    совпадения = [
        билет
        for билет in состояние["waiting"]
        if билет["task_id"] == идентификатор_продолжения
    ]
    if len(совпадения) != 1:
        raise QueueError(
            EXIT_OWNERSHIP,
            "продолжение_не_ожидает",
            "Точная задача-продолжение не ожидает в той же очереди ветки.",
        )
    if совпадения[0]["acknowledged_head"] != владелец["base_head"]:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "вершина_продолжения_не_совпадает",
            "Задача-продолжение не подтвердила исходную вершину владельца.",
        )


def completion_head_is_current(
    контекст_очереди: QueueContext,
    completion: dict[str, object],
) -> bool:
    return current_head(контекст_очереди.root) == completion["head"]


def finish_clean_and_handoff(
    контекст_очереди: QueueContext,
    task_id: str,
    generation: str,
    ограждающая_ссылка: str | None = None,
    ожидаемый_объект_ограждения: str | None = None,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    if not generation or "\0" in generation or "\n" in generation:
        raise QueueError(EXIT_CLI, "invalid_generation", "Некорректное поколение владельца.")
    команда_ограждения, ожидаемый_объект = подготовить_внешнее_ограждение(
        контекст_очереди,
        ограждающая_ссылка,
        ожидаемый_объект_ограждения,
    )
    if (
        ограждающая_ссылка is not None
        and read_ref_oid(контекст_очереди, ограждающая_ссылка) != ожидаемый_объект
    ):
        raise QueueError(
            EXIT_CAS,
            "guard_changed",
            "Внешнее ограждение изменилось до чистой передачи.",
        )

    unchanged_ref_failures = 0
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(контекст_очереди)
        state, old_oid = read_state(контекст_очереди)
        state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
        обязательное_продолжение = обязательное_продолжение_активно(
            контекст_очереди,
            state,
        )
        долговечные_завершения = (
            []
            if обязательное_продолжение
            else [
                завершение
                for завершение in (
                    прочитать_долговечное_чистое_завершение_аналитики(
                        контекст_очереди, task_id, generation
                    ),
                    прочитать_долговечное_чистое_завершение_следующего_шага(
                        контекст_очереди, task_id, generation
                    ),
                )
                if завершение is not None
            ]
        )
        if len(долговечные_завершения) > 1:
            raise QueueError(
                EXIT_CONTEXT,
                "ambiguous_clean_automation_completion",
                "Одно чистое завершение связано с несколькими автоматизациями.",
            )
        if долговечные_завершения:
            return finished_clean_result(
                контекст_очереди,
                old_oid,
                долговечные_завершения[0],
            )
        previous = matching_completion(
            state,
            kind="finished_clean",
            task_id=task_id,
            generation=generation,
        )
        if previous is not None:
            if обязательное_продолжение:
                return finished_clean_result(
                    контекст_очереди,
                    old_oid,
                    previous,
                )
            прежний_переход_аналитики = (
                подготовить_переход_чистого_завершения_аналитики(
                    контекст_очереди,
                    task_id,
                    generation,
                    str(previous["head"]),
                )
            )
            прежний_переход_следующего_шага = (
                подготовить_переход_чистого_завершения_следующего_шага(
                    контекст_очереди,
                    task_id,
                    generation,
                    str(previous["head"]),
                )
            )
            if прежний_переход_аналитики is not None and прежний_переход_следующего_шага is not None:
                raise QueueError(
                    EXIT_CONTEXT,
                    "ambiguous_clean_automation_completion",
                    "Чистое завершение связано с двумя автоматизациями.",
                )
            if (
                прежний_переход_аналитики is not None
                and not переход_чистого_завершения_аналитики_зафиксирован(
                    контекст_очереди,
                    прежний_переход_аналитики,
                )
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "missing_analytics_clean_witness",
                    "Чисто завершённый аналитический запуск не имеет durable witness.",
                )
            if (
                прежний_переход_следующего_шага is not None
                and not переход_чистого_завершения_следующего_шага_зафиксирован(
                    контекст_очереди,
                    прежний_переход_следующего_шага,
                )
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "missing_next_step_clean_witness",
                    "Чисто завершённый следующий шаг не имеет долговечного свидетельства.",
                )
            return finished_clean_result(контекст_очереди, old_oid, previous)
        owner = require_owner(контекст_очереди, state, task_id, generation)
        base_head = str(owner["base_head"])
        live_head = current_head(контекст_очереди.root)
        if live_head != base_head:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился после допуска владельца.",
                данные_результата_операции={"expected_head": base_head, "current_head": live_head},
            )
        if not обязательное_продолжение:
            потребовать_сохранность_незавершённого_автозапуска(
                контекст_очереди,
                state,
                task_id,
                generation,
            )
        blocking = sorted(
            set(all_changed_paths(контекст_очереди.root))
            | set(staged_changed_paths(контекст_очереди.root))
        )
        if blocking:
            raise QueueError(
                EXIT_DIRTY,
                "dirty",
                "Чистое завершение требует чистоты вне корневой .obsidian/ и отсутствия любых staged-изменений.",
                данные_результата_операции={"blocking_paths": blocking},
            )
        if old_oid is None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "У владельца отсутствует Git-ссылка состояния очереди.",
            )
        stamp, _ = utc_values()
        completion = {
            "kind": "finished_clean",
            "task_id": task_id,
            "generation": generation,
            "head": base_head,
            "completed_at": stamp,
        }
        updated = copy.deepcopy(state)
        updated["owner"] = None
        updated["last_completion"] = completion
        updated["updated_at"] = stamp
        new_oid = write_state_blob(контекст_очереди, updated)
        if обязательное_продолжение:
            переход_аналитики = None
            переход_следующего_шага = None
        else:
            переход_аналитики = (
                подготовить_переход_чистого_завершения_аналитики(
                    контекст_очереди,
                    task_id,
                    generation,
                    base_head,
                )
            )
            переход_следующего_шага = (
                подготовить_переход_чистого_завершения_следующего_шага(
                    контекст_очереди,
                    task_id,
                    generation,
                    base_head,
                )
            )
        if переход_аналитики is not None and переход_следующего_шага is not None:
            raise QueueError(
                EXIT_CONTEXT,
                "ambiguous_clean_automation_completion",
                "Чистое завершение связано с двумя автоматизациями.",
            )
        if обязательное_продолжение:
            команды_устаревших_переходов = ""
        else:
            команды_устаревших_переходов = (
                команды_перехода_чистого_завершения_аналитики(
                    переход_аналитики
                )
                + команды_перехода_чистого_завершения_следующего_шага(
                    переход_следующего_шага
                )
            )
        result = update_queue_with_head_verification(
            контекст_очереди,
            expected_head=base_head,
            old_queue_oid=old_oid,
            new_queue_oid=new_oid,
            команда_внешнего_ограждения=(
                команда_ограждения
                + команды_устаревших_переходов
            ),
        )
        if result.returncode == 0:
            return finished_clean_result(контекст_очереди, new_oid, completion)
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        observed_head = current_head(контекст_очереди.root)
        observed_state, observed_queue_oid = read_state(контекст_очереди)
        if (
            ограждающая_ссылка is not None
            and read_ref_oid(контекст_очереди, ограждающая_ссылка)
            != ожидаемый_объект
        ):
            raise QueueError(
                EXIT_CAS,
                "guard_changed",
                "Внешнее ограждение изменилось во время чистой передачи.",
            )
        observed_completion = matching_completion(
            observed_state,
            kind="finished_clean",
            task_id=task_id,
            generation=generation,
        )
        if observed_completion is not None:
            if not обязательное_продолжение:
                if not переход_чистого_завершения_аналитики_зафиксирован(
                    контекст_очереди,
                    переход_аналитики,
                ):
                    raise QueueError(
                        EXIT_CONTEXT,
                        "missing_analytics_clean_witness",
                        "Чистое завершение аналитики не записало durable witness.",
                    )
                if not переход_чистого_завершения_следующего_шага_зафиксирован(
                    контекст_очереди,
                    переход_следующего_шага,
                ):
                    raise QueueError(
                        EXIT_CONTEXT,
                        "missing_next_step_clean_witness",
                        "Чистое завершение следующего шага не записало долговечное свидетельство.",
                    )
            return finished_clean_result(
                контекст_очереди,
                observed_queue_oid,
                observed_completion,
            )
        зафиксировано_аналитикой = (
            переход_аналитики is not None
            and переход_чистого_завершения_аналитики_зафиксирован(контекст_очереди, переход_аналитики)
        )
        зафиксировано_следующим_шагом = (
            переход_следующего_шага is not None
            and переход_чистого_завершения_следующего_шага_зафиксирован(контекст_очереди, переход_следующего_шага)
        )
        if зафиксировано_аналитикой or зафиксировано_следующим_шагом:
            return finished_clean_result(
                контекст_очереди,
                observed_queue_oid,
                completion,
            )
        if переход_следующего_шага is not None:
            наблюдаемый_объект_претензии = read_ref_oid(
                контекст_очереди,
                переход_следующего_шага.ссылка_претензии,
            )
            if наблюдаемый_объект_претензии not in {
                переход_следующего_шага.прежний_объект_претензии,
                переход_следующего_шага.новый_объект_претензии,
            }:
                raise QueueError(
                    EXIT_CAS,
                    "next_step_clean_claim_changed",
                    "Претензия чисто завершаемого следующего шага изменилась во время транзакции.",
                )
        if observed_head != base_head:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился во время чистого завершения.",
                данные_результата_операции={"expected_head": base_head, "current_head": observed_head},
            )
        if observed_queue_oid != old_oid:
            unchanged_ref_failures = 0
            time.sleep(REF_RETRY_BASE_SECONDS)
            continue
        unchanged_ref_failures += 1
        if unchanged_ref_failures >= UNCHANGED_REF_RETRY_ATTEMPTS:
            update_ref_error("атомарно чисто завершить задачу", last_stderr)
        time.sleep(ref_retry_delay(unchanged_ref_failures - 1))
    raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось чисто завершить задачу.")


def finish_own_clean_and_handoff(
    контекст_очереди: QueueContext,
    task_id: str,
    ограждающая_ссылка: str | None = None,
    ожидаемый_объект_ограждения: str | None = None,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    ensure_live_branch(контекст_очереди)
    state, _ = read_state(контекст_очереди)
    state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
    owner = state["owner"]
    if not isinstance(owner, dict) or owner["task_id"] != task_id:
        raise QueueError(
            EXIT_OWNERSHIP,
            "not_owner",
            "Задача не является текущим владельцем очереди.",
        )
    generation = str(owner["generation"])
    return finish_clean_and_handoff(
        контекст_очереди,
        task_id,
        generation,
        ограждающая_ссылка,
        ожидаемый_объект_ограждения,
    )


def основа_служебных_ссылок_ветки(контекст: QueueContext) -> str:
    хэш_ветки = hashlib.sha256(контекст.branch_ref.encode("utf-8")).hexdigest()
    return f"{контекст.worktree_id}/{хэш_ветки}"


def ссылка_журнала_завершений(контекст: QueueContext) -> str:
    return (
        f"{ПРОСТРАНСТВО_ЖУРНАЛА_ЗАВЕРШЕНИЙ}/"
        f"{основа_служебных_ссылок_ветки(контекст)}"
    )


def ссылка_аналитики_завершений(контекст: QueueContext) -> str:
    return (
        f"{ПРОСТРАНСТВО_АНАЛИТИКИ_ЗАВЕРШЕНИЙ}/"
        f"{основа_служебных_ссылок_ветки(контекст)}"
    )


def найти_аналитическую_резервацию_созданной_задачи(
    контекст: QueueContext,
    идентификатор_задачи: str,
) -> tuple[str, str, dict[str, object]] | None:
    префикс = (
        f"{ПРОСТРАНСТВО_РЕЗЕРВАЦИЙ}/"
        f"{основа_служебных_ссылок_ветки(контекст)}/"
    )
    результат = run_git(
        контекст.root,
        ["for-each-ref", "--format=%(refname)%00%(objectname)", префикс],
    )
    найденные: list[tuple[str, str, dict[str, object]]] = []
    for строка in результат.stdout.splitlines():
        if not строка:
            continue
        сырая_ссылка, сырой_объект = строка.split(b"\0", 1)
        ссылка = сырая_ссылка.decode("utf-8", errors="strict")
        объект = сырой_объект.decode("ascii", errors="strict")
        резервация = прочитать_канонический_объект_данных(
            контекст,
            объект,
            состояние_ошибки="corrupt_automation_reservation",
            пояснение="Резервация автоматизации повреждена.",
        )
        if (
            резервация.get("job_id")
            == ИДЕНТИФИКАТОР_ЗАДАНИЯ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ
            and резервация.get("идентификатор_созданной_задачи") == идентификатор_задачи
        ):
            найденные.append((ссылка, объект, резервация))
    if not найденные:
        return None
    if len(найденные) != 1:
        raise QueueError(
            EXIT_CONTEXT,
            "ambiguous_analytics_reservation",
            "Созданная задача связана с несколькими резервациями аналитики.",
        )
    return найденные[0]


def проверить_аналитическую_резервацию_для_чистого_завершения(
    резервация: dict[str, object],
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    *,
    разрешить_завершённую: bool = False,
) -> None:
    поля_3 = {
        "версия_схемы", "branch_ref", "selection_head", "идентификатор_реестра",
        "версия_схемы_реестра", "поколение_реестра", "хэш_реестра", "job_id",
        "spec_generation", "trigger_occurrence", "run_key", "идентификатор_попытки", "фаза",
        "исход", "идентификатор_созданной_задачи", "свидетельство_среды", "подтверждение_результата",
        "курсор_до", "task_id", "generation",
    }
    версия = резервация.get("версия_схемы")
    свидетельство = резервация.get("свидетельство_среды")
    владение = (резервация.get("task_id"), резервация.get("generation"))
    незавершённая = (
        резервация.get("фаза") == "задача_создана"
        and резервация.get("исход") is None
        and резервация.get("подтверждение_результата") is None
        and владение in {(None, None), (идентификатор_задачи, None), (идентификатор_задачи, поколение)}
    )
    завершённая = (
        разрешить_завершённую
        and резервация.get("фаза") == "завершён"
        and резервация.get("исход") == "безопасный_отказ_до_эффекта"
        and isinstance(резервация.get("подтверждение_результата"), str)
        and re.fullmatch(r"[0-9a-f]+", str(резервация["подтверждение_результата"])) is not None
        and len(str(резервация["подтверждение_результата"])) == len(current_head(контекст.root))
        and владение == (идентификатор_задачи, поколение)
    )
    if (
        версия not in {3, 4}
        or set(резервация) != (поля_3 if версия == 3 else поля_3 | {"возобновление"})
        or резервация.get("branch_ref") != контекст.branch_ref
        or резервация.get("job_id") != ИДЕНТИФИКАТОР_ЗАДАНИЯ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ
        or резервация.get("идентификатор_созданной_задачи") != идентификатор_задачи
        or not (незавершённая or завершённая)
        or not isinstance(свидетельство, dict)
        or set(свидетельство) != {"вид", "threadId", "hostId"}
        or свидетельство.get("вид") != "threadId"
        or свидетельство.get("threadId") != идентификатор_задачи
        or not isinstance(свидетельство.get("hostId"), str)
        or not свидетельство["hostId"]
        or (версия == 4 and (
            not isinstance(резервация.get("возобновление"), dict)
            or резервация["возобновление"].get("состояние") != "подтверждено_исполнителем"
        ))
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_analytics_reservation",
            "Резервация аналитики не доказывает exact чистое завершение.",
        )


def подготовить_переход_чистого_завершения_аналитики(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
) -> ПереходЧистогоЗавершенияАналитики | None:
    найденная = найти_аналитическую_резервацию_созданной_задачи(контекст, идентификатор_задачи)
    if найденная is None:
        return None
    ссылка_резервации, объект_резервации, резервация = найденная
    проверить_аналитическую_резервацию_для_чистого_завершения(
        резервация, контекст, идентификатор_задачи, поколение
    )
    ссылка_претензии = ссылка_аналитики_завершений(контекст)
    объект_претензии = read_ref_oid(контекст, ссылка_претензии)
    if объект_претензии is None:
        raise QueueError(EXIT_CONTEXT, "missing_analytics_claim", "Аналитический запуск не имеет exact specialized-претензии.")
    претензия = прочитать_канонический_объект_данных(
        контекст, объект_претензии,
        состояние_ошибки="corrupt_analytics_claim", пояснение="Претензия аналитики повреждена."
    )
    поля = {
        "схема", "branch_ref", "selection_head", "job_id", "spec_generation", "поколение_реестра",
        "trigger_occurrence", "run_key", "идентификатор_попытки", "lease_id", "порог", "диапазон_событий",
        "назначение", "путь_реестра", "путь_отчёта", "идентификатор_анализа", "фаза", "task_id", "generation",
        "свидетельство_передачи", "подтверждённый_результат",
    }
    фаза = претензия.get("фаза")
    свидетельство = {"base_head": базовая_вершина, "task_id": идентификатор_задачи, "generation": поколение}
    if фаза == "очищена":
        if (
            (претензия.get("task_id"), претензия.get("generation")) != (идентификатор_задачи, поколение)
            or претензия.get("свидетельство_передачи") != свидетельство
            or претензия.get("подтверждённый_результат") is not None
        ):
            raise QueueError(EXIT_CONTEXT, "corrupt_analytics_clean_witness", "Свидетельство чистого завершения аналитики повреждено.")
        допустимое_владение: tuple[object, object] | None = (идентификатор_задачи, поколение)
    else:
        допустимое_владение = {
        "зарезервирована": (None, None),
        "привязана": (идентификатор_задачи, None),
        "подтверждена": (идентификатор_задачи, поколение),
        }.get(str(фаза))
    ожидаемые_пары = (
        ("схема", СХЕМА_ПРЕТЕНЗИИ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ), ("branch_ref", резервация["branch_ref"]),
        ("selection_head", резервация["selection_head"]), ("job_id", резервация["job_id"]),
        ("spec_generation", резервация["spec_generation"]), ("поколение_реестра", резервация["поколение_реестра"]),
        ("trigger_occurrence", резервация["trigger_occurrence"]), ("run_key", резервация["run_key"]),
        ("идентификатор_попытки", резервация["идентификатор_попытки"]), ("lease_id", резервация["идентификатор_попытки"]),
    )
    if (
        set(претензия) != поля
        or допустимое_владение is None
        or any(претензия.get(поле) != ожидание for поле, ожидание in ожидаемые_пары)
        or (претензия.get("task_id"), претензия.get("generation")) != допустимое_владение
        or (фаза != "очищена" and претензия.get("свидетельство_передачи") is not None)
        or претензия.get("подтверждённый_результат") is not None
        or (фаза != "зарезервирована" and (резервация.get("task_id"), резервация.get("generation")) != (идентификатор_задачи, поколение))
    ):
        raise QueueError(EXIT_CONTEXT, "unverified_analytics_claim", "Аналитическая претензия не доказывает чистое завершение exact-задачи.")
    if фаза == "очищена":
        return ПереходЧистогоЗавершенияАналитики(
            ссылка_резервации, объект_резервации, ссылка_претензии,
            объект_претензии, объект_претензии, свидетельство,
        )
    новая_претензия = copy.deepcopy(претензия)
    новая_претензия["фаза"] = "очищена"
    новая_претензия["task_id"] = идентификатор_задачи
    новая_претензия["generation"] = поколение
    новая_претензия["свидетельство_передачи"] = свидетельство
    новый_объект = записать_канонический_объект_данных(контекст, новая_претензия)
    return ПереходЧистогоЗавершенияАналитики(
        ссылка_резервации, объект_резервации, ссылка_претензии,
        объект_претензии, новый_объект, свидетельство,
    )


def команды_перехода_чистого_завершения_аналитики(
    переход: ПереходЧистогоЗавершенияАналитики | None,
) -> str:
    if переход is None:
        return ""
    if переход.новый_объект_претензии == переход.прежний_объект_претензии:
        return (
            f"verify {переход.ссылка_резервации} {переход.объект_резервации}\n"
            f"verify {переход.ссылка_претензии} {переход.прежний_объект_претензии}\n"
        )
    return (
        f"verify {переход.ссылка_резервации} {переход.объект_резервации}\n"
        f"update {переход.ссылка_претензии} {переход.новый_объект_претензии} "
        f"{переход.прежний_объект_претензии}\n"
    )


def переход_чистого_завершения_аналитики_зафиксирован(
    контекст: QueueContext,
    переход: ПереходЧистогоЗавершенияАналитики | None,
) -> bool:
    if переход is None:
        return True
    объект = read_ref_oid(контекст, переход.ссылка_претензии)
    if объект != переход.новый_объект_претензии:
        return False
    претензия = прочитать_канонический_объект_данных(
        контекст, объект,
        состояние_ошибки="corrupt_analytics_claim", пояснение="Претензия аналитики повреждена."
    )
    return (
        претензия.get("фаза") == "очищена"
        and претензия.get("свидетельство_передачи") == переход.свидетельство
        and претензия.get("task_id") == переход.свидетельство["task_id"]
        and претензия.get("generation") == переход.свидетельство["generation"]
        and претензия.get("подтверждённый_результат") is None
    )


def прочитать_долговечное_чистое_завершение_аналитики(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> dict[str, object] | None:
    найденная = найти_аналитическую_резервацию_созданной_задачи(контекст, идентификатор_задачи)
    if найденная is None:
        return None
    _, _, резервация = найденная
    if резервация.get("фаза") == "завершён":
        проверить_аналитическую_резервацию_для_чистого_завершения(
            резервация, контекст, идентификатор_задачи, поколение,
            разрешить_завершённую=True,
        )
        базовая_вершина = str(резервация["подтверждение_результата"])
    else:
        ссылка_претензии = ссылка_аналитики_завершений(контекст)
        объект_претензии = read_ref_oid(контекст, ссылка_претензии)
        if объект_претензии is None:
            return None
        претензия = прочитать_канонический_объект_данных(
            контекст, объект_претензии,
            состояние_ошибки="corrupt_analytics_claim", пояснение="Претензия аналитики повреждена."
        )
        if претензия.get("фаза") != "очищена":
            return None
        свидетельство = претензия.get("свидетельство_передачи")
        if not isinstance(свидетельство, dict) or not isinstance(свидетельство.get("base_head"), str):
            raise QueueError(EXIT_CONTEXT, "corrupt_analytics_clean_witness", "Свидетельство чистого завершения аналитики повреждено.")
        базовая_вершина = str(свидетельство["base_head"])
        переход = подготовить_переход_чистого_завершения_аналитики(
            контекст, идентификатор_задачи, поколение, базовая_вершина
        )
        if переход is None or not переход_чистого_завершения_аналитики_зафиксирован(контекст, переход):
            raise QueueError(EXIT_CONTEXT, "corrupt_analytics_clean_witness", "Свидетельство чистого завершения аналитики не подтверждено.")
    текущая_вершина = current_head(контекст.root)
    цепочка = decoded_stdout(run_git(контекст.root, ["rev-list", "--first-parent", текущая_вершина])).splitlines()
    if базовая_вершина not in цепочка:
        raise QueueError(EXIT_CONTEXT, "analytics_clean_head_changed", "Вершина чистого завершения не входит в текущую first-parent историю.")
    return {"kind": "finished_clean", "task_id": идентификатор_задачи, "generation": поколение, "head": базовая_вершина}


def найти_резервацию_следующего_шага_созданной_задачи(
    контекст: QueueContext,
    идентификатор_задачи: str,
) -> tuple[str, str, dict[str, object]] | None:
    префикс = (
        f"{ПРОСТРАНСТВО_РЕЗЕРВАЦИЙ}/"
        f"{основа_служебных_ссылок_ветки(контекст)}/"
    )
    результат = run_git(
        контекст.root,
        ["for-each-ref", "--format=%(refname)%00%(objectname)", префикс],
    )
    найденные: list[tuple[str, str, dict[str, object]]] = []
    for строка in результат.stdout.splitlines():
        if not строка:
            continue
        сырая_ссылка, сырой_объект = строка.split(b"\0", 1)
        ссылка = сырая_ссылка.decode("utf-8", errors="strict")
        объект = сырой_объект.decode("ascii", errors="strict")
        резервация = прочитать_канонический_объект_данных(
            контекст,
            объект,
            состояние_ошибки="corrupt_automation_reservation",
            пояснение="Резервация автоматизации повреждена.",
        )
        if (
            резервация.get("job_id") == "master.next-step"
            and резервация.get("идентификатор_созданной_задачи") == идентификатор_задачи
        ):
            найденные.append((ссылка, объект, резервация))
    if not найденные:
        return None
    if len(найденные) != 1:
        raise QueueError(
            EXIT_CONTEXT,
            "ambiguous_next_step_reservation",
            "Созданная задача связана с несколькими резервациями следующего шага.",
        )
    return найденные[0]


def проверить_резервацию_следующего_шага_для_чистого_завершения(
    резервация: dict[str, object],
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
    *,
    разрешить_завершённую: bool = False,
) -> None:
    поля_3 = {
        "версия_схемы", "branch_ref", "selection_head", "идентификатор_реестра",
        "версия_схемы_реестра", "поколение_реестра", "хэш_реестра", "job_id",
        "spec_generation", "trigger_occurrence", "run_key", "идентификатор_попытки", "фаза",
        "исход", "идентификатор_созданной_задачи", "свидетельство_среды", "подтверждение_результата",
        "курсор_до", "task_id", "generation",
    }
    версия = резервация.get("версия_схемы")
    свидетельство = резервация.get("свидетельство_среды")
    владение = (резервация.get("task_id"), резервация.get("generation"))
    незавершённая = (
        резервация.get("фаза") == "задача_создана"
        and резервация.get("исход") is None
        and резервация.get("подтверждение_результата") is None
        and владение in {(None, None), (идентификатор_задачи, None), (идентификатор_задачи, поколение)}
    )
    завершённая = (
        разрешить_завершённую
        and резервация.get("фаза") == "завершён"
        and резервация.get("исход") == "безопасный_отказ_до_эффекта"
        and резервация.get("подтверждение_результата") == базовая_вершина
        and владение == (идентификатор_задачи, поколение)
    )
    if (
        версия not in {3, 4}
        or set(резервация) != (поля_3 if версия == 3 else поля_3 | {"возобновление"})
        or резервация.get("branch_ref") != контекст.branch_ref
        or резервация.get("selection_head") != базовая_вершина
        or резервация.get("job_id") != "master.next-step"
        or резервация.get("идентификатор_созданной_задачи") != идентификатор_задачи
        or not (незавершённая or завершённая)
        or type(резервация.get("spec_generation")) is not int
        or int(резервация["spec_generation"]) < 1
        or not isinstance(свидетельство, dict)
        or set(свидетельство) != {"вид", "threadId", "hostId"}
        or свидетельство.get("вид") != "threadId"
        or свидетельство.get("threadId") != идентификатор_задачи
        or not isinstance(свидетельство.get("hostId"), str)
        or not свидетельство["hostId"]
        or (версия == 4 and (
            not isinstance(резервация.get("возобновление"), dict)
            or резервация["возобновление"].get("состояние") != "подтверждено_исполнителем"
        ))
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_next_step_reservation",
            "Резервация следующего шага не доказывает exact чистое завершение.",
        )


def подготовить_переход_чистого_завершения_следующего_шага(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
) -> ПереходЧистогоЗавершенияСледующегоШага | None:
    найденная = найти_резервацию_следующего_шага_созданной_задачи(контекст, идентификатор_задачи)
    if найденная is None:
        return None
    ссылка_резервации, объект_резервации, резервация = найденная
    проверить_резервацию_следующего_шага_для_чистого_завершения(
        резервация, контекст, идентификатор_задачи, поколение, базовая_вершина
    )
    ссылка_претензии = f"{ПРОСТРАНСТВО_ПРЕТЕНЗИЙ}/{основа_служебных_ссылок_ветки(контекст)}"
    объект_претензии = read_ref_oid(контекст, ссылка_претензии)
    if объект_претензии is None:
        raise QueueError(EXIT_CONTEXT, "missing_next_step_claim", "Чисто завершаемый шаг не имеет exact претензии.")
    претензия = прочитать_канонический_объект_данных(
        контекст,
        объект_претензии,
        состояние_ошибки="corrupt_next_step_claim",
        пояснение="Претензия следующего шага повреждена.",
    )
    if претензия.get("schema_version") == 4:
        return None
    поля_5 = {
        "schema_version", "branch_ref", "step_id", "card_id", "selection_id",
        "selection_head", "lease_id", "task_id", "generation",
    }
    свидетельство = {
        "base_head": базовая_вершина,
        "task_id": идентификатор_задачи,
        "generation": поколение,
    }
    версия = претензия.get("schema_version")
    ожидаемые_поля = поля_5 if версия == 5 else поля_5 | {"свидетельство_чистого_завершения"}
    допустимое_владение = (
        (претензия.get("task_id"), претензия.get("generation"))
        in {(None, None), (идентификатор_задачи, None), (идентификатор_задачи, поколение)}
        if версия == 5
        else (претензия.get("task_id"), претензия.get("generation")) == (идентификатор_задачи, поколение)
    )
    if (
        версия not in {5, 6}
        or set(претензия) != ожидаемые_поля
        or претензия.get("branch_ref") != контекст.branch_ref
        or претензия.get("selection_head") != базовая_вершина
        or претензия.get("lease_id") != резервация.get("идентификатор_попытки")
        or not допустимое_владение
        or not isinstance(претензия.get("step_id"), str)
        or re.fullmatch(r"[a-z0-9][a-z0-9._-]*", str(претензия.get("step_id"))) is None
        or not isinstance(претензия.get("card_id"), str)
        or re.fullmatch(r"FUM-STEP-[0-9]{4,}", str(претензия.get("card_id"))) is None
        or not isinstance(претензия.get("selection_id"), str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", str(претензия.get("selection_id"))) is None
        or (версия == 6 and претензия.get("свидетельство_чистого_завершения") != свидетельство)
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "unverified_next_step_clean_claim",
            "Претензия следующего шага не доказывает exact чистое завершение.",
        )
    if версия == 6:
        return ПереходЧистогоЗавершенияСледующегоШага(
            ссылка_резервации, объект_резервации, ссылка_претензии,
            объект_претензии, объект_претензии, свидетельство,
        )
    новая_претензия = copy.deepcopy(претензия)
    новая_претензия["schema_version"] = 6
    новая_претензия["task_id"] = идентификатор_задачи
    новая_претензия["generation"] = поколение
    новая_претензия["свидетельство_чистого_завершения"] = свидетельство
    новый_объект = записать_канонический_объект_данных(контекст, новая_претензия)
    return ПереходЧистогоЗавершенияСледующегоШага(
        ссылка_резервации, объект_резервации, ссылка_претензии,
        объект_претензии, новый_объект, свидетельство,
    )


def команды_перехода_чистого_завершения_следующего_шага(
    переход: ПереходЧистогоЗавершенияСледующегоШага | None,
) -> str:
    if переход is None:
        return ""
    if переход.новый_объект_претензии == переход.прежний_объект_претензии:
        return (
            f"verify {переход.ссылка_резервации} {переход.объект_резервации}\n"
            f"verify {переход.ссылка_претензии} {переход.прежний_объект_претензии}\n"
        )
    return (
        f"verify {переход.ссылка_резервации} {переход.объект_резервации}\n"
        f"update {переход.ссылка_претензии} {переход.новый_объект_претензии} "
        f"{переход.прежний_объект_претензии}\n"
    )


def переход_чистого_завершения_следующего_шага_зафиксирован(
    контекст: QueueContext,
    переход: ПереходЧистогоЗавершенияСледующегоШага | None,
) -> bool:
    if переход is None:
        return True
    объект = read_ref_oid(контекст, переход.ссылка_претензии)
    if объект is None:
        return False
    претензия = прочитать_канонический_объект_данных(
        контекст,
        объект,
        состояние_ошибки="corrupt_next_step_claim",
        пояснение="Претензия следующего шага повреждена.",
    )
    return (
        объект == переход.новый_объект_претензии
        and претензия.get("schema_version") == 6
        and претензия.get("свидетельство_чистого_завершения") == переход.свидетельство
        and претензия.get("task_id") == переход.свидетельство["task_id"]
        and претензия.get("generation") == переход.свидетельство["generation"]
    )


def прочитать_долговечное_чистое_завершение_следующего_шага(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> dict[str, object] | None:
    найденная = найти_резервацию_следующего_шага_созданной_задачи(контекст, идентификатор_задачи)
    if найденная is None:
        return None
    _, _, резервация = найденная
    базовая_вершина = str(резервация.get("selection_head"))
    if резервация.get("фаза") == "завершён":
        проверить_резервацию_следующего_шага_для_чистого_завершения(
            резервация,
            контекст,
            идентификатор_задачи,
            поколение,
            базовая_вершина,
            разрешить_завершённую=True,
        )
    else:
        ссылка_претензии = f"{ПРОСТРАНСТВО_ПРЕТЕНЗИЙ}/{основа_служебных_ссылок_ветки(контекст)}"
        объект_претензии = read_ref_oid(контекст, ссылка_претензии)
        if объект_претензии is None:
            return None
        претензия = прочитать_канонический_объект_данных(
            контекст,
            объект_претензии,
            состояние_ошибки="corrupt_next_step_claim",
            пояснение="Претензия следующего шага повреждена.",
        )
        if претензия.get("schema_version") != 6:
            return None
        свидетельство = претензия.get("свидетельство_чистого_завершения")
        if not isinstance(свидетельство, dict) or not isinstance(свидетельство.get("base_head"), str):
            raise QueueError(EXIT_CONTEXT, "corrupt_next_step_clean_witness", "Свидетельство чистого завершения следующего шага повреждено.")
        базовая_вершина = str(свидетельство["base_head"])
        переход = подготовить_переход_чистого_завершения_следующего_шага(
            контекст, идентификатор_задачи, поколение, базовая_вершина
        )
        if переход is None or not переход_чистого_завершения_следующего_шага_зафиксирован(контекст, переход):
            raise QueueError(EXIT_CONTEXT, "corrupt_next_step_clean_witness", "Свидетельство чистого завершения следующего шага не подтверждено.")
    текущая_вершина = current_head(контекст.root)
    цепочка = decoded_stdout(run_git(контекст.root, ["rev-list", "--first-parent", текущая_вершина])).splitlines()
    if базовая_вершина not in цепочка:
        raise QueueError(EXIT_CONTEXT, "next_step_clean_head_changed", "Вершина чистого завершения не входит в текущую first-parent историю.")
    return {"kind": "finished_clean", "task_id": идентификатор_задачи, "generation": поколение, "head": базовая_вершина}


def идентификатор_события_завершения(событие: dict[str, object]) -> str:
    основа = {
        "branch_ref": событие["branch_ref"],
        "step_id": событие["step_id"],
        "card_id": событие["card_id"],
        "завершивший_commit": событие["завершивший_commit"],
        "результат": событие["результат"],
    }
    байты = json.dumps(
        основа,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(байты).hexdigest()


def проверить_событие_завершения(
    значение: object,
    контекст: QueueContext,
    номер: int,
) -> dict[str, object]:
    поля = {
        "номер",
        "идентификатор",
        "branch_ref",
        "step_id",
        "card_id",
        "selection_head",
        "завершивший_commit",
        "результат",
        "job_id",
        "spec_generation",
    }
    if not isinstance(значение, dict) or set(значение) != поля:
        raise QueueError(EXIT_CONTEXT, "corrupt_completion_ledger", "Событие журнала завершений повреждено.")
    if (
        значение["номер"] != номер
        or значение["branch_ref"] != контекст.branch_ref
        or значение["результат"] != "commit+handoff"
        or значение["job_id"] != "master.next-step"
        or type(значение["spec_generation"]) is not int
        or значение["spec_generation"] < 1
        or not isinstance(значение["step_id"], str)
        or re.fullmatch(r"[a-z0-9][a-z0-9._-]*", значение["step_id"]) is None
        or not isinstance(значение["card_id"], str)
        or re.fullmatch(r"FUM-STEP-[0-9]{4,}", значение["card_id"]) is None
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_completion_ledger", "Событие журнала не совпадает с областью.")
    длина_объекта = len(current_head(контекст.root))
    for поле in ("selection_head", "завершивший_commit"):
        if not isinstance(значение[поле], str) or re.fullmatch(
            r"[0-9a-f]+", значение[поле]
        ) is None or len(значение[поле]) != длина_объекта:
            raise QueueError(EXIT_CONTEXT, "corrupt_completion_ledger", "Событие журнала имеет неверный Git-объект.")
    ожидаемый = идентификатор_события_завершения(значение)
    if значение["идентификатор"] != ожидаемый:
        raise QueueError(EXIT_CONTEXT, "corrupt_completion_ledger", "Идентификатор события журнала не воспроизводится.")
    return значение


def прочитать_журнал_завершений(
    контекст: QueueContext,
) -> tuple[dict[str, object], str | None]:
    ссылка = ссылка_журнала_завершений(контекст)
    объект = read_ref_oid(контекст, ссылка)
    if объект is None:
        return {
            "схема": СХЕМА_ЖУРНАЛА_ЗАВЕРШЕНИЙ,
            "branch_ref": контекст.branch_ref,
            "число_событий": 0,
            "события": [],
        }, None
    журнал = прочитать_канонический_объект_данных(
        контекст,
        объект,
        состояние_ошибки="corrupt_completion_ledger",
        пояснение="Журнал завершённых запусков повреждён.",
    )
    if set(журнал) != {"схема", "branch_ref", "число_событий", "события"} or журнал["схема"] != СХЕМА_ЖУРНАЛА_ЗАВЕРШЕНИЙ or журнал["branch_ref"] != контекст.branch_ref or not isinstance(журнал["события"], list) or журнал["число_событий"] != len(журнал["события"]):
        raise QueueError(EXIT_CONTEXT, "corrupt_completion_ledger", "Журнал завершённых запусков нарушает схему.")
    идентификаторы: set[str] = set()
    for номер, событие in enumerate(журнал["события"], 1):
        проверенное = проверить_событие_завершения(событие, контекст, номер)
        идентификатор = str(проверенное["идентификатор"])
        if идентификатор in идентификаторы:
            raise QueueError(EXIT_CONTEXT, "corrupt_completion_ledger", "Журнал повторяет событие завершения.")
        идентификаторы.add(идентификатор)
    return журнал, объект


def записать_канонический_объект_данных(
    контекст: QueueContext,
    значение: dict[str, object],
) -> str:
    результат = run_git(
        контекст.root,
        ["hash-object", "-w", "--stdin"],
        input_bytes=canonical_state_bytes(значение),
    )
    return decoded_stdout(результат)


def найти_резервацию_владельца(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> tuple[str, str, dict[str, object]] | None:
    префикс = (
        f"{ПРОСТРАНСТВО_РЕЗЕРВАЦИЙ}/"
        f"{основа_служебных_ссылок_ветки(контекст)}/"
    )
    результат = run_git(
        контекст.root,
        ["for-each-ref", "--format=%(refname)%00%(objectname)", префикс],
    )
    найденные: list[tuple[str, str, dict[str, object]]] = []
    for строка in результат.stdout.splitlines():
        if not строка:
            continue
        сырая_ссылка, сырой_объект = строка.split(b"\0", 1)
        ссылка = сырая_ссылка.decode("utf-8", errors="strict")
        объект = сырой_объект.decode("ascii", errors="strict")
        резервация = прочитать_канонический_объект_данных(
            контекст,
            объект,
            состояние_ошибки="corrupt_automation_reservation",
            пояснение="Резервация автоматизации повреждена.",
        )
        if резервация.get("task_id") == идентификатор_задачи and резервация.get("generation") == поколение:
            найденные.append((ссылка, объект, резервация))
    if not найденные:
        return None
    if len(найденные) != 1:
        raise QueueError(EXIT_CONTEXT, "ambiguous_automation_reservation", "Один владелец FIFO связан с несколькими резервациями.")
    return найденные[0]


def найти_резервацию_завершаемого_шага(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
) -> tuple[str, str, dict[str, object]] | None:
    найденная = найти_резервацию_владельца(
        контекст,
        идентификатор_задачи,
        поколение,
    )
    if найденная is None:
        return None
    ссылка, объект, резервация = найденная
    if резервация.get("job_id") != "master.next-step":
        return None
    свидетельство = резервация.get("свидетельство_среды")
    if (
        резервация.get("версия_схемы") not in {3, 4}
        or резервация.get("branch_ref") != контекст.branch_ref
        or резервация.get("selection_head") != базовая_вершина
        or резервация.get("фаза") != "задача_создана"
        or резервация.get("исход") is not None
        or резервация.get("подтверждение_результата") is not None
        or резервация.get("идентификатор_созданной_задачи") != идентификатор_задачи
        or type(резервация.get("spec_generation")) is not int
        or int(резервация["spec_generation"]) < 1
        or not isinstance(резервация.get("идентификатор_попытки"), str)
        or not isinstance(свидетельство, dict)
        or set(свидетельство) != {"вид", "threadId", "hostId"}
        or свидетельство.get("вид") != "threadId"
        or свидетельство.get("threadId") != идентификатор_задачи
        or not isinstance(свидетельство.get("hostId"), str)
        or not свидетельство["hostId"]
        or (
            резервация.get("версия_схемы") == 4
            and (
                not isinstance(резервация.get("возобновление"), dict)
                or резервация["возобновление"].get("состояние")
                != "подтверждено_исполнителем"
            )
        )
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_automation_reservation", "Резервация завершаемого шага не доказывает точный запуск.")
    try:
        if str(uuid.UUID(str(резервация["идентификатор_попытки"]))) != резервация["идентификатор_попытки"]:
            raise ValueError
    except ValueError as ошибка:
        raise QueueError(EXIT_CONTEXT, "corrupt_automation_reservation", "Резервация имеет неверную попытку.") from ошибка
    return ссылка, объект, резервация


def прочитать_точную_претензию_завершаемого_шага(
    контекст: QueueContext,
    резервация: dict[str, object],
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
) -> tuple[str, str, dict[str, object]]:
    ссылка = (
        f"{ПРОСТРАНСТВО_ПРЕТЕНЗИЙ}/"
        f"{основа_служебных_ссылок_ветки(контекст)}"
    )
    объект = read_ref_oid(контекст, ссылка)
    if объект is None:
        raise QueueError(
            EXIT_CONTEXT,
            "missing_next_step_claim",
            "Завершаемый автошаг не имеет карточной претензии.",
        )
    претензия = прочитать_канонический_объект_данных(
        контекст,
        объект,
        состояние_ошибки="corrupt_next_step_claim",
        пояснение="Карточная претензия повреждена.",
    )
    версия = претензия.get("schema_version")
    поля_4 = {
        "schema_version",
        "branch_ref",
        "step_id",
        "selection_id",
        "selection_head",
        "lease_id",
        "task_id",
        "generation",
    }
    ожидаемые_поля = поля_4 if версия == 4 else поля_4 | {"card_id"}
    if (
        версия not in {4, 5}
        or set(претензия) != ожидаемые_поля
        or претензия.get("branch_ref") != контекст.branch_ref
        or претензия.get("selection_head") != базовая_вершина
        or претензия.get("lease_id")
        != резервация.get("идентификатор_попытки")
        or претензия.get("task_id") != идентификатор_задачи
        or претензия.get("generation") != поколение
        or not isinstance(претензия.get("step_id"), str)
        or re.fullmatch(
            r"[a-z0-9][a-z0-9._-]*", str(претензия.get("step_id"))
        )
        is None
        or not isinstance(претензия.get("selection_id"), str)
        or re.fullmatch(
            r"sha256:[0-9a-f]{64}", str(претензия.get("selection_id"))
        )
        is None
        or (
            версия == 5
            and (
                not isinstance(претензия.get("card_id"), str)
                or re.fullmatch(
                    r"FUM-STEP-[0-9]{4,}", str(претензия.get("card_id"))
                )
                is None
            )
        )
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_next_step_claim",
            "Карточная претензия не доказывает точный завершаемый шаг.",
        )
    return ссылка, объект, претензия


def получить_историческую_карточку_следующего_шага(
    контекст: QueueContext,
    претензия: dict[str, object],
) -> str:
    ветка = str(претензия["branch_ref"])
    вершина = str(претензия["selection_head"])
    среда = clean_git_environment()
    среда["GIT_TERMINAL_PROMPT"] = "0"
    try:
        with tempfile.TemporaryDirectory(
            prefix="fum-queue-next-step-selection-"
        ) as временный_каталог:
            историческая_копия = Path(временный_каталог) / "repo"
            команды = (
                (
                    "git",
                    "clone",
                    "--shared",
                    "--no-checkout",
                    "--quiet",
                    str(контекст.root),
                    str(историческая_копия),
                ),
                (
                    "git",
                    "-C",
                    str(историческая_копия),
                    "update-ref",
                    "--no-deref",
                    ветка,
                    вершина,
                ),
                (
                    "git",
                    "-C",
                    str(историческая_копия),
                    "symbolic-ref",
                    "HEAD",
                    ветка,
                ),
                (
                    "git",
                    "-C",
                    str(историческая_копия),
                    "reset",
                    "--hard",
                    вершина,
                ),
            )
            for команда in команды:
                результат = subprocess.run(
                    команда,
                    check=False,
                    capture_output=True,
                    text=True,
                    env=среда,
                    timeout=GIT_COMMAND_TIMEOUT_SECONDS,
                )
                if результат.returncode != 0:
                    raise ValueError("исторический checkout не подтверждён")
            сценарий = (
                историческая_копия
                / "Инструменты"
                / "fum-sleduyusjhij-shag-vetki"
                / "scripts"
                / "branch-next-step.py"
            )
            if сценарий.is_symlink() or not сценарий.is_file():
                raise ValueError("исторический сценарий отсутствует")
            проверка = subprocess.run(
                (
                    sys.executable,
                    str(сценарий),
                    "show",
                    "--repo-root",
                    str(историческая_копия),
                    "--expected-branch-ref",
                    ветка,
                    "--expected-step-id",
                    str(претензия["step_id"]),
                    "--expected-selection-id",
                    str(претензия["selection_id"]),
                    "--json",
                ),
                check=False,
                capture_output=True,
                text=True,
                env=среда,
                timeout=GIT_COMMAND_TIMEOUT_SECONDS,
            )
            if проверка.returncode != 0:
                raise ValueError("исторический выбор не подтверждён")
            ответ = json.loads(
                проверка.stdout,
                object_pairs_hook=собрать_объект_без_повторов,
                parse_constant=отклонить_неконечное_число,
            )
    except (
        OSError,
        UnicodeError,
        ValueError,
        json.JSONDecodeError,
        subprocess.TimeoutExpired,
        QueueError,
    ) as ошибка:
        raise QueueError(
            EXIT_CONTEXT,
            "unverified_historical_next_step_selection",
            "Исторический выбор завершаемого шага не подтверждён.",
        ) from ошибка
    выбор = ответ.get("selection") if isinstance(ответ, dict) else None
    карточка = ответ.get("card_id") if isinstance(ответ, dict) else None
    хэш_карточки = (
        ответ.get("card_content_sha256") if isinstance(ответ, dict) else None
    )
    if (
        not isinstance(ответ, dict)
        or ответ.get("state") != "ready"
        or ответ.get("step_id") != претензия["step_id"]
        or not isinstance(карточка, str)
        or re.fullmatch(r"FUM-STEP-[0-9]{4,}", карточка) is None
        or not isinstance(хэш_карточки, str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", хэш_карточки) is None
        or not isinstance(выбор, dict)
        or выбор.get("id") != претензия["selection_id"]
        or выбор.get("head") != вершина
        or (
            "card_id" in претензия
            and претензия.get("card_id") != карточка
        )
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "unverified_historical_next_step_selection",
            "Исторический выбор завершаемого шага не совпал с претензией.",
        )
    return карточка


def подготовить_переход_журнала_завершений(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
    объект_коммита: str,
) -> ПереходЖурналаЗавершений | None:
    найденная = найти_резервацию_завершаемого_шага(контекст, идентификатор_задачи, поколение, базовая_вершина)
    if найденная is None:
        return None
    ссылка_резервации, объект_резервации, резервация = найденная
    ссылка_претензии, объект_претензии, претензия = (
        прочитать_точную_претензию_завершаемого_шага(
            контекст,
            резервация,
            идентификатор_задачи,
            поколение,
            базовая_вершина,
        )
    )
    новый_объект_претензии = объект_претензии
    if претензия["schema_version"] == 4:
        новая_претензия = dict(претензия)
        новая_претензия["schema_version"] = 5
        новая_претензия["card_id"] = (
            получить_историческую_карточку_следующего_шага(
                контекст,
                претензия,
            )
        )
        новый_объект_претензии = записать_канонический_объект_данных(
            контекст,
            новая_претензия,
        )
        претензия = новая_претензия
    elif претензия["schema_version"] != 5:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_next_step_claim",
            "Карточная претензия имеет неподдерживаемую схему.",
        )
    журнал, прежний_объект = прочитать_журнал_завершений(контекст)
    событие: dict[str, object] = {
        "номер": len(журнал["события"]) + 1,
        "идентификатор": "",
        "branch_ref": контекст.branch_ref,
        "step_id": претензия["step_id"],
        "card_id": претензия["card_id"],
        "selection_head": базовая_вершина,
        "завершивший_commit": объект_коммита,
        "результат": "commit+handoff",
        "job_id": "master.next-step",
        "spec_generation": резервация["spec_generation"],
    }
    событие["идентификатор"] = идентификатор_события_завершения(событие)
    существующие = [
        элемент
        for элемент in журнал["события"]
        if isinstance(элемент, dict)
        and элемент.get("идентификатор") == событие["идентификатор"]
    ]
    if существующие:
        if len(существующие) != 1 or {
            ключ: значение
            for ключ, значение in событие.items()
            if ключ != "номер"
        } != {
            ключ: значение
            for ключ, значение in существующие[0].items()
            if ключ != "номер"
        }:
            raise QueueError(EXIT_CONTEXT, "completion_event_collision", "Идентичность события завершения противоречива.")
        событие = существующие[0]
        новый_объект = прежний_объект
    else:
        журнал["события"] = [*журнал["события"], событие]
        журнал["число_событий"] = len(журнал["события"])
        новый_объект = записать_канонический_объект_данных(контекст, журнал)
    if новый_объект is None:
        raise QueueError(EXIT_CONTEXT, "corrupt_completion_ledger", "Не удалось подготовить объект журнала.")
    return ПереходЖурналаЗавершений(
        ссылка=ссылка_журнала_завершений(контекст),
        прежний_объект=прежний_объект,
        новый_объект=новый_объект,
        ссылка_резервации=ссылка_резервации,
        объект_резервации=объект_резервации,
        ссылка_претензии=ссылка_претензии,
        объект_претензии=объект_претензии,
        новый_объект_претензии=новый_объект_претензии,
        событие=событие,
    )


def переход_журнала_зафиксирован(
    контекст: QueueContext,
    переход: ПереходЖурналаЗавершений | None,
) -> bool:
    if переход is None:
        return True
    журнал, _ = прочитать_журнал_завершений(контекст)
    return any(
        isinstance(событие, dict)
        and событие == переход.событие
        for событие in журнал["события"]
    )


def команды_перехода_журнала(
    переход: ПереходЖурналаЗавершений | None,
) -> str:
    if переход is None:
        return ""
    команды = (
        f"verify {переход.ссылка_резервации} "
        f"{переход.объект_резервации}\n"
    )
    if переход.новый_объект_претензии == переход.объект_претензии:
        команды += (
            f"verify {переход.ссылка_претензии} "
            f"{переход.объект_претензии}\n"
        )
    else:
        команды += (
            f"update {переход.ссылка_претензии} "
            f"{переход.новый_объект_претензии} "
            f"{переход.объект_претензии}\n"
        )
    if переход.прежний_объект is None:
        return (
            команды
            + f"create {переход.ссылка} {переход.новый_объект}\n"
        )
    return (
        команды
        + f"update {переход.ссылка} {переход.новый_объект} "
        + f"{переход.прежний_объект}\n"
    )


def прочитать_долговечное_завершение_следующего_шага(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> dict[str, object] | None:
    найденная = найти_резервацию_владельца(контекст, идентификатор_задачи, поколение)
    if найденная is None:
        return None
    _, _, резервация = найденная
    if резервация.get("job_id") != "master.next-step":
        return None
    if резервация.get("фаза") != "завершён":
        return None
    свидетельство = резервация.get("свидетельство_среды")
    базовая_вершина = резервация.get("selection_head")
    объект_коммита = резервация.get("подтверждение_результата")
    поля_3 = {
        "версия_схемы", "branch_ref", "selection_head", "идентификатор_реестра",
        "версия_схемы_реестра", "поколение_реестра", "хэш_реестра", "job_id", "spec_generation",
        "trigger_occurrence", "run_key", "идентификатор_попытки", "фаза", "исход",
        "идентификатор_созданной_задачи", "свидетельство_среды", "подтверждение_результата",
        "курсор_до", "task_id", "generation",
    }
    версия = резервация.get("версия_схемы")
    if (
        версия not in {3, 4}
        or set(резервация) != (поля_3 if версия == 3 else поля_3 | {"возобновление"})
        or резервация.get("branch_ref") != контекст.branch_ref
        or резервация.get("исход") != "успех"
        or резервация.get("идентификатор_созданной_задачи") != идентификатор_задачи
        or резервация.get("task_id") != идентификатор_задачи
        or резервация.get("generation") != поколение
        or not isinstance(свидетельство, dict)
        or set(свидетельство) != {"вид", "threadId", "hostId"}
        or свидетельство.get("вид") != "threadId"
        or свидетельство.get("threadId") != идентификатор_задачи
        or not isinstance(базовая_вершина, str)
        or not isinstance(объект_коммита, str)
        or re.fullmatch(r"[0-9a-f]+", базовая_вершина) is None
        or re.fullmatch(r"[0-9a-f]+", объект_коммита) is None
        or len(базовая_вершина) != len(current_head(контекст.root))
        or len(объект_коммита) != len(базовая_вершина)
        or (
            версия == 4
            and (
                not isinstance(резервация.get("возобновление"), dict)
                or резервация["возобновление"].get("состояние") != "подтверждено_исполнителем"
            )
        )
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_automation_reservation", "Завершённая резервация не доказывает exact next-step запуск.")
    _, _, претензия = прочитать_точную_претензию_завершаемого_шага(
        контекст,
        резервация,
        идентификатор_задачи,
        поколение,
        базовая_вершина,
    )
    совпадения: list[dict[str, object]] = []
    if претензия["schema_version"] == 4:
        получить_историческую_карточку_следующего_шага(
            контекст,
            претензия,
        )
    else:
        журнал, _ = прочитать_журнал_завершений(контекст)
        совпадения = [
            событие for событие in журнал["события"]
            if isinstance(событие, dict)
            and событие.get("branch_ref") == контекст.branch_ref
            and событие.get("step_id") == претензия["step_id"]
            and событие.get("card_id") == претензия["card_id"]
            and событие.get("selection_head") == базовая_вершина
            and событие.get("завершивший_commit") == объект_коммита
            and событие.get("job_id") == "master.next-step"
            and событие.get("spec_generation")
            == резервация.get("spec_generation")
        ]
    родители = decoded_stdout(run_git(контекст.root, ["rev-list", "--parents", "-n", "1", объект_коммита])).split()
    текущая_вершина = current_head(контекст.root)
    цепочка = decoded_stdout(run_git(контекст.root, ["rev-list", "--first-parent", текущая_вершина])).splitlines()
    журнал_подтверждён = (
        претензия["schema_version"] == 4 or len(совпадения) == 1
    )
    if (
        not журнал_подтверждён
        or родители != [объект_коммита, базовая_вершина]
        or объект_коммита not in цепочка
    ):
        raise QueueError(EXIT_CONTEXT, "completion_ledger_unverified", "Журнал не доказывает exact terminal next-step передачу.")
    return {"kind": "committed", "task_id": идентификатор_задачи, "generation": поколение, "base_head": базовая_вершина, "head": объект_коммита}


def долговечный_журнал_доказывает_незавершённое_завершение(
    контекст: QueueContext,
    резервация: dict[str, object],
    завершение: dict[str, object],
) -> bool:
    if завершение.get("kind") != "committed":
        return False
    идентификатор_задачи = str(завершение.get("task_id"))
    поколение = str(завершение.get("generation"))
    базовая_вершина = str(завершение.get("base_head"))
    объект_коммита = str(завершение.get("head"))
    try:
        найденная = найти_резервацию_завершаемого_шага(
            контекст,
            идентификатор_задачи,
            поколение,
            базовая_вершина,
        )
        if найденная is None or найденная[2] != резервация:
            return False
        _, _, претензия = прочитать_точную_претензию_завершаемого_шага(
            контекст,
            резервация,
            идентификатор_задачи,
            поколение,
            базовая_вершина,
        )
        if претензия.get("schema_version") != 5:
            return False
        журнал, объект_журнала = прочитать_журнал_завершений(контекст)
        if объект_журнала is None:
            return False
        совпадения = [
            событие
            for событие in журнал["события"]
            if isinstance(событие, dict)
            and событие.get("branch_ref") == контекст.branch_ref
            and событие.get("step_id") == претензия["step_id"]
            and событие.get("card_id") == претензия["card_id"]
            and событие.get("selection_head") == базовая_вершина
            and событие.get("завершивший_commit") == объект_коммита
            and событие.get("job_id") == "master.next-step"
            and событие.get("spec_generation")
            == резервация.get("spec_generation")
        ]
        родители = decoded_stdout(
            run_git(
                контекст.root,
                ["rev-list", "--parents", "-n", "1", объект_коммита],
            )
        ).split()
        цепочка = decoded_stdout(
            run_git(
                контекст.root,
                ["rev-list", "--first-parent", current_head(контекст.root)],
            )
        ).splitlines()
    except (QueueError, UnicodeError, ValueError):
        return False
    return (
        len(совпадения) == 1
        and родители == [объект_коммита, базовая_вершина]
        and объект_коммита in цепочка
    )


def устаревшая_схема_четыре_доказывает_текущее_завершение(
    контекст: QueueContext,
    завершение: dict[str, object],
) -> bool:
    идентификатор_задачи = str(завершение.get("task_id"))
    поколение = str(завершение.get("generation"))
    базовая_вершина = str(завершение.get("base_head"))
    объект_коммита = str(завершение.get("head"))
    try:
        найденная = найти_резервацию_завершаемого_шага(
            контекст,
            идентификатор_задачи,
            поколение,
            базовая_вершина,
        )
        if найденная is None:
            return False
        _, _, резервация = найденная
        _, _, претензия = прочитать_точную_претензию_завершаемого_шага(
            контекст,
            резервация,
            идентификатор_задачи,
            поколение,
            базовая_вершина,
        )
        if претензия.get("schema_version") != 4:
            return False
        получить_историческую_карточку_следующего_шага(
            контекст,
            претензия,
        )
        родители = decoded_stdout(
            run_git(
                контекст.root,
                ["rev-list", "--parents", "-n", "1", объект_коммита],
            )
        ).split()
    except (QueueError, UnicodeError, ValueError):
        return False
    return (
        current_head(контекст.root) == объект_коммита
        and родители == [объект_коммита, базовая_вершина]
    )


def потребовать_сохранность_незавершённого_автозапуска(
    контекст: QueueContext,
    состояние: dict[str, object],
    идентификатор_задачи: str,
    поколение: str,
) -> None:
    завершение = состояние.get("last_completion")
    if (
        not isinstance(завершение, dict)
        or завершение.get("kind") != "committed"
        or (
            завершение.get("task_id") == идентификатор_задачи
            and завершение.get("generation") == поколение
        )
    ):
        return
    прежняя_задача = завершение.get("task_id")
    прежнее_поколение = завершение.get("generation")
    if not isinstance(прежняя_задача, str) or not isinstance(
        прежнее_поколение, str
    ):
        return
    найденная = найти_резервацию_владельца(
        контекст,
        прежняя_задача,
        прежнее_поколение,
    )
    if найденная is None:
        return
    _, _, резервация = найденная
    if резервация.get("job_id") != "master.next-step":
        return
    доказано = False
    if резервация.get("фаза") == "завершён":
        try:
            долговечное = прочитать_долговечное_завершение_следующего_шага(
                контекст,
                прежняя_задача,
                прежнее_поколение,
            )
        except QueueError:
            долговечное = None
        доказано = долговечное == {
            "kind": "committed",
            "task_id": прежняя_задача,
            "generation": прежнее_поколение,
            "base_head": завершение.get("base_head"),
            "head": завершение.get("head"),
        }
    else:
        доказано = долговечный_журнал_доказывает_незавершённое_завершение(
            контекст,
            резервация,
            завершение,
        )
    if not доказано:
        raise QueueError(
            EXIT_CONTEXT,
            "legacy_terminalization_pending",
            "Прежний запуск следующего шага должен быть терминализирован до перезаписи last_completion.",
        )


def проверить_аналитическую_резервацию_для_передачи(
    резервация: dict[str, object],
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
) -> None:
    поля_3 = {
        "версия_схемы",
        "branch_ref",
        "selection_head",
        "идентификатор_реестра",
        "версия_схемы_реестра",
        "поколение_реестра",
        "хэш_реестра",
        "job_id",
        "spec_generation",
        "trigger_occurrence",
        "run_key",
        "идентификатор_попытки",
        "фаза",
        "исход",
        "идентификатор_созданной_задачи",
        "свидетельство_среды",
        "подтверждение_результата",
        "курсор_до",
        "task_id",
        "generation",
    }
    версия = резервация.get("версия_схемы")
    ожидаемые_поля = поля_3 if версия == 3 else поля_3 | {"возобновление"}
    свидетельство = резервация.get("свидетельство_среды")
    if (
        версия not in {3, 4}
        or set(резервация) != ожидаемые_поля
        or резервация.get("branch_ref") != контекст.branch_ref
        or резервация.get("selection_head") != базовая_вершина
        or резервация.get("job_id")
        != ИДЕНТИФИКАТОР_ЗАДАНИЯ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ
        or резервация.get("фаза") not in {"задача_создана", "завершён"}
        or резервация.get("идентификатор_созданной_задачи") != идентификатор_задачи
        or резервация.get("task_id") != идентификатор_задачи
        or резервация.get("generation") != поколение
        or type(резервация.get("spec_generation")) is not int
        or int(резервация["spec_generation"]) < 1
        or type(резервация.get("поколение_реестра")) is not int
        or int(резервация["поколение_реестра"]) < 1
        or type(резервация.get("версия_схемы_реестра")) is not int
        or int(резервация["версия_схемы_реестра"]) < 1
        or not isinstance(резервация.get("идентификатор_реестра"), str)
        or not резервация["идентификатор_реестра"]
        or not isinstance(резервация.get("хэш_реестра"), str)
        or re.fullmatch(
            r"sha256:[0-9a-f]{64}",
            str(резервация.get("хэш_реестра")),
        )
        is None
        or not isinstance(резервация.get("trigger_occurrence"), dict)
        or not isinstance(резервация.get("курсор_до"), dict)
        or not isinstance(резервация.get("run_key"), str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", str(резервация.get("run_key")))
        is None
        or not isinstance(свидетельство, dict)
        or set(свидетельство) != {"вид", "threadId", "hostId"}
        or свидетельство.get("вид") != "threadId"
        or свидетельство.get("threadId") != идентификатор_задачи
        or not isinstance(свидетельство.get("hostId"), str)
        or not свидетельство["hostId"]
        or (
            версия == 4
            and (
                not isinstance(резервация.get("возобновление"), dict)
                or резервация["возобновление"].get("состояние")
                != "подтверждено_исполнителем"
            )
        )
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_analytics_reservation",
            "Резервация аналитики не доказывает точный verified-запуск.",
        )
    if резервация["фаза"] == "задача_создана":
        if резервация.get("исход") is not None or резервация.get("подтверждение_результата") is not None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_analytics_reservation",
                "Незавершённая резервация аналитики преждевременно содержит результат.",
            )
    elif резервация.get("исход") != "успех" or not isinstance(
        резервация.get("подтверждение_результата"),
        str,
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_analytics_reservation",
            "Завершённая резервация аналитики не подтверждает успех.",
        )
    try:
        if str(uuid.UUID(str(резервация["идентификатор_попытки"]))) != резервация["идентификатор_попытки"]:
            raise ValueError
    except ValueError as ошибка:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_analytics_reservation",
            "Резервация аналитики имеет неверную попытку.",
        ) from ошибка


def подготовить_переход_передачи_аналитики(
    контекст: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    базовая_вершина: str,
    объект_коммита: str,
) -> ПереходПередачиАналитики | None:
    найденная = найти_резервацию_владельца(
        контекст,
        идентификатор_задачи,
        поколение,
    )
    if найденная is None:
        return None
    ссылка_резервации, объект_резервации, резервация = найденная
    if (
        резервация.get("job_id")
        != ИДЕНТИФИКАТОР_ЗАДАНИЯ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ
    ):
        return None
    проверить_аналитическую_резервацию_для_передачи(
        резервация,
        контекст,
        идентификатор_задачи,
        поколение,
        базовая_вершина,
    )
    ссылка_претензии = ссылка_аналитики_завершений(контекст)
    объект_претензии = read_ref_oid(контекст, ссылка_претензии)
    if объект_претензии is None:
        raise QueueError(
            EXIT_CONTEXT,
            "missing_analytics_claim",
            "Аналитический запуск не имеет exact specialized-претензии.",
        )
    претензия = прочитать_канонический_объект_данных(
        контекст,
        объект_претензии,
        состояние_ошибки="corrupt_analytics_claim",
        пояснение="Претензия аналитики повреждена.",
    )
    поля_претензии = {
        "схема",
        "branch_ref",
        "selection_head",
        "job_id",
        "spec_generation",
        "поколение_реестра",
        "trigger_occurrence",
        "run_key",
        "идентификатор_попытки",
        "lease_id",
        "порог",
        "диапазон_событий",
        "назначение",
        "путь_реестра",
        "путь_отчёта",
        "идентификатор_анализа",
        "фаза",
        "task_id",
        "generation",
        "свидетельство_передачи",
        "подтверждённый_результат",
    }
    диапазон = претензия.get("диапазон_событий")
    идентификатор_попытки = резервация["идентификатор_попытки"]
    if (
        set(претензия) != поля_претензии
        or претензия.get("схема")
        != СХЕМА_ПРЕТЕНЗИИ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ
        or претензия.get("branch_ref") != контекст.branch_ref
        or претензия.get("selection_head") != базовая_вершина
        or претензия.get("job_id") != резервация["job_id"]
        or претензия.get("spec_generation") != резервация["spec_generation"]
        or претензия.get("поколение_реестра") != резервация["поколение_реестра"]
        or претензия.get("trigger_occurrence") != резервация["trigger_occurrence"]
        or претензия.get("run_key") != резервация["run_key"]
        or претензия.get("идентификатор_попытки") != идентификатор_попытки
        or претензия.get("lease_id") != идентификатор_попытки
        or претензия.get("task_id") != идентификатор_задачи
        or претензия.get("generation") != поколение
        or type(претензия.get("порог")) is not int
        or int(претензия["порог"]) < 1
        or not isinstance(диапазон, dict)
        or set(диапазон) != {"начало", "конец", "идентификаторы_событий", "источники"}
        or диапазон.get("конец") != претензия["порог"]
        or not isinstance(диапазон.get("идентификаторы_событий"), list)
        or not isinstance(диапазон.get("источники"), list)
        or len(диапазон["идентификаторы_событий"]) != len(диапазон["источники"])
        or not isinstance(претензия.get("назначение"), str)
        or not претензия["назначение"]
        or not isinstance(претензия.get("путь_реестра"), str)
        or not претензия["путь_реестра"]
        or not isinstance(претензия.get("путь_отчёта"), str)
        or not претензия["путь_отчёта"]
        or not isinstance(претензия.get("идентификатор_анализа"), str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", str(претензия.get("идентификатор_анализа")))
        is None
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_analytics_claim",
            "Претензия аналитики не доказывает exact verified-запуск.",
        )
    начало = диапазон["начало"]
    конец = диапазон["конец"]
    идентификаторы = диапазон["идентификаторы_событий"]
    источники = диапазон["источники"]
    наступление = претензия["trigger_occurrence"]
    поля_события = {
        "номер",
        "идентификатор",
        "branch_ref",
        "step_id",
        "card_id",
        "selection_head",
        "завершивший_commit",
        "результат",
        "job_id",
        "spec_generation",
    }
    if (
        type(начало) is not int
        or type(конец) is not int
        or начало < 1
        or конец < начало
        or конец != претензия["порог"]
        or len(идентификаторы) != конец - начало + 1
        or any(
            not isinstance(идентификатор, str)
            or re.fullmatch(r"sha256:[0-9a-f]{64}", идентификатор) is None
            for идентификатор in идентификаторы
        )
        or any(
            not isinstance(источник, dict)
            or set(источник) != поля_события
            or источник.get("идентификатор") != идентификатор
            or источник.get("branch_ref") != контекст.branch_ref
            or источник.get("результат") != "commit+handoff"
            or источник.get("job_id") != "master.next-step"
            or type(источник.get("номер")) is not int
            or int(источник["номер"]) < 1
            or not isinstance(источник.get("step_id"), str)
            or re.fullmatch(r"[a-z0-9][a-z0-9._-]*", str(источник["step_id"]))
            is None
            or not isinstance(источник.get("card_id"), str)
            or re.fullmatch(r"FUM-STEP-[0-9]{4,}", str(источник["card_id"]))
            is None
            or источник.get("идентификатор")
            != идентификатор_события_завершения(источник)
            or type(источник.get("spec_generation")) is not int
            or int(источник["spec_generation"]) < 1
            for источник, идентификатор in zip(источники, идентификаторы)
        )
        or наступление
        != {
            "тип": "порог_подтверждённых_событий",
            "тип_события": "завершение_runtime_ready_commit_handoff",
            "начало": начало,
            "конец": конец,
        }
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_analytics_claim",
            "Замороженный диапазон аналитики нарушает exact-контракт.",
        )
    части_ветки = контекст.branch_ref.removeprefix("refs/heads/").split("/")
    ожидаемый_путь_отчёта = (
        Path("Оценки")
        .joinpath(
            "аналитика-завершённых-запусков",
            *части_ветки,
            ИДЕНТИФИКАТОР_ЗАДАНИЯ_АНАЛИТИКИ_ЗАВЕРШЕНИЙ,
            f"{начало:010d}-{конец:010d}.md",
        )
        .as_posix()
    )
    ожидаемое_назначение = (
        f"Проведи аналитическую ревизию конечного диапазона подтверждённых событий {начало}–{конец}. "
        "Назови наблюдаемую способность, терминальную приёмку, отрицательные результаты и стоимость пройденной цепочки. "
        "Сверь выводы с внешними критериями и проверяемыми источниками. "
        "Не считать число шагов, коммитов или документов доказательством улучшения."
    )
    вход_идентификатора = {
        "branch_ref": претензия["branch_ref"],
        "job_id": претензия["job_id"],
        "spec_generation": претензия["spec_generation"],
        "trigger_occurrence": наступление,
        "начало": начало,
        "конец": конец,
        "идентификаторы_событий": идентификаторы,
    }
    ожидаемый_идентификатор = "sha256:" + hashlib.sha256(
        json.dumps(
            вход_идентификатора,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
    ).hexdigest()
    путь_реестра = Path(str(претензия["путь_реестра"]))
    путь_отчёта = Path(str(претензия["путь_отчёта"]))
    if (
        not контекст.branch_ref.startswith("refs/heads/")
        or any(часть in {"", ".", ".."} for часть in части_ветки)
        or путь_реестра.is_absolute()
        or any(часть in {"", ".", ".."} for часть in путь_реестра.parts)
        or путь_отчёта.is_absolute()
        or any(часть in {"", ".", ".."} for часть in путь_отчёта.parts)
        or претензия["путь_отчёта"] != ожидаемый_путь_отчёта
        or претензия["назначение"] != ожидаемое_назначение
        or претензия["идентификатор_анализа"] != ожидаемый_идентификатор
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_analytics_claim",
            "Замороженные пути, назначение или идентификатор аналитики повреждены.",
        )
    свидетельство = {
        "base_head": базовая_вершина,
        "commit": объект_коммита,
        "task_id": идентификатор_задачи,
        "generation": поколение,
    }
    фаза = претензия.get("фаза")
    if фаза == "подтверждена":
        if (
            резервация["фаза"] != "задача_создана"
            or претензия.get("свидетельство_передачи") is not None
            or претензия.get("подтверждённый_результат") is not None
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_analytics_claim",
                "Подтверждённая претензия аналитики имеет преждевременный результат.",
            )
        новая_претензия = copy.deepcopy(претензия)
        новая_претензия["фаза"] = "передана"
        новая_претензия["свидетельство_передачи"] = свидетельство
        новый_объект = записать_канонический_объект_данных(
            контекст,
            новая_претензия,
        )
    elif фаза in {"передана", "завершена"}:
        if претензия.get("свидетельство_передачи") != свидетельство:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_analytics_claim",
                "Свидетельство передачи аналитики противоречит FIFO-коммиту.",
            )
        if фаза == "передана" and претензия.get("подтверждённый_результат") is not None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_analytics_claim",
                "Переданная претензия преждевременно содержит результат.",
            )
        if фаза == "завершена":
            результат = претензия.get("подтверждённый_результат")
            if (
                not isinstance(результат, dict)
                or set(результат)
                != {
                    "идентификатор",
                    "путь",
                    "content_sha256",
                    "конец_диапазона",
                    "commit",
                }
                or результат.get("идентификатор")
                != претензия["идентификатор_анализа"]
                or результат.get("путь") != претензия["путь_отчёта"]
                or результат.get("конец_диапазона") != конец
                or результат.get("commit") != объект_коммита
                or not isinstance(результат.get("content_sha256"), str)
                or re.fullmatch(
                    r"sha256:[0-9a-f]{64}",
                    str(результат.get("content_sha256")),
                )
                is None
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_analytics_claim",
                    "Завершённая претензия не совпадает со свидетельством передачи.",
                )
        новый_объект = объект_претензии
    else:
        raise QueueError(
            EXIT_CONTEXT,
            "unverified_analytics_claim",
            "Аналитическая претензия не достигла exact verify-run.",
        )
    return ПереходПередачиАналитики(
        ссылка_резервации=ссылка_резервации,
        объект_резервации=объект_резервации,
        ссылка_претензии=ссылка_претензии,
        прежний_объект_претензии=объект_претензии,
        новый_объект_претензии=новый_объект,
        свидетельство=свидетельство,
    )


def переход_передачи_аналитики_зафиксирован(
    контекст: QueueContext,
    переход: ПереходПередачиАналитики | None,
) -> bool:
    if переход is None:
        return True
    объект = read_ref_oid(контекст, переход.ссылка_претензии)
    if объект is None:
        return False
    претензия = прочитать_канонический_объект_данных(
        контекст,
        объект,
        состояние_ошибки="corrupt_analytics_claim",
        пояснение="Претензия аналитики повреждена.",
    )
    return (
        претензия.get("фаза") in {"передана", "завершена"}
        and претензия.get("свидетельство_передачи") == переход.свидетельство
    )


def команды_перехода_передачи_аналитики(
    переход: ПереходПередачиАналитики | None,
) -> str:
    if переход is None:
        return ""
    команды = (
        f"verify {переход.ссылка_резервации} {переход.объект_резервации}\n"
    )
    if переход.новый_объект_претензии == переход.прежний_объект_претензии:
        return (
            команды
            + f"verify {переход.ссылка_претензии} "
            + f"{переход.прежний_объект_претензии}\n"
        )
    return (
        команды
        + f"update {переход.ссылка_претензии} "
        + f"{переход.новый_объект_претензии} "
        + f"{переход.прежний_объект_претензии}\n"
    )


def atomic_commit_and_handoff(
    контекст_очереди: QueueContext,
    task_id: str,
    generation: str,
    message: str | None,
    идентификатор_продолжения: str | None = None,
) -> tuple[int, dict[str, object]] | None:
    task_id = validate_task_id(task_id)
    if идентификатор_продолжения is not None:
        идентификатор_продолжения = validate_task_id(
            идентификатор_продолжения
        )
    if not generation or "\0" in generation or "\n" in generation:
        raise QueueError(EXIT_CLI, "invalid_generation", "Некорректное поколение владельца.")

    ensure_live_branch(контекст_очереди)
    state, state_oid = read_state(контекст_очереди)
    state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
    сохранённая_квитанция = прочитать_квитанцию_связанного_коммита(
        контекст_очереди,
        task_id,
        generation,
    )
    if сохранённая_квитанция is not None:
        квитанция, объект_квитанции, ссылка_квитанции = сохранённая_квитанция
        потребовать_совпадение_продолжения(
            {"идентификатор_продолжения": квитанция["идентификатор_продолжения"]},
            идентификатор_продолжения,
        )
        return результат_квитанции_связанного_коммита(
            контекст_очереди,
            state_oid,
            квитанция,
            объект_квитанции,
            ссылка_квитанции,
        )
    if идентификатор_продолжения is None:
        долговечное_завершение = прочитать_долговечное_завершение_следующего_шага(
            контекст_очереди,
            task_id,
            generation,
        )
        if долговечное_завершение is not None:
            return committed_completion_result(
                контекст_очереди,
                state_oid,
                долговечное_завершение,
            )
    previous = matching_completion(
        state,
        kind="committed",
        task_id=task_id,
        generation=generation,
    )
    if previous is not None:
        потребовать_совпадение_продолжения(
            previous,
            идентификатор_продолжения,
        )
        if "идентификатор_продолжения" in previous:
            raise QueueError(
                EXIT_CONTEXT,
                "отсутствует_квитанция_связанного_коммита",
                "Связанное завершение не имеет неизменяемой Git-квитанции.",
            )
    if previous is not None and completion_head_is_current(контекст_очереди, previous):
        if устаревшая_схема_четыре_доказывает_текущее_завершение(
            контекст_очереди,
            previous,
        ):
            return committed_completion_result(
                контекст_очереди,
                state_oid,
                previous,
            )
        прежний_переход = подготовить_переход_журнала_завершений(
            контекст_очереди,
            task_id,
            generation,
            str(previous["base_head"]),
            str(previous["head"]),
        )
        if not переход_журнала_зафиксирован(
            контекст_очереди,
            прежний_переход,
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "missing_completion_event",
                "Завершённый точный запуск не имеет события журнала.",
            )
        прежний_переход_аналитики = подготовить_переход_передачи_аналитики(
            контекст_очереди,
            task_id,
            generation,
            str(previous["base_head"]),
            str(previous["head"]),
        )
        if not переход_передачи_аналитики_зафиксирован(
            контекст_очереди,
            прежний_переход_аналитики,
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "missing_analytics_handoff_witness",
                "Завершённый аналитический запуск не имеет свидетельства передачи.",
            )
        return committed_completion_result(контекст_очереди, state_oid, previous)
    owner = require_owner(контекст_очереди, state, task_id, generation)
    base_head = str(owner["base_head"])
    live_head = current_head(контекст_очереди.root)
    if live_head != base_head:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "HEAD изменился после допуска владельца.",
            данные_результата_операции={"expected_head": base_head, "current_head": live_head},
        )
    if (
        идентификатор_продолжения is None
        and обязательное_продолжение_активно(контекст_очереди, state)
    ):
        raise QueueError(
            EXIT_OWNERSHIP,
            "продолжение_обязательно",
            "Активный протокол запрещает коммит без точной задачи-продолжения.",
        )
    потребовать_ожидающее_продолжение(
        state,
        owner,
        идентификатор_продолжения,
    )
    if message is None:
        return None
    if not message.strip():
        raise QueueError(
            EXIT_CLI,
            "invalid_message",
            "Сообщение коммита не может быть пустым.",
        )
    if идентификатор_продолжения is None:
        потребовать_сохранность_незавершённого_автозапуска(
            контекст_очереди,
            state,
            task_id,
            generation,
        )

    blocking = unsafe_commit_paths(контекст_очереди.root)
    if blocking:
        raise QueueError(
            EXIT_DIRTY,
            "dirty",
            "Перед атомарным коммитом остаются unstaged, untracked или конфликтные пути.",
            данные_результата_операции={"blocking_paths": blocking},
        )
    if not staged_changes_exist(контекст_очереди.root):
        raise QueueError(
            EXIT_NOTHING_STAGED,
            "nothing_staged",
            "Для завершения задачи нет staged-изменений.",
        )

    tree = decoded_stdout(run_git(контекст_очереди.root, ["write-tree"]))
    parent_tree = decoded_stdout(
        run_git(контекст_очереди.root, ["rev-parse", f"{base_head}^{{tree}}"])
    )
    if tree == parent_tree:
        raise QueueError(
            EXIT_NOTHING_STAGED,
            "nothing_staged",
            "Staged-дерево совпадает с родительским коммитом.",
        )
    commit_message = message if message.endswith("\n") else f"{message}\n"
    commit_oid = decoded_stdout(
        run_git(
            контекст_очереди.root,
            ["commit-tree", tree, "-p", base_head],
            input_bytes=commit_message.encode("utf-8"),
        )
    )
    квитанция_связанного_коммита: dict[str, object] | None = None
    объект_квитанции_связанного_коммита: str | None = None
    целевая_ссылка_квитанции_связанного_коммита: str | None = None
    if идентификатор_продолжения is not None:
        квитанция_связанного_коммита = данные_квитанции_связанного_коммита(
            контекст_очереди,
            task_id,
            generation,
            base_head,
            commit_oid,
            идентификатор_продолжения,
        )
        проверить_квитанцию_связанного_коммита(
            контекст_очереди,
            квитанция_связанного_коммита,
            task_id,
            generation,
            требовать_достижимость=False,
        )
        объект_квитанции_связанного_коммита = записать_канонический_объект_данных(
            контекст_очереди,
            квитанция_связанного_коммита,
        )
        целевая_ссылка_квитанции_связанного_коммита = ссылка_квитанции_связанного_коммита(
            контекст_очереди,
            task_id,
            generation,
        )

    unchanged_ref_failures = 0
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(контекст_очереди)
        live_head = current_head(контекст_очереди.root)
        if live_head != base_head:
            latest_state, latest_oid = read_state(контекст_очереди)
            if идентификатор_продолжения is not None:
                записанная_квитанция = прочитать_квитанцию_связанного_коммита(
                    контекст_очереди,
                    task_id,
                    generation,
                )
                if записанная_квитанция is not None:
                    квитанция, объект_квитанции, ссылка_квитанции = записанная_квитанция
                    потребовать_совпадение_продолжения(
                        {"идентификатор_продолжения": квитанция["идентификатор_продолжения"]},
                        идентификатор_продолжения,
                    )
                    return результат_квитанции_связанного_коммита(
                        контекст_очереди,
                        latest_oid,
                        квитанция,
                        объект_квитанции,
                        ссылка_квитанции,
                    )
            if идентификатор_продолжения is None:
                completion = matching_completion(
                    latest_state,
                    kind="committed",
                    task_id=task_id,
                    generation=generation,
                )
                if live_head == commit_oid and completion is not None:
                    потребовать_совпадение_продолжения(
                        completion,
                        идентификатор_продолжения,
                    )
                    переход = подготовить_переход_журнала_завершений(
                        контекст_очереди,
                        task_id,
                        generation,
                        base_head,
                        commit_oid,
                    )
                    if переход_журнала_зафиксирован(
                        контекст_очереди,
                        переход,
                    ):
                        переход_аналитики = подготовить_переход_передачи_аналитики(
                            контекст_очереди,
                            task_id,
                            generation,
                            base_head,
                            commit_oid,
                        )
                        if not переход_передачи_аналитики_зафиксирован(
                            контекст_очереди,
                            переход_аналитики,
                        ):
                            raise QueueError(
                                EXIT_CONTEXT,
                                "missing_analytics_handoff_witness",
                                "Аналитическая передача не имеет durable witness.",
                            )
                        return committed_completion_result(
                            контекст_очереди,
                            latest_oid,
                            completion,
                        )
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился до атомарной передачи очереди.",
                данные_результата_операции={"expected_head": base_head, "current_head": live_head},
            )

        latest, old_queue_oid = read_state(контекст_очереди)
        текущий_владелец = require_owner(
            контекст_очереди,
            latest,
            task_id,
            generation,
        )
        потребовать_ожидающее_продолжение(
            latest,
            текущий_владелец,
            идентификатор_продолжения,
        )
        if (
            идентификатор_продолжения is None
            and обязательное_продолжение_активно(контекст_очереди, latest)
        ):
            raise QueueError(
                EXIT_OWNERSHIP,
                "продолжение_обязательно",
                "Активный протокол запрещает коммит без точной задачи-продолжения.",
            )
        if old_queue_oid is None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "У владельца отсутствует Git-ссылка состояния очереди.",
            )
        stamp, _ = utc_values()
        completion = {
            "kind": "committed",
            "task_id": task_id,
            "generation": generation,
            "base_head": base_head,
            "head": commit_oid,
            "completed_at": stamp,
        }
        if идентификатор_продолжения is not None:
            completion["идентификатор_продолжения"] = (
                идентификатор_продолжения
            )
        updated = copy.deepcopy(latest)
        updated["owner"] = None
        updated["last_completion"] = completion
        updated["updated_at"] = stamp
        if идентификатор_продолжения is not None:
            updated[ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ] = True
        new_queue_oid = write_state_blob(контекст_очереди, updated)
        if идентификатор_продолжения is None:
            переход_журнала = подготовить_переход_журнала_завершений(
                контекст_очереди,
                task_id,
                generation,
                base_head,
                commit_oid,
            )
            команды_журнала = команды_перехода_журнала(переход_журнала)
            переход_аналитики = подготовить_переход_передачи_аналитики(
                контекст_очереди,
                task_id,
                generation,
                base_head,
                commit_oid,
            )
            команды_аналитики = команды_перехода_передачи_аналитики(
                переход_аналитики,
            )
        else:
            переход_журнала = None
            команды_журнала = ""
            переход_аналитики = None
            команды_аналитики = ""
        команда_квитанции = ""
        if (
            целевая_ссылка_квитанции_связанного_коммита is not None
            and объект_квитанции_связанного_коммита is not None
        ):
            команда_квитанции = (
                f"create {целевая_ссылка_квитанции_связанного_коммита} "
                f"{объект_квитанции_связанного_коммита}\n"
            )
        transaction = (
            "start\n"
            f"{команда_квитанции}"
            f"{команды_журнала}"
            f"{команды_аналитики}"
            f"update {контекст_очереди.branch_ref} {commit_oid} {base_head}\n"
            f"update {контекст_очереди.queue_ref} {new_queue_oid} {old_queue_oid}\n"
            "prepare\n"
            "commit\n"
        ).encode("utf-8")
        result = run_git(
            контекст_очереди.root,
            ["update-ref", "--stdin"],
            input_bytes=transaction,
            check=False,
        )
        if result.returncode == 0:
            if (
                квитанция_связанного_коммита is not None
                and объект_квитанции_связанного_коммита is not None
                and целевая_ссылка_квитанции_связанного_коммита is not None
            ):
                return результат_квитанции_связанного_коммита(
                    контекст_очереди,
                    new_queue_oid,
                    квитанция_связанного_коммита,
                    объект_квитанции_связанного_коммита,
                    целевая_ссылка_квитанции_связанного_коммита,
                )
            ответ = {
                "state": "committed",
                "task_id": task_id,
                "ticket_id": owner["ticket_id"],
                "seq": owner["seq"],
                "generation": generation,
                "old_head": base_head,
                "new_head": commit_oid,
                **common_payload(контекст_очереди, new_queue_oid),
            }
            return 0, ответ
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        observed_head = current_head(контекст_очереди.root)
        observed_state, observed_queue_oid = read_state(контекст_очереди)
        if идентификатор_продолжения is not None:
            записанная_квитанция = прочитать_квитанцию_связанного_коммита(
                контекст_очереди,
                task_id,
                generation,
            )
            if записанная_квитанция is not None:
                квитанция, объект_квитанции, ссылка_квитанции = записанная_квитанция
                потребовать_совпадение_продолжения(
                    {"идентификатор_продолжения": квитанция["идентификатор_продолжения"]},
                    идентификатор_продолжения,
                )
                return результат_квитанции_связанного_коммита(
                    контекст_очереди,
                    observed_queue_oid,
                    квитанция,
                    объект_квитанции,
                    ссылка_квитанции,
                )
        observed_completion = matching_completion(
            observed_state,
            kind="committed",
            task_id=task_id,
            generation=generation,
        )
        if (
            идентификатор_продолжения is None
            and observed_head == commit_oid
            and observed_completion is not None
            and переход_журнала_зафиксирован(
                контекст_очереди,
                переход_журнала,
            )
            and переход_передачи_аналитики_зафиксирован(
                контекст_очереди,
                переход_аналитики,
            )
        ):
            потребовать_совпадение_продолжения(
                observed_completion,
                идентификатор_продолжения,
            )
            return committed_completion_result(
                контекст_очереди,
                observed_queue_oid,
                observed_completion,
            )
        if observed_head != base_head:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился во время атомарной передачи очереди.",
                данные_результата_операции={"expected_head": base_head, "current_head": observed_head},
            )
        if observed_queue_oid != old_queue_oid:
            unchanged_ref_failures = 0
            time.sleep(REF_RETRY_BASE_SECONDS)
            continue
        if переход_журнала is not None and (
            read_ref_oid(
                контекст_очереди,
                переход_журнала.ссылка,
            )
            != переход_журнала.прежний_объект
        ):
            unchanged_ref_failures = 0
            time.sleep(REF_RETRY_BASE_SECONDS)
            continue
        if переход_аналитики is not None and (
            read_ref_oid(
                контекст_очереди,
                переход_аналитики.ссылка_резервации,
            )
            != переход_аналитики.объект_резервации
            or read_ref_oid(
                контекст_очереди,
                переход_аналитики.ссылка_претензии,
            )
            != переход_аналитики.прежний_объект_претензии
        ):
            unchanged_ref_failures = 0
            time.sleep(REF_RETRY_BASE_SECONDS)
            continue
        unchanged_ref_failures += 1
        if unchanged_ref_failures >= UNCHANGED_REF_RETRY_ATTEMPTS:
            update_ref_error(
                "атомарно обновить Git-ветку и очередь",
                last_stderr,
            )
        time.sleep(ref_retry_delay(unchanged_ref_failures - 1))
    raise QueueError(
        EXIT_CAS,
        "cas_conflict",
        "Не удалось атомарно обновить ветку и очередь из-за непрерывных конкурирующих изменений.",
    )


def ссылка_квитанции_принятой_интеграции(
    контекст_очереди: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> str:
    идентичность = {
        "идентификатор_рабочего_дерева": контекст_очереди.worktree_id,
        "ссылка_ветки": контекст_очереди.branch_ref,
        "идентификатор_задачи": идентификатор_задачи,
        "поколение": поколение,
    }
    отпечаток = hashlib.sha256(canonical_state_bytes(идентичность)).hexdigest()
    return (
        f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_ПРИНЯТЫХ_ИНТЕГРАЦИЙ}/"
        f"{контекст_очереди.worktree_id}/{отпечаток}"
    )


def проверить_объект_пула(
    контекст_очереди: QueueContext,
    идентификатор_объекта: str,
) -> str:
    длина = len(current_head(контекст_очереди.root))
    if re.fullmatch(rf"[0-9a-f]{{{длина}}}", идентификатор_объекта) is None:
        raise QueueError(EXIT_CLI, "invalid_pool_oid", "OID состояния пула имеет неверный формат.")
    вид = run_git(
        контекст_очереди.root,
        ["cat-file", "-t", идентификатор_объекта],
        check=False,
    )
    if вид.returncode != 0 or decoded_stdout(вид) != "blob":
        raise QueueError(EXIT_CLI, "invalid_pool_oid", "Состояние пула не является Git blob.")
    return идентификатор_объекта


def хэш_канонического_объекта_пула(значение: dict[str, object]) -> str:
    return "sha256:" + hashlib.sha256(canonical_state_bytes(значение)).hexdigest()


def прочитать_канонический_пул(
    контекст_очереди: QueueContext,
    идентификатор_объекта: str,
) -> dict[str, object]:
    данные = run_git(
        контекст_очереди.root,
        ["cat-file", "blob", идентификатор_объекта],
    ).stdout
    try:
        состояние = json.loads(данные)
    except (UnicodeDecodeError, json.JSONDecodeError) as ошибка:
        raise QueueError(EXIT_CONTEXT, "invalid_pool_state", "Состояние пула повреждено.") from ошибка
    if not isinstance(состояние, dict) or canonical_state_bytes(состояние) != данные:
        raise QueueError(EXIT_CONTEXT, "invalid_pool_state", "Состояние пула неканонично.")
    return состояние


def ожидаемая_ссылка_пула(контекст_очереди: QueueContext) -> tuple[str, str]:
    общий_текст = decoded_stdout(
        run_git(контекст_очереди.root, ["rev-parse", "--git-common-dir"])
    )
    общий = Path(общий_текст)
    if not общий.is_absolute():
        общий = контекст_очереди.root / общий
    идентификатор = hashlib.sha256(
        os.path.normcase(str(общий.resolve())).encode("utf-8")
    ).hexdigest()
    return f"refs/fum/worktree-subnode-pools/{идентификатор}", идентификатор


def найти_назначение_пула_по_хэшу(
    пул: dict[str, object],
    хэш_назначения: object,
) -> dict[str, object]:
    назначения = пул.get("assignments")
    совпадения = (
        [значение for значение in назначения.values() if isinstance(значение, dict) and значение.get("assignment_hash") == хэш_назначения]
        if isinstance(назначения, dict)
        else []
    )
    if len(совпадения) != 1:
        raise QueueError(EXIT_CONTEXT, "commit_intent_assignment_mismatch", "Доказательство коммита не связано с одним assignment.")
    return совпадения[0]


def проверить_объект_по_намерению_пула(
    контекст_очереди: QueueContext,
    назначение: dict[str, object],
    хэш_намерения: object,
    ожидаемый_вид: str,
    идентификатор_коммита: object,
) -> dict[str, object]:
    намерения = назначение.get("намерения_коммитов")
    if not isinstance(намерения, dict) or not isinstance(хэш_намерения, str):
        raise QueueError(EXIT_CONTEXT, "commit_intent_missing", "Квитанция потеряла реестр commit intent.")
    совпадения = [
        (ключ, значение)
        for ключ, значение in намерения.items()
        if isinstance(ключ, str)
        and isinstance(значение, dict)
        and хэш_канонического_объекта_пула(значение) == хэш_намерения
    ]
    поля = {
        "schema", "ключ_операции", "вид", "assignment_hash", "task_id",
        "поколение_владения", "branch_ref", "хэш_продолжения", "индекс_результата",
        "родители", "tree_oid", "хэш_сообщения", "имя_автора", "email_автора",
        "дата_автора", "имя_коммитера", "email_коммитера", "дата_коммитера",
    }
    if len(совпадения) != 1:
        raise QueueError(EXIT_CONTEXT, "commit_intent_missing", "Хэш commit intent не найден однозначно.")
    ключ_реестра, намерение = совпадения[0]
    ожидаемый_ключ = хэш_канонического_объекта_пула(
        {
            "schema": "fum.ключ-операции-коммита-worktree-подузла.1",
            "assignment_hash": намерение.get("assignment_hash"),
            "вид": намерение.get("вид"),
            "хэш_продолжения": намерение.get("хэш_продолжения"),
            "индекс_результата": намерение.get("индекс_результата"),
        }
    )
    дата_автора = намерение.get("дата_автора")
    родители = намерение.get("родители")
    хэш_продолжения = намерение.get("хэш_продолжения")
    индекс_результата = намерение.get("индекс_результата")
    допустимая_операция = (
        ожидаемый_вид == "результат"
        and хэш_продолжения is None
        and индекс_результата is None
        and isinstance(родители, list)
        and len(родители) == 1
    ) or (
        ожидаемый_вид == "передача_линии"
        and isinstance(хэш_продолжения, str)
        and bool(хэш_продолжения)
        and индекс_результата is None
        and isinstance(родители, list)
        and len(родители) == 1
    ) or (
        ожидаемый_вид == "интеграционное_слияние"
        and хэш_продолжения is None
        and isinstance(индекс_результата, int)
        and not isinstance(индекс_результата, bool)
        and индекс_результата >= 0
        and isinstance(родители, list)
        and len(родители) == 2
    )
    длина_идентификатора_объекта = len(current_head(контекст_очереди.root))
    if (
        set(намерение) != поля
        or намерение.get("schema") != "fum.намерение-коммита-worktree-подузла.1"
        or ключ_реестра != ожидаемый_ключ
        or намерение.get("ключ_операции") != ожидаемый_ключ
        or намерение.get("вид") != ожидаемый_вид
        or not допустимая_операция
        or намерение.get("assignment_hash") != назначение.get("assignment_hash")
        or намерение.get("branch_ref") != назначение.get("branch_ref")
        or any(
            not isinstance(намерение.get(поле), str) or not намерение[поле]
            for поле in ("assignment_hash", "task_id", "поколение_владения", "branch_ref")
        )
        or any(
            not isinstance(родитель, str)
            or re.fullmatch(rf"[0-9a-f]{{{длина_идентификатора_объекта}}}", родитель) is None
            for родитель in намерение["родители"]
        )
        or not isinstance(намерение.get("tree_oid"), str)
        or re.fullmatch(rf"[0-9a-f]{{{длина_идентификатора_объекта}}}", намерение["tree_oid"]) is None
        or not isinstance(намерение.get("хэш_сообщения"), str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", намерение["хэш_сообщения"]) is None
        or not isinstance(дата_автора, str)
        or re.fullmatch(r"[0-9]+ \+0000", дата_автора) is None
        or дата_автора != намерение.get("дата_коммитера")
        or int(дата_автора.split()[0]) <= 946684800
        or any(
            not isinstance(намерение.get(поле), str)
            or not намерение[поле]
            or any(знак in намерение[поле] for знак in ("\x00", "\n", "\r", "<", ">"))
            for поле in ("имя_автора", "email_автора", "имя_коммитера", "email_коммитера")
        )
        or not isinstance(идентификатор_коммита, str)
        or re.fullmatch(rf"[0-9a-f]{{{длина_идентификатора_объекта}}}", идентификатор_коммита) is None
    ):
        raise QueueError(EXIT_CONTEXT, "invalid_commit_intent", "Commit intent не прошёл закрытую схему bridge.")
    объект = run_git(
        контекст_очереди.root,
        ["cat-file", "commit", идентификатор_коммита],
        check=False,
    )
    if объект.returncode != 0:
        raise QueueError(EXIT_CONTEXT, "commit_intent_object_missing", "Объект commit intent недоступен.")
    _, разделитель, сообщение = объект.stdout.partition(b"\n\n")
    if разделитель != b"\n\n" or "sha256:" + hashlib.sha256(сообщение).hexdigest() != намерение.get("хэш_сообщения"):
        raise QueueError(EXIT_CONTEXT, "commit_intent_object_mismatch", "Сообщение коммита не совпало с intent.")
    заголовки = [f"tree {намерение['tree_oid']}"]
    заголовки.extend(f"parent {родитель}" for родитель in намерение["родители"])
    заголовки.extend(
        [
            f"author {намерение['имя_автора']} <{намерение['email_автора']}> {намерение['дата_автора']}",
            f"committer {намерение['имя_коммитера']} <{намерение['email_коммитера']}> {намерение['дата_коммитера']}",
        ]
    )
    ожидаемые_байты = "\n".join(заголовки).encode("utf-8") + b"\n\n" + сообщение
    if объект.stdout != ожидаемые_байты:
        raise QueueError(EXIT_CONTEXT, "commit_intent_object_mismatch", "Commit содержит байты вне exact intent.")
    return намерение


def проверить_доказательство_результата_пула(
    контекст_очереди: QueueContext,
    пул: dict[str, object],
    результат: dict[str, object],
) -> None:
    назначение = найти_назначение_пула_по_хэшу(пул, результат.get("assignment_hash"))
    намерения = назначение.get("намерения_коммитов")
    есть_новое_намерение_результата = isinstance(намерения, dict) and any(
        isinstance(намерение, dict) and намерение.get("вид") == "результат"
        for намерение in намерения.values()
    )
    хэш_намерения = результат.get("хэш_намерения_коммита")
    схема = результат.get("schema")
    if схема == ПРЕЖНЯЯ_СХЕМА_КВИТАНЦИИ_РЕЗУЛЬТАТА_ПОДУЗЛА:
        if хэш_намерения is not None or есть_новое_намерение_результата:
            raise QueueError(EXIT_CONTEXT, "result_commit_intent_downgrade", "Legacy result смешан с новым commit intent.")
        return
    if схема != СХЕМА_КВИТАНЦИИ_РЕЗУЛЬТАТА_ПОДУЗЛА or хэш_намерения is None:
        raise QueueError(EXIT_CONTEXT, "result_commit_intent_missing", "Новый result потерял exact commit intent.")
    намерение = проверить_объект_по_намерению_пула(
        контекст_очереди,
        назначение,
        хэш_намерения,
        "результат",
        результат.get("head_oid"),
    )
    коммиты = результат.get("commits")
    if (
        намерение.get("task_id") != результат.get("task_id")
        or намерение.get("tree_oid") != результат.get("tree_oid")
        or намерение.get("хэш_сообщения") != результат.get("хэш_сообщения")
        or not isinstance(коммиты, list)
        or not коммиты
        or коммиты[-1] != результат.get("head_oid")
    ):
        raise QueueError(EXIT_CONTEXT, "result_commit_intent_mismatch", "Result receipt не совпал с exact intent.")
    предыдущая_вершина = результат.get("base_oid")
    if not isinstance(предыдущая_вершина, str):
        raise QueueError(EXIT_CONTEXT, "result_commit_intent_mismatch", "Result потерял исходную вершину.")
    for промежуточный_коммит in коммиты[:-1]:
        совпадения_намерений_передачи = [
            промежуточное_намерение
            for промежуточное_намерение in намерения.values()
            if isinstance(промежуточное_намерение, dict)
            and промежуточное_намерение.get("вид") == "передача_линии"
            and промежуточное_намерение.get("родители") == [предыдущая_вершина]
        ]
        if len(совпадения_намерений_передачи) != 1:
            raise QueueError(
                EXIT_CONTEXT,
                "result_commit_intent_chain_mismatch",
                "Линейный диапазон result потерял exact handoff intent.",
            )
        намерение_коммита_передачи = совпадения_намерений_передачи[0]
        проверить_объект_по_намерению_пула(
            контекст_очереди,
            назначение,
            хэш_канонического_объекта_пула(намерение_коммита_передачи),
            "передача_линии",
            промежуточный_коммит,
        )
        предыдущая_вершина = промежуточный_коммит
    if намерение.get("родители") != [предыдущая_вершина]:
        raise QueueError(
            EXIT_CONTEXT,
            "result_commit_intent_chain_mismatch",
            "Terminal result intent не продолжает exact handoff-цепочку.",
        )


def проверить_доказательство_кандидата_пула(
    контекст_очереди: QueueContext,
    пул: dict[str, object],
    кандидат: dict[str, object],
) -> None:
    назначение = найти_назначение_пула_по_хэшу(пул, кандидат.get("integrator_assignment_hash"))
    хэши = кандидат.get("хэши_намерений_коммитов")
    записи = кандидат.get("интеграционные_коммиты")
    намерения = назначение.get("намерения_коммитов")
    есть_новые_намерения_слияния = isinstance(намерения, dict) and any(
        isinstance(намерение, dict) and намерение.get("вид") == "интеграционное_слияние"
        for намерение in намерения.values()
    )
    схема = кандидат.get("schema")
    if схема == ПРЕЖНЯЯ_СХЕМА_КВИТАНЦИИ_ИНТЕГРАЦИОННОГО_КАНДИДАТА_ПОДУЗЛОВ:
        if хэши is not None or записи is not None or есть_новые_намерения_слияния:
            raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_downgrade", "Legacy candidate смешан с новыми commit intent.")
        return
    if схема != СХЕМА_КВИТАНЦИИ_ИНТЕГРАЦИОННОГО_КАНДИДАТА_ПОДУЗЛОВ:
        raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_missing", "Новый кандидат имеет неизвестную схему.")
    if not isinstance(хэши, list) or not isinstance(записи, list) or len(хэши) != len(записи):
        raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_mismatch", "Кандидат потерял цепочку commit intent.")
    результаты = кандидат.get("result_hashes")
    головы = кандидат.get("result_heads")
    if (
        not isinstance(результаты, list)
        or not isinstance(головы, list)
        or len(результаты) != len(головы)
    ):
        raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_mismatch", "Кандидат потерял результаты.")
    предыдущая_вершина = кандидат.get("base_oid")
    предыдущий_индекс = -1
    for позиция, запись in enumerate(записи):
        if not isinstance(запись, dict) or set(запись) != {
            "индекс_результата", "хэш_результата", "commit_oid",
            "хэш_намерения_коммита", "конфликт_разрешён",
        }:
            raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_mismatch", "Запись коммита кандидата повреждена.")
        индекс = запись["индекс_результата"]
        if (
            not isinstance(индекс, int)
            or индекс <= предыдущий_индекс
            or индекс < 0
            or индекс >= len(результаты)
            or индекс >= len(головы)
            or результаты[индекс] != запись["хэш_результата"]
            or хэши[позиция] != запись["хэш_намерения_коммита"]
        ):
            raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_mismatch", "Порядок intent кандидата повреждён.")
        намерение = проверить_объект_по_намерению_пула(
            контекст_очереди,
            назначение,
            запись["хэш_намерения_коммита"],
            "интеграционное_слияние",
            запись["commit_oid"],
        )
        if (
            намерение.get("индекс_результата") != индекс
            or намерение.get("родители") != [предыдущая_вершина, головы[индекс]]
            or намерение.get("хэш_сообщения")
            != "sha256:"
            + hashlib.sha256(
                (
                    f"Разрешить конфликт результата {запись['хэш_результата']}\n"
                    if запись["конфликт_разрешён"]
                    else f"Интегрировать результат {запись['хэш_результата']}\n"
                ).encode("utf-8")
            ).hexdigest()
        ):
            raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_mismatch", "Intent не продолжает цепочку кандидата.")
        предыдущая_вершина = запись["commit_oid"]
        предыдущий_индекс = индекс
    if (
        предыдущая_вершина != кандидат.get("head_oid")
        or bool(any(запись["конфликт_разрешён"] for запись in записи))
        != bool(кандидат.get("conflict_resolved"))
    ):
        raise QueueError(EXIT_CONTEXT, "candidate_commit_intent_mismatch", "Вершина кандидата не совпала с цепочкой intent.")
    for голова_результата in головы:
        if run_git(
            контекст_очереди.root,
            ["merge-base", "--is-ancestor", голова_результата, кандидат["head_oid"]],
            check=False,
        ).returncode != 0:
            raise QueueError(
                EXIT_CONTEXT,
                "candidate_commit_intent_mismatch",
                "Кандидат не содержит заявленный result head.",
            )


def проверить_предслиянийный_барьер_дат_пула(
    пул: dict[str, object],
    кандидат: dict[str, object],
) -> None:
    хэши_результатов = кандидат.get("result_hashes")
    результаты = пул.get("results")
    if (
        кандидат.get("schema") != СХЕМА_КВИТАНЦИИ_ИНТЕГРАЦИОННОГО_КАНДИДАТА_ПОДУЗЛОВ
        or not isinstance(хэши_результатов, list)
        or not хэши_результатов
        or not isinstance(результаты, dict)
        or any(
            not isinstance(результаты.get(хэш), dict)
            or результаты[хэш].get("schema") != СХЕМА_КВИТАНЦИИ_РЕЗУЛЬТАТА_ПОДУЗЛА
            for хэш in хэши_результатов
        )
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "integration_commit_date_policy_required",
            "Перед merge каждый candidate и result обязан пройти новую политику долговечного времени коммита.",
        )


def проверить_переход_пула_интеграции(
    контекст_очереди: QueueContext,
    исходный_объект: str,
    новый_объект: str,
    хэш_интеграции: str,
    идентификатор_задачи: str,
    поколение: str,
    идентификатор_продолжения: str,
    исходная_вершина: str,
    новая_вершина: str,
) -> None:
    исходное = прочитать_канонический_пул(контекст_очереди, исходный_объект)
    новое = прочитать_канонический_пул(контекст_очереди, новый_объект)
    поля = {
        "schema", "repository_identity", "primary_root", "revision", "next_slot",
        "slots", "assignments", "activations", "results", "reviews",
        "integration_candidates", "integrations", "publications", "session_routes",
    }
    _, идентификатор_репозитория = ожидаемая_ссылка_пула(контекст_очереди)
    if any(
        set(состояние) != поля
        or состояние.get("schema") != СХЕМА_ПУЛА_РАБОЧИХ_ДЕРЕВЬЕВ_ПОДУЗЛОВ
        or состояние.get("repository_identity") != идентификатор_репозитория
        or состояние.get("primary_root") != str(контекст_очереди.root)
        or not isinstance(состояние.get("revision"), int)
        for состояние in (исходное, новое)
    ) or новое["revision"] != исходное["revision"] + 1:
        raise QueueError(EXIT_CONTEXT, "invalid_pool_transition", "Переход пула не прошёл закрытую схему.")
    for поле in поля - {"revision", "integration_candidates", "integrations", "publications"}:
        if исходное[поле] != новое[поле]:
            raise QueueError(EXIT_CONTEXT, "invalid_pool_transition", "Переход изменил постороннее поле пула.")

    исходные_интеграции = исходное["integrations"]
    новые_интеграции = новое["integrations"]
    if not isinstance(исходные_интеграции, dict) or not isinstance(новые_интеграции, dict):
        raise QueueError(EXIT_CONTEXT, "invalid_pool_transition", "Реестр интеграций повреждён.")
    ожидаемые_интеграции = copy.deepcopy(исходные_интеграции)
    квитанция = новые_интеграции.get(хэш_интеграции)
    поля_квитанции = {
        "schema", "integration_candidate_hash", "review_hash", "task_id", "generation",
        "continuation_task_id", "target_ref", "remote", "base_oid", "head_oid",
        "result_hashes", "result_heads",
    }
    if (
        not isinstance(квитанция, dict)
        or set(квитанция) != поля_квитанции
        or квитанция.get("schema") != СХЕМА_КВИТАНЦИИ_СРАВНЕНИЯ_И_ЗАМЕНЫ_ИНТЕГРАЦИИ_ПОДУЗЛОВ
        or хэш_канонического_объекта_пула(квитанция) != хэш_интеграции
        or квитанция.get("task_id") != идентификатор_задачи
        or квитанция.get("generation") != поколение
        or квитанция.get("continuation_task_id") != идентификатор_продолжения
        or квитанция.get("target_ref") != контекст_очереди.branch_ref
        or квитанция.get("base_oid") != исходная_вершина
        or квитанция.get("head_oid") != новая_вершина
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "integration_pool_receipt_mismatch",
            "Новое состояние пула не содержит exact квитанцию интеграции.",
        )
    if хэш_интеграции in исходные_интеграции:
        raise QueueError(EXIT_CONTEXT, "invalid_pool_transition", "Квитанция интеграции уже была в исходном пуле.")
    ожидаемые_интеграции[хэш_интеграции] = квитанция
    if ожидаемые_интеграции != новые_интеграции:
        raise QueueError(EXIT_CONTEXT, "invalid_pool_transition", "Реестр интеграций изменён неточно.")

    хэш_кандидата = квитанция["integration_candidate_hash"]
    исходный_кандидат = исходное["integration_candidates"].get(хэш_кандидата)
    новый_кандидат = новое["integration_candidates"].get(хэш_кандидата)
    основные_поля_кандидата = {
        "schema", "integrator_assignment_id", "integrator_assignment_hash", "task_id",
        "host_id", "branch_ref", "target_ref", "remote", "base_oid", "head_oid",
        "commits", "result_hashes", "review_hashes", "result_heads", "conflict_resolved",
    }
    схема_кандидата = исходный_кандидат.get("schema") if isinstance(исходный_кандидат, dict) else None
    поля_кандидата_допустимы = (
        схема_кандидата == ПРЕЖНЯЯ_СХЕМА_КВИТАНЦИИ_ИНТЕГРАЦИОННОГО_КАНДИДАТА_ПОДУЗЛОВ
        and set(исходный_кандидат) == основные_поля_кандидата
    ) or (
        схема_кандидата == СХЕМА_КВИТАНЦИИ_ИНТЕГРАЦИОННОГО_КАНДИДАТА_ПОДУЗЛОВ
        and set(исходный_кандидат)
        == основные_поля_кандидата | {"хэши_намерений_коммитов", "интеграционные_коммиты"}
    )
    if (
        not isinstance(исходный_кандидат, dict)
        or хэш_канонического_объекта_пула(исходный_кандидат) != хэш_кандидата
        or not поля_кандидата_допустимы
        or исходный_кандидат.get("target_ref") != квитанция["target_ref"]
        or исходный_кандидат.get("base_oid") != квитанция["base_oid"]
        or исходный_кандидат.get("head_oid") != квитанция["head_oid"]
        or исходный_кандидат.get("remote") != квитанция["remote"]
        or исходный_кандидат.get("result_hashes") != квитанция["result_hashes"]
        or исходный_кандидат.get("result_heads") != квитанция["result_heads"]
        or not isinstance(новый_кандидат, dict)
    ):
        raise QueueError(EXIT_CONTEXT, "integration_candidate_mismatch", "Квитанция не связана с exact кандидатом.")
    проверить_предслиянийный_барьер_дат_пула(исходное, исходный_кандидат)
    проверить_доказательство_кандидата_пула(
        контекст_очереди,
        исходное,
        исходный_кандидат,
    )
    ожидаемый_кандидат = copy.deepcopy(исходный_кандидат)
    ожидаемый_кандидат["integration_hash"] = хэш_интеграции
    ожидаемые_кандидаты = copy.deepcopy(исходное["integration_candidates"])
    ожидаемые_кандидаты[хэш_кандидата] = ожидаемый_кандидат
    if новое["integration_candidates"] != ожидаемые_кандидаты or новый_кандидат != ожидаемый_кандидат:
        raise QueueError(EXIT_CONTEXT, "integration_candidate_mismatch", "Кандидат изменён помимо exact хэша интеграции.")

    поля_ревью = {
        "schema", "reviewer_assignment_id", "reviewer_assignment_hash", "task_id", "host_id",
        "reviewed_object_kind", "reviewed_object_hash", "reviewed_head_oid", "reviewed_branch_ref",
        "verdict", "checks", "report_sha256",
    }

    def проверить_релевантное_ревью(
        хэш_ревью: str,
        ревью: object,
        вид_объекта: str,
        хэш_объекта: str,
    ) -> dict[str, object]:
        if (
            not isinstance(ревью, dict)
            or set(ревью) != поля_ревью
            or ревью.get("schema") != СХЕМА_КВИТАНЦИИ_РЕВЬЮ_ПОДУЗЛА
            or хэш_канонического_объекта_пула(ревью) != хэш_ревью
            or ревью.get("reviewed_object_kind") != вид_объекта
            or ревью.get("reviewed_object_hash") != хэш_объекта
            or ревью.get("verdict") not in {"принято", "на_доработку", "отклонено"}
        ):
            raise QueueError(EXIT_CONTEXT, "invalid_pool_review_receipt", "Релевантная квитанция ревью повреждена.")
        return ревью

    хэши_результатов = исходный_кандидат.get("result_hashes")
    головы_результатов = исходный_кандидат.get("result_heads")
    хэши_ревью_результатов = исходный_кандидат.get("review_hashes")
    if (
        not isinstance(хэши_результатов, list)
        or not isinstance(головы_результатов, list)
        or not isinstance(хэши_ревью_результатов, list)
        or not хэши_результатов
        or len(хэши_результатов) != len(головы_результатов)
        or len(хэши_результатов) != len(хэши_ревью_результатов)
        or len(set(хэши_результатов)) != len(хэши_результатов)
        or len(set(хэши_ревью_результатов)) != len(хэши_ревью_результатов)
    ):
        raise QueueError(EXIT_CONTEXT, "integration_result_set_mismatch", "Кандидат имеет неверный набор результатов.")

    покрытые_результаты: set[str] = set()
    for хэш_ревью_результата in хэши_ревью_результатов:
        ревью_результата = исходное["reviews"].get(хэш_ревью_результата)
        if not isinstance(ревью_результата, dict):
            raise QueueError(EXIT_CONTEXT, "integration_result_review_missing", "Ревью результата отсутствует.")
        хэш_результата = ревью_результата.get("reviewed_object_hash")
        if not isinstance(хэш_результата, str):
            raise QueueError(EXIT_CONTEXT, "integration_result_review_mismatch", "Ревью результата повреждено.")
        проверенное_ревью = проверить_релевантное_ревью(
            хэш_ревью_результата,
            ревью_результата,
            "result",
            хэш_результата,
        )
        if (
            проверенное_ревью.get("verdict") != "принято"
            or "публикационная чистота" not in проверенное_ревью.get("checks", [])
            or хэш_результата not in хэши_результатов
            or хэш_результата in покрытые_результаты
        ):
            raise QueueError(EXIT_CONTEXT, "integration_result_review_mismatch", "Ревью не покрывают exact результаты.")
        покрытые_результаты.add(хэш_результата)
    if покрытые_результаты != set(хэши_результатов):
        raise QueueError(EXIT_CONTEXT, "integration_result_review_mismatch", "Ревью не покрывают exact результаты.")

    for хэш_результата, голова_результата in zip(хэши_результатов, головы_результатов):
        результат = исходное["results"].get(хэш_результата)
        основные_поля_результата = {
            "schema", "assignment_hash", "activation_hash", "task_id", "host_id", "slot_id",
            "worktree_id", "queue_ref", "branch_ref", "base_oid", "head_oid", "tree_oid",
            "commits", "write_paths", "target_ref", "remote", "хэш_сообщения",
        }
        схема_результата = результат.get("schema") if isinstance(результат, dict) else None
        поля_результата_допустимы = (
            схема_результата == ПРЕЖНЯЯ_СХЕМА_КВИТАНЦИИ_РЕЗУЛЬТАТА_ПОДУЗЛА
            and set(результат) == основные_поля_результата
        ) or (
            схема_результата == СХЕМА_КВИТАНЦИИ_РЕЗУЛЬТАТА_ПОДУЗЛА
            and set(результат) == основные_поля_результата | {"хэш_намерения_коммита"}
        )
        if (
            not isinstance(результат, dict)
            or хэш_канонического_объекта_пула(результат) != хэш_результата
            or not поля_результата_допустимы
            or результат.get("head_oid") != голова_результата
            or результат.get("target_ref") != квитанция["target_ref"]
        ):
            raise QueueError(EXIT_CONTEXT, "integration_result_receipt_mismatch", "Кандидат не связан с exact результатом.")
        проверить_доказательство_результата_пула(
            контекст_очереди,
            исходное,
            результат,
        )

    релевантные_объекты = {хэш_кандидата: "integration_candidate", **{хэш: "result" for хэш in хэши_результатов}}
    for иной_хэш_ревью, иное_ревью in исходное["reviews"].items():
        if not isinstance(иное_ревью, dict):
            continue
        иной_объект = иное_ревью.get("reviewed_object_hash")
        if иной_объект not in релевантные_объекты:
            continue
        проверенное = проверить_релевантное_ревью(
            иной_хэш_ревью,
            иное_ревью,
            релевантные_объекты[иной_объект],
            иной_объект,
        )
        if проверенное["verdict"] != "принято":
            raise QueueError(EXIT_CONTEXT, "integration_blocked_by_review", "Отрицательное ревью запрещает интеграцию.")

    хэш_ревью = квитанция["review_hash"]
    ревью = исходное["reviews"].get(хэш_ревью)
    if (
        not isinstance(ревью, dict)
        or хэш_канонического_объекта_пула(ревью) != хэш_ревью
        or ревью.get("schema") != СХЕМА_КВИТАНЦИИ_РЕВЬЮ_ПОДУЗЛА
        or ревью.get("verdict") != "принято"
        or "публикационная чистота" not in ревью.get("checks", [])
        or ревью.get("reviewed_object_kind") != "integration_candidate"
        or ревью.get("reviewed_object_hash") != хэш_кандидата
        or ревью.get("reviewed_head_oid") != новая_вершина
    ):
        raise QueueError(EXIT_CONTEXT, "integration_review_mismatch", "Интеграция не имеет exact принятого ревью.")

    ключ_публикации = хэш_канонического_объекта_пула(
        {
            "schema": "fum.ключ-публикации-принятой-интеграции.1",
            "integration_hash": хэш_интеграции,
            "remote": квитанция["remote"],
            "remote_ref": квитанция["target_ref"],
        }
    )
    намерение = новое["publications"].get(ключ_публикации)
    ожидаемое_намерение = {
        "schema": СХЕМА_НАМЕРЕНИЯ_ПУБЛИКАЦИИ_ИНТЕГРАЦИИ,
        "status": "publication_pending",
        "integration_hash": хэш_интеграции,
        "review_hash": хэш_ревью,
        "remote": квитанция["remote"],
        "remote_ref": квитанция["target_ref"],
        "base_oid": исходная_вершина,
        "head_oid": новая_вершина,
        "remote_url_sha256": None,
    }
    if намерение != ожидаемое_намерение or ключ_публикации in исходное["publications"]:
        raise QueueError(EXIT_CONTEXT, "integration_publication_intent_mismatch", "Переход не содержит exact pending intent.")
    ожидаемые_публикации = copy.deepcopy(исходное["publications"])
    ожидаемые_публикации[ключ_публикации] = ожидаемое_намерение
    if новое["publications"] != ожидаемые_публикации:
        raise QueueError(EXIT_CONTEXT, "integration_publication_intent_mismatch", "Реестр публикаций изменён неточно.")


def прочитать_квитанцию_принятой_интеграции(
    контекст_очереди: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
) -> tuple[dict[str, object], str, str] | None:
    ссылка = ссылка_квитанции_принятой_интеграции(
        контекст_очереди,
        идентификатор_задачи,
        поколение,
    )
    объект = read_ref_oid(контекст_очереди, ссылка)
    if объект is None:
        return None
    квитанция = прочитать_канонический_объект_данных(
        контекст_очереди,
        объект,
        состояние_ошибки="повреждена_квитанция_принятой_интеграции",
        пояснение="Квитанция принятой интеграции повреждена.",
    )
    ожидаемые = {
        "схема",
        "идентификатор_рабочего_дерева",
        "ссылка_ветки",
        "идентификатор_задачи",
        "поколение",
        "исходная_вершина",
        "новая_вершина",
        "идентификатор_продолжения",
        "ссылка_пула",
        "исходный_объект_пула",
        "новый_объект_пула",
        "хэш_интеграции",
    }
    if (
        not isinstance(квитанция, dict)
        or set(квитанция) != ожидаемые
        or квитанция.get("схема") != СХЕМА_КВИТАНЦИИ_ПРИНЯТОЙ_ИНТЕГРАЦИИ
        or квитанция.get("идентификатор_рабочего_дерева") != контекст_очереди.worktree_id
        or квитанция.get("ссылка_ветки") != контекст_очереди.branch_ref
        or квитанция.get("идентификатор_задачи") != идентификатор_задачи
        or квитанция.get("поколение") != поколение
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "повреждена_квитанция_принятой_интеграции",
            "Квитанция принятой интеграции повреждена.",
        )
    return квитанция, объект, ссылка


def синхронизировано_основное_рабочее_дерево(
    контекст_очереди: QueueContext,
    вершина: str,
) -> bool:
    наблюдаемая_вершина = current_head(контекст_очереди.root)
    if run_git(
        контекст_очереди.root,
        ["merge-base", "--is-ancestor", вершина, наблюдаемая_вершина],
        check=False,
    ).returncode != 0:
        return False
    дерево = decoded_stdout(run_git(контекст_очереди.root, ["write-tree"]))
    целевое_дерево = decoded_stdout(
        run_git(контекст_очереди.root, ["rev-parse", f"{наблюдаемая_вершина}^{{tree}}"])
    )
    незарегистрированные = run_git(
        контекст_очереди.root,
        ["ls-files", "--others", "--exclude-standard", "-z"],
    ).stdout
    незаписанные = run_git(
        контекст_очереди.root,
        ["diff", "--quiet", "--"],
        check=False,
    )
    return дерево == целевое_дерево and not незарегистрированные and незаписанные.returncode == 0


def результат_принятой_интеграции(
    контекст_очереди: QueueContext,
    квитанция: dict[str, object],
    объект_квитанции: str,
    ссылка_квитанции: str,
) -> tuple[int, dict[str, object]]:
    новая_вершина = str(квитанция["новая_вершина"])
    достижимость = run_git(
        контекст_очереди.root,
        ["merge-base", "--is-ancestor", новая_вершина, current_head(контекст_очереди.root)],
        check=False,
    )
    if достижимость.returncode != 0 or not синхронизировано_основное_рабочее_дерево(
        контекст_очереди,
        новая_вершина,
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "integration_checkout_not_synced",
            "Принятая интеграция не имеет достижимого чистого readback checkout.",
        )
    return 0, {
        "state": "integrated_and_handed_off",
        "task_id": квитанция["идентификатор_задачи"],
        "generation": квитанция["поколение"],
        "old_head": квитанция["исходная_вершина"],
        "new_head": квитанция["новая_вершина"],
        "идентификатор_продолжения": квитанция["идентификатор_продолжения"],
        "хэш_интеграции": квитанция["хэш_интеграции"],
        "объект_квитанции": объект_квитанции,
        "ссылка_квитанции": ссылка_квитанции,
        **common_payload(
            контекст_очереди,
            read_ref_oid(контекст_очереди, контекст_очереди.queue_ref),
        ),
    }


def проверить_повтор_принятой_интеграции(
    квитанция: dict[str, object],
    идентификатор_продолжения: str,
    новая_вершина: str,
    ссылка_пула: str | None,
    исходный_объект_пула: str | None,
    новый_объект_пула: str | None,
    хэш_интеграции: str,
) -> None:
    if (
        квитанция["идентификатор_продолжения"] != идентификатор_продолжения
        or квитанция["новая_вершина"] != новая_вершина
        or квитанция["хэш_интеграции"] != хэш_интеграции
        or (ссылка_пула is not None and квитанция["ссылка_пула"] != ссылка_пула)
        or (
            исходный_объект_пула is not None
            and квитанция["исходный_объект_пула"] != исходный_объект_пула
        )
        or (
            новый_объект_пула is not None
            and квитанция["новый_объект_пула"] != новый_объект_пула
        )
    ):
        raise QueueError(EXIT_OWNERSHIP, "integration_replay_mismatch", "Повтор интеграции не совпал.")


def принять_интеграционный_кандидат(
    контекст_очереди: QueueContext,
    идентификатор_задачи: str,
    поколение: str,
    идентификатор_продолжения: str,
    новая_вершина: str,
    ссылка_пула: str | None,
    исходный_объект_пула: str | None,
    новый_объект_пула: str | None,
    хэш_интеграции: str,
) -> tuple[int, dict[str, object]]:
    идентификатор_задачи = validate_task_id(идентификатор_задачи)
    идентификатор_продолжения = validate_task_id(идентификатор_продолжения)
    if not поколение or any(символ in поколение for символ in ("\0", "\n", "\r")):
        raise QueueError(EXIT_CLI, "invalid_generation", "Некорректное поколение владельца.")
    if re.fullmatch(r"sha256:[0-9a-f]{64}", хэш_интеграции) is None:
        raise QueueError(EXIT_CLI, "invalid_integration_hash", "Хэш интеграции неканоничен.")
    сохранённая = прочитать_квитанцию_принятой_интеграции(
        контекст_очереди,
        идентификатор_задачи,
        поколение,
    )
    if сохранённая is not None:
        квитанция, объект_квитанции, ссылка_квитанции = сохранённая
        проверить_повтор_принятой_интеграции(
            квитанция,
            идентификатор_продолжения,
            новая_вершина,
            ссылка_пула,
            исходный_объект_пула,
            новый_объект_пула,
            хэш_интеграции,
        )
        return результат_принятой_интеграции(
            контекст_очереди,
            квитанция,
            объект_квитанции,
            ссылка_квитанции,
        )

    if ссылка_пула is None or исходный_объект_пула is None or новый_объект_пула is None:
        raise QueueError(EXIT_CLI, "missing_pool_transition", "Первичное принятие требует exact CAS пула.")
    ожидаемая_ссылка, _ = ожидаемая_ссылка_пула(контекст_очереди)
    if ссылка_пула != ожидаемая_ссылка or run_git(
        контекст_очереди.root,
        ["check-ref-format", ссылка_пула],
        check=False,
    ).returncode != 0:
        raise QueueError(EXIT_CLI, "invalid_pool_ref", "Ссылка пула не совпала с exact common-dir.")
    исходный_объект_пула = проверить_объект_пула(контекст_очереди, исходный_объект_пула)
    новый_объект_пула = проверить_объект_пула(контекст_очереди, новый_объект_пула)
    новая_вершина = validate_publication_commit(контекст_очереди.root, новая_вершина)
    ensure_live_branch(контекст_очереди)
    состояние, объект_очереди = read_state(контекст_очереди)
    if объект_очереди is None:
        raise QueueError(EXIT_CONTEXT, "corrupt_queue", "У владельца отсутствует Git-ссылка очереди.")
    владелец = require_owner(
        контекст_очереди,
        состояние,
        идентификатор_задачи,
        поколение,
    )
    исходная_вершина = str(владелец["base_head"])
    if current_head(контекст_очереди.root) != исходная_вершина:
        raise QueueError(EXIT_HEAD_CHANGED, "head_changed", "HEAD изменился после допуска владельца.")
    потребовать_ожидающее_продолжение(
        состояние,
        владелец,
        идентификатор_продолжения,
    )
    if новая_вершина == исходная_вершина or run_git(
        контекст_очереди.root,
        ["merge-base", "--is-ancestor", исходная_вершина, новая_вершина],
        check=False,
    ).returncode != 0:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "integration_candidate_not_descendant",
            "Интеграционный кандидат не продолжает exact исходную вершину.",
        )
    if read_ref_oid(контекст_очереди, ссылка_пула) != исходный_объект_пула:
        raise QueueError(EXIT_CAS, "pool_cas_changed", "Состояние пула сдвинулось до принятия.")
    проверить_переход_пула_интеграции(
        контекст_очереди,
        исходный_объект_пула,
        новый_объект_пула,
        хэш_интеграции,
        идентификатор_задачи,
        поколение,
        идентификатор_продолжения,
        исходная_вершина,
        новая_вершина,
    )
    целевое_дерево = decoded_stdout(
        run_git(контекст_очереди.root, ["rev-parse", f"{новая_вершина}^{{tree}}"])
    )
    дерево_индекса = decoded_stdout(run_git(контекст_очереди.root, ["write-tree"]))
    подготовлено = дерево_индекса == целевое_дерево
    if not подготовлено and decoded_stdout(
        run_git(
            контекст_очереди.root,
            ["status", "--porcelain", "--untracked-files=all"],
        )
    ):
        raise QueueError(EXIT_DIRTY, "dirty", "Основной checkout не чист перед интеграцией.")
    if not подготовлено:
        run_git(
            контекст_очереди.root,
            ["read-tree", "--reset", "-u", новая_вершина],
        )
    if decoded_stdout(run_git(контекст_очереди.root, ["write-tree"])) != целевое_дерево:
        raise QueueError(EXIT_DIRTY, "integration_checkout_prepare_failed", "Не удалось подготовить checkout.")
    if run_git(
        контекст_очереди.root,
        ["ls-files", "--others", "--exclude-standard", "-z"],
    ).stdout or run_git(
        контекст_очереди.root,
        ["diff", "--quiet", "--"],
        check=False,
    ).returncode != 0:
        raise QueueError(EXIT_DIRTY, "integration_checkout_prepare_failed", "Подготовленный checkout изменён.")

    метка, _ = utc_values()
    новое_состояние = copy.deepcopy(состояние)
    новое_состояние["owner"] = None
    новое_состояние["last_completion"] = {
        "kind": "committed",
        "task_id": идентификатор_задачи,
        "generation": поколение,
        "base_head": исходная_вершина,
        "head": новая_вершина,
        "completed_at": метка,
        "идентификатор_продолжения": идентификатор_продолжения,
    }
    новое_состояние["updated_at"] = метка
    новое_состояние[ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ] = True
    новый_объект_очереди = write_state_blob(контекст_очереди, новое_состояние)
    квитанция = {
        "схема": СХЕМА_КВИТАНЦИИ_ПРИНЯТОЙ_ИНТЕГРАЦИИ,
        "идентификатор_рабочего_дерева": контекст_очереди.worktree_id,
        "ссылка_ветки": контекст_очереди.branch_ref,
        "идентификатор_задачи": идентификатор_задачи,
        "поколение": поколение,
        "исходная_вершина": исходная_вершина,
        "новая_вершина": новая_вершина,
        "идентификатор_продолжения": идентификатор_продолжения,
        "ссылка_пула": ссылка_пула,
        "исходный_объект_пула": исходный_объект_пула,
        "новый_объект_пула": новый_объект_пула,
        "хэш_интеграции": хэш_интеграции,
    }
    объект_квитанции = записать_канонический_объект_данных(
        контекст_очереди,
        квитанция,
    )
    ссылка_квитанции = ссылка_квитанции_принятой_интеграции(
        контекст_очереди,
        идентификатор_задачи,
        поколение,
    )
    транзакция = (
        "start\n"
        f"create {ссылка_квитанции} {объект_квитанции}\n"
        f"update {контекст_очереди.branch_ref} {новая_вершина} {исходная_вершина}\n"
        f"update {контекст_очереди.queue_ref} {новый_объект_очереди} {объект_очереди}\n"
        f"update {ссылка_пула} {новый_объект_пула} {исходный_объект_пула}\n"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    переход = run_git(
        контекст_очереди.root,
        ["update-ref", "--stdin"],
        input_bytes=транзакция,
        check=False,
    )
    if переход.returncode != 0:
        сохранённая = прочитать_квитанцию_принятой_интеграции(
            контекст_очереди,
            идентификатор_задачи,
            поколение,
        )
        if сохранённая is not None:
            проверить_повтор_принятой_интеграции(
                сохранённая[0],
                идентификатор_продолжения,
                новая_вершина,
                ссылка_пула,
                исходный_объект_пула,
                новый_объект_пула,
                хэш_интеграции,
            )
            return результат_принятой_интеграции(контекст_очереди, *сохранённая)
        фактическая_вершина = current_head(контекст_очереди.root)
        if (
            decoded_stdout(run_git(контекст_очереди.root, ["write-tree"])) != целевое_дерево
            or run_git(контекст_очереди.root, ["diff", "--quiet", "--"], check=False).returncode != 0
            or run_git(
                контекст_очереди.root,
                ["ls-files", "--others", "--exclude-standard", "-z"],
            ).stdout
        ):
            raise QueueError(
                EXIT_DIRTY,
                "integration_checkout_recovery_blocked",
                "Checkout изменён после подготовки; автоматический rollback запрещён.",
            )
        run_git(
            контекст_очереди.root,
            ["read-tree", "--reset", "-u", фактическая_вершина],
        )
        if not синхронизировано_основное_рабочее_дерево(контекст_очереди, фактическая_вершина):
            raise QueueError(EXIT_DIRTY, "integration_checkout_recovery_failed", "Checkout не восстановился к фактическому HEAD.")
        if фактическая_вершина != исходная_вершина:
            raise QueueError(EXIT_HEAD_CHANGED, "head_changed", "Целевая ветка сдвинулась во время CAS; checkout восстановлен.")
        if read_ref_oid(контекст_очереди, ссылка_пула) != исходный_объект_пула:
            raise QueueError(EXIT_CAS, "pool_cas_changed", "Состояние пула сдвинулось во время CAS.")
        raise QueueError(EXIT_CAS, "integration_cas_failed", "Не удалось атомарно принять интеграцию.")
    return результат_принятой_интеграции(
        контекст_очереди,
        квитанция,
        объект_квитанции,
        ссылка_квитанции,
    )


def validate_publication_commit(root: Path, commit: str) -> str:
    object_format = decoded_stdout(run_git(root, ["rev-parse", "--show-object-format"]))
    expected_length = {"sha1": 40, "sha256": 64}.get(object_format)
    if (
        expected_length is None
        or len(commit) != expected_length
        or re.fullmatch(r"[0-9a-f]+", commit) is None
    ):
        raise QueueError(
            EXIT_CLI,
            "invalid_commit",
            "Публикация требует полный строчный хэш Git-коммита.",
        )
    object_type = run_git(root, ["cat-file", "-t", commit], check=False)
    if object_type.returncode != 0 or decoded_stdout(object_type) != "commit":
        raise QueueError(
            EXIT_CLI,
            "invalid_commit",
            "Указанный объект публикации не является доступным Git-коммитом.",
        )
    return commit


def validate_publication_branch(root: Path, branch_ref: str) -> str:
    if not branch_ref.startswith("refs/heads/"):
        raise QueueError(
            EXIT_CLI,
            "invalid_branch_ref",
            "Публикация требует полную ссылку refs/heads/... .",
        )
    checked = run_git(root, ["check-ref-format", branch_ref], check=False)
    if checked.returncode != 0:
        raise QueueError(
            EXIT_CLI,
            "invalid_branch_ref",
            "Целевая ссылка публикации не соответствует формату Git ref.",
        )
    return branch_ref


def valid_github_repository_path(path: str) -> bool:
    if "%" in path:
        return False
    components = path.removeprefix("/").split("/")
    if len(components) != 2:
        return False
    owner, repository = components
    if repository.endswith(".git"):
        repository = repository[:-4]
    return bool(
        re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?", owner)
        and re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?", repository)
        and repository not in {".", ".."}
    )


def validate_github_push_url(push_url: str) -> str:
    try:
        parsed = urlsplit(push_url)
        port = parsed.port
    except ValueError:
        parsed = None
        port = None
    if parsed is not None:
        common = (
            parsed.hostname == "github.com"
            and parsed.password is None
            and not parsed.query
            and not parsed.fragment
            and valid_github_repository_path(parsed.path)
        )
        https_ok = (
            common
            and parsed.scheme == "https"
            and parsed.username is None
            and port in {None, 443}
        )
        if https_ok:
            return push_url
    raise QueueError(
        EXIT_CLI,
        "invalid_push_url",
        "Нужен однозначный HTTPS GitHub push URL без встроенных учётных данных.",
    )


def terminate_publication_process_group(
    process: subprocess.Popen[bytes],
    environment: dict[str, str],
) -> None:
    if os.name == "posix":
        try:
            os.killpg(process.pid, SIGTERM)
        except ProcessLookupError:
            pass
    elif os.name == "nt":  # pragma: no cover - exercised on Windows hosts.
        try:
            switch = chr(47)
            subprocess.run(
                [
                    "taskkill",
                    f"{switch}PID",
                    str(process.pid),
                    f"{switch}T",
                    f"{switch}F",
                ],
                check=False,
                capture_output=True,
                env=environment,
                timeout=PUBLICATION_TERMINATION_GRACE_SECONDS,
            )
        except (OSError, subprocess.TimeoutExpired):
            pass
    else:  # pragma: no cover - Python currently exposes posix or nt here.
        process.terminate()

    try:
        process.wait(timeout=PUBLICATION_TERMINATION_GRACE_SECONDS)
    except subprocess.TimeoutExpired:
        if os.name == "posix":
            try:
                os.killpg(process.pid, SIGKILL)
            except ProcessLookupError:
                pass
        else:  # pragma: no cover - Windows taskkill normally completed the tree.
            process.kill()
        process.wait()


def run_publication_git(
    root: Path,
    args: list[str],
    *,
    check: bool = False,
) -> subprocess.CompletedProcess[bytes]:
    environment = clean_git_environment()
    environment.update(
        {
            "GCM_INTERACTIVE": "Never",
            "GIT_TERMINAL_PROMPT": "0",
        }
    )
    command = ["git", "-C", str(root), *args]
    popen_arguments: dict[str, object] = {
        "stdin": subprocess.DEVNULL,
        "stdout": subprocess.PIPE,
        "stderr": subprocess.PIPE,
        "env": environment,
    }
    if os.name == "posix":
        popen_arguments["start_new_session"] = True
    elif os.name == "nt":  # pragma: no cover - exercised on Windows hosts.
        popen_arguments["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    try:
        process = subprocess.Popen(command, **popen_arguments)
    except OSError as exc:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            f"Не удалось запустить Git transport: {exc}",
        ) from exc
    try:
        stdout, stderr = process.communicate(
            timeout=PUBLICATION_GIT_TIMEOUT_SECONDS
        )
        result = subprocess.CompletedProcess(
            args=command,
            returncode=process.returncode,
            stdout=stdout,
            stderr=stderr,
        )
    except subprocess.TimeoutExpired:
        terminate_publication_process_group(process, environment)
        stdout, stderr = process.communicate()
        result = subprocess.CompletedProcess(
            args=command,
            returncode=124,
            stdout=stdout,
            stderr=stderr,
        )
    if check and result.returncode != 0:
        raise QueueError(
            EXIT_CONTEXT,
            "git_error",
            "Git transport завершился с ошибкой.",
        )
    return result


def remote_branch_head(
    root: Path,
    push_url: str,
    branch_ref: str,
) -> tuple[bool, str | None]:
    result = run_publication_git(
        root,
        ["ls-remote", "--exit-code", "--heads", push_url, branch_ref],
    )
    if result.returncode == 2 and not result.stdout.strip():
        return True, None
    if result.returncode != 0:
        return False, None
    lines = result.stdout.decode("utf-8", errors="strict").splitlines()
    matches = []
    for line in lines:
        fields = line.split("\t", 1)
        if len(fields) == 2 and fields[1] == branch_ref:
            matches.append(fields[0])
    if len(matches) != 1 or re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", matches[0]) is None:
        return False, None
    return True, matches[0]


def commit_exists(root: Path, commit: str) -> bool | None:
    result = run_git(
        root,
        ["cat-file", "--batch-check=%(objectname) %(objecttype)"],
        input_bytes=f"{commit}\n".encode("ascii"),
        check=False,
    )
    if result.returncode != 0:
        return None
    fields = decoded_stdout(result).split()
    if fields == [commit, "commit"]:
        return True
    if fields == [commit, "missing"]:
        return False
    return None


def is_ancestor(root: Path, ancestor: str, descendant: str) -> bool | None:
    result = run_git(
        root,
        ["merge-base", "--is-ancestor", ancestor, descendant],
        check=False,
    )
    if result.returncode == 0:
        return True
    if result.returncode == 1:
        return False
    return None


def publication_url_rewrites(root: Path, push_url: str) -> list[tuple[str, str]]:
    configured = run_git(
        root,
        [
            "config",
            "--get-regexp",
            r"^url\..*\.(insteadof|pushinsteadof)$",
        ],
        check=False,
    )
    if configured.returncode == 1:
        return []
    if configured.returncode != 0:
        raise QueueError(
            EXIT_CONTEXT,
            "git_error",
            "Не удалось проверить Git URL rewrite перед публикацией.",
        )
    matches: list[tuple[str, str]] = []
    for line in configured.stdout.decode("utf-8", errors="strict").splitlines():
        fields = line.split(None, 1)
        if len(fields) != 2:
            continue
        key, prefix = fields
        if push_url.startswith(prefix):
            matches.append((key, prefix))
    return matches


def publication_url_rewrite_options(root: Path, push_url: str) -> list[str]:
    matches = publication_url_rewrites(root, push_url)
    instead_of = [
        (len(prefix), key, prefix)
        for key, prefix in matches
        if key.lower().endswith(".insteadof")
    ]
    if not instead_of:
        return []
    _, key, prefix = max(instead_of)
    return ["-c", f"{key}={prefix}"]


def remote_contains_commit(
    source_root: Path,
    push_url: str,
    branch_ref: str,
    commit: str,
) -> bool | None:
    with tempfile.TemporaryDirectory(prefix="fum-github-publication-") as directory:
        root = Path(directory)
        disabled_hooks = root / "disabled-hooks"
        disabled_hooks.mkdir()
        initialized = run_publication_git(
            root,
            ["-c", f"core.hooksPath={disabled_hooks}", "init", "--bare", "."],
        )
        if initialized.returncode != 0:
            return None
        fetched = run_publication_git(
            root,
            [
                "-c",
                f"core.hooksPath={disabled_hooks}",
                *publication_url_rewrite_options(source_root, push_url),
                "fetch",
                "--no-tags",
                "--filter=blob:none",
                push_url,
                f"{branch_ref}:refs/fum/remote-tip",
            ],
        )
        if fetched.returncode != 0:
            return None
        available = commit_exists(root, commit)
        if available is None:
            return None
        if not available:
            return False
        remote_head = decoded_stdout(
            run_git(root, ["rev-parse", "refs/fum/remote-tip"])
        )
        return is_ancestor(root, commit, remote_head)


def publication_failure(
    *,
    state: str,
    exit_code: int,
    message: str,
    commit: str,
    branch_ref: str,
    remote_head: str | None,
) -> NoReturn:
    данные_результата_операции: dict[str, object] = {
        "commit": commit,
        "branch_ref": branch_ref,
    }
    if remote_head is not None:
        данные_результата_операции["remote_head"] = remote_head
    raise QueueError(exit_code, state, message, данные_результата_операции=данные_результата_операции)


def publish_exact_commit(
    контекст_очереди: QueueContext,
    commit: str,
    branch_ref: str,
    push_url: str,
    *,
    allow_url_rewrite_for_tests: bool = False,
) -> tuple[int, dict[str, object]]:
    commit = validate_publication_commit(контекст_очереди.root, commit)
    branch_ref = validate_publication_branch(контекст_очереди.root, branch_ref)
    push_url = validate_github_push_url(push_url)
    rewrites = publication_url_rewrites(контекст_очереди.root, push_url)
    if rewrites and not allow_url_rewrite_for_tests:
        raise QueueError(
            EXIT_CLI,
            "invalid_url_rewrite",
            "Применимое url.*.insteadOf или pushInsteadOf запрещает доказать точный GitHub endpoint.",
        )
    refspec = f"{commit}:{branch_ref}"
    pushed = run_publication_git(
        контекст_очереди.root,
        [
            "push",
            "--porcelain",
            "--no-verify",
            "--no-follow-tags",
            "--recurse-submodules=no",
            "--no-signed",
            "--no-push-option",
            push_url,
            refspec,
        ],
    )
    if pushed.returncode == 0:
        return 0, {
            "state": "published",
            "commit": commit,
            "branch_ref": branch_ref,
        }

    observed, remote_head = remote_branch_head(контекст_очереди.root, push_url, branch_ref)
    if not observed:
        publication_failure(
            state="unconfirmed",
            exit_code=EXIT_PUBLICATION_UNCONFIRMED,
            message="Результат отправки не подтверждён чтением удалённой ветки.",
            commit=commit,
            branch_ref=branch_ref,
            remote_head=None,
        )
    if remote_head == commit:
        return 0, {
            "state": "published",
            "commit": commit,
            "branch_ref": branch_ref,
            "remote_head": remote_head,
        }
    if remote_head is None:
        publication_failure(
            state="rejected",
            exit_code=EXIT_PUBLICATION_REJECTED,
            message="Удалённый сервер отклонил создание целевой ветки.",
            commit=commit,
            branch_ref=branch_ref,
            remote_head=None,
        )

    remote_available = commit_exists(контекст_очереди.root, remote_head)
    if remote_available is None:
        publication_failure(
            state="unconfirmed",
            exit_code=EXIT_PUBLICATION_UNCONFIRMED,
            message="Не удалось проверить удалённый commit object в локальном Git.",
            commit=commit,
            branch_ref=branch_ref,
            remote_head=remote_head,
        )
    if remote_available:
        commit_before_remote = is_ancestor(контекст_очереди.root, commit, remote_head)
        if commit_before_remote is None:
            publication_failure(
                state="unconfirmed",
                exit_code=EXIT_PUBLICATION_UNCONFIRMED,
                message="Git не подтвердил отношение предка для удалённой вершины.",
                commit=commit,
                branch_ref=branch_ref,
                remote_head=remote_head,
            )
        if commit_before_remote:
            return 0, {
                "state": "already_published_descendant",
                "commit": commit,
                "branch_ref": branch_ref,
                "remote_head": remote_head,
            }
        remote_before_commit = is_ancestor(контекст_очереди.root, remote_head, commit)
        if remote_before_commit is None:
            publication_failure(
                state="unconfirmed",
                exit_code=EXIT_PUBLICATION_UNCONFIRMED,
                message="Git не подтвердил отношение предка для локального коммита.",
                commit=commit,
                branch_ref=branch_ref,
                remote_head=remote_head,
            )
        if remote_before_commit:
            publication_failure(
                state="rejected",
                exit_code=EXIT_PUBLICATION_REJECTED,
                message="Удалённый сервер отклонил непринудительное продвижение ветки.",
                commit=commit,
                branch_ref=branch_ref,
                remote_head=remote_head,
            )
        publication_failure(
            state="diverged",
            exit_code=EXIT_PUBLICATION_DIVERGED,
            message="Локальный коммит и удалённая ветка имеют расходящуюся историю.",
            commit=commit,
            branch_ref=branch_ref,
            remote_head=remote_head,
        )

    contains = remote_contains_commit(контекст_очереди.root, push_url, branch_ref, commit)
    if contains is None:
        publication_failure(
            state="unconfirmed",
            exit_code=EXIT_PUBLICATION_UNCONFIRMED,
            message="Не удалось проверить достижимость коммита из удалённой ветки.",
            commit=commit,
            branch_ref=branch_ref,
            remote_head=remote_head,
        )
    if contains:
        return 0, {
            "state": "already_published_descendant",
            "commit": commit,
            "branch_ref": branch_ref,
            "remote_head": remote_head,
        }
    publication_failure(
        state="diverged",
        exit_code=EXIT_PUBLICATION_DIVERGED,
        message="Локальный коммит и удалённая ветка имеют расходящуюся историю.",
        commit=commit,
        branch_ref=branch_ref,
        remote_head=remote_head,
    )


def участники_очереди(состояние: dict[str, object]) -> list[str]:
    участники: list[str] = []
    владелец = состояние["owner"]
    if isinstance(владелец, dict):
        участники.append(str(владелец["task_id"]))
    участники.extend(str(билет["task_id"]) for билет in состояние["waiting"])
    return участники


def изменённые_пути_для_сброса(корень: Path) -> list[str]:
    return sorted(
        {
            путь
            for _, пути in status_records(корень, include_root_obsidian=True)
            for путь in пути
        }
    )


def неотслеживаемые_пути_для_сброса(корень: Path) -> list[str]:
    результат = run_git(
        корень,
        [
            "-c",
            "core.quotepath=false",
            "ls-files",
            "--others",
            "--exclude-standard",
            "-z",
            "--",
        ],
    )
    пути = sorted(
        элемент.decode("utf-8", errors="surrogateescape")
        for элемент in результат.stdout.split(b"\0")
        if элемент
    )
    for путь in пути:
        try:
            путь.encode("utf-8", errors="strict")
        except UnicodeEncodeError as ошибка:
            raise QueueError(
                EXIT_CONTEXT,
                "unsupported_path",
                "Штатный сброс не поддерживает путь с некорректным UTF-8.",
            ) from ошибка
    return пути


def путь_виден_гит_как_неотслеживаемый(корень: Path, путь: str) -> bool:
    сырые_пути = run_git(
        корень,
        [
            "-c",
            "core.quotepath=false",
            "ls-files",
            "--others",
            "-z",
            "--",
            f":(top,literal){путь}",
        ],
    ).stdout.split(b"\0")
    return путь.encode("utf-8", errors="strict") in сырые_пути


def игнорируемые_пути_рабочей_копии(корень: Path) -> list[str]:
    результат = run_git(
        корень,
        [
            "-c",
            "core.quotepath=false",
            "ls-files",
            "--others",
            "--ignored",
            "--exclude-standard",
            "-z",
            "--",
        ],
    )
    пути = sorted(
        элемент.decode("utf-8", errors="surrogateescape")
        for элемент in результат.stdout.split(b"\0")
        if элемент
    )
    for путь in пути:
        try:
            путь.encode("utf-8", errors="strict")
        except UnicodeEncodeError as ошибка:
            raise QueueError(
                EXIT_CONTEXT,
                "unsupported_path",
                "Штатный сброс не поддерживает игнорируемый путь с некорректным UTF-8.",
            ) from ошибка
    return пути


def потребовать_отсутствие_коллизий_игнорируемых_путей(
    корень: Path,
    целевая_вершина: str,
) -> None:
    игнорируемые = игнорируемые_пути_рабочей_копии(корень)
    if not игнорируемые:
        return
    результат = run_git(
        корень,
        [
            "-c",
            "core.quotepath=false",
            "ls-tree",
            "-r",
            "-z",
            "--name-only",
            целевая_вершина,
        ],
    )
    целевые = [
        элемент.decode("utf-8", errors="strict")
        for элемент in результат.stdout.split(b"\0")
        if элемент
    ]
    коллизии = sorted(
        игнорируемый
        for игнорируемый in игнорируемые
        if any(
            игнорируемый == целевой
            or игнорируемый.startswith(f"{целевой}/")
            or целевой.startswith(f"{игнорируемый}/")
            for целевой in целевые
        )
    )
    if коллизии:
        raise QueueError(
            EXIT_DIRTY,
            "ignored_path_collision",
            "Целевое дерево пересекается с игнорируемыми данными; штатный сброс их не удаляет.",
            данные_результата_операции={"blocking_paths": коллизии},
        )


def добавить_часть_отпечатка(
    вычислитель,
    название: str,
    содержимое: bytes,
) -> None:
    название_байты = название.encode("utf-8")
    вычислитель.update(len(название_байты).to_bytes(8, "big"))
    вычислитель.update(название_байты)
    вычислитель.update(len(содержимое).to_bytes(8, "big"))
    вычислитель.update(содержимое)


def является_вложенной_границей_репозитория(каталог: Path) -> bool:
    return os.path.lexists(каталог / ".git") or (
        (каталог / "HEAD").is_file()
        and (каталог / "objects").is_dir()
        and (каталог / "refs").is_dir()
    )


def описать_неотслеживаемый_объект(
    корень: Path,
    путь: str,
) -> tuple[dict[str, str], bytes, int]:
    полный_путь = корень / путь
    try:
        сведения = полный_путь.lstat()
    except FileNotFoundError as ошибка:
        raise QueueError(
            EXIT_CAS,
            "reset_plan_changed",
            "Неотслеживаемый путь изменился во время построения плана.",
        ) from ошибка
    вид = stat.S_IFMT(сведения.st_mode)
    if stat.S_ISREG(сведения.st_mode):
        тип = "обычный_файл"
        содержимое = полный_путь.read_bytes()
    elif stat.S_ISLNK(сведения.st_mode):
        тип = "символическая_ссылка"
        содержимое = os.readlink(полный_путь).encode(
            "utf-8",
            errors="surrogateescape",
        )
    elif stat.S_ISDIR(сведения.st_mode) and является_вложенной_границей_репозитория(
        полный_путь
    ):
        тип = "вложенная_git_граница"
        содержимое = b"nested-git-boundary"
    else:
        raise QueueError(
            EXIT_DIRTY,
            "unsupported_untracked_type",
            "Штатный сброс не удаляет специальные неотслеживаемые файлы.",
            данные_результата_операции={"path": путь},
        )
    return (
        {
            "путь": путь,
            "тип": тип,
            "sha256": f"sha256:{hashlib.sha256(содержимое).hexdigest()}",
        },
        содержимое,
        вид,
    )


def описать_состояние_отслеживаемого_пути(
    корень: Path,
    путь: str,
) -> dict[str, object]:
    полный_путь = корень / путь
    try:
        сведения = полный_путь.lstat()
    except (FileNotFoundError, NotADirectoryError):
        return {"тип": "отсутствует"}
    if stat.S_ISREG(сведения.st_mode):
        содержимое = полный_путь.read_bytes()
        return {
            "тип": "обычный_файл",
            "исполняемый": bool(сведения.st_mode & 0o111),
            "sha256": f"sha256:{hashlib.sha256(содержимое).hexdigest()}",
        }
    if stat.S_ISLNK(сведения.st_mode):
        цель = os.readlink(полный_путь).encode(
            "utf-8",
            errors="surrogateescape",
        )
        return {
            "тип": "символическая_ссылка",
            "sha256": f"sha256:{hashlib.sha256(цель).hexdigest()}",
        }
    if stat.S_ISDIR(сведения.st_mode):
        return {"тип": "каталог"}
    raise QueueError(
        EXIT_DIRTY,
        "unsupported_tracked_type",
        "Штатный сброс не очищает специальный объект на отслеживаемом пути.",
        данные_результата_операции={"path": путь},
    )


def целевое_состояние_отслеживаемого_пути(
    корень: Path,
    целевая_вершина: str,
    путь: str,
) -> dict[str, object]:
    результат = run_git(
        корень,
        [
            "ls-tree",
            "-z",
            "--full-tree",
            целевая_вершина,
            "--",
            f":(top,literal){путь}",
        ],
    )
    записи = [запись for запись in результат.stdout.split(b"\0") if запись]
    if not записи:
        return {"тип": "отсутствует"}
    if len(записи) != 1 or b"\t" not in записи[0]:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_target_tree",
            "Целевое дерево неоднозначно описывает отслеживаемый путь.",
        )
    метаданные, сырой_путь = записи[0].split(b"\t", 1)
    части = метаданные.split(b" ")
    if len(части) != 3:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_target_tree",
            "Целевое дерево содержит повреждённую запись пути.",
        )
    режим, тип_объекта, объект = части
    if сырой_путь.decode("utf-8", errors="strict") != путь:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_target_tree",
            "Целевое дерево вернуло другой отслеживаемый путь.",
        )
    if режим == b"040000" and тип_объекта == b"tree":
        return {"тип": "каталог"}
    if режим == b"160000" and тип_объекта == b"commit":
        return {"тип": "gitlink"}
    if тип_объекта != b"blob" or режим not in {b"100644", b"100755", b"120000"}:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_target_tree",
            "Целевое дерево содержит неподдерживаемый вид объекта.",
        )
    if режим == b"120000":
        содержимое = run_git(
            корень,
            ["cat-file", "blob", объект.decode("ascii", errors="strict")],
        ).stdout
    else:
        for режим_атрибутов in ([], ["--cached"]):
            атрибут = run_git(
                корень,
                [
                    "check-attr",
                    "-z",
                    *режим_атрибутов,
                    "filter",
                    "--",
                    путь,
                ],
            ).stdout.split(b"\0")
            if len(атрибут) != 4 or атрибут[-1] != b"":
                raise QueueError(
                    EXIT_CONTEXT,
                    "git_error",
                    "Git вернул неизвестный формат check-attr -z.",
                )
            значение_фильтра = атрибут[2]
            if значение_фильтра not in {b"unspecified", b"unset"}:
                raise QueueError(
                    EXIT_DIRTY,
                    "unsupported_checkout_filter",
                    "Штатный сброс не запускает внешний checkout-filter.",
                    данные_результата_операции={"path": путь},
                )
        содержимое = run_git(
            корень,
            [
                "cat-file",
                "--filters",
                f"--path={путь}",
                f"{целевая_вершина}:{путь}",
            ],
        ).stdout
    отпечаток = f"sha256:{hashlib.sha256(содержимое).hexdigest()}"
    if режим == b"120000":
        return {"тип": "символическая_ссылка", "sha256": отпечаток}
    return {
        "тип": "обычный_файл",
        "исполняемый": режим == b"100755",
        "sha256": отпечаток,
    }


def индекс_содержит_ссылку_на_подмодуль(корень: Path, путь: str) -> bool:
    результат = run_git(
        корень,
        [
            "-c",
            "core.quotepath=false",
            "ls-files",
            "--stage",
            "-z",
            "--",
            f":(top,literal){путь}",
        ],
    )
    return any(
        запись.split(b" ", 1)[0] == b"160000"
        for запись in результат.stdout.split(b"\0")
        if запись
    )


def отпечаток_индекса(корень: Path) -> str:
    содержимое = run_git(
        корень,
        ["-c", "core.quotepath=false", "ls-files", "--stage", "-z"],
    ).stdout
    return f"sha256:{hashlib.sha256(содержимое).hexdigest()}"


def потребовать_обычные_флаги_индекса(корень: Path) -> None:
    результат = run_git(
        корень,
        ["-c", "core.quotepath=false", "ls-files", "-v", "-z"],
    )
    скрытые: list[str] = []
    for запись in результат.stdout.split(b"\0"):
        if not запись:
            continue
        if len(запись) < 3 or запись[1:2] != b" ":
            raise QueueError(
                EXIT_CONTEXT,
                "git_error",
                "Git вернул неизвестный формат ls-files -v.",
            )
        метка = chr(запись[0])
        if метка == "S" or метка.islower():
            скрытые.append(
                запись[2:].decode("utf-8", errors="surrogateescape")
            )
    if скрытые:
        raise QueueError(
            EXIT_DIRTY,
            "hidden_index_flags",
            "Штатный сброс не применяется при assume-unchanged или skip-worktree.",
            данные_результата_операции={"blocking_paths": sorted(скрытые)},
        )


def снимок_изменений_для_сброса(корень: Path) -> dict[str, object]:
    потребовать_обычные_флаги_индекса(корень)
    изменённые = изменённые_пути_для_сброса(корень)
    изменённые_правила_получения_рабочих_файлов = sorted(
        путь
        for путь in изменённые
        if Path(путь).name in {".gitignore", ".gitattributes"}
    )
    if изменённые_правила_получения_рабочих_файлов:
        raise QueueError(
            EXIT_DIRTY,
            "checkout_policy_changed",
            "Штатный сброс требует заранее согласованные .gitignore и .gitattributes.",
            данные_результата_операции={"blocking_paths": изменённые_правила_получения_рабочих_файлов},
        )
    неотслеживаемые = неотслеживаемые_пути_для_сброса(корень)
    целевая_вершина = current_head(корень)
    потребовать_отсутствие_коллизий_игнорируемых_путей(
        корень,
        целевая_вершина,
    )
    вычислитель = hashlib.sha256()
    команды = (
        (
            "индекс",
            ["-c", "core.quotepath=false", "ls-files", "--stage", "-z"],
        ),
        (
            "подготовленные_изменения",
            [
                "-c",
                "core.quotepath=false",
                "diff",
                "--cached",
                "--binary",
                "--full-index",
                "--no-ext-diff",
                "--no-textconv",
                "HEAD",
                "--",
            ],
        ),
        (
            "изменения_рабочего_дерева",
            [
                "-c",
                "core.quotepath=false",
                "diff",
                "--binary",
                "--full-index",
                "--no-ext-diff",
                "--no-textconv",
                "--",
            ],
        ),
    )
    for название, аргументы in команды:
        добавить_часть_отпечатка(
            вычислитель,
            название,
            run_git(корень, аргументы).stdout,
        )
    добавить_часть_отпечатка(
        вычислитель,
        "изменённые_пути",
        canonical_state_bytes({"пути": изменённые}),
    )
    неотслеживаемые_объекты: list[dict[str, str]] = []
    for путь in неотслеживаемые:
        объект, содержимое, вид = описать_неотслеживаемый_объект(корень, путь)
        неотслеживаемые_объекты.append(объект)
        добавить_часть_отпечатка(
            вычислитель,
            f"неотслеживаемый:{путь}:{вид:o}",
            содержимое,
        )
    отслеживаемые_объекты: list[dict[str, object]] = []
    for путь in sorted(set(изменённые) - set(неотслеживаемые)):
        try:
            путь.encode("utf-8", errors="strict")
        except UnicodeEncodeError as ошибка:
            raise QueueError(
                EXIT_CONTEXT,
                "unsupported_path",
                "Штатный сброс не поддерживает отслеживаемый путь с некорректным UTF-8.",
            ) from ошибка
        целевое = целевое_состояние_отслеживаемого_пути(
            корень,
            целевая_вершина,
            путь,
        )
        if целевое["тип"] == "gitlink" or индекс_содержит_ссылку_на_подмодуль(
            корень,
            путь,
        ):
            raise QueueError(
                EXIT_DIRTY,
                "nested_repository_dirty",
                "Штатный сброс не очищает переход между gitlink и обычным путём.",
                данные_результата_операции={"gitlink_paths": [путь]},
            )
        отслеживаемые_объекты.append(
            {
                "путь": путь,
                "до": описать_состояние_отслеживаемого_пути(корень, путь),
                "цель": целевое,
            }
        )
    return {
        "изменённые_пути": изменённые,
        "неотслеживаемые_пути": неотслеживаемые,
        "неотслеживаемые_объекты": неотслеживаемые_объекты,
        "отслеживаемые_объекты": отслеживаемые_объекты,
        "отпечаток_индекса": отпечаток_индекса(корень),
        "отпечаток_изменений": f"sha256:{вычислитель.hexdigest()}",
    }


def фиксированные_служебные_ссылки(контекст: QueueContext) -> dict[str, str]:
    ветка = hashlib.sha256(контекст.branch_ref.encode("utf-8")).hexdigest()
    основа = f"{контекст.worktree_id}/{ветка}"
    return {
        f"{ПРОСТРАНСТВО_УПРАВЛЕНИЯ}/{основа}": "удалить",
        f"{ПРОСТРАНСТВО_ПРЕТЕНЗИЙ}/{основа}": "сохранить",
        f"{ПРОСТРАНСТВО_ПОЧИНКИ}/{основа}": "удалить",
        f"{ПРОСТРАНСТВО_ЭПОХ_РЕЗЕРВАЦИЙ}/{основа}": "сохранить",
        f"{ПРОСТРАНСТВО_ЖУРНАЛА_ЗАВЕРШЕНИЙ}/{основа}": "сохранить",
        f"{ПРОСТРАНСТВО_АНАЛИТИКИ_ЗАВЕРШЕНИЙ}/{основа}": "сохранить",
    }


def проверить_служебные_ограждения(
    значение: object,
    контекст: QueueContext,
) -> list[dict[str, str]]:
    if not isinstance(значение, list):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Служебные ограждения не являются списком.")
    проверенные: list[dict[str, str]] = []
    ссылки: set[str] = set()
    фиксированные = фиксированные_служебные_ссылки(контекст)
    ветка = hashlib.sha256(контекст.branch_ref.encode("utf-8")).hexdigest()
    префикс_резерваций = (
        f"{ПРОСТРАНСТВО_РЕЗЕРВАЦИЙ}/{контекст.worktree_id}/{ветка}/"
    )
    длина_объекта = len(current_head(контекст.root))
    for элемент in значение:
        if not isinstance(элемент, dict) or set(элемент) != {
            "ссылка",
            "объект",
            "действие_при_завершении",
        }:
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Служебное ограждение повреждено.")
        ссылка = элемент["ссылка"]
        объект = элемент["объект"]
        действие = элемент["действие_при_завершении"]
        if not isinstance(ссылка, str) or ссылка in ссылки:
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Служебная ссылка сброса неканонична.")
        ссылки.add(ссылка)
        ожидаемое_действие = фиксированные.get(ссылка)
        if ожидаемое_действие is None and ссылка.startswith(префикс_резерваций):
            ожидаемое_действие = "сохранить"
        if действие != ожидаемое_действие:
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Служебная ссылка сброса вне допустимой области.")
        if объект != "absent" and (
            not isinstance(объект, str)
            or re.fullmatch(r"[0-9a-f]+", объект) is None
            or len(объект) != длина_объекта
        ):
            raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Служебное ограждение имеет неверный объект.")
        проверенные.append(
            {
                "ссылка": ссылка,
                "объект": объект,
                "действие_при_завершении": действие,
            }
        )
    if ссылки.intersection(фиксированные) != set(фиксированные):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Запись сброса не покрывает обязательные ограждения.")
    if проверенные != sorted(проверенные, key=lambda элемент: элемент["ссылка"]):
        raise QueueError(EXIT_CONTEXT, "corrupt_reset", "Служебные ограждения неканоничны.")
    return проверенные


def отклонить_повреждённое_возобновление() -> NoReturn:
    raise QueueError(
        EXIT_CONTEXT,
        "corrupt_service_fence",
        "Ограждение возобновления диспетчера повреждено.",
    )


def проверить_ограждение_возобновления_для_сброса(
    контекст: QueueContext,
    ссылка: str,
    резервация: dict[str, object],
) -> dict[str, object]:
    возобновление = резервация.get("возобновление")
    if (
        not isinstance(возобновление, dict)
        or set(возобновление) != ПОЛЯ_ВОЗОБНОВЛЕНИЯ_РЕЗЕРВАЦИИ
        or type(возобновление.get("версия_схемы")) is not int
        or возобновление.get("версия_схемы") != 1
        or type(возобновление.get("поколение")) is not int
        or возобновление["поколение"] < 1
        or возобновление.get("состояние")
        not in {"вызов_мог_состояться", "подтверждено_исполнителем"}
        or type(возобновление.get("номер_попытки")) is not int
        or возобновление.get("номер_попытки") != 1
        or type(возобновление.get("предел_попыток")) is not int
        or возобновление.get("предел_попыток") != 1
        or возобновление.get("причина") != "не_определена"
        or возобновление.get("класс_наблюдения")
        != "разрыв_потока_ответа"
    ):
        отклонить_повреждённое_возобновление()
    for поле in ("не_раньше", "ограждено"):
        if not isinstance(возобновление.get(поле), str) or re.fullmatch(
            r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z",
            возобновление[поле],
        ) is None:
            отклонить_повреждённое_возобновление()
    состояние = возобновление["состояние"]
    подтверждено = возобновление.get("подтверждено")
    if состояние == "вызов_мог_состояться":
        if подтверждено is not None:
            отклонить_повреждённое_возобновление()
    elif not isinstance(подтверждено, str) or re.fullmatch(
        r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z",
        подтверждено,
    ) is None:
        отклонить_повреждённое_возобновление()
    for поле in ("ключ", "хэш_сообщения"):
        if not isinstance(возобновление.get(поле), str) or re.fullmatch(
            r"sha256:[0-9a-f]{64}",
            возобновление[поле],
        ) is None:
            отклонить_повреждённое_возобновление()
    if (
        возобновление.get("ссылка_резервации") != ссылка
        or not isinstance(возобновление.get("ссылка_очереди"), str)
        or not возобновление["ссылка_очереди"].startswith(
            "refs/fum/worktree-task-queues/"
        )
        or not isinstance(возобновление.get("ссылка_претензии"), str)
        or not возобновление["ссылка_претензии"].startswith(
            f"{ПРОСТРАНСТВО_ПРЕТЕНЗИЙ}/"
        )
    ):
        отклонить_повреждённое_возобновление()
    for поле in (
        "исходный_объект_резервации",
        "объект_очереди",
        "объект_претензии",
    ):
        if not isinstance(возобновление.get(поле), str) or re.fullmatch(
            r"(?:[0-9a-f]{40}|[0-9a-f]{64})",
            возобновление[поле],
        ) is None:
            отклонить_повреждённое_возобновление()
    наблюдение = возобновление.get("наблюдение")
    if (
        not isinstance(наблюдение, dict)
        or set(наблюдение) != ПОЛЯ_НАБЛЮДЕНИЯ_РАЗРЫВА_РЕЗЕРВАЦИИ
        or type(наблюдение.get("версия_схемы_среды")) is not int
        or наблюдение.get("версия_схемы_среды") != 1
        or наблюдение.get("состояние_задачи") not in {"idle", "notLoaded"}
        or not isinstance(наблюдение.get("идентификатор_хода"), str)
        or not наблюдение["идентификатор_хода"]
        or наблюдение.get("сообщение_ошибки")
        != СООБЩЕНИЕ_РАЗРЫВА_ПОТОКА_ОТВЕТА
    ):
        отклонить_повреждённое_возобновление()
    for поле in ("начат", "завершён", "длительность_миллисекунд"):
        число = наблюдение.get(поле)
        if type(число) not in {int, float} or not math.isfinite(число):
            отклонить_повреждённое_возобновление()
    if (
        наблюдение["начат"] > наблюдение["завершён"]
        or наблюдение["длительность_миллисекунд"] < 0
    ):
        отклонить_повреждённое_возобновление()
    конверт = возобновление.get("конверт")
    if (
        not isinstance(конверт, dict)
        or set(конверт) != ПОЛЯ_КОНВЕРТА_ВОЗОБНОВЛЕНИЯ_РЕЗЕРВАЦИИ
        or type(конверт.get("версия_схемы")) is not int
        or конверт.get("версия_схемы") != 1
        or конверт.get("ссылка_ветки") != контекст.branch_ref
        or конверт.get("идентификатор_задачи") != резервация.get("task_id")
        or конверт.get("ключ_возобновления") != возобновление["ключ"]
    ):
        отклонить_повреждённое_возобновление()
    for поле in (
        "идентификатор_задания",
        "идентификатор_попытки",
        "идентификатор_задачи",
        "поколение_очереди",
    ):
        if not isinstance(конверт.get(поле), str) or not конверт[поле]:
            отклонить_повреждённое_возобновление()
    for поле in ("поколение_спецификации", "поколение_реестра"):
        if type(конверт.get(поле)) is not int or конверт[поле] < 1:
            отклонить_повреждённое_возобновление()
    if (
        not isinstance(конверт.get("вершина_выбора"), str)
        or re.fullmatch(
            r"(?:[0-9a-f]{40}|[0-9a-f]{64})",
            конверт["вершина_выбора"],
        )
        is None
        or not isinstance(конверт.get("ключ_запуска"), str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", конверт["ключ_запуска"])
        is None
    ):
        отклонить_повреждённое_возобновление()
    return возобновление


def задачи_из_служебного_объекта(
    контекст: QueueContext,
    ссылка: str,
    объект: str,
) -> set[str]:
    вид = decoded_stdout(run_git(контекст.root, ["cat-file", "-t", объект]))
    if вид != "blob":
        raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Служебная ссылка не указывает на blob.")
    сырые = run_git(контекст.root, ["cat-file", "blob", объект]).stdout
    try:
        значение = json.loads(
            сырые.decode("utf-8", errors="strict"),
            object_pairs_hook=собрать_объект_без_повторов,
            parse_constant=отклонить_неконечное_число,
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as ошибка:
        raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Служебный blob не содержит корректный JSON.") from ошибка
    найденные: set[str] = set()

    if ссылка.startswith(f"{ПРОСТРАНСТВО_РЕЗЕРВАЦИЙ}/"):
        if not isinstance(значение, dict):
            raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Резервация запуска не является объектом.")
        фаза = значение.get("фаза")
        созданная_задача = значение.get("идентификатор_созданной_задачи")
        фактическая_задача = значение.get("task_id")
        свидетельство_среды = значение.get("свидетельство_среды")
        точная_задача_среды = None
        предварительное_свидетельство = False
        if значение.get("версия_схемы") in {3, 4} and свидетельство_среды is not None:
            if not isinstance(свидетельство_среды, dict):
                raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Host-свидетельство диспетчера повреждено.")
            if свидетельство_среды.get("вид") == "threadId":
                if set(свидетельство_среды) != {"вид", "threadId", "hostId"}:
                    raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Точное host-свидетельство диспетчера повреждено.")
                точная_задача_среды = validate_task_id(
                    свидетельство_среды.get("threadId")
                )
                if not isinstance(свидетельство_среды.get("hostId"), str) or not свидетельство_среды["hostId"]:
                    raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Точное host-свидетельство диспетчера не содержит hostId.")
                найденные.add(точная_задача_среды)
            elif свидетельство_среды.get("вид") == "clientThreadId":
                if set(свидетельство_среды) != {"вид", "значение"} or not isinstance(свидетельство_среды.get("значение"), str) or not свидетельство_среды["значение"]:
                    raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Предварительное host-свидетельство диспетчера повреждено.")
                предварительное_свидетельство = True
            else:
                raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Host-свидетельство диспетчера имеет неизвестный вид.")
        if значение.get("версия_схемы") == 4:
            возобновление = проверить_ограждение_возобновления_для_сброса(
                контекст,
                ссылка,
                значение,
            )
            if возобновление["состояние"] == "вызов_мог_состояться":
                raise QueueError(
                    EXIT_DIRTY,
                    "host_call_unresolved",
                    "Сброс запрещён, пока сообщение возобновления может быть принято позднее.",
                )
            if (
                not isinstance(возобновление.get("подтверждено"), str)
                or not возобновление["подтверждено"]
            ):
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_service_fence",
                    "Подтверждённое возобновление не имеет квитанции исполнителя.",
                )
        if фактическая_задача is not None:
            найденные.add(validate_task_id(фактическая_задача))
        if фаза == "вызов_мог_состояться" and фактическая_задача is None:
            raise QueueError(
                EXIT_DIRTY,
                "host_call_unresolved",
                "Сброс запрещён, пока host-вызов создания задачи может завершиться позднее.",
            )
        if фаза == "задача_создана":
            if not isinstance(созданная_задача, str) or not созданная_задача:
                raise QueueError(
                    EXIT_CONTEXT,
                    "corrupt_service_fence",
                    "Созданная диспетчером задача не имеет точного идентификатора.",
                )
            if точная_задача_среды is not None and созданная_задача != точная_задача_среды:
                raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Точное host-свидетельство не совпадает с резервацией диспетчера.")
            if предварительное_свидетельство and созданная_задача != свидетельство_среды["значение"]:
                raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Предварительное host-свидетельство не совпадает с резервацией диспетчера.")
            if фактическая_задача is None and точная_задача_среды is None:
                raise QueueError(
                    EXIT_DIRTY,
                    "host_call_unresolved",
                    "Нетипизированное host-свидетельство диспетчера не заменяет фактическую привязку задачи.",
                )
        elif фаза == "завершён":
            if (
                фактическая_задача is None
                and точная_задача_среды is None
                and (
                    созданная_задача is not None
                    or значение.get("исход") == "неопределённый"
                )
            ):
                raise QueueError(
                    EXIT_DIRTY,
                    "host_call_unresolved",
                    "Неопределённый host-вызов диспетчера не имеет точной созданной задачи.",
                )
        elif фаза not in {"зарезервирован", "вызов_мог_состояться"}:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_service_fence",
                "Резервация запуска имеет неизвестную host-фазу.",
            )

    if ссылка.startswith(f"{ПРОСТРАНСТВО_ПОЧИНКИ}/"):
        if (
            not isinstance(значение, dict)
            or значение.get("схема") != "fum.починка-автозапуска.v1"
        ):
            raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Ограждение починки имеет неизвестную схему.")
        фаза_починки = значение.get("состояние")
        if фаза_починки not in {
            "зарезервирован",
            "вызов_мог_состояться",
            "задача_создана",
            "исполнитель_связан",
            "исполнитель_подтверждён",
            "завершён",
        }:
            raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Починка имеет неизвестную host-фазу.")
        свидетельство = значение.get("свидетельство_среды")
        исполнитель = значение.get("исполнитель")
        фактическая_задача_починки = None
        if isinstance(исполнитель, dict) and исполнитель.get("задача") is not None:
            фактическая_задача_починки = validate_task_id(
                исполнитель["задача"]
            )
            найденные.add(фактическая_задача_починки)
        if фаза_починки == "вызов_мог_состояться":
            raise QueueError(
                EXIT_DIRTY,
                "host_call_unresolved",
                "Сброс запрещён, пока host-вызов починки может завершиться позднее.",
            )
        if свидетельство is not None:
            if not isinstance(свидетельство, dict):
                raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Починка не имеет host-свидетельства созданной задачи.")
            if свидетельство.get("вид") == "clientThreadId":
                if фактическая_задача_починки is None:
                    raise QueueError(
                        EXIT_DIRTY,
                        "host_call_unresolved",
                        "Предварительный clientThreadId не доказывает точную созданную задачу починки.",
                    )
            elif (
                свидетельство.get("вид") != "threadId"
                or not isinstance(свидетельство.get("threadId"), str)
            ):
                raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Host-свидетельство починки повреждено.")
            else:
                найденные.add(validate_task_id(свидетельство["threadId"]))
        elif фаза_починки == "задача_создана":
            raise QueueError(EXIT_CONTEXT, "corrupt_service_fence", "Починка не имеет host-свидетельства созданной задачи.")

    def обойти(узел: object) -> None:
        if isinstance(узел, dict):
            for ключ, вложенное in узел.items():
                if ключ in {"task_id", "задача"}:
                    if вложенное is not None:
                        найденные.add(validate_task_id(вложенное))
                else:
                    обойти(вложенное)
        elif isinstance(узел, list):
            for вложенное in узел:
                обойти(вложенное)

    обойти(значение)
    return найденные


def связанные_задачи_из_ограждений(
    контекст: QueueContext,
    ограждения: list[dict[str, str]],
) -> list[str]:
    задачи: set[str] = set()
    for ограждение in ограждения:
        объект = ограждение["объект"]
        if объект != "absent":
            задачи.update(
                задачи_из_служебного_объекта(
                    контекст,
                    ограждение["ссылка"],
                    объект,
                )
            )
    return sorted(задачи)


def снимок_служебных_ограждений(
    контекст: QueueContext,
) -> tuple[list[dict[str, str]], list[str]]:
    ограждения: list[dict[str, str]] = []
    for ссылка, действие in фиксированные_служебные_ссылки(контекст).items():
        ограждения.append(
            {
                "ссылка": ссылка,
                "объект": read_ref_oid(контекст, ссылка) or "absent",
                "действие_при_завершении": действие,
            }
        )
    ветка = hashlib.sha256(контекст.branch_ref.encode("utf-8")).hexdigest()
    префикс = f"{ПРОСТРАНСТВО_РЕЗЕРВАЦИЙ}/{контекст.worktree_id}/{ветка}/"
    результат = run_git(
        контекст.root,
        ["for-each-ref", "--format=%(refname)%00%(objectname)", префикс],
    )
    for строка in результат.stdout.splitlines():
        if not строка:
            continue
        ссылка_байты, объект_байты = строка.split(b"\0", 1)
        ограждения.append(
            {
                "ссылка": ссылка_байты.decode("utf-8", errors="strict"),
                "объект": объект_байты.decode("ascii", errors="strict"),
                "действие_при_завершении": "сохранить",
            }
        )
    ограждения.sort(key=lambda элемент: элемент["ссылка"])
    проверенные = проверить_служебные_ограждения(ограждения, контекст)
    return проверенные, связанные_задачи_из_ограждений(контекст, проверенные)


def данные_подтверждения_сброса(
    контекст: QueueContext,
    состояние: dict[str, object],
    объект_очереди: str | None,
    идентификатор_диспетчера: str,
) -> dict[str, object]:
    снимок_изменений = снимок_изменений_для_сброса(контекст.root)
    ограждения, связанные = снимок_служебных_ограждений(контекст)
    участники = sorted(set(участники_очереди(состояние)) | set(связанные))
    return {
        "схема": "fum.план-сброса-состояния-FIFO.1",
        "идентификатор_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "целевая_вершина": current_head(контекст.root),
        "объект_очереди": объект_очереди or "absent",
        "идентификатор_диспетчера": идентификатор_диспетчера,
        "участники": участники,
        "связанные_задачи": связанные,
        "изменённые_пути": снимок_изменений["изменённые_пути"],
        "неотслеживаемые_пути": снимок_изменений["неотслеживаемые_пути"],
        "неотслеживаемые_объекты": снимок_изменений["неотслеживаемые_объекты"],
        "отслеживаемые_объекты": снимок_изменений["отслеживаемые_объекты"],
        "отпечаток_индекса": снимок_изменений["отпечаток_индекса"],
        "отпечаток_изменений": снимок_изменений["отпечаток_изменений"],
        "служебные_ограждения": ограждения,
    }


def данные_подтверждения_из_записи(
    запись: dict[str, object],
) -> dict[str, object]:
    return {
        "схема": "fum.план-сброса-состояния-FIFO.1",
        "идентификатор_рабочей_копии": запись["идентификатор_рабочей_копии"],
        "ссылка_ветки": запись["ссылка_ветки"],
        "целевая_вершина": запись["целевая_вершина"],
        "объект_очереди": запись["исходный_объект_очереди"] or "absent",
        "идентификатор_диспетчера": запись["идентификатор_диспетчера"],
        "участники": запись["участники"],
        "связанные_задачи": запись["связанные_задачи"],
        "изменённые_пути": запись["изменённые_пути_плана"],
        "неотслеживаемые_пути": запись["неотслеживаемые_пути_плана"],
        "неотслеживаемые_объекты": запись["неотслеживаемые_объекты_плана"],
        "отслеживаемые_объекты": запись["отслеживаемые_объекты_плана"],
        "отпечаток_индекса": запись["отпечаток_индекса_плана"],
        "отпечаток_изменений": запись["отпечаток_изменений"],
        "служебные_ограждения": запись["служебные_ограждения"],
    }


def идентификатор_подтверждения_сброса(данные: dict[str, object]) -> str:
    байты = (
        json.dumps(
            данные,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")
    return f"sha256:{hashlib.sha256(байты).hexdigest()}"


def план_сброса(
    контекст: QueueContext,
    идентификатор_диспетчера: str,
) -> tuple[int, dict[str, object]]:
    validate_task_id(идентификатор_диспетчера)
    ensure_live_branch(контекст)
    вид, состояние, объект_очереди = прочитать_запись_очереди(контекст)
    if вид == "сброс":
        raise QueueError(
            КОД_ИДЁТ_СБРОС,
            "reset_in_progress",
            "В рабочей копии уже идёт штатный сброс.",
            данные_результата_операции={
                "идентификатор_сброса": состояние["идентификатор_сброса"],
                "фаза": состояние["фаза"],
            },
        )
    состояние = ensure_state_identity(
        контекст,
        состояние,
        allow_idle_rebind=True,
    )
    данные = данные_подтверждения_сброса(
        контекст,
        состояние,
        объект_очереди,
        идентификатор_диспетчера,
    )
    подтверждение = идентификатор_подтверждения_сброса(данные)
    return 0, {
        "состояние": "требуется_подтверждение",
        "подтверждение": подтверждение,
        "идентификатор_сброса": подтверждение,
        **данные,
    }


def заменить_запись_очереди_с_проверкой_ветки(
    контекст: QueueContext,
    ожидаемая_вершина: str,
    прежний_объект: str | None,
    новый_объект: str | None,
    *,
    служебные_ограждения: list[dict[str, str]] | None = None,
    завершить_служебные_ограждения: bool = False,
    дополнительные_команды: str = "",
) -> bool:
    if новый_объект is None:
        if прежний_объект is None:
            команда_очереди = ""
        else:
            команда_очереди = f"delete {контекст.queue_ref} {прежний_объект}\n"
    elif прежний_объект is None:
        команда_очереди = f"create {контекст.queue_ref} {новый_объект}\n"
    else:
        команда_очереди = (
            f"update {контекст.queue_ref} {новый_объект} {прежний_объект}\n"
        )
    команды_ограждений = ""
    for ограждение in служебные_ограждения or []:
        ссылка = ограждение["ссылка"]
        объект = ограждение["объект"]
        нулевой = "0" * len(ожидаемая_вершина)
        if (
            завершить_служебные_ограждения
            and ограждение["действие_при_завершении"] == "удалить"
            and объект != "absent"
        ):
            команды_ограждений += f"delete {ссылка} {объект}\n"
        else:
            команды_ограждений += (
                f"verify {ссылка} {нулевой if объект == 'absent' else объект}\n"
            )
    транзакция = (
        "start\n"
        f"verify {контекст.branch_ref} {ожидаемая_вершина}\n"
        f"{команды_ограждений}"
        f"{команда_очереди}"
        f"{дополнительные_команды}"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    результат = run_git(
        контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=транзакция,
        check=False,
    )
    if результат.returncode == 0:
        return True
    текущая_вершина = current_head(контекст.root)
    if текущая_вершина != ожидаемая_вершина:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "Ветка изменилась во время штатного сброса.",
            данные_результата_операции={
                "expected_head": ожидаемая_вершина,
                "current_head": текущая_вершина,
            },
        )
    if read_ref_oid(контекст, контекст.queue_ref) != прежний_объект:
        return False
    подробность = результат.stderr.decode("utf-8", errors="replace").strip()
    update_ref_error("атомарно заменить запись очереди для сброса", подробность)


def подготовить_сброс(
    контекст: QueueContext,
    идентификатор_диспетчера: str,
    ожидаемая_вершина: str,
    ожидаемый_объект_очереди: str,
    подтверждение: str,
) -> tuple[int, dict[str, object]]:
    validate_task_id(идентификатор_диспетчера)
    ensure_live_branch(контекст)
    вид, запись, объект_очереди = прочитать_запись_очереди(контекст)
    if вид == "сброс":
        if (
            запись["идентификатор_сброса"] == подтверждение
            and запись["идентификатор_диспетчера"] == идентификатор_диспетчера
        ):
            return 0, {
                "состояние": str(запись["фаза"]),
                "идентификатор_сброса": подтверждение,
                **common_payload(контекст, объект_очереди),
            }
        raise QueueError(
            КОД_ИДЁТ_СБРОС,
            "reset_in_progress",
            "Другая попытка сброса уже оградила очередь.",
        )
    исходное_состояние = запись
    состояние = ensure_state_identity(
        контекст,
        запись,
        allow_idle_rebind=True,
    )
    предоставленный_объект = (
        None if ожидаемый_объект_очереди == "absent" else ожидаемый_объект_очереди
    )
    if объект_очереди != предоставленный_объект:
        raise QueueError(
            EXIT_CAS,
            "queue_changed",
            "Объект очереди изменился после плана сброса.",
        )
    if current_head(контекст.root) != ожидаемая_вершина:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "HEAD изменился после плана сброса.",
        )
    данные = данные_подтверждения_сброса(
        контекст,
        состояние,
        объект_очереди,
        идентификатор_диспетчера,
    )
    ожидаемое_подтверждение = идентификатор_подтверждения_сброса(данные)
    if подтверждение != ожидаемое_подтверждение:
        raise QueueError(
            EXIT_CAS,
            "confirmation_mismatch",
            "Точное подтверждение не совпадает с текущим планом сброса.",
        )
    метка, _ = utc_values()
    запись_сброса: dict[str, object] = {
        "схема": СХЕМА_СБРОСА,
        "фаза": "подготовлен",
        "идентификатор_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "целевая_вершина": ожидаемая_вершина,
        "исходный_объект_очереди": объект_очереди,
        "исходное_состояние_очереди": исходное_состояние,
        "идентификатор_сброса": подтверждение,
        "идентификатор_диспетчера": идентификатор_диспетчера,
        "участники": данные["участники"],
        "связанные_задачи": данные["связанные_задачи"],
        "неактивные_задачи": [],
        "изменённые_пути_плана": данные["изменённые_пути"],
        "неотслеживаемые_пути_плана": данные["неотслеживаемые_пути"],
        "неотслеживаемые_объекты_плана": данные["неотслеживаемые_объекты"],
        "отслеживаемые_объекты_плана": данные["отслеживаемые_объекты"],
        "отпечаток_индекса_плана": данные["отпечаток_индекса"],
        "отпечаток_изменений": данные["отпечаток_изменений"],
        "служебные_ограждения": данные["служебные_ограждения"],
        "создано": метка,
        "обновлено": метка,
    }
    новый_объект = записать_объект_сброса(контекст, запись_сброса)
    if not заменить_запись_очереди_с_проверкой_ветки(
        контекст,
        ожидаемая_вершина,
        объект_очереди,
        новый_объект,
        служебные_ограждения=list(данные["служебные_ограждения"]),
    ):
        raise QueueError(EXIT_CAS, "queue_changed", "Очередь изменилась до ограждения сброса.")
    return 0, {
        "состояние": "подготовлен",
        "идентификатор_сброса": подтверждение,
        **common_payload(контекст, новый_объект),
    }


def потребовать_сброс(
    контекст: QueueContext,
    идентификатор_диспетчера: str,
    идентификатор_сброса: str,
) -> tuple[dict[str, object], str]:
    validate_task_id(идентификатор_диспетчера)
    вид, запись, объект = прочитать_запись_очереди(контекст)
    if вид != "сброс" or объект is None:
        raise QueueError(
            EXIT_NOT_REGISTERED,
            "reset_not_found",
            "Активная запись штатного сброса не найдена.",
        )
    if (
        запись["идентификатор_сброса"] != идентификатор_сброса
        or запись["идентификатор_диспетчера"] != идентификатор_диспетчера
    ):
        raise QueueError(
            EXIT_OWNERSHIP,
            "reset_not_owned",
            "Идентификаторы диспетчера и попытки не совпадают со сбросом.",
        )
    return запись, объект


def подтвердить_остановку_сессий(
    контекст: QueueContext,
    идентификатор_диспетчера: str,
    идентификатор_сброса: str,
    неактивные_задачи: list[str],
) -> tuple[int, dict[str, object]]:
    запись, прежний_объект = потребовать_сброс(
        контекст,
        идентификатор_диспетчера,
        идентификатор_сброса,
    )
    for идентификатор in неактивные_задачи:
        validate_task_id(идентификатор)
    предоставленные = set(неактивные_задачи)
    if len(предоставленные) != len(неактивные_задачи):
        raise QueueError(
            КОД_НЕСОВПАДЕНИЯ_СЕССИЙ,
            "session_set_mismatch",
            "Подтверждение содержит повтор идентификатора задачи.",
        )
    требуемые = set(запись["участники"]) - {идентификатор_диспетчера}
    if предоставленные != требуемые:
        raise QueueError(
            КОД_НЕСОВПАДЕНИЯ_СЕССИЙ,
            "session_set_mismatch",
            "Подтверждение не совпадает с точным множеством участников сброса.",
            данные_результата_операции={"требуемое_количество": len(требуемые)},
        )
    if запись["фаза"] in {"сессии_остановлены", "очистка_рабочей_копии"}:
        return 0, {
            "состояние": "сессии_остановлены",
            "идентификатор_сброса": идентификатор_сброса,
            **common_payload(контекст, прежний_объект),
        }
    обновлённая = copy.deepcopy(запись)
    обновлённая["фаза"] = "сессии_остановлены"
    обновлённая["неактивные_задачи"] = sorted(предоставленные)
    обновлённая["обновлено"] = utc_values()[0]
    новый_объект = записать_объект_сброса(контекст, обновлённая)
    if not заменить_запись_очереди_с_проверкой_ветки(
        контекст,
        str(запись["целевая_вершина"]),
        прежний_объект,
        новый_объект,
        служебные_ограждения=list(запись["служебные_ограждения"]),
    ):
        raise QueueError(EXIT_CAS, "queue_changed", "Запись сброса изменилась.")
    return 0, {
        "состояние": "сессии_остановлены",
        "идентификатор_сброса": идентификатор_сброса,
        **common_payload(контекст, новый_объект),
    }


def отменить_сброс(
    контекст: QueueContext,
    идентификатор_диспетчера: str,
    идентификатор_сброса: str,
) -> tuple[int, dict[str, object]]:
    запись, объект_сброса = потребовать_сброс(
        контекст,
        идентификатор_диспетчера,
        идентификатор_сброса,
    )
    if запись["фаза"] != "подготовлен":
        raise QueueError(
            КОД_ИДЁТ_СБРОС,
            "reset_irreversible",
            "Сброс нельзя отменить после подтверждения остановки сессий.",
        )
    исходный_объект = запись["исходный_объект_очереди"]
    if исходный_объект is not None:
        восстановленный = write_state_blob(
            контекст,
            dict(запись["исходное_состояние_очереди"]),
        )
        if восстановленный != исходный_объект:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_reset",
                "Исходное состояние не воспроизводит сохранённый объект очереди.",
            )
    if not заменить_запись_очереди_с_проверкой_ветки(
        контекст,
        str(запись["целевая_вершина"]),
        объект_сброса,
        исходный_объект if isinstance(исходный_объект, str) else None,
        служебные_ограждения=list(запись["служебные_ограждения"]),
    ):
        raise QueueError(EXIT_CAS, "queue_changed", "Запись сброса изменилась до отмены.")
    return 0, {
        "состояние": "отменён",
        "идентификатор_сброса": идентификатор_сброса,
        **common_payload(контекст, исходный_объект if isinstance(исходный_объект, str) else None),
    }


def проверить_вложенные_границы_репозиториев(корень: Path) -> None:
    изменённые = изменённые_пути_для_сброса(корень)
    индекс = run_git(
        корень,
        ["-c", "core.quotepath=false", "ls-files", "--stage", "-z"],
    )
    ссылки_на_подмодули: set[str] = set()
    for запись in индекс.stdout.split(b"\0"):
        if not запись:
            continue
        служебная, сырой_путь = запись.split(b"\t", 1)
        if служебная.split(b" ", 1)[0] == b"160000":
            ссылки_на_подмодули.add(сырой_путь.decode("utf-8", errors="surrogateescape"))
    грязные_ссылки_на_подмодули = sorted(
        путь
        for путь in ссылки_на_подмодули
        if any(
            изменённый == путь or изменённый.startswith(f"{путь}/")
            for изменённый in изменённые
        )
    )
    непроиндексированные = run_git(
        корень,
        ["-c", "core.quotepath=false", "ls-files", "--others", "--exclude-standard", "-z"],
    )
    вложенные: set[str] = set()
    for сырой_путь in непроиндексированные.stdout.split(b"\0"):
        if not сырой_путь:
            continue
        путь = корень / сырой_путь.decode("utf-8", errors="surrogateescape")
        кандидат = путь if путь.is_dir() else путь.parent
        while кандидат != корень and корень in кандидат.parents:
            if является_вложенной_границей_репозитория(кандидат):
                вложенные.add(str(кандидат.relative_to(корень)))
                break
            кандидат = кандидат.parent
    if грязные_ссылки_на_подмодули or вложенные:
        raise QueueError(
            EXIT_DIRTY,
            "nested_repository_dirty",
            "Штатный сброс не очищает грязные submodule или вложенные Git-репозитории.",
            данные_результата_операции={
                "gitlink_paths": грязные_ссылки_на_подмодули,
                "nested_repository_paths": sorted(вложенные),
            },
        )


def потребовать_подтверждённые_изменения(
    корень: Path,
    запись: dict[str, object],
) -> None:
    текущий = снимок_изменений_для_сброса(корень)
    ожидаемый = {
        "изменённые_пути": запись["изменённые_пути_плана"],
        "неотслеживаемые_пути": запись["неотслеживаемые_пути_плана"],
        "неотслеживаемые_объекты": запись["неотслеживаемые_объекты_плана"],
        "отслеживаемые_объекты": запись["отслеживаемые_объекты_плана"],
        "отпечаток_индекса": запись["отпечаток_индекса_плана"],
        "отпечаток_изменений": запись["отпечаток_изменений"],
    }
    if текущий != ожидаемый:
        raise QueueError(
            EXIT_CAS,
            "reset_plan_changed",
            "Изменения рабочей копии разошлись с подтверждённым планом сброса.",
            данные_результата_операции={
                "expected_fingerprint": ожидаемый["отпечаток_изменений"],
                "current_fingerprint": текущий["отпечаток_изменений"],
            },
        )


def индекс_совместим_с_планом_или_целью(
    корень: Path,
    запись: dict[str, object],
    целевая_вершина: str,
) -> bool:
    if отпечаток_индекса(корень) == запись["отпечаток_индекса_плана"]:
        return True
    целевое_дерево = decoded_stdout(
        run_git(корень, ["rev-parse", f"{целевая_вершина}^{{tree}}"])
    )
    текущее_дерево = run_git(корень, ["write-tree"], check=False)
    if текущее_дерево.returncode != 0:
        return False
    if decoded_stdout(текущее_дерево) != целевое_дерево:
        return False
    return True


def потребовать_совместимое_частичное_состояние_отслеживаемых(
    корень: Path,
    запись: dict[str, object],
    целевая_вершина: str,
) -> None:
    плановые_пути = set(запись["изменённые_пути_плана"]) - set(
        запись["неотслеживаемые_пути_плана"]
    )
    текущие_неотслеживаемые = set(неотслеживаемые_пути_для_сброса(корень))
    текущие_отслеживаемые = set(изменённые_пути_для_сброса(корень)) - (
        текущие_неотслеживаемые
    )
    if not текущие_отслеживаемые.issubset(плановые_пути):
        raise QueueError(
            EXIT_CAS,
            "reset_plan_changed",
            "После начала очистки появился новый отслеживаемый путь.",
            данные_результата_операции={
                "blocking_paths": sorted(текущие_отслеживаемые - плановые_пути)
            },
        )
    if not индекс_совместим_с_планом_или_целью(
        корень,
        запись,
        целевая_вершина,
    ):
        raise QueueError(
            EXIT_CAS,
            "reset_plan_changed",
            "Индекс после начала очистки не совпадает ни с планом, ни с целью.",
        )
    for объект in запись["отслеживаемые_объекты_плана"]:
        if объект["путь"] not in текущие_отслеживаемые:
            continue
        текущий = описать_состояние_отслеживаемого_пути(
            корень,
            str(объект["путь"]),
        )
        if текущий != объект["до"] and текущий != объект["цель"]:
            raise QueueError(
                EXIT_CAS,
                "reset_plan_changed",
                "Отслеживаемый путь после начала очистки не совпадает ни с планом, ни с целью.",
                данные_результата_операции={"path": объект["путь"]},
            )


def удалить_подтверждённые_неотслеживаемые_пути(
    корень: Path,
    ожидаемые: list[dict[str, str]],
    целевая_вершина: str,
) -> None:
    for ожидаемый in ожидаемые:
        путь = ожидаемый["путь"]
        if not путь_виден_гит_как_неотслеживаемый(корень, путь):
            continue
        if not os.path.lexists(корень / путь):
            continue
        текущее_состояние = описать_состояние_отслеживаемого_пути(
            корень,
            путь,
        )
        целевое_состояние = целевое_состояние_отслеживаемого_пути(
            корень,
            целевая_вершина,
            путь,
        )
        if (
            целевое_состояние["тип"] != "отсутствует"
            and текущее_состояние == целевое_состояние
        ):
            continue
        текущий, _, _ = описать_неотслеживаемый_объект(корень, путь)
        if текущий != ожидаемый:
            raise QueueError(
                EXIT_CAS,
                "reset_plan_changed",
                "Неотслеживаемый объект изменился непосредственно перед удалением.",
                данные_результата_операции={"path": путь},
            )
        run_git(
            корень,
            ["clean", "-f", "-x", "--", f":(top,literal){путь}"],
        )


def потребовать_совместимые_неотслеживаемые_объекты(
    корень: Path,
    ожидаемые: list[dict[str, str]],
    целевая_вершина: str,
) -> None:
    ожидаемые_пути = {ожидаемый["путь"] for ожидаемый in ожидаемые}
    текущие_пути = set(неотслеживаемые_пути_для_сброса(корень))
    новые_пути = sorted(текущие_пути - ожидаемые_пути)
    if новые_пути:
        raise QueueError(
            EXIT_CAS,
            "reset_plan_changed",
            "После подтверждения сброса появились новые неотслеживаемые пути.",
            данные_результата_операции={"blocking_paths": новые_пути},
        )
    for ожидаемый in ожидаемые:
        путь = ожидаемый["путь"]
        if not путь_виден_гит_как_неотслеживаемый(корень, путь):
            continue
        if not os.path.lexists(корень / путь):
            continue
        текущее_состояние = описать_состояние_отслеживаемого_пути(
            корень,
            путь,
        )
        целевое_состояние = целевое_состояние_отслеживаемого_пути(
            корень,
            целевая_вершина,
            путь,
        )
        if (
            целевое_состояние["тип"] != "отсутствует"
            and текущее_состояние == целевое_состояние
        ):
            continue
        текущий, _, _ = описать_неотслеживаемый_объект(корень, путь)
        if текущий != ожидаемый:
            raise QueueError(
                EXIT_CAS,
                "reset_plan_changed",
                "Неотслеживаемый объект изменился после подтверждения сброса.",
                данные_результата_операции={"path": путь},
            )


def применить_сброс(
    контекст: QueueContext,
    идентификатор_диспетчера: str,
    идентификатор_сброса: str,
) -> tuple[int, dict[str, object]]:
    validate_task_id(идентификатор_диспетчера)
    ensure_live_branch(контекст)
    квитанция, _ = прочитать_квитанцию_сброса(контекст, идентификатор_сброса)
    if квитанция is not None:
        if квитанция["идентификатор_диспетчера"] != идентификатор_диспетчера:
            raise QueueError(EXIT_OWNERSHIP, "reset_owned_by_other", "Квитанция сброса принадлежит другой задаче.")
        _, _, текущий_объект_очереди = прочитать_запись_очереди(контекст)
        return 0, {
            "состояние": "сброшено",
            "идентификатор_сброса": идентификатор_сброса,
            "целевая_вершина": квитанция["целевая_вершина"],
            **common_payload(контекст, текущий_объект_очереди),
        }
    вид, текущая_запись, текущий_объект = прочитать_запись_очереди(контекст)
    if вид == "очередь":
        завершение = текущая_запись.get("last_completion")
        if (
            isinstance(завершение, dict)
            and завершение.get("kind") == "reset"
            and завершение.get("task_id") == идентификатор_диспетчера
            and завершение.get("generation") == идентификатор_сброса
        ):
            return 0, {
                "состояние": "сброшено",
                "идентификатор_сброса": идентификатор_сброса,
                **common_payload(контекст, текущий_объект),
            }
        raise QueueError(EXIT_NOT_REGISTERED, "reset_not_found", "Активный сброс не найден.")
    запись, объект_сброса = потребовать_сброс(
        контекст,
        идентификатор_диспетчера,
        идентификатор_сброса,
    )
    целевая_вершина = str(запись["целевая_вершина"])
    if current_head(контекст.root) != целевая_вершина:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "Ветка изменилась после ограждения сброса.",
        )
    if запись["фаза"] not in {"сессии_остановлены", "очистка_рабочей_копии"}:
        raise QueueError(
            КОД_НЕСОВПАДЕНИЯ_СЕССИЙ,
            "sessions_not_stopped",
            "Нельзя очищать рабочую копию без точного подтверждения сессий.",
        )
    потребовать_обычные_флаги_индекса(контекст.root)
    if запись["фаза"] == "сессии_остановлены":
        потребовать_подтверждённые_изменения(контекст.root, запись)
        проверить_вложенные_границы_репозиториев(контекст.root)
        очищаемая = copy.deepcopy(запись)
        очищаемая["фаза"] = "очистка_рабочей_копии"
        очищаемая["обновлено"] = utc_values()[0]
        объект_очистки = записать_объект_сброса(контекст, очищаемая)
        if not заменить_запись_очереди_с_проверкой_ветки(
            контекст,
            целевая_вершина,
            объект_сброса,
            объект_очистки,
            служебные_ограждения=list(запись["служебные_ограждения"]),
        ):
            raise QueueError(EXIT_CAS, "queue_changed", "Запись сброса изменилась.")
        запись = очищаемая
        объект_сброса = объект_очистки
    проверить_вложенные_границы_репозиториев(контекст.root)
    потребовать_отсутствие_коллизий_игнорируемых_путей(
        контекст.root,
        целевая_вершина,
    )
    try:
        потребовать_подтверждённые_изменения(контекст.root, запись)
    except QueueError as ошибка:
        if ошибка.state != "reset_plan_changed":
            raise
        потребовать_совместимое_частичное_состояние_отслеживаемых(
            контекст.root,
            запись,
            целевая_вершина,
        )
    потребовать_совместимые_неотслеживаемые_объекты(
        контекст.root,
        list(запись["неотслеживаемые_объекты_плана"]),
        целевая_вершина,
    )
    run_git(контекст.root, ["read-tree", "--reset", "-u", целевая_вершина])
    потребовать_совместимые_неотслеживаемые_объекты(
        контекст.root,
        list(запись["неотслеживаемые_объекты_плана"]),
        целевая_вершина,
    )
    удалить_подтверждённые_неотслеживаемые_пути(
        контекст.root,
        list(запись["неотслеживаемые_объекты_плана"]),
        целевая_вершина,
    )
    if current_head(контекст.root) != целевая_вершина:
        raise QueueError(EXIT_HEAD_CHANGED, "head_changed", "HEAD изменился во время очистки.")
    блокирующие = sorted(
        set(изменённые_пути_для_сброса(контекст.root))
        | set(staged_changed_paths(контекст.root))
    )
    дерево = decoded_stdout(run_git(контекст.root, ["write-tree"]))
    целевое_дерево = decoded_stdout(
        run_git(контекст.root, ["rev-parse", f"{целевая_вершина}^{{tree}}"])
    )
    if блокирующие or дерево != целевое_дерево:
        raise QueueError(
            EXIT_DIRTY,
            "reset_incomplete",
            "Рабочая копия не приведена к точному дереву целевого коммита.",
            данные_результата_операции={"blocking_paths": блокирующие},
        )
    метка, _ = utc_values()
    новое_состояние = copy.deepcopy(запись["исходное_состояние_очереди"])
    новое_состояние["branch_ref"] = контекст.branch_ref
    новое_состояние["owner"] = None
    новое_состояние["waiting"] = []
    новое_состояние["last_completion"] = {
        "kind": "reset",
        "task_id": идентификатор_диспетчера,
        "generation": идентификатор_сброса,
        "head": целевая_вершина,
        "completed_at": метка,
        "аннулированные_задачи": list(запись["участники"]),
    }
    новое_состояние["updated_at"] = метка
    новый_объект_очереди = write_state_blob(контекст, новое_состояние)
    квитанция_сброса = {
        "схема": СХЕМА_КВИТАНЦИИ_СБРОСА,
        "идентификатор_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "идентификатор_сброса": идентификатор_сброса,
        "идентификатор_диспетчера": идентификатор_диспетчера,
        "целевая_вершина": целевая_вершина,
        "объект_записи_сброса": объект_сброса,
        "запись_сброса": copy.deepcopy(запись),
        "исходный_объект_очереди": запись["исходный_объект_очереди"],
        "объект_очереди_после": новый_объект_очереди,
        "состояние_очереди_после": copy.deepcopy(новое_состояние),
        "аннулированные_задачи": list(запись["участники"]),
        "неактивные_задачи": list(запись["неактивные_задачи"]),
        "предыдущее_завершение": запись["исходное_состояние_очереди"].get("last_completion"),
        "завершено": метка,
    }
    объект_квитанции = записать_объект_квитанции_сброса(контекст, квитанция_сброса)
    ссылка_квитанции = ссылка_квитанции_сброса(контекст, идентификатор_сброса)
    if read_ref_oid(контекст, ссылка_квитанции) is not None:
        raise QueueError(EXIT_CAS, "reset_receipt_exists", "Квитанция этого сброса уже существует.")
    if not заменить_запись_очереди_с_проверкой_ветки(
        контекст,
        целевая_вершина,
        объект_сброса,
        новый_объект_очереди,
        служебные_ограждения=list(запись["служебные_ограждения"]),
        завершить_служебные_ограждения=True,
        дополнительные_команды=f"create {ссылка_квитанции} {объект_квитанции}\n",
    ):
        raise QueueError(EXIT_CAS, "queue_changed", "Запись сброса изменилась перед финалом.")
    return 0, {
        "состояние": "сброшено",
        "идентификатор_сброса": идентификатор_сброса,
        "целевая_вершина": целевая_вершина,
        **common_payload(контекст, новый_объект_очереди),
    }


def состояние_сброса(контекст: QueueContext) -> tuple[int, dict[str, object]]:
    ensure_live_branch(контекст)
    вид, запись, объект = прочитать_запись_очереди(контекст)
    if вид == "сброс":
        return 0, {
            "состояние": запись["фаза"],
            "идентификатор_сброса": запись["идентификатор_сброса"],
            "целевая_вершина": запись["целевая_вершина"],
            "участники": запись["участники"],
            "неактивные_задачи": запись["неактивные_задачи"],
            **common_payload(контекст, объект),
        }
    завершение = запись.get("last_completion")
    if isinstance(завершение, dict) and завершение.get("kind") == "reset":
        return 0, {
            "состояние": "завершён",
            "идентификатор_сброса": завершение["generation"],
            "целевая_вершина": завершение["head"],
            **common_payload(контекст, объект),
        }
    return 0, {"состояние": "отсутствует", **common_payload(контекст, объект)}


def хэш_ветки_простого_сброса(контекст: QueueContext) -> str:
    return hashlib.sha256(контекст.branch_ref.encode("utf-8")).hexdigest()


def основа_ссылок_простого_сброса(контекст: QueueContext) -> str:
    return (
        f"{контекст.worktree_id}/"
        f"{хэш_ветки_простого_сброса(контекст)}"
    )


def ссылка_границы_простого_сброса(контекст: QueueContext) -> str:
    return (
        f"{ПРОСТРАНСТВО_ГРАНИЦ_ПРОСТОГО_СБРОСА}/"
        f"{основа_ссылок_простого_сброса(контекст)}"
    )


def ссылка_эпохи_простого_сброса(контекст: QueueContext) -> str:
    return (
        f"{ПРОСТРАНСТВО_ЭПОХ_РЕЗЕРВАЦИЙ}/"
        f"{основа_ссылок_простого_сброса(контекст)}"
    )


def ссылка_аннулированной_задачи(
    контекст: QueueContext,
    идентификатор_задачи: str,
) -> str:
    validate_task_id(идентификатор_задачи)
    отпечаток = hashlib.sha256(идентификатор_задачи.encode("utf-8")).hexdigest()
    return (
        f"{ПРОСТРАНСТВО_АННУЛИРОВАННЫХ_ЗАДАЧ}/"
        f"{контекст.worktree_id}/{отпечаток}"
    )


def записать_канонический_объект_данных(
    контекст: QueueContext,
    значение: dict[str, object],
) -> str:
    результат = run_git(
        контекст.root,
        ["hash-object", "-w", "--stdin"],
        input_bytes=canonical_state_bytes(значение),
    )
    return decoded_stdout(результат)


def вычислить_канонический_объект_данных(
    контекст: QueueContext,
    значение: dict[str, object],
) -> str:
    результат = run_git(
        контекст.root,
        ["hash-object", "--stdin"],
        input_bytes=canonical_state_bytes(значение),
    )
    return decoded_stdout(результат)


def попытаться_прочитать_объект_данных(
    контекст: QueueContext,
    объект: str,
) -> object | None:
    результат = run_git(
        контекст.root,
        ["cat-file", "blob", объект],
        check=False,
    )
    if результат.returncode != 0:
        return None
    try:
        return json.loads(
            результат.stdout.decode("utf-8", errors="strict"),
            object_pairs_hook=собрать_объект_без_повторов,
            parse_constant=отклонить_неконечное_число,
        )
    except (UnicodeDecodeError, json.JSONDecodeError, QueueError):
        return None


def прочитать_канонический_объект_данных(
    контекст: QueueContext,
    объект: str,
    *,
    состояние_ошибки: str,
    пояснение: str,
) -> dict[str, object]:
    результат = run_git(
        контекст.root,
        ["cat-file", "blob", объект],
        check=False,
    )
    if результат.returncode != 0:
        raise QueueError(EXIT_CONTEXT, состояние_ошибки, пояснение)
    try:
        значение = json.loads(
            результат.stdout.decode("utf-8", errors="strict"),
            object_pairs_hook=собрать_объект_без_повторов,
            parse_constant=отклонить_неконечное_число,
        )
    except (UnicodeDecodeError, json.JSONDecodeError, QueueError) as ошибка:
        raise QueueError(EXIT_CONTEXT, состояние_ошибки, пояснение) from ошибка
    if not isinstance(значение, dict) or результат.stdout != canonical_state_bytes(значение):
        raise QueueError(EXIT_CONTEXT, состояние_ошибки, пояснение)
    return значение


def действие_со_ссылкой_простого_сброса(
    контекст: QueueContext,
    ссылка: str,
) -> str:
    if ссылка == ссылка_эпохи_простого_сброса(контекст):
        return "повернуть_эпоху"
    if ссылка == ссылка_границы_простого_сброса(контекст):
        return "обновить_границу"
    имя_пространства = ссылка.removeprefix("refs/fum/").split("/", 1)[0]
    if имя_пространства in АРХИВНЫЕ_ПРОСТРАНСТВА_ПРОСТОГО_СБРОСА:
        return "сохранить"
    return "удалить"


def официальная_квитанция_сброса_пригодна(
    контекст: QueueContext,
    ссылка: str,
    объект: str,
) -> bool:
    if not ссылка.startswith(f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_СБРОСА}/"):
        return False
    try:
        квитанция = прочитать_канонический_объект_данных(
            контекст,
            объект,
            состояние_ошибки="corrupt_reset_receipt",
            пояснение="Официальная квитанция сброса повреждена.",
        )
        проверенная = проверить_квитанцию_сброса(квитанция, контекст)
        return ссылка == ссылка_квитанции_сброса(
            контекст,
            str(проверенная["идентификатор_сброса"]),
        )
    except QueueError:
        return False


def сырой_инвентарь_ссылок_простого_сброса(
    контекст: QueueContext,
) -> list[dict[str, str]]:
    результат = run_git(
        контекст.root,
        ["for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/"],
    )
    основа = основа_ссылок_простого_сброса(контекст)
    инвентарь: list[dict[str, str]] = []
    for строка in результат.stdout.splitlines():
        if not строка:
            continue
        try:
            сырая_ссылка, сырой_объект = строка.split(b"\0", 1)
            ссылка = сырая_ссылка.decode("utf-8", errors="strict")
            объект = сырой_объект.decode("ascii", errors="strict")
        except (ValueError, UnicodeDecodeError) as ошибка:
            raise QueueError(EXIT_CONTEXT, "git_error", "Git вернул неверный инвентарь ссылок.") from ошибка
        части = ссылка.removeprefix("refs/fum/").split("/")
        if len(части) < 3 or "/".join(части[1:3]) != основа:
            continue
        действие = действие_со_ссылкой_простого_сброса(контекст, ссылка)
        if ссылка.startswith(f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_СБРОСА}/"):
            действие = (
                "сохранить"
                if официальная_квитанция_сброса_пригодна(контекст, ссылка, объект)
                else "удалить"
            )
        инвентарь.append(
            {
                "ссылка": ссылка,
                "объект": объект,
                "действие": действие,
            }
        )
    return sorted(инвентарь, key=lambda элемент: элемент["ссылка"])


def добавить_идентификаторы_задач_из_данных(
    значение: object,
    найденные: set[str],
) -> None:
    if isinstance(значение, dict):
        if (
            set(значение) == {"вид", "threadId", "hostId"}
            and значение.get("вид") == "threadId"
            and isinstance(значение.get("hostId"), str)
            and значение["hostId"]
        ):
            try:
                найденные.add(validate_task_id(значение.get("threadId")))
            except QueueError:
                pass
        for ключ, вложенное in значение.items():
            if ключ in {"task_id", "задача", "идентификатор_созданной_задачи"}:
                try:
                    найденные.add(validate_task_id(вложенное))
                except QueueError:
                    pass
            добавить_идентификаторы_задач_из_данных(вложенное, найденные)
    elif isinstance(значение, list):
        for вложенное in значение:
            добавить_идентификаторы_задач_из_данных(вложенное, найденные)


def исходные_участники_и_цепочка_простого_сброса(
    контекст: QueueContext,
    объект_очереди: str | None,
    инвентарь: list[dict[str, str]],
) -> tuple[list[str], dict[str, object] | None]:
    участники: set[str] = set()
    цепочка: dict[str, object] | None = None
    значение_очереди = (
        попытаться_прочитать_объект_данных(контекст, объект_очереди)
        if объект_очереди is not None
        else None
    )
    try:
        проверенная_очередь = validate_state(значение_очереди)
    except QueueError:
        проверенная_очередь = None
    if проверенная_очередь is not None:
        участники.update(участники_очереди(проверенная_очередь))
        кандидат = проверенная_очередь.get("текущая_цепочка")
        if (
            кандидат is not None
            and проверенная_очередь.get("worktree_id") == контекст.worktree_id
            and проверенная_очередь.get("branch_ref") == контекст.branch_ref
        ):
            цепочка = copy.deepcopy(проверенная_очередь["текущая_цепочка"])
    elif значение_очереди is not None:
        добавить_идентификаторы_задач_из_данных(значение_очереди, участники)
    for запись in инвентарь:
        if запись["действие"] == "сохранить":
            continue
        значение = попытаться_прочитать_объект_данных(контекст, запись["объект"])
        if значение is not None:
            добавить_идентификаторы_задач_из_данных(значение, участники)
    return sorted(участники), цепочка


def идентификатор_плана_простого_сброса(план: dict[str, object]) -> str:
    данные = copy.deepcopy(план)
    данные.pop("идентификатор_сброса", None)
    return f"sha256:{hashlib.sha256(canonical_state_bytes(данные)).hexdigest()}"


def проверить_план_простого_сброса(
    план: object,
    контекст: QueueContext,
) -> dict[str, object]:
    ожидаемые_поля = {
        "схема",
        "идентификатор_рабочей_копии",
        "ссылка_ветки",
        "целевая_вершина",
        "исходный_объект_очереди",
        "служебные_ссылки",
        "участники",
        "текущая_цепочка",
        "изменённые_пути_плана",
        "неотслеживаемые_пути_плана",
        "неотслеживаемые_объекты_плана",
        "отслеживаемые_объекты_плана",
        "отпечаток_индекса_плана",
        "отпечаток_изменений",
        "идентификатор_сброса",
    }
    if (
        not isinstance(план, dict)
        or set(план) != ожидаемые_поля
        or план.get("схема") != СХЕМА_ПЛАНА_ПРОСТОГО_СБРОСА
        or план.get("идентификатор_рабочей_копии") != контекст.worktree_id
        or план.get("ссылка_ветки") != контекст.branch_ref
        or план.get("идентификатор_сброса") != идентификатор_плана_простого_сброса(план)
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset", "План простого сброса повреждён.")
    if not isinstance(план["участники"], list) or план["участники"] != sorted(set(план["участники"])):
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset", "План простого сброса имеет неверных участников.")
    for участник in план["участники"]:
        validate_task_id(участник)
    if not isinstance(план["служебные_ссылки"], list):
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset", "План простого сброса не имеет инвентаря.")
    if план["текущая_цепочка"] is not None:
        проверить_текущую_цепочку(план["текущая_цепочка"], контекст.branch_ref)
    return план


def построить_новый_план_простого_сброса(
    контекст: QueueContext,
) -> dict[str, object]:
    ensure_live_branch(контекст)
    вершина = current_head(контекст.root)
    объект_очереди = read_ref_oid(контекст, контекст.queue_ref)
    значение_очереди = (
        попытаться_прочитать_объект_данных(контекст, объект_очереди)
        if объект_очереди is not None
        else None
    )
    if (
        isinstance(значение_очереди, dict)
        and значение_очереди.get("схема")
        == СХЕМА_ПЕРЕХОДА_НА_ЦЕПОЧКУ
    ):
        try:
            проверить_запись_перехода_на_цепочку(
                значение_очереди,
                контекст,
            )
        except QueueError:
            pass
        else:
            raise QueueError(
                КОД_ИДЁТ_ПЕРЕХОД_НА_ЦЕПОЧКУ,
                "chain_transition_in_progress",
                "Простой сброс запрещён до завершения активного перехода на цепочку.",
            )
    инвентарь = сырой_инвентарь_ссылок_простого_сброса(контекст)
    участники, цепочка = исходные_участники_и_цепочка_простого_сброса(
        контекст,
        объект_очереди,
        инвентарь,
    )
    изменения = снимок_изменений_для_сброса(контекст.root)
    план: dict[str, object] = {
        "схема": СХЕМА_ПЛАНА_ПРОСТОГО_СБРОСА,
        "идентификатор_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "целевая_вершина": вершина,
        "исходный_объект_очереди": объект_очереди or "absent",
        "служебные_ссылки": инвентарь,
        "участники": участники,
        "текущая_цепочка": цепочка,
        "изменённые_пути_плана": изменения["изменённые_пути"],
        "неотслеживаемые_пути_плана": изменения["неотслеживаемые_пути"],
        "неотслеживаемые_объекты_плана": изменения["неотслеживаемые_объекты"],
        "отслеживаемые_объекты_плана": изменения["отслеживаемые_объекты"],
        "отпечаток_индекса_плана": изменения["отпечаток_индекса"],
        "отпечаток_изменений": изменения["отпечаток_изменений"],
    }
    план["идентификатор_сброса"] = идентификатор_плана_простого_сброса(план)
    return проверить_план_простого_сброса(план, контекст)


def основа_снимка_простого_сброса(
    контекст: QueueContext,
    идентификатор_сброса: str,
) -> str:
    if re.fullmatch(r"sha256:[0-9a-f]{64}", идентификатор_сброса) is None:
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset", "Неверен идентификатор простого сброса.")
    return (
        f"{ПРОСТРАНСТВО_СНИМКОВ_ПРОСТОГО_СБРОСА}/"
        f"{основа_ссылок_простого_сброса(контекст)}/"
        f"{идентификатор_сброса.removeprefix('sha256:')}"
    )


def прямые_резервные_ссылки_простого_сброса(
    контекст: QueueContext,
    план: dict[str, object],
) -> list[dict[str, str]]:
    источники: list[tuple[str, str]] = []
    if план["исходный_объект_очереди"] != "absent":
        источники.append(
            (контекст.queue_ref, str(план["исходный_объект_очереди"]))
        )
    for запись in план["служебные_ссылки"]:
        if запись["действие"] != "сохранить":
            источники.append((запись["ссылка"], запись["объект"]))
    основа = основа_снимка_простого_сброса(
        контекст,
        str(план["идентификатор_сброса"]),
    )
    return [
        {
            "исходная_ссылка": ссылка,
            "исходный_объект": объект,
            "резервная_ссылка": (
                f"{основа}/объекты/"
                f"{hashlib.sha256(ссылка.encode('utf-8')).hexdigest()}"
            ),
        }
        for ссылка, объект in sorted(источники)
    ]


def записи_границ_простого_сброса(
    контекст: QueueContext,
    план: dict[str, object],
    метка: str,
) -> tuple[dict[str, object], dict[str, object]]:
    общие_поля: dict[str, object] = {
        "идентичность_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "целевая_вершина": план["целевая_вершина"],
        "идентификатор_сброса": план["идентификатор_сброса"],
        "создано": метка,
    }
    return (
        {"схема": СХЕМА_ГРАНИЦЫ_ПРОСТОГО_СБРОСА, **общие_поля},
        {"схема": СХЕМА_ГРАНИЦЫ_ЭПОХИ_ПРОСТОГО_СБРОСА, **общие_поля},
    )


def проверить_снимок_простого_сброса(
    снимок: object,
    контекст: QueueContext,
) -> dict[str, object]:
    поля = {
        "схема",
        "план",
        "прямые_резервные_ссылки",
        "ссылка_манифеста",
        "ссылка_границы",
        "объект_границы",
        "ссылка_эпохи",
        "объект_эпохи",
        "создано",
    }
    if not isinstance(снимок, dict) or set(снимок) != поля or снимок.get("схема") != СХЕМА_СНИМКА_ПРОСТОГО_СБРОСА:
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset_snapshot", "Манифест простого сброса повреждён.")
    план = проверить_план_простого_сброса(снимок["план"], контекст)
    основа = основа_снимка_простого_сброса(контекст, str(план["идентификатор_сброса"]))
    if (
        снимок["ссылка_манифеста"] != f"{основа}/манифест"
        or снимок["ссылка_границы"] != ссылка_границы_простого_сброса(контекст)
        or снимок["ссылка_эпохи"] != ссылка_эпохи_простого_сброса(контекст)
        or снимок["прямые_резервные_ссылки"] != прямые_резервные_ссылки_простого_сброса(контекст, план)
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset_snapshot", "Манифест простого сброса не воспроизводит план.")
    return снимок


def прочитать_активный_простой_сброс(
    контекст: QueueContext,
) -> tuple[dict[str, object], str, dict[str, object]] | None:
    объект_очереди = read_ref_oid(контекст, контекст.queue_ref)
    if объект_очереди is None:
        return None
    значение = попытаться_прочитать_объект_данных(контекст, объект_очереди)
    if not isinstance(значение, dict) or значение.get("схема") != СХЕМА_ПРОСТОГО_СБРОСА:
        return None
    маркер = проверить_запись_простого_сброса(значение, контекст)
    if маркер["целевая_вершина"] != current_head(контекст.root):
        raise QueueError(EXIT_HEAD_CHANGED, "head_changed", "HEAD изменился во время простого сброса.")
    if read_ref_oid(контекст, str(маркер["ссылка_снимка"])) != маркер["объект_снимка"]:
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset_snapshot", "Ссылка манифеста простого сброса изменилась.")
    снимок = прочитать_канонический_объект_данных(
        контекст,
        str(маркер["объект_снимка"]),
        состояние_ошибки="corrupt_simple_reset_snapshot",
        пояснение="Манифест простого сброса повреждён.",
    )
    снимок = проверить_снимок_простого_сброса(снимок, контекст)
    план = снимок["план"]
    if any(
        (
            маркер["идентификатор_сброса"] != план["идентификатор_сброса"],
            маркер["целевая_вершина"] != план["целевая_вершина"],
            маркер["исходный_объект_очереди"] != план["исходный_объект_очереди"],
            маркер["участники"] != план["участники"],
            маркер["текущая_цепочка"] != план["текущая_цепочка"],
        )
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset", "Маркер простого сброса не совпадает с манифестом.")
    return маркер, объект_очереди, снимок


def план_простого_сброса(контекст: QueueContext) -> dict[str, object]:
    ensure_live_branch(контекст)
    активный = прочитать_активный_простой_сброс(контекст)
    if активный is not None:
        return copy.deepcopy(активный[2]["план"])
    return построить_новый_план_простого_сброса(контекст)


def фраза_подтверждения_простого_сброса(план: dict[str, object]) -> str:
    return (
        "СБРОСИТЬ FIFO И РАБОЧУЮ КОПИЮ К HEAD "
        f"{план['целевая_вершина']} "
        f"{план['идентификатор_сброса']}"
    )


def команда_замены_ссылки(
    ссылка: str,
    прежний_объект: str | None,
    новый_объект: str | None,
) -> str:
    if новый_объект is None:
        return "" if прежний_объект is None else f"delete {ссылка} {прежний_объект}\n"
    if прежний_объект is None:
        return f"create {ссылка} {новый_объект}\n"
    return f"update {ссылка} {новый_объект} {прежний_объект}\n"


def выполнить_транзакцию_простого_сброса(
    контекст: QueueContext,
    команды: str,
    ожидаемая_вершина: str,
) -> None:
    if (
        current_head(контекст.root) != ожидаемая_вершина
        or read_ref_oid(контекст, контекст.branch_ref)
        != ожидаемая_вершина
    ):
        raise QueueError(
            EXIT_CAS,
            "reset_plan_changed",
            "HEAD или ветка изменились во время простого сброса.",
        )
    ограждённые_команды = (
        f"symref-verify HEAD {контекст.branch_ref}\n"
        + команды
    )
    результат = run_git(
        контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=(
            "start\n"
            + ограждённые_команды
            + "prepare\ncommit\n"
        ).encode("utf-8"),
        check=False,
    )
    if результат.returncode != 0:
        raise QueueError(
            EXIT_CAS,
            "reset_plan_changed",
            "Ссылки или HEAD изменились во время простого сброса.",
            данные_результата_операции={"git_stderr": результат.stderr.decode("utf-8", errors="replace").strip()},
        )


def начать_простой_сброс(
    контекст: QueueContext,
    план: dict[str, object],
) -> tuple[dict[str, object], str, dict[str, object]]:
    повторный_план = построить_новый_план_простого_сброса(контекст)
    if canonical_state_bytes(повторный_план) != canonical_state_bytes(план):
        raise QueueError(EXIT_CAS, "reset_plan_changed", "План простого сброса изменился после подтверждения.")
    метка = utc_values()[0]
    граница, граница_эпохи = записи_границ_простого_сброса(контекст, план, метка)
    объект_границы = записать_канонический_объект_данных(контекст, граница)
    объект_эпохи = записать_канонический_объект_данных(контекст, граница_эпохи)
    прямые_ссылки = прямые_резервные_ссылки_простого_сброса(контекст, план)
    основа_снимка = основа_снимка_простого_сброса(контекст, str(план["идентификатор_сброса"]))
    снимок: dict[str, object] = {
        "схема": СХЕМА_СНИМКА_ПРОСТОГО_СБРОСА,
        "план": copy.deepcopy(план),
        "прямые_резервные_ссылки": прямые_ссылки,
        "ссылка_манифеста": f"{основа_снимка}/манифест",
        "ссылка_границы": ссылка_границы_простого_сброса(контекст),
        "объект_границы": объект_границы,
        "ссылка_эпохи": ссылка_эпохи_простого_сброса(контекст),
        "объект_эпохи": объект_эпохи,
        "создано": метка,
    }
    объект_снимка = записать_канонический_объект_данных(контекст, снимок)
    маркер: dict[str, object] = {
        "схема": СХЕМА_ПРОСТОГО_СБРОСА,
        "фаза": "очистка_рабочей_копии",
        "идентификатор_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "целевая_вершина": план["целевая_вершина"],
        "исходный_объект_очереди": план["исходный_объект_очереди"],
        "идентификатор_сброса": план["идентификатор_сброса"],
        "идентификатор_диспетчера": "человек",
        "участники": план["участники"],
        "неактивные_задачи": [],
        "изменённые_пути_плана": план["изменённые_пути_плана"],
        "ссылка_снимка": снимок["ссылка_манифеста"],
        "объект_снимка": объект_снимка,
        "текущая_цепочка": план["текущая_цепочка"],
        "создано": метка,
    }
    объект_маркера = записать_канонический_объект_данных(контекст, маркер)
    карта_инвентаря = {запись["ссылка"]: запись for запись in план["служебные_ссылки"]}
    ссылка_границы = str(снимок["ссылка_границы"])
    ссылка_эпохи = str(снимок["ссылка_эпохи"])
    команды = ""
    нулевой_объект = "0" * len(str(план["целевая_вершина"]))
    for обязательная_ссылка in фиксированные_служебные_ссылки(контекст):
        if (
            обязательная_ссылка not in карта_инвентаря
            and обязательная_ссылка not in {ссылка_границы, ссылка_эпохи}
        ):
            команды += f"verify {обязательная_ссылка} {нулевой_объект}\n"
    for запись in план["служебные_ссылки"]:
        if запись["ссылка"] not in {ссылка_границы, ссылка_эпохи}:
            команды += f"verify {запись['ссылка']} {запись['объект']}\n"
    прежний_объект_границы = карта_инвентаря.get(ссылка_границы, {}).get("объект")
    прежний_объект_эпохи = карта_инвентаря.get(ссылка_эпохи, {}).get("объект")
    команды += команда_замены_ссылки(ссылка_границы, прежний_объект_границы, объект_границы)
    команды += команда_замены_ссылки(ссылка_эпохи, прежний_объект_эпохи, объект_эпохи)
    команды += команда_замены_ссылки(
        контекст.queue_ref,
        None if план["исходный_объект_очереди"] == "absent" else str(план["исходный_объект_очереди"]),
        объект_маркера,
    )
    команды += f"create {снимок['ссылка_манифеста']} {объект_снимка}\n"
    for резерв in прямые_ссылки:
        команды += f"create {резерв['резервная_ссылка']} {резерв['исходный_объект']}\n"
    выполнить_транзакцию_простого_сброса(
        контекст,
        команды,
        str(план["целевая_вершина"]),
    )
    return маркер, объект_маркера, снимок


def ожидаемые_ссылки_после_маркера(
    снимок: dict[str, object],
    объект_снимка: str,
) -> dict[str, str]:
    план = снимок["план"]
    ожидаемые = {
        запись["ссылка"]: запись["объект"]
        for запись in план["служебные_ссылки"]
    }
    ожидаемые[str(снимок["ссылка_границы"])] = str(снимок["объект_границы"])
    ожидаемые[str(снимок["ссылка_эпохи"])] = str(снимок["объект_эпохи"])
    ожидаемые[str(снимок["ссылка_манифеста"])] = объект_снимка
    for резерв in снимок["прямые_резервные_ссылки"]:
        ожидаемые[резерв["резервная_ссылка"]] = резерв["исходный_объект"]
    return ожидаемые


def потребовать_неизменные_ссылки_после_маркера(
    контекст: QueueContext,
    маркер: dict[str, object],
    объект_маркера: str,
    снимок: dict[str, object],
) -> None:
    if current_head(контекст.root) != маркер["целевая_вершина"]:
        raise QueueError(EXIT_HEAD_CHANGED, "head_changed", "HEAD изменился во время простого сброса.")
    if read_ref_oid(контекст, контекст.queue_ref) != объект_маркера:
        raise QueueError(EXIT_CAS, "reset_record_changed", "Маркер простого сброса изменился.")
    текущие = {
        запись["ссылка"]: запись["объект"]
        for запись in сырой_инвентарь_ссылок_простого_сброса(контекст)
    }
    ожидаемые = ожидаемые_ссылки_после_маркера(
        снимок,
        str(маркер["объект_снимка"]),
    )
    if текущие != ожидаемые:
        raise QueueError(
            EXIT_CAS,
            "simple_reset_runtime_changed",
            "Набор служебных ссылок изменился после маркера сброса.",
            данные_результата_операции={
                "новые_ссылки": sorted(set(текущие) - set(ожидаемые)),
                "исчезнувшие_ссылки": sorted(set(ожидаемые) - set(текущие)),
            },
        )


def запись_аннулирования_задачи(
    контекст: QueueContext,
    план: dict[str, object],
    идентификатор_задачи: str,
    метка: str,
) -> dict[str, object]:
    return {
        "схема": СХЕМА_АННУЛИРОВАННОЙ_ЗАДАЧИ,
        "идентичность_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "целевая_вершина": план["целевая_вершина"],
        "идентификатор_сброса": план["идентификатор_сброса"],
        "идентификатор_задачи": идентификатор_задачи,
        "исходный_объект_очереди": план["исходный_объект_очереди"],
        "создано": метка,
    }


def прочитать_аннулирование_задачи(
    контекст: QueueContext,
    идентификатор_задачи: str,
) -> tuple[dict[str, object] | None, str | None]:
    ссылка = ссылка_аннулированной_задачи(контекст, идентификатор_задачи)
    объект = read_ref_oid(контекст, ссылка)
    if объект is None:
        return None, None
    запись = прочитать_канонический_объект_данных(
        контекст,
        объект,
        состояние_ошибки="corrupt_simple_reset_tombstone",
        пояснение="Запись аннулирования задачи повреждена.",
    )
    ожидаемые_поля = {
        "схема",
        "идентичность_рабочей_копии",
        "ссылка_ветки",
        "целевая_вершина",
        "идентификатор_сброса",
        "идентификатор_задачи",
        "исходный_объект_очереди",
        "создано",
    }
    длина_объекта = len(current_head(контекст.root))
    исходный_объект = запись.get("исходный_объект_очереди")
    if (
        set(запись) != ожидаемые_поля
        or запись.get("схема") != СХЕМА_АННУЛИРОВАННОЙ_ЗАДАЧИ
        or запись.get("идентичность_рабочей_копии") != контекст.worktree_id
        or not isinstance(запись.get("ссылка_ветки"), str)
        or not str(запись["ссылка_ветки"]).startswith("refs/heads/")
        or запись.get("идентификатор_задачи") != идентификатор_задачи
        or not isinstance(запись.get("целевая_вершина"), str)
        or re.fullmatch(r"[0-9a-f]+", str(запись["целевая_вершина"])) is None
        or len(str(запись["целевая_вершина"])) != длина_объекта
        or not isinstance(запись.get("идентификатор_сброса"), str)
        or re.fullmatch(
            r"sha256:[0-9a-f]{64}",
            str(запись["идентификатор_сброса"]),
        )
        is None
        or (
            исходный_объект != "absent"
            and (
                not isinstance(исходный_объект, str)
                or re.fullmatch(r"[0-9a-f]+", исходный_объект) is None
                or len(исходный_объект) != длина_объекта
            )
        )
        or not isinstance(запись.get("создано"), str)
        or not запись["создано"]
    ):
        raise QueueError(EXIT_CONTEXT, "corrupt_simple_reset_tombstone", "Запись аннулирования задачи не совпадает с контекстом.")
    return запись, объект


def потребовать_неаннулированную_задачу(
    контекст: QueueContext,
    идентификатор_задачи: str,
) -> None:
    запись, _ = прочитать_аннулирование_задачи(контекст, идентификатор_задачи)
    if запись is not None:
        raise QueueError(
            EXIT_NOT_REGISTERED,
            "task_annulled_by_simple_reset",
            "Прежняя задача аннулирована простым сбросом FIFO.",
            данные_результата_операции={"идентификатор_сброса": запись["идентификатор_сброса"]},
        )


def сравнить_очередь_при_отсутствии_аннулирования(
    контекст: QueueContext,
    прежний_объект_очереди: str | None,
    состояние: dict[str, object],
    идентификатор_задачи: str,
    ожидаемый_объект_реестра_барьеров: str | None,
    ожидаемая_базовая_вершина_барьера: str | None,
    ссылка_маршрута: str,
    объект_маршрута: str,
    прежний_объект_маршрута: str | None,
) -> tuple[bool, str]:
    новый_объект_очереди = write_state_blob(контекст, состояние)
    ссылка_аннулирования = ссылка_аннулированной_задачи(контекст, идентификатор_задачи)
    нулевой_объект = "0" * len(current_head(контекст.root))
    команды = f"verify {ссылка_аннулирования} {нулевой_объект}\n"
    команды += команда_маршрута_задачи(
        ссылка_маршрута,
        объект_маршрута,
        прежний_объект_маршрута,
    )
    команды += (
        f"verify {ссылка_реестра_барьеров_предактивации(контекст)} "
        f"{ожидаемый_объект_реестра_барьеров or нулевой_объект}\n"
    )
    if ожидаемая_базовая_вершина_барьера is not None:
        команды += (
            f"verify {контекст.branch_ref} "
            f"{ожидаемая_базовая_вершина_барьера}\n"
        )
    команды += команда_замены_ссылки(
        контекст.queue_ref,
        прежний_объект_очереди,
        новый_объект_очереди,
    )
    результат = run_git(
        контекст.root,
        ["update-ref", "--no-deref", "--stdin"],
        input_bytes=("start\n" + команды + "prepare\ncommit\n").encode("utf-8"),
        check=False,
    )
    if результат.returncode == 0:
        try:
            ensure_live_branch(контекст)
        except QueueError:
            восстановить_очередь_и_новый_маршрут_после_смены_ветки(
                контекст,
                прежний_объект_очереди,
                новый_объект_очереди,
                ссылка_маршрута,
                объект_маршрута,
                прежний_объект_маршрута,
            )
            raise
        return True, новый_объект_очереди
    потребовать_неаннулированную_задачу(контекст, идентификатор_задачи)
    ensure_live_branch(контекст)
    _, _, наблюдаемый_объект_маршрута = подготовить_маршрут_обычной_очереди(
        контекст,
        идентификатор_задачи,
    )
    if наблюдаемый_объект_маршрута != прежний_объект_маршрута:
        return False, новый_объект_очереди
    if read_ref_oid(контекст, контекст.queue_ref) != прежний_объект_очереди:
        return False, новый_объект_очереди
    if (
        read_ref_oid(
            контекст,
            ссылка_реестра_барьеров_предактивации(контекст),
        )
        != ожидаемый_объект_реестра_барьеров
    ):
        return False, новый_объект_очереди
    if (
        ожидаемая_базовая_вершина_барьера is not None
        and read_ref_oid(контекст, контекст.branch_ref)
        != ожидаемая_базовая_вершина_барьера
    ):
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "несовпавшая_вершина_барьера",
            "Ветка сдвинулась после корневой активации и до первого exact join.",
        )
    update_ref_error(
        "атомарно зарегистрировать задачу при отсутствии аннулирования",
        результат.stderr.decode("utf-8", errors="replace").strip(),
    )


def ссылка_квитанции_простого_сброса(
    контекст: QueueContext,
    идентификатор_сброса: str,
) -> str:
    return (
        f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_ПРОСТОГО_СБРОСА}/"
        f"{основа_ссылок_простого_сброса(контекст)}/"
        f"{идентификатор_сброса.removeprefix('sha256:')}"
    )


def проверить_границу_завершённого_простого_сброса(
    значение: object,
    контекст: QueueContext,
    схема: str,
    целевая_вершина: str,
    идентификатор_сброса: str,
) -> dict[str, object]:
    поля = {
        "схема",
        "идентичность_рабочей_копии",
        "ссылка_ветки",
        "целевая_вершина",
        "идентификатор_сброса",
        "создано",
    }
    if (
        not isinstance(значение, dict)
        or set(значение) != поля
        or значение.get("схема") != схема
        or значение.get("идентичность_рабочей_копии")
        != контекст.worktree_id
        or значение.get("ссылка_ветки") != контекст.branch_ref
        or значение.get("целевая_вершина") != целевая_вершина
        or значение.get("идентификатор_сброса") != идентификатор_сброса
        or not isinstance(значение.get("создано"), str)
        or not значение["создано"]
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_simple_reset_receipt",
            "Граница завершённого простого сброса повреждена.",
        )
    return значение


def простой_сброс_должен_сохранить_обязательное_продолжение(
    контекст: QueueContext,
    план: dict[str, object],
) -> bool:
    if маркер_обязательного_продолжения_есть_в_текущей_вершине(
        контекст
    ):
        return True
    исходный_объект = план.get("исходный_объект_очереди")
    if isinstance(исходный_объект, str) and исходный_объект != "absent":
        исходное_значение = попытаться_прочитать_объект_данных(
            контекст,
            исходный_объект,
        )
        try:
            исходное_состояние = validate_state(исходное_значение)
        except QueueError:
            исходное_состояние = None
        if (
            исходное_состояние is not None
            and исходное_состояние.get("worktree_id") == контекст.worktree_id
            and исходное_состояние.get("branch_ref") == контекст.branch_ref
            and исходное_состояние.get(
                ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ
            )
            is True
        ):
            return True
    хэш_ветки = hashlib.sha256(контекст.branch_ref.encode("utf-8")).hexdigest()
    префикс_квитанций = (
        f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_СВЯЗАННЫХ_КОММИТОВ}/"
        f"{контекст.worktree_id}/{хэш_ветки}/"
    )
    служебные_ссылки = план.get("служебные_ссылки")
    return isinstance(служебные_ссылки, list) and any(
        isinstance(запись, dict)
        and isinstance(запись.get("ссылка"), str)
        and str(запись["ссылка"]).startswith(префикс_квитанций)
        for запись in служебные_ссылки
    )


def проверить_квитанцию_простого_сброса(
    значение: object,
    контекст: QueueContext,
    ссылка: str,
) -> dict[str, object]:
    поля = {
        "схема",
        "идентичность_рабочей_копии",
        "ссылка_ветки",
        "целевая_вершина",
        "идентификатор_сброса",
        "объект_маркера",
        "маркер",
        "объект_снимка",
        "снимок",
        "исходный_объект_очереди",
        "объект_очереди_после",
        "состояние_очереди_после",
        "аннулирования",
        "объект_границы",
        "объект_эпохи",
        "завершено",
    }
    if (
        not isinstance(значение, dict)
        or set(значение) != поля
        or значение.get("схема") != СХЕМА_КВИТАНЦИИ_ПРОСТОГО_СБРОСА
        or значение.get("идентичность_рабочей_копии")
        != контекст.worktree_id
        or значение.get("ссылка_ветки") != контекст.branch_ref
        or not isinstance(значение.get("завершено"), str)
        or not значение["завершено"]
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_simple_reset_receipt",
            "Квитанция простого сброса повреждена.",
        )
    идентификатор_сброса = значение.get("идентификатор_сброса")
    if (
        not isinstance(идентификатор_сброса, str)
        or re.fullmatch(r"sha256:[0-9a-f]{64}", идентификатор_сброса)
        is None
        or ссылка
        != ссылка_квитанции_простого_сброса(
            контекст,
            идентификатор_сброса,
        )
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_simple_reset_receipt",
            "Квитанция простого сброса имеет неверный идентификатор.",
        )
    маркер = проверить_запись_простого_сброса(
        значение.get("маркер"),
        контекст,
    )
    снимок = проверить_снимок_простого_сброса(
        значение.get("снимок"),
        контекст,
    )
    план = снимок["план"]
    состояние_очереди = validate_state(
        значение.get("состояние_очереди_после")
    )
    объект_маркера = вычислить_канонический_объект_данных(
        контекст,
        маркер,
    )
    объект_снимка = вычислить_канонический_объект_данных(
        контекст,
        снимок,
    )
    объект_очереди = вычислить_канонический_объект_данных(
        контекст,
        состояние_очереди,
    )
    if (
        значение.get("целевая_вершина") != план["целевая_вершина"]
        or значение.get("целевая_вершина") != current_head(контекст.root)
        or идентификатор_сброса != план["идентификатор_сброса"]
        or значение.get("объект_маркера") != объект_маркера
        or значение.get("объект_снимка") != объект_снимка
        or маркер["объект_снимка"] != объект_снимка
        or значение.get("исходный_объект_очереди")
        != план["исходный_объект_очереди"]
        or значение.get("объект_очереди_после") != объект_очереди
        or состояние_очереди["worktree_id"] != контекст.worktree_id
        or состояние_очереди["branch_ref"] != контекст.branch_ref
        or состояние_очереди["owner"] is not None
        or состояние_очереди["waiting"] != []
        or состояние_очереди["next_seq"] != 1
        or состояние_очереди["last_completion"] is not None
        or (
            простой_сброс_должен_сохранить_обязательное_продолжение(
                контекст,
                план,
            )
            and состояние_очереди.get(
                ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ
            )
            is not True
        )
        or состояние_очереди.get("текущая_цепочка")
        != план["текущая_цепочка"]
        or значение.get("объект_границы") != снимок["объект_границы"]
        or значение.get("объект_эпохи") != снимок["объект_эпохи"]
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_simple_reset_receipt",
            "Квитанция простого сброса не воспроизводит терминальное состояние.",
        )
    аннулирования = значение.get("аннулирования")
    if not isinstance(аннулирования, list):
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_simple_reset_receipt",
            "Квитанция простого сброса не имеет аннулирований.",
        )
    задачи: list[str] = []
    for аннулирование in аннулирования:
        if not isinstance(аннулирование, dict) or set(аннулирование) != {
            "задача",
            "ссылка",
            "объект",
        }:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_simple_reset_receipt",
                "Квитанция простого сброса имеет неверное аннулирование.",
            )
        задача = validate_task_id(аннулирование.get("задача"))
        if (
            аннулирование.get("ссылка")
            != ссылка_аннулированной_задачи(контекст, задача)
            or read_ref_oid(контекст, str(аннулирование["ссылка"]))
            != аннулирование.get("объект")
        ):
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_simple_reset_receipt",
                "Аннулирование из квитанции простого сброса изменилось.",
            )
        прочитать_аннулирование_задачи(контекст, задача)
        задачи.append(задача)
    if задачи != план["участники"]:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_simple_reset_receipt",
            "Квитанция простого сброса имеет неверное множество задач.",
        )
    объект_границы = str(значение["объект_границы"])
    объект_эпохи = str(значение["объект_эпохи"])
    граница = прочитать_канонический_объект_данных(
        контекст,
        объект_границы,
        состояние_ошибки="corrupt_simple_reset_receipt",
        пояснение="Граница завершённого простого сброса повреждена.",
    )
    граница_эпохи = прочитать_канонический_объект_данных(
        контекст,
        объект_эпохи,
        состояние_ошибки="corrupt_simple_reset_receipt",
        пояснение="Граница эпохи завершённого простого сброса повреждена.",
    )
    проверить_границу_завершённого_простого_сброса(
        граница,
        контекст,
        СХЕМА_ГРАНИЦЫ_ПРОСТОГО_СБРОСА,
        str(план["целевая_вершина"]),
        идентификатор_сброса,
    )
    проверить_границу_завершённого_простого_сброса(
        граница_эпохи,
        контекст,
        СХЕМА_ГРАНИЦЫ_ЭПОХИ_ПРОСТОГО_СБРОСА,
        str(план["целевая_вершина"]),
        идентификатор_сброса,
    )
    return значение


def рабочая_копия_чиста_для_повтора_простого_сброса(
    контекст: QueueContext,
) -> bool:
    try:
        потребовать_обычные_флаги_индекса(контекст.root)
        return (
            изменённые_пути_для_сброса(контекст.root) == []
            and staged_changed_paths(контекст.root) == []
        )
    except QueueError:
        return False


def прочитать_терминальную_квитанцию_простого_сброса(
    контекст: QueueContext,
) -> tuple[dict[str, object], str] | None:
    ensure_live_branch(контекст)
    if not рабочая_копия_чиста_для_повтора_простого_сброса(контекст):
        return None
    инвентарь = сырой_инвентарь_ссылок_простого_сброса(контекст)
    if any(запись["действие"] == "удалить" for запись in инвентарь):
        return None
    текущий_объект_очереди = read_ref_oid(контекст, контекст.queue_ref)
    текущий_объект_границы = read_ref_oid(
        контекст,
        ссылка_границы_простого_сброса(контекст),
    )
    текущий_объект_эпохи = read_ref_oid(
        контекст,
        ссылка_эпохи_простого_сброса(контекст),
    )
    if (
        текущий_объект_очереди is None
        or текущий_объект_границы is None
        or текущий_объект_эпохи is None
    ):
        return None
    префикс = (
        f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_ПРОСТОГО_СБРОСА}/"
        f"{основа_ссылок_простого_сброса(контекст)}/"
    )
    совпадения: list[tuple[dict[str, object], str]] = []
    for запись in инвентарь:
        ссылка = запись["ссылка"]
        if not ссылка.startswith(префикс):
            continue
        try:
            квитанция = прочитать_канонический_объект_данных(
                контекст,
                запись["объект"],
                состояние_ошибки="corrupt_simple_reset_receipt",
                пояснение="Квитанция простого сброса повреждена.",
            )
            квитанция = проверить_квитанцию_простого_сброса(
                квитанция,
                контекст,
                ссылка,
            )
        except QueueError:
            continue
        if (
            квитанция["объект_очереди_после"]
            == текущий_объект_очереди
            and квитанция["объект_границы"] == текущий_объект_границы
            and квитанция["объект_эпохи"] == текущий_объект_эпохи
        ):
            совпадения.append((квитанция, ссылка))
    if len(совпадения) != 1:
        return None
    return совпадения[0]


def результат_терминального_повтора_простого_сброса(
    контекст: QueueContext,
    квитанция: dict[str, object],
    ссылка_квитанции: str,
) -> tuple[int, dict[str, object]]:
    объект_очереди = str(квитанция["объект_очереди_после"])
    return 0, {
        "состояние": "сброшено",
        "идентификатор_сброса": квитанция["идентификатор_сброса"],
        "целевая_вершина": квитанция["целевая_вершина"],
        "ссылка_квитанции": ссылка_квитанции,
        **common_payload(контекст, объект_очереди),
    }


def завершить_простой_сброс(
    контекст: QueueContext,
    маркер: dict[str, object],
    объект_маркера: str,
    снимок: dict[str, object],
) -> tuple[int, dict[str, object]]:
    потребовать_неизменные_ссылки_после_маркера(контекст, маркер, объект_маркера, снимок)
    план = снимок["план"]
    метка = utc_values()[0]
    новое_состояние = new_state(контекст)
    новое_состояние["updated_at"] = метка
    if простой_сброс_должен_сохранить_обязательное_продолжение(
        контекст,
        план,
    ):
        новое_состояние[ПОЛЕ_НЕОБРАТИМОЙ_АКТИВАЦИИ_ПРОДОЛЖЕНИЯ] = True
    if план["текущая_цепочка"] is not None:
        новое_состояние["текущая_цепочка"] = copy.deepcopy(план["текущая_цепочка"])
    новый_объект_очереди = write_state_blob(контекст, новое_состояние)
    аннулирования: list[dict[str, str]] = []
    новые_аннулирования: list[dict[str, str]] = []
    for идентификатор_задачи in план["участники"]:
        ссылка = ссылка_аннулированной_задачи(контекст, идентификатор_задачи)
        прежняя, прежний_объект = прочитать_аннулирование_задачи(контекст, идентификатор_задачи)
        if прежняя is not None and прежний_объект is not None:
            аннулирования.append({"задача": идентификатор_задачи, "ссылка": ссылка, "объект": прежний_объект})
            continue
        запись = запись_аннулирования_задачи(контекст, план, идентификатор_задачи, метка)
        объект = записать_канонический_объект_данных(контекст, запись)
        итог = {"задача": идентификатор_задачи, "ссылка": ссылка, "объект": объект}
        аннулирования.append(итог)
        новые_аннулирования.append(итог)
    квитанция: dict[str, object] = {
        "схема": СХЕМА_КВИТАНЦИИ_ПРОСТОГО_СБРОСА,
        "идентичность_рабочей_копии": контекст.worktree_id,
        "ссылка_ветки": контекст.branch_ref,
        "целевая_вершина": план["целевая_вершина"],
        "идентификатор_сброса": план["идентификатор_сброса"],
        "объект_маркера": объект_маркера,
        "маркер": copy.deepcopy(маркер),
        "объект_снимка": маркер["объект_снимка"],
        "снимок": copy.deepcopy(снимок),
        "исходный_объект_очереди": план["исходный_объект_очереди"],
        "объект_очереди_после": новый_объект_очереди,
        "состояние_очереди_после": copy.deepcopy(новое_состояние),
        "аннулирования": аннулирования,
        "объект_границы": снимок["объект_границы"],
        "объект_эпохи": снимок["объект_эпохи"],
        "завершено": метка,
    }
    объект_квитанции = записать_канонический_объект_данных(контекст, квитанция)
    ссылка_квитанции = ссылка_квитанции_простого_сброса(контекст, str(план["идентификатор_сброса"]))
    команды = ""
    команды += f"update {контекст.queue_ref} {новый_объект_очереди} {объект_маркера}\n"
    ожидаемые_после_маркера = ожидаемые_ссылки_после_маркера(
        снимок,
        str(маркер["объект_снимка"]),
    )
    нулевой_объект = "0" * len(str(план["целевая_вершина"]))
    for обязательная_ссылка in фиксированные_служебные_ссылки(контекст):
        if обязательная_ссылка not in ожидаемые_после_маркера:
            команды += f"verify {обязательная_ссылка} {нулевой_объект}\n"
    for запись in план["служебные_ссылки"]:
        if запись["ссылка"] in {снимок["ссылка_границы"], снимок["ссылка_эпохи"]}:
            continue
        if запись["действие"] == "удалить":
            команды += f"delete {запись['ссылка']} {запись['объект']}\n"
        else:
            команды += f"verify {запись['ссылка']} {запись['объект']}\n"
    команды += f"verify {снимок['ссылка_границы']} {снимок['объект_границы']}\n"
    команды += f"verify {снимок['ссылка_эпохи']} {снимок['объект_эпохи']}\n"
    команды += f"verify {снимок['ссылка_манифеста']} {маркер['объект_снимка']}\n"
    for резерв in снимок["прямые_резервные_ссылки"]:
        команды += f"verify {резерв['резервная_ссылка']} {резерв['исходный_объект']}\n"
    команды += f"create {ссылка_квитанции} {объект_квитанции}\n"
    for аннулирование in новые_аннулирования:
        команды += f"create {аннулирование['ссылка']} {аннулирование['объект']}\n"
    выполнить_транзакцию_простого_сброса(
        контекст,
        команды,
        str(план["целевая_вершина"]),
    )
    return 0, {
        "состояние": "сброшено",
        "идентификатор_сброса": план["идентификатор_сброса"],
        "целевая_вершина": план["целевая_вершина"],
        "ссылка_квитанции": ссылка_квитанции,
        **common_payload(контекст, новый_объект_очереди),
    }


def применить_простой_сброс(
    контекст: QueueContext,
    маркер: dict[str, object],
    объект_маркера: str,
    снимок: dict[str, object],
) -> tuple[int, dict[str, object]]:
    ensure_live_branch(контекст)
    план = снимок["план"]
    целевая_вершина = str(план["целевая_вершина"])
    потребовать_неизменные_ссылки_после_маркера(контекст, маркер, объект_маркера, снимок)
    потребовать_обычные_флаги_индекса(контекст.root)
    проверить_вложенные_границы_репозиториев(контекст.root)
    потребовать_отсутствие_коллизий_игнорируемых_путей(контекст.root, целевая_вершина)
    try:
        потребовать_подтверждённые_изменения(контекст.root, план)
    except QueueError as ошибка:
        if ошибка.state != "reset_plan_changed":
            raise
        потребовать_совместимое_частичное_состояние_отслеживаемых(контекст.root, план, целевая_вершина)
    потребовать_совместимые_неотслеживаемые_объекты(контекст.root, list(план["неотслеживаемые_объекты_плана"]), целевая_вершина)
    run_git(контекст.root, ["read-tree", "--reset", "-u", целевая_вершина])
    потребовать_совместимые_неотслеживаемые_объекты(контекст.root, list(план["неотслеживаемые_объекты_плана"]), целевая_вершина)
    удалить_подтверждённые_неотслеживаемые_пути(контекст.root, list(план["неотслеживаемые_объекты_плана"]), целевая_вершина)
    if current_head(контекст.root) != целевая_вершина:
        raise QueueError(EXIT_HEAD_CHANGED, "head_changed", "HEAD изменился во время очистки.")
    блокирующие = sorted(set(изменённые_пути_для_сброса(контекст.root)) | set(staged_changed_paths(контекст.root)))
    дерево = decoded_stdout(run_git(контекст.root, ["write-tree"]))
    целевое_дерево = decoded_stdout(run_git(контекст.root, ["rev-parse", f"{целевая_вершина}^{{tree}}"]))
    if блокирующие or дерево != целевое_дерево:
        raise QueueError(EXIT_DIRTY, "reset_incomplete", "Рабочая копия не приведена к точному HEAD.", данные_результата_операции={"blocking_paths": блокирующие})
    return завершить_простой_сброс(контекст, маркер, объект_маркера, снимок)


def простой_сброс(контекст: QueueContext) -> tuple[int, dict[str, object]]:
    if not getattr(sys.stdin, "isatty", lambda: False)() or not getattr(sys.stdout, "isatty", lambda: False)():
        raise QueueError(EXIT_CLI, "interactive_terminal_required", "Простой сброс разрешён только в интерактивном терминале.")
    терминальная_квитанция = прочитать_терминальную_квитанцию_простого_сброса(
        контекст
    )
    if терминальная_квитанция is not None:
        return результат_терминального_повтора_простого_сброса(
            контекст,
            *терминальная_квитанция,
        )
    потребовать_поддержку_символьных_транзакций(контекст)
    план = план_простого_сброса(контекст)
    фраза = фраза_подтверждения_простого_сброса(план)
    print("ВНИМАНИЕ: будут безвозвратно отменены FIFO-билеты и незакоммиченные изменения.")
    print(f"Ветка: {план['ссылка_ветки']}")
    print(f"HEAD: {план['целевая_вершина']}")
    print(f"Ссылка FIFO: {контекст.queue_ref}")
    print(f"Исходный объект FIFO: {план['исходный_объект_очереди']}")
    print(f"Участников: {len(план['участники'])}; изменённых путей: {len(план['изменённые_пути_плана'])}.")
    for путь in план["изменённые_пути_плана"]:
        print(f"Изменённый путь: {json.dumps(путь, ensure_ascii=False)}")
    for служебная_запись in план["служебные_ссылки"]:
        print(
            "Служебная ссылка: "
            f"{служебная_запись['ссылка']} "
            f"{служебная_запись['объект']} "
            f"{служебная_запись['действие']}",
        )
    print("Для подтверждения введите точно без изменений:")
    print(фраза)
    try:
        ответ = input()
    except EOFError as ошибка:
        raise QueueError(EXIT_CLI, "confirmation_cancelled", "Ввод подтверждения прерван до мутации.") from ошибка
    if ответ != фраза:
        raise QueueError(EXIT_CAS, "confirmation_mismatch", "Точная фраза подтверждения не совпала.")
    повторный_план = план_простого_сброса(контекст)
    if canonical_state_bytes(повторный_план) != canonical_state_bytes(план):
        raise QueueError(EXIT_CAS, "reset_plan_changed", "План простого сброса изменился после подтверждения.")
    активный = прочитать_активный_простой_сброс(контекст)
    if активный is None:
        активный = начать_простой_сброс(контекст, план)
    return применить_простой_сброс(контекст, *активный)


def queue_status(контекст_очереди: QueueContext) -> tuple[int, dict[str, object]]:
    ensure_live_branch(контекст_очереди)
    вид, state, state_oid = прочитать_запись_очереди(контекст_очереди)
    if вид == "сброс":
        return 0, {
            "state": "resetting",
            "фаза": state["фаза"],
            "идентификатор_сброса": state["идентификатор_сброса"],
            "участники": state["участники"],
            **common_payload(контекст_очереди, state_oid),
        }
    if state["worktree_id"] != контекст_очереди.worktree_id:
        raise QueueError(EXIT_CONTEXT, "invalid_context", "Очередь принадлежит другому worktree.")
    if (
        state["branch_ref"] != контекст_очереди.branch_ref
        and (state["owner"] is not None or state["waiting"])
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "branch_changed",
            "В worktree переключена ветка при непустой очереди.",
            данные_результата_операции={
                "expected_branch_ref": state["branch_ref"],
                "current_branch_ref": контекст_очереди.branch_ref,
            },
        )
    return 0, {
        "state": "active" if state["owner"] is not None or state["waiting"] else "idle",
        "owner": state["owner"],
        "waiting": state["waiting"],
        "next_seq": state["next_seq"],
        "stored_branch_ref": state["branch_ref"],
        **common_payload(контекст_очереди, state_oid),
    }


def heartbeat_status(
    контекст_очереди: QueueContext,
    task_id: str,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    _, status = queue_status(контекст_очереди)
    if status["state"] == "resetting":
        return 0, {"state": "busy"}
    owner = status["owner"]
    waiting = status["waiting"]
    if isinstance(owner, dict) and owner["task_id"] == task_id:
        observed_state = "own_owner"
    elif owner is None and not waiting:
        observed_state = "idle"
    else:
        observed_state = "busy"
    return 0, {"state": observed_state}


def сформировать_промпт_продолжения(
    контекст_очереди: QueueContext,
    идентификатор_родительской_задачи: str,
) -> tuple[int, dict[str, object]]:
    идентификатор_родительской_задачи = validate_task_id(
        идентификатор_родительской_задачи
    )
    if (
        Path(идентификатор_родительской_задачи).is_absolute()
        or re.search(
            r"(?:^|\s)(?:/|[A-Za-z]:[\\/]|\\\\)",
            идентификатор_родительской_задачи,
        )
        is not None
    ):
        raise QueueError(
            EXIT_CLI,
            "небезопасный_промпт_продолжения",
            "Идентификатор родительской задачи не должен содержать абсолютный путь.",
        )
    ensure_live_branch(контекст_очереди)
    состояние, _ = read_state(контекст_очереди)
    состояние = ensure_state_identity(
        контекст_очереди,
        состояние,
        allow_idle_rebind=False,
    )
    владелец = состояние["owner"]
    if (
        not isinstance(владелец, dict)
        or владелец["task_id"] != идентификатор_родительской_задачи
    ):
        raise QueueError(
            EXIT_OWNERSHIP,
            "not_owner",
            "Промпт продолжения может сформировать только точный владелец очереди.",
        )
    ветка = контекст_очереди.branch_ref
    промпт = f"""Ты — новая корневая сессия-продолжение именованной Git-ветки `{ ветка }`. Родительская задача `{ идентификатор_родительской_задачи }` создала тебя до своего атомарного commit+handoff.

Первым инструментальным действием, до чтения и любой записи, вызови через безопасный HEAD-bootstrap команду `join` очереди `fum-ocheredj-zadach-git-vetki` со своим точным `CODEX_THREAD_ID`. Не подменяй его идентификатором родителя. При `waiting` запусти один `wait-until-actionable` и не меняй checkout, индекс, refs или внешнее состояние до передачи родителя.

После передачи ожидай `reload_required`. Перечитай из нового закоммиченного HEAD как минимум `AGENTS.md` и `Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md`, проверь точные HEAD и symbolic ref `{ ветка }`, затем вызови `ack-head` для этого HEAD и снова `wait-until-actionable`. Начинай содержательную работу только после `admitted`.

После допуска сначала через safe HEAD-bootstrap пула вызови `повторить-ожидающие-публикации` со своими exact `task_id` и `generation`, затем прямо вызови `python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py show --repo-root . --json`. Если ответ означает `done` или `not_ready`, ничего не пиши, останови всех писателей и выполни `finish-clean`. Если выбран готовый шаг, выполни точную карточку по новым правилам HEAD. Если твоя работа завершается `committed`, до собственного commit+handoff создай ровно одну новую сессию-продолжение этой же ветки и повтори весь этот протокол.
""".strip()
    if re.search(
        r"(?:^|[\s`'\"(])(?:/[^\s]|[A-Za-z]:[\\/]|\\\\)",
        промпт,
    ) is not None:
        raise QueueError(
            EXIT_CONTEXT,
            "небезопасный_промпт_продолжения",
            "Сформированный промпт содержит абсолютный путь.",
        )
    return 0, {
        "state": "промпт_продолжения",
        "branch_ref": ветка,
        "идентификатор_родительской_задачи": идентификатор_родительской_задачи,
        "промпт": промпт,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Переносимая последовательная очередь корневых задач Codex в Git worktree.",
        allow_abbrev=False,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    def add_common(subparser: argparse.ArgumentParser) -> None:
        subparser.add_argument("--repo-root", type=Path, default=Path("."))
        subparser.add_argument("--json", action="store_true")

    status = subparsers.add_parser(
        "status", help="Показать состояние очереди.", allow_abbrev=False
    )
    add_common(status)

    формирование_промпта = subparsers.add_parser(
        "сформировать-промпт-продолжения",
        help="Сформировать read-only промпт продолжения текущей ветки.",
        allow_abbrev=False,
    )
    add_common(формирование_промпта)
    формирование_промпта.add_argument("--task-id", required=True)

    heartbeat_status_parser = subparsers.add_parser(
        "heartbeat-status",
        help="Вернуть узкое состояние очереди для heartbeat без непрозрачных полей.",
        allow_abbrev=False,
    )
    add_common(heartbeat_status_parser)
    heartbeat_status_parser.add_argument("--task-id", required=True)

    простой_сброс_парсера = subparsers.add_parser(
        "простой-сброс",
        help="Интерактивно аннулировать FIFO и вернуть checkout к точному HEAD.",
        allow_abbrev=False,
    )
    add_common(простой_сброс_парсера)

    планировщик_сброса = subparsers.add_parser(
        "план-сброса",
        help="Построить точный read-only план штатного сброса.",
        allow_abbrev=False,
    )
    add_common(планировщик_сброса)
    планировщик_сброса.add_argument(
        "--идентификатор-диспетчера",
        dest="идентификатор_диспетчера",
        required=True,
    )

    подготовка_сброса = subparsers.add_parser(
        "подготовить-сброс",
        help="Заменить очередь ограждённой записью точного сброса.",
        allow_abbrev=False,
    )
    add_common(подготовка_сброса)
    подготовка_сброса.add_argument(
        "--идентификатор-диспетчера",
        dest="идентификатор_диспетчера",
        required=True,
    )
    подготовка_сброса.add_argument(
        "--ожидаемая-вершина",
        dest="ожидаемая_вершина",
        required=True,
    )
    подготовка_сброса.add_argument(
        "--ожидаемый-объект-очереди",
        dest="ожидаемый_объект_очереди",
        required=True,
    )
    подготовка_сброса.add_argument("--подтверждение", required=True)

    подтверждение_сессий = subparsers.add_parser(
        "подтвердить-остановку-сессий",
        help="Зафиксировать точное host-доказательство неактивности участников.",
        allow_abbrev=False,
    )
    add_common(подтверждение_сессий)
    подтверждение_сессий.add_argument(
        "--идентификатор-диспетчера",
        dest="идентификатор_диспетчера",
        required=True,
    )
    подтверждение_сессий.add_argument(
        "--идентификатор-сброса",
        dest="идентификатор_сброса",
        required=True,
    )
    подтверждение_сессий.add_argument(
        "--неактивная-задача",
        dest="неактивные_задачи",
        action="append",
        default=[],
    )

    применение_сброса = subparsers.add_parser(
        "применить-сброс",
        help="Очистить checkout к точному HEAD и выпустить пустую очередь.",
        allow_abbrev=False,
    )
    add_common(применение_сброса)
    применение_сброса.add_argument(
        "--идентификатор-диспетчера",
        dest="идентификатор_диспетчера",
        required=True,
    )
    применение_сброса.add_argument(
        "--идентификатор-сброса",
        dest="идентификатор_сброса",
        required=True,
    )

    отмена_сброса = subparsers.add_parser(
        "отменить-сброс",
        help="Отменить подготовленный сброс до host-остановки.",
        allow_abbrev=False,
    )
    add_common(отмена_сброса)
    отмена_сброса.add_argument(
        "--идентификатор-диспетчера",
        dest="идентификатор_диспетчера",
        required=True,
    )
    отмена_сброса.add_argument(
        "--идентификатор-сброса",
        dest="идентификатор_сброса",
        required=True,
    )

    статус_сброса = subparsers.add_parser(
        "состояние-сброса",
        help="Показать узкое состояние попытки сброса.",
        allow_abbrev=False,
    )
    add_common(статус_сброса)

    переход_на_цепочку = subparsers.add_parser(
        "перейти-на-цепочку",
        help="Создать отсутствующую ветку цепочки и сразу допустить текущую задачу.",
        allow_abbrev=False,
    )
    add_common(переход_на_цепочку)
    переход_на_цепочку.add_argument(
        "--task-id",
        dest="идентификатор_задачи",
        required=True,
    )
    переход_на_цепочку.add_argument(
        "--chain-card",
        dest="путь_карточки",
        required=True,
    )
    переход_на_цепочку.add_argument(
        "--expected-chain-id",
        dest="ожидаемый_идентификатор_цепочки",
        required=True,
    )
    переход_на_цепочку.add_argument(
        "--expected-card-sha256",
        dest="ожидаемый_хэш_карточки",
        required=True,
    )
    переход_на_цепочку.add_argument(
        "--expected-source-branch-ref",
        dest="ожидаемая_исходная_ветка",
        required=True,
    )
    переход_на_цепочку.add_argument(
        "--expected-source-head",
        dest="ожидаемая_исходная_вершина",
        required=True,
    )

    def добавить_аргументы_барьера(подкоманда: argparse.ArgumentParser) -> None:
        подкоманда.add_argument("--ветка", required=True)
        подкоманда.add_argument("--базовая-вершина", dest="базовая_вершина", required=True)
        подкоманда.add_argument("--идентификатор-форка", dest="идентификатор_форка", required=True)
        подкоманда.add_argument("--поколение-запуска", dest="поколение_запуска", required=True)
        подкоманда.add_argument(
            "--идентификатор-попытки-создания",
            dest="идентификатор_попытки_создания",
            required=True,
        )
        подкоманда.add_argument(
            "--идентификатор-назначения",
            dest="идентификатор_назначения",
            required=True,
        )
        подкоманда.add_argument(
            "--хэш-назначения",
            dest="хэш_назначения",
            required=True,
        )
        подкоманда.add_argument(
            "--идентификатор-ресурсной-попытки",
            dest="идентификатор_ресурсной_попытки",
            required=True,
        )
        подкоманда.add_argument(
            "--хэш-ресурсного-допуска",
            dest="хэш_ресурсного_допуска",
            required=True,
        )

    установка_барьера = subparsers.add_parser(
        "установить-барьер-предактивации",
        help="До host-вызова закрыть первый join ветки несвязанным барьером.",
        allow_abbrev=False,
    )
    add_common(установка_барьера)
    добавить_аргументы_барьера(установка_барьера)

    привязка_задачи_барьера = subparsers.add_parser(
        "связать-задачу-барьера",
        help="После host-вызова атомарно связать барьер с точной задачей.",
        allow_abbrev=False,
    )
    add_common(привязка_задачи_барьера)
    добавить_аргументы_барьера(привязка_задачи_барьера)
    привязка_задачи_барьера.add_argument(
        "--task-id",
        dest="идентификатор_задачи",
        required=True,
    )
    привязка_задачи_барьера.add_argument(
        "--host-id",
        dest="идентификатор_среды",
        required=True,
    )
    привязка_задачи_барьера.add_argument(
        "--хэш-конверта",
        dest="хэш_конверта",
        required=True,
    )
    привязка_задачи_барьера.add_argument(
        "--хэш-привязки",
        dest="хэш_привязки",
        required=True,
    )
    привязка_задачи_барьера.add_argument(
        "--ожидаемый-объект-реестра",
        dest="ожидаемый_объект_реестра",
        required=True,
    )

    открытие_барьера = subparsers.add_parser(
        "открыть-барьер-предактивации",
        help="Атомарно открыть точный барьер по глобальной квитанции.",
        allow_abbrev=False,
    )
    add_common(открытие_барьера)
    добавить_аргументы_барьера(открытие_барьера)
    открытие_барьера.add_argument(
        "--task-id",
        dest="идентификатор_задачи",
        required=True,
    )
    открытие_барьера.add_argument(
        "--квитанция-активации",
        dest="квитанция_активации",
        required=True,
    )
    открытие_барьера.add_argument(
        "--хэш-предактивации",
        dest="хэш_предактивации",
        required=True,
    )
    открытие_барьера.add_argument(
        "--хэш-привязки-пары",
        dest="хэши_привязок_пары",
        action="append",
        required=True,
    )
    открытие_барьера.add_argument(
        "--хэш-активации",
        dest="хэш_активации",
        required=True,
    )
    открытие_барьера.add_argument(
        "--ожидаемый-объект-реестра",
        dest="ожидаемый_объект_реестра",
        required=True,
    )

    join = subparsers.add_parser(
        "join",
        help="Атомарно зарегистрировать корневую задачу.",
        allow_abbrev=False,
    )
    add_common(join)
    join.add_argument("--task-id", required=True)

    wait = subparsers.add_parser(
        "wait", help="Ограниченно ждать своей позиции без изменения очереди.", allow_abbrev=False
    )
    add_common(wait)
    wait.add_argument("--task-id", required=True)
    wait.add_argument(
        "--timeout-seconds",
        type=float,
        default=DEFAULT_WAIT_TIMEOUT_SECONDS,
        help="Предел одного read-only ожидания; по умолчанию 300 секунд.",
    )

    wait_until_actionable = subparsers.add_parser(
        "wait-until-actionable",
        help="Бесшумно ждать до действенного состояния без промежуточного waiting.",
        allow_abbrev=False,
    )
    add_common(wait_until_actionable)
    wait_until_actionable.add_argument("--task-id", required=True)

    ack = subparsers.add_parser(
        "ack-head",
        help="Подтвердить перечитанный HEAD после коммита предшественника.",
        allow_abbrev=False,
    )
    add_common(ack)
    ack.add_argument("--task-id", required=True)
    ack.add_argument("--head", required=True)

    cancel = subparsers.add_parser(
        "cancel",
        help="Удалить только собственный ожидающий билет.",
        allow_abbrev=False,
    )
    add_common(cancel)
    cancel.add_argument("--task-id", required=True)
    cancel.add_argument("--ticket-id")

    finish_clean = subparsers.add_parser(
        "finish-clean",
        help="Завершить владельца без коммита только при неизменном HEAD и чистом дереве.",
        allow_abbrev=False,
    )
    add_common(finish_clean)
    finish_clean.add_argument("--task-id", required=True)
    finish_clean.add_argument("--generation", required=True)

    finish_own_clean = subparsers.add_parser(
        "finish-own-clean",
        help=(
            "Чисто завершить точно своего текущего владельца, не перенося generation "
            "через модель."
        ),
        allow_abbrev=False,
    )
    add_common(finish_own_clean)
    finish_own_clean.add_argument("--task-id", required=True)
    finish_own_clean.add_argument(
        "--ограждающая-ссылка",
        dest="ограждающая_ссылка",
    )
    finish_own_clean.add_argument(
        "--ожидаемый-объект-ограждения",
        dest="ожидаемый_объект_ограждения",
    )

    commit = subparsers.add_parser(
        "commit",
        help="Атомарно создать коммит и передать право следующей задаче.",
        allow_abbrev=False,
    )
    add_common(commit)
    commit.add_argument("--task-id", required=True)
    commit.add_argument("--generation", required=True)
    commit.add_argument("--идентификатор-продолжения")
    message_group = commit.add_mutually_exclusive_group(required=True)
    message_group.add_argument("--message")
    message_group.add_argument("--message-file")

    принятие_интеграции = subparsers.add_parser(
        "принять-интеграционный-кандидат",
        help="Атомарно принять reviewed-кандидат вместе с FIFO handoff и CAS пула.",
        allow_abbrev=False,
    )
    add_common(принятие_интеграции)
    принятие_интеграции.add_argument("--task-id", required=True)
    принятие_интеграции.add_argument("--generation", required=True)
    принятие_интеграции.add_argument("--идентификатор-продолжения", required=True)
    принятие_интеграции.add_argument("--новая-вершина", required=True)
    принятие_интеграции.add_argument("--ссылка-пула")
    принятие_интеграции.add_argument("--исходный-объект-пула")
    принятие_интеграции.add_argument("--новый-объект-пула")
    принятие_интеграции.add_argument("--хэш-интеграции", required=True)

    publish = subparsers.add_parser(
        "publish",
        help="Опубликовать точный коммит в точную ветку GitHub.",
        allow_abbrev=False,
    )
    add_common(publish)
    publish.add_argument("--commit", required=True)
    publish.add_argument("--branch-ref", required=True)
    publish.add_argument("--push-url", required=True)
    return parser


def commit_message_from_args(args: argparse.Namespace) -> str:
    if args.message is not None:
        return str(args.message)
    if args.message_file == "-":
        return sys.stdin.read()
    try:
        return Path(args.message_file).read_text(encoding="utf-8")
    except OSError as exc:
        raise QueueError(
            EXIT_CLI,
            "invalid_message_file",
            f"Не удалось прочитать файл сообщения коммита: {exc}",
        ) from exc


def error_payload(error: QueueError) -> dict[str, object]:
    return {
        "state": error.state,
        "message": str(error),
        **error.данные_результата_операции,
    }


def сериализовать_ответ(данные: dict[str, object]) -> str:
    return json.dumps(данные, ensure_ascii=True, sort_keys=True) + "\n"


def отпечаток_блокирующих_путей(пути: list[str]) -> str:
    вычислитель = hashlib.sha256()
    вычислитель.update(ДОМЕН_ОТПЕЧАТКА_БЛОКИРУЮЩИХ_ПУТЕЙ)
    вычислитель.update(len(пути).to_bytes(8, "big"))
    for путь in пути:
        сырые_байты = путь.encode("utf-8", errors="surrogateescape")
        вычислитель.update(len(сырые_байты).to_bytes(8, "big"))
        вычислитель.update(сырые_байты)
    return f"sha256:{вычислитель.hexdigest()}"


def ограничить_грязный_ответ(
    данные: dict[str, object],
) -> dict[str, object]:
    исходные_пути = данные.get("blocking_paths")
    if (
        данные.get("state") != "dirty"
        or not isinstance(исходные_пути, list)
        or not all(isinstance(путь, str) for путь in исходные_пути)
    ):
        return данные
    полные_пути = sorted(set(исходные_пути))
    основа = dict(данные)
    основа.update(
        {
            "blocking_paths_schema": СХЕМА_ИНВЕНТАРЯ_БЛОКИРУЮЩИХ_ПУТЕЙ,
            "blocking_paths": [],
            "blocking_paths_count": len(полные_пути),
            "blocking_paths_sha256": отпечаток_блокирующих_путей(полные_пути),
            "blocking_paths_truncated": bool(полные_пути),
        }
    )
    if (
        len(сериализовать_ответ(основа).encode("utf-8"))
        > ЛИМИТ_БАЙТОВ_ГРЯЗНОГО_ОТВЕТА
    ):
        основа = {
            "state": "dirty",
            "message": "Рабочая копия содержит блокирующие пути.",
            "blocking_paths_schema": СХЕМА_ИНВЕНТАРЯ_БЛОКИРУЮЩИХ_ПУТЕЙ,
            "blocking_paths": [],
            "blocking_paths_count": len(полные_пути),
            "blocking_paths_sha256": отпечаток_блокирующих_путей(полные_пути),
            "blocking_paths_truncated": bool(полные_пути),
        }
    предпросмотр: list[str] = []
    for путь in полные_пути[:ЛИМИТ_ПУТЕЙ_В_ПРЕДПРОСМОТРЕ]:
        кандидат = [*предпросмотр, путь]
        кандидат_ответа = {
            **основа,
            "blocking_paths": кандидат,
            "blocking_paths_truncated": len(кандидат) < len(полные_пути),
        }
        if (
            len(сериализовать_ответ(кандидат_ответа).encode("utf-8"))
            > ЛИМИТ_БАЙТОВ_ГРЯЗНОГО_ОТВЕТА
        ):
            break
        предпросмотр = кандидат
    основа["blocking_paths"] = предпросмотр
    основа["blocking_paths_truncated"] = len(предпросмотр) < len(полные_пути)
    return основа


def emit(данные_результата_операции: dict[str, object]) -> None:
    sys.stdout.write(
        сериализовать_ответ(
            ограничить_грязный_ответ(данные_результата_операции)
        )
    )


def потребовать_идентичность_задачи_диспетчера(
    идентификатор_диспетчера: str,
) -> None:
    validate_task_id(идентификатор_диспетчера)
    текущий_идентификатор = os.environ.get("CODEX_THREAD_ID")
    if текущий_идентификатор != идентификатор_диспетчера:
        raise QueueError(
            EXIT_OWNERSHIP,
            "dispatcher_identity_mismatch",
            "Идентификатор диспетчера не совпадает с текущей задачей Codex.",
        )


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        контекст_очереди = resolve_context(args.repo_root)
        if args.command in {
            "план-сброса",
            "подготовить-сброс",
            "подтвердить-остановку-сессий",
            "применить-сброс",
            "отменить-сброс",
        }:
            потребовать_идентичность_задачи_диспетчера(
                args.идентификатор_диспетчера
            )
        if args.command == "status":
            код_завершения_операции, данные_результата_операции = queue_status(контекст_очереди)
        elif args.command == "сформировать-промпт-продолжения":
            (
                код_завершения_операции,
                данные_результата_операции,
            ) = сформировать_промпт_продолжения(
                контекст_очереди,
                args.task_id,
            )
        elif args.command == "heartbeat-status":
            код_завершения_операции, данные_результата_операции = heartbeat_status(контекст_очереди, args.task_id)
        elif args.command == "простой-сброс":
            код_завершения_операции, данные_результата_операции = простой_сброс(контекст_очереди)
        elif args.command == "план-сброса":
            код_завершения_операции, данные_результата_операции = план_сброса(
                контекст_очереди,
                args.идентификатор_диспетчера,
            )
        elif args.command == "подготовить-сброс":
            код_завершения_операции, данные_результата_операции = подготовить_сброс(
                контекст_очереди,
                args.идентификатор_диспетчера,
                args.ожидаемая_вершина,
                args.ожидаемый_объект_очереди,
                args.подтверждение,
            )
        elif args.command == "подтвердить-остановку-сессий":
            код_завершения_операции, данные_результата_операции = подтвердить_остановку_сессий(
                контекст_очереди,
                args.идентификатор_диспетчера,
                args.идентификатор_сброса,
                args.неактивные_задачи,
            )
        elif args.command == "применить-сброс":
            код_завершения_операции, данные_результата_операции = применить_сброс(
                контекст_очереди,
                args.идентификатор_диспетчера,
                args.идентификатор_сброса,
            )
        elif args.command == "отменить-сброс":
            код_завершения_операции, данные_результата_операции = отменить_сброс(
                контекст_очереди,
                args.идентификатор_диспетчера,
                args.идентификатор_сброса,
            )
        elif args.command == "состояние-сброса":
            код_завершения_операции, данные_результата_операции = состояние_сброса(контекст_очереди)
        elif args.command == "перейти-на-цепочку":
            код_завершения_операции, данные_результата_операции = перейти_на_цепочку(
                контекст_очереди,
                args.идентификатор_задачи,
                args.путь_карточки,
                args.ожидаемый_идентификатор_цепочки,
                args.ожидаемый_хэш_карточки,
                args.ожидаемая_исходная_ветка,
                args.ожидаемая_исходная_вершина,
            )
        elif args.command == "установить-барьер-предактивации":
            (
                код_завершения_операции,
                данные_результата_операции,
            ) = установить_барьер_предактивации(
                контекст_очереди,
                args.ветка,
                args.базовая_вершина,
                args.идентификатор_форка,
                args.поколение_запуска,
                args.идентификатор_попытки_создания,
                args.идентификатор_назначения,
                args.хэш_назначения,
                args.идентификатор_ресурсной_попытки,
                args.хэш_ресурсного_допуска,
            )
        elif args.command == "связать-задачу-барьера":
            (
                код_завершения_операции,
                данные_результата_операции,
            ) = связать_задачу_барьера(
                контекст_очереди,
                args.идентификатор_задачи,
                args.идентификатор_среды,
                args.хэш_конверта,
                args.хэш_привязки,
                args.ветка,
                args.базовая_вершина,
                args.идентификатор_форка,
                args.поколение_запуска,
                args.идентификатор_попытки_создания,
                args.идентификатор_назначения,
                args.хэш_назначения,
                args.идентификатор_ресурсной_попытки,
                args.хэш_ресурсного_допуска,
                args.ожидаемый_объект_реестра,
            )
        elif args.command == "открыть-барьер-предактивации":
            (
                код_завершения_операции,
                данные_результата_операции,
            ) = открыть_барьер_предактивации(
                контекст_очереди,
                args.идентификатор_задачи,
                args.ветка,
                args.базовая_вершина,
                args.идентификатор_форка,
                args.поколение_запуска,
                args.идентификатор_попытки_создания,
                args.идентификатор_назначения,
                args.хэш_назначения,
                args.идентификатор_ресурсной_попытки,
                args.хэш_ресурсного_допуска,
                args.квитанция_активации,
                args.хэш_предактивации,
                args.хэши_привязок_пары,
                args.хэш_активации,
                args.ожидаемый_объект_реестра,
            )
        elif args.command == "join":
            код_завершения_операции, данные_результата_операции = join_queue(контекст_очереди, args.task_id)
        elif args.command == "wait":
            код_завершения_операции, данные_результата_операции = wait_queue(контекст_очереди, args.task_id, args.timeout_seconds)
        elif args.command == "wait-until-actionable":
            код_завершения_операции, данные_результата_операции = wait_until_actionable_queue(контекст_очереди, args.task_id)
        elif args.command == "ack-head":
            код_завершения_операции, данные_результата_операции = acknowledge_head(контекст_очереди, args.task_id, args.head)
        elif args.command == "cancel":
            код_завершения_операции, данные_результата_операции = cancel_waiter(
                контекст_очереди,
                args.task_id,
                args.ticket_id,
            )
        elif args.command == "finish-clean":
            код_завершения_операции, данные_результата_операции = finish_clean_and_handoff(
                контекст_очереди,
                args.task_id,
                args.generation,
            )
        elif args.command == "finish-own-clean":
            код_завершения_операции, данные_результата_операции = finish_own_clean_and_handoff(
                контекст_очереди,
                args.task_id,
                args.ограждающая_ссылка,
                args.ожидаемый_объект_ограждения,
            )
        elif args.command == "commit":
            предварительный_повтор = atomic_commit_and_handoff(
                контекст_очереди,
                args.task_id,
                args.generation,
                None,
                args.идентификатор_продолжения,
            )
            if предварительный_повтор is None:
                предварительный_повтор = atomic_commit_and_handoff(
                    контекст_очереди,
                    args.task_id,
                    args.generation,
                    commit_message_from_args(args),
                    args.идентификатор_продолжения,
                )
            if предварительный_повтор is None:
                raise AssertionError("Коммит не вернул итоговый результат.")
            (
                код_завершения_операции,
                данные_результата_операции,
            ) = предварительный_повтор
        elif args.command == "принять-интеграционный-кандидат":
            (
                код_завершения_операции,
                данные_результата_операции,
            ) = принять_интеграционный_кандидат(
                контекст_очереди,
                args.task_id,
                args.generation,
                args.идентификатор_продолжения,
                args.новая_вершина,
                args.ссылка_пула,
                args.исходный_объект_пула,
                args.новый_объект_пула,
                args.хэш_интеграции,
            )
        elif args.command == "publish":
            код_завершения_операции, данные_результата_операции = publish_exact_commit(
                контекст_очереди,
                args.commit,
                args.branch_ref,
                args.push_url,
            )
        else:  # pragma: no cover - argparse makes this unreachable.
            raise AssertionError(args.command)
    except KeyboardInterrupt:
        return EXIT_INTERRUPTED
    except QueueError as error:
        emit(error_payload(error))
        return error.exit_code
    emit(данные_результата_операции)
    return код_завершения_операции


if __name__ == "__main__":
    raise SystemExit(main())
