"""Один полный ответ: точный кадр stdin, приватный файл и долговечный ACK."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import uuid

import захват_вывода as захват

ПРЕДЕЛ = 67108864


def объект(пары):
    результат = {}
    for ключ, значение in пары:
        if ключ in результат:
            raise ValueError('Повтор поля JSON')
        результат[ключ] = значение
    return результат


def прочитать_кадр(поток):
    данные = поток.readline(65537)
    if len(данные) > 65536 or not данные.endswith(b'\n'):
        raise ValueError('Неполный или слишком большой кадр')
    return json.loads(данные.decode('utf-8'), object_pairs_hook=объект)


def проверить_контекст(цикл, задача, запрос):
    if str(uuid.UUID(цикл)) != цикл or str(uuid.UUID(задача)) != задача:
        raise ValueError('Нужны канонические UUID')
    обязательные = {'threadId', 'hostId', 'turnLimit', 'includeOutputs', 'maxOutputCharsPerItem'}
    if not isinstance(запрос, dict) or set(запрос) not in (обязательные, обязательные | {'cursor'}):
        raise ValueError('Неизвестный запрос чтения')
    if (запрос['threadId'] != задача or not isinstance(запрос['hostId'], str)
            or not запрос['hostId'] or запрос['turnLimit'] != 1
            or type(запрос['turnLimit']) is not int or запрос['includeOutputs'] is not True
            or type(запрос['maxOutputCharsPerItem']) is not int
            or not 1 <= запрос['maxOutputCharsPerItem'] <= 16000
            or ('cursor' in запрос and not isinstance(запрос['cursor'], str))):
        raise ValueError('Чужой контекст чтения')


def открыть_корень(каталог):
    каталог = Path(каталог)
    if not каталог.is_absolute() or any(часть in ('.', '..') for часть in каталог.parts):
        raise ValueError('Нужен абсолютный физический каталог')
    ручка = os.open('/', os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        for часть in каталог.parts[1:]:
            следующая = os.open(часть, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=ручка)
            os.close(ручка)
            ручка = следующая
            try:
                os.stat('.git', dir_fd=ручка, follow_symlinks=False)
            except FileNotFoundError:
                pass
            else:
                raise ValueError('Полный ответ хранится вне Git')
        свойства = os.fstat(ручка)
        if свойства.st_uid != os.getuid() or stat.S_IMODE(свойства.st_mode) & 0o077:
            raise ValueError('Нужен собственный приватный каталог')
        return ручка
    except BaseException:
        os.close(ручка)
        raise


def проверить_отсутствие(ручка, имя):
    try:
        os.stat(имя, dir_fd=ручка, follow_symlinks=False)
    except FileNotFoundError:
        return
    raise FileExistsError(имя)


def принять(поток, каталог, цикл, задача, запрос, при_готовности=None):
    проверить_контекст(цикл, задача, запрос)
    ручка = открыть_корень(каталог)
    имя = 'чтение-' + цикл + '.json'
    квитанция = 'чтение-' + цикл + '.ack.json'
    намерение = 'чтение-' + цикл + '.claim.json'
    try:
        проверить_отсутствие(ручка, имя)
        проверить_отсутствие(ручка, квитанция)
        проверить_отсутствие(ручка, намерение)
        исходный_каталог = os.fstat(ручка)
        захват_цикла = os.open(намерение, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                             0o600, dir_fd=ручка)
        try:
            захват.записать(захват_цикла, захват.закодировать({
                'схема': 'fum.намерение-приёма-ответа.1', 'цикл': цикл,
                'задача': задача, 'запрос': запрос, 'файл': str(Path(каталог) / имя)}))
            os.fsync(захват_цикла)
        finally:
            os.close(захват_цикла)
        os.fsync(ручка)
        if при_готовности is not None:
            при_готовности({'схема': 'fum.готовность-приёма-ответа.1', 'цикл': цикл,
                          'задача': задача, 'файл': str(Path(каталог) / имя)})
        заголовок = прочитать_кадр(поток)
        if (not isinstance(заголовок, dict)
                or set(заголовок) != {'схема', 'цикл', 'задача', 'запрос', 'байты', 'sha256'}
                or заголовок['схема'] != 'fum.передача-полного-ответа.1'
                or заголовок['цикл'] != цикл or заголовок['задача'] != задача
                or заголовок['запрос'] != запрос or type(заголовок['байты']) is not int
                or not 1 <= заголовок['байты'] <= ПРЕДЕЛ
                or not isinstance(заголовок['sha256'], str)
                or re.fullmatch('[0-9a-f]{64}', заголовок['sha256']) is None):
            raise ValueError('Недопустимый заголовок полного ответа')
        файл = os.open(имя, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=ручка)
        try:
            хэш = hashlib.sha256()
            осталось = заголовок['байты']
            while осталось:
                блок = поток.read(min(65536, осталось))
                if not блок:
                    raise ValueError('Оборван полный ответ')
                захват.записать(файл, блок)
                хэш.update(блок)
                осталось -= len(блок)
            if поток.read(1) != b'\n':
                raise ValueError('Нет границы завершающего кадра')
            ожидаемый_конец = {ключ: заголовок[ключ] for ключ in ('цикл', 'задача', 'байты', 'sha256')}
            ожидаемый_конец['схема'] = 'fum.конец-полного-ответа.1'
            if прочитать_кадр(поток) != ожидаемый_конец or хэш.hexdigest() != заголовок['sha256']:
                raise ValueError('Не совпали конец или SHA полного ответа')
            os.fsync(файл)
        finally:
            os.close(файл)
        новая_ручка = открыть_корень(каталог)
        try:
            новый_каталог = os.fstat(новая_ручка)
            if (новый_каталог.st_dev, новый_каталог.st_ino) != (исходный_каталог.st_dev, исходный_каталог.st_ino):
                raise ValueError('Подменён каталог полного ответа')
        finally:
            os.close(новая_ручка)
        os.fsync(ручка)
        подтверждение = {'схема': 'fum.ACK-полного-ответа.1', 'цикл': цикл, 'задача': задача,
                        'файл': str(Path(каталог) / имя), 'байты': заголовок['байты'], 'sha256': хэш.hexdigest()}
        выход = os.open(квитанция, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=ручка)
        try:
            захват.записать(выход, захват.закодировать(подтверждение))
            os.fsync(выход)
        finally:
            os.close(выход)
        os.fsync(ручка)
        return подтверждение
    finally:
        os.close(ручка)


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    for имя in ('корень-контейнера', 'цикл', 'задача', 'запрос'):
        разбор.add_argument('--' + имя, required=True)
    параметры = разбор.parse_args()
    try:
        if os.isatty(sys.stdin.fileno()):
            import tty
            tty.setraw(sys.stdin.fileno())
        каталог = Path(параметры.корень_контейнера)
        запрос = json.loads(параметры.запрос, object_pairs_hook=объект)
        def показать_готовность(готовность):
            sys.stdout.buffer.write(захват.закодировать(готовность))
            sys.stdout.buffer.flush()
        подтверждение = принять(sys.stdin.buffer, каталог, параметры.цикл, параметры.задача,
                               запрос, показать_готовность)
        sys.stdout.buffer.write(захват.закодировать(подтверждение)); sys.stdout.buffer.flush()
        return 0
    except (OSError, ValueError, TypeError, KeyError) as ошибка:
        print('Полный ответ не принят: ' + str(ошибка), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(главная())
