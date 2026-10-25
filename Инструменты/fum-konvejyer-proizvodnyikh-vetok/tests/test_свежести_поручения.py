"""Настоящие установка пары и свежесть не теряют метки внутри поручения."""
import importlib
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from test_области_писателя import область_фикстура


class ПроверкаСвежестиПоручения(unittest.TestCase):
    def test_план_свежести_архива_не_удваивает_конечную_метку(сам):
        свежесть = importlib.import_module('свежесть_слоя')
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            путь = корень / 'Источники/URL/https/chatgpt.com/share/id/диалог.md'
            путь.parent.mkdir(parents=True)
            тело = ('# Архив\n\n## Диалог\n\n<!-- FUM-CHATGPT-SHARE-VERBATIM:BEGIN -->\n'
                    '```text\nДословный фрагмент\n<!-- FUM-CHATGPT-SHARE-VERBATIM:END -->\n')
            исходный = свежесть.свежесть.attach_recency_block(тело, '2026-09-22 12:00:00 MSK', 'a' * 64)
            путь.write_text(исходный)
            # Допуск области проверяется отдельными Git-фикстурами; здесь
            # проверяется реальный план байтов для уже допущенного источника.
            with mock.patch.object(свежесть.дочернее_назначение, 'прочитать', return_value={'sha256': 'допущено'}), \
                    mock.patch.object(свежесть, 'markdown', return_value=[путь]), \
                    mock.patch.object(свежесть.запись_слоя, 'сверить_входы'):
                план = свежесть.подготовить(корень, 'фикстура', None)
            сам.assertEqual(путь.read_text(), исходный)
            сам.assertEqual(len(план['файлы']), 1)
            новое = план['файлы'][0].data.decode('utf-8')
            сам.assertEqual(новое.count('<!-- FUM-MD-RECENCY:BEGIN -->'), 1)
            сам.assertTrue(новое.startswith(тело))

    def test_метка_из_C_сохраняется_в_дословном_поле_после_свежести(сам):
        with область_фикстура(v2=True, метки_поручений=True) as (_, _, _, _, назначение, дети):
            корень, задача, источник = дети['события']
            журнал = importlib.import_module('журнал_слоя')
            свежесть = importlib.import_module('свежесть_слоя')
            нативное = importlib.import_module('нативное_назначение')
            поручение = нативное.прочитать(источник)['текст']
            with mock.patch.dict(os.environ, CODEX_THREAD_ID=задача):
                журнал.установить(корень, задача, источник)
                путь = корень / назначение['журналы']['события'] / 'запрос.md'
                сам.assertIn(поручение, путь.read_text())
                план = свежесть.подготовить(корень, задача, источник)
                свежесть.применить(корень, задача, источник, план)
                сам.assertIn(поручение, путь.read_text())
                сам.assertEqual([], свежесть.подготовить(корень, задача, источник)['файлы'])
            сам.assertFalse((корень / 'Индексы').exists())


if __name__ == '__main__':
    unittest.main()
