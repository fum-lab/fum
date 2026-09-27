"""Не терять видимый текст и не экспортировать внутренние фазы native JSONL."""
import hashlib
import importlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

СКРИПТЫ = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(СКРИПТЫ))
ЗАДАЧА = '00000000-0000-4000-8000-000000000001'


class ПроверкаВидимыхОтветов(unittest.TestCase):
    def setUp(сам):
        try:
            сам.читатель = importlib.import_module('видимые_ответы')
        except ModuleNotFoundError as ошибка:
            сам.fail('Канонический читатель отсутствует: ' + str(ошибка))

    def сообщение(сам, текст='ё🙂', **разметка):
        return {'type': 'response_item', 'payload': {
            'type': 'message', 'role': 'assistant',
            'content': [{'type': 'output_text', 'text': текст}], **разметка}}

    def байты(сам, *записи):
        начало = {'type': 'session_meta', 'payload': {'id': ЗАДАЧА}}
        return b''.join((json.dumps(з, ensure_ascii=False) + '\n').encode('utf-8')
                        for з in (начало, *записи))

    def прочитать(сам, *записи):
        return сам.читатель.извлечь(сам.байты(*записи), ЗАДАЧА)

    def test_phase_сохраняет_все_видимые_фазы(сам):
        итог = сам.прочитать(*(сам.сообщение(ф, phase=ф) for ф in ('commentary', 'final', 'final_answer')))
        сам.assertEqual([о['части'] for о in итог['ответы']], [['commentary'], ['final'], ['final_answer']])
        сам.assertTrue(итог['полнота_поддержанных_ответов'])
        сам.assertEqual(итог['состояние'], 'сохранены')

    def test_channel_при_отсутствующем_или_null_phase(сам):
        итог = сам.прочитать(сам.сообщение(channel='commentary'), сам.сообщение(phase=None, channel='final'))
        сам.assertEqual(len(итог['ответы']), 2)
        сам.assertEqual([о['поле_фазы'] for о in итог['ответы']], ['channel', 'channel'])

    def test_внутренняя_фаза_не_раскрывается_через_channel(сам):
        итог = сам.прочитать(сам.сообщение('НЕ ЭКСПОРТИРОВАТЬ', phase='analysis', channel='commentary'))
        сам.assertFalse(итог['полнота_поддержанных_ответов'])
        сам.assertEqual(итог['ответы'], [])
        сам.assertNotIn('НЕ ЭКСПОРТИРОВАТЬ', json.dumps(итог, ensure_ascii=False))

    def test_неизвестная_и_противоречивая_разметка_явно_неполны(сам):
        for разметка in ({}, {'phase': 'future'}, {'phase': []},
                        {'phase': 'final', 'channel': 'commentary'}):
            with сам.subTest(разметка=разметка):
                итог = сам.прочитать(сам.сообщение('СКРЫТО', **разметка))
                сам.assertFalse(итог['полнота_поддержанных_ответов'])
                сам.assertEqual(итог['состояние'], 'неполно')
                сам.assertEqual(len(итог['неопределённости']), 1)
                сам.assertNotIn('СКРЫТО', json.dumps(итог, ensure_ascii=False))

    def test_эквивалентные_имена_финала_не_противоречат(сам):
        итог = сам.прочитать(сам.сообщение(phase='final', channel='final_answer'))
        сам.assertTrue(итог['полнота_поддержанных_ответов'])
        сам.assertEqual(итог['ответы'][0]['поле_фазы'], 'phase')

    def test_байтовые_диапазоны_порядок_повторы_и_части(сам):
        запись = сам.сообщение('а\nё🙂', phase='commentary')
        запись['payload']['content'].append({'type': 'output_text', 'text': '  конец\n'})
        сырые = сам.байты(запись, запись)
        итог = сам.читатель.извлечь(сырые, ЗАДАЧА)
        сам.assertEqual(итог['источник'], {'задача': ЗАДАЧА, 'граница': len(сырые), 'sha256': hashlib.sha256(сырые).hexdigest()})
        сам.assertEqual(len(итог['ответы']), 2)
        границы = []
        for ответ in итог['ответы']:
            источник = ответ['исходник']
            кусок = сырые[источник['начало']:источник['конец']]
            сам.assertTrue(кусок.endswith(b'\n'))
            сам.assertEqual(hashlib.sha256(кусок).hexdigest(), источник['sha256'])
            сам.assertEqual(ответ['сырая_строка'].encode('utf-8'), кусок)
            сам.assertEqual(ответ['части'], ['а\nё🙂', '  конец\n'])
            границы.append(источник['начало'])
        сам.assertLess(*границы)

    def test_события_инструменты_пользователь_и_analysis_не_дублируются(сам):
        записи = [
            {'type': 'event_msg', 'payload': {'type': 'agent_message', 'message': 'Видно'}},
            {'type': 'response_item', 'payload': {'type': 'function_call_output', 'output': 'Служебное'}},
            {'type': 'response_item', 'payload': {'type': 'message', 'role': 'user', 'content': []}},
            сам.сообщение('Внутреннее', phase='analysis'),
            сам.сообщение('Видно', phase='commentary')]
        итог = сам.прочитать(*записи)
        сам.assertEqual(len(итог['ответы']), 1)
        сам.assertEqual(итог['ответы'][0]['части'], ['Видно'])
        сам.assertTrue(итог['полнота_поддержанных_ответов'])

    def test_пустой_результат_явно_отмечен(сам):
        итог = сам.прочитать()
        сам.assertEqual(итог['состояние'], 'пусто')
        сам.assertEqual(итог['ответы'], [])
        сам.assertTrue(итог['полнота_поддержанных_ответов'])

    def test_неизвестная_часть_не_даёт_частичной_тихой_выборки(сам):
        запись = сам.сообщение(phase='commentary')
        запись['payload']['content'].append({'type': 'future', 'text': 'Неизвестное'})
        итог = сам.прочитать(запись)
        сам.assertEqual(итог['ответы'], [])
        сам.assertFalse(итог['полнота_поддержанных_ответов'])

    def test_чужая_задача_и_повреждённая_рамка_отклоняются(сам):
        for сырые, задача in (
            (сам.байты(), '00000000-0000-4000-8000-000000000002'),
            (сам.байты({'type': 'session_meta', 'payload': {'id': 'другая'}}), ЗАДАЧА),
            (сам.байты()[:-1], ЗАДАЧА), (b'', ЗАДАЧА),
            (b'{"type":"session_meta","payload":{"id":"x","id":"y"}}\n', ЗАДАЧА)):
            with сам.subTest(сырые=сырые, задача=задача):
                with сам.assertRaises(ValueError):
                    сам.читатель.извлечь(сырые, задача)

    def test_неизвестная_роль_и_чужой_адресат_не_публикуются(сам):
        for поля in ({'role': None}, {'role': 'future'}, {'recipient': 'functions.exec'}, {'recipient': {'agent': 'другой'}}):
            with сам.subTest(поля=поля):
                запись = сам.сообщение('НЕ ПУБЛИКОВАТЬ', phase='commentary')
                запись['payload'].update(поля)
                итог = сам.прочитать(запись)
                сам.assertFalse(итог['полнота_поддержанных_ответов'])
                сам.assertEqual(итог['ответы'], [])
                сам.assertNotIn('НЕ ПУБЛИКОВАТЬ', json.dumps(итог, ensure_ascii=False))

    def test_общий_адресат_разрешён(сам):
        запись = сам.сообщение(phase='commentary')
        запись['payload']['recipient'] = 'all'
        сам.assertEqual(сам.прочитать(запись)['ответы'][0]['части'], ['ё🙂'])

    def test_cli_не_меняет_источник_и_различает_неполноту(сам):
        with tempfile.TemporaryDirectory() as каталог:
            источник = Path(каталог).resolve() / 'native.jsonl'
            for запись, код, состояние in (
                (сам.сообщение(phase='commentary'), 0, 'сохранены'),
                (сам.сообщение(), 3, 'неполно')):
                сырые = сам.байты(запись)
                источник.write_bytes(сырые)
                процесс = subprocess.run([sys.executable, '-B', str(СКРИПТЫ / 'извлечь-видимые-ответы.py'),
                    '--исходник', str(источник), '--задача', ЗАДАЧА], capture_output=True)
                сам.assertEqual(процесс.returncode, код, процесс.stderr.decode())
                сам.assertEqual(json.loads(процесс.stdout)['состояние'], состояние)
                сам.assertEqual(источник.read_bytes(), сырые)


if __name__ == '__main__':
    unittest.main()
