"""Прочитать известную обёртку и её исходный stdout, не исполняя обёртку."""
import hashlib
from pathlib import Path, PurePosixPath

КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()

import отказ_нативного_приёма as прямой
import приём_направления as хранение


def программа(цель, путь):
    return f"""python3 -B - <<'PY'
from pathlib import Path
import subprocess,json,os
корень=Path({цель['корень']!r})
приватный=Path({str(PurePosixPath(путь).parent)!r})
assert приватный.is_dir() and not приватный.is_symlink()
assert приватный.stat().st_uid==os.getuid() and приватный.stat().st_mode & 0o777 == 0o700
цель=приватный/'ответ-приёма.json'
assert not цель.exists()
команда=['python3','-B','Инструменты/fum-konvejyer-proizvodnyikh-vetok/scripts/подготовить-приём.py','принять','--исходник',{цель['исходник']!r}]
with цель.open('x') as файл:
    процесс=subprocess.run(команда,cwd=корень,stdout=файл,text=True)
print('код:',процесс.returncode)
print('ответ:',цель.read_text())
raise SystemExit(процесс.returncode)
PY"""


def проверить(сырые, цель, канал, артефакт):
    данные, элемент = прямой.вызов(сырые, цель)
    хранение.поля(артефакт, {'путь', 'байты', 'sha256'})
    ожидаемый = '/private/var/tmp/fum-soobsjheniya-' + цель['задача'] + '/ответ-приёма.json'
    хранение.требовать(type(канал) is bytes and 0 < len(канал) <= прямой.ПРЕДЕЛ
        and канал.endswith(b'\n') and type(артефакт['байты']) is int
        and артефакт['байты'] == len(канал) and артефакт['путь'] == ожидаемый
        and хранение.шестнадцатеричный(артефакт['sha256'])
        and артефакт['sha256'] == hashlib.sha256(канал).hexdigest(),
        'Нет точного исходного канала известной обёртки')
    текст = канал.decode('utf-8')
    команда = элемент.get('command')
    хранение.требовать(команда == ['/bin/zsh', '-lc', программа(цель, артефакт['путь'])],
        'Неизвестная обёртка сохранения CLI-канала')
    хранение.требовать(элемент['stdout'].encode('utf-8')
        == 'код: 2\nответ: '.encode('utf-8') + канал + b'\n',
        'Первичный вывод обёртки отличается от сохранённого CLI-канала')
    итог = прямой.результат(цель, данные, текст, прямой.ответ(канал))
    итог['схема'] = 'fum.первичный-отказ-сохранённого-приёма.1'
    итог['артефакт'] = dict(артефакт)
    итог['обёртка'] = {'код': 2,
        'команда_sha256': hashlib.sha256(команда[2].encode('utf-8')).hexdigest(),
        'stdout_sha256': hashlib.sha256(элемент['stdout'].encode('utf-8')).hexdigest(),
        'stderr_sha256': hashlib.sha256(b'').hexdigest()}
    return итог
