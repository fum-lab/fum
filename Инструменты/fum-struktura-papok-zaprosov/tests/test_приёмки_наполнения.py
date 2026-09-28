"""Конечный состав проверки наполнения: блоки, интерфейсы и прежние границы."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parent))


def load_tests(загрузчик, набор, маска):
    return загрузчик.loadTestsFromNames(('test_управляемых_блоков', 'test_наполнения_карточки',
                                        'test_регрессии_наполнения'))


if __name__ == '__main__':
    unittest.main()
