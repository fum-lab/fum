"""Подготовленная зависимость допускает первую v4-проверку нового писателя."""
from pathlib import Path
import importlib
import sys
import unittest
from unittest import mock

from фикстура_дочернего_коммита import фикстура, коммит, НОМЕР
import test_дочернего_коммита as передача

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'fum-proverka-git-zavisimostej/tests'))
from test_proveritj_git_zavisimostj import GitDependencyFixture, run_git, proveritj_git_zavisimostj as зависимость


ПУТЬ = 'Зависимости/Primer'


def подготовить_клон(корень):
    место = корень.parent / 'внешние-фикстуры'
    место.mkdir()
    исходники = GitDependencyFixture(место)
    run_git('remote', 'add', 'origin', str(исходники.fum_origin), cwd=корень)
    ошибки = зависимость.materialize_dependency(корень, исходники.dependency_spec())
    if ошибки:
        raise AssertionError(ошибки)
    run_git('commit', '-qm', 'Зарегистрировать зависимость', cwd=корень)
    оригинал = корень.with_name('первоначальный-репозиторий')
    корень.rename(оригинал)
    run_git('clone', '-q', str(оригинал), str(корень))
    run_git('remote', 'set-url', 'origin', str(исходники.fum_origin), cwd=корень)
    run_git('config', 'user.name', 'Открытая фикстура', cwd=корень)
    run_git('config', 'user.email', 'fixture@example.invalid', cwd=корень)


def подготовить_дерево(корень, задача, источник):
    общий = Path(run_git('rev-parse', '--git-common-dir', cwd=корень))
    конфигурация = общий / 'config'
    до = конфигурация.read_bytes()
    assert (корень / ПУТЬ).is_dir() and not list((корень / ПУТЬ).iterdir())
    окружение = importlib.import_module('окружение_слоя')
    синхронизированы = []
    синхронизировать = окружение.хранение.синхронизировать_каталог
    инициализировать = окружение.зависимости.initialize_registered_dependency
    собственный = Path(run_git('rev-parse', '--absolute-git-dir', cwd=корень))
    def sync(путь):
        синхронизированы.append(путь)
        return синхронизировать(путь)
    def init(*а):
        assert собственный in синхронизированы, 'Родитель намерения не синхронизирован до init'
        return инициализировать(*а)
    with mock.patch.object(окружение.хранение, 'синхронизировать_каталог', side_effect=sync), \
            mock.patch.object(окружение.зависимости, 'initialize_registered_dependency', side_effect=init):
        результат = окружение.подготовить(корень, задача, источник, ПУТЬ)
    assert результат['состояние'] == 'проверен'
    with mock.patch.object(окружение.зависимости, 'initialize_registered_dependency',
                           side_effect=AssertionError('Повторная материализация запрещена')):
        assert окружение.подготовить(корень, задача, источник, ПУТЬ) == результат
    assert до == конфигурация.read_bytes()


class ПроверкаОкруженияПисателя(unittest.TestCase):
    def test_новое_дерево_проходит_первую_v4_и_конечный_коммит(self):
        with фикстура(подготовить_клон, подготовить_дерево) as (корень, источник, параметры):
            файл = передача.ПроверкаДочернегоКоммита().подготовить_готовность(корень, источник, параметры)
            итог = коммит.создать(файл, [НОМЕР])
            self.assertEqual([параметры['исходный_коммит']], итог['родители'])
            self.assertEqual(итог, коммит.создать(файл, [НОМЕР]))
            self.assertEqual('', run_git('status', '--porcelain', cwd=корень))
            self.assertFalse((корень / 'Журнал/README.md').exists())
            self.assertFalse((корень / 'Индексы').exists())

    def test_сдвиг_gitlink_не_начинает_материализацию(self):
        def отказ(корень, задача, источник):
            окружение = importlib.import_module('окружение_слоя')
            другой = run_git('rev-parse', 'HEAD', cwd=корень)
            run_git('update-index', '--cacheinfo', '160000,' + другой + ',' + ПУТЬ, cwd=корень)
            with mock.patch.object(окружение.зависимости, 'initialize_registered_dependency') as запуск:
                with self.assertRaises(ValueError):
                    окружение.подготовить(корень, задача, источник, ПУТЬ)
                запуск.assert_not_called()
            raise RuntimeError('Проверенный отказ до установки Журнала')
        with self.assertRaisesRegex(RuntimeError, 'Проверенный отказ'), фикстура(подготовить_клон, отказ):
            self.fail('Не должно быть установки Журнала')

    def test_частичный_исход_не_разрешает_повтор(self):
        def отказ(корень, задача, источник):
            окружение = importlib.import_module('окружение_слоя')
            with mock.patch.object(окружение.зависимости, 'initialize_registered_dependency',
                                   return_value=(None, ['Открытая фикстура отказа'])) as запуск:
                with self.assertRaises(ValueError):
                    окружение.подготовить(корень, задача, источник, ПУТЬ)
                with self.assertRaisesRegex(ValueError, 'попытк'):
                    окружение.подготовить(корень, задача, источник, ПУТЬ)
                self.assertEqual(1, запуск.call_count)
            raise RuntimeError('Проверенный отказ до установки Журнала')
        with self.assertRaisesRegex(RuntimeError, 'Проверенный отказ'), фикстура(подготовить_клон, отказ):
            self.fail('Не должно быть установки Журнала')


if __name__ == '__main__':
    unittest.main()
