"""Регрессии узкого Git-перехода; высокий допуск проверяется отдельно читателем M."""
import importlib.util
import json
import os
import io
import contextlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

КОРЕНЬ_ИСХОДНИКОВ = Path(__file__).resolve().parents[3]
КОРЕНЬ_РЕАЛИЗАЦИИ = Path(os.environ.get("FUM_CHECKED_CODE_ROOT", str(КОРЕНЬ_ИСХОДНИКОВ)))
спецификация = importlib.util.spec_from_file_location("promotion", КОРЕНЬ_РЕАЛИЗАЦИИ / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/продвинуть_принятое_слияние.py")
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)


class Продвижение(unittest.TestCase):
    def setUp(сам):
        сам.временный_каталог = tempfile.TemporaryDirectory(prefix="fum-promotion-test-")
        сам.addCleanup(сам.временный_каталог.cleanup)
        сам.базовый_каталог = Path(сам.временный_каталог.name)
        сам.корень = сам.базовый_каталог / "repo"
        сам.корень.mkdir()
        сам.выполнить_команду_гита("init", "-b", "master")
        сам.выполнить_команду_гита("config", "user.name", "FUM Test")
        сам.выполнить_команду_гита("config", "user.email", "test@example.invalid")
        сам.выполнить_команду_гита("config", "commit.gpgsign", "false")
        (сам.корень / ".gitignore").write_text("*.tmp\n.DS_Store\n")
        (сам.корень / "a.txt").write_text("base\n")
        сам.выполнить_команду_гита("add", ".")
        сам.выполнить_команду_гита("commit", "-m", "base")
        сам.базовый_коммит = сам.вершина()
        сам.выполнить_команду_гита("checkout", "-b", "leading")
        (сам.корень / "b.txt").write_text("leading\n")
        сам.выполнить_команду_гита("add", ".")
        сам.выполнить_команду_гита("commit", "-m", "leading")
        сам.ведущая_вершина = сам.вершина()
        сам.выполнить_команду_гита("checkout", "master")
        (сам.корень / "a.txt").write_text("master\n")
        сам.выполнить_команду_гита("add", ".")
        сам.выполнить_команду_гита("commit", "-m", "master")
        сам.исходная_вершина = сам.вершина()
        сам.выполнить_команду_гита("checkout", "leading")
        сам.выполнить_команду_гита("merge", "--no-ff", "master", "-m", "candidate")
        сам.принятый_кандидат = сам.вершина()
        сам.выполнить_команду_гита("checkout", "master")
        сам.корень_транзакции = сам.базовый_каталог / "candidate"
        сам.выполнить_команду_гита("worktree", "add", "--detach", str(сам.корень_транзакции), сам.принятый_кандидат)
        сам.путь_намерения = сам.базовый_каталог / "intent.json"

    def выполнить_команду_гита(сам, *аргументы, данные=None):
        if данные is None:
            return модуль.выполнить_гит(сам.корень, *аргументы)
        return subprocess.run(модуль.команда_гита() + list(аргументы), cwd=сам.корень,
                              env=модуль.среда(), input=данные, capture_output=True,
                              check=True).stdout

    def вершина(сам):
        return модуль.идентификатор_объекта(сам.корень, "HEAD")

    def выполнить_переход(сам, обратный_вызов=lambda фаза: None):
        try:
            return модуль.перейти(сам.корень, сам.исходная_вершина, сам.ведущая_вершина, сам.принятый_кандидат, сам.путь_намерения, сам.корень_транзакции,
                                 наблюдатель=обратный_вызов)
        except модуль.Отказ as ошибка:
            if сам.путь_намерения.exists():
                ошибка.add_note(json.loads(сам.путь_намерения.read_text()).get("git_stderr", ""))
            raise

    def test_успех_и_повтор_без_записи(сам):
        (сам.корень / ".DS_Store").write_bytes(b"local")
        сам.assertEqual(сам.выполнить_переход()["состояние"], "завершено")
        прежние_байты = сам.путь_намерения.read_bytes()
        сам.assertEqual(сам.вершина(), сам.принятый_кандидат)
        модуль.проверить_копию(сам.корень, сам.принятый_кандидат)
        сам.assertEqual(сам.выполнить_переход()["состояние"], "уже_достигнуто")
        сам.assertEqual(сам.путь_намерения.read_bytes(), прежние_байты)
        сам.assertEqual((сам.корень / ".DS_Store").read_bytes(), b"local")

    def test_отслеживаемый_и_неотслеживаемый_хвост_запрещают_запись(сам):
        (сам.корень / "a.txt").write_text("human")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertFalse(сам.путь_намерения.exists())
        сам.assertEqual(сам.вершина(), сам.исходная_вершина)
        сам.assertEqual((сам.корень / "a.txt").read_text(), "human")
        (сам.корень / "a.txt").write_text("master\n")
        (сам.корень / "human.txt").write_text("new")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertFalse(сам.путь_намерения.exists())

    def test_скрытые_флаги_индекса(сам):
        for флаг, обратный_флаг in [("--assume-unchanged", "--no-assume-unchanged"),
                              ("--skip-worktree", "--no-skip-worktree")]:
            сам.выполнить_команду_гита("update-index", флаг, "a.txt")
            with сам.assertRaises(модуль.Отказ):
                сам.выполнить_переход()
            сам.выполнить_команду_гита("update-index", обратный_флаг, "a.txt")
        сам.assertEqual(сам.вершина(), сам.исходная_вершина)

    def test_смена_основной_ветки_до_транзакции(сам):
        def внести_гонку(фаза):
            if фаза == "до_транзакции":
                сам.выполнить_команду_гита("update-ref", "refs/heads/master", сам.базовый_коммит, сам.исходная_вершина)
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход(внести_гонку)
        сам.assertEqual(сам.вершина(), сам.базовый_коммит)
        сам.assertEqual((сам.корень / "a.txt").read_text(), "master\n")

    def test_смена_символической_вершины_до_транзакции(сам):
        сам.выполнить_команду_гита("branch", "other", сам.исходная_вершина)
        def внести_гонку(фаза):
            if фаза == "до_транзакции":
                сам.выполнить_команду_гита("symbolic-ref", "HEAD", "refs/heads/other")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход(внести_гонку)
        сам.assertEqual(сам.выполнить_команду_гита("symbolic-ref", "HEAD").strip(), b"refs/heads/other")
        сам.assertEqual(модуль.идентификатор_объекта(сам.корень, "master"), сам.исходная_вершина)

    def test_изменённая_после_предпроверки_цель_не_перезаписывается(сам):
        def внести_гонку(фаза):
            if фаза == "до_read_tree":
                (сам.корень / "b.txt").write_text("human")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход(внести_гонку)
        сам.assertEqual(сам.вершина(), сам.исходная_вершина)
        сам.assertEqual((сам.корень / "b.txt").read_text(), "human")

    def test_частичный_отказ_обновления_дерева_сохраняет_ссылку_и_данные(сам):
        исходная_функция = модуль.выполнить_гит
        def вызов_с_отказом(корень, *аргументы):
            if аргументы[:1] == ("read-tree",):
                (корень / "a.txt").write_text("partial")
                raise модуль.Отказ("injected read-tree failure")
            return исходная_функция(корень, *аргументы)
        with patch.object(модуль, "выполнить_гит", вызов_с_отказом), сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertEqual(сам.вершина(), сам.исходная_вершина)
        сам.assertEqual((сам.корень / "a.txt").read_text(), "partial")
        сам.assertEqual(json.loads(сам.путь_намерения.read_text())["состояние"], "требуется_разбор")

    def test_новый_хвост_после_фиксации_сохраняет_зафиксированную_ссылку(сам):
        def внести_гонку(фаза):
            if фаза == "после_commit":
                (сам.корень / "a.txt").write_text("human after commit")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход(внести_гонку)
        сам.assertEqual(сам.вершина(), сам.принятый_кандидат)
        сам.assertEqual((сам.корень / "a.txt").read_text(), "human after commit")

    def test_неопределённая_зафиксированная_транзакция_не_откатывается(сам):
        исходная_функция = модуль.ответ
        def неопределённый_ответ(процесс, фаза):
            исходная_функция(процесс, фаза)
            if фаза == b"commit":
                raise TimeoutError("injected lost acknowledgement")
        with patch.object(модуль, "ответ", неопределённый_ответ), сам.assertRaises(TimeoutError):
            сам.выполнить_переход()
        сам.assertEqual(сам.вершина(), сам.принятый_кандидат)
        модуль.проверить_копию(сам.корень, сам.принятый_кандидат)
        сам.assertEqual(сам.выполнить_переход()["состояние"], "уже_достигнуто")

    def test_атрибуты_цели_отклоняются(сам):
        исходная_функция = модуль.дерево
        def подменить_дерево(корень, ссылка):
            изменённое_дерево = исходная_функция(корень, ссылка)
            if ссылка == сам.принятый_кандидат:
                изменённое_дерево[".gitattributes"] = ("100644", "0" * 40)
            return изменённое_дерево
        with patch.object(модуль, "дерево", подменить_дерево), сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertEqual(сам.вершина(), сам.исходная_вершина)

    def test_регистровая_коллизия_игнорируемого_пути(сам):
        (сам.корень / ".git/info/exclude").write_text("B.TXT\n")
        (сам.корень / "B.TXT").write_text("human ignored")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertFalse(сам.путь_намерения.exists())
        сам.assertEqual((сам.корень / "B.TXT").read_text(), "human ignored")

    def test_повтор_требует_исходного_намерения(сам):
        сам.выполнить_переход()
        сам.путь_намерения.unlink()
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()

    def test_игнорируемые_атрибуты_отклоняются_до_фильтра(сам):
        (сам.корень / ".git/info/exclude").write_text(".gitattributes\n")
        (сам.корень / ".gitattributes").write_text("b.txt filter=danger\n")
        сам.выполнить_команду_гита("config", "filter.danger.smudge", "touch invoked; cat")
        сам.выполнить_команду_гита("config", "filter.danger.clean", "cat")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertFalse(сам.путь_намерения.exists())
        сам.assertFalse((сам.корень / "invoked").exists())
        (сам.корень / ".gitattributes").unlink()
        (сам.корень / ".git/info/exclude").write_text(".GITATTRIBUTES\n")
        (сам.корень / ".GITATTRIBUTES").write_text("b.txt filter=danger\n")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertFalse(сам.путь_намерения.exists())
        сам.assertFalse((сам.корень / "invoked").exists())

    def добавить_зависимость(сам):
        зависимость = сам.корень / "dep"
        зависимость.mkdir()
        модуль.выполнить_гит(зависимость, "init", "-b", "master")
        модуль.выполнить_гит(зависимость, "config", "user.name", "FUM Test")
        модуль.выполнить_гит(зависимость, "config", "user.email", "test@example.invalid")
        модуль.выполнить_гит(зависимость, "config", "commit.gpgsign", "false")
        (зависимость / "source.txt").write_text("source")
        модуль.выполнить_гит(зависимость, "add", ".")
        модуль.выполнить_гит(зависимость, "commit", "-m", "dependency")
        идентификатор_зависимости = модуль.идентификатор_объекта(зависимость, "HEAD")
        сам.выполнить_команду_гита("update-index", "--add", "--cacheinfo", "160000", идентификатор_зависимости, "dep")
        дерево_исходной_ветки = сам.выполнить_команду_гита("write-tree").decode().strip()
        сам.исходная_вершина = сам.выполнить_команду_гита("commit-tree", дерево_исходной_ветки, "-p", сам.исходная_вершина, "-m", "dependency").decode().strip()
        сам.выполнить_команду_гита("update-ref", "refs/heads/master", сам.исходная_вершина)
        сам.выполнить_команду_гита("read-tree", сам.принятый_кандидат)
        сам.выполнить_команду_гита("update-index", "--add", "--cacheinfo", "160000", идентификатор_зависимости, "dep")
        дерево_кандидата = сам.выполнить_команду_гита("write-tree").decode().strip()
        сам.принятый_кандидат = сам.выполнить_команду_гита("commit-tree", дерево_кандидата, "-p", сам.ведущая_вершина, "-p", сам.исходная_вершина, "-m", "merge dependency").decode().strip()
        сам.выполнить_команду_гита("reset", "--hard", сам.исходная_вершина)
        return зависимость

    def test_изменённая_зависимость_отклоняется(сам):
        зависимость = сам.добавить_зависимость()
        (зависимость / "source.txt").write_text("changed")
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertFalse(сам.путь_намерения.exists())
        сам.assertEqual((зависимость / "source.txt").read_text(), "changed")

    def test_символическая_ссылка_зависимости_отклоняется(сам):
        зависимость = сам.добавить_зависимость()
        внешний_каталог = сам.базовый_каталог / "materialized"
        зависимость.rename(внешний_каталог)
        зависимость.symlink_to(внешний_каталог, target_is_directory=True)
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertFalse(сам.путь_намерения.exists())
        сам.assertTrue(зависимость.is_symlink())

    def test_пустое_поддерево_отклоняется(сам):
        пустое_дерево = сам.выполнить_команду_гита("mktree", данные=b"").decode().strip()
        перечень = сам.выполнить_команду_гита("ls-tree", сам.принятый_кандидат) + ("040000 tree " + пустое_дерево + "\tempty\n").encode()
        новое_дерево = сам.выполнить_команду_гита("mktree", данные=перечень).decode().strip()
        сам.принятый_кандидат = сам.выполнить_команду_гита("commit-tree", новое_дерево, "-p", сам.ведущая_вершина, "-p", сам.исходная_вершина, "-m", "empty tree").decode().strip()
        with сам.assertRaises(модуль.Отказ):
            сам.выполнить_переход()
        сам.assertEqual(сам.вершина(), сам.исходная_вершина)
        сам.assertFalse(сам.путь_намерения.exists())

    def аргументы_команды(сам):
        return ["продвинуть-master.py", "--корень", str(сам.корень), "--M", сам.исходная_вершина,
                "--L", сам.ведущая_вершина, "--C", сам.принятый_кандидат, "--intent", str(сам.путь_намерения),
                "--кандидат", str(сам.корень_транзакции), "--запрос", "Журнал/test/запрос.md"]

    def test_команда_отклоняет_отсутствие_доверенного_читателя(сам):
        with patch.object(модуль.sys, "argv", сам.аргументы_команды()), сам.assertRaises(модуль.Отказ):
            модуль.главная()
        сам.assertFalse(сам.путь_намерения.exists())
        сам.assertEqual(сам.вершина(), сам.исходная_вершина)

    def test_повтор_команды_не_перезагружает_читателя_кандидата(сам):
        сам.выполнить_переход()
        прежние_байты = сам.путь_намерения.read_bytes()
        вывод = io.StringIO()
        with patch.object(модуль.sys, "argv", сам.аргументы_команды()), contextlib.redirect_stdout(вывод):
            модуль.главная()
        сам.assertEqual(json.loads(вывод.getvalue())["состояние"], "уже_достигнуто")
        сам.assertEqual(сам.путь_намерения.read_bytes(), прежние_байты)

    def test_вершина_заблокирована_во_время_обновления_дерева(сам):
        сам.выполнить_команду_гита("branch", "other", сам.исходная_вершина)
        def проверить_блокировку(фаза):
            if фаза == "до_read_tree":
                with сам.assertRaises(модуль.Отказ):
                    сам.выполнить_команду_гита("symbolic-ref", "HEAD", "refs/heads/other")
        сам.assertEqual(сам.выполнить_переход(проверить_блокировку)["состояние"], "завершено")
        сам.assertEqual(сам.выполнить_команду_гита("symbolic-ref", "HEAD").strip(), b"refs/heads/master")

    def test_журнал_ссылок_сохраняет_настроенную_глобальную_идентичность(сам):
        сам.выполнить_команду_гита("config", "--unset", "user.name")
        сам.выполнить_команду_гита("config", "--unset", "user.email")
        (сам.базовый_каталог / ".gitconfig").write_text("[user]\n name = FUM Global Test\n email = global@example.invalid\n")
        with patch.dict(os.environ, {"HOME": str(сам.базовый_каталог), "XDG_CONFIG_HOME": str(сам.базовый_каталог / "xdg")}):
            сам.assertEqual(сам.выполнить_переход()["состояние"], "завершено")
        строка = (сам.корень / ".git/logs/refs/heads/master").read_text().splitlines()[-1]
        сам.assertTrue("FUM Global Test <global@example.invalid>" in строка)


if __name__ == "__main__":
    unittest.main()
