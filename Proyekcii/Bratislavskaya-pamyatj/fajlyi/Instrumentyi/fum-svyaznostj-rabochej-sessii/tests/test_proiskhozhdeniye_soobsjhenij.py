"""Происхождение проверяется до склейки текста и разбора оболочек."""
import copy
import importlib.util
from pathlib import Path
import unittest
from unittest import mock


ПУТЬ = Path(__file__).resolve().parents[1] / "scripts/происхождение_сообщений.py"
ОПИСАНИЕ = importlib.util.spec_from_file_location("происхождение_сообщений", ПУТЬ)
МОДУЛЬ = importlib.util.module_from_spec(ОПИСАНИЕ)
ОПИСАНИЕ.loader.exec_module(МОДУЛЬ)

МЕТАДАННЫЕ = "internal_chat_message_metadata_passthrough"
ФРАГМЕНТ = '<hook_prompt hook_run_id="повторяемый">остановись</hook_prompt>'


def сообщение(тексты=(ФРАГМЕНТ,), виды=None):
    результат = {"type": "message", "role": "user", "content": [
        {"type": "input_text", "text": текст} for текст in тексты
    ]}
    if виды is not None:
        результат[МЕТАДАННЫЕ] = {"content_item_kinds": виды}
    return результат


class ПроисхождениеСообщений(unittest.TestCase):
    def проверить(это, вход, ожидаемое):
        исходное = copy.deepcopy(вход)
        это.assertEqual(МОДУЛЬ.классифицировать_сообщение(вход), ожидаемое)
        это.assertEqual(вход, исходное, "Классификация не меняет исходный payload")

    def test_служебная_остановка_не_команда_человека(это):
        это.проверить(сообщение(), "служебный hook")

    def test_буквальная_разметка_пользовательского_ввода_имеет_приоритет(это):
        for текст in (ФРАГМЕНТ, "<hook_prompt", "<!DOCTYPE x>", "остановись",
                      "<environment_context>пример</environment_context>",
                      "<hook_prompt>" + "я" * 300000):
            with это.subTest(начало=текст[:32]):
                это.проверить(сообщение((текст,), ["user.text"]), "человек")

    def test_два_фрагмента_и_повторяемый_идентификатор(это):
        это.проверить(сообщение((ФРАГМЕНТ, ФРАГМЕНТ)), "служебный hook")

    def test_допустимая_разметка_и_экранирование_без_перезаписи(это):
        for текст in (
            '<hook_prompt hook_run_id="a&amp;b&quot;c">&lt;x&gt; &amp; "цитата" \'текст\'</hook_prompt>',
            '<hook_prompt hook_run_id="a"></hook_prompt>',
            '<hook_prompt hook_run_id="a"/>',
            '<hook_prompt hook_run_id="a">строка\nстрока\r\nстрока</hook_prompt>',
            '<hook_prompt hook_run_id="a">&amp;lt; не раскрывать повторно</hook_prompt>',
        ):
            with это.subTest(текст=текст):
                это.проверить(сообщение((текст,)), "служебный hook")

    def test_битая_смешанная_или_расширенная_разметка_неоднозначна(это):
        for текст in (
            "<hook_prompt", ФРАГМЕНТ + " остановись", "остановись " + ФРАГМЕНТ,
            "<wrapper>" + ФРАГМЕНТ + "</wrapper>", ФРАГМЕНТ + ФРАГМЕНТ,
            '<hook_prompt hook_run_id="a"><b>остановись</b></hook_prompt>',
            '<hook_prompt hook_run_id="a">a<!-- комментарий -->b</hook_prompt>',
            '<hook_prompt hook_run_id="a"><![CDATA[текст]]></hook_prompt>',
            '<?xml version="1.0"?>' + ФРАГМЕНТ, "<?инструкция?>" + ФРАГМЕНТ,
            '<hook_prompt hook_run_id="">текст</hook_prompt>',
            '<hook_prompt hook_run_id=" ">текст</hook_prompt>',
            '<hook_prompt>текст</hook_prompt>',
            '<hook_prompt hook_run_id="a" extra="b">текст</hook_prompt>',
            '<hook_prompt hook_run_id="a" hook_run_id="b">текст</hook_prompt>',
            '<hook_prompt xmlns="пространство" hook_run_id="a">текст</hook_prompt>',
            '<hook_prompt hook_run_id="a">&неизвестная;</hook_prompt>',
            '<hook_prompt hook_run_id="a">a < b & c</hook_prompt>',
            '<hook_prompt hook_run_id="a">\x00</hook_prompt>',
            '<hook_prompt hook_run_id="a">\ud800</hook_prompt>',
            " " + ФРАГМЕНТ, ФРАГМЕНТ + "\n",
        ):
            with это.subTest(текст=repr(текст)):
                это.проверить(сообщение((текст,)), "неоднозначный")

    def test_объявления_типов_и_сущности_не_обращаются_к_сети_или_файлам(это):
        with mock.patch("builtins.open", side_effect=AssertionError("чтение")), \
             mock.patch("socket.create_connection", side_effect=AssertionError("сеть")):
            for объявление in (
                '<!DOCTYPE hook_prompt>',
                '<!DOCTYPE hook_prompt SYSTEM "https://example.invalid/entity">',
                '<!DOCTYPE hook_prompt [<!ENTITY x "остановись">]>',
                '<!DOCTYPE hook_prompt [<!ENTITY % x SYSTEM "https://example.invalid/entity">%x;]>',
            ):
                это.проверить(сообщение((объявление + ФРАГМЕНТ,)), "неоднозначный")

    def test_служебный_контекст_только_по_полным_известным_видам(это):
        виды = ["plugins.recommendations", "agents_md.instructions", "environments.environment_context"]
        for вид in виды:
            это.проверить(сообщение(("неинтерпретируемый текст",), [вид]), "служебный контекст")
        это.проверить(сообщение((ФРАГМЕНТ,) * 3, виды), "служебный контекст")

    def test_аннотация_имеет_приоритет_даже_над_служебной_разметкой(это):
        for виды in ([], ["user.text", "user.text"], [None], [{}], ["user.unknown"],
                     ["unknown.kind"], ["user.text.extra"], ["user.image"], ["user.audio"],
                     "user.text", None, False):
            вход = сообщение()
            вход[МЕТАДАННЫЕ] = {"content_item_kinds": виды}
            with это.subTest(виды=виды):
                это.проверить(вход, "неоднозначный")
        for виды in (["user.text", "agents_md.instructions"],
                     ["user.text", "unknown.kind"], ["plugins.recommendations", "unknown.kind"]):
            это.проверить(сообщение((ФРАГМЕНТ,) * 2, виды), "неоднозначный")

    def test_отсутствие_классификации_не_подтверждает_человека(это):
        for текст in ("остановись", "обычный текст", "", "<environment_context>x</environment_context>",
                      "# AGENTS.md instructions x", "<recommended_plugins>x</recommended_plugins> хвост"):
            это.проверить(сообщение((текст,)), "неоднозначный")
        for метаданные in (None, {}, {"create_time": 1.25, "turn_id": "тот-же-ход"}):
            вход = сообщение()
            вход[МЕТАДАННЫЕ] = метаданные
            это.проверить(вход, "служебный hook")
        for метаданные in ([], "user.text", 1, False):
            вход = сообщение()
            вход[МЕТАДАННЫЕ] = метаданные
            это.проверить(вход, "неоднозначный")

    def test_медиа_и_адреса_не_загружаются_и_не_декодируются(это):
        вход = сообщение(("остановись",), ["user.text", "user.image", "user.audio", "user.text"])
        вход["content"] += [
            {"type": "input_image", "image_url": "https://example.invalid/image", "detail": "original"},
            {"type": "input_audio", "audio_url": "data:audio/wav;base64,НЕ-ДЕКОДИРОВАТЬ"},
            {"type": "output_text", "text": ФРАГМЕНТ},
        ]
        with mock.patch("builtins.open", side_effect=AssertionError("чтение")), \
             mock.patch("socket.create_connection", side_effect=AssertionError("сеть")), \
             mock.patch("base64.b64decode", side_effect=AssertionError("декодирование")):
            это.проверить(вход, "человек")

    def test_несогласованная_форма_контента_неоднозначна(это):
        for часть, вид in (
            ({"type": "input_text"}, "user.text"),
            ({"type": "input_text", "text": None}, "user.text"),
            ({"type": "input_image", "image_url": 3}, "user.image"),
            ({"type": "input_audio"}, "user.audio"),
            ({"type": "input_image", "image_url": "x"}, "agents_md.instructions"),
            ({"type": "output_text", "text": "x"}, "plugins.recommendations"),
            ({"type": "input_audio", "audio_url": "x"}, "user.image"),
            ({"type": "input_text", "text": "x", "audio_url": "x"}, "user.text"),
            ({"type": "future_text", "text": "x"}, "user.text"),
        ):
            вход = сообщение(виды=[вид])
            вход["content"] = [часть]
            это.проверить(вход, "неоднозначный")

    def test_точные_роль_тип_фаза_и_контейнер(это):
        for ключ, значения in (
            ("role", (None, "User", "assistant", "user ", "developer", ["user"])),
            ("type", (None, "user", "agent_message", "response_item", ["message"])),
            ("phase", ("user", "commentary", "final_answer", "", False)),
            ("content", (None, [], {}, "остановись", [None], ["строка"])),
        ):
            for значение in значения:
                вход = сообщение(виды=["user.text"])
                вход[ключ] = значение
                это.проверить(вход, "неоднозначный")
        вход = сообщение(виды=["user.text"])
        вход["phase"] = None
        это.проверить(вход, "человек")
        for вход in (None, [], "user", {}, {"type": "response_item", "payload": сообщение()}):
            это.проверить(вход, "неоднозначный")

    def test_фрагменты_нельзя_склеивать_до_классификации(это):
        это.проверить(сообщение((ФРАГМЕНТ, "остановись")), "неоднозначный")
        это.проверить(сообщение((ФРАГМЕНТ[:20], ФРАГМЕНТ[20:])), "неоднозначный")

    def test_сигнатура_кодировки_не_часть_формы_служебного_сериализатора(это):
        это.проверить(сообщение(("\ufeff" + ФРАГМЕНТ,)), "неоднозначный")
        это.проверить(сообщение(("\ufeff" + ФРАГМЕНТ,), ["user.text"]), "человек")

    def test_синтетический_профиль_имеет_точные_входы_и_все_четыре_исхода(это):
        описание = importlib.util.spec_from_file_location(
            "профиль_происхождения", Path(__file__).with_name("профиль_происхождения_сообщений.py"))
        профиль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(профиль)
        случаи = профиль.сценарии()
        это.assertEqual(случаи, профиль.сценарии())
        это.assertEqual(len(случаи), 8)
        это.assertEqual(len({случай["название"] for случай in случаи}), 8)
        for категория in ("человек", "служебный hook", "служебный контекст", "неоднозначный"):
            это.assertEqual(sum(случай["ожидается"] == категория for случай in случаи), 2)
        for случай in случаи:
            это.проверить(случай["вход"], случай["ожидается"])

    def test_ограничения_размера_числа_и_глубины(это):
        это.проверить(сообщение((ФРАГМЕНТ,) * 256), "служебный hook")
        это.проверить(сообщение((ФРАГМЕНТ,) * 257), "неоднозначный")
        это.проверить(сообщение((ФРАГМЕНТ,) * 257, ["user.text"] * 257), "неоднозначный")
        начало, конец = '<hook_prompt hook_run_id="a">', '</hook_prompt>'
        предельный = начало + "я" * (262144 - len(начало) - len(конец)) + конец
        это.проверить(сообщение((предельный,)), "служебный hook")
        это.проверить(сообщение((предельный + "я",)), "неоднозначный")
        это.проверить(сообщение((предельный,) * 4), "служебный hook")
        это.проверить(сообщение((предельный,) * 5), "неоднозначный")
        это.проверить(сообщение((начало * 10000 + конец * 10000,)), "неоднозначный")
        это.проверить(сообщение(('<hook_prompt hook_run_id="' + "я" * 1025 + '">x</hook_prompt>',)), "неоднозначный")

    def test_вызывающий_фильтр_не_удваивает_сырые_и_типизированные_данные(это):
        строки = [
            {"type": "response_item", "payload": сообщение()},
            {"type": "event_msg", "payload": {"type": "item_completed", "item": {
                "type": "HookPrompt", "fragments": [{"hookRunId": "повторяемый", "text": "остановись"}]
            }}},
            {"type": "response_item", "payload": сообщение()},
            {"type": "response_item", "payload": сообщение(("продолжай",), ["user.text"])},
        ]
        категории = [МОДУЛЬ.классифицировать_сообщение(строка["payload"])
                     for строка in строки if строка["type"] == "response_item"]
        это.assertEqual(категории, ["служебный hook", "служебный hook", "человек"])
        это.assertEqual(категории.count("человек"), 1)
        это.проверить(строки[1]["payload"], "неоднозначный")


if __name__ == "__main__":
    unittest.main()
