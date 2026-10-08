import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


путь = Path(__file__).with_name('собрать-tdlib.py')
спецификация = importlib.util.spec_from_file_location('сборка_tdlib', путь)
сборка = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(сборка)


class ПроверкиСборкиTDLib(unittest.TestCase):
    def setUp(self):
        self.профиль = сборка.прочитатьПрофиль()

    def test_профиль_содержит_точный_gitlink_и_двойной_проверочный_проход(self):
        зависимость = self.профиль['зависимость']
        self.assertEqual(зависимость['коммит'], 'd1085f9cebc5a62379991ae1652673954f229c1f')
        self.assertEqual(зависимость['путь'], 'Зависимости/TDLib')
        self.assertEqual(self.профиль['сборка']['повторений'], 2)
        self.assertEqual(self.профиль['сборка']['цель'], 'tdjson')

    def test_gitmodules_принимает_точные_зеркало_upstream_и_путь(self):
        зависимость = self.профиль['зависимость']
        prefix = b'submodule.' + зависимость['путь'].encode() + b'.'
        вывод = b'\0'.join([
            prefix + b'path\n' + зависимость['путь'].encode(),
            prefix + b'url\n' + зависимость['зеркало'].encode(),
            prefix + b'fumupstream\n' + зависимость['upstream'].encode(),
        ]) + b'\0'
        сборка.разобратьGitmodules(вывод, self.профиль)

    def test_gitmodules_отклоняет_несовпадающее_зеркало(self):
        зависимость = self.профиль['зависимость']
        prefix = b'submodule.' + зависимость['путь'].encode() + b'.'
        вывод = b'\0'.join([
            prefix + b'path\n' + зависимость['путь'].encode(),
            prefix + b'url\nhttps://github.com/tdlib/td.git',
            prefix + b'fumupstream\n' + зависимость['upstream'].encode(),
        ]) + b'\0'
        with self.assertRaisesRegex(сборка.ОтказПрофиля, 'url'):
            сборка.разобратьGitmodules(вывод, self.профиль)

    def test_gitmodules_отклоняет_дублирующую_регистрацию_пути(self):
        зависимость = self.профиль['зависимость']
        поля = []
        for имя in ('один', 'два'):
            prefix = f'submodule.{имя}.'.encode()
            поля.extend([
                prefix + b'path\n' + зависимость['путь'].encode(),
                prefix + b'url\n' + зависимость['зеркало'].encode(),
                prefix + b'fumupstream\n' + зависимость['upstream'].encode(),
            ])
        with self.assertRaisesRegex(сборка.ОтказПрофиля, 'единственный путь'):
            сборка.разобратьGitmodules(b'\0'.join(поля) + b'\0', self.профиль)

    def test_gitlink_принимает_только_точный_режим_oid_и_путь(self):
        зависимость = self.профиль['зависимость']
        oid = зависимость['коммит'].encode()
        relative = зависимость['путь'].encode()
        valid = b'160000 commit ' + oid + b'\t' + relative + b'\0'
        сборка.разобратьGitlink(valid, self.профиль)
        for bad in (
            b'100644 blob ' + oid + b'\t' + relative + b'\0',
            b'160000 commit ' + b'0' * 40 + b'\t' + relative + b'\0',
            b'160000 commit ' + oid + b'\t' + 'Зависимости/иная'.encode() + b'\0',
            valid + valid,
            b'',
        ):
            with self.subTest(bad=bad), self.assertRaises(сборка.ОтказПрофиля):
                сборка.разобратьGitlink(bad, self.профиль)

    def test_выход_должен_быть_новым_абсолютным_и_частным_вне_исходников(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            repo = root / 'repo'; repo.mkdir(mode=0o700)
            source = repo / 'Зависимости/TDLib'; source.mkdir(parents=True)
            private = root / 'private'; private.mkdir(mode=0o700)
            target = private / 'build'
            self.assertEqual(сборка.проверитьВыход(repo, source, target), target)
            with self.assertRaises(сборка.ОтказПрофиля):
                сборка.проверитьВыход(repo, source, repo / 'build')
            with self.assertRaises(сборка.ОтказПрофиля):
                сборка.проверитьВыход(repo, source, Path('relative/build'))
            target.mkdir(mode=0o700)
            with self.assertRaisesRegex(сборка.ОтказПрофиля, 'уже существует'):
                сборка.проверитьВыход(repo, source, target)
            alias = root / 'alias'; alias.symlink_to(private, target_is_directory=True)
            with self.assertRaisesRegex(сборка.ОтказПрофиля, 'неоднозначен'):
                сборка.проверитьВыход(repo, source, alias / 'another-build')

    def test_репозиторий_без_зависимости_останавливается_до_сборки(self):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог).resolve() / 'FUM'
            корень.mkdir(mode=0o700)
            self.git(корень, 'init', '-q')
            (корень / '.gitmodules').write_text('', encoding='utf-8')
            with self.assertRaisesRegex(сборка.ОтказПрофиля, 'не зарегистрирован'):
                сборка.проверитьРегистрацию(корень, self.профиль)
            выход = Path(каталог).resolve() / 'build'
            аргументыИнструментов = []
            for имя in сборка.ИМЕНА_ИНСТРУМЕНТОВ:
                инструмент = Path(каталог).resolve() / имя
                инструмент.write_text('открытая исполняемая фикстура, запуск не разрешён\n')
                инструмент.chmod(0o700)
                аргументыИнструментов.extend(['--инструмент', имя + '=' + str(инструмент)])
            результат = subprocess.run(
                [sys.executable, '-B', str(путь.resolve()),
                 '--корень-репозитория', str(корень), '--выход', str(выход),
                 '--openssl-root', каталог, *аргументыИнструментов],
                capture_output=True, text=True, timeout=15,
            )
            self.assertEqual(результат.returncode, 2)
            отказ = json.loads(результат.stderr)
            self.assertEqual(отказ['схема'], 'fum.сборка-tdlib.1')
            self.assertEqual(отказ['исход'], 'отказ')
            self.assertIn('не зарегистрирован', отказ['причина'])
            self.assertFalse(выход.exists())

    def test_отрицательный_сценарий_использует_изолированный_репозиторий(self):
        with patch.object(сборка, 'проверитьРегистрацию',
                          wraps=сборка.проверитьРегистрацию) as проверка, \
                patch.object(subprocess, 'run', wraps=subprocess.run) as процессы:
            сценарий = ПроверкиСборкиTDLib(
                'test_репозиторий_без_зависимости_останавливается_до_сборки')
            сценарий.setUp()
            сценарий.test_репозиторий_без_зависимости_останавливается_до_сборки()
        self.assertEqual(проверка.call_count, 1)
        кореньПроверки = Path(проверка.call_args.args[0]).resolve()
        кореньВызывающейЗадачи = Path(__file__).resolve().parents[5]
        self.assertNotEqual(кореньПроверки, кореньВызывающейЗадачи)
        команды = [вызов.args[0] for вызов in процессы.call_args_list
                   if вызов.args[0][0] == sys.executable
                   and str(путь.resolve()) in вызов.args[0]]
        self.assertEqual(len(команды), 1)
        номерКорня = команды[0].index('--корень-репозитория') + 1
        self.assertEqual(Path(команды[0][номерКорня]).resolve(), кореньПроверки)

    def test_зарегистрированный_чистый_локальный_gitlink_проходит_допуск(self):
        with tempfile.TemporaryDirectory() as temp:
            tempRoot = Path(temp).resolve()
            root = tempRoot / 'FUM'; root.mkdir()
            seed = tempRoot / 'TDLib-seed'; seed.mkdir()
            self.git(seed, 'init', '-q')
            self.git(seed, 'config', 'user.name', 'fixture')
            self.git(seed, 'config', 'user.email', 'fixture@example.invalid')
            (seed / 'CMakeLists.txt').write_text('project(fixture)\n', encoding='utf-8')
            self.git(seed, 'add', 'CMakeLists.txt')
            self.git(seed, 'commit', '-q', '-m', 'fixture')
            oid = self.git(seed, 'rev-parse', 'HEAD').strip()

            self.git(root, 'init', '-q')
            self.git(root, 'config', 'user.name', 'fixture')
            self.git(root, 'config', 'user.email', 'fixture@example.invalid')
            self.git(root, '-c', 'protocol.file.allow=always', 'submodule', 'add',
                     '--name', 'TDLib', str(seed), 'Зависимости/TDLib')
            dependency = root / 'Зависимости/TDLib'
            self.git(dependency, 'remote', 'set-url', 'origin', self.профиль['зависимость']['зеркало'])
            self.git(dependency, 'remote', 'add', 'upstream', self.профиль['зависимость']['upstream'])
            self.git(root, 'config', '-f', '.gitmodules', 'submodule.TDLib.url',
                     self.профиль['зависимость']['зеркало'])
            self.git(root, 'config', '-f', '.gitmodules', 'submodule.TDLib.fumUpstream',
                     self.профиль['зависимость']['upstream'])
            self.git(root, 'add', '.gitmodules')
            self.git(root, 'commit', '-q', '-m', 'fixture')

            profile = json.loads(json.dumps(self.профиль))
            profile['зависимость']['коммит'] = oid
            profile['зависимость']['дерево'] = self.git(dependency, 'rev-parse', 'HEAD^{tree}').strip()
            profile['зависимость']['времяКоммитаUnix'] = int(
                self.git(dependency, 'show', '-s', '--format=%ct', 'HEAD').strip())
            profile['зависимость']['отпечаткиSha256'] = {
                'CMakeLists.txt': сборка.sha256(dependency / 'CMakeLists.txt')
            }
            actual, actualOid = сборка.проверитьРегистрацию(root, profile)
            self.assertEqual(actual, dependency)
            self.assertEqual(actualOid, oid)
            сборка.проверитьОтпечаткиИсточника(actual, profile)
            profile['зависимость']['отпечаткиSha256']['CMakeLists.txt'] = '0' * 64
            with self.assertRaisesRegex(сборка.ОтказПрофиля, 'хэш исходного файла'):
                сборка.проверитьОтпечаткиИсточника(actual, profile)

            home = tempRoot / 'home'; home.mkdir(mode=0o700)
            temporary = tempRoot / 'tmp'; temporary.mkdir(mode=0o700)
            environment = {
                'PATH': os.defpath,
                'HOME': str(home),
                'TMPDIR': str(temporary),
                'GIT_CONFIG_NOSYSTEM': '1',
                'GIT_CONFIG_GLOBAL': os.devnull,
                'GIT_NO_LAZY_FETCH': '1',
                'GIT_NO_REPLACE_OBJECTS': '1',
                'GIT_OPTIONAL_LOCKS': '0',
                'GIT_TERMINAL_PROMPT': '0',
            }
            copied = сборка._клонироватьИсточник(actual, oid, tempRoot / 'source-copy', environment)
            self.assertEqual(self.git(copied, 'rev-parse', 'HEAD').strip(), oid)
            self.assertEqual(self.git(actual, 'status', '--porcelain=v1', '--untracked-files=all'), '')
            sourceGitDir = Path(self.git(actual, 'rev-parse', '--absolute-git-dir').strip())
            copiedGitDir = Path(self.git(copied, 'rev-parse', '--absolute-git-dir').strip())
            sourceInodes = {item.stat().st_ino for item in (sourceGitDir / 'objects').rglob('*') if item.is_file()}
            copiedInodes = {item.stat().st_ino for item in (copiedGitDir / 'objects').rglob('*') if item.is_file()}
            self.assertFalse(sourceInodes & copiedInodes)

    def test_параметры_cmake_закрепляют_архитектуру_и_динамический_tdjson(self):
        profile = self.профиль
        env = {
            'cmake': Path('/opt/homebrew/bin/cmake'),
            'make': Path('/usr/bin/make'),
            'gperf': Path('/usr/bin/gperf'),
            'clang': Path('/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang'),
            'clangxx': Path('/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++'),
            'sdkПуть': Path('/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk'),
            'opensslRoot': Path('/opt/homebrew/opt/openssl@3'),
        }
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / 'source'
            output = Path(temp) / 'run'
            command = сборка._конфигурация(profile, env, source, output)
        self.assertIn('-DCMAKE_OSX_ARCHITECTURES=arm64', command)
        self.assertIn('-DCMAKE_CXX_STANDARD=17', command)
        self.assertIn('-DOPENSSL_ROOT_DIR=/opt/homebrew/opt/openssl@3', command)
        self.assertIn('-DGPERF_EXECUTABLE=/usr/bin/gperf', command)
        self.assertIn('-DTD_INSTALL_SHARED_LIBRARIES=ON', command)
        self.assertIn('-DTD_INSTALL_STATIC_LIBRARIES=OFF', command)

    def git(self, root, *arguments):
        result = subprocess.run(['git', '-C', str(root), *arguments], capture_output=True, check=True)
        return result.stdout.decode('utf-8')


class ПроверкиГотовностиЗависимости(unittest.TestCase):
    """Локальные фикстуры создаются до измеряемой операции чтения."""

    def setUp(сам):
        сам.временныйКаталог = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временныйКаталог.cleanup)
        сам.каталог = Path(сам.временныйКаталог.name).resolve()
        сам.корень = сам.каталог / 'FUM'
        сам.корень.mkdir()
        сам.источник = сам.каталог / 'источник'
        сам.источник.mkdir()
        for репозиторий in (сам.корень, сам.источник):
            сам.гит(репозиторий, 'init', '-q')
            сам.гит(репозиторий, 'config', 'user.name', 'fixture')
            сам.гит(репозиторий, 'config', 'user.email', 'fixture@example.invalid')
        (сам.источник / 'CMakeLists.txt').write_text('project(fixture)\n')
        сам.гит(сам.источник, 'add', '.')
        сам.гит(сам.источник, 'commit', '-q', '-m', 'fixture')
        сам.гит(сам.корень, '-c', 'protocol.file.allow=always', 'submodule', 'add',
                 '--name', 'TDLib', str(сам.источник), 'Зависимости/TDLib')
        сам.зависимость = сам.корень / 'Зависимости/TDLib'
        сам.профиль = сборка.прочитатьПрофиль()
        сам.гит(сам.зависимость, 'remote', 'set-url', 'origin', сам.профиль['зависимость']['зеркало'])
        сам.гит(сам.зависимость, 'remote', 'add', 'upstream', сам.профиль['зависимость']['upstream'])
        сам.гит(сам.корень, 'config', '-f', '.gitmodules', 'submodule.TDLib.url', сам.профиль['зависимость']['зеркало'])
        сам.гит(сам.корень, 'config', '-f', '.gitmodules', 'submodule.TDLib.fumUpstream', сам.профиль['зависимость']['upstream'])
        сам.гит(сам.корень, 'add', '.gitmodules')
        сам.гит(сам.корень, 'commit', '-q', '-m', 'fixture')
        сам.профиль['зависимость'].update({
            'коммит': сам.гит(сам.зависимость, 'rev-parse', 'HEAD').strip(),
            'дерево': сам.гит(сам.зависимость, 'rev-parse', 'HEAD^{tree}').strip(),
            'времяКоммитаUnix': int(сам.гит(сам.зависимость, 'show', '-s', '--format=%ct', 'HEAD').strip()),
            'отпечаткиSha256': {'CMakeLists.txt': сборка.sha256(сам.зависимость / 'CMakeLists.txt')},
        })

    def гит(сам, корень, *аргументы):
        import os
        окружение = {ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith('GIT_')}
        окружение.update({'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull, 'GIT_OPTIONAL_LOCKS': '0'})
        результат = subprocess.run(['git', '-C', str(корень), '-c', 'core.fsmonitor=false', *аргументы],
                                  env=окружение, capture_output=True, check=True, timeout=15)
        return результат.stdout.decode()

    def снимок(сам):
        import hashlib
        import stat
        снимок = {}
        for файл in sorted(сам.каталог.rglob('*')):
            сведения = файл.lstat()
            запись = [stat.S_IMODE(сведения.st_mode)]
            if файл.is_symlink():
                запись.append(str(файл.readlink()))
            elif файл.is_file():
                запись.append(hashlib.sha256(файл.read_bytes()).hexdigest())
            снимок[str(файл.relative_to(сам.каталог))] = запись
        return снимок

    def проверить(сам, причина=None, *, окружение=None):
        import os
        до = сам.снимок()
        with patch.dict(os.environ, окружение or {}), \
                patch.object(сборка, 'собрать', side_effect=AssertionError('сборка запрещена')), \
                patch.object(сборка, 'проверитьВыход', side_effect=AssertionError('выход запрещён')), \
                patch.object(сборка, 'проверитьСреду', side_effect=AssertionError('toolchain запрещён')), \
                patch.object(сборка, '_клонироватьИсточник', side_effect=AssertionError('clone запрещён')), \
                patch.object(Path, 'mkdir', side_effect=AssertionError('mkdir запрещён')), \
                patch.object(subprocess, 'run', wraps=subprocess.run) as процессы:
            результат = сборка.проверитьГотовность(сам.корень, сам.профиль)
        сам.assertEqual(до, сам.снимок())
        сам.assertEqual(результат['схема'], 'fum.готовность-зависимости-tdlib.1')
        сам.assertEqual(результат['исход'], 'успех' if причина is None else 'отказ')
        сам.assertEqual(результат['причина'], причина or 'проверено')
        сам.assertNotIn(str(сам.каталог), json.dumps(результат, ensure_ascii=False))
        интервалы = результат['профиль']
        сам.assertGreaterEqual(len(интервалы), 2)
        for интервал in интервалы:
            сам.assertIs(type(интервал['длительностьНаносекунды']), int)
            сам.assertGreaterEqual(интервал['длительностьНаносекунды'], 0)
            сам.assertIn(интервал['исход'], ('успех', 'отказ'))
        for вызов in процессы.call_args_list:
            команда = вызов.args[0]
            сам.assertEqual(команда[0], 'git')
            сам.assertIn('core.fsmonitor=false', команда)
            сам.assertFalse({'clone', 'fetch', 'init', 'update', 'add', 'commit', 'checkout'} & set(команда))
            сам.assertEqual(вызов.kwargs['env']['GIT_OPTIONAL_LOCKS'], '0')
            сам.assertEqual(вызов.kwargs['env']['GIT_NO_LAZY_FETCH'], '1')
        return результат

    def test_чистая_синтетическая_зависимость_готова_без_записи(сам):
        результат = сам.проверить()
        сам.assertEqual([интервал['этап'] for интервал in результат['профиль']],
                         ['профиль', 'регистрация', 'исходные_объекты'])
        сам.assertEqual(результат['коммитФУМ'], сам.гит(сам.корень, 'rev-parse', 'HEAD').strip())
        сам.assertEqual(результат['источникПрофиля'], 'аргумент-фикстуры')
        сам.assertEqual(результат['регистрация']['гитлинк'], 'HEAD-и-индекс')
        сам.assertEqual(результат['регистрация']['манифест'], 'HEAD-индекс-рабочее-дерево')

    def test_отсутствие_регистрации_отдельно_от_материализации(сам):
        (сам.корень / '.gitmodules').write_text('')
        сам.проверить('нет_регистрации')

    def test_неинициализированная_зависимость_не_загружается(сам):
        import shutil
        shutil.rmtree(сам.зависимость)
        сам.проверить('нет_локальной_копии')

    def test_гитлинк_вершины_должен_совпадать_с_закреплённым(сам):
        сам.профиль['зависимость']['коммит'] = '0' * 40
        сам.проверить('неверный_гитлинк')

    def test_индекс_гитлинка_не_подменяет_вершину(сам):
        сам.гит(сам.корень, 'update-index', '--cacheinfo', '160000,' + '1' * 40 + ',Зависимости/TDLib')
        сам.проверить('неверный_гитлинк')

    def test_манифест_рабочего_дерева_и_индекса_не_подменяет_вершину(сам):
        файл = сам.корень / '.gitmodules'
        исходный = файл.read_bytes()
        файл.write_bytes(исходный + b'\n# drift\n')
        сам.проверить('расходится_регистрация')
        сам.гит(сам.корень, 'add', '.gitmodules')
        файл.write_bytes(исходный)
        сам.проверить('расходится_регистрация')

    def test_изменённая_локальная_копия_не_готова(сам):
        файл = сам.зависимость / 'CMakeLists.txt'
        исходный = файл.read_bytes()
        файл.write_bytes(исходный + b'# drift\n')
        сам.проверить('изменена_локальная_копия')
        файл.write_bytes(исходный)
        (сам.зависимость / 'чужой-файл').write_text('fixture')
        сам.проверить('изменена_локальная_копия')

    def test_неверный_и_отсутствующий_адрес_различимы_от_грязной_копии(сам):
        сам.гит(сам.зависимость, 'remote', 'set-url', 'origin', 'https://example.invalid/fixture.git')
        сам.проверить('неверные_источники')
        сам.гит(сам.зависимость, 'remote', 'set-url', 'origin', сам.профиль['зависимость']['зеркало'])
        сам.гит(сам.зависимость, 'remote', 'remove', 'upstream')
        сам.проверить('неверные_источники')

    def test_конфликтные_стадии_индекса_не_готовы(сам):
        идентификатор = сам.профиль['зависимость']['коммит']
        данные = f'0 {"0" * 40}\tЗависимости/TDLib\n160000 {идентификатор} 1\tЗависимости/TDLib\n160000 {идентификатор} 2\tЗависимости/TDLib\n'.encode()
        subprocess.run(['git', '-C', str(сам.корень), '-c', 'core.fsmonitor=false',
                        'update-index', '--index-info'], input=данные, capture_output=True, check=True, timeout=15)
        сам.проверить('неверный_гитлинк')

    def test_несовпадение_дерева_и_времени_не_маскируется(сам):
        дерево = сам.профиль['зависимость']['дерево']
        сам.профиль['зависимость']['дерево'] = '0' * 40
        сам.проверить('неверные_исходные_объекты')
        сам.профиль['зависимость']['дерево'] = дерево
        сам.профиль['зависимость']['времяКоммитаUnix'] += 1
        сам.проверить('неверные_исходные_объекты')

    def test_контракт_ревью_скрывающие_флаги_индекса_не_допускаются(сам):
        файл = сам.зависимость / 'CMakeLists.txt'
        исходный = файл.read_bytes()
        for флаг, отмена in (('--assume-unchanged', '--no-assume-unchanged'), ('--skip-worktree', '--no-skip-worktree')):
            with сам.subTest(флаг=флаг):
                сам.гит(сам.зависимость, 'update-index', флаг, 'CMakeLists.txt')
                файл.write_bytes(исходный + b'# hidden drift\n')
                сам.проверить('изменена_локальная_копия')
                файл.write_bytes(исходный)
                сам.гит(сам.зависимость, 'update-index', отмена, 'CMakeLists.txt')

    def test_контракт_ревью_обещания_всех_источников_нормализуется(сам):
        for имя, значение in (('origin', '1'), ('upstream', 'true')):
            with сам.subTest(имя=имя):
                сам.гит(сам.зависимость, 'config', f'remote.{имя}.promisor', значение)
                сам.проверить('неполная_локальная_копия')
                сам.гит(сам.зависимость, 'config', '--unset', f'remote.{имя}.promisor')

    def test_контракт_ревью_повреждённый_профиль_даёт_структурированный_отказ(сам):
        профильныйФайл = сам.каталог / 'профиль.json'
        прочитать = сборка.прочитатьПрофиль
        for значение in ([], None, {'схема': 'fum.профиль-сборки-tdlib.1', 'сборка': []}):
            with сам.subTest(значение=значение):
                профильныйФайл.write_text(json.dumps(значение))
                with patch.object(сборка, 'прочитатьПрофиль', side_effect=lambda: прочитать(профильныйФайл)):
                    результат = сборка.проверитьГотовность(сам.корень)
                сам.assertEqual(результат['исход'], 'отказ')
                сам.assertEqual(результат['причина'], 'неверный_профиль')

    def test_повторный_адрес_не_принимается(сам):
        сам.гит(сам.зависимость, 'config', '--add', 'remote.origin.url', сам.профиль['зависимость']['зеркало'])
        сам.проверить('неверные_источники')

    def test_неверные_объекты_сохраняют_предыдущие_измерения(сам):
        сам.профиль['зависимость']['отпечаткиSha256']['CMakeLists.txt'] = '0' * 64
        результат = сам.проверить('неверные_исходные_объекты')
        сам.assertEqual([интервал['исход'] for интервал in результат['профиль']], ['успех', 'успех', 'отказ'])

    def test_чужое_окружение_и_монитор_не_имеют_эффекта(сам):
        маркер = сам.каталог / 'вызван-fsmonitor'
        обработчик = сам.каталог / 'fsmonitor'
        обработчик.write_text('#!/bin/sh\ntouch "' + str(маркер) + '"\n')
        обработчик.chmod(0o700)
        сам.гит(сам.корень, 'config', 'core.fsmonitor', str(обработчик))
        сам.гит(сам.зависимость, 'config', 'core.fsmonitor', str(обработчик))
        сам.проверить(окружение={
            'GIT_DIR': str(сам.источник / '.git'), 'GIT_WORK_TREE': str(сам.источник),
            'GIT_INDEX_FILE': str(сам.источник / '.git/index'), 'GIT_CONFIG_COUNT': '1',
            'GIT_CONFIG_KEY_0': 'core.fsmonitor', 'GIT_CONFIG_VALUE_0': str(обработчик),
        })
        сам.assertFalse(маркер.exists())

    def test_команда_без_параметров_сборки_даёт_машинный_отказ_и_не_пишет(сам):
        (сам.корень / '.gitmodules').write_text('')
        до = сам.снимок()
        результат = subprocess.run([sys.executable, '-O', '-B', str(путь.resolve()),
                                    '--корень-репозитория', str(сам.корень), '--только-проверить-зависимость'],
                                   capture_output=True, text=True, timeout=15)
        сам.assertEqual(результат.returncode, 2)
        сам.assertEqual(результат.stdout, '')
        отказ = json.loads(результат.stderr)
        сам.assertEqual(отказ['схема'], 'fum.готовность-зависимости-tdlib.1')
        сам.assertEqual(отказ['причина'], 'нет_регистрации')
        сам.assertEqual(до, сам.снимок())

    def test_команда_отклоняет_смешение_режимов_и_неизвестный_флаг(сам):
        for дополнение in (['--выход', str(сам.каталог / 'выход')], ['--неизвестный-флаг']):
            with сам.subTest(дополнение=дополнение):
                до = сам.снимок()
                результат = subprocess.run([sys.executable, '-O', '-B', str(путь.resolve()),
                                            '--корень-репозитория', str(сам.корень),
                                            '--только-проверить-зависимость', *дополнение],
                                           capture_output=True, text=True, timeout=15)
                сам.assertEqual(результат.returncode, 2)
                сам.assertEqual(json.loads(результат.stderr)['причина'], 'неверные_аргументы')
                сам.assertEqual(до, сам.снимок())


if __name__ == '__main__':
    unittest.main()
