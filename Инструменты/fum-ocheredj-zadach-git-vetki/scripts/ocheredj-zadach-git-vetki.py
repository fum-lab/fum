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
import subprocess
import sys
import tempfile
import time
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
EXIT_CLI = 64
EXIT_INTERRUPTED = 130


@dataclass(frozen=True)
class QueueContext:
    root: Path
    git_dir: Path
    worktree_id: str
    queue_ref: str
    branch_ref: str


class QueueError(RuntimeError):
    def __init__(
        self,
        exit_code: int,
        state: str,
        message: str,
        *,
        payload: dict[str, object] | None = None,
    ) -> None:
        super().__init__(message)
        self.exit_code = exit_code
        self.state = state
        self.payload = payload or {}


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


def ensure_live_branch(context: QueueContext) -> None:
    live_branch = symbolic_branch(context.root)
    if live_branch != context.branch_ref:
        raise QueueError(
            EXIT_CONTEXT,
            "branch_changed",
            "Git-ветка была переключена после начала операции очереди.",
            payload={
                "expected_branch_ref": context.branch_ref,
                "current_branch_ref": live_branch,
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


def new_state(context: QueueContext) -> dict[str, object]:
    stamp, _ = utc_values()
    return {
        "schema_version": SCHEMA_VERSION,
        "worktree_id": context.worktree_id,
        "branch_ref": context.branch_ref,
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
        if completion["kind"] not in {"committed", "finished_clean"}:
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


def read_ref_oid(context: QueueContext, reference_name: str) -> str | None:
    reference = run_git(
        context.root,
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


def read_state(context: QueueContext) -> tuple[dict[str, object], str | None]:
    oid = read_ref_oid(context, context.queue_ref)
    if oid is None:
        return new_state(context), None
    blob = run_git(context.root, ["cat-file", "blob", oid])
    try:
        state = json.loads(blob.stdout.decode("utf-8", errors="strict"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise QueueError(
            EXIT_CONTEXT,
            "corrupt_queue",
            "Git-ссылка очереди не содержит корректный JSON blob.",
        ) from exc
    return validate_state(state), oid


def ref_retry_delay(attempt: int) -> float:
    return min(REF_RETRY_BASE_SECONDS * (2**attempt), REF_RETRY_MAX_SECONDS)


def update_ref_error(operation: str, stderr: str) -> NoReturn:
    detail = stderr.strip() or "Git не вернул текст ошибки."
    raise QueueError(
        EXIT_CAS,
        "git_error",
        f"Не удалось {operation}: {detail}",
        payload={"git_stderr": detail},
    )


def write_state_blob(context: QueueContext, state: dict[str, object]) -> str:
    validate_state(state)
    result = run_git(
        context.root,
        ["hash-object", "-w", "--stdin"],
        input_bytes=canonical_state_bytes(state),
    )
    return decoded_stdout(result)


def cas_state(
    context: QueueContext,
    old_oid: str | None,
    state: dict[str, object],
) -> tuple[bool, str]:
    new_oid = write_state_blob(context, state)
    last_stderr = ""
    for attempt in range(UNCHANGED_REF_RETRY_ATTEMPTS):
        result = run_git(
            context.root,
            ["update-ref", context.queue_ref, new_oid, old_oid or ""],
            check=False,
        )
        if result.returncode == 0:
            return True, new_oid
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        current_oid = read_ref_oid(context, context.queue_ref)
        if current_oid != old_oid:
            time.sleep(REF_RETRY_BASE_SECONDS)
            return False, new_oid
        if attempt + 1 < UNCHANGED_REF_RETRY_ATTEMPTS:
            time.sleep(ref_retry_delay(attempt))
    update_ref_error("обновить Git-ссылку очереди", last_stderr)


def update_queue_with_head_verification(
    context: QueueContext,
    *,
    expected_head: str,
    old_queue_oid: str,
    new_queue_oid: str,
) -> subprocess.CompletedProcess[bytes]:
    transaction = (
        "start\n"
        f"verify {context.branch_ref} {expected_head}\n"
        f"update {context.queue_ref} {new_queue_oid} {old_queue_oid}\n"
        "prepare\n"
        "commit\n"
    ).encode("utf-8")
    return run_git(
        context.root,
        ["update-ref", "--stdin"],
        input_bytes=transaction,
        check=False,
    )


def ensure_state_identity(
    context: QueueContext,
    state: dict[str, object],
    *,
    allow_idle_rebind: bool,
) -> dict[str, object]:
    if state["worktree_id"] != context.worktree_id:
        raise QueueError(
            EXIT_CONTEXT,
            "invalid_context",
            "Git-ссылка очереди принадлежит другому worktree.",
        )
    if state["branch_ref"] == context.branch_ref:
        return state
    if allow_idle_rebind and state["owner"] is None and not state["waiting"]:
        rebound = copy.deepcopy(state)
        rebound["branch_ref"] = context.branch_ref
        rebound["updated_at"] = utc_values()[0]
        return rebound
    raise QueueError(
        EXIT_CONTEXT,
        "branch_changed",
        "В worktree переключена ветка при непустой очереди.",
        payload={
            "expected_branch_ref": state["branch_ref"],
            "current_branch_ref": context.branch_ref,
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
    context: QueueContext,
    state_oid: str | None,
) -> dict[str, object]:
    return {
        "queue_ref": context.queue_ref,
        "queue_oid": state_oid,
        "worktree_id": context.worktree_id,
        "branch_ref": context.branch_ref,
    }


def owner_result(
    context: QueueContext,
    owner: dict[str, object],
    state_oid: str | None,
    *,
    ownership: str,
) -> tuple[int, dict[str, object]]:
    return 0, {
        "state": "admitted",
        "ownership": ownership,
        **owner,
        **common_payload(context, state_oid),
    }


def waiting_result(
    context: QueueContext,
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
                **common_payload(context, state_oid),
            }
    raise QueueError(
        EXIT_NOT_REGISTERED,
        "not_registered",
        "Задача не зарегистрирована в очереди.",
    )


def attempt_admit(
    context: QueueContext,
    task_id: str,
) -> tuple[int, dict[str, object]]:
    unchanged_ref_failures = 0
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(context)
        state, old_oid = read_state(context)
        state = ensure_state_identity(context, state, allow_idle_rebind=False)
        owner = state["owner"]
        if isinstance(owner, dict):
            if owner["task_id"] == task_id:
                return owner_result(
                    context,
                    owner,
                    old_oid,
                    ownership="existing",
                )
            return waiting_result(context, state, old_oid, task_id)

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
            return waiting_result(context, state, old_oid, task_id)

        ticket = waiting[0]
        head = current_head(context.root)
        if ticket["acknowledged_head"] != head:
            return EXIT_RELOAD_REQUIRED, {
                "state": "reload_required",
                "position": 1,
                **ticket,
                "current_head": head,
                **common_payload(context, old_oid),
            }
        blocking = all_changed_paths(context.root)
        if blocking:
            return EXIT_DIRTY, {
                "state": "dirty",
                "position": 1,
                **ticket,
                "blocking_paths": blocking,
                **common_payload(context, old_oid),
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
        new_oid = write_state_blob(context, updated)
        result = update_queue_with_head_verification(
            context,
            expected_head=head,
            old_queue_oid=old_oid,
            new_queue_oid=new_oid,
        )
        if result.returncode == 0:
            return owner_result(
                context,
                owner_record,
                new_oid,
                ownership="new",
            )
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        observed_head = current_head(context.root)
        _, observed_queue_oid = read_state(context)
        if observed_head != head or observed_queue_oid != old_oid:
            unchanged_ref_failures = 0
            time.sleep(REF_RETRY_BASE_SECONDS)
            continue
        unchanged_ref_failures += 1
        if unchanged_ref_failures >= UNCHANGED_REF_RETRY_ATTEMPTS:
            update_ref_error("атомарно допустить владельца очереди", last_stderr)
        time.sleep(ref_retry_delay(unchanged_ref_failures - 1))
    raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось получить место владельца.")


def join_queue(context: QueueContext, task_id: str) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(context)
        state, old_oid = read_state(context)
        identity_state = ensure_state_identity(
            context,
            state,
            allow_idle_rebind=True,
        )
        owner = identity_state["owner"]
        if isinstance(owner, dict) and owner["task_id"] == task_id:
            return owner_result(context, owner, old_oid, ownership="existing")

        existing: dict[str, object] | None = None
        for ticket in identity_state["waiting"]:
            if ticket["task_id"] == task_id:
                existing = ticket
                break
        if existing is not None:
            return attempt_admit(context, task_id)

        stamp, epoch = utc_values()
        updated = copy.deepcopy(identity_state)
        ticket = {
            "task_id": task_id,
            "ticket_id": str(uuid.uuid4()),
            "seq": updated["next_seq"],
            "registered_at": stamp,
            "registered_at_epoch": epoch,
            "acknowledged_head": current_head(context.root),
        }
        updated["next_seq"] = int(updated["next_seq"]) + 1
        updated["waiting"].append(ticket)
        updated["updated_at"] = stamp

        success, _ = cas_state(context, old_oid, updated)
        if success:
            break
    else:
        raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось зарегистрировать задачу.")
    return attempt_admit(context, task_id)


def wait_queue(
    context: QueueContext,
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
        code, payload = attempt_admit(context, task_id)
        if code != EXIT_WAITING:
            return code, payload
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return code, payload
        time.sleep(min(WAIT_POLL_SECONDS, remaining))


def wait_until_actionable_queue(
    context: QueueContext,
    task_id: str,
) -> tuple[int, dict[str, object]]:
    while True:
        code, payload = wait_queue(
            context,
            task_id,
            DEFAULT_WAIT_TIMEOUT_SECONDS,
        )
        if code != EXIT_WAITING:
            return code, payload


def acknowledge_head(
    context: QueueContext,
    task_id: str,
    acknowledged_head: str,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    live_head = current_head(context.root)
    if acknowledged_head != live_head:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_mismatch",
            "Подтверждаемая ревизия не совпадает с текущим HEAD.",
            payload={
                "expected_head": live_head,
                "provided_head": acknowledged_head,
            },
        )
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(context)
        state, old_oid = read_state(context)
        state = ensure_state_identity(context, state, allow_idle_rebind=False)
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
        success, new_oid = cas_state(context, old_oid, updated)
        if success:
            return 0, {
                "state": "acknowledged",
                **target,
                **common_payload(context, new_oid),
            }
    raise QueueError(EXIT_CAS, "cas_conflict", "Не удалось подтвердить новый HEAD.")


def cancel_waiter(
    context: QueueContext,
    task_id: str,
    ticket_id: str | None,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(context)
        state, old_oid = read_state(context)
        state = ensure_state_identity(context, state, allow_idle_rebind=False)
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
        success, new_oid = cas_state(context, old_oid, updated)
        if success:
            return 0, {
                "state": "cancelled",
                "task_id": task_id,
                "ticket_id": ticket_id,
                **common_payload(context, new_oid),
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
    context: QueueContext,
    state: dict[str, object],
    task_id: str,
    generation: str,
) -> dict[str, object]:
    state = ensure_state_identity(context, state, allow_idle_rebind=False)
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
    context: QueueContext,
    state_oid: str | None,
    completion: dict[str, object],
) -> tuple[int, dict[str, object]]:
    return 0, {
        "state": "finished_clean",
        **completion,
        **common_payload(context, state_oid),
    }


def committed_completion_result(
    context: QueueContext,
    state_oid: str | None,
    completion: dict[str, object],
) -> tuple[int, dict[str, object]]:
    return 0, {
        "state": "committed",
        "task_id": completion["task_id"],
        "generation": completion["generation"],
        "old_head": completion["base_head"],
        "new_head": completion["head"],
        **common_payload(context, state_oid),
    }


def completion_head_is_current(
    context: QueueContext,
    completion: dict[str, object],
) -> bool:
    return current_head(context.root) == completion["head"]


def finish_clean_and_handoff(
    context: QueueContext,
    task_id: str,
    generation: str,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    if not generation or "\0" in generation or "\n" in generation:
        raise QueueError(EXIT_CLI, "invalid_generation", "Некорректное поколение владельца.")

    unchanged_ref_failures = 0
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(context)
        state, old_oid = read_state(context)
        state = ensure_state_identity(context, state, allow_idle_rebind=False)
        previous = matching_completion(
            state,
            kind="finished_clean",
            task_id=task_id,
            generation=generation,
        )
        if previous is not None:
            return finished_clean_result(context, old_oid, previous)
        owner = require_owner(context, state, task_id, generation)
        base_head = str(owner["base_head"])
        live_head = current_head(context.root)
        if live_head != base_head:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился после допуска владельца.",
                payload={"expected_head": base_head, "current_head": live_head},
            )
        blocking = sorted(
            set(all_changed_paths(context.root))
            | set(staged_changed_paths(context.root))
        )
        if blocking:
            raise QueueError(
                EXIT_DIRTY,
                "dirty",
                "Чистое завершение требует чистоты вне корневой .obsidian/ и отсутствия любых staged-изменений.",
                payload={"blocking_paths": blocking},
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
        new_oid = write_state_blob(context, updated)
        result = update_queue_with_head_verification(
            context,
            expected_head=base_head,
            old_queue_oid=old_oid,
            new_queue_oid=new_oid,
        )
        if result.returncode == 0:
            return finished_clean_result(context, new_oid, completion)
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        observed_head = current_head(context.root)
        observed_state, observed_queue_oid = read_state(context)
        observed_completion = matching_completion(
            observed_state,
            kind="finished_clean",
            task_id=task_id,
            generation=generation,
        )
        if observed_completion is not None:
            return finished_clean_result(
                context,
                observed_queue_oid,
                observed_completion,
            )
        if observed_head != base_head:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился во время чистого завершения.",
                payload={"expected_head": base_head, "current_head": observed_head},
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


def atomic_commit_and_handoff(
    context: QueueContext,
    task_id: str,
    generation: str,
    message: str,
) -> tuple[int, dict[str, object]]:
    task_id = validate_task_id(task_id)
    if not generation or "\0" in generation or "\n" in generation:
        raise QueueError(EXIT_CLI, "invalid_generation", "Некорректное поколение владельца.")
    if not message.strip():
        raise QueueError(EXIT_CLI, "invalid_message", "Сообщение коммита не может быть пустым.")

    ensure_live_branch(context)
    state, state_oid = read_state(context)
    state = ensure_state_identity(context, state, allow_idle_rebind=False)
    previous = matching_completion(
        state,
        kind="committed",
        task_id=task_id,
        generation=generation,
    )
    if previous is not None and completion_head_is_current(context, previous):
        return committed_completion_result(context, state_oid, previous)
    owner = require_owner(context, state, task_id, generation)
    base_head = str(owner["base_head"])
    live_head = current_head(context.root)
    if live_head != base_head:
        raise QueueError(
            EXIT_HEAD_CHANGED,
            "head_changed",
            "HEAD изменился после допуска владельца.",
            payload={"expected_head": base_head, "current_head": live_head},
        )

    blocking = unsafe_commit_paths(context.root)
    if blocking:
        raise QueueError(
            EXIT_DIRTY,
            "dirty",
            "Перед атомарным коммитом остаются unstaged, untracked или конфликтные пути.",
            payload={"blocking_paths": blocking},
        )
    if not staged_changes_exist(context.root):
        raise QueueError(
            EXIT_NOTHING_STAGED,
            "nothing_staged",
            "Для завершения задачи нет staged-изменений.",
        )

    tree = decoded_stdout(run_git(context.root, ["write-tree"]))
    parent_tree = decoded_stdout(
        run_git(context.root, ["rev-parse", f"{base_head}^{{tree}}"])
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
            context.root,
            ["commit-tree", tree, "-p", base_head],
            input_bytes=commit_message.encode("utf-8"),
        )
    )

    unchanged_ref_failures = 0
    for _ in range(MAX_CAS_ATTEMPTS):
        ensure_live_branch(context)
        live_head = current_head(context.root)
        if live_head != base_head:
            latest_state, latest_oid = read_state(context)
            completion = matching_completion(
                latest_state,
                kind="committed",
                task_id=task_id,
                generation=generation,
            )
            if live_head == commit_oid and completion is not None:
                return committed_completion_result(context, latest_oid, completion)
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился до атомарной передачи очереди.",
                payload={"expected_head": base_head, "current_head": live_head},
            )

        latest, old_queue_oid = read_state(context)
        require_owner(context, latest, task_id, generation)
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
        new_queue_oid = write_state_blob(context, updated)
        transaction = (
            "start\n"
            f"update {context.branch_ref} {commit_oid} {base_head}\n"
            f"update {context.queue_ref} {new_queue_oid} {old_queue_oid}\n"
            "prepare\n"
            "commit\n"
        ).encode("utf-8")
        result = run_git(
            context.root,
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
                **common_payload(context, new_queue_oid),
            }
        last_stderr = result.stderr.decode("utf-8", errors="replace").strip()
        observed_head = current_head(context.root)
        observed_state, observed_queue_oid = read_state(context)
        observed_completion = matching_completion(
            observed_state,
            kind="committed",
            task_id=task_id,
            generation=generation,
        )
        if observed_head == commit_oid and observed_completion is not None:
            return committed_completion_result(
                context,
                observed_queue_oid,
                observed_completion,
            )
        if observed_head != base_head:
            raise QueueError(
                EXIT_HEAD_CHANGED,
                "head_changed",
                "HEAD изменился во время атомарной передачи очереди.",
                payload={"expected_head": base_head, "current_head": observed_head},
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
    payload: dict[str, object] = {
        "commit": commit,
        "branch_ref": branch_ref,
    }
    if remote_head is not None:
        payload["remote_head"] = remote_head
    raise QueueError(exit_code, state, message, payload=payload)


def publish_exact_commit(
    context: QueueContext,
    commit: str,
    branch_ref: str,
    push_url: str,
    *,
    allow_url_rewrite_for_tests: bool = False,
) -> tuple[int, dict[str, object]]:
    commit = validate_publication_commit(context.root, commit)
    branch_ref = validate_publication_branch(context.root, branch_ref)
    push_url = validate_github_push_url(push_url)
    rewrites = publication_url_rewrites(context.root, push_url)
    if rewrites and not allow_url_rewrite_for_tests:
        raise QueueError(
            EXIT_CLI,
            "invalid_url_rewrite",
            "Применимое url.*.insteadOf или pushInsteadOf запрещает доказать точный GitHub endpoint.",
        )
    refspec = f"{commit}:{branch_ref}"
    pushed = run_publication_git(
        context.root,
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

    observed, remote_head = remote_branch_head(context.root, push_url, branch_ref)
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

    remote_available = commit_exists(context.root, remote_head)
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
        commit_before_remote = is_ancestor(context.root, commit, remote_head)
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
        remote_before_commit = is_ancestor(context.root, remote_head, commit)
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

    contains = remote_contains_commit(context.root, push_url, branch_ref, commit)
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


def queue_status(context: QueueContext) -> tuple[int, dict[str, object]]:
    ensure_live_branch(context)
    state, state_oid = read_state(context)
    if state["worktree_id"] != context.worktree_id:
        raise QueueError(EXIT_CONTEXT, "invalid_context", "Очередь принадлежит другому worktree.")
    if (
        state["branch_ref"] != context.branch_ref
        and (state["owner"] is not None or state["waiting"])
    ):
        raise QueueError(
            EXIT_CONTEXT,
            "branch_changed",
            "В worktree переключена ветка при непустой очереди.",
            payload={
                "expected_branch_ref": state["branch_ref"],
                "current_branch_ref": context.branch_ref,
            },
        )
    return 0, {
        "state": "active" if state["owner"] is not None or state["waiting"] else "idle",
        "owner": state["owner"],
        "waiting": state["waiting"],
        "next_seq": state["next_seq"],
        "stored_branch_ref": state["branch_ref"],
        **common_payload(context, state_oid),
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
        **error.payload,
    }


def emit(payload: dict[str, object]) -> None:
    print(json.dumps(payload, ensure_ascii=True, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        context = resolve_context(args.repo_root)
        if args.command == "status":
            code, payload = queue_status(context)
        elif args.command == "join":
            code, payload = join_queue(context, args.task_id)
        elif args.command == "wait":
            code, payload = wait_queue(context, args.task_id, args.timeout_seconds)
        elif args.command == "wait-until-actionable":
            code, payload = wait_until_actionable_queue(context, args.task_id)
        elif args.command == "ack-head":
            code, payload = acknowledge_head(context, args.task_id, args.head)
        elif args.command == "cancel":
            code, payload = cancel_waiter(
                context,
                args.task_id,
                args.ticket_id,
            )
        elif args.command == "finish-clean":
            code, payload = finish_clean_and_handoff(
                context,
                args.task_id,
                args.generation,
            )
        elif args.command == "commit":
            code, payload = atomic_commit_and_handoff(
                context,
                args.task_id,
                args.generation,
                commit_message_from_args(args),
            )
        elif args.command == "publish":
            code, payload = publish_exact_commit(
                context,
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
    emit(payload)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
