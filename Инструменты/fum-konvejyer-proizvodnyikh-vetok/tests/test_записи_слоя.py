"""Запись конечного плана проверяет всю область до первого файла."""
import importlib
import os
from pathlib import PurePosixPath
import unittest
from unittest import mock

from test_области_писателя import область_фикстура
from test_запуска_слоёв import хранение, ЗАДАЧА


class ПроверкаЗаписиСлоя(unittest.TestCase):
    def test_установка_пары_сохраняет_поручение_корня_и_не_пишет_общие_файлы(self):
        with область_фикстура(v2=True) as (_, _, _, _, назначение, дети):
            корень, задача, источник = дети['события']
            модуль = importlib.import_module('журнал_слоя')
            общий = (корень / 'общий.txt').read_bytes()
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                итог = модуль.установить(корень, задача, источник)
                повтор = модуль.установить(корень, задача, источник)
            запрос = корень / назначение['журналы']['события'] / 'запрос.md'
            текст = запрос.read_text()
            self.assertIn('Codex-Thread-ID: ' + ЗАДАЧА, текст)
            self.assertIn('<fum_layer_assignment>', текст)
            self.assertIn('отложен до передачи координатору', текст)
            self.assertEqual(итог['происхождение'], 'первоначальное поручение корня')
            self.assertTrue(повтор['повтор'])
            self.assertEqual(общий, (корень / 'общий.txt').read_bytes())
            self.assertFalse((корень / 'Журнал/README.md').exists())

    def test_чужая_цель_в_конце_плана_не_оставляет_первой_записи(self):
        with область_фикстура(v2=True) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            запись = importlib.import_module('запись_слоя')
            журнал = importlib.import_module('журнал_слоя')
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                файлы, сведения = журнал.подготовить(корень, задача, источник, ['Открытая фикстура.'])
                план = [*файлы, журнал.каркас.PreparedFile(PurePosixPath('общий.txt'), b'foreign', 0o644)]
                with self.assertRaisesRegex(ValueError, 'област'):
                    запись.установить(корень, задача, источник, план, сведения['назначение_sha256'])
            self.assertTrue(all(not (корень / файл.path).exists() for файл in файлы))
            self.assertEqual('Общая база\n', (корень / 'общий.txt').read_text())

    def test_устаревший_план_отклоняется_до_записи(self):
        with область_фикстура(v2=True) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            запись = importlib.import_module('запись_слоя')
            журнал = importlib.import_module('журнал_слоя')
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                файлы, сведения = журнал.подготовить(корень, задача, источник, ['Открытая фикстура.'])
                новый = корень / 'Память/события/новый.txt'
                новый.parent.mkdir(parents=True)
                новый.write_text('Изменение после плана\n')
                with self.assertRaisesRegex(ValueError, 'сдвинул|устарел'):
                    запись.установить(корень, задача, источник, файлы, сведения['назначение_sha256'])
            self.assertTrue(all(not (корень / файл.path).exists() for файл in файлы))

    def test_ошибка_второго_файла_восстанавливает_первый(self):
        with область_фикстура(v2=True) as (_, _, _, _, назначение, дети):
            корень, задача, источник = дети['события']
            журнал = importlib.import_module('журнал_слоя')
            исходная = журнал.каркас._install_prepared_file
            счётчик = []
            def установить(root, файл):
                счётчик.append(файл.path)
                if len(счётчик) == 2:
                    raise OSError('Сбой второго файла')
                return исходная(root, файл)
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача), \
                    mock.patch.object(журнал.каркас, '_install_prepared_file', side_effect=установить):
                with self.assertRaisesRegex(Exception, 'Сбой второго файла'):
                    журнал.установить(корень, задача, источник)
            self.assertFalse((корень / назначение['журналы']['события']).exists())

    def test_собственная_свежесть_обновляется_без_общего_индекса(self):
        with область_фикстура(v2=True) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            свежесть = importlib.import_module('свежесть_слоя')
            путь = корень / 'Память/события/README.md'
            путь.parent.mkdir(parents=True)
            путь.write_text('# Открытый слой\n')
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                до = путь.read_bytes()
                план = свежесть.подготовить(корень, задача, источник)
                self.assertEqual(до, путь.read_bytes())
                свежесть.применить(корень, задача, источник, план)
                повтор = свежесть.подготовить(корень, задача, источник)
            self.assertIn('FUM-MD-RECENCY:BEGIN', путь.read_text())
            self.assertEqual([], повтор['файлы'])
            self.assertFalse((корень / 'Индексы').exists())

    def test_повреждённый_последний_файл_не_обновляет_первый(self):
        with область_фикстура(v2=True) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            свежесть = importlib.import_module('свежесть_слоя')
            каталог = корень / 'Память/события'
            каталог.mkdir(parents=True)
            первый = каталог / 'а.md'; первый.write_text('# Первый\n')
            (каталог / 'я.md').write_text('# Повреждённый\n<!-- FUM-MD-RECENCY:BEGIN -->\n')
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                with self.assertRaisesRegex(ValueError, 'recency|свежест|metadata'):
                    свежесть.подготовить(корень, задача, источник)
            self.assertEqual('# Первый\n', первый.read_text())

    def test_переносимые_коллизии_всего_плана_отклоняются_до_транзакции(self):
        with область_фикстура(v2=True) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            запись = importlib.import_module('запись_слоя')
            пары = [('А.md', 'а.md'), ('А', 'а/файл'),
                    ('Каталог/а', 'каталог/б'), ('ё.md', 'е\u0308.md')]
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                назначение = запись.дочернее_назначение.прочитать(корень, задача, источник)
                for имена in пары:
                    with self.subTest(имена=имена):
                        план = [запись.каркас.PreparedFile(PurePosixPath('Память/события/' + имя), b'x', 0o644)
                                for имя in имена]
                        with mock.patch.object(запись.каркас, '_apply_prepared_transaction',
                                               side_effect=AssertionError('Установка началась')):
                            with self.assertRaisesRegex(ValueError, 'коллиз|пересека'):
                                запись.установить(корень, задача, источник, план, назначение['sha256'])
            self.assertFalse((корень / 'Память').exists())

    def test_чужая_среда_Git_не_скрывает_игнорируемую_цель(self):
        with область_фикстура(v2=True) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            запись = importlib.import_module('запись_слоя')
            каталог = корень / 'Память/события'
            каталог.mkdir(parents=True)
            (каталог / '.gitignore').write_text('скрыто.txt\n')
            чужой = корень.parent / 'чужой'; чужой.mkdir()
            хранение.гит(чужой, 'init', '-q')
            план = [запись.каркас.PreparedFile(PurePosixPath('Память/события/' + имя), b'x', 0o644)
                    for имя in ('первый.txt', 'скрыто.txt')]
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                назначение = запись.дочернее_назначение.прочитать(корень, задача, источник)
                with mock.patch.dict(os.environ, GIT_DIR=str(чужой / '.git'), GIT_WORK_TREE=str(чужой)):
                    with self.assertRaisesRegex(ValueError, 'игнорируем'):
                        запись.установить(корень, задача, источник, план, назначение['sha256'])
            self.assertTrue(all(not (корень / файл.path).exists() for файл in план))

    def test_свежесть_сверяет_байты_неизменяемого_входа_даже_при_чистом_Git(self):
        модуль = importlib.import_module('свежесть_слоя')
        def подготовить_базу(корень):
            каталог = корень / 'Память/события'; каталог.mkdir(parents=True)
            содержание = '# Первый\n'
            (каталог / 'а.md').write_text(модуль.свежесть.attach_recency_block(содержание,
                '2026-09-23 12:00:00 MSK', модуль.свежесть.content_digest(содержание)))
        with область_фикстура(v2=True, подготовить_базу=подготовить_базу) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            каталог = корень / 'Память/события'
            исходный = каталог / 'а.md'
            хранение.гит(корень, 'config', 'core.trustctime', 'false')
            хранение.гит(корень, 'config', 'core.checkStat', 'minimal')
            # Старый mtime исключает защиту racy-git и позволяет воспроизвести
            # неизменный Git-статус после побайтовой подмены того же размера.
            os.utime(исходный, (1_700_000_000, 1_700_000_000))
            хранение.гит(корень, 'update-index', '--refresh')
            цель = каталог / 'б.md'; цель.write_text('# Второй\n')
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                план = модуль.подготовить(корень, задача, источник)
                self.assertEqual(['Память/события/б.md'], [ф.path.as_posix() for ф in план['файлы']])
                до = исходный.stat()
                исходный.write_bytes(исходный.read_bytes().replace('Первый'.encode(), 'Второй'.encode()))
                os.utime(исходный, ns=(до.st_atime_ns, до.st_mtime_ns))
                self.assertEqual('', хранение.гит(корень, 'diff', '--name-only', '--', 'Память/события/а.md'))
                with self.assertRaisesRegex(ValueError, 'байты|вход|сдвину'):
                    модуль.применить(корень, задача, источник, план)
            self.assertEqual('# Второй\n', цель.read_text())

    def test_календарно_невозможная_метка_отклоняется_до_любых_записей(self):
        with область_фикстура(v2=True) as (_, _, _, _, _, дети):
            корень, задача, источник = дети['события']
            модуль = importlib.import_module('свежесть_слоя')
            каталог = корень / 'Память/события'; каталог.mkdir(parents=True)
            первый = каталог / 'а.md'; первый.write_text('# Первый\n')
            содержание = '# Последний\n'
            (каталог / 'я.md').write_text(модуль.свежесть.attach_recency_block(содержание,
                '2026-02-31 12:00:00 MSK', модуль.свежесть.content_digest(содержание)))
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                with self.assertRaisesRegex(ValueError, 'дат|врем|day'):
                    модуль.подготовить(корень, задача, источник)
            self.assertEqual('# Первый\n', первый.read_text())
