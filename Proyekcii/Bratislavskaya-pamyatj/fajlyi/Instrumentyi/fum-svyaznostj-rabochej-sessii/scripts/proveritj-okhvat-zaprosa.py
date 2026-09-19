#!/usr/bin/env python3
"""Проверить покрытие фактических изменений запросом, без выдачи разрешения коммита."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess

ПУТЬ = Path(__file__).with_name('сверить-материалы-этапа.py')
ОПИСАНИЕ = importlib.util.spec_from_file_location('охват_материалов', ПУТЬ)
ОХВАТ = importlib.util.module_from_spec(ОПИСАНИЕ)
ОПИСАНИЕ.loader.exec_module(ОХВАТ)


def проверить(корень, запрос):
    корень = Path(корень).resolve()
    if Path(ОХВАТ.выполнить_git(корень, 'rev-parse', '--show-toplevel').decode().strip()).resolve() != корень:
        raise ValueError('Нужен физический корень checkout')
    ссылка = ОХВАТ.выполнить_git(корень, 'symbolic-ref', 'HEAD')
    вершина = ОХВАТ.выполнить_git(корень, 'rev-parse', 'HEAD')
    статус, строки, пути = ОХВАТ.прочитать_статус(корень)
    кэш = {}
    def точный(имя):
        return ОХВАТ.точный_путь(корень, имя, кэш)
    путь, отчёт, исходные, цели, ошибки = ОХВАТ.прочитать_охват(корень, запрос, строки, точный)
    if (путь.read_bytes() != исходные
            or ОХВАТ.прочитать_статус(корень)[0] != статус
            or ОХВАТ.выполнить_git(корень, 'symbolic-ref', 'HEAD') != ссылка
            or ОХВАТ.выполнить_git(корень, 'rev-parse', 'HEAD') != вершина):
        ошибки.append('Вход изменился во время проверки охвата')
    return {'схема': 'fum.покрытие-запроса.1', 'готов': not ошибки, 'ошибки': ошибки, 'путей': len(пути)}


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--корень', type=Path, required=True)
    парсер.add_argument('--запрос', required=True)
    аргументы = парсер.parse_args()
    try:
        результат = проверить(аргументы.корень, аргументы.запрос)
    except (OSError, ValueError, subprocess.CalledProcessError, StopIteration) as ошибка:
        результат = {'схема': 'fum.покрытие-запроса.1', 'готов': False, 'ошибки': [str(ошибка)]}
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
    return 0 if результат['готов'] else 1


if __name__ == '__main__':
    raise SystemExit(выполнить())
