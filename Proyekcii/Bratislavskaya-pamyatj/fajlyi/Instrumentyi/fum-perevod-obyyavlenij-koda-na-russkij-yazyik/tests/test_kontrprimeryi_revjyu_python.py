"""Сохранить семантику контрпримеров независимого ревью C8225."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from безопасные_привязки_python import подготовить_замены


class ПроверкаКонтрпримеровРевью(unittest.TestCase):
    def test_селектор_передачи_не_разрешает_получателя_метода_вызова(сам):
        текст = 'def callback(value): return value\ncallback.__call__(value=1)\n'
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'value': 'значение'}, разрешённые_передачи={(2, 0, 'callback')})

    def test_метод_вызова_лямбды_не_является_прямым_вызовом(сам):
        with сам.assertRaises(ValueError):
            подготовить_замены('результат = (lambda value: value).__call__(value=1)\n', {'value': 'значение'})

    def test_декорированный_класс_не_доказывает_конструктор(сам):
        текст = '''def обёртка(класс):
    return lambda **аргументы: аргументы['value']
@обёртка
class Контейнер:
    def __init__(сам, value): pass
результат = Контейнер(value=1)
'''
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'value': 'значение'})

    def равное_поведение(сам, текст, карта, **настройки):
        итог, _, _ = подготовить_замены(текст, карта, **настройки)
        до, после = {}, {}
        exec(compile(текст, '<фикстура>', 'exec'), до)
        exec(compile(итог, '<фикстура>', 'exec'), после)
        сам.assertEqual(до['результат'], после['результат'])
        return итог

    def test_глобальная_директива_промежуточной_функции_ограничивает_замыкание(сам):
        текст = '''from math import pi
def outer():
    pi = 3
    def middle():
        global pi
        def inner():
            return pi
        return inner()
    return middle()
результат = outer()
'''
        итог = сам.равное_поведение(текст, {'pi': 'число'})
        сам.assertIn('число = 3', итог)
        сам.assertIn('return pi', итог)

    def test_позиционный_параметр_не_переименовывает_ключ_словаря(сам):
        итог = сам.равное_поведение('def своя(value, /, **аргументы):\n    return аргументы["value"]\nрезультат = своя(0, value=1)\n', {'value': 'значение'})
        сам.assertIn('своя(0, value=1)', итог)

    def test_непосредственный_вызов_лямбды_согласован(сам):
        итог = сам.равное_поведение('результат = (lambda value: value)(value=1)\n', {'value': 'значение'})
        сам.assertEqual(итог, 'результат = (lambda значение: значение)(значение=1)\n')

    def test_декоратор_свойства_не_доказывает_сигнатуру_возвращённой_функции(сам):
        текст = '''class Контейнер:
    @property
    def вызов(сам, value=0):
        return lambda **аргументы: аргументы["value"]
    def получить(сам):
        return сам.вызов(value=1)
результат = Контейнер().получить()
'''
        with сам.assertRaises(ValueError):
            подготовить_замены(текст, {'value': 'значение'})

    def test_нелокальная_директива_пропускает_пространство_класса(сам):
        текст = '''def внешняя():
    value = 1
    class Класс:
        value = 2
        def метод(сам):
            nonlocal value
            return value
    return Класс().метод()
результат = внешняя()
'''
        итог = сам.равное_поведение(текст, {'value': 'значение'}, выбранные_области={(1, 0, 'value')})
        сам.assertIn('nonlocal значение', итог)
        сам.assertIn('value = 2', итог)


if __name__ == '__main__':
    unittest.main()
