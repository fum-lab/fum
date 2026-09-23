"""Первичные MCP-события отличаются от упоминаний инструмента в тексте."""
import hashlib
import importlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path[:0] = [str(Path(__file__).resolve().parents[1] / "scripts"),
               str(Path(__file__).resolve().parents[2] / "fum-reyestr-planirovaniya/scripts")]


class ПроверкаНативныхВызовов(unittest.TestCase):
    задача = "00000000-0000-4000-8000-000000000001"

    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.путь = Path(self.временный.name).resolve() / "источник.jsonl"
        self.модуль = importlib.import_module("нативные_вызовы")
        self.база = self.байты({"type": "session_meta", "payload": {"id": self.задача}})
        self.событие = {"type": "event_msg", "payload": {"type": "item_completed",
            "thread_id": self.задача, "turn_id": self.задача,
            "item": {"type": "McpToolCall", "id": "exec-первый", "server": "codex_app",
                     "tool": "create_thread", "arguments": {"prompt": "Точный текст <ё> &lt;"},
                     "status": "completed", "result": {"content": [], "isError": False}}}}

    def байты(self, значение):
        return (json.dumps(значение, ensure_ascii=False) + "\n").encode()

    def прочитать(self, записи=None, *, хвост=b"", изменение=None, **отбор):
        данные = self.база + b"".join(self.байты(з) for з in (записи if записи is not None else [self.событие])) + хвост
        self.путь.write_bytes(данные)
        вход = {"путь": str(self.путь), "начало": len(self.база),
                "начало_sha256": hashlib.sha256(self.база).hexdigest(),
                "граница": len(данные), "sha256": hashlib.sha256(данные).hexdigest()}
        if изменение:
            изменение(вход)
        до = self.путь.read_bytes()
        результат = self.модуль.прочитать(вход, self.задача, **отбор)
        self.assertEqual(до, self.путь.read_bytes())
        return результат

    def test_настоящий_вызов_сохраняет_аргументы_ответ_и_байтовое_происхождение(self):
        результат = self.прочитать()
        self.assertEqual(len(результат["вызовы"]), 1)
        вызов = результат["вызовы"][0]
        self.assertEqual(вызов["аргументы"], self.событие["payload"]["item"]["arguments"])
        self.assertEqual(вызов["ответ"], {"content": [], "isError": False})
        self.assertEqual(вызов["источник"]["начало"], len(self.база))
        self.assertFalse(результат["отсутствие_незаписанного_вызова_доказано"])

    def test_упоминание_в_тексте_и_ответе_другого_инструмента_не_считается_вызовом(self):
        текст = {"type": "response_item", "payload": {"type": "message", "role": "user",
                 "content": [{"type": "input_text", "text": json.dumps(self.событие)}]}}
        другая = json.loads(json.dumps(self.событие))
        другая["payload"]["item"].update(tool="read_thread", result=self.событие)
        self.assertEqual(self.прочитать([текст, другая])["вызовы"], [])

    def test_чужой_UUID_не_принимается(self):
        self.событие["payload"]["thread_id"] = "00000000-0000-4000-8000-000000000002"
        with self.assertRaisesRegex(ValueError, "UUID"):
            self.прочитать()

    def test_дубль_события_не_сворачивается(self):
        with self.assertRaisesRegex(ValueError, "Повтор"):
            self.прочитать([self.событие, self.событие])

    def test_неуспешный_исход_не_доказывает_отсутствие_эффекта(self):
        self.событие["payload"]["item"]["result"]["isError"] = True
        with self.assertRaisesRegex(ValueError, "исход"):
            self.прочитать()

    def test_незавершённый_вызов_не_теряется(self):
        self.событие["payload"]["type"] = "item_started"
        self.событие["payload"]["item"]["status"] = "in_progress"
        with self.assertRaisesRegex(ValueError, "Незавершён"):
            self.прочитать()

    def test_начало_и_завершение_одного_вызова(self):
        начало = json.loads(json.dumps(self.событие))
        начало["payload"]["type"] = "item_started"
        начало["payload"]["item"]["status"] = "in_progress"
        self.assertEqual(len(self.прочитать([начало, self.событие])["вызовы"]), 1)

    def test_подменённые_хэши_и_границы_отклоняются(self):
        for замена in ({"sha256": "f" * 64}, {"начало_sha256": "f" * 64},
                       {"начало": len(self.база) - 1}, {"граница": True}):
            with self.subTest(замена=замена), self.assertRaises(ValueError):
                self.прочитать(изменение=lambda в: в.update(замена))

    def test_оборванный_хвост_не_игнорируется(self):
        with self.assertRaisesRegex(ValueError, "завершён"):
            self.прочитать(хвост=b'{"type":')

    def test_источник_должен_начинаться_с_своего_session_meta(self):
        self.база = self.байты({"type": "session_meta", "payload": {"id": "другая задача"}})
        with self.assertRaisesRegex(ValueError, "UUID"):
            self.прочитать()

    def test_старый_отказ_другого_поручения_не_определяет_исход_нынешнего(self):
        старый = json.loads(json.dumps(self.событие))
        старый["payload"]["item"].update(id="старый", arguments={"prompt": "Другое"}, status="failed")
        старый["payload"]["item"]["result"]["isError"] = True
        ожидаемые = [self.событие["payload"]["item"]["arguments"]]
        self.assertEqual(len(self.прочитать([старый, self.событие], аргументы=ожидаемые)["вызовы"]), 1)

    def test_неуспешный_выбранный_вызов_не_пропускается_отбором(self):
        self.событие["payload"]["item"]["status"] = "failed"
        with self.assertRaisesRegex(ValueError, "исход"):
            self.прочитать(аргументы=[self.событие["payload"]["item"]["arguments"]])

    def test_изменённое_завершение_выбранного_начала_не_теряется(self):
        начало = json.loads(json.dumps(self.событие))
        начало["payload"]["type"] = "item_started"
        self.событие["payload"]["item"]["arguments"] = {"prompt": "Подмена"}
        with self.assertRaisesRegex(ValueError, "аргументы"):
            self.прочитать([начало, self.событие], аргументы=[начало["payload"]["item"]["arguments"]])

    def test_ожидание_заданной_задачи_имеет_отдельное_происхождение(self):
        self.событие["payload"]["item"].update(tool="wait_threads", arguments={"targets": [{"threadId": self.задача}]})
        результат = self.прочитать(ожидания=[self.задача])
        self.assertEqual(результат["вызовы"], [])
        self.assertEqual(len(результат["ожидания"]), 1)
        self.assertEqual(результат["ожидания"][0]["аргументы"], {"targets": [{"threadId": self.задача}]})

    def test_выбранное_завершение_не_может_скрыть_другое_начало(self):
        for инструмент in ("create_thread", "wait_threads"):
            with self.subTest(инструмент=инструмент):
                конец = json.loads(json.dumps(self.событие))
                конец["payload"]["item"].update(tool=инструмент)
                if инструмент == "wait_threads":
                    конец["payload"]["item"]["arguments"] = {"targets": [{"threadId": self.задача}]}
                начало = json.loads(json.dumps(конец))
                начало["payload"]["type"] = "item_started"
                начало["payload"]["item"]["arguments"] = {"targets": [{"threadId": "00000000-0000-4000-8000-000000000002"}]} if инструмент == "wait_threads" else {"prompt": "Чужое начало"}
                with self.assertRaisesRegex(ValueError, "аргументы"):
                    self.прочитать([начало, конец], аргументы=[конец["payload"]["item"]["arguments"]], ожидания=[self.задача])


if __name__ == "__main__":
    unittest.main()
