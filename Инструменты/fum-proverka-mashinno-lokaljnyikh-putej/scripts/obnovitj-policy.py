#!/usr/bin/env python3
"""Add exact machine-local-path policy fences from explicit declarations."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import stat
import sys
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Iterable
from types import SimpleNamespace


SCRIPTS_DIR = Path(__file__).resolve().parent
SCANNER_PATH = SCRIPTS_DIR / "proveritj-mashinno-lokaljnyiye-puti.py"
SCANNER_MODULE_NAME = "_fum_machine_local_path_scanner"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))
scanner_spec = importlib.util.spec_from_file_location(
    SCANNER_MODULE_NAME,
    SCANNER_PATH,
)
if scanner_spec is None or scanner_spec.loader is None:
    raise RuntimeError("machine-local path scanner cannot be loaded")
scanner = importlib.util.module_from_spec(scanner_spec)
sys.modules[SCANNER_MODULE_NAME] = scanner
scanner_spec.loader.exec_module(scanner)
import метаданные_наблюдений as наблюдения


MANIFEST_SCHEMA_V1 = "fum.machine-local-path-policy-update.v1"
MANIFEST_SCHEMA_V2 = "fum.machine-local-path-policy-update.v2"
СХЕМА_МАНИФЕСТА_ТРЕТЬЕЙ_ВЕРСИИ = "fum.machine-local-path-policy-update.v3"
СХЕМА_МАНИФЕСТА_ЧЕТВЁРТОЙ_ВЕРСИИ = "fum.machine-local-path-policy-update.v4"
MANIFEST_V1_KEYS = frozenset({"schema", "declarations"})
MANIFEST_V2_KEYS = frozenset({"schema", "declarations", "retirements"})
ПОЛЯ_МАНИФЕСТА_ТРЕТЬЕЙ_ВЕРСИИ = MANIFEST_V2_KEYS | {"метаданные"}
ПОЛЯ_МАНИФЕСТА_ЧЕТВЁРТОЙ_ВЕРСИИ = ПОЛЯ_МАНИФЕСТА_ТРЕТЬЕЙ_ВЕРСИИ | {
    "байтовые_фикстуры",
    "отмены_байтовых_фикстур",
}
DECLARATION_KEYS = frozenset({"id", "path", "line", "category", "reason"})
ПОЛЯ_ЗАЯВКИ_БАЙТОВОЙ_ФИКСТУРЫ = frozenset(
    {"идентификатор", "путь", "вид", "категория", "причина"}
)


class UpdateError(ValueError):
    """Raised when an explicit policy update cannot be proven narrow."""


@dataclass(frozen=True)
class Declaration:
    identifier: str
    path: str
    line: int
    category: str
    reason: str


@dataclass(frozen=True)
class ЗаявкаБайтовойФикстуры:
    идентификатор: str
    путь: str
    вид: str
    категория: str
    причина: str


@dataclass(frozen=True)
class UpdatePlan:
    declarations: tuple[Declaration, ...]
    retirements: tuple[object, ...]
    метаданные: tuple[object, ...] = ()
    байтовые_фикстуры: tuple[ЗаявкаБайтовойФикстуры, ...] = ()
    отмены_байтовых_фикстур: tuple[object, ...] = ()


def _canonical_json(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def _load_canonical_json(path: Path, label: str) -> object:
    try:
        text = path.read_text(encoding="utf-8")
        value = json.loads(text)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise UpdateError(f"{label} cannot be read as JSON") from exc
    if text != _canonical_json(value):
        raise UpdateError(f"{label} must be canonical JSON")
    return value


def _require_exact_keys(
    value: dict[str, object],
    expected: frozenset[str],
    label: str,
) -> None:
    if frozenset(value) != expected:
        raise UpdateError(f"{label} has missing or unknown fields")


def _parse_declaration(value: object, label: str) -> Declaration:
    if not isinstance(value, dict):
        raise UpdateError(f"{label} must be an object")
    _require_exact_keys(value, DECLARATION_KEYS, label)

    identifier = value.get("id")
    if (
        not isinstance(identifier, str)
        or scanner.EXCEPTION_ID_RE.fullmatch(identifier) is None
    ):
        raise UpdateError(f"{label} has an invalid identifier")

    try:
        path = scanner._validate_policy_path(value.get("path"))
    except scanner.PolicyError as exc:
        raise UpdateError(str(exc)) from exc
    if unicodedata.normalize("NFC", path) != path:
        raise UpdateError(f"{label} path must use canonical NFC")

    line = value.get("line")
    if type(line) is not int or line < 1:
        raise UpdateError(f"{label} line must be a positive integer")

    category = value.get("category")
    if (
        not isinstance(category, str)
        or category not in scanner.POLICY_CATEGORY_BASES
    ):
        raise UpdateError(f"{label} has an unsupported category")

    reason = value.get("reason")
    if (
        not isinstance(reason, str)
        or reason != reason.strip()
        or unicodedata.normalize("NFC", reason) != reason
        or len(reason) < 20
    ):
        raise UpdateError(f"{label} reason must be canonical and substantive")

    return Declaration(
        identifier=identifier,
        path=path,
        line=line,
        category=category,
        reason=reason,
    )


def _parse_declarations(values: Iterable[object], *, допускается_пустой=False) -> tuple[Declaration, ...]:
    declarations = tuple(
        _parse_declaration(value, f"declaration {index}")
        for index, value in enumerate(values)
    )
    if not declarations and not допускается_пустой:
        raise UpdateError("at least one explicit declaration is required")
    identifiers: set[str] = set()
    selectors: set[tuple[str, int]] = set()
    for declaration in declarations:
        if declaration.identifier in identifiers:
            raise UpdateError("declaration identifier collision")
        identifiers.add(declaration.identifier)
        selector = (declaration.path, declaration.line)
        if selector in selectors:
            raise UpdateError("declaration selector collision")
        selectors.add(selector)
    return declarations


def _разобрать_заявку_байтовой_фикстуры(
    значение: object,
    метка: str,
) -> ЗаявкаБайтовойФикстуры:
    if not isinstance(значение, dict):
        raise UpdateError(f"{метка} должна быть объектом")
    _require_exact_keys(значение, ПОЛЯ_ЗАЯВКИ_БАЙТОВОЙ_ФИКСТУРЫ, метка)
    идентификатор = значение.get("идентификатор")
    if (
        not isinstance(идентификатор, str)
        or scanner.EXCEPTION_ID_RE.fullmatch(идентификатор) is None
    ):
        raise UpdateError(f"{метка} имеет неверный идентификатор")
    try:
        путь = scanner._проверить_путь_байтовой_фикстуры(значение.get("путь"))
    except scanner.PolicyError as ошибка:
        raise UpdateError(str(ошибка)) from ошибка
    вид = значение.get("вид")
    if вид != "неполный-хвост-UTF-8":
        raise UpdateError(f"{метка} имеет неподдерживаемый вид")
    категория = значение.get("категория")
    if категория != "allow.test-fixture":
        raise UpdateError(f"{метка} имеет неподдерживаемую категорию")
    причина = значение.get("причина")
    if (
        not isinstance(причина, str)
        or причина != причина.strip()
        or unicodedata.normalize("NFC", причина) != причина
        or len(причина) < 20
    ):
        raise UpdateError(f"{метка} должна иметь каноническую содержательную причину")
    return ЗаявкаБайтовойФикстуры(
        идентификатор,
        путь,
        вид,
        категория,
        причина,
    )


def _разобрать_заявки_байтовых_фикстур(
    значения: Iterable[object],
) -> tuple[ЗаявкаБайтовойФикстуры, ...]:
    заявки = tuple(
        _разобрать_заявку_байтовой_фикстуры(
            значение,
            f"байтовая фикстура {индекс}",
        )
        for индекс, значение in enumerate(значения)
    )
    идентификаторы: set[str] = set()
    пути: set[str] = set()
    for заявка in заявки:
        if заявка.идентификатор in идентификаторы:
            raise UpdateError("коллизия идентификатора байтовой фикстуры")
        if заявка.путь in пути:
            raise UpdateError("коллизия пути байтовой фикстуры")
        идентификаторы.add(заявка.идентификатор)
        пути.add(заявка.путь)
    return заявки


def _parse_retirement(value: object, label: str) -> object:
    if isinstance(value, scanner.ExactException):
        return value
    if not isinstance(value, dict):
        raise UpdateError(f"{label} must be an object")
    try:
        policy = scanner.parse_policy(
            {
                "schema": scanner.POLICY_SCHEMA,
                "exceptions": [value],
            }
        )
    except scanner.PolicyError as exc:
        raise UpdateError(f"{label} must be an exact policy object") from exc
    retirement = policy.exceptions[0]
    if unicodedata.normalize("NFC", retirement.path) != retirement.path:
        raise UpdateError(f"{label} path must use canonical NFC")
    return retirement


def _parse_retirements(values: Iterable[object]) -> tuple[object, ...]:
    retirements = tuple(
        _parse_retirement(value, f"retirement {index}")
        for index, value in enumerate(values)
    )
    identifiers: set[str] = set()
    fingerprints: set[tuple[str, str, str]] = set()
    for retirement in retirements:
        if retirement.identifier in identifiers:
            raise UpdateError("retirement identifier collision")
        identifiers.add(retirement.identifier)
        fingerprint = (
            retirement.path,
            retirement.kind,
            retirement.line_sha256,
        )
        if fingerprint in fingerprints:
            raise UpdateError("retirement fingerprint collision")
        fingerprints.add(fingerprint)
    return retirements


def _разобрать_отмену_байтовой_фикстуры(значение: object, метка: str) -> object:
    if isinstance(значение, scanner.БайтоваяФикстура):
        return значение
    if not isinstance(значение, dict):
        raise UpdateError(f"{метка} должна быть объектом")
    try:
        policy = scanner.parse_policy(
            {
                "schema": scanner.СХЕМА_БАЙТОВОЙ_ПОЛИТИКИ,
                "exceptions": [],
                "метаданные": [],
                "байтовые_фикстуры": [значение],
            }
        )
    except scanner.PolicyError as ошибка:
        raise UpdateError(
            f"{метка} должна быть точным объектом байтовой политики"
        ) from ошибка
    return policy.байтовые_фикстуры[0]


def _разобрать_отмены_байтовых_фикстур(
    значения: Iterable[object],
) -> tuple[object, ...]:
    отмены = tuple(
        _разобрать_отмену_байтовой_фикстуры(
            значение,
            f"отмена байтовой фикстуры {индекс}",
        )
        for индекс, значение in enumerate(значения)
    )
    идентификаторы: set[str] = set()
    пути: set[str] = set()
    for отмена in отмены:
        if отмена.идентификатор in идентификаторы:
            raise UpdateError("коллизия идентификатора отмены байтовой фикстуры")
        if отмена.путь in пути:
            raise UpdateError("коллизия пути отмены байтовой фикстуры")
        идентификаторы.add(отмена.идентификатор)
        пути.add(отмена.путь)
    return отмены


def load_update_plan(path: str | Path) -> UpdatePlan:
    manifest = _load_canonical_json(Path(path), "manifest")
    if not isinstance(manifest, dict):
        raise UpdateError("manifest root must be an object")
    schema = manifest.get("schema")
    метаданные = ()
    исходные_байтовые: object = []
    исходные_байтовые_отмены: object = []
    if schema == MANIFEST_SCHEMA_V1:
        _require_exact_keys(manifest, MANIFEST_V1_KEYS, "manifest")
        исходные_отмены: object = []
    elif schema == MANIFEST_SCHEMA_V2:
        _require_exact_keys(manifest, MANIFEST_V2_KEYS, "manifest")
        исходные_отмены = manifest.get("retirements")
    elif schema == СХЕМА_МАНИФЕСТА_ТРЕТЬЕЙ_ВЕРСИИ:
        _require_exact_keys(manifest, ПОЛЯ_МАНИФЕСТА_ТРЕТЬЕЙ_ВЕРСИИ, "manifest")
        исходные_отмены = manifest.get("retirements")
        try:
            наблюдения.разобрать_заявки(manifest["метаданные"])
        except наблюдения.ОшибкаМетаданных as ошибка:
            raise UpdateError("неверные заявки метаданных") from ошибка
        метаданные = tuple(manifest["метаданные"])
    elif schema == СХЕМА_МАНИФЕСТА_ЧЕТВЁРТОЙ_ВЕРСИИ:
        _require_exact_keys(manifest, ПОЛЯ_МАНИФЕСТА_ЧЕТВЁРТОЙ_ВЕРСИИ, "manifest")
        исходные_отмены = manifest.get("retirements")
        исходные_байтовые = manifest.get("байтовые_фикстуры")
        исходные_байтовые_отмены = manifest.get("отмены_байтовых_фикстур")
        try:
            наблюдения.разобрать_заявки(manifest["метаданные"])
        except наблюдения.ОшибкаМетаданных as ошибка:
            raise UpdateError("неверные заявки метаданных") from ошибка
        метаданные = tuple(manifest["метаданные"])
    else:
        raise UpdateError("unsupported manifest schema")
    raw_declarations = manifest.get("declarations")
    if not isinstance(raw_declarations, list):
        raise UpdateError("manifest declarations must be an array")
    if not isinstance(исходные_отмены, list):
        raise UpdateError("manifest retirements must be an array")
    if not isinstance(исходные_байтовые, list):
        raise UpdateError("поле байтовые_фикстуры манифеста должно быть массивом")
    if not isinstance(исходные_байтовые_отмены, list):
        raise UpdateError("поле отмены_байтовых_фикстур манифеста должно быть массивом")
    разобранные_байтовые_фикстуры = _разобрать_заявки_байтовых_фикстур(
        исходные_байтовые
    )
    разобранные_отмены = _parse_retirements(исходные_отмены)
    разобранные_отмены_байтовых_фикстур = _разобрать_отмены_байтовых_фикстур(
        исходные_байтовые_отмены
    )
    return UpdatePlan(
        declarations=_parse_declarations(
            raw_declarations,
            допускается_пустой=bool(
                метаданные
                or разобранные_байтовые_фикстуры
                or разобранные_отмены
                or разобранные_отмены_байтовых_фикстур
            ),
        ),
        retirements=разобранные_отмены,
        метаданные=метаданные,
        байтовые_фикстуры=разобранные_байтовые_фикстуры,
        отмены_байтовых_фикстур=разобранные_отмены_байтовых_фикстур,
    )


def load_manifest(path: str | Path) -> tuple[Declaration, ...]:
    """Load declarations while preserving the v1 public helper contract."""

    return load_update_plan(path).declarations


def parse_cli_declarations(values: Iterable[str]) -> tuple[Declaration, ...]:
    decoded: list[object] = []
    for index, text in enumerate(values):
        try:
            decoded.append(json.loads(text))
        except json.JSONDecodeError as exc:
            raise UpdateError(f"CLI declaration {index} is not JSON") from exc
    return _parse_declarations(decoded)


def _relative_policy_path(
    root: Path,
    input_root: Path,
    policy_path: Path,
) -> Path:
    candidate = policy_path if policy_path.is_absolute() else input_root / policy_path
    try:
        lexical_relative = candidate.relative_to(input_root)
    except ValueError as exc:
        raise UpdateError("policy path escapes the repository") from exc
    if ".." in lexical_relative.parts:
        raise UpdateError("policy path escapes the repository")
    _reject_symlink_components(input_root, lexical_relative.as_posix(), "policy")
    try:
        candidate.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise UpdateError("policy path escapes the repository") from exc
    return candidate


def _reject_symlink_components(root: Path, relative: str, label: str) -> None:
    cursor = root
    for part in PurePosixPath(relative).parts:
        cursor = cursor / part
        try:
            mode = cursor.lstat().st_mode
        except OSError as exc:
            raise UpdateError(f"{label} path is missing") from exc
        if stat.S_ISLNK(mode):
            raise UpdateError(f"{label} path contains a symlink")


def _отклонить_символические_компоненты_байтового_пути(
    корень: Path,
    относительный: str,
) -> None:
    текущий = корень
    for часть in PurePosixPath(относительный).parts:
        текущий = текущий / часть
        try:
            режим = текущий.lstat().st_mode
        except OSError as ошибка:
            raise UpdateError("путь байтовой фикстуры отсутствует") from ошибка
        if stat.S_ISLNK(режим):
            raise UpdateError(
                "путь байтовой фикстуры содержит символическую ссылку"
            )


def _load_policy_value(policy_path: Path) -> dict[str, object]:
    value = _load_canonical_json(policy_path, "policy")
    if not isinstance(value, dict):
        raise UpdateError("policy root must be an object")
    try:
        scanner.parse_policy(value)
    except scanner.PolicyError as exc:
        raise UpdateError("policy contract is invalid") from exc
    return value


def _inventory_by_path(root: Path) -> dict[str, object]:
    try:
        entries = scanner.git_inventory(root)
    except scanner.InventoryError as exc:
        raise UpdateError("Git inventory cannot be proven") from exc
    return {entry.path: entry for entry in entries}


def _read_target_text(
    root: Path,
    declaration: Declaration,
    inventory: dict[str, object],
) -> str:
    _reject_symlink_components(root, declaration.path, "declaration")
    entry = inventory.get(declaration.path)
    if entry is None:
        raise UpdateError("declaration path is not in the Git inventory")
    if entry.mode == "120000":
        raise UpdateError("declaration path is a tracked symlink")
    if entry.mode not in {None, "100644", "100755"}:
        raise UpdateError("declaration path has an unsupported Git mode")

    target = root / declaration.path
    try:
        mode = target.lstat().st_mode
        data = target.read_bytes()
    except OSError as exc:
        raise UpdateError("declaration path cannot be read") from exc
    if not stat.S_ISREG(mode):
        raise UpdateError("declaration path is not a regular file")
    if b"\0" in data:
        raise UpdateError("declaration path is binary")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise UpdateError("declaration path is not UTF-8") from exc


def _прочитать_байтовую_цель(
    корень: Path,
    заявка: ЗаявкаБайтовойФикстуры,
    инвентарь: dict[str, object],
) -> bytes:
    _отклонить_символические_компоненты_байтового_пути(корень, заявка.путь)
    запись = инвентарь.get(заявка.путь)
    if запись is None:
        raise UpdateError("путь байтовой фикстуры отсутствует в Git-инвентаре")
    if запись.mode == "120000":
        raise UpdateError("путь байтовой фикстуры является отслеживаемой символической ссылкой")
    if запись.mode != "100644":
        raise UpdateError("путь байтовой фикстуры должен иметь Git-режим 100644")
    цель = корень / заявка.путь
    try:
        режим = цель.lstat().st_mode
        данные = цель.read_bytes()
    except OSError as ошибка:
        raise UpdateError("путь байтовой фикстуры невозможно прочитать") from ошибка
    if not stat.S_ISREG(режим):
        raise UpdateError("путь байтовой фикстуры не является обычным файлом")
    if b"\0" in данные:
        raise UpdateError("путь байтовой фикстуры содержит NUL")
    размер_префикса = scanner._размер_префикса_оборванной_кодовой_последовательности(
        данные
    )
    if размер_префикса is None or not 1 <= len(данные) - размер_префикса <= 3:
        raise UpdateError("байтовая фикстура не оканчивается неполной UTF-8-последовательностью")
    return данные


def _вывести_байтовую_фикстуру(
    корень: Path,
    заявка: ЗаявкаБайтовойФикстуры,
    инвентарь: dict[str, object],
    кэш_источников: dict[str, bytes],
) -> object:
    данные = кэш_источников.get(заявка.путь)
    if данные is None:
        данные = _прочитать_байтовую_цель(корень, заявка, инвентарь)
        кэш_источников[заявка.путь] = данные
    размер_префикса = scanner._размер_префикса_оборванной_кодовой_последовательности(
        данные
    )
    assert размер_префикса is not None
    return scanner.БайтоваяФикстура(
        идентификатор=заявка.идентификатор,
        путь=заявка.путь,
        режим="100644",
        размер=len(данные),
        хэш="sha256:" + hashlib.sha256(данные).hexdigest(),
        вид=заявка.вид,
        размер_префикса=размер_префикса,
        шестнадцатеричный_хвост=данные[размер_префикса:].hex(),
        категория=заявка.категория,
        причина=заявка.причина,
    )


def _derive_exception(
    root: Path,
    declaration: Declaration,
    inventory: dict[str, object],
    text_cache: dict[str, tuple[int, tuple[object, ...]]],
) -> object:
    анализ = text_cache.get(declaration.path)
    if анализ is None:
        text = _read_target_text(root, declaration, inventory)
        число_строк = len(text.splitlines())
    else:
        число_строк = анализ[0]
    if declaration.line > число_строк:
        raise UpdateError("declaration line is outside the file")

    if анализ is None:
        candidates = tuple(scanner.scan_text(declaration.path, text))
        text_cache[declaration.path] = (число_строк, candidates)
    else:
        candidates = анализ[1]
    selected = [
        candidate
        for candidate in candidates
        if candidate.line == declaration.line
        and candidate.category.startswith("error.")
    ]
    identities = {(candidate.kind, candidate.line_sha256) for candidate in selected}
    if not identities:
        raise UpdateError("declaration line has no active error candidate")
    if len(identities) != 1:
        raise UpdateError("declaration line is ambiguous")
    kind, line_sha256 = next(iter(identities))
    count = sum(
        candidate.kind == kind
        and candidate.line_sha256 == line_sha256
        and candidate.category.startswith("error.")
        for candidate in candidates
    )
    if not 1 <= count <= scanner.MAX_EXCEPTION_COUNT:
        raise UpdateError("derived exception count is unsafe")
    return scanner.ExactException(
        identifier=declaration.identifier,
        path=declaration.path,
        kind=kind,
        line_sha256=line_sha256,
        count=count,
        category=declaration.category,
        reason=declaration.reason,
    )


def _exception_value(exception: object) -> dict[str, object]:
    return {
        "id": exception.identifier,
        "path": exception.path,
        "kind": exception.kind,
        "line_sha256": exception.line_sha256,
        "count": exception.count,
        "category": exception.category,
        "reason": exception.reason,
    }


def _значение_байтовой_фикстуры(фикстура: object) -> dict[str, object]:
    return {
        "идентификатор": фикстура.идентификатор,
        "путь": фикстура.путь,
        "режим": фикстура.режим,
        "размер": фикстура.размер,
        "хэш": фикстура.хэш,
        "вид": фикстура.вид,
        "размер_префикса": фикстура.размер_префикса,
        "шестнадцатеричный_хвост": фикстура.шестнадцатеричный_хвост,
        "категория": фикстура.категория,
        "причина": фикстура.причина,
    }


def _atomic_write(path: Path, content: bytes, expected: bytes, *, проверить_источники=None) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, stat.S_IMODE(path.stat().st_mode))
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        if проверить_источники is not None:
            проверить_источники()
        if path.read_bytes() != expected:
            raise UpdateError("policy changed during update")
        os.replace(temporary, path)
        directory_descriptor = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_descriptor)
        finally:
            os.close(directory_descriptor)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def update_policy(
    repo_root: str | Path,
    policy_path: str | Path,
    declarations: Iterable[object | Declaration],
    *,
    retirements: Iterable[object] = (),
    метаданные: Iterable[object] = (),
    байтовые_фикстуры: Iterable[object | ЗаявкаБайтовойФикстуры] = (),
    отмены_байтовых_фикстур: Iterable[object] = (),
) -> int:
    input_root = Path(repo_root).absolute()
    root = input_root.resolve()
    заявки = list(метаданные)
    try:
        выбранные = наблюдения.разобрать_заявки(заявки)
    except наблюдения.ОшибкаМетаданных as ошибка:
        raise UpdateError("неверные заявки метаданных") from ошибка
    разобранные_байтовые_заявки = _разобрать_заявки_байтовых_фикстур(
        ({
            "идентификатор": значение.идентификатор,
            "путь": значение.путь,
            "вид": значение.вид,
            "категория": значение.категория,
            "причина": значение.причина,
        }
        if isinstance(значение, ЗаявкаБайтовойФикстуры)
        else значение
        for значение in байтовые_фикстуры)
    )
    parsed_retirements = _parse_retirements(retirements)
    разобранные_отмены_байтовых_фикстур = _разобрать_отмены_байтовых_фикстур(
        отмены_байтовых_фикстур
    )
    parsed_declarations = _parse_declarations(
        ({
            "id": value.identifier,
            "path": value.path,
            "line": value.line,
            "category": value.category,
            "reason": value.reason,
        }
        if isinstance(value, Declaration)
        else value
        for value in declarations),
        допускается_пустой=bool(
            выбранные
            or разобранные_байтовые_заявки
            or parsed_retirements
            or разобранные_отмены_байтовых_фикстур
        ),
    )
    if {
        declaration.identifier for declaration in parsed_declarations
    }.intersection(заявка.идентификатор for заявка in разобранные_байтовые_заявки):
        raise UpdateError("declaration identifier collision")
    policy = _relative_policy_path(root, input_root, Path(policy_path))
    original = policy.read_bytes()
    value = _load_policy_value(policy)
    current_policy = scanner.parse_policy(value)
    inventory = _inventory_by_path(root)
    данные_метаданных = {запись.путь: _read_target_text(root,
        SimpleNamespace(path=запись.путь), inventory).encode("utf-8") for запись in выбранные}
    try:
        новые_метаданные = наблюдения.вывести_декларации(заявки, данные_метаданных)
    except наблюдения.ОшибкаМетаданных as ошибка:
        raise UpdateError("источник метаданных не соответствует заявке") from ошибка

    кэш_байтовых_источников: dict[str, bytes] = {}
    выведенные_байтовые_фикстуры = tuple(
        _вывести_байтовую_фикстуру(
            root,
            заявка,
            inventory,
            кэш_байтовых_источников,
        )
        for заявка in разобранные_байтовые_заявки
    )
    выведенные_по_идентификатору = {
        фикстура.идентификатор: фикстура
        for фикстура in выведенные_байтовые_фикстуры
    }

    current_by_id = {
        exception.identifier: exception for exception in current_policy.exceptions
    }
    retired_ids: set[str] = set()
    изменений = 0
    for retirement in parsed_retirements:
        existing = current_by_id.get(retirement.identifier)
        if existing is None:
            continue
        if existing != retirement:
            raise UpdateError("policy retirement mismatch")
        retired_ids.add(retirement.identifier)
        изменений += 1

    текущие_байтовые_по_идентификатору = {
        фикстура.идентификатор: фикстура
        for фикстура in current_policy.байтовые_фикстуры
    }
    отменённые_байтовые_идентификаторы: set[str] = set()
    for отмена in разобранные_отмены_байтовых_фикстур:
        существующая = текущие_байтовые_по_идентификатору.get(отмена.идентификатор)
        желаемая = выведенные_по_идентификатору.get(отмена.идентификатор)
        if существующая is None:
            continue
        if существующая == отмена:
            if желаемая == существующая:
                continue
            отменённые_байтовые_идентификаторы.add(отмена.идентификатор)
            изменений += 1
            continue
        if желаемая is not None and существующая == желаемая:
            continue
        raise UpdateError("отмена байтовой фикстуры не совпала с политикой")

    обновлённые_байтовые_фикстуры = [
        фикстура
        for фикстура in current_policy.байтовые_фикстуры
        if фикстура.идентификатор not in отменённые_байтовые_идентификаторы
    ]

    updated_exceptions = [
        exception
        for exception in current_policy.exceptions
        if exception.identifier not in retired_ids
    ]
    existing_by_id = {
        exception.identifier: exception for exception in updated_exceptions
    }
    existing_by_fingerprint = {
        (exception.path, exception.kind, exception.line_sha256): exception
        for exception in updated_exceptions
    }
    index_by_id = {
        exception.identifier: index
        for index, exception in enumerate(updated_exceptions)
    }
    text_cache: dict[str, tuple[int, tuple[object, ...]]] = {}
    for declaration in parsed_declarations:
        derived = _derive_exception(
            root,
            declaration,
            inventory,
            text_cache,
        )
        if any(
            фикстура.идентификатор == derived.identifier
            for фикстура in обновлённые_байтовые_фикстуры
        ):
            raise UpdateError("policy identifier collision")
        existing_id = existing_by_id.get(derived.identifier)
        if existing_id is not None:
            if existing_id == derived:
                continue
            if (
                existing_id.path != derived.path
                or existing_id.category != derived.category
                or existing_id.reason != derived.reason
            ):
                raise UpdateError("policy identifier collision")
            fingerprint = (derived.path, derived.kind, derived.line_sha256)
            fingerprint_owner = existing_by_fingerprint.get(fingerprint)
            if (
                fingerprint_owner is not None
                and fingerprint_owner.identifier != derived.identifier
            ):
                raise UpdateError("policy fingerprint collision")
            old_fingerprint = (
                existing_id.path,
                existing_id.kind,
                existing_id.line_sha256,
            )
            del existing_by_fingerprint[old_fingerprint]
            updated_exceptions[index_by_id[derived.identifier]] = derived
            existing_by_id[derived.identifier] = derived
            existing_by_fingerprint[fingerprint] = derived
            изменений += 1
            continue
        fingerprint = (derived.path, derived.kind, derived.line_sha256)
        if fingerprint in existing_by_fingerprint:
            raise UpdateError("policy fingerprint collision")
        index_by_id[derived.identifier] = len(updated_exceptions)
        updated_exceptions.append(derived)
        existing_by_id[derived.identifier] = derived
        existing_by_fingerprint[fingerprint] = derived
        изменений += 1

    байтовые_по_идентификатору = {
        фикстура.идентификатор: фикстура for фикстура in обновлённые_байтовые_фикстуры
    }
    байтовые_по_пути = {
        фикстура.путь: фикстура for фикстура in обновлённые_байтовые_фикстуры
    }
    for выведенная in выведенные_байтовые_фикстуры:
        if выведенная.идентификатор in existing_by_id:
            raise UpdateError("policy identifier collision")
        существующая = байтовые_по_идентификатору.get(выведенная.идентификатор)
        if существующая is not None:
            if существующая == выведенная:
                continue
            raise UpdateError("коллизия идентификатора байтовой политики")
        существующая_по_пути = байтовые_по_пути.get(выведенная.путь)
        if существующая_по_пути is not None:
            raise UpdateError("коллизия пути байтовой политики")
        обновлённые_байтовые_фикстуры.append(выведенная)
        байтовые_по_идентификатору[выведенная.идентификатор] = выведенная
        байтовые_по_пути[выведенная.путь] = выведенная
        изменений += 1

    обновлённые_метаданные = list(current_policy.метаданные)
    по_пути = {запись.путь: запись for запись in обновлённые_метаданные}
    for запись in новые_метаданные:
        прежняя = по_пути.get(запись.путь)
        if прежняя is not None:
            if прежняя != запись:
                raise UpdateError("коллизия точной декларации метаданных")
            continue
        обновлённые_метаданные.append(запись)
        по_пути[запись.путь] = запись
        изменений += 1
    if not изменений:
        return 0
    updated_value = {
        "schema": scanner.POLICY_SCHEMA,
        "exceptions": [
            _exception_value(exception) for exception in updated_exceptions
        ],
    }
    if value["schema"] == scanner.СХЕМА_БАЙТОВОЙ_ПОЛИТИКИ or обновлённые_байтовые_фикстуры:
        updated_value["schema"] = scanner.СХЕМА_БАЙТОВОЙ_ПОЛИТИКИ
        updated_value["метаданные"] = наблюдения.сериализовать_декларации(обновлённые_метаданные)
        updated_value["байтовые_фикстуры"] = [
            _значение_байтовой_фикстуры(фикстура)
            for фикстура in обновлённые_байтовые_фикстуры
        ]
    elif value["schema"] == наблюдения.СХЕМА_ПОЛИТИКИ or обновлённые_метаданные:
        updated_value["schema"] = наблюдения.СХЕМА_ПОЛИТИКИ
        updated_value["метаданные"] = наблюдения.сериализовать_декларации(обновлённые_метаданные)
    try:
        scanner.parse_policy(updated_value)
    except scanner.PolicyError as exc:
        raise UpdateError("derived policy is invalid") from exc
    encoded = _canonical_json(updated_value).encode("utf-8")
    if выбранные or кэш_байтовых_источников:
        def проверить_источники():
            актуальный = _inventory_by_path(root)
            for запись in выбранные:
                сырые = _read_target_text(root, SimpleNamespace(path=запись.путь), актуальный).encode("utf-8")
                if сырые != данные_метаданных[запись.путь]:
                    raise UpdateError("источник метаданных изменился перед заменой политики")
            for заявка in разобранные_байтовые_заявки:
                сырые = _прочитать_байтовую_цель(root, заявка, актуальный)
                if сырые != кэш_байтовых_источников[заявка.путь]:
                    raise UpdateError(
                        "источник байтовой фикстуры изменился перед заменой политики"
                    )
        _atomic_write(policy, encoded, original, проверить_источники=проверить_источники)
    else:
        _atomic_write(policy, encoded, original)
    return изменений


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--policy",
        type=Path,
        help="Policy to update; defaults to this automation's policy.json.",
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--manifest",
        type=Path,
        help="Canonical explicit declaration manifest.",
    )
    source.add_argument(
        "--declaration",
        action="append",
        help="Explicit declaration as a JSON object; may be repeated.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    arguments = parse_args(argv)
    root = arguments.repo_root.absolute()
    policy = arguments.policy
    if policy is None:
        policy = Path(__file__).resolve().parents[1] / "policy.json"
    try:
        plan = (
            load_update_plan(arguments.manifest)
            if arguments.manifest is not None
            else UpdatePlan(
                declarations=parse_cli_declarations(arguments.declaration or []),
                retirements=(),
            )
        )
        added = update_policy(
            root,
            policy,
            plan.declarations,
            retirements=plan.retirements,
            метаданные=plan.метаданные,
            байтовые_фикстуры=plan.байтовые_фикстуры,
            отмены_байтовых_фикстур=plan.отмены_байтовых_фикстур,
        )
    except (UpdateError, OSError) as exc:
        print(f"error.policy-update: {exc}", file=sys.stderr)
        return 2
    state = "updated" if added else "unchanged"
    print(f"policy.{state}: changes={added}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
