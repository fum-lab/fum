"""Три собственных временных репозитория, рекурсивная зависимость и соседнее дерево."""
import hashlib
import os
from pathlib import Path
import subprocess
import sys

КОРЕНЬ = Path(__file__).resolve().parents[3]
СЦЕНАРИИ = Path(__file__).resolve().parent
sys.path.insert(0, str(СЦЕНАРИИ.parent / 'scripts'))
import перенос

ВЛАДЕЛЕЦ = '00000000-0000-4000-8000-000000000207'


def гит(каталог, *аргументы):
    среда = {ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith('GIT_')}
    среда.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull, GIT_TERMINAL_PROMPT='0', GIT_OPTIONAL_LOCKS='0')
    ответ = subprocess.run(['git','-c','protocol.file.allow=always','-c','core.fsmonitor=false','-C',str(каталог),*аргументы],env=среда,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if ответ.returncode:
        raise AssertionError(ответ.stderr.decode())
    return ответ.stdout


def создать_репозиторий(каталог):
    каталог.mkdir()
    гит(каталог,'init','-b','основа')
    гит(каталог,'config','user.name','Фикстура')
    гит(каталог,'config','user.email','fixture@example.invalid')
    (каталог/'данные').write_bytes(b'original\x00bytes\n')
    (каталог/'.gitignore').write_text('игнорируемый\n')
    гит(каталог,'add','.')
    гит(каталог,'commit','-m','Исходная фикстура')


def создать(основание, контейнер=False):
    основание = основание.resolve()
    for имя in ('лист','ветвь','главный'):
        создать_репозиторий(основание/имя)
    гит(основание/'ветвь','submodule','add','--name','особое-имя-листа',str(основание/'лист'),'вложенный')
    гит(основание/'ветвь','commit','-am','Вложенная зависимость')
    гит(основание/'главный','submodule','add','--name','особое-имя-ветви',str(основание/'ветвь'),'модуль')
    гит(основание/'главный','commit','-am','Зависимость')
    if контейнер:
        (основание/'старый-контейнер').mkdir()
    исходный = (основание/'старый-контейнер' if контейнер else основание)/'исходный'
    гит(основание/'главный','worktree','add','-b','codex/перенос',str(исходный))
    гит(исходный,'submodule','update','--init','--recursive')
    for каталог in (исходный, исходный/'модуль', исходный/'модуль/вложенный'):
        (каталог/'игнорируемый').write_bytes(b'ignored\x00\xff\ndata')
        (каталог/'неотслеживаемый').write_text('локальные данные\n')
        (каталог/'данные').write_bytes(b'staged\x00\xff')
        гит(каталог,'add','данные')
        (каталог/'данные').write_bytes(b'working\x00\xfe')
    гит(основание/'главный','worktree','lock','--reason','fum-перенос:'+ВЛАДЕЛЕЦ,str(исходный))
    (основание/'новый-родитель').mkdir()
    состояние = основание/'состояние'
    состояние.mkdir(mode=0o700)
    return {'схема':'fum.привязки-переноса.1','владелец':ВЛАДЕЛЕЦ,'источник':str(исходный),'назначение':str(основание/'новый-родитель'/('исходный' if контейнер else 'назначение')),'общий':str(основание/'главный/.git'),'состояние':str(состояние)}


def снимок_данных(каталог):
    return {str(путь.relative_to(каталог)): (hashlib.sha256(путь.read_bytes()).hexdigest(), путь.stat().st_mode & 0o777) for путь in каталог.rglob('*') if путь.is_file() and путь.name != '.git'}


def снимок_репозиториев(корень):
    результат = []
    for путь in (корень, корень/'модуль', корень/'модуль/вложенный'):
        административный = Path(гит(путь,'rev-parse','--absolute-git-dir').decode().strip())
        результат.append({'вершина':гит(путь,'rev-parse','HEAD').decode().strip(), 'индекс': (административный/'index').read_bytes(), 'ссылки':гит(путь,'for-each-ref','--format=%(refname) %(objectname)'),'статус':гит(путь,'status','--porcelain=v1','--untracked-files=all')})
    return результат


def процесс(план, привязки, прерывание='', владелец=ВЛАДЕЛЕЦ):
    return subprocess.run([sys.executable,'-B',str(СЦЕНАРИИ/'процесс.py'),str(план),str(привязки),прерывание,владелец],stdout=subprocess.PIPE,stderr=subprocess.PIPE)


def снимок_всего(корень):
    import stat
    результат = {}
    for каталог, папки, файлы in os.walk(корень,followlinks=False):
        for имя in папки+файлы:
            путь = Path(каталог)/имя
            состояние = путь.lstat()
            значение = [stat.S_IMODE(состояние.st_mode)]
            if путь.is_symlink():
                значение += ['ссылка',os.readlink(путь)]
            elif путь.is_file():
                значение += ['файл',hashlib.sha256(путь.read_bytes()).hexdigest()]
            else:
                значение += ['каталог']
            результат[путь.relative_to(корень).as_posix()]=значение
    return результат


def подготовить(основание, настройка=None):
    привязки = создать(основание)
    if настройка is not None:
        настройка(привязки)
    план = перенос.построить(привязки)
    путь_плана, путь_привязок = основание/'план.json',основание/'привязки.json'
    путь_плана.write_bytes(перенос.канон.кодировать(план))
    путь_привязок.write_bytes(перенос.канон.кодировать(привязки))
    return привязки,план,путь_плана,путь_привязок
