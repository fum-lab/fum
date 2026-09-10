"""Регрессии узкого Git-перехода; высокий допуск проверяется отдельно читателем M."""
import importlib.util
import json
import os
import io
import contextlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SOURCE_ROOT = Path(__file__).resolve().parents[3]
ROOT = Path(os.environ.get("FUM_CHECKED_CODE_ROOT", str(SOURCE_ROOT)))
spec = importlib.util.spec_from_file_location("promotion", ROOT / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/продвинуть_принятое_слияние.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class Продвижение(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="fum-promotion-test-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "repo"
        self.root.mkdir()
        self.g("init", "-b", "master")
        self.g("config", "user.name", "FUM Test")
        self.g("config", "user.email", "test@example.invalid")
        self.g("config", "commit.gpgsign", "false")
        (self.root / ".gitignore").write_text("*.tmp\n.DS_Store\n")
        (self.root / "a.txt").write_text("base\n")
        self.g("add", ".")
        self.g("commit", "-m", "base")
        self.base_commit = self.head()
        self.g("checkout", "-b", "leading")
        (self.root / "b.txt").write_text("leading\n")
        self.g("add", ".")
        self.g("commit", "-m", "leading")
        self.L = self.head()
        self.g("checkout", "master")
        (self.root / "a.txt").write_text("master\n")
        self.g("add", ".")
        self.g("commit", "-m", "master")
        self.M = self.head()
        self.g("checkout", "leading")
        self.g("merge", "--no-ff", "master", "-m", "candidate")
        self.C = self.head()
        self.g("checkout", "master")
        self.transaction_root = self.base / "candidate"
        self.g("worktree", "add", "--detach", str(self.transaction_root), self.C)
        self.intent = self.base / "intent.json"

    def g(self, *args, data=None):
        if data is None:
            return module.git(self.root, *args)
        return subprocess.run(module.команда_git() + list(args), cwd=self.root,
                              env=module.среда(), input=data, capture_output=True,
                              check=True).stdout

    def head(self):
        return module.oid(self.root, "HEAD")

    def run_transition(self, observer=lambda phase: None):
        try:
            return module.перейти(self.root, self.M, self.L, self.C, self.intent, self.transaction_root,
                                 наблюдатель=observer)
        except module.Отказ as error:
            if self.intent.exists():
                error.add_note(json.loads(self.intent.read_text()).get("git_stderr", ""))
            raise

    def test_success_and_read_only_repeat(self):
        (self.root / ".DS_Store").write_bytes(b"local")
        self.assertEqual(self.run_transition()["состояние"], "завершено")
        before = self.intent.read_bytes()
        self.assertEqual(self.head(), self.C)
        module.проверить_копию(self.root, self.C)
        self.assertEqual(self.run_transition()["состояние"], "уже_достигнуто")
        self.assertEqual(self.intent.read_bytes(), before)
        self.assertEqual((self.root / ".DS_Store").read_bytes(), b"local")

    def test_tracked_and_untracked_tail_prevent_writes(self):
        (self.root / "a.txt").write_text("human")
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertFalse(self.intent.exists())
        self.assertEqual(self.head(), self.M)
        self.assertEqual((self.root / "a.txt").read_text(), "human")
        (self.root / "a.txt").write_text("master\n")
        (self.root / "human.txt").write_text("new")
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertFalse(self.intent.exists())

    def test_hidden_index_flags(self):
        for flag, inverse in [("--assume-unchanged", "--no-assume-unchanged"),
                              ("--skip-worktree", "--no-skip-worktree")]:
            self.g("update-index", flag, "a.txt")
            with self.assertRaises(module.Отказ):
                self.run_transition()
            self.g("update-index", inverse, "a.txt")
        self.assertEqual(self.head(), self.M)

    def test_changed_master_before_transaction(self):
        def race(phase):
            if phase == "до_транзакции":
                self.g("update-ref", "refs/heads/master", self.base_commit, self.M)
        with self.assertRaises(module.Отказ):
            self.run_transition(race)
        self.assertEqual(self.head(), self.base_commit)
        self.assertEqual((self.root / "a.txt").read_text(), "master\n")

    def test_changed_symbolic_head_before_transaction(self):
        self.g("branch", "other", self.M)
        def race(phase):
            if phase == "до_транзакции":
                self.g("symbolic-ref", "HEAD", "refs/heads/other")
        with self.assertRaises(module.Отказ):
            self.run_transition(race)
        self.assertEqual(self.g("symbolic-ref", "HEAD").strip(), b"refs/heads/other")
        self.assertEqual(module.oid(self.root, "master"), self.M)

    def test_changed_target_after_preflight_is_not_overwritten(self):
        def race(phase):
            if phase == "до_read_tree":
                (self.root / "b.txt").write_text("human")
        with self.assertRaises(module.Отказ):
            self.run_transition(race)
        self.assertEqual(self.head(), self.M)
        self.assertEqual((self.root / "b.txt").read_text(), "human")

    def test_partial_checkout_failure_keeps_ref_and_data(self):
        original = module.git
        def failing(root, *args):
            if args[:1] == ("read-tree",):
                (root / "a.txt").write_text("partial")
                raise module.Отказ("injected read-tree failure")
            return original(root, *args)
        with patch.object(module, "git", failing), self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertEqual(self.head(), self.M)
        self.assertEqual((self.root / "a.txt").read_text(), "partial")
        self.assertEqual(json.loads(self.intent.read_text())["состояние"], "требуется_разбор")

    def test_new_tail_after_commit_keeps_committed_ref(self):
        def race(phase):
            if phase == "после_commit":
                (self.root / "a.txt").write_text("human after commit")
        with self.assertRaises(module.Отказ):
            self.run_transition(race)
        self.assertEqual(self.head(), self.C)
        self.assertEqual((self.root / "a.txt").read_text(), "human after commit")

    def test_uncertain_committed_transaction_is_not_rolled_back(self):
        original = module.ответ
        def uncertain(process, phase):
            original(process, phase)
            if phase == b"commit":
                raise TimeoutError("injected lost acknowledgement")
        with patch.object(module, "ответ", uncertain), self.assertRaises(TimeoutError):
            self.run_transition()
        self.assertEqual(self.head(), self.C)
        module.проверить_копию(self.root, self.C)
        self.assertEqual(self.run_transition()["состояние"], "уже_достигнуто")

    def test_target_attributes_refused(self):
        original = module.дерево
        def changed(root, ref):
            d = original(root, ref)
            if ref == self.C:
                d[".gitattributes"] = ("100644", "0" * 40)
            return d
        with patch.object(module, "дерево", changed), self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertEqual(self.head(), self.M)

    def test_casefolded_ignored_collision(self):
        (self.root / ".git/info/exclude").write_text("B.TXT\n")
        (self.root / "B.TXT").write_text("human ignored")
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertFalse(self.intent.exists())
        self.assertEqual((self.root / "B.TXT").read_text(), "human ignored")

    def test_repeat_requires_original_intent(self):
        self.run_transition()
        self.intent.unlink()
        with self.assertRaises(module.Отказ):
            self.run_transition()

    def test_ignored_attributes_refused_before_filter(self):
        (self.root / ".git/info/exclude").write_text(".gitattributes\n")
        (self.root / ".gitattributes").write_text("b.txt filter=danger\n")
        self.g("config", "filter.danger.smudge", "touch invoked; cat")
        self.g("config", "filter.danger.clean", "cat")
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertFalse(self.intent.exists())
        self.assertFalse((self.root / "invoked").exists())
        (self.root / ".gitattributes").unlink()
        (self.root / ".git/info/exclude").write_text(".GITATTRIBUTES\n")
        (self.root / ".GITATTRIBUTES").write_text("b.txt filter=danger\n")
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertFalse(self.intent.exists())
        self.assertFalse((self.root / "invoked").exists())

    def add_dependency(self):
        dep = self.root / "dep"
        dep.mkdir()
        module.git(dep, "init", "-b", "master")
        module.git(dep, "config", "user.name", "FUM Test")
        module.git(dep, "config", "user.email", "test@example.invalid")
        module.git(dep, "config", "commit.gpgsign", "false")
        (dep / "source.txt").write_text("source")
        module.git(dep, "add", ".")
        module.git(dep, "commit", "-m", "dependency")
        value = module.oid(dep, "HEAD")
        self.g("update-index", "--add", "--cacheinfo", "160000", value, "dep")
        tree_m = self.g("write-tree").decode().strip()
        self.M = self.g("commit-tree", tree_m, "-p", self.M, "-m", "dependency").decode().strip()
        self.g("update-ref", "refs/heads/master", self.M)
        self.g("read-tree", self.C)
        self.g("update-index", "--add", "--cacheinfo", "160000", value, "dep")
        tree_c = self.g("write-tree").decode().strip()
        self.C = self.g("commit-tree", tree_c, "-p", self.L, "-p", self.M, "-m", "merge dependency").decode().strip()
        self.g("reset", "--hard", self.M)
        return dep

    def test_dirty_dependency_refused(self):
        dep = self.add_dependency()
        (dep / "source.txt").write_text("changed")
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertFalse(self.intent.exists())
        self.assertEqual((dep / "source.txt").read_text(), "changed")

    def test_symlink_dependency_refused(self):
        dep = self.add_dependency()
        outside = self.base / "materialized"
        dep.rename(outside)
        dep.symlink_to(outside, target_is_directory=True)
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertFalse(self.intent.exists())
        self.assertTrue(dep.is_symlink())

    def test_empty_subtree_refused(self):
        empty = self.g("mktree", data=b"").decode().strip()
        listing = self.g("ls-tree", self.C) + ("040000 tree " + empty + "\tempty\n").encode()
        tree = self.g("mktree", data=listing).decode().strip()
        self.C = self.g("commit-tree", tree, "-p", self.L, "-p", self.M, "-m", "empty tree").decode().strip()
        with self.assertRaises(module.Отказ):
            self.run_transition()
        self.assertEqual(self.head(), self.M)
        self.assertFalse(self.intent.exists())

    def cli(self):
        return ["продвинуть-master.py", "--корень", str(self.root), "--M", self.M,
                "--L", self.L, "--C", self.C, "--intent", str(self.intent),
                "--кандидат", str(self.transaction_root), "--запрос", "Журнал/test/запрос.md"]

    def test_cli_refuses_missing_trusted_reader(self):
        with patch.object(module.sys, "argv", self.cli()), self.assertRaises(module.Отказ):
            module.main()
        self.assertFalse(self.intent.exists())
        self.assertEqual(self.head(), self.M)

    def test_cli_repeat_does_not_reload_candidate_reader(self):
        self.run_transition()
        before = self.intent.read_bytes()
        output = io.StringIO()
        with patch.object(module.sys, "argv", self.cli()), contextlib.redirect_stdout(output):
            module.main()
        self.assertEqual(json.loads(output.getvalue())["состояние"], "уже_достигнуто")
        self.assertEqual(self.intent.read_bytes(), before)

    def test_head_is_locked_during_checkout(self):
        self.g("branch", "other", self.M)
        def check(phase):
            if phase == "до_read_tree":
                with self.assertRaises(module.Отказ):
                    self.g("symbolic-ref", "HEAD", "refs/heads/other")
        self.assertEqual(self.run_transition(check)["состояние"], "завершено")
        self.assertEqual(self.g("symbolic-ref", "HEAD").strip(), b"refs/heads/master")

    def test_reflog_preserves_configured_global_identity(self):
        self.g("config", "--unset", "user.name")
        self.g("config", "--unset", "user.email")
        (self.base / ".gitconfig").write_text("[user]\n name = FUM Global Test\n email = global@example.invalid\n")
        with patch.dict(os.environ, {"HOME": str(self.base), "XDG_CONFIG_HOME": str(self.base / "xdg")}):
            self.assertEqual(self.run_transition()["состояние"], "завершено")
        line = (self.root / ".git/logs/refs/heads/master").read_text().splitlines()[-1]
        self.assertTrue("FUM Global Test <global@example.invalid>" in line)


if __name__ == "__main__":
    unittest.main()
