from __future__ import annotations

import json
import importlib.util
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import uuid
from pathlib import Path
from unittest import mock

from test_отчёты_о_запусках_проверок import ФикстураОтчётов, имя_сессии


def путь_проверяемой_реализации(путь: Path) -> Path:
    выбранный = os.environ.get("FUM_CHECKED_CODE_ROOT")
    if выбранный is None:
        return путь
    if not выбранный or not Path(выбранный).is_absolute():
        raise ValueError("корень проверяемой реализации должен быть явным абсолютным путём")
    return Path(выбранный) / путь.relative_to(Path(__file__).resolve().parents[3])


сценарий = путь_проверяемой_реализации(Path(__file__).resolve().parents[1] / "scripts/связь_отпечатка_с_коммитом.py")


class ТестыОграниченнойСредыЧтенияGit(unittest.TestCase):
    def setUp(сам):
        каталог = str(сценарий.parent)
        sys.path.insert(0, каталог)
        try:
            спецификация = importlib.util.spec_from_file_location('тестовая_связь_с_коммитом', сценарий)
            сам.assertIsNotNone(спецификация)
            сам.модуль = importlib.util.module_from_spec(спецификация)
            спецификация.loader.exec_module(сам.модуль)
        finally:
            sys.path.remove(каталог)

    def test_явная_среда_и_stdin_без_чтения_окружения(сам):
        м = сам.модуль
        ожидаемая = {
            'PATH': os.defpath, 'GIT_OPTIONAL_LOCKS': '0', 'GIT_NO_REPLACE_OBJECTS': '1',
            'GIT_NO_LAZY_FETCH': '1', 'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull,
            'GIT_ATTR_NOSYSTEM': '1', 'LC_ALL': 'C',
        }
        for вход in (None, 'тест'.encode('utf-8')):
            with сам.subTest(вход=вход), mock.patch.object(м.os, 'environ', object()), \
                 mock.patch.object(м.subprocess, 'run',
                                   return_value=subprocess.CompletedProcess([], 0, b'answer', b'')) as запуск:
                итог = м.выполнить_чтение_репозитория(Path('/private/tmp'), 'hash-object', '--stdin', вход=вход)
                сам.assertEqual(итог, b'answer')
                сам.assertEqual(запуск.call_args.args[0][:3], ['git', '-C', '/private/tmp'])
                сам.assertEqual(запуск.call_args.kwargs['env'], ожидаемая)
                if вход is None:
                    сам.assertEqual(запуск.call_args.kwargs['stdin'], subprocess.DEVNULL)
                    сам.assertNotIn('input', запуск.call_args.kwargs)
                else:
                    сам.assertEqual(запуск.call_args.kwargs['input'], вход)
                    сам.assertNotIn('stdin', запуск.call_args.kwargs)

    def test_реальный_git_читает_blob_в_изолированной_среде(сам):
        м = сам.модуль
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            корень = Path(каталог)
            subprocess.run(['/usr/bin/git', '-C', str(корень), 'init', '-q'],
                           env=м.ограниченная_среда_чтения_гит(), stdin=subprocess.DEVNULL,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, timeout=5)
            данные = b'fixture-data'
            ожидаемый = hashlib.sha1(b'blob ' + str(len(данные)).encode('ascii') + b'\0' + данные).hexdigest()
            факт = м.выполнить_чтение_репозитория(корень, 'hash-object', '--stdin', вход=данные)
            сам.assertEqual(факт.strip().decode('ascii'), ожидаемый)
            настоящий_запуск = subprocess.run
            def с_ограничением(*args, **kwargs):
                return настоящий_запуск(*args, **kwargs, timeout=5)
            with mock.patch.object(м.subprocess, 'run', side_effect=с_ограничением):
                пустой = м.выполнить_чтение_репозитория(корень, 'hash-object', '--stdin')
            сам.assertEqual(пустой.strip().decode('ascii'), hashlib.sha1(b'blob 0\0').hexdigest())

    def test_ненулевой_код_git_остаётся_ошибкой(сам):
        м = сам.модуль
        отказ = subprocess.CompletedProcess([], 7, b'', b'fixture-error')
        with mock.patch.object(м.subprocess, 'run', return_value=отказ):
            with сам.assertRaisesRegex(м.ОшибкаОтчёта, 'fixture-error'):
                м.выполнить_чтение_репозитория(Path('/private/tmp'), 'rev-parse', 'HEAD')

    def test_изолированная_среда_не_воспроизводит_чужие_глобальные_настройки_diff(сам):
        м = сам.модуль
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            корень = Path(каталог) / 'репозиторий'
            корень.mkdir()
            глобальная = Path(каталог) / 'глобальные-настройки'
            глобальная.write_text('[diff]\n\tcontext = 0\n\tmnemonicPrefix = true\n', encoding='utf-8')
            среда = м.ограниченная_среда_чтения_гит()
            основа = ['/usr/bin/git', '-C', str(корень)]
            subprocess.run([*основа, 'init', '-q'], env=среда, stdin=subprocess.DEVNULL,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, timeout=5)
            файл = корень / 'data.txt'
            файл.write_text('один\nдва\nтри\nчетыре\nпять\nшесть\nсемь\nвосемь\n', encoding='utf-8')
            subprocess.run([*основа, 'add', '--', 'data.txt'], env=среда, stdin=subprocess.DEVNULL,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, timeout=5)
            файл.write_text('один\nдва\nтри\nзамена\nпять\nшесть\nсемь\nвосемь\n', encoding='utf-8')
            аргументы = ['diff', '--binary', '--no-ext-diff', '--no-textconv', '--ignore-submodules=none',
                         '--', 'data.txt']
            пользовательская = {**среда, 'GIT_CONFIG_GLOBAL': str(глобальная)}
            прежний = subprocess.run([*основа, '-c', 'core.fsmonitor=false', *аргументы],
                                     env=пользовательская, stdin=subprocess.DEVNULL,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                     check=True, timeout=5).stdout
            текущий = м.выполнить_чтение_репозитория(корень, *аргументы)
            сам.assertNotEqual(прежний, текущий)
            сам.assertIn(b'diff --git i/data.txt w/data.txt', прежний)
            сам.assertIn(b'diff --git a/data.txt b/data.txt', текущий)
            def git(*аргументы, env=среда):
                return subprocess.run([*основа, *аргументы], env=env, stdin=subprocess.DEVNULL,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      check=True, timeout=5).stdout
            автор = ['-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid']
            git(*автор, 'commit', '-qm', 'База фикстуры')
            родитель = git('rev-parse', 'HEAD').strip().decode('ascii')
            git('add', '--', 'data.txt')
            сессия = 'Журнал/фикстура'
            пути = м.пути_границы(сессия)
            старые_байты = git('-c', 'core.fsmonitor=false', 'diff', *м.ФЛАГИ_РАЗНИЦЫ,
                               '--cached', родитель, '--', *пути, env=пользовательская)
            git(*автор, 'commit', '-qm', 'Изменение фикстуры')
            коммит = git('rev-parse', 'HEAD').strip().decode('ascii')
            разница = ['diff', *м.ФЛАГИ_РАЗНИЦЫ, родитель, коммит, '--', *пути]
            новые_байты = м.выполнить_чтение_репозитория(корень, *разница)
            сам.assertNotEqual(старые_байты, новые_байты)
            def отпечаток(байты):
                хэш = hashlib.sha256()
                м.добавить_часть_отпечатка(хэш, 'вершина', родитель.encode('ascii'))
                м.добавить_часть_отпечатка(хэш, 'индекс', байты)
                м.добавить_часть_отпечатка(хэш, 'рабочее_дерево', b'')
                return 'sha256:' + хэш.hexdigest()
            старый_отпечаток = отпечаток(старые_байты)
            новый_отпечаток = отпечаток(новые_байты)
            старый_итог = м.связать_отпечаток_с_коммитом(
                корень, сессия, коммит, старый_отпечаток, старый_отпечаток)
            новый_итог = м.связать_отпечаток_с_коммитом(
                корень, сессия, коммит, новый_отпечаток, новый_отпечаток)
            сам.assertEqual(старый_итог['состояние'], 'не восстановлен')
            сам.assertEqual(новый_итог['состояние'], 'подтверждён')


class ТестыСвязиОтпечаткаСКоммитом(unittest.TestCase):
    def setUp(сам):
        среда = mock.patch.dict(os.environ, {"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull})
        среда.start()
        сам.addCleanup(среда.stop)
        сам.фикстура = ФикстураОтчётов()
        сам.addCleanup(сам.фикстура.очистить)
        сам.корень = сам.фикстура.корень
        сам.сессия = f"Журнал/{имя_сессии}"
        сам.родитель = сам.гит("rev-parse", "HEAD").decode().strip()
        (сам.корень / "данные.bin").write_bytes(bytes(range(256)))
        (сам.корень / "текст.txt").write_text("Проверяемый результат.\n")
        сам.гит("add", ".")

    def гит(сам, *аргументы):
        return subprocess.run(["git", "-C", str(сам.корень), *аргументы],
                              check=True, capture_output=True).stdout

    def сохранить_отпечаток(сам):
        идентификатор = str(uuid.uuid4())
        итог = сам.фикстура.запустить(идентификатор, sys.executable, "-c", "pass")
        сам.assertEqual(итог.returncode, 0, итог.stderr)
        return сам.фикстура.запись(идентификатор)["профиль_проверки"]["отпечаток_снимка"]

    def коммит(сам):
        сам.гит("add", ".")
        сам.гит("commit", "-qm", "Сохранить результат")
        return сам.гит("rev-parse", "HEAD").decode().strip()

    def вызвать(сам, коммит, отпечаток, режим="исторический", второй=None, сессия=None, среда=None, корень=None):
        return subprocess.run([
            sys.executable, "-B", str(сценарий), "--корень-репозитория", str(корень or сам.корень),
            "--сессия", сессия or сам.сессия, "--коммит", коммит,
            "--отпечаток-закрытия", отпечаток, "--отпечаток-запуска", второй or отпечаток,
            "--режим", режим,
        ], capture_output=True, text=True, env=среда)

    def test_буквальные_байты_обёртки_восстанавливаются_без_записи(сам):
        (сам.корень / "текст.txt").chmod(0o755)
        сам.гит("add", ".")
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        до = {путь.relative_to(сам.корень): путь.read_bytes()
              for путь in сам.корень.rglob("*") if путь.is_file()}
        for режим in ("исторический", "после-коммита"):
            with сам.subTest(режим=режим):
                итог = сам.вызвать(коммит, отпечаток, режим)
                сам.assertEqual(итог.returncode, 0, итог.stderr)
                данные = json.loads(итог.stdout)
                сам.assertEqual(данные["кандидат"], отпечаток)
                сам.assertEqual(данные["родитель"], сам.родитель)
                сам.assertEqual(данные["состояние"], "подтверждён")
        после = {путь.relative_to(сам.корень): путь.read_bytes()
                 for путь in сам.корень.rglob("*") if путь.is_file()}
        сам.assertEqual(до, после)

    def test_исторический_коммит_не_зависит_от_текущего_индекса(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        (сам.корень / "текст.txt").write_text("Следующий этап.\n")
        сам.коммит()
        сам.assertEqual(сам.вызвать(коммит, отпечаток).returncode, 0)
        сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 1)

    def test_мнёмонические_префиксы_не_подменяются(сам):
        сам.гит("config", "diff.mnemonicPrefix", "true")
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 0)
        итог = сам.вызвать(коммит, отпечаток)
        сам.assertEqual(итог.returncode, 2, итог.stderr)
        сам.assertEqual(json.loads(итог.stdout)["состояние"], "не восстановлен")

    def test_неполная_исходная_индексация_не_выдаётся_за_совпадение(сам):
        (сам.корень / "текст.txt").write_text("Неиндексированная правка.\n")
        (сам.корень / "новый.txt").write_text("Неотслеживаемый вход.\n")
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 2)

    def test_несовпадение_двух_свидетельств_не_подтверждается(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        итог = сам.вызвать(коммит, отпечаток, второй="sha256:" + "0" * 64)
        сам.assertEqual(итог.returncode, 2, итог.stderr)

    def test_после_коммита_проверяется_индекс_хвост_и_флаги(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        for тип in ("рабочее дерево", "индекс", "неотслеживаемый", "assume", "skip"):
            with сам.subTest(тип=тип):
                путь = сам.корень / ("новый.txt" if тип == "неотслеживаемый" else "текст.txt")
                if тип in ("assume", "skip"):
                    сам.гит("update-index", "--assume-unchanged" if тип == "assume" else "--skip-worktree", "текст.txt")
                путь.write_text("Поздняя правка.\n")
                if тип == "индекс":
                    сам.гит("add", "текст.txt")
                итог = сам.вызвать(коммит, отпечаток, "после-коммита")
                сам.assertEqual(итог.returncode, 1, итог.stderr)
                if тип == "неотслеживаемый":
                    путь.unlink()
                else:
                    сам.гит("update-index", "--no-assume-unchanged", "текст.txt")
                    сам.гит("update-index", "--no-skip-worktree", "текст.txt")
                    сам.гит("restore", "--source=HEAD", "--staged", "--worktree", "текст.txt")

    def test_исключения_не_распространяются_на_похожие_пути(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        сам.фикстура.отчёт.write_text("Замыкание отчёта.\n")
        проекция = сам.корень / "Proyekcii/новый.bin"
        проекция.parent.mkdir()
        проекция.write_bytes(b"projection")
        сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 0)
        for имя in ("Proyekcii-copy/новый.bin", "Документация/Proyekcii/новый.bin", str(Path(сам.сессия) / "запрос.md")):
            with сам.subTest(имя=имя):
                путь = сам.корень / имя
                путь.parent.mkdir(parents=True, exist_ok=True)
                прежнее = путь.read_bytes() if путь.exists() else None
                путь.write_bytes(b"changed")
                сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 1)
                if прежнее is None:
                    путь.unlink()
                else:
                    путь.write_bytes(прежнее)

    def test_начальный_несуществующий_и_сокращённый_коммиты_отклоняются(сам):
        отпечаток = сам.сохранить_отпечаток()
        for коммит in (сам.родитель, "0" * 40, "HEAD", сам.родитель[:8]):
            with сам.subTest(коммит=коммит):
                сам.assertEqual(сам.вызвать(коммит, отпечаток).returncode, 1)

    def test_слияние_не_имеет_однозначного_предкоммитного_родителя(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        дерево = сам.гит("rev-parse", коммит + "^{tree}").decode().strip()
        слияние = сам.гит("commit-tree", дерево, "-p", коммит, "-p", сам.родитель, "-m", "Слияние").decode().strip()
        сам.assertEqual(сам.вызвать(слияние, отпечаток).returncode, 1)

    def test_объект_аннотированного_тега_не_является_коммитом(сам):
        отпечаток = сам.сохранить_отпечаток()
        сам.коммит()
        сам.гит("tag", "-a", "приёмка", "-m", "Указатель на результат")
        тег = сам.гит("rev-parse", "refs/tags/приёмка").decode().strip()
        сам.assertEqual(сам.вызвать(тег, отпечаток).returncode, 1)

    def test_среда_не_расширяет_исключение_на_нижний_регистр(сам):
        отпечаток = сам.сохранить_отпечаток()
        путь = сам.корень / "proyekcii/extra"
        путь.parent.mkdir()
        путь.write_bytes(b"unchecked")
        коммит = сам.коммит()
        итог = сам.вызвать(коммит, отпечаток, среда={**os.environ, "GIT_ICASE_PATHSPECS": "1"})
        сам.assertEqual(итог.returncode, 2, итог.stderr)

    def test_настроенный_исполняемый_фильтр_не_запускается(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        сам.гит("config", "filter.пример.clean", "cat")
        сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 1)

    def test_непосредственный_режим_не_обходит_подмодули(сам):
        (сам.корень / "вложенный").mkdir()
        сам.гит("update-index", "--add", "--cacheinfo", "160000," + сам.родитель + ",вложенный")
        отпечаток = сам.сохранить_отпечаток()
        сам.гит("commit", "-qm", "Сохранить gitlink")
        коммит = сам.гит("rev-parse", "HEAD").decode().strip()
        сам.assertEqual(сам.вызвать(коммит, отпечаток).returncode, 0)
        сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 1)

    def test_полный_идентификатор_из_шестидесяти_четырёх_символов(сам):
        shutil.rmtree(сам.корень / ".git")
        сам.гит("init", "-q", "--object-format=sha256")
        сам.гит("config", "user.name", "FUM Tests")
        сам.гит("config", "user.email", "fum-tests@example.invalid")
        сам.коммит()
        (сам.корень / "текст.txt").write_text("Следующий результат.\n")
        сам.гит("add", ".")
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        сам.assertEqual(len(коммит), 64)
        сам.assertEqual(сам.вызвать(коммит, отпечаток).returncode, 0)
        сам.assertEqual(сам.вызвать(коммит[:40], отпечаток).returncode, 1)

    def test_подкаталог_не_сужает_проверяемую_границу(сам):
        сам.коммит()
        вложенный = сам.корень / "подкаталог"
        вложенный.mkdir()
        (вложенный / "файл.txt").write_text("Проверенный вход.\n")
        сам.гит("add", ".")
        отпечаток = сам.сохранить_отпечаток()
        (сам.корень / "поздний.txt").write_text("Непроверенный вход.\n")
        коммит = сам.коммит()
        сам.assertEqual(сам.вызвать(коммит, отпечаток, корень=вложенный).returncode, 1)

    def test_неразрешённые_стадии_индекса_отклоняются(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        объект = сам.гит("rev-parse", "HEAD:текст.txt").decode().strip()
        вход = "0 " + "0" * 40 + "\tтекст.txt\n" + "".join(f"100644 {объект} {стадия}\tтекст.txt\n" for стадия in (1, 2, 3))
        subprocess.run(["git", "-C", str(сам.корень), "update-index", "--index-info"], input=вход.encode(), check=True, capture_output=True)
        до = (сам.корень / ".git/index").read_bytes()
        сам.assertEqual(сам.вызвать(коммит, отпечаток, "после-коммита").returncode, 1)
        сам.assertEqual((сам.корень / ".git/index").read_bytes(), до)

    def test_изменение_вершины_между_чтениями_не_подтверждается(сам):
        отпечаток = сам.сохранить_отпечаток()
        коммит = сам.коммит()
        with mock.patch.object(sys, "path", [str(сценарий.parent), *sys.path]):
            спецификация = importlib.util.spec_from_file_location("адаптер_гонки", сценарий)
            модуль = importlib.util.module_from_spec(спецификация)
            спецификация.loader.exec_module(модуль)
        исходное_чтение = модуль.выполнить_чтение_репозитория
        def читать(корень, *аргументы):
            результат = исходное_чтение(корень, *аргументы)
            if аргументы[0] == "diff" and "--cached" in аргументы:
                сам.гит("commit", "--allow-empty", "-qm", "Смена границы")
            return результат
        with mock.patch.object(модуль, "выполнить_чтение_репозитория", читать):
            with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "HEAD"):
                модуль.связать_отпечаток_с_коммитом(сам.корень, сам.сессия, коммит, отпечаток, отпечаток, "после-коммита")

    def test_путь_сессии_и_формат_отпечатка_закрыты(сам):
        коммит = сам.коммит()
        for сессия in (".", "../Журнал", str(сам.корень / "Журнал"), "Журнал//дубль", "Журнал/*", "Proyekcii/запрос"):
            with сам.subTest(сессия=сессия):
                сам.assertEqual(сам.вызвать(коммит, "sha256:" + "0" * 64, сессия=сессия).returncode, 1)
        сам.assertEqual(сам.вызвать(коммит, "v4:anything").returncode, 1)


if __name__ == "__main__":
    unittest.main()
