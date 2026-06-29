import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "build-estimate.py"
)

spec = importlib.util.spec_from_file_location("build_estimate", SCRIPT_PATH)
build_estimate = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = build_estimate
spec.loader.exec_module(build_estimate)


class BuildEstimateTests(unittest.TestCase):
    def write_fixture(self, root: Path) -> tuple[Path, Path]:
        (root / "Оценки").mkdir()
        (root / "Запросы").mkdir()
        (root / "Инструменты" / "fum-estimates").mkdir(parents=True)

        (root / "Запросы" / "2026-06-29_19-05-53_MSK.md").write_text(
            "# Исходный запрос 2026-06-29 19:05:53 MSK\n",
            encoding="utf-8",
        )
        (root / "Инструменты" / "fum-estimates" / "SKILL.md").write_text(
            "# FUM Estimates\n",
            encoding="utf-8",
        )

        config = {
            "title": "Оценка тестовой трудоёмкости",
            "request_file": "Запросы/2026-06-29_19-05-53_MSK.md",
            "automation_file": "Инструменты/fum-estimates/SKILL.md",
            "question": "Сколько времени потребовалось бы человеку?",
            "unit": "человеко-часы",
            "point_estimate": 10,
            "range": {"low": 8, "high": 14},
            "summary": "Наиболее вероятная оценка составляет **10 человеко-часов**.",
            "scope": "Оценка относится к тестовому фрагменту памяти.",
            "snapshot": {
                "date": "2026-06-29",
                "metrics": [
                    {"name": "Отслеживаемые файлы", "value": "3"},
                    {"name": "Markdown-файлы", "value": "2"},
                ],
                "notes": [
                    "Снимок создан для локального теста автоматизации.",
                ],
            },
            "methodology": [
                {
                    "name": "Разложение по видам работы",
                    "description": "Оценка собирается из компонентных диапазонов.",
                }
            ],
            "breakdown": [
                {
                    "name": "Подготовка источников",
                    "low": 2,
                    "high": 4,
                    "comment": "Поиск и чтение материалов.",
                },
                {
                    "name": "Сборка результата",
                    "low": 6,
                    "high": 10,
                    "comment": "Запись и проверка оценки.",
                },
            ],
            "assumptions": [
                "Исполнитель понимает правила памяти FUM.",
                "Сетевые источники не требуются.",
            ],
            "precision_limits": [
                "Оценка не является фактическим тайм-трекингом.",
                "Диапазон отражает порядок величины, а не точную стоимость.",
            ],
            "result_format": [
                "Ключевой вывод стоит в первых абзацах.",
                "Снимок, методика, диапазоны, допущения и ограничения выделены отдельными разделами.",
            ],
            "interpretation": [
                "Тестовый результат показывает структуру оценочного файла.",
            ],
        }
        config_path = root / "estimate.json"
        config_path.write_text(
            json.dumps(config, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        output_path = root / "Оценки" / "оценка-тестовой-трудоёмкости.md"
        return config_path, output_path

    def test_build_creates_estimate_with_required_sections(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)

            result = build_estimate.build_document(config_path, output_path, root)

            self.assertIn("# Оценка тестовой трудоёмкости", result)
            self.assertIn("## Снимок репозитория", result)
            self.assertIn("## Методика расчёта", result)
            self.assertIn("## Диапазоны", result)
            self.assertIn("## Допущения", result)
            self.assertIn("## Ограничения точности", result)
            self.assertIn("## Оформление результата", result)
            self.assertIn("**8-14 человеко-часы**", result)
            self.assertIn(
                "[исходный запрос 2026-06-29 19:05:53 MSK]",
                result,
            )
            self.assertTrue(output_path.exists())

    def test_validate_accepts_complete_estimate(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            build_estimate.build_document(config_path, output_path, root)

            errors = build_estimate.validate_document(
                config_path,
                output_path,
                root,
                require_complete=True,
            )

            self.assertEqual(errors, [])

    def test_validate_reports_missing_required_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            document = build_estimate.build_document(config_path, output_path, root)
            output_path.write_text(
                document.replace("## Допущения\n\n", ""),
                encoding="utf-8",
            )

            errors = build_estimate.validate_document(
                config_path,
                output_path,
                root,
            )

            self.assertIn("missing heading: Допущения", errors)

    def test_validate_reports_missing_range(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            document = build_estimate.build_document(config_path, output_path, root)
            output_path.write_text(
                document.replace("**8-14 человеко-часы**", "**10 человеко-часы**"),
                encoding="utf-8",
            )

            errors = build_estimate.validate_document(
                config_path,
                output_path,
                root,
            )

            self.assertIn("missing final range: 8-14 человеко-часы", errors)

    def test_collect_repository_snapshot_records_git_metrics(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "README.md").write_text("# README\n\nТекст.\n", encoding="utf-8")
            (root / "data.txt").write_text("plain text\n", encoding="utf-8")
            subprocess.run(["git", "init"], cwd=root, check=True, stdout=subprocess.PIPE)
            subprocess.run(["git", "add", "README.md", "data.txt"], cwd=root, check=True)
            env = {
                **os.environ,
                "GIT_AUTHOR_DATE": "2026-06-29T12:00:00+03:00",
                "GIT_COMMITTER_DATE": "2026-06-29T12:00:00+03:00",
            }
            subprocess.run(
                [
                    "git",
                    "-c",
                    "user.name=FUM Test",
                    "-c",
                    "user.email=fum-test@example.invalid",
                    "commit",
                    "-m",
                    "initial",
                ],
                cwd=root,
                check=True,
                env=env,
                stdout=subprocess.PIPE,
            )

            snapshot = build_estimate.collect_repository_snapshot(root)
            metrics = {
                metric["name"]: metric["value"]
                for metric in snapshot["metrics"]
            }

            self.assertEqual(metrics["Количество коммитов"], "1")
            self.assertEqual(metrics["Отслеживаемые файлы"], "2")
            self.assertEqual(metrics["Markdown-файлы"], "1")
            self.assertIn("Git-коммит", metrics)


if __name__ == "__main__":
    unittest.main()
