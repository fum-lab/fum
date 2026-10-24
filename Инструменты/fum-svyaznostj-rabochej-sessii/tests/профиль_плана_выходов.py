"""Малый профиль чистой предпроверки и одного синтетического процесса."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
import захват_вывода as захват


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выход', type=Path, required=True)
    п = разбор.parse_args()
    исходники = [Path(захват.__file__), Path(__file__)]
    до = {ф.name: hashlib.sha256(ф.read_bytes()).hexdigest() for ф in исходники}
    план = []
    with tempfile.TemporaryDirectory() as временный:
        база = Path(временный).resolve()
        for число in (0, 16, 256):
            цели = [{'роль': 'предмет:'+str(i), 'путь': str(база/('выход-'+str(i))),
                     'режим': 0o400} for i in range(число)]
            длительности = []
            for _ in range(5):
                начало = time.monotonic_ns()
                результат = захват.составить_план_выходов(база/'захват', цели, база/'наблюдение')
                длительности.append(time.monotonic_ns()-начало)
                if len(результат) != число+15:
                    raise ValueError('Изменён состав плана')
            план.append({'предметных_целей': число, 'повторов_без_эффекта': 5,
                'наносекунды': длительности, 'медиана_нс': int(statistics.median(длительности))})
        счётчик = база/'счётчик'
        конфигурация = {'base': str(база), 'prefix': 'один-процесс', 'cwd': str(база),
            'argv': [sys.executable, '-B', '-c',
                'import os,sys; fd=os.open(sys.argv[1],os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600); '
                'os.write(fd,b"one"); os.close(fd); '
                'os.write(1,bytes(range(256))*256); os.write(2,bytes(reversed(range(256)))*256)',
                str(счётчик)]}
        начало = time.monotonic_ns()
        результат = захват.наблюдать_процесс(конфигурация,
            '00000000-0000-0000-0000-000000000356',
            предметные_цели=[{'роль': 'счётчик', 'путь': str(счётчик), 'режим': 0o600},
                {'роль': 'профиль', 'путь': str(п.выход), 'режим': 0o600}],
            тайм_аут=5, предел_байтов=131072)
        захват_нс = time.monotonic_ns()-начало
        начало = time.monotonic_ns()
        прочитано = захват.прочитать_наблюдение(конфигурация, результат['манифест_sha256'])
        чтение_нс = time.monotonic_ns()-начало
        if счётчик.read_bytes() != b'one' or результат['код_процесса'] != 0 or not результат['полнота'] or прочитано['состояние'] != 'завершено':
            raise ValueError('Не подтверждён единственный полный процесс')
        for имя, данные in (('stdout', bytes(range(256))*256), ('stderr', bytes(reversed(range(256)))*256)):
            if результат['каналы'][имя]['sha256'] != hashlib.sha256(данные).hexdigest():
                raise ValueError('Изменены исходные байты')
        время = результат['процесс']
        интервалы = {'план': время['план_проверен_нс']-время['подготовка_начата_нс'],
            'Popen': время['после_запуска_нс']-время['перед_запуском_нс'],
            'наблюдение_процесса_и_потоков': время['процесс_и_потоки_завершены_нс']-время['перед_запуском_нс'],
            'после_наблюдения_до_финальной_записи': время['перед_финальной_записью_нс']-время['процесс_и_потоки_завершены_нс']}
    после = {ф.name: hashlib.sha256(ф.read_bytes()).hexdigest() for ф in исходники}
    if до != после:
        raise ValueError('Исходники изменились во время профиля')
    ответ = {'схема': 'fum.профиль-плана-выходов.1', 'python': sys.version,
        'интерпретатор': str(Path(sys.executable).resolve()),
        'интерпретатор_sha256': hashlib.sha256(Path(sys.executable).read_bytes()).hexdigest(),
        'платформа': platform.platform(), 'исходники_sha256': до, 'предпроверка': план,
        'синтетических_процессов': 1, 'захват_wall_нс': захват_нс,
        'чтение_с_проверкой_SHA_wall_нс': чтение_нс, 'вложенные_интервалы_нс': интервалы,
        'каналы': результат['каналы'], 'внутренний_API_нс': None,
        'ограничения': 'Popen вложен в наблюдение, интервалы не суммируются. Один малый процесс; кэш ОС не очищался. Ускорение, bottleneck ROOT, получение моделью и внутреннее API не измерены.'}
    данные = захват.закодировать(ответ)
    захват.сохранить(п.выход, данные)
    print(json.dumps({'sha256': hashlib.sha256(данные).hexdigest(), 'байты': len(данные)}, ensure_ascii=False))


if __name__ == '__main__':
    выполнить()
