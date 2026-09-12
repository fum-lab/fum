"""Происхождение проверок слияния на настоящих Git-объектах."""
import hashlib
import importlib.util
import json
import os
import py_compile
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class КонтурСлияния(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.источник = Path(сам.временный.name).resolve() / "master"
        сам.кандидат = сам.источник.parent / "кандидат"
        сам.источник.mkdir()
        путь = Path(__file__).resolve().parents[1] / "scripts/контур_слияния.py"
        if os.environ.get("FUM_CHECKED_CODE_ROOT"):
            путь = Path(os.environ["FUM_CHECKED_CODE_ROOT"]) / путь.relative_to(Path(__file__).resolve().parents[3])
        спецификация = importlib.util.spec_from_file_location("контур_слияния_для_теста", путь)
        сам.модуль = importlib.util.module_from_spec(спецификация)
        спецификация.loader.exec_module(сам.модуль)
        сам.гит(сам.источник, "init", "-qb", "master")
        сам.гит(сам.источник, "config", "user.name", "Проверка FUM")
        сам.гит(сам.источник, "config", "user.email", "fum-tests@example.invalid")
        for относительный in ("AGENTS.md", ".codex/config.toml", ".gitmodules", "Правила/агентов/норма.md",
                              "Инструменты/пример/tests/test_пример.py", "Инструменты/пример/fixtures/образец.txt",
                              "Инструменты/пример/scripts/helper.py", "Инструменты/fum-proverka-nazvanij-avtomatizacij/Package.swift"):
            путь = сам.источник / относительный
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_text("Исходный проверяемый материал.\n")
        for область in сам.модуль.ВЛОЖЕННЫЕ_ИНСТРУМЕНТЫ:
            путь = сам.источник / область / "scripts/helper.py"
            путь.parent.mkdir(parents=True)
            путь.write_text("Исходный вложенный модуль.\n")
        (сам.источник / ".gitmodules").write_text('[submodule "LinguisticKit"]\n\tpath = Зависимости/LinguisticKit\n\turl = https://example.invalid/LinguisticKit.git\n')
        корень_реализации = Path(os.environ.get("FUM_CHECKED_CODE_ROOT", Path(__file__).resolve().parents[3]))
        относительный = Path("Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/граница_зависимостей_слияния.py")
        (сам.источник / относительный).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(корень_реализации / относительный, сам.источник / относительный)
        зависимость = сам.источник / "Зависимости/LinguisticKit"
        зависимость.mkdir(parents=True)
        сам.гит(зависимость, "init", "-qb", "master")
        сам.гит(зависимость, "config", "user.name", "Проверка FUM")
        сам.гит(зависимость, "config", "user.email", "fum-tests@example.invalid")
        (зависимость / "исходник.swift").write_text("Исходник зависимости.\n")
        сам.гит(зависимость, "add", ".")
        сам.гит(зависимость, "commit", "-qm", "Зависимость")
        сам.ревизия_зависимости = сам.гит(зависимость, "rev-parse", "HEAD")
        сам.гит(сам.источник, "add", "AGENTS.md", ".codex", ".gitmodules", "Правила", "Инструменты")
        сам.гит(сам.источник, "update-index", "--add", "--cacheinfo", "160000," + сам.ревизия_зависимости + ",Зависимости/LinguisticKit")
        сам.гит(сам.источник, "commit", "-qm", "Исходная основа")
        сам.гит(сам.источник, "worktree", "add", "-qb", "codex/ведущая", str(сам.кандидат))
        (сам.кандидат / "результат.txt").write_text("Предлагаемый результат.\n")
        сам.гит(сам.кандидат, "add", "результат.txt")
        сам.гит(сам.кандидат, "commit", "-qm", "Ведущая основа")
        сам.ведущая = сам.гит(сам.кандидат, "rev-parse", "HEAD")
        политика = сам.источник / сам.модуль.ПОЛИТИКА
        политика.parent.mkdir(parents=True, exist_ok=True)
        политика.write_text("{}\n")
        происхождение = {
            "схема": "fum.политика-слияния.1", "ведущая_основа": сам.ведущая,
            "дерево_основы": сам.гит(сам.кандидат, "rev-parse", "HEAD^{tree}"),
            "путь_политики": сам.модуль.ПОЛИТИКА.as_posix(),
            "хэш_политики": "sha256:" + hashlib.sha256(политика.read_bytes()).hexdigest(),
            "принятие_слияния": False, "прежних_исключений": 0, "дополнительных_исключений": 0,
        }
        (сам.источник / сам.модуль.ПРОИСХОЖДЕНИЕ_ПОЛИТИКИ).write_text(json.dumps(происхождение, ensure_ascii=False))
        сам.гит(сам.источник, "add", "Инструменты")
        сам.гит(сам.источник, "commit", "-qm", "Принятый источник проверок")
        сам.вершина = сам.гит(сам.источник, "rev-parse", "HEAD")
        сам.гит(сам.кандидат, "merge", "--no-ff", "--no-commit", сам.вершина)
        shutil.copytree(зависимость, сам.кандидат / "Зависимости/LinguisticKit", dirs_exist_ok=True)

    @staticmethod
    def гит(корень, *аргументы):
        среда = {к: з for к, з in os.environ.items() if not к.startswith("GIT_")}
        итог = subprocess.run(["git", "-C", str(корень), *аргументы], env=среда, capture_output=True)
        if итог.returncode:
            raise AssertionError(итог.stderr.decode())
        return итог.stdout.decode().strip()

    def проверить(сам):
        return сам.модуль.проверить_контур(сам.источник, сам.вершина, сам.кандидат, сам.ведущая)

    def test_снимок_связывает_источник_родителей_политику_и_зависимость(сам):
        снимок = сам.проверить()
        сам.assertEqual(снимок["источник"], сам.вершина)
        сам.assertEqual(снимок["ведущая_основа"], сам.ведущая)
        сам.assertEqual(снимок["зависимость"], сам.ревизия_зависимости)
        сам.assertNotIn(str(сам.источник), json.dumps(снимок, ensure_ascii=False))

    def test_подмена_описания_модулей_кандидата_не_скрывается_за_той_же_зависимостью(сам):
        путь = сам.кандидат / ".gitmodules"
        путь.write_bytes(путь.read_bytes() + b"\tbranch = unapproved\n")
        сам.гит(сам.кандидат, "add", ".gitmodules")
        with сам.assertRaises(ValueError):
            сам.проверить()

    def test_дополнительная_зависимость_не_скрывается_за_языковой(сам):
        сам.гит(сам.кандидат, "update-index", "--add", "--cacheinfo", "160000,"
                + сам.ревизия_зависимости + ",Зависимости/посторонняя")
        with сам.assertRaises(ValueError):
            сам.проверить()

    def test_поздняя_подмена_проверяющего_файла_отклоняется(сам):
        сам.проверить()
        for относительный in ("AGENTS.md", "Правила/агентов/норма.md", "Инструменты/пример/tests/test_пример.py",
                              "Инструменты/пример/fixtures/образец.txt", "Инструменты/пример/scripts/helper.py", сам.модуль.ПОЛИТИКА):
            путь = сам.источник / относительный
            байты = путь.read_bytes()
            with сам.subTest(путь=str(относительный)):
                путь.write_bytes(байты + b"x")
                with сам.assertRaises(ValueError): сам.проверить()
                путь.write_bytes(байты)

    def test_неотслеживаемый_модуль_и_символическая_ссылка_отклоняются(сам):
        путь = сам.источник / "Инструменты/пример/scripts/подмена.py"
        путь.write_text("pass\n")
        with сам.assertRaises(ValueError): сам.проверить()
        путь.unlink()
        путь = сам.источник / "Инструменты/пример/scripts/helper.py"
        байты = путь.read_bytes()
        внешний = сам.источник.parent / "внешний.py"
        внешний.write_bytes(байты)
        путь.unlink(); путь.symlink_to(внешний)
        with сам.assertRaises(ValueError): сам.проверить()

    def test_лишний_индексированный_модуль_тоже_отклоняется(сам):
        for корень, область in ((сам.источник, "Инструменты/пример"),
                                (сам.кандидат, сам.модуль.ВЛОЖЕННЫЕ_ИНСТРУМЕНТЫ[0])):
            путь = корень / область / "scripts/добавленный.py"
            путь.write_text("pass\n")
            сам.гит(корень, "add", str(путь))
            with сам.subTest(корень=корень.name), сам.assertRaises(ValueError): сам.проверить()
            сам.гит(корень, "rm", "-f", str(путь))

    def test_замена_master_и_неполный_oid_отклоняются(сам):
        вершина = сам.вершина
        for значение in ("HEAD", вершина[:12], сам.ведущая):
            with сам.subTest(значение=значение), сам.assertRaises(ValueError):
                сам.модуль.проверить_контур(сам.источник, значение, сам.кандидат, сам.ведущая)
        сам.гит(сам.источник, "symbolic-ref", "HEAD", "refs/heads/другая")
        with сам.assertRaises(ValueError): сам.проверить()

    def test_родительская_ссылка_зависимости_отклоняется(сам):
        путь = сам.кандидат / "Зависимости"
        внешний = сам.источник.parent / "внешние-зависимости"
        путь.rename(внешний)
        путь.symlink_to(внешний, target_is_directory=True)
        with сам.assertRaises(ValueError): сам.проверить()

    def test_скрытый_импортируемый_файл_кандидата_отклоняется(сам):
        (сам.кандидат / ".gitignore").write_text("*.pyc\n")
        путь = сам.кандидат / "Инструменты/пример/scripts/подмена.pyc"
        путь.write_bytes(b"unknown bytecode")
        with сам.assertRaises(ValueError): сам.проверить()

    def test_изменённая_рабочая_обёртка_кандидата_отклоняется(сам):
        путь = сам.кандидат / сам.модуль.АРХИВИРУЕМАЯ_ОБЁРТКА / "Package.swift"
        путь.write_text("Новая непроверенная обёртка.\n")
        сам.гит(сам.кандидат, "add", str(путь))
        with сам.assertRaises(ValueError): сам.проверить()

    def test_одинаковый_oid_не_заменяет_режим_gitlink(сам):
        def объект(тип, данные):
            итог = subprocess.run(["git", "-C", str(сам.источник), "hash-object", "--literally", "-w", "-t", тип, "--stdin"], input=данные, capture_output=True, check=True)
            return итог.stdout.decode().strip()
        def байты(спецификация):
            return subprocess.check_output(["git", "-C", str(сам.источник), "cat-file", "-p", спецификация])
        старое_дерево = сам.гит(сам.источник, "rev-parse", "HEAD:Зависимости")
        дерево_зависимостей = subprocess.check_output(["git", "-C", str(сам.источник), "cat-file", "tree", старое_дерево])
        новое_дерево = объект("tree", дерево_зависимостей.replace(b"160000 LinguisticKit\0", b"100644 LinguisticKit\0"))
        дерево_корня = subprocess.check_output(["git", "-C", str(сам.источник), "cat-file", "tree", "HEAD^{tree}"])
        новый_корень = объект("tree", дерево_корня.replace(bytes.fromhex(старое_дерево), bytes.fromhex(новое_дерево)))
        коммит = байты("HEAD")
        сам.вершина = объект("commit", b"tree " + новый_корень.encode() + b"\n" + коммит.split(b"\n", 1)[1])
        сам.гит(сам.источник, "update-ref", "refs/heads/master", сам.вершина)
        путь_merge = Path(сам.гит(сам.кандидат, "rev-parse", "--path-format=absolute", "--git-path", "MERGE_HEAD"))
        путь_merge.write_text(сам.вершина + "\n")
        with сам.assertRaisesRegex(ValueError, "gitlink"): сам.проверить()

    def test_изменённая_архивируемая_обёртка_и_зависимость_отклоняются(сам):
        зависимость = сам.кандидат / "Зависимости/LinguisticKit/исходник.swift"
        зависимость.write_text("Подмена зависимости.\n")
        with сам.assertRaises(ValueError): сам.проверить()
        сам.гит(зависимость.parent, "checkout", "--", "исходник.swift")
        пакет = сам.источник / "Инструменты/fum-proverka-nazvanij-avtomatizacij/Package.swift"
        пакет.write_text("Новая архивируемая реализация.\n")
        сам.гит(сам.источник, "add", str(пакет))
        сам.гит(сам.источник, "commit", "-qm", "Другая обёртка")
        сам.вершина = сам.гит(сам.источник, "rev-parse", "HEAD")
        путь_merge = Path(сам.гит(сам.кандидат, "rev-parse", "--path-format=absolute", "--git-path", "MERGE_HEAD"))
        путь_merge.write_text(сам.вершина + "\n")
        with сам.assertRaisesRegex(ValueError, "архивируем|Package.swift"): сам.проверить()

    def test_явная_команда_не_может_сократить_полную_проверку(сам):
        запрос = "Журнал/2026-09-10_00-00-00_MSK/запрос.md"
        свидетельство = "Журнал/2026-09-10_00-00-00_MSK/материалы/контур-слияния.json"
        команда = [sys.executable, "-B", str(сам.источник / "Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py"),
                   "--repo-root", str(сам.кандидат), "--request", запрос,
                   "--commit-message-file", str(сам.источник.parent / "коммит.txt"), "--codex-thread-id", "00000000-0000-4000-8000-000000000001",
                   "--источник-проверок", сам.вершина, "--ведущая-основа", сам.ведущая, "--свидетельство-контура", свидетельство]
        параметры = сам.модуль.параметры_полного_запуска(сам.источник, сам.кандидат, команда, запрос)
        сам.assertEqual(параметры, (сам.вершина, сам.ведущая, свидетельство))
        for дополнение in (["--list"], ["--skip-session-coherence"], ["--профиль", "полный"],
                            ["--repo-root", str(сам.источник)], ["--policy", "иная.json"]):
            with сам.subTest(дополнение=дополнение), сам.assertRaises(ValueError):
                сам.модуль.параметры_полного_запуска(сам.источник, сам.кандидат, команда + дополнение, запрос)
        for старое, новое in ((str(сам.кандидат), str(сам.источник)), (запрос, "Журнал/2026-09-11_00-00-00_MSK/запрос.md"),
                              (свидетельство, "../вне-кандидата.json"), (сам.вершина, "HEAD")):
            подмена = [новое if аргумент == старое else аргумент for аргумент in команда]
            with сам.subTest(старое=старое), сам.assertRaises(ValueError):
                сам.модуль.параметры_полного_запуска(сам.источник, сам.кандидат, подмена, запрос)

    def test_свидетельство_заранее_индексировано_и_связано_с_uuid(сам):
        запрос = "Журнал/2026-09-10_00-00-00_MSK/запрос.md"
        uuid = "00000000-0000-4000-8000-000000000001"
        относительный = str(Path(запрос).parent / "материалы/контур-слияния.json")
        путь = сам.кандидат / относительный
        путь.parent.mkdir(parents=True)
        свидетельство = сам.проверить() | {"запрос": запрос, "идентификатор_запуска": uuid}
        путь.write_bytes(сам.модуль.канонические_байты(свидетельство))
        with сам.assertRaises(ValueError):
            сам.модуль.проверить_свидетельство(сам.кандидат, относительный, свидетельство)
        сам.гит(сам.кандидат, "add", относительный)
        сам.модуль.проверить_свидетельство(сам.кандидат, относительный, свидетельство)
        blob = сам.гит(сам.кандидат, "rev-parse", ":" + относительный)
        сам.гит(сам.кандидат, "update-index", "--cacheinfo", "120000," + blob + "," + относительный)
        with сам.assertRaises(ValueError):
            сам.модуль.проверить_свидетельство(сам.кандидат, относительный, свидетельство)
        сам.гит(сам.кандидат, "update-index", "--cacheinfo", "100644," + blob + "," + относительный)
        with сам.assertRaises(ValueError):
            сам.модуль.проверить_свидетельство(сам.кандидат, относительный, свидетельство | {"идентификатор_запуска": "другой"})
        путь.write_bytes(путь.read_bytes() + b" ")
        with сам.assertRaises(ValueError):
            сам.модуль.проверить_свидетельство(сам.кандидат, относительный, свидетельство)

    def test_полный_v3_запуск_использует_источник_master_на_кандидате(сам):
        сам.полный_запуск(контур=True)

    def test_высокий_читатель_отклоняет_подмену_модулей_при_согласованном_закрытом_отчёте(сам):
        сам.полный_запуск(контур=True, подмена_зависимостей=True)

    def test_обёртка_исполняет_сырые_байты_общего_модуля_при_старом_кэше(сам):
        сам.полный_запуск(контур=True, старый_кэш_модуля=True)

    def test_обычный_полный_запуск_не_подтверждает_происхождение_из_master(сам):
        сам.полный_запуск(контур=False)

    def test_отказ_после_проверки_не_выдаёт_подтверждение_контура(сам):
        сам.полный_запуск(контур=True, сбой_после=True)

    def полный_запуск(сам, *, контур, сбой_после=False, подмена_зависимостей=False, старый_кэш_модуля=False):
        # Фикстуры проверок остаются в M; настоящий smoke и обёртка собирают v3.
        import test_run_smoke_check as фикстуры
        сам.гит(сам.кандидат, "merge", "--abort")
        помощник = фикстуры.RunSmokeCheckTests()
        помощник.write_script_fixture(сам.источник)
        помощник.создать_фикстуры_документационных_тестов(сам.источник)
        (сам.источник / "Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/proveritj-nazvaniya-avtomatizacij.py").unlink()
        код = Path(__file__).resolve().parents[3]
        if os.environ.get("FUM_CHECKED_CODE_ROOT"):
            код = Path(os.environ["FUM_CHECKED_CODE_ROOT"])
        обёртка = "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py"
        читатель = str(Path(обёртка).with_name("закрытый_отчёт_из_гита.py"))
        for относительный in (сам.модуль.СКРИПТ_SMOKE, сам.модуль.СКРИПТ_SMOKE.with_name("контур_слияния.py"), Path(обёртка),
                              Path(читатель), Path(обёртка).with_name("связь_отпечатка_с_коммитом.py"),
                              Path(обёртка).with_name("граница_зависимостей_слияния.py")):
            путь = сам.источник / относительный
            путь.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(код / относительный, путь)
        тест = "Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests/test_фикстура.py"
        (сам.источник / тест).write_text("import os, unittest\nfrom pathlib import Path\nclass Тест(unittest.TestCase):\n def test_из_источника(сам):\n  сам.assertEqual((Path(os.environ['FUM_CHECKED_CODE_ROOT'])/'результат.txt').read_text(), 'Предлагаемый результат.' + chr(10))\n")
        if сбой_после:
            with (сам.источник / тест).open("a") as файл:
                файл.write("  (Path(os.environ['FUM_CHECKED_CODE_ROOT']).parent/'master'/'AGENTS.md').write_text('Изменено во время запуска.' + chr(10))\n")
        сам.гит(сам.источник, "add", "Инструменты", ".codex")
        сам.гит(сам.источник, "commit", "-qm", "Проверяющий контур целиком")
        сам.вершина = сам.гит(сам.источник, "rev-parse", "HEAD")
        исходник = сам.источник / тест
        исходные_байты = исходник.read_bytes()
        время = исходник.stat()
        подмена = b'raise RuntimeError("Loaded obsolete bytecode")\n'
        исходник.write_bytes(подмена + b"#" * (len(исходные_байты) - len(подмена)))
        os.utime(исходник, ns=(время.st_atime_ns, время.st_mtime_ns))
        py_compile.compile(str(исходник), cfile=str(исходник.parent / "__pycache__" / ("test_фикстура." + sys.implementation.cache_tag + ".pyc")), doraise=True)
        исходник.write_bytes(исходные_байты)
        os.utime(исходник, ns=(время.st_atime_ns, время.st_mtime_ns))
        сам.гит(сам.кандидат, "merge", "--no-ff", "--no-commit", сам.вершина)
        if контур:
            (сам.кандидат / тест).write_text('raise RuntimeError("Тесты кандидата не являются источником")\n')
            (сам.кандидат / "unittest.py").write_text('raise RuntimeError("Подмена стандартного раннера")\n')
            (сам.кандидат / Path(обёртка).with_name("граница_зависимостей_слияния.py")).write_text(
                'raise RuntimeError("Кандидат не задаёт собственный допуск зависимостей")\n')
        else:
            (сам.кандидат / тест).write_text('import unittest\nclass Тест(unittest.TestCase):\n def test_кандидата(сам): pass\n')
        запрос = "Журнал/2026-09-10_00-00-00_MSK/запрос.md"
        каталог = сам.кандидат / Path(запрос).parent
        каталог.mkdir(parents=True)
        (сам.кандидат / запрос).write_text("# Исходный запрос\n\nПроверить слияние.\n")
        (каталог / "отчёт.md").write_text("# Отчёт\n\n### Прямые запуски проверок\n\n<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->\nПроверок пока нет.\n<!-- FUM-CHECK-RUNS:END -->\n")
        uuid = "00000000-0000-4000-8000-000000000099"
        относительный = str(Path(запрос).parent / "материалы/контур-слияния.json")
        путь = сам.кандидат / относительный
        путь.parent.mkdir(parents=True)
        ожидаемое = сам.модуль.канонические_байты(сам.проверить() | {"запрос": запрос, "идентификатор_запуска": uuid})
        подготовка = subprocess.run([sys.executable, "-B", str(сам.источник / сам.модуль.СКРИПТ_SMOKE.with_name("контур_слияния.py")),
                                    "--корень-кандидата", str(сам.кандидат), "--источник", сам.вершина,
                                    "--ведущая-основа", сам.ведущая, "--запрос", запрос, "--идентификатор-запуска", uuid], capture_output=True)
        сам.assertEqual(подготовка.returncode, 0, подготовка.stderr)
        сам.assertEqual(подготовка.stdout, ожидаемое)
        путь.write_bytes(подготовка.stdout)
        сам.гит(сам.кандидат, "add", ".")
        сообщение = сам.источник.parent / "коммит.txt"
        сообщение.write_text("Проверить слияние.\n")
        команда = [sys.executable, "-B", str(сам.источник / сам.модуль.СКРИПТ_SMOKE), "--repo-root", str(сам.кандидат),
                   "--request", запрос, "--commit-message-file", str(сообщение), "--codex-thread-id", uuid,
                   "--источник-проверок", сам.вершина, "--ведущая-основа", сам.ведущая, "--свидетельство-контура", относительный]
        среда = os.environ.copy()
        источник_запуска = сам.источник
        if контур:
            среда.update(PYTHONPATH=str(сам.кандидат), GIT_DIR=str(сам.источник.parent / "несуществующий-git"))
        else:
            источник_запуска = сам.кандидат
            команда = команда[:-6]
            команда[2] = str(сам.кандидат / сам.модуль.СКРИПТ_SMOKE)
        вызов = [sys.executable, "-E", "-B", str(источник_запуска / обёртка), "запустить", "--корень-репозитория", str(сам.кандидат),
                               "--запрос", запрос, "--исполнитель", "Проверяющая фикстура", "--класс-проверки", "полная", "--название", "Проверить слияние",
                               "--идентификатор-запуска", uuid, "--", *команда]
        метка = "fum.контур-проверки-слияния.1:sha256:" + hashlib.sha256(ожидаемое).hexdigest()
        поддельный = вызов.copy()
        позиция = поддельный.index("--")
        поддельный[позиция:позиция] = ["--ожидаемое-свидетельство", метка]
        отказ = subprocess.run(поддельный, capture_output=True, text=True, env=среда)
        сам.assertEqual(отказ.returncode, 1, отказ.stdout + отказ.stderr)
        сам.assertFalse(list((каталог / "материалы/запуски-проверок").glob("*.json")))
        след_кэша = сам.источник.parent / "исполнен-старый-кэш"
        if старый_кэш_модуля:
            модуль = сам.источник / Path(обёртка).with_name("граница_зависимостей_слияния.py")
            время_модуля = модуль.stat()
            поддельный_исходник = сам.источник.parent / "поддельный-модуль.py"
            полезная_нагрузка = (
                "from pathlib import Path\n"
                f"Path({str(след_кэша)!r}).write_text('Исполнен старый кэш')\n"
                f"exec(compile(Path({str(модуль)!r}).read_bytes(), {str(модуль)!r}, 'exec'))\n"
            ).encode()
            сам.assertLess(len(полезная_нагрузка), время_модуля.st_size)
            поддельный_исходник.write_bytes(полезная_нагрузка + b"#" * (время_модуля.st_size - len(полезная_нагрузка)))
            os.utime(поддельный_исходник, ns=(время_модуля.st_atime_ns, время_модуля.st_mtime_ns))
            py_compile.compile(str(поддельный_исходник), cfile=importlib.util.cache_from_source(str(модуль)),
                               dfile=str(модуль), doraise=True, invalidation_mode=py_compile.PycInvalidationMode.TIMESTAMP)
        итог = subprocess.run(вызов, capture_output=True, text=True, env=среда)
        запись = json.loads(next((каталог / "материалы/запуски-проверок").glob("1_*.json")).read_bytes())
        if сбой_после:
            сам.assertNotEqual(итог.returncode, 0, итог.stdout + итог.stderr)
            сам.assertNotEqual(запись["статус"], "успешно")
            сам.assertIsNone(запись["профиль_проверки"]["ожидаемое_свидетельство"])
            return
        сам.assertEqual(итог.returncode, 0, итог.stdout + итог.stderr)
        сам.assertFalse(след_кэша.exists(), "Обёртка исполнила старый кэш вместо сырых байтов модуля M")
        сам.assertEqual(запись["схема"], "fum.test-run.v3")
        сам.assertEqual(запись["статус"], "успешно")
        сам.assertEqual(запись["профиль_проверки"]["ожидаемое_свидетельство"], метка if контур else None)
        сам.assertEqual(len(запись["план"]), 13)
        сам.assertEqual(len(запись["наблюдения"]), 13)
        закрытие = subprocess.run([sys.executable, "-B", str(сам.источник / обёртка), "закрыть",
                                   "--корень-репозитория", str(сам.кандидат), "--запрос", запрос], capture_output=True, text=True)
        сам.assertEqual(закрытие.returncode, 0, закрытие.stdout + закрытие.stderr)
        сам.гит(сам.кандидат, "add", ".")
        сам.гит(сам.кандидат, "commit", "-qm", "Зафиксировать проверенное слияние")
        коммит = сам.гит(сам.кандидат, "rev-parse", "HEAD")
        дерево = сам.гит(сам.кандидат, "rev-parse", "HEAD^{tree}")
        команда_приёмки = [sys.executable, "-B", str(сам.источник / читатель), "--корень-репозитория", str(сам.кандидат),
                           "--коммит", коммит, "--запрос", запрос, "--допуск-слияния", "--база", сам.ведущая,
                           "--присоединяемый", сам.вершина, "--дерево", дерево]
        итог = subprocess.run(команда_приёмки, capture_output=True, text=True)
        if not контур:
            сам.assertEqual(итог.returncode, 1, итог.stdout + итог.stderr)
            низкая_команда = ["--слияние" if часть == "--допуск-слияния" else часть for часть in команда_приёмки]
            низкий = subprocess.run(низкая_команда, capture_output=True, text=True)
            сам.assertEqual(низкий.returncode, 0, низкий.stdout + низкий.stderr)
            return
        сам.assertEqual(итог.returncode, 0, итог.stdout + итог.stderr)
        допуск = json.loads(итог.stdout)
        сам.assertEqual(допуск["происхождение_проверок"]["идентификатор_запуска"], uuid)
        сам.assertEqual(допуск["связь"]["родители"], [сам.ведущая, сам.вершина])
        сам.assertFalse(допуск["завершение_обязательства_доказано"])
        if подмена_зависимостей:
            # Заведомо враждебный, но внутренне согласованный архив. Низкий
            # читатель должен принять его структуру, высокий — отвергнуть
            # семантическую подмену .gitmodules независимо от этой структуры.
            сам.гит(сам.кандидат, "reset", "--hard", сам.ведущая)
            сам.гит(сам.кандидат, "merge", "--no-ff", "--no-commit", сам.вершина)
            сам.гит(сам.кандидат, "read-tree", "--reset", "-u", коммит)
            модули = сам.кандидат / ".gitmodules"
            модули.write_bytes(модули.read_bytes() + b"\tbranch = unapproved\n")
            сам.гит(сам.кандидат, "add", ".gitmodules")
            спецификация_подмены = importlib.util.spec_from_file_location("обёртка_подмены_фикстуры", сам.источник / обёртка)
            отчёты = importlib.util.module_from_spec(спецификация_подмены)
            спецификация_подмены.loader.exec_module(отчёты)
            отпечаток = отчёты.вычислить_отпечаток_снимка(сам.кандидат, Path(запрос).parent)
            журнал = каталог / "материалы/запуски-проверок"
            записи = []
            for файл in sorted(журнал.glob("*_*.json")):
                значение = json.loads(файл.read_bytes())
                значение["профиль_проверки"]["отпечаток_снимка"] = отпечаток
                сырые_байты = отчёты.канонические_машинные_байты(значение)
                файл.write_bytes(сырые_байты)
                записи.append((файл, значение, сырые_байты))
            снимок = отчёты.канонические_машинные_байты(отчёты.ожидаемый_снимок(записи, запрос, отпечаток))
            (журнал / "снимок.json").write_bytes(снимок)
            отчёт = каталог / "отчёт.md"
            текст = отчёт.read_text()
            начало, конец, _ = отчёты.границы_управляемого_блока(текст)
            блок = отчёты.сформировать_блок(записи, отчёты.сформировать_закрытый_маркер(снимок), отпечаток)
            отчёт.write_text(текст[:начало] + блок + текст[конец:])
            сам.гит(сам.кандидат, "add", ".")
            сам.гит(сам.кандидат, "commit", "-qm", "Подменить архив для отрицательной проверки")
            плохой = сам.гит(сам.кандидат, "rev-parse", "HEAD")
            плохое_дерево = сам.гит(сам.кандидат, "rev-parse", "HEAD^{tree}")
            команда = [плохой if часть == коммит else плохое_дерево if часть == дерево else часть
                       for часть in команда_приёмки]
            низкий = subprocess.run(["--слияние" if часть == "--допуск-слияния" else часть for часть in команда],
                                    capture_output=True, text=True)
            сам.assertEqual(низкий.returncode, 0, низкий.stdout + низкий.stderr)
            высокий = subprocess.run(команда, capture_output=True, text=True)
            сам.assertEqual(высокий.returncode, 1, высокий.stdout + высокий.stderr)
            сам.assertIn(".gitmodules", высокий.stderr)
            return
        исходный_sidecar = путь.read_bytes()
        варианты = [None, исходный_sidecar + b" ", сам.модуль.канонические_байты(json.loads(исходный_sidecar) | {"идентификатор_запуска": "00000000-0000-4000-8000-000000000100"}),
                    сам.модуль.канонические_байты(json.loads(исходный_sidecar) | {"источник": сам.ведущая}),
                    сам.модуль.канонические_байты(json.loads(исходный_sidecar) | {"лишнее": True})]
        for номер, содержимое in enumerate(варианты):
            if содержимое is None:
                путь.unlink()
            else:
                путь.write_bytes(содержимое)
            сам.гит(сам.кандидат, "add", относительный)
            новое_дерево = сам.гит(сам.кандидат, "write-tree")
            новый_коммит = сам.гит(сам.кандидат, "commit-tree", новое_дерево, "-p", сам.ведущая, "-p", сам.вершина, "-m", "Подмена свидетельства")
            команда_подмены = [новый_коммит if часть == коммит else новое_дерево if часть == дерево else часть for часть in команда_приёмки]
            итог = subprocess.run(команда_подмены, capture_output=True, text=True)
            with сам.subTest(номер=номер):
                сам.assertEqual(итог.returncode, 1, итог.stdout + итог.stderr)
            путь.write_bytes(исходный_sidecar)
