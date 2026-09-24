"""Дописать только назначенный временный префикс и атомарно установить файл."""
import hashlib
import os
from pathlib import Path
import stat

КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()

import эпизод_приёма as эпизод

хранение = эпизод.хранение


def проверить(путь, ожидаемые):
    хранение.безопасный_путь(путь)
    if not os.path.lexists(путь):
        return None
    with os.fdopen(os.open(путь, os.O_RDONLY | os.O_NOFOLLOW), 'rb') as поток:
        состояние = os.fstat(поток.fileno())
        хранение.требовать(stat.S_ISREG(состояние.st_mode) and состояние.st_nlink == 1
            and состояние.st_uid == os.getuid() and stat.S_IMODE(состояние.st_mode) in {0o600, 0o644}
            and состояние.st_size <= len(ожидаемые), 'Неподдержанный временный файл Журнала')
        данные = поток.read()
    хранение.требовать(ожидаемые.startswith(данные), 'Временный файл содержит чужие байты')
    return данные


def установить(путь, временный, данные, режим):
    хранение.требовать(type(режим) is int and режим == 0o644, 'Нужен режим пары 0644')
    хранение.безопасный_путь(путь)
    хранение.требовать(not os.path.lexists(путь), 'Целевой файл уже существует')
    прежние = проверить(временный, данные)
    флаги = os.O_RDWR | os.O_NOFOLLOW
    if прежние is None:
        флаги |= os.O_CREAT | os.O_EXCL
    with os.fdopen(os.open(временный, флаги, 0o600), 'r+b') as поток:
        состояние = os.fstat(поток.fileno())
        хранение.требовать(stat.S_ISREG(состояние.st_mode) and состояние.st_nlink == 1
            and состояние.st_uid == os.getuid(), 'Временный файл подменён до записи')
        существующие = поток.read()
        хранение.требовать(существующие == (прежние or b'') and данные.startswith(существующие),
            'Временный префикс изменился до записи')
        поток.write(данные[len(существующие):])
        os.fchmod(поток.fileno(), режим)
        поток.flush()
        os.fsync(поток.fileno())
    хранение.требовать(not os.path.lexists(путь), 'Целевой файл возник до замены')
    os.replace(временный, путь)
    хранение.синхронизировать_каталог(путь.parent)
