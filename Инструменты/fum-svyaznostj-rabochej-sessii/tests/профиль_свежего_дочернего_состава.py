"""Issue344: по одному свежему процессу immutable17 на основе и ремонте; n=1."""
import argparse, hashlib, json, os, re, resource, signal, stat, statistics, subprocess, sys, time
from pathlib import Path

ТЕСТЫ = 'Инструменты/fum-svyaznostj-rabochej-sessii/tests'
ПРОФИЛЬ = ТЕСТЫ + '/профиль_свежего_дочернего_состава.py'
НЕИЗМЕННЫЙ = 'test_передачи_выбранного_состава'
# Точные rawSHA K579, A/B-v2 и теста после ремонта namespace; путь не доказывает приёмку ROOT.
ИСТОЧНИКИ = [
    ('Инструменты/fum-struktura-papok-zaprosov/scripts/независимый_журнал.py', 'e0d19ce70c97a3bf8d708306127376a494599ca499c08b31b763e844c6464d24', '976be167056a32d0fe6308e2938496447b9c00b358071b82253e0f222405adb0'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/связность_независимого_журнала.py', 'f741062125e9571eddb8b465db7f09c76aa4542fa4452f33caebb457511e0ebc', '0714bfb07080afc911918ebcf8e6fd8c57d792b13cc313d250ade69ec060b7c4'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/подготовка_дочернего_поручения.py', '8a63fdce2232785984ffbd28e0abd0f15c608c4cab10f6c249aafaff7bb4e56d', '29b2ff423c7f7a66506584770d522386bac42d484f67e038ada0f5a41d81564c'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/подготовка_этапа_коммита.py', '68c7017e4b5ce59f2d7d2057c6036f9406cfad1a3fc8b8a2f7dd650634977c67', '6238f8056c0e6cbd9c4ce1c7a9447a92fb0e94289a1d295073d72f1b4f7e0ff4'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py', 'e3610321d8e42763d41484cc650416ddaae3b279fd121b66288c77a717966c22', '2ce83a14d1ae6f7762a39eb79431defd617b6b1ffd85a37d7fc6f6ad0b00696a'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/поздняя_привязка_журнала.py', 'f790ef96ade98fcdd62c56ccbcccc6c21e6aa1cb3bb0111bd415f5ed263ccfd0', 'c87071b00ef74e0d995de4f3f15a85f37c618bf4126dc1bcaf9d2baca701d1e9'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py', '1f03af00a29eb172d2220ee549e66d9d2adc23890c18e84d6cbd9397875d8a66', '8404f62a905f4e3a51cd4c2513b88834e964eeb4b5787a9abd36ca5198476e1a'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/типизированная_контрольная_точка.py', 'e3ef7dc93c8df666b62125efffb2fd00fec95ddd00dac9d2880c21c90143b0cf', '57fad50acafb8a4d262a8904b5efe04edf96e047c515fb3a70bdda82fecc95ad'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_независимой_контрольной_точки.py', '7c47a0568bbb79fecfb484b43881241af1810f3366ad6d6eb4c62ea1d8501cba', '08b0e049489432178fc6a5d707009b725fceaf5e448392bfbbedfa341f052ed8'),
    ('Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_передачи_выбранного_состава.py', '7982eaa9edef137ae7db51ee9ee46a3a9cc709fdf4feb2124bf9bdf969f0f68d', '7982eaa9edef137ae7db51ee9ee46a3a9cc709fdf4feb2124bf9bdf969f0f68d'),
]


def снимок(корень):
    итог = {}
    for имя in [з[0] for з in ИСТОЧНИКИ] + [ПРОФИЛЬ]:
        путь = корень / имя
        try: сведения = путь.lstat()
        except FileNotFoundError: итог[имя] = None; continue
        if путь.resolve() != путь or not stat.S_ISREG(сведения.st_mode):
            raise ValueError('Источник должен быть обычным физическим файлом')
        сырые = путь.read_bytes()
        итог[имя] = {'sha256': hashlib.sha256(сырые).hexdigest(), 'байтов': len(сырые),
            'режим': oct(stat.S_IMODE(сведения.st_mode))}
    return итог


def новый(путь):
    return os.fdopen(os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'wb')


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    for имя in ('код-основы', 'выход', 'сырой-каталог'): разбор.add_argument('--' + имя, type=Path, required=True)
    п = разбор.parse_args()
    if sys.version_info[:2] != (3, 14) or sys.flags.optimize: raise ValueError('Нужен Python 3.14 без -O')
    корни = {'основа': п.код_основы, 'ремонт': Path(__file__).resolve().parents[3]}
    if any(not к.is_absolute() or к.resolve(strict=True) != к or not к.is_dir() for к in корни.values()):
        raise ValueError('Нужны физические абсолютные корни')
    if корни['основа'] == корни['ремонт'] or any(а in б.parents for а, б in [tuple(корни.values()), tuple(reversed(корни.values()))]):
        raise ValueError('Кодовые области должны быть отдельными')
    for путь in (п.выход, п.сырой_каталог):
        if not путь.is_absolute() or путь.parent.resolve(strict=True) != путь.parent or путь.exists() or путь.is_symlink():
            raise ValueError('Выходы должны быть новыми физическими адресами')
        if any(путь == к or к in путь.parents for к in корни.values()): raise ValueError('Выход внутри исходников')
    if п.выход == п.сырой_каталог: raise ValueError('Выходы совпадают')
    if any(os.path.lexists(к / '.git') for к in п.сырой_каталог.parents): raise ValueError('RAW должен быть вне Git')
    до = {имя: снимок(к) for имя, к in корни.items()}
    for имя, столбец in (('основа', 1), ('ремонт', 2)):
        for запись in ИСТОЧНИКИ:
            if not до[имя][запись[0]] or до[имя][запись[0]]['sha256'] != запись[столбец]:
                raise ValueError('Не совпал закреплённый исходник: ' + имя + ': ' + запись[0])
    if до['основа'][ПРОФИЛЬ] is not None or до['ремонт'][ПРОФИЛЬ] is None:
        raise ValueError('Профиль должен быть новым только в ремонте')
    if any(до['основа'][з[0]]['режим'] != до['ремонт'][з[0]]['режим'] for з in ИСТОЧНИКИ):
        raise ValueError('Режимы прежних исходников различаются')
    п.сырой_каталог.mkdir(mode=0o700)
    среда = {к: з for к, з in os.environ.items() if not к.startswith(('PYTHON', 'GIT_'))}
    среда.update(PYTHONDONTWRITEBYTECODE='1', PYTHON_COLORS='0', GIT_OPTIONAL_LOCKS='0',
        GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull, TMPDIR=str(п.сырой_каталог))
    работы = [('основа17', 'основа', НЕИЗМЕННЫЙ, 17, 180), ('ремонт17', 'ремонт', НЕИЗМЕННЫЙ, 17, 180)]
    результаты = []
    for номер, (группа, область, метод, число, предел) in enumerate(работы, 1):
        имена = {вид: f'{номер:02d}-{группа}.{вид}.raw' for вид in ('stdout', 'stderr')}
        среда['PYTHONPATH'] = str(корни[область] / ТЕСТЫ)
        команда = [sys.executable, '-B', '-m', 'unittest', метод]
        процесс = None; код = None; исход = 'завершён'; ошибка = None
        расход_до = resource.getrusage(resource.RUSAGE_CHILDREN); начало = time.perf_counter_ns()
        with новый(п.сырой_каталог / имена['stdout']) as вых, новый(п.сырой_каталог / имена['stderr']) as ош:
            try:
                процесс = subprocess.Popen(команда, cwd=корни[область], env=среда,
                    stdin=subprocess.DEVNULL, stdout=вых, stderr=ош, start_new_session=True)
                код = процесс.wait(timeout=предел)
            except subprocess.TimeoutExpired: исход = 'timeout'
            except KeyboardInterrupt: исход = 'прервано'
            except OSError as отказ: исход = 'ошибка-запуска'; ошибка = {'тип': type(отказ).__name__, 'errno': отказ.errno}
            finally:
                if процесс is not None and процесс.poll() is None:
                    try: os.killpg(процесс.pid, signal.SIGKILL)
                    except ProcessLookupError: pass
                    try: код = процесс.wait(timeout=5)
                    except subprocess.TimeoutExpired: исход = 'неизвестно'
                длительность = time.perf_counter_ns() - начало
                расход = resource.getrusage(resource.RUSAGE_CHILDREN)
                вых.flush(); ош.flush(); os.fsync(вых.fileno()); os.fsync(ош.fileno())
        сырые = {вид: (п.сырой_каталог / имя).read_bytes() for вид, имя in имена.items()}
        найдено = re.findall(rb'(?m)^Ran (\d+) tests? in [0-9.]+s\r?$', сырые['stderr'])
        успех = (исход == 'завершён' and код == 0 and найдено == [str(число).encode()]
            and сырые['stderr'].rstrip().endswith(b'\nOK'))
        результаты.append({'номер': номер, 'группа': группа, 'кодовая_область': область,
            'argv': ['sys.executable', '-B', '-m', 'unittest', метод], 'cwd': '.', 'PYTHONPATH': ТЕСТЫ,
            'предел_секунд': предел, 'код': код, 'исход': исход, 'ошибка': ошибка, 'успех': успех,
            'тестов_ожидается': число, 'тестов_в_сводках': [int(з) for з in найдено], 'монотонные_нс': длительность,
            'cpu_user_с': расход.ru_utime - расход_до.ru_utime, 'cpu_system_с': расход.ru_stime - расход_до.ru_stime,
            'rss_накопительный_до': расход_до.ru_maxrss, 'rss_накопительный_после': расход.ru_maxrss,
            'RAW': {вид: {'файл': имена[вид], 'байтов': len(б), 'sha256': hashlib.sha256(б).hexdigest(),
                'полнота': исход == 'завершён'} for вид, б in сырые.items()}})
        if not успех: break
    ошибка_сверки = None
    try: после = {имя: снимок(к) for имя, к in корни.items()}
    except (OSError, ValueError) as отказ: после = None; ошибка_сверки = type(отказ).__name__
    успех = len(результаты) == 2 and all(р['успех'] for р in результаты) and после == до
    итог = {'схема': 'fum.профиль-свежего-дочернего-состава.2', 'успех': успех,
        'python': sys.version.split()[0], 'платформа': sys.platform, 'исходники_до': до, 'исходники_после': после,
        'ошибка_сверки': ошибка_сверки, 'процессы': результаты, 'наблюдений_на_область_при_успехе': 1,
        'границы': ['Фиксированные immutable17 по одному разу на каждом коде, n=1; медиан и выводов об ускорении/статзначимости нет.',
            'Источники основы читаются; 8 runtime, оба тестовых файла и профиль сверены до/после, не полное Python-замыкание.',
            'Полные временные Git-фикстуры, кэш ОС не очищен. ROOT9 в реальной базе и Desktop-рождение не измерены.',
            'Положительный virtual-S(H) здесь не запускается. Фактический RAW4 ROOT экспортирует отдельно после успеха и сверки pins; runner его не читает. Старый отказ не сравнивается; путь основы не доказывает приёмку ROOT.',
            'Wall включает запуск и ожидание, заканчивается до чтения RAW; CPU — приращение RUSAGE_CHILDREN.',
            'RSS — накопительный пик RUSAGE_CHILDREN: bytes на darwin, KiB на linux; не сумма, не дельта и не пик одного запуска.',
            'При timeout/прерывании SIGKILL группе, ожидание до5с; захваченные RAW сохранены, полнота=false. Ушедшие из группы процессы не доказаны завершёнными.',
            'argv нормализован: sys.executable текущего Python3.14, cwd выбранной области, PYTHONPATH относительно неё; RAW имена относительно private-каталога.']}
    with новый(п.выход) as поток:
        поток.write((json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'успех': успех, 'процессов': len(результаты), 'коды': [р['код'] for р in результаты]}, ensure_ascii=False))
    return 0 if успех else 1


if __name__ == '__main__':
    raise SystemExit(главная())
