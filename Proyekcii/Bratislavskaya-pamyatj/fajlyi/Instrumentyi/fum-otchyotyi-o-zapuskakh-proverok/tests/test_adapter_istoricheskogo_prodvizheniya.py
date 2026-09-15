"""Проверить конечные ссылки before без подмены исторических globals."""
import importlib.util
import inspect
from pathlib import Path
import sys
import unittest

корень = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))


class ПроверкаАдаптераИстории(unittest.TestCase):
    def test_ссылки_сохраняют_функции_и_позиционный_контракт(сам):
        from адаптер_исторического_продвижения import создать_адаптер_истории
        путь = корень / 'Журнал/2026-09-10_20-23-26_MSK_проверить-слияние-после-допуска/материалы/продвижение-до-оптимизации.py'
        спецификация = importlib.util.spec_from_file_location('история_продвижения_для_проверки', путь)
        история = importlib.util.module_from_spec(спецификация)
        спецификация.loader.exec_module(история)
        адаптер = создать_адаптер_истории(история)
        сам.assertIs(адаптер.выполнить_гит, история.git)
        сам.assertIs(адаптер.идентификатор_объекта, история.oid)
        сам.assertIs(адаптер.команда_гита, история.команда_git)
        сам.assertIs(адаптер.перейти, история.перейти)
        сам.assertIs(адаптер.среда, история.среда)
        сам.assertIs(адаптер.Отказ, история.Отказ)
        сам.assertIs(адаптер.subprocess, история.subprocess)
        сам.assertIs(адаптер.перейти.__globals__, история.__dict__)
        inspect.signature(адаптер.перейти).bind(*range(6), наблюдатель=lambda фаза: None)
        сам.assertEqual(адаптер.команда_гита(), история.команда_git())
        история.__file__ = __file__
        with сам.assertRaises(ValueError):
            создать_адаптер_истории(история)


if __name__ == '__main__':
    unittest.main()
