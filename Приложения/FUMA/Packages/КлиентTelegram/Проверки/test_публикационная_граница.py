"""Открытые фикстуры выбора входов; настоящую TDLib не собирают и не загружают."""
import contextlib
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


КАТАЛОГ = Path(__file__).resolve().parent


def загрузить(имя, файл):
    описание = importlib.util.spec_from_file_location(имя, КАТАЛОГ / файл)
    модуль = importlib.util.module_from_spec(описание)
    описание.loader.exec_module(модуль)
    return модуль


пакет = загрузить('граница_пакета', 'проверить-пакет.py')
сборка = загрузить('граница_сборки', 'собрать-tdlib.py')
команда = загрузить('граница_команды', 'проверить-команду.py')


class ПроверкиПубликационнойГраницы(unittest.TestCase):
    def setUp(сам):
        временный = tempfile.TemporaryDirectory()
        сам.addCleanup(временный.cleanup)
        сам.корень = Path(временный.name).resolve()
        сам.пакет = сам.корень / 'пакет'
        сам.пакет.mkdir()
        (сам.пакет / 'Package.swift').write_text('// открытая фикстура\n')
        сам.разработчик = сам.корень / 'developer'
        сам.разработчик.mkdir()
        сам.компилятор = сам.файл(сам.разработчик / 'clang', b'compiler fixture')
        сам.инструменты = {имя: сам.файл(сам.разработчик / имя, имя.encode())
                           for имя in ('clang', 'clang++', 'cmake', 'make', 'gperf', 'lipo', 'nm', 'otool')}

    def файл(сам, путь, байты):
        путь.parent.mkdir(parents=True, exist_ok=True)
        путь.write_bytes(байты)
        путь.chmod(0o700)
        return путь

    def выполнитьRunner(сам, аргументы, окружение=None):
        вызовы = []
        def ребёнок(argv, **kwargs):
            вызовы.append((argv, kwargs))
            return 0
        выбор = subprocess.CompletedProcess([], 0, str(сам.разработчик) + '\n', '')
        with patch.object(sys, 'argv', ['runner', '--пакет', str(сам.пакет), '--кэш', str(сам.корень / 'cache'), *аргументы]), \
             patch.object(пакет.subprocess, 'run', return_value=выбор), \
             patch.object(пакет, 'построитьКоманду', return_value=['swift-fixture']), \
             patch.object(пакет.subprocess, 'call', side_effect=ребёнок), \
             patch.dict(os.environ, окружение or {}, clear=True), \
             contextlib.redirect_stderr(io.StringIO()):
            код = пакет.выполнить()
        return код, вызовы

    def test_runner_всегда_передаёт_проверенный_корень(сам):
        код, вызовы = сам.выполнитьRunner([])
        сам.assertEqual(код, 0)
        сам.assertEqual(вызовы[0][1]['env'].get('ФУМ_КОРЕНЬ_ПАКЕТА'), str(сам.пакет))
        сам.assertEqual(вызовы[0][1]['cwd'], сам.пакет)

    def test_runner_не_наследует_невыбранный_компилятор(сам):
        код, вызовы = сам.выполнитьRunner([], {'ФУМ_КОМПИЛЯТОР': 'невыбранный'})
        сам.assertEqual(код, 0)
        сам.assertNotIn('ФУМ_КОМПИЛЯТОР', вызовы[0][1]['env'])

    def test_runner_явный_компилятор_и_отказ_до_ребёнка(сам):
        код, вызовы = сам.выполнитьRunner(['--компилятор', str(сам.компилятор)])
        сам.assertEqual(код, 0)
        сам.assertEqual(вызовы[0][1]['env']['ФУМ_КОМПИЛЯТОР'], str(сам.компилятор))
        for путь in (сам.корень / 'нет', Path('относительный'), сам.файл(сам.корень / 'чужой', b'outside')):
            код, вызовы = сам.выполнитьRunner(['--компилятор', str(путь)])
            сам.assertEqual((код, вызовы), (2, []))
        сам.компилятор.chmod(0o600)
        сам.assertEqual(сам.выполнитьRunner(['--компилятор', str(сам.компилятор)]), (2, []))

    def test_runner_неверный_корень_не_запускает_ребёнка(сам):
        (сам.пакет / 'Package.swift').unlink()
        сам.assertEqual(сам.выполнитьRunner([]), (2, []))

    def test_синтетическая_компиляция_использует_выбранный_файл(сам):
        class Граница(Exception):
            pass
        вызовы = []
        def запустить(argv, **kwargs):
            вызовы.append(argv)
            сам.assertEqual(argv[0], str(сам.компилятор))
            raise Граница()
        with patch.dict(os.environ, {'ФУМ_КОМПИЛЯТОР': str(сам.компилятор), 'SDKROOT': str(сам.корень)}, clear=True), \
             patch.object(команда.subprocess, 'run', side_effect=запустить):
            with сам.assertRaises(Граница):
                команда.проверитьСинтетическуюБиблиотеку(сам.корень / 'команда')
        сам.assertEqual(len(вызовы), 1)

    def test_компилятор_отсутствует_или_неверен_без_запуска(сам):
        for значение in ('', 'относительный', str(сам.корень / 'нет')):
            with patch.dict(os.environ, {'ФУМ_КОМПИЛЯТОР': значение}, clear=True), \
                 patch.object(команда.subprocess, 'run', side_effect=AssertionError('неожиданный процесс')):
                with сам.assertRaises((ValueError, OSError)):
                    команда.проверитьСинтетическуюБиблиотеку(сам.корень / 'команда')

    def test_карта_закрыта_и_проверяется_до_выбора_среды(сам):
        сам.assertEqual(сборка.проверитьИнструменты(сам.инструменты), сам.инструменты)
        варианты = [{}, {**сам.инструменты, 'чужой': сам.компилятор},
                    {**сам.инструменты, 'cmake': Path('относительный')},
                    {**сам.инструменты, 'make': сам.корень / 'нет'}]
        сам.инструменты['gperf'].chmod(0o600)
        варианты.append(сам.инструменты)
        for значение in варианты:
            with patch.object(сборка, '_запустить', side_effect=AssertionError('selector не разрешён')):
                with сам.assertRaises(сборка.ОтказПрофиля):
                    сборка.проверитьИнструменты(значение)

    def test_диагностика_карты_не_кодирует_путь(сам):
        with сам.assertRaises(сборка.ОтказПрофиля) as отказ:
            сборка.проверитьИнструменты({})
        текст = str(отказ.exception)
        сам.assertNotIn('/', текст)
        for имя in сборка.ИМЕНА_ИНСТРУМЕНТОВ:
            сам.assertIn(имя, текст)

    def test_байты_версии_sdk_и_карта_сохраняют_контракт(сам):
        профиль = copy.deepcopy(сборка.прочитатьПрофиль())
        хост = профиль['хост']
        sdk = сам.корень / 'sdk'
        zlib = сам.файл(sdk / 'usr/lib/libz.tbd', b'zlib fixture')
        openssl = сам.корень / 'openssl'
        сам.файл(openssl / 'bin/openssl', b'openssl fixture')
        хост['zlibTbdSha256'] = сборка.sha256(zlib)
        хост['sha256Инструментов'] = {имя: сборка.sha256(сам.инструменты[имя])
                                    for имя in ('clang', 'clang++', 'cmake', 'make', 'gperf')}
        хост['sha256Инструментов'].update(openssl=сборка.sha256(openssl / 'bin/openssl'))
        def процесс(argv, **kwargs):
            ответы = {'xcode-select': str(сам.разработчик),
                       'xcodebuild': f"Xcode {хост['xcode']}\nBuild version {хост['сборкаXcode']}",
                       str(сам.инструменты['clang']): хост['clang'],
                       str(сам.инструменты['cmake']): 'cmake version ' + хост['cmake'],
                       str(сам.инструменты['make']): хост['make'],
                       str(сам.инструменты['gperf']): хост['gperf'],
                       str(openssl / 'bin/openssl'): хост['openssl']}
            if argv[0] == 'xcrun':
                ответы['xcrun'] = {'--show-sdk-version': хост['sdk'], '--show-sdk-build-version': хост['сборкаSdk'],
                                    '--show-sdk-path': str(sdk)}[argv[-1]]
            return subprocess.CompletedProcess(argv, 0, (ответы[argv[0]] + '\n').encode(), b'')
        with patch.object(сборка.platform, 'system', return_value='Darwin'), \
             patch.object(сборка.platform, 'machine', return_value=хост['архитектура']), \
             patch.object(сборка.platform, 'mac_ver', return_value=(хост['версия'], (), '')), \
             patch.object(сборка, '_запустить', side_effect=процесс):
            среда = сборка.проверитьСреду(профиль, openssl, инструменты=сам.инструменты)
            сам.assertEqual(среда['разработчик'], сам.разработчик)
            for имя in ('cmake', 'make', 'gperf', 'lipo', 'nm', 'otool', 'clang'):
                сам.assertEqual(среда[имя], сам.инструменты[имя])
            for изменение in ('хэш', 'sdk', 'версия'):
                неверный = copy.deepcopy(профиль)
                if изменение == 'хэш':
                    неверный['хост']['sha256Инструментов']['cmake'] = '0' * 64
                elif изменение == 'sdk':
                    zlib.write_bytes(b'changed')
                else:
                    неверный['хост']['clang'] = 'неверная версия'
                with сам.assertRaises(сборка.ОтказПрофиля):
                    сборка.проверитьСреду(неверный, openssl, инструменты=сам.инструменты)
                zlib.write_bytes(b'zlib fixture')

    def test_два_прохода_используют_проверенный_developer(сам):
        источник = сам.корень / 'source'
        источник.mkdir()
        среда = {'разработчик': сам.разработчик, 'наблюдения': {}}
        выход = сам.корень / 'build'
        with patch.object(сборка, 'проверитьРегистрацию', return_value=(источник, 'a' * 40)), \
             patch.object(сборка, 'проверитьОтпечаткиИсточника'), \
             patch.object(сборка, 'проверитьВыход', return_value=выход), \
             patch.object(сборка, 'проверитьСреду', return_value=среда), \
             patch.object(сборка, '_запустить', side_effect=AssertionError('повторный selector')), \
             patch.object(сборка, '_собратьОдин', return_value={'библиотекаSha256': 'b' * 64}) as проход:
            сборка.собрать(сам.корень, выход, сам.корень, инструменты=сам.инструменты)
            сам.assertEqual(проход.call_count, 2)
            for вызов in проход.call_args_list:
                сам.assertIs(вызов.args[4], среда)
                сам.assertEqual(вызов.args[6], сам.разработчик)

    def test_оба_исполнителя_записывают_sha_выбранного_компилятора(сам):
        class Граница(BaseException):
            pass
        исполняемый = сам.файл(сам.корень / 'команда', b'command fixture')
        for действие in (команда.проверитьСинтетическуюБиблиотеку, команда.проверитьОтказы):
            найдено = []
            def процесс(argv, **kwargs):
                if argv[0] == str(сам.компилятор):
                    Path(argv[argv.index('-o') + 1]).write_bytes(b'library fixture')
                    return subprocess.CompletedProcess(argv, 0, b'', b'')
                квитанция = json.loads(Path(argv[argv.index('--квитанция') + 1]).read_bytes())
                сам.assertEqual(квитанция['компиляторSha256'], hashlib.sha256(сам.компилятор.read_bytes()).hexdigest())
                найдено.append(квитанция)
                raise Граница()
            with patch.dict(os.environ, {'ФУМ_КОМПИЛЯТОР': str(сам.компилятор), 'SDKROOT': str(сам.корень)}, clear=True), \
                 patch.object(команда.subprocess, 'run', side_effect=процесс):
                with сам.assertRaises(Граница):
                    действие(исполняемый)
            сам.assertEqual(len(найдено), 1)

    def test_каждая_сборочная_команда_использует_карту(сам):
        профиль = сборка.прочитатьПрофиль()
        источник = сам.корень / 'source'
        источник.mkdir()
        openssl = сам.корень / 'openssl'
        openssl.mkdir()
        среда = {**сам.инструменты, 'clangxx': сам.инструменты['clang++'],
                 'sdkПуть': сам.корень, 'opensslRoot': openssl}
        вызовы = []
        def процесс(argv, **kwargs):
            вызовы.append(argv)
            вывод = b''
            if argv[0] == str(сам.инструменты['cmake']) and '--install' in argv:
                файл = сам.корень / 'проход-1/install/lib/libtdjson.dylib'
                файл.parent.mkdir(parents=True)
                файл.write_bytes(b'library fixture')
            elif argv[0] == str(сам.инструменты['lipo']):
                вывод = b'arm64\n'
            elif argv[0] == str(сам.инструменты['nm']):
                вывод = b'_td_create_client_id\n_td_send\n_td_receive\n'
            elif argv[0] == str(сам.инструменты['otool']):
                вывод = b'fixture:\n @rpath/libtdjson.dylib (compatibility version 1.0)\n'
            return subprocess.CompletedProcess(argv, 0, вывод, b'')
        with patch.object(сборка, '_клонироватьИсточник', return_value=источник), \
             patch.object(сборка, '_git', return_value='a' * 40), \
             patch.object(сборка, '_запустить', side_effect=процесс):
            результат = сборка._собратьОдин(1, источник, 'b' * 40, профиль, среда, сам.корень, сам.разработчик)
        сам.assertEqual(результат['архитектуры'], ['arm64'])
        сам.assertEqual([argv[0] for argv in вызовы], ['git', *[str(сам.инструменты[имя]) for имя in ('cmake', 'cmake', 'cmake', 'lipo', 'nm', 'otool')]])
        сам.assertIn('-DCMAKE_MAKE_PROGRAM=' + str(сам.инструменты['make']), вызовы[1])
        сам.assertIn('-DGPERF_EXECUTABLE=' + str(сам.инструменты['gperf']), вызовы[1])

    def test_повторная_карта_и_смешение_с_readiness_отклоняются(сам):
        записи = [имя + '=' + str(путь) for имя, путь in сам.инструменты.items()]
        сам.assertEqual(сборка.разобратьИнструменты(записи), сам.инструменты)
        with сам.assertRaises(сборка.ОтказПрофиля):
            сборка.разобратьИнструменты([*записи, записи[0]])
        with patch.object(sys, 'argv', ['builder', '--корень-репозитория', str(сам.корень),
                                      '--только-проверить-зависимость', '--инструмент', записи[0]]), \
             patch.object(сборка, 'проверитьГотовность', side_effect=AssertionError('не вызывать readiness')), \
             patch.object(сборка, '_запустить', side_effect=AssertionError('не вызывать selector')), \
             contextlib.redirect_stderr(io.StringIO()) as ошибки:
            сам.assertEqual(сборка.main(), 2)
        сам.assertEqual(json.loads(ошибки.getvalue())['причина'], 'неверные_аргументы')

    def test_относительный_ответ_selector_не_становится_cwd(сам):
        for значение in ('', '.'):
            with patch.object(sys, 'argv', ['runner', '--пакет', str(сам.пакет), '--кэш', str(сам.корень / 'cache')]), \
                 patch.object(пакет.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, значение, '')), \
                 patch.object(пакет.subprocess, 'call', side_effect=AssertionError('не запускать ребёнка')), \
                 contextlib.redirect_stderr(io.StringIO()):
                сам.assertEqual(пакет.выполнить(), 2)

    def test_отсутствующий_или_неверный_sdk_не_запускает_компилятор(сам):
        for значение in ('', 'относительный', str(сам.корень / 'нет'), str(сам.компилятор)):
            with patch.dict(os.environ, {'ФУМ_КОМПИЛЯТОР': str(сам.компилятор), 'SDKROOT': значение}, clear=True), \
                 patch.object(команда.subprocess, 'run', side_effect=AssertionError('не запускать компилятор')):
                with сам.assertRaises((ValueError, OSError)):
                    команда.проверитьСинтетическуюБиблиотеку(сам.корень / 'команда')

    def test_runner_передаёт_проверенный_sdk_и_отклоняет_внешний(сам):
        код, вызовы = сам.выполнитьRunner(['--компилятор', str(сам.компилятор)])
        сам.assertEqual(код, 0)
        сам.assertEqual(вызовы[0][1]['env']['SDKROOT'], str(сам.разработчик))
        for неверный in ('относительный', str(сам.корень)):
            ответы = [subprocess.CompletedProcess([], 0, str(сам.разработчик), ''),
                      subprocess.CompletedProcess([], 0, неверный, '')]
            with patch.object(sys, 'argv', ['runner', '--пакет', str(сам.пакет), '--кэш', str(сам.корень / 'cache'),
                                          '--компилятор', str(сам.компилятор)]), \
                 patch.object(пакет.subprocess, 'run', side_effect=ответы), \
                 patch.object(пакет.subprocess, 'call', side_effect=AssertionError('не запускать ребёнка')), \
                 contextlib.redirect_stderr(io.StringIO()):
                сам.assertEqual(пакет.выполнить(), 2)


if __name__ == '__main__':
    unittest.main()
