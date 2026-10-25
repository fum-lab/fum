"""Приватный пакет проверяется по настоящим сохранённым байтам."""
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from test_пакета_незавершённого import фикстура, пакет, ЗАДАЧА, КАТАЛОГИ
import хранилище_незавершённого as хранилище


class ПроверкаХранилищаНезавершённого(unittest.TestCase):
    def test_сохранение_и_идемпотентный_повтор(сам):
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            (корень / 'Память/слой/данные').write_bytes(b'\x00\xff\r\n')
            план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
            цель = Path(временный).resolve() / 'пакет'
            хранилище.сохранить(цель, план, данные)
            сам.assertEqual(хранилище.прочитать(цель, план['sha256']), (план, данные))
            до = {str(п.relative_to(цель)): (п.stat().st_ino, п.read_bytes()) for п in цель.rglob('*') if п.is_file()}
            хранилище.сохранить(цель, план, данные)
            после = {str(п.relative_to(цель)): (п.stat().st_ino, п.read_bytes()) for п in цель.rglob('*') if п.is_file()}
            сам.assertEqual(до, после)
            сам.assertEqual(цель.stat().st_mode & 0o777, 0o700)
            for п in цель.rglob('*'):
                сам.assertEqual(п.stat().st_mode & 0o777, 0o700 if п.is_dir() else 0o400)

    def test_изменённый_объект_и_лишний_файл_отклоняются(сам):
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            (корень / 'Память/слой/данные').write_bytes(b'changed\n')
            план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
            цель = Path(временный).resolve() / 'пакет'
            хранилище.сохранить(цель, план, данные)
            объект = цель / 'объекты' / next(iter(данные))
            объект.chmod(0o600); объект.write_bytes(b'corrupt\n'); объект.chmod(0o400)
            with сам.assertRaises(ValueError):
                хранилище.прочитать(цель, план['sha256'])
            объект.chmod(0o600); объект.write_bytes(next(iter(данные.values()))); объект.chmod(0o400)
            (цель / 'лишний').write_bytes(b'extra')
            with сам.assertRaises(ValueError):
                хранилище.прочитать(цель, план['sha256'])

    def test_запись_в_git_или_через_ссылку_запрещена(сам):
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
            цель = корень / 'пакет'
            with сам.assertRaises(ValueError):
                хранилище.сохранить(цель, план, данные)
            сам.assertFalse(цель.exists())
            внешний = Path(временный).resolve(); (внешний / 'ссылка').symlink_to(внешний, target_is_directory=True)
            with сам.assertRaises(ValueError):
                хранилище.сохранить(внешний / 'ссылка/пакет', план, данные)
            сам.assertFalse((внешний / 'пакет').exists())

    def test_неполный_каталог_не_перезаписывается(сам):
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
            цель = Path(временный).resolve() / 'пакет'; цель.mkdir(mode=0o700)
            (цель / 'частичный').write_bytes(b'preserve')
            with сам.assertRaises(ValueError):
                хранилище.сохранить(цель, план, данные)
            сам.assertEqual((цель / 'частичный').read_bytes(), b'preserve')

    def test_прерывание_перед_манифестом_сохраняет_частичный_пакет(сам):
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            (корень / 'Память/слой/данные').write_bytes(b'changed\n')
            план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
            цель = Path(временный).resolve() / 'пакет'
            настоящая = хранилище._записать
            def прерывание(путь, байты):
                if путь.name == 'описание.json':
                    raise OSError('Открытая имитация прерывания')
                настоящая(путь, байты)
            with mock.patch.object(хранилище, '_записать', side_effect=прерывание):
                with сам.assertRaises(OSError):
                    хранилище.сохранить(цель, план, данные)
            до = {п.name: п.read_bytes() for п in (цель / 'объекты').iterdir()}
            сам.assertEqual(до, данные)
            with сам.assertRaises(ValueError):
                хранилище.сохранить(цель, план, данные)
            сам.assertEqual({п.name: п.read_bytes() for п in (цель / 'объекты').iterdir()}, до)

    def test_ожидаемый_хэш_и_небезопасные_объекты(сам):
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            (корень / 'Память/слой/данные').write_bytes(b'changed\n')
            план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
            цель = Path(временный).resolve() / 'пакет'
            хранилище.сохранить(цель, план, данные)
            with сам.assertRaises(ValueError):
                хранилище.прочитать(цель, 'a' * 64)
            объект = цель / 'объекты' / next(iter(данные))
            объект.chmod(0o600)
            with сам.assertRaises(ValueError):
                хранилище.прочитать(цель, план['sha256'])
            объект.chmod(0o400)
            ссылка = цель.parent / 'жёсткая'; ссылка.hardlink_to(объект)
            with сам.assertRaises(ValueError):
                хранилище.прочитать(цель, план['sha256'])
            ссылка.unlink()
            объект.unlink(); объект.symlink_to(цель / 'описание.json')
            with сам.assertRaises(ValueError):
                хранилище.прочитать(цель, план['sha256'])

    def test_повтор_после_ошибки_fsync_завершает_синхронизацию(сам):
        with фикстура() as (корень, база), tempfile.TemporaryDirectory() as временный:
            (корень / 'Память/слой/данные').write_bytes(b'changed\n')
            план, данные = пакет.собрать(корень, ЗАДАЧА, база, КАТАЛОГИ)
            цель = Path(временный).resolve() / 'пакет'
            настоящая = хранилище.хранение.синхронизировать_каталог
            def прерывание(путь):
                if путь == цель.parent:
                    raise OSError('Открытый отказ fsync родителя')
                настоящая(путь)
            with mock.patch.object(хранилище.хранение, 'синхронизировать_каталог', side_effect=прерывание):
                with сам.assertRaises(OSError):
                    хранилище.сохранить(цель, план, данные)
            сам.assertEqual(хранилище.прочитать(цель, план['sha256']), (план, данные))
            with mock.patch.object(хранилище.os, 'fsync', side_effect=OSError('Повторный отказ')):
                with сам.assertRaises(OSError):
                    хранилище.сохранить(цель, план, данные)
            with mock.patch.object(хранилище.os, 'fsync', wraps=хранилище.os.fsync) as синхронизация:
                хранилище.сохранить(цель, план, данные)
                сам.assertGreaterEqual(синхронизация.call_count, len(данные) + 4)


if __name__ == '__main__':
    unittest.main()
