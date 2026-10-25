"""Три полных процесса Creator и три самостоятельных читающих процесса."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics

from test_запуска_принятого_писателя import ЗапускПисателя, КОРЕНЬ, СОСТАВ, BOOT, ENGINE


def главная():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--выход', required=True)
    a = parser.parse_args()
    состав = json.loads((КОРЕНЬ / СОСТАВ).read_bytes())
    пути = [*состав['код'], *состав['ресурсы'], BOOT, ENGINE, СОСТАВ,
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_запуска_принятого_писателя.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_запуска_принятого_писателя.py']
    хэши = {п: hashlib.sha256((КОРЕНЬ / п).read_bytes()).hexdigest() for п in пути}
    образцы = []
    for _ in range(3):
        ф = ЗапускПисателя('test_настоящий_Creator_и_RO_повтор_в_разных_процессах')
        ф.setUp()
        try:
            ф.test_настоящий_Creator_и_RO_повтор_в_разных_процессах()
            образцы.append({'процессы': ф.профиль})
        finally:
            ф.doCleanups()
    assert all(hashlib.sha256((КОРЕНЬ / п).read_bytes()).hexdigest() == h for п, h in хэши.items())
    итог = {'схема': 'fum.профиль-принятого-писателя.1', 'образцы': образцы,
        'медианы_нс': {режим: statistics.median(э['процессы'][i]['процесс_нс'] for э in образцы)
            for i, режим in enumerate(('смена', 'повтор'))}, 'хэши_исходников': хэши,
        'граница': 'Полный новый -I -S -B subprocess, включая capture, guards и stock Creator/RO repeat. '
            'Подготовка синтетического Git Q/W находится вне таймера; это не профиль реального узла.',
        'решение_об_оптимизации': 'Перед новым изменением guard измерить реальный конечный состав; '
            'строгость сверки не ослаблена ради времени. Время ROOT-подготовки измеряется отдельно.'}
    цель = Path(a.выход)
    with цель.open('xb') as поток:
        поток.write((json.dumps(итог, ensure_ascii=False, indent=2) + '\n').encode())
    print(json.dumps({'медианы_нс': итог['медианы_нс'], 'образцов': len(образцы)}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
