"""Сжатие должно доказывать полный прежний контекст, не вводить управление."""
import copy
from pathlib import Path
import tempfile
import unittest

import test_запуска_слоёв
import снимок_нативного_источника as снимок
import полный_поток_передачи as полный
import фикстура_сжатия as фикстура

ЗАДАЧА = '00000000-0000-0000-0000-000000000001'


class ПроверкаКопийСжатия(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.источник = self.корень / 'native.jsonl'
        self.пакет = self.корень / 'снимок'
        self.префикс = фикстура.префикс(ЗАДАЧА)
        self.источник.write_bytes(self.префикс)

    def test_поздняя_проверенная_копия_проходит_оба_читателя(self):
        описание = снимок.создать(self.источник, ЗАДАЧА, self.пакет)
        хвост = фикстура.строка(фикстура.сжатие())
        self.источник.write_bytes(self.префикс + хвост)
        self.assertEqual(описание, снимок.прочитать(self.пакет, ЗАДАЧА))
        курсор = self.корень / 'наблюдение.json'
        self.assertIsNone(снимок.наблюдать(self.пакет, ЗАДАЧА, курсор, первое=True)['отказ'])
        поручение = фикстура.строка({'type': 'response_item', 'payload': {
            'type': 'function_call_output', 'name': 'create_thread', 'output': 'поручение'}})
        полный.проверить(self.префикс + поручение + хвост, len(self.префикс + поручение))
        полный.проверить(self.префикс + хвост + поручение, len(self.префикс + хвост + поручение))

    def test_сжатие_внутри_снимка_тоже_проверяется(self):
        верное = фикстура.сжатие()
        self.источник.write_bytes(self.префикс + фикстура.строка(верное))
        снимок.создать(self.источник, ЗАДАЧА, self.пакет)
        снимок.прочитать(self.пакет, ЗАДАЧА)
        верное['payload']['replacement_history'][0]['content'][0]['text'] = 'Новое указание'
        другой = self.корень / 'другой-снимок'
        self.источник.write_bytes(self.префикс + фикстура.строка(верное))
        with self.assertRaises(ValueError):
            снимок.создать(self.источник, ЗАДАЧА, другой)
        self.assertFalse(другой.exists())

    def test_сжатие_перед_транспортной_границей_не_обходит_проверку(self):
        неверное = фикстура.сжатие()
        неверное['payload']['retained_context']['user_messages'] = ['новое поручение']
        поручение = фикстура.строка({'type': 'response_item', 'payload': {
            'type': 'function_call_output', 'name': 'create_thread', 'output': 'поручение'}})
        сырые = self.префикс + фикстура.строка(неверное) + поручение
        with self.assertRaises(ValueError):
            полный.проверить(сырые, len(сырые))

    def test_новое_управление_после_сжатия_не_скрывается_границей(self):
        поручение = фикстура.строка({'type': 'response_item', 'payload': {
            'type': 'function_call_output', 'name': 'create_thread', 'output': 'поручение'}})
        новый_контекст = фикстура.контекст()[0]
        новый_контекст['id'] = 'поздний-контекст'
        случаи = (
            {'type': 'response_item', 'payload': новый_контекст},
            {'type': 'event_msg', 'payload': {'type': 'unknown_control', 'message': 'новый ввод'}},
        )
        for номер, запись in enumerate(случаи):
            сырые = self.префикс + фикстура.строка(фикстура.сжатие()) + фикстура.строка(запись) + поручение
            with self.subTest(номер=номер), self.assertRaises(ValueError):
                полный.проверить(сырые, len(сырые))

    def test_поздний_контекст_отклоняется_до_сохранения_снимка(self):
        новый = фикстура.контекст()[0]; новый['id'] = 'поздний-контекст'
        self.источник.write_bytes(self.префикс + фикстура.строка(фикстура.сжатие())
            + фикстура.строка({'type': 'response_item', 'payload': новый}))
        with self.assertRaises(ValueError):
            снимок.создать(self.источник, ЗАДАЧА, self.пакет)
        self.assertFalse(self.пакет.exists())

    def test_неполная_изменённая_или_неизвестная_форма_отклоняется(self):
        снимок.создать(self.источник, ЗАДАЧА, self.пакет)
        изменения = [
            lambda д: д.update({'unknown': 1}),
            lambda д: д['payload']['retained_context'].update({'incomplete': True}),
            lambda д: д['payload']['retained_context'].update({'user_messages_incomplete': True}),
            lambda д: д['payload']['retained_context'].update({'incomplete': 0}),
            lambda д: д['payload']['retained_context'].update({'verified_answers': ['ответ']}),
            lambda д: д['payload']['replacement_history_metadata'][0].update({'client_authored': True}),
            lambda д: д['payload']['replacement_history_metadata'][0].update({'client_authored': 0}),
            lambda д: д['payload']['replacement_history_metadata'].pop(),
            lambda д: д['payload']['replacement_history'][0]['content'][0].update({'text': 'Новый текст'}),
            lambda д: д['payload']['replacement_history'][0].update({'role': 'assistant'}),
            lambda д: д['payload']['replacement_history'][0]['internal_chat_message_metadata_passthrough'].update({'turn_id': 'чужой-ход'}),
            lambda д: д['payload']['replacement_history'].reverse(),
            lambda д: д['payload']['replacement_history'].__setitem__(1, д['payload']['replacement_history'][0]),
            lambda д: д['payload']['replacement_history'].pop(1),
            lambda д: д['payload'].update({'message': 'Непроверенный текст'}),
            lambda д: д['payload'].update({'unknown': 1}),
            lambda д: д['payload']['replacement_history'][0].update({'unknown': 1}),
            lambda д: д['payload']['replacement_history'][0]['content'][0].update({'unknown': 1}),
            lambda д: д['payload']['replacement_history'][0]['internal_chat_message_metadata_passthrough'].update({'content_item_kinds': ['иной вид']}),
            lambda д: д['payload']['replacement_history'][1].update({'id': д['payload']['replacement_history'][0]['id']}),
            lambda д: д['payload']['replacement_history'][4].update({'unknown': 1}),
            lambda д: д['payload']['replacement_history_metadata'][4].update({'client_authored': True}),
            lambda д: д['payload']['replacement_history_metadata'][4]['mcp_attribution'].update({'status': 'unknown'}),
            lambda д: д['payload']['resume_metadata'].update({'unknown': 1}),
            lambda д: д['payload']['latest_token_usage_record']['usage'].update({'input_tokens': False}),
        ]
        for номер, изменить in enumerate(изменения):
            данные = copy.deepcopy(фикстура.сжатие()); изменить(данные)
            self.источник.write_bytes(self.префикс + фикстура.строка(данные))
            with self.subTest(номер=номер), self.assertRaises(ValueError):
                снимок.прочитать(self.пакет, ЗАДАЧА)

    def test_будущее_сообщение_и_вывод_инструмента_не_служат_якорем(self):
        сообщения = фикстура.контекст()
        без_контекста = фикстура.строка({'type': 'session_meta', 'payload': {'id': ЗАДАЧА}})
        без_контекста += фикстура.строка({'type': 'turn_context', 'payload': {'model': 'gpt-6-astra', 'effort': 'low'}})
        for номер, хвост in enumerate((
            фикстура.строка(фикстура.сжатие()) + b''.join(фикстура.строка({'type': 'response_item', 'payload': с}) for с in сообщения),
            b''.join(фикстура.строка({'type': 'response_item', 'payload': {
                'type': 'function_call_output', 'output': часть['text']}})
                for сообщение in сообщения for часть in сообщение['content']) + фикстура.строка(фикстура.сжатие()),
        )):
            self.источник.write_bytes(без_контекста + хвост)
            with self.subTest(номер=номер), self.assertRaises(ValueError):
                снимок.создать(self.источник, ЗАДАЧА, self.пакет)
            self.assertFalse(self.пакет.exists())

    def test_второе_сжатие_не_создаёт_новые_якоря_и_дубли_исходных_id_отклоняются(self):
        self.источник.write_bytes(self.префикс + фикстура.строка(фикстура.сжатие()) * 2)
        снимок.создать(self.источник, ЗАДАЧА, self.пакет)
        сообщения = фикстура.контекст(); сообщения[1]['id'] = сообщения[0]['id']
        сырые = фикстура.строка({'type': 'session_meta', 'payload': {'id': ЗАДАЧА}})
        сырые += b''.join(фикстура.строка({'type': 'response_item', 'payload': с}) for с in сообщения)
        сырые += фикстура.строка({'type': 'turn_context', 'payload': {'model': 'gpt-6-astra', 'effort': 'low'}})
        self.источник.write_bytes(сырые + фикстура.строка(фикстура.сжатие()))
        with self.assertRaises(ValueError):
            снимок.создать(self.источник, ЗАДАЧА, self.корень / 'другой-снимок')

    def test_старый_отказ_не_сбрасывается_после_исправления_сжатия(self):
        снимок.создать(self.источник, ЗАДАЧА, self.пакет)
        неверное = фикстура.сжатие(); неверное['payload']['retained_context']['incomplete'] = True
        self.источник.write_bytes(self.префикс + фикстура.строка(неверное))
        курсор = self.корень / 'наблюдение.json'
        with self.assertRaises(ValueError):
            снимок.наблюдать(self.пакет, ЗАДАЧА, курсор, первое=True)
        прежнее = курсор.read_bytes()
        self.источник.write_bytes(self.префикс + фикстура.строка(фикстура.сжатие()))
        with self.assertRaisesRegex(ValueError, 'остаётся закрытой'):
            снимок.наблюдать(self.пакет, ЗАДАЧА, курсор)
        self.assertEqual(прежнее, курсор.read_bytes())

    def test_без_истории_сжатие_остаётся_неизвестным(self):
        with self.assertRaises(ValueError):
            снимок.проверить_запись(фикстура.сжатие())


if __name__ == '__main__':
    unittest.main()
