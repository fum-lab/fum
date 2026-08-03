#!/usr/bin/env python3
"""Scan repository content for machine-local filesystem path forms."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
from dataclasses import dataclass, replace
from pathlib import Path, PurePosixPath
from typing import Iterable

from path_forms import PathForm, detect_path_forms

REQUEST_LAYOUT_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-struktura-papok-zaprosov"
    / "scripts"
)
if str(REQUEST_LAYOUT_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(REQUEST_LAYOUT_SCRIPTS))

from request_folder_layout import session_stem_for_request_path  # noqa: E402


POLICY_SCHEMA = "fum.machine-local-path-policy.v2"
POLICY_KEYS = frozenset({"schema", "exceptions"})
EXCEPTION_KEYS = frozenset(
    {"id", "path", "kind", "line_sha256", "count", "category", "reason"}
)
EXCEPTION_ID_RE = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\Z")
SHA256_RE = re.compile(r"sha256:[0-9a-f]{64}\Z")
MAX_EXCEPTION_COUNT = 16
POLICY_CATEGORY_BASES = frozenset(
    {
        "allow.path-validation-definition",
        "allow.test-fixture",
        "report.historical",
    }
)
SUPPORTED_KINDS = frozenset(
    {
        "compiler-file-path",
        "file-uri",
        "home-expansion",
        "posix-absolute",
        "posix-user-home",
        "windows-drive",
        "windows-unc",
    }
)
SYSTEM_RUNTIME_PREFIXES = (
    "/Applications/",
    "/Library/",
    "/System/",
    "/bin/",
    "/dev/",
    "/opt/",
    "/usr/",
)
SYSTEM_REGISTRY_PATH = "Инструменты/реестр-системных-приложений-и-инструментов.md"
SYSTEM_RUNTIME_CODE_PATHS = frozenset(
    {
        "Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py",
        "Прототипы/живой-одноагентный-эпизод/Sources/FUMLiveEpisodeRuntime/LiveGitSystemRuntime.swift",
        "Прототипы/теневой-редактор-продолжений/Sources/FUMShadowCore/LocalRuntimePolicy.swift",
    }
)
FENCE_OPEN_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
H2_RE = re.compile(r"^ {0,3}##(?!#)[ \t]+(.+?)(?:[ \t]+#+[ \t]*)?$")


class PolicyError(ValueError):
    """Raised when the exception policy is not narrow and canonical."""


class InventoryError(RuntimeError):
    """Raised when the Git-backed input inventory cannot be proven."""


@dataclass(frozen=True)
class ExactException:
    identifier: str
    path: str
    kind: str
    line_sha256: str
    count: int
    category: str
    reason: str


@dataclass(frozen=True)
class Policy:
    exceptions: tuple[ExactException, ...]


@dataclass(frozen=True)
class Candidate:
    path: str
    line: int
    kind: str
    line_sha256: str
    category: str


@dataclass(frozen=True, order=True)
class Finding:
    path: str
    line: int
    category: str

    def render(self) -> str:
        return f"{escape_report_path(self.path)}:{self.line}:{self.category}"


@dataclass(frozen=True)
class ScanResult:
    findings: tuple[Finding, ...]
    exit_code: int

    def rendered_lines(self) -> tuple[str, ...]:
        return tuple(finding.render() for finding in self.findings)


@dataclass(frozen=True)
class InventoryEntry:
    path: str
    mode: str | None


def escape_report_path(path: str) -> str:
    return (
        path.replace("%", "%25")
        .replace(":", "%3A")
        .replace("\r", "%0D")
        .replace("\n", "%0A")
    )


def _require_exact_keys(
    value: dict[str, object],
    expected: frozenset[str],
    label: str,
) -> None:
    actual = frozenset(value)
    if actual != expected:
        raise PolicyError(f"{label} has missing or unknown fields")


def _validate_policy_path(raw_path: object) -> str:
    if not isinstance(raw_path, str) or not raw_path:
        raise PolicyError("exception path must be a non-empty string")
    if any(character in raw_path for character in "*?[]\\\x00"):
        raise PolicyError("exception path must be exact")
    path = PurePosixPath(raw_path)
    if path.is_absolute() or ".." in path.parts or path.as_posix() != raw_path:
        raise PolicyError("exception path must be normalized and repository-relative")
    return raw_path


def parse_policy(value: object) -> Policy:
    if not isinstance(value, dict):
        raise PolicyError("policy root must be an object")
    _require_exact_keys(value, POLICY_KEYS, "policy")
    if value.get("schema") != POLICY_SCHEMA:
        raise PolicyError("unsupported policy schema")
    raw_exceptions = value.get("exceptions")
    if not isinstance(raw_exceptions, list):
        raise PolicyError("exceptions must be an array")

    exceptions: list[ExactException] = []
    identifiers: set[str] = set()
    identities: set[tuple[str, str, str]] = set()
    for index, raw_exception in enumerate(raw_exceptions):
        if not isinstance(raw_exception, dict):
            raise PolicyError(f"exception {index} must be an object")
        _require_exact_keys(raw_exception, EXCEPTION_KEYS, f"exception {index}")

        identifier = raw_exception.get("id")
        if (
            not isinstance(identifier, str)
            or EXCEPTION_ID_RE.fullmatch(identifier) is None
            or identifier in identifiers
        ):
            raise PolicyError(f"exception {index} has an invalid or duplicate id")
        identifiers.add(identifier)

        path = _validate_policy_path(raw_exception.get("path"))
        kind = raw_exception.get("kind")
        if not isinstance(kind, str) or kind not in SUPPORTED_KINDS:
            raise PolicyError(f"exception {index} has an unsupported kind")
        line_sha256 = raw_exception.get("line_sha256")
        if (
            not isinstance(line_sha256, str)
            or SHA256_RE.fullmatch(line_sha256) is None
        ):
            raise PolicyError(f"exception {index} has an invalid line hash")
        count = raw_exception.get("count")
        if type(count) is not int or not 1 <= count <= MAX_EXCEPTION_COUNT:
            raise PolicyError(f"exception {index} has an unsafe count")
        category = raw_exception.get("category")
        if not isinstance(category, str) or category not in POLICY_CATEGORY_BASES:
            raise PolicyError(f"exception {index} has an unsupported category")
        reason = raw_exception.get("reason")
        if not isinstance(reason, str) or len(reason.strip()) < 20:
            raise PolicyError(f"exception {index} must explain its narrow reason")

        identity = (path, kind, line_sha256)
        if identity in identities:
            raise PolicyError(f"exception {index} duplicates a fingerprint")
        identities.add(identity)
        exceptions.append(
            ExactException(
                identifier=identifier,
                path=path,
                kind=kind,
                line_sha256=line_sha256,
                count=count,
                category=category,
                reason=reason.strip(),
            )
        )
    return Policy(exceptions=tuple(exceptions))


def load_policy(path: Path) -> Policy:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise PolicyError("policy cannot be read as canonical JSON") from exc
    return parse_policy(value)


def _run_git(repo_root: Path, arguments: list[str]) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo_root), "-c", "core.quotepath=false", *arguments],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise InventoryError("git ls-files failed")
    return result.stdout


def _decode_path(raw: bytes) -> str:
    try:
        return os.fsdecode(raw)
    except UnicodeError as exc:
        raise InventoryError("git returned an undecodable path") from exc


def git_inventory(repo_root: Path) -> tuple[InventoryEntry, ...]:
    cached = _run_git(repo_root, ["ls-files", "--cached", "--stage", "-z"])
    others = _run_git(
        repo_root,
        ["ls-files", "--others", "--exclude-standard", "-z"],
    )
    entries: dict[str, InventoryEntry] = {}
    for raw_record in cached.split(b"\0"):
        if not raw_record:
            continue
        try:
            metadata, raw_path = raw_record.split(b"\t", 1)
            mode, _object_id, stage = metadata.split(b" ", 2)
        except ValueError as exc:
            raise InventoryError("git returned an invalid staged record") from exc
        if stage != b"0":
            raise InventoryError("the Git index contains an unmerged path")
        path = _decode_path(raw_path)
        if path in entries:
            raise InventoryError("git returned a duplicate tracked path")
        entries[path] = InventoryEntry(path=path, mode=mode.decode("ascii"))

    for raw_path in others.split(b"\0"):
        if not raw_path:
            continue
        path = _decode_path(raw_path)
        entries.setdefault(path, InventoryEntry(path=path, mode=None))
    return tuple(entries[path] for path in sorted(entries))


def request_text_line_numbers(text: str) -> frozenset[int]:
    active = False
    fence_character: str | None = None
    fence_length = 0
    selected: set[int] = set()
    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.lstrip()
        if fence_character is not None:
            if re.match(
                rf"^ {{0,3}}{re.escape(fence_character)}{{{fence_length},}}[ \t]*$",
                line,
            ):
                fence_character = None
                fence_length = 0
            elif active:
                selected.add(line_number)
            continue

        fence_match = FENCE_OPEN_RE.match(line)
        if fence_match is not None:
            marker = fence_match.group(1)
            fence_character = marker[0]
            fence_length = len(marker)
            if active:
                selected.add(line_number)
            continue

        heading_match = H2_RE.match(line)
        if heading_match is not None:
            active = heading_match.group(1).strip() == "Текст запроса"
            continue
        if active:
            selected.add(line_number)
    return frozenset(selected)


def _is_external_source(path: str) -> bool:
    return path == "Источники" or path.startswith("Источники/")


def _is_request_file(path: str) -> bool:
    return session_stem_for_request_path(path) is not None


def _is_system_runtime(form: PathForm) -> bool:
    return form.kind == "posix-absolute" and form.value.startswith(
        SYSTEM_RUNTIME_PREFIXES
    )


def _is_shebang_runtime(line: str, form: PathForm, line_number: int) -> bool:
    return (
        line_number == 1
        and line.startswith("#!")
        and form.start == 2
        and _is_system_runtime(form)
    )


def _is_gitignore_anchor(path: str, line: str, form: PathForm) -> bool:
    return (
        PurePosixPath(path).name == ".gitignore"
        and form.kind == "posix-absolute"
        and not line[: form.start].strip()
    )


def _base_error_category(kind: str) -> str:
    return f"error.{kind}"


def _is_documented_placeholder(path: str, form: PathForm) -> bool:
    return path.endswith(".md") and form.value.startswith(("/path/to/", "/путь/к/"))


def classify_candidate(
    path: str,
    line: str,
    line_number: int,
    form: PathForm,
    request_text_lines: frozenset[int],
) -> str:
    if _is_external_source(path):
        return f"report.external-source.{form.kind}"
    if _is_request_file(path) and line_number in request_text_lines:
        return f"report.request-text.{form.kind}"
    if form.kind == "compiler-file-path":
        if not path.endswith(".md"):
            return "error.compiler-file-path"
        return "report.compiler-file-path-reference"
    if _is_gitignore_anchor(path, line, form):
        return "allow.gitignore-anchor"
    if _is_documented_placeholder(path, form):
        return "allow.documented-placeholder"
    if _is_system_runtime(form):
        if (
            path == SYSTEM_REGISTRY_PATH
            or path.endswith(".md")
            or path in SYSTEM_RUNTIME_CODE_PATHS
        ):
            return "allow.system-runtime"
        if _is_shebang_runtime(line, form, line_number):
            return "allow.system-runtime"
        return "error.system-runtime-hardcode"
    return _base_error_category(form.kind)


def _line_digest(line: str) -> str:
    return "sha256:" + hashlib.sha256(line.encode("utf-8")).hexdigest()


def scan_text(path: str, text: str) -> list[Candidate]:
    request_lines = (
        request_text_line_numbers(text) if _is_request_file(path) else frozenset()
    )
    candidates: list[Candidate] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        line_hash = _line_digest(line)
        for form in detect_path_forms(line):
            candidates.append(
                Candidate(
                    path=path,
                    line=line_number,
                    kind=form.kind,
                    line_sha256=line_hash,
                    category=classify_candidate(
                        path,
                        line,
                        line_number,
                        form,
                        request_lines,
                    ),
                )
            )
    return candidates


def _policy_display_path(policy_path: Path, repo_root: Path) -> str:
    try:
        return policy_path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return policy_path.name


def _apply_policy(
    candidates: list[Candidate],
    policy: Policy,
    policy_display_path: str,
) -> tuple[list[Candidate], list[Finding], bool]:
    updated = list(candidates)
    policy_findings: list[Finding] = []
    policy_failed = False
    for exception in policy.exceptions:
        indices = [
            index
            for index, candidate in enumerate(updated)
            if candidate.path == exception.path
            and candidate.kind == exception.kind
            and candidate.line_sha256 == exception.line_sha256
            and candidate.category.startswith("error.")
        ]
        if len(indices) != exception.count:
            policy_failed = True
            policy_findings.append(
                Finding(
                    path=policy_display_path,
                    line=0,
                    category="error.policy-count-mismatch",
                )
            )
            continue
        for index in indices:
            updated[index] = replace(
                updated[index],
                category=f"{exception.category}.{exception.kind}",
            )
    return updated, policy_findings, policy_failed


def _deduplicated_findings(candidates: Iterable[Candidate]) -> list[Finding]:
    return sorted(
        {
            Finding(
                path=candidate.path,
                line=candidate.line,
                category=candidate.category,
            )
            for candidate in candidates
        }
    )


def scan_repository(repo_root: str | Path, policy_path: str | Path) -> ScanResult:
    root = Path(repo_root).resolve()
    policy_file = Path(policy_path)
    if not policy_file.is_absolute():
        policy_file = root / policy_file
    policy = load_policy(policy_file)
    policy_display = _policy_display_path(policy_file, root)

    candidates: list[Candidate] = []
    fixed_findings: list[Finding] = []
    inventory_failed = False
    for entry in git_inventory(root):
        if entry.mode == "160000":
            fixed_findings.append(
                Finding(path=entry.path, line=0, category="report.gitlink")
            )
            continue
        if entry.mode == "120000":
            inventory_failed = True
            fixed_findings.append(
                Finding(path=entry.path, line=0, category="error.tracked-symlink")
            )
            continue
        if entry.mode not in {None, "100644", "100755"}:
            inventory_failed = True
            fixed_findings.append(
                Finding(path=entry.path, line=0, category="error.unsupported-git-mode")
            )
            continue

        absolute = root / entry.path
        try:
            mode = absolute.lstat().st_mode
        except OSError:
            inventory_failed = True
            fixed_findings.append(
                Finding(path=entry.path, line=0, category="error.missing-input")
            )
            continue
        if not stat.S_ISREG(mode):
            inventory_failed = True
            fixed_findings.append(
                Finding(path=entry.path, line=0, category="error.non-regular-input")
            )
            continue
        try:
            data = absolute.read_bytes()
        except OSError:
            inventory_failed = True
            fixed_findings.append(
                Finding(path=entry.path, line=0, category="error.unreadable-input")
            )
            continue
        if b"\0" in data:
            category = (
                "report.external-source.binary"
                if _is_external_source(entry.path)
                else "error.binary-input"
            )
            fixed_findings.append(Finding(path=entry.path, line=0, category=category))
            inventory_failed = inventory_failed or category.startswith("error.")
            continue
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            category = (
                "report.external-source.non-utf8"
                if _is_external_source(entry.path)
                else "error.non-utf8-input"
            )
            fixed_findings.append(Finding(path=entry.path, line=0, category=category))
            inventory_failed = inventory_failed or category.startswith("error.")
            continue
        candidates.extend(scan_text(entry.path, text))

    candidates, policy_findings, policy_failed = _apply_policy(
        candidates,
        policy,
        policy_display,
    )
    findings = sorted(
        {
            *fixed_findings,
            *policy_findings,
            *_deduplicated_findings(candidates),
        }
    )
    content_failed = any(
        finding.category.startswith("error.")
        for finding in findings
        if not finding.category.startswith("error.policy-")
    )
    exit_code = 2 if inventory_failed or policy_failed else 1 if content_failed else 0
    return ScanResult(findings=tuple(findings), exit_code=exit_code)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--policy",
        type=Path,
        help="Exact historical-exception policy; defaults to the automation policy.json.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    arguments = parse_args(argv)
    root = arguments.repo_root.resolve()
    policy_path = arguments.policy
    if policy_path is None:
        policy_path = Path(__file__).resolve().parents[1] / "policy.json"
    elif not policy_path.is_absolute():
        policy_path = root / policy_path
    try:
        result = scan_repository(root, policy_path)
    except PolicyError:
        display = _policy_display_path(policy_path, root)
        print(f"{escape_report_path(display)}:0:error.policy-contract")
        return 2
    except InventoryError:
        print(".:0:error.inventory")
        return 2
    for line in result.rendered_lines():
        print(line)
    return result.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
