"""Общий флаг допустим только без отдельной конфигурации выбранного дерева."""
from pathlib import Path
import tempfile
import unittest
from фикстуры import создать, гит, перенос, процесс


class ПроверкаФлагаКонфигурации(unittest.TestCase):
    def test_отсутствующий_рабочий_путь_подмодуля_сохраняется(сам):
        with tempfile.TemporaryDirectory() as временный:
            основание = Path(временный).resolve()
            привязки = создать(основание)
            модуль = Path(привязки['источник']) / 'модуль'
            гит(модуль, 'config', '--unset', 'core.worktree')
            конфиг = Path(гит(модуль, 'rev-parse', '--absolute-git-dir').decode().strip()) / 'config'
            до = конфиг.read_bytes()
            план = основание / 'план.json'; вход = основание / 'привязки.json'
            план.write_bytes(перенос.канон.кодировать(перенос.построить(привязки)))
            вход.write_bytes(перенос.канон.кодировать(привязки))
            сам.assertEqual(77, процесс(план, вход, 'после-перемещения').returncode)
            ответ = процесс(план, вход)
            сам.assertEqual(0, ответ.returncode, ответ.stderr.decode())
            сам.assertEqual(до, конфиг.read_bytes())
            новый = Path(привязки['назначение']) / 'модуль'
            сам.assertEqual(str(новый), гит(новый, 'rev-parse', '--show-toplevel').decode().strip())

    def test_общий_флаг_без_локального_файла_не_требует_ремонта(сам):
        with tempfile.TemporaryDirectory() as временный:
            основание = Path(временный).resolve()
            привязки = создать(основание)
            источник = Path(привязки['источник'])
            гит(источник, 'config', 'extensions.worktreeConfig', 'true')
            конфиг = Path(привязки['общий']) / 'config'
            до = конфиг.read_bytes()
            план = основание / 'план.json'; вход = основание / 'привязки.json'
            план.write_bytes(перенос.канон.кодировать(перенос.построить(привязки)))
            вход.write_bytes(перенос.канон.кодировать(привязки))
            ответ = процесс(план, вход)
            сам.assertEqual(0, ответ.returncode, ответ.stderr.decode())
            сам.assertEqual(до, конфиг.read_bytes())

    def test_наличие_или_позднее_появление_локального_файла_отклоняется(сам):
        with tempfile.TemporaryDirectory() as временный:
            основание = Path(временный).resolve()
            привязки = создать(основание)
            источник = Path(привязки['источник'])
            гит(источник, 'config', 'extensions.worktreeConfig', 'true')
            план = перенос.построить(привязки)
            локальный = Path(привязки['общий']) / 'worktrees/исходный/config.worktree'
            локальный.write_bytes(b'')
            with сам.assertRaisesRegex(ValueError, 'конфигурац'):
                перенос.построить(привязки)
            with сам.assertRaises(ValueError):
                перенос.применить(план, привязки, привязки['владелец'])
            сам.assertTrue(источник.exists())
            сам.assertEqual(b'', локальный.read_bytes())
