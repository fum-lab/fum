"""P.2 CLI: один читающий расчёт либо историческая сверка, без эффектов."""
import argparse
import json
from pathlib import Path
import sys
import повторный_план_журнала_состояния as план
import проверенный_повторный_план_состояния as читатель


def главная():
    р = argparse.ArgumentParser(allow_abbrev=False)
    р.add_argument('--корень-репозитория', type=Path, required=True)
    команды = р.add_subparsers(dest='команда', required=True)
    for имя in ('построить', 'сверить'):
        к = команды.add_parser(имя, allow_abbrev=False)
        к.add_argument('--вход', type=Path, required=True); к.add_argument('--профиль', action='store_true')
    а = р.parse_args()
    try:
        вход = план.читатель.канон.разобрать(план.читатель.прочитать_файл(а.вход,
            предел=план.читатель.ПРЕДЕЛ, приватный=True))
        профиль = {} if а.профиль else None
        if а.команда == 'построить': итог = план.построить(вход, корень=а.корень_репозитория, профиль=профиль)
        else:
            план.поля(вход, {'схема', 'план'})
            план.требовать(вход['схема'] == 'fum.чтение-плана-журнала-состояния.2', 'неизвестный вход чтения P.2')
            итог = читатель.прочитать(вход['план'], корень=а.корень_репозитория, профиль=профиль)
    except (ValueError, OSError) as ошибка:
        print(json.dumps({'ошибка': str(ошибка), 'разрешение_установки': False}, ensure_ascii=False), file=sys.stderr)
        return 1
    if а.команда == 'построить': sys.stdout.buffer.write(итог['байты'])
    else: print(json.dumps({'sha256': итог['sha256'], 'байты': len(итог['байты']),
        'разрешение_установки': False}, ensure_ascii=False, sort_keys=True))
    print(json.dumps({'sha256': итог['sha256'], 'профиль': профиль,
        'разрешение_установки': False}, ensure_ascii=False, sort_keys=True), file=sys.stderr)
    return 0


if __name__ == '__main__': raise SystemExit(главная())
