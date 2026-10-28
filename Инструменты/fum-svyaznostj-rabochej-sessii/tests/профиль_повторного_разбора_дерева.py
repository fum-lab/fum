"""Три пары полных RO-доказательств: N7 общий, отличается только разбор дерева."""
import argparse
import ast
import copy
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
ЖУРНАЛ = 'Инструменты/fum-struktura-papok-zaprosov/scripts/независимый_журнал.py'
КОНТРАКТ = СКРИПТЫ + 'контракт_независимого_журнала.py'
СВЯЗЬ = СКРИПТЫ + 'связность_независимого_журнала.py'
ХЭШ = lambda б: hashlib.sha256(б).hexdigest()
КАНОН = lambda з: json.dumps(з, ensure_ascii=False, sort_keys=True).encode()


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


def функция(дерево, имя):
    узлы = [у for у in дерево.body if isinstance(у, ast.FunctionDef) and у.name == имя]
    if len(узлы) != 1:
        raise ValueError('Нужна единственная функция: ' + имя)
    return узлы[0]


def граница_вариантов(основа):
    старые = {п: гит('show', основа + ':' + п) for п in (КОНТРАКТ, СВЯЗЬ, ЖУРНАЛ)}
    if ast.dump(ast.parse(старые[СВЯЗЬ])) != ast.dump(ast.parse((КОРЕНЬ / СВЯЗЬ).read_bytes())):
        raise ValueError('Изменено общее доказательство, включая декоратор N7')
    прежний = ast.parse(старые[КОНТРАКТ])
    новый = ast.parse((КОРЕНЬ / КОНТРАКТ).read_bytes())
    функция(новый, 'проверенный_разбор_дерева')
    область = функция(новый, 'область_чистых_проверок')
    словари = [у for у in ast.walk(область) if isinstance(у, ast.Dict)]
    if len(словари) != 1:
        raise ValueError('Неизвестная область N7')
    словарь = словари[0]
    места = [н for н, к in enumerate(словарь.keys)
             if isinstance(к, ast.Constant) and к.value == 'разобранное_дерево']
    if len(места) != 1 or ast.dump(словарь.values[места[0]]) != ast.dump(ast.Constant(value=None)):
        raise ValueError('Неизвестный новый элемент области')
    del словарь.keys[места[0]]; del словарь.values[места[0]]
    пределы = {'_ПРЕДЕЛ_СЫРОГО_ДЕРЕВА', '_ПРЕДЕЛ_ЗАПИСЕЙ_ДЕРЕВА'}
    добавленные = [у for у in новый.body if isinstance(у, ast.Assign)
        and any(isinstance(ц, ast.Name) and ц.id in пределы for ц in у.targets)]
    if len(добавленные) != 2:
        raise ValueError('Неизвестные пределы нового кэша')
    новый.body = [у for у in новый.body if у not in добавленные
        and not (isinstance(у, ast.FunctionDef) and у.name == 'проверенный_разбор_дерева')]
    if ast.dump(прежний) != ast.dump(новый):
        raise ValueError('Контракт изменён вне объявленного N8-кэша')
    прежний = ast.parse(старые[ЖУРНАЛ])
    новый = ast.parse((КОРЕНЬ / ЖУРНАЛ).read_bytes())
    исходная = функция(прежний, '_дерево_коммита')
    разбор = copy.deepcopy(исходная)
    разбор.name = '_разобрать_дерево_коммита'
    разбор.args = ast.parse('def ф(сырые): pass').body[0].args
    цикл = разбор.body[1]
    if not isinstance(цикл, ast.For):
        raise ValueError('Неизвестное прежнее тело разбора')
    цикл.iter = ast.parse("сырые.split(b'\\0')").body[0].value
    if ast.dump(разбор) != ast.dump(функция(новый, '_разобрать_дерево_коммита')):
        raise ValueError('Изменена семантика чистого разбора')
    обёртка = ast.parse("def _дерево_коммита(корень, коммит):\n"
        "    сырые = _гит(корень, 'ls-tree', '-r', '-t', '-z', '--full-tree', коммит)\n"
        "    return контракт.проверенный_разбор_дерева(сырые, _разобрать_дерево_коммита)\n").body[0]
    if ast.dump(обёртка) != ast.dump(функция(новый, '_дерево_коммита')):
        raise ValueError('Изменён внешний Git-вызов')
    новая_обёртка = функция(новый, '_дерево_коммита')
    новый.body = [исходная if у is новая_обёртка else у
        for у in новый.body if not (isinstance(у, ast.FunctionDef) and у.name == разбор.name)]
    if ast.dump(прежний) != ast.dump(новый):
        raise ValueError('Журнал изменён вне выделения чистого разбора')
    return исходная, {п: ХЭШ(б) for п, б in старые.items()}


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
    модуль = связь.журнал()
    прежняя, отпечатки = граница_вариантов(п.основа)
    if п.вариант == 'прежний':
        exec(compile(ast.Module(body=[прежняя], type_ignores=[]), '<точный-прежний-разбор>', 'exec'), vars(модуль))
    выбранная = модуль._дерево_коммита
    def сверить_модули():
        if (связь.журнал() is not модуль or модуль.контракт is not контракт
                or модуль._дерево_коммита is not выбранная
                or Path(модуль.__file__).resolve() != КОРЕНЬ / ЖУРНАЛ
                or Path(контракт.__file__).resolve() != КОРЕНЬ / КОНТРАКТ
                or Path(связь.__file__).resolve() != КОРЕНЬ / СВЯЗЬ):
            raise ValueError('Подменён фактически используемый модуль')
    сверить_модули()
    команды = []
    проверки_структуры = [0]
    прежняя_проверка = модуль._проверить_структуру
    def наблюдать_структуру(записи):
        проверки_структуры[0] += 1
        return прежняя_проверка(записи)
    прежний_запуск = subprocess.Popen.__init__
    def наблюдать(self, *аргументы, **ключи):
        команды.append(аргументы[0] if аргументы else ключи.get('args'))
        return прежний_запуск(self, *аргументы, **ключи)
    начало, процессор = time.perf_counter_ns(), time.process_time_ns()
    with patch.object(subprocess.Popen, '__init__', наблюдать), \
            patch.object(модуль, '_проверить_структуру', наблюдать_структуру):
        результат = связь.доказательство_слоя(параметры)
    время, процессор = time.perf_counter_ns() - начало, time.process_time_ns() - процессор
    сверить_модули()
    if снимок() != до or п.вход.read_bytes() != сырые:
        raise ValueError('Изменился вход, W, индекс или код')
    return {'процесс': os.getpid(), 'вариант': п.вариант, 'wall_ns': время, 'cpu_ns': процессор,
        'maxRSS_байты_macos': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'состояние': до, 'вход_sha256': п.хэш_входа, 'прежние_модули_sha256': отпечатки,
        'проверок_структуры_дерева': проверки_структуры[0],
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
    if (len({з['процесс'] for з in наблюдения}) != 6 or снимок() != до
            or any(з['состояние'] != до for з in наблюдения)
            or any(len({з[к] for з in наблюдения}) != 1
                   for к in ('результат_sha256', 'argv_sha256', 'вход_sha256'))):
        raise ValueError('Различаются процессы, состояние или результаты')
    if any(з['новый']['проверок_структуры_дерева'] >= з['прежний']['проверок_структуры_дерева'] for з in пары):
        raise ValueError('Реальная проверка не подтверждает уменьшения повторных разборов')
    итог = {'схема': 'fum.парный-профиль-разбора-дерева.2', 'пары': пары,
        'медианы_wall_ns': {в: statistics.median(з[в]['wall_ns'] for з in пары) for в in ('прежний', 'новый')},
        'граница': 'Шесть новых процессов, одно полное доказательство слоя в каждом. '
            'N7 и декоратор proof включены в обоих; в прежнем варианте только точный AST '
            '_дерево_коммита из основы установлен в фактически используемый модуль. '
            'Остальной текущий контур общий; допустимая дельта проверена AST. '
            'Setup и начальные прямые импорты вне wall; ленивые импорты, наблюдение argv '
            'и счётчик вызовов проверки структуры внутри в обоих вариантах. '
            'cpu — SELF; RSS — максимум всего работника, не размер кэша. Кэш ОС не сбрасывается. '
            'Git и живые файлы читаются заново. Это не весь READY/Create или активация узла.'}
    дескриптор = os.open(п.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(дескриптор, 'wb') as поток:
        поток.write((json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode())
        поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'процессов': 6, 'медианы_wall_ns': итог['медианы_wall_ns']}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
