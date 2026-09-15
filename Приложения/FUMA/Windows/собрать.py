"""Нативная Windows-сборка общего Swift-пакета с явным профилем и точным выходом."""
import argparse
import hashlib
import json
import pathlib
import platform
import subprocess
import sys
import time


ТРОЙКИ = {'arm64': 'aarch64-unknown-windows-msvc', 'x64': 'x86_64-unknown-windows-msvc'}


def план(пакет, кэш, выход, продукт, архитектура, определение, вход, контейнер):
    if архитектура not in ТРОЙКИ:
        raise ValueError('Неподдержанная архитектура')
    общие = ['--package-path', str(пакет), '--scratch-path', str(кэш), '--configuration', 'release', '--triple', ТРОЙКИ[архитектура]]
    return [
        ['swift', 'test', *общие],
        ['swift', 'build', *общие, '--product', продукт],
        ['swift', 'run', *общие, '--skip-build', продукт, str(определение), str(вход), str(контейнер), str(выход)],
    ]


def проверить_среду(система, машина, тройка, архитектура):
    if система != 'Windows':
        raise ValueError('Исполнение требует настоящей Windows')
    соответствия = {'arm64': 'arm64', 'aarch64': 'arm64', 'amd64': 'x64', 'x86_64': 'x64'}
    if соответствия.get(машина.lower()) != архитектура or ТРОЙКИ.get(архитектура) != тройка:
        raise ValueError('Несовпадение архитектур ОС, процесса, Swift и профиля')


def сверить(файл, ожидаемый):
    данные = pathlib.Path(файл).read_bytes()
    if hashlib.sha256(данные).hexdigest() != ожидаемый:
        raise ValueError('SHA-256 выходных байтов не совпал')
    return len(данные)


def исполнить(команды, исполнитель):
    профиль = []
    for номер, команда in enumerate(команды):
        начало = time.perf_counter_ns()
        исполнитель(команда)
        профиль.append({'этап': номер + 1, 'длительность_нс': time.perf_counter_ns() - начало})
    return профиль


def главный():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--пакет', type=pathlib.Path, required=True)
    парсер.add_argument('--кэш', type=pathlib.Path, required=True)
    парсер.add_argument('--выход', type=pathlib.Path, required=True)
    парсер.add_argument('--контейнер', type=pathlib.Path, required=True)
    парсер.add_argument('--определение', type=pathlib.Path, required=True)
    парсер.add_argument('--вход', type=pathlib.Path, required=True)
    парсер.add_argument('--продукт', required=True)
    парсер.add_argument('--архитектура', choices=ТРОЙКИ, required=True)
    парсер.add_argument('--коммит', required=True)
    парсер.add_argument('--версия-компилятора', required=True)
    парсер.add_argument('--исполнить', action='store_true')
    параметры = парсер.parse_args()
    команды = план(параметры.пакет, параметры.кэш, параметры.выход, параметры.продукт, параметры.архитектура, параметры.определение, параметры.вход, параметры.контейнер)
    if not параметры.исполнить:
        print(json.dumps({'схема': 'fum.windows.план.1', 'команды': команды, 'исполнено': False}, ensure_ascii=False, indent=2))
        return
    if platform.system() != 'Windows':
        raise ValueError('Исполнение требует настоящей Windows')
    корень = pathlib.Path(subprocess.check_output(['git', '-C', str(параметры.пакет), 'rev-parse', '--show-toplevel'], text=True).strip()).resolve()
    текущий = subprocess.check_output(['git', '-C', str(корень), 'rev-parse', 'HEAD'], text=True).strip()
    if текущий != параметры.коммит or len(текущий) != 40:
        raise ValueError('Не совпал точный исходный коммит')
    if subprocess.check_output(['git', '-C', str(корень), 'status', '--porcelain'], text=True).strip():
        raise ValueError('Для воспроизведения требуется чистый исходный checkout')
    каталоги = [параметры.кэш.resolve(), параметры.выход.resolve(), параметры.контейнер.resolve()]
    for каталог in каталоги:
        if каталог.resolve().is_relative_to(корень) or каталог.exists():
            raise ValueError('Нужны новые независимые каталоги вне исходного checkout')
    if any(левый.is_relative_to(правый) for номер, левый in enumerate(каталоги) for другой, правый in enumerate(каталоги) if номер != другой):
        raise ValueError('Каталоги сборки, контейнера и выхода не должны пересекаться')
    if параметры.вход.read_bytes() != bytes.fromhex('0041d191f09f8ebb'):
        raise ValueError('Вход не совпал с открытой фикстурой общего сценария')
    if not параметры.определение.resolve().is_relative_to(корень) or not параметры.определение.is_file():
        raise ValueError('Определение должно принадлежать закреплённому checkout')
    цель = json.loads(subprocess.check_output(['swift', '-print-target-info'], text=True))
    проверить_среду(platform.system(), platform.machine(), цель['target']['triple'], параметры.архитектура)
    if цель['compilerVersion'] != параметры.версия_компилятора:
        raise ValueError('Не совпала закреплённая версия Swift')
    параметры.выход.mkdir(parents=True)
    параметры.контейнер.mkdir(parents=True)
    def выполнить(команда):
        subprocess.run(команда, check=True, timeout=900, stdout=sys.stderr)
    профиль = исполнить(команды, выполнить)
    ожидаемый = hashlib.sha256(bytes.fromhex('000000004100000051040000bbf30100')).hexdigest()
    число = сверить(параметры.выход / 'выход.bin', ожидаемый)
    сверить(параметры.выход / 'повтор.bin', ожидаемый)
    print(json.dumps({'схема': 'fum.windows.результат.1', 'коммит': текущий, 'тройка': цель['target']['triple'], 'компилятор': цель['compilerVersion'], 'байты': число, 'sha256': ожидаемый, 'повтор_совпал': True, 'профиль': профиль}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    главный()
