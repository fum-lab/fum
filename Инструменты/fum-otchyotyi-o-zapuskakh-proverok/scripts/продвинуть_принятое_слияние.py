#!/usr/bin/env python3
"""Узкое локальное продвижение принятого merge; без очереди и публикации.

Предполагает единственного писателя. Любой неопределённый исход сохраняет
наблюдаемое состояние для восстановления; автоматического отката нет.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import selectors
import stat
import subprocess
import sys
import tempfile
import unicodedata


class Отказ(RuntimeError):
    pass


def среда():
    окружение = {имя_поля: значение_поля for имя_поля, значение_поля in os.environ.items()
           if not имя_поля.startswith(("GIT_", "PYTHON"))}
    окружение.update(GIT_NO_REPLACE_OBJECTS="1", GIT_NO_LAZY_FETCH="1", GIT_ATTR_NOSYSTEM="1",
               GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
    return окружение


def команда_гита():
    return ["git", "-c", "core.fsmonitor=false", "-c", "core.autocrlf=false",
            "-c", "core.eol=lf", "-c", "core.attributesFile=" + os.devnull,
            "-c", "core.hooksPath=" + os.devnull]


def идентичность(рабочий_корень):
    # Настроенная идентичность читается как данные; глобальные фильтры,
    # hooks и остальные настройки не передаются транзакциям.
    окружение = среда()
    окружение.pop("GIT_CONFIG_GLOBAL")
    окружение.pop("GIT_CONFIG_NOSYSTEM")
    результат = subprocess.run(команда_гита() + ["var", "GIT_COMMITTER_IDENT"],
                            cwd=рабочий_корень, env=окружение, capture_output=True, timeout=20)
    совпадение = re.fullmatch(r"(.+) <([^<>]+)> [0-9]+ [+-][0-9]{4}\n", результат.stdout.decode())
    if результат.returncode or совпадение is None:
        raise Отказ("Не удалось подтвердить настроенную Git-идентичность")
    return {"GIT_COMMITTER_NAME": совпадение[1], "GIT_COMMITTER_EMAIL": совпадение[2]}


def выполнить_гит(рабочий_корень, *аргументы):
    результат_гита = subprocess.run(команда_гита() + list(аргументы), cwd=рабочий_корень, env=среда(),
                       capture_output=True, timeout=60)
    if результат_гита.returncode:
        raise Отказ(результат_гита.stderr.decode(errors="replace").strip())
    return результат_гита.stdout


def идентификатор_объекта(рабочий_корень, ссылка):
    return выполнить_гит(рабочий_корень, "rev-parse", "--verify", ссылка).decode().strip()


def дерево(рабочий_корень, ссылка):
    результат = {}
    каталоги = []
    for запись in выполнить_гит(рабочий_корень, "ls-tree", "-rtz", ссылка).split(b"\0"):
        if запись:
            метаданные, имя = запись.split(b"\t", 1)
            режим, тип, значение = метаданные.decode().split()
            имя = os.fsdecode(имя)
            if тип == "tree":
                каталоги.append(имя)
            else:
                результат[имя] = (режим, значение)
    занятые_каталоги = {str(путь_элемента) for имя in результат for путь_элемента in Path(имя).parents if str(путь_элемента) != "."}
    for имя in каталоги:
        if имя not in занятые_каталоги:
            raise Отказ("Пустое поддерево не представимо точным индексом")
    return результат


def снимок_объекта(рабочий_корень, ссылка, кэш):
    # Только неизменяемые объекты полного OID; индекс и рабочие файлы
    # всегда перечитываются. Кэш принадлежит одному вызову перехода.
    ключ_кэша = (рабочий_корень.resolve(), ссылка)
    if ключ_кэша not in кэш:
        кэш[ключ_кэша] = (дерево(рабочий_корень, ссылка), идентификатор_объекта(рабочий_корень, ссылка + "^{tree}"),
                      выполнить_гит(рабочий_корень, "rev-parse", "--show-object-format").decode().strip())
    return кэш[ключ_кэша]


def проверить_копию(рабочий_корень, ссылка, кэш=None):
    кэш = {} if кэш is None else кэш
    ожидаемое, идентификатор_дерева, алгоритм = снимок_объекта(рабочий_корень, ссылка, кэш)
    фактическое = {}
    for запись in выполнить_гит(рабочий_корень, "ls-files", "--stage", "-z").split(b"\0"):
        if not запись:
            continue
        метаданные, имя = запись.split(b"\t", 1)
        режим, значение, стадия = метаданные.decode().split()
        if стадия != "0":
            raise Отказ("Незакрытые стадии индекса")
        фактическое[os.fsdecode(имя)] = (режим, значение)
    if фактическое != ожидаемое or выполнить_гит(рабочий_корень, "write-tree").decode().strip() != идентификатор_дерева:
        raise Отказ("Индекс не равен точному дереву")
    for запись in выполнить_гит(рабочий_корень, "ls-files", "-v", "-z").split(b"\0"):
        if запись and запись[:1] != b"H":
            raise Отказ("Скрытые или необычные флаги индекса")
    for имя, (режим, значение) in ожидаемое.items():
        путь = рабочий_корень / имя
        for родитель in путь.parents:
            if родитель == рабочий_корень:
                break
            if родитель.is_symlink():
                raise Отказ("Символическая ссылка в родительском пути")
        if режим == "160000":
            if путь.is_symlink() or not путь.is_dir() or идентификатор_объекта(путь, "HEAD") != значение:
                raise Отказ("Материализация gitlink не совпала")
            if Path(выполнить_гит(путь, "rev-parse", "--show-toplevel").decode().strip()).resolve() != путь.resolve():
                raise Отказ("Неверный физический корень gitlink")
            проверить_копию(путь, значение, кэш)
            if выполнить_гит(путь, "ls-files", "--others", "--ignored", "--exclude-standard", "-z"):
                raise Отказ("Лишние ignored-данные в материализации gitlink")
            continue
        сведения = путь.lstat()
        if режим not in ("100644", "100755") or not stat.S_ISREG(сведения.st_mode):
            raise Отказ("Необычный тип отслеживаемого файла")
        исполняемый = bool(сведения.st_mode & 0o111)
        if исполняемый != (режим == "100755"):
            raise Отказ("Режим рабочего файла не совпал")
        данные = путь.read_bytes()
        хэш = hashlib.new(алгоритм, b"blob " + str(len(данные)).encode()
                             + b"\0" + данные).hexdigest()
        if хэш != значение:
            raise Отказ("Рабочие байты не равны точному дереву: " + имя)
    if выполнить_гит(рабочий_корень, "ls-files", "--others", "--exclude-standard", "-z"):
        raise Отказ("Есть неотслеживаемый пользовательский хвост")


def ключ(имя):
    return unicodedata.normalize("NFC", имя).casefold()


def проверить_границу(рабочий_корень, прежний_коммит, новый_коммит, кэш=None):
    кэш = {} if кэш is None else кэш
    if выполнить_гит(рабочий_корень, "rev-parse", "--is-shallow-repository").strip() != b"false":
        raise Отказ("Shallow-история")
    общий_каталог = Path(выполнить_гит(рабочий_корень, "rev-parse", "--git-common-dir").decode().strip())
    общий_каталог = (рабочий_корень / общий_каталог).resolve()
    for имя in ("info/grafts", "info/attributes"):
        путь_элемента = общий_каталог / имя
        if путь_элемента.exists() and путь_элемента.stat().st_size:
            raise Отказ("Локальное переопределение истории или attributes")
    прежнее_дерево, будущее_дерево = снимок_объекта(рабочий_корень, прежний_коммит, кэш)[0], снимок_объекта(рабочий_корень, новый_коммит, кэш)[0]
    for имя in set(прежнее_дерево) | set(будущее_дерево):
        if Path(имя).name.casefold() == ".gitattributes":
            raise Отказ("Этот узкий переход не поддерживает attributes")
    ссылки_зависимостей = lambda содержимое_дерева: {имя_поля: значение_поля for имя_поля, значение_поля in содержимое_дерева.items() if значение_поля[0] == "160000"}
    if ссылки_зависимостей(прежнее_дерево) != ссылки_зависимостей(будущее_дерево):
        raise Отказ("Этот переход не меняет gitlink")
    цель = {ключ(путь_элемента) for путь_элемента in будущее_дерево}
    if len(цель) != len(будущее_дерево):
        raise Отказ("Регистровая или Unicode-коллизия цели")
    родители = {ключ(str(путь_элемента)) for имя in будущее_дерево for путь_элемента in Path(имя).parents
               if str(путь_элемента) != "."}
    if цель & родители:
        raise Отказ("Файл цели совпадает с родительским каталогом")
    игнорируемые_пути = выполнить_гит(рабочий_корень, "ls-files", "--others", "--ignored", "--exclude-standard", "-z")
    for сырые_байты in игнорируемые_пути.split(b"\0"):
        if not сырые_байты:
            continue
        имя = os.fsdecode(сырые_байты)
        if Path(имя).name.casefold() == ".gitattributes":
            raise Отказ("Игнорируемый attributes-файл рабочего дерева")
        ключ_пути = ключ(имя)
        if ключ_пути in цель or ключ_пути in родители or any(ключ(str(путь_элемента)) in цель for путь_элемента in Path(имя).parents):
            raise Отказ("Игнорируемый путь пересекается с целью: " + имя)


def сохранить(путь, значение):
    путь.parent.mkdir(parents=True, exist_ok=True)
    данные = (json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()
    дескриптор, временный_путь = tempfile.mkstemp(prefix=".fum-intent-", dir=путь.parent)
    try:
        with os.fdopen(дескриптор, "wb") as поток:
            поток.write(данные)
            поток.flush()
            os.fsync(поток.fileno())
        os.replace(временный_путь, путь)
        дескриптор_каталога = os.open(путь.parent, os.O_RDONLY)
        try:
            os.fsync(дескриптор_каталога)
        finally:
            os.close(дескриптор_каталога)
    finally:
        if os.path.exists(временный_путь):
            os.unlink(временный_путь)


def ответ(процесс, ожидаемое):
    with selectors.DefaultSelector() as селектор:
        селектор.register(процесс.stdout, selectors.EVENT_READ)
        if not селектор.select(20):
            raise Отказ("Неопределённый исход Git-транзакции")
        строка = процесс.stdout.readline()
    if строка != ожидаемое + b": ok\n":
        raise Отказ("Git не подтвердил фазу " + ожидаемое.decode())


def перейти(рабочий_корень, прежний_коммит, ведущий_коммит, новый_коммит, путь_намерения, корень_транзакции, *, наблюдатель=lambda фаза: None):
    рабочий_корень, путь_намерения, корень_транзакции = рабочий_корень.resolve(), путь_намерения.resolve(), корень_транзакции.resolve()
    if any(проверяемый_корень == путь_намерения or проверяемый_корень in путь_намерения.parents for проверяемый_корень in (рабочий_корень, корень_транзакции)):
        raise Отказ("Intent должен находиться вне checkout")
    for значение in (прежний_коммит, ведущий_коммит, новый_коммит):
        if not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", значение):
            raise Отказ("Требуются полные OID")
    if выполнить_гит(рабочий_корень, "symbolic-ref", "HEAD").strip() != b"refs/heads/master":
        raise Отказ("HEAD не указывает на master")
    родители = выполнить_гит(рабочий_корень, "show", "-s", "--format=%P", новый_коммит).decode().strip().split()
    if родители != [ведущий_коммит, прежний_коммит]:
        raise Отказ("Иной порядок родителей кандидата")
    текущий = идентификатор_объекта(рабочий_корень, "HEAD")
    кэш = {}
    состояние = {"M": прежний_коммит, "L": ведущий_коммит, "C": новый_коммит, "T": снимок_объекта(рабочий_корень, новый_коммит, кэш)[1],
             "корень": str(рабочий_корень), "контекст_транзакции": str(корень_транзакции),
             "исполнитель_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    предыдущее_состояние = json.loads(путь_намерения.read_text()) if путь_намерения.exists() else None
    if предыдущее_состояние is not None and any(предыдущее_состояние.get(имя_поля) != значение_поля for имя_поля, значение_поля in состояние.items()):
        raise Отказ("Intent относится к другой операции")
    if текущий == новый_коммит:
        if предыдущее_состояние is None:
            raise Отказ("Повтор требует исходного intent")
        проверить_копию(рабочий_корень, новый_коммит, кэш)
        return {"состояние": "уже_достигнуто", "коммит": новый_коммит}
    if текущий != прежний_коммит:
        raise Отказ("Master изменился")
    проверить_границу(рабочий_корень, прежний_коммит, новый_коммит, кэш)
    проверить_копию(рабочий_корень, прежний_коммит, кэш)
    общий_каталог = выполнить_гит(рабочий_корень, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
    if (общий_каталог != выполнить_гит(рабочий_корень, "rev-parse", "--absolute-git-dir").strip()
            or общий_каталог != выполнить_гит(корень_транзакции, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
            or общий_каталог == выполнить_гит(корень_транзакции, "rev-parse", "--absolute-git-dir").strip()
            or идентификатор_объекта(корень_транзакции, "HEAD") != новый_коммит):
        raise Отказ("Требуются первичный master и его отдельный candidate worktree на C")
    символическая_ссылка = subprocess.run(команда_гита() + ["symbolic-ref", "-q", "HEAD"],
                              cwd=корень_транзакции, env=среда(), capture_output=True)
    if символическая_ссылка.returncode not in (0, 1) or символическая_ссылка.stdout.strip() == b"refs/heads/master":
        raise Отказ("Контекст транзакции не должен иметь HEAD master")
    окружение_транзакции = среда()
    окружение_транзакции.update(идентичность(рабочий_корень))
    состояние["состояние"] = "подготовлено"
    сохранить(путь_намерения, состояние)
    процесс = None
    блокировка_вершины = None
    try:
        наблюдатель("до_транзакции")
        # Проверка HEAD держит отдельный lock: Git запрещает её объединять
        # с update его referent, а main-worktree/HEAD не принимает для записи.
        блокировка_вершины = subprocess.Popen(команда_гита() + ["update-ref", "--no-deref", "--stdin"],
                                      cwd=рабочий_корень, env=окружение_транзакции, stdin=subprocess.PIPE,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
        блокировка_вершины.stdin.write(b"start\n")
        ответ(блокировка_вершины, b"start")
        блокировка_вершины.stdin.write(b"symref-verify HEAD refs/heads/master\nprepare\n")
        ответ(блокировка_вершины, b"prepare")
        процесс = subprocess.Popen(команда_гита() + ["update-ref", "--no-deref", "--stdin"],
                                   cwd=корень_транзакции, env=окружение_транзакции, stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
        процесс.stdin.write(b"start\n")
        ответ(процесс, b"start")
        процесс.stdin.write(f"update refs/heads/master {новый_коммит} {прежний_коммит}\nprepare\n".encode())
        ответ(процесс, b"prepare")
        состояние["состояние"] = "refs_заблокированы"
        сохранить(путь_намерения, состояние)
        наблюдатель("до_read_tree")
        # Двухдеревный fast-forward сохраняет защиту Git от изменённых файлов.
        выполнить_гит(рабочий_корень, "read-tree", "-m", "-u", прежний_коммит, новый_коммит)
        наблюдатель("после_read_tree")
        проверить_копию(рабочий_корень, новый_коммит, кэш)
        состояние["состояние"] = "checkout_подготовлен"
        сохранить(путь_намерения, состояние)
        if блокировка_вершины.poll() is not None:
            raise Отказ("Потерян процесс, удерживающий проверку HEAD")
        процесс.stdin.write(b"commit\n")
        ответ(процесс, b"commit")
        процесс.stdin.close()
        процесс.wait(timeout=20)
        наблюдатель("после_commit")
        if процесс.returncode or идентификатор_объекта(рабочий_корень, "HEAD") != новый_коммит or выполнить_гит(рабочий_корень, "symbolic-ref", "HEAD").strip() != b"refs/heads/master":
            raise Отказ("Не подтверждён точный C после транзакции")
        проверить_копию(рабочий_корень, новый_коммит, кэш)
        блокировка_вершины.stdin.write(b"abort\n")
        ответ(блокировка_вершины, b"abort")
        блокировка_вершины.stdin.close()
        блокировка_вершины.wait(timeout=20)
        if блокировка_вершины.returncode:
            raise Отказ("Не подтверждено освобождение проверки HEAD")
        состояние["состояние"] = "завершено"
        сохранить(путь_намерения, состояние)
        return состояние
    except BaseException as ошибка:
        ошибки = []
        for дочерний_процесс in (процесс, блокировка_вершины):
            if дочерний_процесс is None:
                continue
            if дочерний_процесс.poll() is None:
                try:
                    дочерний_процесс.stdin.write(b"abort\n")
                    дочерний_процесс.stdin.close()
                    дочерний_процесс.wait(timeout=5)
                except (OSError, ValueError, subprocess.TimeoutExpired):
                    дочерний_процесс.kill()
                    дочерний_процесс.wait(timeout=5)
            ошибки.append(дочерний_процесс.stderr.read().decode(errors="replace"))
        состояние["git_stderr"] = "\n".join(ошибки)
        состояние["состояние"] = "требуется_разбор"
        состояние["ошибка"] = str(ошибка)
        try:
            состояние["фактический_HEAD"] = идентификатор_объекта(рабочий_корень, "HEAD")
            состояние["фактическое_дерево_индекса"] = выполнить_гит(рабочий_корень, "write-tree").decode().strip()
        except Exception as ошибка_чтения:
            состояние["ошибка_чтения"] = str(ошибка_чтения)
        сохранить(путь_намерения, состояние)
        raise
    finally:
        for дочерний_процесс in (процесс, блокировка_вершины):
            if дочерний_процесс is not None:
                for поток in (дочерний_процесс.stdin, дочерний_процесс.stdout, дочерний_процесс.stderr):
                    поток.close()


def главная():
    разборщик = argparse.ArgumentParser(description=__doc__)
    разборщик.add_argument("--корень", type=Path, required=True)
    разборщик.add_argument("--M", required=True)
    разборщик.add_argument("--L", required=True)
    разборщик.add_argument("--C", required=True)
    разборщик.add_argument("--запрос", required=True)
    разборщик.add_argument("--intent", type=Path, required=True)
    разборщик.add_argument("--кандидат", type=Path, required=True)
    параметры = разборщик.parse_args()
    рабочий_корень = параметры.корень.resolve()
    if идентификатор_объекта(рабочий_корень, "HEAD") == параметры.C:
        результат = перейти(рабочий_корень, параметры.M, параметры.L, параметры.C, параметры.intent, параметры.кандидат)
        print(json.dumps(результат, ensure_ascii=False, indent=2))
        return
    # Приёмка выполняется до любой записи и до загрузки предлагаемых файлов C.
    проверить_копию(рабочий_корень, параметры.M)
    читатель = рабочий_корень / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/закрытый_отчёт_из_гита.py"
    with tempfile.TemporaryDirectory(prefix="fum-promotion-python-") as кэш:
        команда = [sys.executable, "-E", "-B", "-X", "pycache_prefix=" + кэш, str(читатель),
                   "--корень-репозитория", str(рабочий_корень), "--коммит", параметры.C, "--запрос", параметры.запрос,
                   "--допуск-слияния", "--база", параметры.L, "--присоединяемый", параметры.M,
                   "--дерево", идентификатор_объекта(рабочий_корень, параметры.C + "^{tree}")]
        результат = subprocess.run(команда, env=среда(), capture_output=True, timeout=120)
        if результат.returncode or list(Path(кэш).iterdir()):
            raise Отказ("Доверенный читатель M не принял C: " + результат.stderr.decode(errors="replace"))
    print(json.dumps(перейти(рабочий_корень, параметры.M, параметры.L, параметры.C, параметры.intent, параметры.кандидат), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        главная()
    except Exception as ошибка:
        print(str(ошибка), file=sys.stderr)
        raise SystemExit(1)
