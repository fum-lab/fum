"""Три новых процесса; настоящие Git и JSONL, setup вне измерения."""
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
import план_журнала_писателя_состояния as план


def рабочий(путь):
    вход = json.loads(путь.read_bytes()); профиль = {}
    tracemalloc.start()
    итог = план.построить(вход['план'], корень=Path(вход['корень']), профиль=профиль)
    _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
    assert not итог['разрешение_установки'] and профиль['API'] == 0
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'профиль': профиль, 'python_пик_байты': пик}, ensure_ascii=False, sort_keys=True))


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--рабочий', type=Path)
    разбор.add_argument('--выход', type=Path)
    а = разбор.parse_args()
    if а.рабочий: рабочий(а.рабочий); return
    if а.выход is None: разбор.error('Нужен приватный выход профиля')
    from test_план_журнала_писателя_состояния import Фикстура, байты
    with tempfile.TemporaryDirectory(prefix='fum-state-journal-profile-') as каталог:
        пример = Фикстура(каталог)
        вход = пример.с.папка/'профильный-вход.json'
        вход.write_bytes(байты({'корень': str(пример.корень), 'план': пример.вход})); вход.chmod(0o600)
        до = пример.снимок(); замеры = []
        for _ in range(3):
            начало = time.monotonic_ns()
            ответ = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()),
                '--рабочий', str(вход)], capture_output=True, check=True)
            замер = json.loads(ответ.stdout); замер['процесс_наносекунды'] = time.monotonic_ns()-начало
            замеры.append(замер)
        assert all(з['sha256'] == замеры[0]['sha256'] and з['профиль']['команд'] == 3 for з in замеры)
        assert пример.снимок() == до
        исходники = ['scripts/план_журнала_писателя_состояния.py',
            'scripts/построить_план_журнала_писателя_состояния.py',
            'tests/test_план_журнала_писателя_состояния.py', 'tests/профиль_плана_журнала_писателя_состояния.py']
        итог = {'схема': 'fum.профиль-плана-журнала-писателя-состояния.1', 'повторы': 3,
            'замеры': замеры, 'медианы': {к: statistics.median(з['профиль'][к] for з in замеры)
                for к in ('доверие_наносекунды', 'источники_наносекунды',
                    'каркас_и_повтор_наносекунды', 'всего_наносекунды')},
            'медиана_процесса_наносекунды': statistics.median(з['процесс_наносекунды'] for з in замеры),
            'исходники_sha256': {п: hashlib.sha256((КАТАЛОГ/п).read_bytes()).hexdigest() for п in исходники},
            'байты_Git_и_источников_не_изменены': True, 'API': 0, 'разрешение_установки': False,
            'граница': 'Малая синтетическая фикстура: настоящие Git-объекты и JSONL с тремя человеческими сообщениями A,B,A. Подготовка Git и входа исключена. Процесс включает Python и импорты; вложенные фазы не суммируются. tracemalloc измеряет только Python; память Git неизвестна. Кэш ОС не очищается. Живые API, установка пары и запись состояния не измеряются.',
            'решение_об_оптимизации': 'Каркас строится один раз штатным builder, глобальный Журнал не пересобирается. Только выбранная новая папка проверяется в H/checkout/индексе; повтор H/ref/индекса и проверка прежнего доверия сохранены. Индекс просматривается по именам без чтения содержимого отслеживаемых файлов. Кэш полномочий не вводится.'}
        выход = а.выход
        assert выход.is_absolute() and выход.parent.resolve() == выход.parent
        assert not any((п/'.git').exists() for п in (выход.parent, *выход.parents))
        fd = os.open(выход, os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, 'wb') as поток: поток.write(байты(итог))
        print(json.dumps({'медианы': итог['медианы'], 'процесс_наносекунды': итог['медиана_процесса_наносекунды'],
            'повторы': 3, 'API': 0}, ensure_ascii=False))


if __name__ == '__main__': главная()
