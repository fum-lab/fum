#!/usr/bin/env python3
"""Независимая адресная проверка JSON Schema; jsonschema 4.23.0 нужен только ей."""
from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import sys
import unittest

from jsonschema import Draft202012Validator

sys.dont_write_bytecode = True
КАТАЛОГ = Path(__file__).resolve().parent
спецификация = importlib.util.spec_from_file_location('сборщик', КАТАЛОГ / 'сборщик.py')
сборщик = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(сборщик)


class ПроверкаКонтракта(unittest.TestCase):
    def test_форма_входа_и_выхода(сам):
        схема = json.loads((КАТАЛОГ / 'контракт.json').read_text())
        Draft202012Validator.check_schema(схема)
        проверка = Draft202012Validator(схема)
        вход = json.loads((КАТАЛОГ / 'фикстуры/снимок.json').read_text())
        проверка.validate(вход)
        for бюджет in (0, 1, 4096, 100000):
            вход['бюджет_байт'] = бюджет
            проверка.validate(сборщик.собрать(сборщик.байты(вход)))

    def test_противоречивый_паспорт_источника_не_принят(сам):
        схема = json.loads((КАТАЛОГ / 'контракт.json').read_text())
        проверка = Draft202012Validator(схема)
        исходный = json.loads((КАТАЛОГ / 'фикстуры/снимок.json').read_text())
        # Ожидания заданы отдельно от исполняемой проверки и текста схемы.
        случаи = [
            {'данные': None, 'доступность': 'доступен', 'полнота': False, 'байты': None, 'хэш': None},
            {'данные': None, 'доступность': 'недоступен', 'полнота': True, 'байты': None, 'хэш': None},
            {'версия': None},
            {'контракт': 'неподдержанный-формат.99'},
            {'байты': None},
            {'хэш': None},
        ]
        for номер, изменения in enumerate(случаи, 1):
            with сам.subTest(паспорт=номер):
                вход = deepcopy(исходный)
                вход['источники'][0].update(изменения)
                сам.assertFalse(проверка.is_valid(вход))
                with сам.assertRaises(ValueError):
                    сборщик.собрать(сборщик.байты(вход))


if __name__ == '__main__':
    unittest.main()
