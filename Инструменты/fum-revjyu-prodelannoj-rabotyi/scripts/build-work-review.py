#!/usr/bin/env python3
"""Build and validate saved FUM work-review reports."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
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


TODO_MARKER = "WORK_REVIEW_TODO"
REQUIRED_CONFIG_FIELDS = [
    "title",
    "request_file",
    "automation_file",
    "base_ref",
    "head_ref",
    "reviewed_at",
    "reviewer",
    "scope",
    "review_focus",
    "findings",
    "checks",
    "residual_risks",
    "decision",
]
REQUIRED_SECTIONS = [
    "Граница ревью",
    "Снимок Git",
    "Что проверялось",
    "Находки",
    "Проверки",
    "Остаточные риски",
    "Сохранение результата",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    build = subparsers.add_parser("build", help="Build a work-review Markdown report")
    build.add_argument("--config", required=True, type=Path)
    build.add_argument("--output", required=True, type=Path)
    build.add_argument("--repo-root", type=Path, default=Path.cwd())

    validate = subparsers.add_parser("validate", help="Validate a work-review report")
    validate.add_argument("--config", required=True, type=Path)
    validate.add_argument("--document", required=True, type=Path)
    validate.add_argument("--repo-root", type=Path, default=Path.cwd())
    validate.add_argument(
        "--complete",
        action="store_true",
        help=f"Fail if the document still contains {TODO_MARKER}.",
    )
    return parser.parse_args()


def absolute_path(path: str | Path, repo_root: Path) -> Path:
    value = Path(path)
    if value.is_absolute():
        return value.resolve()
    return (repo_root / value).resolve()


def repo_relative(path: str | Path, repo_root: Path) -> str:
    return absolute_path(path, repo_root).relative_to(repo_root.resolve()).as_posix()


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


def markdown_escape(value: Any) -> str:
    return str(value).strip().replace("|", "\\|")


def load_config(config_path: Path) -> dict[str, Any]:
    return json.loads(config_path.read_text(encoding="utf-8"))


def validate_config(config: dict[str, Any], repo_root: Path) -> list[str]:
    errors: list[str] = []
    for field in REQUIRED_CONFIG_FIELDS:
        if field not in config:
            errors.append(f"missing config field: {field}")

    for field in ["review_focus", "findings", "checks", "residual_risks"]:
        value = config.get(field)
        if field in config and not isinstance(value, list):
            errors.append(f"{field} must be a list")

    for field in ["review_focus", "checks", "residual_risks"]:
        value = config.get(field)
        if isinstance(value, list) and not value:
            errors.append(f"{field} must be non-empty")

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

    automation = config.get("automation_file")
    try:
        normalized_project_relative_path(
            automation,
            repo_root,
            field_name="automation_file",
            must_exist=True,
        )
    except ProjectFilesError as error:
        errors.append(str(error))

    config_file = config.get("config_file")
    if config_file is not None:
        try:
            normalized_project_relative_path(
                config_file,
                repo_root,
                field_name="config_file",
                must_exist=True,
            )
        except ProjectFilesError as error:
            errors.append(str(error))

    for index, finding in enumerate(config.get("findings", []), start=1):
        if not isinstance(finding, dict):
            errors.append(f"finding {index} must be an object")
            continue
        for field in ["priority", "status", "title", "details", "recommendation"]:
            if field not in finding:
                errors.append(f"finding {index} missing field: {field}")
        finding_file = finding.get("file")
        if finding_file not in {None, ""}:
            try:
                normalized_project_relative_path(
                    finding_file,
                    repo_root,
                    field_name=f"findings[{index}].file",
                    must_exist=False,
                )
            except ProjectFilesError as error:
                errors.append(str(error))

    for index, check in enumerate(config.get("checks", []), start=1):
        if not isinstance(check, dict):
            errors.append(f"check {index} must be an object")
            continue
        for field in ["name", "command", "result"]:
            if field not in check:
                errors.append(f"check {index} missing field: {field}")

    return errors


def run_git(repo_root: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo_root), "-c", "core.quotepath=false", *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def run_git_text(repo_root: Path, args: list[str]) -> str:
    result = run_git(repo_root, args)
    if result.returncode != 0:
        details = result.stderr.strip() or result.stdout.strip() or "unknown git error"
        raise RuntimeError(f"git {' '.join(args)} failed: {details}")
    return result.stdout.strip()


def collect_git_snapshot(config: dict[str, Any], repo_root: Path) -> dict[str, Any]:
    base = str(config["base_ref"])
    head = str(config["head_ref"])
    revision_range = f"{base}..{head}"
    diff_check = run_git(repo_root, ["diff", "--check", revision_range])
    diff_check_output = (diff_check.stdout + diff_check.stderr).strip()

    return {
        "base_ref": base,
        "head_ref": head,
        "revision_range": revision_range,
        "commits": run_git_text(
            repo_root,
            ["log", "--reverse", "--oneline", revision_range],
        ).splitlines(),
        "changed_files": run_git_text(
            repo_root,
            ["diff", "--name-status", revision_range],
        ).splitlines(),
        "stat": run_git_text(repo_root, ["diff", "--stat", revision_range]),
        "diff_check_passed": diff_check.returncode == 0,
        "diff_check_output": diff_check_output,
        "working_tree_status": run_git_text(
            repo_root,
            ["status", "--short", "--untracked-files=all"],
        ),
    }


def status_label(code: str) -> str:
    labels = {
        "A": "добавлен",
        "M": "изменён",
        "D": "удалён",
        "R": "переименован",
        "C": "скопирован",
    }
    return labels.get(code[:1], code)


def changed_file_rows(lines: list[str]) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line in lines:
        parts = line.split("\t")
        if not parts:
            continue
        status = status_label(parts[0])
        if len(parts) == 1:
            path = ""
        elif len(parts) == 2:
            path = parts[1]
        else:
            path = f"{parts[-2]} -> {parts[-1]}"
        rows.append((status, path))
    return rows


def render_list(items: list[Any]) -> str:
    return "\n".join(f"- {item}" for item in items)


def render_commits(commits: list[str]) -> str:
    if not commits:
        return "- Нет коммитов в выбранном диапазоне."
    rows: list[str] = []
    for line in commits:
        if " " in line:
            commit_hash, subject = line.split(" ", 1)
            rows.append(f"- `{commit_hash}` {subject}")
        else:
            rows.append(f"- `{line}`")
    return "\n".join(rows)


def render_changed_files(lines: list[str]) -> str:
    rows = changed_file_rows(lines)
    if not rows:
        return "Изменённые файлы в выбранном диапазоне не найдены."
    table = ["| Статус | Путь |", "| --- | --- |"]
    for status, path in rows:
        table.append(f"| {markdown_escape(status)} | `{markdown_escape(path)}` |")
    return "\n".join(table)


def render_findings(findings: list[dict[str, Any]], decision: str) -> str:
    if not findings:
        return f"{decision}\n"

    lines = [
        "| Приоритет | Статус | Файл | Строка | Заголовок |",
        "| --- | --- | --- | --- | --- |",
    ]
    for finding in findings:
        path = finding.get("file", "")
        line = finding.get("line", "")
        lines.append(
            "| "
            f"{markdown_escape(finding.get('priority', ''))} | "
            f"{markdown_escape(finding.get('status', ''))} | "
            f"`{markdown_escape(path)}` | "
            f"{markdown_escape(line)} | "
            f"{markdown_escape(finding.get('title', ''))} |"
        )

    for finding in findings:
        priority = finding.get("priority", "")
        title = finding.get("title", "")
        lines.extend(
            [
                "",
                f"### {priority}: {title}".strip(),
                "",
                str(finding.get("details", "")).strip(),
                "",
                f"Рекомендация: {finding.get('recommendation', '')}".strip(),
            ]
        )
    return "\n".join(lines)


def render_checks(checks: list[dict[str, Any]]) -> str:
    lines = ["| Проверка | Команда | Результат | Детали |", "| --- | --- | --- | --- |"]
    for check in checks:
        details = check.get("details", "")
        lines.append(
            "| "
            f"{markdown_escape(check.get('name', ''))} | "
            f"`{markdown_escape(check.get('command', ''))}` | "
            f"{markdown_escape(check.get('result', ''))} | "
            f"{markdown_escape(details)} |"
        )
    return "\n".join(lines)


def render_review(
    config: dict[str, Any],
    output_path: Path,
    repo_root: Path,
    snapshot: dict[str, Any],
) -> str:
    request_link = relative_link(
        config["request_file"],
        output_path,
        repo_root,
        field_name="request_file",
    )
    automation_link = relative_link(
        config["automation_file"],
        output_path,
        repo_root,
        field_name="automation_file",
    )
    config_path = config.get("config_file")
    config_line = ""
    if isinstance(config_path, str):
        config_line = f"- Конфигурация: [{config_path}]({relative_link(config_path, output_path, repo_root, field_name='config_file')})\n"

    diff_check = "прошёл" if snapshot["diff_check_passed"] else "нашёл замечания"
    diff_check_details = snapshot["diff_check_output"] or "Проблем whitespace не обнаружено."
    status = snapshot["working_tree_status"] or "рабочее дерево чистое"
    if "\n" in status:
        status_block = f"```text\n{status}\n```"
    else:
        status_block = f"`{status}`"

    return trim_trailing_whitespace(
        f"""# {config["title"]}

{config["decision"]}

## Граница ревью

- Исходный запрос: [{config["request_file"]}]({request_link})
- Автоматизация: [{config["automation_file"]}]({automation_link})
{config_line}- Ревьюер: {config["reviewer"]}
- Время ревью: {config["reviewed_at"]}
- База: `{snapshot["base_ref"]}`
- Голова: `{snapshot["head_ref"]}`
- Диапазон Git: `{snapshot["revision_range"]}`
- Область: {config["scope"]}

## Снимок Git

Коммиты в диапазоне:

{render_commits(snapshot["commits"])}

Изменённые файлы:

{render_changed_files(snapshot["changed_files"])}

Статистика diff:

```text
{snapshot["stat"]}
```

Автоматический сигнал `git diff --check`: {diff_check}. {diff_check_details}

Текущее состояние рабочего дерева при сборке отчёта:

{status_block}

## Что проверялось

{render_list(config["review_focus"])}

## Находки

{render_findings(config["findings"], config["decision"])}

## Проверки

{render_checks(config["checks"])}

## Остаточные риски

{render_list(config["residual_risks"])}

## Сохранение результата

Отчёт построен локальной автоматизацией `fum-revjyu-prodelannoj-rabotyi` из сохранённой конфигурации, текущего Git-среза и смыслового ревью агента. Скрипт автоматизирует сбор наблюдаемого контекста, структуру отчёта и проверку обязательных разделов, но не подменяет содержательную ответственность ревьюера за выводы.
"""
    )


def build_review_document(config_path: Path, output_path: Path, repo_root: Path) -> None:
    root = repo_root.resolve()
    config = load_config(config_path)
    errors = validate_config(config, root)
    if errors:
        raise ValueError("\n".join(errors))

    snapshot = collect_git_snapshot(config, root)
    config_for_render = dict(config)
    config_for_render.setdefault("config_file", repo_relative(config_path, root))
    output = safe_project_output_path(output_path, root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_review(config_for_render, output, root, snapshot), encoding="utf-8")


def heading_exists(text: str, heading: str) -> bool:
    return re.search(rf"^## {re.escape(heading)}\s*$", text, re.MULTILINE) is not None


def validate_review_document(
    config_path: Path,
    document_path: Path,
    repo_root: Path,
    complete: bool = False,
) -> list[str]:
    root = repo_root.resolve()
    config = load_config(config_path)
    errors = validate_config(config, root)
    if errors:
        return errors

    document = absolute_path(document_path, root)
    if not document.exists():
        return errors + [f"review document does not exist: {document_path}"]

    text = document.read_text(encoding="utf-8")
    expected_heading = f"# {config.get('title', '')}"
    if not text.startswith(expected_heading + "\n"):
        errors.append(f"review must start with heading: {expected_heading}")

    for section in REQUIRED_SECTIONS:
        if not heading_exists(text, section):
            errors.append(f"missing section: {section}")

    for field in ["request_file", "automation_file", "base_ref", "head_ref", "decision"]:
        value = config.get(field)
        if isinstance(value, str) and value not in text:
            errors.append(f"review document does not mention config field {field}: {value}")

    request_link = relative_link(
        config["request_file"],
        document,
        root,
        field_name="request_file",
    )
    automation_link = relative_link(
        config["automation_file"],
        document,
        root,
        field_name="automation_file",
    )
    for link in [request_link, automation_link]:
        if link not in text:
            errors.append(f"review document is missing local link: {link}")

    if not config.get("findings") and "Существенных замечаний не выявлено." not in text:
        errors.append("review without findings must state: Существенных замечаний не выявлено.")

    for index, finding in enumerate(config.get("findings", []), start=1):
        title = finding.get("title")
        priority = finding.get("priority")
        if title and title not in text:
            errors.append(f"review document does not mention finding {index}: {title}")
        if priority and priority not in text:
            errors.append(f"review document does not mention finding priority {index}: {priority}")

    for index, check in enumerate(config.get("checks", []), start=1):
        command = check.get("command")
        if command and command not in text:
            errors.append(f"review document does not mention check command {index}: {command}")

    if complete and TODO_MARKER in text:
        errors.append(f"review document contains draft marker: {TODO_MARKER}")

    return errors


def main() -> int:
    args = parse_args()
    root = args.repo_root.resolve()
    try:
        if args.command == "build":
            build_review_document(args.config, args.output, root)
            print(f"work review written: {repo_relative(args.output, root)}")
            return 0

        if args.command == "validate":
            errors = validate_review_document(
                args.config,
                args.document,
                root,
                complete=args.complete,
            )
            if errors:
                for error in errors:
                    print(error, file=sys.stderr)
                return 1
            print("work review validation passed")
            return 0
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    print(f"unknown command: {args.command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
