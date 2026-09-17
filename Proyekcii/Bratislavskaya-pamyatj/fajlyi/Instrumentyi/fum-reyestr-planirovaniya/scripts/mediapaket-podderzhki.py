#!/usr/bin/env python3
"""Подготовить черновики в stdout; файловые и внешние эффекты не выполняются."""
import sys
sys.dont_write_bytecode = True

import argparse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from медиапакет_поддержки import собрать, прочитать_вход
from реестр_поддержки import байты


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", required=True)
    разбор.add_argument("--вход", required=True)
    аргументы = разбор.parse_args()
    try:
        результат = собрать(Path(аргументы.корень_репозитория), прочитать_вход(аргументы.вход))
    except (OSError, ValueError) as ошибка:
        print("Медиапакет отклонён: " + str(ошибка), file=sys.stderr)
        return 2
    sys.stdout.buffer.write(байты(результат))
    return 0


if __name__ == "__main__":
    raise SystemExit(выполнить())
