import contextlib
import importlib.util
import io
import json
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

spec = importlib.util.spec_from_file_location("run_smoke_check", SCRIPT_PATH)
run_smoke_check = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = run_smoke_check
spec.loader.exec_module(run_smoke_check)


class RunSmokeCheckTests(unittest.TestCase):
    def write_script_fixture(self, root: Path) -> None:
        for path in [
            root / "Инструменты" / "fum-planning-registry" / "scripts" / "build-planning-registry.py",
            root / "Инструменты" / "fum-prototype-launch" / "scripts" / "check-prototype-launchers.py",
            root / "Инструменты" / "fum-question-backlinks" / "scripts" / "check-question-backlinks.py",
            root / "Инструменты" / "fum-readme-index" / "scripts" / "check-readme-index.py",
            root / "Инструменты" / "fum-proverka-nazvanij-avtomatizacij" / "scripts" / "proveritj-nazvaniya-avtomatizacij.py",
            root / "Инструменты" / "fum-md-recency" / "scripts" / "update-md-recency.py",
            root / "Инструменты" / "fum-obsidian-graph-recency" / "scripts" / "build-obsidian-graph-recency.py",
            root / "Инструменты" / "fum-session-coherence" / "scripts" / "check-session-coherence.py",
        ]:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("print('fixture')\n", encoding="utf-8")

        output = root / "Планирование" / "реестр-требований-вариантов-и-кандидатов.json"
        output.parent.mkdir(parents=True, exist_ok=True)
        names_registry = root / "Инструменты" / "реестр-названий-автоматизаций.json"
        names_registry.write_text("{}\n", encoding="utf-8")

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
            / "fum-smoke-check"
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
                    "Инструменты/fum-question-backlinks/scripts/"
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
                    "Инструменты/fum-readme-index/scripts/"
                    "check-readme-index.py",
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
                / "fum-smoke-check"
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
                    "Инструменты/fum-smoke-check/swift-format.json",
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
                / "fum-smoke-check"
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
                / "fum-smoke-check"
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
                / "fum-smoke-check"
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
                / "fum-smoke-check"
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

    def test_list_evaluates_manifest_but_does_not_run_swift_checks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            self.write_swift_package_fixture(root, "alpha")
            policy_path = (
                root
                / "Инструменты"
                / "fum-smoke-check"
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
            with (
                mock.patch.object(run_smoke_check, "parse_args", return_value=args),
                mock.patch.object(
                    run_smoke_check.subprocess,
                    "run",
                    return_value=completed,
                ) as run,
                contextlib.redirect_stdout(output),
            ):
                result = run_smoke_check.main()

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
