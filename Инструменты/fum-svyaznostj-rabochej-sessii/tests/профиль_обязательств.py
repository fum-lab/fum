"""Воспроизводимый профиль CLI на изолированных Git-историях; без сети."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import time

sys.dont_write_bytecode = True
from test_обязательства_задачи_v2 import КОРЕНЬ, ОбязательстваЗадачи


def отпечатки():
    навык = КОРЕНЬ / 'Инструменты/fum-svyaznostj-rabochej-sessii'
    пути = [Path(__file__), Path(__file__).with_name('test_обязательства_задачи_v2.py'),
            Path(__file__).with_name('исходник_проверки.py')]
    пути += [навык / 'scripts' / имя for имя in ('обязательства_задачи.py', 'обязательства_задачи_v2.py',
        'история_пути_гита.py', 'проверить-продолжение-задачи.py', 'обработка_сообщений.py', 'сообщения_задачи.py')]
    пути += [КОРЕНЬ / 'Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts' / имя for имя in (
        'закрытый_отчёт_из_гита.py', 'связь_отпечатка_с_коммитом.py', 'отчёты_о_запусках_проверок.py')]
    пути += [КОРЕНЬ / 'Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py']
    return {путь.relative_to(КОРЕНЬ).as_posix(): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in пути}


def выполнить():
    параметры = argparse.ArgumentParser(description=__doc__)
    параметры.add_argument('--вывод', type=Path, required=True)
    параметры.add_argument('--коммитов', type=int, default=100)
    параметры.add_argument('--повторов', type=int, default=3)
    аргументы = параметры.parse_args()
    if аргументы.коммитов < 2 or аргументы.повторов < 1:
        параметры.error('требуются хотя бы два коммита и один повтор')
    исходники = отпечатки()
    сценарии = []
    for название, количество, приёмка, код in [('остаток', 40, False, 3), ('приёмка', 1, True, 0)]:
        случай = ОбязательстваЗадачи()
        try:
            случай.подготовить()
            for номер in range(1, количество):
                дополнительное = copy.deepcopy(случай.реестр['обязательства'][0])
                дополнительное['идентификатор'] = f'результат-{номер}'
                случай.реестр['обязательства'].append(дополнительное)
            случай.сохранить()
            for номер in range(аргументы.коммитов):
                случай.записать('этап.txt', str(номер) + '\n')
                случай.коммит()
            if приёмка:
                случай.принять()
                случай.коммит()
            замеры = []
            for _ in range(аргументы.повторов):
                до = случай.гит('status', '--porcelain=v1', '--untracked-files=all')
                начало = time.perf_counter_ns()
                ответ = случай.вызвать('--профиль')
                длительность = time.perf_counter_ns() - начало
                if ответ.returncode != код:
                    raise AssertionError(ответ.stderr + ответ.stdout)
                после = случай.гит('status', '--porcelain=v1', '--untracked-files=all')
                if до != после:
                    raise AssertionError('профилируемый вызов изменил Git-состояние')
                профиль = json.loads(next(строка.removeprefix('FUM-PROFILE ') for строка in ответ.stderr.splitlines()
                                         if строка.startswith('FUM-PROFILE ')))
                замеры.append({'внешнее_время_нс': длительность, 'профиль': профиль,
                               'решение': json.loads(ответ.stdout)['решение']})
            сценарии.append({'имя': название, 'обязательств': количество, 'коммитов_этапа': аргументы.коммитов,
                             'повторов': аргументы.повторов, 'замеры': замеры,
                             'медиана_нс': statistics.median(замер['внешнее_время_нс'] for замер in замеры)})
        finally:
            случай.doCleanups()
    if исходники != отпечатки():
        raise AssertionError('код изменился во время профиля')
    результат = {'схема': 'fum.профиль-обязательств.1', 'python': platform.python_version(),
                 'git': subprocess.run(['git', '--version'], check=True, capture_output=True, text=True).stdout.strip(),
                 'условия': 'Изолированные временные репозитории без зависимостей; отдельный процесс CLI на каждый замер; прогрев не исключён.',
                 'версии_кода': исходники,
                 'сценарии': сценарии}
    аргументы.вывод.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    for сценарий in сценарии:
        print(f'{сценарий["имя"]}: медиана {сценарий["медиана_нс"] / 1e9:.6f} с')


if __name__ == '__main__':
    выполнить()
