"""Адресный набор входа, снимка и совместимости прежнего холодного CLI."""
import unittest


if __name__ == '__main__':
    набор = unittest.TestSuite(unittest.defaultTestLoader.loadTestsFromName(имя) for имя in (
        'test_снимка_нативного_источника', 'test_приватного_входа_передачи',
        'test_холодного_дочернего_коммита'))
    результат = unittest.TextTestRunner(verbosity=1).run(набор)
    raise SystemExit(0 if результат.wasSuccessful() else 1)
