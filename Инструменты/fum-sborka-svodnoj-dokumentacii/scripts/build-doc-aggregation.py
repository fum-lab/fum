#!/usr/bin/env python3
"""Build and validate source-backed FUM aggregate documentation articles."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


PROJECT_FILES_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-proyektnyiye-fajlyi"
    / "scripts"
)
if str(PROJECT_FILES_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(PROJECT_FILES_SCRIPTS))

from project_files import (  # noqa: E402
    ProjectFilesError,
    normalized_project_relative_path,
    safe_project_output_path,
)


TODO_MARKER = "DOC_AGGREGATION_TODO"
REQUIRED_HEADINGS = [
    "Паспорт сводной статьи",
    "Назначение",
    "Карта источников",
    "Как поддерживать статью",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    build = subparsers.add_parser("build", help="Build an aggregate article scaffold")
    build.add_argument("--config", required=True, type=Path)
    build.add_argument("--output", required=True, type=Path)
    build.add_argument("--repo-root", type=Path, default=Path.cwd())

    validate = subparsers.add_parser("validate", help="Validate an aggregate article")
    validate.add_argument("--config", required=True, type=Path)
    validate.add_argument("--document", required=True, type=Path)
    validate.add_argument("--repo-root", type=Path, default=Path.cwd())
    validate.add_argument(
        "--complete",
        action="store_true",
        help="Fail if the document still contains draft TODO markers.",
    )
    return parser.parse_args()


def absolute_path(path: str | Path, repo_root: Path) -> Path:
    value = Path(path)
    if value.is_absolute():
        return value.resolve()
    return (repo_root / value).resolve()


def relative_link(
    target: object,
    document_path: Path,
    repo_root: Path,
    *,
    field_name: str = "path",
) -> str:
    relative_target = normalized_project_relative_path(
        target,
        repo_root,
        field_name=field_name,
        must_exist=False,
    )
    absolute_target = repo_root.resolve() / relative_target
    return Path(os.path.relpath(absolute_target, document_path.parent)).as_posix()


def trim_trailing_whitespace(text: str) -> str:
    lines = [line.rstrip() for line in text.splitlines()]
    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines) + "\n"


def strip_markdown_links(text: str) -> str:
    return re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)


def first_heading(path: Path) -> str | None:
    if not path.exists():
        return None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("# "):
            return strip_markdown_links(line[2:].strip())
    return None


def request_label(request_file: str) -> str:
    stem = Path(request_file).stem
    match = re.fullmatch(
        r"(\d{4}-\d{2}-\d{2})_(\d{2})-(\d{2})-(\d{2})_([A-Z]+)",
        stem,
    )
    if not match:
        return request_file
    date, hour, minute, second, zone = match.groups()
    return f"исходный запрос {date} {hour}:{minute}:{second} {zone}"


def load_config(config_path: Path) -> dict[str, Any]:
    return json.loads(config_path.read_text(encoding="utf-8"))


def source_title(source: dict[str, Any], repo_root: Path) -> str:
    configured = source.get("title")
    if isinstance(configured, str) and configured.strip():
        return configured.strip()
    relative = normalized_project_relative_path(
        source["path"],
        repo_root,
        field_name="source_documents[].path",
        must_exist=True,
    )
    path = repo_root.resolve() / relative
    return first_heading(path) or Path(source["path"]).stem


def validate_config(config: dict[str, Any], repo_root: Path) -> list[str]:
    errors: list[str] = []
    for field in ["title", "topic", "purpose", "request_file", "source_documents"]:
        if field not in config:
            errors.append(f"missing config field: {field}")

    sources = config.get("source_documents", [])
    if not isinstance(sources, list) or len(sources) < 2:
        errors.append("source_documents must contain at least two source documents")
    else:
        for index, source in enumerate(sources, start=1):
            if not isinstance(source, dict) or not source.get("path"):
                errors.append(f"source_documents[{index}] is missing path")
                continue
            try:
                normalized_project_relative_path(
                    source["path"],
                    repo_root,
                    field_name=f"source_documents[{index}].path",
                    must_exist=True,
                )
            except ProjectFilesError as error:
                errors.append(str(error))

    request = config.get("request_file")
    try:
        normalized_project_relative_path(
            request,
            repo_root,
            field_name="request_file",
            must_exist=True,
        )
    except ProjectFilesError as error:
        errors.append(str(error))

    automation = config.get(
        "automation_file",
        "Инструменты/fum-sborka-svodnoj-dokumentacii/SKILL.md",
    )
    try:
        normalized_project_relative_path(
            automation,
            repo_root,
            field_name="automation_file",
            must_exist=True,
        )
    except ProjectFilesError as error:
        errors.append(str(error))
    return errors


def render_document(config: dict[str, Any], output_path: Path, repo_root: Path) -> str:
    title = config["title"].strip()
    topic = config["topic"].strip()
    purpose = config["purpose"].strip()
    request_file = config["request_file"]
    automation_file = config.get(
        "automation_file",
        "Инструменты/fum-sborka-svodnoj-dokumentacii/SKILL.md",
    )

    lines: list[str] = [
        f"# {title}",
        "",
        "Источники требований:",
        "",
        f"- [{request_label(request_file)}]({relative_link(request_file, output_path, repo_root, field_name='request_file')})",
        "",
        "Опорные документы:",
        "",
    ]

    for source in config["source_documents"]:
        role = source.get("role", "опорный источник")
        link = relative_link(
            source["path"],
            output_path,
            repo_root,
            field_name="source_documents[].path",
        )
        lines.append(f"- [{source_title(source, repo_root)}]({link}) - {role}")

    lines.extend(
        [
            "",
            "## Паспорт сводной статьи",
            "",
            f"- Общая тема: {topic}",
            f"- Назначение: {purpose}",
            f"- Автоматизация: [fum-sborka-svodnoj-dokumentacii]({relative_link(automation_file, output_path, repo_root, field_name='automation_file')})",
            "- Статус: чёрновой каркас для смысловой сборки агентом.",
            "- Принцип: сводная статья не заменяет опорные документы; она показывает общий слой и оставляет детальные требования в исходных материалах.",
            "",
            "## Назначение",
            "",
            f"{TODO_MARKER}: сформулировать сводный тезис по источникам.",
            "",
            "## Карта источников",
            "",
            "| Источник | Роль в сводной статье |",
            "| --- | --- |",
        ]
    )

    for source in config["source_documents"]:
        role = source.get("role", "опорный источник")
        link = relative_link(
            source["path"],
            output_path,
            repo_root,
            field_name="source_documents[].path",
        )
        lines.append(f"| [{source_title(source, repo_root)}]({link}) | {role} |")

    sections = config.get("sections", [])
    for section in sections:
        section_title = section["title"].strip()
        focus = section.get("focus", "").strip()
        lines.extend(["", f"## {section_title}", ""])
        if focus:
            lines.append(f"Фокус раздела: {focus}")
            lines.append("")
        lines.append(f"{TODO_MARKER}: собрать раздел из опорных документов.")

    lines.extend(
        [
            "",
            "## Как поддерживать статью",
            "",
            "При изменении опорных документов нужно проверить, остаётся ли сводная статья актуальной: добавить новые источники в конфигурацию, пересобрать каркас, перенести смысловые правки в полный текст и запустить валидацию. Если меняется только деталь одного слоя, правится детальный документ; если меняется общая карта темы, обновляется эта сводная статья.",
        ]
    )

    return trim_trailing_whitespace("\n".join(lines))


def build_document(
    config_path: Path,
    output_path: Path,
    repo_root: Path | None = None,
) -> str:
    root = (repo_root or Path.cwd()).resolve()
    output = safe_project_output_path(output_path, root)
    config = load_config(config_path)
    errors = validate_config(config, root)
    if errors:
        raise ValueError("\n".join(errors))

    document = render_document(config, output, root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(document, encoding="utf-8")
    return document


def configured_headings(config: dict[str, Any]) -> list[str]:
    headings = list(REQUIRED_HEADINGS)
    for section in config.get("sections", []):
        title = section.get("title")
        if isinstance(title, str) and title.strip():
            headings.append(title.strip())
    return headings


def validate_document(
    config_path: Path,
    document_path: Path,
    repo_root: Path | None = None,
    require_complete: bool = False,
) -> list[str]:
    root = (repo_root or Path.cwd()).resolve()
    document = absolute_path(document_path, root)
    config = load_config(config_path)
    errors = validate_config(config, root)
    if errors:
        return errors

    if not document.exists():
        return [f"document does not exist: {document_path}"]

    text = document.read_text(encoding="utf-8")
    title = config["title"].strip()
    if not text.startswith(f"# {title}\n"):
        errors.append(f"missing title heading: {title}")

    request = config["request_file"]
    request_link = relative_link(request, document, root)
    if request_link not in text:
        errors.append(f"missing request link: {request}")

    for source in config["source_documents"]:
        link = relative_link(source["path"], document, root)
        if link not in text:
            errors.append(f"missing source link: {source['path']}")

    for heading in configured_headings(config):
        if f"\n## {heading}\n" not in text:
            errors.append(f"missing heading: {heading}")

    if "не заменяет опорные документы" not in text:
        errors.append("missing non-replacement principle")

    if require_complete and TODO_MARKER in text:
        errors.append(f"document still contains {TODO_MARKER} markers")

    return errors


def main() -> int:
    args = parse_args()
    try:
        if args.command == "build":
            build_document(args.config, args.output, args.repo_root)
            return 0

        errors = validate_document(
            args.config,
            args.document,
            args.repo_root,
            require_complete=args.complete,
        )
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
