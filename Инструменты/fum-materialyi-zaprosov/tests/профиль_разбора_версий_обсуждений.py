"""Три пары свежих автономных процессов на ста синтетических комментариях."""
import argparse
import builtins
from contextlib import ExitStack
import hashlib
import importlib.util
import importlib.abc
import io
import json
import os
from pathlib import Path
import platform
import socket
import subprocess
import sys
import tempfile
import time
import types
from unittest.mock import patch


def загрузить(имя, путь, закрепления=None):
    модуль = types.ModuleType(имя); модуль.__file__ = str(путь)
    сырые = путь.read_bytes()
    if закрепления is not None:
        pin = закрепления[str(путь)]
        assert hashlib.sha256(сырые).hexdigest() == pin['sha256'] and путь.stat().st_mode == pin['режим']
    exec(compile(сырые, str(путь), 'exec'), модуль.__dict__)
    return модуль


каталог = Path(__file__).resolve().parent
фикстуры = None


def закрепить_импорты(закрепления):
    прежний = importlib.util.spec_from_file_location
    class Загрузчик(importlib.abc.Loader):
        def __init__(self, путь): self.путь = Path(путь)
        def create_module(self, описание): return None
        def exec_module(self, модуль):
            сырые = self.путь.read_bytes(); pin = закрепления[str(self.путь)]
            assert hashlib.sha256(сырые).hexdigest() == pin['sha256'] and self.путь.stat().st_mode == pin['режим']
            модуль.__file__ = str(self.путь)
            exec(compile(сырые, str(self.путь), 'exec'), модуль.__dict__)
    def спецификация(имя, путь, *а, **п):
        путь = str(Path(путь).resolve())
        if путь in закрепления:
            return прежний(имя, путь, loader=Загрузчик(путь))
        return прежний(имя, путь, *а, **п)
    return patch.object(importlib.util, 'spec_from_file_location', спецификация)


def сверить_исходники(закрепления):
    for адрес, pin in закрепления.items():
        п = Path(адрес)
        assert п == п.resolve() and п.stat().st_mode == pin['режим']
        assert hashlib.sha256(п.read_bytes()).hexdigest() == pin['sha256']


def работник(база, режим, закрепления, закрепления_sha256):
    global фикстуры
    сверить_исходники(закрепления)
    with закрепить_импорты(закрепления):
        фикстуры = загрузить('фикстуры_профиля_покрытия', каталог / 'test_разбора_версий_обсуждений.py', закрепления)
    счётчики = {'API': 0, 'записи': 0}
    def API(*а, **п):
        счётчики['API'] += 1; raise AssertionError('Сетевой или внешний процесс в измеряемой части')
    def мутация(*а, **п):
        счётчики['записи'] += 1; raise AssertionError('Запись в измеряемой части')
    открыть = os.open
    def открытие(путь, флаги, *а, **п):
        if флаги & (os.O_CREAT | os.O_WRONLY | os.O_RDWR | os.O_TRUNC | os.O_APPEND): мутация()
        return открыть(путь, флаги, *а, **п)
    def текстовое(исходное):
        def функция(путь, режим='r', *а, **п):
            if any(ч in режим for ч in 'wax+'): мутация()
            return исходное(путь, режим, *а, **п)
        return функция
    with ExitStack() as стек:
        стек.enter_context(закрепить_импорты(закрепления))
        for объект, имя, функция in [(socket, 'socket', API), (subprocess, 'Popen', API),
            (os, 'open', открытие), (builtins, 'open', текстовое(builtins.open)),
            (io, 'open', текстовое(io.open)), *[(os, и, мутация) for и in ('mkdir', 'unlink', 'rename', 'replace')]]:
            стек.enter_context(patch.object(объект, имя, функция))
        описание = importlib.util.spec_from_file_location('разбор_профиля', каталог.parent / 'scripts/разбор_версий_обсуждений.py')
        модуль = importlib.util.module_from_spec(описание); описание.loader.exec_module(модуль)
        результаты = []
        for _ in range(2):
            cpu = time.process_time_ns(); начало = time.perf_counter_ns()
            план = модуль.план(база / 'архив', фикстуры.репозиторий, база / 'внимание', база / 'покрытия',
                '7', фикстуры.контекст, фикстуры.основания, фикстуры.сейчас, полный=режим == 'А')
            длительность = time.perf_counter_ns() - начало; процессор = time.process_time_ns() - cpu
            результаты.append({'wall_нс': длительность, 'CPU_нс': процессор,
                'выбор_sha256': план['выбор_sha256'], 'план_sha256': модуль.хэш(план),
                'единиц': len(план['единицы']), 'переиспользовано': len(план['переиспользованы']),
                'полнота': план['полнота'], 'внимание': план['внимание']})
        assert результаты[0]['план_sha256'] == результаты[1]['план_sha256']
    сверить_исходники(закрепления)
    return {'режим': режим, 'PID': os.getpid(), 'закрепления_sha256': закрепления_sha256, 'первый': результаты[0],
        'тот_же_процесс': результаты[1], 'эффекты': счётчики}


def измерить(временный_корень, RAW):
    global фикстуры
    исходники = [каталог / 'test_разбора_версий_обсуждений.py', Path(__file__).resolve(),
        *[каталог.parent / 'scripts' / и for и in ('разбор_версий_обсуждений.py',
            'внимание_к_обсуждениям_GitHub.py', 'архив_обсуждений_GitHub.py')]]
    закрепления = {str(п): {'sha256': hashlib.sha256(п.read_bytes()).hexdigest(), 'режим': п.stat().st_mode} for п in исходники}
    with закрепить_импорты(закрепления):
        фикстуры = загрузить('фикстуры_профиля_покрытия', каталог / 'test_разбора_версий_обсуждений.py', закрепления)
    RAW = фикстуры.внимание._путь(RAW, вне_репозитория=True); RAW.mkdir(mode=0o700)
    pins = RAW / 'исходники.json'; pins.write_bytes(фикстуры.внимание._байты(закрепления)); pins.chmod(0o400)
    pins_raw = pins.read_bytes(); pins_sha256 = hashlib.sha256(pins_raw).hexdigest()
    boot = """import hashlib, pathlib, sys
p=pathlib.Path(sys.argv[1]); raw=p.read_bytes()
assert hashlib.sha256(raw).hexdigest()==sys.argv[2] and p.stat().st_mode==int(sys.argv[3])
sys.argv=[str(p),*sys.argv[4:]]
exec(compile(raw,str(p),'exec'),{'__name__':'__main__','__file__':str(p)})
"""
    with tempfile.TemporaryDirectory(prefix='профиль-покрытия-', dir=временный_корень) as имя:
        база = Path(имя).resolve(); (база / 'архив').mkdir()
        модуль = загрузить('подготовка_профиля', каталог.parent / 'scripts/разбор_версий_обсуждений.py')
        комментарии = [фикстуры.комментарий(1000 + и, 'Синтетическое замечание ' + str(и)) for и in range(100)]
        фикстуры.сохранить_архив(база / 'архив', 'до', комментарии[:-1])
        план = модуль.план(база / 'архив', фикстуры.репозиторий, база / 'внимание', база / 'покрытия',
            '7', фикстуры.контекст, фикстуры.основания, фикстуры.сейчас)
        модуль.решение(база / 'архив', фикстуры.репозиторий, база / 'внимание', база / 'покрытия',
            фикстуры.вход_оператора(план))
        фикстуры.сохранить_архив(база / 'архив', 'после', комментарии)
        до = фикстуры.снимок_файлов(база)
        снимок_sha256 = модуль.хэш({п: д[0] for п, д in до.items()})
        пары = []
        for порядок in [('А', 'Б'), ('Б', 'А'), ('А', 'Б')]:
            запуски = []
            for режим in порядок:
                сверить_исходники(закрепления)
                номер = sum(len(п) for п in пары) + len(запуски) + 1
                свой = закрепления[str(Path(__file__).resolve())]
                argv = [sys.executable, '-I', '-S', '-B', '-c', boot, str(Path(__file__).resolve()),
                    свой['sha256'], str(свой['режим']), '--работник', str(база), режим, str(pins), pins_sha256]
                процесс = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                stdout, stderr = процесс.communicate()
                for имя, сырьё in [('stdout', stdout), ('stderr', stderr)]:
                    файл = RAW / f'{номер}-{имя}.bin'; файл.write_bytes(сырьё); файл.chmod(0o600)
                вызов = фикстуры.внимание._байты({'argv': argv, 'PID': процесс.pid, 'код_завершения': процесс.returncode})
                файл = RAW / f'{номер}-вызов.json'; файл.write_bytes(вызов); файл.chmod(0o600)
                assert процесс.returncode == 0 and stderr == b'', stderr
                запись = json.loads(stdout); assert запись['PID'] == процесс.pid
                assert запись['закрепления_sha256'] == pins_sha256 and pins.read_bytes() == pins_raw
                запись['RAW'] = {и: {'байты': len(с), 'sha256': hashlib.sha256(с).hexdigest()}
                    for и, с in [('stdout', stdout), ('stderr', stderr), ('вызов', вызов)]}
                запуски.append(запись); сверить_исходники(закрепления)
            пары.append(запуски)
        assert до == фикстуры.снимок_файлов(база)
        запуски = [з for п in пары for з in п]
        assert len({з['первый']['выбор_sha256'] for з in запуски}) == 1
        for режим, число in [('А', 101), ('Б', 1)]:
            выбранные = [з for з in запуски if з['режим'] == режим]
            assert len({з['первый']['план_sha256'] for з in выбранные}) == 1
            assert all(з['первый']['единиц'] == число and з['первый']['полнота'] and з['первый']['внимание']
                and з['эффекты'] == {'API': 0, 'записи': 0} for з in выбранные)
        assert len({з['PID'] for з in запуски}) == 6
        сверить_исходники(закрепления)
        for и, з in enumerate(запуски, 1):
            for канал, мета in з['RAW'].items():
                сырые = (RAW / (f'{и}-вызов.json' if канал == 'вызов' else f'{и}-{канал}.bin')).read_bytes()
                assert len(сырые) == мета['байты'] and hashlib.sha256(сырые).hexdigest() == мета['sha256']
        assert pins.read_bytes() == pins_raw and pins.stat().st_mode & 0o777 == 0o400
        return {'схема': 'fum.профиль-разбора-версий-обсуждений.1', 'Python': platform.python_version(),
            'платформа': platform.system() + ' ' + platform.machine(), 'синтетических_комментариев': 100,
            'снимок_sha256': снимок_sha256, 'закрепления_sha256': pins_sha256,
            'исходники': {Path(п).name: pin for п, pin in закрепления.items()},
            'пары': пары, 'неизменность_файлов': True,
            'границы': ['Подготовка, первоначальная загрузка helper/subject и запуск интерпретатора исключены из wall/CPU; повторные импорты внутри плана входят.',
                'Шесть свежих процессов последовательно; А — полный план, Б — адресный остаток.',
                'В каждом процессе есть повтор; кэш ОС не очищался.',
                'Это синтетический выбор единиц, без смыслового разбора, сети и модели.',
                'Токены, реальное Issue 151 и полная скорость агента не измеряются.'],
            'решение': 'Сохранить адресный выбор; снижение единиц 101→1 не доказывает ускорения чтения архива.'}


if __name__ == '__main__':
    if sys.argv[1:2] == ['--работник']:
        сырые = Path(sys.argv[4]).read_bytes()
        assert hashlib.sha256(сырые).hexdigest() == sys.argv[5]
        print(json.dumps(работник(Path(sys.argv[2]), sys.argv[3], json.loads(сырые), sys.argv[5]), ensure_ascii=False))
    else:
        парсер = argparse.ArgumentParser(description=__doc__)
        парсер.add_argument('--временный-корень', type=Path, required=True)
        парсер.add_argument('--выход', type=Path, required=True)
        парсер.add_argument('--каталог-RAW', type=Path, required=True)
        а = парсер.parse_args()
        результат = измерить(а.временный_корень, а.каталог_RAW)
        with а.выход.open('x', encoding='utf-8') as поток:
            json.dump(результат, поток, ensure_ascii=False, sort_keys=True, indent=2); поток.write('\n')
        print(json.dumps({'схема': результат['схема'], 'пар': len(результат['пары']),
            'неизменность_файлов': True}, ensure_ascii=False))
