"""Ограниченный JSON-контракт и чтение собственных приватных свидетельств."""
import hashlib
from pathlib import Path

КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat


class ОшибкаОбзора(ValueError):
    pass


def требовать(условие, причина):
    if not условие:
        raise ОшибкаОбзора(причина)


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def байты(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False) + '\n').encode()


def разобрать(данные):
    def пары(элементы):
        результат = {}
        for ключ, значение in элементы:
            требовать(ключ not in результат, 'Повтор ключа JSON')
            результат[ключ] = значение
        return результат
    def константа(_):
        raise ОшибкаОбзора('Неограниченная числовая константа JSON')
    try:
        return json.loads(данные, object_pairs_hook=пары, parse_constant=константа)
    except (ValueError, UnicodeError) as причина:
        raise ОшибкаОбзора(str(причина)) from причина


def поля(значение, имена):
    требовать(type(значение) is dict and set(значение) == set(имена), 'Неизвестные или пропущенные поля')


def проверить_идентификатор_объекта(значение):
    требовать(type(значение) is str and re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}', значение), 'Нужен полный OID')
    return значение


def относительный(значение):
    требовать(type(значение) is str and 0 < len(значение) <= 1024 and not any(элемент in значение for элемент in '\\' + '\0\r\n'), 'Неверный путь Git')
    проверяемый_путь = PurePosixPath(значение)
    требовать(not проверяемый_путь.is_absolute() and str(проверяемый_путь) == значение and all(элемент not in ('.', '..', '') for элемент in значение.split('/')),
        'Нужен нормализованный относительный путь')
    требовать(проверяемый_путь.parts[0].casefold() != 'proyekcii', 'Проекция не является источником обзора')
    return значение


def физический(значение, *, приватный=False):
    проверяемый_путь = Path(значение)
    требовать(проверяемый_путь.is_absolute() and проверяемый_путь == проверяемый_путь.resolve(), 'Нужен физический абсолютный путь без symlink')
    if приватный:
        требовать(not any(os.path.lexists(предок / '.git') for предок in (проверяемый_путь, *проверяемый_путь.parents)), 'Приватное хранение должно быть вне Git')
    return проверяемый_путь


def прочитать_приватный(значение, предел=2 * 1024 * 1024):
    проверяемый_путь = физический(значение, приватный=True)
    with os.fdopen(os.open(проверяемый_путь, os.O_RDONLY | os.O_NOFOLLOW), 'rb') as поток:
        до = os.fstat(поток.fileno())
        требовать(stat.S_ISREG(до.st_mode) and до.st_nlink == 1 and до.st_uid == os.getuid()
            and not до.st_mode & 0o077 and 0 < до.st_size <= предел, 'Нужен собственный ограниченный приватный файл')
        данные = поток.read(предел + 1)
        после = os.fstat(поток.fileno())
        метка = lambda сведения_файла: (сведения_файла.st_dev, сведения_файла.st_ino, сведения_файла.st_size, сведения_файла.st_mtime_ns, сведения_файла.st_ctime_ns)
        требовать(метка(до) == метка(после) == метка(проверяемый_путь.stat()) and len(данные) == до.st_size, 'Приватный файл изменился при чтении')
    return данные
