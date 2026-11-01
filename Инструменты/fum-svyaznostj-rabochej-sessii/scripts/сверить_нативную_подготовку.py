"""Адресная native-пара и полная цепь host-сессии; эффекта не выдаёт."""
from __future__ import annotations

import argparse
import datetime
import json
import os
from pathlib import Path
import re
import stat
import sys
import time

import сформировать_нативный_вызов as к

def текст(значение):
    к.требовать(type(значение) is str, 'неверный native текст')

def число(значение):
    к.требовать(type(значение) is int and значение >= 0, 'неверное native число')

def тексты(значение):
    к.требовать(type(значение) is list and all(type(э) is str for э in значение), 'неверный native список')

def содержание(элементы, тип):
    к.требовать(type(элементы) is list, 'неверное native содержание')
    for э in элементы:
        к.поля(э, {'type','text'}); к.требовать(э['type'] == тип, 'чужой native блок'); текст(э['text'])

def токены(д):
    к.поля(д, {'input_tokens','cached_input_tokens','cache_write_input_tokens',
        'output_tokens','reasoning_output_tokens','total_tokens'})
    for э in д.values(): число(э)

def происхождение(д, ход, время=False, содержание_есть=False):
    имена = {'turn_id'} | ({'create_time'} if время else set())
    if содержание_есть and 'content_item_kinds' in д: имена.add('content_item_kinds')
    к.поля(д, имена); к.требовать(д['turn_id'] == ход, 'чужой neutral turn')
    if время: к.требовать(type(д['create_time']) in (int,float) and д['create_time'] >= 0, 'неверное время пары')
    if 'content_item_kinds' in д: тексты(д['content_item_kinds'])

def оболочка(запись):
    обязательные = {'type','payload','timestamp','ordinal'}
    к.требовать(type(запись) is dict and обязательные <= set(запись)
        <= обязательные | {'metadata'} and type(запись['type']) is str
        and type(запись['payload']) is dict and type(запись['ordinal']) is int,
        'повреждённая native оболочка')
    текст(запись['timestamp'])
    к.требовать(запись['timestamp'].endswith('Z')
        and datetime.datetime.fromisoformat(запись['timestamp']).utcoffset() == datetime.timedelta(0),
        'нужно native время UTC')
    if 'metadata' in запись:
        м = запись['metadata']
        к.требовать(type(м) is dict and set(м) <= {'client_authored','fallback_token_limit_override',
            'user_input_order','retained_source'}, 'чужие native metadata')
        if 'client_authored' in м: к.требовать(type(м['client_authored']) is bool, 'неверный client_authored')
        for имя in ('fallback_token_limit_override','user_input_order'):
            if имя in м: число(м[имя])
        if 'retained_source' in м: к.требовать(type(м['retained_source']) is dict, 'неверный retained_source')

def проверить_рамку(запись, д):
    оболочка(запись)
    вид = запись['type']; п = запись['payload']; ход = д['turn_id']; владелец = д['исполнитель']
    if вид == 'turn_context':
        к.требовать(п.get('turn_id') == ход and п.get('cwd') == д['корень_контекста'], 'смешанный native контекст')
    elif вид == 'response_item':
        тип = п.get('type')
        if тип == 'custom_tool_call':
            к.поля(п, {'type','id','status','call_id','name','input','internal_chat_message_metadata_passthrough'})
            for имя in ('id','call_id','name','input'): текст(п[имя])
            к.требовать(п['status'] == 'completed', 'незавершённый native вызов')
            происхождение(п['internal_chat_message_metadata_passthrough'], ход, True)
        elif тип == 'custom_tool_call_output':
            к.поля(п, {'type','id','call_id','output','internal_chat_message_metadata_passthrough'})
            текст(п['id']); текст(п['call_id']); содержание(п['output'], 'input_text')
            происхождение(п['internal_chat_message_metadata_passthrough'], ход, True)
        elif тип == 'reasoning':
            к.поля(п, {'type','id','summary','encrypted_content','internal_chat_message_metadata_passthrough'})
            текст(п['id']); текст(п['encrypted_content']); содержание(п['summary'], 'summary_text')
            происхождение(п['internal_chat_message_metadata_passthrough'], ход)
        elif тип == 'message':
            к.поля(п, {'type','id','role','content','phase','internal_chat_message_metadata_passthrough'})
            к.требовать(п['role'] == 'assistant' and п['phase'] in {'commentary','final_answer'}, 'управляющее native сообщение')
            текст(п['id']); содержание(п['content'], 'output_text')
            происхождение(п['internal_chat_message_metadata_passthrough'], ход, True, True)
        elif тип in {'function_call','function_call_output'}:
            имена = {'type','call_id','name','arguments'} if тип == 'function_call' else {'type','call_id','output'}
            к.требовать(имена <= set(п) <= имена | {'id','internal_chat_message_metadata_passthrough'}, 'чужая function-рамка')
            for имя in имена-{'type'}: текст(п[имя])
            if 'id' in п: текст(п['id'])
            if 'internal_chat_message_metadata_passthrough' in п:
                происхождение(п['internal_chat_message_metadata_passthrough'], ход, True)
        else: raise ValueError('чужой native response item')
    elif вид == 'token_usage_record':
        к.поля(п, {'thread_id','turn_id','session_id','root_turn_id','response_id','usage','turn_token_usage','thread_token_usage'})
        к.требовать(п['thread_id'] == п['session_id'] == владелец
            and п['turn_id'] == п['root_turn_id'] == ход, 'чужая native запись токенов')
        текст(п['response_id'])
        for имя in ('usage','turn_token_usage','thread_token_usage'): токены(п[имя])
    elif вид == 'event_msg' and п.get('type') == 'token_count':
        к.поля(п, {'type','info','rate_limits'})
        к.поля(п['info'], {'total_token_usage','last_token_usage','model_context_window'})
        токены(п['info']['total_token_usage']); токены(п['info']['last_token_usage']); число(п['info']['model_context_window'])
        р = п['rate_limits']
        к.поля(р, {'limit_id','limit_name','primary','secondary','credits','individual_limit',
            'spend_control_reached','plan_type','rate_limit_reached_type'})
        for имя in ('limit_id','plan_type'): текст(р[имя])
        к.требовать(all(р[имя] is None for имя in ('limit_name','secondary','individual_limit',
            'spend_control_reached','rate_limit_reached_type')), 'неподдержанный native rate-limit вариант')
        к.поля(р['primary'], {'used_percent','window_minutes','resets_at'})
        к.требовать(type(р['primary']['used_percent']) in (int,float) and р['primary']['used_percent'] >= 0, 'неверный процент')
        число(р['primary']['window_minutes']); число(р['primary']['resets_at'])
        к.поля(р['credits'], {'has_credits','unlimited','balance'})
        к.требовать(type(р['credits']['has_credits']) is bool and type(р['credits']['unlimited']) is bool, 'неверные native credits')
        текст(р['credits']['balance'])
    elif вид == 'event_msg' and п.get('type') == 'item_completed':
        к.поля(п, {'type','thread_id','turn_id','item','started_at_ms','completed_at_ms'})
        к.требовать(п['thread_id'] == владелец and п['turn_id'] == ход, 'чужая транспортная копия')
        число(п['started_at_ms']); число(п['completed_at_ms'])
        к.требовать(п['completed_at_ms'] >= п['started_at_ms'], 'обратное native время')
        э = п['item']; к.требовать(type(э) is dict, 'повреждённый native item')
        тип = э.get('type')
        if тип == 'Reasoning':
            к.поля(э, {'type','id','summary_text','raw_content'}); тексты(э['summary_text'])
            к.требовать(э['raw_content'] == [], 'неподдержанное raw_content')
        elif тип == 'AgentMessage':
            к.поля(э, {'type','id','content','phase'}); содержание(э['content'], 'Text')
            к.требовать(э['phase'] in {'commentary','final_answer'}, 'чужая message phase')
        elif тип == 'SubAgentActivity':
            к.поля(э, {'type','id','kind','agent_thread_id','agent_path'})
            for имя in ('kind','agent_thread_id','agent_path'): текст(э[имя])
        elif тип == 'CommandExecution':
            к.поля(э, {'type','id','process_id','command','cwd','parsed_cmd','source','status','aggregated_output','exit_code','duration'})
            for имя in ('process_id','cwd','aggregated_output'): текст(э[имя])
            тексты(э['command'])
            к.требовать(э['source'] == 'unified_exec_startup' and э['status'] in {'completed','failed'}
                and type(э['exit_code']) is int, 'чужой native command outcome')
            к.поля(э['duration'], {'secs','nanos'}); число(э['duration']['secs']); число(э['duration']['nanos'])
            к.требовать(э['duration']['nanos'] < 1_000_000_000 and type(э['parsed_cmd']) is list, 'неверная command duration')
            формы = {'unknown':{'type','cmd'},'read':{'type','cmd','name','path'},
                'list_files':{'type','cmd','path'},'search':{'type','cmd','query','path'}}
            for команда in э['parsed_cmd']:
                к.требовать(type(команда) is dict and команда.get('type') in формы, 'чужой parsed command')
                к.поля(команда, формы[команда['type']])
                for имя,значение in команда.items():
                    if not (команда['type'] == 'search' and имя == 'path' and значение is None): текст(значение)
        else: raise ValueError('чужой native item')
        текст(э['id'])
    else: raise ValueError('чужая native рамка')

def место(значение):
    к.поля(значение, {'начало','конец','sha256'})
    к.требовать(type(значение['начало']) is int and type(значение['конец']) is int
        and 0 <= значение['начало'] < значение['конец'], 'неверный raw span')
    к.сумма(значение['sha256'])

def ожидание(д):
    к.поля(д, {'схема','выбор','выбор_sha256','JS_sha256','исполнитель','turn_id',
        'call_id','корень_контекста','источник'})
    к.требовать(д['схема'] == 'fum.ожидание-нативной-подготовки.1', 'неверное ожидание')
    for имя in ('выбор_sha256','JS_sha256'): к.сумма(д[имя])
    for имя in ('исполнитель','turn_id'): к.идентификатор(д[имя])
    к.физический(д['корень_контекста'], True)
    к.требовать(type(д['call_id']) is str and re.fullmatch(r'call_[A-Za-z0-9_-]{1,120}', д['call_id']),
        'неверный call_id')
    и = д['источник']
    к.поля(и, {'путь','личность','мета','интервал','вызов','исход'})
    к.требовать(type(и['личность']) is list and len(и['личность']) == 9
        and all(type(э) is int and э >= 0 for э in и['личность']), 'неверная native identity')
    for имя in ('мета','интервал','вызов','исход'): место(и[имя])
    к.требовать(и['мета']['начало'] == 0
        and и['мета']['конец'] <= и['интервал']['начало']
        <= и['вызов']['начало'] < и['вызов']['конец'] <= и['исход']['начало']
        < и['исход']['конец'] == и['интервал']['конец'], 'неверный порядок native spans')

def прочитать_нативный(д):
    ожидание(д)
    и = д['источник']; п = к.физический(и['путь'])
    до = к.отпечаток(п.lstat())
    к.требовать(list(до) == и['личность'] and до[3] == os.getuid()
        and stat.S_IMODE(до[2]) == 0o400 and до[5] == 1
        and до[6] <= 32*1024*1024*1024, 'чужой неизменяемый native снимок')
    фд = os.open(п, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        def взять(м):
            размер = м['конец'] - м['начало']
            к.требовать(0 < размер <= к.ПРЕДЕЛ and м['конец'] <= до[6], 'бюджет native span')
            сырые = os.pread(фд, размер, м['начало'])
            к.требовать(len(сырые) == размер and сырые.endswith(b'\n')
                and к.хэш(сырые) == м['sha256'], 'повреждённый native span')
            к.требовать(м['начало'] == 0 or os.pread(фд,1,м['начало']-1) == b'\n',
                'span начался внутри строки')
            return сырые
        мета = к.разобрать(взять(и['мета']))
        оболочка(мета)
        к.требовать(мета['type'] == 'session_meta'
            and мета['payload']['id'] == д['исполнитель'], 'чужой native owner')
        интервал = взять(и['интервал'])
        строки = интервал.splitlines(keepends=True)
        к.требовать(len(строки) <= 131072, 'бюджет адресного интервала')
        записи = []; позиция = и['интервал']['начало']
        предыдущее = -1
        for строка in строки:
            запись = к.разобрать(строка)
            к.требовать(type(запись) is dict
                and type(запись.get('ordinal')) is int
                and запись['ordinal'] > предыдущее, 'native ordinal нарушен')
            проверить_рамку(запись, д)
            предыдущее = запись['ordinal']
            записи.append((позиция, позиция+len(строка), запись, строка))
            позиция += len(строка)
        первый = записи[0][2]
        к.требовать(первый['type'] == 'turn_context'
            and первый['payload']['turn_id'] == д['turn_id']
            and первый['payload']['cwd'] == д['корень_контекста'], 'нет независимого turn context')
        пары = {'custom_tool_call':[], 'custom_tool_call_output':[]}
        открытые = {}; прежние = set()
        for от,до_строки,запись,строка in записи:
            if запись['type'] == 'turn_context':
                к.требовать(запись['payload']['turn_id'] == д['turn_id'], 'смешанные native turns')
            тело = запись.get('payload', {})
            if запись['type'] == 'response_item' and тело.get('type') in {
                    'custom_tool_call','custom_tool_call_output','function_call','function_call_output'}:
                вызов = тело['call_id']; тип = тело['type']
                if вызов != д['call_id']:
                    к.требовать(до_строки <= и['вызов']['начало'], 'другой primary call внутри адресного исполнения')
                    if тип in {'custom_tool_call','function_call'}:
                        к.требовать(вызов not in прежние and вызов not in открытые, 'повтор прежнего call_id')
                        открытые[вызов] = тип
                    else:
                        к.требовать(открытые.pop(вызов, None) == тип.removesuffix('_output'), 'незамкнутая прежняя пара')
                        прежние.add(вызов)
                elif тип == 'custom_tool_call':
                    к.требовать(not открытые, 'прежняя пара не закрыта до адресного вызова')
            if запись['type'] == 'response_item' and тело.get('call_id') == д['call_id']:
                к.требовать(тело.get('type') in пары, 'чужой вид адресного call_id')
                пары[тело['type']].append((от,до_строки,запись,строка))
        к.требовать(all(len(э) == 1 for э in пары.values()), 'повтор или пропуск native пары')
        результат = {}
        for имя, тип in (('вызов','custom_tool_call'), ('исход','custom_tool_call_output')):
            от,конец,запись,строка = пары[тип][0]
            м = и[имя]
            к.требовать(от == м['начало'] and конец == м['конец'] and к.хэш(строка) == м['sha256'],
                'адресная пара отличается от выбора')
            тело = запись['payload']
            к.требовать(тело['internal_chat_message_metadata_passthrough']['turn_id'] == д['turn_id'],
                'чужой turn у пары')
            к.требовать(запись.get('metadata', {}).get('client_authored') is not True,
                'адресная пара записана клиентом')
            результат[имя] = запись
        к.требовать(к.отпечаток(os.fstat(фд)) == к.отпечаток(п.lstat()) == tuple(и['личность']),
            'native снимок дрейфовал')
        return результат
    finally:
        os.close(фд)

def проверить_события(события, бюджет):
    к.требовать(type(события) is list and 1 <= len(события) <= 1+бюджет['ожиданий'],
        'неверное число host objects')
    сеанс = None
    вывод = []
    допустимые = {'chunk_id','wall_time_seconds','exit_code','original_token_count','output','session_id'}
    for номер, э in enumerate(события):
        к.требовать(type(э) is dict and {'output','wall_time_seconds'} <= set(э)
            and set(э) <= допустимые and type(э['output']) is str
            and type(э['wall_time_seconds']) in (int,float) and э['wall_time_seconds'] >= 0,
            'неполный или чужой host object')
        if 'original_token_count' in э:
            к.требовать(type(э['original_token_count']) is int
                and 0 <= э['original_token_count'] <= бюджет['токенов'], 'truncated host output')
        if 'session_id' in э:
            к.требовать('exit_code' not in э and type(э['session_id']) is int, 'неверная live session')
            if номер == 0: сеанс = э['session_id']
            к.требовать(сеанс is not None and э['session_id'] == сеанс, 'чужая host session')
        else:
            к.требовать(номер == len(события)-1 and type(э.get('exit_code')) is int
                and э['exit_code'] == 0, 'нет истинного terminal host0')
            if номер: к.требовать(сеанс is not None, 'terminal после неизвестной session')
        вывод.append(э['output'])
    к.требовать('session_id' not in события[-1], 'незавершённая host session')
    return ''.join(вывод)

def сверить(д):
    начало = time.monotonic_ns()
    пара = прочитать_нативный(д)
    разбор_нс = time.monotonic_ns() - начало
    выбор, удержанные = к.удержать_выбор(д['выбор'], д['выбор_sha256'])
    try:
        к.требовать(д['исполнитель'] == выбор['исполнитель'], 'чужой исполнитель выбора')
        сценарий = к.сформировать(д['выбор'], д['выбор_sha256'])
        к.требовать(к.хэш(сценарий.encode()) == д['JS_sha256'], 'не совпал независимый full JS SHA')
        вызов = пара['вызов']['payload']
        к.поля(вызов, {'type','id','status','call_id','name','input',
            'internal_chat_message_metadata_passthrough'})
        к.требовать(вызов['name'] == 'exec' and вызов['status'] == 'completed'
            and вызов['input'] == сценарий, 'подменена полная композиция JS')
        исход = пара['исход']['payload']
        к.поля(исход, {'type','id','call_id','output','internal_chat_message_metadata_passthrough'})
        к.требовать(пара['исход'].get('metadata', {}).get('client_authored') is False,
            'исход не является host output')
        блоки = исход['output']
        к.требовать(type(блоки) is list and len(блоки) == 2, 'неполные или лишние input_text')
        for блок in блоки:
            к.поля(блок, {'type','text'})
            к.требовать(блок['type'] == 'input_text' and type(блок['text']) is str, 'чужой блок исхода')
        к.требовать(re.fullmatch(r'Script completed\nWall time [0-9]+(?:\.[0-9]+)? seconds\nOutput:\n',
            блоки[0]['text']), 'внешний exec не завершён; функции wait не поддерживаются')
        тело = к.разобрать(блоки[1]['text'].encode())
        к.поля(тело, {'схема','события'})
        к.требовать(тело['схема'] == 'fum.нативные-события-подготовки.1', 'чужой результат JS')
        строка = проверить_события(тело['события'], выбор['бюджет'])
        указатель = к.разобрать(строка.encode())
        к.поля(указатель, {'схема','слот','квитанция_sha256','наблюдатель_код','подготовка_код'})
        к.требовать(указатель['схема'] == 'fum.указатель-нативной-подготовки.1'
            and указатель['слот'] == выбор['слот']
            and type(указатель['наблюдатель_код']) is int and type(указатель['подготовка_код']) is int
            and указатель['наблюдатель_код'] == указатель['подготовка_код'] == 0,
            'наблюдатель или подготовка неуспешны')
        перечитывание = time.monotonic_ns()
        слот = к.физический(выбор['слот'], True)
        с = слот.lstat()
        к.требовать(с.st_uid == os.getuid() and stat.S_IMODE(с.st_mode) == 0o700, 'чужой слот')
        прочитанные = []
        def файл(имя, ожидаемый_хэш):
            удержанный = к.Удержанный(str(слот/имя), ожидаемый_хэш, True, True)
            прочитанные.append(удержанный)
            return удержанный
        try:
            кв = к.разобрать(файл('квитанция.json', указатель['квитанция_sha256']).данные)
            к.поля(кв, {'схема','выбор_sha256','намерение_sha256','поколение','ключ','pid',
                'подготовка_код','наблюдатель_код','завершён','тайм_аут','сигнал','ошибка',
                'каналы','начало_нс','конец_нс','профиль','новый_эффект'})
            к.требовать(кв['схема'] == 'fum.квитанция-нативной-подготовки.1'
                and кв['выбор_sha256'] == д['выбор_sha256']
                and кв['поколение'] == выбор['ожидаемое_поколение'] and кв['ключ'] == выбор['ключ']
                and type(кв['наблюдатель_код']) is int and type(кв['подготовка_код']) is int
                and кв['наблюдатель_код'] == кв['подготовка_код'] == 0
                and кв['завершён'] is True and кв['тайм_аут'] is False
                and кв['сигнал'] is None and кв['ошибка'] is None
                and кв['новый_эффект'] is False and type(кв['pid']) is int and кв['pid'] > 0,
                'неуспешная квитанция')
            намерение = к.разобрать(файл('намерение.json', кв['намерение_sha256']).данные)
            к.требовать(намерение == {'схема':'fum.намерение-нативной-подготовки.1',
                'выбор_sha256':д['выбор_sha256'],'выбор':выбор,'начало_нс':кв['начало_нс']},
                'намерение не выбрало эту операцию')
            к.поля(кв['каналы'], {'stdout','stderr','аудит'})
            каналы = {}
            for имя, описание in кв['каналы'].items():
                к.поля(описание, {'байты','sha256','личность'})
                ф = файл(имя+'.bin', описание['sha256'])
                к.требовать(len(ф.данные) == описание['байты']
                    and list(ф.личность) == описание['личность'], 'канал усечён или заменён')
                каналы[имя] = ф.данные
            р = к.разобрать(каналы['stdout']); аудит = к.разобрать(каналы['аудит'])
            к.требовать(р == {'схема':'fum.подготовленный-запуск-приёма-базиса.1',
                'вход_sha256':выбор['вход']['sha256'],'ключ':выбор['ключ'],
                'процесс':{'код':0,'исполнение_завершено':True,'тайм_аут':False,'прерывание':None}}
                and аудит == {'вход':1,'compile':1,'код':0,
                'argv':[str(удержанные[к.ЗАПУСК].путь),'--подготовить-запуск',выбор['вход']['путь']]},
                'не подтвердился настоящий единственный CLI')
            к.пересверить(выбор, удержанные)
            for ф in прочитанные: ф.сверить()
            return {'схема':'fum.сверка-нативной-подготовки.1','подготовка_подтверждена':True,
                'разрешение_эффекта':False,'выбор_sha256':д['выбор_sha256'],
                'JS_sha256':д['JS_sha256'],'квитанция_sha256':указатель['квитанция_sha256'],
                'поколение':кв['поколение'],'каналы':кв['каналы'],
                'адресный_интервал':д['источник']['интервал'],
                'профиль':{'разбор_нативного_исхода_нс':разбор_нс,
                    'перечитывание_нс':time.monotonic_ns()-перечитывание}}
        finally:
            for ф in прочитанные: ф.закрыть()
    finally:
        for ф in удержанные.values(): ф.закрыть()

def главный():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--ожидание', required=True)
    разбор.add_argument('--sha256', required=True)
    а = разбор.parse_args()
    try:
        with к.Удержанный(а.ожидание, к.сумма(а.sha256), True) as ф:
            д = к.разобрать(ф.данные)
            к.требовать(к.байты(д) == ф.данные, 'неканоническое ожидание')
            результат = сверить(д); ф.сверить()
            sys.stdout.buffer.write(к.байты(результат))
        return 0
    except (ValueError,OSError,KeyError,TypeError,AttributeError) as о:
        print(str(о), file=sys.stderr)
        return 2

if __name__ == '__main__':
    raise SystemExit(главный())
