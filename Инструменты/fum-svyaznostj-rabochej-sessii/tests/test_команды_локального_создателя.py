"""Выбор текущего проверяющего без скрытого возврата к старому контуру."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

СКРИПТЫ = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(СКРИПТЫ))
from команда_локального_создателя import команда


class ЛокальныйСоздатель(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.папка = Path(self.временный.name).resolve()
        self.рабочий = self.папка / 'текущий'
        self.старый = self.папка / 'старый'
        for корень, ответ in ((self.рабочий, 'новый'), (self.старый, 'старый')):
            каталог = корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts'
            каталог.mkdir(parents=True)
            for имя in ('создание_коммита.py', 'типизированная_контрольная_точка.py'):
                (каталог / имя).write_text(
                    'import json,sys\nprint(json.dumps([' + repr(ответ) +
                    ',sys.argv[1:]],ensure_ascii=False))\n', encoding='utf-8')

    def путь(self, имя):
        return self.рабочий / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts' / имя

    def test_фактический_запуск_нового_кода_сохраняет_аргументы(self):
        аргументы = ['--подготовка', 'путь с пробелами', '--проверка', 'RAW',
                     '--выбранный-состав', 'S2']
        for действие in ('подготовить', 'подготовить-повтор', 'первичная-сверка', 'готово', 'создать'):
            with self.subTest(действие=действие):
                argv = команда(self.рабочий, sys.executable, действие, аргументы)
                итог = subprocess.check_output(argv, cwd=self.старый)
                self.assertEqual(json.loads(итог), ['новый', [действие, *аргументы]])

    def test_нет_локального_файла_значит_нет_возврата_к_старому(self):
        self.путь('типизированная_контрольная_точка.py').unlink()
        with self.assertRaises(ValueError):
            команда(self.рабочий, sys.executable, 'создать', [])

    def test_ссылка_на_старый_контур_запрещена(self):
        p = self.путь('типизированная_контрольная_точка.py')
        p.unlink()
        p.symlink_to(self.старый / p.relative_to(self.рабочий))
        with self.assertRaises(ValueError):
            команда(self.рабочий, sys.executable, 'создать', [])

    def test_ссылка_в_предке_и_алиас_корня_запрещены(self):
        alias = self.папка / 'алиас'
        alias.symlink_to(self.рабочий, target_is_directory=True)
        with self.assertRaises(ValueError):
            команда(alias, sys.executable, 'готово', [])
        moved = self.рабочий / 'исходники'
        original = self.рабочий / 'Инструменты'
        original.rename(moved)
        original.symlink_to(moved, target_is_directory=True)
        with self.assertRaises(ValueError):
            команда(self.рабочий, sys.executable, 'готово', [])

    def test_каталог_вместо_файла_и_неизвестное_действие_запрещены(self):
        p = self.путь('создание_коммита.py')
        p.unlink()
        p.mkdir()
        with self.assertRaises(ValueError):
            команда(self.рабочий, sys.executable, 'подготовить', [])
        with self.assertRaises(ValueError):
            команда(self.рабочий, sys.executable, 'внешний-контур', [])

    def test_настоящие_импорты_в_свежем_процессе_локальны(self):
        код = ('import sys,json;sys.path.insert(0,sys.argv[1]);'
               'import типизированная_контрольная_точка as t;'
               'print(json.dumps([t.__file__,t.коммит.__file__]))')
        сырые = subprocess.check_output(
            [sys.executable, '-E', '-s', '-S', '-B', '-c', код, str(СКРИПТЫ)],
            cwd=self.старый)
        self.assertEqual([Path(p).resolve() for p in json.loads(сырые)],
                         [СКРИПТЫ / 'типизированная_контрольная_точка.py',
                          СКРИПТЫ / 'создание_коммита.py'])


if __name__ == '__main__':
    unittest.main()
