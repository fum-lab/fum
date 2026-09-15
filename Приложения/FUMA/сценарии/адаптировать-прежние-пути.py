#!/usr/bin/env python3
"""Применить конечную миграцию путей к проверенному исходному манифесту."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import time


def публичный_шаблон(текст):
    первая, разделитель, остальное = текст.partition('\n')
    остальное = остальное.replace('$HOME/Library/LaunchAgents', '${FUM_LAUNCH_AGENTS_DIR:?Задайте каталог LaunchAgents}')
    остальное = остальное.replace('$HOME/Library/Keychains/login.keychain-db', '${FUM_KEYCHAIN_PATH:?Задайте путь Keychain}')
    остальное = остальное.replace('${FUM_APPLICATIONS_DIR:-/Applications}', '${FUM_APPLICATIONS_DIR:?Задайте каталог установки}')
    остальное = остальное.replace('/Applications, starts it', 'FUM_APPLICATIONS_DIR, starts it')
    остальное = остальное.replace('-T /usr/bin/codesign', '-T "$(command -v codesign)"')
    остальное = остальное.replace('/usr/bin/', '')
    остальное = остальное.replace('/usr/libexec/PlistBuddy', '"${FUM_PLIST_BUDDY:?Задайте исполняемый файл PlistBuddy}"')
    остальное = остальное.replace('/dev/null', '"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}"')
    остальное = остальное.replace('"/CN=$SIGN_IDENTITY/"', '"${FUM_CERT_SUBJECT:?Задайте субъект сертификата}"')
    return первая + разделитель + остальное


def явные_маркеры(значение):
    if isinstance(значение, dict):
        return {ключ: явные_маркеры(содержимое) for ключ, содержимое in значение.items()}
    if isinstance(значение, list):
        return [явные_маркеры(содержимое) for содержимое in значение]
    if isinstance(значение, str):
        return re.sub(r'@(FUM_[A-Z_]+)@', r'${\1}', значение)
    return значение


def преобразовать(имя, текст):
    if имя.startswith('Sources/FUMApp/') and имя.endswith('.swift'):
        прежний = текст
        текст = re.sub(r'"/[^"\n]+/run/([^"\n]+)"',
                       lambda совпадение: 'ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("' + совпадение[1] + '").path', текст)
        текст = re.sub(r'"/[^"\n]+/Documents"', 'ПутиПриложения.текущие.документы.path', текст)
        if имя.endswith('InputEventMonitor.swift'):
            текст = текст.replace('URL(fileURLWithPath: NSHomeDirectory())\n        .appendingPathComponent(".codex/memory/senses/input/events.jsonl")',
                                  'ПутиПриложения.текущие.память.appendingPathComponent("senses/input/events.jsonl")')
        if имя.endswith('VideoMemory.swift'):
            текст = текст.replace('"~/.codex/memory/video-player/events.jsonl"',
                                  'ПутиПриложения.текущие.память.appendingPathComponent("video-player/events.jsonl").path')
        if текст != прежний:
            текст = '#if SWIFT_PACKAGE\nimport ПутиИсполнения\n#endif\n' + текст
    elif имя.startswith('launchd/') and имя.endswith('.plist'):
        данные = plistlib.loads(текст.encode())

        def заменить(значение):
            if isinstance(значение, dict):
                return {ключ: заменить(содержимое) for ключ, содержимое in значение.items()}
            if isinstance(значение, list):
                return [заменить(содержимое) for содержимое in значение]
            if not isinstance(значение, str):
                return значение
            for признак, подстановка in [('/run/', '@FUM_RUNTIME_ROOT@/'),
                                          ('/dist/', '@FUM_BUILD_ROOT@/dist/'),
                                          ('/.codex/memory/', '@FUM_MEMORY_ROOT@/')]:
                if значение.startswith('/') and признак in значение:
                    return подстановка + значение.split(признак, 1)[1]
            return значение

        данные = заменить(данные)
        данные['WorkingDirectory'] = '@FUM_RUNTIME_ROOT@'
        данные['EnvironmentVariables'] = {'FUM_RUNTIME_ROOT': '@FUM_RUNTIME_ROOT@', 'FUM_MEMORY_ROOT': '@FUM_MEMORY_ROOT@'}
        текст = plistlib.dumps(явные_маркеры(данные), sort_keys=False).decode()
    elif имя.startswith('script/install_') and имя.endswith('.sh'):
        первая, остальное = текст.split('\n', 1)
        текст = первая + '\nprintf "%s\\n" "Неприменённый шаблон: установка и системные разрешения требуют отдельной проверенной подготовки." >&2\nexit 2\n' + остальное
        текст = текст.replace('DIST_ROOT="$ROOT_DIR/dist"', 'DIST_ROOT="${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}/dist"')
        текст = текст.replace('DIST="$ROOT/dist"', 'DIST="${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}/dist"')
        текст = текст.replace('RUN_DIR="$ROOT_DIR/run', 'RUN_DIR="${FUM_RUNTIME_ROOT:?Задайте внешний runtime-каталог}')
        текст = текст.replace('RUN_DIR="$ROOT/run', 'RUN_DIR="${FUM_RUNTIME_ROOT:?Задайте внешний runtime-каталог}')
        текст = текст.replace('swift build ', 'swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" ')
        текст = текст.replace('cp ".build/release/fum-attention-loop"', 'cp "$FUM_BUILD_ROOT/release/fum-attention-loop"')
        текст = публичный_шаблон(текст)
    return текст


def подготовить(корень, манифест):
    if манифест.get('схема') != 'fum.перенос-исходников.1' or len(манифест.get('файлы', [])) != 39:
        raise ValueError('Требуется исходный манифест ровно 39 файлов приложения')
    корень = корень.resolve(strict=True)
    имена = set()
    for запись in манифест['файлы']:
        имя = запись['источник']
        if Path(имя).is_absolute() or any(часть in {'', '.', '..'} for часть in имя.split('/')):
            raise ValueError('Неканонический исходный путь')
        if запись['назначение'] != 'Приложения/FUMA/macOS/' + имя or имя in имена:
            raise ValueError('Выход из назначенной области или повтор пути')
        if запись['коммит'] != '39eb66a29c0be6844e73bcb8072e68b914ea7387':
            raise ValueError('Неизвестный исходный commit')
        имена.add(имя)
        путь = корень / запись['назначение']
        for часть in (путь, *путь.parents):
            if часть == корень: break
            if часть.is_symlink(): raise ValueError('Символическая ссылка в пути')
    изменения = []
    for запись in манифест['файлы']:
        путь = корень / запись['назначение']
        исходные = путь.read_bytes()
        if hashlib.sha256(исходные).hexdigest() != запись['sha256']:
            raise ValueError('Исходный файл уже изменён: ' + запись['источник'])
        новые = преобразовать(запись['источник'], исходные.decode()).encode()
        if новые != исходные:
            изменения.append((путь, исходные, новые))
    return изменения


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--корень', type=Path, required=True)
    разбор.add_argument('--исходный-манифест', type=Path, required=True)
    разбор.add_argument('--применить', action='store_true')
    параметры = разбор.parse_args()
    корень = параметры.корень.resolve(strict=True)
    начало = time.monotonic_ns()
    изменения = подготовить(корень, json.loads(параметры.исходный_манифест.read_text()))
    сводка = [{'путь': str(путь.relative_to(корень)),
               'до': hashlib.sha256(старые).hexdigest(),
               'после': hashlib.sha256(новые).hexdigest()} for путь, старые, новые in изменения]
    граница = time.monotonic_ns()
    if параметры.применить:
        for путь, исходные, новые in изменения:
            if путь.read_bytes() != исходные:
                raise ValueError('Изменился вход: ' + str(путь))
        for путь, _, новые in изменения:
            путь.write_bytes(новые)
    конец = time.monotonic_ns()
    print(json.dumps({'схема': 'fum.адаптация-путей-приложения.1',
                      'изменения': сводка,
                      'профиль': {'подготовка_нс': граница - начало, 'применение_нс': конец - граница}},
                     ensure_ascii=False, sort_keys=True, indent=2))


if __name__ == '__main__':
    главная()
