"""Свежие парные процессы с неизменяемыми A/B и настоящим validate_layout."""
from __future__ import annotations

import argparse
import cProfile
import hashlib
import importlib
import json
import os
from pathlib import Path
import platform
import pstats
import shutil
import stat
import statistics
import subprocess
import sys
import time
import traceback

ОСНОВА = 'edabf43260b47c0ec3b0c8d7726e0c6fa37722c6'
ЛЕКСЕР = 'Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py'
ЛИСТ = 'Инструменты/fum-struktura-papok-zaprosov/tests/test_request_folder_layout.py'
ЗАКРЕПЛЕНИЯ = {
    ЛЕКСЕР: '08e9e3eb2cc7876454f06425443db3c1cdac4a192408a6850a51097a8472b9bc',
    ЛИСТ: '9fdc76f6e71ea48b3a82343ddce9ba7310b32b5ccb2cdde8f299df76c74486fb',
    'Инструменты/fum-struktura-papok-zaprosov/scripts/расширение_шаблонов.py': '58b8315eaf1af7d0e99254b199320facf40855fcdb3709a6cffba131d49ccb0e',
    'Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py': 'caf78daee202eeb3a2eba81eb5ffbd2b3e60d64933312ec862a6884eef924b9d',
    'Инструменты/fum-proyektnyiye-fajlyi/scripts/project_files.py': 'a6957117a8fce12e4cd98444697ba539fb00d5096d56b9f218a2b207535bf761',
    'Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py': 'ee26082227da2d8a291f050d716cfe66622a71ff433f8727d9e06efa89b4cbec',
    'Инструменты/fum-struktura-papok-zaprosov/шаблоны/запрос.md.шаблон': 'f1cf28e4481bc64aab04aad646bbe5fea8e58f76c0e5967b9ac18856c60ecf97',
    'Инструменты/fum-struktura-papok-zaprosov/шаблоны/отчёт.md.шаблон': '6db76ec55037fdd40112dd97e32a42d882238c07738039adaf4ab2a0751bb359',
}
СЧЁТЧИКИ = ('_markdown_link_tokens', 'markdown_link_tokens', 'markdown_hidden_mask', 'reference_destination_on_line')


def байты(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False) + '\n').encode()


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def сохранить(путь, данные):
    путь.parent.mkdir(parents=True, exist_ok=True)
    with путь.open('xb') as файл:
        файл.write(данные)
    путь.chmod(0o600)


def среда():
    return {имя: значение for имя, значение in os.environ.items() if not имя.startswith('GIT_')}


def прочитать_репозиторий(корень, *аргументы):
    return subprocess.check_output(['git', '--no-optional-locks', *аргументы], cwd=корень, env=среда())


def снимок(корень, с_историей=False):
    файлы = {}
    for путь in sorted(корень.rglob('*')):
        имя = путь.relative_to(корень).as_posix()
        if '.git' in путь.relative_to(корень).parts:
            continue
        сведения = путь.lstat()
        if stat.S_ISLNK(сведения.st_mode):
            raise RuntimeError('символическая ссылка в корпусе или замороженной версии')
        файлы[имя] = [stat.S_IMODE(сведения.st_mode), хэш(путь.read_bytes()) if путь.is_file() else None]
    результат = {'файлы': файлы}
    if с_историей:
        результат['git'] = состояние_репозитория(корень)
    return результат


def состояние_репозитория(корень):
    каталог = Path(прочитать_репозиторий(корень, 'rev-parse', '--absolute-git-dir').decode().strip())
    return {
        'вершина_и_дерево': прочитать_репозиторий(корень, 'rev-parse', 'HEAD', 'HEAD^{tree}').decode().splitlines(),
        'индекс': прочитать_репозиторий(корень, 'ls-files', '--stage', '-z').hex(),
        'сырой_индекс': хэш((каталог / 'index').read_bytes()),
        'состояние': прочитать_репозиторий(корень, 'status', '--porcelain', '--untracked-files=all').hex(),
    }


def загрузить(корень):
    sys.path.insert(0, str((корень / ЛЕКСЕР).parent))
    модуль = importlib.import_module('request_folder_layout')
    if Path(модуль.__file__).resolve() != корень / ЛЕКСЕР:
        raise RuntimeError('импортировано другое тело layout')
    модуль._link_tools()
    importlib.import_module('расширение_шаблонов')
    проверить_импорты(корень)
    return модуль


def проверить_импорты(корень):
    имена = {Path(п).name for п in ЗАКРЕПЛЕНИЯ if п.endswith('.py') and п != ЛИСТ}
    for модуль in list(sys.modules.values()):
        имя_файла = getattr(модуль, '__file__', None)
        if имя_файла and Path(имя_файла).name in имена:
            путь = Path(имя_файла).resolve()
            if корень not in путь.parents:
                raise RuntimeError('helper импортирован вне выбранной версии')
            имя = путь.relative_to(корень).as_posix()
            if имя != ЛЕКСЕР and хэш(путь.read_bytes()) != ЗАКРЕПЛЕНИЯ[имя]:
                raise RuntimeError('изменились байты импортированного helper')


def измерить(вызов, диагностический, путь):
    профиль = cProfile.Profile() if диагностический else None
    ошибка_вызова = None
    if профиль:
        профиль.enable()
    начало = time.perf_counter_ns()
    try:
        значение = вызов()
    except BaseException as ошибка:
        ошибка_вызова = ошибка
    finally:
        длительность = time.perf_counter_ns() - начало
        if профиль:
            профиль.disable()
    исход = {'вид': 'результат', 'значение': значение} if ошибка_вызова is None else {
        'вид': 'ошибка', 'тип': type(ошибка_вызова).__name__, 'текст': str(ошибка_вызова),
    }
    счётчики = {}
    if профиль:
        профиль.dump_stats(str(путь))
        статистика = pstats.Stats(профиль)
        for имя in СЧЁТЧИКИ:
            счётчики[имя] = sum(значение[1] for ключ, значение in статистика.stats.items() if ключ[2] == имя)
    результат = {'нс': длительность, 'исход': исход, 'счётчики': счётчики}
    if исход['вид'] == 'ошибка':
        результат['трассировка'] = ''.join(traceback.format_exception(ошибка_вызова))
    return результат


def поля(значение):
    маска, токены = значение
    return {'маска': bytes(маска).hex(), 'токены': [
        [т.destination_start, т.destination_end, т.raw_destination, т.angle_destination, т.kind, т.line] for т in токены
    ]}


def образец(план, версия, режим, выход):
    корень = Path(план['версии'][версия]['корень'])
    корпус = Path(план['корпус'])
    if снимок(корень) != план['версии'][версия]['снимок'] or снимок(корпус, True) != план['снимок_корпуса'] or состояние_репозитория(Path(план['корень'])) != план['состояние_рабочего_репозитория']:
        raise RuntimeError('вход образца изменился')
    модуль = загрузить(корень)
    тексты = {имя: (корпус / путь).read_text() for имя, путь in план['прямые_входы'].items()}
    результаты = {'структура': измерить(lambda: модуль.validate_layout(корпус), режим == 'диагностический', выход.with_suffix('.validate.pstats'))}
    for имя, текст in тексты.items():
        # Сериализация полей и маски не входит в интервал предметного вызова.
        запись = измерить(lambda: модуль._markdown_link_tokens(текст), режим == 'диагностический', выход.with_suffix('.' + имя + '.pstats'))
        if запись['исход']['вид'] == 'результат':
            запись['исход']['значение'] = поля(запись['исход']['значение'])
        результаты[имя] = запись
    проверить_импорты(корень)
    if снимок(корень) != план['версии'][версия]['снимок'] or снимок(корпус, True) != план['снимок_корпуса'] or состояние_репозитория(Path(план['корень'])) != план['состояние_рабочего_репозитория']:
        raise RuntimeError('образец изменил исходники или корпус')
    сохранить(выход, байты({'версия': версия, 'режим': режим, 'питон': sys.version, 'результаты': результаты}))
    return 0 if all(з['исход']['вид'] == 'результат' for з in результаты.values()) else 1


def подготовить(параметры):
    корень = параметры.корень.resolve(strict=True)
    приватный = параметры.приватный.resolve(strict=True)
    if приватный == корень or корень in приватный.parents or any((предок / '.git').exists() for предок in (приватный, *приватный.parents)):
        raise RuntimeError('сырые профильные материалы должны находиться вне Git')
    if list(приватный.iterdir()):
        raise RuntimeError('приватный каталог должен быть новым и пустым')
    if stat.S_IMODE(приватный.stat().st_mode) != 0o700:
        raise RuntimeError('приватный каталог требует режима 0700')
    if параметры.кандидат.is_symlink() or not параметры.кандидат.is_file():
        raise RuntimeError('кандидат должен быть обычным файлом')
    кандидат = параметры.кандидат.read_bytes()
    if хэш(кандидат) != параметры.хэш_кандидата:
        raise RuntimeError('не совпал независимо выбранный SHA кандидата')
    if прочитать_репозиторий(корень, 'rev-parse', '--verify', ОСНОВА).decode().strip() != ОСНОВА:
        raise RuntimeError('не найдена точная основа')
    версии = {}
    for версия in ('A', 'B'):
        каталог = приватный / версия
        каталог.mkdir(mode=0o700)
        for имя, ожидаемый in ЗАКРЕПЛЕНИЯ.items():
            данные = прочитать_репозиторий(корень, 'show', ОСНОВА + ':' + имя)
            if хэш(данные) != ожидаемый:
                raise RuntimeError('не совпало закрепление ' + имя)
            if имя == ЛЕКСЕР and версия == 'B':
                данные = кандидат
            путь = каталог / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            сохранить(путь, данные)
            путь.chmod(0o400)
        версии[версия] = {'корень': str(каталог), 'хэш_лексера': хэш((каталог / ЛЕКСЕР).read_bytes()), 'снимок': снимок(каталог)}
    # Подготовка только закреплённой фикстурой A; workers имеют отдельные процессы.
    загрузить(приватный / 'A')
    sys.path.insert(0, str((приватный / 'A' / ЛИСТ).parent))
    фикстуры = importlib.import_module('test_request_folder_layout')
    переменные_репозитория = {и: з for и, з in os.environ.items() if и.startswith('GIT_')}
    for имя in переменные_репозитория:
        del os.environ[имя]
    фикстура = None
    try:
        фикстура = фикстуры.RepositoryFixture()
        фикстура.make_canonical_layout()
        ранний, поздний = фикстуры.EARLY, фикстуры.LATE
        фикстура.write(f'Журнал/{ранний}/запрос.md', фикстуры.request_document(ранний, previous=None, following=поздний, legacy=False))
        путь = фикстура.root / f'Журнал/{поздний}/запрос.md'
        путь.write_text(путь.read_text().replace(фикстуры.navigation(None, None), фикстуры.navigation(ранний, None)))
        фикстура.write('Журнал/README.md', f'# Журнал\n\n## Сессии\n\n- [Первый]({ранний}/запрос.md)\n- [Второй]({поздний}/отчёт.md)\n')
        фикстура.write('Документация/цель.md', '# Цель\n')
        входы = {
            'без_ссылок': ('Документация/без-ссылок.md', 'открытая строка без ссылок ' * 4000 + '\n'),
            'частые_ссылки': ('Документация/частые-ссылки.md', ('[x](цель.md) ![y](<цель.md> "t")\n[r]: <цель.md> "t"\n' * 1000)),
            'метки_с_кодом': ('Документация/метки-с-кодом.md', ('[a `x`](цель.md) [a [b](цель.md) `x`](цель.md)\n' * 1200)),
        }
        for путь, текст in входы.values():
            фикстура.write(путь, текст)
        фикстура.commit()
        корпус = приватный / 'корпус'
        shutil.copytree(фикстура.root, корпус)
    finally:
        if фикстура is not None:
            фикстура.close()
        os.environ.update(переменные_репозитория)
    процедура = приватный / 'процедура.py'
    сохранить(процедура, Path(__file__).read_bytes())
    процедура.chmod(0o400)
    план = {'версии': версии, 'корпус': str(корпус), 'снимок_корпуса': снимок(корпус, True),
            'прямые_входы': {имя: путь for имя, (путь, _текст) in входы.items()},
            'хэш_процедуры': хэш(процедура.read_bytes()), 'корень': str(корень),
            'состояние_рабочего_репозитория': состояние_репозитория(корень)}
    сохранить(приватный / 'план.json', байты(план))
    return план, процедура


def серия(план, процедура, приватный):
    образцы = []
    for режим in ('штатный', 'диагностический'):
        for номер, версия in enumerate('ABBA' * 3, 1):
            if хэш(процедура.read_bytes()) != план['хэш_процедуры'] or (приватный / 'план.json').read_bytes() != байты(план):
                raise RuntimeError('изменилась процедура или план')
            выход = приватный / f'{режим}-{номер}.json'
            команда = [sys.executable, '-I', '-B', str(процедура), 'образец', '--план', str(приватный / 'план.json'), '--версия', версия, '--режим', режим, '--выход', str(выход)]
            начало = time.perf_counter_ns()
            процесс = subprocess.run(команда, cwd=план['корпус'], env=среда(), capture_output=True)
            длительность = time.perf_counter_ns() - начало
            сохранить(выход.with_suffix('.stdout'), процесс.stdout)
            сохранить(выход.with_suffix('.stderr'), процесс.stderr)
            запись = {'порядок': номер, 'версия': версия, 'режим': режим, 'argv': команда, 'код': процесс.returncode,
                      'нс_процесса': длительность, 'SHA_stdout': хэш(процесс.stdout), 'SHA_stderr': хэш(процесс.stderr)}
            if выход.is_file():
                запись['образец'] = json.loads(выход.read_bytes())
            сохранить(выход.with_suffix('.процесс.json'), байты(запись))
            образцы.append(запись)
            if хэш(процедура.read_bytes()) != план['хэш_процедуры'] or (приватный / 'план.json').read_bytes() != байты(план):
                raise RuntimeError('образец изменил процедуру или план')
            if процесс.returncode != 0 or 'образец' not in запись:
                raise RuntimeError('образец отказал; сырые свидетельства сохранены: ' + str(номер))
    return образцы


def сводка(план, образцы):
    первые = образцы[0]['образец']['результаты']
    эталон = {имя: з['исход'] for имя, з in первые.items()}
    for запись in образцы:
        результаты = запись['образец']['результаты']
        if запись['образец']['питон'] != sys.version:
            raise RuntimeError('изменилась версия Python образца')
        if {имя: з['исход'] for имя, з in результаты.items()} != эталон:
            raise RuntimeError('не совпали полные исходы A/B')
    for версия, запись in план['версии'].items():
        if снимок(Path(запись['корень'])) != запись['снимок']:
            raise RuntimeError('изменилась замороженная версия ' + версия)
    if снимок(Path(план['корпус']), True) != план['снимок_корпуса'] or состояние_репозитория(Path(план['корень'])) != план['состояние_рабочего_репозитория']:
        raise RuntimeError('изменился корпус или рабочий Git')
    интервалы = {}
    for версия in ('A', 'B'):
        интервалы[версия] = {}
        for имя in эталон:
            времена = [з['образец']['результаты'][имя]['нс'] for з in образцы if з['версия'] == версия and з['режим'] == 'штатный']
            интервалы[версия][имя] = {'исходные_нс': времена, 'минимум_нс': min(времена), 'максимум_нс': max(времена), 'медиана_нс': statistics.median(времена)}
    диагностические = [{'порядок': з['порядок'], 'версия': з['версия'], 'времена_нс': {и: р['нс'] for и, р in з['образец']['результаты'].items()}, 'счётчики': {и: [{'функция': ф, 'вызовов': ч} for ф, ч in р['счётчики'].items()] for и, р in з['образец']['результаты'].items()}} for з in образцы if з['режим'] == 'диагностический']
    данные = план['снимок_корпуса']['файлы']
    ссылки = {имя: {вид: sum(т[4] == точный for т in з['значение']['токены']) for вид, точный in (('обычные', 'inline'), ('изображения', 'image'), ('определения', 'reference'))} for имя, з in эталон.items() if имя != 'структура'}
    корпус = Path(план['корпус'])
    return {
        'схема': 'fum.профиль-единого-разбора-ссылок.1',
        'среда': {'питон': sys.version, 'платформа': platform.platform(), 'таймер': 'perf_counter_ns', 'кэш_ОС_сбрасывался': False},
        'версии': [{'версия': в, 'основа': ОСНОВА if в == 'A' else None, 'хэш_лексера': з['хэш_лексера']} for в, з in план['версии'].items()],
        'процедура': {'путь': 'Инструменты/fum-struktura-papok-zaprosov/tests/профиль_единого_разбора_ссылок.py', 'хэш': план['хэш_процедуры']},
        'зависимости': {и: ш for и, ш in ЗАКРЕПЛЕНИЯ.items() if и != ЛЕКСЕР},
        'корпус': {'хэш_снимка': хэш(байты(план['снимок_корпуса'])), 'файлы': данные, 'число_файлов': sum(з[1] is not None for з in данные.values()), 'байтов': sum((корпус / п).stat().st_size for п, з in данные.items() if з[1] is not None), 'ссылок_в_прямых_входах': ссылки},
        'штатные_образцы': [{'версия': в, 'измерения': з} for в, з in интервалы.items()], 'диагностические_образцы': диагностические,
        'процессы': [{к: з[к] for к in ('порядок', 'версия', 'режим', 'код', 'нс_процесса')} | {'хэш_стандартного_вывода': з['SHA_stdout'], 'хэш_диагностического_вывода': з['SHA_stderr']} for з in образцы],
        'сверка': {'полные_исходы_равны': True, 'входы_и_история_неизменны': True, 'версии_питона_совпали': True, 'хэш_полных_исходов': хэш(байты(эталон)), 'результат_структуры': json.dumps(эталон['структура']['значение'], ensure_ascii=False, sort_keys=True)},
        'границы': ['3 блока ABBA на режим; 24 свежих процесса', 'Импорт, подготовка и контрольные снимки вне таймера; штатный Git validate_layout внутри', 'cProfile отдельно от штатных ns', 'Этот корпус и четыре вызова; весь фасад не измерен', 'B сверяется с Git blob после коммита'],
    }


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    команды = разбор.add_subparsers(dest='действие', required=True)
    запуск = команды.add_parser('серия')
    запуск.add_argument('--корень', type=Path, required=True)
    запуск.add_argument('--кандидат', type=Path, required=True)
    запуск.add_argument('--хэш-кандидата', required=True)
    запуск.add_argument('--приватный', type=Path, required=True)
    запуск.add_argument('--выход', type=Path, required=True)
    дочерний = команды.add_parser('образец')
    дочерний.add_argument('--план', type=Path, required=True)
    дочерний.add_argument('--версия', choices=('A', 'B'), required=True)
    дочерний.add_argument('--режим', choices=('штатный', 'диагностический'), required=True)
    дочерний.add_argument('--выход', type=Path, required=True)
    параметры = разбор.parse_args()
    if параметры.действие == 'образец':
        return образец(json.loads(параметры.план.read_bytes()), параметры.версия, параметры.режим, параметры.выход)
    план, процедура = подготовить(параметры)
    образцы = серия(план, процедура, параметры.приватный)
    результат = сводка(план, образцы)
    сохранить(параметры.выход, байты(результат))
    параметры.выход.chmod(0o644)
    print(json.dumps({'процессов': len(образцы), 'полные_исходы_равны': True}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(выполнить())
