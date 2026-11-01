"""Конечные прежние сценарии, затронутые расширением транзакции и CLI."""
from pathlib import Path
import sys
import unittest

КОРЕНЬ = Path(__file__).resolve().parents[3]
for каталог in [Path(__file__).parent, КОРЕНЬ / 'Инструменты/fum-svyaznostj-rabochej-sessii/tests']:
    sys.path.insert(0, str(каталог))

СЦЕНАРИИ = (
    'test_request_folder_layout.RequestFolderLayoutTests.test_start_requires_timestamp_updates_navigation_and_is_idempotent',
    'test_request_folder_layout.RequestFolderLayoutTests.test_шаблоны_задают_полный_формат_старта',
    'test_request_folder_layout.RequestFolderLayoutTests.test_reindex_uses_only_baseline_index_section_and_rolls_back',
    'test_request_folder_layout.RequestFolderLayoutTests.test_repair_from_exact_base_rewrites_only_proven_links_and_navigation',
    'test_план_начала.ПроверкаПланаНачала.test_план_не_пишет_байты_режимы_индекс_или_каталоги',
    'test_собственная_пара.ПроверкаСобственнойПары.test_только_два_файла_без_общего_сканирования_и_записи',
    'test_расширение_шаблонов.ПроверкиРасширения.test_откат_второй_записи',
    'test_check_session_coherence.CheckSessionCoherenceTests.test_reports_broken_markdown_link',
)


def load_tests(загрузчик, набор, маска):
    return загрузчик.loadTestsFromNames(СЦЕНАРИИ)


if __name__ == '__main__':
    unittest.main()
