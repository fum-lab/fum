#!/usr/bin/env python3
"""Проверить закреплённый gitlink и дважды собрать TDLib в частном каталоге."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import stat
import subprocess
import sys
import time
from typing import Any


ПУТЬ_К_ПРОФИЛЮ = Path(__file__).resolve().parents[1] / 'Профили' / '2026-09-30-сборка-tdlib.json'
СХЕМА = 'fum.сборка-tdlib.1'
СХЕМА_ГОТОВНОСТИ = 'fum.готовность-зависимости-tdlib.1'


class ОтказПрофиля(RuntimeError):
    """Входное состояние не соответствует закреплённому профилю."""

    def __init__(сам, пояснение: str, причина: str = 'ошибка_чтения'):
        super().__init__(пояснение)
        сам.причина = причина


def прочитатьПрофиль(путь: Path = ПУТЬ_К_ПРОФИЛЮ) -> dict[str, Any]:
    профиль = json.loads(путь.read_text(encoding='utf-8'))
    if not isinstance(профиль, dict) or any(not isinstance(профиль.get(поле), dict) for поле in ('зависимость', 'сборка')):
        raise ОтказПрофиля('профиль требует объект и объектные поля зависимости и сборки', 'неверный_профиль')
    if профиль.get('схема') != 'fum.профиль-сборки-tdlib.1':
        raise ОтказПрофиля('неизвестная схема профиля TDLib')
    зависимость = профиль.get('зависимость', {})
    if зависимость != {
        'путь': 'Зависимости/TDLib',
        'зеркало': 'https://github.com/fum-lab/TDLib.git',
        'upstream': 'https://github.com/tdlib/td.git',
        'коммит': 'd1085f9cebc5a62379991ae1652673954f229c1f',
        'дерево': 'fdcb62d1739c348ede23f87427a82d6e345ca805',
        'времяКоммитаUnix': 1787589927,
        'отпечаткиSha256': {
            'CMakeLists.txt': '0703b8a1c1a38b693942f7fceaa519d29e7a81519964b272ffb46b55210fbb5f',
            'LICENSE_1_0.txt': 'c9bff75738922193e67fa726fa225535870d2aa1059f91452c411736284ad566',
            'td/generate/scheme/td_api.tl': '326b65b41442901ad6bf0ca2f7c356ae54365d6c343956a62e06a8b3cb305e87',
            'td/telegram/td_json_client.h': 'cdf6190b0264417c69c108d192d1f3381f3a1315ddb309798dbefc5036be1eb3',
            'tdutils/generate/CMakeLists.txt': '13764f95b99f2263ac9508e301807a79b2f7a72b9039c6282d3941b8bdf4389b',
            'sqlite/sqlite/LICENSE': '92a681e777538e3cc012d5886505fec7704fb9c1957ef6b67807d771985d457e',
        },
    }:
        raise ОтказПрофиля('изменён точный источник или коммит TDLib')
    if профиль.get('сборка', {}).get('повторений') != 2:
        raise ОтказПрофиля('приёмочный профиль требует ровно две независимые сборки')
    if профиль.get('сборка', {}).get('sourceDateEpoch') != зависимость['времяКоммитаUnix']:
        raise ОтказПрофиля('SOURCE_DATE_EPOCH должен совпадать со временем закреплённого коммита')
    return профиль


def разобратьGitmodules(вывод: bytes, профиль: dict[str, Any]) -> None:
    """Проверить ровно одну запись для TDLib из git config --null --list."""
    модули: dict[str, dict[str, list[str]]] = {}
    for запись in вывод.split(b'\0'):
        if not запись:
            continue
        if b'\n' not in запись:
            raise ОтказПрофиля('.gitmodules содержит некорректную NUL-запись')
        ключСырой, значениеСырой = запись.split(b'\n', 1)
        try:
            ключ = ключСырой.decode('utf-8', errors='strict')
            значение = значениеСырой.decode('utf-8', errors='strict')
        except UnicodeDecodeError as ошибка:
            raise ОтказПрофиля('.gitmodules содержит не-UTF-8 данные') from ошибка
        совпадение = re.fullmatch(r'submodule\.(.+)\.(path|url|fumupstream)', ключ, re.IGNORECASE)
        if совпадение is None:
            continue
        имя, поле = совпадение.groups()
        модули.setdefault(имя, {}).setdefault(поле.lower(), []).append(значение)

    путь = профиль['зависимость']['путь']
    совпавшие = [значения for значения in модули.values() if значения.get('path') == [путь]]
    if len(совпавшие) != 1:
        raise ОтказПрофиля('в .gitmodules не зарегистрирован единственный путь Зависимости/TDLib', 'нет_регистрации')
    запись = совпавшие[0]
    ожидаемые = {
        'path': путь,
        'url': профиль['зависимость']['зеркало'],
        'fumupstream': профиль['зависимость']['upstream'],
    }
    for поле, значение in ожидаемые.items():
        if запись.get(поле) != [значение]:
            raise ОтказПрофиля(f'.gitmodules: ожидалось ровно одно точное поле {поле}', 'неверная_регистрация')


def разобратьGitlink(вывод: bytes, профиль: dict[str, Any]) -> None:
    """Принять только один gitlink на требуемый путь и OID."""
    найдено: list[tuple[bytes, bytes, bytes, bytes]] = []
    for запись in вывод.split(b'\0'):
        if not запись:
            continue
        try:
            заголовок, путь = запись.split(b'\t', 1)
            режим, тип, oid = заголовок.split(b' ', 2)
        except ValueError as ошибка:
            raise ОтказПрофиля('git ls-tree вернул некорректную запись') from ошибка
        найдено.append((режим, тип, oid, путь))
    требуемыйПуть = os.fsencode(профиль['зависимость']['путь'])
    oid = профиль['зависимость']['коммит'].encode('ascii')
    if найдено != [(b'160000', b'commit', oid, требуемыйПуть)]:
        raise ОтказПрофиля('HEAD не содержит единственный gitlink на закреплённый OID TDLib', 'неверный_гитлинк')


def _запустить(команда: list[str], *, cwd: Path | None = None, timeout: int = 30,
              окружение: dict[str, str] | None = None,
              допустимыеКоды: tuple[int, ...] = (0,)) -> subprocess.CompletedProcess[bytes]:
    try:
        результат = subprocess.run(
            команда, cwd=cwd, env=окружение, capture_output=True, check=False, timeout=timeout
        )
    except (OSError, subprocess.TimeoutExpired) as ошибка:
        raise ОтказПрофиля(f'не удалось выполнить {Path(команда[0]).name}: {ошибка}') from ошибка
    if результат.returncode not in допустимыеКоды:
        stderr = результат.stderr.decode('utf-8', errors='replace')[-2000:]
        raise ОтказПрофиля(f'{Path(команда[0]).name} завершился с кодом {результат.returncode}: {stderr}')
    return результат


def _процессГита(корень: Path, *аргументы: str,
                допустимыеКоды: tuple[int, ...] = (0,)) -> subprocess.CompletedProcess[bytes]:
    окружение = {ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith('GIT_')}
    окружение.update({
        'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull,
        'GIT_NO_LAZY_FETCH': '1', 'GIT_NO_REPLACE_OBJECTS': '1',
        'GIT_OPTIONAL_LOCKS': '0', 'GIT_TERMINAL_PROMPT': '0',
    })
    return _запустить(['git', '-C', str(корень), '-c', 'core.fsmonitor=false',
                      *аргументы], окружение=окружение, допустимыеКоды=допустимыеКоды)


def _git(корень: Path, *аргументы: str, бинарный: bool = False) -> str | bytes:
    вывод = _процессГита(корень, *аргументы).stdout
    return вывод if бинарный else вывод.decode('utf-8', errors='strict').strip()


def проверитьРегистрацию(корень: Path, профиль: dict[str, Any],
                         свидетельства: dict[str, Any] | None = None) -> tuple[Path, str]:
    корень = корень.resolve(strict=True)
    if Path(_git(корень, 'rev-parse', '--show-toplevel')) != корень:
        raise ОтказПрофиля('указанный корень не является физическим корнем FUM')
    манифест = корень / '.gitmodules'
    if not манифест.is_file() or манифест.is_symlink():
        raise ОтказПрофиля('обычный файл .gitmodules не найден', 'нет_регистрации')
    выводНастроек = _git(корень, 'config', '--no-includes', '--file', '.gitmodules', '--null', '--list', бинарный=True)
    разобратьGitmodules(выводНастроек, профиль)
    коммитФУМ = _git(корень, 'rev-parse', 'HEAD')
    манифестВершины = _git(корень, 'show', f'{коммитФУМ}:.gitmodules', бинарный=True)
    стадииМанифеста = _git(корень, 'ls-files', '--stage', '-z', '--', '.gitmodules', бинарный=True)
    записьМанифеста = re.fullmatch(rb'100644 [0-9a-f]{40} 0\t\.gitmodules\0', стадииМанифеста)
    if записьМанифеста is None:
        raise ОтказПрофиля('индекс .gitmodules неоднозначен', 'расходится_регистрация')
    манифестИндекса = _git(корень, 'show', ':0:.gitmodules', бинарный=True)
    if манифест.read_bytes() != манифестВершины or манифестИндекса != манифестВершины:
        raise ОтказПрофиля('.gitmodules рабочего дерева или индекса отличается от HEAD', 'расходится_регистрация')
    # Тот же неизменный снимок HEAD задаёт manifest и gitlink.
    разобратьGitmodules(_git(корень, 'config', '--no-includes', '--blob',
                            f'{коммитФУМ}:.gitmodules', '--null', '--list', бинарный=True), профиль)
    oid = профиль['зависимость']['коммит']
    путь = профиль['зависимость']['путь']
    разобратьGitlink(_git(корень, 'ls-tree', '-z', коммитФУМ, '--', путь, бинарный=True), профиль)
    ожидаемыйИндекс = f'160000 {oid} 0\t{путь}\0'.encode()
    if _git(корень, 'ls-files', '--stage', '-z', '--', путь, бинарный=True) != ожидаемыйИндекс:
        raise ОтказПрофиля('индекс gitlink отличается от HEAD или содержит конфликт', 'неверный_гитлинк')
    if свидетельства is not None:
        свидетельства.update({'коммитФУМ': коммитФУМ, 'регистрация': {
            'гитлинк': 'HEAD-и-индекс', 'манифест': 'HEAD-индекс-рабочее-дерево',
            'манифестШа256': hashlib.sha256(манифестВершины).hexdigest(),
        }})
    зависимость = корень / путь
    if any(часть.is_symlink() for часть in (зависимость, *зависимость.parents)
           if часть != корень and корень in часть.parents):
        raise ОтказПрофиля('путь TDLib содержит символическую ссылку', 'нет_локальной_копии')
    if not зависимость.is_dir() or not (зависимость / '.git').exists():
        raise ОтказПрофиля('TDLib submodule не инициализирован как обычный каталог', 'нет_локальной_копии')
    статусЗависимости = _git(корень, '-c', 'core.quotePath=false', 'submodule', 'status', '--', путь, бинарный=True).decode('utf-8', errors='strict').rstrip('\n')
    if re.fullmatch(rf' {re.escape(oid)} {re.escape(путь)}(?: \(.+\))?', статусЗависимости) is None:
        raise ОтказПрофиля('submodule не инициализирован на точном gitlink OID', 'неверная_локальная_вершина')
    физическаяЗависимость = зависимость.resolve(strict=True)
    if Path(_git(физическаяЗависимость, 'rev-parse', '--show-toplevel')) != физическаяЗависимость:
        raise ОтказПрофиля('рабочее дерево TDLib не совпадает с путём submodule', 'нет_локальной_копии')
    if _git(физическаяЗависимость, 'rev-parse', 'HEAD') != oid:
        raise ОтказПрофиля('рабочий HEAD TDLib не совпадает с gitlink', 'неверная_локальная_вершина')
    флагиИндекса = _git(физическаяЗависимость, 'ls-files', '-v', '-z', бинарный=True)
    if any(запись and (запись[:1].islower() or запись[:1] == b'S') for запись in флагиИндекса.split(b'\0')):
        raise ОтказПрофиля('индекс TDLib содержит скрывающие флаги', 'изменена_локальная_копия')
    if _git(физическаяЗависимость, 'status', '--porcelain=v1', '--untracked-files=all'):
        raise ОтказПрофиля('рабочее дерево TDLib изменено или содержит неотслеживаемые файлы', 'изменена_локальная_копия')
    for имя, поле in (('origin', 'зеркало'), ('upstream', 'upstream')):
        результат = _процессГита(физическаяЗависимость, 'remote', 'get-url', '--all', имя, допустимыеКоды=(0, 2))
        адреса = результат.stdout.decode('utf-8', errors='strict').splitlines()
        if результат.returncode != 0 or адреса != [профиль['зависимость'][поле]]:
            raise ОтказПрофиля('origin/upstream TDLib не совпадают с .gitmodules и профилем', 'неверные_источники')
    вложенные = _git(физическаяЗависимость, 'ls-tree', '-r', '--format=%(objectmode) %(objecttype) %(objectname)', 'HEAD')
    if any(строка.startswith('160000 commit ') for строка in вложенные.splitlines()):
        raise ОтказПрофиля('обнаружен неучтённый вложенный gitlink TDLib', 'неучтённый_гитлинк')
    if _git(физическаяЗависимость, 'rev-parse', 'HEAD^{tree}') != профиль['зависимость']['дерево']:
        raise ОтказПрофиля('дерево TDLib не совпадает с отпечатком профиля', 'неверные_исходные_объекты')
    if int(_git(физическаяЗависимость, 'show', '-s', '--format=%ct', oid)) != профиль['зависимость']['времяКоммитаUnix']:
        raise ОтказПрофиля('время закреплённого коммита TDLib не совпадает с профилем', 'неверные_исходные_объекты')
    if _git(физическаяЗависимость, 'rev-parse', '--is-shallow-repository') != 'false':
        raise ОтказПрофиля('частичный или shallow-клон TDLib не допускается', 'неполная_локальная_копия')
    проверкаОбещаний = _процессГита(физическаяЗависимость, 'config', '--type=bool', '--get-regexp', r'^remote\..*\.promisor$', допустимыеКоды=(0, 1))
    расширениеКлона = _процессГита(физическаяЗависимость, 'config', '--get', 'extensions.partialClone', допустимыеКоды=(0, 1))
    if расширениеКлона.returncode == 0 or any(строка.endswith(b' true') for строка in проверкаОбещаний.stdout.splitlines()):
        raise ОтказПрофиля('partial clone TDLib не допускается', 'неполная_локальная_копия')
    _git(физическаяЗависимость, 'cat-file', '-e', f'{oid}^{{tree}}')
    return физическаяЗависимость, oid


def проверитьОтпечаткиИсточника(репозиторий: Path, профиль: dict[str, Any]) -> None:
    oid = профиль['зависимость']['коммит']
    tree = _git(репозиторий, 'rev-parse', f'{oid}^{{tree}}')
    if tree != профиль['зависимость']['дерево']:
        raise ОтказПрофиля('объектное дерево TDLib не совпадает с профилем')
    epoch = int(_git(репозиторий, 'show', '-s', '--format=%ct', oid))
    if epoch != профиль['зависимость']['времяКоммитаUnix']:
        raise ОтказПрофиля('время исходного коммита TDLib не совпадает с профилем')
    for имя, ожидаемый in профиль['зависимость']['отпечаткиSha256'].items():
        данные = _git(репозиторий, 'show', f'{oid}:{имя}', бинарный=True)
        фактический = hashlib.sha256(данные).hexdigest()
        if фактический != ожидаемый:
            raise ОтказПрофиля(f'хэш исходного файла TDLib не совпадает: {имя}', 'неверные_исходные_объекты')


def проверитьВыход(корень: Path, источник: Path, выход: Path) -> Path:
    if not выход.is_absolute() or '..' in выход.parts:
        raise ОтказПрофиля('каталог сборки должен быть абсолютным и без компонента ..')
    if выход.exists() or выход.is_symlink():
        raise ОтказПрофиля('каталог сборки уже существует')
    родитель = выход.parent.resolve(strict=True)
    if выход.parent != родитель:
        raise ОтказПрофиля('родитель каталога сборки неоднозначен')
    for запрещённый in (корень.resolve(strict=True), источник.resolve(strict=True)):
        if родитель == запрещённый or запрещённый in родитель.parents:
            raise ОтказПрофиля('каталог сборки должен находиться вне FUM и checkout TDLib')
    сведения = родитель.stat(follow_symlinks=False)
    if not stat.S_ISDIR(сведения.st_mode) or сведения.st_uid != os.getuid() or сведения.st_mode & 0o077:
        raise ОтказПрофиля('родитель каталога сборки должен принадлежать текущему пользователю и быть приватным')
    return родитель / выход.name


def sha256(путь: Path) -> str:
    хэш = hashlib.sha256()
    with путь.open('rb') as поток:
        for блок in iter(lambda: поток.read(1024 * 1024), b''):
            хэш.update(блок)
    return хэш.hexdigest()


def _версию(команда: list[str], выражение: str, имя: str, *, env: dict[str, str] | None = None) -> str:
    вывод = _запустить(команда, timeout=30, окружение=env).stdout.decode('utf-8', errors='replace')
    строка = next((строка.strip() for строка in вывод.splitlines() if re.search(выражение, строка)), '')
    if not строка:
        raise ОтказПрофиля(f'не удалось определить версию {имя}')
    return строка


ИМЕНА_ИНСТРУМЕНТОВ = frozenset(('clang', 'clang++', 'cmake', 'make', 'gperf', 'lipo', 'nm', 'otool'))


def проверитьИнструменты(инструменты: dict[str, Path] | None) -> dict[str, Path]:
    if not isinstance(инструменты, dict) or set(инструменты) != ИМЕНА_ИНСТРУМЕНТОВ:
        raise ОтказПрофиля('требуется точная карта: clang, clang++, cmake, make, gperf, lipo, nm, otool')
    проверенные = {}
    for имя, путь in инструменты.items():
        if not isinstance(путь, Path) or not путь.is_absolute():
            raise ОтказПрофиля(f'инструмент {имя} требует абсолютного пути')
        try:
            физический = путь.resolve(strict=True)
            if not stat.S_ISREG(физический.stat().st_mode) or not os.access(физический, os.X_OK):
                raise ОтказПрофиля(f'инструмент {имя} не является исполняемым обычным файлом')
        except OSError as ошибка:
            raise ОтказПрофиля(f'инструмент {имя} недоступен') from ошибка
        проверенные[имя] = физический
    return проверенные


def разобратьИнструменты(записи: list[str]) -> dict[str, Path]:
    карта = {}
    for запись in записи:
        имя, разделитель, путь = запись.partition('=')
        if not разделитель or имя not in ИМЕНА_ИНСТРУМЕНТОВ or имя in карта:
            raise ОтказПрофиля('неизвестная или повторная запись --инструмент имя=путь')
        карта[имя] = Path(путь)
    return проверитьИнструменты(карта)


def проверитьСреду(профиль: dict[str, Any], opensslRoot: Path, *,
                   инструменты: dict[str, Path] | None = None) -> dict[str, Any]:
    инструменты = проверитьИнструменты(инструменты)
    хост = профиль['хост']
    system = 'macOS' if platform.system() == 'Darwin' else platform.system()
    if system != хост['система'] or platform.machine() != хост['архитектура']:
        raise ОтказПрофиля('система или архитектура не совпадает с профилем')
    if platform.mac_ver()[0] != хост['версия']:
        raise ОтказПрофиля('версия macOS не совпадает с профилем')
    if not opensslRoot.is_absolute() or not opensslRoot.is_dir():
        raise ОтказПрофиля('--openssl-root должен быть существующим абсолютным каталогом')
    opensslRoot = opensslRoot.resolve(strict=True)

    выборРазработчика = _запустить(['xcode-select', '-p']).stdout.decode().strip()
    разработчик = Path(выборРазработчика).resolve(strict=True)
    xcode = _запустить(['xcodebuild', '-version'], окружение={'DEVELOPER_DIR': str(разработчик), 'PATH': os.defpath})
    строкиXcode = xcode.stdout.decode().splitlines()
    if len(строкиXcode) < 2 or строкиXcode[0] != f"Xcode {хост['xcode']}" or строкиXcode[1] != f"Build version {хост['сборкаXcode']}":
        raise ОтказПрофиля('версия или сборка Xcode не совпадает с профилем')
    envXcode = {'DEVELOPER_DIR': str(разработчик), 'PATH': os.defpath, 'LC_ALL': 'C'}
    sdk = _запустить(['xcrun', '--sdk', 'macosx', '--show-sdk-version'], окружение=envXcode).stdout.decode().strip()
    sdkBuild = _запустить(['xcrun', '--sdk', 'macosx', '--show-sdk-build-version'], окружение=envXcode).stdout.decode().strip()
    if sdk != хост['sdk'] or sdkBuild != хост['сборкаSdk']:
        raise ОтказПрофиля('SDK или его build id не совпадает с профилем')
    sdkPath = Path(_запустить(['xcrun', '--sdk', 'macosx', '--show-sdk-path'], окружение=envXcode).stdout.decode().strip()).resolve(strict=True)
    clang = инструменты['clang']
    clangxx = инструменты['clang++']
    if not clang.is_relative_to(разработчик) or not clangxx.is_relative_to(разработчик):
        raise ОтказПрофиля('компилятор вышел за пределы выбранного Xcode')
    clangВерсия = _версию([str(clang), '--version'], r'Apple clang version', 'Apple Clang', env=envXcode)
    cmake, make, gperf = (инструменты[имя] for имя in ('cmake', 'make', 'gperf'))
    cmakeВерсия = _версию([str(cmake), '--version'], r'^cmake version ', 'CMake', env=envXcode)
    makeВерсия = _версию([str(make), '--version'], r'^GNU Make ', 'GNU Make', env=envXcode)
    gperfВерсия = _версию([str(gperf), '--version'], r'^GNU gperf ', 'GNU gperf', env=envXcode)
    openssl = opensslRoot / 'bin/openssl'
    opensslВерсия = _версию([str(openssl), 'version'], r'^OpenSSL ', 'OpenSSL', env=envXcode)
    zlibStub = sdkPath / 'usr/lib/libz.tbd'
    if not zlibStub.is_file() or sha256(zlibStub) != хост['zlibTbdSha256']:
        raise ОтказПрофиля('zlib из закреплённого SDK не совпадает по SHA-256')
    наблюдения = {
        'macOS': platform.mac_ver()[0],
        'архитектура': platform.machine(),
        'xcode': строкиXcode[0],
        'сборкаXcode': хост['сборкаXcode'],
        'sdk': sdk,
        'сборкаSdk': sdkBuild,
        'clang': clangВерсия,
        'cmake': cmakeВерсия,
        'make': makeВерсия,
        'gperf': gperfВерсия,
        'openssl': opensslВерсия,
        'sha256Инструментов': {
            'clang': sha256(clang),
            'clang++': sha256(clangxx),
            'cmake': sha256(Path(cmake).resolve(strict=True)),
            'make': sha256(Path(make)),
            'gperf': sha256(Path(gperf)),
            'openssl': sha256(openssl),
            'zlibTbd': sha256(zlibStub),
        },
    }
    expected = {
        'clang': хост['clang'],
        'cmake': f"cmake version {хост['cmake']}",
        'make': хост['make'],
        'gperf': хост['gperf'],
        'openssl': хост['openssl'],
    }
    for поле, начало in expected.items():
        if not наблюдения[поле].startswith(начало):
            raise ОтказПрофиля(f'{поле} не совпадает с закреплённым профилем: {наблюдения[поле]}')
    for инструмент, ожидаемыйХэш in хост['sha256Инструментов'].items():
        if наблюдения['sha256Инструментов'].get(инструмент) != ожидаемыйХэш:
            raise ОтказПрофиля(f'байты инструмента {инструмент} не совпадают с закреплённым профилем')
    return {
        **инструменты,
        'разработчик': разработчик,
        'наблюдения': наблюдения,
        'sdkПуть': sdkPath,
        'clang': clang,
        'clangxx': clangxx,
        'cmake': Path(cmake).resolve(strict=True),
        'make': Path(make),
        'gperf': Path(gperf),
        'opensslRoot': opensslRoot.resolve(strict=True),
    }


def _окружение(разработчик: Path, sdk: Path, выход: Path, sourceDateEpoch: int) -> dict[str, str]:
    home = выход / 'home'
    temporary = выход / 'tmp'
    home.mkdir(mode=0o700)
    temporary.mkdir(mode=0o700)
    return {
        'PATH': os.defpath,
        'HOME': str(home),
        'TMPDIR': str(temporary),
        'DEVELOPER_DIR': str(разработчик),
        'SDKROOT': str(sdk),
        'MACOSX_DEPLOYMENT_TARGET': '15.0',
        'LC_ALL': 'C',
        'LANG': 'C',
        'ZERO_AR_DATE': '1',
        'SOURCE_DATE_EPOCH': str(sourceDateEpoch),
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_CONFIG_GLOBAL': os.devnull,
        'GIT_NO_LAZY_FETCH': '1',
        'GIT_NO_REPLACE_OBJECTS': '1',
        'GIT_OPTIONAL_LOCKS': '0',
        'GIT_TERMINAL_PROMPT': '0',
    }


def _клонироватьИсточник(репозиторий: Path, oid: str, целевой: Path, окружение: dict[str, str]) -> Path:
    _запустить(['git', '-c', 'protocol.file.allow=always', 'clone', '--local', '--no-hardlinks',
                '--no-checkout', str(репозиторий), str(целевой)], timeout=180, окружение=окружение)
    _git(целевой, 'checkout', '--detach', oid)
    if _git(целевой, 'rev-parse', 'HEAD') != oid:
        raise ОтказПрофиля('копия источника не установлена на закреплённый OID')
    if _git(целевой, 'status', '--porcelain=v1', '--untracked-files=all'):
        raise ОтказПрофиля('новая копия источника TDLib изначально грязная')
    return целевой


def _конфигурация(профиль: dict[str, Any], среда: dict[str, Any], источник: Path,
                  выход: Path) -> list[str]:
    сборка = профиль['сборка']
    команда = [str(среда['cmake']), '-S', str(источник), '-B', str(выход / 'build'),
               '-G', сборка['генератор'],
               f"-DCMAKE_MAKE_PROGRAM={среда['make']}",
               f"-DCMAKE_BUILD_TYPE={сборка['тип']}",
               f"-DCMAKE_OSX_ARCHITECTURES={профиль['хост']['архитектура']}",
               f"-DCMAKE_OSX_DEPLOYMENT_TARGET={сборка['минимальнаяВерсияMacOS']}",
               f"-DCMAKE_OSX_SYSROOT={среда['sdkПуть']}",
               f"-DCMAKE_C_COMPILER={среда['clang']}",
               f"-DCMAKE_CXX_COMPILER={среда['clangxx']}",
               f"-DCMAKE_CXX_STANDARD={сборка['стандартCxx']}",
               '-DCMAKE_CXX_STANDARD_REQUIRED=ON',
               f"-DCMAKE_INSTALL_PREFIX={выход / 'install'}",
               f"-DOPENSSL_ROOT_DIR={среда['opensslRoot']}",
               f"-DGPERF_EXECUTABLE={среда['gperf']}"]
    команда.extend(f'-D{ключ}={значение}' for ключ, значение in сборка['опции'].items())
    return команда


def _собратьОдин(номер: int, репозиторий: Path, oid: str, профиль: dict[str, Any],
                  среда: dict[str, Any], кореньВыхода: Path, разработчик: Path) -> dict[str, Any]:
    каталог = кореньВыхода / f'проход-{номер}'
    каталог.mkdir(mode=0o700)
    окружение = _окружение(разработчик, среда['sdkПуть'], каталог,
                            профиль['сборка']['sourceDateEpoch'])
    источник = _клонироватьИсточник(репозиторий, oid, каталог / 'source', окружение)
    treeOid = _git(источник, 'rev-parse', 'HEAD^{tree}')
    архив = _запустить(['git', '-C', str(источник), 'archive', '--format=tar', oid],
                       timeout=180, окружение=окружение).stdout
    архивSha256 = hashlib.sha256(архив).hexdigest()

    started = time.perf_counter()
    _запустить(_конфигурация(профиль, среда, источник, каталог), cwd=каталог, timeout=1800, окружение=окружение)
    configureSeconds = time.perf_counter() - started

    started = time.perf_counter()
    _запустить([str(среда['cmake']), '--build', str(каталог / 'build'), '--target', 'tdjson',
                '--parallel', str(профиль['сборка']['параллельныхЗаданий'])],
               cwd=каталог, timeout=7200, окружение=окружение)
    buildSeconds = time.perf_counter() - started

    started = time.perf_counter()
    _запустить([str(среда['cmake']), '--install', str(каталог / 'build')],
               cwd=каталог, timeout=600, окружение=окружение)
    installSeconds = time.perf_counter() - started

    библиотеки = sorted((каталог / 'install').glob('lib/libtdjson*.dylib'))
    if len(библиотеки) != 1:
        raise ОтказПрофиля('установка должна содержать одну libtdjson.dylib')
    библиотека = библиотеки[0]
    архитектуры = _запустить([str(среда['lipo']), '-archs', str(библиотека)]).stdout.decode().split()
    if архитектуры != [профиль['хост']['архитектура']]:
        raise ОтказПрофиля(f'архитектура библиотеки не совпадает: {архитектуры}')
    выводСимволов = _запустить([str(среда['nm']), '-gU', str(библиотека)]).stdout.decode('utf-8', errors='replace')
    символы = {строка.split()[-1].lstrip('_') for строка in выводСимволов.splitlines() if строка.split()}
    отсутствуют = [символ for символ in профиль['сборка']['символы'] if символ not in символы]
    if отсутствуют:
        raise ОтказПрофиля(f'в libtdjson отсутствуют символы: {", ".join(отсутствуют)}')
    выводЗависимостей = _запустить([str(среда['otool']), '-L', str(библиотека)]).stdout.decode('utf-8', errors='replace')
    зависимости = []
    rootOpenSSL = Path(среда['opensslRoot']).resolve(strict=True)
    строкиЗависимостей = выводЗависимостей.splitlines()[1:]
    for строка in строкиЗависимостей:
        имя = строка.strip().split(' (', 1)[0]
        if имя.startswith(('/usr/lib/', '/System/Library/')):
            нормализовано = f'system/{Path(имя).name}'
        elif имя.startswith(('@rpath/', '@loader_path/', '@executable_path/')):
            нормализовано = f'dynamic/{Path(имя).name}'
        elif Path(имя).is_absolute() and Path(имя).resolve(strict=False).is_relative_to(rootOpenSSL):
            нормализовано = f'openssl/{Path(имя).name}'
        else:
            raise ОтказПрофиля(f'неожиданная внешняя динамическая зависимость: {Path(имя).name}')
        зависимости.append(нормализовано)
    if len(зависимости) != len(set(зависимости)):
        raise ОтказПрофиля('otool -L вернул повторные зависимости')
    return {
        'проход': номер,
        'коммит': oid,
        'дерево': treeOid,
        'архивSha256': архивSha256,
        'настройкаСекунд': round(configureSeconds, 6),
        'сборкаСекунд': round(buildSeconds, 6),
        'установкаСекунд': round(installSeconds, 6),
        'библиотекаSha256': sha256(библиотека),
        'библиотекаBytes': библиотека.stat().st_size,
        'архитектуры': архитектуры,
        'символы': профиль['сборка']['символы'],
        'зависимости': зависимости,
    }


def собрать(корень: Path, выход: Path, opensslRoot: Path, *,
            инструменты: dict[str, Path] | None = None) -> dict[str, Any]:
    инструменты = проверитьИнструменты(инструменты)
    профиль = прочитатьПрофиль()
    корень = корень.resolve(strict=True)
    источник, oid = проверитьРегистрацию(корень, профиль)
    проверитьОтпечаткиИсточника(источник, профиль)
    выход = проверитьВыход(корень, источник, выход)
    tools = проверитьСреду(профиль, opensslRoot, инструменты=инструменты)
    разработчик = tools['разработчик']
    выход.mkdir(mode=0o700)
    os.chmod(выход, 0o700)
    сведенияВыхода = выход.stat(follow_symlinks=False)
    if сведенияВыхода.st_uid != os.getuid() or stat.S_IMODE(сведенияВыхода.st_mode) != 0o700:
        raise ОтказПрофиля('каталог сборки не удалось создать с режимом 0700')
    результаты = [_собратьОдин(i, источник, oid, профиль, tools, выход, разработчик)
                  for i in range(1, профиль['сборка']['повторений'] + 1)]
    хэши = {результат['библиотекаSha256'] for результат in результаты}
    if len(хэши) != 1:
        raise ОтказПрофиля('два независимых прохода создали разные байты libtdjson')
    return {
        'схема': СХЕМА,
        'исход': 'успех',
        'коммит': oid,
        'профиль': tools['наблюдения'],
        'повторений': len(результаты),
        'библиотекаSha256': результаты[0]['библиотекаSha256'],
        'байтыСовпали': True,
        'проходы': результаты,
    }



ПОЯСНЕНИЯ_ГОТОВНОСТИ = {
    'проверено': 'Локальные входы закреплённой зависимости проверены.',
    'нет_регистрации': 'Зависимость отсутствует в обычном .gitmodules.',
    'неверная_регистрация': 'Поля регистрации не совпадают с закреплённым профилем.',
    'расходится_регистрация': 'HEAD, индекс и рабочий файл .gitmodules не согласованы.',
    'неверный_гитлинк': 'HEAD или индекс не содержит точный закреплённый gitlink.',
    'нет_локальной_копии': 'Зарегистрированная зависимость не материализована локально.',
    'неверная_локальная_вершина': 'Локальный HEAD зависимости не совпадает с gitlink.',
    'изменена_локальная_копия': 'Локальная копия изменена или содержит неотслеживаемые файлы.',
    'неверные_источники': 'Локальные адреса origin/upstream не совпадают с профилем.',
    'неучтённый_гитлинк': 'Зависимость содержит неучтённый вложенный gitlink.',
    'неверные_исходные_объекты': 'Исходные объекты не совпадают с закреплёнными отпечатками.',
    'неполная_локальная_копия': 'Shallow или partial clone не допускается.',
    'неверный_профиль': 'Профиль зависимости не соответствует закреплённому контракту.',
    'неверные_аргументы': 'Режим диагностики не принимает параметры сборки или неизвестные флаги.',
    'ошибка_чтения': 'Не удалось прочитать локальные входы зависимости.',
}


def проверитьГотовность(корень: Path, профиль: dict[str, Any] | None = None) -> dict[str, Any]:
    """Только чтение. Переданный профиль нужен локальным синтетическим фикстурам."""
    переданныйПрофиль = профиль is not None
    начало = time.perf_counter_ns()
    результат: dict[str, Any] = {'схема': СХЕМА_ГОТОВНОСТИ, 'исход': 'отказ',
        'причина': 'ошибка_чтения', 'профиль': [], 'этап': 'профиль'}
    def измерить(этап, действие):
        результат['этап'] = этап
        началоЭтапа = time.perf_counter_ns()
        исход = 'отказ'
        try:
            значение = действие()
            исход = 'успех'
            return значение
        finally:
            результат['профиль'].append({'этап': этап, 'началоНаносекунды': началоЭтапа - начало,
                'длительностьНаносекунды': time.perf_counter_ns() - началоЭтапа, 'исход': исход})
    try:
        try:
            профиль = измерить('профиль', lambda: прочитатьПрофиль() if профиль is None else профиль)
        except (OSError, ValueError, ОтказПрофиля) as ошибка:
            raise ОтказПрофиля('не удалось прочитать закреплённый профиль', 'неверный_профиль') from ошибка
        результат.update({'путьЗависимости': профиль['зависимость']['путь'],
            'ожидаемыйКоммит': профиль['зависимость']['коммит'],
            'источникПрофиля': 'аргумент-фикстуры' if переданныйПрофиль else 'закреплённый-файл'})
        источник, _ = измерить('регистрация', lambda: проверитьРегистрацию(корень, профиль, результат))
        измерить('исходные_объекты', lambda: проверитьОтпечаткиИсточника(источник, профиль))
        результат.update({'исход': 'успех', 'причина': 'проверено'})
    except ОтказПрофиля as ошибка:
        результат['причина'] = ошибка.причина if ошибка.причина in ПОЯСНЕНИЯ_ГОТОВНОСТИ else 'ошибка_чтения'
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        результат['причина'] = 'ошибка_чтения'
    результат['пояснение'] = ПОЯСНЕНИЯ_ГОТОВНОСТИ[результат['причина']]
    результат['длительностьНаносекунды'] = time.perf_counter_ns() - начало
    return результат

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--корень-репозитория', type=Path, required=True)
    parser.add_argument('--выход', type=Path,
                        help='новый абсолютный каталог с приватным владельцем и правами 0700')
    parser.add_argument('--openssl-root', type=Path)
    parser.add_argument('--инструмент', action='append', default=[], metavar='ИМЯ=ПУТЬ',
                        help='явные исполняемые файлы закрытой карты сборочных инструментов')
    parser.add_argument('--только-проверить-зависимость', action='store_true',
                        help='прочитать локальную регистрацию и объекты TDLib до любых сборочных действий')
    args, неизвестные = parser.parse_known_args()
    if args.только_проверить_зависимость:
        if неизвестные or args.выход is not None or args.openssl_root is not None or args.инструмент:
            диагностика = {'схема': СХЕМА_ГОТОВНОСТИ, 'исход': 'отказ', 'этап': 'аргументы',
                'причина': 'неверные_аргументы', 'пояснение': ПОЯСНЕНИЯ_ГОТОВНОСТИ['неверные_аргументы'],
                'профиль': [], 'длительностьНаносекунды': 0}
        else:
            диагностика = проверитьГотовность(args.корень_репозитория)
        print(json.dumps(диагностика, ensure_ascii=False, sort_keys=True),
              file=sys.stdout if диагностика['исход'] == 'успех' else sys.stderr)
        return 0 if диагностика['исход'] == 'успех' else 2
    if неизвестные or args.выход is None or args.openssl_root is None:
        parser.error('сборка требует --выход и --openssl-root без неизвестных флагов')
    try:
        инструменты = разобратьИнструменты(args.инструмент)
        result = собрать(args.корень_репозитория, args.выход, args.openssl_root, инструменты=инструменты)
    except (OSError, ValueError, ОтказПрофиля, subprocess.SubprocessError) as error:
        print(json.dumps({'схема': СХЕМА, 'исход': 'отказ', 'причина': str(error)},
                         ensure_ascii=False), file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == '__main__':
    sys.exit(main())
