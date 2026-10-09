"""Сбор наблюдений и повторное чтение; неизвестные ошибки закрывают вход."""
from dataclasses import replace
import hashlib
import os
from pathlib import Path, PurePosixPath
import stat
import subprocess
import sys
import uuid
from .модель import Кандидат, Наблюдение, НеполныйСнимок, Снимок, хэш
from .поднабор import пространство
from .пути import Путь


def состояние(путь):
    try: режим = путь.lstat().st_mode
    except (FileNotFoundError, NotADirectoryError): return ('отсутствует',)
    if stat.S_ISLNK(режим): return ('ссылка', os.readlink(путь))
    if stat.S_ISDIR(режим): return ('каталог',)
    if stat.S_ISREG(режим): return ('файл',)
    return ('иной', stat.S_IFMT(режим))


def значение(операция, адрес):
    путь = Path(адрес)
    if not путь.is_absolute(): raise НеполныйСнимок('живое чтение относительного пути')
    try:
        if операция == 'узел': return состояние(путь)
        if операция == 'resolve': return str(путь.resolve())
        if операция == 'read_bytes': return путь.read_bytes()
        if операция == 'stat':
            try: return stat.S_IFMT(путь.stat().st_mode)
            except (FileNotFoundError, NotADirectoryError): return None
        if операция == 'iterdir':
            try: return tuple(sorted(str(элемент) for элемент in путь.iterdir()))
            except (FileNotFoundError, NotADirectoryError): return None
        # Path.exists в ряде Python подавляет прочие OSError. Здесь они неизвестны.
        if операция in ('exists', 'is_dir', 'is_symlink'):
            try: режим = (путь.lstat() if операция == 'is_symlink' else путь.stat()).st_mode
            except (FileNotFoundError, NotADirectoryError): return False
            return True if операция == 'exists' else (stat.S_ISDIR(режим) if операция == 'is_dir' else stat.S_ISLNK(режим))
    except OSError as ошибка:
        raise НеполныйСнимок(f'недоступное наблюдение {операция}: {адрес}') from ошибка
    raise НеполныйСнимок('неизвестная операция живого чтения')


class Наблюдатель:
    def __init__(сам, корень):
        сам.корень = корень
        сам.записи = {}
        сам.цепи = set()
        сам.выходы = set()

    def сохранить(сам, операция, путь):
        новое = значение(операция, путь)
        ключ = операция, путь
        if ключ in сам.записи and сам.записи[ключ] != новое:
            raise НеполныйСнимок('дрейф повторного наблюдения во время сбора')
        сам.записи[ключ] = новое
        return новое

    def каталог(сам, путь):
        ключ = 'iterdir', путь
        дети = сам.записи[ключ] if ключ in сам.записи else сам.сохранить('iterdir', путь)
        if дети is not None:
            for ребёнок in дети:
                if ('узел', ребёнок) not in сам.записи:
                    сам.сохранить('узел', ребёнок)

    def цепь(сам, адрес, глубина=0):
        if глубина > 40: raise НеполныйСнимок('не замкнута цепь символьных ссылок')
        if адрес in сам.цепи: return
        сам.цепи.add(адрес)
        путь = PurePosixPath(адрес)
        try: части = путь.relative_to(сам.корень).parts
        except ValueError:
            raise НеполныйСнимок('незамкнутая внешняя часть цепи символьных ссылок')
        текущий = Path(сам.корень)
        сам.сохранить('узел', str(текущий))
        for часть in части:
            if часть == '..' and текущий.resolve() == Path(сам.корень):
                сам.выходы.add(адрес)
                return
            if состояние(текущий)[0] == 'каталог': сам.каталог(str(текущий))
            текущий /= часть
            узел = сам.сохранить('узел', str(текущий))
            if узел[0] == 'ссылка':
                цель = Path(узел[1])
                if not цель.is_absolute(): цель = текущий.parent / цель
                сам.цепь(str(цель), глубина + 1)
                # Компоненты после alias проверяются по разрешённой основе.
                разрешённый = str(текущий.resolve())
                сам.сохранить('resolve', str(текущий))
                сам.цепь(разрешённый, глубина + 1)
                текущий = Path(разрешённый)
            elif узел[0] == 'отсутствует': break

    def __call__(сам, операция, путь):
        сам.цепь(путь)
        новое = сам.сохранить(операция, путь)
        if операция == 'iterdir': сам.каталог(путь)
        if операция == 'resolve':
            try: PurePosixPath(новое).relative_to(сам.корень)
            except ValueError: pass  # Прямой escape уже доказан конечной целью.
            else:
                if путь in сам.выходы:
                    raise НеполныйСнимок('внешний путь возвращается через незамкнутый обход')
                сам.цепь(новое)
        return новое

    def снимок(сам):
        return tuple(Наблюдение(оп, путь, запись) for (оп, путь), запись in sorted(сам.записи.items()))


def параметры(корень):
    запрещённые = tuple(sorted(ключ for ключ in os.environ if ключ.startswith('GIT_') and ключ != 'GIT_PAGER'))
    if запрещённые: raise НеполныйСнимок('неподдержанная управляющая среда Git')
    гит = (корень / '.git').exists()
    среда_Python = (sys.version, sys.platform, sys.getfilesystemencoding())
    среда = tuple((ключ, hashlib.sha256(os.environ.get(ключ, '').encode()).hexdigest())
        for ключ in ('HOME', 'XDG_CONFIG_HOME', 'PATH', 'GIT_PAGER'))
    if not гит: return (('инвентарь', 'filesystem'), ('среда', среда), ('кодировка', 'utf-8'), ('Python', среда_Python))
    def команда(*аргументы):
        результат = subprocess.run(['git', '-C', str(корень), *аргументы], check=True, capture_output=True)
        return результат.stdout
    верх = Path(os.fsdecode(команда('rev-parse', '--show-toplevel')).strip()).resolve()
    if верх != корень: raise НеполныйСнимок('Git принадлежит другому корню')
    конфигурация = команда('config', '--null', '--show-origin', '--list')
    return (('инвентарь', 'git'), ('корень_git', str(верх)), ('среда', среда),
        ('конфигурация_git', hashlib.sha256(конфигурация).hexdigest()), ('кодировка', 'utf-8'), ('Python', среда_Python))


def инвентарь(корень, наблюдатель):
    from . import ПРОЕКТНЫЕ_ФАЙЛЫ
    гит = (корень / '.git').exists()
    if гит:
        кандидаты, отслеживаемые = ПРОЕКТНЫЕ_ФАЙЛЫ._git_markdown_relpaths(корень)
    else:
        кандидаты = ПРОЕКТНЫЕ_ФАЙЛЫ._filesystem_markdown_relpaths(корень); отслеживаемые = set()
    существующие = ПРОЕКТНЫЕ_ФАЙЛЫ.project_markdown_paths(корень)
    записи = []
    for относительный in sorted(кандидаты):
        путь = корень / относительный
        наблюдатель.цепь(str(путь))
        узел = наблюдатель.сохранить('узел', str(путь))
        удаление = ПРОЕКТНЫЕ_ФАЙЛЫ._git_status_for_path(корень, относительный) if гит and узел[0] == 'отсутствует' and относительный in отслеживаемые else ''
        записи.append(Кандидат(относительный.as_posix(), 'tracked' if относительный in отслеживаемые else ('untracked' if гит else 'filesystem'), узел, удаление))
    байты = tuple((элемент.relative_to(корень).as_posix(), наблюдатель('read_bytes', str(элемент))) for элемент in существующие)
    # Некорректный UTF-8 во внецелевом Markdown тоже не допускается.
    for _, текст in байты: текст.decode('utf-8')
    return tuple(записи), байты


def собрать(корень, выбранные=None):
    from . import КОД_ЗАГРУЗКИ
    корень = Path(корень).resolve(strict=True)
    наблюдатель = Наблюдатель(str(корень))
    настройки = параметры(корень)
    кандидаты, тексты = инвентарь(корень, наблюдатель)
    состав = tuple(элемент[0] for элемент in тексты) if выбранные is None else tuple(выбранные)
    известные = {элемент.путь for элемент in кандидаты}
    if len(set(состав)) != len(состав) or any(type(элемент) is not str or элемент not in известные for элемент in состав):
        raise НеполныйСнимок('выбранный состав не принадлежит полному инвентарю')
    путь = lambda элемент: Путь(элемент, наблюдатель)
    функции = пространство(путь, КОД_ЗАГРУЗКИ)
    функции['validate_markdown_links']({путь(корень) / элемент for элемент in состав}, путь(корень))
    # Первый вычисленный исход не сохраняется как свидетельство pure.
    исходный = Снимок('fum.снимок-ссылок.1', str(uuid.uuid4()), str(корень), состав,
        кандидаты, тексты, наблюдатель.снимок(), КОД_ЗАГРУЗКИ, настройки, True, '')
    итог = replace(исходный, sha256=хэш(исходный))
    from .сверка import сверить
    сверить(итог)
    return итог
