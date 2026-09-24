"""Режим владельца сверяется даже при отключённом наблюдении прав в Git."""
from pathlib import Path
import subprocess
import tempfile
import unittest

from фикстура_дочернего_коммита import коммит


class ПроверкаРежимаИндекса(unittest.TestCase):
    def test_потеря_исполнения_владельцем_отклоняется(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            def гит(*а):
                return subprocess.run(['git', '-C', str(корень), *а], check=True, capture_output=True).stdout
            гит('init', '-q')
            путь = корень / 'импортированный.sh'; путь.write_text('#!/bin/sh\nexit 0\n'); путь.chmod(0o755)
            гит('add', '--', путь.name)
            сам.assertTrue(гит('ls-files', '--stage').startswith(b'100755 '))
            коммит.индекс(корень)
            гит('config', 'core.filemode', 'false')
            путь.chmod(0o655)
            сам.assertEqual(b'', гит('diff', '--name-only'))
            with сам.assertRaisesRegex(коммит.ОшибкаКоммита, 'режим файла'):
                коммит.индекс(корень)
