"""Зеркальный регистратор с закреплённым исходным проверяющим контуром."""
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import types

корень_зеркала = Path(__file__).resolve().parents[1]
хэш_манифеста = "81c136d139a9918fe79eb15049a6c06eee1e6e3348fe23a365fa806d75eb3738"
имя_модуля = "fum_регистратор_закреплённой_базы"
активный_модуль = None
активное_состояние = None


def прочитать(путь, предел):
    for часть in (путь, *путь.parents):
        if часть.is_symlink():
            raise RuntimeError("символическая ссылка в пути зеркала")
        if часть == корень_зеркала:
            break
    дескриптор = os.open(путь, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        до = os.fstat(дескриптор)
        if not stat.S_ISREG(до.st_mode) or до.st_size > предел:
            raise RuntimeError("источник зеркала должен быть ограниченным обычным файлом")
        with os.fdopen(дескриптор, "rb", closefd=False) as поток:
            байты = поток.read(предел + 1)
        после = os.fstat(дескриптор)
        if (до.st_dev, до.st_ino, до.st_size, до.st_mtime_ns, до.st_ctime_ns) != (
                после.st_dev, после.st_ino, после.st_size, после.st_mtime_ns, после.st_ctime_ns):
            raise RuntimeError("источник зеркала изменился при чтении")
        if len(байты) != до.st_size:
            raise RuntimeError("источник зеркала прочитан не полностью")
        return байты, stat.S_IMODE(до.st_mode)
    finally:
        os.close(дескриптор)


def проверить_зеркало():
    байты, _ = прочитать(корень_зеркала / "манифест.json", 8192)
    if hashlib.sha256(байты).hexdigest() != хэш_манифеста:
        raise RuntimeError("манифест зеркала изменился")
    манифест = json.loads(байты)
    сохранённые = {}
    for запись in манифест["файлы"]:
        путь = корень_зеркала / запись["зеркало"]
        байты, режим = прочитать(путь, 200000)
        объект_гит = hashlib.sha1(b"blob " + str(len(байты)).encode() + b"\0" + байты).hexdigest()
        if (len(байты) != запись["байты"] or режим != (int(запись["режим"], 8) & 0o777)
                or hashlib.sha256(байты).hexdigest() != запись["sha256"] or объект_гит != запись["blob"]):
            raise RuntimeError("исходные байты или режим зеркала изменились")
        сохранённые[запись["исходник"]] = байты
    исходники = корень_зеркала / "Источники" / манифест["коммит"]
    фактические = set()
    for путь in исходники.rglob("*"):
        if путь.is_symlink():
            raise RuntimeError("ссылка в составе зеркала")
        if путь.is_file():
            фактические.add(путь.relative_to(исходники).as_posix())
    if фактические != set(сохранённые):
        raise RuntimeError("состав зеркала изменился")
    return сохранённые


@contextmanager
def исходник():
    global активный_модуль, активное_состояние
    сохранённые = проверить_зеркало()
    if имя_модуля in sys.modules or активный_модуль is not None:
        raise RuntimeError("имя модуля зеркала уже занято")
    модуль = types.ModuleType(имя_модуля)
    путь = "Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py"
    setattr(модуль, "__file__", str(корень_зеркала / "Источники/e1c3ab638c2b995905ae476c31c7822309451a0f" / путь))
    sys.modules[имя_модуля] = модуль
    try:
        exec(compile(сохранённые[путь], getattr(модуль, "__file__"), "exec"), vars(модуль))
        активный_модуль = модуль
        активное_состояние = dict(vars(модуль))
        yield модуль
    finally:
        исходная_ошибка = sys.exception()
        try:
            проверить_зеркало()
            if sys.modules.get(имя_модуля) is not модуль:
                raise RuntimeError("загруженный модуль зеркала подменён")
        except Exception as ошибка:
            if исходная_ошибка is None:
                raise
            исходная_ошибка.add_note(str(ошибка))
        finally:
            if sys.modules.get(имя_модуля) is модуль:
                del sys.modules[имя_модуля]
            if активный_модуль is модуль:
                активный_модуль = None
                активное_состояние = None


def проверить_контекст(модуль):
    if модуль is None or активный_модуль is not модуль or sys.modules.get(имя_модуля) is not модуль:
        raise RuntimeError("регистрация требует активный проверенный контекст зеркала")
    if (set(vars(модуль)) != set(активное_состояние)
            or any(vars(модуль)[ключ] is not значение for ключ, значение in активное_состояние.items())):
        raise RuntimeError("состояние или функции модуля зеркала подменены")
    проверить_зеркало()


def зарегистрировать(корень, описание, модуль):
    try:
        проверить_контекст(модуль)
    except (OSError, RuntimeError) as ошибка:
        return [str(ошибка)]
    корень = Path(корень)
    if корень.absolute() != корень.resolve():
        return ["корень рабочего дерева проходит через символическую ссылку"]
    корень = корень.resolve()
    выполнить_гит = getattr(модуль, "run_git")
    ошибки = getattr(модуль, "validate_spec")(описание)
    ошибки.extend(getattr(модуль, "validate_repo_root")(корень))
    if ошибки:
        return ошибки
    try:
        собственный = Path(выполнить_гит(корень, "rev-parse", "--absolute-git-dir").stdout).resolve()
        общий = Path(выполнить_гит(корень, "rev-parse", "--path-format=absolute", "--git-common-dir").stdout).resolve()
        ветка = выполнить_гит(корень, "symbolic-ref", "HEAD").stdout
        коммит = выполнить_гит(корень, "rev-parse", "HEAD").stdout
    except RuntimeError as ошибка:
        return [str(ошибка)]
    if собственный == общий or not собственный.is_relative_to(общий / "worktrees"):
        return ["регистрация разрешена только в собственном linked worktree"]
    if not ветка.startswith("refs/heads/codex/"):
        return ["регистрация требует собственную ветку refs/heads/codex/"]
    путь = getattr(описание, "path")
    if not re.fullmatch(r"[A-Za-zА-Яа-яЁё0-9_./-]+", путь) or str(Path(путь)) != путь:
        return ["путь регистрации не входит в конечный формат имени"]
    ошибки.extend(getattr(модуль, "validate_repository_topology")(корень, описание))
    ошибки.extend(getattr(модуль, "validate_gitmodules_before_add")(корень))
    цель = корень / путь
    ошибки.extend(getattr(модуль, "validate_dependency_worktree_location")(корень, цель, путь))
    if ошибки:
        return ошибки
    раздел = "submodule." + путь
    каталог_гит, ошибки = getattr(модуль, "expected_submodule_git_directory")(корень, путь, раздел)
    if ошибки or каталог_гит is None:
        return ошибки or ["не определён собственный Git-каталог зависимости"]
    метаданные = корень / ".gitmodules"
    найденный = None
    if метаданные.exists():
        try:
            записи_путей = выполнить_гит(корень, "config", "-z", "-f", ".gitmodules", "--get-regexp",
                                       r"^submodule\..*\.path$", allowed_returncodes=(0, 1), strip_output=False).stdout
        except RuntimeError as ошибка:
            return [str(ошибка)]
        if записи_путей and not записи_путей.endswith("\0"):
            return ["метаданные путей submodule имеют неверный NUL-формат"]
        совпадения = []
        for запись in записи_путей.split("\0"):
            if not запись:
                continue
            ключ, разделитель, значение = запись.partition("\n")
            if not разделитель or not ключ.endswith(".path"):
                return ["метаданные путей submodule не разобраны"]
            if значение == путь:
                совпадения.append(ключ)
        if len(совпадения) > 1:
            return ["целевой путь повторяется в метаданных submodule"]
        if совпадения:
            найденный, ошибки = getattr(модуль, "find_submodule_section")(корень, путь)
            if ошибки or найденный is None:
                return ошибки or ["не разобран единственный раздел целевого пути"]
    если_зарегистрировано = выполнить_гит(корень, "ls-files", "--stage", "--", путь).stdout
    if найденный is not None and если_зарегистрировано:
        сохранённое, ошибки = getattr(модуль, "registered_dependency_spec")(корень, путь)
        поля = ("fork_url", "upstream_url", "path", "revision")
        if ошибки or сохранённое is None:
            return ошибки or ["зарегистрированная зависимость не определена"]
        if tuple(getattr(сохранённое, п) for п in поля) != tuple(getattr(описание, п) for п in поля):
            return ["повтор не совпадает с существующей регистрацией"]
        return getattr(модуль, "validate_dependency")(корень, описание)
    if найденный is not None or если_зарегистрировано:
        return ["конфликтующая или частичная регистрация требует отдельного разбора"]
    if цель.exists() and (not цель.is_dir() or any(цель.iterdir())):
        return ["путь новой зависимости занят"]
    if каталог_гит.exists() or каталог_гит.is_symlink():
        return ["остаточный Git-каталог новой зависимости должен отсутствовать"]
    if метаданные.exists():
        ключи = выполнить_гит(корень, "config", "-z", "-f", ".gitmodules", "--name-only", "--get-regexp",
                              r"^submodule\..*\.", allowed_returncodes=(0, 1), strip_output=False).stdout
        if any(к.startswith(раздел + ".") for к in ключи.split("\0")):
            return ["имя раздела новой зависимости уже занято"]
    исходные_метаданные = метаданные.read_bytes() if метаданные.exists() else None
    исходный_индекс = (собственный / "index").read_bytes()
    конфигурация = общий / "config"
    if конфигурация.is_symlink() or not конфигурация.is_file():
        return ["общая Git-конфигурация должна быть обычным файлом"]
    исходная_конфигурация = конфигурация.read_bytes()
    исходные_записи = выполнить_гит(корень, "ls-files", "--stage", "-z", strip_output=False).stdout
    ошибки = getattr(модуль, "preflight_dependency")(описание)
    if ошибки:
        return ошибки
    try:
        проверить_контекст(модуль)
    except (OSError, RuntimeError) as ошибка:
        return [str(ошибка)]
    if ((собственный / "index").read_bytes() != исходный_индекс
            or конфигурация.read_bytes() != исходная_конфигурация
            or (метаданные.read_bytes() if метаданные.exists() else None) != исходные_метаданные
            or выполнить_гит(корень, "rev-parse", "HEAD").stdout != коммит
            or выполнить_гит(корень, "symbolic-ref", "HEAD").stdout != ветка):
        return ["исходная граница регистрации изменилась после preflight"]
    фаза = "подготовка метаданных"
    результат = []
    остальные = lambda записи: [з for з in записи.split("\0") if з and з.partition("\t")[2] not in {путь, ".gitmodules"}]
    try:
        новые = исходные_метаданные or b""
        if новые and not новые.endswith(b"\n"):
            новые += b"\n"
        значения = (("path", путь), ("url", getattr(описание, "fork_url")),
                    ("fumUpstream", getattr(описание, "upstream_url")))
        новые += ("[submodule " + json.dumps(путь, ensure_ascii=False) + "]\n").encode()
        for ключ, значение in значения:
            if any(символ in значение for символ in "\x00\n\r\t"):
                raise RuntimeError("управляющие символы в значении регистрации запрещены")
            новые += ("\t" + ключ + " = " + json.dumps(значение, ensure_ascii=False) + "\n").encode()
        дескриптор, временное_имя = tempfile.mkstemp(prefix=".fum-registration-", dir=корень)
        временный = Path(временное_имя)
        try:
            with os.fdopen(дескриптор, "wb") as поток:
                поток.write(новые)
                поток.flush()
                os.fsync(поток.fileno())
            временный.chmod(stat.S_IMODE(метаданные.stat().st_mode) if метаданные.exists() else 0o644)
            os.replace(временный, метаданные)
        finally:
            if временный.exists():
                временный.unlink()
        фаза = "установка точных записей индекса"
        выполнить_гит(корень, "add", "--", ".gitmodules")
        выполнить_гит(корень, "update-index", "--add", "--cacheinfo",
                      "160000," + getattr(описание, "revision") + "," + путь)
        фаза = "защищённая инициализация"
        _, ошибки = getattr(модуль, "initialize_registered_dependency")(корень, путь)
        if ошибки:
            результат.extend("незавершённая фаза " + фаза + ": " + ошибка for ошибка in ошибки)
        else:
            результат.extend(getattr(модуль, "validate_dependency")(корень, описание))
    except (OSError, RuntimeError) as ошибка:
        результат.append("незавершённая фаза " + фаза + ": " + str(ошибка))
    finally:
        try:
            конечные = выполнить_гит(корень, "ls-files", "--stage", "-z", strip_output=False).stdout
            if остальные(исходные_записи) != остальные(конечные):
                результат.append("посторонние записи индекса изменились при регистрации")
        except (OSError, RuntimeError) as ошибка:
            результат.append("не удалось сверить индекс после фазы " + фаза + ": " + str(ошибка))
        try:
            if конфигурация.read_bytes() != исходная_конфигурация:
                результат.append("общая Git-конфигурация изменилась при регистрации")
        except OSError as ошибка:
            результат.append("не удалось сверить конфигурацию после фазы " + фаза + ": " + str(ошибка))
    return результат
