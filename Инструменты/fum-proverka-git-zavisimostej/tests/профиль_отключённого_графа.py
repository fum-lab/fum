#!/usr/bin/env python3
"""Парный профиль старого и нового допуска на одинаковых автономных копиях."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import tempfile
import time
from unittest import mock

from test_отключённый_граф_libtorrent import ФикстураГрафа
from test_proveritj_git_zavisimostj import GitDependencyFixture
from test_подготовка_зависимостей import загрузить_подготовку


def измерить(модуль, корень, путь):
    настоящий = модуль.исходный.run_git
    чтения = []
    def наблюдать(*аргументы, **параметры):
        начало = time.monotonic_ns()
        try:
            return настоящий(*аргументы, **параметры)
        finally:
            чтения.append(time.monotonic_ns()-начало)
    начало = time.monotonic_ns()
    with mock.patch.object(модуль.исходный, 'run_git', side_effect=наблюдать):
        итог = модуль.проверить_готовность_зависимости(корень, путь)
    return {'весь_допуск_наносекунды': time.monotonic_ns()-начало,
        'чтения_гит_наносекунды': sum(чтения), 'читающих_вызовов': len(чтения),
        'состояние': итог['состояние']}


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--база', required=True)
    разбор.add_argument('--выход', required=True)
    разбор.add_argument('--повторов', type=int, default=3)
    параметры = разбор.parse_args()
    выход = Path(параметры.выход)
    if выход.exists() or параметры.повторов < 1:
        raise ValueError('нужен новый выход и положительное число повторов')
    корень = Path(__file__).resolve().parents[3]
    текущий = загрузить_подготовку()
    with tempfile.TemporaryDirectory(prefix='fum-профиль-графа-') as временный:
        каталог = Path(временный).resolve()
        старый_каталог = каталог/'старая-версия'; старый_каталог.mkdir()
        хэши_базы = {}
        for имя in ('подготовка_зависимостей.py', 'proveritj-git-zavisimostj.py'):
            команда = ['git', '--no-optional-locks', 'show',
                параметры.база+':Инструменты/fum-proverka-git-zavisimostej/scripts/'+имя]
            байты = subprocess.run(команда, cwd=корень, check=True, stdout=subprocess.PIPE).stdout
            (старый_каталог/имя).write_bytes(байты)
            хэши_базы[имя] = hashlib.sha256(байты).hexdigest()
        описание = importlib.util.spec_from_file_location('старый_допуск_графа', старый_каталог/'подготовка_зависимостей.py')
        старый = importlib.util.module_from_spec(описание); sys.modules[описание.name]=старый
        описание.loader.exec_module(старый)
        простой_каталог = каталог/'обычная'; простой_каталог.mkdir()
        простая = GitDependencyFixture(простой_каталог)
        assert простая.add_dependency() == []
        граф_каталог = каталог/'граф'; граф_каталог.mkdir()
        граф = ФикстураГрафа(граф_каталог)
        try:
            # Подмена идентичности только на полную реальную ревизию открытой Git-фикстуры.
            текущий.ПОЛИТИКА_ТОРРЕНТА = граф.политика
            до = текущий.снять_снимок(граф.корень)
            результаты = {'обычная': {'до': [], 'после': []}, 'граф': {'до': [], 'после': []}}
            for повтор in range(параметры.повторов):
                версии = [('до',старый),('после',текущий)]
                if повтор % 2: версии.reverse()
                for имя, модуль in версии:
                    for сценарий, дерево, путь in [('обычная',простая.superproject,простая.path),
                            ('граф',граф.корень,граф.база.path)]:
                        результаты[сценарий][имя].append(измерить(модуль,дерево,путь))
            assert текущий.снять_снимок(граф.корень) == до
            for имя in ('до','после'):
                assert {з['состояние'] for з in результаты['обычная'][имя]} == {'готова'}
            assert {з['состояние'] for з in результаты['граф']['до']} == {'вложенные_зависимости'}
            assert {з['состояние'] for з in результаты['граф']['после']} == {'готова'}
            текущий.проверить_код(); старый.проверить_код()
            данные = {'схема':'fum.профиль-отключённого-графа.1', 'база':параметры.база,
                'код_до':хэши_базы,'код_после':текущий.ОТПЕЧАТОК_КОДА,
                'измеритель_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'фикстура_sha256':hashlib.sha256(Path(__file__).with_name('test_отключённый_граф_libtorrent.py').read_bytes()).hexdigest(),
                'интерпретатор':sys.version,'архитектура':platform.machine(),'повторов':параметры.повторов,
                'внешняя_сеть':False,'защищённый_снимок_сохранён':True,'измерения':результаты,
                'граница':'Подготовка копий и запись выхода исключены; Git-чтения включены в весь допуск и не суммируются повторно; порядок чередуется; кэш ОС не очищается. Граф синтетический; live-регистрация не выполняется.'}
            выход.write_text(json.dumps(данные,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
            for сценарий in результаты:
                print(сценарий, {имя:statistics.median(з['весь_допуск_наносекунды']/1e9 for з in результаты[сценарий][имя]) for имя in ('до','после')})
        finally:
            граф.закрыть()


if __name__ == '__main__':
    выполнить()
