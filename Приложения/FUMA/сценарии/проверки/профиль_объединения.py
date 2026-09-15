#!/usr/bin/env python3
"""Сборка, XCTest, ресурсы и CLI до/после на независимом временном наборе."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import time
from test_объединение_пакетов import ПакетыTests, СЦЕНАРИЙ


def выполнить():
    фикстура = ПакетыTests(); фикстура.setUp()
    измерения = []
    def измерить(имя, действие):
        начало = time.perf_counter_ns(); результат = действие()
        измерения.append({'стадия': имя, 'наносекунды': time.perf_counter_ns() - начало})
        return результат
    def swift(*аргументы):
        процесс = subprocess.run(['swift', *аргументы], cwd=фикстура.корень, capture_output=True, timeout=180)
        if процесс.returncode:
            raise RuntimeError(процесс.stderr.decode(errors='replace'))
        return процесс.stdout
    try:
        измерить('XCTest до', lambda: swift('test', '--package-path', 'Геометрия', '--scratch-path', 'сборка-тестов-до', '--build-system', 'native', '--jobs', '2'))
        до = измерить('CLI и ресурсы до', lambda: swift('run', '--package-path', 'Рисунок', '--scratch-path', 'сборка-до', '--build-system', 'native', '--jobs', '2', 'рисунок'))
        планы = [измерить('План ' + str(номер), фикстура.план) for номер in range(3)]
        assert планы[0] == планы[1] == планы[2]
        план = планы[0]; модуль = фикстура.м; корень = фикстура.корень
        измерить('Каталоги', lambda: модуль.подготовить_каталоги(корень, план, план['sha256']))
        перенос = измерить('План ссылок', lambda: модуль.план_переноса(корень, план, план['sha256']))
        измерить('Перенос', lambda: модуль.перенести(корень, план, план['sha256'], перенос['sha256']))
        измерить('Установка manifest', lambda: модуль.завершить(корень, план, план['sha256']))
        измерить('Повтор установки', lambda: модуль.завершить(корень, план, план['sha256']))
        измерить('XCTest после', lambda: swift('test', '--package-path', 'Общее', '--scratch-path', 'сборка-тестов-после', '--build-system', 'native', '--jobs', '2'))
        после = измерить('CLI и ресурсы после', lambda: swift('run', '--package-path', 'Общее', '--scratch-path', 'сборка-после', '--build-system', 'native', '--jobs', '2', 'рисунок'))
        assert до == после == '7:синий:круг\n'.encode()
        return {'схема': 'fum.профиль-объединения.1', 'результат': 'успешно', 'пакеты': ['Геометрия', 'Палитра', 'Рисунок'],
                'перемещения': len(план['пакет']['перемещения']), 'ссылки': перенос['ссылки'], 'измерения': измерения,
                'выход': после.decode(), 'выход_sha256': hashlib.sha256(после).hexdigest(),
                'манифест': план['манифест'], 'исходники_sha256': {п.name: hashlib.sha256(п.read_bytes()).hexdigest() for п in [СЦЕНАРИЙ, Path(__file__), Path(__file__).with_name('test_объединение_пакетов.py')]},
                'граница': 'Три последовательных плана; сборки отдельно с разными scratch-каталогами. Кэш ОС не очищен; подготовки фикстуры нет во времени. Это корректность и наблюдённое время, не сравнение ускорения.'}
    finally:
        фикстура.doCleanups()


if __name__ == '__main__':
    разбор = argparse.ArgumentParser(description=__doc__); разбор.add_argument('--выход', type=Path, required=True)
    параметры = разбор.parse_args()
    результат = выполнить()
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(результат, ensure_ascii=False))
