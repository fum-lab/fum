"""Одинаковая открытая Native-фикстура; IO и подготовка вынесены за таймер."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import sys

for имя in ('fum-konvejyer-proizvodnyikh-vetok','fum-reyestr-planirovaniya'):
    sys.path.insert(0,str(Path(__file__).resolve().parents[2]/имя/'scripts'))
from фикстура_продолжения_отказа import фикстура, подготовить, КОРНЕВАЯ, ТЕКСТ
import продолжение_отказавшего_приёма as продолжение


def исполнить():
    п=argparse.ArgumentParser(description=__doc__);п.add_argument('--выход',required=True)
    арг=п.parse_args(); результаты={}
    for вид in ('direct','saved-wrapper'):
        ф=фикстура(обёртка=вид=='saved-wrapper')
        ф['строки'][2:2]=[{'type':'response_item','payload':{'type':'message','role':'assistant',
            'content':[{'type':'output_text','text':'Открытые данные профиля ё. '*128}]}} for _ in range(256)]
        # Дополненный источник получает настоящий локатор CLI, а не индекс фикстуры.
        raw=подготовить(ф);позиция=len(ф['префикс'])
        from фикстура_продолжения_отказа import строка
        for с in ф['строки']:
            б=строка(с)
            if с.get('payload',{}).get('type')=='item_completed':
                ф['цель'].update(начало=позиция,конец=позиция+len(б),sha256=hashlib.sha256(б).hexdigest())
            позиция+=len(б)
        серии=[]
        for _ in range(7):
            профиль={}
            р=продолжение.проверить(raw,ф['остановка'],КОРНЕВАЯ,ТЕКСТ,ф['send'],ф['wait'],ф['цель'],
                вид=вид,канал=ф['канал'],артефакт=ф['артефакт'],профиль=профиль)
            assert р['отказ']['исход_прежнего_слияния']=='unknown' and р['повтор_эффекта_разрешён'] is False
            серии.append(профиль)
        результаты[вид]={'байты':len(raw),'строки':len(raw.splitlines()),'источник_sha256':hashlib.sha256(raw).hexdigest(),
            'серии':серии,'медианы_нс':{к:int(statistics.median(с[к] for с in серии)) for к in серии[0]}}
    выход={'схема':'fum.профиль-продолжения-отказа.1','граница':'чистое сопоставление открытой фикстуры без FS/Git, ROOT и создания терминала',
        'повторов':7,'варианты':результаты}
    with Path(арг.выход).open('x',encoding='utf-8') as ф:json.dump(выход,ф,ensure_ascii=False,sort_keys=True,indent=2);ф.write('\n')
    print(json.dumps({к:в['медианы_нс'] for к,в in результаты.items()},ensure_ascii=False))


if __name__=='__main__':исполнить()
