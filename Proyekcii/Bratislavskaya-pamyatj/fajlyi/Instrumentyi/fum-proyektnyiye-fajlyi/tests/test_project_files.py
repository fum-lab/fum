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
    def test_normalizes_only_repository_relative_portable_paths(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            document = корень / "Документация" / "источник.md"
            document.parent.mkdir()
            document.write_text("# Источник\n", encoding="utf-8")

            сам.assertEqual(
                project_files.normalized_project_relative_path(
                    "Документация/источник.md",
                    корень,
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
                with сам.subTest(value=value):
                    with сам.assertRaises(project_files.ProjectFilesError):
                        project_files.normalized_project_relative_path(
                            value,
                            корень,
                            field_name="source.path",
                            must_exist=False,
                        )

    def test_repository_relative_path_rejects_symlink_escape(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            outside = корень.parent / f"{корень.name}-outside"
            outside.mkdir()
            сам.addCleanup(lambda: outside.rmdir())
            (корень / "Документация").symlink_to(outside, target_is_directory=True)

            with сам.assertRaises(project_files.ProjectFilesError):
                project_files.normalized_project_relative_path(
                    "Документация/источник.md",
                    корень,
                    field_name="source.path",
                    must_exist=False,
                )

    def test_git_policy_includes_project_markdown_and_excludes_ignored_files(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            subprocess.run(
                ["git", "init"],
                cwd=корень,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            (корень / ".gitignore").write_text(
                ".build/\n.swiftpm/\nlocal-cache/\n",
                encoding="utf-8",
            )
            tracked = корень / "README.md"
            tracked.write_text("# Tracked\n", encoding="utf-8")
            subprocess.run(
                ["git", "add", ".gitignore", "README.md"],
                cwd=корень,
                check=True,
            )
            (корень / ".git" / "info" / "exclude").write_text(
                "README.md\n",
                encoding="utf-8",
            )
            untracked = корень / "Документация" / "новый.md"
            untracked.parent.mkdir()
            untracked.write_text("# Untracked project file\n", encoding="utf-8")
            ignored = {
                ".build/checkouts/vendor/README.md",
                ".swiftpm/cache/README.md",
                "local-cache/README.md",
            }
            for relative in ignored:
                путь = корень / relative
                путь.parent.mkdir(parents=True, exist_ok=True)
                путь.write_text("# Ignored\n", encoding="utf-8")
            subprocess.run(
                [
                    "git",
                    "add",
                    "-f",
                    ".build/checkouts/vendor/README.md",
                    "local-cache/README.md",
                ],
                cwd=корень,
                check=True,
            )

            пути = project_files.project_markdown_paths(корень)
            относительные_пути = {
                путь.relative_to(корень.resolve()).as_posix()
                for путь in пути
            }

            сам.assertEqual(
                относительные_пути,
                {"README.md", "Документация/новый.md"},
            )
            сам.assertTrue(ignored.isdisjoint(относительные_пути))

    def test_filesystem_fallback_uses_the_same_structural_exclusions(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            included = корень / "Документация" / "проектный.md"
            included.parent.mkdir()
            included.write_text("# Project\n", encoding="utf-8")
            ignored_paths = [
                корень / ".build" / "checkouts" / "vendor" / "README.md",
                корень / ".obsidian" / "plugins" / "local" / "README.md",
            ]
            for ignored in ignored_paths:
                ignored.parent.mkdir(parents=True)
                ignored.write_text("# Ignored\n", encoding="utf-8")

            пути = project_files.project_markdown_paths(корень)

            сам.assertEqual(пути, [included.resolve()])

    def test_производная_проекция_не_входит_в_канонический_маркдаун_инвентарь(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            subprocess.run(
                ["git", "init"],
                cwd=корень,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            канонический_файл = корень / "Документация" / "источник.md"
            канонический_файл.parent.mkdir()
            канонический_файл.write_text("# Источник\n", encoding="utf-8")
            проекция = корень / "Proyekcii" / "Bratislavskaya-pamyatj" / "fajlyi" / "Dokumentaciya" / "istochnik.md"
            проекция.parent.mkdir(parents=True)
            проекция.write_text("# Istochnik\n", encoding="utf-8")
            вложенное_близкое_имя = корень / "Документация" / "Proyekcii" / "nested.md"
            вложенное_близкое_имя.parent.mkdir(parents=True)
            вложенное_близкое_имя.write_text("# Nested\n", encoding="utf-8")
            subprocess.run(
                ["git", "add", "Документация/источник.md", "Proyekcii"],
                cwd=корень,
                check=True,
            )

            пути = project_files.project_markdown_paths(корень)
            относительные_пути = {
                путь.relative_to(корень.resolve()).as_posix()
                for путь in пути
            }

            сам.assertEqual(
                относительные_пути,
                {
                    "Документация/источник.md",
                    "Документация/Proyekcii/nested.md",
                },
            )
            сам.assertFalse(
                project_files.is_structurally_excluded("proyekcii/lowercase.md")
            )

    def test_rejects_tracked_path_with_symlink_parent_into_build_directory(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            subprocess.run(
                ["git", "init"],
                cwd=корень,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            docs = корень / "Docs"
            docs.mkdir()
            tracked = docs / "README.md"
            tracked.write_text("# Tracked\n", encoding="utf-8")
            subprocess.run(
                ["git", "add", "Docs/README.md"],
                cwd=корень,
                check=True,
            )
            tracked.unlink()
            docs.rmdir()
            build_target = корень / ".build" / "README.md"
            build_target.parent.mkdir()
            build_target.write_text("# Build target\n", encoding="utf-8")
            docs.symlink_to(".build", target_is_directory=True)

            with сам.assertRaises(project_files.ProjectFilesError):
                project_files.project_markdown_paths(корень)

            сам.assertEqual(
                build_target.read_text(encoding="utf-8"),
                "# Build target\n",
            )

    def test_filesystem_walk_error_is_not_silently_ignored(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)

            def failing_walk(*_args, onerror=None, **_kwargs):
                assert onerror is not None
                onerror(PermissionError("fixture denied"))
                return iter(())

            with mock.patch.object(project_files.os, "walk", failing_walk):
                with сам.assertRaises(project_files.ProjectFilesError):
                    project_files.project_markdown_paths(корень, use_git=False)

    def test_missing_skip_worktree_markdown_fails_closed(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            subprocess.run(
                ["git", "init"],
                cwd=корень,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            tracked = корень / "README.md"
            tracked.write_text("# Tracked\n", encoding="utf-8")
            subprocess.run(["git", "add", "README.md"], cwd=корень, check=True)
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
                cwd=корень,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            subprocess.run(
                ["git", "update-index", "--skip-worktree", "README.md"],
                cwd=корень,
                check=True,
            )
            tracked.unlink()

            with сам.assertRaises(project_files.ProjectFilesError):
                project_files.project_markdown_paths(корень)


if __name__ == "__main__":
    unittest.main()
