#!/usr/bin/env python3
"""Serialize root Codex tasks and dirty work per attached Git branch."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import math
import os
import subprocess
import sys
import tempfile
import time
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator, NoReturn

try:
    import fcntl
except ImportError:  # pragma: no cover - the project hook is POSIX-only.
    fcntl = None


SCHEMA_VERSION = 6
LEGACY_SCHEMA_VERSIONS = frozenset({4, 5})
DEFAULT_HOOK_WAIT_SECONDS = 85_800
PROMPT_ADMISSION_MARKER = "FUM-BRANCH-TASK-GATE: admitted-v1"
OWNER_CONTEXT_PREFIX = "FUM-BRANCH-TASK-GATE-OWNER: "
GIT_COMMAND_TIMEOUT_SECONDS = 20
TRANSITION_LOCK_TIMEOUT_SECONDS = 20
EXIT_BUSY = 1
EXIT_LOCK_TIMEOUT = 10
EXIT_DIRTY_TIMEOUT = 11
EXIT_CONTEXT = 12
EXIT_BRANCH_CHANGED = 13
EXIT_IO = 14
EXIT_DIRTY_RELEASE = 15
EXIT_OWNERSHIP = 16
EXIT_CLI = 64


@dataclass(frozen=True)
class GateContext:
    root: Path
    common_git_dir: Path
    branch_ref: str
    worktree_id: str
    gate_dir: Path
    guard_path: Path
    lock_path: Path


@dataclass(frozen=True)
class LockRecord:
    task_id: str
    turn_id: str
    branch_ref: str
    acquired_at: str
    lease_id: str
    worktree_id: str


class GateError(RuntimeError):
    def __init__(
        self,
        exit_code: int,
        message: str,
        *,
        payload: dict[str, object] | None = None,
    ) -> None:
        super().__init__(message)
        self.exit_code = exit_code
        self.payload = payload or {}


def run_git(
    cwd: Path,
    args: list[str],
    *,
    check: bool = True,
) -> subprocess.CompletedProcess[bytes]:
    try:
        result = subprocess.run(
            ["git", "-C", str(cwd), *args],
            check=False,
            capture_output=True,
            timeout=GIT_COMMAND_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as exc:
        raise GateError(
            EXIT_IO,
            "Git не завершил проверку веточного барьера за "
            f"{GIT_COMMAND_TIMEOUT_SECONDS} секунд.",
        ) from exc
    except OSError as exc:
        raise GateError(EXIT_IO, f"Не удалось запустить Git: {exc}") from exc

    if check and result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        suffix = f": {detail}" if detail else ""
        raise GateError(
            EXIT_CONTEXT,
            f"Git не смог определить состояние рабочей копии{suffix}",
        )
    return result


def decode_git_path(value: bytes) -> str:
    return value.decode("utf-8", errors="surrogateescape")


def parse_porcelain_v1_z(output: bytes) -> list[str]:
    paths: set[str] = set()
    records = output.split(b"\0")
    index = 0
    while index < len(records):
        record = records[index]
        index += 1
        if not record:
            continue
        if len(record) < 4 or record[2:3] != b" ":
            raise GateError(
                EXIT_IO,
                "Git вернул неизвестный формат status --porcelain=v1 -z",
            )

        status = record[:2]
        paths.add(decode_git_path(record[3:]))
        if b"R" in status or b"C" in status:
            if index >= len(records) or not records[index]:
                raise GateError(
                    EXIT_IO,
                    "Git вернул неполную запись переименования",
                )
            paths.add(decode_git_path(records[index]))
            index += 1
    return sorted(paths)


def git_paths(root: Path, pathspecs: list[str]) -> list[str]:
    result = run_git(
        root,
        [
            "-c",
            "core.quotepath=false",
            "status",
            "--porcelain=v1",
            "-z",
            "--untracked-files=all",
            "--ignore-submodules=none",
            "--",
            *pathspecs,
        ],
    )
    return parse_porcelain_v1_z(result.stdout)


def blocking_paths(root: Path) -> list[str]:
    return git_paths(
        root,
        [
            ".",
            ":(top,exclude).obsidian",
            ":(top,exclude).obsidian/**",
        ],
    )


def ignored_obsidian_paths(root: Path) -> list[str]:
    return git_paths(root, [":(top).obsidian", ":(top).obsidian/**"])


def symbolic_branch(root: Path) -> str:
    result = run_git(root, ["symbolic-ref", "--quiet", "HEAD"], check=False)
    if result.returncode == 1:
        raise GateError(
            EXIT_CONTEXT,
            "Веточный барьер не работает в detached HEAD: переключитесь на "
            "именованную локальную ветку.",
        )
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        suffix = f": {detail}" if detail else ""
        raise GateError(
            EXIT_CONTEXT,
            f"Не удалось определить текущую Git-ветку{suffix}",
        )
    branch_ref = result.stdout.decode("utf-8", errors="strict").strip()
    if not branch_ref.startswith("refs/heads/"):
        raise GateError(
            EXIT_CONTEXT,
            f"Неподдерживаемая ссылка HEAD: {branch_ref}",
        )
    return branch_ref


def worktrees_for_branch(root: Path, branch_ref: str) -> list[Path]:
    result = run_git(root, ["worktree", "list", "--porcelain", "-z"])
    worktrees: list[Path] = []
    for block in result.stdout.split(b"\0\0"):
        if not block:
            continue
        fields = block.split(b"\0")
        worktree: Path | None = None
        branch: str | None = None
        for field in fields:
            if field.startswith(b"worktree "):
                worktree = Path(decode_git_path(field[len(b"worktree ") :])).resolve()
            elif field.startswith(b"branch "):
                branch = field[len(b"branch ") :].decode("utf-8", errors="strict")
        if worktree is not None and branch == branch_ref:
            worktrees.append(worktree)
    return worktrees


def ensure_unique_branch_worktree(root: Path, branch_ref: str) -> None:
    worktrees = worktrees_for_branch(root, branch_ref)
    if len(worktrees) > 1:
        raise GateError(
            EXIT_CONTEXT,
            "Одна Git-ветка принудительно открыта в нескольких worktree. "
            "Веточный барьер не может надёжно проверить их общее грязное "
            "состояние; оставьте для ветки один worktree.",
        )


def validate_branch_ref(branch_ref: object) -> str:
    if (
        not isinstance(branch_ref, str)
        or not branch_ref.startswith("refs/heads/")
        or len(branch_ref) > 1_024
        or "\0" in branch_ref
    ):
        raise GateError(
            EXIT_CLI,
            "Полное имя ветки должно иметь вид refs/heads/<имя>.",
        )
    return branch_ref


def resolve_context(
    repo_root: Path,
    *,
    target_branch_ref: str | None = None,
) -> GateContext:
    candidate = repo_root.expanduser().resolve()
    top_level = run_git(candidate, ["rev-parse", "--show-toplevel"])
    root = Path(top_level.stdout.decode("utf-8", errors="strict").strip()).resolve()

    common_result = run_git(root, ["rev-parse", "--git-common-dir"])
    common_value = Path(
        common_result.stdout.decode("utf-8", errors="strict").strip()
    )
    common_git_dir = (
        common_value if common_value.is_absolute() else root / common_value
    ).resolve()
    git_dir_result = run_git(root, ["rev-parse", "--git-dir"])
    git_dir_value = Path(
        git_dir_result.stdout.decode("utf-8", errors="strict").strip()
    )
    git_dir = (
        git_dir_value if git_dir_value.is_absolute() else root / git_dir_value
    ).resolve()
    try:
        worktree_key = git_dir.relative_to(common_git_dir).as_posix()
    except ValueError:
        worktree_key = str(git_dir)
    worktree_id = hashlib.sha256(
        os.fsencode(worktree_key),
    ).hexdigest()
    if target_branch_ref is None:
        branch_ref = symbolic_branch(root)
        ensure_unique_branch_worktree(root, branch_ref)
    else:
        branch_ref = validate_branch_ref(target_branch_ref)
    branch_hash = hashlib.sha256(branch_ref.encode("utf-8")).hexdigest()
    gate_dir = common_git_dir / "fum-branch-task-gate"
    lock_path = gate_dir / f"{branch_hash}.json"
    return GateContext(
        root=root,
        common_git_dir=common_git_dir,
        branch_ref=branch_ref,
        worktree_id=worktree_id,
        gate_dir=gate_dir,
        guard_path=gate_dir / ".transitions.lock",
        lock_path=lock_path,
    )


def ensure_gate_dir(context: GateContext) -> None:
    try:
        context.gate_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        context.gate_dir.chmod(0o700)
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось подготовить каталог веточного барьера: {exc}",
        ) from exc


def fsync_gate_dir(context: GateContext) -> None:
    try:
        descriptor = os.open(context.gate_dir, os.O_RDONLY)
        try:
            os.fsync(descriptor)
        finally:
            os.close(descriptor)
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось синхронизировать каталог веточного барьера: {exc}",
        ) from exc


@contextlib.contextmanager
def transition_lock(context: GateContext) -> Iterator[None]:
    if fcntl is None:
        raise GateError(
            EXIT_CONTEXT,
            "Веточный барьер требует POSIX flock и не поддерживается "
            "текущей платформой.",
        )
    ensure_gate_dir(context)
    try:
        descriptor = os.open(
            context.guard_path,
            os.O_RDWR | os.O_CREAT,
            0o600,
        )
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось открыть блокировку переходов: {exc}",
        ) from exc
    try:
        deadline = time.monotonic() + TRANSITION_LOCK_TIMEOUT_SECONDS
        while True:
            try:
                fcntl.flock(
                    descriptor,
                    fcntl.LOCK_EX | fcntl.LOCK_NB,
                )
                break
            except BlockingIOError as exc:
                if time.monotonic() >= deadline:
                    raise GateError(
                        EXIT_IO,
                        "Не удалось дождаться сериализации перехода "
                        "веточного барьера за "
                        f"{TRANSITION_LOCK_TIMEOUT_SECONDS} секунд.",
                    ) from exc
                time.sleep(0.05)
            except OSError as exc:
                raise GateError(
                    EXIT_IO,
                    "Не удалось сериализовать переход веточного "
                    f"барьера: {exc}",
                ) from exc
        yield
    finally:
        try:
            fcntl.flock(descriptor, fcntl.LOCK_UN)
        except OSError:
            pass
        os.close(descriptor)


def validate_task_id(task_id: object) -> str:
    if not isinstance(task_id, str) or not task_id.strip():
        raise GateError(EXIT_CLI, "Идентификатор задачи должен быть непустой строкой.")
    if len(task_id) > 512 or any(character in task_id for character in "\0\r\n"):
        raise GateError(EXIT_CLI, "Идентификатор задачи имеет недопустимый формат.")
    return task_id


def validate_lease_id(lease_id: object) -> str:
    if (
        not isinstance(lease_id, str)
        or len(lease_id) != 32
        or any(character not in "0123456789abcdef" for character in lease_id)
    ):
        raise GateError(
            EXIT_CLI,
            "Поколение владения должно быть 32-символьным hex lease_id "
            "из предварительного status --json.",
        )
    return lease_id


def lock_payload(record: LockRecord) -> dict[str, object]:
    return {
        "schema_version": SCHEMA_VERSION,
        "task_id": record.task_id,
        "turn_id": record.turn_id,
        "branch_ref": record.branch_ref,
        "acquired_at": record.acquired_at,
        "lease_id": record.lease_id,
        "worktree_id": record.worktree_id,
    }


def parse_lock_payload(
    payload: object,
    *,
    expected_branch_ref: str | None,
) -> LockRecord:
    if not isinstance(payload, dict):
        raise GateError(EXIT_OWNERSHIP, "Файл владения веткой повреждён.")
    schema_version = payload.get("schema_version")
    if schema_version not in {SCHEMA_VERSION, *LEGACY_SCHEMA_VERSIONS}:
        raise GateError(
            EXIT_OWNERSHIP,
            "Файл владения веткой имеет неизвестную версию схемы.",
        )
    task_id = payload.get("task_id")
    turn_id = payload.get("turn_id")
    branch_ref = payload.get("branch_ref")
    acquired_at = payload.get("acquired_at")
    lease_id = payload.get("lease_id")
    worktree_id = payload.get("worktree_id")
    if not all(
        isinstance(item, str) and item
        for item in (
            task_id,
            turn_id,
            branch_ref,
            acquired_at,
            lease_id,
            worktree_id,
        )
    ):
        raise GateError(EXIT_OWNERSHIP, "Файл владения веткой неполон.")
    if expected_branch_ref is not None and branch_ref != expected_branch_ref:
        raise GateError(
            EXIT_OWNERSHIP,
            "Файл владения не соответствует ветке, указанной его именем.",
        )
    return LockRecord(
        task_id=task_id,
        turn_id=turn_id,
        branch_ref=branch_ref,
        acquired_at=acquired_at,
        lease_id=lease_id,
        worktree_id=worktree_id,
    )


def read_lock_path(
    path: Path,
    *,
    expected_branch_ref: str | None,
) -> LockRecord | None:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return None
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось прочитать файл владения веткой: {exc}",
        ) from exc
    except UnicodeError as exc:
        raise GateError(
            EXIT_OWNERSHIP,
            "Файл владения веткой содержит некорректный UTF-8.",
        ) from exc
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise GateError(
            EXIT_OWNERSHIP,
            "Файл владения веткой содержит некорректный JSON.",
        ) from exc
    return parse_lock_payload(
        payload,
        expected_branch_ref=expected_branch_ref,
    )


def read_lock(context: GateContext) -> LockRecord | None:
    return read_lock_path(
        context.lock_path,
        expected_branch_ref=context.branch_ref,
    )


def new_lock_record(
    context: GateContext,
    task_id: str,
    turn_id: str | None,
) -> LockRecord:
    return LockRecord(
        task_id=task_id,
        turn_id=task_id if turn_id is None else turn_id,
        branch_ref=context.branch_ref,
        acquired_at=datetime.now(timezone.utc).isoformat(),
        lease_id=uuid.uuid4().hex,
        worktree_id=context.worktree_id,
    )


def write_temporary_lock(
    context: GateContext,
    record: LockRecord,
) -> Path:
    ensure_gate_dir(context)
    data = (
        json.dumps(lock_payload(record), ensure_ascii=False, sort_keys=True)
        + "\n"
    ).encode(
        "utf-8",
    )
    temporary_path: Path | None = None
    descriptor: int | None = None
    try:
        descriptor, temporary_name = tempfile.mkstemp(
            prefix=".lease-",
            suffix=".tmp",
            dir=context.gate_dir,
        )
        temporary_path = Path(temporary_name)
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb") as stream:
            descriptor = None
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    except OSError as exc:
        if temporary_path is not None:
            try:
                temporary_path.unlink()
            except OSError:
                pass
        raise GateError(
            EXIT_IO,
            f"Не удалось подготовить файл владения веткой: {exc}",
        ) from exc
    finally:
        if descriptor is not None:
            try:
                os.close(descriptor)
            except OSError:
                pass
    if temporary_path is None:
        raise GateError(EXIT_IO, "Не удалось подготовить файл владения веткой.")
    return temporary_path


def create_lock(
    context: GateContext,
    task_id: str,
    turn_id: str | None = None,
) -> LockRecord | None:
    record = new_lock_record(context, task_id, turn_id)
    temporary_path = write_temporary_lock(context, record)
    try:
        try:
            os.link(temporary_path, context.lock_path)
        except FileExistsError:
            return None
        fsync_gate_dir(context)
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось захватить веточный барьер: {exc}",
        ) from exc
    finally:
        try:
            temporary_path.unlink()
        except FileNotFoundError:
            pass
        except OSError:
            pass
    return record


def replace_lock(
    context: GateContext,
    *,
    expected_lease_id: str,
    task_id: str,
    turn_id: str,
) -> LockRecord | None:
    active = read_lock(context)
    if active is None or active.lease_id != expected_lease_id:
        return None
    record = new_lock_record(context, task_id, turn_id)
    temporary_path = write_temporary_lock(context, record)
    try:
        os.replace(temporary_path, context.lock_path)
        fsync_gate_dir(context)
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось обновить поколение владения веткой: {exc}",
        ) from exc
    finally:
        try:
            temporary_path.unlink()
        except FileNotFoundError:
            pass
        except OSError:
            pass
    return record


def unlink_lock(
    context: GateContext,
    *,
    expected_lease_id: str | None,
) -> bool:
    if expected_lease_id is not None:
        active = read_lock(context)
        if active is None or active.lease_id != expected_lease_id:
            return False
    try:
        context.lock_path.unlink()
    except FileNotFoundError:
        return expected_lease_id is None
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось освободить веточный барьер: {exc}",
        ) from exc
    fsync_gate_dir(context)
    return True


def all_lock_records(context: GateContext) -> list[tuple[Path, LockRecord]]:
    try:
        paths = sorted(context.gate_dir.glob("*.json"))
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось перечислить владения веточного барьера: {exc}",
        ) from exc
    records: list[tuple[Path, LockRecord]] = []
    for path in paths:
        record = read_lock_path(path, expected_branch_ref=None)
        if record is None:
            continue
        expected_name = (
            hashlib.sha256(record.branch_ref.encode("utf-8")).hexdigest()
            + ".json"
        )
        if path.name != expected_name:
            raise GateError(
                EXIT_OWNERSHIP,
                "Файл владения не соответствует ветке, указанной его именем.",
            )
        records.append((path, record))
    return records


def ensure_no_conflicting_lease(
    context: GateContext,
    task_id: str,
) -> None:
    records = [
        record
        for path, record in all_lock_records(context)
        if path != context.lock_path
    ]
    same_task = [record for record in records if record.task_id == task_id]
    if same_task:
        branches = ", ".join(
            sorted(record.branch_ref for record in same_task)
        )
        raise GateError(
            EXIT_BRANCH_CHANGED,
            "Эта задача уже владеет другой Git-веткой "
            f"({branches}). Верните исходную ветку или выполните явное "
            "аварийное восстановление после проверки активности задачи.",
        )
    same_worktree = [
        record for record in records if record.worktree_id == context.worktree_id
    ]
    if same_worktree:
        branches = ", ".join(
            sorted(record.branch_ref for record in same_worktree)
        )
        raise GateError(
            EXIT_BRANCH_CHANGED,
            "Этот worktree сохраняет владение другой Git-веткой "
            f"({branches}). Верните исходную ветку или выполните адресное "
            "аварийное восстановление после проверки активности владельца.",
        )


def state_name(record: LockRecord | None, dirty: list[str]) -> str:
    if record is not None and dirty:
        return "locked_and_dirty"
    if record is not None:
        return "locked"
    if dirty:
        return "dirty"
    return "ready"


def diagnostic_obsidian_paths(
    context: GateContext,
    *,
    include: bool,
) -> list[str]:
    if not include:
        return []
    return ignored_obsidian_paths(context.root)


def current_state_unlocked(
    context: GateContext,
    *,
    tolerate_corrupt_lock: bool = False,
) -> tuple[LockRecord | None, list[str], list[str], str]:
    try:
        record = read_lock(context)
    except GateError:
        if not tolerate_corrupt_lock:
            raise
        record = None
    if record is None:
        worktree_records = [
            candidate
            for path, candidate in all_lock_records(context)
            if path != context.lock_path
            and candidate.worktree_id == context.worktree_id
        ]
        if worktree_records:
            record = worktree_records[0]
    dirty = blocking_paths(context.root)
    obsidian = ignored_obsidian_paths(context.root)
    return record, dirty, obsidian, state_name(record, dirty)


def current_state(
    context: GateContext,
    *,
    tolerate_corrupt_lock: bool = False,
) -> tuple[LockRecord | None, list[str], list[str], str]:
    with transition_lock(context):
        return current_state_unlocked(
            context,
            tolerate_corrupt_lock=tolerate_corrupt_lock,
        )


def state_payload(
    context: GateContext,
    record: LockRecord | None,
    dirty: list[str],
    obsidian: list[str],
    state: str,
) -> dict[str, object]:
    payload: dict[str, object] = {
        "schema_version": SCHEMA_VERSION,
        "state": state,
        "branch_ref": context.branch_ref,
        "blocking_paths": dirty,
        "ignored_obsidian_count": len(obsidian),
    }
    if record is not None:
        payload["task_id"] = record.task_id
        payload["turn_id"] = record.turn_id
        payload["acquired_at"] = record.acquired_at
        payload["lease_id"] = record.lease_id
        if record.branch_ref != context.branch_ref:
            payload["owner_branch_ref"] = record.branch_ref
    return payload


def ensure_branch_unchanged(context: GateContext) -> None:
    if symbolic_branch(context.root) != context.branch_ref:
        raise GateError(
            EXIT_BRANCH_CHANGED,
            "Текущая Git-ветка изменилась во время ожидания веточного барьера.",
        )


def write_waiting_signal(path: Path) -> None:
    try:
        descriptor = os.open(
            path,
            os.O_WRONLY | os.O_CREAT | os.O_TRUNC,
            0o600,
        )
        try:
            os.write(descriptor, b"waiting\n")
        finally:
            os.close(descriptor)
    except OSError as exc:
        raise GateError(
            EXIT_IO,
            f"Не удалось записать диагностический сигнал ожидания: {exc}",
        ) from exc


def acquire(
    context: GateContext,
    task_id: str,
    *,
    turn_id: str | None = None,
    renew_turn: bool = True,
    timeout_seconds: float | None,
    poll_seconds: float,
    include_obsidian_diagnostics: bool = True,
    waiting_signal_file: Path | None = None,
) -> tuple[dict[str, object], int]:
    started = time.monotonic()
    waiting_signaled = False
    active_turn_id = task_id if turn_id is None else turn_id
    while True:
        with transition_lock(context):
            ensure_branch_unchanged(context)
            ensure_no_conflicting_lease(context, task_id)
            record = read_lock(context)
            dirty = blocking_paths(context.root)
            state = state_name(record, dirty)

            if record is not None and record.task_id == task_id:
                ownership = "existing"
                if record.turn_id != active_turn_id and renew_turn:
                    updated = replace_lock(
                        context,
                        expected_lease_id=record.lease_id,
                        task_id=task_id,
                        turn_id=active_turn_id,
                    )
                    if updated is None:
                        raise GateError(
                            EXIT_OWNERSHIP,
                            "Поколение владения изменилось при переходе "
                            "к новому ходу.",
                        )
                    record = updated
                    ownership = "renewed"
                elif record.turn_id != active_turn_id:
                    ownership = "existing_session"
                payload = state_payload(
                    context,
                    record,
                    dirty,
                    diagnostic_obsidian_paths(
                        context,
                        include=include_obsidian_diagnostics,
                    ),
                    state,
                )
                payload.update(state="acquired", ownership=ownership)
                return payload, 0

            if record is None and not dirty:
                created = create_lock(context, task_id, active_turn_id)
                if created is not None:
                    try:
                        ensure_branch_unchanged(context)
                        dirty_after = blocking_paths(context.root)
                        active = read_lock(context)
                        if (
                            not dirty_after
                            and active is not None
                            and active.lease_id == created.lease_id
                        ):
                            payload = state_payload(
                                context,
                                active,
                                [],
                                diagnostic_obsidian_paths(
                                    context,
                                    include=include_obsidian_diagnostics,
                                ),
                                "acquired",
                            )
                            payload["ownership"] = "new"
                            return payload, 0
                        if active is None or active.lease_id != created.lease_id:
                            raise GateError(
                                EXIT_OWNERSHIP,
                                "Владение веткой потеряно во время захвата.",
                            )
                    except BaseException:
                        try:
                            unlink_lock(
                                context,
                                expected_lease_id=created.lease_id,
                            )
                        except GateError:
                            pass
                        raise
                    if not unlink_lock(
                        context,
                        expected_lease_id=created.lease_id,
                    ):
                        raise GateError(
                            EXIT_OWNERSHIP,
                            "Владение веткой изменилось во время отмены захвата.",
                        )
                    dirty = dirty_after
                    record = None
                else:
                    record = read_lock(context)
                    dirty = blocking_paths(context.root)
                state = state_name(record, dirty)

            if (
                timeout_seconds is not None
                and time.monotonic() - started >= timeout_seconds
            ):
                payload = state_payload(
                    context,
                    record,
                    dirty,
                    diagnostic_obsidian_paths(
                        context,
                        include=include_obsidian_diagnostics,
                    ),
                    state,
                )
                if record is not None:
                    return payload, EXIT_LOCK_TIMEOUT
                return payload, EXIT_DIRTY_TIMEOUT
        if waiting_signal_file is not None and not waiting_signaled:
            write_waiting_signal(waiting_signal_file)
            waiting_signaled = True
        time.sleep(poll_seconds)


def release(
    context: GateContext,
    task_id: str,
    *,
    force: bool,
    expected_turn_id: str | None = None,
    expected_force_lease_id: str | None = None,
    include_obsidian_diagnostics: bool = True,
) -> tuple[dict[str, object], int]:
    with transition_lock(context):
        if not force:
            ensure_branch_unchanged(context)
        if not force:
            ensure_no_conflicting_lease(context, task_id)
        record = read_lock(context)

        dirty = blocking_paths(context.root)
        obsidian = diagnostic_obsidian_paths(
            context,
            include=include_obsidian_diagnostics,
        )
        if record is None:
            payload = state_payload(
                context,
                None,
                dirty,
                obsidian,
                "missing" if force else "already_released",
            )
            return payload, EXIT_OWNERSHIP if force else 0

        if not force and record is not None and record.task_id != task_id:
            payload = state_payload(
                context,
                record,
                dirty,
                obsidian,
                state_name(record, dirty),
            )
            return payload, EXIT_OWNERSHIP
        if (
            not force
            and record is not None
            and expected_turn_id is not None
            and record.turn_id != expected_turn_id
        ):
            payload = state_payload(
                context,
                record,
                dirty,
                obsidian,
                state_name(record, dirty),
            )
            return payload, EXIT_OWNERSHIP
        if (
            force
            and record is not None
            and record.lease_id != expected_force_lease_id
        ):
            payload = state_payload(
                context,
                record,
                dirty,
                obsidian,
                state_name(record, dirty),
            )
            return payload, EXIT_OWNERSHIP
        if not force and dirty:
            payload = state_payload(
                context,
                record,
                dirty,
                obsidian,
                "locked_and_dirty",
            )
            return payload, EXIT_DIRTY_RELEASE

        previous_task_id = None if record is None else record.task_id
        expected_lease_id = None if record is None else record.lease_id
        if not unlink_lock(
            context,
            expected_lease_id=expected_lease_id,
        ):
            active = read_lock(context)
            payload = state_payload(
                context,
                active,
                dirty,
                obsidian,
                state_name(active, dirty),
            )
            return payload, EXIT_OWNERSHIP
        state = "force_released" if force else "released"
        payload = state_payload(context, None, dirty, obsidian, state)
        if force:
            payload["previous_task_id"] = previous_task_id
        return payload, 0


def print_payload(payload: dict[str, object], as_json: bool) -> None:
    if as_json:
        print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
        return
    state = payload.get("state", "unknown")
    branch_ref = payload.get("branch_ref", "unknown")
    print(f"{state}: {branch_ref}")
    for path in payload.get("blocking_paths", []):
        print(f"- {path}")


def status_command(args: argparse.Namespace) -> int:
    context = resolve_context(args.repo_root)
    record, dirty, obsidian, state = current_state(context)
    payload = state_payload(context, record, dirty, obsidian, state)
    print_payload(payload, args.json)
    return 0 if state == "ready" else EXIT_BUSY


def acquire_command(args: argparse.Namespace) -> int:
    context = resolve_context(args.repo_root)
    payload, exit_code = acquire(
        context,
        validate_task_id(args.task_id),
        timeout_seconds=args.timeout_seconds,
        poll_seconds=args.poll_seconds,
        waiting_signal_file=args.waiting_signal_file,
    )
    print_payload(payload, args.json)
    return exit_code


def release_command(args: argparse.Namespace) -> int:
    if args.branch_ref is not None and not args.force:
        raise GateError(
            EXIT_CLI,
            "--branch-ref разрешён только вместе с явным --force.",
        )
    if args.force and args.expected_lease_id is None:
        raise GateError(
            EXIT_CLI,
            "--force требует --expected-lease-id из предварительного "
            "status --json.",
        )
    if not args.force and args.expected_lease_id is not None:
        raise GateError(
            EXIT_CLI,
            "--expected-lease-id разрешён только вместе с --force.",
        )
    context = resolve_context(
        args.repo_root,
        target_branch_ref=args.branch_ref,
    )
    payload, exit_code = release(
        context,
        validate_task_id(args.task_id),
        force=args.force,
        expected_force_lease_id=(
            validate_lease_id(args.expected_lease_id)
            if args.force
            else None
        ),
    )
    print_payload(payload, args.json)
    return exit_code


def hook_failure(message: str) -> None:
    print(
        json.dumps(
            {
                "decision": "block",
                "reason": message,
                "systemMessage": message,
            },
            ensure_ascii=False,
        )
    )


def hook_prompt_admission(task_id: str) -> None:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": (
                        f"{PROMPT_ADMISSION_MARKER}\n"
                        f"{OWNER_CONTEXT_PREFIX}{task_id}"
                    ),
                },
            },
            ensure_ascii=False,
        )
    )


def is_subagent_event(payload: dict[str, object]) -> bool:
    return (
        payload.get("agent_id") is not None
        or payload.get("agent_type") is not None
    )


def hook_command(args: argparse.Namespace) -> int:
    try:
        payload = json.load(sys.stdin)
        if not isinstance(payload, dict):
            raise GateError(EXIT_CLI, "Hook получил JSON не объектного типа.")
        event: object = getattr(args, "expected_event", None)
        actual_event = payload.get("hook_event_name")
        if event is not None and actual_event != event:
            raise GateError(
                EXIT_CLI,
                "Hook получил событие, не совпадающее с ожидаемым "
                f"{event!r}: {actual_event!r}.",
            )
        if actual_event != "UserPromptSubmit":
            raise GateError(
                EXIT_CLI,
                f"Неподдерживаемое событие hook: {actual_event!r}",
            )
        if is_subagent_event(payload):
            # Субагент является частью уже допущенной корневой задачи. Он не
            # получает собственного lease и не меняет состояние владельца.
            return 0
        task_id = validate_task_id(payload.get("session_id"))
        turn_id = validate_task_id(payload.get("turn_id"))
        cwd = payload.get("cwd")
        if not isinstance(cwd, str) or not cwd:
            raise GateError(EXIT_CLI, "Hook не получил рабочий каталог Codex.")
        context = resolve_context(Path(cwd))

        _, exit_code = acquire(
            context,
            task_id,
            turn_id=turn_id,
            renew_turn=False,
            timeout_seconds=args.wait_timeout_seconds,
            poll_seconds=1.0,
            include_obsidian_diagnostics=False,
            waiting_signal_file=args.waiting_signal_file,
        )
        if exit_code != 0:
            raise GateError(
                exit_code,
                "Не удалось дождаться допуска к ветке до внутреннего "
                "дедлайна hook; работа в этой ветке не начата.",
            )
        hook_prompt_admission(task_id)
        return 0
    except (json.JSONDecodeError, UnicodeError) as exc:
        hook_failure(f"Hook веточного барьера получил некорректный JSON: {exc}")
        return 0
    except KeyboardInterrupt:
        hook_failure("Ожидание веточного барьера было прервано.")
        return 0
    except GateError as exc:
        hook_failure(str(exc))
        return 0
    except Exception:
        hook_failure(
            "Внутренняя ошибка веточного барьера; автоматический допуск "
            "не подтверждён."
        )
        return 0


def nonnegative_float(value: str) -> float:
    try:
        number = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("ожидалось число") from exc
    if not math.isfinite(number):
        raise argparse.ArgumentTypeError("значение должно быть конечным числом")
    if number < 0:
        raise argparse.ArgumentTypeError("значение не может быть отрицательным")
    return number


def positive_float(value: str) -> float:
    number = nonnegative_float(value)
    if number == 0:
        raise argparse.ArgumentTypeError("значение должно быть больше нуля")
    return number


def add_repo_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Путь внутри проверяемой Git-рабочей копии.",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    status_parser = subparsers.add_parser("status", help="Показать состояние барьера.")
    add_repo_argument(status_parser)
    status_parser.add_argument("--json", action="store_true")
    status_parser.set_defaults(handler=status_command)

    acquire_parser = subparsers.add_parser(
        "acquire",
        help="Дождаться чистой ветки и атомарно получить владение.",
    )
    add_repo_argument(acquire_parser)
    acquire_parser.add_argument("--task-id", required=True)
    acquire_parser.add_argument(
        "--timeout-seconds",
        type=nonnegative_float,
        default=None,
    )
    acquire_parser.add_argument(
        "--poll-seconds",
        type=positive_float,
        default=1.0,
    )
    acquire_parser.add_argument(
        "--waiting-signal-file",
        type=Path,
        help=argparse.SUPPRESS,
    )
    acquire_parser.add_argument("--json", action="store_true")
    acquire_parser.set_defaults(handler=acquire_command)

    release_parser = subparsers.add_parser(
        "release",
        help="Освободить владение после чистого завершения задачи.",
    )
    add_repo_argument(release_parser)
    release_parser.add_argument("--task-id", required=True)
    release_parser.add_argument(
        "--force",
        action="store_true",
        help="Снять оставшееся владение после отдельной проверки активности задачи.",
    )
    release_parser.add_argument(
        "--branch-ref",
        help=(
            "Полный refs/heads/* для адресного --force после смены или "
            "переименования ветки."
        ),
    )
    release_parser.add_argument(
        "--expected-lease-id",
        help=(
            "Точное поколение из status --json для compare-and-delete "
            "при --force."
        ),
    )
    release_parser.add_argument("--json", action="store_true")
    release_parser.set_defaults(handler=release_command)

    hook_parser = subparsers.add_parser(
        "hook",
        help="Обработать корневое событие Codex UserPromptSubmit.",
    )
    hook_parser.add_argument(
        "--wait-timeout-seconds",
        type=nonnegative_float,
        default=DEFAULT_HOOK_WAIT_SECONDS,
        help=(
            "Внутренний дедлайн ожидания UserPromptSubmit; должен быть "
            "короче timeout команды hook."
        ),
    )
    hook_parser.add_argument(
        "--waiting-signal-file",
        type=Path,
        help=argparse.SUPPRESS,
    )
    hook_parser.add_argument(
        "--expected-event",
        choices=("UserPromptSubmit",),
        help=argparse.SUPPRESS,
    )
    hook_parser.set_defaults(handler=hook_command)
    return parser.parse_args()


def fail(error: GateError, *, as_json: bool) -> NoReturn:
    payload = {
        "schema_version": SCHEMA_VERSION,
        "state": "error",
        "error": str(error),
        **error.payload,
    }
    if as_json:
        print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    else:
        print(f"error: {error}", file=sys.stderr)
    raise SystemExit(error.exit_code)


def main() -> int:
    args = parse_args()
    try:
        return args.handler(args)
    except GateError as exc:
        fail(exc, as_json=getattr(args, "json", False))


if __name__ == "__main__":
    raise SystemExit(main())
