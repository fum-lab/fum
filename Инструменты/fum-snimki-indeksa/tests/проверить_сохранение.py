"""Независимый оркестратор обещаний сохранения и прежнего эталона f7b55dcc."""
import hashlib
import importlib.util
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from поток_диалога import экспортировать_файл
from диалог import проверить_экспорт
from канон import ОшибкаВхода

ПРЕЖНИЙ = 'f7b55dccce283643a932b9b84f271377403884eb'
ЗАДАЧА = '00000000-0000-4000-8000-000000000001'


def канонические_байты(значение):
    """Независимая сериализация стандартной библиотекой, без кода канон.py."""
    текст=json.dumps(значение,ensure_ascii=False,sort_keys=True,separators=(',',':'))
    замены={'\\b':'\\u0008','\\f':'\\u000c','\\n':'\\u000a','\\r':'\\u000d','\\t':'\\u0009'}
    return (re.sub(r'\\(?:["\\]|[bfnrt]|u[0-9a-f]{4})',lambda совпадение:замены.get(совпадение[0],совпадение[0]),текст)+'\n').encode()


def сырая_строка(тип,данные):
    return (json.dumps({'type':тип,'payload':данные},ensure_ascii=False)+'\n').encode()


def смешанный_журнал(корень):
    from очередь import Очередь
    части = [{'type':'input_text','text':'Ёж é e\u0301 😀 \x00\b\t\n\f\r \\n \\u000a "'}, {'type':'output_text','text':''}, {'type':'input_image','image_url':'opaque'}, {'type':'input_image','image_url':'opaque','detail':None}, {'type':'input_audio','audio_url':'opaque'}]
    человек = {'type':'message','role':'user','content':части,'internal_chat_message_metadata_passthrough':{'content_item_kinds':['user.text','user.text','user.image','user.image','user.audio']}}
    ответ = {'type':'message','role':'assistant','phase':'commentary','content':[{'type':'output_text','text':'Ёж'},{'type':'output_text','text':''}],'internal_chat_message_metadata_passthrough':{'content_item_kinds':['unknown','unknown']}}
    простой = {'type':'message','role':'assistant','phase':'final','content':[{'type':'output_text','text':'Готово'}]}
    записи = [
        ('session_meta',{'id':ЗАДАЧА}), ('response_item',человек), ('response_item',ответ),
        ('response_item',{'type':'message','role':'system','content':[{'type':'input_text','text':'Система'}]}),
        ('response_item',{**ответ,'phase':'analysis'}),
        ('response_item',{'type':'message','role':'developer','content':[{'type':'input_text','text':'Среда'}]}),
        ('response_item',{'type':'message','role':'tool','content':[{'type':'input_text','text':'Вывод'}]}),
        ('response_item',{'type':'message','role':'user','content':[{'type':'input_text','text':'Контекст'}],'internal_chat_message_metadata_passthrough':{'content_item_kinds':['agents_md.instructions']}}),
        ('response_item',{'type':'message','role':'user','content':[{'type':'input_text','text':'<hook_prompt hook_run_id="1">остановись</hook_prompt>'}]}),
        ('event_msg',{'type':'user_message','message':'Повтор события'}),
        ('response_item',простой),('response_item',{**ответ,'phase':'final_answer'}),('response_item',человек)]
    строки=[сырая_строка(тип,данные) for тип,данные in записи];сырые=b''.join(строки)
    выбранные=[1,2,10,11,12];ожидаемые=[];позиции=[]
    for номер,индекс in enumerate(выбранные,1):
        данные=записи[индекс][1]
        состав={'роль':данные['role'],'фаза':данные.get('phase'),'части':данные['content'],'виды_частей':данные.get('internal_chat_message_metadata_passthrough',{}).get('content_item_kinds')}
        байты=канонические_байты(состав)
        ожидаемые.append({'номер':номер,**состав,'происхождение':'человек' if данные['role']=='user' else 'ответ ассистента','байтовая_длина':len(байты),'хэш_частей':hashlib.sha256(байты).hexdigest()})
        начало=sum(map(len,строки[:индекс]));позиции.append({'номер':номер,'начало':начало,'конец':начало+len(строки[индекс])})
    источник=корень/'смешанный.jsonl';источник.write_bytes(сырые+b'{"text":"\xd1')
    экспорт,курсор=экспортировать_файл(источник,ЗАДАЧА)
    assert экспорт==канонические_байты({'схема':'fum.экспорт-команд.2','идентификатор_задачи':ЗАДАЧА,'сообщения':ожидаемые})
    assert курсор['позиции']==позиции and курсор['граница_байтов']==len(сырые) and курсор['хэш_префикса']==hashlib.sha256(сырые).hexdigest()
    другие=b''.join((json.dumps({'type':тип,'payload':данные},ensure_ascii=True,separators=(',',':'))+'\n').encode() for тип,данные in записи)
    источник.write_bytes(другие);новый,иной=экспортировать_файл(источник,ЗАДАЧА)
    assert новый==экспорт and иной['хэш_префикса']!=курсор['хэш_префикса']
    try: экспортировать_файл(источник,ЗАДАЧА,квитанция=курсор)
    except ОшибкаВхода: pass
    else: raise AssertionError('Другие raw-байты приняли прежний курсор')
    источник.write_bytes(сырые)
    очередь=Очередь.создать(корень/'очередь',источник,ЗАДАЧА,'00000000-0000-4000-8000-000000000002','a'*64,курсор,[])
    поздний_ответ=сырая_строка('response_item',ответ);поздний_человек=сырая_строка('response_item',человек);хвост=поздний_ответ+поздний_человек
    with источник.open('ab') as поток: поток.write(хвост)
    решения=[];связь=lambda запрос:{'запрос':запрос,'состояние':'доступен','решения':решения}
    доставка=очередь.доставить(связь)
    assert bytes.fromhex(доставка['сырая_строка'])==поздний_человек and доставка['происхождение']=='человек'
    assert доставка['ссылка']['номер']==1 and доставка['ссылка']['начало']==len(сырые)+len(поздний_ответ)
    решения.append({'идентификатор':'00000000-0000-4000-8000-000000000003','ссылка':доставка['ссылка'],'действие':'учесть','разрешения':None})
    очередь.подтвердить(доставка['ссылка'],связь)
    assert очередь.доставить(связь) is None
    итог=очередь.барьер(связь);граница=итог['барьер']['курсор']
    assert итог['исполнение_разрешено'] is False and граница['хэш_завершённого_хвоста']==граница['хэш_наблюдённого_хвоста']==hashlib.sha256(хвост).hexdigest()
    события=[json.loads(строка) for строка in (очередь.каталог/'события.jsonl').read_bytes().splitlines()]
    assert b''.join(bytes.fromhex(запись['данные']['байты']) for запись in события if запись['вид']=='источник')==хвост
    подмена={**доставка['ссылка'],'начало':len(сырые),'конец':len(сырые)+len(поздний_ответ),'хэш':hashlib.sha256(поздний_ответ).hexdigest()}
    assert set(подмена)==set(доставка['ссылка'])
    решения.append({'идентификатор':'00000000-0000-4000-8000-000000000004','ссылка':подмена,'действие':'отозвать','разрешения':None})
    итог=очередь.барьер(связь)
    assert итог['барьер'] is None and итог['состояние']=='неоднозначно'
    return 11


def выполнить():
    путь_модуля='Инструменты/fum-snimki-indeksa/scripts/поток_диалога.py'
    прежние_байты=subprocess.check_output(['git','show',ПРЕЖНИЙ+':'+путь_модуля])
    утверждений=0
    with tempfile.TemporaryDirectory() as временный:
        корень=Path(временный).resolve();источник=корень/'источник.jsonl';старый_путь=корень/'прежний.py';старый_путь.write_bytes(прежние_байты)
        спецификация=importlib.util.spec_from_file_location('прежний_поток_сохранения',старый_путь)
        прежний=importlib.util.module_from_spec(спецификация);спецификация.loader.exec_module(прежний)
        человек={'type':'message','role':'user','content':[{'type':'input_text','text':'Начать'}],'internal_chat_message_metadata_passthrough':{'content_item_kinds':['user.text']}}
        заголовок=сырая_строка('session_meta',{'id':ЗАДАЧА});первый=сырая_строка('response_item',человек)
        части=[{'type':'output_text','text':'Ёж e\u0301 \u0000\b\f\n\r\t \\n \\"'},{'type':'output_text','text':''}]
        for фаза in ('commentary','final','final_answer'):
            ответ={'type':'message','role':'assistant','phase':фаза,'content':части}
            источник.write_bytes(заголовок+первый+сырая_строка('response_item',ответ))
            assert экспортировать_файл(источник,ЗАДАЧА)==прежний.экспортировать_файл(источник,ЗАДАЧА);утверждений+=1
            ответ['internal_chat_message_metadata_passthrough']={'content_item_kinds':['unknown','unknown']}
            последняя=сырая_строка('response_item',ответ);сырые=заголовок+первый+последняя;источник.write_bytes(сырые)
            экспорт,курсор=экспортировать_файл(источник,ЗАДАЧА)
            ожидаемые=[]
            for номер,данные in enumerate((человек,ответ),1):
                состав={'роль':данные['role'],'фаза':данные.get('phase'),'части':данные['content'],'виды_частей':данные['internal_chat_message_metadata_passthrough']['content_item_kinds']}
                байты=канонические_байты(состав)
                ожидаемые.append({'номер':номер,**состав,'происхождение':'человек' if номер==1 else 'ответ ассистента','байтовая_длина':len(байты),'хэш_частей':hashlib.sha256(байты).hexdigest()})
            ожидаемый={'схема':'fum.экспорт-команд.2','идентификатор_задачи':ЗАДАЧА,'сообщения':ожидаемые}
            assert экспорт==канонические_байты(ожидаемый);утверждений+=1
            assert проверить_экспорт(json.loads(экспорт),ЗАДАЧА)==ожидаемые;утверждений+=1
            assert курсор=={'схема':'fum.локальная-граница-диалога.2','идентификатор_задачи':ЗАДАЧА,'хэш_источника':hashlib.sha256(заголовок).hexdigest(),'граница_байтов':len(сырые),'хэш_префикса':hashlib.sha256(сырые).hexdigest(),'позиции':[{'номер':1,'начало':len(заголовок),'конец':len(заголовок+первый)},{'номер':2,'начало':len(заголовок+первый),'конец':len(сырые)}]};утверждений+=1
            источник.write_bytes(сырые+последняя[:-1]);assert экспортировать_файл(источник,ЗАДАЧА,квитанция=курсор)==(экспорт,курсор);утверждений+=1
            источник.write_bytes(сырые+последняя)
            новый,новый_курсор=экспортировать_файл(источник,ЗАДАЧА,квитанция=курсор)
            повтор=json.loads(новый)['сообщения'][-1]
            assert {**повтор,'номер':2}==ожидаемые[-1] and len(новый_курсор['позиции'])==3;утверждений+=1
            assert экспортировать_файл(источник,ЗАДАЧА,квитанция=курсор,закрепить=True)==(экспорт,курсор);утверждений+=1
        утверждений+=смешанный_журнал(корень)
        # Аннотации не меняют роль и не используются как основание человеческих полномочий.
        assert all(с['роль']=='assistant' and с['происхождение']=='ответ ассистента' for с in json.loads(новый)['сообщения'][1:]);утверждений+=1
    print(json.dumps({'проверено_утверждений':утверждений,'прежний_коммит':ПРЕЖНИЙ,'прежний_модуль_sha256':hashlib.sha256(прежние_байты).hexdigest(),'исход':'GREEN','оракул':'stdlib JSON с независимым каноническим экранированием, exact raw SHA/позиции и точные прежние байты для всех видимых фаз'},ensure_ascii=False))


if __name__=='__main__': выполнить()
