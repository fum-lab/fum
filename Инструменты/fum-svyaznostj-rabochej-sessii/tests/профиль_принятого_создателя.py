"""Парный профиль полного разбора и свежего файлового barrier; production не измеряется."""
import argparse
import cProfile
import hashlib
import json
import os
from pathlib import Path
import pstats
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


def корпус(число):
    записи = {'.gitmodules': (0o100644, '22' * 20), 'Зависимости/открытая': (0o160000, '33' * 20)}
    for номер in range(число - 2):
        имя = 'данные/' + str(номер).zfill(5) + '-' + 'x' * 159 + '.txt'
        записи[имя] = (0o100644, hashlib.sha1(str(номер).encode()).hexdigest())
    части = [b'DIRC' + struct.pack('>II', 2, число)]
    for имя, (режим, объект) in записи.items():
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
    а = п.parse_args()
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


if __name__ == '__main__':
    raise SystemExit(главная())
