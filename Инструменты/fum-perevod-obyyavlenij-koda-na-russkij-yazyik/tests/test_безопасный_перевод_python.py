"""Регрессии принадлежности Python-имён; исходные фрагменты — открытые фикстуры."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest


путь = Path(__file__).resolve().parents[1] / "scripts/перевести-объявления-кода.py"
спецификация = importlib.util.spec_from_file_location("переводчик_проверяемый", путь)
переводчик = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = переводчик
спецификация.loader.exec_module(переводчик)


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
        итог = сам.перевод('f = lambda value: value + 1\nx = [value for value in range(3)]\n', {"value": "значение"})
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
        текст = 'import ast\ndef visit(): pass\nclass Other:\n    def visit(self): pass\nclass Visitor(ast.NodeVisitor):\n    def visit(self, node): pass\n    def visit_Lambda(self, node): pass\n    def visit_fake(self, node): pass\n'
        with tempfile.TemporaryDirectory() as каталог:
            файл = Path(каталог) / 'пример.py'
            файл.write_text(текст)
            найденные = переводчик.объявления_питона(файл, 'пример.py')
        сам.assertEqual([з.строка for з in найденные if з.имя == 'visit'], [2, 4])
        сам.assertFalse(any(з.имя == 'visit_Lambda' for з in найденные))
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


if __name__ == "__main__":
    unittest.main()
