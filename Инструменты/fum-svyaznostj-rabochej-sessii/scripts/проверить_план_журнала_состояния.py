"""Независимый Git-селектор исторического плана; никаких устанавливающих эффектов."""
import argparse
import json
from pathlib import Path
import sys

import проверенный_план_журнала_состояния as читатель


def главная():
    р = argparse.ArgumentParser(allow_abbrev=False)
    р.add_argument('--корень-репозитория', type=Path, required=True)
    р.add_argument('--вход', type=Path, required=True)
    р.add_argument('--профиль', action='store_true')
    а = р.parse_args()
    try:
        исходник = читатель.генератор.читатель.прочитать_файл(а.вход,
            предел=читатель.генератор.читатель.ПРЕДЕЛ, приватный=True)
        вход = читатель.генератор.читатель.канон.разобрать(исходник)
        читатель.поля(вход, {'схема', 'план'})
        читатель.требовать(вход['схема'] == 'fum.чтение-плана-журнала-состояния.1', 'неизвестный вход чтения')
        профиль = {} if а.профиль else None
        итог = читатель.прочитать(вход['план'], корень=а.корень_репозитория, профиль=профиль)
    except (ValueError, OSError) as ошибка:
        print(json.dumps({'ошибка': str(ошибка), 'разрешение_установки': False}, ensure_ascii=False), file=sys.stderr)
        return 1
    print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'разрешение_установки': False}, ensure_ascii=False, sort_keys=True))
    if профиль is not None: print(json.dumps(профиль, ensure_ascii=False, sort_keys=True), file=sys.stderr)
    return 0


if __name__ == '__main__': raise SystemExit(главная())
