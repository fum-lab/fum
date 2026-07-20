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
    def write_requirement_cards(self, root: Path) -> None:
        requirements = root / "Требования"
        requirements.mkdir()
        (requirements / "README.md").write_text(
            "# Требования FUM\n\n"
            "Первый эмодзи имени файла показывает статус требования.\n\n"
            "- `🟡` — принято и запланировано;\n"
            "- `🚧` — реализуется.\n\n"
            "## Тестовый контур\n\n"
            "- `FUM-REQ-0001` — [🟡 Сохранять трассу](🟡-сохранять-трассу.md)\n"
            "- `FUM-REQ-0002` — [🚧 Проверять трассу](🚧-проверять-трассу.md)\n",
            encoding="utf-8",
        )
        (requirements / "🟡-сохранять-трассу.md").write_text(
            "# Сохранять трассу\n\n"
            "<!-- FUM-REQUIREMENT-ID: FUM-REQ-0001 -->\n\n"
            "FUM должен сохранять восстанавливаемую трассу каждого изменения.\n\n"
            "## Семантические связи\n\n"
            "- **зависит от:** [проверки трассы](🚧-проверять-трассу.md) — "
            "непроверенная трасса не подтверждает происхождение.\n\n"
            "## Критерии проверки\n\n"
            "- трасса содержит вход, результат и проверку;\n"
            "- повторное чтение восстанавливает порядок событий.\n\n"
            "## Статус и границы\n\n"
            "Статус требования — `🟡`: требование принято и запланировано.\n\n"
            "## Источники требований\n\n"
            "- [дорожная карта](../Планирование/дорожная-карта.md)\n",
            encoding="utf-8",
        )
        (requirements / "🚧-проверять-трассу.md").write_text(
            "# Проверять трассу\n\n"
            "<!-- FUM-REQUIREMENT-ID: FUM-REQ-0002 -->\n\n"
            "FUM должен проверять целостность сохранённой трассы.\n\n"
            "## Семантические связи\n\n"
            "- **требуется для:** [сохранения трассы](🟡-сохранять-трассу.md) — "
            "подтверждает происхождение сохранённого результата.\n\n"
            "## Критерии проверки\n\n"
            "- повреждение трассы обнаруживается до использования результата.\n\n"
            "## Статус и границы\n\n"
            "Статус требования — `🚧`: требование реализуется.\n\n"
            "## Источники требований\n\n"
            "- [дорожная карта](../Планирование/дорожная-карта.md)\n",
            encoding="utf-8",
        )

    def write_fixture(self, root: Path) -> Path:
        (root / "Планирование" / "направления-проектирования-и-развития").mkdir(parents=True)
        (root / "Планирование" / "MVP-кандидаты" / "01-тест").mkdir(parents=True)
        (root / "Планирование" / "стадии" / "01-тестовая-стадия").mkdir(parents=True)
        (root / "Вопросы").mkdir()
        (root / "Инструменты" / "fum-planning-registry").mkdir(parents=True)
        self.write_requirement_cards(root)

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
            "| [Память FUM](../Глоссарий/память-FUM.md) | Сохранять трассу. | Ручной контур; [автоматизация](../Инструменты/fum-planning-registry/SKILL.md). | Встроенный реестр происхождения; runtime памяти. | [MVP тест](MVP-кандидаты/01-тест/README.md); [направление](направления-проектирования-и-развития/01-тест.md). | Активно. |\n"
            "| Обзорный слой | Показывать общую картину. | Сводка. | Проекция реестра. | Навигация. | Производно. |\n\n"
            "## Карта широких строк\n\n"
            "| Идентификатор | Слой требований | Роль | Каноническая карточка |\n"
            "| --- | --- | --- | --- |\n"
            "| PLAN-LAYER-MEMORY | Память FUM | Карточечно-связанный слой | [FUM-REQ-0001](../Требования/🟡-сохранять-трассу.md) |\n"
            "| PLAN-LAYER-OVERVIEW | Обзорный слой | Производный слой | — |\n\n"
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

    def test_build_registry_uses_requirement_cards_as_canonical_requirements(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)

            registry = build_planning_registry.build_registry(root)

            self.assertEqual(registry["schema"], build_planning_registry.SCHEMA)
            self.assertEqual(registry["requirements"][0]["id"], "FUM-REQ-0001")
            self.assertEqual(registry["requirements"][0]["status"]["symbol"], "🟡")
            self.assertEqual(registry["requirements"][0]["status"]["code"], "planned")
            self.assertEqual(
                registry["requirements"][0]["formulation"]["text"],
                "FUM должен сохранять восстанавливаемую трассу каждого изменения.",
            )
            self.assertEqual(
                registry["requirements"][0]["criteria"][0]["text"],
                "трасса содержит вход, результат и проверку;",
            )
            self.assertEqual(
                registry["requirements"][0]["semantic_relations"][0]["target_requirement_id"],
                "FUM-REQ-0002",
            )
            self.assertEqual(
                registry["planning_views"][0]["documentation_stage_implementation"][1]["text"],
                "автоматизация.",
            )
            self.assertEqual(
                registry["planning_views"][0]["boxed_fum_implementation"][0]["text"],
                "Встроенный реестр происхождения",
            )
            self.assertEqual(
                registry["planning_views"][0]["canonical_requirement_ids"],
                ["FUM-REQ-0001"],
            )
            self.assertEqual(registry["planning_views"][0]["id"], "PLAN-LAYER-MEMORY")
            self.assertEqual(registry["planning_views"][0]["representation"], "card-linked")
            self.assertEqual(registry["planning_views"][1]["representation"], "derived")
            source_paths = {item["path"] for item in registry["source_files"]}
            self.assertIn("Требования/README.md", source_paths)
            self.assertIn("Требования/🟡-сохранять-трассу.md", source_paths)
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

    def test_build_rejects_requirement_missing_mandatory_section(self):
        for section in build_planning_registry.REQUIRED_REQUIREMENT_SECTIONS:
            with self.subTest(section=section), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                card = root / "Требования" / "🟡-сохранять-трассу.md"
                card.write_text(
                    card.read_text(encoding="utf-8").replace(
                        f"## {section}",
                        f"## Удалённый раздел {section}",
                    ),
                    encoding="utf-8",
                )

                with self.assertRaisesRegex(
                    ValueError,
                    f"missing required section {section}",
                ):
                    build_planning_registry.build_to_file(output, root)

    def test_build_rejects_empty_requirement_sources_before_recency(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            card = root / "Требования" / "🟡-сохранять-трассу.md"
            card.write_text(
                card.read_text(encoding="utf-8").replace(
                    "- [дорожная карта](../Планирование/дорожная-карта.md)\n",
                    "<!-- FUM-MD-RECENCY:BEGIN -->\n"
                    "<!-- last-content-edit: 2026-07-20 21:22:17 MSK -->\n"
                    "<!-- content-sha256: sha256:"
                    "0000000000000000000000000000000000000000000000000000000000000000 -->\n"
                    "<!-- FUM-MD-RECENCY:END -->\n",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                ValueError,
                "missing required section Источники требований",
            ):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_requirement_missing_from_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            index = root / "Требования" / "README.md"
            index.write_text(
                index.read_text(encoding="utf-8").replace(
                    "- `FUM-REQ-0002` — [🚧 Проверять трассу](🚧-проверять-трассу.md)\n",
                    "",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "requirement card is not indexed"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_requirement_index_id_mismatch(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            index = root / "Требования" / "README.md"
            index.write_text(
                index.read_text(encoding="utf-8").replace(
                    "`FUM-REQ-0001` — [🟡 Сохранять трассу]",
                    "`FUM-REQ-0099` — [🟡 Сохранять трассу]",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                ValueError,
                "requirement index id does not match card",
            ):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_non_ascii_requirement_id(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            for path in [
                root / "Требования" / "README.md",
                root / "Требования" / "🟡-сохранять-трассу.md",
                root
                / "Планирование"
                / "сводная-таблица-требований-и-реализаций.md",
            ]:
                path.write_text(
                    path.read_text(encoding="utf-8").replace(
                        "FUM-REQ-0001",
                        "FUM-REQ-٠٠٠١",
                    ),
                    encoding="utf-8",
                )

            with self.assertRaisesRegex(
                ValueError,
                "malformed requirement index entry",
            ):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_invalid_requirement_status(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            card = root / "Требования" / "🟡-сохранять-трассу.md"
            card.rename(root / "Требования" / "❌-сохранять-трассу.md")

            with self.assertRaisesRegex(ValueError, "invalid requirement status"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_status_mismatch_in_index_or_body(self):
        mutations = {
            "index": (
                "README.md",
                "[🟡 Сохранять трассу]",
                "[🚧 Сохранять трассу]",
                "requirement index status does not match filename",
            ),
            "body": (
                "🟡-сохранять-трассу.md",
                "Статус требования — `🟡`",
                "Статус требования — `🚧`",
                "requirement body status does not match filename",
            ),
        }
        for name, (filename, old, new, error) in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                path = root / "Требования" / filename
                path.write_text(
                    path.read_text(encoding="utf-8").replace(old, new),
                    encoding="utf-8",
                )

                with self.assertRaisesRegex(ValueError, error):
                    build_planning_registry.build_to_file(output, root)

    def test_build_rejects_duplicate_requirement_id(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            for path in [
                root / "Требования" / "README.md",
                root / "Требования" / "🚧-проверять-трассу.md",
            ]:
                path.write_text(
                    path.read_text(encoding="utf-8").replace(
                        "FUM-REQ-0002",
                        "FUM-REQ-0001",
                    ),
                    encoding="utf-8",
                )

            with self.assertRaisesRegex(ValueError, "duplicate requirement id"):
                build_planning_registry.build_to_file(output, root)

    def test_build_preserves_multiline_requirement_criterion(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            card = root / "Требования" / "🟡-сохранять-трассу.md"
            card.write_text(
                card.read_text(encoding="utf-8").replace(
                    "- трасса содержит вход, результат и проверку;",
                    "- трасса содержит вход,\n  результат и проверку;",
                ),
                encoding="utf-8",
            )

            registry = build_planning_registry.build_registry(root)

            self.assertEqual(
                registry["requirements"][0]["criteria"][0]["text"],
                "трасса содержит вход, результат и проверку;",
            )

    def test_build_rejects_misplaced_requirement_id(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            card = root / "Требования" / "🟡-сохранять-трассу.md"
            text = card.read_text(encoding="utf-8")
            marker = "<!-- FUM-REQUIREMENT-ID: FUM-REQ-0001 -->"
            card.write_text(
                text.replace(f"{marker}\n\n", "").replace(
                    "## Источники требований",
                    f"{marker}\n\n## Источники требований",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                ValueError,
                "stable requirement id marker must immediately follow heading",
            ):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_unpaired_semantic_relation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            card = root / "Требования" / "🚧-проверять-трассу.md"
            card.write_text(
                card.read_text(encoding="utf-8").replace(
                    "**требуется для:**",
                    "**дополняется:**",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "missing inverse semantic relation"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_unclassified_planning_view(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            summary = root / "Планирование" / "сводная-таблица-требований-и-реализаций.md"
            summary.write_text(
                summary.read_text(encoding="utf-8").replace(
                    "[FUM-REQ-0001](../Требования/🟡-сохранять-трассу.md)",
                    "Не классифицировано",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                ValueError,
                "planning view must link requirement cards or be marked as derived",
            ):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_unindexed_active_proposal_text(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            proposals = root / "Планирование" / "предложения-о-следующих-шагах.md"
            proposals.write_text(
                proposals.read_text(encoding="utf-8").replace(
                    "## Актуальные предложения\n\n",
                    "## Актуальные предложения\n\n"
                    "- **Актуально:** скрытое предложение вне таблицы.\n\n",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "unindexed active proposal text"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_malformed_active_proposal_table(self):
        mutations = {
            "malformed_data_row": (
                "| Актуально | Подготовить тестовый реестр. | Нужна проверка. | "
                "[дорожная карта](дорожная-карта.md) |",
                "| Скрытое актуальное предложение |",
            ),
            "hidden_row_before_header": (
                "## Актуальные предложения\n\n",
                "## Актуальные предложения\n\n"
                "| Скрытое актуальное предложение |\n",
            ),
        }
        for name, (old, new) in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                proposals = (
                    root
                    / "Планирование"
                    / "предложения-о-следующих-шагах.md"
                )
                proposals.write_text(
                    proposals.read_text(encoding="utf-8").replace(old, new),
                    encoding="utf-8",
                )

                with self.assertRaisesRegex(
                    ValueError,
                    "malformed table row.*Актуальные предложения",
                ):
                    build_planning_registry.build_to_file(output, root)

    def test_build_rejects_missing_active_proposals_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            proposals = root / "Планирование" / "предложения-о-следующих-шагах.md"
            proposals.write_text(
                proposals.read_text(encoding="utf-8").replace(
                    "## Актуальные предложения",
                    "## Скрытые предложения",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                ValueError,
                "missing required table section.*Актуальные предложения",
            ):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_malformed_planning_view_tables(self):
        mutations = {
            "summary": "Сохранять трассу.",
            "mapping": "PLAN-LAYER-MEMORY",
        }
        for name, marker in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                summary = (
                    root
                    / "Планирование"
                    / "сводная-таблица-требований-и-реализаций.md"
                )
                lines = summary.read_text(encoding="utf-8").splitlines()
                mutated = False
                for index, line in enumerate(lines):
                    if marker in line:
                        lines[index] = line.rstrip("|")
                        mutated = True
                        break
                self.assertTrue(mutated)
                summary.write_text("\n".join(lines) + "\n", encoding="utf-8")

                with self.assertRaisesRegex(
                    ValueError,
                    "malformed table row",
                ):
                    build_planning_registry.build_to_file(output, root)

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
