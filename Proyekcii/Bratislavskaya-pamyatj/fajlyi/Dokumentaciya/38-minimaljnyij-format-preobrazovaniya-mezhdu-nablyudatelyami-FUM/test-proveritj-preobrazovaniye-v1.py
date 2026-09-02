#!/usr/bin/env python3
"""Автономные тесты пути исходного запроса в преобразовании v1."""

from __future__ import annotations

import importlib.util
import json
import unittest
from pathlib import Path


BASE = Path(__file__).resolve().parent
VALIDATOR_PATH = BASE / "проверить-преобразование-v1.py"
FIXTURES = (
    BASE / "фикстура-обратимого-преобразования.json",
    BASE / "фикстура-необратимого-преобразования.json",
)
CANONICAL_REQUEST = (
    "Журнал/"
    "2026-07-23_11-50-58_MSK_"
    "описать-минимальный-формат-преобразования-между-наблюдателями-FUM/"
    "запрос.md"
)

SPEC = importlib.util.spec_from_file_location("fum_transformation_validator_v1", VALIDATOR_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Не удалось загрузить {VALIDATOR_PATH}")
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


class TransformationRequestReferenceTests(unittest.TestCase):
    def test_live_fixtures_use_the_canonical_request_path(self) -> None:
        for fixture in FIXTURES:
            with self.subTest(fixture=fixture.name):
                data = json.loads(fixture.read_text(encoding="utf-8"))
                self.assertIn(CANONICAL_REQUEST, data["provenance_refs"])
                self.assertFalse(
                    any(ref.startswith("Запросы/") for ref in data["provenance_refs"])
                )

    def test_request_reference_requires_an_exact_calendar_valid_path(self) -> None:
        accepted = (
            CANONICAL_REQUEST,
            "Журнал/2026-07-23_11-50-58_MSK/запрос.md",
        )
        rejected = (
            "Запросы/2026-07-23_11-50-58_MSK_x.md",
            "Журнал/2026-02-30_11-50-58_MSK_x/запрос.md",
            "Журнал/2026-07-23_11-50-58_MSK_/запрос.md",
            "Журнал/2026-07-23_11-50-58_MSK_x/отчёт.md",
            "Журнал/2026-07-23_11-50-58_MSK_x/материалы/запрос.md",
        )

        for reference in accepted:
            with self.subTest(reference=reference):
                self.assertTrue(VALIDATOR.is_canonical_request_ref(reference))
        for reference in rejected:
            with self.subTest(reference=reference):
                self.assertFalse(VALIDATOR.is_canonical_request_ref(reference))


if __name__ == "__main__":
    unittest.main(verbosity=2)
