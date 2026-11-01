"""Чтение точных Git-входов не даёт полномочий записи в их каталоги."""
from contextlib import contextmanager
import hashlib
from pathlib import Path
import runpy
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import отложенные_назначения as назначения
import приём_направления as хранение

ХЭШ_МОДУЛЯ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


def гит(корень, *аргументы):
    return subprocess.check_output(
        ["git", "-c", "core.hooksPath=", "-C", str(корень), *аргументы],
        stderr=subprocess.PIPE,
    ).decode().strip()


@contextmanager
def снимок_фикстуры():
    with TemporaryDirectory(prefix="fum-input-manifest-") as каталог:
        корень = Path(каталог)
        гит(корень, "init", "-q")
        гит(корень, "config", "user.name", "Фикстура")
        гит(корень, "config", "user.email", "fixture@example.invalid")
        данные = {
            "Журнал/пилот/постановка.json": b"{}\n",
            "Память/конвейер/сообщения/README.md": "# Принятые сообщения\n".encode(),
            "Память/конвейер/сообщения/значимые-сообщения.jsonl": b'{"id":1}\n',
            "Память/конвейер/сообщения/связи-происхождения.json": b"{}\n",
            "Приложения/FUMA/Sources/Вход.swift": "// Точный исходник\n".encode(),
            **{f"Журнал/пилот/материалы/вход-{номер}.json": f"{номер}\n".encode()
               for номер in range(5)},
        }
        for имя, байты in данные.items():
            путь = корень / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_bytes(байты)
        гит(корень, "add", ".")
        гит(корень, "commit", "-qm", "Открытая фикстура входов")
        коммит = гит(корень, "rev-parse", "HEAD")
        файлы = {имя: hashlib.sha256(байты).hexdigest() for имя, байты in данные.items()}
        yield корень, коммит, файлы, данные


class ПроверкаМанифестаВходныхФайлов(unittest.TestCase):
    def test_полный_набор_с_принятыми_сообщениями_читается_без_записи(проверка):
        with снимок_фикстуры() as (корень, коммит, файлы, данные):
            до = гит(корень, "status", "--porcelain=v1", "--untracked-files=all")
            проверка.assertEqual(данные, назначения.манифест_коммита(корень, коммит, файлы))
            проверка.assertEqual(до, гит(корень, "status", "--porcelain=v1", "--untracked-files=all"))

    def test_исторический_коммит_читается_при_грязном_и_продвинутом_checkout(проверка):
        with снимок_фикстуры() as (корень, коммит, файлы, данные):
            имя = "Память/конвейер/сообщения/README.md"
            (корень / имя).write_text("# Более позднее содержимое\n")
            гит(корень, "add", имя)
            гит(корень, "commit", "-qm", "Поздний снимок")
            (корень / имя).write_text("# Незакоммиченные данные\n")
            до = гит(корень, "status", "--porcelain=v1")
            проверка.assertEqual(данные, назначения.манифест_коммита(корень, коммит, файлы))
            проверка.assertEqual(до, гит(корень, "status", "--porcelain=v1"))

    def test_неканонический_путь_отклоняется_до_git_lookup(проверка):
        with снимок_фикстуры() as (корень, коммит, файлы, данные):
            for имя in ("", ".", "../README.md", "/README.md", "./Журнал/пилот/постановка.json",
                        "Журнал//пилот/постановка.json", "Журнал/../пилот/постановка.json", "вход\0.json", None, True):
                with проверка.subTest(имя=имя), mock.patch.object(назначения, "гит", wraps=назначения.гит) as чтение:
                    with проверка.assertRaises(хранение.ОшибкаПриёма):
                        назначения.манифест_коммита(корень, коммит, {имя: "0" * 64})
                    проверка.assertFalse(any(вызов.args[1] == "ls-tree" for вызов in чтение.call_args_list))

    def test_неверные_коммит_хэш_и_отсутствующий_файл_отклоняются(проверка):
        with снимок_фикстуры() as (корень, коммит, файлы, данные):
            имя = "Память/конвейер/сообщения/README.md"
            for состав in ({имя: "f" * 64}, {имя: "некорректный"}, {}, {"Память/нет.md": "0" * 64}):
                with проверка.subTest(состав=состав), проверка.assertRaises(хранение.ОшибкаПриёма):
                    назначения.манифест_коммита(корень, коммит, состав)
            with проверка.assertRaises(хранение.ОшибкаПриёма):
                назначения.манифест_коммита(корень, "f" * 40, файлы)
            with проверка.assertRaisesRegex(хранение.ОшибкаПриёма, "Изменён исходный blob"):
                назначения.манифест_коммита(корень, коммит, {имя: "f" * 64})

    def test_ссылка_дерево_и_gitlink_не_выдаются_за_обычный_blob(проверка):
        with снимок_фикстуры() as (корень, коммит, файлы, данные):
            цель = "Память/конвейер/сообщения/README.md"
            (корень / "ссылка").symlink_to(цель)
            (корень / "ссылка-каталог").symlink_to("Память/конвейер/сообщения", target_is_directory=True)
            гит(корень, "add", "ссылка", "ссылка-каталог")
            гит(корень, "update-index", "--add", "--cacheinfo", "160000," + коммит + ",внешняя-зависимость")
            гит(корень, "commit", "-qm", "Необычные режимы")
            иной = гит(корень, "rev-parse", "HEAD")
            for имя in ("ссылка", "ссылка-каталог/README.md", "Память", "внешняя-зависимость"):
                with проверка.subTest(имя=имя), проверка.assertRaises(хранение.ОшибкаПриёма):
                    отпечаток = hashlib.sha256(цель.encode()).hexdigest() if имя == "ссылка" else "0" * 64
                    назначения.манифест_коммита(корень, иной, {имя: отпечаток})

    def test_исполняемый_обычный_blob_разрешён_как_вход(проверка):
        with снимок_фикстуры() as (корень, коммит, файлы, данные):
            имя = "Инструменты/пример/вход.py"
            путь = корень / имя
            путь.parent.mkdir(parents=True)
            байты = b"print(1)\n"
            путь.write_bytes(байты)
            путь.chmod(0o755)
            гит(корень, "add", имя)
            гит(корень, "commit", "-qm", "Обычный исполняемый вход")
            иной = гит(корень, "rev-parse", "HEAD")
            проверка.assertEqual({имя: байты}, назначения.манифест_коммита(
                корень, иной, {имя: hashlib.sha256(байты).hexdigest()}))

    def test_чтение_входа_не_расширяет_права_записи_результата(проверка):
        with проверка.assertRaises(хранение.ОшибкаПриёма):
            хранение.путь_результата("Память/конвейер/сообщения/README.md")

    def test_профиль_отклоняет_подменённый_загрузочный_отпечаток(проверка):
        import профиль_манифеста_входных_файлов as профиль
        with mock.patch.object(назначения, "ХЭШ_МОДУЛЯ", "0" * 64):
            with проверка.assertRaisesRegex(RuntimeError, "Изменён код профиля"):
                профиль.выполнить(1)

    def test_профиль_не_приписывает_старой_фикстуре_хэш_нового_файла(проверка):
        with TemporaryDirectory(prefix="fum-profile-code-") as каталог:
            корень = Path(каталог)
            имя = "профиль_манифеста_входных_файлов.py"
            (корень / имя).write_bytes(Path(__file__).with_name(имя).read_bytes())
            (корень / Path(__file__).name).write_bytes(Path(__file__).read_bytes() + b"\n# Changed fixture\n")
            # Уже импортированный helper остаётся прежним; соседний файл отличается.
            профиль = runpy.run_path(str(корень / имя))
            with проверка.assertRaisesRegex(RuntimeError, "Изменён код профиля"):
                профиль["выполнить"](1)


if __name__ == "__main__":
    unittest.main()
