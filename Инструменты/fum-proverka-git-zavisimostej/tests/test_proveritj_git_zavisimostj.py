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

    def publish_dependency_registration(self) -> None:
        run_git("commit", "-m", "Подключить зависимость", cwd=self.superproject)
        run_git("push", "origin", "HEAD:master", cwd=self.superproject)

    def fresh_clone(self, *, recurse_submodules: bool) -> Path:
        clone = self.root / (
            "fresh-recursive" if recurse_submodules else "fresh-non-recursive"
        )
        arguments = ["-c", "protocol.file.allow=always", "clone"]
        if recurse_submodules:
            arguments.append("--recurse-submodules")
        arguments.extend((str(self.fum_origin), str(clone)))
        run_git(*arguments)
        return clone


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

    def test_принимает_переименованный_дочерний_форк_того_же_владельца(сам):
        with tempfile.TemporaryDirectory() as временный:
            фикстура = GitDependencyFixture(Path(временный))
            run_git(
                "remote",
                "set-url",
                "origin",
                "https://github.com/fum-lab/fum.git",
                cwd=фикстура.superproject,
            )
            дочерний = proveritj_git_zavisimostj.DependencySpec(
                fork_url="https://github.com/fum-lab/fum-yadro.git",
                upstream_url="https://github.com/fum-lab/fum.git",
                path="Ядра/fum-yadro",
                revision=фикстура.first_revision,
            )

            ошибки = proveritj_git_zavisimostj.validate_repository_topology(
                фикстура.superproject,
                дочерний,
            )

            сам.assertEqual(ошибки, [])

    def test_дочерний_форк_требует_корневой_источник_как_основу(сам):
        with tempfile.TemporaryDirectory() as временный:
            фикстура = GitDependencyFixture(Path(временный))
            run_git(
                "remote",
                "set-url",
                "origin",
                "https://github.com/fum-lab/fum.git",
                cwd=фикстура.superproject,
            )
            дочерний = proveritj_git_zavisimostj.DependencySpec(
                fork_url="https://github.com/fum-lab/fum-yadro.git",
                upstream_url="https://github.com/fum-lab/drugoe-yadro.git",
                path="Ядра/fum-yadro",
                revision=фикстура.first_revision,
            )

            ошибки = proveritj_git_zavisimostj.validate_repository_topology(
                фикстура.superproject,
                дочерний,
            )

            сам.assertTrue(
                any("origin родительского FUM" in ошибка for ошибка in ошибки),
                ошибки,
            )

    def test_дочерний_форк_отклоняет_прямую_рекурсивную_композицию(сам):
        with tempfile.TemporaryDirectory() as временный:
            фикстура = GitDependencyFixture(Path(временный))
            дочерний_источник = фикстура.root / "дочерний-источник"
            дочерний_форк = фикстура.namespace / "fum-yadro.git"
            run_git("clone", str(фикстура.fum_origin), str(дочерний_источник))
            run_git(
                "config",
                "user.name",
                "FUM Test",
                cwd=дочерний_источник,
            )
            run_git(
                "config",
                "user.email",
                "fum-test@example.invalid",
                cwd=дочерний_источник,
            )
            (дочерний_источник / "Ядра").mkdir()
            (дочерний_источник / "Ядра" / "маркер.txt").write_text(
                "прямая рекурсивная композиция\n",
                encoding="utf-8",
            )
            run_git("add", "Ядра/маркер.txt", cwd=дочерний_источник)
            run_git(
                "commit",
                "-m",
                "Добавить прямую рекурсивную композицию",
                cwd=дочерний_источник,
            )
            ревизия = run_git("rev-parse", "HEAD", cwd=дочерний_источник)
            run_git("clone", "--bare", str(дочерний_источник), str(дочерний_форк))
            дочерний = proveritj_git_zavisimostj.DependencySpec(
                fork_url=str(дочерний_форк),
                upstream_url=str(фикстура.fum_origin),
                path="Ядра/fum-yadro",
                revision=ревизия,
            )

            ошибки_добавления = proveritj_git_zavisimostj.materialize_dependency(
                фикстура.superproject,
                дочерний,
            )

            сам.assertTrue(
                any(
                    "прямую рекурсивную композицию" in ошибка
                    for ошибка in ошибки_добавления
                ),
                ошибки_добавления,
            )
            сам.assertFalse(
                (фикстура.superproject / "Ядра" / "fum-yadro").exists()
            )
            run_git(
                "-c",
                "protocol.file.allow=always",
                "submodule",
                "add",
                "--",
                str(дочерний_форк),
                "Ядра/fum-yadro",
                cwd=фикстура.superproject,
            )
            зависимость = фикстура.superproject / "Ядра" / "fum-yadro"
            run_git(
                "remote",
                "add",
                "upstream",
                str(фикстура.fum_origin),
                cwd=зависимость,
            )
            run_git("fetch", "origin", cwd=зависимость)
            run_git("fetch", "upstream", cwd=зависимость)
            run_git("checkout", "--detach", ревизия, cwd=зависимость)
            run_git(
                "config",
                "-f",
                ".gitmodules",
                "submodule.Ядра/fum-yadro.fumUpstream",
                str(фикстура.fum_origin),
                cwd=фикстура.superproject,
            )
            run_git(
                "add",
                ".gitmodules",
                "Ядра/fum-yadro",
                cwd=фикстура.superproject,
            )

            ошибки_проверки = proveritj_git_zavisimostj.validate_dependency(
                фикстура.superproject,
                дочерний,
            )

            сам.assertTrue(
                any(
                    "прямую рекурсивную композицию" in ошибка
                    for ошибка in ошибки_проверки
                ),
                ошибки_проверки,
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

    def test_init_restores_upstream_fetches_remotes_and_selects_gitlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            self.assertEqual(run_git("remote", cwd=dependency), "origin")
            run_git("checkout", "--detach", fixture.second_revision, cwd=dependency)

            (fixture.seed / "README.md").write_text(
                "# Полученная после клонирования ревизия\n",
                encoding="utf-8",
            )
            run_git("add", "README.md", cwd=fixture.seed)
            run_git("commit", "-m", "Ревизия после клонирования", cwd=fixture.seed)
            fetched_revision = run_git("rev-parse", "HEAD", cwd=fixture.seed)
            run_git("push", "origin", "HEAD:master", cwd=fixture.seed)
            run_git("push", str(fixture.fork), "HEAD:master", cwd=fixture.seed)

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(errors, [])
            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertEqual(
                run_git("remote", "get-url", "upstream", cwd=dependency),
                str(fixture.upstream),
            )
            self.assertEqual(
                run_git("rev-parse", "refs/remotes/origin/master", cwd=dependency),
                fetched_revision,
            )
            self.assertEqual(
                run_git("rev-parse", "refs/remotes/upstream/master", cwd=dependency),
                fetched_revision,
            )
            self.assertEqual(
                run_git("rev-parse", "HEAD", cwd=dependency),
                fixture.first_revision,
            )
            self.assertEqual(
                proveritj_git_zavisimostj.validate_dependency(
                    fresh_clone,
                    fixture.dependency_spec(),
                ),
                [],
            )

    def test_init_materializes_registered_submodule_after_plain_clone(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=False)

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(errors, [])
            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertEqual(
                run_git("rev-parse", "HEAD", cwd=fresh_clone / fixture.path),
                fixture.first_revision,
            )

    def test_init_rejects_local_submodule_url_override_before_materialization(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=False)
            run_git(
                "config",
                f"submodule.{fixture.path}.url",
                str(fixture.upstream),
                cwd=fresh_clone,
            )

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("локальн" in error and "URL" in error for error in errors),
                errors,
            )
            self.assertFalse((fresh_clone / fixture.path / ".git").exists())

    def test_init_rejects_symlinked_parent_before_writing_local_url(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=False)
            dependency_parent = fresh_clone / Path(fixture.path).parent
            (fresh_clone / fixture.path).rmdir()
            dependency_parent.rmdir()
            external_parent = fixture.root / "external-dependencies"
            external_parent.mkdir()
            dependency_parent.symlink_to(external_parent, target_is_directory=True)
            local_url_key = f"submodule.{fixture.path}.url"

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )
            local_url = subprocess.run(
                ["git", "config", "--get-all", local_url_key],
                cwd=fresh_clone,
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("путь зависимости" in error for error in errors),
                errors,
            )
            self.assertEqual(local_url.returncode, 1)
            self.assertEqual(local_url.stdout, "")
            self.assertFalse((external_parent / Path(fixture.path).name).exists())

    def test_init_rejects_file_parent_before_writing_local_url(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=False)
            dependency_parent = fresh_clone / Path(fixture.path).parent
            (fresh_clone / fixture.path).rmdir()
            dependency_parent.rmdir()
            dependency_parent.write_text("не каталог\n", encoding="utf-8")
            local_url_key = f"submodule.{fixture.path}.url"

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )
            local_url = subprocess.run(
                ["git", "config", "--get-all", local_url_key],
                cwd=fresh_clone,
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("компонент пути" in error for error in errors),
                errors,
            )
            self.assertEqual(local_url.returncode, 1)
            self.assertEqual(local_url.stdout, "")
            self.assertEqual(
                dependency_parent.read_text(encoding="utf-8"),
                "не каталог\n",
            )

    def test_init_rejects_blank_duplicate_local_url_before_materialization(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=False)
            key = f"submodule.{fixture.path}.url"
            run_git("config", "--add", key, str(fixture.fork), cwd=fresh_clone)
            run_git("config", "--add", key, "", cwd=fresh_clone)

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("локальн" in error and "URL" in error for error in errors),
                errors,
            )
            self.assertFalse((fresh_clone / fixture.path / ".git").exists())

    def test_init_rejects_untracked_fum_upstream_override_before_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            run_git(
                "config",
                "-f",
                ".gitmodules",
                f"submodule.{fixture.path}.fumUpstream",
                str(fixture.fork),
                cwd=fresh_clone,
            )

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertIsNone(dependency_spec)
            self.assertTrue(
                any(".gitmodules" in error and "индекс" in error for error in errors),
                errors,
            )
            self.assertEqual(run_git("remote", cwd=dependency), "origin")

    def test_init_cli_rejects_non_utf8_gitmodules_before_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            gitmodules = fresh_clone / ".gitmodules"
            gitmodules.write_bytes(gitmodules.read_bytes() + b"# \xff\n")
            run_git("add", ".gitmodules", cwd=fresh_clone)
            original_head = run_git("rev-parse", "HEAD", cwd=dependency)

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "init",
                    "--repo-root",
                    str(fresh_clone),
                    "--path",
                    fixture.path,
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 1, result)
            self.assertIn("UTF-8", result.stderr)
            self.assertNotIn("Traceback", result.stderr)
            self.assertEqual(run_git("remote", cwd=dependency), "origin")
            self.assertEqual(run_git("rev-parse", "HEAD", cwd=dependency), original_head)

    def test_init_is_idempotent_for_exact_registered_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)

            first_spec, first_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )
            second_spec, second_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(first_errors, [])
            self.assertEqual(second_errors, [])
            self.assertEqual(first_spec, fixture.dependency_spec())
            self.assertEqual(second_spec, fixture.dependency_spec())
            self.assertEqual(
                set(run_git("remote", cwd=fresh_clone / fixture.path).splitlines()),
                {"origin", "upstream"},
            )

    def test_init_rejects_dirty_dependency_before_restoring_upstream(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            dirty_path = dependency / "local.tmp"
            dirty_path.write_text("локальное изменение\n", encoding="utf-8")

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(any("не чист" in error for error in errors), errors)
            self.assertEqual(run_git("remote", cwd=dependency), "origin")
            self.assertTrue(dirty_path.exists())

    def test_init_rejects_nested_linked_worktree_instead_of_submodule(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=False)
            carrier = fixture.root / "carrier"
            run_git("clone", str(fixture.fork), str(carrier))
            target = fresh_clone / fixture.path
            target.parent.mkdir(parents=True, exist_ok=True)
            run_git(
                "worktree",
                "add",
                "--detach",
                str(target),
                fixture.first_revision,
                cwd=carrier,
            )

            check_errors = proveritj_git_zavisimostj.validate_dependency(
                fresh_clone,
                fixture.dependency_spec(),
            )
            dependency_spec, init_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("Git-каталог submodule" in error for error in check_errors),
                check_errors,
            )
            self.assertTrue(
                any("Git-каталог submodule" in error for error in init_errors),
                init_errors,
            )
            self.assertEqual(run_git("remote", cwd=target), "origin")

    def test_init_rejects_symlinked_superproject_module_git_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            module_git_dir = fixture.superproject.joinpath(
                ".git",
                "modules",
                *Path(fixture.path).parts,
            )
            external_git_dir = fixture.root / "external-module.git"
            run_git(
                "config",
                "core.worktree",
                str(fixture.superproject / fixture.path),
                cwd=fixture.superproject / fixture.path,
            )
            module_git_dir.rename(external_git_dir)
            module_git_dir.symlink_to(external_git_dir, target_is_directory=True)

            check_errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )
            dependency_spec, init_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fixture.superproject,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("символическ" in error for error in check_errors),
                check_errors,
            )
            self.assertTrue(
                any("символическ" in error for error in init_errors),
                init_errors,
            )

    def test_init_rejects_symlinked_module_git_directory_before_materialization(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            run_git(
                "submodule",
                "deinit",
                "--force",
                "--",
                fixture.path,
                cwd=fresh_clone,
            )
            if dependency.exists():
                dependency.rmdir()

            module_git_dir = fresh_clone.joinpath(
                ".git",
                "modules",
                *Path(fixture.path).parts,
            )
            run_git(
                "--git-dir",
                str(module_git_dir),
                "config",
                "core.worktree",
                str(dependency),
                cwd=fresh_clone,
            )
            external_git_dir = fixture.root / "external-before-init.git"
            module_git_dir.rename(external_git_dir)
            module_git_dir.symlink_to(external_git_dir, target_is_directory=True)
            external_head = run_git(
                "--git-dir",
                str(external_git_dir),
                "rev-parse",
                "HEAD",
                cwd=fresh_clone,
            )
            external_index = (external_git_dir / "index").read_bytes()

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("символическ" in error for error in errors),
                errors,
            )
            self.assertFalse((dependency / ".git").exists())
            self.assertEqual(
                run_git(
                    "--git-dir",
                    str(external_git_dir),
                    "rev-parse",
                    "HEAD",
                    cwd=fresh_clone,
                ),
                external_head,
            )
            self.assertEqual((external_git_dir / "index").read_bytes(), external_index)

    def test_init_rejects_residual_module_git_directory_before_materialization(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            run_git(
                "submodule",
                "deinit",
                "--force",
                "--",
                fixture.path,
                cwd=fresh_clone,
            )
            if dependency.exists():
                dependency.rmdir()
            module_git_dir = fresh_clone.joinpath(
                ".git",
                "modules",
                *Path(fixture.path).parts,
            )
            run_git(
                "--git-dir",
                str(module_git_dir),
                "config",
                "remote.origin.url",
                str(fixture.upstream),
                cwd=fresh_clone,
            )

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("остаточный Git-каталог" in error for error in errors),
                errors,
            )
            self.assertFalse((dependency / ".git").exists())

    def test_init_accepts_registered_name_different_from_submodule_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            section = "submodule.logical name"
            run_git(
                "-c",
                "protocol.file.allow=always",
                "submodule",
                "add",
                "--name",
                "logical name",
                "--",
                str(fixture.fork),
                fixture.path,
                cwd=fixture.superproject,
            )
            dependency = fixture.superproject / fixture.path
            run_git("remote", "add", "upstream", str(fixture.upstream), cwd=dependency)
            run_git("fetch", "origin", cwd=dependency)
            run_git("fetch", "upstream", cwd=dependency)
            run_git("checkout", "--detach", fixture.first_revision, cwd=dependency)
            run_git(
                "config",
                "-f",
                ".gitmodules",
                f"{section}.fumUpstream",
                str(fixture.upstream),
                cwd=fixture.superproject,
            )
            run_git("add", ".gitmodules", fixture.path, cwd=fixture.superproject)

            check_errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )
            run_git("remote", "remove", "upstream", cwd=dependency)
            dependency_spec, init_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fixture.superproject,
                    fixture.path,
                )
            )

            self.assertEqual(check_errors, [])
            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertEqual(init_errors, [])
            self.assertEqual(
                run_git("remote", "get-url", "upstream", cwd=dependency),
                str(fixture.upstream),
            )

    def test_init_rejects_duplicate_path_in_selected_gitmodules_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency = fixture.superproject / fixture.path
            run_git(
                "config",
                "-f",
                ".gitmodules",
                "--add",
                f"submodule.{fixture.path}.path",
                "Другой/Путь",
                cwd=fixture.superproject,
            )
            run_git("add", ".gitmodules", cwd=fixture.superproject)
            original_head = run_git("rev-parse", "HEAD", cwd=dependency)

            check_errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )
            dependency_spec, init_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fixture.superproject,
                    fixture.path,
                )
            )

            self.assertIsNone(dependency_spec)
            self.assertTrue(
                any("ровно одно значение" in error for error in check_errors),
                check_errors,
            )
            self.assertTrue(
                any("ровно одно значение" in error for error in init_errors),
                init_errors,
            )
            self.assertEqual(run_git("rev-parse", "HEAD", cwd=dependency), original_head)

    def test_check_and_init_reject_blank_duplicate_tracked_urls(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency = fixture.superproject / fixture.path
            section = f"submodule.{fixture.path}"
            for name in ("url", "fumUpstream"):
                run_git(
                    "config",
                    "-f",
                    ".gitmodules",
                    "--add",
                    f"{section}.{name}",
                    "",
                    cwd=fixture.superproject,
                )
            run_git("add", ".gitmodules", cwd=fixture.superproject)
            original_head = run_git("rev-parse", "HEAD", cwd=dependency)

            check_errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )
            dependency_spec, init_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fixture.superproject,
                    fixture.path,
                )
            )

            self.assertIsNone(dependency_spec)
            for name in ("url", "fumUpstream"):
                self.assertTrue(
                    any(name in error and "ровно одно" in error for error in check_errors),
                    check_errors,
                )
                self.assertTrue(
                    any(name in error and "ровно одно" in error for error in init_errors),
                    init_errors,
                )
            self.assertEqual(run_git("rev-parse", "HEAD", cwd=dependency), original_head)

    def test_init_does_not_overwrite_ignored_path_when_selecting_gitlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            victim = fixture.seed / "victim.txt"
            victim.write_text("TRACKED\n", encoding="utf-8")
            run_git("add", "victim.txt", cwd=fixture.seed)
            run_git("commit", "-m", "Добавить целевой файл", cwd=fixture.seed)
            target_revision = run_git("rev-parse", "HEAD", cwd=fixture.seed)
            run_git("push", "origin", "HEAD:master", cwd=fixture.seed)
            run_git("push", str(fixture.fork), "HEAD:master", cwd=fixture.seed)
            self.assertEqual(fixture.add_dependency(revision=target_revision), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path

            run_git("rm", "victim.txt", cwd=fixture.seed)
            (fixture.seed / ".gitignore").write_text(
                "victim.txt\n",
                encoding="utf-8",
            )
            run_git("add", ".gitignore", cwd=fixture.seed)
            run_git("commit", "-m", "Игнорировать локальный файл", cwd=fixture.seed)
            alternate_revision = run_git("rev-parse", "HEAD", cwd=fixture.seed)
            run_git("push", "origin", "HEAD:master", cwd=fixture.seed)
            run_git("push", str(fixture.fork), "HEAD:master", cwd=fixture.seed)
            run_git("fetch", "origin", cwd=dependency)
            run_git("checkout", "--detach", alternate_revision, cwd=dependency)
            local_victim = dependency / "victim.txt"
            local_victim.write_text("LOCAL SECRET\n", encoding="utf-8")
            self.assertEqual(run_git("status", "--porcelain=v1", cwd=dependency), "")

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(
                dependency_spec,
                fixture.dependency_spec(revision=target_revision),
            )
            self.assertTrue(
                any("игнорируем" in error for error in errors),
                errors,
            )
            self.assertEqual(
                local_victim.read_text(encoding="utf-8"),
                "LOCAL SECRET\n",
            )
            self.assertEqual(run_git("rev-parse", "HEAD", cwd=dependency), alternate_revision)

    def test_init_rejects_wrong_existing_upstream_without_rewriting_it(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            run_git("remote", "add", "upstream", str(fixture.fork), cwd=dependency)

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("remote upstream" in error and "URL" in error for error in errors),
                errors,
            )
            self.assertEqual(
                run_git("remote", "get-url", "upstream", cwd=dependency),
                str(fixture.fork),
            )

    def test_init_rejects_missing_remote_fetch_refspec(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency = fixture.superproject / fixture.path
            run_git(
                "config",
                "--unset-all",
                "remote.upstream.fetch",
                cwd=dependency,
            )

            check_errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )
            dependency_spec, init_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fixture.superproject,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("fetch refspec" in error for error in check_errors),
                check_errors,
            )
            self.assertTrue(
                any("fetch refspec" in error for error in init_errors),
                init_errors,
            )

    def test_init_rejects_blank_duplicate_remote_fetch_refspec(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            dependency = fixture.superproject / fixture.path
            run_git(
                "config",
                "--add",
                "remote.origin.fetch",
                "",
                cwd=dependency,
            )

            check_errors = proveritj_git_zavisimostj.validate_dependency(
                fixture.superproject,
                fixture.dependency_spec(),
            )
            dependency_spec, init_errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fixture.superproject,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("fetch refspec" in error for error in check_errors),
                check_errors,
            )
            self.assertTrue(
                any("fetch refspec" in error for error in init_errors),
                init_errors,
            )

    def test_init_prunes_deleted_origin_branches_before_reachability_check(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            run_git("branch", "legacy", fixture.first_revision, cwd=fixture.fork)
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            dependency = fresh_clone / fixture.path
            self.assertEqual(
                run_git("rev-parse", "refs/remotes/origin/legacy", cwd=dependency),
                fixture.first_revision,
            )

            run_git("branch", "-D", "legacy", cwd=fixture.fork)
            unrelated = fixture.root / "unrelated"
            run_git("init", str(unrelated))
            run_git("config", "user.name", "FUM Test", cwd=unrelated)
            run_git("config", "user.email", "fum-test@example.invalid", cwd=unrelated)
            (unrelated / "README.md").write_text(
                "# Несвязанная история\n",
                encoding="utf-8",
            )
            run_git("add", "README.md", cwd=unrelated)
            run_git("commit", "-m", "Несвязанная история", cwd=unrelated)
            run_git(
                "push",
                "--force",
                str(fixture.fork),
                "HEAD:master",
                cwd=unrelated,
            )

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertEqual(dependency_spec, fixture.dependency_spec())
            self.assertTrue(
                any("не достижима из origin" in error for error in errors),
                errors,
            )
            self.assertEqual(
                run_git(
                    "for-each-ref",
                    "--format=%(refname)",
                    "refs/remotes/origin/legacy",
                    cwd=dependency,
                ),
                "",
            )

    def test_init_rejects_missing_tracked_fum_upstream(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            run_git(
                "config",
                "-f",
                ".gitmodules",
                "--unset-all",
                f"submodule.{fixture.path}.fumUpstream",
                cwd=fresh_clone,
            )
            run_git("add", ".gitmodules", cwd=fresh_clone)

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertIsNone(dependency_spec)
            self.assertTrue(any("fumUpstream" in error for error in errors), errors)

    def test_init_rejects_missing_index_gitlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)
            run_git("update-index", "--force-remove", "--", fixture.path, cwd=fresh_clone)

            dependency_spec, errors = (
                proveritj_git_zavisimostj.initialize_registered_dependency(
                    fresh_clone,
                    fixture.path,
                )
            )

            self.assertIsNone(dependency_spec)
            self.assertTrue(any("gitlink" in error for error in errors), errors)

    def test_cli_init_derives_contract_from_registered_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = GitDependencyFixture(Path(tmp))
            self.assertEqual(fixture.add_dependency(), [])
            fixture.publish_dependency_registration()
            fresh_clone = fixture.fresh_clone(recurse_submodules=True)

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "init",
                    "--repo-root",
                    str(fresh_clone),
                    "--path",
                    fixture.path,
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(fixture.first_revision, result.stdout)
            self.assertIn("Инициализирована", result.stdout)


if __name__ == "__main__":
    unittest.main()
