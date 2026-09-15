"""Проверяет сохранность подготовленного результата после перезапуска."""

import base64
import hashlib
import json
from pathlib import Path
import re
import subprocess


корень = Path.cwd()
материалы = Path(__file__).resolve().parent
снимок = json.loads((материалы / "снимок-свидетельств.json").read_bytes())
for путь, ожидаемый in снимок["хэши_неизменяемых_файлов"].items():
    assert hashlib.sha256((корень / путь).read_bytes()).hexdigest() == ожидаемый, путь
for путь in снимок["содержательные_пути"]:
    assert subprocess.check_output(["git", "show", ":" + путь]) == (корень / путь).read_bytes(), путь
прежние_байты = base64.b64decode((материалы / "прежний-запрос-до-навигации.base64").read_bytes().strip(), validate=True)
assert hashlib.sha256(прежние_байты).hexdigest() == снимок["хэш_прежнего_запроса"]


def без_навигации_и_свежести(данные):
    текст = данные.decode("utf-8")
    текст = re.sub(r"## Навигация по запросам\n.*?(?=## Текст запроса)", "", текст, flags=re.S)
    return re.sub(r"<!-- FUM-MD-RECENCY:BEGIN -->.*?<!-- FUM-MD-RECENCY:END -->", "", текст, flags=re.S).strip()


assert без_навигации_и_свежести(прежние_байты) == без_навигации_и_свежести((корень / снимок["прежний_запрос"]).read_bytes())
прежний = (корень / снимок["прежний_запрос"]).parent
записи = прежний / "материалы/запуски-проверок"
осиротевшая = json.loads(next(записи.glob("10_*.json")).read_bytes())
assert осиротевшая["состояние"] == "выполняется"
assert all(осиротевшая[поле] is None for поле in ("код_завершения", "длительность_наносекунды", "статус"))
успех = json.loads(next(записи.glob("7_*.json")).read_bytes())
assert успех["статус"] == "успешно" and успех["код_завершения"] == 0
профиль = json.loads((прежний / "материалы/профиль-перехода.json").read_bytes())
код = корень / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py"
assert профиль["хэш_кода"] == "sha256:" + hashlib.sha256(код.read_bytes()).hexdigest()
subprocess.run(["git", "--literal-pathspecs", "diff", "--cached", "--check", "--",
                *снимок["содержательные_пути"]], check=True)
print("21 неизменяемый файл сохранён; 9 содержательных файлов совпадают с индексом; старый исход не выдуман")
