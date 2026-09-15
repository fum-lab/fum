"""Измерить операторную генерацию и применение общего описания без сборки."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time

КОРЕНЬ = Path(__file__).resolve().parent
sys.path[:0] = [str(КОРЕНЬ / 'общие/Python'), str(КОРЕНЬ / 'порождённые')]
from модели_ответа import представить_снимок


def измерить(действие):
    начало = time.perf_counter_ns()
    результат = действие()
    return результат, (time.perf_counter_ns() - начало) / 1_000_000


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def основная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--исполнитель', type=Path, required=True)
    разбор.add_argument('--swift', type=Path, required=True)
    разбор.add_argument('--выход', type=Path, required=True)
    параметры = разбор.parse_args()
    спецификация = importlib.util.spec_from_file_location('порождение', КОРЕНЬ / 'породить-ответ.py')
    модуль = importlib.util.module_from_spec(спецификация)
    спецификация.loader.exec_module(модуль)
    описание = КОРЕНЬ / 'контракты/описание-ответа.json'
    генерация = []
    эталон = None
    for _ in range(7):
        результат, время = измерить(lambda: модуль.породить(параметры.исполнитель, описание, КОРЕНЬ / 'контракты'))
        if эталон is not None and эталон != результат: raise ValueError('Нестабильная генерация')
        эталон = результат
        генерация.append(время)
    исходный = json.loads((КОРЕНЬ / 'фикстуры/нативный-ответ.json').read_bytes())
    снимок = json.loads(исходный['content'][0]['text'])
    случаи = []
    for имя in ('малый', 'крупный'):
        внутренний = json.loads(json.dumps(снимок))
        if имя == 'малый': внутренний['turns'] = []
        else:
            команда = next(элемент for элемент in внутренний['turns'][0]['items'] if элемент['type'] == 'commandExecution')
            команда['aggregatedOutput'] = 'я' * 2_000_000
        оболочка = json.loads(json.dumps(исходный))
        оболочка['content'][0]['text'] = json.dumps(внутренний, ensure_ascii=False, separators=(',', ':'))
        данные = (json.dumps(оболочка, ensure_ascii=False, separators=(',', ':')) + '\n').encode()
        сумма = хэш(данные)
        задача = внутренний['thread']['id']
        времена = {'Python': [], 'Swift': []}
        выходы = {}
        смысл = None
        for _ in range(7):
            результат, время = измерить(lambda: представить_снимок(данные, сумма, задача))
            времена['Python'].append(время)
            выходы['Python'] = {'байты': len(результат), 'sha256': хэш(результат)}
            смысл = json.loads(результат)
            процесс, время = измерить(lambda: subprocess.run([str(параметры.swift.resolve()), сумма, задача, '16000'], input=данные, capture_output=True))
            if процесс.returncode or json.loads(процесс.stdout) != смысл: raise ValueError('Разошёлся смысл реализации')
            времена['Swift'].append(время)
            текущий = {'байты': len(процесс.stdout), 'sha256': хэш(процесс.stdout)}
            # JSONEncoder не задаёт порядок ключей; байтовый детерминизм runtime не требуется.
            выходы['Swift'] = {'байты': текущий['байты'], 'sha256_последнего': текущий['sha256']}
            if хэш(данные) != сумма: raise ValueError('Изменён полный оригинал')
        случаи.append({'имя': имя, 'вход': {'байты': len(данные), 'sha256': сумма}, 'выходы': выходы,
            'время_мс': времена, 'медианы_мс': {язык: statistics.median(ряды) for язык, ряды in времена.items()},
            'смысловой_sha256': хэш(json.dumps(смысл, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode())})
    пути = [описание, КОРЕНЬ / 'породить-ответ.py'] + sorted((КОРЕНЬ / 'общие').rglob('*.py')) + sorted((КОРЕНЬ / 'общие').rglob('*.swift'))
    отчёт = {'схема': 'fum.профиль-порождённого-ответа.1', 'повторы': 7,
        'исполняемые_файлы': {'генератор_sha256': хэш(параметры.исполнитель.read_bytes()), 'Swift_sha256': хэш(параметры.swift.read_bytes())},
        'генерация': {'граница': 'Два новых процесса готового исполнителя, разбор описания, шаги, выдача и проверка наблюдений; без записи и сборки',
            'время_мс': генерация, 'медиана_мс': statistics.median(генерация),
            'файлы': {имя: {'байты': len(данные), 'sha256': хэш(данные)} for имя, данные in эталон.items()}},
        'применение': {'Python': 'Загруженный модуль: проверка SHA, разбор, модели, проекция и UTF-8+LF; без импорта и файлового чтения',
            'Swift': 'Новый CLI-процесс: запуск, stdin, проверка SHA, разбор, модели, проекция и stdout UTF-8+LF; без сборки'},
        'случаи': случаи, 'исходники': {str(п.relative_to(КОРЕНЬ)): хэш(п.read_bytes()) for п in пути},
        'ограничения': ['Открытая синтетика; не наблюдённая частота реальных ответов', 'Границы Python и Swift различны; это не рейтинг языков',
            'Не измерены токены, RSS, API и сетевые задержки', 'Побайтовая идентичность runtime не требуется', 'Смешанная последовательность и сохранённое повторное чтение проверяются отдельно']}
    параметры.выход.write_text(json.dumps(отчёт, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'генерация_медиана_мс': отчёт['генерация']['медиана_мс'], 'случаи': [{'имя': с['имя'], 'вход_байты': с['вход']['байты'], 'выходы': с['выходы'], 'медианы_мс': с['медианы_мс']} for с in случаи]}, ensure_ascii=False))


if __name__ == '__main__': основная()
