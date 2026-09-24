#!/usr/bin/env python3
"""Читать собственные видимые ответы без изменения native и без экспорта рассуждений."""
import argparse
import json
import sys

from снимок_нативного_источника import _сырой
from видимые_ответы import извлечь


def main():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--исходник', required=True)
    разбор.add_argument('--задача', required=True)
    параметры = разбор.parse_args()
    try:
        сырые, _ = _сырой(параметры.исходник)
        итог = извлечь(сырые, параметры.задача)
    except (OSError, ValueError, TypeError) as ошибка:
        print(json.dumps({'схема': 'fum.отказ-чтения-видимых-ответов.1', 'ошибка': str(ошибка)}, ensure_ascii=False))
        return 2
    print(json.dumps(итог, ensure_ascii=False, indent=2))
    return 0 if итог['полнота_поддержанных_ответов'] else 3


if __name__ == '__main__':
    sys.exit(main())
