#!/usr/bin/env python3
"""Автономная проверка трассы агентского цикла FUM версии 3."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


class ContractError(ValueError):
    """Трасса не удовлетворяет структурному или межсобытийному контракту."""


TERMINAL_EPISODE_STATES = {
    "completed",
    "failed",
    "stopped",
    "cancelled",
    "unresolved_conflict",
    "needs_input",
}
MODEL_SELECTION_STATES = {"selected_in_model", "recommended", "selected_by_user"}
EXTERNAL_STAGES = {
    "transition_user_confirmed",
    "authorized",
    "preflight_passed",
    "executed",
    "observed",
}
EXTERNAL_EVIDENCE_REQUIREMENTS = {
    "authorized": ("authority_decision", "allowed"),
    "preflight_passed": ("current_state_preflight", "passed"),
    "executed": ("execution_receipt", "succeeded"),
    "observed": ("result_observation", "observed"),
}


def _object_without_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ContractError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_trace(path: Path | str) -> list[dict[str, Any]]:
    """Прочитать UTF-8 JSONL без обращения к сети или внешним сервисам."""

    source = Path(path)
    try:
        raw = source.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise ContractError(f"cannot read trace {source}: {error}") from error
    if raw.startswith("\ufeff"):
        raise ContractError(f"trace {source} must not contain an UTF-8 BOM")

    records: list[dict[str, Any]] = []
    for line_number, line in enumerate(raw.splitlines(), start=1):
        if not line.strip():
            raise ContractError(f"trace {source}:{line_number}: blank JSONL line")
        try:
            record = json.loads(line, object_pairs_hook=_object_without_duplicate_keys)
        except (json.JSONDecodeError, ContractError) as error:
            raise ContractError(f"trace {source}:{line_number}: invalid JSON: {error}") from error
        if not isinstance(record, dict):
            raise ContractError(f"trace {source}:{line_number}: record must be an object")
        records.append(record)
    if not records:
        raise ContractError(f"trace {source}: at least one record is required")
    return records


def _json_type_matches(value: Any, expected: str) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if expected == "boolean":
        return isinstance(value, bool)
    if expected == "null":
        return value is None
    return False


def _resolve_ref(root: Mapping[str, Any], ref: str) -> Any:
    if not ref.startswith("#/"):
        raise ContractError(f"schema: only local JSON pointers are supported: {ref}")
    node: Any = root
    pointer_escape = chr(126)
    for token in ref[2:].split("/"):
        token = token.replace(f"{pointer_escape}1", "/").replace(
            f"{pointer_escape}0", pointer_escape
        )
        if not isinstance(node, Mapping) or token not in node:
            raise ContractError(f"schema: unresolved reference {ref}")
        node = node[token]
    return node


def _schema_error(path: str, message: str) -> ContractError:
    return ContractError(f"schema violation at {path}: {message}")


def _validate_schema_value(
    value: Any,
    rule: Any,
    root: Mapping[str, Any],
    path: str,
) -> None:
    """Небольшой локальный интерпретатор используемого подмножества JSON Schema."""

    if isinstance(rule, bool):
        if not rule:
            raise _schema_error(path, "value is forbidden")
        return
    if not isinstance(rule, Mapping):
        raise ContractError(f"schema: rule at {path} must be an object or boolean")

    if "$ref" in rule:
        _validate_schema_value(value, _resolve_ref(root, rule["$ref"]), root, path)

    for nested in rule.get("allOf", []):
        _validate_schema_value(value, nested, root, path)

    if "anyOf" in rule:
        successes = 0
        for nested in rule["anyOf"]:
            try:
                _validate_schema_value(value, nested, root, path)
            except ContractError:
                continue
            successes += 1
        if successes == 0:
            raise _schema_error(path, "anyOf has no matching schema")

    if "oneOf" in rule:
        successes = 0
        for nested in rule["oneOf"]:
            try:
                _validate_schema_value(value, nested, root, path)
            except ContractError:
                continue
            successes += 1
        if successes != 1:
            raise _schema_error(path, f"oneOf expected one matching schema, got {successes}")

    if "not" in rule:
        try:
            _validate_schema_value(value, rule["not"], root, path)
        except ContractError:
            pass
        else:
            raise _schema_error(path, "value matches a forbidden schema")

    if "if" in rule:
        try:
            _validate_schema_value(value, rule["if"], root, path)
        except ContractError:
            branch = rule.get("else")
        else:
            branch = rule.get("then")
        if branch is not None:
            _validate_schema_value(value, branch, root, path)

    expected_type = rule.get("type")
    if expected_type is not None:
        expected_types = [expected_type] if isinstance(expected_type, str) else expected_type
        if not isinstance(expected_types, list) or not all(
            isinstance(item, str) for item in expected_types
        ):
            raise ContractError(f"schema: invalid type declaration at {path}")
        if not any(_json_type_matches(value, item) for item in expected_types):
            raise _schema_error(path, f"expected type {expected_types}, got {type(value).__name__}")

    if "const" in rule and value != rule["const"]:
        raise _schema_error(path, f"expected const {rule['const']!r}")
    if "enum" in rule and value not in rule["enum"]:
        raise _schema_error(path, f"value {value!r} is outside enum")

    if isinstance(value, Mapping):
        required = rule.get("required", [])
        for key in required:
            if key not in value:
                raise _schema_error(path, f"required property {key!r} is missing")
        properties = rule.get("properties", {})
        pattern_properties = rule.get("patternProperties", {})
        for key, child in value.items():
            child_path = f"{path}.{key}"
            if key in properties:
                _validate_schema_value(child, properties[key], root, child_path)
                continue
            matched = False
            for pattern, nested in pattern_properties.items():
                if re.search(pattern, key):
                    _validate_schema_value(child, nested, root, child_path)
                    matched = True
            if matched:
                continue
            additional = rule.get("additionalProperties", True)
            if additional is False:
                raise _schema_error(path, f"unknown property {key!r}")
            if isinstance(additional, Mapping):
                _validate_schema_value(child, additional, root, child_path)
        if "minProperties" in rule and len(value) < rule["minProperties"]:
            raise _schema_error(path, "object has too few properties")
        if "maxProperties" in rule and len(value) > rule["maxProperties"]:
            raise _schema_error(path, "object has too many properties")

    if isinstance(value, list):
        if "minItems" in rule and len(value) < rule["minItems"]:
            raise _schema_error(path, "array has too few items")
        if "maxItems" in rule and len(value) > rule["maxItems"]:
            raise _schema_error(path, "array has too many items")
        if rule.get("uniqueItems"):
            encoded = [json.dumps(item, ensure_ascii=False, sort_keys=True) for item in value]
            if len(encoded) != len(set(encoded)):
                raise _schema_error(path, "array items must be unique")
        if "items" in rule:
            for index, child in enumerate(value):
                _validate_schema_value(child, rule["items"], root, f"{path}[{index}]")

    if isinstance(value, str):
        if "minLength" in rule and len(value) < rule["minLength"]:
            raise _schema_error(path, "string is too short")
        if "maxLength" in rule and len(value) > rule["maxLength"]:
            raise _schema_error(path, "string is too long")
        if "pattern" in rule and re.search(rule["pattern"], value) is None:
            raise _schema_error(path, f"string does not match pattern {rule['pattern']!r}")

    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if isinstance(value, float) and not math.isfinite(value):
            raise _schema_error(path, "number must be finite")
        if "minimum" in rule and value < rule["minimum"]:
            raise _schema_error(path, f"number is below minimum {rule['minimum']}")
        if "maximum" in rule and value > rule["maximum"]:
            raise _schema_error(path, f"number is above maximum {rule['maximum']}")
        if "exclusiveMinimum" in rule and value <= rule["exclusiveMinimum"]:
            raise _schema_error(path, f"number must exceed {rule['exclusiveMinimum']}")
        if "exclusiveMaximum" in rule and value >= rule["exclusiveMaximum"]:
            raise _schema_error(path, f"number must be below {rule['exclusiveMaximum']}")


def _payload(record: Mapping[str, Any], kind: str) -> Mapping[str, Any]:
    if record.get("kind") != kind:
        raise ContractError(f"internal validator error: expected {kind}")
    payload = record.get("payload")
    if not isinstance(payload, Mapping):
        raise ContractError(f"schema violation: {kind} payload must be an object")
    return payload


def _events(records: Sequence[Mapping[str, Any]], kind: str) -> list[Mapping[str, Any]]:
    return [record for record in records if record.get("kind") == kind]


def _required(mapping: Mapping[str, Any], key: str, context: str) -> Any:
    if key not in mapping:
        raise ContractError(f"{context}: required property {key!r} is missing")
    return mapping[key]


def _find_forbidden_material(value: Any, path: str = "record") -> None:
    if isinstance(value, Mapping):
        for key, child in value.items():
            lowered = key.casefold()
            if lowered in {
                "chain_of_thought",
                "hidden_reasoning",
                "private_reasoning",
                "reasoning_tokens",
                "provider_id",
                "network_endpoint",
            }:
                if "provider" in lowered or "network" in lowered:
                    raise ContractError(f"network/provider field {path}.{key} is forbidden")
                raise ContractError(f"unknown hidden reasoning field {path}.{key} is forbidden")
            _find_forbidden_material(child, f"{path}.{key}")
        return
    if isinstance(value, list):
        for index, child in enumerate(value):
            _find_forbidden_material(child, f"{path}[{index}]")
        return
    if isinstance(value, str):
        lowered = value.casefold()
        secret_markers = (
            "fixture-secret",
            "token=",
            "api_key=",
            "api-key=",
            "password=",
            "begin private key",
        )
        if any(marker in lowered for marker in secret_markers):
            raise ContractError(f"secret-like material is forbidden at {path}")


def _validate_record_envelope(records: Sequence[Mapping[str, Any]]) -> None:
    if not isinstance(records, Sequence) or isinstance(records, (str, bytes)) or not records:
        raise ContractError("trace must be a non-empty sequence of records")
    identifiers: set[str] = set()
    trace_ids: set[str] = set()
    terminal_seq: int | None = None
    for expected_seq, record in enumerate(records, start=1):
        if not isinstance(record, Mapping):
            raise ContractError(f"schema violation: record {expected_seq} must be an object")
        if record.get("seq") != expected_seq:
            raise ContractError(
                f"record sequence must be contiguous: expected {expected_seq}, got {record.get('seq')!r}"
            )
        if record.get("schema_version") != 3:
            raise ContractError(f"schema version 3 is required at sequence {expected_seq}")
        trace_id = record.get("trace_id")
        if isinstance(trace_id, str):
            trace_ids.add(trace_id)
        event_id = record.get("event_id")
        if isinstance(event_id, str):
            if event_id in identifiers:
                raise ContractError(f"duplicate event_id {event_id!r}")
            identifiers.add(event_id)
        if terminal_seq is not None:
            raise ContractError(
                f"record {expected_seq} appears after terminal episode state at {terminal_seq}; "
                "terminal state must be final"
            )
        if record.get("kind") == "episode_state":
            payload = record.get("payload")
            if isinstance(payload, Mapping) and payload.get("state") in TERMINAL_EPISODE_STATES:
                terminal_seq = expected_seq
        _find_forbidden_material(record, f"record[{expected_seq}]")
    if len(trace_ids) != 1:
        raise ContractError("all records must preserve the same trace_id; mixed traces are forbidden")


def _validate_storage_policy(records: Sequence[Mapping[str, Any]]) -> None:
    tasks = _events(records, "task")
    if len(tasks) != 1:
        raise ContractError("trace requires exactly one task event")
    task = _payload(tasks[0], "task")
    policy = _required(task, "storage_policy", "task")
    if not isinstance(policy, Mapping):
        raise ContractError("task.storage_policy must be an independently specified object")
    allowed = _required(policy, "allowed_record_classes", "storage_policy")
    if not isinstance(allowed, list) or "candidate" not in allowed:
        raise ContractError("storage policy must independently allow the candidate record class")
    if len(allowed) != len(set(allowed)):
        raise ContractError("storage policy record classes must be unique")

    runtime_policy = _required(task, "model_runtime_policy", "task")
    if not isinstance(runtime_policy, Mapping):
        raise ContractError("model_runtime_policy must be an object")
    if runtime_policy.get("mode") != "deterministic_local_fixture":
        raise ContractError(
            "model_runtime_policy.mode must be deterministic_local_fixture"
        )
    if runtime_policy.get("reasoning_recording") != "summaries_only":
        raise ContractError(
            "model_runtime_policy.reasoning_recording must be summaries_only"
        )
    capability_flags = (
        "network_access",
        "secret_access",
        "live_model",
        "external_services",
        "publication",
        "physical_action",
    )
    for key in capability_flags:
        if runtime_policy.get(key) is not False:
            raise ContractError(
                f"offline model_runtime_policy capability {key} must be strictly false"
            )

    actual_branch_count = len(_events(records, "model_branch"))
    max_branches = runtime_policy.get("max_branches")
    if (
        not isinstance(max_branches, int)
        or isinstance(max_branches, bool)
        or max_branches < actual_branch_count
    ):
        raise ContractError(
            "model_runtime_policy.max_branches is below the actual branch count"
        )
    episode_states = _events(records, "episode_state")
    if not episode_states:
        raise ContractError("runtime policy requires an initial episode_state")
    initial_episode = _payload(episode_states[0], "episode_state")
    episode_budget = _required(initial_episode, "budget", "initial episode_state")
    initial_budget = runtime_policy.get("initial_budget")
    if (
        not isinstance(episode_budget, Mapping)
        or initial_budget != episode_budget.get("initial")
    ):
        raise ContractError(
            "model_runtime_policy.initial_budget must equal the initial episode budget"
        )

    policy_id = policy.get("policy_id", policy.get("id"))
    for record in records:
        payload = record.get("payload")
        if not isinstance(payload, Mapping):
            continue
        reference = payload.get("storage_policy_id", payload.get("storage_policy_ref"))
        record_class = payload.get("record_class", payload.get("storage_class"))
        if reference is not None and policy_id is not None and reference != policy_id:
            raise ContractError("record refers to a different independently specified storage policy")
        if record_class is not None and record_class not in allowed:
            raise ContractError(
                f"storage policy does not allow record class {record_class!r}"
            )


def _validate_episode_identity(records: Sequence[Mapping[str, Any]]) -> None:
    tasks = _events(records, "task")
    if len(tasks) != 1:
        raise ContractError("trace requires exactly one task event")
    episode_id = _required(_payload(tasks[0], "task"), "episode_id", "task")
    for kind in (
        "episode_state",
        "model_checkpoint",
        "model_branch",
        "episode_checkpoint",
    ):
        for record in _events(records, kind):
            payload_episode_id = _required(_payload(record, kind), "episode_id", kind)
            if payload_episode_id != episode_id:
                raise ContractError(
                    f"episode_id must remain the same across one episode; drift in {kind}"
                )


def _validate_model_branches(
    records: Sequence[Mapping[str, Any]], scenario: str
) -> tuple[set[str], list[Mapping[str, Any]]]:
    checkpoint_records = _events(records, "model_checkpoint")
    checkpoints = {
        record["seq"]: _payload(record, "model_checkpoint")
        for record in checkpoint_records
    }
    branches = _events(records, "model_branch")
    steps = _events(records, "model_step")
    checks = _events(records, "branch_check")
    selections = _events(records, "branch_selection")

    if not branches:
        raise ContractError("at least one model branch is required")
    branch_ids: set[str] = set()
    branch_ancestors: dict[str, int] = {}
    branch_consumed: dict[str, int] = {}
    common_ancestors: set[int] = set()
    differences: set[str] = set()
    for record in branches:
        payload = _payload(record, "model_branch")
        branch_id = _required(payload, "branch_id", "model_branch")
        if not isinstance(branch_id, str) or not branch_id or branch_id in branch_ids:
            raise ContractError("model branch IDs must be non-empty and unique")
        branch_ids.add(branch_id)
        ancestor = _required(payload, "common_checkpoint_seq", "model_branch")
        common_ancestors.add(ancestor)
        if ancestor not in checkpoints or ancestor >= record["seq"]:
            raise ContractError("model branch has no valid common checkpoint ancestor")
        if payload.get("parent_checkpoint_id") != checkpoints[ancestor].get("checkpoint_id"):
            raise ContractError(
                "model_branch parent_checkpoint_id must name the exact common checkpoint"
            )
        branch_ancestors[str(branch_id)] = ancestor
        difference = _required(payload, "difference", "model_branch")
        if not isinstance(difference, str) or not difference.strip():
            raise ContractError("model branch difference must be explicit")
        differences.add(difference)
        budget = _required(payload, "budget", "model_branch")
        if not isinstance(budget, Mapping):
            raise ContractError("model_branch budget must be an object")
        allocated = _required(budget, "allocated", "model_branch budget")
        if not isinstance(allocated, int) or isinstance(allocated, bool) or allocated <= 0:
            raise ContractError("model_branch budget.allocated must be a positive integer")
        consumed = _required(budget, "consumed", "model_branch budget")
        remaining = _required(budget, "remaining", "model_branch budget")
        if not all(
            isinstance(value, int) and not isinstance(value, bool) and value >= 0
            for value in (consumed, remaining)
        ) or consumed + remaining != allocated:
            raise ContractError(
                "model_branch budget must be finite and satisfy allocated = consumed + remaining"
            )
        branch_consumed[str(branch_id)] = consumed

    if len(common_ancestors) != 1:
        raise ContractError("model branches must share one exact common checkpoint ancestor")
    if len(branches) > 1 and len(differences) != len(branches):
        raise ContractError("model branches must have distinct declared differences")

    step_branches: set[str] = set()
    actual_costs = {branch_id: 0 for branch_id in branch_ids}
    for record in steps:
        payload = _payload(record, "model_step")
        if payload.get("effect_scope") != "model_only":
            raise ContractError("model_step effect_scope must remain model_only")
        branch_id = _required(payload, "branch_id", "model_step")
        if branch_id not in branch_ids:
            raise ContractError("model_step refers to an unknown model branch")
        if payload.get("parent_checkpoint_seq") != branch_ancestors[branch_id]:
            raise ContractError(
                "model_step parent_checkpoint_seq must point to the branch's exact model checkpoint"
            )
        cost = _required(payload, "budget_cost", "model_step")
        if not isinstance(cost, int) or isinstance(cost, bool) or cost < 0:
            raise ContractError("model_step budget_cost must be a non-negative integer")
        actual_costs[branch_id] += cost
        step_branches.add(branch_id)

    steps_by_seq = {record["seq"]: record for record in steps}
    checked_branches: set[str] = set()
    for record in checks:
        payload = _payload(record, "branch_check")
        branch_id = _required(payload, "branch_id", "branch_check")
        if branch_id not in branch_ids:
            raise ContractError("branch_check refers to an unknown model branch")
        provenance = _required(payload, "provenance_seqs", "branch_check")
        if not isinstance(provenance, list) or not provenance:
            raise ContractError("branch_check requires non-empty result provenance")
        if not all(isinstance(seq, int) and 0 < seq < record["seq"] for seq in provenance):
            raise ContractError("branch_check provenance must refer to earlier records")
        subject_seq = _required(payload, "subject_step_seq", "branch_check")
        subject = steps_by_seq.get(subject_seq)
        if subject is None or _payload(subject, "model_step").get("branch_id") != branch_id:
            raise ContractError("branch_check must check a model_step from the same branch")
        if subject_seq not in provenance:
            raise ContractError("branch_check provenance must include its subject model_step")
        cost = _required(payload, "budget_cost", "branch_check")
        if not isinstance(cost, int) or isinstance(cost, bool) or cost < 0:
            raise ContractError("branch_check budget_cost must be a non-negative integer")
        actual_costs[branch_id] += cost
        checked_branches.add(branch_id)

    if step_branches != branch_ids:
        raise ContractError("each model branch requires a model-only step")
    if checked_branches != branch_ids:
        raise ContractError("each model branch requires a separate check with provenance")
    for branch_id in sorted(branch_ids):
        if actual_costs[branch_id] != branch_consumed[branch_id]:
            raise ContractError(
                f"branch {branch_id!r} budget_cost sum {actual_costs[branch_id]} "
                f"does not equal branch budget consumed {branch_consumed[branch_id]}"
            )

    if not selections:
        raise ContractError("at least one branch_selection is required")
    checks_by_seq = {
        record["seq"]: _payload(record, "branch_check") for record in checks
    }
    for record in selections:
        payload = _payload(record, "branch_selection")
        status = _required(payload, "status", "branch_selection")
        if status not in MODEL_SELECTION_STATES:
            raise ContractError(f"branch selection status {status!r} is outside the allowed enum")
        if payload.get("canonical_state") != "candidate_only":
            raise ContractError("model branch selection cannot be promoted to canonical state")
        selected = _required(payload, "selected_branch_id", "branch_selection")
        if selected not in branch_ids:
            raise ContractError("branch_selection refers to an unknown branch")
        considered = _required(payload, "considered_branch_ids", "branch_selection")
        if not isinstance(considered, list) or selected not in considered:
            raise ContractError("branch_selection must include the selected branch among considered branches")
        if any(branch_id not in branch_ids for branch_id in considered):
            raise ContractError("branch_selection considered an unknown branch")
        evidence = _required(payload, "evidence_seqs", "branch_selection")
        if not isinstance(evidence, list) or not all(
            isinstance(seq, int) and 0 < seq < record["seq"] for seq in evidence
        ):
            raise ContractError(
                "branch_selection evidence must refer only to earlier records"
            )
        checked_in_evidence = {
            checks_by_seq[seq].get("branch_id")
            for seq in evidence
            if seq in checks_by_seq
        }
        if any(branch_id not in checked_in_evidence for branch_id in considered):
            raise ContractError(
                "branch_selection evidence must include a separate branch_check "
                "for every considered branch"
            )
        untested = _required(payload, "untested_branch_ids", "branch_selection")
        if payload.get("ambiguity_resolved") is True and untested:
            raise ContractError(
                "ambiguity_resolved cannot be true while untested_branch_ids is non-empty"
            )

    if scenario == "nonblocking_branching_v3" and len(branches) != 2:
        raise ContractError("nonblocking branching scenario requires exactly two model branches")
    if scenario == "single_branch_limited_budget_v3":
        if len(branches) != 1:
            raise ContractError("single-branch limited-budget scenario requires one branch")
        if not _events(records, "episode_checkpoint"):
            raise ContractError(
                "single-branch scenario requires an episode_checkpoint"
            )
        episode_states = _events(records, "episode_state")
        final_episode = _payload(episode_states[-1], "episode_state")
        if final_episode.get("state") != "needs_input":
            raise ContractError(
                "single-branch scenario final state must be needs_input"
            )
        final_budget = final_episode.get("budget")
        if not isinstance(final_budget, Mapping) or final_budget.get("remaining") != 0:
            raise ContractError(
                "single-branch scenario requires exhausted budget with remaining zero"
            )
        selection = _payload(selections[-1], "branch_selection")
        considered = selection.get("considered_branch_ids")
        untested = selection.get("untested_branch_ids")
        if not isinstance(considered, list) or len(considered) != 1:
            raise ContractError("single branch scenario must consider exactly one branch")
        if not isinstance(untested, list) or not untested:
            raise ContractError("single branch scenario must preserve untested alternatives")
        if selection.get("ambiguity_resolved") is not False:
            raise ContractError("one branch or a single attempt cannot resolve ambiguity")

    return branch_ids, selections


def _validate_transition(
    records: Sequence[Mapping[str, Any]],
    branch_ids: set[str],
    scenario: str,
) -> None:
    pending_records = _events(records, "pending_transition")
    if len(pending_records) != 1:
        raise ContractError("trace requires exactly one pending_transition")
    pending = _payload(pending_records[0], "pending_transition")
    pending_seq = pending_records[0]["seq"]
    if pending.get("status") != "awaiting_confirmation":
        raise ContractError("pending transition must remain awaiting_confirmation")
    transition_id = pending.get("transition_id", pending.get("object_id"))
    transition_version = pending.get("transition_version", pending.get("version"))
    if not isinstance(transition_id, str) or not transition_id:
        raise ContractError("pending transition requires an exact object/transition ID")
    if not isinstance(transition_version, int) or isinstance(transition_version, bool):
        raise ContractError("pending transition requires an exact integer version")
    if not any(key in pending for key in ("expected_effect", "effect")):
        raise ContractError("pending transition requires its expected effect")
    task = _payload(_events(records, "task")[0], "task")
    acceptance_policy_ref = task["storage_policy"]["acceptance_policy_ref"]

    for kind in ("model_checkpoint", "episode_checkpoint"):
        for record in _events(records, kind):
            payload = _payload(record, kind)
            if (
                payload.get("transition_id") != transition_id
                or payload.get("transition_version") != transition_version
            ):
                raise ContractError(
                    f"{kind} must preserve the exact pending transition ID and version"
                )

    stage_records = _events(records, "transition_stage")
    stages = [_payload(record, "transition_stage").get("stage") for record in stage_records]
    action_records = _events(records, "transition_action")
    for record in [*stage_records, *action_records]:
        payload = _payload(record, str(record["kind"]))
        if (
            payload.get("transition_id") != transition_id
            or payload.get("transition_version") != transition_version
        ):
            raise ContractError(
                f"{record['kind']} must preserve the exact transition ID and version"
            )
    external_stage_names = [
        *stages,
        *[_payload(record, "transition_action").get("stage") for record in action_records],
    ]
    if "executed" in external_stage_names:
        missing = [
            name
            for name in ("transition_user_confirmed", "authorized", "preflight_passed")
            if name not in external_stage_names
        ]
        if missing:
            raise ContractError(
                "execution requires independent confirmation, authorization, and preflight evidence; "
                f"missing {', '.join(missing)}"
            )
    if not stages or stages[0] != "closed":
        raise ContractError("pending transition requires an initial closed stage")

    responses = _events(records, "transition_response")
    current_confirmations: list[Mapping[str, Any]] = []
    stale_confirmations: list[Mapping[str, Any]] = []
    refusals: list[Mapping[str, Any]] = []
    revocations: list[Mapping[str, Any]] = []
    checkpoint_by_seq = {
        record["seq"]: _payload(record, "episode_checkpoint")
        for record in _events(records, "episode_checkpoint")
    }
    for record in responses:
        payload = _payload(record, "transition_response")
        response = payload.get("response")
        matching = payload.get("matching")
        chosen = payload.get("chosen_branch_id")
        source_event = _required(payload, "source_event", "transition_response")
        if not isinstance(source_event, Mapping):
            raise ContractError("transition_response.source_event must be an object")
        ingress = _required(
            source_event, "ingress_authorization", "transition_response.source_event"
        )
        if not isinstance(ingress, Mapping):
            raise ContractError("ingress_authorization must be an object")
        if ingress.get("status") != "allowed":
            raise ContractError("ingress authorization status must be allowed")
        if ingress.get("purpose") != "transition_response":
            raise ContractError(
                "ingress authorization purpose must be transition_response"
            )
        if ingress.get("policy_ref") != acceptance_policy_ref:
            raise ContractError(
                "ingress authorization policy_ref must equal the task acceptance_policy_ref"
            )
        if response not in {"confirm", "refuse", "revoke"}:
            raise ContractError("transition response must distinguish confirm, refuse, and revoke")
        checkpoint = payload.get("checkpoint_seq")
        if checkpoint not in checkpoint_by_seq or checkpoint >= record["seq"]:
            raise ContractError("transition response must arrive at a saved safe checkpoint")
        checkpoint_payload = checkpoint_by_seq[checkpoint]
        if checkpoint_payload.get("safe_for_user_signal") is not True:
            raise ContractError("transition response checkpoint must be safe for a user signal")
        exact = (
            payload.get("transition_id", payload.get("object_id")) == transition_id
            and payload.get("transition_version", payload.get("version")) == transition_version
        )
        if matching == "current" and not exact:
            raise ContractError("current confirmation does not match the exact transition and version")
        if response in {"refuse", "revoke"} and matching != "current":
            raise ContractError(f"{response} must match the current transition")
        if matching == "stale":
            if exact:
                raise ContractError("stale transition response unexpectedly matches the current version")
            if chosen != "none":
                raise ContractError("stale response chosen_branch_id must be none")
            if response != "confirm":
                raise ContractError("stale confirmation scenario requires response confirm")
            stale_confirmations.append(record)
        elif matching != "current":
            raise ContractError("transition response matching must be current or stale")
        if response == "confirm" and matching == "current":
            if chosen not in branch_ids:
                raise ContractError("current confirmation must choose a saved model alternative")
            if chosen not in checkpoint_payload.get("saved_branch_ids", []):
                raise ContractError(
                    "current confirmation must choose an alternative saved at its checkpoint"
                )
            current_confirmations.append(record)
        elif response == "refuse":
            if matching != "current" or chosen != "none":
                raise ContractError(
                    "refuse must match the current transition and chosen_branch_id none"
                )
            refusals.append(record)
        elif response == "revoke":
            if matching != "current" or chosen != "none":
                raise ContractError(
                    "revoke must match the current transition and chosen_branch_id none"
                )
            revocations.append(record)

    response_stage_sources = {
        "stale_response": stale_confirmations,
        "refused": refusals,
        "revoked": revocations,
    }
    linked_response_stages: dict[str, list[Mapping[str, Any]]] = {
        stage: [] for stage in response_stage_sources
    }
    for record in stage_records:
        payload = _payload(record, "transition_stage")
        stage = payload.get("stage")
        evidence = payload.get("evidence_seqs")
        if stage == "closed":
            if (
                not isinstance(evidence, list)
                or record["seq"] <= pending_seq
                or pending_seq not in evidence
            ):
                raise ContractError(
                    "closed transition stage must follow and evidence the pending transition"
                )
            continue
        if stage not in response_stage_sources:
            continue
        if payload.get("evidence_source") != "user_event":
            raise ContractError(f"{stage} evidence_source must be user_event")
        if not isinstance(evidence, list):
            raise ContractError(f"{stage} requires response evidence sequences")
        matching_responses = [
            response_record
            for response_record in response_stage_sources[str(stage)]
            if response_record["seq"] < record["seq"]
            and response_record["seq"] in evidence
        ]
        if not matching_responses:
            raise ContractError(
                f"{stage} must follow and include its exact response sequence as evidence"
            )
        linked_response_stages[str(stage)].append(record)

    current_confirmation_by_seq = {
        record["seq"]: record for record in current_confirmations
    }
    confirmation_stages = [
        record
        for record in stage_records
        if _payload(record, "transition_stage").get("stage")
        == "transition_user_confirmed"
    ]
    for record in _events(records, "branch_selection"):
        selection = _payload(record, "branch_selection")
        if selection.get("status") != "selected_by_user":
            continue
        response_seq = selection.get("transition_response_seq")
        response_record = current_confirmation_by_seq.get(response_seq)
        if response_record is None or response_seq >= record["seq"]:
            raise ContractError(
                "selected_by_user requires an earlier exact current confirmation response"
            )
        response_payload = _payload(response_record, "transition_response")
        if response_payload.get("chosen_branch_id") != selection.get("selected_branch_id"):
            raise ContractError(
                "selected_by_user selected branch must match the confirmation chosen_branch_id"
            )
        matching_stages = [
            stage_record
            for stage_record in confirmation_stages
            if stage_record["seq"] < record["seq"]
            and response_seq
            in _payload(stage_record, "transition_stage").get("evidence_seqs", [])
        ]
        if not matching_stages:
            raise ContractError(
                "selected_by_user requires an earlier transition_user_confirmed stage "
                "linked to the exact response"
            )
        evidence = selection.get("evidence_seqs", [])
        confirmation_stage_seqs = {stage_record["seq"] for stage_record in matching_stages}
        if response_seq not in evidence or not confirmation_stage_seqs.intersection(evidence):
            raise ContractError(
                "selected_by_user evidence must include its confirmation response and stage"
            )

    for record in responses:
        payload = _payload(record, "transition_response")
        if payload.get("response") != "revoke":
            continue
        earlier_confirmations = [
            candidate
            for candidate in current_confirmations
            if candidate["seq"] < record["seq"]
        ]
        if not earlier_confirmations:
            raise ContractError("revoke requires an earlier exact current confirmation")
        confirmed_response_seqs = {candidate["seq"] for candidate in earlier_confirmations}
        if not any(
            stage_record["seq"] < record["seq"]
            and confirmed_response_seqs.intersection(
                _payload(stage_record, "transition_stage").get("evidence_seqs", [])
            )
            for stage_record in confirmation_stages
        ):
            raise ContractError("revoked transition requires earlier confirmation stage evidence")

    external_records = _events(records, "external_evidence")
    external_by_seq: dict[int, Mapping[str, Any]] = {}
    external_by_id: dict[str, Mapping[str, Any]] = {}
    source_refs: set[str] = set()
    allowed_evidence_pairs = set(EXTERNAL_EVIDENCE_REQUIREMENTS.values())
    for record in external_records:
        payload = _payload(record, "external_evidence")
        evidence_id = _required(payload, "evidence_id", "external_evidence")
        source_ref = _required(payload, "source_ref", "external_evidence")
        if evidence_id in external_by_id:
            raise ContractError("external evidence_id values must be unique")
        if source_ref in source_refs:
            raise ContractError("external evidence source_ref values must be unique")
        external_by_id[str(evidence_id)] = record
        external_by_seq[record["seq"]] = record
        source_refs.add(str(source_ref))
        if (
            payload.get("transition_id") != transition_id
            or payload.get("transition_version") != transition_version
        ):
            raise ContractError(
                "external_evidence must preserve the exact transition ID and version"
            )
        if payload.get("expected_effect") != pending.get("expected_effect"):
            raise ContractError(
                "external_evidence must preserve the exact expected_effect"
            )
        pair = (payload.get("evidence_kind"), payload.get("outcome"))
        if pair not in allowed_evidence_pairs:
            raise ContractError(
                f"external_evidence kind and outcome do not match: {pair!r}"
            )
        basis = payload.get("basis_seqs")
        if not isinstance(basis, list) or not basis or not all(
            isinstance(seq, int) and 0 < seq < record["seq"] for seq in basis
        ):
            raise ContractError(
                "external_evidence basis_seqs must be non-empty and refer only to earlier records"
            )

    gate_records = [
        record
        for record in [*stage_records, *action_records]
        if _payload(record, str(record["kind"])).get("stage") in EXTERNAL_STAGES
    ]
    gate_records.sort(key=lambda record: record["seq"])
    prior_gate_seqs: dict[str, list[int]] = {}
    consumed_external_evidence: set[str] = set()
    required_predecessor = {
        "authorized": "transition_user_confirmed",
        "preflight_passed": "authorized",
        "executed": "preflight_passed",
        "observed": "executed",
    }
    current_control_responses = [
        record
        for record in responses
        if _payload(record, "transition_response").get("matching") == "current"
    ]

    def latest_current_response(before_seq: int) -> Mapping[str, Any] | None:
        prior = [record for record in current_control_responses if record["seq"] < before_seq]
        return max(prior, key=lambda record: record["seq"]) if prior else None

    for record in gate_records:
        payload = _payload(record, str(record["kind"]))
        stage = str(payload.get("stage"))
        evidence = payload.get("evidence_seqs")
        if not isinstance(evidence, list) or not evidence or not all(
            isinstance(seq, int) and 0 < seq < record["seq"] for seq in evidence
        ):
            raise ContractError(f"{stage} evidence must refer only to earlier records")

        latest_response = latest_current_response(record["seq"])
        if stage == "transition_user_confirmed":
            if payload.get("evidence_source") != "user_event":
                raise ContractError(
                    "transition_user_confirmed evidence_source must be user_event"
                )
            if (
                latest_response is None
                or _payload(latest_response, "transition_response").get("response")
                != "confirm"
                or latest_response["seq"] not in evidence
            ):
                raise ContractError(
                    "transition_user_confirmed must link the latest exact current confirmation"
                )
            prior_gate_seqs.setdefault(stage, []).append(record["seq"])
            continue

        if stage in {"executed", "observed"} and record["kind"] != "transition_action":
            raise ContractError(f"{stage} requires a transition_action record")
        if latest_response is None:
            raise ContractError(f"{stage} requires a current confirmation gate chain")
        latest_response_payload = _payload(latest_response, "transition_response")
        if latest_response_payload.get("response") in {"refuse", "revoke"}:
            raise ContractError(
                f"{stage} gate cannot follow current refuse or revoke; "
                "a new exact confirmation is required"
            )
        confirmation_candidates = [
            seq
            for seq in prior_gate_seqs.get("transition_user_confirmed", [])
            if latest_response["seq"] < seq < record["seq"]
        ]
        if not confirmation_candidates:
            raise ContractError(
                f"{stage} requires transition_user_confirmed after the latest confirmation"
            )
        confirmation_anchor = max(confirmation_candidates)
        predecessor = required_predecessor[stage]
        predecessor_candidates = [
            seq
            for seq in prior_gate_seqs.get(predecessor, [])
            if confirmation_anchor <= seq < record["seq"]
        ]
        if not predecessor_candidates:
            raise ContractError(
                f"{stage} requires an earlier independent {predecessor} gate"
            )
        predecessor_seq = max(predecessor_candidates)

        if len(evidence) != 1 or evidence[0] not in external_by_seq:
            raise ContractError(
                f"{stage} must reference exactly one matching external_evidence event"
            )
        external_record = external_by_seq[evidence[0]]
        external_payload = _payload(external_record, "external_evidence")
        evidence_id = str(external_payload.get("evidence_id"))
        if payload.get("evidence_source") != evidence_id:
            raise ContractError(
                f"{stage} evidence_source must equal the matching external evidence_id"
            )
        expected_pair = EXTERNAL_EVIDENCE_REQUIREMENTS[stage]
        actual_pair = (
            external_payload.get("evidence_kind"),
            external_payload.get("outcome"),
        )
        if actual_pair != expected_pair:
            raise ContractError(
                f"{stage} external_evidence must be {expected_pair!r}, got {actual_pair!r}"
            )
        if evidence_id in consumed_external_evidence:
            raise ContractError(
                "each external_evidence event may support only one external gate"
            )
        required_basis_seq = (
            confirmation_anchor if stage == "authorized" else predecessor_seq
        )
        if required_basis_seq not in external_payload.get("basis_seqs", []):
            raise ContractError(
                f"{stage} external_evidence basis must include its prior gate"
            )
        consumed_external_evidence.add(evidence_id)
        if record["kind"] == "transition_action" and (
            payload.get("expected_effect") != pending.get("expected_effect")
        ):
            raise ContractError(
                "transition action does not preserve the exact expected effect"
            )
        prior_gate_seqs.setdefault(stage, []).append(record["seq"])

    selected_by_user = [
        record
        for record in _events(records, "branch_selection")
        if _payload(record, "branch_selection").get("status") == "selected_by_user"
    ]
    if scenario == "nonblocking_branching_v3":
        model_only_selections = all(
            _payload(record, "branch_selection").get("status")
            in {"selected_in_model", "recommended"}
            for record in _events(records, "branch_selection")
        )
        if (
            stages != ["closed"]
            or responses
            or action_records
            or external_records
            or not model_only_selections
        ):
            raise ContractError(
                "nonblocking scenario requires only closed transition, no response/action, "
                "and model-only selection"
            )
    elif scenario == "late_confirmation_v3":
        if not current_confirmations or not confirmation_stages or not selected_by_user:
            raise ContractError(
                "late_confirmation scenario requires current confirm, linked "
                "transition_user_confirmed, and selected_by_user"
            )
    elif scenario == "stale_confirmation_v3":
        if (
            not stale_confirmations
            or not linked_response_stages["stale_response"]
            or current_confirmations
            or selected_by_user
        ):
            raise ContractError(
                "stale_confirmation scenario requires stale confirm and stale_response only"
            )
    elif scenario == "refusal_v3":
        if (
            not refusals
            or not linked_response_stages["refused"]
            or current_confirmations
            or selected_by_user
        ):
            raise ContractError(
                "refusal scenario requires current refusal without selected_by_user"
            )
    elif scenario == "revocation_v3":
        if not revocations or not linked_response_stages["revoked"]:
            raise ContractError(
                "revocation scenario requires current revoke and linked revoked stage"
            )
    elif scenario == "single_branch_limited_budget_v3":
        if stages != ["closed"] or responses or action_records or external_records:
            raise ContractError(
                "single-branch scenario keeps the transition closed without external events"
            )


def _validate_episode_outcomes(records: Sequence[Mapping[str, Any]]) -> None:
    episode_states = _events(records, "episode_state")
    if not episode_states:
        raise ContractError("trace requires episode_state records")
    final = _payload(episode_states[-1], "episode_state")
    state = final.get("state")
    checkpoints = _events(records, "episode_checkpoint")
    checkpoint = _payload(checkpoints[-1], "episode_checkpoint") if checkpoints else {}
    if checkpoints:
        final_budget = final.get("budget")
        if not isinstance(final_budget, Mapping):
            raise ContractError("final episode_state budget must be an object")
        counter_pairs = (
            (
                "remaining_budget",
                checkpoint.get("remaining_budget"),
                final_budget.get("remaining"),
            ),
            (
                "productive continuations",
                checkpoint.get("productive_continuations_remaining"),
                final.get("safe_productive_continuations_remaining"),
            ),
            (
                "distinguishing checks",
                checkpoint.get("distinguishing_checks_remaining"),
                final.get("distinguishing_checks_remaining"),
            ),
        )
        for label, checkpoint_value, final_value in counter_pairs:
            if checkpoint_value != final_value:
                raise ContractError(
                    f"latest episode_checkpoint {label} counter must match final episode_state"
                )

    if state == "unresolved_conflict":
        remaining_checks = final.get(
            "distinguishing_checks_remaining",
            checkpoint.get("distinguishing_checks_remaining", 0),
        )
        budget = final.get("budget", {})
        remaining_budget = (
            budget.get("remaining")
            if isinstance(budget, Mapping)
            else checkpoint.get("remaining_budget", 0)
        )
        if remaining_budget is None:
            remaining_budget = checkpoint.get("remaining_budget", 0)
        if isinstance(remaining_checks, int) and isinstance(remaining_budget, int):
            if remaining_checks > 0 and remaining_budget > 0:
                raise ContractError(
                    "unresolved_conflict is premature while a distinguishing check fits the budget"
                )

    if state == "needs_input":
        productive = final.get(
            "safe_productive_continuations_remaining",
            checkpoint.get("productive_continuations_remaining", 0),
        )
        budget = final.get("budget", {})
        remaining_budget = (
            budget.get("remaining")
            if isinstance(budget, Mapping)
            else checkpoint.get("remaining_budget", 0)
        )
        if remaining_budget is None:
            remaining_budget = checkpoint.get("remaining_budget", 0)
        if isinstance(productive, int) and isinstance(remaining_budget, int):
            if productive > 0 and remaining_budget > 0:
                raise ContractError(
                    "needs_input is premature while a safe productive continuation has budget"
                )

    for record in episode_states:
        payload = _payload(record, "episode_state")
        budget = _required(payload, "budget", "episode_state")
        if not isinstance(budget, Mapping):
            raise ContractError("episode_state budget must be an object")
        initial = _required(budget, "initial", "episode_state budget")
        consumed = _required(budget, "consumed", "episode_state budget")
        remaining = _required(budget, "remaining", "episode_state budget")
        if not all(
            isinstance(value, int) and not isinstance(value, bool) and value >= 0
            for value in (initial, consumed, remaining)
        ) or initial <= 0 or consumed + remaining != initial:
            raise ContractError(
                "episode_state budget must be finite and satisfy initial = consumed + remaining"
            )
    final_budget = final["budget"]
    consumed_by_branches = sum(
        _payload(record, "model_branch")["budget"]["consumed"]
        for record in _events(records, "model_branch")
    )
    if final_budget["consumed"] != consumed_by_branches:
        raise ContractError(
            "final episode budget must equal the sum of consumed branch budgets"
        )


def validate_trace(
    records: Sequence[Mapping[str, Any]],
    schema: Mapping[str, Any],
    *,
    scenario: str,
) -> None:
    """Проверить v3-трассу, включая отношения между независимыми осями."""

    known_scenarios = {
        "nonblocking_branching_v3",
        "late_confirmation_v3",
        "stale_confirmation_v3",
        "refusal_v3",
        "revocation_v3",
        "single_branch_limited_budget_v3",
    }
    if scenario not in known_scenarios:
        raise ContractError(f"unknown validation scenario {scenario!r}")
    if not isinstance(schema, Mapping):
        raise ContractError("schema must be a JSON object")

    _validate_record_envelope(records)
    _validate_storage_policy(records)
    _validate_episode_identity(records)
    branch_ids, _ = _validate_model_branches(records, scenario)
    _validate_transition(records, branch_ids, scenario)
    _validate_episode_outcomes(records)

    for index, record in enumerate(records, start=1):
        _validate_schema_value(record, schema, schema, f"record[{index}]")


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def _default_cases() -> list[tuple[Path, str]]:
    trace_dir = (
        _repo_root()
        / "Документация"
        / "37-минимальный-формат-трассы-исполняемого-агентского-цикла"
    )
    return [
        (
            trace_dir / "фикстура-неблокирующего-модельного-ветвления-v3.jsonl",
            "nonblocking_branching_v3",
        ),
        (
            trace_dir / "фикстура-позднего-подтверждения-перехода-v3.jsonl",
            "late_confirmation_v3",
        ),
        (
            trace_dir / "фикстура-одной-ветви-при-ограниченном-бюджете-v3.jsonl",
            "single_branch_limited_budget_v3",
        ),
    ]


def _load_schema(path: Path) -> Mapping[str, Any]:
    try:
        schema = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_object_without_duplicate_keys)
    except (OSError, UnicodeError, json.JSONDecodeError, ContractError) as error:
        raise ContractError(f"cannot read schema {path}: {error}") from error
    if not isinstance(schema, Mapping):
        raise ContractError("schema root must be an object")
    return schema


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Проверить локальную трассу агентского цикла FUM v3 без сети."
    )
    parser.add_argument("--schema", type=Path, help="путь к схеме события v3")
    parser.add_argument("--trace", type=Path, help="путь к одной JSONL-трассе")
    parser.add_argument(
        "--scenario",
        choices=(
            "nonblocking_branching_v3",
            "late_confirmation_v3",
            "stale_confirmation_v3",
            "refusal_v3",
            "revocation_v3",
            "single_branch_limited_budget_v3",
        ),
        help="межсобытийный сценарий для --trace",
    )
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(list(argv) if argv is not None else None)
    trace_dir = (
        _repo_root()
        / "Документация"
        / "37-минимальный-формат-трассы-исполняемого-агентского-цикла"
    )
    schema_path = args.schema or trace_dir / "схема-события-v3.json"
    if (args.trace is None) != (args.scenario is None):
        parser.error("--trace и --scenario нужно передавать вместе")

    try:
        schema = _load_schema(schema_path)
        cases = [(args.trace, args.scenario)] if args.trace else _default_cases()
        for path, scenario in cases:
            assert path is not None and scenario is not None
            validate_trace(load_trace(path), schema, scenario=scenario)
            print(f"OK: {path} ({scenario})")
    except ContractError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
