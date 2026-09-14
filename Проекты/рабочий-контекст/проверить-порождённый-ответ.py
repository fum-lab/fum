"""Общая матрица профиля целые64-без-дробей; Python и при наличии явного CLI Swift."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

КАТАЛОГ = Path(__file__).resolve().parent
sys.path[:0] = [str(КАТАЛОГ / "общие/Python"), str(КАТАЛОГ / "порождённые"),
    str(КАТАЛОГ.parents[1] / "Инструменты/fum-svyaznostj-rabochej-sessii/scripts")]
from модели_ответа import представить_снимок
from компактный_ответ_задачи import представить_ответ

ЗАДАЧА = "00000000-0000-0000-0000-000000000165"


def вход(изменить=None):
    оболочка = json.loads((КАТАЛОГ / "фикстуры/нативный-ответ.json").read_bytes())
    снимок = json.loads(оболочка["content"][0]["text"])
    if изменить: изменить(снимок)
    оболочка["content"][0]["text"] = json.dumps(снимок, ensure_ascii=False, separators=(",", ":"))
    return (json.dumps(оболочка, ensure_ascii=False, separators=(",", ":")) + "\n").encode()


class ПроверкаПорождённогоОтвета(unittest.TestCase):
    def сверить(проверка, данные, отказ=False, бюджет=16000):
        хэш = hashlib.sha256(данные).hexdigest()
        if отказ:
            with проверка.assertRaises(ValueError): представить_снимок(данные, хэш, ЗАДАЧА, бюджет)
        else:
            результат = представить_снимок(данные, хэш, ЗАДАЧА, бюджет)
            проверка.assertLessEqual(len(результат), бюджет)
            проверка.assertEqual(json.loads(результат), представить_ответ(данные, хэш, ЗАДАЧА, максимум_байтов=бюджет))
        бинарник = os.environ.get("FUM_СВИФТ_ОТВЕТ")
        if бинарник:
            процесс = subprocess.run([бинарник, хэш, ЗАДАЧА, str(бюджет)], input=данные, capture_output=True)
            if отказ:
                проверка.assertEqual(процесс.returncode, 2, процесс.stderr)
                проверка.assertEqual(процесс.stdout, b"")
            else:
                проверка.assertEqual(процесс.returncode, 0, процесс.stderr)
                проверка.assertLessEqual(len(процесс.stdout), бюджет)
                проверка.assertEqual(json.loads(процесс.stdout), json.loads(результат))

    def test_эталон_и_значения_ошибки(проверка):
        for значение in (None, {}, [], "", 0, False, {"ключ": ["Ёж 🦔", True, 12]}):
            with проверка.subTest(ошибка=значение):
                проверка.сверить(вход(lambda снимок: снимок["turns"][0].update(error=значение)))

    def test_пустота_и_обязательные_null(проверка):
        проверка.сверить(вход(lambda снимок: снимок.update(turns=[])))
        проверка.сверить(вход(lambda снимок: снимок["page"].update(nextCursor="", hasMore=False)))
        for поле in ("error", "completedAt"):
            проверка.сверить(вход(lambda снимок: снимок["turns"][0].pop(поле)), отказ=True)
        проверка.сверить(вход(lambda снимок: снимок["page"].pop("nextCursor")), отказ=True)

    def test_границы_Int64_и_лексические_отказы(проверка):
        for число in (-(2**63), 2**63-1):
            проверка.сверить(вход(lambda снимок: снимок["turns"][0].update(error=число)))
        for число in (-(2**63)-1, 2**63):
            проверка.сверить(вход(lambda снимок: снимок["turns"][0].update(error=число)), отказ=True)
        проверка.сверить(вход(lambda снимок: снимок["turns"][0].update(startedAt=True)), отказ=True)
        for лексема in ("1.0", "1e0"):
            for поле in ("error", "startedAt"):
                оболочка = json.loads(вход(lambda снимок: снимок["turns"][0].update({поле: "ЧИСЛОВАЯ_ЛЕКСЕМА"})))
                оболочка["content"][0]["text"] = оболочка["content"][0]["text"].replace('"ЧИСЛОВАЯ_ЛЕКСЕМА"', лексема)
                проверка.сверить(json.dumps(оболочка, ensure_ascii=False).encode(), отказ=True)

    def test_пробельность_и_поздняя_валидация(проверка):
        for текст in ("\u0085\u001c", "\u200b", "е\u0308 🦔"):
            проверка.сверить(вход(lambda снимок: снимок["turns"][0]["items"][2].update(text=текст)))
        проверка.сверить(вход(lambda снимок: снимок["turns"][1]["items"][0].update(unknown="не терять")), отказ=True)
        проверка.сверить(вход(lambda снимок: снимок["turns"][1]["items"][0].update(phase="unknown")), отказ=True)

    def test_повторы_ключей_и_бюджет(проверка):
        данные = вход()
        проверка.сверить(данные, отказ=True, бюджет=100)
        оболочка = json.loads(данные)
        оболочка["content"][0]["text"] = оболочка["content"][0]["text"].replace('"schemaVersion":1', '"schemaVersion":1,"schemaVersion":1')
        проверка.сверить(json.dumps(оболочка, ensure_ascii=False).encode(), отказ=True)
        проверка.сверить(b'{"content":[],"content":[]}', отказ=True)

    def test_точный_SHA_бюджет_и_доступность_оригинала(проверка):
        import tempfile
        данные = вход()
        хэш = hashlib.sha256(данные).hexdigest()
        with tempfile.TemporaryDirectory(prefix="fum-artifact-") as каталог:
            путь = Path(каталог) / "полный.json"
            путь.write_bytes(данные)
            with проверка.assertRaises(ValueError): представить_снимок(данные, "0" * 64, ЗАДАЧА)
            результат = представить_снимок(данные, хэш, ЗАДАЧА)
            проверка.assertEqual(представить_снимок(данные, хэш, ЗАДАЧА, len(результат)), результат)
            with проверка.assertRaises(ValueError): представить_снимок(данные, хэш, ЗАДАЧА, len(результат) - 1)
            бинарник = os.environ.get("FUM_СВИФТ_ОТВЕТ")
            if бинарник:
                неверный = subprocess.run([бинарник, "0" * 64, ЗАДАЧА, "16000"], input=данные, capture_output=True)
                проверка.assertEqual((неверный.returncode, неверный.stdout), (2, b""))
                полный = subprocess.run([бинарник, хэш, ЗАДАЧА, "16000"], input=данные, capture_output=True)
                проверка.assertEqual(полный.returncode, 0)
                размер = len(полный.stdout)
                for бюджет, код in ((размер, 0), (размер - 1, 2)):
                    попытка = subprocess.run([бинарник, хэш, ЗАДАЧА, str(бюджет)], input=данные, capture_output=True)
                    проверка.assertEqual(попытка.returncode, код)
                    if код == 0: проверка.assertEqual(json.loads(попытка.stdout), json.loads(полный.stdout))
                    else: проверка.assertEqual(попытка.stdout, b"")
            проверка.assertEqual(hashlib.sha256(путь.read_bytes()).hexdigest(), хэш)

    def test_обход_всей_таблицы_пробелов(проверка):
        пробелы = list(range(9, 14)) + list(range(28, 33)) + [133, 160, 5760] + list(range(8192, 8203)) + [8232, 8233, 8239, 8287, 12288]
        for код in пробелы + [8203, 65279]:
            with проверка.subTest(скаляр=код):
                проверка.сверить(вход(lambda снимок: снимок["turns"][0]["items"][2].update(text=chr(код))))


if __name__ == "__main__":
    unittest.main()
