"""Живые Git-фикстуры читающего входа обратной приёмки."""
import importlib
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
наблюдатель = importlib.import_module("наблюдение_обратного_приёма")


class НаблюдениеОбратногоПриёма(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve() / "репозиторий"
        self.корень.mkdir()
        self.среда = {к: з for к, з in os.environ.items() if not к.startswith("GIT_")}
        self.среда.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        self.гит("init", "--initial-branch=fuma")
        self.гит("config", "user.name", "Испытатель")
        self.гит("config", "user.email", "test@example.invalid")
        (self.корень / "основа.txt").write_text("основа\n")
        self.гит("add", "--", "основа.txt")
        self.гит("commit", "-m", "Начальная фикстура")
        self.основа = self.гит("rev-parse", "HEAD").decode().strip()
        self.гит("switch", "-c", "codex/rezuljtat")
        (self.корень / "результат.txt").write_text("результат\n")
        self.гит("add", "--", "результат.txt")
        self.гит("commit", "-m", "Результат фикстуры")
        self.кандидат = self.гит("rev-parse", "HEAD").decode().strip()
        self.гит("switch", "fuma")
        self.получатель = self.ветка("refs/heads/fuma", self.основа)
        self.источник = self.ветка("refs/heads/codex/rezuljtat", self.кандидат)

    def гит(self, *аргументы):
        return subprocess.run(["git", "-C", str(self.корень), *аргументы],
                              env=self.среда, capture_output=True, check=True).stdout

    def ветка(self, имя, коммит):
        return {"ветка": имя, "коммит": коммит,
                "дерево": self.гит("rev-parse", коммит + "^{tree}").decode().strip()}

    def снять(self):
        with patch.dict(os.environ, self.среда, clear=True):
            return наблюдатель.снять_состояние(self.корень, self.получатель, self.источник)

    def test_чистый_получатель_без_нового_дерева_и_записи(self):
        индекс = self.корень / ".git/index"
        до = индекс.read_bytes()
        деревья = self.гит("worktree", "list", "--porcelain")
        результат = self.снять()
        self.assertEqual(результат["получатель"], self.получатель)
        self.assertEqual(результат["источник"], self.источник)
        self.assertTrue(результат["основа_является_предком"])
        self.assertFalse(результат["разрешение_записи"])
        self.assertEqual(результат, self.снять())
        self.assertEqual(индекс.read_bytes(), до)
        self.assertEqual(self.гит("worktree", "list", "--porcelain"), деревья)
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)
        self.assertEqual(len(результат["разница_sha256"]), 64)

    def test_изменённый_отслеживаемый_файл(self):
        (self.корень / "основа.txt").write_text("изменение\n")
        with self.assertRaisesRegex(ValueError, "нечист"):
            self.снять()

    def test_неотслеживаемый_файл(self):
        (self.корень / "лишний.txt").write_text("остаток\n")
        with self.assertRaisesRegex(ValueError, "нечист"):
            self.снять()

    def test_чужая_активная_ветка(self):
        self.гит("switch", "codex/rezuljtat")
        with self.assertRaisesRegex(ValueError, "получател"):
            self.снять()

    def test_дрейф_источника_до_чтения(self):
        self.гит("update-ref", self.источник["ветка"], self.основа)
        with self.assertRaisesRegex(ValueError, "источник"):
            self.снять()

    def test_другая_ожидаемая_структура_дерева(self):
        self.источник["дерево"] = self.получатель["дерево"]
        with self.assertRaisesRegex(ValueError, "дерев"):
            self.снять()

    def test_незавершённое_слияние(self):
        (self.корень / ".git/MERGE_HEAD").write_text(self.кандидат + "\n")
        with self.assertRaisesRegex(ValueError, "операци"):
            self.снять()

    def test_пропуск_рабочих_файлов_индексом(self):
        for флаг in ("--assume-unchanged", "--skip-worktree"):
            with self.subTest(флаг=флаг):
                self.гит("update-index", флаг, "--", "основа.txt")
                with self.assertRaisesRegex(ValueError, "флаг"):
                    self.снять()
                self.гит("update-index", "--no-assume-unchanged", "--no-skip-worktree", "--", "основа.txt")

    def test_дрейф_источника_во_время_чтения(self):
        исходная = наблюдатель._гит
        выполнено = False

        def сдвинуть(корень, *аргументы):
            nonlocal выполнено
            результат = исходная(корень, *аргументы)
            if аргументы and аргументы[0] == "diff" and not выполнено:
                выполнено = True
                self.гит("update-ref", self.источник["ветка"], self.основа)
            return результат

        with patch.object(наблюдатель, "_гит", сдвинуть):
            with self.assertRaisesRegex(ValueError, "источник"):
                self.снять()

    def test_поздний_грязный_файл(self):
        исходная = наблюдатель._гит

        def загрязнить(корень, *аргументы):
            результат = исходная(корень, *аргументы)
            if аргументы and аргументы[0] == "diff":
                (self.корень / "остаток.txt").write_text("позднее изменение\n")
            return результат

        with patch.object(наблюдатель, "_гит", загрязнить):
            with self.assertRaisesRegex(ValueError, "нечист"):
                self.снять()

    def test_основа_не_включена_в_кандидат(self):
        (self.корень / "поздняя-основа.txt").write_text("новая основа\n")
        self.гит("add", "--", "поздняя-основа.txt")
        self.гит("commit", "-m", "Продвинуть получателя")
        self.основа = self.гит("rev-parse", "HEAD").decode().strip()
        self.получатель = self.ветка("refs/heads/fuma", self.основа)
        with self.assertRaisesRegex(ValueError, "предком"):
            self.снять()

    def test_полная_разница_содержит_gitlink_при_скрывающей_настройке(self):
        self.гит("switch", "codex/rezuljtat")
        self.гит("update-index", "--add", "--cacheinfo", "160000", self.основа, "зависимость")
        self.гит("commit", "-m", "Добавить gitlink")
        self.кандидат = self.гит("rev-parse", "HEAD").decode().strip()
        self.источник = self.ветка("refs/heads/codex/rezuljtat", self.кандидат)
        self.гит("switch", "fuma")
        self.гит("config", "diff.ignoreSubmodules", "all")
        ожидаемая = self.гит("diff", "--raw", "-z", "--no-abbrev", "--no-renames",
                            "--ignore-submodules=none", "--no-relative", "-O", os.devnull,
                            self.основа, self.кандидат, "--")
        self.assertIn("зависимость".encode(), ожидаемая)
        self.assertIn(b"160000", ожидаемая)
        self.assertEqual(self.снять()["разница_sha256"], hashlib.sha256(ожидаемая).hexdigest())

    def test_представление_не_зависит_от_настроек_текстового_diff(self):
        self.гит("switch", "codex/rezuljtat")
        (self.корень / "основа.txt").write_text("изменённая основа\n")
        self.гит("add", "--", "основа.txt")
        self.гит("commit", "-m", "Изменить второй путь")
        self.кандидат = self.гит("rev-parse", "HEAD").decode().strip()
        self.источник = self.ветка("refs/heads/codex/rezuljtat", self.кандидат)
        self.гит("switch", "fuma")
        до = self.снять()
        порядок = self.корень.parent / "порядок-diff"
        порядок.write_text("результат.txt\nоснова.txt\n")
        for ключ, значение in (("diff.context", "99"), ("diff.algorithm", "histogram"),
                                ("diff.orderFile", str(порядок)), ("diff.relative", "true"),
                                ("diff.noprefix", "true"), ("diff.submodule", "log")):
            self.гит("config", ключ, значение)
        self.assertEqual(self.снять(), до)

    def test_внешний_фильтр_отклоняется_до_status(self):
        исходная = наблюдатель._гит
        команды = []

        def зарегистрировать(корень, *аргументы):
            команды.append(аргументы[0])
            return исходная(корень, *аргументы)

        for тип in ("clean", "process"):
            with self.subTest(тип=тип):
                self.гит("config", "filter.проверка." + тип, "false")
                команды.clear()
                with patch.object(наблюдатель, "_гит", зарегистрировать):
                    with self.assertRaisesRegex(ValueError, "фильтр"):
                        self.снять()
                self.assertNotIn("status", команды)
                self.гит("config", "--unset", "filter.проверка." + тип)

    def test_фильтр_инициализированной_зависимости_тоже_отклоняется(self):
        зависимость = self.корень / "зависимость"
        self.гит("clone", "--no-hardlinks", "--no-checkout", str(self.корень), str(зависимость))

        def в_зависимости(*аргументы):
            return subprocess.run(["git", "-C", str(зависимость), *аргументы],
                                  env=self.среда, capture_output=True, check=True).stdout

        в_зависимости("checkout", "--detach", self.основа)
        self.гит("update-index", "--add", "--cacheinfo", "160000", self.основа, "зависимость")
        self.гит("commit", "-m", "Основа с зависимостью")
        self.основа = self.гит("rev-parse", "HEAD").decode().strip()
        self.гит("switch", "codex/rezuljtat")
        self.гит("merge", "--no-edit", "fuma")
        self.кандидат = self.гит("rev-parse", "HEAD").decode().strip()
        self.гит("switch", "fuma")
        self.получатель = self.ветка("refs/heads/fuma", self.основа)
        self.источник = self.ветка("refs/heads/codex/rezuljtat", self.кандидат)
        в_зависимости("config", "filter.проверка.clean", "false")
        исходная = наблюдатель._гит
        команды = []

        def зарегистрировать(корень, *аргументы):
            команды.append(аргументы[0])
            return исходная(корень, *аргументы)

        with patch.object(наблюдатель, "_гит", зарегистрировать):
            with self.assertRaisesRegex(ValueError, "фильтр"):
                self.снять()
        self.assertNotIn("status", команды)

    def test_подмена_предка_через_grafts(self):
        (self.корень / "поздняя-основа.txt").write_text("независимое изменение\n")
        self.гит("add", "--", "поздняя-основа.txt")
        self.гит("commit", "-m", "Независимая новая основа")
        self.основа = self.гит("rev-parse", "HEAD").decode().strip()
        self.получатель = self.ветка("refs/heads/fuma", self.основа)
        (self.корень / ".git/info/grafts").write_text(self.кандидат + " " + self.основа + "\n")
        with self.assertRaisesRegex(ValueError, "grafts"):
            self.снять()


if __name__ == "__main__":
    unittest.main()
