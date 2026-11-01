"""До create_thread сверить постановку и требуемый код в одном точном OID.

Пример: python3 -B предзапускная_база.py --корень <физический-корень-FUM>
  --коммит <полный-OID> --постановка <путь> --sha256 <SHA256>
  --код <путь-исходника> <SHA256> [--код <путь> <SHA256> ...]

Читает только Git-объекты; не выполняет исходники и не меняет checkout/refs.
Успех не является ACT, приёмкой S, проверкой native initialC или правом записи.
Вызывающий создаёт задачу только после успеха и передаёт тот же полный OID.
Фактический initialC новой задачи затем всё равно проверяется отдельно.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess


def проверить(корень, коммит, постановка, хэш_постановки, код):
    корень = Path(корень)
    if not корень.is_absolute() or корень != корень.resolve():
        raise ValueError('нужен физический корень')
    if type(коммит) is not str or re.fullmatch(r'(?:[0-9a-f]{40}|[0-9a-f]{64})', коммит) is None:
        raise ValueError('нужен полный OID коммита')
    if type(код) is not list or not 1 <= len(код) <= 64:
        raise ValueError('нужен конечный явный перечень кодовых файлов')
    требования = [(постановка, хэш_постановки)] + код
    имена = set()
    for запись in требования:
        if type(запись) not in (tuple, list) or len(запись) != 2:
            raise ValueError('нужны путь и SHA256')
        имя, хэш = запись
        if (type(имя) is not str or not имя or ':' in имя or '\\' in имя
                or any(знак in имя for знак in ('\0', '\n', '\r', '\t'))
                or PurePosixPath(имя).is_absolute() or PurePosixPath(имя).as_posix() != имя
                or any(часть in ('.', '..') for часть in имя.split('/')) or имя in имена):
            raise ValueError('нужен точный неповторяющийся относительный путь')
        if type(хэш) is not str or re.fullmatch('[0-9a-f]{64}', хэш) is None:
            raise ValueError('нужен полный SHA256')
        имена.add(имя)
    среда = {к: з for к, з in os.environ.items() if not к.startswith('GIT_')}
    среда.update(GIT_OPTIONAL_LOCKS='0', GIT_NO_REPLACE_OBJECTS='1', GIT_NO_LAZY_FETCH='1',
        GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull)
    def гит(*аргументы):
        процесс = subprocess.run(['git', '--no-replace-objects', '--no-optional-locks',
            '-c', 'core.hooksPath=' + os.devnull, '-C', str(корень), *аргументы],
            capture_output=True, timeout=30, env=среда)
        if процесс.returncode:
            raise ValueError('недоступен требуемый Git-объект')
        return процесс.stdout
    if гит('rev-parse', '--verify', коммит + '^{commit}').decode().strip() != коммит:
        raise ValueError('выбран иной коммит')
    записи = {}
    for строка in filter(None, гит('ls-tree', '-z', '--full-tree', коммит, '--', *sorted(имена)).split(b'\0')):
        заголовок, имя = строка.split(b'\t', 1)
        режим, тип, идентификатор = заголовок.decode().split()
        имя = имя.decode()
        if имя in записи:
            raise ValueError('повтор Git-пути')
        записи[имя] = (режим, тип, идентификатор)
    проверенные = []
    полный_перечень = False
    for имя, ожидаемый in требования:
        запись = записи.get(имя)
        if запись is None or запись[0] not in ('100644', '100755') or запись[1] != 'blob':
            raise ValueError('нет требуемого обычного файла: ' + имя)
        идентификатор = запись[2]
        размер = int(гит('cat-file', '-s', идентификатор))
        if not 0 <= размер <= 4 * 1024 * 1024:
            raise ValueError('требуемый файл превышает предел чтения')
        сырые = гит('cat-file', 'blob', идентификатор)
        if len(сырые) != размер or hashlib.sha256(сырые).hexdigest() != ожидаемый:
            raise ValueError('неверный SHA256 требуемого файла: ' + имя)
        if имя == постановка and сырые.lstrip().startswith(b'{'):
            def без_повторов(пары):
                объект = {}
                for ключ, значение in пары:
                    if ключ in объект:
                        raise ValueError('повтор поля постановки')
                    объект[ключ] = значение
                return объект
            описание = json.loads(сырые, object_pairs_hook=без_повторов)
            if описание.get('схема') == 'fum.постановка-исторической-совместимости.1':
                заявленные = описание.get('обязательные_исходники')
                ожидаемые = [{'путь': путь, 'sha256': хэш} for путь, хэш in код]
                if type(заявленные) is not list or заявленные != ожидаемые:
                    raise ValueError('перечень кода отличается от постановки')
                полный_перечень = True
        проверенные.append({'путь': имя, 'sha256': ожидаемый,
            'blob': идентификатор, 'режим': запись[0], 'байты': размер})
    return {'схема': 'fum.предзапускная-кодовая-база.1', 'коммит': коммит,
        'постановка': проверенные[0], 'код': проверенные[1:],
        'полный_перечень_постановки': полный_перечень,
        'разрешает_запись': False, 'исходники_исполнялись': False}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--корень', type=Path, required=True)
    разбор.add_argument('--коммит', required=True)
    разбор.add_argument('--постановка', required=True)
    разбор.add_argument('--sha256', required=True)
    разбор.add_argument('--код', nargs=2, action='append', required=True)
    вход = разбор.parse_args()
    try:
        результат = проверить(вход.корень, вход.коммит, вход.постановка, вход.sha256, вход.код)
    except (ValueError, OSError, subprocess.TimeoutExpired) as ошибка:
        print(json.dumps({'схема': 'fum.отказ-предзапускной-базы.1',
            'причина': str(ошибка), 'разрешает_запись': False}, ensure_ascii=False))
        return 2
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(главная())
