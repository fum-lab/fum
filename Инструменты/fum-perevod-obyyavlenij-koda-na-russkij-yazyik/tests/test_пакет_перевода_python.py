"""Проверить точные карты областей и явных межфайловых потребителей."""
import hashlib
import ast
import copy
import importlib
import json
from pathlib import Path
import sys
import subprocess
import tempfile
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))


class ПроверкаПакетаПереводаПитона(unittest.TestCase):
    def test_нормализация_имени_не_скрывает_коллизию_со_связанным_полем(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            текст = 'class Класс:\n    value = 1\n    def ме\u0308тод(сам): return 2\ndef чтение(запись): return запись.value\n'
            связь = {'вид': 'атрибут', 'владелец': 'запись', 'имя': 'value',
                'новое': 'мётод', 'количество': 1, 'источник': 'код.py'}
            запись = сам.файл(корень, 'код.py', текст, {'value': 'мётод'}, [связь])
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
            сам.assertEqual((корень / 'код.py').read_text(), текст)

    def test_поддельный_диапазон_не_исключает_коллизию(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'value = 1\nзначение = 2\nрезультат = объект.значение\n'
        начало = текст.index('значение')
        конец = начало + len('значение')
        for диапазоны in ([(начало, конец)], [(True, конец)], [(конец + 1, конец + 2)]):
            with сам.subTest(диапазоны=диапазоны), сам.assertRaises(ValueError):
                подготовить_замены(текст, {'value': 'значение'}, связанные_атрибуты=диапазоны)

    def test_связанное_поле_не_создаёт_ложную_коллизию_своего_объявления(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            текст = 'from dataclasses import dataclass\n@dataclass\nclass Хранилище:\n    value: int\ndef чтение(запись): return запись.value\n'
            связь = {'вид': 'атрибут', 'владелец': 'запись', 'имя': 'value',
                'новое': 'значение', 'количество': 1, 'источник': 'код.py'}
            запись = сам.файл(корень, 'код.py', текст, {'value': 'значение'}, [связь])
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
            сам.assertEqual(план[0]['текст'], текст.replace('value', 'значение'))
            сам.assertEqual((корень / 'код.py').read_text(), текст)

    def test_связанное_поле_не_скрывает_настоящую_коллизию(сам):
        for добавка in ('значение = 1\n', 'другое = посторонний.значение\n'):
            with сам.subTest(добавка=добавка), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                текст = 'class Хранилище:\n    value: int\ndef чтение(запись): return запись.value\n' + добавка
                связь = {'вид': 'атрибут', 'владелец': 'запись', 'имя': 'value',
                    'новое': 'значение', 'количество': 1, 'источник': 'код.py'}
                запись = сам.файл(корень, 'код.py', текст, {'value': 'значение'}, [связь])
                with сам.assertRaises(ValueError):
                    сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
                сам.assertEqual((корень / 'код.py').read_text(), текст)

    def test_локальные_имена_распаковки_не_меняют_вызываемую_сигнатуру(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'def counted(*args, **kwargs): return args, kwargs\nполучатель.callback = counted\n'
        итог, _, _ = подготовить_замены(текст, {'args': 'аргументы', 'kwargs': 'ключи'})
        сам.assertEqual(итог, 'def counted(*аргументы, **ключи): return аргументы, ключи\nполучатель.callback = counted\n')

    def test_пакет_закрепляет_внешний_вызов_и_пространство_модуля(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            текст = 'def own(value): return value\noriginal = получатель.callback\noriginal(**параметры)\nexec("pass", модуль.__dict__)\n'
            запись = сам.файл(корень, 'код.py', текст, {'value': 'значение'})
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
            запись['внешние_вызовы'] = [[3, 0]]
            запись['исполнения'] = [[4, 0]]
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
            сам.assertEqual(план[0]['текст'], текст.replace('value', 'значение'))
            запись['внешние_вызовы'] = [[2, 0]]
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})

    def test_разные_привязки_не_сливаются_переопределением_области(сам):
        from безопасные_привязки_python import подготовить_замены
        with сам.assertRaises(ValueError):
            подготовить_замены('first=1\nsecond=2\nрезультат=(first,second)\n',
                              {'first': 'первое', 'second': 'второе'},
                              имена_областей={(0, 0, 'second'): 'первое'})

    def test_исполнение_фикстуры_в_отдельном_пустом_словаре(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'def test_old():\n    до, после = {}, {}\n    exec("value = 1", до)\n    exec("value = 2", после)\n'
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'test_old': 'test_проверка'})
        итог, _, _ = подготовить_замены(текст, {'test_old': 'test_проверка'}, разрешённые_исполнения={(3, 4), (4, 4)})
        сам.assertEqual(итог, текст.replace('def test_old', 'def test_проверка'))
        for опасный in ['def test_old(): exec("pass")\n', 'def test_old():\n    среда = globals()\n    exec("pass", среда)\n']:
            with сам.assertRaises(ValueError):
                подготовить_замены(опасный, {'test_old': 'test_проверка'})

    def test_мутация_словаря_не_разрешает_динамический_вызов(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = "class C:\n    @staticmethod\n    def method(): return 1\nсреда = {}\nпсевдоним = среда\nпсевдоним['C'] = C\nрезультат = eval('C.method()', среда)\n"
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'method': 'метод'})
        with сам.assertRaises(ValueError):
            подготовить_замены('value = 1\n', {'value': 'значение'}, разрешённые_исполнения={(1, 0)})

    def test_пакет_закрепляет_явное_исполнение_хэшем_и_координатой(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            запись = сам.файл(корень, 'код.py', 'def test_old():\n    среда = {}\n    exec("pass", среда)\n', {'test_old': 'test_проверка'})
            запись['исполнения'] = [[3, 4]]
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
            сам.assertIn('def test_проверка', план[0]['текст'])
            запись['исполнения'] = [[2, 4]]
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})

    def test_имя_по_конкретной_области_и_встроенный_код(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            текст = "def one(p): return p\ndef two(p): return p\nкод = 'print([k for k in range(2)])'\n"
            запись = сам.файл(корень, 'код.py', текст, {'p': 'путь'})
            запись['имена_областей'] = [[1, 0, 'p', 'результат']]
            запись['код'] = [{'строка': 3, 'столбец': 9, 'хэш': hashlib.sha256(b'print([k for k in range(2)])').hexdigest(), 'переводы': {'k': 'ключ'}}]
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
            сам.пакет().применить(план)
            сам.assertEqual((корень/'код.py').read_text(), "def one(результат): return результат\ndef two(путь): return путь\nкод = 'print([ключ for ключ in range(2)])'\n")

    def test_словарь_явного_внешнего_объекта_не_читает_локальные_имена(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'value = vars(параметры).copy()\n'
        итог, _, _ = подготовить_замены(текст, {'value': 'значение'})
        сам.assertEqual(итог, 'значение = vars(параметры).copy()\n')
        with сам.assertRaises(ValueError):
            подготовить_замены('value = 1\nvars()\n', {'value': 'значение'})

    def test_единственная_привязка_лямбды_и_явное_значение_по_умолчанию(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'f = lambda value: value + 1\nрезультат = f(value=2)\n'
        итог, _, _ = подготовить_замены(текст, {'value': 'значение'})
        сам.assertIn('f(значение=2)', итог)
        до, после = {}, {}
        exec(текст, до)
        exec(итог, после)
        сам.assertEqual(до['результат'], после['результат'])
        текст = 'def own(observer=lambda phase: None): observer(1)\nown()\n'
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'phase': 'фаза'})
        итог, _, _ = подготовить_замены(текст, {'phase': 'фаза'}, разрешённые_передачи={(1, 17, '<lambda>')})
        сам.assertIn('lambda фаза: None', итог)

    def test_переименование_теста_не_меняет_несвязанный_динамический_вызов(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'def test_old():\n    вызов = получить()\n    вызов(**настройки)\n'
        итог, _, _ = подготовить_замены(текст, {'test_old': 'test_проверка'})
        сам.assertEqual(итог, 'def test_проверка():\n    вызов = получить()\n    вызов(**настройки)\n')

    def test_явная_позиционная_лямбда_сохраняет_поведение(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'результат = sorted([2, 1], key=lambda value: value)\n'
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'value': 'значение'})
        итог, _, _ = подготовить_замены(текст, {'value': 'значение'}, разрешённые_передачи={(1, 40, '<lambda>')})
        до, после = {}, {}
        exec(текст, до)
        exec(итог, после)
        сам.assertEqual(до['результат'], после['результат'])

    def пакет(сам):
        return importlib.import_module('пакет_перевода_python')

    def файл(сам, корень, имя, текст, карта=None, связи=None, области=None, передачи=None):
        путь = корень / имя
        путь.write_text(текст)
        return {'путь': имя, 'хэш': hashlib.sha256(путь.read_bytes()).hexdigest(),
                'переводы': карта or {}, 'области': области, 'связи': связи or [], 'передачи': передачи or []}

    def test_единый_план_связывает_экспорт_атрибут_и_рефлексию(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            файлы = [сам.файл(корень, 'модуль.py', 'def git(value):\n    return value\n', {'git': 'гит', 'value': 'значение'})]
            связь = {'вид': 'атрибут', 'владелец': 'module', 'имя': 'git', 'новое': 'гит', 'количество': 1, 'источник': 'модуль.py'}
            рефлексия = {**связь, 'вид': 'строковый_атрибут'}
            файлы.append(сам.файл(корень, 'потребитель.py', 'module.git(1)\npatch.object(module, "git", replacement)\n', связи=[связь, рефлексия]))
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': файлы})
            сам.assertEqual((корень/'модуль.py').read_text(), 'def git(value):\n    return value\n')
            сам.пакет().применить(план)
            сам.assertEqual((корень/'модуль.py').read_text(), 'def гит(значение):\n    return значение\n')
            сам.assertEqual((корень/'потребитель.py').read_text(), 'module.гит(1)\npatch.object(module, "гит", replacement)\n')

    def test_неверная_связь_или_число_закрывают_пакет_до_записи(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            файлы = [сам.файл(корень, 'модуль.py', 'def git(): pass\n', {'git': 'гит'})]
            связь = {'вид': 'атрибут', 'владелец': 'module', 'имя': 'git', 'новое': 'гит', 'количество': 2, 'источник': 'модуль.py'}
            файлы.append(сам.файл(корень, 'потребитель.py', 'module.git()\n', связи=[связь]))
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': файлы})
            сам.assertEqual((корень/'модуль.py').read_text(), 'def git(): pass\n')
            связь['количество'] = 1
            связь['новое'] = 'подмена'
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': файлы})

    def test_изменение_после_плана_не_пишет_ни_одного_файла(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            файлы = [сам.файл(корень, 'первый.py', 'value = 1\n', {'value': 'значение'}), сам.файл(корень, 'второй.py', 'value = 2\n', {'value': 'значение'})]
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': файлы})
            (корень/'второй.py').write_text('value = 3\n')
            with сам.assertRaises(ValueError):
                сам.пакет().применить(план)
            сам.assertEqual((корень/'первый.py').read_text(), 'value = 1\n')

    def test_карта_областей_оставляет_исторический_одноимённый_параметр(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            запись = сам.файл(корень, 'код.py', 'def old(self): return self\ndef new(self): return self\n', {'self': 'сам'}, области={'self': [[2, 0]]})
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись]})
            сам.пакет().применить(план)
            сам.assertEqual((корень/'код.py').read_text(), 'def old(self): return self\ndef new(сам): return сам\n')

    def test_ссылка_и_повтор_пути_отклоняются(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            запись = сам.файл(корень, 'код.py', 'value=1\n', {'value': 'значение'})
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [запись, запись]})
            (корень/'ссылка.py').symlink_to(корень/'код.py')
            with сам.assertRaises(ValueError):
                сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': [{**запись, 'путь': 'ссылка.py'}]})

    def test_передача_обратного_вызова_требует_точной_координаты(сам):
        from безопасные_привязки_python import подготовить_замены
        текст = 'def callback(phase): return phase\nregister(callback)\n'
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'phase': 'фаза'})
        итог, _, _ = подготовить_замены(текст, {'phase': 'фаза'}, разрешённые_передачи={(2, 9, 'callback')})
        сам.assertEqual(итог, 'def callback(фаза): return фаза\nregister(callback)\n')
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'phase': 'фаза'}, разрешённые_передачи={(99, 0, 'callback')})

    def test_прямой_импорт_меняет_только_свою_привязку(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            исходник = 'from модуль import old\nрезультат = old(1)\ndef вложенная(old): return old\nещё = [old for old in range(2)]\ndef внешний(): return old(3)\n'
            связь = {'вид': 'импорт', 'владелец': 'модуль', 'имя': 'old', 'новое': 'свой', 'количество': 3, 'источник': 'модуль.py'}
            файлы = [сам.файл(корень, 'модуль.py', 'def old(value): return value\n', {'old': 'свой'}),
                     сам.файл(корень, 'потребитель.py', исходник, связи=[связь])]
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': файлы})
            сам.пакет().применить(план)
            сам.assertEqual((корень/'потребитель.py').read_text(), исходник.replace('import old', 'import свой').replace('old(1)', 'свой(1)').replace('old(3)', 'свой(3)'))

    def test_импорт_с_псевдонимом_сохраняет_потребителя(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            исходник = 'from модуль import old as получатель\nрезультат = получатель(1)\n'
            связь = {'вид': 'импорт', 'владелец': 'модуль', 'имя': 'old', 'новое': 'свой', 'количество': 1, 'источник': 'модуль.py'}
            файлы = [сам.файл(корень, 'модуль.py', 'def old(value): return value\n', {'old': 'свой'}),
                     сам.файл(корень, 'потребитель.py', исходник, связи=[связь])]
            план = сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': файлы})
            сам.пакет().применить(план)
            сам.assertEqual((корень/'потребитель.py').read_text(), исходник.replace('import old', 'import свой'))

    def test_неоднозначный_импорт_отклоняется_без_записи(сам):
        варианты = [
            ('from другой import old\nold()\n', 2),
            ('from модуль import old\nold()\n', 1),
            ('from модуль import *\nold()\n', 1),
            ('from модуль import old\nold = 3\n', 1),
            ('from модуль import old\nсвой = 3\nold()\n', 2),
            ('from .модуль import old\nold()\n', 2),
            ('from модуль import old\nfrom модуль import old\nold()\n', 3),
            ('from модуль import old\ndef вложенная(свой): return old()\n', 2),
            ('from модуль import old\ndef вложенная():\n global old\n return old()\n', 2),
            ('from модуль import old\n__all__ = ["old"]\n', 1),
            ('from модуль import old\ngetattr(модуль, "old")\n', 1),
            ('from модуль import old\nрезультат = globals()["old"]\n', 1),
        ]
        for исходник, количество in варианты:
            with сам.subTest(исходник=исходник), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                связь = {'вид': 'импорт', 'владелец': 'модуль', 'имя': 'old', 'новое': 'свой', 'количество': количество, 'источник': 'модуль.py'}
                файлы = [сам.файл(корень, 'модуль.py', 'def old(): return 1\n', {'old': 'свой'}),
                         сам.файл(корень, 'потребитель.py', исходник, связи=[связь])]
                with сам.assertRaises(ValueError):
                    сам.пакет().подготовить(корень, {'схема': 'fum.пакет-перевода-python.1', 'файлы': файлы})
                сам.assertEqual((корень/'модуль.py').read_text(), 'def old(): return 1\n')
                сам.assertEqual((корень/'потребитель.py').read_text(), исходник)


class ПроверкаПолейДинамическогоМодуля(unittest.TestCase):
    def фикстура(сам, корень, преобразовать=None):
        исходники = {
            'код.py': ('import importlib.abc\nimport sys\n'
                'class Загрузчик(importlib.abc.Loader):\n'
                '    def exec_module(сам, модуль):\n'
                '        модуль._own_sha256 = 7\n'
                'def прочитать(выбранное):\n'
                '    for имя, модуль in list(sys.modules.items()):\n'
                '        if имя == выбранное:\n'
                '            return getattr(модуль, "_own_sha256", None)\n'),
            'test_код.py': ('import importlib.util\nfrom unittest import mock\n'
                'def загрузить(путь):\n'
                '    описание = importlib.util.spec_from_file_location("пример", путь)\n'
                '    модуль = importlib.util.module_from_spec(описание)\n'
                '    описание.loader.exec_module(модуль)\n'
                '    return модуль\n'
                'def проверка(путь):\n'
                '    модуль = загрузить(путь)\n'
                '    with mock.patch.object(модуль, "_own_sha256", 8):\n'
                '        assert модуль._own_sha256 == 8\n'
                '    assert "_own_sha256" == "_own_sha256"\n')}
        if преобразовать is not None:
            исходники = преобразовать(исходники)
        файлы, владельцы, употребления = [], [], []
        for путь, текст in исходники.items():
            (корень / путь).write_text(текст)
            дерево = ast.parse(текст)
            from безопасные_привязки_python import ОбластиПитона
            области = ОбластиПитона(дерево)
            локальные = {}
            for узел in ast.walk(дерево):
                if not isinstance(узел, ast.Name) or узел.id != 'модуль':
                    continue
                область = области.владельцы[узел].владелец(узел.id)
                ключ = (getattr(область.узел, 'lineno', 0), getattr(область.узел, 'col_offset', 0))
                if ключ not in локальные:
                    привязка = область.привязки['модуль'][0][1]
                    локальные[ключ] = len(владельцы)
                    владельцы.append({'путь': путь, 'имя': 'модуль', 'область': list(ключ),
                        'получение': [привязка.lineno, привязка.col_offset]})
            for узел in ast.walk(дерево):
                вид, получатель = None, None
                if isinstance(узел, ast.Attribute) and узел.attr == '_own_sha256':
                    вид = 'запись' if isinstance(узел.ctx, ast.Store) else 'чтение'
                    получатель = узел.value
                elif isinstance(узел, ast.Call) and len(узел.args) >= 2 and isinstance(узел.args[1], ast.Constant) and узел.args[1].value == '_own_sha256':
                    вид = 'getattr' if isinstance(узел.func, ast.Name) else 'patch.object'
                    получатель = узел.args[0]
                if вид:
                    область = области.владельцы[получатель].владелец(получатель.id)
                    ключ = (getattr(область.узел, 'lineno', 0), getattr(область.узел, 'col_offset', 0))
                    употребления.append({'путь': путь, 'строка': узел.lineno, 'столбец': узел.col_offset,
                        'вид': вид, 'владелец': локальные[ключ]})
            файлы.append({'путь': путь, 'хэш': hashlib.sha256(текст.encode()).hexdigest(),
                'переводы': {'_own_sha256': '_собственный_хэш'} if путь == 'код.py' else {},
                'области': None, 'связи': [], 'передачи': []})
        номера = sorted({у['владелец'] for у in употребления})
        for употребление in употребления:
            употребление['владелец'] = номера.index(употребление['владелец'])
        владельцы = [владельцы[н] for н in номера]
        поле = {'имя': '_own_sha256', 'новое': '_собственный_хэш', 'источник': 'код.py',
            'владельцы': владельцы, 'употребления': употребления, 'количество': len(употребления)}
        return исходники, {'схема': 'fum.пакет-перевода-python.2', 'файлы': файлы, 'поля_модулей': [поле]}

    def test_полный_пакет_поля_и_обычные_строки(сам):
        import пакет_перевода_python as пакет
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            исходники, карта = сам.фикстура(корень)
            план = пакет.подготовить(корень, карта)
            сам.assertEqual(len(план), 2)
            сам.assertEqual(пакет.описание(план)['схема'], 'fum.план-перевода-python.2')
            пакет.применить(план)
            for путь, исходник in исходники.items():
                итог = (корень / путь).read_text()
                сам.assertIn('_собственный_хэш', итог)
                if путь.startswith('test_'):
                    сам.assertIn('assert "_own_sha256" == "_own_sha256"', итог)
                сам.assertEqual(исходник.count('exec_module'), итог.count('exec_module'))
            with сам.assertRaises(ValueError):
                пакет.подготовить(корень, карта)
            import types
            from unittest import mock
            пространство = {'__name__': 'фикстура_поля'}
            exec((корень / 'код.py').read_text(), пространство)
            модуль = types.ModuleType('пример')
            пространство['Загрузчик']().exec_module(модуль)
            with mock.patch.dict(sys.modules, {'пример': модуль}):
                сам.assertEqual(пространство['прочитать']('пример'), 7)
                тест = {'__name__': 'фикстура_потребителя'}
                exec((корень / 'test_код.py').read_text(), тест)
                with mock.patch('importlib.util.module_from_spec', return_value=модуль):
                    тест['проверка'](корень / 'код.py')
                сам.assertEqual(модуль._собственный_хэш, 7)
            повтор = {'схема': 'fum.пакет-перевода-python.2', 'поля_модулей': [],
                'файлы': [{**з, 'хэш': hashlib.sha256((корень / з['путь']).read_bytes()).hexdigest(), 'переводы': {}} for з in карта['файлы']]}
            карта_повтора = корень / 'повтор.json'
            карта_повтора.write_text(json.dumps(повтор, ensure_ascii=False))
            до = {п: ((корень / п).read_bytes(), (корень / п).stat().st_ino, (корень / п).stat().st_mtime_ns) for п in исходники}
            итог = subprocess.run([sys.executable, '-B', str(Path(пакет.__file__)), 'применить',
                '--корень-репозитория', str(корень), '--карта', str(карта_повтора), '--выход', str(корень / 'план-повтора.json')],
                capture_output=True, text=True)
            сам.assertEqual(итог.returncode, 0, итог.stderr)
            сам.assertEqual({п: ((корень / п).read_bytes(), (корень / п).stat().st_ino, (корень / п).stat().st_mtime_ns) for п in исходники}, до)

    def test_неполное_или_подменённое_свидетельство_не_пишет(сам):
        import пакет_перевода_python as пакет
        for случай in ('счётчик', 'потребитель', 'SHA', 'владелец', 'координата', 'повтор'):
            with сам.subTest(случай=случай), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                исходники, карта = сам.фикстура(корень)
                поле = карта['поля_модулей'][0]
                if случай == 'счётчик': поле['количество'] += 1
                if случай == 'потребитель': поле['употребления'].pop(); поле['количество'] -= 1
                if случай == 'SHA': карта['файлы'][1]['хэш'] = '0' * 64
                if случай == 'владелец': поле['владельцы'][0]['имя'] = 'чужой'
                if случай == 'координата': поле['употребления'][0]['строка'] += 1
                if случай == 'повтор': поле['употребления'].append(copy.deepcopy(поле['употребления'][0])); поле['количество'] += 1
                with сам.assertRaises(ValueError): пакет.подготовить(корень, карта)
                сам.assertEqual({п: (корень / п).read_text() for п in исходники}, исходники)

    def test_получение_модуля_из_реестра_сохраняет_доказательство(сам):
        import пакет_перевода_python as пакет
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            def изменить(исходники):
                исходники['test_код.py'] = 'import sys\n' + исходники['test_код.py'].replace(
                    '    модуль = загрузить(путь)', '    модуль = sys.modules["пример"]')
                return исходники
            исходники, карта = сам.фикстура(корень, изменить)
            сам.assertEqual(len(пакет.подготовить(корень, карта)), 2)
            сам.assertEqual({п: (корень / п).read_text() for п in исходники}, исходники)

    def test_прежняя_запись_поля_остаётся_закрытой(сам):
        import пакет_перевода_python as пакет
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            исходники, карта = сам.фикстура(корень)
            карта['схема'] = 'fum.пакет-перевода-python.1'
            del карта['поля_модулей']
            with сам.assertRaisesRegex(ValueError, 'Неизвестный владелец записываемого поля'):
                пакет.подготовить(корень, карта)
            сам.assertEqual({п: (корень / п).read_text() for п in исходники}, исходники)

    def test_затенение_интерфейса_и_вычисляемая_строка_закрыты(сам):
        import пакет_перевода_python as пакет
        изменения = (
            ('код.py', 'def прочитать(выбранное):', 'def прочитать(выбранное, getattr):'),
            ('test_код.py', 'def проверка(путь):', 'def проверка(путь, mock):'),
            ('test_код.py', '    with mock.patch.object', '    mock.patch = чужая\n    with mock.patch.object'),
            ('test_код.py', '    with mock.patch.object', '    коробка = [mock.patch]\n    коробка[0].object = чужая\n    with mock.patch.object'),
            ('test_код.py', '    with mock.patch.object', '    mock.patch.object.__code__ = чужая.__code__\n    with mock.patch.object'),
            ('test_код.py', '    with mock.patch.object', '    mock.patch.object.__defaults__ = (чужая,)\n    with mock.patch.object'),
            ('test_код.py', '    with mock.patch.object', '    mock.patch.object.__kwdefaults__ = {"чужая": чужая}\n    with mock.patch.object'),
            ('test_код.py', '    with mock.patch.object', '    mock.patch.object.__class__ = чужая\n    with mock.patch.object'),
            ('код.py', 'getattr(модуль, "_own_sha256", None)', 'getattr(модуль, "_own_" + "sha256", None)'),
            ('код.py', 'getattr(модуль, "_own_sha256", None)', 'getattr(модуль, имя, None)'),
            ('код.py', '        модуль._own_sha256 = 7', '        модуль = чужой\n        модуль._own_sha256 = 7'),
            ('код.py', '        модуль._own_sha256 = 7', '        неизвестная(модуль)\n        модуль._own_sha256 = 7'),
            ('код.py', '        модуль._own_sha256 = 7', '        неизвестная([модуль])\n        модуль._own_sha256 = 7'),
            ('код.py', '        модуль._own_sha256 = 7', '        сохранённые = [модуль]\n        модуль._own_sha256 = 7'),
            ('код.py', '        модуль._own_sha256 = 7', '        модуль.__dict__["_own_sha256"] = 8\n        модуль._own_sha256 = 7'),
            ('код.py', '        модуль._own_sha256 = 7', '        модуль.__setattr__("_own_sha256", 8)\n        модуль._own_sha256 = 7'),
            ('код.py', '        модуль._own_sha256 = 7', '        assert "_own_sha256" in модуль.__dir__()\n        модуль._own_sha256 = 7'),
            ('код.py', '        модуль._own_sha256 = 7', '        assert "_own_sha256" in getattr(модуль, "__dir__")()\n        модуль._own_sha256 = 7'),
            ('test_код.py', '    описание.loader.exec_module(модуль)', '    неизвестная([модуль])\n    описание.loader.exec_module(модуль)'),
            ('код.py', '        модуль._own_sha256 = 7', '        словарь = getattr(модуль, "__dict__")\n        модуль._own_sha256 = 7'),
            ('test_код.py', '    with mock.patch.object(модуль, "_own_sha256", 8):',
                '    mock.patch.object(mock.patch, "object", чужая).start()\n    with mock.patch.object(модуль, "_own_sha256", 8):'),
            ('код.py', 'def прочитать(выбранное):', 'import builtins\nfrom unittest import mock\nmock.patch.object(builtins, "getattr", чужая).start()\ndef прочитать(выбранное):'),
            ('test_код.py', '        assert модуль._own_sha256 == 8', '        assert модуль._own_sha256 == 8\n        модуль._собственный_хэш = 9'),
            ('test_код.py', '        assert модуль._own_sha256 == 8', '        assert модуль._own_sha256 == 8\n    with mock.patch.object(модуль, "_собственный_хэш", 8, create=True): pass'),
        )
        for путь, до, после in изменения:
            with сам.subTest(изменение=после), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                def изменить(исходники):
                    исходники[путь] = исходники[путь].replace(до, после)
                    return исходники
                исходники, карта = сам.фикстура(корень, изменить)
                with сам.assertRaises(ValueError): пакет.подготовить(корень, карта)
                сам.assertEqual({п: (корень / п).read_text() for п in исходники}, исходники)


class ПроверкаПубличногоЗамыкания(unittest.TestCase):
    """Свежие production import и изменяющий CLI, без подмен модулей."""

    каталог = Path(__file__).resolve().parents[1] / 'scripts'

    def процесс(сам, этап, аргументы, корень, требовать_успех=True):
        начало = time.perf_counter_ns()
        итог = subprocess.run(аргументы, cwd=корень, capture_output=True, text=True)
        сам.метки.append({'этап': этап, 'длительность_нс': time.perf_counter_ns() - начало,
            'код': итог.returncode, 'stdout_sha256': hashlib.sha256(итог.stdout.encode()).hexdigest(),
            'stderr_sha256': hashlib.sha256(итог.stderr.encode()).hexdigest()})
        if требовать_успех:
            сам.assertEqual(итог.returncode, 0, итог.stderr)
        return итог

    def публичный_импорт(сам):
        сам.метки = []
        код = ('import importlib, json, sys\nfrom pathlib import Path\n'
            'каталог = Path(sys.argv[1]).resolve()\nsys.path.insert(0, str(каталог))\n'
            'главный = importlib.import_module("перевести-объявления-кода")\n'
            'разбор = importlib.import_module("разбор_сценария")\n'
            'assert Path(главный.__file__).resolve() == каталог / "перевести-объявления-кода.py"\n'
            'assert Path(разбор.__file__).resolve() == каталог / "разбор_сценария.py"\n'
            'assert hasattr(разбор, "путь_живого_моста") and callable(разбор.разобрать_живой_перевод)\n'
            'print(json.dumps({"главный": главный.__file__, "разбор": разбор.__file__}, ensure_ascii=False))\n')
        сам.процесс('свежий публичный импорт',
            [sys.executable, '-I', '-S', '-B', '-c', код, str(сам.каталог)], сам.каталог)
        return сам.метки

    def фикстура_двух_полей(сам, корень):
        исходники = {
            'код.py': ('import importlib.abc\n\n'
                'class Загрузчик(importlib.abc.Loader):\n'
                '    def create_module(сам, описание):\n        return None\n\n'
                '    def exec_module(сам, модуль):\n'
                '        модуль._own_sha256 = 7\n        модуль._own_crc32 = 11\n'),
            'test_код.py': ('import importlib.util\nfrom pathlib import Path\nfrom код import Загрузчик\n\n'
                'def загрузить(путь):\n'
                '    описание = importlib.util.spec_from_file_location("пример", путь, loader=Загрузчик())\n'
                '    модуль = importlib.util.module_from_spec(описание)\n'
                '    описание.loader.exec_module(модуль)\n    return модуль\n\n'
                'def проверка(путь):\n    модуль = загрузить(путь)\n'
                '    assert getattr(модуль, "_own_sha256") == 7\n'
                '    assert getattr(модуль, "_own_crc32") == 11\n'
                '    assert модуль._own_sha256 == 7\n    assert модуль._own_crc32 == 11\n'
                '    assert "_own_sha256/_own_crc32" == "_own_sha256/_own_crc32"\n\n'
                'if __name__ == "__main__":\n    проверка(Path(__file__).with_name("код.py"))\n')}
        переводы = {'_own_sha256': '_собственный_хэш', '_own_crc32': '_собственная_сумма'}
        деревья = {путь: ast.parse(текст) for путь, текст in исходники.items()}
        функции = {путь: next(у for у in ast.walk(дерево) if isinstance(у, ast.FunctionDef)
            and у.name == ('exec_module' if путь == 'код.py' else 'проверка'))
            for путь, дерево in деревья.items()}
        владельцы = []
        for путь, функция in функции.items():
            привязка = (next(а for а in функция.args.args if а.arg == 'модуль') if путь == 'код.py'
                else next(у for у in ast.walk(функция) if isinstance(у, ast.Name)
                    and у.id == 'модуль' and isinstance(у.ctx, ast.Store)))
            владельцы.append({'путь': путь, 'имя': 'модуль',
                'область': [функция.lineno, функция.col_offset],
                'получение': [привязка.lineno, привязка.col_offset]})
        поля = []
        for имя, новое in переводы.items():
            употребления = []
            for номер, (путь, функция) in enumerate(функции.items()):
                for узел in ast.walk(функция):
                    вид = None
                    if isinstance(узел, ast.Attribute) and узел.attr == имя:
                        вид = 'запись' if isinstance(узел.ctx, ast.Store) else 'чтение'
                    elif (isinstance(узел, ast.Call) and isinstance(узел.func, ast.Name)
                            and узел.func.id == 'getattr' and len(узел.args) == 2
                            and isinstance(узел.args[1], ast.Constant) and узел.args[1].value == имя):
                        вид = 'getattr'
                    if вид:
                        употребления.append({'путь': путь, 'строка': узел.lineno,
                            'столбец': узел.col_offset, 'вид': вид, 'владелец': номер})
            сам.assertEqual(len(употребления), 3)
            поля.append({'имя': имя, 'новое': новое, 'источник': 'код.py',
                'владельцы': copy.deepcopy(владельцы), 'употребления': употребления, 'количество': 3})
        файлы = []
        for путь, текст in исходники.items():
            (корень / путь).write_text(текст)
            файлы.append({'путь': путь, 'хэш': hashlib.sha256(текст.encode()).hexdigest(),
                'переводы': переводы if путь == 'код.py' else {},
                'области': None, 'связи': [], 'передачи': []})
        return исходники, {'схема': 'fum.пакет-перевода-python.2',
            'файлы': файлы, 'поля_модулей': поля}

    def пакетный_цикл(сам):
        сам.метки = []
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            исходники, карта = сам.фикстура_двух_полей(корень)
            вход = {п: hashlib.sha256(т.encode()).hexdigest() for п, т in исходники.items()}
            карта_путь = корень / 'карта.json'
            карта_путь.write_text(json.dumps(карта, ensure_ascii=False, indent=2) + '\n')
            cli = [sys.executable, '-S', '-B', str(сам.каталог / 'пакет_перевода_python.py')]
            def команда(действие, файл_карты, выход):
                return [*cli, действие, '--корень-репозитория', str(корень),
                    '--карта', str(файл_карты), '--выход', str(выход)]
            выполнить = [sys.executable, '-S', '-B', str(корень / 'test_код.py')]
            сам.процесс('исходная фикстура', выполнить, корень)
            сам.процесс('публичный план', команда('план', карта_путь, корень / 'план.json'), корень)
            план = json.loads((корень / 'план.json').read_bytes())
            сам.assertEqual(план['схема'], 'fum.план-перевода-python.2')
            сам.assertEqual(len(план['файлы']), 2)
            сам.assertEqual(len(план['поля_модулей']), 2)
            сам.assertTrue(all(з['до'] != з['после'] for з in план['файлы']))
            сам.assertEqual({п: (корень / п).read_text() for п in исходники}, исходники)
            итог = сам.процесс('публичное изменяющее применение',
                команда('применить', карта_путь, корень / 'применение.json'), корень, False)
            if итог.returncode:
                сам.assertEqual({п: (корень / п).read_text() for п in исходники}, исходники)
            сам.assertEqual(итог.returncode, 0, итог.stderr)
            сам.assertEqual((корень / 'план.json').read_bytes(), (корень / 'применение.json').read_bytes())
            ожидания = {'_own_sha256': '_собственный_хэш', '_own_crc32': '_собственная_сумма'}
            for путь, исходник in исходники.items():
                новый = (корень / путь).read_text()
                дерево = ast.parse(новый)
                сам.assertFalse(any(isinstance(у, ast.Attribute) and у.attr in ожидания for у in ast.walk(дерево)))
                for имя in ожидания.values():
                    сам.assertIn(имя, новый)
                for api in ('create_module', 'exec_module', 'module_from_spec', 'spec_from_file_location'):
                    сам.assertEqual(исходник.count(api), новый.count(api))
                if путь.startswith('test_'):
                    сам.assertIn('assert "_own_sha256/_own_crc32" == "_own_sha256/_own_crc32"', новый)
            сам.процесс('переведённая фикстура', выполнить, корень)
            остаток = {'схема': 'fum.пакет-перевода-python.2', 'поля_модулей': [],
                'файлы': [{**з, 'хэш': hashlib.sha256((корень / з['путь']).read_bytes()).hexdigest(),
                    'переводы': {}} for з in карта['файлы']]}
            повтор = корень / 'повтор.json'
            повтор.write_text(json.dumps(остаток, ensure_ascii=False, indent=2) + '\n')
            до = {п: ((корень / п).read_bytes(), (корень / п).stat().st_ino,
                (корень / п).stat().st_mtime_ns) for п in исходники}
            сам.процесс('свежий план остатка', команда('план', повтор, корень / 'остаток.json'), корень)
            сам.процесс('свежий повтор без записи', команда('применить', повтор, корень / 'повтор-план.json'), корень)
            сам.assertEqual({п: ((корень / п).read_bytes(), (корень / п).stat().st_ino,
                (корень / п).stat().st_mtime_ns) for п in исходники}, до)
            сам.assertTrue(all(з['до'] == з['после'] for з in json.loads((корень / 'остаток.json').read_bytes())['файлы']))
            return {'вход': вход, 'выход': {п: hashlib.sha256((корень / п).read_bytes()).hexdigest()
                for п in исходники}, 'метки': сам.метки}

    def test_свежий_публичный_импорт(сам):
        сам.публичный_импорт()

    def test_свежий_публичный_пакет_двух_полей(сам):
        сам.пакетный_цикл()


def измерить_публичный_пакет(выход):
    """Три рабочих цикла полного входа; ImportError не является базой скорости."""
    import platform
    import statistics
    файлы = [ПроверкаПубличногоЗамыкания.каталог / имя for имя in (
        'перевести-объявления-кода.py', 'пакет_перевода_python.py',
        'безопасные_привязки_python.py', 'разбор_сценария.py', 'аббревиатуры_контекста.py')]
    файлы.append(Path(__file__).resolve())
    def хэши():
        return {п.name: hashlib.sha256(п.read_bytes()).hexdigest() for п in файлы}
    до = хэши()
    повторы = []
    for _ in range(3):
        проверка = ПроверкаПубличногоЗамыкания()
        начало = time.perf_counter_ns()
        импорт = проверка.публичный_импорт()
        цикл = проверка.пакетный_цикл()
        повторы.append({**цикл, 'импорт': импорт, 'полный_цикл_нс': time.perf_counter_ns() - начало})
    if до != хэши() or any((п['вход'], п['выход']) != (повторы[0]['вход'], повторы[0]['выход']) for п in повторы):
        raise ValueError('Источники или результат публичного цикла изменились')
    результат = {'схема': 'fum.профиль-публичного-пакета-python.1',
        'Python': platform.python_version(), 'источники_sha256': до, 'повторы': повторы,
        'медиана_полного_цикла_нс': statistics.median(п['полный_цикл_нс'] for п in повторы),
        'условия': 'Три малые одинаковые пары, оба поля, отдельные свежие процессы настоящего импорта, public plan/apply, исполнения фикстуры и no-effect повтора. Общий цикл включает подготовку фикстуры и проверки; метки процессов вложены и повторно не суммируются. RED ImportError не используется для заявления ускорения.'}
    with Path(выход).open('x', encoding='utf-8') as поток:
        поток.write(json.dumps(результат, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'повторов': 3, 'медиана_полного_цикла_нс': результат['медиана_полного_цикла_нс']}, ensure_ascii=False))


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--профиль-публичного-пакета':
        измерить_публичный_пакет(sys.argv[2])
    else:
        unittest.main()
