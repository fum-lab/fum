#!/usr/bin/env python3
"""Малый профиль свежих процессов на сохранённой синтетике; реальную эксплуатацию не измеряет."""
import argparse
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import resource
import subprocess
import sys
import time

sys.dont_write_bytecode = True
КОРЕНЬ = Path(__file__).resolve().parent


def нагрузка(сценарий, размер):
    вход = json.loads((КОРЕНЬ / 'фикстуры/снимок.json').read_bytes())
    события = [json.loads(строка) for строка in вход['источники'][0]['данные'].splitlines()]
    if сценарий == 'конфликт':
        прототип = next(с for с in события if с['ид'] == 'ОБЯЗАТЕЛЬСТВО')
        события = []
        for номер in range(размер):
            событие = copy.deepcopy(прототип)
            событие.update(ид=f'ОБ-{номер}', порядок=номер+1, тезис=f'Различный тезис {номер}', подробности='')
            события.append(событие)
        вход['источники'] = вход['источники'][:1]
    elif сценарий != 'эталон':
        raise ValueError('неизвестный сценарий')
    источник = вход['источники'][0]
    сырьё = ''.join(json.dumps(с, ensure_ascii=False, sort_keys=True, separators=(',', ':'))+'\n' for с in события)
    источник.update(данные=сырьё, байты=len(сырьё.encode()), хэш=hashlib.sha256(сырьё.encode()).hexdigest())
    вход['бюджет_байт'] = 100000000 if сценарий == 'эталон' else 0
    return (json.dumps(вход, ensure_ascii=False, sort_keys=True, separators=(',', ':'))+'\n').encode()


def один(сценарий, размер):
    описание = importlib.util.spec_from_file_location('сборщик', КОРЕНЬ / 'сборщик.py')
    модуль = importlib.util.module_from_spec(описание); описание.loader.exec_module(модуль)
    вход = нагрузка(сценарий, размер)
    метки = []
    начало = time.perf_counter_ns()
    результат = модуль.собрать(вход, метки)
    расчёт = time.perf_counter_ns()
    выход = модуль.байты(результат)
    конец = time.perf_counter_ns()
    if сценарий == 'конфликт':
        assert результат['незавершённые_обязательства'] == [f'ОБ-{номер}' for номер in range(размер)]
        assert all(з['состояние']=='противоречие' for з in результат['записи'])
    else:
        assert результат['незавершённые_обязательства'] == ['ОБЯЗАТЕЛЬСТВО', 'ДУБЛЬ', 'ИСТОРИЯ']
        assert next(з for з in результат['записи'] if з['ид']=='РАЗРЕШЕНИЕ')['состояние']=='отменено'
    # ru_maxrss — максимум всего свежего worker, включая подготовку; не дельта функции.
    множитель = 1 if sys.platform == 'darwin' else 1024
    память = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * множитель
    return {'сценарий':сценарий,'размер':размер,'вход_байт':len(вход),'выход_байт':len(выход),
            'хэш_входа':hashlib.sha256(вход).hexdigest(), 'хэш_выхода':hashlib.sha256(выход).hexdigest(),
            'сборка_нс':расчёт-начало,'сериализация_нс':конец-расчёт,'пик_памяти_байт':память,'этапы':метки,
            'эталон_сохранён':True}


def основная():
    разбор=argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--один', choices=('эталон','конфликт'))
    разбор.add_argument('--размер', type=int, default=1)
    разбор.add_argument('--выход', type=Path)
    аргументы=разбор.parse_args()
    if аргументы.один:
        print(json.dumps(один(аргументы.один, аргументы.размер),ensure_ascii=False)); return
    if аргументы.выход is None: разбор.error('нужен --выход')
    # Полный независимый эталон обязан пройти до измерений.
    subprocess.run([sys.executable,'-B','-m','unittest','discover','-s',str(КОРЕНЬ/'tests'),'-p','test_*.py'],check=True)
    попытки=[]
    for сценарий, размер in [('эталон',1),('конфликт',20),('конфликт',100),('конфликт',400)]:
        for повтор in range(3):
            начало=time.perf_counter_ns()
            процесс=subprocess.run([sys.executable,'-B',str(Path(__file__).resolve()),'--один',сценарий,'--размер',str(размер)],check=True,capture_output=True)
            длительность=time.perf_counter_ns()-начало
            измерение=json.loads(процесс.stdout); измерение.update(повтор=повтор+1, процесс_нс=длительность)
            попытки.append(измерение)
    отчёт={'схема':'fum.профиль-синтетического-контекста.1','версия_интерпретатора':platform.python_version(),'система':platform.system(),
           'источники':{имя:hashlib.sha256((КОРЕНЬ/имя).read_bytes()).hexdigest() for имя in ['сборщик.py','собрать-контекст.py','профиль.py','фикстуры/снимок.json','фикстуры/эталон.json','tests/test_сборщик.py']},
           'условия':'Свежий Python-процесс каждого повтора; кэш ОС не очищается; прочая нагрузка хоста не контролируется.',
           'область_пика_памяти':'Пик целого worker, включая импорт и подготовку. Байты; ru_maxrss Darwin либо KiB Linux ×1024.',
           'время_область':'Вложенные разбор/вычисление/упаковка входят в сборку; сериализация измерена отдельно. Процесс включает запуск и подготовку; интервалы не суммируются повторно.',
           'неизвестно':['токены модели','лимиты аккаунта','экономия реального восстановления','живые 0177/0160'],
           'попытки':попытки}
    аргументы.выход.write_text(json.dumps(отчёт,ensure_ascii=False,sort_keys=True,indent=2)+'\n')


if __name__=='__main__':
    основная()
