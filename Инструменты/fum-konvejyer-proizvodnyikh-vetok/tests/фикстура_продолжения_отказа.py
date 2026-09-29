"""Открытый Native: старая остановка, новый send, отказ и конечный postwait."""
import hashlib
import html
import json

from test_отказа_нативного_приёма import образец, строка
from test_отказа_сохранённого_приёма import сохранённый

КОРНЕВАЯ = '44444444-4444-4444-8444-444444444444'
ПРЕЖНИЙ = '55555555-5555-4555-8555-555555555555'
ТЕКСТ = 'Принять <проверенный срез> & сохранить ё.\n'


def транспорт(имя, текст):
    return {'type': 'response_item', 'payload': {'type': 'function_call_output',
        'name': имя, 'output': '<codex_delegation>\n  <source_thread_id>'
            + КОРНЕВАЯ + '</source_thread_id>\n  <input>' + html.escape(текст, quote=False)
            + '</input>\n</codex_delegation>'}}


def фикстура(*, обёртка=False):
    if обёртка:
        мета, событие, цель, канал, артефакт = сохранённый()
    else:
        мета, событие, цель = образец(); канал = артефакт = None
    префикс = мета + строка(транспорт('create_thread', 'Первоначальное назначение'))
    префикс += строка({'type': 'event_msg', 'payload': {'type': 'task_complete', 'turn_id': ПРЕЖНИЙ}})
    строки = [
        {'type': 'event_msg', 'payload': {'type': 'task_started', 'turn_id': цель['ход']}},
        транспорт('send_message_to_thread', ТЕКСТ), событие,
        {'type': 'event_msg', 'payload': {'type': 'task_complete', 'turn_id': цель['ход']}}]
    путь = '/внешнее/нативный-ребёнок.jsonl'
    остановка = {'путь': путь, 'граница': len(префикс), 'sha256': hashlib.sha256(префикс).hexdigest()}
    send = {'инструмент': 'send_message_to_thread', 'id': 'send-новый',
        'аргументы': {'threadId': цель['задача'], 'prompt': ТЕКСТ},
        'источник': {'начало': 100, 'конец': 200, 'sha256': 'a'*64},
        'интервал': {'начало_мс': 5, 'конец_мс': 8}}
    wait = {'инструмент': 'wait_threads', 'id': 'wait-новый',
        'аргументы': {'targets': [{'threadId': цель['задача']}]},
        'источник': {'начало': 300, 'конец': 400, 'sha256': 'b'*64},
        'интервал': {'начало_мс': 9, 'конец_мс': 30},
        'ответ': {'isError': False, 'content': [{'type': 'text', 'text': json.dumps({'polls': [
            {'thread': {'id': цель['задача'], 'status': {'type': 'idle'}},
             'latestTurn': {'id': цель['ход'], 'status': 'completed', 'error': None}}]})}]}}
    return {'префикс': префикс, 'строки': строки, 'остановка': остановка, 'цель': цель,
        'send': send, 'wait': wait, 'канал': канал, 'артефакт': артефакт}


def подготовить(ф):
    позиция = len(ф['префикс'])
    for запись in ф['строки']:
        raw = строка(запись)
        if запись is ф['строки'][2]:
            ф['цель'].update(начало=позиция, конец=позиция+len(raw), sha256=hashlib.sha256(raw).hexdigest())
        позиция += len(raw)
    return ф['префикс'] + b''.join(map(строка, ф['строки']))
