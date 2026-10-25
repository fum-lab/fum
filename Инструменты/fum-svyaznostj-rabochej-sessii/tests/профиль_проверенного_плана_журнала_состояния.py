"""Исторический Git-план: три новых процесса, setup вне измерения."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time
import tracemalloc

КАТАЛОГ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(КАТАЛОГ/'scripts'))
import проверенный_план_журнала_состояния as читатель


def рабочий(путь):
    вход = json.loads(путь.read_bytes()); профиль = {}
    tracemalloc.start()
    итог = читатель.прочитать(вход['план'], корень=Path(вход['корень']), профиль=профиль)
    _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
    assert not итог['разрешение_установки'] and профиль['API'] == профиль['разборов_native'] == 0
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'профиль': профиль, 'python_пик_байты': пик}, ensure_ascii=False, sort_keys=True))


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--рабочий', type=Path)
    разбор.add_argument('--выход', type=Path)
    а = разбор.parse_args()
    if а.рабочий: рабочий(а.рабочий); return
    if а.выход is None: разбор.error('Нужен приватный выход профиля')
    from test_проверенного_плана_журнала_состояния import Пример, байты
    with tempfile.TemporaryDirectory(prefix='fum-checked-journal-profile-') as каталог:
        пример = Пример(каталог)
        вход = пример.ф.с.папка/'профильный-вход.json'
        вход.write_bytes(байты({'корень': str(пример.корень), 'план': пример.выбор})); вход.chmod(0o600)
        до = пример.снимок(); замеры = []
        for _ in range(3):
            начало = time.monotonic_ns()
            ответ = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()),
                '--рабочий', str(вход)], capture_output=True, check=True)
            замер = json.loads(ответ.stdout); замер['процесс_наносекунды'] = time.monotonic_ns()-начало
            замеры.append(замер)
        assert all(з['sha256'] == замеры[0]['sha256'] and з['профиль']['команд'] == 3 for з in замеры)
        assert пример.снимок() == до
        исходники = ['scripts/проверенный_план_журнала_состояния.py',
            'scripts/проверить_план_журнала_состояния.py',
            'tests/test_проверенного_плана_журнала_состояния.py',
            'tests/профиль_проверенного_плана_журнала_состояния.py']
        итог = {'схема': 'fum.профиль-проверенного-плана-журнала-состояния.1', 'повторы': 3,
            'замеры': замеры, 'медианы': {к: statistics.median(з['профиль'][к] for з in замеры)
                for к in ('история_наносекунды', 'каркас_и_повтор_наносекунды', 'всего_наносекунды')},
            'медиана_процесса_наносекунды': statistics.median(з['процесс_наносекунды'] for з in замеры),
            'исходники_sha256': {п: hashlib.sha256((КАТАЛОГ/п).read_bytes()).hexdigest() for п in исходники},
            'байты_Git_и_источников_не_изменены': True, 'API': 0, 'разборов_native': 0,
            'разрешение_установки': False,
            'граница': 'Малая фикстура: настоящие Git-объекты и закреплённый план трёх человеческих сообщений A,B,A. Подготовка Git и плана исключена. Процесс включает Python, импорты и выбор Git blob; внутренний профиль начинается после получения blob. Вложенные стадии не суммируются. tracemalloc измеряет только Python; память Git неизвестна. Кэш ОС не очищается. Живые API, установка пары и запись состояния не измеряются.',
            'решение_об_оптимизации': 'Исторический план читается по полному OID и сырому SHA без повторного расчёта native JSONL, нынешнего trust и карточек checkout. Проверяются прежние запросы, ресурсы builder и точное воспроизведение пары. Обход нынешнего индекса не нужен для исторического чтения; право эффекта отсутствует. Кэш полномочий не вводится.'}
        выход = а.выход
        assert выход.is_absolute() and выход.parent.resolve() == выход.parent
        assert not any((п/'.git').exists() for п in (выход.parent, *выход.parents))
        fd = os.open(выход, os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, 'wb') as поток: поток.write(байты(итог))
        print(json.dumps({'медианы': итог['медианы'], 'процесс_наносекунды': итог['медиана_процесса_наносекунды'],
            'повторы': 3, 'API': 0, 'разборов_native': 0}, ensure_ascii=False))


if __name__ == '__main__': главная()
