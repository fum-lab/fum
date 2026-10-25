"""Служебный начальный контекст отличается от нового пользовательского ввода."""
import copy
import unittest

from фикстура_двух_до_записи import два_до_записи, обновить_источники, хранение, строка
import завершение_двух_до_записи as завершение


def контекст():
    return {'type': 'response_item', 'payload': {'type': 'message', 'role': 'user',
        'content': [{'type': 'input_text', 'text': '# AGENTS.md instructions'},
                    {'type': 'input_text', 'text': '<environment_context/>'}],
        'internal_chat_message_metadata_passthrough': {'content_item_kinds':
            ['agents_md.instructions', 'environments.environment_context']}}}


class ПроверкаНачальногоКонтекста(unittest.TestCase):
    def test_аннотированный_начальный_контекст_не_становится_командой(сам):
        with два_до_записи(сол=True) as (_, объект, _, вход, события, дети):
            for _, _, источник in дети.values():
                записи = [хранение.разобрать(с) for с in источник.read_bytes().splitlines()]
                записи.insert(1, контекст())
                источник.write_bytes(b''.join(строка(з) for з in записи))
            обновить_источники(вход, события)
            до = объект.хранилище.путь.read_bytes()
            сам.assertEqual(2, len(завершение.предпросмотр(объект, вход)['слои']))
            сам.assertEqual(до, объект.хранилище.путь.read_bytes())

    def test_неоднозначный_человеческий_поздний_и_повторный_контекст_отклоняются(сам):
        with два_до_записи() as (_, объект, _, вход, события, дети):
            источник = дети['события'][2]
            исходные = [хранение.разобрать(с) for с in источник.read_bytes().splitlines()]
            до = объект.хранилище.путь.read_bytes()
            for вид in ('без-аннотации', 'неполный', 'человек', 'фаза', 'поле', 'поздний', 'повтор'):
                with сам.subTest(вид=вид):
                    записи = copy.deepcopy(исходные); ввод = контекст(); данные = ввод['payload']
                    if вид == 'без-аннотации': del данные['internal_chat_message_metadata_passthrough']
                    elif вид == 'неполный': данные['internal_chat_message_metadata_passthrough']['content_item_kinds'].pop()
                    elif вид == 'человек': данные['internal_chat_message_metadata_passthrough']['content_item_kinds'] = ['user.text'] * 2
                    elif вид == 'фаза': данные['phase'] = 'final_answer'
                    elif вид == 'поле': данные['content'][0]['инструкция'] = 'Новая команда'
                    позиция = len(записи) - 1 if вид == 'поздний' else 1
                    записи[позиция:позиция] = [ввод, copy.deepcopy(ввод)] if вид == 'повтор' else [ввод]
                    источник.write_bytes(b''.join(строка(з) for з in записи)); обновить_источники(вход, события)
                    with сам.assertRaises(ValueError): завершение.предпросмотр(объект, вход)
                    сам.assertEqual(до, объект.хранилище.путь.read_bytes())


if __name__ == '__main__':
    unittest.main()
