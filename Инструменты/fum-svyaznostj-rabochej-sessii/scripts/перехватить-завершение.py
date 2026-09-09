#!/usr/bin/env python3
"""Синхронный scoped Stop для Codex; guard проверяет обязательства отдельно."""
import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import resource
import select
import signal
import stat
import subprocess
import sys
import tempfile
import time
import uuid


ПРЕДЕЛ_ВВОДА = 65536
ПРЕДЕЛ_ВЫВОДА = 65536
ПРЕДЕЛ_ФАЙЛОВ = 16 * 1024 * 1024
ПОЛЯ_РЕШЕНИЯ = {"схема", "задача", "решение", "следующая_работа",
                "ожидающие_работы", "вид_коммита"}


class Отказ(ValueError):
    pass


class Прерывание(BaseException):
    pass


def пары_без_повторов(пары):
    результат = {}
    for ключ, значение in пары:
        if ключ in результат:
            raise Отказ("повторные-поля")
        результат[ключ] = значение
    return результат


def разобрать(байты):
    def константа(значение):
        raise Отказ("нечисловая-константа")
    try:
        return json.loads(байты.decode("utf-8"), object_pairs_hook=пары_без_повторов,
                          parse_constant=константа)
    except (ValueError, UnicodeError, RecursionError) as ошибка:
        raise Отказ("неверный-JSON") from ошибка


def остановить(код):
    return {"continue": False, "stopReason":
            "FUM Stop: " + код + ". Завершённость обязательств не подтверждена; "
            "требуется действие пользователя или координатора."}


def диагностика(код):
    return {"systemMessage": "FUM Stop: " + код + "; принадлежность события не доказана, управление не применено."}


def число_секунд(текст):
    значение = float(текст)
    if not math.isfinite(значение) or not 0 < значение <= 30:
        raise argparse.ArgumentTypeError("допустим интервал (0, 30]")
    return значение


def предел(текст):
    значение = int(текст)
    if not 1 <= значение <= 128:
        raise argparse.ArgumentTypeError("допустим предел 1..128")
    return значение


class Параметры(argparse.ArgumentParser):
    def error(это, сообщение):
        raise Отказ("параметры")


def аргументы():
    парсер = Параметры(description=__doc__)
    парсер.add_argument("--корень-репозитория", type=Path, required=True)
    парсер.add_argument("--codex-thread-id", required=True)
    парсер.add_argument("--ожидаемый-cwd", type=Path, required=True)
    парсер.add_argument("--guard", type=Path, required=True)
    парсер.add_argument("--каталог-состояния", type=Path, required=True)
    парсер.add_argument("--план")
    парсер.add_argument("--файл-прогресса", action="append", required=True)
    парсер.add_argument("--предел-повторов", type=предел, default=3)
    парсер.add_argument("--предел-продолжений", type=предел, default=64)
    парсер.add_argument("--тайм-аут-backend", type=число_секунд, default=3.0)
    парсер.add_argument("--тайм-аут-ввода", type=число_секунд, default=1.0)
    парсер.add_argument("--профиль", action="store_true")
    return парсер.parse_args()


def прочитать_ввод(секунды):
    конец = time.monotonic() + секунды
    результат = bytearray()
    while True:
        остаток = конец - time.monotonic()
        if остаток <= 0 or not select.select([sys.stdin.fileno()], [], [], остаток)[0]:
            raise Отказ("тайм-аут-ввода")
        блок = os.read(sys.stdin.fileno(), min(8192, ПРЕДЕЛ_ВВОДА + 1 - len(результат)))
        if not блок:
            return bytes(результат)
        результат.extend(блок)
        if len(результат) > ПРЕДЕЛ_ВВОДА:
            raise Отказ("размер-ввода")


def обычный_путь(путь, отсутствует=False):
    if not путь.is_absolute() or ".." in путь.parts:
        raise Отказ("путь")
    for предок in reversed((путь, *путь.parents)):
        if предок.is_symlink():
            raise Отказ("символическая-ссылка")
    if not отсутствует and not путь.exists():
        raise Отказ("файл-отсутствует")
    return путь


def локальный_путь(корень, имя):
    путь = Path(имя)
    if путь.is_absolute() or str(путь) != имя or any(часть in (".", "..") for часть in имя.split("/")):
        raise Отказ("путь-прогресса")
    if путь.parts[0].casefold() == "proyekcii":
        raise Отказ("производный-прогресс")
    текущий = корень
    for часть in путь.parts:
        if текущий.exists() and часть not in os.listdir(текущий):
            # Отсутствующий результат допустим до реализации.
            if (текущий / часть).exists():
                raise Отказ("регистр-прогресса")
        текущий = текущий / часть
        if текущий.is_symlink():
            raise Отказ("ссылка-прогресса")
    return текущий


def хэш_файла(путь, бюджет):
    if not путь.exists():
        return "отсутствует", бюджет
    дескриптор = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(дескриптор, "rb") as поток:
        снимок = os.fstat(поток.fileno())
        if not stat.S_ISREG(снимок.st_mode) or снимок.st_size > бюджет:
            raise Отказ("размер-прогресса")
        хэш = hashlib.sha256()
        прочитано = 0
        while True:
            блок = поток.read(min(65536, бюджет - прочитано + 1))
            if not блок:
                break
            прочитано += len(блок)
            if прочитано > бюджет:
                raise Отказ("размер-прогресса")
            хэш.update(блок)
        после = os.fstat(поток.fileno())
        if (после.st_size, после.st_mtime_ns, после.st_ino) != (снимок.st_size, снимок.st_mtime_ns, снимок.st_ino):
            raise Отказ("изменение-прогресса-при-чтении")
    return хэш.hexdigest(), бюджет - прочитано


def отпечаток(настройки):
    бюджет = ПРЕДЕЛ_ФАЙЛОВ
    хэши = []
    for путь in [настройки.guard, *(локальный_путь(настройки.корень_репозитория, имя)
                                    for имя in настройки.файл_прогресса)]:
        хэш, бюджет = хэш_файла(путь, бюджет)
        хэши.append(хэш)
    # Порядок и набор выбранных файлов тоже часть измеряемого сценария.
    хэши.extend(настройки.файл_прогресса)
    return hashlib.sha256(json.dumps(хэши, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def убрать_процесс(процесс):
    try:
        os.killpg(процесс.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    процесс.wait(timeout=1)


def вызвать_проверку(настройки):
    команда = [sys.executable, "-B", str(обычный_путь(настройки.guard)),
               "--корень-репозитория", str(настройки.корень_репозитория),
               "--codex-thread-id", настройки.codex_thread_id, "--перед-завершением"]
    if настройки.план is not None:
        команда.extend(["--план", настройки.план])
    процесс = None
    маска = signal.pthread_sigmask(signal.SIG_BLOCK, {signal.SIGINT, signal.SIGTERM})
    def восстановить_маску():
        signal.pthread_sigmask(signal.SIG_SETMASK, маска)
    try:
        try:
            процесс = subprocess.Popen(команда, cwd=настройки.корень_репозитория,
                                      stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE, start_new_session=True,
                                      preexec_fn=восстановить_маску)
        finally:
            восстановить_маску()
        конец = time.monotonic() + настройки.тайм_аут_backend
        потоки = {процесс.stdout.fileno(): bytearray(), процесс.stderr.fileno(): bytearray()}
        вывод = потоки[процесс.stdout.fileno()]
        while потоки:
            остаток = конец - time.monotonic()
            if остаток <= 0:
                raise Отказ("guard-тайм-аут")
            готовые = select.select(list(потоки), [], [], остаток)[0]
            if not готовые:
                raise Отказ("guard-тайм-аут")
            for дескриптор in готовые:
                блок = os.read(дескриптор, 8192)
                if not блок:
                    del потоки[дескриптор]
                    continue
                потоки[дескриптор].extend(блок)
                if len(потоки[дескриптор]) > ПРЕДЕЛ_ВЫВОДА:
                    raise Отказ("guard-размер-вывода")
        try:
            код = процесс.wait(timeout=max(0.001, конец - time.monotonic()))
        except subprocess.TimeoutExpired as ошибка:
            raise Отказ("guard-тайм-аут") from ошибка
        if код not in (0, 3):
            raise Отказ("guard-код")
        try:
            ответ = разобрать(bytes(вывод))
            if not isinstance(ответ, dict) or set(ответ) != ПОЛЯ_РЕШЕНИЯ:
                raise Отказ("guard-поля")
            if ответ["схема"] != "fum.решение-продолжения.1" or ответ["задача"] != настройки.codex_thread_id:
                raise Отказ("guard-происхождение")
            решение = ответ["решение"]
            if решение not in ("продолжить", "завершить", "ожидать-ответа", "остановлено-пользователем"):
                raise Отказ("guard-решение")
            if код != (3 if решение == "продолжить" else 0):
                raise Отказ("guard-код-решение")
            следующая = ответ["следующая_работа"]
            if следующая is not None and (not isinstance(следующая, str) or not следующая.strip()
                                          or len(следующая) > 512 or any(ord(буква) < 32 for буква in следующая)):
                raise Отказ("guard-следующая-работа")
            if решение != "продолжить" and следующая is not None:
                raise Отказ("guard-следующая-работа")
            ожидающие = ответ["ожидающие_работы"]
            if not isinstance(ожидающие, list) or not all(isinstance(имя, str) and имя.strip() for имя in ожидающие):
                raise Отказ("guard-ожидания")
            if ответ["вид_коммита"] not in (None, "контрольный", "итоговый-этапа"):
                raise Отказ("guard-коммит")
            return ответ
        except (ValueError, TypeError, RecursionError) as ошибка:
            raise Отказ("guard-ответ") from ошибка
    finally:
        маска_уборки = signal.pthread_sigmask(signal.SIG_BLOCK, {signal.SIGINT, signal.SIGTERM})
        try:
            if процесс is not None:
                убрать_процесс(процесс)
                процесс.stdout.close()
                процесс.stderr.close()
        finally:
            signal.pthread_sigmask(signal.SIG_SETMASK, маска_уборки)


@contextmanager
def замок_состояния(настройки):
    каталог = настройки.каталог_состояния
    try:
        обычный_путь(каталог, отсутствует=True)
        if каталог == настройки.корень_репозитория or настройки.корень_репозитория in каталог.parents:
            raise Отказ("checkout")
        for предок in (каталог, *каталог.parents):
            if (предок / ".git").exists():
                raise Отказ("checkout")
        каталог.mkdir(mode=0o700, exist_ok=True)
        данные = каталог.stat()
        if not stat.S_ISDIR(данные.st_mode) or данные.st_uid != os.getuid() or данные.st_mode & 0o077:
            raise Отказ("права")
        путь = каталог / (настройки.codex_thread_id + ".lock")
        дескриптор = os.open(путь, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        try:
            данные = os.fstat(дескриптор)
            if not stat.S_ISREG(данные.st_mode) or данные.st_nlink != 1 or данные.st_uid != os.getuid() or данные.st_mode & 0o077:
                raise Отказ("права-замка")
            конец = time.monotonic() + 1
            while True:
                try:
                    fcntl.flock(дескриптор, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    if time.monotonic() >= конец:
                        raise Отказ("замок-занят")
                    time.sleep(0.01)
            yield каталог / (настройки.codex_thread_id + ".json")
        finally:
            os.close(дескриптор)
    except (OSError, ValueError) as ошибка:
        raise Отказ("состояние") from ошибка


def обновить_состояние(путь, настройки, хэш):
    состояние = {"схема": "fum.повторы-Stop.1", "задача": настройки.codex_thread_id,
                 "продолжений": 0, "отпечатки": {}}
    if путь.exists() or путь.is_symlink():
        дескриптор = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(дескриптор, "rb") as поток:
            данные = os.fstat(поток.fileno())
            if not stat.S_ISREG(данные.st_mode) or данные.st_nlink != 1 or данные.st_uid != os.getuid() or данные.st_mode & 0o077:
                raise Отказ("состояние")
            байты = поток.read(65537)
        if len(байты) > 65536:
            raise Отказ("состояние")
        старое = разобрать(байты)
        if not isinstance(старое, dict) or set(старое) != set(состояние):
            raise Отказ("состояние")
        if старое["схема"] != состояние["схема"] or старое["задача"] != состояние["задача"]:
            raise Отказ("состояние")
        количество, хэши = старое["продолжений"], старое["отпечатки"]
        if type(количество) is not int or not 0 <= количество <= 128 or not isinstance(хэши, dict):
            raise Отказ("состояние")
        if not all(re.fullmatch("[0-9a-f]{64}", ключ) and type(число) is int and 1 <= число <= 128
                   for ключ, число in хэши.items()) or sum(хэши.values()) != количество:
            raise Отказ("состояние")
        состояние = старое
    if состояние["продолжений"] >= настройки.предел_продолжений:
        return остановить("достигнут предел продолжений")
    повторов = состояние["отпечатки"].get(хэш, 0)
    if повторов >= настройки.предел_повторов:
        return остановить("достигнут предел повторов без нового наблюдаемого прогресса")
    состояние["продолжений"] += 1
    состояние["отпечатки"][хэш] = повторов + 1
    дескриптор, имя = tempfile.mkstemp(prefix=".запись-", dir=путь.parent)
    try:
        with os.fdopen(дескриптор, "wb") as поток:
            поток.write((json.dumps(состояние, ensure_ascii=False, sort_keys=True) + "\n").encode())
            поток.flush()
            os.fsync(поток.fileno())
        os.replace(имя, путь)
        каталог = os.open(путь.parent, os.O_RDONLY)
        try:
            os.fsync(каталог)
        finally:
            os.close(каталог)
    finally:
        if os.path.exists(имя):
            os.unlink(имя)
    return None


def обработать(настройки, событие, стадии):
    if not isinstance(событие, dict):
        return диагностика("неверный-вход")
    if событие.get("session_id") != настройки.codex_thread_id or событие.get("hook_event_name") != "Stop":
        return {} if событие.get("session_id") and событие.get("hook_event_name") else диагностика("нет-идентичности")
    if (type(событие.get("stop_hook_active")) is not bool or not isinstance(событие.get("turn_id"), str)
            or not событие["turn_id"].strip() or событие.get("cwd") != str(настройки.ожидаемый_cwd)):
        return остановить("неверный целевой вход")
    обычный_путь(настройки.корень_репозитория)
    обычный_путь(настройки.ожидаемый_cwd)
    причина = None
    начало = time.perf_counter_ns()
    try:
        ответ = вызвать_проверку(настройки)
    except (OSError, ValueError, subprocess.SubprocessError) as ошибка:
        код = str(ошибка) if isinstance(ошибка, Отказ) and str(ошибка).startswith("guard-") else "guard-запуск"
        причина = ("FUM Stop: " + код + ". Проверка обязательств не выполнена. "
                   "Проверь и исправь guard в пределах уже разрешённой работы; "
                   "не объявляй обязательства выполненными и не расширяй полномочия.")
    else:
        стадии["проверка"] = time.perf_counter_ns() - начало
        if ответ["решение"] == "остановлено-пользователем":
            return {"continue": False, "stopReason": "FUM Stop: задача остановлена пользователем."}
        if ответ["решение"] in ("завершить", "ожидать-ответа"):
            return {}
        причина = ("FUM Stop: guard требует продолжения. Следующая работа: "
                   + (ответ["следующая_работа"] or "проверить незавершённые обязательства")
                   + ". Выполни следующий доступный шаг в пределах исходного разрешения; "
                   "при явной остановке пользователя остановись. Уже показанный ответ не отменён.")
    стадии["проверка"] = time.perf_counter_ns() - начало
    try:
        начало = time.perf_counter_ns()
        хэш = отпечаток(настройки)
        стадии["прогресс"] = time.perf_counter_ns() - начало
        начало = time.perf_counter_ns()
        with замок_состояния(настройки) as путь:
            остановка = обновить_состояние(путь, настройки, хэш)
        стадии["состояние"] = time.perf_counter_ns() - начало
        return остановка or {"decision": "block", "reason": причина}
    except (OSError, ValueError) as ошибка:
        return остановить("состояние или измерение прогресса недоступно")


def выполнить():
    начало = time.perf_counter_ns()
    настройки = None
    размер = 0
    стадии = {}
    целевой = False
    ответ = диагностика("параметры")
    def прервать(номер, кадр):
        raise Прерывание()
    signal.signal(signal.SIGTERM, прервать)
    signal.signal(signal.SIGINT, прервать)
    try:
        настройки = аргументы()
        if str(uuid.UUID(настройки.codex_thread_id)) != настройки.codex_thread_id:
            raise Отказ("идентификатор-настройки")
        if len(настройки.файл_прогресса) > 32:
            raise Отказ("предел-файлов")
        try:
            начало_ввода = time.perf_counter_ns()
            вход = прочитать_ввод(настройки.тайм_аут_ввода)
            размер = len(вход)
            событие = разобрать(вход)
            стадии["ввод"] = time.perf_counter_ns() - начало_ввода
        except (OSError, ValueError):
            ответ = диагностика("неверный-или-неполный-вход")
        else:
            целевой = isinstance(событие, dict) and событие.get("session_id") == настройки.codex_thread_id and событие.get("hook_event_name") == "Stop"
            ответ = обработать(настройки, событие, стадии)
    except Прерывание:
        ответ = остановить("вызов прерван") if целевой else диагностика("вызов прерван")
    except (OSError, ValueError, TypeError, RecursionError):
        ответ = остановить("ошибка целевого входа") if целевой else диагностика("ошибка параметров")
    try:
        print(json.dumps(ответ, ensure_ascii=False, sort_keys=True))
    except (BrokenPipeError, OSError):
        return 1
    if настройки is not None and настройки.профиль:
        try:
            print("FUM-PROFILE " + json.dumps({"схема": "fum.профиль-Stop.1",
                  "вход_байты": размер, "длительность_нс": time.perf_counter_ns() - начало,
                  "стадии_нс": стадии,
                  "пик_памяти_байты": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * (1 if sys.platform == "darwin" else 1024),
                  "пик_памяти_потомков_байты": resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss * (1 if sys.platform == "darwin" else 1024),
                  "исход": "продолжить" if ответ.get("decision") == "block" else
                           "остановить" if ответ.get("continue") is False else "без-управления"},
                  ensure_ascii=False), file=sys.stderr)
        except OSError:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
