import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "check-question-backlinks.py"
)

spec = importlib.util.spec_from_file_location(
    "check_question_backlinks",
    SCRIPT_PATH,
)
check_question_backlinks = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = check_question_backlinks
spec.loader.exec_module(check_question_backlinks)


class CheckQuestionBacklinksTests(unittest.TestCase):
    QUESTION_NAME = "2026-07-20_10-00-00_MSK_пример.md"

    def write_index(
        self,
        root: Path,
        *,
        open_questions: tuple[str, ...] = (),
        partial_questions: tuple[str, ...] = (),
        resolved_questions: tuple[str, ...] = (),
    ) -> None:
        questions = root / "Вопросы"
        questions.mkdir(parents=True, exist_ok=True)

        def entries(names: tuple[str, ...]) -> str:
            return "\n".join(
                f"- [Вопрос {index}]({name})"
                for index, name in enumerate(names, start=1)
            )

        (questions / "README.md").write_text(
            "\n".join(
                [
                    "# Вопросы",
                    "",
                    "## [Открытые вопросы](../Глоссарий/открытый-вопрос.md)",
                    "",
                    entries(open_questions),
                    "",
                    "## Частично прояснённые вопросы",
                    "",
                    entries(partial_questions),
                    "",
                    "## Прояснённые вопросы",
                    "",
                    entries(resolved_questions),
                    "",
                ]
            ),
            encoding="utf-8",
        )

    def write_question(
        self,
        root: Path,
        name: str,
        target: str,
    ) -> Path:
        question = root / "Вопросы" / name
        question.parent.mkdir(parents=True, exist_ok=True)
        question.write_text(
            "\n".join(
                [
                    "# Открытый вопрос",
                    "",
                    "Неоднозначность ещё не разрешена.",
                    "",
                    "## Затронутая документация",
                    "",
                    f"- [Целевой документ]({target})",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        return question

    def write_target(
        self,
        root: Path,
        relative: str,
        backlink: str | None,
    ) -> Path:
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        lines = ["# Целевой документ", ""]
        if backlink is not None:
            lines.append(
                "Решение зависит от "
                f"[открытого вопроса]({backlink})."
            )
        else:
            lines.append("Нерешённая зависимость здесь пока не видна.")
        lines.append("")
        target.write_text("\n".join(lines), encoding="utf-8")
        return target

    def test_accepts_reciprocal_links_for_open_and_partial_questions(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            partial_name = "2026-07-20_10-01-00_MSK_частичный.md"
            self.write_index(
                root,
                open_questions=(self.QUESTION_NAME,),
                partial_questions=(partial_name,),
            )
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/открытая-цель.md",
            )
            self.write_question(
                root,
                partial_name,
                "../Планирование/частичная-цель.md",
            )
            self.write_target(
                root,
                "Документация/открытая-цель.md",
                f"../Вопросы/{self.QUESTION_NAME}#неоднозначность",
            )
            self.write_target(
                root,
                "Планирование/частичная-цель.md",
                f"../Вопросы/{partial_name}",
            )

            self.assertEqual(
                check_question_backlinks.validate_repository(root),
                [],
            )

    def test_reports_existing_target_without_backlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            self.write_target(root, "Документация/цель.md", None)

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any(
                    "missing backlink" in error
                    and "Документация/цель.md" in error
                    and self.QUESTION_NAME in error
                    for error in errors
                ),
                errors,
            )

    def test_does_not_count_images_code_or_comments_as_backlinks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            target = root / "Документация" / "цель.md"
            target.parent.mkdir(parents=True)
            backlink = f"../Вопросы/{self.QUESTION_NAME}"
            target.write_text(
                "\n".join(
                    [
                        "# Целевой документ",
                        "",
                        f"![Снимок вопроса]({backlink})",
                        f"`[Ссылка в коде]({backlink})`",
                        f"<!-- [Скрытая ссылка]({backlink}) -->",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("missing backlink" in error for error in errors),
                errors,
            )

    def test_does_not_count_escaped_plain_text_as_backlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            target = root / "Документация" / "цель.md"
            target.parent.mkdir(parents=True)
            backlink = f"../Вопросы/{self.QUESTION_NAME}"
            target.write_text(
                f"# Целевой документ\n\n\\[Не ссылка]({backlink})\n",
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("missing backlink" in error for error in errors),
                errors,
            )

    def test_does_not_close_backtick_fence_with_tilde_marker(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            target = root / "Документация" / "цель.md"
            target.parent.mkdir(parents=True)
            backlink = f"../Вопросы/{self.QUESTION_NAME}"
            target.write_text(
                "\n".join(
                    [
                        "# Целевой документ",
                        "",
                        "```md",
                        "~~~",
                        f"[Ссылка в примере]({backlink})",
                        "```",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("missing backlink" in error for error in errors),
                errors,
            )

    def test_reports_targetless_question_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/отсутствует.md",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any(
                    "target does not exist" in error
                    and "отсутствует.md" in error
                    for error in errors
                ),
                errors,
            )

    def test_reports_empty_declared_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(root, self.QUESTION_NAME, " ")

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("has no local file path" in error for error in errors),
                errors,
            )

    def test_reports_fragment_only_declared_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(root, self.QUESTION_NAME, "#неоднозначность")

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("has no local file path" in error for error in errors),
                errors,
            )

    def test_reports_non_markdown_declared_target_without_reading_it(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.bin",
            )
            target = root / "Документация" / "цель.bin"
            target.parent.mkdir(parents=True)
            target.write_bytes(b"\xff\xfe\x00")

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("is not a Markdown file" in error for error in errors),
                errors,
            )

    def test_reports_declared_target_through_symbolic_link(self):
        with (
            tempfile.TemporaryDirectory() as tmp,
            tempfile.TemporaryDirectory() as external_tmp,
        ):
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            external = Path(external_tmp) / "цель.md"
            external.write_text(
                f"[Внешняя ссылка](/Вопросы/{self.QUESTION_NAME})\n",
                encoding="utf-8",
            )
            target = root / "Документация" / "цель.md"
            target.parent.mkdir(parents=True)
            target.symlink_to(external)

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("uses a symbolic link" in error for error in errors),
                errors,
            )

    def test_reports_case_mismatch_in_declared_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../документация/цель.md",
            )
            self.write_target(
                root,
                "Документация/цель.md",
                f"../Вопросы/{self.QUESTION_NAME}",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any(
                    "path case mismatch" in error
                    and "Документация/цель.md" in error
                    for error in errors
                ),
                errors,
            )

    def test_reports_case_mismatch_in_backlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            self.write_target(
                root,
                "Документация/цель.md",
                f"../вопросы/{self.QUESTION_NAME}",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any(
                    "path case mismatch" in error
                    and f"Вопросы/{self.QUESTION_NAME}" in error
                    for error in errors
                ),
                errors,
            )

    def test_ignores_resolved_question_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, resolved_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            self.write_target(root, "Документация/цель.md", None)

            self.assertEqual(
                check_question_backlinks.validate_repository(root),
                [],
            )

    def test_reports_active_question_without_targets_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            question = root / "Вопросы" / self.QUESTION_NAME
            question.write_text(
                "# Открытый вопрос\n\nНеоднозначность.\n",
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("Затронутая документация" in error for error in errors),
                errors,
            )

    def test_reports_missing_active_sections_in_questions_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            questions = root / "Вопросы"
            questions.mkdir(parents=True)
            (questions / "README.md").write_text(
                "# Вопросы\n\n## Прояснённые вопросы\n",
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertEqual(
                sum("questions index must contain exactly one" in error for error in errors),
                2,
                errors,
            )

    def test_ignores_active_index_sections_inside_fenced_example(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            questions = root / "Вопросы"
            questions.mkdir(parents=True)
            (questions / "README.md").write_text(
                "\n".join(
                    [
                        "# Вопросы",
                        "",
                        "```md",
                        "## Открытые вопросы",
                        f"- [Пример]({self.QUESTION_NAME})",
                        "## Частично прояснённые вопросы",
                        "```",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertEqual(
                sum(
                    "questions index must contain exactly one" in error
                    for error in errors
                ),
                2,
                errors,
            )

    def test_ignores_targets_section_inside_fenced_example(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            question = root / "Вопросы" / self.QUESTION_NAME
            question.write_text(
                "\n".join(
                    [
                        "# Открытый вопрос",
                        "",
                        "```md",
                        "## Затронутая документация",
                        "",
                        "- [Пример](../Документация/цель.md)",
                        "```",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("must contain exactly one" in error for error in errors),
                errors,
            )

    def test_reports_fragment_only_active_index_entry(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            questions = root / "Вопросы"
            questions.mkdir(parents=True)
            (questions / "README.md").write_text(
                "\n".join(
                    [
                        "# Вопросы",
                        "",
                        "## Открытые вопросы",
                        "",
                        "- [Вопрос](#локальный-фрагмент)",
                        "",
                        "## Частично прояснённые вопросы",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any(
                    "active question entry has no local file path" in error
                    for error in errors
                ),
                errors,
            )

    def test_reports_active_question_with_empty_targets_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            question = root / "Вопросы" / self.QUESTION_NAME
            question.write_text(
                "\n".join(
                    [
                        "# Открытый вопрос",
                        "",
                        "Неоднозначность.",
                        "",
                        "## Затронутая документация",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_question_backlinks.validate_repository(root)

            self.assertTrue(
                any("has no local targets" in error for error in errors),
                errors,
            )

    def test_cli_returns_zero_and_prints_audit_counts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            self.write_target(
                root,
                "Документация/цель.md",
                f"../Вопросы/{self.QUESTION_NAME}",
            )

            result = subprocess.run(
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

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("1 active questions, 1 declared targets", result.stdout)

    def test_cli_returns_one_and_reports_errors_to_stderr(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_index(root, open_questions=(self.QUESTION_NAME,))
            self.write_question(
                root,
                self.QUESTION_NAME,
                "../Документация/цель.md",
            )
            self.write_target(root, "Документация/цель.md", None)

            result = subprocess.run(
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

            self.assertEqual(result.returncode, 1, result.stdout)
            self.assertIn("ERROR: missing backlink", result.stderr)


if __name__ == "__main__":
    unittest.main()
