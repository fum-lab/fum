"""Повторные ссылки сохраняют проверку регистра и замечают изменения дерева."""

import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import test_check_session_coherence as основа

проверка = основа.check_session_coherence


class ПроверкиКаталоговСсылок(unittest.TestCase):
    def test_каталог_перечисляется_один_раз_в_пределах_вызова(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            цели = корень / "цели"
            цели.mkdir()
            for имя in ("один.md", "два.md"):
                (цели / имя).write_text("Цель", encoding="utf-8")
            документ = корень / "источник.md"
            документ.write_text("[Один](цели/один.md)\n[Два](цели/два.md)\n" * 8,
                                encoding="utf-8")
            счётчики = {}
            исходное = Path.iterdir

            def перечислить(путь):
                счётчики[путь] = счётчики.get(путь, 0) + 1
                return исходное(путь)

            with mock.patch.object(Path, "iterdir", перечислить):
                сам.assertEqual(проверка.validate_markdown_links({документ}, корень), [])
                сам.assertEqual(счётчики, {корень: 1, цели: 1})
                сам.assertEqual(проверка.validate_markdown_links({документ}, корень), [])
                сам.assertEqual(счётчики, {корень: 2, цели: 2})

    def test_создание_удаление_и_смена_регистра_между_ссылками(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            документ = корень / "источник.md"
            документ.write_text("Источник", encoding="utf-8")
            цель = корень / "цель.md"

            def ссылки(путь):
                yield проверка.MarkdownLink(путь, 1, "цель.md")
                цель.write_text("Цель", encoding="utf-8")
                yield проверка.MarkdownLink(путь, 2, "цель.md")
                цель.unlink()
                yield проверка.MarkdownLink(путь, 3, "цель.md")
                цель.write_text("Цель", encoding="utf-8")
                цель.rename(корень / "Цель.md")
                yield проверка.MarkdownLink(путь, 4, "цель.md")

            with mock.patch.object(проверка, "iter_markdown_links", ссылки):
                ошибки = проверка.validate_markdown_links({документ}, корень)
            сам.assertEqual(ошибки, [
                "broken Markdown link in источник.md:1: цель.md",
                "broken Markdown link in источник.md:3: цель.md",
                "Markdown link case mismatch in источник.md:4: цель.md points to Цель.md",
            ])

    def test_замена_каталога_и_превращение_в_файл(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            документ = корень / "источник.md"
            документ.write_text("Источник", encoding="utf-8")
            цели = корень / "цели"
            цели.mkdir()
            (цели / "пример.md").write_text("Цель", encoding="utf-8")

            def ссылки(путь):
                yield проверка.MarkdownLink(путь, 1, "цели/пример.md")
                цели.rename(корень / "прежние")
                цели.mkdir()
                yield проверка.MarkdownLink(путь, 2, "цели/пример.md")
                цели.rmdir()
                цели.write_text("Теперь файл", encoding="utf-8")
                yield проверка.MarkdownLink(путь, 3, "цели/пример.md")

            with mock.patch.object(проверка, "iter_markdown_links", ссылки):
                ошибки = проверка.validate_markdown_links({документ}, корень)
            сам.assertEqual(ошибки, [
                "broken Markdown link in источник.md:2: цели/пример.md",
                "broken Markdown link in источник.md:3: цели/пример.md",
            ])

    def test_точный_регистр_имеет_приоритет_неоднозначность_отклоняется(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            # Такой набор имён не создаётся на нечувствительной к регистру ФС.
            with mock.patch.object(Path, "iterdir", return_value=iter([
                корень / "ПРИМЕР.md", корень / "пример.md",
            ])):
                сам.assertEqual(проверка.actual_case_path(корень / "пример.md", корень),
                                корень / "пример.md")
            with mock.patch.object(Path, "iterdir", return_value=iter([
                корень / "ПРИМЕР.md", корень / "пример.md",
            ])):
                сам.assertIsNone(проверка.actual_case_path(корень / "Пример.md", корень))

    def test_изменение_во_время_перечисления_не_закрепляет_старый_состав(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            документ = корень / "источник.md"
            документ.write_text("[Старый](старый.md)\n[Новый](новый.md)\n", encoding="utf-8")
            (корень / "старый.md").write_text("Цель", encoding="utf-8")
            исходное = Path.iterdir
            изменён = False

            def перечислить(путь):
                nonlocal изменён
                состав = list(исходное(путь))
                if not изменён:
                    изменён = True
                    (корень / "новый.md").write_text("Новая цель", encoding="utf-8")
                yield from состав

            with mock.patch.object(Path, "iterdir", перечислить):
                сам.assertEqual(проверка.validate_markdown_links({документ}, корень), [])

    def test_ошибка_метаданных_не_разрешает_старый_положительный_ответ(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            цель = корень / "цель.md"
            цель.write_text("Цель", encoding="utf-8")
            кэш = {}
            сам.assertEqual(проверка.actual_case_path(цель, корень, кэш), цель)
            with mock.patch.object(Path, "stat", side_effect=PermissionError):
                сам.assertIsNone(проверка.actual_case_path(цель, корень, кэш))
            сам.assertEqual(кэш, {})
            сам.assertEqual(проверка.actual_case_path(цель, корень, кэш), цель)

    def test_ошибка_перечисления_после_изменения_не_использует_старые_имена(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            цель = корень / "цель.md"
            цель.write_text("Цель", encoding="utf-8")
            кэш = {}
            сам.assertEqual(проверка.actual_case_path(цель, корень, кэш), цель)
            цель.unlink()
            with mock.patch.object(Path, "iterdir", side_effect=PermissionError):
                сам.assertIsNone(проверка.actual_case_path(цель, корень, кэш))
            сам.assertEqual(кэш, {})
            сам.assertIsNone(проверка.actual_case_path(цель, корень, кэш))

    def test_восстановленное_время_изменения_не_скрывает_переименование(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            документ = корень / "источник.md"
            документ.write_text("Источник", encoding="utf-8")
            цель = корень / "старый.md"
            цель.write_text("Цель", encoding="utf-8")

            def ссылки(путь):
                yield проверка.MarkdownLink(путь, 1, "старый.md")
                прежнее = корень.stat()
                цель.rename(корень / "новый.md")
                os.utime(корень, ns=(прежнее.st_atime_ns, прежнее.st_mtime_ns))
                сам.assertEqual(корень.stat().st_mtime_ns, прежнее.st_mtime_ns)
                yield проверка.MarkdownLink(путь, 2, "новый.md")

            with mock.patch.object(проверка, "iter_markdown_links", ссылки):
                сам.assertEqual(проверка.validate_markdown_links({документ}, корень), [])


if __name__ == "__main__":
    unittest.main()
