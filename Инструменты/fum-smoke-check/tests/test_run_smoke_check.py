import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


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
            root / "Инструменты" / "fum-md-recency" / "scripts" / "update-md-recency.py",
            root / "Инструменты" / "fum-obsidian-graph-recency" / "scripts" / "build-obsidian-graph-recency.py",
            root / "Инструменты" / "fum-session-coherence" / "scripts" / "check-session-coherence.py",
        ]:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("print('fixture')\n", encoding="utf-8")

        output = root / "Планирование" / "реестр-требований-вариантов-и-кандидатов.json"
        output.parent.mkdir(parents=True, exist_ok=True)

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
                    "Проверка скриптов запуска прототипов",
                    "Проверка recency-меток Markdown",
                    "Проверка тепловой карты графа Obsidian",
                    "Проверка связности рабочей сессии",
                ],
            )
            self.assertIn("Инструменты/fum-alpha/tests", steps[0].command)
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


if __name__ == "__main__":
    unittest.main()
