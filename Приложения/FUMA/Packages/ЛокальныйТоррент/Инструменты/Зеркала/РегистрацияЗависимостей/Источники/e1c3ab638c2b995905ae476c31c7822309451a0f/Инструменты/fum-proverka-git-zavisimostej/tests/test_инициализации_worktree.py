"""Инициализация зависимости принадлежит одному связанному рабочему дереву."""
from pathlib import Path
import os
import shlex
import tempfile
import unittest
from unittest import mock

from test_proveritj_git_zavisimostj import GitDependencyFixture, run_git, proveritj_git_zavisimostj as модуль


class ПроверкаИнициализацииРабочегоДерева(unittest.TestCase):
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
