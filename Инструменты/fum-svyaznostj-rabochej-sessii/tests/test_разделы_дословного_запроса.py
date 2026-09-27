"""Границы раздела не должны разрезать первичный текст человека."""
import unittest

from test_check_session_coherence import check_session_coherence as проверка


class РазделыДословногоЗапроса(unittest.TestCase):
    def test_заголовок_внутри_оригинала_сохраняется_дословно(self):
        тело = '\n\n````text\n## Na Studio Display XDR\nё🙂\n````\n\n'
        текст = '## Текст запроса' + тело + '## Проверки\nготово\n'
        self.assertEqual(проверка.section_body(текст, 'Текст запроса'), тело)

    def test_ложный_раздел_до_настоящего_не_выбирается(self):
        текст = '~~~text\n## Текст запроса\nложь\n~~~\n## Текст запроса\nистина\n'
        self.assertEqual(проверка.section_body(текст, 'Текст запроса'), '\nистина\n')

    def test_короткая_ограда_не_завершает_длинную(self):
        тело = '\n````text\n```\n## Проверки\n````\n'
        self.assertEqual(проверка.section_body('## Текст запроса' + тело + '## Конец\n', 'Текст запроса'), тело)

    def test_незакрытая_ограда_сохраняет_остаток(self):
        тело = '\n```text\n## Проверки\n'
        self.assertEqual(проверка.section_body('## Текст запроса' + тело, 'Текст запроса'), тело)

    def test_комментарий_и_crlf_не_сдвигают_исходные_позиции(self):
        текст = '<!--\r\n## Текст запроса\r\n-->\r\n## Текст запроса\r\nё\r\n## Конец\r\n'
        self.assertEqual(проверка.section_body(текст, 'Текст запроса'), '\r\nё\r\n')

    def test_раздел_только_в_ограде_отсутствует(self):
        self.assertIsNone(проверка.section_body('```\n## Текст запроса\n```\n', 'Текст запроса'))


if __name__ == '__main__':
    unittest.main()
