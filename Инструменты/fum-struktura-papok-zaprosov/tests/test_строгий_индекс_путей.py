"""Малый различающий корпус; зависимости всегда из цельного C573.

CLI --основа/--код выбирает неизменную основу и отдельный проверяемый контур.
Каждый работник имеет свежие импорты и собственную Git-фикстуру.
"""
import argparse
from contextlib import ExitStack
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import resource
import stat
import subprocess
import sys
import time
import tempfile
import tracemalloc
import unittest
import unicodedata
from unittest.mock import patch

ПРЕДМЕТ = 'Инструменты/fum-struktura-papok-zaprosov'
БАЗА = 'bac942c7bf9f0d6f68290ddc1fa12ea632d5bd76'
ПАРАМЕТРЫ = argparse.Namespace(основа=None, код=Path(__file__).resolve().parents[3])


def загрузить(основа, код):
    голова = subprocess.check_output(['git', '-C', str(основа), 'rev-parse', 'HEAD'], text=True).strip()
    if голова != БАЗА:
        raise ValueError('нужна цельная основа C573')
    sys.path[:0] = [str(код / ПРЕДМЕТ / 'scripts'), str(основа / ПРЕДМЕТ / 'tests')]
    import test_установки_принятого_состава_журнала as фикстуры
    модуль = фикстуры.загрузить_установщик(код)
    фикстуры.КОРЕНЬ = код
    фикстуры.ИСХОДНИКИ = модуль.ИСХОДНИКИ
    фикстуры.загрузить_установщик = lambda: модуль
    return фикстуры, модуль


def отпечаток_кода(код, модуль):
    return {имя: hashlib.sha256((код / имя).read_bytes()).hexdigest() for имя in модуль.ИСХОДНИКИ}


def корпус(фикстура, количество):
    запрос = next((фикстура.корень / 'Журнал').glob('*/запрос.md'))
    каталог = запрос.parent / 'материалы' / 'корпус'
    каталог.mkdir(parents=True, exist_ok=True)
    for номер in range(количество):
        (каталог / ('файл-%04d.txt' % номер)).write_bytes(('строка %04d\n' % номер).encode())
    фикстура.основа.commit()
    принято = фикстура.основа.git('rev-parse', 'HEAD').stdout.strip()
    return каталог, принято, отпечаток_корпуса(фикстура.корень)


def отпечаток_корпуса(корень):
    манифест = [(п.relative_to(корень).as_posix(), stat.S_IFMT(п.lstat().st_mode),
        stat.S_IMODE(п.lstat().st_mode), hashlib.sha256(п.read_bytes()).hexdigest() if п.is_file() else None)
        for п in sorted((корень / 'Журнал').rglob('*'))]
    return hashlib.sha256(json.dumps(манифест, ensure_ascii=False).encode()).hexdigest()


def работник(параметры):
    начало_подготовки = time.perf_counter_ns()
    фикстуры, модуль = загрузить(параметры.основа, параметры.код)
    if параметры.работник == 'границы':
        return границы(фикстуры, модуль, параметры)
    фикстура = фикстуры.Фикстура(материал_0600=True)
    try:
        каталог, принято, вход = корпус(фикстура, параметры.файлов)
        до = отпечаток_кода(параметры.код, модуль)
        подготовка = time.perf_counter_ns() - начало_подготовки
        сценарий = параметры.работник
        if сценарий == 'байты':
            next(каталог.iterdir()).write_bytes(b'changed')
        elif сценарий == 'режим':
            next(каталог.iterdir()).chmod(0o777)
        elif сценарий == 'ссылка':
            путь = next(каталог.iterdir()); путь.unlink(); путь.symlink_to('/dev/null')
        elif сценарий == 'hardlink':
            os.link(next(каталог.iterdir()), каталог / 'дубликат')
        elif сценарий == 'добавление':
            (каталог / 'чужой').write_bytes(b'x')
        elif сценарий == 'удаление':
            next(каталог.iterdir()).unlink()
        elif сценарий == 'переименование':
            next(каталог.iterdir()).rename(каталог / 'другое')
        elif сценарий == 'fifo':
            os.mkfifo(каталог / 'особый')
        счётчики = {'listing': 0, 'normalization': 0, 'stat': 0, 'bytes': 0, 'Git': 0,
            'перечислений_Path': 0, 'ключей': 0, 'байтов_Git': 0}
        перечислить = Path.iterdir; ключ = модуль.контракт.ключ_коллизии
        нормализовать = unicodedata.normalize; сканировать = os.scandir
        стат = os.stat; лстат = os.lstat; читать = Path.read_bytes; гит = модуль.журнал._гит
        def перечисление(путь):
            счётчики['перечислений_Path'] += 1
            дети = перечислить(путь)
            if сценарий == 'case' and путь == фикстура.корень:
                return iter([*дети, путь / 'журнал'])
            return дети
        def нормализация(имя):
            счётчики['ключей'] += 1
            return ключ(имя)
        def нормализовать_юникод(*аргументы):
            счётчики['normalization'] += 1; return нормализовать(*аргументы)
        def перечислить_каталог(*аргументы):
            счётчики['listing'] += 1; return сканировать(*аргументы)
        def метаданные(*аргументы, **именованные):
            счётчики['stat'] += 1
            return стат(*аргументы, **именованные)
        def лметаданные(*аргументы, **именованные):
            счётчики['stat'] += 1
            return лстат(*аргументы, **именованные)
        изменено = False
        def байты(путь):
            nonlocal изменено
            данные = читать(путь); счётчики['bytes'] += len(данные)
            if сценарий == 'дрейф' and путь.parent == каталог and not изменено:
                (каталог / ('файл-%04d.txt' % (параметры.файлов - 1))).rename(каталог / 'поздний')
                изменено = True
            return данные
        def команда(*аргументы, **именованные):
            счётчики['Git'] += 1
            данные = гит(*аргументы, **именованные); счётчики['байтов_Git'] += len(данные); return данные
        with ExitStack() as стек:
            for объект, имя, замена in [(Path, 'iterdir', перечисление), (модуль.контракт, 'ключ_коллизии', нормализация),
                    (unicodedata, 'normalize', нормализовать_юникод), (os, 'scandir', перечислить_каталог),
                    (os, 'stat', метаданные), (os, 'lstat', лметаданные),
                    (Path, 'read_bytes', байты), (модуль.журнал, '_гит', команда)]:
                стек.enter_context(patch.object(объект, имя, замена))
            tracemalloc.start()
            начало = time.perf_counter_ns(); процессор = time.process_time_ns()
            исход = 'успех'; результат = None
            try:
                результат = модуль.проверить_журнал(фикстура.корень, принято)
            except (ValueError, OSError) as ошибка:
                исход = 'отказ'; результат = type(ошибка).__name__
            длительность = time.perf_counter_ns() - начало
            процессорное = time.process_time_ns() - процессор
            _, память = tracemalloc.get_traced_memory(); tracemalloc.stop()
        после = отпечаток_кода(параметры.код, модуль)
        assert до == после
        return {'исход': исход, 'сценарий': сценарий, 'результат': результат, 'счётчики': счётчики,
            'вход_sha256': вход,
            'вход_после_sha256': отпечаток_корпуса(фикстура.корень) if сценарий == 'успех' else None,
            'код_до': до, 'код_после': после, 'setup_ns': подготовка,
            'wall_ns': длительность, 'CPU_ns': процессорное, 'python_peak_bytes': память,
            'maxRSS': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
            'память_единица': 'байт на macOS; КиБ на Linux', 'память_граница': 'максимум процесса, включает setup'}
    finally:
        фикстура.закрыть()


def границы(фикстуры, модуль, параметры):
    фикстура = фикстуры.Фикстура(материал_0600=True)
    try:
        счёт = {'полные': 0, 'mixed': 0}
        полный = модуль.проверить_журнал; смешанный = модуль.журнал.проверить_смешанный
        def проход(*аргументы, **именованные):
            счёт['полные'] += 1; return полный(*аргументы, **именованные)
        def смешанный_проход(*аргументы, **именованные):
            счёт['mixed'] += 1; return смешанный(*аргументы, **именованные)
        with patch.object(модуль, 'проверить_журнал', проход), patch.object(модуль.журнал, 'проверить_смешанный', смешанный_проход):
            план = фикстура.план()
            план_счёт = dict(счёт)
            счёт.update(полные=0, mixed=0)
            if параметры.установка:
                итог = модуль.применить(план, фикстура.выбор, фикстура.каталог)
                return {'план': план_счёт, 'apply': счёт, 'итог': итог}
            вход = фикстура.приватный / 'работник-lab.json'
            вход.write_text(json.dumps({'план': план, 'выбор': фикстура.выбор, 'каталог': str(фикстура.каталог)}))
            процесс = subprocess.Popen([sys.executable, '-B', str(Path(__file__).resolve()),
                '--основа', str(параметры.основа), '--код', str(параметры.код), '--установить', str(вход)],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            вывод, ошибка = процесс.communicate(timeout=90)
            assert процесс.returncode == 0, ошибка
            установка = json.loads(вывод)
            завершение = фикстура.завершение(процесс)
            результат = модуль.повтор(план, фикстура.выбор, фикстура.каталог, завершение)
            return {'план': план_счёт, 'apply': установка, 'replay': dict(счёт), 'результат': результат}
    finally:
        фикстура.закрыть()


def вызвать(основа, код, сценарий='успех', файлов=24):
    процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--основа', str(основа),
        '--код', str(код), '--работник', сценарий, '--файлов', str(файлов)], capture_output=True, text=True)
    if процесс.returncode:
        raise AssertionError(процесс.stderr[-5000:])
    return json.loads(процесс.stdout)


class СтрогийИндекс(unittest.TestCase):
    def test_локальное_состояние_не_становится_входом(сам):
        путь = ПАРАМЕТРЫ.код / ПРЕДМЕТ / 'scripts/строгий_индекс_путей.py'
        описание = importlib.util.spec_from_file_location('проверяемый_индекс', путь)
        индекс = importlib.util.module_from_spec(описание); описание.loader.exec_module(индекс)
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve(); (корень / '.obsidian').mkdir()
            (корень / 'Индексы' / 'локальное').mkdir(parents=True)
            перечислить = Path.iterdir
            def перечисление(путь):
                if путь == корень / 'Индексы' / 'локальное':
                    raise PermissionError('неуправляемая непрочитываемая область')
                return перечислить(путь)
            with сам.subTest(граница='локальный graph'):
                with индекс.ИндексПутей(корень, str.casefold):
                    (корень / '.obsidian' / 'graph.json').write_bytes(b'{}')
            with сам.subTest(граница='неуправляемое вложение индексов'):
                with patch.object(Path, 'iterdir', перечисление):
                    with индекс.ИндексПутей(корень, str.casefold):
                        pass

    def test_повторное_перечисление(сам):
        if ПАРАМЕТРЫ.основа is None: сам.skipTest('для парного LAB-сценария нужны явные --основа/--код')
        итог = вызвать(ПАРАМЕТРЫ.основа, ПАРАМЕТРЫ.код)
        сам.assertEqual(итог['исход'], 'успех')
        сам.assertLessEqual(итог['счётчики']['listing'], 60, итог['счётчики'])

    def test_прежние_положительные_и_отрицательные_исходы(сам):
        if ПАРАМЕТРЫ.основа is None: сам.skipTest('для парного LAB-сценария нужны явные --основа/--код')
        for сценарий in ('успех', 'байты', 'режим', 'ссылка', 'hardlink', 'добавление', 'удаление', 'переименование', 'fifo', 'case', 'дрейф'):
            with сам.subTest(сценарий=сценарий):
                прежний = вызвать(ПАРАМЕТРЫ.основа, ПАРАМЕТРЫ.основа, сценарий)
                новый = вызвать(ПАРАМЕТРЫ.основа, ПАРАМЕТРЫ.код, сценарий)
                сам.assertEqual(прежний['исход'], новый['исход'])
                сам.assertEqual(новый['исход'], 'успех' if сценарий == 'успех' else 'отказ')
                сам.assertEqual(прежний['вход_sha256'], новый['вход_sha256'])

    def test_все_полные_проходы_и_независимый_повтор(сам):
        if ПАРАМЕТРЫ.основа is None: сам.skipTest('для парного LAB-сценария нужны явные --основа/--код')
        итог = вызвать(ПАРАМЕТРЫ.основа, ПАРАМЕТРЫ.код, 'границы')
        сам.assertEqual(итог['план'], {'полные': 2, 'mixed': 0})
        сам.assertEqual(итог['apply']['полные'], 14)
        сам.assertEqual(итог['apply']['mixed'], 1)
        сам.assertEqual(итог['replay'], {'полные': 2, 'mixed': 1})
        сам.assertEqual(итог['результат']['записей'], 0)

    def test_одноразовый_индекс_и_дрейф_всего_пространства_имён(сам):
        путь = ПАРАМЕТРЫ.код / ПРЕДМЕТ / 'scripts/строгий_индекс_путей.py'
        описание = importlib.util.spec_from_file_location('проверяемый_индекс', путь)
        индекс = importlib.util.module_from_spec(описание); описание.loader.exec_module(индекс)
        import unicodedata
        ключ = lambda имя: unicodedata.normalize('NFC', имя).casefold()
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve(); (корень / 'Журнал').mkdir()
            файл = корень / 'Журнал' / 'текст'; файл.write_bytes(b'a')
            for действие in ('добавить', 'удалить', 'rename', 'inode', 'mode', 'nlink', 'symlink', 'байты'):
                with сам.subTest(действие=действие):
                    снимок = индекс.ИндексПутей(корень, ключ)
                    if действие == 'добавить': (корень / 'Журнал' / 'поздний').mkdir()
                    elif действие == 'удалить': файл.unlink()
                    elif действие == 'rename': файл.rename(файл.with_name('новый'))
                    elif действие == 'inode':
                        новый = файл.with_name('другой'); новый.write_bytes(b'a'); новый.replace(файл)
                    elif действие == 'mode': файл.chmod(0o600)
                    elif действие == 'nlink': os.link(файл, файл.with_name('ссылка'))
                    elif действие == 'symlink': файл.unlink(); файл.symlink_to('/dev/null')
                    elif действие == 'байты': файл.write_bytes(b'b')
                    with сам.assertRaises((ValueError, OSError)): снимок.проверить()
                    for п in (корень / 'Журнал').iterdir():
                        п.rmdir() if п.is_dir() else п.unlink()
                    файл.write_bytes(b'a'); файл.chmod(0o644)
            снимок = индекс.ИндексПутей(корень, ключ)
            with снимок:
                сам.assertEqual(снимок.совпадения(корень, 'Журнал'), ['Журнал'])
            with сам.assertRaises(ValueError): снимок.совпадения(корень, 'Журнал')
            # Полные exact/case/NFC группы проверяются и на ФС, не допускающей
            # физического сосуществования таких имён. Модель listing явна.
            исходный = Path.iterdir
            def имена(путь):
                if путь == корень:
                    return iter([корень / 'Журнал', корень / 'журнал', корень / 'é', корень / 'e\u0301'])
                return исходный(путь)
            with patch.object(Path, 'iterdir', имена):
                снимок = индекс.ИндексПутей(корень, ключ)
                сам.assertEqual(set(снимок.совпадения(корень, 'Журнал')), {'Журнал', 'журнал'})
                сам.assertEqual(set(снимок.совпадения(корень, 'é')), {'é', 'e\u0301'})
            сам.assertEqual(ключ('é'), ключ('e\u0301'))


def разобрать_аргументы():
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--основа', type=Path, required=True)
    разбор.add_argument('--код', type=Path, required=True)
    разбор.add_argument('--работник')
    разбор.add_argument('--файлов', type=int, default=24)
    разбор.add_argument('--только-red', action='store_true')
    разбор.add_argument('--проверка')
    разбор.add_argument('--установить', type=Path)
    разбор.add_argument('--установка', action='store_true')
    return разбор.parse_args()


if __name__ == '__main__':
    ПАРАМЕТРЫ = разобрать_аргументы()
    if ПАРАМЕТРЫ.установить:
        _, модуль = загрузить(ПАРАМЕТРЫ.основа, ПАРАМЕТРЫ.код)
        данные = json.loads(ПАРАМЕТРЫ.установить.read_bytes())
        счёт = {'полные': 0, 'mixed': 0}
        полный = модуль.проверить_журнал; смешанный = модуль.журнал.проверить_смешанный
        def полный_проход(*аргументы, **именованные):
            счёт['полные'] += 1; return полный(*аргументы, **именованные)
        def смешанный_проход(*аргументы, **именованные):
            счёт['mixed'] += 1; return смешанный(*аргументы, **именованные)
        with patch.object(модуль, 'проверить_журнал', полный_проход), patch.object(модуль.журнал, 'проверить_смешанный', смешанный_проход):
            модуль.применить(данные['план'], данные['выбор'], Path(данные['каталог']))
        print(json.dumps(счёт))
    elif ПАРАМЕТРЫ.работник:
        print(json.dumps(работник(ПАРАМЕТРЫ), ensure_ascii=False, sort_keys=True))
    else:
        имя = ПАРАМЕТРЫ.проверка or ('test_повторное_перечисление' if ПАРАМЕТРЫ.только_red else None)
        набор = unittest.TestSuite([СтрогийИндекс(имя)]) if имя else unittest.defaultTestLoader.loadTestsFromTestCase(СтрогийИндекс)
        sys.exit(not unittest.TextTestRunner(verbosity=2).run(набор).wasSuccessful())
