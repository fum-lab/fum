#!/usr/bin/env python3
"""List literal request questions with request-level answer-card coverage."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote


REQUEST_LAYOUT_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-struktura-papok-zaprosov"
    / "scripts"
)
if str(REQUEST_LAYOUT_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(REQUEST_LAYOUT_SCRIPTS))

from request_folder_layout import (  # noqa: E402
    is_valid_session_stem,
    session_stem_for_request_path,
)


JOURNAL_DIRECTORY = Path("Журнал")
REQUEST_FILE_NAME = "запрос.md"
ANSWER_CARDS_DIRECTORY = Path("Вопросы и ответы")
REQUEST_TEXT_SECTION = "Текст запроса"
SOURCES_SECTION = "Источники требований"
REPORT_SCHEMA = "fum.question-answer-coverage-audit.v1"
MANUAL_CHECKS = (
    "directly_about_fum",
    "substantive_answer",
    "standalone_usefulness",
)

H2_RE = re.compile(r"^##[ \t]+(.+?)[ \t]*$")
HEADING_RE = re.compile(r"^[ \t]{0,3}#{1,6}[ \t]+")
FENCE_RE = re.compile(r"^[ \t]{0,3}(`{3,}|~{3,})(.*)$")
BLOCKQUOTE_RE = re.compile(r"^[ \t]{0,3}>[ \t]?(.*)$")
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[([^\]\n]+)\]\(([^)\n]+)\)")
BARE_URL_RE = re.compile(r"(?i)\b(?:https?://|www\.)\S+")
QUESTION_CLOSERS = frozenset("\"'»”’)]}")


@dataclass(frozen=True)
class MarkdownSection:
    title: str
    lines: tuple[str, ...]
    start_line: int


@dataclass(frozen=True)
class LiteralBlock:
    text: str
    start_line: int


@dataclass(frozen=True)
class ExtractedQuestion:
    text: str
    line: int


@dataclass(frozen=True)
class QuestionFinding:
    request_path: str
    line: int
    question: str
    coverage: str
    answer_cards: tuple[str, ...]

    def as_dict(self) -> dict[str, object]:
        return {
            "request_path": self.request_path,
            "line": self.line,
            "text": self.question,
            "coverage": self.coverage,
            "card_paths": list(self.answer_cards),
            "manual_checks": list(MANUAL_CHECKS),
        }


@dataclass(frozen=True)
class AuditReport:
    request_count: int
    card_count: int
    findings: tuple[QuestionFinding, ...]

    @property
    def question_count(self) -> int:
        return len(self.findings)

    @property
    def request_with_questions_count(self) -> int:
        return len({finding.request_path for finding in self.findings})

    @property
    def covered_question_count(self) -> int:
        return sum(finding.coverage == "covered" for finding in self.findings)

    @property
    def uncovered_question_count(self) -> int:
        return sum(finding.coverage == "uncovered" for finding in self.findings)

    def as_dict(self) -> dict[str, object]:
        return {
            "schema": REPORT_SCHEMA,
            "schema_version": 1,
            "request_count": self.request_count,
            "request_with_questions_count": self.request_with_questions_count,
            "card_count": self.card_count,
            "question_count": self.question_count,
            "candidate_count": self.question_count,
            "covered_question_count": self.covered_question_count,
            "uncovered_question_count": self.uncovered_question_count,
            "candidates": [finding.as_dict() for finding in self.findings],
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit a machine-readable JSON report instead of the human report.",
    )
    return parser.parse_args()


def mask_inline_code(line: str) -> str:
    masked = list(line)
    cursor = 0
    while cursor < len(line):
        start = line.find("`", cursor)
        if start < 0:
            break
        delimiter_end = start
        while delimiter_end < len(line) and line[delimiter_end] == "`":
            delimiter_end += 1
        delimiter = line[start:delimiter_end]
        end = line.find(delimiter, delimiter_end)
        if end < 0:
            cursor = delimiter_end
            continue
        for index in range(start, end + len(delimiter)):
            masked[index] = " "
        cursor = end + len(delimiter)
    return "".join(masked)


def mask_html_comments(line: str, in_comment: bool) -> tuple[str, bool]:
    masked = list(line)
    cursor = 0
    while cursor < len(line):
        if in_comment:
            end = line.find("-->", cursor)
            if end < 0:
                for index in range(cursor, len(line)):
                    masked[index] = " "
                return "".join(masked), True
            for index in range(cursor, end + 3):
                masked[index] = " "
            cursor = end + 3
            in_comment = False
            continue

        start = line.find("<!--", cursor)
        if start < 0:
            break
        end = line.find("-->", start + 4)
        if end < 0:
            for index in range(start, len(line)):
                masked[index] = " "
            return "".join(masked), True
        for index in range(start, end + 3):
            masked[index] = " "
        cursor = end + 3

    return "".join(masked), in_comment


def visible_markdown_lines(text: str) -> list[str]:
    visible_lines: list[str] = []
    in_comment = False
    fence: tuple[str, int] | None = None

    for line in text.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        newline = line[len(content) :]

        if fence is not None:
            match = FENCE_RE.match(content)
            if match is not None:
                marker, remainder = match.groups()
                if (
                    marker[0] == fence[0]
                    and len(marker) >= fence[1]
                    and not remainder.strip()
                ):
                    fence = None
            visible_lines.append(" " * len(content) + newline)
            continue

        visible, in_comment = mask_html_comments(
            mask_inline_code(content),
            in_comment,
        )
        match = FENCE_RE.match(visible)
        if match is not None:
            marker = match.group(1)
            fence = (marker[0], len(marker))
            visible_lines.append(" " * len(content) + newline)
            continue

        visible_lines.append(visible + newline)

    return visible_lines


def markdown_sections(text: str) -> list[MarkdownSection]:
    source_lines = text.splitlines(keepends=True)
    visible_lines = visible_markdown_lines(text)
    headings: list[tuple[int, str]] = []
    for index, line in enumerate(visible_lines):
        match = H2_RE.match(line.rstrip("\r\n"))
        if match is not None:
            headings.append((index, match.group(1).strip()))

    sections: list[MarkdownSection] = []
    for index, (line_index, title) in enumerate(headings):
        body_end = (
            headings[index + 1][0]
            if index + 1 < len(headings)
            else len(source_lines)
        )
        sections.append(
            MarkdownSection(
                title=title,
                lines=tuple(source_lines[line_index + 1 : body_end]),
                start_line=line_index + 2,
            )
        )
    return sections


def exact_section(text: str, title: str, source: Path) -> MarkdownSection:
    matches = [section for section in markdown_sections(text) if section.title == title]
    if len(matches) != 1:
        raise ValueError(
            f"{source.as_posix()}: ожидается ровно один раздел ## {title}, "
            f"найдено {len(matches)}"
        )
    return matches[0]


def fenced_literal_blocks(section: MarkdownSection) -> list[LiteralBlock]:
    blocks: list[LiteralBlock] = []
    fence: tuple[str, int, bool, int, list[str]] | None = None

    for offset, line in enumerate(section.lines):
        content = line.rstrip("\r\n")
        match = FENCE_RE.match(content)
        if fence is None:
            if match is None:
                continue
            marker, info = match.groups()
            language = info.strip().split(maxsplit=1)[0].casefold() if info.strip() else ""
            fence = (
                marker[0],
                len(marker),
                language == "text",
                section.start_line + offset + 1,
                [],
            )
            continue

        marker_type, marker_length, is_text, start_line, lines = fence
        if match is not None:
            marker, remainder = match.groups()
            if (
                marker[0] == marker_type
                and len(marker) >= marker_length
                and not remainder.strip()
            ):
                if is_text:
                    blocks.append(LiteralBlock("".join(lines), start_line))
                fence = None
                continue
        lines.append(line)

    if fence is not None:
        raise ValueError("незакрытый fenced-блок внутри ## Текст запроса")
    return blocks


def blockquote_literal_blocks(section: MarkdownSection) -> list[LiteralBlock]:
    blocks: list[LiteralBlock] = []
    current: list[str] = []
    start_line = 0

    def flush() -> None:
        nonlocal current, start_line
        if current:
            blocks.append(LiteralBlock("".join(current), start_line))
            current = []
            start_line = 0

    for offset, line in enumerate(section.lines):
        content = line.rstrip("\r\n")
        newline = line[len(content) :]
        match = BLOCKQUOTE_RE.match(content)
        if match is None:
            flush()
            continue
        if not current:
            start_line = section.start_line + offset
        current.append(match.group(1) + newline)
    flush()
    return blocks


def raw_literal_block(section: MarkdownSection) -> list[LiteralBlock]:
    first = 0
    last = len(section.lines)
    while first < last and not section.lines[first].strip():
        first += 1
    while last > first and not section.lines[last - 1].strip():
        last -= 1
    if first == last:
        return []
    return [
        LiteralBlock(
            "".join(section.lines[first:last]),
            section.start_line + first,
        )
    ]


def literal_blocks(section: MarkdownSection) -> list[LiteralBlock]:
    fenced = fenced_literal_blocks(section)
    if fenced:
        return fenced
    blockquotes = blockquote_literal_blocks(section)
    if blockquotes:
        return blockquotes
    return raw_literal_block(section)


def question_mask(text: str) -> str:
    lines: list[str] = []
    in_comment = False
    for line in text.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        newline = line[len(content) :]
        visible, in_comment = mask_html_comments(
            mask_inline_code(content),
            in_comment,
        )
        masked = list(visible)

        for match in MARKDOWN_LINK_RE.finditer(visible):
            destination_start = match.start(2) - 2
            for index in range(destination_start, match.end(2) + 1):
                masked[index] = " "

        current = "".join(masked)
        for match in BARE_URL_RE.finditer(current):
            for index in range(match.start(), match.end()):
                masked[index] = " "

        for index, character in enumerate(content):
            if character != "?":
                continue
            backslashes = 0
            cursor = index - 1
            while cursor >= 0 and content[cursor] == "\\":
                backslashes += 1
                cursor -= 1
            if backslashes % 2 == 1:
                masked[index] = " "

        lines.append("".join(masked) + newline)
    return "".join(lines)


def terminal_end(masked: str, index: int) -> int | None:
    cursor = index + 1
    while cursor < len(masked) and masked[cursor] in QUESTION_CLOSERS:
        cursor += 1
    if cursor == len(masked) or masked[cursor].isspace():
        return cursor
    return None


def forced_sentence_starts(text: str) -> set[int]:
    starts = {match.end() for match in re.finditer(r"\n[ \t]*\n", text)}
    offset = 0
    for line in text.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        if HEADING_RE.match(content):
            starts.add(offset + len(line))
        offset += len(line)
    return starts


def extract_questions(block: LiteralBlock) -> list[ExtractedQuestion]:
    text = block.text
    masked = question_mask(text)
    starts = forced_sentence_starts(text)
    sentence_start = 0
    questions: list[ExtractedQuestion] = []

    for index, character in enumerate(masked):
        if index in starts:
            sentence_start = index
        if character not in ".!?":
            continue
        end = terminal_end(masked, index)
        if end is None:
            continue
        if character == "?":
            raw = text[sentence_start : index + 1]
            leading = len(raw) - len(raw.lstrip())
            question = raw.strip()
            if question:
                absolute_start = sentence_start + leading
                questions.append(
                    ExtractedQuestion(
                        text=question,
                        line=block.start_line + text.count("\n", 0, absolute_start),
                    )
                )
        sentence_start = end
    return questions


def strip_link_title(destination: str) -> str:
    value = destination.strip()
    if value.startswith("<") and ">" in value:
        return value[1 : value.index(">")]
    title_match = re.search(r"\s+['\"]", value)
    if title_match:
        return value[: title_match.start()]
    return value


def is_external_link(destination: str) -> bool:
    value = destination.strip()
    return (
        re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", value) is not None
        or value.startswith("//")
    )


def visible_links(text: str) -> list[str]:
    links: list[str] = []
    for line in visible_markdown_lines(text):
        for match in MARKDOWN_LINK_RE.finditer(line):
            backslashes = 0
            cursor = match.start() - 1
            while cursor >= 0 and line[cursor] == "\\":
                backslashes += 1
                cursor -= 1
            if backslashes % 2 == 0:
                links.append(strip_link_title(match.group(2)))
    return links


def lexical_absolute(path: Path) -> Path:
    return Path(os.path.abspath(os.path.normpath(path)))


def actual_case_path(path: Path, repo_root: Path) -> Path | None:
    root = repo_root.resolve()
    try:
        relative = path.relative_to(root)
    except ValueError:
        return None

    current = root
    for part in relative.parts:
        if not current.is_dir():
            return None
        children = list(current.iterdir())
        exact = next((child for child in children if child.name == part), None)
        if exact is not None:
            current = exact
            continue
        folded = [child for child in children if child.name.casefold() == part.casefold()]
        if len(folded) != 1:
            return None
        current = folded[0]
    return current


def resolve_request_link(
    destination: str,
    card: Path,
    repo_root: Path,
) -> str | None:
    if not destination or is_external_link(destination):
        return None
    path_part = unquote(destination.split("#", 1)[0].split("?", 1)[0])
    if not path_part:
        return None

    requested = lexical_absolute(card.parent / path_part)
    requests_root = (repo_root / JOURNAL_DIRECTORY).resolve()
    try:
        relative = requested.relative_to(requests_root)
    except ValueError:
        return None
    request_relative = JOURNAL_DIRECTORY / relative
    if session_stem_for_request_path(request_relative.as_posix()) is None:
        return None

    actual = actual_case_path(requested, repo_root)
    if actual is None or not actual.is_file():
        raise ValueError(
            f"{card.relative_to(repo_root).as_posix()}: ссылка на отсутствующий "
            f"исходный запрос {destination!r}"
        )
    if actual != requested:
        raise ValueError(
            f"{card.relative_to(repo_root).as_posix()}: регистр ссылки "
            f"не совпадает с путём {actual.relative_to(repo_root).as_posix()}"
        )
    return actual.relative_to(repo_root).as_posix()


def source_requests_for_card(card: Path, repo_root: Path) -> tuple[str, ...]:
    text = card.read_text(encoding="utf-8")
    sections = [
        section
        for section in markdown_sections(text)
        if section.title == SOURCES_SECTION
    ]
    if len(sections) > 1:
        raise ValueError(
            f"{card.relative_to(repo_root).as_posix()}: повторяется раздел "
            f"## {SOURCES_SECTION}"
        )
    if not sections:
        return ()

    body = "".join(sections[0].lines)
    requests = {
        resolved
        for destination in visible_links(body)
        if (resolved := resolve_request_link(destination, card, repo_root))
        is not None
    }
    return tuple(sorted(requests))


def audit_repository(repo_root: str | Path) -> AuditReport:
    root = Path(repo_root).resolve()
    requests_directory = root / JOURNAL_DIRECTORY
    if not requests_directory.is_dir():
        raise ValueError(f"не найден каталог {JOURNAL_DIRECTORY.as_posix()}")

    request_files = sorted(
        (
            path
            for path in requests_directory.glob(f"*/{REQUEST_FILE_NAME}")
            if is_valid_session_stem(path.parent.name)
        ),
        key=lambda path: path.parent.name,
    )
    questions_by_request: dict[str, list[ExtractedQuestion]] = {}
    for request in request_files:
        relative = request.relative_to(root).as_posix()
        section = exact_section(
            request.read_text(encoding="utf-8"),
            REQUEST_TEXT_SECTION,
            request.relative_to(root),
        )
        questions_by_request[relative] = [
            question
            for block in literal_blocks(section)
            for question in extract_questions(block)
        ]

    cards_directory = root / ANSWER_CARDS_DIRECTORY
    card_files = (
        sorted(
            (
                path
                for path in cards_directory.glob("*.md")
                if path.name.casefold() != "readme.md"
            ),
            key=lambda path: path.name,
        )
        if cards_directory.is_dir()
        else []
    )
    cards_by_request: dict[str, set[str]] = {}
    for card in card_files:
        card_relative = card.relative_to(root).as_posix()
        for request_relative in source_requests_for_card(card, root):
            cards_by_request.setdefault(request_relative, set()).add(card_relative)

    findings: list[QuestionFinding] = []
    for request_relative in sorted(questions_by_request):
        answer_cards = tuple(sorted(cards_by_request.get(request_relative, set())))
        coverage = "covered" if answer_cards else "uncovered"
        for question in questions_by_request[request_relative]:
            findings.append(
                QuestionFinding(
                    request_path=request_relative,
                    line=question.line,
                    question=question.text,
                    coverage=coverage,
                    answer_cards=answer_cards,
                )
            )

    return AuditReport(
        request_count=len(request_files),
        card_count=len(card_files),
        findings=tuple(findings),
    )


def human_report(report: AuditReport) -> str:
    lines = [
        "Кандидаты ручной проверки покрытия раздела «Вопросы и ответы/»",
        "",
        f"Запросов проверено: {report.request_count}",
        f"Запросов с кандидатами: {report.request_with_questions_count}",
        f"Вопросительных кандидатов: {report.question_count}",
        f"Карточек проверено: {report.card_count}",
        f"Кандидатов со ссылкой: {report.covered_question_count}",
        f"Кандидатов без ссылки: {report.uncovered_question_count}",
        "",
        "Кандидаты ручной проверки",
    ]
    if not report.findings:
        lines.append("Кандидатов нет.")
    for index, finding in enumerate(report.findings, start=1):
        cards = ", ".join(finding.answer_cards) if finding.answer_cards else "нет"
        status = "есть ссылка" if finding.coverage == "covered" else "нет ссылки"
        rendered_question = finding.question.replace("\n", "\n   > ")
        lines.extend(
            [
                "",
                f"{index}. [{status}] {finding.request_path}:{finding.line}",
                f"   > {rendered_question}",
                f"   Связанные карточки: {cards}",
                "   Ручная проверка: прямое отношение к сущности FUM; "
                "содержательность ответа; самостоятельная полезность.",
            ]
        )
    lines.extend(
        [
            "",
            "Граница автоматизации",
            "",
            "Ссылка карточки доказывает только покрытие исходного запроса на уровне "
            "пути. Она не доказывает соответствие конкретному вопросу, прямое "
            "отношение к FUM, наличие содержательного ответа или самостоятельную "
            "полезность; наличие ссылки не доказывает качество ответа.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    try:
        report = audit_repository(args.repo_root)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Ошибка аудита покрытия: {error}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(report.as_dict(), ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(human_report(report), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
