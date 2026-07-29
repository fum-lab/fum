import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


TOOL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = TOOL_ROOT / "scripts" / "render-heartbeat-prompt.py"
SNAPSHOT_SCRIPT_PATH = TOOL_ROOT / "scripts" / "automation-status-snapshot.py"
HEARTBEAT_PROMPT_PATH = TOOL_ROOT / "references" / "heartbeat-prompt.md"
SKILL_PATH = TOOL_ROOT / "SKILL.md"


def load_renderer_module():
    module_name = "fum_render_heartbeat_prompt_test_module"
    spec = importlib.util.spec_from_file_location(module_name, SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Не удалось загрузить renderer: {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


RENDERER = load_renderer_module()


def load_snapshot_module():
    module_name = "fum_automation_status_snapshot_test_module"
    spec = importlib.util.spec_from_file_location(module_name, SNAPSHOT_SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Не удалось загрузить snapshot helper: {SNAPSHOT_SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


SNAPSHOT = load_snapshot_module()


class HeartbeatPromptRendererTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.repo = self.root / "проект с пробелом"
        self.repo.mkdir()
        subprocess.run(
            ["git", "init", "-q", str(self.repo)],
            check=True,
            capture_output=True,
            text=True,
        )

    @staticmethod
    def document(template: str) -> str:
        return (
            "# Документ\n\n"
            "Содержательное введение.\n\n"
            "## Шаблон\n\n"
            "```text\n"
            f"{template}\n"
            "```\n\n"
            "## Проверка\n\n"
            "Справочный раздел.\n"
        )

    def test_extracts_and_renders_the_complete_fenced_template(self) -> None:
        template = (
            "Первая строка.\n"
            "Работай в <КОРЕНЬ_КЛОНА>.\n"
            "Проверь точный path <КОРЕНЬ_КЛОНА>.\n"
            "Последняя строка."
        )
        non_normalized = self.repo / ".." / self.repo.name

        rendered = RENDERER.render_heartbeat_prompt(
            self.document(template),
            non_normalized,
        )

        normalized = str(self.repo.resolve(strict=True))
        self.assertEqual(
            rendered,
            template.replace("<КОРЕНЬ_КЛОНА>", normalized),
        )
        self.assertNotIn("<КОРЕНЬ_КЛОНА>", rendered)

    def test_rejects_ambiguous_template_sections(self) -> None:
        duplicated = self.document("Путь: <КОРЕНЬ_КЛОНА>.") + self.document(
            "Другой путь: <КОРЕНЬ_КЛОНА>."
        )

        with self.assertRaisesRegex(RENDERER.TemplateError, "ровно один"):
            RENDERER.render_heartbeat_prompt(duplicated, self.repo)

    def test_rejects_missing_or_unclosed_template_fence(self) -> None:
        missing_fence = (
            "# Документ\n\n## Шаблон\n\nПуть: <КОРЕНЬ_КЛОНА>.\n"
        )
        unclosed_fence = (
            "# Документ\n\n## Шаблон\n\n```text\n"
            "Путь: <КОРЕНЬ_КЛОНА>.\n"
        )

        for document in (missing_fence, unclosed_fence):
            with self.subTest(document=document):
                with self.assertRaises(RENDERER.TemplateError):
                    RENDERER.render_heartbeat_prompt(document, self.repo)

    def test_rejects_missing_and_residual_clone_root_placeholders(self) -> None:
        missing = self.document("Путь отсутствует.")
        residual = self.document(
            "Путь: <КОРЕНЬ_КЛОНА>; резерв: <КОРЕНЬ_КЛОНА_РЕЗЕРВ>."
        )

        with self.assertRaisesRegex(RENDERER.TemplateError, "placeholder"):
            RENDERER.render_heartbeat_prompt(missing, self.repo)
        with self.assertRaisesRegex(RENDERER.TemplateError, "placeholder"):
            RENDERER.render_heartbeat_prompt(residual, self.repo)

    def test_rejects_nested_and_non_git_directories_as_repo_root(self) -> None:
        nested = self.repo / "nested"
        nested.mkdir()
        non_git = self.root / "не git"
        non_git.mkdir()

        for invalid_root in (nested, non_git):
            with self.subTest(invalid_root=invalid_root):
                with self.assertRaises(RENDERER.TemplateError):
                    RENDERER.render_heartbeat_prompt(
                        self.document("Путь: <КОРЕНЬ_КЛОНА>."),
                        invalid_root,
                    )

    def test_cli_emits_only_the_complete_rendered_prompt(self) -> None:
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "--repo-root",
                str(self.repo / ".." / self.repo.name),
                "--template-document",
                str(HEARTBEAT_PROMPT_PATH),
            ],
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith("Это пятиминутный тик"))
        self.assertTrue(result.stdout.endswith("глобальную блокировку."))
        self.assertFalse(result.stdout.endswith("\n"))
        self.assertNotIn("## Штатное управление Stop/Start", result.stdout)
        self.assertNotIn("<КОРЕНЬ_КЛОНА>", result.stdout)
        self.assertIn(str(self.repo.resolve(strict=True)), result.stdout)
        self.assertEqual(result.stderr, "")


class AutomationStatusSnapshotTests(unittest.TestCase):
    @staticmethod
    def snapshot(*, status: str = "PAUSED", updated_at: str = "before") -> dict:
        return {
            "id": "opaque-id",
            "kind": "heartbeat",
            "name": "Следующий шаг",
            "prompt": "Полный prompt\nс переводом строки\n",
            "rrule": "FREQ=MINUTELY;INTERVAL=5",
            "status": status,
            "target": {"threadId": "opaque-thread"},
            "destination": "local",
            "notificationPolicy": None,
            "created_at": "created",
            "updated_at": updated_at,
            "version": 7,
        }

    def test_prepares_status_update_without_rebuilding_snapshot_fields(self) -> None:
        before = self.snapshot()

        prepared = SNAPSHOT.prepare_status_update(before, "ACTIVE")

        self.assertEqual(prepared["status"], "ACTIVE")
        self.assertEqual(prepared["mode"], "update")
        self.assertEqual(prepared["targetThreadId"], "opaque-thread")
        self.assertNotIn("target", prepared)
        self.assertNotIn("created_at", prepared)
        self.assertNotIn("updated_at", prepared)
        self.assertNotIn("version", prepared)
        for key, value in before.items():
            if key not in {
                "status",
                "target",
                "created_at",
                "updated_at",
                "version",
            }:
                self.assertEqual(prepared[key], value, key)

    def test_verifies_only_status_and_host_updated_at_change(self) -> None:
        before = self.snapshot()
        after = self.snapshot(status="ACTIVE", updated_at="after")

        verified = SNAPSHOT.verify_status_only_diff(before, after, "ACTIVE")

        self.assertEqual(verified["state"], "verified")
        self.assertEqual(verified["changed_fields"], ["status", "updated_at"])

    def test_rejects_prompt_target_or_shape_drift(self) -> None:
        mutations = []
        prompt_changed = self.snapshot(status="ACTIVE", updated_at="after")
        prompt_changed["prompt"] += "Краткая замена"
        mutations.append(prompt_changed)
        target_changed = self.snapshot(status="ACTIVE", updated_at="after")
        target_changed["target"] = {"threadId": "other-thread"}
        mutations.append(target_changed)
        extra_field = self.snapshot(status="ACTIVE", updated_at="after")
        extra_field["unexpected"] = True
        mutations.append(extra_field)

        for after in mutations:
            with self.subTest(after=after):
                with self.assertRaises(SNAPSHOT.SnapshotError):
                    SNAPSHOT.verify_status_only_diff(
                        self.snapshot(),
                        after,
                        "ACTIVE",
                    )

    def test_required_fields_are_byte_exact_and_target_alias_is_unambiguous(
        self,
    ) -> None:
        for field in ("id", "kind", "name", "prompt", "rrule"):
            after = self.snapshot(status="ACTIVE", updated_at="after")
            after[field] += "-changed"
            with self.subTest(field=field):
                with self.assertRaises(SNAPSHOT.SnapshotError):
                    SNAPSHOT.verify_status_only_diff(
                        self.snapshot(),
                        after,
                        "ACTIVE",
                    )

        ambiguous = self.snapshot()
        ambiguous["targetThreadId"] = "opaque-thread"
        with self.assertRaisesRegex(SNAPSHOT.SnapshotError, "ровно один"):
            SNAPSHOT.prepare_status_update(ambiguous, "ACTIVE")

        snake_case = self.snapshot()
        snake_case["target"] = {
            "type": "thread",
            "thread_id": "opaque-thread",
        }
        prepared = SNAPSHOT.prepare_status_update(snake_case, "ACTIVE")
        self.assertEqual(prepared["targetThreadId"], "opaque-thread")

    def test_created_at_and_version_are_observed_but_never_updated(self) -> None:
        for field in ("created_at", "version"):
            after = self.snapshot(status="ACTIVE", updated_at="after")
            after[field] = "changed"
            with self.subTest(field=field):
                with self.assertRaises(SNAPSHOT.SnapshotError):
                    SNAPSHOT.verify_status_only_diff(
                        self.snapshot(),
                        after,
                        "ACTIVE",
                    )

        unknown_before = self.snapshot()
        unknown_before["unknown_host_field"] = "value"
        with self.assertRaises(SNAPSHOT.SnapshotError):
            SNAPSHOT.prepare_status_update(unknown_before, "ACTIVE")

    def test_cli_prepares_real_snake_case_toml_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            snapshot_path = Path(temporary_directory) / "automation.toml"
            snapshot_path.write_text(
                "\n".join(
                    (
                        "version = 7",
                        'id = "opaque-id"',
                        'kind = "heartbeat"',
                        'name = "Следующий шаг"',
                        'prompt = "Полный prompt\\n"',
                        'rrule = "FREQ=MINUTELY;INTERVAL=5"',
                        'status = "PAUSED"',
                        'target_thread_id = "opaque-thread"',
                        'destination = "local"',
                        'notification_policy = "failed_runs_only"',
                        'created_at = "created"',
                        'updated_at = "before"',
                        "",
                    )
                ),
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(SNAPSHOT_SCRIPT_PATH),
                    "prepare",
                    "--snapshot",
                    str(snapshot_path),
                    "--status",
                    "ACTIVE",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["mode"], "update")
        self.assertEqual(payload["status"], "ACTIVE")
        self.assertEqual(payload["targetThreadId"], "opaque-thread")
        self.assertEqual(payload["notificationPolicy"], "failed_runs_only")
        self.assertNotIn("version", payload)
        self.assertNotIn("created_at", payload)
        self.assertNotIn("updated_at", payload)

    def test_cli_prepare_and_verify_are_canonical_json(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            before_path = root / "before.json"
            after_path = root / "after.json"
            before_path.write_text(
                json.dumps(self.snapshot(), ensure_ascii=False),
                encoding="utf-8",
            )
            after_path.write_text(
                json.dumps(
                    self.snapshot(status="ACTIVE", updated_at="after"),
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            prepared = subprocess.run(
                [
                    sys.executable,
                    str(SNAPSHOT_SCRIPT_PATH),
                    "prepare",
                    "--snapshot",
                    str(before_path),
                    "--status",
                    "ACTIVE",
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            verified = subprocess.run(
                [
                    sys.executable,
                    str(SNAPSHOT_SCRIPT_PATH),
                    "verify",
                    "--before",
                    str(before_path),
                    "--after",
                    str(after_path),
                    "--status",
                    "ACTIVE",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertEqual(prepared.returncode, 0, prepared.stderr)
        self.assertEqual(json.loads(prepared.stdout)["status"], "ACTIVE")
        self.assertEqual(verified.returncode, 0, verified.stderr)
        self.assertEqual(json.loads(verified.stdout)["state"], "verified")


class HeartbeatControlContractTests(unittest.TestCase):
    def test_stop_start_preserves_every_field_and_verifies_status_only_diff(
        self,
    ) -> None:
        prompt = HEARTBEAT_PROMPT_PATH.read_text(encoding="utf-8")
        skill = SKILL_PATH.read_text(encoding="utf-8")

        for text in (prompt, skill):
            self.assertIn("механически сохраня", text)
            self.assertIn("не замен", text)
            self.assertIn("кратк", text)
            self.assertIn("exact-diff", text)
            self.assertIn("только статус", text)
            self.assertIn("одном orchestration-вызове", text)
            self.assertIn("snapshot", text)
            self.assertIn("updated_at", text)
            self.assertIn("finish-own-clean", text)

    def test_new_tick_recovers_only_its_own_clean_unfinished_control(self) -> None:
        prompt = HEARTBEAT_PROMPT_PATH.read_text(encoding="utf-8")
        skill = SKILL_PATH.read_text(encoding="utf-8")

        for text in (prompt, skill):
            self.assertIn("собственн", text)
            self.assertIn("незаверш", text)
            self.assertIn("finish-own-clean", text)
            self.assertIn("ожидающ", text)
            self.assertIn("не запрещает передач", text)
            self.assertIn("следующ", text)
            self.assertIn("чуж", text)
            self.assertIn("гряз", text)

        template = RENDERER.extract_heartbeat_template(prompt)
        identity = template.index("доказательства собственной закреплённой")
        recovery = template.index("finish-own-clean")
        active_exit = template.index(
            "Исключи только эту собственную запись по точному id"
        )
        self.assertLess(identity, recovery)
        self.assertLess(recovery, active_exit)

    def test_permission_retry_is_exact_and_requires_proven_denial(self) -> None:
        prompt = HEARTBEAT_PROMPT_PATH.read_text(encoding="utf-8")
        skill = SKILL_PATH.read_text(encoding="utf-8")

        for text in (prompt, skill):
            self.assertIn("доказан", text)
            self.assertIn("permission", text)
            self.assertIn("точно повтор", text)
            self.assertIn("cwd", text)
            self.assertIn("argv", text)
            self.assertIn("stdin", text)

    def test_renderer_is_explicit_repair_not_implicit_stop_start_replacement(
        self,
    ) -> None:
        prompt = HEARTBEAT_PROMPT_PATH.read_text(encoding="utf-8")
        skill = SKILL_PATH.read_text(encoding="utf-8")

        for text in (prompt, skill):
            self.assertIn("явно запрош", text)
            self.assertIn("repair", text)
            self.assertIn("Штатный `Stop`/`Start`", text)
            self.assertRegex(text, r"не вызыва\w* renderer|renderer не вызыва")


if __name__ == "__main__":
    unittest.main()
