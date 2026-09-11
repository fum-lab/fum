"""Упаковка собирается воспроизводимо и не присваивает чужие каталоги."""
import importlib.util
import fcntl
import os
import shutil
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

сценарий = Path(__file__).resolve().parents[2] / 'собрать.py'


class ПроверкиСборки(unittest.TestCase):
    def setUp(сам):
        временный = tempfile.TemporaryDirectory(); сам.addCleanup(временный.cleanup)
        сам.корень = Path(временный.name).resolve()
        сам.проект = сам.корень / 'проект'; сам.проект.mkdir()
        (сам.проект / 'Package.swift').write_text('// Открытый манифест\n')
        (сам.проект / 'виртуализация.entitlements').write_text('Открытые права')
        ресурсы = сам.проект / 'Sources/ЯдроМашины/Ресурсы'; ресурсы.mkdir(parents=True)
        (ресурсы / 'готовность.py').write_text('print("Открытая фикстура")\n')
        сам.продукты = сам.корень / 'продукты'; сам.продукты.mkdir()
        (сам.продукты / 'машина').write_bytes(b'open-fixture')
        (сам.продукты / 'машина').chmod(0o700)
        пакет = сам.продукты / 'ВиртуальнаяМашина_ЯдроМашины.bundle/Contents/Resources'
        пакет.mkdir(parents=True)
        (пакет / 'готовность.py').write_bytes((ресурсы / 'готовность.py').read_bytes())
        сам.сборка = сам.корень / 'сборка'; сам.поставка = сам.корень / 'поставка'
        сам.выход = сам.сборка / 'swift/out'
        сам.вызовы = []
        описание = importlib.util.spec_from_file_location('сборка_машины', сценарий)
        сам.модуль = importlib.util.module_from_spec(описание); описание.loader.exec_module(сам.модуль)

    def выполнить(сам, аргументы, **параметры):
        сам.вызовы.append(аргументы)
        if '--version' in аргументы: return b'Swift fixture 1\n'
        if '--show-sdk-path' in аргументы: return b'/SDK/fixture\n'
        if '--show-sdk-version' in аргументы: return b'27.0\n'
        if '--show-bin-path' in аргументы: return str(сам.выход).encode() + b'\n'
        if 'build' in аргументы:
            if сам.выход.exists(): shutil.rmtree(сам.выход)
            shutil.copytree(сам.продукты, сам.выход, symlinks=True)
        return b''

    def собрать(сам):
        return сам.модуль.собрать(сам.проект, сам.сборка, сам.поставка, Path('/usr/bin/swift'),
            система='xcode', выполнить=сам.выполнить)

    def test_пакет_содержит_ресурсы_а_повтор_не_собирает_их_заново(сам):
        результат = сам.собрать()
        сам.assertEqual(результат['состояние'], 'собрана')
        сам.assertEqual((сам.поставка / 'машина').read_bytes(), b'open-fixture')
        сам.assertTrue((сам.поставка / 'ВиртуальнаяМашина_ЯдроМашины.bundle/Contents/Resources/готовность.py').is_file())
        команды = [в for в in сам.вызовы if 'build' in в and '--show-bin-path' not in в]
        сам.assertEqual(len(команды), 1)
        сам.assertIn('--jobs', команды[0]); сам.assertEqual(команды[0][команды[0].index('--jobs') + 1], '2')
        сам.вызовы.clear()
        сам.assertEqual(сам.собрать()['состояние'], 'проверена')
        сам.assertFalse(any('build' in в for в in сам.вызовы))

    def test_неизвестная_цель_и_каталог_сборки_сохраняются(сам):
        for путь in [сам.поставка, сам.сборка]:
            путь.mkdir(); (путь / 'данные').write_bytes(b'preserve')
            with сам.assertRaises(ValueError): сам.собрать()
            сам.assertEqual((путь / 'данные').read_bytes(), b'preserve')
            сам.assertFalse(сам.вызовы)
            (путь / 'данные').unlink(); путь.rmdir()

    def test_изменённый_исходник_или_поставка_не_перезаписываются(сам):
        сам.собрать()
        исходные = (сам.поставка / 'машина').read_bytes()
        (сам.проект / 'Package.swift').write_text('// Другой вход\n')
        with сам.assertRaises(ValueError): сам.собрать()
        сам.assertEqual((сам.поставка / 'машина').read_bytes(), исходные)
        (сам.проект / 'Package.swift').write_text('// Открытый манифест\n')
        (сам.поставка / 'машина').write_bytes(b'changed')
        with сам.assertRaises(ValueError): сам.собрать()
        сам.assertEqual((сам.поставка / 'машина').read_bytes(), b'changed')

    def test_ссылка_в_ресурсах_и_смена_исходника_во_время_сборки_отклоняются(сам):
        ресурс = сам.продукты / 'ВиртуальнаяМашина_ЯдроМашины.bundle/Contents/Resources/готовность.py'
        ресурс.unlink(); ресурс.symlink_to(сам.проект / 'Package.swift')
        with сам.assertRaises(ValueError): сам.собрать()
        сам.assertFalse(сам.поставка.exists())
        ресурс.unlink(); ресурс.write_text('print("Открытая фикстура")\n')
        прежнее = сам.выполнить
        def изменить(аргументы, **параметры):
            if 'build' in аргументы: (сам.проект / 'Package.swift').write_text('// Сдвиг\n')
            return прежнее(аргументы, **параметры)
        сам.выполнить = изменить
        with сам.assertRaises(ValueError): сам.собрать()
        сам.assertFalse(сам.поставка.exists())

    def test_занятый_кэш_не_запускает_параллельную_сборку(сам):
        сам.собрать(); сам.поставка = сам.корень / 'вторая-поставка'; сам.вызовы.clear()
        with (сам.сборка / 'замок').open('a+b') as замок:
            fcntl.flock(замок.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            with сам.assertRaisesRegex(ValueError, 'занят'): сам.собрать()
        сам.assertFalse(сам.поставка.exists())
        сам.assertFalse(any('build' in в for в in сам.вызовы))

    def test_изменение_выбранного_набора_разработчика_требует_новой_поставки(сам):
        сам.собрать(); прежнее = сам.выполнить
        def другой(аргументы, **параметры):
            if '--show-sdk-version' in аргументы: return b'28.0\n'
            return прежнее(аргументы, **параметры)
        сам.выполнить = другой
        with сам.assertRaisesRegex(ValueError, 'изменились'): сам.собрать()

    def test_ссылка_из_кэша_не_разрешает_чужую_запись(сам):
        сам.собрать(); сам.поставка = сам.корень / 'вторая-поставка'; сам.вызовы.clear()
        shutil.rmtree(сам.сборка / 'swift')
        чужое = сам.корень / 'чужое'; чужое.mkdir(); (чужое / 'данные').write_bytes(b'preserve')
        (сам.сборка / 'swift').symlink_to(чужое, target_is_directory=True)
        with сам.assertRaises(ValueError): сам.собрать()
        сам.assertEqual((чужое / 'данные').read_bytes(), b'preserve')
        сам.assertFalse(any('build' in в for в in сам.вызовы))

    def test_внешний_каталог_продуктов_не_принимается(сам):
        прежнее = сам.выполнить
        def внешний(аргументы, **параметры):
            if '--show-bin-path' in аргументы: return str(сам.продукты).encode() + b'\n'
            return прежнее(аргументы, **параметры)
        сам.выполнить = внешний
        with сам.assertRaises(ValueError): сам.собрать()
        сам.assertFalse(сам.поставка.exists())

    def test_лишний_ресурс_не_становится_частью_поставки(сам):
        (сам.продукты / 'ВиртуальнаяМашина_ЯдроМашины.bundle/Contents/Resources/устаревший.py').write_bytes(b'stale')
        with сам.assertRaises(ValueError): сам.собрать()
        сам.assertFalse(сам.поставка.exists())

    def test_изменённые_при_копировании_байты_не_публикуются(сам):
        прежнее = shutil.copytree
        def изменить(источник, цель, *аргументы, **параметры):
            результат = прежнее(источник, цель, *аргументы, **параметры)
            if Path(цель).parent.name.startswith('.поставка-VM-'):
                (Path(цель) / 'Contents/Resources/готовность.py').write_bytes(b'changed')
            return результат
        with mock.patch.object(сам.модуль.shutil, 'copytree', side_effect=изменить):
            with сам.assertRaises(ValueError): сам.собрать()
        сам.assertFalse(сам.поставка.exists())

    def test_появившаяся_перед_установкой_цель_не_заменяется(сам):
        прежнее = сам.модуль.установить_каталог
        def занять(источник, цель):
            if цель == сам.поставка:
                цель.mkdir(); (цель / 'данные').write_bytes(b'preserve')
            return прежнее(источник, цель)
        with mock.patch.object(сам.модуль, 'установить_каталог', side_effect=занять):
            with сам.assertRaises(OSError): сам.собрать()
        сам.assertEqual((сам.поставка / 'данные').read_bytes(), b'preserve')
        сам.assertTrue(list(сам.поставка.parent.glob('.поставка-VM-*')))

    def test_обычная_сборка_передаёт_наблюдателю_свой_удерживаемый_замок(сам):
        def создать(проект, каталог, замок, *, питон):
            сам.assertEqual(питон, сам.модуль.описать_python())
            сам.assertEqual(проект, сам.проект)
            сам.assertEqual(os.fstat(каталог).st_ino, сам.сборка.stat().st_ino)
            сам.assertEqual(os.fstat(замок).st_ino, (сам.сборка / 'замок').stat().st_ino)
            with (сам.сборка / 'замок').open('rb') as иной:
                with сам.assertRaises(BlockingIOError): fcntl.flock(иной.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            return сам.выполнить
        with mock.patch.object(сам.модуль, 'создать_исполнителя', side_effect=создать, create=True) as фабрика:
            ответ = сам.модуль.собрать(сам.проект, сам.сборка, сам.поставка, Path('/usr/bin/swift'), выполнить=None)
            сам.assertEqual(ответ['состояние'], 'собрана')
            сам.assertEqual(фабрика.call_count, 1)

    def test_нет_ресурса_наблюдателя_значит_нет_неподконтрольной_сборки(сам):
        with сам.assertRaisesRegex(ValueError, 'наблюдател'):
            сам.модуль.собрать(сам.проект, сам.сборка, сам.поставка, Path('/usr/bin/swift'), выполнить=None)
        сам.assertFalse(сам.поставка.exists())
        сам.assertFalse(сам.вызовы)


    def test_поставка_сохраняет_точный_python_и_отклоняет_его_замену(сам):
        сам.собрать()
        вход = json.loads((сам.поставка / 'поставка.json').read_bytes())['вход']
        сам.assertIn('python', вход)
        ожидаемый = сам.модуль.описать_python()
        сам.assertEqual(вход['python'], ожидаемый)
        сам.assertEqual(ожидаемый['реализация'], 'cpython')
        сам.assertEqual(ожидаемый['возможности'], ['waitid', 'WNOWAIT'])
        изменённый = dict(ожидаемый, sha256='0' * 64)
        сам.вызовы.clear()
        with mock.patch.object(сам.модуль, 'описать_python', return_value=изменённый):
            with сам.assertRaisesRegex(ValueError, 'изменились'): сам.собрать()
        сам.assertFalse(any('build' in в for в in сам.вызовы))

    def test_неподдерживаемый_python_отвергается_до_создания_кэша(сам):
        for изменения in [{'version_info': (3, 12, 0)}, {'implementation': type('Среда', (), {'name': 'иная'})()}]:
            with mock.patch.multiple(сам.модуль.sys, **изменения):
                with сам.assertRaisesRegex(ValueError, 'CPython'): сам.собрать()
            сам.assertFalse(сам.сборка.exists())
            сам.assertFalse(сам.поставка.exists())
            сам.assertFalse(сам.вызовы)

    def test_замена_python_в_ходе_сборки_не_устанавливает_поставку(сам):
        путь = сам.корень / 'python'; путь.write_bytes(Path(сам.модуль.sys.executable).resolve().read_bytes()); путь.chmod(0o700)
        прежний = сам.выполнить
        def выполнить(аргументы, **параметры):
            ответ = прежний(аргументы, **параметры)
            if '--verify' in аргументы: путь.write_bytes(b'changed-runtime')
            return ответ
        сам.выполнить = выполнить
        with mock.patch.object(сам.модуль.sys, 'executable', str(путь)):
            with сам.assertRaisesRegex(ValueError, 'Python.*изменил'): сам.собрать()
        сам.assertFalse(сам.поставка.exists())

if __name__ == '__main__': unittest.main()
