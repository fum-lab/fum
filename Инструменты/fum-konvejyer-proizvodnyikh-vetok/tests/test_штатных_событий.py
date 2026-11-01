"""Штатное редактирование не скрывает новый человеческий ввод и транспорт."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import test_запуска_слоёв
import снимок_нативного_источника as снимок
import полный_поток_передачи as полный
import нативный_приём
from фикстура_нативного_приёма import ЗАДАЧА, РЕБЁНОК, строка, фикстура
from фикстура_штатных_событий import (изменение_файлов, обновление, служебный_контекст,
    начальные_события, копия_транспорта, полный_получатель)


class ПроверкаШтатныхФайлов(unittest.TestCase):
    def test_добавление_обновление_и_смешанный_пакет_до_и_после_снимка(self):
        начало = строка({'type': 'session_meta', 'payload': {'id': РЕБЁНОК}})
        события = начальные_события()
        # Граница — точный плоский create, его копия остаётся в проверяемом хвосте.
        префикс = начало + b''.join(map(строка, события[:3]))
        for изменения in ({'a': {'type': 'add', 'content': ''}}, {'a': обновление()},
                {'a': обновление(), 'b': {'type': 'add', 'content': 'ё\n'}}):
            with self.subTest(изменения=изменения):
                хвост = строка(события[3]) + строка(изменение_файлов(изменения))
                полный.проверить(префикс + хвост, len(префикс))
                with tempfile.TemporaryDirectory() as tmp:
                    корень = Path(tmp).resolve(); источник = корень / 'native.jsonl'
                    # Для истории модели нужны первичные timestamp, включая session_meta.
                    исходные = [json.loads(с) for с in (префикс + хвост).splitlines()]
                    источник.write_bytes(b''.join(строка({'timestamp': '2026-09-24T12:00:00Z', **с})
                        for с in исходные))
                    снимок.создать(источник, РЕБЁНОК, корень / 'снимок')
                    курсор = корень / 'наблюдение.json'
                    до = снимок.наблюдать(корень / 'снимок', РЕБЁНОК, курсор, первое=True)
                    with источник.open('ab') as файл: файл.write(строка(изменение_файлов(изменения)))
                    после = снимок.наблюдать(корень / 'снимок', РЕБЁНОК, курсор)
                    self.assertGreater(после['граница'], до['граница'])

    def test_неизвестные_и_повреждённые_изменения_закрывают_передачу(self):
        правильное = изменение_файлов()
        варианты = []
        for ключ, значение in (('status', 'failed'), ('id', None), ('stdout', None),
                ('stderr', []), ('role', 'user'), ('changes', {}), ('changes', [])):
            э = copy.deepcopy(правильное); э['payload']['item'][ключ] = значение; варианты.append(э)
        э = copy.deepcopy(правильное); del э['payload']['item']['stderr']; варианты.append(э)
        э = copy.deepcopy(правильное); э['payload']['type'] = 'item_started'; варианты.append(э)
        for изменение in ({'type': 'add', 'content': 0}, {'type': 'delete'},
                {**обновление(), 'move_path': 'другой.txt'}, {'type': 'update', 'unified_diff': ''},
                {**обновление(), 'unified_diff': None}, {'type': 'add', 'content': '', 'лишнее': True}):
            варианты.append(изменение_файлов({'правильный': обновление(), 'другой': изменение}))
        for э in варианты:
            with self.subTest(э=э), self.assertRaises(ValueError):
                снимок.проверить_хвост(строка(э))

    def test_полный_поток_разбирает_каждую_строку_один_раз(self):
        события = [{'type': 'session_meta', 'payload': {'id': РЕБЁНОК}}, *начальные_события()]
        события[-1] = {'type': 'response_item', 'payload': {
            'type': 'custom_tool_call_output', 'output': 'Обычный открытый вывод.'}}
        сырые = b''.join(map(строка, события)); граница = len(b''.join(map(строка, события[:4])))
        with mock.patch.object(снимок.хранение, 'разобрать', wraps=снимок.хранение.разобрать) as разбор:
            полный.проверить(сырые, граница)
        self.assertEqual(len(события), разбор.call_count)

    def test_вложенное_управление_не_теряется_перед_границей(self):
        начало = [{'type': 'session_meta', 'payload': {'id': РЕБЁНОК}}, *начальные_события()[:2]]
        поручение = начальные_события()[2]
        опасные = [{'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {'type': 'UserMessage'}}},
            {'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {
                'type': 'AgentMessage', 'role': 'user'}}}, служебный_контекст(),
            {'type': 'event_msg', 'payload': {'type': 'turn_aborted'}}]
        for э in опасные:
            with self.subTest(э=э), self.assertRaises(ValueError):
                сырые = b''.join(map(строка, [*начало, э, поручение]))
                полный.проверить(сырые, len(сырые))
        э = {'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {
            'type': 'McpToolCall', 'server': 'codex_app', 'tool': 'create_thread'}}}
        with self.assertRaises(ValueError): снимок.проверить_хвост(строка(э))


class ПроверкаПолногоПолучателя(unittest.TestCase):
    def прочитать(self, ф, свидетельство=None):
        return нативный_приём.прочитать(свидетельство or ф['свидетельство'], ЗАДАЧА, РЕБЁНОК,
            str(ф['корень']), ф['источник'], ф['текст'])

    def test_начальный_контекст_создание_остановка_send_копии_и_файлы(self):
        with полный_получатель() as ф:
            self.assertEqual(ф['текст'], self.прочитать(ф)['текст'])

    def test_контекст_без_полной_аннотации_и_поздний_контекст_не_принимаются(self):
        варианты = []
        for поле, значение in (('phase', 'analysis'), ('internal_chat_message_metadata_passthrough', None)):
            э = служебный_контекст(); э['payload'][поле] = значение; варианты.append(э)
        for виды in (['user.text', 'user.text'], ['agents_md.instructions'],
                ['environments.environment_context', 'agents_md.instructions']):
            э = служебный_контекст()
            э['payload']['internal_chat_message_metadata_passthrough']['content_item_kinds'] = виды
            варианты.append(э)
        for э in варианты:
            with self.subTest(э=э), полный_получатель() as ф:
                путь = Path(ф['свидетельство']['остановка']['путь'])
                строки = путь.read_bytes().splitlines(keepends=True); строки[1] = строка(э)
                путь.write_bytes(b''.join(строки))
                with self.assertRaises(ValueError): self.прочитать(ф, ф['сохранить']())
        for позиция in (2, 3, 4):
            with self.subTest(позиция=позиция), полный_получатель() as ф:
                путь = Path(ф['свидетельство']['остановка']['путь'])
                строки = путь.read_bytes().splitlines(keepends=True)
                путь.write_bytes(b''.join(строки[:позиция]) + строка(служебный_контекст())
                    + b''.join(строки[позиция:]))
                with self.assertRaises(ValueError): self.прочитать(ф, ф['сохранить']())

    def test_вложенный_человек_и_отмена_до_и_после_send(self):
        for э in ({'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {'type': 'UserMessage'}}},
                {'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {
                    'type': 'AgentMessage', 'role': 'user'}}},
                {'type': 'event_msg', 'payload': {'type': 'turn_aborted'}}):
            for место in ('префикс', 'до-send', 'после-send'):
                with self.subTest(э=э, место=место), полный_получатель() as ф:
                    входы = [ф['транспорт']]
                    if место == 'префикс':
                        путь = Path(ф['свидетельство']['остановка']['путь'])
                        строки = путь.read_bytes().splitlines(keepends=True)
                        путь.write_bytes(строки[0] + строка(э) + b''.join(строки[1:]))
                    elif место == 'до-send': входы.insert(0, э)
                    else: входы.append(э)
                    with self.assertRaises(ValueError): self.прочитать(ф, ф['сохранить'](входы=входы))

    def test_служебный_контекст_после_остановки_не_становится_первоначальным(self):
        with фикстура() as ф, self.assertRaises(ValueError):
            self.прочитать(ф, ф['сохранить'](входы=[служебный_контекст(), ф['транспорт']]))

    def test_повторное_создание_в_остановленном_префиксе_отклоняется(self):
        with полный_получатель() as ф:
            путь = Path(ф['свидетельство']['остановка']['путь'])
            путь.write_bytes(путь.read_bytes() + строка(начальные_события()[2]))
            with self.assertRaises(ValueError): self.прочитать(ф, ф['сохранить']())

    def test_плоские_вызовы_транспорта_перед_границей_и_send_отклоняются(self):
        for вид in ('function_call', 'custom_tool_call'):
            for имя in ('create_thread', 'send_message_to_thread', 'handoff_thread'):
                поле = 'arguments' if вид == 'function_call' else 'input'
                э = {'type': 'response_item', 'payload': {'type': вид, 'name': имя, поле: '{}'}}
                события = [{'type': 'session_meta', 'payload': {'id': РЕБЁНОК}},
                    *начальные_события()[:2], э, начальные_события()[2]]
                сырые = b''.join(map(строка, события))
                with self.subTest(вид=вид, имя=имя, место='перед-границей'), self.assertRaises(ValueError):
                    полный.проверить(сырые, len(сырые))
                for после in (False, True):
                    with self.subTest(вид=вид, имя=имя, после=после), полный_получатель() as ф:
                        входы = [ф['транспорт'], э] if после else [э, ф['транспорт']]
                        with self.assertRaises(ValueError): self.прочитать(ф, ф['сохранить'](входы=входы))

    def test_обычный_вызов_другого_инструмента_сохраняет_приём(self):
        with полный_получатель() as ф:
            э = {'type': 'response_item', 'payload': {
                'type': 'function_call', 'name': 'exec_command', 'arguments': '{}'}}
            self.assertEqual(ф['текст'], self.прочитать(ф,
                ф['сохранить'](входы=[э, ф['транспорт'], э]))['текст'])

    def test_подмена_повтор_и_копия_до_оригинала_отклоняются(self):
        with полный_получатель() as ф:
            копия = копия_транспорта(ф['транспорт'])
            варианты = [[копия, ф['транспорт']], [ф['транспорт'], копия, копия]]
            for ключ, значение in (('output', 'подмена'), ('namespace', 'другой'), ('name', 'handoff_thread')):
                э = copy.deepcopy(копия); э['payload']['item'][ключ] = значение
                варианты.append([ф['транспорт'], э])
            э = copy.deepcopy(копия); э['payload']['type'] = 'item_started'
            варианты.append([ф['транспорт'], э])
            for имя in ('create_thread', 'handoff_thread', 'send_message_to_thread'):
                э = copy.deepcopy(ф['транспорт']); э['payload']['name'] = имя
                варианты.append([э, ф['транспорт']])
            for входы in варианты:
                with self.subTest(входы=входы), self.assertRaises(ValueError):
                    self.прочитать(ф, ф['сохранить'](входы=входы))


if __name__ == '__main__':
    unittest.main()
