import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "build-planning-registry.py"
)

spec = importlib.util.spec_from_file_location("build_planning_registry", SCRIPT_PATH)
build_planning_registry = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = build_planning_registry
spec.loader.exec_module(build_planning_registry)


class BuildPlanningRegistryTests(unittest.TestCase):
    def write_fixture(self, root: Path) -> Path:
        (root / "Планирование" / "направления-проектирования-и-развития").mkdir(parents=True)
        (root / "Планирование" / "MVP-кандидаты" / "01-тест").mkdir(parents=True)
        (root / "Планирование" / "стадии" / "01-тестовая-стадия").mkdir(parents=True)
        (root / "Вопросы").mkdir()
        (root / "Инструменты" / "fum-planning-registry").mkdir(parents=True)

        (root / "Инструменты" / "fum-planning-registry" / "SKILL.md").write_text(
            "# FUM Planning Registry\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "дорожная-карта.md").write_text(
            "# Дорожная карта FUM\n\n"
            "## Горизонт 0. Связная память проекта\n\n"
            "Тестовый горизонт.\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "сводная-таблица-требований-и-реализаций.md").write_text(
            "# Сводная таблица требований и реализаций FUM\n\n"
            "## Сводная таблица\n\n"
            "| Слой требований | Что нужно реализовать | Предполагаемая реализация на документационной стадии | Предполагаемая реализация в коробочной FUM | Кандидаты и ближайшие артефакты | Статус |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| [Память FUM](../Глоссарий/память-FUM.md) | Сохранять трассу. | Ручной контур; [автоматизация](../Инструменты/fum-planning-registry/SKILL.md). | Встроенный реестр происхождения; runtime памяти. | [MVP тест](MVP-кандидаты/01-тест/README.md); [направление](направления-проектирования-и-развития/01-тест.md). | Активно. |\n\n"
            "## Стадийная очередь продуктовых кандидатов\n\n"
            "| Стадия | Порядок | MVP-кандидат | Первый запускаемый результат | Какие требования закрывает первым | Рабочий вывод |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| [Тестовая стадия](стадии/01-тестовая-стадия/README.md) | 1 | [MVP тест](MVP-кандидаты/01-тест/README.md) | JSON. | Память. | Ближайший. |\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "направления-проектирования-и-развития" / "README.md").write_text(
            "# Направления проектирования и развития FUM\n\n"
            "## Карта направлений и ближайших артефактов\n\n"
            "| Направление | Смысл | Ближайший проверяемый артефакт | Проверка |\n"
            "| --- | --- | --- | --- |\n"
            "| [01. Тест](01-тест.md) | Смысл. | Артефакт. | Проверка. |\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "направления-проектирования-и-развития" / "01-тест.md").write_text(
            "# 01. Тест\n\n## Назначение\n\nТест.\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "MVP-кандидаты" / "README.md").write_text(
            "# MVP-кандидаты FUM\n\n"
            "## Кандидаты\n\n"
            "| Кандидат | Запускаемая продуктовая идея | Первый пользовательский результат |\n"
            "| --- | --- | --- |\n"
            "| [01. MVP тест](01-тест/README.md) | Идея. | Результат. |\n\n"
            "## Стадийная карта кандидатов\n\n"
            "| MVP-кандидат | Форма на стадии документационного прототипа | Переходный результат | Форма в коробочной реализации FUM |\n"
            "| --- | --- | --- | --- |\n"
            "| [01. MVP тест](01-тест/README.md) | Документальная форма. | Контракт. | Коробочная форма. |\n\n"
            "## Текущий выбор\n\n"
            "[MVP тест](01-тест/README.md) выбран в работу.\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "MVP-кандидаты" / "01-тест" / "README.md").write_text(
            "# MVP-кандидат: тест\n\n## Паспорт\n\nТест.\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "стадии" / "README.md").write_text(
            "# Стадии планирования FUM\n\n"
            "## Карта стадий\n\n"
            "| Стадия | Смысл | Основные плановые материалы | Проверка |\n"
            "| --- | --- | --- | --- |\n"
            "| [01. Тестовая стадия](01-тестовая-стадия/README.md) | Смысл стадии. | [сводная таблица](../сводная-таблица-требований-и-реализаций.md). | Проверка стадии. |\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "стадии" / "01-тестовая-стадия" / "README.md").write_text(
            "# Стадия: тестовая стадия\n\n## Назначение\n\nТест.\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "предложения-о-следующих-шагах.md").write_text(
            "# Предложения о следующих шагах FUM\n\n"
            "## Актуальные предложения\n\n"
            "| Статус | Предложение | Почему сейчас | Опорные источники |\n"
            "| --- | --- | --- | --- |\n"
            "| Актуально | Подготовить тестовый реестр. | Нужна проверка. | [дорожная карта](дорожная-карта.md) |\n\n"
            "## История предложений\n\n"
            "| Статус | Предложение | Что произошло | Опорные источники |\n"
            "| --- | --- | --- | --- |\n"
            "| Выполнено | Старое предложение. | Сделано. | [дорожная карта](дорожная-карта.md) |\n",
            encoding="utf-8",
        )
        (root / "Вопросы" / "README.md").write_text(
            "# Вопросы\n\n"
            "## [Открытые вопросы](../Глоссарий/открытый-вопрос.md)\n\n"
            "- [Тестовый вопрос](тестовый-вопрос.md)\n\n"
            "## Частично прояснённые вопросы\n\n"
            "- [Частичный вопрос](частичный-вопрос.md)\n\n"
            "## Прояснённые вопросы\n\n"
            "- [Прояснённый вопрос](прояснённый-вопрос.md)\n",
            encoding="utf-8",
        )
        for name in ["тестовый-вопрос.md", "частичный-вопрос.md", "прояснённый-вопрос.md"]:
            (root / "Вопросы" / name).write_text(f"# {name}\n", encoding="utf-8")

        return root / "Планирование" / "реестр-требований-вариантов-и-кандидатов.json"

    def test_build_registry_normalizes_requirements_and_sources(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)

            registry = build_planning_registry.build_registry(root)

            self.assertEqual(registry["schema"], build_planning_registry.SCHEMA)
            self.assertEqual(registry["requirements"][0]["id"], "REQ-001")
            self.assertEqual(
                registry["requirements"][0]["documentation_stage_implementation"][1]["text"],
                "автоматизация.",
            )
            self.assertEqual(
                registry["requirements"][0]["boxed_fum_implementation"][0]["text"],
                "Встроенный реестр происхождения",
            )
            self.assertEqual(registry["source_inventory"]["roadmap_horizons"][0]["id"], "horizon-0")
            self.assertEqual(registry["source_inventory"]["stages"][0]["id"], "stage-01")
            self.assertEqual(
                registry["source_inventory"]["stages"][0]["file"],
                "Планирование/стадии/01-тестовая-стадия/README.md",
            )
            self.assertEqual(registry["source_inventory"]["mvp_candidates"][0]["status"], "выбран в работу")
            self.assertEqual(
                registry["source_inventory"]["mvp_stage_map"][0]["transition_result"],
                "Контракт.",
            )
            self.assertEqual(
                registry["source_inventory"]["product_queue"][0]["stage_link"],
                "Планирование/стадии/01-тестовая-стадия/README.md",
            )
            self.assertEqual(registry["source_inventory"]["questions"]["open"][0]["title"], "Тестовый вопрос")
            self.assertTrue(registry["coverage"]["mvp_candidates"][0]["in_product_queue"])
            self.assertTrue(registry["coverage"]["mvp_candidates"][0]["in_stage_map"])

    def test_validate_accepts_rebuilt_registry(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)

            build_planning_registry.build_to_file(output, root)
            errors = build_planning_registry.validate_file(output, root)

            self.assertEqual(errors, [])

    def test_validate_reports_stale_registry_after_source_change(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            build_planning_registry.build_to_file(output, root)

            proposals = root / "Планирование" / "предложения-о-следующих-шагах.md"
            proposals.write_text(
                proposals.read_text(encoding="utf-8").replace(
                    "Подготовить тестовый реестр.",
                    "Подготовить изменённый тестовый реестр.",
                ),
                encoding="utf-8",
            )

            errors = build_planning_registry.validate_file(output, root)

            self.assertIn("registry is stale", "\n".join(errors))


if __name__ == "__main__":
    unittest.main()
