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
    env = {k: v for k, v in os.environ.items()
           if not k.startswith(("GIT_", "PYTHON"))}
    env.update(GIT_NO_REPLACE_OBJECTS="1", GIT_NO_LAZY_FETCH="1", GIT_ATTR_NOSYSTEM="1",
               GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
    return env


def команда_git():
    return ["git", "-c", "core.fsmonitor=false", "-c", "core.autocrlf=false",
            "-c", "core.eol=lf", "-c", "core.attributesFile=" + os.devnull,
            "-c", "core.hooksPath=" + os.devnull]


def идентичность(root):
    # Настроенная идентичность читается как данные; глобальные фильтры,
    # hooks и остальные настройки не передаются транзакциям.
    env = среда()
    env.pop("GIT_CONFIG_GLOBAL")
    env.pop("GIT_CONFIG_NOSYSTEM")
    result = subprocess.run(команда_git() + ["var", "GIT_COMMITTER_IDENT"],
                            cwd=root, env=env, capture_output=True, timeout=20)
    match = re.fullmatch(r"(.+) <([^<>]+)> [0-9]+ [+-][0-9]{4}\n", result.stdout.decode())
    if result.returncode or match is None:
        raise Отказ("Не удалось подтвердить настроенную Git-идентичность")
    return {"GIT_COMMITTER_NAME": match[1], "GIT_COMMITTER_EMAIL": match[2]}


def git(root, *args):
    p = subprocess.run(команда_git() + list(args), cwd=root, env=среда(),
                       capture_output=True, timeout=60)
    if p.returncode:
        raise Отказ(p.stderr.decode(errors="replace").strip())
    return p.stdout


def oid(root, ref):
    return git(root, "rev-parse", "--verify", ref).decode().strip()


def дерево(root, ref):
    result = {}
    directories = []
    for row in git(root, "ls-tree", "-rtz", ref).split(b"\0"):
        if row:
            meta, name = row.split(b"\t", 1)
            mode, kind, value = meta.decode().split()
            name = os.fsdecode(name)
            if kind == "tree":
                directories.append(name)
            else:
                result[name] = (mode, value)
    occupied = {str(p) for name in result for p in Path(name).parents if str(p) != "."}
    for name in directories:
        if name not in occupied:
            raise Отказ("Пустое поддерево не представимо точным индексом")
    return result


def снимок_объекта(root, ref, cache):
    # Только неизменяемые объекты полного OID; индекс и рабочие файлы
    # всегда перечитываются. Кэш принадлежит одному вызову перехода.
    key = (root.resolve(), ref)
    if key not in cache:
        cache[key] = (дерево(root, ref), oid(root, ref + "^{tree}"),
                      git(root, "rev-parse", "--show-object-format").decode().strip())
    return cache[key]


def проверить_копию(root, ref, cache=None):
    cache = {} if cache is None else cache
    expected, tree_oid, algorithm = снимок_объекта(root, ref, cache)
    actual = {}
    for row in git(root, "ls-files", "--stage", "-z").split(b"\0"):
        if not row:
            continue
        meta, name = row.split(b"\t", 1)
        mode, value, stage = meta.decode().split()
        if stage != "0":
            raise Отказ("Незакрытые стадии индекса")
        actual[os.fsdecode(name)] = (mode, value)
    if actual != expected or git(root, "write-tree").decode().strip() != tree_oid:
        raise Отказ("Индекс не равен точному дереву")
    for row in git(root, "ls-files", "-v", "-z").split(b"\0"):
        if row and row[:1] != b"H":
            raise Отказ("Скрытые или необычные флаги индекса")
    for name, (mode, value) in expected.items():
        path = root / name
        for parent in path.parents:
            if parent == root:
                break
            if parent.is_symlink():
                raise Отказ("Символическая ссылка в родительском пути")
        if mode == "160000":
            if path.is_symlink() or not path.is_dir() or oid(path, "HEAD") != value:
                raise Отказ("Материализация gitlink не совпала")
            if Path(git(path, "rev-parse", "--show-toplevel").decode().strip()).resolve() != path.resolve():
                raise Отказ("Неверный физический корень gitlink")
            проверить_копию(path, value, cache)
            if git(path, "ls-files", "--others", "--ignored", "--exclude-standard", "-z"):
                raise Отказ("Лишние ignored-данные в материализации gitlink")
            continue
        info = path.lstat()
        if mode not in ("100644", "100755") or not stat.S_ISREG(info.st_mode):
            raise Отказ("Необычный тип отслеживаемого файла")
        executable = bool(info.st_mode & 0o111)
        if executable != (mode == "100755"):
            raise Отказ("Режим рабочего файла не совпал")
        data = path.read_bytes()
        digest = hashlib.new(algorithm, b"blob " + str(len(data)).encode()
                             + b"\0" + data).hexdigest()
        if digest != value:
            raise Отказ("Рабочие байты не равны точному дереву: " + name)
    if git(root, "ls-files", "--others", "--exclude-standard", "-z"):
        raise Отказ("Есть неотслеживаемый пользовательский хвост")


def ключ(name):
    return unicodedata.normalize("NFC", name).casefold()


def проверить_границу(root, old, new, cache=None):
    cache = {} if cache is None else cache
    if git(root, "rev-parse", "--is-shallow-repository").strip() != b"false":
        raise Отказ("Shallow-история")
    common = Path(git(root, "rev-parse", "--git-common-dir").decode().strip())
    common = (root / common).resolve()
    for name in ("info/grafts", "info/attributes"):
        p = common / name
        if p.exists() and p.stat().st_size:
            raise Отказ("Локальное переопределение истории или attributes")
    before, after = снимок_объекта(root, old, cache)[0], снимок_объекта(root, new, cache)[0]
    for name in set(before) | set(after):
        if Path(name).name.casefold() == ".gitattributes":
            raise Отказ("Этот узкий переход не поддерживает attributes")
    links = lambda x: {k: v for k, v in x.items() if v[0] == "160000"}
    if links(before) != links(after):
        raise Отказ("Этот переход не меняет gitlink")
    target = {ключ(p) for p in after}
    if len(target) != len(after):
        raise Отказ("Регистровая или Unicode-коллизия цели")
    parents = {ключ(str(p)) for name in after for p in Path(name).parents
               if str(p) != "."}
    if target & parents:
        raise Отказ("Файл цели совпадает с родительским каталогом")
    ignored = git(root, "ls-files", "--others", "--ignored", "--exclude-standard", "-z")
    for raw in ignored.split(b"\0"):
        if not raw:
            continue
        name = os.fsdecode(raw)
        if Path(name).name.casefold() == ".gitattributes":
            raise Отказ("Игнорируемый attributes-файл рабочего дерева")
        k = ключ(name)
        if k in target or k in parents or any(ключ(str(p)) in target for p in Path(name).parents):
            raise Отказ("Игнорируемый путь пересекается с целью: " + name)


def сохранить(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()
    fd, temporary = tempfile.mkstemp(prefix=".fum-intent-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def ответ(process, expected):
    with selectors.DefaultSelector() as selector:
        selector.register(process.stdout, selectors.EVENT_READ)
        if not selector.select(20):
            raise Отказ("Неопределённый исход Git-транзакции")
        line = process.stdout.readline()
    if line != expected + b": ok\n":
        raise Отказ("Git не подтвердил фазу " + expected.decode())


def перейти(root, old, leading, new, intent, transaction_root, *, наблюдатель=lambda phase: None):
    root, intent, transaction_root = root.resolve(), intent.resolve(), transaction_root.resolve()
    if any(r == intent or r in intent.parents for r in (root, transaction_root)):
        raise Отказ("Intent должен находиться вне checkout")
    for value in (old, leading, new):
        if not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", value):
            raise Отказ("Требуются полные OID")
    if git(root, "symbolic-ref", "HEAD").strip() != b"refs/heads/master":
        raise Отказ("HEAD не указывает на master")
    parents = git(root, "show", "-s", "--format=%P", new).decode().strip().split()
    if parents != [leading, old]:
        raise Отказ("Иной порядок родителей кандидата")
    current = oid(root, "HEAD")
    cache = {}
    state = {"M": old, "L": leading, "C": new, "T": снимок_объекта(root, new, cache)[1],
             "корень": str(root), "контекст_транзакции": str(transaction_root),
             "исполнитель_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    previous = json.loads(intent.read_text()) if intent.exists() else None
    if previous is not None and any(previous.get(k) != v for k, v in state.items()):
        raise Отказ("Intent относится к другой операции")
    if current == new:
        if previous is None:
            raise Отказ("Повтор требует исходного intent")
        проверить_копию(root, new, cache)
        return {"состояние": "уже_достигнуто", "коммит": new}
    if current != old:
        raise Отказ("Master изменился")
    проверить_границу(root, old, new, cache)
    проверить_копию(root, old, cache)
    common = git(root, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
    if (common != git(root, "rev-parse", "--absolute-git-dir").strip()
            or common != git(transaction_root, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
            or common == git(transaction_root, "rev-parse", "--absolute-git-dir").strip()
            or oid(transaction_root, "HEAD") != new):
        raise Отказ("Требуются первичный master и его отдельный candidate worktree на C")
    symbolic = subprocess.run(команда_git() + ["symbolic-ref", "-q", "HEAD"],
                              cwd=transaction_root, env=среда(), capture_output=True)
    if symbolic.returncode not in (0, 1) or symbolic.stdout.strip() == b"refs/heads/master":
        raise Отказ("Контекст транзакции не должен иметь HEAD master")
    transaction_env = среда()
    transaction_env.update(идентичность(root))
    state["состояние"] = "подготовлено"
    сохранить(intent, state)
    process = None
    head_guard = None
    try:
        наблюдатель("до_транзакции")
        # Проверка HEAD держит отдельный lock: Git запрещает её объединять
        # с update его referent, а main-worktree/HEAD не принимает для записи.
        head_guard = subprocess.Popen(команда_git() + ["update-ref", "--no-deref", "--stdin"],
                                      cwd=root, env=transaction_env, stdin=subprocess.PIPE,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
        head_guard.stdin.write(b"start\n")
        ответ(head_guard, b"start")
        head_guard.stdin.write(b"symref-verify HEAD refs/heads/master\nprepare\n")
        ответ(head_guard, b"prepare")
        process = subprocess.Popen(команда_git() + ["update-ref", "--no-deref", "--stdin"],
                                   cwd=transaction_root, env=transaction_env, stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
        process.stdin.write(b"start\n")
        ответ(process, b"start")
        process.stdin.write(f"update refs/heads/master {new} {old}\nprepare\n".encode())
        ответ(process, b"prepare")
        state["состояние"] = "refs_заблокированы"
        сохранить(intent, state)
        наблюдатель("до_read_tree")
        # Двухдеревный fast-forward сохраняет защиту Git от изменённых файлов.
        git(root, "read-tree", "-m", "-u", old, new)
        наблюдатель("после_read_tree")
        проверить_копию(root, new, cache)
        state["состояние"] = "checkout_подготовлен"
        сохранить(intent, state)
        if head_guard.poll() is not None:
            raise Отказ("Потерян процесс, удерживающий проверку HEAD")
        process.stdin.write(b"commit\n")
        ответ(process, b"commit")
        process.stdin.close()
        process.wait(timeout=20)
        наблюдатель("после_commit")
        if process.returncode or oid(root, "HEAD") != new or git(root, "symbolic-ref", "HEAD").strip() != b"refs/heads/master":
            raise Отказ("Не подтверждён точный C после транзакции")
        проверить_копию(root, new, cache)
        head_guard.stdin.write(b"abort\n")
        ответ(head_guard, b"abort")
        head_guard.stdin.close()
        head_guard.wait(timeout=20)
        if head_guard.returncode:
            raise Отказ("Не подтверждено освобождение проверки HEAD")
        state["состояние"] = "завершено"
        сохранить(intent, state)
        return state
    except BaseException as error:
        errors = []
        for child in (process, head_guard):
            if child is None:
                continue
            if child.poll() is None:
                try:
                    child.stdin.write(b"abort\n")
                    child.stdin.close()
                    child.wait(timeout=5)
                except (OSError, ValueError, subprocess.TimeoutExpired):
                    child.kill()
                    child.wait(timeout=5)
            errors.append(child.stderr.read().decode(errors="replace"))
        state["git_stderr"] = "\n".join(errors)
        state["состояние"] = "требуется_разбор"
        state["ошибка"] = str(error)
        try:
            state["фактический_HEAD"] = oid(root, "HEAD")
            state["фактическое_дерево_индекса"] = git(root, "write-tree").decode().strip()
        except Exception as read_error:
            state["ошибка_чтения"] = str(read_error)
        сохранить(intent, state)
        raise
    finally:
        for child in (process, head_guard):
            if child is not None:
                for stream in (child.stdin, child.stdout, child.stderr):
                    stream.close()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--корень", type=Path, required=True)
    p.add_argument("--M", required=True)
    p.add_argument("--L", required=True)
    p.add_argument("--C", required=True)
    p.add_argument("--запрос", required=True)
    p.add_argument("--intent", type=Path, required=True)
    p.add_argument("--кандидат", type=Path, required=True)
    a = p.parse_args()
    root = a.корень.resolve()
    if oid(root, "HEAD") == a.C:
        result = перейти(root, a.M, a.L, a.C, a.intent, a.кандидат)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return
    # Приёмка выполняется до любой записи и до загрузки предлагаемых файлов C.
    проверить_копию(root, a.M)
    reader = root / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/закрытый_отчёт_из_гита.py"
    with tempfile.TemporaryDirectory(prefix="fum-promotion-python-") as cache:
        command = [sys.executable, "-E", "-B", "-X", "pycache_prefix=" + cache, str(reader),
                   "--корень-репозитория", str(root), "--коммит", a.C, "--запрос", a.запрос,
                   "--допуск-слияния", "--база", a.L, "--присоединяемый", a.M,
                   "--дерево", oid(root, a.C + "^{tree}")]
        result = subprocess.run(command, env=среда(), capture_output=True, timeout=120)
        if result.returncode or list(Path(cache).iterdir()):
            raise Отказ("Доверенный читатель M не принял C: " + result.stderr.decode(errors="replace"))
    print(json.dumps(перейти(root, a.M, a.L, a.C, a.intent, a.кандидат), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
