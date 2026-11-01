"""Адресный приём читает send/wait, сохраняя строгий обычный разбор create."""
import copy
import unittest

import test_нативных_вызовов as фикстура


class ПроверкаОтбораВозобновления(unittest.TestCase):
    def setUp(self):
        self.вход = фикстура.ПроверкаНативныхВызовов()
        self.вход.setUp()
        self.addCleanup(self.вход.doCleanups)

    def test_старое_создание_не_становится_основанием_нового_send(self):
        старое = copy.deepcopy(self.вход.событие)
        старое['payload']['item'].update(status='failed')
        новое = copy.deepcopy(self.вход.событие)
        новое['payload'].update(started_at_ms=10, completed_at_ms=20)
        новое['payload']['item'].update(id='send', tool='send_message_to_thread',
            arguments={'threadId': self.вход.задача, 'prompt': 'Принять срез'})
        записи = [старое, новое]
        with self.assertRaises(ValueError):
            self.вход.прочитать(записи, ожидания=[self.вход.задача], интервалы=True)
        итог = self.вход.прочитать(записи, ожидания=[self.вход.задача], интервалы=True,
                                  читать_создания=False)
        self.assertEqual([], итог['вызовы'])
        self.assertEqual(['send'], [э['id'] for э in итог['возобновления']])
        self.assertEqual({'начало_мс': 10, 'конец_мс': 20}, итог['возобновления'][0]['интервал'])
        новое['payload']['item']['status'] = 'failed'
        with self.assertRaisesRegex(ValueError, 'исход'):
            self.вход.прочитать(записи, ожидания=[self.вход.задача], интервалы=True,
                                читать_создания=False)

    def test_неоднозначный_режим_отбора_отклоняется(self):
        for значение in (None, 0, 'нет'):
            with self.subTest(значение=значение), self.assertRaises(ValueError):
                self.вход.прочитать(читать_создания=значение)


if __name__ == '__main__':
    unittest.main()
