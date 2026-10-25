"""Извлечь точный текст единственного входящего send; это ещё не допуск эффекта."""
import html
import os
from pathlib import Path
import re

import конверт_приёма as конверт
import снимок_нативного_источника as снимок

хранение = снимок.хранение


def прочитать(источник):
    сырые, _ = снимок._сырой(источник)
    строки = сырые.splitlines(keepends=True)
    начало = хранение.разобрать(строки[0])
    задача = os.environ.get('CODEX_THREAD_ID')
    корень = str(Path.cwd().resolve())
    хранение.требовать(начало.get('type') == 'session_meta'
        and начало.get('payload', {}).get('id') == задача
        and начало['payload'].get('cwd') == корень, 'Нативный источник другого получателя')
    найдено = None
    for строка in строки:
        запись = хранение.разобрать(строка)
        данные = запись.get('payload', {})
        if запись.get('type') == 'response_item' and данные.get('type') == 'function_call_output' \
                and данные.get('name') == 'send_message_to_thread':
            хранение.требовать(найдено is None and type(данные.get('output')) is str,
                'Повторный либо неизвестный входящий send')
            транспорт = re.fullmatch(r'<codex_delegation>\n  <source_thread_id>([^<\n]+)</source_thread_id>\n  <input>(.*)</input>\n</codex_delegation>',
                данные['output'], re.S)
            хранение.требовать(транспорт is not None, 'Неизвестный нативный транспорт приёма')
            текст = html.unescape(транспорт[2])
            блок = конверт.разобрать_текст(текст)
            хранение.требовать(html.escape(текст, quote=False) == транспорт[2]
                and транспорт[1] == блок['корневая_задача'] and блок['исполнитель'] == задача
                and блок['корень'] == корень, 'Чужой либо изменённый входящий send')
            найдено = текст
    хранение.требовать(найдено is not None, 'Поручение приёма ещё не получено')
    return найдено
