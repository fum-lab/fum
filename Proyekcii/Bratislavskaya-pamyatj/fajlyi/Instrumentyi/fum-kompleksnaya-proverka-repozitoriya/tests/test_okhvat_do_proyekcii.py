"""Проверить раннюю остановку построенного smoke-плана."""
import contextlib
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock
import test_run_smoke_check as основа

МОДУЛЬ = основа.run_smoke_check

class РаннийОхватПлана(unittest.TestCase):
    write_script_fixture = основа.RunSmokeCheckTests.write_script_fixture
    создать_фикстуры_документационных_тестов = основа.RunSmokeCheckTests.создать_фикстуры_документационных_тестов

    def test_охват_после_реестра_останавливает_до_проекции(self):
        with tempfile.TemporaryDirectory() as временный:
            корень=Path(временный);self.write_script_fixture(корень);self.создать_фикстуры_документационных_тестов(корень)
            путь=корень/'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-охват-запроса.py';путь.write_text('')
            шаги=МОДУЛЬ.упорядочить_тестовые_шаги(МОДУЛЬ.build_steps(корень,Path('Журнал/2026-07-01_14-12-17_MSK/запрос.md')), {})
            имена=[ш.name for ш in шаги];имя='Ранняя проверка охвата запроса'
            self.assertIn(имя,имена)
            self.assertLess(имена.index('Проверка планового реестра'),имена.index(имя))
            self.assertLess(имена.index(имя),имена.index('Применение братиславской проекции памяти'))
            цель=шаги[имена.index(имя)]
            self.assertTrue(цель.ранняя_проверка)
            def запустить(команда, **kwargs):
                return subprocess.CompletedProcess(команда,1 if команда==цель.command else 0)
            with mock.patch.object(МОДУЛЬ.subprocess,'run',side_effect=запустить) as вызовы, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(МОДУЛЬ.run_steps(шаги,корень),1)
            self.assertEqual(вызовы.call_args_list[-1].args[0],цель.command)
            self.assertNotIn(шаги[имена.index('Применение братиславской проекции памяти')].command,[в.args[0] for в in вызовы.call_args_list])

    def test_без_сессии_охват_отсутствует(self):
        with tempfile.TemporaryDirectory() as временный:
            корень=Path(временный);self.write_script_fixture(корень);self.создать_фикстуры_документационных_тестов(корень)
            шаги=МОДУЛЬ.build_steps(корень,None,include_session=False)
            self.assertNotIn('Ранняя проверка охвата запроса',[ш.name for ш in шаги])

    def test_ранний_cli_берётся_из_принимающего_источника(self):
        import sys
        with tempfile.TemporaryDirectory() as временный:
            корень=Path(временный).resolve()
            subprocess.run(['git','init','-q',str(корень)],check=True)
            subprocess.run(['git','-C',str(корень),'-c','user.name=Тест','-c','user.email=t@example.invalid','commit','--allow-empty','-qm','Основа'],check=True)
            запрос=Path('Журнал/2026-07-01_14-12-17_MSK/запрос.md')
            (корень/запрос).parent.mkdir(parents=True)
            (корень/запрос).write_text('# Запрос\n\n## Повлиял на файлы\n[Запрос](запрос.md)\n[Отчёт](отчёт.md)\n[Инструменты](../../Инструменты)\n')
            (корень/запрос).with_name('отчёт.md').write_text('Отчёт')
            каталог=корень/'Инструменты/fum-svyaznostj-rabochej-sessii/scripts';каталог.mkdir(parents=True)
            for имя in ('проверить-охват-запроса.py','сверить-материалы-этапа.py','check-session-coherence.py'):
                (каталог/имя).write_text('raise RuntimeError("Подмена кандидатом")')
            (корень/'.codex').mkdir()
            (корень/'.codex/config.toml').write_text('[skills]\ninclude_instructions = false\n')
            with (корень/запрос).open('a') as файл: файл.write('[Конфигурация](../../.codex/config.toml)\n')
            источник=основа.SCRIPT_PATH.parents[3]
            шаги=МОДУЛЬ.build_steps(корень,запрос,python=sys.executable,корень_проверок=источник)
            шаг=next(ш for ш in шаги if ш.name=='Ранняя проверка охвата запроса')
            self.assertEqual(Path(шаг.command[1]),источник/'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-охват-запроса.py')
            p=subprocess.run(шаг.command,cwd=корень,capture_output=True,text=True)
            self.assertEqual(p.returncode,0,p.stdout+p.stderr)
