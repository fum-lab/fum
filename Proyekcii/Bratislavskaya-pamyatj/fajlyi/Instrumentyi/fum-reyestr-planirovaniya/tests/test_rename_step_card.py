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
    def git(сам, корень: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *args],
            cwd=корень,
            check=True,
            capture_output=True,
            text=True,
        )

    def load_script_module(сам):
        module_name = f"fum_rename_step_card_under_test_{id(сам)}"
        spec = importlib.util.spec_from_file_location(module_name, SCRIPT_PATH)
        сам.assertIsNotNone(spec)
        сам.assertIsNotNone(spec.loader)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        return module

    def write_fixture(сам, корень: Path) -> None:
        cards = корень / "Планирование" / "карточки-шагов"
        journal = корень / "Журнал"
        sources = корень / "Источники" / "сырой-снимок"
        cards.mkdir(parents=True)
        journal.mkdir()
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
        (корень / "Планирование" / "план.md").write_text(
            "# План\n",
            encoding="utf-8",
        )
        (корень / "Планирование" / "следующий-шаг.md").write_text(
            "# Следующий шаг\n\n"
            "```toml\n"
            f'card_path = "{OLD_REPO_PATH}"\n'
            "```\n",
            encoding="utf-8",
        )

        request_one = (
            journal
            / "2026-01-01_00-00-00_MSK_проверить-ссылки"
            / "запрос.md"
        )
        request_one.parent.mkdir()
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
        request_two = (
            journal
            / "2026-01-01_00-00-01_MSK_проверить-вторую-ссылку"
            / "запрос.md"
        )
        request_two.parent.mkdir()
        request_two.write_text(
            "# Исходный запрос\n\n"
            "## Текст запроса\n\n```text\nБез пути.\n```\n\n"
            "## Повлиял на файлы\n\n"
            f"- [{OLD_REPO_PATH}](<../{OLD_REPO_PATH}>)\n",
            encoding="utf-8",
        )
        (request_one.parent / "отчёт.md").write_text(
            "# Отчёт\n\n"
            f"Живая ссылка на карточку: {OLD_REPO_PATH}.\n",
            encoding="utf-8",
        )
        (корень / "Планирование" / "реестр.json").write_text(
            json.dumps({"card_path": OLD_REPO_PATH}, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        (sources / "источник.md").write_text(
            f"Сырой источник хранит прежний путь {OLD_REPO_PATH}.\n",
            encoding="utf-8",
        )
        (корень / "двоичный.bin").write_bytes(
            b"\xff\xfe" + OLD_NAME.encode("utf-8")
        )
        (корень / "нулевой-байт.bin").write_bytes(
            b"binary\0" + OLD_NAME.encode("utf-8")
        )

        сам.git(корень, "init", "-q")
        сам.git(корень, "config", "user.name", "FUM Test")
        сам.git(корень, "config", "user.email", "fum-test@example.invalid")
        сам.git(корень, "add", ".")
        сам.git(корень, "commit", "-qm", "fixture")

    def run_script(
        сам,
        корень: Path,
        *arguments: str,
        card_id: str = "FUM-STEP-0001",
        include_repo_root: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        repository_arguments = (
            ["--repo-root", str(корень)] if include_repo_root else []
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
            cwd=корень,
            capture_output=True,
            text=True,
            env=environment,
        )

    def test_status_change_moves_with_git_and_updates_only_live_texts(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            first_request = (
                корень
                / "Журнал"
                / "2026-01-01_00-00-00_MSK_проверить-ссылки"
                / "запрос.md"
            )
            raw_request_before = first_request.read_text(encoding="utf-8").split(
                "## Повлиял на файлы",
                1,
            )[0]
            raw_source_before = (
                корень / "Источники" / "сырой-снимок" / "источник.md"
            ).read_bytes()
            binary_before = (корень / "двоичный.bin").read_bytes()
            nul_binary_before = (корень / "нулевой-байт.bin").read_bytes()

            результат = сам.run_script(корень, "--status", "completed")

            сам.assertEqual(результат.returncode, 0, результат.stderr)
            payload = json.loads(результат.stdout)
            сам.assertEqual(payload["old_path"], OLD_REPO_PATH)
            сам.assertEqual(payload["new_path"], NEW_REPO_PATH)
            сам.assertGreaterEqual(payload["updated_occurrences"], 6)
            сам.assertEqual(payload["preserved_source_occurrences"], 2)

            old_card = корень / OLD_REPO_PATH
            new_card = корень / NEW_REPO_PATH
            сам.assertFalse(old_card.exists())
            сам.assertTrue(new_card.exists())
            сам.assertIn(
                'status = "completed"',
                new_card.read_text(encoding="utf-8"),
            )

            index = (
                корень / "Планирование" / "карточки-шагов" / "README.md"
            ).read_text(encoding="utf-8")
            сам.assertIn("✅ Выполнено", index)
            сам.assertIn(NEW_NAME, index)
            сам.assertNotIn(OLD_NAME, index)

            first_text = first_request.read_text(encoding="utf-8")
            сам.assertEqual(
                first_text.split("## Повлиял на файлы", 1)[0],
                raw_request_before,
            )
            сам.assertEqual(first_text.count(OLD_NAME), 1)
            сам.assertIn(NEW_NAME, first_text)

            second_text = (
                корень
                / "Журнал"
                / "2026-01-01_00-00-01_MSK_проверить-вторую-ссылку"
                / "запрос.md"
            ).read_text(encoding="utf-8")
            сам.assertNotIn(OLD_NAME, second_text)
            сам.assertIn(f"<../{NEW_REPO_PATH}>", second_text)

            report_text = (first_request.parent / "отчёт.md").read_text(
                encoding="utf-8"
            )
            сам.assertIn(NEW_REPO_PATH, report_text)
            сам.assertNotIn(OLD_NAME, report_text)

            selector = (
                корень / "Планирование" / "следующий-шаг.md"
            ).read_text(encoding="utf-8")
            registry = (
                корень / "Планирование" / "реестр.json"
            ).read_text(encoding="utf-8")
            сам.assertIn(NEW_REPO_PATH, selector)
            сам.assertIn(NEW_REPO_PATH, registry)
            сам.assertNotIn(OLD_NAME, selector + registry)

            сам.assertEqual(
                (корень / "Источники" / "сырой-снимок" / "источник.md").read_bytes(),
                raw_source_before,
            )
            сам.assertEqual((корень / "двоичный.bin").read_bytes(), binary_before)
            сам.assertEqual(
                (корень / "нулевой-байт.bin").read_bytes(),
                nul_binary_before,
            )

            cached = сам.git(
                корень,
                "-c",
                "core.quotePath=false",
                "diff",
                "--cached",
                "--name-status",
                "--find-renames",
            ).stdout
            сам.assertIn(f"R100\t{OLD_REPO_PATH}\t{NEW_REPO_PATH}", cached)

    def test_repo_root_defaults_to_current_worktree(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)

            результат = сам.run_script(
                корень,
                "--status",
                "completed",
                include_repo_root=False,
            )

            сам.assertEqual(результат.returncode, 0, результат.stderr)
            сам.assertFalse((корень / OLD_REPO_PATH).exists())
            сам.assertTrue((корень / NEW_REPO_PATH).exists())

    def test_проекция_исключена_из_живых_замен_а_близкий_путь_нет(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            проекция = (
                корень
                / "Proyekcii"
                / "Bratislavskaya-pamyatj"
                / "fajlyi"
                / "proizvodnaya-ssyilka.md"
            )
            близкий_путь = корень / "Proyekcii-ne-kanonicheskaya" / "ssyilka.md"
            for путь in (проекция, близкий_путь):
                путь.parent.mkdir(parents=True, exist_ok=True)
                путь.write_text(f"Ссылка: {OLD_REPO_PATH}.\n", encoding="utf-8")
            сам.git(корень, "add", "-f", "--", "Proyekcii")
            сам.git(корень, "add", "--", "Proyekcii-ne-kanonicheskaya")
            сам.git(корень, "commit", "-qm", "projection boundary")
            проекция_до = проекция.read_bytes()

            результат = сам.run_script(корень, "--status", "completed")

            сам.assertEqual(результат.returncode, 0, результат.stderr)
            сам.assertEqual(проекция.read_bytes(), проекция_до)
            сам.assertIn(
                NEW_REPO_PATH,
                близкий_путь.read_text(encoding="utf-8"),
            )
            сам.assertNotIn(
                OLD_REPO_PATH,
                близкий_путь.read_text(encoding="utf-8"),
            )

    def test_write_failure_restores_files_and_git_rename(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            module = сам.load_script_module()

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
                repo_root=корень,
                card_id="FUM-STEP-0001",
                status="completed",
                description=None,
            )
            with mock.patch.object(
                module.os,
                "replace",
                side_effect=fail_second_replacement,
            ):
                with сам.assertRaisesRegex(ValueError, "rolled back"):
                    module.execute(arguments)

            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertFalse((корень / NEW_REPO_PATH).exists())
            сам.assertEqual(сам.git(корень, "status", "--short").stdout, "")
            сам.assertEqual(list(корень.rglob(".fum-step-card-*")), [])

    def test_interrupt_restores_files_and_git_rename(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            module = сам.load_script_module()
            real_replace = os.replace

            def interrupt_first_replacement(source, destination):
                if Path(source).name.startswith(".fum-step-card-new-"):
                    raise KeyboardInterrupt()
                return real_replace(source, destination)

            arguments = types.SimpleNamespace(
                repo_root=корень,
                card_id="FUM-STEP-0001",
                status="completed",
                description=None,
            )
            with mock.patch.object(
                module.os,
                "replace",
                side_effect=interrupt_first_replacement,
            ):
                with сам.assertRaises(KeyboardInterrupt):
                    module.execute(arguments)

            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertFalse((корень / NEW_REPO_PATH).exists())
            сам.assertEqual(сам.git(корень, "status", "--short").stdout, "")
            сам.assertEqual(list(корень.rglob(".fum-step-card-*")), [])

    def test_incomplete_rollback_preserves_backup_files(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            module = сам.load_script_module()
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
                repo_root=корень,
                card_id="FUM-STEP-0001",
                status="completed",
                description=None,
            )
            with mock.patch.object(
                module.os,
                "replace",
                side_effect=fail_install_and_restore,
            ):
                with сам.assertRaisesRegex(
                    ValueError,
                    "backup preserved at",
                ):
                    module.execute(arguments)

            backups = list(корень.rglob(".fum-step-card-backup-*"))
            сам.assertGreaterEqual(len(backups), 1)

    def test_untracked_duplicate_card_id_fails_before_any_mutation(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            duplicate = (
                корень
                / "Планирование"
                / "карточки-шагов"
                / "🟡-FUM-STEP-0001-дубликат.md"
            )
            duplicate.write_text(
                (корень / OLD_REPO_PATH).read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            status_before = сам.git(корень, "status", "--short").stdout

            результат = сам.run_script(корень, "--status", "completed")

            сам.assertNotEqual(результат.returncode, 0)
            сам.assertIn("multiple live step cards", результат.stderr)
            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertFalse((корень / NEW_REPO_PATH).exists())
            сам.assertEqual(
                сам.git(корень, "status", "--short").stdout,
                status_before,
            )

    def test_unavailable_tracked_branch_record_fails_before_any_mutation(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            selectors = корень / "Планирование" / "следующие-шаги-веток"
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
            сам.git(корень, "add", ".")
            сам.git(корень, "commit", "-qm", "add branch selector")
            record.unlink()
            status_before = сам.git(корень, "status", "--short").stdout

            результат = сам.run_script(корень, "--status", "completed")

            сам.assertNotEqual(результат.returncode, 0)
            сам.assertIn("not live UTF-8 text", результат.stderr)
            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertFalse((корень / NEW_REPO_PATH).exists())
            сам.assertEqual(
                сам.git(корень, "status", "--short").stdout,
                status_before,
            )

    def test_invalid_description_fails_before_any_mutation(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)

            результат = сам.run_script(
                корень,
                "--status",
                "completed",
                "--description",
                "недопустимое_имя",
            )

            сам.assertNotEqual(результат.returncode, 0)
            сам.assertIn("description", результат.stderr)
            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertFalse((корень / NEW_REPO_PATH).exists())
            сам.assertEqual(сам.git(корень, "status", "--short").stdout, "")

    def test_selected_card_requires_fresh_branch_step_before_rename(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            selectors = корень / "Планирование" / "следующие-шаги-веток"
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
            сам.git(корень, "add", ".")
            сам.git(корень, "commit", "-qm", "add branch selector")

            результат = сам.run_script(корень, "--status", "completed")

            сам.assertNotEqual(результат.returncode, 0)
            сам.assertIn("step_id", результат.stderr)
            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertFalse((корень / NEW_REPO_PATH).exists())
            сам.assertEqual(сам.git(корень, "status", "--short").stdout, "")

    def test_existing_destination_fails_before_any_mutation(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            destination = корень / NEW_REPO_PATH
            destination.write_text("Не перезаписывать.\n", encoding="utf-8")
            сам.git(корень, "add", ".")
            сам.git(корень, "commit", "-qm", "add occupied destination")

            результат = сам.run_script(корень, "--status", "completed")

            сам.assertNotEqual(результат.returncode, 0)
            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertEqual(
                destination.read_text(encoding="utf-8"),
                "Не перезаписывать.\n",
            )
            сам.assertEqual(сам.git(корень, "status", "--short").stdout, "")

    def test_unknown_card_id_fails_before_any_mutation(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)

            результат = сам.run_script(
                корень,
                "--status",
                "completed",
                card_id="FUM-STEP-9999",
            )

            сам.assertNotEqual(результат.returncode, 0)
            сам.assertIn("FUM-STEP-9999", результат.stderr)
            сам.assertTrue((корень / OLD_REPO_PATH).exists())
            сам.assertEqual(сам.git(корень, "status", "--short").stdout, "")


if __name__ == "__main__":
    unittest.main()
