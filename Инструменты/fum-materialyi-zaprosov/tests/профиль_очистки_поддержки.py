#!/usr/bin/env python3
"""Адресный профиль очистки сохранённых HTML без сети и изменения источников."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import sys

КОРЕНЬ = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(КОРЕНЬ / "Инструменты/fum-materialyi-zaprosov/scripts"))
import source_archive as архив
sys.path.insert(0, str(КОРЕНЬ / "Инструменты/fum-snimki-indeksa/scripts"))
from профиль import Профиль


def главный():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--выход", type=Path, required=True)
    параметры = парсер.parse_args()
    манифест = КОРЕНЬ / "Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/материалы/очистка-снимков.json"
    профиль = Профиль()
    входы = {}
    набор = []
    отдельные_PDF = []
    for запись in json.loads(манифест.read_text())["снимки"]:
        каталог = архив.url_output_dir(КОРЕНЬ, запись["URL"])
        if (каталог / "body.pdf").is_file():
            отдельные_PDF.append(запись["URL"])
            continue
        тело = каталог / "response.body.html"
        заголовки = каталог / "response.headers.txt"
        for путь in (тело, заголовки):
            входы[путь.relative_to(КОРЕНЬ).as_posix()] = hashlib.sha256(путь.read_bytes()).hexdigest()
        набор.append((тело.read_text(), заголовки.read_text()))
    for повтор in range(7):
        with профиль.стадия("Очистка сохранённого набора"):
            for тело, заголовки in набор:
                очищено = архив.очистить_служебный_html(тело)
                if очищено != тело or архив.redact_headers(заголовки) != заголовки:
                    raise ValueError("Набор ещё не приведён к устойчивому очищенному виду")
    отчёт = {"схема": "fum.профиль-очистки-поддержки.1", "Python": platform.python_version(),
        "повторы": 7, "снимков": len(набор), "входы_sha256": входы,
        "отдельные_PDF_вне_профиля_HTML": отдельные_PDF,
        "код_sha256": {str(п.relative_to(КОРЕНЬ)): hashlib.sha256(п.read_bytes()).hexdigest() for п in (Path(__file__).resolve(), Path(архив.__file__))},
        "измерения": профиль.записи,
        "границы": "Только очистка уже загруженных в память HTML и заголовков. Сеть, извлечение текста, старт Python и запись файлов не измеряются. Проверка идемпотентности не заменяет смысловой аудит секретов."}
    параметры.выход.parent.mkdir(parents=True, exist_ok=True)
    параметры.выход.write_text(json.dumps(отчёт, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"снимков": len(набор), "повторы": 7, "максимум_мс": max(з["длительность_наносекунды"] for з in профиль.записи) / 1e6}, ensure_ascii=False))


if __name__ == "__main__":
    главный()
