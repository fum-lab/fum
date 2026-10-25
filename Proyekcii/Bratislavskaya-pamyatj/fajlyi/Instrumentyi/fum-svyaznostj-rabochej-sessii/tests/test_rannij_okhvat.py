"""Открытые Git-фикстуры ранней сверки материалов."""
import json
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ПУТЬ = Path(__file__).resolve().parents[1] / 'scripts' / 'сверить-материалы-этапа.py'


class ПроверкаОхвата(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name)
        self.git('init', '-q')
        self.git('-c', 'user.name=Тест', '-c', 'user.email=test@example.invalid', 'commit', '--allow-empty', '-qm', 'Основа')
        self.запрос = self.корень / 'Журнал/2026-09-18_12-00-00_MSK_проверить-охват/запрос.md'
        self.запрос.parent.mkdir(parents=True)
        self.отчёт = self.запрос.with_name('отчёт.md')
        self.отчёт.write_text('Отчёт\n')
        self.записать()

    def git(self, *аргументы):
        return subprocess.check_output(['git', '-C', str(self.корень), *аргументы])

    def записать(self, ссылки='[Запрос](запрос.md)\n[Отчёт](отчёт.md)'):
        self.запрос.write_text('# Проверить охват\n\n## Повлиял на файлы\n' + ссылки + '\n')

    def вызвать(self, разрешённые=None, снимок=None):
        цели = разрешённые if разрешённые is not None else [п.relative_to(self.корень).as_posix() for п in self.корень.rglob('*') if п.is_file() and '.git' not in п.parts]
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json') as файл:
            json.dump(цели, файл); файл.flush()
            команда = [sys.executable, '-B', str(ПУТЬ), '--корень-репозитория', str(self.корень), '--запрос', str(self.запрос.relative_to(self.корень)), '--разрешённые-цели', файл.name]
            if снимок: команда += ['--снимок', str(снимок)]
            результат = subprocess.run(команда, capture_output=True, text=True)
        return результат.returncode, json.loads(результат.stdout)

    def test_полная_пара_и_повтор(self):
        код, результат = self.вызвать()
        self.assertEqual(код, 0, результат)
        self.assertEqual(результат, self.вызвать()[1])

    def test_каждая_обязательная_ссылка(self):
        for ссылки in ('[Запрос](запрос.md)', '[Отчёт](отчёт.md)', '[Каталог](.)'):
            with self.subTest(ссылки=ссылки):
                self.записать(ссылки)
                self.assertEqual(self.вызвать()[0], 1)

    def test_материалы_10_29_33_и_индекс(self):
        for число in (10, 29, 33):
            with self.subTest(число=число):
                каталог = self.корень / f'Производные/{число}'
                каталог.mkdir(parents=True)
                for номер in range(число): (каталог / f'{номер}.json').write_text('{}')
        self.assertEqual(self.вызвать()[0], 1)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Производные](../../Производные)')
        self.assertEqual(self.вызвать()[0], 0)
        (self.корень / 'индекс.md').write_text('Индекс')
        self.assertEqual(self.вызвать()[0], 1)

    def test_сосед_префикс_посторонний_и_корень(self):
        for имя in ('Материалы', 'Материалы-сосед', 'Другой'):
            (self.корень / имя).mkdir(); (self.корень / имя / 'a').write_text('a')
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Материалы](../../Материалы)')
        self.assertEqual(self.вызвать()[0], 1)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Всё](../..)')
        self.assertEqual(self.вызвать()[0], 1)

    def test_независимое_разрешение(self):
        self.assertEqual(self.вызвать([])[0], 1)

    def test_кириллица_эмодзи_и_пробел(self):
        for имя in ('🟡-карточка шага.md', 'Ã©.md', ' край .md'):
            (self.корень / имя).write_text('Карточка')
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Карточка](../../🟡-карточка%20шага.md)\n[Байты](../../Ã©.md)\n[Край](../../%20край%20.md)')
        код, результат = self.вызвать()
        self.assertEqual(код, 0, результат)

    def test_запрос_ребёнка_не_покрывает_29_материалов(self):
        ребёнок = self.корень / 'Журнал/ребёнок'
        ребёнок.mkdir()
        (ребёнок / 'запрос.md').write_text('Исходный запрос')
        for номер in range(29): (ребёнок / f'{номер}.json').write_text('{}')
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Ребёнок](../ребёнок/запрос.md)')
        код, результат = self.вызвать()
        self.assertEqual(код, 1)
        self.assertEqual(sum(ошибка.startswith('unexpected Git status path:') for ошибка in результат['ошибки']), 29)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Состав ребёнка](../ребёнок)')
        self.assertEqual(self.вызвать()[0], 0)

    def test_десять_материалов_без_действительной_ссылки(self):
        материалы = self.запрос.parent / 'материалы'
        материалы.mkdir()
        for номер in range(10): (материалы / f'{номер}.json').write_text('{}')
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\nМатериалы: `материалы/`')
        код, результат = self.вызвать()
        self.assertEqual(код, 1)
        self.assertEqual(sum(ошибка.startswith('unexpected Git status path:') for ошибка in результат['ошибки']), 10)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Материалы](материалы)')
        self.assertEqual(self.вызвать()[0], 0)

    def test_удаление(self):
        путь = self.корень / 'старый.md'; путь.write_text('старый')
        self.git('add', '.'); self.git('-c','user.name=Тест','-c','user.email=test@example.invalid','commit','-qm','Файлы')
        путь.unlink()
        цели = [self.запрос.relative_to(self.корень).as_posix(), 'старый.md']
        self.assertEqual(self.вызвать(цели)[0], 1)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n- Удалённый файл: `старый.md`')
        self.assertEqual(self.вызвать(цели)[0], 0)

    def test_дрейф_байтов_и_индекса(self):
        код, результат = self.вызвать(); self.assertEqual(код,0)
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json') as файл:
            json.dump(результат,файл); файл.flush()
            self.assertEqual(self.вызвать(снимок=файл.name)[0],0)
            self.отчёт.write_text('Дрейф')
            self.assertEqual(self.вызвать(снимок=файл.name)[0],1)
            self.отчёт.write_text('Отчёт\n'); self.git('add','.')
            self.assertEqual(self.вызвать(снимок=файл.name)[0],1)

    def test_дрейф_разрешённого_состава(self):
        _, результат = self.вызвать()
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json') as файл:
            json.dump(результат, файл); файл.flush()
            цели = результат['снимок']['разрешённые_цели'] + ['будущий.md']
            self.assertEqual(self.вызвать(цели, файл.name)[0], 1)

    def test_переименование_требует_исходную_цель(self):
        старый = self.корень / 'старый.md'; старый.write_text('байты')
        self.git('add', '.'); self.git('-c','user.name=Тест','-c','user.email=test@example.invalid','commit','-qm','Файлы')
        self.git('mv', 'старый.md', 'новый.md')
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Новый](../../новый.md)')
        self.assertEqual(self.вызвать()[0], 1)
        self.assertIn('старый.md', self.вызвать()[1]['пути'])

    def test_символическая_ссылка_не_даёт_охват(self):
        (self.корень / 'цель').mkdir()
        (self.корень / 'обход').symlink_to('цель', target_is_directory=True)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Обход](../../обход)')
        self.assertEqual(self.вызвать()[0], 1)

    def test_повторные_разделы_не_дают_охват(self):
        with self.запрос.open('a') as файл: файл.write('\n## Повлиял на файлы\n[Корень](../..)\n')
        self.assertEqual(self.вызвать()[0], 1)

    def test_отслеживаемая_symlink(self):
        (self.корень / 'цель').mkdir()
        (self.корень / 'цель/файл').write_text('байты')
        (self.корень / 'обход').symlink_to('цель', target_is_directory=True)
        self.git('add', '.'); self.git('-c','user.name=Тест','-c','user.email=test@example.invalid','commit','-qm','Файлы')
        for цель in ('../../обход', '../../обход?x', '../../обход%3Fx', '../../обход/../цель/файл'):
            with self.subTest(цель=цель):
                self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Обход](' + цель + ')')
                self.assertEqual(self.вызвать([self.запрос.relative_to(self.корень).as_posix()])[0], 1)

    def test_мутации_внутри_сверки(self):
        описание = importlib.util.spec_from_file_location('ранний_охват_фикстура', ПУТЬ)
        модуль = importlib.util.module_from_spec(описание); описание.loader.exec_module(модуль)
        цели = [п.relative_to(self.корень).as_posix() for п in (self.запрос, self.отчёт)]
        исходные = модуль.СВЯЗНОСТЬ.affected_files_from_request
        def изменить_байты(*аргументы):
            результат = исходные(*аргументы)
            self.запрос.write_text(self.запрос.read_text() + '\nДрейф\n')
            return результат
        with patch.object(модуль.СВЯЗНОСТЬ, 'affected_files_from_request', изменить_байты):
            self.assertFalse(модуль.сверить(self.корень, цели[0], цели)['готов'])
        def изменить_индекс(*аргументы):
            результат = исходные(*аргументы); self.git('add', '.'); return результат
        with patch.object(модуль.СВЯЗНОСТЬ, 'affected_files_from_request', изменить_индекс):
            self.assertFalse(модуль.сверить(self.корень, цели[0], цели)['готов'])
        def изменить_ref(*аргументы):
            результат = исходные(*аргументы); self.git('switch', '-qc', 'другая'); return результат
        with patch.object(модуль.СВЯЗНОСТЬ, 'affected_files_from_request', изменить_ref):
            self.assertFalse(модуль.сверить(self.корень, цели[0], цели)['готов'])


if __name__ == '__main__':
    unittest.main()
