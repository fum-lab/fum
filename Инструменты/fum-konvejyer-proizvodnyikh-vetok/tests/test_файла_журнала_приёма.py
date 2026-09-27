"""Восстановление байтового префикса без присвоения чужого временного файла."""
import os
from pathlib import Path
import stat
import tempfile
import unittest

from фикстура_слияния_приёма import эпизод
import файл_журнала_приёма as файл


class ПроверкаФайлаЖурнала(unittest.TestCase):
    def test_дописать_пустой_частичный_и_полный_префикс(сам):
        данные = 'Ёж и 🙂\n'.encode('utf-8')
        for длина in (0, 1, 3, len(данные)):
            with сам.subTest(длина=длина), tempfile.TemporaryDirectory() as папка:
                корень = Path(папка).resolve()
                временный, цель = корень / '.свой', корень / 'отчёт.md'
                временный.write_bytes(данные[:длина]); временный.chmod(0o600)
                файл.установить(цель, временный, данные, 0o644)
                сам.assertEqual(цель.read_bytes(), данные)
                сам.assertEqual(stat.S_IMODE(цель.stat().st_mode), 0o644)
                сам.assertFalse(временный.exists())

    def test_чужой_префикс_режим_и_ссылка_не_изменяются(сам):
        for случай in ('байты', 'режим', 'жёсткая ссылка', 'символическая ссылка'):
            with сам.subTest(случай=случай), tempfile.TemporaryDirectory() as папка:
                корень = Path(папка).resolve()
                временный, цель = корень / '.свой', корень / 'отчёт.md'
                источник = корень / 'источник'; источник.write_bytes(b'x'); источник.chmod(0o600)
                if случай == 'символическая ссылка': временный.symlink_to(источник)
                elif случай == 'жёсткая ссылка': os.link(источник, временный)
                else:
                    временный.write_bytes(b'z' if случай == 'байты' else b'x')
                    временный.chmod(0o666 if случай == 'режим' else 0o600)
                до = временный.read_bytes()
                with сам.assertRaises(ValueError): файл.установить(цель, временный, b'xyz', 0o644)
                сам.assertFalse(цель.exists())
                сам.assertEqual(временный.read_bytes(), до)
                сам.assertEqual(источник.read_bytes(), b'x')

    def test_существующий_результат_не_заменяется(сам):
        with tempfile.TemporaryDirectory() as папка:
            корень = Path(папка).resolve(); цель = корень / 'отчёт.md'
            цель.write_bytes(b'keep')
            with сам.assertRaises(ValueError): файл.установить(цель, корень / '.свой', b'new', 0o644)
            сам.assertEqual(цель.read_bytes(), b'keep')


if __name__ == '__main__':
    unittest.main()
