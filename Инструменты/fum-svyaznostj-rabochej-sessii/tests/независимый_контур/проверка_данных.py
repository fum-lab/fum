"""Выбранный отдельный CLI читает только данные лабораторного W."""
import json
import os
from pathlib import Path
import sys


def главная():
    assert sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode
    assert Path('данные.txt').read_text(encoding='utf-8') == 'проверено\n'
    if len(sys.argv) == 3 and sys.argv[1] == '--преграда':
        выход = Path(sys.argv[2])
        def преграда(кадр, событие, значение):
            родитель = кадр.f_back
            if (событие == 'return' and кадр.f_code.co_qualname == 'ПроверенныйКонтур.сверить'
                and родитель is not None
                and родитель.f_code.co_qualname == 'ПроверенныйКонтур.разрешить_запись'
                and родитель.f_locals.get('значение') == выход):
                sys.setprofile(None)
                print('FUM-ПРЕГРАДА-ПОСЛЕ-СВЕРКИ', file=sys.stderr, flush=True)
                if sys.stdin.readline() != 'продолжить\n':
                    raise ValueError('родитель не продолжил лабораторную преграду')
        sys.setprofile(преграда)
        выход.write_bytes('Разрешённый лабораторный выход\n'.encode())
        sys.setprofile(None)
    else:
        assert len(sys.argv) == 1
    print(json.dumps({'процесс': os.getpid(), 'изоляция': True, 'данные': 'проверено'}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
