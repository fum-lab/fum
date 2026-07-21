import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "update-md-recency.py"
)

spec = importlib.util.spec_from_file_location("update_md_recency", SCRIPT_PATH)
update_md_recency = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = update_md_recency
spec.loader.exec_module(update_md_recency)


class UpdateMdRecencyTests(unittest.TestCase):
    def write_fixture(self, root: Path) -> tuple[Path, Path]:
        (root / "Документация").mkdir()
        first = root / "Документация" / "старый-файл.md"
        second = root / "README.md"
        first.write_text("# Старый файл\n\nПервый текст.\n", encoding="utf-8")
        second.write_text("# README\n\nВторой текст.\n", encoding="utf-8")
        return first, second

    def test_updates_markdown_metadata_and_sorted_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first, second = self.write_fixture(root)

            initial = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )
            self.assertEqual(initial.errors, [])

            second.write_text(
                second.read_text(encoding="utf-8").replace(
                    "Второй текст.",
                    "Второй обновлённый текст.",
                ),
                encoding="utf-8",
            )
            updated = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T12:00:00+03:00"),
                use_git=False,
            )

            self.assertEqual(updated.errors, [])
            self.assertIn(
                "<!-- last-content-edit: 2026-06-26 11:00:00 MSK -->",
                first.read_text(encoding="utf-8"),
            )
            self.assertIn(
                "<!-- last-content-edit: 2026-06-26 12:00:00 MSK -->",
                second.read_text(encoding="utf-8"),
            )

            index = root / update_md_recency.INDEX_PATH
            index_text = index.read_text(encoding="utf-8")
            self.assertIn("[README.md](../README.md)", index_text)
            self.assertIn("[Документация/старый-файл.md](../Документация/старый-файл.md)", index_text)
            table_lines = [
                line for line in index_text.splitlines() if line.startswith("| ")
            ]
            pipe_positions = {
                tuple(index for index, char in enumerate(line) if char == "|")
                for line in table_lines[:4]
            }
            self.assertEqual(len(pipe_positions), 1)
            self.assertRegex(table_lines[0], r"^\| Файл\s+\| Последнее содержательное редактирование \|$")
            self.assertLess(
                index_text.index("[README.md]"),
                index_text.index("[Документация/старый-файл.md]"),
            )

    def test_repeated_update_preserves_clean_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first, _second = self.write_fixture(root)

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )
            self.assertEqual(result.errors, [])
            before = first.read_text(encoding="utf-8")

            repeated = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-27T12:00:00+03:00"),
                use_git=False,
            )
            after = first.read_text(encoding="utf-8")

            self.assertEqual(repeated.errors, [])
            self.assertEqual(repeated.changed_paths, [])
            self.assertEqual(before, after)

    def test_ignored_build_and_cache_markdown_files_are_never_rewritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            ignored_files = {
                ".build/checkouts/vendor/README.md": "# Vendor build checkout\n",
                ".swiftpm/cache/README.md": "# SwiftPM cache\n",
                ".obsidian/cache/README.md": "# Obsidian cache\n",
                ".obsidian/plugins/local/README.md": "# Obsidian plugin\n",
                "__pycache__/README.md": "# Python cache\n",
            }
            for relative, content in ignored_files.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )

            self.assertEqual(result.errors, [])
            index_text = (root / update_md_recency.INDEX_PATH).read_text(
                encoding="utf-8"
            )
            for relative, content in ignored_files.items():
                with self.subTest(relative=relative):
                    self.assertEqual(
                        (root / relative).read_text(encoding="utf-8"),
                        content,
                    )
                    self.assertNotIn(relative, index_text)

    def test_check_reports_stale_metadata_after_content_change(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first, _second = self.write_fixture(root)
            update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )

            first.write_text(
                first.read_text(encoding="utf-8").replace(
                    "Первый текст.",
                    "Первый изменённый текст.",
                ),
                encoding="utf-8",
            )
            checked = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T12:00:00+03:00"),
                check=True,
                use_git=False,
            )

            self.assertTrue(
                any("stale recency metadata: Документация/старый-файл.md" in error for error in checked.errors),
                checked.errors,
            )

    def test_rejects_index_symlink_into_build_without_rewriting_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            target = root / ".build" / "vendor-index.md"
            target.parent.mkdir()
            original = "# Vendor index\n"
            target.write_text(original, encoding="utf-8")
            index = root / update_md_recency.INDEX_PATH
            index.parent.mkdir()
            index.symlink_to("../.build/vendor-index.md")

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )

            self.assertTrue(
                any("symlink" in error for error in result.errors),
                result.errors,
            )
            self.assertEqual(target.read_text(encoding="utf-8"), original)

    def test_initializes_clean_tracked_file_from_git_history(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tracked = root / "README.md"
            tracked.write_text("# README\n\nИсторический текст.\n", encoding="utf-8")
            subprocess.run(["git", "init"], cwd=root, check=True, stdout=subprocess.PIPE)
            subprocess.run(["git", "add", "README.md"], cwd=root, check=True)
            env = {
                **os.environ,
                "GIT_AUTHOR_DATE": "2026-01-02T03:04:05+03:00",
                "GIT_COMMITTER_DATE": "2026-01-02T03:04:05+03:00",
            }
            subprocess.run(
                [
                    "git",
                    "-c",
                    "user.name=FUM Test",
                    "-c",
                    "user.email=fum-test@example.invalid",
                    "commit",
                    "-m",
                    "initial",
                ],
                cwd=root,
                check=True,
                env=env,
                stdout=subprocess.PIPE,
            )

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T12:00:00+03:00"),
            )

            self.assertEqual(result.errors, [])
            self.assertIn(
                "<!-- last-content-edit: 2026-01-02 03:04:05 MSK -->",
                tracked.read_text(encoding="utf-8"),
            )


if __name__ == "__main__":
    unittest.main()
