"""Конечный обычный consumer принятого K, W является только данными."""
import argparse
import ast
import hashlib
import importlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import time
import types

ПРЕФИКС = 'Инструменты/fum-svyaznostj-rabochej-sessii/'
ПУСК = ПРЕФИКС + 'scripts/запуск_принятого_создателя.py'
ВХОД = ПРЕФИКС + 'scripts/вход_принятого_создателя.py'
ДВИЖОК = ПРЕФИКС + 'scripts/исполнение_принятого_кода.py'
СОСТАВ = ПРЕФИКС + 'состав-принятого-писателя.json'


def требовать(условие, пояснение):
    if not условие:
        raise ValueError(пояснение)


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def пары(элементы):
    итог = {}
    for имя, значение in элементы:
        требовать(имя not in итог, 'повторный ключ JSON')
        итог[имя] = значение
    return итог


def разобрать(данные):
    return json.loads(данные, object_pairs_hook=пары,
        parse_constant=lambda значение: требовать(False, 'нечисловая JSON-константа'))


def физический(значение):
    требовать(type(значение) is str, 'нужен физический путь')
    путь = Path(значение)
    требовать(путь.is_absolute() and путь == путь.resolve()
        and not any(п.is_symlink() for п in (путь, *путь.parents)), 'нужен физический путь без symlink')
    return путь


def обычный(значение, *, приватный=False):
    путь = физический(str(значение))
    состояние = путь.stat()
    требовать(stat.S_ISREG(состояние.st_mode) and состояние.st_nlink == 1, 'нужен единственный обычный файл')
    if приватный:
        требовать(stat.S_IMODE(состояние.st_mode) == 0o600 and состояние.st_uid == os.getuid()
            and stat.S_IMODE(путь.parent.stat().st_mode) == 0o700,
            'нужен приватный файл0600 в каталоге0700')
        требовать(not any(os.path.lexists(п / '.git') for п in путь.parents), 'приватный вход запрещён в Git')
    return путь.read_bytes()


def прочитать_blob(корень, коммит, имя):
    требовать(re.fullmatch('[0-9a-f]{40}', коммит) is not None, 'нужен полный OID K')
    среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
    команда = ['git', '--no-optional-locks', '--no-replace-objects', '-C', str(корень)]
    запись = subprocess.check_output([*команда, 'ls-tree', '-z', коммит, '--', имя], env=среда)
    части = запись.split(b'\0')
    требовать(len(части) == 2 and not части[-1], 'неоднозначный bootstrap blob')
    мета, путь = части[0].split(b'\t')
    режим, тип, объект = мета.decode().split()
    требовать(путь.decode() == имя and тип == 'blob' and режим == '100644', 'нужен bootstrap blob0644')
    сырые = subprocess.check_output([*команда, 'cat-file', 'blob', объект], env=среда)
    требовать(hashlib.sha1(b'blob ' + str(len(сырые)).encode() + b'\0' + сырые).hexdigest() == объект
        and обычный(корень / имя) == сырые, 'bootstrap не равен принятому Git-объекту')
    return сырые


def допустимый_гит(аргументы, корни, этап, сообщение, настройки_гита=()):
    """Закрытые формы: глобальные опции не могут назначить иной код/индекс."""
    части = list(аргументы[1:])
    корень = None
    while части and части[0].startswith('-'):
        опция = части.pop(0)
        if опция == '-C':
            требовать(части and корень is None, 'неоднозначный корень Git')
            корень = части.pop(0)
        elif опция == '-c':
            требовать(части and части.pop(0) in {'core.quotepath=false',
                'core.hooksPath=' + os.devnull, 'core.fsmonitor=false', *настройки_гита}, 'неразрешённая настройка Git')
        else:
            требовать(опция in {'--no-optional-locks', '--no-replace-objects', '--literal-pathspecs'},
                'неразрешённая глобальная опция Git')
    требовать(корень in корни and части, 'чужой физический корень Git: ' + repr((корень, части)))
    if части[0] == 'write-tree':
        return этап == 'создать' and корень == корни[-1] and части == ['write-tree']
    if части[0] == 'commit':
        return этап == 'создать' and корень == корни[-1] and части == [
            'commit', '--cleanup=verbatim', '--file', сообщение]
    if части[0] == 'symbolic-ref':
        return части == ['symbolic-ref', 'HEAD']
    if части[0] == 'worktree':
        return части in (['worktree', 'list', '--porcelain'], ['worktree', 'list', '--porcelain', '-z'])
    if части[0] == 'config':
        return части == ['config', '--list']
    if части[0] == 'merge-base':
        return len(части) == 4 and части[1] == '--is-ancestor' and all(
            п == 'HEAD' or re.fullmatch('[0-9a-f]{40}', п) for п in части[2:])
    опции = {
        'rev-parse': {'--verify', '--show-toplevel', '--show-prefix', '--show-object-format',
            '--absolute-git-dir', '--git-common-dir', '--git-dir', '--git-path', '--end-of-options',
            '--is-shallow-repository', '--is-bare-repository', '--path-format=absolute'},
        'ls-tree': {'-z', '-r', '--full-tree', '--name-only', '--'},
        'cat-file': {'--batch', '--batch-check', '-t', '-p', '-s'},
        'show': {'--format=', '--no-patch', '--pretty=format:', '--raw', '--no-abbrev', '-z', '--'},
        'diff': {'--cached', '--no-ext-diff', '--no-textconv', '--binary', '--raw', '--no-abbrev',
            '--name-only', '--name-status', '--numstat', '--exit-code', '--quiet', '--no-renames',
            '--ignore-submodules=none', '-z', '--'},
        'diff-tree': {'--no-commit-id', '--name-only', '--name-status', '--raw', '--no-abbrev', '--no-renames', '-r', '-z', '--'},
        'status': {'--porcelain=v1', '--porcelain=v2', '--short', '-z', '--untracked-files=all',
            '--ignore-submodules=none', '--'},
        'ls-files': {'--stage', '--full-name', '--cached', '--others', '--exclude-standard', '-z', '-v', '--'},
        'log': {'--format=%H', '--format=%P', '--format=%aI', '--format=%cI', '--format=%s', '--format=%an', '--format=%B',
            '--pretty=format:%H', '--all', '--reverse', '--topo-order', '--no-walk', '-z', '--'},
        'rev-list': {'--parents', '--all', '--topo-order', '--reverse', '--count', '--max-count=1', '--'},
        'var': set(), 'check-ref-format': set(),
        'check-attr': {'-z', '--stdin', '--all', '--'}, 'check-ignore': {'-z', '--stdin', '--no-index', '--'},
        'for-each-ref': {'--format=%(refname)', '--format=%(objectname)', '--format=%(refname) %(objectname)'},
    }
    if части[0] not in опции:
        return False
    return all(not п.startswith('-') or п in опции[части[0]] for п in части[1:])


def исполнить(а):
    начало = time.perf_counter_ns()
    требовать(sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode, 'нужен свежий -I -S -B процесс')
    окружение_пути = os.environ.get('PATH', '')
    требовать(окружение_пути and all(п and Path(п).is_absolute() for п in окружение_пути.split(os.pathsep)),
        'нужен абсолютный непустой PATH')
    выбранный_гит = shutil.which('git')
    требовать(выбранный_гит and Path(выбранный_гит).is_absolute(), 'не найден выбранный Git')
    корень_кода = физический(а.корень_кода)
    требовать(Path(__file__) == корень_кода / ПУСК, 'чужой bootstrap')
    сырые = обычный(а.манифест, приватный=True)
    требовать(хэш(сырые) == а.sha256, 'подменён закрытый манифест')
    настройки = разобрать(сырые)
    поля = {'схема', 'этап', 'код', 'данные', 'вход', 'поручение', 'подготовка', 'квитанция',
        'проверки', 'готовность', 'возраст_проверок'}
    требовать(type(настройки) is dict and set(настройки) == поля
        and настройки['схема'] == 'fum.запуск-принятого-создателя.1'
        and настройки['код'] == {'корень': str(корень_кода), 'коммит': а.коммит_кода}
        and настройки['этап'] == а.этап, 'неизвестный манифест/этап')
    корень_данных = физический(настройки['данные']['корень'])
    требовать(Path.cwd() == корень_данных, 'нужен выбранный физический cwd W')
    первичный_запуск = subprocess.Popen
    начальные_настройки = ['core.hooksPath=' + os.devnull, 'core.fsmonitor=false', 'protocol.allow=never',
        'protocol.ext.allow=never', 'protocol.file.allow=never', 'protocol.http.allow=never',
        'protocol.https.allow=never', 'protocol.ssh.allow=never', 'protocol.git.allow=never']
    def начальное_чтение(аргументы, *позиционные, **именованные):
        требовать(type(аргументы) in (list, tuple) and аргументы
            and os.fsdecode(аргументы[0]) in ('git', выбранный_гит)
            and not именованные.get('shell') and именованные.get('executable') in (None, 'git', выбранный_гит),
            'неизвестный начальный Git-процесс')
        требовать('-C' in аргументы and аргументы[аргументы.index('-C') + 1] in (str(корень_кода), str(корень_данных)),
            'чужой корень начального Git-чтения')
        хвост = list(аргументы[аргументы.index('-C') + 2:])
        конфиг_чтение = хвост in (['config', '--local', '--no-includes', '--null', '--list'],
            ['config', '--no-includes', '--null', '--show-origin', '--list'])
        требовать(конфиг_чтение or допустимый_гит(аргументы,
            [str(корень_кода), str(корень_данных)], 'повтор', ''), 'неизвестная форма начального Git-чтения')
        среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
        среда.update(GIT_NO_LAZY_FETCH='1', GIT_TERMINAL_PROMPT='0', GIT_NO_REPLACE_OBJECTS='1',
            GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull)
        if хвост == ['config', '--no-includes', '--null', '--show-origin', '--list']:
            for ключ in ('GIT_CONFIG_GLOBAL',):
                if ключ in os.environ:
                    среда[ключ] = os.environ[ключ]
                else:
                    среда.pop(ключ, None)
        именованные['env'] = среда
        префикс = [э for значение in начальные_настройки for э in ('-c', значение)]
        return первичный_запуск([аргументы[0], *префикс, *аргументы[1:]], *позиционные, **именованные)
    subprocess.Popen = начальное_чтение
    # До первого чтения объектных байтов W: raw local config без include/lazy fetch.
    for корень in (корень_кода, корень_данных):
        конфиг = subprocess.check_output([выбранный_гит, '--no-optional-locks', '-C', str(корень),
            'config', '--local', '--no-includes', '--null', '--list'])
        for запись in конфиг.split(b'\0'):
            ключ = запись.split(b'\n', 1)[0].decode().lower()
            требовать(not (ключ.startswith('include') or ключ == 'extensions.partialclone'
                or (ключ.startswith('remote.') and ключ.endswith('.promisor'))),
                'partial/promisor/include конфигурация запрещена до capture')
    пуск = прочитать_blob(корень_кода, а.коммит_кода, ПУСК)
    движок = прочитать_blob(корень_кода, а.коммит_кода, ДВИЖОК)
    требовать(хэш(пуск) == а.bootstrap_sha256 and хэш(движок) == а.engine_sha256, 'подменён выбранный bootstrap/engine')
    модуль = types.ModuleType('принятый_движок_создателя')
    модуль.__file__ = str(корень_кода / ДВИЖОК)
    exec(compile(движок, модуль.__file__, 'exec', dont_inherit=True), модуль.__dict__)
    # Прежний состав читается как неизменные данные K. Его state entry не исполняется.
    состав = разобрать(прочитать_blob(корень_кода, а.коммит_кода, СОСТАВ))
    требовать(set(состав) == {'схема', 'вход', 'код', 'имена', 'ресурсы'}
        and состав['схема'] == 'fum.состав-принятого-писателя.1', 'неизвестный конечный состав K')
    пути_кода = [п for п in состав['код'] if п != состав['вход']] + [ВХОД]
    код = модуль.захватить_набор(корень_кода, а.коммит_кода, пути_кода, 'K')
    ресурсы = модуль.захватить_набор(корень_кода, а.коммит_кода,
        [ПУСК, ДВИЖОК, СОСТАВ, *состав['ресурсы']], 'B')
    данные = настройки['данные']
    требовать(type(данные) is dict and set(данные) == {'корень', 'коммит', 'пути'}, 'неверный селектор W')
    корень_данных = физический(данные['корень'])
    требовать(Path.cwd() == корень_данных, 'нужен выбранный физический cwd W')
    требовать(not (корень_данных.is_relative_to(корень_кода) or корень_кода.is_relative_to(корень_данных)), 'K и W должны быть раздельными')
    ресурсы.update(модуль.захватить_набор(корень_данных, данные['коммит'], данные['пути'], 'C'))
    контур = модуль.Контур(код, ресурсы)
    защищённые = {а.манифест: сырые}
    конфигурации = {}
    def снимок_конфига(путь):
        путь = физический(str(путь))
        if not os.path.lexists(путь):
            return None
        байты_конфига = обычный(путь)
        с = путь.stat()
        return (байты_конфига, с.st_dev, с.st_ino, с.st_mode, с.st_uid,
            с.st_nlink, с.st_mtime_ns, с.st_ctime_ns)

    def закрепить_конфиг(путь):
        путь = str(путь)
        снимок = снимок_конфига(путь)
        if путь in конфигурации:
            требовать(конфигурации[путь] == снимок, 'изменилась конфигурация Git при inventory')
        else:
            конфигурации[путь] = снимок

    безопасные_настройки = ['core.hooksPath=' + os.devnull, 'core.fsmonitor=false',
        'core.pager=cat', 'commit.gpgsign=false', 'tag.gpgSign=false', 'credential.helper=',
        'diff.external=', 'protocol.allow=never']
    исходная_среда = dict(os.environ)
    перенаправление = {'GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR',
        'GIT_OBJECT_DIRECTORY', 'GIT_ALTERNATE_OBJECT_DIRECTORIES', 'GIT_CONFIG_PARAMETERS',
        'GIT_CONFIG_COUNT', 'GIT_REPLACE_REF_BASE', 'GIT_SHALLOW_FILE', 'GIT_NAMESPACE', 'GIT_EXTERNAL_DIFF'}
    требовать(not перенаправление.intersection(исходная_среда), 'перенаправляющая среда Git запрещена')
    глобальные_пути = ([Path(исходная_среда['GIT_CONFIG_GLOBAL'])] if 'GIT_CONFIG_GLOBAL' in исходная_среда
        else [Path.home() / '.gitconfig', Path(исходная_среда.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'git/config'])
    for путь in глобальные_пути:
        if str(путь) != os.devnull:
            закрепить_конфиг(путь)
    личности = {}
    for корень in (корень_кода, корень_данных):
        общая = subprocess.check_output([выбранный_гит, '-C', str(корень), 'rev-parse',
            '--path-format=absolute', '--git-common-dir'], text=True).strip()
        служебная = subprocess.check_output([выбранный_гит, '-C', str(корень), 'rev-parse',
            '--absolute-git-dir'], text=True).strip()
        закрепить_конфиг(Path(общая) / 'config')
        закрепить_конфиг(Path(служебная) / 'config.worktree')
        личность = {}
        записи = subprocess.check_output([выбранный_гит, '--no-optional-locks', '--no-replace-objects',
            '-C', str(корень), 'config', '--no-includes', '--null', '--show-origin', '--list']).split(b'\0')
        требовать(записи[-1] == b'' and len(записи) % 2 == 1, 'неверный инвентарь конфигурации')
        for позиция in range(0, len(записи) - 1, 2):
            источник = записи[позиция].decode()
            поле_значения = записи[позиция + 1].decode()
            ключ, _, значение = поле_значения.partition('\n')
            требовать(not ключ.lower().startswith('include'), 'include конфигурация запрещена')
            if источник == 'command line:':
                требовать(ключ.lower() + '=' + значение in [п.lower() for п in начальные_настройки],
                    'неизвестная командная конфигурация')
                continue
            требовать(источник.startswith('file:'), 'нефайловая конфигурация Git запрещена')
            путь_конфига = Path(источник[5:])
            if not путь_конфига.is_absolute():
                путь_конфига = корень / путь_конфига
            путь_конфига = путь_конфига.absolute()
            закрепить_конфиг(путь_конфига)
            if ключ.lower() in {'user.name', 'user.email', 'user.useconfigonly',
                'author.name', 'author.email', 'committer.name', 'committer.email'}:
                личность[ключ.lower()] = значение
            if ключ.startswith('filter.'):
                имя, разделитель, поле = ключ.rpartition('.')
                требовать(разделитель and поле in {'clean', 'smudge', 'process', 'required'},
                    'неизвестное поле фильтра Git')
                безопасные_настройки.append(ключ + ('=false' if поле == 'required' else '='))
            if ключ.startswith('diff.') and ключ.endswith('.textconv'):
                безопасные_настройки.append(ключ + '=')
        личности[str(корень)] = [к + '=' + в for к, в in личность.items()]
        for имя, снимок in конфигурации.items():
            требовать(снимок_конфига(имя) == снимок, 'изменилась конфигурация Git при inventory')
    безопасные_настройки = list(dict.fromkeys(безопасные_настройки))
    выбранные = {}
    for имя in ('вход', 'поручение', 'подготовка', 'квитанция'):
        ссылка = настройки[имя]
        if ссылка is None:
            требовать(имя in {'подготовка', 'квитанция'}, 'отсутствующий независимый вход')
            continue
        требовать(type(ссылка) is dict and set(ссылка) == {'путь', 'sha256'}, 'неверный приватный selector')
        байты_входа = обычный(ссылка['путь'], приватный=True)
        требовать(хэш(байты_входа) == ссылка['sha256'], 'подменён выбранный ' + имя)
        защищённые[ссылка['путь']] = байты_входа
        выбранные[имя] = разобрать(байты_входа)
    параметры = выбранные['вход']
    требовать(параметры.get('схема') == 'fum.создание-коммита.7' and параметры['корень'] == str(корень_данных)
        and параметры['исходный_коммит'] == данные['коммит'], 'нужен выбранный обычный maker .7')
    требовать(выбранные['поручение'] == параметры['выбранное_поручение'], 'копия ACT расходится с независимым выбором')
    требовать(os.environ.get('CODEX_THREAD_ID') == параметры['исполнитель'], 'чужой UUID процесса')
    if а.этап == 'подготовить':
        требовать(настройки['подготовка'] is None and настройки['квитанция'] is None, 'prepare не принимает чужую подготовку')
    else:
        требовать(выбранные.get('подготовка', {}).get('схема') == 'fum.подготовленный-коммит.9'
            and выбранные['подготовка']['параметры'] == параметры
            and настройки['подготовка']['путь'] == параметры['подготовка'], 'нужна точная подготовка .9')
    требовать((а.этап == 'повтор') == (настройки['квитанция'] is not None), 'неверный selector повторной квитанции')
    if а.этап == 'повтор':
        требовать(настройки['квитанция']['путь'] == параметры['квитанция'], 'чужая квитанция')
    elif а.этап == 'создать':
        требовать(not os.path.lexists(параметры['квитанция']), 'существующая квитанция требует читающего повтора')
    проверочные_идентификаторы = настройки['проверки']
    требовать(type(проверочные_идентификаторы) is list and проверочные_идентификаторы and len(проверочные_идентификаторы) == len(set(проверочные_идентификаторы))
        and all(type(п) is str and re.fullmatch('[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}', п) for п in проверочные_идентификаторы), 'неверные UUID проверок')
    требовать(type(настройки['возраст_проверок']) is int and 0 < настройки['возраст_проверок'] <= 600, 'неверный предел проверок')
    готовность = физический(настройки['готовность'])
    требовать(not any(os.path.lexists(п / '.git') for п in (готовность, *готовность.parents)), 'READY запрещён в Git')
    стандартные = set()
    for запись in код.values():
        for узел in ast.walk(ast.parse(запись['байты'])):
            имена = [э.name for э in узел.names] if isinstance(узел, ast.Import) else (
                [узел.module] if isinstance(узел, ast.ImportFrom) and узел.module and not узел.level else [])
            стандартные.update(и for и in имена if и.split('.')[0] in sys.stdlib_module_names)
    for имя in sorted(стандартные):
        importlib.import_module(имя)
    каталоги = {}
    for запись in ресурсы.values():
        папка = Path(запись['физический_путь']).parent
        if папка.name in ('шаблоны', 'типы') and папка not in каталоги:
            относительный = папка.relative_to(Path(запись['корень'])).as_posix()
            сырые_имена = subprocess.check_output([выбранный_гит, '--no-optional-locks', '-C', запись['корень'],
                'ls-tree', '-z', запись['коммит'] + ':' + относительный])
            имена = {}
            for элемент in сырые_имена.split(b'\0'):
                if not элемент:
                    continue
                мета, имя = элемент.split(b'\t')
                режим, тип, _ = мета.decode().split()
                требовать(тип == 'blob' and режим in {'100644', '100755'}, 'необычный ресурс Git')
                имена[имя.decode()] = (stat.S_IFREG, режим == '100755')
            каталоги[папка] = имена
    метки = {п: (stat.S_IMODE(Path(п).stat().st_mode), Path(п).stat().st_uid, Path(п).stat().st_nlink)
        for п in [*код, *ресурсы, *защищённые]}
    счётчики = {'эффектов': 0, 'сверок': 0, 'читающих_процессов': 0, 'пишущих_процессов': 0}
    читающий = а.этап in ('повтор', 'свежесть')
    нуль = Path(os.devnull)
    состояние_нуля = нуль.lstat()
    требовать(stat.S_ISCHR(состояние_нуля.st_mode) and not нуль.is_symlink(), 'неверный null device')

    def сверить():
        контур.сверить()
        требовать(os.environ.get('PATH') == окружение_пути
            and os.environ.get('CODEX_THREAD_ID') == параметры['исполнитель'], 'изменилось выбранное окружение')
        требовать(dict(os.environ) == исходная_среда, 'изменилось окружение принятого процесса')
        for имя, байты_входа in защищённые.items():
            требовать(обычный(имя, приватный=True) == байты_входа, 'изменился закрытый вход')
        for имя, снимок in конфигурации.items():
            требовать(снимок_конфига(имя) == снимок, 'изменилась конфигурация Git')
        for имя, метка in метки.items():
            с = Path(имя).stat()
            требовать((stat.S_IMODE(с.st_mode), с.st_uid, с.st_nlink) == метка, 'изменился режим принятого файла')
        for папка, состав_каталога in каталоги.items():
            текущий = {п.name: (stat.S_IFMT(п.lstat().st_mode), bool(п.stat().st_mode & 0o111)) for п in папка.iterdir()}
            требовать(текущий == состав_каталога and all(тип == stat.S_IFREG for тип, _ in текущий.values())
                and len({и.casefold() for и in текущий}) == len(текущий), 'изменился состав ресурсов')
        счётчики['сверок'] += 1

    def аудит(событие, аргументы):
        if событие in {'os.system', 'os.posix_spawn', 'os.exec', 'ctypes.dlopen', 'ctypes.dlsym'}:
            raise ValueError('альтернативное исполнение запрещено')
        эффект = событие in {'os.remove', 'os.rename', 'os.mkdir', 'os.rmdir', 'os.chmod',
            'os.chown', 'os.utime', 'os.link', 'os.symlink', 'os.truncate', 'os.chdir', 'fcntl.flock'}
        if событие == 'open':
            режим = аргументы[1] or ''
            флаги = аргументы[2] or 0
            эффект = bool(set(режим) & set('wax+') or флаги & (os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_TRUNC | os.O_APPEND))
            if type(аргументы[0]) is int and stat.S_ISFIFO(os.fstat(аргументы[0]).st_mode):
                сверить()
                return
            if type(аргументы[0]) in (str, bytes) and os.fsdecode(аргументы[0]) == str(нуль):
                сверить()
                требовать(нуль.lstat() == состояние_нуля and флаги & (os.O_RDWR | os.O_CLOEXEC) == флаги, 'подменён null device')
                return
        if событие == 'subprocess.Popen':
            сверить()
            исполнитель, аргв, рабочий_каталог, среда = аргументы
            требовать(type(аргв) in (list, tuple) and аргв and os.fsdecode(исполнитель) in ('git', выбранный_гит)
                and os.fsdecode(аргв[0]) in ('git', выбранный_гит) and shutil.which('git') == выбранный_гит
                and (среда is None or среда.get('PATH') == окружение_пути), 'subprocess вне конечного контура')
            требовать(рабочий_каталог is None or os.fsdecode(рабочий_каталог) in (str(корень_кода), str(корень_данных)), 'чужой cwd subprocess')
            фактическая_среда = исходная_среда if среда is None else среда
            безопасная_среда = {'GIT_OPTIONAL_LOCKS': '0', 'GIT_NO_LAZY_FETCH': '1',
                'GIT_NO_REPLACE_OBJECTS': '1', 'GIT_TERMINAL_PROMPT': '0', 'LC_ALL': 'C', 'LANG': 'C',
                'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull}
            требовать(not перенаправление.intersection(фактическая_среда)
                and set(фактическая_среда) <= set(исходная_среда) | set(безопасная_среда) | {'GIT_AUTHOR_NAME'}
                and all(значение == исходная_среда.get(ключ) or значение == безопасная_среда.get(ключ)
                    for ключ, значение in фактическая_среда.items() if ключ != 'GIT_AUTHOR_NAME'),
                'подменённая среда subprocess: ' + repr([к for к, в in фактическая_среда.items()
                    if к != 'GIT_AUTHOR_NAME' and в != исходная_среда.get(к) and в != безопасная_среда.get(к)]))
            требовать(допустимый_гит(аргв, [str(корень_кода), str(корень_данных)], а.этап,
                параметры['сообщение'], [*безопасные_настройки, *личности[аргв[аргв.index('-C') + 1]]]),
                'форма Git не входит в закрытый перечень: ' + repr(list(аргв[1:])))
            части_команды = list(аргв[1:])
            while части_команды and части_команды[0].startswith('-'):
                опция = части_команды.pop(0)
                if опция in ('-C', '-c'):
                    части_команды.pop(0)
            счётчики['пишущих_процессов' if части_команды[0] in {'write-tree', 'commit'}
                else 'читающих_процессов'] += 1
            return
        if эффект:
            сверить()
            требовать(not читающий, 'эффект запрещён в читающем повторе')
            счётчики['эффектов'] += 1

    результат = {}
    измерения = {}
    контур.глобальные.update(настройки=настройки, параметры=параметры,
        выбранные=выбранные, результат=результат, сверить_эффект=сверить,
        защищённые=защищённые, читающий=читающий, измерения=измерения)
    сверить()
    исходный_запуск = первичный_запуск
    def принятый_запуск(аргументы, *позиционные, **именованные):
        сверить()
        требовать(type(аргументы) in (list, tuple) and аргументы
            and os.fsdecode(аргументы[0]) in ('git', выбранный_гит), 'чужой subprocess')
        рабочий_каталог = именованные.get('cwd')
        требовать(рабочий_каталог is None or os.fsdecode(рабочий_каталог) in (str(корень_кода), str(корень_данных)), 'чужой cwd subprocess')
        if '-C' not in аргументы:
            аргументы = [аргументы[0], '-C', str(Path.cwd() if рабочий_каталог is None else рабочий_каталог), *аргументы[1:]]
        требовать(допустимый_гит(аргументы, [str(корень_кода), str(корень_данных)], а.этап,
            параметры['сообщение']), 'форма Git вне закрытого перечня')
        префикс = [э for настройка in [*безопасные_настройки, *личности[аргументы[аргументы.index('-C') + 1]]]
            for э in ('-c', настройка)]
        среда = dict(os.environ if именованные.get('env') is None else именованные['env'])
        среда.pop('GIT_CONFIG_SYSTEM', None)
        среда.update(GIT_NO_LAZY_FETCH='1', GIT_TERMINAL_PROMPT='0', GIT_NO_REPLACE_OBJECTS='1', GIT_OPTIONAL_LOCKS='0',
            GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull)
        именованные['env'] = среда
        return исходный_запуск([аргументы[0], *префикс, *аргументы[1:]], *позиционные, **именованные)
    subprocess.Popen = принятый_запуск
    sys.addaudithook(аудит)
    захват_нс = time.perf_counter_ns() - начало
    исходный_вывод = sys.stdout
    исходный_служебный_вывод = sys.__stdout__
    отложенный_вывод = io.StringIO()
    sys.stdout = sys.__stdout__ = отложенный_вывод
    try:
        контур.исполнить(ВХОД, имена=состав['имена'])
        сверить()
        итоговые_байты = (json.dumps({'результат': результат, **счётчики, **измерения, 'pid': os.getpid(),
            'захват_нс': захват_нс, 'процесс_нс': time.perf_counter_ns() - начало,
            'исполненные_пути': list(dict.fromkeys(з['путь'] for з in контур.журнал if з['событие'] == 'exec'))},
            ensure_ascii=False) + '\n').encode('utf-8')
        сверить()
    finally:
        # Ни ошибка, ни CPython shutdown не выпускают прежний буфер K.
        sys.stdout = исходный_вывод
        sys.__stdout__ = исходный_служебный_вывод
        отложенный_вывод.close()
    # Единственная контролируемая выдача после всех late checks, без TextIO-буфера.
    сверить()
    записано = os.write(исходный_вывод.fileno(), итоговые_байты)
    требовать(записано == len(итоговые_байты), 'неполная выдача результата; успешного исхода нет')
    return 0


def главная():
    п = argparse.ArgumentParser(description=__doc__)
    п.add_argument('--корень-кода', required=True)
    п.add_argument('--коммит-кода', required=True)
    п.add_argument('--bootstrap-sha256', required=True)
    п.add_argument('--engine-sha256', required=True)
    п.add_argument('--манифест', required=True)
    п.add_argument('--sha256', required=True)
    п.add_argument('--этап', required=True, choices=('подготовить', 'готово', 'создать', 'повтор', 'свежесть'))
    try:
        return исполнить(п.parse_args())
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as ошибка:
        причины = []
        причина = ошибка.__cause__
        while причина is not None and len(причины) < 8:
            причины.append(str(причина))
            причина = причина.__cause__
        print(json.dumps({'ошибка': str(ошибка), 'причины': причины,
            'автоматический_повтор': False}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(главная())
