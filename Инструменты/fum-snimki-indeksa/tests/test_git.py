import hashlib
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from канон import ОшибкаВхода
from объекты import ОбъектыГит, подготовить_дерево


class СыройГит(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.гит('init', '-q', '-b', 'test')
        self.гит('config', 'user.name', 'Fixture')
        self.гит('config', 'user.email', 'fixture@example.invalid')
        (self.корень / 'файл').write_bytes(b'A\n')
        self.гит('add', 'файл')
        self.гит('commit', '-qm', 'fixture')
        self.исходный = self.гит('rev-parse', 'HEAD').decode().strip()
        self.объекты = ОбъектыГит(self.корень)
        self.коммит = self.объекты.оид(self.исходный)

    def гит(self, *аргументы, вход=None, успешно=True):
        результат = subprocess.run(['git', '-C', str(self.корень), *аргументы], input=вход, capture_output=True)
        if успешно:
            self.assertEqual(результат.returncode, 0, результат.stderr)
        return результат.stdout

    def test_индекс_первый_файлы_вторые_позднее_третьи(self):
        (self.корень / 'файл').write_bytes(b'B\n')
        дерево = подготовить_дерево(self.корень, self.коммит, 'refs/heads/test')
        лист = self.объекты.дерево(дерево)['файл']
        self.assertEqual(self.объекты.прочитать(лист['объект'], 'blob'), b'A\n')
        (self.корень / 'файл').write_bytes(b'C\n')
        self.гит('add', 'файл')
        (self.корень / 'файл').unlink()
        (self.корень / 'файл').symlink_to('/no-such-file')
        self.assertEqual(self.объекты.прочитать(лист['объект'], 'blob'), b'A\n')

    def test_типы_длины_хэши_oid(self):
        for объект in [self.объекты.оид('0' * 40), {'алгоритм': 'sha256', 'значение': 'a' * 64}, {'алгоритм': 'sha1', 'значение': self.исходный[:10]}, self.коммит]:
            with self.subTest(объект=объект), self.assertRaises(ОшибкаВхода):
                self.объекты.прочитать(объект, 'blob')
        дерево = self.объекты.дерево_коммита(self.коммит)
        ссылка = self.объекты.ссылка(дерево, 'файл')
        for поле, значение in [('длина', True), ('длина', 20), ('хэш_байтов', '0' * 64), ('путь', 'Файл'), ('лишнее', 1)]:
            плохая = dict(ссылка, **{поле: значение})
            with self.subTest(поле=поле), self.assertRaises(ОшибкаВхода):
                self.объекты.проверить_ссылку(дерево, плохая)

    def test_конфликт_индекса_и_ожидаемые_голова_ветка(self):
        for коммит, ветка in [(self.объекты.оид('0' * 40), 'refs/heads/test'), (self.коммит, 'refs/heads/other')]:
            with self.assertRaises(ОшибкаВхода):
                подготовить_дерево(self.корень, коммит, ветка)
        объект_файла = self.гит('rev-parse', 'HEAD:файл').decode().strip()
        self.гит('update-index', '--force-remove', 'файл')
        self.гит('update-index', '--index-info', вход=f'100644 {объект_файла} 1\tфайл\n100644 {объект_файла} 2\tфайл\n'.encode())
        with self.assertRaises(ОшибкаВхода):
            подготовить_дерево(self.корень, self.коммит, 'refs/heads/test')

    def test_replace_и_фильтр_не_подменяют_байты(self):
        объект_файла = self.гит('rev-parse', 'HEAD:файл').decode().strip()
        другой = self.гит('hash-object', '-w', '--stdin', вход=b'wrong').decode().strip()
        self.гит('replace', объект_файла, другой)
        self.гит('config', 'filter.evil.smudge', 'false')
        self.гит('config', 'filter.evil.clean', 'false')
        (self.корень / '.gitattributes').write_text('* filter=evil\n')
        self.assertEqual(self.объекты.прочитать(self.объекты.оид(объект_файла), 'blob'), b'A\n')
        self.assertEqual(self.объекты.среда['GIT_NO_LAZY_FETCH'], '1')

    def test_отсутствующий_blob_не_берётся_из_checkout(self):
        объект_файла = self.гит('rev-parse', 'HEAD:файл').decode().strip()
        (self.корень / '.git/objects' / объект_файла[:2] / объект_файла[2:]).unlink()
        with self.assertRaises(ОшибкаВхода):
            self.объекты.прочитать(self.объекты.оид(объект_файла), 'blob')

    def test_повторное_чтение_закреплённого_объекта_переиспользуется(self):
        объект = self.объекты.оид(self.гит('rev-parse', 'HEAD:файл').decode().strip())
        первое = self.объекты.прочитать(объект, 'blob')
        self.assertEqual(self.объекты.прочитать(объект, 'blob'), первое)
        self.assertEqual(self.объекты.чтения, 1)

    def test_missing_promisor_не_догружается(self):
        объект = self.гит('rev-parse', 'HEAD:файл').decode().strip()
        удалённый = self.корень.parent / (self.корень.name + '-remote')
        subprocess.run(['git', 'clone', '--bare', str(self.корень), str(удалённый)], check=True, capture_output=True)
        self.addCleanup(__import__('shutil').rmtree, удалённый)
        отметка = self.корень / 'fetch-was-invoked'
        помощник = self.корень / 'upload-pack'
        помощник.write_text('#!/bin/sh\ntouch "' + str(отметка) + '"\nexec git-upload-pack "$@"\n')
        помощник.chmod(0o755)
        self.гит('config', 'remote.origin.url', str(удалённый))
        self.гит('config', 'remote.origin.promisor', 'true')
        self.гит('config', 'remote.origin.uploadpack', str(помощник))
        self.гит('config', 'extensions.partialClone', 'origin')
        (self.корень / '.git/objects' / объект[:2] / объект[2:]).unlink()
        with self.assertRaises(ОшибкаВхода): self.объекты.прочитать(self.объекты.оид(объект), 'blob')
        self.assertFalse(отметка.exists())
        self.assertFalse((self.корень / '.git/objects' / объект[:2] / объект[2:]).exists())
        self.assertEqual(self.гит('cat-file', 'blob', объект), b'A\n')
        self.assertTrue(отметка.exists(), 'фикстура действительно должна запускать lazy fetch обычным Git')

    def test_симлинк_gitlink_и_коллизия_в_дереве(self):
        объект_файла = self.гит('rev-parse', 'HEAD:файл').decode().strip()
        for режим, тип, значение, имя in [('120000', 'blob', объект_файла, 'ссылка'), ('100644', 'blob', объект_файла, 'Файл')]:
            данные = f'100644 blob {объект_файла}\tфайл\n{режим} {тип} {значение}\t{имя}\n'.encode()
            дерево = self.гит('mktree', вход=данные).decode().strip()
            with self.assertRaises(ОшибкаВхода):
                self.объекты.дерево(self.объекты.оид(дерево))
        дерево = self.гит('mktree', вход=f'160000 commit {self.исходный}\tзависимость\n'.encode()).decode().strip()
        лист = self.объекты.дерево(self.объекты.оид(дерево))['зависимость']
        self.assertEqual(лист['режим'], '160000')
        with self.assertRaises(ОшибкаВхода):
            self.объекты.ссылка(self.объекты.оид(дерево), 'зависимость')


if __name__ == '__main__':
    unittest.main()
