#!/usr/bin/env python3
"""Измерить автономные чтения отсутствующей и готовой Git-зависимости."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import tempfile
import time
from unittest import mock

from test_proveritj_git_zavisimostj import GitDependencyFixture, run_git
from test_подготовка_зависимостей import загрузить_подготовку


def измерить(корень, модуль, путь, повторов):
    снимок = модуль.снять_снимок(корень)
    настоящий = модуль.исходный.run_git
    команды = []

    def наблюдать(корень, *аргументы, **параметры):
        команды.append(аргументы)
        return настоящий(корень, *аргументы, **параметры)

    времена, состояния = [], []
    with mock.patch.object(модуль.исходный, 'run_git', side_effect=наблюдать):
        for _ in range(повторов):
            начало = time.monotonic_ns()
            итог = модуль.проверить_готовность_зависимости(корень, путь)
            времена.append((time.monotonic_ns() - начало) / 1_000_000_000)
            состояния.append(итог['состояние'])
    наблюдённые = [команда[1:] if команда[0] == '--literal-pathspecs' else команда for команда in команды]
    изменяющие = [команда for команда in наблюдённые
                 if команда[0] not in {'rev-parse', 'config', 'ls-files', 'hash-object',
                                      'status', 'remote', 'show-ref', 'cat-file', 'merge-base',
                                      'for-each-ref', 'diff', 'show', 'symbolic-ref'}
                 or (команда[0] == 'hash-object' and '-w' in команда)
                 or (команда[0] == 'config' and not any(флаг in команда for флаг in
                     {'--get', '--get-all', '--get-regexp', '--list'}))
                 or (команда[0] == 'remote' and len(команда) > 1 and команда[1] != 'get-url')]
    assert not изменяющие, изменяющие
    assert модуль.снять_снимок(корень) == снимок
    return {'секунды': времена, 'медиана_секунд': statistics.median(времена),
            'состояния': состояния, 'читающих_команд': len(команды), 'изменяющих_команд': 0,
            'защищённый_снимок_сохранён': True}


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выход', required=True)
    разбор.add_argument('--повторов', type=int, default=3)
    параметры = разбор.parse_args()
    if параметры.повторов < 1:
        raise ValueError('нужен хотя бы один повтор')
    with tempfile.TemporaryDirectory(prefix='fum-профиль-зависимостей-') as временный:
        фикстура = GitDependencyFixture(Path(временный).resolve())
        assert фикстура.add_dependency() == []
        фикстура.publish_dependency_registration()
        клон = фикстура.fresh_clone(recurse_submodules=False)
        корень = фикстура.root / 'рабочее-дерево'
        run_git('worktree', 'add', '-b', 'codex/профиль', str(корень), 'HEAD', cwd=клон)
        модуль = загрузить_подготовку()
        отсутствующая = измерить(корень, модуль, фикстура.path, параметры.повторов)
        исполнитель = '00000000-0000-0000-0000-000000000001'
        задача = '00000000-0000-0000-0000-000000000002'
        with mock.patch.dict(os.environ, {'CODEX_THREAD_ID': исполнитель}):
            модуль.подготовить_зависимости(корень, модуль.снять_снимок(корень), исполнитель, задача)
        готовая = измерить(корень, модуль, фикстура.path, параметры.повторов)
        assert set(отсутствующая['состояния']) == {'не_материализована'}
        assert set(готовая['состояния']) == {'готова'}
        данные = {'схема': 'fum.профиль-подготовки-зависимостей.1', 'повторов': параметры.повторов,
                  'отсутствующая': отсутствующая, 'готовая': готовая,
                  'внешняя_сеть': False, 'код': модуль.ОТПЕЧАТОК_КОДА,
                  'профиль_интерпретатора': os.sys.version,
                  'граница': 'Подготовка фикстуры и запись результата исключены; чтения Git включены; кэш ОС не очищается.'}
        выход = Path(параметры.выход)
        выход.parent.mkdir(parents=True, exist_ok=True)
        выход.write_text(json.dumps(данные, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(json.dumps({'выход': str(выход), 'sha256': hashlib.sha256(выход.read_bytes()).hexdigest(),
                          'медиана_отсутствующей': отсутствующая['медиана_секунд'],
                          'медиана_готовой': готовая['медиана_секунд']}, ensure_ascii=False))


if __name__ == '__main__':
    выполнить()
