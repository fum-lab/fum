"""Полный bound процесс и отдельный читающий повтор настоящего Creator."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import unittest
from unittest.mock import patch

import test_смены_незапечатанной_подготовки as основа

КОРЕНЬ = Path(__file__).resolve().parents[3]
ПРЕФИКС = 'Инструменты/fum-svyaznostj-rabochej-sessii/'
BOOT = ПРЕФИКС + 'scripts/запуск_принятого_писателя.py'
ENGINE = ПРЕФИКС + 'scripts/исполнение_принятого_кода.py'
СОСТАВ = ПРЕФИКС + 'состав-принятого-писателя.json'
_spec = importlib.util.spec_from_file_location('свежесть_фикстуры_запуска',
    КОРЕНЬ / 'Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py')
свежесть = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = свежесть
_spec.loader.exec_module(свежесть)
база = основа.основа.исходные.обычная.база


class ПолнаяФикстура(база.СозданиеКоммита):
    """Metadata создаётся до базовых Git-коммитов; checker не подменяется."""
    def гит(сам, *аргументы):
        if аргументы[0] == 'commit':
            память = сам.корень / 'Глоссарий/память-FUM.md'
            if not память.exists():
                память.parent.mkdir()
                память.write_text('# Память FUM\n\nОткрытая синтетическая память Git-фикстуры.\n')
                super().гит('add', '--', str(память.relative_to(сам.корень)))
            tracked = set(super().гит('ls-files', '-z').split('\0'))
            итог = свежесть.update_repository(сам.корень, check=False)
            if итог.errors: raise ValueError(итог.errors)
            пути = [str(п.relative_to(сам.корень)) for п in итог.changed_paths]
            пути = [п for п in пути if п in tracked or п == 'Индексы/markdown-файлы-по-времени-редактирования.md']
            if пути: super().гит('add', '--', *пути)
        return super().гит(*аргументы)


def байты(объект):
    return (json.dumps(объект, ensure_ascii=False, sort_keys=True) + '\n').encode()


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


class ЗапускПисателя(unittest.TestCase):
    def setUp(сам):
        сам.ф = основа.СменаПодготовки('runTest')
        with patch.object(база, 'СозданиеКоммита', ПолнаяФикстура):
            сам.ф.setUp()
        сам.addCleanup(сам.ф.doCleanups)
        сам.операция = сам.ф.ф
        сам.с = сам.операция.с
        сам.Q = сам.с.ф.каталог / 'принятый-код'; сам.Q.mkdir()
        состав = json.loads((КОРЕНЬ / СОСТАВ).read_bytes())
        for имя in [*состав['код'], *состав['ресурсы'], BOOT, ENGINE, СОСТАВ]:
            цель = сам.Q / имя; цель.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(КОРЕНЬ / имя, цель)
        сам.гит('init', '-q'); сам.гит('config', 'gc.auto', '0')
        сам.гит('config', 'maintenance.auto', 'false')
        сам.гит('config', 'user.name', 'Открытая фикстура')
        сам.гит('config', 'user.email', 'fixture@example.invalid')
        сам.гит('add', '.'); сам.гит('commit', '-qm', 'Конечный принятый код')
        сам.q = сам.гит('rev-parse', 'HEAD').strip()
        сам.вход = сам.с.приватный('bound-вход.json', сам.с.вход)
        сам.настройки = {
            'схема': 'fum.запуск-принятого-писателя.1',
            'код': {'корень': str(сам.Q), 'коммит': сам.q},
            'данные': {'корень': str(сам.с.корень), 'коммит': сам.с.база, 'пути': ['Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy.json']},
            'вход': {'путь': str(сам.вход), 'хэш': хэш(сам.вход.read_bytes())},
            'новые_параметры': сам.ф.запрос['новые_параметры'],
            'проверки': [основа.основа.исходные.обычная.база.ЗАПУСК],
            'готовность': str(основа.писатель.коммит.готовность.КОРЕНЬ_СОСТОЯНИЯ),
            'возраст_проверок': 600,
        }
        сам.манифест = сам.с.приватный('bound-манифест.json', сам.настройки)
        сам.профиль = []

    def гит(сам, *аргументы):
        return subprocess.check_output(['git', '--no-optional-locks', '-C', str(сам.Q), *аргументы], text=True)

    def процесс(сам, режим, *, среда=None):
        начало = time.perf_counter_ns()
        р = subprocess.run([sys.executable, '-I', '-S', '-B', str(сам.Q / BOOT),
            '--корень-кода', str(сам.Q), '--коммит-кода', сам.q,
            '--bootstrap-sha256', хэш((сам.Q / BOOT).read_bytes()),
            '--engine-sha256', хэш((сам.Q / ENGINE).read_bytes()),
            '--манифест', str(сам.манифест), '--sha256', хэш(сам.манифест.read_bytes()),
            '--режим', режим], cwd=сам.с.корень, env=среда, capture_output=True, text=True, timeout=120)
        сам.профиль.append({'режим': режим, 'процесс_нс': time.perf_counter_ns()-начало})
        return р

    def сверить_снимок(сам, до):
        после = сам.операция.снимок()
        изменения = [п for п in sorted(set(до) | set(после)) if до.get(п) != после.get(п)]
        сам.assertFalse(изменения, [(п, [i for i in range(5)
            if до.get(п, (None,)*5)[i] != после.get(п, (None,)*5)[i]]) for п in изменения])

    def test_настоящий_Creator_и_RO_повтор_в_разных_процессах(сам):
        р = сам.процесс('смена')
        сам.assertEqual(0, р.returncode, р.stdout + р.stderr)
        итог = json.loads(р.stdout)
        сам.assertEqual(сам.ф.сохранённые, сам.ф.старые_свидетельства())
        сам.assertEqual('1', сам.с.ф.гит('rev-list', '--count', сам.с.база+'..HEAD').strip())
        до = сам.операция.снимок()
        повтор = сам.процесс('повтор')
        сам.assertEqual(0, повтор.returncode, повтор.stdout + повтор.stderr)
        восстановленный = json.loads(повтор.stdout)
        сам.assertEqual(итог['результат'], восстановленный['результат'])
        сам.assertNotEqual(итог['pid'], восстановленный['pid'])
        сам.сверить_снимок(до)
        сам.assertEqual(0, восстановленный['эффектов'])
        сам.assertEqual(0, восстановленный['API'])

    def test_подмена_принятого_ресурса_отказывает_до_поколения2(сам):
        имя = json.loads((сам.Q / СОСТАВ).read_bytes())['ресурсы'][0]
        (сам.Q / имя).write_bytes('подменено'.encode())
        до = сам.операция.снимок()
        р = сам.процесс('смена')
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('байты', р.stderr)
        сам.сверить_снимок(до)

    def test_относительный_PATH_отказывает_до_записи(сам):
        до = сам.операция.снимок()
        среда = dict(os.environ, PATH='.' + os.pathsep + os.environ['PATH'])
        р = сам.процесс('смена', среда=среда)
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('абсолютный непустой PATH', р.stderr)
        сам.сверить_снимок(до)

    def test_пишущая_форма_symbolic_ref_отказывает_до_Popen(сам):
        вход = json.loads((сам.Q / СОСТАВ).read_bytes())['вход']
        код = "import subprocess\nsubprocess.run(['git', '-C', U['корень'], 'symbolic-ref', 'HEAD', 'refs/heads/чужая'])\n"
        (сам.Q / вход).write_text(код)
        сам.гит('add', вход); сам.гит('commit', '-qm', 'Открытая отрицательная фикстура пишущего Git')
        сам.q = сам.гит('rev-parse', 'HEAD').strip()
        сам.настройки['код']['коммит'] = сам.q
        сам.манифест.write_bytes(байты(сам.настройки))
        до = сам.операция.снимок()
        р = сам.процесс('проверка')
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('пишущий Git в читающем режиме', р.stderr)
        сам.сверить_снимок(до)

    def test_чужой_executable_при_разрешённом_argv_отказывает_до_записи(сам):
        вход = json.loads((сам.Q / СОСТАВ).read_bytes())['вход']
        # Не доверяем argv отдельно от executable: те же аргументы, иной ELF/Mach-O.
        (сам.Q / вход).write_text("import subprocess\nsubprocess.run(команда_проверки, executable='/usr/bin/true')\n")
        сам.гит('add', вход); сам.гит('commit', '-qm', 'Открытая отрицательная фикстура executable')
        сам.q = сам.гит('rev-parse', 'HEAD').strip()
        сам.настройки['код']['коммит'] = сам.q
        сам.манифест.write_bytes(байты(сам.настройки))
        до = сам.операция.снимок()
        р = сам.процесс('смена')
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('subprocess не входит', р.stderr)
        сам.сверить_снимок(до)

    def test_изменённый_манифест_с_прежним_SHA_не_исполняется(сам):
        # Явный внешний SHA в команде не перепривязывается после порчи.
        старый = хэш(сам.манифест.read_bytes())
        сам.манифест.write_bytes(сам.манифест.read_bytes() + b'\n')
        р = subprocess.run([sys.executable, '-I', '-S', '-B', str(сам.Q / BOOT),
            '--корень-кода', str(сам.Q), '--коммит-кода', сам.q,
            '--bootstrap-sha256', хэш((сам.Q / BOOT).read_bytes()),
            '--engine-sha256', хэш((сам.Q / ENGINE).read_bytes()),
            '--манифест', str(сам.манифест), '--sha256', старый, '--режим', 'смена'],
            cwd=сам.с.корень, capture_output=True, text=True, timeout=20)
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('манифест', р.stderr)


class РаннийОтказСмены(unittest.TestCase):
    """Проверяет диспетчер без полного Creator и файловой фикстуры."""

    def setUp(сам):
        описание = importlib.util.spec_from_file_location(
            'запуск_писателя_проверка_раннего_отказа', КОРЕНЬ / BOOT)
        сам.модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(сам.модуль)

    @staticmethod
    def аргументы(режим):
        return ['запуск', '--корень-кода', '/несуществующий-корень',
                '--коммит-кода', '0' * 40, '--bootstrap-sha256', '0' * 64,
                '--engine-sha256', '0' * 64, '--манифест', '/несуществующий-манифест',
                '--sha256', '0' * 64, '--режим', режим]

    def test_смена_отказывает_до_среды_и_эффектов(сам):
        import builtins
        import io
        import tempfile

        class ЗапрещённаяСреда(dict):
            def __getitem__(сам, ключ): raise AssertionError('чтение среды')
            def __iter__(сам): raise AssertionError('чтение среды')
            def __contains__(сам, ключ): raise AssertionError('чтение среды')
            def get(сам, ключ, default=None): raise AssertionError('чтение среды')
            def items(сам): raise AssertionError('чтение среды')
            def keys(сам): raise AssertionError('чтение среды')

        def запрещено(*аргументы, **ключевые):
            raise AssertionError('эффект до раннего отказа')

        ошибка = io.StringIO()
        with patch.object(sys, 'argv', сам.аргументы('смена')), \
             patch.object(sys, 'stderr', ошибка), \
             patch.object(os, 'environ', ЗапрещённаяСреда()), \
             patch.object(builtins, 'open', side_effect=запрещено), \
             patch.object(os, 'open', side_effect=запрещено), \
             patch.object(os, 'mkdir', side_effect=запрещено), \
             patch.object(tempfile, 'mkdtemp', side_effect=запрещено), \
             patch.object(subprocess, 'Popen', side_effect=запрещено), \
             patch.object(sys, 'addaudithook', side_effect=запрещено):
            сам.assertEqual(сам.модуль.главная(), 2)
        результат = json.loads(ошибка.getvalue())
        сам.assertEqual(результат['ошибка'],
            'смена закрыта до восстановления ограниченной среды и отчётной обёртки')
        сам.assertIs(результат['автоматический_повтор'], False)

    def test_остальные_режимы_передаются_прежнему_исполнителю(сам):
        for режим in ('повтор', 'recency', 'проверка'):
            with сам.subTest(режим=режим), \
                 patch.object(sys, 'argv', сам.аргументы(режим)), \
                 patch.object(сам.модуль, 'конечный_запуск', return_value=73) as исполнитель:
                сам.assertEqual(сам.модуль.главная(), 73)
                сам.assertEqual(исполнитель.call_args.args[0].режим, режим)

    def test_прямой_вызов_смены_не_читает_среду(сам):
        from types import SimpleNamespace

        class ЗапрещённаяСреда(dict):
            def get(сам, ключ, default=None): raise AssertionError('чтение среды')
            def items(сам): raise AssertionError('чтение среды')

        with patch.object(os, 'environ', ЗапрещённаяСреда()):
            with сам.assertRaisesRegex(ValueError, 'смена закрыта'):
                сам.модуль.конечный_запуск(SimpleNamespace(режим='смена'))

    def test_cli_смены_в_отдельном_процессе_отказывает_до_импортов_и_эффектов(сам):
        программа = '''
import builtins, os, subprocess, sys, tempfile
имя = sys.argv[1]
with open(имя, 'rb') as файл:
    код = compile(файл.read(), имя, 'exec')
sys.argv = [имя, *sys.argv[2:]]
class ЗапрещённаяСреда(dict):
    def __getitem__(сам, ключ): raise AssertionError('чтение среды')
    def __iter__(сам): raise AssertionError('чтение среды')
    def __contains__(сам, ключ): raise AssertionError('чтение среды')
    def get(сам, ключ, default=None): raise AssertionError('чтение среды')
    def items(сам): raise AssertionError('чтение среды')
    def keys(сам): raise AssertionError('чтение среды')
def запрещено(*аргументы, **ключевые):
    raise AssertionError('эффект до раннего отказа')
os.environ = ЗапрещённаяСреда()
builtins.open = os.open = os.mkdir = tempfile.mkdtemp = subprocess.Popen = sys.addaudithook = запрещено
exec(код, {'__name__': '__main__', '__file__': имя})
'''
        основа = сам.аргументы('смена')[1:-2]
        for окончание in (['--режим', 'смена'], ['--режим=смена'],
                          ['--р', 'смена'], ['--ре=смена'], ['--реж=смена'],
                          ['--режи', 'смена'], ['--режим', 'смена', '--режим', 'повтор'],
                          ['--режим', 'повтор', '--режим', 'смена']):
            with сам.subTest(окончание=окончание):
                р = subprocess.run([sys.executable, '-I', '-S', '-B', '-c', программа,
                                    str(КОРЕНЬ / BOOT), *основа, *окончание],
                                   env={}, capture_output=True, text=True, timeout=5)
                сам.assertEqual(р.returncode, 2, р.stderr)
                сам.assertEqual(р.stdout, '')
                результат = json.loads(р.stderr)
                сам.assertEqual(результат['ошибка'],
                    'смена закрыта до восстановления ограниченной среды и отчётной обёртки')
                сам.assertIs(результат['автоматический_повтор'], False)


class ПроверкаЯвногоGitАудита(unittest.TestCase):
    """Допуск ограниченных Git-reader без наследования PATH."""

    def setUp(сам):
        описание = importlib.util.spec_from_file_location(
            'писатель_аудит_git_проверка', КОРЕНЬ / BOOT)
        сам.модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(сам.модуль)
        сам.корень = '/private/tmp/fum-synthetic-audit'
        сам.среда = {'PATH': '/usr/bin:/bin', 'LC_ALL': 'C', 'GIT_OPTIONAL_LOCKS': '0',
            'GIT_NO_LAZY_FETCH': '1', 'GIT_NO_REPLACE_OBJECTS': '1',
            'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null',
            'GIT_ATTR_NOSYSTEM': '1', 'GIT_TERMINAL_PROMPT': '0'}
        сам.основа = ['/usr/bin/git', '--no-optional-locks', '--no-replace-objects',
            '-c', 'core.hooksPath=/dev/null', '-c', 'core.fsmonitor=false',
            '-c', 'protocol.allow=never', '-C', сам.корень]

    def test_принимает_два_reader_без_host_path(сам):
        class ЗапрещённаяСреда(dict):
            def get(сам, ключ, default=None): raise AssertionError('чтение среды')
            def items(сам): raise AssertionError('чтение среды')
        literal = сам.основа[:3] + ['--literal-pathspecs'] + сам.основа[3:]
        случаи = ((сам.основа + ['rev-parse', 'a' * 40 + '^{commit}'],
                   ['rev-parse', 'a' * 40 + '^{commit}']),
                  (сам.основа + ['cat-file', '--batch'], ['cat-file', '--batch']),
                  (literal + ['ls-tree', '-z', 'a' * 40, '--', 'код/файл'],
                   ['ls-tree', '-z', 'a' * 40, '--', 'код/файл']),
                  (literal + ['cat-file', 'blob', 'b' * 40], ['cat-file', 'blob', 'b' * 40]))
        with patch.object(os, 'environ', ЗапрещённаяСреда()), \
             patch.object(shutil, 'which', side_effect=AssertionError('поиск PATH')):
            for argv, ожидаемое in случаи:
                with сам.subTest(argv=argv):
                    сам.assertEqual(сам.модуль._профиль_явного_гита(
                        '/usr/bin/git', argv, None, сам.среда, (сам.корень,)), ожидаемое)

    def test_неверный_явный_профиль_не_переходит_в_старый(сам):
        argv = сам.основа + ['cat-file', '--batch']
        случаи = (('/usr/bin/git', argv, None, {**сам.среда, 'EXTRA': 'x'}, (сам.корень,)),
                  ('/bin/echo', argv, None, сам.среда, (сам.корень,)),
                  ('/usr/bin/git', argv, '/tmp', сам.среда, (сам.корень,)),
                  ('/usr/bin/git', argv, None, сам.среда, ('/private/tmp/other',)),
                  ('/usr/bin/git', сам.основа[:-2] + ['-c', 'x=y'] + сам.основа[-2:]
                   + ['cat-file', '--batch'], None, сам.среда, (сам.корень,)),
                  ('/usr/bin/git', сам.основа + ['config', '--list'], None, сам.среда, (сам.корень,)),
                  ('/usr/bin/git', сам.основа + ['ls-tree', '-z', 'a' * 40, '--', ':(glob)*'],
                   None, сам.среда, (сам.корень,)))
        for случай in случаи:
            with сам.subTest(случай=случай), сам.assertRaisesRegex(ValueError, 'явный Git'):
                сам.модуль._профиль_явного_гита(*случай)
        сам.assertIsNone(сам.модуль._профиль_явного_гита('/bin/echo', ['/bin/echo'],
            None, {}, (сам.корень,)))

    def test_audit_сохраняет_выбранный_исполнитель(сам):
        import ast

        путь = КОРЕНЬ / BOOT
        дерево = ast.parse(путь.read_bytes(), filename=str(путь))
        запуск = next(узел for узел in дерево.body
            if isinstance(узел, ast.FunctionDef) and узел.name == 'конечный_запуск')
        аудит = next(узел for узел in запуск.body
            if isinstance(узел, ast.FunctionDef) and узел.name == 'аудит')
        вызовы = []
        область = {'os': os, 'сверить': lambda: вызовы.append('сверено'),
            'требовать': сам.модуль.требовать,
            '_профиль_явного_гита': сам.модуль._профиль_явного_гита,
            'Q': Path(сам.корень), 'данные': {'корень': сам.корень},
            'git': '/bin/false'}
        exec(compile(ast.fix_missing_locations(ast.Module(body=[аудит], type_ignores=[])),
            str(путь), 'exec'), область)
        аргументы = ('/usr/bin/git', сам.основа + ['cat-file', '--batch'], None, сам.среда)
        with сам.assertRaisesRegex(ValueError, 'другой выбранный исполнитель'):
            область['аудит']('subprocess.Popen', аргументы)
        область['git'] = '/usr/bin/git'
        область['аудит']('subprocess.Popen', аргументы)
        сам.assertEqual(вызовы, ['сверено', 'сверено'])


class ПроверкаGitEngineБезСреды(unittest.TestCase):
    """Проверяет вызываемый по умолчанию Git-reader принятого движка."""

    def setUp(сам):
        описание = importlib.util.spec_from_file_location(
            'движок_git_проверка', КОРЕНЬ / ENGINE)
        сам.модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(сам.модуль)
        сам.корень = Path('/private/tmp/fum-synthetic-engine')
        сам.среда = {'PATH': '/usr/bin:/bin', 'LC_ALL': 'C', 'GIT_OPTIONAL_LOCKS': '0',
            'GIT_NO_LAZY_FETCH': '1', 'GIT_NO_REPLACE_OBJECTS': '1',
            'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null',
            'GIT_ATTR_NOSYSTEM': '1', 'GIT_TERMINAL_PROMPT': '0'}
        сам.основа = ['/usr/bin/git', '--no-optional-locks', '--no-replace-objects',
            '-c', 'core.hooksPath=/dev/null', '-c', 'core.fsmonitor=false',
            '-c', 'protocol.allow=never', '-C', str(сам.корень)]

    def test_без_входа_не_читает_среду_и_передаёт_eof(сам):
        class ЗапрещённаяСреда(dict):
            def __getitem__(сам, ключ): raise AssertionError('чтение среды')
            def __iter__(сам): raise AssertionError('чтение среды')
            def get(сам, ключ, default=None): raise AssertionError('чтение среды')
            def items(сам): raise AssertionError('чтение среды')
            def keys(сам): raise AssertionError('чтение среды')
        with patch.object(os, 'environ', ЗапрещённаяСреда()), \
             patch.object(subprocess, 'check_output', return_value=b'head\n') as вызов:
            сам.assertEqual(сам.модуль.вызвать_гит(сам.корень, 'rev-parse', 'HEAD'), b'head\n')
        сам.assertEqual(вызов.call_args.args[0], [*сам.основа, 'rev-parse', 'HEAD'])
        сам.assertEqual(вызов.call_args.kwargs,
            {'env': сам.среда, 'stdin': subprocess.DEVNULL, 'timeout': 30})

    def test_явный_вход_сохраняется_включая_пустые_байты(сам):
        for вход in (b'', b'packet\x00bytes\n'):
            with сам.subTest(вход=вход), \
                 patch.object(subprocess, 'check_output', return_value=b'answer') as вызов:
                сам.assertEqual(сам.модуль.вызвать_гит(
                    сам.корень, 'cat-file', '--batch', вход=вход), b'answer')
            сам.assertEqual(вызов.call_args.args[0], [*сам.основа, 'cat-file', '--batch'])
            сам.assertEqual(вызов.call_args.kwargs,
                {'env': сам.среда, 'input': вход, 'timeout': 30})


class ПроверкаGitBlobБезСреды(unittest.TestCase):
    """Граница bootstrap-чтения без реального Git и окружения хоста."""

    def setUp(сам):
        описание = importlib.util.spec_from_file_location(
            'писатель_git_blob_проверка', КОРЕНЬ / BOOT)
        сам.модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(сам.модуль)
        сам.корень = Path('/private/tmp/fum-synthetic-git-blob')
        сам.коммит = 'a' * 40
        сам.имя = 'код/fixture.txt'
        сам.байты = b'fixture\x00bytes\n'
        сам.oid = hashlib.sha1(b'blob ' + str(len(сам.байты)).encode() + b'\x00' + сам.байты).hexdigest()
        сам.запись = ('100644 blob ' + сам.oid + '\t' + сам.имя).encode() + b'\x00'

    def test_git_blob_не_читает_host_env_и_закрывает_stdin(сам):
        class ЗапрещённаяСреда(dict):
            def __getitem__(сам, ключ): raise AssertionError('чтение среды')
            def __iter__(сам): raise AssertionError('чтение среды')
            def get(сам, ключ, default=None): raise AssertionError('чтение среды')
            def items(сам): raise AssertionError('чтение среды')
            def keys(сам): raise AssertionError('чтение среды')

        with patch.object(os, 'environ', ЗапрещённаяСреда()), \
             patch.object(сам.модуль, 'обычный', return_value=сам.байты), \
             patch.object(subprocess, 'check_output', side_effect=[сам.запись, сам.байты]) as вызов:
            сам.assertEqual(сам.модуль.git_blob(сам.корень, сам.коммит, сам.имя), сам.байты)
        среда = {'PATH': '/usr/bin:/bin', 'LC_ALL': 'C', 'GIT_OPTIONAL_LOCKS': '0',
            'GIT_NO_LAZY_FETCH': '1', 'GIT_NO_REPLACE_OBJECTS': '1',
            'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null',
            'GIT_ATTR_NOSYSTEM': '1', 'GIT_TERMINAL_PROMPT': '0'}
        основа = ['/usr/bin/git', '--no-optional-locks', '--no-replace-objects',
            '--literal-pathspecs', '-c', 'core.hooksPath=/dev/null',
            '-c', 'core.fsmonitor=false', '-c', 'protocol.allow=never', '-C', str(сам.корень)]
        сам.assertEqual(вызов.call_count, 2)
        сам.assertEqual(вызов.call_args_list[0].args[0],
            [*основа, 'ls-tree', '-z', сам.коммит, '--', сам.имя])
        сам.assertEqual(вызов.call_args_list[1].args[0], [*основа, 'cat-file', 'blob', сам.oid])
        for запись in вызов.call_args_list:
            сам.assertEqual(запись.kwargs['env'], среда)
            сам.assertEqual(запись.kwargs['stdin'], subprocess.DEVNULL)
            сам.assertEqual(запись.kwargs['timeout'], 30)

    def test_несовпадение_blob_отказывает_без_повтора(сам):
        with patch.object(subprocess, 'check_output', side_effect=[сам.запись, b'wrong bytes']) as вызов:
            with сам.assertRaisesRegex(ValueError, 'не соответствует байтам'):
                сам.модуль.git_blob(сам.корень, сам.коммит, сам.имя)
        сам.assertEqual(вызов.call_count, 2)


class ПроверкаКаталогаРесурсовБезСреды(unittest.TestCase):
    """Список Git-каталога ресурсов получает конечную среду и EOF."""

    def setUp(сам):
        описание = importlib.util.spec_from_file_location(
            'писатель_каталог_ресурсов_проверка', КОРЕНЬ / BOOT)
        сам.модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(сам.модуль)
        сам.корень = '/private/tmp/fum-synthetic-resources'
        сам.коммит = 'a' * 40
        сам.каталог = 'Инструменты/проверка/шаблоны'

    def test_список_передаёт_явные_параметры_без_host_env(сам):
        class ЗапрещённаяСреда(dict):
            def __getitem__(сам, ключ): raise AssertionError('чтение среды')
            def __iter__(сам): raise AssertionError('чтение среды')
            def get(сам, ключ, default=None): raise AssertionError('чтение среды')
            def items(сам): raise AssertionError('чтение среды')
            def keys(сам): raise AssertionError('чтение среды')

        ответ = b'100644 blob ' + b'b' * 40 + b'\tfixture.txt\x00'
        with patch.object(os, 'environ', ЗапрещённаяСреда()), \
             patch.object(shutil, 'which', side_effect=AssertionError('поиск PATH')), \
             patch.object(subprocess, 'check_output', return_value=ответ) as вызов:
            сам.assertEqual(сам.модуль._список_git_каталога(
                сам.корень, сам.коммит, сам.каталог), ответ)
        сам.assertEqual(вызов.call_args.args[0], [
            '/usr/bin/git', '--no-optional-locks', '--no-replace-objects',
            '-c', 'core.hooksPath=/dev/null', '-c', 'core.fsmonitor=false',
            '-c', 'protocol.allow=never', '-C', сам.корень,
            'ls-tree', '-z', сам.коммит + ':' + сам.каталог])
        сам.assertEqual(вызов.call_args.kwargs, {
            'env': {'PATH': '/usr/bin:/bin', 'LC_ALL': 'C', 'GIT_OPTIONAL_LOCKS': '0',
                    'GIT_NO_LAZY_FETCH': '1', 'GIT_NO_REPLACE_OBJECTS': '1',
                    'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null',
                    'GIT_ATTR_NOSYSTEM': '1', 'GIT_TERMINAL_PROMPT': '0'},
            'stdin': subprocess.DEVNULL, 'timeout': 30})

    def test_неверные_входы_отклоняются_до_git(сам):
        случаи = (('relative', сам.коммит, сам.каталог),
                  (сам.корень + '/..', сам.коммит, сам.каталог),
                  (сам.корень, 'a' * 39, сам.каталог),
                  (сам.корень, 'A' * 40, сам.каталог),
                  (сам.корень, сам.коммит, ''),
                  (сам.корень, сам.коммит, '/типы'),
                  (сам.корень, сам.коммит, '../типы'),
                  (сам.корень, сам.коммит, 'a//типы'),
                  (сам.корень, сам.коммит, 'a/./типы'),
                  (сам.корень, сам.коммит, 'a/../типы'),
                  (сам.корень, сам.коммит, 'a\x00/типы'))
        with patch.object(subprocess, 'check_output') as вызов:
            for корень, коммит, каталог in случаи:
                with сам.subTest(корень=корень, коммит=коммит, каталог=каталог), \
                     сам.assertRaises(ValueError):
                    сам.модуль._список_git_каталога(корень, коммит, каталог)
        вызов.assert_not_called()

    def test_разбор_сохраняет_имена_и_режимы(сам):
        первая = b'100644 blob ' + b'a' * 40 + b'\tplain.txt\x00'
        вторая = b'100755 blob ' + b'b' * 40 + b'\tfile\tname\x00'
        сам.assertEqual(сам.модуль._разобрать_git_каталог(b''), {})
        сам.assertEqual(сам.модуль._разобрать_git_каталог(первая + вторая),
                        {'plain.txt': '100644', 'file\tname': '100755'})

    def test_повреждённый_список_отклоняется(сам):
        разбор = сам.модуль._разобрать_git_каталог
        запись = b'100644 blob ' + b'a' * 40 + b'\tfile.txt\x00'
        случаи = (запись[:-1], b'\x00' + запись, запись + b'\x00', запись + запись,
                  b'120000 blob ' + b'a' * 40 + b'\tlink\x00',
                  b'100644 tree ' + b'a' * 40 + b'\tdir\x00',
                  b'100644 blob ' + b'g' * 40 + b'\tfile\x00',
                  b'100644 blob ' + b'a' * 40 + b'\t\x00',
                  b'100644 blob ' + b'a' * 40 + b'\ta/b\x00',
                  b'100644 blob ' + b'a' * 40 + b'\t\xff\x00')
        for данные in случаи:
            with сам.subTest(данные=данные), сам.assertRaises(ValueError):
                разбор(данные)


def load_tests(loader, tests, pattern):
    # Helper наследует fixture API; самостоятельного повторного набора у него нет.
    return unittest.TestSuite((loader.loadTestsFromTestCase(ПроверкаКаталогаРесурсовБезСреды),
                               loader.loadTestsFromTestCase(ПроверкаЯвногоGitАудита),
        loader.loadTestsFromTestCase(ПроверкаGitEngineБезСреды),
        loader.loadTestsFromTestCase(ПроверкаGitBlobБезСреды),
        loader.loadTestsFromTestCase(РаннийОтказСмены),
        loader.loadTestsFromTestCase(ЗапускПисателя)))


if __name__ == '__main__':
    unittest.main()
