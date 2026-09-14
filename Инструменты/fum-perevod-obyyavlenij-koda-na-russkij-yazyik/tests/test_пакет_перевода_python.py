"""Проверить точные карты областей и явных межфайловых потребителей."""
import hashlib
import importlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))


class ПроверкаПакетаПереводаПитона(unittest.TestCase):
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


if __name__ == '__main__':
    unittest.main()
