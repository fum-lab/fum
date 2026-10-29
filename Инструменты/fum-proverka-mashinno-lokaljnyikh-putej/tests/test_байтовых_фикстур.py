import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import types
import unittest
from unittest import mock
from pathlib import Path


def путь_проверяемой_реализации(путь: Path) -> Path:
    выбранный = os.environ.get("FUM_CHECKED_CODE_ROOT")
    if выбранный is None:
        return путь
    if not выбранный or not Path(выбранный).is_absolute():
        raise ValueError("корень проверяемой реализации должен быть явным абсолютным путём")
    return Path(выбранный) / путь.relative_to(Path(__file__).resolve().parents[3])


КАТАЛОГ = Path(__file__).resolve().parents[1]
СЦЕНАРИИ = путь_проверяемой_реализации(КАТАЛОГ / "scripts")
if str(СЦЕНАРИИ) not in sys.path:
    sys.path.insert(0, str(СЦЕНАРИИ))


def загрузить(имя: str, файл: str):
    описание = importlib.util.spec_from_file_location(имя, СЦЕНАРИИ / файл)
    модуль = importlib.util.module_from_spec(описание)
    assert описание.loader is not None
    sys.modules[имя] = модуль
    описание.loader.exec_module(модуль)
    return модуль


def загрузить_профиль():
    путь = Path(__file__).with_name("профиль_байтовых_фикстур.py")
    описание = importlib.util.spec_from_file_location(
        "проверка_профиля_байтовых_фикстур",
        путь,
    )
    модуль = importlib.util.module_from_spec(описание)
    assert описание.loader is not None
    sys.modules[описание.name] = модуль
    описание.loader.exec_module(модуль)
    return модуль


сканер = загрузить("проверка_байтовых_фикстур", "proveritj-mashinno-lokaljnyiye-puti.py")
обновитель = загрузить("обновление_байтовых_фикстур", "obnovitj-policy.py")


class ПроверкиБайтовыхФикстур(unittest.TestCase):
    ПУТЬ = "fixtures/incomplete.jsonl"
    ПРИЧИНА = (
        "Закрепляет точную продуктовую фикстуру с намеренно оборванным "
        "UTF-8-хвостом без расширения области допуска."
    )

    def инициализировать_репозиторий(сам, корень: Path) -> None:
        subprocess.run(
            ["git", "init", "-q"],
            cwd=корень,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        (корень / ".gitignore").write_text("ignored/\n", encoding="utf-8")
        subprocess.run(["git", "add", ".gitignore"], cwd=корень, check=True)

    def записать_байты(
        сам,
        корень: Path,
        данные: bytes,
        *,
        путь: str | None = None,
        исполняемый: bool = False,
    ) -> Path:
        относительный = путь or сам.ПУТЬ
        файл = корень / относительный
        файл.parent.mkdir(parents=True, exist_ok=True)
        файл.write_bytes(данные)
        if исполняемый:
            файл.chmod(0o755)
        subprocess.run(["git", "add", относительный], cwd=корень, check=True)
        return файл

    def запись(
        сам,
        данные: bytes,
        *,
        путь: str | None = None,
        идентификатор: str = "incomplete-jsonl-tail",
    ) -> dict[str, object]:
        префикс = len(данные) - 2
        return {
            "идентификатор": идентификатор,
            "путь": путь or сам.ПУТЬ,
            "режим": "100644",
            "размер": len(данные),
            "хэш": "sha256:" + hashlib.sha256(данные).hexdigest(),
            "вид": "неполный-хвост-UTF-8",
            "размер_префикса": префикс,
            "шестнадцатеричный_хвост": данные[префикс:].hex(),
            "категория": "allow.test-fixture",
            "причина": сам.ПРИЧИНА,
        }

    def заявка(сам, *, идентификатор: str = "incomplete-jsonl-tail") -> dict[str, object]:
        return {
            "идентификатор": идентификатор,
            "путь": сам.ПУТЬ,
            "вид": "неполный-хвост-UTF-8",
            "категория": "allow.test-fixture",
            "причина": сам.ПРИЧИНА,
        }

    def записать_политику(
        сам,
        корень: Path,
        записи: list[dict[str, object]],
        *,
        схема: str = "fum.machine-local-path-policy.v4",
    ) -> Path:
        значение: dict[str, object] = {
            "schema": схема,
            "exceptions": [],
            "метаданные": [],
        }
        if схема == "fum.machine-local-path-policy.v4":
            значение["байтовые_фикстуры"] = записи
        политика = корень / "policy.json"
        политика.write_text(
            json.dumps(значение, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return политика

    def test_точная_фикстура_допускается_а_префикс_сканируется(сам) -> None:
        машинный_путь = b"".join(
            (bytes([47]), b"Users/private/work\n")
        )
        for префикс, ожидаемый_код in (
            (b"clean\n", 0),
            (машинный_путь, 1),
        ):
            with сам.subTest(префикс=префикс), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                сам.инициализировать_репозиторий(корень)
                данные = префикс + b"\xf0\x9f"
                сам.записать_байты(корень, данные)
                политика = сам.записать_политику(корень, [сам.запись(данные)])

                результат = сканер.scan_repository(корень, политика)
                строки = результат.rendered_lines()

                сам.assertEqual(результат.exit_code, ожидаемый_код)
                сам.assertIn(
                    f"{сам.ПУТЬ}:0:allow.test-fixture.неполный-хвост-UTF-8",
                    строки,
                )
                if ожидаемый_код:
                    сам.assertIn(f"{сам.ПУТЬ}:1:error.posix-user-home", строки)

    def test_любое_расхождение_точного_отпечатка_закрывает_политику(сам) -> None:
        исходные = b"clean\n\xf0\x9f"
        случаи = {
            "изменённый-байт": (b"glean\n\xf0\x9f", {}, False),
            "изменённый-размер": (b"clean!\n\xf0\x9f", {}, False),
            "изменённый-хэш": (исходные, {"хэш": "sha256:" + "0" * 64}, False),
            "изменённый-хвост": (исходные, {"шестнадцатеричный_хвост": "f09e"}, False),
            "исполняемый-режим": (исходные, {}, True),
            "nul": (b"clean\0\xf0\x9f", {}, False),
            "корректный-UTF-8": (b"clean\nOK", {}, False),
            "иной-не-utf8": (b"clean\n\xff\xff", {}, False),
        }
        for имя, (фактические, изменения, исполняемый) in случаи.items():
            with сам.subTest(имя=имя), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                сам.инициализировать_репозиторий(корень)
                сам.записать_байты(корень, фактические, исполняемый=исполняемый)
                политика = сам.записать_политику(
                    корень,
                    [{**сам.запись(исходные), **изменения}],
                )
                результат = сканер.scan_repository(корень, политика)
                сам.assertEqual(результат.exit_code, 2)
                сам.assertIn(
                    "policy.json:0:error.несовпадение-байтовой-фикстуры-политики",
                    результат.rendered_lines(),
                )

    def test_отсутствие_символическая_ссылка_и_лишний_файл_неправильной_кодировки_не_скрываются(сам) -> None:
        исходные = b"clean\n\xf0\x9f"
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.инициализировать_репозиторий(корень)
            политика = сам.записать_политику(корень, [сам.запись(исходные)])
            результат = сканер.scan_repository(корень, политика)
            сам.assertEqual(результат.exit_code, 2)
            сам.assertIn(
                "policy.json:0:error.несовпадение-байтовой-фикстуры-политики",
                результат.rendered_lines(),
            )

        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.инициализировать_репозиторий(корень)
            цель = корень / "target.bin"
            цель.write_bytes(исходные)
            ссылка = корень / сам.ПУТЬ
            ссылка.parent.mkdir(parents=True)
            ссылка.symlink_to(цель)
            subprocess.run(["git", "add", сам.ПУТЬ], cwd=корень, check=True)
            политика = сам.записать_политику(корень, [сам.запись(исходные)])
            результат = сканер.scan_repository(корень, политика)
            сам.assertEqual(результат.exit_code, 2)
            сам.assertIn(f"{сам.ПУТЬ}:0:error.tracked-symlink", результат.rendered_lines())

        with (
            tempfile.TemporaryDirectory() as временный,
            tempfile.TemporaryDirectory() as внешний_временный,
        ):
            корень = Path(временный)
            сам.инициализировать_репозиторий(корень)
            сам.записать_байты(корень, исходные)
            политика = сам.записать_политику(корень, [сам.запись(исходные)])
            внешний_каталог = Path(внешний_временный) / "fixtures"
            (корень / "fixtures").rename(внешний_каталог)
            (корень / "fixtures").symlink_to(
                внешний_каталог,
                target_is_directory=True,
            )
            результат = сканер.scan_repository(корень, политика)
            сам.assertEqual(результат.exit_code, 2)
            сам.assertIn(
                f"{сам.ПУТЬ}:0:error.символический-компонент-пути-входа",
                результат.rendered_lines(),
            )

        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.инициализировать_репозиторий(корень)
            сам.записать_байты(корень, исходные)
            сам.записать_байты(корень, b"extra\xff", путь="fixtures/extra.bin")
            политика = сам.записать_политику(корень, [сам.запись(исходные)])
            результат = сканер.scan_repository(корень, политика)
            сам.assertEqual(результат.exit_code, 2)
            сам.assertIn("fixtures/extra.bin:0:error.non-utf8-input", результат.rendered_lines())

    def test_четвёртая_версия_отклоняет_дубликаты_неизвестные_поля_и_неполный_контракт(сам) -> None:
        данные = b"clean\n\xf0\x9f"
        запись = сам.запись(данные)
        основа = {
            "schema": "fum.machine-local-path-policy.v4",
            "exceptions": [],
            "метаданные": [],
            "байтовые_фикстуры": [запись],
        }
        случаи = (
            ({**основа, "байтовые_фикстуры": [запись, запись]}, "повтор"),
            ({**основа, "байтовые_фикстуры": [запись, сам.запись(данные, идентификатор="other-tail")]}, "повтор"),
            ({**основа, "байтовые_фикстуры": [{**запись, "неизвестное": True}]}, "fields"),
            ({**основа, "байтовые_фикстуры": [{ключ: значение for ключ, значение in запись.items() if ключ != "хэш"}]}, "fields"),
            ({**основа, "байтовые_фикстуры": [{**запись, "путь": "fixtures/cafe\u0301"}]}, "NFC"),
        )
        for значение, сообщение in случаи:
            with сам.subTest(сообщение=сообщение):
                with сам.assertRaisesRegex(сканер.PolicyError, сообщение):
                    сканер.parse_policy(значение)

    def test_политики_второй_и_третьей_версий_остаются_совместимыми(сам) -> None:
        прежняя_запись = {
            "id": "legacy-nfd",
            "path": "fixtures/cafe\u0301.txt",
            "kind": "posix-absolute",
            "line_sha256": "sha256:" + "a" * 64,
            "count": 1,
            "category": "allow.test-fixture",
            "reason": "Сохраняет совместимость прежней политики с NFD-путём.",
        }
        политика_второй_версии = сканер.parse_policy(
            {
                "schema": "fum.machine-local-path-policy.v2",
                "exceptions": [прежняя_запись],
            }
        )
        политика_третьей_версии = сканер.parse_policy(
            {
                "schema": "fum.machine-local-path-policy.v3",
                "exceptions": [прежняя_запись],
                "метаданные": [],
            }
        )
        сам.assertEqual(политика_второй_версии.байтовые_фикстуры, ())
        сам.assertEqual(политика_третьей_версии.байтовые_фикстуры, ())
        сам.assertEqual(политика_второй_версии.exceptions[0].path, прежняя_запись["path"])
        сам.assertEqual(политика_третьей_версии.exceptions[0].path, прежняя_запись["path"])

    def test_обновитель_выводит_четвёртую_версию_идемпотентно_и_требует_точную_отмену(сам) -> None:
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.инициализировать_репозиторий(корень)
            исходные = b"clean\n\xf0\x9f"
            файл = сам.записать_байты(корень, исходные)
            политика = сам.записать_политику(
                корень,
                [],
                схема="fum.machine-local-path-policy.v3",
            )
            заявка = сам.заявка()

            сам.assertEqual(
                обновитель.update_policy(корень, политика, [], байтовые_фикстуры=[заявка]),
                1,
            )
            значение = json.loads(политика.read_text(encoding="utf-8"))
            сам.assertEqual(значение["schema"], "fum.machine-local-path-policy.v4")
            сам.assertEqual(значение["байтовые_фикстуры"], [сам.запись(исходные)])
            до = политика.read_bytes()
            метка = политика.stat()
            сам.assertEqual(
                обновитель.update_policy(корень, политика, [], байтовые_фикстуры=[заявка]),
                0,
            )
            сам.assertEqual(политика.read_bytes(), до)
            сам.assertEqual(политика.stat().st_ino, метка.st_ino)
            сам.assertEqual(политика.stat().st_mtime_ns, метка.st_mtime_ns)

            новые = b"other\n\xf0\x9f"
            файл.write_bytes(новые)
            subprocess.run(["git", "add", сам.ПУТЬ], cwd=корень, check=True)
            with сам.assertRaisesRegex(обновитель.UpdateError, "коллизия идентификатора"):
                обновитель.update_policy(корень, политика, [], байтовые_фикстуры=[заявка])
            сам.assertEqual(
                обновитель.update_policy(
                    корень,
                    политика,
                    [],
                    байтовые_фикстуры=[заявка],
                    отмены_байтовых_фикстур=[сам.запись(исходные)],
                ),
                2,
            )
            новая_запись = сам.запись(новые)
            сам.assertEqual(
                json.loads(политика.read_text(encoding="utf-8"))["байтовые_фикстуры"],
                [новая_запись],
            )
            после_замены = политика.read_bytes()
            метка_после_замены = политика.stat()
            сам.assertEqual(
                обновитель.update_policy(
                    корень,
                    политика,
                    [],
                    байтовые_фикстуры=[заявка],
                    отмены_байтовых_фикстур=[сам.запись(исходные)],
                ),
                0,
            )
            сам.assertEqual(политика.read_bytes(), после_замены)
            сам.assertEqual(политика.stat().st_ino, метка_после_замены.st_ino)
            сам.assertEqual(политика.stat().st_mtime_ns, метка_после_замены.st_mtime_ns)
            сам.assertEqual(
                обновитель.update_policy(
                    корень,
                    политика,
                    [],
                    байтовые_фикстуры=[заявка],
                    отмены_байтовых_фикстур=[новая_запись],
                ),
                0,
            )

            третьи = b"third\n\xf0\x9f"
            файл.write_bytes(третьи)
            subprocess.run(["git", "add", сам.ПУТЬ], cwd=корень, check=True)
            with сам.assertRaisesRegex(обновитель.UpdateError, "отмена байтовой фикстуры"):
                обновитель.update_policy(
                    корень,
                    политика,
                    [],
                    байтовые_фикстуры=[заявка],
                    отмены_байтовых_фикстур=[сам.запись(исходные)],
                )
            сам.assertEqual(политика.read_bytes(), после_замены)

            сам.assertEqual(
                обновитель.update_policy(
                    корень,
                    политика,
                    [],
                    отмены_байтовых_фикстур=[новая_запись],
                ),
                1,
            )
            сам.assertEqual(
                json.loads(политика.read_text(encoding="utf-8"))["байтовые_фикстуры"],
                [],
            )

    def test_обновитель_отказывает_неподходящим_байтам_режиму_и_пути(сам) -> None:
        случаи = (
            ("корректный-UTF-8", b"clean\n", True, False, "неполной UTF-8"),
            ("nul", b"clean\0\xf0\x9f", True, False, "NUL"),
            ("иная-ошибка", b"clean\xff", True, False, "неполной UTF-8"),
            ("исполняемый", b"clean\xf0\x9f", True, True, "Git-режим 100644"),
            ("неиндексированный", b"clean\xf0\x9f", False, False, "Git-режим 100644"),
        )
        for имя, данные, добавить, исполняемый, сообщение in случаи:
            with сам.subTest(имя=имя), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                сам.инициализировать_репозиторий(корень)
                файл = корень / сам.ПУТЬ
                файл.parent.mkdir(parents=True)
                файл.write_bytes(данные)
                if исполняемый:
                    файл.chmod(0o755)
                if добавить:
                    subprocess.run(["git", "add", сам.ПУТЬ], cwd=корень, check=True)
                политика = сам.записать_политику(
                    корень,
                    [],
                    схема="fum.machine-local-path-policy.v3",
                )
                исходная = политика.read_bytes()
                with сам.assertRaisesRegex(обновитель.UpdateError, сообщение):
                    обновитель.update_policy(
                        корень,
                        политика,
                        [],
                        байтовые_фикстуры=[сам.заявка()],
                    )
                сам.assertEqual(политика.read_bytes(), исходная)

        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.инициализировать_репозиторий(корень)
            цель = корень / "target.bin"
            цель.write_bytes(b"clean\xf0\x9f")
            ссылка = корень / сам.ПУТЬ
            ссылка.parent.mkdir(parents=True)
            ссылка.symlink_to(цель)
            subprocess.run(["git", "add", сам.ПУТЬ], cwd=корень, check=True)
            политика = сам.записать_политику(
                корень,
                [],
                схема="fum.machine-local-path-policy.v3",
            )
            with сам.assertRaisesRegex(обновитель.UpdateError, "символическую ссылку"):
                обновитель.update_policy(
                    корень,
                    политика,
                    [],
                    байтовые_фикстуры=[сам.заявка()],
                )

    def test_обновитель_повторно_сверяет_байты_перед_заменой_политики(сам) -> None:
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.инициализировать_репозиторий(корень)
            исходные = b"clean\n\xf0\x9f"
            файл = сам.записать_байты(корень, исходные)
            политика = сам.записать_политику(
                корень,
                [],
                схема="fum.machine-local-path-policy.v3",
            )
            исходная_политика = политика.read_bytes()
            настоящая_запись = обновитель._atomic_write

            def изменить_перед_заменой(путь, содержимое, ожидаемое, *, проверить_источники=None):
                файл.write_bytes(b"changed\n\xf0\x9f")
                return настоящая_запись(
                    путь,
                    содержимое,
                    ожидаемое,
                    проверить_источники=проверить_источники,
                )

            with mock.patch.object(
                обновитель,
                "_atomic_write",
                изменить_перед_заменой,
            ):
                with сам.assertRaisesRegex(
                    обновитель.UpdateError,
                    "источник байтовой фикстуры изменился",
                ):
                    обновитель.update_policy(
                        корень,
                        политика,
                        [],
                        байтовые_фикстуры=[сам.заявка()],
                    )
            сам.assertEqual(политика.read_bytes(), исходная_политика)

    def test_манифест_четвёртой_версии_разделяет_текстовые_и_байтовые_изменения(сам) -> None:
        with tempfile.TemporaryDirectory() as временный:
            манифест = Path(временный) / "manifest.json"
            манифест.write_text(
                json.dumps(
                    {
                        "schema": "fum.machine-local-path-policy-update.v4",
                        "declarations": [],
                        "retirements": [],
                        "метаданные": [],
                        "байтовые_фикстуры": [сам.заявка()],
                        "отмены_байтовых_фикстур": [],
                    },
                    ensure_ascii=False,
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )
            план = обновитель.load_update_plan(манифест)
            сам.assertEqual(len(план.байтовые_фикстуры), 1)
            сам.assertEqual(план.отмены_байтовых_фикстур, ())
            with сам.assertRaisesRegex(обновитель.UpdateError, "NFC"):
                обновитель._разобрать_заявки_байтовых_фикстур(
                    [{**сам.заявка(), "путь": "fixtures/cafe\u0301.txt"}]
                )

    def test_профиль_не_перезаписывает_существующий_выход(сам) -> None:
        профиль = загрузить_профиль()
        with tempfile.TemporaryDirectory() as временный:
            выход = Path(временный) / "профиль.json"
            исходные = b"already saved\n"
            выход.write_bytes(исходные)
            метка = выход.stat()
            with (
                mock.patch.object(
                    sys,
                    "argv",
                    ["профиль", "--выход", str(выход), "--повторов", "1"],
                ),
                mock.patch.object(профиль, "измерить") as измерение,
                сам.assertRaises(SystemExit),
            ):
                профиль.основная()
            измерение.assert_not_called()
            сам.assertEqual(выход.read_bytes(), исходные)
            сам.assertEqual(выход.stat().st_ino, метка.st_ino)
            сам.assertEqual(выход.stat().st_mtime_ns, метка.st_mtime_ns)

    def test_профиль_закрыто_отказывает_при_гонке_создания_выхода(сам) -> None:
        профиль = загрузить_профиль()
        with tempfile.TemporaryDirectory() as временный:
            выход = Path(временный) / "профиль.json"
            байты_гонки = b"race winner\n"

            def создать_гонку(_мегабайт):
                выход.write_bytes(байты_гонки)
                return {"вход_байт": 1}

            with (
                mock.patch.object(
                    sys,
                    "argv",
                    ["профиль", "--выход", str(выход), "--повторов", "1"],
                ),
                mock.patch.object(профиль, "измерить", side_effect=создать_гонку),
                сам.assertRaises(FileExistsError),
            ):
                профиль.основная()
            сам.assertEqual(выход.read_bytes(), байты_гонки)

    @unittest.skipUnless(
        os.environ.get("FUM_OLD_CHECKER_REVISION"),
        "нужен явный OID прежнего проверяющего",
    )
    def test_прежний_проверяющий_закрыто_отклоняет_четвёртую_версию(сам) -> None:
        корень = Path(__file__).resolve().parents[3]
        ревизия = os.environ["FUM_OLD_CHECKER_REVISION"]
        пути = (
            ("path_forms", "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/path_forms.py"),
            ("request_folder_layout", "Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py"),
            ("метаданные_наблюдений", "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/метаданные_наблюдений.py"),
            ("прежний_проверяющий_путей", "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/proveritj-mashinno-lokaljnyiye-puti.py"),
        )
        отсутствует = object()
        прежние = {имя: sys.modules.get(имя, отсутствует) for имя, _ in пути}
        try:
            for имя, путь in пути:
                исходник = subprocess.check_output(
                    ["git", "-C", str(корень), "show", f"{ревизия}:{путь}"]
                )
                модуль = types.ModuleType(имя)
                модуль.__file__ = str(корень / путь)
                sys.modules[имя] = модуль
                exec(compile(исходник, модуль.__file__, "exec"), модуль.__dict__)
            прежний = sys.modules["прежний_проверяющий_путей"]
            with сам.assertRaises(прежний.PolicyError):
                прежний.parse_policy(
                    {
                        "schema": "fum.machine-local-path-policy.v4",
                        "exceptions": [],
                        "метаданные": [],
                        "байтовые_фикстуры": [],
                    }
                )
        finally:
            for имя, модуль in прежние.items():
                if модуль is отсутствует:
                    sys.modules.pop(имя, None)
                else:
                    sys.modules[имя] = модуль


if __name__ == "__main__":
    unittest.main()
