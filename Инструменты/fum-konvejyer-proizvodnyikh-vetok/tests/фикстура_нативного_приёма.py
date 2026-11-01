"""Два первичных транспорта: wait/send координатора и вход ребёнка."""
from contextlib import contextmanager
import html
import json
from pathlib import Path
import tempfile

from test_интервалов_нативных_вызовов import событие, РЕБЁНОК
from test_завершения_запуска import граница, строка, ЗАДАЧА

ХОД = '22222222-2222-4222-8222-222222222222'


@contextmanager
def фикстура():
    with tempfile.TemporaryDirectory() as каталог:
        путь = Path(каталог).resolve()
        корень = путь / 'FUM'; корень.mkdir()
        остановка = путь / 'остановка.jsonl'
        остановка.write_bytes(b''.join(строка(э) for э in [
            {'type': 'session_meta', 'payload': {'id': РЕБЁНОК, 'cwd': str(корень)}},
            {'type': 'event_msg', 'payload': {'type': 'task_complete', 'turn_id': ХОД}},
            {'type': 'event_msg', 'payload': {'type': 'thread_settings_applied',
                'thread_id': РЕБЁНОК, 'thread_settings': {'cwd': str(корень)}}}]))
        wait = событие('wait_threads', 'wait', {'targets': [{'threadId': РЕБЁНОК}], 'timeoutMs': 0}, 10, 20)
        wait['payload']['item']['result']['content'] = [{'type': 'text', 'text': json.dumps({'polls': [
            {'thread': {'id': РЕБЁНОК, 'status': {'type': 'idle'}},
             'latestTurn': {'id': ХОД, 'status': 'completed', 'error': None}}]})}]
        текст = 'Принять срез <данные> & сохранить ё.\n'
        send = событие('send_message_to_thread', 'send', {'threadId': РЕБЁНОК, 'prompt': текст}, 21, 22)
        координатор = путь / 'координатор.jsonl'
        источник = путь / 'ребёнок.jsonl'
        транспорт = {'type': 'response_item', 'payload': {'type': 'function_call_output',
            'name': 'send_message_to_thread', 'output': '<codex_delegation>\n  <source_thread_id>'
                + ЗАДАЧА + '</source_thread_id>\n  <input>' + html.escape(текст, quote=False)
                + '</input>\n</codex_delegation>'}}
        def сохранить(события=None, входы=None):
            координатор.write_bytes(b''.join(строка(э) for э in [
                {'type': 'session_meta', 'payload': {'id': ЗАДАЧА}}, *(события or [wait, send])]))
            источник.write_bytes(остановка.read_bytes() + b''.join(строка(э) for э in (входы or [транспорт])))
            return {'схема': 'fum.свидетельство-дочернего-приёма.1',
                'координатор': граница(координатор, корень=True), 'остановка': граница(остановка),
                'ожидание': 'wait', 'возобновление': 'send'}
        yield {'путь': путь, 'корень': корень, 'источник': источник, 'текст': текст,
               'wait': wait, 'send': send, 'транспорт': транспорт, 'сохранить': сохранить,
               'свидетельство': сохранить()}
