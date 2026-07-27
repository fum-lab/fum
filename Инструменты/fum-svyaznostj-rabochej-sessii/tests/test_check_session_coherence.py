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

    def write_time_profile_journal(
        self,
        root: Path,
        *,
        request_name: str,
        request_label: str,
        invocation_rows: list[str] | None,
        invocation_total: str | None,
    ) -> Path:
        (root / "Запросы").mkdir()
        (root / "Журнал").mkdir()
        request_path = root / "Запросы" / request_name
        lines = [
            f"# Отчёт {request_label}",
            "",
            "Отчёт с измеренным профилем.",
            "",
            "## Профиль времени выполнения",
            "",
            "| Стадия | Длительность | Границы и способ измерения |",
            "| --- | ---: | --- |",
            "| Анализ | 12 с | Монотонные отметки. |",
            "| Проверки | 31 с | Wall-clock `real`. |",
            "",
            "Граница профиля: от допуска очереди до завершения проверок.",
            "",
        ]
        if invocation_rows is not None:
            lines.extend(
                [
                    "### Прямые запуски проверок",
                    "",
                    "| Вызов | Длительность | Результат |",
                    "| --- | ---: | --- |",
                    *invocation_rows,
                    "",
                ]
            )
            if invocation_total is not None:
                lines.extend([invocation_total, ""])
        lines.extend(
            [
                "## Источники",
                "",
                f"- [исходный запрос](../Запросы/{request_path.name})",
                "",
            ]
        )
        (root / "Журнал" / request_path.name).write_text(
            "\n".join(lines),
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

    def test_new_request_requires_canonical_session_time_tool(self):
        request_path = Path(
            "Запросы/2026-07-17_10-25-41_MSK_"
            "предотвращать-смещение-времени-сессий.md"
        )
        text = "\n".join(
            [
                "## Использованные инструменты",
                "",
                "- [Реестр](../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                "- `python3` - использован для локальных проверок.",
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
                "used tools section must include fum-moskovskoye-vremya-rabochej-sessii for canonical MSK time"
            ],
        )

    def test_new_request_requires_codex_thread_id(self):
        request_path = Path(
            "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex.md"
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            "## Текст запроса\n\nДобавить идентификатор.\n",
            request_path,
        )

        self.assertEqual(
            errors,
            ["missing section: Идентификатор сеанса Codex"],
        )

    def test_new_request_accepts_root_codex_thread_id(self):
        request_path = Path(
            "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex.md"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                f"Codex-Thread-ID: {root_thread_id}",
                "",
            ]
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            text,
            request_path,
            expected_codex_thread_id=root_thread_id,
        )

        self.assertEqual(errors, [])

    def test_new_request_rejects_split_or_non_unique_codex_thread_id_section(self):
        request_path = Path(
            "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex.md"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        invalid_texts = {
            "split value": (
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID:\n{root_thread_id}\n"
            ),
            "extra content": (
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
                "Лишняя строка.\n"
            ),
            "duplicate heading": (
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n\n"
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
        }

        for label, text in invalid_texts.items():
            with self.subTest(label=label):
                errors = check_session_coherence.validate_codex_thread_id_section(
                    text,
                    request_path,
                )
                self.assertTrue(errors)

    def test_new_request_rejects_subagent_codex_thread_id(self):
        request_path = Path(
            "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex.md"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        child_thread_id = "019f5dd2-af59-7a31-99d0-243a677529ab"
        text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                f"Codex-Thread-ID: {child_thread_id}",
                "",
            ]
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            text,
            request_path,
            expected_codex_thread_id=root_thread_id,
        )

        self.assertEqual(
            errors,
            [
                "Codex-Thread-ID does not match the expected root Codex thread: "
                f"{child_thread_id}"
            ],
        )

    def test_new_request_rejects_non_uuid_codex_thread_id(self):
        request_path = Path(
            "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex.md"
        )
        text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                "Codex-Thread-ID: not-a-uuid",
                "",
            ]
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            text,
            request_path,
        )

        self.assertEqual(
            errors,
            ["Codex-Thread-ID must be a canonical lowercase UUID: not-a-uuid"],
        )

    def test_historical_request_without_codex_thread_id_remains_allowed(self):
        request_path = Path(
            "Запросы/2026-07-14_01-55-34_MSK_"
            "интегрировать-рекурсивную-модель-агента-и-среды.md"
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            "## Текст запроса\n\nИсторический запрос.\n",
            request_path,
        )

        self.assertEqual(errors, [])

    def test_new_request_requires_commit_context_arguments(self):
        request_path = Path(
            "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex.md"
        )

        errors = (
            check_session_coherence.validate_codex_commit_context_requirements(
                request_path,
                expected_codex_thread_id=None,
                commit_message=None,
            )
        )

        self.assertEqual(
            errors,
            [
                "--codex-thread-id is required for this request",
                "--commit-message-file is required for this request",
            ],
        )

        historical_path = Path(
            "Запросы/2026-07-14_01-55-34_MSK_"
            "интегрировать-рекурсивную-модель-агента-и-среды.md"
        )
        self.assertEqual(
            check_session_coherence.validate_codex_commit_context_requirements(
                historical_path,
                expected_codex_thread_id=None,
                commit_message=None,
            ),
            [],
        )

    def test_commit_message_requires_matching_codex_thread_id_trailer(self):
        request_path = Path(
            "Запросы/2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex.md"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        request_text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                f"Codex-Thread-ID: {root_thread_id}",
                "",
            ]
        )
        messages = {
            "missing": "Добавлять ID\n\nСделано.\n",
            "subject only": f"Codex-Thread-ID: {root_thread_id}\n",
            "split value": (
                "Добавлять ID\n\nСделано.\n\n"
                f"Codex-Thread-ID:\n{root_thread_id}\n"
            ),
            "not a trailer block": (
                "Добавлять ID\n\nСделано.\n\n"
                "Обычный текст.\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
            "different": (
                "Добавлять ID\n\nСделано.\n\n"
                "Codex-Thread-ID: 019f5dd2-af59-7a31-99d0-243a677529ab\n"
            ),
            "duplicate": (
                "Добавлять ID\n\nСделано.\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
            "case-insensitive duplicate": (
                "Добавлять ID\n\nСделано.\n\n"
                "codex-thread-id: 019f5dd2-af59-7a31-99d0-243a677529ab\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
        }

        for label, message in messages.items():
            with self.subTest(label=label):
                errors = check_session_coherence.validate_commit_message_codex_thread_id(
                    request_text,
                    request_path,
                    message,
                )
                self.assertTrue(errors)

        valid_message = (
            "Добавлять идентификатор сеанса Codex\n\n"
            "Исходный запрос и описание сделанного.\n\n"
            f"Codex-Thread-ID: {root_thread_id}\n"
        )
        self.assertEqual(
            check_session_coherence.validate_commit_message_codex_thread_id(
                request_text,
                request_path,
                valid_message,
            ),
            [],
        )

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

    def test_new_journal_requires_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Запросы").mkdir()
            (root / "Журнал").mkdir()
            request_path = (
                root
                / "Запросы"
                / "2026-07-23_14-47-43_MSK_"
                "включать-профиль-времени-в-отчёты-журнала.md"
            )
            journal_path = root / "Журнал" / request_path.name
            journal_path.write_text(
                "\n".join(
                    [
                        "# Отчёт 2026-07-23 14:47:43 MSK - "
                        "Включать профиль времени в отчёты журнала",
                        "",
                        "Отчёт без профиля времени.",
                        "",
                        "## Источники",
                        "",
                        f"- [исходный запрос](../Запросы/{request_path.name})",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "missing journal section: Профиль времени выполнения",
                errors,
            )

    def test_new_journal_accepts_two_stage_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Запросы").mkdir()
            (root / "Журнал").mkdir()
            request_path = (
                root
                / "Запросы"
                / "2026-07-23_14-47-43_MSK_"
                "включать-профиль-времени-в-отчёты-журнала.md"
            )
            journal_path = root / "Журнал" / request_path.name
            journal_path.write_text(
                "\n".join(
                    [
                        "# Отчёт 2026-07-23 14:47:43 MSK - "
                        "Включать профиль времени в отчёты журнала",
                        "",
                        "Отчёт с измеренным профилем.",
                        "",
                        "## Профиль времени выполнения",
                        "",
                        "| Стадия | Длительность | Границы и способ измерения |",
                        "| --- | ---: | --- |",
                        "| Анализ | 12 с | Монотонные отметки начала и конца. |",
                        "| Smoke-check | 31 с | Wall-clock `real`. |",
                        "",
                        "Граница профиля: от допуска очереди до завершения smoke-check.",
                        "",
                        "## Источники",
                        "",
                        f"- [исходный запрос](../Запросы/{request_path.name})",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_current_journal_accepts_each_direct_check_run_and_exact_total(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_name=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок.md"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=[
                    "| `python3 -m unittest` | 1,25 с | неуспешно (exit 1) |",
                    "| `python3 -m unittest` | 0.75 с | успешно |",
                    "| `python3 smoke.py` | 2 с | прервано по тайм-ауту |",
                    "| `python3 smoke.py` | 3 с | не завершено из-за остановки |",
                ],
                invocation_total=(
                    "Общее время прямых запусков проверок: 7 с."
                ),
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_current_journal_accepts_escaped_pipe_inside_invocation_cell(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_name=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок.md"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=[
                    r"| `printf 'first \| second'` | 1,5 с | успешно |",
                ],
                invocation_total=(
                    "Общее время прямых запусков проверок: 1,5 с."
                ),
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_current_journal_ignores_fake_direct_check_subsection_in_nonsemantic_regions(self):
        fake_subsection = [
            "### Прямые запуски проверок",
            "",
            "| Вызов | Длительность | Результат |",
            "| --- | ---: | --- |",
            "| `python3 fake.py` | 1 с | успешно |",
            "",
            "Общее время прямых запусков проверок: 1 с.",
        ]
        wrappers = (
            ["```markdown", *fake_subsection, "```"],
            ["<!--", *fake_subsection, "-->"],
        )
        for wrapped_subsection in wrappers:
            with self.subTest(wrapper=wrapped_subsection[0]), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                request_path = self.write_time_profile_journal(
                    root,
                    request_name=(
                        "2026-07-27_16-12-29_MSK_"
                        "учитывать-все-запуски-проверок.md"
                    ),
                    request_label=(
                        "2026-07-27 16:12:29 MSK - "
                        "Учитывать все запуски проверок"
                    ),
                    invocation_rows=None,
                    invocation_total=None,
                )
                journal_path = root / "Журнал" / request_path.name
                journal_text = journal_path.read_text(encoding="utf-8")
                journal_path.write_text(
                    journal_text.replace(
                        "\n## Источники",
                        "\n" + "\n".join(wrapped_subsection) + "\n\n## Источники",
                    ),
                    encoding="utf-8",
                )

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                self.assertIn(
                    "missing journal time profile subsection: "
                    "Прямые запуски проверок",
                    errors,
                )

    def test_current_journal_ignores_fake_direct_check_table_in_fenced_code(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_name=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок.md"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=None,
                invocation_total=None,
            )
            fake_table = "\n".join(
                [
                    "### Прямые запуски проверок",
                    "",
                    "```markdown",
                    "| Вызов | Длительность | Результат |",
                    "| --- | ---: | --- |",
                    "| `python3 fake.py` | 1 с | успешно |",
                    "",
                    "Общее время прямых запусков проверок: 1 с.",
                    "```",
                ]
            )
            journal_path = root / "Журнал" / request_path.name
            journal_text = journal_path.read_text(encoding="utf-8")
            journal_path.write_text(
                journal_text.replace(
                    "\n## Источники",
                    f"\n{fake_table}\n\n## Источники",
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "journal direct check runs must contain table columns: "
                "Вызов | Длительность | Результат",
                errors,
            )

    def test_current_journal_ignores_fake_direct_check_total_in_html_comment(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_name=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок.md"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=[
                    "| `python3 real.py` | 1 с | успешно |",
                ],
                invocation_total=None,
            )
            journal_path = root / "Журнал" / request_path.name
            journal_text = journal_path.read_text(encoding="utf-8")
            journal_path.write_text(
                journal_text.replace(
                    "\n## Источники",
                    "\n<!--\nОбщее время прямых запусков проверок: "
                    "1 с.\n-->\n\n## Источники",
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "journal direct check runs must contain exactly one total line: "
                "Общее время прямых запусков проверок:",
                errors,
            )

    def test_current_journal_sums_durations_at_their_actual_precision(self):
        large = f"{'9' * 60}.9"
        exact_total = f"{'9' * 60}.91"
        rounded_total = f"1{'0' * 60}"
        cases = (
            (exact_total, None),
            (
                rounded_total,
                "journal direct check run total must equal the sum of row durations: "
                f"expected {exact_total} с, got {rounded_total} с",
            ),
        )
        for total, expected_error in cases:
            with self.subTest(total=total), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                request_path = self.write_time_profile_journal(
                    root,
                    request_name=(
                        "2026-07-27_16-12-29_MSK_"
                        "учитывать-все-запуски-проверок.md"
                    ),
                    request_label=(
                        "2026-07-27 16:12:29 MSK - "
                        "Учитывать все запуски проверок"
                    ),
                    invocation_rows=[
                        f"| `python3 first.py` | {large} с | успешно |",
                        "| `python3 second.py` | 0.01 с | успешно |",
                    ],
                    invocation_total=(
                        f"Общее время прямых запусков проверок: {total} с."
                    ),
                )

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                if expected_error is None:
                    self.assertEqual(errors, [])
                else:
                    self.assertIn(expected_error, errors)

    def test_current_journal_requires_direct_check_run_table_and_total(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_name=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок.md"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=None,
                invocation_total=None,
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "missing journal time profile subsection: "
                "Прямые запуски проверок",
                errors,
            )

    def test_current_journal_rejects_invalid_direct_check_run_accounting(self):
        cases = (
            (
                [],
                "Общее время прямых запусков проверок: 0 с.",
                "journal direct check run table must contain at least one "
                "invocation row",
            ),
            (
                ["| `python3 -m unittest` | 1 мин | успешно |"],
                "Общее время прямых запусков проверок: 60 с.",
                "journal direct check run row 1 has invalid duration: 1 мин",
            ),
            (
                ["| `python3 -m unittest` | 1 с | прошла |"],
                "Общее время прямых запусков проверок: 1 с.",
                "journal direct check run row 1 has invalid result status: прошла",
            ),
            (
                [
                    "| `python3 -m unittest` | 1,2 с | неуспешно |",
                    "| `python3 -m unittest` | 2,3 с | успешно |",
                ],
                "Общее время прямых запусков проверок: 2,3 с.",
                "journal direct check run total must equal the sum of row durations: "
                "expected 3.5 с, got 2.3 с",
            ),
            (
                ["| `python3 -m unittest` | 1 с | успешно |"],
                None,
                "journal direct check runs must contain exactly one total line: "
                "Общее время прямых запусков проверок:",
            ),
        )
        for invocation_rows, invocation_total, expected_error in cases:
            with self.subTest(expected_error=expected_error), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                request_path = self.write_time_profile_journal(
                    root,
                    request_name=(
                        "2026-07-27_16-12-29_MSK_"
                        "учитывать-все-запуски-проверок.md"
                    ),
                    request_label=(
                        "2026-07-27 16:12:29 MSK - "
                        "Учитывать все запуски проверок"
                    ),
                    invocation_rows=invocation_rows,
                    invocation_total=invocation_total,
                )

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                self.assertIn(expected_error, errors)

    def test_journal_before_direct_check_run_rule_keeps_old_time_profile_contract(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_name=(
                    "2026-07-27_16-12-28_MSK_"
                    "учитывать-старый-профиль-времени.md"
                ),
                request_label=(
                    "2026-07-27 16:12:28 MSK - "
                    "Учитывать старый профиль времени"
                ),
                invocation_rows=None,
                invocation_total=None,
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_new_journal_rejects_incomplete_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Запросы").mkdir()
            (root / "Журнал").mkdir()
            request_path = (
                root
                / "Запросы"
                / "2026-07-23_14-47-43_MSK_"
                "включать-профиль-времени-в-отчёты-журнала.md"
            )
            journal_path = root / "Журнал" / request_path.name
            journal_path.write_text(
                "\n".join(
                    [
                        "# Отчёт 2026-07-23 14:47:43 MSK - "
                        "Включать профиль времени в отчёты журнала",
                        "",
                        "## Профиль времени выполнения",
                        "",
                        "| Стадия | Длительность | Границы и способ измерения |",
                        "| --- | ---: | --- |",
                        "| Анализ | 12 с | Монотонные отметки начала и конца. |",
                        "",
                        "## Источники",
                        "",
                        f"- [исходный запрос](../Запросы/{request_path.name})",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "journal time profile must contain at least two stage rows",
                errors,
            )
            self.assertIn(
                "journal time profile must contain a non-empty boundary line "
                "after its table: Граница профиля:",
                errors,
            )

    def test_new_journal_rejects_early_or_empty_time_profile_boundary(self):
        for boundary_before, boundary_after in (
            ("Граница профиля: до таблицы.", None),
            (None, "Граница профиля:"),
        ):
            with self.subTest(
                boundary_before=boundary_before,
                boundary_after=boundary_after,
            ), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / "Запросы").mkdir()
                (root / "Журнал").mkdir()
                request_path = (
                    root
                    / "Запросы"
                    / "2026-07-23_14-47-43_MSK_"
                    "включать-профиль-времени-в-отчёты-журнала.md"
                )
                journal_path = root / "Журнал" / request_path.name
                lines = [
                    "# Отчёт 2026-07-23 14:47:43 MSK - "
                    "Включать профиль времени в отчёты журнала",
                    "",
                    "## Профиль времени выполнения",
                    "",
                ]
                if boundary_before is not None:
                    lines.extend([boundary_before, ""])
                lines.extend(
                    [
                        "| Стадия | Длительность | Границы и способ измерения |",
                        "| --- | ---: | --- |",
                        "| Анализ | 12 с | Монотонные отметки. |",
                        "| Smoke-check | 31 с | Wall-clock `real`. |",
                        "",
                    ]
                )
                if boundary_after is not None:
                    lines.extend([boundary_after, ""])
                lines.extend(
                    [
                        "## Источники",
                        "",
                        f"- [исходный запрос](../Запросы/{request_path.name})",
                        "",
                    ]
                )
                journal_path.write_text("\n".join(lines), encoding="utf-8")

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                self.assertIn(
                    "journal time profile must contain a non-empty boundary line "
                    "after its table: Граница профиля:",
                    errors,
                )

    def test_historical_journal_does_not_require_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

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

    def test_rejects_absolute_and_escaping_local_markdown_links(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "Документация"
            docs.mkdir()
            outside = root.parent / f"{root.name}-outside.md"
            outside.write_text("# Outside\n", encoding="utf-8")
            self.addCleanup(outside.unlink)
            source = docs / "индекс.md"
            targets = (
                outside.as_posix(),
                f"../../{outside.name}",
                f"file://{outside.as_posix()}",
                "C:\\repo\\outside.md",
                "\\\\server\\share\\outside.md",
            )

            for target in targets:
                with self.subTest(target=target):
                    source.write_text(
                        f"# Индекс\n\n[внешняя цель](<{target}>)\n",
                        encoding="utf-8",
                    )
                    errors = check_session_coherence.validate_markdown_links(
                        {source},
                        root,
                    )
                    self.assertTrue(
                        any(
                            "local Markdown link" in error
                            and "Документация/индекс.md:3" in error
                            for error in errors
                        ),
                        errors,
                    )

    def test_external_url_and_relative_link_inside_repository_remain_valid(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "Документация" / "вложенная"
            docs.mkdir(parents=True)
            target = root / "README.md"
            target.write_text("# README\n", encoding="utf-8")
            source = docs / "индекс.md"
            source.write_text(
                "# Индекс\n\n"
                "[репозиторий](../../README.md)\n"
                "[сайт](https://example.invalid/path)\n",
                encoding="utf-8",
            )

            self.assertEqual(
                check_session_coherence.validate_markdown_links({source}, root),
                [],
            )

    def test_nested_shorter_fence_does_not_expose_markdown_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "Документация"
            docs.mkdir()
            target = root / "README.md"
            target.write_text("# README\n", encoding="utf-8")
            source = docs / "индекс.md"
            source.write_text(
                "# Индекс\n\n"
                "````text\n"
                "<input>\n"
                "```json\n"
                '{"task":"[термин](../../Глоссарий/термин.md)"}\n'
                "```\n"
                "</input>\n"
                "````\n\n"
                "[README](../README.md)\n",
                encoding="utf-8",
            )

            links = check_session_coherence.iter_markdown_links(source)

            self.assertEqual(
                [(link.line, link.target) for link in links],
                [(11, "../README.md")],
            )
            self.assertEqual(
                check_session_coherence.validate_markdown_links({source}, root),
                [],
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

    def test_ignored_build_and_cache_markdown_files_are_not_checked(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            ignored_paths = [
                ".build/checkouts/vendor/README.md",
                ".swiftpm/cache/README.md",
                ".obsidian/cache/README.md",
                ".obsidian/plugins/local/README.md",
            ]
            for relative in ignored_paths:
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(
                    "# Ignored cache\n\n[broken](missing-target.md)\n",
                    encoding="utf-8",
                )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertEqual(errors, [])

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
                / "fum-svezhestj-markdown"
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
