"""Настоящие процессы: смерть родителя, пределы и независимая квитанция."""
import fcntl
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
import uuid


наблюдатель = Path(__file__).resolve().parents[2] / 'Sources/ЯдроМашины/Ресурсы/наблюдатель.py'


def кодировать(данные):
    return (json.dumps(данные, ensure_ascii=False, sort_keys=True) + '\n').encode()


def командный_процесс(корень, режим):
    конец = time.monotonic() + 8  # Фикстура завершается сама и при поломке наблюдателя.
    if режим == 'потомок':
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        while time.monotonic() < конец:
            with (корень / 'пульс').open('ab') as поток: поток.write(b'.'); поток.flush()
            time.sleep(0.02)
        return 0
    if режим == 'семейство':
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        subprocess.Popen([sys.executable, '-B', __file__, '--команда', str(корень), 'потомок'])
        while time.monotonic() < конец: time.sleep(0.02)
        return 0
    if режим == 'поток':
        while time.monotonic() < конец: os.write(1, b'x' * 8192)
        return 0
    with (корень / 'число-команд').open('ab') as поток: поток.write(b'.')
    os.write(1, sys.stdin.buffer.read())
    os.write(2, 'ошибка'.encode())
    return 17 if режим == 'отказ' else 0


def родительский_процесс(корень, режим):
    описание = json.loads((корень / 'описание.json').read_bytes())
    замок = os.open(корень / 'замок', os.O_RDWR | os.O_CREAT, 0o600)
    fcntl.flock(замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
    каталог = os.open(корень, os.O_RDONLY | os.O_DIRECTORY)
    чтение, жизнь = os.pipe()
    with tempfile.TemporaryFile() as конфигурация, tempfile.TemporaryFile() as ввод, \
            (корень / 'вывод').open('w+b') as вывод, (корень / 'ошибки').open('w+b') as ошибки:
        for поток in (вывод, ошибки): os.fchmod(поток.fileno(), 0o600)
        конфигурация.write(кодировать(описание)); конфигурация.seek(0)
        ввод.write('точные байты\n'.encode()); ввод.seek(0)
        параметры = {'описание': конфигурация.fileno(), 'жизнь': чтение, 'замок': замок,
                     'каталог': каталог, 'вход': ввод.fileno(), 'вывод': вывод.fileno(), 'ошибки': ошибки.fileno()}
        добавленные = []
        if режим == 'грязный-вывод':
            вывод.write(b'x' * 100000); вывод.flush(); вывод.seek(0)
        if режим == 'читающий-вывод':
            параметры['вывод'] = os.open(корень / 'вывод', os.O_RDONLY)
            добавленные.append(параметры['вывод'])
        if режим == 'замок-во-входе':
            параметры['вход'] = os.dup(замок); добавленные.append(параметры['вход'])
        if режим == 'общие-приёмники':
            параметры['ошибки'] = os.dup(вывод.fileno()); добавленные.append(параметры['ошибки'])
        if режим == 'без-родителя': os.close(жизнь); жизнь = None
        процесс = subprocess.Popen([sys.executable, '-I', '-S', '-B', '-c', наблюдатель.read_text(),
            *[часть for имя, номер in параметры.items() for часть in ('--' + имя, str(номер))]],
            pass_fds=tuple(параметры.values()), start_new_session=True, stdout=subprocess.DEVNULL)
        os.close(чтение)
        try: return процесс.wait()
        finally:
            if жизнь is not None: os.close(жизнь)
            for номер in добавленные: os.close(номер)
            os.close(каталог); os.close(замок)


class ПроверкиНаблюдателя(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        сам.процессы = []
        сам.addCleanup(сам.убрать)

    def убрать(сам):
        for процесс in сам.процессы:
            if процесс.poll() is None:
                процесс.kill(); процесс.wait(timeout=3)
            for поток in (процесс.stdout, процесс.stderr):
                if поток is not None: поток.close()
        # Только живые непосредственные дети с сохранённым Popen. Исторические
        # PID не используются; семейная фикстура имеет собственный предел 8 s.

    def дождаться(сам, условие, предел=5):
        конец = time.monotonic() + предел
        while time.monotonic() < конец:
            if условие(): return
            time.sleep(0.01)
        сам.fail('Не получено ожидаемое свидетельство процесса')

    def описание(сам, режим='успех', срок=4, предел=65536, номер=None):
        return {'схема': 'fum.наблюдатель-команды.1', 'идентификатор': номер or str(uuid.uuid4()),
            'родитель': '12345678-1234-4234-8234-123456789abc',
            'проверка': '22345678-1234-4234-8234-123456789abc', 'исходник': 'a' * 64,
            'аргументы': [sys.executable, '-B', __file__, '--команда', str(сам.корень), режим],
            'каталог': str(сам.корень), 'среда': {'PATH': '/usr/bin:/bin'},
            'срок_нс': time.monotonic_ns() + int(срок * 1e9), 'предел_вывода': предел,
            'завершение_нс': 250_000_000}

    def запустить(сам, описание, режим='обычный'):
        (сам.корень / 'описание.json').write_bytes(кодировать(описание))
        процесс = subprocess.Popen([sys.executable, '-B', __file__, '--родитель', str(сам.корень), режим],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
        сам.процессы.append(процесс)
        return процесс

    def квитанция(сам, описание):
        return сам.корень / ('наблюдатель-' + описание['идентификатор'] + '-конец.json')

    def свободен(сам):
        замок = os.open(сам.корень / 'замок', os.O_RDWR)
        try:
            try: fcntl.flock(замок, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError: return False
            return True
        finally: os.close(замок)

    def test_результат_байты_и_повторный_номер_не_подменяют_прежнее(сам):
        описание = сам.описание('отказ')
        процесс = сам.запустить(описание)
        _, ошибки = процесс.communicate(timeout=5)
        сам.assertEqual(процесс.returncode, 0, ошибки.decode())
        исходные = сам.квитанция(описание).read_bytes()
        итог = json.loads(исходные)
        сам.assertEqual((итог['код_команды'], итог['причина'], итог['группа_исчезла']), (17, 'завершение', True))
        сам.assertEqual((сам.корень / 'вывод').read_bytes(), 'точные байты\n'.encode())
        сам.assertEqual((сам.корень / 'ошибки').read_bytes(), 'ошибка'.encode())
        процесс = сам.запустить(описание); процесс.communicate(timeout=5)
        сам.assertNotEqual(процесс.returncode, 0)
        сам.assertEqual(сам.квитанция(описание).read_bytes(), исходные)
        сам.assertEqual((сам.корень / 'число-команд').read_bytes(), b'.')
        следующий = сам.описание()
        процесс = сам.запустить(следующий); процесс.communicate(timeout=5)
        сам.assertEqual(процесс.returncode, 0)
        сам.assertNotEqual(следующий['идентификатор'], описание['идентификатор'])
        сам.assertEqual(сам.квитанция(описание).read_bytes(), исходные)
        сам.assertTrue(сам.свободен())

    def test_смерть_только_родителя_убирает_потомков_и_сохраняет_контроль(сам):
        контроль = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(20)'])
        сам.процессы.append(контроль)
        описание = сам.описание('семейство')
        процесс = сам.запустить(описание)
        сам.дождаться(lambda: (сам.корень / 'пульс').exists())
        сам.assertFalse(сам.свободен())
        os.kill(процесс.pid, signal.SIGKILL); процесс.wait(timeout=3)
        сам.assertFalse(сам.свободен())
        сам.дождаться(lambda: сам.квитанция(описание).exists())
        сам.дождаться(сам.свободен)
        итог = json.loads(сам.квитанция(описание).read_bytes())
        сам.assertEqual(итог['причина'], 'родитель_исчез')
        сам.assertTrue(итог['сигнал_TERM']); сам.assertTrue(итог['сигнал_KILL'])
        сам.assertTrue(итог['группа_исчезла'])
        размер = (сам.корень / 'пульс').stat().st_size
        time.sleep(0.1)
        сам.assertEqual((сам.корень / 'пульс').stat().st_size, размер)
        сам.assertIsNone(контроль.poll())

    def test_срок_завершает_семейство_игнорирующее_сигнал(сам):
        описание = сам.описание('семейство', срок=0.6)
        процесс = сам.запустить(описание); _, ошибки = процесс.communicate(timeout=5)
        сам.assertEqual(процесс.returncode, 0, ошибки.decode())
        итог = json.loads(сам.квитанция(описание).read_bytes())
        сам.assertEqual(итог['причина'], 'срок')
        сам.assertTrue(итог['сигнал_TERM'] and итог['сигнал_KILL'] and итог['группа_исчезла'])
        сам.assertTrue(сам.свободен())

    def test_поток_ограничен_до_записи_и_снимает_замок_после_очистки(сам):
        описание = сам.описание('поток', предел=512)
        процесс = сам.запустить(описание); _, ошибки = процесс.communicate(timeout=5)
        сам.assertEqual(процесс.returncode, 0, ошибки.decode())
        итог = json.loads(сам.квитанция(описание).read_bytes())
        сам.assertEqual(итог['причина'], 'вывод')
        сам.assertLessEqual((сам.корень / 'вывод').stat().st_size, 512)
        сам.assertGreater(итог['вывод_байт'], 512)
        сам.assertTrue(итог['группа_исчезла']); сам.assertTrue(сам.свободен())

    def test_закрытая_жизнь_до_старта_не_запускает_команду(сам):
        описание = сам.описание()
        процесс = сам.запустить(описание, 'без-родителя'); _, ошибки = процесс.communicate(timeout=5)
        сам.assertEqual(процесс.returncode, 0, ошибки.decode())
        итог = json.loads(сам.квитанция(описание).read_bytes())
        сам.assertEqual(итог['причина'], 'родитель_исчез')
        сам.assertIsNone(итог['код_команды'])
        сам.assertFalse((сам.корень / 'число-команд').exists())
        сам.assertTrue(сам.свободен())

    def test_одна_старая_конечная_квитанция_тоже_запрещает_повтор(сам):
        описание = сам.описание()
        прежнее = b'{"old":true}\n'
        сам.квитанция(описание).write_bytes(прежнее)
        процесс = сам.запустить(описание); процесс.communicate(timeout=5)
        сам.assertNotEqual(процесс.returncode, 0)
        сам.assertEqual(сам.квитанция(описание).read_bytes(), прежнее)
        сам.assertFalse((сам.корень / 'число-команд').exists())

    def test_неверные_приёмники_и_алиасы_отвергаются_до_команды(сам):
        for режим in ('грязный-вывод', 'читающий-вывод', 'замок-во-входе', 'общие-приёмники'):
            with сам.subTest(режим=режим):
                описание = сам.описание(предел=512)
                процесс = сам.запустить(описание, режим); процесс.communicate(timeout=5)
                сам.assertNotEqual(процесс.returncode, 0)
                сам.assertFalse((сам.корень / 'число-команд').exists())
                сам.assertFalse(сам.квитанция(описание).exists())
                сам.assertTrue(сам.свободен())

    def test_чужая_схема_не_запускает_команду(сам):
        описание = сам.описание(); описание['схема'] = 'чужая.1'
        процесс = сам.запустить(описание); процесс.communicate(timeout=5)
        сам.assertNotEqual(процесс.returncode, 0)
        сам.assertFalse((сам.корень / 'число-команд').exists())
        сам.assertFalse(сам.квитанция(описание).exists())


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--команда':
        raise SystemExit(командный_процесс(Path(sys.argv[2]), sys.argv[3]))
    if len(sys.argv) > 1 and sys.argv[1] == '--родитель':
        raise SystemExit(родительский_процесс(Path(sys.argv[2]), sys.argv[3]))
    unittest.main()
