"""Быстрые реальные процессы: точные каналы, отказ и ограниченная остановка."""
import contextlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
import допуск_независимого_контура as допуск

from фикстура_контура import наблюдать_процесс, УдержаниеСтенда, КаталогСтенда


class НаблюдениеПроцесса(unittest.TestCase):
    def setUp(сам):
        временный = tempfile.TemporaryDirectory(prefix='fum-наблюдение-тест-')
        сам.addCleanup(временный.cleanup)
        сам.каталог = Path(временный.name).resolve()
        сам.работник = сам.каталог / 'работник.py'
        сам.работник.write_text("import os,sys,time\nos.write(1,bytes.fromhex(sys.argv[1]))\nos.write(2,bytes.fromhex(sys.argv[2]))\ntime.sleep(float(sys.argv[3]))\nsys.exit(int(sys.argv[4]))\n")
        сам.вывод = b'\x00\xffstdout\n' * 31
        сам.ошибки = b'\x00\xfestderr\n' * 29

    def команда(сам, пауза, код):
        return [sys.executable, '-I', '-S', '-B', str(сам.работник),
            сам.вывод.hex(), сам.ошибки.hex(), str(пауза), str(код)]

    def test_код_7_и_оба_бинарных_канала_сохраняются(сам):
        доказательства = сам.каталог / 'свидетельства'; доказательства.mkdir(mode=0o700)
        р = наблюдать_процесс(сам.команда(0, 7), cwd=сам.каталог, предел=2, свидетельства=доказательства)
        сам.assertEqual((7, сам.вывод, сам.ошибки), (р.returncode, р.stdout, р.stderr))
        сам.assertGreater(р.процесс, 0)

    def test_таймаут_оставляет_точные_устойчивые_каналы_до_cleanup(сам):
        доказательства = сам.каталог / 'свидетельства'; доказательства.mkdir(mode=0o700)
        начало = time.monotonic()
        with сам.assertRaises(subprocess.TimeoutExpired) as пойманный:
            наблюдать_процесс(сам.команда(60, 0), cwd=сам.каталог, предел=0.25,
                свидетельства=доказательства)
        сам.assertLess(time.monotonic() - начало, 3)
        наблюдение = getattr(пойманный.exception, 'наблюдение', {})
        сам.assertEqual('fum.наблюдение-лабораторного-процесса.1', наблюдение.get('схема'),
            'настоящий timeout потерял устойчивое наблюдение процесса и каналов')
        for имя, ожидаемые in [('stdout', сам.вывод), ('stderr', сам.ошибки)]:
            запись = наблюдение['каналы'][имя]
            сам.assertEqual(ожидаемые, Path(запись['путь']).read_bytes())
        сам.assertEqual(наблюдение, json.loads((доказательства / 'наблюдение.json').read_bytes()))
        сам.assertTrue(наблюдение['корень_остановлен'])
        сам.assertFalse(наблюдение['все_потомки_остановлены'])

    def test_преграда_не_теряет_диагностику_и_не_сдвигает_запись_ребёнка(сам):
        событие = (json.dumps({'схема': 'fum.событие-независимого-контура.1',
            'событие': 'guard-готов'}, ensure_ascii=False) + '\n').encode()
        префикс = событие + 'FUM-ПРЕГРАДА-ПОСЛЕ-СВЕРКИ\n'.encode()
        сам.работник.write_text(r"""import os,sys
os.write(2,bytes.fromhex(sys.argv[1]))
assert sys.stdin.readline()=='продолжить\n'
os.write(1,b'OK')
os.write(2,b'END\n')
""")
        вызовы = []
        доказательства = сам.каталог / 'свидетельства'; доказательства.mkdir(mode=0o700)
        р = наблюдать_процесс([sys.executable, '-I', '-S', '-B', str(сам.работник), префикс.hex()],
            cwd=сам.каталог, предел=2, преграда=lambda: вызовы.append(1), свидетельства=доказательства)
        сам.assertEqual([1], вызовы)
        сам.assertEqual((0, b'OK', префикс + b'END\n'), (р.returncode, р.stdout, р.stderr))

    def test_исключение_callback_сохраняется_и_удерживает_оба_каталога(сам):
        сам.работник.write_text(r"""import os,sys,time
os.write(2,'FUM-ПРЕГРАДА-ПОСЛЕ-СВЕРКИ\n'.encode())
assert not sys.stdin.readline()
time.sleep(60)
""")
        ошибка = RuntimeError('первичный callback'); удержание = УдержаниеСтенда()
        доказательства = сам.каталог / 'свидетельства'; доказательства.mkdir(mode=0o700)
        вызовы = []
        def отказ():
            вызовы.append(1); raise ошибка
        with КаталогСтенда(удержание, dir=сам.каталог) as k, КаталогСтенда(удержание, dir=сам.каталог) as w:
            with сам.assertRaises(RuntimeError) as пойманный:
                наблюдать_процесс([sys.executable, '-I', '-S', '-B', str(сам.работник)],
                    cwd=сам.каталог, предел=2, преграда=отказ,
                    свидетельства=доказательства, при_отказе=удержание.авария)
        сам.assertIs(ошибка, пойманный.exception); сам.assertEqual([1], вызовы)
        сам.assertTrue(Path(k).is_dir() and Path(w).is_dir())
        сам.assertEqual({'удержан'}, set(удержание.каталоги.values()))
        сам.assertEqual('FUM-ПРЕГРАДА-ПОСЛЕ-СВЕРКИ\n'.encode(),
            Path(ошибка.наблюдение['каналы']['stderr']['путь']).read_bytes())

    def test_отделившийся_потомок_не_задерживает_возврат_на_EOF(сам):
        сам.работник.write_text(r"""import os,sys,subprocess,time
p=subprocess.Popen([sys.executable,'-I','-S','-B','-c','import time;time.sleep(60)'],start_new_session=True)
os.write(2,(str(p.pid)+'\n').encode())
time.sleep(60)
""")
        доказательства = сам.каталог / 'свидетельства'; доказательства.mkdir(mode=0o700)
        потомок = None; начало = time.monotonic()
        try:
            with сам.assertRaises(subprocess.TimeoutExpired) as пойманный:
                наблюдать_процесс([sys.executable, '-I', '-S', '-B', str(сам.работник)],
                    cwd=сам.каталог, предел=0.5, свидетельства=доказательства)
            сам.assertLess(time.monotonic() - начало, 3)
            наблюдение = пойманный.exception.наблюдение
            потомок = int(Path(наблюдение['каналы']['stderr']['путь']).read_bytes())
            сам.assertGreater(потомок, 1); сам.assertEqual(потомок, os.getpgid(потомок))
            сам.assertTrue(наблюдение['корень_остановлен'])
            сам.assertFalse(наблюдение['все_потомки_остановлены'])
        finally:
            if потомок is not None:
                with contextlib.suppress(ProcessLookupError): os.killpg(потомок, signal.SIGKILL)

    def test_терминал_настоящего_Popen_фиксируется_один_раз(сам):
        строки = []
        def писать(д, сырые):
            сам.assertEqual(2, д); строки.append(сырые); return len(сырые)
        диагностика = допуск.ДиагностикаПроцессов('cli', включено=True, писать=писать)
        номер = диагностика.намерение()
        with subprocess.Popen(сам.команда(0, 7), stdout=subprocess.PIPE, stderr=subprocess.PIPE) as п:
            р = диагностика.наблюдать(п, номер)
            сам.assertIs(п, р)
            сам.assertEqual((сам.вывод, сам.ошибки), р.communicate(timeout=2))
            сам.assertEqual(7, р.wait(timeout=2)); сам.assertEqual(7, р.poll())
        события = [json.loads(з) for з in строки]
        сам.assertEqual(['процесс-намерение', 'процесс-запущен', 'группа-наблюдена', 'процесс-завершён'],
            [з['событие'] for з in события])
        сам.assertEqual((п.pid, 7), (события[-1]['потомок'], события[-1]['код']))

    def test_отказ_поздней_сверки_не_вызывает_Popen(сам):
        к = object.__new__(допуск.ПроверенныйКонтур)
        строки = []
        к.диагностика = допуск.ДиагностикаПроцессов('cli', включено=True,
            писать=lambda д, б: (строки.append(б), len(б))[1])
        ошибка = ValueError('поздний дрейф')
        к.сверить = mock.Mock(side_effect=ошибка); к.сырой_запуск = mock.Mock()
        with сам.assertRaises(ValueError) as пойманный:
            к.запуск_процесса(сам.команда(0, 0))
        сам.assertIs(ошибка, пойманный.exception); к.сырой_запуск.assert_not_called()
        сам.assertEqual(['процесс-намерение', 'процесс-отказ'],
            [json.loads(з)['событие'] for з in строки])

    def test_повреждённый_или_неполный_профиль_не_принимается(сам):
        from профиль_контура import собрать_метрики
        from types import SimpleNamespace
        for сырые in (b'{"schema":', b'{}\n', b'\xff\n'):
            with сам.subTest(сырые=сырые), сам.assertRaises((ValueError, UnicodeError)):
                собрать_метрики(SimpleNamespace(args=['--этап', 'выполнить'],
                    процесс=os.getpid(), returncode=0, stdout=b'', stderr=сырые))

    def test_ошибка_сохранения_после_exit_удерживает_каталог_и_второй_канал(сам):
        import фикстура_контура as фикстура
        доказательства = сам.каталог / 'свидетельства'; доказательства.mkdir(mode=0o700)
        удержание = УдержаниеСтенда(); исходный = os.fsync; число = 0
        def сбой(д):
            nonlocal число
            число += 1
            if число == 7: raise OSError('контроль fsync после настоящего wait')
            return исходный(д)
        with КаталогСтенда(удержание, dir=сам.каталог) as корень:
            with mock.patch.object(фикстура.os, 'fsync', side_effect=сбой):
                with сам.assertRaisesRegex(OSError, 'контроль fsync') as пойманный:
                    наблюдать_процесс(сам.команда(0, 0), cwd=сам.каталог, предел=2,
                        свидетельства=доказательства, при_отказе=удержание.авария)
        сам.assertTrue(Path(корень).is_dir())
        сам.assertEqual(сам.ошибки, Path(пойманный.exception.наблюдение['каналы']['stderr']['путь']).read_bytes())
        сам.assertTrue((доказательства / 'наблюдение.json').is_file())

    def test_отказ_диагностики_не_меняет_exit7_и_таймаут_ожидания(сам):
        диагностика = допуск.ДиагностикаПроцессов('cli', включено=True,
            писать=mock.Mock(side_effect=OSError('диагностика недоступна')))
        with subprocess.Popen(сам.команда(0.15, 7), stdout=subprocess.PIPE, stderr=subprocess.PIPE) as п:
            р = диагностика.наблюдать(п, диагностика.намерение())
            with сам.assertRaises(subprocess.TimeoutExpired): р.wait(timeout=0.01)
            сам.assertEqual((сам.вывод, сам.ошибки), р.communicate(timeout=2))
            сам.assertEqual(7, р.poll())
        сам.assertTrue(диагностика.потеря)

    def test_настоящий_D1_CLI_выдаёт_границы_в_приватный_stderr(сам):
        from фикстура_контура import полный_стенд
        from профиль_контура import собрать_метрики
        with полный_стенд() as стенд:
            р = стенд['процесс']('cli', преграда=lambda: None, диагностика=True)
            сам.assertEqual(0, р.returncode, р.stderr.decode(errors='replace'))
            события = []
            for строка in р.stderr.splitlines():
                if строка.startswith(b'{'):
                    з = json.loads(строка)
                    if з.get('схема') == 'fum.событие-независимого-контура.1': события.append(з)
            имена = [з['событие'] for з in события]
            for имя in ('guard-готов', 'D-начало', 'D-конец', 'CLI-начало', 'CLI-конец',
                'процесс-намерение', 'процесс-запущен', 'процесс-завершён', 'stdout-начало', 'stdout-конец'):
                сам.assertIn(имя, имена)
            сам.assertLess(имена.index('D-начало'), имена.index('D-конец'))
            сам.assertEqual(1, len(собрать_метрики(р)))
            сам.assertEqual('проверено', json.loads(р.stdout)['данные'])

    def test_отказ_getpgid_после_настоящего_Popen_сохраняет_PID_и_каналы(сам):
        import фикстура_контура as фикстура
        доказательства = сам.каталог / 'свидетельства'; доказательства.mkdir(mode=0o700)
        удержание = УдержаниеСтенда(); ошибка = OSError(5, 'контроль отказа getpgid')
        настоящий = subprocess.Popen; pids = []
        def запустить(*а, **к):
            п = настоящий(*а, **к); pids.append(п.pid); return п
        def группа(pid):
            сам.assertEqual(pids[-1], pid)
            дедлайн = time.monotonic() + 2
            while time.monotonic() < дедлайн:
                if all((доказательства / (имя + '-поток.bin')).stat().st_size >= len(сырые)
                    for имя, сырые in [('stdout', сам.вывод), ('stderr', сам.ошибки)]): break
                time.sleep(0.005)
            else: сам.fail('настоящий работник не выдал оба канала перед APIerror')
            raise ошибка
        with КаталогСтенда(удержание, dir=сам.каталог) as корень:
            with mock.patch.object(фикстура.subprocess, 'Popen', side_effect=запустить), \
                mock.patch.object(фикстура.os, 'getpgid', side_effect=группа), \
                mock.patch.object(фикстура.os, 'killpg') as групповая_остановка:
                with сам.assertRaises(OSError) as пойманный:
                    наблюдать_процесс(сам.команда(60, 0), cwd=сам.каталог, предел=2,
                        свидетельства=доказательства, при_отказе=удержание.авария)
        сам.assertIs(ошибка, пойманный.exception)
        н = ошибка.наблюдение
        сам.assertEqual(pids[0], н['процесс'], 'успешный Popen потерял фактический PID при getpgid error')
        сам.assertEqual(pids[0], json.loads((доказательства / 'процесс.json').read_bytes())['процесс'])
        сам.assertIsNone(н['группа']); сам.assertEqual('неизвестна', н['состояние_группы'])
        сам.assertIn('контроль отказа getpgid', н['ошибка_группы']); групповая_остановка.assert_not_called()
        сам.assertTrue(н['корень_остановлен']); сам.assertEqual(-signal.SIGKILL, н['код'])
        сам.assertTrue(Path(корень).is_dir())
        for имя, сырые in [('stdout', сам.вывод), ('stderr', сам.ошибки)]:
            сам.assertEqual(сырые, Path(н['каналы'][имя]['путь']).read_bytes())

    def test_диагностический_getpgid_не_стирает_настоящий_PID_и_terminal(сам):
        строки = []
        диагностика = допуск.ДиагностикаПроцессов('cli', включено=True,
            писать=lambda д, б: (строки.append(б), len(б))[1])
        with subprocess.Popen(сам.команда(0, 7), stdout=subprocess.PIPE, stderr=subprocess.PIPE) as п:
            with mock.patch.object(допуск.os, 'getpgid', side_effect=OSError(5, 'диагностический PGID')):
                р = диагностика.наблюдать(п, диагностика.намерение())
            сам.assertIs(п, р)
            сам.assertEqual((сам.вывод, сам.ошибки), р.communicate(timeout=2))
            сам.assertEqual(7, р.poll())
        события = [json.loads(с) for с in строки]
        начала = [с for с in события if с['событие'] == 'процесс-запущен']
        сам.assertEqual([п.pid], [с['потомок'] for с in начала])
        сам.assertEqual(1, sum(с['событие'] == 'процесс-завершён' for с in события))


if __name__ == '__main__':
    unittest.main()
