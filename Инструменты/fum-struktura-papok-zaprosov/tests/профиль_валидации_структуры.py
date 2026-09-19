"""Сравнить две закреплённые версии validate_layout на одном временном входе."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import statistics
import subprocess
import sys
import time
import types

from test_request_folder_layout import RepositoryFixture

КОРЕНЬ = Path(__file__).resolve().parents[3]
МОДУЛЬ = Path('Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py')


def загрузить(ревизия: str, имя: str):
    if re.fullmatch(r'[0-9a-f]{40}', ревизия) is None:
        raise ValueError('нужен полный SHA-1 коммита')
    subprocess.run(['git', '-C', str(КОРЕНЬ), 'cat-file', '-e', ревизия + '^{commit}'], check=True)
    исходник = subprocess.run(['git', '-C', str(КОРЕНЬ), 'show', ревизия + ':' + МОДУЛЬ.as_posix()],
                              check=True, capture_output=True).stdout
    модуль = types.ModuleType(имя)
    модуль.__file__ = str(КОРЕНЬ / МОДУЛЬ)
    sys.modules[имя] = модуль
    exec(compile(исходник, модуль.__file__, 'exec'), модуль.__dict__)
    return модуль, hashlib.sha256(исходник).hexdigest()


def отпечаток(корень: Path) -> str:
    хэш = hashlib.sha256()
    for путь in sorted(корень.rglob('*')):
        относительный = путь.relative_to(корень)
        if '.git' in относительный.parts or not путь.is_file():
            continue
        хэш.update(относительный.as_posix().encode() + b'\0' + путь.read_bytes() + b'\0')
    return хэш.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--до', required=True)
    parser.add_argument('--после', required=True)
    parser.add_argument('--выход', type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str((КОРЕНЬ / МОДУЛЬ).parent))
    версии = [загрузить(args.до, 'структура_до'), загрузить(args.после, 'структура_после')]
    фикстура = RepositoryFixture()
    try:
        фикстура.make_canonical_layout()
        фикстура.write('.gitignore', 'Журнал/локальный-*/\n')
        for номер in range(200):
            фикстура.write(f'Журнал/локальный-{номер}/кэш.bin', b'cache')
        for номер in range(1000):
            фикстура.write(f'Данные/{номер}/значение.txt', 'данные')
        фикстура.commit()
        вход = отпечаток(фикстура.root)
        git_до = фикстура.git('status', '--porcelain').stdout
        результаты = [[], []]
        ожидаемый = None
        for повтор in range(3):
            for номер in ((0, 1) if повтор % 2 == 0 else (1, 0)):
                начало = time.perf_counter_ns()
                результат = версии[номер][0].validate_layout(фикстура.root)
                длительность = time.perf_counter_ns() - начало
                if ожидаемый is None:
                    ожидаемый = результат
                if результат != ожидаемый or отпечаток(фикстура.root) != вход:
                    raise RuntimeError('изменился результат или вход сравнения')
                if фикстура.git('status', '--porcelain').stdout != git_до:
                    raise RuntimeError('изменилось состояние Git фикстуры')
                результаты[номер].append(длительность)
        зависимости = {}
        for модуль in tuple(sys.modules.values()):
            имя = getattr(модуль, '__file__', None)
            if not имя:
                continue
            путь = Path(имя).resolve()
            if путь.is_relative_to(КОРЕНЬ) and путь.is_file():
                зависимости[путь.relative_to(КОРЕНЬ).as_posix()] = hashlib.sha256(путь.read_bytes()).hexdigest()
        выход = {'схема': 'fum.профиль-валидации-структуры.1', 'python': sys.version.split()[0],
                 'вход_sha256': вход, 'результат': ожидаемый,
                 'игнорируемых_папок': 200, 'файлов_данных': 1000,
                 'зависимости_текущего_checkout': зависимости,
                 'граница': 'Три чередующихся повтора на одной фикстуре; подготовка, хэширование, Git-status и импорт исключены из таймера. Зависимости общие из текущего checkout. Оба исходника исполняются с каноническим __file__ для одинаковых ресурсов.',
                 'версии': [{'коммит': oid, 'исходник_sha256': версия[1], 'наносекунды': времена,
                             'медиана_наносекунды': statistics.median(времена)}
                            for oid, версия, времена in zip((args.до, args.после), версии, результаты, strict=True)]}
        args.выход.parent.mkdir(parents=True, exist_ok=True)
        with args.выход.open('x', encoding='utf-8') as файл:
            json.dump(выход, файл, ensure_ascii=False, indent=2)
            файл.write('\n')
        print(json.dumps({'результат': ожидаемый, 'медианы_с': [statistics.median(v)/1e9 for v in результаты]}, ensure_ascii=False))
        return 0
    finally:
        фикстура.close()


if __name__ == '__main__':
    raise SystemExit(main())
