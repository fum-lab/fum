"""Реальный ранний CLI обязан видеть производные изменения до проекции."""
import json
import subprocess
import sys
import unittest
from pathlib import Path
import test_ранний_охват as основа

СКРИПТ = основа.ПУТЬ.with_name('проверить-охват-запроса.py')

class ПокрытиеДоПроекции(unittest.TestCase):
    setUp = основа.ПроверкаОхвата.setUp
    git = основа.ПроверкаОхвата.git
    записать = основа.ПроверкаОхвата.записать

    def вызвать(self):
        p = subprocess.run([sys.executable, '-B', str(СКРИПТ), '--корень', str(self.корень), '--запрос', str(self.запрос.relative_to(self.корень))], capture_output=True, text=True)
        self.assertTrue(p.stdout.strip(), p.stderr)
        return p.returncode, json.loads(p.stdout)

    def test_производный_реестр_нуждается_в_ссылке(self):
        p = self.корень/'Планирование/реестр.json';p.parent.mkdir();p.write_text('{}')
        self.assertEqual(self.вызвать()[0], 1)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Реестр](../../Планирование/реестр.json)')
        до = self.git('status', '--porcelain=v1', '-z')
        self.assertEqual(self.вызвать()[0], 0)
        self.assertEqual(до, self.git('status', '--porcelain=v1', '-z'))

    def test_соседний_префикс_не_покрыт(self):
        for n in ('данные', 'данные-сосед'):
            (self.корень/n).mkdir();(self.корень/n/'файл').write_text('x')
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Данные](../../данные)')
        self.assertEqual(self.вызвать()[0], 1)

    def test_переименование_сохраняет_старую_цель(self):
        (self.корень/'старый').write_text('x');self.git('add','.');self.git('-c','user.name=Тест','-c','user.email=t@example.invalid','commit','-qm','Основа')
        self.git('mv','старый','новый')
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Новый](../../новый)')
        self.assertEqual(self.вызвать()[0],1)
        self.записать(self.запрос.read_text().split('## Повлиял на файлы\n')[1]+'\n- Удалённый файл: `старый`')
        self.assertEqual(self.вызвать()[0],0)

    def test_ошибка_git_закрывает_допуск(self):
        import shutil
        shutil.rmtree(self.корень/'.git')
        self.assertEqual(self.вызвать()[0],1)

    def test_изменённый_отслеживаемый_реестр(self):
        p=self.корень/'реестр.json';p.write_text('{}')
        self.git('add','.');self.git('-c','user.name=Тест','-c','user.email=t@example.invalid','commit','-qm','Основа')
        p.write_text('{"новый":1}')
        self.assertEqual(self.вызвать()[0],1)
        self.записать('[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Реестр](../../реестр.json)')
        self.assertEqual(self.вызвать()[0],0)

    def test_дрейф_внутри_проверки(self):
        import importlib.util
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ранний_охват_новый',СКРИПТ)
        модуль=importlib.util.module_from_spec(spec);spec.loader.exec_module(модуль)
        исходный=модуль.ОХВАТ.прочитать_охват
        действия=[
            lambda:self.запрос.write_text(self.запрос.read_text()+'\nДрейф\n'),
            lambda:(self.корень/'новый-файл').write_text('x'),
            lambda:self.git('switch','-qc','другая'),
            lambda:self.git('-c','user.name=Тест','-c','user.email=t@example.invalid','commit','--allow-empty','-qm','Новая вершина'),
        ]
        for номер,действие in enumerate(действия):
            with self.subTest(номер=номер):
                def изменить(*args):
                    результат=исходный(*args);действие();return результат
                with patch.object(модуль.ОХВАТ,'прочитать_охват',изменить):
                    результат=модуль.проверить(self.корень,str(self.запрос.relative_to(self.корень)))
                self.assertFalse(результат['готов'])
                self.assertIn('Вход изменился во время проверки охвата',результат['ошибки'])
