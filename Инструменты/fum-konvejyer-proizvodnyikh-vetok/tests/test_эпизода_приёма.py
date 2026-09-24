"""Один долговечный эпизод независимо от среза, Журнала и пути вызывающего."""
import copy
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import эпизод_приёма as эпизод


class ПроверкаЭпизодаПриёма(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.назначение = {'корневая_задача': '11111111-1111-4111-8111-111111111111', 'слой': 'события'}
        self.задача = '22222222-2222-4222-8222-222222222222'
        self.блок = {'назначение_sha256': эпизод.хранение.хэш(self.назначение),
            'исполнитель': self.задача, 'корень': str(self.корень), 'ref': 'refs/heads/codex/слой',
            'база': 'a' * 40, 'исходный_коммит': 'b' * 40, 'срез': 'c' * 40,
            'источник_приёмки': 'd' * 40, 'журнал': 'Журнал/2026-09-24_12-00-00_MSK_приём/'}
        self.основание = self.собрать(self.блок)
        self.подмена = mock.patch.object(эпизод, 'КОРЕНЬ_СОСТОЯНИЯ', self.корень / 'приватное')
        self.подмена.start(); self.addCleanup(self.подмена.stop)

    def собрать(self, блок):
        тело = {'схема': 'fum.основание-дочернего-приёма.1', 'назначение': self.назначение,
            'поручение': блок, 'эпизод': эпизод.хранение.хэш({к: блок[к] for к in ('назначение_sha256', 'исполнитель')}),
            'срез': блок['срез'], 'дерево': 'e' * 40, 'приёмка': {'фикстура': True},
            'нативный_приём': {'фикстура': True}, 'журнал': блок['журнал'],
            'проверка': '33333333-3333-4333-8333-333333333333', 'разрешение_записи': False}
        return {**тело, 'sha256': эпизод.хранение.хэш(тело)}

    def test_чтение_отсутствующего_не_создаёт_каталог(self):
        self.assertIsNone(эпизод.прочитать(self.основание))
        self.assertFalse(эпизод.КОРЕНЬ_СОСТОЯНИЯ.exists())

    def test_повтор_возвращает_точные_байты_без_нового_допуска(self):
        первый = эпизод.начать(self.основание, lambda: copy.deepcopy(self.основание))
        путь = эпизод.путь_эпизода(self.основание)
        до = путь.read_bytes()
        self.assertEqual(первый, эпизод.начать(self.основание,
            lambda: self.fail('Повтор не должен заново допускать старый H')))
        self.assertEqual(до, путь.read_bytes())
        self.assertEqual(0o600, путь.stat().st_mode & 0o777)
        self.assertEqual(первый, эпизод.прочитать(self.основание))
        self.assertFalse(первый['разрешение_записи'])

    def test_новый_срез_или_журнал_не_открывает_другой_эпизод(self):
        эпизод.начать(self.основание, lambda: self.основание)
        for замена in ({'срез': 'f' * 40}, {'журнал': 'Журнал/2026-09-24_12-00-01_MSK_иной/'}):
            иной = self.собрать({**self.блок, **замена})
            self.assertEqual(эпизод.путь_эпизода(self.основание), эпизод.путь_эпизода(иной))
            with self.assertRaisesRegex(ValueError, 'друг|измен|совпа'):
                эпизод.начать(иной, lambda: иной)

    def test_сдвиг_допуска_до_записи_не_создаёт_намерение(self):
        иной = self.собрать({**self.блок, 'срез': 'f' * 40})
        with self.assertRaisesRegex(ValueError, 'допуск|основание'):
            эпизод.начать(self.основание, lambda: иной)
        self.assertIsNone(эпизод.прочитать(self.основание))

    def test_прерывание_после_метки_запрещает_повторную_инициализацию(self):
        установить = эпизод.хранение.установить
        def прервать(путь, данные):
            if путь == эпизод.путь_эпизода(self.основание):
                raise OSError('Сбой до записи намерения')
            return установить(путь, данные)
        with mock.patch.object(эпизод.хранение, 'установить', side_effect=прервать), self.assertRaises(OSError):
            эпизод.начать(self.основание, lambda: self.основание)
        with self.assertRaisesRegex(ValueError, 'Потерян|потерян|прерван'):
            эпизод.начать(self.основание, lambda: self.основание)

    def test_удаление_метки_и_повреждение_данных_не_обходятся(self):
        эпизод.начать(self.основание, lambda: self.основание)
        путь = эпизод.путь_эпизода(self.основание)
        метка = путь.with_suffix('.начато.json'); сохранённое = метка.read_bytes()
        метка.unlink()
        with self.assertRaises(ValueError): эпизод.прочитать(self.основание)
        метка.write_bytes(сохранённое); метка.chmod(0o600)
        путь.write_bytes(путь.read_bytes().replace(b'"sha256":', '"подмена":'.encode(), 1))
        with self.assertRaises(ValueError): эпизод.прочитать(self.основание)

    def test_ссылка_и_каталог_в_Git_отказывают(self):
        цель = self.корень / 'чужое'; цель.mkdir()
        эпизод.КОРЕНЬ_СОСТОЯНИЯ.symlink_to(цель, target_is_directory=True)
        with self.assertRaises(ValueError): эпизод.начать(self.основание, lambda: self.основание)
        эпизод.КОРЕНЬ_СОСТОЯНИЯ.unlink()
        (self.корень / '.git').mkdir()
        with self.assertRaises(ValueError): эпизод.начать(self.основание, lambda: self.основание)

    def test_новый_корень_синхронизируется_через_родителя_и_после_отказа(self):
        синхронизировать = эпизод.хранение.синхронизировать_каталог
        посещения = []
        def отказ(путь):
            посещения.append(путь)
            if путь == эпизод.КОРЕНЬ_СОСТОЯНИЯ.parent:
                raise OSError('Ошибка синхронизации родителя нового корня')
            return синхронизировать(путь)
        with mock.patch.object(эпизод.хранение, 'синхронизировать_каталог', side_effect=отказ):
            with self.assertRaises(OSError): эпизод.начать(self.основание, lambda: self.основание)
        self.assertIsNone(эпизод.прочитать(self.основание))
        посещения.clear()
        def продолжить(путь):
            посещения.append(путь)
            return синхронизировать(путь)
        with mock.patch.object(эпизод.хранение, 'синхронизировать_каталог', side_effect=продолжить):
            эпизод.начать(self.основание, lambda: self.основание)
        self.assertIn(эпизод.КОРЕНЬ_СОСТОЯНИЯ.parent, посещения)


if __name__ == '__main__':
    unittest.main()
