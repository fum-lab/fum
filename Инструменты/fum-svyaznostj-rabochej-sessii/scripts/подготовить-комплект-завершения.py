#!/usr/bin/env python3
"""Подготовка приватного Stop-комплекта; никакой установки hooks или Trust."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import time

# Этот текст целиком включается в доверяемую command, а не загружается из checkout.
ЗАГРУЗЧИК = r'''
import hashlib
import json
import os
from pathlib import Path
import re
import select
import stat
import sys
import time
import uuid

ПРЕФИКС = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/"
ПУТИ = [ПРЕФИКС + имя for имя in ("перехватить-завершение.py", "проверить-продолжение-задачи.py", "обязательства_задачи.py")]
ПУТИ += ["Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py"]
ПРЕДЕЛ = 1024 * 1024

def требовать(условие, причина):
    if not условие:
        raise ValueError(причина)

def строка(значение):
    требовать(type(значение) is str and 0 < len(значение) <= 4096
              and not any(ord(символ) < 32 for символ in значение), "строка")
    return значение

def путь(значение, приватный=False, отсутствует=False):
    строка(значение)
    результат = Path(значение)
    требовать(результат.is_absolute() and str(результат) == значение
              and ".." not in результат.parts, "путь")
    for часть in [*reversed(результат.parents), результат]:
        if приватный:
            голый_репозиторий = (os.path.lexists(часть / "HEAD")
                and (os.path.lexists(часть / "commondir")
                     or (os.path.lexists(часть / "objects")
                         and (os.path.lexists(часть / "refs") or os.path.lexists(часть / "packed-refs")))))
            требовать(not os.path.lexists(часть / ".git") and not голый_репозиторий, "git-предок")
        try:
            сведения = часть.lstat()
        except FileNotFoundError:
            требовать(отсутствует and часть == результат, "путь-отсутствует")
            continue
        требовать(not stat.S_ISLNK(сведения.st_mode), "путь-ссылка")
        требовать(stat.S_ISDIR(сведения.st_mode), "путь-тип")
        if приватный:
            требовать(сведения.st_uid in (0, os.getuid())
                      and (not сведения.st_mode & 0o022 or сведения.st_mode & stat.S_ISVTX), "права-предка")
    return результат

def права(объект, режим, каталог=False):
    сведения = объект.lstat()
    требовать((stat.S_ISDIR if каталог else stat.S_ISREG)(сведения.st_mode)
              and stat.S_IMODE(сведения.st_mode) == режим
              and сведения.st_uid == os.getuid()
              and (каталог or сведения.st_nlink == 1), "права-тип")
    return сведения

def читать(объект, предел=ПРЕДЕЛ):
    до = права(объект, 0o400)
    требовать(0 <= до.st_size <= предел, "размер")
    дескриптор = os.open(объект, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        def снимок(сведения):
            return (сведения.st_dev, сведения.st_ino, сведения.st_size,
                    сведения.st_mtime_ns, сведения.st_ctime_ns, сведения.st_mode,
                    сведения.st_uid, сведения.st_nlink)
        требовать(снимок(до) == снимок(os.fstat(дескриптор)), "гонка-чтения")
        данные = bytearray()
        while len(данные) <= предел:
            блок = os.read(дескриптор, min(65536, предел + 1 - len(данные)))
            if not блок:
                break
            данные.extend(блок)
        требовать(len(данные) == до.st_size and снимок(до) == снимок(os.fstat(дескриптор))
                  and снимок(до) == снимок(объект.lstat()), "гонка-чтения")
        return bytes(данные)
    finally:
        os.close(дескриптор)

def пары(элементы):
    результат = {}
    for ключ, значение in элементы:
        требовать(ключ not in результат, "повтор-ключа")
        результат[ключ] = значение
    return результат

def неверная_константа(значение):
    raise ValueError("константа")

def разобрать(данные):
    return json.loads(данные.decode("utf-8"), object_pairs_hook=пары,
                      parse_constant=неверная_константа)

def поля(значение, имена):
    требовать(type(значение) is dict and set(значение) == set(имена), "поля")

def относительный(значение):
    строка(значение)
    кандидат = Path(значение)
    требовать(not кандидат.is_absolute() and str(кандидат) == значение
              and значение != "." and ".." not in кандидат.parts, "относительный-путь")

def конфигурация(настройки):
    поля(настройки, ["интерпретатор", "корень", "cwd", "задача", "состояние", "прогресс", "план"])
    требовать(str(uuid.UUID(строка(настройки["задача"]))) == настройки["задача"], "uuid")
    путь(настройки["корень"])
    путь(настройки["cwd"])
    состояние = путь(настройки["состояние"], приватный=True, отсутствует=True)
    требовать(not состояние.is_relative_to(Path(настройки["корень"])), "состояние-в-дереве")
    интерпретатор = Path(строка(настройки["интерпретатор"]))
    требовать(интерпретатор.is_absolute() and интерпретатор.resolve(strict=True) == интерпретатор
              and интерпретатор.is_file() and os.access(интерпретатор, os.X_OK), "интерпретатор")
    прогресс = настройки["прогресс"]
    требовать(type(прогресс) is list and 1 <= len(прогресс) <= 32
              and all(type(п) is str for п in прогресс) and len(set(прогресс)) == len(прогресс), "прогресс")
    for имя in прогресс:
        относительный(имя)
    if настройки["план"] is not None:
        относительный(настройки["план"])

def проверить(каталог, хэш, адрес=True):
    требовать(type(хэш) is str and re.fullmatch("[0-9a-f]{64}", хэш), "хэш")
    путь(str(каталог), приватный=True)
    права(каталог.parent, 0o700, каталог=True)
    требовать(not адрес or каталог.name == "stop-" + хэш, "адрес")
    манифест_байты = читать(каталог / "манифест.json", 65536)
    требовать(hashlib.sha256(манифест_байты).hexdigest() == хэш, "манифест-хэш")
    манифест = разобрать(манифест_байты)
    поля(манифест, ["схема", "commit", "tree", "файлы", "выполнение"])
    требовать(манифест["схема"] == "fum.комплект-Stop.1", "схема")
    for имя in ("commit", "tree"):
        требовать(type(манифест[имя]) is str and re.fullmatch("[0-9a-f]{40}", манифест[имя]), имя)
    конфигурация(манифест["выполнение"])
    записи = манифест["файлы"]
    требовать(type(записи) is list and len(записи) == 4, "инвентарь")
    каталоги = {"."}
    for имя in ПУТИ:
        каталоги.update(str(родитель) for родитель in Path(имя).parents)
    ожидаемые = set(ПУТИ) | {"манифест.json"} | каталоги
    увиденные = set()
    очередь = [каталог]
    while очередь:
        текущий = очередь.pop()
        имя = str(текущий.relative_to(каталог))
        требовать(имя in ожидаемые and имя not in увиденные, "инвентарь")
        увиденные.add(имя)
        if имя in каталоги:
            права(текущий, 0o500, каталог=True)
            with os.scandir(текущий) as элементы:
                for элемент in элементы:
                    требовать(len(очередь) + len(увиденные) < 32, "инвентарь-размер")
                    очередь.append(Path(элемент.path))
        else:
            права(текущий, 0o400)
    требовать(увиденные == ожидаемые, "инвентарь")
    исходники = {}
    for имя, запись in zip(ПУТИ, записи):
        поля(запись, ["путь", "blob", "git_mode", "mode", "размер", "sha256"])
        требовать(запись["путь"] == имя and запись["git_mode"] == "100644"
                  and запись["mode"] == "0400", "запись")
        требовать(type(запись["размер"]) is int and 0 <= запись["размер"] <= ПРЕДЕЛ, "размер")
        требовать(type(запись["blob"]) is str and re.fullmatch("[0-9a-f]{40}", запись["blob"]), "blob")
        требовать(type(запись["sha256"]) is str and re.fullmatch("[0-9a-f]{64}", запись["sha256"]), "sha256")
        данные = читать(каталог / имя)
        требовать(len(данные) == запись["размер"]
                  and hashlib.sha256(данные).hexdigest() == запись["sha256"]
                  and hashlib.sha1(b"blob " + str(len(данные)).encode() + b"\0" + данные).hexdigest() == запись["blob"], "blob-хэш")
        исходники[имя] = данные
    return манифест, исходники

def отказ(задача):
    # Успешный путь stdin не трогает. Отказ никогда не управляет чужой задачей.
    ответ = {"systemMessage": "FUM Stop: приватный комплект не прошёл проверку целостности."}
    try:
        конец = time.monotonic() + 1.0
        данные = bytearray()
        while len(данные) <= 65536:
            остаток = конец - time.monotonic()
            if остаток <= 0 or not select.select([0], [], [], остаток)[0]:
                raise ValueError("ввод")
            блок = os.read(0, min(8192, 65537 - len(данные)))
            if not блок:
                break
            данные.extend(блок)
        требовать(len(данные) <= 65536, "ввод")
        событие = разобрать(bytes(данные))
        принадлежность = str(uuid.UUID(задача)) == задача
        if принадлежность and type(событие) is dict and событие.get("session_id") == задача and событие.get("hook_event_name") == "Stop":
            ответ = {"continue": False, "stopReason": "FUM: повреждение приватного комплекта Stop. Проверка не выполнена; обязательства не объявлены завершёнными."}
    except (ValueError, OSError, TypeError, RecursionError):
        pass
    print(json.dumps(ответ, ensure_ascii=False))

def запустить():
    задача = sys.argv[3] if len(sys.argv) == 4 else ""
    try:
        требовать(len(sys.argv) == 4 and sys.flags.isolated and sys.flags.no_site
                  and sys.flags.dont_write_bytecode, "запуск")
        каталог = Path(sys.argv[1])
        манифест, исходники = проверить(каталог, sys.argv[2])
        настройки = манифест["выполнение"]
        требовать(настройки["задача"] == задача and str(Path(sys.executable).resolve()) == настройки["интерпретатор"], "запуск")
        адаптер = каталог / ПУТИ[0]
        команда = [str(адаптер), "--корень-репозитория", настройки["корень"],
                   "--codex-thread-id", задача, "--ожидаемый-cwd", настройки["cwd"],
                   "--guard", str(каталог / ПУТИ[1]), "--каталог-состояния", настройки["состояние"]]
        for имя in настройки["прогресс"]:
            команда += ["--файл-прогресса", имя]
        if настройки["план"] is not None:
            команда += ["--план", настройки["план"]]
        код = compile(исходники[ПУТИ[0]], str(адаптер), "exec")
    except (ValueError, OSError, TypeError, KeyError, RecursionError, SyntaxError):
        отказ(задача)
        return
    sys.argv = команда
    exec(код, {"__name__": "__main__", "__file__": str(адаптер),
               "__package__": None, "__cached__": None, "__builtins__": __builtins__})

if __name__ == "__main__":
    запустить()
'''

ПРОВЕРКА = {"__name__": "проверка_комплекта"}
exec(ЗАГРУЗЧИК, ПРОВЕРКА)
ПУТИ = ПРОВЕРКА["ПУТИ"]


def гит(корень, *аргументы):
    среда = {"PATH": "/usr/bin:/bin", "GIT_CONFIG_NOSYSTEM": "1",
             "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_NO_LAZY_FETCH": "1", "GIT_TERMINAL_PROMPT": "0"}
    процесс = subprocess.run(["/usr/bin/git", "--no-replace-objects", "-C", str(корень), *аргументы],
                             capture_output=True, timeout=10, env=среда)
    if процесс.returncode:
        raise ValueError("источник-git")
    return процесс.stdout


def объект(корень, вид, идентификатор):
    размер = int(гит(корень, "cat-file", "-s", идентификатор))
    if not 0 <= размер <= ПРОВЕРКА["ПРЕДЕЛ"]:
        raise ValueError("источник-размер")
    данные = гит(корень, "cat-file", вид, идентификатор)
    if len(данные) != размер or hashlib.sha1(вид.encode() + b" " + str(размер).encode() + b"\0" + данные).hexdigest() != идентификатор:
        raise ValueError("источник-хэш")
    return данные


def найти_объект(корень, дерево, имя, кэш=None):
    if кэш is None:
        кэш = {}
    части = Path(имя).parts
    if not части or Path(имя).is_absolute() or ".." in части:
        raise ValueError("источник-путь")
    for номер, часть in enumerate(части):
        if дерево not in кэш:
            данные = объект(корень, "tree", дерево)
            записи, начало = {}, 0
            while начало < len(данные):
                ноль = данные.find(b"\0", начало)
                if ноль < 0 or ноль + 21 > len(данные):
                    raise ValueError("источник-tree")
                заголовок = данные[начало:ноль].split(b" ", 1)
                if len(заголовок) != 2:
                    raise ValueError("источник-tree")
                режим, имя_узла = заголовок
                if (режим not in (b"40000", b"100644", b"100755", b"120000", b"160000")
                        or not имя_узла or b"/" in имя_узла or имя_узла in (b".", b"..")
                        or имя_узла in записи):
                    raise ValueError("источник-tree")
                записи[имя_узла] = (режим, данные[ноль + 1:ноль + 21].hex())
                начало = ноль + 21
            кэш[дерево] = записи
        запись = кэш[дерево].get(часть.encode())
        if запись is None:
            raise ValueError("источник-инвентарь")
        режим, идентификатор = запись
        if номер == len(части) - 1:
            if режим != b"100644":
                raise ValueError("источник-тип")
            return идентификатор
        if режим != b"40000":
            raise ValueError("источник-тип")
        дерево = идентификатор


def источник(корень, коммит):
    if not re.fullmatch("[0-9a-f]{40}", коммит):
        raise ValueError("commit")
    if гит(корень, "cat-file", "-t", коммит).strip() != b"commit":
        raise ValueError("commit-тип")
    данные = объект(корень, "commit", коммит)
    строка = данные.split(b"\n", 1)[0]
    if not re.fullmatch(b"tree [0-9a-f]{40}", строка):
        raise ValueError("commit-tree")
    дерево = строка[5:].decode()
    записи, байты, кэш = [], {}, {}
    for имя in ПУТИ:
        идентификатор = найти_объект(корень, дерево, имя, кэш)
        данные = объект(корень, "blob", идентификатор)
        байты[имя] = данные
        записи.append({"путь": имя, "blob": идентификатор, "git_mode": "100644",
                       "mode": "0400", "размер": len(данные), "sha256": hashlib.sha256(данные).hexdigest()})
    return дерево, записи, байты


def синхронизировать(каталог):
    дескриптор = os.open(каталог, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(дескриптор)
    finally:
        os.close(дескриптор)


def записать(путь, данные):
    дескриптор = os.open(путь, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(дескриптор, "wb") as поток:
        поток.write(данные)
        поток.flush()
        os.fchmod(поток.fileno(), 0o400)
        os.fsync(поток.fileno())


def подготовить(аргументы):
    корень = ПРОВЕРКА["путь"](аргументы.источник)
    хранилище = ПРОВЕРКА["путь"](аргументы.хранилище, приватный=True, отсутствует=True)
    if not хранилище.exists():
        хранилище.mkdir(mode=0o700, exist_ok=True)
    ПРОВЕРКА["права"](хранилище, 0o700, каталог=True)
    настройки = {"интерпретатор": str(Path(аргументы.интерпретатор).resolve(strict=True)),
                 "корень": аргументы.корень_репозитория, "cwd": аргументы.ожидаемый_cwd,
                 "задача": аргументы.codex_thread_id, "состояние": аргументы.каталог_состояния,
                 "прогресс": аргументы.файл_прогресса, "план": аргументы.план}
    ПРОВЕРКА["конфигурация"](настройки)
    проба = subprocess.run([настройки["интерпретатор"], "-I", "-S", "-B", "-c",
                           "import sys,tomllib,fcntl; assert sys.version_info >= (3,11)"],
                          capture_output=True, timeout=5, env={"PATH": "/usr/bin:/bin"})
    if проба.returncode:
        raise ValueError("интерпретатор")
    дерево, записи, исходники = источник(корень, аргументы.commit)
    манифест = {"схема": "fum.комплект-Stop.1", "commit": аргументы.commit, "tree": дерево,
                "файлы": записи, "выполнение": настройки}
    данные = (json.dumps(манифест, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()
    хэш = hashlib.sha256(данные).hexdigest()
    цель = хранилище / ("stop-" + хэш)
    замок = хранилище / ".подготовка.lock"
    дескриптор = os.open(замок, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    try:
        сведения = os.fstat(дескриптор)
        if not (stat.S_ISREG(сведения.st_mode) and stat.S_IMODE(сведения.st_mode) == 0o600
                and сведения.st_uid == os.getuid() and сведения.st_nlink == 1):
            raise ValueError("замок")
        конец = time.monotonic() + 5
        while True:
            try:
                fcntl.flock(дескриптор, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= конец:
                    raise ValueError("замок-занят")
                time.sleep(0.01)
        if os.path.lexists(цель):
            try:
                ПРОВЕРКА["проверить"](цель, хэш)
            except (ValueError, OSError, TypeError, KeyError, RecursionError) as ошибка:
                raise ValueError("повреждение-существующей-цели") from ошибка
        else:
            временный = Path(tempfile.mkdtemp(prefix=".подготовка-", dir=хранилище))
            try:
                for имя, содержимое in {**исходники, "манифест.json": данные}.items():
                    путь = временный / имя
                    путь.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                    записать(путь, содержимое)
                каталоги = [п for п in временный.rglob("*") if п.is_dir()] + [временный]
                for каталог in sorted(каталоги, key=lambda п: len(п.parts), reverse=True):
                    каталог.chmod(0o500)
                    синхронизировать(каталог)
                ПРОВЕРКА["проверить"](временный, хэш, адрес=False)
                if os.path.lexists(цель):
                    raise ValueError("коллизия")
                os.rename(временный, цель)
                синхронизировать(хранилище)
            finally:
                if временный.exists():
                    for каталог, _, _ in os.walk(временный):
                        Path(каталог).chmod(0o700)
                    shutil.rmtree(временный)
    finally:
        os.close(дескриптор)
    команда = "exec " + shlex.join(["/usr/bin/env", "-i", "PATH=/usr/bin:/bin",
                          настройки["интерпретатор"], "-I", "-S", "-B", "-c", ЗАГРУЗЧИК,
                          str(цель), хэш, настройки["задача"]])
    кандидат = {"hooks": {"Stop": [{"hooks": [{"type": "command", "command": команда, "timeout": 10}]}]}}
    return {"схема": "fum.кандидат-комплекта-Stop.1", "каталог": str(цель), "sha256": хэш,
            "манифест": манифест, "кандидат": кандидат,
            "загрузчик_sha256": hashlib.sha256(ЗАГРУЗЧИК.encode()).hexdigest()}


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    for имя in ("источник", "commit", "хранилище", "интерпретатор", "корень-репозитория",
                "ожидаемый-cwd", "codex-thread-id", "каталог-состояния"):
        парсер.add_argument("--" + имя, required=True)
    парсер.add_argument("--файл-прогресса", action="append", required=True)
    парсер.add_argument("--план")
    аргументы = парсер.parse_args()
    try:
        результат = подготовить(аргументы)
    except (ValueError, OSError, TypeError, KeyError, RecursionError, subprocess.SubprocessError) as ошибка:
        print("FUM: подготовка отклонена: " + str(ошибка), file=sys.stderr)
        return 2
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
