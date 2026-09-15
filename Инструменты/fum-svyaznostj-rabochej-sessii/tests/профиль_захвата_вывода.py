"""Воспроизводимый профиль полного захвата двух независимых бинарных каналов."""
import hashlib
import json
from pathlib import Path
import statistics
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
from захват_вывода import захватить, представить_захват, прочитать_диапазон


def выполнить():
    замеры=[]
    хэши={имя: hashlib.sha256(bytes([номер])*4194304).hexdigest()
          for имя,номер in (('stdout',17),('stderr',29))}
    with tempfile.TemporaryDirectory() as временный:
        корень=Path(временный).resolve()
        for номер in range(5):
            каталог=корень/str(номер)
            начало=time.perf_counter_ns()
            результат=захватить([sys.executable,'-B','-c',
                'import os; os.write(1,bytes([17])*4194304); os.write(2,bytes([29])*4194304)'],
                каталог,корень,'00000000-0000-0000-0000-000000000177')
            сохранён=time.perf_counter_ns()
            хэш=hashlib.sha256((каталог/'манифест.json').read_bytes()).hexdigest()
            ответ=представить_захват(каталог,хэш,16000)
            представлен=time.perf_counter_ns()
            прочитать_диапазон(каталог,хэш,'stderr',1024,256,16000)
            раскрыт=time.perf_counter_ns()
            assert результат['полнота'] and результат['код_процесса']==0
            assert all(результат['каналы'][имя]['sha256']==ожидаемый for имя,ожидаемый in хэши.items())
            замеры.append({'захват_нс':сохранён-начало,'представление_нс':представлен-сохранён,
                'раскрытие_нс':раскрыт-представлен,'выдано_байтов':len(ответ)})
    итог={'схема':'fum.профиль-захвата.1','байтов_на_канал':4194304,'sha256':хэши,
        'замеры':замеры,'медианы':{ключ:statistics.median(з[ключ] for з in замеры)
            for ключ in замеры[0]},'граница':'новый-процесс-два-файла-трасса-fsync-SHA-манифест',
        'токены':None,'получение_моделью':'unknown','ускорение_не_измерено':True}
    print(json.dumps(итог,ensure_ascii=False,sort_keys=True,indent=2))


if __name__=='__main__':
    выполнить()
