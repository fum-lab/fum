"""Реальный CHILD10: внешний S передаётся в полную проверку свежести H/W.

Принятый K задаётся явно; два кандидатных модуля накладываются только на его
приватную копию. Ни checkout K, ни его нормативы и зависимости не изменяются.
"""
import argparse
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock


КОММИТ_K = 'b2ae5245fb6607f9ebff2c6f868edc8b92336cda'
ПРЕФИКС = 'Инструменты/fum-svyaznostj-rabochej-sessii/'
МОДУЛИ = [ПРЕФИКС + 'scripts/' + имя for имя in
    ('check-session-coherence.py', 'связность_независимого_журнала.py')]
ХЭШИ_K = ['128fd7a7a4b923c3a4e20c24e1e972554e78052716ff99ecf7057f792d848ac3',
    '6e9182dce250e9cb3314d56acb2e56522ab2afaf076b0bf24a4d08d8c9fc1935']


def хэш(байты):
    return hashlib.sha256(байты).hexdigest()


def гит(корень, *аргументы):
    return subprocess.check_output(['git', '--no-optional-locks', '-C', str(корень),
        *аргументы], stderr=subprocess.PIPE)


def инвентарь(корень):
    """Весь исполняемый контур и нормативы; прочие данные связывает Git-граница."""
    пути = []
    for имя in ('Инструменты', 'Правила/агентов', 'AGENTS.md', '.codex/config.toml'):
        путь = корень / имя
        пути.extend(путь.rglob('*') if путь.is_dir() else [путь])
    return {п.relative_to(корень).as_posix(): [п.stat().st_mode & 0o777, хэш(п.read_bytes())]
        for п in sorted(пути) if п.is_file()}


def граница_Git(корень):
    return {имя: хэш(гит(корень, *аргументы)) for имя, аргументы in {
        'HEAD': ('rev-parse', 'HEAD'),
        'дерево': ('rev-parse', 'HEAD^{tree}'),
        'статус': ('status', '--porcelain=v1', '--untracked-files=all'),
        'рабочий_diff': ('diff', '--no-ext-diff', '--binary', 'HEAD'),
        'индексный_diff': ('diff', '--no-ext-diff', '--binary', '--cached', 'HEAD'),
    }.items()}


def исходники_запуска():
    пути = [Path(__file__).resolve(), Path(__file__).resolve().with_name(
        'профиль_свежести_внешнего_состава_ребёнка.py')]
    return {п.name: хэш(п.read_bytes()) for п in пути}


@contextlib.contextmanager
def варианты(код_K, кандидат, *, сохранить=False):
    """Exact K из Git; кандидат отличается исключительно двумя модулями."""
    код_K = Path(код_K).resolve(); кандидат = Path(кандидат).resolve()
    if гит(код_K, 'rev-parse', 'HEAD').decode().strip() != КОММИТ_K:
        raise ValueError('не выбран exact K568')
    состояние = гит(код_K, 'status', '--porcelain=v1', '--untracked-files=all')
    исполнители = исходники_запуска()
    if состояние:
        raise ValueError('нужен чистый принятый K568')
    for имя, ожидаемый in zip(МОДУЛИ, ХЭШИ_K):
        сырые = гит(код_K, 'show', КОММИТ_K + ':' + имя)
        if хэш(сырые) != ожидаемый or (код_K / имя).read_bytes() != сырые:
            raise ValueError('изменён исходник принятого K568')
    размещение = (contextlib.nullcontext(tempfile.mkdtemp(prefix='fum-внешний-S-код-'))
        if сохранить else tempfile.TemporaryDirectory(prefix='fum-внешний-S-код-'))
    with размещение as временный:
        каталог = Path(временный).resolve()
        архив = каталог / 'K.tar'
        with архив.open('wb') as поток:
            subprocess.run(['git', '--no-optional-locks', '-C', str(код_K), 'archive',
                КОММИТ_K, 'Инструменты'], stdout=поток, check=True)
        основа = каталог / 'основа'
        subprocess.run(['git', '-c', 'core.hooksPath=' + os.devnull, 'clone',
            '--quiet', '--shared', '--no-checkout', str(код_K), str(основа)], check=True)
        subprocess.run(['git', '-C', str(основа), '-c', 'core.hooksPath=' + os.devnull,
            'checkout', '--quiet', '--detach', КОММИТ_K], check=True)
        исходные = инвентарь(основа)
        новый = каталог / 'кандидат'; shutil.copytree(основа, новый)
        for имя in МОДУЛИ:
            файл = кандидат / имя
            if файл.is_symlink() or not файл.is_file():
                raise ValueError('необычный кандидатный модуль')
            (новый / имя).write_bytes(файл.read_bytes())
        текущие = инвентарь(новый)
        Git_до = {'основа': граница_Git(основа), 'кандидат': граница_Git(новый)}
        изменённые = {п for п in исходные if исходные[п] != текущие[п]}
        if not изменённые <= set(МОДУЛИ):
            raise ValueError('overlay вышел за два исходника')
        try:
            yield {'основа': основа, 'кандидат': новый}, {
                'коммит_K': КОММИТ_K, 'архив_инструментов_K_sha256': хэш(архив.read_bytes()),
                'исполнители_sha256': исполнители,
                'границы_Git': Git_до,
                'полная_локальная_Git_история': True,
                'исходных_файлов': len(исходные), 'изменённые_пути': sorted(изменённые),
                'модули': {п: {'K': исходные[п][1], 'кандидат': хэш((новый / п).read_bytes())}
                    for п in МОДУЛИ}}
        finally:
            if исходники_запуска() != исполнители:
                raise ValueError('дрейф исполнителей тестов или профиля')
            if инвентарь(основа) != исходные or инвентарь(новый) != текущие:
                raise ValueError('изменён базовый или кандидатный исполняемый K')
            if граница_Git(основа) != Git_до['основа'] or граница_Git(новый) != Git_до['кандидат']:
                raise ValueError('изменены прочие данные или Git-состояние вариантов')
            if гит(код_K, 'rev-parse', 'HEAD').decode().strip() != КОММИТ_K or гит(
                    код_K, 'status', '--porcelain=v1', '--untracked-files=all') != состояние:
                raise ValueError('дрейф принятого K568')


def загрузить(корень):
    сценарии = корень / (ПРЕФИКС + 'scripts')
    sys.path[:0] = [str(корень / (ПРЕФИКС + 'tests')), str(сценарии)]
    import test_независимой_контрольной_точки as фикстура
    описание = importlib.util.spec_from_file_location('связность_внешнего_S',
        сценарии / 'check-session-coherence.py')
    проверка = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = проверка; описание.loader.exec_module(проверка)
    return фикстура, проверка


@contextlib.contextmanager
def стенд(фикстура, *, внешний=True, корневой=False):
    """Настоящие H/S/ACT, подготовка, fill и terminal запись без READY/commit."""
    ребёнок = (фикстура.РеальныйНезависимыйСоздатель() if корневой
        else фикстура.РеальныйНезависимыйРебёнок())
    ребёнок.setUp()
    try:
        р = ребёнок if корневой else ребёнок.р
        параметры = {'выбранный_состав': р.выбранный}
        if not корневой:
            параметры['доверенное_поручение'] = ребёнок.выбор
        р.м.подготовить(р.п, **параметры)
        # Только тестовый вход fill: полный список изменённых данных W.
        р.п['разрешённые_цели'].insert(0, р.ж.ПУТЬ_СОСТАВА)
        р.наполнить(json.loads(Path(р.п['подготовка']).read_bytes()))
        р.свежая_собственная_пара()
        р.ф.гит('add', '.')
        with contextlib.redirect_stdout(io.StringIO()):
            код = р.ф.отчёты.выполнить_запуск(р.ф.корень, р.ф.запрос,
                'Проверить открытые данные внешнего состава', 'фикстура',
                фикстура.база.ЗАПУСК, 15, [sys.executable, '-c',
                "from pathlib import Path; assert Path('данные.txt').read_text() == 'проверено\\n'"],
                класс_проверки='адресная', приёмочные_раунды=True)
            if код != 0:
                raise AssertionError('не прошла проверка данных фикстуры')
            р.ф.отчёты.выполнить_предпросмотр(р.ф.корень, р.ф.запрос)
        р.свежая_собственная_пара()
        if внешний:
            родитель = р.ф.гит('rev-parse', 'HEAD').strip()
            файл = р.ф.корень / р.ж.ПУТЬ_СОСТАВА
            прежние = файл.read_bytes()
            сырые = (json.dumps(json.loads(прежние), ensure_ascii=False,
                sort_keys=True, indent=2) + '\n').encode()
            if сырые == прежние:
                raise AssertionError('не различаются raw байты S')
            файл.write_bytes(сырые)
            # Сохраняется только S: уже открытая пара не попадает в H/S.
            р.ф.гит('reset', '-q', родитель)
            р.ф.гит('add', '--', р.ж.ПУТЬ_СОСТАВА)
            р.ф.гит('commit', '-qm', 'Открытая фикстура отдельного raw состава S')
            поставка = р.ф.гит('rev-parse', 'HEAD').strip()
            р.ф.гит('update-ref', 'HEAD', родитель, поставка)
            р.ф.гит('read-tree', родитель)
            р.выбранный = {'коммит': поставка, 'путь': р.ж.ПУТЬ_СОСТАВА,
                'sha256': хэш(сырые)}
            р.п['контракт_журнала']['состав'] = р.выбранный
            if гит(р.ф.корень, 'show', 'HEAD:' + р.ж.ПУТЬ_СОСТАВА) == сырые:
                raise AssertionError('HEAD ошибочно содержит внешний raw S')
            if гит(р.ф.корень, 'show', поставка + ':' + р.ж.ПУТЬ_СОСТАВА) != сырые:
                raise AssertionError('внешний Git источник не совпал с raw S')
        # Preview должен соответствовать окончательному отпечатку этой фикстуры.
        with contextlib.redirect_stdout(io.StringIO()):
            р.ф.отчёты.выполнить_предпросмотр(р.ф.корень, р.ф.запрос)
        р.свежая_собственная_пара()
        писатель = фикстура.база.ЗАДАЧА if корневой else ребёнок.исполнитель
        yield р, писатель
    finally:
        ребёнок.doCleanups()


def аргументы(р, писатель, *, селектор=None):
    контракт = р.ф.каталог / 'контракт-checker.json'
    выбор = р.ф.каталог / 'выбор-checker.json'
    контракт.write_text(json.dumps(р.п['контракт_журнала'], ensure_ascii=False))
    выбор.write_text(json.dumps(р.выбранный if селектор is None else селектор, ensure_ascii=False))
    return ['--repo-root', str(р.ф.корень), '--request', р.п['запрос'],
        '--codex-thread-id', р.п['задача'], '--commit-message-file', р.п['сообщение'],
        '--контрольная-точка', '--контракт-независимого-журнала', str(контракт),
        '--выбранный-состав', str(выбор), '--писатель', писатель]


def вызвать(код, р, писатель, *, селектор=None, без_выбора=False):
    параметры = аргументы(р, писатель, селектор=селектор)
    if без_выбора:
        номер = параметры.index('--выбранный-состав'); del параметры[номер:номер + 2]
    начало = time.monotonic_ns()
    процесс = subprocess.run([sys.executable, '-I', '-S', '-B',
        str(код / МОДУЛИ[0]), *параметры], capture_output=True,
        env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'}, timeout=60)
    return {'код': процесс.returncode, 'наносекунды': time.monotonic_ns() - начало,
        'stdout': процесс.stdout.decode(), 'stderr': процесс.stderr.decode()}


def вызвать_в_процессе(р, писатель):
    вывод = io.StringIO(); ошибки = io.StringIO()
    with mock.patch.object(sys, 'argv', ['check-session-coherence.py',
            *аргументы(р, писатель)]), contextlib.redirect_stdout(вывод), \
            contextlib.redirect_stderr(ошибки):
        код = ПРОВЕРКА.main()
    return код, вывод.getvalue(), ошибки.getvalue()


class ВнешнийСоставРебёнка(unittest.TestCase):
    def test_внешний_raw_S_проходит_настоящий_дочерний_CLI(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            до = ФИКСТУРА.снимок(р.ф.корень)
            результат = вызвать(КОД, р, писатель)
            сам.assertEqual(0, результат['код'], результат['stderr'])
            сам.assertEqual(до, ФИКСТУРА.снимок(р.ф.корень))

    def test_неверный_rawSHA_отвергается_настоящим_CLI(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            р.п['контракт_журнала']['состав'] = {**р.выбранный, 'sha256': '0' * 64}
            результат = вызвать(КОД, р, писатель, селектор=р.п['контракт_журнала']['состав'])
            сам.assertEqual(1, результат['код'])
            сам.assertIn('Git-источник', результат['stderr'])

    def test_неверный_OID_отвергается_настоящим_CLI(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            выбор = {**р.выбранный, 'коммит': р.ф.гит('rev-parse', 'HEAD').strip()}
            р.п['контракт_журнала']['состав'] = выбор
            результат = вызвать(КОД, р, писатель, селектор=выбор)
            сам.assertEqual(1, результат['код'])
            сам.assertIn('Git-источник', результат['stderr'])

    def test_отсутствие_внешнего_выбора_не_принимает_live_S(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            результат = вызвать(КОД, р, писатель, без_выбора=True)
            сам.assertEqual(2, результат['код'])
            сам.assertIn('два независимо переданных файла', результат['stderr'])
            сам.assertTrue(ФИКСТУРА.связность.проверить_свежесть(
                р.ф.корень, {р.ф.запрос, р.ф.запрос.with_name('отчёт.md')}))

    def test_прежний_дочерний_выбор_из_HEAD_проходит(сам):
        with стенд(ФИКСТУРА, внешний=False) as (р, писатель):
            результат = вызвать(КОД, р, писатель)
            сам.assertEqual(0, результат['код'], результат['stderr'])

    def test_дрейф_S_после_первого_контракта_отвергается(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            настоящий = ФИКСТУРА.связность.проверить_контракт
            число = 0
            def с_дрейфом(*аргументы, **поля):
                nonlocal число
                результат = настоящий(*аргументы, **поля); число += 1
                if число == 1:
                    файл = р.ф.корень / р.ж.ПУТЬ_СОСТАВА
                    файл.write_bytes(файл.read_bytes() + b'\n')
                return результат
            with mock.patch.object(ФИКСТУРА.связность, 'проверить_контракт', с_дрейфом):
                код, _, ошибки = вызвать_в_процессе(р, писатель)
            сам.assertEqual(1, код); сам.assertIn('состав отличается', ошибки)
            сам.assertEqual(1, число)

    def test_дрейф_S_после_свежести_виден_повторному_контракту(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            настоящая = ФИКСТУРА.связность.проверить_свежесть
            def с_дрейфом(*аргументы, **поля):
                результат = настоящая(*аргументы, **поля)
                сам.assertEqual([], результат)
                файл = р.ф.корень / р.ж.ПУТЬ_СОСТАВА
                файл.write_bytes(файл.read_bytes() + b'\n')
                return результат
            with mock.patch.object(ФИКСТУРА.связность, 'проверить_свежесть', с_дрейфом):
                код, _, ошибки = вызвать_в_процессе(р, писатель)
            сам.assertEqual(1, код); сам.assertIn('живой состав отличается', ошибки)

    def test_чужая_свежая_разметка_W_вне_пары_не_скрывается(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            файл = р.ф.корень / 'посторонний.md'
            файл.write_text('# Посторонняя разметка\n')
            р.свежесть.process_markdown_file(файл, р.ф.корень, set(),
                '2026-09-16 14:00:00 MSK', False, False)
            результат = вызвать(КОД, р, писатель)
            сам.assertEqual(1, результат['код'])
            сам.assertIn('постороннее изменение Markdown вне адресной области: посторонний.md',
                результат['stderr'])

    def test_удалённая_принятая_разметка_W_отвергается(сам):
        with стенд(ФИКСТУРА) as (р, писатель):
            (р.ф.корень / 'Глоссарий/память-FUM.md').unlink()
            результат = вызвать(КОД, р, писатель)
            сам.assertEqual(1, результат['код'])
            сам.assertIn('отсутствует принятый Markdown W: Глоссарий/память-FUM.md',
                результат['stderr'])


def сохранить_JSON(путь, данные):
    """Новый приватный файл; прежний исход не перезаписывается."""
    флаги = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
    with os.fdopen(os.open(путь, флаги, 0o600), 'wb') as поток:
        поток.write((json.dumps(данные, ensure_ascii=False, sort_keys=True,
            indent=2) + '\n').encode())
        поток.flush(); os.fsync(поток.fileno())


def наблюдать(команда, каталог, манифест):
    """Один worker без kill timeout; каналы и стенд удерживаются до его выхода."""
    каталог = каталог.resolve()
    if any((п / '.git').exists() for п in (каталог, *каталог.parents)):
        raise ValueError('каналы наблюдения должны оставаться вне Git')
    каталог.mkdir(mode=0o700)
    сохранить_JSON(каталог / 'намерение.json', {**манифест, 'argv': команда,
        'мягкие_пороги_секунды': [300, 900], 'принудительный_timeout': None,
        'стенд_сохраняется': True})
    флаги = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
    with os.fdopen(os.open(каталог / 'stdout.bin', флаги, 0o600), 'wb') as вывод, \
            os.fdopen(os.open(каталог / 'stderr.bin', флаги, 0o600), 'wb') as ошибки:
        начало = time.monotonic_ns()
        процесс = subprocess.Popen(команда, stdin=subprocess.DEVNULL,
            stdout=вывод, stderr=ошибки, start_new_session=True)
        пороги = [300, 900]
        сбой = None
        def состояние():
            with (каталог / 'stderr.bin').open('rb') as поток:
                поток.seek(max(0, os.fstat(поток.fileno()).st_size - 16384))
                строки = поток.read().decode(errors='replace').splitlines()
            методы = [с for с in строки if с.startswith('test_') and ' ... ' in с]
            return {'pid': процесс.pid, 'код': процесс.poll(),
                'истекло_секунд': (time.monotonic_ns() - начало) / 1e9,
                'последний_метод': методы[-1] if методы else None,
                'хвост_stderr': строки[-5:]}
        try:
            try:
                группа = os.getpgid(процесс.pid)
            except ProcessLookupError:
                группа = None
            сохранить_JSON(каталог / 'начало.json', {'pid': процесс.pid,
                'pgid_наблюдение': группа, 'контроллер_pid': os.getpid(),
                'начало_monotonic_ns': начало, 'argv': команда})
            while процесс.poll() is None:
                текущие = состояние()
                if пороги and текущие['истекло_секунд'] >= пороги[0]:
                    порог = пороги.pop(0)
                    os.fsync(вывод.fileno()); os.fsync(ошибки.fileno())
                    событие = {**текущие, 'порог_превышен': порог,
                        'worker_удерживается': True, 'сигналы_не_посылались': True}
                    сохранить_JSON(каталог / f'порог-{порог}.json', событие)
                    print(json.dumps(событие, ensure_ascii=False), flush=True)
                time.sleep(0.2)
        except BaseException as ошибка:
            сбой = repr(ошибка)
        finally:
            # Даже ошибка наблюдения не разрешает выйти из контекста живого worker.
            while True:
                try:
                    процесс.wait()
                    break
                except KeyboardInterrupt as ошибка:
                    сбой = сбой or repr(ошибка)
        try:
            os.fsync(вывод.fileno()); os.fsync(ошибки.fileno())
        except OSError as ошибка:
            сбой = сбой or repr(ошибка)
        итог = {**состояние(), 'пороги_превышены': [п for п in (300, 900) if п not in пороги],
            'ошибка_наблюдения': сбой, 'сигналы_не_посылались': True,
            'все_потомки_остановлены': None, 'исход_только_worker': True}
    каналы = {}
    for имя in ('stdout', 'stderr'):
        путь = каталог / (имя + '.bin'); сумма = hashlib.sha256()
        снимок = каталог / (имя + '-снимок.bin')
        with путь.open('rb') as поток, os.fdopen(os.open(снимок, флаги, 0o600), 'wb') as копия:
            размер = os.fstat(поток.fileno()).st_size
            остаток = размер
            while остаток:
                блок = поток.read(min(1024 * 1024, остаток))
                if not блок:
                    raise ValueError('канал усечён при сохранении префикса')
                копия.write(блок); сумма.update(блок); остаток -= len(блок)
            копия.flush(); os.fsync(копия.fileno())
        каналы[имя] = {'путь': str(путь), 'снимок': str(снимок), 'байт': размер,
            'sha256': сумма.hexdigest(), 'размер_после_снимка': путь.stat().st_size,
            'полнота': 'сохранённый префикс после выхода worker; прочие writers не установлены'}
    итог = {**манифест, **итог, 'каналы': каналы, 'argv': команда}
    сохранить_JSON(каталог / 'исход.json', итог)
    print(json.dumps({'код': итог['код'], 'истекло_секунд': итог['истекло_секунд'],
        'последний_метод': итог['последний_метод'], 'каналы': каналы},
        ensure_ascii=False), flush=True)
    return итог


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--код-K', type=Path)
    разбор.add_argument('--кандидат', type=Path)
    разбор.add_argument('--вариант', choices=('основа', 'кандидат'), default='кандидат')
    разбор.add_argument('--процесс', type=Path)
    разбор.add_argument('--тест')
    разбор.add_argument('--исходные-регрессии', action='store_true')
    разбор.add_argument('--выход', type=Path)
    разбор.add_argument('--наблюдение', type=Path,
        help='новый приватный каталог каналов; мягкие пороги 300/900 с, без kill')
    параметры = разбор.parse_args()
    if параметры.наблюдение and (not параметры.исходные_регрессии or параметры.тест
            or параметры.вариант != 'кандидат' or параметры.процесс):
        разбор.error('наблюдение предназначено только для полного кандидатного набора 139')
    if параметры.процесс:
        global КОД, ФИКСТУРА, ПРОВЕРКА
        КОД = параметры.процесс.resolve(); ФИКСТУРА, ПРОВЕРКА = загрузить(КОД)
        набор = (unittest.defaultTestLoader.loadTestsFromName(параметры.тест,
            sys.modules[__name__]) if параметры.тест else
            unittest.defaultTestLoader.loadTestsFromTestCase(ВнешнийСоставРебёнка))
        if параметры.исходные_регрессии:
            for имя in ('test_независимой_контрольной_точки',
                    'test_передачи_выбранного_состава', 'test_исторических_режимов_разметки',
                    'test_check_session_coherence'):
                набор.addTests(unittest.defaultTestLoader.loadTestsFromName(имя))
            print(f'Число выбранных тестов: {набор.countTestCases()}', flush=True)
        return 0 if unittest.TextTestRunner(verbosity=2).run(набор).wasSuccessful() else 1
    if параметры.код_K is None or параметры.кандидат is None:
        разбор.error('нужны --код-K и --кандидат; принятый K выбирается явно')
    итог = None
    try:
        return выполнить(параметры)
    except BaseException as ошибка:
        if параметры.наблюдение and параметры.наблюдение.is_dir():
            сохранить_JSON(параметры.наблюдение / 'сбой-контроллера.json',
                {'ошибка': repr(ошибка), 'целостность_подтверждена': False})
        raise


def выполнить(параметры):
    with варианты(параметры.код_K, параметры.кандидат,
            сохранить=bool(параметры.наблюдение)) as (корни, манифест):
        команда = [sys.executable, '-I', '-S', '-B', '-u', str(Path(__file__).resolve()),
            '--процесс', str(корни[параметры.вариант])]
        if параметры.тест:
            команда += ['--тест', параметры.тест]
        if параметры.исходные_регрессии:
            команда += ['--исходные-регрессии']
        if параметры.наблюдение:
            итог = наблюдать(команда, параметры.наблюдение, {**манифест,
                'вариант': параметры.вариант, 'корни': {к: str(п) for к, п in корни.items()}})
        else:
            результат = subprocess.run(команда, capture_output=True, timeout=300)
            sys.stdout.buffer.write(результат.stdout); sys.stderr.buffer.write(результат.stderr)
            if параметры.выход:
                параметры.выход.write_text(json.dumps({**манифест,
                    'вариант': параметры.вариант, 'код': результат.returncode,
                    'stdout': результат.stdout.decode(), 'stderr': результат.stderr.decode()},
                    ensure_ascii=False, sort_keys=True, indent=2) + '\n')
            return результат.returncode
    # Сюда можно попасть только после terminal worker и сверок finally в варианты().
    итог = {**итог, 'целостность_подтверждена': True,
        'код_контроллера': итог['код'] if итог['ошибка_наблюдения'] is None else 1}
    сохранить_JSON(параметры.наблюдение / 'контроллер-завершён.json', итог)
    if параметры.выход:
        сохранить_JSON(параметры.выход, итог)
    return итог['код_контроллера']


if __name__ == '__main__':
    raise SystemExit(главная())
