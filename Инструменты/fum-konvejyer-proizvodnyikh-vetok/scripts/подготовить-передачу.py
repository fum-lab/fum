"""Создать приватный вход и выполнить фазу штатного дочернего коммита."""
import argparse
import json
from pathlib import Path
import time

import приватный_вход_передачи as вход


def главная(аргументы=None):
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--каталог', required=True, type=Path)
    команды = парсер.add_subparsers(dest='фаза', required=True)
    сборка = команды.add_parser('вход')
    сборка.add_argument('--корень-репозитория', required=True, type=Path)
    сборка.add_argument('--исходник', required=True, type=Path)
    for поле in ('имя-автора', 'заголовок', 'описание'):
        сборка.add_argument('--' + поле, required=True)
    сборка.add_argument('--цель', action='append', required=True)
    команды.add_parser('подготовить')
    for фаза in ('готово', 'создать'):
        команда = команды.add_parser(фаза)
        команда.add_argument('--проверка', action='append', required=True)
        if фаза == 'готово':
            команда.add_argument('--предел-секунд', type=int, default=600)
    п = парсер.parse_args(аргументы)
    начало = time.monotonic_ns()
    try:
        if п.фаза == 'вход':
            результат = вход.создать_вход(п.корень_репозитория, п.исходник, п.каталог,
                {'имя_автора': п.имя_автора, 'заголовок': п.заголовок, 'описание': п.описание,
                 'разрешённые_цели': п.цель})
        else:
            результат = вход.выполнить_фазу(п.каталог, п.фаза,
                getattr(п, 'проверка', ()), getattr(п, 'предел_секунд', 600))
    except (OSError, ValueError, KeyError, TypeError, RuntimeError) as ошибка:
        print(json.dumps({'схема': 'fum.отказ-приватной-передачи.1', 'ошибка': str(ошибка),
            'повтор_эффекта_разрешён': False, 'длительность_наносекунды': time.monotonic_ns() - начало}, ensure_ascii=False))
        return 2
    print(json.dumps({'результат': результат, 'длительность_наносекунды': time.monotonic_ns() - начало}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
