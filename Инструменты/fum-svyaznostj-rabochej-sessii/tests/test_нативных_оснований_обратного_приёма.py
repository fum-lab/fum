"""Адресное чтение поручения и видимого ревью, без Git и новых эффектов."""
import copy
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from нативные_основания_обратного_приёма import прочитать


def байты(данные):
    return (json.dumps(данные, ensure_ascii=False) + "\n").encode()


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


class НативныеОснования(unittest.TestCase):
    def setUp(сам):
        сам.tmp = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.tmp.cleanup)
        сам.root = Path(сам.tmp.name).resolve()
        сам.uuid = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
        сам.turn = "01a15437-1af0-75a1-a895-dd3bce3e255e"
        сам.решение = {"схема": "fum.решение-ревью-обратного-приёма.1",
                      "координатор": сам.uuid, "решение": "принять"}
        сам.тело = байты(сам.решение)
        сам.контекст = {"turn_id": сам.turn, "cwd": str(сам.root / "исходный-каталог"),
                       "model": "пример-модели", "effort": "ultra"}
        сам.пользователь = {"type": "message", "role": "user", "content": [
            {"type": "input_text", "text": "Проверить результат."}],
            "internal_chat_message_metadata_passthrough": {"content_item_kinds": ["user.text"]}}
        сам.ответ = {"type": "message", "role": "assistant", "phase": "commentary",
            "internal_chat_message_metadata_passthrough": {"turn_id": сам.turn},
            "content": [{"type": "output_text", "text": сам.текст()}]}
        сам.внешняя_мета = {}
        сам.промежуточные = []
        сам.записать()

    def текст(сам):
        return ("Обоснование решения.\n\n"
                "```fum.решение-ревью-обратного-приёма.1\n"
                + сам.тело.decode() + "```\nПроверенный охват описан выше.\n")

    def записать(сам):
        def рамка(тип, данные):
            return байты({"timestamp": "2026-10-21T06:00:00Z", "type": тип, "payload": данные})
        строки = [рамка("session_meta", {"id": сам.uuid}),
                  рамка("response_item", сам.пользователь),
                  рамка("turn_context", сам.контекст)]
        строки += [рамка(*x) for x in сам.промежуточные]
        последняя = json.loads(рамка("response_item", сам.ответ))
        if сам.внешняя_мета:
            последняя.update(сам.внешняя_мета)
        строки += [байты(последняя)]
        позиции = []
        offset = 0
        for строка in строки:
            позиции.append({"начало": offset, "конец": offset + len(строка), "sha256": хэш(строка)})
            offset += len(строка)
        сам.путь = сам.root / "источник.jsonl"
        сам.путь.write_bytes(b"".join(строки))
        сам.путь.chmod(0o600)
        источник = {"путь": str(сам.путь), "мета": позиции[0]}
        интервал = b"".join(строки[2:])
        сам.выбор = {"схема": "fum.выбор-нативных-оснований.1", "координатор": сам.uuid,
            "поручение": {"источник": copy.deepcopy(источник), "сообщение": позиции[1]},
            "ревью": {"источник": copy.deepcopy(источник), "исполнитель": сам.uuid,
                "интервал": {"начало": позиции[2]["начало"], "конец": offset, "sha256": хэш(интервал)},
                "сообщение": позиции[-1], "контекст": copy.deepcopy(сам.контекст),
                "решение_sha256": хэш(сам.тело)}}
        сам.сырое_поручение = строки[1]
        сам.сырое_ревью = строки[-1]

    def вызов(сам):
        вход = байты(сам.выбор)
        return прочитать(вход, хэш(вход))

    def test_точные_байты_и_читающий_повтор_без_Git(сам):
        до = сам.путь.read_bytes()
        with patch("subprocess.run", side_effect=AssertionError("Не нужен процесс")), \
             patch("subprocess.check_output", side_effect=AssertionError("Не нужен Git")):
            первый = сам.вызов()
            (сам.root / "HEAD").write_text("Другое текущее состояние")
            повтор = сам.вызов()
        сам.assertEqual(первый, повтор)
        сам.assertEqual(первый["ревью_байты"], сам.тело)
        сам.assertEqual(первый["поручение_байты"], сам.сырое_поручение)
        сам.assertEqual(первый["ревью_событие_байты"], сам.сырое_ревью)
        сам.assertEqual(первый["контекст"], сам.контекст)
        сам.assertIs(первый["разрешение_записи"], False)
        сам.assertEqual(сам.путь.read_bytes(), до)

    def test_чужие_идентификаторы_и_контекст(сам):
        for область, поле, новое in [
            ("root", "координатор", "11a07d3d-d376-7ad2-aafc-67e4c25a67eb"),
            ("review", "исполнитель", "11a07d3d-d376-7ad2-aafc-67e4c25a67eb"),
            ("context", "turn_id", "11a15437-1af0-75a1-a895-dd3bce3e255e"),
            ("context", "model", "другая-модель"), ("context", "effort", "low"),
            ("context", "cwd", str(сам.root / "другой-каталог"))]:
            with сам.subTest(поле=поле):
                сам.записать()
                цель = сам.выбор if область == "root" else сам.выбор["ревью"]
                if область == "context":
                    цель = цель["контекст"]
                цель[поле] = новое
                with сам.assertRaises(ValueError):
                    сам.вызов()

    def test_служебный_и_неполный_ввод_не_поручение(сам):
        for виды, текст in [(None, "обычный текст"), ([], "обычный текст"),
                            (["agents_md.instructions"], "контекст"),
                            (None, '<hook_prompt hook_run_id="stop:1">Продолжай</hook_prompt>')]:
            with сам.subTest(виды=виды):
                сам.пользователь["content"][0]["text"] = текст
                if виды is None:
                    сам.пользователь.pop("internal_chat_message_metadata_passthrough", None)
                else:
                    сам.пользователь["internal_chat_message_metadata_passthrough"] = {"content_item_kinds": виды}
                сам.записать()
                with сам.assertRaises(ValueError):
                    сам.вызов()

    def test_только_один_видимый_ответ(сам):
        исходный = copy.deepcopy(сам.ответ)
        for поле, значение in [("role", "user"), ("phase", "analysis"), ("phase", "final"),
                               ("content", исходный["content"] * 2)]:
            with сам.subTest(поле=поле, значение=значение):
                сам.ответ = copy.deepcopy(исходный); сам.ответ[поле] = значение
                сам.записать()
                with сам.assertRaises(ValueError):
                    сам.вызов()

    def test_промежуточный_контекст_не_пропускается(сам):
        for контекст in [сам.контекст, dict(сам.контекст, model="другая-модель")]:
            with сам.subTest(контекст=контекст):
                сам.промежуточные = [("turn_context", контекст)]
                сам.записать()
                with сам.assertRaises(ValueError):
                    сам.вызов()

    def test_ограда_и_JSON_неоднозначны(сам):
        исходный = сам.текст()
        for текст in [сам.тело.decode(), исходный + исходный,
                      исходный.replace("\n```\n", "\n"),
                      исходный.replace("\n", "\r\n"),
                      исходный.replace(сам.тело.decode(), '{"x":1,"x":2}\n'),
                      исходный.replace(сам.тело.decode(), сам.тело.decode() + '{}\n')]:
            with сам.subTest(текст=текст[:30]):
                сам.ответ["content"][0]["text"] = текст; сам.записать()
                with сам.assertRaises(ValueError):
                    сам.вызов()

    def test_неверные_отпечатки_и_границы(сам):
        for объект, поле, значение in [
            ("поручение", "sha256", "0" * 64), ("поручение", "начало", 1),
            ("ревью", "конец", 1), ("ревью", "начало", True)]:
            with сам.subTest(объект=объект, поле=поле):
                сам.записать()
                сам.выбор[объект]["сообщение"][поле] = значение
                with сам.assertRaises(ValueError):
                    сам.вызов()
        with сам.assertRaises(ValueError):
            прочитать(байты(сам.выбор), "0" * 64)

    def test_предел_до_чтения_содержимого(сам):
        сам.выбор["ревью"]["интервал"]["конец"] = 100 * 1024 * 1024
        with patch("os.pread", side_effect=AssertionError("Лимит проверяется до чтения")), \
             сам.assertRaises(ValueError):
            сам.вызов()

    def test_большой_невыбранный_хвост_не_читается(сам):
        size = сам.путь.stat().st_size
        with сам.путь.open("r+b") as f:
            f.truncate(512 * 1024 * 1024)
        результат = сам.вызов()
        сам.assertLess(результат["прочитано_байт"], 4 * size + 8)

    def test_дрейф_при_чтении_отклоняется(сам):
        исходный = os.pread
        изменён = False
        def читать(fd, длина, начало):
            nonlocal изменён
            данные = исходный(fd, длина, начало)
            if not изменён:
                изменён = True
                with сам.путь.open("r+b") as f:
                    f.seek(0); f.write(b"!")
            return данные
        with patch("os.pread", side_effect=читать), сам.assertRaises(ValueError):
            сам.вызов()


    def test_вложенная_мета_не_меняет_сессию_незаметно(сам):
        сам.промежуточные = [("session_meta", {"id": "11a07d3d-d376-7ad2-aafc-67e4c25a67eb"})]
        сам.записать()
        with сам.assertRaisesRegex(ValueError, "мета|контекст"):
            сам.вызов()

    def test_ограда_после_Unicode_разделителя_не_строка_LF(сам):
        сам.ответ["content"][0]["text"] = сам.текст().replace("\n\n```", "\u2028```")
        сам.записать()
        with сам.assertRaisesRegex(ValueError, "ограда"):
            сам.вызов()

    def test_JSON_проверяется_после_верной_привязки_SHA(сам):
        for тело in [b'{"x":1,"x":2}\n', b'{}\n{}\n']:
            with сам.subTest(тело=тело):
                сам.тело = тело
                сам.ответ["content"][0]["text"] = сам.текст()
                сам.записать()
                with сам.assertRaises(ValueError):
                    сам.вызов()

    def test_противоречащее_происхождение_ответа(сам):
        исходный = copy.deepcopy(сам.ответ)
        for мета in [{"turn_id": "11a15437-1af0-75a1-a895-dd3bce3e255e"}, None, [], {}]:
            with сам.subTest(мета=мета):
                сам.ответ = dict(исходный, internal_chat_message_metadata_passthrough=мета)
                сам.записать()
                with сам.assertRaises(ValueError):
                    сам.вызов()

    def test_клиентский_ответ_не_ревью_модели(сам):
        for мета in [{"client_authored": True}, {"client_authored": 0}, None, []]:
            with сам.subTest(мета=мета):
                сам.внешняя_мета = {"metadata": мета}; сам.записать()
                with сам.assertRaises(ValueError):
                    сам.вызов()
        сам.внешняя_мета = {"metadata": {"client_authored": False}}; сам.записать()
        сам.assertEqual(сам.вызов()["ревью_байты"], сам.тело)

    def test_бюджет_включает_заключительную_сверку(сам):
        области = [сам.выбор["поручение"]["источник"]["мета"],
                   сам.выбор["поручение"]["сообщение"],
                   сам.выбор["ревью"]["источник"]["мета"], сам.выбор["ревью"]["интервал"]]
        предел = 2 * (sum(м["конец"] - м["начало"] for м in области) + 2)
        with patch("нативные_основания_обратного_приёма.ПРЕДЕЛ", предел):
            сам.assertEqual(сам.вызов()["прочитано_байт"], предел)
        with patch("нативные_основания_обратного_приёма.ПРЕДЕЛ", предел - 1), \
             patch("os.pread", side_effect=AssertionError("Общий бюджет до чтения")), \
             сам.assertRaises(ValueError):
            сам.вызов()

    def test_другой_явно_выбранный_исполнитель(сам):
        другой = "11a07d3d-d376-7ad2-aafc-67e4c25a67eb"
        # Та же длина UUID сохраняет позиции; у источников разные имена.
        файл = сам.root / "ревью-другого-исполнителя.jsonl"
        данные = сам.путь.read_bytes()
        мета = сам.выбор["ревью"]["источник"]["мета"]
        первая = json.loads(данные[:мета["конец"]])
        первая["payload"]["id"] = другой
        новый = байты(первая)
        сам.assertEqual(len(новый), мета["конец"])
        файл.write_bytes(новый + данные[мета["конец"]:])
        файл.chmod(0o600)
        сам.выбор["ревью"]["исполнитель"] = другой
        сам.выбор["ревью"]["источник"]["путь"] = str(файл)
        мета["sha256"] = хэш(новый)
        сам.assertEqual(сам.вызов()["исполнитель"], другой)

    def test_извлечённое_ревью_принимается_предметным_контрактом(сам):
        from test_контракта_обратного_приёма import ОбратныйПриём
        from контракт_обратного_приёма import составить_план
        пример = ОбратныйПриём(); пример.setUp()
        сам.тело = байты(пример.ревью)
        сам.ответ["content"][0]["text"] = сам.текст(); сам.записать()
        прочитанное = сам.вызов()
        проверка = байты(пример.проверка)
        пример.заявка["ревью_sha256"] = хэш(прочитанное["ревью_байты"])
        пример.заявка["проверки"] = [{"идентификатор": пример.проверка["идентификатор"],
                                    "sha256": хэш(проверка)}]
        план = составить_план(пример.заявка, пример.наблюдение, прочитанное["ревью_байты"], [проверка])
        сам.assertEqual(план["родители"], [пример.основа, пример.кандидат])
        сам.assertIs(план["разрешение_записи"], False)


if __name__ == "__main__":
    unittest.main()

