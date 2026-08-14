import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "project_files.py"
)

spec = importlib.util.spec_from_file_location("project_files", SCRIPT_PATH)
project_files = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = project_files
spec.loader.exec_module(project_files)


class ProjectFilesTests(unittest.TestCase):
    def test_normalizes_only_repository_relative_portable_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            document = root / "Документация" / "источник.md"
            document.parent.mkdir()
            document.write_text("# Источник\n", encoding="utf-8")

            self.assertEqual(
                project_files.normalized_project_relative_path(
                    "Документация/источник.md",
                    root,
                    field_name="source.path",
                    must_exist=True,
                ),
                "Документация/источник.md",
            )

            rejected = (
                document.as_posix(),
                "../внешний.md",
                "Документация/../источник.md",
                "Документация\\источник.md",
                "C:\\repo\\источник.md",
                "C:/repo/источник.md",
                "\\\\server\\share\\источник.md",
                "file:///repo/источник.md",
                "~",
                "~/repo/источник.md",
                "~user/repo/источник.md",
                "$HOME/repo/источник.md",
                "${HOME}/repo/источник.md",
                "%USERPROFILE%\\repo\\источник.md",
                "$env:USERPROFILE\\repo\\источник.md",
            )
            for value in rejected:
                with self.subTest(value=value):
                    with self.assertRaises(project_files.ProjectFilesError):
                        project_files.normalized_project_relative_path(
                            value,
                            root,
                            field_name="source.path",
                            must_exist=False,
                        )

    def test_repository_relative_path_rejects_symlink_escape(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            outside = root.parent / f"{root.name}-outside"
            outside.mkdir()
            self.addCleanup(lambda: outside.rmdir())
            (root / "Документация").symlink_to(outside, target_is_directory=True)

            with self.assertRaises(project_files.ProjectFilesError):
                project_files.normalized_project_relative_path(
                    "Документация/источник.md",
                    root,
                    field_name="source.path",
                    must_exist=False,
                )

    def test_git_policy_includes_project_markdown_and_excludes_ignored_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            subprocess.run(
                ["git", "init"],
                cwd=root,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            (root / ".gitignore").write_text(
                ".build/\n.swiftpm/\nlocal-cache/\n/.obsidian/\n",
                encoding="utf-8",
            )
            tracked = root / "README.md"
            tracked.write_text("# Tracked\n", encoding="utf-8")
            subprocess.run(
                ["git", "add", ".gitignore", "README.md"],
                cwd=root,
                check=True,
            )
            (root / ".git" / "info" / "exclude").write_text(
                "README.md\n",
                encoding="utf-8",
            )
            untracked = root / "Документация" / "новый.md"
            untracked.parent.mkdir()
            untracked.write_text("# Untracked project file\n", encoding="utf-8")
            ignored = {
                ".build/checkouts/vendor/README.md",
                ".swiftpm/cache/README.md",
                "local-cache/README.md",
                ".obsidian/local/README.md",
            }
            for relative in ignored:
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("# Ignored\n", encoding="utf-8")
            subprocess.run(
                [
                    "git",
                    "add",
                    "-f",
                    ".build/checkouts/vendor/README.md",
                    "local-cache/README.md",
                    ".obsidian/local/README.md",
                ],
                cwd=root,
                check=True,
            )

            paths = project_files.project_markdown_paths(root)
            relatives = {
                path.relative_to(root.resolve()).as_posix()
                for path in paths
            }

            self.assertEqual(
                relatives,
                {"README.md", "Документация/новый.md"},
            )
            self.assertTrue(ignored.isdisjoint(relatives))

    def test_filesystem_fallback_uses_the_same_structural_exclusions(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            included = root / "Документация" / "проектный.md"
            included.parent.mkdir()
            included.write_text("# Project\n", encoding="utf-8")
            ignored_paths = [
                root / ".build" / "checkouts" / "vendor" / "README.md",
                root / ".obsidian" / "plugins" / "local" / "README.md",
                root / ".obsidian" / "local" / "README.md",
            ]
            for ignored in ignored_paths:
                ignored.parent.mkdir(parents=True)
                ignored.write_text("# Ignored\n", encoding="utf-8")

            paths = project_files.project_markdown_paths(root)

            self.assertEqual(paths, [included.resolve()])

    def test_корневое_исключение_обсидиана_требует_точного_регистра(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            документ_с_иным_регистром = корень / ".Obsidian" / "README.md"
            документ_с_иным_регистром.parent.mkdir()
            документ_с_иным_регистром.write_text(
                "# Не корневой .obsidian\n",
                encoding="utf-8",
            )

            пути = project_files.project_markdown_paths(корень, use_git=False)

            сам.assertEqual(пути, [документ_с_иным_регистром.resolve()])

    def test_rejects_tracked_path_with_symlink_parent_into_build_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            subprocess.run(
                ["git", "init"],
                cwd=root,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            docs = root / "Docs"
            docs.mkdir()
            tracked = docs / "README.md"
            tracked.write_text("# Tracked\n", encoding="utf-8")
            subprocess.run(
                ["git", "add", "Docs/README.md"],
                cwd=root,
                check=True,
            )
            tracked.unlink()
            docs.rmdir()
            build_target = root / ".build" / "README.md"
            build_target.parent.mkdir()
            build_target.write_text("# Build target\n", encoding="utf-8")
            docs.symlink_to(".build", target_is_directory=True)

            with self.assertRaises(project_files.ProjectFilesError):
                project_files.project_markdown_paths(root)

            self.assertEqual(
                build_target.read_text(encoding="utf-8"),
                "# Build target\n",
            )

    def test_filesystem_walk_error_is_not_silently_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            def failing_walk(*_args, onerror=None, **_kwargs):
                assert onerror is not None
                onerror(PermissionError("fixture denied"))
                return iter(())

            with mock.patch.object(project_files.os, "walk", failing_walk):
                with self.assertRaises(project_files.ProjectFilesError):
                    project_files.project_markdown_paths(root, use_git=False)

    def test_missing_skip_worktree_markdown_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            subprocess.run(
                ["git", "init"],
                cwd=root,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            tracked = root / "README.md"
            tracked.write_text("# Tracked\n", encoding="utf-8")
            subprocess.run(["git", "add", "README.md"], cwd=root, check=True)
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
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            subprocess.run(
                ["git", "update-index", "--skip-worktree", "README.md"],
                cwd=root,
                check=True,
            )
            tracked.unlink()

            with self.assertRaises(project_files.ProjectFilesError):
                project_files.project_markdown_paths(root)


if __name__ == "__main__":
    unittest.main()
