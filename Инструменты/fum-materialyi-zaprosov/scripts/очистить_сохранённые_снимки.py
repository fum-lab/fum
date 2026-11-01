#!/usr/bin/env python3
"""Повторно очистить уже сохранённые URL-снимки по точному приватному плану."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import source_archive as архив  # noqa: E402


СХЕМА = "fum.очистка-сохранённых-источников.1"
АРХИВАТОР_ДИАЛОГА = Path(__file__).resolve().with_name("archive-chatgpt-share.py")
ЗАМЕРЫ: list[dict[str, object]] = []


@contextmanager
def _метка(имя: str):
    начало = time.perf_counter_ns()
    try:
        yield
    finally:
        ЗАМЕРЫ.append({"этап": имя, "миллисекунды": round((time.perf_counter_ns() - начало) / 1_000_000, 3)})


def _диалоговый_архиватор():
    описание = importlib.util.spec_from_file_location("fum_chatgpt_source_archive", АРХИВАТОР_ДИАЛОГА)
    if описание is None or описание.loader is None:
        raise ValueError("архиватор диалога недоступен")
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = модуль
    описание.loader.exec_module(модуль)
    return модуль


def _хэш(данные: bytes) -> str:
    return hashlib.sha256(данные).hexdigest()


def _отслеживаемые_файлы(корень: Path) -> list[str]:
    вывод = subprocess.check_output(
        ["git", "ls-files", "-z", "--", "Источники/URL"], cwd=корень
    )
    return sorted({путь.decode("utf-8") for путь in вывод.split(b"\0") if путь})


def _входящие_снимки(корень: Path) -> set[str]:
    основа = subprocess.check_output(
        ["git", "merge-base", "HEAD", "MERGE_HEAD"], cwd=корень, text=True
    ).strip()
    вывод = subprocess.check_output(
        ["git", "diff", "--name-only", "-z", основа, "MERGE_HEAD", "--", "Источники/URL"],
        cwd=корень,
    )
    return {str(Path(путь.decode("utf-8")).parent) for путь in вывод.split(b"\0") if путь}


def _байты_текста(данные: bytes, очистить) -> bytes:
    текст = данные.decode("utf-8", errors="surrogateescape")
    return очистить(текст).encode("utf-8", errors="surrogateescape")


def _отчёт_с_поздней_очисткой(данные: bytes) -> bytes:
    текст = данные.decode("utf-8")
    текст = re.sub(
        r"(?m)^(- Effective URL: )(.*)$",
        lambda поле: поле[1] + архив.очистить_код_переадресации(поле[2]),
        текст,
    )
    старая_запись = "- Повторная очистка сохранённого снимка: удалены известные служебные идентификаторы запроса, nonce и локальные метаданные без нового сетевого захвата."
    запись = "- Повторная очистка сохранённого снимка: удалены известные служебные идентификаторы запроса, nonce, локальные метаданные и телеметрия без нового сетевого захвата."
    if запись in текст:
        return текст.encode("utf-8")
    if старая_запись in текст:
        return текст.replace(старая_запись, запись, 1).encode("utf-8")
    заголовок = "## Редакции перед сохранением\n\n"
    if текст.count(заголовок) == 1:
        return текст.replace(заголовок, заголовок + запись + "\n", 1).encode("utf-8")
    if заголовок in текст:
        raise ValueError("отчёт снимка имеет неоднозначный раздел редакций")
    поздний = "## Поздняя очистка служебных данных\n\n" + запись + "\n"
    маркер = "<!-- FUM-MD-RECENCY:BEGIN -->"
    if маркер in текст:
        return текст.replace(маркер, поздний + "\n" + маркер, 1).encode("utf-8")
    return (текст.rstrip("\n") + "\n\n" + поздний).encode("utf-8")


def _преобразования(корень: Path, пути: list[str]) -> dict[str, bytes]:
    диалог = _диалоговый_архиватор()
    снимки = {str(Path(путь).parent) for путь in пути}
    результат: dict[str, bytes] = {}
    пути_по_снимкам: dict[str, list[str]] = {}
    for путь in пути:
        пути_по_снимкам.setdefault(str(Path(путь).parent), []).append(путь)
    for снимок in sorted(снимки):
        текущие = пути_по_снимкам[снимок]
        имена = {Path(путь).name: путь for путь in текущие}
        изменены = False
        значения: set[str] = set()
        if "chatgpt-share.html" in имена:
            for имя in ("chatgpt-share.initial-state.json", "chatgpt-share.decoded-data.json"):
                путь = имена.get(имя)
                if путь is not None:
                    значения.update(диалог.collect_local_metadata_values(json.loads((корень / путь).read_text())))
        for имя, путь in sorted(имена.items()):
            файл = корень / путь
            if файл.is_symlink() or not файл.is_file():
                raise ValueError("необычный путь снимка")
            исходные = файл.read_bytes()
            новые = исходные
            if имя.endswith(".headers.txt"):
                новые = _байты_текста(исходные, архив.redact_headers)
            elif имя == "response.body.html":
                новые = _байты_текста(исходные, архив.очистить_служебную_разметку)
            elif имя == "chatgpt-share.html":
                новые = _байты_текста(
                    исходные,
                    lambda текст: диалог.redact_text_values(
                        архив.очистить_служебную_разметку(текст), значения
                    ),
                )
            elif имя in {"chatgpt-share.initial-state.json", "chatgpt-share.decoded-data.json"}:
                данные = json.loads(исходные.decode("utf-8"))
                новые = json.dumps(диалог.redact_initial_state(данные), ensure_ascii=False, indent=2).encode("utf-8")
            elif имя.startswith("chatgpt-share.script-") or имя == "chatgpt-share.react-router-stream.txt":
                новые = _байты_текста(
                    исходные,
                    lambda текст: диалог.redact_text_values(архив.очистить_поля_скрипта(текст), значения),
                )
            if новые != исходные:
                результат[путь] = новые
                изменены = True
        отчёт = имена.get("extraction-report.md")
        if изменены and отчёт is None:
            raise ValueError("изменяемый снимок без отчёта")
        if отчёт is not None:
            исходный_отчёт = (корень / отчёт).read_bytes()
            текст_отчёта = исходный_отчёт.decode("utf-8")
            адрес_изменится = any(
                строка.startswith("- Effective URL: ")
                and архив.очистить_код_переадресации(строка) != строка
                for строка in текст_отчёта.splitlines()
            )
            if изменены or адрес_изменится:
                новые = _отчёт_с_поздней_очисткой(исходный_отчёт)
                if новые != исходный_отчёт:
                    результат[отчёт] = новые
    return результат


def построить_план(корень: Path) -> dict[str, object]:
    with _метка("инвентаризация"):
        каталоги = _входящие_снимки(корень)
        пути = [путь for путь in _отслеживаемые_файлы(корень) if str(Path(путь).parent) in каталоги]
    with _метка("очистка"):
        новые = _преобразования(корень, пути)
    return {
        "схема": СХЕМА,
        "исходный_коммит": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=корень, text=True).strip(),
        "второй_родитель": subprocess.check_output(["git", "rev-parse", "MERGE_HEAD"], cwd=корень, text=True).strip(),
        "файлы": [
            {"путь": путь, "до": _хэш((корень / путь).read_bytes()), "после": _хэш(данные)}
            for путь, данные in sorted(новые.items())
        ],
    }


def применить(корень: Path, план: dict[str, object]) -> int:
    with _метка("предварительная_сверка"):
        фактический = построить_план(корень)
    if фактический != план:
        raise ValueError("план не совпадает с текущими исходниками или родителями слияния")
    каталоги = _входящие_снимки(корень)
    пути = [путь for путь in _отслеживаемые_файлы(корень) if str(Path(путь).parent) in каталоги]
    новые = _преобразования(корень, пути)
    for запись in план["файлы"]:
        путь = корень / запись["путь"]
        if путь.is_symlink() or _хэш(путь.read_bytes()) != запись["до"]:
            raise ValueError("снимок изменился перед записью")
    with _метка("атомарные_замены"):
        for запись in план["файлы"]:
            путь = корень / запись["путь"]
            descriptor, временный = tempfile.mkstemp(prefix=f".{путь.name}.tmp-", dir=путь.parent)
            try:
                with os.fdopen(descriptor, "wb") as выход:
                    выход.write(новые[запись["путь"]])
                    выход.flush()
                    os.fsync(выход.fileno())
                os.chmod(временный, путь.stat().st_mode & 0o7777)
                os.replace(временный, путь)
            finally:
                Path(временный).unlink(missing_ok=True)
    return len(новые)


def проверить(корень: Path, план: dict[str, object]) -> int:
    if план.get("схема") != СХЕМА or not isinstance(план.get("файлы"), list):
        raise ValueError("неизвестная схема плана")
    for имя, аргумент in (("исходный_коммит", "HEAD"), ("второй_родитель", "MERGE_HEAD")):
        oid = subprocess.check_output(["git", "rev-parse", аргумент], cwd=корень, text=True).strip()
        if план.get(имя) != oid:
            raise ValueError("родители слияния изменились")
    for запись in план["файлы"]:
        путь = корень / запись["путь"]
        if путь.is_symlink() or _хэш(путь.read_bytes()) != запись["после"]:
            raise ValueError("байты очищенного снимка не совпадают с планом")
    каталоги = _входящие_снимки(корень)
    пути = [путь for путь in _отслеживаемые_файлы(корень) if str(Path(путь).parent) in каталоги]
    with _метка("повторная_очистка"):
        if _преобразования(корень, пути):
            raise ValueError("повторная очистка меняет сохранённые снимки")
    with _метка("манифесты"):
        for каталог in sorted({str(Path(запись["путь"]).parent) for запись in план["файлы"]}):
            манифест = корень / каталог / архив.SNAPSHOT_MANIFEST_NAME
            if манифест.is_file():
                архив.validate_snapshot_manifest(манифест.parent)
    return len(план["файлы"])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("режим", choices=("план", "применить", "проверить"))
    parser.add_argument("--корень", type=Path, required=True)
    parser.add_argument("--план", type=Path, required=True)
    args = parser.parse_args()
    корень = args.корень.resolve(strict=True)
    if args.режим == "план":
        if args.план.exists():
            raise ValueError("файл плана уже существует")
        данные = построить_план(корень)
        args.план.write_text(json.dumps(данные, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps({"файлов": len(данные["файлы"]), "профиль": ЗАМЕРЫ}, ensure_ascii=False))
        return 0
    план = json.loads(args.план.read_text())
    if args.режим == "проверить":
        проверено = проверить(корень, план)
        print(json.dumps({"проверено": проверено, "профиль": ЗАМЕРЫ}, ensure_ascii=False))
        return 0
    очищено = применить(корень, план)
    print(json.dumps({"очищено": очищено, "профиль": ЗАМЕРЫ}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
