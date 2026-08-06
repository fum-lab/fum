import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import time
import tomllib
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest import mock


TOOL_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = TOOL_ROOT.parents[1]
SCRIPT_REPO_PATH = (
    "Инструменты/fum-ocheredj-zadach-git-vetki/"
    "scripts/ocheredj-zadach-git-vetki.py"
)
SCRIPT_PATH = REPO_ROOT / SCRIPT_REPO_PATH
HEAD_BOOTSTRAP_CODE = (
    "import os,subprocess,sys;"
    f"p={SCRIPT_REPO_PATH!r};"
    "r=sys.argv[1];"
    "e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};"
    "e['GIT_NO_REPLACE_OBJECTS']='1';"
    "e['GIT_OPTIONAL_LOCKS']='0';"
    "b=subprocess.check_output("
    "['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);"
    "sys.argv=[p,*sys.argv[2:],'--repo-root',r];"
    "exec(compile(b,p,'exec'))"
)
PUBLICATION_BOOTSTRAP_CODE = (
    "import os,subprocess,sys;"
    f"p={SCRIPT_REPO_PATH!r};"
    "r=sys.argv[1];"
    "h=sys.argv[2];"
    "e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};"
    "e['GIT_NO_REPLACE_OBJECTS']='1';"
    "e['GIT_OPTIONAL_LOCKS']='0';"
    "b=subprocess.check_output("
    "['git','--no-replace-objects','-C',r,'show',h+':'+p],env=e,timeout=30);"
    "sys.argv=[p,*sys.argv[3:],'--repo-root',r];"
    "exec(compile(b,p,'exec'))"
)
COMPATIBILITY_SCRIPT_PATH = (
    REPO_ROOT
    / "Инструменты"
    / "fum-branch-task-gate"
    / "scripts"
    / "branch-task-gate.py"
)
CONFIG_PATH = REPO_ROOT / ".codex" / "config.toml"
AGENTS_PATH = REPO_ROOT / "AGENTS.md"
SKILL_PATH = TOOL_ROOT / "SKILL.md"
HEARTBEAT_PROMPT_PATH = (
    REPO_ROOT
    / "Инструменты"
    / "fum-sleduyusjhij-shag-vetki"
    / "references"
    / "heartbeat-prompt.md"
)


def load_queue_module():
    module_name = "fum_ocheredj_zadach_git_vetki_under_test"
    spec = importlib.util.spec_from_file_location(module_name, SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


class GitQueueFixture(unittest.TestCase):
    object_format = "sha1"

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.repo = Path(self.temporary_directory.name) / "main"
        self.repo.mkdir()

        init = ["git", "init", "-b", "master"]
        if self.object_format != "sha1":
            init.append(f"--object-format={self.object_format}")
        subprocess.run(init, cwd=self.repo, check=True, capture_output=True)
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

    def git(
        self,
        *args: str,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", "-C", str(self.repo), *args],
            check=check,
            capture_output=True,
            text=True,
        )

    def run_queue(
        self,
        *args: str,
        timeout: float = 10,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT_PATH), *args],
            cwd=self.repo,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )

    def payload(self, result: subprocess.CompletedProcess[str]) -> dict[str, object]:
        self.assertTrue(result.stdout, result.stderr)
        return json.loads(result.stdout)

    def join(self, task_id: str) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        result = self.run_queue(
            "join",
            "--repo-root",
            str(self.repo),
            "--task-id",
            task_id,
            "--json",
        )
        return result, self.payload(result)

    def wait(self, task_id: str, seconds: float = 0) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        result = self.run_queue(
            "wait",
            "--repo-root",
            str(self.repo),
            "--task-id",
            task_id,
            "--timeout-seconds",
            str(seconds),
            "--json",
        )
        return result, self.payload(result)

    def ack_head(self, task_id: str) -> dict[str, object]:
        head = self.git("rev-parse", "HEAD").stdout.strip()
        result = self.run_queue(
            "ack-head",
            "--repo-root",
            str(self.repo),
            "--task-id",
            task_id,
            "--head",
            head,
            "--json",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.payload(result)

    def commit(self, task_id: str, generation: str, message: str = "Finish task"):
        return self.run_queue(
            "commit",
            "--repo-root",
            str(self.repo),
            "--task-id",
            task_id,
            "--generation",
            generation,
            "--message",
            message,
            "--json",
        )

    def finish_clean(self, task_id: str, generation: str):
        return self.run_queue(
            "finish-clean",
            "--repo-root",
            str(self.repo),
            "--task-id",
            task_id,
            "--generation",
            generation,
            "--json",
        )

    def finish_own_clean(
        self,
        task_id: str,
        *,
        ограждающая_ссылка: str | None = None,
        ожидаемый_объект_ограждения: str | None = None,
    ):
        аргументы = [
            "finish-own-clean",
            "--repo-root",
            str(self.repo),
            "--task-id",
            task_id,
        ]
        if ограждающая_ссылка is not None:
            аргументы.extend(("--ограждающая-ссылка", ограждающая_ссылка))
        if ожидаемый_объект_ограждения is not None:
            аргументы.extend(
                (
                    "--ожидаемый-объект-ограждения",
                    ожидаемый_объект_ограждения,
                )
            )
        аргументы.append("--json")
        return self.run_queue(*аргументы)

    def heartbeat_status(self, task_id: str):
        return self.run_queue(
            "heartbeat-status",
            "--repo-root",
            str(self.repo),
            "--task-id",
            task_id,
            "--json",
        )

    def stage_change(self, value: str) -> None:
        (self.repo / "tracked.txt").write_text(value, encoding="utf-8")
        self.git("add", "tracked.txt")


class QueueContractTests(GitQueueFixture):
    def test_heartbeat_status_reports_exact_idle_without_opaque_fields(self) -> None:
        result = self.heartbeat_status("heartbeat-task")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.payload(result), {"state": "idle"})

    def test_heartbeat_status_reports_idle_after_completed_manual_session(
        self,
    ) -> None:
        _, manual = self.join("manual-task")
        self.stage_change("completed manual session\n")
        completed = self.commit("manual-task", str(manual["generation"]))
        self.assertEqual(completed.returncode, 0, completed.stderr)

        status = self.payload(
            self.run_queue("status", "--repo-root", str(self.repo), "--json")
        )
        stored = json.loads(
            self.git("cat-file", "blob", str(status["queue_oid"])).stdout
        )
        self.assertEqual(stored["next_seq"], 2)
        self.assertIsNotNone(stored["last_completion"])
        self.assertIsNone(stored["owner"])
        self.assertEqual(stored["waiting"], [])

        result = self.heartbeat_status("heartbeat-task")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.payload(result), {"state": "idle"})

    def test_heartbeat_status_distinguishes_own_and_foreign_owner(self) -> None:
        self.join("heartbeat-task")
        before = self.payload(
            self.run_queue("status", "--repo-root", str(self.repo), "--json")
        )

        own = self.heartbeat_status("heartbeat-task")
        foreign = self.heartbeat_status("foreign-heartbeat-task")
        after = self.payload(
            self.run_queue("status", "--repo-root", str(self.repo), "--json")
        )

        self.assertEqual(own.returncode, 0, own.stderr)
        self.assertEqual(self.payload(own), {"state": "own_owner"})
        self.assertEqual(foreign.returncode, 0, foreign.stderr)
        self.assertEqual(self.payload(foreign), {"state": "busy"})
        self.assertEqual(after["queue_oid"], before["queue_oid"])

    def test_heartbeat_status_reports_busy_for_own_or_foreign_waiter(self) -> None:
        _, owner = self.join("owner-task")
        self.join("heartbeat-task")
        self.join("foreign-waiter-task")
        finished = self.finish_clean("owner-task", str(owner["generation"]))
        self.assertEqual(finished.returncode, 0, finished.stderr)

        own_waiter = self.heartbeat_status("heartbeat-task")
        foreign_waiter = self.heartbeat_status("unregistered-heartbeat-task")

        self.assertEqual(own_waiter.returncode, 0, own_waiter.stderr)
        self.assertEqual(self.payload(own_waiter), {"state": "busy"})
        self.assertEqual(foreign_waiter.returncode, 0, foreign_waiter.stderr)
        self.assertEqual(self.payload(foreign_waiter), {"state": "busy"})

    def test_heartbeat_status_keeps_own_owner_with_waiting_successors(self) -> None:
        self.join("heartbeat-task")
        self.join("foreign-waiter-task")

        result = self.heartbeat_status("heartbeat-task")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.payload(result), {"state": "own_owner"})

    def test_first_join_is_admitted_and_repeated_join_is_idempotent(self) -> None:
        first, first_payload = self.join("task-a")
        repeated, repeated_payload = self.join("task-a")

        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertEqual(first_payload["state"], "admitted")
        self.assertEqual(first_payload["ownership"], "new")
        self.assertEqual(repeated_payload["state"], "admitted")
        self.assertEqual(repeated_payload["ownership"], "existing")
        self.assertEqual(first_payload["ticket_id"], repeated_payload["ticket_id"])
        self.assertEqual(first_payload["generation"], repeated_payload["generation"])
        self.assertEqual(first_payload["seq"], 1)
        self.assertTrue(str(first_payload["queue_ref"]).startswith(
            "refs/fum/worktree-task-queues/"
        ))

    def test_waiters_are_ordered_by_atomic_registration_sequence(self) -> None:
        self.join("task-a")
        second, second_payload = self.join("task-b")
        third, third_payload = self.join("task-c")
        repeated, repeated_payload = self.join("task-b")

        self.assertNotEqual(second.returncode, 0)
        self.assertNotEqual(third.returncode, 0)
        self.assertNotEqual(repeated.returncode, 0)
        self.assertEqual(second_payload["state"], "waiting")
        self.assertEqual(third_payload["state"], "waiting")
        self.assertEqual(second_payload["seq"], 2)
        self.assertEqual(third_payload["seq"], 3)
        self.assertEqual(second_payload["position"], 1)
        self.assertEqual(third_payload["position"], 2)
        self.assertEqual(second_payload["ticket_id"], repeated_payload["ticket_id"])
        self.assertEqual(repeated_payload["seq"], 2)

        status = self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        )
        payload = self.payload(status)
        self.assertEqual(payload["owner"]["task_id"], "task-a")
        self.assertEqual(
            [ticket["task_id"] for ticket in payload["waiting"]],
            ["task-b", "task-c"],
        )

    def test_commit_releases_owner_but_next_waiter_must_reload_and_ack_head(self) -> None:
        _, first = self.join("task-a")
        self.join("task-b")
        old_head = self.git("rev-parse", "HEAD").stdout.strip()
        self.stage_change("task a\n")

        committed = self.commit(
            "task-a",
            str(first["generation"]),
            "Finish task a exactly",
        )

        self.assertEqual(committed.returncode, 0, committed.stderr)
        committed_payload = self.payload(committed)
        self.assertEqual(committed_payload["state"], "committed")
        self.assertEqual(committed_payload["old_head"], old_head)
        self.assertNotEqual(committed_payload["new_head"], old_head)
        self.assertEqual(
            self.git("log", "-1", "--pretty=%B").stdout.strip(),
            "Finish task a exactly",
        )
        self.assertEqual(self.git("status", "--short").stdout, "")

        waiting, waiting_payload = self.wait("task-b")
        self.assertNotEqual(waiting.returncode, 0)
        self.assertEqual(waiting_payload["state"], "reload_required")
        self.assertEqual(waiting_payload["acknowledged_head"], old_head)
        self.assertEqual(waiting_payload["current_head"], committed_payload["new_head"])

        acknowledged = self.ack_head("task-b")
        self.assertEqual(acknowledged["state"], "acknowledged")
        admitted, admitted_payload = self.wait("task-b")
        self.assertEqual(admitted.returncode, 0, admitted.stderr)
        self.assertEqual(admitted_payload["state"], "admitted")
        self.assertEqual(admitted_payload["base_head"], committed_payload["new_head"])

        replay = self.commit(
            "task-a",
            str(first["generation"]),
            "Finish task a exactly",
        )
        self.assertEqual(replay.returncode, 0, replay.stderr)
        self.assertEqual(self.payload(replay)["state"], "committed")
        self.assertEqual(
            self.payload(replay)["new_head"],
            committed_payload["new_head"],
        )

        self.git("commit", "--allow-empty", "-m", "Move HEAD outside queue")
        stale_replay = self.commit(
            "task-a",
            str(first["generation"]),
            "Finish task a exactly",
        )
        self.assertNotEqual(stale_replay.returncode, 0)
        self.assertEqual(self.payload(stale_replay)["state"], "not_owner")

    def test_later_waiter_cannot_bypass_the_first_live_waiter(self) -> None:
        _, first = self.join("task-a")
        self.join("task-b")
        self.join("task-c")
        self.stage_change("task a\n")
        committed = self.commit("task-a", str(first["generation"]))
        self.assertEqual(committed.returncode, 0, committed.stderr)

        self.ack_head("task-c")
        later, later_payload = self.wait("task-c")
        self.assertNotEqual(later.returncode, 0)
        self.assertEqual(later_payload["state"], "waiting")
        self.assertEqual(later_payload["position"], 2)

        self.ack_head("task-b")
        next_result, next_payload = self.wait("task-b")
        self.assertEqual(next_result.returncode, 0, next_result.stderr)
        self.assertEqual(next_payload["state"], "admitted")
        still_waiting, still_waiting_payload = self.wait("task-c")
        self.assertNotEqual(still_waiting.returncode, 0)
        self.assertEqual(still_waiting_payload["state"], "waiting")

    def test_cancel_only_removes_the_callers_waiting_ticket(self) -> None:
        self.join("task-a")
        _, second = self.join("task-b")
        self.join("task-c")

        owner_cancel = self.run_queue(
            "cancel",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-a",
            "--json",
        )
        self.assertNotEqual(owner_cancel.returncode, 0)
        self.assertEqual(self.payload(owner_cancel)["state"], "owner_cannot_cancel")

        cancelled = self.run_queue(
            "cancel",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-b",
            "--ticket-id",
            str(second["ticket_id"]),
            "--json",
        )
        self.assertEqual(cancelled.returncode, 0, cancelled.stderr)
        self.assertEqual(self.payload(cancelled)["state"], "cancelled")
        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(
            [ticket["task_id"] for ticket in status["waiting"]],
            ["task-c"],
        )

    def test_concurrent_join_assigns_one_owner_and_unique_fifo_sequences(self) -> None:
        def join_task(task_id: str) -> dict[str, object]:
            return self.join(task_id)[1]

        task_ids = [f"task-{index}" for index in range(12)]
        with ThreadPoolExecutor(max_workers=len(task_ids)) as executor:
            payloads = list(executor.map(join_task, task_ids))

        admitted = [item for item in payloads if item["state"] == "admitted"]
        self.assertEqual(len(admitted), 1)
        self.assertEqual(sorted(int(item["seq"]) for item in payloads), list(range(1, 13)))
        self.assertEqual(len({item["ticket_id"] for item in payloads}), 12)

        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        all_sequences = [int(status["owner"]["seq"])] + [
            int(ticket["seq"]) for ticket in status["waiting"]
        ]
        self.assertEqual(all_sequences, list(range(1, 13)))

    def test_bounded_wait_does_not_mutate_queue_while_blocked(self) -> None:
        self.join("task-a")
        self.join("task-b")
        before = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))

        result, refreshed = self.wait("task-b", seconds=0.15)

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(refreshed["state"], "waiting")
        after = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(after["queue_oid"], before["queue_oid"])

    def test_wait_until_actionable_stays_silent_and_read_only_until_reload(self) -> None:
        _, owner = self.join("task-a")
        self.join("task-b")
        before = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))

        with ThreadPoolExecutor(max_workers=1) as executor:
            waiting = executor.submit(
                self.run_queue,
                "wait-until-actionable",
                "--repo-root",
                str(self.repo),
                "--task-id",
                "task-b",
                "--json",
                timeout=5,
            )
            time.sleep(0.15)

            self.assertFalse(waiting.done())
            blocked = self.payload(self.run_queue(
                "status", "--repo-root", str(self.repo), "--json"
            ))
            self.assertEqual(blocked["queue_oid"], before["queue_oid"])

            self.stage_change("task a\n")
            committed = self.commit("task-a", str(owner["generation"]))
            self.assertEqual(committed.returncode, 0, committed.stderr)
            committed_payload = self.payload(committed)
            result = waiting.result(timeout=5)

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.payload(result)["state"], "reload_required")
        after = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(after["queue_oid"], committed_payload["queue_oid"])

    def test_wait_until_actionable_returns_admitted_without_intermediate_waiting(self) -> None:
        _, owner = self.join("task-a")
        self.join("task-b")

        with ThreadPoolExecutor(max_workers=1) as executor:
            waiting = executor.submit(
                self.run_queue,
                "wait-until-actionable",
                "--repo-root",
                str(self.repo),
                "--task-id",
                "task-b",
                "--json",
                timeout=5,
            )
            time.sleep(0.15)

            self.assertFalse(waiting.done())
            finished = self.finish_clean("task-a", str(owner["generation"]))
            self.assertEqual(finished.returncode, 0, finished.stderr)
            result = waiting.result(timeout=5)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.payload(result)["state"], "admitted")
        self.assertEqual(len(result.stdout.splitlines()), 1)

    def test_stale_waiter_keeps_its_fifo_position_without_any_ttl(self) -> None:
        module = load_queue_module()
        self.join("task-a")
        self.join("task-b")
        self.join("task-c")
        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        queue_oid = str(status["queue_oid"])
        queue_ref = str(status["queue_ref"])
        state = json.loads(self.git("cat-file", "blob", queue_oid).stdout)
        state["waiting"][0]["registered_at"] = "1970-01-01T00:00:00Z"
        state["waiting"][0]["registered_at_epoch"] = 0.0
        stale_oid = subprocess.run(
            ["git", "-C", str(self.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(state, ensure_ascii=False, sort_keys=True),
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        self.git("update-ref", queue_ref, stale_oid, queue_oid)

        waited, payload = self.wait("task-c", seconds=0)

        self.assertNotEqual(waited.returncode, 0)
        self.assertEqual(payload["state"], "waiting")
        refreshed = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(
            [ticket["task_id"] for ticket in refreshed["waiting"]],
            ["task-b", "task-c"],
        )
        self.assertFalse(hasattr(module, "WAITING_TICKET_TTL_SECONDS"))
        self.assertFalse(hasattr(module, "prune_expired_waiters"))
        self.assertFalse(hasattr(module, "OWNER_TTL_SECONDS"))


class QueueSafetyTests(GitQueueFixture):
    def test_head_bootstrap_executes_the_committed_script_and_fences_root(self) -> None:
        committed_script = self.repo / SCRIPT_REPO_PATH
        committed_script.parent.mkdir(parents=True)
        committed_script.write_bytes(SCRIPT_PATH.read_bytes())
        self.git("add", str(committed_script.relative_to(self.repo)))
        self.git("commit", "-m", "Add committed queue script")
        safe_head = self.git("rev-parse", "HEAD").stdout.strip()
        committed_script.write_text(
            "raise RuntimeError('dirty script must not run')\n",
            encoding="utf-8",
        )
        self.git("add", str(committed_script.relative_to(self.repo)))
        self.git("commit", "-m", "Create hostile replacement commit")
        replacement_head = self.git("rev-parse", "HEAD").stdout.strip()
        self.git(
            "update-ref",
            "refs/heads/master",
            safe_head,
            replacement_head,
        )
        self.git("replace", safe_head, replacement_head)
        (self.repo / "subprocess.py").write_text(
            "raise RuntimeError('dirty import must not run')\n",
            encoding="utf-8",
        )
        foreign_repo = Path(self.temporary_directory.name) / "foreign"
        subprocess.run(
            ["git", "init", "-b", "master", str(foreign_repo)],
            check=True,
            capture_output=True,
        )
        (foreign_repo / "foreign.txt").write_text("foreign\n", encoding="utf-8")
        subprocess.run(
            ["git", "-C", str(foreign_repo), "add", "foreign.txt"],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            [
                "git",
                "-C",
                str(foreign_repo),
                "-c",
                "user.name=FUM Test",
                "-c",
                "user.email=fum-test@example.invalid",
                "commit",
                "-m",
                "Foreign commit",
            ],
            check=True,
            capture_output=True,
        )

        result = subprocess.run(
            [
                sys.executable,
                "-I",
                "-c",
                HEAD_BOOTSTRAP_CODE,
                str(self.repo),
                "status",
                "--repo-root",
                str(self.repo / "not-the-bootstrap-root"),
                "--repo-root",
                str(self.repo),
                "--json",
            ],
            cwd=self.repo,
            env={
                **os.environ,
                "GIT_DIR": str(foreign_repo / ".git"),
                "GIT_WORK_TREE": str(foreign_repo),
                "GIT_INDEX_FILE": str(foreign_repo / ".git" / "index"),
                "GIT_CONFIG_COUNT": "1",
                "GIT_CONFIG_KEY_0": "core.bare",
                "GIT_CONFIG_VALUE_0": "true",
                "GIT_TRACE": str(self.repo / "git-trace.log"),
                "GIT_TRACE2_EVENT": str(self.repo / "git-trace2.json"),
            },
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.payload(result)["state"], "idle")
        self.assertFalse((self.repo / "git-trace.log").exists())
        self.assertFalse((self.repo / "git-trace2.json").exists())

        abbreviated = self.run_queue(
            "status", "--repo-r", str(self.repo), "--json"
        )
        self.assertNotEqual(abbreviated.returncode, 0)
        self.assertIn("unrecognized arguments", abbreviated.stderr)

    def test_core_ignores_replace_objects_for_queue_state(self) -> None:
        joined, owner = self.join("task-a")
        self.assertEqual(joined.returncode, 0, joined.stderr)
        queue_oid = str(owner["queue_oid"])
        original = json.loads(self.git("cat-file", "blob", queue_oid).stdout)
        original["owner"]["task_id"] = "replacement-owner"
        replacement = subprocess.run(
            ["git", "-C", str(self.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(original, ensure_ascii=False, sort_keys=True),
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        self.git("replace", queue_oid, replacement)

        status = self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        )

        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertEqual(self.payload(status)["owner"]["task_id"], "task-a")

    def test_join_does_not_refresh_the_git_index_stat_cache(self) -> None:
        index_path = self.repo / ".git" / "index"
        before = index_path.stat().st_mtime_ns
        future = time.time() + 10.0
        os.utime(self.repo / "tracked.txt", (future, future))

        joined, payload = self.join("task-a")

        self.assertEqual(joined.returncode, 0, joined.stderr)
        self.assertEqual(payload["state"], "admitted")
        self.assertEqual(index_path.stat().st_mtime_ns, before)

    def test_persistent_queue_ref_lock_is_reported_as_a_git_error(self) -> None:
        module = load_queue_module()
        context = module.resolve_context(self.repo)
        lock_path = context.git_dir / f"{context.queue_ref}.lock"
        lock_path.parent.mkdir(parents=True, exist_ok=True)
        lock_path.write_text("occupied\n", encoding="utf-8")

        result, payload = self.join("task-a")

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(payload["state"], "git_error")
        self.assertIn("git_stderr", payload)

    def test_persistent_branch_ref_lock_is_reported_as_a_git_error(self) -> None:
        _, owner = self.join("task-a")
        old_head = self.git("rev-parse", "HEAD").stdout.strip()
        self.stage_change("task a\n")
        lock_path = self.repo / ".git" / "refs" / "heads" / "master.lock"
        lock_path.write_text("occupied\n", encoding="utf-8")

        result = self.commit("task-a", str(owner["generation"]))

        self.assertNotEqual(result.returncode, 0)
        payload = self.payload(result)
        self.assertEqual(payload["state"], "git_error")
        self.assertIn("git_stderr", payload)
        self.assertEqual(self.git("rev-parse", "HEAD").stdout.strip(), old_head)
        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(status["owner"]["task_id"], "task-a")

    def test_initial_claim_waits_for_a_clean_tree_outside_root_obsidian(self) -> None:
        (self.repo / ".obsidian" / "workspace.json").write_text(
            "{}\n", encoding="utf-8"
        )
        clean_result, clean_payload = self.join("task-a")
        self.assertEqual(clean_result.returncode, 0, clean_result.stderr)
        self.assertEqual(clean_payload["state"], "admitted")

        self.stage_change("task a\n")
        committed = self.commit("task-a", str(clean_payload["generation"]))
        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.assertIn(".obsidian/workspace.json", self.git("status", "--short").stdout)

        (self.repo / "untracked.txt").write_text("unknown\n", encoding="utf-8")
        dirty_result, dirty_payload = self.join("task-b")
        self.assertNotEqual(dirty_result.returncode, 0)
        self.assertEqual(dirty_payload["state"], "dirty")
        self.assertIn("untracked.txt", dirty_payload["blocking_paths"])

    def test_commit_rejects_unstaged_untracked_and_conflicted_work(self) -> None:
        _, owner = self.join("task-a")
        old_head = self.git("rev-parse", "HEAD").stdout.strip()
        self.stage_change("staged\n")
        (self.repo / "untracked.txt").write_text("unknown\n", encoding="utf-8")

        result = self.commit("task-a", str(owner["generation"]))

        self.assertNotEqual(result.returncode, 0)
        payload = self.payload(result)
        self.assertEqual(payload["state"], "dirty")
        self.assertIn("untracked.txt", payload["blocking_paths"])
        self.assertEqual(self.git("rev-parse", "HEAD").stdout.strip(), old_head)
        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(status["owner"]["task_id"], "task-a")

    def test_commit_requires_staged_changes_and_matching_generation(self) -> None:
        _, owner = self.join("task-a")

        empty = self.commit("task-a", str(owner["generation"]))
        self.assertNotEqual(empty.returncode, 0)
        self.assertEqual(self.payload(empty)["state"], "nothing_staged")

        self.stage_change("task a\n")
        wrong = self.commit("task-a", "wrong-generation")
        self.assertNotEqual(wrong.returncode, 0)
        self.assertEqual(self.payload(wrong)["state"], "not_owner")

    def test_clean_owner_can_finish_without_commit_but_dirty_owner_cannot(self) -> None:
        _, owner = self.join("task-a")
        self.join("task-b")
        old_head = self.git("rev-parse", "HEAD").stdout.strip()
        obsidian_change = self.repo / ".obsidian" / "workspace.json"
        obsidian_change.write_text("{}\n", encoding="utf-8")
        self.git("add", ".obsidian/workspace.json")

        dirty = self.finish_clean("task-a", str(owner["generation"]))

        self.assertNotEqual(dirty.returncode, 0)
        dirty_payload = self.payload(dirty)
        self.assertEqual(dirty_payload["state"], "dirty")
        self.assertIn(".obsidian/workspace.json", dirty_payload["blocking_paths"])
        self.git("reset", "--", ".obsidian/workspace.json")

        wrong = self.finish_clean("task-a", "wrong-generation")
        self.assertNotEqual(wrong.returncode, 0)
        self.assertEqual(self.payload(wrong)["state"], "not_owner")

        finished = self.finish_clean("task-a", str(owner["generation"]))
        self.assertEqual(finished.returncode, 0, finished.stderr)
        self.assertEqual(self.payload(finished)["state"], "finished_clean")
        self.assertEqual(self.git("rev-parse", "HEAD").stdout.strip(), old_head)

        admitted, payload = self.wait("task-b")
        self.assertEqual(admitted.returncode, 0, admitted.stderr)
        self.assertEqual(payload["state"], "admitted")

        replay = self.finish_clean("task-a", str(owner["generation"]))
        self.assertEqual(replay.returncode, 0, replay.stderr)
        self.assertEqual(self.payload(replay)["state"], "finished_clean")
        self.assertEqual(self.payload(replay)["head"], old_head)

    def test_finish_own_clean_cli_captures_generation_and_hands_off(self) -> None:
        _, owner = self.join("task-a")
        self.join("task-b")
        old_head = self.git("rev-parse", "HEAD").stdout.strip()

        finished = self.finish_own_clean("task-a")

        self.assertEqual(finished.returncode, 0, finished.stderr)
        payload = self.payload(finished)
        self.assertEqual(payload["state"], "finished_clean")
        self.assertEqual(payload["task_id"], "task-a")
        self.assertEqual(payload["generation"], owner["generation"])
        self.assertEqual(payload["head"], old_head)

        admitted, admitted_payload = self.wait("task-b")
        self.assertEqual(admitted.returncode, 0, admitted.stderr)
        self.assertEqual(admitted_payload["state"], "admitted")

    def test_finish_own_clean_rejects_foreign_and_missing_owner(self) -> None:
        _, owner = self.join("task-a")

        foreign = self.finish_own_clean("task-b")

        self.assertNotEqual(foreign.returncode, 0)
        self.assertEqual(self.payload(foreign)["state"], "not_owner")
        active = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(active["owner"]["task_id"], "task-a")
        self.assertEqual(active["owner"]["generation"], owner["generation"])

        finished = self.finish_own_clean("task-a")
        self.assertEqual(finished.returncode, 0, finished.stderr)

        missing = self.finish_own_clean("task-a")
        self.assertNotEqual(missing.returncode, 0)
        self.assertEqual(self.payload(missing)["state"], "not_owner")

    def test_finish_own_clean_preserves_dirty_staged_and_head_fences(self) -> None:
        _, owner = self.join("task-a")

        untracked_path = self.repo / "untracked.txt"
        untracked_path.write_text("untracked dirt\n", encoding="utf-8")
        untracked = self.finish_own_clean("task-a")

        self.assertNotEqual(untracked.returncode, 0)
        untracked_payload = self.payload(untracked)
        self.assertEqual(untracked_payload["state"], "dirty")
        self.assertIn("untracked.txt", untracked_payload["blocking_paths"])
        untracked_path.unlink()

        (self.repo / "tracked.txt").write_text("unstaged dirt\n", encoding="utf-8")
        unstaged = self.finish_own_clean("task-a")

        self.assertNotEqual(unstaged.returncode, 0)
        unstaged_payload = self.payload(unstaged)
        self.assertEqual(unstaged_payload["state"], "dirty")
        self.assertIn("tracked.txt", unstaged_payload["blocking_paths"])
        self.git("restore", "tracked.txt")

        self.stage_change("staged dirt\n")

        dirty = self.finish_own_clean("task-a")

        self.assertNotEqual(dirty.returncode, 0)
        dirty_payload = self.payload(dirty)
        self.assertEqual(dirty_payload["state"], "dirty")
        self.assertIn("tracked.txt", dirty_payload["blocking_paths"])
        self.git("restore", "--staged", "tracked.txt")
        self.git("restore", "tracked.txt")

        self.git("commit", "--allow-empty", "-m", "Concurrent head move")
        moved_head = self.git("rev-parse", "HEAD").stdout.strip()
        changed = self.finish_own_clean("task-a")

        self.assertNotEqual(changed.returncode, 0)
        changed_payload = self.payload(changed)
        self.assertEqual(changed_payload["state"], "head_changed")
        self.assertEqual(changed_payload["expected_head"], owner["base_head"])
        self.assertEqual(changed_payload["current_head"], moved_head)
        active = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(active["owner"]["task_id"], "task-a")
        self.assertEqual(active["owner"]["generation"], owner["generation"])

    def test_finish_own_clean_fails_closed_if_generation_changes_after_capture(self) -> None:
        module = load_queue_module()
        _, owner = self.join("task-a")
        context = module.resolve_context(self.repo)
        initial_state, queue_oid = module.read_state(context)
        raced_state = json.loads(json.dumps(initial_state))
        raced_state["owner"]["generation"] = "raced-generation"

        with mock.patch.object(
            module,
            "read_state",
            side_effect=[
                (initial_state, queue_oid),
                (raced_state, queue_oid),
            ],
        ):
            with self.assertRaises(module.QueueError) as raised:
                module.finish_own_clean_and_handoff(context, "task-a")

        self.assertEqual(raised.exception.state, "not_owner")
        active = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(active["owner"]["task_id"], "task-a")
        self.assertEqual(active["owner"]["generation"], owner["generation"])

    def test_чистое_завершение_своего_владельца_атомарно_проверяет_внешнее_ограждение(
        сам,
    ) -> None:
        модуль = load_queue_module()
        _, владелец = сам.join("task-a")
        контекст = модуль.resolve_context(сам.repo)
        ограждающая_ссылка = "refs/fum/test-management-guard"
        исходная_запись_состояния = модуль.write_state_blob
        гонка = False

        def записать_и_создать_ограждение(контекст_очереди, состояние):
            nonlocal гонка
            идентификатор_объекта = исходная_запись_состояния(
                контекст_очереди,
                состояние,
            )
            if not гонка and состояние.get("owner") is None:
                гонка = True
                объект_ограждения = сам.git(
                    "rev-parse",
                    "HEAD",
                ).stdout.strip()
                сам.git(
                    "update-ref",
                    ограждающая_ссылка,
                    объект_ограждения,
                )
            return идентификатор_объекта

        with mock.patch.object(
            модуль,
            "write_state_blob",
            записать_и_создать_ограждение,
        ):
            with сам.assertRaises(модуль.QueueError) as исключение:
                модуль.finish_own_clean_and_handoff(
                    контекст,
                    "task-a",
                    ограждающая_ссылка,
                    "absent",
                )

        сам.assertEqual(исключение.exception.state, "guard_changed")
        активное = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(активное["owner"]["task_id"], "task-a")
        сам.assertEqual(
            активное["owner"]["generation"],
            владелец["generation"],
        )

        сам.git("update-ref", "-d", ограждающая_ссылка)
        завершение = сам.finish_own_clean(
            "task-a",
            ограждающая_ссылка=ограждающая_ссылка,
            ожидаемый_объект_ограждения="absent",
        )
        сам.assertEqual(завершение.returncode, 0, завершение.stderr)
        сам.assertEqual(
            сам.payload(завершение)["state"],
            "finished_clean",
        )

    def test_finish_clean_atomically_verifies_the_branch_head(self) -> None:
        module = load_queue_module()
        _, owner = self.join("task-a")
        context = module.resolve_context(self.repo)
        original_write_state_blob = module.write_state_blob
        raced = False

        def write_blob_then_move_head(queue_context, state):
            nonlocal raced
            oid = original_write_state_blob(queue_context, state)
            if not raced and state.get("owner") is None:
                raced = True
                self.git("commit", "--allow-empty", "-m", "Concurrent head move")
            return oid

        with mock.patch.object(module, "write_state_blob", write_blob_then_move_head):
            with self.assertRaises(module.QueueError) as raised:
                module.finish_clean_and_handoff(
                    context,
                    "task-a",
                    str(owner["generation"]),
                )

        self.assertEqual(raised.exception.state, "head_changed")
        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(status["owner"]["task_id"], "task-a")

    def test_admission_atomically_verifies_the_acknowledged_head(self) -> None:
        module = load_queue_module()
        _, first = self.join("task-a")
        self.join("task-b")
        finished = self.finish_clean("task-a", str(first["generation"]))
        self.assertEqual(finished.returncode, 0, finished.stderr)
        context = module.resolve_context(self.repo)
        original_write_state_blob = module.write_state_blob
        raced = False

        def write_blob_then_move_head(queue_context, state):
            nonlocal raced
            oid = original_write_state_blob(queue_context, state)
            owner = state.get("owner")
            if not raced and isinstance(owner, dict) and owner["task_id"] == "task-b":
                raced = True
                self.git("commit", "--allow-empty", "-m", "Concurrent admission move")
            return oid

        with mock.patch.object(module, "write_state_blob", write_blob_then_move_head):
            code, payload = module.attempt_admit(context, "task-b")

        self.assertEqual(code, module.EXIT_RELOAD_REQUIRED)
        self.assertEqual(payload["state"], "reload_required")
        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertIsNone(status["owner"])
        self.assertEqual(status["waiting"][0]["task_id"], "task-b")

    def test_external_head_change_is_fenced_and_preserves_queue_owner(self) -> None:
        _, owner = self.join("task-a")
        base_head = str(owner["base_head"])
        self.git("commit", "--allow-empty", "-m", "External commit")
        external_head = self.git("rev-parse", "HEAD").stdout.strip()
        self.stage_change("task a\n")

        result = self.commit("task-a", str(owner["generation"]))

        self.assertNotEqual(result.returncode, 0)
        payload = self.payload(result)
        self.assertEqual(payload["state"], "head_changed")
        self.assertEqual(payload["expected_head"], base_head)
        self.assertEqual(payload["current_head"], external_head)
        status = self.payload(self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        ))
        self.assertEqual(status["owner"]["task_id"], "task-a")

    def test_branch_switch_and_detached_head_are_rejected(self) -> None:
        _, owner = self.join("task-a")
        self.git("switch", "-c", "other")
        switched, switched_payload = self.join("task-b")
        self.assertNotEqual(switched.returncode, 0)
        self.assertEqual(switched_payload["state"], "branch_changed")

        self.stage_change("other branch\n")
        commit = self.commit("task-a", str(owner["generation"]))
        self.assertNotEqual(commit.returncode, 0)
        self.assertEqual(self.payload(commit)["state"], "branch_changed")

        self.git("reset", "--hard", "HEAD")
        self.git("switch", "master")
        self.git("checkout", "--detach")
        detached = self.run_queue(
            "status", "--repo-root", str(self.repo), "--json"
        )
        self.assertNotEqual(detached.returncode, 0)
        self.assertEqual(self.payload(detached)["state"], "invalid_context")

    def test_ack_requires_current_head_and_an_existing_waiter(self) -> None:
        self.join("task-a")
        self.join("task-b")
        wrong = self.run_queue(
            "ack-head",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-b",
            "--head",
            "0" * 40,
            "--json",
        )
        self.assertNotEqual(wrong.returncode, 0)
        self.assertEqual(self.payload(wrong)["state"], "head_mismatch")

        absent = self.run_queue(
            "ack-head",
            "--repo-root",
            str(self.repo),
            "--task-id",
            "task-c",
            "--head",
            self.git("rev-parse", "HEAD").stdout.strip(),
            "--json",
        )
        self.assertNotEqual(absent.returncode, 0)
        self.assertEqual(self.payload(absent)["state"], "not_registered")

    def test_wait_rejects_non_finite_timeouts(self) -> None:
        self.join("task-a")
        self.join("task-b")

        for value in ["nan", "inf", "-inf"]:
            with self.subTest(value=value):
                result = self.run_queue(
                    "wait",
                    "--repo-root",
                    str(self.repo),
                    "--task-id",
                    "task-b",
                    f"--timeout-seconds={value}",
                    "--json",
                    timeout=0.5,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.payload(result)["state"], "invalid_timeout")

    def test_wait_until_actionable_keyboard_interrupt_is_silent(self) -> None:
        module = load_queue_module()

        with (
            mock.patch.object(
                module,
                "resolve_context",
                return_value=mock.sentinel.context,
            ),
            mock.patch.object(
                module,
                "wait_until_actionable_queue",
                side_effect=KeyboardInterrupt,
            ),
            mock.patch("sys.stdout", new_callable=io.StringIO) as stdout,
            mock.patch("sys.stderr", new_callable=io.StringIO) as stderr,
        ):
            code = module.main(["wait-until-actionable", "--task-id", "task-b"])

        self.assertEqual(code, 130)
        self.assertEqual(stdout.getvalue(), "")
        self.assertEqual(stderr.getvalue(), "")

    def test_wait_defaults_to_five_minutes(self) -> None:
        module = load_queue_module()

        args = module.build_parser().parse_args(
            ["wait", "--task-id", "task-b"]
        )

        self.assertEqual(args.timeout_seconds, 300.0)

    def test_atomic_commit_supports_a_unicode_branch_ref(self) -> None:
        self.git("switch", "-c", "проверка/очереди")
        joined, owner = self.join("task-a")
        self.assertEqual(joined.returncode, 0, joined.stderr)
        self.stage_change("unicode branch\n")

        committed = self.commit(
            "task-a",
            str(owner["generation"]),
            "Коммит в Unicode-ветке",
        )

        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.assertEqual(self.payload(committed)["state"], "committed")
        self.assertEqual(
            self.git("symbolic-ref", "HEAD").stdout.strip(),
            "refs/heads/проверка/очереди",
        )

    def test_json_errors_are_safe_with_an_ascii_stdout_encoding(self) -> None:
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "wait",
                "--repo-root",
                str(self.repo),
                "--task-id",
                "missing-task",
                "--timeout-seconds=0",
                "--json",
            ],
            cwd=self.repo,
            env={**os.environ, "PYTHONIOENCODING": "ascii"},
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.payload(result)["state"], "not_registered")

    def test_source_uses_git_cas_without_posix_locking_primitives(self) -> None:
        source = SCRIPT_PATH.read_text(encoding="utf-8")
        forbidden = ["import fcntl", "from fcntl", "flock(", "os.link(", "signal."]
        for fragment in forbidden:
            self.assertNotIn(fragment, source)
        self.assertIn("update-ref", source)
        self.assertIn("hash-object", source)
        self.assertIn("commit-tree", source)
        self.assertIn('environment["GIT_NO_REPLACE_OBJECTS"] = "1"', source)

    def test_cli_exposes_no_reordering_or_force_takeover_command(self) -> None:
        result = self.run_queue("--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("reorder", result.stdout.lower())
        self.assertNotIn("force", result.stdout.lower())
        self.assertNotIn("release", result.stdout.lower())


class GitHubPublicationTests(GitQueueFixture):
    push_url = "https://github.com/fum-test/fum-publication-fixture.git"
    branch_ref = "refs/heads/master"

    def setUp(self) -> None:
        super().setUp()
        self.module = load_queue_module()
        self.remote = Path(self.temporary_directory.name) / "remote.git"
        subprocess.run(
            ["git", "init", "--bare", "-b", "master", str(self.remote)],
            check=True,
            capture_output=True,
        )
        self.git(
            "config",
            f"url.{self.remote.as_uri()}.insteadOf",
            self.push_url,
        )
        self.git("push", self.push_url, f"HEAD:{self.branch_ref}")

    def publish(self, commit: str) -> subprocess.CompletedProcess[str]:
        try:
            code, payload = self.module.publish_exact_commit(
                self.module.resolve_context(self.repo),
                commit,
                self.branch_ref,
                self.push_url,
                allow_url_rewrite_for_tests=True,
            )
        except self.module.QueueError as error:
            code = error.exit_code
            payload = self.module.error_payload(error)
        return subprocess.CompletedProcess(
            args=["publish"],
            returncode=code,
            stdout=json.dumps(payload, ensure_ascii=True, sort_keys=True) + "\n",
            stderr="",
        )

    def make_commit(self, value: str, message: str) -> str:
        (self.repo / "tracked.txt").write_text(value, encoding="utf-8")
        self.git("add", "tracked.txt")
        self.git("commit", "-m", message)
        return self.git("rev-parse", "HEAD").stdout.strip()

    def remote_head(self) -> str:
        return subprocess.run(
            ["git", "--git-dir", str(self.remote), "rev-parse", self.branch_ref],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

    def remote_refs(self, pattern: str) -> str:
        return subprocess.run(
            ["git", "--git-dir", str(self.remote), "for-each-ref", pattern],
            check=True,
            capture_output=True,
            text=True,
        ).stdout

    def local_refs(self) -> str:
        return self.git(
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
        ).stdout

    def test_publish_uses_exact_commit_when_current_head_has_advanced(self) -> None:
        first = self.make_commit("first\n", "First")
        second = self.make_commit("second\n", "Second")
        refs_before = self.local_refs()

        result = self.publish(first)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.payload(result)["state"], "published")
        self.assertEqual(self.remote_head(), first)
        self.assertEqual(self.git("rev-parse", "HEAD").stdout.strip(), second)
        self.assertEqual(self.local_refs(), refs_before)

    def test_older_commit_is_already_published_through_remote_descendant(self) -> None:
        first = self.make_commit("first\n", "First")
        second = self.make_commit("second\n", "Second")
        self.assertEqual(self.publish(second).returncode, 0)

        result = self.publish(first)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.payload(result)["state"],
            "already_published_descendant",
        )
        self.assertEqual(self.remote_head(), second)

    def test_unknown_remote_descendant_is_verified_in_temporary_bare_repo(self) -> None:
        target = self.make_commit("target\n", "Target")
        self.assertEqual(self.publish(target).returncode, 0)
        other = Path(self.temporary_directory.name) / "descendant"
        subprocess.run(
            ["git", "clone", self.remote.as_uri(), str(other)],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "FUM Descendant"],
            cwd=other,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.email", "descendant@example.invalid"],
            cwd=other,
            check=True,
        )
        (other / "tracked.txt").write_text("descendant\n", encoding="utf-8")
        subprocess.run(["git", "add", "tracked.txt"], cwd=other, check=True)
        subprocess.run(
            ["git", "commit", "-m", "Remote descendant"],
            cwd=other,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "push", "origin", f"HEAD:{self.branch_ref}"],
            cwd=other,
            check=True,
            capture_output=True,
        )
        remote_descendant = self.remote_head()
        self.assertFalse(
            self.git("cat-file", "-e", remote_descendant, check=False).returncode == 0
        )

        hooks = Path(self.temporary_directory.name) / "global-hooks"
        hooks.mkdir()
        marker = Path(self.temporary_directory.name) / "reference-hook-ran"
        hook = hooks / "reference-transaction"
        hook.write_text(
            f"#!{sys.executable}\n"
            "from pathlib import Path\n"
            f"Path({str(marker)!r}).touch()\n",
            encoding="utf-8",
        )
        hook.chmod(0o755)
        xdg = Path(self.temporary_directory.name) / "xdg" / "git"
        xdg.mkdir(parents=True)
        (xdg / "config").write_text(
            f"[core]\n\thooksPath = {hooks}\n",
            encoding="utf-8",
        )
        with mock.patch.dict(
            os.environ,
            {"XDG_CONFIG_HOME": str(xdg.parent)},
        ):
            result = self.publish(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.payload(result)["state"],
            "already_published_descendant",
        )
        self.assertEqual(self.remote_head(), remote_descendant)
        self.assertFalse(marker.exists())

    def test_divergent_remote_is_not_changed(self) -> None:
        target = self.make_commit("target\n", "Target")
        other = Path(self.temporary_directory.name) / "other"
        subprocess.run(
            ["git", "clone", self.remote.as_uri(), str(other)],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "FUM Other"],
            cwd=other,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.email", "other@example.invalid"],
            cwd=other,
            check=True,
        )
        (other / "tracked.txt").write_text("divergent\n", encoding="utf-8")
        subprocess.run(["git", "add", "tracked.txt"], cwd=other, check=True)
        subprocess.run(
            ["git", "commit", "-m", "Divergent"],
            cwd=other,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "push", "origin", f"HEAD:{self.branch_ref}"],
            cwd=other,
            check=True,
            capture_output=True,
        )
        divergent = self.remote_head()

        result = self.publish(target)

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.payload(result)["state"], "diverged")
        self.assertEqual(self.remote_head(), divergent)

    def test_receive_rejection_is_not_reported_as_success(self) -> None:
        target = self.make_commit("target\n", "Target")
        hook = self.remote / "hooks" / "pre-receive"
        hook.write_text(
            f"#!{sys.executable}\nraise SystemExit(1)\n",
            encoding="utf-8",
        )
        hook.chmod(0o755)
        remote_before = self.remote_head()

        result = self.publish(target)

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.payload(result)["state"], "rejected")
        self.assertEqual(self.remote_head(), remote_before)

    def test_pre_push_hook_is_disabled(self) -> None:
        target = self.make_commit("target\n", "Target")
        hooks = Path(self.temporary_directory.name) / "hooks"
        hooks.mkdir()
        marker = Path(self.temporary_directory.name) / "pre-push-ran"
        hook = hooks / "pre-push"
        hook.write_text(
            f"#!{sys.executable}\n"
            "from pathlib import Path\n"
            f"Path({str(marker)!r}).touch()\n"
            "raise SystemExit(1)\n",
            encoding="utf-8",
        )
        hook.chmod(0o755)
        self.git("config", "core.hooksPath", str(hooks))

        result = self.publish(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(marker.exists())
        self.assertEqual(self.remote_head(), target)

    def test_follow_tags_configuration_cannot_expand_publication(self) -> None:
        target = self.make_commit("target\n", "Target")
        self.git("tag", "-a", "must-not-publish", "-m", "Local tag")
        self.git("config", "push.followTags", "true")

        result = self.publish(target)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.remote_head(), target)
        self.assertEqual(self.remote_refs("refs/tags"), "")

    def test_ambiguous_push_result_is_verified_against_remote_head(self) -> None:
        target = self.make_commit("target\n", "Target")
        timeout = subprocess.CompletedProcess(
            args=["git", "push"],
            returncode=124,
            stdout=b"",
            stderr=b"",
        )
        observed = subprocess.CompletedProcess(
            args=["git", "ls-remote"],
            returncode=0,
            stdout=f"{target}\t{self.branch_ref}\n".encode(),
            stderr=b"",
        )
        with mock.patch.object(
            self.module,
            "run_publication_git",
            side_effect=[timeout, observed],
        ):
            code, payload = self.module.publish_exact_commit(
                self.module.resolve_context(self.repo),
                target,
                self.branch_ref,
                self.push_url,
                allow_url_rewrite_for_tests=True,
            )

        self.assertEqual(code, 0)
        self.assertEqual(payload["state"], "published")
        self.assertEqual(payload["remote_head"], target)

    def test_failed_remote_verification_is_unconfirmed(self) -> None:
        target = self.make_commit("target\n", "Target")
        failed_push = subprocess.CompletedProcess(
            args=["git", "push"],
            returncode=1,
            stdout=b"",
            stderr=b"",
        )
        failed_read = subprocess.CompletedProcess(
            args=["git", "ls-remote"],
            returncode=1,
            stdout=b"",
            stderr=b"",
        )
        with mock.patch.object(
            self.module,
            "run_publication_git",
            side_effect=[failed_push, failed_read],
        ):
            result = self.publish(target)

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.payload(result)["state"], "unconfirmed")

    def test_ancestry_git_error_is_unconfirmed(self) -> None:
        target = self.make_commit("target\n", "Target")
        remote_before = self.remote_head()
        failed_push = subprocess.CompletedProcess(
            args=["git", "push"],
            returncode=1,
            stdout=b"",
            stderr=b"",
        )
        observed = subprocess.CompletedProcess(
            args=["git", "ls-remote"],
            returncode=0,
            stdout=f"{remote_before}\t{self.branch_ref}\n".encode(),
            stderr=b"",
        )
        with (
            mock.patch.object(
                self.module,
                "run_publication_git",
                side_effect=[failed_push, observed],
            ),
            mock.patch.object(self.module, "commit_exists", return_value=True),
            mock.patch.object(self.module, "is_ancestor", return_value=None),
        ):
            result = self.publish(target)

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.payload(result)["state"], "unconfirmed")

    @unittest.skipUnless(os.name == "posix", "requires POSIX process groups")
    def test_timeout_stops_transport_descendants_before_return(self) -> None:
        fake_bin = Path(self.temporary_directory.name) / "fake-bin"
        fake_bin.mkdir()
        marker = Path(self.temporary_directory.name) / "late-transport-write"
        fake_git = fake_bin / "git"
        child_code = (
            "import time\n"
            "from pathlib import Path\n"
            "time.sleep(1)\n"
            f"Path({str(marker)!r}).touch()\n"
        )
        fake_git.write_text(
            f"#!{sys.executable}\n"
            "import subprocess\n"
            "import time\n"
            f"subprocess.Popen([{sys.executable!r}, '-c', {child_code!r}])\n"
            "time.sleep(30)\n",
            encoding="utf-8",
        )
        fake_git.chmod(0o755)
        path = os.pathsep.join([str(fake_bin), os.environ.get("PATH", os.defpath)])

        with (
            mock.patch.dict(os.environ, {"PATH": path}),
            mock.patch.object(
                self.module,
                "PUBLICATION_GIT_TIMEOUT_SECONDS",
                0.1,
            ),
            mock.patch.object(
                self.module,
                "PUBLICATION_TERMINATION_GRACE_SECONDS",
                0.1,
            ),
        ):
            result = self.module.run_publication_git(self.repo, ["version"])

        self.assertEqual(result.returncode, 124)
        time.sleep(1.2)
        self.assertFalse(marker.exists())

    def test_publication_bootstrap_ignores_moving_worktree_script(self) -> None:
        committed_script = self.repo / SCRIPT_REPO_PATH
        committed_script.parent.mkdir(parents=True)
        committed_script.write_bytes(SCRIPT_PATH.read_bytes())
        self.git("add", SCRIPT_REPO_PATH)
        self.git("commit", "-m", "Add exact publisher")
        target = self.git("rev-parse", "HEAD").stdout.strip()
        committed_script.write_text(
            "raise SystemExit('worktree script must not run')\n",
            encoding="utf-8",
        )
        self.git("add", SCRIPT_REPO_PATH)
        self.git("commit", "-m", "Advance moving publisher")
        self.assertNotEqual(self.git("rev-parse", "HEAD").stdout.strip(), target)

        result = subprocess.run(
            [
                sys.executable,
                "-I",
                "-c",
                PUBLICATION_BOOTSTRAP_CODE,
                str(self.repo),
                target,
                "publish",
                "--commit",
                target,
                "--branch-ref",
                self.branch_ref,
                "--push-url",
                self.push_url,
                "--json",
            ],
            cwd=self.repo,
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.payload(result)["state"], "invalid_url_rewrite")

    def test_cli_rejects_instead_of_and_push_instead_of_rewrites(self) -> None:
        target = self.git("rev-parse", "HEAD").stdout.strip()
        instead_of_key = f"url.{self.remote.as_uri()}.insteadOf"
        push_instead_of_key = f"url.{self.remote.as_uri()}.pushInsteadOf"
        for key in [instead_of_key, push_instead_of_key]:
            with self.subTest(key=key):
                self.git("config", "--unset-all", instead_of_key, check=False)
                self.git("config", "--unset-all", push_instead_of_key, check=False)
                self.git("config", key, self.push_url)
                result = self.run_queue(
                    "publish",
                    "--repo-root",
                    str(self.repo),
                    "--commit",
                    target,
                    "--branch-ref",
                    self.branch_ref,
                    "--push-url",
                    self.push_url,
                    "--json",
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(
                    self.payload(result)["state"],
                    "invalid_url_rewrite",
                )

    def test_invalid_publication_inputs_fail_before_transport(self) -> None:
        target = self.git("rev-parse", "HEAD").stdout.strip()
        invalid_arguments = [
            ("--commit", "HEAD"),
            ("--branch-ref", "master"),
            ("--push-url", "https://token@github.com/fum-test/fum.git"),
            ("--push-url", "https://example.com/fum-test/fum.git"),
            ("--push-url", "git@github.com:fum-test/fum.git"),
        ]
        module = load_queue_module()
        for option, value in invalid_arguments:
            with self.subTest(option=option, value=value):
                arguments = [
                    "publish",
                    "--repo-root",
                    str(self.repo),
                    "--commit",
                    target,
                    "--branch-ref",
                    self.branch_ref,
                    "--push-url",
                    self.push_url,
                    "--json",
                ]
                arguments[arguments.index(option) + 1] = value
                with (
                    mock.patch.object(module, "run_publication_git") as transport,
                    mock.patch("sys.stdout", new_callable=io.StringIO) as stdout,
                ):
                    code = module.main(arguments)
                self.assertNotEqual(code, 0)
                self.assertTrue(json.loads(stdout.getvalue())["state"].startswith("invalid_"))
                transport.assert_not_called()


class RepositoryIntegrationTests(unittest.TestCase):
    def test_project_configuration_has_no_hooks(self) -> None:
        with CONFIG_PATH.open("rb") as stream:
            config = tomllib.load(stream)
        self.assertNotIn("hooks", config)
        self.assertNotIn("hooks", config.get("features", {}))

    def test_agents_contract_names_the_portable_fifo_protocol(self) -> None:
        agents = AGENTS_PATH.read_text(encoding="utf-8")
        self.assertIn("fum-ocheredj-zadach-git-vetki", agents)
        self.assertIn("CODEX_THREAD_ID", agents)
        for command in [
            "join",
            "wait",
            "wait-until-actionable",
            "ack-head",
            "finish-clean",
            "commit",
        ]:
            self.assertIn(f"`{command}`", agents)
        self.assertIn("порядке атомарной регистрации", agents)
        self.assertIn("не переупорядоч", agents)
        self.assertIn("Субагент", agents)
        self.assertIn("Единственное исключение", agents)
        self.assertIn("не вызывает `join`", agents)
        self.assertIn("HEAD-bootstrap", agents)
        self.assertIn("isolated mode", agents)
        self.assertIn("--no-replace-objects", agents)
        self.assertNotIn("FUM-BRANCH-TASK-GATE", agents)

        skill = SKILL_PATH.read_text(encoding="utf-8")
        self.assertIn("python3 -I -c", skill)
        self.assertIn(HEAD_BOOTSTRAP_CODE, skill)
        self.assertIn("git','--no-replace-objects'", skill)
        self.assertIn("not k.upper().startswith('GIT_')", skill)
        self.assertIn("env=e,timeout=30", skill)
        self.assertIn("'--repo-root',r", skill)
        self.assertIn("Прямой вызов", skill)
        self.assertIn("--timeout-seconds 300", skill)
        self.assertIn("wait-until-actionable", skill)
        for text in (agents, skill):
            self.assertIn("Ручной push пользователя", text)
            self.assertIn("не предоставляет полномочий", text)
            self.assertIn("не входит в обычный протокол `master`", text)
        self.assertIn("Состояние remote не используется как gate готовности", agents)
        self.assertIn("Remote не является условием готовности", skill)
        self.assertIn("отдельного явно разрешённого транспортного действия", skill)

        self.assertIn("один долгоживущий `wait-until-actionable`", agents)
        self.assertIn("не отправляет промежуточные сообщения", agents)

        heartbeat_prompt = HEARTBEAT_PROMPT_PATH.read_text(encoding="utf-8")
        self.assertIn("не является рабочим билетом FIFO-очереди", heartbeat_prompt)
        self.assertIn("вообще не создаёт задачу", heartbeat_prompt)
        self.assertIn("git --no-optional-locks status", heartbeat_prompt)

    def test_old_hook_loader_target_is_a_noop_compatibility_script_only(self) -> None:
        self.assertTrue(COMPATIBILITY_SCRIPT_PATH.is_file())
        self.assertFalse(COMPATIBILITY_SCRIPT_PATH.parents[1].joinpath("SKILL.md").exists())
        result = subprocess.run(
            [
                sys.executable,
                str(COMPATIBILITY_SCRIPT_PATH),
                "hook",
                "--expected-event",
                "UserPromptSubmit",
            ],
            input=json.dumps({"hook_event_name": "UserPromptSubmit"}),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")


class Sha256QueueTests(GitQueueFixture):
    object_format = "sha256"

    @classmethod
    def setUpClass(cls) -> None:
        with tempfile.TemporaryDirectory() as directory:
            probe = subprocess.run(
                ["git", "init", "--object-format=sha256", directory],
                capture_output=True,
                text=True,
                check=False,
            )
        if probe.returncode != 0:
            raise unittest.SkipTest("Git in this environment has no SHA-256 support")

    def test_join_and_atomic_commit_work_with_sha256_object_ids(self) -> None:
        result, owner = self.join("task-a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(str(owner["base_head"])), 64)
        self.stage_change("sha256 task\n")
        committed = self.commit("task-a", str(owner["generation"]), "SHA-256 task")
        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.assertEqual(len(str(self.payload(committed)["new_head"])), 64)


if __name__ == "__main__":
    unittest.main()
