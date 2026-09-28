"""Повторяемый конечный профиль наполнения; JSON сохраняется вне checkout."""
from pathlib import Path
import json
import platform
import statistics
import subprocess
import sys
import time
from unittest import mock

sys.path.insert(0, str(Path(__file__).parent))
from test_наполнения_карточки import ПроверкаНаполненияКарточки


def главная():
    if len(sys.argv) != 2:
        raise ValueError('Нужен один новый внешний путь для профиля')
    файл = Path(sys.argv[1])
    начало = time.perf_counter_ns()
    фикстура = ПроверкаНаполненияКарточки()
    фикстура.setUp()
    try:
        модуль = фикстура.модуль
        корень = Path(__file__).resolve().parents[3]
        if (not файл.is_absolute() or файл != файл.resolve() or файл.is_relative_to(корень)
                or not файл.parent.is_dir() or файл.exists()
                or any(п.is_symlink() or (п / '.git').exists() for п in файл.parents)):
            raise ValueError('Профиль должен иметь свободный точный путь вне checkout')
        охват = модуль._загрузить('охват')
        настоящий_git = охват.выполнить_git
        вызовы_git = []
        def выполнить_git(корень, *аргументы):
            старт = time.perf_counter_ns()
            try:
                return настоящий_git(корень, *аргументы)
            finally:
                вызовы_git.append({'команда': аргументы[0], 'длительность_нс': time.perf_counter_ns() - старт})
        измерения = []
        def измерить(имя, действие):
            профиль = {}
            старт = time.perf_counter_ns()
            результат = действие(профиль)
            измерения.append({'этап': имя, 'длительность_нс': time.perf_counter_ns() - старт,
                              'точки': профиль})
            return результат
        исходный = фикстура.снимок()
        with mock.patch.object(охват, 'выполнить_git', side_effect=выполнить_git):
            for _ in range(5):
                план = измерить('подготовить', lambda п: модуль.подготовить(фикстура.корень, фикстура.вход, профиль=п))
            assert фикстура.снимок() == исходный
            измерить('применить', lambda п: модуль.применить(фикстура.корень, фикстура.вход, план, профиль=п))
            установленный = фикстура.снимок()
            метаданные = [(п.stat().st_ino, п.stat().st_mtime_ns) for п in (фикстура.запрос, фикстура.отчёт)]
            for _ in range(5):
                assert измерить('повторить', lambda п: модуль.применить(фикстура.корень, фикстура.вход, план, профиль=п))['изменено'] == 0
            for _ in range(5):
                assert измерить('неизменный-предпросмотр', lambda п: модуль.подготовить(фикстура.корень, фикстура.вход, профиль=п))['файлы'] == []
            assert фикстура.снимок() == установленный
            assert метаданные == [(п.stat().st_ino, п.stat().st_mtime_ns) for п in (фикстура.запрос, фикстура.отчёт)]
        сводка = {}
        for имя in dict.fromkeys(э['этап'] for э in измерения):
            времена = [э['длительность_нс'] for э in измерения if э['этап'] == имя]
            сводка[имя] = {'измерений': len(времена), 'медиана_нс': statistics.median(времена),
                          'минимум_нс': min(времена), 'максимум_нс': max(времена)}
        вход = {**фикстура.вход, 'разрешение': {**фикстура.вход['разрешение'], 'путь': '<внешний-файл-разрешения>'}}
        данные = {'схема': 'fum.профиль-наполнения-карточки.1',
                  'исходный_HEAD': subprocess.check_output(['git', '-C', str(корень), 'rev-parse', 'HEAD'], text=True).strip(),
                  'исполнитель': план['зависимости']['исполнитель'], 'шаблоны': план['зависимости']['шаблоны'],
                  'сценарий': {п.relative_to(корень).as_posix(): модуль.хэш(п.read_bytes())
                               for п in (Path(__file__).resolve(), Path(__file__).with_name('test_наполнения_карточки.py').resolve())},
                  'версия_Python': platform.python_version(), 'версия_Git': subprocess.check_output(['git', '--version'], text=True).strip(),
                  'архитектура': platform.machine(), 'версия_macOS': platform.mac_ver()[0],
                  'вход_sha256': модуль.хэш(модуль.блоки.канонические_байты(вход)),
                  'сводка': сводка, 'измерения': измерения, 'вызовы_Git': вызовы_git,
                  'календарная_длительность_нс': time.perf_counter_ns() - начало,
                  'ограничение': 'Открытая синтетическая пара. Вызовы Git обёрнуты монотонным таймером. Это не замер полного Codex-цикла или экономии токенов.'}
        with файл.open('xb') as поток:
            поток.write(json.dumps(данные, ensure_ascii=False, indent=2).encode() + b'\n')
        print(json.dumps({'сводка': сводка, 'вызовов_Git': len(вызовы_git),
                          'суммарное_время_Git_нс': sum(э['длительность_нс'] for э in вызовы_git)}, ensure_ascii=False))
    finally:
        фикстура.doCleanups()


if __name__ == '__main__':
    главная()
