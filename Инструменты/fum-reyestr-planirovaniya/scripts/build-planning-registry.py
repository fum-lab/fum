#!/usr/bin/env python3
"""Build and validate the machine-readable FUM planning registry."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCHEMA = "fum.planning.requirements-registry.v6"
DEFAULT_OUTPUT = Path("Планирование/реестр-требований-вариантов-и-кандидатов.json")
SUMMARY_TABLE = Path("Планирование/сводная-таблица-требований-и-реализаций.md")
ROADMAP = Path("Планирование/дорожная-карта.md")
STAGES_README = Path("Планирование/стадии/README.md")
DIRECTIONS_README = Path("Планирование/направления-проектирования-и-развития/README.md")
MVP_README = Path("Планирование/MVP-кандидаты/README.md")
PROPOSALS_OVERVIEW = Path("Планирование/предложения-о-следующих-шагах.md")
STEP_CARDS_DIR = Path("Планирование/карточки-шагов")
STEP_CARDS_INDEX = STEP_CARDS_DIR / "README.md"
QUESTIONS_README = Path("Вопросы/README.md")
AUTOMATION_FILE = Path("Инструменты/fum-reyestr-planirovaniya/SKILL.md")
REQUIREMENTS_DIR = Path("Требования")
REQUIREMENTS_INDEX = REQUIREMENTS_DIR / "README.md"

STEP_CARD_ID_RE = re.compile(r"^FUM-STEP-[0-9]{4}$")
STEP_CARD_STATUSES = {
    "active": "Актуально",
    "completed": "Выполнено",
    "absorbed": "Поглощено",
    "withdrawn": "Снято",
}
STEP_CARD_EMOJI_BY_MACHINE = {
    "active": "🟡",
    "completed": "✅",
    "absorbed": "🧩",
    "withdrawn": "🗑️",
}
STEP_CARD_MACHINE_BY_EMOJI = {
    emoji: status
    for status, emoji in STEP_CARD_EMOJI_BY_MACHINE.items()
}
INDEX_STATUS_BY_MACHINE = {
    status: f"{STEP_CARD_EMOJI_BY_MACHINE[status]} {label}"
    for status, label in STEP_CARD_STATUSES.items()
}
STEP_CARD_INDEX_HEADERS = ["Идентификатор", "Статус", "Карточка"]
STEP_CARD_FRONTMATTER_KEYS = frozenset(
    {"schema_version", "card_id", "status"}
)

LINK_RE = re.compile(r"!?\[([^\]\n]+)\]\(([^)\n]+)\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$", re.MULTILINE)
REQUIREMENT_ID_RE = re.compile(
    r"<!--\s*FUM-REQUIREMENT-ID:\s*(FUM-REQ-[0-9]{4})\s*-->"
)
REQUIREMENT_INDEX_ENTRY_RE = re.compile(
    r"^\s*-\s+`(FUM-REQ-[0-9]{4})`\s+—\s+"
    r"\[([^\]\n]+)\]\(([^)\n]+)\)\s*$"
)
RELATION_RE = re.compile(
    r"^\s*-\s+\*\*([^*]+?):\*\*\s+"
    r"\[([^\]\n]+)\]\(([^)\n]+)\)\s+—\s+(.+?)\s*$"
)
RECENCY_RE = re.compile(
    r"\n?<!-- FUM-MD-RECENCY:BEGIN -->.*?<!-- FUM-MD-RECENCY:END -->\n?",
    re.DOTALL,
)

REQUIREMENT_STATUSES: dict[str, dict[str, str]] = {
    "⚪": {"code": "draft", "label": "черновик"},
    "🟡": {"code": "planned", "label": "принято и запланировано"},
    "🚧": {"code": "in_progress", "label": "реализуется"},
    "✅": {"code": "verified", "label": "реализовано и подтверждено"},
    "⛔": {"code": "blocked", "label": "заблокировано"},
    "🗑️": {"code": "withdrawn", "label": "снято"},
}
REQUIRED_REQUIREMENT_SECTIONS = [
    "Семантические связи",
    "Критерии проверки",
    "Статус и границы",
    "Источники требований",
]
INVERSE_RELATIONS = {
    "зависит от": "требуется для",
    "требуется для": "зависит от",
    "является частью": "состоит из",
    "состоит из": "является частью",
    "дополняет": "дополняется",
    "дополняется": "дополняет",
    "усиливает": "усиливается",
    "усиливается": "усиливает",
}


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


def has_level_two_heading(text: str, heading: str) -> bool:
    return any(
        clean_text(candidate.group(1)) == heading
        for candidate in re.finditer(r"^##\s+(.+?)\s*$", text, re.MULTILINE)
    )


def first_level_one_heading(text: str, source_file: str) -> tuple[str, int]:
    match = re.search(r"^#\s+(.+?)\s*$", text, re.MULTILINE)
    if match is None:
        raise ValueError(f"requirement card has no level-one heading: {source_file}")
    return clean_text(match.group(1)), match.end()


def markdown_list_items(markdown: str, source_path: Path, repo_root: Path) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    current: list[str] = []

    def append_current() -> None:
        if not current:
            return
        raw = " ".join(current)
        text = clean_text(raw)
        if text:
            items.append(
                {
                    "text": text,
                    "links": links_from_markdown(raw, source_path, repo_root),
                }
            )

    for line in markdown.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("- "):
            append_current()
            current = [stripped[2:].strip()]
            continue
        if not current:
            raise ValueError(
                f"malformed Markdown list in {source_path.as_posix()}: {stripped}"
            )
        current.append(stripped)
    append_current()
    return items


def step_card_filename_metadata(path: Path) -> tuple[str, str, str]:
    filename = path.name
    if len(filename.encode("utf-8")) > 255:
        raise ValueError(
            f"step card filename exceeds 255 UTF-8 bytes: {filename}"
        )

    filename_status: str | None = None
    filename_emoji: str | None = None
    for emoji in sorted(STEP_CARD_MACHINE_BY_EMOJI, key=len, reverse=True):
        if filename.startswith(f"{emoji}-"):
            filename_emoji = emoji
            filename_status = STEP_CARD_MACHINE_BY_EMOJI[emoji]
            break
    if filename_status is None or filename_emoji is None:
        raise ValueError(f"invalid step card filename status emoji: {filename}")

    remainder = filename[len(filename_emoji) + 1 :]
    match = re.fullmatch(r"(FUM-STEP-[0-9]{4})-(.*)\.md", remainder)
    if match is None:
        raise ValueError(
            "invalid step card filename; expected "
            f"<emoji>-FUM-STEP-NNNN-<description>.md: {filename}"
        )
    filename_id, description = match.groups()
    description_parts = description.split("-")
    if (
        not description
        or any(not part for part in description_parts)
        or any(
            not all(character.isalnum() for character in part)
            for part in description_parts
        )
    ):
        raise ValueError(
            "invalid step card filename description; expected Unicode letters "
            f"or digits separated by single hyphens: {filename}"
        )
    return filename_id, filename_status, description


def step_card_paths(repo_root: Path) -> list[Path]:
    directory = absolute_path(STEP_CARDS_DIR, repo_root)
    if not directory.is_dir():
        raise ValueError(
            f"step cards directory does not exist: {STEP_CARDS_DIR.as_posix()}"
        )
    markdown_paths = sorted(
        path
        for path in directory.rglob("*")
        if path.is_file() and path.suffix.casefold() == ".md"
    )
    index_path = directory / STEP_CARDS_INDEX.name
    paths: list[Path] = []
    for path in markdown_paths:
        if path == index_path:
            continue
        if path.parent != directory:
            relative_path = path.relative_to(directory).as_posix()
            raise ValueError(
                "step cards directory must be flat; nested Markdown is "
                f"forbidden: {relative_path}"
            )
        paths.append(path)
    if not paths:
        raise ValueError(
            f"step cards directory contains no cards: {STEP_CARDS_DIR.as_posix()}"
        )
    return paths


def split_step_card_frontmatter(
    text: str,
    source_file: str,
) -> tuple[dict[str, Any], str]:
    if not text.startswith("+++\n"):
        raise ValueError(
            f"step card must start with TOML frontmatter: {source_file}"
        )
    closing = text.find("\n+++\n", 4)
    if closing < 0:
        raise ValueError(f"step card TOML frontmatter is not closed: {source_file}")
    try:
        frontmatter = tomllib.loads(text[4:closing])
    except tomllib.TOMLDecodeError as error:
        raise ValueError(
            f"invalid step card TOML in {source_file}: {error}"
        ) from error
    if not isinstance(frontmatter, dict):
        raise ValueError(f"step card TOML must be a table: {source_file}")
    keys = frozenset(frontmatter)
    missing = STEP_CARD_FRONTMATTER_KEYS - keys
    unknown = keys - STEP_CARD_FRONTMATTER_KEYS
    if missing:
        raise ValueError(
            "missing step card TOML fields in "
            f"{source_file}: {', '.join(sorted(missing))}"
        )
    if unknown:
        raise ValueError(
            "unknown step card TOML fields in "
            f"{source_file}: {', '.join(sorted(unknown))}"
        )
    body = RECENCY_RE.sub("\n", text[closing + 5 :]).strip() + "\n"
    return frontmatter, body


def required_step_card_section(
    body: str,
    heading: str,
    source_file: str,
) -> str:
    if not has_level_two_heading(body, heading):
        raise ValueError(
            f"missing required section {heading} in step card: {source_file}"
        )
    raw = section_body(body, heading).strip()
    if not clean_text(raw):
        raise ValueError(
            f"empty required section {heading} in step card: {source_file}"
        )
    return raw


def parse_step_card(path: Path, repo_root: Path) -> dict[str, Any]:
    filename_id, filename_status, _description = step_card_filename_metadata(path)
    source_file = repo_relative(path, repo_root)
    frontmatter, body = split_step_card_frontmatter(
        path.read_text(encoding="utf-8"),
        source_file,
    )
    schema_version = frontmatter["schema_version"]
    if type(schema_version) is not int or schema_version != 1:
        raise ValueError(
            f"step card supports only schema_version = 1: {source_file}"
        )
    card_id = frontmatter["card_id"]
    if not isinstance(card_id, str) or STEP_CARD_ID_RE.fullmatch(card_id) is None:
        raise ValueError(f"invalid step card id in {source_file}: {card_id!r}")
    if filename_id != card_id:
        raise ValueError(
            "step card filename id does not match TOML card_id in "
            f"{source_file}: {filename_id!r} != {card_id!r}"
        )
    status = frontmatter["status"]
    if not isinstance(status, str) or status not in STEP_CARD_STATUSES:
        raise ValueError(f"invalid step card status in {source_file}: {status!r}")
    if filename_status != status:
        raise ValueError(
            "step card filename status does not match TOML status in "
            f"{source_file}: {filename_status!r} != {status!r}"
        )

    h1_matches = list(re.finditer(r"^#\s+(.+?)\s*$", body, re.MULTILINE))
    if len(h1_matches) != 1:
        raise ValueError(
            f"step card must contain exactly one level-one heading: {source_file}"
        )
    title = clean_text(h1_matches[0].group(1))
    if not title:
        raise ValueError(f"step card title is empty: {source_file}")

    task = clean_text(required_step_card_section(body, "Задача", source_file))
    sources_raw = required_step_card_section(body, "Источники", source_file)
    source_items = markdown_list_items(sources_raw, path, repo_root)
    source_links = [
        link
        for item in source_items
        for link in item["links"]
    ]
    if not source_links:
        raise ValueError(
            f"step card sources must contain at least one link: {source_file}"
        )

    why_now: str | None = None
    criteria: list[str] = []
    outcome: str | None = None
    if status == "active":
        why_now = clean_text(
            required_step_card_section(body, "Почему сейчас", source_file)
        )
        criteria_raw = required_step_card_section(
            body,
            "Критерии завершения",
            source_file,
        )
        criteria = [
            item["text"]
            for item in markdown_list_items(criteria_raw, path, repo_root)
        ]
        if not criteria:
            raise ValueError(
                f"step card criteria must not be empty: {source_file}"
            )
    else:
        outcome = clean_text(
            required_step_card_section(body, "Результат", source_file)
        )

    return {
        "id": card_id,
        "file": source_file,
        "title": title,
        "status": status,
        "task": task,
        "why_now": why_now,
        "criteria": criteria,
        "outcome": outcome,
        "source_links": source_links,
    }


def requirement_status_from_filename(path: Path) -> str:
    for symbol in sorted(REQUIREMENT_STATUSES, key=len, reverse=True):
        if path.name.startswith(f"{symbol}-"):
            return symbol
    raise ValueError(f"invalid requirement status in filename: {path.as_posix()}")


def requirement_card_paths(repo_root: Path) -> list[Path]:
    directory = absolute_path(REQUIREMENTS_DIR, repo_root)
    return sorted(
        path
        for path in directory.glob("*.md")
        if path.name != REQUIREMENTS_INDEX.name
    )


def indexed_requirement_targets(repo_root: Path) -> dict[str, list[dict[str, str]]]:
    index_text = read_text(REQUIREMENTS_INDEX, repo_root)
    indexed: dict[str, list[dict[str, str]]] = {}
    for line in index_text.splitlines():
        links = links_from_markdown(line, REQUIREMENTS_INDEX, repo_root)
        requirement_links = [
            link
            for link in links
            if Path(link["target"]).parent == REQUIREMENTS_DIR
            and Path(link["target"]).name != REQUIREMENTS_INDEX.name
            and Path(link["target"]).suffix == ".md"
        ]
        if not requirement_links:
            continue
        match = REQUIREMENT_INDEX_ENTRY_RE.fullmatch(line)
        if match is None or len(requirement_links) != 1:
            raise ValueError(f"malformed requirement index entry: {line.strip()}")
        link = requirement_links[0]
        indexed.setdefault(link["target"], []).append(
            {
                "id": match.group(1),
                "label": link["label"],
                "target": link["target"],
            }
        )
    return indexed


def requirement_formulation(
    text: str,
    heading_end: int,
    source_path: Path,
    repo_root: Path,
) -> dict[str, Any]:
    next_heading = re.search(r"^##\s+.+$", text[heading_end:], re.MULTILINE)
    end = heading_end + next_heading.start() if next_heading else len(text)
    markdown = REQUIREMENT_ID_RE.sub("", text[heading_end:end]).strip()
    if not clean_text(markdown):
        raise ValueError(
            f"requirement formulation is empty: {source_path.as_posix()}"
        )
    return {
        "markdown": markdown,
        "text": clean_text(markdown),
        "links": links_from_markdown(markdown, source_path, repo_root),
    }


def parse_requirement_relations(
    section: str,
    source_path: Path,
    repo_root: Path,
) -> list[dict[str, str]]:
    relations: list[dict[str, str]] = []
    for line in section.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if not stripped.startswith("- "):
            raise ValueError(
                f"malformed semantic relation in {source_path.as_posix()}: {stripped}"
            )
        match = RELATION_RE.fullmatch(stripped)
        if match is None:
            raise ValueError(
                f"malformed semantic relation in {source_path.as_posix()}: {stripped}"
            )
        relation_type = clean_text(match.group(1))
        if relation_type not in INVERSE_RELATIONS:
            raise ValueError(
                f"unknown semantic relation type in {source_path.as_posix()}: "
                f"{relation_type}"
            )
        relations.append(
            {
                "type": relation_type,
                "target_label": clean_text(match.group(2)),
                "target_file": normalize_target(
                    match.group(3),
                    source_path,
                    repo_root,
                ),
                "reason": clean_text(match.group(4)),
            }
        )
    return relations


def extract_requirement_cards(repo_root: Path) -> list[dict[str, Any]]:
    cards = requirement_card_paths(repo_root)
    if not cards:
        raise ValueError("no canonical requirement cards found")
    statuses_by_file = {
        repo_relative(path, repo_root): requirement_status_from_filename(path)
        for path in cards
    }

    indexed = indexed_requirement_targets(repo_root)
    actual_targets = {repo_relative(path, repo_root) for path in cards}
    indexed_targets = set(indexed)
    for target in sorted(actual_targets - indexed_targets):
        raise ValueError(f"requirement card is not indexed: {target}")
    for target in sorted(indexed_targets - actual_targets):
        raise ValueError(f"requirement index target does not exist: {target}")
    for target, links in sorted(indexed.items()):
        if len(links) != 1:
            raise ValueError(f"requirement card is indexed more than once: {target}")

    parsed: list[dict[str, Any]] = []
    ids: dict[str, str] = {}
    for path in cards:
        source_file = repo_relative(path, repo_root)
        source_path = Path(source_file)
        text = strip_recency(read_text(path, repo_root))
        status_symbol = statuses_by_file[source_file]
        index_link = indexed[source_file][0]
        if not index_link["label"].startswith(status_symbol):
            raise ValueError(
                f"requirement index status does not match filename: {source_file}"
            )

        identifier_matches = REQUIREMENT_ID_RE.findall(text)
        if len(identifier_matches) != 1:
            raise ValueError(
                f"requirement card must contain exactly one stable id: {source_file}"
            )
        requirement_id = identifier_matches[0]
        if requirement_id in ids:
            raise ValueError(
                f"duplicate requirement id: {requirement_id} "
                f"({ids[requirement_id]}, {source_file})"
            )
        ids[requirement_id] = source_file

        title, heading_end = first_level_one_heading(text, source_file)
        marker_after_heading = re.match(
            r"\s*" + REQUIREMENT_ID_RE.pattern,
            text[heading_end:],
        )
        if marker_after_heading is None:
            raise ValueError(
                f"stable requirement id marker must immediately follow heading: "
                f"{source_file}"
            )
        expected_index_label = f"{status_symbol} {title}"
        if index_link["label"] != expected_index_label:
            raise ValueError(
                f"requirement index label does not match card: {source_file}"
            )
        if index_link["id"] != requirement_id:
            raise ValueError(
                f"requirement index id does not match card: {source_file}"
            )
        sections: dict[str, str] = {}
        for section_name in REQUIRED_REQUIREMENT_SECTIONS:
            body = section_body(text, section_name)
            if not body.strip():
                raise ValueError(
                    f"missing required section {section_name}: {source_file}"
                )
            sections[section_name] = body

        body_status_match = re.search(
            r"—\s*`(" + "|".join(
                re.escape(symbol)
                for symbol in sorted(REQUIREMENT_STATUSES, key=len, reverse=True)
            ) + r")`",
            sections["Статус и границы"],
        )
        if body_status_match is None:
            raise ValueError(f"requirement body status is missing: {source_file}")
        if body_status_match.group(1) != status_symbol:
            raise ValueError(
                f"requirement body status does not match filename: {source_file}"
            )

        criteria = markdown_list_items(
            sections["Критерии проверки"],
            source_path,
            repo_root,
        )
        if not criteria:
            raise ValueError(f"requirement criteria are empty: {source_file}")

        parsed.append(
            {
                "id": requirement_id,
                "title": title,
                "file": source_file,
                "status": {
                    "symbol": status_symbol,
                    **REQUIREMENT_STATUSES[status_symbol],
                },
                "formulation": requirement_formulation(
                    text,
                    heading_end,
                    source_path,
                    repo_root,
                ),
                "criteria": criteria,
                "semantic_relations": parse_requirement_relations(
                    sections["Семантические связи"],
                    source_path,
                    repo_root,
                ),
                "source": {
                    "file": source_file,
                    "index_file": REQUIREMENTS_INDEX.as_posix(),
                },
            }
        )

    by_file = {card["file"]: card for card in parsed}
    for card in parsed:
        seen_relations: set[tuple[str, str]] = set()
        for relation in card["semantic_relations"]:
            target_file = relation["target_file"]
            target = by_file.get(target_file)
            if target is None:
                raise ValueError(
                    f"semantic relation target is not an indexed requirement card: "
                    f"{card['file']} -> {target_file}"
                )
            key = (relation["type"], target_file)
            if key in seen_relations:
                raise ValueError(
                    f"duplicate semantic relation: {card['file']} "
                    f"{relation['type']} {target_file}"
                )
            seen_relations.add(key)
            relation["target_requirement_id"] = target["id"]
            relation["inverse_type"] = INVERSE_RELATIONS[relation["type"]]

    for card in parsed:
        for relation in card["semantic_relations"]:
            target = by_file[relation["target_file"]]
            inverse_matches = [
                candidate
                for candidate in target["semantic_relations"]
                if candidate["type"] == relation["inverse_type"]
                and candidate["target_file"] == card["file"]
            ]
            if len(inverse_matches) != 1:
                raise ValueError(
                    "missing inverse semantic relation: "
                    f"{card['id']} {relation['type']} "
                    f"{relation['target_requirement_id']}"
                )

    return sorted(parsed, key=lambda card: card["id"])


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


def strict_table_after_heading(
    path: str | Path,
    heading: str,
    expected_headers: list[str],
    repo_root: Path,
    *,
    allow_preamble: bool = False,
) -> list[list[Cell]]:
    source_path = Path(path)
    text = read_text(source_path, repo_root)
    if not has_level_two_heading(text, heading):
        raise ValueError(
            f"missing required table section {heading}: {source_path.as_posix()}"
        )
    lines = section_body(text, heading).splitlines()
    header_index: int | None = None
    for line_index, line in enumerate(lines):
        cells = split_row(line)
        if [clean_text(cell) for cell in cells] == expected_headers:
            header_index = line_index
            break
    if header_index is None:
        raise ValueError(
            f"unexpected table header in {source_path.as_posix()} section {heading}"
        )
    for line_index in range(header_index):
        line = lines[line_index]
        if not line.strip():
            continue
        if allow_preamble and "|" not in line:
            continue
        raise ValueError(
            f"malformed table row in {source_path.as_posix()} "
            f"section {heading}: line {line_index + 1}"
        )

    populated_after_header = [
        index
        for index in range(header_index, len(lines))
        if lines[index].strip()
    ]
    last = populated_after_header[-1]
    parsed_rows: list[list[str]] = []
    for line_index in range(header_index, last + 1):
        line = lines[line_index]
        cells = split_row(line)
        if len(cells) != len(expected_headers):
            raise ValueError(
                f"malformed table row in {source_path.as_posix()} "
                f"section {heading}: line {line_index + 1}"
            )
        parsed_rows.append(cells)

    if len(parsed_rows) < 2:
        raise ValueError(
            f"malformed table in {source_path.as_posix()} section {heading}"
        )
    if not is_separator(parsed_rows[1]):
        raise ValueError(
            f"missing table separator in {source_path.as_posix()} section {heading}"
        )

    rows: list[list[Cell]] = []
    for cells in parsed_rows[2:]:
        if is_separator(cells):
            raise ValueError(
                f"unexpected table separator in {source_path.as_posix()} "
                f"section {heading}"
            )
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
    return rows


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


def step_card_index_rows(repo_root: Path) -> list[list[Cell]]:
    source_path = STEP_CARDS_INDEX
    text = read_text(source_path, repo_root)
    lines = text.splitlines()
    header_indexes = [
        index
        for index, line in enumerate(lines)
        if [clean_text(cell) for cell in split_row(line)]
        == STEP_CARD_INDEX_HEADERS
    ]
    if len(header_indexes) != 1:
        raise ValueError(
            "step card index must contain exactly one table with headers "
            f"{' | '.join(STEP_CARD_INDEX_HEADERS)}: {source_path.as_posix()}"
        )
    header_index = header_indexes[0]
    separator_index = header_index + 1
    if separator_index >= len(lines):
        raise ValueError(f"step card index table has no separator: {source_path}")
    separator = split_row(lines[separator_index])
    if len(separator) != len(STEP_CARD_INDEX_HEADERS) or not is_separator(separator):
        raise ValueError(f"step card index table has invalid separator: {source_path}")

    rows: list[list[Cell]] = []
    for line_number in range(separator_index + 1, len(lines)):
        line = lines[line_number]
        if not line.strip():
            if rows:
                break
            continue
        cells = split_row(line)
        if not cells:
            if rows:
                break
            raise ValueError(
                f"malformed step card index row at line {line_number + 1}"
            )
        if len(cells) != len(STEP_CARD_INDEX_HEADERS) or is_separator(cells):
            raise ValueError(
                f"malformed step card index row at line {line_number + 1}"
            )
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
    if not rows:
        raise ValueError(f"step card index table is empty: {source_path}")
    return rows


def extract_step_cards(repo_root: Path) -> list[dict[str, Any]]:
    overview = absolute_path(PROPOSALS_OVERVIEW, repo_root)
    if not overview.is_file():
        raise ValueError(
            f"step proposals overview does not exist: {PROPOSALS_OVERVIEW.as_posix()}"
        )
    cards = [parse_step_card(path, repo_root) for path in step_card_paths(repo_root)]
    cards_by_id: dict[str, dict[str, Any]] = {}
    cards_by_file: dict[str, dict[str, Any]] = {}
    for card in cards:
        if card["id"] in cards_by_id:
            raise ValueError(f"duplicate step card id: {card['id']}")
        if card["file"] in cards_by_file:
            raise ValueError(f"duplicate step card path: {card['file']}")
        cards_by_id[card["id"]] = card
        cards_by_file[card["file"]] = card

    label_to_status = {
        label: status
        for status, label in INDEX_STATUS_BY_MACHINE.items()
    }
    indexed_ids: set[str] = set()
    indexed_files: set[str] = set()
    ordered: list[dict[str, Any]] = []
    for row_number, row in enumerate(step_card_index_rows(repo_root), start=1):
        identifier, status_cell, card_cell = row
        if STEP_CARD_ID_RE.fullmatch(identifier.text) is None:
            raise ValueError(
                f"invalid step card index id at row {row_number}: {identifier.text!r}"
            )
        if identifier.text in indexed_ids:
            raise ValueError(f"duplicate step card index id: {identifier.text}")
        if status_cell.text not in label_to_status:
            raise ValueError(
                f"invalid step card index status at row {row_number}: "
                f"{status_cell.text!r}"
            )
        if len(card_cell.links) != 1:
            raise ValueError(
                f"step card index row {row_number} must link exactly one step card"
            )
        link = card_cell.links[0]
        if card_cell.text != link["label"]:
            raise ValueError(
                f"step card index row {row_number} must contain only one step card link"
            )
        target = link["target"]
        if target in indexed_files:
            raise ValueError(f"duplicate step card index path: {target}")
        if target not in cards_by_file:
            raise ValueError(
                f"step card index points outside the card set: {target}"
            )
        card = cards_by_file[target]
        if identifier.text != card["id"]:
            raise ValueError(
                "step card index id mismatch: "
                f"{identifier.text} points to {card['id']}"
            )
        expected_status = label_to_status[status_cell.text]
        if expected_status != card["status"]:
            raise ValueError(
                "step card index status mismatch: "
                f"{card['id']} has {card['status']}, index has {status_cell.text}"
            )
        if link["label"] != card["title"]:
            raise ValueError(
                "step card index link label mismatch: "
                f"{card['id']} title is {card['title']!r}, link is {link['label']!r}"
            )
        indexed_ids.add(identifier.text)
        indexed_files.add(target)
        ordered.append(card)

    card_files = set(cards_by_file)
    card_ids = set(cards_by_id)
    if indexed_files != card_files or indexed_ids != card_ids:
        missing_files = sorted(card_files - indexed_files)
        extra_files = sorted(indexed_files - card_files)
        missing_ids = sorted(card_ids - indexed_ids)
        extra_ids = sorted(indexed_ids - card_ids)
        raise ValueError(
            "step card index does not exactly cover cards: "
            f"missing_files={missing_files}, extra_files={extra_files}, "
            f"missing_ids={missing_ids}, extra_ids={extra_ids}"
        )
    return ordered


def proposal_inventory_from_steps(
    steps: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    active: list[dict[str, Any]] = []
    history: list[dict[str, Any]] = []
    for step in steps:
        item = {
            "id": step["id"],
            "status": STEP_CARD_STATUSES[step["status"]],
            "proposal": step["task"],
            "reason": step["why_now"] or step["outcome"],
            "source_links": step["source_links"],
        }
        if step["status"] == "active":
            active.append(item)
        else:
            history.append(item)
    return active, history


def extract_planning_views(
    repo_root: Path,
    requirements_by_file: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    mapping_rows = strict_table_after_heading(
        SUMMARY_TABLE,
        "Карта широких строк",
        [
            "Идентификатор",
            "Слой требований",
            "Роль",
            "Каноническая карточка",
        ],
        repo_root,
        allow_preamble=True,
    )
    mappings: dict[str, dict[str, Any]] = {}
    mapping_ids: dict[str, str] = {}
    for row_number, row in enumerate(mapping_rows, start=1):
        if len(row) != 4:
            raise ValueError(
                f"planning view mapping row must contain four columns: row {row_number}"
            )
        identifier, layer_name, role, requirement_card = row
        if not re.fullmatch(r"PLAN-LAYER-[A-Z0-9-]+", identifier.text):
            raise ValueError(
                f"invalid planning view id: {identifier.text}"
            )
        known_layer = mapping_ids.get(identifier.text)
        if known_layer is not None and known_layer != layer_name.text:
            raise ValueError(
                f"planning view id is used by different layers: {identifier.text}"
            )
        mapping_ids[identifier.text] = layer_name.text
        mapping = mappings.setdefault(
            layer_name.text,
            {
                "id": identifier.text,
                "role": role.text,
                "requirement_links": [],
            },
        )
        if mapping["id"] != identifier.text or mapping["role"] != role.text:
            raise ValueError(
                f"inconsistent planning view mapping: {layer_name.text}"
            )
        if role.text == "Карточечно-связанный слой":
            if len(requirement_card.links) != 1:
                raise ValueError(
                    "planning view must link requirement cards or be marked as derived: "
                    f"{identifier.text}"
                )
            mapping["requirement_links"].append(requirement_card.links[0])
        elif role.text == "Производный слой":
            if requirement_card.text != "—" or requirement_card.links:
                raise ValueError(
                    f"derived planning view must not link a requirement card: "
                    f"{identifier.text}"
                )
        else:
            raise ValueError(
                "planning view must link requirement cards or be marked as derived: "
                f"{identifier.text}"
            )

    rows = strict_table_after_heading(
        SUMMARY_TABLE,
        "Сводная таблица",
        [
            "Слой требований",
            "Что нужно реализовать",
            "Предполагаемая реализация на документационной стадии",
            "Предполагаемая реализация в коробочной FUM",
            "Кандидаты и ближайшие артефакты",
            "Статус",
        ],
        repo_root,
        allow_preamble=True,
    )
    planning_views: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if len(row) != 6:
            raise ValueError(
                f"planning view row must contain six columns: row {index}"
            )
        (
            layer,
            result,
            documentation_stage,
            boxed_fum,
            candidates,
            status,
        ) = row
        mapping = mappings.pop(layer.text, None)
        if mapping is None:
            raise ValueError(
                f"planning view has no explicit mapping: {layer.text}"
            )
        planning_view_id = mapping["id"]
        linked_requirement_ids: list[str] = []
        for link in mapping["requirement_links"]:
            target = link["target"]
            requirement = requirements_by_file.get(target)
            if requirement is None:
                raise ValueError(
                    f"planning view links a non-requirement card: "
                    f"{planning_view_id} -> {target}"
                )
            if link["label"] != requirement["id"]:
                raise ValueError(
                    f"planning view requirement label must use stable id: "
                    f"{planning_view_id} -> {target}"
                )
            linked_requirement_ids.append(requirement["id"])

        if mapping["role"] == "Карточечно-связанный слой" and linked_requirement_ids:
            representation = "card-linked"
        elif mapping["role"] == "Производный слой" and not linked_requirement_ids:
            representation = "derived"
        else:
            raise ValueError(
                "planning view must link requirement cards or be marked as derived: "
                f"row {index}"
            )

        planning_views.append(
            {
                "id": planning_view_id,
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
                        "id": f"{planning_view_id}-doc-{option_index:02d}",
                        **option,
                    }
                    for option_index, option in enumerate(
                        split_items(documentation_stage, SUMMARY_TABLE, repo_root),
                        start=1,
                    )
                ],
                "boxed_fum_implementation": [
                    {
                        "id": f"{planning_view_id}-box-{option_index:02d}",
                        **option,
                    }
                    for option_index, option in enumerate(
                        split_items(boxed_fum, SUMMARY_TABLE, repo_root),
                        start=1,
                    )
                ],
                "candidates_and_artifacts": [
                    {
                        "id": f"{planning_view_id}-candidate-{candidate_index:02d}",
                        **candidate,
                    }
                    for candidate_index, candidate in enumerate(
                        split_items(candidates, SUMMARY_TABLE, repo_root),
                        start=1,
                    )
                ],
                "status": status.text,
                "representation": representation,
                "canonical_requirement_ids": sorted(set(linked_requirement_ids)),
                "source": {
                    "file": SUMMARY_TABLE.as_posix(),
                    "section": "Сводная таблица",
                    "row": index,
                    "mapping_section": "Карта широких строк",
                },
            }
        )
    if mappings:
        raise ValueError(
            "planning view mapping has no summary row: "
            + ", ".join(sorted(mappings))
        )
    return planning_views


def extract_product_queue(repo_root: Path) -> list[dict[str, Any]]:
    rows = table_after_heading(SUMMARY_TABLE, "Стадийная очередь продуктовых кандидатов", repo_root)
    queue: list[dict[str, Any]] = []
    for row in rows:
        if len(row) == 6:
            stage, order, candidate, first_result, requirements, conclusion = row
        elif len(row) == 5:
            stage = Cell(raw="", text="", links=[])
            order, candidate, first_result, requirements, conclusion = row
        else:
            continue
        queue.append(
            {
                "stage": stage.text,
                "stage_link": first_link_target(stage),
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


def extract_mvp_stage_map(repo_root: Path) -> list[dict[str, Any]]:
    rows = table_after_heading(MVP_README, "Стадийная карта кандидатов", repo_root)
    stage_map: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if len(row) != 4:
            continue
        candidate, documentation_stage, transition_result, boxed_fum = row
        stage_map.append(
            {
                "id": f"mvp-stage-{index:02d}",
                "candidate": candidate.text,
                "candidate_link": first_link_target(candidate),
                "documentation_stage_form": documentation_stage.text,
                "transition_result": transition_result.text,
                "boxed_fum_form": boxed_fum.text,
                "links": candidate.links + documentation_stage.links + transition_result.links + boxed_fum.links,
            }
        )
    return stage_map


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
        REQUIREMENTS_INDEX,
        SUMMARY_TABLE,
        ROADMAP,
        STAGES_README,
        DIRECTIONS_README,
        MVP_README,
        PROPOSALS_OVERVIEW,
        STEP_CARDS_INDEX,
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
    all_files.extend(requirement_card_paths(repo_root))
    all_files.extend(step_card_paths(repo_root))

    unique: dict[str, Path] = {}
    for path in all_files:
        unique[repo_relative(path, repo_root)] = path
    return [unique[key] for key in sorted(unique)]


def targets_from_planning_view(planning_view: dict[str, Any]) -> set[str]:
    targets: set[str] = set()
    for group in [
        planning_view["layer"],
        planning_view["required_result"],
        *planning_view["documentation_stage_implementation"],
        *planning_view["boxed_fum_implementation"],
        *planning_view["candidates_and_artifacts"],
    ]:
        for link in group.get("links", []):
            targets.add(link["target"])
    return targets


def coverage(planning_views: list[dict[str, Any]], inventory: dict[str, Any]) -> dict[str, Any]:
    targets_by_planning_view = {
        planning_view["id"]: targets_from_planning_view(planning_view)
        for planning_view in planning_views
    }

    def covered(target: str | None) -> list[str]:
        if target is None:
            return []
        return [
            planning_view_id
            for planning_view_id, targets in targets_by_planning_view.items()
            if target in targets
        ]

    product_queue_targets = {
        item["candidate_link"]
        for item in inventory["product_queue"]
        if item.get("candidate_link")
    }
    stage_map_targets = {
        item["candidate_link"]
        for item in inventory.get("mvp_stage_map", [])
        if item.get("candidate_link")
    }

    return {
        "directions": [
            {
                "title": direction["title"],
                "file": direction["file"],
                "covered_by_planning_view_ids": covered(direction["file"]),
            }
            for direction in inventory["directions"]
        ],
        "mvp_candidates": [
            {
                "title": candidate["title"],
                "file": candidate["file"],
                "covered_by_planning_view_ids": covered(candidate["file"]),
                "in_product_queue": candidate["file"] in product_queue_targets,
                "in_stage_map": candidate["file"] in stage_map_targets,
            }
            for candidate in inventory["mvp_candidates"]
        ],
        "open_questions": [
            {
                "title": question["title"],
                "file": question["file"],
                "covered_by_planning_view_ids": covered(question["file"]),
            }
            for question in inventory["questions"]["open"]
        ],
    }


def build_registry(repo_root: Path | None = None) -> dict[str, Any]:
    root = (repo_root or Path.cwd()).resolve()
    requirements = extract_requirement_cards(root)
    requirements_by_file = {
        requirement["file"]: requirement
        for requirement in requirements
    }
    planning_views = extract_planning_views(root, requirements_by_file)
    steps = extract_step_cards(root)
    active_proposals, proposal_history = proposal_inventory_from_steps(steps)
    inventory: dict[str, Any] = {
        "roadmap_horizons": extract_roadmap_horizons(root),
        "stages": extract_stages(root),
        "directions": extract_directions(root),
        "mvp_candidates": extract_mvp_candidates(root),
        "mvp_stage_map": extract_mvp_stage_map(root),
        "product_queue": extract_product_queue(root),
        "active_proposals": active_proposals,
        "proposal_history": proposal_history,
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
        "planning_views": planning_views,
        "steps": steps,
        "source_inventory": inventory,
        "coverage": coverage(planning_views, inventory),
    }


def validate_registry_object(registry: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if registry.get("schema") != SCHEMA:
        errors.append(f"unexpected schema: {registry.get('schema')}")
    if not registry.get("requirements"):
        errors.append("registry must contain at least one requirement")
    if not registry.get("planning_views"):
        errors.append("registry must contain at least one planning view")

    steps = registry.get("steps")
    step_ids: set[str] = set()
    if not isinstance(steps, list) or not steps:
        errors.append("registry must contain at least one step card")
        steps = []
    for step in steps:
        if not isinstance(step, dict):
            errors.append(f"invalid step card object: {step!r}")
            continue
        step_id = step.get("id")
        if not isinstance(step_id, str) or STEP_CARD_ID_RE.fullmatch(step_id) is None:
            errors.append(f"invalid step card id: {step_id}")
        elif step_id in step_ids:
            errors.append(f"duplicate step card id: {step_id}")
        else:
            step_ids.add(step_id)
        step_file = step.get("file")
        file_metadata: tuple[str, str, str] | None = None
        if not isinstance(step_file, str) or not step_file:
            errors.append(f"step card file is empty: {step_id}")
        else:
            step_path = Path(step_file)
            if step_path.parent != STEP_CARDS_DIR:
                errors.append(
                    f"step card file is outside {STEP_CARDS_DIR.as_posix()}: "
                    f"{step_file}"
                )
            else:
                try:
                    file_metadata = step_card_filename_metadata(step_path)
                except ValueError as error:
                    errors.append(str(error))
        if not isinstance(step.get("title"), str) or not step.get("title"):
            errors.append(f"step card title is empty: {step_id}")
        if not isinstance(step.get("task"), str) or not step.get("task"):
            errors.append(f"step card task is empty: {step_id}")
        status = step.get("status")
        if status not in STEP_CARD_STATUSES:
            errors.append(f"invalid step card status: {status}")
        if file_metadata is not None:
            filename_id, filename_status, _description = file_metadata
            if filename_id != step_id:
                errors.append(
                    "step card file id does not match step id: "
                    f"{filename_id} != {step_id}"
                )
            if filename_status != status:
                errors.append(
                    "step card file status does not match step status: "
                    f"{filename_status} != {status}"
                )
        source_links = step.get("source_links")
        if not isinstance(source_links, list) or not source_links:
            errors.append(f"step card source links are empty: {step_id}")
        if status == "active":
            if not isinstance(step.get("why_now"), str) or not step.get("why_now"):
                errors.append(f"active step card why_now is empty: {step_id}")
            criteria = step.get("criteria")
            if not isinstance(criteria, list) or not criteria:
                errors.append(f"active step card criteria are empty: {step_id}")
            if step.get("outcome") is not None:
                errors.append(f"active step card outcome must be null: {step_id}")
        elif status in STEP_CARD_STATUSES:
            if step.get("why_now") is not None:
                errors.append(f"historical step card why_now must be null: {step_id}")
            if step.get("criteria") != []:
                errors.append(f"historical step card criteria must be empty: {step_id}")
            if not isinstance(step.get("outcome"), str) or not step.get("outcome"):
                errors.append(f"historical step card outcome is empty: {step_id}")

    requirement_ids: set[str] = set()
    for requirement in registry.get("requirements", []):
        requirement_id = requirement.get("id")
        if not isinstance(requirement_id, str) or not re.fullmatch(
            r"FUM-REQ-[0-9]{4}",
            requirement_id,
        ):
            errors.append(f"invalid requirement id: {requirement_id}")
        elif requirement_id in requirement_ids:
            errors.append(f"duplicate requirement id: {requirement_id}")
        else:
            requirement_ids.add(requirement_id)
        status = requirement.get("status", {})
        if status.get("symbol") not in REQUIREMENT_STATUSES:
            errors.append(
                f"invalid requirement status: {status.get('symbol')}"
            )
        if not requirement.get("formulation", {}).get("text"):
            errors.append(f"requirement formulation is empty: {requirement_id}")
        if not requirement.get("criteria"):
            errors.append(f"requirement criteria are empty: {requirement_id}")

    inventory = registry.get("source_inventory", {})
    for field in ["roadmap_horizons", "stages", "directions", "mvp_candidates", "mvp_stage_map"]:
        if not inventory.get(field):
            errors.append(f"source inventory is empty: {field}")

    for field in ["active_proposals", "proposal_history"]:
        if not isinstance(inventory.get(field), list):
            errors.append(f"source inventory must contain list: {field}")
            continue
        for proposal in inventory[field]:
            proposal_id = proposal.get("id") if isinstance(proposal, dict) else None
            if proposal_id not in step_ids:
                errors.append(
                    f"source inventory {field} references unknown step card: "
                    f"{proposal_id}"
                )

    questions = inventory.get("questions")
    if not isinstance(questions, dict):
        errors.append("source inventory must contain questions")
    else:
        for field in ["open", "partially_clarified", "clarified"]:
            if not isinstance(questions.get(field), list):
                errors.append(f"source inventory questions must contain list: {field}")

    for item in registry.get("coverage", {}).get("mvp_candidates", []):
        if (
            not item.get("covered_by_planning_view_ids")
            and not item.get("in_product_queue")
            and not item.get("in_stage_map")
        ):
            errors.append(
                "MVP candidate is not covered by planning views, product queue or stage map: "
                f"{item.get('title')}"
            )
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
            "python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py build"
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
