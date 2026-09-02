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
    / "build-work-review.py"
)

spec = importlib.util.spec_from_file_location("build_work_review", SCRIPT_PATH)
build_work_review = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = build_work_review
spec.loader.exec_module(build_work_review)


class BuildWorkReviewTests(unittest.TestCase):
    def run_git(self, root: Path, *args: str) -> None:
        subprocess.run(
            ["git", "-C", str(root), *args],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def commit(self, root: Path, message: str) -> None:
        subprocess.run(
            [
                "git",
                "-C",
                str(root),
                "-c",
                "user.name=FUM",
                "-c",
                "user.email=fum@example.invalid",
                "commit",
                "-m",
                message,
            ],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def write_git_fixture(self, root: Path) -> tuple[Path, Path]:
        self.run_git(root, "init")
        (root / "Документация").mkdir()
        request_dir = root / "Журнал" / "2026-07-01_17-03-14_MSK_проверить-работу"
        request_dir.mkdir(parents=True)
        (root / "Инструменты" / "fum-revjyu-prodelannoj-rabotyi").mkdir(parents=True)

        request = request_dir / "запрос.md"
        request.write_text("# Исходный запрос\n", encoding="utf-8")
        automation = root / "Инструменты" / "fum-revjyu-prodelannoj-rabotyi" / "SKILL.md"
        automation.write_text("# FUM Work Review\n", encoding="utf-8")

        document = root / "Документация" / "пример.md"
        document.write_text("# Пример\n\nПервый текст.\n", encoding="utf-8")
        self.run_git(root, "add", ".")
        self.commit(root, "base")

        document.write_text("# Пример\n\nОбновлённый текст.\n", encoding="utf-8")
        self.run_git(root, "add", ".")
        self.commit(root, "reviewed change")
        return request, automation

    def write_config(self, root: Path, request: Path, automation: Path) -> Path:
        config = {
            "title": "Ревью проделанной работы",
            "request_file": request.relative_to(root).as_posix(),
            "automation_file": automation.relative_to(root).as_posix(),
            "base_ref": "HEAD~1",
            "head_ref": "HEAD",
            "reviewed_at": "2026-07-01 17:03:14 MSK",
            "reviewer": "Codex",
            "scope": "Проверяется один тестовый коммит.",
            "review_focus": [
                "связь изменения с запросом",
                "отсутствие структурных регрессий",
            ],
            "findings": [],
            "checks": [
                {
                    "name": "git diff --check",
                    "command": "git diff --check HEAD~1..HEAD",
                    "result": "прошло",
                    "details": "Проблем whitespace не обнаружено.",
                }
            ],
            "residual_risks": [
                "Смысловая проверка остаётся ответственностью агента-ревьюера."
            ],
            "decision": "Существенных замечаний не выявлено.",
        }
        path = root / "review-config.json"
        path.write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
        return path

    def test_builds_review_document_from_git_range_and_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request, automation = self.write_git_fixture(root)
            config = self.write_config(root, request, automation)
            output = root / "Ревью" / "пример-ревью.md"

            build_work_review.build_review_document(config, output, root)

            text = output.read_text(encoding="utf-8")
            self.assertIn("# Ревью проделанной работы", text)
            self.assertIn("## Граница ревью", text)
            self.assertIn("HEAD~1", text)
            self.assertIn("reviewed change", text)
            self.assertIn("Документация/пример.md", text)
            self.assertIn("Существенных замечаний не выявлено.", text)
            self.assertIn("git diff --check HEAD~1..HEAD", text)
            self.assertIn(
                "[исходный запрос 2026-07-01 17:03:14 MSK]"
                "(../Журнал/2026-07-01_17-03-14_MSK_проверить-работу/запрос.md)",
                text,
            )

    def test_build_rejects_nonportable_serialized_path_fields_before_write(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request, automation = self.write_git_fixture(root)
            config_path = self.write_config(root, request, automation)
            output = root / "Ревью" / "пример-ревью.md"
            original = json.loads(config_path.read_text(encoding="utf-8"))
            invalid_configs = []
            for field, value in (
                ("request_file", request.as_posix()),
                ("automation_file", "../внешний-SKILL.md"),
                ("config_file", "file:///repo/review.json"),
            ):
                config = dict(original)
                config[field] = value
                invalid_configs.append((field, config))
            finding_config = dict(original)
            finding_config["findings"] = [
                {
                    "priority": "P2",
                    "status": "подтверждено",
                    "file": "C:\\repo\\secret.txt",
                    "line": 1,
                    "title": "Непереносимый путь",
                    "details": "Проверочная находка.",
                    "recommendation": "Исправить путь.",
                }
            ]
            invalid_configs.append(("findings[0].file", finding_config))

            for field, config in invalid_configs:
                with self.subTest(field=field):
                    config_path.write_text(
                        json.dumps(config, ensure_ascii=False, indent=2),
                        encoding="utf-8",
                    )
                    output.unlink(missing_ok=True)

                    with self.assertRaises(ValueError):
                        build_work_review.build_review_document(
                            config_path,
                            output,
                            root,
                        )
                    self.assertFalse(output.exists())

    def test_complete_review_document_validates(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request, automation = self.write_git_fixture(root)
            config = self.write_config(root, request, automation)
            output = root / "Ревью" / "пример-ревью.md"
            build_work_review.build_review_document(config, output, root)

            errors = build_work_review.validate_review_document(config, output, root, complete=True)

            self.assertEqual(errors, [])

    def test_build_rejects_request_without_timestamped_journal_parent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request, automation = self.write_git_fixture(root)
            invalid_request = root / "Журнал" / "без-времени" / "запрос.md"
            invalid_request.parent.mkdir()
            invalid_request.write_text("# Запрос\n", encoding="utf-8")
            config_path = self.write_config(root, invalid_request, automation)
            output = root / "Ревью" / "пример-ревью.md"

            with self.assertRaisesRegex(ValueError, "Журнал"):
                build_work_review.build_review_document(config_path, output, root)

            self.assertFalse(output.exists())

    def test_validate_reports_missing_findings_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request, automation = self.write_git_fixture(root)
            config = self.write_config(root, request, automation)
            output = root / "Ревью" / "пример-ревью.md"
            build_work_review.build_review_document(config, output, root)
            broken = output.read_text(encoding="utf-8").replace("## Находки", "## Итог")
            output.write_text(broken, encoding="utf-8")

            errors = build_work_review.validate_review_document(config, output, root, complete=True)

            self.assertIn("missing section: Находки", errors)


if __name__ == "__main__":
    unittest.main()
