import contextlib
import importlib.util
import io
import json
import re
import subprocess
import sys
import tempfile
import time
import tomllib
import types
import unittest
from pathlib import Path
from unittest import mock


TOOL_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = TOOL_ROOT.parents[1]
SCRIPT_PATH = TOOL_ROOT / "scripts" / "branch-task-gate.py"
CONFIG_PATH = REPO_ROOT / ".codex" / "config.toml"
AGENTS_PATH = REPO_ROOT / "AGENTS.md"
PROMPT_ADMISSION_MARKER = "FUM-BRANCH-TASK-GATE: admitted-v1"
OWNER_CONTEXT_PREFIX = "FUM-BRANCH-TASK-GATE-OWNER: "


def load_gate_module():
    module_name = "fum_branch_task_gate_under_test"
    spec = importlib.util.spec_from_file_location(module_name, SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


class BranchTaskGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.repo = Path(self.temporary_directory.name) / "main"
        self.repo.mkdir()

        self.git("init", "-b", "master")
        self.git("config", "user.name", "FUM Test")
        self.git("config", "user.email", "fum-test@example.invalid")

        (self.repo / ".obsidian").mkdir()
        (self.repo / ".obsidian" / "graph.json").write_text(
            '{"zoom": 1}\n',
            encoding="utf-8",
        )
        (self.repo / "tracked.txt").write_text("initial\n", encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "-m", "Initial fixture")

    def git(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", "-C", str(self.repo), *args],
            check=True,
            capture_output=True,
            text=True,
        )

    def run_gate(
        self,
        *args: str,
        hook_input: dict[str, object] | None = None,
        timeout: float = 5,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT_PATH), *args],
            cwd=self.repo,
            input=None if hook_input is None else json.dumps(hook_input),
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )

    def payload(self, result: subprocess.CompletedProcess[str]) -> dict[str, object]:
        self.assertTrue(result.stdout, result.stderr)
        return json.loads(result.stdout)

    def assert_prompt_blocked(
        self,
        result: subprocess.CompletedProcess[str],
        expected_reason: str,
    ) -> None:
        payload = self.payload(result)
        self.assertEqual(payload["decision"], "block")
        self.assertIn(expected_reason, str(payload["reason"]))

    def assert_prompt_admitted(
        self,
        result: subprocess.CompletedProcess[str],
    ) -> str:
        payload = self.payload(result)
        specific = payload["hookSpecificOutput"]
        self.assertEqual(specific["hookEventName"], "UserPromptSubmit")
        context_lines = specific["additionalContext"].splitlines()
        self.assertEqual(context_lines[0], PROMPT_ADMISSION_MARKER)
        self.assertEqual(len(context_lines), 2)
        self.assertTrue(context_lines[1].startswith(OWNER_CONTEXT_PREFIX))
        owner = context_lines[1][len(OWNER_CONTEXT_PREFIX) :]
        self.assertTrue(owner)
        return owner

    def test_status_ignores_changes_only_in_root_obsidian(self) -> None:
        (self.repo / ".obsidian" / "graph.json").write_text(
            '{"zoom": 2}\n',
            encoding="utf-8",
        )
        (self.repo / ".obsidian" / "workspace.json").write_text(
            "{}\n",
            encoding="utf-8",
        )

        result = self.run_gate("status", "--repo-root", str(self.repo), "--json")

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = self.payload(result)
        self.assertEqual(payload["state"], "ready")
        self.assertEqual(payload["blocking_paths"], [])
        self.assertEqual(payload["ignored_obsidian_count"], 2)

    def test_status_blocks_staged_unstaged_and_untracked_paths_outside_obsidian(
        self,
    ) -> None:
        (self.repo / "tracked.txt").write_text("modified\n", encoding="utf-8")
        (self.repo / "staged.txt").write_text("staged\n", encoding="utf-8")
        (self.repo / "untracked.txt").write_text("untracked\n", encoding="utf-8")
        self.git("add", "staged.txt")

        result = self.run_gate("status", "--repo-root", str(self.repo), "--json")

        self.assertEqual(result.returncode, 1, result.stderr)
        payload = self.payload(result)
        self.assertEqual(payload["state"], "dirty")
        self.assertEqual(
            set(payload["blocking_paths"]),
            {"staged.txt", "tracked.txt", "untracked.txt"},
        )

    def test_nested_obsidian_directory_and_cross_boundary_rename_still_block(
        self,
    ) -> None:
        nested = self.repo / "nested" / ".obsidian"
        nested.mkdir(parents=True)
        (nested / "state.json").write_text("{}\n", encoding="utf-8")
        self.git("mv", ".obsidian/graph.json", "moved-graph.json")

        result = self.run_gate("status", "--repo-root", str(self.repo), "--json")

        self.assertEqual(result.returncode, 1, result.stderr)
        blocking_paths = set(self.payload(result)["blocking_paths"])
        self.assertIn("moved-graph.json", blocking_paths)
        self.assertIn("nested/.obsidian/state.json", blocking_paths)

    def test_lock_is_branch_scoped_and_same_task_reacquires_idempotently(
        self,
    ) -> None:
        first = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(self.payload(first)["ownership"], "new")

        (self.repo / "tracked.txt").write_text("task a\n", encoding="utf-8")
        repeated = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertEqual(self.payload(repeated)["ownership"], "existing")

        blocked = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-b",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(blocked.returncode, 10, blocked.stderr)
        self.assertEqual(self.payload(blocked)["state"], "locked_and_dirty")

    def test_release_requires_matching_owner_and_clean_non_obsidian_tree(
        self,
    ) -> None:
        acquired = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--timeout-seconds",
            "0",
        )
        self.assertEqual(acquired.returncode, 0, acquired.stderr)

        wrong_owner = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-b",
            "--json",
        )
        self.assertEqual(wrong_owner.returncode, 16, wrong_owner.stderr)

        (self.repo / "tracked.txt").write_text("task a\n", encoding="utf-8")
        dirty_release = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--json",
        )
        self.assertEqual(dirty_release.returncode, 15, dirty_release.stderr)
        self.assertEqual(self.payload(dirty_release)["state"], "locked_and_dirty")

        self.git("add", "tracked.txt")
        self.git("commit", "-m", "Finish task a")
        (self.repo / ".obsidian" / "graph.json").write_text(
            '{"zoom": 3}\n',
            encoding="utf-8",
        )
        released = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--json",
        )
        self.assertEqual(released.returncode, 0, released.stderr)
        self.assertEqual(self.payload(released)["state"], "released")

    def test_different_branches_in_linked_worktrees_use_different_locks(
        self,
    ) -> None:
        master = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "master-task",
            "--timeout-seconds",
            "0",
        )
        self.assertEqual(master.returncode, 0, master.stderr)

        other_worktree = self.repo.parent / "other"
        self.git("worktree", "add", "-b", "other", str(other_worktree))
        other = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "acquire",
                "--repo-root",
                str(other_worktree),
                "--task-id",
                "other-task",
                "--timeout-seconds",
                "0",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(other.returncode, 0, other.stderr)
        self.assertEqual(
            subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "release",
                    "--repo-root",
                    str(other_worktree),
                    "--task-id",
                    "other-task",
                ],
                check=False,
                capture_output=True,
                text=True,
            ).returncode,
            0,
        )

        self.assertEqual(
            self.run_gate(
                "release",
                "--repo-root",
                str(self.repo),
                "--task-id",
                "master-task",
            ).returncode,
            0,
        )

    def test_duplicate_release_cannot_remove_a_new_owner(self) -> None:
        gate = load_gate_module()
        context = gate.resolve_context(self.repo)
        acquired, exit_code = gate.acquire(
            context,
            "task-a",
            timeout_seconds=0,
            poll_seconds=0.01,
        )
        self.assertEqual(exit_code, 0, acquired)

        original_blocking_paths = gate.blocking_paths

        def replace_owner_during_release(root: Path) -> list[str]:
            context.lock_path.unlink()
            self.assertTrue(gate.create_lock(context, "task-b"))
            return original_blocking_paths(root)

        with mock.patch.object(
            gate,
            "blocking_paths",
            side_effect=replace_owner_during_release,
        ):
            payload, exit_code = gate.release(context, "task-a", force=False)

        self.assertEqual(exit_code, gate.EXIT_OWNERSHIP, payload)
        active = gate.read_lock(context)
        self.assertIsNotNone(active)
        self.assertEqual(active.task_id, "task-b")

    def test_prompt_hook_blocks_before_the_host_timeout(self) -> None:
        (self.repo / "untracked.txt").write_text("busy\n", encoding="utf-8")

        result = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input={
                "session_id": "session-b",
                "turn_id": "turn-1",
                "cwd": str(self.repo),
                "hook_event_name": "UserPromptSubmit",
                "model": "test-model",
                "permission_mode": "default",
                "transcript_path": None,
                "prompt": "Start work",
            },
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_prompt_blocked(result, "дождаться допуска")

    def test_hook_converts_unexpected_errors_to_fail_closed_output(self) -> None:
        gate = load_gate_module()
        hook_input = {
            "session_id": "session-a",
            "turn_id": "turn-1",
            "cwd": str(self.repo),
            "hook_event_name": "UserPromptSubmit",
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
            "prompt": "Start work",
        }
        output = io.StringIO()

        with (
            mock.patch.object(
                gate,
                "resolve_context",
                side_effect=OSError("synthetic I/O failure"),
            ),
            mock.patch.object(sys, "stdin", io.StringIO(json.dumps(hook_input))),
            contextlib.redirect_stdout(output),
        ):
            exit_code = gate.hook_command(
                types.SimpleNamespace(wait_timeout_seconds=0)
            )

        self.assertEqual(exit_code, 0)
        payload = json.loads(output.getvalue())
        self.assertEqual(payload["decision"], "block")
        self.assertIn("внутренняя ошибка", payload["reason"].lower())

    def test_branch_switch_is_reported_and_original_lock_is_retained(self) -> None:
        common = {
            "session_id": "session-a",
            "turn_id": "turn-1",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        acquired = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input={
                **common,
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Start work",
            },
        )
        self.assertEqual(acquired.returncode, 0, acquired.stderr)

        self.git("switch", "-c", "other")
        switched_status = self.run_gate(
            "status",
            "--repo-root",
            str(self.repo),
            "--json",
        )
        self.assertEqual(switched_status.returncode, 1, switched_status.stderr)
        switched_payload = self.payload(switched_status)
        self.assertEqual(
            switched_payload["owner_branch_ref"],
            "refs/heads/master",
        )
        self.assertEqual(switched_payload["task_id"], "session-a")
        self.assertTrue(switched_payload["lease_id"])

        second_prompt = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input={
                **common,
                "turn_id": "turn-2",
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Continue in another branch",
            },
        )
        self.assertEqual(second_prompt.returncode, 0, second_prompt.stderr)
        self.assert_prompt_blocked(second_prompt, "другой Git-веткой")

        self.git("switch", "master")
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 1, status.stderr)
        self.assertEqual(self.payload(status)["task_id"], "session-a")

    def test_new_session_cannot_enter_another_branch_in_same_worktree(
        self,
    ) -> None:
        acquired = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "session-a",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(acquired.returncode, 0, acquired.stderr)
        self.git("switch", "-c", "other")

        result = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input={
                "session_id": "session-b",
                "turn_id": "turn-1",
                "cwd": str(self.repo),
                "hook_event_name": "UserPromptSubmit",
                "model": "test-model",
                "permission_mode": "default",
                "transcript_path": None,
                "prompt": "Start task B",
            },
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_prompt_blocked(result, "worktree")

    def test_waiting_task_starts_only_after_previous_owner_releases(self) -> None:
        acquired = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--timeout-seconds",
            "0",
        )
        self.assertEqual(acquired.returncode, 0, acquired.stderr)

        waiting = subprocess.Popen(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "acquire",
                "--repo-root",
                str(self.repo),
                "--task-id",
                "task-b",
                "--timeout-seconds",
                "3",
                "--poll-seconds",
                "0.05",
                "--waiting-signal-file",
                str(self.repo / ".git" / "waiter-ready"),
                "--json",
            ],
            cwd=self.repo,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.addCleanup(lambda: waiting.kill() if waiting.poll() is None else None)
        waiting_signal = self.repo / ".git" / "waiter-ready"
        deadline = time.monotonic() + 2
        while not waiting_signal.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertTrue(waiting_signal.exists(), "the waiter did not observe the lock")
        self.assertIsNone(waiting.poll(), "the second task entered before release")

        released = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
        )
        self.assertEqual(released.returncode, 0, released.stderr)

        stdout, stderr = waiting.communicate(timeout=3)
        self.assertEqual(waiting.returncode, 0, stderr)
        self.assertEqual(json.loads(stdout)["ownership"], "new")

        self.assertEqual(
            self.run_gate(
                "release",
                "--repo-root",
                str(self.repo),
                "--task-id",
                "task-b",
            ).returncode,
            0,
        )

    def test_simultaneous_clean_start_has_exactly_one_owner(self) -> None:
        processes: list[subprocess.Popen[str]] = []
        for task_id in ("task-a", "task-b"):
            processes.append(
                subprocess.Popen(
                    [
                        sys.executable,
                        str(SCRIPT_PATH),
                        "acquire",
                        "--repo-root",
                        str(self.repo),
                        "--task-id",
                        task_id,
                        "--timeout-seconds",
                        "0",
                        "--json",
                    ],
                    cwd=self.repo,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
            )
        for process in processes:
            self.addCleanup(
                lambda process=process: (
                    process.kill() if process.poll() is None else None
                )
            )

        results = []
        for process in processes:
            stdout, stderr = process.communicate(timeout=3)
            results.append((process.returncode, stdout, stderr))

        self.assertEqual(sorted(result[0] for result in results), [0, 10])
        winner = next(
            json.loads(stdout) for code, stdout, _ in results if code == 0
        )
        loser = next(
            json.loads(stdout) for code, stdout, _ in results if code == 10
        )
        self.assertEqual(loser["state"], "locked")
        self.assertEqual(loser["task_id"], winner["task_id"])
        released = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            winner["task_id"],
        )
        self.assertEqual(released.returncode, 0, released.stderr)


    def test_root_hook_keeps_one_lease_until_explicit_release(self) -> None:
        common = {
            "session_id": "session-a",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        first = self.run_gate(
            "hook",
            hook_input={
                **common,
                "turn_id": "turn-1",
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Start work",
            },
        )
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(self.assert_prompt_admitted(first), "session-a")
        first_status = self.run_gate(
            "status",
            "--repo-root",
            str(self.repo),
            "--json",
        )
        first_payload = self.payload(first_status)

        (self.repo / "tracked.txt").write_text(
            "in progress\n",
            encoding="utf-8",
        )
        continued = self.run_gate(
            "hook",
            hook_input={
                **common,
                "turn_id": "turn-2",
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Continue work",
            },
        )
        self.assertEqual(continued.returncode, 0, continued.stderr)
        self.assert_prompt_admitted(continued)
        continued_status = self.run_gate(
            "status",
            "--repo-root",
            str(self.repo),
            "--json",
        )
        continued_payload = self.payload(continued_status)
        self.assertEqual(
            continued_payload["lease_id"],
            first_payload["lease_id"],
        )
        self.assertEqual(continued_payload["turn_id"], "turn-1")
        self.assertEqual(continued_payload["state"], "locked_and_dirty")

        self.git("add", "tracked.txt")
        self.git("commit", "-m", "Finish root task")
        still_owned = self.run_gate(
            "status",
            "--repo-root",
            str(self.repo),
            "--json",
        )
        self.assertEqual(self.payload(still_owned)["state"], "locked")

        released = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "session-a",
            "--json",
        )
        self.assertEqual(released.returncode, 0, released.stderr)
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertEqual(self.payload(status)["state"], "ready")

    def test_subagent_prompt_does_not_touch_root_lease(self) -> None:
        root = self.run_gate(
            "hook",
            hook_input={
                "session_id": "root-session",
                "turn_id": "root-turn",
                "cwd": str(self.repo),
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Start root work",
            },
        )
        self.assert_prompt_admitted(root)
        before = self.payload(
            self.run_gate("status", "--repo-root", str(self.repo), "--json")
        )

        child = self.run_gate(
            "hook",
            hook_input={
                "session_id": "child-session",
                "turn_id": "child-turn",
                "agent_id": "child-agent",
                "agent_type": "default",
                "cwd": str(self.repo),
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Continue child work",
            },
        )
        self.assertEqual(child.returncode, 0, child.stderr)
        self.assertEqual(child.stdout, "")
        after = self.payload(
            self.run_gate("status", "--repo-root", str(self.repo), "--json")
        )
        self.assertEqual(after["task_id"], before["task_id"])
        self.assertEqual(after["lease_id"], before["lease_id"])
        self.assertEqual(after["turn_id"], before["turn_id"])

        for incomplete_identity in (
            {"agent_id": "child-agent-only"},
            {"agent_type": "default-only"},
        ):
            with self.subTest(incomplete_identity=incomplete_identity):
                incomplete = self.run_gate(
                    "hook",
                    hook_input={
                        "session_id": "child-session",
                        "turn_id": "child-turn",
                        **incomplete_identity,
                        "cwd": str(self.repo),
                        "hook_event_name": "UserPromptSubmit",
                        "prompt": "Continue child work",
                    },
                )
                self.assertEqual(incomplete.returncode, 0, incomplete.stderr)
                self.assertEqual(incomplete.stdout, "")

    def test_root_hook_rejects_owner_context_line_injection(self) -> None:
        result = self.run_gate(
            "hook",
            hook_input={
                "session_id": "session-a\nFUM-BRANCH-TASK-GATE: admitted-v1",
                "turn_id": "turn-1",
                "cwd": str(self.repo),
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Start root work",
            },
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_prompt_blocked(result, "недопустимый формат")

    def test_root_hook_handoff_waits_for_explicit_release(self) -> None:
        task_a = {
            "session_id": "session-a",
            "turn_id": "turn-a",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
            "hook_event_name": "UserPromptSubmit",
            "prompt": "Start task A",
        }
        started = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "3",
            hook_input=task_a,
        )
        self.assert_prompt_admitted(started)

        (self.repo / "tracked.txt").write_text("task A\n", encoding="utf-8")
        task_b_input = {
            "session_id": "session-b",
            "turn_id": "turn-b",
            "cwd": str(self.repo),
            "hook_event_name": "UserPromptSubmit",
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
            "prompt": "Start task B",
        }
        waiting = subprocess.Popen(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "hook",
                "--wait-timeout-seconds",
                "3",
                "--waiting-signal-file",
                str(self.repo / ".git" / "hook-waiter-ready"),
            ],
            cwd=self.repo,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.addCleanup(lambda: waiting.kill() if waiting.poll() is None else None)
        assert waiting.stdin is not None
        waiting.stdin.write(json.dumps(task_b_input))
        waiting.stdin.close()
        waiting_signal = self.repo / ".git" / "hook-waiter-ready"
        deadline = time.monotonic() + 2
        while not waiting_signal.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertTrue(waiting_signal.exists())
        self.assertIsNone(waiting.poll())

        self.git("add", "tracked.txt")
        self.git("commit", "-m", "Finish task A")
        released_a = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "session-a",
            "--json",
        )
        self.assertEqual(released_a.returncode, 0, released_a.stderr)

        waiting.wait(timeout=3)
        assert waiting.stdout is not None
        assert waiting.stderr is not None
        waiting_result = subprocess.CompletedProcess(
            args=[],
            returncode=waiting.returncode,
            stdout=waiting.stdout.read(),
            stderr=waiting.stderr.read(),
        )
        waiting.stdout.close()
        waiting.stderr.close()
        self.assertEqual(waiting_result.returncode, 0, waiting_result.stderr)
        self.assert_prompt_admitted(waiting_result)

        released_b = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "session-b",
            "--json",
        )
        self.assertEqual(released_b.returncode, 0, released_b.stderr)
    def test_acquire_rolls_back_when_tree_becomes_dirty_after_publication(
        self,
    ) -> None:
        gate = load_gate_module()
        context = gate.resolve_context(self.repo)

        with mock.patch.object(
            gate,
            "blocking_paths",
            side_effect=[[], ["late-change.txt"]],
        ):
            payload, exit_code = gate.acquire(
                context,
                "task-a",
                timeout_seconds=0,
                poll_seconds=0.01,
            )

        self.assertEqual(exit_code, gate.EXIT_DIRTY_TIMEOUT, payload)
        self.assertEqual(payload["blocking_paths"], ["late-change.txt"])
        self.assertIsNone(gate.read_lock(context))

    def test_numeric_cli_values_must_be_finite(self) -> None:
        gate = load_gate_module()

        for value in ("nan", "inf", "-inf"):
            with self.subTest(value=value):
                with self.assertRaises(gate.argparse.ArgumentTypeError):
                    gate.nonnegative_float(value)
                with self.assertRaises(gate.argparse.ArgumentTypeError):
                    gate.positive_float(value)

    def test_preexisting_dirty_tree_times_out_without_creating_lock(self) -> None:
        (self.repo / "untracked.txt").write_text("busy\n", encoding="utf-8")

        result = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "next-task",
            "--timeout-seconds",
            "0",
            "--json",
        )

        self.assertEqual(result.returncode, 11, result.stderr)
        self.assertEqual(self.payload(result)["state"], "dirty")
        lock_files = list((self.repo / ".git").glob("fum-branch-task-gate/*.json"))
        self.assertEqual(lock_files, [])

    def test_detached_head_fails_closed(self) -> None:
        self.git("checkout", "--detach")

        result = self.run_gate(
            "status",
            "--repo-root",
            str(self.repo),
            "--json",
        )

        self.assertEqual(result.returncode, 12, result.stderr)
        self.assertEqual(self.payload(result)["state"], "error")

    def test_prompt_hook_blocks_turn_when_branch_context_is_invalid(self) -> None:
        self.git("checkout", "--detach")

        result = self.run_gate(
            "hook",
            hook_input={
                "session_id": "session-a",
                "turn_id": "turn-1",
                "cwd": str(self.repo),
                "hook_event_name": "UserPromptSubmit",
                "model": "test-model",
                "permission_mode": "default",
                "transcript_path": None,
                "prompt": "Start work",
            },
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_prompt_blocked(result, "detached HEAD")

    def test_forced_duplicate_branch_worktrees_fail_closed(self) -> None:
        duplicate = self.repo.parent / "duplicate"
        self.git("worktree", "add", "--force", str(duplicate), "master")

        result = self.run_gate(
            "status",
            "--repo-root",
            str(self.repo),
            "--json",
        )

        self.assertEqual(result.returncode, 12, result.stderr)
        self.assertIn("нескольких worktree", self.payload(result)["error"])

    def test_lock_is_published_only_after_complete_json_is_written(self) -> None:
        gate = load_gate_module()
        context = gate.resolve_context(self.repo)
        original_link = gate.os.link
        observed_payloads: list[dict[str, object]] = []

        def inspect_then_publish(source: Path, destination: Path) -> None:
            self.assertFalse(Path(destination).exists())
            observed_payloads.append(
                json.loads(Path(source).read_text(encoding="utf-8"))
            )
            original_link(source, destination)

        with mock.patch.object(gate.os, "link", side_effect=inspect_then_publish):
            with gate.transition_lock(context):
                record = gate.create_lock(context, "task-a")

        self.assertIsNotNone(record)
        self.assertEqual(len(observed_payloads), 1)
        self.assertEqual(observed_payloads[0]["task_id"], "task-a")
        self.assertTrue(observed_payloads[0]["lease_id"])

    def test_non_utf8_lock_fails_closed_without_traceback(self) -> None:
        gate = load_gate_module()
        context = gate.resolve_context(self.repo)
        with gate.transition_lock(context):
            record = gate.create_lock(context, "task-a")
        self.assertIsNotNone(record)
        context.lock_path.write_bytes(b"\xff\xfe")

        result = self.run_gate(
            "status",
            "--repo-root",
            str(self.repo),
            "--json",
        )

        self.assertEqual(result.returncode, 16, result.stderr)
        payload = self.payload(result)
        self.assertEqual(payload["state"], "error")
        self.assertIn("UTF-8", payload["error"])
        self.assertNotIn("Traceback", result.stderr)

    def test_force_release_is_explicit_recovery_for_stale_owner(self) -> None:
        acquired = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "stale-task",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(acquired.returncode, 0, acquired.stderr)
        lease_id = self.payload(acquired)["lease_id"]

        forced = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "recovery-task",
            "--force",
            "--expected-lease-id",
            lease_id,
            "--json",
        )

        self.assertEqual(forced.returncode, 0, forced.stderr)
        payload = self.payload(forced)
        self.assertEqual(payload["state"], "force_released")
        self.assertEqual(payload["previous_task_id"], "stale-task")

    def test_force_release_can_target_original_branch_after_switch(self) -> None:
        acquired = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "stale-task",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(acquired.returncode, 0, acquired.stderr)
        lease_id = self.payload(acquired)["lease_id"]
        self.git("switch", "-c", "other")

        forced = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "recovery-task",
            "--force",
            "--expected-lease-id",
            lease_id,
            "--branch-ref",
            "refs/heads/master",
            "--json",
        )

        self.assertEqual(forced.returncode, 0, forced.stderr)
        payload = self.payload(forced)
        self.assertEqual(payload["state"], "force_released")
        self.assertEqual(payload["branch_ref"], "refs/heads/master")
        self.assertEqual(payload["previous_task_id"], "stale-task")
        self.git("switch", "master")
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 0, status.stderr)

    def test_force_release_cannot_delete_a_replacement_lease(self) -> None:
        first = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(first.returncode, 0, first.stderr)
        stale_lease_id = self.payload(first)["lease_id"]
        released = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
        )
        self.assertEqual(released.returncode, 0, released.stderr)

        replacement = self.run_gate(
            "acquire",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-b",
            "--timeout-seconds",
            "0",
            "--json",
        )
        self.assertEqual(replacement.returncode, 0, replacement.stderr)

        stale_force = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "recovery",
            "--force",
            "--expected-lease-id",
            stale_lease_id,
            "--json",
        )

        self.assertEqual(stale_force.returncode, 16, stale_force.stderr)
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 1, status.stderr)
        self.assertEqual(self.payload(status)["task_id"], "task-b")

    def test_force_release_requires_observed_lease_generation(self) -> None:
        result = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "recovery",
            "--force",
            "--json",
        )

        self.assertEqual(result.returncode, 64, result.stderr)
        self.assertIn("--expected-lease-id", self.payload(result)["error"])

    def test_force_release_of_missing_generation_is_a_mismatch(self) -> None:
        result = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "recovery",
            "--force",
            "--expected-lease-id",
            "0" * 32,
            "--json",
        )

        self.assertEqual(result.returncode, 16, result.stderr)
        self.assertEqual(self.payload(result)["state"], "missing")

    def test_branch_ref_override_requires_force(self) -> None:
        result = self.run_gate(
            "release",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--branch-ref",
            "refs/heads/master",
            "--json",
        )

        self.assertEqual(result.returncode, 64, result.stderr)
        self.assertIn("--force", self.payload(result)["error"])


    def test_project_config_registers_only_root_prompt_hook(self) -> None:
        config = tomllib.loads(CONFIG_PATH.read_text(encoding="utf-8"))

        self.assertTrue(config["features"]["hooks"])
        self.assertEqual(set(config["hooks"]), {"UserPromptSubmit"})
        prompt_hook = config["hooks"]["UserPromptSubmit"][0]["hooks"][0]
        self.assertEqual(prompt_hook["type"], "command")
        self.assertIn("branch-task-gate.py", prompt_hook["command"])
        self.assertIn('"git", "show"', prompt_hook["command"])
        self.assertIn("HEAD:Инструменты/fum-branch-task-gate", prompt_hook["command"])
        self.assertIn(
            "--expected-event UserPromptSubmit",
            prompt_hook["command"],
        )
        self.assertIn("--wait-timeout-seconds 85800", prompt_hook["command"])
        self.assertEqual(prompt_hook["timeout"], 86_400)
        timeout_match = re.search(
            r"--wait-timeout-seconds\s+(\d+)",
            prompt_hook["command"],
        )
        self.assertIsNotNone(timeout_match)
        internal_timeout = int(timeout_match.group(1))
        self.assertGreaterEqual(
            prompt_hook["timeout"] - internal_timeout,
            300,
            "host timeout must leave room for context and the final poll",
        )
        self.assertEqual(
            internal_timeout,
            load_gate_module().DEFAULT_HOOK_WAIT_SECONDS,
        )

    def test_agents_requires_only_root_marker_before_mutation(self) -> None:
        instructions = AGENTS_PATH.read_text(encoding="utf-8")

        self.assertIn(PROMPT_ADMISSION_MARKER, instructions)
        self.assertNotIn("subagent-admitted-v1", instructions)
        self.assertIn(OWNER_CONTEXT_PREFIX.strip(), instructions)
        self.assertIn("дополнительного developer-контекста", instructions)
        self.assertIn("не изменяет файлы", instructions)
        self.assertIn("явно освобождает владение", instructions)
    def test_project_hook_executes_committed_helper_not_dirty_copy(self) -> None:
        relative_script = Path(
            "Инструменты/fum-branch-task-gate/scripts/branch-task-gate.py"
        )
        fixture_script = self.repo / relative_script
        fixture_script.parent.mkdir(parents=True)
        fixture_script.write_text(
            SCRIPT_PATH.read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        self.git("add", str(relative_script))
        self.git("commit", "-m", "Add committed branch gate")

        config = tomllib.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        command = config["hooks"]["UserPromptSubmit"][0]["hooks"][0]["command"]
        command = command.replace(
            "--wait-timeout-seconds 85800",
            "--wait-timeout-seconds 0",
        )
        common = {
            "turn_id": "turn-1",
            "cwd": str(self.repo),
            "hook_event_name": "UserPromptSubmit",
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
            "prompt": "Start work",
        }
        first = subprocess.run(
            command,
            cwd=self.repo,
            shell=True,
            executable="/bin/sh",
            input=json.dumps({**common, "session_id": "session-a"}),
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assert_prompt_admitted(first)

        fixture_script.write_text(
            'print(\'{"continue": true}\')\nraise SystemExit(99)\n',
            encoding="utf-8",
        )
        blocked = subprocess.run(
            command,
            cwd=self.repo,
            shell=True,
            executable="/bin/sh",
            input=json.dumps({**common, "session_id": "session-b"}),
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )

        self.assertEqual(blocked.returncode, 0, blocked.stderr)
        self.assert_prompt_blocked(blocked, "дождаться допуска")

        self.git("add", str(relative_script))
        self.git("commit", "-m", "Commit broken helper fixture")
        broken_head = subprocess.run(
            command,
            cwd=self.repo,
            shell=True,
            executable="/bin/sh",
            input=json.dumps({**common, "session_id": "session-c"}),
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )

        self.assertEqual(broken_head.returncode, 0, broken_head.stderr)
        self.assert_prompt_blocked(broken_head, "автоматический допуск")


if __name__ == "__main__":
    unittest.main()
