"""Исторические маркеры и канонический дословный архив остаются данными."""
from pathlib import Path
import tempfile
import unittest

from test_update_md_recency import update_md_recency as свежесть


НАЧАЛО = '<!-- FUM-CHATGPT-SHARE-VERBATIM:BEGIN -->'
КОНЕЦ = '<!-- FUM-CHATGPT-SHARE-VERBATIM:END -->'


class ПроверкаИсторическихМеток(unittest.TestCase):
    def проверить_файл(сам, тело, имя='запрос.md', отказ=False):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            файл = корень / имя
            файл.parent.mkdir(parents=True, exist_ok=True)
            текст = свежесть.attach_recency_block(тело, '2026-09-22 12:00:00 MSK', свежесть.content_digest(тело))
            файл.write_text(текст, encoding='utf-8')
            _, ошибки, изменён = свежесть.process_markdown_file(файл, корень,
                set(), '2026-09-23 12:00:00 MSK', False, False)
            сам.assertEqual(bool(ошибки), отказ)
            сам.assertFalse(изменён)
            сам.assertEqual(файл.read_bytes(), текст.encode('utf-8'))

    def test_pending_перед_действительным_блоком_сохраняется(сам):
        сам.проверить_файл('# Запрос\n\n<!-- FUM-MD-RECENCY:BEGIN -->\n'
            '<!-- content-sha256: pending -->\n<!-- FUM-MD-RECENCY:END -->\n')

    def test_сломанный_конец_не_откатывается_к_старой_метке(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный); файл = корень / 'запрос.md'
            текст = свежесть.attach_recency_block('# Запрос\n', '2026-09-22 12:00:00 MSK', 'a' * 64)
            текст += '\n<!-- FUM-MD-RECENCY:BEGIN -->\n'
            файл.write_text(текст, encoding='utf-8')
            _, ошибки, изменён = свежесть.process_markdown_file(файл, корень,
                set(), '2026-09-23 12:00:00 MSK', False, False)
            сам.assertTrue(ошибки); сам.assertFalse(изменён)
            сам.assertEqual(файл.read_bytes(), текст.encode('utf-8'))

    def test_дословный_архив_маскируется_только_в_канонической_области(сам):
        тело = '# Архив\n\n## Диалог\n\n' + НАЧАЛО + '\n```text\nСырой фрагмент\n' + КОНЕЦ + '\n'
        for имя, отказ in [('Источники/URL/https/chatgpt.com/share/id/диалог.md', False),
                           ('запрос.md', True)]:
            with сам.subTest(имя=имя):
                сам.проверить_файл(тело, имя, отказ)

    def test_ошибочные_границы_архива_не_дают_исключения(сам):
        имя = 'Источники/URL/https/chatgpt.com/share/id/диалог.md'
        for тело in [
            '## Диалог\n'+НАЧАЛО+'\n```text\n',
            '## Диалог\n'+НАЧАЛО+'\n'+НАЧАЛО+'\n```text\n'+КОНЕЦ+'\n',
            '## Другое\n'+НАЧАЛО+'\n```text\n'+КОНЕЦ+'\n',
            '    ## Диалог\n'+НАЧАЛО+'\n```text\n'+КОНЕЦ+'\n',
            '## Диалог\n'+НАЧАЛО+'\nДанные\n'+КОНЕЦ+'\n```text\n',
        ]:
            with сам.subTest(тело=тело):
                сам.проверить_файл(тело, имя, True)


if __name__ == '__main__':
    unittest.main()
