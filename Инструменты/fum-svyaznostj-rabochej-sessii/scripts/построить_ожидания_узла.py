"""CLI выводит только кандидат в stdout; новое доверие не выдаётся."""
import argparse
import json
from pathlib import Path
import sys

import выбор_ожиданий_узла as выбор


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--корень-репозитория', type=Path, required=True)
    разбор.add_argument('--вход', type=Path, required=True)
    разбор.add_argument('--профиль', action='store_true')
    аргументы = разбор.parse_args()
    try:
        данные = выбор.читатель.прочитать_файл(аргументы.вход,
            предел=выбор.читатель.ПРЕДЕЛ, приватный=True)
        вход = выбор.канон.разобрать(данные)
        профиль = {} if аргументы.профиль else None
        итог = выбор.построить(вход, корень=аргументы.корень_репозитория, профиль=профиль)
    except (ValueError, OSError) as ошибка:
        print(json.dumps({'ошибка': str(ошибка), 'допуск_эффекта': False}, ensure_ascii=False), file=sys.stderr)
        return 1
    sys.stdout.buffer.write(итог['кандидат'])
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['кандидат']),
        'допуск_эффекта': False, 'профиль': профиль}, ensure_ascii=False, sort_keys=True), file=sys.stderr)
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
