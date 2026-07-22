#!/usr/bin/env python3
"""Detect filesystem path forms without resolving or opening them."""

from __future__ import annotations

import re
from dataclasses import dataclass


WEB_URL_RE = re.compile(
    r"\b(?P<scheme>[A-Za-z][A-Za-z0-9+.-]*)://"
    r"[^\s<>\[\]{}\"']+"
)
WINDOWS_DRIVE_RE = re.compile(
    r"(?<![A-Za-z0-9])"
    r"[A-Za-z]:[\\/]"
    r"[^\s<>\[\]{}\"']*"
)
WINDOWS_EXTENDED_UNC_RE = re.compile(
    r"(?<![A-Za-z0-9_\\])\\\\\?\\UNC\\"
    r"[^\s\\/:*?\"<>|]+\\"
    r"[^\s\\:*?\"<>|]+"
    r"(?:\\[^\s\\:*?\"<>|]+)*",
    re.IGNORECASE,
)
WINDOWS_BACKSLASH_UNC_RE = re.compile(
    r"(?<![A-Za-z0-9_\\])\\\\"
    r"[^\s\\/:*?\"<>|]+\\"
    r"[^\s\\:*?\"<>|]+"
    r"(?:\\[^\s\\:*?\"<>|]+)*"
)
WINDOWS_SLASH_UNC_RE = re.compile(
    r"(?<![A-Za-z0-9_:/])//"
    r"[^\s/:*?\"<>|]+/"
    r"[^\s/:*?\"<>|]+"
    r"(?:/[^\s/:*?\"<>|]+)*"
)
HOME_EXPANSION_RE = re.compile(
    r"(?:"
    r"(?<![\w~])~(?:[A-Za-z0-9_][A-Za-z0-9._-]*(?:[\\/][^\s<>\[\]{}\"']*)?|[\\/][^\s<>\[\]{}\"']*|(?![A-Za-z0-9._~-]))"
    r"|(?<!\w)\$(?:env:)?(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)(?!\w)(?:[\\/][^\s<>\[\]{}\"']*)?"
    r"|(?<!\w)\$\{(?:env:)?(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)\}(?!\w)(?:[\\/][^\s<>\[\]{}\"']*)?"
    r"|(?<!\w)\$\((?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)\)(?!\w)(?:[\\/][^\s<>\[\]{}\"']*)?"
    r"|(?<!\w)%(?:HOME|USERPROFILE|HOMEDRIVE|HOMEPATH)%(?!\w)(?:[\\/][^\s<>\[\]{}\"']*)?"
    r")"
    ,
    re.IGNORECASE,
)
COMPILER_FILE_PATH_RE = re.compile(r"(?<![A-Za-z0-9_])#filePath\b")
POSIX_TOKEN_RE = re.compile(
    r"(?<![\w:/.#*%)\]}<])/(?![/\\$*?()<>\[\]{}=+|&!])"
    r"[^\s<>\[\]{}\"'`()]+"
)
TRAILING_PATH_PUNCTUATION = ".,;:!?"


@dataclass(frozen=True, order=True)
class PathForm:
    start: int
    end: int
    kind: str
    value: str


def _overlaps(start: int, end: int, spans: list[tuple[int, int]]) -> bool:
    return any(start < other_end and other_start < end for other_start, other_end in spans)


def _trim_token(text: str, start: int, end: int) -> tuple[int, str]:
    value = text[start:end]
    while value and value[-1] in TRAILING_PATH_PUNCTUATION:
        value = value[:-1]
        end -= 1
    return end, value


def _follows_closing_inline_code_delimiter(text: str, start: int) -> bool:
    if start == 0 or text[start - 1] != "`":
        return False
    run_start = start - 1
    while run_start > 0 and text[run_start - 1] == "`":
        run_start -= 1
    delimiter_length = start - run_start
    previous_equal_runs = sum(
        len(match.group(0)) == delimiter_length
        for match in re.finditer(r"`+", text[:run_start])
    )
    return previous_equal_runs % 2 == 1


def _is_posix_candidate(text: str, start: int, value: str) -> bool:
    if value == "/hooks":
        return False
    if _follows_closing_inline_code_delimiter(text, start):
        return False
    if start > 0 and text[start - 1] == ">" and re.search(
        r"<[^<>]+>$",
        text[:start],
    ):
        return False
    return len(value) > 1


def _posix_kind(value: str) -> str:
    if (
        value == "/Users"
        or value.startswith("/Users/")
        or value == "/home"
        or value.startswith("/home/")
        or value == "/root"
        or value.startswith("/root/")
    ):
        return "posix-user-home"
    return "posix-absolute"


def detect_path_forms(
    text: str,
    *,
    include_web_urls: bool = False,
) -> tuple[PathForm, ...]:
    """Return deterministic non-overlapping path-form spans in source order."""

    forms: list[PathForm] = []
    occupied: list[tuple[int, int]] = []

    for match in WEB_URL_RE.finditer(text):
        scheme = match.group("scheme").casefold()
        kind = "file-uri" if scheme == "file" else "web-url"
        if kind == "file-uri" or include_web_urls:
            forms.append(
                PathForm(
                    start=match.start(),
                    end=match.end(),
                    kind=kind,
                    value=match.group(0),
                )
            )
        occupied.append((match.start(), match.end()))

    for pattern, kind in (
        (WINDOWS_EXTENDED_UNC_RE, "windows-unc"),
        (WINDOWS_BACKSLASH_UNC_RE, "windows-unc"),
        (WINDOWS_SLASH_UNC_RE, "windows-unc"),
        (WINDOWS_DRIVE_RE, "windows-drive"),
        (HOME_EXPANSION_RE, "home-expansion"),
        (COMPILER_FILE_PATH_RE, "compiler-file-path"),
    ):
        for match in pattern.finditer(text):
            if _overlaps(match.start(), match.end(), occupied):
                continue
            end, value = _trim_token(text, match.start(), match.end())
            forms.append(
                PathForm(
                    start=match.start(),
                    end=end,
                    kind=kind,
                    value=value,
                )
            )
            occupied.append((match.start(), match.end()))

    for match in POSIX_TOKEN_RE.finditer(text):
        if _overlaps(match.start(), match.end(), occupied):
            continue
        end, value = _trim_token(text, match.start(), match.end())
        if not value or not _is_posix_candidate(text, match.start(), value):
            continue
        forms.append(
            PathForm(
                start=match.start(),
                end=end,
                kind=_posix_kind(value),
                value=value,
            )
        )

    return tuple(sorted(set(forms)))
