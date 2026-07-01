import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "check-session-coherence.py"
)

spec = importlib.util.spec_from_file_location("check_session_coherence", SCRIPT_PATH)
check_session_coherence = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = check_session_coherence
spec.loader.exec_module(check_session_coherence)


class CheckSessionCoherenceTests(unittest.TestCase):
    def write_fixture(self, root: Path) -> Path:
        (root / "Запросы").mkdir()
        (root / "Журнал").mkdir()
        (root / "Документация").mkdir()
        (root / "Инструменты").mkdir()

        (root / "Документация" / "17-воспроизводимые-автоматизации.md").write_text(
            "# Воспроизводимые автоматизации FUM\n",
            encoding="utf-8",
        )
        (root / "Инструменты" / "реестр-системных-приложений-и-инструментов.md").write_text(
            "# Реестр системных приложений и инструментов\n",
            encoding="utf-8",
        )
        (root / "Запросы" / "2026-06-24_16-26-47_MSK.md").write_text(
            "\n".join(
                [
                    "# Исходный запрос 2026-06-24 16:26:47 MSK",
                    "",
                    "## Навигация по запросам",
                    "",
                    "- Предыдущий запрос: нет",
                    "- Следующий запрос: [2026-06-24 16:32:29 MSK](2026-06-24_16-32-29_MSK.md)",
                    "",
                    "## Текст запроса",
                    "",
                    "> Предыдущий запрос.",
                    "",
                ]
            ),
            encoding="utf-8",
        )

        request_path = root / "Запросы" / "2026-06-24_16-32-29_MSK.md"
        request_path.write_text(
            "\n".join(
                [
                    "# Исходный запрос 2026-06-24 16:32:29 MSK",
                    "",
                    "## Навигация по запросам",
                    "",
                    "- Предыдущий запрос: [2026-06-24 16:26:47 MSK](2026-06-24_16-26-47_MSK.md)",
                    "- Следующий запрос: нет",
                    "",
                    "## Текст запроса",
                    "",
                    "> Выделить автоматическую проверку связности рабочей сессии.",
                    "",
                    "## Использованные инструменты",
                    "",
                    "- [Реестр системных приложений и инструментов](../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                    "- `python3` - использован для запуска проверки.",
                    "",
                    "## Повлиял на файлы",
                    "",
                    "- [Документация/17-воспроизводимые-автоматизации.md](../Документация/17-воспроизводимые-автоматизации.md)",
                    "- [Журнал/2026-06-24_16-32-29_MSK.md](../Журнал/2026-06-24_16-32-29_MSK.md)",
                    "- [Запросы/2026-06-24_16-26-47_MSK.md](2026-06-24_16-26-47_MSK.md)",
                    "- [Запросы/2026-06-24_16-32-29_MSK.md](2026-06-24_16-32-29_MSK.md)",
                    "",
                    "## Проверки",
                    "",
                    "- Проверка связности рабочей сессии - прошла.",
                    "",
                    "## Описание сделанного",
                    "",
                    "Добавлена проверка [воспроизводимых автоматизаций](../Документация/17-воспроизводимые-автоматизации.md).",
                    "",
                ]
            ),
            encoding="utf-8",
        )

        (root / "Журнал" / "2026-06-24_16-32-29_MSK.md").write_text(
            "\n".join(
                [
                    "# Отчёт 2026-06-24 16:32:29 MSK",
                    "",
                    "## Проверки",
                    "",
                    "- Проверка связности рабочей сессии - прошла.",
                    "",
                    "## Источники",
                    "",
                    "- [исходный запрос 2026-06-24 16:32:29 MSK](../Запросы/2026-06-24_16-32-29_MSK.md)",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        return request_path

    def test_valid_session_with_listed_dirty_files_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            git_status = "\n".join(
                [
                    " M Документация/17-воспроизводимые-автоматизации.md",
                    " M Запросы/2026-06-24_16-26-47_MSK.md",
                    "?? Журнал/2026-06-24_16-32-29_MSK.md",
                    "?? Запросы/2026-06-24_16-32-29_MSK.md",
                ]
            )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status=git_status,
            )

            self.assertEqual(errors, [])

    def test_reports_missing_journal(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            (root / "Журнал" / "2026-06-24_16-32-29_MSK.md").unlink()

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertIn(
                "missing journal file: Журнал/2026-06-24_16-32-29_MSK.md",
                errors,
            )

    def test_reports_broken_markdown_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            broken = request_path.read_text(encoding="utf-8").replace(
                "../Документация/17-воспроизводимые-автоматизации.md",
                "../Документация/нет-такого-файла.md",
            )
            request_path.write_text(broken, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertTrue(
                any("broken Markdown link" in error for error in errors),
                errors,
            )

    def test_reports_unlisted_git_status_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            git_status = "?? temporary-debug.log\n"

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status=git_status,
            )

            self.assertIn("unexpected Git status path: temporary-debug.log", errors)

    def test_reports_md_recency_check_failure_when_tool_exists(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            script = (
                root
                / "Инструменты"
                / "fum-md-recency"
                / "scripts"
                / "update-md-recency.py"
            )
            script.parent.mkdir(parents=True)
            script.write_text(
                "import sys\nprint('stale recency index', file=sys.stderr)\nsys.exit(1)\n",
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertIn(
                "md recency check failed: stale recency index",
                errors,
            )

    def test_reports_possible_meta_request_without_request_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            note = root / "Документация" / "служебная-записка.md"
            note.write_text(
                "\n".join(
                    [
                        "# Служебная записка",
                        "",
                        "Пользователь уточнил правило ведения памяти FUM: такие ответы надо сохранять в `Запросы/`.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            request_text = request_path.read_text(encoding="utf-8").replace(
                "- [Журнал/2026-06-24_16-32-29_MSK.md](../Журнал/2026-06-24_16-32-29_MSK.md)",
                "\n".join(
                    [
                        "- [Документация/служебная-записка.md](../Документация/служебная-записка.md)",
                        "- [Журнал/2026-06-24_16-32-29_MSK.md](../Журнал/2026-06-24_16-32-29_MSK.md)",
                    ]
                ),
            )
            request_path.write_text(request_text, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="?? Документация/служебная-записка.md",
            )

            self.assertIn(
                "possible unregistered meta request in Документация/служебная-записка.md:3: add a link to a concrete request file in Запросы/ or create a separate request file",
                errors,
            )

    def test_detects_meta_request_context_from_requests_directory_marker(self):
        text = "Пользователь спросил, нужно ли сохранять это в `Запросы/`."

        line = check_session_coherence.possible_meta_request_line(text)

        self.assertEqual(line, 1)

    def test_reports_top_provenance_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            note = root / "Документация" / "служебная-записка.md"
            note.write_text(
                "\n".join(
                    [
                        "# Служебная записка",
                        "",
                        "Источники требований:",
                        "",
                        "- [исходный запрос 2026-06-24 16:32:29 MSK](../Запросы/2026-06-24_16-32-29_MSK.md)",
                        "",
                        "## Содержание",
                        "",
                        "Основной текст.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            request_text = request_path.read_text(encoding="utf-8").replace(
                "- [Журнал/2026-06-24_16-32-29_MSK.md](../Журнал/2026-06-24_16-32-29_MSK.md)",
                "\n".join(
                    [
                        "- [Документация/служебная-записка.md](../Документация/служебная-записка.md)",
                        "- [Журнал/2026-06-24_16-32-29_MSK.md](../Журнал/2026-06-24_16-32-29_MSK.md)",
                    ]
                ),
            )
            request_path.write_text(request_text, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="?? Документация/служебная-записка.md",
            )

            self.assertIn(
                "provenance section must follow content in Документация/служебная-записка.md:3: move 'Источники требований:' to the bottom of the file before FUM-MD-RECENCY",
                errors,
            )


if __name__ == "__main__":
    unittest.main()
