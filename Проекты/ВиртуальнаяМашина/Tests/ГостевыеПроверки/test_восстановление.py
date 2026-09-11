"""Восстановление собственных units не изменяет неизвестные пользовательские файлы."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ресурсы = Path(__file__).resolve().parents[2] / 'Sources/ЯдроМашины/Ресурсы'
спецификация = importlib.util.spec_from_file_location('гостевое_восстановление', ресурсы / 'восстановление.py')
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)


class ПроверкиВосстановления(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory(); сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        (сам.корень / 'etc/systemd/system').mkdir(parents=True)
        (сам.корень / 'run/lock').mkdir(parents=True)
        (сам.корень / 'etc/fum-vm-id').write_text('12345678-1234-4234-8234-123456789abc\n')
        сам.данные = {'машина': '12345678-1234-4234-8234-123456789abc',
                       'файлы': {'fum-vsock.socket': 'Новая открытая фикстура сокета\n',
                                  'fum-vsock.service': 'Новая открытая фикстура службы\n'},
                       'прежняя_служба': 'Прежняя открытая фикстура службы\n'}
        сам.вызовы = []
        def выполнить(аргументы):
            сам.вызовы.append(аргументы)
            if '--property=UnitPath' in аргументы:
                return '/etc/systemd/system /run/systemd/system /usr/lib/systemd/system\n'
            return ''
        сам.выполнить = выполнить

    def test_переход_сохраняет_прежнее_и_повтор_не_перезапускает_службу(сам):
        служба = сам.корень / 'etc/systemd/system/fum-vsock.service'
        служба.write_text(сам.данные['прежняя_служба'])
        модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        сам.assertEqual(служба.read_text(), сам.данные['файлы']['fum-vsock.service'])
        резерв = list((сам.корень / 'var/lib/fum-vm').glob('*/fum-vsock.service'))
        сам.assertEqual(len(резерв), 1)
        сам.assertEqual(резерв[0].read_text(), сам.данные['прежняя_служба'])
        сам.вызовы.clear()
        модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        сам.assertFalse(any('stop' in команда or 'restart' in команда for команда in сам.вызовы))

    def test_чужая_идентичность_и_изменённые_units_не_переписываются(сам):
        служба = сам.корень / 'etc/systemd/system/fum-vsock.service'; служба.write_text('Изменено пользователем')
        with сам.assertRaises(ValueError): модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        сам.assertEqual(служба.read_text(), 'Изменено пользователем'); сам.assertEqual(сам.вызовы, [])
        служба.unlink(); (сам.корень / 'etc/fum-vm-id').write_text('Чужая VM')
        with сам.assertRaises(ValueError): модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        сам.assertFalse(служба.exists())

    def test_ссылка_не_разрешает_запись_в_чужую_цель(сам):
        цель = сам.корень / 'чужая-цель'; цель.write_text(сам.данные['прежняя_служба'])
        (сам.корень / 'etc/systemd/system/fum-vsock.service').symlink_to(цель)
        with сам.assertRaises(ValueError): модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        сам.assertEqual(цель.read_text(), сам.данные['прежняя_служба']); сам.assertEqual(сам.вызовы, [])

    def test_новая_пара_не_требует_остановки_отсутствующей_службы(сам):
        def выполнить(аргументы):
            if 'stop' in аргументы: raise RuntimeError('Unit не существует')
            return сам.выполнить(аргументы)
        модуль.восстановить(сам.данные, корень=сам.корень, выполнить=выполнить)
        сам.assertTrue((сам.корень / 'etc/systemd/system/fum-vsock.socket').is_file())

    def test_повтор_после_отказа_записи_или_активации_завершает_переход(сам):
        from unittest.mock import patch
        служба = сам.корень / 'etc/systemd/system/fum-vsock.service'
        служба.write_text(сам.данные['прежняя_служба'])
        сохранить = модуль.сохранить
        def отказ_второго_файла(путь, данные, режим):
            if путь == служба: raise OSError('Прерывание между двумя units')
            return сохранить(путь, данные, режим)
        with patch.object(модуль, 'сохранить', side_effect=отказ_второго_файла):
            with сам.assertRaises(OSError):
                модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        # Независимый NAT SSH сохраняется; новый вызов читает оставшийся точный состав.
        модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        сам.assertEqual(служба.read_text(), сам.данные['файлы']['fum-vsock.service'])
        def отказ_активации(аргументы):
            if 'enable' in аргументы: raise RuntimeError('Прервано включение')
            return сам.выполнить(аргументы)
        with сам.assertRaises(RuntimeError):
            модуль.восстановить(сам.данные, корень=сам.корень, выполнить=отказ_активации)
        модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
        сам.assertEqual(служба.read_text(), сам.данные['файлы']['fum-vsock.service'])

    def test_надстройка_службы_отклоняется_до_записи_и_остановки(сам):
        служба = сам.корень / 'etc/systemd/system/fum-vsock.service'
        служба.write_text(сам.данные['прежняя_служба'])
        for имя in ('fum-vsock.service.d', 'fum-vsock.socket.d', 'fum-.service.d', 'socket.d'):
            with сам.subTest(имя=имя):
                папка = служба.parent / имя; папка.mkdir()
                файл = папка / 'override.conf'; файл.write_text('[Service]\nEnvironment=FIXTURE=yes\n')
                try:
                    with сам.assertRaises(ValueError):
                        модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
                    сам.assertEqual(служба.read_text(), сам.данные['прежняя_служба'])
                    сам.assertFalse(any('stop' in команда or 'daemon-reload' in команда for команда in сам.вызовы))
                    сам.assertFalse((сам.корень / 'var/lib/fum-vm').exists())
                finally: файл.unlink(); папка.rmdir(); сам.вызовы.clear()

    def test_параллельное_восстановление_не_выполняет_переход(сам):
        обнаружено = []
        def выполнить(аргументы):
            if 'daemon-reload' in аргументы:
                with сам.assertRaises(ValueError):
                    модуль.восстановить(сам.данные, корень=сам.корень, выполнить=сам.выполнить)
                обнаружено.append(True)
            return сам.выполнить(аргументы)
        модуль.восстановить(сам.данные, корень=сам.корень, выполнить=выполнить)
        сам.assertEqual(обнаружено, [True])


if __name__ == '__main__': unittest.main()
