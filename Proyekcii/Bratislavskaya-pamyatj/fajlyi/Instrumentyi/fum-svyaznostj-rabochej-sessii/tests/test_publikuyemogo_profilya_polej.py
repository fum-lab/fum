"""Публикуемый профиль сохраняет измерения и скрывает временный корень."""

import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from публикуемый_профиль_полей import представить_профиль


class ПроверкиПубликуемогоПрофиля(unittest.TestCase):
    def test_замена_корня_сохраняет_числа_оригинал_и_происхождение(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог).resolve()
            данные = {"результаты": [{"ошибки": ["Отсутствует: " + str(корень / "Журнал/пример")],
                                    "замеры": [101, 205, 99], "вход_sha256": "a" * 64}]}
            сырой = json.dumps(данные, ensure_ascii=False, indent=2) + "\n"
            результат = представить_профиль(данные, корень)
            сам.assertNotIn(str(корень), json.dumps(результат, ensure_ascii=False))
            сам.assertEqual(результат["результаты"][0]["замеры"], [101, 205, 99])
            сам.assertEqual(результат["результаты"][0]["вход_sha256"], "a" * 64)
            сам.assertEqual(json.dumps(данные, ensure_ascii=False, indent=2) + "\n", сырой)
            сам.assertEqual(результат["публикационное_представление"]["исходный_sha256"],
                            hashlib.sha256(сырой.encode()).hexdigest())
            сам.assertEqual(результат["публикационное_представление"]["замен"], 1)
            сам.assertEqual(результат["результаты"][0]["ошибки"], ["Отсутствует: <корень-фикстуры>/Журнал/пример"])
