import importlib.util
import pathlib
import subprocess
import tempfile
import unittest

путь = pathlib.Path(__file__).resolve().parents[1] / 'собрать_либторрент.py'
описание = importlib.util.spec_from_file_location('сборщик_либторрента', путь)
модуль = importlib.util.module_from_spec(описание)
описание.loader.exec_module(модуль)


class СборкаЛибторрентаТесты(unittest.TestCase):
    def test_НетРегистрацииЗапрещаетПервыйЭффект(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный)
            вызовы = []
            def исполнитель(команда):
                вызовы.append(команда)
                return ''
            with сам.assertRaisesRegex(ValueError, 'gitlink'):
                модуль.проверить_регистрацию(корень, исполнитель)
            сам.assertEqual(len(вызовы), 1)
            сам.assertFalse((корень / 'сборка').exists())

    def test_ТочнаяРегистрацияИОшибочныйКоммит(сам):
        def исполнитель(команда):
            if 'ls-tree' in команда:
                имя = 'try_signal' if команда[-1].endswith('try_signal') else 'libtorrent'
                return '160000 commit ' + модуль.ЗАКРЕПЛЕНИЯ[имя] + '\t' + команда[-1] + '\n'
            if '--get-regexp' in команда:
                return '\n'.join('submodule.' + имя + '.path ' + модуль.ПУТИ[имя] for имя in модуль.ЗАКРЕПЛЕНИЯ)
            имя = команда[-1].split('.')[1]
            return (модуль.ФОРКИ if команда[-1].endswith('.url') else модуль.ОРИГИНАЛЫ)[имя] + '\n'
        модуль.проверить_регистрацию(pathlib.Path('/фикстура'), исполнитель)
        def подмена(команда):
            return исполнитель(команда).replace(модуль.ЗАКРЕПЛЕНИЯ['libtorrent'], '0' * 40)
        with сам.assertRaisesRegex(ValueError, 'gitlink'):
            модуль.проверить_регистрацию(pathlib.Path('/фикстура'), подмена)

    def test_ВыходыВнутриГитИПересечениеЗакрыты(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            (корень / '.git').mkdir()
            with сам.assertRaisesRegex(ValueError, 'Git'):
                модуль.проверить_выход(корень / 'сборка')
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            with сам.assertRaisesRegex(ValueError, 'пересечение'):
                модуль.проверить_разделение([корень / 'a', корень / 'a/b'])

    def test_СсылкиИЗанятыйВыходСохраняются(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            (корень / 'занято').mkdir()
            (корень / 'занято/маркер').write_text('сохранить')
            (корень / 'ссылка').symlink_to(корень / 'занято')
            for имя in ['занято', 'ссылка']:
                with сам.assertRaises(ValueError):
                    модуль.проверить_выход(корень / имя)
            сам.assertEqual((корень / 'занято/маркер').read_text(), 'сохранить')

    def test_ТочныеПараметрыСборкиБезСетевыхКоманд(сам):
        среда = {'cmake': '/cmake', 'cxx': '/clang++', 'pkg_config': '/pkg-config',
            'boost': '/boost', 'openssl': '/openssl', 'sdk': '/SDK', 'архитектура': 'arm64', 'минимум_macos': '14.0'}
        команды = модуль.команды_сборки(pathlib.Path('/исходники'), pathlib.Path('/сборка'), pathlib.Path('/префикс'), среда)
        первая = команды[0]
        for аргумент in ['-DBUILD_SHARED_LIBS=ON', '-DCMAKE_BUILD_TYPE=Release',
                '-DCMAKE_CXX_STANDARD=17', '-DCMAKE_CXX_EXTENSIONS=OFF', '-Dexceptions=ON',
                '-Dwebtorrent=OFF', '-Dgnutls=OFF', '-Di2p=OFF', '-Ddht=OFF', '-Dencryption=OFF']:
            сам.assertIn(аргумент, первая)
        сам.assertEqual(len(команды), 3)
        сам.assertFalse(any(слово in ['clone', 'fetch', 'init'] for команда in команды for слово in команда))

    def test_ОтказПрерываетПоследовательность(сам):
        вызовы = []
        def исполнитель(команда):
            вызовы.append(команда)
            if команда == ['сбой']:
                raise subprocess.CalledProcessError(1, команда)
            return ''
        with сам.assertRaises(subprocess.CalledProcessError):
            модуль.выполнить_последовательно([['первая'], ['сбой'], ['последняя']], исполнитель)
        сам.assertEqual(вызовы, [['первая'], ['сбой']])

    def test_НепрозрачныеАргументыЭкспортаЗакрыты(сам):
        сам.assertEqual(модуль.разобрать_аргументы('-I/abc -DTORRENT_USE_OPENSSL -pthread'),
            ['-I/abc', '-DTORRENT_USE_OPENSSL', '-pthread'])
        for значение in ['@скрытый', '-fplugin=/x', '-I"/путь с пробелом"', '-Xclang -load /x', '-include /x']:
            with сам.assertRaises(ValueError):
                модуль.разобрать_аргументы(значение)

    def test_ЗакреплённыйЭкспортРазрешаетТолькоВключённыеИсключения(сам):
        сам.assertEqual(модуль.разобрать_аргументы('-I/abc -fexceptions'), ['-I/abc', '-fexceptions'])
        for значение in ['-fno-exceptions', '-funknown', '-Wl,-rpath,/abc,-plugin,/x']:
            with сам.assertRaises(ValueError):
                модуль.разобрать_аргументы(значение)

    def test_КриптобиблиотекиОбязательныБезПодмены(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            (корень / 'lib').mkdir()
            (корень / 'lib/libcrypto.dylib').write_bytes('фикстура'.encode())
            with сам.assertRaisesRegex(ValueError, 'SSL'):
                модуль.проверить_криптобиблиотеки(корень)
            (корень / 'lib/libssl.dylib').write_bytes('фикстура'.encode())
            сам.assertEqual(len(модуль.проверить_криптобиблиотеки(корень)), 2)
            (корень / 'lib/libcrypto.dylib').unlink()
            with сам.assertRaisesRegex(ValueError, 'Crypto'):
                модуль.проверить_криптобиблиотеки(корень)



class ГраницыСборщикаТесты(unittest.TestCase):
    def test_ФизическиеВыходыИАргументыОптимизации(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            with сам.assertRaises(ValueError):
                модуль.проверить_выход(корень / 'a/../b')
        среда = {'cmake': '/cmake', 'cxx': '/clang++', 'boost': '/boost', 'openssl': '/ssl',
            'sdk': '/SDK', 'архитектура': 'arm64', 'минимум_macos': '14.0'}
        команды = модуль.команды_сборки(pathlib.Path('/src'), pathlib.Path('/build'), pathlib.Path('/prefix'), среда)
        сам.assertIn('Unix Makefiles', команды[0])
        for команда in команды[1:]:
            сам.assertIn('--config', команда)
            сам.assertIn('Release', команда)

    def test_СредаПроцессаНеНаследуетСкрытыеФлаги(сам):
        import os, sys
        from unittest.mock import patch
        with patch.dict(os.environ, {'CMAKE_GENERATOR': 'скрыто', 'CXXFLAGS': '-fno-exceptions',
                'DYLD_LIBRARY_PATH': '/скрыто', 'GIT_WORK_TREE': '/чужое'}):
            результат = модуль.выполнить([sys.executable, '-I', '-S', '-B', '-c',
                'import os; print([os.environ.get(k) for k in ["CMAKE_GENERATOR","CXXFLAGS","DYLD_LIBRARY_PATH","GIT_WORK_TREE"]])'])
        сам.assertEqual(результат.strip(), '[None, None, None, None]')

    def test_ТаймаутЗавершаетПотомкаПослеВыходаЛидера(сам):
        import sys, time
        with tempfile.TemporaryDirectory() as временный:
            маркер = pathlib.Path(временный).resolve() / 'поздняя-запись'
            код = 'import signal,time,pathlib; signal.signal(signal.SIGTERM,signal.SIG_IGN); time.sleep(0.7); pathlib.Path(' + repr(str(маркер)) + ').write_text("ошибка")'
            лидер = 'import subprocess,sys; subprocess.Popen([sys.executable,"-I","-S","-B","-c",' + repr(код) + '])'
            with сам.assertRaises(TimeoutError):
                модуль.выполнить([sys.executable, '-I', '-S', '-B', '-c', лидер], таймаут=0.2)
            time.sleep(0.8)
            сам.assertFalse(маркер.exists())

    def test_КвитанцияНеПересекаетсяСВыходами(сам):
        from unittest.mock import patch
        import sys, json
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            вход = корень / 'вход.json'
            вход.write_text(json.dumps({'корень': str(корень), 'рабочий_каталог': str(корень/'work'),
                'префикс': str(корень/'prefix'), 'среда': {}}))
            with patch.object(модуль, 'собрать') as сборка, patch.object(sys, 'argv',
                    ['сборщик', '--вход', str(вход), '--выход', str(корень/'work/receipt.json')]):
                with сам.assertRaisesRegex(ValueError, 'пересечение'):
                    модуль.основная()
                сборка.assert_not_called()

class ПолныйПроходСборщикаТесты(unittest.TestCase):
    def приготовить(сам, корень):
        среда = {'архитектура': 'arm64', 'минимум_macos': '14.0'}
        for имя in ['cmake', 'cxx', 'pkg_config']:
            путь = корень / 'среда' / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_text('фикстура инструмента')
            путь.chmod(0o700)
            среда[имя] = str(путь)
        for имя, файл in [('boost', 'boost/version.hpp'), ('openssl', 'include/openssl/ssl.h'), ('sdk', 'usr/include/sys/types.h')]:
            путь = корень / 'среда' / имя
            (путь / файл).parent.mkdir(parents=True, exist_ok=True)
            (путь / файл).write_text('фикстура заголовка')
            среда[имя] = str(путь)
        (корень / 'среда/openssl/lib').mkdir()
        for имя in ['libssl.dylib', 'libcrypto.dylib']:
            (корень / 'среда/openssl/lib' / имя).write_bytes(b'fixture')
        исходник = корень / 'репозиторий'
        for имя in модуль.ЗАКРЕПЛЕНИЯ:
            (исходник / модуль.ПУТИ[имя]).mkdir(parents=True)
        (исходник / модуль.ПУТИ['libtorrent'] / 'deps/try_signal').mkdir(parents=True)
        return исходник, корень / 'work', корень / 'prefix', среда

    def исполнитель(сам, вход, вызовы, сбой=None, подмена=False):
        исходник, рабочий, префикс, среда = вход
        def выполнить(команда):
            вызовы.append(команда)
            if команда[0] == 'git':
                место = pathlib.Path(команда[2])
                if 'ls-tree' in команда:
                    имя = 'try_signal' if команда[-1].endswith('try_signal') else 'libtorrent'
                    return '160000 commit ' + модуль.ЗАКРЕПЛЕНИЯ[имя] + '\t' + команда[-1] + '\n'
                if '--get-regexp' in команда:
                    return '\n'.join('submodule.' + имя + '.path ' + модуль.ПУТИ[имя] for имя in модуль.ЗАКРЕПЛЕНИЯ)
                if 'config' in команда:
                    имя = команда[-1].split('.')[1]
                    return (модуль.ФОРКИ if команда[-1].endswith('.url') else модуль.ОРИГИНАЛЫ)[имя] + '\n'
                имя = 'try_signal' if место.name == 'try_signal' else 'libtorrent'
                if команда[-1] == '--show-toplevel': return str(место)
                if команда[-1] == '--is-shallow-repository': return 'false'
                if команда[-1] == 'HEAD': return '1' * 40 if место == исходник else модуль.ЗАКРЕПЛЕНИЯ[имя]
                if 'status' in команда: return ''
                if 'remote' in команда: return (модуль.ФОРКИ if команда[-1] == 'origin' else модуль.ОРИГИНАЛЫ)[имя]
                if 'for-each-ref' in команда: return 'refs/remotes/origin/master'
                raise AssertionError(команда)
            стадия = ('configure' if '-S' in команда else 'build' if '--build' in команда else
                'install' if '--install' in команда else 'cflags' if '--cflags' in команда else
                'libs' if '--libs' in команда else 'compile' if команда[0] == среда['cxx'] else 'probe')
            if стадия == сбой: raise subprocess.CalledProcessError(1, команда)
            if стадия == 'configure':
                (рабочий/'out').mkdir()
                (рабочий/'out/CMakeCache.txt').write_text('\n'.join(имя + ':FILEPATH=' + среда['openssl'] + '/lib/' + файл
                    for имя, файл in [('OPENSSL_SSL_LIBRARY','libssl.dylib'),('OPENSSL_CRYPTO_LIBRARY','libcrypto.dylib')]))
            if стадия == 'install':
                (префикс/'lib/pkgconfig').mkdir(parents=True)
                (префикс/'lib/pkgconfig/libtorrent-rasterbar.pc').write_text('фикстура pc')
                (префикс/'lib/libtorrent-rasterbar.dylib').write_bytes(b'fixture')
                (префикс/'include/libtorrent').mkdir(parents=True)
                (префикс/'include/libtorrent/version.hpp').write_text('фикстура заголовка')
            if стадия == 'cflags': return '-I' + str(префикс/'include') + ' -fexceptions -DTORRENT_USE_OPENSSL'
            if стадия == 'libs': return '-L' + str(префикс/'lib') + ' -ltorrent-rasterbar'
            if стадия == 'probe' and подмена:
                (префикс/'lib/libtorrent-rasterbar.dylib').write_bytes(b'changed')
            return ''
        return выполнить

    def test_ПолныйПроходФикстурыИКаждыйОтказ(сам):
        for сбой in [None, 'configure', 'build', 'install', 'cflags', 'libs', 'compile', 'probe']:
            with сам.subTest(сбой=сбой), tempfile.TemporaryDirectory() as временный:
                вход = сам.приготовить(pathlib.Path(временный).resolve())
                вызовы = []
                исполнитель = сам.исполнитель(вход, вызовы, сбой)
                if сбой:
                    with сам.assertRaises(subprocess.CalledProcessError): модуль.собрать(*вход, исполнитель)
                    сам.assertNotIn('rev-parse', вызовы[-1])
                else:
                    результат = модуль.собрать(*вход, исполнитель)
                    сам.assertEqual(результат['проба'], 'успешно')
                    сам.assertEqual(результат['регистрация'], '1' * 40)
                    сам.assertEqual(len(результат['артефакты']), 5)
                сам.assertFalse(any(аргумент in ['clone','fetch','init'] for команда in вызовы for аргумент in команда))

    def test_ПоздняяПодменаАртефактаНеВыдаётКвитанцию(сам):
        with tempfile.TemporaryDirectory() as временный:
            вход = сам.приготовить(pathlib.Path(временный).resolve())
            with сам.assertRaisesRegex(ValueError, 'артефакт изменился'):
                модуль.собрать(*вход, сам.исполнитель(вход, [], подмена=True))

    def test_ПодменаЭкспортаПриЧтенииФлаговЗакрытаДоПробы(сам):
        for флаг in ['--cflags', '--libs']:
            with сам.subTest(флаг=флаг), tempfile.TemporaryDirectory() as временный:
                вход = сам.приготовить(pathlib.Path(временный).resolve())
                вызовы = []
                выполнить = сам.исполнитель(вход, вызовы)
                def подменить(команда):
                    результат = выполнить(команда)
                    if флаг in команда:
                        (вход[2]/'lib/pkgconfig/libtorrent-rasterbar.pc').write_text('подмена экспорта')
                    return результат
                with сам.assertRaisesRegex(ValueError, 'артефакт изменился'):
                    модуль.собрать(*вход, подменить)
                сам.assertFalse(any(команда[0] == вход[3]['cxx'] for команда in вызовы))

    def test_КаталогВместоИнструментаЗакрытДоЗаписи(сам):
        with tempfile.TemporaryDirectory() as временный:
            вход = сам.приготовить(pathlib.Path(временный).resolve())
            исходник, рабочий, префикс, среда = вход
            путь = pathlib.Path(среда['cmake']); путь.unlink(); путь.mkdir()
            with сам.assertRaisesRegex(ValueError, 'исполняемого'):
                модуль.собрать(*вход, сам.исполнитель(вход, []))
            сам.assertFalse(рабочий.exists()); сам.assertFalse(префикс.exists())

    def test_ПовторнаяСистемнаяОтменаНеОставляетПотомка(сам):
        import sys, time, signal
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            готов = корень/'готов'; маркер = корень/'поздняя-запись'
            код = 'import signal,time,pathlib; signal.signal(signal.SIGTERM,signal.SIG_IGN); pathlib.Path(' + repr(str(готов)) + ').write_text("готов"); time.sleep(1); pathlib.Path(' + repr(str(маркер)) + ').write_text("ошибка")'
            загрузка = 'import importlib.util; описание=importlib.util.spec_from_file_location("сборщик",' + repr(str(путь)) + '); модуль=importlib.util.module_from_spec(описание); описание.loader.exec_module(модуль); модуль.выполнить(' + repr([sys.executable,'-I','-S','-B','-c',код]) + ')'
            процесс = subprocess.Popen([sys.executable,'-I','-S','-B','-c',загрузка], stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            try:
                срок = time.monotonic()+3
                while not готов.exists() and time.monotonic()<срок: time.sleep(0.01)
                сам.assertTrue(готов.exists())
                процесс.send_signal(signal.SIGTERM); time.sleep(0.025)
                if процесс.poll() is None: процесс.send_signal(signal.SIGTERM)
                процесс.communicate(timeout=3)
                time.sleep(1.1)
                сам.assertFalse(маркер.exists())
                сам.assertNotEqual(процесс.returncode,0)
            finally:
                if процесс.poll() is None: процесс.kill()
                процесс.communicate()

class ПоздняяОтменаСборщикаТесты(unittest.TestCase):
    def test_ОтменаВоВремяОчисткиНеВозвращаетУспех(сам):
        import os, sys, signal
        from unittest.mock import patch
        настоящий = os.killpg
        def отменить(группа, номер):
            os.kill(os.getpid(), signal.SIGTERM)
            return настоящий(группа, номер)
        with patch.object(модуль.os, 'killpg', отменить):
            with сам.assertRaises(KeyboardInterrupt):
                модуль.выполнить([sys.executable,'-I','-S','-B','-c','print("готово")'])


def профилировать():
    import json, time, resource
    стадии = []
    def измерить(имя, действие):
        for _ in range(2): действие()
        пробы = []
        for _ in range(9):
            начало = time.monotonic_ns(); действие(); пробы.append(time.monotonic_ns()-начало)
        стадии.append({'имя':имя, 'пробы_нс':пробы})
    измерить('полный_проход_фикстуры_и_отказы_семи_фаз',
        ПолныйПроходСборщикаТесты().test_ПолныйПроходФикстурыИКаждыйОтказ)
    def отказ_регистрации():
        with tempfile.TemporaryDirectory() as временный:
            корень = pathlib.Path(временный).resolve()
            вызовы = []
            def исполнитель(команда): вызовы.append(команда); return ''
            try: модуль.проверить_регистрацию(корень, исполнитель)
            except ValueError: pass
            else: raise AssertionError('ожидался отказ отсутствующего gitlink')
            if len(вызовы)!=1 or list(корень.iterdir()): raise AssertionError('эффект до регистрации')
    измерить('отказ_регистрации_на_фикстуре_без_записей', отказ_регистрации)
    print('ФУМ-ПРОФИЛЬ:' + json.dumps({'схема':'fum.профиль-сборщика-либторрента.1',
        'прогревов':2,'повторов':9,'стадии':стадии,
        'максимум_резидентной_памяти_байт':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'граница':'Python/macOS; fake executor; создание, assertions и cleanup включены; реального CMake/libtorrent нет',
        'производственный_либторрент':'не измерен: отсутствует зарегистрированная зависимость'},ensure_ascii=False,sort_keys=True))

if __name__ == '__main__':
    import sys
    if '--профиль' in sys.argv: профилировать()
    else: unittest.main()
