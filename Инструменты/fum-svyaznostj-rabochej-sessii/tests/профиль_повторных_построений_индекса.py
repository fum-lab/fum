"""Одна штатная сверка на временном Git: повторные построения H/S и их цена."""
import argparse
import contextlib
import hashlib
import json
import os
from pathlib import Path
import sys
import time
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import наблюдение_полного_доказательства as наблюдение
import связность_независимого_журнала as связность
import test_двух_общих_проходов as фикстура
from test_двух_общих_проходов import стенд, снимок


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--пар', type=int, default=32, choices=range(2, 61))
    разбор.add_argument('--выход', type=Path, required=True)
    п = разбор.parse_args()
    выход = п.выход
    if (not выход.is_absolute() or выход.parent.resolve(strict=True) != выход.parent
            or os.path.lexists(выход)
            or any(os.path.lexists(к / '.git')
                or ((к / 'HEAD').is_file() and (к / 'objects').is_dir())
                for к in выход.parents)):
        raise ValueError('Нужен новый физический выход вне Git')
    if sys.version_info[:2] != (3, 14) or sys.flags.optimize:
        raise ValueError('Нужен Python 3.14 без -O')

    with стенд(п.пар) as (р, _):
        ж = р.ж
        точки = (
            (р.м, 'сверить_независимый_журнал', 'вся сверка'),
            (ж, 'построить_принятый_индекс', 'принятый индекс'),
            (ж, 'состав_принятого_дерева', 'состав H'),
            (ж, '_файлы_коммита', 'байты пар H'),
            (ж.индексы, 'построить_индекс', 'чистая навигация'),
            (ж, '_прочитать_объекты', 'пакет Git'),
        )
        корень = Path(__file__).resolve().parents[3]
        пути = {Path(м.__file__).resolve() for м in
            (наблюдение, связность, фикстура, фикстура.независимая)}
        пути.add(Path(__file__).resolve())
        пути.update(Path(м.__file__).resolve() for м, _, _ in точки)

        def код():
            return {путь.relative_to(корень).as_posix():
                hashlib.sha256(путь.read_bytes()).hexdigest()
                for путь in sorted(пути)}

        исходники = код()
        до = снимок(р)
        н = наблюдение.Наблюдение()
        with contextlib.ExitStack() as стек:
            for модуль, имя, роль in точки:
                данные = наблюдение._пакет if роль == 'пакет Git' else None
                стек.enter_context(mock.patch.object(модуль, имя,
                    н.обернуть(роль, getattr(модуль, имя), данные)))
            начало = time.monotonic_ns()
            привязка = р.м.сверить_независимый_журнал(р.п, р.выбранный)
            длительность = time.monotonic_ns() - начало
        if снимок(р) != до or код() != исходники:
            raise AssertionError('Сверка изменила фикстуру или код')
        срез = н.срез()
        if not срез['полон']:
            raise AssertionError('Неполное наблюдение')
        счётчики = {}
        for событие in срез['события']:
            if событие['событие'] == 'начало':
                роль = событие['роль']
                счётчики[роль] = счётчики.get(роль, 0) + 1
        результат = {'схема': 'fum.профиль-повторных-построений-индекса.1',
            'пар': п.пар, 'сверок': 1, 'монотонные_нс': длительность,
            'счётчики': счётчики, 'исходники': исходники,
            'результат_sha256': hashlib.sha256(json.dumps(привязка,
                ensure_ascii=False, sort_keys=True).encode()).hexdigest(),
            'фикстура_не_изменилась': True, 'наблюдение': срез,
            'граница': 'Подготовка и снимки исключены. Временная Git-фикстура, n=1; '
                'не измерение производственного ROOT, Prepare, READY или Create. '
                'Оснастка включена во внешний интервал; вложенные времена не суммируются.'}
    сырые = (json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    fd = os.open(выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as файл:
        файл.write(сырые)
        файл.flush()
        os.fsync(файл.fileno())
    print(json.dumps({'сверок': 1, 'счётчики': счётчики,
        'монотонные_нс': длительность, 'sha256': hashlib.sha256(сырые).hexdigest()},
        ensure_ascii=False))


if __name__ == '__main__':
    главная()
