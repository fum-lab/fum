"""Читающий A.2: три новых процесса, подготовка фикстуры вне измерения."""
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
import проверенные_повторные_полномочия_узла as читатель


def рабочий(путь):
    вход = json.loads(путь.read_bytes()); профиль = {}
    tracemalloc.start()
    итог = читатель.прочитать(вход['полномочия'], корень=Path(вход['корень']), профиль=профиль)
    _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
    assert not итог['разрешение_установки'] and итог['строгий_порядок_Git']
    assert профиль['API'] == профиль['разборов_native'] == 0
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'профиль': профиль, 'python_пик_байты': пик}, ensure_ascii=False, sort_keys=True))


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--рабочий', type=Path)
    разбор.add_argument('--выход', type=Path)
    а = разбор.parse_args()
    if а.рабочий: рабочий(а.рабочий); return
    if а.выход is None: разбор.error('Нужен приватный выход профиля')
    from test_повторных_полномочий_узла import Пример, байты
    with tempfile.TemporaryDirectory(prefix='fum-repeated-authority-profile-') as каталог:
        пример = Пример(каталог)
        вход = пример.ф.ф.с.папка/'профильный-вход.json'
        вход.write_bytes(байты({'корень': str(пример.корень), 'полномочия': пример.выбор})); вход.chmod(0o600)
        до = пример.снимок(); замеры = []
        for _ in range(3):
            начало = time.monotonic_ns()
            ответ = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()),
                '--рабочий', str(вход)], capture_output=True, check=True)
            замер = json.loads(ответ.stdout); замер['процесс_наносекунды'] = time.monotonic_ns()-начало
            замеры.append(замер)
        assert all(з['sha256'] == замеры[0]['sha256'] for з in замеры)
        assert пример.снимок() == до
        исходники = ['scripts/полномочия_ветки_состояния_узла.py',
            'scripts/проверенные_повторные_полномочия_узла.py',
            'scripts/проверить_повторные_полномочия_узла.py',
            'tests/test_повторных_полномочий_узла.py', 'tests/профиль_повторных_полномочий_узла.py']
        итог = {'схема': 'fum.профиль-повторных-полномочий-узла.1', 'повторы': 3,
            'замеры': замеры, 'медианы': {к: statistics.median(з['профиль'][к] for з in замеры)
                for к in ('проект_наносекунды', 'всего_наносекунды')},
            'медиана_процесса_наносекунды': statistics.median(з['процесс_наносекунды'] for з in замеры),
            'исходники_sha256': {п: hashlib.sha256((КАТАЛОГ/п).read_bytes()).hexdigest() for п in исходники},
            'байты_Git_и_источников_не_изменены': True, 'API': 0, 'разборов_native': 0,
            'разрешение_установки': False,
            'граница': 'Малая фикстура настоящих Git-объектов A.2 и более раннего P.1 трёх сообщений A,B,A. Подготовка исключена. Внутренний таймер включает чтение A и P, исторические запросы, builder, точный расчёт пары и Git-порядок. Новый процесс дополнительно включает Python и импорты. Вложенные фазы не суммируются. tracemalloc измеряет Python; память Git неизвестна. Кэш ОС не очищается. API, установка пары, запись состояния и полный повторный запуск не измеряются.',
            'решение_об_оптимизации': 'Повторные полномочия проверяются по точным Git-источникам без native JSONL, текущего control и нынешнего отчёта писателя. Используется общее структурное ядро A.1; прежние публичные эффекты не принимают A.2. Кэш полномочий не вводится.'}
        выход = а.выход
        assert выход.is_absolute() and выход.parent.resolve() == выход.parent
        assert not any((п/'.git').exists() for п in (выход.parent, *выход.parents))
        fd = os.open(выход, os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, 'wb') as поток: поток.write(байты(итог))
        print(json.dumps({'медианы': итог['медианы'], 'процесс_наносекунды': итог['медиана_процесса_наносекунды'],
            'повторы': 3, 'API': 0, 'разборов_native': 0}, ensure_ascii=False))


if __name__ == '__main__': главная()
