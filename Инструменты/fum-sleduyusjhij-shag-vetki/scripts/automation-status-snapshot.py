#!/usr/bin/env python3

import argparse
import copy
import json
import sys
import tomllib
from pathlib import Path
from typing import Any


ALLOWED_STATUSES = frozenset({"ACTIVE", "PAUSED"})
HOST_OBSERVATION_FIELDS = frozenset({"created_at", "updated_at", "version"})
MUTABLE_HOST_OBSERVATION_FIELDS = frozenset({"updated_at"})
REQUIRED_EXACT_FIELDS = frozenset(
    {"id", "kind", "name", "prompt", "rrule", "status"}
)
TARGET_FIELDS = frozenset({"target", "targetThreadId", "target_thread_id"})
OPTIONAL_FIELD_ALIASES = {
    "destination": frozenset({"destination"}),
    "notificationPolicy": frozenset(
        {"notificationPolicy", "notification_policy"}
    ),
}
ALLOWED_INPUT_FIELDS = frozenset(
    REQUIRED_EXACT_FIELDS
    | TARGET_FIELDS
    | HOST_OBSERVATION_FIELDS
    | frozenset().union(*OPTIONAL_FIELD_ALIASES.values())
)


class SnapshotError(ValueError):
    pass


def _validate_status(status: str) -> None:
    if status not in ALLOWED_STATUSES:
        raise SnapshotError("status должен быть точным ACTIVE или PAUSED")


def validate_snapshot(snapshot: Any) -> dict[str, Any]:
    if not isinstance(snapshot, dict):
        raise SnapshotError("snapshot автоматизации должен быть JSON-объектом")
    if any(not isinstance(key, str) for key in snapshot):
        raise SnapshotError("все ключи snapshot должны быть строками")

    missing = sorted(REQUIRED_EXACT_FIELDS - snapshot.keys())
    if missing:
        raise SnapshotError(
            "snapshot не содержит обязательные поля: " + ", ".join(missing)
        )
    unexpected = sorted(snapshot.keys() - ALLOWED_INPUT_FIELDS)
    if unexpected:
        raise SnapshotError(
            "snapshot содержит неподдерживаемые поля: " + ", ".join(unexpected)
        )
    target_fields = sorted(TARGET_FIELDS.intersection(snapshot))
    if len(target_fields) != 1:
        raise SnapshotError(
            "snapshot должен содержать ровно один target alias"
        )

    for field in ("id", "kind", "name", "prompt", "rrule"):
        if not isinstance(snapshot[field], str) or not snapshot[field]:
            raise SnapshotError(f"поле {field} должно быть непустой строкой")
    if not isinstance(snapshot["status"], str):
        raise SnapshotError("поле status должно быть строкой")
    _validate_status(snapshot["status"])
    _normalize_target(snapshot[target_fields[0]], target_fields[0])
    for canonical_field, aliases in OPTIONAL_FIELD_ALIASES.items():
        present = aliases.intersection(snapshot)
        if len(present) > 1:
            raise SnapshotError(
                f"snapshot содержит несколько aliases поля {canonical_field}"
            )
    return snapshot


def _normalize_target(value: Any, alias: str) -> str:
    if alias in {"targetThreadId", "target_thread_id"}:
        if not isinstance(value, str) or not value:
            raise SnapshotError(f"поле {alias} должно быть непустой строкой")
        return value
    if isinstance(value, str):
        if not value:
            raise SnapshotError("поле target должно быть непустой строкой")
        return value
    if not isinstance(value, dict):
        raise SnapshotError("поле target должно быть строкой или объектом")
    allowed_target_keys = {"threadId", "thread_id", "type"}
    unexpected = sorted(set(value) - allowed_target_keys)
    if unexpected:
        raise SnapshotError(
            "target содержит неподдерживаемые поля: " + ", ".join(unexpected)
        )
    identifiers = [key for key in ("threadId", "thread_id") if key in value]
    if len(identifiers) != 1:
        raise SnapshotError("target должен содержать ровно один thread id alias")
    if "type" in value and value["type"] != "thread":
        raise SnapshotError("target.type должен быть точным thread")
    identifier = value[identifiers[0]]
    if not isinstance(identifier, str) or not identifier:
        raise SnapshotError("target thread id должен быть непустой строкой")
    return identifier


def _optional_value(snapshot: dict[str, Any], canonical_field: str) -> tuple[bool, Any]:
    aliases = OPTIONAL_FIELD_ALIASES[canonical_field]
    present = sorted(aliases.intersection(snapshot))
    if not present:
        return False, None
    return True, copy.deepcopy(snapshot[present[0]])


def declarative_snapshot(snapshot: Any) -> dict[str, Any]:
    validated = validate_snapshot(snapshot)
    target_alias = next(iter(TARGET_FIELDS.intersection(validated)))
    normalized = {
        field: copy.deepcopy(validated[field])
        for field in REQUIRED_EXACT_FIELDS
    }
    normalized["targetThreadId"] = _normalize_target(
        validated[target_alias],
        target_alias,
    )
    for canonical_field in OPTIONAL_FIELD_ALIASES:
        present, value = _optional_value(validated, canonical_field)
        if present:
            normalized[canonical_field] = value
    return normalized


def prepare_status_update(snapshot: Any, desired_status: str) -> dict[str, Any]:
    _validate_status(desired_status)
    prepared = declarative_snapshot(snapshot)
    prepared["status"] = desired_status
    prepared["mode"] = "update"
    return prepared


def verify_status_only_diff(
    before: Any,
    after: Any,
    desired_status: str,
) -> dict[str, Any]:
    _validate_status(desired_status)
    before_validated = validate_snapshot(before)
    after_validated = validate_snapshot(after)
    before_declarative = declarative_snapshot(before_validated)
    after_declarative = declarative_snapshot(after_validated)
    if after_declarative["status"] != desired_status:
        raise SnapshotError("итоговый status не совпадает с ожидаемым")

    changed_fields: list[str] = []
    all_fields = sorted(set(before_declarative) | set(after_declarative))
    for field in all_fields:
        before_present = field in before_declarative
        after_present = field in after_declarative
        equal = (
            before_present
            and after_present
            and before_declarative[field] == after_declarative[field]
        )
        if equal:
            continue
        if field == "status":
            changed_fields.append(field)
            continue
        raise SnapshotError(
            f"exact-diff содержит запрещённое изменение поля {field}"
        )

    for field in sorted(HOST_OBSERVATION_FIELDS):
        before_present = field in before_validated
        after_present = field in after_validated
        equal = (
            before_present
            and after_present
            and before_validated[field] == after_validated[field]
        )
        if equal or (not before_present and not after_present):
            continue
        if field in MUTABLE_HOST_OBSERVATION_FIELDS:
            changed_fields.append(field)
            continue
        raise SnapshotError(
            f"exact-diff содержит запрещённое изменение поля {field}"
        )

    return {
        "state": "verified",
        "desired_status": desired_status,
        "changed_fields": changed_fields,
    }


def _reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise SnapshotError(f"JSON содержит повторный ключ {key}")
        result[key] = value
    return result


def read_snapshot(path_text: str, input_format: str) -> Any:
    try:
        if path_text == "-":
            text = sys.stdin.read()
        else:
            text = Path(path_text).read_text(encoding="utf-8")
        selected_format = input_format
        if selected_format == "auto":
            selected_format = "toml" if path_text.endswith(".toml") else "json"
        if selected_format == "toml":
            return tomllib.loads(text)
        return json.loads(
            text,
            object_pairs_hook=_reject_duplicate_keys,
            parse_constant=lambda value: (_ for _ in ()).throw(
                SnapshotError(f"JSON содержит недопустимую константу {value}")
            ),
        )
    except (OSError, UnicodeError, json.JSONDecodeError, tomllib.TOMLDecodeError) as error:
        raise SnapshotError(f"не удалось прочитать snapshot: {error}") from error


def canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
        allow_nan=False,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Механически подготовить status-update автоматизации и проверить "
            "status-only exact-diff."
        )
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser("prepare")
    prepare.add_argument("--snapshot", required=True)
    prepare.add_argument("--status", required=True, choices=sorted(ALLOWED_STATUSES))
    prepare.add_argument("--input-format", choices=("auto", "json", "toml"), default="auto")

    verify = subparsers.add_parser("verify")
    verify.add_argument("--before", required=True)
    verify.add_argument("--after", required=True)
    verify.add_argument("--status", required=True, choices=sorted(ALLOWED_STATUSES))
    verify.add_argument("--input-format", choices=("auto", "json", "toml"), default="auto")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "prepare":
            result = prepare_status_update(
                read_snapshot(args.snapshot, args.input_format),
                args.status,
            )
        else:
            result = verify_status_only_diff(
                read_snapshot(args.before, args.input_format),
                read_snapshot(args.after, args.input_format),
                args.status,
            )
    except SnapshotError as error:
        print(f"Ошибка snapshot автоматизации: {error}", file=sys.stderr)
        return 2
    print(canonical_json(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
