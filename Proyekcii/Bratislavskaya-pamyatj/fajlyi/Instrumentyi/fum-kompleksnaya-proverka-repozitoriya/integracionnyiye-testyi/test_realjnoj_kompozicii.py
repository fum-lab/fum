"""Настоящая SwiftPM-композиция: отдельный набор явного полного профиля."""
import importlib.util
from pathlib import Path
import unittest


путь_набора = Path(__file__).resolve().parents[1] / "tests/test_run_smoke_check.py"
спецификация = importlib.util.spec_from_file_location("исходный_набор_композиции", путь_набора)
исходный_набор = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(исходный_набор)


class ПроверкаРеальнойКомпозиции(unittest.TestCase):
    def test_реальная_локальная_композиция(сам):
        исходный_набор.RunSmokeCheckTests().проверить_реальную_локальную_композицию()
