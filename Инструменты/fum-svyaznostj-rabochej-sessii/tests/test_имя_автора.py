"""Чистый контракт имени без догадок о неизвестной модели."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from автор_коммита import составить_имя, проверить_формат


class ИмяАвтора(unittest.TestCase):
    def test_точная_роль_из_имени_инструмента(сам):
        имя = составить_имя("FUM Codex", {"модель": "gpt-6-sol", "усилие": "ultra"})
        сам.assertEqual("FUM Codex [gpt-6-sol; effort=ultra]", имя)
        сам.assertTrue(проверить_формат(имя))
        сам.assertTrue(проверить_формат("FUM Codex"))

    def test_произвольная_латинская_роль_и_искажённое_имя_инструмента_отклоняются(сам):
        for роль in ("FUM Agent", "FUM codex", "FUM CODEX", "FUM Codex Writer", "FUM  Codex", "FUM Codex\n"):
            with сам.subTest(роль=роль):
                сам.assertFalse(проверить_формат(роль))
                with сам.assertRaises(ValueError):
                    составить_имя(роль, {"модель": "gpt-6-sol", "усилие": "ultra"})

    def test_модель_и_усилие_сохраняются_буквально(сам):
        for модель, усилие in (("gpt-6-astra", "max"), ("gpt-5.6-luna", "high"), ("model_1.2", "none")):
            with сам.subTest(модель=модель, усилие=усилие):
                имя = составить_имя("FUM Писатель", {"модель": модель, "усилие": усилие})
                сам.assertEqual(f"FUM Писатель [{модель}; effort={усилие}]", имя)
                сам.assertTrue(проверить_формат(имя))

    def test_неполные_неизвестные_и_опасные_данные_отклоняются(сам):
        for ключ in ("модель", "усилие"):
            for значение in (None, "", "unknown", "Unknown", "unavailable", "null", "unset", " x", "x ", "x\n", "x;y", "x]", "<x>", "x=y", "x/1", "a" * 129, 1):
                with сам.subTest(ключ=ключ, значение=значение):
                    данные = {"модель": "gpt-6-astra", "усилие": "max", ключ: значение}
                    with сам.assertRaises(ValueError):
                        составить_имя("FUM Писатель", данные)
            with сам.assertRaises(ValueError):
                составить_имя("FUM Писатель", {})

    def test_роль_не_подменяется_готовым_именем(сам):
        for роль in (None, "FUM  Писатель", "FUM писатель", "FUM Писатель [gpt-6-astra; effort=max]"):
            with сам.assertRaises(ValueError):
                составить_имя(роль, {"модель": "gpt-6-astra", "усилие": "max"})

    def test_историческое_имя_читается_без_выдуманного_суффикса(сам):
        сам.assertTrue(проверить_формат("FUM Интегратор"))
        сам.assertFalse(проверить_формат(None))
