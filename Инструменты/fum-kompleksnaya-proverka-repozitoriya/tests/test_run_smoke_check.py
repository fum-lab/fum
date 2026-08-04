import contextlib
import importlib.util
import io
import json
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
from dataclasses import replace
from pathlib import Path
from unittest import mock


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "run-smoke-check.py"
)
TOOLS_DIR = Path(__file__).resolve().parents[2]
MACHINE_LOCAL_PATH_AUTOMATION_DIR = (
    TOOLS_DIR / "fum-proverka-mashinno-lokaljnyikh-putej"
)
REQUEST_FOLDER_LAYOUT_AUTOMATION_DIR = (
    TOOLS_DIR / "fum-struktura-papok-zaprosov"
)

spec = importlib.util.spec_from_file_location("run_smoke_check", SCRIPT_PATH)
run_smoke_check = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = run_smoke_check
spec.loader.exec_module(run_smoke_check)


class RunSmokeCheckTests(unittest.TestCase):
    def test_request_commit_context_rule_reads_parent_session_stem(self):
        self.assertTrue(
            run_smoke_check.request_requires_codex_commit_context(
                Path(
                    "Журнал/2026-07-14_02-31-47_MSK_"
                    "добавлять-идентификатор-сеанса-Codex/запрос.md"
                )
            )
        )
        self.assertFalse(
            run_smoke_check.request_requires_codex_commit_context(
                Path(
                    "Журнал/2026-07-14_01-55-34_MSK_"
                    "интегрировать-рекурсивную-модель/запрос.md"
                )
            )
        )
        self.assertFalse(
            run_smoke_check.request_requires_codex_commit_context(
                Path("Журнал/добавлять-идентификатор-сеанса-Codex/запрос.md")
            )
        )

    def write_script_fixture(self, root: Path) -> None:
        for path in [
            root / "Инструменты" / "fum-reyestr-planirovaniya" / "scripts" / "build-planning-registry.py",
            root / "Инструменты" / "fum-zapusk-prototipov" / "scripts" / "check-prototype-launchers.py",
            root / "Инструменты" / "fum-obratnyiye-ssyilki-voprosov" / "scripts" / "check-question-backlinks.py",
            root / "Инструменты" / "fum-indeks-readme" / "scripts" / "check-readme-index.py",
            root / "Инструменты" / "fum-proverka-nazvanij-avtomatizacij" / "scripts" / "proveritj-nazvaniya-avtomatizacij.py",
            root / "Инструменты" / "fum-proverka-mashinno-lokaljnyikh-putej" / "scripts" / "proveritj-mashinno-lokaljnyiye-puti.py",
            root / "Инструменты" / "fum-perevod-obyyavlenij-koda-na-russkij-yazyik" / "scripts" / "перевести-объявления-кода.py",
            root / "Инструменты" / "fum-proverka-git-zavisimostej" / "scripts" / "proveritj-git-zavisimostj.py",
            root / "Инструменты" / "fum-svezhestj-markdown" / "scripts" / "update-md-recency.py",
            root / "Инструменты" / "fum-svezhestj-grafa-obsidian" / "scripts" / "build-obsidian-graph-recency.py",
            root / "Инструменты" / "fum-svyaznostj-rabochej-sessii" / "scripts" / "check-session-coherence.py",
            root / "Инструменты" / "fum-struktura-papok-zaprosov" / "scripts" / "struktura-papok-zaprosov.py",
        ]:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("print('fixture')\n", encoding="utf-8")

        output = root / "Планирование" / "реестр-требований-вариантов-и-кандидатов.json"
        output.parent.mkdir(parents=True, exist_ok=True)
        names_registry = root / "Инструменты" / "реестр-названий-автоматизаций.json"
        names_registry.write_text("{}\n", encoding="utf-8")
        снимок = (
            root
            / "Инструменты"
            / "fum-perevod-obyyavlenij-koda-na-russkij-yazyik"
            / "остаток-объявлений-кода.json"
        )
        снимок.write_text("{}\n", encoding="utf-8")

        codex_config = root / ".codex" / "config.toml"
        codex_config.parent.mkdir(parents=True, exist_ok=True)
        codex_config.write_text(
            "[skills]\ninclude_instructions = false\n",
            encoding="utf-8",
        )

    def test_requires_external_skill_instructions_disabled(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = root / ".codex" / "config.toml"
            config.parent.mkdir(parents=True)

            for text in (
                "model = \"gpt-5.6-sol\"\n",
                "[skills]\ninclude_instructions = true\n",
                "[skills]\ninclude_instructions = \"false\"\n",
            ):
                with self.subTest(text=text):
                    config.write_text(text, encoding="utf-8")
                    with self.assertRaisesRegex(
                        ValueError,
                        "skills.include_instructions = false",
                    ):
                        run_smoke_check.validate_project_skill_isolation(root)

            config.write_text(
                "[skills]\ninclude_instructions = false\n",
                encoding="utf-8",
            )
            run_smoke_check.validate_project_skill_isolation(root)

            config.write_text("[skills\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "invalid project Codex config"):
                run_smoke_check.validate_project_skill_isolation(root)

    def test_build_plan_requires_project_skill_isolation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            (root / ".codex" / "config.toml").unlink()

            with self.assertRaisesRegex(
                ValueError,
                "skills.include_instructions = false",
            ):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    commit_message_file=None,
                    codex_thread_id=None,
                    include_session=False,
                    python="python3",
                )

    def test_rejects_local_skill_symlink_outside_repository(self):
        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            root = workspace / "repo"
            root.mkdir()
            self.write_script_fixture(root)

            external_skill = workspace / "external" / "SKILL.md"
            external_skill.parent.mkdir()
            external_skill.write_text("# External\n", encoding="utf-8")
            local_skill = root / "Инструменты" / "fum-linked" / "SKILL.md"
            local_skill.parent.mkdir()
            local_skill.symlink_to(external_skill)

            with self.assertRaisesRegex(
                ValueError,
                "local skill path resolves outside repository",
            ):
                run_smoke_check.validate_project_skill_isolation(root)

    def write_swift_package_fixture(self, root: Path, name: str) -> Path:
        package = root / "Прототипы" / name
        (package / "Sources" / "Fixture").mkdir(parents=True)
        (package / "Tests" / "FixtureTests").mkdir(parents=True)
        (package / "Package.swift").write_text(
            """// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Fixture",
  dependencies: [],
  targets: []
)
""",
            encoding="utf-8",
        )
        (package / "Sources" / "Fixture" / "Fixture.swift").write_text(
            "public struct Fixture {}\n",
            encoding="utf-8",
        )
        (package / "Tests" / "FixtureTests" / "FixtureTests.swift").write_text(
            "import Testing\n",
            encoding="utf-8",
        )
        swift_format_config = (
            root
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "swift-format.json"
        )
        swift_format_config.parent.mkdir(parents=True, exist_ok=True)
        if not swift_format_config.exists():
            swift_format_config.write_text("{}\n", encoding="utf-8")
        return package.resolve()

    def write_real_local_swift_composition(self, root: Path) -> tuple[Path, Path]:
        provider = root / "Прототипы" / "beta"
        consumer = root / "Прототипы" / "alpha"
        (provider / "Sources" / "BetaLibrary").mkdir(parents=True)
        (provider / "Sources" / "BetaCLI").mkdir(parents=True)
        (provider / "Tests" / "BetaTests").mkdir(parents=True)
        (consumer / "Sources" / "AlphaCLI").mkdir(parents=True)
        (consumer / "Tests" / "AlphaTests").mkdir(parents=True)
        provider.joinpath("Package.swift").write_text(
            """// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "BetaPackage",
  products: [
    .library(name: "BetaLibrary", targets: ["BetaLibrary"]),
    .executable(name: "BetaCLI", targets: ["BetaCLI"]),
  ],
  targets: [
    .target(name: "BetaLibrary", path: "Sources/BetaLibrary"),
    .executableTarget(
      name: "BetaCLI",
      dependencies: ["BetaLibrary"],
      path: "Sources/BetaCLI"
    ),
    .testTarget(name: "BetaTests", path: "Tests/BetaTests"),
  ]
)
""",
            encoding="utf-8",
        )
        provider.joinpath("Sources/BetaLibrary/Beta.swift").write_text(
            "public struct Beta { public init() {} }\n",
            encoding="utf-8",
        )
        provider.joinpath("Sources/BetaCLI/main.swift").write_text(
            "import BetaLibrary\n_ = Beta()\n",
            encoding="utf-8",
        )
        consumer.joinpath("Package.swift").write_text(
            """// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AlphaPackage",
  products: [
    .executable(name: "AlphaCLI", targets: ["AlphaCLI"])
  ],
  dependencies: [
    .package(path: "../beta")
  ],
  targets: [
    .executableTarget(
      name: "AlphaCLI",
      dependencies: [
        .product(name: "BetaLibrary", package: "beta")
      ],
      path: "Sources/AlphaCLI"
    ),
    .testTarget(name: "AlphaTests", path: "Tests/AlphaTests"),
  ]
)
""",
            encoding="utf-8",
        )
        consumer.joinpath("Sources/AlphaCLI/main.swift").write_text(
            "import BetaLibrary\n_ = Beta()\n",
            encoding="utf-8",
        )
        for tests_path in (
            provider / "Tests" / "BetaTests" / "SmokeTests.swift",
            consumer / "Tests" / "AlphaTests" / "SmokeTests.swift",
        ):
            tests_path.write_text(
                "import Testing\n\n@Test func smoke() { #expect(true) }\n",
                encoding="utf-8",
            )
        swift_format_config = (
            root
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "swift-format.json"
        )
        swift_format_config.parent.mkdir(parents=True, exist_ok=True)
        swift_format_config.write_text("{}\n", encoding="utf-8")
        return consumer.resolve(), provider.resolve()

    def write_local_dependency_policy(self, root: Path) -> None:
        policy_path = (
            root
            / "Инструменты"
            / "fum-kompleksnaya-proverka-repozitoriya"
            / "swift-package-policy.json"
        )
        policy_path.parent.mkdir(parents=True, exist_ok=True)
        policy_path.write_text(
            json.dumps(
                {
                    "schemaVersion": 2,
                    "defaultMode": "strict",
                    "packages": [
                        {
                            "package": "Прототипы/alpha",
                            "executableProducts": ["AlphaCLI"],
                            "localDependencies": [
                                {
                                    "package": "Прототипы/beta",
                                    "identity": "beta",
                                    "products": [
                                        {
                                            "target": "AlphaCLI",
                                            "product": "BetaLibrary",
                                        }
                                    ],
                                }
                            ],
                        },
                        {
                            "package": "Прототипы/beta",
                            "executableProducts": ["BetaCLI"],
                            "localDependencies": [],
                        },
                    ],
                    "exceptions": [],
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )

    def test_accepts_registered_local_swiftpm_composition(self):
        swift = shutil.which("swift")
        if swift is None:
            self.skipTest("SwiftPM is required by the repository smoke-check")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_real_local_swift_composition(root)
            self.write_local_dependency_policy(root)

            steps = run_smoke_check.build_swift_steps(root, swift)

            self.assertEqual(
                [step.name for step in steps],
                [
                    "Тесты SwiftPM Прототипы/alpha",
                    "Сборка SwiftPM-продукта Прототипы/alpha: AlphaCLI",
                    "Строгий lint SwiftPM Прототипы/alpha",
                    "Тесты SwiftPM Прототипы/beta",
                    "Сборка SwiftPM-продукта Прототипы/beta: BetaCLI",
                    "Строгий lint SwiftPM Прототипы/beta",
                ],
            )
            stdout = io.StringIO()
            stderr = io.StringIO()
            with (
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                result = run_smoke_check.run_steps(steps, root)
            self.assertEqual(
                result,
                0,
                stdout.getvalue() + stderr.getvalue(),
            )

    def test_policy_v2_rejects_dependency_boundary_cases(self):
        def payload() -> dict[str, object]:
            return {
                "schemaVersion": 2,
                "defaultMode": "strict",
                "packages": [
                    {
                        "package": "Прототипы/alpha",
                        "executableProducts": ["AlphaCLI"],
                        "localDependencies": [
                            {
                                "package": "Прототипы/beta",
                                "identity": "beta",
                                "products": [
                                    {
                                        "target": "AlphaCLI",
                                        "product": "BetaLibrary",
                                    }
                                ],
                            }
                        ],
                    },
                    {
                        "package": "Прототипы/beta",
                        "executableProducts": ["BetaCLI"],
                        "localDependencies": [],
                    },
                ],
                "exceptions": [],
            }

        cases: list[tuple[str, dict[str, object], str]] = []

        schema_v1 = payload()
        schema_v1["schemaVersion"] = 1
        cases.append(("schema-v1", schema_v1, "schemaVersion"))

        missing_allowlist = payload()
        del missing_allowlist["packages"][0]["localDependencies"]  # type: ignore[index]
        cases.append(("missing-allowlist", missing_allowlist, "localDependencies"))

        absolute = payload()
        absolute["packages"][0]["localDependencies"][0]["package"] = "/tmp/beta"  # type: ignore[index]
        cases.append(("absolute", absolute, "normalized relative path"))

        traversal = payload()
        traversal["packages"][0]["localDependencies"][0]["package"] = "Прототипы/../beta"  # type: ignore[index]
        cases.append(("traversal", traversal, "normalized relative path"))

        self_dependency = payload()
        self_dependency["packages"][0]["localDependencies"][0]["package"] = "Прототипы/alpha"  # type: ignore[index]
        cases.append(("self", self_dependency, "self-dependency"))

        duplicate = payload()
        duplicate["packages"][0]["localDependencies"].append(  # type: ignore[index,union-attr]
            duplicate["packages"][0]["localDependencies"][0]  # type: ignore[index]
        )
        cases.append(("duplicate", duplicate, "duplicate"))

        cycle = payload()
        cycle["packages"][1]["localDependencies"] = [  # type: ignore[index]
            {
                "package": "Прототипы/alpha",
                "identity": "alpha",
                "products": [
                    {"target": "BetaCLI", "product": "AlphaLibrary"}
                ],
            }
        ]
        cases.append(("cycle", cycle, "contains a cycle"))

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.parent.mkdir(parents=True)
            for name, candidate, error in cases:
                with self.subTest(name=name):
                    policy_path.write_text(
                        json.dumps(candidate, ensure_ascii=False),
                        encoding="utf-8",
                    )
                    with self.assertRaisesRegex(ValueError, error):
                        run_smoke_check.load_swift_package_policy(
                            root,
                            {"Прототипы/alpha", "Прототипы/beta"},
                        )

    def test_dump_rejects_remote_registry_unknown_and_binary_dependencies(self):
        base = {
            "dependencies": [],
            "products": [
                {"name": "CLI", "type": {"executable": None}},
            ],
            "targets": [
                {
                    "name": "CLI",
                    "path": "Sources/CLI",
                    "dependencies": [],
                }
            ],
        }
        dependency_cases = {
            "source-control": {"sourceControl": []},
            "registry": {"registry": []},
            "unknown": {"futureDependency": []},
        }
        for name, dependency in dependency_cases.items():
            with self.subTest(name=name):
                candidate = dict(base)
                candidate["dependencies"] = [dependency]
                with self.assertRaisesRegex(ValueError, "non-local dependencies"):
                    run_smoke_check.parse_swift_package_manifest(
                        json.dumps(candidate)
                    )

        binary = dict(base)
        binary["targets"] = [
            {
                "name": "Artifact",
                "type": "binary",
                "path": "Artifacts/Artifact.artifactbundle",
                "dependencies": [],
            }
        ]
        with self.assertRaisesRegex(ValueError, "binary dependencies"):
            run_smoke_check.parse_swift_package_manifest(json.dumps(binary))

    def test_dump_normalizes_local_path_and_rejects_escape_and_duplicates(self):
        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            root = workspace / "repo"
            alpha = root / "Прототипы" / "alpha"
            beta = root / "Прототипы" / "beta"
            tool = root / "Инструменты" / "tool"
            outside = workspace / "outside"
            for path in (alpha, beta, tool, outside):
                path.mkdir(parents=True)
            escaped_link = root / "Прототипы" / "escaped"
            escaped_link.symlink_to(outside, target_is_directory=True)

            def dump_for(paths: list[Path]) -> str:
                dependencies = [
                    {
                        "fileSystem": [
                            {
                                "identity": f"dependency-{index}",
                                "path": str(path),
                                "productFilter": None,
                                "traits": [{"name": "default"}],
                            }
                        ]
                    }
                    for index, path in enumerate(paths)
                ]
                return json.dumps(
                    {
                        "dependencies": dependencies,
                        "products": [
                            {"name": "CLI", "type": {"executable": None}},
                        ],
                        "targets": [
                            {
                                "name": "CLI",
                                "path": "Sources/CLI",
                                "dependencies": [],
                            }
                        ],
                    }
                )

            manifest = run_smoke_check.parse_swift_package_manifest(
                dump_for([beta]),
                repo_root=root,
            )
            self.assertEqual(
                manifest.local_dependencies[0].package,
                "Прототипы/beta",
            )

            for name, path, error in (
                ("outside-repository", outside, "outside repository"),
                ("outside-prototypes", tool, "outside Прототипы"),
                ("symlink-escape", escaped_link, "outside repository"),
            ):
                with self.subTest(name=name):
                    with self.assertRaisesRegex(ValueError, error):
                        run_smoke_check.parse_swift_package_manifest(
                            dump_for([path]),
                            repo_root=root,
                        )

            duplicate_dump = json.loads(dump_for([beta]))
            duplicate_dump["dependencies"].append(
                duplicate_dump["dependencies"][0]
            )
            with self.assertRaisesRegex(ValueError, "duplicate"):
                run_smoke_check.parse_swift_package_manifest(
                    json.dumps(duplicate_dump),
                    repo_root=root,
                )

    def test_manifest_source_rejects_noncanonical_dependency_declarations(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            alpha = root / "Прототипы" / "alpha"
            beta = root / "Прототипы" / "beta"
            alpha.mkdir(parents=True)
            beta.mkdir(parents=True)
            manifest_path = alpha / "Package.swift"
            actual = (
                run_smoke_check.SwiftLocalPackageDependency(
                    package="Прототипы/beta",
                    identity="beta",
                ),
            )

            def source_for(
                dependency_expression: str,
                *,
                prelude: str = "",
            ) -> str:
                return (
                    "import PackageDescription\n"
                    f"{prelude}"
                    "let package = Package(\n"
                    '  name: "Alpha",\n'
                    f"  dependencies: [{dependency_expression}],\n"
                    "  targets: []\n"
                    ")\n"
                )

            manifest_path.write_text(
                source_for('.package(path: "../beta")'),
                encoding="utf-8",
            )
            declared = run_smoke_check.extract_manifest_local_dependency_paths(
                manifest_path
            )
            run_smoke_check._validate_manifest_dependency_declarations(
                root,
                alpha,
                declared,
                actual,
            )

            source_cases = (
                (
                    "absolute",
                    source_for(f'.package(path: "{beta}")'),
                    "must be relative",
                ),
                (
                    "noncanonical",
                    source_for('.package(path: "../alpha/../beta")'),
                    "must be canonical",
                ),
                (
                    "computed",
                    source_for(
                        ".package(path: p)",
                        prelude='let p = "../beta"\n',
                    ),
                    "only import PackageDescription",
                ),
                (
                    "remote",
                    source_for(
                        '.package(url: "https://example.test/x")'
                    ),
                    "must use exactly",
                ),
                (
                    "duplicate",
                    source_for(
                        '.package(path: "../beta"), '
                        '.package(path: "../beta")'
                    ),
                    "duplicate",
                ),
                (
                    "missing",
                    source_for('.package(path: "../missing")'),
                    "does not exist",
                ),
                (
                    "backtick-absolute-with-unused-marker",
                    source_for(
                        f'Package.Dependency.`package`(path: "{beta}")',
                        prelude=(
                            "let unused = Package.Dependency.package("
                            'path: "../beta")\n'
                        ),
                    ),
                    "only import PackageDescription",
                ),
                (
                    "post-initializer-absolute-mutation",
                    source_for('.package(path: "../beta")')
                    + "package.dependencies = ["
                    + f'.package(path: "{beta}")' + "]\n",
                    "may not mutate",
                ),
                (
                    "custom-prelude",
                    source_for(
                        '.package(path: "../beta")',
                        prelude="func overridePackage() {}\n",
                    ),
                    "only import PackageDescription",
                ),
            )
            for name, source, error in source_cases:
                with self.subTest(name=name):
                    manifest_path.write_text(source, encoding="utf-8")
                    with self.assertRaisesRegex(ValueError, error):
                        declared = (
                            run_smoke_check.extract_manifest_local_dependency_paths(
                                manifest_path
                            )
                        )
                        run_smoke_check._validate_manifest_dependency_declarations(
                            root,
                            alpha,
                            declared,
                            actual,
                        )

    def test_dependency_contract_rejects_identity_product_and_graph_drift(self):
        allowed_product = run_smoke_check.SwiftAllowedProductDependency(
            target="AlphaCLI",
            product="BetaLibrary",
        )
        allowed_dependency = run_smoke_check.SwiftAllowedLocalDependency(
            package="Прототипы/beta",
            identity="beta",
            products=(allowed_product,),
        )
        policy = run_smoke_check.SwiftPackagePolicy(
            expected_products={
                "Прототипы/alpha": ("AlphaCLI",),
                "Прототипы/beta": ("BetaCLI",),
            },
            local_dependencies={
                "Прототипы/alpha": (allowed_dependency,),
                "Прототипы/beta": (),
            },
            lint_exceptions={},
        )
        consumer = run_smoke_check.SwiftPackageManifest(
            executable_products=("AlphaCLI",),
            target_paths=("Sources/AlphaCLI",),
            products=("AlphaCLI",),
            targets=("AlphaCLI",),
            local_dependencies=(
                run_smoke_check.SwiftLocalPackageDependency(
                    package="Прототипы/beta",
                    identity="beta",
                ),
            ),
            product_dependencies=(
                run_smoke_check.SwiftProductDependency(
                    target="AlphaCLI",
                    identity="beta",
                    product="BetaLibrary",
                ),
            ),
        )
        provider = run_smoke_check.SwiftPackageManifest(
            executable_products=("BetaCLI",),
            target_paths=("Sources/BetaCLI", "Sources/BetaLibrary"),
            products=("BetaCLI", "BetaLibrary"),
            library_products=("BetaLibrary",),
            targets=("BetaCLI", "BetaLibrary"),
        )
        manifests = {
            "Прототипы/alpha": consumer,
            "Прототипы/beta": provider,
        }
        run_smoke_check.validate_swift_dependency_contract(policy, manifests)

        collision_identity = "collision"
        collision_manifests = {
            "Прототипы/alpha": replace(
                consumer,
                local_dependencies=(
                    run_smoke_check.SwiftLocalPackageDependency(
                        package="Прототипы/beta",
                        identity=collision_identity,
                    ),
                ),
            ),
            "Прототипы/beta": provider,
            "Прототипы/gamma": run_smoke_check.SwiftPackageManifest(
                executable_products=("GammaCLI",),
                target_paths=("Sources/GammaCLI",),
                targets=("GammaCLI",),
                local_dependencies=(
                    run_smoke_check.SwiftLocalPackageDependency(
                        package="Прототипы/delta",
                        identity=collision_identity,
                    ),
                ),
            ),
            "Прототипы/delta": run_smoke_check.SwiftPackageManifest(
                executable_products=("DeltaCLI",),
                target_paths=("Sources/DeltaCLI",),
                targets=("DeltaCLI",),
            ),
        }
        with self.assertRaisesRegex(ValueError, "maps to multiple packages"):
            run_smoke_check.validate_swift_dependency_contract(
                policy,
                collision_manifests,
            )

        cases = (
            (
                "missing-package-edge",
                replace(consumer, local_dependencies=()),
                provider,
                "package dependencies differ",
            ),
            (
                "changed-identity",
                replace(
                    consumer,
                    local_dependencies=(
                        run_smoke_check.SwiftLocalPackageDependency(
                            package="Прототипы/beta",
                            identity="renamed",
                        ),
                    ),
                ),
                provider,
                "package dependencies differ",
            ),
            (
                "changed-product",
                replace(
                    consumer,
                    product_dependencies=(
                        run_smoke_check.SwiftProductDependency(
                            target="AlphaCLI",
                            identity="beta",
                            product="RenamedLibrary",
                        ),
                    ),
                ),
                provider,
                "product dependencies differ",
            ),
            (
                "changed-target",
                replace(
                    consumer,
                    product_dependencies=(
                        run_smoke_check.SwiftProductDependency(
                            target="RenamedCLI",
                            identity="beta",
                            product="BetaLibrary",
                        ),
                    ),
                ),
                provider,
                "product dependencies differ",
            ),
            (
                "extra-product-edge",
                replace(
                    consumer,
                    product_dependencies=consumer.product_dependencies
                    + (
                        run_smoke_check.SwiftProductDependency(
                            target="AlphaCLI",
                            identity="beta",
                            product="ExtraLibrary",
                        ),
                    ),
                ),
                provider,
                "product dependencies differ",
            ),
            (
                "implicit-external-by-name",
                replace(
                    consumer,
                    by_name_dependencies=(("AlphaCLI", "BetaLibrary"),),
                ),
                provider,
                "internal target",
            ),
            (
                "provider-product-is-not-library",
                consumer,
                replace(provider, library_products=()),
                "not an exported library",
            ),
        )
        for name, changed_consumer, changed_provider, error in cases:
            with self.subTest(name=name):
                with self.assertRaisesRegex(ValueError, error):
                    run_smoke_check.validate_swift_dependency_contract(
                        policy,
                        {
                            "Прототипы/alpha": changed_consumer,
                            "Прототипы/beta": changed_provider,
                        },
                    )

        reverse_allowed = run_smoke_check.SwiftAllowedLocalDependency(
            package="Прототипы/alpha",
            identity="alpha",
            products=(
                run_smoke_check.SwiftAllowedProductDependency(
                    target="BetaCLI",
                    product="AlphaLibrary",
                ),
            ),
        )
        cycle_policy = replace(
            policy,
            local_dependencies={
                "Прототипы/alpha": (allowed_dependency,),
                "Прототипы/beta": (reverse_allowed,),
            },
        )
        alpha_library_provider = replace(
            consumer,
            products=("AlphaCLI", "AlphaLibrary"),
            library_products=("AlphaLibrary",),
        )
        cyclic_provider = replace(
            provider,
            local_dependencies=(
                run_smoke_check.SwiftLocalPackageDependency(
                    package="Прототипы/alpha",
                    identity="alpha",
                ),
            ),
            product_dependencies=(
                run_smoke_check.SwiftProductDependency(
                    target="BetaCLI",
                    identity="alpha",
                    product="AlphaLibrary",
                ),
            ),
        )
        with self.assertRaisesRegex(ValueError, "contains a cycle"):
            run_smoke_check.validate_swift_dependency_contract(
                cycle_policy,
                {
                    "Прототипы/alpha": alpha_library_provider,
                    "Прототипы/beta": cyclic_provider,
                },
            )

    def test_builds_full_plan_from_local_automation_tests(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            for tool_name in ["fum-alpha", "fum-beta"]:
                test_dir = root / "Инструменты" / tool_name / "tests"
                test_dir.mkdir(parents=True)
                (test_dir / f"test_{tool_name}.py").write_text(
                    "import unittest\n\nclass Fixture(unittest.TestCase):\n    pass\n",
                    encoding="utf-8",
                )

            steps = run_smoke_check.build_steps(
                root,
                request=Path("Журнал/2026-07-01_14-12-17_MSK/запрос.md"),
                commit_message_file=Path("/tmp/fum-commit-message.txt"),
                codex_thread_id="019f5dd0-c129-7fa0-9315-77e85dead3e7",
                include_session=True,
                python="python3",
            )

            names = [step.name for step in steps]
            self.assertEqual(
                names,
                [
                    "Тесты fum-alpha",
                    "Тесты fum-beta",
                    "Проверка структуры папок запросов",
                    "Сборка планового реестра",
                    "Проверка планового реестра",
                    "Проверка реестра названий автоматизаций",
                    "Проверка машинно-локальных путей",
                    "Проверка перевода объявлений кода",
                    "Проверка Git-зависимости LinguisticKit",
                    "Проверка скриптов запуска прототипов",
                    "Проверка двунаправленности вопросов",
                    "Проверка тематического индекса README",
                    "Проверка recency-меток Markdown",
                    "Проверка тепловой карты графа Obsidian",
                    "Проверка связности рабочей сессии",
                ],
            )
            self.assertIn("Инструменты/fum-alpha/tests", steps[0].command)
            self.assertEqual(
                next(
                    step
                    for step in steps
                    if step.name == "Проверка структуры папок запросов"
                ).command,
                (
                    "python3",
                    "Инструменты/fum-struktura-papok-zaprosov/scripts/"
                    "struktura-papok-zaprosov.py",
                    "validate",
                    "--repo-root",
                    ".",
                ),
            )
            question_step = next(
                step
                for step in steps
                if step.name == "Проверка двунаправленности вопросов"
            )
            self.assertEqual(
                question_step.command,
                (
                    "python3",
                    "Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/"
                    "check-question-backlinks.py",
                ),
            )
            readme_step = next(
                step
                for step in steps
                if step.name == "Проверка тематического индекса README"
            )
            self.assertEqual(
                readme_step.command,
                (
                    "python3",
                    "Инструменты/fum-indeks-readme/scripts/"
                    "check-readme-index.py",
                    "--repo-root",
                    ".",
                ),
            )
            self.assertEqual(
                next(
                    step
                    for step in steps
                    if step.name == "Проверка машинно-локальных путей"
                ).command,
                (
                    "python3",
                    "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/"
                    "scripts/proveritj-mashinno-lokaljnyiye-puti.py",
                    "--repo-root",
                    ".",
                ),
            )
            self.assertEqual(
                next(
                    step
                    for step in steps
                    if step.name == "Проверка реестра названий автоматизаций"
                ).command,
                (
                    "python3",
                    "Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/"
                    "proveritj-nazvaniya-avtomatizacij.py",
                    "--repo-root",
                    ".",
                    "--registry",
                    "Инструменты/реестр-названий-автоматизаций.json",
                ),
            )
            self.assertEqual(
                next(
                    step
                    for step in steps
                    if step.name == "Проверка Git-зависимости LinguisticKit"
                ).command,
                (
                    "python3",
                    "Инструменты/fum-proverka-git-zavisimostej/scripts/"
                    "proveritj-git-zavisimostj.py",
                    "check",
                    "--repo-root",
                    ".",
                    "--fork-url",
                    "https://github.com/fum-lab/LinguisticKit.git",
                    "--upstream-url",
                    "https://github.com/Roman-Kerimov/LinguisticKit.git",
                    "--path",
                    "Зависимости/LinguisticKit",
                    "--revision",
                    "837e2ce107b97ee7b9d3344c9fe99142281fe393",
                ),
            )
            self.assertEqual(
                steps[-1].command[-6:],
                (
                    "--request",
                    "Журнал/2026-07-01_14-12-17_MSK/запрос.md",
                    "--commit-message-file",
                    "/tmp/fum-commit-message.txt",
                    "--codex-thread-id",
                    "019f5dd0-c129-7fa0-9315-77e85dead3e7",
                ),
            )

    def test_добавляет_проверку_перевода_после_машинно_локальных_путей(сам):
        with tempfile.TemporaryDirectory() as временный_каталог:
            корень = Path(временный_каталог)
            сам.write_script_fixture(корень)

            шаги = run_smoke_check.build_steps(
                корень,
                request=None,
                include_session=False,
                python="python3",
            )

            имена = [шаг.name for шаг in шаги]
            индекс_путей = имена.index("Проверка машинно-локальных путей")
            сам.assertEqual(
                имена[индекс_путей + 1],
                "Проверка перевода объявлений кода",
            )
            сам.assertEqual(
                шаги[индекс_путей + 1].command,
                (
                    "python3",
                    "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/"
                    "scripts/перевести-объявления-кода.py",
                    "проверить",
                    "--корень-репозитория",
                    ".",
                    "--снимок",
                    "Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/"
                    "остаток-объявлений-кода.json",
                ),
            )

    def test_конфигурация_форматтера_разрешает_кириллические_идентификаторы(сам):
        путь = SCRIPT_PATH.parents[1] / "swift-format.json"
        конфигурация = json.loads(путь.read_text(encoding="utf-8"))

        сам.assertIs(
            конфигурация["rules"]["IdentifiersMustBeASCII"],
            False,
        )

    def test_session_check_can_be_skipped_for_partial_local_runs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)

            steps = run_smoke_check.build_steps(
                root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                include_session=False,
                python="python3",
            )

            names = [step.name for step in steps]
            self.assertNotIn("Проверка связности рабочей сессии", names)
            self.assertIn("Проверка структуры папок запросов", names)
            self.assertIn("Проверка recency-меток Markdown", names)
            self.assertIn("Проверка тепловой карты графа Obsidian", names)

    def test_new_request_requires_commit_context(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            request = Path(
                "Журнал/2026-07-14_02-31-47_MSK_добавлять-"
                "идентификатор-сеанса-Codex/запрос.md"
            )

            for missing_message, missing_thread_id, expected_flag in [
                (True, False, "--commit-message-file"),
                (False, True, "--codex-thread-id"),
            ]:
                with self.subTest(expected_flag=expected_flag):
                    with self.assertRaisesRegex(ValueError, expected_flag):
                        run_smoke_check.build_steps(
                            root,
                            request=request,
                            commit_message_file=(
                                None
                                if missing_message
                                else Path("/tmp/fum-commit-message.txt")
                            ),
                            codex_thread_id=(
                                None
                                if missing_thread_id
                                else "019f5dd0-c129-7fa0-9315-77e85dead3e7"
                            ),
                            include_session=True,
                            python="python3",
                        )

    def test_rejects_request_folder_without_time_prefix(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)

            with self.assertRaisesRegex(
                ValueError,
                "YYYY-MM-DD_HH-MM-SS_MSK",
            ):
                run_smoke_check.build_steps(
                    root,
                    request=Path("Журнал/добавить-запрос/запрос.md"),
                    include_session=True,
                    python="python3",
                )

    def test_historical_request_allows_missing_commit_context(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)

            steps = run_smoke_check.build_steps(
                root,
                request=Path("Журнал/2026-07-01_14-12-17_MSK/запрос.md"),
                commit_message_file=None,
                codex_thread_id=None,
                include_session=True,
                python="python3",
            )

            self.assertEqual(
                steps[-1].command[-2:],
                ("--request", "Журнал/2026-07-01_14-12-17_MSK/запрос.md"),
            )

    def test_requires_request_when_session_check_is_enabled(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)

            with self.assertRaisesRegex(ValueError, "--request"):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    commit_message_file=None,
                    codex_thread_id=None,
                    include_session=True,
                    python="python3",
                )

    def test_discovers_swift_packages_tests_products_and_strict_lint(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            alpha = self.write_swift_package_fixture(root, "alpha")
            beta = self.write_swift_package_fixture(root, "beta")
            exception_hash = "sha256:" + "a" * 64
            policy = {
                "schemaVersion": 2,
                "defaultMode": "strict",
                "packages": [
                    {
                        "package": "Прототипы/alpha",
                        "executableProducts": ["AlphaCLI"],
                        "localDependencies": [],
                    },
                    {
                        "package": "Прототипы/beta",
                        "executableProducts": ["BetaApp", "BetaProbe"],
                        "localDependencies": [],
                    },
                ],
                "exceptions": [
                    {
                        "package": "Прототипы/beta",
                        "reason": "Существующий пакет ещё не нормализован.",
                        "removalCriterion": "Отформатировать пакет целиком.",
                        "source": "Ревью/ревью.md",
                        "contentSha256": exception_hash,
                    }
                ],
            }
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.parent.mkdir(parents=True, exist_ok=True)
            policy_path.write_text(
                json.dumps(policy, ensure_ascii=False),
                encoding="utf-8",
            )
            source = root / "Ревью" / "ревью.md"
            source.parent.mkdir(parents=True)
            source.write_text("# Ревью\n", encoding="utf-8")

            manifests = {
                alpha: run_smoke_check.SwiftPackageManifest(
                    executable_products=("AlphaCLI",),
                    target_paths=("Sources/Fixture", "Tests/FixtureTests"),
                ),
                beta: run_smoke_check.SwiftPackageManifest(
                    executable_products=("BetaApp", "BetaProbe"),
                    target_paths=("Sources/Fixture", "Tests/FixtureTests"),
                ),
            }

            with (
                mock.patch.object(
                    run_smoke_check,
                    "inspect_swift_package",
                    side_effect=lambda _root, package, _swift: manifests[package],
                ),
                mock.patch.object(
                    run_smoke_check,
                    "swift_lint_content_sha256",
                    return_value=exception_hash,
                ),
            ):
                steps = run_smoke_check.build_steps(
                    root,
                    request=None,
                    include_session=False,
                    python="python3",
                    swift="swift-fixture",
                )

            swift_steps = [
                step for step in steps if "SwiftPM" in step.name
            ]
            self.assertEqual(
                [step.name for step in swift_steps],
                [
                    "Тесты SwiftPM Прототипы/alpha",
                    "Сборка SwiftPM-продукта Прототипы/alpha: AlphaCLI",
                    "Строгий lint SwiftPM Прототипы/alpha",
                    "Тесты SwiftPM Прототипы/beta",
                    "Сборка SwiftPM-продукта Прототипы/beta: BetaApp",
                    "Сборка SwiftPM-продукта Прототипы/beta: BetaProbe",
                    "Lint-исключение SwiftPM Прототипы/beta",
                ],
            )
            self.assertEqual(
                swift_steps[0].command,
                (
                    "swift-fixture",
                    "test",
                    "--package-path",
                    "Прототипы/alpha",
                    *run_smoke_check.SWIFT_OFFLINE_FLAGS,
                ),
            )
            self.assertEqual(
                swift_steps[1].command,
                (
                    "swift-fixture",
                    "build",
                    "--package-path",
                    "Прототипы/alpha",
                    *run_smoke_check.SWIFT_OFFLINE_FLAGS,
                    "--product",
                    "AlphaCLI",
                ),
            )
            self.assertEqual(
                swift_steps[2].command,
                (
                    "swift-fixture",
                    "format",
                    "lint",
                    "--configuration",
                    "Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-format.json",
                    "--strict",
                    "--recursive",
                    "Прототипы/alpha/Package.swift",
                    "Прототипы/alpha/Sources/Fixture",
                    "Прототипы/alpha/Tests/FixtureTests",
                ),
            )
            self.assertIsNone(swift_steps[-1].command)
            self.assertIn(exception_hash, swift_steps[-1].detail)
            self.assertIn(
                "Отформатировать пакет целиком.",
                swift_steps[-1].detail,
            )

    def test_rejects_stale_swift_lint_exception(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            package = self.write_swift_package_fixture(root, "alpha")
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.parent.mkdir(parents=True, exist_ok=True)
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 2,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                                "localDependencies": [],
                            }
                        ],
                        "exceptions": [
                            {
                                "package": "Прототипы/alpha",
                                "reason": "Историческое форматирование.",
                                "removalCriterion": "Запустить форматирование.",
                                "source": "Ревью/ревью.md",
                                "contentSha256": "sha256:" + "a" * 64,
                            }
                        ],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            source = root / "Ревью" / "ревью.md"
            source.parent.mkdir(parents=True)
            source.write_text("# Ревью\n", encoding="utf-8")
            manifest = run_smoke_check.SwiftPackageManifest(
                executable_products=("AlphaCLI",),
                target_paths=("Sources/Fixture", "Tests/FixtureTests"),
            )

            with (
                mock.patch.object(
                    run_smoke_check,
                    "inspect_swift_package",
                    return_value=manifest,
                ),
                mock.patch.object(
                    run_smoke_check,
                    "swift_lint_content_sha256",
                    return_value="sha256:" + "b" * 64,
                ),
            ):
                with self.assertRaisesRegex(ValueError, "устарело"):
                    run_smoke_check.build_steps(
                        root,
                        request=None,
                        include_session=False,
                        python="python3",
                        swift="swift-fixture",
                    )

            self.assertTrue(package.exists())

    def test_swift_lint_hash_changes_with_tracked_inputs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package = self.write_swift_package_fixture(root, "alpha")
            target_paths = ("Sources/Fixture", "Tests/FixtureTests")

            before = run_smoke_check.swift_lint_content_sha256(
                root,
                package,
                target_paths,
            )
            (package / "Sources" / "Fixture" / "Fixture.swift").write_text(
                "public struct ChangedFixture {}\n",
                encoding="utf-8",
            )
            after = run_smoke_check.swift_lint_content_sha256(
                root,
                package,
                target_paths,
            )

            self.assertRegex(before, r"^sha256:[0-9a-f]{64}$")
            self.assertNotEqual(before, after)

            config = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-format.json"
            )
            config.write_text('{"lineLength": 88}\n', encoding="utf-8")
            after_config_change = run_smoke_check.swift_lint_content_sha256(
                root,
                package,
                target_paths,
            )
            self.assertNotEqual(after, after_config_change)

    def test_rejects_nonlocal_swiftpm_dependencies(self):
        dump = json.dumps(
            {
                "dependencies": [
                    {
                        "sourceControl": [
                            {
                                "identity": "remote",
                                "location": {"remote": ["https://example.test/repo"]},
                            },
                            {"branch": ["main"]},
                        ]
                    }
                ],
                "products": [
                    {"name": "CLI", "type": {"executable": None}},
                ],
                "targets": [
                    {
                        "name": "CLI",
                        "path": "Sources/CLI",
                        "dependencies": [],
                    },
                ],
            }
        )

        with self.assertRaisesRegex(ValueError, "non-local dependencies"):
            run_smoke_check.parse_swift_package_manifest(dump)

    def test_rejects_missing_package_and_product_inventory_drift(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            package = self.write_swift_package_fixture(root, "alpha")
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 2,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                                "localDependencies": [],
                            },
                            {
                                "package": "Прототипы/beta",
                                "executableProducts": ["BetaCLI"],
                                "localDependencies": [],
                            },
                        ],
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "missing packages"):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    include_session=False,
                    python="python3",
                    swift="swift-fixture",
                )

            policy = json.loads(policy_path.read_text(encoding="utf-8"))
            policy["packages"] = policy["packages"][:1]
            policy_path.write_text(
                json.dumps(policy, ensure_ascii=False),
                encoding="utf-8",
            )
            manifest = run_smoke_check.SwiftPackageManifest(
                executable_products=("RenamedCLI",),
                target_paths=("Sources/Fixture", "Tests/FixtureTests"),
            )
            with mock.patch.object(
                run_smoke_check,
                "inspect_swift_package",
                return_value=manifest,
            ):
                with self.assertRaisesRegex(ValueError, "products differ"):
                    run_smoke_check.build_steps(
                        root,
                        request=None,
                        include_session=False,
                        python="python3",
                        swift="swift-fixture",
                    )

            self.assertTrue(package.exists())

    def test_rejects_swift_format_ignore_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            package = self.write_swift_package_fixture(root, "alpha")
            (package / ".swift-format-ignore").write_text(
                "Sources/Fixture/Fixture.swift\n",
                encoding="utf-8",
            )
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 2,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                                "localDependencies": [],
                            }
                        ],
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "swift-format-ignore"):
                run_smoke_check.build_steps(
                    root,
                    request=None,
                    include_session=False,
                    python="python3",
                    swift="swift-fixture",
                )

    def test_run_steps_prints_lint_exception_and_continues(self):
        steps = [
            run_smoke_check.SmokeStep(
                name="Lint-исключение SwiftPM fixture",
                command=None,
                detail="Проверенное исключение.",
            ),
            run_smoke_check.SmokeStep(
                name="Следующий шаг",
                command=(sys.executable, "-c", "print('continued')"),
            ),
        ]

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = run_smoke_check.run_steps(steps, Path.cwd())

        self.assertEqual(result, 0)
        self.assertIn("Проверенное исключение.", output.getvalue())
        self.assertIn("continued", output.getvalue())

    def test_run_steps_prints_each_step_timing_and_full_total(self):
        steps = [
            run_smoke_check.SmokeStep(
                name="Информационный шаг",
                command=None,
                detail="Проверенное исключение.",
            ),
            run_smoke_check.SmokeStep(
                name="Исполняемый шаг",
                command=(sys.executable, "-c", "print('continued')"),
            ),
        ]
        clock_values = iter((100.0, 101.0, 101.25, 102.0, 103.5, 104.0))

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = run_smoke_check.run_steps(
                steps,
                Path.cwd(),
                clock=lambda: next(clock_values),
            )

        self.assertEqual(result, 0)
        timing_lines = [
            line
            for line in output.getvalue().splitlines()
            if line.startswith("smoke-timing ")
        ]
        self.assertEqual(len(timing_lines), 3)
        records = [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines]
        self.assertEqual(
            records,
            [
                {
                    "kind": "step",
                    "index": 1,
                    "total_steps": 2,
                    "name": "Информационный шаг",
                    "result": "passed",
                    "duration_seconds": "0.250",
                },
                {
                    "kind": "step",
                    "index": 2,
                    "total_steps": 2,
                    "name": "Исполняемый шаг",
                    "result": "passed",
                    "duration_seconds": "1.500",
                },
                {
                    "kind": "total",
                    "result": "passed",
                    "duration_seconds": "4.000",
                },
            ],
        )

    def test_run_steps_prints_failed_step_timing_and_total_before_stopping(self):
        steps = [
            run_smoke_check.SmokeStep(
                name="Падающий шаг",
                command=("fixture", "fail"),
            ),
            run_smoke_check.SmokeStep(
                name="Недостижимый шаг",
                command=("fixture", "must-not-run"),
            ),
        ]
        completed = subprocess.CompletedProcess(
            args=steps[0].command,
            returncode=7,
            stdout="",
            stderr="fixture failure\n",
        )
        clock_values = iter((10.0, 11.0, 13.5, 14.0))
        stdout = io.StringIO()
        stderr = io.StringIO()

        with (
            mock.patch.object(
                run_smoke_check.subprocess,
                "run",
                return_value=completed,
            ) as run,
            contextlib.redirect_stdout(stdout),
            contextlib.redirect_stderr(stderr),
        ):
            result = run_smoke_check.run_steps(
                steps,
                Path.cwd(),
                clock=lambda: next(clock_values),
            )

        self.assertEqual(result, 7)
        self.assertEqual(run.call_count, 1)
        timing_lines = [
            line
            for line in stdout.getvalue().splitlines()
            if line.startswith("smoke-timing ")
        ]
        self.assertEqual(
            [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
            [
                {
                    "kind": "step",
                    "index": 1,
                    "total_steps": 2,
                    "name": "Падающий шаг",
                    "result": "failed",
                    "duration_seconds": "2.500",
                    "exit_code": 7,
                },
                {
                    "kind": "total",
                    "result": "failed",
                    "duration_seconds": "4.000",
                    "exit_code": 7,
                },
            ],
        )
        self.assertIn("Падающий шаг", stderr.getvalue())

    def test_failed_manifest_inspection_prints_its_timing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package = root / "Прототипы" / "alpha"
            package.mkdir(parents=True)
            completed = subprocess.CompletedProcess(
                args=("swift-fixture", "package"),
                returncode=9,
                stdout="",
                stderr="manifest failure\n",
            )
            clock_values = iter((20.0, 22.25))
            records: list[dict[str, object]] = []

            with mock.patch.object(
                run_smoke_check.subprocess,
                "run",
                return_value=completed,
            ):
                with self.assertRaisesRegex(
                    ValueError,
                    "cannot inspect SwiftPM package",
                ):
                    run_smoke_check.inspect_swift_package(
                        root,
                        package,
                        "swift-fixture",
                        clock=lambda: next(clock_values),
                        timing_sink=records.append,
                    )

            self.assertEqual(
                records,
                [
                    {
                        "kind": "manifest",
                        "name": "SwiftPM manifest Прототипы/alpha",
                        "result": "failed",
                        "duration_seconds": "2.250",
                        "exit_code": 9,
                    }
                ],
            )

    def test_manifest_os_error_uses_stable_exit_code_127(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package = root / "Прототипы" / "alpha"
            package.mkdir(parents=True)
            clock_values = iter((30.0, 31.25))
            records: list[dict[str, object]] = []

            with mock.patch.object(
                run_smoke_check.subprocess,
                "run",
                side_effect=PermissionError("manifest denied"),
            ):
                with self.assertRaisesRegex(
                    FileNotFoundError,
                    "cannot inspect SwiftPM package",
                ):
                    run_smoke_check.inspect_swift_package(
                        root,
                        package,
                        "swift-fixture",
                        clock=lambda: next(clock_values),
                        timing_sink=records.append,
                    )

            self.assertEqual(
                records,
                [
                    {
                        "kind": "manifest",
                        "name": "SwiftPM manifest Прототипы/alpha",
                        "result": "failed",
                        "duration_seconds": "1.250",
                        "exit_code": 127,
                    }
                ],
            )

    def test_main_prints_preparation_and_total_timing_when_plan_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            args = types.SimpleNamespace(
                repo_root=root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                skip_session_coherence=True,
                list=False,
            )
            clock_values = iter((10.0, 11.0, 14.0, 16.0))
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                mock.patch.object(
                    run_smoke_check,
                    "parse_args",
                    return_value=args,
                ),
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                result = run_smoke_check.main(
                    clock=lambda: next(clock_values),
                )

            self.assertEqual(result, 2)
            self.assertIn("skills.include_instructions = false", stderr.getvalue())
            timing_lines = [
                line
                for line in stdout.getvalue().splitlines()
                if line.startswith("smoke-timing ")
            ]
            self.assertEqual(
                [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
                [
                    {
                        "kind": "preparation",
                        "result": "failed",
                        "duration_seconds": "3.000",
                        "exit_code": 2,
                    },
                    {
                        "kind": "total",
                        "result": "failed",
                        "duration_seconds": "6.000",
                        "exit_code": 2,
                    },
                ],
            )

    def test_main_converts_preparation_os_error_to_failed_timing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            args = types.SimpleNamespace(
                repo_root=root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                skip_session_coherence=True,
                list=False,
            )
            clock_values = iter((40.0, 41.0, 44.0, 46.0))
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                mock.patch.object(
                    run_smoke_check,
                    "parse_args",
                    return_value=args,
                ),
                mock.patch.object(
                    run_smoke_check,
                    "build_steps",
                    side_effect=PermissionError("preparation denied"),
                ),
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                result = run_smoke_check.main(
                    clock=lambda: next(clock_values),
                )

            self.assertEqual(result, 2)
            self.assertIn("preparation denied", stderr.getvalue())
            timing_lines = [
                line
                for line in stdout.getvalue().splitlines()
                if line.startswith("smoke-timing ")
            ]
            self.assertEqual(
                [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
                [
                    {
                        "kind": "preparation",
                        "result": "failed",
                        "duration_seconds": "3.000",
                        "exit_code": 2,
                    },
                    {
                        "kind": "total",
                        "result": "failed",
                        "duration_seconds": "6.000",
                        "exit_code": 2,
                    },
                ],
            )

    def test_full_runner_stops_on_tracked_machine_local_path_regression(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            target_automation = (
                root
                / "Инструменты"
                / "fum-proverka-mashinno-lokaljnyikh-putej"
            )
            shutil.copy2(
                MACHINE_LOCAL_PATH_AUTOMATION_DIR
                / "scripts"
                / "proveritj-mashinno-lokaljnyiye-puti.py",
                target_automation
                / "scripts"
                / "proveritj-mashinno-lokaljnyiye-puti.py",
            )
            shutil.copy2(
                MACHINE_LOCAL_PATH_AUTOMATION_DIR / "scripts" / "path_forms.py",
                target_automation / "scripts" / "path_forms.py",
            )
            shutil.copy2(
                REQUEST_FOLDER_LAYOUT_AUTOMATION_DIR
                / "scripts"
                / "request_folder_layout.py",
                root
                / "Инструменты"
                / "fum-struktura-papok-zaprosov"
                / "scripts"
                / "request_folder_layout.py",
            )
            (target_automation / "policy.json").write_text(
                json.dumps(
                    {
                        "schema": "fum.machine-local-path-policy.v2",
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                )
                + "\n",
                encoding="utf-8",
            )
            regression = root / "Документация" / "регрессия.md"
            regression.parent.mkdir()
            regression.write_text(
                "/Users/private-name/secret-project\n",
                encoding="utf-8",
            )
            subprocess.run(
                ["git", "init"],
                cwd=root,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            subprocess.run(["git", "add", "."], cwd=root, check=True)
            steps = run_smoke_check.build_steps(
                root,
                request=None,
                include_session=False,
                python=sys.executable,
            )
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                result = run_smoke_check.run_steps(steps, root)

            self.assertEqual(result, 1)
            self.assertIn(
                "Документация/регрессия.md:1:error.posix-user-home",
                stdout.getvalue(),
            )
            self.assertNotIn("private-name", stdout.getvalue())
            self.assertIn(
                "Проверка машинно-локальных путей",
                stderr.getvalue(),
            )

    def test_list_evaluates_manifest_but_does_not_run_swift_checks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_script_fixture(root)
            self.write_swift_package_fixture(root, "alpha")
            policy_path = (
                root
                / "Инструменты"
                / "fum-kompleksnaya-proverka-repozitoriya"
                / "swift-package-policy.json"
            )
            policy_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 2,
                        "defaultMode": "strict",
                        "packages": [
                            {
                                "package": "Прототипы/alpha",
                                "executableProducts": ["AlphaCLI"],
                                "localDependencies": [],
                            }
                        ],
                        "exceptions": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            dump = json.dumps(
                {
                    "dependencies": [],
                    "products": [
                        {"name": "AlphaCLI", "type": {"executable": None}},
                    ],
                    "targets": [
                        {
                            "name": "Fixture",
                            "path": "Sources/Fixture",
                            "dependencies": [],
                        },
                        {
                            "name": "FixtureTests",
                            "path": "Tests/FixtureTests",
                            "dependencies": [],
                        },
                    ],
                }
            )
            completed = subprocess.CompletedProcess(
                args=(),
                returncode=0,
                stdout=dump,
                stderr="",
            )
            args = types.SimpleNamespace(
                repo_root=root,
                request=None,
                commit_message_file=None,
                codex_thread_id=None,
                skip_session_coherence=True,
                list=True,
            )

            output = io.StringIO()
            clock_values = iter((10.0, 11.0, 12.0, 14.0, 15.0, 16.0))
            with (
                mock.patch.object(run_smoke_check, "parse_args", return_value=args),
                mock.patch.object(
                    run_smoke_check.subprocess,
                    "run",
                    return_value=completed,
                ) as run,
                contextlib.redirect_stdout(output),
            ):
                result = run_smoke_check.main(
                    clock=lambda: next(clock_values),
                )

            self.assertEqual(result, 0)
            self.assertEqual(run.call_count, 1)
            manifest_command = run.call_args.args[0]
            self.assertIn("dump-package", manifest_command)
            self.assertNotIn("test", manifest_command)
            for flag in run_smoke_check.SWIFT_OFFLINE_FLAGS:
                self.assertIn(flag, manifest_command)
            self.assertIn(
                "swift test --package-path",
                output.getvalue(),
            )
            self.assertIn(
                "swift format lint --configuration",
                output.getvalue(),
            )
            timing_lines = [
                line
                for line in output.getvalue().splitlines()
                if line.startswith("smoke-timing ")
            ]
            self.assertEqual(
                [json.loads(line.removeprefix("smoke-timing ")) for line in timing_lines],
                [
                    {
                        "kind": "manifest",
                        "name": "SwiftPM manifest Прототипы/alpha",
                        "result": "passed",
                        "duration_seconds": "2.000",
                    },
                    {
                        "kind": "preparation",
                        "result": "passed",
                        "duration_seconds": "4.000",
                    },
                    {
                        "kind": "total",
                        "result": "passed",
                        "duration_seconds": "6.000",
                    },
                ],
            )

    def test_parses_executable_products_and_target_paths_from_dump_package(self):
        dump = json.dumps(
            {
                "dependencies": [],
                "products": [
                    {"name": "Library", "type": {"library": ["automatic"]}},
                    {"name": "CLI", "type": {"executable": None}},
                ],
                "targets": [
                    {
                        "name": "Library",
                        "path": "Sources/Library",
                        "dependencies": [],
                    },
                    {
                        "name": "CLI",
                        "path": "Sources/CLI",
                        "dependencies": [],
                    },
                    {
                        "name": "LibraryTests",
                        "path": "Tests/LibraryTests",
                        "dependencies": [],
                    },
                ],
            }
        )

        manifest = run_smoke_check.parse_swift_package_manifest(dump)

        self.assertEqual(manifest.executable_products, ("CLI",))
        self.assertEqual(
            manifest.target_paths,
            ("Sources/CLI", "Sources/Library", "Tests/LibraryTests"),
        )


if __name__ == "__main__":
    unittest.main()
