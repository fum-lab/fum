import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time

парсер = argparse.ArgumentParser()
парсер.add_argument('--корень-репозитория', type=Path, required=True)
парсер.add_argument('--база', required=True)
парсер.add_argument('--выход', type=Path, required=True)
аргументы = парсер.parse_args()
корень = аргументы.корень_репозитория.resolve()
имя = 'Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/proveritj-mashinno-lokaljnyiye-puti.py'
путь = корень / имя
sys.path.insert(0, str(путь.parent))
sys.path.insert(0, str(корень / 'Инструменты/fum-struktura-papok-zaprosov/scripts'))
зависимости = [
    'Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/path_forms.py',
    'Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py',
]
for зависимость in зависимости:
    assert (корень / зависимость).read_bytes() == subprocess.check_output(
        ['git', '--no-optional-locks', '-C', str(корень), 'show', аргументы.база + ':' + зависимость])
входы = [(п.relative_to(корень).as_posix(), п.read_bytes()) for п in sorted((корень / 'Issues/fum-lab/fum/данные').glob('*.json'))]
assert входы
база = subprocess.check_output(['git', '--no-optional-locks', '-C', str(корень), 'show', аргументы.база + ':' + имя])
результаты = {}
with tempfile.TemporaryDirectory() as временный:
    прежний = Path(временный) / 'прежний.py'; прежний.write_bytes(база)
    for метка, исходник in [('до', прежний), ('после', путь)]:
        спецификация = importlib.util.spec_from_file_location('сканер_' + метка, исходник)
        модуль = importlib.util.module_from_spec(спецификация); sys.modules[спецификация.name] = модуль
        спецификация.loader.exec_module(модуль)
        измерения = []
        for повтор in range(3):
            начало = time.monotonic_ns()
            находки = [э for имя_входа, байты in входы for э in модуль.scan_text(имя_входа, байты.decode('utf-8'))]
            длительность = time.monotonic_ns() - начало
            форма = [(э.path, э.line, э.kind, э.line_sha256) for э in находки]
            отпечаток = hashlib.sha256(json.dumps(форма, ensure_ascii=False).encode()).hexdigest()
            измерения.append({'длительность_нс': длительность, 'находок': len(находки), 'формы_sha256': отпечаток})
        результаты[метка] = {'код_sha256': hashlib.sha256(исходник.read_bytes()).hexdigest(),
                             'повторы': измерения, 'медиана_нс': statistics.median(э['длительность_нс'] for э in измерения)}
assert {э['формы_sha256'] for э in результаты['до']['повторы']} == {э['формы_sha256'] for э in результаты['после']['повторы']}
результаты.update({'схема': 'fum.профиль-классификации-обсуждений.1', 'база': аргументы.база,
                  'входы': [{'путь': имя_входа, 'sha256': hashlib.sha256(байты).hexdigest()} for имя_входа, байты in входы],
                  'граница': 'Только классификация точных страниц обсуждений. Число и формы находок сохраняются; их категория намеренно меняется. Git-извлечение и чтение исходников вне таймера.'})
with аргументы.выход.open('x') as выход: json.dump(результаты, выход, ensure_ascii=False, indent=2); выход.write('\n')
print(json.dumps({метка: результаты[метка]['медиана_нс'] for метка in ['до', 'после']}))
