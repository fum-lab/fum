import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import собрать
import смета


class ПроверкиГраниц(unittest.TestCase):
    def test_имя_не_выводит_запись_из_каталога(self):
        for имя in ['../чужой', '/tmp/чужой', 'папка/чужой', 'папка\\чужой', '.', '']:
            with self.subTest(имя=имя), self.assertRaises(ValueError):
                собрать.проверить_имена([{'файл': имя}])

    def test_имена_не_перезаписывают_друг_друга_или_документы(self):
        for имена in [['FUMA-Тест', 'fuma-тест'], ['FUMA-бизнес-план'], ['FUMA-тест.pdf']]:
            with self.subTest(имена=имена), self.assertRaises(ValueError):
                собрать.проверить_имена([{'файл': имя} for имя in имена])

    def test_нулевой_долг_не_требует_ставки(self):
        self.assertEqual(смета.аннуитет(0, None, 36), 0)

    def test_нулевой_курс_не_даёт_бесплатную_подписку(self):
        with self.assertRaises(ValueError):
            смета.рубли(200, 0)


if __name__ == '__main__':
    unittest.main()
