"""Читающий изолированный допуск открытой пары ветки состояния; без полномочий из копии."""
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys

КОРЕНЬ_КОДА = Path(__file__).resolve().parents[3]
КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()

# Обычный guard импортируется в отдельном процессе из точных исходных байтов.
# Карта включает и обычные, и динамические импорты SourceFileLoader.
КОД_ДОПУСКА = '''
import base64, hashlib, importlib.machinery, json, os, pathlib, stat, sys
корень = pathlib.Path(sys.argv[1]); отпечатки = {}
прежний = importlib.machinery.SourceFileLoader.get_code
def загрузить(сам, имя):
    путь = pathlib.Path(сам.get_filename(имя))
    if путь.is_relative_to(корень):
        if путь != путь.resolve() or any(п.is_symlink() for п in (путь,*путь.parents)) or not stat.S_ISREG(путь.lstat().st_mode):
            raise ValueError('Необычный исходник допуска')
        данные = путь.read_bytes(); имя_пути = путь.relative_to(корень).as_posix()
        SHA = hashlib.sha256(данные).hexdigest()
        if имя_пути in отпечатки and отпечатки[имя_пути] != SHA:
            raise ValueError('Разные загруженные версии исходника допуска')
        отпечатки[имя_пути] = SHA
        return compile(данные,str(путь),'exec',dont_inherit=True)
    return прежний(сам,имя)
importlib.machinery.SourceFileLoader.get_code = загрузить
sys.path.insert(0,str(корень/'Инструменты/fum-svyaznostj-rabochej-sessii/scripts'))
import создание_коммита as создатель
import обычное_поручение as обычное
if pathlib.Path(создатель.__file__) != корень/'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py':
    raise ValueError('Чужой creator')
def вход(номер):
    данные = создатель.прочитать(sys.argv[номер],приватный=True)
    if hashlib.sha256(данные).hexdigest() != sys.argv[номер+1]: raise ValueError('Подмена сырого основания')
    return создатель.сообщения._разобрать(данные)
maker = вход(2); выбор = вход(4)
if maker.get('схема') != 'fum.создание-коммита.8': raise ValueError('Наполнение .2 требует maker .8')
привязка = создатель.сверить_обычное_поручение(maker,выбор,новый_эффект=True)
дерево = pathlib.Path(maker['корень'])
акт = обычное.прочитать_акт(дерево,выбор,новый_эффект=True)
if акт['схема'] != 'fum.поручение-дочерней-контрольной-точки.2': raise ValueError('Нужен независимый ACT2')
if os.path.lexists(maker['квитанция']) or os.path.lexists(создатель.готовность.путь_этапа(maker)):
    raise ValueError('Готовый этап не наполняется')
C = акт['постановка']['коммит']
парные = [maker['запрос'],pathlib.Path(maker['запрос']).with_name('отчёт.md').as_posix()]
исходные = {}
for имя in парные:
    описание = обычное._гит(дерево,'--literal-pathspecs','ls-tree','-z',C,'--',имя)
    сейчас = обычное._гит(дерево,'--literal-pathspecs','ls-tree','-z','HEAD','--',имя)
    if описание != сейчас or not описание: raise ValueError('HEAD-пара отличается от launch C')
    мета, путь = описание.rstrip(chr(0)).split('\t'); режим, тип, OID = мета.split()
    if путь != имя or тип != 'blob' or режим not in ('100644','100755'): raise ValueError('Пара C не является обычными blob')
    данные = обычное.охват.выполнить_git(дерево,'cat-file','blob',OID)
    if len(данные)>4*1024*1024: raise ValueError('Пара превышает конечную границу')
    исходные[имя] = {'тип':'файл','режим':0o755 if режим=='100755' else 0o644,'sha256':hashlib.sha256(данные).hexdigest()}
for имя,SHA in отпечатки.items():
    путь=корень/имя
    if путь!=путь.resolve() or hashlib.sha256(путь.read_bytes()).hexdigest()!=SHA: raise ValueError('Код допуска изменился')
print(json.dumps({'maker':maker,'акт':акт,'привязка':привязка,'C':C,'исходные':исходные,'код':отпечатки},ensure_ascii=False,sort_keys=True))
'''


def _файл(данные, корень):
    if (type(данные) is not dict or set(данные) != {'путь','sha256'}
            or type(данные['sha256']) is not str or re.fullmatch('[0-9a-f]{64}',данные['sha256']) is None):
        raise ValueError('Основание связывает точный приватный путь с сырым SHA256')
    путь = Path(данные['путь'])
    if (not путь.is_absolute() or путь != путь.resolve() or путь.is_relative_to(корень)
            or any(п.is_symlink() or os.path.lexists(п/'.git') for п in (путь,*путь.parents))):
        raise ValueError('Основание находится в символическом пути или Git')
    состояние = путь.lstat(); родитель = путь.parent.stat()
    if (not stat.S_ISREG(состояние.st_mode) or состояние.st_uid != os.getuid()
            or stat.S_IMODE(состояние.st_mode) != 0o600 or состояние.st_size>4*1024*1024
            or родитель.st_uid!=os.getuid() or stat.S_IMODE(родитель.st_mode)!=0o700
            or hashlib.sha256(путь.read_bytes()).hexdigest()!=данные['sha256']):
        raise ValueError('Не совпадают владение, режим или сырые байты основания')
    return путь


def проверить(корень, вход, цели):
    if вход.get('схема') != 'fum.наполнение-карточки.2':
        raise ValueError('Изолированный допуск применяется только к наполнению .2')
    основание = вход.get('основание')
    if type(основание) is not dict or set(основание) != {'вход_коммита','поручение'}:
        raise ValueError('Нужны maker и независимый селектор ACT2')
    файлы = [_файл(основание[к],Path(корень)) for к in ('вход_коммита','поручение')]
    if файлы[0] == файлы[1]: raise ValueError('Роли основания должны различаться')
    аргументы = [str(КОРЕНЬ_КОДА)]
    for ключ,файл in zip(('вход_коммита','поручение'),файлы):
        аргументы += [str(файл),основание[ключ]['sha256']]
    процесс = subprocess.run([sys.executable,'-B','-I','-c',КОД_ДОПУСКА,*аргументы],
        cwd=корень,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=60)
    if процесс.returncode:
        строки = процесс.stderr.decode().splitlines()
        raise ValueError('Штатный допуск состояния отказал: '+(строки[-1] if строки else str(процесс.returncode)))
    результат = json.loads(процесс.stdout)
    maker = результат.pop('maker')
    if (maker['корень']!=str(корень) or maker['задача']!=вход['задача']
            or maker['запрос']!=вход['запрос'] or maker['разрешённые_цели']!=цели):
        raise ValueError('Допуск отличается от ROOT, дерева, пары или упорядоченного T')
    for ключ in ('вход_коммита','поручение'): _файл(основание[ключ],Path(корень))
    return результат
