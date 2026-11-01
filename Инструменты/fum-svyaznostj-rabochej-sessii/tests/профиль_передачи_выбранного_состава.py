"""Три свежих процесса проверяют отдельный S; время отказа не считается ускорением."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import statistics
import subprocess
import sys
import time


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--выход', type=Path, required=True)
    параметры = разбор.parse_args()
    каталог = Path(__file__).resolve().parent
    корень = каталог.parents[2]
    пути = [каталог / 'test_передачи_выбранного_состава.py',
        каталог.parent / 'scripts/связность_независимого_журнала.py',
        каталог.parent / 'scripts/создание_коммита.py',
        каталог.parent / 'scripts/подготовка_этапа_коммита.py']
    def хэши():
        return {п.relative_to(корень).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest()
            for п in пути}
    исходные = хэши()
    результаты = []
    for номер in range(3):
        расход_до = resource.getrusage(resource.RUSAGE_CHILDREN)
        начало = time.perf_counter_ns()
        процесс = subprocess.run([sys.executable, '-B', '-m', 'unittest',
            'test_передачи_выбранного_состава'], cwd=корень,
            env={**os.environ, 'PYTHONPATH': str(каталог), 'GIT_OPTIONAL_LOCKS': '0'},
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180)
        длительность = time.perf_counter_ns() - начало
        расход_после = resource.getrusage(resource.RUSAGE_CHILDREN)
        результаты.append({'номер': номер + 1, 'код': процесс.returncode,
            'монотонные_нс': длительность,
            'процессорное_пользовательское_с': расход_после.ru_utime - расход_до.ru_utime,
            'процессорное_системное_с': расход_после.ru_stime - расход_до.ru_stime,
            'пиковая_память_всех_дочерних_процессов': расход_после.ru_maxrss,
            'stdout_sha256': hashlib.sha256(процесс.stdout).hexdigest(),
            'stderr_sha256': hashlib.sha256(процесс.stderr).hexdigest()})
        if процесс.returncode:
            sys.stderr.buffer.write(процесс.stderr)
            break
    if хэши() != исходные:
        raise ValueError('Исполняемые исходники изменились при профилировании')
    итог = {'схема': 'fum.профиль-передачи-выбранного-состава.1',
        'граница': 'Время полных временных Git-фикстур в трёх свежих процессах; кэш ОС не очищался. '
            'Показатель пиков памяти накопительный; единица зависит от платформы. '
            'Это не время рабочего ROOT9 и не сравнение с неуспешным старым кодом.',
        'python': sys.version.split()[0], 'платформа': sys.platform,
        'исходники_sha256': исходные, 'процессы': результаты,
        'медиана_монотонных_нс': statistics.median(р['монотонные_нс'] for р in результаты),
        'оптимизация': 'Дополнительное кэширование не вводится: сохранена свежая проверка S и идентичности. '
            'Оптимизация повторных чистых разборов остаётся отдельным ограниченным этапом.'}
    сырые = (json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    with os.fdopen(os.open(параметры.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o644), 'wb') as поток:
        поток.write(сырые); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'процессов': len(результаты),
        'медиана_монотонных_нс': итог['медиана_монотонных_нс'],
        'коды': [р['код'] for р in результаты]}, ensure_ascii=False))
    return 0 if len(результаты) == 3 and all(р['код'] == 0 for р in результаты) else 1


if __name__ == '__main__':
    raise SystemExit(главная())
