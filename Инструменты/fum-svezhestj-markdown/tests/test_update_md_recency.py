import importlib.util
import hashlib
import contextlib
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "update-md-recency.py"
)

spec = importlib.util.spec_from_file_location("update_md_recency", SCRIPT_PATH)
update_md_recency = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = update_md_recency
spec.loader.exec_module(update_md_recency)


class UpdateMdRecencyTests(unittest.TestCase):
    def test_cli_default_по_прежнему_обновляет_полный_индекс(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            первый, второй = self.write_fixture(root)
            аргументы = ['recency', '--repo-root', str(root), '--no-git',
                         '--now', '2026-06-26T11:00:00+03:00']
            with mock.patch.object(sys, 'argv', аргументы), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(update_md_recency.main(), 0)
            index = root / update_md_recency.INDEX_PATH
            содержимое = index.read_text(encoding='utf-8')
            self.assertIn('старый-файл.md', содержимое)
            self.assertIn('README.md', содержимое)
            self.assertIn('FUM-MD-RECENCY:BEGIN', первый.read_text(encoding='utf-8'))
            self.assertIn('FUM-MD-RECENCY:BEGIN', второй.read_text(encoding='utf-8'))

    def test_адресный_профиль_не_меняет_индекс_и_соседа(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            первый, сосед = self.write_fixture(root)
            index = root / update_md_recency.INDEX_PATH
            index.parent.mkdir()
            index.write_bytes(b'index unchanged\n')
            до = первый.read_bytes()
            сосед_до = сосед.read_bytes()
            вход = [('Документация/старый-файл.md', hashlib.sha256(до).hexdigest())]
            now = update_md_recency.parse_now('2026-06-26T11:00:00+03:00')
            проверка = update_md_recency.обновить_выбранные(root, вход, now=now, check=True)
            self.assertTrue(проверка.errors)
            self.assertEqual(проверка.changed_paths, [])
            self.assertEqual(первый.read_bytes(), до)
            результат = update_md_recency.обновить_выбранные(root, вход, now=now)
            self.assertEqual(результат.errors, [])
            self.assertIn(b'FUM-MD-RECENCY:BEGIN', первый.read_bytes())
            self.assertEqual(сосед.read_bytes(), сосед_до)
            self.assertEqual(index.read_bytes(), b'index unchanged\n')

    def test_адресный_профиль_отклоняет_неверные_цели_до_записи(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            первый, _ = self.write_fixture(root)
            до = первый.read_bytes()
            sha = hashlib.sha256(до).hexdigest()
            путь = 'Документация/старый-файл.md'
            ссылка = root / 'ссылка.md'
            ссылка.symlink_to(первый)
            for список in ([], [(путь, sha), (путь, sha)], [(путь, '0' * 64)],
                           [('несуществующий.md', sha)], [('ссылка.md', sha)],
                           [(str(update_md_recency.INDEX_PATH), sha)],
                           [('Имя.md', sha), ('имя.md', sha)],
                           [('е\u0308.md', sha), ('ё.md', sha)]):
                with self.assertRaises((ValueError, update_md_recency.ProjectFilesError)):
                    update_md_recency.обновить_выбранные(root, список)
                self.assertEqual(первый.read_bytes(), до)

    def test_адресная_неясная_запись_не_повторяется(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            первый, сосед = self.write_fixture(root)
            до, сосед_до = первый.read_bytes(), сосед.read_bytes()
            вызовы = []
            def прервать(путь, текст, **_):
                вызовы.append(путь)
                путь.write_bytes(b'changed')
                raise OSError('синтетический отказ после эффекта')
            with mock.patch.object(Path, 'write_text', autospec=True, side_effect=прервать):
                итог = update_md_recency.обновить_выбранные(
                    root, [('Документация/старый-файл.md', hashlib.sha256(до).hexdigest())])
            self.assertEqual(len(вызовы), 1)
            self.assertTrue(any('UNKNOWN запись' in ошибка for ошибка in итог.errors))
            self.assertEqual(первый.read_bytes(), b'changed')
            self.assertEqual(сосед.read_bytes(), сосед_до)

    def test_повреждённый_второй_файл_отказывает_до_первой_записи(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            первый, второй = self.write_fixture(root)
            второй.write_text('# broken\n<!-- FUM-MD-RECENCY:BEGIN -->\n', encoding='utf-8')
            первый_до, второй_до = первый.read_bytes(), второй.read_bytes()
            итог = update_md_recency.обновить_выбранные(root, [
                ('Документация/старый-файл.md', hashlib.sha256(первый_до).hexdigest()),
                ('README.md', hashlib.sha256(второй_до).hexdigest()),
            ])
            self.assertTrue(итог.errors)
            self.assertEqual(итог.changed_paths, [])
            self.assertEqual(первый.read_bytes(), первый_до)
            self.assertEqual(второй.read_bytes(), второй_до)

    def test_неизвестная_диагностика_preflight_отказывает_до_записи(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            первый, _ = self.write_fixture(root)
            до = первый.read_bytes()
            with mock.patch.object(update_md_recency, 'process_markdown_file',
                                   return_value=(None, ['новая непредвиденная ошибка'], False)):
                итог = update_md_recency.обновить_выбранные(
                    root, [('Документация/старый-файл.md', hashlib.sha256(до).hexdigest())])
            self.assertEqual(итог.errors, ['новая непредвиденная ошибка'])
            self.assertEqual(итог.changed_paths, [])
            self.assertEqual(первый.read_bytes(), до)

    def test_cli_показывает_первую_запись_и_unknown_второй(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            первый, второй = self.write_fixture(root)
            первая_сумма = hashlib.sha256(первый.read_bytes()).hexdigest()
            вторая_сумма = hashlib.sha256(второй.read_bytes()).hexdigest()
            запись = Path.write_text
            вызовы = []
            def частичный_отказ(путь, текст, **ключи):
                вызовы.append(путь)
                if путь == второй:
                    путь.write_bytes(b'changed')
                    raise OSError('синтетический отказ после эффекта')
                return запись(путь, текст, **ключи)
            аргументы = ['recency', '--repo-root', str(root), '--no-git',
                '--выбранный-файл', 'Документация/старый-файл.md', первая_сумма,
                '--выбранный-файл', 'README.md', вторая_сумма]
            ошибки = io.StringIO()
            with mock.patch.object(sys, 'argv', аргументы), \
                 mock.patch.object(Path, 'write_text', autospec=True, side_effect=частичный_отказ), \
                 contextlib.redirect_stderr(ошибки):
                self.assertEqual(update_md_recency.main(), 1)
            self.assertEqual(вызовы, [первый, второй])
            self.assertIn('успешный возврат записи: Документация/старый-файл.md', ошибки.getvalue())
            self.assertIn('UNKNOWN запись README.md', ошибки.getvalue())
            self.assertEqual(второй.read_bytes(), b'changed')

    def test_cli_сообщает_partial_при_дрейфе_второго(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            первый, второй = self.write_fixture(root)
            первая_сумма = hashlib.sha256(первый.read_bytes()).hexdigest()
            вторая_сумма = hashlib.sha256(второй.read_bytes()).hexdigest()
            запись = Path.write_text
            вызовы = []
            def изменить_второй(путь, текст, **ключи):
                вызовы.append(путь)
                результат = запись(путь, текст, **ключи)
                второй.write_bytes(b'drift')
                return результат
            аргументы = ['recency', '--repo-root', str(root), '--no-git',
                '--выбранный-файл', 'Документация/старый-файл.md', первая_сумма,
                '--выбранный-файл', 'README.md', вторая_сумма]
            ошибки = io.StringIO()
            with mock.patch.object(sys, 'argv', аргументы), \
                 mock.patch.object(Path, 'write_text', autospec=True, side_effect=изменить_второй), \
                 contextlib.redirect_stderr(ошибки):
                self.assertEqual(update_md_recency.main(), 1)
            self.assertEqual(вызовы, [первый])
            self.assertIn('PARTIAL:', ошибки.getvalue())
            self.assertIn('успешный возврат записи: Документация/старый-файл.md', ошибки.getvalue())
            self.assertIn('Изменён preimage:', ошибки.getvalue())
            self.assertEqual(второй.read_bytes(), b'drift')

    def write_fixture(self, root: Path) -> tuple[Path, Path]:
        (root / "Документация").mkdir()
        first = root / "Документация" / "старый-файл.md"
        second = root / "README.md"
        first.write_text("# Старый файл\n\nПервый текст.\n", encoding="utf-8")
        second.write_text("# README\n\nВторой текст.\n", encoding="utf-8")
        return first, second

    def test_updates_markdown_metadata_and_sorted_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first, second = self.write_fixture(root)

            initial = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )
            self.assertEqual(initial.errors, [])

            second.write_text(
                second.read_text(encoding="utf-8").replace(
                    "Второй текст.",
                    "Второй обновлённый текст.",
                ),
                encoding="utf-8",
            )
            updated = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T12:00:00+03:00"),
                use_git=False,
            )

            self.assertEqual(updated.errors, [])
            self.assertIn(
                "<!-- last-content-edit: 2026-06-26 11:00:00 MSK -->",
                first.read_text(encoding="utf-8"),
            )
            self.assertIn(
                "<!-- last-content-edit: 2026-06-26 12:00:00 MSK -->",
                second.read_text(encoding="utf-8"),
            )

            index = root / update_md_recency.INDEX_PATH
            index_text = index.read_text(encoding="utf-8")
            self.assertIn("[README.md](../README.md)", index_text)
            self.assertIn("[Документация/старый-файл.md](../Документация/старый-файл.md)", index_text)
            table_lines = [
                line for line in index_text.splitlines() if line.startswith("| ")
            ]
            pipe_positions = {
                tuple(index for index, char in enumerate(line) if char == "|")
                for line in table_lines[:4]
            }
            self.assertEqual(len(pipe_positions), 1)
            self.assertRegex(table_lines[0], r"^\| Файл\s+\| Последнее содержательное редактирование \|$")
            self.assertLess(
                index_text.index("[README.md]"),
                index_text.index("[Документация/старый-файл.md]"),
            )

    def test_repeated_update_preserves_clean_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first, _second = self.write_fixture(root)

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )
            self.assertEqual(result.errors, [])
            before = first.read_text(encoding="utf-8")

            repeated = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-27T12:00:00+03:00"),
                use_git=False,
            )
            after = first.read_text(encoding="utf-8")

            self.assertEqual(repeated.errors, [])
            self.assertEqual(repeated.changed_paths, [])
            self.assertEqual(before, after)

    def test_служебный_блок_запусков_не_старит_отчёт_и_индекс(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            каталог_сессии = корень / "Журнал" / "2026-08-14_12-00-00_MSK_проверить-свежесть"
            каталог_сессии.mkdir(parents=True)
            отчёт = каталог_сессии / "отчёт.md"
            открытый_блок = (
                "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->\n"
                "Запусков пока нет.\n"
                "<!-- FUM-CHECK-RUNS:END -->"
            )
            отчёт.write_text(
                f"# Отчёт\n\nСодержательный итог.\n\n{открытый_блок}\n",
                encoding="utf-8",
            )
            первый = update_md_recency.update_repository(
                корень,
                now=update_md_recency.parse_now("2026-08-14T12:00:00+03:00"),
                use_git=False,
            )
            сам.assertEqual(первый.errors, [])
            индекс = корень / update_md_recency.INDEX_PATH
            исходный_индекс = индекс.read_bytes()
            закрытый_блок = (
                "<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; "
                f"sha256=sha256:{'a' * 64} -->\n"
                "| Проверка | Итог |\n"
                "| --------- | ---- |\n"
                "| Набор    | 2 с  |\n"
                "<!-- FUM-CHECK-RUNS:END -->"
            )
            отчёт.write_text(
                отчёт.read_text(encoding="utf-8").replace(
                    открытый_блок,
                    закрытый_блок,
                ),
                encoding="utf-8",
            )

            проверка = update_md_recency.update_repository(
                корень,
                now=update_md_recency.parse_now("2026-08-14T13:00:00+03:00"),
                check=True,
                use_git=False,
            )

            сам.assertEqual(проверка.errors, [])
            сам.assertEqual(проверка.changed_paths, [])
            сам.assertEqual(индекс.read_bytes(), исходный_индекс)
            сам.assertIn(
                "<!-- last-content-edit: 2026-08-14 12:00:00 MSK -->",
                отчёт.read_text(encoding="utf-8"),
            )

    def test_исторический_полный_хэш_отчёта_остаётся_читаемым(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            отчёт = корень / "Журнал" / "2026-08-14_12-00-00_MSK_история" / "отчёт.md"
            отчёт.parent.mkdir(parents=True)
            содержание = (
                "# Отчёт\n\nИтог.\n\n"
                "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->\n"
                "Запусков пока нет.\n"
                "<!-- FUM-CHECK-RUNS:END -->\n"
            )
            полный_хэш = update_md_recency.content_digest(
                update_md_recency.canonical_content(содержание)
            )
            отчёт.write_text(
                update_md_recency.attach_recency_block(
                    содержание,
                    "2026-08-14 12:00:00 MSK",
                    полный_хэш,
                ),
                encoding="utf-8",
            )
            байты_до = отчёт.read_bytes()

            _, ошибки, изменён = update_md_recency.process_markdown_file(
                отчёт,
                корень,
                set(),
                "2026-08-15 12:00:00 MSK",
                False,
                False,
            )

            сам.assertEqual(ошибки, [])
            сам.assertFalse(изменён)
            сам.assertEqual(отчёт.read_bytes(), байты_до)

    def test_повреждённый_и_повторный_блок_запусков_отклоняется(сам):
        открытое_начало = (
            "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->"
        )
        конец = "<!-- FUM-CHECK-RUNS:END -->"
        варианты = (
            f"# Отчёт\n\n{открытое_начало}\nБез конца.\n",
            f"# Отчёт\n\n{открытое_начало}\nПервый.\n{конец}\n\n{открытое_начало}\nВторой.\n{конец}\n",
        )
        for номер, содержание in enumerate(варианты):
            with сам.subTest(номер=номер), tempfile.TemporaryDirectory() as временный_каталог:
                корень = Path(временный_каталог)
                отчёт = корень / "Журнал" / "2026-08-14_12-00-00_MSK_повреждение" / "отчёт.md"
                отчёт.parent.mkdir(parents=True)
                отчёт.write_text(содержание, encoding="utf-8")

                _, ошибки, _ = update_md_recency.process_markdown_file(
                    отчёт,
                    корень,
                    set(),
                    "2026-08-15 12:00:00 MSK",
                    True,
                    False,
                )

                сам.assertTrue(
                    any("malformed managed test-run block" in ошибка for ошибка in ошибки),
                    ошибки,
                )

    def test_ignored_build_and_cache_markdown_files_are_never_rewritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            ignored_files = {
                ".build/checkouts/vendor/README.md": "# Vendor build checkout\n",
                ".swiftpm/cache/README.md": "# SwiftPM cache\n",
                ".obsidian/cache/README.md": "# Obsidian cache\n",
                ".obsidian/plugins/local/README.md": "# Obsidian plugin\n",
                "__pycache__/README.md": "# Python cache\n",
            }
            for relative, content in ignored_files.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )

            self.assertEqual(result.errors, [])
            index_text = (root / update_md_recency.INDEX_PATH).read_text(
                encoding="utf-8"
            )
            for relative, content in ignored_files.items():
                with self.subTest(relative=relative):
                    self.assertEqual(
                        (root / relative).read_text(encoding="utf-8"),
                        content,
                    )
                    self.assertNotIn(relative, index_text)

    def test_check_reports_stale_metadata_after_content_change(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first, _second = self.write_fixture(root)
            update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )

            first.write_text(
                first.read_text(encoding="utf-8").replace(
                    "Первый текст.",
                    "Первый изменённый текст.",
                ),
                encoding="utf-8",
            )
            checked = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T12:00:00+03:00"),
                check=True,
                use_git=False,
            )

            self.assertTrue(
                any("stale recency metadata: Документация/старый-файл.md" in error for error in checked.errors),
                checked.errors,
            )

    def test_rejects_index_symlink_into_build_without_rewriting_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_fixture(root)
            target = root / ".build" / "vendor-index.md"
            target.parent.mkdir()
            original = "# Vendor index\n"
            target.write_text(original, encoding="utf-8")
            index = root / update_md_recency.INDEX_PATH
            index.parent.mkdir()
            index.symlink_to("../.build/vendor-index.md")

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T11:00:00+03:00"),
                use_git=False,
            )

            self.assertTrue(
                any("symlink" in error for error in result.errors),
                result.errors,
            )
            self.assertEqual(target.read_text(encoding="utf-8"), original)

    def test_initializes_clean_tracked_file_from_git_history(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tracked = root / "README.md"
            tracked.write_text("# README\n\nИсторический текст.\n", encoding="utf-8")
            subprocess.run(["git", "init"], cwd=root, check=True, stdout=subprocess.PIPE)
            subprocess.run(["git", "add", "README.md"], cwd=root, check=True)
            env = {
                **os.environ,
                "GIT_AUTHOR_DATE": "2026-01-02T03:04:05+03:00",
                "GIT_COMMITTER_DATE": "2026-01-02T03:04:05+03:00",
            }
            subprocess.run(
                [
                    "git",
                    "-c",
                    "user.name=FUM Test",
                    "-c",
                    "user.email=fum-test@example.invalid",
                    "commit",
                    "-m",
                    "initial",
                ],
                cwd=root,
                check=True,
                env=env,
                stdout=subprocess.PIPE,
            )

            result = update_md_recency.update_repository(
                root,
                now=update_md_recency.parse_now("2026-06-26T12:00:00+03:00"),
            )

            self.assertEqual(result.errors, [])
            self.assertIn(
                "<!-- last-content-edit: 2026-01-02 03:04:05 MSK -->",
                tracked.read_text(encoding="utf-8"),
            )


if __name__ == "__main__":
    unittest.main()
