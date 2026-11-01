import time
МОМЕНТ_НАЧАЛА_ЗАГРУЗКИ = time.perf_counter_ns()
import contextlib
import base64
import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


import os

def путь_проверяемой_реализации(путь: Path) -> Path:
    выбранный = os.environ.get("FUM_CHECKED_CODE_ROOT")
    if выбранный is None:
        return путь
    if not выбранный or not Path(выбранный).is_absolute():
        raise ValueError("корень проверяемой реализации должен быть явным абсолютным путём")
    return Path(выбранный) / путь.relative_to(Path(__file__).resolve().parents[3])


AUTOMATION_DIR = Path(__file__).resolve().parents[1]
SCRIPT_PATH = (
    путь_проверяемой_реализации(AUTOMATION_DIR
    / "scripts"
    / "proveritj-mashinno-lokaljnyiye-puti.py")
)
SCRIPTS_DIR = путь_проверяемой_реализации(AUTOMATION_DIR / "scripts")
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

spec = importlib.util.spec_from_file_location(
    "proveritj_mashinno_lokaljnyiye_puti",
    SCRIPT_PATH,
)
scanner = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = scanner
spec.loader.exec_module(scanner)


class MachineLocalPathScannerTests(unittest.TestCase):
    def test_указатели_остатка_не_являются_путями_файловой_системы(сам) -> None:
        путь = (
            "Журнал/2026-09-22_11-13-26_MSK_продолжить-регистр-остатка/"
            "материалы/индекс-остатка.jsonl"
        )
        строка = json.dumps(
            {
                "указатель_обработки": "/" + "остаток/0",
                "указатель_оригинала": "/" + "сообщения/0",
                "путь": "/" + "Users/example/private",
            },
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        категории = [запись.category for запись in scanner.scan_text(путь, строка)]
        сам.assertEqual(категории.count("report.json-pointer.posix-absolute"), 2)
        сам.assertIn("error.posix-user-home", категории)
        сам.assertIn("error.posix-absolute", [
            запись.category for запись in scanner.scan_text("Документация/пример.jsonl", строка)
        ])

    def test_base64_изображение_не_скрывает_соседний_локальный_путь(сам) -> None:
        путь = "Журнал/2026-09-22_05-12-27_MSK_фикстура/материалы/остаток-команды.jsonl"
        изображение = "data:image/png;base64,iVBORw0KGgoA+" + "/" + "/" + "host/path"
        сам.assertTrue(base64.b64decode(
            изображение.partition(",")[2], validate=True,
        ).startswith(b"\x89PNG\r\n\x1a\n"))
        строка = json.dumps(
            [{}, {}, {"detail": "high", "image_url": изображение, "type": "input_image"},
             {"путь": "/" + "Users/example/private"}],
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        категории = [запись.category for запись in scanner.scan_text(путь, строка)]
        сам.assertIn("report.data-image.windows-unc", категории)
        сам.assertIn("error.posix-user-home", категории)
        сам.assertIn("error.windows-unc", [
            запись.category for запись in scanner.scan_text("Документация/пример.jsonl", строка)
        ])

    def test_бинарное_вложение_требует_обычный_запрос(сам) -> None:
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.init_repo(корень)
            папка = "Журнал/2026-09-10_17-33-36_MSK_проверить-вложение"
            имя = f"{папка}/материалы/источники/вложение/архив.zip"
            архив = корень / имя
            архив.parent.mkdir(parents=True)
            архив.write_bytes(b"archive\0payload")
            отказ = f"{имя}:0:error.binary-input"
            сам.assertIn(отказ, сам.scan(корень).rendered_lines())
            чужой = корень / "другой-запрос.md"
            чужой.write_text("# Другой запрос\n", encoding="utf-8")
            запрос = корень / папка / "запрос.md"
            запрос.symlink_to(чужой)
            сам.assertIn(отказ, сам.scan(корень).rendered_lines())
            запрос.unlink()
            сам.write_and_add(корень, f"{папка}/запрос.md", "# Запрос\n")
            сам.assertIn(
                f"{имя}:0:report.external-source.binary",
                сам.scan(корень).rendered_lines(),
            )

    def test_бинарное_вложение_принадлежит_точной_папке_запроса(сам) -> None:
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.init_repo(корень)
            ствол = "2026-09-08_21-16-28_MSK_фикстура"
            основа = f"Журнал/{ствол}/материалы/источники"
            допустимый = f"{основа}/вложение/архив.bin"
            запрещённые = (
                f"{основа}/архив.bin",
                f"Журнал/без-времени/материалы/источники/вложение/архив.bin",
                f"Журнал/{ствол}/материалы/источники-копия/вложение/архив.bin",
                f"Документация/{допустимый}",
            )
            сам.assertFalse(scanner._это_бинарное_вложение_запроса(
                f"Журнал/{ствол}/материалы/Источники/вложение/архив.bin",
                frozenset({f"Журнал/{ствол}/запрос.md"}),
            ))
            for имя in (допустимый, *запрещённые):
                путь = корень / имя
                путь.parent.mkdir(parents=True, exist_ok=True)
                путь.write_bytes(b"archive\0payload")
            текстовый = f"{основа}/вложение/производное.md"
            (корень / текстовый).write_text(str(корень / "фикстура"), encoding="utf-8")
            сам.assertIn(f"{допустимый}:0:error.binary-input", сам.scan(корень).rendered_lines())
            сам.write_and_add(корень, f"Журнал/{ствол}/запрос.md", "# Запрос\n")
            нетекстовый = f"{основа}/вложение/не-utf8.txt"
            (корень / нетекстовый).write_bytes(b"\xff")
            результат = сам.scan(корень)
            строки = результат.rendered_lines()
            сам.assertIn(f"{допустимый}:0:report.external-source.binary", строки)
            сам.assertIn(f"{нетекстовый}:0:error.non-utf8-input", строки)
            for имя in запрещённые:
                сам.assertIn(f"{имя}:0:error.binary-input", строки)
            сам.assertTrue(any(строка.startswith(f"{текстовый}:1:error.") for строка in строки))
            сам.assertEqual(результат.exit_code, 2)


    def init_repo(себя, корень_сценария: Path) -> None:
        subprocess.run(
            ["git", "init"],
            cwd=корень_сценария,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        (корень_сценария / ".gitignore").write_text("ignored/\n", encoding="utf-8")
        subprocess.run(["git", "add", ".gitignore"], cwd=корень_сценария, check=True)

    def write_policy(
        себя,
        корень_сценария: Path,
        exceptions: list[dict[str, object]] | None = None,
    ) -> Path:
        path = корень_сценария / "policy.json"
        path.write_text(
            json.dumps(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": exceptions or [],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        return path

    def scan(себя, корень_сценария: Path, policy: Path | None = None):
        policy_path = policy or себя.write_policy(корень_сценария)
        return scanner.scan_repository(корень_сценария, policy_path)

    def write_and_add(себя, корень_сценария: Path, relative: str, text: str) -> Path:
        path = корень_сценария / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        subprocess.run(["git", "add", relative], cwd=корень_сценария, check=True)
        return path

    def test_scans_cached_and_untracked_nonignored_files_in_stable_order(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Документация/б.md",
                "/Users/example/work/FUM\n",
            )
            untracked = корень_сценария / "Документация" / "а.md"
            untracked.write_text("D:/work/FUM/config.json\n", encoding="utf-8")
            ignored = корень_сценария / "ignored" / "скрытый.md"
            ignored.parent.mkdir()
            ignored.write_text("/Users/example/hidden\n", encoding="utf-8")

            результат_сценария = себя.scan(корень_сценария)

            себя.assertEqual(
                результат_сценария.rendered_lines(),
                (
                    "Документация/а.md:1:error.windows-drive",
                    "Документация/б.md:1:error.posix-user-home",
                ),
            )
            себя.assertEqual(результат_сценария.exit_code, 1)
            rendered = "\n".join(результат_сценария.rendered_lines())
            себя.assertNotIn("example", rendered)
            себя.assertNotIn("config.json", rendered)
            себя.assertNotIn("скрытый", rendered)

    def test_производная_проекция_не_сканируется_как_канонический_источник(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Proyekcii/Bratislavskaya-pamyatj/fajlyi/Dokumentaciya/kopiya.md",
                "/Users/example/generated-copy\n",
            )
            себя.write_and_add(
                корень_сценария,
                "Proyekcii-copy/канонический.md",
                "/Users/example/prefix-near-miss\n",
            )
            себя.write_and_add(
                корень_сценария,
                "Документация/Proyekcii/вложенный.md",
                "/Users/example/nested-near-miss\n",
            )

            результат_сценария = себя.scan(корень_сценария)

            себя.assertEqual(
                результат_сценария.rendered_lines(),
                (
                    "Proyekcii-copy/канонический.md:1:error.posix-user-home",
                    "Документация/Proyekcii/вложенный.md:1:error.posix-user-home",
                ),
            )
            себя.assertEqual(результат_сценария.exit_code, 1)

    def test_request_text_and_external_sources_are_report_only(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Журнал/2026-07-22_00-00-00_MSK_fixture/запрос.md",
                "# Запрос\n\n"
                "## Текст запроса\n\n"
                "```text\n"
                "/Users/example/source\n"
                "## Заголовок внутри fence\n"
                "```\n\n"
                "## Результат\n\n"
                "/Users/example/active\n",
            )
            себя.write_and_add(
                корень_сценария,
                "Источники/URL/https/example.test/raw.txt",
                r"C:\Users\Example\archive" + "\n",
            )

            результат_сценария = себя.scan(корень_сценария)

            себя.assertIn(
                "Журнал/2026-07-22_00-00-00_MSK_fixture/запрос.md:6:report.request-text.posix-user-home",
                результат_сценария.rendered_lines(),
            )
            себя.assertIn(
                "Журнал/2026-07-22_00-00-00_MSK_fixture/запрос.md:12:error.posix-user-home",
                результат_сценария.rendered_lines(),
            )
            себя.assertIn(
                "Источники/URL/https/example.test/raw.txt:1:report.external-source.windows-drive",
                результат_сценария.rendered_lines(),
            )
            себя.assertEqual(результат_сценария.exit_code, 1)

    def test_бинарное_вложение_принадлежит_точной_папке_запроса(сам) -> None:
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.init_repo(корень)
            ствол = "2026-09-08_21-16-28_MSK_фикстура"
            основа = f"Журнал/{ствол}/материалы/источники"
            допустимый = f"{основа}/вложение/архив.bin"
            запрещённые = (
                f"{основа}/архив.bin",
                f"Журнал/без-времени/материалы/источники/вложение/архив.bin",
                f"Журнал/{ствол}/материалы/источники-копия/вложение/архив.bin",
                f"Документация/{допустимый}",
            )
            сам.assertFalse(scanner._это_бинарное_вложение_запроса(
                f"Журнал/{ствол}/материалы/Источники/вложение/архив.bin",
                frozenset({f"Журнал/{ствол}/запрос.md"}),
            ))
            for имя in (допустимый, *запрещённые):
                путь = корень / имя
                путь.parent.mkdir(parents=True, exist_ok=True)
                путь.write_bytes(b"archive\0payload")
            текстовый = f"{основа}/вложение/производное.md"
            (корень / текстовый).write_text(str(корень / "фикстура"), encoding="utf-8")
            сам.assertIn(f"{допустимый}:0:error.binary-input", сам.scan(корень).rendered_lines())
            сам.write_and_add(корень, f"Журнал/{ствол}/запрос.md", "# Запрос\n")
            нетекстовый = f"{основа}/вложение/не-utf8.txt"
            (корень / нетекстовый).write_bytes(b"\xff")
            результат = сам.scan(корень)
            строки = результат.rendered_lines()
            сам.assertIn(f"{допустимый}:0:report.external-source.binary", строки)
            сам.assertIn(f"{нетекстовый}:0:error.non-utf8-input", строки)
            for имя in запрещённые:
                сам.assertIn(f"{имя}:0:error.binary-input", строки)
            сам.assertTrue(any(строка.startswith(f"{текстовый}:1:error.") for строка in строки))
            сам.assertEqual(результат.exit_code, 2)

    def test_noncanonical_journal_markdown_does_not_gain_request_provenance(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Журнал/2026-07-22_00-00-00_MSK_fixture/отчёт.md",
                "# Отчёт\n\n## Текст запроса\n\n/Users/example/not-verbatim\n",
            )

            результат_сценария = себя.scan(корень_сценария)

            себя.assertIn(
                "Журнал/2026-07-22_00-00-00_MSK_fixture/отчёт.md:5:error.posix-user-home",
                результат_сценария.rendered_lines(),
            )

    def test_канонический_исполнитель_субагента_допускается_только_в_точном_контексте(сам) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.init_repo(корень)
            основа_идентификатора = "/" + "root/"
            ствол = "2026-08-13_18-17-47_MSK_fixture"
            сессия = f"Журнал/{ствол}/запрос.md"
            каталог = f"Журнал/{ствол}/материалы/запуски-проверок"
            идентификатор = "11111111-1111-4111-8111-111111111111"
            исполнитель = основа_идентификатора + "security_docs_sync"
            запись = {
                "схема": "fum.test-run.v1",
                "сессия": сессия,
                "порядок": 1,
                "идентификатор": идентификатор,
                "состояние": "завершён",
                "исполнитель": исполнитель,
                "вызов": "Целевая проверка",
                "длительность_наносекунды": 1_000_000,
                "статус": "успешно",
                "код_завершения": 0,
                "пояснение": None,
            }
            путь_записи = (
                f"{каталог}/1_{идентификатор}.json"
            )
            текст_записи = json.dumps(
                запись,
                ensure_ascii=False,
                sort_keys=True,
                indent=2,
            ) + "\n"
            сам.write_and_add(корень, путь_записи, текст_записи)

            путь_отчёта = f"Журнал/{ствол}/отчёт.md"
            текст_отчёта = (
                "# Отчёт\n\n"
                "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; "
                "каталог=материалы/запуски-проверок -->\n"
                "| Вызов | Длительность | Результат |\n"
                "| ------ | ------------ | --------- |\n"
                f"| [{исполнитель}] Целевая проверка | 0,001 с | успешно |\n"
                "<!-- FUM-CHECK-RUNS:END -->\n\n"
                f"Вне блока: {исполнитель}\n"
            )
            сам.write_and_add(корень, путь_отчёта, текст_отчёта)

            неверная_запись = dict(запись)
            неверная_запись["порядок"] = 2
            неверная_запись["идентификатор"] = (
                "22222222-2222-4222-8222-222222222222"
            )
            неверная_запись["исполнитель"] = (
                основа_идентификатора + "private/cache"
            )
            путь_неверной_записи = (
                f"{каталог}/2_{неверная_запись['идентификатор']}.json"
            )
            сам.write_and_add(
                корень,
                путь_неверной_записи,
                json.dumps(
                    неверная_запись,
                    ensure_ascii=False,
                    sort_keys=True,
                    indent=2,
                )
                + "\n",
            )

            результат = сам.scan(корень)

            строка_исполнителя = текст_записи.splitlines().index(
                f'  "исполнитель": "{исполнитель}",'
            ) + 1
            строка_таблицы = текст_отчёта.splitlines().index(
                f"| [{исполнитель}] Целевая проверка | 0,001 с | успешно |"
            ) + 1
            строка_вне_блока = len(текст_отчёта.splitlines())
            сам.assertIn(
                f"{путь_записи}:{строка_исполнителя}:allow.collaboration-executor-id",
                результат.rendered_lines(),
            )
            сам.assertIn(
                f"{путь_отчёта}:{строка_таблицы}:allow.collaboration-executor-id",
                результат.rendered_lines(),
            )
            сам.assertIn(
                f"{путь_отчёта}:{строка_вне_блока}:error.posix-user-home",
                результат.rendered_lines(),
            )
            сам.assertTrue(
                any(
                    строка.startswith(f"{путь_неверной_записи}:")
                    and строка.endswith(":error.posix-user-home")
                    for строка in результат.rendered_lines()
                )
            )
            сам.assertEqual(результат.exit_code, 1)

    def test_профилированная_запись_сохраняет_узкое_разрешение_исполнителя(
        сам,
    ) -> None:
        ствол = "2026-08-14_18-59-37_MSK_fixture"
        идентификатор = "33333333-3333-4333-8333-333333333333"
        исполнитель = "/" + "root/audit_v3"
        путь = (
            f"Журнал/{ствол}/материалы/запуски-проверок/"
            f"1_{идентификатор}.json"
        )
        запись = {
            "схема": "fum.test-run.v3",
            "идентификатор": идентификатор,
            "сессия": f"Журнал/{ствол}/запрос.md",
            "порядок": 1,
            "исполнитель": исполнитель,
            "вызов": "Адресная проверка",
            "состояние": "завершён",
            "длительность_наносекунды": 1,
            "статус": "успешно",
            "код_завершения": 0,
            "пояснение": None,
            "план": None,
            "наблюдения": [],
            "профиль_проверки": {
                "класс": "адресная",
                "отпечаток_снимка": "sha256:" + "a" * 64,
                "полные_наборы": [],
                "основание": None,
                "идентификатор_отказа": None,
                "ожидаемое_свидетельство": None,
            },
        }
        текст = json.dumps(
            запись,
            ensure_ascii=False,
            sort_keys=True,
            indent=2,
        ) + "\n"

        сам.assertEqual(
            scanner._каноническая_запись_исполнителя(путь, текст),
            (ствол, исполнитель),
        )
        for название, мутация in (
            (
                "нет профиля",
                lambda значение: значение.pop("профиль_проверки"),
            ),
            (
                "лишнее поле",
                lambda значение: значение.update({"лишнее": None}),
            ),
        ):
            искажённая = dict(запись)
            мутация(искажённая)
            искажённый_текст = json.dumps(
                искажённая,
                ensure_ascii=False,
                sort_keys=True,
                indent=2,
            ) + "\n"
            with сам.subTest(мутация=название):
                сам.assertIsNone(
                    scanner._каноническая_запись_исполнителя(
                        путь,
                        искажённый_текст,
                    )
                )

    def test_narrow_system_fixture_url_and_gitignore_categories(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Инструменты/реестр-системных-приложений-и-инструментов.md",
                "`/usr/bin/git` и `/Applications/ChatGPT.app`\n",
            )
            себя.write_and_add(
                корень_сценария,
                "Инструменты/demo/scripts/tool.py",
                "#!/usr/bin/env python3\n",
            )
            себя.write_and_add(
                корень_сценария,
                "Инструменты/demo/tests/test_fixture.py",
                "ROOT = '/repo'\nURI = 'file://localhost/private/material.html'\n",
            )
            себя.write_and_add(
                корень_сценария,
                "Документация/url.md",
                "https://example.test/a/b\n",
            )
            (корень_сценария / ".gitignore").write_text(
                "ignored/\n/build/output/\n",
                encoding="utf-8",
            )

            fixture_lines = {
                "ROOT = '/repo'": "posix-absolute",
                "URI = 'file://localhost/private/material.html'": "file-uri",
            }
            policy = себя.write_policy(
                корень_сценария,
                [
                    {
                        "id": f"fixture-{index}",
                        "path": "Инструменты/demo/tests/test_fixture.py",
                        "kind": kind,
                        "line_sha256": "sha256:"
                        + hashlib.sha256(line.encode("utf-8")).hexdigest(),
                        "count": 1,
                        "category": "allow.test-fixture",
                        "reason": "Закрепляет точную автономную тестовую фикстуру без расширения области.",
                    }
                    for index, (line, kind) in enumerate(fixture_lines.items(), start=1)
                ],
            )

            результат_сценария = себя.scan(корень_сценария, policy)

            lines = результат_сценария.rendered_lines()
            себя.assertIn(
                "Инструменты/реестр-системных-приложений-и-инструментов.md:1:allow.system-runtime",
                lines,
            )
            себя.assertIn(
                "Инструменты/demo/scripts/tool.py:1:allow.system-runtime",
                lines,
            )
            себя.assertIn(
                "Инструменты/demo/tests/test_fixture.py:1:allow.test-fixture.posix-absolute",
                lines,
            )
            себя.assertIn(
                "Инструменты/demo/tests/test_fixture.py:2:allow.test-fixture.file-uri",
                lines,
            )
            себя.assertIn(".gitignore:2:allow.gitignore-anchor", lines)
            себя.assertFalse(
                any(line.startswith("Документация/url.md:") for line in lines)
            )
            себя.assertEqual(результат_сценария.exit_code, 0)

    def test_system_runtime_literal_in_first_party_code_is_rejected(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Инструменты/demo/scripts/tool.py",
                "COMMAND = '/usr/bin/git'\n",
            )

            результат_сценария = себя.scan(корень_сценария)

            себя.assertEqual(
                результат_сценария.rendered_lines(),
                ("Инструменты/demo/scripts/tool.py:1:error.system-runtime-hardcode",),
            )
            себя.assertEqual(результат_сценария.exit_code, 1)

    def test_registered_writing_subnode_runtime_literals_are_allowed(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            path = (
                "Прототипы/проверяемый-многоагентный-контур/Sources/"
                "FUMVerifiableMultiAgentContour/WritingSubnodeSystemRuntime.swift"
            )
            себя.write_and_add(
                корень_сценария,
                path,
                'let git = "/usr/bin/git"\nlet null = "/dev/null"\n',
            )

            результат_сценария = себя.scan(корень_сценария)

            себя.assertEqual(
                результат_сценария.rendered_lines(),
                (
                    f"{path}:1:allow.system-runtime",
                    f"{path}:2:allow.system-runtime",
                ),
            )
            себя.assertEqual(результат_сценария.exit_code, 0)

    def test_first_party_file_path_is_rejected_but_documented_reference_is_typed(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Прототипы/demo/Sources/App.swift",
                "let source = #filePath\nlet portable = #fileID\n",
            )
            себя.write_and_add(
                корень_сценария,
                "Документация/compiler.md",
                "Ограничение upstream связано с `#filePath`.\n",
            )

            результат_сценария = себя.scan(корень_сценария)

            себя.assertIn(
                "Прототипы/demo/Sources/App.swift:1:error.compiler-file-path",
                результат_сценария.rendered_lines(),
            )
            себя.assertIn(
                "Документация/compiler.md:1:report.compiler-file-path-reference",
                результат_сценария.rendered_lines(),
            )
            себя.assertEqual(результат_сценария.exit_code, 1)

    def test_exact_historical_exception_uses_line_hash_count_and_reason(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            line = "Историческое доказательство: /Users/example/work/FUM"
            relative = "Ревью/исторический-аудит.md"
            себя.write_and_add(корень_сценария, relative, line + "\n")
            fingerprint = "sha256:" + hashlib.sha256(line.encode("utf-8")).hexdigest()
            policy = себя.write_policy(
                корень_сценария,
                [
                    {
                        "id": "historical-audit-evidence",
                        "path": relative,
                        "kind": "posix-user-home",
                        "line_sha256": fingerprint,
                        "count": 1,
                        "category": "report.historical",
                        "reason": "Сохраняет доказательство прежнего аудита без расширения области.",
                    }
                ],
            )

            результат_сценария = себя.scan(корень_сценария, policy)

            себя.assertEqual(
                результат_сценария.rendered_lines(),
                (f"{relative}:1:report.historical.posix-user-home",),
            )
            себя.assertEqual(результат_сценария.exit_code, 0)

    def test_changed_or_unused_historical_exception_fails_closed(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            relative = "Ревью/исторический-аудит.md"
            себя.write_and_add(
                корень_сценария,
                relative,
                "Изменённое доказательство: /Users/example/work/FUM\n",
            )
            old_line = "Историческое доказательство: /Users/example/work/FUM"
            policy = себя.write_policy(
                корень_сценария,
                [
                    {
                        "id": "historical-audit-evidence",
                        "path": relative,
                        "kind": "posix-user-home",
                        "line_sha256": "sha256:"
                        + hashlib.sha256(old_line.encode("utf-8")).hexdigest(),
                        "count": 1,
                        "category": "report.historical",
                        "reason": "Сохраняет доказательство прежнего аудита без расширения области.",
                    }
                ],
            )

            результат_сценария = себя.scan(корень_сценария, policy)

            себя.assertIn(
                f"{relative}:1:error.posix-user-home",
                результат_сценария.rendered_lines(),
            )
            себя.assertIn(
                "policy.json:0:error.policy-count-mismatch",
                результат_сценария.rendered_lines(),
            )
            себя.assertEqual(результат_сценария.exit_code, 2)

    def test_policy_rejects_unknown_fields_wildcards_and_large_counts(себя) -> None:
        base = {
            "id": "bad-exception",
            "path": "Ревью/*.md",
            "kind": "posix-user-home",
            "line_sha256": "sha256:" + "a" * 64,
            "count": 17,
            "category": "allow.everything",
            "reason": "Намеренно невалидная слишком широкая тестовая запись.",
            "unknown": True,
        }

        with себя.assertRaises(scanner.PolicyError):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": [base],
                }
            )

    def test_policy_rejects_unknown_category(себя) -> None:
        exception = {
            "id": "unknown-category",
            "path": "Инструменты/demo/tests/test_fixture.py",
            "kind": "posix-absolute",
            "line_sha256": "sha256:" + "a" * 64,
            "count": 1,
            "category": "allow.arbitrary-directory",
            "reason": "Проверяет закрытый список типизированных категорий политики.",
        }

        with себя.assertRaisesRegex(scanner.PolicyError, "unsupported category"):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": [exception],
                }
            )

    def test_policy_rejects_duplicate_fingerprint_across_categories(себя) -> None:
        base = {
            "path": "Инструменты/demo/tests/test_fixture.py",
            "kind": "posix-absolute",
            "line_sha256": "sha256:" + "b" * 64,
            "count": 1,
            "reason": "Проверяет запрет неоднозначной повторной типизации одного отпечатка.",
        }
        exceptions = [
            {
                **base,
                "id": "duplicate-fixture",
                "category": "allow.test-fixture",
            },
            {
                **base,
                "id": "duplicate-definition",
                "category": "allow.path-validation-definition",
            },
        ]

        with себя.assertRaisesRegex(scanner.PolicyError, "duplicates a fingerprint"):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v2",
                    "exceptions": exceptions,
                }
            )

    def test_legacy_v1_policy_is_rejected(себя) -> None:
        with себя.assertRaisesRegex(scanner.PolicyError, "unsupported policy schema"):
            scanner.parse_policy(
                {
                    "schema": "fum.machine-local-path-policy.v1",
                    "exceptions": [],
                }
            )

    def test_exact_policy_preserves_definition_and_fixture_categories(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            cases = (
                (
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/example.py",
                    "PATTERN = '/custom/definition/path'",
                    "allow.path-validation-definition",
                ),
                (
                    "Инструменты/demo/tests/test_example.py",
                    "FIXTURE = '~alice/private/project'",
                    "allow.test-fixture",
                ),
                (
                    "Инструменты/demo/scripts/syntax.py",
                    "PATTERN = '~{3,}'",
                    "allow.nonpath-syntax",
                ),
            )
            exceptions = []
            for index, (relative, line, category) in enumerate(cases, start=1):
                себя.write_and_add(корень_сценария, relative, line + "\n")
                exceptions.append(
                    {
                        "id": f"typed-example-{index}",
                        "path": relative,
                        "kind": "posix-absolute"
                        if index == 1
                        else "home-expansion",
                        "line_sha256": "sha256:"
                        + hashlib.sha256(line.encode("utf-8")).hexdigest(),
                        "count": 1,
                        "category": category,
                        "reason": "Закрепляет одну точную строку определения или тестовой фикстуры.",
                    }
                )

            результат_сценария = себя.scan(корень_сценария, себя.write_policy(корень_сценария, exceptions))

            себя.assertEqual(
                результат_сценария.rendered_lines(),
                (
                    "Инструменты/demo/scripts/syntax.py:1:allow.nonpath-syntax.home-expansion",
                    "Инструменты/demo/tests/test_example.py:1:allow.test-fixture.home-expansion",
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/example.py:1:allow.path-validation-definition.posix-absolute",
                ),
            )
            себя.assertEqual(результат_сценария.exit_code, 0)

    def test_unfingerprinted_scanner_branch_and_test_literals_fail(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            cases = (
                (
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/regression.py",
                    "LEAK = '/custom/private/scanner-checkout'\n",
                    "error.posix-absolute",
                ),
                (
                    "Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py",
                    "LEAK = '$env:USERPROFILE\\branch-checkout'\n",
                    "error.home-expansion",
                ),
                (
                    "Инструменты/demo/tests/test_leak.py",
                    "LEAK = '//server/share/private-tests'\n",
                    "error.windows-unc",
                ),
                (
                    "Инструменты/demo/scripts/blockquote-leak.py",
                    "LEAK = '>/custom/private/checkout'\n",
                    "error.posix-absolute",
                ),
            )
            for relative, text, _category in cases:
                себя.write_and_add(корень_сценария, relative, text)

            результат_сценария = себя.scan(корень_сценария)

            себя.assertEqual(
                результат_сценария.rendered_lines(),
                tuple(
                    f"{relative}:1:{category}"
                    for relative, _text, category in sorted(cases)
                ),
            )
            себя.assertEqual(результат_сценария.exit_code, 1)

    def test_cli_returns_one_and_emits_only_stable_redacted_findings(себя) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог_сценария:
            корень_сценария = Path(временный_каталог_сценария)
            себя.init_repo(корень_сценария)
            себя.write_and_add(
                корень_сценария,
                "Документация/регрессия.md",
                "/Users/private-name/secret-project\n",
            )
            policy = себя.write_policy(корень_сценария)
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                exit_code = scanner.main(
                    [
                        "--repo-root",
                        str(корень_сценария),
                        "--policy",
                        str(policy),
                    ]
                )

            себя.assertEqual(exit_code, 1)
            себя.assertEqual(
                stdout.getvalue(),
                "Документация/регрессия.md:1:error.posix-user-home\n",
            )
            себя.assertEqual(stderr.getvalue(), "")
            себя.assertNotIn("private-name", stdout.getvalue())
            себя.assertNotIn("secret-project", stdout.getvalue())


ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ = (
    "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/вызов_нативной_подготовки.cjs",
    "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/сформировать_нативный_вызов.py",
    "Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_нативной_подготовки_базиса.py",
    "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/tests/test_сценариев_полного_ответа.py",
)


def сценарии_системных_литералов():
    """Независимые точные входы и oracle; таблица реализации не читается."""
    допустимые = ((0, "/bin/sh"), (1, "/usr/bin/env"), (2, "/bin/sh"),
                  (2, "/bin/bash"), (3, "/bin/sh"))
    сценарии = []
    for номер, литерал in допустимые:
        for кавычка in ("'", '"'):
            сценарии.append((ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[номер],
                f"значение = {кавычка}{литерал}{кавычка};", "allow.system-runtime"))
    for путь in ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ:
        сценарии.extend(((путь + ".копия", 'значение = "/bin/sh";', "error.system-runtime-hardcode"),
            (путь, 'значение = "/usr/bin/git";', "error.system-runtime-hardcode"),
            (путь, 'значение = "/Users/example/private";', "error.posix-user-home")))
    путь = ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[0]
    for строка in ('значение = "/bin/bash";', 'значение = "/bin/sh;";',
            'значение = "/bin/sh.evil";', 'значение = "/bin/sh" + ".evil";',
            'значение = "/bin/sh" ".evil";', 'значение = "/bin/" + "sh";',
            'значение = "/bin/sh', 'значение = r"/bin/sh";',
            'значение = f"/bin/sh";', 'значение = "/bin/sh".upper();',
            'значение = "/bin/sh" * 2;'):
        сценарии.append((путь, строка, "error.system-runtime-hardcode"))
    for строка in ('значение = ("/bin/sh") + ".evil";',
            'значение = (("/bin/sh")) + ".evil";',
            'значение = ("/bin/sh").upper();',
            'значение = ["/bin/sh"][0] + ".evil";'):
        сценарии.append((путь, строка, "error.system-runtime-hardcode"))
    сценарии.append((путь.replace("Инструменты/", "инструменты/", 1),
        'значение = "/bin/sh";', "error.system-runtime-hardcode"))
    основа = """',shell:"/bin/sh"'"""
    for продолжение in (' + ".evil"', '.upper()', '[0]'):
        сценарии.append((ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[3],
            "строка = " + основа + продолжение, "error.system-runtime-hardcode"))
    for строка in ("""строка = 'prefix' ',shell:"/bin/sh"'""",
            """строка = 'prefix' ',shell:' '"/bin/sh"'""",
            """строка = ('prefix' ',shell:"/bin/sh"')"""):
        сценарии.append((ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[3], строка, "error.system-runtime-hardcode"))
    return tuple(сценарии)


class СистемныеЛитералыНативногоМоста(unittest.TestCase):
    def test_точные_литералы_и_независимые_отказы(сам):
        for путь, строка, ожидаемая in сценарии_системных_литералов():
            with сам.subTest(путь=путь, строка=строка):
                записи = scanner.scan_text(путь, строка)
                сам.assertEqual([(з.path, з.line, з.category) for з in записи],
                    [(путь, 1, ожидаемая)])

    def test_соседний_приватный_путь_не_скрывается(сам):
        системный = "/bin/sh"
        приватный = "/Users/example/private"
        for путь in (ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[0], ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[2],
                ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[3]):
            записи = scanner.scan_text(путь,
                f'значение = ["{системный}", "{приватный}"];')
            сам.assertEqual([з.category for з in записи],
                ["allow.system-runtime", "error.posix-user-home"])

    def test_экранирование_не_получает_новый_допуск(сам):
        for строка in (r'значение = "\/bin/sh";', r'значение = "/bin\/sh";'):
            записи = scanner.scan_text(ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[0], строка)
            сам.assertTrue(записи)
            сам.assertTrue(all(з.category.startswith("error.") for з in записи))

    def test_перенос_не_скрывает_конкатенацию_и_смежный_литерал(сам):
        for строка in ('значение = ("/bin/sh"\n + ".evil");',
                'значение = ("/bin/sh"\n ".evil");',
                'значение = ("/bin/sh"\n # пояснение\n ".evil");'):
            записи = scanner.scan_text(ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[0], строка)
            сам.assertEqual([з.category for з in записи], ["error.system-runtime-hardcode"])

    def test_закрывающая_скобка_не_скрывает_продолжение(сам):
        for строка in ('значение = ("/bin/sh") + ".evil";',
                'значение = (("/bin/sh")) + ".evil";',
                'значение = ("/bin/sh").upper();',
                'значение = ["/bin/sh"][0] + ".evil";',
                'значение = (("/bin/sh")\n # пояснение\n + ".evil");'):
            записи = scanner.scan_text(ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[0], строка)
            сам.assertEqual([з.category for з in записи], ["error.system-runtime-hardcode"])

    def test_обязательные_настоящие_строки_моста_допускаются(сам):
        корень = Path(__file__).resolve().parents[3]
        значения = (("/bin/sh",), ("/usr/bin/env",), ("/bin/sh", "/bin/bash"), ("/bin/sh",))
        for путь, литералы in zip(ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ, значения):
            текст = (корень / путь).read_text()
            строки = текст.splitlines()
            выбранные = {номер for номер, строка in enumerate(строки, 1)
                if any(форма.value in литералы for форма in scanner.detect_path_forms(строка))}
            сам.assertTrue(выбранные)
            реальные = [з for з in scanner.scan_text(путь, текст) if з.line in выбранные
                and з.kind == "posix-absolute"]
            сам.assertTrue(реальные)
            сам.assertTrue(all(з.category == "allow.system-runtime" for з in реальные), путь)

    def test_внешняя_строка_фикстуры_тоже_не_вычисляется(сам):
        основа = """',shell:"/bin/sh"'"""
        for продолжение in (' + ".evil"', '.upper()', '[0]'):
            записи = scanner.scan_text(ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[3],
                "строка = " + основа + продолжение)
            сам.assertEqual([з.category for з in записи], ["error.system-runtime-hardcode"])

    def test_смежный_префикс_не_становится_одним_литералом_дерева(сам):
        for строка in ("""строка = 'prefix' ',shell:"/bin/sh"'""",
                """строка = 'prefix' ',shell:' '"/bin/sh"'""",
                """строка = ('prefix' ',shell:"/bin/sh"')"""):
            записи = scanner.scan_text(ФАЙЛЫ_СИСТЕМНЫХ_ЛИТЕРАЛОВ[3], строка)
            сам.assertEqual([з.category for з in записи], ["error.system-runtime-hardcode"])


МОМЕНТ_ЗАВЕРШЕНИЯ_ЗАГРУЗКИ = time.perf_counter_ns()


def хэши_проектного_контура():
    корень = Path(__file__).resolve().parents[3]
    результат = {}
    for модуль in tuple(sys.modules.values()):
        имя = getattr(модуль, "__file__", None)
        if not имя:
            continue
        файл = Path(имя).resolve()
        try:
            путь = файл.relative_to(корень).as_posix()
        except ValueError:
            continue
        if файл.is_file() and файл.suffix == ".py":
            результат[путь] = hashlib.sha256(файл.read_bytes()).hexdigest()
    return dict(sorted(результат.items()))


def измерить_классификацию(блоков):
    assert type(блоков) is int and 1 <= блоков <= 1000
    assert os.environ.get("FUM_CHECKED_CODE_ROOT") is None
    код_до = хэши_проектного_контура()
    подготовка = time.perf_counter_ns()
    группы = {}
    for путь, строка, категория in сценарии_системных_литералов():
        группы.setdefault(путь, []).append((строка, категория))
    корпуса = []
    for путь, строки in sorted(группы.items()):
        ожидаемые = []
        данные = []
        for повтор in range(блоков):
            for строка, категория in строки:
                данные.append(строка)
                ожидаемые.append((путь, len(данные), категория))
        текст = "\n".join(данные) + "\n"
        корпуса.append((путь, текст, ожидаемые))
    подготовка_нс = time.perf_counter_ns() - подготовка
    наблюдения = []
    for путь, текст, ожидаемые in корпуса:
        начало = time.perf_counter_ns()
        записи = scanner.scan_text(путь, текст)
        сканирование_нс = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        фактические = [(з.path, з.line, з.category) for з in записи]
        assert фактические == ожидаемые, (путь, len(фактические), len(ожидаемые))
        сверка_нс = time.perf_counter_ns() - начало
        байты_оракула = json.dumps(ожидаемые, ensure_ascii=False, separators=(",", ":")).encode()
        байты_результата = json.dumps(фактические, ensure_ascii=False, separators=(",", ":")).encode()
        наблюдения.append({"путь": путь, "байтов_входа": len(текст.encode()),
            "строк": len(ожидаемые), "записей": len(записи),
            "вход_sha256": hashlib.sha256(текст.encode()).hexdigest(),
            "оракул_sha256": hashlib.sha256(байты_оракула).hexdigest(),
            "результат_sha256": hashlib.sha256(байты_результата).hexdigest(),
            "сканирование_нс": сканирование_нс, "сверка_нс": сверка_нс})
    код_после = хэши_проектного_контура()
    assert код_до == код_после
    return {"схема": "fum.профиль-классификации-системных-литералов.1",
        "блоков": блоков, "версия_интерпретатора": sys.version,
        "интерпретатор_sha256": hashlib.sha256(Path(sys.executable).resolve().read_bytes()).hexdigest(),
        "код_sha256": код_до, "загрузка_модуля_нс": МОМЕНТ_ЗАВЕРШЕНИЯ_ЗАГРУЗКИ - МОМЕНТ_НАЧАЛА_ЗАГРУЗКИ,
        "подготовка_корпусов_нс": подготовка_нс, "корпуса": наблюдения}


def профиль_системных_литералов(аргументы):
    import argparse
    import statistics
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument("--профиль-системных-литералов", action="store_true")
    разбор.add_argument("--блоков", type=int, default=200)
    разбор.add_argument("--выход", required=True)
    параметры = разбор.parse_args(аргументы)
    if not 1 <= параметры.блоков <= 1000:
        разбор.error("нужно от одного до тысячи блоков")
    выход = Path(параметры.выход)
    if not выход.is_absolute() or not выход.parent.is_dir() or выход.exists():
        разбор.error("нужен новый абсолютный файл в существующем приватном каталоге")
    до = хэши_проектного_контура()
    запуски = []
    for номер in range(3):
        начало = time.perf_counter_ns()
        процесс = subprocess.run([sys.executable, "-I", "-S", "-B", str(Path(__file__).resolve()),
            "--воркер-системных-литералов", str(параметры.блоков)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120, check=True)
        внешнее_нс = time.perf_counter_ns() - начало
        assert not процесс.stderr
        наблюдение = json.loads(процесс.stdout)
        assert наблюдение["код_sha256"] == до
        assert наблюдение["блоков"] == параметры.блоков
        запуски.append({"номер": номер + 1, "внешнее_нс": внешнее_нс, "наблюдение": наблюдение})
    def подпись(наблюдение):
        return [(з["путь"], з["байтов_входа"], з["строк"], з["записей"],
            з["вход_sha256"], з["оракул_sha256"], з["результат_sha256"])
            for з in наблюдение["корпуса"]]
    первая = запуски[0]["наблюдение"]
    assert all(подпись(з["наблюдение"]) == подпись(первая) for з in запуски)
    assert all(з["наблюдение"]["интерпретатор_sha256"] == первая["интерпретатор_sha256"]
        and з["наблюдение"]["версия_интерпретатора"] == первая["версия_интерпретатора"] for з in запуски)
    assert до == хэши_проектного_контура()
    итог = {"схема": "fum.серия-профилей-системных-литералов.1", "запуски": запуски,
        "медиана_внешнего_нс": statistics.median(з["внешнее_нс"] for з in запуски),
        "полный_оракул_совпал": True, "ускорение_не_заявлено": True,
        "граница": "Три свежих процесса -I -S -B; подготовка данных отделена от scan_text; код и полные классификации сверены."}
    with выход.open("xb") as файл:
        файл.write((json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode())
        файл.flush()
        os.fsync(файл.fileno())
    выход.chmod(0o400)
    print(json.dumps({"запусков": 3, "корпусов": len(первая["корпуса"]),
        "записей": sum(з["записей"] for з in первая["корпуса"]),
        "медиана_внешнего_нс": итог["медиана_внешнего_нс"],
        "sha256": hashlib.sha256(выход.read_bytes()).hexdigest()}, ensure_ascii=False))


if __name__ == "__main__":
    if sys.argv[1:2] == ["--воркер-системных-литералов"]:
        assert len(sys.argv) == 3
        print(json.dumps(измерить_классификацию(int(sys.argv[2])), ensure_ascii=False))
    elif sys.argv[1:2] == ["--профиль-системных-литералов"]:
        профиль_системных_литералов(sys.argv[1:])
    else:
        unittest.main()
