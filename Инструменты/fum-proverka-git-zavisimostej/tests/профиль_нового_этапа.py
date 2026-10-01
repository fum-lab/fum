"""Малый профиль перехода и готового повтора в открытых локальных фикстурах."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time

from test_новый_этап_подготовки import ПроверкиНовогоЭтапа


def измерить(повторов):
    переходы, повторы = [], []
    for _ in range(повторов):
        сценарий = ПроверкиНовогоЭтапа()
        try:
            сценарий.setUp()
            сценарий.подготовить_процессом()
            прежние = сценарий.квитанция().read_bytes()
            хэш = hashlib.sha256(прежние).hexdigest()
            снимок = сценарий.следующая_граница()
            журнал = (сценарий.фикстура.root / 'вызовы-init.jsonl').read_bytes()
            начало = time.perf_counter_ns()
            итог = сценарий.перейти_через_команду(снимок, хэш)
            переходы.append((time.perf_counter_ns() - начало) / 1e9)
            сценарий.assertEqual(0, итог.returncode, итог.stderr + итог.stdout)
            сценарий.assertTrue(json.loads(итог.stdout)['попытка_создана'])
            сценарий.assertEqual(прежние, сценарий.архив(хэш).read_bytes())
            сценарий.подготовить_процессом()
            активная = сценарий.квитанция().read_bytes()
            начало = time.perf_counter_ns()
            сценарий.подготовить_процессом()
            повторы.append((time.perf_counter_ns() - начало) / 1e9)
            сценарий.assertEqual(активная, сценарий.квитанция().read_bytes())
            сценарий.assertEqual(журнал, (сценарий.фикстура.root / 'вызовы-init.jsonl').read_bytes())
            сценарий.assertEqual(прежние, сценарий.архив(хэш).read_bytes())
            сценарий.assertEqual(снимок, сценарий.модуль.снять_снимок(сценарий.корень))
        finally:
            сценарий.doCleanups()
    return {'схема': 'fum.профиль-нового-этапа-зависимостей.1', 'повторов': повторов,
            'границы': 'Включены запуск отдельного Python-процесса, чтения Git и запись входного JSON снимка; повтор включает также снятие защитного снимка. Создание фикстуры, исходная подготовка, первая финализация после перехода и запись результата исключены. Кэш ОС не очищается.',
            'переход_секунды': переходы, 'готовый_повтор_секунды': повторы,
            'медиана_перехода': statistics.median(переходы),
            'медиана_готового_повтора': statistics.median(повторы),
            'сохранность_и_отсутствие_init': True}


if __name__ == '__main__':
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--повторов', type=int, default=3)
    разбор.add_argument('--выход', type=Path, required=True)
    параметры = разбор.parse_args()
    if параметры.повторов < 1:
        разбор.error('нужно положительное число повторов')
    результат = измерить(параметры.повторов)
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, sort_keys=True, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
