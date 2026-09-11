"""Узкий переход службы собственной VM; ввод формирует подписанный Swift-инструмент."""
import json
import fcntl
import os
from pathlib import Path
import stat
import subprocess
import uuid


def проверить_путь(путь, корень):
    for предок in [путь, *путь.parents]:
        if предок.is_symlink(): raise ValueError('Символическая ссылка в пути гостевой службы')
        if предок == корень: return
    raise ValueError('Путь вышел за гостевой корень')


def прочитать(путь, корень):
    проверить_путь(путь, корень)
    try:
        файл = os.open(путь, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC)
    except FileNotFoundError:
        return None
    try:
        сведения = os.fstat(файл)
        if (not stat.S_ISREG(сведения.st_mode) or сведения.st_uid != os.geteuid()
                or сведения.st_nlink != 1 or сведения.st_size > 1024 * 1024):
            raise ValueError('Небезопасный файл гостевой службы')
        байты = os.read(файл, 1024 * 1024 + 1)
        if len(байты) > 1024 * 1024: raise ValueError('Файл гостевой службы слишком велик')
        return байты.decode('utf-8')
    finally:
        os.close(файл)


def сохранить(путь, данные, режим):
    временный = путь.with_name('.fum-' + str(uuid.uuid4()))
    файл = os.open(временный, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC, режим)
    try:
        байты = данные.encode()
        while байты:
            число = os.write(файл, байты)
            if число <= 0: raise OSError('Гостевой файл не записан')
            байты = байты[число:]
        os.fchmod(файл, режим); os.fsync(файл)
    finally:
        os.close(файл)
    os.replace(временный, путь)
    каталог = os.open(путь.parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try: os.fsync(каталог)
    finally: os.close(каталог)


def системная_команда(аргументы):
    результат = subprocess.run(аргументы, check=True, timeout=30, stdin=subprocess.DEVNULL,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if len(результат.stdout) > 1024 * 1024: raise ValueError('Слишком большой ответ systemd')
    return результат.stdout.decode('utf-8')


def проверить_входы(данные, корень):
    корень = Path(корень)
    if str(uuid.UUID(данные['машина'])) != данные['машина']:
        raise ValueError('Неверный идентификатор VM')
    if set(данные['файлы']) != {'fum-vsock.socket', 'fum-vsock.service'}:
        raise ValueError('Восстановление ограничено двумя собственными units')
    if (прочитать(корень / 'etc/fum-vm-id', корень) or '').strip() != данные['машина']:
        raise ValueError('Подключена другая VM; изменения запрещены')
    if корень == Path('/'):
        if os.geteuid() != 0: raise ValueError('Восстановление требует root только в своём госте')
        if not os.access('/usr/lib/systemd/systemd-socket-proxyd', os.X_OK):
            raise ValueError('В закреплённом госте отсутствует системный прокси')
    каталог = корень / 'etc/systemd/system'
    прежние = {}
    for имя, новое in данные['файлы'].items():
        if not isinstance(новое, str) or not новое or len(новое.encode()) > 65536:
            raise ValueError('Неверное содержимое собственной службы')
        прежнее = прочитать(каталог / имя, корень)
        допустимые = (None, новое, данные['прежняя_служба']) if имя.endswith('.service') else (None, новое)
        if прежнее not in допустимые: raise ValueError('Собственная служба изменена пользователем; восстановление остановлено')
        прежние[имя] = прежнее
    return прежние


def проверить_надстройки(корень, выполнить):
    ответ = выполнить(['/usr/bin/systemctl', 'show', '--property=UnitPath', '--value'])
    if not isinstance(ответ, str) or not ответ.strip(): raise ValueError('Не получены пути поиска systemd')
    пути = ответ.split()
    for имя_пути in пути:
        относительный = Path(имя_пути)
        if not относительный.is_absolute() or '..' in относительный.parts:
            raise ValueError('Неизвестный путь поиска systemd')
        папка = корень / относительный.relative_to('/')
        проверить_путь(папка, корень)
        for имя in ('fum-vsock.service', 'fum-vsock.socket'):
            адрес = папка / имя
            if папка != корень / 'etc/systemd/system' and os.path.lexists(адрес):
                raise ValueError('Найдена альтернативная служба вне собственного пути')
            for суффикс in ('.d', '.wants', '.requires', '.upholds'):
                if os.path.lexists(папка / (имя + суффикс)):
                    raise ValueError('Найдена дополнительная настройка собственной службы')
        for имя in ('fum-.service.d', 'fum-.socket.d', 'service.d', 'socket.d'):
            if os.path.lexists(папка / имя): raise ValueError('Найдена общая надстройка службы')


def восстановить(данные, *, корень=Path('/'), выполнить=системная_команда):
    корень = Path(корень)
    проверить_входы(данные, корень)
    проверить_надстройки(корень, выполнить)
    путь = корень / 'run/lock/fum-vsock.lock'
    проверить_путь(путь, корень)
    замок = os.open(путь, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC, 0o600)
    try:
        сведения = os.fstat(замок)
        if (not stat.S_ISREG(сведения.st_mode) or сведения.st_nlink != 1
                or сведения.st_uid != os.geteuid() or сведения.st_mode & 0o077):
            raise ValueError('Небезопасный замок восстановления гостя')
        try: fcntl.flock(замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as ошибка: raise ValueError('Восстановление гостя уже выполняется') from ошибка
        return применить_переход(данные, корень, выполнить)
    finally: os.close(замок)


def применить_переход(данные, корень, выполнить):
    прежние = проверить_входы(данные, корень)
    проверить_надстройки(корень, выполнить)
    каталог = корень / 'etc/systemd/system'
    изменённые = [имя for имя in прежние if прежние[имя] != данные['файлы'][имя]]
    if изменённые:
        резерв = корень / 'var/lib/fum-vm' / str(uuid.uuid4())
        проверить_путь(резерв, корень)
        резерв.mkdir(parents=True, mode=0o700)
        for имя, текст in прежние.items():
            if текст is not None: сохранить(резерв / имя, текст, 0o600)
        сохранить(резерв / 'переход.json', json.dumps({'схема': 'fum.восстановление-гостя.1',
            'машина': данные['машина'], 'этап': 'резерв сохранён', 'файлы': изменённые}, ensure_ascii=False) + '\n', 0o600)
        # Останавливается только проверенная собственная старая служба, а не sshd.
        if прежние['fum-vsock.service'] is not None:
            выполнить(['/usr/bin/systemctl', 'stop', 'fum-vsock.service'])
        if прежние['fum-vsock.service'] == данные['прежняя_служба']:
            выполнить(['/usr/bin/systemctl', 'disable', 'fum-vsock.service'])
        for имя in изменённые: сохранить(каталог / имя, данные['файлы'][имя], 0o644)
    выполнить(['/usr/bin/systemctl', 'daemon-reload'])
    проверить_надстройки(корень, выполнить)
    выполнить(['/usr/bin/systemctl', 'enable', '--now', 'fum-vsock.socket'])
    выполнить(['/usr/bin/systemctl', 'is-active', '--quiet', 'fum-vsock.socket'])
    return {'схема': 'fum.восстановление-гостя.1', 'машина': данные['машина'],
            'изменены': изменённые, 'результат': 'сокет запущен; сквозной SSH проверяется отдельно'}
