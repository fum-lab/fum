#!/usr/bin/env python3
"""Адресная проверка Swift Testing на проверенном профиле Xcode 27; глобальная среда не меняется."""
import argparse
import json
import os
from pathlib import Path
import stat
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
    разбор.add_argument('--компилятор', type=Path, help='явный clang для тестовых C ABI фикстур')
    разбор.add_argument('--показать-команду', action='store_true')
    аргументы = разбор.parse_args()
    try:
        if not аргументы.пакет.is_absolute():
            raise ValueError('Требуется абсолютный корень пакета')
        кореньПакета = аргументы.пакет.resolve(strict=True)
        if not (кореньПакета / 'Package.swift').is_file():
            raise ValueError('Не найден манифест выбранного пакета')
        выбор = subprocess.run(['xcode-select', '-p'], check=True, capture_output=True, text=True, timeout=10)
        выбранныйРазработчик = Path(выбор.stdout.strip())
        if not выбранныйРазработчик.is_absolute():
            raise ValueError('Требуется абсолютный developer directory')
        разработчик = выбранныйРазработчик.resolve(strict=True)
        компилятор = None
        sdk = None
        if аргументы.компилятор is not None:
            if not аргументы.компилятор.is_absolute():
                raise ValueError('Требуется абсолютный путь компилятора')
            компилятор = аргументы.компилятор.resolve(strict=True)
            if (not stat.S_ISREG(компилятор.stat().st_mode)
                    or not os.access(компилятор, os.X_OK)
                    or not компилятор.is_relative_to(разработчик)):
                raise ValueError('Компилятор должен быть исполняемым файлом выбранного developer directory')
            выборSDK = subprocess.run(['xcrun', '--sdk', 'macosx', '--show-sdk-path'], check=True,
                                     capture_output=True, text=True, timeout=10,
                                     env={'DEVELOPER_DIR': str(разработчик), 'PATH': os.defpath})
            выбранныйSDK = Path(выборSDK.stdout.strip())
            if not выбранныйSDK.is_absolute():
                raise ValueError('Требуется абсолютный корень SDK')
            sdk = выбранныйSDK.resolve(strict=True)
            if not sdk.is_dir() or not sdk.is_relative_to(разработчик):
                raise ValueError('SDK должен находиться внутри выбранного developer directory')
        команда = построитьКоманду(разработчик, кореньПакета, аргументы.кэш.resolve(), аргументы.фильтр)
        if аргументы.показать_команду:
            print(json.dumps(команда, ensure_ascii=False))
            return 0
        окружение = os.environ.copy()
        окружение['ФУМ_КОРЕНЬ_ПАКЕТА'] = str(кореньПакета)
        окружение.pop('ФУМ_КОМПИЛЯТОР', None)
        if компилятор is not None:
            окружение['ФУМ_КОМПИЛЯТОР'] = str(компилятор)
            окружение['SDKROOT'] = str(sdk)
        окружение['DEVELOPER_DIR'] = str(разработчик.resolve())
        код = subprocess.call(команда, cwd=кореньПакета, env=окружение)
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
