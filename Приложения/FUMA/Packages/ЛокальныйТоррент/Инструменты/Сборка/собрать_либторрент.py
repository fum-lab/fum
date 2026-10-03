"""Собрать уже зарегистрированные исходники; подключение зависимостей не выполняется."""
import argparse
import hashlib
import json
import os
import pathlib
import selectors
import shlex
import signal
import subprocess
import time

ЗАКРЕПЛЕНИЯ = {'libtorrent': '56ae8caba38bf154ffc210403cb23f91d0ecaa49',
    'try_signal': '105cce59972f925a33aa6b1c3109e4cd3caf583d'}
ПУТИ = {имя: 'Приложения/FUMA/Packages/ЛокальныйТоррент/Зависимости/' + имя for имя in ЗАКРЕПЛЕНИЯ}
ФОРКИ = {имя: 'https://github.com/fum-lab/' + имя + '.git' for имя in ЗАКРЕПЛЕНИЯ}
ОРИГИНАЛЫ = {имя: 'https://github.com/arvidn/' + имя + '.git' for имя in ЗАКРЕПЛЕНИЯ}


def выполнить(команда, таймаут=1200):
    среда = {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin', 'LC_ALL': 'C',
        'TMPDIR': '/tmp', 'GIT_OPTIONAL_LOCKS': '0', 'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_CONFIG_GLOBAL': '/dev/null'}
    процесс = None
    отменено = False
    прежние = {}
    def прервать(номер, кадр):
        nonlocal отменено
        отменено = True
    import threading
    if threading.current_thread() is threading.main_thread():
        for номер in [signal.SIGTERM, signal.SIGINT]:
            прежние[номер] = signal.signal(номер, прервать)
    try:
        процесс = subprocess.Popen(команда, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            start_new_session=True, env=среда)
        данные = bytearray()
        срок = time.monotonic() + таймаут
        def проверить_срок():
            if отменено:
                raise KeyboardInterrupt('прерван процесс сборки')
            if time.monotonic() >= срок:
                raise TimeoutError('тайм-аут процесса сборки')
        with selectors.DefaultSelector() as селектор:
            селектор.register(процесс.stdout, selectors.EVENT_READ)
            while селектор.get_map():
                проверить_срок()
                for ключ, _ in селектор.select(min(0.05, max(0, срок - time.monotonic()))):
                    часть = os.read(ключ.fd, 65536)
                    if not часть:
                        селектор.unregister(ключ.fileobj)
                    else:
                        данные.extend(часть)
                        if len(данные) > 4 * 1024 * 1024:
                            raise ValueError('вывод процесса превысил 4 МиБ')
        while процесс.poll() is None:
            проверить_срок()
            time.sleep(0.01)
        проверить_срок()
        if процесс.returncode:
            raise subprocess.CalledProcessError(процесс.returncode, команда, bytes(данные))
        return данные.decode('utf-8', errors='strict')
    finally:
        try:
            if процесс is not None:
                # Повторные сигналы во время teardown только отмечаются.
                try:
                    os.killpg(процесс.pid, signal.SIGTERM)
                    time.sleep(0.1)
                    os.killpg(процесс.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                процесс.wait()
                процесс.stdout.close()
        finally:
            for номер, обработчик in прежние.items():
                signal.signal(номер, обработчик)
        if отменено:
            raise KeyboardInterrupt('отмена подтверждена после очистки группы')


def проверить_регистрацию(корень, исполнитель=выполнить):
    for имя, коммит in ЗАКРЕПЛЕНИЯ.items():
        путь = ПУТИ[имя]
        строка = исполнитель(['git', '-C', str(корень), 'ls-tree', 'HEAD', '--', путь])
        if строка != '160000 commit ' + коммит + '\t' + путь + '\n':
            raise ValueError('нет точного зарегистрированного gitlink: ' + имя)
    строки = исполнитель(['git', '-C', str(корень), 'config', '--blob', 'HEAD:.gitmodules',
        '--get-regexp', r'^submodule\..*\.path$']).splitlines()
    for имя, путь in ПУТИ.items():
        разделы = [строка.split(' ', 1)[0][:-5] for строка in строки if строка.endswith(' ' + путь)]
        if len(разделы) != 1:
            raise ValueError('неоднозначная регистрация .gitmodules: ' + имя)
        for ключ, ожидаемое in [('url', ФОРКИ[имя]), ('fumUpstream', ОРИГИНАЛЫ[имя])]:
            значение = исполнитель(['git', '-C', str(корень), 'config', '--blob', 'HEAD:.gitmodules',
                '--get', разделы[0] + '.' + ключ])
            if значение != ожидаемое + '\n':
                raise ValueError('неверный источник зарегистрированной зависимости: ' + имя)


def проверить_клон(путь, имя, исполнитель):
    коммит = ЗАКРЕПЛЕНИЯ[имя]
    if not путь.is_dir() or путь.resolve() != путь:
        raise ValueError('нет физического материализованного клона: ' + имя)
    def прочитать(*аргументы):
        return исполнитель(['git', '-C', str(путь), *аргументы]).strip()
    if прочитать('rev-parse', '--show-toplevel') != str(путь):
        raise ValueError('каталог не является отдельным клоном: ' + имя)
    if прочитать('rev-parse', 'HEAD') != коммит or прочитать('rev-parse', '--is-shallow-repository') != 'false':
        raise ValueError('неверный OID или неполный клон: ' + имя)
    if прочитать('status', '--porcelain', '--untracked-files=all'):
        raise ValueError('грязные исходники зависимости: ' + имя)
    for роль, адрес in [('origin', ФОРКИ[имя]), ('upstream', ОРИГИНАЛЫ[имя])]:
        if прочитать('remote', 'get-url', '--all', роль) != адрес:
            raise ValueError('неверный remote ' + роль + ': ' + имя)
    ветки = прочитать('for-each-ref', '--format=%(refname)', '--contains=' + коммит, 'refs/remotes/origin/')
    if not ветки:
        raise ValueError('OID не достижим из локальных refs форка: ' + имя)


def проверить_выход(путь):
    if not путь.is_absolute() or '..' in путь.parts or путь.resolve() != путь:
        raise ValueError('нужен физический абсолютный выход без .. и ссылок')
    for предок in [путь, *путь.parents]:
        if предок.is_symlink():
            raise ValueError('символическая ссылка в выходе')
        if (предок / '.git').exists():
            raise ValueError('выход должен находиться вне Git')
    if путь.exists():
        if not путь.is_dir() or any(путь.iterdir()):
            raise ValueError('выход занят; наработка сохранена')


def проверить_разделение(пути):
    пути = [путь.resolve() for путь in пути]
    for номер, путь in enumerate(пути):
        for другой in пути[номер + 1:]:
            if путь == другой or путь in другой.parents or другой in путь.parents:
                raise ValueError('пересечение исходников и выходов')


def проверить_криптобиблиотеки(префикс):
    результат = []
    for имя, метка in [('libssl.dylib', 'SSL'), ('libcrypto.dylib', 'Crypto')]:
        путь = префикс / 'lib' / имя
        if not путь.is_file() or префикс not in путь.resolve().parents:
            raise ValueError('нет явной библиотеки OpenSSL ' + метка)
        результат.append(путь)
    return результат


def команды_сборки(источник, рабочий, префикс, среда):
    параметры = ['-DCMAKE_BUILD_TYPE=Release', '-DBUILD_SHARED_LIBS=ON', '-DCMAKE_CXX_STANDARD=17',
        '-DCMAKE_CXX_EXTENSIONS=OFF', '-Dexceptions=ON']
    параметры += ['-D' + имя + '=OFF' for имя in ['webtorrent', 'gnutls', 'dht', 'i2p', 'encryption',
        'build_tests', 'build_examples', 'build_tools', 'python-bindings']]
    параметры += ['-DCMAKE_INSTALL_PREFIX=' + str(префикс), '-DCMAKE_CXX_COMPILER=' + среда['cxx'],
        '-DCMAKE_OSX_SYSROOT=' + среда['sdk'], '-DCMAKE_OSX_ARCHITECTURES=' + среда['архитектура'],
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=' + среда['минимум_macos'], '-DBOOST_ROOT=' + среда['boost'],
        '-DOPENSSL_ROOT_DIR=' + среда['openssl'], '-DOPENSSL_INCLUDE_DIR=' + среда['openssl'] + '/include',
        '-DOPENSSL_SSL_LIBRARY=' + среда['openssl'] + '/lib/libssl.dylib',
        '-DOPENSSL_CRYPTO_LIBRARY=' + среда['openssl'] + '/lib/libcrypto.dylib']
    return [[среда['cmake'], '-G', 'Unix Makefiles', '-S', str(источник), '-B', str(рабочий / 'out'), *параметры],
        [среда['cmake'], '--build', str(рабочий / 'out'), '--config', 'Release', '--target', 'torrent-rasterbar', '--parallel', '2'],
        [среда['cmake'], '--install', str(рабочий / 'out'), '--config', 'Release']]


def выполнить_последовательно(команды, исполнитель=выполнить):
    for команда in команды:
        исполнитель(команда)


def разобрать_аргументы(строка):
    аргументы = shlex.split(строка)
    if not аргументы:
        raise ValueError('пустой экспорт аргументов')
    for аргумент in аргументы:
        разрешён = аргумент in ['-pthread', '-fexceptions']
        if аргумент.startswith(('-I/', '-L/')):
            разрешён = ',' not in аргумент
        if аргумент.startswith('-D'):
            разрешён = len(аргумент) > 2 and all(символ.isalnum() or символ in '_=.' for символ in аргумент[2:])
        if аргумент.startswith('-l'):
            разрешён = len(аргумент) > 2 and all(символ.isalnum() or символ in '_-' for символ in аргумент[2:])
        if аргумент.startswith('-Wl,-rpath,/'):
            разрешён = аргумент.count(',') == 2
        if any(символ.isspace() for символ in аргумент) or not разрешён:
            raise ValueError('непрозрачный аргумент экспорта: ' + аргумент)
    return аргументы


def собрать(корень, рабочий, префикс, среда, исполнитель=выполнить):
    if set(среда) != {'cmake', 'cxx', 'pkg_config', 'boost', 'openssl', 'sdk', 'архитектура', 'минимум_macos'}:
        raise ValueError('нужна точная явно объявленная среда сборки')
    if среда['архитектура'] not in ['arm64', 'x86_64'] or среда['минимум_macos'] != '14.0':
        raise ValueError('неподдержанные архитектура или deployment target')
    проверить_регистрацию(корень, исполнитель)
    регистрация = исполнитель(['git', '-C', str(корень), 'rev-parse', 'HEAD']).strip()
    if len(регистрация) != 40 or any(буква not in '0123456789abcdef' for буква in регистрация):
        raise ValueError('нет точного HEAD регистрации')
    исходники = корень / ПУТИ['libtorrent']
    для_сигналов = корень / ПУТИ['try_signal']
    проверить_клон(исходники, 'libtorrent', исполнитель)
    проверить_клон(для_сигналов, 'try_signal', исполнитель)
    вложенный = исходники / 'deps/try_signal'
    проверить_клон(вложенный, 'try_signal', исполнитель)
    if исполнитель(['git', '-C', str(исходники), 'ls-tree', 'HEAD', '--', 'deps/try_signal']) != (
            '160000 commit ' + ЗАКРЕПЛЕНИЯ['try_signal'] + '\tdeps/try_signal\n'):
        raise ValueError('неверный вложенный gitlink try_signal')
    проверить_выход(рабочий)
    проверить_выход(префикс)
    проверить_разделение([рабочий, префикс, корень])
    for имя in ['cmake', 'cxx', 'pkg_config', 'boost', 'openssl', 'sdk']:
        путь = pathlib.Path(среда[имя])
        if not путь.is_absolute() or путь.resolve() != путь or any(
                символ.isspace() or символ in '";$[]\\' for символ in str(путь)) or not путь.exists():
            raise ValueError('нет явного входа среды: ' + имя)
        if имя in ['cmake', 'cxx', 'pkg_config']:
            if not путь.is_file() or not os.access(путь, os.X_OK):
                raise ValueError('нет исполняемого файла среды: ' + имя)
        elif not путь.is_dir():
            raise ValueError('нет каталога среды: ' + имя)
    for путь in [pathlib.Path(среда['boost']) / 'boost/version.hpp',
            pathlib.Path(среда['openssl']) / 'include/openssl/ssl.h',
            pathlib.Path(среда['sdk']) / 'usr/include/sys/types.h']:
        if not путь.is_file():
            raise ValueError('нет обязательного заголовка среды: ' + str(путь))
    if any(символ in '";$[]\\' for символ in str(исходники)):
        raise ValueError('путь исходников содержит метасимвол CMake')
    криптобиблиотеки = проверить_криптобиблиотеки(pathlib.Path(среда['openssl']))
    рабочий.mkdir(parents=True, exist_ok=True)
    обёртка = рабочий / 'источник'
    обёртка.mkdir()
    (обёртка / 'CMakeLists.txt').write_text('cmake_minimum_required(VERSION 3.24)\n'
        'project(libtorrent LANGUAGES CXX)\nfind_package(OpenSSL REQUIRED COMPONENTS SSL Crypto)\n'
        'add_subdirectory("' + str(исходники) + '" "libtorrent")\n')
    начало = time.monotonic_ns()
    команды = команды_сборки(обёртка, рабочий, префикс, среда)
    исполнитель(команды[0])
    конфигурация = (рабочий / 'out/CMakeCache.txt').read_text()
    for имя, путь in zip(['OPENSSL_SSL_LIBRARY', 'OPENSSL_CRYPTO_LIBRARY'], криптобиблиотеки):
        if [строка for строка in конфигурация.splitlines() if строка.startswith(имя + ':')] != [имя + ':FILEPATH=' + str(путь)]:
            raise ValueError('CMake не подтвердил явно выбранный OpenSSL: ' + имя)
    выполнить_последовательно(команды[1:], исполнитель)
    пакет = префикс / 'lib/pkgconfig/libtorrent-rasterbar.pc'
    if not пакет.is_file():
        raise ValueError('нет установленного экспорта libtorrent-rasterbar.pc')
    библиотеки = list((префикс / 'lib').glob('libtorrent-rasterbar*.dylib'))
    заголовки = sorted(путь for путь in (префикс / 'include').rglob('*') if путь.is_file())
    if not библиотеки or not заголовки:
        raise ValueError('нет установленной shared библиотеки или заголовков')
    пути_артефактов = [*библиотеки, *криптобиблиотеки, пакет, *заголовки]
    def отпечатки():
        результат = {}
        for путь in пути_артефактов:
            до = путь.stat()
            хэш = hashlib.sha256(путь.read_bytes()).hexdigest()
            после = путь.stat()
            метка = lambda данные: (данные.st_dev, данные.st_ino, данные.st_size, данные.st_mtime_ns, данные.st_ctime_ns)
            if метка(до) != метка(после):
                raise ValueError('артефакт изменился при чтении')
            результат[str(путь)] = (хэш, метка(после))
        return результат
    проверенные = отпечатки()
    компиляция = разобрать_аргументы(исполнитель([среда['pkg_config'], '--cflags', str(пакет)]))
    if отпечатки() != проверенные:
        raise ValueError('артефакт изменился при экспорте флагов')
    линковка = разобрать_аргументы(исполнитель([среда['pkg_config'], '--libs', str(пакет)]))
    if отпечатки() != проверенные:
        raise ValueError('артефакт изменился при экспорте флагов')
    компиляция += ['-std=c++17', '-isysroot', среда['sdk'], '-arch', среда['архитектура'], '-mmacosx-version-min=14.0']
    линковка += [str(путь) for путь in криптобиблиотеки] + ['-Wl,-rpath,' + str(префикс / 'lib'),
        '-Wl,-rpath,' + среда['openssl'] + '/lib']
    проба = рабочий / 'проба.cpp'
    проба.write_text('#include <libtorrent/version.hpp>\n#include <openssl/ssl.h>\n'
        '#include <cstring>\nint main() { return std::strcmp(libtorrent::version(), "2.1.1.0") == 0'
        ' && TLS_method() != nullptr ? 0 : 1; }\n')
    исполнитель([среда['cxx'], *компиляция, str(проба), '-o', str(рабочий / 'проба'), *линковка])
    исполнитель([str(рабочий / 'проба')])
    проверить_регистрацию(корень, исполнитель)
    if исполнитель(['git', '-C', str(корень), 'rev-parse', 'HEAD']).strip() != регистрация:
        raise ValueError('HEAD регистрации изменился')
    for путь, имя in [(исходники, 'libtorrent'), (для_сигналов, 'try_signal'), (вложенный, 'try_signal')]:
        проверить_клон(путь, имя, исполнитель)
    if отпечатки() != проверенные:
        raise ValueError('артефакт изменился после пробы')
    return {'схема': 'fum.сборка-либторрента.1', 'коммиты': ЗАКРЕПЛЕНИЯ,
        'регистрация': регистрация,
        'аргументы_компиляции': компиляция, 'аргументы_линковки': линковка,
        'среда': среда, 'длительность_нс': time.monotonic_ns() - начало,
        'артефакты': {путь: значение[0] for путь, значение in проверенные.items()}, 'проба': 'успешно'}


def основная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--вход', required=True)
    парсер.add_argument('--выход', required=True)
    параметры = парсер.parse_args()
    вход = json.loads(pathlib.Path(параметры.вход).read_bytes())
    if set(вход) != {'корень', 'рабочий_каталог', 'префикс', 'среда'}:
        raise ValueError('неверный состав входа сборки')
    выход = pathlib.Path(параметры.выход)
    проверить_выход(выход.parent)
    проверить_разделение([выход.parent, pathlib.Path(вход['корень']),
        pathlib.Path(вход['рабочий_каталог']), pathlib.Path(вход['префикс'])])
    if выход.exists():
        raise ValueError('квитанция уже существует')
    результат = собрать(pathlib.Path(вход['корень']).resolve(), pathlib.Path(вход['рабочий_каталог']),
        pathlib.Path(вход['префикс']), вход['среда'])
    проверить_выход(выход.parent)
    выход.parent.mkdir(parents=True, exist_ok=True)
    # dir_fd удерживает тот физический каталог, который принят перед записью.
    import secrets
    каталог = os.open(выход.parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    временное = '.квитанция-' + secrets.token_hex(16)
    try:
        if os.fstat(каталог).st_ino != выход.parent.stat().st_ino:
            raise ValueError('каталог квитанции подменён')
        дескриптор = os.open(временное, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=каталог)
        with os.fdopen(дескриптор, 'w') as файл:
            json.dump(результат, файл, ensure_ascii=False, indent=2)
            файл.write('\n')
            файл.flush()
            os.fsync(файл.fileno())
        os.link(временное, выход.name, src_dir_fd=каталог, dst_dir_fd=каталог, follow_symlinks=False)
        os.fsync(каталог)
    finally:
        try:
            os.unlink(временное, dir_fd=каталог)
        except FileNotFoundError:
            pass
        os.close(каталог)


if __name__ == '__main__':
    основная()
