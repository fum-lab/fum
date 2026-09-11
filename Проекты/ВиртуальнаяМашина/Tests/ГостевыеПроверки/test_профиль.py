"""Закреплённый профиль отклоняет неполные результаты дочерних процессов."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ресурсы = Path(__file__).resolve().parents[2] / 'Sources/ЯдроМашины/Ресурсы'
спецификация = importlib.util.spec_from_file_location('проверка_профиля_гостя', ресурсы / 'готовность.py')
модуль = importlib.util.module_from_spec(спецификация); спецификация.loader.exec_module(модуль)


class ПроверкиПрофиля(unittest.TestCase):
    def испытать(сам, изменить=None):
        вызовы = []
        def выполнить(имя, аргументы, **настройки):
            вызовы.append((имя, аргументы, настройки))
            if len(вызовы) <= 4:
                число = [8, 4, 25, 21][len(вызовы)-1]
                счётчики = {'выполнено': число, 'ошибки': 0, 'отказы': 0, 'пропущено': 0,
                            'ожидаемые_ошибки': 0, 'неожиданные_успехи': 0}
                if изменить is not None: изменить(счётчики)
                return json.dumps(счётчики).encode()
            return b'OK\n'
        результат = модуль.проверить_профиль(Path('/открытая-фикстура'), 'Открытый ресурс счётчика', выполнить)
        return результат, вызовы

    def test_профиль_охватывает_четыре_набора_и_два_валидатора(сам):
        результат, вызовы = сам.испытать()
        сам.assertEqual(len(вызовы), 6)
        сам.assertEqual(результат['тесты'], 58)
        сам.assertEqual(результат['проверки_индексов'], 2)
        клон = Path('/открытая-фикстура')
        имена = ['fum-proyektnyiye-fajlyi', 'fum-moskovskoye-vremya-rabochej-sessii',
                 'fum-indeks-readme', 'fum-obratnyiye-ssyilki-voprosov']
        for (имя, аргументы, настройки), набор, число in zip(вызовы[:4], имена, [8, 4, 25, 21]):
            сам.assertEqual(имя, 'Набор ' + набор)
            сам.assertEqual(аргументы, ['/usr/bin/python3', '-B', '-s', '-', str(клон / 'Инструменты' / набор / 'tests'), str(число)])
            сам.assertEqual(настройки['вход'], 'Открытый ресурс счётчика'.encode())
        for (имя, аргументы, настройки), набор, файл in zip(вызовы[4:], имена[2:], ['check-readme-index.py', 'check-question-backlinks.py']):
            сам.assertEqual(имя, 'Индекс ' + набор)
            сам.assertEqual(аргументы, ['/usr/bin/python3', '-B', '-s', str(клон / 'Инструменты' / набор / 'scripts' / файл), '--repo-root', str(клон)])
            сам.assertNotIn('вход', настройки)
        for _, _, настройки in вызовы:
            сам.assertEqual(настройки['каталог'], клон)
            сам.assertEqual(настройки['предел'], 120)
            сам.assertEqual(настройки['среда']['PYTHONDONTWRITEBYTECODE'], '1')
            сам.assertEqual(настройки['среда']['GIT_NO_REPLACE_OBJECTS'], '1')

    def test_неполный_дочерний_набор_не_принимается(сам):
        with сам.assertRaises(ValueError): сам.испытать(lambda счётчики: счётчики.update({'выполнено': 0}))
        with сам.assertRaises(ValueError): сам.испытать(lambda счётчики: счётчики.update({'пропущено': 1}))


if __name__ == '__main__': unittest.main()
