from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

КАТАЛОГ_СКРИПТОВ = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(КАТАЛОГ_СКРИПТОВ))

import обновить_состав_карточки as состав


class ОбновлениеСоставаКарточки(unittest.TestCase):
    def setUp(self):
        self.временная = tempfile.TemporaryDirectory()
        self.основание = Path(self.временная.name).resolve()
        self.корень = self.основание / 'репозиторий'
        self.корень.mkdir()
        self.сессия = self.корень / 'Журнал/2026-09-30_10-00-00_MSK_обновить-состав'
        (self.сессия / 'материалы').mkdir(parents=True)
        self.путь_запроса = 'Журнал/2026-09-30_10-00-00_MSK_обновить-состав/запрос.md'
        self.путь_отчёта = 'Журнал/2026-09-30_10-00-00_MSK_обновить-состав/отчёт.md'
        self.запрос = self.корень / self.путь_запроса
        self.отчёт = self.корень / self.путь_отчёта
        self.цель = self.корень / 'Инструменты/пример.py'
        self.цель.parent.mkdir(parents=True)
        self.цель.write_text('исходное\n', encoding='utf-8')
        self.отчёт.write_text('# Отчёт\nнеизменяемый отчёт\n', encoding='utf-8')
        self.запрос.write_text(
            '# Исходный запрос\n'
            '## Текст запроса\nДословное сообщение\n'
            '## Повлиял на файлы\n'
            '<!-- FUM-КАРТОЧКА:НАЧАЛО состав -->\n'
            '- [устаревший путь](несуществующий.md)\n'
            '<!-- FUM-КАРТОЧКА:КОНЕЦ состав -->\n',
            encoding='utf-8',
        )
        self._git('init', '-q', '-b', 'main')
        self._git('config', 'user.name', 'Тест')
        self._git('config', 'user.email', 'test@example.invalid')
        self._git('add', '.')
        self._git('commit', '-qm', 'основание')
        self.цель.write_text('изменённая цель\n', encoding='utf-8')
        self.путь_разрешения = self.основание / 'разрешение.json'
        self.вход = {
            'схема': 'fum.разрешение-состава-карточки.1',
            'задача': '00000000-0000-0000-0000-000000000001',
            'запрос': self.путь_запроса,
            'корень': str(self.корень),
            'ветка': 'refs/heads/main',
            'исходный_коммит': self._git('rev-parse', 'HEAD').decode().strip(),
            'разрешённые_цели': sorted([
                self.путь_запроса,
                self.путь_отчёта,
                'Инструменты/пример.py',
            ]),
            'ожидаемые_цели': [],
        }
        self.путь_разрешения.write_bytes(
            json.dumps(self.вход, ensure_ascii=False, sort_keys=True).encode() + b'\n'
        )
        os.chmod(self.путь_разрешения, 0o600)

    def tearDown(self):
        self.временная.cleanup()

    def _git(self, *args):
        return subprocess.run(
            ['git', '-C', str(self.корень), *args],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout

    def test_план_строит_точный_состав_и_ничего_не_пишет(self):
        до = self.запрос.read_bytes()
        план = состав.подготовить(self.корень, self.путь_запроса, self.путь_разрешения)

        self.assertEqual(до, self.запрос.read_bytes())
        self.assertTrue(план['изменить'])
        self.assertEqual(set(self.вход['разрешённые_цели']), set(план['цели']))
        self.assertEqual([], план['ожидаемые_цели'])
        self.assertIn('Инструменты/пример.py', план['новые_ссылки'])
        self.assertEqual(
            [self.путь_запроса.rsplit('/', 1)[0] + '/несуществующий.md'],
            план['удалённые_ссылки'],
        )
        self.assertEqual(
            hashlib.sha256(до).hexdigest(),
            план['запрос_sha256_до'],
        )

    def test_применение_меняет_только_блок_состава(self):
        исходные = self.запрос.read_bytes()
        план = состав.подготовить(self.корень, self.путь_запроса, self.путь_разрешения)
        путь_плана = self.основание / 'план.json'
        хэш_плана = состав.сохранить_план(путь_плана, план, self.корень)
        результат = состав.применить(
            self.корень, self.путь_запроса, self.путь_разрешения,
            путь_плана, хэш_плана,
        )
        новое = self.запрос.read_bytes()

        self.assertTrue(результат['применено'])
        self.assertIn('[Инструменты/пример.py]'.encode(), новое)
        self.assertNotIn('несуществующий.md'.encode(), новое)
        self.assertIn('## Текст запроса\nДословное сообщение\n'.encode(), новое)
        начало_маркер = '<!-- FUM-КАРТОЧКА:НАЧАЛО состав -->'.encode()
        конец_маркер = '<!-- FUM-КАРТОЧКА:КОНЕЦ состав -->'.encode()
        начало_до = исходные.index(начало_маркер)
        конец_до = исходные.index(конец_маркер)
        начало_после = новое.index(начало_маркер)
        конец_после = новое.index(конец_маркер)
        self.assertEqual(
            исходные[:начало_до], новое[:начало_после]
        )
        self.assertEqual(
            исходные[конец_до + len(конец_маркер):],
            новое[конец_после + len(конец_маркер):],
        )

    def test_вход_выбранных_команд_сохраняет_точный_состав(self):
        self.вход['схема'] = 'fum.создание-коммита.5'
        self.вход.pop('ожидаемые_цели')
        self.путь_разрешения.write_bytes(
            json.dumps(self.вход, ensure_ascii=False, sort_keys=True).encode() + b'\n'
        )
        self.test_применение_меняет_только_блок_состава()

    def test_изменение_git_состояния_после_плана_закрывает_применение(self):
        план = состав.подготовить(self.корень, self.путь_запроса, self.путь_разрешения)
        путь_плана = self.основание / 'план.json'
        хэш_плана = состав.сохранить_план(путь_плана, план, self.корень)
        (self.корень / 'посторонний.txt').write_text('изменение\n', encoding='utf-8')
        до = self.запрос.read_bytes()

        with self.assertRaises(ValueError):
            состав.применить(
                self.корень, self.путь_запроса, self.путь_разрешения,
                путь_плана, хэш_плана,
            )
        self.assertEqual(до, self.запрос.read_bytes())

    def test_переименование_вне_разрешённого_состава_отклоняется(self):
        self._git('mv', 'Инструменты/пример.py', 'Инструменты/пример новый.py')
        self.цель.write_text('повторно созданный путь\n', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'вне разрешённого состава'):
            состав.подготовить(self.корень, self.путь_запроса, self.путь_разрешения)

    def test_porcelain_v2_отклоняет_неразрешённый_конфликт(self):
        статус = (
            b'# branch.oid ' + b'0' * 40 + b'\0'
            b'# branch.head main\0'
            b'u UU N... 100644 100644 100644 100644 '
            b'0000000000000000000000000000000000000000 '
            b'0000000000000000000000000000000000000000 ' + 'конфликт.txt'.encode() + b'\0'
        )
        with self.assertRaisesRegex(ValueError, 'конфликт'):
            состав._разобрать_статус_v2(статус)

    def test_изменённое_разрешение_отвергается(self):
        self.вход['разрешённые_цели'].remove('Инструменты/пример.py')
        self.путь_разрешения.write_text(
            json.dumps(self.вход, ensure_ascii=False), encoding='utf-8'
        )
        with self.assertRaises(ValueError):
            состав.подготовить(self.корень, self.путь_запроса, self.путь_разрешения)

    def test_повторное_применение_старого_плана_не_идемпотентно_через_изменённый_снимок(self):
        план = состав.подготовить(self.корень, self.путь_запроса, self.путь_разрешения)
        путь_плана = self.основание / 'план.json'
        хэш_плана = состав.сохранить_план(путь_плана, план, self.корень)
        состав.применить(
            self.корень, self.путь_запроса, self.путь_разрешения,
            путь_плана, хэш_плана,
        )
        после_первого = self.запрос.read_bytes()
        with self.assertRaises(ValueError):
            состав.применить(
                self.корень, self.путь_запроса, self.путь_разрешения,
                путь_плана, хэш_плана,
            )
        self.assertEqual(после_первого, self.запрос.read_bytes())


if __name__ == '__main__':
    unittest.main()
