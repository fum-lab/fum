"""Три пары одной RO-сверки: меняется только область чистых преобразований."""
import argparse
import ast
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import resource
import statistics
import stat
import subprocess
import sys
import time
from unittest.mock import patch

КОРЕНЬ = Path(__file__).resolve().parents[3]
СКРИПТЫ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/'
ЖУРНАЛ = 'Инструменты/fum-struktura-papok-zaprosov/scripts/независимый_журнал.py'
КОНТРАКТ = СКРИПТЫ + 'контракт_независимого_журнала.py'
СВЯЗЬ = СКРИПТЫ + 'связность_независимого_журнала.py'
СОЗДАТЕЛЬ = СКРИПТЫ + 'создание_коммита.py'
ХЭШ = lambda б: hashlib.sha256(б).hexdigest()
КАНОН = lambda з: json.dumps(з, ensure_ascii=False, sort_keys=True).encode()


def гит(*аргументы):
    return subprocess.check_output(['git', '--no-replace-objects', '--no-optional-locks',
        '-c', 'core.hooksPath=' + os.devnull, '-C', str(КОРЕНЬ), *аргументы],
        env={**{к: з for к, з in os.environ.items() if not к.startswith('GIT_')},
            'GIT_NO_REPLACE_OBJECTS': '1', 'GIT_NO_LAZY_FETCH': '1', 'GIT_OPTIONAL_LOCKS': '0'})


def идентичность(мета):
    return [мета.st_dev, мета.st_ino, мета.st_mode, мета.st_nlink,
        мета.st_size, мета.st_mtime_ns, мета.st_ctime_ns]


def снимок_целей(корень, цели):
    if type(цели) is not list or len(цели) > 4096 or len(set(цели)) != len(цели):
        raise ValueError('Нужен ограниченный точный список целей')
    результат = {}
    for имя in цели:
        путь = PurePosixPath(имя)
        if (type(имя) is not str or путь.is_absolute() or путь.as_posix() != имя
                or any(ч in {'.', '..'} for ч in путь.parts)):
            raise ValueError('Неверная цель снимка')
        файл = корень
        for часть in путь.parts:
            файл /= часть
            if файл.is_symlink():
                raise ValueError('Symlink в цели снимка')
        if not файл.exists():
            результат[имя] = None
            continue
        до = файл.lstat()
        if not stat.S_ISREG(до.st_mode) or до.st_nlink != 1:
            raise ValueError('Необычная цель снимка')
        with os.fdopen(os.open(файл, os.O_RDONLY | os.O_NOFOLLOW), 'rb') as поток:
            if идентичность(os.fstat(поток.fileno())) != идентичность(до):
                raise ValueError('Подмена цели перед чтением')
            сырые = поток.read()
            if идентичность(os.fstat(поток.fileno())) != идентичность(до):
                raise ValueError('Цель изменилась при чтении')
        if идентичность(файл.lstat()) != идентичность(до):
            raise ValueError('Подмена цели после чтения')
        результат[имя] = {'режим': stat.S_IMODE(до.st_mode),
            'байтов': len(сырые), 'sha256': ХЭШ(сырые)}
    return результат


def частные_источники(параметры):
    результат = {}
    for источник in параметры['источники']:
        for поле in ('путь', 'кэш'):
            if поле not in источник:
                continue
            файл = Path(источник[поле])
            до = файл.lstat()
            if (файл.resolve() != файл or not stat.S_ISREG(до.st_mode)
                    or до.st_nlink != 1):
                raise ValueError('Необычный частный источник')
            if поле == 'путь' and stat.S_IMODE(до.st_mode) & 0o222:
                raise ValueError('Профиль требует закрытый префикс команд')
            значение = {'идентичность_sha256': ХЭШ(КАНОН(идентичность(до)))}
            if поле == 'кэш':
                значение['sha256'] = ХЭШ(файл.read_bytes())
            if идентичность(файл.lstat()) != идентичность(до):
                raise ValueError('Частный источник изменился при чтении')
            # Пути остаются только во входе; в открытом профиле — порядок и метки.
            результат[str(len(результат)) + ':' + поле] = значение
    return результат


def снимок(параметры):
    индекс = Path(гит('rev-parse', '--path-format=absolute', '--git-path', 'index').decode().strip())
    имена = set(filter(None, гит('ls-files', '--cached', '--others', '--exclude-standard',
        '-z', '--', '*.py').decode().split('\0')))
    return {'HEAD': гит('rev-parse', 'HEAD').decode().strip(),
        'ref': гит('symbolic-ref', 'HEAD').decode().strip(),
        'status_sha256': ХЭШ(гит('status', '--porcelain=v1', '-z')),
        'index_sha256': ХЭШ(индекс.read_bytes()),
        'исходники': {п: ХЭШ((КОРЕНЬ / п).read_bytes()) for п in sorted(имена)},
        'разрешённые_цели': снимок_целей(КОРЕНЬ, параметры['разрешённые_цели']),
        'частные_источники': частные_источники(параметры)}


def проверить_выход(выход, вход):
    sys.path.insert(0, str(КОРЕНЬ / 'Инструменты/fum-struktura-papok-zaprosov/tests'))
    from профиль_единого_пакета_установщика import проверить_новый_выход
    проверить_новый_выход(выход)
    if выход == вход:
        raise ValueError('Вход и выход должны различаться')


def функция(дерево, имя):
    узлы = [у for у in дерево.body if isinstance(у, ast.FunctionDef) and у.name == имя]
    if len(узлы) != 1:
        raise ValueError('Нужна единственная функция: ' + имя)
    return узлы[0]


def граница_вариантов(основа):
    старые = {п: гит('show', основа + ':' + п)
        for п in (КОНТРАКТ, СВЯЗЬ, ЖУРНАЛ, СОЗДАТЕЛЬ)}
    for п in (КОНТРАКТ, СВЯЗЬ, ЖУРНАЛ):
        if ast.dump(ast.parse(старые[п])) != ast.dump(ast.parse((КОРЕНЬ / п).read_bytes())):
            raise ValueError('Изменена общая зависимость: ' + п)
    прежде = ast.parse(старые[СОЗДАТЕЛЬ])
    теперь = ast.parse((КОРЕНЬ / СОЗДАТЕЛЬ).read_bytes())
    исходная = функция(прежде, 'сверить_независимый_журнал')
    новая = функция(теперь, 'сверить_независимый_журнал')
    if len(новая.body) != 3 or not isinstance(новая.body[2], ast.With):
        raise ValueError('Неизвестная граница чистой области')
    область = новая.body[2]
    ожидаемая = ast.parse('with журнал.контракт.область_чистых_проверок(): pass').body[0]
    if ast.dump(область.items[0]) != ast.dump(ожидаемая.items[0]) or len(область.items) != 1:
        raise ValueError('Чужая область либо изменён её вызов')
    новая.body = новая.body[:2] + область.body
    if ast.dump(прежде) != ast.dump(теперь):
        raise ValueError('Создатель изменён вне одной чистой области')
    return исходная, {п: ХЭШ(б) for п, б in старые.items()}


def работник(п):
    сырые = п.вход.read_bytes()
    if ХЭШ(сырые) != п.хэш_входа:
        raise ValueError('Изменён вход профиля')
    параметры = json.loads(сырые)
    if Path(параметры['корень']) != КОРЕНЬ or параметры['исходный_коммит'] != п.основа:
        raise ValueError('Чужой корень или основа')
    до = снимок(параметры)
    if до['HEAD'] != п.основа:
        raise ValueError('Изменён HEAD')
    sys.path.insert(0, str(КОРЕНЬ / СКРИПТЫ))
    import контракт_независимого_журнала as контракт
    import связность_независимого_журнала as связь
    import создание_коммита as создатель
    модуль = связь.журнал()
    прежняя, отпечатки = граница_вариантов(п.основа)
    if п.вариант == 'прежний':
        exec(compile(ast.Module(body=[прежняя], type_ignores=[]),
            '<точная-прежняя-сверка>', 'exec'), vars(создатель))
    выбранная = создатель.сверить_независимый_журнал

    def сверить_модули():
        if (связь.журнал() is not модуль or модуль.контракт is not контракт
                or создатель.сверить_независимый_журнал is not выбранная
                or Path(модуль.__file__).resolve() != КОРЕНЬ / ЖУРНАЛ
                or Path(контракт.__file__).resolve() != КОРЕНЬ / КОНТРАКТ
                or Path(связь.__file__).resolve() != КОРЕНЬ / СВЯЗЬ
                or Path(создатель.__file__).resolve() != КОРЕНЬ / СОЗДАТЕЛЬ):
            raise ValueError('Подменён фактически используемый модуль')

    сверить_модули()
    команды, области = [], []
    разборов = [0]
    прежний_разбор = модуль._разобрать_дерево_коммита
    прежняя_область = контракт.область_чистых_проверок

    def наблюдать_разбор(сырые):
        разборов[0] += 1
        return прежний_разбор(сырые)

    @contextmanager
    def наблюдать_область():
        with прежняя_область():
            try:
                yield
            finally:
                кэш = контракт._ЧИСТЫЕ_ПРОВЕРКИ.get()
                области.append({'строк': len(кэш['строки']), 'путей': len(кэш['пути']),
                    'дерево_сохранено': кэш['разобранное_дерево'] is not None})

    прежний_запуск = subprocess.Popen.__init__

    def наблюдать(self, *аргументы, **ключи):
        команды.append(аргументы[0] if аргументы else ключи.get('args'))
        return прежний_запуск(self, *аргументы, **ключи)

    начало, процессор = time.perf_counter_ns(), time.process_time_ns()
    with patch.object(subprocess.Popen, '__init__', наблюдать), \
            patch.object(модуль, '_разобрать_дерево_коммита', наблюдать_разбор), \
            patch.object(контракт, 'область_чистых_проверок', наблюдать_область):
        результат = создатель.сверить_независимый_журнал(параметры,
            параметры['контракт_журнала']['состав'])
    время, процессор = time.perf_counter_ns() - начало, time.process_time_ns() - процессор
    сверить_модули()
    if снимок(параметры) != до or п.вход.read_bytes() != сырые or контракт._ЧИСТЫЕ_ПРОВЕРКИ.get() is not None:
        raise ValueError('Изменился вход, W, индекс, код или осталась область')
    return {'процесс': os.getpid(), 'вариант': п.вариант, 'wall_ns': время, 'cpu_ns': процессор,
        'maxRSS_байты_macos': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'состояние': до, 'вход_sha256': п.хэш_входа, 'прежние_модули_sha256': отпечатки,
        'чистых_разборов_дерева': разборов[0], 'области': области,
        'результат_sha256': ХЭШ(КАНОН(результат)), 'Git_и_прочие_процессы': len(команды),
        'argv_sha256': ХЭШ(КАНОН(команды))}


def главная():
    р = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    р.add_argument('--основа', required=True)
    р.add_argument('--вход', type=Path, required=True)
    р.add_argument('--хэш-входа', required=True)
    р.add_argument('--выход', type=Path)
    р.add_argument('--вариант', choices=('прежний', 'новый'))
    п = р.parse_args()
    if sys.platform != 'darwin' or sys.flags.optimize or not sys.dont_write_bytecode:
        raise ValueError('Нужен macOS, -B, без -O')
    if п.вариант:
        print(json.dumps(работник(п), ensure_ascii=False, sort_keys=True)); return
    проверить_выход(п.выход, п.вход)
    сырые = п.вход.read_bytes()
    if ХЭШ(сырые) != п.хэш_входа:
        raise ValueError('Изменён вход профиля')
    параметры = json.loads(сырые)
    до = снимок(параметры); пары = []
    for номер in range(3):
        порядок = ('прежний', 'новый') if номер % 2 == 0 else ('новый', 'прежний')
        пара = {'порядок': порядок}
        for вариант in порядок:
            процесс = subprocess.run([sys.executable, '-E', '-s', '-S', '-B', str(Path(__file__).resolve()),
                '--основа', п.основа, '--вход', str(п.вход), '--хэш-входа', п.хэш_входа,
                '--вариант', вариант], capture_output=True, text=True, timeout=180, check=False)
            if процесс.returncode:
                sys.stdout.write(процесс.stdout); sys.stderr.write(процесс.stderr)
                raise SystemExit(процесс.returncode)
            пара[вариант] = json.loads(процесс.stdout)
        пары.append(пара)
    наблюдения = [з[в] for з in пары for в in ('прежний', 'новый')]
    if (len({з['процесс'] for з in наблюдения}) != 6 or снимок(параметры) != до
            or п.вход.read_bytes() != сырые
            or any(з['состояние'] != до for з in наблюдения)
            or any(len({з[к] for з in наблюдения}) != 1
                   for к in ('результат_sha256', 'argv_sha256', 'вход_sha256'))):
        raise ValueError('Различаются процессы, состояние или результаты')
    if any(з['прежний']['области'] or len(з['новый']['области']) != 1
            or з['новый']['области'][0]['путей'] == 0
            or з['новый']['чистых_разборов_дерева'] > з['прежний']['чистых_разборов_дерева']
            for з in пары):
        raise ValueError('Реальная сверка не подтверждает единственную чистую область')
    итог = {'схема': 'fum.парный-профиль-области-сверки.1', 'пары': пары,
        'медианы_wall_ns': {в: statistics.median(з[в]['wall_ns'] for з in пары) for в in ('прежний', 'новый')},
        'граница': 'Шесть новых процессов; один публичный вызов сверить_независимый_журнал в каждом. '
            'Прежний вариант исполняет точный AST этой функции из основы; новый добавляет '
            'ровно один with, что проверяет fence всего AST создателя и трёх общих зависимостей. '
            'Setup и прямые импорты вне wall; ленивые импорты, наблюдение argv, счётчик чистого '
            'разбора и наблюдение области внутри обоих окон. cpu — SELF; RSS — максимум '
            'работника. Кэш ОС не сбрасывается. Результат, весь argv, исходники и состояние '
            'совпадают; внешние Git/FS-чтения выполняются заново. Это не весь READY/Create.'}

    дескриптор = os.open(п.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(дескриптор, 'wb') as поток:
        поток.write((json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode())
        поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'процессов': 6, 'медианы_wall_ns': итог['медианы_wall_ns']}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
