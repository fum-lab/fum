#!/usr/bin/env python3
"""Ранняя сверка покрытия: только чтение, без глобального обхода Markdown."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import time
from urllib.parse import unquote


def загрузить_связность():
    путь = Path(__file__).with_name('check-session-coherence.py')
    описание = importlib.util.spec_from_file_location('связность_раннего_охвата', путь)
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = модуль
    описание.loader.exec_module(модуль)
    return модуль


СВЯЗНОСТЬ = загрузить_связность()


def хэш(байты):
    return hashlib.sha256(байты).hexdigest()


def выполнить_git(корень, *аргументы):
    return subprocess.check_output(['git', '-C', str(корень), *аргументы], env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})


def точный_путь(корень, имя, кэш=None):
    if not isinstance(имя, str) or not имя or Path(имя).is_absolute() or any(часть in ('', '.', '..', '.git') for часть in имя.split('/')):
        raise ValueError(f'Требуется точная относительная цель: {имя!r}')
    путь = корень
    if кэш is None: кэш = {}
    for часть in имя.split('/'):
        путь = путь / часть
        if путь.is_symlink():
            raise ValueError(f'Символическая ссылка в цели: {имя}')
        фактический = СВЯЗНОСТЬ.actual_case_path(путь, корень, кэш)
        if фактический is not None and фактический != путь:
            raise ValueError(f'Неверный регистр цели: {имя}')
        if путь.exists() and фактический is None:
            raise ValueError(f'Не удалось подтвердить точную цель: {имя}')
    return путь


def прочитать_статус(корень):
    байты = выполнить_git(корень, 'status', '--porcelain=v1', '-z', '--untracked-files=all')
    части = iter(байты.split(b'\0'))
    строки = []
    пути = set()
    for часть in части:
        if not часть: continue
        статус = часть[:2].decode('ascii')
        имя = часть[3:].decode('utf-8')
        пары = [(статус, имя)]
        if 'R' in статус or 'C' in статус:
            исходное = next(части).decode('utf-8')
            пары.append((' D' if 'R' in статус else ' M', исходное))
        for код, путь in пары:
            # Старый построчный валидатор не различает буквальную стрелку и rename.
            # Закрытый отказ сохраняет полный сырой снимок без ложного покрытия.
            if any(знак in путь for знак in ('\n', '\r', ' -> ')):
                raise ValueError(f'Имя не поддержано построчным контрактом связности: {путь!r}')
            # Git C-quoting: старый decoder ожидает UTF-8 через octal-байты,
            # а не JSON surrogate-пары или неоднозначный Latin-1-текст.
            кавычки = '"' + ''.join(
                chr(байт) if 32 <= байт < 127 and байт not in (34, 92)
                else '\\' + format(байт, '03o')
                for байт in путь.encode('utf-8')
            ) + '"'
            строки.append(код + ' ' + кавычки)
            пути.add(путь)
    return байты, '\n'.join(строки), sorted(пути)


def состояние_пути(путь):
    try: метаданные = путь.lstat()
    except FileNotFoundError: return {'тип': 'отсутствует'}
    if stat.S_ISDIR(метаданные.st_mode):
        return {'тип': 'каталог', 'имена_sha256': хэш(json.dumps(sorted(э.name for э in путь.iterdir()), ensure_ascii=True).encode())}
    if not stat.S_ISREG(метаданные.st_mode): raise ValueError('Цель не является обычным файлом или каталогом')
    return {'тип': 'файл', 'режим': stat.S_IMODE(метаданные.st_mode), 'sha256': хэш(путь.read_bytes())}


def прочитать_охват(корень, запрос, строки, проверенный_путь):
    путь_запроса = проверенный_путь(запрос)
    путь_отчёта = путь_запроса.with_name('отчёт.md')
    исходные_байты = путь_запроса.read_bytes()
    текст = исходные_байты.decode('utf-8')
    структурный = СВЯЗНОСТЬ.markdown_structural_text(текст)
    if структурный.splitlines().count('## Повлиял на файлы') != 1:
        raise ValueError('Требуется единственный раздел «Повлиял на файлы»')
    for совпадение in СВЯЗНОСТЬ.MARKDOWN_LINK_RE.finditer(СВЯЗНОСТЬ.section_body(текст, 'Повлиял на файлы') or ''):
        ссылка_материала = СВЯЗНОСТЬ.MarkdownLink(путь_запроса, 1, совпадение.group(2))
        if СВЯЗНОСТЬ.is_external_link(ссылка_материала.target): continue
        цель = unquote(СВЯЗНОСТЬ.strip_link_title(ссылка_материала.target).strip()).split('#', 1)[0].split('?', 1)[0]
        if not цель: continue
        if СВЯЗНОСТЬ.is_absolute_local_markdown_link(цель):
            raise ValueError('Абсолютная локальная Markdown-цель запрещена')
        лексический = путь_запроса.parent
        for часть in Path(цель).parts:
            if часть == '..':
                лексический = лексический.parent
                if not лексический.is_relative_to(корень): raise ValueError('Markdown-цель выходит за корень')
            elif часть != '.':
                лексический = лексический / часть
                проверенный_путь(лексический.relative_to(корень).as_posix())
    состав, ошибки = СВЯЗНОСТЬ.affected_files_from_request(текст, путь_запроса, корень)
    for путь, роль in ((путь_запроса, 'запрос'), (путь_отчёта, 'отчёт')):
        if путь not in состав: ошибки.append(f'Нет прямой ссылки на текущий {роль}: {путь.relative_to(корень)}')
        if not путь.is_file(): ошибки.append(f'Нет текущего файла: {путь.relative_to(корень)}')
    цели = set(состав) | состав.existing_directories | состав.deleted_subtrees | состав.deleted_direct_files_directories
    for путь in цели:
        if путь == корень: raise ValueError('Охват корня репозитория запрещён')
        проверенный_путь(путь.relative_to(корень).as_posix())
    # Проверяются активные ссылки только текущего запроса, не весь репозиторий.
    ошибки.extend(СВЯЗНОСТЬ.validate_markdown_links({путь_запроса}, корень))
    ошибки.extend(СВЯЗНОСТЬ.validate_git_status(корень, состав, строки))
    return путь_запроса, путь_отчёта, исходные_байты, цели, ошибки


def сверить(корень, запрос, разрешённые):
    корень = Path(корень).resolve()
    кэш_каталогов = {}
    def проверенный_путь(имя):
        return точный_путь(корень, имя, кэш_каталогов)
    if Path(os.fsdecode(выполнить_git(корень, 'rev-parse', '--show-toplevel')).strip()).resolve() != корень:
        raise ValueError('Нужен физический корень собственного checkout')
    ссылка = выполнить_git(корень, 'symbolic-ref', 'HEAD').decode().strip()
    вершина = выполнить_git(корень, 'rev-parse', 'HEAD').decode().strip()
    статус, строки, пути = прочитать_статус(корень)
    индекс = хэш(выполнить_git(корень, 'ls-files', '--stage', '-z'))
    if not isinstance(разрешённые, list) or any(not isinstance(э, str) for э in разрешённые) or len(set(разрешённые)) != len(разрешённые):
        raise ValueError('Разрешённые цели должны быть массивом уникальных точных путей')
    for имя in разрешённые:
        if проверенный_путь(имя).is_dir(): raise ValueError(f'Разрешение каталога вместо конечного состава: {имя}')
    путь_запроса, путь_отчёта, исходные_байты, цели, ошибки = прочитать_охват(корень, запрос, строки, проверенный_путь)
    ошибки.extend(f'Путь вне разрешённого состава: {имя}' for имя in пути if имя not in разрешённые)
    входы = set(пути) | set(разрешённые) | {запрос, путь_отчёта.relative_to(корень).as_posix()}
    входы.update(путь.relative_to(корень).as_posix() for путь in цели)
    снимок = {
        'корень_sha256': хэш(os.fsencode(корень)), 'ref': ссылка, 'HEAD': вершина,
        'статус_sha256': хэш(статус), 'индекс_sha256': индекс,
        'разрешённые_цели': sorted(разрешённые),
        'входы': {имя: состояние_пути(проверенный_путь(имя)) for имя in sorted(входы)},
        'проверяющий_sha256': хэш(Path(__file__).read_bytes()),
        'связность_sha256': хэш(Path(СВЯЗНОСТЬ.__file__).read_bytes()),
    }
    корень_исполнителя = Path(__file__).resolve().parents[3]
    снимок['модули'] = {
        Path(модуль.__file__).resolve().relative_to(корень_исполнителя).as_posix(): хэш(Path(модуль.__file__).read_bytes())
        for модуль in list(sys.modules.values())
        if getattr(модуль, '__file__', None)
        and Path(модуль.__file__).resolve().is_relative_to(корень_исполнителя)
        and Path(модуль.__file__).is_file()
    }
    повторные_входы = {имя: состояние_пути(проверенный_путь(имя)) for имя in sorted(входы)}
    if (путь_запроса.read_bytes() != исходные_байты
            or повторные_входы != снимок['входы']
            or хэш(выполнить_git(корень, 'ls-files', '--stage', '-z')) != снимок['индекс_sha256']
            or выполнить_git(корень, 'symbolic-ref', 'HEAD').decode().strip() != ссылка
            or прочитать_статус(корень)[0] != статус
            or выполнить_git(корень, 'rev-parse', 'HEAD').decode().strip() != вершина):
        ошибки.append('Вход изменился во время сверки')
    return {'схема': 'fum.ранний-охват.1', 'запрос': запрос, 'пути': пути, 'снимок': снимок, 'ошибки': ошибки, 'готов': not ошибки}


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--корень-репозитория', type=Path, required=True)
    парсер.add_argument('--запрос', required=True)
    парсер.add_argument('--разрешённые-цели', type=Path, required=True)
    парсер.add_argument('--снимок', type=Path)
    парсер.add_argument('--профиль', action='store_true')
    аргументы = парсер.parse_args()
    начало = time.monotonic_ns()
    try:
        байты_разрешения = аргументы.разрешённые_цели.read_bytes()
        разрешённые = json.loads(байты_разрешения)
        результат = сверить(аргументы.корень_репозитория, аргументы.запрос, разрешённые)
        результат['снимок']['разрешение_sha256'] = хэш(байты_разрешения)
        if аргументы.разрешённые_цели.read_bytes() != байты_разрешения:
            raise ValueError('Разрешённый состав изменился во время сверки')
        if аргументы.снимок:
            прежний = json.loads(аргументы.снимок.read_bytes())
            if прежний != результат or прежний.get('готов') is not True:
                результат['ошибки'].append('Дрейф или неуспешный прежний снимок: нужна новая сверка')
                результат['готов'] = False
        код = 0 if результат['готов'] else 1
    except (OSError, ValueError, subprocess.CalledProcessError, StopIteration) as ошибка:
        результат = {'схема': 'fum.ранний-охват.1', 'готов': False, 'ошибки': [str(ошибка)]}
        код = 1
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2))
    if аргументы.профиль:
        print(json.dumps({'стадия': 'ранняя сверка', 'наносекунды': time.monotonic_ns()-начало, 'код': код}, ensure_ascii=False), file=sys.stderr)
    return код


if __name__ == '__main__':
    raise SystemExit(выполнить())
