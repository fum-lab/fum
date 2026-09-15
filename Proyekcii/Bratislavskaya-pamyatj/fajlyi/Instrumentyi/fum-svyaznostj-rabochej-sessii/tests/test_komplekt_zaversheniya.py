"""Приватный Stop-комплект: настоящие Git-объекты и отдельные процессы."""
import hashlib
import argparse
from concurrent.futures import ThreadPoolExecutor
import importlib.util
import json
import os
from pathlib import Path
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import unittest
import zlib
from unittest import mock

СЦЕНАРИЙ = Path(__file__).resolve().parents[1] / "scripts/подготовить-комплект-завершения.py"
ПРЕФИКС = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/"
ПУТИ = [ПРЕФИКС + имя for имя in ("перехватить-завершение.py", "проверить-продолжение-задачи.py", "обязательства_задачи.py")]
ПУТИ += ["Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py"]
ПУТИ += [ПРЕФИКС + имя for имя in ("обязательства_задачи_v2.py", "история_пути_гита.py")]
ПУТИ += ["Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/" + имя for имя in (
    "закрытый_отчёт_из_гита.py", "связь_отпечатка_с_коммитом.py")]
ПУТИ += [ПРЕФИКС + имя for имя in ("обработка_сообщений.py", "сообщения_задачи.py")]
ПУТИ += ["Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py"]
ЗАДАЧА = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"


class КомплектЗавершения(unittest.TestCase):
    def setUp(это):
        это.каталог = Path(tempfile.mkdtemp()).resolve()
        это.addCleanup(это.убрать)
        это.репозиторий = это.каталог / "источник"
        это.репозиторий.mkdir()
        это.хранилище = это.каталог / "приватное"
        это.хранилище.mkdir(mode=0o700)
        это.данные = это.каталог / "данные"
        это.данные.mkdir()
        это.гит("init", "-q")
        это.гит("config", "user.name", "Фикстура")
        это.гит("config", "user.email", "fixture@example.invalid")
        for имя in ПУТИ:
            путь = это.репозиторий / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_text("# Синтетический исходник\n", encoding="utf-8")
            путь.chmod(0o644)
        (это.репозиторий / ПУТИ[0]).write_text(
            'import json, os, sys\n'
            'assert sys.flags.isolated and sys.flags.no_site and sys.flags.dont_write_bytecode\n'
            'assert "PYTHONPATH" not in os.environ and "ПОСТОРОННЕЕ" not in os.environ\n'
            'assert os.environ["PATH"] == "/usr/bin:/bin"\n'
            'assert "--исходник" in sys.argv\n'
            'print(json.dumps(json.load(sys.stdin), ensure_ascii=False))\n')
        это.коммит = это.сохранить()

    def убрать(это):
        for корень, каталоги, файлы in os.walk(это.каталог, followlinks=False):
            if not Path(корень).is_symlink():
                Path(корень).chmod(0o700)
        shutil.rmtree(это.каталог)

    def гит(это, *аргументы):
        return subprocess.run(["/usr/bin/git", "-C", str(это.репозиторий), *аргументы],
                              capture_output=True, check=True, timeout=10).stdout.decode().strip()

    def сохранить(это):
        это.гит("add", ".")
        это.гит("commit", "-qm", "Синтетический снимок")
        return это.гит("rev-parse", "HEAD")

    def команда(это, *добавка):
        return [sys.executable, "-I", "-S", "-B", str(СЦЕНАРИЙ),
                "--источник", str(это.репозиторий), "--commit", это.коммит,
                "--хранилище", str(это.хранилище), "--интерпретатор", sys.executable,
                "--корень-репозитория", str(это.данные), "--ожидаемый-cwd", str(это.данные),
                "--codex-thread-id", ЗАДАЧА, "--каталог-состояния", str(это.каталог / "состояние"),
                "--исходник", str(это.каталог / "диалог.jsonl"),
                "--файл-прогресса", "результат.py", *добавка]

    def подготовить(это, *добавка):
        результат = subprocess.run(это.команда(*добавка), capture_output=True, timeout=15)
        это.assertEqual(результат.returncode, 0, результат.stderr.decode())
        это.assertEqual(результат.stderr, b"")
        return json.loads(результат.stdout)

    def отказ_подготовки(это, причина):
        результат = subprocess.run(это.команда(), capture_output=True, timeout=15)
        это.assertEqual(результат.returncode, 2)
        это.assertIn(причина, результат.stderr.decode())
        это.assertEqual(результат.stdout, b"")

    def вызвать(это, кандидат, вход=None):
        if вход is None:
            вход = {"session_id": ЗАДАЧА, "hook_event_name": "Stop", "test": "ё ' $ `"}
        команда = кандидат["hooks"]["Stop"][0]["hooks"][0]["command"]
        return subprocess.run(["/bin/sh", "-c", команда], input=json.dumps(вход).encode(),
                              capture_output=True, timeout=5,
                              env=dict(os.environ, PYTHONPATH=str(это.каталог), ПОСТОРОННЕЕ="лишнее"))

    def test_полный_комплект_сохраняет_ввод_и_точные_байты(это):
        результат = это.подготовить()
        цель = Path(результат["каталог"])
        манифест = (цель / "манифест.json").read_bytes()
        это.assertEqual(hashlib.sha256(манифест).hexdigest(), результат["sha256"])
        это.assertEqual(цель.name, "stop-" + результат["sha256"])
        это.assertEqual(len(результат["манифест"]["файлы"]), 11)
        это.assertEqual(результат["манифест"]["схема"], "fum.комплект-Stop.3")
        for имя in ПУТИ:
            это.assertEqual((цель / имя).read_bytes(), (это.репозиторий / имя).read_bytes())
            это.assertEqual((цель / имя).stat().st_mode & 0o777, 0o400)
        процесс = это.вызвать(результат["кандидат"])
        это.assertEqual(процесс.returncode, 0, процесс.stderr)
        это.assertEqual(json.loads(процесс.stdout)["test"], "ё ' $ `")
        это.assertFalse((это.каталог / "состояние").exists())

    def test_четвёртый_исходник_обязателен(это):
        (это.репозиторий / ПУТИ[3]).unlink()
        это.коммит = это.сохранить()
        это.отказ_подготовки("источник-инвентарь")

    def test_зависимости_обеих_версий_реестра_обязательны(это):
        for имя in ПУТИ[4:]:
            with это.subTest(имя=имя):
                путь = это.репозиторий / имя
                байты = путь.read_bytes()
                путь.unlink()
                это.коммит = это.сохранить()
                это.отказ_подготовки("источник-инвентарь")
                путь.write_bytes(байты)
                это.коммит = это.сохранить()

    def test_тип_и_режим_исходника_проверяются(это):
        путь = это.репозиторий / ПУТИ[3]
        путь.chmod(0o755)
        это.коммит = это.сохранить()
        это.отказ_подготовки("источник-тип")
        путь.unlink()
        путь.symlink_to("посторонний.py")
        это.коммит = это.сохранить()
        это.отказ_подготовки("источник-тип")

    def test_плавающая_ссылка_не_заменяет_точный_коммит(это):
        это.коммит = "HEAD"
        это.отказ_подготовки("commit")

    def test_повреждение_не_исправляется_и_не_исполняется(это):
        результат = это.подготовить()
        цель = Path(результат["каталог"])
        for имя in [ПУТИ[0], "манифест.json"]:
            путь = цель / имя
            исходное = путь.read_bytes()
            путь.chmod(0o600)
            путь.write_bytes(исходное + b" ")
            путь.chmod(0o400)
            это.отказ_подготовки("повреждение")
            это.assertEqual(путь.read_bytes(), исходное + b" ")
            процесс = это.вызвать(результат["кандидат"])
            это.assertEqual(процесс.returncode, 0)
            это.assertIs(json.loads(процесс.stdout)["continue"], False)
            чужой = это.вызвать(результат["кандидат"], {"session_id": "чужая", "hook_event_name": "Stop"})
            это.assertNotIn("continue", json.loads(чужой.stdout))
            путь.chmod(0o600)
            путь.write_bytes(исходное)
            путь.chmod(0o400)

    def test_лишний_кэш_ссылка_и_неверные_права_отклоняются(это):
        результат = это.подготовить()
        цель = Path(результат["каталог"])
        цель.chmod(0o700)
        (цель / "__pycache__").mkdir(mode=0o500)
        цель.chmod(0o500)
        это.отказ_подготовки("повреждение")
        цель.chmod(0o700)
        (цель / "__pycache__").rmdir()
        (цель / "ссылка.py").symlink_to(это.репозиторий / ПУТИ[0])
        цель.chmod(0o500)
        это.отказ_подготовки("повреждение")
        цель.chmod(0o700)
        (цель / "ссылка.py").unlink()
        это.отказ_подготовки("повреждение")

    def test_повтор_и_параллельный_вход_идемпотентны(это):
        процессы = [subprocess.Popen(это.команда(), stdout=subprocess.PIPE, stderr=subprocess.PIPE) for _ in range(3)]
        результаты = []
        try:
            записи = [(процесс, *процесс.communicate(timeout=15)) for процесс in процессы]
            for процесс, вывод, ошибки in записи:
                это.assertEqual(процесс.returncode, 0, ошибки)
                результаты.append(json.loads(вывод))
        finally:
            for процесс in процессы:
                if процесс.poll() is None:
                    процесс.kill()
                процесс.communicate(timeout=5)
        это.assertEqual(результаты[0], результаты[1])
        это.assertEqual(результаты[1], результаты[2])
        цель = Path(результаты[0]["каталог"])
        def снимок():
            return {str(п): (п.stat().st_mode, п.stat().st_mtime_ns) for п in [цель, *цель.rglob("*")]}
        до = снимок()
        это.assertEqual(это.подготовить(), результаты[0])
        это.assertEqual(снимок(), до)

    def test_пути_с_кавычками_не_исполняют_оболочку(это):
        новое = это.каталог / "приватное ' $ ` кавычки"
        это.хранилище.rename(новое)
        это.хранилище = новое
        результат = это.подготовить()
        команда = результат["кандидат"]["hooks"]["Stop"][0]["hooks"][0]["command"]
        это.assertIn(результат["sha256"], shlex.split(команда))
        процесс = это.вызвать(результат["кандидат"])
        это.assertEqual(процесс.returncode, 0, процесс.stderr)
        это.assertEqual(json.loads(процесс.stdout)["test"], "ё ' $ `")

    def test_приватная_цель_под_репозиторием_и_ссылкой_запрещена(это):
        (это.хранилище / ".git").mkdir()
        это.отказ_подготовки("git-предок")
        (это.хранилище / ".git").rmdir()
        это.хранилище = это.каталог / "ссылка"
        это.хранилище.symlink_to(это.каталог / "приватное", target_is_directory=True)
        это.отказ_подготовки("путь-ссылка")

    def test_незакоммиченные_байты_не_подменяют_источник(это):
        исходное = (это.репозиторий / ПУТИ[0]).read_bytes()
        (это.репозиторий / ПУТИ[0]).write_text("raise RuntimeError('подмена')\n")
        результат = это.подготовить()
        это.assertEqual((Path(результат["каталог"]) / ПУТИ[0]).read_bytes(), исходное)

    def test_подмена_объекта_репозитория_отклоняется(это):
        идентификатор = это.гит("rev-parse", это.коммит + ":" + ПУТИ[0])
        путь = это.репозиторий / ".git/objects" / идентификатор[:2] / идентификатор[2:]
        путь.chmod(0o600)
        путь.write_bytes(zlib.compress(b"blob 1\0x"))
        это.отказ_подготовки("источник-хэш")

    def test_подмена_промежуточного_дерева_не_меняет_источник(это):
        подкаталог = str(Path(ПУТИ[0]).parent)
        дерево = это.гит("rev-parse", это.коммит + ":" + подкаталог)
        исходный = это.гит("rev-parse", это.коммит + ":" + ПУТИ[0])
        подмена = subprocess.run(["/usr/bin/git", "-C", str(это.репозиторий), "hash-object", "-w", "--stdin"],
                                input=b"print('different valid blob')\n", capture_output=True, check=True).stdout.decode().strip()
        данные = subprocess.run(["/usr/bin/git", "-C", str(это.репозиторий), "cat-file", "tree", дерево],
                                capture_output=True, check=True).stdout
        это.assertEqual(данные.count(bytes.fromhex(исходный)), 1)
        данные = данные.replace(bytes.fromhex(исходный), bytes.fromhex(подмена))
        путь = это.репозиторий / ".git/objects" / дерево[:2] / дерево[2:]
        путь.chmod(0o600)
        путь.write_bytes(zlib.compress(b"tree " + str(len(данные)).encode() + b"\0" + данные))
        это.отказ_подготовки("источник-хэш")

    def test_жёсткая_ссылка_и_спецфайл_не_читаются(это):
        результат = это.подготовить()
        путь = Path(результат["каталог"]) / ПУТИ[0]
        os.link(путь, это.каталог / "вторая-ссылка")
        это.отказ_подготовки("повреждение")
        (это.каталог / "вторая-ссылка").unlink()
        путь.parent.chmod(0o700)
        путь.unlink()
        os.mkfifo(путь, mode=0o400)
        путь.parent.chmod(0o500)
        это.отказ_подготовки("повреждение")

    def test_коллизия_с_файлом_не_заменяется(это):
        результат = это.подготовить()
        цель = Path(результат["каталог"])
        цель.rename(цель.with_name("сохранённый-комплект"))
        цель.write_text("пользовательские байты")
        это.отказ_подготовки("повреждение")
        это.assertEqual(цель.read_text(), "пользовательские байты")

    def test_код_выхода_и_сигнал_не_подменяются(это):
        путь = это.репозиторий / ПУТИ[0]
        путь.write_text("raise SystemExit(7)\n")
        это.коммит = это.сохранить()
        результат = это.подготовить()
        процесс = это.вызвать(результат["кандидат"])
        это.assertEqual(процесс.returncode, 7)
        это.assertEqual(процесс.stdout, b"")
        путь.write_text("import signal\nprint('готов', flush=True)\nsignal.pause()\n")
        это.коммит = это.сохранить()
        результат = это.подготовить()
        команда = результат["кандидат"]["hooks"]["Stop"][0]["hooks"][0]["command"]
        with subprocess.Popen(["/bin/sh", "-c", команда], stdout=subprocess.PIPE, stderr=subprocess.PIPE) as процесс:
            это.assertEqual(процесс.stdout.readline().decode().strip(), "готов")
            процесс.send_signal(signal.SIGTERM)
            вывод, ошибки = процесс.communicate(timeout=5)
            это.assertEqual(процесс.returncode, -signal.SIGTERM)
            это.assertEqual((вывод, ошибки), (b"", b""))

    def test_первое_создание_хранилища_не_гоняется(это):
        это.хранилище.rmdir()
        описание = importlib.util.spec_from_file_location("подготовка_для_теста", СЦЕНАРИЙ)
        модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(модуль)
        аргументы = argparse.Namespace(источник=str(это.репозиторий), commit=это.коммит,
            хранилище=str(это.хранилище), интерпретатор=sys.executable,
            корень_репозитория=str(это.данные), ожидаемый_cwd=str(это.данные),
            codex_thread_id=ЗАДАЧА, каталог_состояния=str(это.каталог / "состояние"),
            файл_прогресса=["результат.py"], план=None, исходник=str(это.каталог / "диалог.jsonl"), кэш=None)
        исходный = Path.mkdir
        барьер = threading.Barrier(2)
        def создать(путь, *позиционные, **именованные):
            if путь == это.хранилище:
                барьер.wait(timeout=5)
            return исходный(путь, *позиционные, **именованные)
        with mock.patch.object(Path, "mkdir", создать), ThreadPoolExecutor(max_workers=2) as исполнители:
            результаты = list(исполнители.map(модуль.подготовить, [аргументы, аргументы]))
        это.assertEqual(результаты[0], результаты[1])

    def test_приватная_цель_в_голом_репозитории_запрещена(это):
        subprocess.run(["/usr/bin/git", "init", "--bare", "-q", str(это.хранилище)], check=True)
        это.отказ_подготовки("git-предок")

    def test_доступный_для_чужой_записи_предок_запрещён(это):
        предок = это.каталог / "общая-запись"
        предок.mkdir()
        предок.chmod(0o777)
        это.хранилище = предок / "приватное"
        это.отказ_подготовки("права-предка")

    def test_закрытая_схема_после_проверки_хэша(это):
        результат = это.подготовить()
        цель = Path(результат["каталог"])
        путь = цель / "манифест.json"
        описание = importlib.util.spec_from_file_location("проверка_схемы", СЦЕНАРИЙ)
        модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(модуль)
        исходные = json.loads(путь.read_bytes())
        варианты = []
        for изменить in (lambda м: м.update(лишнее=True),
                        lambda м: м.update(схема="fum.комплект-Stop.1"),
                        lambda м: м["файлы"].pop(),
                        lambda м: м["файлы"][0].update(размер=True),
                        lambda м: м["выполнение"].update(лишнее=True)):
            значение = json.loads(json.dumps(исходные))
            изменить(значение)
            варианты.append(json.dumps(значение, ensure_ascii=False).encode())
        варианты.append(b'{"commit":"' + исходные["commit"].encode() + b'",' + путь.read_bytes()[1:])
        for данные in варианты:
            путь.chmod(0o600)
            путь.write_bytes(данные)
            путь.chmod(0o400)
            with это.assertRaises(ValueError):
                модуль.ПРОВЕРКА["проверить"](цель, hashlib.sha256(данные).hexdigest(), адрес=False)

    def test_вынесенный_общий_каталог_также_запрещён(это):
        общий = это.каталог / "общие-объекты"
        subprocess.run(["/usr/bin/git", "init", "--bare", "-q", str(общий)], check=True)
        административный = это.каталог / "административный"
        административный.mkdir(mode=0o700)
        (административный / "HEAD").write_text("ref: refs/heads/master\n")
        (административный / "commondir").write_text(str(общий) + "\n")
        подтверждение = subprocess.run(["/usr/bin/git", "--git-dir=" + str(административный),
                                       "rev-parse", "--git-common-dir"], capture_output=True, check=True)
        это.assertEqual(подтверждение.stdout.decode().strip(), str(общий))
        это.хранилище = административный / "приватное"
        это.отказ_подготовки("git-предок")

    def test_неопределённый_и_незакрытый_ввод_при_повреждении_ограничен(это):
        результат = это.подготовить()
        путь = Path(результат["каталог"]) / "манифест.json"
        путь.chmod(0o600)
        путь.write_bytes(b"{")
        путь.chmod(0o400)
        команда = результат["кандидат"]["hooks"]["Stop"][0]["hooks"][0]["command"]
        for вход in (b"{", b"x" * 65537, b"\xff", b"[" * 1500):
            процесс = subprocess.run(["/bin/sh", "-c", команда], input=вход, capture_output=True, timeout=3)
            это.assertEqual(процесс.returncode, 0)
            это.assertEqual(set(json.loads(процесс.stdout)), {"systemMessage"})
        with subprocess.Popen(["/bin/sh", "-c", команда], stdin=subprocess.PIPE,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE) as процесс:
            процесс.wait(timeout=3)
            вывод, ошибки = процесс.communicate(timeout=1)
            это.assertEqual(процесс.returncode, 0)
            это.assertEqual(set(json.loads(вывод)), {"systemMessage"})
            это.assertEqual(ошибки, b"")


if __name__ == "__main__":
    unittest.main()
