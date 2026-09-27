"""Вывести сохраняющее происхождение объединение двух точных Git-снимков."""
import argparse
import json
import sys
import time
from pathlib import Path

import обработка_сообщений as обработка


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, required=True)
    разбор.add_argument("--codex-thread-id", dest="задача", required=True)
    разбор.add_argument("--родитель", action="append", required=True)
    параметры = разбор.parse_args()
    начало = time.perf_counter_ns()
    try:
        результат = обработка.подготовить_слияние_историй(
            параметры.корень_репозитория, параметры.задача, параметры.родитель)
        байты = результат.pop("байты")
        результат.update(схема="fum.подготовка-слияния-историй.1", хэш=обработка.хэш(байты),
                         байты=len(байты), длительность_наносекунды=time.perf_counter_ns() - начало)
        sys.stdout.buffer.write(байты)
        print(json.dumps(результат, ensure_ascii=False, sort_keys=True), file=sys.stderr)
        return 0
    except (OSError, ValueError, TypeError, KeyError, обработка.гит.ОшибкаОтчёта) as ошибка:
        print(str(ошибка), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(выполнить())
