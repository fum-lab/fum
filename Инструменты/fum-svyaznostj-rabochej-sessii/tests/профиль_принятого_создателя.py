"""Три свежих процесса зарегистрированной leaf Git-фикстуры на закреплённых исходниках."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys


def снимок_кода():
    корень = Path(__file__).resolve().parents[3]
    каталог = корень / 'Инструменты/fum-svyaznostj-rabochej-sessii'
    состав = json.loads((каталог / 'состав-принятого-писателя.json').read_bytes())
    пути = [*состав['код'], *состав['ресурсы'],
        'Инструменты/fum-svyaznostj-rabochej-sessii/состав-принятого-писателя.json',
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/запуск_принятого_создателя.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/вход_принятого_создателя.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/исполнение_принятого_кода.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_принятого_создателя.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_обычной_дочерней_точки.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_запуска_принятого_писателя.py',
        'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_создание_коммита.py',
        'Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py',
        'Инструменты/fum-proverka-git-zavisimostej/scripts/подготовка_зависимостей.py',
        str(Path(__file__).relative_to(корень))]
    return {п: hashlib.sha256((корень / п).read_bytes()).hexdigest() for п in dict.fromkeys(пути)}


def рабочий_процесс():
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import test_принятого_создателя as проверка
    фикстура = проверка.ПринятыйСоздатель('runTest')
    try:
        фикстура.setUp()
        фикстура.зарегистрировать_вложенную_фикстуру()
        до = фикстура.неизменяемые_листы()
        измерения = фикстура.цикл()
        if фикстура.неизменяемые_листы() != до:
            raise ValueError('профиль изменил D или контроль первичного соседа')
        return {'процесс': os.getpid(), 'измерения': измерения,
            'сценарий': 'создатель-.2-linked-W-leaf-D-.7-.9-и-читающий-повтор',
            'база_данных': фикстура.база, 'ревизия_зависимости': фикстура.пин_зависимости,
            'выбор_чтения_sha256': hashlib.sha256(фикстура.выбор_чтения.read_bytes()).hexdigest(),
            'зависимость_и_сосед_сохранены': True}
    finally:
        фикстура.doCleanups()


def главная():
    п = argparse.ArgumentParser(description=__doc__)
    п.add_argument('--выход')
    п.add_argument('--свежий-процесс', action='store_true')
    а = п.parse_args()
    if а.свежий_процесс:
        print(json.dumps(рабочий_процесс(), ensure_ascii=False))
        return 0
    if not а.выход:
        п.error('нужен новый приватный выход')
    до = снимок_кода()
    версия_гит = subprocess.run(['git', '--version'], capture_output=True, text=True, check=True).stdout.strip()
    запуски = []
    for _ in range(3):
        р = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--свежий-процесс'],
            capture_output=True, text=True, timeout=300)
        if р.returncode:
            raise ValueError('свежий профильный процесс отказал: ' + р.stderr)
        запуски.append(json.loads(р.stdout))
    if снимок_кода() != до or len({р['процесс'] for р in запуски}) != 3:
        raise ValueError('изменился код либо процессы не были свежими')
    медианы = {этап: int(statistics.median(м['процесс_нс'] for р in запуски for м in р['измерения']
        if м['этап'] == этап)) for этап in ('подготовить', 'готово', 'создать', 'повтор')}
    итог = {'схема': 'fum.профиль-принятого-создателя.2', 'запуски': запуски,
        'медианы_нс': медианы, 'состав_sha256': до,
        'граница': 'Подготовка фикстуры, внешний v4 и recency исключены; захват K, guards и API внутри каждого consumer включены.',
        'кэш_ОС_очищен': False, 'настоящая_приёмка': False,
        'среда': {'python': sys.version, 'git': версия_гит, 'платформа': sys.platform}}
    путь = Path(а.выход)
    if not путь.is_absolute() or путь != путь.resolve() or any((п / '.git').exists() for п in путь.parents):
        raise ValueError('нужен физический приватный выход вне Git')
    with os.fdopen(os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600), 'w') as поток:
        json.dump(итог, поток, ensure_ascii=False, sort_keys=True, indent=2)
        поток.write('\n')
        поток.flush()
        os.fsync(поток.fileno())
    print(json.dumps({'свежих_процессов': 3, 'медианы_нс': медианы, 'настоящая_приёмка': False}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
