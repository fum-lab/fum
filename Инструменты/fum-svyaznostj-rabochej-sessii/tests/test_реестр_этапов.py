import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from contextlib import redirect_stdout
from io import StringIO


СКРИПТЫ = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(СКРИПТЫ))
import реестр_этапов as реестр  # noqa: E402
_СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location(
    "вести_конвейер", СКРИПТЫ / "вести-конвейер.py")
конвейер = importlib.util.module_from_spec(_СПЕЦИФИКАЦИЯ)
sys.modules[_СПЕЦИФИКАЦИЯ.name] = конвейер
_СПЕЦИФИКАЦИЯ.loader.exec_module(конвейер)


ЗАДАЧА = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
ВЫПОЛНИТЕЛЬ = "11111111-2222-4333-8444-555555555555"
ДРУГОЙ_ВЫПОЛНИТЕЛЬ = "22222222-3333-4444-8555-666666666666"
ХЭШ_КОНТРАКТА = hashlib.sha256(b"stage contract v1").hexdigest()


def событие(начало=10, конец=20, текст=b"user message"):
    позиция = {"начало": начало, "конец": конец, "sha256": hashlib.sha256(текст).hexdigest()}
    источник = hashlib.sha256(b"jsonl source prefix").hexdigest()
    экземпляр = hashlib.sha256(реестр.канонические_байты({
        "задача": ЗАДАЧА, "источник": источник, **позиция,
    })).hexdigest()
    return {"задача": ЗАДАЧА, "источник": источник, "экземпляр": экземпляр, "позиция": позиция}


def квитанция(событие_, этап, claim_id, назначение_id="33333333-4444-4555-8666-777777777777"):
    return {"схема": реестр.СХЕМА_КВИТАНЦИИ, "событие": событие_, "этап": этап,
            "контракт": "Планирование/контракты-конвейера/test.json",
            "контракт_sha256": ХЭШ_КОНТРАКТА, "назначение_id": назначение_id,
            "claim_id": claim_id, "исполнитель": ВЫПОЛНИТЕЛЬ, "ref": "refs/heads/codex/worker",
            "база": "a" * 40, "выходы": {"result.txt": hashlib.sha256(b"result").hexdigest()}}


class РеестрЭтаповTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "root"
        self.worker = Path(self.temp.name) / "worker"
        self.second = Path(self.temp.name) / "second"
        self.root.mkdir()
        self.git(self.root, "init", "-b", "fuma")
        self.git(self.root, "config", "user.name", "Codex Test")
        self.git(self.root, "config", "user.email", "codex-test@example.invalid")
        (self.root / "seed.txt").write_text("seed\n")
        self.git(self.root, "add", "seed.txt")
        self.git(self.root, "commit", "-m", "init")

    @staticmethod
    def git(cwd, *args):
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        return subprocess.run(["git", *args], cwd=cwd, env=env, check=True, capture_output=True).stdout

    def assign(self, *, stage="fum/dialog/intake/v1", event=None, owner=ВЫПОЛНИТЕЛЬ):
        event = event or globals()["событие"]()
        contract = f"Планирование/контракты-конвейера/{stage}.json"
        contract_path = self.root / contract
        if not contract_path.exists():
            contract_path.parent.mkdir(parents=True, exist_ok=True)
            contract_path.write_text(f"contract for {stage}\n")
            self.git(self.root, "add", contract)
            self.git(self.root, "commit", "-m", f"contract {stage}")
        output = f"results/{event['экземпляр'][:12]}-{stage.replace('/', '-')}.txt"
        result = реестр.Реестр(self.root).назначить(
            событие=event, этап=stage, контракт=contract,
            исполнитель=owner, выходы=[output],
        )
        self.git(self.root, "add", result["путь"])
        self.git(self.root, "commit", "-m", f"assign {stage}")
        return result

    def add_worker(self, name="codex/worker", path=None, start="fuma"):
        path = path or (self.worker if name == "codex/worker" else self.second)
        self.git(self.root, "worktree", "add", "-b", name, str(path), start)
        return path

    def sync_worker(self, path=None):
        path = path or self.worker
        self.git(path, "merge", "--no-edit", "fuma")
        return path

    def take(self, root=None, assignment=None, owner=ВЫПОЛНИТЕЛЬ):
        root = root or self.worker
        assignment = assignment or self.assign()
        if not root.exists():
            self.add_worker(path=root)
        self.sync_worker(root)
        return реестр.Реестр(root).взять(путь_назначения_=assignment["путь"], исполнитель=owner)

    def test_parallel_linked_worktrees_cannot_claim_same_assignment(self):
        назначение = self.assign()
        первое_дерево = self.add_worker()
        второе_дерево = self.add_worker("codex/worker-two", self.second)
        первое = реестр.Реестр(первое_дерево).взять(
            путь_назначения_=назначение["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)
        self.assertEqual(первое["решение"], "разрешено")
        with self.assertRaises(реестр.ДубликатОбработки):
            реестр.Реестр(второе_дерево).взять(
                путь_назначения_=назначение["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)

    def test_same_event_can_be_assigned_to_a_distinct_downstream_stage(self):
        исходное = событие()
        первое = self.assign(stage="fum/dialog/intake/v1", event=исходное)
        второе = self.assign(stage="fum/requirements/extract/v1", event=исходное)
        worker = self.add_worker()
        self.assertEqual(реестр.Реестр(worker).взять(
            путь_назначения_=первое["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)["решение"], "разрешено")
        self.assertEqual(реестр.Реестр(worker).взять(
            путь_назначения_=второе["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)["решение"], "разрешено")

    def test_identical_text_at_different_source_positions_is_distinct(self):
        первое = self.assign(event=событие(начало=10, конец=20))
        второе = self.assign(event=событие(начало=30, конец=40))
        self.assertNotEqual(первое["назначение_id"], второе["назначение_id"])
        снимок = реестр.проверить_ветки(self.root)
        self.assertEqual(len(снимок["назначения"]), 2)

    def test_assignment_must_be_committed_in_fuma_before_worker_claim(self):
        contract = "Планирование/контракты-конвейера/fum/dialog/intake/v1.json"
        contract_path = self.root / contract
        contract_path.parent.mkdir(parents=True, exist_ok=True)
        contract_path.write_text("contract for fum/dialog/intake/v1\n")
        self.git(self.root, "add", contract)
        self.git(self.root, "commit", "-m", "contract")
        назначение = реестр.Реестр(self.root).назначить(
            событие=событие(), этап="fum/dialog/intake/v1",
            контракт="Планирование/контракты-конвейера/fum/dialog/intake/v1.json",
            исполнитель=ВЫПОЛНИТЕЛЬ,
            выходы=["result.txt"],
        )
        worker = self.add_worker()
        with self.assertRaises(реестр.ОшибкаРеестра):
            реестр.Реестр(worker).взять(
                путь_назначения_=назначение["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)

    def test_interrupted_assignment_resumes_with_same_id(self):
        event = событие()
        stage = "fum/dialog/intake/v1"
        contract = f"Планирование/контракты-конвейера/{stage}.json"
        contract_path = self.root / contract
        contract_path.parent.mkdir(parents=True, exist_ok=True)
        contract_path.write_text("contract\n")
        self.git(self.root, "add", contract)
        self.git(self.root, "commit", "-m", "contract")
        with mock.patch.object(реестр, "записать_атомарно", side_effect=OSError("interrupted")):
            with self.assertRaises(OSError):
                реестр.Реестр(self.root).назначить(
                    событие=event, этап=stage, контракт=contract,
                    исполнитель=ВЫПОЛНИТЕЛЬ, выходы=["result.txt"])
        resumed = реестр.Реестр(self.root).назначить(
            событие=event, этап=stage, контракт=contract,
            исполнитель=ВЫПОЛНИТЕЛЬ, выходы=["result.txt"])
        self.assertEqual(resumed["состояние"], "назначено")
        retried = реестр.Реестр(self.root).назначить(
            событие=event, этап=stage, контракт=contract,
            исполнитель=ВЫПОЛНИТЕЛЬ, выходы=["result.txt"])
        self.assertEqual(retried["назначение_id"], resumed["назначение_id"])
        self.assertEqual(retried["путь"], resumed["путь"])
        self.assertFalse(retried["запускать_работу"])
        self.assertEqual(len(реестр.проверить_ветки(self.root)["назначения"]), 0)

    def test_assignment_retry_after_committed_record_is_a_duplicate_not_new_work(self):
        self.assign()
        with self.assertRaises(реестр.ДубликатОбработки):
            реестр.Реестр(self.root).назначить(
                событие=событие(), этап="fum/dialog/intake/v1",
                контракт="Планирование/контракты-конвейера/fum/dialog/intake/v1.json",
                исполнитель=ВЫПОЛНИТЕЛЬ,
                выходы=[f"results/{событие()['экземпляр'][:12]}-fum-dialog-intake-v1.txt"],
            )

    def test_same_event_and_stage_cannot_be_assigned_twice(self):
        self.assign()
        with self.assertRaises(реестр.ДубликатОбработки):
            self.assign()

    def test_same_owner_can_resume_only_in_the_original_worker_tree(self):
        назначение = self.assign()
        worker = self.add_worker()
        первое = реестр.Реестр(worker).взять(
            путь_назначения_=назначение["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)
        второе = реестр.Реестр(worker).взять(
            путь_назначения_=назначение["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)
        self.assertEqual(второе["решение"], "возобновить-запись")
        self.assertFalse(второе["запускать_повторно"])
        self.assertEqual(первое["claim_id"], второе["claim_id"])

    def test_receipt_is_bound_to_assignment_and_blocks_later_worktrees(self):
        назначение = self.assign()
        worker = self.add_worker()
        резерв = реестр.Реестр(worker).взять(
            путь_назначения_=назначение["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)
        (worker / "results").mkdir()
        (worker / "results" / f"{событие()['экземпляр'][:12]}-fum-dialog-intake-v1.txt").write_text("verified result\n")
        квитанция_результат = реестр.Реестр(worker).подготовить_квитанцию(резерв["claim_id"])
        self.git(worker, "add", "results", квитанция_результат["путь"])
        self.git(worker, "commit", "-m", "result and receipt")
        завершение = реестр.Реестр(worker).завершить(резерв["claim_id"])
        self.assertEqual(завершение["состояние"], "завершён")
        script = Path(конвейер.__file__).resolve()
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        check_command = [sys.executable, "-B", str(script), "проверить",
                         "--корень-репозитория", str(self.root)]
        in_worker = subprocess.run(check_command, cwd=self.root, env=env, text=True, capture_output=True)
        self.assertEqual(in_worker.returncode, 0, in_worker.stderr)
        self.assertEqual(json.loads(in_worker.stdout)["назначения"][0]["состояние"],
                         "результат-в-рабочей-ветке")
        self.git(self.root, "merge", "--no-ff", "--no-edit", "codex/worker")
        in_fuma = subprocess.run(check_command, cwd=self.root, env=env, text=True, capture_output=True)
        self.assertEqual(in_fuma.returncode, 0, in_fuma.stderr)
        self.assertEqual(json.loads(in_fuma.stdout)["назначения"][0]["состояние"],
                         "возвращено-в-fuma")
        второй = self.add_worker("codex/worker-two", self.second)
        with self.assertRaises(реестр.ДубликатОбработки):
            реестр.Реестр(второй).взять(
                путь_назначения_=назначение["путь"], исполнитель=ВЫПОЛНИТЕЛЬ)

    def test_two_completed_runs_for_one_pair_are_rejected(self):
        первое = квитанция(событие(), "fum/dialog/intake/v1",
                            "11111111-2222-4333-8444-555555555555")
        второе = квитанция(событие(), "fum/dialog/intake/v1",
                            "22222222-3333-4444-8555-666666666666")
        with self.assertRaises(реестр.ОшибкаРеестра):
            реестр.проверить_набор_квитанций([первое, второе])

    def test_event_extractor_preserves_selected_source_identity_without_text(self):
        source_event = событие()
        message = {"экземпляр": source_event["экземпляр"],
                   "позиция": source_event["позиция"], "content": "private text"}
        snapshot = {"задача": ЗАДАЧА, "источник": source_event["источник"],
                    "sha256": "b" * 64, "полнота_подтверждена": True,
                    "сообщения": [message]}
        args = type("Args", (), {"экземпляр": [source_event["экземпляр"]],
                                "исходник": Path("/private/source.jsonl"),
                                "codex_thread_id": ЗАДАЧА,
                                "корень_репозитория": self.root,
                                "кэш": None, "перепроверить": False})()
        output = StringIO()
        with mock.patch.object(конвейер, "прочитать_сообщения", return_value=snapshot), redirect_stdout(output):
            код = конвейер._извлечь(args)
        self.assertEqual(код, 0)
        extracted = json.loads(output.getvalue())
        self.assertEqual(extracted["события"], [source_event])
        self.assertNotIn("private text", output.getvalue())

    def test_cli_commits_assignment_record_only_after_explicit_git_commit(self):
        stage = "fum/dialog/intake/v1"
        contract = f"Планирование/контракты-конвейера/{stage}.json"
        contract_path = self.root / contract
        contract_path.parent.mkdir(parents=True, exist_ok=True)
        contract_path.write_text("contract\n")
        self.git(self.root, "add", contract)
        self.git(self.root, "commit", "-m", "contract")
        event_path = Path(self.temp.name) / "event.json"
        event = событие()
        event_path.write_text(json.dumps({
            "схема": "fum.события-конвейера.1",
            "задача": ЗАДАЧА,
            "полнота_подтверждена": True,
            "источник_sha256": "b" * 64,
            "события": [event],
        }, ensure_ascii=False))
        script = Path(конвейер.__file__).resolve()
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        command = [sys.executable, "-B", str(script), "назначить",
                   "--корень-репозитория", str(self.root), "--событие-json", str(event_path),
                   "--экземпляр", event["экземпляр"],
                   "--этап", stage, "--контракт", contract, "--исполнитель", ВЫПОЛНИТЕЛЬ,
                   "--выход", "results/result.txt"]
        result = subprocess.run(command, cwd=self.root, env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        assignment = json.loads(result.stdout)
        self.assertFalse(assignment["запускать_работу"])
        self.assertTrue((self.root / assignment["путь"]).is_file())
        self.git(self.root, "add", assignment["путь"])
        self.git(self.root, "commit", "-m", "assignment")
        check = subprocess.run([sys.executable, "-B", str(script), "проверить",
                                "--корень-репозитория", str(self.root)],
                               cwd=self.root, env=env, text=True, capture_output=True)
        self.assertEqual(check.returncode, 0, check.stderr)
        snapshot = json.loads(check.stdout)
        self.assertEqual(snapshot["число_назначений"], 1)
        self.assertEqual(snapshot["назначения"][0]["состояние"], "назначено")


if __name__ == "__main__":
    unittest.main()
