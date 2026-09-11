"""Отсоединённая вершина сохраняется без создания или переключения refs."""
from pathlib import Path
import tempfile
import unittest
from фикстуры import создать, гит, перенос, процесс, снимок_данных, снимок_репозиториев


class ПроверкаОтсоединённогоКорня(unittest.TestCase):
    def подготовить(сам, основание):
        привязки = создать(основание)
        гит(Path(привязки['источник']), 'checkout', '--detach')
        план = основание / 'план.json'
        вход = основание / 'привязки.json'
        план.write_bytes(перенос.канон.кодировать(перенос.построить(привязки)))
        вход.write_bytes(перенос.канон.кодировать(привязки))
        return привязки, план, вход

    def test_авария_возобновление_и_повтор_сохраняют_отсоединённый_корень(сам):
        with tempfile.TemporaryDirectory() as временный:
            привязки, план, вход = сам.подготовить(Path(временный).resolve())
            источник, цель = Path(привязки['источник']), Path(привязки['назначение'])
            до, данные = снимок_репозиториев(источник), снимок_данных(источник)
            сам.assertEqual(77, процесс(план, вход, 'после-перемещения').returncode)
            первый = процесс(план, вход)
            сам.assertEqual(0, первый.returncode, первый.stderr.decode())
            сам.assertEqual(до, снимок_репозиториев(цель))
            сам.assertEqual(данные, снимок_данных(цель))
            сам.assertFalse((Path(привязки['общий']) / 'worktrees/исходный/HEAD').read_bytes().startswith(b'ref:'))
            повтор = процесс(план, вход)
            сам.assertEqual(0, повтор.returncode, повтор.stderr.decode())
            сам.assertEqual(первый.stdout, повтор.stdout)

    def test_сдвиг_вершины_режима_или_индекса_после_аварии_отклоняется(сам):
        for случай in ('вершина', 'режим', 'индекс'):
            with сам.subTest(случай=случай), tempfile.TemporaryDirectory() as временный:
                привязки, план, вход = сам.подготовить(Path(временный).resolve())
                сам.assertEqual(77, процесс(план, вход, 'после-перемещения').returncode)
                каталог = Path(привязки['общий']) / 'worktrees/исходный'
                if случай == 'вершина':
                    (каталог / 'HEAD').write_bytes(гит(Path(привязки['общий']).parent, 'rev-parse', 'HEAD^'))
                elif случай == 'режим':
                    (каталог / 'HEAD').write_bytes(b'ref: refs/heads/codex/' + 'перенос\n'.encode())
                else:
                    with (каталог / 'index').open('ab') as поток:
                        поток.write(b'changed')
                изменённое = {имя: (каталог / имя).read_bytes() for имя in ('HEAD', 'index')}
                отказ = процесс(план, вход)
                сам.assertEqual(2, отказ.returncode, отказ.stderr.decode())
                сам.assertEqual(изменённое, {имя: (каталог / имя).read_bytes() for имя in изменённое})
