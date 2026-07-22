import contextlib
import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


AUTOMATION_DIR = Path(__file__).resolve().parents[1]
SCRIPT_PATH = (
    AUTOMATION_DIR
    / "scripts"
    / "proveritj-mashinno-lokaljnyiye-puti.py"
)
SCRIPTS_DIR = AUTOMATION_DIR / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

spec = importlib.util.spec_from_file_location(
    "proveritj_mashinno_lokaljnyiye_puti",
    SCRIPT_PATH,
)
scanner = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = scanner
spec.loader.exec_module(scanner)


class MachineLocalPathScannerTests(unittest.TestCase):
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

    def write_policy(
        self,
        root: Path,
        exceptions: list[dict[str, object]] | None = None,
    ) -> Path:
        path = root / "policy.json"
        path.write_text(
            json.dumps(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": exceptions or [],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        return path

    def scan(self, root: Path, policy: Path | None = None):
        policy_path = policy or self.write_policy(root)
        return scanner.scan_repository(root, policy_path)

    def write_and_add(self, root: Path, relative: str, text: str) -> Path:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        subprocess.run(["git", "add", relative], cwd=root, check=True)
        return path

    def test_scans_cached_and_untracked_nonignored_files_in_stable_order(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "Документация/б.md",
                "/Users/example/work/FUM\n",
            )
            untracked = root / "Документация" / "а.md"
            untracked.write_text("D:/work/FUM/config.json\n", encoding="utf-8")
            ignored = root / "ignored" / "скрытый.md"
            ignored.parent.mkdir()
            ignored.write_text("/Users/example/hidden\n", encoding="utf-8")

            result = self.scan(root)

            self.assertEqual(
                result.rendered_lines(),
                (
                    "Документация/а.md:1:error.windows-drive",
                    "Документация/б.md:1:error.posix-user-home",
                ),
            )
            self.assertEqual(result.exit_code, 1)
            rendered = "\n".join(result.rendered_lines())
            self.assertNotIn("example", rendered)
            self.assertNotIn("config.json", rendered)
            self.assertNotIn("скрытый", rendered)

    def test_request_text_and_external_sources_are_report_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "Запросы/2026-07-22_00-00-00_MSK_fixture.md",
                "# Запрос\n\n"
                "## Текст запроса\n\n"
                "```text\n"
                "/Users/example/source\n"
                "## Заголовок внутри fence\n"
                "```\n\n"
                "## Результат\n\n"
                "/Users/example/active\n",
            )
            self.write_and_add(
                root,
                "Источники/URL/https/example.test/raw.txt",
                r"C:\Users\Example\archive" + "\n",
            )

            result = self.scan(root)

            self.assertIn(
                "Запросы/2026-07-22_00-00-00_MSK_fixture.md:6:report.request-text.posix-user-home",
                result.rendered_lines(),
            )
            self.assertIn(
                "Запросы/2026-07-22_00-00-00_MSK_fixture.md:12:error.posix-user-home",
                result.rendered_lines(),
            )
            self.assertIn(
                "Источники/URL/https/example.test/raw.txt:1:report.external-source.windows-drive",
                result.rendered_lines(),
            )
            self.assertEqual(result.exit_code, 1)

    def test_narrow_system_fixture_url_and_gitignore_categories(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "Инструменты/реестр-системных-приложений-и-инструментов.md",
                "`/usr/bin/git` и `/Applications/ChatGPT.app`\n",
            )
            self.write_and_add(
                root,
                "Инструменты/demo/scripts/tool.py",
                "#!/usr/bin/env python3\n",
            )
            self.write_and_add(
                root,
                "Инструменты/demo/tests/test_fixture.py",
                "ROOT = '/repo'\nURI = 'file://localhost/private/material.html'\n",
            )
            self.write_and_add(
                root,
                "Документация/url.md",
                "https://example.test/a/b\n",
            )
            (root / ".gitignore").write_text(
                "ignored/\n/build/output/\n",
                encoding="utf-8",
            )

            fixture_lines = {
                "ROOT = '/repo'": "posix-absolute",
                "URI = 'file://localhost/private/material.html'": "file-uri",
            }
            policy = self.write_policy(
                root,
                [
                    {
                        "id": f"fixture-{index}",
                        "path": "Инструменты/demo/tests/test_fixture.py",
                        "kind": kind,
                        "line_sha256": "sha256:"
                        + hashlib.sha256(line.encode("utf-8")).hexdigest(),
                        "count": 1,
                        "category": "allow.test-fixture",
                        "reason": "Закрепляет точную автономную тестовую фикстуру без расширения области.",
                    }
                    for index, (line, kind) in enumerate(fixture_lines.items(), start=1)
                ],
            )

            result = self.scan(root, policy)

            lines = result.rendered_lines()
            self.assertIn(
                "Инструменты/реестр-системных-приложений-и-инструментов.md:1:allow.system-runtime",
                lines,
            )
            self.assertIn(
                "Инструменты/demo/scripts/tool.py:1:allow.system-runtime",
                lines,
            )
            self.assertIn(
                "Инструменты/demo/tests/test_fixture.py:1:allow.test-fixture.posix-absolute",
                lines,
            )
            self.assertIn(
                "Инструменты/demo/tests/test_fixture.py:2:allow.test-fixture.file-uri",
                lines,
            )
            self.assertIn(".gitignore:2:allow.gitignore-anchor", lines)
            self.assertFalse(
                any(line.startswith("Документация/url.md:") for line in lines)
            )
            self.assertEqual(result.exit_code, 0)

    def test_system_runtime_literal_in_first_party_code_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "Инструменты/demo/scripts/tool.py",
                "COMMAND = '/usr/bin/git'\n",
            )

            result = self.scan(root)

            self.assertEqual(
                result.rendered_lines(),
                ("Инструменты/demo/scripts/tool.py:1:error.system-runtime-hardcode",),
            )
            self.assertEqual(result.exit_code, 1)

    def test_first_party_file_path_is_rejected_but_documented_reference_is_typed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "Прототипы/demo/Sources/App.swift",
                "let source = #filePath\nlet portable = #fileID\n",
            )
            self.write_and_add(
                root,
                "Документация/compiler.md",
                "Ограничение upstream связано с `#filePath`.\n",
            )

            result = self.scan(root)

            self.assertIn(
                "Прототипы/demo/Sources/App.swift:1:error.compiler-file-path",
                result.rendered_lines(),
            )
            self.assertIn(
                "Документация/compiler.md:1:report.compiler-file-path-reference",
                result.rendered_lines(),
            )
            self.assertEqual(result.exit_code, 1)

    def test_exact_historical_exception_uses_line_hash_count_and_reason(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            line = "Историческое доказательство: /Users/example/work/FUM"
            relative = "Ревью/исторический-аудит.md"
            self.write_and_add(root, relative, line + "\n")
            fingerprint = "sha256:" + hashlib.sha256(line.encode("utf-8")).hexdigest()
            policy = self.write_policy(
                root,
                [
                    {
                        "id": "historical-audit-evidence",
                        "path": relative,
                        "kind": "posix-user-home",
                        "line_sha256": fingerprint,
                        "count": 1,
                        "category": "report.historical",
                        "reason": "Сохраняет доказательство прежнего аудита без расширения области.",
                    }
                ],
            )

            result = self.scan(root, policy)

            self.assertEqual(
                result.rendered_lines(),
                (f"{relative}:1:report.historical.posix-user-home",),
            )
            self.assertEqual(result.exit_code, 0)

    def test_changed_or_unused_historical_exception_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            relative = "Ревью/исторический-аудит.md"
            self.write_and_add(
                root,
                relative,
                "Изменённое доказательство: /Users/example/work/FUM\n",
            )
            old_line = "Историческое доказательство: /Users/example/work/FUM"
            policy = self.write_policy(
                root,
                [
                    {
                        "id": "historical-audit-evidence",
                        "path": relative,
                        "kind": "posix-user-home",
                        "line_sha256": "sha256:"
                        + hashlib.sha256(old_line.encode("utf-8")).hexdigest(),
                        "count": 1,
                        "category": "report.historical",
                        "reason": "Сохраняет доказательство прежнего аудита без расширения области.",
                    }
                ],
            )

            result = self.scan(root, policy)

            self.assertIn(
                f"{relative}:1:error.posix-user-home",
                result.rendered_lines(),
            )
            self.assertIn(
                "policy.json:0:error.policy-count-mismatch",
                result.rendered_lines(),
            )
            self.assertEqual(result.exit_code, 2)

    def test_policy_rejects_unknown_fields_wildcards_and_large_counts(self) -> None:
        base = {
            "id": "bad-exception",
            "path": "Ревью/*.md",
            "kind": "posix-user-home",
            "line_sha256": "sha256:" + "a" * 64,
            "count": 17,
            "category": "allow.everything",
            "reason": "Намеренно невалидная слишком широкая тестовая запись.",
            "unknown": True,
        }

        with self.assertRaises(scanner.PolicyError):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": [base],
                }
            )

    def test_policy_rejects_unknown_category(self) -> None:
        exception = {
            "id": "unknown-category",
            "path": "Инструменты/demo/tests/test_fixture.py",
            "kind": "posix-absolute",
            "line_sha256": "sha256:" + "a" * 64,
            "count": 1,
            "category": "allow.arbitrary-directory",
            "reason": "Проверяет закрытый список типизированных категорий политики.",
        }

        with self.assertRaisesRegex(scanner.PolicyError, "unsupported category"):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": [exception],
                }
            )

    def test_policy_rejects_duplicate_fingerprint_across_categories(self) -> None:
        base = {
            "path": "Инструменты/demo/tests/test_fixture.py",
            "kind": "posix-absolute",
            "line_sha256": "sha256:" + "b" * 64,
            "count": 1,
            "reason": "Проверяет запрет неоднозначной повторной типизации одного отпечатка.",
        }
        exceptions = [
            {
                **base,
                "id": "duplicate-fixture",
                "category": "allow.test-fixture",
            },
            {
                **base,
                "id": "duplicate-definition",
                "category": "allow.path-validation-definition",
            },
        ]

        with self.assertRaisesRegex(scanner.PolicyError, "duplicates a fingerprint"):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": exceptions,
                }
            )

    def test_legacy_v1_policy_is_rejected(self) -> None:
        with self.assertRaisesRegex(scanner.PolicyError, "unsupported policy schema"):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v1",
                    "exceptions": [],
                }
            )

    def test_exact_policy_preserves_definition_and_fixture_categories(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            cases = (
                (
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/example.py",
                    "PATTERN = '/custom/definition/path'",
                    "allow.path-validation-definition",
                ),
                (
                    "Инструменты/demo/tests/test_example.py",
                    "FIXTURE = '~alice/private/project'",
                    "allow.test-fixture",
                ),
            )
            exceptions = []
            for index, (relative, line, category) in enumerate(cases, start=1):
                self.write_and_add(root, relative, line + "\n")
                exceptions.append(
                    {
                        "id": f"typed-example-{index}",
                        "path": relative,
                        "kind": "posix-absolute"
                        if index == 1
                        else "home-expansion",
                        "line_sha256": "sha256:"
                        + hashlib.sha256(line.encode("utf-8")).hexdigest(),
                        "count": 1,
                        "category": category,
                        "reason": "Закрепляет одну точную строку определения или тестовой фикстуры.",
                    }
                )

            result = self.scan(root, self.write_policy(root, exceptions))

            self.assertEqual(
                result.rendered_lines(),
                (
                    "Инструменты/demo/tests/test_example.py:1:allow.test-fixture.home-expansion",
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/example.py:1:allow.path-validation-definition.posix-absolute",
                ),
            )
            self.assertEqual(result.exit_code, 0)

    def test_unfingerprinted_scanner_branch_and_test_literals_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            cases = (
                (
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/regression.py",
                    "LEAK = '/custom/private/scanner-checkout'\n",
                    "error.posix-absolute",
                ),
                (
                    "Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py",
                    "LEAK = '$env:USERPROFILE\\branch-checkout'\n",
                    "error.home-expansion",
                ),
                (
                    "Инструменты/demo/tests/test_leak.py",
                    "LEAK = '//server/share/private-tests'\n",
                    "error.windows-unc",
                ),
                (
                    "Инструменты/demo/scripts/blockquote-leak.py",
                    "LEAK = '>/custom/private/checkout'\n",
                    "error.posix-absolute",
                ),
            )
            for relative, text, _category in cases:
                self.write_and_add(root, relative, text)

            result = self.scan(root)

            self.assertEqual(
                result.rendered_lines(),
                tuple(
                    f"{relative}:1:{category}"
                    for relative, _text, category in sorted(cases)
                ),
            )
            self.assertEqual(result.exit_code, 1)

    def test_cli_returns_one_and_emits_only_stable_redacted_findings(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.init_repo(root)
            self.write_and_add(
                root,
                "Документация/регрессия.md",
                "/Users/private-name/secret-project\n",
            )
            policy = self.write_policy(root)
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                exit_code = scanner.main(
                    [
                        "--repo-root",
                        str(root),
                        "--policy",
                        str(policy),
                    ]
                )

            self.assertEqual(exit_code, 1)
            self.assertEqual(
                stdout.getvalue(),
                "Документация/регрессия.md:1:error.posix-user-home\n",
            )
            self.assertEqual(stderr.getvalue(), "")
            self.assertNotIn("private-name", stdout.getvalue())
            self.assertNotIn("secret-project", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()
