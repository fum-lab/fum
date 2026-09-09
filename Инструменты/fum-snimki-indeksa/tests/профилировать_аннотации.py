"""Малый профиль исправления аннотаций; оптимизация большого журнала не измеряется."""
import argparse
import hashlib
import json
import platform
import sys
import tempfile
import tracemalloc
from pathlib import Path
from time import perf_counter_ns

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from поток_диалога import экспортировать_файл, ЗамерыПотока
from канон import хэш
from test_диалог import ЗАДАЧА, сообщение, строка_события


def выполнить(выход):
    инструмент=Path(__file__).resolve().parents[1]
    версии={п.relative_to(инструмент).as_posix():хэш(п.read_bytes()) for п in sorted(инструмент.rglob('*.py'))}
    результаты=[]
    with tempfile.TemporaryDirectory() as временный:
        файл=Path(временный).resolve()/'публичная-синтетика.jsonl'
        for название,виды in (('без аннотаций',None),('с согласованными аннотациями',['unknown','unknown'])):
            ответ={'type':'message','role':'assistant','phase':'final_answer','content':[{'type':'output_text','text':'Первый ёж'},{'type':'output_text','text':''}]}
            if виды is not None: ответ['internal_chat_message_metadata_passthrough']={'content_item_kinds':виды}
            сырые=строка_события('session_meta',{'id':ЗАДАЧА})+сообщение('user','Начать')+строка_события('response_item',ответ)*100
            файл.write_bytes(сырые)
            длительности=[];наблюдаемый_пик=0;хэши=set()
            for повтор in range(5):
                замеры=ЗамерыПотока();tracemalloc.start();начало=perf_counter_ns()
                экспорт,курсор=экспортировать_файл(файл,ЗАДАЧА,профиль=замеры)
                длительности.append(perf_counter_ns()-начало)
                _,пик=tracemalloc.get_traced_memory();tracemalloc.stop();наблюдаемый_пик=max(наблюдаемый_пик,пик,замеры.пик_памяти)
                хэши.add(хэш(экспорт))
                сообщения=json.loads(экспорт)['сообщения']
                assert len(сообщения)==101 and курсор['хэш_префикса']==хэш(сырые)
                assert all(запись['виды_частей']==виды and запись['части']==ответ['content'] and запись['роль']=='assistant' and запись['происхождение']=='ответ ассистента' for запись in сообщения[1:])
            assert len(хэши)==1
            результаты.append({'случай':название,'raw_байтов':len(сырые),'raw_sha256':хэш(сырые),'экспорт_байтов':len(экспорт),'экспорт_sha256':next(iter(хэши)),'длительности_наносекунд':длительности,'медиана_наносекунд':sorted(длительности)[2],'максимум_наблюдённых_пиков_python_байтов':наблюдаемый_пик,'проверенные_ответы_в_повторе':100})
        assert результаты[0]['экспорт_sha256']!=результаты[1]['экспорт_sha256']
    assert версии=={п.relative_to(инструмент).as_posix():хэш(п.read_bytes()) for п in sorted(инструмент.rglob('*.py'))}
    профиль={'схема':'fum.профиль-аннотаций-ассистента.1','python':platform.python_version(),'платформа':platform.platform(),'версии_файлов':версии,'случаи':результаты,'граница':'Десять малых чтений с tracemalloc, по100 видимых ответов с2частями; файлы только что созданы. Максимум наблюдённых пиков не является полным RSS. Между случаями меняются входные аннотации и выходные байты; это не сравнение скорости эквивалентных алгоритмов. Исполнение не реализовано.'}
    выход.write_text(json.dumps(профиль,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(результаты,ensure_ascii=False))


if __name__=='__main__':
    разбор=argparse.ArgumentParser(description=__doc__);разбор.add_argument('--выход',type=Path,required=True)
    выполнить(разбор.parse_args().выход)
