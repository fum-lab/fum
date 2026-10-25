"""В stdout только проверенный план; установка и API-вызовы отсутствуют."""
import argparse
import json
from pathlib import Path
import sys

import план_журнала_писателя_состояния as план


def главная():
    разбор = argparse.ArgumentParser(allow_abbrev=False)
    разбор.add_argument('--корень-репозитория', type=Path, required=True)
    разбор.add_argument('--вход', type=Path, required=True)
    разбор.add_argument('--профиль', action='store_true')
    а = разбор.parse_args()
    try:
        сырые = план.читатель.прочитать_файл(а.вход, предел=план.читатель.ПРЕДЕЛ, приватный=True)
        вход = план.читатель.канон.разобрать(сырые)
        профиль = {} if а.профиль else None
        итог = план.построить(вход, корень=а.корень_репозитория, профиль=профиль)
    except (ValueError, OSError) as ошибка:
        print(json.dumps({'ошибка': str(ошибка), 'разрешение_установки': False}, ensure_ascii=False), file=sys.stderr)
        return 1
    sys.stdout.buffer.write(итог['байты'])
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'разрешение_установки': False, 'профиль': профиль}, ensure_ascii=False, sort_keys=True), file=sys.stderr)
    return 0


if __name__ == '__main__': raise SystemExit(главная())
