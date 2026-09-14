"""Выдать ограниченную страницу заранее сохранённого полного остатка."""
import argparse
import sys
from pathlib import Path

from компактный_остаток import представить, закодировать


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--результат", type=Path, required=True)
    разбор.add_argument("--sha256", required=True)
    разбор.add_argument("--начало", type=int, default=0)
    разбор.add_argument("--число", type=int, default=20)
    разбор.add_argument("--максимум-байтов", type=int, default=16000)
    параметры = разбор.parse_args()
    try:
        with параметры.результат.open("rb") as поток:
            данные = поток.read(128 * 1024 * 1024 + 1)
        результат = представить(данные, параметры.sha256, начало=параметры.начало,
            число=параметры.число, максимум_байтов=параметры.максимум_байтов)
        sys.stdout.buffer.write(закодировать(результат))
        return 0
    except (OSError, ValueError) as ошибка:
        print("Не удалось показать остаток: " + (str(ошибка) if isinstance(ошибка, ValueError)
            else "файл недоступен"), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(выполнить())
