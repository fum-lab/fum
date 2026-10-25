"""Сравнить стоимость сохранённого и текущего валидатора на прежнем корректном имени."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import tempfile
import time


def выполнить():
    параметры = argparse.ArgumentParser(description=__doc__)
    параметры.add_argument('--до', required=True)
    параметры.add_argument('--выход', type=Path, required=True)
    аргументы = параметры.parse_args()
    if re.fullmatch('[0-9a-f]{40}', аргументы.до) is None:
        параметры.error('Нужен полный OID доверенного исходного коммита')
    путь_кода = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/автор_коммита.py'
    прежний = subprocess.check_output(['git', '--no-optional-locks', 'show', аргументы.до + ':' + путь_кода])
    текущий = Path(путь_кода).read_bytes()
    начало = time.monotonic_ns()
    срезы = [('до', прежний), ('после', текущий)]
    наблюдение = {'модель': 'gpt-6-sol', 'усилие': 'ultra'}
    имя = 'FUM Писатель [gpt-6-sol; effort=ultra]'
    with tempfile.TemporaryDirectory(prefix='fum-имя-автора-') as временное:
        определения = {}
        for режим, код in срезы:
            файл = Path(временное) / (режим + '.py'); файл.write_bytes(код)
            область = {'__file__': str(файл)}
            exec(compile(код, str(файл), 'exec'), область)
            определения[режим] = область
        def измерить(режим):
            область = определения[режим]; старт = time.monotonic_ns()
            for _ in range(5000):
                результат = область['составить_имя']('FUM Писатель', наблюдение)
                assert результат == имя and область['проверить_формат'](результат)
            return {'режим': режим, 'длительность_нс': time.monotonic_ns() - старт,
                'результат_sha256': hashlib.sha256(результат.encode()).hexdigest()}
        прогрев = [измерить(режим) for режим, _ in срезы]
        измерения = []
        for номер in range(3):
            for режим in (('до', 'после') if номер % 2 == 0 else ('после', 'до')):
                измерения.append(dict(измерить(режим), повтор=номер + 1))
        assert len({x['результат_sha256'] for x in измерения + прогрев}) == 1
        итог = {'схема': 'fum.профиль-имени-автора.1', 'исходный_коммит': аргументы.до,
            'граница': 'Чистые составление и проверка прежнего имени; 5000 пар вызовов за повтор; без native JSONL, Git-коммита и общего рабочего цикла',
            'ограничение': 'Новая роль Codex проверяется функциональными сценариями; прежний валидатор её не поддерживает',
            'исходники_sha256': {режим: hashlib.sha256(код).hexdigest() for режим, код in срезы},
            'вход': {'роль': 'FUM Писатель', 'наблюдение': наблюдение},
            'прогрев': прогрев, 'измерения': измерения,
            'медианы_нс': {режим: int(statistics.median(x['длительность_нс']
                for x in измерения if x['режим'] == режим)) for режим, _ in срезы},
            'результаты_совпали': True, 'всего_нс': time.monotonic_ns() - начало}
    сырые = (json.dumps(итог, ensure_ascii=False, sort_keys=True) + '\n').encode()
    with os.fdopen(os.open(аргументы.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o644), 'wb') as файл:
        файл.write(сырые); файл.flush(); os.fsync(файл.fileno())
    print(json.dumps({'медианы_нс': итог['медианы_нс'], 'результаты_совпали': True}, ensure_ascii=False))


if __name__ == '__main__': выполнить()
