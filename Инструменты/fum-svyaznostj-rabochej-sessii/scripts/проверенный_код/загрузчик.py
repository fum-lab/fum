"""Загрузка удержанного пакета с точным восстановлением sys.modules."""
import importlib
import importlib.util
import builtins
import sys
import threading
from types import SimpleNamespace

# Один процесс и один сеанс: исключаем гонку глобальных sys.modules/meta_path.
_замок = sys.__dict__.setdefault("_замок_проверенного_кода", threading.Lock())


class _Загрузчик:
    def __init__(сам, сеанс, имя):
        сам.сеанс, сам.имя = сеанс, имя

    def создать_модуль(сам, спецификация):
        return None

    def исполнить_модуль(сам, модуль):
        if not сам.сеанс.активен:
            raise ValueError("сеанс закрыт")
        сам.сеанс.модули[сам.имя] = модуль
        среда = vars(builtins).copy()
        среда["__import__"] = сам.сеанс.импорт
        модуль.__dict__["__builtins__"] = среда
        try:
            exec(сам.сеанс.коды[сам.имя], модуль.__dict__)
        except BaseException:
            сам.сеанс.модули.pop(сам.имя, None)
            raise

    def интерфейс(сам):
        # Точные ключи принадлежат протоколу Python importlib, callbacks — FUM.
        return SimpleNamespace(**{"create_module": сам.создать_модуль,
            "exec_module": сам.исполнить_модуль})


class Исполнение:
    def __init__(сам, снимок):
        сам.снимок = снимок
        сам.активен = False
        сам.коды = снимок.скомпилировать()
        сам.модули = {}

    def принадлежит(сам, имя):
        return имя == сам.снимок.пространство or имя.startswith(сам.снимок.пространство + ".")

    def сверить_кэш(сам):
        if not сам.активен:
            raise ValueError("импорт требует активный сеанс")
        for имя, модуль in list(sys.modules.items()):
            if сам.принадлежит(имя):
                if имя not in сам.снимок.записи:
                    raise ModuleNotFoundError("необъявленная запись кэша", name=имя)
                if сам.модули.get(имя) is not модуль or модуль is None:
                    raise ValueError("чужой объект в кэше собственного пространства")
                родитель, _, потомок = имя.rpartition(".")
                пакет = сам.модули.get(родитель)
                if пакет is not None and hasattr(пакет, потомок) and getattr(пакет, потомок) is not модуль:
                    raise ValueError("чужой объект в атрибуте объявленного модуля")

    def импорт(сам, имя, глобальные=None, локальные=None, список=(), уровень=0):
        # Охраняется только import исполняемых модулей, не весь Python-процесс.
        сам.сверить_кэш()
        результат = builtins.__import__(имя, глобальные, локальные, список, уровень)
        сам.сверить_кэш()
        return результат

    def __enter__(сам):
        if сам.активен or not _замок.acquire(blocking=False):
            raise ValueError("перекрывающиеся сеансы запрещены")
        try:
            # Доверенные объекты принадлежат только текущему входу.
            сам.модули.clear()
            # Все прежние scoped записи, включая неизвестные модули и None.
            сам.прежние = {к: в for к, в in sys.modules.items() if сам.принадлежит(к)}
            сам.поиск = tuple(sys.meta_path)
            for имя in сам.прежние:
                del sys.modules[имя]
            sys.meta_path.insert(0, SimpleNamespace(**{"find_spec": сам.спецификация}))
            сам.активен = True
            return сам
        except BaseException:
            for имя in list(sys.modules):
                if сам.принадлежит(имя):
                    del sys.modules[имя]
            sys.modules.update(сам.прежние)
            sys.meta_path[:] = сам.поиск
            _замок.release()
            raise

    def __exit__(сам, вид, ошибка, трасса):
        try:
            for имя in list(sys.modules):
                if сам.принадлежит(имя):
                    del sys.modules[имя]
            sys.modules.update(сам.прежние)
            sys.meta_path[:] = сам.поиск
            сам.активен = False
        finally:
            _замок.release()
        return False

    def спецификация(сам, имя, путь=None, цель=None):
        if not сам.принадлежит(имя):
            return None
        if not сам.активен or имя not in сам.снимок.записи:
            raise ModuleNotFoundError("модуль не объявлен в удержанном Q", name=имя)
        путь, пакет = сам.снимок.записи[имя]
        return importlib.util.spec_from_loader(имя, _Загрузчик(сам, имя).интерфейс(),
            origin=f"git:{сам.снимок.коммит}:{путь}", is_package=пакет)

    def загрузить(сам, имя):
        if not сам.активен or not сам.принадлежит(имя):
            raise ValueError("нужен активный сеанс собственного пространства")
        if имя not in сам.снимок.записи:
            raise ModuleNotFoundError("модуль не объявлен в удержанном Q", name=имя)
        сам.сверить_кэш()
        результат = importlib.import_module(имя)
        сам.сверить_кэш()
        return результат
