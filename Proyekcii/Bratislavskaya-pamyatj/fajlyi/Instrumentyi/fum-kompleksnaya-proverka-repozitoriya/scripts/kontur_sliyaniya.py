"""Сверить неизменный источник приёмки слияния без изменения Git и файлов."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
from pathlib import Path


ПОЛИТИКА = Path("Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy-кандидата-слияния.json")
ПРОИСХОЖДЕНИЕ_ПОЛИТИКИ = ПОЛИТИКА.with_name("происхождение-политики-слияния.json")
АРХИВИРУЕМАЯ_ОБЁРТКА = "Инструменты/fum-proverka-nazvanij-avtomatizacij"
ЗАВИСИМОСТЬ = "Зависимости/LinguisticKit"
ИСТОЧНИКИ = ("Инструменты", "Правила", "AGENTS.md", ".codex/config.toml", ".gitmodules")
ВЛОЖЕННЫЕ_ИНСТРУМЕНТЫ = ("Инструменты/fum-svezhestj-markdown", "Инструменты/fum-proyektnyiye-fajlyi")
ПОЛНЫЙ_OID = re.compile(r"(?:[0-9a-f]{40}|[0-9a-f]{64})\Z")
СКРИПТ_SMOKE = Path("Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py")


def окружение_контура() -> dict[str, str]:
    среда = {ключ: значение for ключ, значение in os.environ.items()
             if not ключ.startswith(("GIT_", "PYTHON"))}
    среда.update(GIT_NO_REPLACE_OBJECTS="1", GIT_NO_LAZY_FETCH="1", GIT_OPTIONAL_LOCKS="0",
                 PYTHONDONTWRITEBYTECODE="1")
    return среда


def канонические_байты(значение: dict) -> bytes:
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode("utf-8")


def путь_свидетельства(запрос: str) -> str:
    путь = Path(запрос)
    if (путь.is_absolute() or len(путь.parts) != 3 or путь.parts[0] != "Журнал" or путь.name != "запрос.md"
            or путь.as_posix() != запрос
            or re.fullmatch(r"\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_MSK(?:_[0-9A-Za-zА-Яа-яЁё-]+)?", путь.parent.name) is None):
        raise ValueError("нужен канонический путь запроса в Журнале")
    return (путь.parent / "материалы/контур-слияния.json").as_posix()


def параметры_полного_запуска(
    источник: Path, кандидат: Path, команда: list[str] | tuple[str, ...], запрос: str | None = None,
) -> tuple[str, str, str]:
    """Узкая явная форма вызова не допускает старого неявного распознавания."""
    if not команда or not Path(команда[0]).is_absolute() or Path(команда[0]).resolve() != Path(sys.executable).resolve():
        raise ValueError("полный контур требует текущий интерпретатор по абсолютному пути")
    индекс = 1
    while индекс < len(команда) and команда[индекс] in ("-B", "-E", "-I"):
        индекс += 1
    if индекс >= len(команда) or команда[индекс] != str(источник / СКРИПТ_SMOKE):
        raise ValueError("полный контур требует точный smoke из master")
    хвост = команда[индекс + 1:]
    if len(хвост) % 2:
        raise ValueError("неполный или сокращённый вызов контура слияния")
    значения = {}
    обязательные = {"--repo-root", "--request", "--commit-message-file", "--codex-thread-id",
                    "--источник-проверок", "--ведущая-основа", "--свидетельство-контура"}
    for ключ, значение in zip(хвост[::2], хвост[1::2]):
        if ключ not in обязательные | {"--профиль"} or ключ in значения:
            raise ValueError("неизвестный или повторный параметр контура слияния")
        значения[ключ] = значение
    if not обязательные <= значения.keys() or значения.get("--профиль", "документационный") != "документационный":
        raise ValueError("контур слияния требует полный документационный план")
    if значения["--repo-root"] != str(кандидат):
        raise ValueError("команда указывает другой корень кандидата")
    if запрос is not None and значения["--request"] != запрос:
        raise ValueError("команда указывает другой запрос")
    ожидаемое_свидетельство = путь_свидетельства(значения["--request"])
    if значения["--свидетельство-контура"] != ожидаемое_свидетельство:
        raise ValueError("нужен фиксированный путь происхождения в текущем Журнале")
    for ключ in ("--источник-проверок", "--ведущая-основа"):
        if ПОЛНЫЙ_OID.fullmatch(значения[ключ]) is None:
            raise ValueError("контур слияния требует полные OID")
    if not Path(значения["--commit-message-file"]).is_absolute():
        raise ValueError("нужен абсолютный путь текста коммита")
    if re.fullmatch(r"[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}", значения["--codex-thread-id"]) is None:
        raise ValueError("нужен точный UUID задачи")
    return значения["--источник-проверок"], значения["--ведущая-основа"], ожидаемое_свидетельство


def проверить_свидетельство(кандидат: Path, относительный: str, ожидаемое: dict) -> None:
    байты = канонические_байты(ожидаемое)
    if обычный_путь(кандидат, относительный).read_bytes() != байты:
        raise ValueError("свидетельство контура не совпадает с текущим источником и UUID запуска")
    индекс = прочитать_git(кандидат, "ls-files", "--stage", "-z", "--", относительный)
    if re.fullmatch(rb"100644 (?:[0-9a-f]{40}|[0-9a-f]{64}) 0\t" + re.escape(относительный.encode()) + rb"\x00", индекс) is None:
        raise ValueError("свидетельство контура требует единственную запись stage 0 режима 100644")
    if прочитать_git(кандидат, "show", ":" + относительный) != байты:
        raise ValueError("свидетельство контура должно быть индексировано до полного запуска")


def проверить_запуск(источник: Path, кандидат: Path, команда, запрос: str, идентификатор: str) -> dict:
    коммит, ведущая, свидетельство = параметры_полного_запуска(источник, кандидат, команда, запрос)
    if re.fullmatch(r"[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}", идентификатор) is None:
        raise ValueError("полная проверка слияния требует UUID отчётного запуска")
    ожидаемое = проверить_контур(источник, коммит, кандидат, ведущая) | {
        "запрос": запрос, "идентификатор_запуска": идентификатор,
    }
    проверить_свидетельство(кандидат, свидетельство, ожидаемое)
    return ожидаемое


def прочитать_git(корень: Path, *аргументы: str) -> bytes:
    процесс = subprocess.run(
        ["git", "--no-optional-locks", "-c", "core.fsmonitor=false", "-C", str(корень), *аргументы],
        env=окружение_контура(), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if процесс.returncode:
        raise ValueError("не удалось прочитать границу Git проверяющего контура")
    return процесс.stdout


def строка_git(корень: Path, *аргументы: str) -> str:
    return прочитать_git(корень, *аргументы).decode("utf-8").strip()


def обычный_путь(корень: Path, относительный: str) -> Path:
    части = Path(относительный).parts
    if not части or Path(относительный).is_absolute() or any(часть in (".", "..") for часть in части):
        raise ValueError("неканонический путь проверяющего контура")
    текущий = корень
    for часть in части:
        текущий = текущий / часть
        if текущий.is_symlink():
            raise ValueError("символическая ссылка в проверяющем контуре")
    if not текущий.is_file():
        raise ValueError("нет обычного файла проверяющего контура")
    return текущий


def известный_локальный_кэш(путь: Path) -> bool:
    return (путь.name == ".DS_Store"
            or ("__pycache__" in путь.parts and путь.suffix == ".pyc")
            or (Path(АРХИВИРУЕМАЯ_ОБЁРТКА) / ".build") in путь.parents)


def проверить_инвентарь_реализации(корень: Path) -> None:
    """Предлагаемый код может отличаться, но каждый его источник входит в индекс."""
    for имя in прочитать_git(корень, "ls-files", "--others", "-z", "--", "Инструменты").split(b"\0"):
        if имя and not известный_локальный_кэш(Path(os.fsdecode(имя))):
            raise ValueError("источник реализации кандидата отсутствует в индексе: " + os.fsdecode(имя))
    for запись in прочитать_git(корень, "ls-files", "--stage", "-z", "--", "Инструменты").split(b"\0"):
        if not запись:
            continue
        заголовок, имя = запись.split(b"\t", 1)
        режим, oid, стадия = заголовок.split()
        if режим not in (b"100644", b"100755") or стадия != b"0":
            raise ValueError("источник реализации кандидата имеет необычный режим или стадию")
        обычный_путь(корень, os.fsdecode(имя))


def проверить_байты_источника(корень: Path, коммит: str, области: tuple[str, ...]) -> None:
    """Сравнивать сырые байты с blob OID, независимо от stat-кэша, фильтров и индекса."""
    алгоритм = строка_git(корень, "rev-parse", "--show-object-format")
    if алгоритм not in ("sha1", "sha256"):
        raise ValueError("неизвестный формат объектов проверяющего контура")
    дерево = прочитать_git(корень, "ls-tree", "-rz", "--full-tree", коммит, "--", *области)
    if not дерево:
        raise ValueError("пустой источник проверяющего контура")
    ожидаемые_пути = set()
    for запись in дерево.split(b"\0"):
        if not запись:
            continue
        заголовок, имя = запись.split(b"\t", 1)
        ожидаемые_пути.add(имя)
        режим, тип, ожидаемый = заголовок.decode("ascii").split()
        if тип != "blob" or режим not in ("100644", "100755"):
            raise ValueError("необычный объект в источнике проверяющего контура")
        путь = обычный_путь(корень, os.fsdecode(имя))
        байты = путь.read_bytes()
        хэш = hashlib.new(алгоритм, b"blob " + str(len(байты)).encode("ascii") + b"\0" + байты).hexdigest()
        исполняемый = bool(путь.stat().st_mode & stat.S_IXUSR)
        if хэш != ожидаемый or исполняемый != (режим == "100755"):
            raise ValueError("байты или режим источника проверяющего контура изменены: " + os.fsdecode(имя))
    # Игнорирование Git не должно позволять добавить импортируемый исходник.
    фактические_пути = set(прочитать_git(корень, "ls-files", "--cached", "--others", "-z", "--", *области).split(b"\0")) - {b""}
    if ожидаемые_пути - фактические_пути:
        raise ValueError("файл проверяющего контура исчез из инвентаря")
    for имя in фактические_пути - ожидаемые_пути:
        if not имя:
            continue
        путь = Path(os.fsdecode(имя))
        if известный_локальный_кэш(путь):
            # Этот пакет исполняется из Git-архива в отдельном временном каталоге.
            continue
        raise ValueError("лишний файл в источнике проверяющего контура: " + путь.as_posix())


def проверить_контур(источник: Path, коммит: str, кандидат: Path, ведущая: str) -> dict[str, str]:
    """Приёмочный источник — первичный master; кандидат остаётся на предкоммитном L."""
    for oid in (коммит, ведущая):
        if not isinstance(oid, str) or ПОЛНЫЙ_OID.fullmatch(oid) is None:
            raise ValueError("контур слияния требует полные OID")
    источник = Path(источник).absolute()
    кандидат = Path(кандидат).absolute()
    if источник.resolve(strict=True) != источник or кандидат.resolve(strict=True) != кандидат or источник == кандидат:
        raise ValueError("нужны разные физические корни источника и кандидата")
    for корень in (источник, кандидат):
        if Path(строка_git(корень, "rev-parse", "--show-toplevel")) != корень:
            raise ValueError("нужен точный корень рабочего дерева")
        if строка_git(корень, "rev-parse", "--is-shallow-repository") != "false":
            raise ValueError("неполная история проверяющего контура")
        grafts = Path(строка_git(корень, "rev-parse", "--path-format=absolute", "--git-path", "info/grafts"))
        if os.path.lexists(grafts):
            raise ValueError("подмена истории через grafts")
    общий = строка_git(источник, "rev-parse", "--path-format=absolute", "--git-common-dir")
    if (строка_git(источник, "rev-parse", "--absolute-git-dir") != общий
            or строка_git(кандидат, "rev-parse", "--path-format=absolute", "--git-common-dir") != общий
            or строка_git(источник, "symbolic-ref", "HEAD") != "refs/heads/master"
            or строка_git(источник, "rev-parse", "HEAD") != коммит
            or строка_git(источник, "rev-parse", "refs/heads/master") != коммит):
        raise ValueError("источник проверок не является закреплённым первичным master")
    if строка_git(кандидат, "rev-parse", "HEAD") != ведущая:
        raise ValueError("сдвинулась ведущая основа кандидата")
    merge_head = Path(строка_git(кандидат, "rev-parse", "--path-format=absolute", "--git-path", "MERGE_HEAD"))
    if merge_head.is_symlink() or merge_head.read_text().strip() != коммит:
        raise ValueError("кандидат не готовит слияние с закреплённым master")
    проверить_байты_источника(источник, коммит, ИСТОЧНИКИ)
    проверить_инвентарь_реализации(кандидат)
    проверить_байты_источника(кандидат, коммит, (*ВЛОЖЕННЫЕ_ИНСТРУМЕНТЫ, АРХИВИРУЕМАЯ_ОБЁРТКА))
    обёртка = строка_git(источник, "rev-parse", коммит + ":" + АРХИВИРУЕМАЯ_ОБЁРТКА)
    if строка_git(кандидат, "rev-parse", ведущая + ":" + АРХИВИРУЕМАЯ_ОБЁРТКА) != обёртка:
        raise ValueError("архивируемая обёртка кандидата отличается от master")
    запись_зависимости = прочитать_git(источник, "ls-tree", "-z", коммит, "--", ЗАВИСИМОСТЬ)
    совпадение = re.fullmatch(rb"160000 commit ([0-9a-f]{40}|[0-9a-f]{64})\t" + re.escape(ЗАВИСИМОСТЬ.encode()) + rb"\x00", запись_зависимости)
    if совпадение is None:
        raise ValueError("зависимость должна иметь точный режим gitlink 160000 и тип commit")
    зависимость = совпадение[1].decode("ascii")
    for корень in (источник, кандидат):
        путь = корень / ЗАВИСИМОСТЬ
        текущий = корень
        for часть in Path(ЗАВИСИМОСТЬ).parts:
            текущий = текущий / часть
            if текущий.is_symlink() or not текущий.is_dir():
                raise ValueError("символическая ссылка или необычный каталог зависимости")
        if (Path(строка_git(путь, "rev-parse", "--show-toplevel")) != путь
                or строка_git(путь, "rev-parse", "HEAD") != зависимость
                or строка_git(путь, "cat-file", "-t", зависимость) != "commit"):
            raise ValueError("иная материализация зависимости проверяющего контура")
        проверить_байты_источника(путь, зависимость, (".",))
    политика = обычный_путь(источник, ПОЛИТИКА.as_posix()).read_bytes()
    происхождение = json.loads(обычный_путь(источник, ПРОИСХОЖДЕНИЕ_ПОЛИТИКИ.as_posix()).read_bytes())
    хэш_политики = "sha256:" + hashlib.sha256(политика).hexdigest()
    if (происхождение.get("схема") != "fum.политика-слияния.1"
            or происхождение.get("ведущая_основа") != ведущая
            or происхождение.get("дерево_основы") != строка_git(кандидат, "rev-parse", ведущая + "^{tree}")
            or происхождение.get("путь_политики") != ПОЛИТИКА.as_posix()
            or происхождение.get("хэш_политики") != хэш_политики
            or происхождение.get("принятие_слияния") is not False):
        raise ValueError("не подтверждено происхождение политики слияния")
    return {"схема": "fum.контур-проверки-слияния.1", "источник": коммит,
            "дерево_источника": строка_git(источник, "rev-parse", коммит + "^{tree}"),
            "ведущая_основа": ведущая, "архивируемая_обёртка": обёртка,
            "зависимость": зависимость, "политика": хэш_политики}


def главная() -> int:
    разбор = argparse.ArgumentParser(description="Подготовить происхождение полного запуска в stdout без изменения файлов и Git.", allow_abbrev=False)
    разбор.add_argument("--корень-кандидата", type=Path, required=True)
    разбор.add_argument("--источник", required=True)
    разбор.add_argument("--ведущая-основа", required=True)
    разбор.add_argument("--запрос", required=True)
    разбор.add_argument("--идентификатор-запуска", required=True)
    параметры = разбор.parse_args()
    try:
        путь_свидетельства(параметры.запрос)
        if re.fullmatch(r"[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}", параметры.идентификатор_запуска) is None:
            raise ValueError("нужен канонический UUID запуска")
        кандидат = параметры.корень_кандидата.absolute()
        обычный_путь(кандидат, параметры.запрос)
        значение = проверить_контур(Path(__file__).resolve().parents[3], параметры.источник, кандидат, параметры.ведущая_основа)
        значение.update(запрос=параметры.запрос, идентификатор_запуска=параметры.идентификатор_запуска)
        sys.stdout.buffer.write(канонические_байты(значение))
        return 0
    except (OSError, ValueError) as ошибка:
        print("Ошибка: " + str(ошибка), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(главная())
