#!/usr/bin/env python3
"""Профилировать исходник, сохраняя его исход; дамп остаётся приватным."""
import cProfile as профилирование
import marshal as формат
import os as ос
import runpy as запуск
import sys as система
import traceback as трассировка
from pathlib import Path as Путь


def главная():
    if len(система.argv) < 3:
        raise SystemExit('Нужны: приватный_выход исходник [аргументы...]')
    выход = Путь(система.argv[1])
    исходник = Путь(система.argv[2]).resolve(strict=True)
    система.argv = [str(исходник), *система.argv[3:]]
    система.path[:1] = [str(исходник.parent)]
    профиль = профилирование.Profile()
    флаги = ос.O_WRONLY | ос.O_CREAT | ос.O_EXCL | ос.O_NOFOLLOW
    поток = ос.fdopen(ос.open(выход, флаги, 0o600), 'wb')
    первичная_ошибка = None
    try:
        профиль.runcall(запуск.run_path, str(исходник), run_name='__main__')
    except BaseException as ошибка:
        первичная_ошибка = ошибка
        raise
    finally:
        try:
            with поток:
                профиль.create_stats()
                ос.fchmod(поток.fileno(), 0o600)
                формат.dump(профиль.stats, поток)
                поток.flush()
                ос.fsync(поток.fileno())
        except BaseException:
            try:
                print('Не удалось сохранить приватный профиль.', file=система.stderr)
                трассировка.print_exc()
            except BaseException:
                pass
            if первичная_ошибка is None or (isinstance(первичная_ошибка, SystemExit)
                    and первичная_ошибка.code in (None, 0)):
                raise SystemExit(1)


if __name__ == '__main__':
    главная()
