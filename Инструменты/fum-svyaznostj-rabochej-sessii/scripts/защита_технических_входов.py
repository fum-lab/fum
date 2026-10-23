"""Малые читающие предикаты композиции; не приёмка и не общий builder."""
from pathlib import Path
import os
import re
import stat
import uuid


def проверить_снимок_открытой_пары(снимок):
    """Сохраняет уже полный envelope API без добавления ещё одного уровня."""
    if (type(снимок) is not dict or set(снимок) != {'план', 'файлы'}
            or type(снимок['план']) is not dict
            or type(снимок['файлы']) is not list or not снимок['файлы']):
        raise ValueError('неверная форма снимка открытой пары')
    for запись in снимок['файлы']:
        if (type(запись) is not dict
                or set(запись) != {'путь', 'тип', 'режим', 'sha256'}
                or type(запись['путь']) is not str or not запись['путь']
                or type(запись['режим']) is not int
                or запись['тип'] not in ('файл', 'каталог')
                or (запись['тип'] == 'каталог' and
                    (запись['sha256'] is not None or запись['режим'] not in (0o700, 0o755)))
                or (запись['тип'] == 'файл' and
                    (type(запись['sha256']) is not str
                     or not re.fullmatch('[0-9a-f]{64}', запись['sha256'])
                     or запись['режим'] not in (0o600, 0o644, 0o755)))):
            raise ValueError('неверная запись снимка открытой пары')
    return снимок


def _физический_файл(значение):
    try:
        путь = Path(значение)
        if (not путь.is_absolute() or путь.resolve(strict=True) != путь
                or not stat.S_ISREG(путь.lstat().st_mode)):
            raise ValueError('нужен явный обычный физический файл входа')
    except (TypeError, OSError, RuntimeError) as ошибка:
        raise ValueError('нужен явный обычный физический файл входа') from ошибка
    return путь


def команда_продолжения(корень, интерпретатор, *, задача, исходник, кэш,
        профиль=False):
    """Составляет читающий guard; не выполняет процесс и не записывает кэш."""
    корень = Path(корень)
    if not корень.is_absolute() or корень.resolve() != корень or not корень.is_dir():
        raise ValueError('нужен точный физический корень текущего checkout')
    if (type(интерпретатор) is not str or not Path(интерпретатор).is_absolute()
            or not Path(интерпретатор).is_file() or not os.access(интерпретатор, os.X_OK)):
        raise ValueError('нужен явный существующий исполняемый интерпретатор')
    if type(задача) is not str or str(uuid.UUID(задача)) != задача or type(профиль) is not bool:
        raise ValueError('неверная идентичность задачи или режим профиля')
    исходник, кэш = _физический_файл(исходник), _физический_файл(кэш)
    путь = Path(корень) / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py'
    _физический_файл(путь)
    return [интерпретатор, '-E', '-s', '-S', '-B', str(путь),
        '--корень-репозитория', str(корень), '--codex-thread-id', задача,
        '--исходник', str(исходник), '--кэш', str(кэш), '--перед-завершением',
        *(['--профиль'] if профиль else [])]
