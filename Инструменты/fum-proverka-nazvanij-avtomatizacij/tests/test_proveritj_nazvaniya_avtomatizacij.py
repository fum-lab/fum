import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


AUTOMATION_DIR = Path(__file__).resolve().parents[1]
SCRIPT_PATH = (
    AUTOMATION_DIR
    / "scripts"
    / "proveritj-nazvaniya-avtomatizacij.py"
)

spec = importlib.util.spec_from_file_location(
    "proveritj_nazvaniya_avtomatizacij",
    SCRIPT_PATH,
)
proveritj_nazvaniya_avtomatizacij = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = proveritj_nazvaniya_avtomatizacij
spec.loader.exec_module(proveritj_nazvaniya_avtomatizacij)


SCHEMA = "fum.automation-names.v1"
REVISION = "837e2ce107b97ee7b9d3344c9fe99142281fe393"
DEPENDENCY_PATH = "Зависимости/LinguisticKit"
FORK_REPOSITORY = "https://github.com/fum-lab/LinguisticKit.git"
UPSTREAM_REPOSITORY = "https://github.com/Roman-Kerimov/LinguisticKit.git"

GOLDEN_ENTRIES = [
    {
        "source": "проверка названий автоматизаций",
        "transliteration": "proverka nazvanij avtomatizacij",
        "slug": "fum-proverka-nazvanij-avtomatizacij",
    },
    {
        "source": "автоматизации",
        "transliteration": "avtomatizacii",
        "slug": "fum-avtomatizacii",
    },
    {
        "source": "имён",
        "transliteration": "imyon",
        "slug": "fum-imyon",
    },
    {
        "source": "следующий шаг ветки",
        "transliteration": "sleduyusjhij shag vetki",
        "slug": "fum-sleduyusjhij-shag-vetki",
    },
    {
        "source": "прототипы",
        "transliteration": "prototipyi",
        "slug": "fum-prototipyi",
    },
]


class RepositoryFixture:
    def __init__(self, root: Path):
        self.root = root
        self.registry_path = (
            root / "Инструменты" / "реестр-названий-автоматизаций.json"
        )
        self.registry = {
            "schema": SCHEMA,
            "linguistic_kit": {
                "path": DEPENDENCY_PATH,
                "fork_repository": FORK_REPOSITORY,
                "upstream_repository": UPSTREAM_REPOSITORY,
                "revision": REVISION,
                "source_script": "Cyrl",
                "target_script": "Latn",
                "table": "ru",
                "materialization": {
                    "status": "ready",
                },
            },
            "golden": [
                {
                    "source": entry["source"],
                    "transliteration": entry["transliteration"],
                }
                for entry in GOLDEN_ENTRIES
            ],
            "current": [dict(entry) for entry in GOLDEN_ENTRIES],
            "legacy_display": ["построение описания FUM для адресата"],
            "legacy": ["fum-legacy-example"],
        }
        self.mapping = {
            entry["source"]: entry["transliteration"]
            for entry in GOLDEN_ENTRIES
        }
        self.transformer_path = root / "fake-transformer.py"

        (root / "Инструменты").mkdir(parents=True)
        (root / DEPENDENCY_PATH).mkdir(parents=True)
        self.sync_automation_directories()
        self.write_registry()
        self.write_transformer()

    @property
    def transformer_command(self) -> list[str]:
        return [sys.executable, str(self.transformer_path)]

    def write_skill(self, slug: str, *, skill_name: str | None = None) -> None:
        directory = self.root / "Инструменты" / slug
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "SKILL.md").write_text(
            "---\n"
            f"name: {skill_name or slug}\n"
            "description: Тестовая автоматизация.\n"
            "---\n\n"
            f"# {slug}\n",
            encoding="utf-8",
        )

    def sync_automation_directories(self) -> None:
        for entry in self.registry["current"]:
            slug = entry.get("slug")
            if isinstance(slug, str):
                self.write_skill(slug)
        for slug in self.registry["legacy"]:
            if isinstance(slug, str):
                self.write_skill(slug)

    def write_registry(self) -> None:
        self.registry_path.write_text(
            json.dumps(self.registry, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def write_transformer(self) -> None:
        self.transformer_path.write_text(
            "import json\n"
            "import sys\n"
            f"mapping = {self.mapping!r}\n"
            "values = json.load(sys.stdin)\n"
            "json.dump([mapping.get(value, value) for value in values], "
            "sys.stdout, ensure_ascii=False)\n",
            encoding="utf-8",
        )

    def validate(self) -> list[str]:
        return proveritj_nazvaniya_avtomatizacij.validate_repository(
            self.root,
            self.registry_path,
            self.transformer_command,
        )


class AutomationNamesValidationTests(unittest.TestCase):
    def test_accepts_golden_linguistic_kit_vectors(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))

            self.assertEqual(fixture.validate(), [])

    def test_rejects_noncanonical_transliteration(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            entry = fixture.registry["current"][-1]
            entry["source"] = "рабочие прототипы"
            entry["transliteration"] = "rabochiye prototipy"
            entry["slug"] = "fum-rabochiye-prototipy"
            fixture.mapping["рабочие прототипы"] = "rabochiye prototipyi"
            fixture.write_skill("fum-rabochiye-prototipy")
            fixture.write_registry()
            fixture.write_transformer()

            errors = fixture.validate()

            self.assertTrue(
                any(
                    "rabochiye prototipyi" in error
                    and "rabochiye prototipy" in error
                    and "LinguisticKit" in error
                    for error in errors
                ),
                errors,
            )

    def test_rejects_missing_or_non_cyrillic_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.registry["current"][0].pop("source")
            fixture.registry["current"][1]["source"] = "automation names"
            fixture.write_registry()

            errors = fixture.validate()

            self.assertTrue(any("source" in error and "отсутствует" in error for error in errors), errors)
            self.assertTrue(any("кириллиц" in error for error in errors), errors)

    def test_rejects_cyrillic_uppercase_underscore_and_space_in_slugs(self):
        invalid_slugs = [
            "fum-прототипы",
            "fum-Prototipyi",
            "fum_prototipyi",
            "fum-prototipyi name",
        ]

        for invalid_slug in invalid_slugs:
            with self.subTest(slug=invalid_slug):
                with tempfile.TemporaryDirectory() as tmp:
                    fixture = RepositoryFixture(Path(tmp))
                    fixture.registry["current"][-1]["slug"] = invalid_slug
                    fixture.write_skill(invalid_slug)
                    fixture.write_registry()

                    errors = fixture.validate()

                    self.assertTrue(
                        any("недопустимый slug" in error for error in errors),
                        errors,
                    )

    def test_rejects_skill_name_and_directory_mismatch(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            slug = fixture.registry["current"][0]["slug"]
            fixture.write_skill(slug, skill_name="fum-drugoye-imya")

            errors = fixture.validate()

            self.assertTrue(
                any("SKILL.md" in error and "fum-drugoye-imya" in error for error in errors),
                errors,
            )

    def test_rejects_duplicate_sources_slugs_and_legacy_overlap(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            duplicate = dict(fixture.registry["current"][0])
            fixture.registry["current"].append(duplicate)
            fixture.registry["legacy"].append(duplicate["slug"])
            fixture.write_registry()

            errors = fixture.validate()

            self.assertTrue(any("повторяется source" in error for error in errors), errors)
            self.assertTrue(any("коллиз" in error for error in errors), errors)
            self.assertTrue(any("current" in error and "legacy" in error for error in errors), errors)

    def test_rejects_discovered_unregistered_automation(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.write_skill("fum-neuchetnaya-avtomatizaciya")

            errors = fixture.validate()

            self.assertTrue(
                any("fum-neuchetnaya-avtomatizaciya" in error and "не зарегистрирован" in error for error in errors),
                errors,
            )

    def test_rejects_stale_legacy_allowlist_entry(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.registry["legacy"].append("fum-missing-legacy")
            fixture.write_registry()

            errors = fixture.validate()

            self.assertTrue(
                any("fum-missing-legacy" in error and "каталог не найден" in error for error in errors),
                errors,
            )

    def test_missing_dependency_requires_explicit_blocked_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            shutil.rmtree(fixture.root / DEPENDENCY_PATH)

            errors = fixture.validate()

            self.assertTrue(
                any("материализ" in error and "blocked" in error for error in errors),
                errors,
            )

    def test_rejects_changed_pinned_dependency_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.registry["linguistic_kit"]["revision"] = "0" * 40
            fixture.write_registry()

            errors = fixture.validate()

            self.assertTrue(
                any("linguistic_kit.revision" in error and REVISION in error for error in errors),
                errors,
            )

            fixture.registry["linguistic_kit"]["revision"] = REVISION
            fixture.registry["linguistic_kit"]["fork_repository"] = (
                UPSTREAM_REPOSITORY
            )
            fixture.write_registry()

            errors = fixture.validate()

            self.assertTrue(
                any(
                    "linguistic_kit.fork_repository" in error
                    and FORK_REPOSITORY in error
                    for error in errors
                ),
                errors,
            )

    def test_blocked_dependency_passes_structurally_with_warning(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            shutil.rmtree(fixture.root / DEPENDENCY_PATH)
            fixture.registry["linguistic_kit"]["materialization"] = {
                "status": "blocked",
                "reason": "публичный форк ещё не создан",
            }
            fixture.write_registry()

            report = proveritj_nazvaniya_avtomatizacij.validate_repository_report(
                fixture.root,
                fixture.registry_path,
                fixture.transformer_command,
            )

            self.assertEqual(report.errors, [])
            self.assertTrue(
                any("LinguisticKit" in warning and "не выполнен" in warning for warning in report.warnings),
                report.warnings,
            )

    def test_blocked_state_requires_reason_and_absent_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.registry["linguistic_kit"]["materialization"] = {
                "status": "blocked",
                "reason": "",
            }
            fixture.write_registry()

            errors = fixture.validate()

            self.assertTrue(any("reason" in error and "непуст" in error for error in errors), errors)
            self.assertTrue(any("уже материализован" in error for error in errors), errors)

    def test_blocked_mode_still_checks_stored_golden_vectors(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            shutil.rmtree(fixture.root / DEPENDENCY_PATH)
            fixture.registry["linguistic_kit"]["materialization"] = {
                "status": "blocked",
                "reason": "форк не создан",
            }
            fixture.registry["golden"][-1]["transliteration"] = "prototipy"
            fixture.write_registry()

            errors = fixture.validate()

            self.assertTrue(
                any("golden" in error and "prototipyi" in error for error in errors),
                errors,
            )

    def test_display_names_are_checked_without_tool_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.registry["display"] = [
                {
                    "source": "запуск следующего шага",
                    "transliteration": "zapusk sleduyusjhego shaga",
                }
            ]
            fixture.mapping["запуск следующего шага"] = (
                "zapusk sleduyusjhego shaga"
            )
            fixture.write_registry()
            fixture.write_transformer()

            self.assertEqual(fixture.validate(), [])

    def test_display_name_transliteration_and_collision_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.registry["display"] = [
                {
                    "source": "другие прототипы",
                    "transliteration": "prototipyi",
                }
            ]
            fixture.mapping["другие прототипы"] = "drugiye prototipyi"
            fixture.write_registry()
            fixture.write_transformer()

            errors = fixture.validate()

            self.assertTrue(any("display" in error and "LinguisticKit" in error for error in errors), errors)
            self.assertTrue(any("коллиз" in error and "prototipyi" in error for error in errors), errors)

    def test_legacy_display_rejects_duplicates_and_display_overlap(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            legacy_name = "построение описания FUM для адресата"
            fixture.registry["legacy_display"].append(legacy_name)
            fixture.registry["display"] = [
                {
                    "source": legacy_name,
                    "transliteration": "postroyeniye opisaniya FUM dlya adresata",
                }
            ]
            fixture.mapping[legacy_name] = "postroyeniye opisaniya FUM dlya adresata"
            fixture.write_registry()
            fixture.write_transformer()

            errors = fixture.validate()

            self.assertTrue(any("legacy_display" in error and "повторяется" in error for error in errors), errors)
            self.assertTrue(any("legacy_display" in error and "display" in error for error in errors), errors)

    def test_rejects_transformer_failure_and_invalid_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            fixture.transformer_path.write_text(
                "import sys\nsys.stderr.write('boom\\n')\nsys.exit(7)\n",
                encoding="utf-8",
            )

            errors = fixture.validate()

            self.assertTrue(any("boom" in error and "7" in error for error in errors), errors)

            fixture.transformer_path.write_text(
                "print('not-json')\n",
                encoding="utf-8",
            )
            errors = fixture.validate()
            self.assertTrue(any("JSON" in error for error in errors), errors)

    def test_cli_accepts_transformer_command_as_trailing_arguments(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(fixture.root),
                    "--registry",
                    str(fixture.registry_path),
                    "--transformer-command",
                    *fixture.transformer_command,
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Проверено автоматизаций: 6", result.stdout)

    def test_cli_reports_skipped_live_check_in_blocked_mode(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = RepositoryFixture(Path(tmp))
            shutil.rmtree(fixture.root / DEPENDENCY_PATH)
            fixture.registry["linguistic_kit"]["materialization"] = {
                "status": "blocked",
                "reason": "приемлемый источник зависимости ещё недоступен",
            }
            fixture.write_registry()

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--repo-root",
                    str(fixture.root),
                    "--registry",
                    str(fixture.registry_path),
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Живая проверка LinguisticKit не выполнена", result.stdout)

    def test_swift_wrapper_declares_pinned_local_api_contract(self):
        package = (AUTOMATION_DIR / "Package.swift").read_text(encoding="utf-8")
        main = (
            AUTOMATION_DIR
            / "Sources"
            / "preobrazovatj-nazvaniya"
            / "main.swift"
        ).read_text(encoding="utf-8")

        self.assertTrue(package.startswith("// swift-tools-version: 5.9\n"))
        self.assertIn('.package(path: "../../Зависимости/LinguisticKit")', package)
        self.assertIn("import LinguisticKit", main)
        self.assertIn(".applyingTransform(", main)
        self.assertIn("from: .Cyrl", main)
        self.assertIn("to: .Latn", main)
        self.assertIn("withTable: .ru", main)


if __name__ == "__main__":
    unittest.main()
