"""Воспроизводимый профиль; генерация фикстуры измеряется отдельно от чтения."""
import argparse
import hashlib
import json
import platform
import subprocess
import sys
import tempfile
from pathlib import Path
from time import perf_counter_ns

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from канон import кодировать, конверт, хэш
from вход import проверить_вход, РеестрВходов
from профиль import Профиль
from фикстуры import создать


def выполнить():
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--размеры', default='1,100,1000')
    разбор.add_argument('--сравнить', type=Path)
    параметры = разбор.parse_args()
    источник = Path(__file__).resolve().parents[1]
    версии = {путь.relative_to(источник).as_posix(): хэш(путь.read_bytes()) for путь in sorted(источник.rglob('*.py'))}
    замеры = []
    for размер in map(int, параметры.размеры.split(',')):
        with tempfile.TemporaryDirectory() as временный:
            папка = Path(временный).resolve()
            начало = perf_counter_ns()
            запись = создать(папка / 'repo', размер)
            подготовка = perf_counter_ns() - начало
            байты = кодировать(запись)
            оболочка = кодировать(конверт(байты))
            профиль = Профиль()
            начало = perf_counter_ns()
            результат = проверить_вход(папка / 'repo', байты, оболочка,
                ожидаемый_коммит=запись['исходный_коммит'], ожидаемая_ветка=запись['исходная_ветка'],
                реестр=РеестрВходов(папка / 'registry', папка / 'repo'), профиль=профиль)
            длительность = perf_counter_ns() - начало
            замеры.append({'размер': размер, 'подготовка_наносекунды': подготовка, 'чтение_наносекунды': длительность,
                'хэш_входа': хэш(байты), 'хэш_результата': хэш(кодировать(результат)), 'метки': профиль.записи})
    if параметры.сравнить:
        база = json.loads(параметры.сравнить.read_text())
        for до, после in zip(база['замеры'], замеры, strict=True):
            assert (до['размер'], до['хэш_входа'], до['хэш_результата']) == (после['размер'], после['хэш_входа'], после['хэш_результата']), 'байты сравнения изменились'
    print(json.dumps({'схема': 'fum.профиль-входа.1', 'python': platform.python_version(), 'git': subprocess.check_output(['git', '--version'], text=True).strip(),
                      'условия': 'локальные синтетические репозитории; одинаковые исходные blob повторяются под разными путями; wall-clock; интервалы вложены',
                      'версии_файлов': версии, 'замеры': замеры}, ensure_ascii=False, indent=2))


if __name__ == '__main__': выполнить()
