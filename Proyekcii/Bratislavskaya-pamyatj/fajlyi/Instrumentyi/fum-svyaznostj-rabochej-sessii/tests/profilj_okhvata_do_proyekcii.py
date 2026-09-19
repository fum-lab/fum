"""Измерить ранний отказ на открытой Git-фикстуре; полная приёмка не запускается."""
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time
import test_ранний_охват as основа


def выполнить():
    фикстура = основа.ПроверкаОхвата()
    фикстура.setUp()
    try:
        корень = фикстура.корень
        материалы = корень/'материалы';материалы.mkdir()
        for номер in range(200): (материалы/f'{номер}.json').write_text('{}\n')
        фикстура.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Материалы](../../материалы)')
        реестр=корень/'реестр.json';реестр.write_text('{}\n')
        def снимок():
            файлы={str(p.relative_to(корень)):hashlib.sha256(p.read_bytes()).hexdigest() for p in корень.rglob('*') if p.is_file() and '.git' not in p.parts}
            return {'файлы':файлы,'status':фикстура.git('status','--porcelain=v1','-z').hex()}
        до=снимок();замеры=[];выводы=[]
        скрипт=основа.ПУТЬ.with_name('проверить-охват-запроса.py')
        for _ in range(3):
            начало=time.monotonic_ns()
            p=subprocess.run([sys.executable,'-B',str(скрипт),'--корень',str(корень),'--запрос',str(фикстура.запрос.relative_to(корень))],capture_output=True)
            замеры.append(time.monotonic_ns()-начало)
            assert p.returncode==1,p.stderr
            результат=json.loads(p.stdout)
            assert результат['ошибки']==['unexpected Git status path: реестр.json'],результат
            выводы.append(p.stdout)
        assert снимок()==до
        assert len(set(выводы))==1
        print(json.dumps({'схема':'fum.профиль-охвата.1','файлов':len(до['файлы']),'замеры_ns':замеры,'медиана_ns':statistics.median(замеры),'вход_неизменен':True,'результат':'непокрытый реестр отклонён','вывод_sha256':hashlib.sha256(выводы[0]).hexdigest(),'скрипт_sha256':hashlib.sha256(скрипт.read_bytes()).hexdigest(),'граница':'Весь отдельный Python CLI с импортами и Git; создание фикстуры и проверка неизменности вне таймера. Без проекции и без сравнения общего цикла.'},ensure_ascii=False,sort_keys=True))
    finally:
        фикстура.doCleanups()


if __name__=='__main__':
    выполнить()
