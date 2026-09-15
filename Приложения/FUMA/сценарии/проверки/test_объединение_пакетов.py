"""Открытые независимые пакеты Геометрия, Палитра и Рисунок."""
import hashlib
import importlib.util
import json
import os
from unittest import mock
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

СЦЕНАРИЙ = Path(__file__).resolve().parents[1] / 'объединить-пакеты.py'


def загрузить():
    описание = importlib.util.spec_from_file_location('объединение', СЦЕНАРИЙ)
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = модуль
    описание.loader.exec_module(модуль)
    return модуль


class ПакетыTests(unittest.TestCase):
    def setUp(self):
        self.м = загрузить()
        self.временный = tempfile.TemporaryDirectory(prefix='пакеты с пробелами ')
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.git('init', '-q')
        self.git('config', 'user.name', 'Фикстура')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.записать('Геометрия/Package.swift', self.манифест('Геометрия', '.library(name: "Геометрия", targets: ["Геометрия"])', '.target(name: "Геометрия"), .testTarget(name: "ГеометрияTests", dependencies: ["Геометрия"])'))
        self.записать('Геометрия/Sources/Геометрия/Число.swift', 'public let число = 7\n')
        self.записать('Геометрия/Tests/ГеометрияTests/ЧислоTests.swift', 'import XCTest\nimport Геометрия\nfinal class ЧислоTests: XCTestCase { func test_значение() { XCTAssertEqual(число, 7) } }\n')
        self.записать('Палитра/Package.swift', self.манифест('Палитра', '.library(name: "Палитра", targets: ["Палитра"])', '.target(name: "Палитра", resources: [.copy("цвет.txt"), .process("форма.txt")])'))
        self.записать('Палитра/Sources/Палитра/Цвет.swift', 'import Foundation\npublic let форма = try! String(contentsOf: Bundle.module.url(forResource: "форма", withExtension: "txt")!, encoding: .utf8)\npublic let цвет = try! String(contentsOf: Bundle.module.url(forResource: "цвет", withExtension: "txt")!, encoding: .utf8)\n')
        self.записать('Палитра/Sources/Палитра/цвет.txt', 'синий')
        self.записать('Палитра/Sources/Палитра/форма.txt', 'круг')
        self.записать('Рисунок/Package.swift', self.манифест('Рисунок', '.executable(name: "рисунок", targets: ["Рисунок"])', '.executableTarget(name: "Рисунок", dependencies: [.product(name: "Геометрия", package: "Геометрия"), .product(name: "Палитра", package: "Палитра", condition: .when(platforms: [.macOS]))])', '.package(path: "../Геометрия"), .package(path: "../Палитра")'))
        self.записать('Рисунок/Sources/Рисунок/main.swift', 'import Геометрия\nimport Палитра\nprint("\\(число):\\(цвет):\\(форма)")\n')
        self.записать('README.md', '[цвет](Палитра/Sources/Палитра/цвет.txt)\n')
        self.фиксация()

    def git(self, *аргументы):
        return subprocess.check_output(['git', *аргументы], cwd=self.корень).decode().strip()

    def записать(self, имя, текст):
        путь = self.корень / имя
        путь.parent.mkdir(parents=True, exist_ok=True)
        путь.write_text(текст)

    def манифест(self, имя, продукты, цели, зависимости=''):
        return f'// swift-tools-version: 6.0\nimport PackageDescription\nlet package = Package(name: "{имя}", platforms: [.macOS(.v14)], products: [{продукты}], dependencies: [{зависимости}], targets: [{цели}], swiftLanguageModes: [.v6])\n'

    def фиксация(self):
        self.git('add', '--all')
        self.git('commit', '-qm', 'фикстура')
        self.вход = {'схема': 'fum.объединение-пакетов.1', 'HEAD': self.git('rev-parse', 'HEAD'), 'назначение': 'Общее', 'имя': 'Рисование', 'пакеты': [
            {'корень': имя, 'sha256': hashlib.sha256((self.корень / имя / 'Package.swift').read_bytes()).hexdigest()} for имя in ['Геометрия', 'Палитра', 'Рисунок']]}

    def план(self):
        return self.м.планировать(self.корень, self.вход)

    def test_план_применение_повтор_байты_ссылки(self):
        план = self.план()
        self.assertEqual(план, self.план())
        self.assertIn('.target(name: "Палитра", condition: .when(platforms: [.macOS]))', план['манифест'])
        self.assertEqual(9, len(план['пакет']['перемещения']))
        self.м.подготовить_каталоги(self.корень, план, план['sha256'])
        перенос = self.м.план_переноса(self.корень, план, план['sha256'])
        self.м.перенести(self.корень, план, план['sha256'], перенос['sha256'])
        self.assertFalse((self.корень / 'Общее/Package.swift').exists())
        self.м.завершить(self.корень, план, план['sha256'])
        self.м.завершить(self.корень, план, план['sha256'])
        self.assertEqual('синий', (self.корень / 'Общее/Sources/Палитра/цвет.txt').read_text())
        self.assertIn('Общее/Sources/Палитра/цвет.txt', (self.корень / 'README.md').read_text())
        self.assertFalse((self.корень / 'Палитра/Package.swift').exists())

    def test_коллизии_до_записи(self):
        for прежнее, новое in [('name: "Палитра", targets:', 'name: "Геометрия", targets:'), ('name: "Палитра", resources:', 'name: "Геометрия", resources:')]:
            with self.subTest(новое=новое):
                путь = self.корень / 'Палитра/Package.swift'; исходное = путь.read_text()
                путь.write_text(исходное.replace(прежнее, новое)); self.фиксация()
                состояние = self.git('status', '--porcelain')
                with self.assertRaises(ValueError): self.план()
                self.assertEqual(состояние, self.git('status', '--porcelain'))
                путь.write_text(исходное); self.фиксация()

    def test_неизвестный_код_не_исполняется(self):
        путь = self.корень / 'Палитра/Package.swift'
        путь.write_text(путь.read_text() + '\nprint("не выполнять")\n'); self.фиксация()
        with self.assertRaises(ValueError): self.план()

    def test_изменение_после_плана(self):
        план = self.план()
        self.записать('Геометрия/Sources/Геометрия/Число.swift', 'public let число = 8\n')
        with self.assertRaises(ValueError): self.м.подготовить_каталоги(self.корень, план, план['sha256'])
        self.assertFalse((self.корень / 'Общее').exists())

    def test_ресурс_коллизия_и_выход(self):
        путь = self.корень / 'Палитра/Package.swift'; исходное = путь.read_text()
        for ресурс in ['.copy("цвет.txt"), .process("цвет.txt")', '.copy("../цвет.txt")']:
            путь.write_text(исходное.replace('.copy("цвет.txt")', ресурс)); self.фиксация()
            with self.assertRaises(ValueError): self.план()

    def test_зависимость_неоднозначна(self):
        путь = self.корень / 'Рисунок/Package.swift'
        путь.write_text(путь.read_text().replace('package: "Геометрия"', 'package: "нет"')); self.фиксация()
        with self.assertRaises(ValueError): self.план()

    def test_подмена_между_стадиями(self):
        план = self.план(); self.м.подготовить_каталоги(self.корень, план, план['sha256'])
        перенос = self.м.план_переноса(self.корень, план, план['sha256'])
        self.м.перенести(self.корень, план, план['sha256'], перенос['sha256'])
        self.записать('Общее/Sources/Палитра/цвет.txt', 'другой')
        with self.assertRaises(ValueError): self.м.завершить(self.корень, план, план['sha256'])
        self.assertFalse((self.корень / 'Общее/Package.swift').exists())


    def test_неподдержанные_настройки_платформы_цикл(self):
        путь = self.корень / 'Геометрия/Package.swift'; исходное = путь.read_text()
        варианты = [исходное.replace('.v14', '.v13'),
                    исходное.replace('.target(name: "Геометрия")', '.target(name: "Геометрия", swiftSettings: [.define("ФЛАГ")])'),
                    исходное.replace('.target(name: "Геометрия")', '.target(name: "Геометрия", dependencies: ["ГеометрияTests"])')]
        for текст in варианты:
            путь.write_text(текст); self.фиксация()
            with self.assertRaises(ValueError): self.план()

    def test_символическая_ссылка_не_переносится(self):
        путь = self.корень / 'Палитра/Sources/Палитра/цвет.txt'
        путь.unlink(); путь.symlink_to('форма.txt'); self.фиксация()
        with self.assertRaises(ValueError): self.план()

    def test_индекс_изменён_после_просмотра(self):
        план = self.план()
        self.записать('новое.txt', 'новое'); self.git('add', 'новое.txt')
        with self.assertRaises(ValueError): self.м.подготовить_каталоги(self.корень, план, план['sha256'])

    def test_CLI_чужой_cwd_и_ошибочный_SHA(self):
        вход = self.корень / 'input.json'; вход.write_text(json.dumps(self.вход, ensure_ascii=False))
        запуск = subprocess.run([sys.executable, '-B', str(СЦЕНАРИЙ), 'план', '--корень', str(self.корень), '--вход', str(вход)], cwd='/', capture_output=True, text=True)
        self.assertEqual(0, запуск.returncode, запуск.stderr)
        план = json.loads(запуск.stdout); self.assertEqual(план, self.план())
        with self.assertRaises(ValueError): self.м.подготовить_каталоги(self.корень, план, '0' * 64)



    def применить_перенос(self, план):
        self.м.подготовить_каталоги(self.корень, план, план['sha256'])
        перенос = self.м.план_переноса(self.корень, план, план['sha256'])
        self.м.перенести(self.корень, план, план['sha256'], перенос['sha256'])

    def test_повтор_в_существующий_пакет(self):
        self.вход['назначение'] = 'Геометрия'
        план = self.план(); self.применить_перенос(план)
        self.м.завершить(self.корень, план, план['sha256'])
        self.м.завершить(self.корень, план, план['sha256'])

    def test_новый_исходник_между_стадиями(self):
        план = self.план(); self.применить_перенос(план)
        self.записать('Общее/Sources/Геометрия/Новый.swift', 'public let новый = 9\n')
        with self.assertRaises(ValueError): self.м.завершить(self.корень, план, план['sha256'])
        self.assertFalse((self.корень / 'Общее/Package.swift').exists())

    def test_чужая_Git_среда_не_перенаправляет_работу(self):
        чужой = self.корень / 'чужой-индекс'
        with mock.patch.dict(os.environ, {'GIT_INDEX_FILE': str(чужой), 'GIT_WORK_TREE': '/' }):
            план = self.план(); self.применить_перенос(план)
            self.м.завершить(self.корень, план, план['sha256'])
        self.assertFalse(чужой.exists())
        self.assertTrue((self.корень / 'Общее/Package.swift').exists())



    def test_версионный_manifest_не_игнорируется(self):
        self.записать('Геометрия/Package@swift-6.0.swift', 'иная декларация')
        self.фиксация()
        with self.assertRaises(ValueError): self.план()

    def test_транзитивная_внешняя_зависимость_отклоняется(self):
        self.записать('Посредник/Package.swift', self.манифест('Посредник', '.library(name: "Посредник", targets: ["Посредник"])', '.target(name: "Посредник")', '.package(path: "../Геометрия")'))
        self.записать('Посредник/Sources/Посредник/Код.swift', 'public let код = 1\n')
        путь = self.корень / 'Рисунок/Package.swift'
        путь.write_text(путь.read_text().replace('.package(path: "../Геометрия")', '.package(path: "../Посредник"), .package(path: "../Геометрия")'))
        self.фиксация()
        with self.assertRaises(ValueError): self.план()


    def test_версионный_manifest_в_назначении_отказ_до_переноса(self):
        self.записать('Общее/Package@swift-6.0.swift', 'существующий вариант')
        self.фиксация()
        with self.assertRaises(ValueError): self.план()
        self.assertTrue((self.корень / 'Геометрия/Package.swift').is_file())

if __name__ == '__main__': unittest.main()
