"""Три исходных монотонных повтора той же приёмочной Git-фикстуры №231."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time

from test_контрольной_точки_обратной_доставки import КонтрольнаяТочкаДоставки, ИНСТРУМЕНТЫ


def выполнить(повторов, выход):
    повторы = []
    for номер in range(1, повторов + 1):
        тест = КонтрольнаяТочкаДоставки()
        начало = time.perf_counter_ns()
        try:
            тест.setUp()
            подготовка = time.perf_counter_ns() - начало
            начало = time.perf_counter_ns()
            тест.test_новая_пара_обычная_подготовка_и_точный_merge_commit()
            конец = time.perf_counter_ns()
            квитанция = тест.доставка.подтвердить_коммит()
            поток = Path(квитанция['проверка']['каталог']) / 'манифест.json'
            повторы.append({'номер': номер, 'setup_нс': подготовка, 'цикл_нс': конец - начало,
                'стадии': тест.профиль, 'RAW_sha256': hashlib.sha256(поток.read_bytes()).hexdigest(),
                'коммит': квитанция['коммит'], 'дерево': квитанция['дерево'],
                'родители': тест.п['родители'], 'один_эффект': True,
                'схема_квитанции': квитанция['схема'],
                'терминал_sha256': квитанция['отчёт']['терминал']['sha256']})
        finally:
            тест.doCleanups()
    имена = ['fum-reyestr-planirovaniya/scripts/' + и for и in
        ['доставка_отчёта.py', 'обратная_доставка.py', 'доставка_состояние.py']]
    имена += ['fum-svyaznostj-rabochej-sessii/scripts/подготовка_дочернего_поручения.py',
        'fum-reyestr-planirovaniya/tests/test_контрольной_точки_обратной_доставки.py']
    результат = {'схема': 'fum.профиль-контрольной-точки-обратной-доставки.1',
        'граница': 'Реальные apply, stock start, полный генератор .7, maker .9, CLI fill, recency, v4/RAW/preview, staging, готовность, merge commit, две квитанции и повтор maker. Setup и очистка вне цикла. Без сети; кэши ОС не сбрасывались.',
        'исходники': {('Инструменты/' + и): hashlib.sha256((ИНСТРУМЕНТЫ / и).read_bytes()).hexdigest() for и in имена},
        'повторы': повторы, 'медиана_цикла_нс': int(statistics.median(п['цикл_нс'] for п in повторы))}
    выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2, sort_keys=True) + '\n')
    print(json.dumps({'повторов': повторов, 'медиана_цикла_нс': результат['медиана_цикла_нс']}, ensure_ascii=False))


if __name__ == '__main__':
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--повторов', type=int, default=3)
    разбор.add_argument('--выход', type=Path, required=True)
    параметры = разбор.parse_args()
    if not 3 <= параметры.повторов <= 10 or параметры.выход.exists():
        разбор.error('Нужно 3–10 повторов и новый файл результата')
    выполнить(параметры.повторов, параметры.выход)
