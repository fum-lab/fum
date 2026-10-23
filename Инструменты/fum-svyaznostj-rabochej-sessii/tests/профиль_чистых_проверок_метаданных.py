"""Три пары полных RO-доказательств одного неподвижного слоя.

Базовый вариант исполняет точные прежние тела двух чистых валидаторов и
прежнее тело proof без нового декоратора. Остальной текущий контур общий.
"""
import argparse
import ast
import hashlib
import json
import os
from pathlib import Path
import resource
import statistics
import subprocess
import sys
import time
from unittest.mock import patch

КОРЕНЬ = Path(__file__).resolve().parents[3]
СКРИПТЫ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/'
ИМЕНА = ('контракт_независимого_журнала', 'связность_независимого_журнала')
ХЭШ = lambda b: hashlib.sha256(b).hexdigest()
КАНОН = lambda v: json.dumps(v, ensure_ascii=False, sort_keys=True).encode()


def гит(*аргументы):
    return subprocess.check_output(['git', '--no-replace-objects', '--no-optional-locks',
        '-c', 'core.hooksPath=' + os.devnull, '-C', str(КОРЕНЬ), *аргументы],
        env={**{к: з for к, з in os.environ.items() if not к.startswith('GIT_')},
            'GIT_NO_REPLACE_OBJECTS': '1', 'GIT_NO_LAZY_FETCH': '1', 'GIT_OPTIONAL_LOCKS': '0'})


def снимок():
    индекс = Path(гит('rev-parse', '--path-format=absolute', '--git-path', 'index').decode().strip())
    имена = set(filter(None, гит('ls-files', '--cached', '--others', '--exclude-standard',
        '-z', '--', '*.py').decode().split('\0')))
    return {'HEAD': гит('rev-parse', 'HEAD').decode().strip(),
        'ref': гит('symbolic-ref', 'HEAD').decode().strip(),
        'status_sha256': ХЭШ(гит('status', '--porcelain=v1', '-z')),
        'index_sha256': ХЭШ(индекс.read_bytes()),
        'исходники': {п: ХЭШ((КОРЕНЬ / п).read_bytes()) for п in sorted(имена)}}


def проверить_выход(выход, вход):
    sys.path.insert(0, str(КОРЕНЬ / 'Инструменты/fum-struktura-papok-zaprosov/tests'))
    from профиль_единого_пакета_установщика import проверить_новый_выход
    проверить_новый_выход(выход)
    if выход == вход:
        raise ValueError('Вход и выход должны различаться')


def прежний_контур(основа, контракт, связь):
    старые = {имя: гит('show', основа + ':' + СКРИПТЫ + имя + '.py') for имя in ИМЕНА}
    before = ast.parse(старые[ИМЕНА[0]])
    after = ast.parse((КОРЕНЬ / (СКРИПТЫ + ИМЕНА[0] + '.py')).read_bytes())
    тела = {у.name: у for у in before.body if isinstance(у, ast.FunctionDef)
        and у.name in {'строка', 'путь'}}
    def новый(у):
        return ((isinstance(у, ast.ImportFrom) and у.module in {'contextlib', 'contextvars'})
            or (isinstance(у, ast.FunctionDef) and у.name == 'область_чистых_проверок')
            or (isinstance(у, ast.Assign) and any(isinstance(ц, ast.Name)
                and ц.id in {'_ПРЕДЕЛ_ЧИСТЫХ_ЗНАЧЕНИЙ', '_ЧИСТЫЕ_ПРОВЕРКИ'} for ц in у.targets)))
    after.body = [тела.get(у.name, у) if isinstance(у, ast.FunctionDef) else у
        for у in after.body if not новый(у)]
    if ast.dump(before) != ast.dump(after):
        raise ValueError('Изменение выходит за объявленный чистый контракт')
    before = ast.parse(старые[ИМЕНА[1]])
    after = ast.parse((КОРЕНЬ / (СКРИПТЫ + ИМЕНА[1] + '.py')).read_bytes())
    proof = next(у for у in after.body if isinstance(у, ast.FunctionDef) and у.name == 'доказательство_слоя')
    if [ast.unparse(д) for д in proof.decorator_list] != ['контракт.область_чистых_проверок()']:
        raise ValueError('Неизвестная обёртка доказательства')
    proof.decorator_list = []
    if ast.dump(before) != ast.dump(after):
        raise ValueError('Изменено общее тело доказательства')
    пространство = dict(vars(контракт))
    exec(compile(ast.Module(body=list(тела.values()), type_ignores=[]),
        '<точные-прежние-валидаторы>', 'exec'), пространство)
    # Обе функции должны видеть прежнюю строка(), в том числе из прежней путь().
    for имя in тела:
        setattr(контракт, имя, пространство[имя])
    return связь.доказательство_слоя.__wrapped__, {и: ХЭШ(б) for и, б in старые.items()}


def работник(п):
    сырые = п.вход.read_bytes()
    if ХЭШ(сырые) != п.хэш_входа:
        raise ValueError('Изменён вход профиля')
    параметры = json.loads(сырые)
    if Path(параметры['корень']) != КОРЕНЬ or параметры['исходный_коммит'] != п.основа:
        raise ValueError('Чужой корень или основа')
    до = снимок()
    if до['HEAD'] != п.основа:
        raise ValueError('Изменён HEAD')
    sys.path.insert(0, str(КОРЕНЬ / СКРИПТЫ))
    import контракт_независимого_журнала as контракт
    import связность_независимого_журнала as связь
    функция = связь.доказательство_слоя
    прежняя, отпечатки = прежний_контур(п.основа, контракт, связь)
    if п.вариант == 'прежний':
        функция = прежняя
    else:
        # Проверка границы выше временно установила старые тела: восстановить
        # обе исходные функции нового модуля до окна, без reload общих модулей.
        пространство = dict(vars(контракт))
        дерево = ast.parse((КОРЕНЬ / (СКРИПТЫ + ИМЕНА[0] + '.py')).read_bytes())
        узлы = [у for у in дерево.body if isinstance(у, ast.FunctionDef) and у.name in {'строка', 'путь'}]
        exec(compile(ast.Module(body=узлы, type_ignores=[]), '<текущие-валидаторы>', 'exec'), пространство)
        for у in узлы:
            setattr(контракт, у.name, пространство[у.name])
    команды = []
    popen = subprocess.Popen.__init__
    def наблюдать(self, *аргументы, **ключи):
        команды.append(аргументы[0] if аргументы else ключи.get('args'))
        return popen(self, *аргументы, **ключи)
    начало, cpu = time.perf_counter_ns(), time.process_time_ns()
    with patch.object(subprocess.Popen, '__init__', наблюдать):
        результат = функция(параметры)
    wall, cpu = time.perf_counter_ns() - начало, time.process_time_ns() - cpu
    if снимок() != до or п.вход.read_bytes() != сырые:
        raise ValueError('Изменился вход, W, индекс или код')
    return {'процесс': os.getpid(), 'вариант': п.вариант, 'wall_ns': wall, 'cpu_ns': cpu,
        'maxRSS_байты_macos': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'состояние': до, 'вход_sha256': п.хэш_входа, 'прежние_модули_sha256': отпечатки,
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
    до = снимок(); пары = []
    for номер in range(3):
        порядок = ('прежний', 'новый') if номер % 2 == 0 else ('новый', 'прежний')
        пара = {'порядок': порядок}
        for в in порядок:
            процесс = subprocess.run([sys.executable, '-E', '-s', '-S', '-B', str(Path(__file__).resolve()),
                '--основа', п.основа, '--вход', str(п.вход), '--хэш-входа', п.хэш_входа,
                '--вариант', в], capture_output=True, text=True, timeout=180, check=False)
            if процесс.returncode:
                sys.stdout.write(процесс.stdout); sys.stderr.write(процесс.stderr)
                raise SystemExit(процесс.returncode)
            пара[в] = json.loads(процесс.stdout)
        пары.append(пара)
    н = [з[в] for з in пары for в in ('прежний', 'новый')]
    if (len({з['процесс'] for з in н}) != 6 or снимок() != до
            or any(з['состояние'] != до for з in н)
            or any(len({з[к] for з in н}) != 1 for к in ('результат_sha256', 'argv_sha256', 'вход_sha256'))):
        raise ValueError('Различаются процессы, состояние или результаты')
    итог = {'схема': 'fum.парный-профиль-чистых-проверок.1', 'пары': пары,
        'медианы_wall_ns': {в: statistics.median(з[в]['wall_ns'] for з in пары) for в in ('прежний', 'новый')},
        'граница': 'Шесть новых процессов, одно полное доказательство слоя в каждом. '
            'Прежние тела двух чистых валидаторов и proof без нового декоратора из точной основы; '
            'остальной текущий контур общий, допустимая дельта проверена AST. '
            'Начальные прямые импорты, снимки и setup вне wall; ленивые импорты внутри proof '
            'и наблюдение argv включены в оба окна. '
            'cpu — SELF; RSS — максимум всего работника. Кэш ОС не сбрасывается. '
            'Сами файлы, Git, индексы и исходники перечитываются. Временное H создаётся вне W. '
            'Это не весь READY/Create, установка S1 или активация узла.'}
    fd = os.open(п.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as f:
        f.write((json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode())
        f.flush(); os.fsync(f.fileno())
    print(json.dumps({'процессов': 6, 'медианы_wall_ns': итог['медианы_wall_ns']}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
