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
import threading
import time
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[2] /
                       "fum-otchyotyi-o-zapuskakh-proverok/scripts"))
from отчёты_о_запусках_проверок import (
    ОшибкаОтчёта, выполнить_предпросмотр, _тестово_предпросмотреть_active_помощника,
    _ТестоваяСверкаЗаписиПомощника, _тестово_предпросмотреть_собственный_active,
)
from проверка_полей_журнала import проверить


def _тестовый_канал_без_записи(корень: Path, *, запрос: Path | None = None) -> bool:
    """Synthetic обмен с UNKNOWN; не подтверждает authority и не пишет отчёт."""
    if (not корень.is_absolute() or корень == Path('/private/tmp')
        or not корень.is_relative_to(Path('/private/tmp')) or корень.resolve(strict=True) != корень
        or Path.cwd().resolve(strict=True) != корень):
        raise ОшибкаОтчёта('неверный корень тестового канала')
    текст = os.environ.get('FUM_SYNTHETIC_HELPER_FDS', '')
    части = текст.split(',')
    с_записью = запрос is not None
    if len(части) != (7 if с_записью else 5) or any(not часть.isascii() or not часть.isdecimal() for часть in части):
        raise ОшибкаОтчёта('неверные дескрипторы тестового канала')
    номера = [int(часть) for часть in части]
    if any(fd <= 2 or str(fd) != часть for fd, часть in zip(номера, части)) or len(set(номера)) != len(номера):
        raise ОшибкаОтчёта('коллизия дескрипторов тестового канала')
    вход, выход, rootfd, lockfd, receiptfd = номера[:5]
    if os.getuid() != os.geteuid():
        raise ОшибкаОтчёта('неверный владелец тестового канала')
    for fd, режим in ((вход, os.O_RDONLY), (выход, os.O_WRONLY)):
        данные = os.fstat(fd)
        if (not stat.S_ISFIFO(данные.st_mode) or данные.st_uid != os.geteuid()
            or fcntl.fcntl(fd, fcntl.F_GETFL) & os.O_ACCMODE != режим):
            raise ОшибкаОтчёта('неверный тип тестового канала')
    метки = []
    for fd in номера[2:]:
        данные = os.fstat(fd)
        if (not stat.S_ISDIR(данные.st_mode) or данные.st_uid != os.geteuid()
            or stat.S_IMODE(данные.st_mode) != 0o700
            or fcntl.fcntl(fd, fcntl.F_GETFL) & os.O_ACCMODE != os.O_RDONLY):
            raise ОшибкаОтчёта('неверная опора тестового канала')
        метки.append((данные.st_dev, данные.st_ino))
    именованный = os.stat(корень, follow_symlinks=False)
    if len(set(метки)) != len(метки) or метки[0] != (именованный.st_dev, именованный.st_ino):
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
    if с_записью:
        # Синтетический issuer и его custody являются внешними предпосылками.
        for fd in номера:
            флаги_fd = fcntl.fcntl(fd, fcntl.F_GETFD)
            fcntl.fcntl(fd, fcntl.F_SETFD, флаги_fd | fcntl.FD_CLOEXEC)
        сверка = _ТестоваяСверкаЗаписиПомощника(
            корень, rootfd, lockfd, receiptfd, значение['grant_sha256'], _мосты=tuple(номера[5:]))
        сверка._канальное_намерение = (сверка._метка_файла(до), raw)
        authority = сверка._запись
        if (authority['schema'] != 'fum.test-helper-authority.2'
            or authority['run'] != значение['run'] or authority['generation'] != значение['generation']
            or authority['nonce_sha256'] != hashlib.sha256(hello[36:52]).hexdigest()
            or authority['session'] != запрос.as_posix()):
            raise ОшибкаОтчёта('канал не совпадает с synthetic намерением')
        метка = authority['lock']
        root_селектор = ('fum.test-lock-root.2', authority['lock_path'], *метка,
                         'controlled-own.1', str(корень))
        def селектор(ключ):
            роль = authority[ключ]
            return ('fum.test-lock-root.2', роль['path'], *роль['identity'], authority['session'], str(корень))
        мост = ('fum.test-lock-bridge.1', селектор('session_lock'), номера[5],
                селектор('bridge_lock'), номера[6])
        опоры = tuple(tuple(authority[ключ]['lock_identity']) for ключ in ('session_lock', 'bridge_lock'))
        срок_записи = authority['deadline_ns'] / 1_000_000_000
        попытка_использования = False
        try:
            попытка_использования = True
            имя = 'used-' + authority['run'] + '.json'
            fd = os.open(имя, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC,
                         0o600, dir_fd=receiptfd)
            used = (json.dumps({'schema': 'fum.test-helper-used.1', 'state': 'UNKNOWN',
                                'run': authority['run'], 'generation': authority['generation'],
                                'authority_sha256': значение['grant_sha256']},
                               sort_keys=True, separators=(',', ':')) + '\n').encode('ascii')
            if os.write(fd, used) != len(used):
                raise ОшибкаОтчёта('неполная квитанция synthetic использования')
            os.fsync(fd)
            создан = os.fstat(fd)
            def идентичность(st):
                return (st.st_dev, st.st_ino, st.st_uid, st.st_mode, st.st_nlink, st.st_size,
                        st.st_mtime_ns, st.st_ctime_ns)
            if (not stat.S_ISREG(создан.st_mode) or создан.st_uid != os.geteuid() or создан.st_nlink != 1
                or stat.S_IMODE(создан.st_mode) != 0o600 or создан.st_size != len(used)):
                raise ОшибкаОтчёта('неверная созданная synthetic квитанция')
            os.close(fd)
            os.fsync(receiptfd)
            прочитать = os.open(имя, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC, dir_fd=receiptfd)
            try:
                st = os.fstat(прочитать)
                if (not stat.S_ISREG(st.st_mode) or st.st_uid != os.geteuid() or st.st_nlink != 1
                    or stat.S_IMODE(st.st_mode) != 0o600 or st.st_size != len(used)
                    or идентичность(st) != идентичность(создан)
                    or os.read(прочитать, len(used) + 1) != used
                    or идентичность(os.fstat(прочитать)) != идентичность(создан)
                    or идентичность(os.stat(имя, dir_fd=receiptfd, follow_symlinks=False)) != идентичность(создан)):
                    raise ОшибкаОтчёта('квитанция synthetic использования не совпадает')
            finally:
                os.close(прочитать)
            сверка._использование = (имя, сверка._метка_файла(создан), used)
            _тестово_предпросмотреть_собственный_active(сверка, root_селектор, мост, опоры, срок_записи)
            отправить(b'FHX1' + hello[4:])
            print(json.dumps({'схема': 'fum.test-helper-channel.1', 'состояние': 'UNKNOWN'},
                             ensure_ascii=False), flush=True)
        except BaseException:
            if попытка_использования:
                try:
                    print('state=UNKNOWN HOLD', file=sys.stderr, flush=True)
                finally:
                    threading.Event().wait()
            raise
        return True
    отправить(b'FHX1' + hello[4:])
    return False


def выполнить() -> int:
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень", type=Path, required=True)
    разбор.add_argument("--запрос", type=Path, required=True)
    разбор.add_argument("--каталог-замка", type=Path)
    разбор.add_argument("--тестовый-каталог-нового-замка", type=Path)
    разбор.add_argument("--тестовый-active")
    разбор.add_argument("--тестовые-опоры", nargs=4, type=int)
    разбор.add_argument("--тестовый-канал-без-записи", action="store_true")
    разбор.add_argument("--тестовый-канал-с-записью", action="store_true")
    аргументы = разбор.parse_args()
    try:
        if аргументы.тестовый_канал_без_записи or аргументы.тестовый_канал_с_записью:
            if аргументы.тестовый_канал_без_записи and аргументы.тестовый_канал_с_записью:
                raise ОшибкаОтчёта('тестовые режимы несовместимы')
            if any(значение is not None for значение in (аргументы.каталог_замка,
                аргументы.тестовый_каталог_нового_замка, аргументы.тестовый_active, аргументы.тестовые_опоры)):
                raise ОшибкаОтчёта('тестовый канал не принимает bridge параметры')
            if _тестовый_канал_без_записи(аргументы.корень,
                запрос=аргументы.запрос if аргументы.тестовый_канал_с_записью else None):
                return 3
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
                                      if аргументы.тестовый_канал_без_записи or аргументы.тестовый_канал_с_записью
                                      else str(ошибка))],
                          "входы": []}, ensure_ascii=False))
        return 2
    print(json.dumps(результат, ensure_ascii=False))
    return 1 if результат["ошибки"] else 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
