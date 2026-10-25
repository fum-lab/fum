"""Нативный журнал внутри Git не должен попадать в приватные адреса v3."""
import importlib
import json
from pathlib import Path
import subprocess
import unittest

from фикстура_дочернего_коммита import фикстура


class ПроверкаПриватногоВхода(unittest.TestCase):
    def test_холодные_фазы_создают_коммит_и_восстанавливают_его_после_позднего_ввода(self):
        from сценарий_холодной_передачи import выполнить
        результат = выполнить(приватный=True)
        self.assertEqual(0, результат['код'], результат['ошибка'])
        self.assertTrue(результат['повтор_совпал'])

    def test_собирает_вход_из_назначения_и_сверяет_поздний_ввод(self):
        вход = importlib.import_module('приватный_вход_передачи')
        with фикстура() as (корень, источник, параметры):
            каталог_git = корень.parent / 'native-git'
            subprocess.run(['git', 'init', '-q', str(каталог_git)], check=True)
            живой = каталог_git / 'native.jsonl'
            живой.write_bytes(источник.read_bytes())
            каталог = корень.parent / 'приватная-передача'
            поля = {к: параметры[к] for к in ('имя_автора', 'заголовок', 'описание', 'разрешённые_цели')}
            созданный = вход.создать_вход(корень, живой, каталог, поля)
            self.assertEqual(параметры['назначение_sha256'], созданный['назначение_sha256'])
            снимок = Path(созданный['источник_модели'])
            self.assertEqual(живой.read_bytes(), снимок.read_bytes())
            self.assertFalse(снимок.is_relative_to(каталог_git))
            inode = снимок.stat().st_ino
            self.assertEqual(созданный, вход.создать_вход(корень, живой, каталог, поля))
            self.assertEqual(inode, снимок.stat().st_ino)
            with живой.open('ab') as поток:
                поток.write(json.dumps({'type': 'response_item', 'payload': {
                    'type': 'message', 'role': 'assistant', 'content': [
                        {'type': 'output_text', 'text': 'Проверяю подготовку.'}]}}).encode() + b'\n')
            self.assertEqual(созданный, вход.прочитать(каталог))
            with живой.open('ab') as поток:
                поток.write(json.dumps({'type': 'response_item', 'payload': {
                    'type': 'message', 'role': 'user', 'content': [
                        {'type': 'input_text', 'text': 'Остановись.'}]}}).encode() + b'\n')
            with self.assertRaisesRegex(ValueError, 'новое управляющее'):
                вход.прочитать(каталог)
            self.assertEqual(inode, снимок.stat().st_ino)


if __name__ == '__main__':
    unittest.main()
