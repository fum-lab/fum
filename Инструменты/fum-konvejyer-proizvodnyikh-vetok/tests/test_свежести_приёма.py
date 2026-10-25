"""Оба входа собственной свежести проверяются до первого изменения."""
from pathlib import Path
import re
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import свежесть_приёма


class ПроверкаСвежестиПриёма(unittest.TestCase):
    def подготовить(сам):
        корень = Path(сам.enterContext(tempfile.TemporaryDirectory())).resolve()
        имена = ['запрос.md', 'отчёт.md']
        for имя in имена:
            (корень / имя).write_text('# Открытая фикстура\n\nСодержательный текст.\n')
        return корень, имена

    def test_план_только_читает_и_сохраняет_содержание(сам):
        корень, имена = сам.подготовить()
        файлы, прежние = свежесть_приёма.подготовить_пару(корень, имена)
        сам.assertEqual(len(файлы), 2)
        for файл in файлы:
            имя = файл.path.as_posix()
            сам.assertEqual((корень / имя).read_bytes(), прежние[имя][0])
            сам.assertIn(прежние[имя][0].rstrip(), файл.data)
            (корень / имя).write_bytes(файл.data)
        сам.assertEqual(свежесть_приёма.подготовить_пару(корень, имена)[0], [])

    def test_неисправный_второй_вход_не_меняет_первый(сам):
        корень, имена = сам.подготовить()
        первый = (корень / имена[0]).read_bytes()
        второй = корень / имена[1]
        готовые, _ = свежесть_приёма.подготовить_пару(корень, имена)
        неверное_время = re.sub(rb'last-content-edit: [^\n]+ -->',
            b'last-content-edit: nonsense -->', готовые[1].data)
        for содержимое in (None, b'# CRLF\r\n', b'\xff',
                b'# Text\n<!-- FUM-MD-RECENCY:BEGIN -->\ninvalid\n', неверное_время):
            with сам.subTest(содержимое=содержимое):
                if второй.exists():
                    второй.unlink()
                if содержимое is not None:
                    второй.write_bytes(содержимое)
                with сам.assertRaises((ValueError, OSError)):
                    свежесть_приёма.подготовить_пару(корень, имена)
                сам.assertEqual((корень / имена[0]).read_bytes(), первый)


if __name__ == '__main__':
    unittest.main()
