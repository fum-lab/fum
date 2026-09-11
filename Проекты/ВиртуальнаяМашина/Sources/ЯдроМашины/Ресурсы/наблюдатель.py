"""Одна команда под наблюдением отдельного Python-процесса.

Запуск: python3 -I -S -B наблюдатель.py --описание N --жизнь N --замок N
    --каталог N --вход N --вывод N --ошибки N
Вместо пути ресурса допустимы -c и его точные байты; __file__ не используется.
Передаются семь различных FD >= 3 через pass_fds; только родитель держит
пишущий конец канала жизни. Конфигурация, stdin и приёмники вывода — личные
обычные различные файлы; конфигурация и stdin читаются, stdin начинается
с нулевого смещения; приёмники пусты, доступны для записи без O_APPEND.
Родитель больше не меняет эти файлы. Каталог содержит уже захваченный
flock-файл «замок». Все переданные FD, кроме stdin, закрыты в команде.

Закрытая схема fum.наблюдатель-команды.1: идентификатор, родитель, проверка
(канонические UUID), исходник (SHA-256), аргументы (массив), каталог (cwd),
среда (объект), срок_нс (абсолютный time.monotonic_ns в текущем запуске ОС),
предел_вывода (на каждый поток, 1..32 MiB), завершение_нс (1 ms..2 s).
Родитель до запуска сохраняет свой манифест и включает байты этого ресурса
в происхождение. Для Python macOS нужны os.waitid/WNOWAIT (Python >= 3.13).

Код 0 означает установленную квитанцию, а не успех команды: вызывающий
обязан проверить её исход, код и происхождение. Повтор UUID отвергается.
Файлы наблюдатель-UUID-начало/конец.json не заменяют фазы гостевых метрик.
Наблюдатель не запускает повтор и не удаляет незавершённую поставку/клон.
CLI закрывает свою копию flock последней; LOCK_UN не применяется. Поля
сигнал_TERM/KILL означают попытки: исчезновение группы проверяется отдельно.

Граница: процессы, ушедшие из PGID, смерть самого наблюдателя/SIGKILL,
отказ носителя и непрерываемый ввод-вывод не покрыты. Пока группа ещё
существует после SIGKILL, наблюдатель удерживает lock и ждёт её исчезновения.
Исторические PID не читаются для сигналов. Swift fork/preexec_fn не нужны.
"""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import selectors
import signal
import stat
import subprocess
import time
import uuid


def кодировать(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()


def записать_всё(дескриптор, байты):
    while байты:
        число = os.write(дескриптор, байты)
        if число <= 0: raise OSError('Короткая запись свидетельства')
        байты = байты[число:]


def установить(каталог, имя, данные, *, начальное=False):
    временное = имя if начальное else '.наблюдатель-' + str(uuid.uuid4())
    файл = os.open(временное, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC,
                    0o600, dir_fd=каталог)
    try:
        записать_всё(файл, кодировать(данные)); os.fsync(файл)
    finally: os.close(файл)
    if not начальное:
        os.link(временное, имя, src_dir_fd=каталог, dst_dir_fd=каталог, follow_symlinks=False)
        os.unlink(временное, dir_fd=каталог)
    os.fsync(каталог)


def личный_файл(номер):
    сведения = os.fstat(номер)
    if (not stat.S_ISREG(сведения.st_mode) or сведения.st_uid != os.getuid()
            or сведения.st_nlink > 1 or сведения.st_mode & 0o077):
        raise ValueError('Требуется личный обычный дескриптор')
    return сведения


def разобрать(описание):
    if личный_файл(описание).st_size > 65536: raise ValueError('Конфигурация превышает 64 KiB')
    байты = os.pread(описание, 65537, 0)
    if len(байты) > 65536: raise ValueError('Конфигурация выросла')
    def объект(пары):
        результат = {}
        for имя, значение in пары:
            if имя in результат: raise ValueError('Повтор поля конфигурации')
            результат[имя] = значение
        return результат
    данные = json.loads(байты, object_pairs_hook=объект)
    поля = {'схема', 'идентификатор', 'родитель', 'проверка', 'исходник', 'аргументы',
            'каталог', 'среда', 'срок_нс', 'предел_вывода', 'завершение_нс'}
    if not isinstance(данные, dict) or set(данные) != поля or данные['схема'] != 'fum.наблюдатель-команды.1':
        raise ValueError('Неизвестная схема наблюдателя')
    for имя in ('идентификатор', 'родитель', 'проверка'):
        if not isinstance(данные[имя], str) or str(uuid.UUID(данные[имя])) != данные[имя]:
            raise ValueError('Нужен канонический UUID')
    источник = данные['исходник']
    if not isinstance(источник, str) or len(источник) != 64 or any(буква not in '0123456789abcdef' for буква in источник):
        raise ValueError('Неверное происхождение команды')
    аргументы = данные['аргументы']
    if (not isinstance(аргументы, list) or not аргументы or len(аргументы) > 256
            or any(not isinstance(часть, str) or '\0' in часть for часть in аргументы)
            or not os.path.isabs(аргументы[0])):
        raise ValueError('Нужен точный массив аргументов с абсолютной программой')
    каталог = данные['каталог']
    if not isinstance(каталог, str) or not os.path.isabs(каталог) or Path(каталог).resolve() != Path(каталог):
        raise ValueError('Нужен физический абсолютный cwd')
    среда = данные['среда']
    if (not isinstance(среда, dict) or any(not isinstance(значение, str) or '\0' in ключ + значение
            or '=' in ключ or not ключ for ключ, значение in среда.items())):
        raise ValueError('Неверная среда команды')
    for имя, нижняя, верхняя in [('срок_нс', 1, 2**63 - 1), ('предел_вывода', 1, 32 * 1024**2),
                                ('завершение_нс', 1_000_000, 2_000_000_000)]:
        if type(данные[имя]) is not int or not нижняя <= данные[имя] <= верхняя:
            raise ValueError('Неверный предел наблюдателя')
    return данные, hashlib.sha256(байты).hexdigest()


def проверить_дескрипторы(параметры):
    if len(set(параметры.values())) != 7 or any(номер < 3 for номер in параметры.values()):
        raise ValueError('Нужны семь различных дескрипторов вне стандартных потоков')
    for номер in параметры.values(): os.set_inheritable(номер, False)
    файлы = {}
    for имя in ('описание', 'замок', 'вход', 'вывод', 'ошибки'):
        файлы[имя] = личный_файл(параметры[имя])
    if len({(сведения.st_dev, сведения.st_ino) for сведения in файлы.values()}) != 5:
        raise ValueError('Файлы дескрипторов не должны совпадать')
    for имя in ('описание', 'вход', 'вывод', 'ошибки'):
        номер = параметры[имя]
        флаги = fcntl.fcntl(номер, fcntl.F_GETFL)
        доступ = флаги & os.O_ACCMODE
        if имя in ('описание', 'вход'):
            if доступ == os.O_WRONLY: raise ValueError('Источник недоступен для чтения')
        elif доступ == os.O_RDONLY or флаги & os.O_APPEND or файлы[имя].st_size != 0:
            raise ValueError('Нужен пустой приёмник с записью без дополнения')
        if имя != 'описание' and os.lseek(номер, 0, os.SEEK_CUR) != 0:
            raise ValueError('Начальное смещение потока должно быть нулевым')
    жизнь = параметры['жизнь']
    if not stat.S_ISFIFO(os.fstat(жизнь).st_mode) or fcntl.fcntl(жизнь, fcntl.F_GETFL) & os.O_ACCMODE != os.O_RDONLY:
        raise ValueError('Канал жизни должен быть читающим концом pipe')
    каталог, замок = параметры['каталог'], параметры['замок']
    сведения = os.fstat(каталог)
    if not stat.S_ISDIR(сведения.st_mode) or сведения.st_uid != os.getuid() or сведения.st_mode & 0o077:
        raise ValueError('Каталог квитанций должен быть личным')
    проверочный = os.open('замок', os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC, dir_fd=каталог)
    try:
        свой, иной = os.fstat(замок), os.fstat(проверочный)
        if (свой.st_dev, свой.st_ino, свой.st_nlink) != (иной.st_dev, иной.st_ino, 1):
            raise ValueError('Передан чужой замок')
        try: fcntl.flock(проверочный, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError: pass
        else: raise ValueError('Замок не захвачен родителем')
        fcntl.flock(замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
    finally: os.close(проверочный)
    if not all(hasattr(os, имя) for имя in ('waitid', 'WNOWAIT', 'WEXITED', 'WNOHANG')):
        raise ValueError('Нужен Python с waitid/WNOWAIT; на macOS версия не ниже 3.13')


def наблюдать(**параметры):
    """Исполнить CLI-контракт; переданные FD закрывает главная()."""
    проверить_дескрипторы(параметры)
    каталог = параметры['каталог']
    данные, отпечаток = разобрать(параметры['описание'])
    основа = {ключ: данные[ключ] for ключ in ('идентификатор', 'родитель', 'проверка', 'исходник')}
    основа['описание_sha256'] = отпечаток
    имя = 'наблюдатель-' + данные['идентификатор']
    # Начало резервирует UUID до запуска; старые UUID и незавершённые попытки не повторяются.
    try: os.stat(имя + '-конец.json', dir_fd=каталог, follow_symlinks=False)
    except FileNotFoundError: pass
    else: raise ValueError('UUID уже имеет конечную квитанцию')
    установить(каталог, имя + '-начало.json', {**основа, 'схема': 'fum.начало-наблюдателя.1'}, начальное=True)
    начало = time.monotonic_ns()
    жизнь = параметры['жизнь']; os.set_blocking(жизнь, False)
    отмена = [None]
    def сигнал(номер, кадр): отмена[0] = 'сигнал_наблюдателя'
    for номер in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP): signal.signal(номер, сигнал)
    def причина_остановки():
        try:
            байты = os.read(жизнь, 1)
            return 'родитель_исчез' if not байты else 'протокол_жизни'
        except BlockingIOError: pass
        if отмена[0]: return отмена[0]
        if time.monotonic_ns() >= данные['срок_нс']: return 'срок'
        return None
    процесс = None; причина = причина_остановки(); мягкое = жёсткое = False
    счётчики = {'вывод': 0, 'ошибки': 0}
    записано = {'вывод': 0, 'ошибки': 0}
    выбор = selectors.DefaultSelector()
    def сигнал_группе(номер):
        try: os.killpg(процесс.pid, номер)
        except ProcessLookupError: pass
        except PermissionError:
            # Darwin возвращает EPERM и для группы из одних zombie. Это не
            # свидетельство очистки: ниже обязательны wait и исчезновение PGID.
            # При живом недоступном процессе wait удерживает замок без квитанции.
            pass
    def читать_вывод(задержка):
        nonlocal причина
        for ключ, _ in выбор.select(задержка):
            поток, вид = ключ.fileobj, ключ.data
            блок = os.read(поток.fileno(), 65536)
            if not блок:
                выбор.unregister(поток); поток.close(); continue
            счётчики[вид] += len(блок)
            остаток = max(0, данные['предел_вывода'] - записано[вид])
            записать_всё(параметры[вид], блок[:остаток]); записано[вид] += min(остаток, len(блок))
            if счётчики[вид] > данные['предел_вывода'] and причина in (None, 'завершение'): причина = 'вывод'
    try:
        if причина is None:
            процесс = subprocess.Popen(данные['аргументы'], cwd=данные['каталог'], env=данные['среда'],
                stdin=параметры['вход'], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                close_fds=True, start_new_session=True)
            for поток, вид in ((процесс.stdout, 'вывод'), (процесс.stderr, 'ошибки')):
                os.set_blocking(поток.fileno(), False); выбор.register(поток, selectors.EVENT_READ, вид)
            конец_мягкого = None
            while True:
                читать_вывод(0)
                причина = причина or причина_остановки()
                # Не использовать poll(): он забирает zombie и освобождает PID до последнего сигнала.
                состояние = os.waitid(os.P_PID, процесс.pid, os.WEXITED | os.WNOHANG | os.WNOWAIT)
                причина = причина or причина_остановки()
                if причина is None and состояние is not None:
                    причина = 'завершение'
                    сигнал_группе(signal.SIGKILL); жёсткое = True; break
                if причина is not None and конец_мягкого is None:
                    сигнал_группе(signal.SIGTERM); мягкое = True
                    конец_мягкого = time.monotonic_ns() + данные['завершение_нс']
                if конец_мягкого is not None and time.monotonic_ns() >= конец_мягкого:
                    сигнал_группе(signal.SIGKILL); жёсткое = True; break
                читать_вывод(0.01)
    except BaseException:
        причина = причина or 'ошибка_наблюдателя'
        if процесс is not None:
            сигнал_группе(signal.SIGTERM); мягкое = True
            time.sleep(данные['завершение_нс'] / 1e9)
            сигнал_группе(signal.SIGKILL); жёсткое = True
    finally:
        if процесс is not None:
            процесс.wait()  # Последний сигнал уже отправлен: теперь разрешено забрать статус.
            конец_чтения = time.monotonic() + 1
            try:
                while выбор.get_map() and time.monotonic() < конец_чтения: читать_вывод(0.01)
                if выбор.get_map(): причина = 'канал_не_закрыт'
            except OSError:
                причина = 'ошибка_вывода'
            # После wait допускается только наблюдение: по освобождённому PID сигналы не посылаются.
            while True:
                try: os.killpg(процесс.pid, 0)
                except ProcessLookupError: break
                except PermissionError: pass  # Не подтверждает исчезновение.
                time.sleep(0.02)
        for ключ in list(выбор.get_map().values()): ключ.fileobj.close()
        выбор.close()
    for вид in ('вывод', 'ошибки'): os.fsync(параметры[вид])
    код = None if процесс is None else процесс.returncode
    итог = {**основа, 'схема': 'fum.квитанция-наблюдателя.1', 'причина': причина,
        'исход': 'успех' if причина == 'завершение' and код == 0 else 'ошибка',
        'код_команды': код, 'длительность_нс': time.monotonic_ns() - начало,
        'вывод_байт': счётчики['вывод'], 'ошибки_байт': счётчики['ошибки'],
        'сигнал_TERM': мягкое, 'сигнал_KILL': жёсткое, 'группа_исчезла': True}
    установить(каталог, имя + '-конец.json', итог)
    return итог


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    for имя in ('описание', 'жизнь', 'замок', 'каталог', 'вход', 'вывод', 'ошибки'):
        разбор.add_argument('--' + имя, type=int, required=True)
    параметры = vars(разбор.parse_args())
    try:
        наблюдать(**параметры)
        return 0
    except (OSError, ValueError, TypeError) as ошибка:
        os.write(2, ('Наблюдение не подтверждено: ' + str(ошибка) + '\n').encode())
        return 125
    finally:
        # Не LOCK_UN: дескриптор ссылается на то же владение, что и родитель.
        порядок = [значение for имя, значение in параметры.items() if имя != 'замок'] + [параметры['замок']]
        for номер in dict.fromkeys(порядок):
            if номер >= 3:
                try: os.close(номер)
                except OSError: pass


if __name__ == '__main__': raise SystemExit(главная())
