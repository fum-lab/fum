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
            вызовы.append((имя, аргументы))
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

    def test_неполный_дочерний_набор_не_принимается(сам):
        with сам.assertRaises(ValueError): сам.испытать(lambda счётчики: счётчики.update({'выполнено': 0}))
        with сам.assertRaises(ValueError): сам.испытать(lambda счётчики: счётчики.update({'пропущено': 1}))


if __name__ == '__main__': unittest.main()
