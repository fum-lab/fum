"""Закреплённые исходники переживают изменение checkout без нового worktree."""
import importlib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
копия = importlib.import_module("копия_кода_обратного_приёма")


class КопияКода(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.родитель = Path(self.временный.name).resolve()
        self.корень = self.родитель / "источник"
        self.корень.mkdir()
        self.каталог = self.родитель / "код"
        self.среда = {к: з for к, з in os.environ.items() if not к.startswith("GIT_")}
        self.среда.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        self.гит("init", "--initial-branch=fuma")
        self.гит("config", "user.name", "Испытатель")
        self.гит("config", "user.email", "test@example.invalid")
        self.пути = ["код/вход.py", "код/зависимость.py"]
        (self.корень / "код").mkdir()
        (self.корень / self.пути[0]).write_text(
            "from pathlib import Path\n"
            "def прочитать():\n"
            " import зависимость\n"
            " return зависимость.ЗНАЧЕНИЕ, Path(__file__).read_text()\n")
        (self.корень / self.пути[1]).write_text("ЗНАЧЕНИЕ = 'принятый код'\n")
        self.гит("add", ".")
        self.гит("commit", "-m", "Принятый код фикстуры")
        self.коммит = self.гит("rev-parse", "HEAD").decode().strip()

    def гит(self, *аргументы):
        return subprocess.check_output(["git", "-C", str(self.корень), *аргументы],
                                       env=self.среда, stderr=subprocess.DEVNULL)

    def создать(self):
        return копия.материализовать(self.корень, self.коммит, self.каталог, self.пути)

    def проверить(self, результат):
        return копия.проверить(self.каталог, результат["sha256"])

    def test_исходники_и_поздний_импорт_переживают_замену_checkout(self):
        индекс = (self.корень / ".git/index").read_bytes()
        деревья = self.гит("worktree", "list", "--porcelain")
        результат = self.создать()
        (self.корень / self.пути[1]).write_text("raise RuntimeError('Код кандидата')\n")
        программа = ("import sys,json;sys.path.insert(0,sys.argv[1]);import вход;"
                     "print(json.dumps(вход.прочитать()))")
        процесс = subprocess.run([sys.executable, "-I", "-S", "-B", "-c", программа,
            str(self.каталог / "код")], cwd=self.корень, env=self.среда,
            capture_output=True, check=True)
        значение, исходник = json.loads(процесс.stdout)
        self.assertEqual(значение, "принятый код")
        self.assertEqual(исходник, (self.корень / self.пути[0]).read_text())
        self.assertEqual(self.проверить(результат)["коммит"], self.коммит)
        self.assertEqual((self.корень / ".git/index").read_bytes(), индекс)
        self.assertEqual(self.гит("worktree", "list", "--porcelain"), деревья)
        self.assertFalse((self.каталог / ".git").exists())

    def test_грязный_исходник_отказывает_до_создания_копии(self):
        (self.корень / self.пути[1]).write_text("подмена\n")
        with self.assertRaises(ValueError):
            self.создать()
        self.assertFalse(self.каталог.exists())

    def test_отсутствующий_исходник_отказывает_до_записи(self):
        self.пути.append("код/отсутствует.py")
        with self.assertRaises(ValueError):
            self.создать()
        self.assertFalse(self.каталог.exists())

    def test_повтор_создания_не_переписывает_снимок(self):
        self.создать()
        до = (self.каталог / "манифест.json").read_bytes()
        with self.assertRaises(ValueError):
            self.создать()
        self.assertEqual((self.каталог / "манифест.json").read_bytes(), до)

    def test_подмена_байтов_и_режима_копии(self):
        результат = self.создать()
        путь = self.каталог / self.пути[1]
        путь.chmod(0o600)
        with self.assertRaises(ValueError):
            self.проверить(результат)
        путь.write_text("подмена\n")
        путь.chmod(0o400)
        with self.assertRaises(ValueError):
            self.проверить(результат)

    def test_ссылка_и_лишний_файл_отклоняются(self):
        результат = self.создать()
        путь = self.каталог / "лишний.py"
        путь.write_text("pass\n")
        with self.assertRaises(ValueError):
            self.проверить(результат)
        путь.unlink()
        путь.symlink_to(self.корень / self.пути[0])
        with self.assertRaises(ValueError):
            self.проверить(результат)

    def test_отпечаток_выбирается_независимо_от_манифеста(self):
        self.создать()
        with self.assertRaises(ValueError):
            копия.проверить(self.каталог, "0" * 64)

    def test_нельзя_материализовать_внутри_Git(self):
        self.каталог = self.корень / "копия"
        with self.assertRaises(ValueError):
            self.создать()
        self.assertFalse(self.каталог.exists())

    def test_нельзя_материализовать_внутри_bare_Git(self):
        bare = self.родитель / "хранилище.git"
        subprocess.run(["git", "init", "--bare", str(bare)], env=self.среда,
                       capture_output=True, check=True)
        bare.chmod(0o700)
        self.каталог = bare / "копия"
        with self.assertRaisesRegex(ValueError, "Git"):
            self.создать()
        self.assertFalse(self.каталог.exists())

    def test_чтение_не_отказывает_при_изменении_только_atime(self):
        результат = self.создать()
        with self.изменение_свойства("st_atime"):
            self.assertEqual(self.проверить(результат)["коммит"], self.коммит)

    def test_наносекундные_изменения_не_теряются(self):
        результат = self.создать()
        for имя in ("st_mtime_ns", "st_ctime_ns"):
            with self.subTest(имя=имя), self.изменение_свойства(имя):
                with self.assertRaises(ValueError):
                    self.проверить(результат)

    def изменение_свойства(self, имя):
        исходный_stat = Path.stat
        выбранный = self.каталог / self.пути[0]
        вызовы = 0

        def наблюдать(путь, *аргументы, **параметры):
            nonlocal вызовы
            состояние = исходный_stat(путь, *аргументы, **параметры)
            if путь != выбранный:
                return состояние
            вызовы += 1
            свойства = {ключ: getattr(состояние, ключ) for ключ in (
                "st_dev", "st_ino", "st_mode", "st_uid", "st_nlink", "st_size",
                "st_atime", "st_mtime_ns", "st_ctime_ns")}
            свойства[имя] += вызовы
            return SimpleNamespace(**свойства)

        return mock.patch.object(Path, "stat", наблюдать)

    def поместить_ядро(self):
        исходный = Path(__file__).resolve().parents[3]
        путь_скриптов = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/"
        self.пути = [путь_скриптов + имя + ".py" for имя in (
            "исполнение_обратного_приёма", "контракт_обратного_приёма",
            "наблюдение_обратного_приёма", "настройки_обратного_приёма",
            "фаза_обратного_приёма", "создание_коммита", "история_модели",
            "сообщения_задачи", "автор_коммита", "готовность_коммита",
            "поколения_готовности", "готовность_этапа", "граница_выбранных_команд",
            "текст_команды_с_изображением", "check-session-coherence", "сверить-материалы-этапа")]
        self.пути += ["Инструменты/" + имя for имя in (
            "fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py",
            "fum-proyektnyiye-fajlyi/scripts/project_files.py",
            "fum-struktura-papok-zaprosov/scripts/request_folder_layout.py",
            "fum-snimki-indeksa/scripts/происхождение_сообщений.py")]
        for имя in self.пути:
            цель = self.корень / имя
            цель.parent.mkdir(parents=True, exist_ok=True)
            цель.write_bytes((исходный / имя).read_bytes())
            цель.chmod((исходный / имя).stat().st_mode & 0o777)
        self.гит("add", ".")
        self.гит("commit", "-m", "Настоящие исходники принимающей стороны")
        self.коммит = self.гит("rev-parse", "HEAD").decode().strip()
        return путь_скриптов

    def test_настоящее_ядро_импортируется_из_копии_после_замены_создателя(self):
        путь_скриптов = self.поместить_ядро()
        результат = self.создать()
        ожидаемый_sha = hashlib.sha256(
            (self.корень / путь_скриптов / "создание_коммита.py").read_bytes()).hexdigest()
        (self.корень / путь_скриптов / "создание_коммита.py").write_text(
            "raise RuntimeError('Загружен код кандидата')\n")
        программа = ("import sys,json,pathlib;sys.path.insert(0,sys.argv[1]);"
            "import исполнение_обратного_приёма as ядро;"
            "print(json.dumps({'создатель':ядро.создатель.__file__,"
            "'самочтение':ядро.создатель.КОД_ПРИ_ЗАГРУЗКЕ,"
            "'классификатор':ядро.создатель.сообщения._КЛАССИФИКАТОР.__file__,"
            "'модули':[м.__file__ for м in sys.modules.values() if "
            "getattr(м,'__file__',None) and 'Инструменты' in pathlib.Path(м.__file__).parts]}))")
        процесс = subprocess.run([sys.executable, "-I", "-S", "-B", "-c", программа,
            str(self.каталог / путь_скриптов)], cwd=self.корень, env=self.среда,
            capture_output=True, check=True)
        наблюдение = json.loads(процесс.stdout)
        self.assertTrue(наблюдение["модули"])
        self.assertTrue(all(Path(имя).is_relative_to(self.каталог)
                            for имя in наблюдение["модули"]))
        self.assertEqual(наблюдение["создатель"], str(self.каталог / путь_скриптов / "создание_коммита.py"))
        self.assertEqual(наблюдение["самочтение"], ожидаемый_sha)
        self.assertEqual(наблюдение["классификатор"], str(self.каталог /
            "Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py"))
        self.assertEqual(self.проверить(результат)["коммит"], self.коммит)

    def test_merge_заменяет_код_но_исполнение_и_повтор_остаются_в_копии(self):
        from test_контракта_обратного_приёма import ОбратныйПриём
        from наблюдение_обратного_приёма import снять_состояние

        путь_скриптов = self.поместить_ядро()
        получатель = {"ветка": "refs/heads/fuma", "коммит": self.коммит,
                      "дерево": self.гит("rev-parse", "HEAD^{tree}").decode().strip()}
        сохранение = self.создать()
        self.гит("switch", "-c", "codex/rezuljtat")
        for имя in self.пути:
            (self.корень / имя).write_text("raise RuntimeError('Код кандидата')\n")
        self.гит("add", ".")
        self.гит("commit", "-m", "Кандидат заменяет принимающий код")
        источник = {"ветка": "refs/heads/codex/rezuljtat",
                    "коммит": self.гит("rev-parse", "HEAD").decode().strip(),
                    "дерево": self.гит("rev-parse", "HEAD^{tree}").decode().strip()}
        self.гит("switch", "fuma")
        with mock.patch.dict(os.environ, self.среда, clear=True):
            наблюдение = снять_состояние(self.корень, получатель, источник)
        пример = ОбратныйПриём()
        пример.setUp()
        пример.заявка.update(получатель=получатель, источник=источник)
        пример.наблюдение.update(получатель=получатель, источник=источник,
                                разница_sha256=наблюдение["разница_sha256"])
        пример.проверка.update(кандидат=источник["коммит"], дерево=источник["дерево"])
        пример.ревью.update(основа=self.коммит, кандидат=источник["коммит"],
                           дерево=источник["дерево"], разница_sha256=наблюдение["разница_sha256"])
        операция = self.родитель / "операция"
        операция.mkdir(mode=0o700)
        вход = self.родитель / "вход.json"
        вход.write_text(json.dumps({"корень": str(self.корень), "план": пример.вызов(),
            "каталог": str(операция), "сообщение": "Принять лабораторный кандидат\n",
            "автор": ["FUM Codex [gpt-6-astra; effort=ultra]", "test@example.invalid", "1792540000", "+0300"],
            "коммиттер": ["FUM", "test@example.invalid", "1792540000", "+0300"]}))
        программа = ("import sys,json;sys.path.insert(0,sys.argv[1]);"
            "import исполнение_обратного_приёма as ядро;"
            "данные=json.load(open(sys.argv[2]));данные['сообщение']=данные['сообщение'].encode();"
            "print(json.dumps(getattr(ядро,sys.argv[3])(**данные,сверить_основание=lambda:None)))")

        def выполнить(действие):
            процесс = subprocess.run([sys.executable, "-I", "-S", "-B", "-c", программа,
                str(self.каталог / путь_скриптов), str(вход), действие], cwd=self.корень,
                env=self.среда, capture_output=True, check=True)
            return json.loads(процесс.stdout)

        деревья = self.гит("worktree", "list", "--porcelain").count(b"worktree ")
        результат = выполнить("применить")
        self.assertEqual(результат["родители"], [self.коммит, источник["коммит"]])
        self.assertEqual(результат["дерево"], источник["дерево"])
        self.assertEqual(self.гит("status", "--porcelain"), b"")
        self.assertIn("Код кандидата", (self.корень / self.пути[0]).read_text())
        файлы = {п.name: п.read_bytes() for п in операция.iterdir()}
        индекс = (self.корень / ".git/index").read_bytes()
        self.assertEqual(выполнить("повтор"), результат)
        self.assertEqual(файлы, {п.name: п.read_bytes() for п in операция.iterdir()})
        self.assertEqual((self.корень / ".git/index").read_bytes(), индекс)
        self.assertEqual(self.гит("rev-parse", "HEAD").decode().strip(), результат["коммит"])
        self.assertEqual(self.гит("rev-list", "--count", источник["коммит"] + "..HEAD").strip(), b"1")
        self.assertEqual(self.гит("worktree", "list", "--porcelain").count(b"worktree "), деревья)
        self.assertEqual(self.проверить(сохранение)["коммит"], self.коммит)


if __name__ == "__main__":
    unittest.main()
