"""Различающие проверки живой фазы между merge и commit."""
import importlib
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

import test_наблюдения_обратного_приёма as фикстура

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))


class ФазаОбратногоПриёма(unittest.TestCase):
    setUp = фикстура.НаблюдениеОбратногоПриёма.setUp
    гит = фикстура.НаблюдениеОбратногоПриёма.гит
    ветка = фикстура.НаблюдениеОбратногоПриёма.ветка

    def проверить(self):
        модуль = importlib.import_module("фаза_обратного_приёма")
        with patch.dict(os.environ, self.среда, clear=True):
            return модуль.проверить_готовое_слияние(
                self.корень, self.получатель, self.источник)

    def слить(self):
        self.гит("merge", "--no-commit", "--no-ff", "--no-edit",
                 "--no-overwrite-ignore", self.кандидат)

    def test_подготовленное_слияние_читается_без_записи(self):
        self.слить()
        индекс = (self.корень / ".git/index").read_bytes()
        деревья = self.гит("worktree", "list", "--porcelain")
        результат = self.проверить()
        self.assertEqual(результат["дерево"], self.источник["дерево"])
        self.assertEqual(результат["родители"], [self.основа, self.кандидат])
        self.assertEqual(результат, self.проверить())
        self.assertEqual(индекс, (self.корень / ".git/index").read_bytes())
        self.assertEqual(деревья, self.гит("worktree", "list", "--porcelain"))
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), self.основа)

    def test_без_начатого_слияния_отказ(self):
        with self.assertRaisesRegex(ValueError, "MERGE_HEAD"):
            self.проверить()

    def test_другой_merge_head(self):
        self.слить()
        (self.корень / ".git/MERGE_HEAD").write_text(self.основа + "\n")
        with self.assertRaisesRegex(ValueError, "MERGE_HEAD"):
            self.проверить()

    def test_другой_orig_head(self):
        self.слить()
        (self.корень / ".git/ORIG_HEAD").write_text(self.кандидат + "\n")
        with self.assertRaisesRegex(ValueError, "ORIG_HEAD"):
            self.проверить()

    def test_поздняя_правка_индекса(self):
        self.слить()
        (self.корень / "результат.txt").write_text("подмена\n")
        self.гит("add", "--", "результат.txt")
        with self.assertRaisesRegex(ValueError, "индекс"):
            self.проверить()

    def test_поздняя_правка_рабочего_файла(self):
        self.слить()
        (self.корень / "результат.txt").write_text("подмена\n")
        with self.assertRaisesRegex(ValueError, "рабоч"):
            self.проверить()

    def test_неотслеживаемый_файл(self):
        self.слить()
        (self.корень / "поздний.txt").write_text("остаток\n")
        with self.assertRaisesRegex(ValueError, "[Рр]абоч"):
            self.проверить()

    def test_флаг_индекса_скрывает_правку(self):
        self.слить()
        for флаг in ("--assume-unchanged", "--skip-worktree"):
            with self.subTest(флаг=флаг):
                self.гит("update-index", флаг, "--", "результат.txt")
                with self.assertRaisesRegex(ValueError, "флаг"):
                    self.проверить()
                self.гит("update-index", "--no-assume-unchanged", "--no-skip-worktree",
                         "--", "результат.txt")

    def test_тот_же_blob_другой_режим(self):
        self.слить()
        self.гит("update-index", "--chmod=+x", "--", "результат.txt")
        with self.assertRaisesRegex(ValueError, "индекс"):
            self.проверить()

    def test_два_родителя_merge_head(self):
        self.слить()
        (self.корень / ".git/MERGE_HEAD").write_text(self.кандидат + "\n" + self.основа + "\n")
        with self.assertRaisesRegex(ValueError, "MERGE_HEAD"):
            self.проверить()

    def test_несовместимая_операция(self):
        self.слить()
        (self.корень / ".git/CHERRY_PICK_HEAD").write_text(self.кандидат + "\n")
        with self.assertRaisesRegex(ValueError, "операци"):
            self.проверить()

    def test_дрейф_основания_внутри_чтения(self):
        self.слить()
        модуль = importlib.import_module("фаза_обратного_приёма")
        исходная = модуль._индекс_и_файлы
        for имя, прежнее, новое in (("MERGE_HEAD", self.кандидат, self.основа),
                                    ("ORIG_HEAD", self.основа, self.кандидат)):
            with self.subTest(имя=имя):
                def подменить(*аргументы):
                    результат = исходная(*аргументы)
                    (self.корень / ".git" / имя).write_text(новое + "\n")
                    return результат
                with patch.object(модуль, "_индекс_и_файлы", подменить):
                    with self.assertRaisesRegex(ValueError, имя):
                        self.проверить()
                (self.корень / ".git" / имя).write_text(прежнее + "\n")

    def test_сдвиг_ref_с_тем_же_деревом(self):
        self.слить()
        новый = self.гит("commit-tree", self.источник["дерево"],
                         "-p", self.кандидат, "-m", "Другой коммит").decode().strip()
        self.гит("update-ref", self.источник["ветка"], новый)
        with self.assertRaisesRegex(ValueError, "источник"):
            self.проверить()


if __name__ == "__main__":
    unittest.main()
