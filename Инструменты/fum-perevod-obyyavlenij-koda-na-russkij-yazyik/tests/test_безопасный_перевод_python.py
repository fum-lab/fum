"""Регрессии принадлежности Python-имён; исходные фрагменты — открытые фикстуры."""
import argparse
import ast
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import tempfile
import time
import unittest


путь = Path(__file__).resolve().parents[1] / "scripts/перевести-объявления-кода.py"
начало_загрузки = time.perf_counter_ns()
спецификация = importlib.util.spec_from_file_location("переводчик_проверяемый", путь)
переводчик = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = переводчик
спецификация.loader.exec_module(переводчик)
загрузка_модуля_нс = time.perf_counter_ns() - начало_загрузки


class ПроверкаБезопасногоПереводаПитона(unittest.TestCase):
    def перевод(сам, текст, карта):
        return переводчик.замены_питона(текст, карта)[0]

    def test_внешние_ключевые_аргументы_и_атрибуты(сам):
        текст = '''import os, subprocess
from pathlib import Path
def work(env, name, path, errors):
    return subprocess.run([name], env=env), Path(path).name, os.path, b"x".decode(errors=errors)
'''
        итог = сам.перевод(текст, {"env": "среда", "name": "имя", "path": "путь", "errors": "ошибки"})
        сам.assertIn('subprocess.run([имя], env=среда)', итог)
        сам.assertIn('Path(путь).name, os.path', итог)
        сам.assertIn('decode(errors=ошибки)', итог)

    def test_свой_параметр_и_чужой_одноимённый_аргумент(сам):
        текст = 'def own(value):\n    return value\nx = own(value=1)\ny = external(value=2)\n'
        итог = сам.перевод(текст, {"value": "значение", "own": "своя"})
        сам.assertIn('своя(значение=1)', итог)
        сам.assertIn('external(value=2)', итог)
        сам.assertEqual(итог, 'def своя(значение):\n    return значение\nx = своя(значение=1)\ny = external(value=2)\n')

    def test_импорт_и_затеняющий_параметр(сам):
        текст = 'from math import sqrt\ndef calculate(sqrt):\n    return sqrt\nx = sqrt(4)\n'
        итог = сам.перевод(текст, {"sqrt": "корень"})
        сам.assertIn('from math import sqrt', итог)
        сам.assertIn('calculate(корень)', итог)
        сам.assertIn('x = sqrt(4)', итог)

    def test_псевдоним_импорта_не_меняет_имя_модуля(сам):
        текст = 'import os.path as path\nx = path.basename("a")\n'
        итог = сам.перевод(текст, {"path": "путь"})
        сам.assertEqual(итог, 'import os.path as путь\nx = путь.basename("a")\n')

    def test_форматная_строка_меняет_выражение_сохраняя_текст(сам):
        текст = 'value = 2\nresult = f"value: {value + 1}"\n'
        итог = сам.перевод(текст, {"value": "значение"})
        сам.assertEqual(итог, 'значение = 2\nresult = f"value: {значение + 1}"\n')

    def test_аргпарс_сохраняет_контракт_флага_и_свойства(сам):
        текст = 'def work(intent, a, p):\n    p.add_argument("--intent")\n    return intent, a.intent\n'
        итог = сам.перевод(текст, {"intent": "намерение", "a": "аргументы"})
        сам.assertIn('"--intent"', итог)
        сам.assertIn('return намерение, аргументы.intent', итог)

    def test_рефлексия_не_принимается_как_обычная_строка(сам):
        for текст in (
            'def git(): pass\npatch.object(module, "git", failing)\n',
            'def git(): pass\ngetattr(module, "git")\n',
            'def git(): pass\n__all__ = ["git"]\n',
        ):
            with сам.subTest(текст=текст), сам.assertRaises(ValueError):
                сам.перевод(текст, {"git": "гит"})

    def test_неизвестный_владелец_своего_поля_закрывает_замену(сам):
        текст = 'class Box:\n    def get(self):\n        self.value = 1\n        return self.value\nx = unknown.value\n'
        with сам.assertRaises(ValueError):
            сам.перевод(текст, {"value": "значение"})

    def test_своё_поле_и_внешнее_поле_различаются(сам):
        текст = 'class Box:\n    def get(self):\n        self.value = 1\n        return self.value\n'
        итог = сам.перевод(текст, {"value": "значение", "self": "сам"})
        сам.assertIn('сам.значение = 1', итог)
        сам.assertIn('return сам.значение', итог)

    def test_лямбда_исключение_и_область_генератора(сам):
        текст = 'import math as error\nf = lambda value: value + 1\ntry:\n    pass\nexcept Exception as error:\n    print(error)\nx = [value for value in range(3)]\n'
        with сам.assertRaises(ValueError):
            сам.перевод(текст, {"error": "ошибка"})
        with сам.assertRaises(ValueError):
            сам.перевод('f = lambda value: value + 1\nescape(f)\n', {"value": "значение"})
        итог = сам.перевод('f = (lambda value: value + 1)(2)\nx = [value for value in range(3)]\n', {"value": "значение"})
        сам.assertIn('lambda значение: значение + 1', итог)
        сам.assertIn('[значение for значение in range(3)]', итог)

    def test_область_генератора_не_захватывает_внешнее_имя(сам):
        текст = 'from math import sqrt\nx = [sqrt for sqrt in [1, 2]]\ny = sqrt(4)\n'
        итог = сам.перевод(текст, {"sqrt": "корень"})
        сам.assertIn('[корень for корень in [1, 2]]', итог)
        сам.assertIn('y = sqrt(4)', итог)

    def test_глобальные_и_нелокальные_связи(сам):
        текст = 'value = 1\ndef outer():\n    value = 2\n    def inner():\n        nonlocal value\n        value += 1\n    return inner\ndef update():\n    global value\n    value += 1\n'
        итог = сам.перевод(текст, {"value": "значение"})
        сам.assertIn('nonlocal значение', итог)
        сам.assertIn('global значение', итог)
        сам.assertNotIn('value', итог)

    def test_инвентарь_параметров_лямбды_исключений_псевдонимов(сам):
        with tempfile.TemporaryDirectory() as каталог:
            файл = Path(каталог) / 'пример.py'
            файл.write_text('import os as operating\nf = lambda value: value\ntry:\n    pass\nexcept Exception as error:\n    pass\n')
            имена = {з.имя for з in переводчик.объявления_питона(файл, 'пример.py')}
        сам.assertTrue({'operating', 'value', 'error'} <= имена)
        сам.assertNotIn('os', имена)
        сам.assertNotIn('Exception', имена)

    def test_байтовые_столбцы_после_кириллицы(сам):
        сам.assertEqual(сам.перевод('текст = "ё"; value = 1; итог = value\n', {'value': 'значение'}),
                        'текст = "ё"; значение = 1; итог = значение\n')

    def test_отладочная_форматная_строка_закрыта(сам):
        with сам.assertRaises(ValueError):
            сам.перевод('name = 1\ns = f"{name=}"\n', {'name': 'имя'})

    def test_строковая_аннотация_своего_типа_закрыта(сам):
        with сам.assertRaises(ValueError):
            сам.перевод('class Box: pass\ndef take(value: "Box") -> "Box":\n    return value\n', {'Box': 'Коробка'})

    def test_декоратор_и_значение_по_умолчанию_используют_внешнюю_область(сам):
        текст = 'from math import sqrt\n@sqrt\ndef f(sqrt=sqrt(4)):\n    return sqrt\n'
        итог = сам.перевод(текст, {'sqrt': 'корень'})
        сам.assertIn('@sqrt\ndef f(корень=sqrt(4)):', итог)

    def test_конструктор_и_параметр_инициализатора(сам):
        текст = 'class Box:\n    def __init__(self, value):\n        self.данные = value\nx = Box(value=2)\n'
        итог = сам.перевод(текст, {'value': 'значение'})
        сам.assertIn('Box(значение=2)', итог)
        окружение = {}
        exec(итог, окружение)
        сам.assertEqual(окружение['x'].данные, 2)

    def test_одноимённое_своё_и_внешнее_поле_закрыто_без_доказательства(сам):
        текст = 'from pathlib import Path\nclass Box:\n    def get(self):\n        self.name = "a"\n        return self.name, Path("b").name, self.tmp.name\n'
        with сам.assertRaises(ValueError):
            сам.перевод(текст, {'name': 'имя'})

    def test_внешние_методы_посетителя_требуют_контекста(сам):
        текст = 'import ast\ndef visit(): pass\nclass Other:\n    def visit(self): pass\nclass Visitor(ast.NodeVisitor):\n    def visit(self, node): pass\n    def visit_Lambda(self, node): pass\n    def visit_fake(self, node): pass\n    def visit_Assign(self, node): pass\n'
        with tempfile.TemporaryDirectory() as каталог:
            файл = Path(каталог) / 'пример.py'
            файл.write_text(текст)
            найденные = переводчик.объявления_питона(файл, 'пример.py')
        сам.assertEqual([з.строка for з in найденные if з.имя == 'visit'], [2, 4])
        сам.assertFalse(any(з.имя == 'visit_Lambda' for з in найденные))
        сам.assertFalse(any(з.имя == 'visit_Assign' for з in найденные))
        сам.assertTrue(any(з.имя == 'visit_fake' for з in найденные))

    def test_неизвестный_получатель_метода_с_переведённым_параметром(сам):
        текст = 'class Box:\n    def get(self, value):\n        return value\nx = box.get(value=2)\n'
        with сам.assertRaises(ValueError):
            сам.перевод(текст, {'value': 'значение'})

    def test_выбор_только_новой_лексической_области(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'def old(self):\n    return self\ndef new(self):\n    return self\n'
        итог, план, _ = подготовить_замены(текст, {'self': 'сам'}, {(3, 0, 'self')})
        сам.assertEqual(итог, 'def old(self):\n    return self\ndef new(сам):\n    return сам\n')
        сам.assertTrue(all(п['область'] == [3, 0] for п in план))

    def test_опасные_изменения_владельца_закрыты(сам):
        случаи = [
            ('class Box:\n    def get(self):\n        self = external\n        self.value = 1\n', {'value': 'значение'}),
            ('class Box:\n    value = 1\nmatch obj:\n    case Box(value=x): pass\n', {'value': 'значение'}),
            ('value = 1\nfrom external import *\nprint(value)\n', {'value': 'значение'}),
            ('def own(value): return value\nalias = own\nx = alias(**{"value": 1})\n', {'value': 'значение'}),
        ]
        for текст, карта in случаи:
            with сам.subTest(текст=текст), сам.assertRaises(ValueError):
                сам.перевод(текст, карта)

    def test_порядок_тела_класса_не_смешивается_с_лексической_областью(сам):
        with сам.assertRaises(ValueError):
            сам.перевод('from math import pi\nclass Box:\n    first = pi\n    pi = 3\n', {'pi': 'число'})

    def test_вложенный_класс_не_видит_привязок_внешнего_класса(сам):
        текст = 'from math import pi\nclass Outer:\n    pi = 3\n    class Inner:\n        answer = pi\n'
        итог = сам.перевод(текст, {'pi': 'число'})
        сам.assertIn('    число = 3', итог)
        сам.assertIn('answer = pi', итог)

    def test_неизвестная_координата_области_закрыта(сам):
        from безопасные_привязки_python import подготовить_замены
        with сам.assertRaises(ValueError):
            подготовить_замены('value = 1\n', {'value': 'значение'}, {(900, 0, 'value')})

    def инвентарь(сам, текст):
        with tempfile.TemporaryDirectory() as каталог:
            файл = Path(каталог) / 'пример.py'
            файл.write_text(текст, encoding='utf-8')
            return [(з.строка, з.столбец, з.вид, з.имя)
                    for з in переводчик.объявления_питона(файл, 'пример.py')]

    def test_внешний_метод_тестов_требует_доказанного_импорта(сам):
        for импорт, база in (
            ('import unittest', 'unittest.TestCase'),
            ('import unittest as проверки', 'проверки.TestCase'),
            ('from unittest import TestCase', 'TestCase'),
            ('from unittest import TestCase as Случай', 'Случай'),
        ):
            текст = импорт + '\nclass Тест(' + база + '):\n    def setUp(сам): pass\n'
            with сам.subTest(импорт=импорт):
                сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'], [])

    def test_внешний_метод_не_скрывает_параметры_тело_и_поле(сам):
        текст = ('import unittest\nclass Тест(unittest.TestCase):\n'
                 '    setUp = 1\n    def setUp(сам, value=None):\n'
                 '        local = value\n        def setUp(): pass\n')
        найденные = сам.инвентарь(текст)
        сам.assertEqual([з for з in найденные if з[3] == 'setUp'],
                        [(3, 5, 'привязка', 'setUp'), (6, 9, 'функция', 'setUp')])
        сам.assertIn((4, 23, 'параметр', 'value'), найденные)
        сам.assertIn((5, 9, 'привязка', 'local'), найденные)

    def test_одноимённые_собственные_объявления_не_становятся_внешними(сам):
        текст = ('def setUp(): pass\nclass Тест:\n    def setUp(сам): pass\n'
                 'class setUp: pass\nsetUp = 1\ndef другая(setUp): pass\n')
        сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'],
                        [(1, 1, 'функция', 'setUp'), (3, 5, 'функция', 'setUp'),
                         (4, 1, 'класс', 'setUp'), (5, 1, 'привязка', 'setUp'),
                         (6, 18, 'параметр', 'setUp')])
        текст = 'import unittest\nclass Тест(unittest.TestCase):\n    class setUp: pass\n'
        сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'],
                        [(3, 5, 'класс', 'setUp')])

    def test_неизвестный_импорт_затенение_и_база_закрывают_исключение(сам):
        случаи = (
            'import другая as unittest\nclass Тест(unittest.TestCase):\n    def setUp(сам): pass\n',
            'from .unittest import TestCase\nclass Тест(TestCase):\n    def setUp(сам): pass\n',
            'from unittest.case import TestCase\nclass Тест(TestCase):\n    def setUp(сам): pass\n',
            'class Тест(unittest.TestCase):\n    def setUp(сам): pass\nimport unittest\n',
            'import unittest\nunittest = Подмена\nclass Тест(unittest.TestCase):\n    def setUp(сам): pass\n',
            'from unittest import TestCase\nTestCase = Подмена\nclass Тест(TestCase):\n    def setUp(сам): pass\n',
            'import unittest\ndef фабрика(unittest):\n    class Тест(unittest.TestCase):\n        def setUp(сам): pass\n',
            'import unittest\nclass База(unittest.TestCase): pass\nclass Тест(База):\n    def setUp(сам): pass\n',
            'import unittest\nБаза = unittest.TestCase\nclass Тест(База):\n    def setUp(сам): pass\n',
            'import unittest\nclass Тест(unittest.TestCase()):\n    def setUp(сам): pass\n',
            'import unittest\nclass Тест(Другая, unittest.TestCase):\n    def setUp(сам): pass\n',
        )
        for текст in случаи:
            строка = next(н for н, с in enumerate(текст.splitlines(), 1) if 'def setUp(' in с)
            столбец = len(текст.splitlines()[строка - 1]) - len(текст.splitlines()[строка - 1].lstrip()) + 1
            with сам.subTest(текст=текст):
                сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'],
                                [(строка, столбец, 'функция', 'setUp')])

    def test_подмена_импортного_модуля_закрывает_исключение(сам):
        мутации = ('unittest.TestCase = Подмена', 'unittest.TestCase: object = Подмена',
                   'unittest.TestCase += Подмена', 'del unittest.TestCase',
                   'for unittest.TestCase in []: pass')
        случаи = ['import unittest\n' + м + '\nclass Тест(unittest.TestCase):\n    def setUp(сам): pass\n'
                  for м in мутации]
        случаи += [
            'import unittest as а\nimport unittest as б\nб.TestCase = Подмена\nclass Тест(а.TestCase):\n    def setUp(сам): pass\n',
            'import unittest\ndef фабрика():\n    class Тест(unittest.TestCase):\n        def setUp(сам): pass\ndef мутатор():\n    unittest.TestCase = Подмена\n',
            'import unittest\nif False:\n    unittest.TestCase = Подмена\nclass Тест(unittest.TestCase):\n    def setUp(сам): pass\n',
        ]
        for текст in случаи:
            строка = next(н for н, с in enumerate(текст.splitlines(), 1) if 'def setUp(' in с)
            столбец = len(текст.splitlines()[строка - 1]) - len(текст.splitlines()[строка - 1].lstrip()) + 1
            with сам.subTest(текст=текст):
                сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'],
                                [(строка, столбец, 'функция', 'setUp')])

    def test_аннотация_чужое_поле_и_затенённый_получатель_не_подменяют_базу(сам):
        for действие in ('unittest.TestCase: object', 'unittest.Other = Подмена',
                         'unittest.TestCase.поле = 1',
                         'def мутатор(unittest):\n    unittest.TestCase = Подмена'):
            текст = 'import unittest\n' + действие + '\nclass Тест(unittest.TestCase):\n    def setUp(сам): pass\n'
            with сам.subTest(действие=действие):
                сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'], [])

    def test_инвентарь_не_исполняет_исходник_и_видит_лексический_импорт(сам):
        текст = ('def фабрика():\n    import unittest as проверки\n'
                 '    raise RuntimeError("Исходник нельзя исполнять")\n'
                 '    class Тест(проверки.TestCase):\n        def setUp(сам): pass\n')
        сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'], [])

    def test_поздняя_классовая_привязка_не_скрывает_подмену_глобального_модуля(сам):
        for тело in ('    unittest.TestCase = Подмена\n    unittest = Свой\n',
                     '    if False:\n        unittest = Свой\n    unittest.TestCase = Подмена\n',
                     '    unittest: object\n    unittest.TestCase = Подмена\n',
                     '    unittest = unittest\n    unittest.TestCase = Подмена\n'):
            текст = ('import unittest\nclass Контейнер:\n' + тело
                     + 'class Тест(unittest.TestCase):\n    def setUp(сам): pass\n')
            строка = len(текст.splitlines())
            with сам.subTest(тело=тело):
                сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'],
                                [(строка, 5, 'функция', 'setUp')])

    def test_прямая_ранняя_собственная_классовая_привязка_не_есть_импорт(сам):
        текст = ('import unittest\nclass Своя: pass\nclass Контейнер:\n'
                 '    unittest = Своя\n    unittest.TestCase = Подмена\n'
                 'class Тест(unittest.TestCase):\n    def setUp(сам): pass\n')
        сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'], [])

    def test_поздняя_модульная_мутация_остаётся_консервативной_неизвестностью(сам):
        текст = ('import unittest\nclass Тест(unittest.TestCase):\n'
                 '    def setUp(сам): pass\nunittest.TestCase = Подмена\n')
        сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'],
                        [(3, 5, 'функция', 'setUp')])

    def test_вложенное_тело_класса_не_использует_пространство_внешнего_класса(сам):
        текст = ('import unittest\nclass Свой: pass\nclass Наружный:\n'
                 '    unittest = Свой\n    class Контейнер:\n'
                 '        unittest.TestCase = Подмена\n        unittest = Свой\n'
                 'class Тест(unittest.TestCase):\n    def setUp(сам): pass\n')
        сам.assertEqual([з for з in сам.инвентарь(текст) if з[3] == 'setUp'],
                        [(9, 5, 'функция', 'setUp')])


def байты_профиля(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True,
                       separators=(',', ':')) + '\n').encode()


def контур_профиля():
    корень = Path(__file__).resolve().parents[3]
    файлы = [Path(__file__).resolve(), путь,
             *(путь.with_name(имя) for имя in ('разбор_сценария.py',
                'аббревиатуры_контекста.py', 'безопасные_привязки_python.py'))]
    return {ф.relative_to(корень).as_posix(): hashlib.sha256(ф.read_bytes()).hexdigest()
            for ф in файлы}


def корпус_профиля(блоков, подмена):
    # Это данные: фикстура прежнего AST visitor и два разных владельца setUp.
    # Исходник нигде не исполняется. Oracle задан независимо от collector.
    тело = ('def visit(): pass\nclass Other:\n    def visit(self): pass\n'
            'class Visitor(ast.NodeVisitor):\n    def visit(self, node): pass\n'
            '    def visit_Lambda(self, node): pass\n    def visit_fake(self, node): pass\n'
            '    def visit_Assign(self, node): pass\nclass Trial(unittest.TestCase):\n'
            '    def setUp(self):\n        local = 1\nclass Own:\n    def setUp(self): pass\n')
    записи = [(3, 1, 'функция', 'visit'), (4, 1, 'класс', 'Other'),
              (5, 5, 'функция', 'visit'), (5, 15, 'параметр', 'self'),
              (6, 1, 'класс', 'Visitor'), (7, 15, 'параметр', 'self'),
              (7, 21, 'параметр', 'node'), (8, 22, 'параметр', 'self'),
              (8, 28, 'параметр', 'node'), (9, 5, 'функция', 'visit_fake'),
              (9, 20, 'параметр', 'self'), (9, 26, 'параметр', 'node'),
              (10, 22, 'параметр', 'self'), (10, 28, 'параметр', 'node'),
              (11, 1, 'класс', 'Trial'), (12, 15, 'параметр', 'self'),
              (13, 9, 'привязка', 'local'), (14, 1, 'класс', 'Own'),
              (15, 5, 'функция', 'setUp'), (15, 15, 'параметр', 'self')]
    префикс = 'import ast\nimport unittest\n'
    ожидаемые = []
    сдвиг = 0
    if подмена:
        префикс += 'unittest.TestCase = object\n'
        сдвиг = 1
        ожидаемые.append({'путь': 'пример.py', 'язык': 'python', 'строка': 3,
                         'столбец': 1, 'вид': 'атрибут', 'имя': 'TestCase'})
        записи.insert(15, (12, 5, 'функция', 'setUp'))
    for номер in range(блоков):
        for строка, столбец, вид, имя in записи:
            ожидаемые.append({'путь': 'пример.py', 'язык': 'python',
                              'строка': строка + сдвиг + 13 * номер,
                              'столбец': столбец, 'вид': вид, 'имя': имя})
    return префикс + тело * блоков, ожидаемые


def измерить_сборщик(блоков):
    if not 1 <= блоков <= 1000:
        raise ValueError('Число блоков вне конечной границы')
    исходный_контур = контур_профиля()
    сценарии = []
    for подмена in (False, True):
        текст, ожидаемые = корпус_профиля(блоков, подмена)
        вход = текст.encode()
        фазы = {}
        начало = time.perf_counter_ns()
        дерево = ast.parse(текст, filename='пример.py')
        фазы['разбор_нс'] = time.perf_counter_ns() - начало
        дерево_до = ast.dump(дерево, include_attributes=True).encode()
        начало = time.perf_counter_ns()
        сборщик = переводчик.СборщикОбъявленийПитона('пример.py', дерево)
        фазы['подготовка_сборщика_нс'] = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        сборщик.visit(дерево)
        фазы['обход_нс'] = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        наблюдаемые = [з.словарь() for з in сборщик.объявления]
        итог = байты_профиля(наблюдаемые)
        оракул = байты_профиля(ожидаемые)
        фазы['сериализация_нс'] = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        if наблюдаемые != ожидаемые:
            raise ValueError('Полный упорядоченный инвентарь не совпал с независимым oracle')
        if дерево_до != ast.dump(дерево, include_attributes=True).encode():
            raise ValueError('Сборщик изменил исходное AST')
        фазы['сверка_нс'] = time.perf_counter_ns() - начало
        сценарии.append({'подмена': подмена, 'блоков': блоков, 'объявлений': len(наблюдаемые),
            'байты_входа': len(вход), 'хэш_входа': hashlib.sha256(вход).hexdigest(),
            'хэш_синтаксического_дерева': hashlib.sha256(дерево_до).hexdigest(),
            'хэш_оракула': hashlib.sha256(оракул).hexdigest(),
            'хэш_результата': hashlib.sha256(итог).hexdigest(), 'фазы': фазы})
    if исходный_контур != контур_профиля():
        raise ValueError('Контур измерителя дрейфовал')
    return {'контур': исходный_контур, 'сценарии': сценарии,
            'загрузка_модуля_нс': загрузка_модуля_нс, 'версия_интерпретатора': platform.python_version(),
            'хэш_интерпретатора': hashlib.sha256(Path(sys.executable).resolve().read_bytes()).hexdigest()}


def профиль_свежих_процессов(блоков):
    контур_до = контур_профиля()
    повторы = []
    for номер in range(3):
        начало = time.perf_counter_ns()
        процесс = subprocess.run([str(Path(sys.executable).resolve()), '-I', '-S', '-B',
            str(Path(__file__).resolve()), '--воркер-профиля', '--блоков', str(блоков)],
            cwd=Path(__file__).resolve().parents[3], capture_output=True, timeout=30)
        внешнее = time.perf_counter_ns() - начало
        if процесс.returncode != 0 or процесс.stderr or len(процесс.stdout) > 131072:
            raise ValueError('Свежий worker не подтвердил полный профиль')
        запись = json.loads(процесс.stdout)
        if запись['контур'] != контур_до:
            raise ValueError('Worker прочитал другой контур')
        повторы.append({'повтор': номер + 1, 'код': процесс.returncode,
                       'внешний_процесс_нс': внешнее, 'процесс': запись})
    if контур_до != контур_профиля():
        raise ValueError('Контур изменился между свежими процессами')
    устойчивые = [{**п['процесс'], 'загрузка_модуля_нс': None,
                  'сценарии': [{**с, 'фазы': None} for с in п['процесс']['сценарии']]}
                 for п in повторы]
    if not устойчивые[0] == устойчивые[1] == устойчивые[2]:
        raise ValueError('Вход, AST или полный результат процессов различается')
    return {'схема': 'fum.профиль-внешнего-метода-unittest.1', 'повторы': повторы,
            'медиана_внешнего_процесса_нс': statistics.median(п['внешний_процесс_нс'] for п in повторы),
            'условия': {'исполнение_исходника': False, 'свежие_процессы': 3,
                        'подготовка_корпуса_вне_внутренних_фаз': True,
                        'контур_сверен_до_после': True}}


def главный_профиль():
    разбор = argparse.ArgumentParser(description='Профиль сборщика в трёх свежих процессах')
    режим = разбор.add_mutually_exclusive_group(required=True)
    режим.add_argument('--профиль-коллектора', action='store_true')
    режим.add_argument('--воркер-профиля', action='store_true')
    разбор.add_argument('--блоков', type=int, default=400)
    разбор.add_argument('--выход', type=Path)
    аргументы = разбор.parse_args()
    if not 1 <= аргументы.блоков <= 1000:
        разбор.error('Нужно от 1 до 1000 блоков')
    if аргументы.воркер_профиля:
        if аргументы.выход is not None:
            разбор.error('Worker пишет только stdout')
        sys.stdout.buffer.write(байты_профиля(измерить_сборщик(аргументы.блоков)))
    else:
        if аргументы.выход is None:
            разбор.error('Нужен новый файл полного профиля')
        результат = байты_профиля(профиль_свежих_процессов(аргументы.блоков))
        with аргументы.выход.open('xb') as поток:
            поток.write(результат)
        аргументы.выход.chmod(0o400)
        sys.stdout.buffer.write(результат)


if __name__ == "__main__":
    if '--профиль-коллектора' in sys.argv or '--воркер-профиля' in sys.argv:
        главный_профиль()
    else:
        unittest.main()
