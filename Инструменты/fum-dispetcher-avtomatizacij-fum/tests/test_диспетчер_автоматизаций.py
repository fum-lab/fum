from __future__ import annotations

import ast
import hashlib
import json
import re
import subprocess
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path


КОРЕНЬ_АВТОМАТИЗАЦИИ = Path(__file__).resolve().parents[1]
КОРЕНЬ_РЕПОЗИТОРИЯ = КОРЕНЬ_АВТОМАТИЗАЦИИ.parents[1]
СЦЕНАРИЙ = (
    КОРЕНЬ_АВТОМАТИЗАЦИИ
    / "scripts"
    / "диспетчер-автоматизаций.py"
)
СХЕМА = (
    КОРЕНЬ_АВТОМАТИЗАЦИИ
    / "схемы"
    / "реестр-заданий-v1.schema.json"
)
ПРОБНИК = КОРЕНЬ_АВТОМАТИЗАЦИИ / "scripts" / "пробник.sh"
ФИКСТУРЫ = Path(__file__).resolve().parent / "фикстуры"
КОРРЕКТНЫЙ_РЕЕСТР = ФИКСТУРЫ / "корректный-реестр.json"
НАБЛЮДЕНИЯ = ФИКСТУРЫ / "наблюдения-готовы.json"
НЕВАЛИДНЫЕ_СЛУЧАИ = ФИКСТУРЫ / "невалидные-случаи.json"
ПОВТОР_КЛЮЧА = ФИКСТУРЫ / "повтор-ключа.json"
КАНОНИЧЕСКИЙ_РЕЕСТР = (
    КОРЕНЬ_РЕПОЗИТОРИЯ
    / "Планирование"
    / "реестры-заданий-автоматизаций"
    / "master.json"
)


class КонтрактДиспетчераАвтоматизаций(unittest.TestCase):
    def выполнить(сам, *аргументы: str) -> subprocess.CompletedProcess[str]:
        return сам.выполнить_с_корнем(КОРЕНЬ_РЕПОЗИТОРИЯ, *аргументы)

    def выполнить_с_корнем(
        сам,
        корень: Path,
        *аргументы: str,
    ) -> subprocess.CompletedProcess[str]:
        команда, *остаток = аргументы
        return subprocess.run(
            [
                sys.executable,
                str(СЦЕНАРИЙ),
                команда,
                "--корень-рабочей-копии",
                str(корень),
                *остаток,
            ],
            cwd=КОРЕНЬ_РЕПОЗИТОРИЯ,
            check=False,
            capture_output=True,
            text=True,
        )

    def test_корректный_реестр_проходит_закрытую_схему(сам) -> None:
        результат = сам.выполнить(
            "проверить",
            "--реестр",
            str(КОРРЕКТНЫЙ_РЕЕСТР),
            "--схема",
            str(СХЕМА),
            "--json",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        ответ = json.loads(результат.stdout)
        сам.assertEqual(
            ответ,
            {
                "идентификатор_реестра": "fum.master.contract-fixture",
                "поколение_реестра": 1,
                "состояние": "корректен",
                "версия_схемы": 1,
                "число_заданий": 5,
            },
        )

    def test_канонический_реестр_содержит_два_активных_адаптера(сам) -> None:
        результат = сам.выполнить(
            "проверить",
            "--реестр",
            str(КАНОНИЧЕСКИЙ_РЕЕСТР),
            "--схема",
            str(СХЕМА),
            "--json",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        ответ = json.loads(результат.stdout)
        сам.assertEqual(ответ["число_заданий"], 2)
        сам.assertEqual(ответ["поколение_реестра"], 3)
        реестр = json.loads(
            КАНОНИЧЕСКИЙ_РЕЕСТР.read_text(encoding="utf-8")
        )
        аналитика = next(
            задание
            for задание in реестр["задания"]
            if задание["job_id"] == "master.completed-step-analysis"
        )
        сам.assertEqual(
            аналитика["адаптер"],
            {
                "тип": "аналитика_завершённых_шагов",
                "контракт": "fum-analitika-zavershyonnyikh-shagov.1",
            },
        )
        сам.assertGreater(аналитика["триггер"]["каждые"], 0)
        курсор = аналитика["курсор_результата"]
        сам.assertEqual(курсор["начальная_граница"]["минимальная_версия_claim"], 5)
        сам.assertEqual(курсор["область_анализа"]["job_id"], "master.next-step")
        сам.assertIsNone(
            курсор["последний_подтверждённый_аналитический_результат"]
        )

    def test_проверка_может_успешно_молчать(сам) -> None:
        результат = сам.выполнить(
            "проверить",
            "--реестр",
            str(КАНОНИЧЕСКИЙ_РЕЕСТР),
            "--схема",
            str(СХЕМА),
            "--без-вывода",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(результат.stdout, "")

    def test_схема_закрывает_каждый_объект_реестра(сам) -> None:
        схема = json.loads(СХЕМА.read_text(encoding="utf-8"))

        def проверить_объекты(узел: object, путь: str = "$") -> None:
            if isinstance(узел, dict):
                if узел.get("type") == "object":
                    сам.assertIs(
                        узел.get("additionalProperties"),
                        False,
                        f"объект схемы не закрыт: {путь}",
                    )
                for ключ, значение in узел.items():
                    проверить_объекты(значение, f"{путь}/{ключ}")
            elif isinstance(узел, list):
                for номер, значение in enumerate(узел):
                    проверить_объекты(значение, f"{путь}/{номер}")

        проверить_объекты(схема)
        обязательные_поля = set(схема["$defs"]["задание"]["required"])
        сам.assertTrue(
            {
                "job_id",
                "поколение",
                "адаптер",
                "цель",
                "триггер",
                "условия_допуска",
                "состояние",
                "эффект",
                "исполнитель",
                "защита_поколения",
                "курсор_результата",
                "политика_ошибки",
            }.issubset(обязательные_поля)
        )
        исполнитель = схема["$defs"]["исполнитель"]
        варианты = {
            (
                вариант["properties"]["тип"]["const"],
                вариант["properties"]["контракт"]["const"],
            )
            for вариант in исполнитель["oneOf"]
        }
        сам.assertEqual(
            варианты,
            {
                ("локальный_пробник", "локальный-симулятор.1"),
                (
                    "обычная_корневая_задача_Codex",
                    "обычная-корневая-задача-Codex.1",
                ),
            },
        )
        шаблон_корня = схема["properties"]["branch_ref"]["pattern"]
        шаблон_цели = схема["$defs"]["цель"]["properties"]["branch_ref"][
            "pattern"
        ]
        сам.assertEqual(шаблон_цели, шаблон_корня)
        for безопасная_ссылка in (
            "refs/heads/master",
            "refs/heads/codex/step_1",
        ):
            сам.assertIsNotNone(re.search(шаблон_корня, безопасная_ссылка))
        for небезопасная_ссылка in (
            "refs/heads/a..b",
            "refs/heads/.hidden",
            "refs/heads/-danger",
            "refs/heads/a//b",
            "refs/heads/master\n",
        ):
            сам.assertIsNone(re.search(шаблон_корня, небезопасная_ссылка))

        ограничения = схема["$defs"]["задание"]["allOf"]
        сам.assertEqual(len(ограничения), 1)
        ограничение = ограничения[0]
        сам.assertEqual(
            ограничение["if"]["properties"]["эффект"]["properties"][
                "класс"
            ]["enum"],
            ["изменение_репозитория", "внешний_эффект"],
        )
        исполнитель_для_изменений = ограничение["then"]["properties"][
            "исполнитель"
        ]["properties"]
        сам.assertEqual(
            исполнитель_для_изменений,
            {
                "контракт": {"const": "обычная-корневая-задача-Codex.1"},
                "тип": {"const": "обычная_корневая_задача_Codex"},
            },
        )

    def test_отрицательные_фикстуры_закрываются_до_симуляции(сам) -> None:
        основа = json.loads(КОРРЕКТНЫЙ_РЕЕСТР.read_text(encoding="utf-8"))
        набор = json.loads(НЕВАЛИДНЫЕ_СЛУЧАИ.read_text(encoding="utf-8"))
        сам.assertEqual(набор["schema"], "fum.dispatcher-invalid-fixtures.v1")

        for случай in набор["cases"]:
            with сам.subTest(случай=случай["name"]):
                реестр = deepcopy(основа)
                сам.применить_мутацию(реестр, случай["mutation"])
                with tempfile.TemporaryDirectory() as временный_каталог:
                    путь = Path(временный_каталог) / "реестр.json"
                    путь.write_text(
                        json.dumps(
                            реестр,
                            ensure_ascii=False,
                            indent=2,
                            sort_keys=True,
                        )
                        + "\n",
                        encoding="utf-8",
                    )
                    результат = сам.выполнить(
                        "проверить",
                        "--реестр",
                        str(путь),
                        "--схема",
                        str(СХЕМА),
                        "--json",
                    )

                сам.assertEqual(результат.returncode, 2, результат.stdout)
                ответ = json.loads(результат.stdout)
                сам.assertEqual(ответ["состояние"], "некорректен")
                сам.assertIn(случай["error_contains"], ответ["ошибка"])

    def test_повторный_ключ_данных_закрывает_контракт(сам) -> None:
        результат = сам.выполнить(
            "проверить",
            "--реестр",
            str(ПОВТОР_КЛЮЧА),
            "--схема",
            str(СХЕМА),
            "--json",
        )

        сам.assertEqual(результат.returncode, 2, результат.stdout)
        ответ = json.loads(результат.stdout)
        сам.assertIn("повтор ключа", ответ["ошибка"])

    def test_корень_должен_быть_рабочей_копией_гит(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            (корень / "README.md").write_text("# FUM\n", encoding="utf-8")
            результат = сам.выполнить_с_корнем(
                корень,
                "проверить",
                "--реестр",
                str(КОРРЕКТНЫЙ_РЕЕСТР),
                "--схема",
                str(СХЕМА),
                "--json",
            )

        сам.assertEqual(результат.returncode, 2, результат.stdout)
        ответ = json.loads(результат.stdout)
        сам.assertIn("Git", ответ["ошибка"])

    def test_паспорт_через_промежуточную_символическую_ссылку_отклоняется(
        сам,
    ) -> None:
        реестр = json.loads(КОРРЕКТНЫЙ_РЕЕСТР.read_text(encoding="utf-8"))
        реестр["путь_проекта"] = "проект/README.md"
        for задание in реестр["задания"]:
            задание["цель"]["путь_проекта"] = "проект/README.md"

        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            (корень / ".git").mkdir()
            настоящий_каталог = корень / "настоящий-проект"
            настоящий_каталог.mkdir()
            (настоящий_каталог / "README.md").write_text(
                "# FUM\n",
                encoding="utf-8",
            )
            (корень / "проект").symlink_to(настоящий_каталог, target_is_directory=True)
            путь_реестра = корень / "реестр.json"
            путь_реестра.write_text(
                json.dumps(реестр, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            результат = сам.выполнить_с_корнем(
                корень,
                "проверить",
                "--реестр",
                str(путь_реестра),
                "--схема",
                str(СХЕМА),
                "--json",
            )

        сам.assertEqual(результат.returncode, 2, результат.stdout)
        ответ = json.loads(результат.stdout)
        сам.assertIn("символическую ссылку", ответ["ошибка"])

    def применить_мутацию(
        сам,
        реестр: dict[str, object],
        мутация: dict[str, object],
    ) -> None:
        операция = мутация["operation"]
        if операция == "duplicate_first_job":
            задания = реестр["задания"]
            сам.assertIsInstance(задания, list)
            задания.append(deepcopy(задания[0]))
            return

        путь = мутация["path"]
        сам.assertIsInstance(путь, list)
        цель: object = реестр
        for часть in путь[:-1]:
            цель = цель[часть]  # type: ignore[index]
        ключ = путь[-1]
        if операция == "set":
            цель[ключ] = мутация["value"]  # type: ignore[index]
            return
        if операция == "delete":
            del цель[ключ]  # type: ignore[index]
            return
        raise AssertionError(f"Неизвестная мутация фикстуры: {операция}")

    def test_симулятор_различает_срок_условия_паузу_и_блокировку(сам) -> None:
        результат = сам.выполнить(
            "симулировать",
            "--реестр",
            str(КОРРЕКТНЫЙ_РЕЕСТР),
            "--схема",
            str(СХЕМА),
            "--наблюдения",
            str(НАБЛЮДЕНИЯ),
            "--json",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        ответ = json.loads(результат.stdout)
        сам.assertEqual(ответ["состояние"], "смоделирован")
        статусы = {
            задание["job_id"]: задание["статус"]
            for задание in ответ["задания"]
        }
        сам.assertEqual(
            статусы,
            {
                "master.blocked-schedule": "заблокировано",
                "master.event-threshold": "готово",
                "master.paused-schedule": "приостановлено",
                "master.retired-schedule": "выведено_из_эксплуатации",
                "master.scheduled": "готово",
            },
        )
        результаты = {
            задание["job_id"]: задание
            for задание in ответ["задания"]
        }
        сам.assertEqual(
            результаты["master.event-threshold"]["наступление"],
            "завершённое_поколение_шага:1-5",
        )
        for идентификатор_задания in (
            "master.paused-schedule",
            "master.blocked-schedule",
            "master.retired-schedule",
        ):
            with сам.subTest(задание=идентификатор_задания):
                задание = результаты[идентификатор_задания]
                сам.assertEqual(задание["наступление"], "2026-08-05T00:10:00Z")
                сам.assertIs(задание["триггер_наступил"], True)
                сам.assertIs(задание["условия_выполнены"], True)
                сам.assertIs(задание["состояние_разрешает"], False)
                сам.assertIs(задание["готово"], False)

    def test_условия_не_становятся_частью_триггера(сам) -> None:
        наблюдения = json.loads(НАБЛЮДЕНИЯ.read_text(encoding="utf-8"))
        наблюдения["условия"]["среда_свободна"] = False
        with tempfile.TemporaryDirectory() as временный_каталог:
            путь = Path(временный_каталог) / "наблюдения.json"
            путь.write_text(
                json.dumps(
                    наблюдения,
                    ensure_ascii=False,
                    indent=2,
                    sort_keys=True,
                )
                + "\n",
                encoding="utf-8",
            )
            результат = сам.выполнить(
                "симулировать",
                "--реестр",
                str(КОРРЕКТНЫЙ_РЕЕСТР),
                "--схема",
                str(СХЕМА),
                "--наблюдения",
                str(путь),
                "--json",
            )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        ответ = json.loads(результат.stdout)
        результаты = {
            задание["job_id"]: задание
            for задание in ответ["задания"]
        }
        сам.assertEqual(
            результаты["master.scheduled"]["статус"],
            "ожидание_условий",
        )
        сам.assertEqual(
            результаты["master.scheduled"]["наступление"],
            "2026-08-05T00:10:00Z",
        )
        сам.assertEqual(
            результаты["master.scheduled"]["невыполненные_условия"],
            ["среда-свободна"],
        )
        сам.assertIs(результаты["master.scheduled"]["триггер_наступил"], True)
        сам.assertIs(результаты["master.scheduled"]["условия_выполнены"], False)
        сам.assertIs(результаты["master.scheduled"]["состояние_разрешает"], True)
        сам.assertIs(результаты["master.scheduled"]["готово"], False)

    def test_сценарий_не_имеет_сетевых_и_внешних_адаптеров(сам) -> None:
        исходник = СЦЕНАРИЙ.read_text(encoding="utf-8")
        дерево = ast.parse(исходник)
        импорты: set[str] = set()
        for узел in ast.walk(дерево):
            if isinstance(узел, ast.Import):
                импорты.update(имя.name.split(".")[0] for имя in узел.names)
            elif isinstance(узел, ast.ImportFrom) and узел.module:
                импорты.add(узел.module.split(".")[0])
        сам.assertTrue(
            импорты.isdisjoint(
                {
                    "http",
                    "requests",
                    "socket",
                    "time",
                    "urllib",
                    "codex_app",
                }
            )
        )
        сам.assertNotIn("create_thread", исходник)
        сам.assertNotIn("codex_app", исходник)
        вызовы_процессов = [
            узел
            for узел in ast.walk(дерево)
            if isinstance(узел, ast.Call)
            and isinstance(узел.func, ast.Attribute)
            and isinstance(узел.func.value, ast.Name)
            and узел.func.value.id == "subprocess"
            and узел.func.attr == "run"
        ]
        сам.assertEqual(len(вызовы_процессов), 3)
        аргументы_вызовов = [
            вызов.args[0] for вызов in вызовы_процессов
        ]
        общие_аргументы = next(
            аргументы
            for аргументы in аргументы_вызовов
            if isinstance(аргументы, ast.List)
        )
        сам.assertIsInstance(общие_аргументы, ast.List)
        первый = общие_аргументы.elts[0]
        сам.assertIsInstance(первый, ast.Constant)
        сам.assertEqual(первый.value, "git")
        исторический_вызов_гит = next(
            аргументы
            for аргументы in аргументы_вызовов
            if isinstance(аргументы, ast.Name)
        )
        сам.assertIsInstance(исторический_вызов_гит, ast.Name)
        сам.assertEqual(исторический_вызов_гит.id, "команда")
        исторический_адаптер = next(
            аргументы
            for аргументы in аргументы_вызовов
            if isinstance(аргументы, ast.Tuple)
        )
        сам.assertIsInstance(исторический_адаптер, ast.Tuple)
        сам.assertIsInstance(исторический_адаптер.elts[0], ast.Attribute)
        сам.assertEqual(исторический_адаптер.elts[0].attr, "executable")
        запрещённые_часы = [
            узел
            for узел in ast.walk(дерево)
            if isinstance(узел, ast.Call)
            and isinstance(узел.func, ast.Attribute)
            and узел.func.attr in {"now", "utcnow", "today"}
        ]
        сам.assertEqual(запрещённые_часы, [])

    def test_локальный_пробник_не_меняет_индекс(сам) -> None:
        путь_индекса = КОРЕНЬ_РЕПОЗИТОРИЯ / ".git" / "index"
        до = (
            hashlib.sha256(путь_индекса.read_bytes()).hexdigest()
            if путь_индекса.is_file()
            else None
        )
        результат = subprocess.run(
            [str(ПРОБНИК)],
            cwd=КОРЕНЬ_РЕПОЗИТОРИЯ,
            check=False,
            capture_output=True,
            text=True,
        )
        после = (
            hashlib.sha256(путь_индекса.read_bytes()).hexdigest()
            if путь_индекса.is_file()
            else None
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(до, после)
        ответ = json.loads(результат.stdout)
        сам.assertEqual(ответ["состояние"], "смоделирован")
        сам.assertEqual(
            {задание["job_id"] for задание in ответ["задания"]},
            {
                "master.blocked-schedule",
                "master.event-threshold",
                "master.paused-schedule",
                "master.retired-schedule",
                "master.scheduled",
            },
        )


if __name__ == "__main__":
    unittest.main()
