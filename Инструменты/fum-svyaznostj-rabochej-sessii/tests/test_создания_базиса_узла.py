"""Независимые Git-фикстуры фиксированного предметного индекса базиса."""
import hashlib
import ast
import fcntl
import importlib.util
import json
import os
import signal
import stat
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import types
import unittest
import shutil
import uuid
import re
import unicodedata
from unittest.mock import patch


КОРЕНЬ = Path(__file__).resolve().parents[3]
ДОПУСК = КОРЕНЬ / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/допуск_создания_базиса_узла.py'


class ФикстураБазиса:
    def __init__(сам):
        сам.временный = tempfile.TemporaryDirectory(prefix='fum-basis-fixture-')
        сам.каталог = Path(сам.временный.name).resolve()
        сам.корень = сам.каталог / 'предмет'
        сам.корень.mkdir()
        сам.гит('init', '-q', '-b', 'основа')
        assert сам.гит('rev-parse', '--absolute-git-dir').strip() == str(сам.корень / '.git')
        assert not (сам.корень / '.git').is_symlink()
        сам.гит('config', 'user.name', 'Открытая фикстура')
        сам.гит('config', 'user.email', 'fixture@example.invalid')
        сам.гит('config', 'gc.auto', '0')
        сам.гит('config', 'maintenance.auto', 'false')
        for имя in ('корень.txt', 'состояние.txt'):
            (сам.корень / имя).write_text('Начало\n')
        сам.гит('add', '.')
        сам.гит('commit', '-qm', 'Начальная фикстура')
        сам.начало = сам.гит('rev-parse', 'HEAD').strip()
        (сам.корень / 'корень.txt').write_text('Корень K\n')
        сам.гит('add', 'корень.txt')
        сам.гит('commit', '-qm', 'Закрепить K')
        сам.основа_фикстуры = сам.гит('rev-parse', 'HEAD').strip()
        сам.гит('checkout', '-q', '-b', 'включение', сам.начало)
        (сам.корень / 'состояние.txt').write_text('Включение R1\n')
        сам.гит('add', 'состояние.txt')
        сам.гит('commit', '-qm', 'Закрепить R1')
        сам.включение_фикстуры = сам.гит('rev-parse', 'HEAD').strip()
        сам.гит('checkout', '-q', 'основа')
        сам.гит('merge', '--no-ff', '--no-commit', сам.включение_фикстуры)
        сам.дерево_фикстуры = сам.гит('write-tree').strip()
        сам.предмет = {'основа': сам.основа_фикстуры, 'включение': сам.включение_фикстуры,
                      'дерево': сам.дерево_фикстуры, 'родители': [сам.основа_фикстуры, сам.включение_фикстуры]}

    def гит(сам, *аргументы, вход=None):
        среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
        среда.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull,
                     GIT_NO_REPLACE_OBJECTS='1', GIT_NO_LAZY_FETCH='1', GIT_TERMINAL_PROMPT='0')
        return subprocess.check_output(['git', '--no-optional-locks',
            '-c', 'core.hooksPath=' + os.devnull, '-c', 'trace2.normalTarget=0',
            '-c', 'trace2.eventTarget=0', '-c', 'trace2.perfTarget=0',
            '-c', 'core.fsmonitor=false', '-c', 'commit.gpgSign=false',
            '-c', 'gc.auto=0', '-c', 'maintenance.auto=false', '-c', 'protocol.allow=never',
            '-C', str(сам.корень), *аргументы],
            text=True, input=вход, env=среда, stderr=subprocess.PIPE)

    def снимок(сам):
        return ((сам.корень / '.git/index').read_bytes(),
                (сам.корень / '.git/HEAD').read_bytes(),
                (сам.корень / '.git/MERGE_HEAD').read_bytes(),
                сам.гит('rev-parse', 'HEAD'),
                (сам.корень / '.git/config').read_bytes(),
                tuple(sorted((п.relative_to(сам.корень / '.git/objects').as_posix(),
                              п.stat().st_mode, hashlib.sha256(п.read_bytes()).hexdigest())
                             for п in (сам.корень / '.git/objects').rglob('*') if п.is_file())))

    def закрепить_дерево(сам):
        сам.дерево_фикстуры = сам.гит('write-tree').strip()
        сам.предмет['дерево'] = сам.дерево_фикстуры

    def закрыть(сам):
        сам.временный.cleanup()


def загрузить_допуск():
    описание = importlib.util.spec_from_file_location('допуск_базиса_фикстуры', ДОПУСК)
    модуль = importlib.util.module_from_spec(описание)
    описание.loader.exec_module(модуль)
    return модуль


class ИндексБазиса(unittest.TestCase):
    def setUp(сам):
        сам.ф = ФикстураБазиса()
        сам.addCleanup(сам.ф.закрыть)
        сам.допуск = загрузить_допуск()

    def отказ(сам, предмет):
        до = сам.ф.снимок()
        with сам.assertRaises(ValueError):
            сам.допуск.сверить_индекс(сам.ф.корень, предмет)
        сам.assertEqual(до, сам.ф.снимок())

    def test_точное_дерево_читается_без_записи_индекса_и_объектов(сам):
        до = сам.ф.снимок()
        объекты = sorted(п.relative_to(сам.ф.корень / '.git/objects').as_posix()
                         for п in (сам.ф.корень / '.git/objects').rglob('*') if п.is_file())
        результат = сам.допуск.сверить_индекс(сам.ф.корень, сам.ф.предмет)
        сам.assertEqual(сам.ф.дерево_фикстуры, результат['дерево'])
        сам.assertEqual(до, сам.ф.снимок())
        сам.assertEqual(объекты, sorted(п.relative_to(сам.ф.корень / '.git/objects').as_posix()
                         for п in (сам.ф.корень / '.git/objects').rglob('*') if п.is_file()))

    def test_отчётное_дерево_не_подставляется_вместо_предметного(сам):
        сам.отказ({**сам.ф.предмет, 'дерево': сам.ф.гит('rev-parse', сам.ф.основа_фикстуры + '^{tree}').strip()})

    def test_переставленные_родители_отклоняются(сам):
        сам.отказ({**сам.ф.предмет, 'родители': [сам.ф.включение_фикстуры, сам.ф.основа_фикстуры]})

    def test_повторный_родитель_отклоняется(сам):
        сам.отказ({**сам.ф.предмет, 'родители': [сам.ф.основа_фикстуры, сам.ф.основа_фикстуры]})

    def test_лишний_индексный_путь_отклоняется(сам):
        (сам.ф.корень / 'лишний.txt').write_text('Не входит в T\n')
        сам.ф.гит('add', 'лишний.txt')
        сам.отказ(сам.ф.предмет)

    def test_неверный_родитель_слияния_отклоняется(сам):
        (сам.ф.корень / '.git/MERGE_HEAD').write_text(сам.ф.основа_фикстуры + '\n')
        сам.отказ(сам.ф.предмет)

    def test_несколько_родителей_слияния_отклоняются(сам):
        (сам.ф.корень / '.git/MERGE_HEAD').write_text(сам.ф.включение_фикстуры + '\n' + сам.ф.основа_фикстуры + '\n')
        сам.отказ(сам.ф.предмет)

    def test_признак_неизменности_не_скрывает_состояние(сам):
        сам.ф.гит('update-index', '--assume-unchanged', 'корень.txt')
        сам.отказ(сам.ф.предмет)

    def test_признак_пропуска_рабочего_дерева_отклоняется(сам):
        сам.ф.гит('update-index', '--skip-worktree', 'корень.txt')
        сам.отказ(сам.ф.предмет)

    def test_рабочие_байты_защищённого_пути_не_подменяют_индекс(сам):
        (сам.ф.корень / 'корень.txt').write_text('Подмена после подготовки\n')
        сам.отказ(сам.ф.предмет)

    def test_вложенное_дерево_и_порядок_префиксов_равны_дереву_фикстуры(сам):
        for имя in ('а.файл', 'а/лист', 'а/вложение/ё', 'а0'):
            путь = сам.ф.корень / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_text(имя + '\n')
        сам.ф.гит('add', '.')
        сам.ф.закрепить_дерево()
        до = сам.ф.снимок()
        сам.assertEqual(сам.ф.дерево_фикстуры,
                       сам.допуск.сверить_индекс(сам.ф.корень, сам.ф.предмет)['дерево'])
        сам.assertEqual(до, сам.ф.снимок())

    def test_настоящие_конфликтные_стадии_отклоняются(сам):
        объект = сам.ф.гит('rev-parse', сам.ф.основа_фикстуры + ':корень.txt').strip()
        данные = '0 ' + '0' * 40 + '\tкорень.txt\n'
        данные += ''.join(f'100644 {объект} {стадия}\tкорень.txt\n' for стадия in (1, 2, 3))
        сам.ф.гит('update-index', '--index-info', вход=данные)
        сам.assertEqual(3, len(сам.ф.гит('ls-files', '--unmerged', 'корень.txt').splitlines()))
        сам.отказ(сам.ф.предмет)

    def test_чужие_биты_исполнения_не_меняют_режим_индекса(сам):
        (сам.ф.корень / 'корень.txt').chmod(0o641)
        до = сам.ф.снимок()
        сам.допуск.сверить_индекс(сам.ф.корень, сам.ф.предмет)
        сам.assertEqual(до, сам.ф.снимок())

    def test_режим_исполняемого_файла_читается(сам):
        (сам.ф.корень / 'корень.txt').chmod(0o755)
        сам.ф.гит('add', 'корень.txt')
        сам.ф.закрепить_дерево()
        до = сам.ф.снимок()
        результат = сам.допуск.сверить_индекс(сам.ф.корень, сам.ф.предмет)
        сам.assertEqual('100755', next(п['режим'] for п in результат['файлы'] if п['путь'] == 'корень.txt'))
        сам.assertEqual(до, сам.ф.снимок())

    def test_изменённый_бит_исполнения_владельца_отклоняется(сам):
        (сам.ф.корень / 'корень.txt').chmod(0o755)
        сам.отказ(сам.ф.предмет)

    def test_трассировка_не_пишет_при_успехе_и_отказе(сам):
        цели = [сам.ф.каталог / имя for имя in ('trace-normal', 'trace-event', 'trace-perf')]
        for ключ, цель in zip(('normalTarget', 'eventTarget', 'perfTarget'), цели):
            сам.ф.гит('config', 'trace2.' + ключ, str(цель))
        до = сам.ф.снимок()
        сам.допуск.сверить_индекс(сам.ф.корень, сам.ф.предмет)
        сам.отказ({**сам.ф.предмет, 'дерево': сам.ф.гит('rev-parse', сам.ф.основа_фикстуры + '^{tree}').strip()})
        сам.assertEqual(до, сам.ф.снимок())
        сам.assertTrue(all(not п.exists() for п in цели))

    def test_ранее_прочитанный_файл_проверяется_перед_возвратом(сам):
        читать = сам.допуск.обычные_байты
        первый = сам.ф.корень / 'корень.txt'
        изменён = False

        def чтение_с_подменой(путь, *аргументы, **параметры):
            nonlocal изменён
            if путь == сам.ф.корень / 'состояние.txt' and not изменён:
                изменён = True
                первый.write_text('Подмена после первого чтения\n')
            return читать(путь, *аргументы, **параметры)

        with patch.object(сам.допуск, 'обычные_байты', чтение_с_подменой):
            сам.отказ(сам.ф.предмет)

    def test_изменение_и_восстановление_байтов_отклоняется(сам):
        читать = сам.допуск.обычные_байты
        первый = сам.ф.корень / 'корень.txt'
        исходные = первый.read_bytes()
        изменён = False

        def чтение_с_возвратом(путь, *аргументы, **параметры):
            nonlocal изменён
            if путь == сам.ф.корень / 'состояние.txt' and not изменён:
                изменён = True
                первый.write_bytes(b'changed\n')
                первый.write_bytes(исходные)
            return читать(путь, *аргументы, **параметры)

        with patch.object(сам.допуск, 'обычные_байты', чтение_с_возвратом):
            сам.отказ(сам.ф.предмет)

    def test_символическая_ссылка_на_рабочий_файл_отклоняется(сам):
        путь = сам.ф.корень / 'корень.txt'
        копия = сам.ф.каталог / 'копия.txt'
        копия.write_bytes(путь.read_bytes())
        путь.unlink()
        путь.symlink_to(копия)
        сам.отказ(сам.ф.предмет)

    def test_родитель_прочитанного_файла_не_подменяется_ссылкой(сам):
        каталог = сам.ф.корень / 'а'
        каталог.mkdir()
        (каталог / 'лист').write_text('Вложенный файл\n')
        сам.ф.гит('add', 'а/лист')
        сам.ф.закрепить_дерево()
        читать = сам.допуск.обычные_байты
        изменён = False

        def чтение_с_подменой_родителя(путь, *аргументы, **параметры):
            nonlocal изменён
            if путь == сам.ф.корень / 'корень.txt' and not изменён:
                изменён = True
                перемещённый = сам.ф.каталог / 'перемещённый'
                каталог.rename(перемещённый)
                каталог.symlink_to(перемещённый, target_is_directory=True)
            return читать(путь, *аргументы, **параметры)

        with patch.object(сам.допуск, 'обычные_байты', чтение_с_подменой_родителя):
            сам.отказ(сам.ф.предмет)

    def test_жёсткая_ссылка_на_рабочий_файл_отклоняется(сам):
        os.link(сам.ф.корень / 'корень.txt', сам.ф.каталог / 'вторая-ссылка.txt')
        сам.отказ(сам.ф.предмет)

    def test_среда_не_перенаправляет_пишущую_фикстуру(сам):
        перенаправление = сам.ф.каталог / 'чужой-git'
        перенаправление.mkdir()
        индекс = сам.ф.каталог / 'чужой-индекс'
        индекс.write_bytes(b'guard-index\n')
        объекты = сам.ф.каталог / 'чужие-объекты'
        объекты.mkdir()
        среда = {'GIT_DIR': str(перенаправление), 'GIT_INDEX_FILE': str(индекс),
                 'GIT_OBJECT_DIRECTORY': str(объекты), 'GIT_CONFIG_COUNT': '1',
                 'GIT_CONFIG_KEY_0': 'core.worktree', 'GIT_CONFIG_VALUE_0': str(перенаправление)}
        with patch.dict(os.environ, среда):
            фикстура = ФикстураБазиса()
            try:
                сам.assertEqual(str(фикстура.корень / '.git'), фикстура.гит('rev-parse', '--absolute-git-dir').strip())
                сам.допуск.сверить_индекс(фикстура.корень, фикстура.предмет)
            finally:
                фикстура.закрыть()
        сам.assertEqual(b'guard-index\n', индекс.read_bytes())
        сам.assertEqual([], list(перенаправление.iterdir()))
        сам.assertEqual([], list(объекты.iterdir()))

    def конечный_отказ_канала(сам, имя, гонка=False):
        путь = сам.ф.корень / имя
        исходные = путь.read_bytes()
        режим = путь.stat().st_mode & 0o777
        до = сам.ф.снимок()
        код = '''import importlib.util,json,os,stat,sys
from pathlib import Path
описание=importlib.util.spec_from_file_location('допуск_канала',sys.argv[1])
модуль=importlib.util.module_from_spec(описание)
описание.loader.exec_module(модуль)
корень=Path(sys.argv[2]);предмет=json.loads(sys.argv[3]);проверяемый=Path(sys.argv[4])
if sys.argv[5]=='гонка':
 первичное=модуль.os.open
 подменён=False
 def подменить_после_сверки(путь,*аргументы,**параметры):
  global подменён
  if Path(путь)==проверяемый and not подменён:
   подменён=True
   проверяемый.unlink()
   os.mkfifo(проверяемый)
  return первичное(путь,*аргументы,**параметры)
 модуль.os.open=подменить_после_сверки
try:модуль.сверить_индекс(корень,предмет)
except (ValueError,OSError):
 assert stat.S_ISFIFO(проверяемый.lstat().st_mode), 'Канал не установлен'
 assert sys.argv[5]!='гонка' or подменён, 'Гонка не выполнена'
 print(json.dumps({'отказ':True,'канал':True,'подмена':sys.argv[5]=='гонка'},ensure_ascii=False))
else:raise SystemExit('Канал принят вместо обычного файла')
'''
        try:
            if not гонка:
                путь.unlink()
                os.mkfifo(путь)
            среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
            with subprocess.Popen([sys.executable, '-I', '-S', '-B', '-c', код,
                    str(ДОПУСК), str(сам.ф.корень), json.dumps(сам.ф.предмет), str(путь),
                    'гонка' if гонка else 'обычный'], env=среда,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True) as процесс:
                try:
                    вывод, ошибки = процесс.communicate(timeout=2)
                except subprocess.TimeoutExpired:
                    try:
                        os.killpg(процесс.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    процесс.communicate()
                    сам.fail('Читающий процесс завис на именованном канале; внешний deadline 2 с')
                сам.assertEqual(0, процесс.returncode, ошибки.decode())
                сам.assertEqual({'отказ': True, 'канал': True, 'подмена': гонка}, json.loads(вывод))
        finally:
            путь.unlink()
            путь.write_bytes(исходные)
            путь.chmod(режим)
        сам.assertEqual(до, сам.ф.снимок())

    def test_канал_вместо_индекса_отклоняется_конечно(сам):
        сам.конечный_отказ_канала('.git/index')

    def test_канал_вместо_родителя_слияния_отклоняется_конечно(сам):
        сам.конечный_отказ_канала('.git/MERGE_HEAD')

    def test_канал_вместо_рабочего_файла_отклоняется_конечно(сам):
        сам.конечный_отказ_канала('корень.txt')

    def test_подмена_на_канал_после_сверки_пути_отклоняется_конечно(сам):
        сам.конечный_отказ_канала('корень.txt', гонка=True)


class ОбъектыБазиса(unittest.TestCase):
    def test_неполный_двухадресный_ответ_гита_закрывает_допуск(сам):
        ф = ФикстураБазиса()
        сам.addCleanup(ф.закрыть)
        допуск = загрузить_допуск()
        адрес = str(ф.корень / '.git').encode()
        for ответ in (адрес, адрес + b'\n', адрес + b'\n\n'):
            with сам.subTest(ответ=ответ):
                до = ф.снимок()
                with patch.object(допуск, 'гит', return_value=ответ):
                    with сам.assertRaises(ValueError):
                        допуск.собственная_гит_база(ф.корень)
                сам.assertEqual(до, ф.снимок())

    def setUp(сам):
        сам.ф = ФикстураБазиса()
        сам.addCleanup(сам.ф.закрыть)
        сам.допуск = загрузить_допуск()

    def test_все_объекты_точного_дерева_перечитываются_без_эффекта(сам):
        до = сам.ф.снимок()
        итог = сам.допуск.сверить_объекты_дерева(сам.ф.корень, сам.ф.дерево_фикстуры)
        ожидаемые = {сам.ф.дерево_фикстуры,
                      *(строка.split()[2] for строка in сам.ф.гит('ls-tree', '-r', сам.ф.дерево_фикстуры).splitlines())}
        сам.assertEqual(ожидаемые, set(итог))
        сам.assertTrue(all(set(объект) == {'тип', 'размер', 'sha256'} for объект in итог.values()))
        сам.assertEqual(до, сам.ф.снимок())

    def test_рассчитанный_индекс_не_скрывает_отсутствующий_объект_листа(сам):
        лист = сам.ф.гит('rev-parse', сам.ф.дерево_фикстуры + ':состояние.txt').strip()
        путь = сам.ф.корень / '.git/objects' / лист[:2] / лист[2:]
        сам.assertTrue(путь.is_file())
        путь.unlink()  # Только собственная независимая фикстура.
        до = сам.ф.снимок()
        with сам.assertRaises(ValueError):
            сам.допуск.сверить_объекты_дерева(сам.ф.корень, сам.ф.дерево_фикстуры)
        сам.assertEqual(до, сам.ф.снимок())

    def test_отсутствующее_вложенное_дерево_отклоняется_без_материализации(сам):
        вложение = сам.ф.корень / 'вложение'
        вложение.mkdir()
        (вложение / 'лист.txt').write_text('Самостоятельное поддерево\n')
        сам.ф.гит('add', 'вложение')
        сам.ф.закрепить_дерево()
        объект = сам.ф.гит('rev-parse', сам.ф.дерево_фикстуры + ':вложение').strip()
        (сам.ф.корень / '.git/objects' / объект[:2] / объект[2:]).unlink()
        до = сам.ф.снимок()
        with сам.assertRaises(ValueError):
            сам.допуск.сверить_объекты_дерева(сам.ф.корень, сам.ф.дерево_фикстуры)
        сам.assertEqual(до, сам.ф.снимок())

    def test_внешнее_хранилище_не_становится_собственной_базой(сам):
        адрес = сам.ф.корень / '.git/objects/info/alternates'
        адрес.write_text(str(сам.ф.каталог / 'чужая-область') + '\n')
        до = сам.ф.снимок()
        with сам.assertRaises(ValueError):
            сам.допуск.сверить_объекты_дерева(сам.ф.корень, сам.ф.дерево_фикстуры)
        сам.assertEqual(до, сам.ф.снимок())

    def test_связанное_рабочее_дерево_не_получает_допуск_эффекта_общей_базы(сам):
        адрес = сам.ф.каталог / 'linked'
        сам.ф.гит('worktree', 'add', '-q', '-b', 'отдельный-ref', str(адрес), сам.ф.основа_фикстуры)
        до = сам.ф.снимок()
        with сам.assertRaises(ValueError):
            сам.допуск.сверить_объекты_дерева(адрес, сам.ф.дерево_фикстуры)
        сам.assertEqual(до, сам.ф.снимок())


def загрузить_создатель():
    путь = ДОПУСК.with_name('создание_базиса_узла.py')
    описание = importlib.util.spec_from_file_location('создатель_базиса_фикстуры', путь)
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = модуль
    данные = путь.read_bytes()
    модуль.УДЕРЖАННЫЙ_БУФЕР_СОЗДАТЕЛЯ = данные
    модуль.ПУТЬ_ЗАКРЕПЛЁННОГО_ГИТА = str(Path(shutil.which('git')).resolve())
    модуль.УДЕРЖАННЫЙ_БУФЕР_ДОПУСКА = ДОПУСК.read_bytes()
    модуль.ХЭШ_УДЕРЖАННОГО_ДОПУСКА = hashlib.sha256(модуль.УДЕРЖАННЫЙ_БУФЕР_ДОПУСКА).hexdigest()
    exec(compile(данные, str(путь), 'exec', dont_inherit=True), модуль.__dict__)
    return модуль


class СыройКоммитБазиса(unittest.TestCase):
    def setUp(сам):
        сам.ф = ФикстураБазиса()
        сам.addCleanup(сам.ф.закрыть)
        сам.сообщение = 'Проверяемый базис фикстуры\n'
        файл = сам.ф.каталог / 'сообщение.txt'
        файл.write_text(сам.сообщение)
        сам.ф.гит('commit', '--cleanup=verbatim', '--file', str(файл))
        сам.объект = сам.ф.гит('rev-parse', 'HEAD').strip()
        сам.создатель = загрузить_создатель()

    def test_объект_возвращает_ровно_шесть_сырых_полей(сам):
        результат = сам.создатель.прочитать_сырой_коммит(сам.ф.корень, сам.объект)
        сам.assertEqual({'коммит', 'дерево', 'родители', 'автор', 'коммиттер',
                         'сообщение_sha256'}, set(результат))
        сам.assertEqual(сам.объект, результат['коммит'])
        сам.assertEqual(сам.ф.дерево_фикстуры, результат['дерево'])
        сам.assertEqual(сам.ф.предмет['родители'], результат['родители'])
        сам.assertTrue(результат['автор'].startswith('Открытая фикстура <fixture@example.invalid> '))
        сам.assertTrue(результат['коммиттер'].startswith('Открытая фикстура <fixture@example.invalid> '))
        сам.assertEqual(hashlib.sha256(сам.сообщение.encode()).hexdigest(), результат['сообщение_sha256'])

    def test_подмена_любого_поля_ожидания_закрывает_квитанцию(сам):
        исходный = сам.создатель.прочитать_сырой_коммит(сам.ф.корень, сам.объект)
        до = tuple(sorted((п.relative_to(сам.ф.корень).as_posix(), п.stat().st_mode,
                           п.stat().st_mtime_ns, п.stat().st_ino, hashlib.sha256(п.read_bytes()).hexdigest())
                          for п in сам.ф.корень.rglob('*') if п.is_file()))
        замены = {'коммит': сам.ф.основа_фикстуры, 'дерево': '0' * 40,
                   'родители': list(reversed(исходный['родители'])),
                   'автор': исходный['автор'] + 'подмена', 'коммиттер': исходный['коммиттер'] + 'подмена',
                   'сообщение_sha256': '0' * 64}
        for поле, значение in замены.items():
            with сам.subTest(поле=поле), сам.assertRaises(ValueError):
                сам.создатель.сверить_сырой_коммит(сам.ф.корень, сам.объект, {**исходный, поле: значение})
        после = tuple(sorted((п.relative_to(сам.ф.корень).as_posix(), п.stat().st_mode,
                              п.stat().st_mtime_ns, п.stat().st_ino, hashlib.sha256(п.read_bytes()).hexdigest())
                             for п in сам.ф.корень.rglob('*') if п.is_file()))
        сам.assertEqual(до, после)


def байты_описания(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()


def закрытое_описание(данные):
    def неповторные(пары):
        итог = {}
        for ключ, значение in пары:
            if ключ in итог:
                raise ValueError('Повторное поле выбранного описания')
            итог[ключ] = значение
        return итог
    return json.loads(данные, object_pairs_hook=неповторные,
        parse_constant=lambda значение: (_ for _ in ()).throw(ValueError('Нефинитное число')))


def частный_вход_поставки(путь, ожидаемый):
    путь = Path(путь)
    assert путь.is_absolute() and путь == путь.resolve()
    assert not any(п.is_symlink() for п in (путь, *путь.parents))
    assert not any((п / '.git').exists() for п in путь.parents)
    сведения = путь.lstat()
    assert stat.S_ISREG(сведения.st_mode) and сведения.st_nlink == 1
    assert сведения.st_uid == os.getuid() and stat.S_IMODE(сведения.st_mode) == 0o600
    дескриптор = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(дескриптор, 'rb') as поток:
        открытые = os.fstat(поток.fileno())
        assert stat.S_ISREG(открытые.st_mode) and открытые.st_nlink == 1
        assert (открытые.st_uid, открытые.st_dev, открытые.st_ino, открытые.st_mode) == (
            сведения.st_uid, сведения.st_dev, сведения.st_ino, сведения.st_mode)
        данные = поток.read()
    assert hashlib.sha256(данные).hexdigest() == ожидаемый
    return закрытое_описание(данные)


def загрузить_создатель_из_закреплённого_кода(выбор):
    assert set(выбор['M']) == {'корень', 'коммит', 'путь', 'sha256'}
    assert set(выбор['runtime']) == {'python', 'git', 'ps'}
    for сведения in выбор['runtime'].values():
        assert set(сведения) == {'путь', 'sha256'}
        путь = Path(сведения['путь'])
        assert путь.is_absolute() and путь == путь.resolve()
        assert not any(п.is_symlink() for п in (путь, *путь.parents))
        assert hashlib.sha256(путь.read_bytes()).hexdigest() == сведения['sha256']
    assert str(Path(sys.executable).resolve()) == выбор['runtime']['python']['путь']
    assert str(Path(shutil.which('git')).resolve()) == выбор['runtime']['git']['путь']
    корень = Path(выбор['M']['корень'])
    assert корень.is_absolute() and корень.resolve() == корень
    среда = {к: в for к, в in os.environ.items() if not к.startswith(('GIT_', 'PYTHON'))}
    среда.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull, GIT_NO_REPLACE_OBJECTS='1', GIT_NO_LAZY_FETCH='1')
    def блоб(имя):
        return subprocess.check_output([выбор['runtime']['git']['путь'], '--no-optional-locks', '--no-replace-objects',
            '-c', 'core.hooksPath=' + os.devnull, '-c', 'core.fsmonitor=false', '-c', 'gc.auto=0',
            '-c', 'maintenance.auto=false', '-c', 'trace2.normalTarget=0', '-c', 'trace2.eventTarget=0',
            '-c', 'trace2.perfTarget=0', '-c', 'protocol.allow=never', '-C', str(корень),
            'cat-file', 'blob', выбор['M']['коммит'] + ':' + имя], env=среда, stderr=subprocess.PIPE)
    манифест = блоб(выбор['M']['путь'])
    assert hashlib.sha256(манифест).hexdigest() == выбор['M']['sha256']
    контур = закрытое_описание(манифест)
    assert type(контур) is dict and set(контур) == {'схема', 'контракты'}
    assert контур['схема'] == 'fum.фикстурный-контур-базиса.1'
    assert type(контур['контракты']) is list and контур['контракты']
    буферы = {}
    for запись in контур['контракты']:
        assert type(запись) is dict and set(запись) == {'путь', 'sha256'}
        имя = запись['путь']
        assert type(имя) is str and имя.endswith('.py') and not Path(имя).is_absolute()
        assert all(ч not in ('', '.', '..', '.git') for ч in имя.split('/'))
        assert '\\' not in имя and all(ord(з) >= 32 and ord(з) != 127 for з in имя)
        assert unicodedata.normalize('NFC', имя) == имя and имя not in буферы
        assert type(запись['sha256']) is str and re.fullmatch('[0-9a-f]{64}', запись['sha256'])
        путь = корень / запись['путь']
        assert путь.resolve() == путь and путь.is_relative_to(корень)
        данные = блоб(запись['путь'])
        assert hashlib.sha256(данные).hexdigest() == запись['sha256'] and путь.read_bytes() == данные
        буферы[запись['путь']] = данные
    путь = ДОПУСК.with_name('создание_базиса_узла.py').relative_to(КОРЕНЬ).as_posix()
    модуль = types.ModuleType('независимый_потребитель_сырых_полей_P')
    модуль.__file__ = str(корень / путь)
    модуль.УДЕРЖАННЫЙ_БУФЕР_СОЗДАТЕЛЯ = буферы[путь]
    модуль.ПУТЬ_ЗАКРЕПЛЁННОГО_ГИТА = выбор['runtime']['git']['путь']
    модуль.УДЕРЖАННЫЙ_БУФЕР_ДОПУСКА = буферы[ДОПУСК.relative_to(КОРЕНЬ).as_posix()]
    модуль.ХЭШ_УДЕРЖАННОГО_ДОПУСКА = hashlib.sha256(модуль.УДЕРЖАННЫЙ_БУФЕР_ДОПУСКА).hexdigest()
    exec(compile(буферы[путь], модуль.__file__, 'exec', dont_inherit=True), модуль.__dict__)
    return модуль


def проверить_фикстурную_поставку(путь, ожидаемый):
    выбор = частный_вход_поставки(путь, ожидаемый)
    assert set(выбор) == {'схема', 'M', 'runtime', 'приёмник', 'ветка', 'ожидание'}
    assert выбор['схема'] == 'fum.выбор-фикстурной-поставки-базиса.1'
    модуль = загрузить_создатель_из_закреплённого_кода(выбор)
    приёмник = модуль.допуск.физический_корень(выбор['приёмник'])
    модуль.допуск.собственная_гит_база(приёмник)
    строка = модуль.допуск.гит(приёмник, '-c', 'protocol.file.allow=always',
                              'ls-remote', str(приёмник), выбор['ветка'])
    assert строка == (выбор['ожидание']['коммит'] + '\t' + выбор['ветка'] + '\n').encode()
    результат = модуль.сверить_сырой_коммит(приёмник, выбор['ожидание']['коммит'], выбор['ожидание'])
    assert строка == модуль.допуск.гит(приёмник, '-c', 'protocol.file.allow=always',
                                     'ls-remote', str(приёмник), выбор['ветка'])
    return {'схема': 'fum.проверенная-фикстурная-поставка-базиса.1', 'подтверждена': True,
            'ветка': выбор['ветка'], 'результат': результат}


class ФикстураПолногоБазиса:
    """Независимый fixture issuer; его выбор не является Desktop-полномочием."""
    def __init__(сам, преобразование=None, исходные_буферы=None):
        сам.преобразование = преобразование
        сам.исходные_буферы = исходные_буферы
        сам.ф = ФикстураБазиса()
        try:
            сам.подготовить()
        except BaseException:
            сам.ф.закрыть()
            raise

    def подготовить(сам):
        сам.каталог = сам.ф.каталог
        сам.корень = сам.ф.корень
        сам.код = сам.каталог / 'принятый-код'
        сам.отчёт = сам.каталог / 'отдельный-отчёт'
        сам.частное = сам.каталог / 'частное'
        сам.частное.mkdir(mode=0o700)
        for база in (сам.код, сам.отчёт):
            база.mkdir()
            сам.гит(база, 'init', '-q', '-b', 'основание')
            сам.гит(база, 'config', 'user.name', 'Независимый fixture issuer')
            сам.гит(база, 'config', 'user.email', 'issuer@example.invalid')
        пути = [ДОПУСК, ДОПУСК.with_name('создание_базиса_узла.py'), Path(__file__),
                 КОРЕНЬ / 'Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py']
        if сам.исходные_буферы is not None:
            пути = [КОРЕНЬ / п for п in сам.исходные_буферы]
        сам.контракты = []
        for источник in пути:
            относительный = источник.relative_to(КОРЕНЬ).as_posix()
            цель = сам.код / относительный
            цель.parent.mkdir(parents=True, exist_ok=True)
            данные = (источник.read_bytes() if сам.исходные_буферы is None
                      else сам.исходные_буферы[относительный])
            if сам.преобразование is not None and источник == ДОПУСК.with_name('создание_базиса_узла.py'):
                данные = сам.преобразование(данные, сам)
            цель.write_bytes(данные)
            сам.контракты.append({'путь': относительный, 'sha256': hashlib.sha256(данные).hexdigest()})
        сам.сохранить(сам.код / 'контур.json', {'схема': 'fum.фикстурный-контур-базиса.1',
                                              'контракты': сам.контракты})
        сам.гит(сам.код, 'add', '.')
        сам.гит(сам.код, 'commit', '-qm', 'Независимо выбрать код фикстуры M')
        сам.источник_кода = сам.селектор(сам.код, 'контур.json')
        сам.журнал = 'Журнал/2026-10-14_12-05-56_MSK_проверить-фикстуру-базиса/'
        сам.запрос = сам.журнал + 'запрос.md'
        папка = сам.отчёт / сам.журнал
        папка.mkdir(parents=True)
        (папка / 'запрос.md').write_text('Открытый контролируемый REPORT, не сообщение человека.\n')
        (папка / 'отчёт.md').write_text('# Отчёт фикстуры\n\n'
            '<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->\n'
            '<!-- FUM-CHECK-RUNS:END -->\n')
        сам.номер = str(uuid.uuid4())
        сам.исполнитель = str(uuid.uuid4())
        сам.поколение = str(uuid.uuid4())
        сам.нативный_срез = сам.частное / 'нативная-фикстура.jsonl'
        нативный_срез = {'type': 'session_meta', 'payload': {'id': сам.исполнитель,
                  'cwd': str(сам.корень), 'source': 'контролируемая-фикстура',
                  'координатор': '01a07d3d-d376-7ad2-aafc-67e4c25a67eb', 'поколение': сам.поколение}}
        сам.нативный_срез.write_bytes((json.dumps(нативный_срез, ensure_ascii=False) + '\n').encode())
        сам.нативный_срез.chmod(0o600)
        сведения = сам.корень.stat()
        сам.адрес = {'корень': str(сам.корень), 'ветка': 'refs/heads/основа',
            'git_dir': str(сам.корень / '.git'), 'common_dir': str(сам.корень / '.git'),
            'ODB': str(сам.корень / '.git/objects'), 'uid': os.getuid(),
            'устройство': сведения.st_dev, 'inode': сведения.st_ino,
            'HEAD_sha256': hashlib.sha256((сам.корень / '.git/HEAD').read_bytes()).hexdigest(),
            'ref_sha256': hashlib.sha256((сам.корень / '.git/refs/heads/основа').read_bytes()).hexdigest()}
        база = сам.корень / '.git'
        сам.адрес['git_каталоги'] = {}
        for имя in ('', 'objects', 'refs', 'refs/heads', 'logs', 'logs/refs', 'logs/refs/heads'):
            сведения_каталога = (база / имя).stat()
            сам.адрес['git_каталоги'][имя] = [сведения_каталога.st_uid, сведения_каталога.st_dev,
                сведения_каталога.st_ino, сведения_каталога.st_mode]
        сам.адрес['config_sha256'] = hashlib.sha256((база / 'config').read_bytes()).hexdigest()
        сам.адрес['прочие_refs'] = {п.relative_to(база).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest()
            for п in (база / 'refs').rglob('*') if п.is_file()
            and п.relative_to(база).as_posix() != сам.адрес['ветка']}
        сам.адрес['исходные_объекты'] = {п.relative_to(база).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest()
            for п in (база / 'objects').rglob('*') if п.is_file()}
        замок = сам.частное / 'замок-предмета'
        замок.write_bytes(b'')
        замок.chmod(0o600)
        сведения_замка = замок.stat()
        сам.адрес['замок'] = {'путь': str(замок), 'uid': сведения_замка.st_uid,
            'устройство': сведения_замка.st_dev, 'inode': сведения_замка.st_ino,
            'sha256': hashlib.sha256(b'').hexdigest()}
        сам.защита = []
        for строка in сам.ф.гит('ls-files', '--stage', '-z').split('\0')[:-1]:
            поля, путь = строка.split('\t', 1)
            режим, объект, _ = поля.split()
            сам.защита.append({'путь': путь, 'режим': режим, 'объект': объект,
                               'sha256': hashlib.sha256((сам.корень / путь).read_bytes()).hexdigest()})
        привязки_назначения = {'M': сам.источник_кода, 'предмет': сам.ф.предмет, 'адрес': сам.адрес,
            'исполнитель': сам.исполнитель, 'координатор': '01a07d3d-d376-7ad2-aafc-67e4c25a67eb',
            'поколение': сам.поколение,
            'нативный_срез': {'путь': str(сам.нативный_срез), 'sha256': hashlib.sha256(сам.нативный_срез.read_bytes()).hexdigest()},
            'защищённые_продукты': сам.защита}
        сам.сохранить(сам.отчёт / 'C0.json', {'схема': 'fum.фикстурное-поручение-базиса.1', **привязки_назначения})
        сам.сохранить(сам.отчёт / 'ACT_B.json', {'схема': 'fum.фикстурный-ACT-базиса.1', **привязки_назначения})
        сам.сохранить(сам.отчёт / 'решение.json', {'схема': 'fum.фикстурное-решение-базиса.1',
                                               'предмет': сам.ф.предмет, 'защита': сам.защита})
        (сам.отчёт / 'шаблон.txt').write_text('Проверяемый базис фикстуры\n\nD: {{OID_D}}\n')
        сам.гит(сам.отчёт, 'add', '.')
        сам.гит(сам.отчёт, 'commit', '-qm', 'Независимо выбрать C0 и ACT_B вне предмета')
        сам.выбор = {'схема': 'fum.выбор-фикстурного-базиса.1', 'режим': 'изолированная-фикстура',
            **привязки_назначения, 'C0': сам.селектор(сам.отчёт, 'C0.json'),
            'ACT_B': сам.селектор(сам.отчёт, 'ACT_B.json'),
            'решения_корня': [сам.селектор(сам.отчёт, 'решение.json')],
            'проверка': {'корень': str(сам.отчёт), 'запрос': сам.запрос,
                         'идентификатор': сам.номер, 'тайм_аут': 15},
            'частный_каталог': str(сам.частное),
            'идентичность': {'автор': 'Открытая фикстура <fixture@example.invalid> 1791960000 +0000',
                            'коммиттер': 'Открытая фикстура <fixture@example.invalid> 1791960000 +0000'},
            'runtime': {имя: {'путь': str(Path(путь).resolve()),
                              'sha256': hashlib.sha256(Path(путь).resolve().read_bytes()).hexdigest()}
                        for имя, путь in [('python', sys.executable), ('git', shutil.which('git')),
                                          ('ps', shutil.which('ps', path=os.defpath))]}}
        сам.выбор_путь = сам.частное / 'выбор-корня.json'
        сам.выбор_хэш = сам.сохранить(сам.выбор_путь, сам.выбор)
        сам.вход = сам.частное / 'вход.json'
        сам.вход_хэш = сам.сохранить(сам.вход, {'схема': 'fum.создание-базиса-узла.1',
                          'выбор_sha256': сам.выбор_хэш, 'предмет': сам.ф.предмет})

    def сохранить(сам, путь, значение):
        данные = байты_описания(значение)
        путь.write_bytes(данные)
        путь.chmod(0o600 if путь.is_relative_to(сам.частное) else 0o644)
        return hashlib.sha256(данные).hexdigest()

    def гит(сам, корень, *аргументы, текст=True):
        среда = {к: в for к, в in os.environ.items() if not к.startswith(('GIT_', 'PYTHON'))}
        среда.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull)
        return subprocess.check_output(['git', '--no-optional-locks', '-c', 'core.hooksPath=' + os.devnull,
            '-c', 'core.fsmonitor=false', '-c', 'commit.gpgSign=false', '-c', 'gc.auto=0',
            '-c', 'maintenance.auto=false', '-c', 'trace2.normalTarget=0',
            '-c', 'trace2.eventTarget=0', '-c', 'trace2.perfTarget=0',
            '-c', 'protocol.allow=never', '-C', str(корень), *аргументы],
            env=среда, text=текст, stderr=subprocess.PIPE)

    def селектор(сам, корень, путь):
        объект = сам.гит(корень, 'rev-parse', 'HEAD').strip()
        сырое = сам.гит(корень, 'cat-file', 'blob', объект + ':' + путь, текст=False)
        return {'корень': str(корень), 'коммит': объект, 'путь': путь,
                'sha256': hashlib.sha256(сырое).hexdigest()}

    def аргументы_режима(сам, действие, *дополнительно, профиль=None):
        входной_код = сам.код / ДОПУСК.with_name('создание_базиса_узла.py').relative_to(КОРЕНЬ)
        относительный = входной_код.relative_to(сам.код).as_posix()
        закреплённые = сам.гит(сам.код, 'cat-file', 'blob', сам.источник_кода['коммит'] + ':' + относительный, текст=False)
        ожидаемый = next(з['sha256'] for з in сам.контракты if з['путь'] == относительный)
        assert hashlib.sha256(закреплённые).hexdigest() == ожидаемый
        узлы = [у.value for у in ast.parse(закреплённые).body if isinstance(у, ast.Assign)
                and any(isinstance(ц, ast.Name) and ц.id == 'БУФЕР_ДОВЕРЕННОГО_ЗАПУСКА' for ц in у.targets)]
        assert len(узлы) == 1
        запуск = ast.literal_eval(узлы[0])
        if профиль is not None:
            # cProfile — явная диагностика только этого CLI, не вложенного stock child.
            точка = 'exec(compile(данные, путь, "exec", dont_inherit=True),\n     {"__name__": "__main__", "__file__": путь, "__builtins__": __builtins__,\n      "УДЕРЖАННЫЙ_БУФЕР_СОЗДАТЕЛЯ": данные})\n'
            assert запуск.count(точка) == 1
            запуск = ('import cProfile, marshal\n' + запуск.replace(точка,
                'измеритель = cProfile.Profile()\nизмеритель.enable()\ntry:\n    '
                + точка.replace('\n', '\n    ').rstrip() + '\nfinally:\n'
                '    измеритель.disable()\n    измеритель.dump_stats(' + repr(str(профиль)) + ')\n'))
        return [sys.executable, '-I', '-S', '-B', '-c', запуск,
            str(входной_код), ожидаемый, действие,
            '--выбор', str(сам.выбор_путь), '--выбор-sha256', сам.выбор_хэш,
            '--вход', str(сам.вход), '--вход-sha256', сам.вход_хэш, *дополнительно]

    def команда(сам, действие, *дополнительно, профиль=None):
        среда = {к: в for к, в in os.environ.items() if not к.startswith(('GIT_', 'PYTHON'))}
        return subprocess.run(сам.аргументы_режима(действие, *дополнительно, профиль=профиль),
            cwd=сам.отчёт, env=среда, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=35, start_new_session=True)

    def закрепить_допуск(сам):
        for имя in ('типизированное.json', 'процесс-проверки.json'):
            цель = сам.отчёт / сам.журнал / 'материалы' / имя
            цель.parent.mkdir(parents=True, exist_ok=True)
            цель.write_bytes((сам.частное / имя).read_bytes())
        запись = next((сам.отчёт / сам.журнал / 'материалы/запуски-проверок').glob('1_*.json'))
        свидетельства = {'v4': {'путь': запись.relative_to(сам.отчёт).as_posix(),
                         'sha256': hashlib.sha256(запись.read_bytes()).hexdigest()}}
        for ключ, имя in [('typed', 'типизированное.json'), ('rawprocess', 'процесс-проверки.json')]:
            путь = сам.журнал + 'материалы/' + имя
            свидетельства[ключ] = {'путь': путь, 'sha256': hashlib.sha256((сам.отчёт / путь).read_bytes()).hexdigest()}
        отчётный_допуск = {'схема': 'fum.допуск-создания-базиса-узла.1', 'выбор_sha256': сам.выбор_хэш,
             'предмет': сам.ф.предмет, 'решения_корня': сам.выбор['решения_корня'],
             'защищённые_продукты': сам.защита,
             'проверка': {'идентификатор': сам.номер, **свидетельства},
             'шаблон_сообщения': {'путь': 'шаблон.txt',
                 'sha256': hashlib.sha256((сам.отчёт / 'шаблон.txt').read_bytes()).hexdigest()}}
        сам.сохранить(сам.отчёт / 'D.json', отчётный_допуск)
        сам.гит(сам.отчёт, 'add', '.')
        сам.гит(сам.отчёт, 'commit', '-qm', 'Независимый fixture issuer принимает D вне T')
        сам.отчётный_допуск = сам.селектор(сам.отчёт, 'D.json')
        сам.выбор_допуска = сам.частное / 'выбор-D.json'
        сам.выбор_допуска_хэш = сам.сохранить(сам.выбор_допуска, {'схема': 'fum.выбор-допуска-базиса.1',
                            'выбор_sha256': сам.выбор_хэш, 'D': сам.отчётный_допуск})

    def закрепить_поставку(сам):
        assert сам.гит(сам.отчёт, 'status', '--porcelain=v1', '--untracked-files=all') == '', 'REPORT содержит чужой delta до P'
        основание_поставки = сам.гит(сам.отчёт, 'rev-parse', 'HEAD').strip()
        выбор_кода = {'M': сам.источник_кода, 'runtime': сам.выбор['runtime']}
        читатель = загрузить_создатель_из_закреплённого_кода(выбор_кода)
        объект = сам.ф.гит('rev-parse', 'HEAD').strip()
        ожидание = читатель.прочитать_сырой_коммит(сам.корень, объект)
        приёмник = сам.каталог / 'приёмник-поставки'
        приёмник.mkdir()
        сам.гит(приёмник, 'init', '-q', '-b', 'приёмник')
        ветка = 'refs/heads/поставка-базиса'
        до = сам.снимок(сам.корень)
        сам.гит(сам.корень, '-c', 'protocol.file.allow=always', 'push', '--no-follow-tags',
                str(приёмник), объект + ':' + ветка)
        assert до == сам.снимок(сам.корень), 'Отдельная P-поставка изменила исходную базу B'
        выбор = {'схема': 'fum.выбор-фикстурной-поставки-базиса.1', **выбор_кода,
                 'приёмник': str(приёмник), 'ветка': ветка, 'ожидание': ожидание}
        путь = сам.частное / 'выбор-P.json'
        ожидаемый = сам.сохранить(путь, выбор)
        # Верификатор — отдельный процесс из exact test/issuer Git-буфера M, входом служит независимый raw6.
        основной_путь = ДОПУСК.with_name('создание_базиса_узла.py').relative_to(КОРЕНЬ).as_posix()
        данные = сам.гит(сам.код, 'cat-file', 'blob', сам.источник_кода['коммит'] + ':' + основной_путь, текст=False)
        узел = next(у.value for у in ast.parse(данные).body if isinstance(у, ast.Assign)
            and any(isinstance(ц, ast.Name) and ц.id == 'БУФЕР_ДОВЕРЕННОГО_ЗАПУСКА' for ц in у.targets))
        тестовый_путь = Path(__file__).relative_to(КОРЕНЬ).as_posix()
        закреплённый = next(з['sha256'] for з in сам.контракты if з['путь'] == тестовый_путь)
        среда = {к: в for к, в in os.environ.items() if not к.startswith(('GIT_', 'PYTHON'))}
        сам.аргументы_поставки = [sys.executable, '-I', '-S', '-B', '-c', ast.literal_eval(узел),
            str(сам.код / тестовый_путь), закреплённый, '--проверить-фикстурную-поставку', str(путь), ожидаемый]
        проверка = subprocess.run(сам.аргументы_поставки,
            env=среда, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
        assert проверка.returncode == 0, проверка.stderr.decode()
        поставка = json.loads(проверка.stdout)
        assert поставка['результат'] == ожидание and поставка['подтверждена'] is True
        сам.сохранить(сам.отчёт / 'P.json', {**поставка, 'D': сам.отчётный_допуск,
            'проверка_sha256': hashlib.sha256(проверка.stdout).hexdigest()})
        исходный_допуск = сам.гит(сам.отчёт, 'cat-file', 'blob', сам.отчётный_допуск['коммит'] + ':D.json', текст=False)
        сам.гит(сам.отчёт, 'add', 'P.json')
        assert сам.гит(сам.отчёт, 'diff', '--cached', '--name-status', '-z') == 'A\x00P.json\x00'
        сам.гит(сам.отчёт, 'commit', '-qm', 'Независимо подтвердить фикстурную поставку P после B')
        assert сам.гит(сам.отчёт, 'diff', '--name-status', '-z', основание_поставки, 'HEAD') == 'A\x00P.json\x00'
        assert исходный_допуск == сам.гит(сам.отчёт, 'cat-file', 'blob', 'HEAD:D.json', текст=False)
        return поставка

    def закрыть(сам):
        сам.ф.закрыть()

    def снимок(сам, корень=None):
        корень = сам.каталог if корень is None else корень
        итог = []
        for путь in (корень, *корень.rglob('*')):
            сведения = путь.lstat()
            содержимое = (os.readlink(путь) if stat.S_ISLNK(сведения.st_mode) else
                hashlib.sha256(путь.read_bytes()).hexdigest() if stat.S_ISREG(сведения.st_mode) else None)
            итог.append((путь.relative_to(корень).as_posix(), сведения.st_mode,
                сведения.st_uid, сведения.st_dev, сведения.st_ino, сведения.st_nlink,
                сведения.st_mtime_ns, содержимое))
        return tuple(sorted(итог))

    def аргументы_допуска(сам):
        return ('--выбор-D', str(сам.выбор_допуска), '--выбор-D-sha256', сам.выбор_допуска_хэш)

    def подготовить_базис(сам):
        проверка = сам.команда('подготовить-допуск')
        if проверка.returncode:
            raise AssertionError(проверка.stderr.decode())
        сам.закрепить_допуск()
        создание = сам.команда('создать', *сам.аргументы_допуска())
        if создание.returncode:
            raise AssertionError(создание.stderr.decode())
        return json.loads(создание.stdout)


class ОтказыПовтора(unittest.TestCase):
    def setUp(сам):
        сам.ф = ФикстураПолногоБазиса()
        сам.addCleanup(сам.ф.закрыть)
        сам.результат = сам.ф.подготовить_базис()

    def отказ_без_эффекта(сам):
        до = сам.ф.снимок()
        for действие in ('повтор', 'создать'):
            отказ = сам.ф.команда(действие, *сам.ф.аргументы_допуска())
            сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
            сам.assertEqual(до, сам.ф.снимок())
            сам.assertEqual(сам.результат['коммит'], сам.ф.ф.гит('rev-parse', 'HEAD').strip())

    def test_повтор_отказывает_подменённой_защите_после_коммита(сам):
        путь = сам.ф.корень / 'корень.txt'
        исходные = путь.read_bytes()
        режим = stat.S_IMODE(путь.stat().st_mode)
        индекс = сам.ф.корень / '.git/index'
        исходный_индекс = индекс.read_bytes()
        for вид in ('рабочие-байты', 'рабочий-режим', 'индекс'):
            with сам.subTest(вид=вид):
                путь.write_bytes(исходные)
                путь.chmod(режим)
                индекс.write_bytes(исходный_индекс)
                if вид == 'рабочий-режим':
                    путь.chmod(0o755)
                else:
                    путь.write_bytes('Подменён защищённый предмет\n'.encode())
                    if вид == 'индекс':
                        сам.ф.ф.гит('add', 'корень.txt')
                        путь.write_bytes(исходные)
                сам.отказ_без_эффекта()

    def test_неизвестная_схема_и_лишние_поля_согласованно_перехэшированы(сам):
        имена = ('намерение.json', 'процесс-коммита.json', 'квитанция.json')
        исходные = {имя: (сам.ф.частное / имя).read_bytes() for имя in имена}
        for вид in ('схема-намерения', 'лишнее-намерение', 'лишняя-квитанция'):
            with сам.subTest(вид=вид):
                намерение, процесс, квитанция = (json.loads(исходные[имя]) for имя in имена)
                if вид == 'схема-намерения':
                    намерение['схема'] = 'fum.неизвестное-намерение.1'
                elif вид == 'лишнее-намерение':
                    намерение['неизвестное'] = True
                else:
                    квитанция['неизвестное'] = True
                хэш_намерения = сам.ф.сохранить(сам.ф.частное / имена[0], намерение)
                процесс['намерение_sha256'] = квитанция['намерение_sha256'] = хэш_намерения
                квитанция['процесс_sha256'] = сам.ф.сохранить(сам.ф.частное / имена[1], процесс)
                сам.ф.сохранить(сам.ф.частное / имена[2], квитанция)
                сам.отказ_без_эффекта()

                for имя, данные in исходные.items():
                    (сам.ф.частное / имя).write_bytes(данные)

    def test_утраченные_свидетельства_не_восстанавливаются(сам):
        for имя in ('квитанция.json', 'процесс-коммита.json', 'commit.stdout', 'commit.stderr'):
            with сам.subTest(имя=имя):
                путь = сам.ф.частное / имя
                данные = путь.read_bytes()
                путь.unlink()
                сам.отказ_без_эффекта()
                путь.write_bytes(данные)
                путь.chmod(0o600)

    def test_неуспешный_процесс_с_пересчитанной_квитанцией(сам):
        путь = сам.ф.частное / 'процесс-коммита.json'
        исходные = путь.read_bytes()
        квитанция = json.loads((сам.ф.частное / 'квитанция.json').read_bytes())
        for ключ, значение in (('код', -signal.SIGTERM), ('код', True),
                ('исполнение_завершено', False), ('тайм_аут', True), ('прерывание', 'SIGTERM')):
            with сам.subTest(ключ=ключ, значение=значение):
                процесс = json.loads(исходные)
                процесс[ключ] = значение
                квитанция['процесс_sha256'] = сам.ф.сохранить(путь, процесс)
                сам.ф.сохранить(сам.ф.частное / 'квитанция.json', квитанция)
                сам.отказ_без_эффекта()


class ОтказыПоставки(unittest.TestCase):
    def test_потребитель_поставки_отказывает_незамкнутому_манифесту(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        ф.подготовить_базис()
        ф.закрепить_поставку()
        путь = ф.частное / 'выбор-P.json'
        исходный_выбор = json.loads(путь.read_bytes())
        манифест = ф.код / 'контур.json'
        исходный_манифест = json.loads(манифест.read_bytes())
        for вид in ('неизвестная-схема', 'лишнее-поле', 'повторный-путь'):
            with сам.subTest(вид=вид):
                данные = json.loads(байты_описания(исходный_манифест))
                if вид == 'неизвестная-схема':
                    данные['схема'] = 'fum.неизвестный-контур.1'
                elif вид == 'лишнее-поле':
                    данные['неизвестное'] = True
                else:
                    данные['контракты'].append(данные['контракты'][0])
                ф.сохранить(манифест, данные)
                ф.гит(ф.код, 'add', 'контур.json')
                ф.гит(ф.код, 'commit', '-qm', 'Подменить манифест адресного отказа поставки')
                выбор = json.loads(байты_описания(исходный_выбор))
                выбор['M'] = ф.селектор(ф.код, 'контур.json')
                ожидаемый = ф.сохранить(путь, выбор)
                до = ф.снимок()
                отказ = subprocess.run([*ф.аргументы_поставки[:-1], ожидаемый],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
                сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
                сам.assertEqual(до, ф.снимок())

    def test_поставка_не_поглощает_заранее_индексированное_изменение_допуска(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        ф.подготовить_базис()
        (ф.отчёт / 'D.json').chmod(0o755)
        ф.гит(ф.отчёт, 'add', 'D.json')
        до = ф.снимок()
        with сам.assertRaises(AssertionError):
            ф.закрепить_поставку()
        сам.assertEqual(до, ф.снимок())

    def test_читающий_потребитель_поставки_отказывает_нечастному_входу_и_повторному_полю(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        ф.подготовить_базис()
        ф.закрепить_поставку()
        путь = ф.частное / 'выбор-P.json'
        исходные = путь.read_bytes()
        for вид in ('режим-0644', 'ссылка', 'жёсткая-ссылка', 'повторное-поле', 'канал'):
            with сам.subTest(вид=вид):
                путь.unlink()
                if вид in ('ссылка', 'жёсткая-ссылка'):
                    цель = ф.частное / ('внешний-P-' + вид + '.json')
                    цель.write_bytes(исходные)
                    цель.chmod(0o600)
                    if вид == 'ссылка':
                        путь.symlink_to(цель)
                    else:
                        os.link(цель, путь)
                    данные = исходные
                elif вид == 'канал':
                    os.mkfifo(путь, 0o600)
                    данные = исходные
                else:
                    данные = исходные if вид == 'режим-0644' else исходные.rstrip()[:-1] + b', "\xd1\x81\xd1\x85\xd0\xb5\xd0\xbc\xd0\xb0": "fum.\xd0\xb2\xd1\x8b\xd0\xb1\xd0\xbe\xd1\x80-\xd1\x84\xd0\xb8\xd0\xba\xd1\x81\xd1\x82\xd1\x83\xd1\x80\xd0\xbd\xd0\xbe\xd0\xb9-\xd0\xbf\xd0\xbe\xd1\x81\xd1\x82\xd0\xb0\xd0\xb2\xd0\xba\xd0\xb8-\xd0\xb1\xd0\xb0\xd0\xb7\xd0\xb8\xd1\x81\xd0\xb0.1"}\n'
                    путь.write_bytes(данные)
                    путь.chmod(0o644 if вид == 'режим-0644' else 0o600)
                аргументы = [*ф.аргументы_поставки[:-1], hashlib.sha256(данные).hexdigest()]
                до = ф.снимок()
                отказ = subprocess.run(аргументы, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
                сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
                сам.assertEqual(до, ф.снимок())


class ЗакрытыйДопуск(unittest.TestCase):
    def test_наблюдение_штатного_процесса_не_является_отдельным_незакреплённым_листом(сам):
        for вид in ('утрачено', 'чужой-владелец', 'другой-номер', 'другой-родитель',
                    'другой-вызов', 'логический-номер', 'лишнее-поле'):
            with сам.subTest(вид=вид):
                ф = ФикстураПолногоБазиса()
                сам.addCleanup(ф.закрыть)
                подготовка = ф.команда('подготовить-допуск')
                сам.assertEqual(0, подготовка.returncode, подготовка.stderr.decode())
                путь = ф.частное / 'наблюдение-stock-child.json'
                if вид == 'утрачено':
                    путь.unlink()
                else:
                    наблюдение = json.loads(путь.read_bytes())
                    if вид in ('чужой-владелец', 'другой-номер'):
                        наблюдение['child']['uid' if вид == 'чужой-владелец' else 'pid'] += 1
                    elif вид == 'другой-вызов':
                        наблюдение['форма_вызова_хэш'] = '0' * 64
                    elif вид == 'логический-номер':
                        наблюдение['child']['pid'] = True
                    elif вид == 'лишнее-поле':
                        наблюдение['child']['неизвестное'] = True
                    хэш_наблюдения = ф.сохранить(путь, наблюдение)
                    рабочее = json.loads((ф.частное / 'worker.json').read_bytes())
                    if 'наблюдение_дочернего_sha256' in рабочее:
                        рабочее['наблюдение_дочернего_sha256'] = хэш_наблюдения
                        if вид == 'другой-родитель':
                            старт = json.loads((ф.частное / 'старт-дочернего.json').read_bytes())
                            старт['родитель'] += 1
                            рабочее['старт_дочернего_sha256'] = ф.сохранить(ф.частное / 'старт-дочернего.json', старт)
                        процесс = json.loads((ф.частное / 'процесс-проверки.json').read_bytes())
                        процесс['worker_sha256'] = ф.сохранить(ф.частное / 'worker.json', рабочее)
                        свидетельство = json.loads((ф.частное / 'типизированное.json').read_bytes())
                        свидетельство['rawprocess_sha256'] = ф.сохранить(ф.частное / 'процесс-проверки.json', процесс)
                        ф.сохранить(ф.частное / 'типизированное.json', свидетельство)
                ф.закрепить_допуск()
                до = ф.снимок()
                отказ = ф.команда('создать', *ф.аргументы_допуска())
                сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
                сам.assertEqual(до, ф.снимок())
                сам.assertFalse((ф.частное / 'намерение.json').exists())

    def test_независимый_допуск_не_принимает_перехэшированный_подменённый_процесс(сам):
        for вид in ('вызов', 'runtime', 'лишнее-поле', 'code_sha256', 'неполный-контур', 'роль'):
            with сам.subTest(вид=вид):
                ф = ФикстураПолногоБазиса()
                сам.addCleanup(ф.закрыть)
                проверка = ф.команда('подготовить-допуск')
                сам.assertEqual(0, проверка.returncode, проверка.stderr.decode())
                сырые = (ф.частное / 'процесс-проверки.json').read_bytes()
                типизированные = (ф.частное / 'типизированное.json').read_bytes()
                процесс = json.loads(сырые)
                свидетельство = json.loads(типизированные)
                if вид == 'вызов':
                    процесс['форма_вызова_хэш'] = '0' * 64
                elif вид == 'runtime':
                    процесс['runtime']['git']['sha256'] = '0' * 64
                elif вид == 'лишнее-поле':
                    процесс['неизвестное'] = True
                elif вид == 'code_sha256':
                    свидетельство['child_контур']['загрузки'][0]['code_sha256'] = '0' * 64
                elif вид == 'неполный-контур':
                    свидетельство['worker_контур']['загрузки'] = свидетельство['worker_контур']['загрузки'][:1]
                else:
                    свидетельство['supervisor_контур']['загрузки'][0]['роль'] = 'подменённая'
                свидетельство['rawprocess_sha256'] = ф.сохранить(ф.частное / 'процесс-проверки.json', процесс)
                ф.сохранить(ф.частное / 'типизированное.json', свидетельство)
                ф.закрепить_допуск()
                до = ф.снимок()
                отказ = ф.команда('создать', *ф.аргументы_допуска())
                сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
                сам.assertEqual(до, ф.снимок())
                сам.assertFalse((ф.частное / 'намерение.json').exists())


class ОтказыФизическойБазы(unittest.TestCase):
    def test_независимый_акт_владелец_и_поколение_сверяются_до_запуска(сам):
        for вид, признак in (('ACT-хэш', 'Независимый селектор'),
                ('ACT-исполнитель', 'Независимые C0/ACT_B'),
                ('владелец', 'Подменён владелец'), ('поколение', 'Независимые C0/ACT_B')):
            with сам.subTest(вид=вид):
                ф = ФикстураПолногоБазиса()
                сам.addCleanup(ф.закрыть)
                if вид == 'ACT-хэш':
                    ф.выбор['ACT_B']['sha256'] = '0' * 64
                elif вид == 'ACT-исполнитель':
                    акт = ф.выбор['ACT_B']
                    данные = закрытое_описание(ф.гит(ф.отчёт, 'cat-file', 'blob', акт['коммит'] + ':' + акт['путь']))
                    данные['исполнитель'] = str(uuid.uuid4())
                    ф.сохранить(ф.отчёт / акт['путь'], данные)
                    ф.гит(ф.отчёт, 'add', акт['путь'])
                    ф.гит(ф.отчёт, 'commit', '-qm', 'Подменить исполнителя адресного ACT отказа')
                    ф.выбор['ACT_B'] = ф.селектор(ф.отчёт, акт['путь'])
                elif вид == 'владелец':
                    ф.выбор['адрес']['uid'] += 1
                else:
                    ф.выбор['поколение'] = str(uuid.uuid4())
                ф.выбор_хэш = ф.сохранить(ф.выбор_путь, ф.выбор)
                ф.вход_хэш = ф.сохранить(ф.вход, {'схема': 'fum.создание-базиса-узла.1',
                    'выбор_sha256': ф.выбор_хэш, 'предмет': ф.ф.предмет})
                до = ф.снимок()
                отказ = ф.команда('подготовить-допуск')
                сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
                сам.assertIn(признак, отказ.stderr.decode())
                сам.assertEqual(до, ф.снимок())
                сам.assertFalse((ф.частное / 'намерение.json').exists())
                сам.assertFalse((ф.частное / 'наблюдение-stock-child.json').exists())

    def test_создатель_не_подменяет_предмет_нативные_данные_и_ссылку(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        проверка = ф.команда('подготовить-допуск')
        сам.assertEqual(0, проверка.returncode, проверка.stderr.decode())
        ф.закрепить_допуск()
        исходные = ф.вход.read_bytes()
        исходный_хэш = ф.вход_хэш
        for ключ in ('основа', 'включение', 'дерево', 'родители'):
            with сам.subTest(ключ=ключ):
                вход = json.loads(исходные)
                вход['предмет'][ключ] = ['0' * 40, '1' * 40] if ключ == 'родители' else '0' * 40
                ф.вход_хэш = ф.сохранить(ф.вход, вход)
                до = ф.снимок()
                отказ = ф.команда('создать', *ф.аргументы_допуска())
                сам.assertNotEqual(0, отказ.returncode)
                сам.assertEqual(до, ф.снимок())
                сам.assertFalse((ф.частное / 'намерение.json').exists())
        ф.вход.write_bytes(исходные)
        ф.вход_хэш = исходный_хэш
        for путь, данные in ((ф.нативный_срез, b'{}\n'),
                (ф.корень / '.git/HEAD', 'ref: refs/heads/другая\n'.encode()),
                (ф.корень / '.git/MERGE_HEAD', (ф.ф.предмет['основа'] + '\n').encode())):
            with сам.subTest(путь=путь.name):
                прежние = путь.read_bytes()
                путь.write_bytes(данные)
                до = ф.снимок()
                отказ = ф.команда('создать', *ф.аргументы_допуска())
                сам.assertNotEqual(0, отказ.returncode)
                сам.assertEqual(до, ф.снимок())
                сам.assertFalse((ф.частное / 'намерение.json').exists())
                путь.write_bytes(прежние)

    def test_подменённые_метаданные_и_каталог_объектов_не_дают_эффект(сам):
        for вид in ('ссылка-журнала', 'жёсткая-ссылка-журнала', 'ссылка-конфигурации', 'другой-inode-ODB'):
            with сам.subTest(вид=вид):
                ф = ФикстураПолногоБазиса()
                сам.addCleanup(ф.закрыть)
                проверка = ф.команда('подготовить-допуск')
                сам.assertEqual(0, проверка.returncode, проверка.stderr.decode())
                ф.закрепить_допуск()
                if вид == 'другой-inode-ODB':
                    прежнее = ф.каталог / 'старые-объекты'
                    исходное = ф.корень / '.git/objects'
                    исходное.rename(прежнее)
                    shutil.copytree(прежнее, исходное)
                else:
                    путь = ф.корень / ('.git/config' if вид == 'ссылка-конфигурации'
                                       else '.git/logs/refs/heads/основа')
                    внешний = ф.каталог / 'чужие-байты.txt'
                    внешний.write_bytes(путь.read_bytes())
                    путь.unlink()
                    if вид == 'жёсткая-ссылка-журнала':
                        os.link(внешний, путь)
                    else:
                        путь.symlink_to(внешний)
                до = ф.снимок()
                отказ = ф.команда('создать', *ф.аргументы_допуска())
                сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
                сам.assertEqual(до, ф.снимок())
                сам.assertFalse((ф.частное / 'намерение.json').exists())


class ИсключительностьЭффекта(unittest.TestCase):
    def test_ранний_отказ_регистрации_не_оставляет_удерживаемый_проверяющий_процесс(сам):
        def отказ_регистрации(данные, фикстура):
            точка = '            рабочий = прочитать_процессы(выбор)[процесс.pid]\n'.encode()
            добавка = ('            новый_частный_файл(выбор.частное / "барьер-регистрации.json", байты(рабочий))\n'
                '            raise ValueError("Адресная ошибка после реального spawn/OS registration")\n').encode()
            assert данные.count(точка) == 1
            return данные.replace(точка, точка + добавка)
        ф = ФикстураПолногоБазиса(отказ_регистрации)
        сам.addCleanup(ф.закрыть)
        отказ = ф.команда('подготовить-допуск')
        рабочий = json.loads((ф.частное / 'барьер-регистрации.json').read_bytes())
        try:
            сам.assertNotEqual(0, отказ.returncode)
            with сам.assertRaises(ProcessLookupError):
                os.killpg(рабочий['pid'], 0)
            сам.assertTrue((ф.частное / 'очистка-проверки.json').exists())
            сам.assertFalse((ф.частное / 'типизированное.json').exists())
        finally:
            # Контролируемый M-barrier фиксирует созданную own worker PG до преднамеренной ошибки.
            try:
                os.killpg(рабочий['pid'], signal.SIGTERM)
            except ProcessLookupError:
                pass
            time.sleep(0.1)

    def test_надзорный_процесс_завершает_отдельную_остановленную_группу_проверяющего(сам):
        сам.очистка_остановленных_групп()

    def test_отказ_наблюдателя_после_остановки_не_оставляет_проверяющий_процесс_остановленным(сам):
        сам.очистка_остановленных_групп(отказ_после_остановки=True)

    def очистка_остановленных_групп(сам, отказ_после_остановки=False):
        def остановка_дочернего(данные, фикстура):
            точка = '    новый_частный_файл(выбор.частное / \'старт-дочернего.json\', байты(старт))\n'.encode()
            assert данные.count(точка) == 1
            данные = данные.replace(точка, точка + b'    signal.pause()\n')
            if отказ_после_остановки:
                точка_очистки = '        таблица = прочитать_процессы(выбор)\n'.encode()
                assert данные.count(точка_очистки) == 1
                данные = данные.replace(точка_очистки,
                    '        raise ValueError("Реальный отказ наблюдателя после подтверждённого STOP")\n'.encode() + точка_очистки)
            return данные
        ф = ФикстураПолногоБазиса(остановка_дочернего)
        сам.addCleanup(ф.закрыть)
        среда = {к: в for к, в in os.environ.items() if not к.startswith(('GIT_', 'PYTHON'))}
        процесс = subprocess.Popen(ф.аргументы_режима('подготовить-допуск'), cwd=ф.отчёт, env=среда,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
        дочерний = рабочий = None
        try:
            срок = time.monotonic() + 10
            while not (ф.частное / 'старт-дочернего.json').exists() and time.monotonic() < срок:
                time.sleep(0.01)
            сам.assertTrue((ф.частное / 'старт-дочернего.json').exists())
            старт = json.loads((ф.частное / 'старт-дочернего.json').read_bytes())
            дочерний, рабочий = старт['pid'], старт['родитель']
            сам.assertEqual(дочерний, старт['pgid'])
            сам.assertEqual(дочерний, os.getpgid(дочерний))
            сам.assertEqual(рабочий, os.getpgid(рабочий))
            os.killpg(дочерний, signal.SIGSTOP)
            os.killpg(рабочий, signal.SIGSTOP)
            if отказ_после_остановки:
                os.killpg(процесс.pid, signal.SIGTERM)
            процесс.communicate(timeout=40)
            сам.assertNotEqual(0, процесс.returncode)
            for группа in (дочерний, рабочий):
                with сам.assertRaises(ProcessLookupError):
                    os.killpg(группа, 0)
            сам.assertFalse((ф.частное / 'типизированное.json').exists())
        finally:
            # Harness владеет наблюдёнными и остановленными fixture PG; это не authority JSON в Creator.
            for группа in (дочерний, рабочий):
                if группа is not None:
                    try:
                        os.killpg(группа, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
            if процесс.poll() is None:
                os.killpg(процесс.pid, signal.SIGKILL)
            процесс.communicate(timeout=5)

    def test_сигнал_завершения_после_намерения_и_базиса_не_разрешает_второй_эффект(сам):
        for этап in ('после-намерения', 'после-B'):
            with сам.subTest(этап=этап):
                def установить_барьер(данные, фикстура):
                    точка = ('    намерение_хэш = новый_частный_файл(выбор.частное / \'намерение.json\', байты(намерение))\n'
                        if этап == 'после-намерения' else
                        '    процесс_хэш = новый_частный_файл(выбор.частное / \'процесс-коммита.json\', байты(процесс))\n').encode()
                    добавка = ('    новый_частный_файл(выбор.частное / "барьер.json", байты({"pid": os.getpid(), "pgid": os.getpgrp(), "этап": '
                        + repr(этап) + '}))\n    signal.pause()\n').encode()
                    assert данные.count(точка) == 1
                    return данные.replace(точка, точка + добавка)
                ф = ФикстураПолногоБазиса(установить_барьер)
                сам.addCleanup(ф.закрыть)
                проверка = ф.команда('подготовить-допуск')
                сам.assertEqual(0, проверка.returncode, проверка.stderr.decode())
                ф.закрепить_допуск()
                коммиты_до = set(ф.ф.гит('rev-list', '--all').splitlines())
                среда = {к: в for к, в in os.environ.items() if not к.startswith(('GIT_', 'PYTHON'))}
                процесс = subprocess.Popen(ф.аргументы_режима('создать', *ф.аргументы_допуска()),
                    cwd=ф.отчёт, env=среда, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
                try:
                    срок = time.monotonic() + 15
                    while not (ф.частное / 'барьер.json').exists() and time.monotonic() < срок:
                        time.sleep(0.01)
                    сам.assertTrue((ф.частное / 'барьер.json').exists(), 'Реальный процесс не достиг барьера')
                    барьер = json.loads((ф.частное / 'барьер.json').read_bytes())
                    сам.assertEqual({'pid': процесс.pid, 'pgid': процесс.pid, 'этап': этап}, барьер)
                    os.killpg(процесс.pid, signal.SIGTERM)
                    процесс.communicate(timeout=5)
                    сам.assertEqual(-signal.SIGTERM, процесс.returncode)
                    with сам.assertRaises(ProcessLookupError):
                        os.killpg(процесс.pid, 0)
                finally:
                    if процесс.poll() is None:
                        os.killpg(процесс.pid, signal.SIGKILL)
                        процесс.communicate(timeout=5)
                после = set(ф.ф.гит('rev-list', '--all').splitlines())
                сам.assertEqual(0 if этап == 'после-намерения' else 1, len(после - коммиты_до))
                сам.assertTrue((ф.частное / 'намерение.json').exists())
                сам.assertFalse((ф.частное / 'квитанция.json').exists())
                до_повтора = ф.снимок()
                for действие in ('создать', 'повтор'):
                    отказ = ф.команда(действие, *ф.аргументы_допуска())
                    сам.assertNotEqual(0, отказ.returncode)
                    сам.assertEqual(до_повтора, ф.снимок())

    def test_занятый_замок_предмета_отказывает_до_намерения(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        проверка = ф.команда('подготовить-допуск')
        сам.assertEqual(0, проверка.returncode, проверка.stderr.decode())
        ф.закрепить_допуск()
        путь = ф.частное / 'замок-предмета'
        if not путь.exists():
            путь.write_bytes(b'')
            путь.chmod(0o600)
        with путь.open('rb') as замок:
            fcntl.flock(замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
            до = ф.снимок()
            отказ = ф.команда('создать', *ф.аргументы_допуска())
            сам.assertNotEqual(0, отказ.returncode, отказ.stdout.decode())
            сам.assertEqual(до, ф.снимок())
            сам.assertFalse((ф.частное / 'намерение.json').exists())
        создание = ф.команда('создать', *ф.аргументы_допуска())
        сам.assertEqual(0, создание.returncode, создание.stderr.decode())


class ПолныйБазис(unittest.TestCase):
    def test_неподтверждённый_гит_из_пути_поиска_не_исполняется_при_выборе_кода(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        каталог = ф.частное / 'подставной-bin'
        каталог.mkdir()
        след = ф.частное / 'неподтверждённый-Git.txt'
        исполняемый = каталог / 'git'
        исполняемый.write_text('#!' + sys.executable + '\nfrom pathlib import Path\nPath('
            + repr(str(след)) + ').write_text("Исполнен неподтверждённый Git")\n')
        исполняемый.chmod(0o700)
        среда = {к: в for к, в in os.environ.items() if not к.startswith(('GIT_', 'PYTHON'))}
        среда['PATH'] = str(каталог) + ':/usr/bin:/bin'
        до = ф.снимок()
        отказ = subprocess.run(ф.аргументы_режима('подготовить-допуск'), cwd=ф.отчёт, env=среда,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
        сам.assertNotEqual(0, отказ.returncode)
        сам.assertFalse(след.exists())
        сам.assertEqual(до, ф.снимок())

    def test_подменённый_вход_не_исполняется_до_допуска_кода(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        вход = ф.код / ДОПУСК.with_name('создание_базиса_узла.py').relative_to(КОРЕНЬ)
        след = ф.частное / 'подменённый-вход.txt'
        вход.write_bytes(('from pathlib import Path\nPath(' + repr(str(след))
            + ').write_text("Неприкреплённый вход")\n').encode() + вход.read_bytes())
        до = ф.снимок()
        отказ = ф.команда('подготовить-допуск')
        сам.assertNotEqual(0, отказ.returncode)
        сам.assertFalse(след.exists(), 'Вход исполнился до доверенного bootstrap')
        сам.assertEqual(до, ф.снимок())

    def test_поддельное_имя_среды_не_разрешает_новую_компиляцию_и_исполнение(сам):
        for имя in ('<frozen подмена>', str(Path(sys.base_prefix).resolve() / 'подмена.py')):
            with сам.subTest(имя=имя):
                def подменить(данные, фикстура):
                    нагрузка = 'from pathlib import Path\nPath(' + repr(str(фикстура.частное / 'подмена-runtime.txt')) + ').write_text("Исполнена подмена")'
                    точка = '        контур = КонтурЗагрузки(выбор)\n'.encode()
                    добавка = ('        exec(compile(' + repr(нагрузка) + ', ' + repr(имя) + ', "exec"), globals())\n').encode()
                    assert данные.count(точка) == 1
                    return данные.replace(точка, точка + добавка)
                ф = ФикстураПолногоБазиса(подменить)
                сам.addCleanup(ф.закрыть)
                до = ф.снимок()
                отказ = ф.команда('подготовить-допуск')
                сам.assertNotEqual(0, отказ.returncode)
                сам.assertFalse((ф.частное / 'подмена-runtime.txt').exists())
                сам.assertEqual(до, ф.снимок())

    def test_подменённый_физический_помощник_не_исполняется_до_допуска_кода(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        помощник = ф.код / ДОПУСК.relative_to(КОРЕНЬ)
        след = ф.частное / 'неразрешённый-эффект.txt'
        старое = помощник.read_bytes()
        помощник.write_bytes(('from pathlib import Path\nPath(' + repr(str(след))
                           + ').write_text("Подмена исполнена")\n').encode() + старое)
        до = ф.ф.снимок()
        отказ = ф.команда('подготовить-допуск')
        сам.assertNotEqual(0, отказ.returncode)
        сам.assertFalse(след.exists(), 'Неприкреплённый helper исполнился до проверки M')
        сам.assertEqual(до, ф.ф.снимок())

    def test_подлинная_проверка_независимый_допуск_один_базис_и_читающий_повтор(сам):
        ф = ФикстураПолногоБазиса()
        сам.addCleanup(ф.закрыть)
        до = ф.ф.снимок()
        проверка = ф.команда('подготовить-допуск')
        файл_ошибок_проверяющего = ф.частное / 'worker.stderr'
        диагностика = проверка.stderr.decode() + (файл_ошибок_проверяющего.read_text() if файл_ошибок_проверяющего.exists() else '')
        сам.assertEqual(0, проверка.returncode, диагностика)
        сам.assertTrue((ф.частное / 'типизированное.json').is_file(),
                       'Нет типизированного свидетельства реально выполненной stock v4')
        сам.assertEqual(до, ф.ф.снимок())
        ф.закрепить_допуск()
        аргументы_допуска = ('--выбор-D', str(ф.выбор_допуска), '--выбор-D-sha256', ф.выбор_допуска_хэш)
        создание = ф.команда('создать', *аргументы_допуска)
        сам.assertEqual(0, создание.returncode, создание.stderr.decode())
        итог = json.loads(создание.stdout)
        сам.assertEqual(ф.ф.дерево_фикстуры, итог['дерево'])
        сам.assertEqual(ф.ф.предмет['родители'], итог['родители'])
        сам.assertEqual(итог['коммит'], ф.ф.гит('rev-parse', 'HEAD').strip())
        до_повтора = tuple(sorted((п.relative_to(ф.каталог).as_posix(), п.stat().st_mode,
                                  п.stat().st_mtime_ns, п.stat().st_ino, hashlib.sha256(п.read_bytes()).hexdigest())
                                 for п in ф.каталог.rglob('*') if п.is_file()))
        повтор = ф.команда('повтор', *аргументы_допуска)
        сам.assertEqual(0, повтор.returncode, повтор.stderr.decode())
        сам.assertEqual(итог, json.loads(повтор.stdout))
        после_повтора = tuple(sorted((п.relative_to(ф.каталог).as_posix(), п.stat().st_mode,
                                     п.stat().st_mtime_ns, п.stat().st_ino, hashlib.sha256(п.read_bytes()).hexdigest())
                                    for п in ф.каталог.rglob('*') if п.is_file()))
        сам.assertEqual(до_повтора, после_повтора)
        # Потерянная/ещё не созданная поставка P не разрешает повтор B.
        до_поставки = ф.снимок()
        повтор_без_поставки = ф.команда('создать', *аргументы_допуска)
        сам.assertEqual(0, повтор_без_поставки.returncode, повтор_без_поставки.stderr.decode())
        сам.assertEqual(итог, json.loads(повтор_без_поставки.stdout))
        сам.assertEqual(до_поставки, ф.снимок())
        поставка = ф.закрепить_поставку()
        сам.assertTrue(поставка['подтверждена'])
        сам.assertEqual(итог, поставка['результат'])
        снимок_после_поставки = ф.снимок()
        повтор_после_поставки = ф.команда('повтор', *аргументы_допуска)
        сам.assertEqual(0, повтор_после_поставки.returncode, повтор_после_поставки.stderr.decode())
        сам.assertEqual(итог, json.loads(повтор_после_поставки.stdout))
        сам.assertEqual(снимок_после_поставки, ф.снимок())


class ШтатныйПутьБазиса(unittest.TestCase):
    """Production-вход не требует Журнала внутри принятого T."""
    def setUp(сам):
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        sys.path.insert(0, str(ДОПУСК.parent))
        import создание_коммита
        from test_построителя_дерева_базиса_узла import ПримерПостроителя, штатный_гит
        import построить_дерево_базиса_узла as построитель
        сам.м = создание_коммита
        сам.временная_область = tempfile.TemporaryDirectory(prefix='fum-production-b-')
        сам.addCleanup(сам.временная_область.cleanup)
        сам.каталог = Path(сам.временная_область.name).resolve()
        сам.пример = ПримерПостроителя(сам.каталог)
        if 'ссылка_на_коммит' in сам._testMethodName:
            from test_построителя_дерева_базиса_узла import ПостроительДерева
            оснастка = ПостроительДерева(); оснастка.пример = сам.пример
            сам.специальный_путь, сам.специальная_запись = оснастка.специальный_общий_предок('160000')
        сам.ф = сам.пример.ф
        сам.корень = сам.ф.корень
        if 'отдельный_кандидат' in сам._testMethodName:
            сам.корень = сам.каталог / 'кандидат'
            сам.гит(сам.ф.корень,'worktree','add','--detach',str(сам.корень),сам.ф.принятый_код)
        сам.каталог_готовности = сам.каталог / 'готовность'
        сам.подмена_хранилища = patch.object(сам.м.готовность, 'КОРЕНЬ_СОСТОЯНИЯ', сам.каталог_готовности)
        сам.подмена_хранилища.start(); сам.addCleanup(сам.подмена_хранилища.stop)
        сам.владелец = str(uuid.uuid4())
        сам.корневая_задача = сам.ф.идентичность['координатор']
        сам.ветка = 'refs/heads/codex/создать-b'
        сам.нативный = сам.каталог / 'native.jsonl'
        сам.текст = 'Создай ровно выбранный базис B из уже принятого дерева.\n'
        сам.события = [
            {'type':'session_meta','payload':{'id':сам.владелец,'cwd':str(сам.корень),
                'thread_source':'agent_created_thread','git':{'commit_hash':сам.ф.принятый_код}}},
            {'type':'turn_context','timestamp':'2026-10-16T10:00:00Z',
                'payload':{'cwd':str(сам.корень),'model':'gpt-6.1-sol','effort':'ultra'}},
            {'type':'response_item','payload':{'type':'function_call_output','name':'create_thread',
                'output':'<codex_delegation>\n  <source_thread_id>'+сам.корневая_задача+
                    '</source_thread_id>\n  <input>'+сам.текст+'</input>\n</codex_delegation>'}}]
        сам.нативный.write_bytes(b''.join(сам.м.байты(э) for э in сам.события))
        среда = {к:в for к,в in os.environ.items() if not к.startswith('GIT_')}
        среда.update(CODEX_THREAD_ID=сам.владелец,GIT_CONFIG_NOSYSTEM='1',GIT_CONFIG_GLOBAL=os.devnull)
        сам.окружение = patch.dict(os.environ, среда, clear=True)
        сам.окружение.start(); сам.addCleanup(сам.окружение.stop)
        кандидат = построитель.построить_дерево(сам.пример.вход, сам.пример.выбор)
        сам.дерево = кандидат['дерево']
        # Уже принятые tree-объекты переносит оснастка; Creator их не строит.
        for префикс in сам.пример.объекты.iterdir():
            база_объектов=Path(сам.гит(сам.корень,'rev-parse','--git-path','objects').decode().strip())
            if not база_объектов.is_absolute(): база_объектов=сам.корень/база_объектов
            цель = база_объектов.resolve() / префикс.name
            цель.mkdir(exist_ok=True)
            for объект in префикс.iterdir():
                if not (цель / объект.name).exists(): shutil.copyfile(объект, цель / объект.name)
                else:
                    import zlib
                    сам.assertEqual(zlib.decompress(объект.read_bytes()), zlib.decompress((цель / объект.name).read_bytes()))
        сам.отчёт = сам.каталог / 'доказательства'; сам.отчёт.mkdir()
        сам.гит(сам.отчёт,'init','-q','-b','codex/доказательства')
        сам.гит(сам.отчёт,'config','user.name','Независимый ROOT')
        сам.гит(сам.отчёт,'config','user.email','root@example.invalid')
        сам.сохранить('постановка.md',сам.текст.encode())
        коммит_постановки=сам.коммит('Закрепить постановку')
        сам.постановка=сам.выбор(коммит_постановки,'постановка.md')
        сам.сохранить('построитель.json',сам.м.байты(кандидат))
        коммит_построителя=сам.коммит('Принять результат построителя')
        сам.выбор_построителя=сам.выбор(коммит_построителя,'построитель.json')
        сам.предмет={'K':сам.ф.принятый_код,'R':сам.ф.исходное_состояние,
            'дерево':сам.дерево,'родители':[сам.ф.принятый_код,сам.ф.исходное_состояние]}
        сам.запрос='Журнал/2026-10-16_10-00-00_MSK_создать-b/запрос.md'
        сам.вход_построителя=сам.каталог/'вход-построителя.json'
        сам.вход_построителя.write_bytes(сам.м.байты(сам.пример.вход)); сам.вход_построителя.chmod(0o400)
        сам.акт={'схема':'fum.поручение-создания-базиса-узла.1','координатор':сам.корневая_задача,
            'исполнитель':сам.владелец,'постановка':сам.постановка,
            'адрес':{'хэш_корня':сам.м.хэш(str(сам.корень).encode()),'ветка':сам.ветка,'запрос':сам.запрос},
            'предмет':сам.предмет,'построитель':сам.выбор_построителя,
            'вход_построителя_sha256':сам.м.хэш(сам.м.байты(сам.пример.вход)),
            'контроль':{'ветка':'refs/heads/codex/контроль-b','коммит':коммит_построителя},
            'хэш_нативного_поручения':сам.м.хэш(сам.текст.encode())}
        сам.гит(сам.отчёт,'branch','codex/контроль-b',коммит_построителя)
        сам.сохранить('ACT_B.json',сам.м.байты(сам.акт))
        коммит_назначения=сам.коммит('Назначить единственного владельца B')
        сам.назначение=сам.выбор(коммит_назначения,'ACT_B.json')
        сам.гит(сам.корень,'switch','-C','codex/создать-b',сам.ф.принятый_код)
        сам.гит(сам.корень,'read-tree','--reset','-u',сам.дерево)
        админ=Path(сам.гит(сам.корень,'rev-parse','--absolute-git-dir').decode().strip())
        (админ/'MERGE_HEAD').write_text(сам.ф.исходное_состояние+'\n')
        сам.хэш_индекса=сам.м.хэш(сам.гит(сам.корень,'ls-files','--stage','-v','-z'))
        сам.проверка=str(uuid.uuid4())
        # Реальные v4 и RAW создаются отдельным фиксированным процессом.
        сам.предвыбор={'схема':'fum.выбор-проверки-предмета-базиса.1','отчётный_корень':str(сам.отчёт),
            'назначение':сам.назначение,
            'вход_построителя':{'путь':str(сам.вход_построителя),'sha256':сам.м.хэш(сам.вход_построителя.read_bytes())},
            'гит':{'путь':str(Path(shutil.which('git')).resolve()),
                'sha256':сам.м.хэш(Path(shutil.which('git')).resolve().read_bytes())},
            'python':{'путь':str(Path(sys.executable).resolve()),
                'sha256':сам.м.хэш(Path(sys.executable).resolve().read_bytes())}}
        сам.п = {'схема':'fum.создание-коммита.12','режим':'контрольная-точка',
            'корень':str(сам.корень),'ветка':сам.ветка,'исходный_коммит':сам.предмет['K'],
            'родители':сам.предмет['родители'],'задача':сам.корневая_задача,'исполнитель':сам.владелец,
            'запрос':сам.запрос,'разрешённые_цели':[э['путь'] for э in кандидат['защищённые']],
            'источник_модели':str(сам.нативный),'имя_автора':'FUM Codex',
            'заголовок':'Создать выбранный базис узла','описание':'Сохранить точное принятое дерево.',
            'выбранный_базис':сам.предвыбор,'сообщение':str(сам.каталог/'сообщение.txt'),
            'подготовка':str(сам.каталог/'подготовка.json'),'квитанция':str(сам.каталог/'квитанция.json')}

        сам.п['квитанция']=str(сам.м.готовность.путь_этапа(сам.п).with_suffix('.базис-квитанция.json'))
        сам.вход_захвата=сам.каталог/'вход-RAW.json'
        сам.вход_захвата.write_bytes(сам.м.байты(сам.п)); сам.вход_захвата.chmod(0o600)
        сам.создать_доказательства()
        сам.выбор_базиса={**сам.предвыбор,'схема':'fum.выбор-создания-базиса-узла.1',
            'доказательства':сам.выбор_доказательств,'проверка':{'вход':str(сам.вход_захвата),
                'вход_sha256':сам.м.хэш(сам.вход_захвата.read_bytes()),'каталог':str(сам.каталог/'RAW'),
                'манифест_sha256':сам.хэш_манифеста,'нативный_префикс':str(сам.каталог/'native-D.jsonl')}}
        сам.выбор_базиса['проверка']['нативный']=сам.нативная_пара_захвата()
        сам.п['выбранный_базис']=сам.выбор_базиса

    def гит(сам,корень,*аргументы):
        return subprocess.check_output(['git','--no-optional-locks','-c','core.hooksPath='+os.devnull,
            '-c','core.fsmonitor=false','-C',str(корень),*аргументы],stderr=subprocess.PIPE)

    def сохранить(сам,имя,данные):
        п=сам.отчёт/имя; п.parent.mkdir(parents=True,exist_ok=True); п.write_bytes(данные)

    def коммит(сам,текст):
        сам.гит(сам.отчёт,'add','-A'); сам.гит(сам.отчёт,'commit','-qm',текст)
        return сам.гит(сам.отчёт,'rev-parse','HEAD').decode().strip()

    def выбор(сам,коммит,имя):
        return {'коммит':коммит,'путь':имя,'sha256':сам.м.хэш(сам.гит(сам.отчёт,'show',коммит+':'+имя))}

    def создать_доказательства(сам):
        import contextlib,io
        о=сам.м.отчёты
        запрос=сам.отчёт/сам.запрос
        сам.сохранить(сам.запрос,('# Запрос\n\n## Идентификатор сеанса Codex\n\nCodex-Thread-ID: '+сам.корневая_задача+'\n').encode())
        сам.сохранить(str(Path(сам.запрос).with_name('отчёт.md')),
            ('# Отчёт\n\n### Прямые запуски проверок\n\n'+о.ОТКРЫТЫЙ_МАРКЕР+'\nДо запуска.\n'+о.КОНЕЧНЫЙ_МАРКЕР+'\n').encode())
        import допуск_создания_базиса_узла as адаптер
        команда=адаптер.команда_сырого_захвата_базиса(сам.предвыбор,сам.п,сам.м,сам.проверка,
            str(сам.вход_захвата),str(сам.каталог/'RAW'))
        процесс_обёртки=subprocess.run(команда,cwd=сам.отчёт,capture_output=True,timeout=60)
        сам.assertEqual(0,процесс_обёртки.returncode,процесс_обёртки.stderr.decode())
        сам.указатель_захвата=json.loads(процесс_обёртки.stdout)
        with contextlib.redirect_stdout(io.StringIO()): о.выполнить_предпросмотр(сам.отчёт,запрос)
        каталог=запрос.parent/'материалы/запуски-проверок'
        запись=next(каталог.glob('*_'+сам.проверка+'.json'))
        манифест=json.loads((сам.каталог/'RAW/манифест.json').read_bytes())
        сам.хэш_манифеста=сам.указатель_захвата['манифест_sha256']
        сам.assertEqual(сам.хэш_манифеста,сам.м.хэш((сам.каталог/'RAW/манифест.json').read_bytes()))
        сам.сохранить('proof.json',(сам.каталог/'RAW/stdout.bin').read_bytes())
        сам.сохранить('stdout',(сам.каталог/'RAW/stdout.bin').read_bytes())
        сам.сохранить('stderr',(сам.каталог/'RAW/stderr.bin').read_bytes())
        процесс={'схема':'fum.процесс-проверки-предмета-базиса.1','проверка':сам.проверка,
            'код':манифест['код_процесса'],'исполнение_завершено':манифест['полнота'],
            'тайм_аут':False,'прерывание':None,'stdout_sha256':манифест['каналы']['stdout']['sha256'],
            'stderr_sha256':манифест['каналы']['stderr']['sha256']}
        сам.сохранить('process.json',сам.м.байты(процесс))
        def материал(имя): return {'путь':имя,'sha256':сам.м.хэш((сам.отчёт/имя).read_bytes())}
        предметный_результат=json.loads((сам.каталог/'RAW/stdout.bin').read_bytes())
        история=предметный_результат['история_модели']
        сам.сохранить('model.json',сам.м.байты(история))
        префикс=сам.каталог/'native-D.jsonl'
        префикс.write_bytes(сам.нативный.read_bytes()[:история['граница']]); префикс.chmod(0o400)
        сам.документ_доказательств={'схема':'fum.доказательства-создания-базиса-узла.1',
            'назначение':сам.назначение,'предмет':сам.предмет,'построитель':сам.выбор_построителя,
            'индекс':{'дерево':сам.дерево,'индекс_sha256':сам.хэш_индекса},'история_модели':материал('model.json'),
            'нативный_срез':{'sha256':сам.м.хэш(префикс.read_bytes()),'граница':история['граница']},
            'проверки':[{'идентификатор':сам.проверка,'v4':материал(запись.relative_to(сам.отчёт).as_posix()),
                'предмет':материал('proof.json'),'процесс':материал('process.json'),
                'stdout':материал('stdout'),'stderr':материал('stderr')} ]}
        сам.сохранить('D.json',сам.м.байты(сам.документ_доказательств)); коммит_доказательств=сам.коммит('Закрепить D до B вне T')
        сам.выбор_доказательств=сам.выбор(коммит_доказательств,'D.json')

    def подготовить(сам):
        return сам.м.подготовить(сам.п,доверенное_поручение=сам.выбор_базиса)

    def test_подготовка_читает_доказательства_без_добавления_Журнала_к_дереву(сам):
        до=сам.гит(сам.корень,'ls-files','--stage','-v','-z')
        сам.подготовить()
        сам.assertEqual(до,сам.гит(сам.корень,'ls-files','--stage','-v','-z'))
        сам.assertFalse((сам.корень/сам.запрос).exists())
        подготовка=json.loads(Path(сам.п['подготовка']).read_text())
        сам.assertEqual('fum.подготовленный-коммит.14',подготовка['схема'])
        сам.assertEqual(сам.дерево,подготовка['привязка_базиса']['предмет']['дерево'])


    def нативная_пара_захвата(сам):
        import сформировать_нативный_вызов as генератор
        import допуск_создания_базиса_узла as адаптер
        исходник=адаптер.нативный_вызов_сырого_захвата_базиса(сам.выбор_базиса,сам.п,сам.м,сам.проверка)
        ход=str(uuid.uuid4()); вызов='call_'+uuid.uuid4().hex
        мета={'turn_id':ход,'create_time':1.0}
        указатель={'схема':'fum.указатель-RAW-предмета-базиса.1','проверка':сам.проверка,
            'каталог':str(сам.каталог/'RAW'),'манифест_sha256':сам.хэш_манифеста}
        данные=[{'type':'session_meta','payload':{'id':сам.владелец,'cwd':str(сам.отчёт)}},
            {'type':'turn_context','payload':{'turn_id':ход,'cwd':str(сам.отчёт)}},
            {'type':'response_item','payload':{'type':'custom_tool_call','id':'fixture-вызов',
                'call_id':вызов,'status':'completed','name':'exec','input':исходник,
                'internal_chat_message_metadata_passthrough':мета},'metadata':{'client_authored':False}},
            {'type':'response_item','payload':{'type':'custom_tool_call_output','id':'fixture-исход',
                'call_id':вызов,'output':[{'type':'input_text','text':'Script completed\nWall time 0.1 seconds\nOutput:\n'},
                    {'type':'input_text','text':сам.м.байты(указатель).decode()}],
                'internal_chat_message_metadata_passthrough':мета},'metadata':{'client_authored':False}}]
        строки=[генератор.байты({**з,'ordinal':н,'timestamp':'2026-10-16T10:00:00.000Z'}) for н,з in enumerate(данные)]
        путь=сам.каталог/'host-RAW.jsonl'; путь.write_bytes(b''.join(строки)); путь.chmod(0o400)
        def позиция(начало,конец):
            return {'начало':sum(map(len,строки[:начало])),'конец':sum(map(len,строки[:конец])),
                'sha256':сам.м.хэш(b''.join(строки[начало:конец]))}
        return {'схема':'fum.ожидание-нативной-подготовки.1','выбор':str(сам.вход_захвата),
            'выбор_sha256':сам.м.хэш(сам.вход_захвата.read_bytes()),'JS_sha256':сам.м.хэш(исходник.encode()),
            'исполнитель':сам.владелец,'turn_id':ход,'call_id':вызов,'корень_контекста':str(сам.отчёт),
            'источник':{'путь':str(путь),'личность':list(генератор.отпечаток(путь.stat())),
                'мета':позиция(0,1),'интервал':позиция(1,4),'вызов':позиция(2,3),'исход':позиция(3,4)}}

    def готово(сам):
        сам.подготовить()
        return сам.м.объявить_готовность(Path(сам.п['подготовка']),[сам.проверка],600,
            доверенное_поручение=сам.выбор_базиса)

    def создать(сам):
        return сам.м.создать(Path(сам.п['подготовка']),[сам.проверка],доверенное_поручение=сам.выбор_базиса)

    def снимок_базиса(сам):
        результат={}
        for п in сам.каталог.rglob('*'):
            с=п.lstat()
            результат[п.relative_to(сам.каталог).as_posix()]=(с.st_mode,с.st_ino,с.st_size,
                с.st_mtime_ns,с.st_ctime_ns,hashlib.sha256(п.read_bytes()).hexdigest() if п.is_file() else None)
        return результат

    def test_обычный_эффект_сохраняет_дерево_и_повтор_не_пишет(сам):
        сам.готово()
        итог=сам.создать()
        сам.assertEqual(сам.дерево,итог['дерево'])
        сам.assertEqual(сам.предмет['родители'],итог['родители'])
        сам.assertEqual(6,len(итог))
        import приём_базиса_состояния_узла as приём
        приём.сверить_первый_цикл(сам.корень,сам.предмет['R'],итог['коммит'],
            сам.ф.выбранный_акт,сам.ф.выбранные_полномочия,сам.ф.идентичность,сам.ф.защищённые())
        # Исторический успех не зависит от сегодняшних READY/control/native.
        сам.гит(сам.отчёт,'update-ref','refs/heads/codex/контроль-b',сам.выбор_доказательств['коммит'])
        сам.нативный.unlink()
        сам.м.готовность.путь_этапа(сам.п).unlink()
        Path(сам.п['квитанция']+'.lock').unlink()
        выбор=сам.каталог/'выбор.json'; выбор.write_bytes(сам.м.байты(сам.выбор_базиса)); выбор.chmod(0o600)
        до=сам.снимок_базиса()
        команда=("import sys; from pathlib import Path; sys.path.insert(0,sys.argv.pop(1)); "
            "import создание_коммита as м; м.готовность.КОРЕНЬ_СОСТОЯНИЯ=Path(sys.argv.pop(1)); raise SystemExit(м.главная())")
        повтор=subprocess.run([sys.executable,'-B','-c',команда,str(ДОПУСК.parent),str(сам.каталог_готовности),
            'создать','--подготовка',сам.п['подготовка'],'--проверка',сам.проверка,
            '--доверенное-поручение',str(выбор)],capture_output=True)
        сам.assertEqual(0,повтор.returncode,повтор.stderr.decode())
        сам.assertEqual(итог,json.loads(повтор.stdout))
        сам.assertEqual(до,сам.снимок_базиса())

    def отказ_базиса(сам,действие):
        до=сам.гит(сам.корень,'rev-parse','HEAD'),сам.гит(сам.корень,'ls-files','--stage','-v','-z')
        with сам.assertRaises(ValueError): действие()
        сам.assertEqual(до,(сам.гит(сам.корень,'rev-parse','HEAD'),сам.гит(сам.корень,'ls-files','--stage','-v','-z')))

    def test_добавление_Журнала_к_дереву_отклоняется(сам):
        п=сам.корень/сам.запрос; п.parent.mkdir(parents=True); п.write_text('Лишний Журнал B\n')
        сам.гит(сам.корень,'add',сам.запрос)
        сам.отказ_базиса(сам.подготовить)
        сам.assertFalse(Path(сам.п['подготовка']).exists())

    def test_перестановка_родителей_отклоняется(сам):
        сам.п['родители']=list(reversed(сам.п['родители']))
        сам.отказ_базиса(сам.подготовить)

    def test_независимый_выбор_нельзя_заменить_копией_создателя(сам):
        import copy
        сам.п['выбранный_базис']=copy.deepcopy(сам.выбор_базиса)
        сам.п['выбранный_базис']['доказательства']['sha256']='0'*64
        сам.отказ_базиса(сам.подготовить)

    def test_режим_защищённого_файла_отклоняется(сам):
        (сам.корень/сам.ф.замороженные[0]).chmod(0o755)
        сам.отказ_базиса(сам.подготовить)

    def test_контроль_после_готовности_останавливает_свежий_эффект(сам):
        сам.готово()
        сам.гит(сам.отчёт,'update-ref','refs/heads/codex/контроль-b',сам.выбор_доказательств['коммит'])
        сам.отказ_базиса(сам.создать)
        сам.assertFalse(Path(сам.п['квитанция']).exists())

    def test_намерение_не_разрешает_новую_подготовку_или_эффект(сам):
        сам.готово()
        кв=Path(сам.п['квитанция']); кв.write_bytes(сам.м.байты({'состояние':'намерение'})); кв.chmod(0o600)
        до=сам.снимок_базиса()
        сам.отказ_базиса(сам.создать)
        сам.assertEqual(до,сам.снимок_базиса())
        сам.п['сообщение']=str(сам.каталог/'другое-сообщение.txt')
        сам.п['подготовка']=str(сам.каталог/'другая-подготовка.json')
        сам.п['квитанция']=str(сам.каталог/'другая-квитанция.json')
        сам.отказ_базиса(сам.подготовить)
        сам.assertFalse(Path(сам.п['подготовка']).exists())


    def test_сообщение_и_хэш_подготовки_не_подменяют_нативные_доказательства(сам):
        сам.подготовить()
        путь=Path(сам.п['подготовка']); подготовка=json.loads(путь.read_bytes())
        ложное=b'Wrong message without commands or metadata\n'
        Path(сам.п['сообщение']).write_bytes(ложное)
        подготовка['сообщение_sha256']=сам.м.хэш(ложное)
        путь.write_bytes(сам.м.байты(подготовка))
        сам.отказ_базиса(lambda:сам.м.объявить_готовность(путь,[сам.проверка],600,
            доверенное_поручение=сам.выбор_базиса))

    def test_новая_модель_во_время_чтения_закрывает_допуск(сам):
        сверить=сам.м.модели.чтение._сверить_снимок
        def дописать(поток,источник,сведения,индекс):
            with Path(источник).open('ab') as запись:
                запись.write(сам.м.байты({'type':'turn_context','timestamp':'2026-10-16T11:00:00Z',
                    'payload':{'model':'gpt-6-astra','effort':'high'}}))
            return сверить(поток,источник,сведения,индекс)
        with patch.object(сам.м.модели.чтение,'_сверить_снимок',дописать):
            сам.отказ_базиса(сам.подготовить)
        сам.assertFalse(Path(сам.п['подготовка']).exists())

    def test_отсутствующий_сырой_захват_не_заменяется_согласованным_пакетом_доказательств(сам):
        (сам.каталог/'RAW/stdout.bin').unlink()
        сам.отказ_базиса(сам.подготовить)
        сам.assertFalse(Path(сам.п['подготовка']).exists())

    def test_подмена_среды_ответа_не_разрешает_базис(сам):
        дескриптор=сам.выбор_базиса['проверка']['нативный']
        дескриптор['JS_sha256']='0'*64
        сам.отказ_базиса(сам.подготовить)


    def test_историческая_ссылка_на_коммит_остаётся_непрозрачной(сам):
        сам.готово()
        итог=сам.создать()
        сам.assertEqual(сам.дерево,итог['дерево'])
        сам.assertIn(('160000 '+сам.специальная_запись[2]).encode(),
            сам.гит(сам.корень,'ls-files','--stage','--',сам.специальный_путь))
        сам.assertFalse((сам.корень/сам.специальный_путь/'.git').exists())

    def test_изменённая_ссылка_на_коммит_отклоняется(сам):
        сам.гит(сам.корень,'update-index','--cacheinfo','160000,'+'a'*40+','+сам.специальный_путь)
        сам.отказ_базиса(сам.подготовить)


    def test_отдельный_кандидат_с_трассировкой_исходника_отказывает_до_чтения(сам):
        исходный = сам.ф.корень
        сам.assertNotEqual(исходный, сам.корень)
        след = сам.каталог / 'трассировка-исходного-репозитория.jsonl'
        сам.гит(исходный, 'config', 'extensions.worktreeConfig', 'true')
        сам.гит(исходный, 'config', '--worktree', 'trace2.eventTarget', str(след))
        сам.assertFalse(след.exists())
        with сам.assertRaises(сам.м.ОшибкаКоммита) as отказ:
            сам.подготовить()
        сам.assertIn('Трассирующая конфигурация', str(отказ.exception))
        сам.assertFalse(след.exists())

    def test_отдельный_кандидат_сохраняет_исходный_рабочий_каталог(сам):
        исходный=сам.ф.корень
        def исходные_байты():
            return (сам.гит(исходный,'rev-parse','HEAD'),сам.гит(исходный,'symbolic-ref','HEAD'),
                (исходный/'.git/index').read_bytes(),
                {п.relative_to(исходный).as_posix():п.read_bytes() for п in исходный.rglob('*')
                    if п.is_file() and '.git' not in п.relative_to(исходный).parts})
        до=исходные_байты(); сам.готово(); итог=сам.создать()
        сам.assertEqual(сам.дерево,итог['дерево'])
        сам.assertEqual(до,исходные_байты())
        сам.assertTrue((сам.корень/'.git').is_file())

    def test_посторонний_рабочий_каталог_отклоняется(сам):
        сам.п['корень']=str(сам.отчёт)
        сам.отказ_базиса(сам.подготовить)

    def test_посторонняя_ветка_отклоняется(сам):
        сам.гит(сам.корень,'branch','codex/чужой',сам.предмет['K'])
        сам.гит(сам.корень,'symbolic-ref','HEAD','refs/heads/codex/чужой')
        сам.отказ_базиса(сам.подготовить)

    def test_дрейф_ожиданий_отклоняется(сам):
        путь=сам.ф.замороженные[0]
        (сам.корень/путь).write_text('{"подмена":true}\n')
        сам.гит(сам.корень,'add','--',путь)
        сам.отказ_базиса(сам.подготовить)

    def test_дрейф_хэша_доказательств_отклоняется(сам):
        сам.выбор_базиса['доказательства']['sha256']='0'*64
        сам.отказ_базиса(сам.подготовить)

    def test_дрейф_выбранного_дерева_отклоняется(сам):
        сам.акт['предмет']['дерево']=сам.гит(сам.корень,'rev-parse',сам.предмет['K']+'^{tree}').decode().strip()
        сам.сохранить('ACT_B.json',сам.м.байты(сам.акт))
        новый=сам.коммит('Отрицательный ACT с другим T')
        сам.выбор_базиса['назначение']=сам.выбор(новый,'ACT_B.json')
        сам.отказ_базиса(сам.подготовить)

    def test_обычный_инструментальный_хвост_не_подменяет_снимок_доказательств(сам):
        with сам.нативный.open('ab') as п:
            п.write(сам.м.байты({'type':'event_msg','payload':{'type':'agent_message','message':'tool completed'}}))
        сам.подготовить()
        сам.assertTrue(Path(сам.п['подготовка']).is_file())

    def test_контроль_после_намерения_не_разрешает_повтор(сам):
        сам.готово(); сохранить=сам.м.модели.сохранить_сообщение
        def после_намерения(путь,текст):
            результат=сохранить(путь,текст)
            if Path(путь)==Path(сам.п['квитанция']):
                сам.гит(сам.отчёт,'update-ref','refs/heads/codex/контроль-b',сам.выбор_доказательств['коммит'])
            return результат
        with patch.object(сам.м.модели,'сохранить_сообщение',после_намерения):
            сам.отказ_базиса(сам.создать)
        квитанция=json.loads(Path(сам.п['квитанция']).read_bytes())
        сам.assertNotEqual('проверен',квитанция['состояние'])
        до=сам.снимок_базиса(); сам.отказ_базиса(сам.создать); сам.assertEqual(до,сам.снимок_базиса())


    def test_поздняя_смена_символической_ссылки_не_завершает_квитанцию_и_не_повторяет_эффект(сам):
        сам.готово()
        прежние = set(сам.гит(сам.корень, 'rev-list', '--all').splitlines())
        выполнить = сам.м.выполнить_эффект
        чужая_ветка = 'refs/heads/codex/поздний-ref-b'
        вызовов = 0
        def с_поздней_подменой(*аргументы, **параметры):
            проверка_после_эффекта = параметры['после_эффекта']
            def после_проверки(квитанция):
                nonlocal вызовов
                проверка_после_эффекта(квитанция)
                вызовов += 1
                if вызовов == 2:
                    голова = сам.гит(сам.корень, 'rev-parse', 'HEAD').decode().strip()
                    сам.гит(сам.корень, 'update-ref', чужая_ветка, голова, '0' * 40)
                    сам.гит(сам.корень, 'symbolic-ref', 'HEAD', чужая_ветка)
            параметры['после_эффекта'] = после_проверки
            return выполнить(*аргументы, **параметры)
        with patch.object(сам.м, 'выполнить_эффект', side_effect=с_поздней_подменой):
            with сам.assertRaisesRegex(сам.м.ОшибкаКоммита, 'после последнего предметного допуска'):
                сам.создать()
        сам.assertEqual(2, вызовов)
        сам.assertEqual(чужая_ветка, сам.гит(сам.корень, 'symbolic-ref', 'HEAD').decode().strip())
        голова = сам.гит(сам.корень, 'rev-parse', 'HEAD').strip()
        сам.assertEqual({голова}, set(сам.гит(сам.корень, 'rev-list', '--all').splitlines()) - прежние)
        сам.assertEqual(сам.дерево, сам.гит(сам.корень, 'rev-parse', 'HEAD^{tree}').decode().strip())
        путь = сам.м.базисный_адаптер().каноническая_квитанция(сам.п, сам.м)
        сам.assertEqual(Path(сам.п['квитанция']), путь)
        квитанция_байты = путь.read_bytes(); квитанция = json.loads(квитанция_байты)
        сам.assertEqual('намерение', квитанция['состояние'])
        сам.assertEqual(0, квитанция['процесс']['код'])
        сам.assertTrue(квитанция['процесс']['исполнение_завершено'])
        сам.assertNotIn('результат', квитанция)
        выбор = сам.каталог / 'выбор-повтора-после-ref.json'
        выбор.write_bytes(сам.м.байты(сам.выбор_базиса)); выбор.chmod(0o600)
        до = сам.снимок_базиса()
        загрузчик = ("import sys; from pathlib import Path; sys.path.insert(0,sys.argv.pop(1)); "
            "import создание_коммита as м; м.готовность.КОРЕНЬ_СОСТОЯНИЯ=Path(sys.argv.pop(1)); "
            "raise SystemExit(м.главная())")
        повтор = subprocess.run([sys.executable, '-I', '-S', '-B', '-c', загрузчик,
            str(ДОПУСК.parent), str(сам.каталог_готовности), 'создать', '--подготовка', сам.п['подготовка'],
            '--проверка', сам.проверка, '--доверенное-поручение', str(выбор)], capture_output=True, timeout=60)
        сам.assertEqual(2, повтор.returncode, повтор.stderr.decode()); сам.assertEqual(b'', повтор.stdout)
        отказ = json.loads(повтор.stderr)
        сам.assertEqual('fum.отказ-создания-коммита.1', отказ['схема'])
        сам.assertIn('Неизвестный исход', отказ['ошибка'])
        сам.assertEqual(квитанция_байты, путь.read_bytes()); сам.assertEqual(до, сам.снимок_базиса())


class СовместимостьОшибокСоздателя(unittest.TestCase):
    def test_отсутствующая_подготовка_сохраняет_публичный_тип_ошибки(сам):
        sys.path.insert(0,str(ДОПУСК.parent))
        import создание_коммита as м
        with tempfile.TemporaryDirectory() as п:
            файл=Path(п).resolve()/'нет.json'
            for действие in [lambda:м.создать(файл,[]),lambda:м.объявить_готовность(файл,[],10),
                    lambda:м.отозвать_готовность(файл,0,'Отрицательная проверка')]:
                with сам.assertRaises(м.ОшибкаКоммита): действие()


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == '--проверить-фикстурную-поставку':
        print(байты_описания(проверить_фикстурную_поставку(sys.argv[2], sys.argv[3])).decode(), end='')
    else:
        unittest.main()
