"""Ранний отказ полного плана и однократность канонического producer."""
import hashlib
import json
import os
import stat
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import захват_вывода as захват


class ПроверкаПланаВыходов(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        сам.задача = '00000000-0000-0000-0000-000000000356'
        сам.конфигурация = {'base': str(сам.корень), 'prefix': 'наблюдение',
            'cwd': str(сам.корень), 'argv': [sys.executable, '-B', '-c', 'pass']}

    def цель(сам, путь, роль='предмет', режим=0o400):
        return {'роль': роль, 'путь': str(путь), 'режим': режим}

    def запуск(сам, цели):
        return захват.наблюдать_процесс(сам.конфигурация, сам.задача,
            предметные_цели=цели, тайм_аут=5, предел_байтов=1048576)

    def снимок(сам):
        результат = {}
        for путь in сам.корень.rglob('*'):
            состояние = путь.lstat()
            данные = (os.readlink(путь) if stat.S_ISLNK(состояние.st_mode) else
                путь.read_bytes() if stat.S_ISREG(состояние.st_mode) else None)
            результат[путь.relative_to(сам.корень).as_posix()] = (
                состояние.st_mode, состояние.st_nlink, данные)
        return результат

    def отказ_до_процесса(сам, цели):
        до = сам.снимок()
        with patch.object(захват.subprocess, 'Popen') as процесс:
            with сам.assertRaises((ValueError, OSError)):
                сам.запуск(цели)
            процесс.assert_not_called()
        сам.assertEqual(до, сам.снимок())

    def test_каждый_зарезервированный_суффикс_отказывает_до_запуска(сам):
        for суффикс in ('.stdout', '.stderr', '.process', '.json'):
            with сам.subTest(суффикс=суффикс):
                сам.отказ_до_процесса([сам.цель(сам.корень / ('наблюдение' + суффикс))])

    def test_повторы_целей_ролей_и_нормализация_отказывают(сам):
        сам.корень.joinpath('подкаталог').mkdir()
        for цели in (
            [сам.цель(сам.корень/'результат'), сам.цель(сам.корень/'результат', 'другая')],
            [сам.цель(сам.корень/'первый'), сам.цель(сам.корень/'второй')],
            [сам.цель(сам.корень/'результат'), сам.цель(сам.корень/'подкаталог/../результат', 'другая')],
            [сам.цель(сам.корень/'Имя'), сам.цель(сам.корень/'имя', 'другая')],
            [сам.цель(сам.корень/'й'), сам.цель(сам.корень/'и\u0306', 'другая')],
            [сам.цель(сам.корень/'файл'), сам.цель(сам.корень/'файл/вложенный', 'другая')],
        ):
            with сам.subTest(цели=цели):
                сам.отказ_до_процесса(цели)

    def test_существующие_цели_каждой_роли_сохраняются(сам):
        for имя in ('наблюдение.stdout', 'наблюдение.stderr', 'наблюдение.process',
                    'наблюдение.json', 'предмет.json'):
            with сам.subTest(имя=имя):
                путь = сам.корень/имя
                путь.write_bytes(b'previous evidence')
                сам.отказ_до_процесса([сам.цель(сам.корень/'предмет.json')])
                путь.unlink()

    def test_символические_и_специальные_цели_не_открываются(сам):
        путь = сам.корень/'цель'
        путь.symlink_to(сам.корень/'отсутствует')
        сам.отказ_до_процесса([сам.цель(путь)])
        путь.unlink()
        os.mkfifo(путь)
        прежний = os.open
        def открыть(адрес, *аргументы, **параметры):
            if Path(адрес) == путь:
                raise AssertionError('FIFO не открывается через os.open')
            return прежний(адрес, *аргументы, **параметры)
        with patch.object(Path, 'open', side_effect=AssertionError('FIFO не открывается')), patch.object(os, 'open', side_effect=открыть):
            сам.отказ_до_процесса([сам.цель(путь)])

    def test_каждый_канонический_выход_и_каталог_зарезервированы(сам):
        каталог = сам.корень/'наблюдение.захват'
        for имя in ('', *захват.ВЫХОДЫ_ЗАХВАТА):
            with сам.subTest(имя=имя):
                сам.отказ_до_процесса([сам.цель(каталог/имя)])
        сам.отказ_до_процесса([сам.цель(каталог/'неизвестный-предмет')])
        сам.отказ_до_процесса([сам.цель(сам.корень/'другой', роль='захват:подмена')])

    def test_существующий_каталог_и_символьный_родитель_отказывают(сам):
        цель = сам.корень/'предмет'
        цель.mkdir()
        сам.отказ_до_процесса([сам.цель(цель)])
        ссылка = сам.корень/'ссылка'
        ссылка.symlink_to(цель, target_is_directory=True)
        сам.отказ_до_процесса([сам.цель(ссылка/'выход')])
        сам.отказ_до_процесса([сам.цель(ссылка/'../выход')])

    def test_отказ_каждого_резервирования_не_запускает_процесс(сам):
        for суффикс in захват.СУФФИКСЫ_НАБЛЮДАТЕЛЯ:
            with сам.subTest(суффикс=суффикс), tempfile.TemporaryDirectory() as временный:
                база = Path(временный).resolve()
                конфигурация = dict(сам.конфигурация, base=str(база))
                цель = база/('наблюдение.'+суффикс)
                прежний = os.open
                def открыть(путь, флаги, *аргументы, **параметры):
                    if Path(путь) == цель and флаги & os.O_CREAT:
                        # Имитируем появление файла после preflight; O_EXCL обязан
                        # сохранить новые байты и отказать до Popen.
                        цель.write_bytes(b'appeared after preflight')
                    return прежний(путь, флаги, *аргументы, **параметры)
                with patch.object(os, 'open', side_effect=открыть), patch.object(захват.subprocess, 'Popen') as процесс:
                    with сам.assertRaises(FileExistsError):
                        захват.наблюдать_процесс(конфигурация, сам.задача, предметные_цели=[])
                    процесс.assert_not_called()
                сам.assertEqual(цель.read_bytes(), b'appeared after preflight')

    def test_недопустимые_режимы_отказывают(сам):
        for режим in (0o644, 0o777, True, '0400', None):
            with сам.subTest(режим=режим):
                сам.отказ_до_процесса([сам.цель(сам.корень/'предмет', режим=режим)])

    def подготовить_производителя(сам):
        сам.счётчик = сам.корень/'счётчик'
        сам.предмет = сам.корень/'предмет.json'
        сам.конфигурация['argv'] = [sys.executable, '-B', '-c',
            'import os,pathlib,sys; '
            'дескриптор=os.open(sys.argv[1],os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600); '
            'os.write(дескриптор,b"one"); os.close(дескриптор); '
            'дескриптор=os.open(sys.argv[2],os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o400); '
            'os.write(дескриптор,"{\\"код\\":0}\\n".encode()); os.close(дескриптор); '
            'os.write(1, bytes(range(256))*1024); '
            'os.write(2, bytes(reversed(range(256)))*1024); '
            'raise SystemExit(7)', str(сам.счётчик), str(сам.предмет)]
        return [сам.цель(сам.счётчик, 'счётчик', 0o600), сам.цель(сам.предмет)]

    def test_положительный_план_один_процесс_сохраняет_оба_исхода(сам):
        цели = сам.подготовить_производителя()
        исходная = json.loads(json.dumps(сам.конфигурация))
        with patch.object(захват.subprocess, 'Popen', wraps=захват.subprocess.Popen) as процесс:
            результат = сам.запуск(цели)
            сам.assertEqual(процесс.call_count, 1)
        сам.assertEqual(сам.конфигурация, исходная)
        сам.assertEqual(сам.счётчик.read_bytes(), b'one')
        сам.assertEqual(json.loads(сам.предмет.read_bytes()), {'код': 0})
        сам.assertEqual(сам.счётчик.stat().st_mode & 0o777, 0o600)
        сам.assertEqual(сам.предмет.stat().st_mode & 0o777, 0o400)
        сам.assertEqual(результат['код_процесса'], 7)
        сам.assertTrue(результат['полнота'])
        сам.assertEqual(результат['схема'], 'fum.захват-вывода.2')
        _, прочитано = захват.прочитать_манифест(сам.корень/'наблюдение.захват', результат['манифест_sha256'])
        сам.assertEqual(прочитано, {к: з for к, з in результат.items() if к != 'манифест_sha256'})
        известный = захват.прочитать_наблюдение(сам.конфигурация, результат['манифест_sha256'])
        сам.assertEqual(известный['состояние'], 'завершено')
        сам.assertEqual(известный['результат'], прочитано)
        сам.assertFalse(известный['повтор_разрешён'])
        сам.assertEqual(захват.прочитать_наблюдение(сам.конфигурация)['состояние'], 'unknown')
        наблюдение = json.loads((сам.корень/'наблюдение.process').read_bytes())
        сам.assertEqual(наблюдение['argv'], исходная['argv'])
        сам.assertEqual(наблюдение['cwd'], исходная['cwd'])
        сам.assertEqual(наблюдение['pid'], результат['процесс']['pid'])
        сам.assertEqual(наблюдение['observer_pid'], os.getpid())
        время = результат['процесс']
        границы = [время[к] for к in ('подготовка_начата_нс', 'план_проверен_нс', 'перед_запуском_нс',
            'после_запуска_нс', 'процесс_и_потоки_завершены_нс', 'перед_финальной_записью_нс')]
        сам.assertEqual(границы, sorted(границы))
        for канал, данные in (('stdout', bytes(range(256))*1024),
                             ('stderr', bytes(reversed(range(256)))*1024)):
            путь = сам.корень/('наблюдение.'+канал)
            сам.assertEqual(путь.read_bytes(), данные)
            сам.assertEqual((сам.корень/'наблюдение.захват'/(канал+'.bin')).read_bytes(), данные)
            сам.assertEqual(путь.stat().st_mode & 0o777, 0o600)
            сам.assertEqual(результат['каналы'][канал]['sha256'], hashlib.sha256(данные).hexdigest())

    def test_неизвестный_исход_и_чтение_не_повторяют_процесс(сам):
        цели = сам.подготовить_производителя()
        прежнее = захват.сохранить
        def поздний_отказ(путь, данные):
            if путь.name == 'манифест-временный.json':
                raise OSError('поздний отказ диска')
            return прежнее(путь, данные)
        with patch.object(захват, 'сохранить', side_effect=поздний_отказ):
            with сам.assertRaises(OSError):
                сам.запуск(цели)
        до = сам.снимок()
        with patch.object(захват.subprocess, 'Popen') as процесс:
            with сам.assertRaises((ValueError, OSError)):
                сам.запуск(цели)
            первый = захват.прочитать_наблюдение(сам.конфигурация)
            второй = захват.прочитать_наблюдение(сам.конфигурация)
            процесс.assert_not_called()
        сам.assertEqual(первый, второй)
        сам.assertEqual(первый['состояние'], 'unknown')
        сам.assertFalse(первый['повтор_разрешён'])
        сам.assertIsNone(первый['результат'])
        сам.assertIsNotNone(первый['процесс'])
        for канал in ('stdout', 'stderr'):
            факт = первый['свидетельства']['наблюдатель:'+канал]
            данные = (сам.корень/('наблюдение.'+канал)).read_bytes()
            сам.assertEqual(факт['состояние'], 'обычный')
            сам.assertEqual(факт['байты'], 262144)
            сам.assertEqual(факт['sha256'], hashlib.sha256(данные).hexdigest())
        сам.assertEqual(сам.счётчик.read_bytes(), b'one')
        сам.assertEqual(до, сам.снимок())

    def test_авария_наблюдателя_до_PID_не_разрешает_свежий_запуск(сам):
        счётчик = сам.корень/'счётчик'
        освобождение = сам.корень/'освободить-фикстуру'
        окончание = сам.корень/'фикстура-завершена'
        диагностический_PID = сам.корень/'PID-фикстуры'
        сам.конфигурация['argv'] = [sys.executable, '-B', '-c',
            'import os,pathlib,sys,time; '
            'дескриптор=os.open(sys.argv[1],os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600); '
            'os.write(дескриптор,b"one"); os.close(дескриптор); '
            'граница=time.monotonic()+60; '
            '\nwhile not pathlib.Path(sys.argv[2]).exists() and time.monotonic()<граница: time.sleep(.01)\n'
            'дескриптор=os.open(sys.argv[3],os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600); '
            'os.write(дескриптор,b"done"); os.close(дескриптор)',
            str(счётчик), str(освобождение), str(окончание)]
        цели = [сам.цель(счётчик, 'счётчик', 0o600), сам.цель(окончание, 'окончание', 0o600)]
        общий = [str(Path(захват.__file__).parent), json.dumps(сам.конфигурация),
            сам.задача, json.dumps(цели)]
        обрыв = '''import json,os,pathlib,sys,time
sys.path.insert(0,sys.argv[1])
import захват_вывода as захват
конфигурация=json.loads(sys.argv[2]); цели=json.loads(sys.argv[4])
прежний=захват.subprocess.Popen
def прервать(*позиционные,**именованные):
    процесс=прежний(*позиционные,**именованные)
    pathlib.Path(sys.argv[5]).write_text(str(процесс.pid))
    граница=time.monotonic()+2
    while not pathlib.Path(sys.argv[6]).exists() and time.monotonic()<граница:
        time.sleep(.01)
    os._exit(91 if pathlib.Path(sys.argv[6]).exists() else 92)
захват.subprocess.Popen=прервать
захват.наблюдать_процесс(конфигурация,sys.argv[3],предметные_цели=цели,тайм_аут=4)
'''
        повтор = '''import json,sys
sys.path.insert(0,sys.argv[1])
import захват_вывода as захват
конфигурация=json.loads(sys.argv[2]); цели=json.loads(sys.argv[4])
def запрещённый_процесс(*позиционные,**именованные):
    raise RuntimeError('Producer повторён после неизвестного исхода')
захват.subprocess.Popen=запрещённый_процесс
try:
    захват.наблюдать_процесс(конфигурация,sys.argv[3],предметные_цели=цели,тайм_аут=4)
except (ValueError,OSError):
    pass
else:
    raise RuntimeError('Неизвестный исход разрешил повтор')
первый=захват.прочитать_наблюдение(конфигурация)
второй=захват.прочитать_наблюдение(конфигурация)
if первый!=второй or первый['состояние']!='unknown' or первый['повтор_разрешён']:
    raise RuntimeError('Чтение изменило неизвестный исход')
print(json.dumps(первый,ensure_ascii=False))
'''
        try:
            результат = subprocess.run([sys.executable, '-B', '-c', обрыв, *общий,
                str(диагностический_PID), str(счётчик)], capture_output=True, timeout=5)
            сам.assertEqual(результат.returncode, 91, результат.stderr)
            сам.assertEqual(счётчик.read_bytes(), b'one')
            сам.assertFalse(окончание.exists())
            сам.assertFalse((сам.корень/'наблюдение.захват/процесс.json').exists())
            сам.assertEqual((сам.корень/'наблюдение.process').read_bytes(), b'')
            сам.assertFalse((сам.корень/'наблюдение.захват/манифест.json').exists())
            до = сам.снимок()
            чтение = subprocess.run([sys.executable, '-B', '-c', повтор, *общий],
                capture_output=True, timeout=5)
            сам.assertEqual(чтение.returncode, 0, чтение.stderr)
            выдано = json.loads(чтение.stdout)
            сам.assertEqual(выдано['состояние'], 'unknown')
            сам.assertIsNone(выдано['процесс'])
            сам.assertIsNone(выдано['результат'])
            for канал in ('stdout', 'stderr'):
                факт = выдано['свидетельства']['наблюдатель:'+канал]
                сам.assertEqual(факт['состояние'], 'обычный')
                сам.assertEqual(факт['байты'], 0)
                сам.assertEqual(факт['sha256'], hashlib.sha256(b'').hexdigest())
            сам.assertFalse(окончание.exists())
            сам.assertEqual(до, сам.снимок())
        finally:
            import signal
            import time
            try:
                освобождение.write_bytes(b'release')
            finally:
                if диагностический_PID.exists():
                    идентификатор = int(диагностический_PID.read_text())
                    граница = time.monotonic()+2
                    завершён = False
                    while time.monotonic()<граница:
                        try:
                            группа = os.getpgid(идентификатор)
                        except ProcessLookupError:
                            завершён = True
                            break
                        сам.assertEqual(группа, идентификатор, 'Нельзя останавливать чужую группу')
                        if time.monotonic() > граница-1:
                            try:
                                os.killpg(идентификатор, signal.SIGKILL)
                            except ProcessLookupError:
                                завершён = True
                                break
                        time.sleep(.01)
                    сам.assertTrue(завершён, 'Прекращение fixture-процесса не подтверждено')

    def test_первая_схема_по_умолчанию_и_явная_вторая_без_экспорта(сам):
        первый, sha1 = захват.захватить_с_хэшем(сам.конфигурация['argv'],
            сам.корень/'первый', сам.корень, сам.задача)
        сам.assertEqual(первый['схема'], 'fum.захват-вывода.1')
        сам.assertNotIn('процесс', первый)
        сам.assertNotIn('экспорт', первый)
        сам.assertEqual(захват.прочитать_манифест(сам.корень/'первый', sha1)[1], первый)
        второй, sha2 = захват.захватить_с_хэшем(сам.конфигурация['argv'],
            сам.корень/'второй', сам.корень, сам.задача, предметные_цели=[])
        сам.assertEqual(второй['схема'], 'fum.захват-вывода.2')
        сам.assertIsNone(второй['экспорт'])
        сам.assertEqual(захват.прочитать_манифест(сам.корень/'второй', sha2)[1], второй)
        for имя, sha, схема in (('первый', sha1, '.1'), ('второй', sha2, '.2')):
            сам.assertEqual(json.loads(захват.представить_захват(сам.корень/имя, sha, 16000))['схема'], 'fum.представление-захвата'+схема)
        for поле, значение in (('pid', True), ('перед_запуском_нс', -1), ('после_запуска_нс', None)):
            испорченный = json.loads(json.dumps(второй))
            испорченный['процесс'][поле] = значение
            with сам.assertRaises(ValueError):
                захват.проверить_манифест(испорченный)
        for исходный in (первый, второй):
            испорченный = dict(исходный, лишнее=True)
            with сам.assertRaises(ValueError):
                захват.проверить_манифест(испорченный)

    def test_изменённый_экспорт_не_принимается_терминальным_читателем(сам):
        цели = сам.подготовить_производителя()
        результат = сам.запуск(цели)
        путь = сам.корень/'наблюдение.stdout'
        путь.write_bytes(b'tampered')
        with сам.assertRaises(ValueError):
            захват.прочитать_наблюдение(сам.конфигурация, результат['манифест_sha256'])
        неизвестный = захват.прочитать_наблюдение(сам.конфигурация)
        сам.assertEqual(неизвестный['состояние'], 'unknown')
        сам.assertEqual(неизвестный['свидетельства']['наблюдатель:stdout']['байты'], 8)

    def test_новый_CLI_сохраняет_argv_и_не_повторяет_неизвестное(сам):
        цели = сам.подготовить_производителя()
        сам.конфигурация['argv'] += ['пробел ; $() буквальный аргумент']
        конфиг = сам.корень/'вход.json'
        конфиг.write_bytes(захват.закодировать(сам.конфигурация))
        предметные = сам.корень/'цели.json'
        предметные.write_bytes(захват.закодировать(цели))
        cli = Path(захват.__file__).with_name('наблюдать-процесс.py')
        общий = [sys.executable, '-B', str(cli), str(конфиг)]
        первый = subprocess.run([*общий, '--задача', сам.задача,
            '--предметные-цели', str(предметные)], capture_output=True, timeout=5)
        сам.assertEqual(первый.returncode, 0, первый.stderr)
        результат = json.loads(первый.stdout)
        сам.assertEqual(результат['код_процесса'], 7)
        сам.assertEqual(первый.stderr, b'')
        неизвестный = subprocess.run([*общий, '--прочитать'], capture_output=True, timeout=5)
        сам.assertEqual(неизвестный.returncode, 0, неизвестный.stderr)
        сам.assertEqual(json.loads(неизвестный.stdout)['состояние'], 'unknown')
        известный = subprocess.run([*общий, '--прочитать', '--sha256', результат['манифест_sha256']], capture_output=True, timeout=5)
        сам.assertEqual(известный.returncode, 0, известный.stderr)
        сам.assertEqual(json.loads(известный.stdout)['состояние'], 'завершено')
        до = сам.снимок()
        повтор = subprocess.run([*общий, '--задача', сам.задача,
            '--предметные-цели', str(предметные)], capture_output=True, timeout=5)
        сам.assertEqual(повтор.returncode, 2)
        сам.assertFalse(json.loads(повтор.stdout)['retry'])
        сам.assertEqual(сам.счётчик.read_bytes(), b'one')
        сам.assertEqual(до, сам.снимок())

    def test_строгий_читатель_не_приравнивает_float_к_PID(сам):
        каталог = сам.корень/'строгий'
        результат, sha = захват.захватить_с_хэшем(сам.конфигурация['argv'], каталог,
            сам.корень, сам.задача, предметные_цели=[])
        путь = каталог/'процесс.json'
        процесс = json.loads(путь.read_bytes())
        процесс['pid'] = float(процесс['pid'])
        путь.write_bytes(захват.закодировать(процесс))
        with сам.assertRaises(ValueError):
            захват.прочитать_манифест(каталог, sha)

    def test_строгий_читатель_отклоняет_невозможный_вызов(сам):
        каталог = сам.корень/'строгий'
        результат, _ = захват.захватить_с_хэшем(сам.конфигурация['argv'], каталог,
            сам.корень, сам.задача, предметные_цели=[])
        исходный = json.loads((каталог/'вызов.json').read_bytes())
        for ключ, значение in (('оболочка', True), ('автоматический_повтор', True),
                ('тайм_аут', False), ('предел_байтов', True), ('команда', ['bad\0arg']),
                ('обработчик', 'неизвестен'), ('корень', 'relative')):
            with сам.subTest(ключ=ключ):
                вызов = dict(исходный)
                вызов[ключ] = значение
                данные = захват.закодировать(вызов)
                (каталог/'вызов.json').write_bytes(данные)
                манифест = dict(результат, вызов_sha256=hashlib.sha256(данные).hexdigest())
                данные = захват.закодировать(манифест)
                (каталог/'манифест.json').write_bytes(данные)
                with сам.assertRaises(ValueError):
                    захват.прочитать_манифест(каталог, hashlib.sha256(данные).hexdigest())

    def test_профиль_проверяет_свой_выход_до_процесса(сам):
        import runpy
        модуль = runpy.run_path(str(Path(__file__).with_name('профиль_плана_выходов.py')))
        путь = сам.корень/'готовый-профиль.json'
        путь.write_bytes(b'previous profile')
        до = сам.снимок()
        with patch.object(sys, 'argv', ['профиль', '--выход', str(путь)]), patch.object(
                захват.subprocess, 'Popen', side_effect=AssertionError('Ранний producer')) as процесс:
            with сам.assertRaises(FileExistsError):
                модуль['выполнить']()
            процесс.assert_not_called()
        сам.assertEqual(до, сам.снимок())

    def test_null_не_заменяет_обязательный_предметный_план(сам):
        import runpy
        for имя in ('API', 'наблюдать-процесс.py', 'захватить-вывод.py'):
            with сам.subTest(имя=имя), tempfile.TemporaryDirectory() as временный:
                база = Path(временный).resolve()
                конфигурация = dict(сам.конфигурация, base=str(база), cwd=str(база))
                вход = база/'вход.json'
                вход.write_bytes(захват.закодировать(конфигурация))
                цели = база/'цели.json'
                цели.write_bytes(b'null\n')
                до = {п.name: п.read_bytes() for п in база.iterdir()}
                with patch.object(захват.subprocess, 'Popen', side_effect=AssertionError('Producer с неизвестным планом')) as процесс:
                    if имя == 'API':
                        with сам.assertRaises(ValueError):
                            захват.наблюдать_процесс(конфигурация, сам.задача, предметные_цели=None)
                    else:
                        cli = runpy.run_path(str(Path(захват.__file__).with_name(имя)))['выполнить']
                        аргументы = ([str(вход), '--задача', сам.задача, '--предметные-цели', str(цели)]
                            if имя == 'наблюдать-процесс.py' else ['--каталог', str(база/'захват'),
                                'запустить', '--корень', str(база), '--задача', сам.задача,
                                '--предметные-цели', str(цели), '--', *конфигурация['argv']])
                        with patch.dict(cli.__globals__, записать=lambda *а: None):
                            сам.assertEqual(cli(аргументы), 2)
                    процесс.assert_not_called()
                сам.assertEqual({п.name: п.read_bytes() for п in база.iterdir()}, до)


if __name__ == '__main__':
    unittest.main()
