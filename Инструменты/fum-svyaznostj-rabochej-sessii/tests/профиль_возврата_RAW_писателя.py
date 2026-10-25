"""Три пары процессов с настоящим возвратом каталога и новым RO-повтором."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics

from test_возврата_RAW_писателя import ВозвратRAW
from test_запуска_принятого_писателя import КОРЕНЬ, СОСТАВ, BOOT, ENGINE


def главная():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--выход', required=True)
    a = parser.parse_args()
    состав = json.loads((КОРЕНЬ / СОСТАВ).read_bytes())
    пути = [*состав['код'], *состав['ресурсы'], BOOT, ENGINE, СОСТАВ,
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_возврата_RAW_писателя.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_возврата_RAW_писателя.py']
    хэши = {п: hashlib.sha256((КОРЕНЬ / п).read_bytes()).hexdigest() for п in пути}
    образцы = []
    for _ in range(3):
        ф = ВозвратRAW('test_полный_Creator_и_повтор_после_возврата')
        ф.setUp()
        try:
            ф.test_полный_Creator_и_повтор_после_возврата()
            образцы.append({'процессы': ф.профиль})
        finally: ф.doCleanups()
    assert all(hashlib.sha256((КОРЕНЬ / п).read_bytes()).hexdigest() == h for п, h in хэши.items())
    итог = {'схема': 'fum.профиль-возврата-RAW.1', 'образцы': образцы,
        'медианы_нс': {режим: statistics.median(э['процессы'][i]['процесс_нс'] for э in образцы)
            for i, режим in enumerate(('смена', 'повтор'))}, 'хэши_исходников': хэши,
        'граница': 'Новый bound процесс: G2, возврат исходного каталога, v4 и Creator; '
            'отдельный новый RO-процесс. Подготовка Q/W вне таймера; не реальный узел.',
        'решение_об_оптимизации': 'Сначала измерить реальный цикл; не ослаблять guards или повторять prepare.'}
    with os.fdopen(os.open(Path(a.выход), os.O_CREAT | os.O_EXCL | os.O_WRONLY | os.O_NOFOLLOW, 0o600), 'wb') as поток:
        поток.write((json.dumps(итог, ensure_ascii=False, indent=2)+'\n').encode()); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'медианы_нс': итог['медианы_нс'], 'образцов': 3}, ensure_ascii=False))


if __name__ == '__main__': главная()
