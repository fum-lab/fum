#!/usr/bin/env python3
"""Адресная проверка Swift Testing на проверенном профиле Xcode 27; глобальная среда не меняется."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys


def построитьКоманду(разработчик: Path, пакет: Path, кэш: Path, фильтр: str | None) -> list[str]:
    if not разработчик.is_absolute() or not пакет.is_absolute() or not кэш.is_absolute():
        raise ValueError('Требуются абсолютные разрешённые пути входов')
    корень = разработчик.resolve(strict=True)
    профили = [
        (
            (
                корень / 'usr/bin/swift',
                корень / 'usr/lib/swift/host/plugins/testing/libTestingMacros.dylib',
                корень / 'Library/Developer/Frameworks/Testing.framework/Versions/A/Testing',
                корень / 'Library/Developer/usr/lib/lib_TestingInterop.dylib',
            ),
            ('test',),
        ),
        (
            (
                корень / 'Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-test',
                корень / 'Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib',
                корень / 'Platforms/MacOSX.platform/Developer/Library/Frameworks/Testing.framework/Versions/A/Testing',
                корень / 'Platforms/MacOSX.platform/Developer/usr/lib/lib_TestingInterop.dylib',
            ),
            (),
        ),
    ]
    необходимые = None
    подкоманда = ()
    for профиль, префикс in профили:
        if not all(путь.is_file() for путь in профиль):
            continue
        разрешённые = tuple(путь.resolve(strict=True) for путь in профиль)
        if all(путь.is_relative_to(корень) for путь in разрешённые):
            необходимые = профиль
            подкоманда = префикс
            break
    if необходимые is None:
        raise ValueError('Неполный установленный профиль Swift Testing либо ссылка вне developer directory')
    if not (пакет / 'Package.swift').is_file():
        raise ValueError('Не найден манифест выбранного пакета')
    swift, плагин, testing, interop = необходимые
    команда = [str(необходимые[0]), *подкоманда, '--build-system', 'swiftbuild', '--package-path', str(пакет),
               '--scratch-path', str(кэш), '--jobs', '1',
               '-Xswiftc', '-load-plugin-library', '-Xswiftc', str(плагин),
               '-Xlinker', '-rpath', '-Xlinker', str(testing.parents[3]),
               '-Xlinker', '-rpath', '-Xlinker', str(interop.parent)]
    if фильтр is not None:
        команда.extend(['--filter', фильтр])
    return команда


def выполнить() -> int:
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--пакет', type=Path, default=Path(__file__).resolve().parent.parent)
    разбор.add_argument('--кэш', type=Path, required=True)
    разбор.add_argument('--фильтр')
    разбор.add_argument('--показать-команду', action='store_true')
    аргументы = разбор.parse_args()
    try:
        выбор = subprocess.run(['xcode-select', '-p'], check=True, capture_output=True, text=True, timeout=10)
        разработчик = Path(выбор.stdout.strip())
        команда = построитьКоманду(разработчик, аргументы.пакет.resolve(), аргументы.кэш.resolve(), аргументы.фильтр)
        if аргументы.показать_команду:
            print(json.dumps(команда, ensure_ascii=False))
            return 0
        окружение = os.environ.copy()
        окружение['DEVELOPER_DIR'] = str(разработчик.resolve())
        код = subprocess.call(команда, cwd=аргументы.пакет.resolve(), env=окружение)
        кодИсполнителя = 128 - код if код < 0 else код
        исход = {'схема': 'fum.исход-проверки-пакета.1', 'завершение': 'сигнал' if код < 0 else 'выход',
                 'кодПроцесса': код, 'кодИсполнителя': кодИсполнителя}
        if код < 0: исход['сигнал'] = -код
        print(json.dumps(исход, ensure_ascii=False), file=sys.stderr)
        return кодИсполнителя
    except (OSError, ValueError, subprocess.SubprocessError) as ошибка:
        print(str(ошибка), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(выполнить())
