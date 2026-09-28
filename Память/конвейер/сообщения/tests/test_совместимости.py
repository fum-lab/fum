"""Адресные проверки неизменных сообщений и закреплённых событий пилота."""

import copy
import importlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


КОРЕНЬ = Path(__file__).resolve().parents[4]
КАТАЛОГ = КОРЕНЬ / "Память/конвейер/сообщения"
БАЗА = "fde24399d912d530f9f359b8022f8e40fb7c151d"
ПРЕЖНИЙ = "daa53209ebafe4208e26e70953d5adf8ad4a7b12"
СОБЫТИЯ = "f2b0b806f6c4b89a4c626ad40cd5e900df794ad7"
ДЕРЕВО = "0803a525c791fb5856ed437977b536f7a2f9886c"
ВХОД = "Журнал/2026-09-24_22-51-12_MSK_поставить-пилот-с-читателем-ответов/материалы/постановка/вход.jsonl"
ИМЕНА = ("README.md", "значимые-сообщения.jsonl", "связи-происхождения.json")


def вызвать_гит(корень, *аргументы, вход=None):
    return subprocess.run(
        ["git", "-C", str(корень), *аргументы], input=вход,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
    ).stdout


def байты_объекта(значение):
    return (json.dumps(значение, ensure_ascii=False) + "\n").encode()


def байты_строк(записи):
    return b"".join(байты_объекта(запись) for запись in записи)


class Совместимость(unittest.TestCase):
    def setUp(self):
        sys.path.insert(0, str(КАТАЛОГ))
        self.проверяющий = importlib.import_module("проверка_совместимости")
        self.временный = tempfile.TemporaryDirectory(prefix="fum-совместимость-")
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        вызвать_гит(self.корень, "init", "--quiet")
        объекты = вызвать_гит(КОРЕНЬ, "rev-parse", "--path-format=absolute", "--git-path", "objects").decode().strip()
        (self.корень / ".git/objects/info/alternates").write_text(объекты + "\n")
        self.файлы = {}
        for имя in ИМЕНА:
            относительный = "Память/конвейер/сообщения/" + имя
            путь = self.корень / относительный
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_bytes(вызвать_гит(КОРЕНЬ, "show", БАЗА + ":" + относительный))
            путь.chmod(0o644)
            self.файлы[имя] = путь
        self.вход = вызвать_гит(КОРЕНЬ, "show", БАЗА + ":" + ВХОД)
        self.поток = вызвать_гит(КОРЕНЬ, "show", СОБЫТИЯ + ":Память/конвейер/события/поток.jsonl")
        self.свидетельство = вызвать_гит(КОРЕНЬ, "show", СОБЫТИЯ + ":Память/конвейер/события/свидетельство.json")
        self.сообщения = self.файлы["значимые-сообщения.jsonl"].read_bytes()
        self.связи = self.файлы["связи-происхождения.json"].read_bytes()
        self.исходники = {
            запись["исходник"]["путь"]: вызвать_гит(КОРЕНЬ, "show", БАЗА + ":" + запись["исходник"]["путь"])
            for запись in map(json.loads, self.вход.splitlines())
        }

    def проверить(self, **замены):
        параметры = dict(корень=self.корень, база=БАЗА, прежний=ПРЕЖНИЙ,
                         события=СОБЫТИЯ, дерево=ДЕРЕВО, файлы=self.файлы)
        параметры.update(замены)
        return self.проверяющий.проверить(**параметры)

    def отказ(self, действие):
        with self.assertRaises(self.проверяющий.Несовместимость):
            действие()

    def сверить(self, сообщения=None, связи=None, исходники=None):
        return self.проверяющий.сверить_записи(
            self.вход, self.сообщения if сообщения is None else сообщения,
            self.связи if связи is None else связи,
            self.исходники if исходники is None else исходники,
        )

    def test_принятые_данные_и_профиль(self):
        результат = self.проверить()
        self.assertEqual(результат["сравнения"]["записей"], 7)
        self.assertEqual(результат["сравнения"]["диапазонов"], 7)
        self.assertEqual(результат["поток"]["байтов"], 5790)
        self.assertEqual(set(результат["профиль_наносекунды"]), {"чтение_Git", "сверка", "весь_проход"})
        self.assertTrue(all(type(число) is int and число >= 0 for число in результат["профиль_наносекунды"].values()))

    def test_изменение_каждого_прежнего_файла(self):
        for имя, путь in self.файлы.items():
            with self.subTest(файл=имя):
                байты = путь.read_bytes()
                путь.write_bytes(байты + b" ")
                self.отказ(self.проверить)
                путь.write_bytes(байты)

    def test_изменение_режима_каждого_файла(self):
        for имя, путь in self.файлы.items():
            with self.subTest(файл=имя):
                путь.chmod(0o755)
                self.отказ(self.проверить)
                путь.chmod(0o644)

    def test_символическая_ссылка_и_недостающий_файл(self):
        путь = self.файлы["README.md"]
        байты = путь.read_bytes()
        путь.unlink()
        self.отказ(self.проверить)
        иной = self.корень / "копия.md"
        иной.write_bytes(байты)
        путь.symlink_to(иной)
        self.отказ(self.проверить)

    def test_чужие_коммиты_и_дерево(self):
        for поле, значение in (("база", ПРЕЖНИЙ), ("прежний", БАЗА),
                                ("события", ПРЕЖНИЙ), ("дерево", БАЗА),
                                ("события", "0" * 40), ("события", "HEAD")):
            with self.subTest(поле=поле, значение=значение):
                self.отказ(lambda: self.проверить(**{поле: значение}))

    def коммит_событий(self, поток=None, свидетельство=None, родители=(БАЗА,)):
        файлы = {"поток.jsonl": self.поток if поток is None else поток,
                 "свидетельство.json": self.свидетельство if свидетельство is None else свидетельство}
        строки = []
        for имя, байты in файлы.items():
            объект = вызвать_гит(self.корень, "hash-object", "-w", "--stdin", вход=байты).decode().strip()
            строки.append("100644 blob " + объект + "\t" + имя + "\n")
        дерево = вызвать_гит(self.корень, "mktree", вход="".join(строки).encode()).decode().strip()
        for имя in ("события", "конвейер", "Память"):
            дерево = вызвать_гит(self.корень, "mktree", вход=("040000 tree " + дерево + "\t" + имя + "\n").encode()).decode().strip()
        команда = ["git", "-C", str(self.корень), "commit-tree", дерево]
        for родитель in родители:
            команда.extend(("-p", родитель))
        среда = os.environ | {"GIT_AUTHOR_NAME": "Тест", "GIT_AUTHOR_EMAIL": "test@example.invalid",
                             "GIT_COMMITTER_NAME": "Тест", "GIT_COMMITTER_EMAIL": "test@example.invalid"}
        объект = subprocess.run(команда, input=b"test\n", env=среда, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout.decode().strip()
        return объект, дерево

    def test_отказ_неверным_родителям(self):
        for родители in ((), (ПРЕЖНИЙ,), (БАЗА, ПРЕЖНИЙ)):
            with self.subTest(родители=родители):
                объект, дерево = self.коммит_событий(родители=родители)
                self.отказ(lambda: self.проверить(события=объект, дерево=дерево))

    def test_повреждение_потока_из_Git(self):
        строки = self.поток.splitlines(keepends=True)
        варианты = (self.поток + b" ", self.поток[:-1], b"".join(строки[1:]),
                    b"".join([строки[1], строки[0], *строки[2:]]),
                    b"".join([строки[0], строки[0], *строки[2:]]), self.поток + строки[0])
        for вариант in варианты:
            with self.subTest(байтов=len(вариант)):
                объект, дерево = self.коммит_событий(поток=вариант)
                self.отказ(lambda: self.проверить(события=объект, дерево=дерево))

    def test_повреждение_точного_свидетельства(self):
        исходное = json.loads(self.свидетельство)
        for поле in исходное:
            повреждённое = copy.deepcopy(исходное)
            повреждённое[поле] = 0 if type(повреждённое[поле]) is int else "ошибка"
            with self.subTest(поле=поле):
                объект, дерево = self.коммит_событий(свидетельство=байты_объекта(повреждённое))
                self.отказ(lambda: self.проверить(события=объект, дерево=дерево))
        for байты in (b"{", self.свидетельство.replace(b"5790", b"5790.0"),
                      self.свидетельство.replace(b"5790", b"true"),
                      self.свидетельство.replace(b"{", '{"схема":"подмена",'.encode(), 1),
                      байты_объекта(исходное | {"лишнее": True})):
            self.отказ(lambda: self.проверяющий.сверить_поток(self.вход, self.поток, байты))

    def test_порядок_пропуски_дубликаты_и_лишние_сообщения(self):
        записи = list(map(json.loads, self.сообщения.splitlines()))
        for вариант in (записи[1:], [записи[1], записи[0], *записи[2:]],
                        [записи[0], записи[0], *записи[2:]], записи + [записи[0]]):
            self.отказ(lambda: self.сверить(байты_строк(вариант)))

    def test_текст_Unicode_и_пробелы(self):
        записи = list(map(json.loads, self.сообщения.splitlines()))
        for номер in range(7):
            for суффикс in (" ", "ё", "е\u0308", "\u200b", "\n"):
                вариант = copy.deepcopy(записи)
                вариант[номер]["текст"] += суффикс
                with self.subTest(номер=номер, суффикс=repr(суффикс)):
                    self.отказ(lambda: self.сверить(байты_строк(вариант)))

    def test_идентичность_роль_номер_и_класс(self):
        записи = list(map(json.loads, self.сообщения.splitlines()))
        for номер in range(7):
            for поле, значение in (("идентичность", "иной"), ("роль", "иная"),
                                    ("номер", номер + 2), ("номер", True), ("вид", "иной")):
                вариант = copy.deepcopy(записи)
                вариант[номер][поле] = значение
                with self.subTest(номер=номер, поле=поле):
                    self.отказ(lambda: self.сверить(байты_строк(вариант)))

    def test_полный_объект_происхождения(self):
        записи = list(map(json.loads, self.сообщения.splitlines()))
        for номер in range(7):
            for поле in записи[номер]["исходник"]:
                вариант = copy.deepcopy(записи)
                del вариант[номер]["исходник"][поле]
                with self.subTest(номер=номер, поле=поле):
                    self.отказ(lambda: self.сверить(байты_строк(вариант)))
            вариант = copy.deepcopy(записи)
            вариант[номер]["исходник"]["лишнее"] = False
            self.отказ(lambda: self.сверить(байты_строк(вариант)))

    def test_ложь_строго_boolean(self):
        записи = list(map(json.loads, self.сообщения.splitlines()))
        for номер in range(7):
            for значение in (0, 0.0, None, "false", True):
                вариант = copy.deepcopy(записи)
                вариант[номер]["исполнение_доказано"] = значение
                with self.subTest(номер=номер, значение=repr(значение)):
                    self.отказ(lambda: self.сверить(байты_строк(вариант)))

    def test_необязательный_номер_при_сохранении_точен(self):
        записи = list(map(json.loads, self.сообщения.splitlines()))
        for запись in записи:
            del запись["номер"]
        self.assertEqual(self.сверить(байты_строк(записи))["записей"], 7)

    def test_исходные_диапазоны_и_LF_ответа(self):
        for путь, байты in self.исходники.items():
            повреждённые = self.исходники | {путь: b" " + байты}
            self.отказ(lambda: self.сверить(исходники=повреждённые))
        ответы = next(путь for путь in self.исходники if путь.endswith(".jsonl"))
        self.отказ(lambda: self.сверить(исходники=self.исходники | {ответы: self.исходники[ответы].replace(b"\n", b" ", 1)}))
        self.отказ(lambda: self.сверить(исходники={}))

    def test_связи_происхождения_точны(self):
        исходное = json.loads(self.связи)
        for вариант in (исходное | {"поток_sha256": "0" * 64}, исходное | {"лишнее": 1},
                        исходное | {"идентичности": list(reversed(исходное["идентичности"]))}):
            self.отказ(lambda: self.сверить(связи=байты_объекта(вариант)))

    def test_повторный_ключ_и_неполная_строка(self):
        for вариант in (self.сообщения[:-1], self.сообщения + b"\n",
                        self.сообщения.replace(b"{", '{"номер":999,'.encode(), 1)):
            self.отказ(lambda: self.сверить(вариант))

    def test_ложная_успешная_квитанция_не_обходит_сверку(self):
        путь = self.корень / "Память/конвейер/сообщения/квитанция-совместимости.json"
        путь.write_bytes(байты_объекта({"схема": "fum.совместимость-сообщений-пилота.1", "успешно": True}))
        self.файлы["значимые-сообщения.jsonl"].write_bytes(b"{}\n")
        self.отказ(self.проверить)

    def test_повторная_сверка_не_читает_квитанцию(self):
        первый = self.проверить()
        второй = self.проверить()
        self.assertEqual(первый["сравнения"], второй["сравнения"])
        self.assertEqual(первый["файлы"], второй["файлы"])

    def test_в_проходе_нет_повторных_чтений_объектов(self):
        исходный = self.проверяющий.ЧитательGit.выполнить
        обращения = []
        def наблюдать(читатель, *аргументы):
            if аргументы[0] == "show":
                обращения.append(аргументы[-1])
            return исходный(читатель, *аргументы)
        with patch.object(self.проверяющий.ЧитательGit, "выполнить", наблюдать):
            self.проверить()
        self.assertEqual(len(обращения), len(set(обращения)))

    def test_сдвиг_живого_ref_проверяется_отдельно(self):
        ref = "refs/heads/codex/проверка-сдвига"
        вызвать_гит(self.корень, "update-ref", ref, СОБЫТИЯ)
        def наблюдение(читатель, *аргументы):
            if аргументы[:2] == ("remote", "get-url"):
                return b"https://github.com/fum-lab/fum.git\n"
            if аргументы[0] == "ls-remote":
                return (СОБЫТИЯ + "\t" + ref + "\n").encode()
            return исходный(читатель, *аргументы)
        исходный = self.проверяющий.ЧитательGit.выполнить
        with patch.object(self.проверяющий.ЧитательGit, "выполнить", наблюдение):
            self.проверяющий.сверить_закрепление(self.корень, ref, СОБЫТИЯ, ДЕРЕВО, "https://github.com/fum-lab/fum.git")
            вызвать_гит(self.корень, "update-ref", ref, ПРЕЖНИЙ)
            self.отказ(lambda: self.проверяющий.сверить_закрепление(self.корень, ref, СОБЫТИЯ, ДЕРЕВО, "https://github.com/fum-lab/fum.git"))


if __name__ == "__main__":
    unittest.main()
