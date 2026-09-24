#!/usr/bin/env python3
"""Читать приватную выгрузку и выдавать только ограниченное свидетельство её происхождения."""
import argparse
import json
import sys

from снимок_нативного_источника import _сырой
from свидетельство_видимых_ответов import свидетельство


def main():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--выгрузка', required=True)
    разбор.add_argument('--задача', required=True)
    параметры = разбор.parse_args()
    try:
        сырые, _ = _сырой(параметры.выгрузка)
        итог = свидетельство(сырые, параметры.задача)
    except (OSError, ValueError, TypeError):
        print(json.dumps({'схема': 'fum.отказ-свидетельства-ответов.1',
                          'ошибка': 'Недопустимая приватная выгрузка'}, ensure_ascii=False))
        return 2
    print(json.dumps(итог, ensure_ascii=False, indent=2))
    return 0 if итог['полнота_поддержанных_ответов'] else 3


if __name__ == '__main__':
    sys.exit(main())
