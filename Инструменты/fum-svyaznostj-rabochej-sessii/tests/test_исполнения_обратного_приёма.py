"""Лабораторный эффект: настоящий Git, синтетический независимый допуск."""
import hashlib
import importlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import unittest
from unittest.mock import patch

import test_наблюдения_обратного_приёма as фикстура
import test_контракта_обратного_приёма as контрактная_фикстура


class ИсполнениеОбратногоПриёма(unittest.TestCase):
    гит = фикстура.НаблюдениеОбратногоПриёма.гит
    ветка = фикстура.НаблюдениеОбратногоПриёма.ветка

    def setUp(self):
        фикстура.НаблюдениеОбратногоПриёма.setUp(self)
        пример = контрактная_фикстура.ОбратныйПриём()
        пример.setUp()
        with patch.dict(os.environ, self.среда, clear=True):
            наблюдение = фикстура.наблюдатель.снять_состояние(
                self.корень, self.получатель, self.источник)
        пример.заявка.update(получатель=self.получатель, источник=self.источник)
        пример.наблюдение.update(получатель=self.получатель, источник=self.источник,
                                разница_sha256=наблюдение["разница_sha256"])
        пример.проверка.update(кандидат=self.кандидат, дерево=self.источник["дерево"])
        пример.ревью.update(основа=self.основа, кандидат=self.кандидат,
                           дерево=self.источник["дерево"], разница_sha256=наблюдение["разница_sha256"])
        self.план = пример.вызов()
        self.каталог = self.корень.parent / "операция"
        self.каталог.mkdir(mode=0o700)
        self.сообщение = "Принять подготовленный результат\n".encode()
        self.автор = ["FUM Codex [gpt-6-astra; effort=ultra]", "test@example.invalid", "1792540000", "+0300"]
        self.коммиттер = ["FUM", "test@example.invalid", "1792540000", "+0300"]
        self.число_сверок = 0

    def допуск(self):
        self.число_сверок += 1

    def вызов(self, имя="применить", допуск=None):
        модуль = importlib.import_module("исполнение_обратного_приёма")
        with patch.dict(os.environ, self.среда, clear=True):
            return getattr(модуль, имя)(self.корень, self.план, self.каталог,
                                       self.сообщение, self.автор, self.коммиттер,
                                       сверить_основание=допуск or self.допуск)

    def test_один_merge_точные_родители_и_дерево_без_нового_worktree(self):
        деревья = self.гит("worktree", "list", "--porcelain")
        результат = self.вызов()
        self.assertEqual(результат["родители"], [self.основа, self.кандидат])
        self.assertEqual(результат["дерево"], self.источник["дерево"])
        self.assertEqual(результат["сообщение_sha256"], hashlib.sha256(self.сообщение).hexdigest())
        self.assertEqual(self.гит("rev-list", "--count", self.кандидат + "..HEAD").strip(), b"1")
        self.assertEqual(self.гит("status", "--porcelain"), b"")
        self.assertEqual(len(деревья.split(b"worktree ")), len(self.гит("worktree", "list", "--porcelain").split(b"worktree ")))
        self.assertGreater(self.число_сверок, 1)

    def test_повтор_без_новой_записи(self):
        результат = self.вызов()
        до = {п.name: п.read_bytes() for п in self.каталог.iterdir()}
        self.assertEqual(self.вызов("повтор"), результат)
        self.assertEqual(до, {п.name: п.read_bytes() for п in self.каталог.iterdir()})
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), результат["коммит"])

    def test_отказ_допуска_до_эффекта(self):
        def запрет():
            raise ValueError("Нет выбранного ревью")
        with self.assertRaisesRegex(ValueError, "ревью"):
            self.вызов(допуск=запрет)
        self.assertEqual(list(self.каталог.iterdir()), [])
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)

    def test_грязь_до_эффекта(self):
        (self.корень / "лишний").write_text("поздний ввод")
        with self.assertRaisesRegex(ValueError, "нечист"):
            self.вызов()
        self.assertEqual(list(self.каталог.iterdir()), [])

    def test_bare_каталог_операции_отклоняется_до_эффекта(self):
        bare = self.корень.parent / "хранилище.git"
        subprocess.run(["git", "init", "--bare", str(bare)], env=self.среда,
                       capture_output=True, check=True)
        self.каталог = bare / "операция"
        self.каталог.mkdir(mode=0o700)
        индекс = (self.корень / ".git/index").read_bytes()
        for имя in ("применить", "повтор"):
            with self.subTest(операция=имя):
                with self.assertRaisesRegex(ValueError, "вне Git"):
                    self.вызов(имя)
                self.assertEqual(list(self.каталог.iterdir()), [])
                self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)
                self.assertEqual((self.корень / ".git/index").read_bytes(), индекс)
                self.assertFalse((self.корень / ".git/MERGE_HEAD").exists())

    def test_прерывание_после_merge_не_перезапускается(self):
        модуль = importlib.import_module("исполнение_обратного_приёма")
        with patch.object(модуль, "проверить_готовое_слияние", side_effect=ValueError("Прервано после merge")):
            with self.assertRaisesRegex(ValueError, "после merge"):
                self.вызов()
        for имя in ("применить", "повтор"):
            with self.assertRaises(ValueError):
                self.вызов(имя)
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)
        self.assertEqual((self.корень / ".git/MERGE_HEAD").read_text().strip(), self.кандидат)

    def test_подмена_сообщения_при_повторе(self):
        self.вызов()
        self.сообщение = b"different\n"
        with self.assertRaises(ValueError):
            self.вызов("повтор")

    def test_hook_не_исполняется(self):
        след = self.корень.parent / "побочный-эффект"
        хук = self.корень / ".git/hooks/pre-commit"
        оболочка = shutil.which("sh")
        self.assertIsNotNone(оболочка)
        хук.write_text("#!" + оболочка + "\ntouch '" + str(след) + "'\n")
        хук.chmod(0o755)
        with self.assertRaisesRegex(ValueError, "hook"):
            self.вызов()
        self.assertFalse(след.exists())
        self.assertFalse((self.корень / ".git/MERGE_HEAD").exists())

    def test_повтор_в_новом_процессе(self):
        результат = self.вызов()
        вход = self.корень.parent / "вход.json"
        вход.write_text(json.dumps({"корень": str(self.корень), "план": self.план,
            "каталог": str(self.каталог), "сообщение": self.сообщение.decode(),
            "автор": self.автор, "коммиттер": self.коммиттер}))
        программа = ("import sys,json; sys.path.insert(0,sys.argv[1]); "
                     "import исполнение_обратного_приёма as модуль; "
                     "данные=json.load(open(sys.argv[2])); "
                     "данные['сообщение']=данные['сообщение'].encode(); "
                     "print(json.dumps(модуль.повтор(**данные,сверить_основание=lambda:None)))")
        до = {п.name: п.read_bytes() for п in self.каталог.iterdir()}
        процесс = subprocess.run([sys.executable, "-E", "-s", "-S", "-B", "-c", программа,
            str(Path(__file__).resolve().parents[1] / "scripts"), str(вход)],
            env=self.среда, capture_output=True, check=True)
        self.assertEqual(json.loads(процесс.stdout), результат)
        self.assertEqual(до, {п.name: п.read_bytes() for п in self.каталог.iterdir()})

    def test_неизвестный_исход_после_commit_не_повторяется(self):
        модуль = importlib.import_module("исполнение_обратного_приёма")
        with patch.object(модуль, "_конечное_состояние", side_effect=ValueError("Прервано после commit")):
            with self.assertRaisesRegex(ValueError, "после commit"):
                self.вызов()
        голова = self.гит("rev-parse", "HEAD")
        self.assertNotEqual(голова.decode().strip(), self.основа)
        for имя in ("применить", "повтор"):
            with self.assertRaises(ValueError):
                self.вызов(имя)
        self.assertEqual(self.гит("rev-parse", "HEAD"), голова)
        self.assertEqual(self.гит("rev-list", "--count", self.кандидат + "..HEAD").strip(), b"1")

    def test_исполняемые_настройки_отклоняются(self):
        for ключ, значение in (("merge.особый.driver", "false"), ("submodule.recurse", "true"),
                               ("merge.autostash", "true"), ("core.hooksPath", ".hooks"),
                               ("merge.verifySignatures", "true")):
            with self.subTest(ключ=ключ):
                self.гит("config", ключ, значение)
                with self.assertRaises(ValueError):
                    self.вызов()
                self.assertEqual(list(self.каталог.iterdir()), [])
                self.гит("config", "--unset", ключ)

    def test_защита_от_автообслуживания_в_пишущем_процессе(self):
        модуль = importlib.import_module("исполнение_обратного_приёма")
        исходный = модуль.создатель.гит
        self.гит("config", "maintenance.auto", "true")
        self.гит("config", "gc.auto", "1")
        проверенные = []

        def проверить(корень, *аргументы, **параметры):
            if аргументы[0] in {"merge", "commit"}:
                for ключ, значение in (("maintenance.auto", b"false"), ("gc.auto", b"0")):
                    self.assertEqual(исходный(корень, "config", "--get", ключ, **параметры).strip(), значение)
                проверенные.append(аргументы[0])
            return исходный(корень, *аргументы, **параметры)

        with patch.object(модуль.создатель, "гит", side_effect=проверить):
            self.вызов()
        self.assertEqual(проверенные, ["merge", "commit"])

    def test_защита_при_ошибке_синхронизации_родителя(self):
        модуль = importlib.import_module("исполнение_обратного_приёма")
        исходный = os.fsync
        родитель = self.каталог.parent.stat()

        def синхронизировать(дескриптор):
            состояние = os.fstat(дескриптор)
            if (состояние.st_dev, состояние.st_ino) == (родитель.st_dev, родитель.st_ino):
                raise OSError("Не сохранён родитель операции")
            return исходный(дескриптор)

        with patch.object(модуль.os, "fsync", side_effect=синхронизировать):
            with self.assertRaisesRegex(OSError, "родитель операции"):
                self.вызов()
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)
        self.assertFalse((self.корень / ".git/MERGE_HEAD").exists())

    def test_защита_от_подмены_типов_результата_merge(self):
        результат = self.вызов()
        путь = self.каталог / "процесс-merge.json"
        исходные = путь.read_bytes()
        процесс = json.loads(исходные)
        процесс["код"] = False
        путь.write_bytes((json.dumps(процесс, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode())
        снимок = {п.name: п.read_bytes() for п in self.каталог.iterdir()}
        with self.assertRaisesRegex(ValueError, "успеха merge"):
            self.вызов("повтор")
        self.assertEqual(снимок, {п.name: п.read_bytes() for п in self.каталог.iterdir()})
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), результат["коммит"])


if __name__ == "__main__":
    unittest.main()
