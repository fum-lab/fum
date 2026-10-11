"""Новый -I -S -B процесс конечного принятого писателя; не sandbox ОС."""
import argparse
import ast
import hashlib
import importlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import time
import types

ПРЕФИКС = 'Инструменты/fum-svyaznostj-rabochej-sessii/'
BOOT = ПРЕФИКС + 'scripts/запуск_принятого_писателя.py'
ENGINE = ПРЕФИКС + 'scripts/исполнение_принятого_кода.py'
СОСТАВ = ПРЕФИКС + 'состав-принятого-писателя.json'


def требовать(условие, сообщение):
    if not условие: raise ValueError(сообщение)


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def обычный(путь, *, приватный=False):
    путь = Path(путь)
    требовать(путь.is_absolute() and путь == путь.resolve(), 'нужен физический путь')
    требовать(not any(п.is_symlink() for п in (путь, *путь.parents)), 'symlink запрещён')
    с = путь.stat()
    требовать(stat.S_ISREG(с.st_mode) and с.st_nlink == 1, 'нужен единственный обычный файл')
    if приватный:
        требовать(stat.S_IMODE(с.st_mode) == 0o600 and с.st_uid == os.getuid()
            and stat.S_IMODE(путь.parent.stat().st_mode) == 0o700, 'нужен приватный вход0600/700')
    return путь.read_bytes()


def git_blob(корень, коммит, имя):
    требовать(len(коммит) == 40 and all(с in '0123456789abcdef' for с in коммит), 'нужен полный OID Q')
    среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
    argv = ['git', '--no-optional-locks', '-C', str(корень)]
    запись = subprocess.check_output([*argv, 'ls-tree', '-z', коммит, '--', имя], env=среда)
    части = запись.split(b'\0'); требовать(len(части) == 2 and части[1] == b'', 'неоднозначный bootstrap blob')
    мета, путь = части[0].split(b'\t'); режим, тип, oid = мета.decode().split()
    требовать(путь.decode() == имя and тип == 'blob' and режим == '100644', 'нужен обычный bootstrap blob0644')
    данные = subprocess.check_output([*argv, 'cat-file', 'blob', oid], env=среда)
    требовать(hashlib.sha1(b'blob '+str(len(данные)).encode()+b'\0'+данные).hexdigest() == oid,
        'bootstrap blob не соответствует байтам')
    требовать(обычный(корень / имя) == данные, 'рабочие байты bootstrap не равны Q')
    return данные


def конечный_запуск(а):
    требовать(sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode,
        'нужен новый процесс -I -S -B')
    path_env = os.environ.get('PATH')
    требовать(type(path_env) is str and path_env and all(п and Path(п).is_absolute()
        for п in path_env.split(os.pathsep)), 'нужен абсолютный непустой PATH')
    git = shutil.which('git')
    требовать(type(git) is str and Path(git).is_absolute(), 'не найден выбранный Git')
    Q = Path(а.корень_кода)
    требовать(Q.is_absolute() and Q == Q.resolve() and Path(__file__) == Q / BOOT,
        'неверный физический bootstrap')
    boot = git_blob(Q, а.коммит_кода, BOOT)
    engine = git_blob(Q, а.коммит_кода, ENGINE)
    требовать(хэш(boot) == а.bootstrap_sha256 and хэш(engine) == а.engine_sha256,
        'нет независимой привязки bootstrap/engine')
    сырые = обычный(а.манифест, приватный=True)
    требовать(хэш(сырые) == а.sha256, 'манифест не соответствует внешнему SHA')
    настройки = json.loads(сырые)
    требовать(type(настройки) is dict and set(настройки) == {'схема', 'код', 'данные',
        'вход', 'новые_параметры', 'проверки', 'готовность', 'возраст_проверок'}
        and настройки['схема'] == 'fum.запуск-принятого-писателя.1'
        and настройки['код'] == {'корень': str(Q), 'коммит': а.коммит_кода}, 'неизвестный манифест запуска')
    # Engine исполняется из проверенного blob, а не повторно открытого SourceLoader.
    модуль = types.ModuleType('доверенный_bootstrap_писателя'); модуль.__file__ = str(Q / ENGINE)
    exec(compile(engine, модуль.__file__, 'exec', dont_inherit=True), модуль.__dict__)
    состав = json.loads(git_blob(Q, а.коммит_кода, СОСТАВ))
    требовать(set(состав) == {'схема', 'вход', 'код', 'имена', 'ресурсы'}
        and состав['схема'] == 'fum.состав-принятого-писателя.1', 'неизвестный конечный состав')
    код = модуль.захватить_набор(Q, а.коммит_кода, состав['код'], 'K')
    ресурсы = модуль.захватить_набор(Q, а.коммит_кода,
        [BOOT, ENGINE, СОСТАВ, *состав['ресурсы']], 'B')
    данные = настройки['данные']
    требовать(type(данные) is dict and set(данные) == {'корень', 'коммит', 'пути'}
        and not (Path(данные['корень']).is_relative_to(Q) or Q.is_relative_to(Path(данные['корень']))),
        'Q и W должны быть физически раздельными')
    ресурсы.update(модуль.захватить_набор(данные['корень'], данные['коммит'], данные['пути'], 'C'))
    контур = модуль.Контур(код, ресурсы)
    вход = настройки['вход']
    требовать(type(вход) is dict and set(вход) == {'путь', 'хэш'}, 'неверный селектор U')
    u_bytes = обычный(вход['путь'], приватный=True)
    требовать(хэш(u_bytes) == вход['хэш'], 'подменён U')
    U = json.loads(u_bytes)
    требовать(U['корень'] == данные['корень'], 'чужой корень U')
    новые = настройки['новые_параметры']
    требовать(type(новые) is dict and set(новые) == {'путь', 'хэш'}, 'неверный селектор G2')
    новые_bytes = обычный(новые['путь'], приватный=True)
    требовать(хэш(новые_bytes) == новые['хэш'], 'подменены новые параметры')
    ids = настройки['проверки']
    требовать(type(ids) is list and 1 <= len(ids) <= 2 and len(ids) == len(set(ids)), 'нужны конечные проверки ACT')
    требовать(type(настройки['возраст_проверок']) is int and 0 < настройки['возраст_проверок'] <= 600,
        'неверная свежесть проверок')
    # До hooks загружаются только конечные stdlib-импорты из AST принятых байтов.
    стандартные = set()
    for запись in код.values():
        for узел in ast.walk(ast.parse(запись['байты'])):
            имена = [э.name for э in узел.names] if isinstance(узел, ast.Import) else (
                [узел.module] if isinstance(узел, ast.ImportFrom) and узел.module and not узел.level else [])
            стандартные.update(и for и in имена if и.split('.')[0] in sys.stdlib_module_names)
    for имя in sorted(стандартные): importlib.import_module(имя)
    # Неизменные каталоги шаблонов/типов: полный список имён и Git-режимов,
    # включая неисполняемые блоки; их содержимое не объявляется прочитанным.
    каталоги = {}
    среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
    for запись in ресурсы.values():
        папка = Path(запись['физический_путь']).parent
        if папка.name not in ('шаблоны', 'типы') or str(папка) in каталоги: continue
        rel = папка.relative_to(Path(запись['корень'])).as_posix()
        raw = subprocess.check_output(['git', '--no-optional-locks', '-C', запись['корень'],
            'ls-tree', '-z', запись['коммит'] + ':' + rel], env=среда)
        имена = {}
        for э in raw.split(b'\0'):
            if not э: continue
            мета, имя = э.split(b'\t'); mode, kind, _ = мета.decode().split()
            требовать(kind == 'blob' and mode in ('100644', '100755'), 'необычный элемент каталога ресурсов')
            имена[имя.decode()] = mode
        каталоги[str(папка)] = имена
    # File-only guard: ни Git, ни Popen, ни blanket recursion bypass здесь нет.
    защищённые = {а.манифест: сырые, вход['путь']: u_bytes, новые['путь']: новые_bytes}
    метки = {п: (stat.S_IMODE(Path(п).stat().st_mode), Path(п).stat().st_uid,
        Path(п).stat().st_nlink) for п in [*код, *ресурсы, *защищённые]}
    счётчики = {'эффектов': 0, 'сверок': 0, 'открытий_IPC': 0}
    null = Path(os.devnull); null_stat = null.lstat()
    требовать(stat.S_ISCHR(null_stat.st_mode) and not null.is_symlink(), 'нужен штатный null device')
    null_identity = (null_stat.st_dev, null_stat.st_ino, null_stat.st_rdev, null_stat.st_mode, null_stat.st_uid)
    читающий = а.режим in ('повтор', 'recency', 'проверка')
    команда_проверки = [sys.executable, '-I', '-S', '-B', str(Q / BOOT),
        '--корень-кода', str(Q), '--коммит-кода', а.коммит_кода,
        '--bootstrap-sha256', а.bootstrap_sha256, '--engine-sha256', а.engine_sha256,
        '--манифест', а.манифест, '--sha256', а.sha256, '--режим', 'проверка']
    def сверить():
        контур.сверить()
        for п, байты in защищённые.items():
            требовать(обычный(п, приватный=True) == байты, 'изменился закрытый вход запуска')
        for п, метка in метки.items():
            с = Path(п).stat()
            требовать((stat.S_IMODE(с.st_mode), с.st_uid, с.st_nlink) == метка, 'изменился физический режим принятого файла')
        for п, имена in каталоги.items():
            имена_диска = os.listdir(п)
            требовать(set(имена_диска) == set(имена)
                and len({и.casefold() for и in имена_диска}) == len(имена_диска), 'изменился состав каталога ресурсов')
            for и in имена_диска:
                файл = Path(п) / и
                требовать(not файл.is_symlink() and файл.is_file()
                    and ('100755' if файл.stat().st_mode & 0o111 else '100644') == имена[и],
                    'изменился тип или Git-режим элемента ресурсов')
        счётчики['сверок'] += 1
    def аудит(событие, аргументы):
        эффект = событие in {'os.remove', 'os.rename', 'os.mkdir', 'os.rmdir', 'os.chmod',
            'os.chown', 'os.utime', 'os.link', 'os.symlink', 'os.truncate', 'os.chdir',
            'fcntl.flock', 'fum.сообщение-коммита.write', 'fum.сообщение-коммита.flush',
            'fum.сообщение-коммита.fsync'}
        if событие == 'open':
            режим = аргументы[1] or ''; флаги = аргументы[2] or 0
            эффект = bool(set(режим) & set('wax+') or флаги & (os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_TRUNC | os.O_APPEND))
            # Stock subprocess открывает null RDWR для stdin=DEVNULL. Это
            # character device, а не запись файла; никакие иные пути не допущены.
            if type(аргументы[0]) is int and stat.S_ISFIFO(os.fstat(аргументы[0]).st_mode):
                # io.open оборачивает уже созданный pipe для input=Git batch.
                # Целочисленный fd исключает создание/замену файлов по пути.
                сверить(); счётчики['открытий_IPC'] += 1
                return
            if type(аргументы[0]) in (str, bytes) and os.fsdecode(аргументы[0]) == str(null):
                сверить(); ns = null.lstat()
                требовать((ns.st_dev, ns.st_ino, ns.st_rdev, ns.st_mode, ns.st_uid) == null_identity
                    and флаги & ~(os.O_RDWR | os.O_CLOEXEC) == 0, 'подменён штатный null device')
                return
        if событие == 'subprocess.Popen':
            сверить()
            exe, argv, _, env = аргументы
            требовать(os.environ.get('PATH') == path_env
                and (env is None or env.get('PATH') == path_env), 'PATH изменился перед subprocess')
            требовать(type(argv) in (list, tuple), 'неизвестная команда subprocess')
            если_гит = os.fsdecode(exe) in ('git', git) and os.fsdecode(argv[0]) in ('git', git)
            if если_гит:
                требовать(shutil.which('git') == git, 'изменился выбранный executable Git')
                if читающий:
                    части = list(argv[1:]); i = 0
                    while i < len(части) and части[i].startswith('-'):
                        i += 2 if части[i] in ('-C', '-c') else 1
                    хвост = части[i:]
                    точное_чтение = хвост in (['symbolic-ref', 'HEAD'], ['worktree', 'list', '--porcelain'],
                        ['worktree', 'list', '--porcelain', '-z'], ['config', '--list'])
                    точное_чтение |= (len(хвост) == 4 and хвост[:2] == ['merge-base', '--is-ancestor']
                        and all(п == 'HEAD' or (len(п) == 40 and all(с in '0123456789abcdef' for с in п))
                            for п in хвост[2:]))
                    требовать(точное_чтение or (i < len(части) and части[i] in {'rev-parse', 'ls-tree', 'cat-file', 'show',
                        'diff', 'diff-tree', 'status', 'log', 'rev-list', 'var', 'check-ref-format',
                        'check-attr', 'check-ignore', 'for-each-ref', 'ls-files'}), 'пишущий Git в читающем режиме')
            else:
                # Единственный дочерний Python — тот же bootstrap в режиме проверки.
                требовать(not читающий and os.fsdecode(exe) == sys.executable
                    and list(argv) == команда_проверки,
                    'subprocess не входит в конечный контур')
            return
        if эффект:
            сверить(); требовать(not читающий, 'эффект запрещён в читающем режиме')
            счётчики['эффектов'] += 1
    результат = {}
    контур.глобальные.update(контур=контур, настройки=настройки, U=U, режим=а.режим,
        результат=результат, сверить_эффект=сверить,
        команда_проверки=команда_проверки)
    сверить()
    sys.addaudithook(аудит)
    начало = time.perf_counter_ns()
    try:
        контур.исполнить(состав['вход'], имена=состав['имена'])
    finally:
        сверить()
    if а.режим != 'recency':
        print(json.dumps({'результат': результат, 'pid': os.getpid(), 'API': 0,
            **счётчики, 'исполнение_нс': time.perf_counter_ns()-начало,
            'исполненные_пути': list(dict.fromkeys(з['путь'] for з in контур.журнал if з['событие'] == 'exec'))},
            ensure_ascii=False), file=sys.stderr if а.режим == 'проверка' else sys.stdout)
    return результат.get('код', 0) if а.режим == 'recency' else 0


def главная():
    п = argparse.ArgumentParser(description=__doc__)
    п.add_argument('--корень-кода', required=True); п.add_argument('--коммит-кода', required=True)
    п.add_argument('--bootstrap-sha256', required=True); п.add_argument('--engine-sha256', required=True)
    п.add_argument('--манифест', required=True); п.add_argument('--sha256', required=True)
    п.add_argument('--режим', required=True, choices=('смена', 'повтор', 'recency', 'проверка'))
    а = п.parse_args()
    try: return конечный_запуск(а)
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as ошибка:
        трасса = []; tb = ошибка.__traceback__
        while tb is not None:
            трасса.append({'файл': tb.tb_frame.f_code.co_filename, 'строка': tb.tb_lineno})
            tb = tb.tb_next
        print(json.dumps({'ошибка': str(ошибка), 'автоматический_повтор': False,
            'трасса': трасса}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(главная())
