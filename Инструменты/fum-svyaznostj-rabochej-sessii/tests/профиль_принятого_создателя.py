"""Парный профиль полного разбора и свежего файлового barrier; production не измеряется."""
import argparse
import cProfile
import hashlib
import json
import os
from pathlib import Path
import pstats
import resource
import statistics
import struct
import subprocess
import sys
import tempfile
import time
import types

БАЗА = '0fadd035f3bca1b669ec7c9269e2db954552fd23'
ОТПЕЧАТОК_БАЗЫ = '87783ee1814ff87a92f8f941f6489742aec7802c86f4b5786701ef7dbd2a859b'
ПУСК = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/запуск_принятого_создателя.py'
ЧИТАТЕЛЬ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/чтение_цепочки_подготовки.py'
КОММИТ_ЧИТАТЕЛЯ = '712da538a86171cbcbf9b10827bedb1c97a87354'
ОТПЕЧАТОК_ЧИТАТЕЛЯ = 'd91a595143c90995747375680596644fce1edbf4faf3127586741e533e81a7b8'


def корпус(число, *, регистрация=None, обычный_объект=None):
    записи = dict(регистрация) if регистрация is not None else {
        '.gitmodules': (0o100644, '22' * 20), 'Зависимости/открытая': (0o160000, '33' * 20)}
    if число < len(записи):
        raise ValueError('корпус меньше обязательной регистрации')
    for номер in range(число - len(записи)):
        имя = 'данные/' + str(номер).zfill(5) + '-' + 'x' * 159 + '.txt'
        if имя in записи:
            raise ValueError('обычный путь пересекает регистрацию')
        записи[имя] = (0o100644, обычный_объект or hashlib.sha1(str(номер).encode()).hexdigest())
    части = [b'DIRC' + struct.pack('>II', 2, число)]
    for имя, (режим, объект) in sorted(записи.items(), key=lambda з: os.fsencode(з[0])):
        имя = имя.encode()
        заголовок = bytearray(40)
        заголовок[24:28] = struct.pack('>I', режим)
        запись = bytes(заголовок) + bytes.fromhex(объект) + struct.pack('>H', len(имя)) + имя + bytes(1)
        части.append(запись + bytes((-len(запись)) % 8))
    тело = b''.join(части)
    return тело + hashlib.sha1(тело).digest(), записи


def загрузить(путь, ожидаемый, имя):
    сырые = Path(путь).read_bytes()
    if hashlib.sha256(сырые).hexdigest() != ожидаемый:
        raise ValueError('изменён закреплённый исходник ' + имя)
    модуль = types.ModuleType('парсер_' + имя)
    модуль.__file__ = str(путь)
    exec(compile(сырые, str(путь), 'exec', dont_inherit=True), модуль.__dict__)
    return модуль


def измерить_разбор(модуль, данные, ожидаемые, *, новый):
    кэш = модуль.КэшРазбораИндекса() if новый else None
    времена, результаты = [], []
    for _ in range(3):
        начало = time.perf_counter_ns()
        ответ = кэш.разобрать(данные, полный=True) if новый else модуль.регистрация_индекса(данные, полный=True)
        времена.append(time.perf_counter_ns() - начало)
        результаты.append(ответ)
    снимок = кэш.снимок() if новый else None
    if any(р != ожидаемые for р in результаты):
        raise ValueError('полный parser изменил результат')
    if новый and (снимок['полных_разборов'], снимок['попаданий'], снимок['промахов']) != (1, 2, 1):
        raise ValueError('не подтверждены cold MISS и два warm HIT')
    return {'вызовы_нс': времена, 'cold_нс': времена[0], 'warm_нс': времена[1:],
        'сумма_вызовов_нс': sum(времена), 'кэш': снимок,
        'SHA1_байтов_расчётно': (1 if новый else 3) * (len(данные) - 20),
        'граница': 'Только три полных вызова parser/cache API; setup, загрузка, сравнение результатов и JSON исключены. Full parser включает SHA1 и helpers.'}


def измерить_чтение(модуль, путь):
    ожидаемый = модуль.файловый_срез(путь)
    отпечаток = hashlib.sha256(ожидаемый[1]).hexdigest()
    времена, равенства = [], []
    for _ in range(3):
        начало = time.perf_counter_ns()
        текущий = модуль.файловый_срез(путь)
        отпечаток_текущего = модуль.hashlib.sha256(текущий[1]).hexdigest()
        совпало = текущий == ожидаемый and отпечаток_текущего == отпечаток
        времена.append(time.perf_counter_ns() - начало)
        равенства.append(совпало)
    if not all(равенства):
        raise ValueError('свежее чтение/barrier не сохранило metadata/bytes/SHA')
    return {'вызовы_нс': времена, 'сумма_вызовов_нс': sum(времена),
        'свежих_чтений': 3, 'SHA256_байтов_расчётно': 3 * len(ожидаемый[1]),
        'граница': 'Три файловый_срез→SHA256→точное сравнение metadata/bytes/hash. Parser и SHA1 отсутствуют; первоначальный ожидаемый срез вне таймера.'}


def диагностика(модуль, данные, путь, ожидаемые, *, новый):
    кэш = модуль.КэшРазбораИндекса() if новый else None
    ожидаемый = модуль.файловый_срез(путь)
    отпечаток = hashlib.sha256(ожидаемый[1]).hexdigest()
    профилировщик = cProfile.Profile()
    результаты, равенства = [], []
    профилировщик.enable()
    for _ in range(3):
        результаты.append(кэш.разобрать(данные, полный=True) if новый else модуль.регистрация_индекса(данные, полный=True))
    for _ in range(3):
        текущий = модуль.файловый_срез(путь)
        текущий_хэш = модуль.hashlib.sha256(текущий[1]).hexdigest()
        равенства.append(текущий == ожидаемый and текущий_хэш == отпечаток)
    профилировщик.disable()
    снимок = кэш.снимок() if новый else None
    if not all(равенства) or any(р != ожидаемые for р in результаты):
        raise ValueError('диагностический parser/barrier изменился')
    группы = dict(чтение=0, SHA1=0, SHA256=0, общий_hash=0, парсер=0, прочее=0)
    вызовы = dict(полный_парсер=0, SHA1=0, SHA256=0)
    исходник = str(модуль.__file__)
    # pstats использует ASCII126 как псевдофайл встроенных функций.
    псевдофайл = chr(126)
    стандартные_чтения = {(ф.__code__.co_filename, ф.__code__.co_firstlineno, ф.__name__)
        for ф in (Path.read_bytes, Path.lstat)}
    чтений = 0
    for (файл, строка, имя), (_, число, собственное, _, _) in pstats.Stats(профилировщик).stats.items():
        if файл == псевдофайл and имя == '<built-in method _hashlib.openssl_sha1>':
            группа = 'SHA1'; вызовы['SHA1'] += число
        elif файл == псевдофайл and имя == '<built-in method _hashlib.openssl_sha256>':
            группа = 'SHA256'; вызовы['SHA256'] += число
        elif файл == псевдофайл and ('hexdigest' in имя or 'digest' in имя):
            группа = 'общий_hash'
        elif файл == исходник and (строка, имя) in ((модуль.регистрация_индекса.__code__.co_firstlineno, 'регистрация_индекса'),
                (модуль.относительный_путь.__code__.co_firstlineno, 'относительный_путь')):
            группа = 'парсер'
            if имя == 'регистрация_индекса': вызовы['полный_парсер'] += число
        elif (файл == исходник and (строка, имя) == (модуль.файловый_срез.__code__.co_firstlineno, 'файловый_срез')):
            группа = 'чтение'
            чтений += число
        elif (файл, строка, имя) in стандартные_чтения or (файл == псевдофайл and '_io.' in имя and 'read' in имя):
            группа = 'чтение'
        else: группа = 'прочее'
        группы[группа] += int(собственное * 1_000_000_000)
    вызовы['файловых_срезов'] = чтений
    return {'непересекающиеся_tottime_нс': группы, 'наблюдённые_вызовы': вызовы, 'кэш': снимок,
        'граница': 'Отдельный диагностический корпус 512 строк: 3 parser и 3 fresh-read вызова; cProfile exclusive tottime, cumtime не складываются. Digest общий, не приписан SHA1/SHA256. Это не времена большого корпуса.'}


def рабочий_процесс(вход):
    if not (sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode):
        raise ValueError('профилю нужен свежий -I -S -B')
    настройки = json.loads(Path(вход).read_bytes())
    исполненный_отпечаток = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    if исполненный_отпечаток != настройки['профиль_sha256']:
        raise ValueError('изменён закреплённый исполняемый профиль')
    модули = {имя: загрузить(з['путь'], з['sha256'], имя) for имя, з in настройки['исходники'].items()}
    большие, ожидаемые = корпус(33405)
    малые, ожидаемые_малые = корпус(512)
    if hashlib.sha256(большие).hexdigest() != настройки['корпус_sha256']:
        raise ValueError('изменён открытый корпус')
    путь = Path(настройки['каталог']) / ('index-' + str(os.getpid()))
    путь.write_bytes(большие)
    малый_путь = путь.with_name(путь.name + '-512')
    малый_путь.write_bytes(малые)
    результаты = {}
    for имя in настройки['порядок']:
        модуль = модули[имя]
        результаты[имя] = {'разбор': измерить_разбор(модуль, большие, ожидаемые, новый=имя == 'B'),
            'свежее_чтение': измерить_чтение(модуль, путь)}
    for имя in настройки['порядок']:
        результаты[имя]['диагностика_512'] = диагностика(модули[имя], малые, малый_путь, ожидаемые_малые, новый=имя == 'B')
    return {'pid': os.getpid(), 'порядок': настройки['порядок'], 'результаты': результаты,
        'строк': 33405, 'байтов': len(большие), 'корпус_sha256': настройки['корпус_sha256'], 'исполненный_профиль_sha256': исполненный_отпечаток}


def главная():
    п = argparse.ArgumentParser(description=__doc__)
    п.add_argument('--выход')
    п.add_argument('--рабочий-вход')
    п.add_argument('--поздний-рабочий-вход')
    п.add_argument('--цепочка', choices=('чтение', 'цикл', 'прежний-цикл', 'поздний-индекс'))
    п.add_argument('--повторы', type=int, default=3)
    а = п.parse_args()
    if а.поздний_рабочий_вход:
        print(json.dumps(рабочий_процесс_позднего_индекса(а.поздний_рабочий_вход), ensure_ascii=False))
        return 0
    if а.цепочка == 'поздний-индекс':
        return профиль_позднего_индекса(а)
    if а.цепочка:
        return профиль_цепочки(а)
    if а.рабочий_вход:
        print(json.dumps(рабочий_процесс(а.рабочий_вход), ensure_ascii=False))
        return 0
    if not а.выход: п.error('нужен новый приватный выход')
    корень = Path(__file__).resolve().parents[3]
    выход = Path(а.выход)
    if not выход.is_absolute() or выход != выход.resolve() or any(os.path.lexists(п / '.git') for п in выход.parents):
        raise ValueError('нужен физический приватный выход вне Git')
    А = subprocess.check_output(['git', '--no-optional-locks', '-C', str(корень), 'show', БАЗА + ':' + ПУСК])
    if hashlib.sha256(А).hexdigest() != ОТПЕЧАТОК_БАЗЫ:
        raise ValueError('неизменный baseline H2 не подтверждён')
    состав = {п: hashlib.sha256((корень / п).read_bytes()).hexdigest() for п in (ПУСК, str(Path(__file__).relative_to(корень)))}
    большие, _ = корпус(33405)
    запуски = []
    with tempfile.TemporaryDirectory(prefix='fum-profile-', dir=выход.parent) as временный:
        каталог = Path(временный).resolve()
        путь_А = каталог / 'принятый-H2.py'
        путь_А.write_bytes(А)
        путь_А.chmod(0o400)
        профиль = каталог / 'закреплённый-профиль.py'
        профиль.write_bytes(Path(__file__).read_bytes())
        профиль.chmod(0o400)
        отпечаток_профиля = hashlib.sha256(профиль.read_bytes()).hexdigest()
        for номер, порядок in enumerate(('AB', 'BA', 'AB')):
            настройки = {'исходники': {'A': {'путь': str(путь_А), 'sha256': ОТПЕЧАТОК_БАЗЫ},
                'B': {'путь': str(корень / ПУСК), 'sha256': состав[ПУСК]}},
                'каталог': str(каталог), 'корпус_sha256': hashlib.sha256(большие).hexdigest(), 'порядок': порядок, 'профиль_sha256': отпечаток_профиля}
            вход = каталог / ('вход-' + str(номер) + '.json')
            вход.write_text(json.dumps(настройки, ensure_ascii=False))
            р = subprocess.run([sys.executable, '-I', '-S', '-B', str(профиль), '--рабочий-вход', str(вход)],
                capture_output=True, text=True, timeout=180)
            if р.returncode: raise ValueError('свежий профиль отказал: ' + р.stderr)
            запуски.append(json.loads(р.stdout))
    if len({р['pid'] for р in запуски}) != 3 or any(hashlib.sha256((корень / п).read_bytes()).hexdigest() != отпечаток_исходника for п, отпечаток_исходника in состав.items()):
        raise ValueError('не свежие процессы или изменён состав')
    медианы = {компонент: {имя: int(statistics.median(р['результаты'][имя][компонент]['сумма_вызовов_нс'] for р in запуски))
        for имя in ('A', 'B')} for компонент in ('разбор', 'свежее_чтение')}
    итог = {'схема': 'fum.профиль-принятого-создателя.3', 'принятый_исходник': {'коммит': БАЗА, 'sha256': ОТПЕЧАТОК_БАЗЫ},
        'состав_sha256': состав, 'запуски': запуски, 'медианы_нс': медианы,
        'production_ускорение_доказано': False, 'настоящая_приёмка': False, 'кэш_ОС_очищен': False,
        'граница': 'Два раздельных компонента не складываются в production guard; 1 cold + 2 warm parser и 3 fresh read на вариант. Setup/compile/корпус/проверка/JSON исключены. AB/BA/AB, три свежих процесса; диагностический малый cProfile отдельно.',
        'среда': {'python': sys.version, 'платформа': sys.platform}}
    with os.fdopen(os.open(выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'w') as поток:
        json.dump(итог, поток, ensure_ascii=False, sort_keys=True, indent=2); поток.write('\n')
    print(json.dumps({'свежих_процессов': 3, 'медианы_нс': медианы, 'production_ускорение_доказано': False}, ensure_ascii=False))
    return 0


def профиль_цепочки(а):
    """Полный mixed reader либо настоящий consumer после D.4; setup вне таймера."""
    if not а.выход or not 1 <= а.повторы <= 10:
        raise ValueError('нужны новый приватный выход и от одного до десяти повторов')
    корень = Path(__file__).resolve().parents[3]
    выход = Path(а.выход)
    if not выход.is_absolute() or выход != выход.resolve() or any(os.path.lexists(п / '.git') for п in выход.parents):
        raise ValueError('нужен физический приватный выход вне Git')
    for путь in ('Инструменты/fum-proverka-git-zavisimostej/tests',
                 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts',
                 'Инструменты/fum-svyaznostj-rabochej-sessii/tests'):
        sys.path.insert(0, str(корень / путь))
    import test_чтения_цепочки_подготовки as чтение
    import test_принятого_создателя as создатель
    import чтение_цепочки_подготовки as читатель
    пути = [ПУСК, 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/чтение_цепочки_подготовки.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/состав-принятого-писателя.json',
        str(Path(__file__).relative_to(корень))]
    пути += [str(п.relative_to(корень)) for п in корень.glob('Инструменты/fum-proverka-git-zavisimostej/scripts/*.py')]
    пути += [str(п.relative_to(корень)) for п in корень.glob('Инструменты/fum-proverka-git-zavisimostej/tests/test_*.py')]
    пути += [str(п.relative_to(корень)) for п in корень.glob('Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_*.py')]
    состав_кода = json.loads((корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/состав-принятого-писателя.json').read_bytes())
    пути.extend([*состав_кода['код'], *состав_кода['ресурсы'],
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/вход_принятого_создателя.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/исполнение_принятого_кода.py'])
    состав = {п: hashlib.sha256((корень / п).read_bytes()).hexdigest() for п in sorted(set(пути))}
    запуски = []
    for _ in range(а.повторы):
        ф = (чтение.ЧтениеЦепочкиПодготовки if а.цепочка == 'чтение' else создатель.ПринятыйСоздатель)('runTest')
        ф.setUp()
        try:
            if а.цепочка != 'чтение':
                if а.цепочка == 'цикл':
                    ф.test_смена_ветки_сохраняет_подготовку_в_полном_цикле()
                else:
                    ф.test_зарегистрированная_вложенная_копия_проходит_полный_цикл()
                запуски.append({'процессы': ф.профиль, 'неизменность_цепочки_и_листьев': True,
                    'коммит_кода_фикстуры': ф.к, 'основа_данных': ф.база, 'пин': ф.пин_зависимости})
            else:
                ф.создать_цепочку(смешанная=True)
                до = ф.срез()
                профилировщик = cProfile.Profile()
                профилировщик.enable()
                начало = time.perf_counter_ns()
                допуск = ф.допустить()
                первичное = time.perf_counter_ns() - начало
                сверки = []
                for _ in range(3):
                    начало = time.perf_counter_ns()
                    читатель.сверить_чтение_цепочки(допуск)
                    сверки.append(time.perf_counter_ns() - начало)
                профилировщик.disable()
                if до != ф.срез():
                    raise ValueError('профиль чтения изменил fixture')
                статистика = [{'файл': Path(файл).name, 'имя': имя, 'вызовов': число,
                    'собственное_нс': int(собственное * 1e9)}
                    for (файл, _, имя), (_, число, собственное, _, _) in pstats.Stats(профилировщик).stats.items()]
                запуски.append({'первичное_чтение_нс': первичное, 'сверки_нс': сверки,
                    'диагностика': sorted(статистика, key=lambda з: з['собственное_нс'], reverse=True)[:20]})
        finally:
            ф.doCleanups()
    if any(hashlib.sha256((корень / п).read_bytes()).hexdigest() != х for п, х in состав.items()):
        raise ValueError('исходники профиля изменились')
    итог = {'схема': 'fum.профиль-цепочки-подготовки.1', 'режим': а.цепочка,
        'состав_sha256': состав, 'запуски': запуски, 'кэш_ОС_очищен': False,
        'граница': 'Малая реальная Git fixture, setup и assertions исключены из API-времён. Вложенные интервалы cProfile не суммируются. Consumer использует четыре свежих процесса. Производственная приёмка отдельно.',
        'среда': {'python': sys.version, 'платформа': sys.platform}}
    with os.fdopen(os.open(выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'w') as поток:
        json.dump(итог, поток, ensure_ascii=False, sort_keys=True, indent=2); поток.write('\n')
    print(json.dumps({'режим': а.цепочка, 'повторов': len(запуски), 'исходники_неизменны': True}, ensure_ascii=False))
    return 0


def рабочий_процесс_позднего_индекса(вход):
    """Один вариант, один настоящий допуск; первичная и поздние границы раздельны."""
    if not (sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode):
        raise ValueError('профилю нужен свежий -I -S -B')
    настройки = json.loads(Path(вход).read_bytes())
    if hashlib.sha256(Path(__file__).read_bytes()).hexdigest() != настройки['профиль_sha256']:
        raise ValueError('изменён исполняемый профиль')
    корень = Path(настройки['корень_кода'])
    for путь in ('Инструменты/fum-proverka-git-zavisimostej/tests',
                 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts',
                 'Инструменты/fum-svyaznostj-rabochej-sessii/tests'):
        sys.path.insert(0, str(корень / путь))
    import test_чтения_цепочки_подготовки as чтение
    from unittest import mock
    модуль = загрузить(настройки['исходник']['путь'], настройки['исходник']['sha256'], настройки['вариант'])
    ф = чтение.ЧтениеЦепочкиПодготовки('runTest')
    ф.корень, ф.база, ф.вызовы = Path(настройки['данные']), настройки['база'], []
    os.environ['CODEX_THREAD_ID'] = настройки['исполнитель']
    индекс = Path(настройки['индекс'])
    сырые = индекс.read_bytes()
    if hashlib.sha256(сырые).hexdigest() != настройки['корпус_sha256']:
        raise ValueError('изменён файловый корпус индекса')
    разбор, чтение_файла = модуль.регистрация_индекса, модуль._прочитать
    метрики = dict(вызовов_парсера=0, время_парсера_нс=0, прочитано_байтов=0, индекс_байтов=0, чтений_индекса=0, пути=[])
    def разобрать(*аргументы, **параметры):
        начало = time.perf_counter_ns()
        try:
            return разбор(*аргументы, **параметры)
        finally:
            метрики['вызовов_парсера'] += 1
            метрики['время_парсера_нс'] += time.perf_counter_ns() - начало
    def прочитать(путь, *аргументы, **параметры):
        результат = чтение_файла(путь, *аргументы, **параметры)
        метрики['пути'].append(str(путь))
        if результат is not None:
            длина = len(результат[1]); метрики['прочитано_байтов'] += длина
            if Path(путь) == индекс:
                метрики['индекс_байтов'] += длина; метрики['чтений_индекса'] += 1
        return результат
    def снимок():
        return {к: з for к, з in метрики.items() if к != 'пути'} | {
            'пути_sha256': hashlib.sha256(json.dumps(метрики['пути'], ensure_ascii=False).encode()).hexdigest()}
    модуль.регистрация_индекса, модуль._прочитать = разобрать, прочитать
    начало = time.perf_counter_ns()
    допуск = модуль.допустить_чтение_цепочки(настройки['выбор'], корень=ф.корень,
        исходный_коммит=ф.база, ветка=настройки['ветка'], исполнитель=настройки['исполнитель'],
        корневая_задача=настройки['координатор'], гит=ф.гит)
    первичное = {'время_нс': time.perf_counter_ns() - начало, **снимок()}
    статистика = getattr(модуль, 'профиль_запоминания_индекса', None)
    до = статистика(допуск) if статистика else None
    метрики = dict(вызовов_парсера=0, время_парсера_нс=0, прочитано_байтов=0, индекс_байтов=0, чтений_индекса=0, пути=[])
    сверки = []
    with mock.patch.object(subprocess, 'Popen', side_effect=ValueError('процесс в поздней сверке')):
        with mock.patch.object(os, 'killpg', side_effect=ValueError('проверка группы в поздней сверке')):
            for _ in range(3):
                начало = time.perf_counter_ns()
                модуль.сверить_чтение_цепочки(допуск)
                сверки.append(time.perf_counter_ns() - начало)
    позднее = {'вызовы_нс': сверки, 'время_нс': sum(сверки), **снимок()}
    после = статистика(допуск) if статистика else None
    if позднее['чтений_индекса'] != 3 or позднее['индекс_байтов'] != 3 * len(сырые):
        raise ValueError('поздние границы не прочитали полный индекс')
    новый = настройки['вариант'] == 'B'
    if позднее['вызовов_парсера'] != (0 if новый else 3):
        raise ValueError('не подтверждён прежний разбор либо повторное использование')
    запоминание = None if после is None else {
        'попадания': после['попадания'] - до['попадания'],
        'промахи': после['промахи'] - до['промахи'],
        'удержано_байтов': после['удержано_байтов'],
        'всего_удержано_байтов': после['всего_удержано_байтов']}
    if новый and (запоминание['попадания'], запоминание['промахи']) != (3, 0):
        raise ValueError('не подтверждены три поздних попадания')
    if hashlib.sha256(индекс.read_bytes()).hexdigest() != настройки['корпус_sha256']:
        raise ValueError('изменён индекс после чтения')
    пик = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    if sys.platform != 'darwin': пик *= 1024
    return {'процесс': os.getpid(), 'вариант': настройки['вариант'], 'исход': 'успешно',
        'первичный_допуск': первичное, 'поздние_сверки': позднее, 'запоминание': запоминание,
        'пик_резидентной_памяти_байтов': пик, 'корпус_sha256': настройки['корпус_sha256'],
        'исходник_sha256': настройки['исходник']['sha256'], 'границ': 3}


def запустить_поздний_процесс(команда, *, каталог, имя, сохранить):
    """Сырые каналы отказа сохраняются и при превышении предела времени."""
    try:
        процесс = subprocess.run(команда, capture_output=True, timeout=120)
    except subprocess.TimeoutExpired as отказ:
        сохранить(каталог / (имя + '.stdout'), отказ.stdout or b'')
        сохранить(каталог / (имя + '.stderr'), отказ.stderr or b'')
        сохранить(каталог / (имя + '-завершение.json'),
            (json.dumps({'исход': 'тайм-аут', 'предел_секунд': 120}, ensure_ascii=False) + '\n').encode())
        raise
    сохранить(каталог / (имя + '.stdout'), процесс.stdout)
    сохранить(каталог / (имя + '.stderr'), процесс.stderr)
    return процесс


def профиль_позднего_индекса(а):
    """Три пары АБ/БА/АБ, шесть новых процессов на одном неизменном файловом корпусе."""
    if not а.выход or а.повторы != 3:
        raise ValueError('поздний профиль требует ровно три пары и новый выход')
    корень = Path(__file__).resolve().parents[3]
    выход = Path(а.выход)
    if (not выход.is_absolute() or выход != выход.resolve() or выход.exists()
            or any(os.path.lexists(п / '.git') for п in выход.parents)):
        raise ValueError('нужен новый физический приватный выход вне Git')
    каталог = выход.parent / (выход.stem + '-сырьё')
    каталог.mkdir(mode=0o700)
    def сохранить(путь, сырые, режим=0o600):
        with os.fdopen(os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, режим), 'wb') as файл:
            файл.write(сырые); файл.flush(); os.fsync(файл.fileno())
    def кодировать(данные):
        return (json.dumps(данные, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    А = subprocess.check_output(['git', '--no-optional-locks', '-C', str(корень),
        'show', КОММИТ_ЧИТАТЕЛЯ + ':' + ЧИТАТЕЛЬ])
    if hashlib.sha256(А).hexdigest() != ОТПЕЧАТОК_ЧИТАТЕЛЯ:
        raise ValueError('не подтверждён baseline позднего читателя')
    путь_А, профиль = каталог / 'принятый-читатель.py', каталог / 'исполняемый-профиль.py'
    сохранить(путь_А, А, 0o400); сохранить(профиль, Path(__file__).read_bytes(), 0o400)
    for путь in ('Инструменты/fum-proverka-git-zavisimostej/tests',
                 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts',
                 'Инструменты/fum-svyaznostj-rabochej-sessii/tests'):
        sys.path.insert(0, str(корень / путь))
    import test_чтения_цепочки_подготовки as чтение
    import чтение_цепочки_подготовки as читатель
    ф = чтение.ЧтениеЦепочкиПодготовки('runTest'); ф.setUp()
    пары, ошибка, состав = [], None, {}
    try:
        ф.создать_цепочку(смешанная=True)
        индекс = ф.админ / 'index'
        регистрация = читатель.регистрация_индекса(индекс.read_bytes())
        пустой_объект = subprocess.check_output(['git', '--no-optional-locks', '-C', str(ф.корень),
            'hash-object', '-w', '--stdin'], input=b'').decode().strip()
        сырые, _ = корпус(33405, регистрация=регистрация, обычный_объект=пустой_объект)
        индекс.write_bytes(сырые)
        сохранить(каталог / 'корпус-index', сырые, 0o400)
        до = ф.срез()
        пути = {Path(__file__), корень / ЧИТАТЕЛЬ}
        for модуль in tuple(sys.modules.values()):
            имя = getattr(модуль, '__file__', None)
            if имя:
                путь = Path(имя).resolve()
                if путь.is_relative_to(корень) and путь.suffix == '.py': пути.add(путь)
        состав = {str(п.relative_to(корень)): hashlib.sha256(п.read_bytes()).hexdigest() for п in sorted(пути)}
        for номер, порядок in enumerate(('AB', 'BA', 'AB'), 1):
            результаты = {}
            for вариант in порядок:
                настройки = {'корень_кода': str(корень), 'профиль_sha256': hashlib.sha256(профиль.read_bytes()).hexdigest(),
                    'исходник': {'путь': str(путь_А if вариант == 'A' else корень / ЧИТАТЕЛЬ),
                        'sha256': ОТПЕЧАТОК_ЧИТАТЕЛЯ if вариант == 'A' else состав[ЧИТАТЕЛЬ]},
                    'вариант': вариант, 'данные': str(ф.корень), 'индекс': str(индекс),
                    'корпус_sha256': hashlib.sha256(сырые).hexdigest(), 'база': ф.база, 'ветка': ф.ветка,
                    'исполнитель': ф.ф.исполнитель, 'координатор': ф.ф.задача, 'выбор': ф.выбор}
                имя = str(номер) + '-' + вариант
                вход = каталог / (имя + '-вход.json'); сохранить(вход, кодировать(настройки))
                процесс = запустить_поздний_процесс([sys.executable, '-I', '-S', '-B', str(профиль),
                    '--поздний-рабочий-вход', str(вход)], каталог=каталог, имя=имя, сохранить=сохранить)
                if процесс.returncode:
                    raise ValueError('свежий поздний процесс отказал: ' + имя + ', код ' + str(процесс.returncode))
                результаты[вариант] = json.loads(процесс.stdout)
            for ключ in ('прочитано_байтов', 'индекс_байтов', 'чтений_индекса', 'пути_sha256'):
                if результаты['A']['поздние_сверки'][ключ] != результаты['B']['поздние_сверки'][ключ]:
                    raise ValueError('различаются обязательные поздние чтения: ' + ключ)
            пары.append({'порядок': порядок, 'результаты': результаты})
        if до != ф.срез(): raise ValueError('поздние процессы изменили фикстуру')
        if len({п['результаты'][в]['процесс'] for п in пары for в in ('A', 'B')}) != 6:
            raise ValueError('нужны шесть различных свежих процессов')
        if any(hashlib.sha256((корень / п).read_bytes()).hexdigest() != х for п, х in состав.items()):
            raise ValueError('изменены наблюдённые исходники профиля')
    except Exception as отказ:
        ошибка = type(отказ).__name__ + ': ' + str(отказ)
    finally:
        ф.doCleanups()
    итог = {'схема': 'fum.профиль-позднего-разбора-индекса.1', 'завершён': ошибка is None,
        'ошибка': ошибка, 'база': {'коммит': КОММИТ_ЧИТАТЕЛЯ, 'sha256': ОТПЕЧАТОК_ЧИТАТЕЛЯ},
        'наблюдённые_исходники_sha256': состав, 'пар': len(пары), 'пары': пары, 'строк': 33405,
        'кэш_ОС_очищен': False, 'ускорение_всего_узла_доказано': False,
        'граница': 'Первичный допуск включает внутреннюю позднюю сверку. Затем три целые поздние границы; одинаковые файлы, чтения и байты. Шесть свежих процессов АБ/БА/АБ; setup, compile, сравнения и JSON вне таймера. Время включает одинаковые счётчики чтений/parser. RSS — пик worker с импортами и первичным допуском; вес memo включает sys.getsizeof и консервативные резервы, не RSS. Сырые каналы сохранены рядом до разбора результата.',
        'среда': {'python': sys.version, 'платформа': sys.platform}}
    сохранить(выход, кодировать(итог))
    if ошибка: raise ValueError(ошибка)
    print(json.dumps({'пар': 3, 'свежих_процессов': 6, 'исходники_неизменны': True,
        'поздние_времена_нс': [{в: п['результаты'][в]['поздние_сверки']['время_нс'] for в in ('A', 'B')} for п in пары]}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
