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
        stopped = self.run_gate(
            "hook",
            hook_input={
                **common,
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Done",
            },
        )
        self.assertEqual(stopped.returncode, 0, stopped.stderr)
        warning = self.payload(stopped)
        self.assertTrue(warning["continue"])
        self.assertIn("ветк", warning["systemMessage"])

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

    def test_hook_keeps_dirty_owner_allows_same_session_and_releases_when_clean(
        self,
    ) -> None:
        common = {
            "session_id": "session-a",
            "turn_id": "turn-1",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        started = self.run_gate(
            "hook",
            hook_input={
                **common,
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Start work",
            },
        )
        self.assertEqual(started.returncode, 0, started.stderr)
        self.assertEqual(started.stdout, "")

        (self.repo / "tracked.txt").write_text("in progress\n", encoding="utf-8")
        stopped_dirty = self.run_gate(
            "hook",
            hook_input={
                **common,
                "hook_event_name": "Stop",
                "stop_hook_active": False,
            },
        )
        self.assertEqual(stopped_dirty.returncode, 0, stopped_dirty.stderr)

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

        self.git("add", "tracked.txt")
        self.git("commit", "-m", "Finish session")
        stopped_clean = self.run_gate(
            "hook",
            hook_input={
                **common,
                "turn_id": "turn-2",
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Done",
            },
        )
        self.assertEqual(stopped_clean.returncode, 0, stopped_clean.stderr)

        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertEqual(self.payload(status)["state"], "ready")

    def test_delayed_stop_cannot_release_a_new_turn_of_same_session(self) -> None:
        common = {
            "session_id": "session-a",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        first_prompt = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input={
                **common,
                "turn_id": "turn-1",
                "hook_event_name": "UserPromptSubmit",
                "prompt": "First turn",
            },
        )
        self.assertEqual(first_prompt.returncode, 0, first_prompt.stderr)
        first_stop = self.run_gate(
            "hook",
            hook_input={
                **common,
                "turn_id": "turn-1",
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "First turn done",
            },
        )
        self.assertEqual(first_stop.returncode, 0, first_stop.stderr)

        second_prompt = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input={
                **common,
                "turn_id": "turn-2",
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Second turn",
            },
        )
        self.assertEqual(second_prompt.returncode, 0, second_prompt.stderr)
        delayed_stop = self.run_gate(
            "hook",
            hook_input={
                **common,
                "turn_id": "turn-1",
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Delayed duplicate",
            },
        )

        self.assertEqual(delayed_stop.returncode, 0, delayed_stop.stderr)
        warning = self.payload(delayed_stop)
        self.assertTrue(warning["continue"])
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 1, status.stderr)
        payload = self.payload(status)
        self.assertEqual(payload["task_id"], "session-a")
        self.assertEqual(payload["turn_id"], "turn-2")

    def test_pre_tool_hook_reacquires_after_a_parallel_stop_continuation(
        self,
    ) -> None:
        common = {
            "session_id": "session-a",
            "turn_id": "turn-1",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        started = self.run_gate(
            "hook",
            hook_input={
                **common,
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Start work",
            },
        )
        self.assertEqual(started.returncode, 0, started.stderr)
        stopped = self.run_gate(
            "hook",
            hook_input={
                **common,
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Done",
            },
        )
        self.assertEqual(stopped.returncode, 0, stopped.stderr)

        continued_tool = self.run_gate(
            "hook",
            hook_input={
                **common,
                "hook_event_name": "PreToolUse",
                "tool_name": "apply_patch",
                "tool_use_id": "tool-1",
                "tool_input": {"command": "*** Begin Patch\n*** End Patch\n"},
            },
        )

        self.assertEqual(continued_tool.returncode, 0, continued_tool.stderr)
        self.assertEqual(continued_tool.stdout, "")
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 1, status.stderr)
        payload = self.payload(status)
        self.assertEqual(payload["task_id"], "session-a")
        self.assertEqual(payload["turn_id"], "turn-1")

    def test_pre_tool_hook_denies_a_continued_turn_after_handoff(self) -> None:
        common = {
            "session_id": "session-a",
            "turn_id": "turn-1",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        self.assertEqual(
            self.run_gate(
                "hook",
                hook_input={
                    **common,
                    "hook_event_name": "UserPromptSubmit",
                    "prompt": "Start work",
                },
            ).returncode,
            0,
        )
        self.assertEqual(
            self.run_gate(
                "hook",
                hook_input={
                    **common,
                    "hook_event_name": "Stop",
                    "stop_hook_active": False,
                    "last_assistant_message": "Done",
                },
            ).returncode,
            0,
        )
        next_owner = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input={
                **common,
                "session_id": "session-b",
                "turn_id": "turn-2",
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Next task",
            },
        )
        self.assertEqual(next_owner.returncode, 0, next_owner.stderr)

        old_tool = self.run_gate(
            "hook",
            hook_input={
                **common,
                "hook_event_name": "PreToolUse",
                "tool_name": "Bash",
                "tool_use_id": "tool-1",
                "tool_input": {"command": "touch forbidden.txt"},
            },
        )

        self.assertEqual(old_tool.returncode, 0, old_tool.stderr)
        denial = self.payload(old_tool)
        specific = denial["hookSpecificOutput"]
        self.assertEqual(specific["hookEventName"], "PreToolUse")
        self.assertEqual(specific["permissionDecision"], "deny")
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 1, status.stderr)
        self.assertEqual(self.payload(status)["task_id"], "session-b")

    def test_pre_tool_hook_denies_an_obsolete_turn_of_the_same_session(
        self,
    ) -> None:
        common = {
            "session_id": "session-a",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        self.assertEqual(
            self.run_gate(
                "hook",
                hook_input={
                    **common,
                    "turn_id": "turn-1",
                    "hook_event_name": "UserPromptSubmit",
                    "prompt": "First turn",
                },
            ).returncode,
            0,
        )
        self.assertEqual(
            self.run_gate(
                "hook",
                hook_input={
                    **common,
                    "turn_id": "turn-2",
                    "hook_event_name": "UserPromptSubmit",
                    "prompt": "Newer turn",
                },
            ).returncode,
            0,
        )

        obsolete_tool = self.run_gate(
            "hook",
            hook_input={
                **common,
                "turn_id": "turn-1",
                "hook_event_name": "PreToolUse",
                "tool_name": "apply_patch",
                "tool_use_id": "tool-obsolete",
                "tool_input": {"patch": "obsolete"},
            },
        )

        self.assertEqual(obsolete_tool.returncode, 0, obsolete_tool.stderr)
        denial = self.payload(obsolete_tool)
        self.assertEqual(
            denial["hookSpecificOutput"]["permissionDecision"],
            "deny",
        )
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 1, status.stderr)
        payload = self.payload(status)
        self.assertEqual(payload["task_id"], "session-a")
        self.assertEqual(payload["turn_id"], "turn-2")

    def test_full_hook_handoff_waits_until_clean_stop(self) -> None:
        task_a = {
            "session_id": "session-a",
            "turn_id": "turn-a",
            "cwd": str(self.repo),
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
        }
        started = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "3",
            hook_input={
                **task_a,
                "hook_event_name": "UserPromptSubmit",
                "prompt": "Start task A",
            },
        )
        self.assertEqual(started.returncode, 0, started.stderr)

        (self.repo / "tracked.txt").write_text("task A\n", encoding="utf-8")
        dirty_stop = self.run_gate(
            "hook",
            hook_input={
                **task_a,
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Task A still has changes",
            },
        )
        self.assertEqual(dirty_stop.returncode, 0, dirty_stop.stderr)

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
        self.assertTrue(
            waiting_signal.exists(),
            "task B did not observe task A ownership",
        )
        self.assertIsNone(
            waiting.poll(),
            "task B entered before task A stopped cleanly",
        )

        self.git("add", "tracked.txt")
        self.git("commit", "-m", "Finish task A")
        (self.repo / ".obsidian" / "graph.json").write_text(
            '{"zoom": 4}\n',
            encoding="utf-8",
        )
        clean_stop = self.run_gate(
            "hook",
            hook_input={
                **task_a,
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Task A is committed",
            },
        )
        self.assertEqual(clean_stop.returncode, 0, clean_stop.stderr)

        waiting.wait(timeout=3)
        assert waiting.stdout is not None
        assert waiting.stderr is not None
        stdout = waiting.stdout.read()
        stderr = waiting.stderr.read()
        waiting.stdout.close()
        waiting.stderr.close()
        self.assertEqual(waiting.returncode, 0, stderr)
        self.assertEqual(stdout, "")

        task_b_stop = self.run_gate(
            "hook",
            hook_input={
                **task_b_input,
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Task B did not change files",
            },
        )
        self.assertEqual(task_b_stop.returncode, 0, task_b_stop.stderr)
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertEqual(self.payload(status)["state"], "ready")

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

    def test_detached_stop_warns_and_retains_original_lock(self) -> None:
        prompt = {
            "session_id": "session-a",
            "turn_id": "turn-1",
            "cwd": str(self.repo),
            "hook_event_name": "UserPromptSubmit",
            "model": "test-model",
            "permission_mode": "default",
            "transcript_path": None,
            "prompt": "Start work",
        }
        acquired = self.run_gate(
            "hook",
            "--wait-timeout-seconds",
            "0",
            hook_input=prompt,
        )
        self.assertEqual(acquired.returncode, 0, acquired.stderr)

        self.git("checkout", "--detach")
        stopped = self.run_gate(
            "hook",
            hook_input={
                **prompt,
                "hook_event_name": "Stop",
                "stop_hook_active": False,
                "last_assistant_message": "Done",
            },
        )
        self.assertEqual(stopped.returncode, 0, stopped.stderr)
        warning = self.payload(stopped)
        self.assertTrue(warning["continue"])
        self.assertIn("detached HEAD", warning["systemMessage"])

        self.git("switch", "master")
        status = self.run_gate("status", "--repo-root", str(self.repo), "--json")
        self.assertEqual(status.returncode, 1, status.stderr)
        self.assertEqual(self.payload(status)["task_id"], "session-a")

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

    def test_project_config_registers_prompt_tool_and_stop_hooks(self) -> None:
        config = tomllib.loads(CONFIG_PATH.read_text(encoding="utf-8"))

        self.assertTrue(config["features"]["hooks"])
        prompt_hook = config["hooks"]["UserPromptSubmit"][0]["hooks"][0]
        tool_hook = config["hooks"]["PreToolUse"][0]["hooks"][0]
        stop_hook = config["hooks"]["Stop"][0]["hooks"][0]

        self.assertEqual(prompt_hook["type"], "command")
        self.assertIn("branch-task-gate.py", prompt_hook["command"])
        self.assertIn('"git", "show"', prompt_hook["command"])
        self.assertIn("HEAD:Инструменты/fum-branch-task-gate", prompt_hook["command"])
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
        self.assertEqual(tool_hook["type"], "command")
        self.assertIn("branch-task-gate.py", tool_hook["command"])
        self.assertIn('"git", "show"', tool_hook["command"])
        self.assertIn("--expected-event PreToolUse", tool_hook["command"])
        self.assertGreaterEqual(tool_hook["timeout"], 300)
        self.assertEqual(len(config["hooks"]["Stop"]), 1)
        self.assertEqual(len(config["hooks"]["Stop"][0]["hooks"]), 1)
        self.assertEqual(stop_hook["type"], "command")
        self.assertIn("branch-task-gate.py", stop_hook["command"])
        self.assertIn('"git", "show"', stop_hook["command"])
        self.assertGreaterEqual(stop_hook["timeout"], 300)

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
        self.assertEqual(first.stdout, "")

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

        tool_command = config["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
        broken_tool = subprocess.run(
            tool_command,
            cwd=self.repo,
            shell=True,
            executable="/bin/sh",
            input=json.dumps(
                {
                    **common,
                    "session_id": "session-a",
                    "hook_event_name": "PreToolUse",
                    "tool_name": "Bash",
                    "tool_use_id": "tool-1",
                    "tool_input": {"command": "touch forbidden.txt"},
                }
            ),
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
        self.assertEqual(broken_tool.returncode, 0, broken_tool.stderr)
        tool_payload = self.payload(broken_tool)
        self.assertEqual(
            tool_payload["hookSpecificOutput"]["permissionDecision"],
            "deny",
        )

        stop_command = config["hooks"]["Stop"][0]["hooks"][0]["command"]
        broken_stop = subprocess.run(
            stop_command,
            cwd=self.repo,
            shell=True,
            executable="/bin/sh",
            input=json.dumps(
                {
                    **common,
                    "session_id": "session-a",
                    "hook_event_name": "Stop",
                    "stop_hook_active": False,
                    "last_assistant_message": "Done",
                }
            ),
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )

        self.assertEqual(broken_stop.returncode, 0, broken_stop.stderr)
        stop_payload = self.payload(broken_stop)
        self.assertTrue(stop_payload["continue"])
        self.assertIn("не снято", stop_payload["systemMessage"])


if __name__ == "__main__":
    unittest.main()
