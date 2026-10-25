"""Публикуемое происхождение не раскрывает текст и служебную оболочку ответа."""
import hashlib
import importlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

СКРИПТЫ = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(СКРИПТЫ))
from видимые_ответы import извлечь

ЗАДАЧА = '00000000-0000-4000-8000-000000000001'


class ПроверкаСвидетельства(unittest.TestCase):
    def setUp(сам):
        сам.модуль = importlib.import_module('свидетельство_видимых_ответов')

    def выгрузка(сам, неопределённый=False):
        записи = [{'type': 'session_meta', 'payload': {'id': ЗАДАЧА}}]
        for _ in range(2):
            записи.append({'type': 'response_item', 'payload': {
                'type': 'message', 'role': 'assistant', 'phase': 'commentary',
                'id': 'PRIVATE_ID', 'turn_id': 'PRIVATE_TURN',
                'content': [{'type': 'output_text', 'text': '/private/PRIVATE_PATH ё🙂'}]}})
        if неопределённый:
            записи.append({'type': 'response_item', 'payload': {
                'type': 'message', 'role': 'assistant', 'phase': 'unknown_PRIVATE',
                'content': [{'type': 'output_text', 'text': 'PRIVATE_UNKNOWN'}]}})
        native = b''.join((json.dumps(з, ensure_ascii=False) + '\n').encode() for з in записи)
        return (json.dumps(извлечь(native, ЗАДАЧА), ensure_ascii=False, indent=2) + '\n').encode()

    def test_происхождение_и_повторы_без_приватного_содержимого(сам):
        сырые = сам.выгрузка(); исходный = json.loads(сырые)
        итог = сам.модуль.свидетельство(сырые, ЗАДАЧА)
        сам.assertNotIn('PRIVATE', json.dumps(итог, ensure_ascii=False))
        сам.assertFalse(итог['содержимое_включено'])
        сам.assertEqual(итог['выгрузка'], {'байтов': len(сырые), 'sha256': hashlib.sha256(сырые).hexdigest()})
        сам.assertEqual(итог['источник'], исходный['источник'])
        сам.assertEqual([о['исходник'] for о in итог['ответы']], [о['исходник'] for о in исходный['ответы']])
        сам.assertEqual(len(итог['ответы']), 2)

    def test_неполнота_сохраняется_без_содержимого_неопределённости(сам):
        итог = сам.модуль.свидетельство(сам.выгрузка(True), ЗАДАЧА)
        сам.assertEqual(итог['состояние'], 'неполно')
        сам.assertFalse(итог['полнота_поддержанных_ответов'])
        сам.assertEqual(len(итог['неопределённости']), 1)
        сам.assertNotIn('PRIVATE', json.dumps(итог))

    def test_повреждённый_оригинал_и_чужая_задача_отклоняются(сам):
        данные = json.loads(сам.выгрузка())
        данные['ответы'][0]['сырая_строка'] += ' '
        with сам.assertRaises(ValueError):
            сам.модуль.свидетельство(json.dumps(данные).encode(), ЗАДАЧА)
        with сам.assertRaises(ValueError):
            сам.модуль.свидетельство(сам.выгрузка(), '00000000-0000-4000-8000-000000000002')

    def test_неизвестные_поля_и_неверные_безопасные_значения_отклоняются(сам):
        for поле, значение in [('лишнее', 'PRIVATE'), ('sha256', 'PRIVATE'), ('граница', True)]:
            with сам.subTest(поле=поле):
                данные = json.loads(сам.выгрузка()); данные['источник'][поле] = значение
                with сам.assertRaises(ValueError):
                    сам.модуль.свидетельство(json.dumps(данные).encode(), ЗАДАЧА)

    def test_cli_читает_сохранённый_оригинал_без_мутации(сам):
        with tempfile.TemporaryDirectory() as каталог:
            путь = Path(каталог).resolve() / 'private.json'
            for неполно, код in ((False, 0), (True, 3)):
                сырые = сам.выгрузка(неполно); путь.write_bytes(сырые)
                процесс = subprocess.run([sys.executable, '-B', str(СКРИПТЫ / 'свидетельство-видимых-ответов.py'),
                    '--выгрузка', str(путь), '--задача', ЗАДАЧА], capture_output=True)
                сам.assertEqual(процесс.returncode, код, процесс.stderr.decode())
                сам.assertNotIn(b'PRIVATE', процесс.stdout)
                сам.assertEqual(путь.read_bytes(), сырые)


if __name__ == '__main__':
    unittest.main()
