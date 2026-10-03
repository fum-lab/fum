"""Адресный составной исполнитель: воспроизводимость, Swift-тесты и три парных замера."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import subprocess
import tempfile
import time

КОРЕНЬ = Path(__file__).resolve().parents[1]


def основная():
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--кэш', type=Path, required=True)
    разбор.add_argument('--выход', type=Path, required=True)
    параметры = разбор.parse_args()
    if параметры.выход.exists():
        raise SystemExit('Результат не перезаписывается')
    if параметры.кэш.resolve().is_relative_to(КОРЕНЬ.parents[3]):
        raise SystemExit('Кэш сборки должен находиться вне checkout')
    subprocess.run(['python3', '-B', str(КОРЕНЬ / 'Сценарии/собрать-определение.py'), '--проверить'], check=True)
    начало = time.perf_counter_ns()
    subprocess.run(['swift', 'test', '--package-path', str(КОРЕНЬ), '--scratch-path', str(параметры.кэш), '-j', '2'], check=True)
    проверка = time.perf_counter_ns() - начало
    начало = time.perf_counter_ns()
    subprocess.run(['swift', 'build', '--package-path', str(КОРЕНЬ), '--scratch-path', str(параметры.кэш), '-j', '2', '-c', 'release', '--product', 'Klaviatura'], check=True)
    сборка = time.perf_counter_ns() - начало
    ответ = subprocess.check_output(['swift', 'build', '--package-path', str(КОРЕНЬ), '--scratch-path', str(параметры.кэш), '-c', 'release', '--show-bin-path'], text=True)
    программа = Path(ответ.strip()) / 'Klaviatura'
    вход = КОРЕНЬ / 'Фикстуры/последовательность-профиля.json'
    пары = []
    последняя = None
    with tempfile.TemporaryDirectory(prefix='klaviatura-профиль-') as временное:
        for номер in range(3):
            измерения = {}
            данныеПары = {}
            for режим in (['эталон', 'FUMA'] if номер % 2 == 0 else ['FUMA', 'эталон']):
                выход = Path(временное) / (str(номер) + '-' + режим + '.json')
                начало = time.perf_counter_ns()
                subprocess.run([str(программа), '--режим', режим, '--определение', str(КОРЕНЬ / 'определение.json'), '--вход', str(вход), '--выход', str(выход)], check=True)
                полный = time.perf_counter_ns() - начало
                результат = json.loads(выход.read_text())
                данныеПары[режим] = результат
                измерения[режим] = {'полный_процесс_нс': полный, **результат['профиль']}
            if данныеПары['FUMA']['входы'] != данныеПары['эталон']['входы'] or данныеПары['FUMA']['выходы'] != данныеПары['эталон']['выходы']:
                raise SystemExit('FUMA расходится с независимым Swift-эталоном')
            пары.append(измерения)
            последняя = данныеПары['FUMA']
    файлы = ['Package.swift', 'определение.json', 'таблица-раскладки.json', 'Фикстуры/переходы.json', 'Фикстуры/последовательность-профиля.json', 'Сценарии/собрать-определение.py', 'Sources/ЭталонКлавиатуры/Эталон.swift', 'Sources/ИсполнительКлавиатуры/main.swift', 'Tests/ПроверкиКлавиатуры/ПроверкиПереходов.swift', 'Проверки/проверить-и-измерить.py']
    библиотека = КОРЕНЬ.parents[3] / 'Прототипы/память-структурирующих-операторов'
    хэшиБиблиотеки = {файл.relative_to(библиотека).as_posix(): hashlib.sha256(файл.read_bytes()).hexdigest() for файл in sorted(библиотека.rglob('*')) if файл.is_file() and (файл.suffix in {'.swift', '.json'}) and not any(часть.startswith('.') for часть in файл.relative_to(библиотека).parts)}
    результат = {'схема': 'klaviatura.профиль.1', 'статус': 'измерен', 'условия': {'система': platform.system(), 'архитектура': platform.machine(), 'Swift': subprocess.check_output(['swift', '--version'], text=True).strip(), 'процессов_сборки': 2, 'пар': 3, 'прогрев': 'один переход вне внутреннего таймера', 'память': 'пик RSS отдельного процесса; включает запуск, разбор и переходы'}, 'sha256': {имя: hashlib.sha256((КОРЕНЬ / имя).read_bytes()).hexdigest() for имя in файлы}, 'библиотека_FUMA_sha256': хэшиБиблиотеки, 'тесты_нс': проверка, 'сборка_release_нс': сборка, 'пары': пары, 'полный_вход': последняя['входы'], 'полный_выход': последняя['выходы'], 'нативные_наблюдения': последняя['наблюдения'], 'совпадение': True, 'оптимизация': {'статус': 'требуется решение по измерениям', 'основание': 'Парные значения сохранены; ускорение полного приложения этим сценарием не измеряется'}}
    результат['бинарник_sha256'] = hashlib.sha256(программа.read_bytes()).hexdigest()
    параметры.выход.write_text(json.dumps(результат, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    основная()
