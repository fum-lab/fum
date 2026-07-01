#!/usr/bin/env python3
"""Build Obsidian graph color groups as a recency heatmap."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo


MSK = ZoneInfo("Europe/Moscow")
GRAPH_PATH = Path(".obsidian/graph.json")
RECENCY_RE = re.compile(
    r"<!-- last-content-edit: "
    r"(?P<date>\d{4}-\d{2}-\d{2}) "
    r"\d{2}:\d{2}:\d{2} MSK -->"
)


@dataclass(frozen=True)
class RecencyRecord:
    path: Path
    rel_path: str
    edit_date: date


@dataclass(frozen=True)
class RecencyBucket:
    name: str
    min_age_days: int
    max_age_days: int | None
    color_rgb: int


@dataclass(frozen=True)
class GraphUpdateResult:
    errors: list[str]
    changed: bool


BUCKETS = [
    RecencyBucket("0 days", 0, 0, 0xD7263D),
    RecencyBucket("1 day", 1, 1, 0xE94F37),
    RecencyBucket("2 days", 2, 2, 0xF77F00),
    RecencyBucket("3-4 days", 3, 4, 0xF4A261),
    RecencyBucket("5 days", 5, 5, 0xE9C46A),
    RecencyBucket("6 days", 6, 6, 0xA7C957),
    RecencyBucket("7 days", 7, 7, 0x74C69D),
    RecencyBucket("8 days", 8, 8, 0x4ECDC4),
    RecencyBucket("9 days", 9, 9, 0x277DA1),
    RecencyBucket("10+ days", 10, None, 0x457B9D),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate that .obsidian/graph.json already contains the generated heatmap.",
    )
    parser.add_argument(
        "--today",
        help="Override today's date as YYYY-MM-DD. Mainly for tests.",
    )
    return parser.parse_args()


def parse_date(value: str) -> date:
    return date.fromisoformat(value)


def today_msk() -> date:
    return datetime.now(MSK).date()


def repo_relative(path: Path, repo_root: Path) -> str:
    return path.resolve().relative_to(repo_root.resolve()).as_posix()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def find_markdown_paths(repo_root: Path) -> list[Path]:
    paths: list[Path] = []
    for path in repo_root.rglob("*.md"):
        if ".git" in path.parts:
            continue
        if path.is_file():
            paths.append(path.resolve())
    return sorted(paths, key=lambda path: repo_relative(path, repo_root))


def parse_recency_record(path: Path, repo_root: Path) -> tuple[RecencyRecord | None, str | None]:
    rel_path = repo_relative(path, repo_root)
    match = RECENCY_RE.search(read_text(path))
    if not match:
        return None, f"missing recency metadata: {rel_path}"

    try:
        edit_date = parse_date(match.group("date"))
    except ValueError:
        return None, f"invalid recency date: {rel_path}"

    return RecencyRecord(path=path, rel_path=rel_path, edit_date=edit_date), None


def collect_recency_records(repo_root: Path) -> tuple[list[RecencyRecord], list[str]]:
    records: list[RecencyRecord] = []
    errors: list[str] = []
    for path in find_markdown_paths(repo_root):
        record, error = parse_recency_record(path, repo_root)
        if error is not None:
            errors.append(error)
            continue
        if record is not None:
            records.append(record)
    return records, errors


def age_days(record: RecencyRecord, current_date: date) -> int:
    return max(0, (current_date - record.edit_date).days)


def bucket_for_record(record: RecencyRecord, current_date: date) -> RecencyBucket:
    age = age_days(record, current_date)
    for bucket in BUCKETS:
        if age < bucket.min_age_days:
            continue
        if bucket.max_age_days is None or age <= bucket.max_age_days:
            return bucket
    return BUCKETS[-1]


def escape_obsidian_query_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def render_path_query(paths: list[str]) -> str:
    terms = [f'path:"{escape_obsidian_query_string(path)}"' for path in sorted(paths)]
    if len(terms) == 1:
        return terms[0]
    return f"({' OR '.join(terms)})"


def build_color_groups(records: list[RecencyRecord], current_date: date) -> list[dict[str, object]]:
    grouped: dict[RecencyBucket, list[str]] = {bucket: [] for bucket in BUCKETS}
    for record in records:
        grouped[bucket_for_record(record, current_date)].append(record.rel_path)

    groups: list[dict[str, object]] = []
    for bucket in BUCKETS:
        paths = grouped[bucket]
        if not paths:
            continue
        groups.append(
            {
                "query": render_path_query(paths),
                "color": {
                    "a": 1,
                    "rgb": bucket.color_rgb,
                },
            }
        )
    return groups


def read_graph(path: Path) -> tuple[dict[str, object] | None, list[str]]:
    if not path.exists():
        return None, [f"missing Obsidian graph settings: {GRAPH_PATH.as_posix()}"]
    try:
        data = json.loads(read_text(path))
    except json.JSONDecodeError as exc:
        return None, [f"invalid Obsidian graph JSON: {exc}"]
    if not isinstance(data, dict):
        return None, ["Obsidian graph JSON must be an object"]
    return data, []


def expected_graph_data(
    graph_data: dict[str, object],
    records: list[RecencyRecord],
    current_date: date,
) -> dict[str, object]:
    expected = dict(graph_data)
    expected["collapse-color-groups"] = False
    expected["colorGroups"] = build_color_groups(records, current_date)
    return expected


def render_graph(data: dict[str, object]) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def update_graph(
    repo_root: str | Path,
    today: date | None = None,
    check: bool = False,
) -> GraphUpdateResult:
    root = Path(repo_root).resolve()
    graph_path = root / GRAPH_PATH
    current_date = today or today_msk()
    records, record_errors = collect_recency_records(root)
    graph_data, graph_errors = read_graph(graph_path)
    errors = [*record_errors, *graph_errors]
    if errors or graph_data is None:
        return GraphUpdateResult(errors=errors, changed=False)

    expected_data = expected_graph_data(graph_data, records, current_date)
    expected_text = render_graph(expected_data)
    original_text = read_text(graph_path)
    changed = expected_text != original_text

    if changed and check:
        errors.append(f"stale Obsidian graph recency heatmap: {GRAPH_PATH.as_posix()}")
    elif changed:
        graph_path.write_text(expected_text, encoding="utf-8")

    return GraphUpdateResult(errors=errors, changed=changed)


def main() -> int:
    args = parse_args()
    result = update_graph(
        args.repo_root,
        today=parse_date(args.today) if args.today else None,
        check=args.check,
    )
    if result.errors:
        for error in result.errors:
            print(error, file=sys.stderr)
        return 1

    if args.check:
        print("obsidian graph recency heatmap check passed")
    else:
        state = "changed" if result.changed else "already current"
        print(f"obsidian graph recency heatmap {state}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
