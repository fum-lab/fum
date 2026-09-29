"""Первичный отказ CLI не подтверждает неизвестный исход прежнего слияния."""
import copy
import hashlib
import json
import shlex
from pathlib import Path
import sys
import unittest

for каталог in ('fum-konvejyer-proizvodnyikh-vetok', 'fum-reyestr-planirovaniya'):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / каталог / 'scripts'))
import отказ_нативного_приёма as отказ

ЗАДАЧА = '11111111-1111-4111-8111-111111111111'
ХОД = '22222222-2222-4222-8222-222222222222'
КОРЕНЬ = '/внешнее/дерево'
ИСТОЧНИК = '/внешнее/источник.jsonl'
КОМАНДА = ['python3', '-B',
    'Инструменты/fum-konvejyer-proizvodnyikh-vetok/scripts/подготовить-приём.py',
    'принять', '--исходник', ИСТОЧНИК]


def строка(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True) + '\n').encode()


def образец():
    вывод = json.dumps({'схема': 'fum.отказ-обнаружения-приёма.1',
        'ошибка': 'Нужна подтверждённая квитанция своего слияния',
        'повтор_эффекта_разрешён': False, 'длительность_наносекунды': 100},
        ensure_ascii=False) + '\n'
    элемент = {'type': 'CommandExecution', 'id': 'exec-отказ',
        'command': ['/bin/zsh', '-lc', ' '.join(КОМАНДА)],
        'cwd': 'file://' + КОРЕНЬ, 'source': 'unified_exec_startup',
        'status': 'failed', 'exit_code': 2, 'stdout': вывод, 'stderr': ''}
    событие = {'type': 'event_msg', 'payload': {'type': 'item_completed',
        'thread_id': ЗАДАЧА, 'turn_id': ХОД, 'item': элемент,
        'started_at_ms': 10, 'completed_at_ms': 20}}
    мета = строка({'type': 'session_meta', 'payload': {'id': ЗАДАЧА, 'cwd': КОРЕНЬ}})
    цель = {'задача': ЗАДАЧА, 'ход': ХОД, 'корень': КОРЕНЬ,
        'исходник': ИСТОЧНИК, 'id': элемент['id'],
        'начало': len(мета), 'конец': len(мета) + len(строка(событие)),
        'sha256': hashlib.sha256(строка(событие)).hexdigest()}
    return мета, событие, цель


class ПроверкаОтказаНативногоПриёма(unittest.TestCase):
    def проверить(self, мета, событие, цель, хвост=b''):
        return отказ.проверить(мета + строка(событие) + хвост, цель)

    def пересчитать(self, мета, событие, цель):
        цель['конец'] = len(мета) + len(строка(событие))
        цель['sha256'] = hashlib.sha256(строка(событие)).hexdigest()

    def test_точный_первичный_отказ_сохраняет_границу_неизвестного_слияния(self):
        мета, событие, цель = образец(); до = copy.deepcopy(цель)
        результат = self.проверить(мета, событие, цель)
        self.assertEqual(2, результат['код'])
        self.assertEqual('unknown', результат['исход_прежнего_слияния'])
        self.assertFalse(результат['повтор_эффекта_разрешён'])
        self.assertEqual(hashlib.sha256(событие['payload']['item']['stdout'].encode()).hexdigest(),
                         результат['stdout_sha256'])
        self.assertEqual(до, цель)

    def test_подмена_байтов_локатора_и_оборванный_источник_отклоняются(self):
        мета, событие, цель = образец()
        for изменение in ('байты', 'граница', 'sha', 'LF'):
            with self.subTest(изменение=изменение):
                з = copy.deepcopy(цель); с = copy.deepcopy(событие)
                if изменение == 'байты': с['payload']['item']['stdout'] += ' '
                elif изменение == 'граница': з['начало'] += 1
                elif изменение == 'sha': з['sha256'] = '0' * 64
                with self.assertRaises(ValueError):
                    сырой = мета + строка(с)
                    отказ.проверить(сырой[:-1] if изменение == 'LF' else сырой, з)

    def test_чужие_задача_ход_каталог_и_команда_не_подтверждают_приём(self):
        for поле in ('thread_id', 'turn_id', 'cwd', 'command', 'id'):
            with self.subTest(поле=поле):
                мета, событие, цель = образец(); д = событие['payload']
                if поле in ('thread_id', 'turn_id'): д[поле] = '33333333-3333-4333-8333-333333333333'
                elif поле == 'cwd': д['item'][поле] = 'file:///другое/дерево'
                elif поле == 'command': д['item'][поле] = ['/bin/zsh', '-lc', 'git merge иной-ref']
                else: д['item'][поле] = 'exec-другой'
                self.пересчитать(мета, событие, цель)
                with self.assertRaises(ValueError): self.проверить(мета, событие, цель)

    def test_незавершённый_исход_и_код_старого_git_не_подменяют_код_cli(self):
        for поле, значение in (('exit_code', 128), ('exit_code', None),
                               ('exit_code', True), ('status', 'inProgress')):
            with self.subTest(поле=поле, значение=значение):
                мета, событие, цель = образец(); событие['payload']['item'][поле] = значение
                self.пересчитать(мета, событие, цель)
                with self.assertRaises(ValueError): self.проверить(мета, событие, цель)

    def test_другая_ошибка_разрешённый_повтор_и_неизвестный_канал_закрывают_допуск(self):
        for изменение in ('ошибка', 'повтор', 'stderr', 'JSON'):
            with self.subTest(изменение=изменение):
                мета, событие, цель = образец(); э = событие['payload']['item']
                if изменение == 'stderr': э['stderr'] = 'неизвестный исход'
                elif изменение == 'JSON': э['stdout'] = 'не JSON\n'
                else:
                    д = json.loads(э['stdout'])
                    if изменение == 'ошибка': д['ошибка'] = 'Другая ошибка'
                    else: д['повтор_эффекта_разрешён'] = True
                    э['stdout'] = json.dumps(д, ensure_ascii=False) + '\n'
                self.пересчитать(мета, событие, цель)
                with self.assertRaises(ValueError): self.проверить(мета, событие, цель)

    def test_повтор_первичного_терминала_и_обратный_интервал_не_принимаются(self):
        мета, событие, цель = образец()
        with self.assertRaises(ValueError): self.проверить(мета, событие, цель, строка(событие))
        событие['payload']['completed_at_ms'] = 9
        self.пересчитать(мета, событие, цель)
        with self.assertRaises(ValueError): self.проверить(мета, событие, цель)

    def test_подстановка_shell_не_доказывает_исходный_argv(self):
        for исходник in ('/tmp/$(printf replaced).jsonl', '/tmp/$HOME.jsonl', '/tmp/`uname`.jsonl'):
            with self.subTest(исходник=исходник):
                мета, событие, цель = образец(); цель['исходник'] = исходник
                событие['payload']['item']['command'][2] = ' '.join(КОМАНДА[:-1]) + ' "' + исходник + '"'
                self.пересчитать(мета, событие, цель)
                with self.assertRaises(ValueError): self.проверить(мета, событие, цель)

    def test_литеральный_путь_с_экранированием_не_путается_с_подстановкой(self):
        мета, событие, цель = образец(); цель['исходник'] = '/tmp/$HOME и пробел.jsonl'
        событие['payload']['item']['command'][2] = ' '.join(map(shlex.quote, [*КОМАНДА[:-1], цель['исходник']]))
        self.пересчитать(мета, событие, цель)
        self.assertEqual(2, self.проверить(мета, событие, цель)['код'])


if __name__ == '__main__':
    unittest.main()
