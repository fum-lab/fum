"""Штатные начальные инструкции не разрешают позднее изменение управления."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import поток_остановленного_писателя as поток
import снимок_нативного_источника as снимок
from фикстура_штатных_событий import служебный_контекст

ЗАДАЧА = '22222222-2222-4222-8222-222222222222'
ХОД = '33333333-3333-4333-8333-333333333333'
БАЗА = 'a' * 40
ГРУППЫ = [
    ['generic.developer_instructions', 'memories.instructions', 'permissions.instructions',
        'collaboration_mode.instructions', 'plugins.recommendations'],
    ['multi_agent.role_instructions'], ['multi_agent.mode_instructions'],
]


def начальная_инструкция(номер):
    виды = ГРУППЫ[номер]
    return {'type': 'response_item', 'payload': {'type': 'message', 'id': 'инструкция-' + str(номер),
        'role': 'developer', 'content': [{'type': 'input_text', 'text': 'Открытая фикстура ' + вид}
            for вид in виды], 'internal_chat_message_metadata_passthrough': {'turn_id': ХОД,
                'create_time': 1790591420.08237, 'content_item_kinds': виды[:]}}}


class ПроверкаНачальногоКонтекстаПисателя(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory(prefix='fum-pervichny-kontekst-')
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.источник = self.корень / 'источник.jsonl'
        self.ожидание = {'ответ': {'content': [{'type': 'text', 'text': json.dumps({'polls': [{
            'thread': {'id': ЗАДАЧА, 'status': {'type': 'idle'}},
            'latestTurn': {'id': ХОД, 'status': 'completed', 'error': None}}]})}]}}

    def записи(self, с_инструкциями=True):
        return [{'type': 'session_meta', 'payload': {'id': ЗАДАЧА, 'cwd': str(self.корень),
                'git': {'commit_hash': БАЗА}}},
            {'type': 'event_msg', 'payload': {'type': 'task_started', 'turn_id': ХОД}},
            *([начальная_инструкция(н) for н in range(3)] if с_инструкциями else []),
            служебный_контекст(), {'type': 'world_state', 'payload': {}},
            {'type': 'turn_context', 'payload': {'turn_id': ХОД, 'cwd': str(self.корень),
                'model': 'gpt-6-sol', 'effort': 'ultra'}},
            {'type': 'response_item', 'payload': {'type': 'function_call_output',
                'name': 'create_thread', 'namespace': 'codex_app', 'output': 'Первоначальное поручение'}},
            {'type': 'event_msg', 'payload': {'type': 'task_complete', 'turn_id': ХОД}}]

    def прочитать(self, записи):
        сырые = b''.join((json.dumps(з, ensure_ascii=False) + '\n').encode() for з in записи)
        self.источник.write_bytes(сырые)
        описание = {'путь': str(self.источник), 'граница': len(сырые),
            'sha256': hashlib.sha256(сырые).hexdigest()}
        return поток.прочитать(описание, ЗАДАЧА, str(self.корень), БАЗА,
            'gpt-6-sol', 'ultra', self.ожидание)

    def test_три_начальные_группы_связаны_с_единственным_ходом(self):
        _, _, ход = self.прочитать(self.записи())
        self.assertEqual(ХОД, ход)

    def test_прежний_поток_без_групп_сохраняется(self):
        self.assertEqual(ХОД, self.прочитать(self.записи(False))[2])

    def test_повреждённые_начальные_группы_закрывают_поток(self):
        исходные = self.записи()
        случаи = []
        копия = copy.deepcopy(исходные); копия[2], копия[3] = копия[3], копия[2]
        случаи.append(('перестановка', копия))
        копия = copy.deepcopy(исходные); del копия[4]
        случаи.append(('неполный блок', копия))
        копия = copy.deepcopy(исходные); копия.insert(5, начальная_инструкция(0))
        случаи.append(('повтор', копия))
        for поле, значение in [('turn_id', ЗАДАЧА), ('create_time', float('nan')),
                ('content_item_kinds', ['user.text'])]:
            копия = copy.deepcopy(исходные)
            копия[2]['payload']['internal_chat_message_metadata_passthrough'][поле] = значение
            случаи.append((поле, копия))
        копия = copy.deepcopy(исходные)
        копия[3]['payload']['internal_chat_message_metadata_passthrough']['user_input_order'] = 1
        случаи.append(('человеческое происхождение', копия))
        копия = copy.deepcopy(исходные); копия[2]['payload']['content'].pop()
        случаи.append(('состав контента', копия))
        копия = copy.deepcopy(исходные); копия[2]['payload']['id'] = ''
        случаи.append(('пустой идентификатор', копия))
        копия = copy.deepcopy(исходные); копия[7]['payload']['turn_id'] = ЗАДАЧА
        случаи.append(('другой первый контекст', копия))
        копия = copy.deepcopy(исходные); копия[3]['payload']['internal_chat_message_metadata_passthrough']['create_time'] += 1
        случаи.append(('другая метка выпуска', копия))
        for имя, записи in случаи:
            with self.subTest(имя=имя), self.assertRaises(ValueError):
                self.прочитать(записи)

    def test_поздняя_инструкция_и_новый_ввод_закрывают_поток(self):
        for позиция in (5, 7, 9):
            копия = self.записи(); копия.insert(позиция, начальная_инструкция(0))
            with self.subTest(позиция=позиция), self.assertRaises(ValueError):
                self.прочитать(копия)
        копия = self.записи(); копия.insert(-1, служебный_контекст())
        with self.assertRaises(ValueError):
            self.прочитать(копия)

    def test_фильтр_хвоста_по_прежнему_отклоняет_инструкцию(self):
        with self.assertRaises(ValueError):
            снимок.проверить_запись(начальная_инструкция(0))


if __name__ == '__main__':
    unittest.main()
