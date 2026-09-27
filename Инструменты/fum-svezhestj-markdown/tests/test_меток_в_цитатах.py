"""Служебная метка внутри дословной ограды остаётся исходными данными."""
from pathlib import Path
import tempfile
import unittest

from test_update_md_recency import update_md_recency as свежесть


def цитата(ограда='````', отступ=''):
    метка = свежесть.attach_recency_block('Сохранить ё, пробелы  и повторы.\n',
        '2026-09-22 12:00:00 MSK', 'a' * 64)
    return '# Поручение\n\n' + отступ + ограда + 'text\n' + метка + отступ + ограда + '\n\n## После цитаты\n\nНе менять.\n'


class ПроверкаЦитированныхМеток(unittest.TestCase):
    def test_ограждённые_метки_не_являются_метаданными_файла(сам):
        for ограда, отступ in [('````', ''), ('~~~', ''), ('```', '   ')]:
            with сам.subTest(ограда=ограда, отступ=отступ):
                текст = цитата(ограда, отступ)
                содержание, метаданные, повреждение = свежесть.split_recency_block(текст)
                сам.assertEqual(содержание, текст)
                сам.assertIsNone(метаданные)
                сам.assertFalse(повреждение)

    def test_читается_наружная_конечная_метка(сам):
        содержание = цитата()
        хэш = свежесть.content_digest(содержание)
        текст = свежесть.attach_recency_block(содержание, '2026-09-23 12:00:00 MSK', хэш)
        получено, метаданные, повреждение = свежесть.split_recency_block(текст)
        сам.assertEqual(получено, содержание)
        сам.assertEqual(метаданные.timestamp, '2026-09-23 12:00:00 MSK')
        сам.assertEqual(метаданные.digest, хэш)
        сам.assertFalse(повреждение)

    def test_обновление_и_повтор_сохраняют_исходные_байты(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            файл = корень / 'запрос.md'
            исходный = цитата()
            файл.write_text(исходный, encoding='utf-8')
            запись, ошибки, изменён = свежесть.process_markdown_file(файл, корень,
                {'запрос.md'}, '2026-09-23 12:00:00 MSK', False, False)
            сам.assertEqual(ошибки, [])
            сам.assertTrue(изменён)
            сам.assertTrue(файл.read_bytes().startswith(исходный.encode('utf-8')))
            до = файл.read_bytes()
            _, ошибки, изменён = свежесть.process_markdown_file(файл, корень,
                set(), '2026-09-24 12:00:00 MSK', False, False)
            сам.assertEqual(ошибки, [])
            сам.assertFalse(изменён)
            сам.assertEqual(файл.read_bytes(), до)

    def test_сломанная_наружная_метка_не_скрывается_за_цитатой(сам):
        текст = цитата() + '\n<!-- FUM-MD-RECENCY:BEGIN -->\n'
        содержание, метаданные, повреждение = свежесть.split_recency_block(текст)
        сам.assertEqual(содержание, текст)
        сам.assertIsNone(метаданные)
        сам.assertTrue(повреждение)

    def test_короткая_ограда_не_закрывает_длинную(сам):
        текст = '````text\n```\n' + свежесть.attach_recency_block('Данные\n',
            '2026-09-22 12:00:00 MSK', 'a' * 64) + '````\n'
        сам.assertEqual(свежесть.split_recency_block(текст), (текст, None, False))

    def test_незакрытая_ограда_не_разрешает_служебную_запись(сам):
        текст = '```text\n' + свежесть.attach_recency_block('Данные\n',
            '2026-09-22 12:00:00 MSK', 'a' * 64)
        содержание, метаданные, повреждение = свежесть.split_recency_block(текст)
        сам.assertEqual(содержание, текст)
        сам.assertIsNone(метаданные)
        сам.assertTrue(повреждение)

    def test_прежняя_метка_остаётся_содержимым(сам):
        метка = свежесть.attach_recency_block('# Данные\n', '2026-09-22 12:00:00 MSK', 'a' * 64)
        текст = свежесть.attach_recency_block(метка, '2026-09-23 12:00:00 MSK', 'b' * 64)
        содержание, конечная, повреждение = свежесть.split_recency_block(текст)
        сам.assertEqual(содержание, метка)
        сам.assertEqual(конечная.digest, 'b' * 64)
        сам.assertFalse(повреждение)

    def test_юникодный_пробел_не_закрывает_ограду(сам):
        for хвост in ('\u00a0', '\u2003', '\u2028'):
            with сам.subTest(хвост=repr(хвост)), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                файл = корень / 'запрос.md'
                исходный = '```text\nДанные\n```' + хвост + '\n' + свежесть.attach_recency_block(
                    'Всё ещё цитата\n', '2026-09-22 12:00:00 MSK', 'a' * 64)
                файл.write_text(исходный, encoding='utf-8')
                сам.assertEqual(свежесть.split_recency_block(исходный), (исходный, None, True))
                _, ошибки, изменён = свежесть.process_markdown_file(файл, корень,
                    {'запрос.md'}, '2026-09-23 12:00:00 MSK', False, False)
                сам.assertTrue(ошибки)
                сам.assertFalse(изменён)
                сам.assertEqual(файл.read_bytes(), исходный.encode('utf-8'))

    def test_плохая_метка_не_вызывает_записи(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            файл = корень / 'запрос.md'
            исходный = '# Данные\n<!-- FUM-MD-RECENCY:BEGIN -->\n'
            файл.write_text(исходный, encoding='utf-8')
            _, ошибки, изменён = свежесть.process_markdown_file(файл, корень,
                {'запрос.md'}, '2026-09-23 12:00:00 MSK', False, False)
            сам.assertTrue(ошибки)
            сам.assertFalse(изменён)
            сам.assertEqual(файл.read_bytes(), исходный.encode('utf-8'))

    def test_метка_в_середине_строки_не_служебная(сам):
        for префикс in ('Пример: ', '    '):
            with сам.subTest(префикс=префикс):
                текст = префикс + свежесть.render_recency_block('2026-09-22 12:00:00 MSK', 'a' * 64)
                сам.assertEqual(свежесть.split_recency_block(текст), (текст, None, True))


if __name__ == '__main__':
    unittest.main()
