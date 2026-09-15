"""Поведение пакетного переноса на открытом временном репозитории."""
import hashlib
import json
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock
from test_pereimenovatj_fajl_s_obnovleniyem_ssyilok import RepositoryFixture, SCRIPT


def загрузить():
    spec = importlib.util.spec_from_file_location('перенос_проверки', SCRIPT)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ПакетTests(unittest.TestCase):
    def setUp(self):
        self.м = загрузить()
        self.р = RepositoryFixture()
        self.addCleanup(self.р.close)
        self.р.write('src/a.bin', b'\x00\xff\r\n', 0o755)
        self.р.write('src/b.swift', 'let ё = 1\n')
        self.р.write('index.md', '[a](src/a.bin) [b](src/b.swift#x)\r\n')
        self.р.write('dirty.md', 'before\n')
        self.р.commit()
        (self.р.root / 'out').mkdir()
        self.вход = {'схема': 'fum.пакет-переноса.1',
            'HEAD': self.р.git('rev-parse', 'HEAD').stdout.strip(),
            'перемещения': [self.пара('src/a.bin', 'out/a.bin'), self.пара('src/b.swift', 'out/b.swift')]}

    def пара(self, a, b):
        return {'исходник': a, 'назначение': b,
                'sha256': hashlib.sha256((self.р.root/a).read_bytes()).hexdigest()}

    def план(self):
        return self.м.план_пакета(self.р.root.resolve(), self.вход)

    def test_байты_режим_ссылки_один_разбор(self):
        with mock.patch.object(self.м, 'markdown_link_tokens', wraps=self.м.markdown_link_tokens) as разбор:
            план = self.план()
            self.assertEqual(разбор.call_count, 2)
        описание = self.м.описание_пакета(план)
        self.assertEqual(описание, self.м.описание_пакета(self.план()))
        self.м.применить_пакет(план, описание['sha256'])
        self.assertEqual((self.р.root/'out/a.bin').read_bytes(), b'\x00\xff\r\n')
        self.assertEqual((self.р.root/'out/a.bin').stat().st_mode & 0o777, 0o755)
        self.assertEqual((self.р.root/'index.md').read_bytes(), b'[a](out/a.bin) [b](out/b.swift#x)\r\n')
        self.assertFalse((self.р.root/'src/b.swift').exists())

    def test_cli_сохранённый_план_и_обязательный_хэш(self):
        путь=self.р.root/'batch.json'
        путь.write_text(json.dumps(self.вход,ensure_ascii=False))
        def cli(mode,*extra):
            return subprocess.run([sys.executable,str(SCRIPT),mode,'--repo-root',str(self.р.root),
                '--пакет',str(путь),*extra],capture_output=True,text=True)
        plan=cli('план-пакета')
        self.assertEqual(plan.returncode,0,plan.stderr)
        self.assertEqual(cli('применить-пакет').returncode,1)
        applied=cli('применить-пакет','--план-sha256',json.loads(plan.stdout)['sha256'])
        self.assertEqual(applied.returncode,0,applied.stderr)
        self.assertFalse((self.р.root/'src/a.bin').exists())

    def test_md_и_неверный_HEAD_отклонены(self):
        head=self.вход['HEAD'];self.вход['HEAD']='0'*40
        with self.assertRaises(self.м.RenameError):self.план()
        self.вход['HEAD']=head
        self.вход['перемещения']=[self.пара('index.md','out/index.md')]
        with self.assertRaises(self.м.RenameError):self.план()

    def test_непросмотренный_план_отклонён(self):
        старый = self.м.описание_пакета(self.план())['sha256']
        self.р.write('index.md', '[a](src/a.bin)\n')
        with self.assertRaises(self.м.RenameError):
            self.м.применить_пакет(self.план(), старый)
        self.assertTrue((self.р.root/'src/a.bin').exists())

    def test_хэш_и_коллизии_отклонены(self):
        исходный = self.вход['перемещения'][0].copy()
        for правка in [{'sha256':'0'*64}, {'назначение':'out/b.swift'}, {'назначение':'out/B.swift'}, {'назначение':'src/b.swift'}]:
            with self.subTest(правка=правка):
                self.вход['перемещения'][0] = dict(исходный, **правка)
                with self.assertRaises(self.м.RenameError):self.план()
        self.assertEqual(self.р.git('status','--porcelain').stdout, '')

    def test_защищённая_цитата_wiki_symlink(self):
        for текст in ['[[src/a.bin]]\n', '[a](alias/a.bin)\n']:
            self.р.write('index.md', текст)
            if 'alias' in текст:(self.р.root/'alias').symlink_to('src', target_is_directory=True)
            with self.assertRaises(self.м.RenameError):self.план()
        (self.р.root/'alias').unlink()
        self.р.write('index.md', '')
        self.р.write('Журнал/2026-09-15_12-00-00_MSK_проверить/запрос.md', '## Текст запроса\n\n[a](../../src/a.bin)\n')
        with self.assertRaises(self.м.RenameError):self.план()

    def test_изменение_снимка_останавливает_запись(self):
        план=self.план();хэш=self.м.описание_пакета(план)['sha256']
        self.р.write('src/b.swift','changed\n')
        with self.assertRaises(self.м.RenameError):self.м.применить_пакет(план,хэш)
        self.assertFalse((self.р.root/'out/a.bin').exists())

    def test_индекс_изменился_при_планировании(self):
        real = self.м.build_plan
        def changed(*args, **kwargs):
            # Same worktree bytes, different staged blob.
            original = (self.р.root/'src/a.bin').read_bytes()
            self.р.write('src/a.bin', b'other')
            self.р.git('add','src/a.bin')
            self.р.write('src/a.bin', original, 0o755)
            return real(*args, **kwargs)
        with mock.patch.object(self.м,'build_plan',side_effect=changed):
            with self.assertRaises(self.м.RenameError):self.план()

    def test_внешняя_правка_между_mv_не_теряется(self):
        план=self.план();хэш=self.м.описание_пакета(план)['sha256']
        real=self.м.run_git;calls=0
        def changed(root,*args,**kwargs):
            nonlocal calls
            result=real(root,*args,**kwargs)
            if args[0]=='mv':
                calls+=1
                if calls==1:self.р.write('index.md','external edit\n')
            return result
        with mock.patch.object(self.м,'run_git',side_effect=changed):
            with self.assertRaises(self.м.RenameError):self.м.применить_пакет(план,хэш)
        self.assertEqual((self.р.root/'index.md').read_text(),'external edit\n')
        self.assertTrue((self.р.root/'src/a.bin').exists())
        self.assertTrue((self.р.root/'src/b.swift').exists())

    def test_откат_второго_mv_и_установки(self):
        for отказ in ['mv','replace']:
            with self.subTest(отказ=отказ):
                self.р.write('dirty.md','staged\n');self.р.git('add','dirty.md')
                self.р.write('dirty.md','unstaged\n')
                before=self.р.git('status','--porcelain','-z').stdout
                индекс=self.р.git('ls-files','--stage','-z').stdout
                план=self.план();хэш=self.м.описание_пакета(план)['sha256']
                real_git=self.м.run_git;real_replace=os.replace;calls=0
                def git(root,*args,**kwargs):
                    nonlocal calls
                    if args[0]=='mv':
                        calls+=1
                        if calls==2:return subprocess.CompletedProcess(args,1,b'',b'injected')
                    return real_git(root,*args,**kwargs)
                def replace(a,b):
                    nonlocal calls
                    calls+=1
                    if calls==1:raise OSError('injected')
                    return real_replace(a,b)
                patch=mock.patch.object(self.м,'run_git',side_effect=git) if отказ=='mv' else mock.patch.object(self.м.os,'replace',side_effect=replace)
                with patch:
                    with self.assertRaisesRegex(self.м.RenameError,'rolled back'):
                        self.м.применить_пакет(план,хэш)
                self.assertEqual(self.р.git('status','--porcelain','-z').stdout,before)
                self.assertEqual(self.р.git('ls-files','--stage','-z').stdout,индекс)
                self.assertEqual((self.р.root/'src/a.bin').read_bytes(),b'\x00\xff\r\n')
                self.assertEqual((self.р.root/'dirty.md').read_text(),'unstaged\n')
                self.assertEqual(list(self.р.root.rglob('.fum-rename-*')),[])

if __name__=='__main__':unittest.main()
