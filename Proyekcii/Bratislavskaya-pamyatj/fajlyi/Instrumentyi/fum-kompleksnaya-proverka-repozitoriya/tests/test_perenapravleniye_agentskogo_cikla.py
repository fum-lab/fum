import copy
import json
import re
import unittest
from datetime import datetime
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
TRACE_DIR = (
    REPO_ROOT
    / "Документация"
    / "37-минимальный-формат-трассы-исполняемого-агентского-цикла"
)
SCHEMA_PATH = TRACE_DIR / "схема-события-v2.json"
FIXTURE_PATH = TRACE_DIR / "фикстура-перенаправления-пользовательским-вводом-v2.jsonl"

EXPECTED_KINDS = {
    "task",
    "plan",
    "input_event",
    "input_signal",
    "checkpoint",
    "redirect",
    "observation",
    "action",
    "check",
    "result",
    "error",
    "continuation",
}
EXPECTED_FIXTURE_ORDER = [
    "task",
    "plan",
    "continuation",
    "input_event",
    "input_event",
    "input_signal",
    "checkpoint",
    "redirect",
    "plan",
    "continuation",
    "action",
    "result",
    "check",
    "continuation",
]
TERMINAL_CONTINUATIONS = {
    "completed",
    "blocked",
    "awaiting_confirmation",
    "handed_off",
    "stopped",
    "failed",
}
FORBIDDEN_REASONING_KEYS = {
    "reasoning",
    "thought",
    "thoughts",
    "chain_of_thought",
    "hidden_reasoning",
    "model_tokens",
}
WINDOWS_ABSOLUTE_RE = re.compile(r"^[A-Za-z]:[\\/]")


class SchemaViolation(ValueError):
    pass


def resolve_ref(root_schema: dict, reference: str) -> dict:
    if not reference.startswith("#/"):
        raise SchemaViolation(f"unsupported non-local schema reference: {reference}")
    value: object = root_schema
    pointer_escape = chr(126)
    for raw_part in reference[2:].split("/"):
        part = raw_part.replace(f"{pointer_escape}1", "/").replace(
            f"{pointer_escape}0", pointer_escape
        )
        if not isinstance(value, dict) or part not in value:
            raise SchemaViolation(f"unresolved schema reference: {reference}")
        value = value[part]
    if not isinstance(value, dict):
        raise SchemaViolation(f"schema reference is not an object: {reference}")
    return value


def validate_schema(value: object, schema: dict, root_schema: dict, path: str = "$") -> None:
    if "$ref" in schema:
        validate_schema(value, resolve_ref(root_schema, schema["$ref"]), root_schema, path)

    if "type" in schema:
        expected_type = schema["type"]
        type_matches = {
            "object": isinstance(value, dict),
            "array": isinstance(value, list),
            "string": isinstance(value, str),
            "integer": isinstance(value, int) and not isinstance(value, bool),
            "boolean": isinstance(value, bool),
        }.get(expected_type)
        if type_matches is not True:
            raise SchemaViolation(f"{path}: expected {expected_type}")

    if "const" in schema and value != schema["const"]:
        raise SchemaViolation(f"{path}: expected const {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        raise SchemaViolation(f"{path}: value is outside enum")

    if "oneOf" in schema:
        matches = 0
        discriminator_error = None
        for alternative in schema["oneOf"]:
            try:
                validate_schema(value, alternative, root_schema, path)
            except SchemaViolation as exc:
                alternative_kind = (
                    alternative.get("properties", {})
                    .get("kind", {})
                    .get("const")
                )
                if (
                    alternative_kind is not None
                    and isinstance(value, dict)
                    and value.get("kind") == alternative_kind
                ):
                    discriminator_error = exc
                continue
            matches += 1
        if matches != 1:
            if matches == 0 and discriminator_error is not None:
                raise discriminator_error
            raise SchemaViolation(f"{path}: expected exactly one oneOf match, got {matches}")

    if isinstance(value, dict):
        required = schema.get("required", [])
        missing = [name for name in required if name not in value]
        if missing:
            raise SchemaViolation(f"{path}: missing required fields {missing}")
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            unknown = sorted(set(value) - set(properties))
            if unknown:
                raise SchemaViolation(f"{path}: unknown fields {unknown}")
        for name, child_schema in properties.items():
            if name in value:
                validate_schema(value[name], child_schema, root_schema, f"{path}.{name}")

    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            raise SchemaViolation(f"{path}: too few items")
        if schema.get("uniqueItems"):
            canonical = [
                json.dumps(item, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
                for item in value
            ]
            if len(canonical) != len(set(canonical)):
                raise SchemaViolation(f"{path}: duplicate array item")
        if "items" in schema:
            for index, item in enumerate(value):
                validate_schema(item, schema["items"], root_schema, f"{path}[{index}]")

    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            raise SchemaViolation(f"{path}: string is too short")
        pattern = schema.get("pattern")
        if pattern is not None and re.fullmatch(pattern, value) is None:
            raise SchemaViolation(f"{path}: string does not match pattern")

    if isinstance(value, int) and not isinstance(value, bool):
        if value < schema.get("minimum", value):
            raise SchemaViolation(f"{path}: integer is below minimum")


def parse_timestamp(value: str) -> datetime:
    normalized = value[:-1] + "+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError as exc:
        raise SchemaViolation(f"invalid timestamp: {value}") from exc
    if parsed.tzinfo is None:
        raise SchemaViolation(f"timestamp has no timezone: {value}")
    return parsed


def walk(value: object):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def all_strings(value: object):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from all_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from all_strings(child)


def load_schema() -> dict:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def load_fixture() -> list[dict]:
    raw = FIXTURE_PATH.read_bytes()
    if not raw.endswith(b"\n"):
        raise SchemaViolation("JSONL fixture must end with a newline")
    text = raw.decode("utf-8")
    lines = text.splitlines()
    if not lines or any(not line for line in lines):
        raise SchemaViolation("JSONL fixture must contain one non-empty object per line")
    records = [json.loads(line) for line in lines]
    if json.loads(text.splitlines()[0]) != records[0]:
        raise SchemaViolation("JSONL parsing is not deterministic")
    return records


def require_backward_reference(
    by_seq: dict[int, dict], current_seq: int, target_seq: int, expected_kinds: set[str]
) -> dict:
    if target_seq >= current_seq or target_seq not in by_seq:
        raise SchemaViolation(f"seq {current_seq}: invalid backward reference {target_seq}")
    target = by_seq[target_seq]
    if target["kind"] not in expected_kinds:
        raise SchemaViolation(
            f"seq {current_seq}: reference {target_seq} has kind {target['kind']}"
        )
    return target


def validate_redirect_fixture(records: list[dict], schema: dict) -> None:
    for index, record in enumerate(records):
        validate_schema(record, schema, schema, f"$[{index}]")

    if [record["kind"] for record in records] != EXPECTED_FIXTURE_ORDER:
        raise SchemaViolation("fixture event order differs from the accepted scenario")
    trace_ids = {record["trace_id"] for record in records}
    versions = {record["schema_version"] for record in records}
    if len(trace_ids) != 1 or versions != {2}:
        raise SchemaViolation("fixture mixes trace identifiers or schema versions")
    if [record["seq"] for record in records] != list(range(1, len(records) + 1)):
        raise SchemaViolation("fixture sequence is not contiguous")

    by_seq = {record["seq"]: record for record in records}
    tasks = [record for record in records if record["kind"] == "task"]
    if len(tasks) != 1 or tasks[0]["seq"] != 1:
        raise SchemaViolation("task message must be the unique first event")
    task = tasks[0]["payload"]
    if task["input_form"] != "task_message":
        raise SchemaViolation("task is not marked as a discrete task message")
    if task["model_step"] != {"mode": "none"}:
        raise SchemaViolation("fixture must not invoke a model provider")
    if not task["allowed_actions"] or any(
        action["effect"] != "read" or action["adapter"] != "local_files_read_only"
        for action in task["allowed_actions"]
    ):
        raise SchemaViolation("fixture may allow only local read actions")

    input_events = [record for record in records if record["kind"] == "input_event"]
    if len(input_events) < 2:
        raise SchemaViolation("fixture must aggregate more than one primary input event")
    stream_positions: dict[str, list[int]] = {}
    for record in input_events:
        payload = record["payload"]
        if payload["authorization"]["status"] != "allowed":
            raise SchemaViolation("fixture contains input outside the allowed scope")
        if parse_timestamp(payload["occurred_at"]) > parse_timestamp(payload["observed_at"]):
            raise SchemaViolation("input event was observed before it occurred")
        stream_positions.setdefault(payload["stream_id"], []).append(payload["stream_seq"])
    for positions in stream_positions.values():
        if positions != sorted(set(positions)):
            raise SchemaViolation("input stream positions are not strictly increasing")

    signal_record = next(record for record in records if record["kind"] == "input_signal")
    signal = signal_record["payload"]
    source_events = [
        require_backward_reference(by_seq, signal_record["seq"], seq, {"input_event"})
        for seq in signal["source_event_seqs"]
    ]
    if signal["source_event_seqs"] != [record["seq"] for record in input_events]:
        raise SchemaViolation("aggregate does not preserve all primary events in order")
    if signal["aggregation"]["event_count"] != len(source_events):
        raise SchemaViolation("aggregate event count differs from its provenance")
    stream_seqs = [record["payload"]["stream_seq"] for record in source_events]
    if signal["aggregation"]["first_stream_seq"] != stream_seqs[0]:
        raise SchemaViolation("aggregate first stream position is inconsistent")
    if signal["aggregation"]["last_stream_seq"] != stream_seqs[-1]:
        raise SchemaViolation("aggregate last stream position is inconsistent")
    latest_observation = max(
        parse_timestamp(record["payload"]["observed_at"]) for record in source_events
    )
    if parse_timestamp(signal["emitted_at"]) < latest_observation:
        raise SchemaViolation("aggregate was emitted before its source events were observed")

    initial_plan_record = by_seq[2]
    old_continuation_record = by_seq[3]
    old_plan = initial_plan_record["payload"]
    old_continuation = old_continuation_record["payload"]
    for basis_seq in old_plan["basis_seqs"]:
        require_backward_reference(
            by_seq, initial_plan_record["seq"], basis_seq, EXPECTED_KINDS
        )
    if old_continuation["plan_seq"] != initial_plan_record["seq"]:
        raise SchemaViolation("initial continuation is not bound to the initial plan")

    checkpoint_record = next(record for record in records if record["kind"] == "checkpoint")
    checkpoint = checkpoint_record["payload"]
    require_backward_reference(
        by_seq, checkpoint_record["seq"], checkpoint["plan_seq"], {"plan"}
    )
    if checkpoint["plan_seq"] != initial_plan_record["seq"]:
        raise SchemaViolation("checkpoint does not guard the active initial plan")
    if checkpoint_record["seq"] <= signal_record["seq"]:
        raise SchemaViolation("checkpoint precedes the accepted input signal")
    for basis_seq in checkpoint["basis_seqs"]:
        require_backward_reference(
            by_seq, checkpoint_record["seq"], basis_seq, EXPECTED_KINDS
        )
    if not {
        initial_plan_record["seq"],
        old_continuation_record["seq"],
        signal_record["seq"],
    }.issubset(checkpoint["basis_seqs"]):
        raise SchemaViolation("checkpoint omits the active plan, continuation or input")
    for action_seq in checkpoint["in_flight_action_seqs"]:
        require_backward_reference(
            by_seq, checkpoint_record["seq"], action_seq, {"action"}
        )

    redirect_record = next(record for record in records if record["kind"] == "redirect")
    redirect = redirect_record["payload"]
    require_backward_reference(
        by_seq, redirect_record["seq"], redirect["checkpoint_seq"], {"checkpoint"}
    )
    require_backward_reference(
        by_seq, redirect_record["seq"], redirect["previous_plan_seq"], {"plan"}
    )
    require_backward_reference(
        by_seq,
        redirect_record["seq"],
        redirect["previous_continuation_seq"],
        {"continuation"},
    )
    if redirect["previous_plan_seq"] != initial_plan_record["seq"]:
        raise SchemaViolation("redirect does not identify the active initial plan")
    if redirect["previous_continuation_seq"] != old_continuation_record["seq"]:
        raise SchemaViolation("redirect does not identify the active continuation")
    for input_seq in redirect["input_seqs"]:
        require_backward_reference(
            by_seq, redirect_record["seq"], input_seq, {"input_event", "input_signal"}
        )
    if redirect["input_seqs"] != [signal_record["seq"]]:
        raise SchemaViolation("redirect mixes aggregate and already aggregated primary events")
    if redirect["decision"] != "change" or not redirect["changed_dimensions"]:
        raise SchemaViolation("fixture redirect must apply an observable change")
    if not set(redirect["changed_dimensions"]).issubset(checkpoint["safe_changes"]):
        raise SchemaViolation("redirect changes a dimension not allowed at the checkpoint")
    if "action" in redirect["changed_dimensions"] and checkpoint["in_flight_action_seqs"]:
        raise SchemaViolation("fixture replaces an action that is already in flight")
    dispositions = redirect["planned_action_dispositions"]
    if "action" in redirect["changed_dimensions"]:
        expected_disposition = {
            "planned_action_id": old_plan["next_action"]["planned_action_id"],
            "status": "superseded_before_start",
        }
        if dispositions != [expected_disposition]:
            raise SchemaViolation("redirect does not preserve the displaced action identity")
    elif dispositions:
        raise SchemaViolation("redirect assigns a disposition without changing the action")

    revised_plan_record = by_seq[9]
    new_plan = revised_plan_record["payload"]
    if new_plan.get("supersedes_plan_seq") != initial_plan_record["seq"]:
        raise SchemaViolation("revised plan does not supersede the initial plan")
    if new_plan.get("redirect_seq") != redirect_record["seq"]:
        raise SchemaViolation("revised plan does not preserve redirect provenance")
    if new_plan["plan_id"] != old_plan["plan_id"]:
        raise SchemaViolation("revised plan changed its stable identity")
    if new_plan["revision"] != old_plan["revision"] + 1:
        raise SchemaViolation("revised plan did not advance exactly one revision")
    dimensions = {
        "goal": (old_plan["goal"], new_plan["goal"]),
        "priority": (old_plan["priority"], new_plan["priority"]),
        "branch": (old_plan["branch"], new_plan["branch"]),
        "action": (old_plan["next_action"], new_plan["next_action"]),
    }
    actual_changes = {name for name, pair in dimensions.items() if pair[0] != pair[1]}
    if actual_changes != set(redirect["changed_dimensions"]):
        raise SchemaViolation("declared and actual plan changes differ")
    for basis_seq in new_plan["basis_seqs"]:
        require_backward_reference(by_seq, revised_plan_record["seq"], basis_seq, EXPECTED_KINDS)
    if redirect_record["seq"] not in new_plan["basis_seqs"]:
        raise SchemaViolation("revised plan basis omits the redirect decision")

    new_continuation_record = by_seq[10]
    new_continuation = new_continuation_record["payload"]
    if new_continuation["plan_seq"] != revised_plan_record["seq"]:
        raise SchemaViolation("new continuation points to the old plan")
    if new_continuation.get("supersedes_continuation_seq") != old_continuation_record["seq"]:
        raise SchemaViolation("new continuation omits the previous continuation")

    action_record = by_seq[11]
    action = action_record["payload"]
    if action["plan_seq"] != revised_plan_record["seq"]:
        raise SchemaViolation("action is not bound to the revised plan")
    planned_action = new_plan["next_action"]
    for field in (
        "planned_action_id",
        "operation",
        "adapter",
        "effect",
        "target_refs",
    ):
        if action[field] != planned_action[field]:
            raise SchemaViolation(f"action differs from revised plan field {field}")
    allowed_triples = {
        (item["operation"], item["adapter"], item["effect"])
        for item in task["allowed_actions"]
    }
    if (action["operation"], action["adapter"], action["effect"]) not in allowed_triples:
        raise SchemaViolation("action is outside the task allowlist")
    if len(action["target_refs"]) != 1:
        raise SchemaViolation("fixture action must have exactly one local target")
    target_path = (REPO_ROOT / action["target_refs"][0]).resolve()
    try:
        target_path.relative_to(REPO_ROOT.resolve())
    except ValueError as exc:
        raise SchemaViolation("fixture action target leaves the repository") from exc
    if not target_path.is_file():
        raise SchemaViolation("fixture action target is not a local file")
    first_content_line = next(
        (line for line in target_path.read_text(encoding="utf-8").splitlines() if line),
        None,
    )
    if first_content_line is None:
        raise SchemaViolation("fixture action target has no observable content")

    result_record = by_seq[12]
    result = result_record["payload"]
    require_backward_reference(
        by_seq,
        result_record["seq"],
        result["action_seq"],
        {"action"},
    )
    if result["action_seq"] != action_record["seq"]:
        raise SchemaViolation("result is not bound to the redirected action")
    if result["status"] != "success":
        raise SchemaViolation("fixture result is not successful")
    if result["artifact_refs"] != action["target_refs"]:
        raise SchemaViolation("result artifacts differ from the redirected action target")

    check_record = by_seq[13]
    check = check_record["payload"]
    require_backward_reference(
        by_seq,
        check_record["seq"],
        check["subject_seq"],
        {"result", "error"},
    )
    if check["subject_seq"] != result_record["seq"]:
        raise SchemaViolation("check is not bound to the redirected action result")
    if check["status"] != "passed":
        raise SchemaViolation("fixture check did not pass")
    if check["evidence_refs"] != result["artifact_refs"]:
        raise SchemaViolation("check evidence differs from the result artifacts")
    expected_check_summary = (
        f"Первая содержательная строка равна «{first_content_line}»."
    )
    if check["summary"] != expected_check_summary:
        raise SchemaViolation("check summary differs from the observed local content")

    final_continuation = by_seq[14]["payload"]
    if final_continuation["status"] != "completed":
        raise SchemaViolation("fixture does not end in checked completion")
    if final_continuation["plan_seq"] != revised_plan_record["seq"]:
        raise SchemaViolation("final continuation is not bound to the revised plan")
    if final_continuation.get("supersedes_continuation_seq") != new_continuation_record["seq"]:
        raise SchemaViolation("final continuation omits the redirected continuation")
    if not {
        new_continuation_record["seq"],
        result_record["seq"],
        check_record["seq"],
    }.issubset(final_continuation["basis_seqs"]):
        raise SchemaViolation("final continuation omits continuation, result or check evidence")

    for record in records:
        if record["kind"] == "continuation":
            for basis_seq in record["payload"]["basis_seqs"]:
                require_backward_reference(by_seq, record["seq"], basis_seq, EXPECTED_KINDS)
            if (
                record["payload"]["status"] in TERMINAL_CONTINUATIONS
                and record["seq"] != len(records)
            ):
                raise SchemaViolation("terminal continuation is not the final event")

    for mapping in walk(records):
        if FORBIDDEN_REASONING_KEYS.intersection(mapping):
            raise SchemaViolation("fixture contains a forbidden hidden-reasoning field")
    for value in all_strings(records):
        lowered = value.lower()
        if (
            value.startswith("/")
            or value.startswith("\\\\")
            or WINDOWS_ABSOLUTE_RE.match(value)
            or lowered.startswith(("file://", "http://", "https://"))
        ):
            raise SchemaViolation("fixture contains a machine-local or network reference")


class AgentCycleRedirectionFixtureTests(unittest.TestCase):
    def setUp(self) -> None:
        self.schema = load_schema()
        self.records = load_fixture()

    def assert_invalid(self, records: list[dict], pattern: str) -> None:
        with self.assertRaisesRegex(SchemaViolation, pattern):
            validate_redirect_fixture(records, self.schema)

    def test_schema_and_fixture_preserve_the_redirect_contract(self):
        self.assertEqual(self.schema["properties"]["schema_version"]["const"], 2)
        self.assertEqual(set(self.schema["properties"]["kind"]["enum"]), EXPECTED_KINDS)
        for kind in EXPECTED_KINDS:
            self.assertIn(kind, self.schema["$defs"])
        validate_redirect_fixture(self.records, self.schema)
        reparsed = [json.loads(line) for line in FIXTURE_PATH.read_text(encoding="utf-8").splitlines()]
        self.assertEqual(reparsed, self.records)

    def test_rejects_aggregate_without_primary_event_provenance(self):
        records = copy.deepcopy(self.records)
        records[5]["payload"]["source_event_seqs"] = [1, 5]
        self.assert_invalid(records, "reference 1 has kind task")

    def test_rejects_redirect_outside_safe_checkpoint(self):
        records = copy.deepcopy(self.records)
        records[6]["payload"]["safe_changes"].remove("goal")
        self.assert_invalid(records, "not allowed at the checkpoint")

    def test_rejects_undeclared_plan_change(self):
        records = copy.deepcopy(self.records)
        records[8]["payload"]["priority"] += 1
        self.assert_invalid(records, "declared and actual plan changes differ")

    def test_rejects_hidden_reasoning_field(self):
        records = copy.deepcopy(self.records)
        records[7]["payload"]["chain_of_thought"] = "not observable"
        self.assert_invalid(records, "unknown fields")

    def test_rejects_model_provider_or_network_reference(self):
        records = copy.deepcopy(self.records)
        records[0]["payload"]["model_step"] = {
            "mode": "provider",
            "provider_ref": "https://example.invalid/model",
        }
        self.assert_invalid(records, "must not invoke a model provider")

    def test_rejects_disallowed_primary_input(self):
        records = copy.deepcopy(self.records)
        records[3]["payload"]["authorization"]["status"] = "denied"
        self.assert_invalid(records, "outside enum")

    def test_rejects_empty_primary_input_provenance(self):
        records = copy.deepcopy(self.records)
        records[3]["payload"]["source_refs"] = []
        self.assert_invalid(records, "too few items")

    def test_rejects_future_initial_plan_basis(self):
        records = copy.deepcopy(self.records)
        records[1]["payload"]["basis_seqs"] = [14]
        self.assert_invalid(records, "invalid backward reference 14")

    def test_rejects_foreign_displaced_action_identity(self):
        records = copy.deepcopy(self.records)
        records[7]["payload"]["planned_action_dispositions"][0][
            "planned_action_id"
        ] = "unrelated-action"
        self.assert_invalid(records, "displaced action identity")

    def test_rejects_action_target_outside_revised_plan(self):
        records = copy.deepcopy(self.records)
        records[10]["payload"]["target_refs"] = ["Глоссарий/FUM.md"]
        self.assert_invalid(records, "field target_refs")

    def test_rejects_failed_result_or_check(self):
        for record_index, field, value, pattern in (
            (11, "status", "failed", "result is not successful"),
            (12, "status", "failed", "check did not pass"),
        ):
            with self.subTest(record_index=record_index):
                records = copy.deepcopy(self.records)
                records[record_index]["payload"][field] = value
                self.assert_invalid(records, pattern)

    def test_rejects_completed_continuation_without_checked_evidence(self):
        records = copy.deepcopy(self.records)
        records[13]["payload"]["basis_seqs"] = [1]
        self.assert_invalid(records, "omits continuation, result or check evidence")

    def test_schema_rejects_unsupported_or_empty_redirect_change(self):
        records = copy.deepcopy(self.records)
        records[6]["payload"]["safe_changes"].append("pause")
        self.assert_invalid(records, "outside enum")

        records = copy.deepcopy(self.records)
        records[7]["payload"]["decision"] = "keep"
        self.assert_invalid(records, "expected exactly one oneOf match")


if __name__ == "__main__":
    unittest.main()
