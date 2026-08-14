import importlib.util
import hashlib
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
ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ = (
    "Требования/"
    "✅-обязательное-продолжение-Git-ветки-после-коммита.md"
)
ПРОСТРАНСТВО_КВИТАНЦИЙ_СВЯЗАННЫХ_КОММИТОВ = (
    "refs/fum/квитанции-связанных-коммитов"
)
ПРОСТРАНСТВО_МАРШРУТОВ_ЗАДАЧ = "refs/fum/task-runtime-routes"
ПУТЬ_КОРНЕВОГО_СБРОСА = REPO_ROOT / "sbrositj.sh"
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
ПУТЬ_НАВЫКА_КОМПЛЕКСНОЙ_ПРОВЕРКИ = (
    REPO_ROOT
    / "Инструменты"
    / "fum-kompleksnaya-proverka-repozitoriya"
    / "SKILL.md"
)
ПУТЬ_ИНДЕКСА_КАРТОЧЕК_ЦЕПОЧЕК = (
    REPO_ROOT / "Планирование" / "карточки-цепочек-шагов" / "README.md"
)
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
    формат_объектов = "sha1"

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.repo = Path(self.temporary_directory.name) / "main"
        self.repo.mkdir()

        init = ["git", "init", "-b", "master"]
        if self.формат_объектов != "sha1":
            init.append(f"--object-format={self.формат_объектов}")
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
        timeout: float = 60,
    ) -> subprocess.CompletedProcess[str]:
        среда = dict(os.environ)
        if "--идентификатор-диспетчера" in args:
            позиция = args.index("--идентификатор-диспетчера")
            среда["CODEX_THREAD_ID"] = args[позиция + 1]
        return subprocess.run(
            [sys.executable, str(SCRIPT_PATH), *args],
            cwd=self.repo,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=среда,
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

    def commit(
        self,
        task_id: str,
        generation: str,
        message: str = "Finish task",
        идентификатор_продолжения: str | None = None,
    ):
        аргументы = [
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
        ]
        if идентификатор_продолжения is not None:
            аргументы[-1:-1] = [
                "--идентификатор-продолжения",
                идентификатор_продолжения,
            ]
        return self.run_queue(*аргументы)

    def активировать_обязательное_продолжение(сам) -> None:
        маркер = сам.repo / ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ
        маркер.parent.mkdir(parents=True, exist_ok=True)
        маркер.write_text(
            "# Обязательное продолжение Git-ветки\n",
            encoding="utf-8",
        )
        сам.git("add", ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ)
        сам.git("commit", "-m", "Активировать обязательное продолжение")

    def ссылки_квитанций_связанных_коммитов(сам) -> list[str]:
        вывод = сам.git(
            "for-each-ref",
            "--format=%(refname)",
            f"{ПРОСТРАНСТВО_КВИТАНЦИЙ_СВЯЗАННЫХ_КОММИТОВ}/",
        ).stdout
        return [строка for строка in вывод.splitlines() if строка]

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

    def ссылка_маршрута_задачи(сам, идентификатор_задачи: str) -> str:
        отпечаток = hashlib.sha256(
            идентификатор_задачи.encode("utf-8")
        ).hexdigest()
        return f"{ПРОСТРАНСТВО_МАРШРУТОВ_ЗАДАЧ}/{отпечаток}"

    def прочитать_маршрут_задачи(
        сам,
        идентификатор_задачи: str,
    ) -> tuple[str, dict[str, object]]:
        ссылка = сам.ссылка_маршрута_задачи(идентификатор_задачи)
        объект = сам.git("rev-parse", "--verify", ссылка).stdout.strip()
        нагрузка = json.loads(сам.git("cat-file", "blob", объект).stdout)
        return объект, нагрузка

    def записать_маршрут_задачи(
        сам,
        идентификатор_задачи: str,
        нагрузка: dict[str, object],
    ) -> str:
        байты = (
            json.dumps(
                нагрузка,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n"
        ).encode("utf-8")
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=байты,
            check=True,
            capture_output=True,
        ).stdout.decode("ascii").strip()
        сам.git("update-ref", сам.ссылка_маршрута_задачи(идентификатор_задачи), объект)
        return объект


class QueueContractTests(GitQueueFixture):
    def test_маршрут_задачи_хэширует_точную_идентичность_обычной_очереди(сам) -> None:
        _, допуск = сам.join("task-route-identity")

        _, маршрут = сам.прочитать_маршрут_задачи("task-route-identity")
        идентичность = {
            "schema": "fum.идентичность-ordinary-fifo.1",
            "worktree_id": допуск["worktree_id"],
            "queue_ref": допуск["queue_ref"],
            "branch_ref": допуск["branch_ref"],
        }
        канонические_байты = (
            json.dumps(
                идентичность,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n"
        ).encode("utf-8")
        ожидаемый_хэш = (
            "sha256:" + hashlib.sha256(канонические_байты).hexdigest()
        )

        сам.assertEqual(
            маршрут,
            {
                "schema": "fum.маршрут-задачи-runtime.1",
                "task_id": "task-route-identity",
                "route_kind": "ordinary_fifo",
                "route_identity": ожидаемый_хэш,
            },
        )

    def test_потеря_процесса_после_атомарной_транзакции_не_оставляет_маршрут_без_билета(сам) -> None:
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)
        исходный_запуск = модуль.run_git
        сбой_выдан = False

        class ИскусственнаяПотеряПроцесса(Exception):
            pass

        def запустить_и_потеряться(*аргументы, **именованные_аргументы):
            nonlocal сбой_выдан
            результат = исходный_запуск(*аргументы, **именованные_аргументы)
            команда = аргументы[1]
            ввод = именованные_аргументы.get("input_bytes", b"")
            if (
                not сбой_выдан
                and команда == ["update-ref", "--no-deref", "--stdin"]
                and результат.returncode == 0
                and ПРОСТРАНСТВО_МАРШРУТОВ_ЗАДАЧ.encode("utf-8") in ввод
            ):
                сбой_выдан = True
                raise ИскусственнаяПотеряПроцесса
            return результат

        with mock.patch.object(модуль, "run_git", запустить_и_потеряться):
            with сам.assertRaises(ИскусственнаяПотеряПроцесса):
                модуль.join_queue(контекст, "task-lost-after-route-CAS")

        сам.assertTrue(сбой_выдан)
        объект_очереди = сам.git(
            "rev-parse",
            "--verify",
            контекст.queue_ref,
            check=False,
        )
        сам.assertEqual(объект_очереди.returncode, 0)
        очередь = json.loads(
            сам.git("cat-file", "blob", объект_очереди.stdout.strip()).stdout
        )
        сам.assertIn(
            "task-lost-after-route-CAS",
            [
                *(
                    [очередь["owner"]["task_id"]]
                    if isinstance(очередь["owner"], dict)
                    else []
                ),
                *[билет["task_id"] for билет in очередь["waiting"]],
            ],
        )

    def test_прежние_владелец_и_ожидающий_без_маршрута_безопасно_дозаполняют_его(сам) -> None:
        _, владелец = сам.join("legacy-owner-route")
        сам.join("legacy-waiter-route")

        сам.git("update-ref", "-d", сам.ссылка_маршрута_задачи("legacy-owner-route"))
        повтор, ответ_повтора = сам.join("legacy-owner-route")
        сам.assertEqual(повтор.returncode, 0, повтор.stderr)
        сам.assertEqual(ответ_повтора["generation"], владелец["generation"])
        сам.прочитать_маршрут_задачи("legacy-owner-route")

        сам.git("update-ref", "-d", сам.ссылка_маршрута_задачи("legacy-waiter-route"))
        ожидание, ответ_ожидания = сам.wait("legacy-waiter-route")
        сам.assertNotEqual(ожидание.returncode, 0)
        сам.assertEqual(ответ_ожидания["state"], "waiting")
        сам.прочитать_маршрут_задачи("legacy-waiter-route")

    def test_подтверждение_вершины_не_обходит_несовпавший_маршрут_задачи(сам) -> None:
        сам.join("route-owner-for-ack")
        сам.join("route-waiter-for-ack")
        сам.записать_маршрут_задачи(
            "route-waiter-for-ack",
            {
                "schema": "fum.маршрут-задачи-runtime.1",
                "task_id": "route-waiter-for-ack",
                "route_kind": "worktree_self",
                "route_identity": "sha256:" + "1" * 64,
            },
        )
        до = сам.payload(сам.run_queue("status", "--repo-root", str(сам.repo), "--json"))

        результат = сам.run_queue(
            "ack-head",
            "--repo-root",
            str(сам.repo),
            "--task-id",
            "route-waiter-for-ack",
            "--head",
            сам.git("rev-parse", "HEAD").stdout.strip(),
            "--json",
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(сам.payload(результат)["state"], "task_route_already_reserved")
        после = сам.payload(сам.run_queue("status", "--repo-root", str(сам.repo), "--json"))
        сам.assertEqual(после["queue_oid"], до["queue_oid"])

    def test_допуск_не_обходит_несовпавший_маршрут_задачи(сам) -> None:
        _, владелец = сам.join("route-owner-for-admission")
        сам.join("route-waiter-for-admission")
        завершение = сам.finish_clean(
            "route-owner-for-admission",
            str(владелец["generation"]),
        )
        сам.assertEqual(завершение.returncode, 0, завершение.stderr)
        сам.записать_маршрут_задачи(
            "route-waiter-for-admission",
            {
                "schema": "fum.маршрут-задачи-runtime.1",
                "task_id": "route-waiter-for-admission",
                "route_kind": "worktree_continuation",
                "route_identity": "sha256:" + "2" * 64,
            },
        )
        до = сам.payload(сам.run_queue("status", "--repo-root", str(сам.repo), "--json"))

        ожидание, ответ = сам.wait("route-waiter-for-admission")

        сам.assertNotEqual(ожидание.returncode, 0)
        сам.assertEqual(ответ["state"], "task_route_already_reserved")
        после = сам.payload(сам.run_queue("status", "--repo-root", str(сам.repo), "--json"))
        сам.assertEqual(после["queue_oid"], до["queue_oid"])
        сам.assertIsNone(после["owner"])
        сам.assertEqual(после["waiting"][0]["task_id"], "route-waiter-for-admission")

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

    def test_коммит_хранит_точное_продолжение_и_закрывает_неточный_повтор(
        сам,
    ) -> None:
        _, владелец = сам.join("задача-родитель")
        сам.join("задача-продолжение")
        исходная_вершина = сам.git("rev-parse", "HEAD").stdout.strip()
        сам.stage_change("готово к продолжению\n")

        завершён = сам.commit(
            "задача-родитель",
            str(владелец["generation"]),
            "Передать работу продолжению",
            "задача-продолжение",
        )

        сам.assertEqual(завершён.returncode, 0, завершён.stderr)
        ответ = сам.payload(завершён)
        сам.assertEqual(
            ответ["идентификатор_продолжения"],
            "задача-продолжение",
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сырая_очередь = json.loads(
            сам.git("cat-file", "blob", str(состояние["queue_oid"])).stdout
        )
        сам.assertEqual(
            сырая_очередь["last_completion"]["идентификатор_продолжения"],
            "задача-продолжение",
        )
        сам.assertEqual(
            [билет["task_id"] for билет in состояние["waiting"]],
            ["задача-продолжение"],
        )
        сам.assertEqual(
            состояние["waiting"][0]["acknowledged_head"],
            исходная_вершина,
        )
        вершина_до = сам.git("rev-parse", "HEAD").stdout.strip()
        объект_очереди_до = str(состояние["queue_oid"])

        без_связи = сам.commit(
            "задача-родитель",
            str(владелец["generation"]),
        )
        иное = сам.commit(
            "задача-родитель",
            str(владелец["generation"]),
            идентификатор_продолжения="другая-задача",
        )
        точный = сам.commit(
            "задача-родитель",
            str(владелец["generation"]),
            идентификатор_продолжения="задача-продолжение",
        )

        сам.assertNotEqual(без_связи.returncode, 0)
        сам.assertEqual(сам.payload(без_связи)["state"], "несовпадение_продолжения")
        сам.assertNotEqual(иное.returncode, 0)
        сам.assertEqual(сам.payload(иное)["state"], "несовпадение_продолжения")
        сам.assertEqual(точный.returncode, 0, точный.stderr)
        сам.assertEqual(сам.payload(точный)["new_head"], вершина_до)
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), вершина_до)
        сам.assertEqual(
            сам.git("rev-parse", str(состояние["queue_ref"])).stdout.strip(),
            объект_очереди_до,
        )

    def test_неподтверждённое_продолжение_отклоняется_до_создания_объекта_коммита(
        сам,
    ) -> None:
        _, владелец = сам.join("родитель")
        сам.join("продолжение")
        сам.stage_change("новое дерево\n")

        одинаковое_с_владельцем = сам.commit(
            "родитель",
            str(владелец["generation"]),
            идентификатор_продолжения="родитель",
        )
        нет_билета = сам.commit(
            "родитель",
            str(владелец["generation"]),
            идентификатор_продолжения="незарегистрированная-задача",
        )
        сам.assertEqual(
            сам.payload(одинаковое_с_владельцем)["state"],
            "продолжение_совпадает_с_владельцем",
        )
        сам.assertEqual(сам.payload(нет_билета)["state"], "продолжение_не_ожидает")

        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        ссылка = str(состояние["queue_ref"])
        прежний_объект = str(состояние["queue_oid"])
        запись = json.loads(сам.git("cat-file", "blob", прежний_объект).stdout)
        запись["waiting"][0]["acknowledged_head"] = "0" * len(
            str(владелец["base_head"])
        )
        новый_объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(запись, ensure_ascii=False, sort_keys=True),
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка, новый_объект, прежний_объект)
        вершина_до = сам.git("rev-parse", "HEAD").stdout.strip()
        объекты_до = сам.git(
            "cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype)"
        ).stdout

        неверная_вершина = сам.commit(
            "родитель",
            str(владелец["generation"]),
            идентификатор_продолжения="продолжение",
        )

        сам.assertEqual(
            сам.payload(неверная_вершина)["state"],
            "вершина_продолжения_не_совпадает",
        )
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), вершина_до)
        сам.assertEqual(сам.git("rev-parse", ссылка).stdout.strip(), новый_объект)
        сам.assertEqual(
            сам.git(
                "cat-file",
                "--batch-all-objects",
                "--batch-check=%(objectname) %(objecttype)",
            ).stdout,
            объекты_до,
        )

    def test_промпт_продолжения_связан_с_точной_веткой_и_не_содержит_абсолютных_путей(
        сам,
    ) -> None:
        сам.join("019ff27a-19da-7912-a9c8-6084e3cd2afc")
        состояние_до = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        объекты_до = сам.git(
            "cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype)"
        ).stdout

        результат = сам.run_queue(
            "сформировать-промпт-продолжения",
            "--repo-root",
            str(сам.repo),
            "--task-id",
            "019ff27a-19da-7912-a9c8-6084e3cd2afc",
            "--json",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        ответ = сам.payload(результат)
        сам.assertEqual(ответ["state"], "промпт_продолжения")
        сам.assertEqual(ответ["branch_ref"], "refs/heads/master")
        сам.assertEqual(
            ответ["идентификатор_родительской_задачи"],
            "019ff27a-19da-7912-a9c8-6084e3cd2afc",
        )
        промпт = str(ответ["промпт"])
        for фрагмент in (
            "refs/heads/master",
            "019ff27a-19da-7912-a9c8-6084e3cd2afc",
            "Первым инструментальным действием",
            "join",
            "wait-until-actionable",
            "reload_required",
            "ack-head",
            "AGENTS.md",
            "fum-ocheredj-zadach-git-vetki/SKILL.md",
            "branch-next-step.py",
            "show --repo-root . --json",
            "set_thread_title",
            "card_id",
            "title",
            "FUM-STEP-NNNN — <краткое содержательное название>",
            "Название задачи не доказывает маршрут",
            "not_ready",
            "done",
            "finish-clean",
            "committed",
        ):
            сам.assertIn(фрагмент, промпт)
        сам.assertNotIn(str(сам.repo), промпт)
        сам.assertNotIn("file://", промпт)
        сам.assertNotIn("~/", промпт)
        сам.assertNotIn("hostId", промпт)
        сам.assertNotIn("clientThreadId", промпт)
        сам.assertNotIn("Планирование/карточки-цепочек-шагов/", промпт)
        сам.assertEqual(
            сам.git("rev-parse", str(состояние_до["queue_ref"])).stdout.strip(),
            состояние_до["queue_oid"],
        )
        сам.assertEqual(
            сам.git(
                "cat-file",
                "--batch-all-objects",
                "--batch-check=%(objectname) %(objecttype)",
            ).stdout,
            объекты_до,
        )

    def test_маркер_в_текущей_вершине_машинно_требует_продолжение(сам) -> None:
        сам.активировать_обязательное_продолжение()
        _, владелец = сам.join("родитель")
        сам.stage_change("изменение без продолжения\n")
        вершина_до = сам.git("rev-parse", "HEAD").stdout.strip()
        состояние_до = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        объекты_до = сам.git(
            "cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype)"
        ).stdout

        результат = сам.commit(
            "родитель",
            str(владелец["generation"]),
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(сам.payload(результат)["state"], "продолжение_обязательно")
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), вершина_до)
        сам.assertEqual(
            сам.git("rev-parse", str(состояние_до["queue_ref"])).stdout.strip(),
            состояние_до["queue_oid"],
        )
        сам.assertEqual(
            сам.git(
                "cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype)"
            ).stdout,
            объекты_до,
        )

    def test_связанный_коммит_необратимо_активирует_продолжение(сам) -> None:
        сам.активировать_обязательное_продолжение()
        _, владелец = сам.join("родитель")
        сам.join("ребёнок")
        сам.git("rm", ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ)

        завершён = сам.commit(
            "родитель",
            str(владелец["generation"]),
            "Удалить маркер без ослабления",
            "ребёнок",
        )

        сам.assertEqual(завершён.returncode, 0, завершён.stderr)
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сырая_очередь = json.loads(
            сам.git("cat-file", "blob", str(состояние["queue_oid"])).stdout
        )
        сам.assertIs(сырая_очередь["обязательное_продолжение_активировано"], True)
        сам.assertFalse((сам.repo / ПУТЬ_МАРКЕРА_ОБЯЗАТЕЛЬНОГО_ПРОДОЛЖЕНИЯ).exists())

        _, ожидание = сам.wait("ребёнок")
        сам.assertEqual(ожидание["state"], "reload_required")
        сам.ack_head("ребёнок")
        _, допущен = сам.wait("ребёнок")
        сам.assertEqual(допущен["state"], "admitted")
        сам.stage_change("маркера нет, обязанность есть\n")

        обход = сам.commit(
            "ребёнок",
            str(допущен["generation"]),
        )

        сам.assertNotEqual(обход.returncode, 0)
        сам.assertEqual(сам.payload(обход)["state"], "продолжение_обязательно")

    def test_квитанция_даёт_точный_повтор_после_чистого_завершения_ребёнка(сам) -> None:
        _, владелец = сам.join("родитель")
        сам.join("ребёнок")
        исходная_вершина = сам.git("rev-parse", "HEAD").stdout.strip()
        сам.stage_change("коммит с квитанцией\n")
        завершён = сам.commit(
            "родитель",
            str(владелец["generation"]),
            "Записать неизменяемую квитанцию",
            "ребёнок",
        )
        сам.assertEqual(завершён.returncode, 0, завершён.stderr)
        ответ_коммита = сам.payload(завершён)
        ссылки = сам.ссылки_квитанций_связанных_коммитов()
        сам.assertEqual(ссылки, [ответ_коммита["ссылка_квитанции"]])
        объект_квитанции = сам.git("rev-parse", ссылки[0]).stdout.strip()
        квитанция = json.loads(сам.git("cat-file", "blob", объект_квитанции).stdout)
        сам.assertEqual(
            квитанция,
            {
                "схема": "fum.квитанция-связанного-коммита.1",
                "идентификатор_рабочего_дерева": ответ_коммита["worktree_id"],
                "ссылка_ветки": "refs/heads/master",
                "идентификатор_задачи": "родитель",
                "поколение": владелец["generation"],
                "исходная_вершина": исходная_вершина,
                "новая_вершина": ответ_коммита["new_head"],
                "идентификатор_продолжения": "ребёнок",
            },
        )

        _, ожидание = сам.wait("ребёнок")
        сам.assertEqual(ожидание["state"], "reload_required")
        сам.ack_head("ребёнок")
        _, допущен = сам.wait("ребёнок")
        чисто = сам.finish_clean("ребёнок", str(допущен["generation"]))
        сам.assertEqual(чисто.returncode, 0, чисто.stderr)

        точный = сам.commit(
            "родитель",
            str(владелец["generation"]),
            идентификатор_продолжения="ребёнок",
        )
        иной = сам.commit(
            "родитель",
            str(владелец["generation"]),
            идентификатор_продолжения="другой-ребёнок",
        )
        без_связи = сам.commit(
            "родитель",
            str(владелец["generation"]),
        )

        сам.assertEqual(точный.returncode, 0, точный.stderr)
        сам.assertEqual(сам.payload(точный)["new_head"], ответ_коммита["new_head"])
        сам.assertEqual(сам.payload(точный)["ссылка_квитанции"], ссылки[0])
        сам.assertEqual(сам.payload(иной)["state"], "несовпадение_продолжения")
        сам.assertEqual(сам.payload(без_связи)["state"], "несовпадение_продолжения")
        сам.assertEqual(сам.git("rev-parse", ссылки[0]).stdout.strip(), объект_квитанции)

    def test_квитанция_родителя_переживает_связанный_коммит_ребёнка_и_требует_объект_очереди(
        сам,
    ) -> None:
        _, родитель = сам.join("родитель")
        сам.join("ребёнок")
        сам.stage_change("первый связанный коммит\n")
        первый = сам.commit(
            "родитель",
            str(родитель["generation"]),
            "Передать ребёнку",
            "ребёнок",
        )
        сам.assertEqual(первый.returncode, 0, первый.stderr)
        первый_ответ = сам.payload(первый)

        _, ожидание = сам.wait("ребёнок")
        сам.assertEqual(ожидание["state"], "reload_required")
        сам.ack_head("ребёнок")
        _, ребёнок = сам.wait("ребёнок")
        сам.assertEqual(ребёнок["state"], "admitted")
        сам.join("внук")
        сам.stage_change("второй связанный коммит\n")
        второй = сам.commit(
            "ребёнок",
            str(ребёнок["generation"]),
            "Передать внуку",
            "внук",
        )
        сам.assertEqual(второй.returncode, 0, второй.stderr)
        второй_ответ = сам.payload(второй)
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )

        точный = сам.commit(
            "родитель",
            str(родитель["generation"]),
            идентификатор_продолжения="ребёнок",
        )
        иной = сам.commit(
            "родитель",
            str(родитель["generation"]),
            идентификатор_продолжения="другая-задача",
        )
        без_связи = сам.commit(
            "родитель",
            str(родитель["generation"]),
        )

        сам.assertEqual(точный.returncode, 0, точный.stderr)
        точный_ответ = сам.payload(точный)
        сам.assertEqual(точный_ответ["new_head"], первый_ответ["new_head"])
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), второй_ответ["new_head"])
        сам.assertEqual(точный_ответ["queue_oid"], состояние["queue_oid"])
        сам.assertRegex(
            str(точный_ответ["queue_oid"]),
            rf"\A[0-9a-f]{{{len(str(второй_ответ['new_head']))}}}\Z",
        )
        сам.assertEqual(сам.payload(иной)["state"], "несовпадение_продолжения")
        сам.assertEqual(сам.payload(без_связи)["state"], "несовпадение_продолжения")

        сам.git(
            "update-ref",
            "-d",
            str(состояние["queue_ref"]),
            str(состояние["queue_oid"]),
        )
        без_объекта_очереди = сам.commit(
            "родитель",
            str(родитель["generation"]),
            идентификатор_продолжения="ребёнок",
        )
        сам.assertNotEqual(без_объекта_очереди.returncode, 0)
        сам.assertEqual(
            сам.payload(без_объекта_очереди)["state"],
            "отсутствует_объект_очереди_связанного_коммита",
        )

    def test_более_ранний_билет_не_мешает_точно_связать_позднее_продолжение(сам) -> None:
        _, владелец = сам.join("родитель")
        сам.join("более-ранняя-задача")
        сам.join("точное-продолжение")
        сам.stage_change("не переупорядочивать FIFO\n")

        завершён = сам.commit(
            "родитель",
            str(владелец["generation"]),
            "Связать позднее продолжение",
            "точное-продолжение",
        )

        сам.assertEqual(завершён.returncode, 0, завершён.stderr)
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(
            [билет["task_id"] for билет in состояние["waiting"]],
            ["более-ранняя-задача", "точное-продолжение"],
        )
        сам.assertEqual(
            json.loads(
                сам.git(
                    "cat-file",
                    "blob",
                    сам.git(
                        "rev-parse",
                        сам.ссылки_квитанций_связанных_коммитов()[0],
                    ).stdout.strip(),
                ).stdout
            )["идентификатор_продолжения"],
            "точное-продолжение",
        )
        _, ранняя = сам.wait("более-ранняя-задача")
        сам.assertEqual(ранняя["state"], "reload_required")
        сам.ack_head("более-ранняя-задача")
        _, допущена = сам.wait("более-ранняя-задача")
        сам.assertEqual(допущена["state"], "admitted")
        _, поздняя = сам.wait("точное-продолжение")
        сам.assertEqual(поздняя["state"], "waiting")

    def test_связанный_коммит_не_касается_устаревших_переходов(сам) -> None:
        модуль = load_queue_module()
        _, владелец = сам.join("родитель")
        сам.join("ребёнок")
        сам.stage_change("без диспетчерского контура\n")
        контекст = модуль.resolve_context(сам.repo)
        запрет = AssertionError("Устаревший переход не должен вызываться")

        with (
            mock.patch.object(
                модуль,
                "прочитать_долговечное_завершение_следующего_шага",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "потребовать_сохранность_незавершённого_автозапуска",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "подготовить_переход_журнала_завершений",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "подготовить_переход_передачи_аналитики",
                side_effect=запрет,
            ),
        ):
            код, ответ = модуль.atomic_commit_and_handoff(
                контекст,
                "родитель",
                str(владелец["generation"]),
                "Передать без устаревших переходов",
                "ребёнок",
            )

        сам.assertEqual(код, 0)
        сам.assertEqual(ответ["state"], "committed")

    def test_активное_чистое_завершение_не_касается_устаревших_переходов(
        сам,
    ) -> None:
        модуль = load_queue_module()
        сам.активировать_обязательное_продолжение()
        _, владелец = сам.join("владелец")
        контекст = модуль.resolve_context(сам.repo)
        запрет = AssertionError("Устаревший переход не должен вызываться")

        with (
            mock.patch.object(
                модуль,
                "прочитать_долговечное_чистое_завершение_аналитики",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "прочитать_долговечное_чистое_завершение_следующего_шага",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "потребовать_сохранность_незавершённого_автозапуска",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "подготовить_переход_чистого_завершения_аналитики",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "подготовить_переход_чистого_завершения_следующего_шага",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "команды_перехода_чистого_завершения_аналитики",
                side_effect=запрет,
            ),
            mock.patch.object(
                модуль,
                "команды_перехода_чистого_завершения_следующего_шага",
                side_effect=запрет,
            ),
        ):
            код, ответ = модуль.finish_clean_and_handoff(
                контекст,
                "владелец",
                str(владелец["generation"]),
            )
            код_повтора, ответ_повтора = модуль.finish_clean_and_handoff(
                контекст,
                "владелец",
                str(владелец["generation"]),
            )

        сам.assertEqual(код, 0)
        сам.assertEqual(ответ["state"], "finished_clean")
        сам.assertEqual(код_повтора, 0)
        сам.assertEqual(ответ_повтора, ответ)

    def test_отмена_продолжения_в_гонке_не_двигает_ветку_и_не_создаёт_квитанцию(сам) -> None:
        модуль = load_queue_module()
        _, владелец = сам.join("родитель")
        _, билет = сам.join("ребёнок")
        сам.stage_change("гонка после точной проверки\n")
        контекст = модуль.resolve_context(сам.repo)
        исходная_запись = модуль.write_state_blob
        вершина_до = сам.git("rev-parse", "HEAD").stdout.strip()
        объекты_до = {
            строка.split()[0]
            for строка in сам.git(
                "cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype)"
            ).stdout.splitlines()
        }
        гонка = False

        def записать_и_отменить(контекст_очереди, состояние):
            nonlocal гонка
            объект = исходная_запись(контекст_очереди, состояние)
            завершение = состояние.get("last_completion")
            if (
                not гонка
                and состояние.get("owner") is None
                and isinstance(завершение, dict)
                and завершение.get("kind") == "committed"
            ):
                гонка = True
                текущее, текущий_объект = модуль.read_state(контекст_очереди)
                отменённое = json.loads(json.dumps(текущее))
                отменённое["waiting"] = []
                отменённое["updated_at"] = модуль.utc_values()[0]
                объект_отмены = исходная_запись(контекст_очереди, отменённое)
                сам.git(
                    "update-ref",
                    контекст_очереди.queue_ref,
                    объект_отмены,
                    str(текущий_объект),
                )
            return объект

        with mock.patch.object(модуль, "write_state_blob", записать_и_отменить):
            with сам.assertRaises(модуль.QueueError) as исключение:
                модуль.atomic_commit_and_handoff(
                    контекст,
                    "родитель",
                    str(владелец["generation"]),
                    "Гонка отмены",
                    "ребёнок",
                )

        сам.assertEqual(исключение.exception.state, "продолжение_не_ожидает")
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), вершина_до)
        сам.assertEqual(сам.ссылки_квитанций_связанных_коммитов(), [])
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["owner"]["task_id"], "родитель")
        сам.assertEqual(состояние["waiting"], [])
        объекты_после = {
            строка.split()[0]
            for строка in сам.git(
                "cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype)"
            ).stdout.splitlines()
        }
        новые_коммиты = [
            объект
            for объект in объекты_после - объекты_до
            if сам.git("cat-file", "-t", объект).stdout.strip() == "commit"
        ]
        сам.assertEqual(len(новые_коммиты), 1)
        достижимые = {
            строка.split()[0]
            for строка in сам.git("rev-list", "--objects", "--all").stdout.splitlines()
        }
        сам.assertNotIn(новые_коммиты[0], достижимые)
        сам.assertEqual(билет["task_id"], "ребёнок")

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
                timeout=60,
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
            result = waiting.result(timeout=60)

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
                timeout=60,
            )
            time.sleep(0.15)

            self.assertFalse(waiting.done())
            finished = self.finish_clean("task-a", str(owner["generation"]))
            self.assertEqual(finished.returncode, 0, finished.stderr)
            result = waiting.result(timeout=60)

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


class ТестыШтатногоСбросаОчереди(GitQueueFixture):
    def записать_резервацию_возобновления(
        сам,
        состояние_возобновления: str,
        *,
        удалить_поле: str | None = None,
        удалить_поле_наблюдения: str | None = None,
        логическое_поле: str | None = None,
    ) -> str:
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка = (
            "refs/fum/резервации-запусков-автоматизаций/"
            f"{состояние['worktree_id']}/{хэш_ветки}/{'9' * 64}"
        )
        подтверждено = (
            "2026-08-08T16:00:10Z"
            if состояние_возобновления == "подтверждено_исполнителем"
            else None
        )
        возобновление = {
            "версия_схемы": 1,
            "поколение": 1,
            "состояние": состояние_возобновления,
            "номер_попытки": 1,
            "предел_попыток": 1,
            "не_раньше": "2026-08-08T16:00:00Z",
            "ограждено": "2026-08-08T16:00:00Z",
            "подтверждено": подтверждено,
            "ключ": "sha256:" + "1" * 64,
            "хэш_сообщения": "sha256:" + "2" * 64,
            "причина": "не_определена",
            "класс_наблюдения": "разрыв_потока_ответа",
            "ссылка_резервации": ссылка,
            "исходный_объект_резервации": "3" * 40,
            "ссылка_очереди": str(состояние["queue_ref"]),
            "объект_очереди": "4" * 40,
            "ссылка_претензии": (
                "refs/fum/worktree-next-step-claims/"
                f"{состояние['worktree_id']}/{хэш_ветки}"
            ),
            "объект_претензии": "5" * 40,
            "наблюдение": {
                "версия_схемы_среды": 1,
                "состояние_задачи": "idle",
                "идентификатор_хода": "ход-разрыва",
                "начат": 1_786_200_000.0,
                "завершён": 1_786_200_010.0,
                "длительность_миллисекунд": 10_000,
                "сообщение_ошибки": (
                    "stream disconnected before completion: error sending "
                    "request for url "
                    "(https://chatgpt.com/backend-api/codex/responses)"
                ),
            },
            "конверт": {
                "версия_схемы": 1,
                "ссылка_ветки": состояние["branch_ref"],
                "вершина_выбора": сам.git("rev-parse", "HEAD").stdout.strip(),
                "идентификатор_задания": "master.next-step",
                "поколение_спецификации": 1,
                "поколение_реестра": 1,
                "ключ_запуска": "sha256:" + "6" * 64,
                "идентификатор_попытки": "попытка-возобновления",
                "идентификатор_задачи": "возобновляемая-задача",
                "поколение_очереди": "поколение-очереди",
                "ключ_возобновления": "sha256:" + "1" * 64,
            },
        }
        if удалить_поле is not None:
            возобновление.pop(удалить_поле)
        if удалить_поле_наблюдения is not None:
            возобновление["наблюдение"].pop(удалить_поле_наблюдения)
        if логическое_поле is not None:
            возобновление[логическое_поле] = True
        резервация = {
            "версия_схемы": 4,
            "фаза": "задача_создана",
            "task_id": "возобновляемая-задача",
            "идентификатор_созданной_задачи": "возобновляемая-задача",
            "свидетельство_среды": {
                "вид": "threadId",
                "threadId": "возобновляемая-задача",
                "hostId": "host-1",
            },
            "возобновление": возобновление,
        }
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(резервация, ensure_ascii=False) + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка, объект)
        return ссылка

    def план_сброса(
        сам,
        идентификатор_диспетчера: str = "dispatcher-task",
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        результат = сам.run_queue(
            "план-сброса",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--json",
        )
        return результат, сам.payload(результат)

    def подготовить_сброс(
        сам,
        план: dict[str, object],
        идентификатор_диспетчера: str = "dispatcher-task",
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        результат = сам.run_queue(
            "подготовить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--ожидаемая-вершина",
            str(план["целевая_вершина"]),
            "--ожидаемый-объект-очереди",
            str(план["объект_очереди"]),
            "--подтверждение",
            str(план["подтверждение"]),
            "--json",
        )
        return результат, сам.payload(результат)

    def подтвердить_остановку(
        сам,
        идентификатор_сброса: str,
        *неактивные_задачи: str,
        идентификатор_диспетчера: str = "dispatcher-task",
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        аргументы = [
            "подтвердить-остановку-сессий",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
        ]
        for идентификатор_задачи in неактивные_задачи:
            аргументы.extend(("--неактивная-задача", идентификатор_задачи))
        аргументы.append("--json")
        результат = сам.run_queue(*аргументы)
        return результат, сам.payload(результат)

    def test_план_и_подготовка_фиксируют_точную_границу_сброса(сам) -> None:
        сам.join("owner-task")
        сам.join("waiter-task")
        (сам.repo / "tracked.txt").write_text("изменено\n", encoding="utf-8")
        (сам.repo / ".obsidian" / "graph.json").write_text(
            '{"zoom": 2}\n',
            encoding="utf-8",
        )
        (сам.repo / "untracked.txt").write_text("новое\n", encoding="utf-8")
        снимок = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )

        результат_плана, план = сам.план_сброса()

        сам.assertEqual(результат_плана.returncode, 0, результат_плана.stderr)
        сам.assertEqual(
            план["целевая_вершина"],
            сам.git("rev-parse", "HEAD").stdout.strip(),
        )
        сам.assertEqual(план["объект_очереди"], снимок["queue_oid"])
        сам.assertEqual(план["участники"], ["owner-task", "waiter-task"])
        сам.assertEqual(
            план["изменённые_пути"],
            [".obsidian/graph.json", "tracked.txt", "untracked.txt"],
        )

        подготовка, подготовлено = сам.подготовить_сброс(план)

        сам.assertEqual(
            подготовка.returncode,
            0,
            подготовка.stdout + подготовка.stderr,
        )
        сам.assertEqual(подготовлено["состояние"], "подготовлен")
        сам.assertEqual(
            подготовлено["идентификатор_сброса"],
            план["идентификатор_сброса"],
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["state"], "resetting")
        сам.assertEqual(состояние["фаза"], "подготовлен")

        объект_сброса = str(состояние["queue_oid"])
        запись = json.loads(сам.git("cat-file", "blob", объект_сброса).stdout)
        сам.assertEqual(запись["схема"], "fum.сброс-состояния-FIFO.1")
        сам.assertEqual(
            запись["исходный_объект_очереди"],
            снимок["queue_oid"],
        )

        заблокирован = сам.run_queue(
            "join",
            "--repo-root",
            str(сам.repo),
            "--task-id",
            "late-task",
            "--json",
        )
        сам.assertNotEqual(заблокирован.returncode, 0)
        сам.assertEqual(сам.payload(заблокирован)["state"], "reset_in_progress")
        сам.assertEqual(
            сам.git("rev-parse", str(состояние["queue_ref"])).stdout.strip(),
            объект_сброса,
        )

    def test_план_отклоняет_самодекларированный_идентификатор_диспетчера(
        сам,
    ) -> None:
        среда = dict(os.environ)
        среда.pop("CODEX_THREAD_ID", None)

        результат = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "план-сброса",
                "--repo-root",
                str(сам.repo),
                "--идентификатор-диспетчера",
                "задача-диспетчера",
                "--json",
            ],
            cwd=сам.repo,
            check=False,
            capture_output=True,
            text=True,
            env=среда,
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(
            сам.payload(результат)["state"],
            "dispatcher_identity_mismatch",
        )

    def test_отмена_до_остановки_восстанавливает_очередь_и_не_трогает_файлы(
        сам,
    ) -> None:
        сам.join("owner-task")
        (сам.repo / "tracked.txt").write_text("не терять\n", encoding="utf-8")
        _, план = сам.план_сброса()
        _, подготовлено = сам.подготовить_сброс(план)

        отмена = сам.run_queue(
            "отменить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            "dispatcher-task",
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertEqual(отмена.returncode, 0, отмена.stderr)
        сам.assertEqual(сам.payload(отмена)["состояние"], "отменён")
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["queue_oid"], план["объект_очереди"])
        сам.assertEqual(
            (сам.repo / "tracked.txt").read_text(encoding="utf-8"),
            "не терять\n",
        )

    def test_остановка_подтверждается_только_точным_множеством_участников(
        сам,
    ) -> None:
        сам.join("owner-task")
        сам.join("waiter-task")
        _, план = сам.план_сброса()
        _, подготовлено = сам.подготовить_сброс(план)
        состояние_до = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )

        неполное, неполный_ответ = сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "owner-task",
        )

        сам.assertNotEqual(неполное.returncode, 0)
        сам.assertEqual(неполный_ответ["state"], "session_set_mismatch")
        состояние_после = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние_после["queue_oid"], состояние_до["queue_oid"])

        полное, полный_ответ = сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "waiter-task",
            "owner-task",
        )
        сам.assertEqual(полное.returncode, 0, полное.stderr)
        сам.assertEqual(полный_ответ["состояние"], "сессии_остановлены")

        отмена = сам.run_queue(
            "отменить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            "dispatcher-task",
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )
        сам.assertNotEqual(отмена.returncode, 0)

    def test_задача_диспетчера_исключается_из_остановки_только_по_идентификатору(сам) -> None:
        сам.join("dispatcher-task")
        сам.join("other-task")
        _, план = сам.план_сброса()
        _, подготовлено = сам.подготовить_сброс(план)

        результат, ответ = сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "other-task",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(ответ["состояние"], "сессии_остановлены")

    def test_применение_возвращает_рабочую_копию_к_вершине_и_обнуляет_очередь(сам) -> None:
        (сам.repo / ".gitignore").write_text("ignored.tmp\n", encoding="utf-8")
        сам.git("add", ".gitignore")
        сам.git("commit", "-m", "Add ignored fixture")
        исходная_вершина = сам.git("rev-parse", "HEAD").stdout.strip()
        сам.join("owner-task")
        сам.join("waiter-task")
        сам.stage_change("staged\n")
        (сам.repo / "tracked.txt").write_text("unstaged after staged\n", encoding="utf-8")
        (сам.repo / ".obsidian" / "graph.json").write_text(
            '{"zoom": 9}\n',
            encoding="utf-8",
        )
        (сам.repo / "untracked.txt").write_text("remove\n", encoding="utf-8")
        (сам.repo / "ignored.tmp").write_text("preserve\n", encoding="utf-8")
        _, план = сам.план_сброса()
        _, подготовлено = сам.подготовить_сброс(план)
        сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "owner-task",
            "waiter-task",
        )

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            "dispatcher-task",
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertEqual(применение.returncode, 0, применение.stderr)
        сам.assertEqual(сам.payload(применение)["состояние"], "сброшено")
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), исходная_вершина)
        сам.assertEqual(
            (сам.repo / "tracked.txt").read_text(encoding="utf-8"),
            "initial\n",
        )
        сам.assertEqual(
            (сам.repo / ".obsidian" / "graph.json").read_text(encoding="utf-8"),
            '{"zoom": 1}\n',
        )
        сам.assertFalse((сам.repo / "untracked.txt").exists())
        сам.assertTrue((сам.repo / "ignored.tmp").exists())
        сам.assertEqual(сам.git("status", "--short").stdout, "")

        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["state"], "idle")
        сам.assertIsNone(состояние["owner"])
        сам.assertEqual(состояние["waiting"], [])
        сам.assertEqual(состояние["next_seq"], 3)
        очередь = json.loads(
            сам.git("cat-file", "blob", str(состояние["queue_oid"])).stdout
        )
        сам.assertEqual(очередь["last_completion"]["kind"], "reset")
        сам.assertEqual(
            очередь["last_completion"]["generation"],
            подготовлено["идентификатор_сброса"],
        )

    def test_квитанция_сохраняет_идемпотентность_после_нового_завершения(
        сам,
    ) -> None:
        сам.join("owner-task")
        _, план = сам.план_сброса()
        _, подготовлено = сам.подготовить_сброс(план)
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "owner-task",
        )
        первое_применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            "dispatcher-task",
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )
        сам.assertEqual(первое_применение.returncode, 0, первое_применение.stderr)
        _, новый_владелец = сам.join("later-task")
        завершение = сам.finish_clean(
            "later-task",
            str(новый_владелец["generation"]),
        )
        сам.assertEqual(завершение.returncode, 0, завершение.stderr)
        сам.git("reflog", "expire", "--expire=now", "--all")
        сам.git("gc", "--prune=now")

        повтор = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            "dispatcher-task",
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertEqual(повтор.returncode, 0, повтор.stderr)
        сам.assertEqual(сам.payload(повтор)["состояние"], "сброшено")
        сам.assertRegex(
            сам.git(
                "for-each-ref",
                "--format=%(objectname)",
                "refs/fum/квитанции-сброса-состояния-FIFO",
            ).stdout.strip(),
            r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$",
        )

    def test_сдвиг_ветки_после_ограждения_запрещает_очистку(сам) -> None:
        сам.join("owner-task")
        (сам.repo / "tracked.txt").write_text("сохранить при отказе\n", encoding="utf-8")
        _, план = сам.план_сброса()
        _, подготовлено = сам.подготовить_сброс(план)
        сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "owner-task",
        )
        сам.git("commit", "--allow-empty", "-m", "Move branch behind reset fence")

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            "dispatcher-task",
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertNotEqual(применение.returncode, 0)
        сам.assertEqual(сам.payload(применение)["state"], "head_changed")
        сам.assertEqual(
            (сам.repo / "tracked.txt").read_text(encoding="utf-8"),
            "сохранить при отказе\n",
        )

    def test_применение_не_отматывает_конкурентный_коммит_после_атомарной_смены_фазы(
        сам,
    ) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        (сам.repo / "tracked.txt").write_text(
            "изменение владельца\n",
            encoding="utf-8",
        )
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)
        исходная_замена = модуль.заменить_запись_очереди_с_проверкой_ветки
        конкурентная_вершина: str | None = None
        фаза_переведена = False

        def заменить_и_сдвинуть_ветку(*аргументы, **именованные_аргументы):
            nonlocal конкурентная_вершина, фаза_переведена
            результат = исходная_замена(*аргументы, **именованные_аргументы)
            if результат and not фаза_переведена:
                фаза_переведена = True
                сам.git(
                    "commit",
                    "--allow-empty",
                    "-m",
                    "Concurrent commit after reset phase CAS",
                )
                конкурентная_вершина = сам.git(
                    "rev-parse",
                    "HEAD",
                ).stdout.strip()
            return результат

        ошибка: object | None = None
        with mock.patch.object(
            модуль,
            "заменить_запись_очереди_с_проверкой_ветки",
            заменить_и_сдвинуть_ветку,
        ):
            try:
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    str(подготовлено["идентификатор_сброса"]),
                )
            except модуль.QueueError as исключение:
                ошибка = исключение

        сам.assertIsNotNone(конкурентная_вершина)
        сам.assertEqual(
            сам.git("rev-parse", "HEAD").stdout.strip(),
            конкурентная_вершина,
        )
        сам.assertIsNotNone(ошибка)
        сам.assertEqual(ошибка.state, "head_changed")

    def test_повтор_очистки_не_удаляет_изменённый_после_падения_файл(
        сам,
    ) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        неотслеживаемый = сам.repo / "planned-untracked.txt"
        неотслеживаемый.write_text("подтверждённые байты\n", encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)

        with mock.patch.object(
            модуль,
            "удалить_подтверждённые_неотслеживаемые_пути",
            side_effect=RuntimeError("имитация падения перед удалением"),
        ):
            with сам.assertRaisesRegex(RuntimeError, "имитация падения"):
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    идентификатор_сброса,
                )

        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["фаза"], "очистка_рабочей_копии")
        неотслеживаемый.write_text("новые неподтверждённые байты\n", encoding="utf-8")

        повтор = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertNotEqual(повтор.returncode, 0)
        сам.assertEqual(сам.payload(повтор)["state"], "reset_plan_changed")
        сам.assertEqual(
            неотслеживаемый.read_text(encoding="utf-8"),
            "новые неподтверждённые байты\n",
        )

    def test_каждый_неотслеживаемый_путь_повторно_проверяется_перед_удалением(
        сам,
    ) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        первый = сам.repo / "а-первый.txt"
        второй = сам.repo / "б-второй.txt"
        первый.write_text("первые байты\n", encoding="utf-8")
        второй.write_text("вторые байты\n", encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)
        исходный_запуск_команды_репозитория = модуль.run_git
        первый_удалён = False

        def изменить_второй_после_первого(
            корень,
            аргументы,
            **именованные_аргументы,
        ):
            nonlocal первый_удалён
            результат = исходный_запуск_команды_репозитория(
                корень,
                аргументы,
                **именованные_аргументы,
            )
            if аргументы and аргументы[0] == "clean" and not первый_удалён:
                первый_удалён = True
                второй.write_text(
                    "новые неподтверждённые байты\n",
                    encoding="utf-8",
                )
            return результат

        with mock.patch.object(
            модуль,
            "run_git",
            side_effect=изменить_второй_после_первого,
        ):
            with сам.assertRaises(модуль.QueueError) as ошибка:
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    идентификатор_сброса,
                )

        сам.assertEqual(ошибка.exception.state, "reset_plan_changed")
        сам.assertFalse(первый.exists())
        сам.assertEqual(
            второй.read_text(encoding="utf-8"),
            "новые неподтверждённые байты\n",
        )

    def test_восстановление_дерева_принимает_плановый_неотслеживаемый_файл_вместо_целевого_каталога(
        сам,
    ) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        каталог = сам.repo / "целевой-каталог"
        каталог.mkdir()
        целевой = каталог / "файл.txt"
        целевой.write_text("цель\n", encoding="utf-8")
        сам.git("add", "--", "целевой-каталог/файл.txt")
        сам.git("commit", "-m", "Добавить целевой каталог")
        сам.join("задача-владельца")
        целевой.unlink()
        каталог.rmdir()
        каталог.write_text("плановый untracked-файл\n", encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertEqual(применение.returncode, 0, применение.stderr)
        сам.assertTrue(каталог.is_dir())
        сам.assertEqual(целевой.read_text(encoding="utf-8"), "цель\n")

    def test_восстановление_дерева_не_обходит_целевую_ссылку_при_удалении_неотслеживаемого(
        сам,
    ) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        внешний_каталог = сам.repo.parent / "внешний-каталог"
        внешний_каталог.mkdir()
        внешний_файл = внешний_каталог / "файл.txt"
        внешний_файл.write_text("внешние байты\n", encoding="utf-8")
        ссылка = сам.repo / "целевая-ссылка"
        ссылка.symlink_to("../внешний-каталог", target_is_directory=True)
        сам.git("add", "--", "целевая-ссылка")
        сам.git("commit", "-m", "Добавить целевую ссылку")
        сам.join("задача-владельца")
        ссылка.unlink()
        ссылка.mkdir()
        (ссылка / "файл.txt").write_text("плановые байты\n", encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertEqual(применение.returncode, 0, применение.stderr)
        сам.assertTrue(ссылка.is_symlink())
        сам.assertEqual(
            внешний_файл.read_text(encoding="utf-8"),
            "внешние байты\n",
        )

    def test_повтор_после_восстановления_дерева_не_обходит_целевую_ссылку_для_отслеживаемого_потомка(
        сам,
    ) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        внешний_каталог = сам.repo.parent / "внешний-каталог"
        внешний_каталог.mkdir()
        внешний_файл = внешний_каталог / "файл.txt"
        внешний_файл.write_text("внешние байты\n", encoding="utf-8")
        ссылка = сам.repo / "целевая-ссылка"
        ссылка.symlink_to("../внешний-каталог", target_is_directory=True)
        сам.git("add", "--", "целевая-ссылка")
        сам.git("commit", "-m", "Добавить целевую ссылку")
        сам.join("задача-владельца")
        ссылка.unlink()
        ссылка.mkdir()
        (ссылка / "файл.txt").write_text("плановые байты\n", encoding="utf-8")
        сам.git("add", "-A", "--", "целевая-ссылка")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)
        исходный_запуск_команды_репозитория = модуль.run_git

        def упасть_после_восстановления_дерева(корень, аргументы, **именованные_аргументы):
            результат = исходный_запуск_команды_репозитория(
                корень,
                аргументы,
                **именованные_аргументы,
            )
            if аргументы and аргументы[0] == "read-tree":
                raise RuntimeError("имитация падения после read-tree")
            return результат

        with mock.patch.object(
            модуль,
            "run_git",
            side_effect=упасть_после_восстановления_дерева,
        ):
            with сам.assertRaisesRegex(RuntimeError, "после read-tree"):
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    идентификатор_сброса,
                )
        сам.assertTrue(ссылка.is_symlink())

        повтор = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertEqual(повтор.returncode, 0, повтор.stderr)
        сам.assertEqual(
            внешний_файл.read_text(encoding="utf-8"),
            "внешние байты\n",
        )

    def test_план_блокирует_переход_ссылки_на_подмодуль_в_обычный_файл(сам) -> None:
        вершина = сам.git("rev-parse", "HEAD").stdout.strip()
        сам.git(
            "update-index",
            "--add",
            "--cacheinfo",
            "160000",
            вершина,
            "модуль",
        )
        сам.git("commit", "-m", "Добавить gitlink")
        сам.git("rm", "--cached", "--", "модуль")
        путь = сам.repo / "модуль"
        путь.write_text("обычный файл\n", encoding="utf-8")
        сам.git("add", "--", "модуль")

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "nested_repository_dirty")
        сам.assertEqual(путь.read_text(encoding="utf-8"), "обычный файл\n")

    def test_повтор_после_перехода_фазы_не_стирает_новое_отслеживаемое_изменение(
        сам,
    ) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        отслеживаемый = сам.repo / "tracked.txt"
        отслеживаемый.write_text(
            "содержимое из подтверждённого плана\n",
            encoding="utf-8",
        )
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)
        исходный_запуск_команды_репозитория = модуль.run_git

        def упасть_до_восстановления_дерева(корень, аргументы, **именованные_аргументы):
            if аргументы and аргументы[0] == "read-tree":
                raise RuntimeError("имитация падения до очистки tracked")
            return исходный_запуск_команды_репозитория(
                корень,
                аргументы,
                **именованные_аргументы,
            )

        with mock.patch.object(
            модуль,
            "run_git",
            side_effect=упасть_до_восстановления_дерева,
        ):
            with сам.assertRaisesRegex(
                RuntimeError,
                "имитация падения до очистки tracked",
            ):
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    идентификатор_сброса,
                )

        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["фаза"], "очистка_рабочей_копии")
        отслеживаемый.write_text(
            "новые неподтверждённые tracked-байты\n",
            encoding="utf-8",
        )
        сам.git("add", "--", "tracked.txt")

        повтор = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertNotEqual(повтор.returncode, 0)
        сам.assertEqual(сам.payload(повтор)["state"], "reset_plan_changed")
        сам.assertEqual(
            отслеживаемый.read_text(encoding="utf-8"),
            "новые неподтверждённые tracked-байты\n",
        )
        сам.assertEqual(
            сам.git("show", ":tracked.txt").stdout,
            "новые неподтверждённые tracked-байты\n",
        )

    def test_повтор_не_позволяет_восстановлению_дерева_удалить_новый_неотслеживаемый_путь(
        сам,
    ) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        конфликт = сам.repo / "конфликт"
        конфликт.write_text("цель\n", encoding="utf-8")
        сам.git("add", "--", "конфликт")
        сам.git("commit", "-m", "Добавить целевой файл")
        сам.join("задача-владельца")
        конфликт.unlink()
        конфликт.mkdir()
        (конфликт / "старое.txt").write_text("план\n", encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)
        исходный_запуск_команды_репозитория = модуль.run_git

        def упасть_до_восстановления_дерева(корень, аргументы, **именованные_аргументы):
            if аргументы and аргументы[0] == "read-tree":
                raise RuntimeError("имитация падения до read-tree")
            return исходный_запуск_команды_репозитория(
                корень,
                аргументы,
                **именованные_аргументы,
            )

        with mock.patch.object(
            модуль,
            "run_git",
            side_effect=упасть_до_восстановления_дерева,
        ):
            with сам.assertRaisesRegex(RuntimeError, "имитация падения"):
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    идентификатор_сброса,
                )
        новый = конфликт / "новое.txt"
        новый.write_text("не удалять\n", encoding="utf-8")

        повтор = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertNotEqual(повтор.returncode, 0)
        сам.assertEqual(сам.payload(повтор)["state"], "reset_plan_changed")
        сам.assertEqual(новый.read_text(encoding="utf-8"), "не удалять\n")

    def test_план_не_позволяет_восстановлению_дерева_удалить_игнорируемые_данные(сам) -> None:
        конфликт = сам.repo / "конфликт"
        конфликт.write_text("цель\n", encoding="utf-8")
        (сам.repo / ".gitignore").write_text(
            "конфликт/секрет.tmp\n",
            encoding="utf-8",
        )
        сам.git("add", "--", "конфликт", ".gitignore")
        сам.git("commit", "-m", "Добавить целевой файл и правило игнорирования")
        сам.join("задача-владельца")
        конфликт.unlink()
        конфликт.mkdir()
        секрет = конфликт / "секрет.tmp"
        секрет.write_text("сохранить\n", encoding="utf-8")

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "ignored_path_collision")
        сам.assertEqual(секрет.read_text(encoding="utf-8"), "сохранить\n")

    def test_план_блокирует_скрытое_предположение_неизменности(сам) -> None:
        путь = сам.repo / "tracked.txt"
        путь.write_text("скрытые байты\n", encoding="utf-8")
        сам.git("update-index", "--assume-unchanged", "--", "tracked.txt")

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "hidden_index_flags")
        сам.assertEqual(путь.read_text(encoding="utf-8"), "скрытые байты\n")

    def test_план_блокирует_скрытый_пропуск_рабочего_дерева(сам) -> None:
        путь = сам.repo / "tracked.txt"
        сам.git("update-index", "--skip-worktree", "--", "tracked.txt")
        путь.write_text("скрытые байты\n", encoding="utf-8")

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "hidden_index_flags")
        сам.assertEqual(путь.read_text(encoding="utf-8"), "скрытые байты\n")

    def test_план_блокирует_удаление_правила_игнорирования(сам) -> None:
        правило = сам.repo / ".gitignore"
        правило.write_text("мусор\n", encoding="utf-8")
        сам.git("add", "--", ".gitignore")
        сам.git("commit", "-m", "Игнорировать мусор")
        правило.write_text("", encoding="utf-8")
        мусор = сам.repo / "мусор"
        мусор.write_text("сохранить\n", encoding="utf-8")

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "checkout_policy_changed")
        сам.assertEqual(мусор.read_text(encoding="utf-8"), "сохранить\n")

    def test_план_блокирует_добавление_правила_игнорирования(сам) -> None:
        правило = сам.repo / ".gitignore"
        правило.write_text("", encoding="utf-8")
        сам.git("add", "--", ".gitignore")
        сам.git("commit", "-m", "Добавить пустую политику игнорирования")
        правило.write_text("мусор\n", encoding="utf-8")
        мусор = сам.repo / "мусор"
        мусор.write_text("сохранить\n", encoding="utf-8")

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "checkout_policy_changed")
        сам.assertEqual(мусор.read_text(encoding="utf-8"), "сохранить\n")

    def test_повтор_завершает_частично_применённое_восстановление_дерева(сам) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        второй = сам.repo / "tracked-second.txt"
        второй.write_text("цель второго файла\n", encoding="utf-8")
        сам.git("add", "--", "tracked-second.txt")
        сам.git("commit", "-m", "Добавить второй отслеживаемый файл")
        сам.join("задача-владельца")
        первый = сам.repo / "tracked.txt"
        первый.write_text("план первого файла\n", encoding="utf-8")
        второй.write_text("план второго файла\n", encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)
        исходный_запуск_команды_репозитория = модуль.run_git

        def частично_восстановить_дерево(
            корень,
            аргументы,
            **именованные_аргументы,
        ):
            if аргументы and аргументы[0] == "read-tree":
                первый.write_text(
                    "initial\n",
                    encoding="utf-8",
                )
                raise RuntimeError("имитация частичного read-tree")
            return исходный_запуск_команды_репозитория(
                корень,
                аргументы,
                **именованные_аргументы,
            )

        with mock.patch.object(
            модуль,
            "run_git",
            side_effect=частично_восстановить_дерево,
        ):
            with сам.assertRaisesRegex(
                RuntimeError,
                "имитация частичного read-tree",
            ):
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    идентификатор_сброса,
                )

        сам.assertEqual(первый.read_text(encoding="utf-8"), "initial\n")
        сам.assertEqual(
            второй.read_text(encoding="utf-8"),
            "план второго файла\n",
        )
        повтор = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertEqual(повтор.returncode, 0, повтор.stderr)
        сам.assertEqual(сам.payload(повтор)["состояние"], "сброшено")
        сам.assertEqual(первый.read_text(encoding="utf-8"), "initial\n")
        сам.assertEqual(
            второй.read_text(encoding="utf-8"),
            "цель второго файла\n",
        )

    def test_повтор_принимает_представление_с_преобразованными_концами_строк(сам) -> None:
        модуль = load_queue_module()
        идентификатор_диспетчера = "задача-диспетчера"
        (сам.repo / ".gitattributes").write_text(
            "*.txt text eol=crlf\n",
            encoding="utf-8",
        )
        сам.git("add", "--", ".gitattributes")
        сам.git("commit", "-m", "Закрепить CRLF checkout")
        отслеживаемый = сам.repo / "tracked.txt"
        отслеживаемый.unlink()
        сам.git("checkout-index", "-u", "--", "tracked.txt")
        сам.assertEqual(отслеживаемый.read_bytes(), b"initial\r\n")
        сам.join("задача-владельца")
        отслеживаемый.write_bytes(b"planned\r\n")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        идентификатор_сброса = str(подготовлено["идентификатор_сброса"])
        сам.подтвердить_остановку(
            идентификатор_сброса,
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        контекст = модуль.resolve_context(сам.repo)
        исходный_запуск_команды_репозитория = модуль.run_git

        def частично_восстановить_дерево(
            корень,
            аргументы,
            **именованные_аргументы,
        ):
            if аргументы and аргументы[0] == "read-tree":
                отслеживаемый.write_bytes(b"initial\r\n")
                raise RuntimeError("имитация падения read-tree с CRLF")
            return исходный_запуск_команды_репозитория(
                корень,
                аргументы,
                **именованные_аргументы,
            )

        with mock.patch.object(
            модуль,
            "run_git",
            side_effect=частично_восстановить_дерево,
        ):
            with сам.assertRaisesRegex(RuntimeError, "с CRLF"):
                модуль.применить_сброс(
                    контекст,
                    идентификатор_диспетчера,
                    идентификатор_сброса,
                )

        повтор = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            идентификатор_сброса,
            "--json",
        )

        сам.assertEqual(повтор.returncode, 0, повтор.stderr)
        сам.assertEqual(отслеживаемый.read_bytes(), b"initial\r\n")

    def test_план_не_запускает_внешний_фильтр_получения_рабочих_файлов(сам) -> None:
        маркер = сам.repo / "маркер-фильтра"
        сам.git(
            "config",
            "filter.danger.smudge",
            "sh -c 'printf invoked > маркер-фильтра; cat'",
        )
        (сам.repo / ".gitattributes").write_text(
            "tracked.txt filter=danger\n",
            encoding="utf-8",
        )
        сам.git("add", "--", ".gitattributes")
        сам.git("commit", "-m", "Закрепить внешний filter-атрибут")
        (сам.repo / "tracked.txt").write_text(
            "плановое изменение\n",
            encoding="utf-8",
        )

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "unsupported_checkout_filter")
        сам.assertFalse(маркер.exists())

    def test_план_не_запускает_фильтр_из_игнорируемых_атрибутов(сам) -> None:
        маркер = сам.repo / "маркер-фильтра"
        (сам.repo / ".gitignore").write_text(
            ".gitattributes\n",
            encoding="utf-8",
        )
        сам.git("add", "--", ".gitignore")
        сам.git("commit", "-m", "Игнорировать локальные attributes")
        сам.git(
            "config",
            "filter.danger.smudge",
            "sh -c 'printf invoked > маркер-фильтра; cat'",
        )
        (сам.repo / ".gitattributes").write_text(
            "tracked.txt filter=danger\n",
            encoding="utf-8",
        )
        (сам.repo / "tracked.txt").write_text(
            "плановое изменение\n",
            encoding="utf-8",
        )

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "unsupported_checkout_filter")
        сам.assertFalse(маркер.exists())

    def test_дрейф_изменений_после_подготовки_останавливает_сброс_до_удаления(
        сам,
    ) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        (сам.repo / "tracked.txt").write_text(
            "содержимое из подтверждённого плана\n",
            encoding="utf-8",
        )
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        (сам.repo / "tracked.txt").write_text(
            "новое неподтверждённое содержимое\n",
            encoding="utf-8",
        )
        новый_путь = сам.repo / "появилось-после-подтверждения.txt"
        новый_путь.write_text("не удалять\n", encoding="utf-8")
        сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertNotEqual(применение.returncode, 0)
        сам.assertEqual(
            (сам.repo / "tracked.txt").read_text(encoding="utf-8"),
            "новое неподтверждённое содержимое\n",
        )
        сам.assertEqual(
            новый_путь.read_text(encoding="utf-8"),
            "не удалять\n",
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["state"], "resetting")

    def test_повреждённая_связь_записи_сброса_с_планом_отвергается(сам) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        сам.join("задача-ожидания")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        ссылка_очереди = str(состояние["queue_ref"])
        исходный_объект = str(состояние["queue_oid"])
        исходная_запись = json.loads(
            сам.git("cat-file", "blob", исходный_объект).stdout
        )
        длина_объекта = len(сам.git("rev-parse", "HEAD").stdout.strip())

        def скрыть_участника(запись: dict[str, object]) -> None:
            запись["участники"] = ["задача-владельца"]

        def отвязать_исходный_объект(запись: dict[str, object]) -> None:
            запись["исходный_объект_очереди"] = "0" * длина_объекта

        def отвязать_идентификатор_сброса(запись: dict[str, object]) -> None:
            запись["идентификатор_сброса"] = "sha256:" + "0" * 64

        повреждения = [
            ("участники", скрыть_участника),
            ("исходный объект", отвязать_исходный_объект),
            ("идентификатор сброса", отвязать_идентификатор_сброса),
        ]
        for название, повредить in повреждения:
            with сам.subTest(поле=название):
                повреждённая = json.loads(
                    json.dumps(исходная_запись, ensure_ascii=False)
                )
                повредить(повреждённая)
                повреждённый_объект = subprocess.run(
                    [
                        "git",
                        "-C",
                        str(сам.repo),
                        "hash-object",
                        "-w",
                        "--stdin",
                    ],
                    input=(
                        json.dumps(
                            повреждённая,
                            ensure_ascii=False,
                            sort_keys=True,
                            separators=(",", ":"),
                        )
                        + "\n"
                    ),
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout.strip()
                сам.git(
                    "update-ref",
                    ссылка_очереди,
                    повреждённый_объект,
                    исходный_объект,
                )
                try:
                    результат = сам.run_queue(
                        "status",
                        "--repo-root",
                        str(сам.repo),
                        "--json",
                    )
                    сам.assertNotEqual(результат.returncode, 0)
                    сам.assertEqual(
                        сам.payload(результат)["state"],
                        "corrupt_reset",
                    )
                finally:
                    сам.git(
                        "update-ref",
                        ссылка_очереди,
                        исходный_объект,
                        повреждённый_объект,
                    )

    def test_пульс_считает_идущий_сброс_занятой_очередью(сам) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, _ = сам.подготовить_сброс(план, идентификатор_диспетчера)

        результат = сам.heartbeat_status(идентификатор_диспетчера)

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(сам.payload(результат), {"state": "busy"})

    def test_полный_сброс_создаёт_пустую_очередь_из_отсутствующей_ссылки(
        сам,
    ) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        исходная_вершина = сам.git("rev-parse", "HEAD").stdout.strip()
        (сам.repo / "tracked.txt").write_text(
            "незафиксированное изменение\n",
            encoding="utf-8",
        )
        новый_путь = сам.repo / "незафиксированный-файл.txt"
        новый_путь.write_text("удалить\n", encoding="utf-8")

        _, план = сам.план_сброса(идентификатор_диспетчера)

        сам.assertEqual(план["объект_очереди"], "absent")
        сам.assertEqual(план["участники"], [])
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        остановка, _ = сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        сам.assertEqual(остановка.returncode, 0, остановка.stderr)

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertEqual(применение.returncode, 0, применение.stderr)
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), исходная_вершина)
        сам.assertFalse(новый_путь.exists())
        сам.assertEqual(
            (сам.repo / "tracked.txt").read_text(encoding="utf-8"),
            "initial\n",
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["state"], "idle")
        сам.assertEqual(состояние["next_seq"], 1)
        сам.assertIsNotNone(состояние["queue_oid"])
        очередь = json.loads(
            сам.git("cat-file", "blob", str(состояние["queue_oid"])).stdout
        )
        сам.assertEqual(очередь["last_completion"]["kind"], "reset")

    def test_смена_резервации_после_плана_блокирует_подготовку_без_побочных_эффектов(
        сам,
    ) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        (сам.repo / "tracked.txt").write_text(
            "не удалять при конфликте резервации\n",
            encoding="utf-8",
        )
        исходная_вершина = сам.git("rev-parse", "HEAD").stdout.strip()
        состояние_очереди = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние_очереди["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка_резервации = (
            "refs/fum/резервации-запусков-автоматизаций/"
            f"{состояние_очереди['worktree_id']}/{хэш_ветки}/{'3' * 64}"
        )

        def записать_объект_резервации(содержимое: str) -> str:
            return subprocess.run(
                [
                    "git",
                    "-C",
                    str(сам.repo),
                    "hash-object",
                    "-w",
                    "--stdin",
                ],
                input=содержимое,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()

        первый_объект = записать_объект_резервации(
            json.dumps({"task_id": None, "фаза": "зарезервирован"}) + "\n"
        )
        второй_объект = записать_объект_резервации(
            json.dumps({"task_id": None, "фаза": "вызов_мог_состояться"}) + "\n"
        )
        сам.git("update-ref", ссылка_резервации, первый_объект)
        _, план = сам.план_сброса(идентификатор_диспетчера)
        сам.git(
            "update-ref",
            ссылка_резервации,
            второй_объект,
            первый_объект,
        )

        подготовка, _ = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )

        сам.assertNotEqual(подготовка.returncode, 0)
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), исходная_вершина)
        сам.assertEqual(
            сам.git("rev-parse", ссылка_резервации).stdout.strip(),
            второй_объект,
        )
        сам.assertEqual(
            (сам.repo / "tracked.txt").read_text(encoding="utf-8"),
            "не удалять при конфликте резервации\n",
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["queue_oid"], план["объект_очереди"])
        сам.assertEqual(состояние["state"], "active")

    def test_план_блокирует_неразрешённую_границу_среды_резервации(сам) -> None:
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка_резервации = (
            "refs/fum/резервации-запусков-автоматизаций/"
            f"{состояние['worktree_id']}/{хэш_ветки}/{'5' * 64}"
        )
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {
                    "фаза": "вызов_мог_состояться",
                    "task_id": None,
                    "идентификатор_созданной_задачи": None,
                },
                ensure_ascii=False,
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка_резервации, объект)

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "host_call_unresolved")
        сам.assertEqual(
            сам.payload(
                сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
            )["state"],
            "idle",
        )

    def test_план_блокирует_нетипизированный_предварительный_идентификатор_среды_до_привязки_запуска(
        сам,
    ) -> None:
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка = (
            "refs/fum/резервации-запусков-автоматизаций/"
            f"{состояние['worktree_id']}/{хэш_ветки}/{'6' * 64}"
        )
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {
                    "версия_схемы": 3,
                    "фаза": "задача_создана",
                    "task_id": None,
                    "идентификатор_созданной_задачи": "подготовка-host",
                    "свидетельство_среды": {
                        "вид": "clientThreadId",
                        "значение": "подготовка-host",
                    },
                },
                ensure_ascii=False,
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка, объект)

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "host_call_unresolved")

    def test_план_включает_точный_идентификатор_задачи_среды_общего_запуска_до_привязки_запуска(
        сам,
    ) -> None:
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка = (
            "refs/fum/резервации-запусков-автоматизаций/"
            f"{состояние['worktree_id']}/{хэш_ветки}/{'8' * 64}"
        )
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {
                    "версия_схемы": 3,
                    "фаза": "задача_создана",
                    "task_id": None,
                    "идентификатор_созданной_задачи": "точная-host-задача",
                    "свидетельство_среды": {
                        "вид": "threadId",
                        "threadId": "точная-host-задача",
                        "hostId": "host-1",
                    },
                },
                ensure_ascii=False,
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка, объект)

        результат, план = сам.план_сброса("задача-диспетчера")

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(план["участники"], ["точная-host-задача"])

    def test_план_сброса_блокирует_ожидающее_сообщение_возобновления(
        сам,
    ) -> None:
        сам.записать_резервацию_возобновления("вызов_мог_состояться")

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "host_call_unresolved")

    def test_план_сброса_принимает_подтверждённое_возобновление(
        сам,
    ) -> None:
        сам.записать_резервацию_возобновления(
            "подтверждено_исполнителем"
        )

        результат, план = сам.план_сброса("задача-диспетчера")

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(план["участники"], ["возобновляемая-задача"])

    def test_план_сброса_закрывает_повреждённое_возобновление(
        сам,
    ) -> None:
        сам.записать_резервацию_возобновления(
            "подтверждено_исполнителем",
            удалить_поле="ключ",
        )

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "corrupt_service_fence")

    def test_план_сброса_закрывает_неполное_наблюдение_возобновления(
        сам,
    ) -> None:
        сам.записать_резервацию_возобновления(
            "подтверждено_исполнителем",
            удалить_поле_наблюдения="идентификатор_хода",
        )

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "corrupt_service_fence")

    def test_план_сброса_не_принимает_логическое_число_возобновления(
        сам,
    ) -> None:
        сам.записать_резервацию_возобновления(
            "подтверждено_исполнителем",
            логическое_поле="номер_попытки",
        )

        результат, ответ = сам.план_сброса("задача-диспетчера")

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(ответ["state"], "corrupt_service_fence")

    def test_план_принимает_фактическую_привязку_запуска_после_неясной_границы_среды(
        сам,
    ) -> None:
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка = (
            "refs/fum/резервации-запусков-автоматизаций/"
            f"{состояние['worktree_id']}/{хэш_ветки}/{'7' * 64}"
        )
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {
                    "фаза": "вызов_мог_состояться",
                    "task_id": "фактическая-задача",
                    "идентификатор_созданной_задачи": None,
                },
                ensure_ascii=False,
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка, объект)

        результат, план = сам.план_сброса("задача-диспетчера")

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(план["участники"], ["фактическая-задача"])

    def test_план_включает_точный_идентификатор_задачи_среды_созданной_задачи_починки(сам) -> None:
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка_починки = (
            "refs/fum/починка-автозапуска/"
            f"{состояние['worktree_id']}/{хэш_ветки}"
        )
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {
                    "схема": "fum.починка-автозапуска.v1",
                    "состояние": "задача_создана",
                    "создатель": {
                        "задача": "задача-координатора",
                        "поколение": "11111111-1111-4111-8111-111111111111",
                    },
                    "свидетельство_среды": {
                        "вид": "threadId",
                        "threadId": "задача-починки",
                        "hostId": "host-1",
                    },
                    "исполнитель": None,
                },
                ensure_ascii=False,
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка_починки, объект)

        результат, план = сам.план_сброса("задача-диспетчера")

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(
            план["участники"],
            ["задача-координатора", "задача-починки"],
        )

    def test_план_сохраняет_идентификатор_задачи_среды_починки_после_привязки_исполнителя(
        сам,
    ) -> None:
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка = (
            "refs/fum/починка-автозапуска/"
            f"{состояние['worktree_id']}/{хэш_ветки}"
        )
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {
                    "схема": "fum.починка-автозапуска.v1",
                    "состояние": "исполнитель_связан",
                    "создатель": {"задача": "задача-координатора"},
                    "свидетельство_среды": {
                        "вид": "threadId",
                        "threadId": "созданная-host-задача",
                        "hostId": "host-1",
                    },
                    "исполнитель": {
                        "задача": "привязанный-исполнитель",
                        "поколение": None,
                    },
                },
                ensure_ascii=False,
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка, объект)

        результат, план = сам.план_сброса("задача-диспетчера")

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(
            план["участники"],
            [
                "задача-координатора",
                "привязанный-исполнитель",
                "созданная-host-задача",
            ],
        )

    def test_сдвиг_эпохи_новых_резерваций_блокирует_подготовку(сам) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        _, план = сам.план_сброса(идентификатор_диспетчера)
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        ссылка_эпохи = (
            "refs/fum/эпохи-резерваций-запусков-автоматизаций/"
            f"{состояние['worktree_id']}/{хэш_ветки}"
        )
        объект_эпохи = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input='{"\u0441\u0445\u0435\u043c\u0430":"fum.\u044d\u043f\u043e\u0445\u0430-\u0440\u0435\u0437\u0435\u0440\u0432\u0430\u0446\u0438\u0439.1"}\n',
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка_эпохи, объект_эпохи)

        подготовка, _ = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )

        сам.assertNotEqual(подготовка.returncode, 0)
        сам.assertEqual(
            сам.payload(сам.run_queue("status", "--repo-root", str(сам.repo), "--json"))["state"],
            "idle",
        )

    def test_финал_согласует_точные_служебные_ограждения(сам) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        основа = f"{состояние['worktree_id']}/{хэш_ветки}"
        служебные = {
            f"refs/fum/управление-диспетчером/{основа}": {
                "task_id": идентификатор_диспетчера,
            },
            f"refs/fum/worktree-next-step-claims/{основа}": {
                "task_id": "задача-карточки",
            },
            f"refs/fum/починка-автозапуска/{основа}": {
                "схема": "fum.починка-автозапуска.v1",
                "состояние": "зарезервирован",
                "создатель": {"задача": "задача-починки"},
                "свидетельство_среды": None,
                "исполнитель": None,
            },
            (
                "refs/fum/резервации-запусков-автоматизаций/"
                f"{основа}/{'4' * 64}"
            ): {
                "идентификатор_созданной_задачи": "подготовка-запуска",
                "task_id": "задача-запуска",
                "фаза": "задача_создана",
            },
        }
        объекты: dict[str, str] = {}
        for ссылка, содержимое in служебные.items():
            объект = subprocess.run(
                ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
                input=json.dumps(содержимое, ensure_ascii=False) + "\n",
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            сам.git("update-ref", ссылка, объект)
            объекты[ссылка] = объект

        _, план = сам.план_сброса(идентификатор_диспетчера)

        сам.assertEqual(
            план["участники"],
            sorted(
                {
                    идентификатор_диспетчера,
                    "задача-владельца",
                    "задача-запуска",
                    "задача-карточки",
                    "задача-починки",
                }
            ),
        )
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "задача-владельца",
            "задача-запуска",
            "задача-карточки",
            "задача-починки",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )
        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertEqual(применение.returncode, 0, применение.stderr)
        for ссылка, объект in объекты.items():
            обнаруженный = сам.git("rev-parse", "--verify", "--quiet", ссылка, check=False)
            if (
                "резервации-запусков-автоматизаций" in ссылка
                or "worktree-next-step-claims" in ссылка
            ):
                сам.assertEqual(обнаруженный.returncode, 0)
                сам.assertEqual(обнаруженный.stdout.strip(), объект)
            else:
                сам.assertEqual(обнаруженный.returncode, 1)

    def test_грязный_вложенный_обычный_репозиторий_не_удаляется(сам) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        вложенный = сам.repo / "вложенный-репозиторий"
        subprocess.run(
            ["git", "init", "-b", "master", str(вложенный)],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", str(вложенный), "config", "user.name", "FUM Test"],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            [
                "git",
                "-C",
                str(вложенный),
                "config",
                "user.email",
                "fum-test@example.invalid",
            ],
            check=True,
            capture_output=True,
        )
        вложенный_файл = вложенный / "данные.txt"
        вложенный_файл.write_text("исходное\n", encoding="utf-8")
        subprocess.run(
            ["git", "-C", str(вложенный), "add", "данные.txt"],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            [
                "git",
                "-C",
                str(вложенный),
                "commit",
                "-m",
                "Начальное состояние вложенного репозитория",
            ],
            check=True,
            capture_output=True,
        )
        вложенный_файл.write_text("грязное\n", encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertNotEqual(применение.returncode, 0)
        сам.assertEqual(сам.payload(применение)["state"], "nested_repository_dirty")
        сам.assertTrue((вложенный / ".git").exists())
        сам.assertEqual(вложенный_файл.read_text(encoding="utf-8"), "грязное\n")

    def test_вложенный_репозиторий_без_рабочей_копии_не_удаляется(сам) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        сам.join("задача-владельца")
        вложенный = сам.repo / "вложенное-хранилище.git"
        subprocess.run(
            ["git", "init", "--bare", str(вложенный)],
            check=True,
            capture_output=True,
        )
        служебный_файл = вложенный / "description"
        исходное_содержимое = служебный_файл.read_text(encoding="utf-8")
        _, план = сам.план_сброса(идентификатор_диспетчера)
        _, подготовлено = сам.подготовить_сброс(
            план,
            идентификатор_диспетчера,
        )
        сам.подтвердить_остановку(
            str(подготовлено["идентификатор_сброса"]),
            "задача-владельца",
            идентификатор_диспетчера=идентификатор_диспетчера,
        )

        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertNotEqual(применение.returncode, 0)
        сам.assertEqual(сам.payload(применение)["state"], "nested_repository_dirty")
        сам.assertTrue(вложенный.exists())
        сам.assertEqual(
            служебный_файл.read_text(encoding="utf-8"),
            исходное_содержимое,
        )


class ТестыСбросаОчередиСХэшем256(GitQueueFixture):
    формат_объектов = "sha256"

    def test_полный_цикл_сброса_использует_полные_шестидесятичетырёхзначные_объекты(
        сам,
    ) -> None:
        идентификатор_диспетчера = "задача-диспетчера"
        _, владелец = сам.join("задача-владельца")
        (сам.repo / "tracked.txt").write_text("изменено\n", encoding="utf-8")
        исходная_вершина = сам.git("rev-parse", "HEAD").stdout.strip()

        результат_плана = сам.run_queue(
            "план-сброса",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--json",
        )
        план = сам.payload(результат_плана)

        сам.assertEqual(результат_плана.returncode, 0, результат_плана.stderr)
        сам.assertEqual(len(str(план["целевая_вершина"])), 64)
        сам.assertEqual(len(str(план["объект_очереди"])), 64)
        подготовка = сам.run_queue(
            "подготовить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--ожидаемая-вершина",
            str(план["целевая_вершина"]),
            "--ожидаемый-объект-очереди",
            str(план["объект_очереди"]),
            "--подтверждение",
            str(план["подтверждение"]),
            "--json",
        )
        подготовлено = сам.payload(подготовка)
        сам.assertEqual(подготовка.returncode, 0, подготовка.stderr)
        остановка = сам.run_queue(
            "подтвердить-остановку-сессий",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--неактивная-задача",
            str(владелец["task_id"]),
            "--json",
        )
        сам.assertEqual(остановка.returncode, 0, остановка.stderr)
        применение = сам.run_queue(
            "применить-сброс",
            "--repo-root",
            str(сам.repo),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
        )

        сам.assertEqual(применение.returncode, 0, применение.stderr)
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), исходная_вершина)
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(состояние["state"], "idle")
        сам.assertEqual(len(str(состояние["queue_oid"])), 64)
        очередь = json.loads(
            сам.git("cat-file", "blob", str(состояние["queue_oid"])).stdout
        )
        сам.assertEqual(очередь["last_completion"]["kind"], "reset")


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
            timeout=60,
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

    def test_малый_грязный_инвентарь_сохраняет_полную_диагностику(
        сам,
    ) -> None:
        _, владелец = сам.join("task-a")
        сам.stage_change("подготовлено\n")
        (сам.repo / "untracked.txt").write_text("unknown\n", encoding="utf-8")
        ожидаемые_пути = ["untracked.txt"]
        вычислитель = hashlib.sha256()
        вычислитель.update(b"FUM\0queue-dirty-blocking-paths\0v1\0")
        вычислитель.update(len(ожидаемые_пути).to_bytes(8, "big"))
        for путь in ожидаемые_пути:
            сырые_байты = путь.encode("utf-8", errors="surrogateescape")
            вычислитель.update(len(сырые_байты).to_bytes(8, "big"))
            вычислитель.update(сырые_байты)

        результат = сам.commit("task-a", str(владелец["generation"]))

        сам.assertNotEqual(результат.returncode, 0)
        ответ = сам.payload(результат)
        сам.assertEqual(ответ["state"], "dirty")
        сам.assertEqual(ответ["blocking_paths_schema"], 1)
        сам.assertEqual(ответ["blocking_paths"], ожидаемые_пути)
        сам.assertEqual(ответ["blocking_paths_count"], 1)
        сам.assertEqual(
            ответ["blocking_paths_sha256"],
            f"sha256:{вычислитель.hexdigest()}",
        )
        сам.assertIs(ответ["blocking_paths_truncated"], False)

    def test_большой_грязный_инвентарь_возвращает_ограниченный_детерминированный_ответ(
        сам,
    ) -> None:
        модуль = load_queue_module()
        _, владелец = сам.join("task-a")
        сам.stage_change("подготовлено\n")
        ожидаемые_пути = [
            f"блокирующий-{номер:04d}-{'я' * 60}.txt"
            for номер in range(320)
        ]
        for путь in ожидаемые_пути:
            (сам.repo / путь).write_text("блокирует\n", encoding="utf-8")
        вычислитель = hashlib.sha256()
        вычислитель.update(b"FUM\0queue-dirty-blocking-paths\0v1\0")
        вычислитель.update(len(ожидаемые_пути).to_bytes(8, "big"))
        for путь in ожидаемые_пути:
            сырые_байты = путь.encode("utf-8", errors="surrogateescape")
            вычислитель.update(len(сырые_байты).to_bytes(8, "big"))
            вычислитель.update(сырые_байты)
        вершина_до = сам.git("rev-parse", "HEAD").stdout.strip()
        контекст = модуль.resolve_context(сам.repo)
        объект_очереди_до = сам.git(
            "rev-parse",
            контекст.queue_ref,
        ).stdout.strip()
        индекс_до = (сам.repo / ".git" / "index").read_bytes()

        первый = сам.commit("task-a", str(владелец["generation"]))
        повторный = сам.commit("task-a", str(владелец["generation"]))

        сам.assertEqual(первый.returncode, модуль.EXIT_DIRTY)
        сам.assertEqual(повторный.stdout, первый.stdout)
        сам.assertLessEqual(len(первый.stdout.encode("utf-8")), 16384)
        ответ = сам.payload(первый)
        сам.assertEqual(
            set(ответ),
            {
                "state",
                "message",
                "blocking_paths_schema",
                "blocking_paths",
                "blocking_paths_count",
                "blocking_paths_sha256",
                "blocking_paths_truncated",
            },
        )
        сам.assertEqual(ответ["state"], "dirty")
        сам.assertEqual(ответ["blocking_paths_schema"], 1)
        сам.assertEqual(ответ["blocking_paths_count"], 320)
        сам.assertEqual(
            ответ["blocking_paths_sha256"],
            f"sha256:{вычислитель.hexdigest()}",
        )
        сам.assertIs(ответ["blocking_paths_truncated"], True)
        сам.assertEqual(
            ответ["blocking_paths"],
            ожидаемые_пути[:16],
        )
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), вершина_до)
        сам.assertEqual(
            сам.git("rev-parse", контекст.queue_ref).stdout.strip(),
            объект_очереди_до,
        )
        сам.assertEqual((сам.repo / ".git" / "index").read_bytes(), индекс_до)

    def test_один_чрезмерный_путь_даёт_пустой_точный_предпросмотр(
        сам,
    ) -> None:
        модуль = load_queue_module()
        поток = io.StringIO()
        with mock.patch.object(sys, "stdout", поток):
            модуль.emit(
                {
                    "state": "dirty",
                    "message": "Диагностика грязной рабочей копии.",
                    "blocking_paths": ["я" * 20_000, "я" * 20_000],
                }
            )

        сериализованный_ответ = поток.getvalue()
        сам.assertLessEqual(len(сериализованный_ответ.encode("utf-8")), 16384)
        ответ = json.loads(сериализованный_ответ)
        сам.assertEqual(ответ["blocking_paths_count"], 1)
        сам.assertEqual(ответ["blocking_paths"], [])
        сам.assertIs(ответ["blocking_paths_truncated"], True)

    def test_точный_повтор_коммита_не_требует_исчезнувший_файл_сообщения(
        сам,
    ) -> None:
        _, владелец = сам.join("task-a")
        сам.stage_change("готово\n")
        файл_сообщения = Path(сам.temporary_directory.name) / "message.txt"
        файл_сообщения.write_text("Завершить задачу\n", encoding="utf-8")
        аргументы = (
            "commit",
            "--repo-root",
            str(сам.repo),
            "--task-id",
            "task-a",
            "--generation",
            str(владелец["generation"]),
            "--message-file",
            str(файл_сообщения),
            "--json",
        )

        первый = сам.run_queue(*аргументы)
        сам.assertEqual(первый.returncode, 0, первый.stderr)
        первый_ответ = сам.payload(первый)
        сам.assertEqual(первый_ответ["state"], "committed")
        файл_сообщения.unlink()
        вершина_до = сам.git("rev-parse", "HEAD").stdout.strip()
        индекс_до = (сам.repo / ".git" / "index").read_bytes()

        повторный = сам.run_queue(*аргументы)

        сам.assertEqual(повторный.returncode, 0, повторный.stderr)
        повторный_ответ = сам.payload(повторный)
        for поле in {
            "state",
            "task_id",
            "generation",
            "old_head",
            "new_head",
            "branch_ref",
            "queue_ref",
            "queue_oid",
            "worktree_id",
        }:
            сам.assertEqual(повторный_ответ[поле], первый_ответ[поле])
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), вершина_до)
        сам.assertEqual((сам.repo / ".git" / "index").read_bytes(), индекс_до)

    def test_первый_коммит_с_отсутствующим_файлом_сообщения_отклоняется(
        сам,
    ) -> None:
        модуль = load_queue_module()
        _, владелец = сам.join("task-a")
        сам.stage_change("готово\n")
        отсутствующий_файл = Path(сам.temporary_directory.name) / "missing.txt"
        вершина_до = сам.git("rev-parse", "HEAD").stdout.strip()
        индекс_до = (сам.repo / ".git" / "index").read_bytes()

        результат = сам.run_queue(
            "commit",
            "--repo-root",
            str(сам.repo),
            "--task-id",
            "task-a",
            "--generation",
            str(владелец["generation"]),
            "--message-file",
            str(отсутствующий_файл),
            "--json",
        )

        сам.assertEqual(результат.returncode, модуль.EXIT_CLI)
        сам.assertEqual(сам.payload(результат)["state"], "invalid_message_file")
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), вершина_до)
        сам.assertEqual((сам.repo / ".git" / "index").read_bytes(), индекс_до)

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
                    timeout=60,
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
        self.join("продолжение-юникод")
        self.stage_change("unicode branch\n")

        committed = self.commit(
            "task-a",
            str(owner["generation"]),
            "Коммит в Unicode-ветке",
            "продолжение-юникод",
        )

        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.assertEqual(self.payload(committed)["state"], "committed")
        self.assertEqual(
            self.git("symbolic-ref", "HEAD").stdout.strip(),
            "refs/heads/проверка/очереди",
        )
        ссылка = self.ссылки_квитанций_связанных_коммитов()[0]
        объект = self.git("rev-parse", ссылка).stdout.strip()
        квитанция = json.loads(self.git("cat-file", "blob", объект).stdout)
        self.assertEqual(
            квитанция["ссылка_ветки"],
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
            timeout=60,
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
            timeout=60,
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


class ТестыПростогоСбросаКТекущейВершине(GitQueueFixture):
    def записать_служебный_объект(сам, ссылка: str, метка: str) -> str:
        объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {"метка": метка, "фаза": "вызов_мог_состоять"},
                ensure_ascii=False,
                sort_keys=True,
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка, объект)
        return объект

    def служебные_ссылки(
        сам,
        состояние: dict[str, object],
    ) -> dict[str, str]:
        хэш_ветки = hashlib.sha256(
            str(состояние["branch_ref"]).encode("utf-8")
        ).hexdigest()
        основа = f"{состояние['worktree_id']}/{хэш_ветки}"
        return {
            "управление": f"refs/fum/управление-диспетчером/{основа}",
            "претензия": f"refs/fum/worktree-next-step-claims/{основа}",
            "починка": f"refs/fum/починка-автозапуска/{основа}",
            "резервация": (
                "refs/fum/резервации-запусков-автоматизаций/"
                f"{основа}/{'9' * 64}"
            ),
            "эпоха": (
                "refs/fum/эпохи-резерваций-запусков-автоматизаций/"
                f"{основа}"
            ),
            "аналитика": f"refs/fum/аналитика-завершённых-запусков/{основа}",
            "журнал_завершений": f"refs/fum/worktree-task-completion-ledgers/{основа}",
            "повреждённая_квитанция": (
                "refs/fum/квитанции-сброса-состояния-FIFO/"
                f"{основа}/{'6' * 64}"
            ),
            "постоянное_доказательство": (
                "refs/fum/аварийные-снимки-состояния/"
                f"{основа}/ранее/объект"
            ),
            "чужая_ветка": (
                "refs/fum/аналитика-завершённых-запусков/"
                f"{состояние['worktree_id']}/{'8' * 64}"
            ),
        }

    def выполнить_простой_сброс(сам, ответ: str):
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)

        class ИнтерактивныйБуфер(io.StringIO):
            def isatty(себя) -> bool:
                return True

        вывод = ИнтерактивныйБуфер()
        with (
            mock.patch.object(модуль.sys, "stdin", ИнтерактивныйБуфер()),
            mock.patch.object(модуль.sys, "stdout", вывод),
            mock.patch.object(модуль.sys, "stderr", ИнтерактивныйБуфер()),
            mock.patch("builtins.input", return_value=ответ),
        ):
            результат = модуль.простой_сброс(контекст)
        return результат, вывод.getvalue()

    def test_без_терминала_сброс_отказывает_до_мутации(сам) -> None:
        сам.join("owner-task")
        (сам.repo / "tracked.txt").write_text("изменено\n", encoding="utf-8")
        до = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )

        результат = сам.run_queue(
            "простой-сброс",
            "--repo-root",
            str(сам.repo),
            "--json",
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(сам.payload(результат)["state"], "interactive_terminal_required")
        после = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(после["queue_oid"], до["queue_oid"])
        сам.assertEqual((сам.repo / "tracked.txt").read_text(encoding="utf-8"), "изменено\n")

    def test_терминал_требуется_и_для_стандартного_вывода(сам) -> None:
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)

        class ТерминальныйБуфер(io.StringIO):
            def isatty(себя) -> bool:
                return True

        with (
            mock.patch.object(модуль.sys, "stdin", ТерминальныйБуфер()),
            mock.patch.object(модуль.sys, "stdout", io.StringIO()),
            mock.patch.object(модуль.sys, "stderr", ТерминальныйБуфер()),
        ):
            with сам.assertRaises(Exception) as отказ:
                модуль.простой_сброс(контекст)

        сам.assertEqual(
            getattr(отказ.exception, "state", None),
            "interactive_terminal_required",
        )
        сам.assertEqual(
            сам.git(
                "for-each-ref",
                "--format=%(refname)",
                "refs/fum/",
            ).stdout,
            "",
        )

    def test_неверная_фраза_ничего_не_сбрасывает(сам) -> None:
        сам.join("owner-task")
        до = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )

        with сам.assertRaises(Exception) as отказ:
            сам.выполнить_простой_сброс("нет")

        сам.assertEqual(getattr(отказ.exception, "state", None), "confirmation_mismatch")
        после = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(после["queue_oid"], до["queue_oid"])

    def test_изменение_оперативного_состояния_после_плана_закрывает_сброс(сам) -> None:
        сам.join("owner-task")
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        ссылка_управления = сам.служебные_ссылки(состояние)["управление"]
        сам.записать_служебный_объект(ссылка_управления, "до")
        план = модуль.план_простого_сброса(контекст)
        фраза = модуль.фраза_подтверждения_простого_сброса(план)

        class ИнтерактивныйБуфер(io.StringIO):
            def isatty(себя) -> bool:
                return True

        новый_объект = ""

        def изменить_и_подтвердить(*_аргументы: object) -> str:
            nonlocal новый_объект
            новый_объект = сам.записать_служебный_объект(
                ссылка_управления,
                "после",
            )
            return фраза

        with (
            mock.patch.object(модуль.sys, "stdin", ИнтерактивныйБуфер()),
            mock.patch.object(модуль.sys, "stdout", ИнтерактивныйБуфер()),
            mock.patch.object(модуль.sys, "stderr", ИнтерактивныйБуфер()),
            mock.patch("builtins.input", side_effect=изменить_и_подтвердить),
        ):
            with сам.assertRaises(Exception) as отказ:
                модуль.простой_сброс(контекст)

        сам.assertEqual(getattr(отказ.exception, "state", None), "reset_plan_changed")
        сам.assertEqual(
            сам.git("rev-parse", "--verify", ссылка_управления).stdout.strip(),
            новый_объект,
        )
        после = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(после["queue_oid"], состояние["queue_oid"])

    def test_повреждённая_очередь_не_блокирует_ручной_сброс(сам) -> None:
        повреждённый_объект = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input="не JSON\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        контекст = load_queue_module().resolve_context(сам.repo)
        сам.git("update-ref", контекст.queue_ref, повреждённый_объект)
        (сам.repo / "tracked.txt").write_text("изменено\n", encoding="utf-8")
        модуль = load_queue_module()
        план = модуль.план_простого_сброса(модуль.resolve_context(сам.repo))

        (код, ответ), _ = сам.выполнить_простой_сброс(
            модуль.фраза_подтверждения_простого_сброса(план)
        )

        сам.assertEqual(код, 0)
        сам.assertEqual(ответ["состояние"], "сброшено")
        после = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(после["state"], "idle")
        сам.assertNotEqual(после["queue_oid"], повреждённый_объект)

    def test_повтор_после_терминального_ответа_возвращает_прежний_успех_без_мутации(
        сам,
    ) -> None:
        сам.join("задача-владельца")
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)
        план = модуль.план_простого_сброса(контекст)
        первый, _ = сам.выполнить_простой_сброс(
            модуль.фраза_подтверждения_простого_сброса(план)
        )
        ссылки_до = сам.git(
            "for-each-ref",
            "--format=%(refname) %(objectname)",
            "refs/fum/",
        ).stdout

        class ИнтерактивныйБуфер(io.StringIO):
            def isatty(себя) -> bool:
                return True

        with (
            mock.patch.object(модуль.sys, "stdin", ИнтерактивныйБуфер()),
            mock.patch.object(модуль.sys, "stdout", ИнтерактивныйБуфер()),
            mock.patch.object(модуль.sys, "stderr", ИнтерактивныйБуфер()),
            mock.patch("builtins.input", side_effect=AssertionError("ввод не ожидался")) as ввод,
        ):
            повтор = модуль.простой_сброс(контекст)

        ввод.assert_not_called()
        сам.assertEqual(повтор, первый)
        сам.assertEqual(
            сам.git(
                "for-each-ref",
                "--format=%(refname) %(objectname)",
                "refs/fum/",
            ).stdout,
            ссылки_до,
        )

    def test_грязная_рабочая_копия_не_маскируется_терминальной_квитанцией(
        сам,
    ) -> None:
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)
        план = модуль.план_простого_сброса(контекст)
        сам.выполнить_простой_сброс(
            модуль.фраза_подтверждения_простого_сброса(план)
        )
        (сам.repo / "tracked.txt").write_text("новое изменение\n", encoding="utf-8")

        with сам.assertRaises(Exception) as отказ:
            сам.выполнить_простой_сброс("нет")

        сам.assertEqual(getattr(отказ.exception, "state", None), "confirmation_mismatch")
        сам.assertEqual(
            (сам.repo / "tracked.txt").read_text(encoding="utf-8"),
            "новое изменение\n",
        )

    def test_новая_оперативная_ссылка_не_маскируется_терминальной_квитанцией(
        сам,
    ) -> None:
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)
        план = модуль.план_простого_сброса(контекст)
        сам.выполнить_простой_сброс(
            модуль.фраза_подтверждения_простого_сброса(план)
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        ссылка = сам.служебные_ссылки(состояние)["управление"]
        объект = сам.записать_служебный_объект(ссылка, "после-сброса")

        with сам.assertRaises(Exception) as отказ:
            сам.выполнить_простой_сброс("нет")

        сам.assertEqual(getattr(отказ.exception, "state", None), "confirmation_mismatch")
        сам.assertEqual(
            сам.git("rev-parse", "--verify", ссылка).stdout.strip(),
            объект,
        )

    def test_точное_свидетельство_среды_получает_аннулирование_для_всей_рабочей_копии(
        сам,
    ) -> None:
        сам.join("задача-владельца")
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        ссылка_починки = сам.служебные_ссылки(состояние)["починка"]
        объект_починки = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                {
                    "схема": "fum.починка-автозапуска.v1",
                    "состояние": "задача_создана",
                    "свидетельство_среды": {
                        "вид": "threadId",
                        "threadId": "задача-из-свидетельства",
                        "hostId": "проверочный-хост",
                    },
                },
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git("update-ref", ссылка_починки, объект_починки)
        модуль = load_queue_module()
        контекст = модуль.resolve_context(сам.repo)
        план = модуль.план_простого_сброса(контекст)
        сам.assertIn("задача-из-свидетельства", план["участники"])

        сам.выполнить_простой_сброс(
            модуль.фраза_подтверждения_простого_сброса(план)
        )

        отпечаток = hashlib.sha256(
            "задача-из-свидетельства".encode("utf-8")
        ).hexdigest()
        ссылка_аннулирования = (
            "refs/fum/аннулированные-задачи-простого-сброса/"
            f"{состояние['worktree_id']}/{отпечаток}"
        )
        сам.assertEqual(
            сам.git(
                "rev-parse",
                "--verify",
                ссылка_аннулирования,
            ).returncode,
            0,
        )
        сам.git("switch", "-c", "другая-ветка")
        повтор, ответ = сам.join("задача-из-свидетельства")
        сам.assertNotEqual(повтор.returncode, 0)
        сам.assertEqual(ответ["state"], "task_annulled_by_simple_reset")

    def test_подтверждённый_сброс_обнуляет_очередь_и_оперативное_состояние(
        сам,
    ) -> None:
        (сам.repo / ".gitignore").write_text(".ignored/\n", encoding="utf-8")
        сам.git("add", ".gitignore")
        сам.git("commit", "-m", "Add ignored fixture")
        _, владелец = сам.join("owner-task")
        сам.join("waiter-task")
        исходная_вершина = сам.git("rev-parse", "HEAD").stdout.strip()
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        исходная_очередь = json.loads(
            сам.git("cat-file", "blob", str(состояние["queue_oid"])).stdout
        )
        текущая_цепочка = {
            "идентификатор": "FUM-ЦЕПОЧКА-0001",
            "путь": "Планирование/карточки-цепочек-шагов/фикстура.md",
            "хэш": f"sha256:{'7' * 64}",
            "ветка": состояние["branch_ref"],
        }
        исходная_очередь["текущая_цепочка"] = текущая_цепочка
        объект_очереди_с_цепочкой = subprocess.run(
            ["git", "-C", str(сам.repo), "hash-object", "-w", "--stdin"],
            input=json.dumps(
                исходная_очередь,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        сам.git(
            "update-ref",
            str(состояние["queue_ref"]),
            объект_очереди_с_цепочкой,
            str(состояние["queue_oid"]),
        )
        состояние = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        исходный_объект_очереди = str(состояние["queue_oid"])
        ссылки = сам.служебные_ссылки(состояние)
        исходные_объекты = {
            имя: сам.записать_служебный_объект(ссылка, имя)
            for имя, ссылка in ссылки.items()
        }
        (сам.repo / "tracked.txt").write_text("изменено\n", encoding="utf-8")
        сам.git("add", "tracked.txt")
        (сам.repo / "new.txt").write_text("удалить\n", encoding="utf-8")
        (сам.repo / ".ignored").mkdir()
        (сам.repo / ".ignored" / "keep.txt").write_text("сохранить\n", encoding="utf-8")

        модуль = load_queue_module()
        план = модуль.план_простого_сброса(
            модуль.resolve_context(сам.repo)
        )
        фраза = модуль.фраза_подтверждения_простого_сброса(план)
        сам.assertIn(исходная_вершина, фраза)
        (код, ответ), вывод = сам.выполнить_простой_сброс(фраза)

        сам.assertEqual(код, 0)
        сам.assertEqual(ответ["состояние"], "сброшено")
        сам.assertIn(исходная_вершина, вывод)
        сам.assertIn(str(состояние["branch_ref"]), вывод)
        сам.assertIn("new.txt", вывод)
        сам.assertIn(ссылки["управление"], вывод)
        сам.assertIn(исходные_объекты["управление"], вывод)
        сам.assertEqual(сам.git("rev-parse", "HEAD").stdout.strip(), исходная_вершина)
        сам.assertEqual((сам.repo / "tracked.txt").read_text(encoding="utf-8"), "initial\n")
        сам.assertFalse((сам.repo / "new.txt").exists())
        сам.assertTrue((сам.repo / ".ignored" / "keep.txt").is_file())
        сам.assertEqual(сам.git("status", "--short").stdout, "")

        после = сам.payload(
            сам.run_queue("status", "--repo-root", str(сам.repo), "--json")
        )
        сам.assertEqual(после["state"], "idle")
        сам.assertIsNone(после["owner"])
        сам.assertEqual(после["waiting"], [])
        сам.assertEqual(после["next_seq"], 1)
        сам.assertNotEqual(после["queue_oid"], исходный_объект_очереди)
        конечная_очередь = json.loads(
            сам.git("cat-file", "blob", str(после["queue_oid"])).stdout
        )
        сам.assertEqual(
            конечная_очередь["текущая_цепочка"],
            текущая_цепочка,
        )

        for имя in (
            "управление",
            "претензия",
            "починка",
            "резервация",
            "аналитика",
            "журнал_завершений",
            "повреждённая_квитанция",
        ):
            сам.assertNotEqual(
                сам.git("rev-parse", "--verify", "--quiet", ссылки[имя], check=False).returncode,
                0,
                имя,
            )
        хэш_ветки = hashlib.sha256(str(после["branch_ref"]).encode("utf-8")).hexdigest()
        основа = f"{после['worktree_id']}/{хэш_ветки}/"
        новая_эпоха = сам.git("rev-parse", "--verify", ссылки["эпоха"]).stdout.strip()
        сам.assertNotEqual(новая_эпоха, исходные_объекты["эпоха"])
        ссылка_границы = f"refs/fum/границы-простого-сброса/{основа[:-1]}"
        объект_границы = сам.git(
            "rev-parse",
            "--verify",
            ссылка_границы,
        ).stdout.strip()
        граница = json.loads(
            сам.git("cat-file", "blob", объект_границы).stdout
        )
        сам.assertEqual(граница["схема"], "fum.граница-простого-сброса.1")
        сам.assertEqual(
            сам.git("rev-parse", "--verify", ссылки["постоянное_доказательство"]).stdout.strip(),
            исходные_объекты["постоянное_доказательство"],
        )
        сам.assertEqual(
            сам.git("rev-parse", "--verify", ссылки["чужая_ветка"]).stdout.strip(),
            исходные_объекты["чужая_ветка"],
        )

        снимки = сам.git(
            "for-each-ref",
            "--format=%(refname) %(objectname)",
            f"refs/fum/снимки-простого-сброса/{основа}",
        ).stdout.splitlines()
        квитанции = сам.git("for-each-ref", "--format=%(objectname)", f"refs/fum/квитанции-простого-сброса/{основа}").stdout.splitlines()
        манифесты = [
            строка for строка in снимки if строка.split()[0].endswith(chr(47) + "манифест")
        ]
        архивные_объекты = {
            строка.split()[1]
            for строка in снимки
            if "объекты" in строка.split()[0].split(chr(47))
        }
        сам.assertEqual(len(манифесты), 1)
        сам.assertEqual(len(квитанции), 1)
        снимок = сам.git(
            "cat-file",
            "blob",
            манифесты[0].split()[1],
        ).stdout
        архивированные = {исходный_объект_очереди}
        архивированные.update(
            объект
            for имя, объект in исходные_объекты.items()
            if имя not in {"постоянное_доказательство", "чужая_ветка"}
        )
        сам.assertLessEqual(архивированные, архивные_объекты)
        for объект in архивированные:
            сам.assertIn(объект, снимок)
        сам.git("reflog", "expire", "--expire=now", "--all")
        сам.git("gc", "--prune=now")
        for объект in архивированные:
            сам.assertEqual(сам.git("cat-file", "-t", объект).stdout.strip(), "blob")

        старое_завершение = сам.finish_clean("owner-task", str(владелец["generation"]))
        сам.assertNotEqual(старое_завершение.returncode, 0)
        старый_повтор, старый_ответ = сам.join("owner-task")
        сам.assertNotEqual(старый_повтор.returncode, 0)
        сам.assertEqual(старый_ответ["state"], "task_annulled_by_simple_reset")
        новый_запуск, новый_владелец = сам.join("autostart-task")
        сам.assertEqual(новый_запуск.returncode, 0, новый_запуск.stderr)
        сам.assertEqual(новый_владелец["base_head"], исходная_вершина)

    def test_корневой_запускатель_исполняет_код_из_текущей_вершины(сам) -> None:
        сам.assertTrue(ПУТЬ_КОРНЕВОГО_СБРОСА.is_file())
        сам.assertTrue(os.access(ПУТЬ_КОРНЕВОГО_СБРОСА, os.X_OK))
        текст = ПУТЬ_КОРНЕВОГО_СБРОСА.read_text(encoding="utf-8")
        сам.assertIn("git','--no-replace-objects'", текст)
        сам.assertIn(SCRIPT_REPO_PATH, текст)

        путь_сценария = сам.repo / SCRIPT_REPO_PATH
        путь_сценария.parent.mkdir(parents=True)
        путь_сценария.write_bytes(SCRIPT_PATH.read_bytes())
        путь_запускателя = сам.repo / "sbrositj.sh"
        путь_запускателя.write_bytes(ПУТЬ_КОРНЕВОГО_СБРОСА.read_bytes())
        путь_запускателя.chmod(0o755)
        сам.git("add", SCRIPT_REPO_PATH, "sbrositj.sh")
        сам.git("commit", "-m", "Add reset launcher fixture")

        ссылки_до = сам.git(
            "for-each-ref",
            "--format=%(refname) %(objectname)",
            "refs/fum/",
        ).stdout
        лишний_аргумент = subprocess.run(
            [str(путь_запускателя), "лишний-аргумент"],
            cwd=сам.repo,
            check=False,
            capture_output=True,
            text=True,
        )

        сам.assertNotEqual(лишний_аргумент.returncode, 0)
        сам.assertEqual(
            сам.git(
                "for-each-ref",
                "--format=%(refname) %(objectname)",
                "refs/fum/",
            ).stdout,
            ссылки_до,
        )

        результат = subprocess.run(
            [str(путь_запускателя)],
            cwd=сам.repo,
            check=False,
            capture_output=True,
            text=True,
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertEqual(json.loads(результат.stdout)["state"], "interactive_terminal_required")


class ТестыПростогоСбросаВРепозиторииСДругимФорматомОбъектов(
    ТестыПростогоСбросаКТекущейВершине
):
    формат_объектов = "sha256"


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
        self.assertIn("`./sbrositj.sh`", agents)
        self.assertIn("--идентификатор-продолжения", agents)
        self.assertIn("`create_thread`", agents)
        self.assertIn("`set_thread_title`", agents)
        self.assertIn("FUM-STEP-NNNN — <краткое содержательное название>", agents)
        self.assertIn("не доказывает маршрут", agents)
        self.assertIn("корневой `.obsidian/`", agents)
        self.assertIn("стартовой маршрутизации", agents)
        self.assertIn("должна оставаться остановленной", agents)
        self.assertIn("HEAD-bootstrap", agents)
        self.assertIn("isolated mode", agents)
        self.assertIn("--no-replace-objects", agents)
        self.assertNotIn("FUM-BRANCH-TASK-GATE", agents)

        skill = SKILL_PATH.read_text(encoding="utf-8")
        self.assertIn("`set_thread_title`", skill)
        self.assertIn("корневой `.obsidian/`", skill)
        self.assertIn("python3 -I -c", skill)
        self.assertIn(HEAD_BOOTSTRAP_CODE, skill)
        self.assertIn("git','--no-replace-objects'", skill)
        self.assertIn("not k.upper().startswith('GIT_')", skill)
        self.assertIn("env=e,timeout=30", skill)
        self.assertIn("'--repo-root',r", skill)
        self.assertIn("Прямой вызов", skill)
        self.assertIn("--timeout-seconds 300", skill)
        self.assertIn("wait-until-actionable", skill)
        self.assertIn("Ручной push пользователя", agents)
        self.assertIn("не предоставляет полномочий", agents)
        self.assertIn("Ручная публикация пользователя", skill)
        self.assertIn("не дают текущей задаче полномочий", skill)
        self.assertIn("не подготавливает push", agents)
        self.assertIn("не выполняет push", skill)
        self.assertIn("Состояние remote не используется как gate готовности", agents)
        self.assertIn("самостоятельным транспортным действием", skill)
        self.assertIn("не входит в причинную цепочку продолжений", skill)

        навык_следующего_шага = (
            REPO_ROOT
            / "Инструменты"
            / "fum-sleduyusjhij-shag-vetki"
            / "SKILL.md"
        ).read_text(encoding="utf-8")
        self.assertIn("`set_thread_title`", навык_следующего_шага)
        self.assertIn("`card_id`", навык_следующего_шага)
        self.assertIn("`title`", навык_следующего_шага)

        self.assertIn("один долгоживущий `wait-until-actionable`", agents)
        self.assertIn("не отправляет промежуточные сообщения", agents)

        heartbeat_prompt = HEARTBEAT_PROMPT_PATH.read_text(encoding="utf-8")
        self.assertIn("больше не является шаблоном prompt", heartbeat_prompt)
        self.assertIn("сохраняются только в истории", heartbeat_prompt)
        self.assertIn("заранее создаёт ровно одну задачу-продолжение", heartbeat_prompt)
        self.assertNotIn("Это пятиминутный тик", heartbeat_prompt)

    def test_успех_комплексной_проверки_сессии_завершается_коммитом_ветки_цепочки(это) -> None:
        правила_агентов = AGENTS_PATH.read_text(encoding="utf-8")
        навык_комплексной_проверки = ПУТЬ_НАВЫКА_КОМПЛЕКСНОЙ_ПРОВЕРКИ.read_text(encoding="utf-8")

        for текст in (правила_агентов, навык_комплексной_проверки):
            это.assertIn(
                "нулевой код внутреннего проверочного процесса",
                текст.casefold(),
            )
            это.assertIn("карточк", текст.casefold())
            это.assertIn("цепоч", текст.casefold())
            это.assertIn("`committed`", текст)
            это.assertIn("commit+handoff", текст)

        это.assertIn("между корневыми задачами", правила_агентов)
        это.assertIn("не переключает ветку", правила_агентов)
        это.assertIn("не выполняет Git-коммит", навык_комплексной_проверки)
        это.assertTrue(ПУТЬ_ИНДЕКСА_КАРТОЧЕК_ЦЕПОЧЕК.is_file())

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
    формат_объектов = "sha256"

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
        self.join("продолжение-sha256")
        self.stage_change("sha256 task\n")
        committed = self.commit(
            "task-a",
            str(owner["generation"]),
            "SHA-256 task",
            "продолжение-sha256",
        )
        self.assertEqual(committed.returncode, 0, committed.stderr)
        ответ = self.payload(committed)
        self.assertEqual(len(str(ответ["new_head"])), 64)
        self.assertRegex(str(ответ["queue_oid"]), r"\A[0-9a-f]{64}\Z")
        ссылка = self.ссылки_квитанций_связанных_коммитов()[0]
        self.assertEqual(len(self.git("rev-parse", ссылка).stdout.strip()), 64)


class ИнвариантыТаймАутаОбвязки(unittest.TestCase):
    def test_тайм_аут_обвязки_превышает_внутренний_Гит_лимит(
        сам,
    ) -> None:
        модуль = load_queue_module()
        сам.assertGreater(60, модуль.GIT_COMMAND_TIMEOUT_SECONDS)


if __name__ == "__main__":
    unittest.main()
