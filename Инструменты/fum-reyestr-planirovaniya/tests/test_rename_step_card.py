import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import types
import unittest
from unittest import mock
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "rename-step-card.py"
)

OLD_NAME = "🟡-FUM-STEP-0001-проверить-ссылки.md"
NEW_NAME = "✅-FUM-STEP-0001-проверить-ссылки.md"
OLD_REPO_PATH = f"Планирование/карточки-шагов/{OLD_NAME}"
NEW_REPO_PATH = f"Планирование/карточки-шагов/{NEW_NAME}"


class RenameStepCardTests(unittest.TestCase):
    def git(self, root: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *args],
            cwd=root,
            check=True,
            capture_output=True,
            text=True,
        )

    def load_script_module(self):
        module_name = f"fum_rename_step_card_under_test_{id(self)}"
        spec = importlib.util.spec_from_file_location(module_name, SCRIPT_PATH)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        return module

    def write_fixture(self, root: Path) -> None:
        cards = root / "Планирование" / "карточки-шагов"
        requests = root / "Запросы"
        sources = root / "Источники" / "сырой-снимок"
        cards.mkdir(parents=True)
        requests.mkdir()
        sources.mkdir(parents=True)

        (cards / OLD_NAME).write_text(
            "+++\n"
            "schema_version = 1\n"
            'card_id = "FUM-STEP-0001"\n'
            'status = "active"\n'
            "+++\n"
            "# Проверить ссылки\n\n"
            "## Задача\n\nПроверить ссылки.\n\n"
            "## Результат\n\nСсылки проверены.\n\n"
            "## Источники\n\n- [план](../план.md)\n",
            encoding="utf-8",
        )
        (cards / "README.md").write_text(
            "# Карточки шагов FUM\n\n"
            "## Индекс карточек\n\n"
            "| Идентификатор | Статус      | Карточка                  |\n"
            "| ------------- | ----------- | ------------------------- |\n"
            f"| FUM-STEP-0001 | 🟡 Актуально | [Проверить ссылки]({OLD_NAME}) |\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "план.md").write_text(
            "# План\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "следующий-шаг.md").write_text(
            "# Следующий шаг\n\n"
            "```toml\n"
            f'card_path = "{OLD_REPO_PATH}"\n'
            "```\n",
            encoding="utf-8",
        )

        request_one = requests / "2026-01-01_00-00-00_MSK_проверить-ссылки.md"
        request_one.write_text(
            "# Исходный запрос\n\n"
            "## Текст запроса\n\n"
            "```text\n"
            "В исходном payload был путь:\n"
            f'"card_path": "{OLD_REPO_PATH}"\n'
            "## Это заголовок внутри дословного блока\n"
            "```\n\n"
            "## Повлиял на файлы\n\n"
            f"- [{OLD_REPO_PATH}](../{OLD_REPO_PATH})\n",
            encoding="utf-8",
        )
        request_two = requests / "2026-01-01_00-00-01_MSK_проверить-вторую-ссылку.md"
        request_two.write_text(
            "# Исходный запрос\n\n"
            "## Текст запроса\n\n```text\nБез пути.\n```\n\n"
            "## Повлиял на файлы\n\n"
            f"- [{OLD_REPO_PATH}](<../{OLD_REPO_PATH}>)\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "реестр.json").write_text(
            json.dumps({"card_path": OLD_REPO_PATH}, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        (sources / "источник.md").write_text(
            f"Сырой источник хранит прежний путь {OLD_REPO_PATH}.\n",
            encoding="utf-8",
        )
        (root / "двоичный.bin").write_bytes(
            b"\xff\xfe" + OLD_NAME.encode("utf-8")
        )
        (root / "нулевой-байт.bin").write_bytes(
            b"binary\0" + OLD_NAME.encode("utf-8")
        )

        self.git(root, "init", "-q")
        self.git(root, "config", "user.name", "FUM Test")
        self.git(root, "config", "user.email", "fum-test@example.invalid")
        self.git(root, "add", ".")
        self.git(root, "commit", "-qm", "fixture")

    def run_script(
        self,
        root: Path,
        *arguments: str,
        card_id: str = "FUM-STEP-0001",
        include_repo_root: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        repository_arguments = (
            ["--repo-root", str(root)] if include_repo_root else []
        )
        return subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                *repository_arguments,
                "--card-id",
                card_id,
                *arguments,
            ],
            cwd=root,
            capture_output=True,
            text=True,
            env=environment,
        )

    def test_status_change_moves_with_git_and_updates_only_live_texts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            first_request = (
                root
                / "Запросы"
                / "2026-01-01_00-00-00_MSK_проверить-ссылки.md"
            )
            raw_request_before = first_request.read_text(encoding="utf-8").split(
                "## Повлиял на файлы",
                1,
            )[0]
            raw_source_before = (
                root / "Источники" / "сырой-снимок" / "источник.md"
            ).read_bytes()
            binary_before = (root / "двоичный.bin").read_bytes()
            nul_binary_before = (root / "нулевой-байт.bin").read_bytes()

            result = self.run_script(root, "--status", "completed")

            self.assertEqual(result.returncode, 0, result.stderr)
            payload = json.loads(result.stdout)
            self.assertEqual(payload["old_path"], OLD_REPO_PATH)
            self.assertEqual(payload["new_path"], NEW_REPO_PATH)
            self.assertGreaterEqual(payload["updated_occurrences"], 6)
            self.assertEqual(payload["preserved_source_occurrences"], 2)

            old_card = root / OLD_REPO_PATH
            new_card = root / NEW_REPO_PATH
            self.assertFalse(old_card.exists())
            self.assertTrue(new_card.exists())
            self.assertIn(
                'status = "completed"',
                new_card.read_text(encoding="utf-8"),
            )

            index = (
                root / "Планирование" / "карточки-шагов" / "README.md"
            ).read_text(encoding="utf-8")
            self.assertIn("✅ Выполнено", index)
            self.assertIn(NEW_NAME, index)
            self.assertNotIn(OLD_NAME, index)

            first_text = first_request.read_text(encoding="utf-8")
            self.assertEqual(
                first_text.split("## Повлиял на файлы", 1)[0],
                raw_request_before,
            )
            self.assertEqual(first_text.count(OLD_NAME), 1)
            self.assertIn(NEW_NAME, first_text)

            second_text = (
                root
                / "Запросы"
                / "2026-01-01_00-00-01_MSK_проверить-вторую-ссылку.md"
            ).read_text(encoding="utf-8")
            self.assertNotIn(OLD_NAME, second_text)
            self.assertIn(f"<../{NEW_REPO_PATH}>", second_text)

            selector = (
                root / "Планирование" / "следующий-шаг.md"
            ).read_text(encoding="utf-8")
            registry = (
                root / "Планирование" / "реестр.json"
            ).read_text(encoding="utf-8")
            self.assertIn(NEW_REPO_PATH, selector)
            self.assertIn(NEW_REPO_PATH, registry)
            self.assertNotIn(OLD_NAME, selector + registry)

            self.assertEqual(
                (root / "Источники" / "сырой-снимок" / "источник.md").read_bytes(),
                raw_source_before,
            )
            self.assertEqual((root / "двоичный.bin").read_bytes(), binary_before)
            self.assertEqual(
                (root / "нулевой-байт.bin").read_bytes(),
                nul_binary_before,
            )

            cached = self.git(
                root,
                "-c",
                "core.quotePath=false",
                "diff",
                "--cached",
                "--name-status",
                "--find-renames",
            ).stdout
            self.assertIn(f"R100\t{OLD_REPO_PATH}\t{NEW_REPO_PATH}", cached)

    def test_repo_root_defaults_to_current_worktree(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)

            result = self.run_script(
                root,
                "--status",
                "completed",
                include_repo_root=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse((root / OLD_REPO_PATH).exists())
            self.assertTrue((root / NEW_REPO_PATH).exists())

    def test_write_failure_restores_files_and_git_rename(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            module = self.load_script_module()

            real_replace = os.replace
            replacement_count = 0

            def fail_second_replacement(source, destination):
                nonlocal replacement_count
                if Path(source).name.startswith(".fum-step-card-new-"):
                    replacement_count += 1
                    if replacement_count == 2:
                        raise OSError("injected replacement failure")
                return real_replace(source, destination)

            arguments = types.SimpleNamespace(
                repo_root=root,
                card_id="FUM-STEP-0001",
                status="completed",
                description=None,
            )
            with mock.patch.object(
                module.os,
                "replace",
                side_effect=fail_second_replacement,
            ):
                with self.assertRaisesRegex(ValueError, "rolled back"):
                    module.execute(arguments)

            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertFalse((root / NEW_REPO_PATH).exists())
            self.assertEqual(self.git(root, "status", "--short").stdout, "")
            self.assertEqual(list(root.rglob(".fum-step-card-*")), [])

    def test_interrupt_restores_files_and_git_rename(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            module = self.load_script_module()
            real_replace = os.replace

            def interrupt_first_replacement(source, destination):
                if Path(source).name.startswith(".fum-step-card-new-"):
                    raise KeyboardInterrupt()
                return real_replace(source, destination)

            arguments = types.SimpleNamespace(
                repo_root=root,
                card_id="FUM-STEP-0001",
                status="completed",
                description=None,
            )
            with mock.patch.object(
                module.os,
                "replace",
                side_effect=interrupt_first_replacement,
            ):
                with self.assertRaises(KeyboardInterrupt):
                    module.execute(arguments)

            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertFalse((root / NEW_REPO_PATH).exists())
            self.assertEqual(self.git(root, "status", "--short").stdout, "")
            self.assertEqual(list(root.rglob(".fum-step-card-*")), [])

    def test_incomplete_rollback_preserves_backup_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            module = self.load_script_module()
            real_replace = os.replace
            replacement_count = 0

            def fail_install_and_restore(source, destination):
                nonlocal replacement_count
                name = Path(source).name
                if name.startswith(".fum-step-card-new-"):
                    replacement_count += 1
                    if replacement_count == 2:
                        raise OSError("injected replacement failure")
                if name.startswith(".fum-step-card-backup-"):
                    raise OSError("injected rollback failure")
                return real_replace(source, destination)

            arguments = types.SimpleNamespace(
                repo_root=root,
                card_id="FUM-STEP-0001",
                status="completed",
                description=None,
            )
            with mock.patch.object(
                module.os,
                "replace",
                side_effect=fail_install_and_restore,
            ):
                with self.assertRaisesRegex(
                    ValueError,
                    "backup preserved at",
                ):
                    module.execute(arguments)

            backups = list(root.rglob(".fum-step-card-backup-*"))
            self.assertGreaterEqual(len(backups), 1)

    def test_untracked_duplicate_card_id_fails_before_any_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            duplicate = (
                root
                / "Планирование"
                / "карточки-шагов"
                / "🟡-FUM-STEP-0001-дубликат.md"
            )
            duplicate.write_text(
                (root / OLD_REPO_PATH).read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            status_before = self.git(root, "status", "--short").stdout

            result = self.run_script(root, "--status", "completed")

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("multiple live step cards", result.stderr)
            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertFalse((root / NEW_REPO_PATH).exists())
            self.assertEqual(
                self.git(root, "status", "--short").stdout,
                status_before,
            )

    def test_unavailable_tracked_branch_record_fails_before_any_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            selectors = root / "Планирование" / "следующие-шаги-веток"
            selectors.mkdir()
            record = selectors / "master.md"
            record.write_text(
                "# Следующий шаг ветки\n\n"
                "```toml\n"
                'step_id = "master-fum-step-0001-ready-v1"\n'
                'card_id = "FUM-STEP-0001"\n'
                f'card_path = "{OLD_REPO_PATH}"\n'
                "```\n",
                encoding="utf-8",
            )
            self.git(root, "add", ".")
            self.git(root, "commit", "-qm", "add branch selector")
            record.unlink()
            status_before = self.git(root, "status", "--short").stdout

            result = self.run_script(root, "--status", "completed")

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("not live UTF-8 text", result.stderr)
            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertFalse((root / NEW_REPO_PATH).exists())
            self.assertEqual(
                self.git(root, "status", "--short").stdout,
                status_before,
            )

    def test_invalid_description_fails_before_any_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)

            result = self.run_script(
                root,
                "--status",
                "completed",
                "--description",
                "недопустимое_имя",
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("description", result.stderr)
            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertFalse((root / NEW_REPO_PATH).exists())
            self.assertEqual(self.git(root, "status", "--short").stdout, "")

    def test_selected_card_requires_fresh_branch_step_before_rename(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            selectors = root / "Планирование" / "следующие-шаги-веток"
            selectors.mkdir()
            (selectors / "master.md").write_text(
                "# Следующий шаг ветки\n\n"
                "```toml\n"
                'step_id = "master-fum-step-0001-ready-v1"\n'
                'card_id = "FUM-STEP-0001"\n'
                f'card_path = "{OLD_REPO_PATH}"\n'
                "```\n",
                encoding="utf-8",
            )
            self.git(root, "add", ".")
            self.git(root, "commit", "-qm", "add branch selector")

            result = self.run_script(root, "--status", "completed")

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("step_id", result.stderr)
            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertFalse((root / NEW_REPO_PATH).exists())
            self.assertEqual(self.git(root, "status", "--short").stdout, "")

    def test_existing_destination_fails_before_any_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            destination = root / NEW_REPO_PATH
            destination.write_text("Не перезаписывать.\n", encoding="utf-8")
            self.git(root, "add", ".")
            self.git(root, "commit", "-qm", "add occupied destination")

            result = self.run_script(root, "--status", "completed")

            self.assertNotEqual(result.returncode, 0)
            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertEqual(
                destination.read_text(encoding="utf-8"),
                "Не перезаписывать.\n",
            )
            self.assertEqual(self.git(root, "status", "--short").stdout, "")

    def test_unknown_card_id_fails_before_any_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)

            result = self.run_script(
                root,
                "--status",
                "completed",
                card_id="FUM-STEP-9999",
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("FUM-STEP-9999", result.stderr)
            self.assertTrue((root / OLD_REPO_PATH).exists())
            self.assertEqual(self.git(root, "status", "--short").stdout, "")


if __name__ == "__main__":
    unittest.main()
