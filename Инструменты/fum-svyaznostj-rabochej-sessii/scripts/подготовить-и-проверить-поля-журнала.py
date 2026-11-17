#!/usr/bin/env python3
"""Обновить открытый служебный блок и проверить поля внутри учтённого запуска."""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import select
import stat
import sys
import time
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[2] /
                       "fum-otchyotyi-o-zapuskakh-proverok/scripts"))
from отчёты_о_запусках_проверок import (
    ОшибкаОтчёта, выполнить_предпросмотр, _тестово_предпросмотреть_active_помощника,
)
from проверка_полей_журнала import проверить


def _тестовый_канал_без_записи(корень: Path) -> None:
    """Synthetic обмен с UNKNOWN; не подтверждает authority и не пишет отчёт."""
    if (not корень.is_absolute() or корень == Path('/private/tmp')
        or not корень.is_relative_to(Path('/private/tmp')) or корень.resolve(strict=True) != корень
        or Path.cwd().resolve(strict=True) != корень):
        raise ОшибкаОтчёта('неверный корень тестового канала')
    текст = os.environ.get('FUM_SYNTHETIC_HELPER_FDS', '')
    части = текст.split(',')
    if len(части) != 5 or any(not часть.isascii() or not часть.isdecimal() for часть in части):
        raise ОшибкаОтчёта('неверные дескрипторы тестового канала')
    номера = [int(часть) for часть in части]
    if any(fd <= 2 or str(fd) != часть for fd, часть in zip(номера, части)) or len(set(номера)) != 5:
        raise ОшибкаОтчёта('коллизия дескрипторов тестового канала')
    вход, выход, rootfd, lockfd, receiptfd = номера
    if os.getuid() != os.geteuid():
        raise ОшибкаОтчёта('неверный владелец тестового канала')
    for fd, режим in ((вход, os.O_RDONLY), (выход, os.O_WRONLY)):
        данные = os.fstat(fd)
        if (not stat.S_ISFIFO(данные.st_mode) or данные.st_uid != os.geteuid()
            or fcntl.fcntl(fd, fcntl.F_GETFL) & os.O_ACCMODE != режим):
            raise ОшибкаОтчёта('неверный тип тестового канала')
    метки = []
    for fd in (rootfd, lockfd, receiptfd):
        данные = os.fstat(fd)
        if (not stat.S_ISDIR(данные.st_mode) or данные.st_uid != os.geteuid()
            or stat.S_IMODE(данные.st_mode) != 0o700
            or fcntl.fcntl(fd, fcntl.F_GETFL) & os.O_ACCMODE != os.O_RDONLY):
            raise ОшибкаОтчёта('неверная опора тестового канала')
        метки.append((данные.st_dev, данные.st_ino))
    именованный = os.stat(корень, follow_symlinks=False)
    if len(set(метки)) != 3 or метки[0] != (именованный.st_dev, именованный.st_ino):
        raise ОшибкаОтчёта('опоры тестового канала не совпадают')
    срок = time.monotonic() + 5.0
    def принять() -> bytes:
        результат = bytearray()
        while len(результат) < 84:
            остаток = срок - time.monotonic()
            if остаток <= 0 or not select.select([вход], [], [], остаток)[0]:
                raise ОшибкаОтчёта('истёк срок тестового кадра')
            часть = os.read(вход, 84 - len(результат))
            if not часть:
                raise ОшибкаОтчёта('неполный тестовый кадр')
            результат.extend(часть)
        return bytes(результат)
    def отправить(байты: bytes) -> None:
        os.set_blocking(выход, False)
        позиция = 0
        while позиция < len(байты):
            остаток = срок - time.monotonic()
            if остаток <= 0 or not select.select([], [выход], [], остаток)[1]:
                raise ОшибкаОтчёта('истёк срок тестового ответа')
            try:
                число = os.write(выход, байты[позиция:])
            except BlockingIOError:
                continue
            if число <= 0:
                raise ОшибкаОтчёта('неполный тестовый ответ')
            позиция += число
    hello = принять()
    if hello[:4] != b'FHU1' or hello[36:52] == bytes(16):
        raise ОшибкаОтчёта('неверный HELLO тестового канала')
    intent_fd = os.open('intent.json', os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC, dir_fd=receiptfd)
    try:
        до = os.fstat(intent_fd)
        if (not stat.S_ISREG(до.st_mode) or до.st_uid != os.geteuid() or до.st_nlink != 1
            or stat.S_IMODE(до.st_mode) != 0o600 or not 0 < до.st_size <= 4096):
            raise ОшибкаОтчёта('неверное тестовое намерение')
        raw = os.pread(intent_fd, до.st_size + 1, 0)
        после = os.fstat(intent_fd)
        имя = os.stat('intent.json', dir_fd=receiptfd, follow_symlinks=False)
        if (len(raw) != до.st_size or (до.st_dev, до.st_ino, до.st_size, до.st_mtime_ns, до.st_ctime_ns)
            != (после.st_dev, после.st_ino, после.st_size, после.st_mtime_ns, после.st_ctime_ns)
            or (имя.st_dev, имя.st_ino) != (до.st_dev, до.st_ino)
            or hashlib.sha256(raw).digest() != hello[52:84]):
            raise ОшибкаОтчёта('тестовое намерение изменилось')
    finally:
        os.close(intent_fd)
    def без_повторов(пары):
        объект = {}
        for ключ, значение in пары:
            if ключ in объект:
                raise ValueError('повтор поля')
            объект[ключ] = значение
        return объект
    значение = json.loads(raw.decode('utf-8'), object_pairs_hook=без_повторов)
    if (type(значение) is not dict or set(значение) != {'schema', 'state', 'run', 'generation', 'grant_sha256'}
        or значение['schema'] != 'fum.test-helper-intent.1' or значение['state'] != 'UNKNOWN'
        or type(значение['grant_sha256']) is not str or len(значение['grant_sha256']) != 64
        or any(символ not in '0123456789abcdef' for символ in значение['grant_sha256'])
        or type(значение['run']) is not str or type(значение['generation']) is not str
        or str(uuid.UUID(значение['run'])) != значение['run']
        or str(uuid.UUID(значение['generation'])) != значение['generation']
        or uuid.UUID(значение['run']).bytes != hello[4:20]
        or uuid.UUID(значение['generation']).bytes != hello[20:36]):
        raise ОшибкаОтчёта('неверное содержимое тестового намерения')
    отправить(b'FHR1' + hello[4:])
    if принять() != b'FHG1' + hello[4:]:
        raise ОшибкаОтчёта('неверный GO тестового канала')
    остаток = срок - time.monotonic()
    if остаток <= 0 or not select.select([вход], [], [], остаток)[0] or os.read(вход, 1) != b'':
        raise ОшибкаОтчёта('тестовый канал не завершён после GO')
    отправить(b'FHX1' + hello[4:])


def выполнить() -> int:
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", type=Path, required=True)
    разбор.add_argument("--запрос", type=Path, required=True)
    разбор.add_argument("--каталог-замка", type=Path)
    разбор.add_argument("--тестовый-каталог-нового-замка", type=Path)
    разбор.add_argument("--тестовый-active")
    разбор.add_argument("--тестовые-опоры", nargs=4, type=int)
    разбор.add_argument("--тестовый-канал-без-записи", action="store_true")
    аргументы = разбор.parse_args()
    try:
        if аргументы.тестовый_канал_без_записи:
            if any(значение is not None for значение in (аргументы.каталог_замка,
                аргументы.тестовый_каталог_нового_замка, аргументы.тестовый_active, аргументы.тестовые_опоры)):
                raise ОшибкаОтчёта('тестовый канал не принимает bridge параметры')
            _тестовый_канал_без_записи(аргументы.корень)
            print(json.dumps({'схема': 'fum.test-helper-channel.1', 'состояние': 'UNKNOWN'}, ensure_ascii=False))
            return 3
        опытные = (аргументы.тестовый_каталог_нового_замка,
                   аргументы.тестовый_active, аргументы.тестовые_опоры)
        if any(значение is not None for значение in опытные):
            if аргументы.каталог_замка is None or any(значение is None for значение in опытные):
                raise ОшибкаОтчёта('опытный active требует все параметры опор')
            числа = аргументы.тестовые_опоры
            _тестово_предпросмотреть_active_помощника(
                аргументы.корень, аргументы.запрос, аргументы.каталог_замка,
                аргументы.тестовый_каталог_нового_замка, аргументы.тестовый_active,
                ((числа[0], числа[1]), (числа[2], числа[3])))
        else:
            выполнить_предпросмотр(аргументы.корень, аргументы.запрос,
                                 каталог_замка=аргументы.каталог_замка)
        результат = проверить(аргументы.корень, аргументы.запрос)
    except (ОшибкаОтчёта, OSError, ValueError, RuntimeError) as ошибка:
        print(json.dumps({"схема": "fum.поля-журнала.1", "полная_приёмка": False,
                          "ошибки": [('тестовый канал не подтверждён'
                                      if аргументы.тестовый_канал_без_записи else str(ошибка))],
                          "входы": []}, ensure_ascii=False))
        return 2
    print(json.dumps(результат, ensure_ascii=False))
    return 1 if результат["ошибки"] else 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
