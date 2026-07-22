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
