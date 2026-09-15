#!/usr/bin/env python3
"""Явный импорт наблюдений и необязательная подготовка сообщения коммита."""
import argparse
import json
from pathlib import Path

from история_модели import импортировать, подготовить_коммит, _путь


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    for имя in ("корень-репозитория", "исходник", "native-task-id", "кэш", "история"):
        разбор.add_argument("--" + имя, required=True)
    разбор.add_argument("--без-записи", action="store_true")
    разбор.add_argument("--основа-коммита")
    разбор.add_argument("--сообщение-коммита")
    разбор.add_argument("--codex-thread-id")
    параметры = разбор.parse_args()
    try:
        поля = (параметры.основа_коммита, параметры.сообщение_коммита, параметры.codex_thread_id)
        if any(поля) and (not all(поля) or параметры.без_записи):
            raise ValueError("подготовке коммита нужны три параметра и пишущий режим")
        if all(поля):
            путь = _путь(параметры.сообщение_коммита)
            if путь.exists() or путь.is_symlink() or any((предок / '.git').exists() for предок in путь.parents):
                raise ValueError("сообщению коммита нужен новый приватный файл вне Git")
            основа = Path(параметры.основа_коммита).read_text(encoding="utf-8")
        результат = импортировать(параметры.исходник, параметры.native_task_id,
            корень_репозитория=параметры.корень_репозитория, кэш=параметры.кэш,
            история=параметры.история, без_записи=параметры.без_записи)
        if all(поля):
            текст = подготовить_коммит(основа, результат, параметры.codex_thread_id)
            with путь.open("x", encoding="utf-8") as поток:
                поток.write(текст)
            путь.chmod(0o600)
        print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
        return 0 if результат["полнота"] else 3
    except (ValueError, OSError, KeyError, TypeError) as ошибка:
        print(json.dumps({"схема": "fum.отказ-истории-модели.1", "полнота": False,
                          "ошибка": str(ошибка)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    raise SystemExit(выполнить())
