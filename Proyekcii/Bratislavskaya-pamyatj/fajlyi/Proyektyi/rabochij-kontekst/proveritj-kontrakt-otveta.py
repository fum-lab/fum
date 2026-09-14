"""Проверить схемы эталонного ответа отдельным jsonschema 4.23.0."""
import json
from pathlib import Path
import sys
import unittest

from jsonschema import Draft202012Validator

КОРЕНЬ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(КОРЕНЬ / "Инструменты/fum-svyaznostj-rabochej-sessii/tests"))
import test_компактный_ответ_задачи as эталон


class ПроверкаСхемОтвета(unittest.TestCase):
    def test_эталон_и_пустая_страница(проверка):
        каталог = Path(__file__).resolve().parent / "контракты"
        схемы = [json.loads((каталог / имя).read_text()) for имя in ("схема-входа-ответа.json", "схема-выхода-ответа.json")]
        for схема in схемы: Draft202012Validator.check_schema(схема)
        вход, выход = map(Draft202012Validator, схемы)
        for пусто in (False, True):
            значение = эталон.снимок_ответа()
            if пусто: значение["turns"] = []
            вход.validate(значение)
            результат = эталон.ПроверкаОтветаЗадачи().показать(значение)
            выход.validate(результат)
            результат["полный_снимок"]["путь"] = "/".join(("", "приватный", "снимок.json"))
            выход.validate(результат)
        значение["thread"]["status"]["новое"] = "неизвестное поле"
        проверка.assertFalse(вход.is_valid(значение))


if __name__ == "__main__":
    unittest.main()
