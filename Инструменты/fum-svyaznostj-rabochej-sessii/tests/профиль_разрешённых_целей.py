"""Рост работы точной проверки T целей; подготовка временного стенда исключена."""
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import time
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import создание_коммита as коммит


@contextmanager
def стенд(число):
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный).resolve()
        каталог = корень / 'цели'
        каталог.mkdir()
        цели = [f'цели/{номер:04d}.txt' for номер in range(число)]
        for имя in цели:
            (корень / имя).write_bytes(b'fixture\n')
        yield корень, каталог, цели


def снимок(корень):
    результат = {}
    for путь in [корень, *sorted(корень.rglob('*'))]:
        с = путь.lstat()
        результат[путь.relative_to(корень).as_posix()] = (
            с.st_dev, с.st_ino, с.st_mode, с.st_mtime_ns, с.st_ctime_ns,
            hashlib.sha256(путь.read_bytes()).hexdigest() if путь.is_file() else None)
    return результат


def измерить(корень, каталог, цели):
    счётчики = {'перечислений': 0, 'имён': 0}
    исходное = Path.iterdir

    def перечислить(путь):
        if путь != каталог:
            yield from исходное(путь)
            return
        счётчики['перечислений'] += 1
        for ребёнок in исходное(путь):
            счётчики['имён'] += 1
            yield ребёнок

    with mock.patch.object(Path, 'iterdir', перечислить):
        начало = time.monotonic_ns()
        результат = коммит.разрешённые_цели(корень, {'разрешённые_цели': цели})
        длительность = time.monotonic_ns() - начало
    if результат is not цели:
        raise AssertionError('Изменился исходный результат проверки')
    return {**счётчики, 'монотонные_нс': длительность}


def проверить_выход(выход):
    if (not выход.is_absolute() or выход.parent.resolve(strict=True) != выход.parent
            or os.path.lexists(выход)
            or any(os.path.lexists(к / '.git')
                or ((к / 'HEAD').is_file() and (к / 'objects').is_dir())
                for к in выход.parents)):
        raise ValueError('Нужен новый физический выход вне Git')


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--выход', type=Path, required=True)
    п = разбор.parse_args()
    проверить_выход(п.выход)
    if sys.version_info[:2] != (3, 14) or sys.flags.optimize:
        raise ValueError('Нужен Python 3.14 без -O')
    корень_кода = Path(__file__).resolve().parents[3]
    пути = {Path(м.__file__).resolve() for м in
        (коммит, коммит.охват, коммит.охват.СВЯЗНОСТЬ)} | {Path(__file__).resolve()}

    def код():
        return {п.relative_to(корень_кода).as_posix():
            hashlib.sha256(п.read_bytes()).hexdigest() for п in sorted(пути)}

    исходники = код()
    наблюдения = []
    for число in (32, 64, 128):
        with стенд(число) as (корень, каталог, цели):
            до = снимок(корень)
            повторы = [измерить(корень, каталог, цели) for _ in range(3)]
            if снимок(корень) != до:
                raise AssertionError('Проверка изменила временный стенд')
            наблюдения.append({'целей': число, 'наблюдения': повторы,
                'стенд_не_изменился': True})
    if код() != исходники:
        raise AssertionError('Исполняемый код изменился во время профиля')
    результат = {'схема': 'fum.профиль-разрешённых-целей.1',
        'исходники': исходники, 'размеры': наблюдения,
        'граница': 'Считаются перечисления и выданные имена общего каталога '
            'в одном штатном вызове разрешённые_цели. Каждый из трёх вызовов '
            'независим. Подготовка и снимки исключены; оснастка включена. '
            'Это профиль роста работы, не ускорение полного ROOT Create.'}
    сырые = (json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    fd = os.open(п.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as файл:
        файл.write(сырые)
        файл.flush()
        os.fsync(файл.fileno())
    print(json.dumps({'sha256': hashlib.sha256(сырые).hexdigest(),
        'размеры': наблюдения}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
