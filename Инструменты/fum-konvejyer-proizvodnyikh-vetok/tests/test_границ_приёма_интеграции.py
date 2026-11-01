"""Git-содержимое, режимы и происхождение загруженного кода проверяются отдельно."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unicodedata
import unittest
from unittest import mock

from фикстура_границ_приёма import фикстура, коммит
from фикстура_приёма_интеграции import ЖУРНАЛ
import приём_интеграции as приём


class ПроверкаГраницПриёма(unittest.TestCase):
    def test_восстановление_файла_не_скрывает_иной_загруженный_классификатор(self):
        from фикстура_штатных_событий import служебный_контекст
        исходный = Path(__file__).resolve().parents[3]
        with фикстура() as (корень, _, _, _):
            файлы = set(приём.КОД) | set(исходный.glob('Инструменты/*/scripts/**/*.py'))
            for путь in файлы:
                цель = корень / путь.relative_to(исходный)
                цель.parent.mkdir(parents=True, exist_ok=True)
                цель.write_bytes(путь.read_bytes())
            приём.хранение.гит(корень, 'add', '.')
            приём.хранение.гит(корень, 'commit', '-qm', 'Закрепить настоящий контур C')
            база = приём.хранение.гит(корень, 'rev-parse', 'HEAD').strip()
            код = '''from pathlib import Path
import sys,json
корень=Path.cwd()
for имя in ('fum-konvejyer-proizvodnyikh-vetok','fum-reyestr-planirovaniya','fum-svyaznostj-rabochej-sessii'):
    sys.path.insert(0,str(корень/'Инструменты'/имя/'scripts'))
путь=корень/'Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py'
исходные=путь.read_bytes()
if sys.argv[2]=='подмена': путь.write_bytes(исходные+'\\n# Другой загруженный код.\\n'.encode())
try:
    import снимок_нативного_источника
finally:
    путь.write_bytes(исходные)
assert снимок_нативного_источника.сообщения_задачи._КЛАССИФИКАТОР.классифицировать_сообщение(json.loads(sys.argv[3]))=='служебный контекст'
import приём_интеграции
try:
    приём_интеграции.проверить_код(корень,sys.argv[1])
except ValueError as ошибка:
    assert sys.argv[2]=='подмена' and 'Код приёма изменён после загрузки' in str(ошибка),str(ошибка)
else:
    assert sys.argv[2]=='исходный','Загруженный изменённый классификатор прошёл допуск C'
'''
            до = приём.хранение.гит(корень, 'status', '--porcelain')
            for режим in ('исходный', 'подмена'):
                with self.subTest(режим=режим):
                    процесс = subprocess.run([sys.executable, '-B', '-c', код, база, режим,
                        json.dumps(служебный_контекст()['payload'], ensure_ascii=False)], cwd=корень,
                        capture_output=True, text=True, timeout=30)
                    self.assertEqual(0, процесс.returncode, процесс.stdout + процесс.stderr)
                    self.assertEqual(до, приём.хранение.гит(корень, 'status', '--porcelain'))
                    self.assertEqual(база, приём.хранение.гит(корень, 'rev-parse', 'HEAD').strip())
                    self.assertFalse((корень / ЖУРНАЛ).exists())

    def test_неизменные_чужие_и_непринятые_байты_кода_отклоняются(self):
        with фикстура() as (корень, база, _, _):
            путь = корень / 'Инструменты/вложенный.py'
            чужой = корень.parent / 'чужой.py'
            чужой.write_bytes(путь.read_bytes())
            with mock.patch.object(приём.дочернее_назначение, 'проверить_код'):
                with mock.patch.object(приём, 'КОД', {путь: hashlib.sha256(путь.read_bytes()).hexdigest()}):
                    приём.проверить_код(корень, база)
                with mock.patch.object(приём, 'КОД', {чужой: hashlib.sha256(чужой.read_bytes()).hexdigest()}):
                    with self.assertRaisesRegex(ValueError, 'checkout|дерев|происхож'):
                        приём.проверить_код(корень, база)
                путь.write_text('Новый код, которого нет в C\n')
                with mock.patch.object(приём, 'КОД', {путь: hashlib.sha256(путь.read_bytes()).hexdigest()}):
                    with self.assertRaisesRegex(ValueError, 'коммит| C|баз'):
                        приём.проверить_код(корень, база)

    def test_контур_учитывает_добавление_удаление_и_режим(self):
        with фикстура() as (корень, база, вершина, срез):
            приём.проверить_деревья(корень, база, вершина, срез, ЖУРНАЛ)
            варианты = [
                {'Инструменты/новый.py': ('100644', b'new\n')},
                {'Правила/правило.md': None},
                {'AGENTS.md': ('100755', (корень / 'AGENTS.md').read_bytes())},
                {'.codex/config.toml': ('120000', b'outside')},
                {'инструменты/другой.py': ('100644', b'new\n')},
            ]
            for правки in варианты:
                with self.subTest(правки=list(правки)), self.assertRaisesRegex(ValueError, 'контур'):
                    приём.проверить_деревья(корень, база, вершина, коммит(корень, срез, правки), ЖУРНАЛ)

    def test_новый_журнал_не_переиспользует_путь_с_иным_регистром_и_нормализацией(self):
        with фикстура() as (корень, база, вершина, срез):
            журнал = ЖУРНАЛ.replace('срез', 'своё-обновление')
            self.assertNotEqual(журнал, unicodedata.normalize('NFD', журнал))
            for путь in (журнал + 'запрос.md', журнал.casefold() + 'запрос.md',
                         unicodedata.normalize('NFD', журнал) + 'запрос.md', 'Журнал'):
                иной = коммит(корень, срез, {путь: ('100644', b'old\n')})
                with self.subTest(путь=путь), self.assertRaisesRegex(ValueError, 'Журнал'):
                    приём.проверить_деревья(корень, база, вершина, иной, журнал)


if __name__ == '__main__':
    unittest.main()
