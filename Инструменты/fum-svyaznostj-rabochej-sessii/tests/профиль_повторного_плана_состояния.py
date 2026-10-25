"""Три новых процесса на фазу; подготовка фикстуры вне измерений."""
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

ТЕМА = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ТЕМА/'scripts'))
import повторный_план_журнала_состояния as план
import проверенный_повторный_план_состояния as читатель


def рабочий(путь):
    в = json.loads(путь.read_bytes()); профиль = {}; tracemalloc.start()
    if в['операция'] == 'построить':
        итог = план.построить(в['вход'], корень=Path(в['корень']), профиль=профиль)
    else: итог = читатель.прочитать(в['вход'], корень=Path(в['корень']), профиль=профиль)
    _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
    assert not итог['разрешение_установки'] and профиль['API'] == 0
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'профиль': профиль, 'python_пик_байты': пик}, ensure_ascii=False, sort_keys=True))


def главная():
    р = argparse.ArgumentParser(allow_abbrev=False)
    р.add_argument('--рабочий', type=Path); р.add_argument('--выход', type=Path)
    а = р.parse_args()
    if а.рабочий: рабочий(а.рабочий); return
    if а.выход is None: р.error('Нужен приватный выход')
    from test_повторного_плана_журнала_состояния import Пример, байты
    with tempfile.TemporaryDirectory(prefix='fum-repeated-state-profile-') as каталог:
        ф = Пример(каталог); результаты = {}
        for операция in ('построить', 'сверить'):
            вход = ф.ф.с.папка/(операция+'.json')
            выбор = ф.вход if операция == 'построить' else ф.закрепить(ф.построить()['байты'])
            вход.write_bytes(байты({'операция': операция, 'корень': str(ф.корень), 'вход': выбор})); вход.chmod(0o600)
            до = ф.снимок(); замеры = []
            for _ in range(3):
                начало = time.monotonic_ns()
                о = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()),
                    '--рабочий', str(вход)], capture_output=True, check=True)
                з = json.loads(о.stdout); з['процесс_наносекунды'] = time.monotonic_ns()-начало; замеры.append(з)
            assert ф.снимок() == до and len({з['sha256'] for з in замеры}) == 1
            результаты[операция] = {'замеры': замеры,
                'медиана_функции_наносекунды': statistics.median(з['профиль']['всего_наносекунды'] for з in замеры),
                'медиана_процесса_наносекунды': statistics.median(з['процесс_наносекунды'] for з in замеры)}
        assert результаты['построить']['замеры'][0]['sha256'] == результаты['сверить']['замеры'][0]['sha256']
        исходники = ['scripts/каркас_журнала_состояния.py', 'scripts/повторный_план_журнала_состояния.py',
            'scripts/исторические_байты_ожиданий.py', 'scripts/историческая_доставка_ожиданий.py',
            'scripts/проверенный_повторный_план_состояния.py', 'scripts/повторный_журнал_состояния.py',
            'tests/test_повторного_плана_журнала_состояния.py', 'tests/профиль_повторного_плана_состояния.py']
        итог = {'схема': 'fum.профиль-повторного-плана-журнала-состояния.1', 'операции': результаты,
            'исходники_sha256': {п: hashlib.sha256((ТЕМА/п).read_bytes()).hexdigest() for п in исходники},
            'граница': 'Малая фикстура: настоящий Git и JSONL A,B,A; R предок второго H. Три новых процесса каждой фазы. Setup и закрепление плана исключены. Функция вложена в процесс; фазы не суммируются. tracemalloc учитывает только Python. Кэш ОС не очищается. Живое API, установка, Creator и автоматическое возобновление не измерены.',
            'решение_об_оптимизации': 'При восстановлении используются закреплённые экземпляры и replay пары без повторного native-разбора. Нет глобального сканирования содержимого Журнала. Повторные ресурсные проверки и HEAD/ref/индекс сохранены.',
            'API': 0, 'разрешение_установки': False}
        выход = а.выход; assert выход.is_absolute() and выход.parent.resolve() == выход.parent
        assert not any((п/'.git').exists() for п in (выход.parent, *выход.parents))
        fd = os.open(выход, os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, 'wb') as фп: фп.write(байты(итог))
        print(json.dumps({к: {н: в for н, в in з.items() if н != 'замеры'}
            for к, з in результаты.items()}, ensure_ascii=False))


if __name__ == '__main__': главная()
