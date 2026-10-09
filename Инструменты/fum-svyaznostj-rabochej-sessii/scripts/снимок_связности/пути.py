"""Лексические пути; I/O выполняет только отдельный наблюдатель."""
from pathlib import PurePosixPath
from types import SimpleNamespace
from .модель import НеполныйСнимок


class Путь:
    def __init__(сам, значение, наблюдатель):
        сам.имя = PurePosixPath(str(значение))
        сам.наблюдатель = наблюдатель

    def __str__(сам): return str(сам.имя)
    def __fspath__(сам): return str(сам)
    def __hash__(сам): return hash(сам.имя)
    def __eq__(сам, другой): return isinstance(другой, Путь) and сам.имя == другой.имя
    def __lt__(сам, другой): return сам.имя < другой.имя
    def __truediv__(сам, другой): return Путь(сам.имя / str(другой), сам.наблюдатель)
    @property
    def name(сам): return сам.имя.name
    @property
    def suffix(сам): return сам.имя.suffix
    @property
    def parts(сам): return сам.имя.parts
    @property
    def parent(сам): return Путь(сам.имя.parent, сам.наблюдатель)
    def is_absolute(сам): return сам.имя.is_absolute()
    def as_posix(сам): return сам.имя.as_posix()
    def relative_to(сам, другой): return Путь(сам.имя.relative_to(str(другой)), сам.наблюдатель)
    def absolute(сам):
        if not сам.is_absolute(): raise НеполныйСнимок('относительный absolute вне закрытого корня')
        return сам
    def resolve(сам): return Путь(сам.наблюдатель('resolve', str(сам)), сам.наблюдатель)
    def exists(сам): return сам.наблюдатель('exists', str(сам))
    def is_symlink(сам): return сам.наблюдатель('is_symlink', str(сам))
    def is_dir(сам): return сам.наблюдатель('is_dir', str(сам))
    def stat(сам):
        вид = сам.наблюдатель('stat', str(сам))
        if вид is None: raise FileNotFoundError(str(сам))
        return SimpleNamespace(st_mode=вид, st_dev=0, st_ino=0, st_mtime_ns=0, st_ctime_ns=0)
    def iterdir(сам):
        дети = сам.наблюдатель('iterdir', str(сам))
        if дети is None: raise FileNotFoundError(str(сам))
        return iter(Путь(элемент, сам.наблюдатель) for элемент in дети)
    def read_text(сам, encoding):
        if encoding != 'utf-8': raise НеполныйСнимок('неизвестная кодировка')
        return сам.наблюдатель('read_bytes', str(сам)).decode('utf-8').replace('\r\n', '\n').replace('\r', '\n')


def повтор(наблюдения):
    словарь = {(элемент.операция, элемент.путь): элемент.значение for элемент in наблюдения}
    def прочитать(операция, путь):
        try: return словарь[операция, путь]
        except KeyError as ошибка: raise НеполныйСнимок(f'нет наблюдения {операция}: {путь}') from ошибка
    return прочитать
