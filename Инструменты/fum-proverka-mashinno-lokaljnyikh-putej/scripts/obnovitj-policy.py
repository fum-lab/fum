#!/usr/bin/env python3
"""Add exact machine-local-path policy fences from explicit declarations."""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import stat
import sys
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Iterable


SCRIPTS_DIR = Path(__file__).resolve().parent
SCANNER_PATH = SCRIPTS_DIR / "proveritj-mashinno-lokaljnyiye-puti.py"
SCANNER_MODULE_NAME = "_fum_machine_local_path_scanner"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))
scanner_spec = importlib.util.spec_from_file_location(
    SCANNER_MODULE_NAME,
    SCANNER_PATH,
)
if scanner_spec is None or scanner_spec.loader is None:
    raise RuntimeError("machine-local path scanner cannot be loaded")
scanner = importlib.util.module_from_spec(scanner_spec)
sys.modules[SCANNER_MODULE_NAME] = scanner
scanner_spec.loader.exec_module(scanner)


MANIFEST_SCHEMA_V1 = "fum.machine-local-path-policy-update.v1"
MANIFEST_SCHEMA_V2 = "fum.machine-local-path-policy-update.v2"
MANIFEST_V1_KEYS = frozenset({"schema", "declarations"})
MANIFEST_V2_KEYS = frozenset({"schema", "declarations", "retirements"})
DECLARATION_KEYS = frozenset({"id", "path", "line", "category", "reason"})


class UpdateError(ValueError):
    """Raised when an explicit policy update cannot be proven narrow."""


@dataclass(frozen=True)
class Declaration:
    identifier: str
    path: str
    line: int
    category: str
    reason: str


@dataclass(frozen=True)
class UpdatePlan:
    declarations: tuple[Declaration, ...]
    retirements: tuple[object, ...]


def _canonical_json(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def _load_canonical_json(path: Path, label: str) -> object:
    try:
        text = path.read_text(encoding="utf-8")
        value = json.loads(text)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise UpdateError(f"{label} cannot be read as JSON") from exc
    if text != _canonical_json(value):
        raise UpdateError(f"{label} must be canonical JSON")
    return value


def _require_exact_keys(
    value: dict[str, object],
    expected: frozenset[str],
    label: str,
) -> None:
    if frozenset(value) != expected:
        raise UpdateError(f"{label} has missing or unknown fields")


def _parse_declaration(value: object, label: str) -> Declaration:
    if not isinstance(value, dict):
        raise UpdateError(f"{label} must be an object")
    _require_exact_keys(value, DECLARATION_KEYS, label)

    identifier = value.get("id")
    if (
        not isinstance(identifier, str)
        or scanner.EXCEPTION_ID_RE.fullmatch(identifier) is None
    ):
        raise UpdateError(f"{label} has an invalid identifier")

    try:
        path = scanner._validate_policy_path(value.get("path"))
    except scanner.PolicyError as exc:
        raise UpdateError(str(exc)) from exc
    if unicodedata.normalize("NFC", path) != path:
        raise UpdateError(f"{label} path must use canonical NFC")

    line = value.get("line")
    if type(line) is not int or line < 1:
        raise UpdateError(f"{label} line must be a positive integer")

    category = value.get("category")
    if (
        not isinstance(category, str)
        or category not in scanner.POLICY_CATEGORY_BASES
    ):
        raise UpdateError(f"{label} has an unsupported category")

    reason = value.get("reason")
    if (
        not isinstance(reason, str)
        or reason != reason.strip()
        or unicodedata.normalize("NFC", reason) != reason
        or len(reason) < 20
    ):
        raise UpdateError(f"{label} reason must be canonical and substantive")

    return Declaration(
        identifier=identifier,
        path=path,
        line=line,
        category=category,
        reason=reason,
    )


def _parse_declarations(values: Iterable[object]) -> tuple[Declaration, ...]:
    declarations = tuple(
        _parse_declaration(value, f"declaration {index}")
        for index, value in enumerate(values)
    )
    if not declarations:
        raise UpdateError("at least one explicit declaration is required")
    identifiers: set[str] = set()
    selectors: set[tuple[str, int]] = set()
    for declaration in declarations:
        if declaration.identifier in identifiers:
            raise UpdateError("declaration identifier collision")
        identifiers.add(declaration.identifier)
        selector = (declaration.path, declaration.line)
        if selector in selectors:
            raise UpdateError("declaration selector collision")
        selectors.add(selector)
    return declarations


def _parse_retirement(value: object, label: str) -> object:
    if isinstance(value, scanner.ExactException):
        return value
    if not isinstance(value, dict):
        raise UpdateError(f"{label} must be an object")
    try:
        policy = scanner.parse_policy(
            {
                "schema": scanner.POLICY_SCHEMA,
                "exceptions": [value],
            }
        )
    except scanner.PolicyError as exc:
        raise UpdateError(f"{label} must be an exact policy object") from exc
    retirement = policy.exceptions[0]
    if unicodedata.normalize("NFC", retirement.path) != retirement.path:
        raise UpdateError(f"{label} path must use canonical NFC")
    return retirement


def _parse_retirements(values: Iterable[object]) -> tuple[object, ...]:
    retirements = tuple(
        _parse_retirement(value, f"retirement {index}")
        for index, value in enumerate(values)
    )
    identifiers: set[str] = set()
    fingerprints: set[tuple[str, str, str]] = set()
    for retirement in retirements:
        if retirement.identifier in identifiers:
            raise UpdateError("retirement identifier collision")
        identifiers.add(retirement.identifier)
        fingerprint = (
            retirement.path,
            retirement.kind,
            retirement.line_sha256,
        )
        if fingerprint in fingerprints:
            raise UpdateError("retirement fingerprint collision")
        fingerprints.add(fingerprint)
    return retirements


def load_update_plan(path: str | Path) -> UpdatePlan:
    manifest = _load_canonical_json(Path(path), "manifest")
    if not isinstance(manifest, dict):
        raise UpdateError("manifest root must be an object")
    schema = manifest.get("schema")
    if schema == MANIFEST_SCHEMA_V1:
        _require_exact_keys(manifest, MANIFEST_V1_KEYS, "manifest")
        raw_retirements: object = []
    elif schema == MANIFEST_SCHEMA_V2:
        _require_exact_keys(manifest, MANIFEST_V2_KEYS, "manifest")
        raw_retirements = manifest.get("retirements")
    else:
        raise UpdateError("unsupported manifest schema")
    raw_declarations = manifest.get("declarations")
    if not isinstance(raw_declarations, list):
        raise UpdateError("manifest declarations must be an array")
    if not isinstance(raw_retirements, list):
        raise UpdateError("manifest retirements must be an array")
    return UpdatePlan(
        declarations=_parse_declarations(raw_declarations),
        retirements=_parse_retirements(raw_retirements),
    )


def load_manifest(path: str | Path) -> tuple[Declaration, ...]:
    """Load declarations while preserving the v1 public helper contract."""

    return load_update_plan(path).declarations


def parse_cli_declarations(values: Iterable[str]) -> tuple[Declaration, ...]:
    decoded: list[object] = []
    for index, text in enumerate(values):
        try:
            decoded.append(json.loads(text))
        except json.JSONDecodeError as exc:
            raise UpdateError(f"CLI declaration {index} is not JSON") from exc
    return _parse_declarations(decoded)


def _relative_policy_path(
    root: Path,
    input_root: Path,
    policy_path: Path,
) -> Path:
    candidate = policy_path if policy_path.is_absolute() else input_root / policy_path
    try:
        lexical_relative = candidate.relative_to(input_root)
    except ValueError as exc:
        raise UpdateError("policy path escapes the repository") from exc
    if ".." in lexical_relative.parts:
        raise UpdateError("policy path escapes the repository")
    _reject_symlink_components(input_root, lexical_relative.as_posix(), "policy")
    try:
        candidate.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise UpdateError("policy path escapes the repository") from exc
    return candidate


def _reject_symlink_components(root: Path, relative: str, label: str) -> None:
    cursor = root
    for part in PurePosixPath(relative).parts:
        cursor = cursor / part
        try:
            mode = cursor.lstat().st_mode
        except OSError as exc:
            raise UpdateError(f"{label} path is missing") from exc
        if stat.S_ISLNK(mode):
            raise UpdateError(f"{label} path contains a symlink")


def _load_policy_value(policy_path: Path) -> dict[str, object]:
    value = _load_canonical_json(policy_path, "policy")
    if not isinstance(value, dict):
        raise UpdateError("policy root must be an object")
    try:
        scanner.parse_policy(value)
    except scanner.PolicyError as exc:
        raise UpdateError("policy contract is invalid") from exc
    return value


def _inventory_by_path(root: Path) -> dict[str, object]:
    try:
        entries = scanner.git_inventory(root)
    except scanner.InventoryError as exc:
        raise UpdateError("Git inventory cannot be proven") from exc
    return {entry.path: entry for entry in entries}


def _read_target_text(
    root: Path,
    declaration: Declaration,
    inventory: dict[str, object],
) -> str:
    _reject_symlink_components(root, declaration.path, "declaration")
    entry = inventory.get(declaration.path)
    if entry is None:
        raise UpdateError("declaration path is not in the Git inventory")
    if entry.mode == "120000":
        raise UpdateError("declaration path is a tracked symlink")
    if entry.mode not in {None, "100644", "100755"}:
        raise UpdateError("declaration path has an unsupported Git mode")

    target = root / declaration.path
    try:
        mode = target.lstat().st_mode
        data = target.read_bytes()
    except OSError as exc:
        raise UpdateError("declaration path cannot be read") from exc
    if not stat.S_ISREG(mode):
        raise UpdateError("declaration path is not a regular file")
    if b"\0" in data:
        raise UpdateError("declaration path is binary")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise UpdateError("declaration path is not UTF-8") from exc


def _derive_exception(
    root: Path,
    declaration: Declaration,
    inventory: dict[str, object],
    text_cache: dict[str, str],
) -> object:
    text = text_cache.get(declaration.path)
    if text is None:
        text = _read_target_text(root, declaration, inventory)
        text_cache[declaration.path] = text
    lines = text.splitlines()
    if declaration.line > len(lines):
        raise UpdateError("declaration line is outside the file")

    candidates = scanner.scan_text(declaration.path, text)
    selected = [
        candidate
        for candidate in candidates
        if candidate.line == declaration.line
        and candidate.category.startswith("error.")
    ]
    identities = {(candidate.kind, candidate.line_sha256) for candidate in selected}
    if not identities:
        raise UpdateError("declaration line has no active error candidate")
    if len(identities) != 1:
        raise UpdateError("declaration line is ambiguous")
    kind, line_sha256 = next(iter(identities))
    count = sum(
        candidate.kind == kind
        and candidate.line_sha256 == line_sha256
        and candidate.category.startswith("error.")
        for candidate in candidates
    )
    if not 1 <= count <= scanner.MAX_EXCEPTION_COUNT:
        raise UpdateError("derived exception count is unsafe")
    return scanner.ExactException(
        identifier=declaration.identifier,
        path=declaration.path,
        kind=kind,
        line_sha256=line_sha256,
        count=count,
        category=declaration.category,
        reason=declaration.reason,
    )


def _exception_value(exception: object) -> dict[str, object]:
    return {
        "id": exception.identifier,
        "path": exception.path,
        "kind": exception.kind,
        "line_sha256": exception.line_sha256,
        "count": exception.count,
        "category": exception.category,
        "reason": exception.reason,
    }


def _atomic_write(path: Path, content: bytes, expected: bytes) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, stat.S_IMODE(path.stat().st_mode))
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        if path.read_bytes() != expected:
            raise UpdateError("policy changed during update")
        os.replace(temporary, path)
        directory_descriptor = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_descriptor)
        finally:
            os.close(directory_descriptor)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def update_policy(
    repo_root: str | Path,
    policy_path: str | Path,
    declarations: Iterable[object | Declaration],
    *,
    retirements: Iterable[object] = (),
) -> int:
    input_root = Path(repo_root).absolute()
    root = input_root.resolve()
    parsed_declarations = _parse_declarations(
        {
            "id": value.identifier,
            "path": value.path,
            "line": value.line,
            "category": value.category,
            "reason": value.reason,
        }
        if isinstance(value, Declaration)
        else value
        for value in declarations
    )
    parsed_retirements = _parse_retirements(retirements)
    policy = _relative_policy_path(root, input_root, Path(policy_path))
    original = policy.read_bytes()
    value = _load_policy_value(policy)
    current_policy = scanner.parse_policy(value)
    inventory = _inventory_by_path(root)

    current_by_id = {
        exception.identifier: exception for exception in current_policy.exceptions
    }
    retired_ids: set[str] = set()
    changes = 0
    for retirement in parsed_retirements:
        existing = current_by_id.get(retirement.identifier)
        if existing is None:
            continue
        if existing != retirement:
            raise UpdateError("policy retirement mismatch")
        retired_ids.add(retirement.identifier)
        changes += 1

    updated_exceptions = [
        exception
        for exception in current_policy.exceptions
        if exception.identifier not in retired_ids
    ]
    existing_by_id = {
        exception.identifier: exception for exception in updated_exceptions
    }
    existing_by_fingerprint = {
        (exception.path, exception.kind, exception.line_sha256): exception
        for exception in updated_exceptions
    }
    index_by_id = {
        exception.identifier: index
        for index, exception in enumerate(updated_exceptions)
    }
    text_cache: dict[str, str] = {}
    for declaration in parsed_declarations:
        derived = _derive_exception(
            root,
            declaration,
            inventory,
            text_cache,
        )
        existing_id = existing_by_id.get(derived.identifier)
        if existing_id is not None:
            if existing_id == derived:
                continue
            if (
                existing_id.path != derived.path
                or existing_id.category != derived.category
                or existing_id.reason != derived.reason
            ):
                raise UpdateError("policy identifier collision")
            fingerprint = (derived.path, derived.kind, derived.line_sha256)
            fingerprint_owner = existing_by_fingerprint.get(fingerprint)
            if (
                fingerprint_owner is not None
                and fingerprint_owner.identifier != derived.identifier
            ):
                raise UpdateError("policy fingerprint collision")
            old_fingerprint = (
                existing_id.path,
                existing_id.kind,
                existing_id.line_sha256,
            )
            del existing_by_fingerprint[old_fingerprint]
            updated_exceptions[index_by_id[derived.identifier]] = derived
            existing_by_id[derived.identifier] = derived
            existing_by_fingerprint[fingerprint] = derived
            changes += 1
            continue
        fingerprint = (derived.path, derived.kind, derived.line_sha256)
        if fingerprint in existing_by_fingerprint:
            raise UpdateError("policy fingerprint collision")
        index_by_id[derived.identifier] = len(updated_exceptions)
        updated_exceptions.append(derived)
        existing_by_id[derived.identifier] = derived
        existing_by_fingerprint[fingerprint] = derived
        changes += 1

    if not changes:
        return 0
    updated_value = {
        "schema": scanner.POLICY_SCHEMA,
        "exceptions": [
            _exception_value(exception) for exception in updated_exceptions
        ],
    }
    try:
        scanner.parse_policy(updated_value)
    except scanner.PolicyError as exc:
        raise UpdateError("derived policy is invalid") from exc
    encoded = _canonical_json(updated_value).encode("utf-8")
    _atomic_write(policy, encoded, original)
    return changes


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
        help="Policy to update; defaults to this automation's policy.json.",
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--manifest",
        type=Path,
        help="Canonical explicit declaration manifest.",
    )
    source.add_argument(
        "--declaration",
        action="append",
        help="Explicit declaration as a JSON object; may be repeated.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    arguments = parse_args(argv)
    root = arguments.repo_root.absolute()
    policy = arguments.policy
    if policy is None:
        policy = Path(__file__).resolve().parents[1] / "policy.json"
    try:
        plan = (
            load_update_plan(arguments.manifest)
            if arguments.manifest is not None
            else UpdatePlan(
                declarations=parse_cli_declarations(arguments.declaration or []),
                retirements=(),
            )
        )
        added = update_policy(
            root,
            policy,
            plan.declarations,
            retirements=plan.retirements,
        )
    except (UpdateError, OSError) as exc:
        print(f"error.policy-update: {exc}", file=sys.stderr)
        return 2
    state = "updated" if added else "unchanged"
    print(f"policy.{state}: changes={added}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
