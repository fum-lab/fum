import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "build-doc-aggregation.py"
)

spec = importlib.util.spec_from_file_location("build_doc_aggregation", SCRIPT_PATH)
build_doc_aggregation = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(build_doc_aggregation)


class BuildDocAggregationTests(unittest.TestCase):
    def write_fixture(self, root: Path) -> tuple[Path, Path]:
        (root / "Документация").mkdir()
        request_dir = root / "Журнал" / "2026-06-24_15-45-41_MSK_собрать-архитектуру"
        request_dir.mkdir(parents=True)
        (root / "Инструменты" / "fum-sborka-svodnoj-dokumentacii").mkdir(parents=True)
        (
            root / "Инструменты" / "fum-sborka-svodnoj-dokumentacii" / "SKILL.md"
        ).write_text("# Сборка сводной документации\n", encoding="utf-8")

        (request_dir / "запрос.md").write_text(
            "# Исходный запрос 2026-06-24 15:45:41 MSK\n",
            encoding="utf-8",
        )
        (root / "Документация" / "00-обзор-проекта.md").write_text(
            "# Обзор проекта FUM\n\nТекст обзора.\n",
            encoding="utf-8",
        )
        (root / "Документация" / "05-модульная-архитектура-FUM.md").write_text(
            "# Модульная архитектура FUM\n\nТекст о модульности.\n",
            encoding="utf-8",
        )
        config = {
            "title": "Архитектура FUM",
            "topic": "архитектура FUM",
            "purpose": "Собрать разнесённые архитектурные требования в одну карту.",
            "request_file": "Журнал/2026-06-24_15-45-41_MSK_собрать-архитектуру/запрос.md",
            "automation_file": "Инструменты/fum-sborka-svodnoj-dokumentacii/SKILL.md",
            "source_documents": [
                {
                    "path": "Документация/00-обзор-проекта.md",
                    "role": "обзорный вход",
                },
                {
                    "path": "Документация/05-модульная-архитектура-FUM.md",
                    "role": "детальный слой модульности",
                },
            ],
            "sections": [
                {
                    "title": "Карта слоёв",
                    "focus": "Показать, какие слои образуют общую архитектуру.",
                }
            ],
        }
        config_path = root / "aggregation.json"
        config_path.write_text(
            json.dumps(config, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        output_path = root / "Документация" / "22-архитектура-FUM.md"
        return config_path, output_path

    def test_build_creates_canonical_svodnaya_article_scaffold(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)

            result = build_doc_aggregation.build_document(config_path, output_path, root)

            self.assertIn("# Архитектура FUM", result)
            self.assertIn(
                "[исходный запрос 2026-06-24 15:45:41 MSK]"
                "(../Журнал/2026-06-24_15-45-41_MSK_собрать-архитектуру/запрос.md)",
                result,
            )
            self.assertIn(
                "[Обзор проекта FUM](00-обзор-проекта.md) - обзорный вход",
                result,
            )
            self.assertIn("## Паспорт сводной статьи", result)
            self.assertIn("## Карта источников", result)
            self.assertIn("## Карта слоёв", result)
            self.assertIn("DOC_AGGREGATION_TODO", result)
            self.assertTrue(output_path.exists())

    def test_build_rejects_absolute_and_escaping_config_paths_before_write(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            original = json.loads(config_path.read_text(encoding="utf-8"))
            invalid_values = (
                ("request_file", (root / original["request_file"]).as_posix()),
                ("request_file", "../внешний-запрос.md"),
                ("automation_file", "C:\\repo\\SKILL.md"),
                ("source_documents", "file:///repo/источник.md"),
            )

            for field, value in invalid_values:
                with self.subTest(field=field, value=value):
                    config = json.loads(json.dumps(original, ensure_ascii=False))
                    if field == "source_documents":
                        config[field][0]["path"] = value
                    else:
                        config[field] = value
                    config_path.write_text(
                        json.dumps(config, ensure_ascii=False, indent=2),
                        encoding="utf-8",
                    )
                    output_path.unlink(missing_ok=True)

                    with self.assertRaises(ValueError):
                        build_doc_aggregation.build_document(
                            config_path,
                            output_path,
                            root,
                        )
                    self.assertFalse(output_path.exists())

    def test_validate_accepts_complete_document_with_all_sources(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            document = build_doc_aggregation.build_document(config_path, output_path, root)
            complete = document.replace(
                "DOC_AGGREGATION_TODO: сформулировать сводный тезис по источникам.",
                "Сводный тезис сформулирован на основе указанных источников.",
            ).replace(
                "DOC_AGGREGATION_TODO: собрать раздел из опорных документов.",
                "Раздел собран из опорных документов.",
            )
            output_path.write_text(complete, encoding="utf-8")

            errors = build_doc_aggregation.validate_document(
                config_path,
                output_path,
                root,
                require_complete=True,
            )

            self.assertEqual(errors, [])

    def test_build_rejects_request_without_timestamped_journal_parent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            invalid_request = root / "Журнал" / "без-времени" / "запрос.md"
            invalid_request.parent.mkdir()
            invalid_request.write_text("# Запрос\n", encoding="utf-8")
            config = json.loads(config_path.read_text(encoding="utf-8"))
            config["request_file"] = invalid_request.relative_to(root).as_posix()
            config_path.write_text(
                json.dumps(config, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Журнал"):
                build_doc_aggregation.build_document(config_path, output_path, root)

            self.assertFalse(output_path.exists())

    def test_validate_reports_missing_source_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            document = build_doc_aggregation.build_document(config_path, output_path, root)
            broken = document.replace(
                "[Обзор проекта FUM](00-обзор-проекта.md)",
                "Обзор проекта FUM",
            )
            output_path.write_text(broken, encoding="utf-8")

            errors = build_doc_aggregation.validate_document(
                config_path,
                output_path,
                root,
            )

            self.assertIn(
                "missing source link: Документация/00-обзор-проекта.md",
                errors,
            )

    def test_validate_requires_completed_document_when_requested(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config_path, output_path = self.write_fixture(root)
            build_doc_aggregation.build_document(config_path, output_path, root)

            errors = build_doc_aggregation.validate_document(
                config_path,
                output_path,
                root,
                require_complete=True,
            )

            self.assertIn("document still contains DOC_AGGREGATION_TODO markers", errors)


if __name__ == "__main__":
    unittest.main()
