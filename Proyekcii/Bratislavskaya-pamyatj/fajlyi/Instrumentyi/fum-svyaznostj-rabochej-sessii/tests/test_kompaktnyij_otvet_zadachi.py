"""Открытые проверки среза ответа без исполнения содержимого."""
import subprocess
import tempfile
import hashlib
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from компактный_ответ_задачи import представить_ответ
from компактный_остаток import закодировать

ЗАДАЧА = "00000000-0000-0000-0000-000000000165"


def снимок_ответа():
    return {"schemaVersion": 1, "thread": {"id": ЗАДАЧА, "kind": "codex",
        "status": {"type": "active", "activeFlags": ["waitingForApproval"]},
        "title": "Открытая задача", "preview": "Не выдавать весь предварительный текст"},
        "page": {"order": "newest_first", "limit": 2, "nextCursor": "открытый-курсор", "hasMore": True},
        "turns": [{"id": "новый", "status": "inProgress", "error": {"message": "Открытая ошибка"},
            "startedAt": 200, "completedAt": None, "durationMs": None,
            "items": [{"type": "agentMessage", "id": "первый", "text": "Старый ответ", "phase": "final"},
                {"type": "commandExecution", "id": "команда", "command": "НЕ ВЫПОЛНЯТЬ", "output": "я" * 10000},
                {"type": "agentMessage", "id": "последний", "text": "Ёж 🦔\n[вложение](https://example.org/image.png)\n", "phase": "commentary"},
                {"type": "reasoning", "id": "рассуждение", "text": "Открытая нагрузка"},
                {"type": "agentMessage", "id": "пустой", "text": " \n", "phase": "commentary"}]},
            {"id": "старый", "status": "completed", "error": None, "startedAt": 100,
                "completedAt": 150, "durationMs": 50000,
                "items": [{"type": "agentMessage", "id": "прежний", "text": "Предыдущий ход", "phase": "final"}]}]}


def оболочка(значение):
    return {"content": [{"type": "text", "text": json.dumps(значение, ensure_ascii=False)}], "isError": False}


def открыть_указатель(значение, указатель):
    for часть in указатель.split("/")[1:]:
        значение = значение[int(часть)] if isinstance(значение, list) else значение[часть]
    return значение


class ПроверкаОтветаЗадачи(unittest.TestCase):
    def показать(проверка, значение=None, **параметры):
        данные = закодировать(оболочка(снимок_ответа() if значение is None else значение))
        return представить_ответ(данные, hashlib.sha256(данные).hexdigest(), ЗАДАЧА, **параметры)

    def test_последний_ответ_состояние_и_ошибка_сохраняются(проверка):
        вход = снимок_ответа()
        результат = проверка.показать(вход)
        проверка.assertEqual(результат["задача"], {ключ: вход["thread"][ключ] for ключ in ("id", "kind", "status")})
        проверка.assertEqual(результат["ответ"]["оригинал"], вход["turns"][0]["items"][2])
        проверка.assertEqual(результат["текущий_ход"]["error"], вход["turns"][0]["error"])
        проверка.assertEqual(результат["элементов_всего"], 6)
        проверка.assertEqual(результат["элементов_опущено"], 5)
        проверка.assertEqual(sum(результат["опущено_по_типам"].values()), 5)
        проверка.assertNotIn("reasoning", json.dumps(результат["ответ"]))

    def test_цепочка_указателей_проходит_через_строку_джейсон(проверка):
        вход = снимок_ответа(); результат = проверка.показать(вход)
        ссылка = результат["ответ"]["адрес"]
        внутренний = json.loads(открыть_указатель(оболочка(вход), ссылка["внешний_указатель"]))
        проверка.assertEqual(ссылка["декодирование"], "JSON")
        проверка.assertEqual(открыть_указатель(внутренний, ссылка["внутренний_указатель"]), результат["ответ"]["оригинал"])

    def test_пустой_новый_ход_не_делает_старый_ответ_свежим(проверка):
        вход = снимок_ответа(); вход["turns"][0]["items"] = []
        результат = проверка.показать(вход)
        проверка.assertEqual(результат["ответ"]["ход"]["id"], "старый")
        проверка.assertFalse(результат["ответ_из_первого_хода"])
        проверка.assertFalse(результат["живой_источник_перепроверен"])
        проверка.assertFalse(результат["завершение_задачи_доказано"])
        проверка.assertEqual(результат["полнота_истории"], "не доказана")

    def test_пустота_и_конец_страницы_не_означают_завершение(проверка):
        вход = снимок_ответа(); вход["turns"] = []
        вход["page"].update({"hasMore": False, "nextCursor": None})
        результат = проверка.показать(вход)
        проверка.assertIsNone(результат["ответ"])
        проверка.assertIsNone(результат["текущий_ход"])
        проверка.assertTrue(результат["причина_отсутствия_ответа"])
        проверка.assertFalse(результат["завершение_задачи_доказано"])
        проверка.assertEqual(результат["полнота_истории"], "не доказана")

    def test_бюджет_точно_по_байтам_без_усечения(проверка):
        ожидаемый = проверка.показать(); размер = len(закодировать(ожидаемый))
        проверка.assertEqual(проверка.показать(максимум_байтов=размер), ожидаемый)
        with проверка.assertRaisesRegex(ValueError, "бюджет"):
            проверка.показать(максимум_байтов=размер-1)

    def test_неизвестная_форма_идентичность_и_усечение_отклоняются(проверка):
        for изменение in ("схема", "задача", "порядок", "поле-ответа", "фаза", "поле-задачи", "усечение"):
            вход = снимок_ответа()
            if изменение == "схема": вход["schemaVersion"] = 2
            elif изменение == "задача": вход["thread"]["id"] = "чужая"
            elif изменение == "порядок": вход["page"]["order"] = "неизвестный"
            elif изменение == "поле-ответа": вход["turns"][0]["items"][2]["unknown"] = "не терять молча"
            elif изменение == "фаза": вход["turns"][0]["items"][2]["phase"] = "analysis"
            elif изменение == "поле-задачи": вход["thread"]["unknown"] = "новая семантика"
            else: вход["truncated"] = True
            with проверка.subTest(изменение=изменение), проверка.assertRaises(ValueError): проверка.показать(вход)

    def test_полный_хэш_и_двойные_ключи_проверяются(проверка):
        данные = закодировать(оболочка(снимок_ответа()))
        with проверка.assertRaisesRegex(ValueError, "хэш"):
            представить_ответ(данные, "0"*64, ЗАДАЧА)
        повтор = данные.replace(b'"isError":false', b'"isError":true,"isError":false')
        with проверка.assertRaises(ValueError): представить_ответ(повтор, hashlib.sha256(повтор).hexdigest(), ЗАДАЧА)
        внешний = оболочка(снимок_ответа()); внешний["content"][0]["text"] = '{"schemaVersion":1,"schemaVersion":1}'
        данные = закодировать(внешний)
        with проверка.assertRaises(ValueError): представить_ответ(данные, hashlib.sha256(данные).hexdigest(), ЗАДАЧА)

    def test_повреждённая_вложенная_строка_не_разбирается_по_обрывкам(проверка):
        внешний = оболочка(снимок_ответа()); внешний["content"][0]["text"] = внешний["content"][0]["text"][:-20]
        данные = закодировать(внешний)
        with проверка.assertRaises(ValueError): представить_ответ(данные, hashlib.sha256(данные).hexdigest(), ЗАДАЧА)

    def test_ошибка_протокола_не_превращается_в_успешную_страницу(проверка):
        внешний = оболочка(снимок_ответа()); внешний["isError"] = True; данные = закодировать(внешний)
        with проверка.assertRaises(ValueError): представить_ответ(данные, hashlib.sha256(данные).hexdigest(), ЗАДАЧА)

    def test_типы_метаданных_не_теряются_при_кодировании(проверка):
        for изменение in ("время", "необязательная-строка", "флаги", "новое-состояние"):
            вход = снимок_ответа()
            if изменение == "время": вход["turns"][0]["startedAt"] = True
            elif изменение == "необязательная-строка": вход["thread"]["title"] = None
            elif изменение == "флаги": вход["thread"]["status"]["activeFlags"] = None
            else: вход["thread"]["status"]["unknown"] = "новые данные"
            with проверка.subTest(изменение=изменение), проверка.assertRaises(ValueError): проверка.показать(вход)

    def test_командная_строка_проверяет_снимок_и_не_выдаёт_частичный_ответ(проверка):
        with tempfile.TemporaryDirectory() as временный:
            путь = Path(временный) / "снимок.json"; данные = закодировать(оболочка(снимок_ответа())); путь.write_bytes(данные)
            команда = [sys.executable, "-B", str(Path(__file__).resolve().parents[1] / "scripts/показать-ответ-задачи.py"),
                "--снимок", str(путь), "--sha256", hashlib.sha256(данные).hexdigest(), "--задача", ЗАДАЧА]
            успех = subprocess.run(команда, capture_output=True)
            проверка.assertEqual(успех.returncode, 0, успех.stderr)
            проверка.assertEqual(json.loads(успех.stdout), проверка.показать())
            адресованный = subprocess.run(команда + ["--путь-в-результате"], capture_output=True)
            проверка.assertEqual(адресованный.returncode, 0, адресованный.stderr)
            проверка.assertEqual(json.loads(адресованный.stdout)["полный_снимок"]["путь"], str(путь))
            проверка.assertTrue(адресованный.stdout.endswith(b"\n"))
            размер = len(адресованный.stdout)
            for профиль in ("прежний", "порождённый"):
                for бюджет in (размер, размер - 1):
                    with проверка.subTest(профиль=профиль, бюджет=бюджет):
                        точный = subprocess.run(команда + ["--путь-в-результате", "--профиль", профиль,
                            "--максимум-байтов", str(бюджет)], capture_output=True)
                        проверка.assertEqual(точный.returncode, 0 if бюджет == размер else 2, точный.stderr)
                        проверка.assertEqual(точный.stdout, адресованный.stdout if бюджет == размер else b"")
            тесный = subprocess.run(команда + ["--путь-в-результате", "--максимум-байтов", str(len(успех.stdout))], capture_output=True)
            проверка.assertEqual(тесный.returncode, 2); проверка.assertEqual(тесный.stdout, b"")
            отказ = subprocess.run(команда + ["--максимум-байтов", "100"], capture_output=True)
            проверка.assertEqual(отказ.returncode, 2); проверка.assertEqual(отказ.stdout, b"")
            проверка.assertEqual(путь.read_bytes(), данные); проверка.assertEqual(list(Path(временный).iterdir()), [путь])

    def test_явный_профиль_сохраняет_совместимость_и_строгие_границы(проверка):
        варианты = []
        for поле in ("ошибка", "опущенный-элемент"):
            for значение in (-(2**63), 2**63 - 1, -(2**63) - 1, 2**63, 1.5):
                вход = снимок_ответа()
                if поле == "ошибка": вход["turns"][0]["error"] = значение
                else: вход["turns"][0]["items"][1]["output"] = значение
                причина = "Дробные" if type(значение) is float else "Int64" if not -(2**63) <= значение < 2**63 else None
                варианты.append((f"{поле}-{значение}", закодировать(оболочка(вход)), ЗАДАЧА, причина))
        for глубина in (64, 65):
            вход = снимок_ответа(); вложенное = None
            # Корень → turns → ход → items → элемент → output: пять уровней.
            for _ in range(глубина - 5): вложенное = [вложенное]
            вход["turns"][0]["items"][1]["output"] = вложенное
            варианты.append((f"глубина-{глубина}", закодировать(оболочка(вход)), ЗАДАЧА,
                "глубина" if глубина == 65 else None))
        вход = снимок_ответа(); вход["turns"][0]["error"] = {"é": 1, "e\u0301": 2}
        варианты.append(("совпадающие-ключи", закодировать(оболочка(вход)), ЗАДАЧА, "совпадающие ключи"))
        for задача in ("aaaaaaaa-0000-0000-0000-000000000165", "AAAAAAAA-0000-0000-0000-000000000165", "старая-задача"):
            вход = снимок_ответа(); вход["thread"]["id"] = задача
            варианты.append(("идентичность-" + задача, закодировать(оболочка(вход)), задача,
                None if задача.startswith("aaaaaaaa") else "UUID"))
        текст = закодировать(оболочка(снимок_ответа())).decode("utf8")
        for кодировка in ("utf-8-sig", "utf-16", "utf-32"):
            варианты.append((кодировка, текст.encode(кодировка), ЗАДАЧА,
                "UTF-8 BOM" if кодировка == "utf-8-sig" else "Повреждённый JSON"))
        with tempfile.TemporaryDirectory() as временный:
            путь = Path(временный) / "снимок.json"
            for имя, данные, задача, причина in варианты:
                with проверка.subTest(пример=имя):
                    путь.write_bytes(данные)
                    команда = [sys.executable, "-B", str(Path(__file__).resolve().parents[1] / "scripts/показать-ответ-задачи.py"),
                        "--снимок", str(путь), "--sha256", hashlib.sha256(данные).hexdigest(), "--задача", задача]
                    прежний = subprocess.run(команда, capture_output=True)
                    проверка.assertEqual(прежний.returncode, 0, прежний.stderr)
                    проверка.assertEqual(прежний.stdout,
                        закодировать(представить_ответ(данные, hashlib.sha256(данные).hexdigest(), задача)))
                    строгий = subprocess.run(команда + ["--профиль", "порождённый"], capture_output=True)
                    проверка.assertEqual(строгий.returncode, 2 if причина else 0, строгий.stderr)
                    if причина:
                        проверка.assertEqual(строгий.stdout, b"")
                        проверка.assertIn(причина, строгий.stderr.decode("utf8"))
                    else: проверка.assertEqual(строгий.stdout, прежний.stdout)
                    проверка.assertEqual(путь.read_bytes(), данные)
            проверка.assertEqual(list(Path(временный).iterdir()), [путь])
