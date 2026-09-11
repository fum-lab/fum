"""Чистый план использует стандартный каркас и сохраняет прежний старт."""
import contextlib
import importlib.util
import stat
import sys
import unittest
from pathlib import Path

import test_request_folder_layout as прежние


путь_реализации = Path(__file__).resolve().parents[1] / "scripts/request_folder_layout.py"
спецификация = importlib.util.spec_from_file_location("проверка_плана_начала", путь_реализации)
модуль = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = модуль
спецификация.loader.exec_module(модуль)
основа = "2026-06-24_12-00-00_MSK_создать-новый-запрос"
аргументы = (основа, "создать-новый-запрос", "Создать новый запрос",
             прежние.THREAD_ID, ["Первое сообщение.", "Второе с {{полем}}."])


@contextlib.contextmanager
def репозиторий():
    фикстура = прежние.RepositoryFixture()
    try:
        фикстура.make_canonical_layout()
        фикстура.write(f"Журнал/{прежние.EARLY}/запрос.md", прежние.request_document(
            прежние.EARLY, previous=None, following=прежние.LATE, legacy=False,
            heading_title="Первый запрос"), mode=0o640)
        фикстура.write(f"Журнал/{прежние.LATE}/запрос.md", прежние.request_document(
            прежние.LATE, previous=прежние.EARLY, following=None, legacy=False,
            heading_title="Vtoroj: особый Запрос!"), mode=0o600)
        фикстура.write("Журнал/README.md", "# Журнал\n\n## Сессии\n\n"
                      f"- [Второй]({прежние.LATE}/отчёт.md)\n"
                      f"- [Первый]({прежние.EARLY}/запрос.md)\n")
        фикстура.commit()
        yield фикстура
    finally:
        фикстура.close()


def снимок(корень, включать_служебные=True):
    return {путь.relative_to(корень).as_posix(): (
                "каталог" if путь.is_dir() else путь.read_bytes(),
                stat.S_IMODE(путь.stat().st_mode))
            for путь in корень.rglob("*")
            if включать_служебные or путь.relative_to(корень).parts[0] != ".git"}


class ПроверкаПланаНачала(unittest.TestCase):
    def test_план_не_пишет_байты_режимы_индекс_или_каталоги(сам):
        with репозиторий() as фикстура:
            до = снимок(фикстура.root)
            файлы, сведения = модуль.подготовить_начало(фикстура.root, *аргументы)
            сам.assertEqual(снимок(фикстура.root), до)
            сам.assertEqual(сведения, {"schema_version": модуль.SCHEMA_VERSION,
                                     "mode": "start", "session_stem": основа,
                                     "idempotent": False})
            сам.assertEqual({файл.path.as_posix() for файл in файлы}, {
                f"Журнал/{основа}/запрос.md", f"Журнал/{основа}/отчёт.md",
                f"Журнал/{прежние.EARLY}/запрос.md", f"Журнал/{прежние.LATE}/запрос.md",
                "Журнал/README.md"})
            сам.assertTrue(all(isinstance(файл, модуль.PreparedFile) for файл in файлы))

    def test_план_даёт_те_же_файлы_и_навигацию_что_обычный_старт(сам):
        with репозиторий() as плановый, репозиторий() as обычный:
            файлы, сведения = модуль.подготовить_начало(плановый.root, *аргументы)
            for файл in файлы:
                плановый.write(файл.path.as_posix(), файл.data, файл.mode)
            результат = модуль.start_session(обычный.root, *аргументы)
            сам.assertEqual(сведения, результат)
            сам.assertEqual(снимок(плановый.root, False), снимок(обычный.root, False))
            запрос = (плановый.root / f"Журнал/{основа}/запрос.md").read_text()
            сам.assertIn(f"../{прежние.EARLY}/запрос.md", запрос)
            сам.assertIn("Vtoroj: особый Запрос!", запрос)
            сам.assertIn("Второе с {{полем}}.", запрос)

    def test_повторный_план_пуст_и_не_пишет(сам):
        with репозиторий() as фикстура:
            модуль.start_session(фикстура.root, *аргументы)
            до = снимок(фикстура.root)
            файлы, сведения = модуль.подготовить_начало(фикстура.root, *аргументы)
            сам.assertEqual(файлы, [])
            сам.assertTrue(сведения["idempotent"])
            сам.assertEqual(снимок(фикстура.root), до)

    def test_конфликт_не_пишет(сам):
        with репозиторий() as фикстура:
            модуль.start_session(фикстура.root, *аргументы)
            до = снимок(фикстура.root)
            with сам.assertRaises(модуль.LayoutError):
                модуль.подготовить_начало(фикстура.root, *аргументы[:-1], ["Иной текст."])
            сам.assertEqual(снимок(фикстура.root), до)

    def test_ошибочные_входы_не_пишут(сам):
        with репозиторий() as фикстура:
            до = снимок(фикстура.root)
            for сообщения in ([], [""], [None]):
                with сам.subTest(сообщения=сообщения), сам.assertRaises(модуль.LayoutError):
                    модуль.подготовить_начало(фикстура.root, *аргументы[:-1], сообщения)
                сам.assertEqual(снимок(фикстура.root), до)


if __name__ == "__main__":
    unittest.main()
