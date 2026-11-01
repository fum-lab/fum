"""Связать загруженный Python-исходник с точными исполненными байтами."""
from __future__ import annotations

import hashlib
import importlib.util
from pathlib import Path, PurePosixPath
import stat
import sys


КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


def _обычный_исходник(путь):
    путь = Path(путь)
    if (not путь.is_absolute() or путь != путь.resolve()
            or путь.is_symlink() or any(предок.is_symlink() for предок in путь.parents)
            or not stat.S_ISREG(путь.lstat().st_mode)):
        raise ValueError('Загрузочный исходник должен иметь точный обычный путь без символических ссылок')
    return путь


def загрузить_исходник(путь, имя):
    путь = _обычный_исходник(путь)
    байты = путь.read_bytes()
    отпечаток = hashlib.sha256(байты).hexdigest()
    описание = importlib.util.spec_from_file_location(имя, путь)
    if описание is None:
        raise ValueError('Не удалось описать загрузочный исходник')
    модуль = importlib.util.module_from_spec(описание)
    прежний = sys.modules.get(имя)
    sys.modules[имя] = модуль
    try:
        exec(compile(байты, str(путь), 'exec', dont_inherit=True), модуль.__dict__)
        сверить_загрузку(путь.parent, {путь.name: отпечаток})
        модуль.КОД_ПРИ_ЗАГРУЗКЕ = отпечаток
    except BaseException:
        if прежний is None:
            sys.modules.pop(имя, None)
        else:
            sys.modules[имя] = прежний
        raise
    return модуль, отпечаток


def сверить_загрузку(корень, отпечатки):
    корень = Path(корень)
    if not корень.is_absolute() or корень != корень.resolve():
        raise ValueError('Требуется физический корень загрузочного контура')
    for имя, отпечаток in отпечатки.items():
        части = PurePosixPath(имя)
        if (type(имя) is not str or not имя or имя != части.as_posix() or части.is_absolute()
                or any(часть in {'.', '..', '.git'} for часть in имя.split('/'))):
            raise ValueError('Загрузочный путь вышел за конечный контур')
        путь = _обычный_исходник(корень / имя)
        if not путь.is_relative_to(корень) or hashlib.sha256(путь.read_bytes()).hexdigest() != отпечаток:
            raise ValueError('Исполняемый исходник изменился после загрузки; нужен новый процесс')
