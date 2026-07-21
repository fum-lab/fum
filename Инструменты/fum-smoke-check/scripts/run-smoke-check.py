#!/usr/bin/env python3
"""Run the local FUM repository smoke-check without network dependencies."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


PLANNING_REGISTRY_SCRIPT = Path(
    "Инструменты/fum-planning-registry/scripts/build-planning-registry.py"
)
PLANNING_REGISTRY_OUTPUT = Path(
    "Планирование/реестр-требований-вариантов-и-кандидатов.json"
)
PROTOTYPE_LAUNCH_CHECK_SCRIPT = Path(
    "Инструменты/fum-prototype-launch/scripts/check-prototype-launchers.py"
)
QUESTION_BACKLINKS_SCRIPT = Path(
    "Инструменты/fum-question-backlinks/scripts/check-question-backlinks.py"
)
README_INDEX_CHECK_SCRIPT = Path(
    "Инструменты/fum-readme-index/scripts/check-readme-index.py"
)
CODEX_COMMIT_CONTEXT_RULE_START = (2026, 7, 14, 2, 31, 47)
REQUEST_DATETIME_PREFIX_RE = re.compile(
    r"^(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})_MSK"
)
RECENCY_SCRIPT = Path("Инструменты/fum-md-recency/scripts/update-md-recency.py")
OBSIDIAN_GRAPH_RECENCY_SCRIPT = Path(
    "Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py"
)
SESSION_COHERENCE_SCRIPT = Path(
    "Инструменты/fum-session-coherence/scripts/check-session-coherence.py"
)
SWIFT_PACKAGE_POLICY = Path(
    "Инструменты/fum-smoke-check/swift-package-policy.json"
)
SWIFT_FORMAT_CONFIG = Path(
    "Инструменты/fum-smoke-check/swift-format.json"
)
SHA256_RE = re.compile(r"^sha256:[0-9a-f]{64}$")


@dataclass(frozen=True)
class SmokeStep:
    name: str
    command: tuple[str, ...] | None
    detail: str | None = None

    def __post_init__(self) -> None:
        if (self.command is None) == (self.detail is None):
            raise ValueError("smoke step must define exactly one of command or detail")


@dataclass(frozen=True)
class SwiftPackageManifest:
    executable_products: tuple[str, ...]
    target_paths: tuple[str, ...]


@dataclass(frozen=True)
class SwiftLintException:
    package: str
    reason: str
    removal_criterion: str
    source: str
    content_sha256: str


@dataclass(frozen=True)
class SwiftPackagePolicy:
    expected_products: dict[str, tuple[str, ...]]
    lint_exceptions: dict[str, SwiftLintException]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--request",
        type=Path,
        help="Selected working session request file for fum-session-coherence.",
    )
    parser.add_argument(
        "--commit-message-file",
        type=Path,
        help="Commit message file forwarded to fum-session-coherence.",
    )
    parser.add_argument(
        "--codex-thread-id",
        help="Expected root Codex thread identifier forwarded to fum-session-coherence.",
    )
    parser.add_argument(
        "--skip-session-coherence",
        action="store_true",
        help="Run repository checks without validating a specific working session.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help=(
            "Print planned check commands without running tests, builds or lint. "
            "Swift manifests are evaluated for discovery."
        ),
    )
    return parser.parse_args()


def repo_relative(path: Path, repo_root: Path) -> str:
    absolute = path if path.is_absolute() else repo_root / path
    return absolute.resolve().relative_to(repo_root.resolve()).as_posix()


def request_requires_codex_commit_context(request: str | Path) -> bool:
    match = REQUEST_DATETIME_PREFIX_RE.match(Path(request).name)
    if match is None:
        return False
    return tuple(int(part) for part in match.groups()) >= CODEX_COMMIT_CONTEXT_RULE_START


def require_file(repo_root: Path, path: Path) -> str:
    absolute = (repo_root / path).resolve()
    if not absolute.exists():
        raise FileNotFoundError(f"required smoke-check component is missing: {path.as_posix()}")
    return repo_relative(absolute, repo_root)


def discover_test_dirs(repo_root: Path) -> list[Path]:
    tools_dir = repo_root / "Инструменты"
    if not tools_dir.exists():
        return []

    test_dirs: list[Path] = []
    for tests_path in tools_dir.glob("*/tests"):
        if tests_path.is_dir() and any(tests_path.glob("test_*.py")):
            test_dirs.append(tests_path)
    return sorted(test_dirs, key=lambda path: repo_relative(path, repo_root))


def discover_swift_packages(repo_root: Path) -> list[Path]:
    prototypes_dir = repo_root / "Прототипы"
    if not prototypes_dir.exists():
        return []

    packages = [
        manifest.parent.resolve()
        for manifest in prototypes_dir.glob("*/Package.swift")
        if manifest.is_file()
    ]
    return sorted(packages, key=lambda path: repo_relative(path, repo_root))


def require_safe_relative_path(raw_path: object, label: str) -> str:
    if not isinstance(raw_path, str) or not raw_path:
        raise ValueError(f"{label} must be a non-empty relative path")
    path = Path(raw_path)
    if path.is_absolute() or ".." in path.parts or path.as_posix() != raw_path:
        raise ValueError(f"{label} must be a normalized relative path: {raw_path!r}")
    return raw_path


def parse_swift_package_manifest(output: str) -> SwiftPackageManifest:
    try:
        payload = json.loads(output)
    except json.JSONDecodeError as exc:
        raise ValueError(f"swift dump-package returned invalid JSON: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValueError("swift dump-package must return a JSON object")

    products = payload.get("products")
    targets = payload.get("targets")
    dependencies = payload.get("dependencies")
    if (
        not isinstance(products, list)
        or not isinstance(targets, list)
        or not isinstance(dependencies, list)
    ):
        raise ValueError(
            "swift dump-package is missing dependencies, products or targets"
        )
    if dependencies:
        raise ValueError(
            "SwiftPM dependencies require a separate reproducible offline contract"
        )

    executable_products: set[str] = set()
    for product in products:
        if not isinstance(product, dict):
            raise ValueError("swift dump-package contains an invalid product")
        product_type = product.get("type")
        if not isinstance(product_type, dict):
            raise ValueError("swift dump-package contains a product without a type")
        if "executable" not in product_type:
            continue
        name = product.get("name")
        if not isinstance(name, str) or not name:
            raise ValueError("swift dump-package contains an unnamed executable product")
        executable_products.add(name)

    if not executable_products:
        raise ValueError("SwiftPM prototype has no executable products")

    target_paths: set[str] = set()
    for target in targets:
        if not isinstance(target, dict):
            raise ValueError("swift dump-package contains an invalid target")
        target_path = require_safe_relative_path(
            target.get("path"),
            "SwiftPM target path",
        )
        target_paths.add(target_path)

    if not target_paths:
        raise ValueError("SwiftPM prototype has no target paths")

    return SwiftPackageManifest(
        executable_products=tuple(sorted(executable_products)),
        target_paths=tuple(sorted(target_paths)),
    )


def inspect_swift_package(
    repo_root: Path,
    package: Path,
    swift: str,
) -> SwiftPackageManifest:
    package_path = repo_relative(package, repo_root)
    command = (
        swift,
        "package",
        "--package-path",
        package_path,
        "--manifest-cache",
        "none",
        "dump-package",
    )
    try:
        result = subprocess.run(
            command,
            cwd=repo_root,
            env=smoke_env(),
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as exc:
        raise FileNotFoundError(
            f"cannot inspect SwiftPM package {package_path}: {exc}"
        ) from exc
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        suffix = f": {detail}" if detail else ""
        raise ValueError(
            f"cannot inspect SwiftPM package {package_path}{suffix}"
        )
    return parse_swift_package_manifest(result.stdout)


def swift_lint_content_sha256(
    repo_root: Path,
    package: Path,
    target_paths: tuple[str, ...],
) -> str:
    root = repo_root.resolve()
    package_root = package.resolve()
    repo_relative(package_root, root)

    inputs: set[Path] = {
        package_root / "Package.swift",
        root / SWIFT_FORMAT_CONFIG,
    }
    for target_path in target_paths:
        normalized = require_safe_relative_path(
            target_path,
            "SwiftPM target path",
        )
        target = package_root / normalized
        if not target.exists():
            raise ValueError(
                "SwiftPM lint input is missing: "
                f"{repo_relative(target, root)}"
            )
        if target.is_file():
            if target.suffix == ".swift":
                inputs.add(target)
            continue
        for current_root, dirnames, filenames in os.walk(target):
            dirnames[:] = [
                name
                for name in dirnames
                if not name.startswith(".") and name not in {".build", ".swiftpm"}
            ]
            current = Path(current_root)
            for filename in filenames:
                if filename.endswith(".swift"):
                    inputs.add(current / filename)

    digest = hashlib.sha256()
    for path in sorted(
        inputs,
        key=lambda item: repo_relative(item, root),
    ):
        if not path.is_file():
            raise ValueError(
                "SwiftPM lint input is missing: "
                f"{repo_relative(path, root)}"
            )
        relative = repo_relative(path, root).encode("utf-8")
        content = path.read_bytes()
        digest.update(len(relative).to_bytes(8, "big"))
        digest.update(relative)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return f"sha256:{digest.hexdigest()}"


def reject_swift_format_ignores(repo_root: Path, package: Path) -> None:
    root = repo_root.resolve()
    package_root = package.resolve()
    candidates: set[Path] = set()

    current = package_root
    while True:
        candidate = current / ".swift-format-ignore"
        if candidate.exists():
            candidates.add(candidate)
        if current == current.parent:
            break
        current = current.parent

    for candidate in package_root.rglob(".swift-format-ignore"):
        relative_parts = candidate.relative_to(package_root).parts
        if ".build" not in relative_parts and ".swiftpm" not in relative_parts:
            candidates.add(candidate)

    if candidates:
        rendered: list[str] = []
        for candidate in sorted(candidates):
            try:
                rendered.append(repo_relative(candidate, root))
            except ValueError:
                rendered.append(candidate.as_posix())
        raise ValueError(
            "SwiftPM strict lint does not allow .swift-format-ignore: "
            + ", ".join(rendered)
        )


def load_swift_package_policy(
    repo_root: Path,
    discovered_packages: set[str],
) -> SwiftPackagePolicy:
    policy_path = repo_root / SWIFT_PACKAGE_POLICY
    if not policy_path.exists():
        if discovered_packages:
            raise ValueError(
                "SwiftPM packages were discovered but swift-package-policy.json "
                "is missing"
            )
        return SwiftPackagePolicy(
            expected_products={},
            lint_exceptions={},
        )
    try:
        payload = json.loads(policy_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid SwiftPM policy JSON: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValueError("SwiftPM policy must be a JSON object")
    expected_top_level = {
        "schemaVersion",
        "defaultMode",
        "packages",
        "exceptions",
    }
    if set(payload) != expected_top_level:
        raise ValueError(
            "SwiftPM policy must contain exactly schemaVersion, "
            "defaultMode, packages and exceptions"
        )
    if payload["schemaVersion"] != 1:
        raise ValueError("unsupported SwiftPM policy schemaVersion")
    if payload["defaultMode"] != "strict":
        raise ValueError("SwiftPM policy defaultMode must be strict")

    raw_packages = payload["packages"]
    if not isinstance(raw_packages, list):
        raise ValueError("SwiftPM policy packages must be a list")
    expected_products: dict[str, tuple[str, ...]] = {}
    for raw_package in raw_packages:
        if not isinstance(raw_package, dict) or set(raw_package) != {
            "package",
            "executableProducts",
        }:
            raise ValueError(
                "SwiftPM policy package must contain package and "
                "executableProducts"
            )
        package = require_safe_relative_path(
            raw_package["package"],
            "SwiftPM policy package",
        )
        if package in expected_products:
            raise ValueError(f"duplicate SwiftPM policy package: {package}")
        products = raw_package["executableProducts"]
        if (
            not isinstance(products, list)
            or not products
            or not all(
                isinstance(product, str) and product
                for product in products
            )
            or len(set(products)) != len(products)
        ):
            raise ValueError(
                "SwiftPM policy executableProducts must be a non-empty "
                "unique string list"
            )
        expected_products[package] = tuple(sorted(products))

    expected_package_names = set(expected_products)
    if expected_package_names != discovered_packages:
        missing = sorted(expected_package_names - discovered_packages)
        unregistered = sorted(discovered_packages - expected_package_names)
        details: list[str] = []
        if missing:
            details.append(f"missing packages: {', '.join(missing)}")
        if unregistered:
            details.append(
                f"unregistered packages: {', '.join(unregistered)}"
            )
        raise ValueError(
            "SwiftPM package inventory differs from policy: "
            + "; ".join(details)
        )

    raw_exceptions = payload["exceptions"]
    if not isinstance(raw_exceptions, list):
        raise ValueError("SwiftPM policy exceptions must be a list")

    exceptions: dict[str, SwiftLintException] = {}
    expected_exception_fields = {
        "package",
        "reason",
        "removalCriterion",
        "source",
        "contentSha256",
    }
    for raw_exception in raw_exceptions:
        if not isinstance(raw_exception, dict):
            raise ValueError("SwiftPM lint exception must be an object")
        if set(raw_exception) != expected_exception_fields:
            raise ValueError(
                "SwiftPM lint exception has missing or unknown fields"
            )
        package = require_safe_relative_path(
            raw_exception["package"],
            "SwiftPM lint exception package",
        )
        if package not in discovered_packages:
            raise ValueError(
                f"SwiftPM lint exception refers to an undiscovered package: {package}"
            )
        if package in exceptions:
            raise ValueError(
                f"duplicate SwiftPM lint exception for package: {package}"
            )
        source = require_safe_relative_path(
            raw_exception["source"],
            "SwiftPM lint exception source",
        )
        if not (repo_root / source).is_file():
            raise ValueError(
                f"SwiftPM lint exception source is missing: {source}"
            )
        reason = raw_exception["reason"]
        removal_criterion = raw_exception["removalCriterion"]
        content_sha256 = raw_exception["contentSha256"]
        if not isinstance(reason, str) or not reason.strip():
            raise ValueError("SwiftPM lint exception reason must not be empty")
        if (
            not isinstance(removal_criterion, str)
            or not removal_criterion.strip()
        ):
            raise ValueError(
                "SwiftPM lint exception removalCriterion must not be empty"
            )
        if (
            not isinstance(content_sha256, str)
            or SHA256_RE.fullmatch(content_sha256) is None
        ):
            raise ValueError(
                "SwiftPM lint exception contentSha256 must be sha256:<hex>"
            )
        exceptions[package] = SwiftLintException(
            package=package,
            reason=reason.strip(),
            removal_criterion=removal_criterion.strip(),
            source=source,
            content_sha256=content_sha256,
        )
    return SwiftPackagePolicy(
        expected_products=expected_products,
        lint_exceptions=exceptions,
    )


def build_swift_steps(
    repo_root: Path,
    swift: str,
) -> list[SmokeStep]:
    packages = discover_swift_packages(repo_root)
    package_names = {
        repo_relative(package, repo_root)
        for package in packages
    }
    policy = load_swift_package_policy(repo_root, package_names)
    if not packages:
        return []
    swift_format_config = require_file(repo_root, SWIFT_FORMAT_CONFIG)
    steps: list[SmokeStep] = []

    for package in packages:
        package_path = repo_relative(package, repo_root)
        reject_swift_format_ignores(repo_root, package)
        manifest = inspect_swift_package(repo_root, package, swift)
        expected_products = policy.expected_products[package_path]
        if manifest.executable_products != expected_products:
            raise ValueError(
                f"SwiftPM executable products differ from policy for "
                f"{package_path}: expected {expected_products}, "
                f"got {manifest.executable_products}"
            )
        exception = policy.lint_exceptions.get(package_path)
        if exception is not None:
            current_hash = swift_lint_content_sha256(
                repo_root,
                package,
                manifest.target_paths,
            )
            if current_hash != exception.content_sha256:
                raise ValueError(
                    "SwiftPM lint exception is stale (устарело) for "
                    f"{package_path}: expected {exception.content_sha256}, "
                    f"got {current_hash}"
                )

        steps.append(
            SmokeStep(
                name=f"Тесты SwiftPM {package_path}",
                command=(swift, "test", "--package-path", package_path),
            )
        )
        for product in manifest.executable_products:
            steps.append(
                SmokeStep(
                    name=(
                        f"Сборка SwiftPM-продукта {package_path}: {product}"
                    ),
                    command=(
                        swift,
                        "build",
                        "--package-path",
                        package_path,
                        "--product",
                        product,
                    ),
                )
            )

        if exception is None:
            lint_inputs = [f"{package_path}/Package.swift"]
            lint_inputs.extend(
                f"{package_path}/{target_path}"
                for target_path in manifest.target_paths
            )
            steps.append(
                SmokeStep(
                    name=f"Строгий lint SwiftPM {package_path}",
                    command=(
                        swift,
                        "format",
                        "lint",
                        "--configuration",
                        swift_format_config,
                        "--strict",
                        "--recursive",
                        *lint_inputs,
                    ),
                )
            )
        else:
            steps.append(
                SmokeStep(
                    name=f"Lint-исключение SwiftPM {package_path}",
                    command=None,
                    detail=(
                        f"{exception.reason} Критерий снятия: "
                        f"{exception.removal_criterion} Источник: "
                        f"{exception.source}. Проверенный снимок: "
                        f"{exception.content_sha256}"
                    ),
                )
            )
    return steps


def build_steps(
    repo_root: str | Path,
    request: str | Path | None,
    include_session: bool = True,
    python: str | None = None,
    swift: str | None = None,
    commit_message_file: str | Path | None = None,
    codex_thread_id: str | None = None,
) -> list[SmokeStep]:
    root = Path(repo_root).resolve()
    python_cmd = python or sys.executable
    swift_cmd = swift or "swift"
    steps: list[SmokeStep] = []

    for test_dir in discover_test_dirs(root):
        tool_name = test_dir.parent.name
        steps.append(
            SmokeStep(
                name=f"Тесты {tool_name}",
                command=(
                    python_cmd,
                    "-m",
                    "unittest",
                    "discover",
                    "-s",
                    repo_relative(test_dir, root),
                    "-p",
                    "test_*.py",
                ),
            )
        )

    steps.extend(build_swift_steps(root, swift_cmd))

    planning_script = require_file(root, PLANNING_REGISTRY_SCRIPT)
    planning_output = PLANNING_REGISTRY_OUTPUT.as_posix()
    steps.append(
        SmokeStep(
            name="Сборка планового реестра",
            command=(python_cmd, planning_script, "build", "--output", planning_output),
        )
    )
    steps.append(
        SmokeStep(
            name="Проверка планового реестра",
            command=(python_cmd, planning_script, "validate", "--registry", planning_output),
        )
    )

    prototype_launch_script = require_file(root, PROTOTYPE_LAUNCH_CHECK_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка скриптов запуска прототипов",
            command=(python_cmd, prototype_launch_script),
        )
    )

    question_backlinks_script = require_file(root, QUESTION_BACKLINKS_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка двунаправленности вопросов",
            command=(python_cmd, question_backlinks_script),
        )
    )

    readme_index_script = require_file(root, README_INDEX_CHECK_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка тематического индекса README",
            command=(python_cmd, readme_index_script, "--repo-root", "."),
        )
    )

    recency_script = require_file(root, RECENCY_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка recency-меток Markdown",
            command=(python_cmd, recency_script, "--check"),
        )
    )
    obsidian_graph_recency_script = require_file(root, OBSIDIAN_GRAPH_RECENCY_SCRIPT)
    steps.append(
        SmokeStep(
            name="Проверка тепловой карты графа Obsidian",
            command=(python_cmd, obsidian_graph_recency_script, "--check"),
        )
    )

    if include_session:
        if request is None:
            raise ValueError("--request is required unless --skip-session-coherence is used")
        if request_requires_codex_commit_context(request):
            if commit_message_file is None:
                raise ValueError(
                    "--commit-message-file is required for this request"
                )
            if codex_thread_id is None:
                raise ValueError("--codex-thread-id is required for this request")
        session_script = require_file(root, SESSION_COHERENCE_SCRIPT)
        request_path = repo_relative(Path(request), root)
        session_command = [python_cmd, session_script, "--request", request_path]
        if commit_message_file is not None:
            message_path = Path(commit_message_file)
            session_command.extend(
                ["--commit-message-file", message_path.as_posix()]
            )
        if codex_thread_id is not None:
            session_command.extend(["--codex-thread-id", codex_thread_id])
        steps.append(
            SmokeStep(
                name="Проверка связности рабочей сессии",
                command=tuple(session_command),
            )
        )

    return steps


def smoke_env() -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    return env


def print_output(result: subprocess.CompletedProcess[str]) -> None:
    if result.stdout:
        print(result.stdout, end="", flush=True)
    if result.stderr:
        print(result.stderr, end="", flush=True)


def run_steps(steps: list[SmokeStep], repo_root: Path) -> int:
    env = smoke_env()
    total = len(steps)
    for index, step in enumerate(steps, start=1):
        print(f"[{index}/{total}] {step.name}", flush=True)
        if step.command is None:
            print(step.detail, flush=True)
            continue
        print(shlex.join(step.command), flush=True)
        result = subprocess.run(
            step.command,
            cwd=repo_root,
            env=env,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print_output(result)
        if result.returncode != 0:
            print(
                f"smoke-check failed at step {index}: {step.name}",
                file=sys.stderr,
            )
            return result.returncode
    print(f"smoke-check passed: {total} step(s)")
    return 0


def main() -> int:
    args = parse_args()
    root = args.repo_root.resolve()
    include_session = not args.skip_session_coherence

    try:
        steps = build_steps(
            root,
            args.request,
            include_session=include_session,
            commit_message_file=args.commit_message_file,
            codex_thread_id=args.codex_thread_id,
        )
    except (FileNotFoundError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if args.list:
        for step in steps:
            if step.command is None:
                print(f"{step.name}: {step.detail}")
            else:
                print(f"{step.name}: {shlex.join(step.command)}")
        return 0

    return run_steps(steps, root)


if __name__ == "__main__":
    raise SystemExit(main())
