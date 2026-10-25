"""Проверка точного кандидата с внешним результатом и читающим повтором."""
import hashlib
import importlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
проверка = importlib.import_module('проверка_кандидата_обратного_приёма')


class ПроверкаКандидата(unittest.TestCase):
    def setUp(self):
        временный = tempfile.TemporaryDirectory()
        self.addCleanup(временный.cleanup)
        self.каталог = Path(временный.name).resolve()
        self.корень = self.каталог / 'кандидат'
        self.корень.mkdir()
        среда = {к: з for к, з in os.environ.items() if not к.startswith('GIT_')}
        среда.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull)
        self.среда = patch.dict(os.environ, среда, clear=True)
        self.среда.start()
        self.addCleanup(self.среда.stop)
        self.гит('init', '--initial-branch=codex/kandidat')
        self.гит('config', 'user.name', 'Испытатель')
        self.гит('config', 'user.email', 'test@example.invalid')
        (self.корень / 'данные.txt').write_text('проверяемые данные\n')
        self.гит('add', '--', 'данные.txt')
        self.гит('commit', '-m', 'Кандидат')
        self.вход = {
            'корень': str(self.корень),
            'кандидат': {'ветка': 'refs/heads/codex/kandidat',
                'коммит': self.гит('rev-parse', 'HEAD').strip(),
                'дерево': self.гит('rev-parse', 'HEAD^{tree}').strip()},
            'команда': [sys.executable, '-I', '-B', '-c',
                "from pathlib import Path; assert Path('данные.txt').read_text() == 'проверяемые данные\\n'; print('OK')"],
            'задача': '11111111-1111-4111-8111-111111111111',
            'тайм_аут': 10, 'предел_байтов': 1048576,
        }
        self.выход = self.каталог / 'результат'

    def гит(self, *аргументы):
        return subprocess.check_output(['git', '-C', str(self.корень), *аргументы],
                                       stderr=subprocess.PIPE).decode()

    def запустить(self):
        return проверка.запустить(**self.вход, каталог=self.выход)

    def прочитать(self, результат):
        return проверка.прочитать(self.выход, результат['sha256'], self.вход)

    def сохранить_подмену(self, результат):
        сырые = проверка.захват.закодировать(результат['результат'])
        (self.выход / 'результат.json').write_bytes(сырые)
        результат['sha256'] = hashlib.sha256(сырые).hexdigest()

    def test_пользовательский_исполняемый_бит_обязателен(self):
        путь = self.корень / 'данные.txt'
        путь.chmod(0o755)
        self.гит('add', '--', 'данные.txt')
        self.гит('commit', '-m', 'Исполняемый файл')
        self.вход['кандидат'].update(коммит=self.гит('rev-parse', 'HEAD').strip(),
                                    дерево=self.гит('rev-parse', 'HEAD^{tree}').strip())
        self.гит('config', 'core.filemode', 'false')
        путь.chmod(0o641)
        with self.assertRaises(ValueError):
            self.запустить()
        self.assertFalse(self.выход.exists())

    def test_неполное_наблюдение_не_подтверждается_новым_sha(self):
        результат = self.запустить()
        for сторона in ('до', 'после'):
            del результат['результат'][сторона]['индекс_sha256']
            del результат['результат'][сторона]['зависимости']
        (self.выход / 'до.json').write_bytes(проверка.захват.закодировать(результат['результат']['до']))
        self.сохранить_подмену(результат)
        with self.assertRaises(ValueError):
            self.прочитать(результат)

    def test_лимит_каналов_проверяется_до_их_чтения(self):
        self.вход['предел_байтов'] = 16
        результат = self.запустить()
        путь = self.выход / 'процесс/манифест.json'
        манифест = json.loads(путь.read_bytes())
        манифест['каналы']['stdout']['байты'] = 17
        манифест['всего_произведено_байтов'] = 17
        сырые = проверка.захват.закодировать(манифест)
        путь.write_bytes(сырые)
        результат['результат']['процесс_sha256'] = hashlib.sha256(сырые).hexdigest()
        self.сохранить_подмену(результат)
        with patch.object(проверка.захват, 'прочитать_диапазон',
                          side_effect=AssertionError('Каналы не должны читаться')), self.assertRaises(ValueError):
            self.прочитать(результат)

    def test_успех_сохраняется_вне_кандидата_повтор_не_запускает_проверку(self):
        деревья = self.гит('worktree', 'list', '--porcelain')
        индекс = (self.корень / '.git/index').read_bytes()
        результат = self.запустить()
        self.assertTrue(результат['результат']['пригоден'])
        self.assertFalse(результат['результат']['разрешение_записи'])
        self.assertEqual(индекс, (self.корень / '.git/index').read_bytes())
        self.assertEqual('', self.гит('status', '--porcelain'))
        self.assertEqual(деревья, self.гит('worktree', 'list', '--porcelain'))
        снимок = {p.relative_to(self.выход): (p.read_bytes(), p.stat().st_mtime_ns)
                  for p in self.выход.rglob('*') if p.is_file()}
        self.гит('commit', '--allow-empty', '-m', 'После приёма')
        with patch('subprocess.Popen', side_effect=AssertionError('Повтор не запускает процесс')):
            self.assertEqual(результат['результат'], self.прочитать(результат))
        self.assertEqual(снимок, {p.relative_to(self.выход): (p.read_bytes(), p.stat().st_mtime_ns)
                         for p in self.выход.rglob('*') if p.is_file()})

    def test_чужой_коммит_или_дерево_отказывает_до_процесса(self):
        for поле in ('коммит', 'дерево'):
            исходное = self.вход['кандидат'][поле]
            self.вход['кандидат'][поле] = '0' * 40
            with self.subTest(поле=поле), self.assertRaises(ValueError):
                self.запустить()
            self.assertFalse(self.выход.exists())
            self.вход['кандидат'][поле] = исходное

    def test_скрывающий_флаг_не_разрешает_проверку(self):
        self.гит('update-index', '--assume-unchanged', '--', 'данные.txt')
        (self.корень / 'данные.txt').write_text('подмена\n')
        with self.assertRaises(ValueError):
            self.запустить()
        self.assertFalse(self.выход.exists())

    def test_изменение_кандидата_процессом_сохраняет_отказ(self):
        self.вход['команда'][-1] = "from pathlib import Path; Path('данные.txt').write_text('изменено')"
        результат = self.запустить()
        self.assertFalse(результат['результат']['пригоден'])
        self.assertTrue((self.выход / 'процесс/манифест.json').is_file())
        with self.assertRaises(ValueError):
            self.прочитать(результат)

    def test_ненулевой_код_не_становится_успехом(self):
        self.вход['команда'][-1] = 'raise SystemExit(7)'
        результат = self.запустить()
        self.assertFalse(результат['результат']['пригоден'])
        with self.assertRaises(ValueError):
            self.прочитать(результат)

    def test_тайм_аут_сохраняется_без_автоповтора(self):
        self.вход['тайм_аут'] = 0.1
        self.вход['команда'][-1] = 'import time; time.sleep(10)'
        результат = self.запустить()
        self.assertFalse(результат['результат']['пригоден'])
        with self.assertRaises(ValueError):
            self.запустить()

    def test_подмена_канала_отклоняется_при_чтении(self):
        результат = self.запустить()
        (self.выход / 'процесс/stdout.bin').write_bytes(b'NO\n')
        with self.assertRaises(ValueError):
            self.прочитать(результат)

    def test_нельзя_положить_результат_в_рабочее_дерево_или_bare(self):
        for выход in (self.корень / 'сырой', self.каталог / 'bare/сырой'):
            if выход.parent.name == 'bare':
                subprocess.run(['git', 'init', '--bare', str(выход.parent)],
                               check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                выход.parent.chmod(0o700)
            self.выход = выход
            with self.assertRaises(ValueError):
                self.запустить()
            self.assertFalse(выход.exists())

    def test_неинициализированная_зависимость_отказывает_до_процесса(self):
        self.гит('update-index', '--add', '--cacheinfo', '160000',
                 self.вход['кандидат']['коммит'], 'зависимость')
        self.гит('commit', '-m', 'Gitlink')
        self.вход['кандидат']['коммит'] = self.гит('rev-parse', 'HEAD').strip()
        self.вход['кандидат']['дерево'] = self.гит('rev-parse', 'HEAD^{tree}').strip()
        with self.assertRaises(ValueError):
            self.запустить()
        self.assertFalse(self.выход.exists())

    def test_инициализированная_зависимость_проверяется_рекурсивно(self):
        self.гит('-c', 'protocol.file.allow=always', 'submodule', 'add',
                 str(self.корень), 'зависимость')
        self.гит('commit', '-am', 'Инициализированная зависимость')
        self.вход['кандидат'].update(коммит=self.гит('rev-parse', 'HEAD').strip(),
                                    дерево=self.гит('rev-parse', 'HEAD^{tree}').strip())
        результат = self.запустить()
        self.assertTrue(self.прочитать(результат)['пригоден'])
        self.assertEqual('зависимость', результат['результат']['до']['зависимости'][0]['путь'])
        исходный = json.loads(json.dumps(результат))
        for поле, подмена in (('индекс_sha256', False), ('корень', str(self.корень)),
                              ('коммит', '0'), ('зависимости', {})):
            результат = json.loads(json.dumps(исходный))
            for сторона in ('до', 'после'):
                результат['результат'][сторона]['зависимости'][0]['состояние'][поле] = подмена
            (self.выход / 'до.json').write_bytes(проверка.захват.закодировать(результат['результат']['до']))
            self.сохранить_подмену(результат)
            with self.subTest(поле=поле), self.assertRaises(ValueError):
                self.прочитать(результат)
        (self.корень / 'зависимость/данные.txt').write_text('дрейф зависимости\n')
        self.выход = self.каталог / 'после-дрейфа'
        with self.assertRaises(ValueError):
            self.запустить()
        self.assertFalse(self.выход.exists())

    def test_изменение_входа_и_sha_не_принимаются(self):
        результат = self.запустить()
        with self.assertRaises(ValueError):
            проверка.прочитать(self.выход, '0' * 64, self.вход)
        другой = dict(self.вход, команда=['false'])
        with self.assertRaises(ValueError):
            проверка.прочитать(self.выход, результат['sha256'], другой)


if __name__ == '__main__':
    unittest.main()
