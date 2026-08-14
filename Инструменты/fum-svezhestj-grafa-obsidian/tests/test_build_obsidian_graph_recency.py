import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "build-obsidian-graph-recency.py"
)

spec = importlib.util.spec_from_file_location("build_obsidian_graph_recency", SCRIPT_PATH)
build_obsidian_graph_recency = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = build_obsidian_graph_recency
spec.loader.exec_module(build_obsidian_graph_recency)


class BuildObsidianGraphRecencyTests(unittest.TestCase):
    def write_note(self, root: Path, relative: str, timestamp: str) -> Path:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            "\n".join(
                [
                    f"# {path.stem}",
                    "",
                    "Текст.",
                    "",
                    "<!-- FUM-MD-RECENCY:BEGIN -->",
                    f"<!-- last-content-edit: {timestamp} -->",
                    "<!-- content-sha256: sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef -->",
                    "<!-- FUM-MD-RECENCY:END -->",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        return path

    def write_graph(self, root: Path) -> Path:
        graph = root / ".obsidian" / "graph.json"
        graph.parent.mkdir(parents=True)
        graph.write_text(
            json.dumps(
                {
                    "collapse-filter": True,
                    "collapse-color-groups": True,
                    "colorGroups": [
                        {
                            "query": "",
                            "color": {"a": 1, "rgb": 14048348},
                        }
                    ],
                    "scale": 0.5,
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        return graph

    def инициализировать_репозиторий(сам, корень: Path) -> None:
        subprocess.run(
            ["git", "init"],
            cwd=корень,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def test_updates_graph_color_groups_from_recency_buckets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            graph = self.write_graph(root)
            notes = [
                ("Документация/сегодня.md", "2026-07-01 10:00:00 MSK", 0xD7263D),
                ("Документация/вчера.md", "2026-06-30 10:00:00 MSK", 0xE94F37),
                ("Документация/позавчера.md", "2026-06-29 10:00:00 MSK", 0xF77F00),
                ("Документация/три-дня.md", "2026-06-28 10:00:00 MSK", 0xF4A261),
                ("Документация/пять-дней.md", "2026-06-26 10:00:00 MSK", 0xE9C46A),
                ("Документация/шесть-дней.md", "2026-06-25 10:00:00 MSK", 0xA7C957),
                ("Документация/семь-дней.md", "2026-06-24 10:00:00 MSK", 0x74C69D),
                ("Документация/восемь-дней.md", "2026-06-23 10:00:00 MSK", 0x4ECDC4),
                ("Документация/девять-дней.md", "2026-06-22 10:00:00 MSK", 0x277DA1),
                ("README.md", "2026-06-21 10:00:00 MSK", 0x457B9D),
            ]
            for relative, timestamp, _color in notes:
                self.write_note(root, relative, timestamp)

            result = build_obsidian_graph_recency.update_graph(
                root,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
            )

            self.assertEqual(result.errors, [])
            self.assertEqual(result.changed, True)

            data = json.loads(graph.read_text(encoding="utf-8"))
            self.assertEqual(data["scale"], 0.5)
            self.assertEqual(data["collapse-color-groups"], False)
            self.assertEqual(len(data["colorGroups"]), 10)
            self.assertEqual(
                (root / build_obsidian_graph_recency.REFERENCE_DATE_PATH).read_text(
                    encoding="utf-8"
                ),
                "2026-07-01\n",
            )
            queries = [group["query"] for group in data["colorGroups"]]
            colors = [group["color"]["rgb"] for group in data["colorGroups"]]
            for index, (relative, _timestamp, color) in enumerate(notes):
                self.assertIn(f'path:"{relative}"', queries[index])
                self.assertEqual(colors[index], color)

    def test_обычное_обновление_создаёт_локальную_тепловую_карту_без_каталога_обсидиана(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_note(корень, "README.md", "2026-07-01 10:00:00 MSK")
            каталог_обсидиана = корень / ".obsidian"
            сам.assertFalse(каталог_обсидиана.exists())

            результат = build_obsidian_graph_recency.update_graph(
                корень,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
            )

            сам.assertEqual(результат.errors, [])
            сам.assertTrue(результат.changed)
            граф = каталог_обсидиана / "graph.json"
            опорная_дата = каталог_обсидиана / "fum-recency-reference-date"
            сам.assertTrue(граф.is_file())
            сам.assertEqual(опорная_дата.read_text(encoding="utf-8"), "2026-07-01\n")
            данные = json.loads(граф.read_text(encoding="utf-8"))
            сам.assertEqual(данные["collapse-color-groups"], False)
            сам.assertEqual(
                данные["colorGroups"],
                [
                    {
                        "query": 'path:"README.md"',
                        "color": {"a": 1, "rgb": 0xD7263D},
                    }
                ],
            )

    def test_проверка_пропускает_отсутствующий_локальный_каталог_обсидиана_без_записи(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_note(корень, "README.md", "2026-07-01 10:00:00 MSK")
            каталог_обсидиана = корень / ".obsidian"
            сам.assertFalse(каталог_обсидиана.exists())

            результат = build_obsidian_graph_recency.update_graph(
                корень,
                check=True,
            )

            сам.assertEqual(результат.errors, [])
            сам.assertFalse(результат.changed)
            сам.assertFalse(каталог_обсидиана.exists())

            вызов = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(корень),
                    "--check",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            сам.assertEqual(вызов.returncode, 0, вызов.stderr)
            сам.assertIn("проверка пропущена", вызов.stdout)
            сам.assertFalse(каталог_обсидиана.exists())

    def test_проверка_учёта_требует_точное_корневое_правило_игнорирования(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.инициализировать_репозиторий(корень)
            (корень / ".gitignore").write_text(".obsidian/cache/\n", encoding="utf-8")

            результат = build_obsidian_graph_recency.update_graph(корень, check=True)

            сам.assertTrue(
                any(
                    build_obsidian_graph_recency.КОРНЕВОЕ_ПРАВИЛО_ИГНОРИРОВАНИЯ_ОБСИДИАНА
                    in ошибка
                    for ошибка in результат.errors
                ),
                результат.errors,
            )

    def test_проверка_учёта_отклоняет_повторное_включение_корневого_обсидиана(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.инициализировать_репозиторий(корень)
            правило = (
                build_obsidian_graph_recency.КОРНЕВОЕ_ПРАВИЛО_ИГНОРИРОВАНИЯ_ОБСИДИАНА
            )
            (корень / ".gitignore").write_text(
                f"{правило}\n!{правило}\n!{правило}**\n",
                encoding="utf-8",
            )
            локальный_файл = корень / ".obsidian/локальный-маркер.tmp"
            локальный_файл.parent.mkdir()
            локальный_файл.write_text("локальное состояние\n", encoding="utf-8")
            проверка_игнорирования = subprocess.run(
                [
                    "git",
                    "check-ignore",
                    "--quiet",
                    "--no-index",
                    "--",
                    str(локальный_файл.relative_to(корень)),
                ],
                cwd=корень,
                check=False,
                capture_output=True,
                text=True,
            )

            результат = build_obsidian_graph_recency.update_graph(корень, check=True)

            сам.assertEqual(
                проверка_игнорирования.returncode,
                1,
                проверка_игнорирования.stderr,
            )
            сам.assertTrue(
                any(".obsidian" in ошибка for ошибка in результат.errors),
                результат.errors,
            )

    def test_проверка_учёта_отклоняет_отслеживаемый_путь_обсидиана(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.инициализировать_репозиторий(корень)
            правило = (
                build_obsidian_graph_recency.КОРНЕВОЕ_ПРАВИЛО_ИГНОРИРОВАНИЯ_ОБСИДИАНА
            )
            (корень / ".gitignore").write_text(
                f"{правило}\n",
                encoding="utf-8",
            )
            граф = сам.write_graph(корень)
            (корень / ".obsidian/fum-recency-reference-date").write_text(
                "2026-07-01\n",
                encoding="utf-8",
            )
            subprocess.run(
                ["git", "add", "-f", "--", str(граф.relative_to(корень))],
                cwd=корень,
                check=True,
            )

            результат = build_obsidian_graph_recency.update_graph(
                корень,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
                check=True,
            )

            сам.assertTrue(
                any("отслеживаем" in ошибка for ошибка in результат.errors),
                результат.errors,
            )

    def test_проверка_графа_без_опорной_даты_сообщает_ошибку_и_не_пишет(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            граф = сам.write_graph(корень)
            сам.write_note(корень, "README.md", "2026-07-01 10:00:00 MSK")
            исходный_граф = граф.read_bytes()
            опорная_дата = корень / build_obsidian_graph_recency.REFERENCE_DATE_PATH
            сам.assertFalse(опорная_дата.exists())

            вызов = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(корень),
                    "--check",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            сам.assertNotEqual(вызов.returncode, 0)
            сам.assertIn(".obsidian/fum-recency-reference-date", вызов.stderr)
            сам.assertEqual(граф.read_bytes(), исходный_граф)
            сам.assertFalse(опорная_дата.exists())

    def test_проверка_опорной_даты_без_графа_сообщает_ошибку_и_не_пишет(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_note(корень, "README.md", "2026-07-01 10:00:00 MSK")
            опорная_дата = корень / build_obsidian_graph_recency.REFERENCE_DATE_PATH
            опорная_дата.parent.mkdir(parents=True)
            исходная_опорная_дата = b"2026-07-01\n"
            опорная_дата.write_bytes(исходная_опорная_дата)
            граф = корень / build_obsidian_graph_recency.GRAPH_PATH
            сам.assertFalse(граф.exists())

            вызов = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(корень),
                    "--check",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            сам.assertNotEqual(вызов.returncode, 0)
            сам.assertIn(".obsidian/graph.json", вызов.stderr)
            сам.assertFalse(граф.exists())
            сам.assertEqual(опорная_дата.read_bytes(), исходная_опорная_дата)

    def test_проверка_неверного_формата_графа_сообщает_ошибку_и_не_пишет(
        сам,
    ) -> None:
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_note(корень, "README.md", "2026-07-01 10:00:00 MSK")
            граф = корень / build_obsidian_graph_recency.GRAPH_PATH
            граф.parent.mkdir(parents=True)
            исходный_граф = "{ неверный JSON\n".encode("utf-8")
            граф.write_bytes(исходный_граф)
            опорная_дата = корень / build_obsidian_graph_recency.REFERENCE_DATE_PATH
            исходная_опорная_дата = b"2026-07-01\n"
            опорная_дата.write_bytes(исходная_опорная_дата)

            вызов = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(корень),
                    "--check",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            сам.assertNotEqual(вызов.returncode, 0)
            сам.assertIn("invalid Obsidian graph JSON", вызов.stderr)
            сам.assertEqual(граф.read_bytes(), исходный_граф)
            сам.assertEqual(опорная_дата.read_bytes(), исходная_опорная_дата)

    def test_check_reports_stale_graph(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_graph(root)
            self.write_note(root, "README.md", "2026-07-01 10:00:00 MSK")

            result = build_obsidian_graph_recency.update_graph(
                root,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
                check=True,
            )

            self.assertIn("stale Obsidian graph recency heatmap: .obsidian/graph.json", result.errors)

    def test_check_uses_saved_reference_date_instead_of_current_day(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            graph = self.write_graph(root)
            self.write_note(root, "README.md", "2026-07-01 10:00:00 MSK")
            first_day = build_obsidian_graph_recency.parse_date("2026-07-01")
            next_day = build_obsidian_graph_recency.parse_date("2026-07-02")

            updated = build_obsidian_graph_recency.update_graph(
                root,
                today=first_day,
            )
            graph_data = json.loads(graph.read_text(encoding="utf-8"))
            graph.write_text(
                json.dumps(graph_data, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            with mock.patch.object(
                build_obsidian_graph_recency,
                "today_msk",
                return_value=next_day,
            ):
                checked = build_obsidian_graph_recency.update_graph(
                    root,
                    check=True,
                )

            self.assertEqual(updated.errors, [])
            self.assertEqual(checked.errors, [])
            self.assertFalse(checked.changed)
            self.assertEqual(
                (root / build_obsidian_graph_recency.REFERENCE_DATE_PATH).read_text(
                    encoding="utf-8"
                ),
                "2026-07-01\n",
            )

    def test_explicit_next_day_rebuilds_and_saves_reference_date(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            graph = self.write_graph(root)
            self.write_note(root, "README.md", "2026-07-01 10:00:00 MSK")

            first_update = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                    "--today",
                    "2026-07-01",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            stable_check = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                    "--check",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            stale = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                    "--today",
                    "2026-07-02",
                    "--check",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            updated = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                    "--today",
                    "2026-07-02",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(first_update.returncode, 0, first_update.stderr)
            self.assertEqual(stable_check.returncode, 0, stable_check.stderr)
            self.assertNotEqual(stale.returncode, 0)
            self.assertIn(
                "stale Obsidian graph recency heatmap: .obsidian/graph.json",
                stale.stderr,
            )
            self.assertEqual(updated.returncode, 0, updated.stderr)
            data = json.loads(graph.read_text(encoding="utf-8"))
            self.assertEqual(
                (root / build_obsidian_graph_recency.REFERENCE_DATE_PATH).read_text(
                    encoding="utf-8"
                ),
                "2026-07-02\n",
            )
            self.assertEqual(data["colorGroups"][0]["color"]["rgb"], 0xE94F37)

    def test_ignored_build_and_cache_markdown_files_are_not_graph_inputs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            graph = self.write_graph(root)
            self.write_note(root, "README.md", "2026-07-01 10:00:00 MSK")
            ignored_files = {
                ".build/checkouts/vendor/README.md": "# Vendor build checkout\n",
                ".swiftpm/cache/README.md": "# SwiftPM cache\n",
                ".obsidian/cache/README.md": "# Obsidian cache\n",
                ".obsidian/plugins/local/README.md": "# Obsidian plugin\n",
            }
            for relative, content in ignored_files.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")

            result = build_obsidian_graph_recency.update_graph(
                root,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
            )

            self.assertEqual(result.errors, [])
            graph_text = graph.read_text(encoding="utf-8")
            for relative, content in ignored_files.items():
                with self.subTest(relative=relative):
                    self.assertEqual(
                        (root / relative).read_text(encoding="utf-8"),
                        content,
                    )
                    self.assertNotIn(relative, graph_text)

    def test_cli_check_passes_after_update(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_graph(root)
            self.write_note(root, "README.md", "2026-07-01 10:00:00 MSK")

            updated = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                    "--today",
                    "2026-07-01",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            checked = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(root),
                    "--today",
                    "2026-07-01",
                    "--check",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(updated.returncode, 0, updated.stderr)
            self.assertEqual(checked.returncode, 0, checked.stderr)

    def test_rejects_graph_symlink_into_build_without_rewriting_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            graph = self.write_graph(root)
            graph.unlink()
            target = root / ".build" / "vendor-graph.json"
            target.parent.mkdir()
            original = "{}\n"
            target.write_text(original, encoding="utf-8")
            graph.symlink_to("../.build/vendor-graph.json")
            self.write_note(root, "README.md", "2026-07-01 10:00:00 MSK")

            result = build_obsidian_graph_recency.update_graph(
                root,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
            )

            self.assertTrue(
                any("project output path" in error for error in result.errors),
                result.errors,
            )
            self.assertEqual(target.read_text(encoding="utf-8"), original)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            graph = self.write_graph(root)
            original_graph = graph.read_text(encoding="utf-8")
            target = root / ".build" / "vendor-reference-date"
            target.parent.mkdir()
            original = "2026-01-01\n"
            target.write_text(original, encoding="utf-8")
            reference_date = root / build_obsidian_graph_recency.REFERENCE_DATE_PATH
            reference_date.symlink_to("../.build/vendor-reference-date")
            self.write_note(root, "README.md", "2026-07-01 10:00:00 MSK")

            result = build_obsidian_graph_recency.update_graph(
                root,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
            )

            self.assertTrue(
                any("project output path" in error for error in result.errors),
                result.errors,
            )
            self.assertEqual(target.read_text(encoding="utf-8"), original)
            self.assertEqual(graph.read_text(encoding="utf-8"), original_graph)


if __name__ == "__main__":
    unittest.main()
