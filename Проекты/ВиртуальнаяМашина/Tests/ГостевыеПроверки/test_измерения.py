"""Срок и жизненный цикл команды подтверждаются до успешного события."""
import importlib.util
import json
import os
from pathlib import Path
import signal
import tempfile
import unittest
from unittest import mock

ресурс = Path(__file__).resolve().parents[2] / 'Sources/ЯдроМашины/Ресурсы/готовность.py'
спецификация = importlib.util.spec_from_file_location('измерения_гостя', ресурс)
модуль = importlib.util.module_from_spec(спецификация); спецификация.loader.exec_module(модуль)


class ПроверкиИзмерений(unittest.TestCase):
    def испытать(сам, часы, остаток=False, ожидаемая_ошибка=None):
        родитель = '12345678-1234-4234-8234-123456789abc'
        запуск = '22345678-1234-4234-8234-123456789abc'
        процесс = mock.Mock(pid=123456, returncode=0)
        процесс.poll.side_effect = [None, 0]
        сигналы = []
        def послать(идентификатор, сигнал):
            сам.assertEqual(идентификатор, процесс.pid)
            сигналы.append(сигнал)
            if not остаток: raise ProcessLookupError()
        with tempfile.TemporaryDirectory() as временный:
            каталог = os.open(временный, os.O_RDONLY | os.O_DIRECTORY)
            try:
                метрики = модуль.ИзмеренияГостя(родитель, каталог, запуск, 'a' * 64)
                with mock.patch.object(модуль.subprocess, 'Popen', return_value=процесс), \
                     mock.patch.object(модуль.time, 'monotonic', side_effect=часы), \
                     mock.patch.object(модуль.time, 'sleep'), mock.patch.object(модуль.os, 'killpg', side_effect=послать):
                    if ожидаемая_ошибка:
                        with сам.assertRaisesRegex(ValueError, ожидаемая_ошибка):
                            метрики.команда('Открытая команда', ['/фикстура'], предел=1)
                    else:
                        сам.assertEqual(метрики.команда('Открытая команда', ['/фикстура'], предел=1), b'')
                события = [json.loads(путь.read_text()) for путь in Path(временный).glob('*.json')]
                сам.assertEqual(len(события), 2)
                начало = next(событие for событие in события if событие['исход'] == 'выполняется')
                конец = next(событие for событие in события if событие['исход'] != 'выполняется')
                сам.assertEqual(начало['идентификатор'], конец['идентификатор'])
                сам.assertEqual(конец['исход'], 'ошибка' if ожидаемая_ошибка else 'успех')
                сам.assertIsNone(начало['длительностьНс'])
                сам.assertGreaterEqual(конец['длительностьНс'], 0)
                for событие in события:
                    сам.assertEqual((событие['родитель'], событие['запуск'], событие['происхождение']), (родитель, запуск, 'a' * 64))
                процесс.wait.assert_called_once()
                if остаток: сам.assertIn(signal.SIGKILL, сигналы)
            finally: os.close(каталог)

    def test_завершение_после_срока_не_принимается(сам):
        сам.испытать([0, 0.1, 1.1], ожидаемая_ошибка='Превышено время')

    def test_своевременное_завершение_принимается(сам):
        сам.испытать([0, 0.1, 0.2])

    def test_оставшийся_дочерний_процесс_не_принимается(сам):
        сам.испытать([0, 0.1, 0.2], остаток=True, ожидаемая_ошибка='дочерн')


if __name__ == '__main__': unittest.main()
