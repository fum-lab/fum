"""Точный отбор видимых ответов; неизвестная маркировка остаётся неопределённой."""
import hashlib
import io
import uuid

from снимок_нативного_источника import хранение, ПРЕДЕЛ

ФАЗЫ = {'commentary': 'commentary', 'final': 'final', 'final_answer': 'final', 'analysis': 'analysis'}


def извлечь(сырые, задача):
    хранение.требовать(type(задача) is str and str(uuid.UUID(задача)) == задача, 'Нужен точный UUID задачи')
    хранение.требовать(type(сырые) is bytes and 0 < len(сырые) <= ПРЕДЕЛ and сырые.endswith(b'\n'),
                       'Нужен ограниченный JSONL с завершающим LF')
    ответы, неопределённости = [], []
    смещение = 0
    for строка in io.BytesIO(сырые):
        начало, смещение = смещение, смещение + len(строка)
        запись = хранение.разобрать(строка)
        хранение.требовать(type(запись) is dict and type(запись.get('payload')) is dict,
                           'Неизвестная рамка native JSONL')
        данные = запись['payload']
        if начало == 0:
            хранение.требовать(запись.get('type') == 'session_meta', 'Источник не начинается с session_meta')
        if запись.get('type') == 'session_meta':
            хранение.требовать(данные.get('id') == задача, 'Чужой UUID native JSONL')
            continue
        if запись.get('type') != 'response_item':
            continue
        роль = данные.get('role')
        if данные.get('type') == 'message' and (type(роль) is not str or роль not in {
                'assistant', 'user', 'system', 'developer', 'tool'}):
            неопределённости.append({'исходник': {'начало': начало, 'конец': смещение,
                'sha256': hashlib.sha256(строка).hexdigest()}, 'причина': 'Неизвестная роль сообщения'})
            continue
        if роль != 'assistant':
            continue
        источник = {'начало': начало, 'конец': смещение, 'sha256': hashlib.sha256(строка).hexdigest()}
        поле = 'phase' if данные.get('phase') is not None else 'channel'
        фаза, канал = данные.get(поле), данные.get('channel')
        причина = None
        if данные.get('type') != 'message':
            причина = 'Неизвестный тип сообщения assistant'
        elif данные.get('recipient') is not None and данные['recipient'] != 'all':
            причина = 'Сообщение адресовано не пользователю'
        elif type(фаза) is not str or фаза not in ФАЗЫ:
            причина = 'Неизвестная либо отсутствующая фаза'
        elif поле == 'phase' and канал is not None and (
                type(канал) is not str or канал not in ФАЗЫ or ФАЗЫ[канал] != ФАЗЫ[фаза]):
            причина = 'Противоречие phase и channel'
        if причина is not None:
            неопределённости.append({'исходник': источник, 'причина': причина})
            continue
        if ФАЗЫ[фаза] == 'analysis':
            continue
        части = данные.get('content')
        if type(части) is not list or not части or any(
                type(часть) is not dict or часть.get('type') not in {'output_text', 'text'}
                or type(часть.get('text')) is not str for часть in части):
            неопределённости.append({'исходник': источник, 'причина': 'Неизвестное текстовое содержимое'})
            continue
        ответы.append({'фаза': ФАЗЫ[фаза], 'поле_фазы': поле,
                       'части': [часть['text'] for часть in части],
                       'исходник': источник, 'сырая_строка': строка.decode('utf-8')})
    return {'схема': 'fum.видимые-ответы-нативной-задачи.1',
            'источник': {'задача': задача, 'граница': len(сырые), 'sha256': hashlib.sha256(сырые).hexdigest()},
            'состояние': 'неполно' if неопределённости else ('сохранены' if ответы else 'пусто'),
            'полнота_поддержанных_ответов': not неопределённости,
            'ответы': ответы, 'неопределённости': неопределённости}
