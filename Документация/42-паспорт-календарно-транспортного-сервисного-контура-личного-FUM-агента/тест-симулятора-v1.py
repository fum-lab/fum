#!/usr/bin/env python3
"""Автономная приёмка модельного календарно-транспортного контура v1."""

from __future__ import annotations

import copy
import importlib.util
import json
import unittest
from pathlib import Path


BASE = Path(__file__).resolve().parent
SIMULATOR_PATH = BASE / "симулятор-v1.py"
FIXTURES_PATH = BASE / "фикстуры-сценариев-v1.json"
SCHEMA_PATH = BASE / "схема-набора-фикстур-v1.json"

SPEC = importlib.util.spec_from_file_location("fum_calendar_transport_simulator_v1", SIMULATOR_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Не удалось загрузить {SIMULATOR_PATH.name}")
SIMULATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SIMULATOR)


class CalendarTransportSimulatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fixture_set = json.loads(FIXTURES_PATH.read_text(encoding="utf-8"))
        cls.fixtures = cls.fixture_set["fixtures"]

    def test_schema_and_fixture_set_have_exact_version(self) -> None:
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
        self.assertEqual("https://json-schema.org/draft/2020-12/schema", schema["$schema"])
        self.assertEqual(1, self.fixture_set["schema_version"])
        self.assertEqual(10, len(self.fixtures))

    def test_every_fixture_reproduces_expected_decision(self) -> None:
        for fixture in self.fixtures:
            with self.subTest(fixture_id=fixture["fixture_id"]):
                report = SIMULATOR.simulate_fixture(fixture, self.fixture_set)
                self.assertEqual(fixture["expected"]["decision"], report["decision"])
                self.assertEqual(fixture["expected"]["reason_code"], report["reason_code"])
                self.assertEqual(fixture["expected"]["public_conflict"], report["public_conflict"])
                self.assertEqual("none", report["external_effect"])

    def test_report_preserves_safe_provenance_and_event_order(self) -> None:
        report = SIMULATOR.simulate_fixture(self.fixtures[2], self.fixture_set)
        self.assertEqual("taxi-order.confirmed", report["provenance"]["fixture_id"])
        self.assertEqual(self.fixture_set["source_refs"], report["provenance"]["source_refs"])
        self.assertRegex(report["provenance"]["fixture_sha256"], r"^sha256:[0-9a-f]{64}$")
        self.assertEqual(
            ["intent", "access_check", "guard_check", "confirmation_check", "adapter_fixture", "decision"],
            [event["type"] for event in report["trace"]],
        )

    def test_private_values_never_leave_report(self) -> None:
        for fixture in self.fixtures:
            with self.subTest(fixture_id=fixture["fixture_id"]):
                report = SIMULATOR.simulate_fixture(fixture, self.fixture_set)
                serialized = json.dumps(report, ensure_ascii=False, sort_keys=True)
                for private_value in fixture["private_payload"].values():
                    self.assertNotIn(private_value, serialized)
                self.assertEqual(
                    sorted(f"private_payload.{key}" for key in fixture["private_payload"]),
                    report["redacted_fields"],
                )

    def test_changed_confirmation_snapshot_requires_new_confirmation(self) -> None:
        fixture = copy.deepcopy(self.fixtures[2])
        fixture["operation"]["state_fingerprint"] = "state.taxi.changed"
        report = SIMULATOR.simulate_fixture(fixture, self.fixture_set)
        self.assertEqual("reconfirmation_required", report["decision"])
        self.assertEqual("confirmation_snapshot_mismatch", report["reason_code"])
        self.assertNotIn("adapter_fixture", [event["type"] for event in report["trace"]])

    def test_expired_confirmation_requires_new_confirmation(self) -> None:
        fixture = copy.deepcopy(self.fixtures[2])
        fixture["confirmation"]["valid_until"] = "2030-01-15T08:59:59Z"
        report = SIMULATOR.simulate_fixture(fixture, self.fixture_set)
        self.assertEqual("reconfirmation_required", report["decision"])
        self.assertEqual("confirmation_expired", report["reason_code"])

    def test_unknown_operation_is_rejected_without_echoing_private_payload(self) -> None:
        fixture = copy.deepcopy(self.fixtures[0])
        fixture["operation"]["kind"] = "unknown_private_operation"
        with self.assertRaisesRegex(SIMULATOR.ContractError, "operation.kind") as context:
            SIMULATOR.simulate_fixture(fixture, self.fixture_set)
        self.assertNotIn("SYNTHETIC_PRIVATE_ORIGIN", str(context.exception))


if __name__ == "__main__":
    unittest.main(verbosity=2)
