"""Конечный AST прежних функций, без новой грамматики и внешних импортов."""
import ast
import builtins
import __future__
from dataclasses import dataclass
from pathlib import Path, PurePosixPath, PureWindowsPath
import posixpath
import re
import stat
from types import SimpleNamespace
from urllib.parse import unquote
from .модель import НеполныйСнимок

КОРЕНЬ = Path(__file__).resolve().parents[4]
ПРЕЖНИЙ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py'
ИНВЕНТАРЬ = 'Инструменты/fum-proyektnyiye-fajlyi/scripts/project_files.py'
ЛЕКСЕР = 'Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py'
ДВИЖОК = 'Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py'
ИМЕНА_ПРЕЖНИЕ = ('MARKDOWN_LINK_RE', 'REQUEST_STEM_RE', 'JOURNAL_DIRECTORY',
    'REQUEST_FILENAME', 'MARKDOWN_TILDE_FENCE_MARKER', 'ЧАСТИ_КАТАЛОГА_CHATGPT_SHARE',
    'МАРКЕР_НАЧАЛА_ДОСЛОВНОГО_ДИАЛОГА', 'МАРКЕР_КОНЦА_ДОСЛОВНОГО_ДИАЛОГА',
    'MarkdownLink', 'MarkdownFence', 'absolute_path', 'repo_relative', 'read_text',
    'is_request_file', 'strip_link_title', 'is_external_link',
    'is_absolute_local_markdown_link', 'opening_markdown_fence', 'closes_markdown_fence',
    'iter_markdown_links', 'resolve_markdown_target', 'actual_case_path',
    'request_text_line_span', 'диапазон_дословного_диалога_chatgpt',
    'отсутствует_необязательный_граф', 'validate_markdown_links')
ИМЕНА_ИНВЕНТАРЯ = ('STRUCTURAL_EXCLUDED_DIRECTORY_NAMES', 'CACHE_DIRECTORY_SUFFIXES',
    'STRUCTURAL_EXCLUDED_PATH_PREFIXES', 'is_excluded_directory_name',
    '_directory_parts_are_excluded', 'is_structurally_excluded', '_lexical_absolute',
    'is_structurally_excluded_path')


def выделить(байты, имена):
    дерево = ast.parse(байты.decode('utf-8'))
    выбранные = []
    найденные = []
    for узел in дерево.body:
        имя = getattr(узел, 'name', None)
        if isinstance(узел, ast.Assign) and len(узел.targets) == 1 and isinstance(узел.targets[0], ast.Name):
            имя = узел.targets[0].id
        if имя in имена:
            выбранные.append(узел); найденные.append(имя)
    if set(найденные) != set(имена) or len(найденные) != len(имена):
        raise НеполныйСнимок('замыкание прежнего поднабора изменилось')
    модуль = ast.Module(body=[ast.ImportFrom(module='__future__', names=[ast.alias(name='annotations')], level=0), *выбранные], type_ignores=[])
    ast.fix_missing_locations(модуль)
    return compile(модуль, '<закреплённый поднабор>', 'exec')


def пространство(путь, код):
    # В снимке код — данные. Исполняется только равный источникам загрузки поднабор.
    from . import КОД_ЗАГРУЗКИ, ИСПОЛНЯЕМЫЙ_ПОДНАБОР
    if tuple(код) != КОД_ЗАГРУЗКИ:
        raise НеполныйСнимок('исполняемый код не совпал с закреплённым')
    def импорт(имя, *аргументы, **именованные):
        if имя != '__future__': raise НеполныйСнимок('импорт за пределами закреплённого поднабора')
        return __future__
    имена = ('__build_class__', 'next', 'len', 'enumerate', 'sorted', 'tuple', 'set',
        'frozenset', 'dict', 'list', 'str', 'int', 'bool', 'any', 'range',
        'isinstance', 'chr', 'ValueError', 'OSError', 'FileNotFoundError')
    встроенные = {имя: getattr(builtins, имя) for имя in имена}
    встроенные['__import__'] = импорт
    словарь = {'__name__': __name__, '__builtins__': встроенные,
        'Path': путь, 'PurePosixPath': PurePosixPath,
        'PureWindowsPath': PureWindowsPath, 're': re, 'stat': stat, 'unquote': unquote,
        'dataclass': dataclass, 'os': SimpleNamespace(path=posixpath, fspath=str)}
    for объект_кода in ИСПОЛНЯЕМЫЙ_ПОДНАБОР:
        exec(объект_кода, словарь)
    return словарь
