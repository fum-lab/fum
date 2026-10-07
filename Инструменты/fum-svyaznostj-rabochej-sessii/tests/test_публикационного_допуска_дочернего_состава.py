"""Конечный допуск: настоящие producer, ready/create и Git обычной .7."""
import contextlib
import base64
import hashlib
import importlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import types
import unittest

import test_подготовки_этапа_коммита as примеры

этап = importlib.import_module('подготовка_этапа_коммита')
коммит = этап.коммит
ПОЛИТИКА = 'Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy.json'


def запрещённая_строка():
    return chr(47) + 'Users' + chr(47) + 'fixture' + chr(47) + 'private.txt'


class Фикстура(примеры.Фикстура):
    """Дополняет прежнюю реальную фикстуру, сохраняя её source/ACT и v4."""
    def __init__(сам, владелец, *, материал=False, текст='Открытые данные\n', исключения=(), неизменный=False):
        прежнее = os.environ.get('PYTHONDONTWRITEBYTECODE')
        def восстановить():
            if прежнее is None:
                os.environ.pop('PYTHONDONTWRITEBYTECODE', None)
            else:
                os.environ['PYTHONDONTWRITEBYTECODE'] = прежнее
        владелец.addCleanup(восстановить)
        os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
        super().__init__(владелец)
        сам.предмет = (str(Path(сам.п['запрос']).parent / 'материалы/предмет.txt')
            if материал else 'предмет.txt')
        сам.цели += [сам.предмет, ПОЛИТИКА]
        сам.д.акт['область'] += [сам.предмет, ПОЛИТИКА]
        предмет = сам.корень / сам.предмет
        предмет.parent.mkdir(parents=True, exist_ok=True)
        предмет.write_text(текст)
        политика = сам.корень / ПОЛИТИКА
        политика.parent.mkdir(parents=True)
        политика.write_bytes(примеры.байты({'schema': 'fum.machine-local-path-policy.v2',
            'exceptions': list(исключения)}))
        акт = сам.корень / сам.д.выбор['путь']
        акт.write_bytes(примеры.байты(сам.д.акт))
        сам.ф.гит('add', ПОЛИТИКА, сам.д.выбор['путь'])
        if неизменный:
            сам.ф.гит('add', сам.предмет)
        сам.ф.гит('commit', '-qm', 'Закрепить публикационный состав открытой фикстуры')
        голова = сам.ф.гит('rev-parse', 'HEAD').strip()
        сам.д.выбор.update(коммит=голова, sha256=hashlib.sha256(акт.read_bytes()).hexdigest())
        сам.п.update(исходный_коммит=голова, родители=[голова], выбранное_поручение=сам.д.выбор)
        сам.сохранить('вход.json', сам.п)
        сам.сохранить('выбор.json', сам.д.выбор)
        разрешение = сам.сохранить('разрешение.json', сам.цели)
        сам.наполнение['разрешение']['sha256'] = hashlib.sha256(разрешение.read_bytes()).hexdigest()
        сам.сохранить('наполнение.json', сам.наполнение)
        сам.исходы = []
        каталог = os.environ.get('FUM_PUBLICATION_EVIDENCE_DIR')
        if каталог:
            сохранение = Path(tempfile.mkdtemp(prefix='фикстура-', dir=каталог))
            def сохранить_исходы():
                (сохранение / 'исходы.json').write_bytes(примеры.байты(сам.исходы))
                (сохранение / 'исходы.json').chmod(0o600)
                shutil.copytree(сам.приватный, сохранение / 'состояние', symlinks=True)
            владелец.addCleanup(сохранить_исходы)

    def подготовить(сам):
        план = этап.построить_план(сам.вход)
        прежнее = этап.исполнить_команду
        def изолированная_команда(аргументы, корень):
            а = list(аргументы)
            if len(а) > 2 and а[2] == str(Path(коммит.__file__)):
                а = сам.ф.команда_CLI(*а[3:])
            итог = прежнее(а, корень)
            итог['аргументы'] = аргументы
            return итог
        этап.исполнить_команду = изолированная_команда
        try:
            итог = этап.выполнить(сам.вход, план, этап.хэш(этап.байты(план)))
        finally:
            этап.исполнить_команду = прежнее
        if итог['код'] != 0:
            raise ValueError('Незавершённый producer: ' + json.dumps(итог, ensure_ascii=False))
        сам.исходы.append({'стадия': 'producer', 'результат': итог})
        return итог

    def объявить_готовность(сам):
        try:
            итог = коммит.объявить_готовность(Path(сам.п['подготовка']), сам.номера, 600,
                доверенное_поручение=сам.д.выбор)
        except ValueError as ошибка:
            сам.исходы.append({'стадия': 'ready', 'ошибка': str(ошибка)}); raise
        сам.исходы.append({'стадия': 'ready', 'результат': итог}); return итог

    def создать(сам):
        try:
            итог = коммит.создать(Path(сам.п['подготовка']), сам.номера,
                доверенное_поручение=сам.д.выбор)
        except ValueError as ошибка:
            сам.исходы.append({'стадия': 'create', 'ошибка': str(ошибка)}); raise
        сам.исходы.append({'стадия': 'create', 'результат': итог}); return итог


@contextlib.contextmanager
def изолированный_код(ф):
    """Настоящие копии исполняемых исходников; checkout зависимостей read-only."""
    import публикационный_допуск_дочернего_состава as исходный
    корень = ф.приватный / 'код-публикации'
    имена = [*исходный.ИСХОДНИКИ_СКАНЕРА,
        ('публикационный_допуск_дочернего_состава', str(Path(исходный.__file__).relative_to(исходный.КОРЕНЬ_КОДА)))]
    for _, имя in имена:
        цель = корень / имя
        цель.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(исходный.КОРЕНЬ_КОДА / имя, цель)
    имя, путь = имена[-1]
    модуль = types.ModuleType(имя)
    модуль.__file__ = str(корень / путь)
    прежний = sys.modules[имя]
    sys.modules[имя] = модуль
    try:
        exec(compile(Path(модуль.__file__).read_bytes(), модуль.__file__, 'exec'), модуль.__dict__)
        yield модуль
    finally:
        sys.modules[имя] = прежний


def исключение(путь, *, sha=None, счёт=1):
    return {'id': 'fixture-subject', 'path': путь, 'kind': 'posix-user-home',
        'line_sha256': sha or 'sha256:' + hashlib.sha256(запрещённая_строка().encode()).hexdigest(),
        'count': счёт, 'category': 'allow.test-fixture', 'reason': 'Открытая отрицательная фикстура.'}


def сырой_канал(данные):
    return {'base64': base64.b64encode(данные).decode('ascii'),
        'sha256': hashlib.sha256(данные).hexdigest(), 'байты': len(данные)}


def адресный_снимок(ф, *, без_замка=False, без_квитанции=False):
    состояние = ф.снимок()
    файлы = dict(состояние[2])
    имя = str(Path(ф.п['квитанция']).relative_to(ф.приватный))
    if без_замка:
        файлы.pop(имя + '.lock', None)
    if без_квитанции:
        файлы.pop(имя, None)
    return ((состояние[0], состояние[1], файлы), ф.ф.гит('symbolic-ref', 'HEAD'),
        ф.ф.гит('for-each-ref', '--format=%(refname) %(objectname)'))


class ПозднийДрейфROOT:
    """Наблюдает настоящий успешный stdout; меняет только адрес Git фикстуры."""
    def __init__(сам, ф, граница, дрейф, *, адаптер=None, код_гита=None, номера_гейтов=None):
        сам.ф, сам.граница, сам.дрейф = ф, граница, дрейф
        сам.адаптер = адаптер or коммит.публикационный_адаптер()
        сам.код_гита = код_гита or коммит.гит.__code__
        сам.номера_гейтов = номера_гейтов or {'ready': 1, 'до-intent': 2, 'после-intent': 3}
        сам.гейт = сам.списков = сам.коммитов = 0
        сам.после = сам.квитанция = None
        сам.след = {'граница': граница, 'дрейф': дрейф, 'инъекций': 0}
        сам.след['записывающие_Git_после'] = []
        сам.другой_ref = 'refs/heads/codex/fixture-late-address'
        # Иной commit исходного HEAD-дерева заранее; checkout и индекс не меняются.
        сам.иной = ф.ф.гит('commit-tree', ф.ф.гит('rev-parse', 'HEAD^{tree}').strip(),
            '-p', ф.ф.гит('rev-parse', 'HEAD').strip(), '-m', 'Иной адрес открытой фикстуры').strip()
        ф.ф.гит('update-ref', сам.другой_ref, ф.ф.гит('rev-parse', 'HEAD').strip())

    def инъекция(сам, кадр, stdout):
        ф = сам.ф
        до = ф.ф.гит('rev-parse', 'HEAD').strip()
        if сам.дрейф == 'ref':
            ф.ф.гит('update-ref', сам.другой_ref, до)
            ф.ф.гит('symbolic-ref', 'HEAD', сам.другой_ref)
        else:
            ф.ф.гит('update-ref', ф.п['ветка'], сам.иной, до)
        голова, ветка = ф.ф.гит('rev-parse', 'HEAD').strip(), ф.ф.гит('symbolic-ref', 'HEAD').strip()
        if сам.дрейф == 'ref':
            if not (голова == до and ветка != ф.п['ветка']):
                raise AssertionError('Не получен ROOT-only дрейф ref при прежнем C')
        elif not (ветка == ф.п['ветка'] and голова != до):
            raise AssertionError('Не получен ROOT-only дрейф HEAD при прежнем ref')
        путь = Path(ф.п['квитанция'])
        сам.квитанция = путь.read_bytes() if путь.exists() else None
        сам.след.update(инъекций=1, гейт=сам.гейт, stdout=сырой_канал(stdout),
            аргументы=list(кадр.f_locals['аргументы']), процесс=dict(кадр.f_locals['исход']),
            HEAD_до=до, HEAD_после=голова, ref_после=ветка, commit_до=сам.коммитов,
            квитанция_при_инъекции=None if сам.квитанция is None else сырой_канал(сам.квитанция))
        сам.после = адресный_снимок(ф, без_квитанции=сам.граница == 'новая-квитанция')

    def наблюдать(сам, кадр, событие, значение):
        м = сам.адаптер
        if событие == 'call' and кадр.f_code == м.сверить.__code__:
            сам.гейт += 1; сам.списков = 0
        if кадр.f_code != сам.код_гита:
            return
        а = tuple(кадр.f_locals['аргументы'])
        if событие == 'call' and а[0] == 'commit':
            сам.коммитов += 1
        if событие == 'call' and сам.след['инъекций'] and а[0] in {'commit', 'write-tree', 'update-ref', 'hash-object', 'commit-tree', 'add', 'reset'}:
            сам.след['записывающие_Git_после'].append(list(а))
        if событие != 'return' or not isinstance(значение, bytes) or сам.след['инъекций']:
            return
        процесс = кадр.f_locals['исход']
        if процесс['код'] != 0 or процесс['исполнение_завершено'] is not True:
            return
        родители = []; к = кадр.f_back
        while к:
            родители.append(к.f_code); к = к.f_back
        номер = сам.номера_гейтов.get(сам.граница)
        if номер is not None and м.сверить.__code__ in родители and сам.гейт == номер:
            if а == ('ls-files', '--stage', '-v', '-z'):
                сам.списков += 1
                if сам.списков == 5:
                    сам.инъекция(кадр, значение)
        elif сам.граница == 'write-tree' and а == ('write-tree',):
            сам.инъекция(кадр, значение)
        elif сам.граница in {'новая-квитанция', 'replay'} and а == ('rev-parse', '--show-object-format'):
            целевая = (коммит._зафиксировать_новую_квитанцию if сам.граница == 'новая-квитанция'
                else коммит.восстановить)
            if коммит.проверить_объект.__code__ in родители and целевая.__code__ in родители:
                сам.инъекция(кадр, значение)

    def __enter__(сам):
        if sys.getprofile() is not None:
            raise ValueError('Занят наблюдатель адресной регрессии')
        sys.setprofile(сам.наблюдать)
        return сам

    def __exit__(сам, *исход):
        sys.setprofile(None)
        сам.след['commit_всего'] = сам.коммитов
        путь = Path(сам.ф.п['квитанция'])
        сам.след['квитанция_после'] = сырой_канал(путь.read_bytes()) if путь.exists() else None
        сам.ф.исходы.append({'стадия': 'поздний-ROOT', 'наблюдение': сам.след})


class ПозднийАдресROOT(unittest.TestCase):
    def сырой_результат(сам, ф, итог):
        сам.assertEqual({'коммит', 'дерево', 'родители', 'автор', 'коммиттер', 'сообщение_sha256'}, set(итог))
        к = json.loads(Path(ф.п['квитанция']).read_bytes())
        сам.assertEqual(итог, коммит.проверить_объект(ф.корень, к['ожидание'], итог['коммит']))
        сам.assertEqual({'код': 0, 'тайм_аут': False, 'исполнение_завершено': True, 'прерывание': None}, к['процесс'])

    def test_поздний_ROOT_чистый_контроль(сам):
        ф = Фикстура(сам)
        сам.assertEqual(0, ф.подготовить()['код'])
        ф.объявить_готовность()
        итог = ф.создать(); сам.сырой_результат(ф, итог)
        до = адресный_снимок(ф)
        сам.assertEqual(итог, ф.создать())
        сам.assertEqual(до, адресный_снимок(ф))
        сам.assertEqual('1', ф.ф.гит('rev-list', '--count', ф.п['исходный_коммит'] + '..HEAD').strip())

    def отказ(сам, граница):
        for дрейф in ('ref', 'HEAD'):
            with сам.subTest(граница=граница, дрейф=дрейф):
                ф = Фикстура(сам)
                сам.assertEqual(0, ф.подготовить()['код'])
                if граница != 'ready':
                    ф.объявить_готовность()
                if граница == 'replay':
                    сам.сырой_результат(ф, ф.создать())
                ошибка = None; результат = None
                with ПозднийДрейфROOT(ф, граница, дрейф) as н:
                    try:
                        результат = ф.объявить_готовность() if граница == 'ready' else ф.создать()
                    except ValueError as причина:
                        ошибка = str(причина)
                ф.исходы.append({'стадия': 'итог-позднего-ROOT', 'ошибка': ошибка, 'результат': результат})
                сам.assertEqual(1, н.след['инъекций'], н.след)
                сам.assertIsNotNone(ошибка, н.след)
                сам.assertIsNone(результат)
                сам.assertEqual(1 if граница == 'новая-квитанция' else 0, н.коммитов)
                сам.assertEqual([], н.след['записывающие_Git_после'])
                сам.assertEqual(н.после, адресный_снимок(ф, без_квитанции=граница == 'новая-квитанция'))
                путь = Path(ф.п['квитанция'])
                if граница in {'ready', 'до-intent', 'write-tree'}:
                    сам.assertFalse(путь.exists())
                elif граница == 'новая-квитанция':
                    до_отказа, после_отказа = json.loads(н.квитанция), json.loads(путь.read_bytes())
                    сам.assertNotEqual('проверен', после_отказа['состояние'])
                    for ключ in ('ожидание', 'подготовка_sha256', 'процесс', 'проверки', 'допуск', 'готовность'):
                        сам.assertEqual(до_отказа[ключ], после_отказа[ключ])
                    сам.assertEqual({'код': 0, 'тайм_аут': False, 'исполнение_завершено': True, 'прерывание': None}, после_отказа['процесс'])
                    сам.assertEqual(н.след['HEAD_до'], после_отказа.get('наблюдённый_коммит', н.след['HEAD_до']))
                else:
                    сам.assertEqual(н.квитанция, путь.read_bytes())
                    к = json.loads(н.квитанция)
                    сам.assertEqual('проверен' if граница == 'replay' else 'намерение', к['состояние'])
                    сам.assertEqual(граница == 'replay', 'процесс' in к)
                if граница == 'ready':
                    сам.assertFalse(коммит.готовность.путь_этапа(ф.п).exists())
                до = адресный_снимок(ф, без_замка=True)
                with сам.assertRaises(ValueError):
                    ф.создать()
                а = ['создать', '--подготовка', ф.п['подготовка'], '--доверенное-поручение', str(ф.приватный / 'выбор.json')]
                for номер in ф.номера:
                    а += ['--проверка', номер]
                повтор = subprocess.run(ф.ф.команда_CLI(*а), cwd=ф.корень, capture_output=True, timeout=30)
                ф.исходы.append({'стадия': 'повтор-CLI-позднего-ROOT', 'код': повтор.returncode,
                    'stdout': сырой_канал(повтор.stdout), 'stderr': сырой_канал(повтор.stderr)})
                сам.assertEqual(2, повтор.returncode)
                сам.assertEqual(до, адресный_снимок(ф, без_замка=True))

    def test_поздний_ROOT_ready(сам):
        сам.отказ('ready')

    def test_поздний_ROOT_до_intent(сам):
        сам.отказ('до-intent')

    def test_поздний_ROOT_после_intent(сам):
        сам.отказ('после-intent')

    def test_поздний_ROOT_write_tree(сам):
        сам.отказ('write-tree')

    def test_поздний_ROOT_новая_квитанция(сам):
        сам.отказ('новая-квитанция')

    def test_поздний_ROOT_replay(сам):
        сам.отказ('replay')


class ПубликационныйДопуск(unittest.TestCase):
    def отказ_готовности(сам, материал):
        ф = Фикстура(сам, материал=материал, текст=запрещённая_строка() + '\n')
        исход = ф.подготовить()
        сам.assertEqual(0, исход['код'])
        до = ф.снимок()
        with сам.assertRaisesRegex(ValueError, 'публикац'):
            ф.объявить_готовность()
        сам.assertEqual(до, ф.снимок())
        сам.assertFalse(Path(ф.п['квитанция']).exists())

    def test_новый_предмет_отказывает_до_готовности(сам):
        сам.отказ_готовности(False)

    def test_материал_журнала_отказывает_до_готовности(сам):
        сам.отказ_готовности(True)

    def test_неизменная_разрешённая_цель_тоже_сканируется(сам):
        ф = Фикстура(сам, текст=запрещённая_строка() + '\n', неизменный=True)
        ф.подготовить()
        сам.assertNotIn(ф.предмет, ф.ф.гит('diff', '--cached', '--name-only').splitlines())
        with сам.assertRaisesRegex(ValueError, 'публикац'):
            ф.объявить_готовность()

    def test_точное_исключение_и_сохранённая_квитанция(сам):
        ф = Фикстура(сам, текст=запрещённая_строка() + '\n', исключения=[исключение('предмет.txt')])
        ф.подготовить(); ф.объявить_готовность()
        первый = ф.создать()
        голова = ф.ф.гит('rev-parse', 'HEAD')
        квитанция = Path(ф.п['квитанция']).read_bytes()
        готовность = коммит.готовность.путь_этапа(ф.п).read_bytes()
        (ф.корень / ПОЛИТИКА).write_text('После эффекта policy недоступна для нового допуска\n')
        сам.assertEqual(первый, ф.создать())
        сам.assertEqual(голова, ф.ф.гит('rev-parse', 'HEAD'))
        сам.assertEqual(квитанция, Path(ф.п['квитанция']).read_bytes())
        сам.assertEqual(готовность, коммит.готовность.путь_этапа(ф.п).read_bytes())
        сам.assertEqual('1', ф.ф.гит('rev-list', '--count', ф.п['исходный_коммит'] + '..HEAD').strip())

    def test_несовпадающие_путь_sha_count_исключений(сам):
        for имя, э in [('путь', исключение('иной.txt')), ('sha', исключение('предмет.txt', sha='sha256:' + '0' * 64)),
                ('count', исключение('предмет.txt', счёт=2))]:
            with сам.subTest(граница=имя):
                ф = Фикстура(сам, текст=запрещённая_строка() + '\n', исключения=[э])
                ф.подготовить()
                with сам.assertRaisesRegex(ValueError, 'публикац'):
                    ф.объявить_готовность()

    def test_прямой_create_не_принимает_прежний_успешный_uuid_за_публикацию(сам):
        ф = Фикстура(сам, текст=запрещённая_строка() + '\n')
        ф.подготовить()
        _, п = коммит.прочитать_подготовку_готовности(Path(ф.п['подготовка']), доверенное_поручение=ф.д.выбор)
        д = коммит.проверки(ф.корень, п, ф.номера)
        коммит.готовность.объявить(п, коммит.готовность.снимок(п, коммит.команды(п), ф.номера, д),
            д['свидетельства'], 600)
        голова = ф.ф.гит('rev-parse', 'HEAD')
        with сам.assertRaisesRegex(ValueError, 'публикац'):
            ф.создать()
        сам.assertEqual(голова, ф.ф.гит('rev-parse', 'HEAD'))
        сам.assertFalse(Path(ф.п['квитанция']).exists())

    def test_дрейф_чистых_входов_во_время_сканирования(сам):
        ф = Фикстура(сам); ф.подготовить()
        with изолированный_код(ф) as м:
            for граница in ('индекс', 'policy', 'сканер', 'зависимость'):
                with сам.subTest(граница=граница):
                    путь = (ф.корень / (ф.предмет if граница == 'индекс' else ПОЛИТИКА)
                        if граница in {'индекс', 'policy'} else м.КОРЕНЬ_КОДА / м.ИСХОДНИКИ_СКАНЕРА[
                            2 if граница == 'сканер' else 0][1])
                    до = путь.read_bytes(); прежний = м.сканер
                    @contextlib.contextmanager
                    def сканер_с_дрейфом(сырые):
                        with прежний(сырые) as с:
                            функция = с.scan_text
                            изменён = False
                            def чтение(*а, **к):
                                nonlocal изменён
                                if not изменён:
                                    изменён = True
                                    путь.write_bytes(до + (b' ' if граница == 'policy' else b'\n# drift\n'))
                                    if граница in {'индекс', 'policy'}:
                                        ф.ф.гит('add', str(путь.relative_to(ф.корень)))
                                return функция(*а, **к)
                            с.scan_text = чтение
                            yield с
                    м.сканер = сканер_с_дрейфом
                    try:
                        with сам.assertRaisesRegex(ValueError, 'публикац'):
                            ф.объявить_готовность()
                        сам.assertFalse(коммит.готовность.путь_этапа(ф.п).exists())
                        сам.assertFalse(Path(ф.п['квитанция']).exists())
                    finally:
                        м.сканер = прежний; путь.write_bytes(до)
                        if граница in {'индекс', 'policy'}:
                            ф.ф.гит('add', str(путь.relative_to(ф.корень)))

    def test_чистый_дрейф_между_ready_и_create_не_получает_старый_допуск(сам):
        ф = Фикстура(сам); ф.подготовить()
        with изолированный_код(ф) as м:
            ф.объявить_готовность()
            for граница in ('индекс', 'policy', 'сканер', 'зависимость'):
                with сам.subTest(граница=граница):
                    путь = (ф.корень / (ф.предмет if граница == 'индекс' else ПОЛИТИКА)
                        if граница in {'индекс', 'policy'} else м.КОРЕНЬ_КОДА / м.ИСХОДНИКИ_СКАНЕРА[
                            2 if граница == 'сканер' else 0][1])
                    до = путь.read_bytes(); голова = ф.ф.гит('rev-parse', 'HEAD')
                    try:
                        путь.write_bytes(до + (b' ' if граница == 'policy' else b'\n# drift\n'))
                        if граница in {'индекс', 'policy'}:
                            ф.ф.гит('add', str(путь.relative_to(ф.корень)))
                        with сам.assertRaises(ValueError):
                            ф.создать()
                        сам.assertFalse(Path(ф.п['квитанция']).exists())
                        сам.assertEqual(голова, ф.ф.гит('rev-parse', 'HEAD'))
                    finally:
                        путь.write_bytes(до)
                        if граница in {'индекс', 'policy'}:
                            ф.ф.гит('add', str(путь.relative_to(ф.корень)))

    def test_поздний_дрейф_под_настоящим_замком_ready(сам):
        ф = Фикстура(сам); ф.подготовить()
        прежний = коммит.готовность.файлы._замок
        целевой = коммит.готовность.путь_этапа(ф.п)
        @contextlib.contextmanager
        def замок_с_дрейфом(путь):
            with прежний(путь):
                if Path(путь) == целевой:
                    политика = ф.корень / ПОЛИТИКА
                    политика.write_bytes(политика.read_bytes() + b' ')
                    ф.ф.гит('add', ПОЛИТИКА)
                yield
        коммит.готовность.файлы._замок = замок_с_дрейфом
        try:
            with сам.assertRaisesRegex(ValueError, 'публикац'):
                ф.объявить_готовность()
            сам.assertFalse(целевой.exists())
            сам.assertFalse(Path(ф.п['квитанция']).exists())
        finally:
            коммит.готовность.файлы._замок = прежний

    def test_неизвестный_настоящий_процесс_не_повторяет_коммит(сам):
        ф = Фикстура(сам); ф.подготовить(); ф.объявить_готовность()
        метка = ф.приватный / 'hook-process.json'
        крючок = ф.корень / '.git/hooks/pre-commit'
        крючок.write_text('#!' + sys.executable + '\nimport os,json,time\nfrom pathlib import Path\n'
            + 'Path(' + repr(str(метка)) + ').write_text(json.dumps({"pid":os.getpid(),"pgid":os.getpgrp()}))\n'
            + 'time.sleep(120)\n')
        крючок.chmod(0o755)
        а = ['создать', '--подготовка', ф.п['подготовка'], '--доверенное-поручение', str(ф.приватный / 'выбор.json')]
        for н in ф.номера:
            а += ['--проверка', н]
        процесс = subprocess.Popen(ф.ф.команда_CLI(*а), cwd=ф.корень,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
        группа = None
        try:
            предел = time.monotonic() + 30
            while not метка.exists() and процесс.poll() is None and time.monotonic() < предел:
                time.sleep(0.02)
            сам.assertTrue(метка.exists())
            наблюдение = json.loads(метка.read_text()); группа = наблюдение['pgid']
            сам.assertEqual(группа, os.getpgid(наблюдение['pid']))
            сам.assertNotEqual(os.getpgrp(), группа)
            сам.assertNotEqual(процесс.pid, группа)
            квитанция = Path(ф.п['квитанция'])
            сам.assertEqual('намерение', json.loads(квитанция.read_bytes())['состояние'])
            os.killpg(процесс.pid, signal.SIGKILL)
            os.killpg(группа, signal.SIGKILL)
            процесс.communicate(timeout=5)
            сырые = квитанция.read_bytes(); голова = ф.ф.гит('rev-parse', 'HEAD')
            сам.assertNotIn('процесс', json.loads(сырые))
            with сам.assertRaises(ValueError):
                ф.создать()
            повтор = subprocess.run(ф.ф.команда_CLI(*а), cwd=ф.корень, capture_output=True, timeout=15)
            ф.исходы.append({'стадия': 'повтор-CLI-unknown', 'код': повтор.returncode,
                'stdout': повтор.stdout.decode(), 'stderr': повтор.stderr.decode()})
            сам.assertNotEqual(0, повтор.returncode)
            сам.assertEqual(сырые, квитанция.read_bytes())
            сам.assertEqual(голова, ф.ф.гит('rev-parse', 'HEAD'))
            сам.assertEqual(наблюдение, json.loads(метка.read_text()))
        finally:
            for г in (процесс.pid, группа):
                if г is not None:
                    try:
                        os.killpg(г, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
            процесс.communicate(timeout=5)

    def test_последняя_сверка_после_write_tree_отказывает_до_commit(сам):
        ф = Фикстура(сам); ф.подготовить(); ф.объявить_готовность()
        прежний = коммит.гит; коммитов = 0
        def наблюдать(корень, *аргументы, **поля):
            nonlocal коммитов
            if аргументы[0] == 'commit':
                коммитов += 1
            исход = прежний(корень, *аргументы, **поля)
            if аргументы[0] == 'write-tree':
                ф.корень.joinpath(ПОЛИТИКА).write_bytes(ф.корень.joinpath(ПОЛИТИКА).read_bytes() + b' ')
                ф.ф.гит('add', ПОЛИТИКА)
            return исход
        коммит.гит = наблюдать
        try:
            with сам.assertRaisesRegex(ValueError, 'публикац'):
                ф.создать()
            сам.assertEqual(0, коммитов)
            сохранённая = Path(ф.п['квитанция']).read_bytes()
            сам.assertEqual('намерение', json.loads(сохранённая)['состояние'])
            with сам.assertRaisesRegex(ValueError, 'повтор запрещён'):
                ф.создать()
            сам.assertEqual(сохранённая, Path(ф.п['квитанция']).read_bytes())
        finally:
            коммит.гит = прежний


class ПриватныйВыходПрофиля(unittest.TestCase):
    def test_занятый_символический_и_поздно_занятый_выход_сохраняются(сам):
        import профиль_публикационного_допуска_дочернего_состава as п
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            занят = корень / 'занятый.json'; занят.write_bytes(b'occupied')
            with сам.assertRaises(FileExistsError):
                п.резервировать(занят)
            ссылка = корень / 'ссылка.json'; ссылка.symlink_to(занят)
            with сам.assertRaises(FileExistsError):
                п.резервировать(ссылка)
            поздний = корень / 'поздний.json'; д = п.резервировать(поздний)
            try:
                поздний.unlink(); поздний.write_bytes(b'late occupied'); поздний.chmod(0o600)
                with сам.assertRaises(ValueError):
                    п.установить(д, поздний, b'overwrite')
                сам.assertEqual(b'late occupied', поздний.read_bytes())
                сам.assertEqual(b'occupied', занят.read_bytes())
            finally:
                os.close(д)

    def test_поздняя_запись_в_тот_же_inode_сохраняется(сам):
        import профиль_публикационного_допуска_дочернего_состава as п
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve(); путь = корень / 'выход.json'
            д = п.резервировать(путь)
            try:
                путь.write_bytes(b'late occupied')
                with сам.assertRaises(ValueError):
                    п.установить(д, путь, b'overwrite')
                сам.assertEqual(b'late occupied', путь.read_bytes())
            finally:
                os.close(д)

    def test_подмена_родителя_ссылкой_сохраняется(сам):
        import профиль_публикационного_допуска_дочернего_состава as п
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve(); родитель = корень / 'родитель'; родитель.mkdir(mode=0o700)
            путь = родитель / 'выход.json'; д = п.резервировать(путь)
            try:
                исходные = путь.read_bytes(); перенесённый = корень / 'перенесённый'
                родитель.rename(перенесённый); родитель.symlink_to(перенесённый, target_is_directory=True)
                with сам.assertRaises(ValueError):
                    п.установить(д, путь, b'overwrite')
                сам.assertEqual(исходные, путь.read_bytes())
            finally:
                os.close(д)


class ПаритетСканера(unittest.TestCase):
    def test_полные_binary_external_и_context_результаты_совпадают(сам):
        import публикационный_допуск_дочернего_состава as м
        ствол = 'Журнал/2026-08-13_18-17-47_MSK_fixture/'
        номер = '11111111-1111-4111-8111-111111111111'
        исполнитель = chr(47) + 'root' + chr(47) + 'fixture'
        запрос = ствол + 'запрос.md'
        запись = {'схема': 'fum.test-run.v1', 'сессия': запрос, 'порядок': 1, 'идентификатор': номер,
            'состояние': 'завершён', 'исполнитель': исполнитель, 'вызов': 'Проверка',
            'длительность_наносекунды': 1, 'статус': 'успешно', 'код_завершения': 0, 'пояснение': None}
        данные = {ПОЛИТИКА: примеры.байты({'schema': 'fum.machine-local-path-policy.v2', 'exceptions': []}),
            'данные.bin': b'\0binary', 'Источники/URL/https/example.test/raw.bin': b'\0binary',
            'Источники/URL/https/example.test/raw.txt': b'\xff',
            ствол + 'материалы/источники/описание/вложение.bin': b'\0binary',
            ствол + 'материалы/источники/описание/не-utf8.bin': b'\xff',
            запрос: ('# Запрос\n\n## Текст запроса\n\n```text\n' + запрещённая_строка() + '\n```\n').encode(),
            ствол + 'материалы/запуски-проверок/1_' + номер + '.json': примеры.байты(запись),
            ствол + 'отчёт.md': ('# Отчёт\n\n<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->\n'
                '| Вызов | Длительность | Результат |\n| ------ | ------------ | --------- |\n'
                + '| [' + исполнитель + '] Проверка | 0,001 с | успешно |\n<!-- FUM-CHECK-RUNS:END -->\n'
                + 'Вне блока: ' + исполнитель + '\n').encode()}
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            subprocess.run(['git', 'init', '-q', str(корень)], check=True)
            for путь, д in данные.items():
                ф = корень / путь; ф.parent.mkdir(parents=True, exist_ok=True); ф.write_bytes(д)
            subprocess.run(['git', '-C', str(корень), 'add', '.'], check=True)
            with м.сканер(м.код(коммит)) as с:
                прежний = с.scan_repository(корень, корень / ПОЛИТИКА)
                новый = м.сканировать(с, данные, list(данные), м.разобрать(данные[ПОЛИТИКА]))
            сам.assertEqual({'код': прежний.exit_code, 'находки': [
                {'путь': э.path, 'строка': э.line, 'категория': э.category} for э in прежний.findings]}, новый)
            категории = {э['категория'] for э in новый['находки']}
            сам.assertIn('report.external-source.binary', категории)
            сам.assertIn('error.binary-input', категории)
            сам.assertIn('error.non-utf8-input', категории)
            параметры = {'схема': 'fum.создание-коммита.7', 'корень': str(корень),
                'разрешённые_цели': [*данные, 'отсутствующий.txt'], 'запрос': запрос}
            with сам.assertRaisesRegex(ValueError, 'отсутствующая разрешённая цель'):
                м.построить(параметры, коммит)

    def test_полная_policy_проверяется_до_отбора_и_aliases_восстанавливаются(сам):
        import публикационный_допуск_дочернего_состава as м
        до = sys.modules.get('path_forms'); присутствовал = 'path_forms' in sys.modules
        sys.modules['path_forms'] = None
        try:
            with м.сканер(м.код(коммит)) as с:
                with сам.assertRaises(ValueError):
                    м.сканировать(с, {'предмет.txt': b'clean'}, ['предмет.txt'],
                        {'schema': 'fum.machine-local-path-policy.v2', 'exceptions': [{'path': 'иной.txt'}]})
            сам.assertIn('path_forms', sys.modules)
            сам.assertIsNone(sys.modules['path_forms'])
        finally:
            if присутствовал:
                sys.modules['path_forms'] = до
            else:
                sys.modules.pop('path_forms', None)


if __name__ == '__main__':
    unittest.main()
