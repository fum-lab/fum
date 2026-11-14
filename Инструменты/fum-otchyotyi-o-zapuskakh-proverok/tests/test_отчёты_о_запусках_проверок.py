from __future__ import annotations

import contextlib
import copy
import errno
import hashlib
import importlib.util
import json
import os
import re
import signal
import subprocess
import sys
import tempfile
import time
import unittest
import uuid
from decimal import Decimal
from pathlib import Path
from unittest import mock


class ПроверкаОграниченногоПредпросмотра(unittest.TestCase):
    удерживаемые_фикстуры = []

    def _сценарий_с_занятым_замком(сам, длительность, ожидается_тайм_аут):
        import errno
        import select
        модуль = загрузить_модуль_автоматизации()
        временный = tempfile.TemporaryDirectory(dir='/private/tmp')
        временный._finalizer.detach()
        удержание = [временный, None]
        сам.удерживаемые_фикстуры.append(удержание)
        процесс = None
        запуск_начат = False
        состояние_ожидания = 'не начато'
        код_процесса = None

        def дождаться():
            nonlocal состояние_ожидания, код_процесса
            if состояние_ожидания == 'получено':
                return код_процесса
            if состояние_ожидания != 'не начато':
                raise AssertionError('неизвестное ожидание процесса не повторяется')
            состояние_ожидания = 'начато'
            try:
                код_процесса = процесс.wait(timeout=16)
            except BaseException:
                состояние_ожидания = 'неизвестно'
                raise
            состояние_ожидания = 'получено'
            return код_процесса

        try:
            база = Path(временный.name).resolve()
            корень = база / 'репозиторий'
            корень.mkdir()
            каталог_замка = база / 'замки'
            каталог_замка.mkdir(mode=0o700)
            сессия = 'Журнал/сессия/запрос.md'
            запрос = корень / сессия
            запрос.parent.mkdir(parents=True)
            запрос.write_text('запрос\n', encoding='utf-8')
            отчёт = запрос.with_name('отчёт.md')
            исходный = ('до\n' + модуль.ОТКРЫТЫЙ_МАРКЕР + '\nпока пусто\n' +
                        модуль.КОНЕЧНЫЙ_МАРКЕР + '\nпосле\n').encode('utf-8')
            отчёт.write_bytes(исходный)
            история = запрос.parent / 'материалы/запуски-проверок'
            история.mkdir(parents=True)
            идентификатор = '00000000-0000-4000-8000-000000000001'
            запись = история / ('1_' + идентификатор + '.json')
            данные = {
                'схема': 'fum.test-run.v1', 'идентификатор': идентификатор,
                'сессия': сессия, 'порядок': 1, 'исполнитель': 'root',
                'вызов': 'синтетическая проверка', 'состояние': 'завершён',
                'длительность_наносекунды': 1, 'статус': 'успешно',
                'код_завершения': 0, 'пояснение': None,
            }
            байты_записи = (json.dumps(данные, ensure_ascii=False, sort_keys=True,
                                      separators=(',', ':')) + '\n').encode('utf-8')
            запись.write_bytes(байты_записи)
            ключ = hashlib.sha256((str(корень) + '\0' + сессия).encode('utf-8')).hexdigest()
            замок = каталог_замка / ('fum-check-runs-' + ключ + '.lock')
            fd = os.open(замок, os.O_CREAT | os.O_EXCL | os.O_RDWR | os.O_CLOEXEC, 0o600)
            try:
                os.fchmod(fd, 0o600)
                метка = os.fstat(fd)
            finally:
                os.close(fd)
            код = '\n'.join([
                'import fcntl,os,signal,sys,time',
                'def timeout(_number,_frame): raise TimeoutError("срок владельца фикстуры")',
                'signal.signal(signal.SIGALRM,timeout); signal.alarm(15)',
                'fd=os.open(sys.argv[1],os.O_RDWR|os.O_NOFOLLOW|os.O_CLOEXEC)',
                's=os.fstat(fd); assert (s.st_dev,s.st_ino)==(int(sys.argv[2]),int(sys.argv[3]))',
                'fcntl.flock(fd,fcntl.LOCK_EX); os.write(1,b"R")',
                'time.sleep(float(sys.argv[4]))',
                'fcntl.flock(fd,fcntl.LOCK_UN); os.close(fd); os.write(1,b"D")',
            ])
            запуск_начат = True
            процесс = subprocess.Popen(
                [sys.executable, '-I', '-S', '-B', '-c', код, str(замок),
                 str(метка.st_dev), str(метка.st_ino), str(длительность)],
                env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'},
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                close_fds=True, start_new_session=True)
            удержание[1] = процесс
            сам.assertTrue(select.select([процесс.stdout.fileno()], [], [], 5.0)[0])
            сам.assertEqual(os.read(процесс.stdout.fileno(), 1), b'R')
            настоящий_flock = модуль.fcntl.flock
            наблюдалась_занятость = []
            def наблюдать(fd, операция):
                try:
                    return настоящий_flock(fd, операция)
                except BlockingIOError as причина:
                    текущая = os.fstat(fd)
                    if (операция == модуль.fcntl.LOCK_EX | модуль.fcntl.LOCK_NB
                        and причина.errno in (errno.EAGAIN, errno.EWOULDBLOCK)
                        and (текущая.st_dev, текущая.st_ino) == (метка.st_dev, метка.st_ino)):
                        наблюдалась_занятость.append(time.monotonic())
                    raise
            with mock.patch.object(модуль.tempfile, 'gettempdir', return_value=str(каталог_замка)), \
                 mock.patch.object(модуль.fcntl, 'flock', side_effect=наблюдать):
                начало = time.monotonic()
                if ожидается_тайм_аут:
                    with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'срок'):
                        модуль.выполнить_предпросмотр(корень, запрос)
                    сам.assertGreaterEqual(time.monotonic() - начало, 4.9)
                    сам.assertTrue(наблюдалась_занятость)
                    сам.assertEqual(отчёт.read_bytes(), исходный)
                    сам.assertIsNone(процесс.poll())
                    сам.assertEqual([(p.name, p.read_bytes()) for p in история.iterdir()],
                                    [(запись.name, байты_записи)])
                    сам.assertEqual(дождаться(), 0)
                    сам.assertEqual(os.read(процесс.stdout.fileno(), 1), b'D')
                сам.assertEqual(модуль.выполнить_предпросмотр(корень, запрос), 0)
                сам.assertTrue(наблюдалась_занятость)
                сам.assertNotEqual(отчёт.read_bytes(), исходный)
                сам.assertIn(модуль.ОТКРЫТЫЙ_МАРКЕР.encode('utf-8'), отчёт.read_bytes())
                сам.assertEqual(дождаться(), 0)
                if not ожидается_тайм_аут:
                    сам.assertEqual(os.read(процесс.stdout.fileno(), 1), b'D')
        finally:
            if процесс is not None:
                if состояние_ожидания == 'не начато':
                    дождаться()
                if состояние_ожидания == 'получено':
                    процесс.stdout.close()
                    процесс.stderr.close()
                    временный.cleanup()
                    сам.удерживаемые_фикстуры.remove(удержание)
            elif not запуск_начат:
                временный.cleanup()
                сам.удерживаемые_фикстуры.remove(удержание)

    def test_занятый_замок_ограничивает_предпросмотр_без_записи(сам):
        сам._сценарий_с_занятым_замком(8.0, True)

    def test_освобождение_замка_до_срока_разрешает_предпросмотр(сам):
        сам._сценарий_с_занятым_замком(0.75, False)

    def test_прошедший_срок_после_flock_не_открывает_секцию(сам):
        import fcntl
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as временный:
            корень = Path(временный).resolve()
            with mock.patch.object(модуль.tempfile, 'gettempdir', return_value=str(корень)), \
                 mock.patch.object(модуль.time, 'monotonic', side_effect=[1.0, 1.0, 3.0]):
                with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'срок'):
                    with модуль.межпроцессная_блокировка(корень, 'fixture', срок_монотонный=2.0):
                        сам.fail('истёкший срок допустил защищённую секцию')
            ключ = hashlib.sha256((str(корень) + '\0fixture').encode('utf-8')).hexdigest()
            fd = os.open(корень / ('fum-check-runs-' + ключ + '.lock'), os.O_RDWR | os.O_CLOEXEC)
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                fcntl.flock(fd, fcntl.LOCK_UN)
            finally:
                os.close(fd)

    def test_без_срока_сохраняется_блокирующий_flock(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as временный:
            корень = Path(временный).resolve()
            with mock.patch.object(модуль.tempfile, 'gettempdir', return_value=str(корень)), \
                 mock.patch.object(модуль.fcntl, 'flock', wraps=модуль.fcntl.flock) as вызовы:
                with модуль.межпроцессная_блокировка(корень, 'fixture'):
                    pass
            операции = [вызов.args[1] for вызов in вызовы.call_args_list]
            сам.assertEqual(операции, [модуль.fcntl.LOCK_EX, модуль.fcntl.LOCK_UN])

    def test_недостоверные_часы_не_открывают_секцию(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as временный:
            корень = Path(временный).resolve()
            with mock.patch.object(модуль.tempfile, 'gettempdir', return_value=str(корень)), \
                 mock.patch.object(модуль.time, 'monotonic', return_value=float('nan')):
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    with модуль.межпроцессная_блокировка(корень, 'fixture', срок_монотонный=2.0):
                        сам.fail('недостоверные часы допустили защищённую секцию')

    def test_ошибка_часов_до_захвата_возвращает_ошибку_отчёта(сам):
        модуль = загрузить_модуль_автоматизации()
        корень = Path('/private/tmp')
        запрос = корень / 'запрос.md'
        with mock.patch.object(модуль, 'разрешить_сессию',
                               return_value=(корень, запрос, корень / 'отчёт.md',
                                             корень / 'история', 'fixture')), \
             mock.patch.object(модуль, 'прочитать_историю_проверок', return_value=[]), \
             mock.patch.object(модуль.time, 'monotonic', side_effect=OSError('часы')), \
             mock.patch.object(модуль, 'межпроцессная_блокировка') as замок:
            with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'срок'):
                модуль.выполнить_предпросмотр(корень, запрос)
            замок.assert_not_called()

    def test_неожиданный_errno_не_считается_занятостью(сам):
        import errno
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as временный:
            корень = Path(временный).resolve()
            причина = BlockingIOError(errno.EBADF, 'неожиданный errno')
            with mock.patch.object(модуль.tempfile, 'gettempdir', return_value=str(корень)), \
                 mock.patch.object(модуль.fcntl, 'flock', side_effect=причина) as вызовы:
                with сам.assertRaises(BlockingIOError) as отказ:
                    with модуль.межпроцессная_блокировка(
                        корень, 'fixture', срок_монотонный=time.monotonic() + 1.0
                    ):
                        сам.fail('ошибка flock допустила защищённую секцию')
            сам.assertIs(отказ.exception, причина)
            сам.assertEqual(вызовы.call_count, 1)

    def test_ошибка_close_сохраняется_вместе_с_истечением(сам):
        import errno
        модуль = загрузить_модуль_автоматизации()
        настоящий_close = модуль.os.close
        def закрыть_и_отказать(fd):
            настоящий_close(fd)
            raise OSError('ошибка после закрытия')
        with tempfile.TemporaryDirectory(dir='/private/tmp') as временный:
            корень = Path(временный).resolve()
            with mock.patch.object(модуль.tempfile, 'gettempdir', return_value=str(корень)), \
                 mock.patch.object(модуль.time, 'monotonic', side_effect=[1.0, 1.0, 3.0]), \
                 mock.patch.object(модуль.fcntl, 'flock', side_effect=BlockingIOError(errno.EAGAIN, 'занят')), \
                 mock.patch.object(модуль.os, 'close', side_effect=закрыть_и_отказать) as закрытия:
                with сам.assertRaises(BaseExceptionGroup) as отказ:
                    with модуль.межпроцессная_блокировка(корень, 'fixture', срок_монотонный=2.0):
                        сам.fail('занятый замок допустил защищённую секцию')
            сам.assertEqual(закрытия.call_count, 1)
            сам.assertTrue(any(isinstance(e, модуль.ОшибкаОтчёта) for e in отказ.exception.exceptions))
            сам.assertTrue(any(isinstance(e, OSError) for e in отказ.exception.exceptions))



class ПроверкаКаноническихМашинныхЗаписей(unittest.TestCase):
    def test_обычная_запись_сохраняет_канонические_байты(сам):
        модуль = загрузить_модуль_автоматизации()
        значение = {'я': [1, None, True], 'a': -1.25}
        ожидается = '{\n  "a": -1.25,\n  "я": [\n    1,\n    null,\n    true\n  ]\n}\n'.encode('utf-8')
        сам.assertEqual(модуль.канонические_машинные_байты(значение), ожидается)

    def test_нечисловые_значения_не_попадают_в_json(сам):
        модуль = загрузить_модуль_автоматизации()
        for значение in (float('nan'), float('inf'), float('-inf')):
            with сам.subTest(значение=repr(значение)):
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    модуль.канонические_машинные_байты({'вложено': [значение]})


class ПроверкаСохранностиВременнойАтомарнойЗаписи(unittest.TestCase):
    def setUp(self):
        self.модуль = загрузить_модуль_автоматизации()
        каталог = tempfile.TemporaryDirectory(prefix="fum-atomic-test-", dir="/private/tmp")
        self.addCleanup(каталог.cleanup)
        self.путь = Path(каталог.name) / "отчёт.txt"
        self.путь.write_bytes(b"old")
        self.uuid = uuid.UUID("12345678-1234-4678-9234-123456789abc")
        self.временный = self.путь.parent / f".{self.путь.name}.{self.uuid}.tmp"

    def test_занятое_временное_имя_сохраняется(self):
        self.временный.write_bytes(b"other-owner")
        with mock.patch.object(self.модуль.uuid, "uuid4", return_value=self.uuid):
            with self.assertRaises(self.модуль.ОшибкаОтчёта):
                self.модуль.атомарно_записать_байты(self.путь, b"new")
        self.assertEqual(self.путь.read_bytes(), b"old")
        self.assertTrue(self.временный.is_file())
        self.assertEqual(self.временный.read_bytes(), b"other-owner")

    def test_ошибка_синхронизации_сохраняет_остаток(self):
        with mock.patch.object(self.модуль.uuid, "uuid4", return_value=self.uuid):
            with mock.patch.object(self.модуль.os, "fsync", side_effect=OSError("synthetic fsync failure")):
                with self.assertRaises(self.модуль.ОшибкаОтчёта):
                    self.модуль.атомарно_записать_байты(self.путь, b"new")
        self.assertEqual(self.путь.read_bytes(), b"old")
        self.assertTrue(self.временный.is_file())
        self.assertEqual(self.временный.read_bytes(), b"new")

    def test_новый_владелец_имени_после_replace_сохраняется(self):
        прежняя_замена = os.replace

        def заменить_и_занять(временный, цель):
            прежняя_замена(временный, цель)
            Path(временный).write_bytes(b"new-owner")

        with mock.patch.object(self.модуль.uuid, "uuid4", return_value=self.uuid):
            with mock.patch.object(self.модуль.os, "replace", side_effect=заменить_и_занять):
                self.модуль.атомарно_записать_байты(self.путь, b"new")
        self.assertEqual(self.путь.read_bytes(), b"new")
        self.assertTrue(self.временный.is_file())
        self.assertEqual(self.временный.read_bytes(), b"new-owner")

    def test_обычная_замена_без_остатка(self):
        with mock.patch.object(self.модуль.uuid, "uuid4", return_value=self.uuid):
            self.модуль.атомарно_записать_байты(self.путь, b"new")
        self.assertEqual(self.путь.read_bytes(), b"new")
        self.assertFalse(self.временный.exists())


class ПроверкаСтрогогоЧтенияМашиннойЗаписи(unittest.TestCase):
    def test_корректный_json_сохраняет_значение_и_байты(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            сырые = '{"имя":"тест","значения":[1,-1.5,true,null]}\n'.encode('utf-8')
            путь.write_bytes(сырые)
            сам.assertEqual(модуль.прочитать_машинную_запись(путь),
                            ({'имя': 'тест', 'значения': [1, -1.5, True, None]}, сырые))

    def test_повторы_ключей_и_неконечные_числа_отклоняются(сам):
        модуль = загрузить_модуль_автоматизации()
        случаи = (b'{"a":1,"a":2}', b'{"x":{"b":1,"b":2}}', b'{"n":NaN}',
                  b'{"n":Infinity}', b'{"n":-Infinity}', b'{"n":1e309}',
                  b'{"x":', b'\xff')
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            for сырые in случаи:
                with сам.subTest(сырые=сырые):
                    путь.write_bytes(сырые)
                    with сам.assertRaises(модуль.ОшибкаОтчёта):
                        модуль.прочитать_машинную_запись(путь)

    def test_предел_машинной_записи_до_чтения(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            данные = b'{"a":1}'
            путь.write_bytes(данные)
            сам.assertEqual(модуль.прочитать_машинную_запись(путь, предел=len(данные)),
                            ({'a': 1}, данные))
            with mock.patch.object(модуль.os, 'read', side_effect=AssertionError('чтение')):
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    модуль.прочитать_машинную_запись(путь, предел=len(данные) - 1)
            for предел in (-1, True, 16 * 1024 * 1024 + 1):
                with сам.subTest(предел=предел), mock.patch.object(
                        модуль.os, 'open', side_effect=AssertionError('открытие')):
                    with сам.assertRaises(модуль.ОшибкаОтчёта):
                        модуль.прочитать_машинную_запись(путь, предел=предел)

    def test_ошибки_json_и_close_сохраняются_без_повтора(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            путь.write_bytes(b'{')
            настоящий_close = os.close
            вызовы = []
            def закрыть_с_неизвестным_исходом(fd):
                вызовы.append(fd)
                настоящий_close(fd)
                raise OSError('модельный UNKNOWN после close')
            with mock.patch.object(модуль.os, 'close', side_effect=закрыть_с_неизвестным_исходом):
                with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'неизвестен исход закрытия') as отказ:
                    модуль.прочитать_машинную_запись(путь)
            сам.assertEqual(len(вызовы), 1)
            ошибки = отказ.exception.__cause__
            сам.assertIsInstance(ошибки, ExceptionGroup)
            сам.assertEqual(len(ошибки.exceptions), 2)
            сам.assertIsInstance(ошибки.exceptions[0], модуль.ОшибкаОтчёта)
            сам.assertIsInstance(ошибки.exceptions[1], OSError)

    def test_ошибка_close_после_успешного_json_не_выглядит_успехом(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            путь.write_bytes(b'{}')
            настоящий_close = os.close
            вызовы = []
            def закрыть_с_неизвестным_исходом(fd):
                вызовы.append(fd)
                настоящий_close(fd)
                raise OSError('модельный UNKNOWN после close')
            with mock.patch.object(модуль.os, 'close', side_effect=закрыть_с_неизвестным_исходом):
                with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'неизвестен исход закрытия') as отказ:
                    модуль.прочитать_машинную_запись(путь)
            сам.assertEqual(len(вызовы), 1)
            сам.assertIsInstance(отказ.exception.__cause__, ExceptionGroup)
            сам.assertIsInstance(отказ.exception.__cause__.exceptions[0], OSError)

    def test_короткие_чтения_собирают_полную_запись(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            данные = b'{"name":"value"}\n'
            путь.write_bytes(данные)
            настоящий_read = os.read
            размеры = []
            def прочитать(fd, размер):
                размеры.append(размер)
                return настоящий_read(fd, min(2, размер))
            with mock.patch.object(модуль.os, 'read', side_effect=прочитать):
                сам.assertEqual(модуль.прочитать_машинную_запись(путь), ({'name': 'value'}, данные))
            сам.assertGreater(len(размеры), 2)

    def test_ошибка_read_закрывает_открытый_fd(сам):
        import errno
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/private/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            путь.write_bytes(b'{}')
            настоящий_open = os.open
            открытые = []
            def открыть(*args, **kwargs):
                fd = настоящий_open(*args, **kwargs)
                открытые.append(fd)
                return fd
            with mock.patch.object(модуль.os, 'open', side_effect=открыть), \
                 mock.patch.object(модуль.os, 'read', side_effect=OSError('модельный отказ')):
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    модуль.прочитать_машинную_запись(путь)
            сам.assertEqual(len(открытые), 1)
            with сам.assertRaises(OSError) as ошибка:
                os.fstat(открытые[0])
            сам.assertEqual(ошибка.exception.errno, errno.EBADF)

    def test_чтение_машинной_записи_отклоняет_подмену_перед_open(сам):
        модуль = загрузить_модуль_автоматизации()
        for вариант in ('fifo', 'symlink'):
            with сам.subTest(вариант=вариант), tempfile.TemporaryDirectory(dir='/tmp') as каталог:
                путь = Path(каталог) / 'запись.json'
                путь.write_bytes(b'{"a":1}\n')
                исходный_open = os.open
                попытки = []
                def открыть(адрес, флаги, *аргументы, **ключи):
                    if Path(адрес) == путь and not попытки:
                        попытки.append(True)
                        сам.assertTrue(флаги & os.O_NONBLOCK)
                        сам.assertTrue(флаги & os.O_NOFOLLOW)
                        путь.rename(Path(каталог) / 'old.json')
                        if вариант == 'fifo':
                            os.mkfifo(путь, 0o600)
                        else:
                            путь.symlink_to('old.json')
                    return исходный_open(адрес, флаги, *аргументы, **ключи)
                with mock.patch.object(модуль.os, 'open', side_effect=открыть):
                    with сам.assertRaises(модуль.ОшибкаОтчёта):
                        модуль.прочитать_машинную_запись(путь)
                сам.assertEqual(попытки, [True])
                сам.assertEqual((Path(каталог) / 'old.json').read_bytes(), b'{"a":1}\n')

    def test_замена_машинной_записи_при_чтении_не_возвращает_данные(сам):
        import errno
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            исходные = b'{"a":1}\n'
            путь.write_bytes(исходные)
            штатный_open, штатный_read = os.open, os.read
            открытые, изменено = [], []
            def открыть(адрес, флаги, *аргументы, **ключи):
                fd = штатный_open(адрес, флаги, *аргументы, **ключи)
                if Path(адрес) == путь:
                    открытые.append(fd)
                return fd
            def читать(fd, размер):
                часть = штатный_read(fd, размер)
                if открытые and fd == открытые[0] and часть and not изменено:
                    изменено.append(True)
                    путь.rename(Path(каталог) / 'old.json')
                    путь.write_bytes(b'{"a":2}\n')
                return часть
            with mock.patch.object(модуль.os, 'open', side_effect=открыть), \
                 mock.patch.object(модуль.os, 'read', side_effect=читать):
                with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'изменилась'):
                    модуль.прочитать_машинную_запись(путь)
            сам.assertEqual(изменено, [True])
            сам.assertEqual(len(открытые), 1)
            with сам.assertRaises(OSError) as закрыт:
                os.fstat(открытые[0])
            сам.assertEqual(закрыт.exception.errno, errno.EBADF)
            сам.assertEqual((Path(каталог) / 'old.json').read_bytes(), исходные)
            сам.assertEqual(путь.read_bytes(), b'{"a":2}\n')

    def test_рост_или_усечение_машинной_записи_отклоняется(сам):
        модуль = загрузить_модуль_автоматизации()
        for вариант in ('рост', 'усечение'):
            with сам.subTest(вариант=вариант), tempfile.TemporaryDirectory(dir='/tmp') as каталог:
                путь = Path(каталог) / 'запись.json'
                исходные = b'{"a":1}\n'
                путь.write_bytes(исходные)
                штатный_read = os.read
                изменено = []
                def читать(fd, размер):
                    часть = штатный_read(fd, размер)
                    if часть and not изменено:
                        изменено.append(True)
                        путь.write_bytes(исходные + b' ' if вариант == 'рост' else b'')
                    return часть
                with mock.patch.object(модуль.os, 'read', side_effect=читать):
                    with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'изменилась'):
                        модуль.прочитать_машинную_запись(путь)
                сам.assertEqual(изменено, [True])

    def test_машинная_запись_сохраняет_точные_байты(сам):
        модуль = загрузить_модуль_автоматизации()
        with tempfile.TemporaryDirectory(dir='/tmp') as каталог:
            путь = Path(каталог) / 'запись.json'
            данные = b'{ "a": 1 }\n'
            путь.write_bytes(данные)
            сам.assertEqual(модуль.прочитать_машинную_запись(путь), ({'a': 1}, данные))


def путь_проверяемой_реализации(путь: Path) -> Path:
    выбранный = os.environ.get("FUM_CHECKED_CODE_ROOT")
    if выбранный is None:
        return путь
    if not выбранный or not Path(выбранный).is_absolute():
        raise ValueError("корень проверяемой реализации должен быть явным абсолютным путём")
    return Path(выбранный) / путь.relative_to(Path(__file__).resolve().parents[3])


корень_автоматизации = Path(__file__).resolve().parents[1]
сценарий = (
    путь_проверяемой_реализации(корень_автоматизации
    / "scripts"
    / "отчёты_о_запусках_проверок.py")
)
имя_сессии = "2026-08-04_20-45-26_MSK_формировать-отчёты-о-запусках-тестов"
путь_запроса = f"Журнал/{имя_сессии}/запрос.md"
открытый_маркер = (
    "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; "
    "каталог=материалы/запуски-проверок -->"
)
шаблон_закрытого_маркера = re.compile(
    r"<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; "
    r"снимок=материалы/запуски-проверок/снимок\.json; "
    r"sha256=sha256:[0-9a-f]{64} -->"
)
конечный_маркер = "<!-- FUM-CHECK-RUNS:END -->"
имя_журнала_возобновления = "возобновление.json"
схема_журнала_возобновления = "возобновление-отчёта-проверок.1"
поля_записи = {
    "схема",
    "идентификатор",
    "сессия",
    "порядок",
    "исполнитель",
    "вызов",
    "состояние",
    "длительность_наносекунды",
    "статус",
    "код_завершения",
    "пояснение",
}
поля_записи_с_наблюдениями = поля_записи | {"план", "наблюдения"}
поля_профиля_проверки = {
    "класс",
    "отпечаток_снимка",
    "полные_наборы",
    "основание",
    "идентификатор_отказа",
    "ожидаемое_свидетельство",
}
поля_профилированной_записи = поля_записи_с_наблюдениями | {
    "профиль_проверки"
}


def загрузить_модуль_автоматизации():
    спецификация = importlib.util.spec_from_file_location(
        "fum_отчёты_о_запусках_проверок_тест",
        сценарий,
    )
    if спецификация is None or спецификация.loader is None:
        raise AssertionError("Не удалось загрузить модуль автоматизации")
    модуль = importlib.util.module_from_spec(спецификация)
    спецификация.loader.exec_module(модуль)
    return модуль


def дождаться_файла(путь: Path, тайм_аут: float = 5.0) -> None:
    предел = time.monotonic() + тайм_аут
    while time.monotonic() < предел:
        if путь.exists():
            return
        time.sleep(0.01)
    raise AssertionError(f"Файл не появился за {тайм_аут} с: {путь}")


class ПроверкаПереносаВидимыхАтрибутовДарвина(unittest.TestCase):
    """Новые синтетические файлы; при ошибке нет автоматической очистки."""

    удерживаемые_фикстуры = []

    def setUp(сам):
        if sys.platform != 'darwin':
            сам.fail('для адресного теста нужен Darwin; пропуск не является успехом')
        import ctypes

        сам.модуль = загрузить_модуль_автоматизации()
        сам.удержание = {
            'состояние': 'создание', 'каталог': None, 'источник': [],
            'назначение': [], 'ошибка': None,
        }
        сам.удерживаемые_фикстуры.append(сам.удержание)
        try:
            каталог = Path(tempfile.mkdtemp(prefix='fum-visible-xattr-', dir='/private/tmp'))
            сам.удержание['каталог'] = каталог
            флаги = os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC
            сам.источник = сам.модуль._приобрести_fd(
                сам.удержание['источник'], os.open, каталог / 'источник',
                флаги, 0o600)
            сам.назначение = сам.модуль._приобрести_fd(
                сам.удержание['назначение'], os.open, каталог / 'назначение',
                флаги, 0o600)
            os.fchmod(сам.источник, 0o600)
            os.fchmod(сам.назначение, 0o600)
            сам.типы = ctypes
            сам.библиотека = ctypes.CDLL(None, use_errno=True)
            сам.тестовая_запись = сам.библиотека.fsetxattr
            сам.тестовая_запись.argtypes = [
                ctypes.c_int, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t,
                ctypes.c_uint32, ctypes.c_int,
            ]
            сам.тестовая_запись.restype = ctypes.c_int
            сам.тестовое_чтение = сам.библиотека.fgetxattr
            сам.тестовое_чтение.argtypes = [
                ctypes.c_int, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t,
                ctypes.c_uint32, ctypes.c_int,
            ]
            сам.тестовое_чтение.restype = ctypes.c_ssize_t
            сам.тестовый_список = сам.библиотека.flistxattr
            сам.тестовый_список.argtypes = [
                ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int,
            ]
            сам.тестовый_список.restype = ctypes.c_ssize_t
            сам.система = сам.модуль._ВызовыВидимыхАтрибутовДарвина()
            сам.перенос = сам.модуль._ОпытныйПереносВидимыхАтрибутов(
                сам.система, сам.источник, сам.назначение)
            сам.удержание['перенос'] = сам.перенос
            сам.удержание['состояние'] = 'готово'
        except BaseException as ошибка:
            сам.удержание['состояние'] = 'неизвестно'
            сам.удержание['ошибка'] = ошибка
            raise

    def создать_атрибут_фикстуры(сам, дескриптор, имя, значение):
        буфер = сам.типы.create_string_buffer(значение)
        итог = сам.тестовая_запись(
            дескриптор, имя, сам.типы.cast(буфер, сам.типы.c_void_p), len(значение), 0, 0)
        if итог != 0:
            raise OSError(сам.типы.get_errno(), 'не создан синтетический xattr')

    def прочитать_атрибут_фикстуры(сам, дескриптор, имя, размер):
        буфер = сам.типы.create_string_buffer(max(размер, 1))
        итог = сам.тестовое_чтение(
            дескриптор, имя, сам.типы.cast(буфер, сам.типы.c_void_p), max(размер, 1), 0, 0)
        if итог < 0:
            raise OSError(сам.типы.get_errno(), 'не прочитан синтетический xattr')
        сам.assertEqual(итог, размер)
        return буфер.raw[:размер]

    def имена_фикстуры(сам, дескриптор):
        буфер = сам.типы.create_string_buffer(64 * 1024)
        итог = сам.тестовый_список(
            дескриптор, сам.типы.cast(буфер, сам.типы.c_void_p), len(буфер), 0)
        if итог < 0:
            raise OSError(сам.типы.get_errno(), 'не прочитан список синтетических xattr')
        if итог == 0:
            return ()
        данные = буфер.raw[:итог]
        сам.assertTrue(данные.endswith(b'\0'))
        return tuple(sorted(данные[:-1].split(b'\0')))

    def test_реальные_пустое_двоичное_и_длинное_значения_по_двум_дескрипторам(сам):
        значения = {
            b'com.fum.empty': b'',
            b'com.fum.binary': b'\0\xff\x80A\0',
            b'com.fum.large': bytes(range(256)) * 64,
        }
        сам.assertEqual(сам.имена_фикстуры(сам.источник), ())
        сам.assertEqual(сам.имена_фикстуры(сам.назначение), ())
        for имя, значение in значения.items():
            сам.создать_атрибут_фикстуры(сам.источник, имя, значение)
        до = os.fstat(сам.назначение)
        сам.assertEqual(сам.перенос.выполнить(), len(значения))
        сам.assertEqual(сам.перенос.состояние, 'подтверждено')
        после = os.fstat(сам.назначение)
        сам.assertEqual((после.st_dev, после.st_ino, после.st_mode, после.st_uid, после.st_gid,
                         после.st_nlink, после.st_flags),
                        (до.st_dev, до.st_ino, до.st_mode, до.st_uid, до.st_gid, до.st_nlink, до.st_flags))
        сам.assertEqual(сам.имена_фикстуры(сам.назначение), tuple(sorted(значения)))
        for имя, значение in значения.items():
            сам.assertEqual(сам.прочитать_атрибут_фикстуры(сам.назначение, имя, len(значение)), значение)
            сам.assertEqual(сам.прочитать_атрибут_фикстуры(сам.источник, имя, len(значение)), значение)
        with mock.patch.object(сам.система, 'снять', side_effect=AssertionError('повторное чтение')):
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()

    def test_ошибка_чтения_не_превращается_в_пустой_список_и_не_повторяется(сам):
        import errno

        ошибка = OSError(errno.EACCES, 'синтетический отказ')
        with mock.patch.object(сам.система, 'снять', side_effect=ошибка) as чтение, \
             mock.patch.object(сам.система, 'создать') as запись:
            with сам.assertRaises(OSError) as исход:
                сам.перенос.выполнить()
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        сам.assertIs(исход.exception, ошибка)
        сам.assertIs(сам.перенос.ошибка, ошибка)
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')
        чтение.assert_called_once()
        запись.assert_not_called()

    def test_другие_ошибки_чтения_отказывают_до_записи(сам):
        import errno

        сам.удержание['попытки'] = []
        for код in (errno.EIO, errno.ENOTSUP, errno.ERANGE):
            перенос = сам.модуль._ОпытныйПереносВидимыхАтрибутов(
                сам.система, сам.источник, сам.назначение)
            сам.удержание['попытки'].append(перенос)
            ошибка = OSError(код, 'синтетический отказ')
            with сам.subTest(код=код), \
                 mock.patch.object(сам.система, 'снять', side_effect=ошибка) as чтение, \
                 mock.patch.object(сам.система, 'создать') as запись:
                with сам.assertRaises(OSError) as исход:
                    перенос.выполнить()
                with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                    перенос.выполнить()
            сам.assertIs(исход.exception, ошибка)
            сам.assertEqual(перенос.состояние, 'отказ до записи')
            чтение.assert_called_once()
            запись.assert_not_called()

    def test_потерянный_результат_фактической_записи_не_повторяется(сам):
        import errno

        сам.создать_атрибут_фикстуры(сам.источник, b'com.fum.one', b'value')
        исходная_запись = сам.система.создать
        подтверждённые_вызовы = []
        ошибка = OSError(errno.EIO, 'потерян результат записи')
        def записать_и_потерять(*аргументы):
            исходная_запись(*аргументы)
            подтверждённые_вызовы.append(True)
            raise ошибка
        with mock.patch.object(сам.система, 'создать', side_effect=записать_и_потерять) as запись:
            with сам.assertRaises(OSError) as исход:
                сам.перенос.выполнить()
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        сам.assertEqual(подтверждённые_вызовы, [True])
        сам.assertIs(исход.exception, ошибка)
        сам.assertIs(сам.перенос.ошибка, ошибка)
        сам.assertEqual(сам.перенос.состояние, 'неизвестно')
        сам.assertEqual(сам.перенос.попытка, (b'com.fum.one', 'начата'))
        запись.assert_called_once()

    def test_существующий_атрибут_назначения_не_заменяется(сам):
        сам.создать_атрибут_фикстуры(сам.назначение, b'com.fum.existing', b'old')
        with mock.patch.object(сам.система, 'создать') as запись:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'уже имеет'):
                сам.перенос.выполнить()
        запись.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')
        сам.assertEqual(сам.прочитать_атрибут_фикстуры(
            сам.назначение, b'com.fum.existing', 3), b'old')

    def test_чужой_поток_отклоняется_до_чтения_и_не_портит_владельца(сам):
        with mock.patch.object(сам.модуль.threading, 'current_thread', return_value=object()), \
             mock.patch.object(сам.система, 'снять') as чтение:
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        чтение.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'готов')
        сам.assertEqual(сам.перенос.выполнить(), 0)

    def test_слишком_большое_значение_не_читается_повторно(сам):
        with mock.patch.object(
            сам.система, '_чтение', return_value=сам.система._предел_значения + 1,
        ) as чтение:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'предел'):
                сам.система.значение(сам.источник, b'com.fum.large', 4 * 1024 * 1024)
        чтение.assert_called_once()

    def test_ошибка_изменения_размера_не_объявляется_пустым_атрибутом(сам):
        import errno

        сам.создать_атрибут_фикстуры(сам.источник, b'com.fum.change', b'data')
        def чтение(дескриптор, имя, указатель, размер, позиция, параметры):
            if указатель is None:
                return 4
            сам.типы.set_errno(errno.ERANGE)
            return -1
        with mock.patch.object(сам.система, '_чтение', side_effect=чтение) as вызовы, \
             mock.patch.object(сам.система, 'создать') as запись:
            with сам.assertRaises(OSError) as исход:
                сам.перенос.выполнить()
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        сам.assertEqual(исход.exception.errno, errno.ERANGE)
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')
        сам.assertEqual(вызовы.call_count, 2)
        запись.assert_not_called()

    def test_повторные_или_оборванные_имена_отклоняются(сам):
        варианты = (b'com.fum.one\0com.fum.one\0', b'com.fum.one')
        for данные in варианты:
            def список(дескриптор, указатель, размер, параметры):
                if указатель is None:
                    return len(данные)
                сам.типы.memmove(указатель, данные, len(данные))
                return len(данные)
            with сам.subTest(число_байт=len(данные)), \
                 mock.patch.object(сам.система, '_список', side_effect=список), \
                 mock.patch.object(сам.система, 'значение') as чтение:
                with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                    сам.система.снять(сам.источник)
            чтение.assert_not_called()

    def test_изменившийся_набор_имён_отклоняется(сам):
        with mock.patch.object(сам.система, 'имена',
                               side_effect=[(b'com.fum.one',), (b'com.fum.one', b'com.fum.two')]), \
             mock.patch.object(сам.система, 'значение', return_value=b'value'):
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'список.*изменился'):
                сам.система.снять(сам.источник)

    def test_ресурсная_вилка_отклоняется_без_чтения_значений(сам):
        данные = b'com.apple.ResourceFork\0'
        def список(дескриптор, указатель, размер, параметры):
            if указатель is None:
                return len(данные)
            сам.типы.memmove(указатель, данные, len(данные))
            return len(данные)
        with mock.patch.object(сам.система, '_список', side_effect=список), \
             mock.patch.object(сам.система, 'значение') as чтение:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'ресурсная вилка'):
                сам.система.снять(сам.источник)
        чтение.assert_not_called()

class ПроверкаПереносаСпискаДоступаДарвина(unittest.TestCase):
    """Адресная APFS-фикстура: при любом UNKNOWN ресурсы не очищаются."""

    удерживаемые_фикстуры = []

    def setUp(сам):
        if sys.platform != 'darwin' or os.uname().machine != 'arm64':
            сам.fail('для проверки нужен Darwin arm64; пропуск не является успехом')
        import ctypes

        сам.типы = ctypes
        сам.модуль = загрузить_модуль_автоматизации()
        сам.удержание = {
            'состояние': 'создание', 'каталог': None, 'источник': [],
            'назначение': [], 'другие': [], 'построения': [], 'наблюдения': [],
            'система': None, 'перенос': None, 'переносы': [], 'ошибка': None,
            'действие': None, 'аргументы_действия': None, 'фаза_действия': None,
        }
        сам.удерживаемые_фикстуры.append(сам.удержание)
        try:
            сам.каталог = Path(tempfile.mkdtemp(prefix='fum-acl-fd-', dir='/private/tmp'))
            сам.удержание['каталог'] = сам.каталог
            сам.путь_источника = сам.каталог / 'источник'
            сам.путь_назначения = сам.каталог / 'назначение'
            сам.источник = сам._открыть(сам.удержание['источник'], сам.путь_источника)
            сам.назначение = сам._открыть(сам.удержание['назначение'], сам.путь_назначения)
            сам.система = сам.модуль._ВызовыСписковДоступаДарвина()
            сам.удержание['система'] = сам.система
            сам.перенос = сам.модуль._ОпытныйПереносСпискаДоступа(
                сам.система, сам.источник, сам.назначение)
            сам.удержание['перенос'] = сам.перенос
            сам.удержание['переносы'].append(сам.перенос)
            сам.удержание['состояние'] = 'готово'
        except BaseException as ошибка:
            сам.удержание['состояние'] = 'неизвестно'
            сам.удержание['ошибка'] = ошибка
            raise

    def _открыть(сам, опора, путь):
        прежнее = сам.удержание['состояние']
        if прежнее == 'готово':
            сам._начать_операцию_фикстуры()
        elif прежнее != 'создание':
            raise AssertionError('фикстура не допускает открытие')
        флаги = os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC
        try:
            дескриптор = сам.модуль._приобрести_fd(
                опора, os.open, путь, флаги, 0o600)
            os.fchmod(дескриптор, 0o600)
        except BaseException as ошибка:
            сам.удержание['состояние'] = 'неизвестно'
            сам.удержание['ошибка'] = ошибка
            raise
        if прежнее == 'готово':
            сам.удержание['состояние'] = 'готово'
        return дескриптор

    def _начать_операцию_фикстуры(сам):
        if сам.удержание['состояние'] != 'готово':
            raise AssertionError('неизвестная или занятая фикстура')
        for перенос in сам.удержание['переносы']:
            if перенос.состояние not in ('готов', 'подтверждено'):
                сам.удержание['состояние'] = 'неизвестно'
                сам.удержание['ошибка'] = перенос.ошибка
                raise AssertionError('перенос фикстуры не подтверждён')
        сам.удержание['состояние'] = 'операция начата'

    def _действие_фикстуры(сам, имя, операция, *аргументы):
        сам._начать_операцию_фикстуры()
        try:
            сам.удержание['действие'] = имя
            сам.удержание['аргументы_действия'] = аргументы
            сам.удержание['фаза_действия'] = 'начата'
            результат = операция(*аргументы)
            if сам.удержание['состояние'] != 'операция начата':
                raise AssertionError('состояние фикстуры изменилось')
            сам.удержание['фаза_действия'] = 'подтверждена'
            сам.удержание['состояние'] = 'готово'
            return результат
        except BaseException as ошибка:
            сам.удержание['состояние'] = 'неизвестно'
            if сам.удержание['ошибка'] is None:
                сам.удержание['ошибка'] = ошибка
            raise

    def _открыть_каталог(сам, путь):
        сам._начать_операцию_фикстуры()
        флаги = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
        try:
            дескриптор = сам.модуль._приобрести_fd(
                сам.удержание['другие'], os.open, путь, флаги)
        except BaseException as ошибка:
            сам.удержание['состояние'] = 'неизвестно'
            сам.удержание['ошибка'] = ошибка
            raise
        сам.удержание['состояние'] = 'готово'
        return дескриптор

    def _текст_для_всех(сам, правило):
        return (b'!#acl 1\n'
                b'group:ABCDEFAB-CDEF-ABCD-EFAB-CDEF0000000C:everyone:12:'
                + правило + b'\n')

    def _задать_список(сам, дескриптор, текст):
        сам._начать_операцию_фикстуры()
        try:
            сам._задать_список_внутри(дескриптор, текст)
            if сам.удержание['состояние'] != 'операция начата':
                raise AssertionError('состояние фикстуры изменилось')
        except BaseException as ошибка:
            сам.удержание['состояние'] = 'неизвестно'
            if сам.удержание['ошибка'] is None:
                сам.удержание['ошибка'] = ошибка
            raise
        сам.удержание['состояние'] = 'готово'

    def _задать_список_внутри(сам, дескриптор, текст):
        if сам.удержание['состояние'] != 'операция начата':
            raise AssertionError('не начата операция фикстуры')
        типы = сам.типы
        библиотека = типы.CDLL(None, use_errno=True)
        разобрать = библиотека.acl_from_text
        разобрать.argtypes = [типы.c_char_p]
        разобрать.restype = типы.c_void_p
        установить = библиотека.acl_set_fd_np
        установить.argtypes = [типы.c_int, типы.c_void_p, типы.c_int]
        установить.restype = типы.c_int
        освободить = библиотека.acl_free
        освободить.argtypes = [типы.c_void_p]
        освободить.restype = типы.c_int
        запись = {
            'библиотека': библиотека, 'указатель': None, 'получение': 'начато',
            'установка': 'не начата', 'освобождение': 'не начато', 'ошибка': None,
        }
        сам.удержание['построения'].append(запись)
        try:
            указатель = разобрать(текст)
            if not указатель:
                запись['получение'] = 'отказ'
                raise OSError(типы.get_errno(), 'не разобран синтетический список доступа')
            запись['указатель'] = указатель
            запись['получение'] = 'подтверждено'
            запись['установка'] = 'начата'
            if установить(дескриптор, указатель, 0x100) != 0:
                raise OSError(типы.get_errno(), 'не установлен синтетический список доступа')
            запись['установка'] = 'подтверждена'
            запись['освобождение'] = 'начато'
            if освободить(указатель) != 0:
                raise OSError(типы.get_errno(), 'неизвестен исход освобождения фикстуры')
            запись['освобождение'] = 'подтверждено'
        except BaseException as ошибка:
            запись['ошибка'] = ошибка
            сам.удержание['состояние'] = 'неизвестно'
            сам.удержание['ошибка'] = ошибка
            raise

    def _реальный_список(сам, дескриптор, число_записей):
        сам._начать_операцию_фикстуры()
        try:
            результат = сам._реальный_список_внутри(дескриптор, число_записей)
            if сам.удержание['состояние'] != 'операция начата':
                raise AssertionError('состояние фикстуры изменилось')
        except BaseException as ошибка:
            сам.удержание['состояние'] = 'неизвестно'
            if сам.удержание['ошибка'] is None:
                сам.удержание['ошибка'] = ошибка
            raise
        сам.удержание['состояние'] = 'готово'
        return результат

    def _реальный_список_внутри(сам, дескриптор, число_записей):
        if сам.удержание['состояние'] != 'операция начата':
            raise AssertionError('не начата операция фикстуры')
        типы = сам.типы
        библиотека = типы.CDLL(None, use_errno=True)
        взять = библиотека.acl_get_fd_np
        взять.argtypes = [типы.c_int, типы.c_int]
        взять.restype = типы.c_void_p
        размер = библиотека.acl_size
        размер.argtypes = [типы.c_void_p]
        размер.restype = типы.c_ssize_t
        скопировать = библиотека.acl_copy_ext
        скопировать.argtypes = [типы.c_void_p, типы.c_void_p, типы.c_ssize_t]
        скопировать.restype = типы.c_ssize_t
        взять_запись = библиотека.acl_get_entry
        взять_запись.argtypes = [типы.c_void_p, типы.c_int, типы.POINTER(типы.c_void_p)]
        взять_запись.restype = типы.c_int
        взять_тип = библиотека.acl_get_tag_type
        взять_тип.argtypes = [типы.c_void_p, типы.POINTER(типы.c_int)]
        взять_тип.restype = типы.c_int
        взять_флаги = библиотека.acl_get_flagset_np
        взять_флаги.argtypes = [типы.c_void_p, типы.POINTER(типы.c_void_p)]
        взять_флаги.restype = типы.c_int
        взять_флаг = библиотека.acl_get_flag_np
        взять_флаг.argtypes = [типы.c_void_p, типы.c_int]
        взять_флаг.restype = типы.c_int
        взять_права = библиотека.acl_get_permset
        взять_права.argtypes = [типы.c_void_p, типы.POINTER(типы.c_void_p)]
        взять_права.restype = типы.c_int
        взять_право = библиотека.acl_get_perm_np
        взять_право.argtypes = [типы.c_void_p, типы.c_int]
        взять_право.restype = типы.c_int
        представить = библиотека.acl_to_text
        представить.argtypes = [типы.c_void_p, типы.POINTER(типы.c_ssize_t)]
        представить.restype = типы.c_void_p
        освободить = библиотека.acl_free
        освободить.argtypes = [типы.c_void_p]
        освободить.restype = типы.c_int
        запись = {'фаза': 'получение начато', 'указатель': None, 'библиотека': библиотека}
        сам.удержание['наблюдения'].append(запись)
        список = взять(дескриптор, 0x100)
        if not список:
            запись['фаза'] = 'отказ'
            raise OSError(типы.get_errno(), 'не прочитан список доступа фикстуры')
        запись['указатель'] = список
        запись['фаза'] = 'получен'
        длина = размер(список)
        сам.assertGreater(длина, 0)
        буфер = типы.create_string_buffer(длина)
        сам.assertEqual(скопировать(буфер, список, длина), длина)
        результаты = []
        for номер in range(число_записей):
            элемент, флаги, права = типы.c_void_p(), типы.c_void_p(), типы.c_void_p()
            вид = типы.c_int()
            сам.assertEqual(взять_запись(список, 0 if номер == 0 else -1, типы.byref(элемент)), 0)
            сам.assertEqual(взять_тип(элемент, типы.byref(вид)), 0)
            сам.assertEqual(взять_флаги(элемент, типы.byref(флаги)), 0)
            сам.assertEqual(взять_права(элемент, типы.byref(права)), 0)
            наследуется = взять_флаг(флаги, 1 << 4)
            выполнение = взять_право(права, 1 << 3)
            сам.assertGreaterEqual(наследуется, 0)
            сам.assertGreaterEqual(выполнение, 0)
            результаты.append((вид.value, int(bool(наследуется)), int(bool(выполнение))))
        элемент = типы.c_void_p()
        типы.set_errno(0)
        сам.assertEqual(взять_запись(список, -1, типы.byref(элемент)), -1)
        сам.assertEqual(типы.get_errno(), errno.EINVAL)
        данные = буфер.raw[:длина]
        запись_текста = {'фаза': 'получение начато', 'указатель': None, 'библиотека': библиотека}
        сам.удержание['наблюдения'].append(запись_текста)
        длина_текста = типы.c_ssize_t()
        указатель_текста = представить(список, типы.byref(длина_текста))
        if not указатель_текста:
            запись_текста['фаза'] = 'отказ'
            raise OSError(типы.get_errno(), 'не получен текст списка фикстуры')
        запись_текста['указатель'] = указатель_текста
        запись_текста['фаза'] = 'получен'
        сам.assertGreater(длина_текста.value, 0)
        сам.assertLessEqual(длина_текста.value, 64 * 1024)
        текст = типы.string_at(указатель_текста, длина_текста.value)
        запись_текста['фаза'] = 'освобождение начато'
        if освободить(указатель_текста) != 0:
            запись_текста['фаза'] = 'неизвестно'
            raise OSError(типы.get_errno(), 'неизвестен исход освобождения текста фикстуры')
        запись_текста['фаза'] = 'освобождён'
        запись['фаза'] = 'освобождение начато'
        if освободить(список) != 0:
            запись['фаза'] = 'неизвестно'
            raise OSError(типы.get_errno(), 'неизвестен исход acl_free фикстуры')
        запись['фаза'] = 'освобождён'
        return данные, tuple(результаты), текст

    def test_фикстура_не_повторяет_создание_каталога_после_потери_результата(сам):
        путь = сам.каталог / 'модель-неизвестного-каталога'
        исходное = os.mkdir
        подтверждения = []
        ошибка = OSError(errno.EIO, 'потерян результат создания каталога')
        def создать_и_потерять(*аргументы):
            исходное(*аргументы)
            подтверждения.append(True)
            raise ошибка
        with mock.patch.object(os, 'mkdir', side_effect=создать_и_потерять) as создание:
            with сам.assertRaises(OSError) as итог:
                сам._действие_фикстуры('каталог', os.mkdir, путь, 0o700)
            with сам.assertRaises(AssertionError):
                сам._действие_фикстуры('каталог', os.mkdir, путь, 0o700)
        сам.assertIs(итог.exception, ошибка)
        сам.assertEqual(подтверждения, [True])
        сам.assertEqual(сам.удержание['состояние'], 'неизвестно')
        сам.assertIs(сам.удержание['ошибка'], ошибка)
        сам.assertEqual(сам.удержание['действие'], 'каталог')
        сам.assertEqual(сам.удержание['аргументы_действия'], (путь, 0o700))
        сам.assertEqual(сам.удержание['фаза_действия'], 'начата')
        создание.assert_called_once_with(путь, 0o700)

    def test_фикстура_не_повторяет_смену_прав_после_потери_результата(сам):
        исходное = os.fchmod
        подтверждения = []
        ошибка = OSError(errno.EIO, 'потерян результат смены прав')
        def изменить_и_потерять(*аргументы):
            исходное(*аргументы)
            подтверждения.append(True)
            raise ошибка
        with mock.patch.object(os, 'fchmod', side_effect=изменить_и_потерять) as изменение:
            with сам.assertRaises(OSError) as итог:
                сам._действие_фикстуры('режим', os.fchmod, сам.источник, 0o755)
            with сам.assertRaises(AssertionError):
                сам._действие_фикстуры('режим', os.fchmod, сам.источник, 0o755)
        сам.assertIs(итог.exception, ошибка)
        сам.assertEqual(подтверждения, [True])
        сам.assertEqual(сам.удержание['состояние'], 'неизвестно')
        сам.assertIs(сам.удержание['ошибка'], ошибка)
        сам.assertEqual(сам.удержание['действие'], 'режим')
        сам.assertEqual(сам.удержание['аргументы_действия'], (сам.источник, 0o755))
        сам.assertEqual(сам.удержание['фаза_действия'], 'начата')
        изменение.assert_called_once_with(сам.источник, 0o755)

    def test_фикстура_не_повторяет_установку_после_потерянного_результата(сам):
        типы = сам.типы
        библиотека = типы.CDLL(None, use_errno=True)
        разобрать = библиотека.acl_from_text
        разобрать.argtypes = [типы.c_char_p]
        разобрать.restype = типы.c_void_p
        установить = библиотека.acl_set_fd_np
        установить.argtypes = [типы.c_int, типы.c_void_p, типы.c_int]
        установить.restype = типы.c_int
        освободить = библиотека.acl_free
        освободить.argtypes = [типы.c_void_p]
        освободить.restype = типы.c_int
        ошибка = OSError(errno.EIO, 'потерян результат установки фикстуры')
        подтверждения = []
        def установить_и_потерять(*аргументы):
            if установить(*аргументы) != 0:
                raise OSError(типы.get_errno(), 'установка фикстуры не выполнена')
            подтверждения.append(True)
            raise ошибка
        подмена = mock.Mock()
        подмена.acl_from_text = mock.Mock(wraps=разобрать)
        подмена.acl_set_fd_np = mock.Mock(side_effect=установить_и_потерять)
        подмена.acl_free = mock.Mock(wraps=освободить)
        текст = сам._текст_для_всех(b'deny:execute')
        with mock.patch.object(типы, 'CDLL', return_value=подмена) as загрузка:
            with сам.assertRaises(OSError) as итог:
                сам._задать_список(сам.источник, текст)
            with сам.assertRaises(AssertionError):
                сам._задать_список(сам.источник, текст)
            with сам.assertRaises(AssertionError):
                сам._реальный_список(сам.источник, 1)
            with сам.assertRaises(AssertionError):
                сам._задать_список_внутри(сам.источник, текст)
        сам.assertIs(итог.exception, ошибка)
        сам.assertEqual(подтверждения, [True])
        сам.assertEqual(сам.удержание['состояние'], 'неизвестно')
        сам.assertIs(сам.удержание['ошибка'], ошибка)
        сам.assertEqual(сам.удержание['построения'][-1]['установка'], 'начата')
        загрузка.assert_called_once()
        подмена.acl_from_text.assert_called_once()
        подмена.acl_set_fd_np.assert_called_once()
        подмена.acl_free.assert_not_called()

    def test_фикстура_не_повторяет_освобождение_после_потери_результата(сам):
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        типы = сам.типы
        библиотека = типы.CDLL(None, use_errno=True)
        освободить = библиотека.acl_free
        освободить.argtypes = [типы.c_void_p]
        освободить.restype = типы.c_int
        ошибка = OSError(errno.EIO, 'потерян результат освобождения фикстуры')
        подтверждения = []
        def освободить_и_потерять(указатель):
            if освободить(указатель) != 0:
                raise OSError(типы.get_errno(), 'освобождение фикстуры не выполнено')
            подтверждения.append(True)
            raise ошибка
        class ПодменённаяБиблиотека:
            def __init__(владелец):
                владелец.acl_free = mock.Mock(side_effect=освободить_и_потерять)
            def __getattr__(владелец, имя):
                return getattr(библиотека, имя)
        подмена = ПодменённаяБиблиотека()
        with mock.patch.object(типы, 'CDLL', return_value=подмена) as загрузка:
            with сам.assertRaises(OSError) as итог:
                сам._реальный_список(сам.источник, 1)
            with сам.assertRaises(AssertionError):
                сам._реальный_список(сам.источник, 1)
            with сам.assertRaises(AssertionError):
                сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        сам.assertIs(итог.exception, ошибка)
        сам.assertEqual(подтверждения, [True])
        сам.assertEqual(сам.удержание['состояние'], 'неизвестно')
        сам.assertIs(сам.удержание['ошибка'], ошибка)
        сам.assertEqual(сам.удержание['наблюдения'][-1]['фаза'], 'освобождение начато')
        загрузка.assert_called_once()
        подмена.acl_free.assert_called_once()

    def test_прерывание_чтения_фикстуры_сохраняется_и_запрещает_повтор(сам):
        ошибка = KeyboardInterrupt('модель прерывания')
        with mock.patch.object(сам, '_реальный_список_внутри', side_effect=ошибка) as чтение, \
             mock.patch.object(сам.типы, 'CDLL') as загрузка:
            with сам.assertRaises(KeyboardInterrupt) as итог:
                сам._реальный_список(сам.источник, 1)
            with сам.assertRaises(AssertionError):
                сам._реальный_список(сам.источник, 1)
        сам.assertIs(итог.exception, ошибка)
        сам.assertIs(сам.удержание['ошибка'], ошибка)
        сам.assertEqual(сам.удержание['состояние'], 'неизвестно')
        чтение.assert_called_once()
        загрузка.assert_not_called()

    def test_неизвестный_перенос_закрывает_операции_фикстуры(сам):
        ошибка = OSError(errno.EIO, 'неизвестный перенос')
        сам.перенос.ошибка = ошибка
        сам.перенос.состояние = 'неизвестно'
        with mock.patch.object(сам.типы, 'CDLL') as загрузка:
            with сам.assertRaises(AssertionError):
                сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
            with сам.assertRaises(AssertionError):
                сам._реальный_список(сам.источник, 1)
            with сам.assertRaises(AssertionError):
                сам._реальный_список_внутри(сам.источник, 1)
        сам.assertEqual(сам.удержание['состояние'], 'неизвестно')
        сам.assertIs(сам.удержание['ошибка'], ошибка)
        загрузка.assert_not_called()

    def test_отсутствующий_список_не_устанавливается_и_не_повторяется(сам):
        with mock.patch.object(сам.система, '_установить') as установка:
            сам.assertFalse(сам.перенос.выполнить())
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        установка.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'подтверждено')
        сам.assertIsNone(сам.перенос.попытка)
        сам.assertTrue(all(объект['фаза'] == 'освобождён' for объект in сам.система._ресурсы))

    def test_неподтверждённая_архитектура_отклоняется_до_загрузки_библиотеки(сам):
        with mock.patch.object(сам.модуль.os, 'uname', return_value=mock.Mock(machine='x86_64')), \
             mock.patch.object(сам.типы, 'CDLL') as библиотека:
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.модуль._ВызовыСписковДоступаДарвина()
        библиотека.assert_not_called()

    def test_ограничивающий_список_передаётся_полностью(сам):
        сам._действие_фикстуры('режим', os.fchmod, сам.источник, 0o755)
        сам.assertTrue(os.access(сам.путь_источника, os.X_OK))
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        сам.assertFalse(os.access(сам.путь_источника, os.X_OK))
        исходные = сам._реальный_список(сам.источник, 1)
        сам.assertEqual(исходные[1], ((2, 0, 1),))
        сам.assertTrue(сам.перенос.выполнить())
        сам.assertEqual(сам.перенос.состояние, 'подтверждено')
        сам.assertEqual(сам._реальный_список(сам.назначение, 1), исходные)
        сам._действие_фикстуры('режим', os.fchmod, сам.назначение, 0o755)
        сам.assertFalse(os.access(сам.путь_назначения, os.X_OK))
        сам.assertEqual(сам._реальный_список(сам.назначение, 1), исходные)

    def test_унаследованный_порядок_и_флаги_сохраняются(сам):
        каталог = сам.каталог / 'наследование'
        сам._действие_фикстуры('каталог', os.mkdir, каталог, 0o700)
        каталог_дескриптор = сам._открыть_каталог(каталог)
        сам._задать_список(
            каталог_дескриптор, сам._текст_для_всех(b'allow,file_inherit:execute'))
        путь = каталог / 'наследник'
        источник = сам._открыть(сам.удержание['другие'], путь)
        сам._действие_фикстуры('режим', os.fchmod, источник, 0o700)
        унаследованный = сам._реальный_список(источник, 1)
        сам.assertEqual(унаследованный[1], ((1, 1, 1),))
        сам.assertTrue(os.access(путь, os.X_OK))
        строки = унаследованный[2].splitlines()
        сам.assertEqual(len(строки), 2)
        сам.assertEqual(строки[0], b'!#acl 1')
        составной = сам._текст_для_всех(b'deny:execute') + строки[1] + b'\n'
        сам._задать_список(источник, составной)
        исходные = сам._реальный_список(источник, 2)
        сам.assertEqual(исходные[1], ((2, 0, 1), (1, 1, 1)))
        сам.assertEqual(исходные[2].splitlines()[2], строки[1])
        сам.assertFalse(os.access(путь, os.X_OK))
        система = сам.модуль._ВызовыСписковДоступаДарвина()
        перенос = сам.модуль._ОпытныйПереносСпискаДоступа(система, источник, сам.назначение)
        сам.удержание['унаследованный'] = (система, перенос)
        сам.удержание['переносы'].append(перенос)
        сам.assertTrue(перенос.выполнить())
        сам.assertEqual(сам._реальный_список(сам.назначение, 2), исходные)
        сам._действие_фикстуры('режим', os.fchmod, сам.назначение, 0o700)
        сам.assertFalse(os.access(сам.путь_назначения, os.X_OK))
        сам.assertEqual(сам._реальный_список(сам.назначение, 2), исходные)

    def test_реальный_запрет_чтения_защиты_не_считается_отсутствием(сам):
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:readsecurity'))
        with mock.patch.object(сам.система, '_установить') as установка:
            with сам.assertRaises(OSError) as итог:
                сам.перенос.выполнить()
        сам.assertEqual(итог.exception.errno, errno.EACCES)
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')
        установка.assert_not_called()

    def test_неподдерживаемая_файловая_система_отказывает_до_установки(сам):
        def нет_поддержки(*аргументы):
            сам.типы.set_errno(errno.ENOTSUP)
            return -1
        with mock.patch.object(сам.система, '_стат', side_effect=нет_поддержки) as чтение, \
             mock.patch.object(сам.система, '_установить') as установка:
            with сам.assertRaises(OSError) as итог:
                сам.перенос.выполнить()
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        сам.assertEqual(итог.exception.errno, errno.ENOTSUP)
        чтение.assert_called_once()
        установка.assert_not_called()

    def test_неподтверждённый_признак_не_считается_отсутствием(сам):
        with mock.patch.object(сам.система, '_наличие', return_value=0), \
             mock.patch.object(сам.система, '_установить') as установка:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'признак'):
                сам.перенос.выполнить()
        установка.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')

    def test_несовпадение_структуры_статуса_отказывает_до_установки(сам):
        with mock.patch.object(сам.система, '_стат', return_value=0) as статус, \
             mock.patch.object(сам.система, '_установить') as установка:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'fstatx'):
                сам.перенос.выполнить()
        статус.assert_called_once()
        установка.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')

    def test_неизвестное_получение_объекта_не_повторяется(сам):
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        ошибка = OSError(errno.EIO, 'потерян результат получения объекта')
        with mock.patch.object(сам.система, '_взять_список', side_effect=ошибка) as получение, \
             mock.patch.object(сам.система, '_установить') as установка, \
             mock.patch.object(сам.система, '_кончить_список') as освобождение:
            with сам.assertRaises(OSError) as итог:
                сам.перенос.выполнить()
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        сам.assertIs(итог.exception, ошибка)
        сам.assertEqual(сам.перенос.состояние, 'неизвестно')
        сам.assertEqual(сам.система._ресурсы[-1]['фаза'], 'получение начато')
        получение.assert_called_once()
        установка.assert_not_called()
        освобождение.assert_not_called()

    def test_слишком_большой_список_не_копируется(сам):
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        with mock.patch.object(сам.система, '_размер_списка',
                               return_value=сам.система._предел_байтов + 1), \
             mock.patch.object(сам.система, '_копия_списка') as копия, \
             mock.patch.object(сам.система, '_установить') as установка:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'размер'):
                сам.перенос.выполнить()
        копия.assert_not_called()
        установка.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')

    def test_изменение_списка_до_установки_прерывает_перенос(сам):
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        снять = сам.система._снять
        число = []
        def подменить(дескриптор):
            данные, объект = снять(дескриптор)
            if дескриптор == сам.источник:
                число.append(True)
                if len(число) == 2:
                    данные = данные + b'!'
            return данные, объект
        with mock.patch.object(сам.система, '_снять', side_effect=подменить), \
             mock.patch.object(сам.система, '_установить') as установка:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'изменились'):
                сам.перенос.выполнить()
        установка.assert_not_called()
        сам.assertEqual(len(число), 2)
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')

    def test_неизвестная_установка_после_реального_эффекта_не_повторяется(сам):
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        исходная = сам.система._установить
        подтверждённые = []
        ошибка = OSError(errno.EIO, 'потерян результат set')
        def установить_и_потерять(*аргументы):
            исходная(*аргументы)
            подтверждённые.append(True)
            raise ошибка
        with mock.patch.object(сам.система, '_установить', side_effect=установить_и_потерять) as установка:
            with сам.assertRaises(OSError) as итог:
                сам.перенос.выполнить()
            with mock.patch.object(сам.система, '_снять', side_effect=AssertionError('повторное чтение')):
                with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                    сам.перенос.выполнить()
        сам.assertIs(итог.exception, ошибка)
        сам.assertIs(сам.перенос.ошибка, ошибка)
        сам.assertEqual(подтверждённые, [True])
        сам.assertEqual(сам.перенос.состояние, 'неизвестно')
        сам.assertEqual(сам.перенос.попытка, ('установка', 'начата'))
        установка.assert_called_once()

    def test_несовпадение_внешних_байтов_после_установки_не_подтверждается(сам):
        сам._задать_список(сам.источник, сам._текст_для_всех(b'deny:execute'))
        снять = сам.система._снять
        число = []
        def подменить(дескриптор):
            данные, объект = снять(дескриптор)
            if дескриптор == сам.назначение:
                число.append(True)
                if len(число) == 3:
                    данные = данные[:-1] + bytes([данные[-1] ^ 1])
            return данные, объект
        with mock.patch.object(сам.система, '_снять', side_effect=подменить):
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'не подтверждён'):
                сам.перенос.выполнить()
        сам.assertEqual(len(число), 3)
        сам.assertEqual(сам.перенос.состояние, 'неизвестно')

    def test_неизвестное_освобождение_не_повторяется(сам):
        исходное = сам.система._кончить_безопасность
        ошибка = OSError(errno.EIO, 'потерян результат освобождения')
        def освободить_и_потерять(указатель):
            исходное(указатель)
            raise ошибка
        with mock.patch.object(сам.система, '_кончить_безопасность',
                               side_effect=освободить_и_потерять) as освобождение:
            with сам.assertRaises(OSError) as итог:
                сам.перенос.выполнить()
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        сам.assertIs(итог.exception, ошибка)
        сам.assertEqual(сам.перенос.состояние, 'неизвестно')
        сам.assertEqual(сам.система._ресурсы[-1]['фаза'], 'неизвестно')
        освобождение.assert_called_once()

    def test_чужой_поток_не_потребляет_владельца(сам):
        with mock.patch.object(сам.модуль.threading, 'current_thread', return_value=object()), \
             mock.patch.object(сам.система, '_снять') as чтение:
            with сам.assertRaises(сам.модуль.ОшибкаОтчёта):
                сам.перенос.выполнить()
        чтение.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'готов')
        сам.assertFalse(сам.перенос.выполнить())

    def test_готовый_список_назначения_не_перезаписывается(сам):
        сам._задать_список(сам.назначение, сам._текст_для_всех(b'deny:execute'))
        with mock.patch.object(сам.система, '_установить') as установка:
            with сам.assertRaisesRegex(сам.модуль.ОшибкаОтчёта, 'уже имеет'):
                сам.перенос.выполнить()
        установка.assert_not_called()
        сам.assertEqual(сам.перенос.состояние, 'отказ до записи')


class ФикстураОтчётов:
    def __init__(сам) -> None:
        сам.временный_каталог = tempfile.TemporaryDirectory()
        сам.корень = Path(сам.временный_каталог.name)
        сам.каталог_сессии = сам.корень / "Журнал" / имя_сессии
        сам.каталог_сессии.mkdir(parents=True)
        сам.запрос = сам.каталог_сессии / "запрос.md"
        сам.запрос.write_text(
            "# Исходный запрос 2026-08-04 20:45:26 MSK\n\n"
            "## Текст запроса\n\n````text\nПроверить.\n````\n",
            encoding="utf-8",
        )
        сам.отчёт = сам.каталог_сессии / "отчёт.md"
        сам.отчёт.write_text(
            "# Отчёт 2026-08-04 20:45:26 MSK\n\n"
            "Содержательное введение, которое нельзя менять рендером.\n\n"
            "## Профиль времени выполнения\n\n"
            "### Прямые запуски проверок\n\n"
            f"{открытый_маркер}\n"
            "Запусков пока нет.\n"
            f"{конечный_маркер}\n\n"
            "## Проверки\n\n"
            "Содержательный хвост, который нельзя менять рендером.\n",
            encoding="utf-8",
        )
        сам.каталог_записей = (
            сам.каталог_сессии
            / "материалы"
            / "запуски-проверок"
        )
        for команда in (
            ("init", "-q"),
            ("config", "user.name", "FUM Tests"),
            ("config", "user.email", "fum-tests@example.invalid"),
            ("add", "."),
            ("commit", "-q", "-m", "Исходная фикстура"),
        ):
            subprocess.run(
                ["git", *команда],
                cwd=сам.корень,
                check=True,
                capture_output=True,
            )

    def очистить(сам) -> None:
        сам.временный_каталог.cleanup()

    def аргументы(сам, команда: str, *дополнения: str) -> list[str]:
        return [
            sys.executable,
            str(сценарий),
            команда,
            "--корень-репозитория",
            str(сам.корень),
            "--запрос",
            путь_запроса,
            *дополнения,
        ]

    def выполнить(
        сам,
        команда: str,
        *дополнения: str,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            сам.аргументы(команда, *дополнения),
            cwd=сам.корень,
            check=False,
            capture_output=True,
            text=True,
        )

    def запустить(
        сам,
        идентификатор: str,
        *вызываемая_команда: str,
        название: str = "целевая проверка",
        исполнитель: str = "root",
        тайм_аут: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        аргументы = [
            "--название",
            название,
            "--исполнитель",
            исполнитель,
            "--идентификатор-запуска",
            идентификатор,
        ]
        if тайм_аут is not None:
            аргументы.extend(["--тайм-аут-секунды", тайм_аут])
        путь_полной_проверки = (
            сам.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        класс_проверки = (
            "полная"
            if len(вызываемая_команда) >= 2
            and Path(вызываемая_команда[1]).resolve()
            == путь_полной_проверки.resolve()
            else "адресная"
        )
        аргументы.extend(["--класс-проверки", класс_проверки, "--обычная-схема-профиля"])
        аргументы.extend(["--", *вызываемая_команда])
        return сам.выполнить("запустить", *аргументы)

    def файлы_записей(сам) -> list[Path]:
        if not сам.каталог_записей.exists():
            return []
        return sorted(
            файл
            for файл in сам.каталог_записей.glob("*.json")
            if файл.name != "снимок.json"
        )

    def записи(сам) -> list[dict[str, object]]:
        return [
            json.loads(файл.read_text(encoding="utf-8"))
            for файл in сам.файлы_записей()
        ]

    def запись(сам, идентификатор: str) -> dict[str, object]:
        совпадения = [
            запись
            for запись in сам.записи()
            if запись["идентификатор"] == идентификатор
        ]
        if len(совпадения) != 1:
            raise AssertionError(
                f"Ожидалась одна запись {идентификатор}, получено {len(совпадения)}"
            )
        return совпадения[0]

    def записать_завершённую_запись(
        сам,
        порядок: int,
        идентификатор: str,
        длительность: int,
        *,
        название: str = "проверка",
        исполнитель: str = "root",
        статус: str = "успешно",
        код: int | None = 0,
        пояснение: str | None = None,
    ) -> Path:
        сам.каталог_записей.mkdir(parents=True, exist_ok=True)
        файл = сам.каталог_записей / f"{порядок}_{идентификатор}.json"
        файл.write_text(
            json.dumps(
                {
                    "схема": "fum.test-run.v1",
                    "идентификатор": идентификатор,
                    "сессия": путь_запроса,
                    "порядок": порядок,
                    "исполнитель": исполнитель,
                    "вызов": название,
                    "состояние": "завершён",
                    "длительность_наносекунды": длительность,
                    "статус": статус,
                    "код_завершения": код,
                    "пояснение": пояснение,
                },
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
            encoding="utf-8",
        )
        return файл


class ОтчётыОЗапускахПроверок(unittest.TestCase):
    def test_полный_запуск_слияния_требует_точного_источника_и_полного_набора_аргументов(сам):
        спецификация = importlib.util.spec_from_file_location("отчёты_слияния_для_теста", сценарий)
        модуль = importlib.util.module_from_spec(спецификация)
        спецификация.loader.exec_module(модуль)
        источник = сценарий.resolve().parents[3]
        with tempfile.TemporaryDirectory() as временный:
            кандидат = Path(временный).resolve()
            команда = [sys.executable, "-B", str(источник / "Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py"),
                       "--repo-root", str(кандидат), "--request", путь_запроса,
                       "--commit-message-file", str(кандидат / "коммит.txt"), "--codex-thread-id", "00000000-0000-4000-8000-000000000001",
                       "--источник-проверок", "1" * 40, "--ведущая-основа", "2" * 40,
                       "--свидетельство-контура", str(Path(путь_запроса).parent / "материалы/контур-слияния.json")]
            сам.assertTrue(модуль.является_запуском_полной_проверки(кандидат, команда))
            for хвост in (["--list"], ["--skip-session-coherence"], ["--repo-root", str(источник)]):
                with сам.subTest(хвост=хвост):
                    сам.assertFalse(модуль.является_запуском_полной_проверки(кандидат, команда + хвост))
            команда[2] = str(кандидат / "Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py")
            сам.assertFalse(модуль.является_запуском_полной_проверки(кандидат, команда))

    @property
    def фикстура(сам) -> ФикстураОтчётов:
        if not hasattr(сам, "_фикстура"):
            сам._фикстура = ФикстураОтчётов()
            сам.addCleanup(сам._фикстура.очистить)
        return сам._фикстура

    def проверить_общие_поля(
        сам,
        запись: dict[str, object],
        идентификатор: str,
        порядок: int,
    ) -> None:
        сам.assertEqual(set(запись), поля_профилированной_записи)
        сам.assertEqual(запись["схема"], "fum.test-run.v3")
        сам.assertEqual(запись["идентификатор"], идентификатор)
        сам.assertEqual(запись["сессия"], путь_запроса)
        сам.assertEqual(запись["порядок"], порядок)
        сам.assertEqual(запись["состояние"], "завершён")
        сам.assertIsInstance(запись["длительность_наносекунды"], int)
        сам.assertGreaterEqual(запись["длительность_наносекунды"], 0)
        сам.assertIsNone(запись["план"])
        сам.assertEqual(запись["наблюдения"], [])
        сам.assertEqual(запись["профиль_проверки"]["класс"], "адресная")

    def test_пустая_таблица_сохраняет_заголовки_и_нулевой_итог(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        таблица, итог = модуль.сформировать_таблицу_запусков([])
        сам.assertEqual(таблица, [
            "| Вызов | Длительность | Результат |",
            "| ----- | ------------ | --------- |",
        ])
        сам.assertEqual(итог, "0")

    def test_первая_контрольная_точка_не_требует_фиктивного_завершённого_запуска(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        проверка = """
import importlib.util
import os
import sys
спецификация = importlib.util.spec_from_file_location("отчёты", sys.argv[1])
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)
ошибки = модуль.проверить_журнал_сессии(
    sys.argv[2], sys.argv[3], контрольная_точка=True,
    идентификатор_активного_запуска=os.environ["FUM_CHECK_RUN_ID"],
)
assert not ошибки, ошибки
"""
        for раунды in (False, True):
            with сам.subTest(приёмочные_раунды=раунды):
                фикстура = ФикстураОтчётов()
                сам.addCleanup(фикстура.очистить)
                пустой_блок = "\n".join((
                    открытый_маркер, "",
                    "| Вызов | Длительность | Результат |",
                    "| ----- | ------------ | --------- |", "",
                    "Общее время прямых запусков проверок: 0 с.", "",
                    конечный_маркер,
                ))
                фикстура.отчёт.write_bytes(модуль.заменить_управляемый_блок_в_байтах(
                    фикстура.отчёт.read_bytes(), пустой_блок,
                ))
                предпросмотр = фикстура.отчёт.read_bytes()
                сам.assertEqual(фикстура.файлы_записей(), [])
                дополнения = ["--приёмочные-раунды"] if раунды else ["--обычная-схема-профиля"]
                результат = фикстура.выполнить(
                    "запустить", "--название", "первая контрольная точка",
                    "--исполнитель", "корень", "--класс-проверки", "адресная",
                    *дополнения, "--", sys.executable, "-B", "-c", проверка,
                    str(сценарий), str(фикстура.корень), путь_запроса,
                )
                сам.assertEqual(результат.returncode, 0, результат.stderr)
                сам.assertEqual(фикстура.отчёт.read_bytes(), предпросмотр)
                записи = фикстура.записи()
                сам.assertEqual(len(записи), 1)
                сам.assertEqual(записи[0]["состояние"], "завершён")
                сам.assertEqual(записи[0]["статус"], "успешно")
                сам.assertEqual(записи[0]["схема"], "fum.test-run.v4" if раунды else "fum.test-run.v3")
                сам.assertFalse((фикстура.каталог_записей / "снимок.json").exists())

    def test_обёртка_передаёт_свой_uuid_контрольной_точке_при_старом_значении_среды(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        завершённый = сам.фикстура.запустить(
            "00000000-0000-4000-8000-0000000000a4",
            sys.executable,
            "-B",
            "-c",
            "pass",
        )
        сам.assertEqual(завершённый.returncode, 0, завершённый.stderr)
        сам.assertEqual(
            модуль.выполнить_предпросмотр(
                сам.фикстура.корень,
                Path(путь_запроса),
            ),
            0,
        )
        run_id = "00000000-0000-4000-8000-0000000000a2"
        stale_id = "00000000-0000-4000-8000-0000000000a3"
        checker = r"""
import importlib.util
import json
import os
import sys
spec = importlib.util.spec_from_file_location("fum_run_report", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
errors = module.проверить_журнал_сессии(
    sys.argv[2], sys.argv[3],
    контрольная_точка=True,
    идентификатор_активного_запуска=os.environ.get("FUM_CHECK_RUN_ID"),
)
print(json.dumps({"run_id": os.environ.get("FUM_CHECK_RUN_ID"), "errors": errors}))
raise SystemExit(bool(errors))
"""

        with mock.patch.dict(os.environ, {"FUM_CHECK_RUN_ID": stale_id}):
            результат = сам.фикстура.выполнить(
                "запустить",
                "--название",
                "проверить собственную активную запись",
                "--исполнитель",
                "корень",
                "--идентификатор-запуска",
                run_id,
                "--класс-проверки",
                "адресная",
                "--",
                sys.executable,
                "-c",
                checker,
                str(сценарий),
                str(сам.фикстура.корень),
                путь_запроса,
            )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        запись = сам.фикстура.запись(run_id)
        сам.assertEqual(запись["состояние"], "завершён")

    def test_контрольная_точка_не_разрешает_дополнительную_чужую_активную_запись(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        завершённый_id = "00000000-0000-4000-8000-0000000000a6"
        завершённый = сам.фикстура.запустить(
            завершённый_id,
            sys.executable,
            "-B",
            "-c",
            "pass",
        )
        сам.assertEqual(завершённый.returncode, 0, завершённый.stderr)
        сам.assertEqual(
            модуль.выполнить_предпросмотр(
                сам.фикстура.корень,
                Path(путь_запроса),
            ),
            0,
        )
        исходная = сам.фикстура.запись(завершённый_id)
        собственный_id = "00000000-0000-4000-8000-0000000000a7"
        чужой_id = "00000000-0000-4000-8000-0000000000a8"

        for порядок, идентификатор in ((2, собственный_id), (3, чужой_id)):
            активная = copy.deepcopy(исходная)
            активная.update(
                {
                    "идентификатор": идентификатор,
                    "порядок": порядок,
                    "состояние": "выполняется",
                    "длительность_наносекунды": None,
                    "статус": None,
                    "код_завершения": None,
                    "пояснение": None,
                    "план": None,
                    "наблюдения": [],
                }
            )
            путь = сам.фикстура.каталог_записей / f"{порядок}_{идентификатор}.json"
            путь.write_bytes(модуль.канонические_машинные_байты(активная))

        ошибки = модуль.проверить_журнал_сессии(
            сам.фикстура.корень,
            Path(путь_запроса),
            контрольная_точка=True,
            идентификатор_активного_запуска=собственный_id,
        )

        сам.assertIn(
            "контрольная точка допускает только одну собственную активную запись",
            ошибки,
        )

    def test_успех_создаёт_отдельную_завершённую_запись(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000001"
        начало = time.monotonic_ns()

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            "-c",
            "import time; time.sleep(0.03)",
            название="целевые тесты",
            исполнитель="root",
        )
        конец = time.monotonic_ns()

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual(len(сам.фикстура.файлы_записей()), 1)
        файл = сам.фикстура.файлы_записей()[0]
        сам.assertEqual(файл.name, f"1_{идентификатор}.json")
        запись = сам.фикстура.запись(идентификатор)
        сам.проверить_общие_поля(запись, идентификатор, 1)
        сам.assertEqual(запись["исполнитель"], "root")
        сам.assertEqual(запись["вызов"], "целевые тесты")
        сам.assertEqual(запись["статус"], "успешно")
        сам.assertEqual(запись["код_завершения"], 0)
        сам.assertIsNone(запись["пояснение"])
        сам.assertGreaterEqual(запись["длительность_наносекунды"], 20_000_000)
        сам.assertLessEqual(запись["длительность_наносекунды"], конец - начало)
        сам.assertFalse(
            [
                путь
                for путь in сам.фикстура.каталог_записей.iterdir()
                if путь.name != файл.name
            ]
        )

    def test_полная_проверка_встраивает_структурированные_наблюдения(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a1"
        путь_сценария_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_сценария_полной_проверки.parent.mkdir(parents=True)
        путь_сценария_полной_проверки.write_text(
            "import json, os\n"
            "from pathlib import Path\n"
            "путь = Path(os.environ['FUM_CHECK_RUN_OBSERVATIONS_PATH'])\n"
            "идентификатор = os.environ['FUM_CHECK_RUN_ID']\n"
            "значение = {\n"
            "    'схема': 'fum.smoke-test-observations.v1',\n"
            "    'идентификатор_запуска': идентификатор,\n"
            "    'текущая_проверка': None,\n"
            "    'план': [{\n"
            "        'ключ_проверки': 'Инструменты/fum-alpha/tests',\n"
            "        'название': 'Тесты fum-alpha',\n"
            "    }],\n"
            "    'наблюдения': [{\n"
            "        'ключ_проверки': 'Инструменты/fum-alpha/tests',\n"
            "        'название': 'Тесты fum-alpha',\n"
            "        'статус': 'неуспешно',\n"
            "        'длительность_наносекунды': 1250000,\n"
            "    }],\n"
            "}\n"
            "путь.write_text(json.dumps(значение, ensure_ascii=False, "
            "indent=2, sort_keys=True) + '\\n', encoding='utf-8')\n"
            "raise SystemExit(7)\n",
            encoding="utf-8",
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            str(путь_сценария_полной_проверки),
            название="полный smoke-check",
        )

        сам.assertEqual(результат.returncode, 7, результат.stderr)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(set(запись), поля_профилированной_записи)
        сам.assertEqual(запись["схема"], "fum.test-run.v3")
        сам.assertEqual(запись["профиль_проверки"]["класс"], "полная")
        сам.assertEqual(
            запись["план"],
            [
                {
                    "ключ_проверки": "Инструменты/fum-alpha/tests",
                    "название": "Тесты fum-alpha",
                }
            ],
        )
        сам.assertEqual(
            запись["наблюдения"],
            [
                {
                    "ключ_проверки": "Инструменты/fum-alpha/tests",
                    "название": "Тесты fum-alpha",
                    "статус": "неуспешно",
                    "длительность_наносекунды": 1_250_000,
                }
            ],
        )
        сам.assertFalse(
            any(
                "FUM_CHECK_RUN_OBSERVATIONS_PATH" in путь.name
                for путь in сам.фикстура.корень.rglob("*")
            )
        )

        закрытие = сам.фикстура.выполнить("закрыть")
        сам.assertEqual(закрытие.returncode, 0, закрытие.stderr)
        проверка = сам.фикстура.выполнить("проверить")
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)

    def test_ранний_отказ_подготовки_сохраняет_исходный_код(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a5"
        путь_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_полной_проверки.parent.mkdir(parents=True)
        путь_полной_проверки.write_text(
            "raise SystemExit(2)\n",
            encoding="utf-8",
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            str(путь_полной_проверки),
            название="отказ подготовки",
        )

        сам.assertEqual(результат.returncode, 2, результат.stderr)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertIsNone(запись["план"])
        сам.assertEqual(запись["наблюдения"], [])

    def test_ранний_фиксированный_отказ_сохраняет_план_без_наблюдений(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a9"
        путь_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_полной_проверки.parent.mkdir(parents=True)
        путь_полной_проверки.write_text(
            "import json, os\n"
            "from pathlib import Path\n"
            "значение = {\n"
            "    'схема': 'fum.smoke-test-observations.v1',\n"
            "    'идентификатор_запуска': os.environ['FUM_CHECK_RUN_ID'],\n"
            "    'текущая_проверка': None,\n"
            "    'план': [{\n"
            "        'ключ_проверки': 'Инструменты/fum-alpha/tests',\n"
            "        'название': 'Тесты fum-alpha',\n"
            "    }],\n"
            "    'наблюдения': [],\n"
            "}\n"
            "Path(os.environ['FUM_CHECK_RUN_OBSERVATIONS_PATH']).write_text(\n"
            "    json.dumps(значение, ensure_ascii=False, indent=2, "
            "sort_keys=True) + '\\n', encoding='utf-8'\n"
            ")\n"
            "raise SystemExit(7)\n",
            encoding="utf-8",
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            str(путь_полной_проверки),
            название="ранний фиксированный отказ",
        )

        сам.assertEqual(результат.returncode, 7, результат.stderr)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["статус"], "неуспешно")
        сам.assertEqual(запись["код_завершения"], 7)
        сам.assertEqual(
            запись["план"],
            [
                {
                    "ключ_проверки": "Инструменты/fum-alpha/tests",
                    "название": "Тесты fum-alpha",
                }
            ],
        )
        сам.assertEqual(запись["наблюдения"], [])

        закрытие = сам.фикстура.выполнить("закрыть")
        сам.assertEqual(закрытие.returncode, 0, закрытие.stderr)
        проверка = сам.фикстура.выполнить("проверить")
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)

    def test_тайм_аут_учитывает_текущий_зависший_тест(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a6"
        путь_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_полной_проверки.parent.mkdir(parents=True)
        путь_полной_проверки.write_text(
            "import json, os, time\n"
            "from pathlib import Path\n"
            "ключ = 'Инструменты/fum-alpha/tests'\n"
            "название = 'Тесты fum-alpha'\n"
            "значение = {\n"
            "    'схема': 'fum.smoke-test-observations.v1',\n"
            "    'идентификатор_запуска': os.environ['FUM_CHECK_RUN_ID'],\n"
            "    'план': [{'ключ_проверки': ключ, 'название': название}],\n"
            "    'наблюдения': [],\n"
            "    'текущая_проверка': {\n"
            "        'ключ_проверки': ключ,\n"
            "        'название': название,\n"
            "        'начало_монотонные_наносекунды': time.monotonic_ns(),\n"
            "    },\n"
            "}\n"
            "Path(os.environ['FUM_CHECK_RUN_OBSERVATIONS_PATH']).write_text(\n"
            "    json.dumps(значение, ensure_ascii=False, indent=2, "
            "sort_keys=True) + '\\n', encoding='utf-8'\n"
            ")\n"
            "time.sleep(10)\n",
            encoding="utf-8",
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            str(путь_полной_проверки),
            название="зависший тест",
            тайм_аут="0.15",
        )

        сам.assertEqual(результат.returncode, 124, результат.stderr)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["план"][0]["ключ_проверки"], "Инструменты/fum-alpha/tests")
        сам.assertEqual(len(запись["наблюдения"]), 1)
        наблюдение = запись["наблюдения"][0]
        сам.assertEqual(наблюдение["статус"], "не завершено")
        сам.assertGreater(наблюдение["длительность_наносекунды"], 0)

    def test_полная_проверка_без_обязательного_конверта_завершается_ошибкой(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a2"
        путь_сценария_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_сценария_полной_проверки.parent.mkdir(parents=True)
        путь_сценария_полной_проверки.write_text(
            "import os\n"
            "from pathlib import Path\n"
            "Path(os.environ['FUM_CHECK_RUN_OBSERVATIONS_PATH']).unlink()\n",
            encoding="utf-8",
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            str(путь_сценария_полной_проверки),
            название="smoke без конверта",
        )

        сам.assertEqual(результат.returncode, 125)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["схема"], "fum.test-run.v3")
        сам.assertEqual(запись["статус"], "не завершено")
        сам.assertIn("конверт", запись["пояснение"])

    @unittest.skipUnless(hasattr(signal, "SIGTERM"), "Нужен POSIX-сигнал SIGTERM")
    def test_сигнал_имеет_приоритет_над_ошибкой_конверта(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a7"
        путь_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_полной_проверки.parent.mkdir(parents=True)
        путь_полной_проверки.write_text(
            "import os, signal\n"
            "from pathlib import Path\n"
            "Path(os.environ['FUM_CHECK_RUN_OBSERVATIONS_PATH']).write_text(\n"
            "    '{}\\n', encoding='utf-8'\n"
            ")\n"
            "os.kill(os.getpid(), signal.SIGTERM)\n",
            encoding="utf-8",
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            str(путь_полной_проверки),
            название="прерванный smoke-check",
        )

        сам.assertEqual(
            результат.returncode,
            128 + signal.SIGTERM,
            результат.stderr,
        )
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["статус"], "прервано")
        сам.assertEqual(запись["код_завершения"], -signal.SIGTERM)
        сам.assertIsNone(запись["план"])
        сам.assertEqual(запись["наблюдения"], [])

    def test_путь_полной_проверки_как_аргумент_чужой_команды_не_включает_наблюдения(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a3"
        путь_сценария_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_сценария_полной_проверки.parent.mkdir(parents=True)
        путь_сценария_полной_проверки.write_text("raise SystemExit(0)\n", encoding="utf-8")

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            "-c",
            "raise SystemExit(0)",
            str(путь_сценария_полной_проверки),
            название="чужая команда",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["схема"], "fum.test-run.v3")
        сам.assertEqual(set(запись), поля_профилированной_записи)

    def test_успешная_полная_проверка_с_неуспешным_наблюдением_отклоняется(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-0000000000a4"
        путь_сценария_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_сценария_полной_проверки.parent.mkdir(parents=True)
        путь_сценария_полной_проверки.write_text(
            "import json, os\n"
            "from pathlib import Path\n"
            "ключ = 'Инструменты/fum-alpha/tests'\n"
            "название = 'Тесты fum-alpha'\n"
            "значение = {\n"
            "    'схема': 'fum.smoke-test-observations.v1',\n"
            "    'идентификатор_запуска': os.environ['FUM_CHECK_RUN_ID'],\n"
            "    'текущая_проверка': None,\n"
            "    'план': [{'ключ_проверки': ключ, 'название': название}],\n"
            "    'наблюдения': [{\n"
            "        'ключ_проверки': ключ,\n"
            "        'название': название,\n"
            "        'статус': 'неуспешно',\n"
            "        'длительность_наносекунды': 1,\n"
            "    }],\n"
            "}\n"
            "Path(os.environ['FUM_CHECK_RUN_OBSERVATIONS_PATH']).write_text(\n"
            "    json.dumps(значение, ensure_ascii=False, indent=2, "
            "sort_keys=True) + '\\n', encoding='utf-8'\n"
            ")\n",
            encoding="utf-8",
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            str(путь_сценария_полной_проверки),
            название="противоречивый smoke",
        )

        сам.assertEqual(результат.returncode, 125)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["статус"], "не завершено")
        сам.assertIn("полный успешный тестовый план", запись["пояснение"])

    def test_запись_с_наблюдениями_сама_отклоняет_нарушение_остановки_после_ошибки(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        идентификатор = "00000000-0000-4000-8000-0000000000a8"
        план = [
            {"ключ_проверки": "тест-а", "название": "Тест А"},
            {"ключ_проверки": "тест-б", "название": "Тест Б"},
        ]
        запись = {
            "схема": "fum.test-run.v2",
            "идентификатор": идентификатор,
            "сессия": путь_запроса,
            "порядок": 1,
            "исполнитель": "root",
            "вызов": "smoke-check",
            "состояние": "завершён",
            "длительность_наносекунды": 10,
            "статус": "неуспешно",
            "код_завершения": 7,
            "пояснение": None,
            "план": план,
            "наблюдения": [
                {
                    **план[0],
                    "статус": "неуспешно",
                    "длительность_наносекунды": 1,
                },
                {
                    **план[1],
                    "статус": "успешно",
                    "длительность_наносекунды": 1,
                },
            ],
        }

        with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "fail-fast"):
            модуль.проверить_запись(
                запись,
                f"1_{идентификатор}.json",
                путь_запроса,
            )

    def test_ненулевой_код_сохраняет_отказ_и_возвращает_код(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000002"

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            "-c",
            "import sys; sys.exit(7)",
        )

        сам.assertEqual(результат.returncode, 7)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["статус"], "неуспешно")
        сам.assertEqual(запись["код_завершения"], 7)
        сам.assertIsNone(запись["пояснение"])

    @unittest.skipUnless(hasattr(signal, "SIGTERM"), "Нужен POSIX-сигнал SIGTERM")
    def test_сигнал_завершает_вызов_как_прерванный(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000003"

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            "-c",
            "import os, signal; os.kill(os.getpid(), signal.SIGTERM)",
        )

        сам.assertEqual(результат.returncode, 128 + signal.SIGTERM)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["статус"], "прервано")
        сам.assertEqual(запись["код_завершения"], -signal.SIGTERM)
        сам.assertIn("SIGTERM", запись["пояснение"])

    def test_незапущенная_команда_фиксируется_без_утечки_аргументов(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000004"
        секрет = "секретная-несуществующая-команда"

        результат = сам.фикстура.запустить(идентификатор, секрет)

        сам.assertEqual(результат.returncode, 127)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["статус"], "не завершено")
        сам.assertEqual(запись["код_завершения"], 127)
        сам.assertIsInstance(запись["пояснение"], str)
        сам.assertNotIn(секрет, json.dumps(запись, ensure_ascii=False))

    def test_тайм_аут_сохраняет_незавершённый_исход(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000005"

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            "-c",
            "import time; time.sleep(2)",
            тайм_аут="0.05",
        )

        сам.assertEqual(результат.returncode, 124, результат.stderr)
        запись = сам.фикстура.запись(идентификатор)
        сам.assertEqual(запись["статус"], "не завершено")
        сам.assertEqual(запись["код_завершения"], 124)
        сам.assertIn("тайм-аут", запись["пояснение"])

    def test_сырые_аргументы_и_потоки_не_попадают_в_машинные_данные(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000006"
        секрет_аргумента = "СЕКРЕТ-ARGV-6a01"
        секрет_вывода = "СЕКРЕТ-LOG-6a02"

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            "-c",
            "import sys; print(sys.argv[2]); print(sys.argv[2], file=sys.stderr)",
            секрет_аргумента,
            секрет_вывода,
            название="публикационно чистая метка",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.фикстура.выполнить("предпросмотр")
        сохранённое = "\n".join(
            путь.read_text(encoding="utf-8")
            for путь in (
                *сам.фикстура.файлы_записей(),
                сам.фикстура.отчёт,
            )
        )
        сам.assertNotIn(секрет_аргумента, сохранённое)
        сам.assertNotIn(секрет_вывода, сохранённое)

    def test_предпросмотр_строит_выровненную_таблицу_и_сохраняет_окружение(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000011",
            1_499_999,
            название="проверка | пути \\",
            исполнитель="субагент",
            статус="неуспешно",
            код=1,
            пояснение="ожидаемый TDD-red",
        )
        сам.фикстура.записать_завершённую_запись(
            2,
            "00000000-0000-4000-8000-000000000012",
            1_500_000,
            название="повтор",
        )

        результат = сам.фикстура.выполнить("предпросмотр")

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        отчёт = сам.фикстура.отчёт.read_text(encoding="utf-8")
        сам.assertIn("Содержательное введение, которое нельзя менять", отчёт)
        сам.assertIn("Содержательный хвост, который нельзя менять", отчёт)
        сам.assertIn(r"[субагент] проверка \| пути \\", отчёт)
        сам.assertIn("0,001 с", отчёт)
        сам.assertIn("0,002 с", отчёт)
        сам.assertIn("неуспешно — ожидаемый TDD-red", отчёт)
        сам.assertIn("Общее время прямых запусков проверок: 0,003 с.", отчёт)
        строки_таблицы = [
            строка
            for строка in отчёт.splitlines()
            if строка.startswith("|")
        ]
        позиции = [
            tuple(
                совпадение.start()
                for совпадение in re.finditer(r"(?<!\\)\|", строка)
            )
            for строка in строки_таблицы
        ]
        сам.assertGreaterEqual(len(позиции), 4)
        сам.assertTrue(all(позиция == позиции[0] for позиция in позиции))

    def test_закрытие_создаёт_проверяемый_идемпотентный_снимок(сам) -> None:
        файл = сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000021",
            250_000_000,
        )

        первый = сам.фикстура.выполнить("закрыть")

        сам.assertEqual(первый.returncode, 0, первый.stderr)
        снимок = сам.фикстура.каталог_записей / "снимок.json"
        сам.assertTrue(снимок.is_file())
        данные = json.loads(снимок.read_text(encoding="utf-8"))
        сам.assertEqual(
            данные,
            {
                "схема": "fum.test-run-report.v1",
                "сессия": путь_запроса,
                "файлы": [
                    {
                        "имя": файл.name,
                        "sha256": hashlib.sha256(файл.read_bytes()).hexdigest(),
                    }
                ],
            },
        )
        хэш_снимка = hashlib.sha256(снимок.read_bytes()).hexdigest()
        отчёт = сам.фикстура.отчёт.read_text(encoding="utf-8")
        сам.assertRegex(отчёт, шаблон_закрытого_маркера)
        сам.assertIn(f"sha256=sha256:{хэш_снимка}", отчёт)
        байты_до = (снимок.read_bytes(), сам.фикстура.отчёт.read_bytes())

        проверка = сам.фикстура.выполнить("проверить")
        второй = сам.фикстура.выполнить("закрыть")

        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        сам.assertEqual(второй.returncode, 0, второй.stderr)
        сам.assertEqual(
            (снимок.read_bytes(), сам.фикстура.отчёт.read_bytes()),
            байты_до,
        )

    def test_проверка_закрытого_снимка_отклоняет_подмену_записи(сам) -> None:
        файл = сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000031",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        файл.write_bytes(файл.read_bytes() + b" ")

        проверка = сам.фикстура.выполнить("проверить")

        сам.assertNotEqual(проверка.returncode, 0)

    def test_возобновление_сохраняет_историю_и_продолжает_порядок(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000041",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)

        возобновление = сам.фикстура.выполнить("возобновить")
        запуск = сам.фикстура.запустить(
            "00000000-0000-4000-8000-000000000042",
            sys.executable,
            "-c",
            "pass",
        )

        сам.assertEqual(возобновление.returncode, 0, возобновление.stderr)
        сам.assertEqual(запуск.returncode, 0, запуск.stderr)
        сам.assertFalse((сам.фикстура.каталог_записей / "снимок.json").exists())
        сам.assertIn(
            открытый_маркер,
            сам.фикстура.отчёт.read_text(encoding="utf-8"),
        )
        сам.assertEqual(
            [запись["порядок"] for запись in сам.фикстура.записи()],
            [1, 2],
        )

    def test_профилированный_снимок_версии_два_возобновляется_с_тем_же_вердиктом(сам) -> None:
        первый = сам.фикстура.запустить(
            "00000000-0000-4000-8000-000000000043",
            sys.executable,
            "-c",
            "pass",
        )
        сам.assertEqual(первый.returncode, 0, первый.stderr)
        закрытие = сам.фикстура.выполнить("закрыть")
        сам.assertEqual(закрытие.returncode, 0, закрытие.stderr)
        снимок = сам.фикстура.каталог_записей / "снимок.json"
        сам.assertEqual(
            json.loads(снимок.read_text(encoding="utf-8"))["схема"],
            "fum.test-run-report.v2",
        )

        возобновление = сам.фикстура.выполнить("возобновить")

        сам.assertEqual(возобновление.returncode, 0, возобновление.stderr)
        сам.assertFalse(снимок.exists())
        сам.assertFalse(
            (сам.фикстура.каталог_записей / имя_журнала_возобновления).exists()
        )
        сам.assertIn(
            "Экономный порядок проверок: не готов.",
            сам.фикстура.отчёт.read_text(encoding="utf-8"),
        )
        второй = сам.фикстура.запустить(
            "00000000-0000-4000-8000-000000000044",
            sys.executable,
            "-c",
            "pass",
        )
        сам.assertEqual(второй.returncode, 0, второй.stderr)
        сам.assertEqual(
            [запись["порядок"] for запись in сам.фикстура.записи()],
            [1, 2],
        )

    def test_сбой_открытия_профилированного_снимка_сохраняет_журнал_версии_два(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        первый = сам.фикстура.запустить(
            "00000000-0000-4000-8000-000000000046",
            sys.executable,
            "-c",
            "pass",
        )
        сам.assertEqual(первый.returncode, 0, первый.stderr)
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        путь_журнала = (
            сам.фикстура.каталог_записей / имя_журнала_возобновления
        )
        байты_до = (
            сам.фикстура.отчёт.read_bytes(),
            путь_снимка.read_bytes(),
        )
        снимок = json.loads(байты_до[1])

        with mock.patch.object(
            модуль,
            "заменить_управляемый_блок",
            side_effect=модуль.ОшибкаОтчёта("искусственный сбой"),
        ):
            with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "журнал возобновления"):
                модуль.выполнить_возобновление(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        журнал = json.loads(путь_журнала.read_text(encoding="utf-8"))
        сам.assertEqual(журнал["схема"], "возобновление-отчёта-проверок.2")
        сам.assertEqual(
            set(журнал),
            {
                "схема",
                "сессия",
                "хэш_закрытого_отчёта",
                "хэш_открытого_отчёта",
                "хэш_снимка",
                "отпечаток_закрытия",
            },
        )
        сам.assertEqual(
            журнал["отпечаток_закрытия"],
            снимок["отпечаток_закрытия"],
        )
        сам.assertEqual(
            (сам.фикстура.отчёт.read_bytes(), путь_снимка.read_bytes()),
            байты_до,
        )
        сам.assertNotEqual(сам.фикстура.выполнить("проверить").returncode, 0)
        повтор = сам.фикстура.выполнить("возобновить")
        сам.assertEqual(повтор.returncode, 0, повтор.stderr)
        сам.assertFalse(путь_журнала.exists())
        сам.assertFalse(путь_снимка.exists())

    def test_исторический_снимок_версии_два_не_возобновляется(сам) -> None:
        путь = сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000047",
            1,
        )
        запись = json.loads(путь.read_text(encoding="utf-8"))
        запись.update({"схема": "fum.test-run.v2", "план": [], "наблюдения": []})
        путь.write_text(
            json.dumps(запись, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        байты_до = (сам.фикстура.отчёт.read_bytes(), путь_снимка.read_bytes())

        возобновление = сам.фикстура.выполнить("возобновить")

        сам.assertNotEqual(возобновление.returncode, 0)
        сам.assertIn("v2", возобновление.stderr)
        сам.assertEqual(
            (сам.фикстура.отчёт.read_bytes(), путь_снимка.read_bytes()),
            байты_до,
        )
        сам.assertFalse(
            (сам.фикстура.каталог_записей / имя_журнала_возобновления).exists()
        )

    def test_готовый_профилированный_снимок_нельзя_возобновить(сам) -> None:
        путь_полной_проверки = (
            сам.фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )
        путь_полной_проверки.parent.mkdir(parents=True)
        путь_полной_проверки.write_text(
            "import json, os\n"
            "from pathlib import Path\n"
            "путь = Path(os.environ['FUM_CHECK_RUN_OBSERVATIONS_PATH'])\n"
            "идентификатор = os.environ['FUM_CHECK_RUN_ID']\n"
            "план = [{'\u043a\u043b\u044e\u0447_\u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0438': '\u043d\u0430\u0431\u043e\u0440', '\u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435': '\u041d\u0430\u0431\u043e\u0440'}]\n"
            "значение = {'\u0441\u0445\u0435\u043c\u0430': 'fum.smoke-test-observations.v1', "
            "'\u0438\u0434\u0435\u043d\u0442\u0438\u0444\u0438\u043a\u0430\u0442\u043e\u0440_\u0437\u0430\u043f\u0443\u0441\u043a\u0430': идентификатор, '\u0442\u0435\u043a\u0443\u0449\u0430\u044f_\u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0430': None, "
            "'\u043f\u043b\u0430\u043d': план, '\u043d\u0430\u0431\u043b\u044e\u0434\u0435\u043d\u0438\u044f': [{**план[0], '\u0441\u0442\u0430\u0442\u0443\u0441': '\u0443\u0441\u043f\u0435\u0448\u043d\u043e', '\u0434\u043b\u0438\u0442\u0435\u043b\u044c\u043d\u043e\u0441\u0442\u044c_\u043d\u0430\u043d\u043e\u0441\u0435\u043a\u0443\u043d\u0434\u044b': 1}]}\n"
            "путь.write_text(json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + '\\n', encoding='utf-8')\n",
            encoding="utf-8",
        )
        запуск = сам.фикстура.запустить(
            "00000000-0000-4000-8000-000000000045",
            sys.executable,
            str(путь_полной_проверки),
            название="финальная полная проверка",
        )
        сам.assertEqual(запуск.returncode, 0, запуск.stderr)
        закрытие = сам.фикстура.выполнить("закрыть")
        сам.assertEqual(закрытие.returncode, 0, закрытие.stderr)
        сам.assertIn("Экономный порядок проверок: готов.", сам.фикстура.отчёт.read_text(encoding="utf-8"))

        возобновление = сам.фикстура.выполнить("возобновить")

        сам.assertNotEqual(возобновление.returncode, 0)
        сам.assertIn("готов", возобновление.stderr)
        сам.assertTrue((сам.фикстура.каталог_записей / "снимок.json").is_file())

    def test_параллельные_запуски_получают_уникальный_порядок(сам) -> None:
        процессы = []
        for номер in range(8):
            идентификатор = str(uuid.UUID(int=100 + номер))
            процессы.append(
                subprocess.Popen(
                    сам.фикстура.аргументы(
                        "запустить",
                        "--название",
                        f"параллельная проверка {номер}",
                        "--обычная-схема-профиля",
                        "--исполнитель",
                        "субагент",
                        "--идентификатор-запуска",
                        идентификатор,
                        "--класс-проверки",
                        "адресная",
                        "--",
                        sys.executable,
                        "-c",
                        "import time; time.sleep(0.03)",
                    ),
                    cwd=сам.фикстура.корень,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
            )

        результаты = [процесс.communicate(timeout=10) for процесс in процессы]

        сам.assertEqual([процесс.returncode for процесс in процессы], [0] * 8, результаты)
        сам.assertEqual(
            sorted(запись["порядок"] for запись in сам.фикстура.записи()),
            list(range(1, 9)),
        )
        сам.assertEqual(
            len({запись["идентификатор"] for запись in сам.фикстура.записи()}),
            8,
        )

    def test_проверка_читает_согласованный_срез_под_общим_замком(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000051",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        модуль = загрузить_модуль_автоматизации()
        входы: list[tuple[Path, str]] = []

        @contextlib.contextmanager
        def зафиксировать_замок(корень: Path, сессия: str):
            входы.append((корень, сессия))
            yield

        with mock.patch.object(
            модуль,
            "межпроцессная_блокировка",
            зафиксировать_замок,
        ):
            ошибки = модуль.проверить_журнал_сессии(
                сам.фикстура.корень,
                путь_запроса,
            )

        сам.assertEqual(ошибки, [])
        сам.assertEqual(
            входы,
            [(сам.фикстура.корень.resolve(), путь_запроса)],
        )

    def test_снимок_обязан_иметь_канонические_байты(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000052",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        снимок = сам.фикстура.каталог_записей / "снимок.json"
        прежние_байты = снимок.read_bytes()
        значение = json.loads(прежние_байты)
        неканонические_байты = (
            json.dumps(
                значение,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n"
        ).encode("utf-8")
        сам.assertNotEqual(неканонические_байты, прежние_байты)
        снимок.write_bytes(неканонические_байты)
        прежний_хэш = hashlib.sha256(прежние_байты).hexdigest()
        новый_хэш = hashlib.sha256(неканонические_байты).hexdigest()
        сам.фикстура.отчёт.write_text(
            сам.фикстура.отчёт.read_text(encoding="utf-8").replace(
                f"sha256=sha256:{прежний_хэш}",
                f"sha256=sha256:{новый_хэш}",
            ),
            encoding="utf-8",
        )

        проверка = сам.фикстура.выполнить("проверить")

        сам.assertNotEqual(проверка.returncode, 0)

    def test_закрытая_проверка_отклоняет_замену_переводов_строк(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000053",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        байты = сам.фикстура.отчёт.read_bytes()
        сам.assertNotIn(b"\r\n", байты)
        сам.фикстура.отчёт.write_bytes(байты.replace(b"\n", b"\r\n"))

        проверка = сам.фикстура.выполнить("проверить")

        сам.assertNotEqual(проверка.returncode, 0)

    def test_противоречивые_терминальные_статус_и_код_отклоняются(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        идентификатор = "00000000-0000-4000-8000-000000000054"
        имя = f"1_{идентификатор}.json"
        основа: dict[str, object] = {
            "схема": "fum.test-run.v1",
            "идентификатор": идентификатор,
            "сессия": путь_запроса,
            "порядок": 1,
            "исполнитель": "root",
            "вызов": "проверка",
            "состояние": "завершён",
            "длительность_наносекунды": 1,
            "статус": "успешно",
            "код_завершения": 0,
            "пояснение": None,
        }
        противоречия = (
            ("успешно", 1),
            ("успешно", None),
            ("неуспешно", 0),
            ("неуспешно", -1),
            ("прервано", 143),
            ("прервано", 0),
            ("не завершено", -9),
            ("не завершено", 0),
        )
        for статус, код in противоречия:
            with сам.subTest(статус=статус, код=код):
                запись = dict(основа)
                запись["статус"] = статус
                запись["код_завершения"] = код
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    модуль.проверить_запись(запись, имя, путь_запроса)

        допустимые = (
            ("успешно", 0),
            ("неуспешно", 1),
            ("прервано", -signal.SIGTERM),
            ("не завершено", 124),
        )
        for статус, код in допустимые:
            with сам.subTest(допустимый_статус=статус, допустимый_код=код):
                запись = dict(основа)
                запись["статус"] = статус
                запись["код_завершения"] = код
                сам.assertEqual(
                    модуль.проверить_запись(запись, имя, путь_запроса),
                    запись,
                )

    def test_отказ_записи_снимка_возвращает_открытый_блок_отчёта(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000055",
            10_000_000,
        )
        модуль = загрузить_модуль_автоматизации()
        исходная_запись = модуль.атомарно_записать_байты
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"

        def записать_с_отказом(путь: Path, байты: bytes) -> None:
            if путь.resolve() == путь_снимка.resolve():
                raise модуль.ОшибкаОтчёта("ожидаемый отказ записи снимка")
            исходная_запись(путь, байты)

        with mock.patch.object(
            модуль,
            "атомарно_записать_байты",
            записать_с_отказом,
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_закрытие(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        сам.assertFalse(путь_снимка.exists())
        отчёт = сам.фикстура.отчёт.read_text(encoding="utf-8")
        сам.assertIn(открытый_маркер, отчёт)
        сам.assertIsNone(шаблон_закрытого_маркера.search(отчёт))

    def test_отказ_удаления_снимка_оставляет_журнал_для_повтора(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000056",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        модуль = загрузить_модуль_автоматизации()
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        путь_журнала = (
            сам.фикстура.каталог_записей / имя_журнала_возобновления
        )
        прежний_отчёт = сам.фикстура.отчёт.read_bytes()
        прежний_снимок = путь_снимка.read_bytes()
        исходное_удаление = Path.unlink

        def удалить_с_отказом(путь: Path, *аргументы, **параметры) -> None:
            if путь.resolve() == путь_снимка.resolve():
                raise OSError("ожидаемый отказ удаления снимка")
            исходное_удаление(путь, *аргументы, **параметры)

        with (
            mock.patch.object(Path, "unlink", удалить_с_отказом),
            mock.patch.object(
                модуль,
                "заменить_управляемый_блок",
                wraps=модуль.заменить_управляемый_блок,
            ) as замены,
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_возобновление(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        сам.assertEqual(замены.call_count, 1)
        сам.assertNotEqual(сам.фикстура.отчёт.read_bytes(), прежний_отчёт)
        сам.assertIn(
            открытый_маркер,
            сам.фикстура.отчёт.read_text(encoding="utf-8"),
        )
        сам.assertEqual(путь_снимка.read_bytes(), прежний_снимок)
        сам.assertTrue(путь_журнала.is_file())
        сам.assertNotEqual(
            модуль.проверить_журнал_сессии(
                сам.фикстура.корень,
                путь_запроса,
            ),
            [],
        )
        сам.assertEqual(
            модуль.выполнить_возобновление(
                сам.фикстура.корень,
                Path(путь_запроса),
            ),
            0,
        )
        сам.assertFalse(путь_журнала.exists())
        сам.assertFalse(путь_снимка.exists())

    @unittest.skipUnless(
        hasattr(os, "symlink"),
        "Нужна поддержка символических ссылок",
    )
    def test_лексический_алиас_через_символическую_ссылку_отклоняется(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        имя_алиаса = "2026-08-04_20-45-27_MSK_алиас"
        путь_алиаса = сам.фикстура.корень / "Журнал" / имя_алиаса
        путь_алиаса.symlink_to(сам.фикстура.каталог_сессии, target_is_directory=True)

        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.разрешить_сессию(
                сам.фикстура.корень,
                Path("Журнал") / имя_алиаса / "запрос.md",
            )

    def test_тайм_аут_убивает_игнорирующего_завершение_потомка_группы(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000057"
        путь_идентификатора_потомка = сам.фикстура.корень / "pid-потомка.txt"
        путь_пульса = сам.фикстура.корень / "пульс-потомка.txt"
        код_потомка = (
            "import os,pathlib,signal,sys,time\n"
            "signal.signal(signal.SIGTERM, signal.SIG_IGN)\n"
            "pathlib.Path(sys.argv[1]).write_text(str(os.getpid()), encoding='utf-8')\n"
            "while True:\n"
            "    pathlib.Path(sys.argv[2]).write_text(str(time.monotonic_ns()), encoding='utf-8')\n"
            "    time.sleep(0.02)\n"
        )
        код_лидера = (
            "import pathlib,subprocess,sys,time\n"
            "subprocess.Popen([sys.executable, '-c', sys.argv[1], sys.argv[2], sys.argv[3]], "
            "stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
            "while not pathlib.Path(sys.argv[2]).exists():\n"
            "    time.sleep(0.01)\n"
            "time.sleep(30)\n"
        )

        результат = сам.фикстура.запустить(
            идентификатор,
            sys.executable,
            "-c",
            код_лидера,
            код_потомка,
            str(путь_идентификатора_потомка),
            str(путь_пульса),
            тайм_аут="1",
        )
        дождаться_файла(путь_идентификатора_потомка)
        дождаться_файла(путь_пульса)
        идентификатор_процесса = int(
            путь_идентификатора_потомка.read_text(encoding="utf-8")
        )
        try:
            первый_пульс = путь_пульса.stat().st_mtime_ns
            time.sleep(0.15)
            второй_пульс = путь_пульса.stat().st_mtime_ns
            сам.assertEqual(результат.returncode, 124, результат.stderr)
            сам.assertEqual(первый_пульс, второй_пульс)
        finally:
            try:
                os.kill(идентификатор_процесса, signal.SIGKILL)
            except ProcessLookupError:
                pass

    @unittest.skipUnless(hasattr(signal, "SIGINT"), "Нужен POSIX-сигнал SIGINT")
    def test_сигнал_во_время_очистки_оставляет_терминальную_запись(сам) -> None:
        идентификатор = "00000000-0000-4000-8000-000000000058"
        путь_идентификатора_цели = сам.фикстура.корень / "pid-цели.txt"
        путь_готовности = сам.фикстура.корень / "цель-готова.txt"
        путь_получения_сигнала = сам.фикстура.корень / "цель-получила-SIGTERM.txt"
        код_цели = (
            "import os,pathlib,signal,sys,time\n"
            "def отметить_сигнал(*_):\n"
            "    pathlib.Path(sys.argv[1]).write_text('SIGTERM', encoding='utf-8')\n"
            "signal.signal(signal.SIGTERM, отметить_сигнал)\n"
            "pathlib.Path(sys.argv[2]).write_text(str(os.getpid()), encoding='utf-8')\n"
            "pathlib.Path(sys.argv[3]).write_text('готово', encoding='utf-8')\n"
            "while True:\n"
            "    time.sleep(0.02)\n"
        )
        процесс = subprocess.Popen(
            сам.фикстура.аргументы(
                "запустить",
                "--название",
                "сигнал во время очистки",
                "--обычная-схема-профиля",
                "--исполнитель",
                "субагент",
                "--идентификатор-запуска",
                идентификатор,
                "--тайм-аут-секунды",
                "0.3",
                "--класс-проверки",
                "адресная",
                "--",
                sys.executable,
                "-c",
                код_цели,
                str(путь_получения_сигнала),
                str(путь_идентификатора_цели),
                str(путь_готовности),
            ),
            cwd=сам.фикстура.корень,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        идентификатор_процесса: int | None = None
        try:
            дождаться_файла(путь_готовности)
            идентификатор_процесса = int(
                путь_идентификатора_цели.read_text(encoding="utf-8")
            )
            дождаться_файла(путь_получения_сигнала)
            os.kill(процесс.pid, signal.SIGINT)
            код = процесс.wait(timeout=5)
            запись = сам.фикстура.запись(идентификатор)
            сам.assertEqual(код, 128 + signal.SIGINT)
            сам.assertEqual(запись["состояние"], "завершён")
            сам.assertEqual(запись["статус"], "прервано")
            сам.assertEqual(запись["код_завершения"], -signal.SIGINT)
        finally:
            if процесс.poll() is None:
                процесс.kill()
                процесс.wait(timeout=5)
            if идентификатор_процесса is not None:
                try:
                    os.kill(идентификатор_процесса, signal.SIGKILL)
                except ProcessLookupError:
                    pass

    def test_очистка_останавливает_сохранённую_группу_после_лидера(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        путь_идентификатора = сам.фикстура.корень / "идентификатор-потомка.txt"
        путь_пульса = сам.фикстура.корень / "пульс-осиротевшего-потомка.txt"
        код_потомка = (
            "import os,pathlib,signal,sys,time\n"
            "signal.signal(signal.SIGTERM, signal.SIG_IGN)\n"
            "pathlib.Path(sys.argv[1]).write_text(str(os.getpid()), encoding='utf-8')\n"
            "while True:\n"
            "    pathlib.Path(sys.argv[2]).write_text(str(time.monotonic_ns()), encoding='utf-8')\n"
            "    time.sleep(0.02)\n"
        )
        код_лидера = (
            "import pathlib,subprocess,sys,time\n"
            "subprocess.Popen([sys.executable, '-c', sys.argv[1], sys.argv[2], sys.argv[3]], "
            "stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
            "while not pathlib.Path(sys.argv[2]).exists():\n"
            "    time.sleep(0.01)\n"
        )
        процесс = subprocess.Popen(
            [
                sys.executable,
                "-c",
                код_лидера,
                код_потомка,
                str(путь_идентификатора),
                str(путь_пульса),
            ],
            cwd=сам.фикстура.корень,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        идентификатор_группы = процесс.pid
        идентификатор_потомка: int | None = None
        try:
            дождаться_файла(путь_идентификатора)
            дождаться_файла(путь_пульса)
            идентификатор_потомка = int(
                путь_идентификатора.read_text(encoding="utf-8")
            )
            сам.assertEqual(процесс.wait(timeout=5), 0)
            начало = time.monotonic()

            модуль.остановить_группу(процесс, идентификатор_группы)

            сам.assertLess(time.monotonic() - начало, 2.0)
            первый_пульс = путь_пульса.stat().st_mtime_ns
            time.sleep(0.15)
            сам.assertEqual(путь_пульса.stat().st_mtime_ns, первый_пульс)
            with сам.assertRaises(ProcessLookupError):
                os.killpg(идентификатор_группы, 0)
        finally:
            try:
                os.killpg(идентификатор_группы, signal.SIGKILL)
            except (ProcessLookupError, PermissionError):
                pass
            if идентификатор_потомка is not None:
                try:
                    os.kill(идентификатор_потомка, signal.SIGKILL)
                except ProcessLookupError:
                    pass

    def test_сбой_записи_отчёта_оставляет_подготовленный_снимок_для_закрытия(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000061",
            10_000_000,
        )
        модуль = загрузить_модуль_автоматизации()
        прежний_отчёт = сам.фикстура.отчёт.read_bytes()
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"

        with mock.patch.object(
            модуль,
            "заменить_управляемый_блок",
            side_effect=модуль.ОшибкаОтчёта("ожидаемый отказ Markdown"),
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_закрытие(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        сам.assertTrue(путь_снимка.is_file())
        сам.assertEqual(сам.фикстура.отчёт.read_bytes(), прежний_отчёт)
        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.выполнить_запуск(
                сам.фикстура.корень,
                Path(путь_запроса),
                "запрещённый запуск",
                "root",
                "00000000-0000-4000-8000-000000000062",
                None,
                [sys.executable, "-c", "pass"],
                класс_проверки="адресная",
            )

        сам.assertEqual(
            модуль.выполнить_закрытие(
                сам.фикстура.корень,
                Path(путь_запроса),
            ),
            0,
        )
        сам.assertEqual(
            модуль.проверить_журнал_сессии(
                сам.фикстура.корень,
                путь_запроса,
            ),
            [],
        )

    def test_сбой_открытия_возобновления_сохраняет_закрытые_байты(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000063",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        модуль = загрузить_модуль_автоматизации()
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        путь_журнала = (
            сам.фикстура.каталог_записей / имя_журнала_возобновления
        )
        прежний_отчёт = сам.фикстура.отчёт.read_bytes()
        прежний_снимок = путь_снимка.read_bytes()

        with mock.patch.object(
            модуль,
            "заменить_управляемый_блок",
            side_effect=модуль.ОшибкаОтчёта("ожидаемый отказ открытия"),
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_возобновление(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        сам.assertEqual(сам.фикстура.отчёт.read_bytes(), прежний_отчёт)
        сам.assertEqual(путь_снимка.read_bytes(), прежний_снимок)
        сам.assertTrue(путь_журнала.is_file())
        сам.assertNotEqual(
            модуль.проверить_журнал_сессии(
                сам.фикстура.корень,
                путь_запроса,
            ),
            [],
        )
        сам.assertEqual(
            модуль.выполнить_возобновление(
                сам.фикстура.корень,
                Path(путь_запроса),
            ),
            0,
        )
        сам.assertFalse(путь_журнала.exists())
        сам.assertFalse(путь_снимка.exists())

    def test_отказ_удаления_возобновляется_по_журналу(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000064",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        модуль = загрузить_модуль_автоматизации()
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        путь_журнала = (
            сам.фикстура.каталог_записей / имя_журнала_возобновления
        )
        исходное_удаление = Path.unlink
        исходная_запись = модуль.атомарно_записать_байты
        записи_отчёта = 0

        def удалить_с_отказом(путь: Path, *аргументы, **параметры) -> None:
            if путь.resolve() == путь_снимка.resolve():
                raise OSError("ожидаемый отказ удаления")
            исходное_удаление(путь, *аргументы, **параметры)

        def записать_с_отказом_отката(путь: Path, байты: bytes) -> None:
            nonlocal записи_отчёта
            if путь.name == "отчёт.md":
                записи_отчёта += 1
                if записи_отчёта == 2:
                    raise модуль.ОшибкаОтчёта("ожидаемый отказ отката")
            исходная_запись(путь, байты)

        with (
            mock.patch.object(Path, "unlink", удалить_с_отказом),
            mock.patch.object(
                модуль,
                "атомарно_записать_байты",
                записать_с_отказом_отката,
            ),
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_возобновление(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        сам.assertTrue(путь_снимка.is_file())
        сам.assertTrue(путь_журнала.is_file())
        сам.assertIn(
            открытый_маркер,
            сам.фикстура.отчёт.read_text(encoding="utf-8"),
        )
        сам.assertEqual(
            модуль.выполнить_возобновление(
                сам.фикстура.корень,
                Path(путь_запроса),
            ),
            0,
        )
        сам.assertFalse(путь_журнала.exists())
        сам.assertFalse(путь_снимка.exists())

    @unittest.skipUnless(
        hasattr(signal, "pthread_sigmask"),
        "Нужна потоковая маска сигналов",
    )
    def test_сигналы_заблокированы_при_создании_и_финализации_записи(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        исходная_запись = модуль.атомарно_записать_байты
        наблюдённые_маски: dict[str, set[signal.Signals]] = {}

        def записать_с_маской(путь: Path, байты: bytes) -> None:
            if путь.name.endswith(".json") and путь.name != "снимок.json":
                состояние = str(json.loads(байты)["состояние"])
                наблюдённые_маски[состояние] = set(
                    signal.pthread_sigmask(signal.SIG_BLOCK, set())
                )
            исходная_запись(путь, байты)

        with mock.patch.object(
            модуль,
            "атомарно_записать_байты",
            записать_с_маской,
        ):
            код = модуль.выполнить_запуск(
                сам.фикстура.корень,
                Path(путь_запроса),
                "проверка маски",
                "root",
                "00000000-0000-4000-8000-000000000065",
                None,
                [sys.executable, "-c", "pass"],
                класс_проверки="адресная",
            )

        сам.assertEqual(код, 0)
        for состояние in ("выполняется", "завершён"):
            with сам.subTest(состояние=состояние):
                сам.assertTrue(
                    {signal.SIGINT, signal.SIGTERM}
                    <= наблюдённые_маски[состояние]
                )

    @unittest.skipUnless(hasattr(signal, "SIGTERM"), "Нужен сигнал завершения")
    def test_отложенный_сигнал_определяет_терминальную_запись(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        вызовы_часов = 0

        def монотонные_часы() -> int:
            nonlocal вызовы_часов
            вызовы_часов += 1
            if вызовы_часов == 2:
                os.kill(os.getpid(), signal.SIGTERM)
            return вызовы_часов * 100

        with mock.patch.object(
            модуль.time,
            "monotonic_ns",
            монотонные_часы,
        ):
            код = модуль.выполнить_запуск(
                сам.фикстура.корень,
                Path(путь_запроса),
                "отложенный сигнал",
                "root",
                "00000000-0000-4000-8000-000000000066",
                None,
                [sys.executable, "-c", "pass"],
                класс_проверки="адресная",
            )

        запись = сам.фикстура.запись(
            "00000000-0000-4000-8000-000000000066"
        )
        сам.assertEqual(код, 128 + signal.SIGTERM)
        сам.assertEqual(запись["состояние"], "завершён")
        сам.assertEqual(запись["статус"], "прервано")
        сам.assertEqual(запись["код_завершения"], -signal.SIGTERM)

    def test_метки_отклоняют_управляющие_и_разделяющие_символы_Юникода(сам) -> None:
        модуль = загрузить_модуль_автоматизации()

        for знак in ("\u0085", "\u2028", "\u2029"):
            with сам.subTest(кодовая_точка=f"U+{ord(знак):04X}"):
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    модуль.проверить_строку(f"до{знак}после", "метка")

    def test_возобновление_сначала_устанавливает_канонический_журнал(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000067",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        модуль = загрузить_модуль_автоматизации()
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        путь_журнала = (
            сам.фикстура.каталог_записей / имя_журнала_возобновления
        )
        прежний_отчёт = сам.фикстура.отчёт.read_bytes()
        прежний_снимок = путь_снимка.read_bytes()
        записи = модуль.прочитать_записи(
            сам.фикстура.каталог_записей,
            путь_запроса,
        )
        текст_отчёта = прежний_отчёт.decode("utf-8")
        начало, конец, _ = модуль.границы_управляемого_блока(текст_отчёта)
        открытый_отчёт = (
            текст_отчёта[:начало]
            + модуль.сформировать_блок(записи, модуль.ОТКРЫТЫЙ_МАРКЕР)
            + текст_отчёта[конец:]
        ).encode("utf-8")

        with mock.patch.object(
            модуль,
            "заменить_управляемый_блок",
            side_effect=модуль.ОшибкаОтчёта("ожидаемый отказ открытия"),
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_возобновление(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        сам.assertTrue(путь_журнала.is_file())
        значение_журнала = json.loads(путь_журнала.read_bytes())
        ожидаемый_журнал = {
            "схема": схема_журнала_возобновления,
            "сессия": путь_запроса,
            "хэш_закрытого_отчёта": hashlib.sha256(
                прежний_отчёт
            ).hexdigest(),
            "хэш_открытого_отчёта": hashlib.sha256(
                открытый_отчёт
            ).hexdigest(),
            "хэш_снимка": hashlib.sha256(прежний_снимок).hexdigest(),
        }
        сам.assertEqual(значение_журнала, ожидаемый_журнал)
        сам.assertEqual(
            путь_журнала.read_bytes(),
            модуль.канонические_машинные_байты(ожидаемый_журнал),
        )
        сам.assertNotIn(
            имя_журнала_возобновления,
            {
                описание["имя"]
                for описание in json.loads(прежний_снимок)["файлы"]
            },
        )

        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.выполнить_закрытие(
                сам.фикстура.корень,
                Path(путь_запроса),
            )
        сам.assertNotEqual(
            модуль.проверить_журнал_сессии(
                сам.фикстура.корень,
                путь_запроса,
            ),
            [],
        )

    def test_повтор_возобновления_завершает_фазу_без_снимка(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000068",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        модуль = загрузить_модуль_автоматизации()
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        путь_журнала = (
            сам.фикстура.каталог_записей / имя_журнала_возобновления
        )
        исходная_синхронизация = модуль.синхронизировать_каталог
        исходная_запись = модуль.атомарно_записать_байты

        def синхронизировать_с_отказом(каталог: Path) -> None:
            if (
                каталог.resolve() == сам.фикстура.каталог_записей.resolve()
                and not путь_снимка.exists()
            ):
                raise OSError("ожидаемый отказ синхронизации каталога")
            исходная_синхронизация(каталог)

        def отказать_в_записи_отката(путь: Path, байты: bytes) -> None:
            if (
                not путь_снимка.exists()
                and путь.resolve()
                in {путь_снимка.resolve(), сам.фикстура.отчёт.resolve()}
            ):
                raise модуль.ОшибкаОтчёта("ожидаемый отказ записи отката")
            исходная_запись(путь, байты)

        with (
            mock.patch.object(
                модуль,
                "синхронизировать_каталог",
                синхронизировать_с_отказом,
            ),
            mock.patch.object(
                модуль,
                "атомарно_записать_байты",
                отказать_в_записи_отката,
            ),
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_возобновление(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        сам.assertFalse(путь_снимка.exists())
        сам.assertTrue(путь_журнала.is_file())
        сам.assertIn(
            открытый_маркер,
            сам.фикстура.отчёт.read_text(encoding="utf-8"),
        )
        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.выполнить_запуск(
                сам.фикстура.корень,
                Path(путь_запроса),
                "запрещённый запуск при восстановлении",
                "root",
                "00000000-0000-4000-8000-000000000069",
                None,
                [sys.executable, "-c", "pass"],
                класс_проверки="адресная",
            )
        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.выполнить_предпросмотр(
                сам.фикстура.корень,
                Path(путь_запроса),
            )
        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.выполнить_закрытие(
                сам.фикстура.корень,
                Path(путь_запроса),
            )
        сам.assertNotEqual(
            модуль.проверить_журнал_сессии(
                сам.фикстура.корень,
                путь_запроса,
            ),
            [],
        )

        сам.assertEqual(
            модуль.выполнить_возобновление(
                сам.фикстура.корень,
                Path(путь_запроса),
            ),
            0,
        )
        сам.assertFalse(путь_журнала.exists())
        сам.assertFalse(путь_снимка.exists())
        сам.assertIn(
            открытый_маркер,
            сам.фикстура.отчёт.read_text(encoding="utf-8"),
        )

    def test_журнал_возобновления_строго_проверяется(сам) -> None:
        сам.фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000070",
            10_000_000,
        )
        сам.assertEqual(сам.фикстура.выполнить("закрыть").returncode, 0)
        модуль = загрузить_модуль_автоматизации()
        путь_снимка = сам.фикстура.каталог_записей / "снимок.json"
        путь_журнала = (
            сам.фикстура.каталог_записей / имя_журнала_возобновления
        )

        with mock.patch.object(
            модуль,
            "заменить_управляемый_блок",
            side_effect=модуль.ОшибкаОтчёта("ожидаемый отказ открытия"),
        ):
            with сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.выполнить_возобновление(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                )

        правильные_байты = путь_журнала.read_bytes()
        правильное_значение = json.loads(правильные_байты)
        прежний_отчёт = сам.фикстура.отчёт.read_bytes()
        прежний_снимок = путь_снимка.read_bytes()
        варианты: list[tuple[str, bytes]] = []
        for поле in (
            "хэш_закрытого_отчёта",
            "хэш_открытого_отчёта",
            "хэш_снимка",
        ):
            значение = dict(правильное_значение)
            значение[поле] = "0" * 64
            варианты.append(
                (поле, модуль.канонические_машинные_байты(значение))
            )
        неверная_схема = dict(правильное_значение)
        неверная_схема["схема"] = "неизвестная-схема.1"
        варианты.append(
            (
                "схема",
                модуль.канонические_машинные_байты(неверная_схема),
            )
        )
        неверная_сессия = dict(правильное_значение)
        неверная_сессия["сессия"] = "Журнал/чужая-сессия/запрос.md"
        варианты.append(
            (
                "сессия",
                модуль.канонические_машинные_байты(неверная_сессия),
            )
        )
        лишнее_поле = dict(правильное_значение)
        лишнее_поле["лишнее"] = True
        варианты.append(
            (
                "набор полей",
                модуль.канонические_машинные_байты(лишнее_поле),
            )
        )
        варианты.append(
            (
                "неканонические байты",
                (
                    json.dumps(
                        правильное_значение,
                        ensure_ascii=False,
                        sort_keys=True,
                        separators=(",", ":"),
                    )
                    + "\n"
                ).encode("utf-8"),
            )
        )

        for название, байты in варианты:
            with сам.subTest(вариант=название):
                путь_журнала.write_bytes(байты)
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    модуль.выполнить_возобновление(
                        сам.фикстура.корень,
                        Path(путь_запроса),
                    )
                сам.assertEqual(сам.фикстура.отчёт.read_bytes(), прежний_отчёт)
                сам.assertEqual(путь_снимка.read_bytes(), прежний_снимок)

    @unittest.skipUnless(
        all(
            hasattr(signal, имя)
            for имя in ("pthread_sigmask", "sigpending", "sigwait")
        ),
        "Нужны потоковая маска и ожидание сигналов",
    )
    def test_сигнал_после_терминальной_записи_передаётся_прежнему_обработчику(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        исходное_ожидание = signal.sigpending
        прежний_обработчик = signal.getsignal(signal.SIGTERM)
        полученные_прежним: list[int] = []
        вызовы_ожидания = 0
        вызовы_часов = 0

        def обработать_после_записи(номер: int, _кадр: object) -> None:
            полученные_прежним.append(номер)

        def монотонные_часы() -> int:
            nonlocal вызовы_часов
            вызовы_часов += 1
            if вызовы_часов == 2:
                os.kill(os.getpid(), signal.SIGINT)
            return вызовы_часов * 100

        def ожидающие_с_новым_сигналом() -> set[signal.Signals]:
            nonlocal вызовы_ожидания
            вызовы_ожидания += 1
            if вызовы_ожидания == 2:
                os.kill(os.getpid(), signal.SIGTERM)
            return set(исходное_ожидание())

        signal.signal(signal.SIGTERM, обработать_после_записи)
        try:
            with (
                mock.patch.object(
                    модуль.time,
                    "monotonic_ns",
                    монотонные_часы,
                ),
                mock.patch.object(
                    модуль.signal,
                    "sigpending",
                    ожидающие_с_новым_сигналом,
                ),
            ):
                код = модуль.выполнить_запуск(
                    сам.фикстура.корень,
                    Path(путь_запроса),
                    "граница терминального сигнала",
                    "root",
                    "00000000-0000-4000-8000-000000000071",
                    None,
                    [sys.executable, "-c", "pass"],
                    класс_проверки="адресная",
                )
        finally:
            signal.signal(signal.SIGTERM, прежний_обработчик)

        запись = сам.фикстура.запись(
            "00000000-0000-4000-8000-000000000071"
        )
        сам.assertEqual(код, 128 + signal.SIGINT)
        сам.assertEqual(запись["статус"], "прервано")
        сам.assertEqual(запись["код_завершения"], -signal.SIGINT)
        сам.assertEqual(полученные_прежним, [signal.SIGTERM])


class ТестыЭкономногоПорядкаПроверок(unittest.TestCase):
    снимок = "sha256:" + "a" * 64
    ключ = "Инструменты/fum-primer/tests"

    def запись(
        сам,
        порядок: int,
        класс_проверки: str,
        *,
        ключи: list[str] | None = None,
        основание: str | None = None,
        идентификатор_отказа: str | None = None,
        ожидаемое_свидетельство: str | None = None,
        длительность: int = 2_000_000_000,
        статус: str = "успешно",
        название: str | None = None,
        снимок: str | None = None,
    ) -> tuple[Path, dict[str, object], bytes]:
        идентификатор = f"00000000-0000-4000-8000-{порядок:012d}"
        план = None
        наблюдения: list[dict[str, object]] = []
        if класс_проверки == "полная":
            план = [
                {"ключ_проверки": ключ, "название": "Полный набор"}
                for ключ in (ключи or [])
            ]
            наблюдения = [
                {
                    **элемент,
                    "статус": "успешно",
                    "длительность_наносекунды": 1,
                }
                for элемент in план
            ]
        значение: dict[str, object] = {
            "схема": "fum.test-run.v3",
            "идентификатор": идентификатор,
            "сессия": путь_запроса,
            "порядок": порядок,
            "исполнитель": "корневой агент",
            "вызов": название or класс_проверки,
            "состояние": "завершён",
            "длительность_наносекунды": длительность,
            "статус": статус,
            "код_завершения": 0 if статус == "успешно" else 1,
            "пояснение": None,
            "план": план,
            "наблюдения": наблюдения,
            "профиль_проверки": {
                "класс": класс_проверки,
                "отпечаток_снимка": снимок or сам.снимок,
                "полные_наборы": ключи or [],
                "основание": основание,
                "идентификатор_отказа": идентификатор_отказа,
                "ожидаемое_свидетельство": ожидаемое_свидетельство,
            },
        }
        return Path(f"{ порядок}_{идентификатор}.json"), значение, b"{}\n"

    def новая_фикстура(сам) -> ФикстураОтчётов:
        фикстура = ФикстураОтчётов()
        сам.addCleanup(фикстура.очистить)
        return фикстура

    def подготовить_репозиторный_снимок(
        сам,
        фикстура: ФикстураОтчётов,
    ) -> Path:
        содержательный_файл = фикстура.корень / "содержание.md"
        содержательный_файл.write_text("Исходный снимок.\n", encoding="utf-8")
        команды = (
            ("init", "-q"),
            ("config", "user.name", "FUM Tests"),
            ("config", "user.email", "fum-tests@example.invalid"),
            ("add", "."),
            ("commit", "-q", "-m", "Исходный снимок"),
        )
        for команда in команды:
            subprocess.run(
                ["git", *команда],
                cwd=фикстура.корень,
                check=True,
                capture_output=True,
            )
        return содержательный_файл

    def test_профилированная_версия_три_строго_проверяет_три_класса_и_закрытые_поля(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        случаи = [
            сам.запись(1, "адресная"),
            сам.запись(
                2,
                "диагностическая",
                ключи=[сам.ключ],
                основание="локализация_наблюдаемого_отказа",
                идентификатор_отказа="00000000-0000-4000-8000-000000000099",
                ожидаемое_свидетельство="Отделить отказ набора от валидатора.",
            ),
            сам.запись(3, "полная", ключи=[сам.ключ]),
        ]
        for путь, значение, _ in случаи:
            with сам.subTest(класс=значение["профиль_проверки"]["класс"]):
                проверенная = модуль.проверить_запись(
                    значение,
                    путь.name,
                    путь_запроса,
                )
                сам.assertEqual(
                    set(проверенная),
                    поля_профилированной_записи,
                )
                сам.assertEqual(
                    set(проверенная["профиль_проверки"]),
                    поля_профиля_проверки,
                )

        основа = copy.deepcopy(случаи[1][1])
        мутации = {
            "неизвестный класс": lambda запись: запись[
                "профиль_проверки"
            ].update({"класс": "широкая"}),
            "класс не строка": lambda запись: запись[
                "профиль_проверки"
            ].update({"класс": []}),
            "неверный отпечаток": lambda запись: запись[
                "профиль_проверки"
            ].update({"отпечаток_снимка": "sha256:1234"}),
            "повтор набора": lambda запись: запись[
                "профиль_проверки"
            ].update({"полные_наборы": [сам.ключ, сам.ключ]}),
            "лишнее поле профиля": lambda запись: запись[
                "профиль_проверки"
            ].update({"лишнее": None}),
            "лишнее поле записи": lambda запись: запись.update(
                {"лишнее": None}
            ),
            "неполная диагностика": lambda запись: запись[
                "профиль_проверки"
            ].update({"ожидаемое_свидетельство": None}),
        }
        for название, мутация in мутации.items():
            искажённая = copy.deepcopy(основа)
            мутация(искажённая)
            with сам.subTest(мутация=название):
                with сам.assertRaises(модуль.ОшибкаОтчёта):
                    модуль.проверить_запись(
                        искажённая,
                        случаи[1][0].name,
                        путь_запроса,
                    )

    def test_успешный_план_разделяет_нормативный_контур_и_доказанные_условия(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        записи = [
            сам.запись(
                1,
                "адресная",
                статус="неуспешно",
                название="адресная красная проверка",
            ),
            сам.запись(2, "адресная", название="адресная зелёная проверка"),
            сам.запись(3, "адресная", название="изменённые плановые контракты"),
            сам.запись(4, "адресная", название="свежесть документов"),
            сам.запись(5, "адресная", название="связность сессии"),
            сам.запись(6, "полная", ключи=[сам.ключ]),
        ]

        план = модуль.построить_план_успешной_сессии(записи, сам.снимок)

        сам.assertEqual(план["состояние"], "готов")
        сам.assertEqual(план["полные_прогоны"], 1)
        сам.assertEqual(план["дублирования"], [])
        сам.assertEqual(
            план["нормативный_контур"],
            [
                "адресные_красные_и_зелёные_проверки",
                "изменённые_плановые_контракты",
                "свежесть",
                "связность_сессии",
                "финальная_комплексная_проверка",
                "закрытие_отчёта",
                "локальный_коммит_этапа_на_master",
            ],
        )
        сам.assertNotIn("этапы", план)
        сам.assertEqual(
            план["доказанные_условия"],
            {
                "нет_активных": True,
                "финальная_полная_последняя": True,
                "финальная_полная_успешна": True,
                "ровно_один_успешный_полный_прогон": True,
                "нет_запрещённых_перекрытий": True,
                "локализации_связаны_с_предшествующим_отказом": True,
                "непокрытые_диагностики_успешны": True,
                "совместимая_история": True,
                "снимок_совпадает": True,
            },
        )
        сам.assertEqual(план["состояние"] == "готов", all(план["доказанные_условия"].values()))

    def test_неразрешённое_дублирование_на_неизменённом_снимке_отклоняется(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        записи = [
            сам.запись(1, "полная", ключи=[сам.ключ]),
            сам.запись(2, "полная", ключи=[сам.ключ]),
        ]

        план = модуль.построить_план_успешной_сессии(записи)

        сам.assertEqual(план["полные_прогоны"], 2)
        сам.assertEqual(len(план["дублирования"]), 1)
        сам.assertFalse(план["дублирования"][0]["разрешено"])
        сам.assertEqual(план["дублирования"][0]["наборы"], [сам.ключ])

        with сам.assertRaisesRegex(
            модуль.ОшибкаОтчёта,
            "повторена на неизменённом снимке",
        ):
            модуль.проверить_порядок_проверок(записи)

    def test_диагностика_требует_точный_идентификатор_предшествующего_неуспеха(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        успех = сам.запись(1, "адресная")
        отказ = сам.запись(2, "адресная", статус="неуспешно")
        последующий_отказ = сам.запись(4, "адресная", статус="неуспешно")
        финал = сам.запись(5, "полная", ключи=[сам.ключ])
        ссылки = (
            str(успех[1]["идентификатор"]),
            "00000000-0000-4000-8000-000000000088",
            str(последующий_отказ[1]["идентификатор"]),
        )
        for ссылка in ссылки:
            диагностика = сам.запись(
                3,
                "диагностическая",
                ключи=[сам.ключ],
                основание="локализация_наблюдаемого_отказа",
                идентификатор_отказа=ссылка,
                ожидаемое_свидетельство="Уточнить границу отказа.",
            )
            with сам.subTest(ссылка=ссылка):
                with сам.assertRaisesRegex(
                    модуль.ОшибкаОтчёта,
                    "предшествующего неуспешного запуска",
                ):
                    модуль.проверить_порядок_проверок(
                        [успех, отказ, диагностика, последующий_отказ, финал]
                    )

    def test_локализация_непокрытого_набора_тоже_требует_предшествующий_отказ(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        непокрытый_ключ = "Прототипы/ВнеПолнойПроверки"
        записи = [
            сам.запись(1, "адресная", статус="неуспешно"),
            сам.запись(
                2,
                "диагностическая",
                ключи=[непокрытый_ключ],
                основание="локализация_наблюдаемого_отказа",
                идентификатор_отказа="00000000-0000-4000-8000-000000000099",
                ожидаемое_свидетельство="Локализовать отказ вне финального плана.",
            ),
            сам.запись(3, "полная", ключи=[сам.ключ]),
        ]

        план = модуль.построить_план_успешной_сессии(записи, сам.снимок)

        сам.assertEqual(план["состояние"], "не готов")
        сам.assertFalse(
            план["доказанные_условия"][
                "локализации_связаны_с_предшествующим_отказом"
            ]
        )
        with сам.assertRaisesRegex(
            модуль.ОшибкаОтчёта,
            "предшествующего неуспешного запуска",
        ):
            модуль.проверить_порядок_проверок(записи, сам.снимок)

    def test_локализация_не_принимает_прерывание_или_незавершённый_запуск_за_отказ(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        for статус, код in (("прервано", -2), ("не завершено", 125)):
            ссылка = сам.запись(1, "адресная", статус=статус)
            ссылка[1]["код_завершения"] = код
            диагностика = сам.запись(
                2,
                "диагностическая",
                ключи=[сам.ключ],
                основание="локализация_наблюдаемого_отказа",
                идентификатор_отказа=str(ссылка[1]["идентификатор"]),
                ожидаемое_свидетельство="Локализовать точный неуспешный исход.",
            )
            записи = [
                ссылка,
                диагностика,
                сам.запись(3, "полная", ключи=[сам.ключ]),
            ]

            with сам.subTest(статус=статус):
                план = модуль.построить_план_успешной_сессии(
                    записи,
                    сам.снимок,
                )
                сам.assertEqual(план["состояние"], "не готов")
                сам.assertFalse(
                    план["доказанные_условия"][
                        "локализации_связаны_с_предшествующим_отказом"
                    ]
                )
                with сам.assertRaisesRegex(
                    модуль.ОшибкаОтчёта,
                    "предшествующего неуспешного запуска",
                ):
                    модуль.проверить_порядок_проверок(
                        записи,
                        сам.снимок,
                    )

    def test_диагностический_повтор_показывает_дублирование_и_длительность(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        отказ = сам.запись(1, "адресная", статус="неуспешно")
        идентификатор_отказа = str(отказ[1]["идентификатор"])
        записи = [
            отказ,
            сам.запись(
                2,
                "диагностическая",
                ключи=[сам.ключ],
                основание="локализация_наблюдаемого_отказа",
                идентификатор_отказа=идентификатор_отказа,
                ожидаемое_свидетельство="Отделить отказ набора от раннего валидатора.",
            ),
            сам.запись(3, "полная", ключи=[сам.ключ]),
        ]

        план = модуль.построить_план_успешной_сессии(записи)
        блок = модуль.сформировать_блок(записи, открытый_маркер)

        сам.assertEqual(len(план["дублирования"]), 1)
        сам.assertTrue(план["дублирования"][0]["разрешено"])
        сам.assertEqual(
            план["дублирования"][0]["длительность_наносекунды"],
            2_000_000_000,
        )
        сам.assertIn(
            "Дублирование полного набора: разрешено; 2 с;",
            блок,
        )

    def test_поздний_отказ_или_изменённый_снимок_лишают_план_приёмки(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        поздний_отказ = [
            сам.запись(1, "полная", ключи=[сам.ключ]),
            сам.запись(
                2,
                "полная",
                ключи=[сам.ключ],
                статус="неуспешно",
            ),
        ]

        план = модуль.построить_план_успешной_сессии(поздний_отказ)

        сам.assertEqual(план["состояние"], "не готов")
        сам.assertEqual(план["последний_полный_статус"], "неуспешно")
        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.проверить_порядок_проверок(поздний_отказ)

        один_финал = [сам.запись(1, "полная", ключи=[сам.ключ])]
        with сам.assertRaisesRegex(
            модуль.ОшибкаОтчёта,
            "снимок изменился",
        ):
            модуль.проверить_порядок_проверок(
                один_финал,
                "sha256:" + "b" * 64,
            )

    def test_финальный_полный_прогон_является_последней_терминальной_записью(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        полный = сам.запись(1, "полная", ключи=[сам.ключ])
        поздняя_адресная = сам.запись(2, "адресная")
        активная = сам.запись(2, "полная", ключи=[])
        активная[1].update(
            {
                "состояние": "выполняется",
                "длительность_наносекунды": None,
                "статус": None,
                "код_завершения": None,
            }
        )
        активная[1]["план"] = None
        активная[1]["наблюдения"] = []

        for название, записи, ошибка in (
            (
                "поздняя адресная",
                [полный, поздняя_адресная],
                "последней записью",
            ),
            (
                "активный полный прогон",
                [полный, активная],
                "выполняющуюся запись",
            ),
        ):
            with сам.subTest(случай=название):
                план = модуль.построить_план_успешной_сессии(записи)
                сам.assertEqual(план["состояние"], "не готов")
                with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, ошибка):
                    модуль.проверить_порядок_проверок(записи)

    def test_неуспешный_полный_старого_снимка_не_запрещает_финал(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        записи = [
            сам.запись(
                1,
                "полная",
                ключи=[сам.ключ],
                статус="неуспешно",
                снимок="sha256:" + "b" * 64,
            ),
            сам.запись(2, "полная", ключи=[сам.ключ]),
        ]

        план = модуль.построить_план_успешной_сессии(записи, сам.снимок)

        сам.assertEqual(план["полные_попытки"], 2)
        сам.assertEqual(план["полные_прогоны"], 1)
        сам.assertEqual(план["состояние"], "готов")
        сам.assertEqual(
            модуль.проверить_порядок_проверок(записи, сам.снимок)["состояние"],
            "готов",
        )

    def test_полную_попытку_нельзя_повторять_на_неизменённом_снимке(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        записи = [
            сам.запись(1, "полная", ключи=[], статус="неуспешно"),
            сам.запись(2, "полная", ключи=[сам.ключ]),
        ]

        сам.assertEqual(
            модуль.построить_план_успешной_сессии(записи, сам.снимок)[
                "повторные_полные_снимки"
            ],
            [сам.снимок],
        )
        with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "повторена на неизменённом снимке"):
            модуль.проверить_порядок_проверок(записи, сам.снимок)

    def test_два_успешных_полных_прогона_разных_снимков_отклоняются(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        записи = [
            сам.запись(1, "полная", ключи=[сам.ключ], снимок="sha256:" + "b" * 64),
            сам.запись(2, "полная", ключи=[сам.ключ]),
        ]

        with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "ровно один полный прогон"):
            модуль.проверить_порядок_проверок(записи, сам.снимок)

    def test_без_текущего_отпечатка_совпадение_снимка_не_доказано(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        записи = [сам.запись(1, "полная", ключи=[сам.ключ])]

        план = модуль.построить_план_успешной_сессии(записи)

        сам.assertEqual(план["состояние"], "не готов")
        сам.assertFalse(план["доказанные_условия"]["снимок_совпадает"])
        with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "текущий отпечаток"):
            модуль.проверить_порядок_проверок(записи)

    def test_историческая_запись_после_профилированной_отклоняется_планом(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        полный = сам.запись(1, "полная", ключи=[сам.ключ])
        путь, историческая, байты = сам.запись(2, "адресная")
        историческая["схема"] = "fum.test-run.v1"
        историческая.pop("план")
        историческая.pop("наблюдения")
        историческая.pop("профиль_проверки")
        записи = [полный, (путь, историческая, байты)]

        план = модуль.построить_план_успешной_сессии(записи)

        сам.assertEqual(план["состояние"], "не готов")
        with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "v1/v2"):
            модуль.проверить_порядок_проверок(записи)

    def test_диагностика_непокрытого_набора_рендерится_отдельно(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        непокрытый_ключ = "Прототипы/ОтдельныйПакет"
        записи = [
            сам.запись(
                1,
                "диагностическая",
                ключи=[непокрытый_ключ],
                основание="не_покрывается_финальной_комплексной_проверкой",
                ожидаемое_свидетельство="Подтвердить отдельный пакет.",
            ),
            сам.запись(2, "полная", ключи=[сам.ключ]),
        ]

        план = модуль.построить_план_успешной_сессии(записи, сам.снимок)
        блок = модуль.сформировать_блок(записи, открытый_маркер, сам.снимок)

        сам.assertEqual(план["состояние"], "готов")
        сам.assertIn(
            "Отдельная диагностическая проверка: 2 с; результат: успешно;",
            блок,
        )
        сам.assertIn(f"наборы: {непокрытый_ключ};", блок)
        сам.assertIn(
            "основание: не_покрывается_финальной_комплексной_проверкой.",
            блок,
        )

    def test_неуспешная_частично_непокрытая_диагностика_не_даёт_готовность(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        непокрытый_ключ = "Прототипы/ОтдельныйПакет"
        отказ = сам.запись(1, "адресная", статус="неуспешно")
        диагностика = сам.запись(
            2,
            "диагностическая",
            ключи=[сам.ключ, непокрытый_ключ],
            основание="локализация_наблюдаемого_отказа",
            идентификатор_отказа=str(отказ[1]["идентификатор"]),
            ожидаемое_свидетельство="Локализовать отказ двух наборов.",
            статус="неуспешно",
        )
        записи = [
            отказ,
            диагностика,
            сам.запись(3, "полная", ключи=[сам.ключ]),
        ]

        план = модуль.построить_план_успешной_сессии(записи)
        блок = модуль.сформировать_блок(записи, открытый_маркер)

        сам.assertEqual(план["состояние"], "не готов")
        сам.assertEqual(
            план["отдельные_диагностики"][0]["наборы"],
            [непокрытый_ключ],
        )
        сам.assertIn(f"наборы: {непокрытый_ключ};", блок)
        with сам.assertRaisesRegex(
            модуль.ОшибкаОтчёта,
            "непокрытая диагностика",
        ):
            модуль.проверить_порядок_проверок(записи)

    def test_отпечаток_игнорирует_собственные_файлы_и_замечает_содержательные_правки(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        фикстура = сам.новая_фикстура()
        содержательный_файл = сам.подготовить_репозиторный_снимок(фикстура)
        каталог_сессии = Path("Журнал") / имя_сессии

        def вычислить() -> str:
            return модуль.вычислить_отпечаток_снимка(
                фикстура.корень,
                каталог_сессии,
            )

        исходный = вычислить()
        сам.assertRegex(исходный, r"^sha256:[0-9a-f]{64}$")

        фикстура.каталог_записей.mkdir(parents=True)
        (фикстура.каталог_записей / "1_служебная-запись.json").write_text(
            "{}\n",
            encoding="utf-8",
        )
        фикстура.отчёт.write_text("Обновлённый предпросмотр.\n", encoding="utf-8")
        сам.assertEqual(вычислить(), исходный)

        содержательный_файл.write_text(
            "Изменённый отслеживаемый снимок.\n",
            encoding="utf-8",
        )
        с_изменением_отслеживаемого = вычислить()
        сам.assertNotEqual(с_изменением_отслеживаемого, исходный)

        неотслеживаемый = фикстура.корень / "новая-граница.txt"
        неотслеживаемый.write_text("Новая граница.\n", encoding="utf-8")
        сам.assertNotEqual(вычислить(), с_изменением_отслеживаемого)

    def test_отпечаток_игнорирует_точную_проекцию_но_замечает_близкий_путь(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        каталог_сессии = Path("Журнал") / имя_сессии
        проекция = (
            фикстура.корень
            / "Proyekcii"
            / "Bratislavskaya-pamyatj"
            / "fajlyi"
            / "proizvodnyj.md"
        )
        проекция.parent.mkdir(parents=True)
        проекция.write_text("Первое поколение.\n", encoding="utf-8")
        subprocess.run(
            ["git", "add", "-f", "--", "Proyekcii"],
            cwd=фикстура.корень,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "commit", "-q", "-m", "Производная область"],
            cwd=фикстура.корень,
            check=True,
            capture_output=True,
        )

        def вычислить() -> str:
            return модуль.вычислить_отпечаток_снимка(
                фикстура.корень,
                каталог_сессии,
            )

        исходный = вычислить()
        проекция.write_text("Второе поколение.\n", encoding="utf-8")
        сам.assertEqual(вычислить(), исходный)
        subprocess.run(
            ["git", "add", "-f", "--", "Proyekcii"],
            cwd=фикстура.корень,
            check=True,
            capture_output=True,
        )
        сам.assertEqual(вычислить(), исходный)
        новый_выход = проекция.parent / "novyj.md"
        новый_выход.write_text("Новое поколение.\n", encoding="utf-8")
        сам.assertEqual(вычислить(), исходный)

        близкие = (
            фикстура.корень / "Proyekcii-ne-kanonicheskaya.md",
            фикстура.корень / "Документация" / "Proyekcii" / "nested.md",
        )
        for близкий in близкие:
            with сам.subTest(путь=близкий.relative_to(фикстура.корень)):
                близкий.parent.mkdir(parents=True, exist_ok=True)
                близкий.write_text("Не проекция.\n", encoding="utf-8")
                сам.assertNotEqual(вычислить(), исходный)
                близкий.unlink()
        сам.assertTrue(модуль.путь_в_производном_пространстве("Proyekcii/fajl.md"))
        сам.assertFalse(модуль.путь_в_производном_пространстве("proyekcii/fajl.md"))

    def test_отпечаток_замечает_изменённый_подмодуль_несмотря_на_пользовательскую_настройку(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        with tempfile.TemporaryDirectory() as внешний_каталог:
            источник = Path(внешний_каталог)
            (источник / "зависимость.txt").write_text("Исходник.\n", encoding="utf-8")
            для_источника = (
                ("init", "-q"),
                ("config", "user.name", "FUM Tests"),
                ("config", "user.email", "fum-tests@example.invalid"),
                ("add", "."),
                ("commit", "-q", "-m", "Исходник зависимости"),
            )
            for команда in для_источника:
                subprocess.run(
                    ["git", *команда],
                    cwd=источник,
                    check=True,
                    capture_output=True,
                )
            subprocess.run(
                [
                    "git",
                    "-c",
                    "protocol.file.allow=always",
                    "submodule",
                    "add",
                    str(источник),
                    "Зависимости/ТестоваяЗависимость",
                ],
                cwd=фикстура.корень,
                check=True,
                capture_output=True,
            )
            subprocess.run(
                ["git", "commit", "-q", "-am", "Добавить тестовую зависимость"],
                cwd=фикстура.корень,
                check=True,
                capture_output=True,
            )
            subprocess.run(
                ["git", "config", "diff.ignoreSubmodules", "all"],
                cwd=фикстура.корень,
                check=True,
            )
            каталог_сессии = Path("Журнал") / имя_сессии
            исходный = модуль.вычислить_отпечаток_снимка(
                фикстура.корень,
                каталог_сессии,
            )
            путь_в_подмодуле = (
                фикстура.корень
                / "Зависимости"
                / "ТестоваяЗависимость"
                / "зависимость.txt"
            )
            путь_в_подмодуле.write_text("Изменено.\n", encoding="utf-8")

            with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "изменённый подмодуль"):
                модуль.вычислить_отпечаток_снимка(
                    фикстура.корень,
                    каталог_сессии,
                )
            сам.assertRegex(исходный, r"^sha256:[0-9a-f]{64}$")

    def test_командный_интерфейс_создаёт_профилированную_запись(сам) -> None:
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        идентификатор = "00000000-0000-4000-8000-000000000081"
        успех = фикстура.выполнить(
            "запустить",
            "--название",
            "живая адресная проверка",
            "--обычная-схема-профиля",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            идентификатор,
            "--класс-проверки",
            "адресная",
            "--",
            sys.executable,
            "-c",
            "pass",
        )

        сам.assertEqual(успех.returncode, 0, успех.stderr)
        запись = фикстура.запись(идентификатор)
        сам.assertEqual(set(запись), поля_профилированной_записи)
        сам.assertEqual(запись["схема"], "fum.test-run.v3")
        профиль = запись["профиль_проверки"]
        сам.assertEqual(set(профиль), поля_профиля_проверки)
        сам.assertEqual(профиль["класс"], "адресная")
        сам.assertEqual(профиль["полные_наборы"], [])
        сам.assertIsNone(профиль["основание"])
        сам.assertIsNone(профиль["идентификатор_отказа"])
        сам.assertIsNone(профиль["ожидаемое_свидетельство"])
        сам.assertRegex(
            профиль["отпечаток_снимка"],
            r"^sha256:[0-9a-f]{64}$",
        )

    def test_командный_интерфейс_требует_профиль_с_первого_нового_запуска(сам) -> None:
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        маркер = фикстура.корень / "непрофилированный-дочерний-процесс"

        результат = фикстура.выполнить(
            "запустить",
            "--название",
            "непрофилированная проверка",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            "00000000-0000-4000-8000-000000000084",
            "--",
            sys.executable,
            "-c",
            "from pathlib import Path; import sys; Path(sys.argv[1]).touch()",
            str(маркер),
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertIn("--класс-проверки", результат.stderr)
        сам.assertFalse(маркер.exists())

    def test_командный_интерфейс_отклоняет_сокращённый_флаг_и_отсутствие_разделителя(сам) -> None:
        for название, класс_аргумент, разделитель in (
            ("сокращённый флаг", "--класс-п", ["--"]),
            ("нет разделителя", "--класс-проверки", []),
        ):
            with сам.subTest(случай=название):
                фикстура = сам.новая_фикстура()
                сам.подготовить_репозиторный_снимок(фикстура)
                маркер = фикстура.корень / f"запрещённый-разбор-{название}"
                результат = фикстура.выполнить(
                    "запустить",
                    "--название",
                    "отклонить неточный вызов",
                    "--исполнитель",
                    "корневой агент",
                    "--идентификатор-запуска",
                    "00000000-0000-4000-8000-000000000089",
                    класс_аргумент,
                    "адресная",
                    *разделитель,
                    sys.executable,
                    "-c",
                    "from pathlib import Path; import sys; Path(sys.argv[1]).touch()",
                    str(маркер),
                )

                сам.assertNotEqual(результат.returncode, 0)
                сам.assertFalse(маркер.exists())

    def test_историческую_версию_два_нельзя_смешивать_с_новым_профилированным_контуром(сам) -> None:
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        путь = фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000085",
            1,
        )
        запись = json.loads(путь.read_text(encoding="utf-8"))
        запись.update(
            {
                "схема": "fum.test-run.v2",
                "план": [],
                "наблюдения": [],
            }
        )
        путь.write_text(
            json.dumps(запись, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        маркер = фикстура.корень / "смешанный-дочерний-процесс"

        результат = фикстура.выполнить(
            "запустить",
            "--название",
            "новая профилированная проверка",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            "00000000-0000-4000-8000-000000000086",
            "--класс-проверки",
            "адресная",
            "--",
            sys.executable,
            "-c",
            "from pathlib import Path; import sys; Path(sys.argv[1]).touch()",
            str(маркер),
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertIn("v2", результат.stderr)
        сам.assertFalse(маркер.exists())

    def test_исторический_префикс_разрешён_а_исторический_хвост_запрещён(сам) -> None:
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        фикстура.записать_завершённую_запись(
            1,
            "00000000-0000-4000-8000-000000000090",
            1,
        )
        новая = фикстура.выполнить(
            "запустить",
            "--название",
            "первая профилированная проверка",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            "00000000-0000-4000-8000-000000000091",
            "--класс-проверки",
            "адресная",
            "--",
            sys.executable,
            "-c",
            "pass",
        )

        сам.assertEqual(новая.returncode, 0, новая.stderr)
        сам.assertEqual(
            [запись["схема"] for запись in фикстура.записи()],
            ["fum.test-run.v1", "fum.test-run.v3"],
        )

        фикстура.записать_завершённую_запись(
            3,
            "00000000-0000-4000-8000-000000000092",
            1,
        )
        маркер = фикстура.корень / "дочерний-процесс-после-исторического-хвоста"
        отказ = фикстура.выполнить(
            "запустить",
            "--название",
            "запуск после исторического хвоста",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            "00000000-0000-4000-8000-000000000093",
            "--класс-проверки",
            "адресная",
            "--",
            sys.executable,
            "-c",
            "from pathlib import Path; import sys; Path(sys.argv[1]).touch()",
            str(маркер),
        )

        сам.assertNotEqual(отказ.returncode, 0)
        сам.assertIn("историч", отказ.stderr)
        сам.assertFalse(маркер.exists())

    def test_командный_интерфейс_проверяет_план_и_отпечаток_живой_сессии(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        фикстура = сам.новая_фикстура()
        содержательный_файл = сам.подготовить_репозиторный_снимок(фикстура)
        отпечаток = модуль.вычислить_отпечаток_снимка(
            фикстура.корень,
            Path(путь_запроса).parent,
        )
        путь, запись, _ = сам.запись(1, "полная", ключи=[сам.ключ])
        запись["профиль_проверки"]["отпечаток_снимка"] = отпечаток
        фикстура.каталог_записей.mkdir(parents=True)
        (фикстура.каталог_записей / путь.name).write_text(
            json.dumps(запись, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

        подтверждение = фикстура.выполнить("проверить-план")
        сам.assertEqual(подтверждение.returncode, 0, подтверждение.stderr)

        содержательный_файл.write_text("Изменённый снимок.\n", encoding="utf-8")
        отказ = фикстура.выполнить("проверить-план")
        сам.assertNotEqual(отказ.returncode, 0)
        сам.assertIn("снимок изменился", отказ.stderr)

    def test_командный_интерфейс_проверяет_план_только_в_открытой_сессии(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        отпечаток = модуль.вычислить_отпечаток_снимка(
            фикстура.корень,
            Path(путь_запроса).parent,
        )
        путь, запись, _ = сам.запись(1, "полная", ключи=[сам.ключ], снимок=отпечаток)
        фикстура.каталог_записей.mkdir(parents=True)
        (фикстура.каталог_записей / путь.name).write_text(
            json.dumps(запись, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        сам.assertEqual(фикстура.выполнить("проверить-план").returncode, 0)
        сам.assertEqual(фикстура.выполнить("закрыть").returncode, 0)

        закрытая_проверка = фикстура.выполнить("проверить-план")

        сам.assertNotEqual(закрытая_проверка.returncode, 0)
        сам.assertIn("открыт", закрытая_проверка.stderr)

    def test_закрытие_сохраняет_неуспешный_вердикт_времени_закрытия(сам) -> None:
        модуль = загрузить_модуль_автоматизации()
        фикстура = сам.новая_фикстура()
        содержательный_файл = сам.подготовить_репозиторный_снимок(фикстура)
        отпечаток = модуль.вычислить_отпечаток_снимка(
            фикстура.корень,
            Path(путь_запроса).parent,
        )
        путь, запись, _ = сам.запись(1, "полная", ключи=[сам.ключ])
        запись["профиль_проверки"]["отпечаток_снимка"] = отпечаток
        фикстура.каталог_записей.mkdir(parents=True)
        (фикстура.каталог_записей / путь.name).write_text(
            json.dumps(запись, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        содержательный_файл.write_text("Снимок B.\n", encoding="utf-8")
        отпечаток_закрытия = модуль.вычислить_отпечаток_снимка(
            фикстура.корень,
            Path(путь_запроса).parent,
        )

        закрытие = фикстура.выполнить("закрыть")

        сам.assertEqual(закрытие.returncode, 0, закрытие.stderr)
        снимок = json.loads(
            (фикстура.каталог_записей / "снимок.json").read_text(encoding="utf-8")
        )
        сам.assertEqual(снимок["схема"], "fum.test-run-report.v2")
        сам.assertEqual(снимок["отпечаток_закрытия"], отпечаток_закрытия)
        сам.assertIn(
            "Экономный порядок проверок: не готов.",
            фикстура.отчёт.read_text(encoding="utf-8"),
        )
        проверка = фикстура.выполнить("проверить")
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)

    def test_командный_интерфейс_не_запускает_неполную_диагностику(сам) -> None:
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        маркер = фикстура.корень / "дочерний-процесс-диагностики"

        отказ = фикстура.выполнить(
            "запустить",
            "--название",
            "неполная диагностика",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            "00000000-0000-4000-8000-000000000082",
            "--класс-проверки",
            "диагностическая",
            "--основание",
            "локализация_наблюдаемого_отказа",
            "--ожидаемое-свидетельство",
            "Найти источник наблюдаемого отказа.",
            "--полный-набор",
            сам.ключ,
            "--",
            sys.executable,
            "-c",
            "from pathlib import Path; import sys; Path(sys.argv[1]).touch()",
            str(маркер),
        )
        сам.assertNotEqual(отказ.returncode, 0)
        сам.assertIn(
            "требует точный UUID предшествующего неуспешного запуска",
            отказ.stderr,
        )
        сам.assertFalse(маркер.exists())

    def test_командный_интерфейс_не_принимает_прерывание_или_незавершённый_запуск_за_отказ(
        сам,
    ) -> None:
        модуль = загрузить_модуль_автоматизации()
        for статус, код in (("прервано", -2), ("не завершено", 125)):
            with сам.subTest(статус=статус):
                фикстура = сам.новая_фикстура()
                сам.подготовить_репозиторный_снимок(фикстура)
                отпечаток = модуль.вычислить_отпечаток_снимка(
                    фикстура.корень,
                    Path(путь_запроса).parent,
                )
                путь, ссылка, _ = сам.запись(
                    1,
                    "адресная",
                    статус=статус,
                    снимок=отпечаток,
                )
                ссылка["код_завершения"] = код
                фикстура.каталог_записей.mkdir(parents=True)
                (фикстура.каталог_записей / путь.name).write_text(
                    json.dumps(
                        ссылка,
                        ensure_ascii=False,
                        indent=2,
                        sort_keys=True,
                    )
                    + "\n",
                    encoding="utf-8",
                )
                маркер = фикстура.корень / f"дочерний-процесс-{код}"

                результат = фикстура.выполнить(
                    "запустить",
                    "--название",
                    "диагностика точного отказа",
                    "--исполнитель",
                    "корневой агент",
                    "--идентификатор-запуска",
                    f"00000000-0000-4000-8000-00000000009{abs(код) % 10}",
                    "--класс-проверки",
                    "диагностическая",
                    "--основание",
                    "локализация_наблюдаемого_отказа",
                    "--идентификатор-отказа",
                    str(ссылка["идентификатор"]),
                    "--ожидаемое-свидетельство",
                    "Локализовать точный неуспешный исход.",
                    "--полный-набор",
                    сам.ключ,
                    "--",
                    sys.executable,
                    "-c",
                    "from pathlib import Path; import sys; Path(sys.argv[1]).touch()",
                    str(маркер),
                )

                сам.assertNotEqual(результат.returncode, 0)
                сам.assertIn(
                    "диагностика требует предшествующий отказ на том же снимке",
                    результат.stderr,
                )
                сам.assertFalse(маркер.exists())

    def test_командный_интерфейс_не_запускает_финал_пока_есть_активная_запись(сам) -> None:
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        путь, активная, _ = сам.запись(1, "адресная")
        активная.update(
            {
                "состояние": "выполняется",
                "длительность_наносекунды": None,
                "статус": None,
                "код_завершения": None,
            }
        )
        фикстура.каталог_записей.mkdir(parents=True)
        (фикстура.каталог_записей / путь.name).write_text(
            json.dumps(активная, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        маркер = фикстура.корень / "дочерний-финал"
        путь_полной_проверки = (
            фикстура.корень
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "scripts"
            / "run-smoke-check.py"
        )

        результат = фикстура.выполнить(
            "запустить",
            "--название",
            "финальная комплексная проверка",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            "00000000-0000-4000-8000-000000000087",
            "--класс-проверки",
            "полная",
            "--",
            sys.executable,
            str(путь_полной_проверки),
            str(маркер),
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertIn("выполняющ", результат.stderr)
        сам.assertFalse(маркер.exists())

    def test_командный_интерфейс_не_запускает_адресную_проверку_пока_выполняется_финал(
        сам,
    ) -> None:
        фикстура = сам.новая_фикстура()
        сам.подготовить_репозиторный_снимок(фикстура)
        путь, активная, _ = сам.запись(1, "полная", ключи=[])
        активная.update(
            {
                "состояние": "выполняется",
                "длительность_наносекунды": None,
                "статус": None,
                "код_завершения": None,
                "план": None,
                "наблюдения": [],
            }
        )
        фикстура.каталог_записей.mkdir(parents=True)
        (фикстура.каталог_записей / путь.name).write_text(
            json.dumps(активная, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        маркер = фикстура.корень / "дочерняя-адресная-проверка"

        результат = фикстура.выполнить(
            "запустить",
            "--название",
            "поздняя адресная проверка",
            "--исполнитель",
            "корневой агент",
            "--идентификатор-запуска",
            "00000000-0000-4000-8000-000000000088",
            "--класс-проверки",
            "адресная",
            "--",
            sys.executable,
            "-c",
            "from pathlib import Path; import sys; Path(sys.argv[1]).touch()",
            str(маркер),
        )

        сам.assertNotEqual(результат.returncode, 0)
        сам.assertIn("выполняется финальная", результат.stderr)
        сам.assertFalse(маркер.exists())


class ТестыВременноЗакрытогоЗапуска(unittest.TestCase):
    def test_прямой_запуск_отказывает_до_всех_эффектов(сам):
        модуль = загрузить_модуль_автоматизации()
        варианты = ({}, {"обычная_схема_профиля": True}, {"приёмочные_раунды": True},
                    {"исходный_коммит_раундов": "a" * 40})
        with contextlib.ExitStack() as стек:
            вызовы = []
            for объект, имя in ((модуль, "разрешить_сессию"),
                                (модуль, "межпроцессная_блокировка"),
                                (модуль, "атомарно_записать_байты"),
                                (модуль, "выполнить_чтение_репозитория"),
                                (модуль.subprocess, "Popen")):
                вызовы.append(стек.enter_context(mock.patch.object(объект, имя, side_effect=AssertionError(имя))))
            стек.enter_context(mock.patch.object(модуль.os, "environ", object()))
            for параметры in варианты:
                for класс in ("адресная", "полная"):
                    with сам.subTest(параметры=параметры, класс=класс):
                        with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, "запуск проверок закрыт"):
                            модуль.выполнить_запуск(Path("/repo"), Path("/repo/request"),
                                "test", "root", None, 5.0, ["/bin/true"],
                                класс_проверки=класс, **параметры)
            for вызов in вызовы:
                вызов.assert_not_called()

    def test_cli_отказывает_до_всех_эффектов(сам):
        import io
        модуль = загрузить_модуль_автоматизации()
        общие = ["запустить", "--корень-репозитория", "/repo", "--запрос", "/repo/request",
                 "--название", "test", "--исполнитель", "root", "--класс-проверки", "адресная"]
        варианты = ([], ["--обычная-схема-профиля"], ["--приёмочные-раунды"],
                    ["--исходный-коммит-раундов", "a" * 40])
        with contextlib.ExitStack() as стек:
            вызовы = []
            for объект, имя in ((модуль, "разрешить_сессию"),
                                (модуль, "межпроцессная_блокировка"),
                                (модуль, "атомарно_записать_байты"),
                                (модуль, "выполнить_чтение_репозитория"),
                                (модуль.subprocess, "Popen")):
                вызовы.append(стек.enter_context(mock.patch.object(объект, имя, side_effect=AssertionError(имя))))
            стек.enter_context(mock.patch.object(модуль.os, "environ", object()))
            for вариант in варианты:
                with сам.subTest(вариант=вариант):
                    ошибки = io.StringIO()
                    with contextlib.redirect_stderr(ошибки):
                        код = модуль.главная([*общие, *вариант, "--", "/bin/true"])
                    сам.assertEqual(код, 1)
                    сам.assertIn("запуск проверок закрыт", ошибки.getvalue())
            for вызов in вызовы:
                вызов.assert_not_called()

    def test_cli_передаёт_прочие_команды_своим_обработчикам(сам):
        модуль = загрузить_модуль_автоматизации()
        for команда, функция in (("предпросмотр", "выполнить_предпросмотр"),
                                  ("проверить-план", "выполнить_проверку_плана"),
                                  ("закрыть", "выполнить_закрытие"),
                                  ("возобновить", "выполнить_возобновление")):
            with сам.subTest(команда=команда), mock.patch.object(модуль, функция, return_value=73) as вызов:
                код = модуль.главная([команда, "--корень-репозитория", "/repo", "--запрос", "/repo/request"])
                сам.assertEqual(код, 73)
                вызов.assert_called_once_with(Path("/repo"), Path("/repo/request"))

    def test_cli_с_ведущим_разделителем_отказывает_до_разбора(сам):
        import io
        модуль = загрузить_модуль_автоматизации()
        общие = ["запустить", "--корень-репозитория", "/repo", "--запрос", "/repo/request",
                 "--название", "test", "--исполнитель", "root", "--класс-проверки", "адресная",
                 "--", "/bin/true"]
        with mock.patch.object(модуль.os, "environ", object()), \
             mock.patch.object(модуль, "разрешить_сессию") as сессия, \
             mock.patch.object(модуль.subprocess, "Popen") as процесс:
            for разделители in (["--"], ["--", "--"]):
                with сам.subTest(разделители=разделители):
                    ошибки = io.StringIO()
                    with contextlib.redirect_stderr(ошибки):
                        код = модуль.главная([*разделители, *общие])
                    сам.assertEqual(код, 1)
                    сам.assertIn("запуск проверок закрыт", ошибки.getvalue())
            сессия.assert_not_called()
            процесс.assert_not_called()


class ТестыГраницыИсторическогоПрофиля(unittest.TestCase):
    def setUp(сам):
        сам.м = загрузить_модуль_автоматизации()
        сам.временный = tempfile.TemporaryDirectory(dir="/tmp")
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        сам.сессия = "Журнал/2026-09-08_10-00-00_MSK_проверка/запрос.md"
        сам.запрос = сам.корень / сам.сессия
        сам.запрос.parent.mkdir(parents=True)
        сам.запрос.write_text("Исторический запрос\n")
        сам.отчёт = сам.запрос.parent / "отчёт.md"
        сам.отчёт.write_text(сам.м.ОТКРЫТЫЙ_МАРКЕР + "\n\nистория\n" + сам.м.КОНЕЧНЫЙ_МАРКЕР + "\n")
        сам.каталог = сам.запрос.parent / "материалы/запуски-проверок"
        сам.каталог.mkdir(parents=True)
        сам.отпечаток = "sha256:" + "a" * 64
        сам.идентификатор = "00000000-0000-4000-8000-000000000001"
        профиль = {"класс": "полная", "отпечаток_снимка": сам.отпечаток,
                   "полные_наборы": [], "основание": None,
                   "идентификатор_отказа": None, "ожидаемое_свидетельство": None}
        запись = {"схема": "fum.test-run.v3", "идентификатор": сам.идентификатор,
                  "сессия": сам.сессия, "порядок": 1, "исполнитель": "тест",
                  "вызов": "историческая полная проверка", "состояние": "завершён",
                  "длительность_наносекунды": 0, "статус": "успешно", "код_завершения": 0,
                  "пояснение": None, "план": [], "наблюдения": [], "профиль_проверки": профиль}
        (сам.каталог / ("1_" + сам.идентификатор + ".json")).write_bytes(сам.м.канонические_машинные_байты(запись))
        сам.записи = сам.м.прочитать_историю_проверок(сам.каталог, сам.сессия)

    def test_история_читается_но_совпавший_старый_отпечаток_не_даёт_приёмку(сам):
        сам.assertEqual(сам.записи[0][1]["идентификатор"], сам.идентификатор)
        блок = сам.м.сформировать_блок_истории(сам.записи, сам.м.ОТКРЫТЫЙ_МАРКЕР)
        сам.assertIn("историческая полная проверка", блок)
        сам.assertIn("не готов", блок)
        with mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.проверить_порядок_проверок(сам.записи, сам.отпечаток)
            git.assert_not_called()

    def test_старый_git_reader_отказывает_до_среды_и_git(сам):
        with mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.выполнить_чтение_репозитория(сам.корень, "rev-parse", "HEAD")
            git.assert_not_called()

    def test_проверка_плана_не_принимает_историю_без_профиля(сам):
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.выполнить_проверку_плана(сам.корень, сам.запрос)
            git.assert_not_called()

    def test_подготовленный_исторический_снимок_не_закрывается_повторно(сам):
        снимок = сам.м.ожидаемый_снимок(сам.записи, сам.сессия, сам.отпечаток)
        (сам.каталог / сам.м.ИМЯ_СНИМКА).write_bytes(сам.м.канонические_машинные_байты(снимок))
        до = сам.отчёт.read_bytes()
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "заменить_управляемый_блок") as запись:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.выполнить_закрытие(сам.корень, сам.запрос)
            git.assert_not_called()
            запись.assert_not_called()
        сам.assertEqual(сам.отчёт.read_bytes(), до)

    def test_закрытая_история_проверяется_как_сохранённая_без_git(сам):
        снимок = сам.м.ожидаемый_снимок(сам.записи, сам.сессия, сам.отпечаток)
        байты = сам.м.канонические_машинные_байты(снимок)
        (сам.каталог / сам.м.ИМЯ_СНИМКА).write_bytes(байты)
        маркер = сам.м.сформировать_закрытый_маркер(байты)
        сам.отчёт.write_text(сам.м.сформировать_блок_истории(сам.записи, маркер, сам.отпечаток) + "\n")
        with mock.patch.object(сам.м, "межпроцессная_блокировка", return_value=contextlib.nullcontext()), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git:
            сам.assertEqual(сам.м.проверить_журнал_сессии(сам.корень, сам.запрос), [])
            git.assert_not_called()

    def test_закрытая_история_не_даёт_допуск_контрольной_точки(сам):
        снимок = сам.м.ожидаемый_снимок(сам.записи, сам.сессия, сам.отпечаток)
        байты = сам.м.канонические_машинные_байты(снимок)
        (сам.каталог / сам.м.ИМЯ_СНИМКА).write_bytes(байты)
        маркер = сам.м.сформировать_закрытый_маркер(байты)
        сам.отчёт.write_text(сам.м.сформировать_блок_истории(сам.записи, маркер, сам.отпечаток) + "\n")
        до = сам.отчёт.read_bytes()
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "атомарно_записать_байты") as запись:
            ошибки = сам.м.проверить_журнал_сессии(сам.корень, сам.запрос, контрольная_точка=True)
            сам.assertEqual(len(ошибки), 1)
            сам.assertRegex(ошибки[0], "профиль.*неизвестен")
            git.assert_not_called()
            запись.assert_not_called()
        сам.assertEqual(сам.отчёт.read_bytes(), до)

    def test_открытая_история_не_даёт_допуск_без_git_профиля(сам):
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "атомарно_записать_байты") as запись:
            ошибки = сам.м.проверить_журнал_сессии(сам.корень, сам.запрос, контрольная_точка=True)
            сам.assertEqual(len(ошибки), 1)
            сам.assertRegex(ошибки[0], "профиль.*неизвестен")
            git.assert_not_called()
            запись.assert_not_called()

    def подготовить_неготовый_снимок(сам):
        путь = сам.записи[0][0]
        значение = dict(сам.записи[0][1])
        значение["статус"] = "неуспешно"
        значение["код_завершения"] = 7
        путь.write_bytes(сам.м.канонические_машинные_байты(значение))
        сам.записи = сам.м.прочитать_историю_проверок(сам.каталог, сам.сессия)
        снимок = сам.м.ожидаемый_снимок(сам.записи, сам.сессия, сам.отпечаток)
        байты = сам.м.канонические_машинные_байты(снимок)
        (сам.каталог / сам.м.ИМЯ_СНИМКА).write_bytes(байты)
        маркер = сам.м.сформировать_закрытый_маркер(байты)
        сам.отчёт.write_text(сам.м.сформировать_блок_истории(сам.записи, маркер, сам.отпечаток) + "\n")
        return байты

    def test_неготовая_история_не_возобновляется_без_git_профиля(сам):
        сам.подготовить_неготовый_снимок()
        до = сам.отчёт.read_bytes()
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "атомарно_записать_байты", side_effect=AssertionError("запись")) as запись:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.выполнить_возобновление(сам.корень, сам.запрос)
            git.assert_not_called()
            запись.assert_not_called()
        сам.assertEqual(сам.отчёт.read_bytes(), до)
        сам.assertTrue((сам.каталог / сам.м.ИМЯ_СНИМКА).exists())

    def test_начатое_возобновление_истории_сохраняется_без_git_профиля(сам):
        байты_снимка = сам.подготовить_неготовый_снимок()
        закрытый = сам.отчёт.read_bytes()
        открытый = сам.м.заменить_управляемый_блок_в_байтах(
            закрытый, сам.м.сформировать_блок(сам.записи, сам.м.ОТКРЫТЫЙ_МАРКЕР, сам.отпечаток))
        журнал = сам.м.ожидаемый_журнал_возобновления(
            сам.сессия, байты_снимка, закрытый, открытый, сам.отпечаток)
        путь = сам.каталог / сам.м.ИМЯ_ЖУРНАЛА_ВОЗОБНОВЛЕНИЯ
        путь.write_bytes(сам.м.канонические_машинные_байты(журнал))
        до = путь.read_bytes()
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "заменить_управляемый_блок", side_effect=AssertionError("запись")) as запись:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.выполнить_возобновление(сам.корень, сам.запрос)
            git.assert_not_called()
            запись.assert_not_called()
        сам.assertEqual(путь.read_bytes(), до)
        сам.assertEqual(сам.отчёт.read_bytes(), закрытый)
        сам.assertEqual((сам.каталог / сам.м.ИМЯ_СНИМКА).read_bytes(), байты_снимка)

    def test_история_v1_без_git_профиля_сохраняет_возобновление(сам):
        путь = сам.записи[0][0]
        значение = dict(сам.записи[0][1])
        значение["схема"] = "fum.test-run.v1"
        for имя in ("план", "наблюдения", "профиль_проверки"):
            del значение[имя]
        путь.write_bytes(сам.м.канонические_машинные_байты(значение))
        записи = сам.м.прочитать_историю_проверок(сам.каталог, сам.сессия)
        снимок = сам.м.ожидаемый_снимок(записи, сам.сессия)
        байты = сам.м.канонические_машинные_байты(снимок)
        путь_снимка = сам.каталог / сам.м.ИМЯ_СНИМКА
        путь_снимка.write_bytes(байты)
        маркер = сам.м.сформировать_закрытый_маркер(байты)
        сам.отчёт.write_text(сам.м.сформировать_блок_истории(записи, маркер) + "\n")
        with mock.patch.object(сам.м, "межпроцессная_блокировка", return_value=contextlib.nullcontext()), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git:
            сам.assertEqual(сам.м.выполнить_возобновление(сам.корень, сам.запрос), 0)
            git.assert_not_called()
        сам.assertFalse(путь_снимка.exists())
        сам.assertTrue(путь.exists())
        сам.assertIn(сам.м.ОТКРЫТЫЙ_МАРКЕР, сам.отчёт.read_text())

    def test_раунды_v4_не_проходят_в_старое_возобновление(сам):
        путь_записи = сам.записи[0][0]
        запись = dict(сам.записи[0][1])
        запись["схема"] = "fum.test-run.v4"
        запись["отпечаток_содержимого"] = "sha256:" + "b" * 64
        запись["переход_схемы"] = None
        путь_записи.write_bytes(сам.м.канонические_машинные_байты(запись))
        журнал = сам.каталог / сам.м.ИМЯ_ЖУРНАЛА_ВОЗОБНОВЛЕНИЯ
        for уже_начато in (False, True):
            with сам.subTest(уже_начато=уже_начато):
                if уже_начато:
                    журнал.write_bytes(b"prepared synthetic record")
                with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
                     mock.patch.object(сам.м.os, "environ", object()), \
                     mock.patch.object(сам.м.subprocess, "run") as git, \
                     mock.patch.object(сам.м, "атомарно_записать_байты") as запись_файла:
                    with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "не поддерживает приёмочные раунды v4"):
                        сам.м.выполнить_возобновление(сам.корень, сам.запрос)
                    git.assert_not_called()
                    запись_файла.assert_not_called()
                if уже_начато:
                    сам.assertEqual(журнал.read_bytes(), b"prepared synthetic record")

    def test_собственная_активная_v3_не_даёт_контрольную_точку_без_профиля(сам):
        путь = сам.записи[0][0]
        значение = dict(сам.записи[0][1])
        значение["состояние"] = "выполняется"
        for имя in ("длительность_наносекунды", "статус", "код_завершения", "пояснение", "план"):
            значение[имя] = None
        путь.write_bytes(сам.м.канонические_машинные_байты(значение))
        сам.отчёт.write_text(сам.м.сформировать_блок_истории([], сам.м.ОТКРЫТЫЙ_МАРКЕР) + "\n")
        до = сам.отчёт.read_bytes()
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "атомарно_записать_байты") as запись:
            ошибки = сам.м.проверить_журнал_сессии(
                сам.корень, сам.запрос, контрольная_точка=True,
                идентификатор_активного_запуска=сам.идентификатор)
            сам.assertEqual(len(ошибки), 1)
            сам.assertRegex(ошибки[0], "профиль.*неизвестен")
            git.assert_not_called()
            запись.assert_not_called()
        сам.assertEqual(сам.отчёт.read_bytes(), до)

    def test_предпросмотр_v3_отказывает_до_старого_замка(сам):
        до = сам.отчёт.read_bytes()
        with mock.patch.object(сам.м, "межпроцессная_блокировка", side_effect=AssertionError("lock")), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "заменить_управляемый_блок") as запись:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.выполнить_предпросмотр(сам.корень, сам.запрос)
            git.assert_not_called()
            запись.assert_not_called()
        сам.assertEqual(сам.отчёт.read_bytes(), до)

    def test_закрытая_история_v4_проверяется_без_git(сам):
        путь = сам.записи[0][0]
        значение = dict(сам.записи[0][1])
        значение["схема"] = "fum.test-run.v4"
        содержимое = "sha256:" + "b" * 64
        значение["отпечаток_содержимого"] = содержимое
        значение["переход_схемы"] = None
        путь.write_bytes(сам.м.канонические_машинные_байты(значение))
        записи = сам.м.прочитать_историю_проверок(сам.каталог, сам.сессия)
        снимок = сам.м.ожидаемый_снимок_раундов(записи, сам.сессия, сам.отпечаток, содержимое)
        байты = сам.м.канонические_машинные_байты(снимок)
        (сам.каталог / сам.м.ИМЯ_СНИМКА).write_bytes(байты)
        маркер = сам.м.сформировать_закрытый_маркер(байты)
        сам.отчёт.write_text(сам.м.сформировать_блок_истории(записи, маркер, сам.отпечаток, содержимое) + "\n")
        with mock.patch.object(сам.м, "межпроцессная_блокировка", return_value=contextlib.nullcontext()), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git:
            сам.assertEqual(сам.м.проверить_журнал_сессии(сам.корень, сам.запрос), [])
            git.assert_not_called()

    def test_смена_v1_на_v3_между_проверками_отклоняется(сам):
        путь = сам.записи[0][0]
        v3 = путь.read_bytes()
        снимок = сам.м.ожидаемый_снимок(сам.записи, сам.сессия, сам.отпечаток)
        путь_снимка = сам.каталог / сам.м.ИМЯ_СНИМКА
        байты_снимка = сам.м.канонические_машинные_байты(снимок)
        путь_снимка.write_bytes(байты_снимка)
        v1 = dict(сам.записи[0][1])
        v1["схема"] = "fum.test-run.v1"
        for имя in ("план", "наблюдения", "профиль_проверки"):
            del v1[имя]
        путь.write_bytes(сам.м.канонические_машинные_байты(v1))
        до = сам.отчёт.read_bytes()
        @contextlib.contextmanager
        def подменить(*аргументы):
            путь.write_bytes(v3)
            yield
        with mock.patch.object(сам.м, "межпроцессная_блокировка", подменить), \
             mock.patch.object(сам.м.os, "environ", object()), \
             mock.patch.object(сам.м.subprocess, "run") as git, \
             mock.patch.object(сам.м, "заменить_управляемый_блок", side_effect=AssertionError("запись")) as запись:
            with сам.assertRaisesRegex(сам.м.ОшибкаОтчёта, "профиль.*неизвестен"):
                сам.м.выполнить_закрытие(сам.корень, сам.запрос)
            git.assert_not_called()
            запись.assert_not_called()
        сам.assertEqual(путь.read_bytes(), v3)
        сам.assertEqual(сам.отчёт.read_bytes(), до)
        сам.assertEqual(путь_снимка.read_bytes(), байты_снимка)

class ПроверкаЗащитыПрежнегоЗамка(unittest.TestCase):
    def setUp(сам):
        сам.м = загрузить_модуль_автоматизации()
        временный = tempfile.TemporaryDirectory(prefix='fum-lock-', dir='/private/tmp')
        сам.addCleanup(временный.cleanup)
        сам.каталог = Path(временный.name)
        сам.корень = сам.каталог / 'repo'
        сам.сессия = 'проверка/одна'
        ключ = hashlib.sha256(f'{сам.корень}\0{сам.сессия}'.encode('utf-8')).hexdigest()
        сам.путь = сам.каталог / f'fum-check-runs-{ключ}.lock'
        патч = mock.patch.object(сам.м.tempfile, 'gettempdir', return_value=str(сам.каталог))
        патч.start()
        сам.addCleanup(патч.stop)

    def замок(сам):
        return сам.м.межпроцессная_блокировка(сам.корень, сам.сессия)

    def создать(сам):
        fd = os.open(сам.путь, os.O_CREAT | os.O_EXCL | os.O_RDWR, 0o600)
        os.close(fd)
        сам.путь.chmod(0o600)

    def test_новый_и_существующий_файл_сохраняют_формат(сам):
        with сам.замок():
            сведения = сам.путь.stat()
            сам.assertEqual(сведения.st_mode & 0o777, 0o600)
            сам.assertEqual(сведения.st_nlink, 1)
        with сам.замок():
            сам.assertEqual(сам.путь.stat().st_ino, сведения.st_ino)

    def test_опасные_существующие_файлы_отклоняются(сам):
        import stat
        цель = сам.каталог / 'цель'
        цель.write_bytes('не менять'.encode('utf-8'))
        случаи = ('ссылка', 'fifo', 'несколько_ссылок', 'права')
        for вид in случаи:
            with сам.subTest(вид=вид):
                if os.path.lexists(сам.путь):
                    сам.путь.unlink()
                if вид == 'ссылка':
                    сам.путь.symlink_to(цель)
                elif вид == 'fifo':
                    os.mkfifo(сам.путь, 0o600)
                elif вид == 'несколько_ссылок':
                    os.link(цель, сам.путь)
                else:
                    сам.создать()
                    сам.путь.chmod(0o644)
                with сам.assertRaises((OSError, сам.м.ОшибкаОтчёта)):
                    with сам.замок():
                        сам.fail('опасный замок допущен')
                сам.путь.unlink()
        сам.assertEqual(цель.read_bytes(), 'не менять'.encode('utf-8'))

    def test_замена_после_lstat_или_после_flock_отклоняется(сам):
        import fcntl
        for момент in ('open', 'flock'):
            with сам.subTest(момент=момент):
                прежний = сам.путь.with_name('прежний')
                if os.path.lexists(сам.путь):
                    сам.путь.unlink()
                if os.path.lexists(прежний):
                    прежний.unlink()
                сам.создать()
                открыть, flock = os.open, fcntl.flock
                заменено = []
                def заменить():
                    сам.путь.rename(прежний)
                    fd = открыть(сам.путь, os.O_CREAT | os.O_EXCL | os.O_RDWR, 0o600)
                    os.close(fd)
                    заменено.append(True)
                def открыть_с_подменой(путь, *а, **к):
                    if момент == 'open' and Path(путь) == сам.путь and а and not а[0] & os.O_CREAT and not заменено:
                        заменить()
                    return открыть(путь, *а, **к)
                def flock_с_подменой(fd, операция):
                    результат = flock(fd, операция)
                    if момент == 'flock' and операция & fcntl.LOCK_EX and not заменено:
                        заменить()
                    return результат
                with mock.patch.object(сам.м.os, 'open', side_effect=открыть_с_подменой), \
                     mock.patch.object(сам.м.fcntl, 'flock', side_effect=flock_с_подменой):
                    with сам.assertRaises((OSError, сам.м.ОшибкаОтчёта)):
                        with сам.замок():
                            сам.fail('замена файла не обнаружена')
                сам.assertTrue(заменено)
                сам.путь.unlink()
                прежний.unlink()

    def test_другой_процесс_видит_тот_же_замок(сам):
        код = ('import fcntl,os,sys\n'
               'fd=os.open(sys.argv[1],os.O_RDWR)\n'
               'try:\n'
               ' fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB)\n'
               ' print("OPEN")\n'
               'except BlockingIOError:\n'
               ' print("BUSY")\n'
               'finally:\n'
               ' os.close(fd)\n')
        def проверить():
            р = subprocess.run([sys.executable, '-I', '-S', '-B', '-c', код, str(сам.путь)],
                env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'}, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5, check=False)
            сам.assertEqual(р.returncode, 0, р.stderr)
            return р.stdout
        with сам.замок():
            сам.assertEqual(проверить(), b'BUSY\n')
        сам.assertEqual(проверить(), b'OPEN\n')

    def test_неизвестное_закрытие_сохраняет_исходную_ошибку(сам):
        закрыть = os.close
        ошибки = []
        def закрыть_с_отказом(fd):
            закрыть(fd)
            ошибки.append(fd)
            raise OSError('исход close неизвестен')
        with mock.patch.object(сам.м.os, 'close', side_effect=закрыть_с_отказом):
            with сам.assertRaises(BaseException) as перехват:
                with сам.замок():
                    raise ValueError('ошибка тела')
        текст = repr(перехват.exception)
        if isinstance(перехват.exception, BaseExceptionGroup):
            текст += repr(перехват.exception.exceptions)
        сам.assertIn('ошибка тела', текст)
        сам.assertEqual(len(ошибки), 1)

    def test_подмена_во_время_работы_не_объявляется_успехом(сам):
        with сам.assertRaises(сам.м.ОшибкаОтчёта):
            with сам.замок():
                сам.путь.rename(сам.каталог / 'старый')
                сам.создать()

    def test_отказ_flock_закрывает_fd_без_повтора(сам):
        import fcntl
        закрыть = os.close
        операции, закрытия = [], []
        def отказ(fd, операция):
            операции.append(операция)
            raise OSError('отказ flock')
        def закрыть_один(fd):
            закрытия.append(fd)
            return закрыть(fd)
        with mock.patch.object(сам.м.fcntl, 'flock', side_effect=отказ), \
             mock.patch.object(сам.м.os, 'close', side_effect=закрыть_один):
            with сам.assertRaisesRegex(OSError, 'отказ flock'):
                with сам.замок():
                    сам.fail('отказ блокировки пропущен')
        сам.assertEqual(операции, [fcntl.LOCK_EX])
        сам.assertEqual(len(закрытия), 1)

    def test_ошибки_тела_unlock_и_close_сохраняются(сам):
        import fcntl
        flock, закрыть = fcntl.flock, os.close
        закрытия = []
        def отказ_unlock(fd, операция):
            результат = flock(fd, операция)
            if операция & fcntl.LOCK_UN:
                raise OSError('отказ unlock')
            return результат
        def отказ_close(fd):
            закрыть(fd)
            закрытия.append(fd)
            raise OSError('исход close неизвестен')
        def листья(ошибка):
            if isinstance(ошибка, BaseExceptionGroup):
                return sum((листья(вложенная) for вложенная in ошибка.exceptions), [])
            return [str(ошибка)]
        with mock.patch.object(сам.м.fcntl, 'flock', side_effect=отказ_unlock), \
             mock.patch.object(сам.м.os, 'close', side_effect=отказ_close):
            with сам.assertRaises(BaseExceptionGroup) as перехват:
                with сам.замок():
                    raise ValueError('ошибка тела')
        сам.assertEqual(len(закрытия), 1)
        сам.assertCountEqual(листья(перехват.exception),
                            ['ошибка тела', 'отказ unlock', 'исход close неизвестен'])

    def test_ошибка_close_не_повторяется_при_неизвестном_исходе(сам):
        код = """
import os, sys, types
from pathlib import Path
исходник, каталог, режим = sys.argv[1:]
м = types.ModuleType('candidate_lock_child')
м.__file__ = исходник
exec(compile(Path(исходник).read_bytes(), исходник, 'exec'), м.__dict__)
м.tempfile.gettempdir = lambda: каталог
обычный_close = os.close
вызовы = []
def неизвестный_close(fd):
    вызовы.append(fd)
    if режим == 'после':
        обычный_close(fd)
    raise OSError('неизвестный исход close')
м.os.close = неизвестный_close
try:
    try:
        with м.межпроцессная_блокировка(Path(каталог) / 'repo', 'проверка/одна'):
            pass
    except BaseExceptionGroup as ошибка:
        assert 'неизвестен исход закрытия' in str(ошибка)
    else:
        raise AssertionError('потеряна ошибка close')
finally:
    м.os.close = обычный_close
assert len(вызовы) == 1
try:
    os.fstat(вызовы[0])
except OSError:
    assert режим == 'после'
else:
    assert режим == 'до'
print('UNKNOWN')
"""
        for режим in ('до', 'после'):
            with сам.subTest(режим=режим):
                # Известный тесту незакрытый FD освободит ОС при выходе процесса.
                with tempfile.TemporaryDirectory(dir=сам.каталог) as отдельный:
                    р = subprocess.run([sys.executable, '-I', '-S', '-B', '-c', код,
                                        сам.м.__file__, отдельный, режим],
                                       env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'},
                                       stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, timeout=5, check=False)
                    сам.assertEqual((р.returncode, р.stdout), (0, b'UNKNOWN\n'), р.stderr)

    def test_настоящий_предпросмотр_отказывает_на_подменном_замке(сам):
        запрос = Path('Журнал/проверка/запрос.md')
        каталог = сам.корень / запрос.parent
        каталог.mkdir(parents=True)
        (каталог / 'запрос.md').write_text('# Запрос\n', encoding='utf-8')
        отчёт = каталог / 'отчёт.md'
        отчёт.write_text('начало\n' + сам.м.ОТКРЫТЫЙ_МАРКЕР + '\nстарое\n'
                         + сам.м.КОНЕЧНЫЙ_МАРКЕР + '\nконец\n', encoding='utf-8')
        история = каталог / 'материалы/запуски-проверок'
        история.mkdir(parents=True)
        идентификатор = '00000000-0000-4000-8000-000000000011'
        запись = {'схема': 'fum.test-run.v1', 'идентификатор': идентификатор,
                  'сессия': запрос.as_posix(), 'порядок': 1, 'исполнитель': 'root',
                  'вызов': 'проверка', 'состояние': 'завершён',
                  'длительность_наносекунды': 1_000_000, 'статус': 'успешно',
                  'код_завершения': 0, 'пояснение': None}
        (история / f'1_{идентификатор}.json').write_text(
            json.dumps(запись, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n',
            encoding='utf-8')
        сам.assertEqual(сам.м.выполнить_предпросмотр(сам.корень, запрос), 0)
        до = отчёт.read_bytes()
        сам.assertIn('проверка'.encode('utf-8'), до)
        сам.assertTrue(до.startswith('начало\n'.encode('utf-8')))
        сам.assertTrue(до.endswith('конец\n'.encode('utf-8')))
        ключ = hashlib.sha256(f'{сам.корень}\0{запрос.as_posix()}'.encode('utf-8')).hexdigest()
        замок = сам.каталог / f'fum-check-runs-{ключ}.lock'
        замок.unlink()
        цель = сам.каталог / 'чужой'
        цель.write_bytes(b'unchanged')
        замок.symlink_to(цель)
        with сам.assertRaises((OSError, сам.м.ОшибкаОтчёта)):
            сам.м.выполнить_предпросмотр(сам.корень, запрос)
        сам.assertEqual(отчёт.read_bytes(), до)
        сам.assertEqual(цель.read_bytes(), b'unchanged')


class ПроверкаОграниченнойСреды(unittest.TestCase):
    def test_дочерняя_среда_не_читает_унаследованную_и_различает_проекцию(сам):
        модуль = загрузить_модуль_автоматизации()
        идентификатор = "00000000-0000-4000-8000-000000000001"
        наблюдения = Path("/tmp/наблюдения.json")
        запретная_среда = object()
        базовая = {"PATH": os.defpath, "GIT_OPTIONAL_LOCKS": "0", "GIT_NO_LAZY_FETCH": "1",
                   "GIT_NO_REPLACE_OBJECTS": "1", "LC_ALL": "C"}
        with mock.patch.object(модуль.os, "environ", запретная_среда):
            обычная = модуль.подготовить_ограниченную_среду_проверки(
                идентификатор, наблюдения, неполная_проекция=False)
            без_наблюдений = модуль.подготовить_ограниченную_среду_проверки(
                идентификатор, None, неполная_проекция=False)
            проекция = модуль.подготовить_ограниченную_среду_проверки(
                идентификатор, None, неполная_проекция=True)
        сам.assertEqual(обычная, базовая | {"FUM_CHECK_RUN_ID": идентификатор,
                                           "FUM_CHECK_RUN_OBSERVATIONS_PATH": str(наблюдения)})
        сам.assertEqual(без_наблюдений, базовая | {"FUM_CHECK_RUN_ID": идентификатор})
        сам.assertEqual(проекция, базовая)

    def test_изолированный_git_не_читает_внешнюю_конфигурацию(сам):
        модуль = загрузить_модуль_автоматизации()
        идентификатор = '00000000-0000-4000-8000-000000000001'
        with mock.patch.object(модуль.os, 'environ', object()):
            изолированная = модуль.подготовить_ограниченную_среду_проверки(
                идентификатор, None, неполная_проекция=False, изолировать_git=True)
            изолированная_проекция = модуль.подготовить_ограниченную_среду_проверки(
                идентификатор, None, неполная_проекция=True, изолировать_git=True)
        with сам.assertRaises(модуль.ОшибкаОтчёта):
            модуль.подготовить_ограниченную_среду_проверки(
                идентификатор, None, неполная_проекция=False, изолировать_git=1)
        сам.assertEqual(изолированная_проекция, {
            'PATH': os.defpath, 'LC_ALL': 'C', 'GIT_OPTIONAL_LOCKS': '0',
            'GIT_NO_LAZY_FETCH': '1', 'GIT_NO_REPLACE_OBJECTS': '1',
            'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null',
            'GIT_ATTR_NOSYSTEM': '1',
        })
        сам.assertEqual(изолированная, изолированная_проекция | {'FUM_CHECK_RUN_ID': идентификатор})
        with tempfile.TemporaryDirectory(dir='/tmp') as временный:
            корень = Path(временный).resolve()
            личный_каталог = корень / 'fixture-home'
            личный_каталог.mkdir()
            (личный_каталог / '.gitconfig').write_text(
                '[fumfixture]\n\tmarker = fixture-global\n', encoding='utf-8')
            системный = корень / 'fixture-system.gitconfig'
            системный.write_text('[fumfixture]\n\tmarker = fixture-system\n', encoding='utf-8')
            проверка = ['/usr/bin/git', '-C', str(корень), 'config', '--show-scope', '--get-all', 'fumfixture.marker']
            среда = изолированная | {
                'HOME': str(личный_каталог), 'GIT_CONFIG_SYSTEM': str(системный),
                'GIT_CEILING_DIRECTORIES': str(корень.parent),
            }
            без_защиты = dict(среда)
            for ключ in ('GIT_CONFIG_NOSYSTEM', 'GIT_CONFIG_GLOBAL', 'GIT_ATTR_NOSYSTEM'):
                без_защиты.pop(ключ)
            открытая = subprocess.run(проверка, env=без_защиты, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5, check=False)
            сам.assertEqual(открытая.returncode, 0, открытая.stderr)
            сам.assertEqual(set(открытая.stdout.splitlines()),
                {b'system\tfixture-system', b'global\tfixture-global'})
            закрытая = subprocess.run(проверка, env=среда, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5, check=False)
            сам.assertEqual(закрытая.returncode, 1, закрытая.stderr)
            сам.assertEqual(закрытая.stdout, b'')

    def test_среда_отказывает_при_неоднозначных_входах(сам):
        модуль = загрузить_модуль_автоматизации()
        идентификатор = "00000000-0000-4000-8000-000000000001"
        for параметры in (("не-uuid", None, False),
                          (идентификатор, Path("относительный.json"), False),
                          (идентификатор, Path("/tmp/../наблюдения.json"), False),
                          (идентификатор, Path("/tmp/данные\0.json"), False),
                          (идентификатор, Path("/tmp/наблюдения.json"), True),
                          (идентификатор, None, 1)):
            with сам.subTest(параметры=параметры), сам.assertRaises(модуль.ОшибкаОтчёта):
                модуль.подготовить_ограниченную_среду_проверки(
                    параметры[0], параметры[1], неполная_проекция=параметры[2])
