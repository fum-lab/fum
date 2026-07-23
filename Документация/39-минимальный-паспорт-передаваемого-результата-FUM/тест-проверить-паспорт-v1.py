#!/usr/bin/env python3
"""Автономные положительные и отрицательные тесты валидатора паспорта FUM v1."""

from __future__ import annotations

import copy
import importlib.util
import json
import unittest
from pathlib import Path


BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
VALIDATOR_PATH = BASE / "проверить-паспорт-v1.py"
EXAMPLE_PATH = BASE / "пример-паспорта-FUM-STEP-0025.json"

SPEC = importlib.util.spec_from_file_location("fum_passport_validator_v1", VALIDATOR_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Не удалось загрузить {VALIDATOR_PATH}")
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


class PassportValidatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.example = json.loads(EXAMPLE_PATH.read_text(encoding="utf-8"))

    def errors_for(self, mutation) -> list[str]:
        passport = copy.deepcopy(self.example)
        mutation(passport)
        return VALIDATOR.validate_passport(passport, EXAMPLE_PATH, ROOT)

    def assert_rejected(self, mutation, expected_fragment: str) -> None:
        errors = self.errors_for(mutation)
        self.assertTrue(errors, "Отрицательная мутация неожиданно принята")
        self.assertTrue(
            any(expected_fragment in error for error in errors),
            f"В ошибках нет {expected_fragment!r}:\n" + "\n".join(errors),
        )

    def test_positive_example(self) -> None:
        errors = VALIDATOR.validate_passport(copy.deepcopy(self.example), EXAMPLE_PATH, ROOT)
        self.assertEqual([], errors)

    def test_optional_transformation_ref_can_point_to_record(self) -> None:
        errors = self.errors_for(
            lambda passport: passport["transfers"][0].__setitem__(
                "transformation_ref",
                "Документация/38-минимальный-формат-преобразования-между-наблюдателями-FUM/фикстура-обратимого-преобразования.json",
            )
        )
        self.assertEqual([], errors)

    def test_unknown_root_field_is_rejected(self) -> None:
        self.assert_rejected(lambda passport: passport.__setitem__("extra", True), "неизвестные поля запрещены")

    def test_duplicate_artifact_id_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["result"]["artifacts"][1].__setitem__(
                "artifact_id", passport["result"]["artifacts"][0]["artifact_id"]
            ),
            "дубликат artifact_id",
        )

    def test_mixed_artifact_state_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["result"]["artifacts"][0].__setitem__("state_ref", "sha256:" + "0" * 64),
            "единым $.result.state_ref",
        )

    def test_dangling_check_subject_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["verification"][0]["subject_artifact_ids"].append("missing-artifact"),
            "неизвестный artifact_id",
        )

    def test_passed_check_without_evidence_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["verification"][0].__setitem__("evidence_refs", []),
            "статус passed требует свидетельство",
        )

    def test_negative_measured_cost_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["cost"]["actual"]["items"][0].__setitem__("amount", -1),
            "требует конечное число >= 0",
        )

    def test_unknown_cost_cannot_be_zero(self) -> None:
        self.assert_rejected(
            lambda passport: passport["cost"]["actual"]["items"][1].__setitem__("amount", 0),
            "неизвестное не равно нулю",
        )

    def test_dangling_confidence_basis_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["confidence"]["basis_check_ids"].append("missing-check"),
            "неизвестный check_id",
        )

    def test_confidence_outside_unit_interval_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["confidence"].__setitem__("value", 1.01),
            "число от 0 до 1",
        )

    def test_duplicate_recipient_is_rejected(self) -> None:
        def mutate(passport: dict) -> None:
            passport["recipients"].append(copy.deepcopy(passport["recipients"][0]))

        self.assert_rejected(mutate, "дубликат recipient_id")

    def test_dangling_transfer_recipient_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["transfers"][0].__setitem__("recipient_id", "missing-recipient"),
            "неизвестный recipient_id",
        )

    def test_delivered_transfer_without_evidence_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["transfers"][0].__setitem__("evidence_refs", []),
            "статус delivered требует свидетельство",
        )

    def test_transfer_cannot_add_implicit_quality_claim(self) -> None:
        self.assert_rejected(
            lambda passport: passport["transfers"][0].__setitem__("quality_status", "accepted"),
            "неизвестные поля запрещены",
        )

    def test_absolute_local_ref_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["provenance"].__setitem__("producer_ref", "/Users/example/private.md"),
            "машинно-локальный абсолютный путь запрещён",
        )

    def test_private_https_ref_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["provenance"]["origin"].__setitem__(
                "repository_ref", "https://127.0.0.1/fum"
            ),
            "приватный или локальный URL запрещён",
        )

    def test_secret_query_ref_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["provenance"]["origin"].__setitem__(
                "repository_ref", "https://github.com/fum-lab/fum?access_token=secret"
            ),
            "похожий на секрет параметр URL запрещён",
        )

    def test_private_transformation_ref_is_rejected(self) -> None:
        self.assert_rejected(
            lambda passport: passport["transfers"][0].__setitem__(
                "transformation_ref", "https://localhost/transformation.json"
            ),
            "приватный или локальный URL запрещён",
        )

    def test_missing_git_commit_is_rejected(self) -> None:
        missing_commit = "f" * 40

        def mutate(passport: dict) -> None:
            passport["provenance"]["origin"]["commit"]["value"] = missing_commit
            passport["result"]["state_ref"] = f"git:commit:{missing_commit}"
            for artifact in passport["result"]["artifacts"]:
                artifact["state_ref"] = f"git:commit:{missing_commit}"

        self.assert_rejected(mutate, "Git-коммит не найден")


if __name__ == "__main__":
    unittest.main(verbosity=2)
