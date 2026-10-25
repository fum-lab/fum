"""Точная версия каталога определяет служебный блок нового отчёта."""
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

import test_update_md_recency as прежние

КОРЕНЬ = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(КОРЕНЬ / 'Инструменты/fum-struktura-papok-zaprosov/tests'))
import test_братиславского_имени_пары as пары


class СвежестьПары2(unittest.TestCase):
    @classmethod
    def setUpClass(класс):
        пары.БратиславскоеИмяПары.setUpClass()
        файлы, класс.план = пары.БратиславскоеИмяПары().новая_пара()
        класс.отчёт = next(ф for ф in файлы if ф.path.name == 'отчёт.md')
        каталоги = класс.план['имя']['каталоги']
        класс.каталог = '/'.join(каталоги[к] for к in ('материалы', 'запуски-проверок'))

    def test_переход_открытого_в_закрытый_не_меняет_дату_и_индекс(сам):
        м = прежние.update_md_recency
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            отчёт = корень / сам.отчёт.path
            отчёт.parent.mkdir(parents=True)
            отчёт.write_bytes(сам.отчёт.data)
            первый = м.update_repository(корень, now=м.parse_now('2026-10-25T12:00:00+03:00'), use_git=False)
            сам.assertEqual([], первый.errors)
            индекс = корень / м.INDEX_PATH
            исходный_индекс = индекс.read_bytes()
            открытый = '<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=' + сам.каталог + ' -->'
            закрытый = ('<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок='
                + сам.каталог + '/снимок.json; sha256=sha256:' + 'a' * 64 + ' -->')
            тело = отчёт.read_text().replace(открытый, закрытый)
            конец = '<!-- FUM-CHECK-RUNS:END -->'
            а = тело.index(закрытый) + len(закрытый)
            б = тело.index(конец)
            тело = тело[:а] + '\n| Итог | Время |\n| ---- | ----- |\n| Успешно | 2 с |\n' + тело[б:]
            отчёт.write_text(тело)
            второй = м.update_repository(корень, now=м.parse_now('2026-10-25T13:00:00+03:00'), check=True, use_git=False)
            сам.assertEqual([], второй.errors)
            сам.assertEqual([], второй.changed_paths)
            сам.assertEqual(исходный_индекс, индекс.read_bytes())
            сам.assertIn('<!-- last-content-edit: 2026-10-25 12:00:00 MSK -->', отчёт.read_text())

    def test_смешение_поколений_и_повторы_не_маскируются(сам):
        м = прежние.update_md_recency
        текст = сам.отчёт.data.decode()
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            новые_смешения = [
                текст.replace(сам.каталог, 'материалы/запуски-проверок'),
                текст.replace('FUM-ОБЫЧНЫЙ-ЖУРНАЛ: 2', 'FUM-ОБЫЧНЫЙ-ЖУРНАЛ: 1'),
                текст.replace(сам.каталог, сам.каталог.upper()),
                текст.replace('<!-- FUM-CHECK-RUNS:END -->', '<!-- FUM-CHECK-RUNS:END -->\n<!-- FUM-CHECK-RUNS:END -->'),
                текст.replace('<!-- FUM-CHECK-RUNS:BEGIN ', '<!-- FUM-CHECK-RUNS:BEGIN лишний -->\n<!-- FUM-CHECK-RUNS:BEGIN '),
            ]
            случаи = [(сам.отчёт.path, т) for т in новые_смешения]
            случаи.append((Path('Журнал/2026-10-25_12-00-00_MSK_создать-краткую-запись/отчёт.md'), текст))
            случаи.append((Path('Журнал/2026-10-25_12-00-00_MSK_создать-краткую-запись/отчёт.md'),
                текст.replace(сам.каталог, 'материалы/запуски-проверок')))
            for путь, данные in случаи:
                with сам.subTest(путь=путь, данные=данные[:100]):
                    результат, отказ = м.стабильное_содержание_отчёта(корень / путь, корень, данные)
                    сам.assertTrue(отказ)
                    сам.assertEqual(данные, результат)

    def test_повтор_маркера_отклонён_до_дорогой_проверки_имени(сам):
        м = прежние.update_md_recency
        текст = сам.отчёт.data.decode() + '\n<!-- FUM-CHECK-RUNS:END -->\n'
        with mock.patch.object(м, '_блок_запусков_нового_отчёта',
                side_effect=AssertionError('Не требуется преобразование заведомого повтора')):
            результат, отказ = м.стабильное_содержание_отчёта(
                КОРЕНЬ / сам.отчёт.path, КОРЕНЬ, текст)
        сам.assertTrue(отказ)
        сам.assertEqual(текст, результат)


if __name__ == '__main__':
    unittest.main()
