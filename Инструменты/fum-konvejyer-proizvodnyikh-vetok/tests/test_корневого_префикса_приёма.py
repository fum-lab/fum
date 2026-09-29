"""Граница прежнего ROOT не может скрыть незавершённый выбранный вызов."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from фикстура_двух_до_записи import первичный_вызов
from test_запуска_слоёв import строка, ЗАДАЧА
import нативные_вызовы as поток

РЕБЁНОК = '77777777-7777-4777-8777-777777777777'


class ПроверкаКорневогоПрефикса(unittest.TestCase):
    def test_выбранное_ожидание_пересекающее_границу_отвергается(сам):
        with tempfile.TemporaryDirectory() as временное:
            путь=Path(временное).resolve()/'root.jsonl'
            заголовок=строка({'type':'session_meta','payload':{'id':ЗАДАЧА}})
            завершённый_вызов=первичный_вызов('wait_threads','wait-старый',
                {'targets':[{'threadId':РЕБЁНОК}]}, {'isError':False,'content':[]}, 10)
            начатый_вызов=json.loads(json.dumps(завершённый_вызов)); начатый_вызов['payload']['type']='item_started'
            прежний_префикс=заголовок+строка(начатый_вызов); полные_байты=прежний_префикс+строка(завершённый_вызов)
            путь.write_bytes(полные_байты)
            прежнее_описание={'путь':str(путь),'начало':len(заголовок),'начало_sha256':hashlib.sha256(заголовок).hexdigest(),
                'граница':len(прежний_префикс),'sha256':hashlib.sha256(прежний_префикс).hexdigest()}
            полное_описание=dict(прежнее_описание,граница=len(полные_байты),sha256=hashlib.sha256(полные_байты).hexdigest())
            сам.assertEqual(1,len(поток.прочитать(полное_описание,ЗАДАЧА,ожидания=[РЕБЁНОК],интервалы=True)['ожидания']))
            with сам.assertRaisesRegex(ValueError,'Незавершённый'):
                поток.прочитать_префикс(прежнее_описание,ЗАДАЧА,ожидания=[РЕБЁНОК],интервалы=True)
            with сам.assertRaisesRegex(ValueError,'точный завершённый'):
                поток.прочитать(прежнее_описание,ЗАДАЧА,ожидания=[РЕБЁНОК],интервалы=True)


if __name__ == '__main__': unittest.main()
