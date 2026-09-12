"""Профиль отклоняет изменение измеряемых исходников между границами."""

import tempfile
import unittest
from pathlib import Path

import профиль_пакетного_анализа as профиль


class ПроверкиПроисхожденияПрофиля(unittest.TestCase):
    def test_изменение_байтов_и_исчезновение_источника_не_принимаются(сам):
        with tempfile.TemporaryDirectory() as временный:
            путь = Path(временный) / "источник.py"
            путь.write_bytes(b"1\n")
            пути = {"источник": путь}
            исходные = профиль.снять_отпечатки(пути)
            профиль.подтвердить_неизменность(пути, исходные)
            путь.write_bytes(b"2\n")
            with сам.assertRaisesRegex(RuntimeError, "Исходники изменились"):
                профиль.подтвердить_неизменность(пути, исходные)
            путь.unlink()
            with сам.assertRaises(FileNotFoundError):
                профиль.подтвердить_неизменность(пути, исходные)


if __name__ == "__main__":
    unittest.main()
