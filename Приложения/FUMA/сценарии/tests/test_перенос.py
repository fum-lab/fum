import importlib.util
import pathlib
import subprocess
import tempfile
import unittest

путь = pathlib.Path(__file__).resolve().parents[1] / 'перенести-исходники.py'
спецификация = importlib.util.spec_from_file_location('перенос', путь)
перенос = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(перенос)


class ПроверкиПереноса(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = pathlib.Path(self.временный.name)
        self.источник = self.корень / 'источник'
        self.цель = self.корень / 'цель'
        self.источник.mkdir()
        self.цель.mkdir()
        self.git('init', '-q')
        self.git('config', 'user.name', 'Фикстура')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.источник / 'Пакет').mkdir()
        (self.источник / 'Пакет/байты').write_bytes(bytes(range(256)))
        (self.источник / 'Пакет/команда').write_bytes(b'#!/bin/sh\nexit 0\n')
        (self.источник / 'Пакет/команда').chmod(0o755)
        self.git('add', '.')
        self.git('commit', '-qm', 'Фикстура')
        self.коммит = self.git('rev-parse', 'HEAD').decode().strip()
        (self.источник / 'Пакет/байты').write_bytes('НЕ ЧИТАТЬ РАБОЧЕЕ ДЕРЕВО'.encode())
        (self.источник / 'приватный').write_bytes('НЕ ИМПОРТИРОВАТЬ'.encode())

    def git(self, *аргументы):
        return subprocess.check_output(['git', '-C', str(self.источник), *аргументы])

    def план(self):
        return перенос.построить_план(self.источник, [(self.коммит, 'Пакет')], 'Приложения/FUMA')

    def test_точные_объекты_режимы_и_повтор(self):
        план = self.план()
        перенос.применить(self.источник, self.цель, план)
        self.assertEqual((self.цель/'Приложения/FUMA/Пакет/байты').read_bytes(), bytes(range(256)))
        self.assertEqual((self.цель/'Приложения/FUMA/Пакет/команда').stat().st_mode & 0o777, 0o755)
        self.assertFalse((self.цель/'приватный').exists())
        self.assertEqual(план, self.план())
        with self.assertRaises(ValueError):
            перенос.применить(self.источник, self.цель, план)

    def test_конфликт_до_любой_записи(self):
        план = self.план()
        занято = self.цель / план['файлы'][-1]['назначение']
        занято.parent.mkdir(parents=True)
        занято.write_bytes('сохранить'.encode())
        with self.assertRaises(ValueError):
            перенос.применить(self.источник, self.цель, план)
        self.assertEqual(занято.read_bytes(), 'сохранить'.encode())
        self.assertFalse((self.цель/план['файлы'][0]['назначение']).exists())

    def test_подмена_хэша_и_выход_за_корень(self):
        for ключ, значение in [('sha256','0'*64), ('назначение','../побег')]:
            with self.subTest(ключ=ключ):
                план = self.план()
                план['файлы'][0][ключ] = значение
                with self.assertRaises(ValueError):
                    перенос.применить(self.источник, self.цель, план)
                self.assertEqual(list(self.цель.iterdir()), [])

    def test_символическая_ссылка_в_цели(self):
        (self.цель/'Приложения').symlink_to(self.источник, target_is_directory=True)
        with self.assertRaises(ValueError):
            перенос.применить(self.источник, self.цель, self.план())
        self.assertFalse((self.источник/'FUMA').exists())

    def test_ссылка_в_исходнике_и_плавающая_ревизия(self):
        with self.assertRaises(ValueError):
            перенос.построить_план(self.источник, [('HEAD','Пакет')], 'Приложения/FUMA')
        (self.источник/'Пакет/ссылка').symlink_to('../приватный')
        self.git('add', 'Пакет/ссылка')
        self.git('commit', '-qm', 'Ссылка')
        with self.assertRaises(ValueError):
            перенос.построить_план(self.источник, [(self.git('rev-parse','HEAD').decode().strip(),'Пакет')], 'Приложения/FUMA')

    def test_подмена_пути_и_верхнего_происхождения(self):
        for вид in ('путь', 'коммит', 'дерево'):
            план = self.план()
            if вид == 'путь':
                план['файлы'][0]['источник'] = 'Пакет/*'
            elif вид == 'коммит':
                план['источники'][0]['коммит'] = '0' * 40
            else:
                дерево = план['источники'][0]['дерево']
                план['источники'][0]['коммит'] = дерево
                for запись in план['файлы']:
                    запись['коммит'] = дерево
            with self.subTest(вид=вид), self.assertRaises(ValueError):
                перенос.применить(self.источник, self.цель, план)
            self.assertEqual(list(self.цель.iterdir()), [])

    def test_объединение_не_дублирует_равные_пути(self):
        план = перенос.построить_план(self.источник, [(self.коммит,'Пакет'),(self.коммит,'Пакет')], 'Приложения/FUMA')
        self.assertEqual(len(план['файлы']), 2)


if __name__ == '__main__':
    unittest.main()
