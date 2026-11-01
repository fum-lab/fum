"""Конечный смешанный исход сохраняет пакет H и опубликованный настоящий S."""
import importlib.util
import copy
from contextlib import contextmanager, ExitStack
import json
from pathlib import Path
import sys
import os
import subprocess
import unittest
from unittest.mock import patch

from фикстура_сохранения_поставки import сохранение_поставки
from фикстура_двух_до_записи import первичный_вызов, обновить_источники
import завершение_сохранённой_поставки as переход
import терминал_запуска
from test_завершения_запуска import граница
from фикстура_штатных_событий import служебный_контекст
import постановка_задачи
from test_запуска_слоёв import хранение, ЗАДАЧА


class ПроверкаСохраненияПоставки(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.контекст = сохранение_поставки()
        cls.фикстура = cls.контекст.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.контекст.__exit__(None, None, None)

    @contextmanager
    def сохранённая_фикстура(self):
        корень, объект, _, _, вход, _, дети = self.фикстура
        пути = {Path(вход['источник']['путь']), объект.хранилище.путь}
        for дерево, _, источник in дети.values():
            пути.update((источник, постановка_задачи.путь_подтверждения(дерево),
                Path(хранение.гит(дерево, 'rev-parse', '--path-format=absolute', '--git-path', 'index').strip())))
        пути.add(Path(хранение.гит(корень, 'rev-parse', '--path-format=absolute', '--git-path', 'config').strip()))
        пакет_S = Path(вход['слои']['сообщения']['пакет_передачи']['путь']).parent
        пути.update(пакет_S / п for п in ('вход.json', 'подготовка.json', 'квитанция.json',
            'пакет.json', 'нативный/источник.jsonl', 'нативный/описание.json'))
        пути.update((дети['события'][0] / 'Память/события/поток.jsonl',
            дети['сообщения'][0] / 'Память/сообщения/данные.txt'))
        снимки = {п: (п.read_bytes(), п.stat().st_mode & 0o777) for п in пути}
        S = вход['слои']['сообщения']; ветка = S['публикация']['ref']; oid = S['публикация']['коммит']
        origin = корень.parent / 'origin.git'
        try:
            yield copy.deepcopy(вход)
        finally:
            for п, (байты, режим) in снимки.items():
                п.chmod(0o600); п.write_bytes(байты); п.chmod(режим)
            хранение.гит(корень, 'update-ref', ветка, oid)
            хранение.гит(origin, 'update-ref', ветка, oid)

    def test_штатный_CLI_принимает_смешанный_исход_восьмой_версии(self):
        корень, _, _, _, вход, _, _ = self.фикстура
        файл = корень.parent / 'закрытие.json'
        файл.write_bytes(хранение.байты(вход))
        адрес = Path(__file__).resolve().parents[1] / 'scripts/запустить-слои.py'
        spec = importlib.util.spec_from_file_location('cli_сохранения_поставки', адрес)
        cli = importlib.util.module_from_spec(spec); spec.loader.exec_module(cli)
        argv = [str(адрес), '--корень-репозитория', str(корень), '--задача', ЗАДАЧА,
            'завершение-предпросмотр', '--вход', str(файл)]
        with patch.object(sys, 'argv', argv):
            итог = cli.выполнить()
        self.assertEqual('fum.завершённый-неудачный-запуск.8', итог['схема'])
        self.assertEqual('остановлен-с-сохранением', итог['слои']['события']['вид'])
        self.assertEqual('остановлен-с-коммитом', итог['слои']['сообщения']['вид'])
        self.assertFalse(итог['слои']['сообщения']['интегрирован'])

    def test_скрытое_возобновление_в_ROOT_закрывает_переход(self):
        _, объект, _, _, вход, события, дети = self.фикстура
        исходник = Path(вход['источник']['путь'])
        оригинал = исходник.read_bytes(); копия = copy.deepcopy(вход)
        аргументы = {'threadId': дети['сообщения'][1], 'hostId': 'local',
            'prompt': 'Новое поручение', 'model': 'gpt-6-sol', 'thinking': 'ultra'}
        ответ = {'content': [{'type': 'text', 'text': json.dumps({'threadId': дети['сообщения'][1]})}],
            'isError': False}
        новые = [*события[:3], первичный_вызов('send_message_to_thread', 'скрытая-отправка',
            аргументы, ответ, 25), *события[3:]]
        до = объект.хранилище.путь.read_bytes()
        try:
            обновить_источники(копия, новые)
            with self.assertRaisesRegex(ValueError, 'возобновлен|поручен'):
                переход.предпросмотр(объект, копия)
            self.assertEqual(до, объект.хранилище.путь.read_bytes())
        finally:
            исходник.write_bytes(оригинал)

    def test_индекс_H_меняется_во_время_сверки_remote_S(self):
        _, объект, _, _, вход, _, дети = self.фикстура
        H = дети['события'][0]
        индекс = Path(хранение.гит(H, 'rev-parse', '--path-format=absolute', '--git-path', 'index').strip())
        байты = индекс.read_bytes(); до = объект.хранилище.путь.read_bytes()
        просмотр = переход.предпросмотр(объект, вход)
        оригинальный_план = переход._план
        оригинальная_публикация = переход.поставка.проверить_публикацию
        после_плана = False; изменён = False
        def план(*args):
            nonlocal после_плана
            результат = оригинальный_план(*args); после_плана = True
            return результат
        def публикация(*args):
            nonlocal изменён
            результат = оригинальная_публикация(*args)
            if после_плана and not изменён:
                хранение.гит(H, 'add', '--', 'Память/события/поток.jsonl'); изменён = True
            return результат
        try:
            with patch.object(переход, '_план', side_effect=план), \
                    patch.object(переход.поставка, 'проверить_публикацию', side_effect=публикация):
                with self.assertRaises(ValueError):
                    переход.завершить(объект, вход, просмотр['sha256'])
            self.assertTrue(изменён)
            self.assertEqual(до, объект.хранилище.путь.read_bytes())
        finally:
            индекс.write_bytes(байты)
            объект.хранилище.путь.write_bytes(до)

    def test_первичные_создания_ответы_и_последние_wait(self):
        _, объект, _, _, _, события, _ = self.фикстура
        варианты = []
        э = copy.deepcopy(события); э[2]['payload']['item']['arguments']['prompt'] += ' Подмена'
        варианты.append(('поручение', э))
        э = copy.deepcopy(события); э[2]['payload']['item']['result']['content'][0]['text'] = '{}'
        варианты.append(('ответ', э))
        э = copy.deepcopy(события); э[3]['payload']['started_at_ms'] = 19
        варианты.append(('перекрытие', э))
        э = copy.deepcopy(события); э[3]['payload']['item']['arguments']['targets'].append(
            copy.deepcopy(э[4]['payload']['item']['arguments']['targets'][0]))
        варианты.append(('объединённый-wait', э))
        последнее = события[4]['payload']['item']
        варианты.append(('поздний-wait', [*copy.deepcopy(события), первичный_вызов('wait_threads',
            'последний-другой', последнее['arguments'], последнее['result'], 50)]))
        for имя, э in варианты:
            with self.subTest(имя=имя), self.сохранённая_фикстура() as вход:
                до = объект.хранилище.путь.read_bytes(); обновить_источники(вход, э)
                with self.assertRaises(ValueError): переход.предпросмотр(объект, вход)
                self.assertEqual(до, объект.хранилище.путь.read_bytes())

    def test_человек_отмена_поздний_контекст_и_транспорт_в_детях(self):
        _, объект, _, _, _, _, дети = self.фикстура
        варианты = [
            {'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {'type': 'UserMessage'}}},
            {'type': 'event_msg', 'payload': {'type': 'turn_aborted'}}, служебный_контекст(),
            {'type': 'response_item', 'payload': {'type': 'function_call',
                'name': 'send_message_to_thread', 'arguments': '{}'}},
            {'type': 'turn_context', 'payload': {'cwd': 'другой', 'model': 'gpt-6-astra', 'effort': 'low'}},
        ]
        for слой in ('события', 'сообщения'):
            for n, э in enumerate(варианты):
                with self.subTest(слой=слой, вариант=n), self.сохранённая_фикстура() as вход:
                    путь = дети[слой][2]; строки = путь.read_bytes().splitlines(keepends=True)
                    # Полный человеческий контекст после create не становится первоначальным.
                    путь.write_bytes(b''.join(строки[:-1]) + (json.dumps(э, ensure_ascii=False)+'\n').encode() + строки[-1])
                    вход['слои'][слой]['источник'] = граница(путь)
                    with self.assertRaises(ValueError): переход.предпросмотр(объект, вход)

    def test_семантика_подготовки_квитанции_и_пакета_S(self):
        _, объект, _, _, _, _, _ = self.фикстура
        варианты = [('подготовка', lambda x: x['модель'].update(усилие='low')),
            ('подготовка', lambda x: x['команды'][0].update(текст='Чужое поручение')),
            ('подготовка', lambda x: x['параметры'].update(родители=['0'*40])),
            ('квитанция', lambda x: x['процесс'].update(код=1)),
            ('квитанция', lambda x: x.update(подготовка_sha256='0'*64)),
            ('квитанция', lambda x: x['ожидание'].update(родители=['0'*40])),
            ('пакет_передачи', lambda x: x.update(снимок_sha256='0'*64))]
        for имя, изменить in варианты:
            with self.subTest(имя=имя), self.сохранённая_фикстура() as вход:
                описание = вход['слои']['сообщения'][имя]; путь = Path(описание['путь'])
                э = json.loads(путь.read_bytes()); изменить(э)
                сырые = хранение.байты(э); путь.chmod(0o600); путь.write_bytes(сырые)
                описание['sha256'] = переход.поставка.коммит.хэш(сырые)
                with self.assertRaises(ValueError): переход.предпросмотр(объект, вход)

    def test_origin_и_удалённый_OID_не_подменяются(self):
        корень, объект, пакет, _, _, _, дети = self.фикстура
        S = дети['сообщения'][0]; origin = корень.parent / 'origin.git'
        for вариант in ('потерян', 'два-адреса', 'другой-fetch', 'иной-OID'):
            with self.subTest(вариант=вариант), self.сохранённая_фикстура() as вход:
                if вариант == 'потерян': хранение.гит(S, 'remote', 'remove', 'origin')
                elif вариант == 'два-адреса':
                    хранение.гит(S, 'config', '--add', 'remote.origin.pushurl', str(origin))
                    хранение.гит(S, 'config', '--add', 'remote.origin.pushurl', str(origin))
                elif вариант == 'другой-fetch':
                    хранение.гит(S, 'config', 'remote.origin.pushurl', str(origin))
                    хранение.гит(S, 'config', 'remote.origin.url', str(origin)+'-другой')
                else:
                    хранение.гит(origin, 'update-ref', вход['слои']['сообщения']['публикация']['ref'],
                        пакет['постановка']['коммит'])
                with self.assertRaises(ValueError): переход.предпросмотр(объект, вход)

    def test_чужой_самосогласованный_frozen_не_заменяет_живой_префикс(self):
        _, объект, _, _, _, _, _ = self.фикстура
        with self.сохранённая_фикстура() as вход:
            S = вход['слои']['сообщения']; каталог = Path(S['пакет_передачи']['путь']).parent
            файл = каталог/'нативный/источник.jsonl'
            строки = [json.loads(с) for с in файл.read_bytes().splitlines()]
            строки[-1]['payload']['item']['stdout'] = 'Иной нейтральный вывод'
            сырые = b''.join((json.dumps(с, ensure_ascii=False)+'\n').encode() for с in строки)
            файл.chmod(0o600); файл.write_bytes(сырые); файл.chmod(0o400)
            путь = каталог/'нативный/описание.json'; описание = json.loads(путь.read_bytes())
            описание.update(граница=len(сырые), sha256=переход.поставка.коммит.хэш(сырые))
            путь.chmod(0o600); путь.write_bytes(хранение.байты(описание)); путь.chmod(0o400)
            путь = каталог/'пакет.json'; пакет = json.loads(путь.read_bytes())
            пакет['снимок_sha256'] = хранение.хэш(описание)
            raw = хранение.байты(пакет); путь.chmod(0o600); путь.write_bytes(raw); путь.chmod(0o400)
            S['пакет_передачи']['sha256'] = переход.поставка.коммит.хэш(raw)
            with self.assertRaisesRegex(ValueError, 'Замороженный источник не является исходным префиксом'):
                переход.предпросмотр(объект, вход)

    def test_гонки_после_плана_под_замком(self):
        корень, объект, пакет, план, _, _, дети = self.фикстура
        for вариант in ('ROOT', 'native-H', 'native-S', 'frozen-S', 'ранняя-H', 'ранняя-S',
                'байты-H', 'байты-S', 'ref-S', 'origin', 'история'):
            with self.subTest(вариант=вариант), self.сохранённая_фикстура() as вход:
                просмотр = переход.предпросмотр(объект, вход)
                до = объект.хранилище.путь.read_bytes(); исходный = переход._план
                def сдвиг(*args):
                    результат = исходный(*args)
                    if вариант == 'история':
                        args[2]['попытки'][план['попытки']['сообщения']]['ответ']['threadId'] = 'чужой'
                    elif вариант == 'ref-S':
                        хранение.гит(корень, 'update-ref', вход['слои']['сообщения']['публикация']['ref'],
                            пакет['постановка']['коммит'])
                    elif вариант == 'origin':
                        хранение.гит(корень.parent/'origin.git', 'update-ref',
                            вход['слои']['сообщения']['публикация']['ref'], пакет['постановка']['коммит'])
                    elif вариант.startswith('ранняя-'):
                        слой = 'события' if вариант.endswith('H') else 'сообщения'
                        п = постановка_задачи.путь_подтверждения(дети[слой][0])
                        конверт = json.loads(п.read_bytes())
                        конверт['данные']['ref'] = 'refs/heads/codex/чужое-назначение'
                        конверт['sha256'] = хранение.хэш(конверт['данные'])
                        п.write_bytes(хранение.байты(конверт))
                    else:
                        пути = {'ROOT': Path(вход['источник']['путь']),
                            'native-H': дети['события'][2], 'native-S': дети['сообщения'][2],
                            'frozen-S': Path(вход['слои']['сообщения']['пакет_передачи']['путь']).parent/'нативный/источник.jsonl',
                            'ранняя-H': постановка_задачи.путь_подтверждения(дети['события'][0]),
                            'ранняя-S': постановка_задачи.путь_подтверждения(дети['сообщения'][0]),
                            'байты-H': дети['события'][0]/'Память/события/поток.jsonl',
                            'байты-S': дети['сообщения'][0]/'Память/сообщения/данные.txt'}
                        п = пути[вариант]; п.chmod(0o600); п.write_bytes(п.read_bytes()+b'\n')
                    return результат
                with patch.object(переход, '_план', side_effect=сдвиг):
                    with self.assertRaises(ValueError): переход.завершить(объект, вход, просмотр['sha256'])
                self.assertEqual(до, объект.хранилище.путь.read_bytes())

    def test_загруженный_помощник_не_маскируется_восстановленным_файлом(self):
        корень, _, _, _, вход, _, _ = self.фикстура
        исходники = Path(__file__).resolve().parents[1]/'scripts'
        каталог = корень.parent/'холодная-загрузка'; каталог.mkdir()
        путь = каталог/'поток_остановленного_писателя.py'
        сырые = (исходники/путь.name).read_bytes()
        (каталог/'исходник').write_bytes(сырые); путь.write_bytes(сырые+'\nметка_изменения = True\n'.encode())
        входной = каталог/'вход.json'; входной.write_bytes(хранение.байты(вход))
        код = '''import sys,json,hashlib
from pathlib import Path
from unittest.mock import patch
sys.path[:0]=[sys.argv[1],sys.argv[2],sys.argv[5]]
import поток_остановленного_писателя
p=Path(sys.argv[1])/'поток_остановленного_писателя.py'
p.write_bytes((p.parent/'исходник').read_bytes())
import завершение_сохранённой_поставки as m
from запуск_слоёв import ИсполнительЗапускаСлоёв
вход=json.loads((p.parent/'вход.json').read_bytes())
объект=ИсполнительЗапускаСлоёв(sys.argv[3],sys.argv[4])
with patch.object(объект,'_инструменты'):
 try: m.предпросмотр(объект,вход)
 except ValueError as e: assert 'Код сохранения поставки изменился' in str(e),str(e)
 else: raise AssertionError('Загруженная подмена пропущена')
'''
        процесс = subprocess.run([sys.executable, '-B', '-c', код, str(каталог), str(исходники),
            str(корень), ЗАДАЧА, str(исходники.parents[1]/'fum-reyestr-planirovaniya/scripts')],
            cwd=корень, env={**os.environ,'CODEX_THREAD_ID':ЗАДАЧА},
            capture_output=True, text=True, timeout=60)
        self.assertEqual(0, процесс.returncode, процесс.stderr)

    def test_я_запись_терминала_и_исторический_повтор_без_живых_чтений(self):
        _, объект, _, план, вход, _, _ = self.фикстура
        до = copy.deepcopy(объект.хранилище.прочитать())
        просмотр = переход.предпросмотр(объект, вход)
        self.assertEqual(просмотр, переход.завершить(объект, вход, просмотр['sha256']))
        после = объект.хранилище.прочитать()
        self.assertEqual(просмотр, после['приёмы'].pop(терминал_запуска.ключ(план['запуск'])))
        self.assertEqual(до, после)
        байты = объект.хранилище.путь.read_bytes()
        цели = [(переход.нативные_вызовы,'прочитать'), (переход.поток,'прочитать'),
            (переход.сохранённый_писатель,'проверить'), (переход.поставка,'проверить'),
            (переход.поставка,'проверить_публикацию'), (переход.общие,'_координатор')]
        with ExitStack() as стек:
            запреты = [стек.enter_context(patch.object(м, имя,
                side_effect=AssertionError('Повтор читает живое основание'))) for м,имя in цели]
            self.assertEqual(просмотр, переход.завершить(объект, вход, просмотр['sha256']))
            другой = copy.deepcopy(вход); другой['ожидания'] = {}
            with self.assertRaises(ValueError): переход.предпросмотр(объект, другой)
            for запрет in запреты: запрет.assert_not_called()
        self.assertEqual(байты, объект.хранилище.путь.read_bytes())


if __name__ == '__main__':
    unittest.main()
