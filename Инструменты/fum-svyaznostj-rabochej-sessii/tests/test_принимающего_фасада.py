"""Композиция настоящего Git, native и захватов; допуск ROOT синтетический."""
import hashlib
import json
import os
import sys
import subprocess
from unittest.mock import patch
import unittest

import test_исполнения_обратного_приёма as эффектная_фикстура
import test_нативных_оснований_обратного_приёма as нативная_фикстура
from test_нативных_оснований_обратного_приёма import байты, хэш
import проверка_кандидата_обратного_приёма as проверка
import принимающий_фасад_обратного_приёма as фасад
from принимающий_фасад_обратного_приёма import подготовить


class ПринимающийФасад(unittest.TestCase):
    гит = эффектная_фикстура.ИсполнениеОбратногоПриёма.гит
    ветка = эффектная_фикстура.ИсполнениеОбратногоПриёма.ветка

    def setUp(self):
        эффектная_фикстура.ИсполнениеОбратногоПриёма.setUp(self)
        self.native = нативная_фикстура.НативныеОснования()
        self.native.setUp()
        self.addCleanup(self.native.doCleanups)
        self.счётчик = self.корень.parent / "число-предметных-запусков"
        команда = [sys.executable, "-B", "-c",
            "from pathlib import Path; p=Path(__import__('sys').argv[1]); "
            "p.write_text(str(int(p.read_text())+1) if p.exists() else '1'); print('OK')",
            str(self.счётчик)]
        self.каталог_проверки = self.корень.parent / "проверка-кандидата"
        with patch.dict(os.environ, self.среда, clear=True):
            self.гит("switch", "codex/rezuljtat")
            результат = проверка.запустить(self.корень, self.источник, команда,
                self.native.uuid, self.каталог_проверки)
            self.гит("switch", "fuma")
        self.проверки = [{"идентификатор": "адресная", "каталог": str(self.каталог_проверки),
                         "sha256": результат["sha256"], "вход": результат["результат"]["вход"]}]
        self.native.решение = {"схема": "fum.решение-ревью-обратного-приёма.1",
            "координатор": self.native.uuid, "основа": self.основа, "кандидат": self.кандидат,
            "дерево": self.источник["дерево"], "разница_sha256": self.план["разница_sha256"],
            "решение": "принять", "охват": "полное-изменение",
            "проверки": ["адресная"], "переносимые_проверки": ["адресная"]}
        self.native.тело = байты(self.native.решение)
        self.native.ответ["content"][0]["text"] = self.native.текст()
        self.native.записать()
        self.вызовы_допуска = []

    def допуск(self, основание):
        self.assertIs(type(основание), bytes)
        данные = json.loads(основание)
        self.assertEqual(данные["получатель"], self.получатель)
        self.assertEqual(данные["источник"], self.источник)
        self.assertEqual(данные["исполнитель_ревью"], self.native.uuid)
        self.вызовы_допуска.append(основание)

    def подготовить(self, допуск=None):
        сырые = байты(self.native.выбор)
        with patch.dict(os.environ, self.среда, clear=True):
            return подготовить(self.корень, self.получатель, self.источник,
                сырые, хэш(сырые), self.проверки, допуск_получателя=допуск or self.допуск)

    def применить(self, основание, повтор=False):
        with patch.dict(os.environ, self.среда, clear=True):
            return (основание.повтор if повтор else основание.применить)(
                self.каталог, self.сообщение, self.автор, self.коммиттер)

    def test_полный_цикл_один_тест_один_merge_без_нового_дерева(self):
        деревья = self.гит("worktree", "list", "--porcelain")
        основание = self.подготовить()
        self.assertFalse(основание.план["разрешение_записи"])
        результат = self.применить(основание)
        self.assertEqual(результат["родители"], [self.основа, self.кандидат])
        self.assertEqual(результат["дерево"], self.источник["дерево"])
        сообщение = self.гит("cat-file", "commit", "HEAD").split(b"\n\n", 1)[1]
        self.assertEqual(сообщение, self.сообщение + b"\nFUM-Reverse-Acceptance-SHA256: "
            + хэш(основание.свидетельство).encode() + b"\n")
        self.assertEqual(self.счётчик.read_text(), "1")
        # HEAD должен измениться на M; все остальные поля списка сохраняются.
        состав = lambda сырые: [строка for строка in сырые.splitlines() if not строка.startswith(b"HEAD ")]
        self.assertEqual(состав(self.гит("worktree", "list", "--porcelain")), состав(деревья))
        self.assertEqual(self.гит("status", "--porcelain"), b"")

    def test_повтор_не_запускает_проверку_и_не_создаёт_коммит(self):
        основание = self.подготовить()
        результат = self.применить(основание)
        количество = self.гит("rev-list", "--count", "HEAD")
        self.assertEqual(self.применить(основание, повтор=True), результат)
        self.assertEqual(self.гит("rev-list", "--count", "HEAD"), количество)
        self.assertEqual(self.счётчик.read_text(), "1")

    def test_допуск_не_заменяется_флагом_или_результатом_true(self):
        for допуск in (True, lambda данные: True):
            with self.subTest(допуск=допуск), self.assertRaises(ValueError):
                self.подготовить(допуск)
        self.assertEqual(list(self.каталог.iterdir()), [])
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)

    def test_неподтверждённая_переносимость_отвергается(self):
        self.native.решение["переносимые_проверки"] = []
        self.native.тело = байты(self.native.решение)
        self.native.ответ["content"][0]["text"] = self.native.текст()
        self.native.записать()
        with self.assertRaises(ValueError):
            self.подготовить()
        self.assertEqual(list(self.каталог.iterdir()), [])

    def test_чужой_кандидат_в_ожидаемом_захвате_отвергается(self):
        self.проверки[0]["вход"]["кандидат"] = self.получатель
        with self.assertRaises(ValueError):
            self.подготовить()

    def test_дрейф_L_до_подготовки_отвергается(self):
        (self.корень / "поздний.txt").write_text("ввод")
        self.гит("add", "поздний.txt")
        self.гит("commit", "-m", "Поздний коммит получателя")
        with self.assertRaises(ValueError):
            self.подготовить()
        self.assertEqual(self.вызовы_допуска, [])

    def test_дрейф_C_после_подготовки_не_создаёт_merge(self):
        основание = self.подготовить()
        self.гит("update-ref", self.источник["ветка"], self.основа)
        with self.assertRaises(ValueError):
            self.применить(основание)
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)

    def test_изменённое_native_основание_после_merge_запрещает_повтор(self):
        основание = self.подготовить()
        self.применить(основание)
        до = self.гит("rev-list", "--count", "HEAD")
        self.native.путь.write_bytes(self.native.путь.read_bytes().replace(b'"ultra"', b'"other"'))
        with self.assertRaises(ValueError):
            self.применить(основание, повтор=True)
        self.assertEqual(self.гит("rev-list", "--count", "HEAD"), до)

    def test_повторная_сверка_основания_не_читает_HEAD_и_не_запускает_процесс(self):
        основание = self.подготовить()
        with patch("subprocess.run", side_effect=AssertionError("Не нужен процесс")), \
             patch("subprocess.check_output", side_effect=AssertionError("Не нужен Git")):
            основание.сверить()
        self.assertGreaterEqual(len(self.вызовы_допуска), 2)

    def test_план_и_исходные_аргументы_не_передаются_по_ссылке(self):
        основание = self.подготовить()
        план = основание.план
        план["родители"][0] = "0" * 40
        self.проверки.clear()
        self.assertEqual(основание.план["родители"][0], self.основа)
        основание.сверить()

    def test_повтор_в_новом_процессе_из_закреплённого_свидетельства(self):
        основание = self.подготовить()
        результат = self.применить(основание)
        пакет = self.корень.parent / "повтор.json"
        пакет.write_text(json.dumps({"свидетельство": основание.свидетельство.decode(),
            "sha256": хэш(основание.свидетельство), "каталог": str(self.каталог),
            "сообщение": self.сообщение.decode(), "автор": self.автор, "коммиттер": self.коммиттер}))
        программа = ("import sys,json; from pathlib import Path; sys.path.insert(0,sys.argv[1]); "
            "import принимающий_фасад_обратного_приёма as f; "
            "p=json.loads(Path(sys.argv[2]).read_text()); "
            "a=f.восстановить(p['свидетельство'].encode(),p['sha256'],допуск_получателя=lambda b:None); "
            "r=a.повтор(p['каталог'],p['сообщение'].encode(),p['автор'],p['коммиттер']); print(json.dumps(r))")
        исходные = {п.name: п.read_bytes() for п in self.каталог.iterdir()}
        запуск = subprocess.run([sys.executable, "-E", "-s", "-S", "-B", "-c", программа,
            str(__import__('pathlib').Path(фасад.__file__).parent), str(пакет)],
            env=self.среда, capture_output=True, text=True)
        self.assertEqual(запуск.returncode, 0, запуск.stderr)
        self.assertEqual(json.loads(запуск.stdout), результат)
        self.assertEqual({п.name: п.read_bytes() for п in self.каталог.iterdir()}, исходные)
        self.assertEqual(self.счётчик.read_text(), "1")

    def test_другой_успешный_захват_того_же_C_не_подменяет_основание_merge(self):
        первое = self.подготовить()
        with patch.dict(os.environ, self.среда, clear=True):
            self.гит("switch", "codex/rezuljtat")
            вход = self.проверки[0]["вход"]
            другой = self.корень.parent / "другая-проверка"
            результат = проверка.запустить(self.корень, self.источник, вход["команда"], self.native.uuid, другой)
            self.гит("switch", "fuma")
        self.проверки[0].update(каталог=str(другой), sha256=результат["sha256"])
        второе = self.подготовить()
        self.assertEqual(первое.план, второе.план)
        self.assertNotEqual(первое.свидетельство, второе.свидетельство)
        self.применить(первое)
        до = self.гит("rev-list", "--count", "HEAD")
        with self.assertRaises(ValueError):
            self.применить(второе, повтор=True)
        self.assertEqual(self.гит("rev-list", "--count", "HEAD"), до)

    def test_восстановление_не_разрешает_новое_применение(self):
        основание = self.подготовить()
        восстановленное = фасад.восстановить(основание.свидетельство,
            хэш(основание.свидетельство), допуск_получателя=self.допуск)
        with self.assertRaises(ValueError):
            восстановленное.применить(self.каталог, self.сообщение, self.автор, self.коммиттер)
        self.assertEqual(list(self.каталог.iterdir()), [])

    def test_восстановление_сверяет_SHA_и_пересобранный_план_без_Git(self):
        основание = self.подготовить()
        пакет = json.loads(основание.свидетельство)
        пакет["план"]["дерево"] = "0" * 40
        изменённые = байты(пакет)
        with patch("subprocess.run", side_effect=AssertionError("Не нужен процесс")), \
             patch("subprocess.check_output", side_effect=AssertionError("Не нужен Git")):
            for сырые, sha in ((основание.свидетельство, "0" * 64), (изменённые, хэш(изменённые))):
                with self.subTest(sha=sha), self.assertRaises(ValueError):
                    фасад.восстановить(сырые, sha, допуск_получателя=self.допуск)
            восстановленное = фасад.восстановить(основание.свидетельство,
                хэш(основание.свидетельство), допуск_получателя=self.допуск)
            self.assertEqual(восстановленное.план, основание.план)

    def test_исходное_сообщение_не_может_подменить_метку_основания(self):
        основание = self.подготовить()
        self.сообщение += b"FUM-Reverse-Acceptance-SHA256: " + b"0" * 64 + b"\n"
        with self.assertRaises(ValueError):
            self.применить(основание)
        self.assertEqual(list(self.каталог.iterdir()), [])
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)

    def test_отзыв_допуска_после_M_не_изменяет_успешную_попытку(self):
        отозван = []
        def допуск(сырые):
            if отозван:
                raise ValueError("Поручение отозвано")
            self.допуск(сырые)
        основание = self.подготовить(допуск)
        self.применить(основание)
        файлы = {п.name: п.read_bytes() for п in self.каталог.iterdir()}
        до = self.гит("rev-list", "--count", "HEAD")
        отозван.append(True)
        with self.assertRaises(ValueError):
            self.применить(основание, повтор=True)
        with self.assertRaises(ValueError):
            фасад.восстановить(основание.свидетельство, хэш(основание.свидетельство),
                допуск_получателя=допуск)
        self.assertEqual({п.name: п.read_bytes() for п in self.каталог.iterdir()}, файлы)
        self.assertEqual(self.гит("rev-list", "--count", "HEAD"), до)

    def test_неполная_попытка_не_дописывается_восстановленным_повтором(self):
        основание = self.подготовить()
        self.применить(основание)
        (self.каталог / "квитанция.json").unlink()
        файлы = {п.name: п.read_bytes() for п in self.каталог.iterdir()}
        до = self.гит("rev-list", "--count", "HEAD")
        восстановленное = фасад.восстановить(основание.свидетельство,
            хэш(основание.свидетельство), допуск_получателя=self.допуск)
        with self.assertRaises(ValueError):
            self.применить(восстановленное, повтор=True)
        self.assertEqual({п.name: п.read_bytes() for п in self.каталог.iterdir()}, файлы)
        self.assertEqual(self.гит("rev-list", "--count", "HEAD"), до)
        self.assertEqual(self.счётчик.read_text(), "1")


if __name__ == "__main__":
    unittest.main()
