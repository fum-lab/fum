import json
import tempfile
import unittest
from pathlib import Path

import test_build_planning_registry as исходные_проверки


class ПроверкиОтсутствияСемантическихСвязей(unittest.TestCase):
    def создать_фикстуру(сам, корень: Path) -> Path:
        return исходные_проверки.BuildPlanningRegistryTests().write_fixture(корень)

    def заменить_раздел(сам, карточка: Path, тело: str | None) -> None:
        текст = карточка.read_text(encoding="utf-8")
        начало = текст.index("## Семантические связи\n")
        конец = текст.index("## Критерии проверки\n", начало)
        вставка = "" if тело is None else "## Семантические связи\n\n" + тело + "\n\n"
        карточка.write_text(текст[:начало] + вставка + текст[конец:], encoding="utf-8")

    def test_явный_маркер_даёт_пустой_граф_при_сборке_и_валидации(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            выход = сам.создать_фикстуру(корень)
            for имя in ("🟡-сохранять-трассу.md", "🚧-проверять-трассу.md"):
                сам.заменить_раздел(
                    корень / "Требования" / имя,
                    "Прямые семантические связи пока не установлены.",
                )
            исходные_проверки.build_planning_registry.build_to_file(выход, корень)
            реестр = json.loads(выход.read_text(encoding="utf-8"))
            сам.assertEqual(реестр["schema"], "fum.planning.requirements-registry.v9")
            сам.assertEqual(
                [(карточка["id"], карточка["semantic_relations"]) for карточка in реестр["requirements"]],
                [("FUM-REQ-0001", []), ("FUM-REQ-0002", [])],
            )
            сам.assertEqual(
                исходные_проверки.build_planning_registry.validate_file(выход, корень),
                [],
            )

    def test_внешние_пробелы_не_меняют_явный_маркер(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            сам.создать_фикстуру(корень)
            for имя in ("🟡-сохранять-трассу.md", "🚧-проверять-трассу.md"):
                сам.заменить_раздел(
                    корень / "Требования" / имя,
                    "  \n  Прямые семантические связи пока не установлены.  \n\t",
                )
            карточки = исходные_проверки.build_planning_registry.extract_requirement_cards(корень)
            сам.assertEqual([карточка["semantic_relations"] for карточка in карточки], [[], []])

    def test_пустой_и_пропущенный_раздел_по_прежнему_запрещены(сам):
        for тело in (None, "", " \n\t"):
            with сам.subTest(тело=тело), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                сам.создать_фикстуру(корень)
                сам.заменить_раздел(корень / "Требования" / "🟡-сохранять-трассу.md", тело)
                with сам.assertRaisesRegex(ValueError, "missing required section Семантические связи"):
                    исходные_проверки.build_planning_registry.extract_requirement_cards(корень)

    def test_неточный_повторный_или_смешанный_маркер_запрещён(сам):
        маркер = "Прямые семантические связи пока не установлены."
        связь = "- **зависит от:** [проверки трассы](🚧-проверять-трассу.md) — проверяет результат."
        варианты = (
            "Прямые межкарточные зависимости пока не установлены.",
            "Прямые семантические связи пока не установлены",
            "прямые семантические связи пока не установлены.",
            "Прямые  семантические связи пока не установлены.",
            "- " + маркер,
            "<!-- " + маркер + " -->",
            маркер + "\n" + маркер,
            маркер + "\n" + связь,
            связь + "\n" + маркер,
            маркер + "\nДополнительное пояснение.",
        )
        for тело in варианты:
            with сам.subTest(тело=тело), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                сам.создать_фикстуру(корень)
                сам.заменить_раздел(корень / "Требования" / "🟡-сохранять-трассу.md", тело)
                with сам.assertRaisesRegex(ValueError, "malformed semantic relation"):
                    исходные_проверки.build_planning_registry.extract_requirement_cards(корень)

    def test_маркер_не_скрывает_входящую_связь_без_обратной(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            сам.создать_фикстуру(корень)
            сам.заменить_раздел(
                корень / "Требования" / "🚧-проверять-трассу.md",
                "Прямые семантические связи пока не установлены.",
            )
            with сам.assertRaisesRegex(ValueError, "missing inverse semantic relation"):
                исходные_проверки.build_planning_registry.extract_requirement_cards(корень)

    def test_настоящие_связи_сохраняют_строгие_проверки(сам):
        связь = "- **зависит от:** [проверки трассы](🚧-проверять-трассу.md) — проверяет результат."
        варианты = (
            (связь.replace("**зависит от:**", "**неизвестно:**"), "unknown semantic relation type"),
            (связь + "\n" + связь, "duplicate semantic relation"),
            (связь.replace("🚧-проверять-трассу.md", "🟡-неизвестная-карточка.md"), "semantic relation target is not an indexed requirement card"),
            (связь.replace("**зависит от:**", "**дополняет:**"), "missing inverse semantic relation"),
        )
        for тело, ошибка in варианты:
            with сам.subTest(ошибка=ошибка), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                сам.создать_фикстуру(корень)
                сам.заменить_раздел(корень / "Требования" / "🟡-сохранять-трассу.md", тело)
                with сам.assertRaisesRegex(ValueError, ошибка):
                    исходные_проверки.build_planning_registry.extract_requirement_cards(корень)


if __name__ == "__main__":
    unittest.main()
