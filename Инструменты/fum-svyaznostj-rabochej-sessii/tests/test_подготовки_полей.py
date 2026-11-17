"""Настоящий вложенный запуск готовит управляемый блок до проверки полей."""

import json
import importlib.util
import io
import hashlib
import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import uuid
from unittest import mock

from фикстура_полей_журнала import создать_пару

корень_кода = Path(__file__).resolve().parents[3]
помощник = Path(__file__).resolve().parents[1] / "scripts/подготовить-и-проверить-поля-журнала.py"
обёртка = корень_кода / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py"
маркер = "<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->"


class ПроверкаПараметровПомощника(unittest.TestCase):
    def test_issuer_fifo_отклоняется_до_pread(сам):
        спецификация = importlib.util.spec_from_file_location('помощник_issuer_test', помощник)
        модуль = importlib.util.module_from_spec(спецификация)
        with mock.patch('sys.path', [str(помощник.parent), *sys.path]):
            спецификация.loader.exec_module(модуль)
        чтение, запись = os.pipe()
        try:
            сам.assertGreater(чтение, 2)
            with mock.patch.object(модуль.os, 'pread', side_effect=AssertionError('чтение FIFO')) as читать:
                with сам.assertRaisesRegex(модуль.ОшибкаОтчёта, 'неверный файл synthetic issuer'):
                    модуль._тестово_сверить_опору_issuer(
                        str(чтение), [], '0' * 64, модуль._ТестоваяСверкаЗаписиПомощника)
                читать.assert_not_called()
        finally:
            os.close(чтение)
            os.close(запись)

    def test_bridge_принимает_только_полный_набор(сам):
        спецификация = importlib.util.spec_from_file_location('помощник_полей', помощник)
        модуль = importlib.util.module_from_spec(спецификация)
        with mock.patch('sys.path', [str(помощник.parent), *sys.path]):
            спецификация.loader.exec_module(модуль)
        общие = ['helper', '--корень', '/private/tmp/fixture', '--запрос', 'запрос.md']
        опытные = ['--каталог-замка', '/private/tmp/old',
                   '--тестовый-каталог-нового-замка', '/private/tmp/new',
                   '--тестовый-active', 'fixture', '--тестовые-опоры', '1', '2', '3', '4']
        with mock.patch.object(модуль, 'выполнить_предпросмотр') as обычный, \
             mock.patch.object(модуль, '_тестово_предпросмотреть_active_помощника') as bridge, \
             mock.patch.object(модуль, 'проверить', return_value={'ошибки': []}), \
             mock.patch('sys.stdout', new_callable=io.StringIO):
            with mock.patch('sys.argv', общие):
                сам.assertEqual(модуль.выполнить(), 0)
            обычный.assert_called_once()
            with mock.patch('sys.argv', общие + ['--тестовый-active', 'fixture']):
                сам.assertEqual(модуль.выполнить(), 2)
            bridge.assert_not_called()
            with mock.patch('sys.argv', общие + опытные):
                сам.assertEqual(модуль.выполнить(), 0)
            bridge.assert_called_once_with(Path('/private/tmp/fixture'), Path('запрос.md'),
                Path('/private/tmp/old'), Path('/private/tmp/new'), 'fixture', ((1, 2), (3, 4)))

    def _проверить_реальный_канал(сам, режим):
        база = Path(tempfile.mkdtemp(prefix='fum-helper-channel-', dir='/private/tmp')).resolve()
        root, locks, receipts = (база / имя for имя in ('root', 'locks', 'receipts'))
        for путь in (root, locks, receipts):
            путь.mkdir(mode=0o700)
        fds = []
        def учесть(fd):
            fds.append(fd)
            return fd
        def закрыть(fd):
            os.close(fd)
            fds.remove(fd)
        def точно(fd, размер, срок):
            результат = b''
            while len(результат) < размер:
                осталось = срок - time.monotonic()
                if осталось <= 0 or not select.select([fd], [], [], осталось)[0]:
                    raise RuntimeError('срок канала неизвестен')
                часть = os.read(fd, размер - len(результат))
                if not часть:
                    raise RuntimeError('неполный кадр')
                результат += часть
            return результат
        def до_eof(fd, срок):
            os.set_blocking(fd, False)
            результат = bytearray()
            while True:
                осталось = срок - time.monotonic()
                if осталось <= 0 or not select.select([fd], [], [], осталось)[0]:
                    raise RuntimeError('EOF канала неизвестен')
                try:
                    часть = os.read(fd, 4097 - len(результат))
                except BlockingIOError:
                    continue
                if not часть:
                    return bytes(результат)
                результат.extend(часть)
                if len(результат) > 4096:
                    raise RuntimeError('превышен предел вывода')
        процесс = None
        собран = False
        завершено = False
        try:
            корень_fd, lock_fd, receipt_fd = (учесть(os.open(путь, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW))
                                             for путь in (root, locks, receipts))
            вход_r, вход_w = (учесть(fd) for fd in os.pipe())
            выход_r, выход_w = (учесть(fd) for fd in os.pipe())
            run, generation = uuid.uuid4(), uuid.uuid4()
            raw = json.dumps({'schema': 'fum.test-helper-intent.1', 'state': 'UNKNOWN',
                              'run': str(run), 'generation': str(generation), 'grant_sha256': '0' * 64},
                             sort_keys=True, separators=(',', ':')).encode()
            fd = учесть(os.open('intent.json', os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                0o600, dir_fd=receipt_fd))
            сам.assertEqual(os.write(fd, raw), len(raw)); os.fsync(fd); закрыть(fd); os.fsync(receipt_fd)
            nonce = bytes(range(1, 17)); digest = hashlib.sha256(raw).digest()
            if режим == 'плохой-hash': digest = bytes(32)
            hello = b'FHU1' + run.bytes + generation.bytes + nonce + digest
            среда = {'FUM_SYNTHETIC_HELPER_FDS': ','.join(map(str, (вход_r, выход_w, корень_fd, lock_fd, receipt_fd)))}
            процесс = subprocess.Popen([sys.executable, '-S', '-B', str(помощник), '--корень', str(root),
                                        '--запрос', 'Журнал/fixture/запрос.md', '--тестовый-канал-без-записи'],
                                       cwd=root, env=среда, stdin=subprocess.DEVNULL,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       pass_fds=(вход_r, выход_w, корень_fd, lock_fd, receipt_fd),
                                       close_fds=True, start_new_session=True)
            закрыть(вход_r); закрыть(выход_w)
            срок = time.monotonic() + 15.0
            сам.assertEqual(os.write(вход_w, hello), len(hello))
            if режим != 'плохой-hash':
                сам.assertEqual(точно(выход_r, 84, срок), b'FHR1' + hello[4:])
                go = b'FHG1' + hello[4:] + (b'!' if режим == 'хвост' else b'')
                сам.assertEqual(os.write(вход_w, go), len(go))
            закрыть(вход_w)
            if режим == 'успех':
                сам.assertEqual(точно(выход_r, 84, срок), b'FHX1' + hello[4:])
            raw_status = None
            while time.monotonic() < срок:
                pid, значение = os.waitpid(процесс.pid, os.WNOHANG)
                if pid == процесс.pid:
                    raw_status = значение; процесс.returncode = os.waitstatus_to_exitcode(значение); собран = True
                    break
                time.sleep(0.01)
            if raw_status is None:
                raise RuntimeError('исход процесса неизвестен')
            сам.assertEqual(raw_status, (3 if режим == 'успех' else 2) << 8)
            вывод = до_eof(процесс.stdout.fileno(), срок); ошибки = до_eof(процесс.stderr.fileno(), срок)
            сам.assertLessEqual(len(вывод), 4096); сам.assertEqual(ошибки, b'')
            сам.assertNotIn(os.fsencode(root), вывод)
            сам.assertEqual(до_eof(выход_r, срок), b'')
            процесс.stdout.close(); процесс.stderr.close()
            завершено = True
            данные = json.loads(вывод)
            if режим == 'успех':
                сам.assertEqual(данные, {'схема': 'fum.test-helper-channel.1', 'состояние': 'UNKNOWN'})
            else:
                сам.assertEqual(данные['ошибки'], ['тестовый канал не подтверждён'])
            сам.assertEqual(list(root.iterdir()), [])
        except BaseException:
            if процесс is not None and not завершено:
                print('state=UNKNOWN HOLD', flush=True)
                threading.Event().wait()
            raise
        finally:
            for fd in reversed(fds):
                os.close(fd)

    def test_реальный_канал_helper_без_записи(self):
        self._проверить_реальный_канал('успех')

    def test_реальный_канал_helper_отклоняет_неверный_hash(self):
        self._проверить_реальный_канал('плохой-hash')

    def test_реальный_канал_helper_отклоняет_хвост(self):
        self._проверить_реальный_канал('хвост')


class ПроверкиПодготовкиПолей(unittest.TestCase):
    def setUp(сам):
        сам.корень = Path(сам.enterContext(tempfile.TemporaryDirectory())).resolve()
        сам.запрос = создать_пару(сам.корень)
        сам.отчёт = сам.запрос.with_name("отчёт.md")
        текст = сам.отчёт.read_text()
        начало = текст.index("| Вызов |")
        конец = текст.index("## Источники")
        сам.отчёт.write_text(текст[:начало] +
            "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->\n" +
            маркер + "\n<!-- FUM-CHECK-RUNS:END -->\n\n" + текст[конец:])
        сам.каталог = сам.запрос.parent / "материалы/запуски-проверок"
        for команда in (["init", "-q"], ["add", "."],
                        ["-c", "user.name=Фикстура", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "Фикстура"]):
            subprocess.run(["git", *команда], cwd=сам.корень, check=True, capture_output=True)

    def вызвать(сам, обернуть=False):
        команда = [sys.executable, "-B", str(помощник), "--корень", str(сам.корень), "--запрос", str(сам.запрос)]
        if обернуть:
            команда = [sys.executable, "-B", str(обёртка), "запустить",
                "--корень-репозитория", str(сам.корень), "--запрос", str(сам.запрос),
                "--название", "Подготовить поля", "--исполнитель", "Фикстура",
                "--класс-проверки", "адресная", "--приёмочные-раунды",
                "--тайм-аут-секунды", "20", "--", *команда]
        return subprocess.run(команда, cwd=сам.корень, capture_output=True, text=True, timeout=30)

    def test_первая_активная_запись_завершается_без_взаимной_блокировки(сам):
        сам.assertFalse(сам.каталог.exists())
        результат = сам.вызвать(True)
        сам.assertEqual(результат.returncode, 0, результат.stdout + результат.stderr)
        записи = list(сам.каталог.glob("*.json"))
        сам.assertEqual(len(записи), 1)
        запись = json.loads(записи[0].read_text())
        сам.assertEqual((запись["схема"], запись["состояние"], запись["статус"]),
                        ("fum.test-run.v4", "завершён", "успешно"))
        сам.assertNotIn(маркер, сам.отчёт.read_text())
        сам.assertIn("нет активных»: не выполнено", сам.отчёт.read_text())

    def test_маркер_вне_управляемого_блока_остаётся_ошибкой(сам):
        сам.отчёт.write_text(сам.отчёт.read_text() + "\n" + маркер + "\n")
        результат = сам.вызвать(True)
        сам.assertEqual(результат.returncode, 1, результат.stdout + результат.stderr)
        запись = json.loads(next(сам.каталог.glob("*.json")).read_text())
        сам.assertEqual(запись["статус"], "неуспешно")
        сам.assertEqual(сам.отчёт.read_text().count(маркер), 1)

    def test_отсутствующая_история_не_создаётся_помощником(сам):
        исходное = сам.отчёт.read_bytes()
        результат = сам.вызвать()
        сам.assertEqual(результат.returncode, 2)
        сам.assertTrue(json.loads(результат.stdout)["ошибки"])
        сам.assertFalse(сам.каталог.exists())
        сам.assertEqual(сам.отчёт.read_bytes(), исходное)

    def test_повреждённая_история_не_перезаписывает_отчёт(сам):
        сам.каталог.mkdir(parents=True)
        (сам.каталог / "повреждено.json").write_text("{}\n")
        исходное = сам.отчёт.read_bytes()
        результат = сам.вызвать()
        сам.assertEqual(результат.returncode, 2)
        сам.assertTrue(json.loads(результат.stdout)["ошибки"])
        сам.assertEqual(сам.отчёт.read_bytes(), исходное)

    def test_закрытие_и_возобновление_не_обходятся(сам):
        сам.каталог.mkdir(parents=True)
        for имя in ("снимок.json", "возобновление.json"):
            with сам.subTest(имя=имя):
                путь = сам.каталог / имя
                путь.write_text("{}\n")
                исходное = сам.отчёт.read_bytes()
                результат = сам.вызвать()
                сам.assertEqual(результат.returncode, 2)
                сам.assertTrue(json.loads(результат.stdout)["ошибки"])
                сам.assertEqual(сам.отчёт.read_bytes(), исходное)
                путь.unlink()

    def test_потерянная_ссылка_не_исправляется_предпросмотром(сам):
        сам.отчёт.write_text(сам.отчёт.read_text().replace("[Исходный запрос](запрос.md).", "Источник утрачен."))
        результат = сам.вызвать(True)
        сам.assertEqual(результат.returncode, 1, результат.stdout + результат.stderr)
        сам.assertIn("Нет прямой ссылки", результат.stdout)


if __name__ == "__main__":
    unittest.main()
