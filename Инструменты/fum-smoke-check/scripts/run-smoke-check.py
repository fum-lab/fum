#!/usr/bin/env python3
"""Run the local FUM repository smoke-check without network dependencies."""

from __future__ import annotations

import argparse
import os
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


PLANNING_REGISTRY_SCRIPT = Path(
    "Инструменты/fum-planning-registry/scripts/build-planning-registry.py"
)
PLANNING_REGISTRY_OUTPUT = Path(
    "Планирование/реестр-требований-вариантов-и-кандидатов.json"
)
PROTOTYPE_LAUNCH_CHECK_SCRIPT = Path(
    "Инструменты/fum-prototype-launch/scripts/check-prototype-launchers.py"
)
CODEX_COMMIT_CONTEXT_RULE_START = (2026, 7, 14, 2, 31, 47)
REQUEST_DATETIME_PREFIX_RE = re.compile(
    r"^(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})_MSK"
)
RECENCY_SCRIPT = Path("Инструменты/fum-md-recency/scripts/update-md-recency.py")
OBSIDIAN_GRAPH_RECENCY_SCRIPT = Path(
    "Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py"
)
SESSION_COHERENCE_SCRIPT = Path(
    "Инструменты/fum-session-coherence/scripts/check-session-coherence.py"
)


@dataclass(frozen=True)
class SmokeStep:
    name: str
    command: tuple[str, ...]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--request",
        type=Path,
        help="Selected working session request file for fum-session-coherence.",
    )
    parser.add_argument(
        "--commit-message-file",
        type=Path,
        help="Commit message file forwarded to fum-session-coherence.",
    )
    parser.add_argument(
        "--codex-thread-id",
        help="Expected root Codex thread identifier forwarded to fum-session-coherence.",
    )
    parser.add_argument(
        "--skip-session-coherence",
        action="store_true",
        help="Run repository checks without validating a specific working session.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print the planned commands without running them.",
    )
    return parser.parse_args()


def repo_relative(path: Path, repo_root: Path) -> str:
    absolute = path if path.is_absolute() else repo_root / path
    return absolute.resolve().relative_to(repo_root.resolve()).as_posix()


def request_requires_codex_commit_context(request: str | Path) -> bool:
    match = REQUEST_DATETIME_PREFIX_RE.match(Path(request).name)
    if match is None:
        return False
    return tuple(int(part) for part in match.groups()) >= CODEX_COMMIT_CONTEXT_RULE_START


def require_file(repo_root: Path, path: Path) -> str:
    absolute = (repo_root / path).resolve()
    if not absolute.exists():
        raise FileNotFoundError(f"required smoke-check component is missing: {path.as_posix()}")
    return repo_relative(absolute, repo_root)


def discover_test_dirs(repo_root: Path) -> list[Path]:
    tools_dir = repo_root / "Инструменты"
    if not tools_dir.exists():
        return []

    test_dirs: list[Path] = []
    for tests_path in tools_dir.glob("*/tests"):
        if tests_path.is_dir() and any(tests_path.glob("test_*.py")):
            test_dirs.append(tests_path)
    return sorted(test_dirs, key=lambda path: repo_relative(path, repo_root))


def build_steps(
    repo_root: str | Path,
    request: str | Path | None,
    include_session: bool = True,
    python: str | None = None,
    commit_message_file: str | Path | None = None,
    codex_thread_id: str | None = None,
) -> list[SmokeStep]:
    root = Path(repo_root).resolve()
    python_cmd = python or sys.executable
    steps: list[SmokeStep] = []

    for test_dir in discover_test_dirs(root):
        tool_name = test_dir.parent.name
        steps.append(
            SmokeStep(
                name=f"Тесты {tool_name}",
                command=(
                    python_cmd,
                    "-m",
                    "unittest",
                    "discover",
                    "-s",
                    repo_relative(test_dir, root),
                    "-p",
                    "test_*.py",
                ),
            )
        )

    planning_script = require_file(root, PLANNING_REGISTRY_SCRIPT)
    planning_output = PLANNING_REGISTRY_OUTPUT.as_posix()
    steps.append(
        SmokeStep(
            name="Сборка планового реестра",
            command=(python_cmd, planning_script, "build", "--output", planning_output),
        )
    )
    steps.append(
        SmokeStep(
            name="Проверка планового реестра",
            command=(python_cmd, planning_script, "validate", "--registry", planning_output),
        )
    )

    prototype_launch_script = require_file(root, PROTOTYPE_LAUNCH_CHECK_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка скриптов запуска прототипов",
            command=(python_cmd, prototype_launch_script),
        )
    )

    recency_script = require_file(root, RECENCY_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка recency-меток Markdown",
            command=(python_cmd, recency_script, "--check"),
        )
    )
    obsidian_graph_recency_script = require_file(root, OBSIDIAN_GRAPH_RECENCY_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка тепловой карты графа Obsidian",
            command=(python_cmd, obsidian_graph_recency_script, "--check"),
        )
    )

    if include_session:
        if request is None:
            raise ValueError("--request is required unless --skip-session-coherence is used")
        if request_requires_codex_commit_context(request):
            if commit_message_file is None:
                raise ValueError(
                    "--commit-message-file is required for this request"
                )
            if codex_thread_id is None:
                raise ValueError("--codex-thread-id is required for this request")
        session_script = require_file(root, SESSION_COHERENCE_SCRIPT)
        request_path = repo_relative(Path(request), root)
        session_command = [python_cmd, session_script, "--request", request_path]
        if commit_message_file is not None:
            message_path = Path(commit_message_file)
            session_command.extend(
                ["--commit-message-file", message_path.as_posix()]
            )
        if codex_thread_id is not None:
            session_command.extend(["--codex-thread-id", codex_thread_id])
        steps.append(
            SmokeStep(
                name="Проверка связности рабочей сессии",
                command=tuple(session_command),
            )
        )

    return steps


def smoke_env() -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    return env


def print_output(result: subprocess.CompletedProcess[str]) -> None:
    if result.stdout:
        print(result.stdout, end="", flush=True)
    if result.stderr:
        print(result.stderr, end="", flush=True)


def run_steps(steps: list[SmokeStep], repo_root: Path) -> int:
    env = smoke_env()
    total = len(steps)
    for index, step in enumerate(steps, start=1):
        print(f"[{index}/{total}] {step.name}", flush=True)
        print(shlex.join(step.command), flush=True)
        result = subprocess.run(
            step.command,
            cwd=repo_root,
            env=env,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print_output(result)
        if result.returncode != 0:
            print(
                f"smoke-check failed at step {index}: {step.name}",
                file=sys.stderr,
            )
            return result.returncode
    print(f"smoke-check passed: {total} step(s)")
    return 0


def main() -> int:
    args = parse_args()
    root = args.repo_root.resolve()
    include_session = not args.skip_session_coherence

    try:
        steps = build_steps(
            root,
            args.request,
            include_session=include_session,
            commit_message_file=args.commit_message_file,
            codex_thread_id=args.codex_thread_id,
        )
    except (FileNotFoundError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if args.list:
        for step in steps:
            print(f"{step.name}: {shlex.join(step.command)}")
        return 0

    return run_steps(steps, root)


if __name__ == "__main__":
    raise SystemExit(main())
