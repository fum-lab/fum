"""Воспроизводимый профиль первого сегмента; полный READY пока не подключён."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time
import tracemalloc

КОРЕНЬ = Path(__file__).resolve().parents[3]
СТРУКТУРА = КОРЕНЬ / 'Инструменты/fum-struktura-papok-zaprosov'
sys.path[:0] = [str(СТРУКТУРА / 'scripts'), str(СТРУКТУРА / 'tests')]
from test_план_начала import репозиторий
from test_обычного_независимого_журнала import НезависимыйОбычныйЖурнал, ЭТАПЫ, прежний
import независимый_журнал as журнал


def один_запуск():
    проверки = НезависимыйОбычныйЖурнал()
    with репозиторий() as фикс:
        база = проверки.основа(фикс)
        до = {п.relative_to(фикс.root).as_posix(): п.read_bytes()
            for п in (фикс.root / 'Журнал').rglob('*.md')}
        времена = {}
        tracemalloc.start()
        def измерить(имя, действие):
            начало = time.perf_counter_ns()
            результат = действие()
            времена[имя] = time.perf_counter_ns() - начало
            return результат
        измерить('чистый_план_P.1', lambda: журнал.каркас.подготовить_собственную_пару(
            фикс.root, ЭТАПЫ[0], ЭТАПЫ[0].split('_MSK_', 1)[1],
            'Создать первый этап', прежний.THREAD_ID, ['Повтор.\n', 'Повтор.\n']))
        план = измерить('чистый_план', lambda: проверки.план(фикс, база))
        измерить('установка_собственной_пары', lambda: проверки.установить(фикс, план))
        фикс.commit()
        голова = фикс.git('rev-parse', 'HEAD').stdout.strip()
        состав = измерить('полный_состав_Git', lambda: журнал.состав_принятого_дерева(фикс.root, голова))
        индекс = измерить('повтор_состава_и_индекс', lambda: журнал.построить_принятый_индекс(фикс.root, состав))
        фикс.write('Индексы/навигация-журнала.md', индекс['байты'])
        измерить('сверка_смешанного_состава', lambda: журнал.проверить_смешанный(фикс.root, состав))
        начало = time.perf_counter_ns()
        исходный = журнал._гит(КОРЕНЬ, 'rev-parse', 'HEAD').decode().strip()
        большой_состав = журнал.состав_принятого_дерева(КОРЕНЬ, исходный)
        большой_индекс = журнал.построить_принятый_индекс(КОРЕНЬ, большой_состав)
        времена['полный_состав_реальной_базы_и_индекс'] = time.perf_counter_ns() - начало
        _, пик = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        assert индекс['записей'] == 3
        assert len(план[0]) == 2
        assert all((фикс.root / п).read_bytes() == б for п, б in до.items())
        return {'наносекунды': времена, 'пик_памяти_байты': пик,
            'принятых': 3, 'созданных_файлов': 2, 'соседи_сохранены': True,
            'база': исходный, 'записей_реальной_базы': большой_индекс['записей'],
            'байтов_индекса_реальной_базы': len(большой_индекс['байты'])}


def главная():
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--один-запуск', action='store_true')
    разбор.add_argument('--выход', type=Path)
    параметры = разбор.parse_args()
    if параметры.один_запуск:
        результат = один_запуск()
    else:
        запуски = []
        for _ in range(3):
            процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--один-запуск'],
                cwd=КОРЕНЬ, capture_output=True, timeout=90)
            if процесс.returncode:
                sys.stderr.buffer.write(процесс.stderr)
                raise RuntimeError('Отказ процесса профиля: ' + str(процесс.returncode))
            запуски.append(json.loads(процесс.stdout))
        источники = [Path(__file__), СТРУКТУРА / 'scripts/независимый_журнал.py',
            СТРУКТУРА / 'tests/test_обычного_независимого_журнала.py',
            КОРЕНЬ / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/независимый_индекс_журнала.py']
        результат = {'схема': 'fum.профиль-обычного-независимого-журнала.1',
            'граница': 'Первый сегмент: две новые карточки, Git-состав и индекс; полный Creator/READY отсутствует.',
            'предусловия': {'новых_процессов': 3, 'записей_основы': 2, 'новых_пар': 1,
                'принятых_записей': 3, 'повреждений': 0},
            'код': {п.relative_to(КОРЕНЬ).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest() for п in источники},
            'медиана_наносекунды': {имя: int(statistics.median(з['наносекунды'][имя] for з in запуски))
                for имя in запуски[0]['наносекунды']}, 'запуски': запуски}
    байты = (json.dumps(результат, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n').encode()
    if параметры.выход:
        with параметры.выход.open('xb') as файл:
            файл.write(байты)
    print(байты.decode(), end='')


if __name__ == '__main__':
    главная()
