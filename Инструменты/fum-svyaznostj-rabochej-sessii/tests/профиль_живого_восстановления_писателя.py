"""Три свежих процесса локального протокола; сеть и подготовка не измеряются."""
import argparse
import hashlib
import json
from pathlib import Path
import resource
import subprocess
import sys
import tempfile
import time
import tracemalloc

sys.path.insert(0,str(Path(__file__).resolve().parent))
from test_живое_восстановление_писателя import Стенд, КАТАЛОГ


def дочерний(папка):
    с=Стенд.загрузить(папка)
    tracemalloc.start();начало_измерения=time.monotonic_ns();п={}
    итог=с.выполнить(п);первый=time.monotonic_ns()-начало_измерения
    до={ф.name:(ф.read_bytes(),ф.stat().st_ino,ф.stat().st_mtime_ns) for ф in с.хранилище.iterdir()}
    с.вызовы.clear();начало_измерения=time.monotonic_ns();повтор={};с.выполнить(повтор);второй=time.monotonic_ns()-начало_измерения
    _,пик=tracemalloc.get_traced_memory();tracemalloc.stop()
    assert п['отправок_инструментов']==1 and повтор['отправок_инструментов']==0 and not с.вызовы,итог
    assert до=={ф.name:(ф.read_bytes(),ф.stat().st_ino,ф.stat().st_mtime_ns) for ф in с.хранилище.iterdir()}
    print(json.dumps({'первый_нс':первый,'повтор_нс':второй,'стадии':п,'стадии_повтора':повтор,
        'пик_памяти_интерпретатора_байты':пик,'максимальная_резидентная_память_как_возвращает_ОС':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'сеть':'не выполнялась','исход':итог['действие']},ensure_ascii=False))


def главная():
    разбор=argparse.ArgumentParser(description=__doc__);разбор.add_argument('--выход');разбор.add_argument('--дочерний');п=разбор.parse_args()
    if п.дочерний:дочерний(п.дочерний);return
    if not п.выход:разбор.error('нужен новый --выход')
    файлы=[КАТАЛОГ/'scripts/живое_восстановление_писателя.py',КАТАЛОГ/'scripts/мост_живого_восстановления_писателя.cjs',
        Path(__file__).with_name('test_живое_восстановление_писателя.py'),Path(__file__).resolve()]
    хэши=lambda:{ф.name:hashlib.sha256(ф.read_bytes()).hexdigest() for ф in файлы}
    до=хэши();записи=[]
    with tempfile.TemporaryDirectory(prefix='fum-live-profile-') as папка:
        for номер in range(3):
            путь=Path(папка)/str(номер);путь.mkdir();с=Стенд(путь);с.сохранить_стенд()
            р=subprocess.run([sys.executable,'-B',str(Path(__file__).resolve()),'--дочерний',str(путь)],capture_output=True,timeout=180)
            if р.returncode:raise RuntimeError(р.stderr.decode())
            записи.append(json.loads(р.stdout))
    assert до==хэши(),'изменились исходники'
    итог={'схема':'fum.профиль-живого-восстановления.1','повторы':записи,'исходники_sha256':до,
        'граница':'Setup, запуск интерпретатора и запись JSON исключены. Стадии вложены в первый интервал; повторно не складываются. Кэш ОС не очищался. Локальный управляемый транспорт, не production-сеть.'}
    with Path(п.выход).open('x') as ф:json.dump(итог,ф,ensure_ascii=False,indent=2);ф.write('\n')
    print(json.dumps({'повторов':len(записи),'отправок':sum(з['стадии']['отправок_инструментов'] for з in записи),
        'повторных_отправок':sum(з['стадии_повтора']['отправок_инструментов'] for з in записи)},ensure_ascii=False))


if __name__=='__main__':главная()
