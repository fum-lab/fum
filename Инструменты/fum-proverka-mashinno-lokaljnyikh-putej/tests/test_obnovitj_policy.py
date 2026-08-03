import contextlib
import hashlib
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


AUTOMATION_DIR = Path(__file__).resolve().parents[1]
SCRIPT_PATH = AUTOMATION_DIR / "scripts" / "obnovitj-policy.py"
SCRIPTS_DIR = AUTOMATION_DIR / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

spec = importlib.util.spec_from_file_location("obnovitj_policy", SCRIPT_PATH)
updater = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = updater
spec.loader.exec_module(updater)


class PolicyUpdaterTests(unittest.TestCase):
    def init_repo(self, root: Path) -> None:
        subprocess.run(
            ["git", "init"],
            cwd=root,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        (root / ".gitignore").write_text("ignored/\n", encoding="utf-8")
        subprocess.run(["git", "add", ".gitignore"], cwd=root, check=True)

    def write_and_add(self, root: Path, relative: str, text: str) -> Path:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        subprocess.run(["git", "add", relative], cwd=root, check=True)
        return path

    def write_json(self, path: Path, value: object, *, canonical: bool = True) -> None:
        if canonical:
            text = json.dumps(value, ensure_ascii=False, indent=2) + "\n"
        else:
            text = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
        path.write_text(text, encoding="utf-8")

    def write_policy(
        self,
        root: Path,
        exceptions: list[dict[str, object]] | None = None,
    ) -> Path:
        path = root / "policy.json"
        self.write_json(
            path,
            {
                "schema": "fum.machine-local-path-policy.v2",
                "exceptions": exceptions or [],
            },
        )
        return path

    def declaration(
        self,
        *,
        identifier: str = "fixture-private-root",
        path: str = "tests/fixture.py",
        line: int = 1,
        category: str = "allow.test-fixture",
    ) -> dict[str, object]:
        return {
            "id": identifier,
            "path": path,
            "line": line,
            "category": category,
            "reason": (
                "Закрепляет одну явно выбранную автономную "
                "тестовую строку без расширения области."
            ),
        }

    def test_computes_fingerprint_kind_and_count_then_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            line = "FIXTURE = '/private/example'"
            self.write_and_add(root, "tests/fixture.py", f"{line}\n{line}\n")
            policy = self.write_policy(root)

            added = updater.update_policy(
                root,
                policy,
                [self.declaration()],
            )

            self.assertEqual(added, 1)
            value = json.loads(policy.read_text(encoding="utf-8"))
            self.assertEqual(
                value["exceptions"],
                [
                    {
                        "id": "fixture-private-root",
                        "path": "tests/fixture.py",
                        "kind": "posix-absolute",
                        "line_sha256": "sha256:"
                        + hashlib.sha256(line.encode("utf-8")).hexdigest(),
                        "count": 2,
                        "category": "allow.test-fixture",
                        "reason": (
                            "Закрепляет одну явно выбранную автономную "
                            "тестовую строку без расширения области."
                        ),
                    }
                ],
            )
            before = policy.read_bytes()
            before_stat = policy.stat()
            self.assertEqual(
                updater.update_policy(root, policy, [self.declaration()]),
                0,
            )
            self.assertEqual(policy.read_bytes(), before)
            self.assertEqual(policy.stat().st_ino, before_stat.st_ino)
            self.assertEqual(policy.stat().st_mtime_ns, before_stat.st_mtime_ns)

    def test_rejects_ambiguous_line_and_non_error_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "tests/fixture.py",
                "VALUES = ('\x2fprivate/example', '\x7ealice/example')\n",
            )
            policy = self.write_policy(root)
            with self.assertRaisesRegex(updater.UpdateError, "ambiguous"):
                updater.update_policy(root, policy, [self.declaration()])

            self.write_and_add(
                root,
                "tests/fixture.py",
                "URL = 'https://example.test/a/b'\n",
            )
            with self.assertRaisesRegex(updater.UpdateError, "active error"):
                updater.update_policy(root, policy, [self.declaration()])

    def test_rejects_escape_wildcard_unknown_category_and_bad_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(root, "tests/fixture.py", "ROOT = '/private/example'\n")
            policy = self.write_policy(root)
            cases = (
                ({**self.declaration(), "path": "../fixture.py"}, "normalized"),
                ({**self.declaration(), "path": "tests/*.py"}, "exact"),
                ({**self.declaration(), "path": "tests/cafe\u0301.py"}, "canonical"),
                ({**self.declaration(), "category": "allow.everything"}, "category"),
                ({**self.declaration(), "line": True}, "line"),
                ({**self.declaration(), "unknown": "field"}, "fields"),
            )
            for declaration, message in cases:
                with self.subTest(message=message):
                    with self.assertRaisesRegex(updater.UpdateError, message):
                        updater.update_policy(root, policy, [declaration])

    def test_rejects_symlinked_target_and_symlinked_parent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            policy = self.write_policy(root)
            real = root / "real"
            real.mkdir()
            (real / "fixture.py").write_text(
                "ROOT = '/private/example'\n",
                encoding="utf-8",
            )
            os.symlink(real / "fixture.py", root / "fixture-link.py")
            os.symlink(real, root / "parent-link")

            for path in ("fixture-link.py", "parent-link/fixture.py"):
                with self.subTest(path=path):
                    declaration = self.declaration(path=path)
                    with self.assertRaisesRegex(updater.UpdateError, "symlink"):
                        updater.update_policy(root, policy, [declaration])

    def test_rejects_identifier_and_fingerprint_collisions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            line = "ROOT = '/private/example'"
            self.write_and_add(root, "tests/fixture.py", line + "\n")
            digest = "sha256:" + hashlib.sha256(line.encode("utf-8")).hexdigest()
            base = {
                "id": "existing-fence",
                "path": "tests/fixture.py",
                "kind": "posix-absolute",
                "line_sha256": digest,
                "count": 1,
                "category": "allow.test-fixture",
                "reason": (
                    "Закрепляет одну точную автономную тестовую строку "
                    "без расширения области."
                ),
            }
            policy = self.write_policy(root, [base])

            with self.assertRaisesRegex(updater.UpdateError, "identifier collision"):
                updater.update_policy(
                    root,
                    policy,
                    [
                        self.declaration(
                            identifier="existing-fence",
                            category="report.historical",
                        )
                    ],
                )
            with self.assertRaisesRegex(updater.UpdateError, "fingerprint collision"):
                updater.update_policy(
                    root,
                    policy,
                    [self.declaration(identifier="other-fence")],
                )

    def test_updates_same_named_fence_when_its_scope_is_unchanged(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            line = "ROOT = '/private/current'"
            self.write_and_add(root, "tests/fixture.py", line + "\n")
            reason = self.declaration()["reason"]
            policy = self.write_policy(
                root,
                [
                    {
                        "id": "fixture-private-root",
                        "path": "tests/fixture.py",
                        "kind": "posix-absolute",
                        "line_sha256": "sha256:" + "a" * 64,
                        "count": 1,
                        "category": "allow.test-fixture",
                        "reason": reason,
                    }
                ],
            )

            self.assertEqual(
                updater.update_policy(root, policy, [self.declaration()]),
                1,
            )
            exception = json.loads(policy.read_text(encoding="utf-8"))["exceptions"][0]
            self.assertEqual(
                exception["line_sha256"],
                "sha256:" + hashlib.sha256(line.encode("utf-8")).hexdigest(),
            )
            self.assertEqual(exception["kind"], "posix-absolute")
            self.assertEqual(exception["count"], 1)

    def test_manifest_and_policy_must_be_canonical(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(root, "tests/fixture.py", "ROOT = '/private/example'\n")
            policy = self.write_policy(root)
            manifest = root / "manifest.json"
            manifest_value = {
                "schema": "fum.machine-local-path-policy-update.v1",
                "declarations": [self.declaration()],
            }
            self.write_json(manifest, manifest_value, canonical=False)
            with self.assertRaisesRegex(updater.UpdateError, "manifest.*canonical"):
                updater.load_manifest(manifest)

            self.write_json(manifest, manifest_value)
            declarations = updater.load_manifest(manifest)
            self.assertEqual(len(declarations), 1)

            value = json.loads(policy.read_text(encoding="utf-8"))
            self.write_json(policy, value, canonical=False)
            with self.assertRaisesRegex(updater.UpdateError, "policy.*canonical"):
                updater.update_policy(root, policy, declarations)

    def test_cli_accepts_one_explicit_json_declaration(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "tests/fixture.py",
                "ROOT = '\x2fprivate/cli'\n",
            )
            policy = self.write_policy(root)
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                exit_code = updater.main(
                    [
                        "--repo-root",
                        str(root),
                        "--policy",
                        str(policy),
                        "--declaration",
                        json.dumps(self.declaration(), ensure_ascii=False),
                    ]
                )

            self.assertEqual(exit_code, 0)
            self.assertEqual(stdout.getvalue(), "policy.updated: changes=1\n")
            self.assertEqual(stderr.getvalue(), "")

    def test_v2_manifest_exactly_retires_duplicate_before_safe_update(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            line = "ROOT = '\x2fprivate/current'"
            self.write_and_add(root, "tests/fixture.py", line + "\n")
            current_hash = (
                "sha256:" + hashlib.sha256(line.encode("utf-8")).hexdigest()
            )
            reason = self.declaration()["reason"]
            duplicate = {
                "id": "fixture-duplicate",
                "path": "tests/fixture.py",
                "kind": "posix-absolute",
                "line_sha256": current_hash,
                "count": 1,
                "category": "allow.test-fixture",
                "reason": "Закрепляет точный временный дубликат для безопасного удаления.",
            }
            policy = self.write_policy(
                root,
                [
                    {
                        "id": "fixture-private-root",
                        "path": "tests/fixture.py",
                        "kind": "posix-absolute",
                        "line_sha256": "sha256:" + "a" * 64,
                        "count": 1,
                        "category": "allow.test-fixture",
                        "reason": reason,
                    },
                    duplicate,
                ],
            )
            manifest = root / "manifest.json"
            self.write_json(
                manifest,
                {
                    "schema": "fum.machine-local-path-policy-update.v2",
                    "declarations": [self.declaration()],
                    "retirements": [duplicate],
                },
            )

            plan = updater.load_update_plan(manifest)
            before_failure = policy.read_bytes()
            with self.assertRaisesRegex(updater.UpdateError, "retirement mismatch"):
                updater.update_policy(
                    root,
                    policy,
                    plan.declarations,
                    retirements=[
                        {
                            **duplicate,
                            "reason": (
                                "Намеренно изменённая причина не должна разрешать "
                                "удаление другой записи политики."
                            ),
                        }
                    ],
                )
            self.assertEqual(policy.read_bytes(), before_failure)
            self.assertEqual(
                updater.update_policy(
                    root,
                    policy,
                    plan.declarations,
                    retirements=plan.retirements,
                ),
                2,
            )
            value = json.loads(policy.read_text(encoding="utf-8"))
            self.assertEqual(len(value["exceptions"]), 1)
            self.assertEqual(value["exceptions"][0]["id"], "fixture-private-root")
            self.assertEqual(value["exceptions"][0]["line_sha256"], current_hash)
            before = policy.read_bytes()
            before_stat = policy.stat()
            self.assertEqual(
                updater.update_policy(
                    root,
                    policy,
                    plan.declarations,
                    retirements=plan.retirements,
                ),
                0,
            )
            self.assertEqual(policy.read_bytes(), before)
            self.assertEqual(policy.stat().st_ino, before_stat.st_ino)
            self.assertEqual(policy.stat().st_mtime_ns, before_stat.st_mtime_ns)


if __name__ == "__main__":
    unittest.main()
