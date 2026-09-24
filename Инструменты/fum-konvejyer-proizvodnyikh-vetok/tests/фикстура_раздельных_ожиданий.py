"""Два независимых ответа Desktop в открытом синтетическом JSONL."""
import copy
import json
from pathlib import Path

from фикстура_остановленного_поколения import граница, строка, ЗАДАЧА
from test_интервалов_нативных_вызовов import событие


def сохранить(вход, события):
    путь = Path(вход['источник']['путь'])
    путь.write_bytes(b''.join(строка(з) for з in [
        {'type': 'session_meta', 'payload': {'id': ЗАДАЧА}}, *события]))
    вход['источник'] = граница(путь, корень=True)


def разделить(вход, события, выгружено=True):
    опросы = json.loads(события[-1]['payload']['item']['result']['content'][0]['text'])['polls']
    записи = copy.deepcopy(события[:-1]); номера = {}
    for номер, опрос in enumerate(опросы):
        задача = опрос['thread']['id']; идентификатор = 'остановка-' + str(номер)
        запись = событие('wait_threads', идентификатор, {'targets': [{'threadId': задача}], 'timeoutMs': 0},
                         9 + 2 * номер, 10 + 2 * номер)
        опрос = copy.deepcopy(опрос)
        if выгружено and номер == 0:
            опрос['thread']['status'] = {'type': 'notLoaded'}
        запись['payload']['item']['result'] = {'content': [{'type': 'text', 'text': json.dumps({'polls': [опрос]})}], 'isError': False}
        записи.append(запись); номера[задача] = идентификатор
    вход['схема'] = 'fum.завершение-неудачного-запуска.3'
    del вход['ожидание']; вход['ожидания'] = номера
    сохранить(вход, записи)
    return записи
