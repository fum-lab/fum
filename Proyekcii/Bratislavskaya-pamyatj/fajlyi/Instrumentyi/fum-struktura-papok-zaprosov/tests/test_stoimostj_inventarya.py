"""Границы допуска и стоимость обхода публикуемых путей."""
from pathlib import PurePosixPath
import importlib.util
import sys
import unittest
from unittest import mock

from test_request_folder_layout import RepositoryFixture, MODULE, LATE, путь_проверяемой_реализации


class ПутьСоСчётчиком(PurePosixPath):
    обращений = 0

    @property
    def parents(self):
        type(self).обращений += 1
        return super().parents


class СтоимостьИнвентаря(unittest.TestCase):
    def setUp(self):
        self.фикстура = RepositoryFixture()
        self.addCleanup(self.фикстура.close)
        self.фикстура.make_canonical_layout()
        модуль = путь_проверяемой_реализации(MODULE)
        sys.path.insert(0, str(модуль.parent))
        self.addCleanup(sys.path.remove, str(модуль.parent))
        спецификация = importlib.util.spec_from_file_location('стоимость_структуры', модуль)
        self.модуль = importlib.util.module_from_spec(спецификация)
        sys.modules[спецификация.name] = self.модуль
        спецификация.loader.exec_module(self.модуль)

    def test_игнорируемые_каталоги_не_умножают_обход_инвентаря(self):
        self.фикстура.write('.gitignore', 'Журнал/локальный-*/\n')
        for номер in range(40):
            self.фикстура.write(f'Журнал/локальный-{номер}/кэш.bin', b'cache')
        for номер in range(80):
            self.фикстура.write(f'Данные/{номер}/значение.txt', 'данные')
        исходный = self.модуль._project_relative_files
        инвентарь = исходный(self.фикстура.root)
        ПутьСоСчётчиком.обращений = 0
        def наблюдать(корень):
            return [ПутьСоСчётчиком(путь) for путь in исходный(корень)]
        with mock.patch.object(self.модуль, '_project_relative_files', side_effect=наблюдать):
            результат = self.модуль.validate_layout(self.фикстура.root)
        self.assertEqual(результат['sessions'], 1)
        self.assertLessEqual(ПутьСоСчётчиком.обращений, 3 * len(инвентарь))

    def test_публикуемый_лист_в_лишнем_каталоге_отклоняется(self):
        self.фикстура.write(f'Журнал/{LATE}/лишний/глубже/лист.txt', 'данные')
        with self.assertRaisesRegex(self.модуль.LayoutError, 'unexpected top-level entry'):
            self.модуль.validate_layout(self.фикстура.root)

    def test_игнорируемый_лист_не_становится_публикуемым(self):
        self.фикстура.write('.gitignore', 'Журнал/*/лишний/\n')
        self.фикстура.write(f'Журнал/{LATE}/лишний/глубже/лист.txt', 'данные')
        self.assertEqual(self.модуль.validate_layout(self.фикстура.root)['sessions'], 1)
        self.фикстура.git('add', '-f', '--', f'Журнал/{LATE}/лишний/глубже/лист.txt')
        with self.assertRaisesRegex(self.модуль.LayoutError, 'unexpected top-level entry'):
            self.модуль.validate_layout(self.фикстура.root)

    def test_одноимённый_префикс_не_делает_папку_публикуемой(self):
        self.фикстура.write('.gitignore', 'Журнал/локальный/\n')
        self.фикстура.write('Журнал/локальный/кэш.bin', b'cache')
        self.фикстура.write('Журнал/локальный-другой/лист.txt', 'данные')
        with self.assertRaisesRegex(self.модуль.LayoutError, 'journal request folder: локальный-другой$'):
            self.модуль.validate_layout(self.фикстура.root)

    def test_символическая_ссылка_по_прежнему_отклоняется(self):
        (self.фикстура.root / 'Журнал' / 'ссылка').symlink_to(LATE, target_is_directory=True)
        with self.assertRaises(self.модуль.LayoutError):
            self.модуль.validate_layout(self.фикстура.root)


if __name__ == '__main__':
    unittest.main()
