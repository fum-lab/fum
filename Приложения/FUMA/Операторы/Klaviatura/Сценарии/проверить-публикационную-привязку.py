"""Настоящие Swift-запуски: явный корень, другой cwd и закрытые отказы."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

КОРЕНЬ = Path(__file__).resolve().parents[1]
ПЕРЕМЕННАЯ_КОРНЯ = 'КЛАВИАТУРА_КОРЕНЬ_ПАКЕТА'


def основная():
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--кэш', type=Path, required=True)
    разбор.add_argument('--выход', type=Path, required=True)
    разбор.add_argument('--журналы', type=Path, required=True)
    параметры = разбор.parse_args()
    if параметры.выход.exists() or параметры.журналы.exists():
        raise SystemExit('Результаты и сырые журналы не перезаписываются')
    for путь in [параметры.кэш, параметры.выход, параметры.журналы]:
        if путь.resolve().is_relative_to(КОРЕНЬ.parents[3]):
            raise SystemExit('Служебные результаты должны находиться вне checkout')
    журналы = параметры.журналы.resolve()
    журналы.mkdir(parents=True, mode=0o700)
    другой = журналы / 'другой-каталог'
    другой.mkdir()
    ссылка = журналы / 'ссылка-корня'
    ссылка.symlink_to(КОРЕНЬ, target_is_directory=True)
    образцы = []
    for имя in ['ссылка-файла', 'ссылка-каталога']:
        образец = журналы / имя
        образец.mkdir()
        for файл in ['Package.swift', 'определение.json']:
            shutil.copyfile(КОРЕНЬ / файл, образец / файл)
        if имя == 'ссылка-файла':
            (образец / 'Фикстуры').mkdir()
            (образец / 'Фикстуры/переходы.json').symlink_to(КОРЕНЬ / 'Фикстуры/переходы.json')
        else:
            (образец / 'Фикстуры').symlink_to(КОРЕНЬ / 'Фикстуры', target_is_directory=True)
        образцы.append(образец)
    варианты = [
        ('Явный корень из другого cwd', str(КОРЕНЬ), True),
        ('Отсутствующий корень', None, False),
        ('Несуществующий корень', str(другой / 'отсутствует'), False),
        ('Пустой корень', '', False),
        ('Относительный корень', '.', False),
        ('Файл вместо корня', str(КОРЕНЬ / 'Package.swift'), False),
        ('Символическая ссылка корня', str(ссылка), False),
        ('Символическая ссылка обязательного файла', str(образцы[0]), False),
        ('Символическая ссылка каталога фикстур', str(образцы[1]), False),
        ('Родительский переход в корне', str(КОРЕНЬ) + '/../Klaviatura', False),
    ]
    вызовы = []
    for номер, (имя, значение, успех) in enumerate(варианты):
        среда = dict(os.environ)
        среда.pop('KLAVIATURA_RED', None)
        среда.pop(ПЕРЕМЕННАЯ_КОРНЯ, None)
        if значение is not None:
            среда[ПЕРЕМЕННАЯ_КОРНЯ] = значение
        команда = ['swift', 'test', '--package-path', str(КОРЕНЬ), '--scratch-path', str(параметры.кэш.resolve()), '-j', '2']
        if номер:
            команда += ['--skip-build', '--filter', 'testПервыйТекстНастоящимИнтерпретатором']
        начало = time.perf_counter_ns()
        процесс = subprocess.run(команда, cwd=другой, env=среда, capture_output=True)
        длительность = time.perf_counter_ns() - начало
        (журналы / (str(номер) + '-stdout')).write_bytes(процесс.stdout)
        (журналы / (str(номер) + '-stderr')).write_bytes(процесс.stderr)
        объяснение = 'КЛАВИАТУРА:'.encode() in процесс.stdout + процесс.stderr
        соответствует = процесс.returncode == 0 if успех else процесс.returncode != 0 and объяснение
        вызовы.append({'вызов': имя, 'код': процесс.returncode, 'длительность_нс': длительность,
                       'соответствие': соответствует, 'отказ_корня': объяснение,
                       'stdout_sha256': hashlib.sha256(процесс.stdout).hexdigest(),
                       'stderr_sha256': hashlib.sha256(процесс.stderr).hexdigest()})
    исходник = (КОРЕНЬ / 'Tests/ПроверкиКлавиатуры/ПроверкиПереходов.swift').read_bytes()
    макрос = re.search(rb'#[f]ile(?:Path|ID)?\b', исходник) is not None
    результат = {'схема': 'klaviatura.публикационная-привязка.1', 'вызовы': вызовы,
                 'макрос_пути_исходника': макрос, 'другой_cwd': True,
                 'sha256': {имя: hashlib.sha256((КОРЕНЬ / имя).read_bytes()).hexdigest() for имя in [
                     'Tests/ПроверкиКлавиатуры/ПроверкиПереходов.swift',
                     'Проверки/проверить-и-измерить.py', 'Сценарии/проверить-публикационную-привязку.py']},
                 'успех': not макрос and all(вызов['соответствие'] for вызов in вызовы)}
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'успех': результат['успех'], 'вызовов': len(вызовы)}, ensure_ascii=False))
    return 0 if результат['успех'] else 1


if __name__ == '__main__':
    raise SystemExit(основная())
