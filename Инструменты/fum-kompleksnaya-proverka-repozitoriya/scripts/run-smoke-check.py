#!/usr/bin/env python3
"""Run the local FUM repository smoke-check without network dependencies."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import posixpath
import re
import shlex
import subprocess
import sys
import time
import tomllib
import unicodedata as данные_юникода
import uuid as уникальные_идентификаторы
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path, PurePosixPath


PLANNING_REGISTRY_SCRIPT = Path(
    "Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py"
)
PLANNING_REGISTRY_OUTPUT = Path(
    "Планирование/реестр-требований-вариантов-и-кандидатов.json"
)
PROTOTYPE_LAUNCH_CHECK_SCRIPT = Path(
    "Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py"
)
QUESTION_BACKLINKS_SCRIPT = Path(
    "Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py"
)
README_INDEX_CHECK_SCRIPT = Path(
    "Инструменты/fum-indeks-readme/scripts/check-readme-index.py"
)
AUTOMATION_NAMES_CHECK_SCRIPT = Path(
    "Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/"
    "proveritj-nazvaniya-avtomatizacij.py"
)
AUTOMATION_NAMES_REGISTRY = Path(
    "Инструменты/реестр-названий-автоматизаций.json"
)
MACHINE_LOCAL_PATH_CHECK_SCRIPT = Path(
    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/"
    "proveritj-mashinno-lokaljnyiye-puti.py"
)
СКРИПТ_ПРОВЕРКИ_ПЕРЕВОДА_ОБЪЯВЛЕНИЙ_КОДА = Path(
    "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/"
    "перевести-объявления-кода.py"
)
СНИМОК_ОСТАТКА_ОБЪЯВЛЕНИЙ_КОДА = Path(
    "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/"
    "остаток-объявлений-кода.json"
)
REQUEST_FOLDER_LAYOUT_SCRIPT = Path(
    "Инструменты/fum-struktura-papok-zaprosov/scripts/"
    "struktura-papok-zaprosov.py"
)
GIT_DEPENDENCY_CHECK_SCRIPT = Path(
    "Инструменты/fum-proverka-git-zavisimostej/scripts/"
    "proveritj-git-zavisimostj.py"
)
LINGUISTIC_KIT_FORK_URL = "https://github.com/fum-lab/LinguisticKit.git"
LINGUISTIC_KIT_UPSTREAM_URL = (
    "https://github.com/Roman-Kerimov/LinguisticKit.git"
)
LINGUISTIC_KIT_PATH = "Зависимости/LinguisticKit"
LINGUISTIC_KIT_REVISION = "837e2ce107b97ee7b9d3344c9fe99142281fe393"
CODEX_COMMIT_CONTEXT_RULE_START = (2026, 7, 14, 2, 31, 47)
REQUEST_SESSION_STEM_RE = re.compile(
    r"^(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})_MSK"
    r"(?:_[0-9A-Za-zА-Яа-яЁё][0-9A-Za-zА-Яа-яЁё-]*)?$"
)
RECENCY_SCRIPT = Path("Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py")
OBSIDIAN_GRAPH_RECENCY_SCRIPT = Path(
    "Инструменты/fum-svezhestj-grafa-obsidian/scripts/build-obsidian-graph-recency.py"
)
SESSION_COHERENCE_SCRIPT = Path(
    "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py"
)
SWIFT_PACKAGE_POLICY = Path(
    "Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json"
)
SWIFT_FORMAT_CONFIG = Path(
    "Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-format.json"
)
CODEX_PROJECT_CONFIG = Path(".codex/config.toml")
SHA256_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
WINDOWS_ABSOLUTE_PATH_RE = re.compile(r"^[A-Za-z]:[\\/]")
СХЕМА_СНИМКА_ЗАПУСКОВ = "fum.test-run-report.v1"
СХЕМА_СНИМКА_ЗАПУСКОВ_С_ВЕРДИКТОМ = "fum.test-run-report.v2"
СХЕМА_ЗАПУСКА_С_НАБЛЮДЕНИЯМИ = "fum.test-run.v2"
СХЕМА_ПРОФИЛИРОВАННОГО_ЗАПУСКА = "fum.test-run.v3"
СХЕМА_ЗАПУСКА_БЕЗ_НАБЛЮДЕНИЙ = "fum.test-run.v1"
СХЕМА_КОНВЕРТА_НАБЛЮДЕНИЙ = "fum.smoke-test-observations.v1"
ПЕРЕМЕННАЯ_ПУТИ_НАБЛЮДЕНИЙ = "FUM_CHECK_RUN_OBSERVATIONS_PATH"
ПЕРЕМЕННАЯ_ИДЕНТИФИКАТОРА_ЗАПУСКА = "FUM_CHECK_RUN_ID"
СТАТУСЫ_НАБЛЮДЕНИЙ = frozenset(
    {"успешно", "неуспешно", "прервано", "не завершено"}
)
ЗАКРЫТЫЙ_МАРКЕР_ЗАПУСКОВ = re.compile(
    r"^<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; "
    r"снимок=материалы/запуски-проверок/снимок\.json; "
    r"sha256=sha256:(?P<хэш>[0-9a-f]{64}) -->$",
    re.MULTILINE,
)
ПУТЬ_ПРОВЕРКИ_ЖУРНАЛА_ЗАПУСКОВ = (
    Path(__file__).resolve().parents[2]
    / "fum-otchyotyi-o-zapuskakh-proverok"
    / "scripts"
    / "отчёты_о_запусках_проверок.py"
)
_модуль_проверки_журнала: object | None = None
SWIFT_OFFLINE_FLAGS = (
    "--disable-dependency-cache",
    "--manifest-cache",
    "none",
    "--disable-prefetching",
    "--disable-netrc",
    "--disable-keychain",
    "--disable-automatic-resolution",
)
Clock = Callable[[], float]
TimingRecord = dict[str, object]
TimingSink = Callable[[TimingRecord], None]


@dataclass(frozen=True)
class SmokeStep:
    name: str
    command: tuple[str, ...] | None
    detail: str | None = None
    аналитический_ключ: str | None = None
    ранняя_проверка: bool = False

    def __post_init__(self) -> None:
        if (self.command is None) == (self.detail is None):
            raise ValueError("smoke step must define exactly one of command or detail")
        if self.аналитический_ключ is not None:
            if self.command is None or not self.аналитический_ключ:
                raise ValueError(
                    "analytical smoke key requires a command and must not be empty"
                )
        if self.ранняя_проверка and self.аналитический_ключ is not None:
            raise ValueError(
                "ранняя smoke-проверка не может быть аналитическим тестовым шагом"
            )


@dataclass(frozen=True)
class СтатистикаТеста:
    успешные: int
    неуспешные: int
    цензурированные: int
    суммарная_длительность_наносекунды: int

    def __post_init__(сам) -> None:
        if any(
            isinstance(значение, bool)
            or not isinstance(значение, int)
            or значение < 0
            for значение in (
                сам.успешные,
                сам.неуспешные,
                сам.цензурированные,
                сам.суммарная_длительность_наносекунды,
            )
        ):
            raise ValueError("test statistics values must be non-negative integers")

    @property
    def завершённые(сам) -> int:
        return сам.успешные + сам.неуспешные

    @property
    def вероятность_успеха(сам) -> Fraction:
        if сам.завершённые == 0:
            raise ValueError("success probability requires completed observations")
        return Fraction(сам.успешные, сам.завершённые)

    @property
    def средняя_длительность_наносекунды(сам) -> Fraction:
        if сам.завершённые == 0:
            raise ValueError("mean duration requires completed observations")
        return Fraction(
            сам.суммарная_длительность_наносекунды,
            сам.завершённые,
        )


def собрать_статистику_наблюдений(
    наблюдения: Iterable[dict[str, object]],
) -> dict[str, СтатистикаТеста]:
    накопители: dict[str, list[int]] = {}
    for наблюдение in наблюдения:
        ключ = наблюдение.get("ключ_проверки")
        статус = наблюдение.get("статус")
        длительность = наблюдение.get("длительность_наносекунды")
        if not isinstance(ключ, str) or not ключ:
            raise ValueError("smoke observation has an invalid test key")
        if статус not in СТАТУСЫ_НАБЛЮДЕНИЙ:
            raise ValueError(f"smoke observation has an invalid status: {ключ}")
        if (
            isinstance(длительность, bool)
            or not isinstance(длительность, int)
            or длительность < 0
        ):
            raise ValueError(f"smoke observation has an invalid duration: {ключ}")
        накопитель = накопители.setdefault(ключ, [0, 0, 0, 0])
        if статус == "успешно":
            накопитель[0] += 1
            накопитель[3] += длительность
        elif статус in {"неуспешно", "не завершено"}:
            накопитель[1] += 1
            накопитель[3] += длительность
        else:
            накопитель[2] += 1
    return {
        ключ: СтатистикаТеста(*значения)
        for ключ, значения in накопители.items()
    }


def упорядочить_тестовые_шаги(
    шаги: list[SmokeStep],
    статистика: dict[str, СтатистикаТеста],
) -> list[SmokeStep]:
    ранние_проверки: list[SmokeStep] = []
    тестовые: list[SmokeStep] = []
    фиксированные: list[SmokeStep] = []
    ключи: set[str] = set()
    for шаг in шаги:
        if шаг.ранняя_проверка:
            ранние_проверки.append(шаг)
            continue
        ключ = шаг.аналитический_ключ
        if ключ is None:
            фиксированные.append(шаг)
            continue
        if ключ in ключи:
            raise ValueError(f"duplicate analytical smoke key: {ключ}")
        ключи.add(ключ)
        тестовые.append(шаг)

    def ключ_порядка(шаг: SmokeStep) -> tuple[object, ...]:
        ключ = шаг.аналитический_ключ
        assert ключ is not None
        данные = статистика.get(ключ)
        if данные is None or данные.завершённые == 0:
            return (1, ключ)
        if данные.неуспешные == 0:
            return (
                2,
                данные.средняя_длительность_наносекунды,
                ключ,
            )
        return (
            0,
            данные.вероятность_успеха,
            данные.средняя_длительность_наносекунды,
            ключ,
        )

    return (
        ранние_проверки
        + sorted(тестовые, key=ключ_порядка)
        + фиксированные
    )


def канонические_машинные_байты(значение: object) -> bytes:
    return (
        json.dumps(
            значение,
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    ).encode("utf-8")


def прочитать_каноническую_машинную_запись(путь: Path, назначение: str) -> tuple[object, bytes]:
    if путь.is_symlink() or not путь.is_file():
        raise ValueError(f"{назначение} is not a regular file: {путь}")
    try:
        байты = путь.read_bytes()
        значение = json.loads(байты.decode("utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as ошибка:
        raise ValueError(f"cannot read {назначение}: {путь}: {ошибка}") from ошибка
    if байты != канонические_машинные_байты(значение):
        raise ValueError(f"{назначение} is not canonical JSON: {путь}")
    return значение, байты


def проверить_наблюдение_истории(
    значение: object,
    источник: Path,
) -> dict[str, object]:
    поля = {
        "ключ_проверки",
        "название",
        "статус",
        "длительность_наносекунды",
    }
    if not isinstance(значение, dict) or set(значение) != поля:
        raise ValueError(f"invalid smoke observation fields: {источник}")
    for поле in ("ключ_проверки", "название"):
        if not isinstance(значение[поле], str) or not значение[поле]:
            raise ValueError(f"invalid smoke observation {поле}: {источник}")
    проверить_аналитический_ключ(str(значение["ключ_проверки"]))
    if значение["статус"] not in СТАТУСЫ_НАБЛЮДЕНИЙ:
        raise ValueError(f"invalid smoke observation status: {источник}")
    длительность = значение["длительность_наносекунды"]
    if (
        isinstance(длительность, bool)
        or not isinstance(длительность, int)
        or длительность < 0
    ):
        raise ValueError(f"invalid smoke observation duration: {источник}")
    return значение


def проверить_целостность_закрытой_сессии(
    корень: Path,
    каталог_сессии: Path,
) -> None:
    global _модуль_проверки_журнала
    if _модуль_проверки_журнала is None:
        спецификация = importlib.util.spec_from_file_location(
            "fum_проверка_журнала_запусков_для_smoke",
            ПУТЬ_ПРОВЕРКИ_ЖУРНАЛА_ЗАПУСКОВ,
        )
        if спецификация is None or спецификация.loader is None:
            raise ValueError("cannot load the test-run report validator")
        модуль = importlib.util.module_from_spec(спецификация)
        спецификация.loader.exec_module(модуль)
        _модуль_проверки_журнала = модуль
    проверка = getattr(
        _модуль_проверки_журнала,
        "проверить_журнал_сессии",
        None,
    )
    if not callable(проверка):
        raise ValueError("test-run report validator has no session entry point")
    запрос = каталог_сессии / "запрос.md"
    ошибки = проверка(корень, запрос)
    if ошибки:
        raise ValueError(
            "closed test-run session failed integrity validation: "
            + "; ".join(str(ошибка) for ошибка in ошибки)
        )


def прочитать_наблюдения_закрытого_снимка(
    корень: Path,
    путь_снимка: Path,
) -> list[dict[str, object]]:
    каталог_сессии = путь_снимка.parents[2]
    путь_отчёта = каталог_сессии / "отчёт.md"
    if путь_отчёта.is_symlink() or not путь_отчёта.is_file():
        raise ValueError(f"test-run snapshot has no session report: {путь_снимка}")
    try:
        текст_отчёта = путь_отчёта.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as ошибка:
        raise ValueError(f"cannot read closed session report: {путь_отчёта}") from ошибка
    маркеры = list(ЗАКРЫТЫЙ_МАРКЕР_ЗАПУСКОВ.finditer(текст_отчёта))
    if not маркеры:
        raise ValueError(
            f"test-run snapshot is not in a closed session: {путь_снимка}"
        )
    if len(маркеры) != 1:
        raise ValueError(f"multiple closed test-run markers: {путь_отчёта}")
    проверить_целостность_закрытой_сессии(корень, каталог_сессии)

    снимок, байты_снимка = прочитать_каноническую_машинную_запись(
        путь_снимка,
        "closed test-run snapshot",
    )
    if hashlib.sha256(байты_снимка).hexdigest() != маркеры[0].group("хэш"):
        raise ValueError(f"closed test-run snapshot hash mismatch: {путь_снимка}")
    if not isinstance(снимок, dict):
        raise ValueError(f"invalid closed test-run snapshot fields: {путь_снимка}")
    схема_снимка = снимок.get("схема")
    if схема_снимка == СХЕМА_СНИМКА_ЗАПУСКОВ:
        ожидаемые_поля_снимка = {"схема", "сессия", "файлы"}
    elif схема_снимка == СХЕМА_СНИМКА_ЗАПУСКОВ_С_ВЕРДИКТОМ:
        ожидаемые_поля_снимка = {
            "схема",
            "сессия",
            "файлы",
            "отпечаток_закрытия",
        }
        отпечаток_закрытия = снимок.get("отпечаток_закрытия")
        if not isinstance(отпечаток_закрытия, str) or SHA256_RE.fullmatch(
            отпечаток_закрытия
        ) is None:
            raise ValueError(
                f"invalid closed test-run snapshot fingerprint: {путь_снимка}"
            )
    else:
        raise ValueError(f"invalid closed test-run snapshot schema: {путь_снимка}")
    if set(снимок) != ожидаемые_поля_снимка:
        raise ValueError(f"invalid closed test-run snapshot fields: {путь_снимка}")
    ожидаемая_сессия = (
        каталог_сессии.relative_to(корень) / "запрос.md"
    ).as_posix()
    if снимок["сессия"] != ожидаемая_сессия:
        raise ValueError(f"closed test-run snapshot belongs to another session: {путь_снимка}")
    файлы = снимок["файлы"]
    if not isinstance(файлы, list):
        raise ValueError(f"invalid closed test-run snapshot file list: {путь_снимка}")

    результат: list[dict[str, object]] = []
    имена: set[str] = set()
    for описание in файлы:
        if not isinstance(описание, dict) or set(описание) != {"имя", "sha256"}:
            raise ValueError(f"invalid closed test-run snapshot entry: {путь_снимка}")
        имя = описание["имя"]
        ожидаемый_хэш = описание["sha256"]
        if (
            not isinstance(имя, str)
            or Path(имя).name != имя
            or not имя.endswith(".json")
            or имя in имена
        ):
            raise ValueError(f"invalid test-run record name in snapshot: {путь_снимка}")
        if (
            not isinstance(ожидаемый_хэш, str)
            or re.fullmatch(r"[0-9a-f]{64}", ожидаемый_хэш) is None
        ):
            raise ValueError(f"invalid test-run record hash in snapshot: {путь_снимка}")
        имена.add(имя)
        путь_записи = путь_снимка.parent / имя
        запись, байты_записи = прочитать_каноническую_машинную_запись(
            путь_записи,
            "snapshotted test-run record",
        )
        if hashlib.sha256(байты_записи).hexdigest() != ожидаемый_хэш:
            raise ValueError(f"snapshotted test-run record hash mismatch: {путь_записи}")
        if not isinstance(запись, dict):
            raise ValueError(f"invalid snapshotted test-run record: {путь_записи}")
        схема = запись.get("схема")
        if схема == СХЕМА_ЗАПУСКА_БЕЗ_НАБЛЮДЕНИЙ:
            continue
        if схема not in {
            СХЕМА_ЗАПУСКА_С_НАБЛЮДЕНИЯМИ,
            СХЕМА_ПРОФИЛИРОВАННОГО_ЗАПУСКА,
        }:
            raise ValueError(f"unknown snapshotted test-run schema: {путь_записи}")
        if запись.get("состояние") != "завершён":
            raise ValueError(f"unfinished observed test-run record in snapshot: {путь_записи}")
        наблюдения = запись.get("наблюдения")
        if not isinstance(наблюдения, list):
            raise ValueError(f"invalid smoke observations: {путь_записи}")
        ключи: set[str] = set()
        for наблюдение in наблюдения:
            проверенное = проверить_наблюдение_истории(
                наблюдение,
                путь_записи,
            )
            ключ = str(проверенное["ключ_проверки"])
            if ключ in ключи:
                raise ValueError(
                    f"duplicate smoke observation key in one run: {путь_записи}"
                )
            ключи.add(ключ)
            результат.append(проверенное)
    return результат


def загрузить_статистику_закрытых_запусков(
    корень: Path,
) -> dict[str, СтатистикаТеста]:
    наблюдения: list[dict[str, object]] = []
    журнал = корень / "Журнал"
    if not журнал.is_dir():
        return {}
    журналы_возобновления = sorted(
        журнал.glob("*/материалы/запуски-проверок/возобновление.json"),
        key=lambda путь: путь.as_posix(),
    )
    if журналы_возобновления:
        raise ValueError(
            "test-run history contains an unfinished recovery journal: "
            f"{журналы_возобновления[0]}"
        )
    снимки = set(
        журнал.glob("*/материалы/запуски-проверок/снимок.json")
    )
    for путь_отчёта in sorted(
        журнал.glob("*/отчёт.md"),
        key=lambda путь: путь.as_posix(),
    ):
        try:
            текст = путь_отчёта.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as ошибка:
            raise ValueError(f"cannot read test-run report: {путь_отчёта}") from ошибка
        if "FUM-CHECK-RUNS:BEGIN состояние=закрыт;" not in текст:
            continue
        путь_снимка = (
            путь_отчёта.parent
            / "материалы"
            / "запуски-проверок"
            / "снимок.json"
        )
        if not путь_снимка.is_file() or путь_снимка.is_symlink():
            raise ValueError(
                f"closed test-run report has no regular snapshot: {путь_отчёта}"
            )
        снимки.add(путь_снимка)
    for путь_снимка in sorted(снимки, key=lambda путь: путь.as_posix()):
        наблюдения.extend(
            прочитать_наблюдения_закрытого_снимка(корень, путь_снимка)
        )
    return собрать_статистику_наблюдений(наблюдения)


def проверить_аналитический_ключ(ключ: str) -> str:
    путь = PurePosixPath(ключ)
    if (
        not ключ
        or ключ != данные_юникода.normalize("NFC", ключ)
        or "\\" in ключ
        or путь.is_absolute()
        or путь.as_posix() != ключ
        or any(часть in {"", ".", ".."} for часть in путь.parts)
    ):
        raise ValueError(f"invalid canonical analytical smoke key: {ключ!r}")
    return ключ


class СборщикНаблюдений:
    def __init__(
        сам,
        путь: Path,
        идентификатор_запуска: str,
    ) -> None:
        сам.путь = путь
        сам.идентификатор_запуска = идентификатор_запуска
        сам.план: list[dict[str, str]] | None = None
        сам.наблюдения: list[dict[str, object]] = []
        сам.текущая_проверка: dict[str, object] | None = None
        значение, _ = прочитать_каноническую_машинную_запись(
            сам.путь,
            "initial smoke observation envelope",
        )
        ожидаемые_поля = {
            "схема",
            "идентификатор_запуска",
            "план",
            "наблюдения",
            "текущая_проверка",
        }
        if (
            not isinstance(значение, dict)
            or set(значение) != ожидаемые_поля
            or значение["схема"] != СХЕМА_КОНВЕРТА_НАБЛЮДЕНИЙ
            or значение["идентификатор_запуска"] != идентификатор_запуска
            or значение["план"] is not None
            or значение["наблюдения"] != []
            or значение["текущая_проверка"] is not None
        ):
            raise ValueError("invalid initial smoke observation envelope")

    def установить_план(сам, шаги: Sequence[SmokeStep]) -> None:
        if сам.план is not None:
            raise ValueError("smoke analytical plan is already initialized")
        план: list[dict[str, str]] = []
        приведённые_ключи: set[str] = set()
        for шаг in шаги:
            if шаг.аналитический_ключ is None:
                continue
            ключ = проверить_аналитический_ключ(шаг.аналитический_ключ)
            приведённый = ключ.casefold()
            if приведённый in приведённые_ключи:
                raise ValueError(
                    f"case-insensitive analytical smoke key collision: {ключ}"
                )
            приведённые_ключи.add(приведённый)
            план.append(
                {"ключ_проверки": ключ, "название": шаг.name}
            )
        сам.план = план
        сам._сохранить()

    def начать(сам, шаг: SmokeStep) -> None:
        ключ = шаг.аналитический_ключ
        if ключ is None:
            return
        if сам.план is None:
            raise ValueError("smoke analytical plan is not initialized")
        if сам.текущая_проверка is not None:
            raise ValueError("another smoke test is already active")
        номер = len(сам.наблюдения)
        if номер >= len(сам.план) or any(
            значение != сам.план[номер][поле]
            for поле, значение in (
                ("ключ_проверки", ключ),
                ("название", шаг.name),
            )
        ):
            raise ValueError("active smoke test does not follow the analytical plan")
        if сам.наблюдения and сам.наблюдения[-1]["статус"] != "успешно":
            raise ValueError("active smoke test follows a fail-fast outcome")
        сам.текущая_проверка = {
            "ключ_проверки": ключ,
            "название": шаг.name,
            "начало_монотонные_наносекунды": time.monotonic_ns(),
        }
        сам._сохранить()

    def учесть(
        сам,
        шаг: SmokeStep,
        длительность_наносекунды: int,
        статус: str,
    ) -> None:
        ключ = шаг.аналитический_ключ
        if ключ is None:
            return
        if сам.план is None:
            raise ValueError("smoke analytical plan is not initialized")
        номер = len(сам.наблюдения)
        if номер >= len(сам.план) or any(
            значение != сам.план[номер][поле]
            for поле, значение in (
                ("ключ_проверки", ключ),
                ("название", шаг.name),
            )
        ):
            raise ValueError("smoke observations do not follow the analytical plan")
        if сам.наблюдения and сам.наблюдения[-1]["статус"] != "успешно":
            raise ValueError("smoke observation follows a fail-fast outcome")
        if сам.текущая_проверка is None or any(
            значение != сам.текущая_проверка[поле]
            for поле, значение in (
                ("ключ_проверки", ключ),
                ("название", шаг.name),
            )
        ):
            raise ValueError("completed smoke test does not match the active test")
        наблюдение = проверить_наблюдение_истории(
            {
                "ключ_проверки": ключ,
                "название": шаг.name,
                "статус": статус,
                "длительность_наносекунды": длительность_наносекунды,
            },
            сам.путь,
        )
        сам.наблюдения.append(наблюдение)
        сам.текущая_проверка = None

        сам._сохранить()

    def _сохранить(сам) -> None:
        конверт = {
            "схема": СХЕМА_КОНВЕРТА_НАБЛЮДЕНИЙ,
            "идентификатор_запуска": сам.идентификатор_запуска,
            "план": сам.план,
            "наблюдения": сам.наблюдения,
            "текущая_проверка": сам.текущая_проверка,
        }
        временный = (
            сам.путь.parent
            / f".{сам.путь.name}.{уникальные_идентификаторы.uuid4()}.tmp"
        )
        try:
            with временный.open("xb") as поток:
                поток.write(канонические_машинные_байты(конверт))
                поток.flush()
                os.fsync(поток.fileno())
            os.replace(временный, сам.путь)
            дескриптор = os.open(сам.путь.parent, os.O_RDONLY)
            try:
                os.fsync(дескриптор)
            finally:
                os.close(дескриптор)
        finally:
            try:
                временный.unlink()
            except FileNotFoundError:
                pass


def создать_сборщик_наблюдений_из_окружения(
) -> СборщикНаблюдений | None:
    путь_строкой = os.environ.get(ПЕРЕМЕННАЯ_ПУТИ_НАБЛЮДЕНИЙ)
    идентификатор = os.environ.get(ПЕРЕМЕННАЯ_ИДЕНТИФИКАТОРА_ЗАПУСКА)
    if путь_строкой is None and идентификатор is None:
        return None
    if путь_строкой is None or идентификатор is None:
        raise ValueError("incomplete smoke observation environment contract")
    try:
        канонический_идентификатор = str(
            уникальные_идентификаторы.UUID(идентификатор)
        )
    except ValueError as ошибка:
        raise ValueError("invalid smoke observation run identifier") from ошибка
    if канонический_идентификатор != идентификатор:
        raise ValueError("smoke observation run identifier must be canonical")
    путь = Path(путь_строкой)
    if not путь.is_absolute() or путь.parent.is_symlink():
        raise ValueError("invalid smoke observation output path")
    if not путь.parent.is_dir():
        raise ValueError("smoke observation output directory is missing")
    return СборщикНаблюдений(путь, идентификатор)


@dataclass(frozen=True)
class SwiftPackageManifest:
    executable_products: tuple[str, ...]
    target_paths: tuple[str, ...]
    products: tuple[str, ...] = ()
    library_products: tuple[str, ...] = ()
    targets: tuple[str, ...] = ()
    local_dependencies: tuple["SwiftLocalPackageDependency", ...] = ()
    product_dependencies: tuple["SwiftProductDependency", ...] = ()
    by_name_dependencies: tuple[tuple[str, str], ...] = ()


@dataclass(frozen=True, order=True)
class SwiftLocalPackageDependency:
    package: str
    identity: str


@dataclass(frozen=True, order=True)
class SwiftProductDependency:
    target: str
    identity: str
    product: str


@dataclass(frozen=True, order=True)
class SwiftAllowedProductDependency:
    target: str
    product: str


@dataclass(frozen=True, order=True)
class SwiftAllowedLocalDependency:
    package: str
    identity: str
    products: tuple[SwiftAllowedProductDependency, ...]


@dataclass(frozen=True)
class SwiftLintException:
    package: str
    reason: str
    removal_criterion: str
    source: str
    content_sha256: str


@dataclass(frozen=True)
class SwiftPackagePolicy:
    expected_products: dict[str, tuple[str, ...]]
    local_dependencies: dict[str, tuple[SwiftAllowedLocalDependency, ...]]
    lint_exceptions: dict[str, SwiftLintException]


def timing_record(
    kind: str,
    duration_seconds: float,
    result: str,
    *,
    index: int | None = None,
    total_steps: int | None = None,
    name: str | None = None,
    exit_code: int | None = None,
) -> TimingRecord:
    record: TimingRecord = {"kind": kind}
    if index is not None:
        record["index"] = index
    if total_steps is not None:
        record["total_steps"] = total_steps
    if name is not None:
        record["name"] = name
    record["result"] = result
    record["duration_seconds"] = f"{duration_seconds:.3f}"
    if exit_code is not None:
        record["exit_code"] = exit_code
    return record


def print_timing(record: TimingRecord) -> None:
    payload = json.dumps(
        record,
        ensure_ascii=False,
        separators=(",", ":"),
    )
    print(f"smoke-timing {payload}", flush=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--request",
        type=Path,
        help=(
            "Selected Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_slug]>/запрос.md "
            "file for fum-svyaznostj-rabochej-sessii."
        ),
    )
    parser.add_argument(
        "--commit-message-file",
        type=Path,
        help="Commit message file forwarded to fum-svyaznostj-rabochej-sessii.",
    )
    parser.add_argument(
        "--codex-thread-id",
        help="Expected root Codex thread identifier forwarded to fum-svyaznostj-rabochej-sessii.",
    )
    parser.add_argument(
        "--skip-session-coherence",
        action="store_true",
        help="Run repository checks without validating a specific working session.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help=(
            "Print planned check commands without running tests, builds or lint. "
            "Swift manifests are evaluated for discovery."
        ),
    )
    return parser.parse_args()


def repo_relative(path: Path, repo_root: Path) -> str:
    absolute = path if path.is_absolute() else repo_root / path
    return absolute.resolve().relative_to(repo_root.resolve()).as_posix()


def request_session_match(request: str | Path) -> re.Match[str] | None:
    path = Path(request)
    if path.name != "запрос.md" or path.parent.parent.name != "Журнал":
        return None
    return REQUEST_SESSION_STEM_RE.fullmatch(path.parent.name)


def request_requires_codex_commit_context(request: str | Path) -> bool:
    match = request_session_match(request)
    if match is None:
        return False
    return tuple(int(part) for part in match.groups()) >= CODEX_COMMIT_CONTEXT_RULE_START


def require_file(repo_root: Path, path: Path) -> str:
    absolute = (repo_root / path).resolve()
    if not absolute.exists():
        raise FileNotFoundError(f"required smoke-check component is missing: {path.as_posix()}")
    return repo_relative(absolute, repo_root)


def validate_project_skill_isolation(repo_root: Path) -> None:
    config_path = repo_root / CODEX_PROJECT_CONFIG
    if not config_path.is_file():
        raise ValueError(
            "project Codex config must set skills.include_instructions = false: "
            f"missing {CODEX_PROJECT_CONFIG.as_posix()}"
        )
    try:
        config = tomllib.loads(config_path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as exc:
        raise ValueError(
            f"invalid project Codex config {CODEX_PROJECT_CONFIG.as_posix()}: {exc}"
        ) from exc

    skills = config.get("skills")
    if not isinstance(skills, dict) or skills.get("include_instructions") is not False:
        raise ValueError(
            "project Codex config must set skills.include_instructions = false"
        )

    skills_root = repo_root / "Инструменты"
    if not skills_root.is_dir():
        return

    resolved_root = repo_root.resolve()
    for skill_dir in skills_root.iterdir():
        candidate = skill_dir / "SKILL.md"
        if not candidate.exists() and not candidate.is_symlink():
            continue
        candidate_path = candidate.relative_to(repo_root).as_posix()
        try:
            resolved = candidate.resolve(strict=True)
        except FileNotFoundError as exc:
            raise ValueError(
                f"local skill path is broken: {candidate_path}"
            ) from exc
        try:
            resolved.relative_to(resolved_root)
        except ValueError as exc:
            raise ValueError(
                "local skill path resolves outside repository: "
                f"{candidate_path}"
            ) from exc
        if not resolved.is_file():
            raise ValueError(
                f"local skill path is not a file: {candidate_path}"
            )


def discover_test_dirs(repo_root: Path) -> list[Path]:
    tools_dir = repo_root / "Инструменты"
    if not tools_dir.exists():
        return []

    test_dirs: list[Path] = []
    for tests_path in tools_dir.glob("*/tests"):
        if tests_path.is_dir() and any(tests_path.glob("test_*.py")):
            test_dirs.append(tests_path)
    return sorted(test_dirs, key=lambda path: repo_relative(path, repo_root))


def discover_swift_packages(repo_root: Path) -> list[Path]:
    prototypes_dir = repo_root / "Прототипы"
    if not prototypes_dir.exists():
        return []

    packages = [
        manifest.parent.resolve()
        for manifest in prototypes_dir.glob("*/Package.swift")
        if manifest.is_file()
    ]
    return sorted(packages, key=lambda path: repo_relative(path, repo_root))


def require_safe_relative_path(raw_path: object, label: str) -> str:
    if not isinstance(raw_path, str) or not raw_path:
        raise ValueError(f"{label} must be a non-empty relative path")
    path = PurePosixPath(raw_path)
    if (
        path.is_absolute()
        or WINDOWS_ABSOLUTE_PATH_RE.match(raw_path) is not None
        or raw_path.startswith(("\\\\", "//", "~", "$"))
        or "\\" in raw_path
        or ".." in path.parts
        or path.as_posix() != raw_path
    ):
        raise ValueError(f"{label} must be a normalized relative path: {raw_path!r}")
    return raw_path


def require_prototype_package_path(raw_path: object, label: str) -> str:
    path = require_safe_relative_path(raw_path, label)
    parts = PurePosixPath(path).parts
    if len(parts) != 2 or parts[0] != "Прототипы":
        raise ValueError(
            f"{label} must name one top-level package inside Прототипы: {path!r}"
        )
    return path


@dataclass(frozen=True)
class _SwiftToken:
    kind: str
    value: str


def _tokenize_swift_manifest(source: str) -> tuple[_SwiftToken, ...]:
    tokens: list[_SwiftToken] = []
    index = 0
    length = len(source)
    while index < length:
        current = source[index]
        if current.isspace():
            index += 1
            continue
        if source.startswith("//", index):
            newline = source.find("\n", index + 2)
            index = length if newline == -1 else newline + 1
            continue
        if source.startswith("/*", index):
            depth = 1
            index += 2
            while index < length and depth:
                if source.startswith("/*", index):
                    depth += 1
                    index += 2
                elif source.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            if depth:
                raise ValueError("Package.swift contains an unterminated block comment")
            continue
        if source.startswith('"""', index):
            end = source.find('"""', index + 3)
            if end == -1:
                raise ValueError("Package.swift contains an unterminated string literal")
            tokens.append(_SwiftToken("complex_string", source[index : end + 3]))
            index = end + 3
            continue
        if current == '"':
            index += 1
            value: list[str] = []
            complex_literal = False
            while index < length:
                char = source[index]
                if char == '"':
                    index += 1
                    tokens.append(
                        _SwiftToken(
                            "complex_string" if complex_literal else "string",
                            "".join(value),
                        )
                    )
                    break
                if char == "\\":
                    complex_literal = True
                    if index + 1 >= length:
                        raise ValueError(
                            "Package.swift contains an unterminated string escape"
                        )
                    value.extend((char, source[index + 1]))
                    index += 2
                    continue
                if char == "\n":
                    raise ValueError("Package.swift contains an unterminated string literal")
                value.append(char)
                index += 1
            else:
                raise ValueError("Package.swift contains an unterminated string literal")
            continue
        if current.isalpha() or current == "_":
            end = index + 1
            while end < length and (source[end].isalnum() or source[end] == "_"):
                end += 1
            tokens.append(_SwiftToken("identifier", source[index:end]))
            index = end
            continue
        tokens.append(_SwiftToken("symbol", current))
        index += 1
    return tuple(tokens)


def extract_manifest_local_dependency_paths(manifest_path: Path) -> tuple[str, ...]:
    try:
        source = manifest_path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        raise ValueError("Package.swift must be valid UTF-8") from exc
    tokens = _tokenize_swift_manifest(source)
    package_prefix = (
        _SwiftToken("identifier", "let"),
        _SwiftToken("identifier", "package"),
        _SwiftToken("symbol", "="),
        _SwiftToken("identifier", "Package"),
        _SwiftToken("symbol", "("),
    )
    package_starts = [
        index
        for index in range(len(tokens) - len(package_prefix) + 1)
        if tokens[index : index + len(package_prefix)] == package_prefix
    ]
    if len(package_starts) != 1:
        raise ValueError(
            "Package.swift must contain exactly one literal "
            "let package = Package(...) declaration"
        )

    declaration_start = package_starts[0]
    allowed_prelude = (
        _SwiftToken("identifier", "import"),
        _SwiftToken("identifier", "PackageDescription"),
    )
    if tokens[:declaration_start] != allowed_prelude:
        raise ValueError(
            "Package.swift may contain only import PackageDescription before "
            "the package declaration"
        )

    package_start = declaration_start + len(package_prefix) - 1
    package_end = _matching_swift_delimiter(tokens, package_start, "(", ")")
    if tokens[package_end + 1 :]:
        raise ValueError(
            "Package.swift may not mutate or execute code after the package "
            "declaration"
        )
    arguments = _split_swift_tokens_at_top_level(
        tokens[package_start + 1 : package_end]
    )
    dependency_values = [
        argument[2:]
        for argument in arguments
        if len(argument) >= 2
        and argument[0] == _SwiftToken("identifier", "dependencies")
        and argument[1] == _SwiftToken("symbol", ":")
    ]
    if len(dependency_values) > 1:
        raise ValueError("Package.swift contains duplicate dependencies arguments")
    if not dependency_values:
        return ()

    dependency_value = dependency_values[0]
    if (
        len(dependency_value) < 2
        or dependency_value[0] != _SwiftToken("symbol", "[")
        or dependency_value[-1] != _SwiftToken("symbol", "]")
        or _matching_swift_delimiter(dependency_value, 0, "[", "]")
        != len(dependency_value) - 1
    ):
        raise ValueError(
            "Package.swift dependencies must be a literal array"
        )

    entries = _split_swift_tokens_at_top_level(dependency_value[1:-1])
    paths: list[str] = []
    expected_prefix = (
        _SwiftToken("symbol", "."),
        _SwiftToken("identifier", "package"),
        _SwiftToken("symbol", "("),
        _SwiftToken("identifier", "path"),
        _SwiftToken("symbol", ":"),
    )
    for entry in entries:
        if not entry:
            continue
        if not (
            len(entry) == 7
            and entry[:5] == expected_prefix
            and entry[5].kind == "string"
            and entry[6] == _SwiftToken("symbol", ")")
        ):
            raise ValueError(
                "Package.swift dependencies must use exactly "
                '.package(path: "<canonical-relative-path>")'
            )
        paths.append(entry[5].value)
    if len(paths) != len(set(paths)):
        raise ValueError("Package.swift contains a duplicate local dependency path")
    return tuple(paths)


def _matching_swift_delimiter(
    tokens: tuple[_SwiftToken, ...],
    start: int,
    opening: str,
    closing: str,
) -> int:
    if tokens[start] != _SwiftToken("symbol", opening):
        raise ValueError("Package.swift delimiter parser received an invalid start")
    depth = 0
    for index in range(start, len(tokens)):
        token = tokens[index]
        if token == _SwiftToken("symbol", opening):
            depth += 1
        elif token == _SwiftToken("symbol", closing):
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("Package.swift contains an unterminated delimiter")


def _split_swift_tokens_at_top_level(
    tokens: tuple[_SwiftToken, ...],
) -> tuple[tuple[_SwiftToken, ...], ...]:
    segments: list[tuple[_SwiftToken, ...]] = []
    start = 0
    stack: list[str] = []
    matching = {")": "(", "]": "[", "}": "{"}
    for index, token in enumerate(tokens):
        if token.kind != "symbol":
            continue
        if token.value in {"(", "[", "{"}:
            stack.append(token.value)
        elif token.value in matching:
            if not stack or stack.pop() != matching[token.value]:
                raise ValueError("Package.swift contains mismatched delimiters")
        elif token.value == "," and not stack:
            segments.append(tokens[start:index])
            start = index + 1
    if stack:
        raise ValueError("Package.swift contains unterminated delimiters")
    segments.append(tokens[start:])
    return tuple(segments)


def _normalize_dump_local_dependency_path(
    raw_path: object,
    repo_root: Path,
) -> str:
    if not isinstance(raw_path, str) or not raw_path:
        raise ValueError("SwiftPM fileSystem dependency path must be non-empty")
    dump_path = Path(raw_path)
    if not dump_path.is_absolute():
        raise ValueError(
            "swift dump-package fileSystem dependency path must be absolute"
        )
    try:
        resolved = dump_path.resolve(strict=True)
    except FileNotFoundError as exc:
        raise ValueError("SwiftPM local dependency path does not exist") from exc
    root = repo_root.resolve()
    prototypes = (root / "Прототипы").resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ValueError("SwiftPM local dependency resolves outside repository") from exc
    try:
        resolved.relative_to(prototypes)
    except ValueError as exc:
        raise ValueError("SwiftPM local dependency resolves outside Прототипы") from exc
    relative = repo_relative(resolved, root)
    return require_prototype_package_path(
        relative,
        "SwiftPM local dependency",
    )


def _validate_manifest_dependency_declarations(
    repo_root: Path,
    package: Path,
    declared_paths: tuple[str, ...],
    dependencies: tuple[SwiftLocalPackageDependency, ...],
) -> None:
    if len(declared_paths) != len(dependencies):
        raise ValueError(
            "Package.swift local dependencies must use canonical literal .package(path:)"
        )
    package_path = repo_relative(package, repo_root)
    actual_by_path = {dependency.package: dependency for dependency in dependencies}
    normalized_declared: set[str] = set()
    for raw_path in declared_paths:
        if (
            Path(raw_path).is_absolute()
            or WINDOWS_ABSOLUTE_PATH_RE.match(raw_path) is not None
            or raw_path.startswith(("\\\\", "//", "~", "$"))
            or "\\" in raw_path
        ):
            raise ValueError("Package.swift local dependency path must be relative")
        try:
            resolved = (package / raw_path).resolve(strict=True)
        except FileNotFoundError as exc:
            raise ValueError(
                "Package.swift local dependency path does not exist"
            ) from exc
        normalized = repo_relative(resolved, repo_root)
        dependency = actual_by_path.get(normalized)
        if dependency is None:
            raise ValueError(
                "Package.swift local dependency does not match dump-package"
            )
        expected = posixpath.relpath(dependency.package, start=package_path)
        if raw_path != expected:
            raise ValueError(
                "Package.swift local dependency path must be canonical: "
                f"expected {expected!r}"
            )
        normalized_declared.add(normalized)
    if normalized_declared != set(actual_by_path):
        raise ValueError(
            "Package.swift local dependency set differs from dump-package"
        )


def parse_swift_package_manifest(
    output: str,
    *,
    repo_root: Path | None = None,
) -> SwiftPackageManifest:
    try:
        payload = json.loads(output)
    except json.JSONDecodeError as exc:
        raise ValueError(f"swift dump-package returned invalid JSON: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValueError("swift dump-package must return a JSON object")

    products = payload.get("products")
    targets = payload.get("targets")
    dependencies = payload.get("dependencies")
    if (
        not isinstance(products, list)
        or not isinstance(targets, list)
        or not isinstance(dependencies, list)
    ):
        raise ValueError(
            "swift dump-package is missing dependencies, products or targets"
        )

    executable_products: set[str] = set()
    all_products: set[str] = set()
    library_products: set[str] = set()
    for product in products:
        if not isinstance(product, dict):
            raise ValueError("swift dump-package contains an invalid product")
        product_type = product.get("type")
        if not isinstance(product_type, dict):
            raise ValueError("swift dump-package contains a product without a type")
        name = product.get("name")
        if not isinstance(name, str) or not name:
            raise ValueError("swift dump-package contains an unnamed product")
        if name in all_products:
            raise ValueError("swift dump-package contains a duplicate product")
        all_products.add(name)
        if "executable" in product_type:
            executable_products.add(name)
        if "library" in product_type:
            library_products.add(name)

    if not executable_products:
        raise ValueError("SwiftPM prototype has no executable products")

    target_paths: set[str] = set()
    target_names: set[str] = set()
    raw_product_dependencies: list[tuple[str, str, str]] = []
    by_name_dependencies: set[tuple[str, str]] = set()
    for target in targets:
        if not isinstance(target, dict):
            raise ValueError("swift dump-package contains an invalid target")
        target_name = target.get("name")
        if not isinstance(target_name, str) or not target_name:
            raise ValueError("swift dump-package contains an unnamed target")
        if target_name in target_names:
            raise ValueError("swift dump-package contains a duplicate target")
        target_names.add(target_name)
        if target.get("type") == "binary" or any(
            key in target for key in ("url", "checksum")
        ):
            raise ValueError("SwiftPM binary dependencies are forbidden")
        target_path = require_safe_relative_path(
            target.get("path"),
            "SwiftPM target path",
        )
        target_paths.add(target_path)
        raw_target_dependencies = target.get("dependencies")
        if not isinstance(raw_target_dependencies, list):
            raise ValueError("swift dump-package target dependencies must be a list")
        seen_target_dependencies: set[tuple[str, str, str]] = set()
        for raw_dependency in raw_target_dependencies:
            if not isinstance(raw_dependency, dict) or len(raw_dependency) != 1:
                raise ValueError(
                    "swift dump-package contains an invalid target dependency"
                )
            variant, value = next(iter(raw_dependency.items()))
            if variant in {"target", "byName"}:
                if (
                    not isinstance(value, list)
                    or len(value) != 2
                    or not isinstance(value[0], str)
                    or not value[0]
                ):
                    raise ValueError(
                        "swift dump-package contains an invalid internal target dependency"
                    )
                edge = (variant, target_name, value[0])
                if edge in seen_target_dependencies:
                    raise ValueError(
                        "swift dump-package contains a duplicate target dependency"
                    )
                seen_target_dependencies.add(edge)
                by_name_dependencies.add((target_name, value[0]))
                continue
            if variant != "product":
                raise ValueError(
                    "SwiftPM target dependency variant is not allowed"
                )
            if (
                not isinstance(value, list)
                or len(value) != 4
                or not isinstance(value[0], str)
                or not value[0]
                or not isinstance(value[1], str)
                or not value[1]
                or value[2] is not None
                or value[3] is not None
            ):
                raise ValueError(
                    "SwiftPM product dependency must have an exact unconditional form"
                )
            edge = ("product", value[0], value[1].lower())
            if edge in seen_target_dependencies:
                raise ValueError(
                    "swift dump-package contains a duplicate product dependency"
                )
            seen_target_dependencies.add(edge)
            raw_product_dependencies.append((target_name, value[1].lower(), value[0]))

    if not target_paths:
        raise ValueError("SwiftPM prototype has no target paths")

    local_dependencies: list[SwiftLocalPackageDependency] = []
    seen_dependency_paths: set[str] = set()
    seen_dependency_identities: set[str] = set()
    for raw_dependency in dependencies:
        if not isinstance(raw_dependency, dict) or len(raw_dependency) != 1:
            raise ValueError("swift dump-package contains an invalid package dependency")
        variant, value = next(iter(raw_dependency.items()))
        if variant != "fileSystem":
            raise ValueError(
                "SwiftPM source-control, registry and other non-local dependencies "
                "are forbidden"
            )
        if not isinstance(value, list) or len(value) != 1 or not isinstance(value[0], dict):
            raise ValueError("SwiftPM fileSystem dependency has an invalid shape")
        description = value[0]
        allowed_fields = {"identity", "path", "productFilter", "traits"}
        if not {"identity", "path", "productFilter"}.issubset(description):
            raise ValueError("SwiftPM fileSystem dependency is missing required fields")
        if not set(description).issubset(allowed_fields):
            raise ValueError("SwiftPM fileSystem dependency has unknown fields")
        if description["productFilter"] is not None:
            raise ValueError("SwiftPM fileSystem dependency productFilter is forbidden")
        traits = description.get("traits")
        if traits not in (None, [{"name": "default"}]):
            raise ValueError("SwiftPM fileSystem dependency traits are not supported")
        identity = description["identity"]
        if (
            not isinstance(identity, str)
            or not identity
            or identity != identity.lower()
            or any(character in identity for character in ("/", "\\"))
        ):
            raise ValueError("SwiftPM fileSystem dependency identity is invalid")
        if repo_root is None:
            raise ValueError(
                "SwiftPM local dependencies require repository context"
            )
        normalized_path = _normalize_dump_local_dependency_path(
            description["path"],
            repo_root,
        )
        if normalized_path in seen_dependency_paths:
            raise ValueError("duplicate SwiftPM local dependency path")
        if identity in seen_dependency_identities:
            raise ValueError("duplicate SwiftPM local dependency identity")
        seen_dependency_paths.add(normalized_path)
        seen_dependency_identities.add(identity)
        local_dependencies.append(
            SwiftLocalPackageDependency(
                package=normalized_path,
                identity=identity,
            )
        )

    product_dependencies: set[SwiftProductDependency] = set()
    for target_name, identity, product_name in raw_product_dependencies:
        if identity not in seen_dependency_identities:
            raise ValueError(
                "SwiftPM product dependency refers to an undeclared package identity"
            )
        dependency = SwiftProductDependency(
            target=target_name,
            identity=identity,
            product=product_name,
        )
        if dependency in product_dependencies:
            raise ValueError("duplicate SwiftPM product dependency")
        product_dependencies.add(dependency)

    return SwiftPackageManifest(
        executable_products=tuple(sorted(executable_products)),
        target_paths=tuple(sorted(target_paths)),
        products=tuple(sorted(all_products)),
        library_products=tuple(sorted(library_products)),
        targets=tuple(sorted(target_names)),
        local_dependencies=tuple(sorted(local_dependencies)),
        product_dependencies=tuple(sorted(product_dependencies)),
        by_name_dependencies=tuple(sorted(by_name_dependencies)),
    )


def inspect_swift_package(
    repo_root: Path,
    package: Path,
    swift: str,
    *,
    clock: Clock | None = None,
    timing_sink: TimingSink | None = None,
) -> SwiftPackageManifest:
    package_path = repo_relative(package, repo_root)
    command = (
        swift,
        "package",
        "--package-path",
        package_path,
        *SWIFT_OFFLINE_FLAGS,
        "dump-package",
    )
    timer = clock or time.perf_counter
    started_at = timer() if timing_sink is not None else None
    result: subprocess.CompletedProcess[str] | None = None
    try:
        result = subprocess.run(
            command,
            cwd=repo_root,
            env=smoke_env(),
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if result.returncode != 0:
            detail = (result.stderr or result.stdout).strip()
            suffix = f": {detail}" if detail else ""
            raise ValueError(
                f"cannot inspect SwiftPM package {package_path}{suffix}"
            )
        manifest = parse_swift_package_manifest(
            result.stdout,
            repo_root=repo_root,
        )
        declared_paths = extract_manifest_local_dependency_paths(
            package / "Package.swift"
        )
        _validate_manifest_dependency_declarations(
            repo_root,
            package,
            declared_paths,
            manifest.local_dependencies,
        )
    except OSError as exc:
        if timing_sink is not None and started_at is not None:
            timing_sink(
                timing_record(
                    "manifest",
                    timer() - started_at,
                    "failed",
                    name=f"SwiftPM manifest {package_path}",
                    exit_code=127,
                )
            )
        raise FileNotFoundError(
            f"cannot inspect SwiftPM package {package_path}: {exc}"
        ) from exc
    except Exception:
        if timing_sink is not None and started_at is not None:
            exit_code = (
                result.returncode
                if result is not None and result.returncode != 0
                else None
            )
            timing_sink(
                timing_record(
                    "manifest",
                    timer() - started_at,
                    "failed",
                    name=f"SwiftPM manifest {package_path}",
                    exit_code=exit_code,
                )
            )
        raise
    if timing_sink is not None and started_at is not None:
        timing_sink(
            timing_record(
                "manifest",
                timer() - started_at,
                "passed",
                name=f"SwiftPM manifest {package_path}",
            )
        )
    return manifest


def swift_lint_content_sha256(
    repo_root: Path,
    package: Path,
    target_paths: tuple[str, ...],
) -> str:
    root = repo_root.resolve()
    package_root = package.resolve()
    repo_relative(package_root, root)

    inputs: set[Path] = {
        package_root / "Package.swift",
        root / SWIFT_FORMAT_CONFIG,
    }
    for target_path in target_paths:
        normalized = require_safe_relative_path(
            target_path,
            "SwiftPM target path",
        )
        target = package_root / normalized
        if not target.exists():
            raise ValueError(
                "SwiftPM lint input is missing: "
                f"{repo_relative(target, root)}"
            )
        if target.is_file():
            if target.suffix == ".swift":
                inputs.add(target)
            continue
        for current_root, dirnames, filenames in os.walk(target):
            dirnames[:] = [
                name
                for name in dirnames
                if not name.startswith(".") and name not in {".build", ".swiftpm"}
            ]
            current = Path(current_root)
            for filename in filenames:
                if filename.endswith(".swift"):
                    inputs.add(current / filename)

    digest = hashlib.sha256()
    for path in sorted(
        inputs,
        key=lambda item: repo_relative(item, root),
    ):
        if not path.is_file():
            raise ValueError(
                "SwiftPM lint input is missing: "
                f"{repo_relative(path, root)}"
            )
        relative = repo_relative(path, root).encode("utf-8")
        content = path.read_bytes()
        digest.update(len(relative).to_bytes(8, "big"))
        digest.update(relative)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return f"sha256:{digest.hexdigest()}"


def reject_swift_format_ignores(repo_root: Path, package: Path) -> None:
    root = repo_root.resolve()
    package_root = package.resolve()
    candidates: set[Path] = set()

    current = package_root
    while True:
        candidate = current / ".swift-format-ignore"
        if candidate.exists():
            candidates.add(candidate)
        if current == current.parent:
            break
        current = current.parent

    for candidate in package_root.rglob(".swift-format-ignore"):
        relative_parts = candidate.relative_to(package_root).parts
        if ".build" not in relative_parts and ".swiftpm" not in relative_parts:
            candidates.add(candidate)

    if candidates:
        rendered: list[str] = []
        for candidate in sorted(candidates):
            try:
                rendered.append(repo_relative(candidate, root))
            except ValueError:
                rendered.append(candidate.as_posix())
        raise ValueError(
            "SwiftPM strict lint does not allow .swift-format-ignore: "
            + ", ".join(rendered)
        )


def load_swift_package_policy(
    repo_root: Path,
    discovered_packages: set[str],
) -> SwiftPackagePolicy:
    policy_path = repo_root / SWIFT_PACKAGE_POLICY
    if not policy_path.exists():
        if discovered_packages:
            raise ValueError(
                "SwiftPM packages were discovered but swift-package-policy.json "
                "is missing"
            )
        return SwiftPackagePolicy(
            expected_products={},
            local_dependencies={},
            lint_exceptions={},
        )
    try:
        payload = json.loads(policy_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid SwiftPM policy JSON: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValueError("SwiftPM policy must be a JSON object")
    expected_top_level = {
        "schemaVersion",
        "defaultMode",
        "packages",
        "exceptions",
    }
    if set(payload) != expected_top_level:
        raise ValueError(
            "SwiftPM policy must contain exactly schemaVersion, "
            "defaultMode, packages and exceptions"
        )
    if payload["schemaVersion"] != 2:
        raise ValueError("unsupported SwiftPM policy schemaVersion")
    if payload["defaultMode"] != "strict":
        raise ValueError("SwiftPM policy defaultMode must be strict")

    raw_packages = payload["packages"]
    if not isinstance(raw_packages, list):
        raise ValueError("SwiftPM policy packages must be a list")
    expected_products: dict[str, tuple[str, ...]] = {}
    raw_local_dependencies_by_package: dict[str, object] = {}
    for raw_package in raw_packages:
        if not isinstance(raw_package, dict) or set(raw_package) != {
            "package",
            "executableProducts",
            "localDependencies",
        }:
            raise ValueError(
                "SwiftPM policy package must contain package, "
                "executableProducts and localDependencies"
            )
        package = require_prototype_package_path(
            raw_package["package"],
            "SwiftPM policy package",
        )
        if package in expected_products:
            raise ValueError(f"duplicate SwiftPM policy package: {package}")
        products = raw_package["executableProducts"]
        if (
            not isinstance(products, list)
            or not products
            or not all(
                isinstance(product, str) and product
                for product in products
            )
            or len(set(products)) != len(products)
        ):
            raise ValueError(
                "SwiftPM policy executableProducts must be a non-empty "
                "unique string list"
            )
        expected_products[package] = tuple(sorted(products))
        raw_local_dependencies_by_package[package] = raw_package[
            "localDependencies"
        ]

    expected_package_names = set(expected_products)
    if expected_package_names != discovered_packages:
        missing = sorted(expected_package_names - discovered_packages)
        unregistered = sorted(discovered_packages - expected_package_names)
        details: list[str] = []
        if missing:
            details.append(f"missing packages: {', '.join(missing)}")
        if unregistered:
            details.append(
                f"unregistered packages: {', '.join(unregistered)}"
            )
        raise ValueError(
            "SwiftPM package inventory differs from policy: "
            + "; ".join(details)
        )

    local_dependencies: dict[str, tuple[SwiftAllowedLocalDependency, ...]] = {}
    for package, raw_dependencies in raw_local_dependencies_by_package.items():
        if not isinstance(raw_dependencies, list):
            raise ValueError("SwiftPM policy localDependencies must be a list")
        parsed_dependencies: list[SwiftAllowedLocalDependency] = []
        dependency_paths: set[str] = set()
        dependency_identities: set[str] = set()
        for raw_dependency in raw_dependencies:
            if not isinstance(raw_dependency, dict) or set(raw_dependency) != {
                "package",
                "identity",
                "products",
            }:
                raise ValueError(
                    "SwiftPM policy local dependency must contain package, "
                    "identity and products"
                )
            dependency_package = require_prototype_package_path(
                raw_dependency["package"],
                "SwiftPM policy local dependency package",
            )
            if dependency_package not in discovered_packages:
                raise ValueError(
                    "SwiftPM policy local dependency refers to an unregistered "
                    f"package: {dependency_package}"
                )
            if dependency_package == package:
                raise ValueError("SwiftPM policy does not allow self-dependency")
            identity = raw_dependency["identity"]
            if (
                not isinstance(identity, str)
                or not identity
                or identity != identity.lower()
                or any(character in identity for character in ("/", "\\"))
            ):
                raise ValueError(
                    "SwiftPM policy local dependency identity must be a "
                    "lowercase non-empty string"
                )
            if dependency_package in dependency_paths:
                raise ValueError("duplicate SwiftPM policy local dependency package")
            if identity in dependency_identities:
                raise ValueError("duplicate SwiftPM policy local dependency identity")
            dependency_paths.add(dependency_package)
            dependency_identities.add(identity)

            raw_products = raw_dependency["products"]
            if not isinstance(raw_products, list) or not raw_products:
                raise ValueError(
                    "SwiftPM policy local dependency products must be a "
                    "non-empty list"
                )
            parsed_products: set[SwiftAllowedProductDependency] = set()
            for raw_product in raw_products:
                if not isinstance(raw_product, dict) or set(raw_product) != {
                    "target",
                    "product",
                }:
                    raise ValueError(
                        "SwiftPM policy product dependency must contain target "
                        "and product"
                    )
                target = raw_product["target"]
                product = raw_product["product"]
                if not isinstance(target, str) or not target:
                    raise ValueError(
                        "SwiftPM policy product dependency target must not be empty"
                    )
                if not isinstance(product, str) or not product:
                    raise ValueError(
                        "SwiftPM policy product dependency product must not be empty"
                    )
                parsed_product = SwiftAllowedProductDependency(
                    target=target,
                    product=product,
                )
                if parsed_product in parsed_products:
                    raise ValueError("duplicate SwiftPM policy product dependency")
                parsed_products.add(parsed_product)
            parsed_dependencies.append(
                SwiftAllowedLocalDependency(
                    package=dependency_package,
                    identity=identity,
                    products=tuple(sorted(parsed_products)),
                )
            )
        local_dependencies[package] = tuple(sorted(parsed_dependencies))

    _validate_unique_swift_dependency_identities(
        dependency
        for dependencies in local_dependencies.values()
        for dependency in dependencies
    )

    graph = {
        package: tuple(
            dependency.package
            for dependency in local_dependencies[package]
        )
        for package in expected_products
    }
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(package: str) -> None:
        if package in visiting:
            raise ValueError("SwiftPM policy local dependency graph contains a cycle")
        if package in visited:
            return
        visiting.add(package)
        for dependency in graph[package]:
            visit(dependency)
        visiting.remove(package)
        visited.add(package)

    for package in sorted(graph):
        visit(package)

    raw_exceptions = payload["exceptions"]
    if not isinstance(raw_exceptions, list):
        raise ValueError("SwiftPM policy exceptions must be a list")

    exceptions: dict[str, SwiftLintException] = {}
    expected_exception_fields = {
        "package",
        "reason",
        "removalCriterion",
        "source",
        "contentSha256",
    }
    for raw_exception in raw_exceptions:
        if not isinstance(raw_exception, dict):
            raise ValueError("SwiftPM lint exception must be an object")
        if set(raw_exception) != expected_exception_fields:
            raise ValueError(
                "SwiftPM lint exception has missing or unknown fields"
            )
        package = require_safe_relative_path(
            raw_exception["package"],
            "SwiftPM lint exception package",
        )
        if package not in discovered_packages:
            raise ValueError(
                f"SwiftPM lint exception refers to an undiscovered package: {package}"
            )
        if package in exceptions:
            raise ValueError(
                f"duplicate SwiftPM lint exception for package: {package}"
            )
        source = require_safe_relative_path(
            raw_exception["source"],
            "SwiftPM lint exception source",
        )
        if not (repo_root / source).is_file():
            raise ValueError(
                f"SwiftPM lint exception source is missing: {source}"
            )
        reason = raw_exception["reason"]
        removal_criterion = raw_exception["removalCriterion"]
        content_sha256 = raw_exception["contentSha256"]
        if not isinstance(reason, str) or not reason.strip():
            raise ValueError("SwiftPM lint exception reason must not be empty")
        if (
            not isinstance(removal_criterion, str)
            or not removal_criterion.strip()
        ):
            raise ValueError(
                "SwiftPM lint exception removalCriterion must not be empty"
            )
        if (
            not isinstance(content_sha256, str)
            or SHA256_RE.fullmatch(content_sha256) is None
        ):
            raise ValueError(
                "SwiftPM lint exception contentSha256 must be sha256:<hex>"
            )
        exceptions[package] = SwiftLintException(
            package=package,
            reason=reason.strip(),
            removal_criterion=removal_criterion.strip(),
            source=source,
            content_sha256=content_sha256,
        )
    return SwiftPackagePolicy(
        expected_products=expected_products,
        local_dependencies=local_dependencies,
        lint_exceptions=exceptions,
    )


def _validate_unique_swift_dependency_identities(
    dependencies: Iterable[
        SwiftLocalPackageDependency | SwiftAllowedLocalDependency
    ],
) -> None:
    identity_to_package: dict[str, str] = {}
    package_to_identity: dict[str, str] = {}
    for dependency in dependencies:
        package = dependency.package
        identity = dependency.identity
        previous_package = identity_to_package.setdefault(identity, package)
        if previous_package != package:
            raise ValueError(
                "SwiftPM local dependency identity maps to multiple packages: "
                f"{identity}"
            )
        previous_identity = package_to_identity.setdefault(package, identity)
        if previous_identity != identity:
            raise ValueError(
                "SwiftPM local dependency package maps to multiple identities: "
                f"{package}"
            )


def validate_swift_dependency_contract(
    policy: SwiftPackagePolicy,
    manifests: dict[str, SwiftPackageManifest],
) -> None:
    _validate_unique_swift_dependency_identities(
        dependency
        for manifest in manifests.values()
        for dependency in manifest.local_dependencies
    )
    actual_graph: dict[str, tuple[str, ...]] = {}
    for package in sorted(manifests):
        manifest = manifests[package]
        expected_dependencies = {
            SwiftLocalPackageDependency(
                package=dependency.package,
                identity=dependency.identity,
            )
            for dependency in policy.local_dependencies[package]
        }
        actual_dependencies = set(manifest.local_dependencies)
        if actual_dependencies != expected_dependencies:
            missing = sorted(expected_dependencies - actual_dependencies)
            extra = sorted(actual_dependencies - expected_dependencies)
            raise ValueError(
                "SwiftPM local package dependencies differ from policy for "
                f"{package}: missing {missing}, extra {extra}"
            )

        expected_products = {
            SwiftProductDependency(
                target=product.target,
                identity=dependency.identity,
                product=product.product,
            )
            for dependency in policy.local_dependencies[package]
            for product in dependency.products
        }
        actual_products = set(manifest.product_dependencies)
        if actual_products != expected_products:
            missing = sorted(expected_products - actual_products)
            extra = sorted(actual_products - expected_products)
            raise ValueError(
                "SwiftPM local product dependencies differ from policy for "
                f"{package}: missing {missing}, extra {extra}"
            )

        own_targets = set(manifest.targets)
        for target, dependency_name in manifest.by_name_dependencies:
            if dependency_name not in own_targets:
                raise ValueError(
                    "SwiftPM byName dependency must refer to an internal target: "
                    f"{package}:{target}"
                )

        for dependency in policy.local_dependencies[package]:
            provider = manifests[dependency.package]
            provider_products = set(provider.library_products)
            for product in dependency.products:
                if product.target not in own_targets:
                    raise ValueError(
                        "SwiftPM policy product dependency target is missing: "
                        f"{package}:{product.target}"
                    )
                if product.product not in provider_products:
                    raise ValueError(
                        "SwiftPM policy product is not an exported library: "
                        f"{dependency.package}:{product.product}"
                    )
        actual_graph[package] = tuple(
            dependency.package for dependency in manifest.local_dependencies
        )

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(package: str) -> None:
        if package in visiting:
            raise ValueError("SwiftPM local dependency graph contains a cycle")
        if package in visited:
            return
        visiting.add(package)
        for dependency in actual_graph[package]:
            if dependency not in actual_graph:
                raise ValueError(
                    "SwiftPM local dependency is not a registered package: "
                    f"{dependency}"
                )
            visit(dependency)
        visiting.remove(package)
        visited.add(package)

    for package in sorted(actual_graph):
        visit(package)


def build_swift_steps(
    repo_root: Path,
    swift: str,
    *,
    clock: Clock | None = None,
    timing_sink: TimingSink | None = None,
) -> list[SmokeStep]:
    packages = discover_swift_packages(repo_root)
    package_names = {
        repo_relative(package, repo_root)
        for package in packages
    }
    policy = load_swift_package_policy(repo_root, package_names)
    if not packages:
        return []
    swift_format_config = require_file(repo_root, SWIFT_FORMAT_CONFIG)
    steps: list[SmokeStep] = []
    manifests: dict[str, SwiftPackageManifest] = {}

    for package in packages:
        package_path = repo_relative(package, repo_root)
        reject_swift_format_ignores(repo_root, package)
        if timing_sink is None:
            manifest = inspect_swift_package(repo_root, package, swift)
        else:
            manifest = inspect_swift_package(
                repo_root,
                package,
                swift,
                clock=clock,
                timing_sink=timing_sink,
            )
        expected_products = policy.expected_products[package_path]
        if manifest.executable_products != expected_products:
            raise ValueError(
                f"SwiftPM executable products differ from policy for "
                f"{package_path}: expected {expected_products}, "
                f"got {manifest.executable_products}"
            )
        manifests[package_path] = manifest

    validate_swift_dependency_contract(policy, manifests)

    for package in packages:
        package_path = repo_relative(package, repo_root)
        manifest = manifests[package_path]
        exception = policy.lint_exceptions.get(package_path)
        if exception is not None:
            current_hash = swift_lint_content_sha256(
                repo_root,
                package,
                manifest.target_paths,
            )
            if current_hash != exception.content_sha256:
                raise ValueError(
                    "SwiftPM lint exception is stale (устарело) for "
                    f"{package_path}: expected {exception.content_sha256}, "
                    f"got {current_hash}"
                )

        steps.append(
            SmokeStep(
                name=f"Тесты SwiftPM {package_path}",
                command=(
                    swift,
                    "test",
                    "--package-path",
                    package_path,
                    *SWIFT_OFFLINE_FLAGS,
                ),
                аналитический_ключ=package_path,
            )
        )
        for product in manifest.executable_products:
            steps.append(
                SmokeStep(
                    name=(
                        f"Сборка SwiftPM-продукта {package_path}: {product}"
                    ),
                    command=(
                        swift,
                        "build",
                        "--package-path",
                        package_path,
                        *SWIFT_OFFLINE_FLAGS,
                        "--product",
                        product,
                    ),
                )
            )

        if exception is None:
            lint_inputs = [f"{package_path}/Package.swift"]
            lint_inputs.extend(
                f"{package_path}/{target_path}"
                for target_path in manifest.target_paths
            )
            steps.append(
                SmokeStep(
                    name=f"Строгий lint SwiftPM {package_path}",
                    command=(
                        swift,
                        "format",
                        "lint",
                        "--configuration",
                        swift_format_config,
                        "--strict",
                        "--recursive",
                        *lint_inputs,
                    ),
                )
            )
        else:
            steps.append(
                SmokeStep(
                    name=f"Lint-исключение SwiftPM {package_path}",
                    command=None,
                    detail=(
                        f"{exception.reason} Критерий снятия: "
                        f"{exception.removal_criterion} Источник: "
                        f"{exception.source}. Проверенный снимок: "
                        f"{exception.content_sha256}"
                    ),
                )
            )
    return steps


def build_steps(
    repo_root: str | Path,
    request: str | Path | None,
    include_session: bool = True,
    python: str | None = None,
    swift: str | None = None,
    commit_message_file: str | Path | None = None,
    codex_thread_id: str | None = None,
    clock: Clock | None = None,
    timing_sink: TimingSink | None = None,
) -> list[SmokeStep]:
    root = Path(repo_root).resolve()
    validate_project_skill_isolation(root)
    if include_session:
        if request is None:
            raise ValueError("--request is required unless --skip-session-coherence is used")
        if request_session_match(request) is None:
            raise ValueError(
                "--request must match "
                "Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_slug]>/запрос.md"
            )
        if request_requires_codex_commit_context(request):
            if commit_message_file is None:
                raise ValueError(
                    "--commit-message-file is required for this request"
                )
            if codex_thread_id is None:
                raise ValueError("--codex-thread-id is required for this request")
    python_cmd = python or sys.executable
    swift_cmd = swift or "swift"
    steps: list[SmokeStep] = []

    for test_dir in discover_test_dirs(root):
        tool_name = test_dir.parent.name
        путь_набора = repo_relative(test_dir, root)
        steps.append(
            SmokeStep(
                name=f"Тесты {tool_name}",
                command=(
                    python_cmd,
                    "-m",
                    "unittest",
                    "discover",
                    "-s",
                    путь_набора,
                    "-p",
                    "test_*.py",
                ),
                аналитический_ключ=путь_набора,
            )
        )

    steps.extend(
        build_swift_steps(
            root,
            swift_cmd,
            clock=clock,
            timing_sink=timing_sink,
        )
    )

    request_folder_layout_script = require_file(root, REQUEST_FOLDER_LAYOUT_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка структуры папок запросов",
            command=(
                python_cmd,
                request_folder_layout_script,
                "validate",
                "--repo-root",
                ".",
            ),
            ранняя_проверка=True,
        )
    )

    planning_script = require_file(root, PLANNING_REGISTRY_SCRIPT)
    planning_output = PLANNING_REGISTRY_OUTPUT.as_posix()
    steps.append(
        SmokeStep(
            name="Сборка планового реестра",
            command=(python_cmd, planning_script, "build", "--output", planning_output),
            ранняя_проверка=True,
        )
    )
    steps.append(
        SmokeStep(
            name="Проверка планового реестра",
            command=(python_cmd, planning_script, "validate", "--registry", planning_output),
            ранняя_проверка=True,
        )
    )

    automation_names_script = require_file(root, AUTOMATION_NAMES_CHECK_SCRIPT)
    automation_names_registry = require_file(root, AUTOMATION_NAMES_REGISTRY)
    steps.append(
        SmokeStep(
            name="Проверка реестра названий автоматизаций",
            command=(
                python_cmd,
                automation_names_script,
                "--repo-root",
                ".",
                "--registry",
                automation_names_registry,
            ),
            ранняя_проверка=True,
        )
    )

    machine_local_path_script = require_file(root, MACHINE_LOCAL_PATH_CHECK_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка машинно-локальных путей",
            command=(
                python_cmd,
                machine_local_path_script,
                "--repo-root",
                ".",
            ),
            ранняя_проверка=True,
        )
    )

    скрипт_перевода = require_file(
        root,
        СКРИПТ_ПРОВЕРКИ_ПЕРЕВОДА_ОБЪЯВЛЕНИЙ_КОДА,
    )
    снимок_остатка = require_file(
        root,
        СНИМОК_ОСТАТКА_ОБЪЯВЛЕНИЙ_КОДА,
    )
    steps.append(
        SmokeStep(
            name="Проверка перевода объявлений кода",
            command=(
                python_cmd,
                скрипт_перевода,
                "проверить",
                "--корень-репозитория",
                ".",
                "--снимок",
                снимок_остатка,
            ),
            ранняя_проверка=True,
        )
    )

    git_dependency_script = require_file(root, GIT_DEPENDENCY_CHECK_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка Git-зависимости LinguisticKit",
            command=(
                python_cmd,
                git_dependency_script,
                "check",
                "--repo-root",
                ".",
                "--fork-url",
                LINGUISTIC_KIT_FORK_URL,
                "--upstream-url",
                LINGUISTIC_KIT_UPSTREAM_URL,
                "--path",
                LINGUISTIC_KIT_PATH,
                "--revision",
                LINGUISTIC_KIT_REVISION,
            ),
            ранняя_проверка=True,
        )
    )

    prototype_launch_script = require_file(root, PROTOTYPE_LAUNCH_CHECK_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка скриптов запуска прототипов",
            command=(python_cmd, prototype_launch_script),
            ранняя_проверка=True,
        )
    )

    question_backlinks_script = require_file(root, QUESTION_BACKLINKS_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка двунаправленности вопросов",
            command=(python_cmd, question_backlinks_script),
            ранняя_проверка=True,
        )
    )

    readme_index_script = require_file(root, README_INDEX_CHECK_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка тематического индекса README",
            command=(python_cmd, readme_index_script, "--repo-root", "."),
            ранняя_проверка=True,
        )
    )

    recency_script = require_file(root, RECENCY_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка recency-меток Markdown",
            command=(python_cmd, recency_script, "--check"),
            ранняя_проверка=True,
        )
    )
    obsidian_graph_recency_script = require_file(root, OBSIDIAN_GRAPH_RECENCY_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка тепловой карты графа Obsidian",
            command=(python_cmd, obsidian_graph_recency_script, "--check"),
            ранняя_проверка=True,
        )
    )

    if include_session:
        session_script = require_file(root, SESSION_COHERENCE_SCRIPT)
        assert request is not None  # Validated before the plan is built.
        request_path = repo_relative(Path(request), root)
        session_command = [python_cmd, session_script, "--request", request_path]
        if commit_message_file is not None:
            message_path = Path(commit_message_file)
            session_command.extend(
                ["--commit-message-file", message_path.as_posix()]
            )
        if codex_thread_id is not None:
            session_command.extend(["--codex-thread-id", codex_thread_id])
        steps.append(
            SmokeStep(
                name="Проверка связности рабочей сессии",
                command=tuple(session_command),
                ранняя_проверка=True,
            )
        )

    return steps


def smoke_env() -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    env.pop(ПЕРЕМЕННАЯ_ПУТИ_НАБЛЮДЕНИЙ, None)
    env.pop(ПЕРЕМЕННАЯ_ИДЕНТИФИКАТОРА_ЗАПУСКА, None)
    return env


def print_output(result: subprocess.CompletedProcess[str]) -> None:
    if result.stdout:
        print(result.stdout, end="", flush=True)
    if result.stderr:
        print(result.stderr, end="", flush=True)


def run_steps(
    steps: list[SmokeStep],
    repo_root: Path,
    *,
    clock: Clock | None = None,
    overall_started_at: float | None = None,
    сборщик_наблюдений: СборщикНаблюдений | None = None,
) -> int:
    timer = clock or time.perf_counter
    total_started_at = (
        timer() if overall_started_at is None else overall_started_at
    )
    env = smoke_env()
    total = len(steps)
    for index, step in enumerate(steps, start=1):
        print(f"[{index}/{total}] {step.name}", flush=True)
        step_started_at = timer()
        if step.command is None:
            print(step.detail, flush=True)
            print_timing(
                timing_record(
                    "step",
                    timer() - step_started_at,
                    "passed",
                    index=index,
                    total_steps=total,
                    name=step.name,
                )
            )
            continue
        print(shlex.join(step.command), flush=True)
        if сборщик_наблюдений is not None:
            сборщик_наблюдений.начать(step)
        try:
            result = subprocess.run(
                step.command,
                cwd=repo_root,
                env=env,
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
        except OSError as exc:
            exit_code = 127
            шаг_завершён = timer()
            if сборщик_наблюдений is not None:
                сборщик_наблюдений.учесть(
                    step,
                    round(max(0.0, шаг_завершён - step_started_at) * 1_000_000_000),
                    "не завершено",
                )
            print_timing(
                timing_record(
                    "step",
                    шаг_завершён - step_started_at,
                    "failed",
                    index=index,
                    total_steps=total,
                    name=step.name,
                    exit_code=exit_code,
                )
            )
            print(
                f"smoke-check could not run step {index}: {step.name}: {exc}",
                file=sys.stderr,
            )
            print_timing(
                timing_record(
                    "total",
                    timer() - total_started_at,
                    "failed",
                    exit_code=exit_code,
                )
            )
            return exit_code
        step_finished_at = timer()
        print_output(result)
        step_result = "passed" if result.returncode == 0 else "failed"
        if сборщик_наблюдений is not None:
            статус_наблюдения = (
                "успешно" if result.returncode == 0 else "неуспешно"
            )
            сборщик_наблюдений.учесть(
                step,
                round(
                    max(0.0, step_finished_at - step_started_at)
                    * 1_000_000_000
                ),
                статус_наблюдения,
            )
        print_timing(
            timing_record(
                "step",
                step_finished_at - step_started_at,
                step_result,
                index=index,
                total_steps=total,
                name=step.name,
                exit_code=(
                    result.returncode
                    if result.returncode != 0
                    else None
                ),
            )
        )
        if result.returncode != 0:
            print(
                f"smoke-check failed at step {index}: {step.name}",
                file=sys.stderr,
            )
            print_timing(
                timing_record(
                    "total",
                    timer() - total_started_at,
                    "failed",
                    exit_code=result.returncode,
                )
            )
            return result.returncode
    print(f"smoke-check passed: {total} step(s)")
    print_timing(
        timing_record(
            "total",
            timer() - total_started_at,
            "passed",
        )
    )
    return 0


def main(*, clock: Clock | None = None) -> int:
    timer = clock or time.perf_counter
    overall_started_at = timer()
    try:
        сборщик_наблюдений = создать_сборщик_наблюдений_из_окружения()
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    args = parse_args()
    root = args.repo_root.resolve()
    include_session = not args.skip_session_coherence
    preparation_started_at = timer()

    try:
        steps = build_steps(
            root,
            args.request,
            include_session=include_session,
            commit_message_file=args.commit_message_file,
            codex_thread_id=args.codex_thread_id,
            clock=timer,
            timing_sink=print_timing,
        )
        статистика = загрузить_статистику_закрытых_запусков(root)
        steps[:] = упорядочить_тестовые_шаги(steps, статистика)
        if not args.list and сборщик_наблюдений is not None:
            сборщик_наблюдений.установить_план(steps)
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        print_timing(
            timing_record(
                "preparation",
                timer() - preparation_started_at,
                "failed",
                exit_code=2,
            )
        )
        print_timing(
            timing_record(
                "total",
                timer() - overall_started_at,
                "failed",
                exit_code=2,
            )
        )
        return 2

    print_timing(
        timing_record(
            "preparation",
            timer() - preparation_started_at,
            "passed",
        )
    )

    if args.list:
        for step in steps:
            if step.command is None:
                print(f"{step.name}: {step.detail}")
            else:
                print(f"{step.name}: {shlex.join(step.command)}")
        print_timing(
            timing_record(
                "total",
                timer() - overall_started_at,
                "passed",
            )
        )
        return 0

    return run_steps(
        steps,
        root,
        clock=timer,
        overall_started_at=overall_started_at,
        сборщик_наблюдений=сборщик_наблюдений,
    )


if __name__ == "__main__":
    raise SystemExit(main())
