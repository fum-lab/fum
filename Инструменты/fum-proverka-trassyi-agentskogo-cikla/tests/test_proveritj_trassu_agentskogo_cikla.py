import copy
import hashlib
import importlib.util
import json
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
TRACE_DIR = (
    REPO_ROOT
    / "Документация"
    / "37-минимальный-формат-трассы-исполняемого-агентского-цикла"
)
AUTOMATION_DIR = REPO_ROOT / "Инструменты" / "fum-proverka-trassyi-agentskogo-cikla"
SCRIPT_PATH = AUTOMATION_DIR / "scripts" / "proveritj-trassu-agentskogo-cikla.py"
SCHEMA_PATH = TRACE_DIR / "схема-события-v3.json"
PRIMARY_PATH = TRACE_DIR / "фикстура-неблокирующего-модельного-ветвления-v3.jsonl"
LATE_PATH = TRACE_DIR / "фикстура-позднего-подтверждения-перехода-v3.jsonl"
LIMITED_PATH = TRACE_DIR / "фикстура-одной-ветви-при-ограниченном-бюджете-v3.jsonl"

EXPECTED_TRACE_SHA256 = {
    "схема-события-v1.json": "3a76daec5034e463f19923c7e1fa8fdbe3fb90312547fe959cb9503838cd28ee",
    "фикстура-короткой-локальной-задачи.jsonl": "b66c434cc199e82bd2b1fbf7c41a6d22e32def4402c4b462d727d06af743dd12",
    "схема-события-v2.json": "db023129e0d0d44ed08f83a24964c598128fdfa3bd04398baf1051d530ddb951",
    "фикстура-перенаправления-пользовательским-вводом-v2.jsonl": "26c038a75524b05e0e9c5b1b61b14061097f610c32c626c98737aba50999e3fc",
    "схема-события-v3.json": "717e3a770890e09e81a4a4f1e1268f985a10fd183f1feb4a756c8757c64c3c18",
    "фикстура-неблокирующего-модельного-ветвления-v3.jsonl": "1b3970dce00494c2e374a057a3b7ddf39bacf72ff1d4491503fe09236bba7a5f",
    "фикстура-одной-ветви-при-ограниченном-бюджете-v3.jsonl": "4b93e7fa78bc9f69414c322c36e0b7a2cead2a344cf6cefc2abab8a65e2c041e",
    "фикстура-позднего-подтверждения-перехода-v3.jsonl": "331b4ef36322c2f43153bd32087b945e8b676c8ed67a474ceb99e7bff1bbdac4",
}
EXPECTED_NEW_KINDS = {
    "task",
    "episode_state",
    "pending_transition",
    "model_checkpoint",
    "model_branch",
    "model_step",
    "branch_check",
    "branch_selection",
    "episode_checkpoint",
    "transition_response",
    "transition_stage",
    "transition_action",
    "external_evidence",
}


def load_module():
    spec = importlib.util.spec_from_file_location("fum_trace_validator", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("validator module cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_module()


class AgentCycleTraceV3Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
        cls.primary = validator.load_trace(PRIMARY_PATH)
        cls.late = validator.load_trace(LATE_PATH)
        cls.limited = validator.load_trace(LIMITED_PATH)

    def assert_invalid(self, records, pattern, scenario="nonblocking_branching_v3"):
        with self.assertRaisesRegex(validator.ContractError, pattern):
            validator.validate_trace(records, self.schema, scenario=scenario)

    @staticmethod
    def events(records, kind):
        return [record for record in records if record["kind"] == kind]

    @staticmethod
    def event(records, kind, index=0):
        return AgentCycleTraceV3Tests.events(records, kind)[index]

    @staticmethod
    def insert_before_last(records, record):
        result = copy.deepcopy(records)
        result.insert(len(result) - 1, record)
        for index, item in enumerate(result, start=1):
            item["seq"] = index
        return result

    @staticmethod
    def renumber(records):
        for index, item in enumerate(records, start=1):
            item["seq"] = index
        return records

    def without_user_selection(self, records):
        return self.renumber(
            [
                item
                for item in records
                if not (
                    item["kind"] == "branch_selection"
                    and item["payload"]["status"] == "selected_by_user"
                )
            ]
        )

    def external_execution_trace(self, base=None):
        records = copy.deepcopy(self.late if base is None else base)
        pending = self.event(records, "pending_transition")["payload"]
        stage_template = copy.deepcopy(self.event(records, "transition_stage"))
        confirmation_stage_seq = max(
            item["seq"]
            for item in records
            if item["kind"] == "transition_stage"
            and item["payload"]["stage"] == "transition_user_confirmed"
        )

        def evidence(evidence_id, evidence_kind, outcome, source_ref, basis_seqs):
            return {
                "schema_version": 3,
                "trace_id": records[0]["trace_id"],
                "seq": len(records) + 1,
                "kind": "external_evidence",
                "payload": {
                    "evidence_id": evidence_id,
                    "transition_id": pending["transition_id"],
                    "transition_version": pending["transition_version"],
                    "evidence_kind": evidence_kind,
                    "outcome": outcome,
                    "source_ref": source_ref,
                    "expected_effect": copy.deepcopy(pending["expected_effect"]),
                    "basis_seqs": basis_seqs,
                    "storage_policy_id": pending["storage_policy_id"],
                    "record_class": "trace",
                },
            }

        authority_evidence = evidence(
            "evidence-authority-v1",
            "authority_decision",
            "allowed",
            "fixture:authority-policy-v1",
            [confirmation_stage_seq],
        )
        records.append(authority_evidence)

        authorized = copy.deepcopy(stage_template)
        authorized["seq"] = len(records) + 1
        authorized["payload"].update(
            {
                "stage": "authorized",
                "evidence_source": authority_evidence["payload"]["evidence_id"],
                "evidence_seqs": [authority_evidence["seq"]],
            }
        )
        records.append(authorized)

        preflight_evidence = evidence(
            "evidence-preflight-v1",
            "current_state_preflight",
            "passed",
            "fixture:preflight-v1",
            [authorized["seq"]],
        )
        records.append(preflight_evidence)
        preflight = copy.deepcopy(stage_template)
        preflight["seq"] = len(records) + 1
        preflight["payload"].update(
            {
                "stage": "preflight_passed",
                "evidence_source": preflight_evidence["payload"]["evidence_id"],
                "evidence_seqs": [preflight_evidence["seq"]],
            }
        )
        records.append(preflight)

        execution_evidence = evidence(
            "evidence-execution-v1",
            "execution_receipt",
            "succeeded",
            "fixture:executor-receipt-v1",
            [preflight["seq"]],
        )
        records.append(execution_evidence)

        executed = {
            "schema_version": 3,
            "trace_id": records[0]["trace_id"],
            "seq": len(records) + 1,
            "kind": "transition_action",
            "payload": {
                "action_id": "action-executed-v1",
                "transition_id": pending["transition_id"],
                "transition_version": pending["transition_version"],
                "stage": "executed",
                "effect_scope": "external",
                "expected_effect": copy.deepcopy(pending["expected_effect"]),
                "evidence_source": execution_evidence["payload"]["evidence_id"],
                "evidence_seqs": [execution_evidence["seq"]],
                "storage_policy_id": pending["storage_policy_id"],
                "record_class": "trace",
            },
        }
        records.append(executed)

        observation_evidence = evidence(
            "evidence-observation-v1",
            "result_observation",
            "observed",
            "fixture:result-observation-v1",
            [executed["seq"]],
        )
        records.append(observation_evidence)
        observed = copy.deepcopy(executed)
        observed["seq"] = len(records) + 1
        observed["payload"].update(
            {
                "action_id": "action-observed-v1",
                "stage": "observed",
                "evidence_source": observation_evidence["payload"]["evidence_id"],
                "evidence_seqs": [observation_evidence["seq"]],
            }
        )
        records.append(observed)
        return records

    def revocation_trace(self):
        records = copy.deepcopy(self.late)
        checkpoint = self.event(records, "episode_checkpoint")["seq"]
        response = copy.deepcopy(self.event(records, "transition_response"))
        response["seq"] = len(records) + 1
        response["payload"].update(
            {
                "response_id": "response-revoke-v1",
                "response": "revoke",
                "matching": "current",
                "chosen_branch_id": "none",
                "checkpoint_seq": checkpoint,
            }
        )
        response["payload"]["source_event"].update(
            {
                "event_id": "fixture-user-revocation-v1",
                "evidence_ref": "fixture:user-event-log-v1#event-revoke",
            }
        )
        stage = copy.deepcopy(
            next(
                item for item in records
                if item["kind"] == "transition_stage"
                and item["payload"]["stage"] == "transition_user_confirmed"
            )
        )
        stage["seq"] = len(records) + 2
        stage["payload"].update(
            {"stage": "revoked", "evidence_seqs": [response["seq"]]}
        )
        records.extend([response, stage])
        return records

    def test_v3_is_separate_and_v1_v2_v3_bytes_are_unchanged(self):
        self.assertEqual(self.schema["properties"]["schema_version"]["const"], 3)
        self.assertEqual(set(self.schema["properties"]["kind"]["enum"]), EXPECTED_NEW_KINDS)
        for filename, expected in EXPECTED_TRACE_SHA256.items():
            actual = hashlib.sha256((TRACE_DIR / filename).read_bytes()).hexdigest()
            self.assertEqual(actual, expected, filename)

    def test_primary_fixture_preserves_two_checked_model_only_branches(self):
        validator.validate_trace(
            self.primary, self.schema, scenario="nonblocking_branching_v3"
        )
        branches = self.events(self.primary, "model_branch")
        steps = self.events(self.primary, "model_step")
        checks = self.events(self.primary, "branch_check")
        self.assertEqual(len(branches), 2)
        self.assertEqual(len(steps), 2)
        self.assertEqual(len(checks), 2)
        self.assertEqual(len({b["payload"]["common_checkpoint_seq"] for b in branches}), 1)
        self.assertEqual(len({b["payload"]["difference"] for b in branches}), 2)
        self.assertTrue(all(s["payload"]["effect_scope"] == "model_only" for s in steps))
        self.assertTrue(all(c["payload"]["provenance_seqs"] for c in checks))
        self.assertTrue(all(b["payload"]["budget"]["allocated"] > 0 for b in branches))

    def test_model_selection_does_not_open_the_pending_transition(self):
        selection = self.event(self.primary, "branch_selection")["payload"]
        transition = self.event(self.primary, "pending_transition")["payload"]
        stages = [event["payload"]["stage"] for event in self.events(self.primary, "transition_stage")]
        self.assertIn(selection["status"], {"selected_in_model", "recommended"})
        self.assertEqual(selection["canonical_state"], "candidate_only")
        self.assertEqual(transition["status"], "awaiting_confirmation")
        self.assertEqual(stages, ["closed"])

    def test_late_exact_confirmation_selects_a_saved_alternative_only_in_model(self):
        validator.validate_trace(
            self.late, self.schema, scenario="late_confirmation_v3"
        )
        selections = self.events(self.late, "branch_selection")
        response = self.event(self.late, "transition_response")["payload"]
        confirmed = [
            event for event in self.events(self.late, "transition_stage")
            if event["payload"]["stage"] == "transition_user_confirmed"
        ]
        self.assertEqual(response["matching"], "current")
        self.assertEqual(response["response"], "confirm")
        self.assertEqual(len(confirmed), 1)
        self.assertEqual(selections[-1]["payload"]["status"], "selected_by_user")
        self.assertNotEqual(
            selections[0]["payload"]["selected_branch_id"],
            selections[-1]["payload"]["selected_branch_id"],
        )
        self.assertEqual(selections[-1]["payload"]["canonical_state"], "candidate_only")

    def test_transition_response_requires_exact_ingress_authorization(self):
        mutations = (
            ("missing", None, "ingress_authorization|required"),
            ("status", "denied", "ingress.*allowed|status"),
            ("purpose", "model_selection", "purpose.*transition_response"),
            ("policy_ref", "fixture:wrong-policy", "policy_ref|acceptance_policy"),
        )
        for field, value, pattern in mutations:
            with self.subTest(field=field):
                records = copy.deepcopy(self.late)
                source = self.event(records, "transition_response")["payload"][
                    "source_event"
                ]
                if field == "missing":
                    del source["ingress_authorization"]
                else:
                    source["ingress_authorization"][field] = value
                self.assert_invalid(records, pattern, scenario="late_confirmation_v3")

    def test_stale_refusal_and_revocation_are_distinct(self):
        stale = copy.deepcopy(self.late)
        response = self.event(stale, "transition_response")["payload"]
        response["transition_version"] -= 1
        response["matching"] = "stale"
        response["chosen_branch_id"] = "none"
        stage = next(
            item for item in stale
            if item["kind"] == "transition_stage"
            and item["payload"]["stage"] == "transition_user_confirmed"
        )
        stage["payload"]["stage"] = "stale_response"
        with self.assertRaisesRegex(
            validator.ContractError, "selected_by_user.*stale|exact.*confirmation"
        ):
            validator.validate_trace(stale, self.schema, scenario="late_confirmation_v3")
        stale = self.without_user_selection(stale)
        validator.validate_trace(stale, self.schema, scenario="stale_confirmation_v3")

        refused = copy.deepcopy(self.late)
        response = self.event(refused, "transition_response")["payload"]
        response["response"] = "refuse"
        response["chosen_branch_id"] = "none"
        stage = next(
            item for item in refused
            if item["kind"] == "transition_stage"
            and item["payload"]["stage"] == "transition_user_confirmed"
        )
        stage["payload"]["stage"] = "refused"
        with self.assertRaisesRegex(
            validator.ContractError, "selected_by_user.*confirm|exact.*confirmation"
        ):
            validator.validate_trace(refused, self.schema, scenario="late_confirmation_v3")
        refused = self.without_user_selection(refused)
        validator.validate_trace(refused, self.schema, scenario="refusal_v3")

        revoked = self.revocation_trace()
        validator.validate_trace(revoked, self.schema, scenario="revocation_v3")

        revoked_without_confirmation = copy.deepcopy(self.late)
        response = self.event(revoked_without_confirmation, "transition_response")["payload"]
        response.update({"response": "revoke", "chosen_branch_id": "none"})
        stage = next(
            item for item in revoked_without_confirmation
            if item["kind"] == "transition_stage"
            and item["payload"]["stage"] == "transition_user_confirmed"
        )
        stage["payload"].update({"stage": "revoked", "evidence_source": "user_event"})
        revoked_without_confirmation = self.without_user_selection(
            revoked_without_confirmation
        )
        self.assert_invalid(
            revoked_without_confirmation,
            "revoke.*earlier.*confirm|revoked.*confirmation",
            scenario="revocation_v3",
        )

    def test_scenarios_reject_other_episode_shapes(self):
        self.assert_invalid(
            copy.deepcopy(self.primary),
            "late_confirmation.*confirm|selected_by_user",
            scenario="late_confirmation_v3",
        )
        self.assert_invalid(
            copy.deepcopy(self.limited),
            "late_confirmation.*confirm|selected_by_user",
            scenario="late_confirmation_v3",
        )
        self.assert_invalid(
            copy.deepcopy(self.late),
            "nonblocking.*response|only.*closed|model-only",
            scenario="nonblocking_branching_v3",
        )
        self.assert_invalid(
            copy.deepcopy(self.late),
            "stale_confirmation|stale_response",
            scenario="stale_confirmation_v3",
        )

    def test_response_outcome_stage_requires_exact_ordered_response(self):
        stale = self.without_user_selection(copy.deepcopy(self.late))
        response = self.event(stale, "transition_response")["payload"]
        response.update(
            {"transition_version": 6, "matching": "stale", "chosen_branch_id": "none"}
        )
        stage = next(
            item
            for item in stale
            if item["kind"] == "transition_stage"
            and item["payload"]["stage"] == "transition_user_confirmed"
        )
        stage["payload"].update({"stage": "stale_response", "evidence_seqs": [1]})
        self.assert_invalid(
            stale,
            "stale_response.*response|evidence.*response",
            scenario="stale_confirmation_v3",
        )

        refused = self.without_user_selection(copy.deepcopy(self.late))
        response = self.event(refused, "transition_response")["payload"]
        response.update({"response": "refuse", "chosen_branch_id": "branch-contract-first"})
        stage = next(
            item
            for item in refused
            if item["kind"] == "transition_stage"
            and item["payload"]["stage"] == "transition_user_confirmed"
        )
        stage["payload"].update({"stage": "refused", "evidence_seqs": [15]})
        self.assert_invalid(
            refused,
            "refuse.*chosen_branch_id.*none|refusal.*none",
            scenario="refusal_v3",
        )

        revoked = self.revocation_trace()
        self.event(revoked, "transition_response", -1)["payload"]["matching"] = "stale"
        self.event(revoked, "transition_response", -1)["payload"][
            "transition_version"
        ] -= 1
        self.assert_invalid(
            revoked,
            "revoke.*current|revocation.*current",
            scenario="revocation_v3",
        )

    def test_refusal_or_revocation_resets_external_gate_chain(self):
        revoked = self.revocation_trace()
        execution_after_revoke = self.external_execution_trace(revoked)
        self.assert_invalid(
            execution_after_revoke,
            "revoke.*execution|new.*confirmation|gate.*revoked",
            scenario="revocation_v3",
        )

        reconfirmed = copy.deepcopy(revoked)
        response = copy.deepcopy(self.event(reconfirmed, "transition_response"))
        response["seq"] = len(reconfirmed) + 1
        response["payload"].update(
            {
                "response_id": "response-confirm-v2",
                "response": "confirm",
                "matching": "current",
                "chosen_branch_id": "branch-contract-first",
            }
        )
        response["payload"]["source_event"].update(
            {
                "event_id": "fixture-user-confirmation-v2",
                "evidence_ref": "fixture:user-event-log-v1#event-confirm-2",
            }
        )
        stage = copy.deepcopy(
            next(
                item for item in reconfirmed
                if item["kind"] == "transition_stage"
                and item["payload"]["stage"] == "transition_user_confirmed"
            )
        )
        stage["seq"] = len(reconfirmed) + 2
        stage["payload"]["evidence_seqs"] = [response["seq"]]
        reconfirmed.extend([response, stage])
        validator.validate_trace(
            self.external_execution_trace(reconfirmed),
            self.schema,
            scenario="revocation_v3",
        )

    def test_rejects_mixed_trace_identifiers(self):
        records = copy.deepcopy(self.primary)
        records[-1]["trace_id"] = "different-trace"
        self.assert_invalid(records, "trace_id.*same|mixed.*trace")

    def test_rejects_episode_identifier_drift(self):
        records = copy.deepcopy(self.primary)
        self.events(records, "model_branch")[1]["payload"]["episode_id"] = (
            "different-episode"
        )
        self.assert_invalid(records, "episode_id.*same|episode.*drift")

    def test_rejects_branch_and_step_checkpoint_mismatches(self):
        records = copy.deepcopy(self.primary)
        self.events(records, "model_branch")[0]["payload"]["parent_checkpoint_id"] = (
            "different-checkpoint"
        )
        self.assert_invalid(records, "parent_checkpoint_id|exact.*checkpoint")

        records = copy.deepcopy(self.primary)
        self.event(records, "model_step")["payload"]["parent_checkpoint_seq"] -= 1
        self.assert_invalid(records, "parent_checkpoint_seq|exact.*checkpoint")

    def test_rejects_branch_cost_and_final_episode_budget_mismatches(self):
        records = copy.deepcopy(self.primary)
        self.event(records, "model_step")["payload"]["budget_cost"] = 0
        self.assert_invalid(records, "budget_cost.*consumed|branch.*budget")

        records = copy.deepcopy(self.primary)
        final = self.event(records, "episode_state", -1)["payload"]["budget"]
        final["consumed"] -= 1
        final["remaining"] += 1
        self.event(records, "episode_checkpoint")["payload"]["remaining_budget"] = final[
            "remaining"
        ]
        self.assert_invalid(records, "episode.*budget.*branches|sum.*branch")

    def test_rejects_transition_coordinate_drift_in_stages_and_checkpoints(self):
        for kind, field, value, pattern in (
            ("transition_stage", "transition_version", 8, "transition.*version"),
            ("model_checkpoint", "transition_id", "other-transition", "checkpoint.*transition"),
            ("episode_checkpoint", "transition_version", 8, "checkpoint.*transition|version"),
        ):
            with self.subTest(kind=kind, field=field):
                records = copy.deepcopy(self.primary)
                self.event(records, kind)["payload"][field] = value
                self.assert_invalid(records, pattern)

    def test_selected_by_user_requires_exact_linked_confirmation_evidence(self):
        mutations = (
            ("transition_response_seq", 14, "transition_response_seq|exact.*response"),
            ("selected_branch_id", "branch-contract-first", "chosen_branch|selected.*branch"),
            ("evidence_seqs", [8, 11, 13], "evidence.*confirm|response.*evidence"),
        )
        for field, value, pattern in mutations:
            with self.subTest(field=field):
                records = copy.deepcopy(self.late)
                self.event(records, "branch_selection", -1)["payload"][field] = value
                self.assert_invalid(records, pattern, scenario="late_confirmation_v3")

    def test_branch_selection_evidence_covers_each_considered_branch(self):
        records = copy.deepcopy(self.primary)
        self.event(records, "branch_selection")["payload"]["evidence_seqs"] = [8]
        self.assert_invalid(records, "evidence.*branch_check|considered.*branch")

        records = copy.deepcopy(self.primary)
        self.event(records, "branch_selection")["payload"]["evidence_seqs"] = [8, 14]
        self.assert_invalid(records, "evidence.*earlier|only.*back")

        records = copy.deepcopy(self.primary)
        selection = self.event(records, "branch_selection")["payload"]
        selection["untested_branch_ids"] = ["untested-branch"]
        self.assert_invalid(records, "ambiguity_resolved.*untested|untested.*ambiguity")

    def test_external_execution_requires_actions_and_role_specific_evidence(self):
        records = self.external_execution_trace()
        validator.validate_trace(records, self.schema, scenario="late_confirmation_v3")

        action_coordinate_drift = copy.deepcopy(records)
        self.event(action_coordinate_drift, "transition_action")["payload"][
            "transition_version"
        ] += 1
        self.assert_invalid(
            action_coordinate_drift,
            "transition_action.*transition.*version|different.*transition",
            scenario="late_confirmation_v3",
        )

        without_executed_action = copy.deepcopy(records)
        self.event(without_executed_action, "transition_action")["kind"] = (
            "transition_stage"
        )
        self.assert_invalid(
            without_executed_action,
            "executed.*transition_action|action.*executed",
            scenario="late_confirmation_v3",
        )

        arbitrary_model_evidence = copy.deepcopy(records)
        executed = self.event(arbitrary_model_evidence, "transition_action")["payload"]
        executed["evidence_source"] = "model_summary"
        executed["evidence_seqs"] = [7]
        self.assert_invalid(
            arbitrary_model_evidence,
            "external_evidence|evidence_source|model.*evidence",
            scenario="late_confirmation_v3",
        )

        wrong_observation_role = copy.deepcopy(records)
        self.event(wrong_observation_role, "transition_action", -1)["payload"][
            "evidence_source"
        ] = "executor_adapter"
        self.assert_invalid(
            wrong_observation_role,
            "observed.*evidence_source|result_observation",
            scenario="late_confirmation_v3",
        )

        without_executed_action = copy.deepcopy(records)
        without_executed_action = [
            item
            for item in without_executed_action
            if not (
                item["kind"] == "transition_action"
                and item["payload"]["stage"] == "executed"
            )
        ]
        observation_evidence = next(
            item
            for item in without_executed_action
            if item["kind"] == "external_evidence"
            and item["payload"]["evidence_kind"] == "result_observation"
        )
        observation_evidence["payload"]["basis_seqs"] = [22]
        self.renumber(without_executed_action)
        self.event(without_executed_action, "transition_action", -1)["payload"][
            "evidence_seqs"
        ] = [observation_evidence["seq"]]
        self.assert_invalid(
            without_executed_action,
            "observed.*executed.*action|earlier.*executed",
            scenario="late_confirmation_v3",
        )

    def test_external_gates_require_matching_external_evidence(self):
        records = self.external_execution_trace()

        self_labeled_gate = copy.deepcopy(records)
        authorized = next(
            item
            for item in self_labeled_gate
            if item["kind"] == "transition_stage"
            and item["payload"]["stage"] == "authorized"
        )["payload"]
        authorized.update({"evidence_source": "authority_policy", "evidence_seqs": [1]})
        self.assert_invalid(
            self_labeled_gate,
            "external_evidence|matching.*evidence",
            scenario="late_confirmation_v3",
        )

        wrong_outcome = copy.deepcopy(records)
        self.event(wrong_outcome, "external_evidence")["payload"]["outcome"] = "passed"
        self.assert_invalid(
            wrong_outcome,
            "authority_decision.*allowed|kind.*outcome",
            scenario="late_confirmation_v3",
        )

        wrong_effect = copy.deepcopy(records)
        self.event(wrong_effect, "external_evidence")["payload"]["expected_effect"][
            "target_ref"
        ] = "fixture:other-target"
        self.assert_invalid(
            wrong_effect,
            "expected_effect|exact.*effect",
            scenario="late_confirmation_v3",
        )

        future_basis = copy.deepcopy(records)
        evidence = self.event(future_basis, "external_evidence")["payload"]
        evidence["basis_seqs"] = [len(future_basis)]
        self.assert_invalid(
            future_basis,
            "basis.*earlier",
            scenario="late_confirmation_v3",
        )

        duplicate_identity = copy.deepcopy(records)
        evidences = self.events(duplicate_identity, "external_evidence")
        evidences[1]["payload"]["evidence_id"] = evidences[0]["payload"]["evidence_id"]
        self.assert_invalid(
            duplicate_identity,
            "evidence_id.*unique|duplicate.*evidence",
            scenario="late_confirmation_v3",
        )

        duplicate_source = copy.deepcopy(records)
        evidences = self.events(duplicate_source, "external_evidence")
        evidences[1]["payload"]["source_ref"] = evidences[0]["payload"]["source_ref"]
        self.assert_invalid(
            duplicate_source,
            "source_ref.*unique|duplicate.*source",
            scenario="late_confirmation_v3",
        )

    def test_rejects_execution_without_all_independent_gates(self):
        records = copy.deepcopy(self.primary)
        closed = self.event(records, "transition_stage")
        closed["payload"].update(
            {"stage": "executed", "evidence_source": "executor_adapter", "evidence_seqs": [1]}
        )
        self.assert_invalid(records, "confirmation.*authorization.*preflight")

    def test_rejects_model_choice_promoted_to_authorization_or_canonical_state(self):
        for field, value, pattern in (
            ("canonical_state", "accepted", "canonical"),
            ("status", "authorized", "schema|enum|selection"),
        ):
            with self.subTest(field=field):
                records = copy.deepcopy(self.primary)
                self.event(records, "branch_selection")["payload"][field] = value
                self.assert_invalid(records, pattern)

    def test_rejects_branch_without_common_ancestor_or_budget(self):
        records = copy.deepcopy(self.primary)
        self.events(records, "model_branch")[1]["payload"]["common_checkpoint_seq"] -= 1
        self.assert_invalid(records, "common.*checkpoint|ancestor")

        records = copy.deepcopy(self.primary)
        del self.events(records, "model_branch")[0]["payload"]["budget"]
        self.assert_invalid(records, "budget|required")

    def test_rejects_missing_or_insufficient_independent_storage_policy(self):
        records = copy.deepcopy(self.primary)
        del self.event(records, "task")["payload"]["storage_policy"]
        self.assert_invalid(records, "storage_policy|required")

        records = copy.deepcopy(self.primary)
        policy = self.event(records, "task")["payload"]["storage_policy"]
        policy["allowed_record_classes"].remove("candidate")
        self.assert_invalid(records, "storage policy.*candidate")

    def test_rejects_record_after_terminal_episode_state(self):
        records = copy.deepcopy(self.limited)
        terminal = self.event(records, "episode_state", -1)
        terminal["payload"]["state"] = "failed"
        terminal["payload"]["reason"] = "fixture terminal stop"
        extra = copy.deepcopy(self.event(records, "episode_checkpoint"))
        extra["seq"] = len(records) + 1
        records.append(extra)
        self.assert_invalid(records, "terminal.*final|after terminal")

    def test_rejects_false_ambiguity_resolution_from_one_attempt(self):
        records = copy.deepcopy(self.limited)
        selection = self.event(records, "branch_selection")["payload"]
        selection["ambiguity_resolved"] = True
        self.assert_invalid(
            records,
            "one.*branch|single.*branch|ambiguity",
            scenario="single_branch_limited_budget_v3",
        )

    def test_rejects_unresolved_conflict_while_a_check_fits_the_budget(self):
        records = copy.deepcopy(self.primary)
        final_checkpoint = self.event(records, "episode_checkpoint")["payload"]
        final_checkpoint["distinguishing_checks_remaining"] = 1
        final_checkpoint["remaining_budget"] = 1
        episode = self.event(records, "episode_state", -1)["payload"]
        episode["state"] = "unresolved_conflict"
        episode["reason"] = "branches still differ"
        episode["distinguishing_checks_remaining"] = 1
        episode["budget"]["remaining"] = 1
        self.assert_invalid(records, "unresolved_conflict.*check|distinguishing")

    def test_final_episode_state_must_match_latest_checkpoint_counters(self):
        unresolved = copy.deepcopy(self.late)
        checkpoint = self.event(unresolved, "episode_checkpoint")["payload"]
        checkpoint["distinguishing_checks_remaining"] = 1
        final = self.event(unresolved, "episode_state", -1)["payload"]
        final.update(
            {
                "state": "unresolved_conflict",
                "reason": "counter mismatch must not hide a remaining check",
                "distinguishing_checks_remaining": 0,
            }
        )
        self.assert_invalid(
            unresolved,
            "checkpoint.*distinguishing|counter.*match",
            scenario="late_confirmation_v3",
        )

        needs_input = copy.deepcopy(self.late)
        checkpoint = self.event(needs_input, "episode_checkpoint")["payload"]
        checkpoint["productive_continuations_remaining"] = 1
        final = self.event(needs_input, "episode_state", -1)["payload"]
        final.update(
            {
                "state": "needs_input",
                "reason": "counter mismatch must not hide productive continuation",
                "safe_productive_continuations_remaining": 0,
            }
        )
        self.assert_invalid(
            needs_input,
            "checkpoint.*productive|counter.*match",
            scenario="late_confirmation_v3",
        )

    def test_single_branch_fixture_preserves_untested_alternatives_and_budget_limit(self):
        validator.validate_trace(
            self.limited,
            self.schema,
            scenario="single_branch_limited_budget_v3",
        )
        selection = self.event(self.limited, "branch_selection")["payload"]
        episode = self.event(self.limited, "episode_state", -1)["payload"]
        self.assertEqual(len(selection["considered_branch_ids"]), 1)
        self.assertTrue(selection["untested_branch_ids"])
        self.assertFalse(selection["ambiguity_resolved"])
        self.assertEqual(episode["state"], "needs_input")
        self.assertEqual(episode["budget"]["remaining"], 0)

    def test_single_branch_scenario_requires_checkpoint_terminal_state_and_zero_budget(self):
        no_checkpoint = [
            item
            for item in copy.deepcopy(self.limited)
            if item["kind"] != "episode_checkpoint"
        ]
        self.renumber(no_checkpoint)
        self.assert_invalid(
            no_checkpoint,
            "single.*episode_checkpoint|checkpoint.*required",
            scenario="single_branch_limited_budget_v3",
        )

        wrong_state = copy.deepcopy(self.limited)
        self.event(wrong_state, "episode_state", -1)["payload"]["state"] = (
            "model_selection_preserved"
        )
        self.assert_invalid(
            wrong_state,
            "single.*needs_input|final.*needs_input",
            scenario="single_branch_limited_budget_v3",
        )

        budget_left = copy.deepcopy(self.limited)
        final_budget = self.event(budget_left, "episode_state", -1)["payload"]["budget"]
        final_budget.update({"consumed": 1, "remaining": 1})
        self.assert_invalid(
            budget_left,
            "single.*budget|remaining.*zero|exhausted",
            scenario="single_branch_limited_budget_v3",
        )

    def test_rejects_needs_input_while_safe_productive_work_remains(self):
        records = copy.deepcopy(self.late)
        episode = self.event(records, "episode_state", -1)["payload"]
        episode["state"] = "needs_input"
        episode["reason"] = "safe productive work still remains"
        episode["safe_productive_continuations_remaining"] = 1
        checkpoint = self.event(records, "episode_checkpoint")["payload"]
        checkpoint["productive_continuations_remaining"] = 1
        self.assert_invalid(
            records,
            "needs_input.*productive|safe.*continuation",
            scenario="late_confirmation_v3",
        )

    def test_rejects_hidden_reasoning_network_secret_or_external_effect(self):
        mutations = (
            ("task", "chain_of_thought", "hidden", "unknown|reasoning"),
            ("model_step", "provider_id", "https://example.invalid/model", "network|provider"),
            ("model_step", "effect_scope", "external", "model_only|enum"),
            ("model_step", "summary", "token=fixture-secret", "secret"),
        )
        for kind, field, value, pattern in mutations:
            with self.subTest(kind=kind, field=field):
                records = copy.deepcopy(self.primary)
                self.event(records, kind)["payload"][field] = value
                self.assert_invalid(records, pattern)

    def test_runtime_policy_is_fail_closed_and_matches_the_episode(self):
        for field in (
            "network_access",
            "secret_access",
            "live_model",
            "external_services",
            "publication",
            "physical_action",
        ):
            with self.subTest(capability=field):
                records = copy.deepcopy(self.primary)
                policy = self.event(records, "task")["payload"]["model_runtime_policy"]
                policy[field] = True
                self.assert_invalid(records, f"{field}|capabilit|offline")

        for field, value, pattern in (
            ("mode", "live_provider", "mode|deterministic_local_fixture"),
            ("reasoning_recording", "full", "reasoning_recording|summaries_only"),
            ("max_branches", 1, "max_branches|actual.*branch"),
            ("initial_budget", 6, "initial_budget|episode.*budget"),
        ):
            with self.subTest(field=field):
                records = copy.deepcopy(self.primary)
                policy = self.event(records, "task")["payload"]["model_runtime_policy"]
                policy[field] = value
                self.assert_invalid(records, pattern)

    def test_fixtures_are_canonical_jsonl_and_validate_through_local_api(self):
        for path, scenario in (
            (PRIMARY_PATH, "nonblocking_branching_v3"),
            (LATE_PATH, "late_confirmation_v3"),
            (LIMITED_PATH, "single_branch_limited_budget_v3"),
        ):
            raw = path.read_bytes()
            self.assertTrue(raw.endswith(b"\n"), path)
            lines = raw.decode("utf-8").splitlines()
            parsed = [json.loads(line) for line in lines]
            self.assertEqual(parsed, validator.load_trace(path))
            validator.validate_trace(parsed, self.schema, scenario=scenario)


if __name__ == "__main__":
    unittest.main()
