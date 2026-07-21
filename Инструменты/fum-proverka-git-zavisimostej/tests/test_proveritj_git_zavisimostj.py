import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


AUTOMATION_DIR = Path(__file__).resolve().parents[1]
SCRIPT_PATH = AUTOMATION_DIR / "scripts" / "proveritj-git-zavisimostj.py"

spec = importlib.util.spec_from_file_location(
    "proveritj_git_zavisimostj",
    SCRIPT_PATH,
)
proveritj_git_zavisimostj = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = proveritj_git_zavisimostj
spec.loader.exec_module(proveritj_git_zavisimostj)


def run_git(*arguments: str, cwd: Path | None = None) -> str:
    result = subprocess.run(
        ["git", *arguments],
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


class GitDependencyFixture:
    def __init__(self, root: Path):
        self.root = root
        self.namespace = root / "namespace"
        self.upstream_namespace = root / "source"
        self.namespace.mkdir()
        self.upstream_namespace.mkdir()
        self.fum_origin = self.namespace / "fum.git"
        self.upstream = self.upstream_namespace / "Primer.git"
        self.fork = self.namespace / "Primer.git"
        self.seed = root / "seed"
        self.superproject = root / "superproject"
        self.path = "Зависимости/Primer"

        run_git("init", "--bare", str(self.fum_origin))
        run_git("init", "--bare", str(self.upstream))
        run_git("init", str(self.seed))
        run_git("config", "user.name", "FUM Test", cwd=self.seed)
        run_git("config", "user.email", "fum-test@example.invalid", cwd=self.seed)

        (self.seed / "README.md").write_text("# Первая ревизия\n", encoding="utf-8")
        run_git("add", "README.md", cwd=self.seed)
        run_git("commit", "-m", "Первая ревизия", cwd=self.seed)
        self.first_revision = run_git("rev-parse", "HEAD", cwd=self.seed)

        (self.seed / "README.md").write_text("# Вторая ревизия\n", encoding="utf-8")
        run_git("add", "README.md", cwd=self.seed)
        run_git("commit", "-m", "Вторая ревизия", cwd=self.seed)
        self.second_revision = run_git("rev-parse", "HEAD", cwd=self.seed)
        run_git("remote", "add", "origin", str(self.upstream), cwd=self.seed)
        run_git("push", "-u", "origin", "HEAD:master", cwd=self.seed)
        run_git("symbolic-ref", "HEAD", "refs/heads/master", cwd=self.upstream)

        run_git("clone", "--bare", str(self.upstream), str(self.fork))
        run_git("symbolic-ref", "HEAD", "refs/heads/master", cwd=self.fork)

        run_git("init", str(self.superproject))
        run_git("config", "user.name", "FUM Test", cwd=self.superproject)
        run_git(
            "config",
            "user.email",
            "fum-test@example.invalid",
            cwd=self.superproject,
        )
        (self.superproject / "README.md").write_text(
            "# Основной репозиторий\n",
            encoding="utf-8",
        )
        run_git("add", "README.md", cwd=self.superproject)
        run_git("commit", "-m", "Начальное состояние", cwd=self.superproject)
        run_git(
            "remote",
            "add",
            "origin",
            str(self.fum_origin),
            cwd=self.superproject,
        )
        run_git("push", "-u", "origin", "HEAD:master", cwd=self.superproject)
        run_git("symbolic-ref", "HEAD", "refs/heads/master", cwd=self.fum_origin)

    def dependency_spec(
        self,
        *,
        revision: str | None = None,
    ) -> "proveritj_git_zavisimostj.DependencySpec":
        return proveritj_git_zavisimostj.DependencySpec(
            fork_url=str(self.fork),
            upstream_url=str(self.upstream),
            path=self.path,
            revision=revision or self.first_revision,
        )

    def add_dependency(
        self,
        *,
        revision: str | None = None,
    ) -> list[str]:
        return proveritj_git_zavisimostj.materialize_dependency(
            self.superproject,
            self.dependency_spec(revision=revision),
        )


class GitDependencyAutomationTests(unittest.TestCase):
    def test_materializes_and_validates_fork_backed_submodule_offline(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))

            errors = fixture.add_dependency()

            self.assertEqual(errors, [])
            dependency = fixture.superproject / fixture.path
            self.assertEqual(
                run_git("rev-parse", "HEAD", cwd=dependency),
                fixture.first_revision,
            )
            self.assertEqual(
                run_git("remote", "get-url", "origin", cwd=dependency),
                str(fixture.fork),
            )
            self.assertEqual(
                run_git("remote", "get-url", "upstream", cwd=dependency),
                str(fixture.upstream),
            )
            self.assertEqual(
                run_git(
                    "config",
                    "-f",
                    ".gitmodules",
                    f"--get",
                    f"submodule.{fixture.path}.fumUpstream",
                    cwd=fixture.superproject,
                ),
                str(fixture.upstream),
            )
            self.assertEqual(
                proveritj_git_zavisimostj.validate_dependency(
                    fixture.superproject,
                    fixture.dependency_spec(),
                ),
                [],
            )

    def test_add_is_idempotent_for_exact_existing_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))

            self.assertEqual(fixture.add_dependency(), [])
            self.assertEqual(fixture.add_dependency(), [])

    def test_allows_unrelated_superproject_changes(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            (fixture.superproject / "unrelated.tmp").write_text(
                "не относится к зависимости\n",
                encoding="utf-8",
            )

            self.assertEqual(fixture.add_dependency(), [])

    def test_rejects_fork_outside_current_fum_namespace(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            outsider_namespace = fixture.root / "outsider"
            outsider_namespace.mkdir()
            outsider_fork = outsider_namespace / "Primer.git"
            run_git("clone", "--bare", str(fixture.upstream), str(outsider_fork))
            dependency_spec = fixture.dependency_spec()
            wrong_namespace = proveritj_git_zavisimostj.DependencySpec(
                fork_url=str(outsider_fork),
                upstream_url=dependency_spec.upstream_url,
                path=dependency_spec.path,
                revision=dependency_spec.revision,
            )

            errors = proveritj_git_zavisimostj.materialize_dependency(
                fixture.superproject,
                wrong_namespace,
            )

            self.assertTrue(
                any("рядом" in error or "владел" in error for error in errors),
                errors,
            )
            self.assertFalse((fixture.superproject / fixture.path).exists())

    def test_rejects_revision_not_published_by_fork(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            (fixture.seed / "README.md").write_text(
                "# Только upstream\n",
                encoding="utf-8",
            )
            run_git("add", "README.md", cwd=fixture.seed)
            run_git("commit", "-m", "Только upstream", cwd=fixture.seed)
            unpublished = run_git("rev-parse", "HEAD", cwd=fixture.seed)
            run_git("push", "origin", "HEAD:master", cwd=fixture.seed)

            errors = fixture.add_dependency(revision=unpublished)

            self.assertTrue(
                any("не достижима из origin" in error for error in errors),
                errors,
            )
            self.assertFalse((fixture.superproject / fixture.path).exists())
            self.assertFalse((fixture.superproject / ".gitmodules").exists())

    def test_rejects_changed_gitmodules_url_and_remote_roles(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency = fixture.superproject / fixture.path
            run_git(
                "config",
                "-f",
                ".gitmodules",
                f"submodule.{fixture.path}.url",
                str(fixture.upstream),
                cwd=fixture.superproject,
            )
            run_git("remote", "set-url", "origin", str(fixture.upstream), cwd=dependency)

            errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )

            self.assertTrue(any(".gitmodules" in error for error in errors), errors)
            self.assertTrue(any("remote origin" in error for error in errors), errors)

    def test_rejects_wrong_head_gitlink_and_dirty_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency = fixture.superproject / fixture.path
            run_git("checkout", "--detach", fixture.second_revision, cwd=dependency)
            run_git("add", fixture.path, cwd=fixture.superproject)
            (dependency / "local.tmp").write_text("локальное состояние\n", encoding="utf-8")

            errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )

            self.assertTrue(any("HEAD" in error for error in errors), errors)
            self.assertTrue(any("gitlink" in error for error in errors), errors)
            self.assertTrue(any("не чист" in error for error in errors), errors)

    def test_rejects_unsafe_path_and_non_distinct_remotes_before_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            unsafe = proveritj_git_zavisimostj.DependencySpec(
                fork_url=str(fixture.fork),
                upstream_url=str(fixture.fork),
                path="../outside",
                revision=fixture.first_revision,
            )

            errors = proveritj_git_zavisimostj.materialize_dependency(
                fixture.superproject,
                unsafe,
            )

            self.assertTrue(any("путь" in error for error in errors), errors)
            self.assertTrue(any("различ" in error for error in errors), errors)
            self.assertFalse((fixture.root / "outside").exists())

    def test_rejects_same_normalized_github_repository_and_owner(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            run_git(
                "remote",
                "set-url",
                "origin",
                "https://github.com/fum-lab/fum.git",
                cwd=fixture.superproject,
            )
            dependency_spec = proveritj_git_zavisimostj.DependencySpec(
                fork_url="https://github.com/fum-lab/Primer.git",
                upstream_url="https://github.com/fum-lab/Primer",
                path=fixture.path,
                revision=fixture.first_revision,
            )

            errors = proveritj_git_zavisimostj.validate_repository_topology(
                fixture.superproject,
                dependency_spec,
            )

            self.assertTrue(
                any("один GitHub-репозиторий" in error for error in errors),
                errors,
            )
            self.assertTrue(
                any("владельцы" in error and "различ" in error for error in errors),
                errors,
            )

    def test_rejects_same_github_owner_even_when_names_differ(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            run_git(
                "remote",
                "set-url",
                "origin",
                "https://github.com/fum-lab/fum.git",
                cwd=fixture.superproject,
            )
            dependency_spec = proveritj_git_zavisimostj.DependencySpec(
                fork_url="https://github.com/fum-lab/Primer.git",
                upstream_url="https://github.com/fum-lab/Drugoj-Primer.git",
                path=fixture.path,
                revision=fixture.first_revision,
            )

            errors = proveritj_git_zavisimostj.validate_repository_topology(
                fixture.superproject,
                dependency_spec,
            )

            self.assertTrue(
                any("владельцы" in error and "различ" in error for error in errors),
                errors,
            )

    def test_rejects_non_public_https_github_upstream_urls(self):
        invalid_upstream_urls = (
            "https://token@github.com/Roman-Kerimov/Primer.git",
            "ssh://git@github.com/Roman-Kerimov/Primer.git",
            "git@github.com:Roman-Kerimov/Primer.git",
        )
        for upstream_url in invalid_upstream_urls:
            with self.subTest(upstream_url=upstream_url), tempfile.TemporaryDirectory() as tmp:
                fixture = GitDependencyFixture(Path(tmp))
                run_git(
                    "remote",
                    "set-url",
                    "origin",
                    "https://github.com/fum-lab/fum.git",
                    cwd=fixture.superproject,
                )
                dependency_spec = proveritj_git_zavisimostj.DependencySpec(
                    fork_url="https://github.com/fum-lab/Primer.git",
                    upstream_url=upstream_url,
                    path=fixture.path,
                    revision=fixture.first_revision,
                )

                errors = proveritj_git_zavisimostj.validate_repository_topology(
                    fixture.superproject,
                    dependency_spec,
                )

                self.assertTrue(
                    any(
                        "URL upstream" in error
                        and "HTTPS URL GitHub" in error
                        for error in errors
                    ),
                    errors,
                )

    def test_rejects_extra_and_misdirected_fetch_and_push_urls(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency = fixture.superproject / fixture.path
            run_git(
                "remote",
                "set-url",
                "--add",
                "origin",
                str(fixture.upstream),
                cwd=dependency,
            )
            run_git(
                "remote",
                "set-url",
                "--add",
                "--push",
                "origin",
                str(fixture.fork),
                cwd=dependency,
            )
            run_git(
                "remote",
                "set-url",
                "--add",
                "--push",
                "origin",
                str(fixture.upstream),
                cwd=dependency,
            )
            run_git(
                "remote",
                "set-url",
                "--add",
                "--push",
                "upstream",
                str(fixture.fork),
                cwd=dependency,
            )

            errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )

            self.assertTrue(
                any("remote origin fetch URL" in error for error in errors),
                errors,
            )
            self.assertTrue(
                any("remote origin push URL" in error for error in errors),
                errors,
            )
            self.assertTrue(
                any("remote upstream push URL" in error for error in errors),
                errors,
            )

    def test_add_rejects_modified_tracked_gitmodules_before_preflight(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            gitmodules = fixture.superproject / ".gitmodules"
            indexed_content = (
                '[submodule "Poljzovatelj"]\n'
                "\tpath = Poljzovatelj\n"
                "\turl = /tmp/poljzovatelj.git\n"
            )
            working_content = indexed_content + "# незавершённая правка\n"
            gitmodules.write_text(indexed_content, encoding="utf-8")
            run_git("add", ".gitmodules", cwd=fixture.superproject)
            gitmodules.write_text(working_content, encoding="utf-8")

            with mock.patch.object(
                proveritj_git_zavisimostj,
                "preflight_dependency",
                return_value=["вызвана сетевая проверка"],
            ) as preflight:
                errors = fixture.add_dependency()

            preflight.assert_not_called()
            self.assertTrue(
                any("предшествующ" in error and ".gitmodules" in error for error in errors),
                errors,
            )
            self.assertEqual(
                run_git("show", ":.gitmodules", cwd=fixture.superproject),
                indexed_content.strip(),
            )
            self.assertEqual(gitmodules.read_text(encoding="utf-8"), working_content)

    def test_add_rejects_untracked_gitmodules_before_preflight(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            gitmodules = fixture.superproject / ".gitmodules"
            gitmodules.write_text("# незавершённая правка\n", encoding="utf-8")

            with mock.patch.object(
                proveritj_git_zavisimostj,
                "preflight_dependency",
                return_value=["вызвана сетевая проверка"],
            ) as preflight:
                errors = fixture.add_dependency()

            preflight.assert_not_called()
            self.assertTrue(
                any("предшествующ" in error and ".gitmodules" in error for error in errors),
                errors,
            )
            self.assertEqual(
                gitmodules.read_text(encoding="utf-8"),
                "# незавершённая правка\n",
            )

    def test_cli_check_validates_existing_dependency_without_fetch(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency_spec = fixture.dependency_spec()

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "check",
                    "--repo-root",
                    str(fixture.superproject),
                    "--fork-url",
                    dependency_spec.fork_url,
                    "--upstream-url",
                    dependency_spec.upstream_url,
                    "--path",
                    dependency_spec.path,
                    "--revision",
                    dependency_spec.revision,
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(fixture.first_revision, result.stdout)


if __name__ == "__main__":
    unittest.main()
