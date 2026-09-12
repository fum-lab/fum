import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest

путь = Path(__file__).with_name('проверить-пакет.py')
спецификация = importlib.util.spec_from_file_location('среда_проверок', путь)
среда = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(среда)


class ПроверкиСреды(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.разработчик = self.корень / 'Инструменты Apple'
        self.пакет = self.корень / 'Пакет'; self.пакет.mkdir()
        (self.пакет / 'Package.swift').write_text('// фикстура')
        self.кэш = self.корень / 'Кэш'
        self.пути = [
            'usr/bin/swift',
            'usr/lib/swift/host/plugins/testing/libTestingMacros.dylib',
            'Library/Developer/Frameworks/Testing.framework/Versions/A/Testing',
            'Library/Developer/usr/lib/lib_TestingInterop.dylib',
        ]
        for имя in self.пути:
            файл = self.разработчик / имя; файл.parent.mkdir(parents=True, exist_ok=True); файл.write_bytes(b'fixture')

    def test_производные_пути_и_фильтр_передаются_отдельными_аргументами(self):
        команда = среда.построитьКоманду(self.разработчик, self.пакет, self.кэш, 'одинПриёмник')
        self.assertEqual(команда[0], str(self.разработчик / 'usr/bin/swift'))
        self.assertIn(str(self.разработчик / self.пути[1]), команда)
        self.assertIn(str(self.разработчик / 'Library/Developer/Frameworks'), команда)
        self.assertIn(str(self.разработчик / 'Library/Developer/usr/lib'), команда)
        self.assertEqual(команда[-2:], ['--filter', 'одинПриёмник'])
        self.assertEqual(команда[команда.index('--jobs') + 1], '1')

    def test_неполный_комплект_отклоняется_до_запуска(self):
        for имя in self.пути:
            with self.subTest(имя=имя):
                файл = self.разработчик / имя; файл.unlink()
                with self.assertRaises(ValueError): среда.построитьКоманду(self.разработчик, self.пакет, self.кэш, None)
                файл.write_bytes(b'fixture')

    def test_плагин_из_другого_комплекта_отклоняется(self):
        чужой = self.корень / 'Чужой'; чужой.write_bytes(b'fixture')
        файл = self.разработчик / self.пути[1]; файл.unlink(); файл.symlink_to(чужой)
        with self.assertRaises(ValueError): среда.построитьКоманду(self.разработчик, self.пакет, self.кэш, None)

    def test_относительный_корень_разработчика_отклоняется(self):
        with self.assertRaises(ValueError): среда.построитьКоманду(Path('относительный'), self.пакет, self.кэш, None)

    def test_кли_различает_сигнал_и_обычный_код_143(self):
        команды = self.корень / 'Команды'; команды.mkdir()
        выбор = команды / 'xcode-select'
        выбор.write_text(f'#!{sys.executable}\nprint({str(self.разработчик)!r})\n'); выбор.chmod(0o700)
        окружение = os.environ.copy(); окружение['PATH'] = str(команды) + os.pathsep + окружение['PATH']
        swift = self.разработчик / 'usr/bin/swift'
        for причина, исходныйКод, ожидаемыйКод in [('сигнал', -15, 143), ('выход', 143, 143), ('выход', 7, 7), ('выход', 0, 0)]:
            with self.subTest(причина=причина, код=исходныйКод):
                тело = 'import os, signal; os.kill(os.getpid(), signal.SIGTERM)' if причина == 'сигнал' else f'raise SystemExit({исходныйКод})'
                swift.write_text(f'#!{sys.executable}\n{тело}\n'); swift.chmod(0o700)
                результат = subprocess.run([sys.executable, '-B', str(путь.resolve()), '--пакет', str(self.пакет), '--кэш', str(self.кэш)],
                                           capture_output=True, text=True, timeout=10, env=окружение)
                self.assertEqual(результат.returncode, ожидаемыйКод)
                исход = json.loads(результат.stderr.splitlines()[-1])
                self.assertEqual(исход['схема'], 'fum.исход-проверки-пакета.1')
                self.assertEqual(исход['завершение'], причина)
                self.assertEqual(исход['кодПроцесса'], исходныйКод)
                self.assertEqual(исход['кодИсполнителя'], ожидаемыйКод)
                if причина == 'сигнал': self.assertEqual(исход['сигнал'], 15)
                else: self.assertNotIn('сигнал', исход)


if __name__ == '__main__':
    unittest.main()
