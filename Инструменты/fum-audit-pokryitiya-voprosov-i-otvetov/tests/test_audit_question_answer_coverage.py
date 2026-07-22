import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "audit-question-answer-coverage.py"
)

spec = importlib.util.spec_from_file_location(
    "audit_question_answer_coverage",
    SCRIPT_PATH,
)
audit_question_answer_coverage = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = audit_question_answer_coverage
spec.loader.exec_module(audit_question_answer_coverage)


class AuditQuestionAnswerCoverageTests(unittest.TestCase):
    def write_request(
        self,
        root: Path,
        name: str,
        literal_text: str,
        *,
        trailing_text: str = "",
    ) -> Path:
        requests = root / "Запросы"
        requests.mkdir(parents=True, exist_ok=True)
        request = requests / name
        request.write_text(
            "\n".join(
                [
                    "# Исходный запрос",
                    "",
                    "## Текст запроса",
                    "",
                    "```text",
                    literal_text,
                    "```",
                    "",
                    "## Проверки",
                    "",
                    trailing_text,
                    "",
                ]
            ),
            encoding="utf-8",
        )
        return request

    def write_card(
        self,
        root: Path,
        name: str,
        source_link: str,
        *,
        fenced: bool = False,
    ) -> Path:
        cards = root / "Вопросы и ответы"
        cards.mkdir(parents=True, exist_ok=True)
        card = cards / name
        link = f"[исходный запрос]({source_link})"
        if fenced:
            source = f"```markdown\n{link}\n```"
        else:
            source = f"- {link}"
        card.write_text(
            "\n".join(
                [
                    "# Ответ",
                    "",
                    "## Вопрос",
                    "",
                    "Что проверяется?",
                    "",
                    "## Ответ",
                    "",
                    "Проверяется структурное покрытие.",
                    "",
                    "## Источники требований",
                    "",
                    source,
                    "",
                ]
            ),
            encoding="utf-8",
        )
        return card

    def test_extracts_questions_only_from_exact_literal_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request = self.write_request(
                root,
                "2026-07-01_10-00-00_MSK_спросить-о-FUM.md",
                "\n".join(
                    [
                        "Утверждение. Что такое FUM?",
                        "## Заголовок внутри дословного блока",
                        "Как он работает\nна практике?",
                        "https://example.test/search?q=value",
                    ]
                ),
                trailing_text="Этот вопрос находится вне блока?",
            )

            report = audit_question_answer_coverage.audit_repository(root)

            self.assertEqual(report.request_count, 1)
            self.assertEqual(report.card_count, 0)
            self.assertEqual(
                [finding.question for finding in report.findings],
                ["Что такое FUM?", "Как он работает\nна практике?"],
            )
            self.assertEqual(
                {finding.request_path for finding in report.findings},
                {request.relative_to(root).as_posix()},
            )
            self.assertTrue(all(finding.line > 0 for finding in report.findings))

    def test_matches_all_questions_from_request_by_visible_card_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_name = "2026-07-01_10-00-00_MSK_спросить-дважды.md"
            self.write_request(
                root,
                request_name,
                "Что такое узел? Как он взаимодействует с другими узлами?",
            )
            card = self.write_card(
                root,
                "2026-07-01_10-00-00_MSK_ответить.md",
                f"../Запросы/{request_name}#Текст-запроса",
            )

            report = audit_question_answer_coverage.audit_repository(root)

            self.assertEqual(report.covered_question_count, 2)
            self.assertEqual(report.uncovered_question_count, 0)
            self.assertTrue(
                all(finding.coverage == "covered" for finding in report.findings)
            )
            self.assertEqual(
                {finding.answer_cards for finding in report.findings},
                {(card.relative_to(root).as_posix(),)},
            )

    def test_ignores_card_links_inside_fenced_examples(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_name = "2026-07-01_10-00-00_MSK_спросить.md"
            self.write_request(root, request_name, "Кем является FUM?")
            self.write_card(
                root,
                "2026-07-01_10-00-00_MSK_пример.md",
                f"../Запросы/{request_name}",
                fenced=True,
            )

            report = audit_question_answer_coverage.audit_repository(root)

            self.assertEqual(report.covered_question_count, 0)
            self.assertEqual(report.uncovered_question_count, 1)
            self.assertEqual(report.findings[0].coverage, "uncovered")
            self.assertEqual(report.findings[0].answer_cards, ())

    def test_prefers_text_fences_then_blockquotes_then_raw_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            requests = root / "Запросы"
            requests.mkdir(parents=True)
            (requests / "2026-07-01_10-00-00_MSK_несколько-ходов.md").write_text(
                "\n".join(
                    [
                        "# Исходный запрос",
                        "",
                        "## Текст запроса",
                        "",
                        "Служебное пояснение с вопросом?",
                        "",
                        "### Сообщение 1",
                        "",
                        "```text",
                        "Первый вопрос?",
                        "```",
                        "",
                        "### Сообщение 2",
                        "",
                        "```text",
                        "Второй вопрос?",
                        "```",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            (requests / "2026-07-01_10-01-00_MSK_цитата.md").write_text(
                "# Исходный запрос\n\n## Текст запроса\n\n> Вопрос из цитаты?\n",
                encoding="utf-8",
            )
            (requests / "2026-07-01_10-02-00_MSK_сырой.md").write_text(
                "# Исходный запрос\n\n## Текст запроса\n\nСырой вопрос?\n",
                encoding="utf-8",
            )

            report = audit_question_answer_coverage.audit_repository(root)

            self.assertEqual(
                [finding.question for finding in report.findings],
                [
                    "Первый вопрос?",
                    "Второй вопрос?",
                    "Вопрос из цитаты?",
                    "Сырой вопрос?",
                ],
            )

    def test_counts_only_terminal_question_marks_visible_in_prose(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_request(
                root,
                "2026-07-01_10-00-00_MSK_пунктуация.md",
                "\n".join(
                    [
                        "https://example.test/search?q=value",
                        r"Это экранировано\?",
                        "Это `a ? b : c` не вопрос.",
                        "Что делает `a ? b : c`?",
                        "Это не принимается?!",
                    ]
                ),
            )

            report = audit_question_answer_coverage.audit_repository(root)

            self.assertEqual(
                [finding.question for finding in report.findings],
                ["Что делает `a ? b : c`?"],
            )

    def test_counts_only_links_from_sources_section_as_coverage(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_name = "2026-07-01_10-00-00_MSK_спросить.md"
            self.write_request(root, request_name, "Что покрыто?")
            cards = root / "Вопросы и ответы"
            cards.mkdir(parents=True)
            (cards / "2026-07-01_10-00-00_MSK_ложная-связь.md").write_text(
                "\n".join(
                    [
                        "# Ответ",
                        "",
                        "## Ответ",
                        "",
                        f"[Контекст](../Запросы/{request_name})",
                        "",
                        "## Источники требований",
                        "",
                        "- [Другое правило](../AGENTS.md)",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            report = audit_question_answer_coverage.audit_repository(root)

            self.assertEqual(report.covered_question_count, 0)
            self.assertEqual(report.findings[0].coverage, "uncovered")

    def test_answer_index_links_do_not_count_as_card_coverage(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_name = "2026-07-01_10-00-00_MSK_спросить.md"
            self.write_request(root, request_name, "Что покрывает индекс?")
            cards = root / "Вопросы и ответы"
            cards.mkdir(parents=True)
            (cards / "README.md").write_text(
                "# Индекс\n\n## Источники требований\n\n"
                f"- [Исходный запрос](../Запросы/{request_name})\n",
                encoding="utf-8",
            )

            report = audit_question_answer_coverage.audit_repository(root)

            self.assertEqual(report.card_count, 0)
            self.assertEqual(report.covered_question_count, 0)
            self.assertEqual(report.findings[0].coverage, "uncovered")

    def test_all_detected_questions_remain_manual_review_candidates(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            covered_name = "2026-07-01_10-00-00_MSK_покрытый.md"
            uncovered_name = "2026-07-01_10-01-00_MSK_непокрытый.md"
            self.write_request(root, covered_name, "Что уже покрыто?")
            self.write_request(root, uncovered_name, "Что ещё не покрыто?")
            self.write_card(
                root,
                "2026-07-01_10-00-00_MSK_ответ.md",
                f"../Запросы/{covered_name}",
            )

            report = audit_question_answer_coverage.audit_repository(root)
            payload = report.as_dict()

            self.assertEqual(payload["question_count"], 2)
            self.assertEqual(payload["candidate_count"], 2)
            self.assertEqual(payload["covered_question_count"], 1)
            self.assertEqual(payload["uncovered_question_count"], 1)
            for candidate in payload["candidates"]:
                self.assertEqual(
                    candidate["manual_checks"],
                    [
                        "directly_about_fum",
                        "substantive_answer",
                        "standalone_usefulness",
                    ],
                )

    def test_cli_emits_deterministic_json_and_human_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_request(
                root,
                "2026-07-01_10-00-00_MSK_спросить.md",
                "Какова граница FUM?",
            )

            json_result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                    "--json",
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            human_result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(json_result.returncode, 0, json_result.stderr)
            payload = json.loads(json_result.stdout)
            self.assertEqual(payload["schema_version"], 1)
            self.assertEqual(payload["candidates"][0]["coverage"], "uncovered")
            self.assertEqual(human_result.returncode, 0, human_result.stderr)
            self.assertIn("Кандидаты ручной проверки", human_result.stdout)
            self.assertIn("Какова граница FUM?", human_result.stdout)
            self.assertIn("прямое отношение к сущности FUM", human_result.stdout)
            self.assertIn("не доказывает качество ответа", human_result.stdout)

    def test_missing_request_text_section_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            requests = root / "Запросы"
            requests.mkdir(parents=True)
            (requests / "2026-07-01_10-00-00_MSK_без-раздела.md").write_text(
                "# Исходный запрос\n\n## Другой раздел\n\nЕсть вопрос?\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Текст запроса"):
                audit_question_answer_coverage.audit_repository(root)

    def test_duplicate_request_text_section_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            requests = root / "Запросы"
            requests.mkdir(parents=True)
            (requests / "2026-07-01_10-00-00_MSK_два-раздела.md").write_text(
                "# Исходный запрос\n\n"
                "## Текст запроса\n\nПервый вопрос?\n\n"
                "## Текст запроса\n\nВторой вопрос?\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "найдено 2"):
                audit_question_answer_coverage.audit_repository(root)


if __name__ == "__main__":
    unittest.main()
