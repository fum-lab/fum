"""Git-содержимое, режимы и происхождение загруженного кода проверяются отдельно."""
import hashlib
import unicodedata
import unittest
from unittest import mock

from фикстура_границ_приёма import фикстура, коммит
from фикстура_приёма_интеграции import ЖУРНАЛ
import приём_интеграции as приём


class ПроверкаГраницПриёма(unittest.TestCase):
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
