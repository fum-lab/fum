"""Настоящие Git/JSONL и закрытая копия reader; только временные фикстуры."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import types
import unittest
from unittest import mock

корень_регистратора = Path(__file__).resolve().parents[1]
корень_читателя = корень_регистратора.parent / "ПривязкаИсполнителя"
запрос_фикстуры = "Журнал/2026-10-01_00-00-00_MSK_проверить-привязку/запрос.md"
корневая_задача = "00000000-0000-0000-0000-000000000001"
собственный_исполнитель = "00000000-0000-0000-0000-000000000002"


def гит_фикстуры(корень, *аргументы):
    среда = {к: в for к, в in os.environ.items() if not к.startswith("GIT_")}
    среда.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
    return subprocess.check_output(["git", "--no-optional-locks", "-C", str(корень), *аргументы],
                                   env=среда, stderr=subprocess.PIPE).decode().strip()


def создать_поручение(корень, основание):
    постановка = корень / "Планирование/условие.md"
    постановка.parent.mkdir(exist_ok=True)
    постановка.write_text("Проверить только открытую временную фикстуру.\n")
    гит_фикстуры(корень, "add", "--", "Планирование/условие.md")
    гит_фикстуры(корень, "commit", "-qm", "Закрепить условие фикстуры")
    начало = гит_фикстуры(корень, "rev-parse", "HEAD")
    команда = "Проверить собственное поручение без живой зависимости.\n"
    источник = основание / "нативный.jsonl"
    события = [
        {"type": "session_meta", "payload": {"id": собственный_исполнитель,
         "cwd": str(корень), "thread_source": "agent_created_thread", "git": {"commit_hash": начало}}},
        {"type": "turn_context", "payload": {"cwd": str(корень), "model": "gpt-6.1-sol", "effort": "ultra"}},
        {"type": "response_item", "payload": {"type": "function_call_output", "name": "create_thread",
         "output": "<codex_delegation>\n  <source_thread_id>" + корневая_задача
         + "</source_thread_id>\n  <input>" + команда + "</input>\n</codex_delegation>"}},
    ]
    источник.write_text("".join(json.dumps(с, ensure_ascii=False) + "\n" for с in события))
    акт = {"схема": "fum.поручение-дочерней-контрольной-точки.1", "координатор": корневая_задача,
           "исполнитель": собственный_исполнитель, "ветка": гит_фикстуры(корень, "symbolic-ref", "HEAD"),
           "область": [str(Path(запрос_фикстуры).parent) + "/"],
           "постановка": {"коммит": начало, "путь": "Планирование/условие.md",
                         "sha256": hashlib.sha256(постановка.read_bytes()).hexdigest()},
           "хэш_нативного_поручения": hashlib.sha256(команда.encode()).hexdigest()}
    путь_акта = корень / "Планирование/поручение.json"
    путь_акта.write_text(json.dumps(акт, ensure_ascii=False) + "\n")
    гит_фикстуры(корень, "add", "--", "Планирование/поручение.json")
    гит_фикстуры(корень, "commit", "-qm", "Назначить исполнителя фикстуры")
    выбор = {"координатор": корневая_задача, "исполнитель": собственный_исполнитель,
             "коммит": гит_фикстуры(корень, "rev-parse", "HEAD"), "путь": "Планирование/поручение.json",
             "sha256": hashlib.sha256(путь_акта.read_bytes()).hexdigest()}
    параметры = {"схема": "fum.создание-коммита.7", "режим": "контрольная-точка",
                 "задача": корневая_задача, "исполнитель": собственный_исполнитель,
                 "корень": str(корень), "ветка": акт["ветка"], "исходный_коммит": выбор["коммит"],
                 "источник_модели": str(источник), "выбранное_поручение": dict(выбор),
                 "запрос": запрос_фикстуры,
                 "история_модели": str(Path(запрос_фикстуры).parent / "материалы/модель.json"),
                 "разрешённые_цели": [запрос_фикстуры]}
    return параметры, выбор


class ПроверкаПривязки(unittest.TestCase):
    def setUp(сам):
        временный = tempfile.TemporaryDirectory(prefix="fum-actor-fixture-")
        сам.addCleanup(временный.cleanup)
        сам.основание = Path(временный.name).resolve()
        сам.корень = сам.основание / "дерево"
        сам.корень.mkdir()
        гит_фикстуры(сам.корень, "init", "-q", "-b", "codex/фикстура")
        гит_фикстуры(сам.корень, "config", "user.name", "FUM Test")
        гит_фикстуры(сам.корень, "config", "user.email", "test@example.invalid")
        сам.параметры, сам.выбор = создать_поручение(сам.корень, сам.основание)
        сам.зеркало = сам.основание / "зеркало"
        shutil.copytree(корень_читателя, сам.зеркало)
        сам.среда = mock.patch.dict(os.environ, {"CODEX_THREAD_ID": собственный_исполнитель})
        сам.среда.start()
        сам.addCleanup(сам.среда.stop)

    def загрузчик(сам):
        путь = корень_регистратора / "scripts/привязка_исполнителя.py"
        сам.assertTrue(путь.is_file(), "нет предметного загрузчика проверки исполнителя")
        описание = importlib.util.spec_from_file_location("предметная_привязка_фикстуры", путь)
        модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(модуль)
        return модуль

    def вызвать(сам, модуль, выбор=None, профиль=None):
        return модуль.проверить(сам.параметры, сам.выбор if выбор is None else выбор,
                               зеркало=сам.зеркало, профиль=профиль)

    def test_проверяет_настоящие_акт_и_нативный_префикс_в_частной_копии(сам):
        модуль = сам.загрузчик()
        индекс = (сам.корень / ".git/index").read_bytes()
        профиль = {}
        результат = сам.вызвать(модуль, профиль=профиль)
        сам.assertEqual(сам.выбор, результат["выбранное_поручение"])
        сам.assertGreater(результат["нативное_поручение"]["граница"], результат["нативное_начало"]["граница"])
        сам.assertEqual(индекс, (сам.корень / ".git/index").read_bytes())
        сам.assertFalse((сам.корень / "Журнал").exists())
        сам.assertTrue(профиль["модули_копии"])
        сам.assertTrue(all(not Path(п).exists() and str(сам.зеркало) not in п for п in профиль["модули_копии"]))
        сам.assertGreater(профиль["весь_загрузчик"], 0)

    def test_нет_или_изменился_независимый_выбор_значит_нет_работника(сам):
        модуль = сам.загрузчик()
        for выбор in (None, dict(сам.выбор, sha256="0" * 64)):
            with сам.subTest(выбор=выбор), mock.patch.object(модуль.subprocess, "Popen") as запуск:
                with сам.assertRaisesRegex(ValueError, "независим"):
                    модуль.проверить(сам.параметры, выбор, зеркало=сам.зеркало)
                запуск.assert_not_called()

    def test_подмена_кода_лишний_файл_и_ссылка_отказывают_до_работника(сам):
        модуль = сам.загрузчик()
        исходник = next(сам.зеркало.rglob("обычное_поручение.py"))
        оригинал = исходник.read_bytes()
        for вид in ("код", "лишний", "ссылка"):
            with сам.subTest(вид=вид):
                if вид == "код":
                    исходник.write_bytes(оригинал + b"\nraise RuntimeError('foreign code')\n")
                else:
                    лишний = сам.зеркало / "посторонний.py"
                    лишний.write_text("raise RuntimeError('foreign code')\n") if вид == "лишний" else лишний.symlink_to(исходник)
                with mock.patch.object(модуль.subprocess, "Popen") as запуск:
                    with сам.assertRaises(ValueError):
                        сам.вызвать(модуль)
                    запуск.assert_not_called()
                исходник.write_bytes(оригинал) if вид == "код" else лишний.unlink()

    def test_чужой_загруженный_читатель_закрывает_путь(сам):
        модуль = сам.загрузчик()
        чужой = types.ModuleType("обычное_поручение")
        with mock.patch.dict(sys.modules, {"обычное_поручение": чужой}), mock.patch.object(модуль.subprocess, "Popen") as запуск:
            with сам.assertRaisesRegex(ValueError, "модул"):
                сам.вызвать(модуль)
            запуск.assert_not_called()

    def test_поздняя_подмена_исходника_не_исполняется_и_закрывает_возврат(сам):
        модуль = сам.загрузчик()
        исходник = next(сам.зеркало.rglob("обычное_поручение.py"))
        оригинал = исходник.read_bytes()
        настоящий = subprocess.Popen
        профиль = {}
        def запустить(*а, **п):
            исходник.write_bytes(оригинал + b"\nraise RuntimeError('foreign code')\n")
            return настоящий(*а, **п)
        with mock.patch.object(модуль.subprocess, "Popen", new=запустить):
            with сам.assertRaisesRegex(ValueError, "зеркал|байт|состав"):
                сам.вызвать(модуль, профиль=профиль)
        сам.assertTrue(профиль["читатель"])

    def test_чужая_вершина_и_нативный_идентификатор_отказывают(сам):
        модуль = сам.загрузчик()
        for поле, значение in (("исходный_коммит", "0" * 40), ("исполнитель", корневая_задача), ("лишнее", True)):
            with сам.subTest(поле=поле):
                параметры = dict(сам.параметры)
                параметры[поле] = значение
                with сам.assertRaises(ValueError):
                    модуль.проверить(параметры, сам.выбор, зеркало=сам.зеркало)

    def test_поздняя_подмена_частной_копии_не_исполняет_чужие_байты(сам):
        модуль = сам.загрузчик()
        метка = сам.основание / "чужой-код-исполнен.txt"
        настоящий = subprocess.Popen
        def запустить(аргументы, **параметры):
            файл = next(Path(аргументы[-1]).rglob("обычное_поручение.py"))
            файл.chmod(0o644)
            файл.write_bytes(файл.read_bytes() + ("\nfrom pathlib import Path\nPath(" + repr(str(метка))
                                                + ").write_text('foreign')\n").encode())
            return настоящий(аргументы, **параметры)
        with mock.patch.object(модуль.subprocess, "Popen", new=запустить):
            with сам.assertRaises(ValueError):
                сам.вызвать(модуль)
        сам.assertFalse(метка.exists(), "поздние чужие байты были исполнены до отказа")

    def test_нулевой_нативный_префикс_не_является_успехом_работника(сам):
        модуль = сам.загрузчик()
        ответ = {"схема": "fum.предметная-привязка.1", "результат": {
                    "выбранное_поручение": сам.выбор, "нативное_начало": None, "нативное_поручение": None},
                 "читатель": [], "загрузка": -1, "модули": []}
        код = "import json; print(json.dumps(" + repr(ответ) + "))"
        with mock.patch.object(модуль, "код_работника", код):
            with сам.assertRaisesRegex(ValueError, "ответ|префикс"):
                сам.вызвать(модуль)

    def test_только_строгий_текстовый_объект_без_дублей_и_переполнения(сам):
        модуль = сам.загрузчик()
        for байты in ('{}'.encode("utf-16"), b'{"a":1,"a":2}', b'{"a":NaN}', b'{}{}',
                      b'[' * 2000 + b']' * 2000, b' ' * (модуль.предел_обмена + 1)):
            with сам.subTest(размер=len(байты)), сам.assertRaises(ValueError):
                модуль.разобрать(байты)

    def test_переполнение_вывода_прерывает_ещё_живую_группу_и_удаляет_копию(сам):
        модуль = сам.загрузчик()
        процессы = []
        настоящий = subprocess.Popen
        def запустить(*а, **п):
            процесс = настоящий(*а, **п)
            процессы.append((процесс, Path(а[0][-1])))
            return процесс
        путь_потомка = сам.основание / "потомок.txt"
        код = ("import sys,time,subprocess; from pathlib import Path; "
               "потомок=subprocess.Popen([sys.executable,'-I','-B','-S','-c','import time;time.sleep(30)']); "
               "Path(" + repr(str(путь_потомка)) + ").write_text(str(потомок.pid)); "
               "sys.stdout.buffer.write(b'x'*300000); sys.stdout.flush(); time.sleep(30)")
        начало = time.perf_counter()
        with mock.patch.object(модуль, "код_работника", код), mock.patch.object(модуль, "тайм_аут", 2), \
                mock.patch.object(модуль.subprocess, "Popen", new=запустить):
            with сам.assertRaises(ValueError):
                сам.вызвать(модуль)
        сам.assertLess(time.perf_counter() - начало, 1, "переполнение ждёт общего тайм-аута")
        сам.assertIsNotNone(процессы[0][0].returncode)
        сам.assertFalse(процессы[0][1].exists())
        потомок = int(путь_потомка.read_text())
        сам.assertNotEqual(процессы[0][0].pid, потомок)
        состояние = subprocess.run(["ps", "-o", "stat=", "-p", str(потомок)],
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        сам.assertTrue(состояние.returncode == 1 or состояние.stdout.strip().startswith("Z"),
                       "отдельный потомок продолжает исполняться")

    def test_чужой_каталог_отказывает_до_обхода_его_содержимого(сам):
        модуль = сам.загрузчик()
        каталог = сам.зеркало / "чужой-каталог"
        каталог.mkdir()
        def обход(*а, **п):
            yield каталог
            raise RuntimeError("обход чужого поддерева продолжен")
        with mock.patch.object(Path, "rglob", new=обход):
            with сам.assertRaises(ValueError):
                сам.вызвать(модуль)

    def test_удержанные_байты_помощника_не_заменяются_поздним_исходником_и_байткодом(сам):
        модуль = сам.загрузчик()
        метка = сам.основание / "поздний-помощник-исполнен.txt"
        точка = "начало = time.perf_counter_ns()\nimport обычное_поручение"
        сам.assertEqual(1, модуль.код_работника.count(точка))
        подмена = ("исходник = pathlib.Path(модули_по_имени['сверить-материалы-этапа'])\n"
                   "исходник.chmod(0o644)\n"
                   "чужое = " + repr("from pathlib import Path\nPath(" + repr(str(метка)) + ").write_text('foreign')\n") + "\n"
                   "исходник.write_text(чужое)\nисходник.chmod(0o400)\n"
                   "import importlib._bootstrap_external\n"
                   "кэш = pathlib.Path(importlib.util.cache_from_source(str(исходник)))\n"
                   "кэш.parent.mkdir()\n"
                   "состояние = исходник.stat()\n"
                   "кэш.write_bytes(importlib._bootstrap_external._code_to_timestamp_pyc(compile(чужое, str(исходник), 'exec'), int(состояние.st_mtime), состояние.st_size))\n")
        код = модуль.код_работника.replace(точка, подмена + точка)
        профиль = {}
        with mock.patch.object(модуль, "код_работника", код):
            with сам.assertRaises(ValueError):
                сам.вызвать(модуль, профиль=профиль)
        сам.assertTrue(профиль["читатель"], "удержанные исходники не выполнили настоящий reader")
        сам.assertFalse(метка.exists())

    def test_нативный_канал_останавливается_общим_тайм_аутом(сам):
        модуль = сам.загрузчик()
        путь = Path(сам.параметры["источник_модели"])
        путь.unlink()
        os.mkfifo(путь)
        процессы = []
        настоящий = subprocess.Popen
        def запустить(*а, **п):
            процесс = настоящий(*а, **п)
            процессы.append((процесс, Path(а[0][-1])))
            return процесс
        with mock.patch.object(модуль, "тайм_аут", 0.25), mock.patch.object(модуль.subprocess, "Popen", new=запустить):
            with сам.assertRaisesRegex(ValueError, "тайм-аут"):
                сам.вызвать(модуль)
        сам.assertIsNotNone(процессы[0][0].returncode)
        сам.assertFalse(процессы[0][1].exists())

    def test_неверный_тип_входа_не_исправляется_сериализацией(сам):
        модуль = сам.загрузчик()
        параметры = dict(сам.параметры)
        параметры["разрешённые_цели"] = tuple(параметры["разрешённые_цели"])
        with сам.assertRaisesRegex(ValueError, "тип|список"):
            модуль.проверить(параметры, сам.выбор, зеркало=сам.зеркало)

    def test_параметры_изменились_после_сериализации_значит_нет_положительного_ответа(сам):
        модуль = сам.загрузчик()
        настоящий = subprocess.Popen
        def запустить(*а, **п):
            сам.параметры["исходный_коммит"] = "0" * 40
            return настоящий(*а, **п)
        with mock.patch.object(модуль.subprocess, "Popen", new=запустить):
            with сам.assertRaisesRegex(ValueError, "вход|параметр"):
                сам.вызвать(модуль)

    def test_профиль_не_может_изменять_проверяемый_вход(сам):
        модуль = сам.загрузчик()
        до = json.dumps(сам.выбор, sort_keys=True)
        with сам.assertRaisesRegex(ValueError, "профил"):
            сам.вызвать(модуль, профиль=сам.выбор)
        сам.assertEqual(до, json.dumps(сам.выбор, sort_keys=True))
