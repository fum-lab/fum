"""Цена проверки переноса ROOT на двух допустимых native-началах."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time

import test_происхождения_писателя_генератора as примеры


def образец(вариант):
    пример = примеры.ПроисхождениеПисателя('test_перенос_ROOT_проходит_вторую_корневую_фазу')
    начало = time.monotonic_ns()
    try:
        пример.setUp()
        if вариант=='текущий':
            for н in (0,1): пример.ф.ф.события[н]['payload']['cwd'] = str(пример.ф.корень)
            пример.обновить_источник()
        подготовлен = time.monotonic_ns(); счётчики = {}
        имена = {'проверить_структуру','прочитать_начало_источника','_прочитать_поток'}
        def наблюдение(кадр,событие,значение):
            имя = кадр.f_code.co_name
            if событие=='call' and имя in имена: счётчики[имя] = счётчики.get(имя,0)+1
        прежний = sys.getprofile(); sys.setprofile(наблюдение)
        try: план = пример.м.построить_план(пример.вход)
        finally: sys.setprofile(прежний)
        конец = time.monotonic_ns()
        основание = план['снимок']['основание_переноса']
        return {'вариант':вариант,'подготовка_нс':подготовлен-начало,'план_нс':конец-подготовлен,
            'вызовы_читателей':счётчики,'входов_правила':len(основание['входы']) if основание else 0,
            'план_байтов':len(пример.м.байты(план)),'код':0,
            'смысл_sha256':пример.м.хэш(пример.п.решение['постановка']['текст'].encode())}
    finally: пример.doCleanups()


def главная():
    р = argparse.ArgumentParser(description=__doc__,allow_abbrev=False)
    г = р.add_mutually_exclusive_group(required=True)
    г.add_argument('--образец',choices=('текущий','перемещённый')); г.add_argument('--выход')
    п = р.parse_args()
    if п.образец:
        print(json.dumps(образец(п.образец),ensure_ascii=False)); return 0
    выход = Path(п.выход)
    if not выход.is_absolute() or выход!=выход.resolve() or os.path.lexists(выход):
        raise ValueError('нужен новый абсолютный приватный выход')
    наблюдения = []
    for н in range(3):
        for вариант in (('текущий','перемещённый') if н%2==0 else ('перемещённый','текущий')):
            процесс = subprocess.run([sys.executable,'-B',str(Path(__file__).resolve()),'--образец',вариант],
                capture_output=True,text=True,cwd=Path.cwd(),check=True)
            наблюдения.append(json.loads(процесс.stdout))
    if len({н['смысл_sha256'] for н in наблюдения})!=1: raise ValueError('разный смысл профиля')
    итог = {'схема':'fum.профиль-происхождения-писателя.1','наблюдения':наблюдения,
        'медианы_плана_нс':{в:statistics.median(н['план_нс'] for н in наблюдения if н['вариант']==в)
            for в in ('текущий','перемещённый')},
        'сценарий_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'граница':'Каждый образец в новом процессе. Одинаковое смысловое решение, два допустимых native-начала с разным cwd и сырыми байтами. План — отдельный интервал после подготовки фикстуры и кэша; apply, ready, коммит, доставка, cleanup и сериализация не измерены. Счётчики Python-вызовов не доказывают физический I/O. Профиль измеряет цену дополнительной проверки, не ускорение полезной работы.'}
    дескриптор = os.open(выход,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
    with os.fdopen(дескриптор,'w') as поток: json.dump(итог,поток,ensure_ascii=False,sort_keys=True,indent=2); поток.write('\n')
    print(json.dumps({'образцов':len(наблюдения),'медианы_плана_нс':итог['медианы_плана_нс']},ensure_ascii=False)); return 0


if __name__=='__main__':
    raise SystemExit(главная())
