"""Исторический Git-селектор A.2, без нового права эффекта."""
import argparse
import json
from pathlib import Path
import sys

import проверенные_повторные_полномочия_узла as читатель
import состояние_задач_узла as состояние


def главная():
    р = argparse.ArgumentParser(allow_abbrev=False)
    р.add_argument('--корень-репозитория', type=Path, required=True)
    р.add_argument('--вход', type=Path, required=True)
    р.add_argument('--профиль', action='store_true')
    а = р.parse_args()
    try:
        вход = состояние.канон.разобрать(состояние.прочитать_файл(а.вход,
            предел=состояние.ПРЕДЕЛ, приватный=True))
        читатель.полномочия.поля(вход, {'схема', 'полномочия'})
        читатель.полномочия.требовать(вход['схема'] == 'fum.чтение-повторных-полномочий-узла.1', 'неизвестный вход чтения A.2')
        профиль = {} if а.профиль else None
        итог = читатель.прочитать(вход['полномочия'], корень=а.корень_репозитория, профиль=профиль)
    except (ValueError, OSError) as ошибка:
        print(json.dumps({'ошибка': str(ошибка), 'разрешение_установки': False}, ensure_ascii=False), file=sys.stderr)
        return 1
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'строгий_порядок_Git': итог['строгий_порядок_Git'], 'разрешение_установки': False}, ensure_ascii=False, sort_keys=True))
    if профиль is not None: print(json.dumps(профиль, ensure_ascii=False, sort_keys=True), file=sys.stderr)
    return 0


if __name__ == '__main__': raise SystemExit(главная())
