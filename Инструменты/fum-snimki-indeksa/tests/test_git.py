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
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        сам.гит('init', '-q', '-b', 'test')
        сам.гит('config', 'user.name', 'Fixture')
        сам.гит('config', 'user.email', 'fixture@example.invalid')
        (сам.корень / 'файл').write_bytes(b'A\n')
        сам.гит('add', 'файл')
        сам.гит('commit', '-qm', 'fixture')
        сам.исходный = сам.гит('rev-parse', 'HEAD').decode().strip()
        сам.объекты = ОбъектыГит(сам.корень)
        сам.коммит = сам.объекты.оид(сам.исходный)

    def гит(сам, *аргументы, вход=None, успешно=True):
        результат = subprocess.run(['git', '-C', str(сам.корень), *аргументы], input=вход, capture_output=True)
        if успешно:
            сам.assertEqual(результат.returncode, 0, результат.stderr)
        return результат.stdout

    def test_индекс_первый_файлы_вторые_позднее_третьи(сам):
        (сам.корень / 'файл').write_bytes(b'B\n')
        дерево = подготовить_дерево(сам.корень, сам.коммит, 'refs/heads/test')
        лист = сам.объекты.дерево(дерево)['файл']
        сам.assertEqual(сам.объекты.прочитать(лист['объект'], 'blob'), b'A\n')
        (сам.корень / 'файл').write_bytes(b'C\n')
        сам.гит('add', 'файл')
        (сам.корень / 'файл').unlink()
        (сам.корень / 'файл').symlink_to('/no-such-file')
        сам.assertEqual(сам.объекты.прочитать(лист['объект'], 'blob'), b'A\n')

    def test_типы_длины_хэши_идентификаторы(сам):
        for объект in [сам.объекты.оид('0' * 40), {'алгоритм': 'sha256', 'значение': 'a' * 64}, {'алгоритм': 'sha1', 'значение': сам.исходный[:10]}, сам.коммит]:
            with сам.subTest(объект=объект), сам.assertRaises(ОшибкаВхода):
                сам.объекты.прочитать(объект, 'blob')
        дерево = сам.объекты.дерево_коммита(сам.коммит)
        ссылка = сам.объекты.ссылка(дерево, 'файл')
        for поле, значение in [('длина', True), ('длина', 20), ('хэш_байтов', '0' * 64), ('путь', 'Файл'), ('лишнее', 1)]:
            плохая = dict(ссылка, **{поле: значение})
            with сам.subTest(поле=поле), сам.assertRaises(ОшибкаВхода):
                сам.объекты.проверить_ссылку(дерево, плохая)

    def test_конфликт_индекса_и_ожидаемые_голова_ветка(сам):
        for коммит, ветка in [(сам.объекты.оид('0' * 40), 'refs/heads/test'), (сам.коммит, 'refs/heads/other')]:
            with сам.assertRaises(ОшибкаВхода):
                подготовить_дерево(сам.корень, коммит, ветка)
        объект_файла = сам.гит('rev-parse', 'HEAD:файл').decode().strip()
        сам.гит('update-index', '--force-remove', 'файл')
        сам.гит('update-index', '--index-info', вход=f'100644 {объект_файла} 1\tфайл\n100644 {объект_файла} 2\tфайл\n'.encode())
        with сам.assertRaises(ОшибкаВхода):
            подготовить_дерево(сам.корень, сам.коммит, 'refs/heads/test')

    def test_замены_объектов_и_фильтр_не_подменяют_байты(сам):
        объект_файла = сам.гит('rev-parse', 'HEAD:файл').decode().strip()
        другой = сам.гит('hash-object', '-w', '--stdin', вход=b'wrong').decode().strip()
        сам.гит('replace', объект_файла, другой)
        сам.гит('config', 'filter.evil.smudge', 'false')
        сам.гит('config', 'filter.evil.clean', 'false')
        (сам.корень / '.gitattributes').write_text('* filter=evil\n')
        сам.assertEqual(сам.объекты.прочитать(сам.объекты.оид(объект_файла), 'blob'), b'A\n')
        сам.assertEqual(сам.объекты.среда['GIT_NO_LAZY_FETCH'], '1')

    def test_отсутствующий_объект_не_берётся_из_рабочих_файлов(сам):
        объект_файла = сам.гит('rev-parse', 'HEAD:файл').decode().strip()
        (сам.корень / '.git/objects' / объект_файла[:2] / объект_файла[2:]).unlink()
        with сам.assertRaises(ОшибкаВхода):
            сам.объекты.прочитать(сам.объекты.оид(объект_файла), 'blob')

    def test_повторное_чтение_закреплённого_объекта_переиспользуется(сам):
        объект = сам.объекты.оид(сам.гит('rev-parse', 'HEAD:файл').decode().strip())
        первое = сам.объекты.прочитать(объект, 'blob')
        сам.assertEqual(сам.объекты.прочитать(объект, 'blob'), первое)
        сам.assertEqual(сам.объекты.чтения, 1)

    def test_недостающий_обещанный_объект_не_догружается(сам):
        объект = сам.гит('rev-parse', 'HEAD:файл').decode().strip()
        удалённый = сам.корень.parent / (сам.корень.name + '-remote')
        subprocess.run(['git', 'clone', '--bare', str(сам.корень), str(удалённый)], check=True, capture_output=True)
        сам.addCleanup(__import__('shutil').rmtree, удалённый)
        отметка = сам.корень / 'fetch-was-invoked'
        помощник = сам.корень / 'upload-pack'
        помощник.write_text('#!/bin/sh\ntouch "' + str(отметка) + '"\nexec git-upload-pack "$@"\n')
        помощник.chmod(0o755)
        сам.гит('config', 'remote.origin.url', str(удалённый))
        сам.гит('config', 'remote.origin.promisor', 'true')
        сам.гит('config', 'remote.origin.uploadpack', str(помощник))
        сам.гит('config', 'extensions.partialClone', 'origin')
        (сам.корень / '.git/objects' / объект[:2] / объект[2:]).unlink()
        with сам.assertRaises(ОшибкаВхода): сам.объекты.прочитать(сам.объекты.оид(объект), 'blob')
        сам.assertFalse(отметка.exists())
        сам.assertFalse((сам.корень / '.git/objects' / объект[:2] / объект[2:]).exists())
        сам.assertEqual(сам.гит('cat-file', 'blob', объект), b'A\n')
        сам.assertTrue(отметка.exists(), 'фикстура действительно должна запускать lazy fetch обычным Git')

    def test_симлинк_подмодуль_и_коллизия_в_дереве(сам):
        объект_файла = сам.гит('rev-parse', 'HEAD:файл').decode().strip()
        for режим, тип, значение, имя in [('120000', 'blob', объект_файла, 'ссылка'), ('100644', 'blob', объект_файла, 'Файл')]:
            данные = f'100644 blob {объект_файла}\tфайл\n{режим} {тип} {значение}\t{имя}\n'.encode()
            дерево = сам.гит('mktree', вход=данные).decode().strip()
            with сам.assertRaises(ОшибкаВхода):
                сам.объекты.дерево(сам.объекты.оид(дерево))
        дерево = сам.гит('mktree', вход=f'160000 commit {сам.исходный}\tзависимость\n'.encode()).decode().strip()
        лист = сам.объекты.дерево(сам.объекты.оид(дерево))['зависимость']
        сам.assertEqual(лист['режим'], '160000')
        with сам.assertRaises(ОшибкаВхода):
            сам.объекты.ссылка(сам.объекты.оид(дерево), 'зависимость')


if __name__ == '__main__':
    unittest.main()
