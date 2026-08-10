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
СХЕМА_ПЕРЕХОДА_НА_ЦЕПОЧКУ = "fum.переход-на-цепочку.1"
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
ПРОСТРАНСТВО_СНИМКОВ_ПРОСТОГО_СБРОСА = "refs/fum/снимки-простого-сброса"
ПРОСТРАНСТВО_КВИТАНЦИЙ_ПРОСТОГО_СБРОСА = "refs/fum/квитанции-простого-сброса"
ПРОСТРАНСТВО_ГРАНИЦ_ПРОСТОГО_СБРОСА = "refs/fum/границы-простого-сброса"
ПРОСТРАНСТВО_АННУЛИРОВАННЫХ_ЗАДАЧ = "refs/fum/аннулированные-задачи-простого-сброса"
АРХИВНЫЕ_ПРОСТРАНСТВА_ПРОСТОГО_СБРОСА = frozenset(
    {
        "аварийные-снимки-состояния",
        "снимки-простого-сброса",
        "квитанции-простого-сброса",
        "границы-простого-сброса",
        "аннулированные-задачи-простого-сброса",
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
        if isinstance(owner, dict):
            if owner["task_id"] == task_id:
                return owner_result(
                    контекст_очереди,
                    owner,
                    old_oid,
                    ownership="existing",
                )
            return waiting_result(контекст_очереди, state, old_oid, task_id)

        waiting = state["waiting"]
        target_index = next(
            (
                index
                for index, ticket in enumerate(waiting)
                if ticket["task_id"] == task_id
            ),
            None,
        )
        if target_index is None:
            raise QueueError(
                EXIT_NOT_REGISTERED,
                "not_registered",
                "Задача не зарегистрирована в очереди.",
            )
        if target_index != 0:
            return waiting_result(контекст_очереди, state, old_oid, task_id)

        ticket = waiting[0]
        head = current_head(контекст_очереди.root)
        if ticket["acknowledged_head"] != head:
            return EXIT_RELOAD_REQUIRED, {
                "state": "reload_required",
                "position": 1,
                **ticket,
                "current_head": head,
                **common_payload(контекст_очереди, old_oid),
            }
        blocking = all_changed_paths(контекст_очереди.root)
        if blocking:
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
        updated = copy.deepcopy(state)
        updated["owner"] = owner_record
        updated["waiting"] = updated["waiting"][1:]
        updated["updated_at"] = stamp
        if old_oid is None:
            raise QueueError(
                EXIT_CONTEXT,
                "corrupt_queue",
                "У ожидающего билета отсутствует Git-ссылка состояния очереди.",
            )
        new_oid = write_state_blob(контекст_очереди, updated)
        result = update_queue_with_head_verification(
            контекст_очереди,
            expected_head=head,
            old_queue_oid=old_oid,
            new_queue_oid=new_oid,
        )
        if result.returncode == 0:
            return owner_result(
                контекст_очереди,
                owner_record,
                new_oid,
                ownership="new",
            )
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        observed_head = current_head(контекст_очереди.root)
        _, observed_queue_oid = read_state(контекст_очереди)
        if observed_head != head or observed_queue_oid != old_oid:
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
        owner = identity_state["owner"]
        if isinstance(owner, dict) and owner["task_id"] == task_id:
            return owner_result(контекст_очереди, owner, old_oid, ownership="existing")

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
        updated["next_seq"] = int(updated["next_seq"]) + 1
        updated["waiting"].append(ticket)
        updated["updated_at"] = stamp

        success, _ = сравнить_очередь_при_отсутствии_аннулирования(
            контекст_очереди,
            old_oid,
            updated,
            task_id,
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
        f"symref-verify HEAD {контекст.branch_ref}\n"
        f"verify {ссылка_аннулирования} {нулевой_объект}\n"
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
        f"symref-update HEAD {целевая_ветка} ref {исходная_ветка}\n"
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
        if symbolic_branch(целевой_контекст.root) != целевая_ветка:
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
        return owner_result(
            контекст,
            существующий_владелец,
            объект_очереди,
            ownership="existing",
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
        stamp, epoch = utc_values()
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
        target["acknowledged_head"] = acknowledged_head
        updated["updated_at"] = stamp
        success, new_oid = cas_state(контекст_очереди, old_oid, updated)
        if success:
            return 0, {
                "state": "acknowledged",
                **target,
                **common_payload(контекст_очереди, new_oid),
            }
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
    return 0, {
        "state": "committed",
        "task_id": completion["task_id"],
        "generation": completion["generation"],
        "old_head": completion["base_head"],
        "new_head": completion["head"],
        **common_payload(контекст_очереди, state_oid),
    }


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
        previous = matching_completion(
            state,
            kind="finished_clean",
            task_id=task_id,
            generation=generation,
        )
        if previous is not None:
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
        result = update_queue_with_head_verification(
            контекст_очереди,
            expected_head=base_head,
            old_queue_oid=old_oid,
            new_queue_oid=new_oid,
            команда_внешнего_ограждения=команда_ограждения,
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
            return finished_clean_result(
                контекст_очереди,
                observed_queue_oid,
                observed_completion,
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


def atomic_commit_and_handoff(
    контекст_очереди: QueueContext,
    task_id: str,
    generation: str,
    message: str,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    if not generation or "\0" in generation or "\n" in generation:
        raise QueueError(EXIT_CLI, "invalid_generation", "Некорректное поколение владельца.")
    if not message.strip():
        raise QueueError(EXIT_CLI, "invalid_message", "Сообщение коммита не может быть пустым.")

    ensure_live_branch(контекст_очереди)
    state, state_oid = read_state(контекст_очереди)
    state = ensure_state_identity(контекст_очереди, state, allow_idle_rebind=False)
    previous = matching_completion(
        state,
        kind="committed",
        task_id=task_id,
        generation=generation,
    )
    if previous is not None and completion_head_is_current(контекст_очереди, previous):
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

    unchanged_ref_failures = 0
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(контекст_очереди)
        live_head = current_head(контекст_очереди.root)
        if live_head != base_head:
            latest_state, latest_oid = read_state(контекст_очереди)
            completion = matching_completion(
                latest_state,
                kind="committed",
                task_id=task_id,
                generation=generation,
            )
            if live_head == commit_oid and completion is not None:
                return committed_completion_result(контекст_очереди, latest_oid, completion)
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился до атомарной передачи очереди.",
                данные_результата_операции={"expected_head": base_head, "current_head": live_head},
            )

        latest, old_queue_oid = read_state(контекст_очереди)
        require_owner(контекст_очереди, latest, task_id, generation)
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
        updated = copy.deepcopy(latest)
        updated["owner"] = None
        updated["last_completion"] = completion
        updated["updated_at"] = stamp
        new_queue_oid = write_state_blob(контекст_очереди, updated)
        transaction = (
            "start\n"
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
            return 0, {
                "state": "committed",
                "task_id": task_id,
                "ticket_id": owner["ticket_id"],
                "seq": owner["seq"],
                "generation": generation,
                "old_head": base_head,
                "new_head": commit_oid,
                **common_payload(контекст_очереди, new_queue_oid),
            }
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        observed_head = current_head(контекст_очереди.root)
        observed_state, observed_queue_oid = read_state(контекст_очереди)
        observed_completion = matching_completion(
            observed_state,
            kind="committed",
            task_id=task_id,
            generation=generation,
        )
        if observed_head == commit_oid and observed_completion is not None:
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
        f"{ПРОСТРАНСТВО_ПРЕТЕНЗИЙ}/{основа}": "удалить",
        f"{ПРОСТРАНСТВО_ПОЧИНКИ}/{основа}": "удалить",
        f"{ПРОСТРАНСТВО_ЭПОХ_РЕЗЕРВАЦИЙ}/{основа}": "сохранить",
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
) -> tuple[bool, str]:
    новый_объект_очереди = write_state_blob(контекст, состояние)
    ссылка_аннулирования = ссылка_аннулированной_задачи(контекст, идентификатор_задачи)
    нулевой_объект = "0" * len(current_head(контекст.root))
    команды = f"verify {ссылка_аннулирования} {нулевой_объект}\n"
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
        return True, новый_объект_очереди
    потребовать_неаннулированную_задачу(контекст, идентификатор_задачи)
    if read_ref_oid(контекст, контекст.queue_ref) != прежний_объект_очереди:
        return False, новый_объект_очереди
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
    message_group = commit.add_mutually_exclusive_group(required=True)
    message_group.add_argument("--message")
    message_group.add_argument("--message-file")

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


def emit(данные_результата_операции: dict[str, object]) -> None:
    print(json.dumps(данные_результата_операции, ensure_ascii=True, sort_keys=True))


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
            код_завершения_операции, данные_результата_операции = atomic_commit_and_handoff(
                контекст_очереди,
                args.task_id,
                args.generation,
                commit_message_from_args(args),
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
