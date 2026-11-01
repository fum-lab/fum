"""Три новых процесса: действительный исторический состав и смешанный индекс."""
import copy
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time
import tracemalloc
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_исторических_одиночных_запросов import ИсторическийИндекс, канон
import исторические_одиночные_запросы as исторические
from независимый_индекс_журнала import построить_индекс


МАНИФЕСТ_SHA256 = '5707402fd51ee352c0ff3e3406b0f812887ec84104292cca47f3ceec84052686'


def реальное_чтение(корень):
    манифест = (корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/исторические-одиночные-запросы.json').read_bytes()
    коммит = исторические._гит(корень, 'rev-parse', 'HEAD').decode().strip()
    стадии = {}; вызовы = {}; git_вызовов = 0
    def счётчик(имя, функция):
        def вызов(*а, **к):
            nonlocal git_вызовов
            начало = time.monotonic_ns()
            try:
                return функция(*а, **к)
            finally:
                if имя == '_гит':
                    git_вызовов += 1
                    if а[1:3] == ('cat-file', 'blob'):
                        стадии['байты_blob'] = стадии.get('байты_blob', 0) + time.monotonic_ns() - начало
                else:
                    стадии[имя] = стадии.get(имя, 0) + time.monotonic_ns() - начало
                    вызовы[имя] = вызовы.get(имя, 0) + 1
        return вызов
    начало = time.monotonic_ns()
    with patch.object(исторические, '_дерево', счётчик('_дерево', исторические._дерево)), \
         patch.object(исторические, '_пути', счётчик('_пути', исторические._пути)), \
         patch.object(исторические, '_без_отчёта', счётчик('_без_отчёта', исторические._без_отчёта)), \
         patch.object(исторические, '_checkout', счётчик('_checkout', исторические._checkout)), \
         patch.object(исторические, '_гит', счётчик('_гит', исторические._гит)):
        итог = исторические.прочитать(корень, манифест, ожидаемый_sha256=МАНИФЕСТ_SHA256,
            текущий_коммит=коммит, checkout=True)
    return {'всего_нс': time.monotonic_ns() - начало, 'стадии_нс': стадии, 'вызовы': вызовы,
        'git_вызовов': git_вызовов, 'результат_sha256': hashlib.sha256(канон(итог)).hexdigest(),
        'запросов': итог['запросов'], 'исторических': len(итог['одиночных']),
        'checkout_проверен': итог['checkout_проверен'], 'разрешение_установки': итог['разрешение_установки'],
        'поколения': итог['поколения'], 'API': 0, 'разборов_native': 0}


def смешанный_индекс():
    пример, исходные = ИсторическийИндекс().поколение(); результаты = []
    for количество in (1, 100, 1000):
        записи = []; файлы = {}; tracemalloc.start(); начало = time.monotonic_ns()
        for номер in range(количество):
            запись = copy.deepcopy(пример['записи'][номер % 3])
            старое = запись['журнал']; новое = старое + '_профиль-' + str(номер)
            запись['журнал'] = новое; запись['идентификатор'] = hashlib.sha256(str(номер).encode()).hexdigest()
            for ф in запись['файлы']:
                прежний = ф['путь']; ф['путь'] = прежний.replace('/' + старое + '/', '/' + новое + '/')
                файлы[ф['путь']] = исходные[прежний]
            записи.append(запись)
        после_состава = time.monotonic_ns()
        с = {'схема': 'fum.состав-независимого-журнала.2', 'записи': sorted(записи, key=lambda з: з['журнал'])}
        ш = hashlib.sha256(канон(с)).hexdigest()
        индекс = построить_индекс(с, файлы, ожидаемый_sha256=ш)
        конец = time.monotonic_ns(); _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
        результаты.append({'записей': количество, 'состав_нс': после_состава - начало,
            'индекс_нс': конец - после_состава, 'всего_нс': конец - начало, 'пик_Python_байты': пик,
            'sha256': индекс['sha256'], 'состав_sha256': ш, 'разрешение_установки': индекс['разрешение_установки']})
    return результаты


def главная():
    корень = Path(__file__).resolve().parents[3]
    if sys.argv[1:] == ['--новый-процесс']:
        print(json.dumps({'чтение': реальное_чтение(корень), 'индексы': смешанный_индекс()}, ensure_ascii=False, sort_keys=True)); return
    if sys.argv[1:]: raise ValueError('неизвестные аргументы профиля')
    проверки = []
    for шаблон in ('test_исторических_одиночных_запросов.py', 'test_проверенного_плана_журнала_состояния.py'):
        набор = unittest.defaultTestLoader.discover(str(Path(__file__).resolve().parent), pattern=шаблон)
        итог = unittest.TextTestRunner().run(набор)
        if not итог.wasSuccessful(): raise SystemExit(1)
        проверки.append({'шаблон': шаблон, 'тестов': итог.testsRun})
    повторы = []
    for _ in range(3):
        начало = time.monotonic_ns()
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--новый-процесс'],
            cwd=корень, capture_output=True, check=True)
        повторы.append({'процесс_нс': time.monotonic_ns() - начало, **json.loads(процесс.stdout)})
    assert len({п['чтение']['результат_sha256'] for п in повторы}) == 1
    assert all(п['чтение']['checkout_проверен'] and not п['чтение']['разрешение_установки'] for п in повторы)
    for номер in range(3):
        assert len({п['индексы'][номер]['sha256'] for п in повторы}) == 1
        assert len({п['индексы'][номер]['состав_sha256'] for п in повторы}) == 1
        assert all(not п['индексы'][номер]['разрешение_установки'] for п in повторы)
    print(json.dumps({'проверки': проверки, 'повторы': повторы,
        'медиана_чтения_нс': statistics.median(п['чтение']['всего_нс'] for п in повторы),
        'медиана_процесса_нс': statistics.median(п['процесс_нс'] for п in повторы),
        'граница': 'Два точных Git-поколения и два чтения исторических файлов checkout; затем синтетические смешанные индексы с tracemalloc. Без установки, native/API и автоматического возобновления.'}, ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    главная()
