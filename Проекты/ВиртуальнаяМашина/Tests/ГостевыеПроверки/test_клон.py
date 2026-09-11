"""Настоящие локальные Git-фикстуры проверяют повтор без сети и сброса данных."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ресурс = Path(__file__).resolve().parents[2] / 'Sources/ЯдроМашины/Ресурсы/готовность.py'
спецификация = importlib.util.spec_from_file_location('готовность_для_клона', ресурс)
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)


class ПроверкиКлона(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory(); сам.addCleanup(сам.временный.cleanup)
        сам.основа = Path(сам.временный.name).resolve()
        сам.источник = сам.основа / 'источник'; сам.источник.mkdir()
        сам.среда = {'PATH': os.environ['PATH'], 'HOME': str(сам.основа),
                     'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null'}
        сам.git(сам.источник, 'init', '-q')
        (сам.источник / 'данные.txt').write_text('Сохраняем исходные данные\n')
        сам.git(сам.источник, 'add', '.')
        сам.git(сам.источник, '-c', 'user.name=Фикстура', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'Открытая фикстура')
        сам.коммит = сам.git(сам.источник, 'rev-parse', 'HEAD').strip()
        сам.дерево = сам.git(сам.источник, 'rev-parse', 'HEAD^{tree}').strip()
        сам.корень = сам.основа / 'гость'
        сам.владелец = {'схема': 'фикстура.1', 'машина': 'открытая-фикстура'}
        сам.получений = 0

    def git(сам, путь, *аргументы):
        return subprocess.check_output(['git', *аргументы], cwd=путь, env=сам.среда, stderr=subprocess.PIPE, text=True)

    def получить(сам, путь, коммит, среда):
        сам.получений += 1
        сам.git(путь, 'fetch', '--no-tags', str(сам.источник), коммит)

    def подготовить(сам):
        with модуль.область_гостя(сам.корень, сам.владелец) as каталог:
            with patch.object(модуль, 'получить_объекты', side_effect=сам.получить):
                return модуль.подготовить_клон(сам.корень, каталог, сам.владелец, сам.коммит, сам.дерево)

    def test_повтор_проверяет_точный_клон_без_нового_fetch(сам):
        путь = сам.подготовить()
        сам.assertEqual(сам.git(путь, 'rev-parse', 'HEAD').strip(), сам.коммит)
        сам.assertEqual(сам.подготовить(), путь)
        сам.assertEqual(сам.получений, 1)

    def test_изменения_и_скрытый_флаг_индекса_не_стираются(сам):
        путь = сам.подготовить(); файл = путь / 'данные.txt'
        сам.git(путь, 'update-index', '--assume-unchanged', 'данные.txt')
        файл.write_text('Ручная правка')
        with сам.assertRaises(ValueError): сам.подготовить()
        сам.assertEqual(файл.read_text(), 'Ручная правка'); сам.assertEqual(сам.получений, 1)

    def test_прерванная_попытка_сохраняется_а_повтор_создаёт_новую(сам):
        def прервать(путь, коммит, среда):
            (путь / 'остаток').write_text('Не удалять')
            raise RuntimeError('Прерван fetch')
        with модуль.область_гостя(сам.корень, сам.владелец) as каталог:
            with patch.object(модуль, 'получить_объекты', side_effect=прервать):
                with сам.assertRaises(RuntimeError):
                    модуль.подготовить_клон(сам.корень, каталог, сам.владелец, сам.коммит, сам.дерево)
        остатки = list(сам.корень.glob('попытка-*/остаток')); сам.assertEqual(len(остатки), 1)
        путь = сам.подготовить()
        сам.assertEqual(остатки[0].read_text(), 'Не удалять')
        сам.assertNotEqual(остатки[0].parent, путь)

    def test_незавершённое_свидетельство_не_публикуется(сам):
        with модуль.область_гостя(сам.корень, сам.владелец) as каталог:
            def прервать(каталог, имя, данные):
                файл = os.open(имя, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600, dir_fd=каталог)
                try: os.write(файл, b'{')
                finally: os.close(файл)
                raise RuntimeError('Прерывание записи метаданных')
            with patch.object(модуль, 'записать_новый_файл', side_effect=прервать):
                with сам.assertRaises(RuntimeError):
                    модуль.установить_свидетельство(каталог, 'готовый-клон.json', {'схема': 'фикстура'})
            сам.assertFalse((сам.корень / 'готовый-клон.json').exists())
            модуль.установить_свидетельство(каталог, 'готовый-клон.json', {'схема': 'фикстура'})
            прежние = (сам.корень / 'готовый-клон.json').read_bytes()
            with сам.assertRaises(FileExistsError):
                модуль.установить_свидетельство(каталог, 'готовый-клон.json', {'схема': 'подмена'})
            сам.assertEqual((сам.корень / 'готовый-клон.json').read_bytes(), прежние)

    def test_замена_объекта_не_подменяет_опубликованное_дерево(сам):
        путь = сам.подготовить()
        файл = путь / 'данные.txt'; файл.write_text('Локальная подмена дерева\n')
        сам.git(путь, 'add', 'данные.txt')
        другое = сам.git(путь, 'write-tree').strip()
        сам.git(путь, 'replace', сам.дерево, другое)
        with сам.assertRaises(ValueError): сам.подготовить()
        сам.assertEqual(файл.read_text(), 'Локальная подмена дерева\n')

    def test_исполняемый_файл_должен_исполняться_владельцем(сам):
        исходник = сам.источник / 'выполнить'; исходник.write_text('#!/bin/sh\nexit 0\n'); исходник.chmod(0o755)
        сам.git(сам.источник, 'add', 'выполнить')
        сам.git(сам.источник, '-c', 'user.name=Фикстура', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'Исполняемая фикстура')
        сам.коммит = сам.git(сам.источник, 'rev-parse', 'HEAD').strip()
        сам.дерево = сам.git(сам.источник, 'rev-parse', 'HEAD^{tree}').strip()
        путь = сам.подготовить(); файл = путь / 'выполнить'; файл.chmod(0o645)
        with сам.assertRaises(ValueError): сам.подготовить()
        сам.assertEqual(файл.stat().st_mode & 0o777, 0o645)


if __name__ == '__main__': unittest.main()
