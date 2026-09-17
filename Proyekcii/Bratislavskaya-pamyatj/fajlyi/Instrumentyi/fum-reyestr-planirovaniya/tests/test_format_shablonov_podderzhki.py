"""Поставляемые шаблоны должны проходить реальную классификацию проекции."""
import json
from pathlib import Path
import sys
import unittest

КОРЕНЬ = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(КОРЕНЬ / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts"))
from братиславская_проекция_памяти import классифицировать_содержимое


class ПроверкаФорматаШаблоновПоддержки(unittest.TestCase):
    def test_шаблоны_сохраняются_проекцией_без_изменения_байтов(сам):
        политика = json.loads((КОРЕНЬ / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json").read_text())
        шаблоны = sorted((КОРЕНЬ / "Инструменты/fum-reyestr-planirovaniya/шаблоны").glob("*поддержки*"))
        сам.assertEqual(len(шаблоны), 3)
        for шаблон in шаблоны:
            with сам.subTest(шаблон=шаблон.name):
                _, действие, _ = классифицировать_содержимое(КОРЕНЬ, шаблон.relative_to(КОРЕНЬ).as_posix(), политика)
                сам.assertEqual(действие, "сохранить_байты")
