import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


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
            self.write_note(root, "Документация/сегодня.md", "2026-07-01 10:00:00 MSK")
            self.write_note(root, "Журнал/позавчера.md", "2026-06-29 10:00:00 MSK")
            self.write_note(root, "Глоссарий/неделя.md", "2026-06-26 10:00:00 MSK")
            self.write_note(root, "README.md", "2026-05-01 10:00:00 MSK")

            result = build_obsidian_graph_recency.update_graph(
                root,
                today=build_obsidian_graph_recency.parse_date("2026-07-01"),
            )

            self.assertEqual(result.errors, [])
            self.assertEqual(result.changed, True)

            data = json.loads(graph.read_text(encoding="utf-8"))
            self.assertEqual(data["scale"], 0.5)
            self.assertEqual(data["collapse-color-groups"], False)
            self.assertEqual(len(data["colorGroups"]), 4)
            queries = [group["query"] for group in data["colorGroups"]]
            self.assertIn('path:"Документация/сегодня.md"', queries[0])
            self.assertIn('path:"Журнал/позавчера.md"', queries[1])
            self.assertIn('path:"Глоссарий/неделя.md"', queries[2])
            self.assertIn('path:"README.md"', queries[3])
            self.assertEqual(data["colorGroups"][0]["color"]["rgb"], 0xD7263D)
            self.assertEqual(data["colorGroups"][3]["color"]["rgb"], 0x457B9D)

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


if __name__ == "__main__":
    unittest.main()
