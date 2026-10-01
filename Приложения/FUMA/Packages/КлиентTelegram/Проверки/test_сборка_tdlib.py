import importlib.util
import json
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
            результат = subprocess.run(
                [sys.executable, '-B', str(путь.resolve()),
                 '--корень-репозитория', str(корень), '--выход', str(выход),
                 '--openssl-root', каталог],
                capture_output=True, text=True, timeout=15,
            )
            self.assertEqual(результат.returncode, 2)
            отказ = json.loads(результат.stderr)
            self.assertEqual(отказ['схема'], 'fum.сборка-tdlib.1')
            self.assertEqual(отказ['исход'], 'отказ')
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
                'PATH': '/usr/bin:/bin:/usr/sbin:/sbin',
                'HOME': str(home),
                'TMPDIR': str(temporary),
                'GIT_CONFIG_NOSYSTEM': '1',
                'GIT_CONFIG_GLOBAL': '/dev/null',
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


if __name__ == '__main__':
    unittest.main()
