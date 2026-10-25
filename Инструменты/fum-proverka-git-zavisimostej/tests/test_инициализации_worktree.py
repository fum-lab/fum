"""Инициализация зависимости принадлежит одному связанному рабочему дереву."""
from pathlib import Path
import os
import shlex
import tempfile
import unittest
from unittest import mock

from test_proveritj_git_zavisimostj import GitDependencyFixture, run_git, proveritj_git_zavisimostj as модуль
from test_подготовка_зависимостей import загрузить_подготовку


class ПроверкаИнициализацииРабочегоДерева(unittest.TestCase):
    def test_заполненные_общие_модули_и_чужие_деревья_сохраняются(сам):
        with tempfile.TemporaryDirectory() as имя:
            фикстура = GitDependencyFixture(Path(имя).resolve())
            сам.assertEqual([], фикстура.add_dependency())
            фикстура.publish_dependency_registration()
            первичный = фикстура.superproject
            общий = первичный / '.git'
            сам.assertTrue(any((общий / 'modules').rglob('config')))
            сам.assertEqual([], модуль.validate_dependency(первичный, фикстура.dependency_spec()))
            собственный = фикстура.root / 'собственная-подготовка'
            run_git('worktree', 'add', '-b', 'codex/подготовка', str(собственный), 'HEAD', cwd=первичный)
            чужие = []
            for номер in range(2):
                дерево = фикстура.root / f'чужое-дерево-{номер}'
                run_git('worktree', 'add', '-b', f'codex/чужой-{номер}', str(дерево), 'HEAD', cwd=первичный)
                (дерево / 'README.md').write_text(f'Отдельный чужой коммит {номер}\n', encoding='utf-8')
                run_git('add', 'README.md', cwd=дерево)
                run_git('commit', '-m', f'Сохранить чужой этап {номер}', cwd=дерево)
                (дерево / 'README.md').write_text(f'Подготовленный индекс {номер}\n', encoding='utf-8')
                (дерево / 'добавка.txt').write_text(f'Чужая добавка {номер}\n', encoding='utf-8')
                run_git('add', 'README.md', 'добавка.txt', cwd=дерево)
                сам.assertEqual({'README.md', 'добавка.txt'}, set(run_git('diff', '--cached', '--name-only', '-z', cwd=дерево).split('\0')) - {''})
                чужие.append(дерево)
            (первичный / 'README.md').write_text('Подготовленный первичный индекс\n', encoding='utf-8')
            run_git('add', 'README.md', cwd=первичный)
            сам.assertEqual('README.md', run_git('diff', '--cached', '--name-only', cwd=первичный))
            сам.assertEqual(2, len({run_git('rev-parse', 'HEAD', cwd=дерево) for дерево in чужие}))

            def каталог(путь):
                return {п.relative_to(путь).as_posix():
                        (п.lstat().st_mode, п.read_bytes() if п.is_file() else None)
                        for п in путь.rglob('*')}

            def защищённые_снимки():
                return {
                    'общие_модули': каталог(общий / 'modules'),
                    'конфигурация': (общий / 'config').read_bytes(),
                    'первичный_индекс': (общий / 'index').read_bytes(),
                    'первичный_указатель': (общий / 'HEAD').read_bytes(),
                    'ссылки': каталог(общий / 'refs'),
                    'упакованные_ссылки': (общий / 'packed-refs').read_bytes() if (общий / 'packed-refs').exists() else None,
                    'идентификаторы_ссылок': run_git('for-each-ref', '--format=%(refname) %(objectname)', cwd=первичный),
                    'первичная_копия': каталог(первичный / фикстура.path),
                    'чужие_копии': [каталог(дерево) for дерево in чужие],
                    'чужие_гит_каталоги': [каталог(Path(run_git('rev-parse', '--absolute-git-dir', cwd=дерево)))
                                            for дерево in чужие],
                }

            до = защищённые_снимки()
            подготовка = загрузить_подготовку()
            снимок = подготовка.снять_снимок(собственный)
            исполнитель = '00000000-0000-0000-0000-000000000001'
            задача = '00000000-0000-0000-0000-000000000002'
            with mock.patch.dict(os.environ, {'CODEX_THREAD_ID': исполнитель}):
                итог = подготовка.подготовить_зависимости(собственный, снимок, исполнитель, задача)
            сам.assertTrue(итог['готова'])
            сам.assertEqual(до, защищённые_снимки())
            сам.assertEqual(снимок, подготовка.снять_снимок(собственный))
            зависимый = Path(run_git('rev-parse', '--absolute-git-dir', cwd=собственный / фикстура.path))
            ожидаемый = Path(снимок['гит_каталог']) / 'modules' / фикстура.path
            сам.assertEqual(ожидаемый, зависимый)
            сам.assertEqual(str(ожидаемый), run_git('rev-parse', '--path-format=absolute', '--git-common-dir', cwd=собственный / фикстура.path))
            сам.assertFalse(зависимый.is_relative_to(общий / 'modules'))
            with mock.patch.dict(os.environ, {'CODEX_THREAD_ID': исполнитель}), mock.patch.object(
                    подготовка.исходный, 'initialize_registered_dependency', side_effect=AssertionError('готовый повтор init')):
                повтор = подготовка.подготовить_зависимости(собственный, снимок, исполнитель, задача)
            сам.assertTrue(повтор['готова'])
            сам.assertTrue(повтор['без_повторных_эффектов'])
            сам.assertEqual(до, защищённые_снимки())
            сам.assertEqual(снимок, подготовка.снять_снимок(собственный))

    def test_внешняя_среда_не_запускает_hook_при_материализации(self):
        with tempfile.TemporaryDirectory() as имя:
            фикстура = GitDependencyFixture(Path(имя).resolve())
            self.assertEqual([], фикстура.add_dependency())
            фикстура.publish_dependency_registration()
            клон = фикстура.fresh_clone(recurse_submodules=False)
            hooks = фикстура.root / 'hooks'; hooks.mkdir()
            маркер = фикстура.root / 'запись-вне-дерева'
            hook = hooks / 'post-checkout'
            hook.write_text('#!/bin/sh\n: > ' + shlex.quote(str(маркер)) + '\n')
            hook.chmod(0o755)
            with mock.patch.dict(os.environ, {'GIT_CONFIG_COUNT': '1', 'GIT_CONFIG_KEY_0': 'core.hooksPath',
                                             'GIT_CONFIG_VALUE_0': str(hooks)}):
                _, ошибки = модуль.initialize_registered_dependency(клон, фикстура.path)
            self.assertEqual([], ошибки)
            self.assertFalse(маркер.exists())

    def test_скрытые_изменения_зависимости_не_считаются_готовностью(self):
        with tempfile.TemporaryDirectory() as имя:
            фикстура = GitDependencyFixture(Path(имя).resolve())
            self.assertEqual([], фикстура.add_dependency())
            зависимость = фикстура.superproject / фикстура.path
            run_git('update-index', '--assume-unchanged', 'README.md', cwd=зависимость)
            (зависимость / 'README.md').write_text('Скрытое изменение\n')
            self.assertEqual('', run_git('status', '--porcelain', cwd=зависимость))
            self.assertTrue(модуль.validate_dependency(фикстура.superproject, фикстура.dependency_spec()))

    def test_новый_clone_и_worktree_не_меняют_общую_конфигурацию(self):
        with tempfile.TemporaryDirectory() as имя:
            фикстура = GitDependencyFixture(Path(имя).resolve())
            self.assertEqual([], фикстура.add_dependency())
            фикстура.publish_dependency_registration()
            клон = фикстура.fresh_clone(recurse_submodules=False)
            дерево = фикстура.root / 'связанное-дерево'
            run_git('worktree', 'add', '-b', 'codex/писатель', str(дерево), 'HEAD', cwd=клон)
            конфигурация = клон / '.git/config'
            до = конфигурация.read_bytes()
            общий_индекс = (клон / '.git/index').read_bytes()
            исходный_gitlink = run_git('ls-files', '--stage', '--', фикстура.path, cwd=дерево)
            модуль_до = dict((п.relative_to(клон / '.git').as_posix(), п.read_bytes())
                            for п in (клон / '.git/modules').rglob('*') if п.is_file())
            for _ in range(2):
                описание, ошибки = модуль.initialize_registered_dependency(дерево, фикстура.path)
                self.assertEqual([], ошибки)
                self.assertEqual(фикстура.dependency_spec(), описание)
                self.assertEqual(до, конфигурация.read_bytes())
                self.assertEqual(общий_индекс, (клон / '.git/index').read_bytes())
                self.assertEqual(исходный_gitlink, run_git('ls-files', '--stage', '--', фикстура.path, cwd=дерево))
                self.assertEqual([], list((клон / фикстура.path).iterdir()))
                self.assertEqual('', run_git('status', '--porcelain', cwd=дерево))
                собственный = Path(run_git('rev-parse', '--absolute-git-dir', cwd=дерево))
                зависимый = Path(run_git('rev-parse', '--absolute-git-dir', cwd=дерево / фикстура.path))
                self.assertTrue(зависимый.is_relative_to(собственный / 'modules'))
            self.assertEqual(модуль_до, dict((п.relative_to(клон / '.git').as_posix(), п.read_bytes())
                            for п in (клон / '.git/modules').rglob('*') if п.is_file()))


if __name__ == '__main__':
    unittest.main()
