"""Конечный снимок обычных исходников из точного Git-коммита."""
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
from pathlib import PurePosixPath
import re
import stat
import subprocess
import tempfile
import unicodedata


def гит(корень, *аргументы):
    среда = {имя: значение for имя, значение in os.environ.items() if not имя.startswith("GIT_")}
    среда.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_SYSTEM="/dev/null",
                GIT_CONFIG_GLOBAL="/dev/null", GIT_NO_LAZY_FETCH="1")
    return subprocess.check_output(
        ["git", "--no-replace-objects", "--no-optional-locks", "--literal-pathspecs", "-C", str(корень), *аргументы],
        stderr=subprocess.PIPE, env=среда)


def снять(корень, коммит, пути):
    корень = Path(корень)
    if корень != корень.resolve() or not корень.is_dir():
        raise ValueError("нужен физический корень исходного Git checkout")
    if Path(гит(корень, "rev-parse", "--show-toplevel").decode().strip()) != корень:
        raise ValueError("подкаталог не подходит: нужен точный корень исходного Git checkout")
    if type(коммит) is not str or not re.fullmatch(r"[0-9a-f]{40}", коммит):
        raise ValueError("нужен полный точный OID исходного коммита")
    if type(пути) is not list or not 1 <= len(пути) <= 64:
        raise ValueError("нужен конечный непустой перечень не более 64 исходников")
    виденные = set()
    компоненты = {}
    for путь in пути:
        if (type(путь) is not str or len(путь.encode()) > 1024
                or PurePosixPath(путь).is_absolute() or str(PurePosixPath(путь)) != путь
                or any(часть in {"", ".", ".."} or часть.startswith(".") for часть in путь.split("/"))
                or any(ord(символ) < 32 for символ in путь)):
            raise ValueError("неканонический относительный путь источника")
        ключ = unicodedata.normalize("NFC", путь).casefold()
        if ключ in виденные:
            raise ValueError("повтор или коллизия пути зеркала")
        виденные.add(ключ)
        части = путь.split("/")
        for число in range(1, len(части) + 1):
            префикс = "/".join(части[:число])
            ключ_компонента = unicodedata.normalize("NFC", префикс).casefold()
            вид = "файл" if число == len(части) else "каталог"
            if ключ_компонента in компоненты and компоненты[ключ_компонента] != (префикс, вид):
                raise ValueError("коллизия компонента каталога или файла")
            компоненты[ключ_компонента] = (префикс, вид)
    if гит(корень, "cat-file", "-t", коммит).strip() != b"commit":
        raise ValueError("OID должен указывать на commit")
    записи = []
    for путь in sorted(пути):
        строка = гит(корень, "ls-tree", "-z", коммит, "--", путь).decode()
        if not строка.endswith("\0") or строка.count("\0") != 1 or строка.count("\t") != 1:
            raise ValueError("не найден единственный обычный исходник из Git")
        описание, имя = строка.rstrip("\0").split("\t")
        режим, тип, объект = описание.split(" ")
        if имя != путь or тип != "blob" or режим not in {"100644", "100755"}:
            raise ValueError("источник из Git должен быть обычным файлом")
        размер = int(гит(корень, "cat-file", "-s", объект).strip())
        if not 0 <= размер <= 2 * 1024 * 1024:
            raise ValueError("исходный файл превышает предел 2 MiB")
        байты = гит(корень, "cat-file", "blob", объект)
        if len(байты) != размер or hashlib.sha1(b"blob " + str(размер).encode() + b"\0" + байты).hexdigest() != объект:
            raise ValueError("размер или Git blob исходника не совпал")
        записи.append({"исходник": имя, "режим": режим, "blob": объект,
                       "байты": len(байты), "sha256": hashlib.sha256(байты).hexdigest()})
    return {"схема": "fum.конечное-зеркало-инструментов.1", "коммит": коммит, "файлы": записи}


def байты_плана(план):
    return (json.dumps(план, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()


def сохранить(корень, план, назначение, ожидаемый_хэш):
    """Проверка всего плана, закрытая сборка и одна публикация нового каталога."""
    if (type(план) is not dict or type(план.get("файлы")) is not list
            or type(ожидаемый_хэш) is not str
            or hashlib.sha256(байты_плана(план)).hexdigest() != ожидаемый_хэш):
        raise ValueError("байты плана не совпали с независимым SHA256")
    try:
        свежий = снять(корень, план["коммит"], [запись["исходник"] for запись in план["файлы"]])
    except (KeyError, TypeError) as ошибка:
        raise ValueError("не разобран конечный план зеркала") from ошибка
    if байты_плана(свежий) != байты_плана(план):
        raise ValueError("план не совпал с точными Git-объектами")
    if sum(запись["байты"] for запись in план["файлы"]) > 8 * 1024 * 1024:
        raise ValueError("конечное зеркало превышает 8 MiB")
    назначение = Path(назначение)
    if not назначение.is_absolute() or назначение != назначение.resolve() or not назначение.parent.is_dir():
        raise ValueError("назначение должно иметь физический существующий родитель")
    проверить_путь(назначение)
    содержимое = {"манифест.json": (байты_плана(план), 0o644)}
    for запись in план["файлы"]:
        байты = гит(корень, "cat-file", "blob", запись["blob"])
        if len(байты) != запись["байты"] or hashlib.sha256(байты).hexdigest() != запись["sha256"]:
            raise ValueError("источник изменился перед сохранением")
        имя = "Источники/" + план["коммит"] + "/" + запись["исходник"]
        содержимое[имя] = (байты, int(запись["режим"], 8) & 0o777)
    if назначение.exists():
        проверить_состав(назначение, содержимое)
        синхронизировать_дерево(назначение)
        with открытый_каталог(назначение.parent) as дескриптор:
            os.fsync(дескриптор)
        return
    with tempfile.TemporaryDirectory(prefix=".fum-mirror-capture-", dir=назначение.parent) as имя:
        временный = Path(имя).resolve()
        for имя_файла, (байты, режим) in содержимое.items():
            путь = временный / имя_файла
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_bytes(байты)
            путь.chmod(режим)
            with путь.open("rb") as поток:
                os.fsync(поток.fileno())
        проверить_состав(временный, содержимое)
        синхронизировать_дерево(временный)
        проверить_путь(назначение)
        if os.path.lexists(назначение):
            raise ValueError("назначение появилось во время подготовки зеркала")
        # Кооперативная граница одного писателя: проверка выше и rename не являются CAS.
        os.rename(временный, назначение)
        try:
            with открытый_каталог(назначение.parent) as дескриптор:
                os.fsync(дескриптор)
        except OSError as ошибка:
            ошибка.add_note("rename выполнен; синхронизация родителя не подтверждена; назначение сохранено")
            raise
    проверить_состав(назначение, содержимое)


def проверить_путь(путь):
    if any(часть.is_symlink() for часть in (путь, *путь.parents)):
        raise ValueError("символическая ссылка в назначении зеркала")


def прочитать_обычный(путь):
    проверить_путь(путь)
    дескриптор = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        до = os.fstat(дескриптор)
        if not stat.S_ISREG(до.st_mode) or до.st_size > 2 * 1024 * 1024:
            raise ValueError("нужен ограниченный обычный файл зеркала")
        with os.fdopen(дескриптор, "rb", closefd=False) as поток:
            байты = поток.read(2 * 1024 * 1024 + 1)
        после = os.fstat(дескриптор)
        if ((до.st_dev, до.st_ino, до.st_size, до.st_mtime_ns, до.st_ctime_ns)
                != (после.st_dev, после.st_ino, после.st_size, после.st_mtime_ns, после.st_ctime_ns)
                or len(байты) != до.st_size):
            raise ValueError("файл зеркала изменился во время чтения")
        return байты, stat.S_IMODE(до.st_mode)
    finally:
        os.close(дескриптор)


def проверить_состав(назначение, содержимое):
    проверить_путь(назначение)
    файлы = set()
    каталоги = set()
    ожидаемые_каталоги = {str(предок) for имя in содержимое for предок in PurePosixPath(имя).parents if str(предок) != "."}
    for путь in назначение.rglob("*"):
        if путь.is_symlink():
            raise ValueError("символическая ссылка в составе зеркала")
        имя = путь.relative_to(назначение).as_posix()
        if путь.is_dir():
            каталоги.add(имя)
        else:
            файлы.add(имя)
            if имя not in содержимое or прочитать_обычный(путь) != содержимое[имя]:
                raise ValueError("байты, режим или состав зеркала изменились")
    if файлы != set(содержимое) or каталоги != ожидаемые_каталоги:
        raise ValueError("состав зеркала не совпал с конечным планом")


def синхронизировать_дерево(корень):
    каталоги = [путь for путь in корень.rglob("*") if путь.is_dir()]
    for путь in sorted(каталоги, key=lambda путь: len(путь.parts), reverse=True) + [корень]:
        with открытый_каталог(путь) as дескриптор:
            os.fsync(дескриптор)


@contextmanager
def открытый_каталог(путь):
    дескриптор = os.open(путь, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        yield дескриптор
    finally:
        os.close(дескриптор)
