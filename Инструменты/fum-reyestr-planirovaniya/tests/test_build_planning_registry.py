import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


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


ACTIVE_STEP_CARD = "🟡-FUM-STEP-0001-подготовить-тестовый-реестр.md"
COMPLETED_STEP_CARD = "✅-FUM-STEP-0002-старое-предложение.md"
ABSORBED_STEP_CARD = "🧩-FUM-STEP-0003-поглощённое-предложение.md"
WITHDRAWN_STEP_CARD = "🗑️-FUM-STEP-0004-снятое-предложение.md"
АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ = "🚧-FUM-ЦЕПОЧКА-0001-тестовая-цепочка.md"
ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ = "🗑️-FUM-ЦЕПОЧКА-0002-отозванная-цепочка.md"
BOXED_GRAPH_MARKDOWN = Path(
    "Планирование/стадии/02-коробочная-реализация-FUM/граф-зависимостей.md"
)
BOXED_GRAPH_JSON = BOXED_GRAPH_MARKDOWN.with_suffix(".json")


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

    def write_step_cards(self, root: Path) -> None:
        cards = root / "Планирование" / "карточки-шагов"
        cards.mkdir(parents=True)
        (root / "Планирование" / "предложения-о-следующих-шагах.md").write_text(
            "# Предложения о следующих шагах FUM\n\n"
            "Актуальный канонический список хранится в карточках шагов.\n",
            encoding="utf-8",
        )
        (cards / "README.md").write_text(
            "# Карточки шагов FUM\n\n"
            "## Индекс\n\n"
            "| Идентификатор | Статус | Карточка |\n"
            "| --- | --- | --- |\n"
            f"| `FUM-STEP-0001` | 🟡 Актуально | [Подготовить тестовый реестр]({ACTIVE_STEP_CARD}) |\n"
            f"| `FUM-STEP-0002` | ✅ Выполнено | [Старое предложение]({COMPLETED_STEP_CARD}) |\n"
            f"| `FUM-STEP-0003` | 🧩 Поглощено | [Поглощённое предложение]({ABSORBED_STEP_CARD}) |\n"
            f"| `FUM-STEP-0004` | 🗑️ Снято | [Снятое предложение]({WITHDRAWN_STEP_CARD}) |\n",
            encoding="utf-8",
        )
        (cards / ACTIVE_STEP_CARD).write_text(
            "+++\n"
            "schema_version = 1\n"
            'card_id = "FUM-STEP-0001"\n'
            'status = "active"\n'
            "+++\n"
            "# Подготовить тестовый реестр\n\n"
            "Карточка сохраняет один самостоятельный шаг.\n\n"
            "## Задача\n\n"
            "Подготовить тестовый реестр.\n\n"
            "## Почему сейчас\n\n"
            "Нужна проверка.\n\n"
            "## Критерии завершения\n\n"
            "- Реестр собирается.\n"
            "- Проверка реестра проходит.\n\n"
            "## Источники\n\n"
            "- [дорожная карта](../дорожная-карта.md)\n",
            encoding="utf-8",
        )
        (cards / COMPLETED_STEP_CARD).write_text(
            "+++\n"
            "schema_version = 1\n"
            'card_id = "FUM-STEP-0002"\n'
            'status = "completed"\n'
            "+++\n"
            "# Старое предложение\n\n"
            "Карточка сохраняет историю шага.\n\n"
            "## Задача\n\n"
            "Старое предложение.\n\n"
            "## Результат\n\n"
            "Сделано.\n\n"
            "## Источники\n\n"
            "- [дорожная карта](../дорожная-карта.md)\n",
            encoding="utf-8",
        )
        historical_cards = (
            (
                ABSORBED_STEP_CARD,
                "FUM-STEP-0003",
                "absorbed",
                "Поглощённое предложение",
                "Предложение поглощено более точным шагом.",
            ),
            (
                WITHDRAWN_STEP_CARD,
                "FUM-STEP-0004",
                "withdrawn",
                "Снятое предложение",
                "Предложение снято с сохранением истории.",
            ),
        )
        for filename, card_id, status, title, outcome in historical_cards:
            (cards / filename).write_text(
                "+++\n"
                "schema_version = 1\n"
                f'card_id = "{card_id}"\n'
                f'status = "{status}"\n'
                "+++\n"
                f"# {title}\n\n"
                "Карточка сохраняет историю шага.\n\n"
                "## Задача\n\n"
                f"{title}.\n\n"
                "## Результат\n\n"
                f"{outcome}\n\n"
                "## Источники\n\n"
                "- [дорожная карта](../дорожная-карта.md)\n",
                encoding="utf-8",
            )

    def записать_карточки_цепочек(сам, корень: Path) -> None:
        карточки = корень / "Планирование" / "карточки-цепочек-шагов"
        карточки.mkdir(parents=True)
        (корень / "README.md").write_text(
            "# Тестовый проект FUM\n",
            encoding="utf-8",
        )
        (карточки / "README.md").write_text(
            "# Карточки цепочек шагов FUM\n\n"
            "## Индекс\n\n"
            "| Идентификатор | Состояние | Ветка | Карточка |\n"
            "| --- | --- | --- | --- |\n"
            "| `FUM-ЦЕПОЧКА-0001` | 🚧 Активна | `refs/heads/codex/test-chain` | "
            f"[Тестовая цепочка]({АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ}) |\n"
            "| `FUM-ЦЕПОЧКА-0002` | 🗑️ Отозвана | `refs/heads/codex/withdrawn-chain` | "
            f"[Отозванная цепочка]({ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ}) |\n",
            encoding="utf-8",
        )
        (карточки / АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ).write_text(
            "+++\n"
            '"версия_схемы" = 1\n'
            '"идентификатор_цепочки" = "FUM-ЦЕПОЧКА-0001"\n'
            '"состояние" = "активна"\n'
            '"ветка" = "refs/heads/codex/test-chain"\n'
            '"базовая_ветка" = "refs/heads/master"\n'
            '"путь_проекта" = "README.md"\n'
            '"карточки_шагов" = ["FUM-STEP-0001", "FUM-STEP-0002"]\n'
            "+++\n"
            "# Тестовая цепочка\n\n"
            "Цепочка задаёт упорядоченное последующее выполнение двух шагов.\n",
            encoding="utf-8",
        )
        (карточки / ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ).write_text(
            "+++\n"
            '"версия_схемы" = 1\n'
            '"идентификатор_цепочки" = "FUM-ЦЕПОЧКА-0002"\n'
            '"состояние" = "отозвана"\n'
            '"ветка" = "refs/heads/codex/withdrawn-chain"\n'
            '"базовая_ветка" = "refs/heads/master"\n'
            '"путь_проекта" = "README.md"\n'
            '"карточки_шагов" = ["FUM-STEP-0001"]\n'
            "+++\n"
            "# Отозванная цепочка\n\n"
            "Отозванная цепочка сохраняет плановую историю.\n",
            encoding="utf-8",
        )

    def rename_step_card(self, root: Path, old_name: str, new_name: str) -> Path:
        cards = root / "Планирование" / "карточки-шагов"
        old_path = cards / old_name
        new_path = cards / new_name
        old_path.rename(new_path)
        index = cards / "README.md"
        index.write_text(
            index.read_text(encoding="utf-8").replace(old_name, new_name),
            encoding="utf-8",
        )
        return new_path

    def write_fixture(self, root: Path) -> Path:
        (root / "Планирование" / "направления-проектирования-и-развития").mkdir(parents=True)
        (root / "Планирование" / "MVP-кандидаты" / "01-тест").mkdir(parents=True)
        (root / "Планирование" / "стадии" / "01-тестовая-стадия").mkdir(parents=True)
        (root / "Вопросы").mkdir()
        (root / "Инструменты" / "fum-reyestr-planirovaniya").mkdir(parents=True)
        self.write_requirement_cards(root)
        self.write_step_cards(root)
        self.записать_карточки_цепочек(root)

        карточка_активного_шага = (
            Path("Планирование") / "карточки-шагов" / ACTIVE_STEP_CARD
        )
        хэш_карточки = build_planning_registry.content_sha256(
            карточка_активного_шага,
            root,
        )
        каталог_следующих_шагов = (
            root / "Планирование" / "следующие-шаги-веток"
        )
        каталог_следующих_шагов.mkdir(parents=True)
        (каталог_следующих_шагов / "master.md").write_text(
            "+++\n"
            "schema_version = 5\n"
            'branch_ref = "refs/heads/master"\n'
            'state = "open"\n\n'
            'project_path = "README.md"\n\n'
            "[[candidates]]\n"
            'step_id = "master-fum-step-0001-automatic-v1"\n'
            'dispatch = "automatic"\n'
            'card_id = "FUM-STEP-0001"\n'
            f'card_content_sha256 = "{хэш_карточки}"\n'
            "requires_completed_card_ids = []\n"
            "+++\n"
            "# Выбирать следующий шаг\n",
            encoding="utf-8",
        )

        (root / "Инструменты" / "fum-reyestr-planirovaniya" / "SKILL.md").write_text(
            "# FUM Planning Registry\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "дорожная-карта.md").write_text(
            "# Дорожная карта FUM\n\n"
            "## Горизонт 0. Связная память проекта\n\n"
            "Тестовый горизонт.\n\n"
            "## Горизонт 1. Воспроизводимые автоматизации\n\n"
            "Тестовый горизонт без назначенного шага.\n\n"
            "## Проверяемая очередь следующих шагов\n\n"
            "Таблица проецирует канонический рабочий набор `master`.\n\n"
            "| Порядок записи | Поколение | Карточка | Режим | Зависимости | Стадии | Горизонты | Плановый горизонт |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- |\n"
            f"| 1 | master-fum-step-0001-automatic-v1 | [FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}) | `automatic` | — | [01. Тестовая стадия](стадии/01-тестовая-стадия/README.md) | `0` | готов сейчас |\n\n"
            "## Покрытие стадий и горизонтов\n\n"
            "Отсутствие назначенного шага показано явно.\n\n"
            "| Контур | Следующие шаги |\n"
            "| --- | --- |\n"
            f"| [01. Тестовая стадия](стадии/01-тестовая-стадия/README.md) | [FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}) |\n"
            f"| [Горизонт 0](#горизонт-0-связная-память-проекта) | [FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}) |\n"
            "| [Горизонт 1](#горизонт-1-воспроизводимые-автоматизации) | Нет назначенного шага |\n",
            encoding="utf-8",
        )
        (root / "Планирование" / "сводная-таблица-требований-и-реализаций.md").write_text(
            "# Сводная таблица требований и реализаций FUM\n\n"
            "## Сводная таблица\n\n"
            "| Слой требований | Что нужно реализовать | Предполагаемая реализация на документационной стадии | Предполагаемая реализация в коробочной FUM | Кандидаты и ближайшие артефакты | Статус |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| [Память FUM](../Глоссарий/память-FUM.md) | Сохранять трассу. | Ручной контур; [автоматизация](../Инструменты/fum-reyestr-planirovaniya/SKILL.md). | Встроенный реестр происхождения; runtime памяти. | [MVP тест](MVP-кандидаты/01-тест/README.md); [направление](направления-проектирования-и-развития/01-тест.md). | Активно. |\n"
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
        boxed_graph_markdown = root / BOXED_GRAPH_MARKDOWN
        boxed_graph_markdown.parent.mkdir(parents=True, exist_ok=True)
        boxed_graph_markdown.write_text(
            "# Граф зависимостей элементов коробочной реализации FUM\n\n"
            "Тестовая гипотеза порядка, не разрешающая начало коробочной стадии.\n",
            encoding="utf-8",
        )
        boxed_graph = {
            "schema": "fum.planning.boxed-implementation-dependency-graph.v1",
            "graph_id": "FUM-BOXED-IMPLEMENTATION-GRAPH",
            "source": {
                "path": BOXED_GRAPH_MARKDOWN.as_posix(),
                "content_sha256_without_recency": (
                    build_planning_registry.content_sha256(
                        BOXED_GRAPH_MARKDOWN,
                        root,
                    )
                ),
            },
            "scope": {
                "kind": "planning-hypothesis",
                "statement": "Машинная проекция проверяемого порядка реализации.",
                "excludes": [
                    "Разрешение начала коробочной стадии.",
                    "Разрешение внешних или физических действий.",
                ],
            },
            "readiness_rule": {
                "requires_all_dependencies_ready": True,
                "requires_all_readiness_prerequisites_met": True,
                "requires_all_blocking_risks_resolved": True,
                "requires_all_readiness_criteria_met": True,
            },
            "elements": [
                {
                    "id": "P0",
                    "order": 0,
                    "title": "Паспорт поставки",
                    "depends_on": [],
                    "readiness_prerequisites": ["Плановая стадия описана."],
                    "readiness_criteria": ["Паспорт принят."],
                },
                {
                    "id": "P1",
                    "order": 1,
                    "title": "Реестр происхождения",
                    "depends_on": ["P0"],
                    "readiness_prerequisites": ["Правила сессии определены."],
                    "readiness_criteria": ["Происхождение восстанавливается."],
                },
                {
                    "id": "P2",
                    "order": 2,
                    "title": "Контур сессии",
                    "depends_on": ["P0"],
                    "readiness_prerequisites": ["Реестр происхождения готов."],
                    "readiness_criteria": ["Сессия завершается проверяемо."],
                },
                *[
                    {
                        "id": f"P{index}",
                        "order": index,
                        "title": f"Тестовый элемент {index}",
                        "depends_on": ["P2"],
                        "readiness_prerequisites": ["Контур сессии готов."],
                        "readiness_criteria": ["Результат элемента проверен."],
                    }
                    for index in range(3, 17)
                ],
            ],
            "parallelizable_groups": [
                {
                    "id": "parallel-origin-and-session",
                    "element_ids": ["P1", "P2"],
                    "rationale": "После общего паспорта ветви не зависят друг от друга.",
                }
            ],
            "blocking_risks": [
                {
                    "id": "RISK-01",
                    "title": "Нет разрешения на коробочную стадию",
                    "description": "Плановый слой не является разрешением исполнения.",
                    "blocks_element_ids": ["P2"],
                    "resolution_criteria": ["Получен отдельный запрос пользователя."],
                    "source_paths": [BOXED_GRAPH_MARKDOWN.as_posix()],
                }
            ],
            "mvp_links": [
                {
                    "mvp_candidate_id": "mvp-01",
                    "mvp_path": "Планирование/MVP-кандидаты/01-тест/README.md",
                    "element_ids": ["P1"],
                    "role": "Проверяет реестр происхождения.",
                }
            ],
        }
        (root / BOXED_GRAPH_JSON).write_text(
            json.dumps(boxed_graph, ensure_ascii=False, indent=2) + "\n",
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
            self.assertEqual(registry["schema"], "fum.planning.requirements-registry.v9")
            self.assertEqual(
                registry["boxed_implementation_graph"]["schema"],
                "fum.planning.boxed-implementation-dependency-graph.v1",
            )
            self.assertEqual(
                [
                    element["id"]
                    for element in registry["boxed_implementation_graph"]["elements"]
                ],
                [f"P{index}" for index in range(17)],
            )
            self.assertEqual(registry["steps"][0]["id"], "FUM-STEP-0001")
            self.assertEqual(registry["steps"][0]["status"], "active")
            self.assertEqual(registry["steps"][0]["title"], "Подготовить тестовый реестр")
            self.assertEqual(registry["steps"][0]["task"], "Подготовить тестовый реестр.")
            self.assertEqual(registry["steps"][0]["why_now"], "Нужна проверка.")
            self.assertEqual(len(registry["steps"][0]["criteria"]), 2)
            self.assertIsNone(registry["steps"][0]["outcome"])
            self.assertEqual(registry["steps"][1]["status"], "completed")
            self.assertIsNone(registry["steps"][1]["why_now"])
            self.assertEqual(registry["steps"][1]["criteria"], [])
            self.assertEqual(registry["steps"][1]["outcome"], "Сделано.")
            self.assertEqual(
                [step["status"] for step in registry["steps"]],
                ["active", "completed", "absorbed", "withdrawn"],
            )
            self.assertEqual(
                [Path(step["file"]).name for step in registry["steps"]],
                [
                    ACTIVE_STEP_CARD,
                    COMPLETED_STEP_CARD,
                    ABSORBED_STEP_CARD,
                    WITHDRAWN_STEP_CARD,
                ],
            )
            self.assertEqual(
                [
                    цепочка["идентификатор"]
                    for цепочка in registry["цепочки_шагов"]
                ],
                ["FUM-ЦЕПОЧКА-0001", "FUM-ЦЕПОЧКА-0002"],
            )
            активная_цепочка = registry["цепочки_шагов"][0]
            self.assertEqual(
                set(активная_цепочка),
                {
                    "идентификатор",
                    "файл",
                    "заголовок",
                    "состояние",
                    "ветка",
                    "базовая_ветка",
                    "путь_проекта",
                    "карточки_шагов",
                },
            )
            self.assertEqual(активная_цепочка["состояние"], "активна")
            self.assertEqual(
                активная_цепочка["ветка"],
                "refs/heads/codex/test-chain",
            )
            self.assertEqual(
                активная_цепочка["базовая_ветка"],
                "refs/heads/master",
            )
            self.assertEqual(активная_цепочка["путь_проекта"], "README.md")
            self.assertEqual(
                активная_цепочка["карточки_шагов"],
                ["FUM-STEP-0001", "FUM-STEP-0002"],
            )
            self.assertEqual(
                registry["source_inventory"]["active_proposals"][0]["id"],
                "FUM-STEP-0001",
            )
            self.assertEqual(
                registry["source_inventory"]["proposal_history"][0]["id"],
                "FUM-STEP-0002",
            )
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
            self.assertIn("Планирование/предложения-о-следующих-шагах.md", source_paths)
            self.assertIn("Планирование/карточки-шагов/README.md", source_paths)
            self.assertIn(
                f"Планирование/карточки-шагов/{ACTIVE_STEP_CARD}",
                source_paths,
            )
            self.assertIn(
                "Планирование/карточки-цепочек-шагов/README.md",
                source_paths,
            )
            self.assertIn(
                "Планирование/карточки-цепочек-шагов/"
                f"{АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ}",
                source_paths,
            )
            self.assertIn(
                "Планирование/карточки-цепочек-шагов/"
                f"{ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ}",
                source_paths,
            )
            self.assertIn(BOXED_GRAPH_MARKDOWN.as_posix(), source_paths)
            self.assertIn(BOXED_GRAPH_JSON.as_posix(), source_paths)
            self.assertIn(
                "Планирование/следующие-шаги-веток/master.md",
                source_paths,
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
            self.assertEqual(
                registry["source_inventory"]["очередь_дорожной_карты"],
                [
                    {
                        "порядок_записи": 1,
                        "идентификатор_шага": "master-fum-step-0001-automatic-v1",
                        "карточка": "FUM-STEP-0001",
                        "файл": f"Планирование/карточки-шагов/{ACTIVE_STEP_CARD}",
                        "хэш_содержимого_карточки": (
                            build_planning_registry.content_sha256(
                                Path("Планирование")
                                / "карточки-шагов"
                                / ACTIVE_STEP_CARD,
                                root,
                            )
                        ),
                        "режим": "automatic",
                        "зависимости": [],
                        "стадии": ["stage-01"],
                        "горизонты": ["horizon-0"],
                        "плановый_горизонт": "готов сейчас",
                    }
                ],
            )
            self.assertEqual(
                registry["source_inventory"]["покрытие_дорожной_карты"][-1],
                {
                    "вид": "горизонт",
                    "идентификатор": "horizon-1",
                    "название": "Воспроизводимые автоматизации",
                    "файл": "Планирование/дорожная-карта.md#горизонт-1-воспроизводимые-автоматизации",
                    "карточки": [],
                },
            )

    def test_дорожная_карта_отклоняет_пропущенный_горизонт(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            карта = корень / "Планирование" / "дорожная-карта.md"
            текст = карта.read_text(encoding="utf-8")
            текст = "\n".join(
                строка
                for строка in текст.splitlines()
                if not строка.startswith("| [Горизонт 1]")
            ) + "\n"
            карта.write_text(текст, encoding="utf-8")

            with сам.assertRaisesRegex(ValueError, "roadmap coverage misses contours.*horizon-1"):
                build_planning_registry.build_registry(корень)

    def test_валидация_реестра_проверяет_проекции_дорожной_карты(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            реестр = build_planning_registry.build_registry(корень)
            очередь = реестр["source_inventory"]["очередь_дорожной_карты"]
            покрытие = реестр["source_inventory"]["покрытие_дорожной_карты"]
            очередь[0]["режим"] = "неизвестный"
            очередь[0]["лишнее"] = True
            очередь[0]["плановый_горизонт"] = []
            покрытие[0]["карточки"] = []

            ошибки = build_planning_registry.validate_registry_object(реестр)

            сам.assertIn(
                "roadmap queue object has unexpected fields",
                "\n".join(ошибки),
            )
            сам.assertIn(
                "invalid roadmap queue dispatch",
                "\n".join(ошибки),
            )
            сам.assertIn(
                "invalid roadmap queue planning horizon",
                "\n".join(ошибки),
            )
            сам.assertIn(
                "roadmap coverage cards do not match queue",
                "\n".join(ошибки),
            )

    def test_карта_стадий_отклоняет_несуществующую_точную_цель(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            карта_стадий = корень / "Планирование" / "стадии" / "README.md"
            карта_стадий.write_text(
                карта_стадий.read_text(encoding="utf-8").replace(
                    "01-тестовая-стадия/README.md",
                    "99-несуществующая-стадия/README.md",
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "planning stage link is not an exact stage README",
            ):
                build_planning_registry.build_registry(корень)

    def test_карта_стадий_требует_точный_заголовок_таблицы(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            карта_стадий = корень / "Планирование" / "стадии" / "README.md"
            карта_стадий.write_text(
                карта_стадий.read_text(encoding="utf-8").replace(
                    "| Стадия | Смысл |",
                    "| Этап | Смысл |",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "unexpected table header.*Карта стадий",
            ):
                build_planning_registry.build_registry(корень)

    def test_карта_стадий_отклоняет_символьный_псевдоним_цели(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            каталог_стадии = (
                корень / "Планирование" / "стадии" / "01-тестовая-стадия"
            )
            (каталог_стадии / "README-ссылка.md").symlink_to("README.md")
            карта_стадий = корень / "Планирование" / "стадии" / "README.md"
            карта_стадий.write_text(
                карта_стадий.read_text(encoding="utf-8").replace(
                    "01-тестовая-стадия/README.md",
                    "01-тестовая-стадия/README-ссылка.md",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "planning stage link is not lexically exact",
            ):
                build_planning_registry.build_registry(корень)

    def test_инвентарь_стадий_отклоняет_символьный_псевдоним_паспорта(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            каталог_стадий = корень / "Планирование" / "стадии"
            (каталог_стадий / "99-псевдоним").symlink_to(
                "01-тестовая-стадия",
                target_is_directory=True,
            )

            with сам.assertRaisesRegex(
                ValueError,
                "planning stage inventory path must not contain symbolic links",
            ):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_отклоняет_нестрогую_границу_метаданных(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    "+++\nschema_version",
                    "+++schema_version",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "master next-step set must start with TOML frontmatter",
            ):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_отклоняет_вещественную_версию_схемы(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    "schema_version = 5",
                    "schema_version = 5.0",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "master next-step set supports only schema_version = 5",
            ):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_отклоняет_нетекстовое_состояние(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    'state = "open"',
                    "state = []",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "master next-step set has invalid state or candidates",
            ):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_отклоняет_нетекстовый_режим(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    'dispatch = "automatic"',
                    "dispatch = []",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "invalid master next-step dispatch",
            ):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_отклоняет_нетекстовую_карточку(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    'card_id = "FUM-STEP-0001"',
                    "card_id = []",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "invalid master next-step card id",
            ):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_принимает_общий_устойчивый_идентификатор_шага(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    "master-fum-step-0001-automatic-v1",
                    "stable-step.id-v7",
                ),
                encoding="utf-8",
            )
            карта = корень / "Планирование" / "дорожная-карта.md"
            карта.write_text(
                карта.read_text(encoding="utf-8").replace(
                    "master-fum-step-0001-automatic-v1",
                    "stable-step.id-v7",
                ),
                encoding="utf-8",
            )
            реестр = build_planning_registry.build_registry(корень)

            сам.assertEqual(
                реестр["source_inventory"]["очередь_дорожной_карты"][0][
                    "идентификатор_шага"
                ],
                "stable-step.id-v7",
            )

    def test_дорожная_карта_отклоняет_несинхронную_перестановку_записей(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            имя_второй_карточки = (
                "🟡-FUM-STEP-0005-подготовить-второй-тестовый-реестр.md"
            )
            путь_второй_карточки = (
                корень
                / "Планирование"
                / "карточки-шагов"
                / имя_второй_карточки
            )
            путь_второй_карточки.write_text(
                "+++\n"
                "schema_version = 1\n"
                'card_id = "FUM-STEP-0005"\n'
                'status = "active"\n'
                "+++\n"
                "# Подготовить второй тестовый реестр\n\n"
                "Карточка сохраняет второй самостоятельный шаг.\n\n"
                "## Задача\n\n"
                "Подготовить второй тестовый реестр.\n\n"
                "## Почему сейчас\n\n"
                "Нужна проверка перестановки.\n\n"
                "## Критерии завершения\n\n"
                "- Реестр собирается.\n\n"
                "## Источники\n\n"
                "- [дорожная карта](../дорожная-карта.md)\n",
                encoding="utf-8",
            )
            индекс = корень / "Планирование" / "карточки-шагов" / "README.md"
            индекс.write_text(
                индекс.read_text(encoding="utf-8")
                + "| `FUM-STEP-0005` | 🟡 Актуально | "
                + f"[Подготовить второй тестовый реестр]({имя_второй_карточки}) |\n",
                encoding="utf-8",
            )
            хэш_первой_карточки = build_planning_registry.content_sha256(
                Path("Планирование") / "карточки-шагов" / ACTIVE_STEP_CARD,
                корень,
            )
            хэш_второй_карточки = build_planning_registry.content_sha256(
                Path("Планирование") / "карточки-шагов" / имя_второй_карточки,
                корень,
            )
            первая_запись = (
                "[[candidates]]\n"
                'step_id = "master-fum-step-0001-automatic-v1"\n'
                'dispatch = "automatic"\n'
                'card_id = "FUM-STEP-0001"\n'
                f'card_content_sha256 = "{хэш_первой_карточки}"\n'
                "requires_completed_card_ids = []\n"
            )
            вторая_запись = (
                "[[candidates]]\n"
                'step_id = "master-fum-step-0005-automatic-v1"\n'
                'dispatch = "automatic"\n'
                'card_id = "FUM-STEP-0005"\n'
                f'card_content_sha256 = "{хэш_второй_карточки}"\n'
                "requires_completed_card_ids = []\n"
            )
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    первая_запись + "+++\n",
                    первая_запись + "\n" + вторая_запись + "+++\n",
                ),
                encoding="utf-8",
            )
            карта = корень / "Планирование" / "дорожная-карта.md"
            ссылка_на_вторую = (
                f"[FUM-STEP-0005](карточки-шагов/{имя_второй_карточки})"
            )
            строка_первой_очереди = (
                "| 1 | master-fum-step-0001-automatic-v1 | "
                f"[FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}) | "
                "`automatic` | — | [01. Тестовая стадия]"
                "(стадии/01-тестовая-стадия/README.md) | `0` | готов сейчас |\n"
            )
            строка_второй_очереди = (
                "| 2 | master-fum-step-0005-automatic-v1 | "
                f"{ссылка_на_вторую} | `automatic` | — | "
                "[01. Тестовая стадия]"
                "(стадии/01-тестовая-стадия/README.md) | `0` | готов сейчас |\n"
            )
            карта.write_text(
                карта.read_text(encoding="utf-8")
                .replace(
                    строка_первой_очереди,
                    строка_первой_очереди + строка_второй_очереди,
                    1,
                )
                .replace(
                    f") | [FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}) |",
                    f") | [FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}), {ссылка_на_вторую} |",
                    1,
                )
                .replace(
                    f"| [Горизонт 0](#горизонт-0-связная-память-проекта) | [FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}) |",
                    f"| [Горизонт 0](#горизонт-0-связная-память-проекта) | [FUM-STEP-0001](карточки-шагов/{ACTIVE_STEP_CARD}), {ссылка_на_вторую} |",
                ),
                encoding="utf-8",
            )
            build_planning_registry.build_registry(корень)
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    первая_запись + "\n" + вторая_запись,
                    вторая_запись + "\n" + первая_запись,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "roadmap queue generation mismatch",
            ):
                build_planning_registry.build_registry(корень)

    def test_дорожная_карта_отклоняет_пропущенную_стадию(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            карта = корень / "Планирование" / "дорожная-карта.md"
            текст = карта.read_text(encoding="utf-8")
            текст = "\n".join(
                строка
                for строка in текст.splitlines()
                if not строка.startswith("| [01. Тестовая стадия]")
            ) + "\n"
            карта.write_text(текст, encoding="utf-8")

            with сам.assertRaisesRegex(
                ValueError,
                "roadmap coverage misses contours.*stage-01",
            ):
                build_planning_registry.build_registry(корень)

    def test_дорожная_карта_отклоняет_битую_карточку(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            карта = корень / "Планирование" / "дорожная-карта.md"
            карта.write_text(
                карта.read_text(encoding="utf-8").replace(
                    f"карточки-шагов/{ACTIVE_STEP_CARD}",
                    "карточки-шагов/несуществующая-карточка.md",
                    1,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(ValueError, "roadmap queue card path mismatch"):
                build_planning_registry.build_registry(корень)

    def test_дорожная_карта_отклоняет_смену_режима_без_синхронизации(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8")
                .replace(
                    'step_id = "master-fum-step-0001-automatic-v1"',
                    'step_id = "master-fum-step-0001-paused-v2"',
                )
                .replace(
                    'dispatch = "automatic"',
                    'dispatch = "paused"\nresume_condition = "До повторной аттестации."',
                ),
                encoding="utf-8",
            )
            карта = корень / "Планирование" / "дорожная-карта.md"
            карта.write_text(
                карта.read_text(encoding="utf-8").replace(
                    "master-fum-step-0001-automatic-v1",
                    "master-fum-step-0001-paused-v2",
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(ValueError, "roadmap queue dispatch mismatch"):
                build_planning_registry.build_registry(корень)

    def test_дорожная_карта_отклоняет_смену_поколения_без_синхронизации(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    "master-fum-step-0001-automatic-v1",
                    "master-fum-step-0001-automatic-v2",
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(ValueError, "roadmap queue generation mismatch"):
                build_planning_registry.build_registry(корень)

    def test_дорожная_карта_отклоняет_смену_зависимостей_без_синхронизации(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    "requires_completed_card_ids = []",
                    'requires_completed_card_ids = ["FUM-STEP-0002"]',
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(ValueError, "roadmap queue dependencies mismatch"):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_отклоняет_цикл_зависимостей(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8").replace(
                    "requires_completed_card_ids = []",
                    'requires_completed_card_ids = ["FUM-STEP-0001"]',
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "master next-step dependencies contain cycle",
            ):
                build_planning_registry.build_registry(корень)

    def test_дорожная_карта_отклоняет_пропущенного_кандидата(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            карта = корень / "Планирование" / "дорожная-карта.md"
            текст = карта.read_text(encoding="utf-8")
            текст = "\n".join(
                строка
                for строка in текст.splitlines()
                if not строка.startswith(
                    "| 1 | master-fum-step-0001-automatic-v1 |"
                )
            ) + "\n"
            карта.write_text(текст, encoding="utf-8")

            with сам.assertRaisesRegex(
                ValueError,
                "roadmap queue does not exactly cover master candidates",
            ):
                build_planning_registry.build_registry(корень)

    def test_рабочий_набор_отклоняет_снятую_карточку(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            снятая_карточка = (
                Path("Планирование")
                / "карточки-шагов"
                / WITHDRAWN_STEP_CARD
            )
            хэш_снятой_карточки = build_planning_registry.content_sha256(
                снятая_карточка,
                корень,
            )
            набор = корень / "Планирование" / "следующие-шаги-веток" / "master.md"
            набор.write_text(
                набор.read_text(encoding="utf-8")
                .replace("FUM-STEP-0001", "FUM-STEP-0004")
                .replace(
                    build_planning_registry.content_sha256(
                        Path("Планирование")
                        / "карточки-шагов"
                        / ACTIVE_STEP_CARD,
                        корень,
                    ),
                    хэш_снятой_карточки,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "master next-step candidate references non-active card.*FUM-STEP-0004",
            ):
                build_planning_registry.build_registry(корень)

    def test_дорожная_карта_отклоняет_отсутствующий_плановый_горизонт(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_fixture(корень)
            карта = корень / "Планирование" / "дорожная-карта.md"
            карта.write_text(
                карта.read_text(encoding="utf-8").replace(
                    "| `0` | готов сейчас |",
                    "| `0` |  |",
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(ValueError, "roadmap queue planning horizon mismatch"):
                build_planning_registry.build_registry(корень)

    def test_реестр_отклоняет_повтор_шага_в_неотозванных_цепочках(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            выход = сам.write_fixture(корень)
            каталог = корень / "Планирование" / "карточки-цепочек-шагов"
            карточка = каталог / ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ
            карточка.write_text(
                карточка.read_text(encoding="utf-8").replace(
                    '"состояние" = "отозвана"',
                    '"состояние" = "активна"',
                ),
                encoding="utf-8",
            )
            активированное_имя = ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ.replace(
                "🗑️-",
                "🚧-",
            )
            карточка.rename(каталог / активированное_имя)
            индекс = каталог / "README.md"
            индекс.write_text(
                индекс.read_text(encoding="utf-8")
                .replace(
                    "| `FUM-ЦЕПОЧКА-0002` | 🗑️ Отозвана |",
                    "| `FUM-ЦЕПОЧКА-0002` | 🚧 Активна |",
                )
                .replace(
                    ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ,
                    активированное_имя,
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "duplicate step chain membership.*FUM-STEP-0001",
            ):
                build_planning_registry.build_to_file(выход, корень)

    def test_реестр_отклоняет_тег_или_ветку_вне_целевого_пространства(сам):
        случаи = (
            "refs/tags/test-chain",
            "refs/heads/feature/test-chain",
            "refs/heads/codex/bad..chain",
            "refs/heads/codex/bad@{chain",
            "refs/heads/codex/bad chain",
            "refs/heads/codex/bad\\chain",
            "refs/heads/codex/trailing.",
            "refs/heads/codex/trailing/",
        )
        for неверная_ветка in случаи:
            with сам.subTest(ветка=неверная_ветка):
                временный_каталог = tempfile.TemporaryDirectory()
                сам.addCleanup(временный_каталог.cleanup)
                корень = Path(временный_каталог.name)
                выход = сам.write_fixture(корень)
                каталог = корень / "Планирование" / "карточки-цепочек-шагов"
                карточка = каталог / АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ
                ветка_в_метаданных = неверная_ветка.replace("\\", "\\\\")
                карточка.write_text(
                    карточка.read_text(encoding="utf-8").replace(
                        "refs/heads/codex/test-chain",
                        ветка_в_метаданных,
                    ),
                    encoding="utf-8",
                )
                индекс = каталог / "README.md"
                индекс.write_text(
                    индекс.read_text(encoding="utf-8").replace(
                        "refs/heads/codex/test-chain",
                        неверная_ветка,
                    ),
                    encoding="utf-8",
                )

                with сам.assertRaisesRegex(
                    ValueError,
                    r"step chain branch.*refs/heads/codex/",
                ):
                    build_planning_registry.build_to_file(выход, корень)

    def test_реестр_отклоняет_неизвестную_карточку_шага_цепочки(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            выход = сам.write_fixture(корень)
            карточка = (
                корень
                / "Планирование"
                / "карточки-цепочек-шагов"
                / АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ
            )
            карточка.write_text(
                карточка.read_text(encoding="utf-8").replace(
                    "FUM-STEP-0002",
                    "FUM-STEP-9999",
                ),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "unknown step card FUM-STEP-9999",
            ):
                build_planning_registry.build_to_file(выход, корень)

    def test_реестр_требует_точное_покрытие_индекса_цепочек(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            выход = сам.write_fixture(корень)
            индекс = (
                корень
                / "Планирование"
                / "карточки-цепочек-шагов"
                / "README.md"
            )
            строки = индекс.read_text(encoding="utf-8").splitlines()
            индекс.write_text(
                "\n".join(
                    строка
                    for строка in строки
                    if "FUM-ЦЕПОЧКА-0002" not in строка
                )
                + "\n",
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "step chain index does not exactly cover cards",
            ):
                build_planning_registry.build_to_file(выход, корень)

    def test_реестр_требует_ровно_одну_активную_цепочку(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            выход = сам.write_fixture(корень)
            каталог = корень / "Планирование" / "карточки-цепочек-шагов"
            карточка = каталог / АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ
            запланированное_имя = АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ.replace(
                "🚧-",
                "🟡-",
            )
            карточка.write_text(
                карточка.read_text(encoding="utf-8").replace(
                    '"состояние" = "активна"',
                    '"состояние" = "запланирована"',
                ),
                encoding="utf-8",
            )
            карточка.rename(каталог / запланированное_имя)
            индекс = каталог / "README.md"
            индекс.write_text(
                индекс.read_text(encoding="utf-8")
                .replace("🚧 Активна", "🟡 Запланирована", 1)
                .replace(АКТИВНАЯ_КАРТОЧКА_ЦЕПОЧКИ, запланированное_имя),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "registry must contain exactly one active step chain",
            ):
                build_planning_registry.build_to_file(выход, корень)

        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            выход = сам.write_fixture(корень)
            каталог = корень / "Планирование" / "карточки-цепочек-шагов"
            карточка = каталог / ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ
            активированное_имя = ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ.replace(
                "🗑️-",
                "🚧-",
            )
            карточка.write_text(
                карточка.read_text(encoding="utf-8")
                .replace(
                    '"состояние" = "отозвана"',
                    '"состояние" = "активна"',
                )
                .replace("FUM-STEP-0001", "FUM-STEP-0003"),
                encoding="utf-8",
            )
            карточка.rename(каталог / активированное_имя)
            индекс = каталог / "README.md"
            индекс.write_text(
                индекс.read_text(encoding="utf-8")
                .replace("🗑️ Отозвана", "🚧 Активна")
                .replace(ОТОЗВАННАЯ_КАРТОЧКА_ЦЕПОЧКИ, активированное_имя),
                encoding="utf-8",
            )

            with сам.assertRaisesRegex(
                ValueError,
                "registry must contain exactly one active step chain",
            ):
                build_planning_registry.build_to_file(выход, корень)

    def test_build_rejects_boxed_graph_with_unknown_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            graph = json.loads(graph_path.read_text(encoding="utf-8"))
            graph["elements"][1]["depends_on"] = ["P99"]
            graph_path.write_text(
                json.dumps(graph, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "unknown dependency P99"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_boxed_graph_missing_expected_element(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            graph = json.loads(graph_path.read_text(encoding="utf-8"))
            graph["elements"].pop()
            graph_path.write_text(
                json.dumps(graph, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "exactly match P0 through P16"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_boxed_graph_cycle(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            graph = json.loads(graph_path.read_text(encoding="utf-8"))
            graph["elements"][0]["depends_on"] = ["P1"]
            graph_path.write_text(
                json.dumps(graph, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "dependency cycle"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_dependent_elements_in_parallelizable_group(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            graph = json.loads(graph_path.read_text(encoding="utf-8"))
            graph["parallelizable_groups"][0]["element_ids"] = ["P0", "P1"]
            graph_path.write_text(
                json.dumps(graph, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                ValueError,
                "parallelizable group contains dependent elements",
            ):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_boxed_graph_with_unknown_mvp_candidate(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            graph = json.loads(graph_path.read_text(encoding="utf-8"))
            graph["mvp_links"][0]["mvp_candidate_id"] = "mvp-99"
            graph_path.write_text(
                json.dumps(graph, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "unknown MVP candidate mvp-99"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_stale_boxed_graph_source_hash(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            graph_source = root / BOXED_GRAPH_MARKDOWN
            graph_source.write_text(
                graph_source.read_text(encoding="utf-8") + "Уточнение.\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "source hash does not match"):
                build_planning_registry.build_to_file(output, root)

    def test_sync_boxed_graph_source_hash_is_atomic_and_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            graph_source = root / BOXED_GRAPH_MARKDOWN
            graph_before = json.loads(graph_path.read_text(encoding="utf-8"))
            graph_source.write_text(
                graph_source.read_text(encoding="utf-8") + "Уточнение.\n",
                encoding="utf-8",
            )
            expected_hash = build_planning_registry.content_sha256(
                BOXED_GRAPH_MARKDOWN,
                root,
            )
            replace_calls: list[tuple[Path, Path]] = []
            real_replace = os.replace

            def recording_replace(source, destination):
                replace_calls.append((Path(source), Path(destination)))
                real_replace(source, destination)

            with mock.patch.object(
                build_planning_registry.os,
                "replace",
                side_effect=recording_replace,
            ):
                changed = build_planning_registry.sync_boxed_graph_source_hash(root)

            graph_after = json.loads(graph_path.read_text(encoding="utf-8"))
            graph_before["source"]["content_sha256_without_recency"] = expected_hash
            self.assertTrue(changed)
            self.assertEqual(graph_after, graph_before)
            self.assertEqual(len(replace_calls), 1)
            self.assertEqual(replace_calls[0][0].parent, graph_path.parent.resolve())
            self.assertEqual(replace_calls[0][1], graph_path.resolve())

            bytes_after_first_sync = graph_path.read_bytes()
            with mock.patch.object(build_planning_registry.os, "replace") as replace:
                changed_again = build_planning_registry.sync_boxed_graph_source_hash(root)

            self.assertFalse(changed_again)
            self.assertEqual(graph_path.read_bytes(), bytes_after_first_sync)
            replace.assert_not_called()

    def test_sync_boxed_graph_source_hash_rejects_invalid_input_before_write(self):
        cases = [
            (
                "malformed JSON",
                lambda graph: "{\n",
                "not valid JSON",
            ),
            (
                "wrong schema",
                lambda graph: {
                    **graph,
                    "schema": "fum.planning.boxed-implementation-dependency-graph.v0",
                },
                "unexpected boxed implementation graph schema",
            ),
            (
                "wrong source path",
                lambda graph: {
                    **graph,
                    "source": {
                        **graph["source"],
                        "path": "../вне-репозитория.md",
                    },
                },
                "source path must be",
            ),
            (
                "malformed source hash",
                lambda graph: {
                    **graph,
                    "source": {
                        **graph["source"],
                        "content_sha256_without_recency": "broken",
                    },
                },
                "source hash is malformed",
            ),
            (
                "malformed source object",
                lambda graph: {
                    **graph,
                    "source": {
                        **graph["source"],
                        "unexpected": True,
                    },
                },
                "source has unknown fields",
            ),
        ]
        for label, mutate, error_pattern in cases:
            with self.subTest(label=label), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                self.write_fixture(root)
                graph_path = root / BOXED_GRAPH_JSON
                graph = json.loads(graph_path.read_text(encoding="utf-8"))
                mutated = mutate(graph)
                if isinstance(mutated, str):
                    graph_path.write_text(mutated, encoding="utf-8")
                else:
                    graph_path.write_text(
                        json.dumps(mutated, ensure_ascii=False, indent=2) + "\n",
                        encoding="utf-8",
                    )
                bytes_before = graph_path.read_bytes()

                with self.assertRaisesRegex(ValueError, error_pattern):
                    build_planning_registry.sync_boxed_graph_source_hash(root)

                self.assertEqual(graph_path.read_bytes(), bytes_before)

    def test_sync_boxed_graph_source_hash_rejects_missing_markdown_before_write(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            bytes_before = graph_path.read_bytes()
            (root / BOXED_GRAPH_MARKDOWN).unlink()

            with self.assertRaisesRegex(ValueError, "Markdown source does not exist"):
                build_planning_registry.sync_boxed_graph_source_hash(root)

            self.assertEqual(graph_path.read_bytes(), bytes_before)

    def test_sync_boxed_graph_source_hash_rolls_back_atomic_replace_failure(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            graph_path = root / BOXED_GRAPH_JSON
            graph_source = root / BOXED_GRAPH_MARKDOWN
            graph_source.write_text(
                graph_source.read_text(encoding="utf-8") + "Уточнение.\n",
                encoding="utf-8",
            )
            bytes_before = graph_path.read_bytes()
            directory_before = set(graph_path.parent.iterdir())

            with mock.patch.object(
                build_planning_registry.os,
                "replace",
                side_effect=OSError("replace failed"),
            ):
                with self.assertRaisesRegex(OSError, "replace failed"):
                    build_planning_registry.sync_boxed_graph_source_hash(root)

            self.assertEqual(graph_path.read_bytes(), bytes_before)
            self.assertEqual(set(graph_path.parent.iterdir()), directory_before)

    def test_sync_boxed_graph_source_hash_command(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            graph_source = root / BOXED_GRAPH_MARKDOWN
            graph_source.write_text(
                graph_source.read_text(encoding="utf-8") + "Уточнение.\n",
                encoding="utf-8",
            )

            with mock.patch.object(
                sys,
                "argv",
                [
                    str(SCRIPT_PATH),
                    "sync-boxed-graph-source-hash",
                    "--repo-root",
                    str(root),
                ],
            ):
                result = build_planning_registry.main()

            self.assertEqual(result, 0)
            graph = json.loads((root / BOXED_GRAPH_JSON).read_text(encoding="utf-8"))
            self.assertEqual(
                graph["source"]["content_sha256_without_recency"],
                build_planning_registry.content_sha256(BOXED_GRAPH_MARKDOWN, root),
            )

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

    def test_build_rejects_invalid_duplicate_or_non_exact_step_card_identity(self):
        mutations = {
            "invalid_id": (
                "FUM-STEP-0001",
                "STEP-0001",
                "invalid step card id",
            ),
            "duplicate_id": (
                "FUM-STEP-0002",
                "FUM-STEP-0001",
                "duplicate step card id",
            ),
            "unknown_toml_field": (
                'status = "active"',
                'status = "active"\npriority = 1',
                "unknown step card TOML fields",
            ),
        }
        for name, (old, new, error) in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                card_name = (
                    COMPLETED_STEP_CARD
                    if name == "duplicate_id"
                    else ACTIVE_STEP_CARD
                )
                if name == "duplicate_id":
                    card_name = COMPLETED_STEP_CARD.replace(
                        "FUM-STEP-0002",
                        "FUM-STEP-0001",
                    )
                    self.rename_step_card(
                        root,
                        COMPLETED_STEP_CARD,
                        card_name,
                    )
                card = root / "Планирование" / "карточки-шагов" / card_name
                card.write_text(
                    card.read_text(encoding="utf-8").replace(old, new),
                    encoding="utf-8",
                )

                with self.assertRaisesRegex(ValueError, error):
                    build_planning_registry.build_to_file(output, root)

    def test_build_rejects_noncanonical_step_card_filenames(self):
        cases = (
            (
                "legacy_name",
                "FUM-STEP-0001-подготовить-тестовый-реестр.md",
                "step card filename",
            ),
            (
                "unknown_emoji",
                "❌-FUM-STEP-0001-подготовить-тестовый-реестр.md",
                "step card filename",
            ),
            (
                "empty_description",
                "🟡-FUM-STEP-0001-.md",
                "description",
            ),
            (
                "id_mismatch",
                "🟡-FUM-STEP-0099-подготовить-тестовый-реестр.md",
                "filename id does not match",
            ),
            (
                "status_mismatch",
                "✅-FUM-STEP-0001-подготовить-тестовый-реестр.md",
                "filename status does not match",
            ),
            (
                "double_hyphen",
                "🟡-FUM-STEP-0001-подготовить--тестовый-реестр.md",
                "description",
            ),
            (
                "underscore",
                "🟡-FUM-STEP-0001-подготовить_тестовый-реестр.md",
                "description",
            ),
            (
                "punctuation",
                "🟡-FUM-STEP-0001-подготовить-тестовый-реестр!.md",
                "description",
            ),
        )
        for name, filename, error in cases:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                self.rename_step_card(root, ACTIVE_STEP_CARD, filename)

                with self.assertRaisesRegex(ValueError, error):
                    build_planning_registry.build_to_file(output, root)

    def test_step_card_filename_rejects_more_than_255_utf8_bytes(self):
        filename = f"🟡-FUM-STEP-0001-{'я' * 117}.md"
        self.assertGreater(len(filename.encode("utf-8")), 255)

        with self.assertRaisesRegex(ValueError, "255 UTF-8 bytes"):
            build_planning_registry.step_card_filename_metadata(Path(filename))

    def test_step_card_filename_accepts_exactly_255_utf8_bytes(self):
        prefix = "🟡-FUM-STEP-0001-"
        suffix = ".md"
        description_length = 255 - len((prefix + suffix).encode("utf-8"))
        filename = f"{prefix}{'A' * description_length}{suffix}"
        self.assertEqual(len(filename.encode("utf-8")), 255)

        filename_id, filename_status, description = (
            build_planning_registry.step_card_filename_metadata(Path(filename))
        )

        self.assertEqual(filename_id, "FUM-STEP-0001")
        self.assertEqual(filename_status, "active")
        self.assertEqual(description, "A" * description_length)

    def test_build_rejects_foreign_markdown_in_step_cards_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = self.write_fixture(root)
            cards = root / "Планирование" / "карточки-шагов"
            (cards / "заметки.md").write_text(
                "# Посторонний документ\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "step card filename"):
                build_planning_registry.build_to_file(output, root)

    def test_build_rejects_nested_or_noncanonical_markdown_inventory(self):
        cases = (
            (
                "nested_markdown",
                "черновики/заметки.md",
                "step cards directory must be flat",
            ),
            (
                "nested_uppercase_extension",
                "черновики/заметки.MD",
                "step cards directory must be flat",
            ),
            (
                "nested_readme",
                "черновики/README.md",
                "step cards directory must be flat",
            ),
            (
                "root_lowercase_readme",
                "readme.md",
                r"step card (?:filename|index)",
            ),
            (
                "root_uppercase_extension",
                "заметки.MD",
                "step card filename",
            ),
        )
        for name, relative_path, error in cases:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                foreign = (
                    root
                    / "Планирование"
                    / "карточки-шагов"
                    / relative_path
                )
                foreign.parent.mkdir(parents=True, exist_ok=True)
                foreign.write_text("# Посторонний Markdown\n", encoding="utf-8")

                with self.assertRaisesRegex(ValueError, error):
                    build_planning_registry.build_to_file(output, root)

    def test_step_card_description_can_change_without_changing_identity(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            renamed = (
                "🟡-FUM-STEP-0001-собрать-SwiftPM-2.md"
            )
            self.rename_step_card(root, ACTIVE_STEP_CARD, renamed)
            карта = root / "Планирование" / "дорожная-карта.md"
            карта.write_text(
                карта.read_text(encoding="utf-8").replace(
                    ACTIVE_STEP_CARD,
                    renamed,
                ),
                encoding="utf-8",
            )

            registry = build_planning_registry.build_registry(root)

            self.assertEqual(registry["steps"][0]["id"], "FUM-STEP-0001")
            self.assertEqual(registry["steps"][0]["status"], "active")
            self.assertEqual(Path(registry["steps"][0]["file"]).name, renamed)

    def test_registry_validation_cross_checks_step_file_identity(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            registry = build_planning_registry.build_registry(root)
            registry["steps"][0]["file"] = (
                "Планирование/карточки-шагов/"
                "✅-FUM-STEP-0099-другая-карточка.md"
            )

            errors = build_planning_registry.validate_registry_object(registry)

            self.assertIn("step card file id does not match", "\n".join(errors))
            self.assertIn("step card file status does not match", "\n".join(errors))

    def test_build_requires_complete_exact_step_card_index(self):
        mutations = {
            "unindexed_card": (
                f"| `FUM-STEP-0002` | ✅ Выполнено | [Старое предложение]({COMPLETED_STEP_CARD}) |\n",
                "",
                "step card index does not exactly cover cards",
            ),
            "status_mismatch": (
                "| `FUM-STEP-0001` | 🟡 Актуально |",
                "| `FUM-STEP-0001` | ✅ Выполнено |",
                "step card index status mismatch",
            ),
            "title_mismatch": (
                f"[Подготовить тестовый реестр]({ACTIVE_STEP_CARD})",
                f"[Другое название]({ACTIVE_STEP_CARD})",
                "step card index link label mismatch",
            ),
            "missing_link": (
                f"[Подготовить тестовый реестр]({ACTIVE_STEP_CARD})",
                "Подготовить тестовый реестр",
                "must link exactly one step card",
            ),
        }
        for name, (old, new, error) in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                index = root / "Планирование" / "карточки-шагов" / "README.md"
                index.write_text(
                    index.read_text(encoding="utf-8").replace(old, new),
                    encoding="utf-8",
                )

                with self.assertRaisesRegex(ValueError, error):
                    build_planning_registry.build_to_file(output, root)

    def test_build_enforces_status_specific_step_card_sections_and_links(self):
        mutations = {
            "active_why_now": (
                ACTIVE_STEP_CARD,
                "## Почему сейчас",
                "## Удалённый раздел",
                "missing required section Почему сейчас",
            ),
            "active_list_criteria": (
                ACTIVE_STEP_CARD,
                "- Реестр собирается.\n- Проверка реестра проходит.",
                "Реестр собирается.",
                "malformed Markdown list",
            ),
            "historical_outcome": (
                COMPLETED_STEP_CARD,
                "## Результат",
                "## Удалённый раздел",
                "missing required section Результат",
            ),
            "source_link": (
                ACTIVE_STEP_CARD,
                "- [дорожная карта](../дорожная-карта.md)",
                "- дорожная карта",
                "step card sources must contain at least one link",
            ),
        }
        for name, (filename, old, new, error) in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = self.write_fixture(root)
                card = root / "Планирование" / "карточки-шагов" / filename
                card.write_text(
                    card.read_text(encoding="utf-8").replace(old, new),
                    encoding="utf-8",
                )

                with self.assertRaisesRegex(ValueError, error):
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

            card = (
                root
                / "Планирование"
                / "карточки-шагов"
                / ACTIVE_STEP_CARD
            )
            card.write_text(
                card.read_text(encoding="utf-8").replace(
                    "Подготовить тестовый реестр.",
                    "Подготовить изменённый тестовый реестр.",
                ),
                encoding="utf-8",
            )

            errors = build_planning_registry.validate_file(output, root)

            self.assertIn("registry is stale", "\n".join(errors))


if __name__ == "__main__":
    unittest.main()
