"""Независимые Git-фикстуры фиксированного предметного индекса базиса."""
import hashlib
import importlib.util
import json
import os
import signal
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
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


if __name__ == '__main__':
    unittest.main()
