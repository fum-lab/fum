#!/usr/bin/env python3

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


TOOL_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEMPLATE_DOCUMENT = TOOL_ROOT / "references" / "heartbeat-prompt.md"
TEMPLATE_HEADING = "## Шаблон"
CLONE_ROOT_PLACEHOLDER = "<КОРЕНЬ_КЛОНА>"
RESIDUAL_PLACEHOLDER_RE = re.compile(
    r"<[^<>\r\n]*КОРЕНЬ_КЛОНА[^<>\r\n]*>"
)


class TemplateError(ValueError):
    pass


def extract_heartbeat_template(document: str) -> str:
    heading_matches = list(
        re.finditer(
            rf"^{re.escape(TEMPLATE_HEADING)}$",
            document,
            flags=re.MULTILINE,
        )
    )
    if len(heading_matches) != 1:
        raise TemplateError(
            "документ должен содержать ровно один точный раздел "
            f"{TEMPLATE_HEADING}"
        )

    section_start = heading_matches[0].end()
    next_section = re.search(r"^## .+$", document[section_start:], re.MULTILINE)
    section_end = (
        section_start + next_section.start()
        if next_section is not None
        else len(document)
    )
    section = document[section_start:section_end]

    opening_matches = list(re.finditer(r"^```text\n", section, re.MULTILINE))
    closing_matches = list(re.finditer(r"^```$", section, re.MULTILINE))
    if len(opening_matches) != 1 or len(closing_matches) != 1:
        raise TemplateError(
            "раздел шаблона должен содержать ровно один закрытый fenced-блок "
            "```text"
        )

    opening = opening_matches[0]
    closing = closing_matches[0]
    if closing.start() <= opening.end():
        raise TemplateError("закрывающий fence шаблона расположен неверно")
    if section[: opening.start()].strip() or section[closing.end() :].strip():
        raise TemplateError(
            "в разделе шаблона допустим только один fenced-блок без соседнего "
            "содержания"
        )

    template = section[opening.end() : closing.start()]
    if not template.endswith("\n"):
        raise TemplateError("fenced-шаблон должен завершаться переводом строки")
    template = template[:-1]
    if not template:
        raise TemplateError("fenced-шаблон не может быть пустым")
    return template


def normalize_repo_root(repo_root: str | os.PathLike[str]) -> str:
    try:
        normalized = Path(repo_root).expanduser().resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise TemplateError(
            f"не удалось нормализовать существующий корень проекта: {error}"
        ) from error
    if not normalized.is_dir():
        raise TemplateError("корень проекта должен быть существующим каталогом")
    normalized_text = str(normalized)
    if any(character in normalized_text for character in ("\x00", "\r", "\n")):
        raise TemplateError("корень проекта содержит запрещённый управляющий символ")

    git_environment = {
        key: value
        for key, value in os.environ.items()
        if not key.upper().startswith("GIT_")
    }
    git_environment["GIT_NO_REPLACE_OBJECTS"] = "1"
    git_environment["GIT_OPTIONAL_LOCKS"] = "0"
    try:
        result = subprocess.run(
            [
                "git",
                "--no-replace-objects",
                "--no-optional-locks",
                "-C",
                normalized_text,
                "rev-parse",
                "--show-toplevel",
            ],
            check=True,
            capture_output=True,
            text=True,
            env=git_environment,
            timeout=30,
        )
        git_root_lines = result.stdout.splitlines()
        if len(git_root_lines) != 1 or not git_root_lines[0]:
            raise TemplateError("Git вернул неоднозначный корень checkout")
        git_root = Path(git_root_lines[0]).resolve(strict=True)
    except (OSError, subprocess.SubprocessError) as error:
        raise TemplateError(
            f"не удалось доказать корень Git checkout: {error}"
        ) from error
    if git_root != normalized:
        raise TemplateError(
            "--repo-root должен точно совпадать с корнем Git checkout"
        )
    return normalized_text


def render_heartbeat_prompt(
    document: str,
    repo_root: str | os.PathLike[str],
) -> str:
    template = extract_heartbeat_template(document)
    if CLONE_ROOT_PLACEHOLDER not in template:
        raise TemplateError(
            f"fenced-шаблон не содержит обязательный placeholder "
            f"{CLONE_ROOT_PLACEHOLDER}"
        )

    rendered = template.replace(
        CLONE_ROOT_PLACEHOLDER,
        normalize_repo_root(repo_root),
    )
    residual = RESIDUAL_PLACEHOLDER_RE.search(rendered)
    if residual is not None:
        raise TemplateError(
            "после подстановки остался placeholder корня клона"
        )
    return rendered


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Извлечь полный heartbeat prompt и подставить нормализованный "
            "абсолютный корень проекта."
        )
    )
    parser.add_argument(
        "--repo-root",
        required=True,
        help="существующий каталог локального проекта",
    )
    parser.add_argument(
        "--template-document",
        default=str(DEFAULT_TEMPLATE_DOCUMENT),
        help="Markdown-документ с единственным разделом шаблона",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        document = Path(args.template_document).read_text(encoding="utf-8")
        rendered = render_heartbeat_prompt(document, args.repo_root)
    except (OSError, UnicodeError, TemplateError) as error:
        print(f"Ошибка renderer heartbeat: {error}", file=sys.stderr)
        return 2
    sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
