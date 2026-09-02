#!/usr/bin/env python3
"""Проверяет реестр русских латинских названий автоматизаций FUM."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence


SCHEMA = "fum.automation-names.v1"
EXPECTED_DEPENDENCY = {
    "path": "Зависимости/LinguisticKit",
    "fork_repository": "https://github.com/fum-lab/LinguisticKit.git",
    "upstream_repository": "https://github.com/Roman-Kerimov/LinguisticKit.git",
    "revision": "837e2ce107b97ee7b9d3344c9fe99142281fe393",
    "source_script": "Cyrl",
    "target_script": "Latn",
    "table": "ru",
}
REQUIRED_GOLDEN_VECTORS = {
    "проверка названий автоматизаций": "proverka nazvanij avtomatizacij",
    "автоматизации": "avtomatizacii",
    "имён": "imyon",
    "следующий шаг ветки": "sleduyusjhij shag vetki",
    "прототипы": "prototipyi",
}

CYRILLIC_PATTERN = re.compile(r"[А-Яа-яЁё]")
TRANSLITERATION_PATTERN = re.compile(
    r"[A-Za-z0-9]+(?:[ -][A-Za-z0-9]+)*\Z"
)
SLUG_PATTERN = re.compile(r"fum-[a-z0-9]+(?:-[a-z0-9]+)*\Z")


@dataclass(frozen=True)
class NameEntry:
    section: str
    index: int
    source: str
    transliteration: str
    slug: str | None = None

    @property
    def location(self) -> str:
        return f"{self.section}[{self.index}]"


@dataclass(frozen=True)
class Materialization:
    status: str
    reason: str | None


@dataclass(frozen=True)
class Registry:
    current: tuple[NameEntry, ...]
    display: tuple[NameEntry, ...]
    legacy: tuple[str, ...]
    legacy_display: tuple[str, ...]
    golden: tuple[NameEntry, ...]
    materialization: Materialization


@dataclass(frozen=True)
class ValidationReport:
    errors: list[str]
    warnings: list[str]
    automation_count: int


def expected_registry_path(repo_root: Path) -> Path:
    return repo_root / "Инструменты" / "реестр-названий-автоматизаций.json"


def default_transformer_command() -> list[str]:
    automation_dir = Path(__file__).resolve().parents[1]
    return [
        "swift",
        "run",
        "--quiet",
        "--package-path",
        str(automation_dir),
        "preobrazovatj-nazvaniya",
    ]


def slug_from_transliteration(transliteration: str) -> str:
    normalized = re.sub(r"\s+", "-", transliteration.casefold())
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", normalized):
        raise ValueError(
            "транслитерация не сводится к ASCII slug "
            "из слов, цифр и дефисов"
        )
    return f"fum-{normalized}"


def parse_name_entries(
    data: Any,
    section: str,
    *,
    require_slug: bool,
    errors: list[str],
) -> tuple[NameEntry, ...]:
    if data is None and section == "display":
        return ()
    if not isinstance(data, list):
        errors.append(f"{section}: ожидается массив")
        return ()

    entries: list[NameEntry] = []
    for index, raw_entry in enumerate(data):
        location = f"{section}[{index}]"
        if not isinstance(raw_entry, dict):
            errors.append(f"{location}: ожидается объект")
            continue

        source = raw_entry.get("source")
        transliteration = raw_entry.get("transliteration")
        slug = raw_entry.get("slug") if require_slug else None

        valid = True
        if not isinstance(source, str) or not source:
            errors.append(f"{location}.source: значение отсутствует")
            valid = False
        elif source != source.strip():
            errors.append(f"{location}.source: не должно иметь краевых пробелов")
        elif CYRILLIC_PATTERN.search(source) is None:
            errors.append(f"{location}.source: русское имя должно содержать кириллицу")

        if not isinstance(transliteration, str) or not transliteration:
            errors.append(f"{location}.transliteration: значение отсутствует")
            valid = False
        elif transliteration != transliteration.strip():
            errors.append(
                f"{location}.transliteration: не должна иметь краевых пробелов"
            )
        elif TRANSLITERATION_PATTERN.fullmatch(transliteration) is None:
            errors.append(
                f"{location}.transliteration: допустимы ASCII-буквы, цифры, "
                "пробелы и дефисы"
            )

        if require_slug:
            if not isinstance(slug, str) or not slug:
                errors.append(f"{location}.slug: значение отсутствует")
                valid = False
            elif SLUG_PATTERN.fullmatch(slug) is None:
                errors.append(f"{location}.slug: недопустимый slug {slug!r}")

        if valid:
            entries.append(
                NameEntry(
                    section=section,
                    index=index,
                    source=source,
                    transliteration=transliteration,
                    slug=slug,
                )
            )

    return tuple(entries)


def parse_registry(data: Any) -> tuple[Registry | None, list[str]]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return None, ["корень реестра: ожидается JSON-объект"]

    if data.get("schema") != SCHEMA:
        errors.append(f"schema: ожидается {SCHEMA!r}")

    dependency = data.get("linguistic_kit")
    if not isinstance(dependency, dict):
        errors.append("linguistic_kit: ожидается объект")
        dependency = {}
    for key, expected in EXPECTED_DEPENDENCY.items():
        actual = dependency.get(key)
        if actual != expected:
            errors.append(
                f"linguistic_kit.{key}: ожидается {expected!r}, получено {actual!r}"
            )

    materialization_data = dependency.get("materialization")
    if not isinstance(materialization_data, dict):
        errors.append("linguistic_kit.materialization: ожидается объект")
        materialization = Materialization(status="invalid", reason=None)
    else:
        status = materialization_data.get("status")
        reason = materialization_data.get("reason")
        if status not in {"ready", "blocked"}:
            errors.append(
                "linguistic_kit.materialization.status: "
                "ожидается 'ready' или 'blocked'"
            )
            status = "invalid"
        if status == "blocked" and (
            not isinstance(reason, str) or not reason.strip()
        ):
            errors.append(
                "linguistic_kit.materialization.reason: "
                "для blocked требуется непустая причина"
            )
        if status == "ready" and reason is not None:
            errors.append(
                "linguistic_kit.materialization.reason: "
                "для ready поле не задаётся"
            )
        materialization = Materialization(
            status=status,
            reason=reason if isinstance(reason, str) else None,
        )

    current = parse_name_entries(
        data.get("current"), "current", require_slug=True, errors=errors
    )
    display = parse_name_entries(
        data.get("display"), "display", require_slug=False, errors=errors
    )
    golden = parse_name_entries(
        data.get("golden"), "golden", require_slug=False, errors=errors
    )

    legacy_data = data.get("legacy")
    legacy: list[str] = []
    if not isinstance(legacy_data, list):
        errors.append("legacy: ожидается массив")
    else:
        for index, raw_slug in enumerate(legacy_data):
            if not isinstance(raw_slug, str) or not raw_slug:
                errors.append(f"legacy[{index}]: ожидается непустая строка")
                continue
            if SLUG_PATTERN.fullmatch(raw_slug) is None:
                errors.append(f"legacy[{index}]: недопустимый slug {raw_slug!r}")
            legacy.append(raw_slug)

    legacy_display_data = data.get("legacy_display", [])
    legacy_display: list[str] = []
    if not isinstance(legacy_display_data, list):
        errors.append("legacy_display: ожидается массив")
    else:
        for index, raw_name in enumerate(legacy_display_data):
            if not isinstance(raw_name, str) or not raw_name:
                errors.append(
                    f"legacy_display[{index}]: ожидается непустая строка"
                )
                continue
            if raw_name != raw_name.strip():
                errors.append(
                    f"legacy_display[{index}]: не должно иметь краевых пробелов"
                )
            legacy_display.append(raw_name)

    registry = Registry(
        current=current,
        display=display,
        legacy=tuple(legacy),
        legacy_display=tuple(legacy_display),
        golden=golden,
        materialization=materialization,
    )
    errors.extend(validate_registry_semantics(registry))
    return registry, errors


def является_регистровым_отображением(
    первая: NameEntry,
    вторая: NameEntry,
) -> bool:
    return (
        (первая.slug is None) != (вторая.slug is None)
        and первая.source.casefold() == вторая.source.casefold()
        and первая.transliteration.casefold()
        == вторая.transliteration.casefold()
    )


def validate_registry_semantics(registry: Registry) -> list[str]:
    errors: list[str] = []

    actual_golden: dict[str, str] = {}
    for entry in registry.golden:
        if entry.source in actual_golden:
            errors.append(f"golden: повторяется source {entry.source!r}")
        actual_golden[entry.source] = entry.transliteration
    for source, expected in REQUIRED_GOLDEN_VECTORS.items():
        actual = actual_golden.get(source)
        if actual != expected:
            errors.append(
                f"golden: для {source!r} ожидается {expected!r}, получено {actual!r}"
            )
    for source in sorted(set(actual_golden) - set(REQUIRED_GOLDEN_VECTORS)):
        errors.append(f"golden: неожиданный эталон для {source!r}")

    sources: dict[str, str] = {}
    transliterations: dict[str, NameEntry] = {}
    slugs: dict[str, str] = {}
    for entry in (*registry.current, *registry.display):
        previous = sources.get(entry.source)
        if previous is not None:
            errors.append(
                f"{entry.location}.source: повторяется source {entry.source!r} из {previous}"
            )
        else:
            sources[entry.source] = entry.location

        transliteration_key = entry.transliteration.casefold()
        previous = transliterations.get(transliteration_key)
        if previous is not None and not является_регистровым_отображением(
            previous,
            entry,
        ):
            errors.append(
                f"{entry.location}.transliteration: коллизия "
                f"{entry.transliteration!r} с {previous.location}"
            )
        elif previous is None:
            transliterations[transliteration_key] = entry

        if entry.slug is None:
            continue
        try:
            expected_slug = slug_from_transliteration(entry.transliteration)
        except ValueError as error:
            errors.append(f"{entry.location}.transliteration: {error}")
        else:
            if entry.slug != expected_slug:
                errors.append(
                    f"{entry.location}.slug: ожидается {expected_slug!r}, "
                    f"получено {entry.slug!r}"
                )
        previous = slugs.get(entry.slug)
        if previous is not None:
            errors.append(
                f"{entry.location}.slug: коллизия {entry.slug!r} с {previous}"
            )
        else:
            slugs[entry.slug] = entry.location

    seen_legacy: set[str] = set()
    current_slugs = {entry.slug for entry in registry.current}
    for index, slug in enumerate(registry.legacy):
        if slug in seen_legacy:
            errors.append(f"legacy[{index}]: повторяется slug {slug!r}")
        seen_legacy.add(slug)
        if slug in current_slugs:
            errors.append(f"legacy[{index}]: {slug!r} одновременно в current и legacy")

    display_names = {
        value
        for entry in registry.display
        for value in (entry.source, entry.transliteration)
    }
    seen_legacy_display: set[str] = set()
    for index, name in enumerate(registry.legacy_display):
        if name in seen_legacy_display:
            errors.append(
                f"legacy_display[{index}]: повторяется имя {name!r}"
            )
        seen_legacy_display.add(name)
        if name in display_names:
            errors.append(
                f"legacy_display[{index}]: {name!r} одновременно записано в display"
            )

    return errors


def read_skill_name(skill_path: Path) -> tuple[str | None, list[str]]:
    errors: list[str] = []
    try:
        lines = skill_path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        return None, [f"{skill_path}: не удалось прочитать: {error}"]

    if not lines or lines[0] != "---":
        return None, [f"{skill_path}: отсутствует YAML frontmatter"]
    try:
        closing = lines.index("---", 1)
    except ValueError:
        return None, [f"{skill_path}: не закрыт YAML frontmatter"]

    names: list[str] = []
    for line in lines[1:closing]:
        match = re.fullmatch(r"name:\s*(.*?)\s*", line)
        if match is not None:
            value = match.group(1)
            if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
                value = value[1:-1]
            names.append(value)
    if len(names) != 1 or not names[0]:
        errors.append(f"{skill_path}: frontmatter должен содержать ровно одно name")
        return None, errors
    return names[0], errors


def discover_automations(repo_root: Path) -> tuple[dict[str, str], list[str]]:
    tools_dir = repo_root / "Инструменты"
    if not tools_dir.is_dir():
        return {}, ["Инструменты: каталог не найден"]

    discovered: dict[str, str] = {}
    errors: list[str] = []
    for skill_path in sorted(tools_dir.glob("fum-*/SKILL.md")):
        slug = skill_path.parent.name
        skill_name, skill_errors = read_skill_name(skill_path)
        errors.extend(skill_errors)
        if skill_name is None:
            continue
        discovered[slug] = skill_name
        if skill_name != slug:
            errors.append(
                f"{skill_path.relative_to(repo_root)}: name {skill_name!r} "
                f"не совпадает с каталогом {slug!r}"
            )
    return discovered, errors


def validate_discovery(
    registry: Registry,
    discovered: dict[str, str],
) -> list[str]:
    errors: list[str] = []
    current = {entry.slug for entry in registry.current if entry.slug is not None}
    registered = current | set(registry.legacy)
    actual = set(discovered)

    for slug in sorted(actual - registered):
        errors.append(f"Инструменты/{slug}: автоматизация не зарегистрирована")
    for slug in sorted(registered - actual):
        errors.append(f"Инструменты/{slug}: каталог не найден")
    return errors


def run_transformer(
    command: Sequence[str],
    sources: Sequence[str],
    repo_root: Path,
) -> tuple[list[str] | None, list[str]]:
    if not command:
        return None, ["LinguisticKit: команда преобразователя пуста"]
    try:
        result = subprocess.run(
            list(command),
            cwd=repo_root,
            check=False,
            input=json.dumps(list(sources), ensure_ascii=False),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=120,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return None, [f"LinguisticKit: не удалось запустить преобразователь: {error}"]
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "без диагностики"
        return None, [
            f"LinguisticKit: преобразователь завершился с кодом "
            f"{result.returncode}: {detail}"
        ]
    try:
        transformed = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        return None, [f"LinguisticKit: преобразователь вернул некорректный JSON: {error}"]
    if (
        not isinstance(transformed, list)
        or len(transformed) != len(sources)
        or any(not isinstance(value, str) for value in transformed)
    ):
        return None, [
            "LinguisticKit: ожидается JSON-массив строк "
            "той же длины, что и вход"
        ]
    return transformed, []


def validate_live_transliterations(
    registry: Registry,
    command: Sequence[str],
    repo_root: Path,
) -> list[str]:
    expected_by_source: dict[str, tuple[str, list[str]]] = {}
    for entry in (*registry.golden, *registry.current, *registry.display):
        existing = expected_by_source.get(entry.source)
        if existing is None:
            expected_by_source[entry.source] = (
                entry.transliteration,
                [entry.location],
            )
        else:
            expected, locations = existing
            locations.append(entry.location)
            if expected != entry.transliteration:
                return [
                    f"{entry.location}: для source {entry.source!r} реестр "
                    f"содержит и {expected!r}, и {entry.transliteration!r}"
                ]

    sources = list(expected_by_source)
    transformed, errors = run_transformer(command, sources, repo_root)
    if errors or transformed is None:
        return errors

    validation_errors: list[str] = []
    for source, actual in zip(sources, transformed, strict=True):
        expected, locations = expected_by_source[source]
        if actual != expected:
            validation_errors.append(
                f"{', '.join(locations)}: LinguisticKit для {source!r} вернул "
                f"{actual!r}, а в реестре записано {expected!r}"
            )
    return validation_errors


def load_registry(registry_path: Path) -> tuple[Any | None, list[str]]:
    try:
        text = registry_path.read_text(encoding="utf-8")
    except OSError as error:
        return None, [f"{registry_path}: не удалось прочитать реестр: {error}"]
    try:
        return json.loads(text), []
    except json.JSONDecodeError as error:
        return None, [f"{registry_path}: некорректный JSON: {error}"]


def validate_repository_report(
    repo_root: Path,
    registry_path: Path,
    transformer_command: Sequence[str] | None = None,
) -> ValidationReport:
    repo_root = repo_root.resolve()
    registry_path = registry_path.resolve()
    data, load_errors = load_registry(registry_path)
    if load_errors:
        return ValidationReport(load_errors, [], 0)

    registry, errors = parse_registry(data)
    discovered, discovery_errors = discover_automations(repo_root)
    errors.extend(discovery_errors)
    warnings: list[str] = []
    if registry is None:
        return ValidationReport(errors, warnings, len(discovered))

    errors.extend(validate_discovery(registry, discovered))

    dependency_path = repo_root / EXPECTED_DEPENDENCY["path"]
    dependency_exists = dependency_path.is_dir()
    status = registry.materialization.status
    if not dependency_exists:
        if status != "blocked":
            errors.append(
                f"{EXPECTED_DEPENDENCY['path']}: зависимость не материализована; "
                "требуется materialization.status = 'blocked'"
            )
        else:
            warnings.append(
                "Живая проверка LinguisticKit не выполнена: "
                f"{registry.materialization.reason}"
            )
    else:
        if status == "blocked":
            errors.append(
                f"{EXPECTED_DEPENDENCY['path']}: каталог уже материализован, "
                "но materialization.status = 'blocked'"
            )
        command = list(transformer_command or default_transformer_command())
        errors.extend(validate_live_transliterations(registry, command, repo_root))

    return ValidationReport(errors, warnings, len(discovered))


def validate_repository(
    repo_root: Path,
    registry_path: Path,
    transformer_command: Sequence[str] | None = None,
) -> list[str]:
    return validate_repository_report(
        repo_root,
        registry_path,
        transformer_command,
    ).errors


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Проверить реестр названий автоматизаций FUM."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[3],
        help="Корень репозитория FUM.",
    )
    parser.add_argument(
        "--registry",
        type=Path,
        help="Путь к JSON-реестру; по умолчанию берётся из Инструменты/.",
    )
    parser.add_argument(
        "--transformer-command",
        nargs=argparse.REMAINDER,
        help=(
            "Команда JSON-преобразователя для теста; должна быть последним "
            "аргументом. Без неё используется Swift-обёртка."
        ),
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(argv)
    repo_root = arguments.repo_root.resolve()
    registry_path = arguments.registry
    if registry_path is None:
        registry_path = expected_registry_path(repo_root)
    elif not registry_path.is_absolute():
        registry_path = repo_root / registry_path

    report = validate_repository_report(
        repo_root,
        registry_path,
        arguments.transformer_command,
    )
    for warning in report.warnings:
        print(f"Предупреждение: {warning}")
    if report.errors:
        for error in report.errors:
            print(f"Ошибка: {error}", file=sys.stderr)
        return 1

    print(f"Проверено автоматизаций: {report.automation_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
