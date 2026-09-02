#!/usr/bin/env python3
"""Детерминированный R0-симулятор календарно-транспортного контура FUM v1."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path, PurePosixPath


BASE = Path(__file__).resolve().parent
DEFAULT_FIXTURES = BASE / "фикстуры-сценариев-v1.json"

FIXTURE_SET_KEYS = {"schema_version", "fixture_set_id", "frozen_at", "source_refs", "fixtures"}
FIXTURE_KEYS = {
    "fixture_id",
    "intent_id",
    "access",
    "operation",
    "confirmation",
    "conditions",
    "adapter",
    "private_payload",
    "expected",
}
ACCESS_KEYS = {"level", "grants"}
OPERATION_KEYS = {
    "operation_id",
    "kind",
    "adapter_id",
    "state_fingerprint",
    "terms_version",
    "amount_minor",
    "currency",
    "data_categories",
}
CONFIRMATION_KEYS = {
    "status",
    "confirmation_id",
    "operation_id",
    "state_fingerprint",
    "terms_version",
    "amount_minor",
    "currency",
    "data_categories",
    "valid_until",
}
CONDITION_KEYS = {"schedule_conflict", "route_risk"}
ADAPTER_KEYS = {"network", "outcome", "error_code"}
EXPECTED_KEYS = {"decision", "reason_code", "public_conflict"}

IDENTIFIER_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,127}$")
CURRENCY_RE = re.compile(r"^[A-Z]{3}$")

ACCESS_LEVELS = {"public", "restricted", "private", "closed"}
OPERATION_ACCESS = {
    "read_calendar": {"calendar.read.free_busy"},
    "read_schedule": {"schedule.read"},
    "plan_route": {"maps.route.model"},
    "write_calendar_event": {"calendar.write"},
    "send_notification": {"notification.send"},
    "order_taxi": {"location.disclose", "taxi.order"},
    "purchase_ticket": {"payment.authorize", "ticket.purchase"},
    "cancel_reservation": {"reservation.cancel"},
}
MODEL_ONLY_OPERATIONS = {"read_calendar", "read_schedule", "plan_route"}
CONFIRMATION_OPERATIONS = set(OPERATION_ACCESS) - MODEL_ONLY_OPERATIONS

DECISIONS = {
    "modeled",
    "blocked",
    "access_denied",
    "confirmation_required",
    "reconfirmation_required",
    "simulated_success",
    "simulated_error",
    "simulated_cancelled",
}


class ContractError(ValueError):
    """Публикационно безопасная ошибка структуры фикстуры."""


def _exact_object(value: object, field: str, keys: set[str]) -> dict:
    if not isinstance(value, dict):
        raise ContractError(f"{field}: ожидается объект")
    missing = sorted(keys - value.keys())
    unknown = sorted(value.keys() - keys)
    if missing:
        raise ContractError(f"{field}: отсутствуют поля {', '.join(missing)}")
    if unknown:
        raise ContractError(f"{field}: неизвестные поля {', '.join(unknown)}")
    return value


def _identifier(value: object, field: str) -> str:
    if not isinstance(value, str) or not IDENTIFIER_RE.fullmatch(value):
        raise ContractError(f"{field}: недопустимый идентификатор")
    return value


def _enum(value: object, field: str, allowed: set[str]) -> str:
    if not isinstance(value, str) or value not in allowed:
        raise ContractError(f"{field}: недопустимое значение")
    return value


def _nullable_string(value: object, field: str) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str) or not value:
        raise ContractError(f"{field}: ожидается непустая строка или null")
    return value


def _string_list(value: object, field: str, *, min_items: int = 0) -> list[str]:
    if not isinstance(value, list) or len(value) < min_items:
        raise ContractError(f"{field}: ожидается массив строк")
    result: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item:
            raise ContractError(f"{field}: ожидается массив непустых строк")
        result.append(item)
    if len(result) != len(set(result)):
        raise ContractError(f"{field}: повторяющиеся значения запрещены")
    return result


def _amount(value: object, field: str) -> int | None:
    if value is None:
        return None
    if not isinstance(value, int) or isinstance(value, bool) or value < 0:
        raise ContractError(f"{field}: ожидается целое число >= 0 или null")
    return value


def _instant(value: object, field: str) -> datetime:
    if not isinstance(value, str) or not value.endswith("Z"):
        raise ContractError(f"{field}: ожидается UTC date-time с Z")
    try:
        return datetime.fromisoformat(value.removesuffix("Z") + "+00:00")
    except ValueError as exc:
        raise ContractError(f"{field}: недопустимый date-time") from exc


def _publication_ref(value: object, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ContractError(f"{field}: ожидается непустой относительный путь")
    path = PurePosixPath(value)
    if value[:1] in {"/", chr(126)} or "\\" in value or ".." in path.parts or "://" in value:
        raise ContractError(f"{field}: допускается только путь внутри памяти FUM")
    return value


def validate_fixture_set(fixture_set: object) -> dict:
    root = _exact_object(fixture_set, "$", FIXTURE_SET_KEYS)
    if root["schema_version"] != 1:
        raise ContractError("schema_version: поддерживается только версия 1")
    _identifier(root["fixture_set_id"], "fixture_set_id")
    _instant(root["frozen_at"], "frozen_at")
    source_refs = _string_list(root["source_refs"], "source_refs", min_items=1)
    for index, source_ref in enumerate(source_refs):
        _publication_ref(source_ref, f"source_refs[{index}]")
    fixtures = root["fixtures"]
    if not isinstance(fixtures, list) or not fixtures:
        raise ContractError("fixtures: ожидается непустой массив")
    seen: set[str] = set()
    for index, fixture in enumerate(fixtures):
        validated = validate_fixture(fixture, field=f"fixtures[{index}]")
        fixture_id = validated["fixture_id"]
        if fixture_id in seen:
            raise ContractError("fixtures: fixture_id должен быть уникальным")
        seen.add(fixture_id)
    return root


def validate_fixture(fixture: object, *, field: str = "fixture") -> dict:
    value = _exact_object(fixture, field, FIXTURE_KEYS)
    _identifier(value["fixture_id"], f"{field}.fixture_id")
    _identifier(value["intent_id"], f"{field}.intent_id")

    access = _exact_object(value["access"], f"{field}.access", ACCESS_KEYS)
    _enum(access["level"], f"{field}.access.level", ACCESS_LEVELS)
    _string_list(access["grants"], f"{field}.access.grants")

    operation = _exact_object(value["operation"], f"{field}.operation", OPERATION_KEYS)
    _identifier(operation["operation_id"], f"{field}.operation.operation_id")
    _enum(operation["kind"], f"{field}.operation.kind", set(OPERATION_ACCESS))
    _identifier(operation["adapter_id"], f"{field}.operation.adapter_id")
    _identifier(operation["state_fingerprint"], f"{field}.operation.state_fingerprint")
    _identifier(operation["terms_version"], f"{field}.operation.terms_version")
    _amount(operation["amount_minor"], f"{field}.operation.amount_minor")
    currency = _nullable_string(operation["currency"], f"{field}.operation.currency")
    if currency is not None and not CURRENCY_RE.fullmatch(currency):
        raise ContractError(f"{field}.operation.currency: ожидается трёхбуквенный код")
    _string_list(operation["data_categories"], f"{field}.operation.data_categories")

    confirmation = _exact_object(value["confirmation"], f"{field}.confirmation", CONFIRMATION_KEYS)
    status = _enum(confirmation["status"], f"{field}.confirmation.status", {"absent", "granted"})
    for key in ("confirmation_id", "operation_id", "state_fingerprint", "terms_version", "currency", "valid_until"):
        _nullable_string(confirmation[key], f"{field}.confirmation.{key}")
    _amount(confirmation["amount_minor"], f"{field}.confirmation.amount_minor")
    _string_list(confirmation["data_categories"], f"{field}.confirmation.data_categories")
    if status == "absent":
        nullable_keys = {
            "confirmation_id",
            "operation_id",
            "state_fingerprint",
            "terms_version",
            "amount_minor",
            "currency",
            "valid_until",
        }
        if any(confirmation[key] is not None for key in nullable_keys) or confirmation["data_categories"]:
            raise ContractError(f"{field}.confirmation: отсутствующее подтверждение не содержит снимок")
    else:
        required_values = ("confirmation_id", "operation_id", "state_fingerprint", "terms_version", "valid_until")
        if any(confirmation[key] is None for key in required_values):
            raise ContractError(f"{field}.confirmation: подтверждённый снимок неполон")
        _instant(confirmation["valid_until"], f"{field}.confirmation.valid_until")

    conditions = _exact_object(value["conditions"], f"{field}.conditions", CONDITION_KEYS)
    _enum(conditions["schedule_conflict"], f"{field}.conditions.schedule_conflict", {"none", "private"})
    _enum(conditions["route_risk"], f"{field}.conditions.route_risk", {"acceptable", "unknown", "unsafe"})

    adapter = _exact_object(value["adapter"], f"{field}.adapter", ADAPTER_KEYS)
    _enum(adapter["network"], f"{field}.adapter.network", {"available", "unavailable"})
    _enum(adapter["outcome"], f"{field}.adapter.outcome", {"success", "error", "cancelled", "unknown"})
    _nullable_string(adapter["error_code"], f"{field}.adapter.error_code")

    private_payload = value["private_payload"]
    if not isinstance(private_payload, dict):
        raise ContractError(f"{field}.private_payload: ожидается объект")
    for key, private_value in private_payload.items():
        if not isinstance(key, str) or not key or not isinstance(private_value, str):
            raise ContractError(f"{field}.private_payload: ожидаются строковые пары")
        if not private_value.startswith("SYNTHETIC_PRIVATE_"):
            raise ContractError(f"{field}.private_payload: допускаются только синтетические значения")

    expected = _exact_object(value["expected"], f"{field}.expected", EXPECTED_KEYS)
    _enum(expected["decision"], f"{field}.expected.decision", DECISIONS)
    if not isinstance(expected["reason_code"], str) or not expected["reason_code"]:
        raise ContractError(f"{field}.expected.reason_code: ожидается непустая строка")
    _nullable_string(expected["public_conflict"], f"{field}.expected.public_conflict")
    return value


def load_fixture_set(path: Path = DEFAULT_FIXTURES) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ContractError("fixture_set: не удалось прочитать JSON") from exc
    return validate_fixture_set(value)


def _event(index: int, event_type: str, code: str, subject_ref: str) -> dict:
    return {"index": index, "type": event_type, "code": code, "subject_ref": subject_ref}


def _confirmation_result(operation: dict, confirmation: dict, frozen_at: str) -> tuple[bool, str]:
    if confirmation["status"] != "granted":
        return False, "explicit_confirmation_missing"
    comparable_fields = (
        "operation_id",
        "state_fingerprint",
        "terms_version",
        "amount_minor",
        "currency",
    )
    if any(confirmation[field] != operation[field] for field in comparable_fields):
        return False, "confirmation_snapshot_mismatch"
    if sorted(confirmation["data_categories"]) != sorted(operation["data_categories"]):
        return False, "confirmation_snapshot_mismatch"
    if _instant(confirmation["valid_until"], "confirmation.valid_until") < _instant(frozen_at, "frozen_at"):
        return False, "confirmation_expired"
    return True, "confirmation_snapshot_matched"


def _fixture_digest(fixture: dict) -> str:
    payload = json.dumps(fixture, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return "sha256:" + hashlib.sha256(payload).hexdigest()


def simulate_fixture(fixture: object, fixture_set: object) -> dict:
    root = validate_fixture_set(fixture_set)
    value = validate_fixture(fixture)
    operation = value["operation"]
    access = value["access"]
    confirmation = value["confirmation"]
    conditions = value["conditions"]
    adapter = value["adapter"]

    trace = [_event(0, "intent", "received", value["intent_id"])]
    required_access = sorted(OPERATION_ACCESS[operation["kind"]])
    missing_access = sorted(set(required_access) - set(access["grants"]))
    trace.append(
        _event(
            len(trace),
            "access_check",
            "missing" if missing_access else "granted",
            operation["operation_id"],
        )
    )

    public_conflict = None
    adapter_calls = 0
    confirmation_ref = None

    if missing_access:
        decision, reason_code = "access_denied", "required_access_missing"
    else:
        if conditions["schedule_conflict"] == "private":
            guard_code = "private_schedule_conflict"
            public_conflict = "busy"
        elif conditions["route_risk"] in {"unknown", "unsafe"}:
            guard_code = f"route_risk_{conditions['route_risk']}"
        else:
            guard_code = "passed"
        trace.append(_event(len(trace), "guard_check", guard_code, operation["operation_id"]))

        if guard_code != "passed":
            decision, reason_code = "blocked", guard_code
        else:
            confirmation_ok = True
            confirmation_code = "not_required"
            if operation["kind"] in CONFIRMATION_OPERATIONS:
                confirmation_ok, confirmation_code = _confirmation_result(
                    operation, confirmation, root["frozen_at"]
                )
                trace.append(
                    _event(
                        len(trace),
                        "confirmation_check",
                        confirmation_code,
                        operation["operation_id"],
                    )
                )
                confirmation_ref = confirmation["confirmation_id"]

            if not confirmation_ok:
                if confirmation_code == "explicit_confirmation_missing":
                    decision, reason_code = "confirmation_required", confirmation_code
                else:
                    decision, reason_code = "reconfirmation_required", confirmation_code
            else:
                adapter_calls = 1
                adapter_code = (
                    "network_unavailable" if adapter["network"] == "unavailable" else adapter["outcome"]
                )
                trace.append(
                    _event(len(trace), "adapter_fixture", adapter_code, operation["adapter_id"])
                )
                if adapter["network"] == "unavailable":
                    decision, reason_code = "simulated_error", "network_unavailable"
                elif adapter["outcome"] == "error":
                    decision, reason_code = "simulated_error", "adapter_error"
                elif adapter["outcome"] == "unknown":
                    decision, reason_code = "simulated_error", "adapter_outcome_unknown"
                elif operation["kind"] == "cancel_reservation" and adapter["outcome"] in {
                    "cancelled",
                    "success",
                }:
                    decision, reason_code = "simulated_cancelled", "adapter_fixture_cancelled"
                elif adapter["outcome"] == "cancelled":
                    decision, reason_code = "simulated_error", "unexpected_adapter_outcome"
                elif operation["kind"] in MODEL_ONLY_OPERATIONS:
                    decision, reason_code = "modeled", "model_completed"
                else:
                    decision, reason_code = "simulated_success", "adapter_fixture_success"

    trace.append(_event(len(trace), "decision", reason_code, operation["operation_id"]))
    report = {
        "schema_version": 1,
        "fixture_set_id": root["fixture_set_id"],
        "frozen_at": root["frozen_at"],
        "simulation_only": True,
        "external_effect": "none",
        "external_effects": [],
        "decision": decision,
        "reason_code": reason_code,
        "public_conflict": public_conflict,
        "simulated_adapter_calls": adapter_calls,
        "access": {
            "level": access["level"],
            "required_grants": required_access,
            "missing_grants": missing_access,
        },
        "operation": {
            "operation_id": operation["operation_id"],
            "kind": operation["kind"],
            "adapter_id": operation["adapter_id"],
            "state_fingerprint": operation["state_fingerprint"],
        },
        "confirmation_ref": confirmation_ref,
        "provenance": {
            "fixture_id": value["fixture_id"],
            "intent_id": value["intent_id"],
            "source_refs": list(root["source_refs"]),
            "fixture_sha256": _fixture_digest(value),
        },
        "retained": {
            "operation_id": operation["operation_id"],
            "operation_kind": operation["kind"],
            "adapter_id": operation["adapter_id"],
            "state_fingerprint": operation["state_fingerprint"],
            "decision": decision,
            "reason_code": reason_code,
        },
        "redacted_fields": sorted(f"private_payload.{key}" for key in value["private_payload"]),
        "trace": trace,
    }
    return report


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Выполнить локальные синтетические фикстуры без внешних эффектов."
    )
    parser.add_argument("--fixtures", type=Path, default=DEFAULT_FIXTURES)
    parser.add_argument("--fixture-id")
    parser.add_argument("--pretty", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(sys.argv[1:] if argv is None else argv)
    try:
        fixture_set = load_fixture_set(args.fixtures)
        fixtures = fixture_set["fixtures"]
        if args.fixture_id is not None:
            fixtures = [fixture for fixture in fixtures if fixture["fixture_id"] == args.fixture_id]
            if not fixtures:
                raise ContractError("fixture_id: фикстура не найдена")
        reports = [simulate_fixture(fixture, fixture_set) for fixture in fixtures]
    except ContractError as exc:
        print(f"Ошибка контракта: {exc}", file=sys.stderr)
        return 2
    output: object = reports[0] if args.fixture_id is not None else reports
    print(
        json.dumps(
            output,
            ensure_ascii=False,
            indent=2 if args.pretty else None,
            sort_keys=True,
            separators=None if args.pretty else (",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
