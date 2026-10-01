"""Предметный read-only reader .7 в закрытой частной копии 17 исходников."""
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import selectors
import signal
import stat
import subprocess
import sys
import tempfile
import time

хэш_манифеста = "d2eb066ccc9faf612b1f4b754c73c662810c34b4f29af04b1019fc5ff8447fb4"
коммит_читателя = "e8112e88e0a574ade47ab560324af834dc6e2d00"
корень_зеркала = Path(__file__).absolute().parents[2] / "ПривязкаИсполнителя"
поля_входа = {"схема", "режим", "выбранное_поручение", "задача", "исполнитель", "корень", "ветка",
              "источник_модели", "исходный_коммит", "разрешённые_цели", "запрос", "история_модели"}
поля_выбора = {"координатор", "исполнитель", "коммит", "путь", "sha256"}
предел_обмена = 256 * 1024
тайм_аут = 20


def разобрать(байты):
    def пары(элементы):
        результат = {}
        for ключ, значение in элементы:
            if ключ in результат:
                raise ValueError("повторный ключ JSON")
            результат[ключ] = значение
        return результат
    def запретить(значение):
        raise ValueError("нечисловая константа JSON запрещена")
    if len(байты) > предел_обмена:
        raise ValueError("JSON превышает предел обмена")
    try:
        результат = json.loads(байты.decode("utf-8"), object_pairs_hook=пары, parse_constant=запретить)
    except (UnicodeError, RecursionError) as ошибка:
        raise ValueError("нужен ограниченный JSON в UTF8") from ошибка
    if type(результат) is not dict:
        raise ValueError("нужен один объект JSON")
    return результат


def читать(путь):
    if any(часть.is_symlink() for часть in (путь, *путь.parents)):
        raise ValueError("символическая ссылка в пути зеркала")
    дескриптор = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        до = os.fstat(дескриптор)
        if not stat.S_ISREG(до.st_mode) or до.st_size > 2 * 1024 * 1024:
            raise ValueError("нужен ограниченный обычный исходник зеркала")
        with os.fdopen(дескриптор, "rb", closefd=False) as поток:
            байты = поток.read(2 * 1024 * 1024 + 1)
        после = os.fstat(дескриптор)
        if ((до.st_dev, до.st_ino, до.st_size, до.st_mtime_ns, до.st_ctime_ns)
                != (после.st_dev, после.st_ino, после.st_size, после.st_mtime_ns, после.st_ctime_ns)
                or len(байты) != до.st_size):
            raise ValueError("исходник зеркала изменился при чтении")
        return байты, stat.S_IMODE(до.st_mode)
    finally:
        os.close(дескриптор)


def состав(корень, содержимое):
    if корень != корень.resolve() or not корень.is_dir():
        raise ValueError("нужен физический каталог зеркала")
    фактические_файлы = set()
    фактические_каталоги = set()
    каталоги = {str(п) for имя in содержимое for п in PurePosixPath(имя).parents if str(п) != "."}
    for путь in корень.rglob("*"):
        if путь.is_symlink():
            raise ValueError("ссылка в составе зеркала")
        имя = путь.relative_to(корень).as_posix()
        if путь.is_dir():
            if имя not in каталоги:
                raise ValueError("чужой каталог в составе зеркала")
            фактические_каталоги.add(имя)
        else:
            фактические_файлы.add(имя)
            if имя not in содержимое or читать(путь) != содержимое[имя]:
                raise ValueError("байты, режим или состав зеркала изменились")
    if фактические_файлы != set(содержимое) or фактические_каталоги != каталоги:
        raise ValueError("конечный состав зеркала изменился")


def снять(зеркало):
    зеркало = Path(зеркало)
    манифест, режим = читать(зеркало / "манифест.json")
    if hashlib.sha256(манифест).hexdigest() != хэш_манифеста or режим != 0o644:
        raise ValueError("манифест зеркала изменился")
    план = разобрать(манифест)
    if план["коммит"] != коммит_читателя or len(план["файлы"]) != 17:
        raise ValueError("неверный закреплённый читатель")
    содержимое = {"манифест.json": (манифест, режим)}
    for запись in план["файлы"]:
        имя = "Источники/" + коммит_читателя + "/" + запись["исходник"]
        байты, режим = читать(зеркало / имя)
        if (len(байты) != запись["байты"] or режим != (int(запись["режим"], 8) & 0o777)
                or hashlib.sha256(байты).hexdigest() != запись["sha256"]
                or hashlib.sha1(b"blob " + str(len(байты)).encode() + b"\0" + байты).hexdigest() != запись["blob"]):
            raise ValueError("байты или режим исходника зеркала изменились")
        содержимое[имя] = (байты, режим)
    состав(зеркало, содержимое)
    return содержимое


код_работника = r'''
import hashlib, importlib.machinery, importlib.util, json, os, pathlib, stat, sys, sysconfig, time
копия = pathlib.Path(sys.argv[1])
вход = json.loads(sys.stdin.buffer.read().decode("utf-8"))
разрешённые = {str(копия / имя) for имя in вход["файлы"]}
стандартная = pathlib.Path(sysconfig.get_path("stdlib")).resolve()
def прочитать(путь):
    if any(п.is_symlink() for п in (путь, *путь.parents)):
        raise ValueError("ссылка в частной копии")
    д = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        до = os.fstat(д)
        if not stat.S_ISREG(до.st_mode) or до.st_size > 2 * 1024 * 1024 or stat.S_IMODE(до.st_mode) != 0o400:
            raise ValueError("неверный обычный файл частной копии")
        with os.fdopen(д, "rb", closefd=False) as поток:
            байты = поток.read(2 * 1024 * 1024 + 1)
        после = os.fstat(д)
        if (до.st_dev,до.st_ino,до.st_size,до.st_mtime_ns,до.st_ctime_ns) != (после.st_dev,после.st_ino,после.st_size,после.st_mtime_ns,после.st_ctime_ns) or len(байты) != до.st_size:
            raise ValueError("частная копия изменилась при чтении")
        return байты
    finally:
        os.close(д)
манифест = прочитать(копия / "манифест.json")
if hashlib.sha256(манифест).hexdigest() != "d2eb066ccc9faf612b1f4b754c73c662810c34b4f29af04b1019fc5ff8447fb4":
    raise ValueError("подменён манифест частной копии")
план = json.loads(манифест.decode("utf-8"))
сохранённые = {}
модули_по_имени = {}
for запись in план["файлы"]:
    путь = копия / "Источники" / план["коммит"] / запись["исходник"]
    байты = прочитать(путь)
    if len(байты) != запись["байты"] or hashlib.sha256(байты).hexdigest() != запись["sha256"]:
        raise ValueError("подменены байты частной копии")
    сохранённые[str(путь)] = байты
    имя = путь.stem
    if имя in модули_по_имени:
        raise ValueError("неоднозначное имя закрытого модуля")
    модули_по_имени[имя] = str(путь)
ожидаемые_файлы = set(сохранённые) | {str(копия / "манифест.json")}
ожидаемые_каталоги = {п for имя in ожидаемые_файлы for п in pathlib.Path(имя).parents if п != копия and п.is_relative_to(копия)}
фактические_файлы = set()
фактические_каталоги = set()
for путь in копия.rglob("*"):
    if путь.is_symlink():
        raise ValueError("ссылка в частной копии")
    if путь.is_dir():
        if путь not in ожидаемые_каталоги:
            raise ValueError("чужой каталог частной копии")
        фактические_каталоги.add(путь)
    else:
        if str(путь) not in ожидаемые_файлы:
            raise ValueError("чужой файл частной копии")
        фактические_файлы.add(str(путь))
if фактические_файлы != ожидаемые_файлы or фактические_каталоги != ожидаемые_каталоги or ожидаемые_файлы != разрешённые:
    raise ValueError("состав частной копии не совпал")
# Все проектные SourceFileLoader исполняют уже проверенные bytes, включая exec_module помощников.
обычное_чтение = importlib.machinery.SourceFileLoader.get_data
def закрытое_чтение(загрузчик, имя):
    путь = pathlib.Path(имя).resolve()
    if путь.is_relative_to(копия):
        if str(путь) not in сохранённые:
            raise FileNotFoundError("непроверенный источник частной копии")
        return сохранённые[str(путь)]
    if not путь.is_relative_to(стандартная) or "site-packages" in путь.parts:
        raise ImportError("источник вне стандартной библиотеки")
    return обычное_чтение(загрузчик, имя)
setattr(importlib.machinery.SourceFileLoader, "get_data", закрытое_чтение)
class ЗакрытыйПоиск:
    def найти(сам, имя, путь=None, цель=None):
        if имя in модули_по_имени:
            исходник = модули_по_имени[имя]
            return importlib.util.spec_from_file_location(имя, исходник, loader=importlib.machinery.SourceFileLoader(имя, исходник))
        область = [п for п in (sys.path if путь is None else путь)
                   if pathlib.Path(п).resolve().is_relative_to(стандартная) and "site-packages" not in pathlib.Path(п).parts]
        описание = importlib.machinery.PathFinder.find_spec(имя, область, цель)
        if описание is not None and описание.origin is not None:
            источник = pathlib.Path(описание.origin).resolve()
            if not источник.is_relative_to(стандартная) or "site-packages" in источник.parts:
                raise ImportError("чужой модуль вне стандартной библиотеки")
        return описание
setattr(ЗакрытыйПоиск, "find_spec", ЗакрытыйПоиск.найти)
sys.meta_path = [importlib.machinery.BuiltinImporter, importlib.machinery.FrozenImporter, ЗакрытыйПоиск()]
начало = time.perf_counter_ns()
import обычное_поручение
загрузка = time.perf_counter_ns() - начало
профиль = {}
результат = обычное_поручение.проверить(вход["параметры"], вход["независимый"], новый_эффект=True, профиль=профиль)
модули = set()
for модуль in tuple(sys.modules.values()):
    имя = getattr(модуль, "__file__", None)
    if имя is None:
        continue
    путь = pathlib.Path(имя).resolve()
    if путь.is_relative_to(копия):
        if str(путь) not in разрешённые:
            raise ValueError("чужой модуль в частной копии")
        модули.add(str(путь))
    elif not путь.is_relative_to(стандартная) or "site-packages" in путь.parts:
        raise ValueError("модуль вне закрытой копии и стандартной библиотеки")
print(json.dumps({"схема":"fum.предметная-привязка.1", "результат":результат,
                  "читатель":профиль, "загрузка":загрузка, "модули":sorted(модули)}, ensure_ascii=False))
'''


def остановить(процесс):
    try:
        os.killpg(процесс.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    процесс.wait(timeout=2)
    for поток in (процесс.stdin, процесс.stdout, процесс.stderr):
        if поток is not None:
            поток.close()


def обменяться(процесс, вход):
    край = time.monotonic() + тайм_аут
    вывод = bytearray()
    ошибки = bytearray()
    позиция = 0
    with selectors.DefaultSelector() as наблюдатель:
        for поток, вид in ((процесс.stdout, "вывод"), (процесс.stderr, "ошибки"), (процесс.stdin, "вход")):
            os.set_blocking(поток.fileno(), False)
            наблюдатель.register(поток, selectors.EVENT_WRITE if вид == "вход" else selectors.EVENT_READ, вид)
        while наблюдатель.get_map():
            остаток = край - time.monotonic()
            if остаток <= 0:
                raise ValueError("общий тайм-аут работника проверки исполнителя")
            for событие, _ in наблюдатель.select(min(остаток, 0.1)):
                поток = событие.fileobj
                if событие.data == "вход":
                    try:
                        позиция += os.write(поток.fileno(), вход[позиция:позиция + 65536])
                    except BrokenPipeError:
                        позиция = len(вход)
                    if позиция == len(вход):
                        наблюдатель.unregister(поток)
                        поток.close()
                else:
                    байты = os.read(поток.fileno(), 65536)
                    if not байты:
                        наблюдатель.unregister(поток)
                        поток.close()
                        continue
                    буфер = вывод if событие.data == "вывод" else ошибки
                    if len(буфер) + len(байты) > предел_обмена:
                        raise ValueError("вывод работника превышает предел обмена")
                    буфер.extend(байты)
        процесс.wait(timeout=max(0.001, край - time.monotonic()))
    return bytes(вывод), bytes(ошибки)


def проверить_ответ(ответ, независимый, копия, содержимое):
    if (type(ответ) is not dict or set(ответ) != {"схема", "результат", "читатель", "загрузка", "модули"}
            or ответ["схема"] != "fum.предметная-привязка.1"
            or type(ответ["результат"]) is not dict
            or set(ответ["результат"]) != {"выбранное_поручение", "нативное_начало", "нативное_поручение"}
            or ответ["результат"]["выбранное_поручение"] != независимый):
        raise ValueError("неверный закрытый ответ работника")
    границы = []
    for поле in ("нативное_начало", "нативное_поручение"):
        префикс = ответ["результат"][поле]
        if (type(префикс) is not dict or set(префикс) != {"граница", "sha256"}
                or type(префикс["граница"]) is not int or not 0 < префикс["граница"] <= 16 * 1024 * 1024
                or type(префикс["sha256"]) is not str or re.fullmatch("[0-9a-f]{64}", префикс["sha256"]) is None):
            raise ValueError("неверный нативный префикс ответа")
        границы.append(префикс["граница"])
    if границы[0] > границы[1]:
        raise ValueError("порядок нативных префиксов ответа неверен")
    профиль = ответ["читатель"]
    поля_профиля = {"идентичности", "корень-и-акт", "ветка-и-владение", "нативные-префиксы",
                   "HEAD-и-область", "единый-снимок", "весь-читатель"}
    if (type(профиль) is not dict or set(профиль) != поля_профиля
            or any(type(в) is not list or len(в) != 1 or type(в[0]) is not int or not 0 <= в[0] <= 120_000_000_000
                   for в in профиль.values())
            or type(ответ["загрузка"]) is not int or not 0 <= ответ["загрузка"] <= 120_000_000_000):
        raise ValueError("неверный профиль ответа")
    модули = ответ["модули"]
    допустимые = {str(копия / имя) for имя in содержимое if имя.endswith(".py")}
    основной = str(копия / "Источники" / коммит_читателя / "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обычное_поручение.py")
    if (type(модули) is not list or not 1 <= len(модули) <= 17 or any(type(м) is not str for м in модули)
            or len(set(модули)) != len(модули) or not set(модули) <= допустимые or основной not in модули):
        raise ValueError("неверные модули ответа")


def байты_входа(параметры, независимый):
    if (type(параметры) is not dict or set(параметры) != поля_входа
            or параметры["схема"] != "fum.создание-коммита.7" or параметры["режим"] != "контрольная-точка"):
        raise ValueError("нужны ровно 12 полей предметного входа .7")
    if (type(независимый) is not dict or set(независимый) != поля_выбора
            or type(параметры["выбранное_поручение"]) is not dict
            or параметры["выбранное_поручение"] != независимый):
        raise ValueError("нет независимого выбора поручения либо его копия изменилась")
    if (any(type(параметры[к]) is not str or not параметры[к]
            for к in поля_входа - {"выбранное_поручение", "разрешённые_цели"})
            or any(type(в) is not str or not в for в in независимый.values())
            or type(параметры["разрешённые_цели"]) is not list
            or not 1 <= len(параметры["разрешённые_цели"]) <= 1024
            or any(type(п) is not str or not п for п in параметры["разрешённые_цели"])):
        raise ValueError("неверный тип полей входа или конечного списка целей")
    байты = json.dumps({"параметры": параметры, "независимый": независимый},
                       ensure_ascii=False, allow_nan=False, sort_keys=True, separators=(",", ":")).encode()
    разобрать(байты)
    return байты


def проверить(параметры, независимый, *, зеркало=None, профиль=None):
    копия_выбора = параметры.get("выбранное_поручение") if type(параметры) is dict else None
    if профиль is not None and (type(профиль) is not dict
            or any(профиль is в for в in (параметры, независимый, копия_выбора))):
        raise ValueError("профиль должен быть отдельным словарём вне проверяемого входа")
    начало = time.perf_counter_ns()
    try:
        удержанный_вход = байты_входа(параметры, независимый)
        вход = разобрать(удержанный_вход)
        зеркало = корень_зеркала if зеркало is None else Path(зеркало)
        содержимое = снять(зеркало)
        имена = {Path(имя).stem for имя in содержимое if имя.endswith(".py")}
        имена.add("охват_обычного_поручения")
        if имена.intersection(sys.modules):
            raise ValueError("предметный модуль уже загружен в чужом контексте")
        копия_содержимого = {имя: (байты, 0o400) for имя, (байты, _) in содержимое.items()}
        with tempfile.TemporaryDirectory(prefix="fum-actor-reader-") as временный:
            копия = Path(временный).resolve()
            if any(os.path.lexists(предок / ".git") for предок in (копия, *копия.parents)):
                raise ValueError("частная копия должна находиться вне любого Git-предка")
            for имя, (байты, режим) in копия_содержимого.items():
                путь = копия / имя
                путь.parent.mkdir(parents=True, exist_ok=True)
                путь.write_bytes(байты)
                путь.chmod(режим)
            состав(копия, копия_содержимого)
            обмен = json.dumps({**вход,
                               "файлы": list(содержимое), "коммит": коммит_читателя},
                              ensure_ascii=False, allow_nan=False).encode()
            разобрать(обмен)
            процесс = subprocess.Popen([sys.executable, "-I", "-B", "-S", "-c", код_работника, str(копия)],
                                       cwd=копия, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, start_new_session=True)
            try:
                вывод, ошибки = обменяться(процесс, обмен)
            except BaseException:
                остановить(процесс)
                raise
            if len(вывод) > предел_обмена or len(ошибки) > предел_обмена or процесс.returncode != 0:
                raise ValueError("работник проверки исполнителя отказал: " + ошибки[:2048].decode(errors="replace"))
            ответ = разобрать(вывод)
            проверить_ответ(ответ, вход["независимый"], копия, содержимое)
            if профиль is not None:
                профиль.update(читатель=ответ["читатель"], загрузка=ответ["загрузка"], модули_копии=ответ["модули"])
            состав(копия, копия_содержимого)
            состав(зеркало, содержимое)
            if байты_входа(параметры, независимый) != удержанный_вход:
                raise ValueError("параметры входа изменились при проверке исполнителя")
            return ответ["результат"]
    except (OSError, subprocess.TimeoutExpired, TypeError, KeyError, UnicodeError) as ошибка:
        raise ValueError(str(ошибка)) from ошибка
    finally:
        if профиль is not None:
            профиль["весь_загрузчик"] = time.perf_counter_ns() - начало
