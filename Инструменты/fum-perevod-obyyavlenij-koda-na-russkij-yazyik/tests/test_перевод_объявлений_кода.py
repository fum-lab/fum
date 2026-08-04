import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


корень_автоматизации = Path(__file__).resolve().parents[1]
путь_сценария = (
    корень_автоматизации / "scripts" / "перевести-объявления-кода.py"
)


class ПроверкаПереводаОбъявленийКода(unittest.TestCase):
    def запустить(сам, *аргументы: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(путь_сценария), *аргументы],
            check=False,
            capture_output=True,
            text=True,
        )

    def записать(сам, корень: Path, путь: str, текст: str) -> Path:
        файл = корень / путь
        файл.parent.mkdir(parents=True, exist_ok=True)
        файл.write_text(текст, encoding="utf-8")
        return файл

    def хэш(сам, файл: Path) -> str:
        return "sha256:" + hashlib.sha256(файл.read_bytes()).hexdigest()

    def карта(сам, файлы: list[tuple[str, str, dict[str, str]]]) -> dict[str, object]:
        return {
            "версия_схемы": 1,
            "файлы": [
                {
                    "путь": путь,
                    "ожидаемый_хэш": ожидаемый_хэш,
                    "переименования": переименования,
                }
                for путь, ожидаемый_хэш, переименования in файлы
            ],
        }

    def test_инвентарь_находит_питон_свифт_и_мермейд(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.записать(
                корень,
                "Инструменты/пример.py",
                "class OldType:\n"
                "    def old_function(old_parameter):\n"
                "        local_value = 1\n"
                "        old_parameter.old_attribute = local_value\n"
                "        return local_value\n"
                "\n"
                "text = 'class HiddenType: pass'\n"
                "# def hidden_function(): pass\n",
            )
            сам.записать(
                корень,
                "Прототипы/пример.swift",
                "// struct HiddenStruct {}\n"
                "let hiddenText = \"func hiddenFunction(fake: Int) {}\"\n"
                "struct OldStruct {\n"
                "    let oldValue: Int\n"
                "    func oldFunction(oldLabel oldParameter: Int, second: String) {}\n"
                "    enum Kind { case oldCase, secondCase }\n"
                "}\n",
            )
            сам.записать(
                корень,
                "Документация/схема.md",
                "# Схема\n\n"
                "```mermaid\n"
                "flowchart LR\n"
                "    oldNode[\"Старый\"] --> nextNode[\"Следующий\"]\n"
                "    nextNode --> oldNode\n"
                "```\n",
            )

            результат = сам.запустить(
                "инвентаризировать",
                "--корень-репозитория",
                str(корень),
            )

            сам.assertEqual(результат.returncode, 0, результат.stderr)
            инвентарь = json.loads(результат.stdout)
            сам.assertEqual(set(инвентарь), {"версия_схемы", "объявления"})
            сам.assertEqual(инвентарь["версия_схемы"], 1)
            найденные = {
                (запись["язык"], запись["вид"], запись["имя"])
                for запись in инвентарь["объявления"]
            }
            сам.assertTrue(
                {
                    ("python", "класс", "OldType"),
                    ("python", "функция", "old_function"),
                    ("python", "параметр", "old_parameter"),
                    ("python", "привязка", "local_value"),
                    ("python", "атрибут", "old_attribute"),
                    ("swift", "тип", "OldStruct"),
                    ("swift", "свойство", "oldValue"),
                    ("swift", "функция", "oldFunction"),
                    ("swift", "параметр", "oldParameter"),
                    ("swift", "вариант", "oldCase"),
                    ("mermaid", "узел", "oldNode"),
                    ("mermaid", "узел", "nextNode"),
                }.issubset(найденные)
            )
            имена = {запись["имя"] for запись in инвентарь["объявления"]}
            сам.assertFalse(
                {"HiddenType", "hidden_function", "HiddenStruct", "hiddenFunction", "fake"}
                & имена
            )

    def test_инвентарь_исключает_защищённые_области(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            защищённая_схема = (
                "```mermaid\nflowchart LR\noldProtected[\"Не менять\"]\n```\n"
            )
            сам.записать(
                корень,
                "Журнал/2026-01-01_00-00-00_MSK_пример/запрос.md",
                "# Запрос\n\n## Текст запроса\n\n" + защищённая_схема,
            )
            сам.записать(
                корень,
                "Журнал/2026-01-01_00-00-01_MSK_пример/материалы/ревью/ревью.md",
                "# Ревью\n\n## Снимок Git\n\n" + защищённая_схема,
            )
            сам.записать(
                корень,
                "Источники/URL/https/example.test/материал.md",
                защищённая_схема,
            )
            сам.записать(
                корень,
                "Зависимости/внешняя/материал.md",
                защищённая_схема,
            )
            сам.записать(
                корень,
                ".build/мусор.py",
                "def oldCached():\n    pass\n",
            )

            результат = сам.запустить(
                "инвентаризировать",
                "--корень-репозитория",
                str(корень),
            )

            сам.assertEqual(результат.returncode, 0, результат.stderr)
            инвентарь = json.loads(результат.stdout)
            сам.assertEqual(инвентарь["объявления"], [])

    def test_снимок_проверяет_точный_остаток(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            файл = сам.записать(корень, "код.py", "def old_name():\n    pass\n")
            снимок = корень / "снимок.json"

            обновление = сам.запустить(
                "обновить-снимок",
                "--корень-репозитория",
                str(корень),
                "--снимок",
                str(снимок),
            )
            сам.assertEqual(обновление.returncode, 0, обновление.stderr)
            сам.assertTrue(снимок.is_file())
            сам.assertFalse(list(корень.glob(".снимок.json.*")))
            сводка = json.loads(снимок.read_text(encoding="utf-8"))
            сам.assertEqual(
                set(сводка),
                {
                    "версия_схемы",
                    "объявлений",
                    "отпечаток_инвентаря",
                    "по_языкам",
                },
            )
            сам.assertEqual(сводка["объявлений"], 1)
            сам.assertEqual(сводка["по_языкам"], {"python": 1})
            сам.assertLess(снимок.stat().st_size, 1024)

            проверка = сам.запустить(
                "проверить",
                "--корень-репозитория",
                str(корень),
                "--снимок",
                str(снимок),
            )
            сам.assertEqual(проверка.returncode, 0, проверка.stderr)

            файл.write_text(
                файл.read_text(encoding="utf-8") + "\ndef replacement_name():\n    pass\n",
                encoding="utf-8",
            )
            расхождение = сам.запустить(
                "проверить",
                "--корень-репозитория",
                str(корень),
                "--снимок",
                str(снимок),
            )
            сам.assertNotEqual(расхождение.returncode, 0)
            сам.assertIn("снимок не совпадает", расхождение.stderr)

    def test_план_не_пишет_а_применение_меняет_только_токены(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            файл = сам.записать(
                корень,
                "код.py",
                "def old_name():\n"
                "    # old_name в комментарии\n"
                "    value = 'old_name в строке'\n"
                "    return old_name\n",
            )
            исходный_текст = файл.read_text(encoding="utf-8")
            карта = корень / "карта.json"
            карта.write_text(
                json.dumps(
                    сам.карта([("код.py", сам.хэш(файл), {"old_name": "старое_имя"})]),
                    ensure_ascii=False,
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )

            план = сам.запустить(
                "план",
                "--корень-репозитория",
                str(корень),
                "--карта",
                str(карта),
            )
            сам.assertEqual(план.returncode, 0, план.stderr)
            сам.assertEqual(файл.read_text(encoding="utf-8"), исходный_текст)
            сам.assertEqual(json.loads(план.stdout)["режим"], "план")

            применение = сам.запустить(
                "применить",
                "--корень-репозитория",
                str(корень),
                "--карта",
                str(карта),
            )
            сам.assertEqual(применение.returncode, 0, применение.stderr)
            итог = файл.read_text(encoding="utf-8")
            сам.assertIn("def старое_имя():", итог)
            сам.assertIn("return старое_имя", итог)
            сам.assertIn("# old_name в комментарии", итог)
            сам.assertIn("'old_name в строке'", итог)

    def test_применение_обрабатывает_свифт_и_мермейд(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            файл_языка_свифт = сам.записать(
                корень,
                "Прототипы/код.swift",
                "struct OldType {}\n"
                "let oldValue = OldType()\n"
                "// OldType oldValue\n"
                "let text = \"OldType oldValue\"\n",
            )
            файл_схемы = сам.записать(
                корень,
                "Документация/схема.md",
                "oldNode вне блока\n\n"
                "```mermaid\n"
                "flowchart LR\n"
                "oldNode[\"oldNode в подписи\"] --> nextNode[\"Узел\"]\n"
                "oldNode[oldNode в сырой подписи]\n"
                "nextNode --> oldNode\n"
                "```\n",
            )
            карта = корень / "карта.json"
            карта.write_text(
                json.dumps(
                    сам.карта(
                        [
                            (
                                "Прототипы/код.swift",
                                сам.хэш(файл_языка_свифт),
                                {"OldType": "СтарыйТип", "oldValue": "староеЗначение"},
                            ),
                            (
                                "Документация/схема.md",
                                сам.хэш(файл_схемы),
                                {"oldNode": "старый_узел", "nextNode": "следующий_узел"},
                            ),
                        ]
                    ),
                    ensure_ascii=False,
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )

            результат = сам.запустить(
                "применить",
                "--корень-репозитория",
                str(корень),
                "--карта",
                str(карта),
            )

            сам.assertEqual(результат.returncode, 0, результат.stderr)
            итог_кода_свифт = файл_языка_свифт.read_text(encoding="utf-8")
            сам.assertIn("struct СтарыйТип", итог_кода_свифт)
            сам.assertIn("let староеЗначение = СтарыйТип()", итог_кода_свифт)
            сам.assertIn("// OldType oldValue", итог_кода_свифт)
            сам.assertIn('"OldType oldValue"', итог_кода_свифт)
            итог_схемы = файл_схемы.read_text(encoding="utf-8")
            сам.assertIn("старый_узел[\"oldNode в подписи\"]", итог_схемы)
            сам.assertIn("старый_узел[oldNode в сырой подписи]", итог_схемы)
            сам.assertIn("следующий_узел --> старый_узел", итог_схемы)
            сам.assertTrue(итог_схемы.startswith("oldNode вне блока"))

    def test_свифт_находит_и_переводит_параметр_замыкания(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            файл = сам.записать(
                корень,
                "код.swift",
                "let values = [1]\n"
                "let result = values.map { oldValue -> String in\n"
                "  String(oldValue)\n"
                "}\n",
            )
            инвентарь = сам.запустить(
                "инвентаризировать",
                "--корень-репозитория",
                str(корень),
            )
            сам.assertEqual(инвентарь.returncode, 0, инвентарь.stderr)
            объявления = json.loads(инвентарь.stdout)["объявления"]
            сам.assertIn(
                ("параметр", "oldValue"),
                {(запись["вид"], запись["имя"]) for запись in объявления},
            )
            карта = корень / "карта.json"
            карта.write_text(
                json.dumps(
                    сам.карта(
                        [("код.swift", сам.хэш(файл), {"oldValue": "староеЗначение"})]
                    ),
                    ensure_ascii=False,
                )
                + "\n",
                encoding="utf-8",
            )
            применение = сам.запустить(
                "применить",
                "--корень-репозитория",
                str(корень),
                "--карта",
                str(карта),
            )
            сам.assertEqual(применение.returncode, 0, применение.stderr)
            итог = файл.read_text(encoding="utf-8")
            сам.assertIn("{ староеЗначение -> String in", итог)
            сам.assertIn("String(староеЗначение)", итог)

    def test_карта_отклоняет_хэш_коллизию_и_нерусское_имя(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            файл = сам.записать(
                корень,
                "код.py",
                "old_name = 1\nзанятое_имя = 2\n",
            )

            случаи = [
                (
                    "неверный хэш",
                    сам.карта([("код.py", "sha256:" + "0" * 64, {"old_name": "новое_имя"})]),
                ),
                (
                    "коллизия",
                    сам.карта([("код.py", сам.хэш(файл), {"old_name": "занятое_имя"})]),
                ),
                (
                    "кириллиц",
                    сам.карта([("код.py", сам.хэш(файл), {"old_name": "new_name"})]),
                ),
                (
                    "латиниц",
                    сам.карта(
                        [
                            (
                                "код.py",
                                сам.хэш(файл),
                                {"old_name": "смешанноеИмяLatin"},
                            )
                        ]
                    ),
                ),
            ]
            for ожидаемый_фрагмент, содержимое_карты in случаи:
                with сам.subTest(причина=ожидаемый_фрагмент):
                    карта = корень / "карта.json"
                    карта.write_text(
                        json.dumps(содержимое_карты, ensure_ascii=False) + "\n",
                        encoding="utf-8",
                    )
                    исходный_текст = файл.read_text(encoding="utf-8")
                    результат = сам.запустить(
                        "план",
                        "--корень-репозитория",
                        str(корень),
                        "--карта",
                        str(карта),
                    )
                    сам.assertNotEqual(результат.returncode, 0)
                    сам.assertIn(ожидаемый_фрагмент, результат.stderr)
                    сам.assertEqual(файл.read_text(encoding="utf-8"), исходный_текст)

    def test_собственный_питон_код_не_объявляет_латинские_имена(сам) -> None:
        результат = сам.запустить(
            "инвентаризировать",
            "--корень-репозитория",
            str(корень_автоматизации),
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        инвентарь = json.loads(результат.stdout)
        объявления_питона = [
            запись
            for запись in инвентарь["объявления"]
            if запись["язык"] == "python"
        ]
        сам.assertEqual(объявления_питона, [])


if __name__ == "__main__":
    unittest.main()
