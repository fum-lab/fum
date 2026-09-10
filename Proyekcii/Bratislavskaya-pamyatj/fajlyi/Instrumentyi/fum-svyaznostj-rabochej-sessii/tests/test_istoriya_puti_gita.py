"""Полная история точного пути не теряет промежуточные состояния и родителей."""
import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
import unicodedata
from pathlib import Path
from unittest import mock


def путь_проверяемой_реализации(путь: Path) -> Path:
    выбранный = os.environ.get("FUM_CHECKED_CODE_ROOT")
    if выбранный is None:
        return путь
    if not выбранный or not Path(выбранный).is_absolute():
        raise ValueError("корень проверяемой реализации должен быть явным абсолютным путём")
    return Path(выбранный) / путь.relative_to(Path(__file__).resolve().parents[3])


class ТестыИсторииПути(unittest.TestCase):
    def setUp(сам):
        среда = mock.patch.dict(os.environ, {"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull})
        среда.start()
        сам.addCleanup(среда.stop)
        временный = tempfile.TemporaryDirectory()
        сам.addCleanup(временный.cleanup)
        сам.корень = Path(временный.name)
        сам.гит("init", "-q")
        сам.гит("config", "user.name", "Проверка")
        сам.гит("config", "user.email", "fixture@example.invalid")
        сам.гит("commit", "--allow-empty", "-qm", "Источник")
        сам.источник = сам.гит("rev-parse", "HEAD").decode().strip()
        сам.путь = "Планирование/задачи/пример/обязательства.json"
        сценарии = путь_проверяемой_реализации(Path(__file__).resolve().parents[1] / "scripts")
        sys.path.insert(0, str(сценарии))
        сам.addCleanup(sys.path.remove, str(сценарии))
        описание = importlib.util.spec_from_file_location("история_для_теста", сценарии / "история_пути_гита.py")
        сам.модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(сам.модуль)

    def гит(сам, *аргументы, вход=None):
        return subprocess.run(["git", "-C", str(сам.корень), *аргументы], input=вход, check=True, capture_output=True).stdout

    def записать(сам, байты):
        путь = сам.корень / сам.путь
        путь.parent.mkdir(parents=True, exist_ok=True)
        if байты is None:
            путь.unlink()
        else:
            путь.write_bytes(байты)
        сам.гит("add", "-A")
        сам.гит("commit", "-qm", "Изменить реестр")
        return сам.гит("rev-parse", "HEAD").decode().strip()

    def прочитать(сам):
        return сам.модуль.прочитать_историю(сам.корень, сам.путь)

    def test_удаление_восстановление_и_неизменность_живых_файлов(сам):
        первый = сам.записать(b"{\"one\":1}\n")
        удаление = сам.записать(None)
        последний = сам.записать(b"{\"one\":1}\n")
        (сам.корень / сам.путь).write_bytes(b"dirty checkout")
        до = {str(п.relative_to(сам.корень)): (п.read_bytes(), п.stat().st_mode) for п in сам.корень.rglob("*") if п.is_file()}
        история = сам.прочитать()
        после = {str(п.relative_to(сам.корень)): (п.read_bytes(), п.stat().st_mode) for п in сам.корень.rglob("*") if п.is_file()}
        сам.assertEqual(до, после)
        сам.assertEqual(история["вершина"], последний)
        сам.assertEqual(история["версии"], {сам.источник: None, первый: b"{\"one\":1}\n", удаление: None, последний: b"{\"one\":1}\n"})
        сам.assertEqual(история["родители"][последний], [удаление])

    def test_сохраняются_все_родители_слияния(сам):
        первый = сам.записать(b"first")
        сам.гит("checkout", "--detach", "-q", сам.источник)
        второй = сам.записать(b"second")
        дерево = сам.гит("rev-parse", первый + "^{tree}").decode().strip()
        слияние = сам.гит("commit-tree", дерево, "-p", первый, "-p", второй, "-m", "Слияние").decode().strip()
        сам.гит("update-ref", "HEAD", слияние)
        история = сам.прочитать()
        сам.assertEqual(история["родители"][слияние], [первый, второй])
        сам.assertEqual(история["версии"][второй], b"second")

    def test_символическая_ссылка_и_дерево_вместо_реестра(сам):
        сам.записать(b"content")
        путь = сам.корень / сам.путь
        путь.unlink()
        путь.symlink_to("неизвестный")
        сам.гит("add", "-A")
        сам.гит("commit", "-qm", "Ссылка")
        with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
            сам.прочитать()

    def test_укороченная_история_отклоняется(сам):
        вершина = сам.записать(b"content")
        (сам.корень / ".git/shallow").write_text(вершина + "\n")
        with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
            сам.прочитать()

    def test_неверный_и_производный_путь_отклоняется(сам):
        for путь in (".", "../снаружи", "./файл", "Proyekcii/копия", "Планирование//файл", "Планирование/*", unicodedata.normalize("NFD", "учёт/обязательства.json"), "учёт/\u2028файл"):
            with сам.subTest(путь=путь), сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.модуль.прочитать_историю(сам.корень, путь)

    def test_двоичное_дерево_дубли_и_усечённый_идентификатор(сам):
        объект = bytes(range(20))
        запись = b"100644 " + "реестр".encode() + b"\0" + объект
        сам.assertEqual(сам.модуль.разобрать_дерево(запись, 20), {"реестр".encode(): ("100644", объект.hex())})
        for байты in (запись[:-1], запись + запись, b"100644 ..\0" + объект, b"40000 a/b\0" + объект):
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.модуль.разобрать_дерево(байты, 20)

    def заменить_узел(сам, объект, режим="100644"):
        части = сам.путь.split("/")
        for имя in reversed(части):
            дерево = режим.encode() + b" " + имя.encode() + b"\0" + bytes.fromhex(объект)
            объект = сам.гит("hash-object", "--literally", "-t", "tree", "-w", "--stdin", вход=дерево).decode().strip()
            режим = "40000"
        коммит = сам.гит("commit-tree", объект, "-p", сам.источник, "-m", "Проверить тип").decode().strip()
        сам.гит("update-ref", "HEAD", коммит)

    def test_неверные_фактические_типы_и_недоступные_объекты(сам):
        блоб = сам.гит("hash-object", "-w", "--stdin", вход=b"content").decode().strip()
        метка = сам.гит("hash-object", "--literally", "-t", "tag", "-w", "--stdin", вход=("object " + блоб + "\ntype blob\ntag fixture\n\nИсточник\n").encode()).decode().strip()
        for объект, режим in ((метка, "100644"), ("f" * 40, "100644"), (блоб, "40000"), (блоб, "160000")):
            сам.заменить_узел(объект, режим)
            with сам.subTest(объект=объект, режим=режим), сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.прочитать()

    def test_подмены_истории_и_смена_вершины_закрывают_чтение(сам):
        последний = сам.записать(b"content")
        подмены = сам.корень / ".git/info/grafts"
        подмены.write_bytes(b"")
        with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
            сам.прочитать()
        подмены.unlink()
        чтение = сам.модуль.выполнить_чтение_репозитория
        счётчик = 0
        def со_сменой(корень, *аргументы, **параметры):
            nonlocal счётчик
            if аргументы == ("rev-parse", "--verify", "HEAD"):
                счётчик += 1
                if счётчик == 2:
                    return (сам.источник + "\n").encode()
            return чтение(корень, *аргументы, **параметры)
        with mock.patch.object(сам.модуль, "выполнить_чтение_репозитория", со_сменой), сам.assertRaises(сам.модуль.ОшибкаОтчёта):
            сам.прочитать()
        сам.assertEqual(сам.гит("rev-parse", "HEAD").decode().strip(), последний)

    def test_искажённый_граф_и_родитель_в_теле_сообщения(сам):
        первый = сам.записать(b"content")
        сам.гит("commit", "--allow-empty", "-qm", "Содержимое\n\nparent " + "f" * 40)
        последний = сам.гит("rev-parse", "HEAD").decode().strip()
        сам.assertEqual(сам.прочитать()["родители"][последний], [первый])
        чтение = сам.модуль.выполнить_чтение_репозитория
        def с_пропуском(корень, *аргументы, **параметры):
            итог = чтение(корень, *аргументы, **параметры)
            if аргументы[:3] == ("rev-list", "--topo-order", "--parents"):
                return итог.replace((последний + " " + первый).encode(), последний.encode(), 1)
            return итог
        with mock.patch.object(сам.модуль, "выполнить_чтение_репозитория", с_пропуском), сам.assertRaises(сам.модуль.ОшибкаОтчёта):
            сам.прочитать()
