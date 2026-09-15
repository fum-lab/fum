"""Ограниченное наблюдение Git и допуск собственного дерева получателя."""
import hashlib
import os
from pathlib import Path
import re
import stat
import subprocess

from приём_направления import безопасный_путь, требовать, идентификатор_задачи


def выполнить(корень, *аргументы, допустимые=(0,)):
    среда = {ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith("GIT_")}
    среда.update(GIT_OPTIONAL_LOCKS="0", GIT_NO_LAZY_FETCH="1", GIT_TERMINAL_PROMPT="0",
                GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
    результат = subprocess.run(
        ["git", "--no-replace-objects", "-c", "core.fsmonitor=false", "-c", "core.hooksPath=" + os.devnull,
         "-c", "core.quotepath=false", "-c", "rerere.enabled=false", "-c", "merge.autoStash=false",
         "-c", "submodule.recurse=false",
         "-c", "commit.gpgSign=false", *аргументы], cwd=корень, env=среда, capture_output=True)
    требовать(результат.returncode in допустимые, "Git не подтвердил операцию: " + аргументы[0])
    return результат


def гит(корень, *аргументы):
    return выполнить(корень, *аргументы).stdout.decode("utf-8").strip()


def полный_объект(корень, значение, тип="commit"):
    формат = гит(корень, "rev-parse", "--show-object-format")
    требовать(формат in ("sha1", "sha256"), "Неподдержанный формат OID")
    длина = 40 if формат == "sha1" else 64
    требовать(isinstance(значение, str) and re.fullmatch("[0-9a-f]{" + str(длина) + "}", значение), "Нужен полный OID")
    требовать(гит(корень, "cat-file", "-t", значение) == тип, "Неверный тип Git-объекта")
    return значение


def физический_корень(значение):
    путь = Path(значение)
    требовать(путь.is_absolute() and str(путь.resolve()) == str(путь), "Нужен физический абсолютный корень")
    безопасный_путь(путь, каталог=True)
    требовать(Path(гит(путь, "rev-parse", "--show-toplevel")).resolve() == путь, "Нужен корень checkout")
    return путь


def снимок(корень, задача, ветка):
    корень = физический_корень(корень)
    требовать(идентификатор_задачи(задача), "Нужен UUID владельца")
    требовать(ветка.startswith("refs/heads/codex/"), "Получателю нужна собственная codex-ветка")
    требовать(гит(корень, "symbolic-ref", "HEAD") == ветка, "Изменился ref получателя")
    коммит = полный_объект(корень, гит(корень, "rev-parse", "HEAD"))
    деревья = выполнить(корень, "worktree", "list", "--porcelain", "-z").stdout.decode().split("\0")
    требовать(деревья.count("branch " + ветка) == 1, "Ветка занята несколькими деревьями")
    требовать(коммит == гит(корень, "rev-parse", "HEAD") and ветка == гит(корень, "symbolic-ref", "HEAD"), "Сдвиг во время наблюдения")
    return {"корень": str(корень), "владелец": задача, "ref": ветка, "коммит": коммит,
            "дерево": гит(корень, "rev-parse", коммит + "^{tree}")}


def предок(корень, источник, цель):
    return выполнить(корень, "merge-base", "--is-ancestor", источник, цель, допустимые=(0, 1)).returncode == 0


def объект_файла(корень, коммит, путь):
    требовать(isinstance(путь, str) and путь and not Path(путь).is_absolute()
              and Path(путь).as_posix() == путь and ".." not in Path(путь).parts, "Неверный путь свидетельства")
    текущий = коммит
    for номер, часть in enumerate(Path(путь).parts):
        записи = выполнить(корень, "ls-tree", "-z", текущий).stdout.split(b"\0")
        совпадения = [строка.split(b"\t", 1)[0].split() for строка in записи
                      if b"\t" in строка and строка.split(b"\t", 1)[1] == часть.encode()]
        требовать(len(совпадения) == 1, "Нет точного пути свидетельства")
        режим, тип, объект = совпадения[0]
        if номер + 1 < len(Path(путь).parts):
            требовать(режим == b"040000" and тип == b"tree", "Неподдержанный предок свидетельства")
        else:
            требовать(режим in (b"100644", b"100755") and тип == b"blob", "Нужен обычный файл свидетельства")
        текущий = объект.decode()
    полный_объект(корень, текущий, "blob")
    return выполнить(корень, "cat-file", "blob", текущий).stdout


def служебные_состояния(корень):
    имена = ("MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-merge", "rebase-apply",
             "sequencer", "BISECT_START", "index.lock", "MERGE_AUTOSTASH")
    return [имя for имя in имена if Path(гит(корень, "rev-parse", "--path-format=absolute", "--git-path", имя)).exists()]


def поддержанное_дерево(корень, источник, *, конфликт=False):
    конфигурация = гит(корень, "config", "--list")
    for строка in конфигурация.splitlines():
        ключ, _, значение = строка.partition("=")
        требовать(not (ключ in ("core.sparsecheckout", "core.sparsecheckoutcone") and значение != "false"), "Sparse checkout не поддержан")
        требовать(not (ключ.startswith("filter.") or (ключ.startswith("merge.") and ключ.endswith(".driver"))), "Внешний фильтр или merge-driver не поддержан")
        требовать(not (ключ.startswith("branch.") and ключ.endswith(".mergeoptions")), "Неявные параметры слияния ветки не поддержаны")
    требовать(гит(корень, "rev-parse", "--is-shallow-repository") == "false", "Неполная история не поддержана")
    for строка in выполнить(корень, "ls-files", "-v", "-z").stdout.split(b"\0"):
        if строка:
            требовать(строка[:1] == b"H" or (конфликт and строка[:1] == b"M"), "Необычный флаг индекса или конфликт")
    ссылки = []
    for версия in ("HEAD", источник):
        зависимости = {}
        for строка in выполнить(корень, "ls-tree", "-r", "-z", версия).stdout.split(b"\0"):
            if строка:
                сведения, путь = строка.split(b"\t", 1)
                режим, тип, объект = сведения.split()
                требовать(режим in (b"100644", b"100755", b"160000"), "Символьные файлы пока не поддержаны")
                if режим == b"160000":
                    требовать(тип == b"commit", "Повреждён gitlink")
                    зависимости[путь] = объект
        ссылки.append(зависимости)
    требовать(ссылки[0] == ссылки[1], "Изменяемые gitlink не поддержаны")
    for путь, объект in ссылки[0].items():
        запись = выполнить(корень, "ls-files", "--stage", "-z", "--", путь.decode()).stdout
        требовать(запись == b"160000 " + объект + b" 0\t" + путь + b"\0", "Gitlink индекса изменён либо конфликтует")
        папка = Path(корень) / путь.decode()
        безопасный_путь(папка, каталог=True)
        if (папка / ".git").exists():
            требовать(гит(папка, "rev-parse", "HEAD").encode() == объект, "Материализованная зависимость имеет другой HEAD")
            требовать(not служебные_состояния(папка), "В зависимости идёт Git-операция")
            чисто(папка)


def чисто(корень, *, индекс=True):
    требовать(not гит(корень, "diff", "--no-ext-diff", "--no-textconv", "--ignore-submodules=none", "--name-only"), "Есть незакоммиченная рабочая разница")
    if индекс:
        требовать(not гит(корень, "diff", "--cached", "--no-ext-diff", "--no-textconv", "--ignore-submodules=none", "--name-only"), "Индекс не чист")


def защищённые_файлы(корень):
    имена = set()
    for опции in (("--others", "--exclude-standard"), ("--others", "--ignored", "--exclude-standard")):
        имена.update(имя.decode() for имя in выполнить(корень, "ls-files", "-z", *опции).stdout.split(b"\0") if имя)
    итог = {}
    for имя in sorted(имена):
        путь = Path(корень) / имя
        данные = путь.lstat()
        требовать(stat.S_ISREG(данные.st_mode) or stat.S_ISLNK(данные.st_mode), "Неподдержанные неотслеживаемые данные")
        содержимое = os.readlink(путь).encode() if путь.is_symlink() else путь.read_bytes()
        итог[имя] = {"режим": данные.st_mode, "sha256": hashlib.sha256(содержимое).hexdigest()}
    for строка in выполнить(корень, "ls-files", "--stage", "-z").stdout.split(b"\0"):
        if строка.startswith(b"160000 "):
            имя = строка.split(b"\t", 1)[1].decode()
            вложенный = Path(корень) / имя
            if (вложенный / ".git").exists():
                for путь, данные in защищённые_файлы(вложенный).items():
                    итог[имя + "/" + путь] = данные
    return итог


def исключить_коллизии(корень, источник, защищённые):
    входящие = [имя.decode() for имя in выполнить(корень, "diff", "--name-only", "-z", "--no-renames", "HEAD", источник).stdout.split(b"\0") if имя]
    for имя in защищённые:
        for цель in входящие:
            левое, правое = имя.casefold(), цель.casefold()
            требовать(левое != правое and not левое.startswith(правое + "/") and not правое.startswith(левое + "/"),
                      "Входящий путь пересекает untracked/ignored: " + имя)
