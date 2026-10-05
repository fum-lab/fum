"""Адресная семантика единого прохода; независимый oracle из точных байтов C265."""
from __future__ import annotations

import hashlib
import importlib.util
import os
from pathlib import Path, PurePosixPath
import random
import stat
import subprocess
import sys
import tempfile
import types
import unittest
from unittest import mock

from test_request_folder_layout import (
    RepositoryFixture, EARLY, LATE, request_document, navigation,
)

КОРЕНЬ = Path(__file__).resolve().parents[3]
ПУТЬ = Path('Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py')
ОСНОВА = 'edabf43260b47c0ec3b0c8d7726e0c6fa37722c6'
ХЭШ_ОСНОВЫ = '08e9e3eb2cc7876454f06425443db3c1cdac4a192408a6850a51097a8472b9bc'
ХЭШ_БИБЛИОТЕКИ = 'caf78daee202eeb3a2eba81eb5ffbd2b3e60d64933312ec862a6884eef924b9d'
ПРИЁМОЧНЫЙ_ЛИСТ = Path('Инструменты/fum-struktura-papok-zaprosov/tests/test_request_folder_layout.py')
ХЭШ_ЛИСТА = '9fdc76f6e71ea48b3a82343ddce9ba7310b32b5ccb2cdde8f299df76c74486fb'


def загрузить(исходник: bytes, имя: str, путь: Path):
    модуль = types.ModuleType(имя)
    модуль.__file__ = str(путь)
    sys.modules[имя] = модуль
    exec(compile(исходник, str(путь), 'exec'), модуль.__dict__)
    return модуль


def поля(токены):
    return [(т.destination_start, т.destination_end, т.raw_destination,
             т.angle_destination, т.kind, т.line) for т in токены]


def исход(вызов):
    try:
        return ('результат', вызов())
    except Exception as ошибка:
        return ('ошибка', type(ошибка).__name__, str(ошибка))


def снимок(фикстура):
    файлы = {}
    for путь in sorted(фикстура.root.rglob('*')):
        имя = путь.relative_to(фикстура.root).as_posix()
        if '.git' in Path(имя).parts:
            continue
        режим = stat.S_IMODE(путь.lstat().st_mode)
        if путь.is_symlink():
            файлы[имя] = ('ссылка', режим, os.readlink(путь))
        elif путь.is_file():
            файлы[имя] = ('файл', режим, путь.read_bytes())
    состояния = [фикстура.git('--no-optional-locks', *аргументы).stdout for аргументы in (
        ('rev-parse', 'HEAD', 'HEAD^{tree}'), ('ls-files', '--stage'), ('status', '--porcelain'),
    )]
    return файлы, состояния, (фикстура.root / '.git/index').read_bytes()


class ЕдиныйРазборСсылок(unittest.TestCase):
    @classmethod
    def setUpClass(класс):
        sys.path.insert(0, str((КОРЕНЬ / ПУТЬ).parent))
        старые = subprocess.check_output(['git', 'show', ОСНОВА + ':' + ПУТЬ.as_posix()], cwd=КОРЕНЬ)
        if hashlib.sha256(старые).hexdigest() != ХЭШ_ОСНОВЫ:
            raise RuntimeError('изменились закреплённые байты oracle')
        выбранный = Path(os.environ.get('FUM_CHECKED_CODE_ROOT', str(КОРЕНЬ)))
        класс.новый = загрузить((выбранный / ПУТЬ).read_bytes(), 'единый_кандидат', выбранный / ПУТЬ)
        класс.старый = загрузить(старые, 'единый_старый_эталон', КОРЕНЬ / ПУТЬ)
        # Helpers общие, но обе функции layout происходят из независимых исходников.
        библиотека = класс.старый._link_tools()
        if hashlib.sha256(Path(библиотека.__file__).read_bytes()).hexdigest() != ХЭШ_БИБЛИОТЕКИ:
            raise RuntimeError('изменились закреплённые helpers')
        if hashlib.sha256(Path(класс.новый._link_tools().__file__).read_bytes()).hexdigest() != ХЭШ_БИБЛИОТЕКИ:
            raise RuntimeError('изменились helpers кандидата')

    def test_неизменяемый_приёмочный_лист(сам):
        путь = КОРЕНЬ / ПРИЁМОЧНЫЙ_ЛИСТ
        исходные = subprocess.check_output(['git', 'show', ОСНОВА + ':' + ПРИЁМОЧНЫЙ_ЛИСТ.as_posix()], cwd=КОРЕНЬ)
        сам.assertEqual(hashlib.sha256(исходные).hexdigest(), ХЭШ_ЛИСТА)
        сам.assertEqual(путь.read_bytes(), исходные)
        сам.assertTrue(stat.S_ISREG(путь.lstat().st_mode))
        сам.assertEqual(stat.S_IMODE(путь.lstat().st_mode), 0o644)
        индекс = subprocess.check_output(['git', 'show', ':' + ПРИЁМОЧНЫЙ_ЛИСТ.as_posix()], cwd=КОРЕНЬ)
        сам.assertEqual(индекс, исходные)
        описание = subprocess.check_output(['git', 'ls-tree', ОСНОВА, '--', ПРИЁМОЧНЫЙ_ЛИСТ.as_posix()], cwd=КОРЕНЬ)
        стадия = subprocess.check_output(['git', 'ls-files', '--stage', '--', ПРИЁМОЧНЫЙ_ЛИСТ.as_posix()], cwd=КОРЕНЬ)
        сам.assertEqual(стадия.split(b'\t')[0].split(), [описание.split()[0], описание.split()[2], b'0'])

    def test_публикационная_чистота_полного_подготовленного_состава(сам):
        имена = subprocess.check_output(['git', 'diff', '--cached', '--name-only', '--diff-filter=ACMRT', '-z'], cwd=КОРЕНЬ).decode().split('\0')
        файлы = {и: subprocess.check_output(['git', 'show', ':' + и], cwd=КОРЕНЬ) for и in имена if и}
        if not файлы:
            сам.skipTest('адресная публикационная проверка требует полного staging этапа')
        sys.path.insert(0, str(КОРЕНЬ / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts'))
        from подготовка_дочернего_поручения import публикация
        результат = публикация(КОРЕНЬ, файлы)
        сам.assertEqual(результат['проверенные_пути'], sorted(файлы))

    def test_полный_библиотечный_лексер_не_вызывается(сам):
        текст = 'открытая строка без ссылок ' * 4000
        инструменты = сам.новый._link_tools()
        with mock.patch.object(инструменты, 'markdown_link_tokens', wraps=инструменты.markdown_link_tokens) as наблюдатель:
            маска, токены = сам.новый._markdown_link_tokens(текст)
        сам.assertEqual(маска, bytearray(len(текст)))
        сам.assertEqual(поля(токены), [])
        сам.assertEqual(наблюдатель.call_count, 0)

    def test_профиль_не_поглощает_отказ_и_не_принимает_неверный_SHA(сам):
        путь = Path(__file__).with_name('профиль_единого_разбора_ссылок.py')
        описание = importlib.util.spec_from_file_location('адресный_профиль', путь)
        профиль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(профиль)
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный)
            def отказ():
                raise SystemExit(7)
            запись = профиль.измерить(отказ, True, каталог / 'отказ.pstats')
            сам.assertEqual(запись['исход'], {'вид': 'ошибка', 'тип': 'SystemExit', 'текст': '7'})
            сам.assertGreater(запись['нс'], 0)
            (каталог / 'отказ.pstats').unlink()
            кандидат = каталог / 'кандидат.py'
            кандидат.write_text('кандидат\n')
            приватный = каталог / 'выходы'
            приватный.mkdir(mode=0o700)
            параметры = types.SimpleNamespace(корень=КОРЕНЬ, приватный=приватный, кандидат=кандидат, хэш_кандидата='0' * 64)
            with сам.assertRaisesRegex(RuntimeError, 'SHA кандидата'):
                профиль.подготовить(параметры)
            сам.assertEqual(list(приватный.iterdir()), [])

    def test_явные_поля_и_независимый_эталон(сам):
        случаи = [
            ('[наружная [внутренняя](Запросы/old.md) `код`](target.md)',
             [(23, 37, 'Запросы/old.md', False, 'inline', 1), (46, 55, 'target.md', False, 'inline', 1)]),
            ('[a [b](one.md)](two.md)', [(16, 22, 'two.md', False, 'inline', 1)]),
            ('[a `x` [b](one.md)](two.md) [z](three.md)',
             [(11, 17, 'one.md', False, 'inline', 1), (20, 26, 'two.md', False, 'inline', 1), (32, 40, 'three.md', False, 'inline', 1)]),
            ('![a `x`](<Запросы/old.md> "t")', [(10, 24, 'Запросы/old.md', True, 'image', 1)]),
            ('[r]:\r\n  <one.md>\r\n  "t"\r\n![b `x`](<two.md> "i")\r\n',
             [(9, 15, 'one.md', True, 'reference', 1), (35, 41, 'two.md', True, 'image', 4)]),
            ('\\![a](one.md)', [(6, 12, 'one.md', False, 'image', 1)]),
            ('[a](x.md) [b](x.md)', [(4, 8, 'x.md', False, 'inline', 1), (14, 18, 'x.md', False, 'inline', 1)]),
            ('[a `x](one.md)', [(7, 13, 'one.md', False, 'inline', 1)]),
            ('[a [b `x`](two.md)](broken "unterminated)', [(11, 17, 'two.md', False, 'inline', 1)]),
            ('[a]() [b `x`]()', [(4, 4, '', False, 'inline', 1), (14, 14, '', False, 'inline', 1)]),
            ('\\[a](x.md)', []),
        ]
        for текст, ожидаемые in случаи:
            with сам.subTest(текст=текст):
                старая_маска, старые = сам.старый._markdown_link_tokens(текст)
                маска, новые = сам.новый._markdown_link_tokens(текст)
                сам.assertEqual(поля(старые), ожидаемые)
                сам.assertEqual(поля(новые), ожидаемые)
                сам.assertEqual(маска, старая_маска)

    def test_маски_ограды_экранирование_и_незакрытые_метки(сам):
        ссылка = '[x](Запросы/old.md)'
        случаи = [
            '```\n' + ссылка + '\n```\n', '~~~\n' + ссылка + '\n~~~\n',
            '````\n' + ссылка + '\n```\n' + ссылка + '\n````\n',
            '```\n' + ссылка, '<!--\n' + ссылка + '\n-->\n', '    ' + ссылка + '\n',
            '+++\n' + ссылка + '\n+++\n', '+++\n' + ссылка, '`' + ссылка + '`',
            '[a ``x`y``](one.md)', '[a \\] [b]](one\\(x\\).md "t")',
            '[a `x`](one.md) [b `x](two.md)', '[a](one.md "broken)',
            '[r]: <one.md> "t"\n[r]\n![r][]\n', '---\n' + ссылка + '\n---\n',
        ]
        случайный = random.Random(265)
        части = ['[a](x.md)', '![b `x`](<y.md>)', '`[z](z.md)`', '[c [d](v.md) `x`](w.md)', '\\[x]', '\r\n', 'текст ']
        случаи += [''.join(случайный.choices(части, k=20)) for _ in range(80)]
        for текст in случаи:
            with сам.subTest(текст=текст):
                старая_маска, старые = сам.старый._markdown_link_tokens(текст)
                маска, новые = сам.новый._markdown_link_tokens(текст)
                сам.assertEqual(маска, старая_маска)
                сам.assertEqual(поля(новые), поля(старые))

    def сверить_структуру(сам, фикстура):
        до = снимок(фикстура)
        старый = исход(lambda: сам.старый.validate_layout(фикстура.root))
        сам.assertEqual(снимок(фикстура), до)
        новый = исход(lambda: сам.новый.validate_layout(фикстура.root))
        сам.assertEqual(новый, старый)
        сам.assertEqual(снимок(фикстура), до)
        return новый

    def test_структура_ограды_защищённый_оригинал_и_дрейф(сам):
        фикстура = RepositoryFixture()
        try:
            фикстура.make_canonical_layout()
            запрос = фикстура.root / f'Журнал/{LATE}/запрос.md'
            запрос.write_text(запрос.read_text().replace(
                '## Текст запроса\n',
                '## Текст запроса\n\n[оригинал](../../Запросы/old.md)\n',
            ))
            путь = фикстура.write('Документация/проверка.md', '# Проверка\n')
            фикстура.commit()
            ожидаемый = сам.сверить_структуру(фикстура)
            сам.assertEqual(ожидаемый, ('результат', {'schema_version': 1, 'mode': 'validate', 'sessions': 1, 'reports': 1, 'request_only': 0}))
            старая_ссылка = '[внешняя [внутренняя](../Запросы/old.md) `код`](target.md)'
            for ограда in [('```\n', '\n```\n'), ('~~~\n', '\n~~~\n'), ('````\n', '\n```\n\n````\n'), ('```\n', ''), ('<!--\n', '\n-->\n'), ('    ', '\n'), ('+++\n', '\n+++\n')]:
                путь.write_text(ограда[0] + старая_ссылка + ограда[1])
                сам.assertEqual(сам.сверить_структуру(фикстура), ожидаемый)
            путь.write_text('# Проверка\n' + старая_ссылка + '\n')
            сам.assertEqual(сам.сверить_структуру(фикстура)[0], 'ошибка')
            путь.write_text('# Проверка\n')
            сам.assertEqual(сам.сверить_структуру(фикстура), ожидаемый)
            текст = запрос.read_text()
            сам.assertIn('Запросы/legacy.md', текст)
            маска, токены = сам.новый._markdown_link_tokens(текст)
            оригинал = next(т for т in токены if т.raw_destination == '../../Запросы/old.md')
            сам.assertFalse(any(маска[оригинал.destination_start:оригинал.destination_end]))
            сам.assertFalse(сам.новый._markdown_has_active_legacy_link(
                текст, PurePosixPath(f'Журнал/{LATE}/запрос.md'), фикстура.root,
            ))
            for значение in ('[a `x`](запрос.md)', '[a [b](запрос.md) `x`](отчёт.md)'):
                до = снимок(фикстура)
                старый = исход(lambda: сам.старый._markdown_targets(значение, PurePosixPath(f'Журнал/{LATE}/запрос.md'), фикстура.root))
                сам.assertEqual(снимок(фикстура), до)
                новый = исход(lambda: сам.новый._markdown_targets(значение, PurePosixPath(f'Журнал/{LATE}/запрос.md'), фикстура.root))
                сам.assertEqual(новый, старый)
                сам.assertEqual(снимок(фикстура), до)
        finally:
            фикстура.close()

    def test_перенос_отклоняет_портативную_коллизию_без_зависимости_от_файловой_системы(сам):
        фикстура = RepositoryFixture()
        try:
            фикстура.make_canonical_layout()
            до = снимок(фикстура)
            результаты = []
            for модуль in (сам.старый, сам.новый):
                переносы = [модуль.Move(PurePosixPath('первый.md'), PurePosixPath(f'Журнал/{EARLY}_{суффикс}/запрос.md')) for суффикс in ('ß', 'ss')]
                результаты.append(исход(lambda: модуль._check_move_collisions(фикстура.root, переносы)))
                сам.assertEqual(снимок(фикстура), до)
            сам.assertEqual(результаты[0], результаты[1])
            сам.assertEqual(результаты[0][0], 'ошибка')
            сам.assertIn('portable destination collision', результаты[0][2])
        finally:
            фикстура.close()

    def test_прежние_отказы_регистра_и_символической_ссылки(сам):
        for вид in ('регистр', 'символическая-ссылка'):
            фикстура = RepositoryFixture()
            try:
                фикстура.make_canonical_layout()
                if вид == 'регистр':
                    фикстура.write(f'Журнал/{EARLY}/запрос.md', request_document(EARLY, previous=None, following=LATE, legacy=False))
                    путь = фикстура.root / f'Журнал/{LATE}/запрос.md'
                    путь.write_text(путь.read_text().replace(navigation(None, None), navigation(EARLY, None).replace('запрос.md', 'ЗАПРОС.md')))
                    фикстура.write('Журнал/README.md', f'# Журнал\n\n## Сессии\n\n- [Первый]({EARLY}/запрос.md)\n- [Второй]({LATE}/отчёт.md)\n')
                else:
                    (фикстура.root / f'Журнал/{LATE}/материалы').mkdir()
                    (фикстура.root / f'Журнал/{LATE}/материалы/ссылка').symlink_to('../../README.md')
                фикстура.commit()
                with сам.subTest(вид=вид):
                    результат = сам.сверить_структуру(фикстура)
                    сам.assertEqual(результат[0], 'ошибка')
                    сам.assertIn({'регистр': 'wrong предыдущий link', 'символическая-ссылка': 'symbolic'}[вид], результат[2])
            finally:
                фикстура.close()


if __name__ == '__main__':
    unittest.main()
