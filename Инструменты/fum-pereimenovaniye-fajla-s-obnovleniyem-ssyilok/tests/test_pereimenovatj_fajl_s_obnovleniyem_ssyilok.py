from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import stat
import subprocess
import sys
import tempfile
import unicodedata
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT = (
    REPO_ROOT
    / "Инструменты"
    / "fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok"
    / "scripts"
    / "pereimenovatj-fajl-s-obnovleniyem-ssyilok.py"
)


class RepositoryFixture:
    def __init__(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.git("init", "-q")
        self.git("config", "user.name", "FUM Test")
        self.git("config", "user.email", "fum-test@example.invalid")

    def close(self) -> None:
        self.temporary.cleanup()

    def git(self, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            check=check,
            capture_output=True,
            text=True,
        )

    def write(self, relative: str, content: str | bytes, mode: int = 0o644) -> Path:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            path.write_bytes(content)
        else:
            path.write_text(content, encoding="utf-8")
        path.chmod(mode)
        return path

    def commit(self) -> None:
        self.git("add", "--all")
        self.git("commit", "-qm", "fixture")

    def run_tool(
        self,
        mode: str,
        source: str,
        destination: str,
        *,
        extra_environment: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        if extra_environment:
            environment.update(extra_environment)
        return subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                mode,
                "--source",
                source,
                "--destination",
                destination,
                "--repo-root",
                str(self.root),
            ],
            cwd=self.root,
            check=False,
            capture_output=True,
            text=True,
            env=environment,
        )


class RenameFileWithLinksTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = RepositoryFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def assert_failed_without_changes(
        self,
        source: str,
        destination: str,
        expected_error: str,
    ) -> None:
        for mode in ("plan", "apply"):
            with self.subTest(mode=mode):
                before = self.fixture.git("status", "--porcelain=v1").stdout
                result = self.fixture.run_tool(mode, source, destination)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertIn(expected_error, result.stderr)
                self.assertEqual(self.fixture.git("status", "--porcelain=v1").stdout, before)
                self.assertTrue((self.fixture.root / source).exists())
                self.assertFalse((self.fixture.root / destination).exists())

    def test_plan_is_deterministic_and_does_not_mutate_worktree_or_index(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        self.fixture.write("index.md", "[old](docs/old.md#top)\n")
        self.fixture.commit()
        git_index = self.fixture.root / ".git" / "index"
        index_bytes = git_index.read_bytes()
        index_mtime = git_index.stat().st_mtime_ns

        first = self.fixture.run_tool("plan", "docs/old.md", "docs/new.md")
        second = self.fixture.run_tool("plan", "docs/old.md", "docs/new.md")

        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(first.stdout, second.stdout)
        payload = json.loads(first.stdout)
        self.assertEqual(payload["mode"], "plan")
        self.assertEqual(payload["source"], "docs/old.md")
        self.assertEqual(payload["destination"], "docs/new.md")
        self.assertEqual(payload["updated_links"], 1)
        self.assertEqual(payload["rewritten_files"], ["index.md"])
        self.assertEqual(payload["updated_files"], ["docs/new.md", "index.md"])
        self.assertEqual(git_index.read_bytes(), index_bytes)
        self.assertEqual(git_index.stat().st_mtime_ns, index_mtime)
        self.assertEqual(self.fixture.git("status", "--porcelain=v1").stdout, "")
        self.assertTrue((self.fixture.root / "docs/old.md").exists())
        self.assertFalse((self.fixture.root / "docs/new.md").exists())

    def test_apply_updates_supported_links_and_rebases_moved_document(self) -> None:
        source_text = (
            "# Old\n\n"
            "[target](../shared/target.md#part)\n"
            "[parenthesized](../shared/target_(x).md)\n"
            "[self](#local)\n"
            "[explicit self](old%20file.md#local)\n"
        )
        incoming_text = (
            "[inline](../docs/area/old%20file.md?view=1#top \"Title\")\n"
            "![image](<../docs/area/old file.md#image>)\n"
            "[reference]: ../docs/area/old%20file.md#ref 'Ref title'\n"
            "[other](../other/old%20file.md)\n"
            "Проза old file.md и подписи ссылок остаются без изменений.\n"
        )
        self.fixture.write("docs/area/old file.md", source_text)
        self.fixture.write("docs/shared/target.md", "# Target\n")
        self.fixture.write("docs/shared/target_(x).md", "# Parenthesized\n")
        self.fixture.write("other/old file.md", "# Other\n")
        self.fixture.write("notes/incoming.md", incoming_text)
        (self.fixture.root / "archive").mkdir()
        self.fixture.commit()

        result = self.fixture.run_tool(
            "apply",
            "docs/area/old file.md",
            "archive/new file.md",
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["mode"], "apply")
        self.assertEqual(payload["updated_links"], 6)
        self.assertFalse((self.fixture.root / "docs/area/old file.md").exists())
        destination = self.fixture.root / "archive/new file.md"
        self.assertTrue(destination.exists())
        self.assertEqual(
            destination.read_text(encoding="utf-8"),
            "# Old\n\n"
            "[target](../docs/shared/target.md#part)\n"
            "[parenthesized](../docs/shared/target_%28x%29.md)\n"
            "[self](#local)\n"
            "[explicit self](new%20file.md#local)\n",
        )
        incoming = (self.fixture.root / "notes/incoming.md").read_text(encoding="utf-8")
        self.assertIn(
            '[inline](../archive/new%20file.md?view=1#top "Title")',
            incoming,
        )
        self.assertIn("![image](<../archive/new file.md#image>)", incoming)
        self.assertIn(
            "[reference]: ../archive/new%20file.md#ref 'Ref title'",
            incoming,
        )
        self.assertIn("[other](../other/old%20file.md)", incoming)
        self.assertIn("Проза old file.md", incoming)
        name_status = self.fixture.git("diff", "--cached", "--name-status").stdout
        self.assertIn("docs/area/old file.md", name_status)
        self.assertIn("archive/new file.md", name_status)

    def test_protected_primary_sources_block_live_link_rewrite(self) -> None:
        cases = {
            "Источники/raw.md": "[raw](../docs/old.md)\n",
            "Запросы/request.md": (
                "# Request\n\n"
                "## Текст запроса\n\n"
                "[verbatim](../docs/old.md)\n\n"
                "## Результат\n\n"
                "Без изменений.\n"
            ),
        }
        for protected_path, protected_text in cases.items():
            with self.subTest(protected_path=protected_path):
                fixture = RepositoryFixture()
                try:
                    fixture.write("docs/old.md", "# Old\n")
                    fixture.write(protected_path, protected_text)
                    fixture.commit()
                    for mode in ("plan", "apply"):
                        result = fixture.run_tool(mode, "docs/old.md", "docs/new.md")
                        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                        self.assertIn("защищ", result.stderr.casefold())
                        self.assertEqual(fixture.git("status", "--porcelain=v1").stdout, "")
                        self.assertTrue((fixture.root / "docs/old.md").exists())
                finally:
                    fixture.close()

    def test_step_card_requires_specialized_rename_command(self) -> None:
        source = "Планирование/карточки-шагов/🟡-FUM-STEP-0001-old.md"
        destination = "Планирование/карточки-шагов/✅-FUM-STEP-0001-new.md"
        self.fixture.write(source, "# Card\n")
        self.fixture.commit()

        self.assert_failed_without_changes(source, destination, "rename-step-card.py")

    def test_unsafe_paths_and_portable_name_collisions_fail_closed(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        self.fixture.write("docs/New.md", "# Occupied\n")
        self.fixture.write("docs/Café.md", "# Unicode collision\n")
        self.fixture.commit()

        cases = (
            ("../escape.md", "repository"),
            (os.sep + "absolute.md", "absolute"),
            ("docs\\windows.md", "backslashes"),
            ("docs/new.md", "collision"),
            (f"docs/{unicodedata.normalize('NFD', 'Café')}.md", "collision"),
            ("docs/New.md", "exists"),
            ("missing/new.md", "parent"),
        )
        for destination, expected in cases:
            with self.subTest(destination=destination):
                for mode in ("plan", "apply"):
                    result = self.fixture.run_tool(mode, "docs/old.md", destination)
                    self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                    self.assertIn(expected, result.stderr.casefold())
                    self.assertEqual(self.fixture.git("status", "--porcelain=v1").stdout, "")

    def test_broken_outgoing_link_and_wikilink_candidate_fail_before_mutation(self) -> None:
        cases = {
            "broken": (
                "# Old\n\n[broken](missing.md)\n",
                "# Index\n",
                "broken",
            ),
            "wikilink": (
                "# Old\n",
                "[[docs/old.md]]\n",
                "wikilink",
            ),
            "case-mismatch": (
                "# Old\n",
                "[old](docs/OLD.md)\n",
                "mismatch",
            ),
        }
        for name, (source_text, index_text, expected) in cases.items():
            with self.subTest(name=name):
                fixture = RepositoryFixture()
                try:
                    fixture.write("docs/old.md", source_text)
                    fixture.write("index.md", index_text)
                    fixture.commit()
                    for mode in ("plan", "apply"):
                        result = fixture.run_tool(mode, "docs/old.md", "docs/new.md")
                        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                        self.assertIn(expected, result.stderr.casefold())
                        self.assertEqual(fixture.git("status", "--porcelain=v1").stdout, "")
                        self.assertTrue((fixture.root / "docs/old.md").exists())
                finally:
                    fixture.close()

    def test_apply_preserves_crlf_and_executable_mode(self) -> None:
        source = self.fixture.write(
            "docs/area/old.md",
            b"# Old\r\n\r\n[target](../shared/target.md)\r\n",
            mode=0o755,
        )
        source_mode = stat.S_IMODE(source.stat().st_mode)
        self.fixture.write("docs/shared/target.md", "# Target\n")
        self.fixture.write("index.md", "[old](docs/area/old.md)\n")
        (self.fixture.root / "archive").mkdir()
        self.fixture.commit()

        result = self.fixture.run_tool("apply", "docs/area/old.md", "archive/new.md")

        self.assertEqual(result.returncode, 0, result.stderr)
        destination = self.fixture.root / "archive/new.md"
        self.assertEqual(
            destination.read_bytes(),
            b"# Old\r\n\r\n[target](../docs/shared/target.md)\r\n",
        )
        self.assertEqual(stat.S_IMODE(destination.stat().st_mode), source_mode)

    def test_non_markdown_source_preserves_bytes_and_is_a_staged_rename(self) -> None:
        original = b"\x00\xffFUM\r\n"
        self.fixture.write("assets/old.bin", original, mode=0o755)
        self.fixture.write(
            "notes/incoming.md",
            "![asset](../assets/old.bin?download=1#raw)\n",
        )
        (self.fixture.root / "archive").mkdir()
        self.fixture.commit()

        result = self.fixture.run_tool("apply", "assets/old.bin", "archive/new.bin")

        self.assertEqual(result.returncode, 0, result.stderr)
        destination = self.fixture.root / "archive/new.bin"
        self.assertEqual(destination.read_bytes(), original)
        self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o755)
        self.assertEqual(
            (self.fixture.root / "notes/incoming.md").read_text(encoding="utf-8"),
            "![asset](../archive/new.bin?download=1#raw)\n",
        )
        name_status = self.fixture.git(
            "diff",
            "--cached",
            "--name-status",
            "--find-renames=100%",
        ).stdout
        self.assertIn("R100\tassets/old.bin\tarchive/new.bin", name_status)

    def test_unrelated_and_code_wikilinks_do_not_block_but_protected_target_does(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        self.fixture.write("other/old.md", "# Other\n")
        self.fixture.write(
            "index.md",
            "[old](docs/old.md)\n"
            "[[other.md]]\n"
            "[[other/old.md]]\n"
            "[[100% ready]]\n"
            "`[[docs/old.md]]`\n"
            "```toml\n[[docs/old.md]]\n```\n"
            "    [indented code](docs/old.md)\n"
            "> ```markdown\n> [quoted code](docs/old.md)\n> ```\n"
            "- ```markdown\n  [listed code](docs/old.md)\n  ```\n",
        )
        self.fixture.commit()

        result = self.fixture.run_tool("apply", "docs/old.md", "docs/new.md")

        self.assertEqual(result.returncode, 0, result.stderr)
        updated = (self.fixture.root / "index.md").read_text(encoding="utf-8")
        self.assertIn("[old](docs/new.md)", updated)
        self.assertIn("[[other.md]]", updated)
        self.assertIn("[[other/old.md]]", updated)
        self.assertIn("[[100% ready]]", updated)
        self.assertIn("`[[docs/old.md]]`", updated)
        self.assertIn("    [indented code](docs/old.md)", updated)
        self.assertIn("> [quoted code](docs/old.md)", updated)
        self.assertIn("  [listed code](docs/old.md)", updated)

        fixture = RepositoryFixture()
        try:
            fixture.write("docs/old.md", "# Old\n")
            fixture.write("Источники/raw.md", "[[docs/old.md]]\n")
            fixture.commit()
            for mode in ("plan", "apply"):
                blocked = fixture.run_tool(mode, "docs/old.md", "docs/new.md")
                self.assertEqual(blocked.returncode, 1, blocked.stdout + blocked.stderr)
                self.assertIn("защищ", blocked.stderr.casefold())
                self.assertEqual(fixture.git("status", "--porcelain=v1").stdout, "")
        finally:
            fixture.close()

    def test_untracked_incoming_link_and_unrelated_dirty_file_are_preserved(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        self.fixture.write("unrelated.md", "# Before\n")
        self.fixture.commit()
        self.fixture.write("notes/untracked.md", "[old](../docs/old.md)\n")
        self.fixture.write("unrelated.md", "# Locally edited\n")

        result = self.fixture.run_tool("apply", "docs/old.md", "docs/new.md")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.fixture.root / "notes/untracked.md").read_text(encoding="utf-8"),
            "[old](../docs/new.md)\n",
        )
        self.assertEqual(
            (self.fixture.root / "unrelated.md").read_text(encoding="utf-8"),
            "# Locally edited\n",
        )

    def test_multiline_inline_and_reference_destinations_are_updated(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        self.fixture.write(
            "index.md",
            "[inline](\n  docs/old.md?view=1#top\n  \"Title\"\n)\n\n"
            "[reference]:\n  docs/old.md#part\n"
            "> [quoted]: docs/old.md#quote\n"
            "- [listed]: docs/old.md#list\n",
        )
        self.fixture.commit()

        result = self.fixture.run_tool("apply", "docs/old.md", "docs/new.md")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.fixture.root / "index.md").read_text(encoding="utf-8"),
            "[inline](\n  docs/new.md?view=1#top\n  \"Title\"\n)\n\n"
            "[reference]:\n  docs/new.md#part\n"
            "> [quoted]: docs/new.md#quote\n"
            "- [listed]: docs/new.md#list\n",
        )

    def test_git_redirection_and_pathspec_magic_cannot_redirect_the_operation(self) -> None:
        self.fixture.write(":(glob).md", "# Literal path\n")
        self.fixture.commit()
        alternate_index = self.fixture.root / "alternate.index"
        alternate_index.write_bytes(b"not a Git index")

        result = self.fixture.run_tool(
            "apply",
            ":(glob).md",
            "renamed.md",
            extra_environment={
                "GIT_DIR": str(self.fixture.root / "missing-git-dir"),
                "GIT_INDEX_FILE": str(alternate_index),
                "GIT_WORK_TREE": str(self.fixture.root / "missing-worktree"),
            },
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.fixture.root / ":(glob).md").exists())
        self.assertTrue((self.fixture.root / "renamed.md").exists())
        self.assertEqual(alternate_index.read_bytes(), b"not a Git index")

    def test_symlink_link_to_source_is_rejected(self) -> None:
        self.fixture.write("assets/old.bin", b"source")
        alias = self.fixture.root / "alias.bin"
        alias.symlink_to("assets/old.bin")
        self.fixture.write("index.md", "[alias](alias.bin)\n")
        self.fixture.commit()

        self.assert_failed_without_changes(
            "assets/old.bin",
            "assets/new.bin",
            "symbolic",
        )

    def test_dirty_source_is_rejected_in_both_modes(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        self.fixture.commit()
        self.fixture.write("docs/old.md", "# Locally edited\n")

        self.assert_failed_without_changes("docs/old.md", "docs/new.md", "source must be clean")
        self.fixture.git("add", "--", "docs/old.md")
        self.assert_failed_without_changes("docs/old.md", "docs/new.md", "source must be clean")

    def test_source_spelling_must_match_exact_case_and_unicode(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        self.fixture.commit()

        result = self.fixture.run_tool("plan", "docs/OLD.md", "docs/new.md")

        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.fixture.git("status", "--porcelain=v1").stdout, "")

    def test_concurrent_inventory_and_index_changes_stop_before_git_mv(self) -> None:
        cases = ("inventory", "index")
        for case in cases:
            with self.subTest(case=case):
                fixture = RepositoryFixture()
                try:
                    fixture.write("docs/old.md", "# Old\n")
                    fixture.write("index.md", "[old](docs/old.md)\n")
                    fixture.write("unrelated.md", "# Before\n")
                    fixture.commit()
                    if case == "index":
                        fixture.write("unrelated.md", "# Locally edited\n")

                    spec = importlib.util.spec_from_file_location(
                        f"fum_rename_concurrent_{case}",
                        SCRIPT,
                    )
                    self.assertIsNotNone(spec)
                    self.assertIsNotNone(spec.loader)
                    module = importlib.util.module_from_spec(spec)
                    sys.modules[spec.name] = module
                    spec.loader.exec_module(module)
                    real_prepare = module.prepare_writes

                    def prepare_then_change(plan: object) -> object:
                        prepared = real_prepare(plan)
                        if case == "inventory":
                            fixture.write("late.md", "# Arrived concurrently\n")
                        else:
                            fixture.git("add", "--", "unrelated.md")
                        return prepared

                    stderr = io.StringIO()
                    with mock.patch.object(
                        module,
                        "prepare_writes",
                        side_effect=prepare_then_change,
                    ):
                        with contextlib.redirect_stderr(stderr):
                            result = module.main(
                                [
                                    "apply",
                                    "--source",
                                    "docs/old.md",
                                    "--destination",
                                    "docs/new.md",
                                    "--repo-root",
                                    str(fixture.root),
                                ]
                            )

                    self.assertEqual(result, 1)
                    expected = "inventory" if case == "inventory" else "exact Git index"
                    self.assertIn(expected, stderr.getvalue())
                    self.assertTrue((fixture.root / "docs/old.md").exists())
                    self.assertFalse((fixture.root / "docs/new.md").exists())
                    self.assertEqual(
                        list(fixture.root.rglob(".fum-rename-*-*")),
                        [],
                    )
                finally:
                    fixture.close()

    def test_install_failure_rolls_back_files_and_git_rename(self) -> None:
        self.fixture.write("docs/old.md", "# Old\n")
        first = self.fixture.write("one.md", "[old](docs/old.md)\n")
        second = self.fixture.write("two.md", "[old](docs/old.md)\n")
        self.fixture.write("staged.md", "# Staged before\n")
        self.fixture.write("unstaged.md", "# Unstaged before\n")
        self.fixture.commit()
        self.fixture.write("staged.md", "# Staged after\n")
        self.fixture.git("add", "--", "staged.md")
        self.fixture.write("unstaged.md", "# Unstaged after\n")
        before_first = first.read_bytes()
        before_second = second.read_bytes()
        before_status = self.fixture.git("status", "--porcelain=v1", "-z").stdout

        spec = importlib.util.spec_from_file_location("fum_rename_file", SCRIPT)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)

        real_replace = os.replace
        calls = 0

        def fail_second_install(source: os.PathLike[str], destination: os.PathLike[str]) -> None:
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError("injected install failure")
            real_replace(source, destination)

        stderr = io.StringIO()
        with mock.patch.object(module.os, "replace", side_effect=fail_second_install):
            with contextlib.redirect_stderr(stderr):
                result = module.main(
                    [
                        "apply",
                        "--source",
                        "docs/old.md",
                        "--destination",
                        "docs/new.md",
                        "--repo-root",
                        str(self.fixture.root),
                    ]
                )

        self.assertEqual(result, 1)
        self.assertIn("rolled back", stderr.getvalue())
        self.assertTrue((self.fixture.root / "docs/old.md").exists())
        self.assertFalse((self.fixture.root / "docs/new.md").exists())
        self.assertEqual(first.read_bytes(), before_first)
        self.assertEqual(second.read_bytes(), before_second)
        self.assertEqual(
            (self.fixture.root / "staged.md").read_text(encoding="utf-8"),
            "# Staged after\n",
        )
        self.assertEqual(
            (self.fixture.root / "unstaged.md").read_text(encoding="utf-8"),
            "# Unstaged after\n",
        )
        self.assertEqual(
            self.fixture.git("status", "--porcelain=v1", "-z").stdout,
            before_status,
        )


if __name__ == "__main__":
    unittest.main()
