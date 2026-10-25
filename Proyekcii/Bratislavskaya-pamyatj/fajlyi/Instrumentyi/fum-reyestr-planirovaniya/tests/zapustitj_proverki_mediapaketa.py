"""Обычный unittest: полный вывод в stderr, допустимое представление в stdout."""
import hashlib
import io
from pathlib import Path
import sys
import tempfile
import unittest

КОРЕНЬ = Path(__file__).resolve().parents[3]
КАТАЛОГ = Path(__file__).resolve().parent


def выполнить():
    набор = unittest.defaultTestLoader.discover(str(КАТАЛОГ), pattern="test_медиапакет_поддержки.py")
    поток = io.StringIO()
    результат = unittest.TextTestRunner(stream=поток, verbosity=2).run(набор)
    сырой = поток.getvalue()
    sys.stderr.write(сырой)
    представление = сырой.replace(str(КОРЕНЬ), "<корень-FUM>").replace(tempfile.gettempdir(), "<временный-каталог>")
    sys.stdout.write(представление)
    print("SHA-256 полного вывода unittest:", hashlib.sha256(сырой.encode()).hexdigest())
    print("Представление stdout: заменены только корень checkout и системный временный каталог.")
    return 0 if результат.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(выполнить())
