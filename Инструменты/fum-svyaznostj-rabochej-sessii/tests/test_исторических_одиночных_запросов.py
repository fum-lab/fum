"""Отсутствие отчёта доказывается полным деревом и выбранным перечнем."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from исторические_одиночные_запросы import прочитать
from независимый_индекс_журнала import построить_индекс
from test_независимой_пары_и_индекса import НезависимаяПараИИндекс, состав


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def канон(значение):
    return json.dumps(значение, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()


ОДИНОЧНЫЙ = 'fum.исторический-одиночный-запрос-журнала.1'


class ИсторическийИндекс(unittest.TestCase):
    def поколение(сам):
        _, _, записи, файлы = НезависимаяПараИИндекс()._поколение()
        старая = copy.deepcopy(записи[0]); старая['формат'] = ОДИНОЧНЫЙ
        отчёт = старая['файлы'].pop(); del файлы[отчёт['путь']]
        старый_парный = copy.deepcopy(записи[0])
        старый_парный['журнал'] = '2026-07-03_11-14-15_MSK'
        старый_парный['идентификатор'] = 'a' * 64
        старый_парный['заголовок'] = 'Старая пара'
        for ф in старый_парный['файлы']:
            прежний = ф['путь']; ф['путь'] = прежний.replace('2026-07-02', '2026-07-03')
            файлы[ф['путь']] = (b'# old request\n' if прежний.endswith('/запрос.md') else b'# old report\n')
            ф['sha256'] = хэш(файлы[ф['путь']])
        c = {'схема': 'fum.состав-независимого-журнала.2', 'записи': [старая, старый_парный, записи[1]]}
        return c, файлы

    def вычислить(сам, с, ф):
        ожидаемый = хэш(канон({**с, 'записи': sorted(с['записи'], key=lambda з: з['журнал'])}))
        return построить_индекс(с, ф, ожидаемый_sha256=ожидаемый)

    def test_три_формата_точные_соседи_и_отсутствие_ссылки_отчёта(сам):
        с, ф = сам.поколение(); исходные = copy.deepcopy(ф)
        итог = сам.вычислить(с, ф); текст = итог['байты'].decode()
        сам.assertIn('<!-- FUM-ИНДЕКС-ЖУРНАЛА: 2 -->', текст)
        строки = [x for x in текст.splitlines() if x.startswith('| ')][2:]
        сам.assertEqual(len(строки), 3)
        сам.assertEqual(строки[0], '| Историческая запись | [перейти](../Журнал/2026-07-02_11-14-15_MSK/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md) | Историческая запись без отдельного отчёта | — | [перейти](../Журнал/2026-07-03_11-14-15_MSK/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md) |')
        сам.assertEqual(сам.вычислить({**с, 'записи': list(reversed(с['записи']))}, ф), итог)
        сам.assertEqual(ф, исходные); сам.assertFalse(итог['разрешение_установки'])

    def test_первая_версия_сохранена_побайтно(сам):
        _, _, з, ф = НезависимаяПараИИндекс()._поколение(); с, ш = состав(з)
        сам.assertEqual(построить_индекс(с, ф, ожидаемый_sha256=ш)['sha256'], '50bfadf2a54e1f7eca485086ce08f76b407a9296c5154afd8fcb6b9e41157e0b')

    def test_одиночный_не_допускается_первой_версией(сам):
        с, ф = сам.поколение(); с['схема'] = 'fum.состав-независимого-журнала.1'
        with сам.assertRaises(ValueError): сам.вычислить(с, ф)

    def test_неизвестное_поколение_неполная_пара_и_лишний_отчёт(сам):
        for нарушение in ('схема', 'формат', 'старая пара', 'новая пара', 'лишний отчёт', 'лишнее поле'):
            с, ф = сам.поколение()
            if нарушение == 'схема': с['схема'] = 'fum.состав-независимого-журнала.99'
            if нарушение == 'формат': с['записи'][0]['формат'] += '.99'
            if нарушение == 'старая пара': с['записи'][1]['файлы'].pop()
            if нарушение == 'новая пара': с['записи'][2]['файлы'].pop()
            if нарушение == 'лишний отчёт': ф['Журнал/2026-07-02_11-14-15_MSK/отчёт.md'] = b'present'
            if нарушение == 'лишнее поле': с['записи'][0]['отсутствует'] = True
            with сам.subTest(нарушение=нарушение), сам.assertRaises(ValueError): сам.вычислить(с, ф)


class ЧитающееИсторическоеДоказательство(unittest.TestCase):
    def setUp(сам):
        сам.tmp = tempfile.TemporaryDirectory(); сам.addCleanup(сам.tmp.cleanup)
        сам.r = Path(сам.tmp.name).resolve()
        сам.git('init', '-q')
        сам.путь = 'Журнал/2026-06-21_22-17-26_MSK/запрос.md'
        п = сам.r / сам.путь; п.parent.mkdir(parents=True); п.write_bytes('# Прежняя запись\n\nИсходная команда с ё.\n'.encode())
        сам.база = сам.коммит()
        сам.м = {'схема': 'fum.исторические-одиночные-запросы-журнала.1',
                 'исходный_коммит': сам.база, 'записи': [{'путь': сам.путь, 'sha256': хэш(п.read_bytes()), 'режим': 0o644}]}

    def git(сам, *аргументы, вход=None):
        env = os.environ.copy()
        for к in ('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR', 'GIT_NAMESPACE', 'GIT_OBJECT_DIRECTORY', 'GIT_ALTERNATE_OBJECT_DIRECTORIES'):
            env.pop(к, None)
        return subprocess.check_output(['git', '-C', str(сам.r), '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgsign=false', '-c', 'user.name=Тест', '-c', 'user.email=test@example.invalid', *аргументы], env=env, stderr=subprocess.PIPE, input=вход)

    def коммит(сам):
        сам.git('add', '--all'); сам.git('commit', '-qm', 'Фикстура')
        return сам.git('rev-parse', 'HEAD').decode().strip()

    def прочитать(сам, м=None, c=None, *, checkout=False):
        б = канон(сам.м if м is None else м)
        return прочитать(сам.r, б, ожидаемый_sha256=хэш(б), текущий_коммит=c or сам.база, checkout=checkout)

    def test_точный_повтор_с_проверкой_checkout_без_изменения_индекса(сам):
        до = сам.git('ls-files', '--stage', '-z')
        а = сам.прочитать(checkout=True); б = сам.прочитать(checkout=True)
        сам.assertEqual(а, б); сам.assertEqual(до, сам.git('ls-files', '--stage', '-z'))
        сам.assertFalse(а['разрешение_установки']); сам.assertEqual(а['запросов'], 1)
        сам.assertEqual(а['одиночных'], [сам.путь])

    def test_изменённый_или_удалённый_запрос_и_новая_одиночная_запись(сам):
        for вид in ('изменён', 'удалён', 'новый'):
            (сам.r/сам.путь).write_bytes(сам.git('show', сам.база+':'+сам.путь))
            if вид == 'изменён': (сам.r/сам.путь).write_bytes(b'changed')
            if вид == 'удалён': (сам.r/сам.путь).unlink()
            if вид == 'новый':
                п=сам.r/'Журнал/2026-06-22_22-17-26_MSK/запрос.md';п.parent.mkdir();п.write_bytes(b'new')
            с=сам.коммит()
            with сам.subTest(вид=вид), сам.assertRaises(ValueError): сам.прочитать(c=с)

    def test_пропуск_лишняя_цель_подмена_манифеста_неизвестная_версия(сам):
        for вид in ('пропуск', 'лишняя', 'байты', 'режим', 'версия', 'поле'):
            м=copy.deepcopy(сам.м)
            if вид=='пропуск': м['записи']=[]
            if вид=='лишняя': м['записи'].append({**м['записи'][0], 'путь':'Журнал/2026-06-22_22-17-26_MSK/запрос.md'})
            if вид=='байты': м['записи'][0]['sha256']='f'*64
            if вид=='режим': м['записи'][0]['режим']=True
            if вид=='версия': м['схема']+='неизвестна'
            if вид=='поле': м['разрешение']=True
            with сам.subTest(вид=вид), сам.assertRaises(ValueError): сам.прочитать(м)
        б=канон(сам.м)
        with сам.assertRaises(ValueError): прочитать(сам.r,б,ожидаемый_sha256='0'*64,текущий_коммит=сам.база)

    def test_существующий_отчёт_нельзя_скрыть_во_входе(сам):
        п=(сам.r/сам.путь).with_name('отчёт.md');п.write_bytes(b'report');с=сам.коммит()
        with сам.assertRaises(ValueError): сам.прочитать(c=с)

    def test_checkout_отчёт_пустой_каталог_symlink_и_регистр(сам):
        папка=(сам.r/сам.путь).parent
        for вид in ('пустой', 'каталог', 'symlink', 'регистр'):
            п=папка/('ОТЧЁТ.md' if вид=='регистр' else 'отчёт.md')
            if вид in ('пустой','регистр'): п.write_bytes(b'')
            if вид=='каталог': п.mkdir()
            if вид=='symlink': п.symlink_to('несуществующий')
            try:
                with сам.subTest(вид=вид), сам.assertRaises(ValueError): сам.прочитать(checkout=True)
            finally:
                if вид=='каталог': п.rmdir()
                else: п.unlink()

    def test_git_отчёт_symlink_и_каталог_тоже_существуют(сам):
        п=(сам.r/сам.путь).with_name('отчёт.md');п.symlink_to('несуществующий');с=сам.коммит()
        with сам.assertRaises(ValueError): сам.прочитать(c=с)
        п.unlink();п.mkdir();(п/'дочерний').write_bytes(b'x');с=сам.коммит()
        with сам.assertRaises(ValueError): сам.прочитать(c=с)

    def test_checkout_подмена_запроса_и_несовпадение_HEAD(сам):
        п=сам.r/сам.путь;исходные=п.read_bytes();п.write_bytes(b'changed')
        with сам.assertRaises(ValueError): сам.прочитать(checkout=True)
        п.write_bytes(исходные);(сам.r/'другой').write_bytes(b'x');сам.коммит()
        with сам.assertRaises(ValueError): сам.прочитать(checkout=True)

    def test_отсутствующий_promisor_blob_не_скачивается_при_чтении(сам):
        сам.git('config', 'uploadpack.allowFilter', 'true')
        читатель = сам.r / 'читатель'
        сам.git('clone', '-q', '--no-local', '--no-checkout', '--filter=blob:none', сам.r.as_uri(), str(читатель))
        blob = сам.git('rev-parse', сам.база + ':' + сам.путь).decode().strip()
        среда = {к: з for к, з in os.environ.items() if not к.startswith('GIT_')}
        среда['GIT_NO_LAZY_FETCH'] = '1'
        отсутствует = subprocess.run(['git', '-C', str(читатель), 'cat-file', '-e', blob], env=среда, capture_output=True)
        сам.assertNotEqual(отсутствует.returncode, 0)
        objects = читатель / '.git/objects'
        def снимок():
            return {str(п.relative_to(objects)): п.read_bytes() for п in objects.rglob('*') if п.is_file()}
        до = снимок(); м = канон(сам.м)
        with сам.assertRaises(ValueError):
            прочитать(читатель, м, ожидаемый_sha256=хэш(м), текущий_коммит=сам.база)
        сам.assertEqual(до, снимок())

    def test_пустое_Git_дерево_отчёта_и_его_двойник_не_означают_отсутствие(сам):
        пустое = сам.git('mktree', вход=b'').strip()
        blob = сам.git('rev-parse', сам.база + ':' + сам.путь).strip()
        for имя in ('отчёт.md', 'ОТЧЁТ.md'):
            папка = сам.git('mktree', вход=b'100644 blob ' + blob + '\tзапрос.md\n'.encode()
                + b'040000 tree ' + пустое + ('\t' + имя + '\n').encode()).strip()
            журнал = сам.git('mktree', вход=b'040000 tree ' + папка + b'\t2026-06-21_22-17-26_MSK\n').strip()
            дерево = сам.git('mktree', вход=b'040000 tree ' + журнал + '\tЖурнал\n'.encode()).strip()
            коммит = сам.git('commit-tree', дерево.decode(), '-p', сам.база, вход=b'Empty report fixture\n').decode().strip()
            with сам.subTest(имя=имя), сам.assertRaises(ValueError): сам.прочитать(c=коммит)

    def test_изменение_atime_от_чтения_не_означает_подмену(сам):
        настоящий = os.fstat
        def с_новым_atime(fd):
            з = настоящий(fd)
            return SimpleNamespace(**{n: getattr(з, n) for n in dir(з) if n.startswith('st_')})
        def изменённый(fd):
            з = с_новым_atime(fd); з.st_atime += 1; з.st_atime_ns += 1_000_000_000
            return з
        with patch('исторические_одиночные_запросы.os.fstat', side_effect=изменённый):
            сам.assertTrue(сам.прочитать(checkout=True)['checkout_проверен'])


if __name__ == '__main__':
    unittest.main()
