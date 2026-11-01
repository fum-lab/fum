"""Настройки Desktop после завершения не являются новым ходом агента."""
import copy
import json
import unittest

from фикстура_остановленного_поколения import остановленное_поколение
from фикстура_раздельных_ожиданий import разделить
from test_завершения_запуска import граница, строка
import остановка_ребёнка
import завершение_сохранённых_писателей as завершение


ЗАДАЧА = '00000000-0000-4000-8000-000000000011'
ХОД = '00000000-0000-4000-8000-000000000012'
КОРЕНЬ = '/tmp/фикстура-писателя'


def настройка(задача=ЗАДАЧА, корень=КОРЕНЬ):
    return {'type': 'event_msg', 'payload': {'type': 'thread_settings_applied',
        'thread_id': задача, 'thread_settings': {'cwd': корень, 'model': 'gpt-6-astra', 'reasoning_effort': 'low'}}}


class ПроверкаНастроекПослеОстановки(unittest.TestCase):
    def setUp(self):
        self.записи = [{'type': 'event_msg', 'payload': {'type': 'task_complete', 'turn_id': ХОД}}]
        self.ожидание = {'ответ': {'content': [{'type': 'text', 'text': json.dumps({'polls': [
            {'thread': {'id': ЗАДАЧА, 'status': {'type': 'idle'}},
             'latestTurn': {'id': ХОД, 'status': 'completed', 'error': None}}]})}]}}

    def test_настройки_после_завершения_разрешены_только_новому_входу(self):
        записи = self.записи + [настройка(), настройка()]
        self.assertEqual(ХОД, остановка_ребёнка.подтвердить_ход(записи, ЗАДАЧА, self.ожидание, True, корень=КОРЕНЬ))
        with self.assertRaisesRegex(ValueError, 'конечной остановки'):
            остановка_ребёнка.подтвердить_ход(записи, ЗАДАЧА, self.ожидание)

    def test_любая_другая_активность_после_остановки_запрещена(self):
        for тип in ('task_started', 'item_started', 'item_completed', 'agent_message', 'turn_aborted', 'unknown'):
            for позиция in range(3):
                хвост = [настройка(), настройка()]
                хвост.insert(позиция, {'type': 'event_msg', 'payload': {'type': тип}})
                with self.subTest(тип=тип, позиция=позиция), self.assertRaises(ValueError):
                    остановка_ребёнка.подтвердить_ход(self.записи + хвост, ЗАДАЧА, self.ожидание, True, корень=КОРЕНЬ)

    def test_чужая_повреждённая_или_неоднозначная_настройка_запрещена(self):
        образцы = [настройка(ХОД), настройка(), настройка(), настройка(), настройка(корень='/tmp/чужой'), настройка()]
        образцы[1]['payload']['thread_settings'] = []
        образцы[2]['payload']['лишнее'] = 'данные'
        образцы[3]['type'] = 'response_item'
        del образцы[5]['payload']['thread_settings']['cwd']
        for запись in образцы:
            with self.subTest(запись=запись), self.assertRaises(ValueError):
                остановка_ребёнка.подтвердить_ход(self.записи + [запись], ЗАДАЧА, self.ожидание, True, корень=КОРЕНЬ)
        with self.assertRaises(ValueError):
            остановка_ребёнка.подтвердить_ход([настройка()], ЗАДАЧА, self.ожидание, True, корень=КОРЕНЬ)

    def test_настройки_не_заменяют_совпадение_последнего_хода(self):
        ожидание = copy.deepcopy(self.ожидание)
        ответ = json.loads(ожидание['ответ']['content'][0]['text'])
        ответ['polls'][0]['latestTurn']['id'] = ЗАДАЧА
        ожидание['ответ']['content'][0]['text'] = json.dumps(ответ)
        with self.assertRaises(ValueError):
            остановка_ребёнка.подтвердить_ход(self.записи + [настройка()], ЗАДАЧА, ожидание, True, корень=КОРЕНЬ)

    def test_реестр_принимает_точный_живой_хвост_настроек(self):
        with остановленное_поколение() as (_, объект, _, _, вход, события, _):
            разделить(вход, события)
            from pathlib import Path
            for слой in вход['слои'].values():
                путь = Path(слой['источник']['путь'])
                with путь.open('ab') as поток:
                    поток.write(строка(настройка(слой['задача'], слой['корень'])))
                слой['источник'] = граница(путь)
            до = объект.хранилище.путь.read_bytes()
            результат = завершение.предпросмотр(объект, вход)
            self.assertEqual(до, объект.хранилище.путь.read_bytes())
            self.assertEqual(результат, завершение.завершить(объект, вход, результат['sha256']))


if __name__ == '__main__':
    unittest.main()
