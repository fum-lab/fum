#!/usr/bin/env python3
"""Структурная и семантическая проверка паспортов результата FUM версии 1."""

from __future__ import annotations

import argparse
import hashlib
import ipaddress
import json
import math
import os
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from urllib.parse import parse_qsl, urlsplit


ROOT_KEYS = {
    "schema_version",
    "passport_id",
    "supersedes_passport_id",
    "result",
    "provenance",
    "verification",
    "cost",
    "confidence",
    "recipients",
    "transfers",
}
RESULT_KEYS = {"result_id", "kind", "summary", "state_ref", "scope", "artifacts"}
SCOPE_KEYS = {"claim", "acceptance_criteria", "intended_uses", "preconditions", "exclusions"}
ARTIFACT_KEYS = {"artifact_id", "role", "publication_ref", "state_ref"}
PROVENANCE_KEYS = {"producer_ref", "source_refs", "parent_result_ids", "origin"}
ORIGIN_KEYS = {"carrier", "repository_ref", "lineage_role", "commit"}
COMMIT_KEYS = {"algorithm", "value"}
CHECK_KEYS = {
    "check_id",
    "stage",
    "subject_artifact_ids",
    "method",
    "status",
    "evidence_refs",
    "reason",
}
COST_KEYS = {"expected", "actual"}
COST_SECTION_KEYS = {"coverage", "coverage_reason", "items"}
COST_ITEM_KEYS = {"kind", "status", "amount", "unit", "evidence_refs", "reason"}
CONFIDENCE_KEYS = {
    "assessor_ref",
    "subject_artifact_ids",
    "claim",
    "assessment",
    "value",
    "method",
    "basis_check_ids",
    "evidence_refs",
    "calibration",
    "reason",
}
RECIPIENT_KEYS = {"recipient_id", "purpose", "access", "constraints"}
TRANSFER_KEYS = {"transfer_id", "recipient_id", "artifact_ids", "status", "evidence_refs", "reason"}
TRANSFER_OPTIONAL_KEYS = {"transformation_ref"}

IDENTIFIER_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,127}$")
SCHEME_RE = re.compile(r"^([A-Za-z][A-Za-z0-9+.-]*):")
WINDOWS_ABSOLUTE_RE = re.compile(r"^[A-Za-z]:[\\/]")
SHA1_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
GIT_COMMIT_REF_RE = re.compile(r"^git:commit:([0-9a-f]{40}|[0-9a-f]{64})$")
URN_RE = re.compile(r"^urn:[A-Za-z0-9][A-Za-z0-9-]{0,31}:[^\s\\]+$")
SHA256_REF_RE = re.compile(r"^sha256:([0-9a-f]{64})$")

CHECK_STAGES = {"internal", "external"}
CHECK_STATUSES = {"passed", "failed", "inconclusive", "not_run"}
COST_COVERAGES = {"complete", "partial", "unknown"}
COST_KINDS = {
    "compute",
    "wall_time",
    "communication",
    "verification",
    "error_recovery",
    "human_attention",
    "money",
    "energy",
    "other",
}
COST_STATUSES = {"measured", "estimated", "unknown"}
LINEAGE_ROLES = {"upstream", "fork", "mirror", "local_derivative", "unknown"}
RECIPIENT_ACCESS = {"public", "restricted", "private"}
TRANSFER_STATUSES = {"planned", "attempted", "delivered", "acknowledged", "failed", "cancelled"}
SECRET_MARKERS = ("token", "secret", "password", "passwd", "credential", "api_key", "apikey", "signature")
GIT_ENVIRONMENT_KEYS = {
    "GIT_DIR",
    "GIT_WORK_TREE",
    "GIT_INDEX_FILE",
    "GIT_NAMESPACE",
    "GIT_OBJECT_DIRECTORY",
    "GIT_ALTERNATE_OBJECT_DIRECTORIES",
    "GIT_COMMON_DIR",
}

_GIT_OBJECT_CACHE: dict[tuple[str, str], bool] = {}


class DuplicateKeyError(ValueError):
    """Повтор ключа в одном JSON-объекте."""


def add_error(errors: list[str], record: Path, field: str, message: str) -> None:
    errors.append(f"{record}: {field}: {message}")


def object_without_duplicate_keys(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError(f"повтор ключа {key!r}")
        result[key] = value
    return result


def reject_non_json_constant(value: str) -> None:
    raise ValueError(f"недопустимая JSON-константа {value}")


def load_json_object(path: Path, errors: list[str]) -> dict | None:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=object_without_duplicate_keys,
            parse_constant=reject_non_json_constant,
        )
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
        add_error(errors, path, "$", f"не удалось прочитать JSON: {exc}")
        return None
    if not isinstance(value, dict):
        add_error(errors, path, "$", "должен быть JSON-объектом")
        return None
    return value


def exact_object(
    value: object,
    field: str,
    keys: set[str],
    errors: list[str],
    record: Path,
    *,
    optional_keys: set[str] | frozenset[str] = frozenset(),
) -> dict:
    if not isinstance(value, dict):
        add_error(errors, record, field, "должен быть объектом")
        return {}
    missing = sorted(keys - value.keys())
    unknown = sorted(value.keys() - keys - optional_keys)
    if missing:
        add_error(errors, record, field, f"отсутствуют обязательные поля: {', '.join(missing)}")
    if unknown:
        add_error(errors, record, field, f"неизвестные поля запрещены: {', '.join(unknown)}")
    return value


def non_empty_string(value: object, field: str, errors: list[str], record: Path) -> str | None:
    if not isinstance(value, str) or not value:
        add_error(errors, record, field, "должен быть непустой строкой")
        return None
    return value


def nullable_string(value: object, field: str, errors: list[str], record: Path) -> str | None:
    if value is None:
        return None
    return non_empty_string(value, field, errors, record)


def identifier(value: object, field: str, errors: list[str], record: Path) -> str | None:
    if not isinstance(value, str) or not IDENTIFIER_RE.fullmatch(value):
        add_error(errors, record, field, "должен соответствовать [a-z0-9][a-z0-9._-]{0,127}")
        return None
    return value


def string_list(
    value: object,
    field: str,
    errors: list[str],
    record: Path,
    *,
    min_items: int = 0,
    identifiers: bool = False,
) -> list[str]:
    if not isinstance(value, list):
        add_error(errors, record, field, "должен быть массивом")
        return []
    if len(value) < min_items:
        add_error(errors, record, field, f"должен содержать не менее {min_items} элементов")
    result: list[str] = []
    seen: set[str] = set()
    for index, item in enumerate(value):
        item_field = f"{field}[{index}]"
        parsed = identifier(item, item_field, errors, record) if identifiers else non_empty_string(item, item_field, errors, record)
        if parsed is None:
            continue
        if parsed in seen:
            add_error(errors, record, item_field, f"повтор значения {parsed!r}")
        seen.add(parsed)
        result.append(parsed)
    return result


def number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def is_private_https_url(value: str) -> bool:
    parts = urlsplit(value)
    if parts.username or parts.password:
        return True
    host = parts.hostname
    if not host:
        return True
    folded_host = host.rstrip(".").casefold()
    if folded_host == "localhost" or folded_host.endswith((".localhost", ".local", ".internal", ".lan", ".home")):
        return True
    try:
        address = ipaddress.ip_address(folded_host)
    except ValueError:
        return False
    return address.is_private or address.is_loopback or address.is_link_local or address.is_reserved


def has_secret_url_material(value: str) -> bool:
    parts = urlsplit(value)
    keys = [key for key, _ in parse_qsl(parts.query, keep_blank_values=True)]
    keys.extend(key for key, _ in parse_qsl(parts.fragment, keep_blank_values=True))
    if any(any(marker in key.casefold() for marker in SECRET_MARKERS) for key in keys):
        return True
    folded = f"{parts.query}&{parts.fragment}".casefold()
    return any(re.search(rf"(?:^|[?&#;])[^=]*{re.escape(marker)}[^=]*=", folded) for marker in SECRET_MARKERS)


def exact_case_exists(root: Path, relative: str) -> bool:
    current = root
    for part in PurePosixPath(relative).parts:
        try:
            names = {entry.name for entry in current.iterdir()}
        except OSError:
            return False
        if part not in names:
            return False
        current = current / part
    return current.exists()


def local_ref_path(value: str, root: Path) -> Path | None:
    folded = value.casefold()
    if (
        SCHEME_RE.match(value)
        or value.startswith(("/", "~/", "./"))
        or WINDOWS_ABSOLUTE_RE.match(value)
        or folded.startswith("file:")
        or "\\" in value
        or "?" in value
        or "%" in value
    ):
        return None
    path_text = value.split("#", 1)[0]
    if not path_text or "//" in path_text or path_text.endswith("/"):
        return None
    parts = PurePosixPath(path_text).parts
    if not parts or any(part in {"", ".", ".."} for part in parts):
        return None
    candidate = (root / PurePosixPath(path_text)).resolve()
    try:
        candidate.relative_to(root)
    except ValueError:
        return None
    return candidate


def git_environment() -> dict[str, str]:
    environment = os.environ.copy()
    for key in GIT_ENVIRONMENT_KEYS:
        environment.pop(key, None)
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    return environment


def git_object_exists(root: Path, object_spec: str) -> bool:
    cache_key = (str(root), object_spec)
    if cache_key in _GIT_OBJECT_CACHE:
        return _GIT_OBJECT_CACHE[cache_key]
    completed = subprocess.run(
        ["git", "--no-replace-objects", "-C", str(root), "cat-file", "-e", object_spec],
        cwd=root,
        env=git_environment(),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    exists = completed.returncode == 0
    _GIT_OBJECT_CACHE[cache_key] = exists
    return exists


def validate_ref(
    value: object,
    field: str,
    root: Path,
    errors: list[str],
    record: Path,
    *,
    pinned_commit: str | None = None,
) -> None:
    if not isinstance(value, str) or not value:
        add_error(errors, record, field, "должен быть непустой ссылкой")
        return
    folded = value.casefold()
    if value.startswith(("/", "~/")) or WINDOWS_ABSOLUTE_RE.match(value) or folded.startswith("file:"):
        add_error(errors, record, field, f"машинно-локальный абсолютный путь запрещён: {value}")
        return
    if "\\" in value:
        add_error(errors, record, field, f"обратная косая черта запрещена: {value}")
        return

    scheme_match = SCHEME_RE.match(value)
    if scheme_match:
        scheme = scheme_match.group(1).casefold()
        if scheme == "https":
            parts = urlsplit(value)
            if parts.scheme != "https" or not parts.netloc:
                add_error(errors, record, field, f"некорректная HTTPS-ссылка: {value}")
            elif is_private_https_url(value):
                add_error(errors, record, field, f"приватный или локальный URL запрещён: {value}")
            elif has_secret_url_material(value):
                add_error(errors, record, field, f"похожий на секрет параметр URL запрещён: {value}")
            return
        if scheme == "git":
            match = GIT_COMMIT_REF_RE.fullmatch(value)
            if not match:
                add_error(errors, record, field, f"git-ссылка должна иметь вид git:commit:<SHA-1|SHA-256>: {value}")
                return
            commit = match.group(1)
            if not git_object_exists(root, f"{commit}^{{commit}}"):
                add_error(errors, record, field, f"Git-коммит не найден в репозитории: {commit}")
            return
        if scheme == "urn":
            if not URN_RE.fullmatch(value):
                add_error(errors, record, field, f"некорректная устойчивая URN-ссылка: {value}")
            return
        if scheme == "sha256":
            if not SHA256_REF_RE.fullmatch(value):
                add_error(errors, record, field, f"sha256-ссылка должна содержать 64 строчные hex-цифры: {value}")
            return
        add_error(errors, record, field, f"поддерживаются только относительные, https:, git:, urn: и sha256: ссылки: {value}")
        return

    if "?" in value or "%" in value:
        add_error(errors, record, field, f"query и percent-encoding в локальной ссылке запрещены: {value}")
        return
    path_text, separator, fragment = value.partition("#")
    if not path_text or path_text.startswith("./") or "//" in path_text or path_text.endswith("/"):
        add_error(errors, record, field, f"локальный путь должен быть каноническим относительно корня памяти: {value}")
        return
    if separator and not fragment:
        add_error(errors, record, field, f"пустой фрагмент локальной ссылки запрещён: {value}")
        return
    parts = PurePosixPath(path_text).parts
    if not parts or any(part in {"", ".", ".."} for part in parts):
        add_error(errors, record, field, f"локальная ссылка содержит неканонический сегмент: {value}")
        return
    candidate = (root / PurePosixPath(path_text)).resolve()
    try:
        candidate.relative_to(root)
    except ValueError:
        add_error(errors, record, field, f"локальная ссылка выходит за корень памяти: {value}")
        return
    if pinned_commit is not None:
        if not git_object_exists(root, f"{pinned_commit}:{path_text}"):
            add_error(
                errors,
                record,
                field,
                f"путь отсутствует в закреплённом Git-коммите {pinned_commit}",
            )
    elif not exact_case_exists(root, path_text):
        add_error(errors, record, field, f"локальная ссылка отсутствует или не совпадает по регистру: {value}")


def walk_refs(
    value: object,
    root: Path,
    errors: list[str],
    record: Path,
    prefix: str = "$",
    *,
    pinned_commit: str | None = None,
) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            field = f"{prefix}.{key}"
            if key.endswith("_ref"):
                if key == "transformation_ref" and child is None:
                    pass
                else:
                    validate_ref(child, field, root, errors, record, pinned_commit=pinned_commit)
            elif key.endswith("_refs"):
                if not isinstance(child, list):
                    add_error(errors, record, field, "должен быть массивом ссылок")
                else:
                    for index, item in enumerate(child):
                        validate_ref(
                            item,
                            f"{field}[{index}]",
                            root,
                            errors,
                            record,
                            pinned_commit=pinned_commit,
                        )
            walk_refs(child, root, errors, record, field, pinned_commit=pinned_commit)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk_refs(child, root, errors, record, f"{prefix}[{index}]", pinned_commit=pinned_commit)


def shared_git_commit(passport: dict) -> str | None:
    """Вернуть commit, одинаково закрепляющий результат и его Git-происхождение."""

    result = passport.get("result")
    provenance = passport.get("provenance")
    if not isinstance(result, dict) or not isinstance(provenance, dict):
        return None
    state_ref = result.get("state_ref")
    state_match = GIT_COMMIT_REF_RE.fullmatch(state_ref) if isinstance(state_ref, str) else None
    origin = provenance.get("origin")
    commit_record = origin.get("commit") if isinstance(origin, dict) else None
    commit = commit_record.get("value") if isinstance(commit_record, dict) else None
    if state_match is None or not isinstance(commit, str) or state_match.group(1) != commit:
        return None
    return commit


def validate_commit(value: object, field: str, root: Path, errors: list[str], record: Path) -> str | None:
    commit = exact_object(value, field, COMMIT_KEYS, errors, record)
    algorithm = commit.get("algorithm")
    digest = commit.get("value")
    if algorithm not in {"sha1", "sha256"}:
        add_error(errors, record, f"{field}.algorithm", "должен быть sha1 или sha256")
        return None
    pattern = SHA1_RE if algorithm == "sha1" else SHA256_RE
    if not isinstance(digest, str) or not pattern.fullmatch(digest):
        expected_length = 40 if algorithm == "sha1" else 64
        add_error(errors, record, f"{field}.value", f"должен содержать {expected_length} строчных hex-цифр")
        return None
    if not git_object_exists(root, f"{digest}^{{commit}}"):
        add_error(errors, record, f"{field}.value", f"Git-коммит не найден в репозитории: {digest}")
    return digest


def validate_scope(value: object, errors: list[str], record: Path) -> None:
    scope = exact_object(value, "$.result.scope", SCOPE_KEYS, errors, record)
    non_empty_string(scope.get("claim"), "$.result.scope.claim", errors, record)
    string_list(scope.get("acceptance_criteria"), "$.result.scope.acceptance_criteria", errors, record, min_items=1)
    string_list(scope.get("intended_uses"), "$.result.scope.intended_uses", errors, record, min_items=1)
    string_list(scope.get("preconditions"), "$.result.scope.preconditions", errors, record)
    string_list(scope.get("exclusions"), "$.result.scope.exclusions", errors, record, min_items=1)


def validate_result(value: object, root: Path, errors: list[str], record: Path) -> tuple[set[str], str | None, str | None]:
    result = exact_object(value, "$.result", RESULT_KEYS, errors, record)
    result_id = identifier(result.get("result_id"), "$.result.result_id", errors, record)
    identifier(result.get("kind"), "$.result.kind", errors, record)
    non_empty_string(result.get("summary"), "$.result.summary", errors, record)
    state_ref = non_empty_string(result.get("state_ref"), "$.result.state_ref", errors, record)
    if state_ref is not None and not (GIT_COMMIT_REF_RE.fullmatch(state_ref) or SHA256_REF_RE.fullmatch(state_ref)):
        add_error(errors, record, "$.result.state_ref", "состояние результата должно быть закреплено git:commit: или sha256:")
    validate_scope(result.get("scope"), errors, record)

    artifacts_value = result.get("artifacts")
    if not isinstance(artifacts_value, list):
        add_error(errors, record, "$.result.artifacts", "должен быть массивом")
        artifacts_value = []
    if not artifacts_value:
        add_error(errors, record, "$.result.artifacts", "должен содержать хотя бы один артефакт")
    artifact_ids: set[str] = set()
    state_sha_match = SHA256_REF_RE.fullmatch(state_ref or "")
    for index, item in enumerate(artifacts_value):
        field = f"$.result.artifacts[{index}]"
        artifact = exact_object(item, field, ARTIFACT_KEYS, errors, record)
        artifact_id = identifier(artifact.get("artifact_id"), f"{field}.artifact_id", errors, record)
        if artifact_id is not None:
            if artifact_id in artifact_ids:
                add_error(errors, record, f"{field}.artifact_id", f"дубликат artifact_id {artifact_id!r}")
            artifact_ids.add(artifact_id)
        identifier(artifact.get("role"), f"{field}.role", errors, record)
        publication_ref = non_empty_string(artifact.get("publication_ref"), f"{field}.publication_ref", errors, record)
        artifact_state = non_empty_string(artifact.get("state_ref"), f"{field}.state_ref", errors, record)
        if state_ref is not None and artifact_state is not None and artifact_state != state_ref:
            add_error(errors, record, f"{field}.state_ref", "должен совпадать с единым $.result.state_ref")

        local_path = local_ref_path(publication_ref, root) if publication_ref else None
        if local_path is not None and state_sha_match:
            try:
                actual_hash = hashlib.sha256(local_path.read_bytes()).hexdigest()
            except OSError as exc:
                add_error(errors, record, f"{field}.publication_ref", f"не удалось вычислить SHA-256: {exc}")
            else:
                if actual_hash != state_sha_match.group(1):
                    add_error(errors, record, f"{field}.state_ref", "не совпадает с SHA-256 локального артефакта")
    return artifact_ids, state_ref, result_id


def validate_provenance(
    value: object,
    result_state_ref: str | None,
    result_id: str | None,
    root: Path,
    errors: list[str],
    record: Path,
) -> None:
    provenance = exact_object(value, "$.provenance", PROVENANCE_KEYS, errors, record)
    non_empty_string(provenance.get("producer_ref"), "$.provenance.producer_ref", errors, record)
    string_list(provenance.get("source_refs"), "$.provenance.source_refs", errors, record, min_items=1)
    parents = string_list(
        provenance.get("parent_result_ids"),
        "$.provenance.parent_result_ids",
        errors,
        record,
        identifiers=True,
    )
    if result_id is not None and result_id in parents:
        add_error(errors, record, "$.provenance.parent_result_ids", "результат не может быть собственным родителем")
    origin = exact_object(provenance.get("origin"), "$.provenance.origin", ORIGIN_KEYS, errors, record)
    if origin.get("carrier") != "git":
        add_error(errors, record, "$.provenance.origin.carrier", "в версии 1 должен быть равен git")
    non_empty_string(origin.get("repository_ref"), "$.provenance.origin.repository_ref", errors, record)
    if origin.get("lineage_role") not in LINEAGE_ROLES:
        add_error(errors, record, "$.provenance.origin.lineage_role", f"допустимы: {', '.join(sorted(LINEAGE_ROLES))}")
    commit = validate_commit(origin.get("commit"), "$.provenance.origin.commit", root, errors, record)
    if commit is not None and result_state_ref is not None and result_state_ref != f"git:commit:{commit}":
        add_error(errors, record, "$.result.state_ref", "должен совпадать с $.provenance.origin.commit")


def validate_checks(
    value: object,
    artifact_ids: set[str],
    errors: list[str],
    record: Path,
) -> set[str]:
    if not isinstance(value, list):
        add_error(errors, record, "$.verification", "должен быть массивом")
        return set()
    if not value:
        add_error(errors, record, "$.verification", "должен содержать хотя бы одну проверку")
    check_ids: set[str] = set()
    for index, item in enumerate(value):
        field = f"$.verification[{index}]"
        check = exact_object(item, field, CHECK_KEYS, errors, record)
        check_id = identifier(check.get("check_id"), f"{field}.check_id", errors, record)
        if check_id is not None:
            if check_id in check_ids:
                add_error(errors, record, f"{field}.check_id", f"дубликат check_id {check_id!r}")
            check_ids.add(check_id)
        if check.get("stage") not in CHECK_STAGES:
            add_error(errors, record, f"{field}.stage", "должен быть internal или external")
        subjects = string_list(
            check.get("subject_artifact_ids"),
            f"{field}.subject_artifact_ids",
            errors,
            record,
            min_items=1,
            identifiers=True,
        )
        for subject in subjects:
            if subject not in artifact_ids:
                add_error(errors, record, f"{field}.subject_artifact_ids", f"неизвестный artifact_id {subject!r}")
        non_empty_string(check.get("method"), f"{field}.method", errors, record)
        status = check.get("status")
        if status not in CHECK_STATUSES:
            add_error(errors, record, f"{field}.status", f"допустимы: {', '.join(sorted(CHECK_STATUSES))}")
        evidence = string_list(check.get("evidence_refs"), f"{field}.evidence_refs", errors, record)
        reason = nullable_string(check.get("reason"), f"{field}.reason", errors, record)
        if status in {"passed", "failed"} and not evidence:
            add_error(errors, record, f"{field}.evidence_refs", f"статус {status} требует свидетельство")
        if status in {"inconclusive", "not_run"} and reason is None:
            add_error(errors, record, f"{field}.reason", f"статус {status} требует причину")
    return check_ids


def validate_cost_section(value: object, field: str, errors: list[str], record: Path) -> None:
    section = exact_object(value, field, COST_SECTION_KEYS, errors, record)
    coverage = section.get("coverage")
    if coverage not in COST_COVERAGES:
        add_error(errors, record, f"{field}.coverage", f"допустимы: {', '.join(sorted(COST_COVERAGES))}")
    coverage_reason = nullable_string(section.get("coverage_reason"), f"{field}.coverage_reason", errors, record)
    if coverage in {"partial", "unknown"} and coverage_reason is None:
        add_error(errors, record, f"{field}.coverage_reason", f"coverage={coverage} требует причину")
    items = section.get("items")
    if not isinstance(items, list):
        add_error(errors, record, f"{field}.items", "должен быть массивом")
        return
    if not items:
        add_error(errors, record, f"{field}.items", "должен содержать хотя бы одну статью стоимости")
    for index, item in enumerate(items):
        item_field = f"{field}.items[{index}]"
        cost_item = exact_object(item, item_field, COST_ITEM_KEYS, errors, record)
        if cost_item.get("kind") not in COST_KINDS:
            add_error(errors, record, f"{item_field}.kind", f"неизвестный вид стоимости {cost_item.get('kind')!r}")
        status = cost_item.get("status")
        if status not in COST_STATUSES:
            add_error(errors, record, f"{item_field}.status", f"допустимы: {', '.join(sorted(COST_STATUSES))}")
        amount = cost_item.get("amount")
        unit = cost_item.get("unit")
        evidence = string_list(cost_item.get("evidence_refs"), f"{item_field}.evidence_refs", errors, record)
        reason = nullable_string(cost_item.get("reason"), f"{item_field}.reason", errors, record)
        if status in {"measured", "estimated"}:
            if not number(amount) or amount < 0:
                add_error(errors, record, f"{item_field}.amount", f"status={status} требует конечное число >= 0")
            non_empty_string(unit, f"{item_field}.unit", errors, record)
            if not evidence:
                add_error(errors, record, f"{item_field}.evidence_refs", f"status={status} требует свидетельство")
        elif status == "unknown":
            if amount is not None or unit is not None:
                add_error(errors, record, item_field, "unknown требует amount=null и unit=null; неизвестное не равно нулю")
            if reason is None:
                add_error(errors, record, f"{item_field}.reason", "unknown требует причину")


def validate_cost(value: object, errors: list[str], record: Path) -> None:
    cost = exact_object(value, "$.cost", COST_KEYS, errors, record)
    validate_cost_section(cost.get("expected"), "$.cost.expected", errors, record)
    validate_cost_section(cost.get("actual"), "$.cost.actual", errors, record)


def validate_confidence(
    value: object,
    artifact_ids: set[str],
    check_ids: set[str],
    errors: list[str],
    record: Path,
) -> None:
    confidence = exact_object(value, "$.confidence", CONFIDENCE_KEYS, errors, record)
    non_empty_string(confidence.get("assessor_ref"), "$.confidence.assessor_ref", errors, record)
    subjects = string_list(
        confidence.get("subject_artifact_ids"),
        "$.confidence.subject_artifact_ids",
        errors,
        record,
        identifiers=True,
    )
    for subject in subjects:
        if subject not in artifact_ids:
            add_error(errors, record, "$.confidence.subject_artifact_ids", f"неизвестный artifact_id {subject!r}")
    claim = nullable_string(confidence.get("claim"), "$.confidence.claim", errors, record)
    if not subjects and claim is None:
        add_error(errors, record, "$.confidence", "нужно указать хотя бы один subject_artifact_id или claim")

    assessment = confidence.get("assessment")
    if assessment not in {"estimated", "unknown"}:
        add_error(errors, record, "$.confidence.assessment", "должен быть estimated или unknown")
    value_number = confidence.get("value")
    method = nullable_string(confidence.get("method"), "$.confidence.method", errors, record)
    basis = string_list(
        confidence.get("basis_check_ids"),
        "$.confidence.basis_check_ids",
        errors,
        record,
        identifiers=True,
    )
    for check_id in basis:
        if check_id not in check_ids:
            add_error(errors, record, "$.confidence.basis_check_ids", f"неизвестный check_id {check_id!r}")
    evidence = string_list(confidence.get("evidence_refs"), "$.confidence.evidence_refs", errors, record)
    calibration = confidence.get("calibration")
    reason = nullable_string(confidence.get("reason"), "$.confidence.reason", errors, record)

    if assessment == "estimated":
        if not number(value_number) or not 0 <= value_number <= 1:
            add_error(errors, record, "$.confidence.value", "estimated требует конечное число от 0 до 1")
        if method is None:
            add_error(errors, record, "$.confidence.method", "estimated требует метод")
        if not basis and not evidence:
            add_error(errors, record, "$.confidence", "estimated требует basis_check_ids или evidence_refs")
        if calibration not in {"calibrated", "uncalibrated"}:
            add_error(errors, record, "$.confidence.calibration", "estimated требует calibrated или uncalibrated")
        if calibration == "uncalibrated" and reason is None:
            add_error(errors, record, "$.confidence.reason", "uncalibrated требует явную причину")
    elif assessment == "unknown":
        if value_number is not None or method is not None or calibration is not None:
            add_error(errors, record, "$.confidence", "unknown требует value=null, method=null и calibration=null")
        if reason is None:
            add_error(errors, record, "$.confidence.reason", "unknown требует причину")


def validate_recipients(value: object, errors: list[str], record: Path) -> set[str]:
    if not isinstance(value, list):
        add_error(errors, record, "$.recipients", "должен быть массивом")
        return set()
    if not value:
        add_error(errors, record, "$.recipients", "должен содержать хотя бы одного адресата")
    recipient_ids: set[str] = set()
    for index, item in enumerate(value):
        field = f"$.recipients[{index}]"
        recipient = exact_object(item, field, RECIPIENT_KEYS, errors, record)
        recipient_id = identifier(recipient.get("recipient_id"), f"{field}.recipient_id", errors, record)
        if recipient_id is not None:
            if recipient_id in recipient_ids:
                add_error(errors, record, f"{field}.recipient_id", f"дубликат recipient_id {recipient_id!r}")
            recipient_ids.add(recipient_id)
        non_empty_string(recipient.get("purpose"), f"{field}.purpose", errors, record)
        if recipient.get("access") not in RECIPIENT_ACCESS:
            add_error(errors, record, f"{field}.access", f"допустимы: {', '.join(sorted(RECIPIENT_ACCESS))}")
        string_list(recipient.get("constraints"), f"{field}.constraints", errors, record)
    return recipient_ids


def validate_transfers(
    value: object,
    artifact_ids: set[str],
    recipient_ids: set[str],
    errors: list[str],
    record: Path,
) -> None:
    if not isinstance(value, list):
        add_error(errors, record, "$.transfers", "должен быть массивом")
        return
    if not value:
        add_error(errors, record, "$.transfers", "должен содержать хотя бы одну передачу")
    transfer_ids: set[str] = set()
    for index, item in enumerate(value):
        field = f"$.transfers[{index}]"
        transfer = exact_object(
            item,
            field,
            TRANSFER_KEYS,
            errors,
            record,
            optional_keys=TRANSFER_OPTIONAL_KEYS,
        )
        transfer_id = identifier(transfer.get("transfer_id"), f"{field}.transfer_id", errors, record)
        if transfer_id is not None:
            if transfer_id in transfer_ids:
                add_error(errors, record, f"{field}.transfer_id", f"дубликат transfer_id {transfer_id!r}")
            transfer_ids.add(transfer_id)
        recipient_id = identifier(transfer.get("recipient_id"), f"{field}.recipient_id", errors, record)
        if recipient_id is not None and recipient_id not in recipient_ids:
            add_error(errors, record, f"{field}.recipient_id", f"неизвестный recipient_id {recipient_id!r}")
        transferred_artifacts = string_list(
            transfer.get("artifact_ids"),
            f"{field}.artifact_ids",
            errors,
            record,
            min_items=1,
            identifiers=True,
        )
        for artifact_id in transferred_artifacts:
            if artifact_id not in artifact_ids:
                add_error(errors, record, f"{field}.artifact_ids", f"неизвестный artifact_id {artifact_id!r}")
        if "transformation_ref" in transfer:
            nullable_string(transfer.get("transformation_ref"), f"{field}.transformation_ref", errors, record)
        status = transfer.get("status")
        if status not in TRANSFER_STATUSES:
            add_error(errors, record, f"{field}.status", f"допустимы: {', '.join(sorted(TRANSFER_STATUSES))}")
        evidence = string_list(transfer.get("evidence_refs"), f"{field}.evidence_refs", errors, record)
        reason = nullable_string(transfer.get("reason"), f"{field}.reason", errors, record)
        if status in {"attempted", "delivered", "acknowledged", "failed"} and not evidence:
            add_error(errors, record, f"{field}.evidence_refs", f"статус {status} требует свидетельство")
        if status in {"failed", "cancelled"} and reason is None:
            add_error(errors, record, f"{field}.reason", f"статус {status} требует причину")


def validate_passport(data: dict, record: Path, root: Path) -> list[str]:
    """Проверить один уже разобранный паспорт; функция используется также автономными тестами."""

    errors: list[str] = []
    passport = exact_object(data, "$", ROOT_KEYS, errors, record)
    if type(passport.get("schema_version")) is not int or passport.get("schema_version") != 1:
        add_error(errors, record, "$.schema_version", "должен быть целым числом 1")
    passport_id = identifier(passport.get("passport_id"), "$.passport_id", errors, record)
    supersedes = passport.get("supersedes_passport_id")
    if supersedes is not None:
        supersedes = identifier(supersedes, "$.supersedes_passport_id", errors, record)
        if supersedes is not None and supersedes == passport_id:
            add_error(errors, record, "$.supersedes_passport_id", "паспорт не может заменять сам себя")

    artifact_ids, state_ref, result_id = validate_result(passport.get("result"), root, errors, record)
    validate_provenance(passport.get("provenance"), state_ref, result_id, root, errors, record)
    check_ids = validate_checks(passport.get("verification"), artifact_ids, errors, record)
    validate_cost(passport.get("cost"), errors, record)
    validate_confidence(passport.get("confidence"), artifact_ids, check_ids, errors, record)
    recipient_ids = validate_recipients(passport.get("recipients"), errors, record)
    validate_transfers(passport.get("transfers"), artifact_ids, recipient_ids, errors, record)
    walk_refs(
        passport,
        root,
        errors,
        record,
        pinned_commit=shared_git_commit(passport),
    )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", required=True, type=Path, help="корень репозитория памяти FUM")
    parser.add_argument("passports", nargs="+", type=Path, help="один или несколько JSON-паспортов")
    args = parser.parse_args()

    root = args.repo_root.resolve()
    if not (root / ".git").exists():
        print(f"{root}: не найден корень Git-репозитория", file=sys.stderr)
        return 2

    all_errors: list[str] = []
    seen_passports: dict[str, Path] = {}
    checked = 0
    for supplied in args.passports:
        path = supplied if supplied.is_absolute() else root / supplied
        path = path.resolve()
        try:
            path.relative_to(root)
        except ValueError:
            add_error(all_errors, path, "$", "файл паспорта находится вне корня памяти FUM")
            continue
        data = load_json_object(path, all_errors)
        if data is None:
            continue
        checked += 1
        passport_id = data.get("passport_id")
        if isinstance(passport_id, str):
            previous = seen_passports.get(passport_id)
            if previous is not None:
                add_error(all_errors, path, "$.passport_id", f"уже использован в {previous}")
            else:
                seen_passports[passport_id] = path
        all_errors.extend(validate_passport(data, path, root))

    if all_errors:
        for error in all_errors:
            print(error, file=sys.stderr)
        return 1
    print(f"Проверка паспортов передаваемых результатов FUM пройдена: паспортов — {checked}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
