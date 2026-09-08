"""Сравнить этапы переименования на одинаковых копиях настоящей Git-фикстуры."""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import statistics
import subprocess
import sys
import tempfile
import time
import types


def загрузить(имя, байты, путь):
    модуль = types.ModuleType(имя)
    модуль.__dict__.update({'__file__': str(путь)})
    sys.modules[имя] = модуль
    exec(compile(байты, str(путь), 'exec'), модуль.__dict__)
    return модуль


def измеритель(действие, имя, метки):
    def измерить(*аргументы, **параметры):
        начало = time.perf_counter_ns()
        исход = 'неуспешно'
        try:
            результат = действие(*аргументы, **параметры)
            исход = 'успешно'
            return результат
        finally:
            метки.append({'стадия': имя, 'наносекунды': time.perf_counter_ns() - начало, 'исход': исход, 'родитель': 'переименование'})
    return измерить


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--корень-репозитория', type=Path, required=True)
    разбор.add_argument('--вывод', type=Path, required=True)
    параметры = разбор.parse_args()
    корень = параметры.корень_репозитория.resolve()
    источник = Path('Инструменты/fum-reyestr-planirovaniya/scripts/rename-step-card.py')
    путь_тестов = корень / 'Инструменты/fum-reyestr-planirovaniya/tests/test_rename_step_card.py'
    тесты = загрузить('профиль_фикстура', путь_тестов.read_bytes(), путь_тестов)
    база = '955851da1f8ce2424c2f4d020c74a9cf631056e5'
    версии = {
        'до': subprocess.run(['git', 'show', f'{база}:{источник.as_posix()}'], cwd=корень, check=True, capture_output=True).stdout,
        'после': (корень / источник).read_bytes(),
    }
    результат = {'база': база, 'интерпретатор': sys.version.split()[0], 'повторов': 5, 'сценарий': 'Копии одной Git-фикстуры: один профиль, живой реестр, Markdown и источники; подготовка копии вне интервала.', 'версии': {}}
    with tempfile.TemporaryDirectory(prefix='fum-rename-profile-') as временный_каталог:
        каталог = Path(временный_каталог)
        эталон = каталог / 'эталон'
        эталон.mkdir()
        проверка = тесты.RenameStepCardTests()
        проверка.write_fixture(эталон)
        профиль = проверка.записать_исторический_профиль(эталон).relative_to(эталон)
        исходные_байты = (эталон / профиль).read_bytes()
        инвентарь = [(путь.relative_to(эталон).as_posix(), hashlib.sha256(путь.read_bytes()).hexdigest()) for путь in sorted(эталон.rglob('*')) if путь.is_file() and '.git' not in путь.relative_to(эталон).parts]
        результат['вход_sha256'] = hashlib.sha256(json.dumps(инвентарь, ensure_ascii=False).encode()).hexdigest()
        for имя, байты in версии.items():
            модуль = загрузить('профиль_' + имя, байты, корень / источник)
            прогоны = []
            исходные_функции = {ключ: getattr(модуль, ключ) for ключ in ('load_live_files', 'build_mutation_plan')}
            for номер in range(5):
                копия = каталог / f'{имя}-{номер}'
                shutil.copytree(эталон, копия)
                метки = []
                for ключ, название in [('load_live_files', 'чтение-и-валидация'), ('build_mutation_plan', 'план-замен')]:
                    setattr(модуль, ключ, измеритель(исходные_функции[ключ], название, метки))
                начало = time.perf_counter_ns()
                ответ = модуль.execute(argparse.Namespace(repo_root=копия, card_id='FUM-STEP-0001', status='completed', description=None))
                длительность = time.perf_counter_ns() - начало
                assert (копия / тесты.NEW_REPO_PATH).is_file()
                assert тесты.NEW_REPO_PATH in (копия / 'Планирование/реестр.json').read_text()
                assert ((копия / профиль).read_bytes() == исходные_байты) == (имя == 'после')
                assert ответ['new_path'] == тесты.NEW_REPO_PATH
                прогоны.append({'наносекунды': длительность, 'исход': 'успешно', 'стадии': метки})
            результат['версии'][имя] = {'код_sha256': hashlib.sha256(байты).hexdigest(), 'прогоны': прогоны, 'медиана_наносекунды': statistics.median(запись['наносекунды'] for запись in прогоны)}
    параметры.вывод.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({имя: запись['медиана_наносекунды'] for имя, запись in результат['версии'].items()}, ensure_ascii=False))


if __name__ == '__main__':
    выполнить()
