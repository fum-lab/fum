"""Приём требует остановки, адресного send и совпавшего нативного входа."""
import copy
import importlib
import unittest

from фикстура_нативного_приёма import фикстура, ЗАДАЧА, РЕБЁНОК, ХОД


class ПроверкаНативногоПриёма(unittest.TestCase):
    def прочитать(self, ф, свидетельство=None, текст=None):
        return importlib.import_module('нативный_приём').прочитать(
            ф['свидетельство'] if свидетельство is None else свидетельство,
            ЗАДАЧА, РЕБЁНОК, str(ф['корень']), ф['источник'], ф['текст'] if текст is None else текст)

    def test_двустороннее_происхождение_стабильно_после_обычного_вывода(self):
        with фикстура() as ф:
            до = self.прочитать(ф)
            self.assertEqual(ХОД, до['остановленный_ход'])
            self.assertEqual(ф['текст'], до['текст'])
            from test_завершения_запуска import строка
            with ф['источник'].open('ab') as файл:
                файл.write(строка({'type': 'response_item', 'payload': {'type': 'message',
                    'role': 'assistant', 'content': [{'type': 'output_text', 'text': 'Проверяю'}]}}))
            self.assertEqual(до, self.прочитать(ф))

    def test_чужой_вход_и_позднее_поручение_не_теряются(self):
        with фикстура() as ф:
            with self.assertRaises(ValueError):
                self.прочитать(ф, текст='Другой текст')
            for входы in ([ф['транспорт'], ф['транспорт']], [
                    ф['транспорт'], {'type': 'event_msg', 'payload': {'type': 'user_message', 'message': 'Стоп'}}]):
                with self.subTest(входы=входы), self.assertRaises(ValueError):
                    self.прочитать(ф, ф['сохранить'](входы=входы))

    def test_перекрытие_ожидания_и_позднее_воздействие_закрывают_допуск(self):
        with фикстура() as ф:
            for начало in (19, 20):
                send = copy.deepcopy(ф['send']); send['payload']['started_at_ms'] = начало
                with self.subTest(начало=начало), self.assertRaises(ValueError):
                    self.прочитать(ф, ф['сохранить']([ф['wait'], send]))
            лишнее = copy.deepcopy(ф['send']); лишнее['payload']['item']['id'] = 'позднее'
            with self.assertRaises(ValueError):
                self.прочитать(ф, ф['сохранить']([ф['wait'], ф['send'], лишнее]))

    def test_отмена_хода_после_приёма_закрывает_допуск(self):
        with фикстура() as ф, self.assertRaisesRegex(ValueError, 'отмен'):
            self.прочитать(ф, ф['сохранить'](входы=[ф['транспорт'],
                {'type': 'event_msg', 'payload': {'type': 'turn_aborted'}}]))

    def test_сообщение_в_остановленном_префиксе_нельзя_погасить_send(self):
        from pathlib import Path
        from фикстура_нативного_приёма import граница, строка
        with фикстура() as ф:
            путь = Path(ф['свидетельство']['остановка']['путь'])
            строки = путь.read_bytes().splitlines(keepends=True)
            путь.write_bytes(строки[0] + строка({'type': 'event_msg',
                'payload': {'type': 'user_message', 'message': 'Стоп'}}) + b''.join(строки[1:]))
            with self.assertRaisesRegex(ValueError, 'пользовательск'):
                self.прочитать(ф, ф['сохранить']())

    def test_первичный_человеческий_ввод_до_и_после_остановки(self):
        from pathlib import Path
        from фикстура_нативного_приёма import строка
        запись = {'type': 'response_item', 'payload': {'type': 'message', 'role': 'user',
            'content': [{'type': 'input_text', 'text': 'Приостанови работу'}]}}
        for до in (True, False):
            with self.subTest(до=до), фикстура() as ф:
                входы = [ф['транспорт']]
                if до:
                    путь = Path(ф['свидетельство']['остановка']['путь'])
                    строки = путь.read_bytes().splitlines(keepends=True)
                    путь.write_bytes(строки[0] + строка(запись) + b''.join(строки[1:]))
                else:
                    входы.append(запись)
                with self.assertRaisesRegex(ValueError, 'пользовательск'):
                    self.прочитать(ф, ф['сохранить'](входы=входы))


if __name__ == '__main__':
    unittest.main()
