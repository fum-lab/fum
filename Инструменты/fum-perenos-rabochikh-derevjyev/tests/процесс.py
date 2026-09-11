"""Отдельный процесс аварийной фикстуры; не является интерфейсом переноса."""
import os
from pathlib import Path
import sys
import time
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import перенос


def прервать(фаза):
    if sys.argv[3]=='ожидать' and фаза=='после-фазы-ремонта':
        Path(os.environ['FUM_FIXTURE_WAIT']).write_text('готово')
        while True: time.sleep(1)
    if фаза == sys.argv[3]:
        os._exit(77)


перенос.контрольная_точка = прервать
if sys.argv[3] in ('до-записи-намерения','после-записи-намерения'):
    исходное_открытие = os.open
    исходная_синхронизация = os.fsync
    дескриптор_намерения = None
    def открыть(путь,*аргументы,**параметры):
        global дескриптор_намерения
        номер = исходное_открытие(путь,*аргументы,**параметры)
        if Path(путь).name=='подготовка.tmp':
            дескриптор_намерения = номер
            if sys.argv[3]=='до-записи-намерения': os._exit(77)
        return номер
    def закрепить(номер):
        исходная_синхронизация(номер)
        if номер==дескриптор_намерения: os._exit(77)
    setattr(os,'open',открыть)
    setattr(os,'fsync',закрепить)
try:
    результат = перенос.применить(перенос.канон.прочитать(Path(sys.argv[1]).read_bytes()), перенос.канон.прочитать(Path(sys.argv[2]).read_bytes()),sys.argv[4])
    print(перенос.канон.кодировать(результат).decode(), end='')
except (ValueError, OSError) as ошибка:
    print(str(ошибка), file=sys.stderr)
    raise SystemExit(2)
