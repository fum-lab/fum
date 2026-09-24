"""Профиль читающего приёма в новых процессах на открытой настоящей Git-истории."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import time

from фикстура_приёма_интеграции import фикстура, прочитать_холодно
import приём_интеграции as приём


def главная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход', type=Path, required=True)
    парсер.add_argument('--повторов', type=int, default=3)
    параметры = парсер.parse_args()
    if not 1 <= параметры.повторов <= 20:
        парсер.error('Нужно от 1 до 20 повторов')
    начало = time.perf_counter_ns()
    with фикстура() as пример:
        текст = приём.сформировать(пример['блок'])
        свидетельство = пример['отправить'](текст)
        подготовка = time.perf_counter_ns() - начало
        длительности, первый = [], None
        for _ in range(параметры.повторов):
            начало = time.perf_counter_ns()
            результат = прочитать_холодно(пример, текст, свидетельство)
            длительности.append(time.perf_counter_ns() - начало)
            if первый is None:
                первый = результат
            assert результат == первый and результат['разрешение_записи'] is False
        код = {str(п.relative_to(пример['корень'])): hashlib.sha256(п.read_bytes()).hexdigest() for п in приём.КОД}
        профиль = {'схема': 'fum.профиль-приёма-интеграции.1', 'подготовка_нс': подготовка,
            'длительности_нс': длительности, 'медиана_нс': statistics.median(длительности),
            'исходники': код, 'байтов_нативного_входа': пример['источник'].stat().st_size,
            'граница': 'Каждый повтор включает новый Python-процесс, импорт из C, подготовку частного JSON-входа '
                'и полный читающий допуск. Создание Git-фикстуры измерено отдельно; кэш ОС не очищается. '
                'Нативный транспорт синтетический. Нет реального Desktop, слияния получателя или разрешения записи.'}
    with параметры.выход.open('x', encoding='utf-8') as файл:
        json.dump(профиль, файл, ensure_ascii=False, indent=2)
        файл.write('\n')
    print(json.dumps({к: з for к, з in профиль.items() if к != 'исходники'}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
