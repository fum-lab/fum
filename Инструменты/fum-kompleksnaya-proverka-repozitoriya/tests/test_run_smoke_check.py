import contextlib
import importlib.util
import io
import json
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest import mock


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "run-smoke-check.py"
)
TOOLS_DIR = Path(__file__).resolve().parents[2]
MACHINE_LOCAL_PATH_AUTOMATION_DIR = (
    TOOLS_DIR / "fum-proverka-mashinno-lokaljnyikh-putej"
)

spec = importlib.util.spec_from_file_location("run_smoke_check", SCRIPT_PATH)
run_smoke_check = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = run_smoke_check
spec.loader.exec_module(run_smoke_check)


class RunSmokeCheckTests(unittest.TestCase):
    def write_script_fixture(self, root: Path) -> None:
        for path in [
            root / "Инструменты" / "fum-reyestr-planirovaniya" / "scripts" / "build-planning-registry.py",
            root / "Инструменты" / "fum-zapusk-prototipov" / "scripts" / "check-prototype-launchers.py",
            root / "Инструменты" / "fum-obratnyiye-ssyilki-voprosov" / "scripts" / "check-question-backlinks.py",
            root / "Инструменты" / "fum-indeks-readme" / "scripts" / "check-readme-index.py",
            root / "Инструменты" / "fum-proverka-nazvanij-avtomatizacij" / "scripts" / "proveritj-nazvaniya-avtomatizacij.py",
            root / "Инструменты" / "fum-proverka-mashinno-lokaljnyikh-putej" / "scripts" / "proveritj-mashinno-lokaljnyiye-puti.py",
            root / "Инструменты" / "fum-proverka-git-zavisimostej" / "scripts" / "proveritj-git-zavisimostj.py",
            root / "Инструменты" / "fum-svezhestj-markdown" / "scripts" / "update-md-recency.py",
            root / "Инструменты" / "fum-svezhestj-grafa-obsidian" / "scripts" / "build-obsidian-graph-recency.py",
            root / "Инструменты" / "fum-svyaznostj-rabochej-sessii" / "scripts" / "check-session-coherence.py",
        ]:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("print('fixture')\n", encoding="utf-8")

        output = root / "Планирование" / "реестр-требований-вариантов-и-кандидатов.json"
        output.parent.mkdir(parents=True, exist_ok=True)
        names_registry = root / "Инструменты" / "реестр-названий-автоматизаций.json"
        names_registry.write_text("{}\n", encoding="utf-8")

        codex_config = root / ".codex" / "config.toml"
        codex_config.parent.mkdir(parents=True, exist_ok=True)
        codex_config.write_text(
            "[skills]\ninclude_instructions = false\n",
            encoding="utf-8",
        )

    def test_requires_external_skill_instructions_disabled(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = root / ".codex" / "config.toml"
            config.parent.mkdir(parents=True)

            for text in (
                "model = \"gpt-5.6-sol\"\n",
                "[skills]\ninclude_instructions = true\n",
                "[skills]\ninclude_instructions = \"false\"\n",
            ):
                with self.subTest(text=text):
                    config.write_text(text, encoding="utf-8")
                    with self.assertRaisesRegex(
                        ValueError,
                        "skills.include_instructions = false",
                    ):
                        run_smoke_check.validate_project_skill_isolation(root)

            config.write_text(
                "[skills]\ninclude_instructions = false\n",
                encoding="utf-8",
            )
            run_smoke_check.validate_project_skill_isolation(root)

            config.write_text("[skills\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "invalid project Codex config"):
                run_smoke_check.validate_project_skill_isolation(root)

    def test_build_plan_requires_project_skill_isolation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            (root / ".codex" / "config.toml").unlink()

            with self.assertRaisesRegex(
                ValueError,
                "skills.include_instructions = false",
            ):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    commit_message_file=None,
                    codex_thread_id=None,
                    include_session=False,
                    python="python3",
                )

    def test_rejects_local_skill_symlink_outside_repository(self):
        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            root = workspace / "repo"
            root.mkdir()
            self.write_script_fixture(root)

            external_skill = workspace / "external" / "SKILL.md"
            external_skill.parent.mkdir()
            external_skill.write_text("# External\n", encoding="utf-8")
            local_skill = root / "Инструменты" / "fum-linked" / "SKILL.md"
            local_skill.parent.mkdir()
            local_skill.symlink_to(external_skill)

            with self.assertRaisesRegex(
                ValueError,
                "local skill path resolves outside repository",
            ):
                run_smoke_check.validate_project_skill_isolation(root)

    def write_swift_package_fixture(self, root: Path, name: str) -> Path:
        package = root / "Прототипы" / name
        (package / "Sources" / "Fixture").mkdir(parents=True)
        (package / "Tests" / "FixtureTests").mkdir(parents=True)
        (package / "Package.swift").write_text("// fixture\n", encoding="utf-8")
        (package / "Sources" / "Fixture" / "Fixture.swift").write_text(
            "public struct Fixture {}\n",
            encoding="utf-8",
        )
        (package / "Tests" / "FixtureTests" / "FixtureTests.swift").write_text(
            "import Testing\n",
            encoding="utf-8",
        )
        swift_format_config = (
            root
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "swift-format.json"
        )
        swift_format_config.parent.mkdir(parents=True, exist_ok=True)
        if not swift_format_config.exists():
            swift_format_config.write_text("{}\n", encoding="utf-8")
        return package.resolve()

    def test_builds_full_plan_from_local_automation_tests(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            for tool_name in ["fum-alpha", "fum-beta"]:
                test_dir = root / "Инструменты" / tool_name / "tests"
                test_dir.mkdir(parents=True)
                (test_dir / f"test_{tool_name}.py").write_text(
                    "import unittest\n\nclass Fixture(unittest.TestCase):\n    pass\n",
                    encoding="utf-8",
                )

            steps = run_smoke_check.build_steps(
                root,
                request=Path("Запросы/2026-07-01_14-12-17_MSK.md"),
                commit_message_file=Path("/tmp/fum-commit-message.txt"),
                codex_thread_id="019f5dd0-c129-7fa0-9315-77e85dead3e7",
                include_session=True,
                python="python3",
            )

            names = [step.name for step in steps]
            self.assertEqual(
                names,
                [
                    "Тесты fum-alpha",
                    "Тесты fum-beta",
                    "Сборка планового реестра",
                    "Проверка планового реестра",
                    "Проверка реестра названий автоматизаций",
                    "Проверка машинно-локальных путей",
                    "Проверка Git-зависимости LinguisticKit",
                    "Проверка скриптов запуска прототипов",
                    "Проверка двунаправленности вопросов",
                    "Проверка тематического индекса README",
                    "Проверка recency-меток Markdown",
                    "Проверка тепловой карты графа Obsidian",
                    "Проверка связности рабочей сессии",
                ],
            )
            self.assertIn("Инструменты/fum-alpha/tests", steps[0].command)
            question_step = next(
                step
                for step in steps
                if step.name == "Проверка двунаправленности вопросов"
            )
            self.assertEqual(
                question_step.command,
                (
                    "python3",
                    "Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/"
                    "check-question-backlinks.py",
                ),
            )
            readme_step = next(
                step
                for step in steps
                if step.name == "Проверка тематического индекса README"
            )
            self.assertEqual(
                readme_step.command,
                (
                    "python3",
                    "Инструменты/fum-indeks-readme/scripts/"
                    "check-readme-index.py",
                    "--repo-root",
                    ".",
                ),
            )
            self.assertEqual(
                next(
                    step
                    for step in steps
                    if step.name == "Проверка машинно-локальных путей"
                ).command,
                (
                    "python3",
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/"
                    "scripts/proveritj-mashinno-lokaljnyiye-puti.py",
                    "--repo-root",
                    ".",
                ),
            )
            self.assertEqual(
                next(
                    step
                    for step in steps
                    if step.name == "Проверка реестра названий автоматизаций"
                ).command,
                (
                    "python3",
                    "Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/"
                    "proveritj-nazvaniya-avtomatizacij.py",
                    "--repo-root",
                    ".",
                    "--registry",
                    "Инструменты/реестр-названий-автоматизаций.json",
                ),
            )
            self.assertEqual(
                next(
                    step
                    for step in steps
                    if step.name == "Проверка Git-зависимости LinguisticKit"
                ).command,
                (
                    "python3",
                    "Инструменты/fum-proverka-git-zavisimostej/scripts/"
                    "proveritj-git-zavisimostj.py",
                    "check",
                    "--repo-root",
                    ".",
                    "--fork-url",
                    "https://github.com/fum-lab/LinguisticKit.git",
                    "--upstream-url",
                    "https://github.com/Roman-Kerimov/LinguisticKit.git",
                    "--path",
                    "Зависимости/LinguisticKit",
                    "--revision",
                    "837e2ce107b97ee7b9d3344c9fe99142281fe393",
                ),
            )
            self.assertEqual(
                steps[-1].command[-6:],
                (
                    "--request",
                    "Запросы/2026-07-01_14-12-17_MSK.md",
                    "--commit-message-file",
                    "/tmp/fum-commit-message.txt",
                    "--codex-thread-id",
                    "019f5dd0-c129-7fa0-9315-77e85dead3e7",
                ),
            )

    def test_session_check_can_be_skipped_for_partial_local_runs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)

            steps = run_smoke_check.build_steps(
                root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                include_session=False,
                python="python3",
            )

            names = [step.name for step in steps]
            self.assertNotIn("Проверка связности рабочей сессии", names)
            self.assertIn("Проверка recency-меток Markdown", names)
            self.assertIn("Проверка тепловой карты графа Obsidian", names)

    def test_new_request_requires_commit_context(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            request = Path(
                "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
                "идентификатор-сеанса-Codex.md"
            )

            for missing_message, missing_thread_id, expected_flag in [
                (True, False, "--commit-message-file"),
                (False, True, "--codex-thread-id"),
            ]:
                with self.subTest(expected_flag=expected_flag):
                    with self.assertRaisesRegex(ValueError, expected_flag):
                        run_smoke_check.build_steps(
                            root,
                            request=request,
                            commit_message_file=(
                                None
                                if missing_message
                                else Path("/tmp/fum-commit-message.txt")
                            ),
                            codex_thread_id=(
                                None
                                if missing_thread_id
                                else "019f5dd0-c129-7fa0-9315-77e85dead3e7"
                            ),
                            include_session=True,
                            python="python3",
                        )

    def test_historical_request_allows_missing_commit_context(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)

            steps = run_smoke_check.build_steps(
                root,
                request=Path("Запросы/2026-07-01_14-12-17_MSK.md"),
                commit_message_file=None,
                codex_thread_id=None,
                include_session=True,
                python="python3",
            )

            self.assertEqual(
                steps[-1].command[-2:],
                ("--request", "Запросы/2026-07-01_14-12-17_MSK.md"),
            )

    def test_requires_request_when_session_check_is_enabled(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)

            with self.assertRaisesRegex(ValueError, "--request"):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    commit_message_file=None,
                    codex_thread_id=None,
                    include_session=True,
                    python="python3",
                )

    def test_discovers_swift_packages_tests_products_and_strict_lint(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            alpha = self.write_swift_package_fixture(root, "alpha")
            beta = self.write_swift_package_fixture(root, "beta")
            exception_hash = "sha256:" + "a" * 64
            policy = {
                "schemaVersion": 1,
                "defaultMode": "strict",
                "packages": [
                    {
                        "package": "Прототипы/alpha",
                        "executableProducts": ["AlphaCLI"],
                    },
                    {
                        "package": "Прототипы/beta",
                        "executableProducts": ["BetaApp", "BetaProbe"],
                    },
                ],
                "exceptions": [
                    {
                        "package": "Прототипы/beta",
                        "reason": "Существующий пакет ещё не нормализован.",
                        "removalCriterion": "Отформатировать пакет целиком.",
                        "source": "Ревью/ревью.md",
                        "contentSha256": exception_hash,
                    }
                ],
            }
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.parent.mkdir(parents=True, exist_ok=True)
            policy_path.write_text(
                json.dumps(policy, ensure_ascii=False),
                encoding="utf-8",
            )
            source = root / "Ревью" / "ревью.md"
            source.parent.mkdir(parents=True)
            source.write_text("# Ревью\n", encoding="utf-8")

            manifests = {
                alpha: run_smoke_check.SwiftPackageManifest(
                    executable_products=("AlphaCLI",),
                    target_paths=("Sources/Fixture", "Tests/FixtureTests"),
                ),
                beta: run_smoke_check.SwiftPackageManifest(
                    executable_products=("BetaApp", "BetaProbe"),
                    target_paths=("Sources/Fixture", "Tests/FixtureTests"),
                ),
            }

            with (
                mock.patch.object(
                    run_smoke_check,
                    "inspect_swift_package",
                    side_effect=lambda _root, package, _swift: manifests[package],
                ),
                mock.patch.object(
                    run_smoke_check,
                    "swift_lint_content_sha256",
                    return_value=exception_hash,
                ),
            ):
                steps = run_smoke_check.build_steps(
                    root,
                    request=None,
                    include_session=False,
                    python="python3",
                    swift="swift-fixture",
                )

            swift_steps = [
                step for step in steps if "SwiftPM" in step.name
            ]
            self.assertEqual(
                [step.name for step in swift_steps],
                [
                    "Тесты SwiftPM Прототипы/alpha",
                    "Сборка SwiftPM-продукта Прототипы/alpha: AlphaCLI",
                    "Строгий lint SwiftPM Прототипы/alpha",
                    "Тесты SwiftPM Прототипы/beta",
                    "Сборка SwiftPM-продукта Прототипы/beta: BetaApp",
                    "Сборка SwiftPM-продукта Прототипы/beta: BetaProbe",
                    "Lint-исключение SwiftPM Прототипы/beta",
                ],
            )
            self.assertEqual(
                swift_steps[0].command,
                (
                    "swift-fixture",
                    "test",
                    "--package-path",
                    "Прототипы/alpha",
                ),
            )
            self.assertEqual(
                swift_steps[1].command,
                (
                    "swift-fixture",
                    "build",
                    "--package-path",
                    "Прототипы/alpha",
                    "--product",
                    "AlphaCLI",
                ),
            )
            self.assertEqual(
                swift_steps[2].command,
                (
                    "swift-fixture",
                    "format",
                    "lint",
                    "--configuration",
                    "Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-format.json",
                    "--strict",
                    "--recursive",
                    "Прототипы/alpha/Package.swift",
                    "Прототипы/alpha/Sources/Fixture",
                    "Прототипы/alpha/Tests/FixtureTests",
                ),
            )
            self.assertIsNone(swift_steps[-1].command)
            self.assertIn(exception_hash, swift_steps[-1].detail)
            self.assertIn(
                "Отформатировать пакет целиком.",
                swift_steps[-1].detail,
            )

    def test_rejects_stale_swift_lint_exception(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            package = self.write_swift_package_fixture(root, "alpha")
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.parent.mkdir(parents=True, exist_ok=True)
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                            }
                        ],
                        "exceptions": [
                            {
                                "package": "Прототипы/alpha",
                                "reason": "Историческое форматирование.",
                                "removalCriterion": "Запустить форматирование.",
                                "source": "Ревью/ревью.md",
                                "contentSha256": "sha256:" + "a" * 64,
                            }
                        ],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            source = root / "Ревью" / "ревью.md"
            source.parent.mkdir(parents=True)
            source.write_text("# Ревью\n", encoding="utf-8")
            manifest = run_smoke_check.SwiftPackageManifest(
                executable_products=("AlphaCLI",),
                target_paths=("Sources/Fixture", "Tests/FixtureTests"),
            )

            with (
                mock.patch.object(
                    run_smoke_check,
                    "inspect_swift_package",
                    return_value=manifest,
                ),
                mock.patch.object(
                    run_smoke_check,
                    "swift_lint_content_sha256",
                    return_value="sha256:" + "b" * 64,
                ),
            ):
                with self.assertRaisesRegex(ValueError, "устарело"):
                    run_smoke_check.build_steps(
                        root,
                        request=None,
                        include_session=False,
                        python="python3",
                        swift="swift-fixture",
                    )

            self.assertTrue(package.exists())

    def test_swift_lint_hash_changes_with_tracked_inputs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package = self.write_swift_package_fixture(root, "alpha")
            target_paths = ("Sources/Fixture", "Tests/FixtureTests")

            before = run_smoke_check.swift_lint_content_sha256(
                root,
                package,
                target_paths,
            )
            (package / "Sources" / "Fixture" / "Fixture.swift").write_text(
                "public struct ChangedFixture {}\n",
                encoding="utf-8",
            )
            after = run_smoke_check.swift_lint_content_sha256(
                root,
                package,
                target_paths,
            )

            self.assertRegex(before, r"^sha256:[0-9a-f]{64}$")
            self.assertNotEqual(before, after)

            config = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-format.json"
            )
            config.write_text('{"lineLength": 88}\n', encoding="utf-8")
            after_config_change = run_smoke_check.swift_lint_content_sha256(
                root,
                package,
                target_paths,
            )
            self.assertNotEqual(after, after_config_change)

    def test_rejects_swiftpm_dependencies_without_offline_contract(self):
        dump = json.dumps(
            {
                "dependencies": [
                    {
                        "sourceControl": [
                            {
                                "identity": "remote",
                                "location": {"remote": ["https://example.test/repo"]},
                            },
                            {"branch": ["main"]},
                        ]
                    }
                ],
                "products": [
                    {"name": "CLI", "type": {"executable": None}},
                ],
                "targets": [
                    {"path": "Sources/CLI"},
                ],
            }
        )

        with self.assertRaisesRegex(ValueError, "offline contract"):
            run_smoke_check.parse_swift_package_manifest(dump)

    def test_rejects_missing_package_and_product_inventory_drift(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            package = self.write_swift_package_fixture(root, "alpha")
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                            },
                            {
                                "package": "Прототипы/beta",
                                "executableProducts": ["BetaCLI"],
                            },
                        ],
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "missing packages"):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    include_session=False,
                    python="python3",
                    swift="swift-fixture",
                )

            policy = json.loads(policy_path.read_text(encoding="utf-8"))
            policy["packages"] = policy["packages"][:1]
            policy_path.write_text(
                json.dumps(policy, ensure_ascii=False),
                encoding="utf-8",
            )
            manifest = run_smoke_check.SwiftPackageManifest(
                executable_products=("RenamedCLI",),
                target_paths=("Sources/Fixture", "Tests/FixtureTests"),
            )
            with mock.patch.object(
                run_smoke_check,
                "inspect_swift_package",
                return_value=manifest,
            ):
                with self.assertRaisesRegex(ValueError, "products differ"):
                    run_smoke_check.build_steps(
                        root,
                        request=None,
                        include_session=False,
                        python="python3",
                        swift="swift-fixture",
                    )

            self.assertTrue(package.exists())

    def test_rejects_swift_format_ignore_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            package = self.write_swift_package_fixture(root, "alpha")
            (package / ".swift-format-ignore").write_text(
                "Sources/Fixture/Fixture.swift\n",
                encoding="utf-8",
            )
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                            }
                        ],
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "swift-format-ignore"):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    include_session=False,
                    python="python3",
                    swift="swift-fixture",
                )

    def test_run_steps_prints_lint_exception_and_continues(self):
        steps = [
            run_smoke_check.SmokeStep(
                name="Lint-исключение SwiftPM fixture",
                command=None,
                detail="Проверенное исключение.",
            ),
            run_smoke_check.SmokeStep(
                name="Следующий шаг",
                command=(sys.executable, "-c", "print('continued')"),
            ),
        ]

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = run_smoke_check.run_steps(steps, Path.cwd())

        self.assertEqual(result, 0)
        self.assertIn("Проверенное исключение.", output.getvalue())
        self.assertIn("continued", output.getvalue())

    def test_run_steps_prints_each_step_timing_and_full_total(self):
        steps = [
            run_smoke_check.SmokeStep(
                name="Информационный шаг",
                command=None,
                detail="Проверенное исключение.",
            ),
            run_smoke_check.SmokeStep(
                name="Исполняемый шаг",
                command=(sys.executable, "-c", "print('continued')"),
            ),
        ]
        clock_values = iter((100.0, 101.0, 101.25, 102.0, 103.5, 104.0))

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = run_smoke_check.run_steps(
                steps,
                Path.cwd(),
                clock=lambda: next(clock_values),
            )

        self.assertEqual(result, 0)
        timing_lines = [
            line
            for line in output.getvalue().splitlines()
            if line.startswith("smoke-timing ")
        ]
        self.assertEqual(len(timing_lines), 3)
        records = [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines]
        self.assertEqual(
            records,
            [
                {
                    "kind": "step",
                    "index": 1,
                    "total_steps": 2,
                    "name": "Информационный шаг",
                    "result": "passed",
                    "duration_seconds": "0.250",
                },
                {
                    "kind": "step",
                    "index": 2,
                    "total_steps": 2,
                    "name": "Исполняемый шаг",
                    "result": "passed",
                    "duration_seconds": "1.500",
                },
                {
                    "kind": "total",
                    "result": "passed",
                    "duration_seconds": "4.000",
                },
            ],
        )

    def test_run_steps_prints_failed_step_timing_and_total_before_stopping(self):
        steps = [
            run_smoke_check.SmokeStep(
                name="Падающий шаг",
                command=("fixture", "fail"),
            ),
            run_smoke_check.SmokeStep(
                name="Недостижимый шаг",
                command=("fixture", "must-not-run"),
            ),
        ]
        completed = subprocess.CompletedProcess(
            args=steps[0].command,
            returncode=7,
            stdout="",
            stderr="fixture failure\n",
        )
        clock_values = iter((10.0, 11.0, 13.5, 14.0))
        stdout = io.StringIO()
        stderr = io.StringIO()

        with (
            mock.patch.object(
                run_smoke_check.subprocess,
                "run",
                return_value=completed,
            ) as run,
            contextlib.redirect_stdout(stdout),
            contextlib.redirect_stderr(stderr),
        ):
            result = run_smoke_check.run_steps(
                steps,
                Path.cwd(),
                clock=lambda: next(clock_values),
            )

        self.assertEqual(result, 7)
        self.assertEqual(run.call_count, 1)
        timing_lines = [
            line
            for line in stdout.getvalue().splitlines()
            if line.startswith("smoke-timing ")
        ]
        self.assertEqual(
            [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
            [
                {
                    "kind": "step",
                    "index": 1,
                    "total_steps": 2,
                    "name": "Падающий шаг",
                    "result": "failed",
                    "duration_seconds": "2.500",
                    "exit_code": 7,
                },
                {
                    "kind": "total",
                    "result": "failed",
                    "duration_seconds": "4.000",
                    "exit_code": 7,
                },
            ],
        )
        self.assertIn("Падающий шаг", stderr.getvalue())

    def test_failed_manifest_inspection_prints_its_timing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package = root / "Прототипы" / "alpha"
            package.mkdir(parents=True)
            completed = subprocess.CompletedProcess(
                args=("swift-fixture", "package"),
                returncode=9,
                stdout="",
                stderr="manifest failure\n",
            )
            clock_values = iter((20.0, 22.25))
            records: list[dict[str, object]] = []

            with mock.patch.object(
                run_smoke_check.subprocess,
                "run",
                return_value=completed,
            ):
                with self.assertRaisesRegex(
                    ValueError,
                    "cannot inspect SwiftPM package",
                ):
                    run_smoke_check.inspect_swift_package(
                        root,
                        package,
                        "swift-fixture",
                        clock=lambda: next(clock_values),
                        timing_sink=records.append,
                    )

            self.assertEqual(
                records,
                [
                    {
                        "kind": "manifest",
                        "name": "SwiftPM manifest Прототипы/alpha",
                        "result": "failed",
                        "duration_seconds": "2.250",
                        "exit_code": 9,
                    }
                ],
            )

    def test_manifest_os_error_uses_stable_exit_code_127(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package = root / "Прототипы" / "alpha"
            package.mkdir(parents=True)
            clock_values = iter((30.0, 31.25))
            records: list[dict[str, object]] = []

            with mock.patch.object(
                run_smoke_check.subprocess,
                "run",
                side_effect=PermissionError("manifest denied"),
            ):
                with self.assertRaisesRegex(
                    FileNotFoundError,
                    "cannot inspect SwiftPM package",
                ):
                    run_smoke_check.inspect_swift_package(
                        root,
                        package,
                        "swift-fixture",
                        clock=lambda: next(clock_values),
                        timing_sink=records.append,
                    )

            self.assertEqual(
                records,
                [
                    {
                        "kind": "manifest",
                        "name": "SwiftPM manifest Прототипы/alpha",
                        "result": "failed",
                        "duration_seconds": "1.250",
                        "exit_code": 127,
                    }
                ],
            )

    def test_main_prints_preparation_and_total_timing_when_plan_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            args = types.SimpleNamespace(
                repo_root=root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                skip_session_coherence=True,
                list=False,
            )
            clock_values = iter((10.0, 11.0, 14.0, 16.0))
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                mock.patch.object(
                    run_smoke_check,
                    "parse_args",
                    return_value=args,
                ),
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                result = run_smoke_check.main(
                    clock=lambda: next(clock_values),
                )

            self.assertEqual(result, 2)
            self.assertIn("skills.include_instructions = false", stderr.getvalue())
            timing_lines = [
                line
                for line in stdout.getvalue().splitlines()
                if line.startswith("smoke-timing ")
            ]
            self.assertEqual(
                [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
                [
                    {
                        "kind": "preparation",
                        "result": "failed",
                        "duration_seconds": "3.000",
                        "exit_code": 2,
                    },
                    {
                        "kind": "total",
                        "result": "failed",
                        "duration_seconds": "6.000",
                        "exit_code": 2,
                    },
                ],
            )

    def test_main_converts_preparation_os_error_to_failed_timing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            args = types.SimpleNamespace(
                repo_root=root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                skip_session_coherence=True,
                list=False,
            )
            clock_values = iter((40.0, 41.0, 44.0, 46.0))
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                mock.patch.object(
                    run_smoke_check,
                    "parse_args",
                    return_value=args,
                ),
                mock.patch.object(
                    run_smoke_check,
                    "build_steps",
                    side_effect=PermissionError("preparation denied"),
                ),
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                result = run_smoke_check.main(
                    clock=lambda: next(clock_values),
                )

            self.assertEqual(result, 2)
            self.assertIn("preparation denied", stderr.getvalue())
            timing_lines = [
                line
                for line in stdout.getvalue().splitlines()
                if line.startswith("smoke-timing ")
            ]
            self.assertEqual(
                [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
                [
                    {
                        "kind": "preparation",
                        "result": "failed",
                        "duration_seconds": "3.000",
                        "exit_code": 2,
                    },
                    {
                        "kind": "total",
                        "result": "failed",
                        "duration_seconds": "6.000",
                        "exit_code": 2,
                    },
                ],
            )

    def test_full_runner_stops_on_tracked_machine_local_path_regression(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            target_automation = (
                root
                / "Инструменты"
                / "fum-proverka-mashinno-lokaljnyikh-putej"
            )
            shutil.copy2(
                MACHINE_LOCAL_PATH_AUTOMATION_DIR
                / "scripts"
                / "proveritj-mashinno-lokaljnyiye-puti.py",
                target_automation
                / "scripts"
                / "proveritj-mashinno-lokaljnyiye-puti.py",
            )
            shutil.copy2(
                MACHINE_LOCAL_PATH_AUTOMATION_DIR / "scripts" / "path_forms.py",
                target_automation / "scripts" / "path_forms.py",
            )
            (target_automation / "policy.json").write_text(
                json.dumps(
                    {
                        "schema": "fum.machine-local-path-policy.v2",
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                )
                + "\n",
                encoding="utf-8",
            )
            regression = root / "Документация" / "регрессия.md"
            regression.parent.mkdir()
            regression.write_text(
                "/Users/private-name/secret-project\n",
                encoding="utf-8",
            )
            subprocess.run(
                ["git", "init"],
                cwd=root,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            subprocess.run(["git", "add", "."], cwd=root, check=True)
            steps = run_smoke_check.build_steps(
                root,
                request=None,
                include_session=False,
                python=sys.executable,
            )
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                result = run_smoke_check.run_steps(steps, root)

            self.assertEqual(result, 1)
            self.assertIn(
                "Документация/регрессия.md:1:error.posix-user-home",
                stdout.getvalue(),
            )
            self.assertNotIn("private-name", stdout.getvalue())
            self.assertIn(
                "Проверка машинно-локальных путей",
                stderr.getvalue(),
            )

    def test_list_evaluates_manifest_but_does_not_run_swift_checks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            self.write_swift_package_fixture(root, "alpha")
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                            }
                        ],
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            dump = json.dumps(
                {
                    "dependencies": [],
                    "products": [
                        {"name": "AlphaCLI", "type": {"executable": None}},
                    ],
                    "targets": [
                        {"path": "Sources/Fixture"},
                        {"path": "Tests/FixtureTests"},
                    ],
                }
            )
            completed = subprocess.CompletedProcess(
                args=(),
                returncode=0,
                stdout=dump,
                stderr="",
            )
            args = types.SimpleNamespace(
                repo_root=root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                skip_session_coherence=True,
                list=True,
            )

            output = io.StringIO()
            clock_values = iter((10.0, 11.0, 12.0, 14.0, 15.0, 16.0))
            with (
                mock.patch.object(run_smoke_check, "parse_args", return_value=args),
                mock.patch.object(
                    run_smoke_check.subprocess,
                    "run",
                    return_value=completed,
                ) as run,
                contextlib.redirect_stdout(output),
            ):
                result = run_smoke_check.main(
                    clock=lambda: next(clock_values),
                )

            self.assertEqual(result, 0)
            self.assertEqual(run.call_count, 1)
            manifest_command = run.call_args.args[0]
            self.assertIn("dump-package", manifest_command)
            self.assertNotIn("test", manifest_command)
            self.assertIn(
                "swift test --package-path",
                output.getvalue(),
            )
            self.assertIn(
                "swift format lint --configuration",
                output.getvalue(),
            )
            timing_lines = [
                line
                for line in output.getvalue().splitlines()
                if line.startswith("smoke-timing ")
            ]
            self.assertEqual(
                [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
                [
                    {
                        "kind": "manifest",
                        "name": "SwiftPM manifest Прототипы/alpha",
                        "result": "passed",
                        "duration_seconds": "2.000",
                    },
                    {
                        "kind": "preparation",
                        "result": "passed",
                        "duration_seconds": "4.000",
                    },
                    {
                        "kind": "total",
                        "result": "passed",
                        "duration_seconds": "6.000",
                    },
                ],
            )

    def test_parses_executable_products_and_target_paths_from_dump_package(self):
        dump = json.dumps(
            {
                "dependencies": [],
                "products": [
                    {"name": "Library", "type": {"library": ["automatic"]}},
                    {"name": "CLI", "type": {"executable": None}},
                ],
                "targets": [
                    {"path": "Sources/Library"},
                    {"path": "Sources/CLI"},
                    {"path": "Tests/LibraryTests"},
                ],
            }
        )

        manifest = run_smoke_check.parse_swift_package_manifest(dump)

        self.assertEqual(manifest.executable_products, ("CLI",))
        self.assertEqual(
            manifest.target_paths,
            ("Sources/CLI", "Sources/Library", "Tests/LibraryTests"),
        )


if __name__ == "__main__":
    unittest.main()
