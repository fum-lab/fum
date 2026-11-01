"""Три пары RO-проходов реального Журнала; установка и Create не вызываются.

Прежнее тело одного прохода берётся из точного Git-blob. Остальной замкнутый
контур обязан совпадать; каждый замер выполняется в отдельном новом процессе.
"""
import argparse
import ast
import hashlib
import json
import os
from pathlib import Path
import resource
import statistics
import subprocess
import sys
import time
from unittest.mock import patch

from test_установки_принятого_состава_журнала import (
    КОРЕНЬ, ПУТЬ_УСТАНОВЩИКА, загрузить_установщик)


def гит(*аргументы):
    return subprocess.check_output(['git', '--no-replace-objects', '--no-optional-locks',
        '-c', 'core.hooksPath=' + os.devnull, '-C', str(КОРЕНЬ), *аргументы],
        env={**{к: з for к, з in os.environ.items() if not к.startswith('GIT_')},
            'GIT_NO_REPLACE_OBJECTS': '1', 'GIT_NO_LAZY_FETCH': '1', 'GIT_OPTIONAL_LOCKS': '0'})


def снимок():
    индекс = Path(гит('rev-parse', '--path-format=absolute', '--git-path', 'index').decode().strip())
    return {'HEAD': гит('rev-parse', 'HEAD').decode().strip(),
        'ref': гит('symbolic-ref', 'HEAD').decode().strip(),
        'status': гит('status', '--porcelain=v1', '-z').hex(),
        'index_sha256': hashlib.sha256(индекс.read_bytes()).hexdigest()}


def стенд():
    пути = (Path(__file__).resolve(), Path(__file__).with_name(
        'test_установки_принятого_состава_журнала.py').resolve())
    return {п.relative_to(КОРЕНЬ).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest()
        for п in пути}


def проверить_новый_выход(выход):
    if (выход is None or not выход.is_absolute() or выход.parent.resolve(strict=True) != выход.parent
            or os.path.lexists(выход) or any(os.path.lexists(к / '.git')
                or ((к / 'HEAD').is_file() and (к / 'objects').is_dir()) for к in выход.parents)):
        raise ValueError('Нужен новый физический выход вне Git')


def подготовить_свежую_пару(п):
    """Вызывается внутри запущенного RAW после появления его собственных файлов."""
    проверить_новый_выход(п.снимок_открытой)
    if п.снимок_открытой == п.выход:
        raise ValueError('Выходы профиля и снимка должны различаться')
    модуль = загрузить_установщик()
    план = модуль.приватный({'путь': str(п.план_пары), 'sha256': п.хэш_плана_пары})
    данные = модуль.снять_открытую_пару(КОРЕНЬ, план)
    сырые = (json.dumps(данные, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    fd = os.open(п.снимок_открытой, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o400)
    with os.fdopen(fd, 'wb') as f:
        f.write(сырые); f.flush(); os.fsync(f.fileno())
    return п.снимок_открытой, hashlib.sha256(сырые).hexdigest()


def работник(п):
    модуль = загрузить_установщик()
    до = снимок()
    if до['HEAD'] != п.основа:
        raise ValueError('Нужен неизменный HEAD выбранной основы')
    исходники = {и: модуль.прочитать_исходник(и) for и in модуль.ЛОКАЛЬНЫЕ_ИСХОДНИКИ}
    исходный_стенд = стенд()
    старые = гит('show', п.основа + ':' + ПУТЬ_УСТАНОВЩИКА)
    прежнее = ast.parse(старые)
    новое = ast.parse((КОРЕНЬ / ПУТЬ_УСТАНОВЩИКА).read_bytes())
    имя = '_проверить_журнал_проход'
    узел = next(у for у in прежнее.body if isinstance(у, ast.FunctionDef) and у.name == имя)
    текущий = next(у for у in новое.body if isinstance(у, ast.FunctionDef) and у.name == имя)
    прежнее.body[прежнее.body.index(узел)] = текущий
    if ast.dump(прежнее, include_attributes=False) != ast.dump(новое, include_attributes=False):
        raise ValueError('Изменение выходит за одно тело полного прохода')
    for и in модуль.ЛОКАЛЬНЫЕ_ИСХОДНИКИ:
        if и != ПУТЬ_УСТАНОВЩИКА and (КОРЕНЬ / и).read_bytes() != гит('show', п.основа + ':' + и):
            raise ValueError('Изменена общая зависимость сравниваемых проходов')
    if п.вариант == 'прежний':
        пространство = dict(vars(модуль))
        exec(compile(ast.Module(body=[узел], type_ignores=[]),
            '<принятый-Git-blob:' + hashlib.sha256(старые).hexdigest() + '>', 'exec'), пространство)
        модуль._проверить_журнал_проход = пространство[имя]
    открытая = модуль.приватный({'путь': str(п.открытая), 'sha256': п.хэш_открытой})
    исходный = модуль.журнал._гит
    счётчики = {'Git': 0, 'batch': 0, 'байты_batch': 0}

    def прочитать(*аргументы, **ключи):
        счётчики['Git'] += 1
        данные = исходный(*аргументы, **ключи)
        if аргументы[1:] == ('cat-file', '--batch'):
            счётчики['batch'] += 1
            счётчики['байты_batch'] += len(данные)
        return данные

    начало = time.perf_counter_ns()
    cpu = time.process_time_ns()
    with patch.object(модуль.журнал, '_гит', side_effect=прочитать):
        результат = модуль.проверить_журнал(КОРЕНЬ, п.основа, открытая=открытая)
    wall, cpu = time.perf_counter_ns() - начало, time.process_time_ns() - cpu
    if (снимок() != до or исходники != {и: модуль.прочитать_исходник(и) for и in исходники}
            or стенд() != исходный_стенд):
        raise ValueError('Изменились W, Git или исходники')
    return {'процесс': os.getpid(), 'вариант': п.вариант, 'wall_ns': wall, 'cpu_ns': cpu,
        'maxRSS_байты_macos': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'счётчики': счётчики, 'результат': результат, 'состояние_сохранено': True,
        'основа': п.основа, 'до': до, 'стенд': исходный_стенд,
        'старый_blob_sha256': hashlib.sha256(старые).hexdigest(),
        'исходники': {и: з[0] for и, з in исходники.items()}}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--основа', required=True)
    разбор.add_argument('--открытая', type=Path)
    разбор.add_argument('--хэш-открытой')
    разбор.add_argument('--план-пары', type=Path)
    разбор.add_argument('--хэш-плана-пары')
    разбор.add_argument('--снимок-открытой', type=Path)
    разбор.add_argument('--выход', type=Path)
    разбор.add_argument('--работник', action='store_true')
    разбор.add_argument('--вариант', choices=('прежний', 'новый'))
    п = разбор.parse_args()
    if sys.platform != 'darwin' or sys.flags.optimize:
        raise ValueError('Профиль требует macOS без -O; единицы RSS определены для macOS')
    if п.работник:
        if п.вариант is None or п.открытая is None or п.хэш_открытой is None:
            разбор.error('Нужны вариант работника и точный снимок открытой пары')
        print(json.dumps(работник(п), ensure_ascii=False, sort_keys=True))
        return
    выход = п.выход
    проверить_новый_выход(выход)
    свежий = (п.план_пары, п.хэш_плана_пары, п.снимок_открытой)
    готовый = (п.открытая, п.хэш_открытой)
    if all(з is not None for з in свежий) and all(з is None for з in готовый):
        п.открытая, п.хэш_открытой = подготовить_свежую_пару(п)
    elif any(з is not None for з in свежий) or any(з is None for з in готовый):
        разбор.error('Нужен готовый снимок либо полный отдельный вход свежего снимка')
    пары = []
    до, исходный_стенд = снимок(), стенд()
    начало = time.perf_counter_ns()
    for номер in range(3):
        порядок = ('прежний', 'новый') if номер % 2 == 0 else ('новый', 'прежний')
        пара = {'порядок': порядок}
        for вариант in порядок:
            r = subprocess.run([sys.executable, '-E', '-s', '-S', '-B', str(Path(__file__).resolve()),
                '--работник', '--вариант', вариант, '--основа', п.основа,
                '--открытая', str(п.открытая), '--хэш-открытой', п.хэш_открытой],
                capture_output=True, text=True, timeout=180, check=False)
            if r.returncode:
                sys.stdout.write(r.stdout); sys.stderr.write(r.stderr)
                raise SystemExit(r.returncode)
            пара[вариант] = json.loads(r.stdout)
        пары.append(пара)
    наблюдения = [пара[в] for пара in пары for в in ('прежний', 'новый')]
    if len({н['процесс'] for н in наблюдения}) != 6 or len({н['результат'] for н in наблюдения}) != 1:
        raise ValueError('Процессы не независимы либо результаты различаются')
    if (снимок() != до or стенд() != исходный_стенд
            or any(н['до'] != до or н['стенд'] != исходный_стенд for н in наблюдения)
            or any(н['исходники'] != наблюдения[0]['исходники'] for н in наблюдения)
            or len({н['старый_blob_sha256'] for н in наблюдения}) != 1):
        raise ValueError('Между работниками изменилось сравниваемое состояние или код')
    итог = {'схема': 'fum.RO-профиль-единого-пакета-установщика.1', 'пары': пары,
        'сбор_всего_нс': time.perf_counter_ns() - начало,
        'медианы_wall_ns': {в: statistics.median(пара[в]['wall_ns'] for пара in пары)
            for в in ('прежний', 'новый')},
        'граница': 'Шесть новых процессов одного неподвижного W/H и объявленной открытой пары. '
            'Сравниваются два тела полного RO-прохода при одинаковых текущих зависимостях. '
            'Setup и импорт вне wall; счётчики входят в оба окна. cpu_ns включает только SELF, без CPU Git. '
            'maxRSS — максимум всего работника, включая setup и заключительные проверки. '
            'Кэш ОС не сбрасывается. Установка S1, READY, Create и полный узел не запускаются.'}
    fd = os.open(выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as f:
        f.write((json.dumps(итог, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode())
        f.flush(); os.fsync(f.fileno())
    print(json.dumps({'процессов': 6, 'медианы_wall_ns': итог['медианы_wall_ns']}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
