"""Обновляет только управляемый блок состава по точному входу подготовки коммита."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
import tempfile
import time

КОРЕНЬ_КОДА = Path(__file__).resolve().parents[3]
КАТАЛОГ_СКРИПТОВ = Path(__file__).resolve().parent
if str(КАТАЛОГ_СКРИПТОВ) not in sys.path:
    sys.path.insert(0, str(КАТАЛОГ_СКРИПТОВ))

import request_folder_layout as каркас
import блоки_карточки as рендер
import управляемые_блоки as блоки

КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
ЗАДАЧА = re.compile(r'^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
ХЭШ = re.compile(r'^[0-9a-f]{64}$')
ИМЯ_ЗАПУСКА = re.compile(r'[1-9][0-9]*_[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\.json')

ПУТИ_ИСПОЛНЯЕМОГО_КОНТУРА = (
    Path(__file__),
    Path(каркас.__file__),
    Path(рендер.__file__),
    Path(блоки.__file__),
    КОРЕНЬ_КОДА / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py',
)


def _хэш(байты: bytes) -> str:
    return hashlib.sha256(байты).hexdigest()


def _уникальные_поля(пары):
    результат = {}
    for ключ, значение in пары:
        if ключ in результат:
            raise ValueError('Повторное поле JSON запрещено')
        результат[ключ] = значение
    return результат


def _канонический_json(значение) -> bytes:
    return json.dumps(значение, ensure_ascii=False, sort_keys=True,
                      separators=(',', ':'), allow_nan=False).encode('utf-8') + b'\n'


def _git(корень: Path, *аргументы: str) -> bytes:
    результат = subprocess.run(
        ['git', '-C', str(корень), *аргументы], check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return результат.stdout


def _обычный_внешний_вход(путь: Path, корень: Path) -> tuple[Path, bytes]:
    if not путь.is_absolute() or путь != путь.resolve() or путь.is_relative_to(корень):
        raise ValueError('Вход сохраняется обычным файлом вне checkout')
    if any(предок.is_symlink() or os.path.lexists(предок / '.git') for предок in путь.parents):
        raise ValueError('Символический путь или Git checkout во входной цепочке запрещён')
    if путь.is_symlink() or not stat.S_ISREG(путь.lstat().st_mode):
        raise ValueError('Вход должен быть обычным файлом')
    if путь.stat().st_size > 4 * 1024 * 1024 or путь.stat().st_mode & 0o077:
        raise ValueError('Внешний вход должен быть ограничен и доступен только владельцу')
    return путь, путь.read_bytes()


def _путь_репозитория(корень: Path, относительный: str, *, отсутствует_допустимым=False) -> Path:
    if (type(относительный) is not str or not относительный
            or относительный != PurePosixPath(относительный).as_posix()
            or PurePosixPath(относительный).is_absolute()
            or any(часть in {'.', '..', '.git'} for часть in относительный.split('/'))
            or re.search(r'[\x00-\x1f\x7f\\#?]', относительный)):
        raise ValueError('Требуется точный относительный путь файла')
    путь = корень
    части = относительный.split('/')
    for номер, часть in enumerate(части):
        путь = путь / часть
        финал = номер == len(части) - 1
        if not os.path.lexists(путь):
            if финал and отсутствует_допустимым:
                return путь
            raise ValueError('Разрешённая цель отсутствует: ' + относительный)
        if путь.is_symlink():
            raise ValueError('Символическая ссылка в разрешённой цели запрещена: ' + относительный)
        if not финал and not путь.is_dir():
            raise ValueError('Компонент пути не является каталогом: ' + относительный)
    if not путь.is_file():
        raise ValueError('Разрешённая цель должна быть обычным файлом: ' + относительный)
    if путь.resolve() != путь:
        raise ValueError('Разрешённая цель выходит за checkout')
    return путь


def _прочитать_разрешение(корень: Path, путь_запроса: str, путь_разрешения: Path):
    путь_разрешения, байты = _обычный_внешний_вход(путь_разрешения, корень)
    вход = json.loads(байты, object_pairs_hook=_уникальные_поля)
    if type(вход) is not dict:
        raise ValueError('Разрешение состава должно быть JSON-объектом')
    схема = вход.get('схема')
    if схема == 'fum.создание-коммита.2':
        поля = {'задача', 'запрос', 'корень', 'ветка', 'исходный_коммит', 'разрешённые_цели'}
    elif схема == 'fum.разрешение-состава-карточки.1':
        поля = {'задача', 'запрос', 'корень', 'ветка', 'исходный_коммит',
                'разрешённые_цели', 'ожидаемые_цели'}
        if set(вход) != {'схема', *поля}:
            raise ValueError('Неверные поля самостоятельного разрешения состава')
    else:
        raise ValueError('Неизвестная схема разрешения состава')
    if not поля <= set(вход):
        raise ValueError('В разрешении состава отсутствуют обязательные поля')
    if (type(вход['задача']) is not str or not ЗАДАЧА.fullmatch(вход['задача'])
            or вход['запрос'] != путь_запроса or вход['корень'] != str(корень)):
        raise ValueError('Разрешение не относится к этой задаче, запросу и корню')
    if type(вход['ветка']) is not str or type(вход['исходный_коммит']) is not str:
        raise ValueError('Ref и исходный коммит должны быть явными строками')
    цели = вход['разрешённые_цели']
    ожидаемые = вход.get('ожидаемые_цели', [])
    for имя, значение in (('разрешённые_цели', цели), ('ожидаемые_цели', ожидаемые)):
        if (type(значение) is not list or any(type(путь) is not str for путь in значение)
                or len(set(значение)) != len(значение)):
            raise ValueError(f'{имя} должен быть списком уникальных путей')
    if not цели or not set(ожидаемые) <= set(цели):
        raise ValueError('Список целей пуст или ожидаемые файлы вне разрешённого состава')
    путь_отчёта = str(PurePosixPath(путь_запроса).with_name('отчёт.md'))
    if not {путь_запроса, путь_отчёта} <= set(цели):
        raise ValueError('Разрешение должно включать запрос и отчёт своей сессии')
    папка_запусков = str(PurePosixPath(путь_запроса).parent / 'материалы/запуски-проверок') + '/'
    for имя in цели:
        _путь_репозитория(корень, имя, отсутствует_допустимым=имя in ожидаемые)
        if имя in ожидаемые and not имя.startswith(папка_запусков):
            raise ValueError('Ожидаемая цель должна быть записью проверки своей сессии')
        if имя in ожидаемые and not ИМЯ_ЗАПУСКА.fullmatch(имя[len(папка_запусков):]):
            raise ValueError('Ожидаемая цель должна иметь точное имя машинной записи проверки')
    if any(имя not in цели for имя in (путь_запроса, путь_отчёта)):
        raise ValueError('Запрос и отчёт должны входить в разрешённый состав')
    return вход, путь_разрешения, байты, sorted(цели), sorted(ожидаемые)


def _загрузить_проверку_связности():
    путь = КОРЕНЬ_КОДА / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py'
    имя = '_fum_проверка_связности_состава'
    существующий = sys.modules.get(имя)
    if существующий is not None:
        if Path(существующий.__file__).resolve() != путь.resolve():
            raise ValueError('Проверка связности загружена из другого checkout')
        return существующий
    спецификация = importlib.util.spec_from_file_location(имя, путь)
    if спецификация is None or спецификация.loader is None:
        raise ValueError('Не удалось загрузить штатный парсер состава')
    модуль = importlib.util.module_from_spec(спецификация)
    sys.modules[имя] = модуль
    спецификация.loader.exec_module(модуль)
    return модуль


def _разобрать_статус_v2(байты: bytes) -> tuple[str, str, set[str]]:
    oid = None
    имя_ветки = None
    пути = set()
    части = байты.split(b'\0')
    индекс = 0
    while индекс < len(части):
        запись = части[индекс]
        индекс += 1
        if not запись:
            continue
        if запись.startswith(b'# branch.oid '):
            if oid is not None:
                raise ValueError('Повторный branch.oid в Git-status')
            oid = запись[len(b'# branch.oid '):].decode('ascii', 'strict')
            continue
        if запись.startswith(b'# branch.head '):
            if имя_ветки is not None:
                raise ValueError('Повторный branch.head в Git-status')
            имя_ветки = запись[len(b'# branch.head '):].decode('utf-8', 'strict')
            continue
        if запись.startswith(b'# '):
            continue
        if запись.startswith(b'1 '):
            поля = запись.split(b' ', 8)
            if len(поля) != 9 or b'U' in поля[1]:
                raise ValueError('Повреждённая или конфликтная запись Git-status')
            пути.add(поля[8].decode('utf-8', 'strict'))
            continue
        if запись.startswith(b'2 '):
            поля = запись.split(b' ', 9)
            if len(поля) != 10 or b'U' in поля[1] or индекс >= len(части):
                raise ValueError('Повреждённая или конфликтная запись переименования Git-status')
            пути.add(поля[9].decode('utf-8', 'strict'))
            пути.add(части[индекс].decode('utf-8', 'strict'))
            индекс += 1
            continue
        if запись.startswith(b'u '):
            raise ValueError('Неразрешённые конфликты индекса закрывают обновление')
        if запись.startswith(b'? '):
            пути.add(запись[2:].decode('utf-8', 'strict'))
            continue
        raise ValueError('Неизвестная запись Git-status v2')
    if (oid is None or имя_ветки is None or имя_ветки == '(detached)'
            or not (ХЭШ.fullmatch(oid) or re.fullmatch(r'[0-9a-f]{40}', oid))):
        raise ValueError('Git-status не подтверждает полный HEAD и именованную ветку')
    return oid, 'refs/heads/' + имя_ветки, пути


def _хэши_исполняемого_контура():
    результат = {}
    for путь in ПУТИ_ИСПОЛНЯЕМОГО_КОНТУРА:
        if путь.is_symlink() or not путь.is_file() or путь.resolve() != путь:
            raise ValueError('Исполняемый контур должен состоять из канонических файлов checkout')
        результат[путь.relative_to(КОРЕНЬ_КОДА).as_posix()] = _хэш(путь.read_bytes())
    return результат


def _срез_состава(байты_запроса: bytes) -> tuple[bytes, bytes, bytes]:
    границы = блоки.границы_блоков(байты_запроса)
    if 'состав' not in границы:
        raise ValueError('Управляемый блок состава отсутствует')
    начало, конец, _ = границы['состав']
    строки = list(блоки.структурные_строки(байты_запроса))
    заголовки = [(а, б, текст[3:]) for а, б, текст in строки if текст.startswith('## ')]
    раздел = [(а, б) for а, б, имя in заголовки if имя == 'Повлиял на файлы']
    if len(раздел) != 1:
        raise ValueError('Раздел «Повлиял на файлы» должен встречаться ровно один раз')
    а, б = раздел[0]
    следующий = next((начало for начало, _, _ in заголовки if начало > а), len(байты_запроса))
    if not а <= начало <= конец <= следующий:
        raise ValueError('Блок состава находится вне раздела «Повлиял на файлы»')
    return байты_запроса[:начало], байты_запроса[начало:конец], байты_запроса[конец:]


def _сформировать_запрос(корень: Path, путь_запроса: str, исходные: bytes,
                         цели: list[str], ожидаемые: list[str]) -> tuple[bytes, dict]:
    начало, прежний_блок, конец = _срез_состава(исходные)
    шаблон = рендер.прочитать_шаблоны()['блок-состава.md.шаблон']
    папка = str(PurePosixPath(путь_запроса).parent)
    ссылки = []
    отсутствующие_ожидаемые = []
    for путь in цели:
        отсутствует = ожидаемые and путь in ожидаемые and not (корень / путь).exists()
        ссылки.append(рендер._ссылка(путь, папка, bool(отсутствует)))
        if отсутствует:
            отсутствующие_ожидаемые.append(путь)
    тело = каркас._заполнить_шаблон(шаблон, {'ссылки': '\n'.join(ссылки)}).encode('utf-8')
    результат = блоки.заменить_блоки(исходные, {'состав': тело})
    if _срез_состава(результат)[0] != начало or _срез_состава(результат)[2] != конец:
        raise ValueError('Генерация изменила байты за пределами блока состава')
    парсер = _загрузить_проверку_связности()
    обнаружено, ошибки = парсер.affected_files_from_request(
        результат.decode('utf-8'), корень / путь_запроса, корень,
    )
    найдено = {путь.relative_to(корень).as_posix() for путь in обнаружено}
    if (ошибки or найдено != set(цели) or обнаружено.existing_directories
            or обнаружено.deleted_subtrees or обнаружено.deleted_direct_files_directories):
        raise ValueError('Сгенерированный блок не соответствует точному разрешённому составу')
    старый, старые_ошибки = парсер.affected_files_from_request(
        исходные.decode('utf-8'), корень / путь_запроса, корень,
    )
    старые = {путь.relative_to(корень).as_posix() for путь in старый}
    новые = set(цели) - старые
    удалённые = старые - set(цели)
    return результат, {
        'цели': цели,
        'ожидаемые_цели': отсутствующие_ожидаемые,
        'новые_ссылки': sorted(новые),
        'удалённые_ссылки': sorted(удалённые),
        'изменить': результат != исходные,
        'блок_sha256_до': _хэш(прежний_блок),
        'блок_sha256_после': _хэш(тело),
        'запрос_sha256_до': _хэш(исходные),
        'запрос_sha256_после': _хэш(результат),
    }


def _снимок_git(корень: Path, цели: list[str]) -> dict:
    корень_git = _git(корень, 'rev-parse', '--show-toplevel').decode().strip()
    if Path(корень_git).resolve() != корень:
        raise ValueError('Нужен точный физический корень собственного checkout')
    индекс = _git(корень, 'ls-files', '--stage', '-z')
    статус = _git(корень, 'status', '--porcelain=v2', '--branch', '-z', '--untracked-files=all')
    head, ref, пути_статуса = _разобрать_статус_v2(статус)
    if пути_статуса - set(цели):
        raise ValueError('Git status содержит путь вне разрешённого состава')
    return {
        'корень': str(корень), 'ref': ref, 'head': head,
        'индекс_sha256': _хэш(индекс), 'статус_sha256': _хэш(статус),
    }


def подготовить(корень: Path, путь_запроса: str, путь_разрешения: Path,
                профиль: dict | None = None) -> dict:
    корень = Path(корень).resolve()
    начало = time.perf_counter_ns() if профиль is not None else 0
    вход, путь_разрешения, байты_разрешения, цели, ожидаемые = _прочитать_разрешение(
        корень, путь_запроса, Path(путь_разрешения),
    )
    состояние = _снимок_git(корень, цели)
    if вход['ветка'] != состояние['ref'] or вход['исходный_коммит'] != состояние['head']:
        raise ValueError('Разрешение привязано к другому ref или HEAD')
    if профиль is not None:
        профиль['разрешение-и-снимок-git'] = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
    путь_запроса_файла = _путь_репозитория(корень, путь_запроса)
    запрос = путь_запроса_файла.read_bytes()
    после, рендер_состав = _сформировать_запрос(корень, путь_запроса, запрос, цели, ожидаемые)
    if профиль is not None:
        профиль['рендер-и-проверка-ссылок'] = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
    состояние_после = _снимок_git(корень, цели)
    if (состояние != состояние_после or путь_разрешения.read_bytes() != байты_разрешения
            or путь_запроса_файла.read_bytes() != запрос):
        raise ValueError('Git-снимок, разрешение или запрос изменились во время подготовки')
    if профиль is not None:
        профиль['повторная-сверка'] = time.perf_counter_ns() - начало
    return {
        'схема': 'fum.план-обновления-состава-карточки.1',
        'задача': вход['задача'], 'запрос': путь_запроса,
        'разрешение_sha256': _хэш(байты_разрешения),
        'разрешённые_цели': цели,
        'разрешённые_ожидаемые_цели': ожидаемые,
        'исполняемый_контур': _хэши_исполняемого_контура(),
        'состояние_git': состояние,
        **рендер_состав,
    }


def сохранить_план(путь: Path, план: dict, корень: Path) -> str:
    корень = Path(корень).resolve()
    путь = Path(путь)
    if (not путь.is_absolute() or путь != путь.resolve() or путь.is_relative_to(корень)
            or not путь.parent.is_dir() or os.path.lexists(путь)
            or any(предок.is_symlink() or os.path.lexists(предок / '.git') for предок in путь.parents)):
        raise ValueError('Предпросмотр сохраняется в свободный точный путь вне checkout')
    байты = _канонический_json(план)
    дескриптор = os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o400)
    with os.fdopen(дескриптор, 'wb') as файл:
        файл.write(байты)
        файл.flush()
        os.fsync(файл.fileno())
    if путь.read_bytes() != байты:
        raise ValueError('Предпросмотр не подтверждён повторным чтением')
    return _хэш(байты)


def _атомарно_заменить(путь: Path, прежние: bytes, новые: bytes):
    if путь.is_symlink() or not stat.S_ISREG(путь.lstat().st_mode) or путь.stat().st_nlink != 1:
        raise ValueError('Запрос должен быть обычным файлом без дополнительных жёстких ссылок')
    if путь.read_bytes() != прежние:
        raise ValueError('Запрос изменился перед атомарной заменой')
    режим = stat.S_IMODE(путь.stat().st_mode)
    дескриптор, имя = tempfile.mkstemp(prefix='.состав-', dir=путь.parent)
    временный = Path(имя)
    try:
        os.fchmod(дескриптор, режим)
        with os.fdopen(дескриптор, 'wb') as файл:
            файл.write(новые)
            файл.flush()
            os.fsync(файл.fileno())
        if временный.read_bytes() != новые:
            raise ValueError('Временный запрос не совпал с подготовленными байтами')
        if путь.read_bytes() != прежние:
            raise ValueError('Запрос изменился перед атомарной установкой')
        os.replace(временный, путь)
        каталог = os.open(путь.parent, os.O_RDONLY)
        try:
            os.fsync(каталог)
        finally:
            os.close(каталог)
        if путь.read_bytes() != новые:
            raise ValueError('Атомарно установленный запрос не совпал с предпросмотром')
    finally:
        if временный.exists():
            временный.unlink()


def применить(корень: Path, путь_запроса: str, путь_разрешения: Path,
              путь_плана: Path, ожидаемый_sha256: str) -> dict:
    корень = Path(корень).resolve()
    путь_плана, байты_плана = _обычный_внешний_вход(Path(путь_плана), корень)
    if type(ожидаемый_sha256) is not str or not ХЭШ.fullmatch(ожидаемый_sha256):
        raise ValueError('Нужен полный SHA256 одобренного предпросмотра')
    if _хэш(байты_плана) != ожидаемый_sha256:
        raise ValueError('SHA256 предпросмотра не совпадает с одобренным')
    план = json.loads(байты_плана, object_pairs_hook=_уникальные_поля)
    текущий = подготовить(корень, путь_запроса, Path(путь_разрешения))
    if _канонический_json(план) != _канонический_json(текущий):
        raise ValueError('Снимок, разрешение, шаблон или исходный запрос изменились после предпросмотра')
    если = _путь_репозитория(корень, путь_запроса)
    прежние = если.read_bytes()
    новые, сводка = _сформировать_запрос(
        корень, путь_запроса, прежние, текущий['цели'],
        текущий['разрешённые_ожидаемые_цели'],
    )
    if _хэш(новые) != текущий['запрос_sha256_после']:
        raise ValueError('Повторный рендер не совпал с одобренным SHA256 запроса')
    _, байты_разрешения_сейчас = _обычный_внешний_вход(Path(путь_разрешения), корень)
    if (_хэш(байты_разрешения_сейчас) != текущий['разрешение_sha256']
            or _снимок_git(корень, текущий['цели']) != текущий['состояние_git']
            or _хэши_исполняемого_контура() != текущий['исполняемый_контур']):
        raise ValueError('Разрешение, состояние Git или исполняемый контур изменились перед установкой')
    if новые != прежние:
        _атомарно_заменить(если, прежние, новые)
    if если.read_bytes() != новые:
        raise ValueError('Итоговые байты запроса отличаются от предпросмотра')
    начало, _, конец = _срез_состава(прежние)
    после_начало, _, после_конец = _срез_состава(если.read_bytes())
    if начало != после_начало or конец != после_конец:
        raise ValueError('Преобразование затронуло байты вне управляемого блока')
    return {'применено': новые != прежние, 'запрос_sha256': _хэш(новые), **сводка}


def main(argv=None) -> int:
    парсер = argparse.ArgumentParser(description='Предпросмотр и безопасное обновление блока «Повлиял на файлы».')
    подкоманды = парсер.add_subparsers(dest='действие', required=True)
    план = подкоманды.add_parser('план')
    применить_план = подкоманды.add_parser('применить')
    for подкоманда in (план, применить_план):
        подкоманда.add_argument('--корень-репозитория', required=True, type=Path)
        подкоманда.add_argument('--запрос', required=True)
        подкоманда.add_argument('--разрешение', required=True, type=Path)
    план.add_argument('--выход', required=True, type=Path)
    применить_план.add_argument('--план', required=True, type=Path)
    применить_план.add_argument('--sha256', required=True)
    args = парсер.parse_args(argv)
    корень = args.корень_репозитория.resolve()
    if args.действие == 'план':
        данные = подготовить(корень, args.запрос, args.разрешение)
        хэш_плана = сохранить_план(args.выход, данные, корень)
        print(json.dumps({'схема': 'fum.предпросмотр-состава-карточки.1',
                          'план_sha256': хэш_плана,
                          'ссылок': len(данные['цели']),
                          'изменить': данные['изменить'],
                          'новые_ссылки': данные['новые_ссылки'],
                          'удалённые_ссылки': данные['удалённые_ссылки']},
                         ensure_ascii=False, sort_keys=True))
    else:
        результат = применить(корень, args.запрос, args.разрешение, args.план, args.sha256)
        print(json.dumps({'схема': 'fum.обновление-состава-карточки.1', **результат},
                         ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (ValueError, OSError, subprocess.CalledProcessError, json.JSONDecodeError) as ошибка:
        print(f'Отказ: {ошибка}', file=sys.stderr)
        raise SystemExit(2)
