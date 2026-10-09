"""Независимый прежний oracle и закрытая чистая проверка одинаковых входов."""
import sys
from contextlib import ExitStack
from dataclasses import FrozenInstanceError, replace
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from test_check_session_coherence import check_session_coherence as прежняя
import снимок_связности as новая
from снимок_связности.модель import хэш
from снимок_связности.чтение import Наблюдатель


class ПроверкиСнимка(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        сам.записать('вход.md', '[да](Docs/цель.txt)\n')
        сам.записать('Docs/цель.txt', 'цель')
        сам.записать('внецелевой.md', 'исходный')

    def записать(сам, путь, текст):
        файл = сам.корень / путь
        файл.parent.mkdir(parents=True, exist_ok=True)
        файл.write_text(текст, encoding='utf-8')
        return файл

    def собрать(сам):
        return новая.собрать(сам.корень, ('вход.md',))

    def гит(сам, *аргументы):
        return subprocess.run(['git', '-C', str(сам.корень), *аргументы], check=True,
            capture_output=True, text=True).stdout

    def подписать(сам, снимок, **изменения):
        новый = replace(снимок, **изменения)
        return replace(новый, sha256=хэш(новый))

    def test_правильные_и_ошибочные_формы_совпадают_по_порядку(сам):
        случаи = [
            '[да](Docs/цель.txt#часть)\n', '[да](Docs)\n', '[да](#часть)\n',
            '[внешняя](https://example.invalid/x)\n', '[внешняя](' + chr(47)*2 + 'example.invalid/x)\n',
            '[нет](missing/путь.md)\n[регистр](docs/цель.txt)\n',
            '[абсолютный](file:' + chr(47)*3 + 'tmp/x)\n[выход](../x.md)\n',
            '[Windows](C' + ':' + chr(47) + 'tmp/x.md)\n', '[код](%2Ftmp/x.md)\n',
            '```text\n[не ссылка](нет.md)\n```\n[ошибка](нет.md)\n',
            '[с заголовком](Docs/цель.txt "Название")\n',
            '[углы](<Docs/цель.txt>)\n',
            '[исключено](Proyekcii/вход.md)\n',
        ]
        for текст in случаи:
            with сам.subTest(текст=текст):
                файл = сам.записать('вход.md', текст)
                снимок = сам.собрать()
                сам.assertEqual(tuple(прежняя.validate_markdown_links({файл}, сам.корень)), новая.проверить(снимок))
                сам.assertTrue(новая.сверить(снимок, новая.вычислить(снимок)))

    def test_все_байты_включая_внецелевой_Markdown_меняют_тождество(сам):
        снимок = сам.собрать()
        сам.записать('внецелевой.md', 'другой!!!')
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_не_полагаться_на_размер_и_mtime(сам):
        снимок = сам.собрать()
        файл = сам.корень / 'внецелевой.md'
        метки = файл.stat()
        исходные = файл.read_bytes()
        файл.write_bytes(b'x' * len(исходные))
        os.utime(файл, ns=(метки.st_atime_ns, метки.st_mtime_ns))
        сам.assertEqual(файл.stat().st_size, метки.st_size)
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_добавление_и_исчезновение_кандидата(сам):
        for операция in ('добавить', 'удалить'):
            with сам.subTest(операция=операция):
                снимок = сам.собрать()
                if операция == 'добавить': сам.записать('новый.md', 'новый')
                else: (сам.корень / 'внецелевой.md').unlink()
                with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_Git_происхождение_ignored_untracked_и_отсутствующий_tracked(сам):
        сам.гит('init', '--quiet')
        сам.гит('add', 'вход.md', 'внецелевой.md')
        снимок = сам.собрать()
        сам.гит('add', 'Docs/цель.txt')
        # Включение не-Markdown в индекс само по себе не меняет срез.
        сам.assertTrue(новая.сверить(снимок))
        сам.записать('новый.md', 'новый')
        снимок = сам.собрать()
        сам.гит('add', 'новый.md')
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)
        (сам.корень / 'внецелевой.md').unlink()
        снимок = сам.собрать()
        запись = next(элемент for элемент in снимок.инвентарь if элемент.путь == 'внецелевой.md')
        сам.assertEqual(запись.происхождение, 'tracked')
        сам.assertEqual(запись.состояние, ('отсутствует',))
        сам.assertTrue(запись.удаление)
        сам.записать('игнорируемый.md', 'скрыт')
        сам.записать('.gitignore', 'игнорируемый.md\n')
        снимок = сам.собрать()
        сам.записать('.gitignore', '')
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_появление_отсутствующей_цели_и_исчезновение_цели(сам):
        сам.записать('вход.md', '[нет](Docs/отсутствует.txt)\n')
        снимок = сам.собрать()
        сам.записать('Docs/отсутствует.txt', 'появилась')
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)
        сам.записать('вход.md', '[да](Docs/цель.txt)\n')
        снимок = сам.собрать()
        (сам.корень / 'Docs/цель.txt').unlink()
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_смена_типа_цели_и_предка(сам):
        for вид in ('каталог', 'ссылка'):
            with сам.subTest(вид=вид):
                цель = сам.корень / 'Docs/цель.txt'
                if цель.is_dir(): цель.rmdir()
                elif цель.exists() or цель.is_symlink(): цель.unlink()
                цель.write_text('цель')
                снимок = сам.собрать()
                цель.unlink()
                if вид == 'каталог': цель.mkdir()
                else: цель.symlink_to('../внецелевой.md')
                with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)
        сам.записать('вход.md', '[нет](предок/цель.txt)\n')
        снимок = сам.собрать()
        сам.записать('предок', 'файл вместо предка')
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_symlink_цепь_и_raw_readlink_не_сводятся_к_resolve(сам):
        псевдоним = сам.корень / 'alias'
        псевдоним.symlink_to('Docs', target_is_directory=True)
        сам.записать('вход.md', '[да](alias/цель.txt)\n')
        снимок = сам.собрать()
        сам.assertEqual(новая.проверить(снимок), tuple(прежняя.validate_markdown_links({сам.корень/'вход.md'}, сам.корень)))
        псевдоним.unlink();псевдоним.symlink_to('./Docs', target_is_directory=True)
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_выходящая_и_возвращающаяся_symlink_цепь_не_объявляется_замкнутой(сам):
        with tempfile.TemporaryDirectory() as каталог:
            внешняя = Path(каталог).resolve() / 'обход'
            внешняя.symlink_to(сам.корень/'Docs', target_is_directory=True)
            (сам.корень/'alias').symlink_to(внешняя, target_is_directory=True)
            сам.записать('вход.md', '[да](alias/цель.txt)\n')
            сам.assertEqual(прежняя.validate_markdown_links({сам.корень/'вход.md'}, сам.корень), [])
            with сам.assertRaises(новая.НеполныйСнимок): сам.собрать()

    def test_регистр_и_casefold_коллизия(сам):
        снимок = сам.собрать()
        (сам.корень / 'Docs/цель.txt').rename(сам.корень / 'Docs/Цель.txt')
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)
        сам.записать('Docs/ss.txt', 'одна')
        сам.записать('вход.md', '[нет](Docs/SS.txt)\n')
        снимок = сам.собрать()
        сам.записать('Docs/ß.txt', 'другая')
        имена = [элемент for элемент in (сам.корень/'Docs').iterdir() if элемент.name.casefold() == 'ss.txt']
        if len(имена) == 2:
            with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)
        else:
            # ФС этого host объединяет эти имена; проверяем наблюдённый дрейф
            # каталога, не объявляя две физически созданные записи.
            import снимок_связности.сверка as живая
            исходный = живая.значение
            адрес = str(сам.корень / 'Docs')
            def коллизия(операция, путь):
                ответ = исходный(операция, путь)
                if операция == 'iterdir' and путь == адрес:
                    return tuple(sorted((*ответ, str(сам.корень/'Docs/ß.txt'))))
                return ответ
            with mock.patch.object(живая, 'значение', side_effect=коллизия):
                with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)

    def test_изменение_параметров_и_исполняемого_кода(сам):
        снимок = сам.собрать()
        with mock.patch.dict(os.environ, {'GIT_PAGER': 'другой'}):
            with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)
        испорченный = (*снимок.код[:-1], (снимок.код[-1][0], снимок.код[-1][1] + b'\n'))
        with сам.assertRaises(новая.НеполныйСнимок): новая.проверить(сам.подписать(снимок, код=испорченный))
        исходное_чтение = Path.read_bytes
        путь_кода = новая.КОРЕНЬ / снимок.код[-1][0]
        def другие_байты(путь):
            ответ = исходное_чтение(путь)
            return ответ + b'\n' if путь == путь_кода else ответ
        with mock.patch.object(Path, 'read_bytes', другие_байты):
            with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(снимок)
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(сам.подписать(снимок, код=()))

    def test_противоречивый_exists_не_скрывает_ошибочную_ссылку(сам):
        сам.записать('вход.md', '[ошибка](нет.md)\n')
        снимок = сам.собрать()
        наблюдения = tuple(replace(элемент, значение=False) if элемент.операция == 'exists'
            and элемент.путь == str(сам.корень/'вход.md') else элемент for элемент in снимок.наблюдения)
        with сам.assertRaises(новая.НеполныйСнимок): новая.проверить(сам.подписать(снимок, наблюдения=наблюдения))

    def test_дословные_области_и_необязательный_граф(сам):
        сам.записать('вход.md', '[граф](.obsidian/graph.json)\n')
        запрос = 'Журнал/2026-10-09_12-00-00_MSK_проверить-ссылки/запрос.md'
        сам.записать(запрос, '## Текст запроса\n[нет](нет.md)\n## Источники\n')
        share = 'Источники/URL/https/chatgpt.com/share/id/диалог.md'
        сам.записать(share, '## Диалог\n<!-- FUM-CHATGPT-SHARE-VERBATIM:BEGIN -->\n[нет](нет.md)\n<!-- FUM-CHATGPT-SHARE-VERBATIM:END -->\n')
        снимок = новая.собрать(сам.корень)
        сам.assertEqual(новая.проверить(снимок), ())
        (сам.корень/'.obsidian').mkdir()
        сам.assertFalse((сам.корень/'.obsidian/graph.json').exists())
        сам.assertEqual(новая.проверить(новая.собрать(сам.корень)), ())
        сам.записать('.obsidian/graph.json', '{}')
        сохранённый = новая.собрать(сам.корень)
        сам.assertTrue(новая.сверить(сохранённый))
        сам.assertEqual((сам.корень/'.obsidian/graph.json').read_text(), '{}')

    def test_чистая_граница_не_читает_FS_Git_среду_и_часы(сам):
        снимок = сам.собрать()
        def запрет(*аргументы, **именованные): raise AssertionError('I/O внутри pure')
        цели = ['builtins.open', 'io.open', 'os.open', 'os.stat', 'os.lstat',
            'os.listdir', 'os.scandir', 'os.readlink', 'os.getcwd', 'os.getenv',
            'subprocess.run', 'subprocess.Popen', 'time.time', 'time.time_ns',
            'time.monotonic', 'time.monotonic_ns', 'time.perf_counter', 'time.perf_counter_ns']
        with ExitStack() as стек:
            for имя in цели: стек.enter_context(mock.patch(имя, side_effect=запрет))
            class ЗакрытаяСреда:
                __getitem__ = __iter__ = __len__ = __contains__ = get = запрет
            стек.enter_context(mock.patch.object(os, 'environ', ЗакрытаяСреда()))
            сам.assertEqual(новая.проверить(снимок), ())

    def test_неполнота_не_становится_обычной_ошибкой_ссылки(сам):
        снимок = сам.собрать()
        изменения = [
            {'полный': False}, {'тексты': ()}, {'параметры': ()},
            {'код': снимок.код[:-1]},
            {'наблюдения': tuple(элемент for элемент in снимок.наблюдения if элемент.операция != 'resolve')},
            {'наблюдения': снимок.наблюдения + (снимок.наблюдения[0],)},
        ]
        for поля in изменения:
            with сам.subTest(поля=list(поля)), сам.assertRaises(новая.НеполныйСнимок):
                новая.проверить(сам.подписать(снимок, **поля))
        with сам.assertRaises(FrozenInstanceError): снимок.полный = False
        with сам.assertRaises(новая.НеполныйСнимок): новая.проверить(replace(снимок, выбранные=()))

    def test_повреждённый_UTF8_и_недоступность_отвергаются(сам):
        (сам.корень/'внецелевой.md').write_bytes(b'\xff')
        with сам.assertRaises((новая.НеполныйСнимок, UnicodeDecodeError)): сам.собрать()
        сам.записать('внецелевой.md', 'исправлен')
        with mock.patch('pathlib.Path.iterdir', side_effect=PermissionError('нет доступа')):
            with сам.assertRaises(новая.НеполныйСнимок): сам.собрать()

    def test_повторный_живой_вызов_не_берёт_старое_свидетельство(сам):
        первый = сам.собрать();результат = новая.вычислить(первый)
        второй = сам.собрать()
        сам.assertEqual(первый.тексты, второй.тексты)
        сам.assertNotEqual(первый.вызов, второй.вызов)
        with сам.assertRaises(новая.НеполныйСнимок): новая.сверить(второй, результат)

    def test_дрейф_повторного_наблюдения_не_дедуплицируется(сам):
        наблюдатель = Наблюдатель(str(сам.корень))
        путь = str(сам.корень/'вход.md')
        наблюдатель('read_bytes', путь)
        сам.записать('вход.md', 'поменялся')
        with сам.assertRaises(новая.НеполныйСнимок): наблюдатель('read_bytes', путь)

    def test_общий_лексер_сравнивается_отдельно(сам):
        различия = [
            ('`[x](нет.md)`', ()), ('<!-- [x](нет.md) -->', ()),
            ('\\[x](нет.md)', ()), ('    [x](нет.md)', ()),
            ('[r]: нет.md\n[x][r]', ('нет.md',)),
            ('[a [b](one.md)](two.md)', ('two.md',)),
        ]
        for текст, цели in различия:
            with сам.subTest(текст=текст):
                сам.assertEqual(новая.лексические_цели(текст), цели)
                файл = сам.записать('вход.md', текст)
                снимок = сам.собрать()
                сам.assertEqual(новая.проверить(снимок), tuple(прежняя.validate_markdown_links({файл}, сам.корень)))

    def test_упорядоченный_отрицательный_исход(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог).resolve()
            файл = корень / 'вход.md'
            файл.write_text('[нет](нет.md)\n[абсолютный](' + chr(47) + 'tmp/нет.md)\n', encoding='utf-8')
            ожидаемый = прежняя.validate_markdown_links({файл}, корень)
            сам.assertEqual(ожидаемый, [
                'broken Markdown link in вход.md:1: нет.md',
                'absolute local Markdown link is forbidden in вход.md:2'])
            сам.assertEqual(tuple(ожидаемый), новая.проверить(новая.собрать(корень, ('вход.md',))))


if __name__ == '__main__':
    unittest.main()
