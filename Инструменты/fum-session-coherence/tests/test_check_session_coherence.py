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
        (root / "Запросы" / "2026-06-24_16-26-47_MSK_первый-запрос.md").write_text(
            "\n".join(
                [
                    "# Исходный запрос 2026-06-24 16:26:47 MSK - Первый запрос",
                    "",
                    "## Навигация по запросам",
                    "",
                    "- Предыдущий запрос: нет",
                    "- Следующий запрос: [2026-06-24 16:32:29 MSK - Проверка связности сессии](2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
                    "",
                    "## Текст запроса",
                    "",
                    "> Предыдущий запрос.",
                    "",
                ]
            ),
            encoding="utf-8",
        )

        request_path = (
            root
            / "Запросы"
            / "2026-06-24_16-32-29_MSK_проверка-связности-сессии.md"
        )
        request_path.write_text(
            "\n".join(
                [
                    "# Исходный запрос 2026-06-24 16:32:29 MSK - Проверка связности сессии",
                    "",
                    "## Навигация по запросам",
                    "",
                    "- Предыдущий запрос: [2026-06-24 16:26:47 MSK - Первый запрос](2026-06-24_16-26-47_MSK_первый-запрос.md)",
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
                    "- [Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
                    "- [Запросы/2026-06-24_16-26-47_MSK_первый-запрос.md](2026-06-24_16-26-47_MSK_первый-запрос.md)",
                    "- [Запросы/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
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

        (
            root
            / "Журнал"
            / "2026-06-24_16-32-29_MSK_проверка-связности-сессии.md"
        ).write_text(
            "\n".join(
                [
                    "# Отчёт 2026-06-24 16:32:29 MSK - Проверка связности сессии",
                    "",
                    "## Проверки",
                    "",
                    "- Проверка связности рабочей сессии - прошла.",
                    "",
                    "## Источники",
                    "",
                    "- [исходный запрос 2026-06-24 16:32:29 MSK - Проверка связности сессии](../Запросы/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
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
                    " M Запросы/2026-06-24_16-26-47_MSK_первый-запрос.md",
                    "?? Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md",
                    "?? Запросы/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md",
                ]
            )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status=git_status,
            )

            self.assertEqual(errors, [])

    def test_historical_request_filename_without_title_still_has_old_heading(self):
        request_path = Path("Запросы/2026-06-24_16-32-29_MSK.md")

        self.assertIsNotNone(check_session_coherence.request_match(request_path))
        self.assertEqual(
            check_session_coherence.expected_request_heading(request_path),
            "# Исходный запрос 2026-06-24 16:32:29 MSK",
        )

    def test_new_request_title_must_start_with_infinitive_verb(self):
        request_path = Path("Запросы/2026-07-03_00-00-00_MSK_имена-запросов.md")

        errors = check_session_coherence.validate_request_filename_title(request_path)

        self.assertEqual(
            errors,
            [
                "request filename title must start with an infinitive verb: имена-запросов"
            ],
        )

    def test_historical_request_title_before_infinitive_rule_remains_allowed(self):
        request_path = Path("Запросы/2026-07-02_22-43-41_MSK_имена-файлов-запросов.md")

        errors = check_session_coherence.validate_request_filename_title(request_path)

        self.assertEqual(errors, [])

    def test_new_request_rejects_unqualified_codex_version_fallback(self):
        request_path = Path(
            "Запросы/2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex.md"
        )
        generic_entries = (
            "- Codex - версия не раскрывается средой; использован как агентская среда.",
            "- `Codex` - версия не раскрывается средой; использован как агентская среда.",
            "- ChatGPT/Codex — версия не раскрывается средой; использован как агентская среда.",
            "- `ChatGPT / Codex` – версия не раскрывается средой; использован как агентская среда.",
        )

        for generic_entry in generic_entries:
            with self.subTest(generic_entry=generic_entry):
                text = "\n".join(
                    [
                        "## Использованные инструменты",
                        "",
                        "- [Реестр](../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                        generic_entry,
                        "",
                    ]
                )

                errors = check_session_coherence.validate_used_tools_section(
                    text,
                    request_path,
                )

                self.assertEqual(
                    errors,
                    [
                        "used tools section must qualify the ChatGPT or Codex layer instead of using the generic version fallback"
                    ],
                )

    def test_historical_request_keeps_unqualified_codex_version_fallback(self):
        text = "\n".join(
            [
                "## Использованные инструменты",
                "",
                "- [Реестр](../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                "- Codex - версия не раскрывается средой; использован как агентская среда.",
                "",
            ]
        )
        request_path = Path(
            "Запросы/2026-07-10_05-51-44_MSK_создать-папку-вопросов-и-ответов.md"
        )

        errors = check_session_coherence.validate_used_tools_section(
            text,
            request_path,
        )

        self.assertEqual(errors, [])

    def test_answered_question_file_requires_literal_question_mark(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / "Вопросы и ответы"
            directory.mkdir()
            (directory / "README.md").write_text(
                "# Вопросы и ответы\n",
                encoding="utf-8",
            )
            valid = directory / "верный-вопрос.md"
            valid.write_text(
                "\n".join(
                    [
                        "# Почему это вопрос",
                        "",
                        "## Вопрос",
                        "",
                        "```text",
                        "Почему это вопрос?",
                        "```",
                        "",
                        "## Ответ",
                        "",
                        "Потому что он оканчивается вопросительным знаком.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            invalid = directory / "невопросительный-запрос.md"
            invalid.write_text(
                "\n".join(
                    [
                        "# Создать папку",
                        "",
                        "## Вопрос",
                        "",
                        "```text",
                        "Давай создадим папку вопросов и ответов.",
                        "```",
                        "",
                        "## Ответ",
                        "",
                        "Папка создана.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_answered_question_files(root)

            self.assertEqual(
                errors,
                [
                    "answered-question text must end with '?' in "
                    "Вопросы и ответы/невопросительный-запрос.md"
                ],
            )

    def test_answered_question_file_requires_question_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / "Вопросы и ответы"
            directory.mkdir()
            path = directory / "нет-раздела-вопроса.md"
            path.write_text(
                "# Нет раздела вопроса\n\n## Ответ\n\nОтвет без вопроса.\n",
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_answered_question_files(root)

            self.assertEqual(
                errors,
                [
                    "answered-question text must end with '?' in "
                    "Вопросы и ответы/нет-раздела-вопроса.md"
                ],
            )

    def test_affected_files_accepts_deleted_path_marker(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = root / "Запросы" / "запрос.md"
            request_path.parent.mkdir()
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённый файл: `Вопросы и ответы/ошибочный-материал.md`",
                    "",
                ]
            )

            affected, errors = check_session_coherence.affected_files_from_request(
                text,
                request_path,
                root,
            )

            self.assertEqual(errors, [])
            self.assertEqual(
                affected,
                {(root / "Вопросы и ответы" / "ошибочный-материал.md").resolve()},
            )

    def test_deleted_path_marker_rejects_existing_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = root / "Запросы" / "запрос.md"
            request_path.parent.mkdir()
            existing = root / "Документация" / "существующий-файл.md"
            existing.parent.mkdir()
            existing.write_text("# Существующий файл\n", encoding="utf-8")
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённый файл: `Документация/существующий-файл.md`",
                    "",
                ]
            )

            _, errors = check_session_coherence.affected_files_from_request(
                text,
                request_path,
                root,
            )

            self.assertEqual(
                errors,
                [
                    "deleted affected path still exists: "
                    "Документация/существующий-файл.md"
                ],
            )

    def test_reports_missing_journal(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            (
                root
                / "Журнал"
                / "2026-06-24_16-32-29_MSK_проверка-связности-сессии.md"
            ).unlink()

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertIn(
                "missing journal file: Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md",
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

    def test_reports_case_mismatched_markdown_link_anywhere_in_repo(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            note = root / "Документация" / "индекс.md"
            note.write_text(
                "\n".join(
                    [
                        "# Индекс",
                        "",
                        "[автоматизации](../документация/17-воспроизводимые-автоматизации.md)",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertTrue(
                any(
                    "Markdown link case mismatch in Документация/индекс.md:3" in error
                    and "points to Документация/17-воспроизводимые-автоматизации.md"
                    in error
                    for error in errors
                ),
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
                "- [Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
                "\n".join(
                    [
                        "- [Документация/служебная-записка.md](../Документация/служебная-записка.md)",
                        "- [Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
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
                        "- [исходный запрос 2026-06-24 16:32:29 MSK - Проверка связности сессии](../Запросы/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
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
                "- [Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
                "\n".join(
                    [
                        "- [Документация/служебная-записка.md](../Документация/служебная-записка.md)",
                        "- [Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
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

    def test_reports_mermaid_label_that_starts_as_markdown_list(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            diagram = root / "Документация" / "диаграмма.md"
            diagram.write_text(
                "\n".join(
                    [
                        "# Диаграмма",
                        "",
                        "```mermaid",
                        "flowchart TD",
                        '    A["1. Первый шаг"]',
                        '    B["Этап 2 - Второй шаг"]',
                        "```",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            request_text = request_path.read_text(encoding="utf-8").replace(
                "- [Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
                "\n".join(
                    [
                        "- [Документация/диаграмма.md](../Документация/диаграмма.md)",
                        "- [Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии.md)",
                    ]
                ),
            )
            request_path.write_text(request_text, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="?? Документация/диаграмма.md",
            )

            self.assertIn(
                "unsupported Mermaid Markdown list label in Документация/диаграмма.md:5: use text like 'Этап 1 - ...' instead of '1. ...'",
                errors,
            )


if __name__ == "__main__":
    unittest.main()
