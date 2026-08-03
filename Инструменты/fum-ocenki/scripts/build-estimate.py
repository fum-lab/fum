#!/usr/bin/env python3
"""Build and validate repository-backed FUM estimate documents."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo


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

REQUEST_LAYOUT_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-struktura-papok-zaprosov"
    / "scripts"
)
if str(REQUEST_LAYOUT_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(REQUEST_LAYOUT_SCRIPTS))

from request_folder_layout import session_stem_for_request_path  # noqa: E402


TODO_MARKER = "ESTIMATE_TODO"
MSK = ZoneInfo("Europe/Moscow")
REQUIRED_HEADINGS = [
    "Снимок репозитория",
    "Методика расчёта",
    "Диапазоны",
    "Допущения",
    "Ограничения точности",
    "Оформление результата",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    snapshot = subparsers.add_parser("snapshot", help="Collect a repository snapshot")
    snapshot.add_argument("--repo-root", type=Path, default=Path.cwd())
    snapshot.add_argument("--output", type=Path)

    build = subparsers.add_parser("build", help="Build an estimate document")
    build.add_argument("--config", required=True, type=Path)
    build.add_argument("--output", required=True, type=Path)
    build.add_argument("--repo-root", type=Path, default=Path.cwd())
    build.add_argument(
        "--refresh-snapshot",
        action="store_true",
        help="Use a fresh repository snapshot instead of the one stored in config.",
    )

    validate = subparsers.add_parser("validate", help="Validate an estimate document")
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
    stem = session_stem_for_request_path(request_file)
    if stem is None:
        return request_file
    date, time, zone = stem[:23].split("_")
    return f"исходный запрос {date} {time.replace('-', ':')} {zone}"


def load_config(config_path: Path) -> dict[str, Any]:
    return json.loads(config_path.read_text(encoding="utf-8"))


def format_value(value: Any) -> str:
    return str(value).strip()


def markdown_escape_table(value: Any) -> str:
    return format_value(value).replace("|", "\\|")


def run_git(repo_root: Path, args: list[str]) -> str | None:
    result = subprocess.run(
        ["git", "-C", str(repo_root), "-c", "core.quotepath=false", *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def tracked_files(repo_root: Path) -> list[Path]:
    output = run_git(repo_root, ["ls-files"])
    if output is None:
        return []
    return [repo_root / line for line in output.splitlines() if line.strip()]


def file_line_count(path: Path) -> int:
    data = path.read_bytes()
    if not data:
        return 0
    return data.count(b"\n") + (0 if data.endswith(b"\n") else 1)


def markdown_word_count(path: Path) -> int:
    text = path.read_text(encoding="utf-8", errors="ignore")
    return len(re.findall(r"[0-9A-Za-zА-Яа-яЁё]+(?:[-'][0-9A-Za-zА-Яа-яЁё]+)*", text))


def collect_repository_snapshot(repo_root: Path) -> dict[str, Any]:
    now = datetime.now(timezone.utc).astimezone(MSK)
    files = [path for path in tracked_files(repo_root) if path.exists()]
    markdown_files = [path for path in files if path.suffix.lower() == ".md"]
    line_count = sum(file_line_count(path) for path in files if path.is_file())
    word_count = sum(markdown_word_count(path) for path in markdown_files)

    first_date = run_git(repo_root, ["log", "--reverse", "--format=%cs", "-n", "1"])
    last_date = run_git(repo_root, ["log", "--format=%cs", "-n", "1"])
    commit_count = run_git(repo_root, ["rev-list", "--count", "HEAD"])
    commit = run_git(repo_root, ["rev-parse", "--short", "HEAD"])
    branch = run_git(repo_root, ["rev-parse", "--abbrev-ref", "HEAD"])
    status = run_git(repo_root, ["status", "--short", "--untracked-files=all"])
    dirty = "чистый" if status == "" else f"есть незакоммиченные изменения: {len(status.splitlines())}"

    metrics = [
        {"name": "Дата снимка", "value": now.strftime("%Y-%m-%d")},
        {"name": "Git-коммит", "value": commit or "недоступно"},
        {"name": "Ветка Git", "value": branch or "недоступно"},
        {"name": "Состояние рабочего дерева", "value": dirty},
        {
            "name": "Период Git-истории",
            "value": f"{first_date or 'недоступно'} - {last_date or 'недоступно'}",
        },
        {"name": "Количество коммитов", "value": commit_count or "недоступно"},
        {"name": "Отслеживаемые файлы", "value": str(len(files))},
        {"name": "Markdown-файлы", "value": str(len(markdown_files))},
        {"name": "Общий объём строк в отслеживаемых файлах", "value": str(line_count)},
        {"name": "Общий объём слов в Markdown-файлах", "value": str(word_count)},
    ]
    return {
        "date": now.strftime("%Y-%m-%d"),
        "generated_at": now.strftime("%Y-%m-%d %H:%M:%S MSK"),
        "metrics": metrics,
        "notes": [
            "Снимок собран локальной автоматизацией fum-ocenki по отслеживаемым Git-файлам.",
            "Незакоммиченные изменения учитываются как состояние рабочего дерева, но не входят в статистику tracked-файлов до добавления в Git.",
        ],
    }


def validate_config(config: dict[str, Any], repo_root: Path) -> list[str]:
    errors: list[str] = []
    required_fields = [
        "title",
        "request_file",
        "question",
        "unit",
        "point_estimate",
        "range",
        "summary",
        "scope",
        "methodology",
        "breakdown",
        "assumptions",
        "precision_limits",
        "result_format",
    ]
    for field in required_fields:
        if field not in config:
            errors.append(f"missing config field: {field}")

    estimate_range = config.get("range", {})
    if not isinstance(estimate_range, dict):
        errors.append("range must be an object with low and high")
    else:
        for field in ["low", "high"]:
            if field not in estimate_range:
                errors.append(f"missing range field: {field}")

    for field in [
        "methodology",
        "breakdown",
        "assumptions",
        "precision_limits",
        "result_format",
    ]:
        value = config.get(field)
        if field in config and (not isinstance(value, list) or not value):
            errors.append(f"{field} must be a non-empty list")

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
    if not isinstance(request, str) or session_stem_for_request_path(request) is None:
        errors.append(
            "request_file must match "
            "Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_название]>/запрос.md"
        )

    automation = config.get("automation_file", "Инструменты/fum-ocenki/SKILL.md")
    try:
        normalized_project_relative_path(
            automation,
            repo_root,
            field_name="automation_file",
            must_exist=True,
        )
    except ProjectFilesError as error:
        errors.append(str(error))

    snapshot = config.get("snapshot")
    if snapshot is not None:
        if not isinstance(snapshot, dict):
            errors.append("snapshot must be an object")
        elif not isinstance(snapshot.get("metrics"), list) or not snapshot.get("metrics"):
            errors.append("snapshot.metrics must be a non-empty list")

    return errors


def range_text(config: dict[str, Any]) -> str:
    estimate_range = config["range"]
    return (
        f"{format_value(estimate_range['low'])}-"
        f"{format_value(estimate_range['high'])} {format_value(config['unit'])}"
    )


def point_text(config: dict[str, Any]) -> str:
    return f"{format_value(config['point_estimate'])} {format_value(config['unit'])}"


def snapshot_for_render(
    config: dict[str, Any],
    repo_root: Path,
    refresh_snapshot: bool,
) -> dict[str, Any]:
    if refresh_snapshot or "snapshot" not in config:
        return collect_repository_snapshot(repo_root)
    return config["snapshot"]


def render_document(
    config: dict[str, Any],
    output_path: Path,
    repo_root: Path,
    refresh_snapshot: bool = False,
) -> str:
    title = config["title"].strip()
    snapshot = snapshot_for_render(config, repo_root, refresh_snapshot)
    automation_file = config.get("automation_file", "Инструменты/fum-ocenki/SKILL.md")

    lines: list[str] = [
        f"# {title}",
        "",
        config["summary"].strip(),
        "",
        config["scope"].strip(),
        "",
        "## Снимок репозитория",
        "",
        f"Оценка опирается на снимок репозитория от {snapshot.get('date', 'не указано')}.",
        "",
        "| Показатель | Значение |",
        "| --- | --- |",
    ]

    for metric in snapshot.get("metrics", []):
        if isinstance(metric, dict):
            lines.append(
                f"| {markdown_escape_table(metric.get('name', 'Показатель'))} | "
                f"{markdown_escape_table(metric.get('value', 'не указано'))} |"
            )

    notes = snapshot.get("notes", [])
    if notes:
        lines.extend(["", "Примечания к снимку:"])
        for note in notes:
            lines.append(f"- {format_value(note)}")

    lines.extend(["", "## Методика расчёта", "", f"Вопрос оценки: {config['question'].strip()}", ""])
    for method in config["methodology"]:
        name = format_value(method.get("name", "Шаг методики"))
        description = format_value(method.get("description", TODO_MARKER))
        lines.append(f"- {name} - {description}")

    lines.extend(
        [
            "",
            "## Диапазоны",
            "",
            "| Компонент | Нижняя граница | Верхняя граница | Комментарий |",
            "| --- | ---: | ---: | --- |",
        ]
    )
    for item in config["breakdown"]:
        lines.append(
            f"| {markdown_escape_table(item.get('name', 'Компонент'))} | "
            f"{markdown_escape_table(item.get('low', ''))} | "
            f"{markdown_escape_table(item.get('high', ''))} | "
            f"{markdown_escape_table(item.get('comment', ''))} |"
        )

    lines.extend(
        [
            "",
            f"Итоговый рабочий диапазон: **{range_text(config)}**.",
            f"Точечная оценка: **{point_text(config)}**.",
            "",
            "## Допущения",
            "",
        ]
    )
    for assumption in config["assumptions"]:
        lines.append(f"- {format_value(assumption)}")

    lines.extend(["", "## Ограничения точности", ""])
    for limit in config["precision_limits"]:
        lines.append(f"- {format_value(limit)}")

    lines.extend(["", "## Оформление результата", ""])
    for rule in config["result_format"]:
        lines.append(f"- {format_value(rule)}")

    interpretation = config.get("interpretation", [])
    if interpretation:
        lines.extend(["", "## Итоговая интерпретация", ""])
        for index, paragraph in enumerate(interpretation):
            lines.append(format_value(paragraph))
            if index + 1 < len(interpretation):
                lines.append("")

    lines.extend(
        [
            "",
            "## Источники требований",
            "",
            f"- [{request_label(config['request_file'])}]({relative_link(config['request_file'], output_path, repo_root, field_name='request_file')})",
            f"- [fum-ocenki]({relative_link(automation_file, output_path, repo_root, field_name='automation_file')}) - локальная автоматизация сборки и проверки оценочных материалов.",
        ]
    )

    return trim_trailing_whitespace("\n".join(lines))


def build_document(
    config_path: Path,
    output_path: Path,
    repo_root: Path | None = None,
    refresh_snapshot: bool = False,
) -> str:
    root = (repo_root or Path.cwd()).resolve()
    output = safe_project_output_path(output_path, root)
    config = load_config(config_path)
    errors = validate_config(config, root)
    if errors:
        raise ValueError("\n".join(errors))

    document = render_document(config, output, root, refresh_snapshot=refresh_snapshot)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(document, encoding="utf-8")
    return document


def configured_strings(config: dict[str, Any]) -> list[str]:
    values = [point_text(config), range_text(config)]
    values.extend(format_value(item) for item in config["assumptions"])
    values.extend(format_value(item) for item in config["precision_limits"])
    values.extend(format_value(item) for item in config["result_format"])

    for method in config["methodology"]:
        values.append(format_value(method.get("name", "")))
    for item in config["breakdown"]:
        values.append(format_value(item.get("name", "")))

    snapshot = config.get("snapshot")
    if isinstance(snapshot, dict):
        for metric in snapshot.get("metrics", []):
            if isinstance(metric, dict):
                values.append(format_value(metric.get("name", "")))
                values.append(format_value(metric.get("value", "")))
    return [value for value in values if value]


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

    for heading in REQUIRED_HEADINGS:
        if f"\n## {heading}\n" not in text:
            errors.append(f"missing heading: {heading}")

    request_link = relative_link(config["request_file"], document, root)
    if request_link not in text:
        errors.append(f"missing request link: {config['request_file']}")

    automation_file = config.get("automation_file")
    if isinstance(automation_file, str):
        automation_link = relative_link(automation_file, document, root)
        if automation_link not in text:
            errors.append(f"missing automation link: {automation_file}")

    final_range = range_text(config)
    if final_range not in text:
        errors.append(f"missing final range: {final_range}")

    for value in configured_strings(config):
        if value not in text:
            errors.append(f"missing configured value: {value}")

    if require_complete and TODO_MARKER in text:
        errors.append(f"document still contains {TODO_MARKER} markers")

    return errors


def write_snapshot(snapshot: dict[str, Any], output: Path | None) -> None:
    text = json.dumps(snapshot, ensure_ascii=False, indent=2) + "\n"
    if output is None:
        print(text, end="")
        return
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text, encoding="utf-8")


def main() -> int:
    args = parse_args()
    try:
        if args.command == "snapshot":
            write_snapshot(
                collect_repository_snapshot(args.repo_root.resolve()),
                args.output,
            )
            return 0

        if args.command == "build":
            build_document(
                args.config,
                args.output,
                args.repo_root,
                refresh_snapshot=args.refresh_snapshot,
            )
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
