"""Проверка Linux: стандартный Python закреплённого образа, без установки Swift в госте."""
import math


def проверить_инициализацию(код, данные):
    if (type(код) is not int or код != 0 or not isinstance(данные, dict)
            or данные.get('status') != 'done' or данные.get('extended_status') != 'done'
            or 'stage' not in данные or данные['stage'] is not None
            or данные.get('boot_status_code') != 'enabled-by-generator'
            or данные.get('datasource') != 'nocloud'
            or данные.get('errors') != [] or данные.get('recoverable_errors') != {}):
        raise ValueError('cloud-init не завершён без ошибок; код процесса сам по себе недостаточен')
    for имя in ('init-local', 'init', 'modules-config', 'modules-final'):
        этап = данные.get(имя)
        if not isinstance(этап, dict) or этап.get('errors') != [] or этап.get('recoverable_errors') != {}:
            raise ValueError('Отсутствует чистый этап cloud-init: ' + имя)
        for поле in ('start', 'finished'):
            число = этап.get(поле)
            if type(число) not in (float, int) or not math.isfinite(число) or число < 0:
                raise ValueError('Неверное время этапа cloud-init: ' + имя)
        if этап['finished'] < этап['start']:
            raise ValueError('Этап cloud-init завершён раньше начала')


def проверить_счётчики(данные, ожидается):
    ожидаемые = {'выполнено': ожидается, 'ошибки': 0, 'отказы': 0, 'пропущено': 0,
                 'ожидаемые_ошибки': 0, 'неожиданные_успехи': 0}
    if (type(ожидается) is not int or ожидается <= 0 or not isinstance(данные, dict)
            or set(данные) != set(ожидаемые)
            or any(type(данные[ключ]) is not int or данные[ключ] != значение
                   for ключ, значение in ожидаемые.items())):
        raise ValueError('Гостевой набор пропущен, неполон или завершился с ошибкой')


import contextlib
import fcntl
import json
import os
from pathlib import Path
import stat


def прочитать_личный_файл(каталог, имя):
    try:
        файл = os.open(имя, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC, dir_fd=каталог)
        try:
            сведения = os.fstat(файл)
            if (not stat.S_ISREG(сведения.st_mode) or сведения.st_uid != os.getuid()
                    or сведения.st_nlink != 1 or сведения.st_mode & 0o077
                    or сведения.st_size > 1024 * 1024):
                raise ValueError('Небезопасный или слишком большой файл состояния гостя')
            байты = bytearray()
            while len(байты) <= 1024 * 1024:
                блок = os.read(файл, min(65536, 1024 * 1024 + 1 - len(байты)))
                if not блок: return bytes(байты)
                байты.extend(блок)
            raise ValueError('Файл состояния гостя вырос за предел')
        finally:
            os.close(файл)
    except OSError as ошибка:
        raise ValueError('Не удалось безопасно прочитать состояние гостя') from ошибка


def записать_новый_файл(каталог, имя, данные):
    байты = json.dumps(данные, ensure_ascii=False, sort_keys=True, indent=2).encode() + b'\n'
    файл = os.open(имя, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC,
                    0o600, dir_fd=каталог)
    try:
        while байты:
            число = os.write(файл, байты)
            if число <= 0: raise OSError('Не записан файл гостя')
            байты = байты[число:]
        os.fsync(файл)
    finally:
        os.close(файл)
    os.fsync(каталог)


def перенести_без_замены(родитель, временное, имя):
    import ctypes
    import sys
    библиотека = ctypes.CDLL(None, use_errno=True)
    if sys.platform == 'linux':
        функция, флаг = библиотека.renameat2, 1
    elif sys.platform == 'darwin':
        # Ветвь только для автономных тестов на Mac; SDK sys/stdio.h RENAME_EXCL.
        функция, флаг = библиотека.renameatx_np, 4
    else:
        raise ValueError('Нет проверенного атомарного переноса каталога без замены')
    функция.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    функция.restype = ctypes.c_int
    if функция(родитель, os.fsencode(временное), родитель, os.fsencode(имя), флаг) != 0:
        код = ctypes.get_errno()
        raise OSError(код, 'Не установлен подготовленный гостевой объект')
    os.fsync(родитель)


def установить_свидетельство(каталог, имя, данные):
    временное = '.fum-proof-' + str(uuid.uuid4())
    записать_новый_файл(каталог, временное, данные)
    перенести_без_замены(каталог, временное, имя)


def установить_каталог(родитель, имя, владелец):
    """Подготовить полную принадлежность до единственной публикации без замены."""
    import errno
    try:
        os.stat(имя, dir_fd=родитель, follow_symlinks=False)
        return
    except FileNotFoundError:
        pass
    временное = '.fum-guest-' + str(uuid.uuid4())
    os.mkdir(временное, mode=0o700, dir_fd=родитель)
    каталог = os.open(временное, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC,
                      dir_fd=родитель)
    try:
        записать_новый_файл(каталог, 'владелец.json', владелец)
        os.fsync(каталог)
    finally:
        os.close(каталог)
    try:
        перенести_без_замены(родитель, временное, имя)
    except OSError as ошибка:
        if ошибка.errno not in (errno.EEXIST, errno.ENOTEMPTY): raise


@contextlib.contextmanager
def область_гостя(путь, владелец, *, создать=True, вернуть_замок=False):
    путь = Path(путь)
    if not путь.is_absolute() or путь == Path('/') or '..' in путь.parts:
        raise ValueError('Нужен абсолютный физический гостевой путь')
    каталог = os.open('/', os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC)
    замок = None
    try:
        for номер, часть in enumerate(путь.parts[1:]):
            try:
                os.stat('.git', dir_fd=каталог, follow_symlinks=False)
            except FileNotFoundError:
                pass
            else:
                raise ValueError('Гостевое состояние нельзя создать внутри Git')
            if создать and номер == len(путь.parts) - 2:
                установить_каталог(каталог, часть, владелец)
            следующий = os.open(часть, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC,
                                dir_fd=каталог)
            os.close(каталог); каталог = следующий
        сведения = os.fstat(каталог)
        if сведения.st_uid != os.getuid() or сведения.st_mode & 0o077:
            raise ValueError('Гостевой каталог не принадлежит текущему пользователю или открыт другим')
        if json.loads(прочитать_личный_файл(каталог, 'владелец.json')) != владелец:
            raise ValueError('Гостевой каталог относится к другому плану или VM')
        замок = os.open('замок', os.O_RDWR | (os.O_CREAT if создать else 0) | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC,
                        0o600, dir_fd=каталог)
        сведения = os.fstat(замок)
        if (not stat.S_ISREG(сведения.st_mode) or сведения.st_nlink != 1
                or сведения.st_uid != os.getuid() or сведения.st_mode & 0o077):
            raise ValueError('Небезопасный замок гостевого каталога')
        fcntl.flock(замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
        yield (каталог, замок) if вернуть_замок else каталог
    except OSError as ошибка:
        raise ValueError('Гостевой каталог занят или не прошёл безопасное открытие') from ошибка
    finally:
        if замок is not None: os.close(замок)
        os.close(каталог)


import hashlib
import uuid


def собрать_измерения(каталог, проверка, источник):
    """Экспортировать неизменяемые файлы одной проверки, не создавая завершений."""
    if str(uuid.UUID(проверка)) != проверка or len(источник) != 64 or any(буква not in '0123456789abcdef' for буква in источник):
        raise ValueError('Неверное происхождение экспорта измерений')
    имена = sorted(имя for имя in os.listdir(каталог) if имя.startswith(('начало-', 'конец-')))
    if len(имена) > 16384: raise ValueError('Экспорт измерений превысил предел числа файлов')
    результат = []; размер = 0
    for имя in имена:
        фаза, идентификатор = имя.split('-', 1)
        идентификатор = идентификатор.removesuffix('.json')
        if not имя.endswith('.json') or str(uuid.UUID(идентификатор)) != идентификатор:
            raise ValueError('Неверное имя файла измерения')
        байты = прочитать_личный_файл(каталог, имя)
        событие = json.loads(байты)
        if not isinstance(событие, dict) or событие.get('идентификатор') != идентификатор:
            raise ValueError('Имя измерения не совпало с содержимым')
        if событие.get('запуск') != проверка: continue
        поля = {'идентификатор', 'родитель', 'операция', 'исход', 'длительностьНс', 'происхождение', 'запуск'}
        if (set(событие) != поля or событие['происхождение'] != источник
                or not isinstance(событие['операция'], str) or not событие['операция']
                or str(uuid.UUID(событие['родитель'])) != событие['родитель']):
            raise ValueError('Измерение относится к другому источнику или повреждено')
        длительность = событие['длительностьНс']
        if фаза == 'начало':
            if событие['исход'] != 'выполняется' or длительность is not None:
                raise ValueError('Начальная фаза измерения повреждена')
        elif событие['исход'] not in ('успех', 'ошибка') or type(длительность) is not int or not 0 <= длительность <= 2**64 - 1:
            raise ValueError('Конечная фаза измерения повреждена')
        запись = {'имя': имя, 'sha256': hashlib.sha256(байты).hexdigest(), 'данные': байты.decode('utf-8')}
        размер += len(json.dumps(запись, ensure_ascii=False).encode())
        if размер > 4 * 1024**2: raise ValueError('Экспорт измерений превысил предел ответа')
        результат.append(запись)
    return результат


def экспортировать_измерения(данные):
    владелец = {'схема': 'fum.область-гостя.1', 'машина': данные['машина'], 'план': данные['план']}
    if Path('/etc/fum-vm-id').read_text().strip() != данные['машина']:
        raise ValueError('Подключена другая VM')
    with область_гостя(Path.home() / '.fum-linux-vm', владелец, создать=False) as каталог:
        пакет = {**владелец, 'схема': 'fum.измерения-гостя.1',
                'проверка': данные['проверка'], 'исходник': данные['исходник'],
                'файлы': собрать_измерения(каталог, данные['проверка'], данные['исходник'])}
        if len(json.dumps(пакет, ensure_ascii=False, sort_keys=True).encode('utf-8')) + 1 > 4 * 1024**2:
            raise ValueError('Полный экспорт измерений превысил предел 4 MiB')
        return пакет

АДРЕС_РЕПОЗИТОРИЯ = 'https://github.com/fum-lab/fum.git'
ТЕКУЩИЕ_МЕТРИКИ = None


def среда_репозитория(прокси=None):
    среда = {'PATH': '/usr/bin:/bin', 'HOME': str(Path.home()), 'LC_ALL': 'C',
             'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null',
             'GIT_NO_REPLACE_OBJECTS': '1',
             'GIT_TERMINAL_PROMPT': '0', 'GIT_OPTIONAL_LOCKS': '0',
             'PYTHONDONTWRITEBYTECODE': '1'}
    if прокси is not None:
        if прокси != 'socks5h://127.0.0.1:1080': raise ValueError('Неизвестный гостевой прокси')
        среда['https_proxy'] = прокси
    return среда


def команда_репозитория(путь, аргументы, среда, предел=180):
    if ТЕКУЩИЕ_МЕТРИКИ is not None:
        return ТЕКУЩИЕ_МЕТРИКИ.команда('Git: ' + аргументы[0], ['/usr/bin/git', '-c', 'core.hooksPath=/dev/null',
            '-c', 'core.fsmonitor=false', '-c', 'http.sslVerify=true', *аргументы],
            каталог=путь, среда=среда, предел=предел)
    raise ValueError('Гостевая Git-команда требует явных активных метрик')


def получить_объекты(путь, коммит, среда):
    команда_репозитория(путь, ['fetch', '--no-tags', '--no-recurse-submodules',
        '--no-auto-maintenance', '--no-write-fetch-head', 'origin', коммит], среда)


def проверить_клон(путь, владелец, коммит, дерево, среда):
    if путь.is_symlink() or not путь.is_dir(): raise ValueError('Гостевой клон не является своим каталогом')
    служебный = os.open(путь / '.git', os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try:
        if json.loads(прочитать_личный_файл(служебный, 'владелец-linux-vm.json')) != владелец:
            raise ValueError('Гостевой Git относится к другой VM')
    finally: os.close(служебный)
    def запрос(*аргументы): return команда_репозитория(путь, list(аргументы), среда)
    if запрос('for-each-ref', '--format=%(refname)', 'refs/replace').strip():
        raise ValueError('Локальные замены Git-объектов запрещены для закреплённого клона')
    настройки = запрос('config', '--local', '--no-includes', '--list', '-z').split(b'\0')
    разрешённые = {b'core.repositoryformatversion', b'core.filemode', b'core.bare',
                   b'core.logallrefupdates', b'core.ignorecase', b'core.precomposeunicode',
                   b'remote.origin.url', b'remote.origin.fetch'}
    if any(строка.split(b'\n', 1)[0] not in разрешённые for строка in настройки if строка):
        raise ValueError('В гостевой Git добавлены неизвестные локальные настройки')
    if запрос('remote').strip() != b'origin' or запрос('remote', 'get-url', '--all', 'origin').decode().strip() != АДРЕС_РЕПОЗИТОРИЯ:
        raise ValueError('Гостевой origin изменён')
    for флаг, ожидается in [('--show-toplevel', путь), ('--absolute-git-dir', путь / '.git'), ('--git-common-dir', путь / '.git')]:
        фактический = Path(запрос('rev-parse', флаг).decode().strip())
        if not фактический.is_absolute(): фактический = путь / фактический
        if фактический.resolve() != ожидается: raise ValueError('Гостевой Git перенаправлен вне собственного клона')
    if запрос('rev-parse', 'HEAD').decode().strip() != коммит or запрос('rev-parse', 'HEAD^{tree}').decode().strip() != дерево:
        raise ValueError('Гостевой HEAD или дерево не совпадает с опубликованным коммитом')
    ожидаемые = {}
    for строка in запрос('ls-tree', '-r', '-z', коммит).split(b'\0'):
        if not строка: continue
        поля, имя = строка.split(b'\t', 1); режим, тип, объект = поля.split(b' ')
        ожидаемые[имя.decode()] = (режим.decode(), объект.decode())
    индекс = {}
    for строка in запрос('ls-files', '--stage', '-z').split(b'\0'):
        if not строка: continue
        поля, имя = строка.split(b'\t', 1); режим, объект, этап = поля.split(b' ')
        if этап != b'0' or имя.decode() in индекс: raise ValueError('Незавершённый гостевой индекс')
        индекс[имя.decode()] = (режим.decode(), объект.decode())
    if индекс != ожидаемые: raise ValueError('Гостевой индекс отличается от дерева коммита')
    if any(строка[:2] != b'H ' for строка in запрос('ls-files', '-v', '-z').split(b'\0') if строка):
        raise ValueError('Флаг индекса скрывает изменения гостевых файлов')
    каталоги = set()
    for имя, (режим, объект) in ожидаемые.items():
        относительный = Path(имя)
        if относительный.is_absolute() or '..' in относительный.parts: raise ValueError('Некорректный путь Git-дерева')
        for предок in относительный.parents:
            if предок == Path('.'): break
            каталоги.add(str(предок))
            адрес = путь / предок
            if адрес.is_symlink() or not адрес.is_dir(): raise ValueError('Подменён предок гостевого файла')
        адрес = путь / имя
        сведения = адрес.lstat()
        if режим == '160000':
            if not stat.S_ISDIR(сведения.st_mode) or any(адрес.iterdir()):
                raise ValueError('Переносимый профиль требует нематериализованный gitlink')
            continue
        if режим == '120000':
            if not stat.S_ISLNK(сведения.st_mode): raise ValueError('Изменён тип символической ссылки Git')
            байты = os.fsencode(os.readlink(адрес))
            сумма = hashlib.sha1(b'blob ' + str(len(байты)).encode() + b'\0' + байты).hexdigest()
        else:
            if (режим not in ('100644', '100755') or not stat.S_ISREG(сведения.st_mode)
                    or сведения.st_nlink != 1 or bool(сведения.st_mode & stat.S_IXUSR) != (режим == '100755')
                    or (режим == '100644' and сведения.st_mode & 0o111)):
                raise ValueError('Изменён тип или режим гостевого файла')
            файл = os.open(адрес, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC)
            try:
                состояние = os.fstat(файл)
                if (состояние.st_dev, состояние.st_ino, состояние.st_size) != (сведения.st_dev, сведения.st_ino, сведения.st_size):
                    raise ValueError('Гостевой файл изменился при открытии')
                хэш = hashlib.sha1(b'blob ' + str(состояние.st_size).encode() + b'\0')
                прочитано = 0
                while True:
                    блок = os.read(файл, 1024 * 1024)
                    if not блок: break
                    прочитано += len(блок); хэш.update(блок)
                    if прочитано > состояние.st_size: raise ValueError('Гостевой файл вырос при проверке')
                if прочитано != состояние.st_size: raise ValueError('Гостевой файл укорочен при проверке')
                сумма = хэш.hexdigest()
            finally: os.close(файл)
        if сумма != объект: raise ValueError('Гостевой файл изменён: ' + имя)
    for каталог, папки, файлы in os.walk(путь, followlinks=False):
        относительный = Path(каталог).relative_to(путь)
        if относительный == Path('.') and '.git' in папки: папки.remove('.git')
        for имя in [*папки, *файлы]:
            запись = str(относительный / имя)
            if запись not in ожидаемые and запись not in каталоги:
                raise ValueError('Посторонний файл в гостевом клоне: ' + запись)


def подготовить_клон(корень, каталог, владелец, коммит, дерево, прокси=None):
    for значение in (коммит, дерево):
        if len(значение) != 40 or any(буква not in '0123456789abcdef' for буква in значение):
            raise ValueError('Нужны полные OID гостевого коммита и дерева')
    среда = среда_репозитория(прокси)
    try: os.stat('готовый-клон.json', dir_fd=каталог, follow_symlinks=False)
    except FileNotFoundError: готовый = None
    else: готовый = json.loads(прочитать_личный_файл(каталог, 'готовый-клон.json'))
    if готовый is not None:
        if (not isinstance(готовый, dict) or set(готовый) != {'схема', 'каталог', 'коммит', 'дерево'}
                or готовый['схема'] != 'fum.гостевой-клон.1' or not isinstance(готовый['каталог'], str)):
            raise ValueError('Неверная схема свидетельства гостевого клона')
        имя = готовый.get('каталог', '')
        if (not имя.startswith('попытка-') or str(uuid.UUID(имя.removeprefix('попытка-'))) != имя.removeprefix('попытка-')
                or готовый.get('коммит') != коммит or готовый.get('дерево') != дерево):
            raise ValueError('Неверное свидетельство гостевого клона')
        путь = корень / имя
        проверить_клон(путь, владелец, коммит, дерево, среда)
        return путь
    if len(list(корень.glob('попытка-*'))) >= 16: raise ValueError('Сохранено 16 попыток; требуется разбор перед следующей')
    if os.statvfs(корень).f_bavail * os.statvfs(корень).f_frsize < 2 * 1024**3:
        raise ValueError('Для гостевого клона нужны 2 GiB свободного места')
    имя = 'попытка-' + str(uuid.uuid4()); os.mkdir(имя, mode=0o700, dir_fd=каталог)
    путь = корень / имя
    команда_репозитория(путь, ['init', '--initial-branch=codex/linux-vm', '--template='], среда)
    служебный = os.open(путь / '.git', os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try: записать_новый_файл(служебный, 'владелец-linux-vm.json', владелец)
    finally: os.close(служебный)
    команда_репозитория(путь, ['remote', 'add', 'origin', АДРЕС_РЕПОЗИТОРИЯ], среда)
    получить_объекты(путь, коммит, среда)
    if команда_репозитория(путь, ['cat-file', '-t', коммит], среда).strip() != b'commit':
        raise ValueError('Полученный объект не является коммитом')
    команда_репозитория(путь, ['checkout', '--detach', коммит], среда)
    проверить_клон(путь, владелец, коммит, дерево, среда)
    установить_свидетельство(каталог, 'готовый-клон.json', {'схема': 'fum.гостевой-клон.1',
                         'каталог': имя, 'коммит': коммит, 'дерево': дерево})
    return путь


def проверить_профиль(клон, счётчик, выполнить):
    наборы = [('fum-proyektnyiye-fajlyi', 8), ('fum-moskovskoye-vremya-rabochej-sessii', 4),
              ('fum-indeks-readme', 25), ('fum-obratnyiye-ssyilki-voprosov', 21)]
    результаты = []
    for имя, число in наборы:
        вывод = выполнить('Набор ' + имя, ['/usr/bin/python3', '-B', '-s', '-',
            str(клон / 'Инструменты' / имя / 'tests'), str(число)],
            каталог=клон, среда=среда_репозитория(), вход=счётчик.encode(), предел=120)
        счётчики = json.loads(вывод)
        проверить_счётчики(счётчики, число)
        результаты.append({'набор': имя, 'счётчики': счётчики})
    for имя, файл in [('fum-indeks-readme', 'check-readme-index.py'),
                       ('fum-obratnyiye-ssyilki-voprosov', 'check-question-backlinks.py')]:
        выполнить('Индекс ' + имя, ['/usr/bin/python3', '-B', '-s', str(клон / 'Инструменты' / имя / 'scripts' / файл),
                                    '--repo-root', str(клон)], каталог=клон, среда=среда_репозитория(), предел=120)
    return {'профиль': 'fum.linux-portable.1', 'тесты': sum(число for _, число in наборы),
            'проверки_индексов': 2, 'наборы': результаты}


import time


def загрузить_исполнителя(данные):
    """Получить обязательный адаптер из точных строк единственного stdin."""
    if not isinstance(данные, dict): raise ValueError('Нужны исходники гостевого наблюдения')
    for имя in ('наблюдатель', 'родитель_наблюдателя'):
        исходник = данные.get(имя)
        if not isinstance(исходник, str) or not 1 <= len(исходник.encode('utf-8')) <= 256 * 1024:
            raise ValueError('Исходник ' + имя + ' должен занимать от 1 байта до 256 KiB')
    область = {'__name__': 'fum_родитель_наблюдателя'}
    try: exec(compile(данные['родитель_наблюдателя'], '<родитель_наблюдателя>', 'exec'), область)
    except Exception as ошибка: raise ValueError('Не удалось загрузить родителя наблюдателя') from ошибка
    исполнитель = область.get('исполнить_под_наблюдением')
    if not callable(исполнитель): raise ValueError('В исходнике нет функции родителя наблюдателя')
    return исполнитель


class ИзмеренияГостя:
    def __init__(сам, родитель, каталог, запуск, источник, *, замок, наблюдатель, исполнитель):
        if not callable(исполнитель): raise ValueError('Нужна явная функция родителя наблюдателя')
        if not isinstance(наблюдатель, str) or not 1 <= len(наблюдатель.encode()) <= 256 * 1024:
            raise ValueError('Нужен ограниченный точный исходник наблюдателя')
        сам.замок = замок; сам.наблюдатель = наблюдатель; сам.исполнитель = исполнитель
        сам.родители = [родитель]; сам.каталог = каталог; сам.запуск = запуск
        сам.источник = источник; сам.события = []

    @contextlib.contextmanager
    def этап(сам, имя):
        событие = {'идентификатор': str(uuid.uuid4()), 'родитель': сам.родители[-1],
                   'операция': имя, 'исход': 'выполняется', 'длительностьНс': None,
                   'происхождение': сам.источник, 'запуск': сам.запуск}
        установить_свидетельство(сам.каталог, 'начало-' + событие['идентификатор'] + '.json', событие)
        начало = time.monotonic_ns(); сам.родители.append(событие['идентификатор'])
        try:
            yield
            событие['исход'] = 'успех'
        except BaseException:
            событие['исход'] = 'ошибка'
            raise
        finally:
            событие['длительностьНс'] = time.monotonic_ns() - начало
            сам.родители.pop(); сам.события.append(событие)
            установить_свидетельство(сам.каталог, 'конец-' + событие['идентификатор'] + '.json', событие)

    def команда(сам, имя, аргументы, *, каталог=None, среда=None, вход=None, предел=60):
        with сам.этап(имя):
            if type(предел) not in (int, float) or not math.isfinite(предел) or предел <= 0:
                raise ValueError('Неверное время гостевой команды')
            рабочий = str(Path(os.getcwd() if каталог is None else каталог).resolve(strict=True))
            try:
                итог = сам.исполнитель(наблюдатель=сам.наблюдатель, каталог=сам.каталог, замок=сам.замок,
                    аргументы=аргументы, рабочий_каталог=рабочий,
                    среда=среда_репозитория() if среда is None else среда, вход=b'' if вход is None else вход,
                    родитель=сам.родители[-1], проверка=сам.запуск, исходник=сам.источник,
                    тайм_аут_нс=int(предел * 1_000_000_000), предел_вывода=32 * 1024**2)
            except RuntimeError as ошибка:
                raise ValueError(имя + ': наблюдатель не подтвердил результат') from ошибка
            if (not isinstance(итог, dict) or 'код_команды' not in итог
                    or итог['код_команды'] is not None and type(итог['код_команды']) is not int
                    or type(итог.get('вывод')) is not bytes or type(итог.get('ошибки')) is not bytes
                    or not isinstance(итог.get('идентификатор'), str)
                    or str(uuid.UUID(итог['идентификатор'])) != итог['идентификатор']):
                raise ValueError(имя + ': родитель вернул неверный результат')
            if итог.get('исход') != 'успех' or итог['код_команды'] != 0 or итог.get('причина') != 'завершение':
                raise ValueError(имя + ': причина ' + str(итог.get('причина')) + '; попытка ' + итог['идентификатор']
                    + '; код ' + str(итог['код_команды']) + '; ' + итог['ошибки'][-2000:].decode(errors='replace'))
            return итог['вывод']


def подтвердить_готовность(данные):
    import platform
    global ТЕКУЩИЕ_МЕТРИКИ
    for ключ in ('машина', 'запуск', 'родитель', 'проверка'):
        if str(uuid.UUID(данные[ключ])) != данные[ключ]: raise ValueError('Неверная идентичность запроса готовности')
    for ключ in ('план', 'исходник'):
        if len(данные[ключ]) != 64 or any(буква not in '0123456789abcdef' for буква in данные[ключ]):
            raise ValueError('Неверный отпечаток готовности')
    коммит, дерево = '4dd5a7f33913b17f705e512be1826314da89a4c4', '03e9f37be0717b35e9e87a46fe27e540cd071d63'
    if данные['коммит'] != коммит: raise ValueError('Для этого коммита переносимый профиль ещё не закреплён')
    if Path('/etc/fum-vm-id').read_text().strip() != данные['машина']: raise ValueError('Подключена другая VM')
    система = platform.freedesktop_os_release()
    if platform.system() != 'Linux' or platform.machine() != 'aarch64' or система.get('ID') != 'ubuntu' or система.get('VERSION_ID') != '24.04':
        raise ValueError('Поддерживается только Ubuntu 24.04 aarch64')
    исполнитель = загрузить_исполнителя(данные)
    гостевой_запуск = Path('/proc/sys/kernel/random/boot_id').read_text().strip()
    корень = Path.home() / '.fum-linux-vm'
    владелец = {'схема': 'fum.область-гостя.1', 'машина': данные['машина'], 'план': данные['план']}
    with область_гостя(корень, владелец, вернуть_замок=True) as (каталог, замок):
        ожидаемые_данные = данные.get('ожидаемые_данные', '')
        if ожидаемые_данные and hashlib.sha256(прочитать_личный_файл(каталог, 'данные-повтора.json')).hexdigest() != ожидаемые_данные:
            raise ValueError('Прежние гостевые данные утрачены или изменены; новый эталон не создаётся')
        метрики = ИзмеренияГостя(данные['родитель'], каталог, данные['проверка'], данные['исходник'],
            замок=замок, наблюдатель=данные['наблюдатель'], исполнитель=исполнитель)
        ТЕКУЩИЕ_МЕТРИКИ = метрики
        try:
            with метрики.этап('Готовность Linux'):
                инициализация = json.loads(метрики.команда('Завершение cloud-init', ['/usr/bin/cloud-init', 'status', '--wait', '--format', 'json'], предел=240))
                проверить_инициализацию(0, инициализация)
                файловая_система = метрики.команда('Файловая система гостя', ['/usr/bin/findmnt', '-n', '-o', 'FSTYPE', '--target', str(корень)]).decode().strip()
                if файловая_система != 'ext4': raise ValueError('Гостевой профиль требует отдельную ext4')
                имена = метрики.команда('Гостевой DNS', ['/usr/bin/getent', 'ahostsv4', 'ports.ubuntu.com'])
                if not имена.strip(): raise ValueError('DNS гостя не вернул адресов')
                метрики.команда('HTTPS через ограниченный хостовый туннель', ['/usr/bin/curl', '-q', '--fail', '--silent', '--show-error', '--head',
                    '--connect-timeout', '5', '--max-time', '20', '--proxy', 'socks5h://127.0.0.1:1080',
                    'https://ports.ubuntu.com/ubuntu-ports/dists/noble/InRelease'], предел=25)
                версия = метрики.команда('Версия Git', ['/usr/bin/git', '--version']).decode().strip()
                with метрики.этап('Подготовка точного гостевого клона'):
                    клон = подготовить_клон(корень, каталог, владелец, коммит, дерево, 'socks5h://127.0.0.1:1080')
                with метрики.этап('Переносимый профиль FUM'):
                    профиль = проверить_профиль(клон, данные['счётчик'], метрики.команда)
                    проверить_клон(клон, владелец, коммит, дерево, среда_репозитория())
                try: os.stat('данные-повтора.json', dir_fd=каталог, follow_symlinks=False)
                except FileNotFoundError:
                    установить_свидетельство(каталог, 'данные-повтора.json', {'схема': 'fum.повтор-гостя.1', 'машина': данные['машина'], 'содержимое': str(uuid.uuid4())})
                повтор = прочитать_личный_файл(каталог, 'данные-повтора.json')
                if json.loads(повтор).get('машина') != данные['машина']: raise ValueError('Данные повтора относятся к другой VM')
                if ожидаемые_данные and hashlib.sha256(повтор).hexdigest() != ожидаемые_данные:
                    raise ValueError('Гостевые данные изменились во время проверки')
            результат = {'схема': 'fum.готовность-гостя.1', 'машина': данные['машина'], 'план': данные['план'],
                'запуск': данные['запуск'], 'проверка': данные['проверка'], 'гостевой_запуск': гостевой_запуск,
                'коммит': коммит, 'дерево': дерево, 'файловая_система': файловая_система, 'инициализация': 'done',
                'сеть': 'DNS гостя; HTTPS и Git через временный ограниченный SOCKS хоста',
                'версии': {'Python': platform.python_version(), 'Git': версия}, 'профиль': профиль,
                'сохранённые_данные': hashlib.sha256(повтор).hexdigest(), 'события': метрики.события}
            установить_свидетельство(каталог, 'готовность-' + данные['проверка'] + '.json', результат)
            return результат
        finally: ТЕКУЩИЕ_МЕТРИКИ = None
