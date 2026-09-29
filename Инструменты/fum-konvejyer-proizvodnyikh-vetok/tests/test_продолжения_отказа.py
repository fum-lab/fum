"""Старый отказ, чужой postwait и переставленные события не закрывают новый ход."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest

for имя in ('fum-konvejyer-proizvodnyikh-vetok', 'fum-reyestr-planirovaniya'):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / имя / 'scripts'))
from фикстура_продолжения_отказа import фикстура, подготовить, строка, транспорт, КОРНЕВАЯ, ТЕКСТ, ПРЕЖНИЙ
import продолжение_отказавшего_приёма as продолжение


class ПроверкаПродолженияОтказа(unittest.TestCase):
    def проверить(self, ф, *, сырые=None):
        return продолжение.проверить(подготовить(ф) if сырые is None else сырые,
            ф['остановка'], КОРНЕВАЯ, ТЕКСТ, ф['send'], ф['wait'], ф['цель'],
            вид='saved-wrapper' if ф['канал'] is not None else 'direct',
            канал=ф['канал'], артефакт=ф['артефакт'])

    def test_новый_direct_и_обёртка_связаны_с_собственным_конечным_ходом(self):
        for обёртка in (False, True):
            with self.subTest(обёртка=обёртка):
                ф=фикстура(обёртка=обёртка); сырые=подготовить(ф); до=copy.deepcopy(ф)
                р=self.проверить(ф, сырые=сырые)
                self.assertEqual(ПРЕЖНИЙ, р['прежний_ход'])
                self.assertEqual(ф['цель']['ход'], р['ход'])
                self.assertEqual(ф['send']['id'], р['отправка']['id'])
                self.assertEqual(ф['wait']['id'], р['ожидание']['id'])
                self.assertEqual('unknown', р['отказ']['исход_прежнего_слияния'])
                self.assertFalse(р['повтор_эффекта_разрешён'])
                self.assertEqual(до, ф)

    def test_подмена_первоначального_префикса_и_границы_строки_отклоняются(self):
        for поле, значение in (('sha256','0'*64),('граница',True),('граница',1)):
            with self.subTest(поле=поле,значение=значение):
                ф=фикстура(); ф['остановка'][поле]=значение
                with self.assertRaises(ValueError):self.проверить(ф)

    def test_отказ_из_старого_хода_не_подтверждает_новое_завершение(self):
        ф=фикстура(); ф['цель']['ход']=ПРЕЖНИЙ
        for с in (ф['строки'][0],ф['строки'][2],ф['строки'][3]):с['payload']['turn_id']=ПРЕЖНИЙ
        item=ф['wait']['ответ']['content'][0]; ответ=json.loads(item['text'])
        ответ['polls'][0]['latestTurn']['id']=ПРЕЖНИЙ;item['text']=json.dumps(ответ)
        with self.assertRaisesRegex(ValueError,'прежнему'):self.проверить(ф)

    def test_чужие_настройки_после_прежней_остановки_не_пропускаются(self):
        ф=фикстура(); ф['префикс']+=строка({'type':'event_msg','payload':{
            'type':'thread_settings_applied','thread_id':КОРНЕВАЯ,'thread_settings':{'cwd':'/иной/корень'}}})
        ф['остановка'].update(граница=len(ф['префикс']),sha256=hashlib.sha256(ф['префикс']).hexdigest())
        with self.assertRaisesRegex(ValueError,'настройки'):self.проверить(ф)

    def test_несовпадающий_или_незавершённый_latestTurn_закрывает_допуск(self):
        for поле,значение in (('id',ПРЕЖНИЙ),('status','inProgress'),('error',{'message':'ошибка'})):
            with self.subTest(поле=поле):
                ф=фикстура(); item=ф['wait']['ответ']['content'][0]; ответ=json.loads(item['text'])
                ответ['polls'][0]['latestTurn'][поле]=значение; item['text']=json.dumps(ответ)
                with self.assertRaises(ValueError):self.проверить(ф)

    def test_повторный_транспорт_и_другое_поручение_не_принимаются(self):
        for изменение in ('повтор','текст','отправитель','handoff'):
            with self.subTest(изменение=изменение):
                ф=фикстура(); д=ф['строки'][1]['payload']
                if изменение=='повтор':ф['строки'].append(copy.deepcopy(ф['строки'][1]))
                elif изменение=='текст':д['output']=транспорт('send_message_to_thread','Иное поручение')['payload']['output']
                elif изменение=='отправитель':д['output']=д['output'].replace(КОРНЕВАЯ,ПРЕЖНИЙ)
                else:д['name']='handoff_thread'
                with self.assertRaises(ValueError):self.проверить(ф)

    def test_получение_и_конец_должны_окружать_именно_свой_cli(self):
        for изменение in ('до-получения','после-конца'):
            with self.subTest(изменение=изменение):
                ф=фикстура(); raw=подготовить(ф)
                if изменение=='до-получения':
                    ф['строки'][1],ф['строки'][2]=ф['строки'][2],ф['строки'][1]
                else:ф['строки'][2],ф['строки'][3]=ф['строки'][3],ф['строки'][2]
                raw=ф['префикс']+b''.join(map(строка,ф['строки']))
                # Новый корректный локатор не должен скрыть перестановку событий.
                позиция=len(ф['префикс'])
                for с in ф['строки']:
                    б=строка(с)
                    if с.get('payload',{}).get('type')=='item_completed':
                        ф['цель'].update(начало=позиция,конец=позиция+len(б),sha256=hashlib.sha256(б).hexdigest())
                    позиция+=len(б)
                with self.assertRaises(ValueError):self.проверить(ф,сырые=raw)

    def test_чужой_send_и_многоадресный_wait_не_становятся_своими(self):
        for изменение in ('send-адрес','send-текст','wait-адрес','общий-wait','ошибка-wait'):
            with self.subTest(изменение=изменение):
                ф=фикстура()
                if изменение=='send-адрес':ф['send']['аргументы']['threadId']=КОРНЕВАЯ
                elif изменение=='send-текст':ф['send']['аргументы']['prompt']='Иное поручение'
                elif изменение=='wait-адрес':ф['wait']['аргументы']['targets'][0]['threadId']=КОРНЕВАЯ
                elif изменение=='общий-wait':ф['wait']['аргументы']['targets'].append({'threadId':КОРНЕВАЯ})
                else:ф['wait']['ответ']['isError']=True
                with self.assertRaises(ValueError):self.проверить(ф)

    def test_несовместимые_runtime_интервалы_не_принимаются(self):
        for изменение in ('ранний-cli','поздний-cli','обратный-wait','обратный-send'):
            with self.subTest(изменение=изменение):
                ф=фикстура()
                if изменение=='ранний-cli':ф['строки'][2]['payload']['started_at_ms']=4
                elif изменение=='поздний-cli':ф['строки'][2]['payload']['completed_at_ms']=31
                elif изменение=='обратный-wait':ф['wait']['интервал']['конец_мс']=8
                else:ф['send']['интервал']['конец_мс']=4
                with self.assertRaises(ValueError):self.проверить(ф)

    def test_второй_завершённый_ход_и_отсутствие_конца_не_принимаются(self):
        for изменение in ('лишний-конец','нет-конца','другое-начало'):
            with self.subTest(изменение=изменение):
                ф=фикстура()
                if изменение=='лишний-конец':ф['строки'].append(copy.deepcopy(ф['строки'][3]))
                elif изменение=='нет-конца':ф['строки'].pop()
                else:ф['строки'][0]['payload']['turn_id']=ПРЕЖНИЙ
                with self.assertRaises(ValueError):self.проверить(ф)

    def test_приватный_канал_не_подменяет_неподходящий_вид_читателя(self):
        ф=фикстура(обёртка=True); raw=подготовить(ф)
        with self.assertRaises(ValueError):
            продолжение.проверить(raw,ф['остановка'],КОРНЕВАЯ,ТЕКСТ,ф['send'],ф['wait'],ф['цель'],
                вид='direct',канал=ф['канал'],артефакт=ф['артефакт'])


if __name__=='__main__':unittest.main()
