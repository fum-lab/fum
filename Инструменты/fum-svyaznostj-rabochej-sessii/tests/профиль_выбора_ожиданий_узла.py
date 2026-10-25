"""Три новых читающих процесса; создание Git-фикстуры исключено."""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time
import tracemalloc

КАТАЛОГ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(КАТАЛОГ/'scripts'))
import выбор_ожиданий_узла as выбор


def рабочий_процесс(путь):
    вход = json.loads(путь.read_bytes())
    профиль = {}
    tracemalloc.start()
    итог = выбор.построить(вход['выбор'], корень=Path(вход['корень']), профиль=профиль)
    _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
    assert not итог['допуск_эффекта'] and профиль['реальных_API'] == 0
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['кандидат']),
        'профиль': профиль, 'python_пик_байты': пик}, ensure_ascii=False, sort_keys=True))


def выполнить():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--рабочий', type=Path)
    разбор.add_argument('--выход', type=Path)
    разбор.add_argument('--повторов', type=int, default=3)
    а = разбор.parse_args()
    if а.рабочий:
        рабочий_процесс(а.рабочий); return
    if а.выход is None or not 3 <= а.повторов <= 20:
        разбор.error('Нужен выход и от 3 до 20 новых процессов')
    from test_выбор_ожиданий_узла import ВыборОжиданий, байты
    пример = ВыборОжиданий(); пример.setUp()
    try:
        for n in range(2, 7):
            задача = '00000000-0000-0000-0000-' + f'{n:012d}'
            р = copy.deepcopy(пример.решение)
            р.update(задача=задача, владелец=задача, поручение=пример.с.акт(задача))
            пример.вход['решения'].append(пример.с.сохранить(f'решение-{n}.json', байты(р)))
        вход = пример.с.папка/'профильный-вход.json'
        вход.write_bytes(байты({'корень': str(пример.с.репо), 'выбор': пример.вход})); вход.chmod(0o600)
        до = пример.снимок()
        замеры = []
        for _ in range(а.повторов):
            начало = time.monotonic_ns()
            ответ = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()),
                '--рабочий', str(вход)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
            замер = json.loads(ответ.stdout); замер['процесс_наносекунды'] = time.monotonic_ns()-начало
            замеры.append(замер)
        assert all(з['sha256'] == замеры[0]['sha256'] and з['профиль']['выбрано_задач'] == 6 for з in замеры)
        assert пример.снимок() == до
        исходники = ['scripts/выбор_ожиданий_узла.py', 'scripts/построить_ожидания_узла.py',
            'tests/test_выбор_ожиданий_узла.py', 'tests/профиль_выбора_ожиданий_узла.py']
        итог = {'схема': 'fum.профиль-выбора-ожиданий-узла.1', 'повторы': а.повторов,
            'замеры': замеры, 'медианы': {к: statistics.median(з['профиль'][к] for з in замеры)
                for к in ('доверие_наносекунды', 'выбор_наносекунды', 'проверка_наносекунды',
                    'повтор_ref_наносекунды', 'всего_наносекунды')},
            'медиана_процесса_наносекунды': statistics.median(з['процесс_наносекунды'] for з in замеры),
            'исходники_sha256': {п: hashlib.sha256((КАТАЛОГ/п).read_bytes()).hexdigest() for п in исходники},
            'байты_Git_не_изменены': True, 'реальных_API': 0, 'допуск_эффекта': False,
            'граница': 'Синтетический конечный перечень шести решений; настоящие локальные Git-объекты. Подготовка фикстуры исключена. Процесс включает запуск Python и импорты; вложенные фазы не суммируются. tracemalloc измеряет только Python; память Git неизвестна. Кэш ОС не очищается. Это не живое наблюдение задач и не запись ветки состояния.',
            'решение_об_оптимизации': 'Кандидат проходит общий валидатор один раз; второй предпросмотр не вычисляется для того же результата. Повторная сверка доверенного ref сохраняется. Новые API, кэш полномочий и обход проверок не вводятся.'}
        выход = а.выход
        assert выход.is_absolute() and выход.parent.resolve() == выход.parent
        assert not any((п/'.git').exists() for п in (выход.parent, *выход.parents))
        fd = os.open(выход, os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, 'wb') as поток: поток.write(байты(итог))
        print(json.dumps({'медианы': итог['медианы'], 'повторы': а.повторов,
            'процесс_наносекунды': итог['медиана_процесса_наносекунды'], 'реальных_API': 0}, ensure_ascii=False))
    finally:
        пример.doCleanups()


if __name__ == '__main__':
    выполнить()
