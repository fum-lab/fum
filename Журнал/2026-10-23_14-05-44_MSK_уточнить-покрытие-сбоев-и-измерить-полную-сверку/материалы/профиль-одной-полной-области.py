"""Один наблюдаемый проход области. Не допуск коммита и не оценка асимптотики."""
import argparse
from contextlib import ExitStack
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import time
from unittest.mock import patch

sys.dont_write_bytecode = True


def хэш(сырые):
    return hashlib.sha256(сырые).hexdigest()


def проверить_выход(корень, выход):
    if (not выход.is_absolute() or выход.parent != выход.parent.resolve()
            or выход.is_relative_to(корень) or os.path.lexists(выход)
            or stat.S_IMODE(выход.parent.stat().st_mode) != 0o700):
        raise ValueError('выход должен быть новым файлом приватного каталога вне W')


def проверить_окружение(окружение):
    разрешённые = {'GIT_PAGER', 'GIT_OPTIONAL_LOCKS', 'GIT_NO_REPLACE_OBJECTS'}
    if set(имя for имя in окружение if имя.startswith('GIT_')) - разрешённые:
        raise ValueError('неизвестная настройка Git')
    for имя, значение in [('GIT_OPTIONAL_LOCKS', '0'), ('GIT_NO_REPLACE_OBJECTS', '1')]:
        if имя in окружение and окружение[имя] != значение:
            raise ValueError('настройка Git не сохраняет чтение')


def сверить_трассу(трасса, *, успех):
    if (трасса['схема'] != 'fum.наблюдение-полного-доказательства.1'
            or трасса['полон'] is not True or трасса['ошибки_наблюдения']):
        raise ValueError('неполная диагностика')
    события = трасса['события']
    if трасса['событий'] != len(события) or len(события) != 2 * трасса['рамок']:
        raise ValueError('непарная трасса')
    стек = []; начала = {}; концы = {}; роли = set()
    ожидаемые = {'Git', 'разбор Git-дерева', 'построение принятого индекса', 'полная область'}
    for порядок, событие in enumerate(события, 1):
        рамка = событие['рамка']; роль = событие['роль']
        if событие['порядок'] != порядок or роль not in ожидаемые:
            raise ValueError('неизвестная роль либо порядок')
        if событие['событие'] == 'начало':
            if рамка in начала or событие['родитель'] != (стек[-1] if стек else None):
                raise ValueError('неверный родитель')
            начала[рамка] = событие; стек.append(рамка); роли.add(роль)
        elif событие['событие'] == 'конец':
            if not стек or стек.pop() != рамка or рамка in концы:
                raise ValueError('нарушена вложенность')
            начало = начала[рамка]
            if (начало['роль'] != роль or начало['родитель'] != событие['родитель']
                    or начало['монотонные_нс'] > событие['монотонные_нс']):
                raise ValueError('границы рамки различаются')
            концы[рамка] = событие
        else:
            raise ValueError('неизвестное событие')
    полные = [р for р, с in начала.items() if с['роль'] == 'полная область']
    if стек or len(полные) != 1 or начала[полные[0]]['родитель'] is not None:
        raise ValueError('нет единственного полного вызова')
    if успех and (роли != ожидаемые or концы[полные[0]]['исход'] != 'успех'):
        raise ValueError('нет успешного охвата четырёх точек')


def пины_зависимостей(корень):
    # Тело из принятого tests/профиль_границы_фасада.py:39, без импорта фикстур.
    результат = {}
    for модуль in list(sys.modules.values()):
        имя = getattr(модуль, '__file__', None)
        if not isinstance(имя, str):
            continue
        файл = Path(имя)
        if not файл.is_relative_to(корень / 'Инструменты'):
            continue
        if файл.resolve() != файл or not файл.is_file():
            raise ValueError('нефизическая зависимость профиля')
        до = файл.stat(); сырые = файл.read_bytes(); после = файл.stat()
        def метка(с):
            return [с.st_dev, с.st_ino, с.st_mode, с.st_uid, с.st_nlink,
                с.st_size, с.st_mtime_ns, с.st_ctime_ns]
        if not stat.S_ISREG(до.st_mode) or метка(до) != метка(после):
            raise ValueError('зависимость изменилась при чтении')
        результат[файл.relative_to(корень).as_posix()] = {
            'sha256': hashlib.sha256(сырые).hexdigest(), 'идентичность': метка(до)}
    return результат


def главная():
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--корень', type=Path, required=True)
    разбор.add_argument('--вход', type=Path, required=True)
    разбор.add_argument('--выход', type=Path, required=True)
    аргументы = разбор.parse_args()
    корень, вход, выход = аргументы.корень, аргументы.вход, аргументы.выход
    assert корень == корень.resolve() and вход == вход.resolve()
    проверить_выход(корень, выход)
    проверить_окружение(os.environ)
    def гит(*аргументы):
        return subprocess.check_output(['git', '--no-replace-objects',
            '--no-optional-locks', '-C', str(корень), *аргументы])
    сырые = вход.read_bytes(); данные = json.loads(сырые)
    assert set(данные) == {'схема', 'HEAD', 'параметры', 'выбор'}
    assert данные['схема'] == 'fum.вход-компонентного-профиля-области.1'
    assert гит('rev-parse', 'HEAD').decode().strip() == данные['HEAD']
    параметры = данные['параметры']
    assert параметры['корень'] == str(корень)
    assert параметры['исходный_коммит'] == данные['HEAD']
    assert параметры['контракт_журнала']['состав'] == данные['выбор']
    assert параметры['схема'] == 'fum.создание-коммита.9'
    def снимок():
        имена = set()
        for команда in [('diff', '--name-only', '-z'),
                ('diff', '--cached', '--name-only', '-z'),
                ('ls-files', '--others', '--exclude-standard', '-z')]:
            имена.update(filter(None, гит(*команда).decode().split('\0')))
        assert имена <= set(параметры['разрешённые_цели'])
        индекс = Path(гит('rev-parse', '--path-format=absolute', '--git-path', 'index').decode().strip())
        файлы = {}
        for имя in sorted(имена):
            файл = корень / имя
            if not os.path.lexists(файл):
                файлы[имя] = None
            else:
                сведения = файл.lstat()
                assert stat.S_ISREG(сведения.st_mode)
                файлы[имя] = {'sha256': хэш(файл.read_bytes()),
                    'режим': stat.S_IMODE(сведения.st_mode)}
        return {'статус_sha256': хэш(гит('status', '--porcelain=v1', '-z')),
            'индекс_sha256': хэш(индекс.read_bytes()), 'файлы': файлы,
            'HEAD': гит('rev-parse', 'HEAD').decode().strip(),
            'ref': гит('symbolic-ref', 'HEAD').decode().strip()}
    до = снимок()
    sys.path.insert(0, str(корень/'Инструменты/fum-svyaznostj-rabochej-sessii/scripts'))
    sys.path.insert(0, str(корень/'Инструменты/fum-proyektnyiye-fajlyi/scripts'))
    import связность_независимого_журнала as область
    import project_files  # Точный ленивый импорт проверяемого контура закрепляется до окна.
    assert Path(project_files.__file__) == корень/'Инструменты/fum-proyektnyiye-fajlyi/scripts/project_files.py'
    from наблюдение_полного_доказательства import Наблюдение
    журнал = область.журнал(); наблюдение = Наблюдение()
    def данные_гита(аргументы, поля, результат):
        return {'аргументы': list(аргументы[1:]), 'байты': len(результат), 'sha256': хэш(результат)}
    def данные_разбора(аргументы, поля, результат):
        return {'входные_байты': len(аргументы[0]), 'вход_sha256': хэш(аргументы[0]),
            'записей': len(результат)}
    def данные_индекса(аргументы, поля, результат):
        return {'тип_результата': type(результат).__name__}
    точки = [(журнал, '_гит', 'Git', данные_гита),
        (журнал, '_разобрать_дерево_коммита', 'разбор Git-дерева', данные_разбора),
        (журнал, 'построить_принятый_индекс', 'построение принятого индекса', данные_индекса),
        (область, 'проверить_область_записей', 'полная область', None)]
    исходные = {(id(м), имя): getattr(м, имя) for м, имя, _, _ in точки}
    код_до = пины_зависимостей(корень)
    ошибка = None; исходное_исключение = None; начало = time.monotonic_ns()
    try:
        with ExitStack() as стек:
            for модуль, имя, роль, сведения in точки:
                стек.enter_context(patch.object(модуль, имя,
                    наблюдение.обернуть(роль, исходные[(id(модуль), имя)], сведения)))
            область.проверить_область_записей(параметры, выбранный_состав=данные['выбор'])
    except BaseException as исключение:
        ошибка = {'тип': type(исключение).__name__, 'текст': str(исключение)}
        исходное_исключение = (исключение, исключение.__traceback__)
    длительность = time.monotonic_ns() - начало
    try:
        после = снимок(); код_после = пины_зависимостей(корень)
        assert до == после and код_до == код_после and вход.read_bytes() == сырые
        assert all(getattr(м, имя) is исходные[(id(м), имя)] for м, имя, _, _ in точки)
        трасса = наблюдение.срез(); сверить_трассу(трасса, успех=ошибка is None)
        доказательство = {'схема': 'fum.профиль-одной-полной-области.1',
            'HEAD': данные['HEAD'], 'вход_sha256': хэш(сырые),
            'профилировщик_sha256': хэш(Path(__file__).read_bytes()),
            'параметры': параметры, 'выбор': данные['выбор'],
            'снимок_до': до, 'снимок_после': после, 'код': код_до,
            'монотонные_нс': длительность, 'ошибка': ошибка, 'наблюдение': трасса,
            'граница': 'Один компонентный проход, не полный Maker/READY/Create. '
                'Не доказательство асимптотики или ускорения. Вложенные интервалы не складываются. '
                'Диагностический SHA добавляет затраты. Четыре точки, логические байты, не физический I/O. '
                'Закреплены загруженные исходники, не все ресурсы и не равенство code objects.'}
        запись = (json.dumps(доказательство, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()
        with os.fdopen(os.open(выход, os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW, 0o400), 'wb') as поток:
            поток.write(запись); поток.flush(); os.fsync(поток.fileno())
    except BaseException:
        if исходное_исключение is not None:
            raise исходное_исключение[0].with_traceback(исходное_исключение[1])
        raise
    if исходное_исключение is not None:
        raise исходное_исключение[0].with_traceback(исходное_исключение[1])
    print(json.dumps({'секунды': длительность/1e9, 'рамок': трасса['рамок'],
        'без_записей_W': True}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
