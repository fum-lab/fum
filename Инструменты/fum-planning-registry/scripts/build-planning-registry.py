#!/usr/bin/env python3
"""Build and validate the machine-readable FUM planning registry."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCHEMA = "fum.planning.requirements-registry.v3"
DEFAULT_OUTPUT = Path("Планирование/реестр-требований-вариантов-и-кандидатов.json")
SUMMARY_TABLE = Path("Планирование/сводная-таблица-требований-и-реализаций.md")
ROADMAP = Path("Планирование/дорожная-карта.md")
STAGES_README = Path("Планирование/стадии/README.md")
DIRECTIONS_README = Path("Планирование/направления-проектирования-и-развития/README.md")
MVP_README = Path("Планирование/MVP-кандидаты/README.md")
PROPOSALS = Path("Планирование/предложения-о-следующих-шагах.md")
QUESTIONS_README = Path("Вопросы/README.md")
AUTOMATION_FILE = Path("Инструменты/fum-planning-registry/SKILL.md")

LINK_RE = re.compile(r"!?\[([^\]\n]+)\]\(([^)\n]+)\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$", re.MULTILINE)
RECENCY_RE = re.compile(
    r"\n?<!-- FUM-MD-RECENCY:BEGIN -->.*?<!-- FUM-MD-RECENCY:END -->\n?",
    re.DOTALL,
)


@dataclass(frozen=True)
class Cell:
    raw: str
    text: str
    links: list[dict[str, str]]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    build = subparsers.add_parser("build", help="Build the planning registry JSON")
    build.add_argument("--repo-root", type=Path, default=Path.cwd())
    build.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)

    validate = subparsers.add_parser("validate", help="Validate a built registry JSON")
    validate.add_argument("--repo-root", type=Path, default=Path.cwd())
    validate.add_argument("--registry", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def absolute_path(path: str | Path, repo_root: Path) -> Path:
    value = Path(path)
    if value.is_absolute():
        return value.resolve()
    return (repo_root / value).resolve()


def repo_relative(path: str | Path, repo_root: Path) -> str:
    absolute = absolute_path(path, repo_root)
    return absolute.relative_to(repo_root.resolve()).as_posix()


def read_text(path: str | Path, repo_root: Path) -> str:
    return absolute_path(path, repo_root).read_text(encoding="utf-8")


def strip_recency(text: str) -> str:
    return RECENCY_RE.sub("\n", text).strip() + "\n"


def content_sha256(path: str | Path, repo_root: Path) -> str:
    text = read_text(path, repo_root)
    digest = hashlib.sha256(strip_recency(text).encode("utf-8")).hexdigest()
    return f"sha256:{digest}"


def normalize_target(target: str, source_path: Path, repo_root: Path) -> str:
    if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
        return target

    path_part, sep, fragment = target.partition("#")
    if not path_part:
        return target

    normalized = (absolute_path(source_path, repo_root).parent / path_part).resolve()
    try:
        result = normalized.relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        result = os.path.normpath(target)
    if sep:
        return f"{result}#{fragment}"
    return result


def links_from_markdown(markdown: str, source_path: Path, repo_root: Path) -> list[dict[str, str]]:
    links: list[dict[str, str]] = []
    for match in LINK_RE.finditer(markdown):
        links.append(
            {
                "label": clean_text(match.group(1)),
                "target": normalize_target(match.group(2), source_path, repo_root),
            }
        )
    return links


def clean_text(markdown: str) -> str:
    text = LINK_RE.sub(r"\1", markdown)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = text.replace("**", "").replace("__", "")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def section_body(text: str, heading: str) -> str:
    match: re.Match[str] | None = None
    for candidate in re.finditer(r"^##\s+(.+?)\s*$", text, re.MULTILINE):
        if clean_text(candidate.group(1)) == heading:
            match = candidate
            break
    if match is None:
        return ""
    next_heading = re.search(r"^## .+$", text[match.end() :], re.MULTILINE)
    if not next_heading:
        return text[match.end() :]
    return text[match.end() : match.end() + next_heading.start()]


def split_row(line: str) -> list[str]:
    value = line.strip()
    if not value.startswith("|") or not value.endswith("|"):
        return []
    return [cell.strip() for cell in value.strip("|").split("|")]


def is_separator(cells: list[str]) -> bool:
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell.strip()) for cell in cells)


def parse_table(section: str, source_path: Path, repo_root: Path) -> list[list[Cell]]:
    rows: list[list[Cell]] = []
    for line in section.splitlines():
        cells = split_row(line)
        if not cells or is_separator(cells):
            continue
        rows.append(
            [
                Cell(
                    raw=cell,
                    text=clean_text(cell),
                    links=links_from_markdown(cell, source_path, repo_root),
                )
                for cell in cells
            ]
        )
    if len(rows) <= 1:
        return []
    return rows[1:]


def table_after_heading(
    path: str | Path,
    heading: str,
    repo_root: Path,
) -> list[list[Cell]]:
    source_path = Path(path)
    return parse_table(section_body(read_text(source_path, repo_root), heading), source_path, repo_root)


def split_items(cell: Cell, source_path: Path, repo_root: Path) -> list[dict[str, Any]]:
    fragments = [part.strip() for part in re.split(r";\s+", cell.raw) if part.strip()]
    if not fragments:
        fragments = [cell.raw.strip()] if cell.raw.strip() else []
    return [
        {
            "text": clean_text(fragment),
            "links": links_from_markdown(fragment, source_path, repo_root),
        }
        for fragment in fragments
        if clean_text(fragment)
    ]


def first_link_target(cell: Cell) -> str | None:
    if not cell.links:
        return None
    return cell.links[0]["target"]


def extract_requirements(repo_root: Path) -> list[dict[str, Any]]:
    rows = table_after_heading(SUMMARY_TABLE, "Сводная таблица", repo_root)
    requirements: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if len(row) != 6:
            continue
        layer, result, documentation_stage, boxed_fum, candidates, status = row
        requirement_id = f"REQ-{index:03d}"
        requirements.append(
            {
                "id": requirement_id,
                "layer": {
                    "text": layer.text,
                    "links": layer.links,
                },
                "required_result": {
                    "text": result.text,
                    "links": result.links,
                },
                "documentation_stage_implementation": [
                    {
                        "id": f"{requirement_id}-DOC-{option_index:02d}",
                        **option,
                    }
                    for option_index, option in enumerate(
                        split_items(documentation_stage, SUMMARY_TABLE, repo_root),
                        start=1,
                    )
                ],
                "boxed_fum_implementation": [
                    {
                        "id": f"{requirement_id}-BOX-{option_index:02d}",
                        **option,
                    }
                    for option_index, option in enumerate(
                        split_items(boxed_fum, SUMMARY_TABLE, repo_root),
                        start=1,
                    )
                ],
                "candidates_and_artifacts": [
                    {
                        "id": f"{requirement_id}-CAND-{candidate_index:02d}",
                        **candidate,
                    }
                    for candidate_index, candidate in enumerate(
                        split_items(candidates, SUMMARY_TABLE, repo_root),
                        start=1,
                    )
                ],
                "status": status.text,
                "source": {
                    "file": SUMMARY_TABLE.as_posix(),
                    "section": "Сводная таблица",
                    "row": index,
                },
            }
        )
    return requirements


def extract_product_queue(repo_root: Path) -> list[dict[str, Any]]:
    rows = table_after_heading(SUMMARY_TABLE, "Очередь продуктовых кандидатов", repo_root)
    queue: list[dict[str, Any]] = []
    for row in rows:
        if len(row) != 5:
            continue
        order, candidate, first_result, requirements, conclusion = row
        queue.append(
            {
                "order": int(order.text) if order.text.isdigit() else order.text,
                "candidate": candidate.text,
                "candidate_link": first_link_target(candidate),
                "first_runnable_result": first_result.text,
                "first_closed_requirements": requirements.text,
                "working_conclusion": conclusion.text,
            }
        )
    return queue


def extract_roadmap_horizons(repo_root: Path) -> list[dict[str, Any]]:
    text = read_text(ROADMAP, repo_root)
    horizons: list[dict[str, Any]] = []
    for match in re.finditer(r"^## Горизонт\s+(\d+)\.\s+(.+?)\s*$", text, re.MULTILINE):
        horizons.append(
            {
                "id": f"horizon-{match.group(1)}",
                "title": clean_text(match.group(2)),
                "source_file": ROADMAP.as_posix(),
            }
        )
    return horizons


def extract_stages(repo_root: Path) -> list[dict[str, Any]]:
    rows = table_after_heading(STAGES_README, "Карта стадий", repo_root)
    stages: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if len(row) != 4:
            continue
        stage, meaning, materials, check = row
        stages.append(
            {
                "id": f"stage-{index:02d}",
                "title": stage.text,
                "file": first_link_target(stage),
                "meaning": meaning.text,
                "planning_materials": materials.text,
                "check": check.text,
                "links": stage.links + meaning.links + materials.links + check.links,
            }
        )
    return stages


def extract_directions(repo_root: Path) -> list[dict[str, Any]]:
    rows = table_after_heading(DIRECTIONS_README, "Карта направлений и ближайших артефактов", repo_root)
    directions: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if len(row) != 4:
            continue
        direction, meaning, artifact, check = row
        directions.append(
            {
                "id": f"direction-{index:02d}",
                "title": direction.text,
                "file": first_link_target(direction),
                "meaning": meaning.text,
                "nearest_artifact": artifact.text,
                "check": check.text,
                "links": direction.links + meaning.links + artifact.links + check.links,
            }
        )
    return directions


def current_mvp_target(repo_root: Path) -> str | None:
    body = section_body(read_text(MVP_README, repo_root), "Текущий выбор")
    links = links_from_markdown(body, MVP_README, repo_root)
    return links[0]["target"] if links else None


def extract_mvp_candidates(repo_root: Path) -> list[dict[str, Any]]:
    rows = table_after_heading(MVP_README, "Кандидаты", repo_root)
    current = current_mvp_target(repo_root)
    candidates: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if len(row) != 3:
            continue
        candidate, idea, result = row
        target = first_link_target(candidate)
        candidates.append(
            {
                "id": f"mvp-{index:02d}",
                "title": candidate.text,
                "file": target,
                "product_idea": idea.text,
                "first_user_result": result.text,
                "status": "выбран в работу" if target == current else "кандидат",
                "links": candidate.links + idea.links + result.links,
            }
        )
    return candidates


def proposal_rows(repo_root: Path, heading: str) -> list[dict[str, Any]]:
    rows = table_after_heading(PROPOSALS, heading, repo_root)
    proposals: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if len(row) != 4:
            continue
        status, proposal, reason, sources = row
        proposals.append(
            {
                "id": f"proposal-{heading.lower().replace(' ', '-')}-{index:03d}",
                "status": status.text,
                "proposal": proposal.text,
                "reason": reason.text,
                "source_links": sources.links,
            }
        )
    return proposals


def bullet_links_by_section(repo_root: Path, heading: str) -> list[dict[str, str]]:
    text = read_text(QUESTIONS_README, repo_root)
    body = section_body(text, heading)
    items: list[dict[str, str]] = []
    for line in body.splitlines():
        if not line.lstrip().startswith("- "):
            continue
        links = links_from_markdown(line, QUESTIONS_README, repo_root)
        if links:
            items.append({"title": links[0]["label"], "file": links[0]["target"]})
    return items


def extract_questions(repo_root: Path) -> dict[str, list[dict[str, str]]]:
    return {
        "open": bullet_links_by_section(repo_root, "Открытые вопросы"),
        "partially_clarified": bullet_links_by_section(repo_root, "Частично прояснённые вопросы"),
        "clarified": bullet_links_by_section(repo_root, "Прояснённые вопросы"),
    }


def linked_existing_files(items: list[dict[str, Any]], repo_root: Path) -> list[Path]:
    files: list[Path] = []
    for item in items:
        target = item.get("file")
        if not isinstance(target, str):
            continue
        path = absolute_path(target, repo_root)
        if path.exists() and path.is_file():
            files.append(path)
    return files


def source_files(repo_root: Path, inventory: dict[str, Any]) -> list[Path]:
    fixed = [
        SUMMARY_TABLE,
        ROADMAP,
        STAGES_README,
        DIRECTIONS_README,
        MVP_README,
        PROPOSALS,
        QUESTIONS_README,
    ]
    direction_files = sorted(
        path
        for path in absolute_path("Планирование/направления-проектирования-и-развития", repo_root).glob("*.md")
        if path.name != "README.md"
    )
    stage_files = sorted(absolute_path("Планирование/стадии", repo_root).glob("*/README.md"))
    mvp_files = sorted(absolute_path("Планирование/MVP-кандидаты", repo_root).glob("*/README.md"))
    question_files = []
    for status_items in inventory["questions"].values():
        question_files.extend(linked_existing_files(status_items, repo_root))

    all_files = [
        absolute_path(path, repo_root)
        for path in fixed
        if absolute_path(path, repo_root).exists()
    ]
    all_files.extend(direction_files)
    all_files.extend(stage_files)
    all_files.extend(mvp_files)
    all_files.extend(question_files)

    unique: dict[str, Path] = {}
    for path in all_files:
        unique[repo_relative(path, repo_root)] = path
    return [unique[key] for key in sorted(unique)]


def targets_from_requirement(requirement: dict[str, Any]) -> set[str]:
    targets: set[str] = set()
    for group in [
        requirement["layer"],
        requirement["required_result"],
        *requirement["documentation_stage_implementation"],
        *requirement["boxed_fum_implementation"],
        *requirement["candidates_and_artifacts"],
    ]:
        for link in group.get("links", []):
            targets.add(link["target"])
    return targets


def coverage(requirements: list[dict[str, Any]], inventory: dict[str, Any]) -> dict[str, Any]:
    targets_by_requirement = {
        requirement["id"]: targets_from_requirement(requirement)
        for requirement in requirements
    }

    def covered(target: str | None) -> list[str]:
        if target is None:
            return []
        return [
            requirement_id
            for requirement_id, targets in targets_by_requirement.items()
            if target in targets
        ]

    product_queue_targets = {
        item["candidate_link"]
        for item in inventory["product_queue"]
        if item.get("candidate_link")
    }

    return {
        "directions": [
            {
                "title": direction["title"],
                "file": direction["file"],
                "covered_by_requirement_ids": covered(direction["file"]),
            }
            for direction in inventory["directions"]
        ],
        "mvp_candidates": [
            {
                "title": candidate["title"],
                "file": candidate["file"],
                "covered_by_requirement_ids": covered(candidate["file"]),
                "in_product_queue": candidate["file"] in product_queue_targets,
            }
            for candidate in inventory["mvp_candidates"]
        ],
        "open_questions": [
            {
                "title": question["title"],
                "file": question["file"],
                "covered_by_requirement_ids": covered(question["file"]),
            }
            for question in inventory["questions"]["open"]
        ],
    }


def build_registry(repo_root: Path | None = None) -> dict[str, Any]:
    root = (repo_root or Path.cwd()).resolve()
    requirements = extract_requirements(root)
    inventory: dict[str, Any] = {
        "roadmap_horizons": extract_roadmap_horizons(root),
        "stages": extract_stages(root),
        "directions": extract_directions(root),
        "mvp_candidates": extract_mvp_candidates(root),
        "product_queue": extract_product_queue(root),
        "active_proposals": proposal_rows(root, "Актуальные предложения"),
        "proposal_history": proposal_rows(root, "История предложений"),
        "questions": extract_questions(root),
    }
    sources = source_files(root, inventory)
    return {
        "schema": SCHEMA,
        "generated_by": AUTOMATION_FILE.as_posix(),
        "source_files": [
            {
                "path": repo_relative(path, root),
                "content_sha256_without_recency": content_sha256(path, root),
            }
            for path in sources
        ],
        "requirements": requirements,
        "source_inventory": inventory,
        "coverage": coverage(requirements, inventory),
    }


def validate_registry_object(registry: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if registry.get("schema") != SCHEMA:
        errors.append(f"unexpected schema: {registry.get('schema')}")
    if not registry.get("requirements"):
        errors.append("registry must contain at least one requirement")

    inventory = registry.get("source_inventory", {})
    for field in ["roadmap_horizons", "stages", "directions", "mvp_candidates"]:
        if not inventory.get(field):
            errors.append(f"source inventory is empty: {field}")

    for field in ["active_proposals", "proposal_history"]:
        if not isinstance(inventory.get(field), list):
            errors.append(f"source inventory must contain list: {field}")

    questions = inventory.get("questions")
    if not isinstance(questions, dict):
        errors.append("source inventory must contain questions")
    else:
        for field in ["open", "partially_clarified", "clarified"]:
            if not isinstance(questions.get(field), list):
                errors.append(f"source inventory questions must contain list: {field}")

    for item in registry.get("coverage", {}).get("mvp_candidates", []):
        if not item.get("covered_by_requirement_ids") and not item.get("in_product_queue"):
            errors.append(f"MVP candidate is not covered by requirements or product queue: {item.get('title')}")
    return errors


def registry_json(registry: dict[str, Any]) -> str:
    return json.dumps(registry, ensure_ascii=False, indent=2) + "\n"


def build_to_file(output_path: Path, repo_root: Path | None = None) -> dict[str, Any]:
    root = (repo_root or Path.cwd()).resolve()
    registry = build_registry(root)
    errors = validate_registry_object(registry)
    if errors:
        raise ValueError("\n".join(errors))
    output = absolute_path(output_path, root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(registry_json(registry), encoding="utf-8")
    return registry


def validate_file(registry_path: Path, repo_root: Path | None = None) -> list[str]:
    root = (repo_root or Path.cwd()).resolve()
    path = absolute_path(registry_path, root)
    if not path.exists():
        return [f"registry does not exist: {repo_relative(path, root)}"]

    try:
        actual = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"registry is not valid JSON: {exc}"]

    errors = validate_registry_object(actual)
    expected = build_registry(root)
    expected_errors = validate_registry_object(expected)
    if expected_errors:
        errors.extend(expected_errors)

    if registry_json(actual) != registry_json(expected):
        errors.append(
            "registry is stale; rebuild it with "
            "python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build"
        )
    return errors


def main() -> int:
    args = parse_args()
    try:
        if args.command == "build":
            build_to_file(args.output, args.repo_root)
            return 0

        errors = validate_file(args.registry, args.repo_root)
        if errors:
            for error in errors:
                print(error, file=sys.stderr)
            return 1
        return 0
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
