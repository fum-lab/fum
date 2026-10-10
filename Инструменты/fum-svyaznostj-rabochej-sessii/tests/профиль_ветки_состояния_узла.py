"""Три новых процесса: стоимость чтения допуска state, без живых эффектов."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time


КОРЕНЬ = Path(__file__).resolve().parents[3]
ПУТИ = [
    'Инструменты/fum-reyestr-planirovaniya/scripts/доставка_гит.py',
    *['Инструменты/fum-svyaznostj-rabochej-sessii/scripts/'+имя for имя in (
        'полномочия_ветки_состояния_узла.py', 'обычное_поручение.py',
        'обновление_ожиданий_узла.py', 'создание_коммита.py',
        'готовность_коммита.py', 'типизированная_контрольная_точка.py',
        'публикационный_допуск_дочернего_состава.py', 'восстановление_прерванной_задачи.py')],
    'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_ветка_состояния_узла.py',
    'Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_ветки_состояния_узла.py']


def хэши():
    return {имя: hashlib.sha256((КОРЕНЬ/имя).read_bytes()).hexdigest() for имя in ПУТИ}


def измерить():
    import test_ветка_состояния_узла as проверки
    начало = time.monotonic_ns()
    случай = проверки.ВеткаСостоянияУзла()
    try:
        случай.setUp()
        подготовка = time.monotonic_ns()-начало
        ф = случай.ф
        до = ф.ф.гит('status', '--porcelain')
        начало = time.monotonic_ns()
        план = проверки.прежний.писатель.план(ф.вход)
        план_нс = time.monotonic_ns()-начало
        профиль = {}
        проверки.прежний.писатель.обычное.проверить(ф.о.параметры, ф.о.выбор, профиль=профиль)
        if план['допуск_эффекта'] is not False or до != ф.ф.гит('status', '--porcelain'):
            raise ValueError('читающая проверка изменила фикстуру')
        return {'подготовка_фикстуры_нс': подготовка, 'план_нс': план_нс,
                'читатель_нс': профиль, 'живые_эффекты': 0}
    finally:
        случай.doCleanups()


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--дочерний', action='store_true')
    разбор.add_argument('--выход')
    вход = разбор.parse_args()
    if вход.дочерний:
        if вход.выход is not None:
            raise ValueError('дочерний замер не пишет выход')
        print(json.dumps(измерить(), ensure_ascii=False, sort_keys=True))
        return
    if вход.выход is None:
        raise ValueError('нужен отдельный новый выход профиля')
    до = хэши(); серии = []
    for _ in range(3):
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--дочерний'],
            cwd=КОРЕНЬ, capture_output=True, check=True, timeout=120)
        if процесс.stderr:
            raise ValueError('неожиданный stderr нового процесса')
        серии.append(json.loads(процесс.stdout))
    if хэши() != до:
        raise ValueError('исходники изменились при профилировании')
    итог = {'схема': 'fum.профиль-допуска-ветки-состояния.1', 'серии': серии,
            'медиана_плана_нс': int(statistics.median(с['план_нс'] for с in серии)),
            'исходники': до,
            'граница': 'Фикстура Git; подготовка отдельно. Это чтение допуска, а не время живого восстановления.'}
    данные = (json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()
    with os.fdopen(os.open(вход.выход, os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW, 0o600), 'wb') as поток:
        поток.write(данные); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'схема': итог['схема'], 'серий': len(серии),
        'медиана_плана_нс': итог['медиана_плана_нс'], 'живые_эффекты': 0}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
