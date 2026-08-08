#!/usr/bin/env python3
"""Build and validate the machine-readable FUM planning registry."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import sys
import tempfile
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCHEMA = "fum.planning.requirements-registry.v8"
BOXED_GRAPH_SCHEMA = "fum.planning.boxed-implementation-dependency-graph.v1"
BOXED_GRAPH_ID = "FUM-BOXED-IMPLEMENTATION-GRAPH"
BOXED_GRAPH_ELEMENT_IDS = [f"P{index}" for index in range(17)]
DEFAULT_OUTPUT = Path("Планирование/реестр-требований-вариантов-и-кандидатов.json")
SUMMARY_TABLE = Path("Планирование/сводная-таблица-требований-и-реализаций.md")
ROADMAP = Path("Планирование/дорожная-карта.md")
STAGES_README = Path("Планирование/стадии/README.md")
DIRECTIONS_README = Path("Планирование/направления-проектирования-и-развития/README.md")
MVP_README = Path("Планирование/MVP-кандидаты/README.md")
BOXED_GRAPH_MARKDOWN = Path(
    "Планирование/стадии/02-коробочная-реализация-FUM/граф-зависимостей.md"
)
BOXED_GRAPH_JSON = BOXED_GRAPH_MARKDOWN.with_suffix(".json")
PROPOSALS_OVERVIEW = Path("Планирование/предложения-о-следующих-шагах.md")
STEP_CARDS_DIR = Path("Планирование/карточки-шагов")
STEP_CARDS_INDEX = STEP_CARDS_DIR / "README.md"
КАТАЛОГ_КАРТОЧЕК_ЦЕПОЧЕК = Path("Планирование/карточки-цепочек-шагов")
ИНДЕКС_КАРТОЧЕК_ЦЕПОЧЕК = КАТАЛОГ_КАРТОЧЕК_ЦЕПОЧЕК / "README.md"
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

ШАБЛОН_ИДЕНТИФИКАТОРА_ЦЕПОЧКИ = re.compile(
    r"^FUM-ЦЕПОЧКА-[0-9]{4}$"
)
СОСТОЯНИЯ_ЦЕПОЧКИ = {
    "запланирована": {"эмодзи": "🟡", "метка": "Запланирована"},
    "активна": {"эмодзи": "🚧", "метка": "Активна"},
    "завершена": {"эмодзи": "✅", "метка": "Завершена"},
    "отозвана": {"эмодзи": "🗑️", "метка": "Отозвана"},
}
СОСТОЯНИЕ_ЦЕПОЧКИ_ПО_ЭМОДЗИ = {
    сведения["эмодзи"]: состояние
    for состояние, сведения in СОСТОЯНИЯ_ЦЕПОЧКИ.items()
}
СОСТОЯНИЕ_ЦЕПОЧКИ_ПО_МЕТКЕ = {
    f"{сведения['эмодзи']} {сведения['метка']}": состояние
    for состояние, сведения in СОСТОЯНИЯ_ЦЕПОЧКИ.items()
}
ЗАГОЛОВКИ_ИНДЕКСА_ЦЕПОЧЕК = [
    "Идентификатор",
    "Состояние",
    "Ветка",
    "Карточка",
]
ПОЛЯ_КАРТОЧКИ_ЦЕПОЧКИ = frozenset(
    {
        "версия_схемы",
        "идентификатор_цепочки",
        "состояние",
        "ветка",
        "базовая_ветка",
        "путь_проекта",
        "карточки_шагов",
    }
)
ПОЛЯ_ОБЪЕКТА_ЦЕПОЧКИ = frozenset(
    {
        "идентификатор",
        "файл",
        "заголовок",
        "состояние",
        "ветка",
        "базовая_ветка",
        "путь_проекта",
        "карточки_шагов",
    }
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

    sync_graph_hash = subparsers.add_parser(
        "sync-boxed-graph-source-hash",
        help=(
            "Atomically synchronize only the boxed graph Markdown source hash "
            "in its JSON projection"
        ),
    )
    sync_graph_hash.add_argument("--repo-root", type=Path, default=Path.cwd())
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


def exact_object(
    value: Any,
    expected_keys: set[str] | frozenset[str],
    label: str,
    errors: list[str],
) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        errors.append(f"{label} must be an object")
        return None
    missing = sorted(expected_keys - value.keys())
    unknown = sorted(value.keys() - expected_keys)
    if missing:
        errors.append(f"{label} is missing fields: {', '.join(missing)}")
    if unknown:
        errors.append(f"{label} has unknown fields: {', '.join(unknown)}")
    return value


def nonempty_string_list(value: Any, label: str, errors: list[str]) -> list[str]:
    if not isinstance(value, list) or not value:
        errors.append(f"{label} must be a non-empty list")
        return []
    result: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            errors.append(f"{label} must contain only non-empty strings")
            continue
        result.append(item)
    if len(result) != len(set(result)):
        errors.append(f"{label} must not contain duplicates")
    return result


def boxed_implementation_graph_errors(
    graph: Any,
    mvp_candidates: Any,
    repo_root: Path | None = None,
) -> list[str]:
    errors: list[str] = []
    root = exact_object(
        graph,
        {
            "schema",
            "graph_id",
            "source",
            "scope",
            "readiness_rule",
            "elements",
            "parallelizable_groups",
            "blocking_risks",
            "mvp_links",
        },
        "boxed implementation graph",
        errors,
    )
    if root is None:
        return errors

    if root.get("schema") != BOXED_GRAPH_SCHEMA:
        errors.append(f"unexpected boxed implementation graph schema: {root.get('schema')}")
    if root.get("graph_id") != BOXED_GRAPH_ID:
        errors.append(f"unexpected boxed implementation graph id: {root.get('graph_id')}")

    source = exact_object(
        root.get("source"),
        {"path", "content_sha256_without_recency"},
        "boxed implementation graph source",
        errors,
    )
    if source is not None:
        if source.get("path") != BOXED_GRAPH_MARKDOWN.as_posix():
            errors.append(
                "boxed implementation graph source path must be "
                f"{BOXED_GRAPH_MARKDOWN.as_posix()}"
            )
        digest = source.get("content_sha256_without_recency")
        if not isinstance(digest, str) or re.fullmatch(r"sha256:[0-9a-f]{64}", digest) is None:
            errors.append("boxed implementation graph source hash is malformed")
        if repo_root is not None and source.get("path") == BOXED_GRAPH_MARKDOWN.as_posix():
            source_path = absolute_path(BOXED_GRAPH_MARKDOWN, repo_root)
            if not source_path.is_file():
                errors.append("boxed implementation graph Markdown source does not exist")
            elif digest != content_sha256(BOXED_GRAPH_MARKDOWN, repo_root):
                errors.append("boxed implementation graph source hash does not match Markdown")

    scope = exact_object(
        root.get("scope"),
        {"kind", "statement", "excludes"},
        "boxed implementation graph scope",
        errors,
    )
    if scope is not None:
        if scope.get("kind") != "planning-hypothesis":
            errors.append("boxed implementation graph scope kind must be planning-hypothesis")
        if not isinstance(scope.get("statement"), str) or not scope["statement"].strip():
            errors.append("boxed implementation graph scope statement is empty")
        nonempty_string_list(
            scope.get("excludes"),
            "boxed implementation graph scope excludes",
            errors,
        )

    readiness_rule = exact_object(
        root.get("readiness_rule"),
        {
            "requires_all_dependencies_ready",
            "requires_all_readiness_prerequisites_met",
            "requires_all_blocking_risks_resolved",
            "requires_all_readiness_criteria_met",
        },
        "boxed implementation graph readiness rule",
        errors,
    )
    if readiness_rule is not None:
        for field in [
            "requires_all_dependencies_ready",
            "requires_all_readiness_prerequisites_met",
            "requires_all_blocking_risks_resolved",
            "requires_all_readiness_criteria_met",
        ]:
            if readiness_rule.get(field) is not True:
                errors.append(f"boxed implementation graph readiness rule {field} must be true")

    elements = root.get("elements")
    if not isinstance(elements, list) or not elements:
        errors.append("boxed implementation graph elements must be a non-empty list")
        elements = []
    elements_by_id: dict[str, dict[str, Any]] = {}
    dependencies_by_id: dict[str, list[str]] = {}
    orders: list[int] = []
    for index, value in enumerate(elements):
        element = exact_object(
            value,
            {
                "id",
                "order",
                "title",
                "depends_on",
                "readiness_prerequisites",
                "readiness_criteria",
            },
            f"boxed implementation graph element {index}",
            errors,
        )
        if element is None:
            continue
        element_id = element.get("id")
        if not isinstance(element_id, str) or re.fullmatch(r"P(?:0|[1-9][0-9]*)", element_id) is None:
            errors.append(f"invalid boxed implementation element id: {element_id}")
            continue
        if element_id in elements_by_id:
            errors.append(f"duplicate boxed implementation element id: {element_id}")
            continue
        order = element.get("order")
        if type(order) is not int or order < 0:
            errors.append(f"invalid boxed implementation element order: {element_id}")
        else:
            orders.append(order)
            if int(element_id[1:]) != order:
                errors.append(
                    "boxed implementation element id does not match order: "
                    f"{element_id} != {order}"
                )
        if not isinstance(element.get("title"), str) or not element["title"].strip():
            errors.append(f"boxed implementation element title is empty: {element_id}")
        depends_on = element.get("depends_on")
        if not isinstance(depends_on, list):
            errors.append(f"boxed implementation dependencies must be a list: {element_id}")
            depends_on = []
        elif any(not isinstance(item, str) for item in depends_on):
            errors.append(f"boxed implementation dependencies must be strings: {element_id}")
            depends_on = [item for item in depends_on if isinstance(item, str)]
        if len(depends_on) != len(set(depends_on)):
            errors.append(f"duplicate boxed implementation dependency: {element_id}")
        nonempty_string_list(
            element.get("readiness_prerequisites"),
            f"boxed implementation readiness prerequisites {element_id}",
            errors,
        )
        nonempty_string_list(
            element.get("readiness_criteria"),
            f"boxed implementation readiness criteria {element_id}",
            errors,
        )
        elements_by_id[element_id] = element
        dependencies_by_id[element_id] = depends_on

    if orders and orders != list(range(len(elements))):
        errors.append("boxed implementation element orders must be contiguous and sorted")
    if list(elements_by_id) != BOXED_GRAPH_ELEMENT_IDS:
        errors.append(
            "boxed implementation element ids must exactly match P0 through P16"
        )

    for element_id, dependencies in dependencies_by_id.items():
        for dependency_id in dependencies:
            if dependency_id not in elements_by_id:
                errors.append(f"unknown dependency {dependency_id} for {element_id}")
                continue
            if dependency_id == element_id:
                errors.append(f"boxed implementation element depends on itself: {element_id}")
                continue
    visit_state: dict[str, int] = {}

    def visit(element_id: str) -> bool:
        state = visit_state.get(element_id, 0)
        if state == 1:
            return True
        if state == 2:
            return False
        visit_state[element_id] = 1
        for dependency_id in dependencies_by_id.get(element_id, []):
            if dependency_id in elements_by_id and visit(dependency_id):
                return True
        visit_state[element_id] = 2
        return False

    if any(visit(element_id) for element_id in elements_by_id):
        errors.append("boxed implementation dependency cycle detected")

    def transitively_depends_on(element_id: str, target_id: str) -> bool:
        pending = list(dependencies_by_id.get(element_id, []))
        seen: set[str] = set()
        while pending:
            dependency_id = pending.pop()
            if dependency_id == target_id:
                return True
            if dependency_id in seen:
                continue
            seen.add(dependency_id)
            pending.extend(dependencies_by_id.get(dependency_id, []))
        return False

    groups = root.get("parallelizable_groups")
    if not isinstance(groups, list) or not groups:
        errors.append("boxed implementation parallelizable groups must be a non-empty list")
        groups = []
    group_ids: set[str] = set()
    for index, value in enumerate(groups):
        group = exact_object(
            value,
            {"id", "element_ids", "rationale"},
            f"boxed implementation parallelizable group {index}",
            errors,
        )
        if group is None:
            continue
        group_id = group.get("id")
        if not isinstance(group_id, str) or re.fullmatch(
            r"[a-z0-9]+(?:-[a-z0-9]+)*",
            group_id,
        ) is None:
            errors.append(f"invalid boxed implementation parallelizable group id: {group_id}")
        elif group_id in group_ids:
            errors.append(f"duplicate boxed implementation parallelizable group id: {group_id}")
        else:
            group_ids.add(group_id)
        element_ids = group.get("element_ids")
        if not isinstance(element_ids, list) or len(element_ids) < 2:
            errors.append(f"parallelizable group must contain at least two elements: {group_id}")
            element_ids = []
        elif any(not isinstance(item, str) for item in element_ids):
            errors.append(f"parallelizable group element ids must be strings: {group_id}")
            element_ids = [item for item in element_ids if isinstance(item, str)]
        if len(element_ids) != len(set(element_ids)):
            errors.append(f"parallelizable group contains duplicate elements: {group_id}")
        for element_id in element_ids:
            if element_id not in elements_by_id:
                errors.append(f"parallelizable group references unknown element {element_id}")
        for left_index, left_id in enumerate(element_ids):
            for right_id in element_ids[left_index + 1 :]:
                if left_id not in elements_by_id or right_id not in elements_by_id:
                    continue
                if transitively_depends_on(left_id, right_id) or transitively_depends_on(
                    right_id,
                    left_id,
                ):
                    errors.append(
                        "parallelizable group contains dependent elements: "
                        f"{group_id}: {left_id}, {right_id}"
                    )
        if not isinstance(group.get("rationale"), str) or not group["rationale"].strip():
            errors.append(f"parallelizable group rationale is empty: {group_id}")

    risks = root.get("blocking_risks")
    if not isinstance(risks, list) or not risks:
        errors.append("boxed implementation blocking risks must be a non-empty list")
        risks = []
    risk_ids: set[str] = set()
    for index, value in enumerate(risks):
        risk = exact_object(
            value,
            {
                "id",
                "title",
                "description",
                "blocks_element_ids",
                "resolution_criteria",
                "source_paths",
            },
            f"boxed implementation blocking risk {index}",
            errors,
        )
        if risk is None:
            continue
        risk_id = risk.get("id")
        if not isinstance(risk_id, str) or re.fullmatch(r"RISK-[0-9]{2}", risk_id) is None:
            errors.append(f"invalid boxed implementation blocking risk id: {risk_id}")
        elif risk_id in risk_ids:
            errors.append(f"duplicate boxed implementation blocking risk id: {risk_id}")
        else:
            risk_ids.add(risk_id)
        for field in ["title", "description"]:
            if not isinstance(risk.get(field), str) or not risk[field].strip():
                errors.append(f"blocking risk {field} is empty: {risk_id}")
        blocked_ids = nonempty_string_list(
            risk.get("blocks_element_ids"),
            f"blocking risk element ids {risk_id}",
            errors,
        )
        for element_id in blocked_ids:
            if element_id not in elements_by_id:
                errors.append(f"blocking risk references unknown element {element_id}")
        nonempty_string_list(
            risk.get("resolution_criteria"),
            f"blocking risk resolution criteria {risk_id}",
            errors,
        )
        source_paths = nonempty_string_list(
            risk.get("source_paths"),
            f"blocking risk source paths {risk_id}",
            errors,
        )
        if repo_root is not None:
            for source_path in source_paths:
                path = Path(source_path)
                if path.is_absolute() or ".." in path.parts:
                    errors.append(f"blocking risk source path is not repository-relative: {risk_id}")
                elif not absolute_path(path, repo_root).is_file():
                    errors.append(f"blocking risk source path does not exist: {source_path}")

    candidate_lookup: dict[str, str] = {}
    if isinstance(mvp_candidates, list):
        for candidate in mvp_candidates:
            if not isinstance(candidate, dict):
                continue
            candidate_id = candidate.get("id")
            candidate_file = candidate.get("file")
            if isinstance(candidate_id, str) and isinstance(candidate_file, str):
                candidate_lookup[candidate_id] = candidate_file

    links = root.get("mvp_links")
    if not isinstance(links, list) or not links:
        errors.append("boxed implementation MVP links must be a non-empty list")
        links = []
    linked_candidate_ids: set[str] = set()
    for index, value in enumerate(links):
        link = exact_object(
            value,
            {"mvp_candidate_id", "mvp_path", "element_ids", "role"},
            f"boxed implementation MVP link {index}",
            errors,
        )
        if link is None:
            continue
        candidate_id = link.get("mvp_candidate_id")
        if not isinstance(candidate_id, str) or re.fullmatch(r"mvp-[0-9]{2}", candidate_id) is None:
            errors.append(f"invalid MVP candidate id in boxed implementation graph: {candidate_id}")
        elif candidate_id not in candidate_lookup:
            errors.append(f"unknown MVP candidate {candidate_id} in boxed implementation graph")
        elif candidate_id in linked_candidate_ids:
            errors.append(f"duplicate MVP candidate link {candidate_id}")
        else:
            linked_candidate_ids.add(candidate_id)
            if link.get("mvp_path") != candidate_lookup[candidate_id]:
                errors.append(f"MVP candidate path does not match inventory: {candidate_id}")
        element_ids = nonempty_string_list(
            link.get("element_ids"),
            f"MVP link element ids {candidate_id}",
            errors,
        )
        for element_id in element_ids:
            if element_id not in elements_by_id:
                errors.append(f"MVP link references unknown element {element_id}")
        if not isinstance(link.get("role"), str) or not link["role"].strip():
            errors.append(f"MVP link role is empty: {candidate_id}")

    missing_candidate_ids = sorted(candidate_lookup.keys() - linked_candidate_ids)
    if missing_candidate_ids:
        errors.append(
            "boxed implementation graph does not cover MVP candidates: "
            + ", ".join(missing_candidate_ids)
        )
    return errors


def extract_boxed_implementation_graph(
    repo_root: Path,
    mvp_candidates: list[dict[str, Any]],
) -> dict[str, Any]:
    path = absolute_path(BOXED_GRAPH_JSON, repo_root)
    if not path.is_file():
        raise ValueError(
            "boxed implementation dependency graph does not exist: "
            f"{BOXED_GRAPH_JSON.as_posix()}"
        )
    try:
        graph = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError(
            f"boxed implementation dependency graph is not valid JSON: {error}"
        ) from error
    errors = boxed_implementation_graph_errors(graph, mvp_candidates, repo_root)
    if errors:
        raise ValueError("\n".join(errors))
    return graph


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


def метаданные_имени_карточки_цепочки(
    путь: Path,
) -> tuple[str, str, str]:
    имя = путь.name
    if len(имя.encode("utf-8")) > 255:
        raise ValueError(
            f"step chain card filename exceeds 255 UTF-8 bytes: {имя}"
        )

    эмодзи_имени: str | None = None
    состояние_имени: str | None = None
    for эмодзи in sorted(
        СОСТОЯНИЕ_ЦЕПОЧКИ_ПО_ЭМОДЗИ,
        key=len,
        reverse=True,
    ):
        if имя.startswith(f"{эмодзи}-"):
            эмодзи_имени = эмодзи
            состояние_имени = СОСТОЯНИЕ_ЦЕПОЧКИ_ПО_ЭМОДЗИ[эмодзи]
            break
    if эмодзи_имени is None or состояние_имени is None:
        raise ValueError(f"invalid step chain card filename state emoji: {имя}")

    остаток = имя[len(эмодзи_имени) + 1 :]
    совпадение = re.fullmatch(
        r"(FUM-ЦЕПОЧКА-[0-9]{4})-(.*)\.md",
        остаток,
    )
    if совпадение is None:
        raise ValueError(
            "invalid step chain card filename; expected "
            f"<emoji>-FUM-ЦЕПОЧКА-NNNN-<description>.md: {имя}"
        )
    идентификатор, описание = совпадение.groups()
    части_описания = описание.split("-")
    if (
        not описание
        or any(not часть for часть in части_описания)
        or any(
            not all(символ.isalnum() for символ in часть)
            for часть in части_описания
        )
    ):
        raise ValueError(
            "invalid step chain card filename description; expected Unicode "
            f"letters or digits separated by single hyphens: {имя}"
        )
    return идентификатор, состояние_имени, описание


def пути_карточек_цепочек(корень: Path) -> list[Path]:
    каталог = absolute_path(КАТАЛОГ_КАРТОЧЕК_ЦЕПОЧЕК, корень)
    if not каталог.is_dir():
        raise ValueError(
            "step chain cards directory does not exist: "
            f"{КАТАЛОГ_КАРТОЧЕК_ЦЕПОЧЕК.as_posix()}"
        )
    пути_разметки = sorted(
        путь
        for путь in каталог.rglob("*")
        if путь.is_file() and путь.suffix.casefold() == ".md"
    )
    путь_индекса = каталог / ИНДЕКС_КАРТОЧЕК_ЦЕПОЧЕК.name
    пути: list[Path] = []
    for путь in пути_разметки:
        if путь == путь_индекса:
            continue
        if путь.parent != каталог:
            относительный_путь = путь.relative_to(каталог).as_posix()
            raise ValueError(
                "step chain cards directory must be flat; nested Markdown is "
                f"forbidden: {относительный_путь}"
            )
        пути.append(путь)
    if not пути:
        raise ValueError(
            "step chain cards directory contains no cards: "
            f"{КАТАЛОГ_КАРТОЧЕК_ЦЕПОЧЕК.as_posix()}"
        )
    return пути


def разделить_метаданные_карточки_цепочки(
    текст: str,
    исходный_файл: str,
) -> tuple[dict[str, Any], str]:
    if not текст.startswith("+++\n"):
        raise ValueError(
            f"step chain card must start with TOML frontmatter: {исходный_файл}"
        )
    закрытие = текст.find("\n+++\n", 4)
    if закрытие < 0:
        raise ValueError(
            f"step chain card TOML frontmatter is not closed: {исходный_файл}"
        )
    try:
        метаданные = tomllib.loads(текст[4:закрытие])
    except tomllib.TOMLDecodeError as ошибка:
        raise ValueError(
            f"invalid step chain card TOML in {исходный_файл}: {ошибка}"
        ) from ошибка
    if not isinstance(метаданные, dict):
        raise ValueError(
            f"step chain card TOML must be a table: {исходный_файл}"
        )
    ключи = frozenset(метаданные)
    отсутствующие = ПОЛЯ_КАРТОЧКИ_ЦЕПОЧКИ - ключи
    неизвестные = ключи - ПОЛЯ_КАРТОЧКИ_ЦЕПОЧКИ
    if отсутствующие:
        raise ValueError(
            "missing step chain card TOML fields in "
            f"{исходный_файл}: {', '.join(sorted(отсутствующие))}"
        )
    if неизвестные:
        raise ValueError(
            "unknown step chain card TOML fields in "
            f"{исходный_файл}: {', '.join(sorted(неизвестные))}"
        )
    тело = RECENCY_RE.sub("\n", текст[закрытие + 5 :]).strip() + "\n"
    return метаданные, тело


def проверить_ссылку_локальной_ветки(
    значение: Any,
    требуемый_префикс: str,
    описание: str,
) -> str:
    if not isinstance(значение, str) or not значение.startswith(
        требуемый_префикс
    ):
        raise ValueError(
            f"{описание} must start with {требуемый_префикс}: {значение!r}"
        )
    if not значение.startswith("refs/heads/"):
        raise ValueError(f"{описание} must be a local branch: {значение!r}")
    имя_ветки = значение[len("refs/heads/") :]
    запрещённые_фрагменты = ("..", "@{")
    запрещённые_символы = "~^:?*[\\"
    части = имя_ветки.split("/")
    недопустимо = (
        not имя_ветки
        or имя_ветки == "@"
        or значение.endswith((".", "/"))
        or any(фрагмент in значение for фрагмент in запрещённые_фрагменты)
        or any(
            ord(символ) <= 32
            or ord(символ) == 127
            or символ in запрещённые_символы
            for символ in значение
        )
        or any(
            not часть
            or часть.startswith((".", "-"))
            or часть.endswith((".", ".lock"))
            for часть in части
        )
    )
    if недопустимо:
        raise ValueError(f"invalid {описание}: {значение!r}")
    return значение


def проверить_относительный_путь_проекта(
    значение: Any,
    корень: Path | None = None,
) -> str:
    if not isinstance(значение, str) or not значение:
        raise ValueError(f"step chain project path must be non-empty: {значение!r}")
    путь = Path(значение)
    if (
        путь.is_absolute()
        or значение != путь.as_posix()
        or any(часть in {"", ".", ".."} for часть in путь.parts)
        or any(ord(символ) < 32 or ord(символ) == 127 for символ in значение)
    ):
        raise ValueError(
            f"step chain project path must be a normalized relative path: {значение!r}"
        )
    if корень is None:
        return значение
    разрешённый_корень = корень.resolve()
    разрешённый_путь = (разрешённый_корень / путь).resolve()
    try:
        разрешённый_путь.relative_to(разрешённый_корень)
    except ValueError as ошибка:
        raise ValueError(
            f"step chain project path leaves repository: {значение!r}"
        ) from ошибка
    if not разрешённый_путь.exists():
        raise ValueError(
            f"step chain project path does not exist: {значение!r}"
        )
    return значение


def разобрать_карточку_цепочки(
    путь: Path,
    корень: Path,
    известные_шаги: set[str],
) -> dict[str, Any]:
    идентификатор_имени, состояние_имени, _описание = (
        метаданные_имени_карточки_цепочки(путь)
    )
    исходный_файл = repo_relative(путь, корень)
    метаданные, тело = разделить_метаданные_карточки_цепочки(
        путь.read_text(encoding="utf-8"),
        исходный_файл,
    )
    версия_схемы = метаданные["версия_схемы"]
    if type(версия_схемы) is not int or версия_схемы != 1:
        raise ValueError(
            "step chain card supports only версия_схемы = 1: "
            f"{исходный_файл}"
        )
    идентификатор = метаданные["идентификатор_цепочки"]
    if (
        not isinstance(идентификатор, str)
        or ШАБЛОН_ИДЕНТИФИКАТОРА_ЦЕПОЧКИ.fullmatch(идентификатор) is None
    ):
        raise ValueError(
            f"invalid step chain id in {исходный_файл}: {идентификатор!r}"
        )
    if идентификатор_имени != идентификатор:
        raise ValueError(
            "step chain card filename id does not match TOML id in "
            f"{исходный_файл}: {идентификатор_имени!r} != {идентификатор!r}"
        )
    состояние = метаданные["состояние"]
    if not isinstance(состояние, str) or состояние not in СОСТОЯНИЯ_ЦЕПОЧКИ:
        raise ValueError(
            f"invalid step chain state in {исходный_файл}: {состояние!r}"
        )
    if состояние_имени != состояние:
        raise ValueError(
            "step chain card filename state does not match TOML state in "
            f"{исходный_файл}: {состояние_имени!r} != {состояние!r}"
        )
    ветка = проверить_ссылку_локальной_ветки(
        метаданные["ветка"],
        "refs/heads/codex/",
        "step chain branch",
    )
    базовая_ветка = проверить_ссылку_локальной_ветки(
        метаданные["базовая_ветка"],
        "refs/heads/",
        "step chain base branch",
    )
    путь_проекта = проверить_относительный_путь_проекта(
        метаданные["путь_проекта"],
        корень,
    )
    карточки_шагов = метаданные["карточки_шагов"]
    if not isinstance(карточки_шагов, list) or not карточки_шагов:
        raise ValueError(
            f"step chain step cards must be a non-empty list: {исходный_файл}"
        )
    проверенные_шаги: list[str] = []
    for карточка_шага in карточки_шагов:
        if (
            not isinstance(карточка_шага, str)
            or STEP_CARD_ID_RE.fullmatch(карточка_шага) is None
        ):
            raise ValueError(
                "invalid step card id in step chain "
                f"{идентификатор}: {карточка_шага!r}"
            )
        if карточка_шага in проверенные_шаги:
            raise ValueError(
                "duplicate step card in step chain "
                f"{идентификатор}: {карточка_шага}"
            )
        if карточка_шага not in известные_шаги:
            raise ValueError(
                f"unknown step card {карточка_шага} in step chain {идентификатор}"
            )
        проверенные_шаги.append(карточка_шага)

    заголовки = list(re.finditer(r"^#\s+(.+?)\s*$", тело, re.MULTILINE))
    if len(заголовки) != 1:
        raise ValueError(
            "step chain card must contain exactly one level-one heading: "
            f"{исходный_файл}"
        )
    заголовок = clean_text(заголовки[0].group(1))
    if not заголовок:
        raise ValueError(f"step chain card title is empty: {исходный_файл}")

    return {
        "идентификатор": идентификатор,
        "файл": исходный_файл,
        "заголовок": заголовок,
        "состояние": состояние,
        "ветка": ветка,
        "базовая_ветка": базовая_ветка,
        "путь_проекта": путь_проекта,
        "карточки_шагов": проверенные_шаги,
    }


def строки_индекса_цепочек(корень: Path) -> list[list[Cell]]:
    исходный_путь = ИНДЕКС_КАРТОЧЕК_ЦЕПОЧЕК
    текст = read_text(исходный_путь, корень)
    строки = текст.splitlines()
    номера_заголовков = [
        номер
        for номер, строка in enumerate(строки)
        if [clean_text(ячейка) for ячейка in split_row(строка)]
        == ЗАГОЛОВКИ_ИНДЕКСА_ЦЕПОЧЕК
    ]
    if len(номера_заголовков) != 1:
        raise ValueError(
            "step chain index must contain exactly one table with headers "
            f"{' | '.join(ЗАГОЛОВКИ_ИНДЕКСА_ЦЕПОЧЕК)}: "
            f"{исходный_путь.as_posix()}"
        )
    номер_заголовка = номера_заголовков[0]
    номер_разделителя = номер_заголовка + 1
    if номер_разделителя >= len(строки):
        raise ValueError(
            f"step chain index table has no separator: {исходный_путь}"
        )
    разделитель = split_row(строки[номер_разделителя])
    if (
        len(разделитель) != len(ЗАГОЛОВКИ_ИНДЕКСА_ЦЕПОЧЕК)
        or not is_separator(разделитель)
    ):
        raise ValueError(
            f"step chain index table has invalid separator: {исходный_путь}"
        )

    результат: list[list[Cell]] = []
    for номер_строки in range(номер_разделителя + 1, len(строки)):
        строка = строки[номер_строки]
        if not строка.strip():
            if результат:
                break
            continue
        ячейки = split_row(строка)
        if not ячейки:
            if результат:
                break
            raise ValueError(
                f"malformed step chain index row at line {номер_строки + 1}"
            )
        if (
            len(ячейки) != len(ЗАГОЛОВКИ_ИНДЕКСА_ЦЕПОЧЕК)
            or is_separator(ячейки)
        ):
            raise ValueError(
                f"malformed step chain index row at line {номер_строки + 1}"
            )
        результат.append(
            [
                Cell(
                    raw=ячейка,
                    text=clean_text(ячейка),
                    links=links_from_markdown(
                        ячейка,
                        исходный_путь,
                        корень,
                    ),
                )
                for ячейка in ячейки
            ]
        )
    if not результат:
        raise ValueError(f"step chain index table is empty: {исходный_путь}")
    return результат


def извлечь_карточки_цепочек(
    корень: Path,
    шаги: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    известные_шаги = {шаг["id"] for шаг in шаги}
    карточки = [
        разобрать_карточку_цепочки(путь, корень, известные_шаги)
        for путь in пути_карточек_цепочек(корень)
    ]
    карточки_по_идентификатору: dict[str, dict[str, Any]] = {}
    карточки_по_файлу: dict[str, dict[str, Any]] = {}
    карточки_по_ветке: dict[str, dict[str, Any]] = {}
    for карточка in карточки:
        идентификатор = карточка["идентификатор"]
        файл = карточка["файл"]
        ветка = карточка["ветка"]
        if идентификатор in карточки_по_идентификатору:
            raise ValueError(f"duplicate step chain id: {идентификатор}")
        if файл in карточки_по_файлу:
            raise ValueError(f"duplicate step chain path: {файл}")
        if ветка in карточки_по_ветке:
            raise ValueError(f"duplicate step chain branch: {ветка}")
        карточки_по_идентификатору[идентификатор] = карточка
        карточки_по_файлу[файл] = карточка
        карточки_по_ветке[ветка] = карточка

    индексированные_идентификаторы: set[str] = set()
    индексированные_файлы: set[str] = set()
    упорядоченные: list[dict[str, Any]] = []
    for номер_строки, строка in enumerate(
        строки_индекса_цепочек(корень),
        start=1,
    ):
        идентификатор, состояние, ветка, карточка_ячейка = строка
        if (
            ШАБЛОН_ИДЕНТИФИКАТОРА_ЦЕПОЧКИ.fullmatch(
                идентификатор.text
            )
            is None
        ):
            raise ValueError(
                "invalid step chain index id at row "
                f"{номер_строки}: {идентификатор.text!r}"
            )
        if идентификатор.text in индексированные_идентификаторы:
            raise ValueError(
                f"duplicate step chain index id: {идентификатор.text}"
            )
        if состояние.text not in СОСТОЯНИЕ_ЦЕПОЧКИ_ПО_МЕТКЕ:
            raise ValueError(
                "invalid step chain index state at row "
                f"{номер_строки}: {состояние.text!r}"
            )
        if len(карточка_ячейка.links) != 1:
            raise ValueError(
                f"step chain index row {номер_строки} must link exactly one card"
            )
        ссылка = карточка_ячейка.links[0]
        if карточка_ячейка.text != ссылка["label"]:
            raise ValueError(
                f"step chain index row {номер_строки} must contain only one card link"
            )
        целевой_файл = ссылка["target"]
        if целевой_файл in индексированные_файлы:
            raise ValueError(f"duplicate step chain index path: {целевой_файл}")
        if целевой_файл not in карточки_по_файлу:
            raise ValueError(
                f"step chain index points outside the card set: {целевой_файл}"
            )
        карточка = карточки_по_файлу[целевой_файл]
        if идентификатор.text != карточка["идентификатор"]:
            raise ValueError(
                "step chain index id mismatch: "
                f"{идентификатор.text} points to {карточка['идентификатор']}"
            )
        ожидаемое_состояние = СОСТОЯНИЕ_ЦЕПОЧКИ_ПО_МЕТКЕ[
            состояние.text
        ]
        if ожидаемое_состояние != карточка["состояние"]:
            raise ValueError(
                "step chain index state mismatch: "
                f"{карточка['идентификатор']} has {карточка['состояние']}, "
                f"index has {состояние.text}"
            )
        if ветка.text != карточка["ветка"]:
            raise ValueError(
                "step chain index branch mismatch: "
                f"{карточка['идентификатор']} has {карточка['ветка']}, "
                f"index has {ветка.text}"
            )
        if ссылка["label"] != карточка["заголовок"]:
            raise ValueError(
                "step chain index link label mismatch: "
                f"{карточка['идентификатор']} title is "
                f"{карточка['заголовок']!r}, link is {ссылка['label']!r}"
            )
        индексированные_идентификаторы.add(идентификатор.text)
        индексированные_файлы.add(целевой_файл)
        упорядоченные.append(карточка)

    файлы_карточек = set(карточки_по_файлу)
    идентификаторы_карточек = set(карточки_по_идентификатору)
    if (
        индексированные_файлы != файлы_карточек
        or индексированные_идентификаторы != идентификаторы_карточек
    ):
        отсутствующие_файлы = sorted(
            файлы_карточек - индексированные_файлы
        )
        лишние_файлы = sorted(индексированные_файлы - файлы_карточек)
        отсутствующие_идентификаторы = sorted(
            идентификаторы_карточек - индексированные_идентификаторы
        )
        лишние_идентификаторы = sorted(
            индексированные_идентификаторы - идентификаторы_карточек
        )
        raise ValueError(
            "step chain index does not exactly cover cards: "
            f"missing_files={отсутствующие_файлы}, "
            f"extra_files={лишние_файлы}, "
            f"missing_ids={отсутствующие_идентификаторы}, "
            f"extra_ids={лишние_идентификаторы}"
        )

    занятость_шагов: dict[str, str] = {}
    for карточка in упорядоченные:
        if карточка["состояние"] == "отозвана":
            continue
        for карточка_шага in карточка["карточки_шагов"]:
            предыдущая_цепочка = занятость_шагов.get(карточка_шага)
            if предыдущая_цепочка is not None:
                raise ValueError(
                    "duplicate step chain membership for "
                    f"{карточка_шага}: {предыдущая_цепочка}, "
                    f"{карточка['идентификатор']}"
                )
            занятость_шагов[карточка_шага] = карточка["идентификатор"]
    активные_цепочки = [
        карточка
        for карточка in упорядоченные
        if карточка["состояние"] == "активна"
    ]
    if len(активные_цепочки) != 1:
        raise ValueError(
            "registry must contain exactly one active step chain: "
            f"found {len(активные_цепочки)}"
        )
    return упорядоченные


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
        BOXED_GRAPH_MARKDOWN,
        BOXED_GRAPH_JSON,
        PROPOSALS_OVERVIEW,
        STEP_CARDS_INDEX,
        ИНДЕКС_КАРТОЧЕК_ЦЕПОЧЕК,
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
    all_files.extend(пути_карточек_цепочек(repo_root))

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
    цепочки_шагов = извлечь_карточки_цепочек(root, steps)
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
    boxed_implementation_graph = extract_boxed_implementation_graph(
        root,
        inventory["mvp_candidates"],
    )
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
        "цепочки_шагов": цепочки_шагов,
        "boxed_implementation_graph": boxed_implementation_graph,
        "source_inventory": inventory,
        "coverage": coverage(planning_views, inventory),
    }


def ошибки_цепочек_шагов(
    значение: Any,
    известные_шаги: set[str],
) -> list[str]:
    ошибки: list[str] = []
    if not isinstance(значение, list) or not значение:
        ошибки.append("registry must contain at least one step chain")
        return ошибки

    идентификаторы: set[str] = set()
    файлы: set[str] = set()
    ветки: set[str] = set()
    занятость_шагов: dict[str, str] = {}
    количество_активных_цепочек = 0
    for номер, исходный_объект in enumerate(значение, start=1):
        объект = exact_object(
            исходный_объект,
            ПОЛЯ_ОБЪЕКТА_ЦЕПОЧКИ,
            f"step chain {номер}",
            ошибки,
        )
        if объект is None:
            continue

        идентификатор = объект.get("идентификатор")
        if (
            not isinstance(идентификатор, str)
            or ШАБЛОН_ИДЕНТИФИКАТОРА_ЦЕПОЧКИ.fullmatch(идентификатор)
            is None
        ):
            ошибки.append(f"invalid step chain id: {идентификатор}")
        elif идентификатор in идентификаторы:
            ошибки.append(f"duplicate step chain id: {идентификатор}")
        else:
            идентификаторы.add(идентификатор)

        файл = объект.get("файл")
        метаданные_имени: tuple[str, str, str] | None = None
        if not isinstance(файл, str) or not файл:
            ошибки.append(f"step chain card file is empty: {идентификатор}")
        else:
            путь = Path(файл)
            if путь.parent != КАТАЛОГ_КАРТОЧЕК_ЦЕПОЧЕК:
                ошибки.append(
                    "step chain card file is outside "
                    f"{КАТАЛОГ_КАРТОЧЕК_ЦЕПОЧЕК.as_posix()}: {файл}"
                )
            else:
                try:
                    метаданные_имени = метаданные_имени_карточки_цепочки(
                        путь
                    )
                except ValueError as ошибка:
                    ошибки.append(str(ошибка))
            if файл in файлы:
                ошибки.append(f"duplicate step chain path: {файл}")
            else:
                файлы.add(файл)

        заголовок = объект.get("заголовок")
        if not isinstance(заголовок, str) or not заголовок:
            ошибки.append(f"step chain card title is empty: {идентификатор}")

        состояние = объект.get("состояние")
        if состояние not in СОСТОЯНИЯ_ЦЕПОЧКИ:
            ошибки.append(f"invalid step chain state: {состояние}")
        elif состояние == "активна":
            количество_активных_цепочек += 1
        if метаданные_имени is not None:
            идентификатор_имени, состояние_имени, _описание = метаданные_имени
            if идентификатор_имени != идентификатор:
                ошибки.append(
                    "step chain card file id does not match chain id: "
                    f"{идентификатор_имени} != {идентификатор}"
                )
            if состояние_имени != состояние:
                ошибки.append(
                    "step chain card file state does not match chain state: "
                    f"{состояние_имени} != {состояние}"
                )

        ветка = объект.get("ветка")
        try:
            проверить_ссылку_локальной_ветки(
                ветка,
                "refs/heads/codex/",
                "step chain branch",
            )
        except ValueError as ошибка:
            ошибки.append(str(ошибка))
        if isinstance(ветка, str):
            if ветка in ветки:
                ошибки.append(f"duplicate step chain branch: {ветка}")
            else:
                ветки.add(ветка)

        try:
            проверить_ссылку_локальной_ветки(
                объект.get("базовая_ветка"),
                "refs/heads/",
                "step chain base branch",
            )
        except ValueError as ошибка:
            ошибки.append(str(ошибка))
        try:
            проверить_относительный_путь_проекта(
                объект.get("путь_проекта")
            )
        except ValueError as ошибка:
            ошибки.append(str(ошибка))

        карточки_шагов = nonempty_string_list(
            объект.get("карточки_шагов"),
            f"step chain {идентификатор} step cards",
            ошибки,
        )
        for карточка_шага in карточки_шагов:
            if STEP_CARD_ID_RE.fullmatch(карточка_шага) is None:
                ошибки.append(
                    "invalid step card id in step chain "
                    f"{идентификатор}: {карточка_шага}"
                )
                continue
            if карточка_шага not in известные_шаги:
                ошибки.append(
                    f"unknown step card {карточка_шага} in step chain "
                    f"{идентификатор}"
                )
            if состояние == "отозвана":
                continue
            предыдущая_цепочка = занятость_шагов.get(карточка_шага)
            if предыдущая_цепочка is not None:
                ошибки.append(
                    "duplicate step chain membership for "
                    f"{карточка_шага}: {предыдущая_цепочка}, "
                    f"{идентификатор}"
                )
            else:
                занятость_шагов[карточка_шага] = str(идентификатор)
    if количество_активных_цепочек != 1:
        ошибки.append(
            "registry must contain exactly one active step chain: "
            f"found {количество_активных_цепочек}"
        )
    return ошибки


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

    errors.extend(
        ошибки_цепочек_шагов(
            registry.get("цепочки_шагов"),
            step_ids,
        )
    )

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
    if not isinstance(inventory, dict):
        errors.append("source inventory must be an object")
        inventory = {}
    for field in ["roadmap_horizons", "stages", "directions", "mvp_candidates", "mvp_stage_map"]:
        if not inventory.get(field):
            errors.append(f"source inventory is empty: {field}")

    errors.extend(
        boxed_implementation_graph_errors(
            registry.get("boxed_implementation_graph"),
            inventory.get("mvp_candidates"),
        )
    )

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


def canonical_existing_file(
    relative_path: Path,
    repo_root: Path,
    label: str,
) -> Path:
    lexical_path = repo_root / relative_path
    try:
        resolved_path = lexical_path.resolve(strict=True)
    except FileNotFoundError as error:
        raise ValueError(f"{label} does not exist: {relative_path.as_posix()}") from error
    try:
        resolved_path.relative_to(repo_root)
    except ValueError as error:
        raise ValueError(f"{label} path escapes repository root") from error
    if resolved_path != lexical_path or lexical_path.is_symlink():
        raise ValueError(f"{label} path must not contain symbolic links")
    if not resolved_path.is_file():
        raise ValueError(f"{label} is not a regular file: {relative_path.as_posix()}")
    return resolved_path


def atomic_replace_text(path: Path, text: str) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    temporary_path = Path(temporary_name)
    try:
        os.fchmod(descriptor, stat.S_IMODE(path.stat().st_mode))
        handle = os.fdopen(descriptor, "w", encoding="utf-8", newline="")
        descriptor = -1
        with handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
    finally:
        if descriptor >= 0:
            os.close(descriptor)
        temporary_path.unlink(missing_ok=True)


def sync_boxed_graph_source_hash(repo_root: Path | None = None) -> bool:
    root = (repo_root or Path.cwd()).resolve()
    graph_path = canonical_existing_file(
        BOXED_GRAPH_JSON,
        root,
        "boxed implementation dependency graph",
    )
    canonical_existing_file(
        BOXED_GRAPH_MARKDOWN,
        root,
        "boxed implementation graph Markdown source",
    )
    try:
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(
            f"boxed implementation dependency graph is not valid JSON: {error}"
        ) from error

    errors = boxed_implementation_graph_errors(
        graph,
        extract_mvp_candidates(root),
        root,
    )
    syncable_error = "boxed implementation graph source hash does not match Markdown"
    blocking_errors = [error for error in errors if error != syncable_error]
    if blocking_errors:
        raise ValueError("\n".join(blocking_errors))

    expected_hash = content_sha256(BOXED_GRAPH_MARKDOWN, root)
    current_hash = graph["source"]["content_sha256_without_recency"]
    if current_hash == expected_hash:
        return False

    graph["source"]["content_sha256_without_recency"] = expected_hash
    atomic_replace_text(graph_path, registry_json(graph))
    return True


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

        if args.command == "sync-boxed-graph-source-hash":
            sync_boxed_graph_source_hash(args.repo_root)
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
