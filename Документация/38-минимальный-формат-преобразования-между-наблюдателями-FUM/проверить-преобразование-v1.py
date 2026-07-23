#!/usr/bin/env python3
"""Семантическая проверка записей преобразования между наблюдателями FUM v1."""

from __future__ import annotations

import argparse
import hashlib
import ipaddress
import json
import re
import socket
import sys
from pathlib import Path
from urllib.parse import parse_qsl, urlsplit


ROOT_KEYS = {
    "schema_version",
    "transformation_id",
    "scope",
    "source",
    "target",
    "transformation",
    "signal_mappings",
    "invariants",
    "losses",
    "reversibility",
    "full_information_route",
    "provenance_refs",
}
IDENTIFIER_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,127}$")
SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
WINDOWS_ABSOLUTE_RE = re.compile(r"^[A-Za-z]:[\\/]")
HOME_EXPANSION_PREFIX = chr(126) + "/"


def add_error(errors: list[str], record: Path, message: str) -> None:
    errors.append(f"{record}: {message}")


def load_object(path: Path, errors: list[str], record: Path) -> dict | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        add_error(errors, record, f"не удалось прочитать JSON {path}: {exc}")
        return None
    if not isinstance(value, dict):
        add_error(errors, record, f"{path} должен содержать JSON-объект")
        return None
    return value


def object_list(value: object, field: str, errors: list[str], record: Path) -> list[dict]:
    if not isinstance(value, list):
        add_error(errors, record, f"{field} должен быть массивом")
        return []
    result: list[dict] = []
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            add_error(errors, record, f"{field}[{index}] должен быть объектом")
            continue
        result.append(item)
    return result


def identifier_set(
    items: list[dict], field: str, label: str, errors: list[str], record: Path
) -> set[str]:
    result: set[str] = set()
    for index, item in enumerate(items):
        value = item.get(field)
        if not isinstance(value, str) or not IDENTIFIER_RE.fullmatch(value):
            add_error(errors, record, f"{label}[{index}].{field} не является допустимым ID")
            continue
        if value in result:
            add_error(errors, record, f"дубликат {label}.{field}: {value}")
        result.add(value)
    return result


def string_set(value: object, field: str, errors: list[str], record: Path) -> set[str]:
    if not isinstance(value, list) or not value:
        add_error(errors, record, f"{field} должен быть непустым массивом строк")
        return set()
    result: set[str] = set()
    for index, item in enumerate(value):
        if not isinstance(item, str) or not item:
            add_error(errors, record, f"{field}[{index}] должен быть непустой строкой")
            continue
        if item in result:
            add_error(errors, record, f"дубликат в {field}: {item}")
        result.add(item)
    return result


def passed_check(value: object) -> bool:
    return isinstance(value, dict) and value.get("status") == "passed"


def is_private_http_url(value: str) -> bool:
    parts = urlsplit(value)
    if parts.scheme.casefold() not in {"http", "https"}:
        return False
    if parts.username or parts.password:
        return True
    host = parts.hostname
    if not host:
        return True
    host = host.rstrip(".").casefold()
    if host == "localhost" or host.endswith((".localhost", ".local", ".internal", ".lan", ".home")):
        return True
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        try:
            address = ipaddress.ip_address(socket.inet_ntoa(socket.inet_aton(host)))
        except OSError:
            return False
    return address.is_private or address.is_loopback or address.is_link_local


def has_secret_http_parameter(value: str) -> bool:
    parts = urlsplit(value)
    if parts.scheme.casefold() not in {"http", "https"}:
        return False
    secret_markers = ("token", "secret", "password", "passwd", "credential", "api_key", "apikey", "signature")
    parameter_keys = [key for key, _ in parse_qsl(parts.query)] + [key for key, _ in parse_qsl(parts.fragment)]
    if any(any(marker in key.casefold() for marker in secret_markers) for key in parameter_keys):
        return True
    folded_fragment = parts.fragment.casefold()
    return any(marker in folded_fragment for marker in secret_markers)


def resolve_repo_path(value: str, root: Path) -> Path | None:
    folded = value.casefold()
    if value.startswith(("/", HOME_EXPANSION_PREFIX)) or folded.startswith("file:") or WINDOWS_ABSOLUTE_RE.match(value):
        return None
    if "\\" in value or SCHEME_RE.match(value):
        return None
    candidate = (root / value.split("#", 1)[0]).resolve()
    try:
        candidate.relative_to(root)
    except ValueError:
        return None
    return candidate


def validate_ref(value: str, field: str, root: Path, errors: list[str], record: Path) -> None:
    folded = value.casefold()
    if value.startswith(("/", HOME_EXPANSION_PREFIX)) or folded.startswith("file:") or WINDOWS_ABSOLUTE_RE.match(value):
        add_error(errors, record, f"{field} содержит машинно-локальный абсолютный путь: {value}")
        return
    if "\\" in value:
        add_error(errors, record, f"{field} должен использовать публикационный POSIX-путь: {value}")
        return
    if is_private_http_url(value):
        add_error(errors, record, f"{field} содержит приватный или локальный URL: {value}")
        return
    if has_secret_http_parameter(value):
        add_error(errors, record, f"{field} содержит похожий на секрет параметр URL: {value}")
        return
    if SCHEME_RE.match(value):
        scheme = value.split(":", 1)[0].casefold()
        if scheme not in {"http", "https", "urn", "sha256", "derived", "value", "operation"}:
            add_error(errors, record, f"{field} использует неподдерживаемую схему ссылки: {value}")
        return

    path_part = value.split("#", 1)[0]
    if not path_part:
        add_error(errors, record, f"{field} не содержит разрешимого пути: {value}")
        return
    candidate = (root / path_part).resolve()
    try:
        candidate.relative_to(root)
    except ValueError:
        add_error(errors, record, f"{field} выходит за корень памяти FUM: {value}")
        return
    if not candidate.exists():
        add_error(errors, record, f"{field} ссылается на отсутствующий путь: {value}")


def walk_refs(value: object, root: Path, errors: list[str], record: Path, prefix: str = "") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            field = f"{prefix}.{key}" if prefix else key
            if key.endswith("_ref") and child is not None:
                if isinstance(child, str) and child:
                    validate_ref(child, field, root, errors, record)
                else:
                    add_error(errors, record, f"{field} должен быть непустой строкой или null")
            elif key.endswith("_refs"):
                if not isinstance(child, list):
                    add_error(errors, record, f"{field} должен быть массивом ссылок")
                else:
                    for index, item in enumerate(child):
                        if isinstance(item, str) and item:
                            validate_ref(item, f"{field}[{index}]", root, errors, record)
                        else:
                            add_error(errors, record, f"{field}[{index}] должен быть непустой строкой")
            walk_refs(child, root, errors, record, field)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk_refs(child, root, errors, record, f"{prefix}[{index}]")


def validate_sidecar(
    discovery: dict,
    data: dict,
    record_path: Path,
    root: Path,
    errors: list[str],
) -> None:
    if discovery.get("method") != "sidecar":
        return
    context_ref = discovery.get("delivery_context_ref")
    locator_ref = discovery.get("locator_ref")
    if not isinstance(context_ref, str) or not isinstance(locator_ref, str):
        return
    if SCHEME_RE.match(context_ref) or SCHEME_RE.match(locator_ref):
        add_error(errors, record_path, "sidecar требует локальные публикационные delivery_context_ref и locator_ref")
        return
    context_path = resolve_repo_path(context_ref, root)
    if context_path is None:
        add_error(errors, record_path, "delivery_context_ref нельзя читать вне корня памяти FUM")
        return
    manifest = load_object(context_path, errors, record_path)
    if manifest is None:
        return
    expected_keys = {"target_state_ref", "transformation_id", "transformation_record_ref"}
    if set(manifest) != expected_keys:
        add_error(errors, record_path, "контекст поставки должен содержать точный набор binding-полей")
    if manifest.get("target_state_ref") != data.get("target", {}).get("state_ref"):
        add_error(errors, record_path, "контекст поставки не совпадает с target.state_ref")
    if manifest.get("transformation_id") != data.get("transformation_id"):
        add_error(errors, record_path, "контекст поставки не совпадает с transformation_id")
    try:
        record_ref = record_path.resolve().relative_to(root).as_posix()
    except ValueError:
        add_error(errors, record_path, "проверяемая запись находится вне корня памяти FUM")
        return
    if manifest.get("transformation_record_ref") != record_ref:
        add_error(errors, record_path, "контекст поставки не указывает на проверяемую запись")
    if locator_ref != record_ref:
        add_error(errors, record_path, "record_discovery.locator_ref не указывает на проверяемую запись")


def validate_known_fixture(data: dict, record: Path, root: Path, errors: list[str]) -> None:
    method = data.get("transformation", {}).get("method")
    source_ref = data.get("source", {}).get("layer_ref")
    state_ref = data.get("source", {}).get("state_ref")
    if not isinstance(source_ref, str) or SCHEME_RE.match(source_ref):
        return
    source_path = resolve_repo_path(source_ref, root)
    if source_path is None:
        add_error(errors, record, "source.layer_ref нельзя читать вне корня памяти FUM")
        return
    try:
        raw = source_path.read_bytes()
    except OSError as exc:
        add_error(errors, record, f"не удалось прочитать source.layer_ref: {exc}")
        return
    if isinstance(state_ref, str) and state_ref.startswith("sha256:"):
        actual = "sha256:" + hashlib.sha256(raw).hexdigest()
        if actual != state_ref:
            add_error(errors, record, f"source.state_ref не совпадает с SHA-256: {actual}")

    if method == "decode-utf8-strict":
        try:
            restored = raw.decode("utf-8", errors="strict").encode("utf-8", errors="strict")
        except UnicodeError as exc:
            add_error(errors, record, f"строгий UTF-8 round-trip завершился ошибкой: {exc}")
            return
        if restored != raw:
            add_error(errors, record, "строгий UTF-8 round-trip не восстановил исходные байты")
    elif method == "extract-first-h1":
        text = raw.decode("utf-8", errors="strict")
        first = next((line for line in text.splitlines() if line.strip()), None)
        source_samples = {
            item.get("signal_id"): item.get("sample_value")
            for item in data.get("source", {}).get("observed_signals", [])
            if isinstance(item, dict)
        }
        target_samples = {
            item.get("signal_id"): item.get("sample_value")
            for item in data.get("target", {}).get("observed_signals", [])
            if isinstance(item, dict)
        }
        if first != source_samples.get("source.title") or not first or not first.startswith("# "):
            add_error(errors, record, "source.title не совпадает с полным первым H1 закреплённого источника")
        elif first[2:] != target_samples.get("target.title"):
            add_error(errors, record, "удаление маркера H1 не даёт target.title")
        counterexample = data.get("reversibility", {}).get("counterexample")
        if isinstance(counterexample, dict):
            def extract(value: object) -> str | None:
                if not isinstance(value, str):
                    return None
                heading = next((line for line in value.splitlines() if line.strip()), None)
                return heading[2:] if heading and heading.startswith("# ") else None

            source_a = counterexample.get("source_a")
            source_b = counterexample.get("source_b")
            target_a = extract(source_a)
            target_b = extract(source_b)
            if source_a == source_b or target_a is None or target_a != target_b:
                add_error(errors, record, "counterexample не подтверждает коллизию extract-first-h1")
            if target_a != counterexample.get("target_a") or target_b != counterexample.get("target_b"):
                add_error(errors, record, "вычисленные значения counterexample не совпадают с заявленными")


def validate_record(data: dict, record: Path, root: Path) -> list[str]:
    errors: list[str] = []
    if set(data) != ROOT_KEYS:
        missing = sorted(ROOT_KEYS - set(data))
        extra = sorted(set(data) - ROOT_KEYS)
        add_error(errors, record, f"неверный набор корневых полей; missing={missing}, extra={extra}")
    if data.get("schema_version") != 1:
        add_error(errors, record, "schema_version должен быть равен 1")
    transformation_id = data.get("transformation_id")
    if not isinstance(transformation_id, str) or not IDENTIFIER_RE.fullmatch(transformation_id):
        add_error(errors, record, "transformation_id не является допустимым ID")

    source = data.get("source")
    target = data.get("target")
    if not isinstance(source, dict) or not isinstance(target, dict):
        add_error(errors, record, "source и target должны быть объектами")
        return errors
    source_signals = object_list(source.get("observed_signals"), "source.observed_signals", errors, record)
    target_signals = object_list(target.get("observed_signals"), "target.observed_signals", errors, record)
    source_ids = identifier_set(source_signals, "signal_id", "source.observed_signals", errors, record)
    target_ids = identifier_set(target_signals, "signal_id", "target.observed_signals", errors, record)
    if not passed_check(source.get("inventory_check")):
        add_error(errors, record, "source.inventory_check должен иметь status=passed")
    if not passed_check(target.get("inventory_check")):
        add_error(errors, record, "target.inventory_check должен иметь status=passed")

    mappings = object_list(data.get("signal_mappings"), "signal_mappings", errors, record)
    losses = object_list(data.get("losses"), "losses", errors, record)
    invariants = object_list(data.get("invariants"), "invariants", errors, record)
    identifier_set(mappings, "mapping_id", "signal_mappings", errors, record)
    identifier_set(losses, "loss_id", "losses", errors, record)
    invariant_ids = identifier_set(invariants, "invariant_id", "invariants", errors, record)
    passed_invariant_ids = {
        item.get("invariant_id")
        for item in invariants
        if isinstance(item.get("check"), dict) and item["check"].get("status") == "passed"
    }
    mapped_source: set[str] = set()
    mapped_target: set[str] = set()
    for index, mapping in enumerate(mappings):
        sources = string_set(mapping.get("source_signal_ids"), f"signal_mappings[{index}].source_signal_ids", errors, record)
        targets = string_set(mapping.get("target_signal_ids"), f"signal_mappings[{index}].target_signal_ids", errors, record)
        mapping_invariants = string_set(mapping.get("invariant_ids"), f"signal_mappings[{index}].invariant_ids", errors, record)
        unknown_sources = sources - source_ids
        unknown_targets = targets - target_ids
        if unknown_sources:
            add_error(errors, record, f"mapping ссылается на неизвестные source IDs: {sorted(unknown_sources)}")
        if unknown_targets:
            add_error(errors, record, f"mapping ссылается на неизвестные target IDs: {sorted(unknown_targets)}")
        if mapping_invariants - invariant_ids:
            add_error(errors, record, f"mapping ссылается на неизвестные invariant IDs: {sorted(mapping_invariants - invariant_ids)}")
        if mapping.get("status") == "preserved" and not (mapping_invariants & passed_invariant_ids):
            add_error(errors, record, "mapping.status=preserved требует связанный passed-инвариант")
        mapped_source.update(sources)
        mapped_target.update(targets)
    lost_source: set[str] = set()
    irrecoverably_lost_source: set[str] = set()
    for index, loss in enumerate(losses):
        sources = string_set(loss.get("source_signal_ids"), f"losses[{index}].source_signal_ids", errors, record)
        unknown_sources = sources - source_ids
        if unknown_sources:
            add_error(errors, record, f"loss ссылается на неизвестные source IDs: {sorted(unknown_sources)}")
        lost_source.update(sources)
        if loss.get("recoverable_from_target") is False:
            irrecoverably_lost_source.update(sources)
    if source_ids - (mapped_source | lost_source):
        add_error(errors, record, f"не учтены source IDs: {sorted(source_ids - (mapped_source | lost_source))}")
    if target_ids - mapped_target:
        add_error(errors, record, f"не указано происхождение target IDs: {sorted(target_ids - mapped_target)}")

    reversibility = data.get("reversibility")
    if not isinstance(reversibility, dict):
        add_error(errors, record, "reversibility должен быть объектом")
    else:
        claim = reversibility.get("claim")
        check_status = reversibility.get("check", {}).get("status") if isinstance(reversibility.get("check"), dict) else None
        if claim == "reversible":
            if check_status != "passed" or not reversibility.get("inverse_ref"):
                add_error(errors, record, "reversible требует passed-check и inverse_ref")
            if any(loss.get("recoverable_from_target") is False for loss in losses):
                add_error(errors, record, "reversible несовместим с невосстановимой потерей")
        elif claim == "partially_reversible":
            recoverable = string_set(reversibility.get("recoverable_signal_ids"), "reversibility.recoverable_signal_ids", errors, record)
            if recoverable - source_ids:
                add_error(errors, record, f"неизвестные recoverable_signal_ids: {sorted(recoverable - source_ids)}")
            if check_status != "passed" or not reversibility.get("inverse_ref"):
                add_error(errors, record, "partially_reversible требует passed-check и inverse_ref")
            if recoverable == source_ids:
                add_error(errors, record, "partially_reversible требует собственное подмножество recoverable_signal_ids")
            if recoverable & irrecoverably_lost_source:
                add_error(errors, record, "recoverable_signal_ids пересекаются с невосстановимой потерей")
            if (source_ids - recoverable) - irrecoverably_lost_source:
                add_error(errors, record, "каждый невосстанавливаемый source ID должен иметь recoverable_from_target=false loss")
        elif claim == "irreversible":
            if check_status != "passed" or reversibility.get("inverse_ref") is not None:
                add_error(errors, record, "irreversible требует passed-check и inverse_ref=null")
            if not reversibility.get("counterexample") and not reversibility.get("proof_refs"):
                add_error(errors, record, "irreversible требует counterexample или proof_refs")
            if not irrecoverably_lost_source:
                add_error(errors, record, "irreversible требует хотя бы одну явную невосстановимую потерю")
        elif claim == "undetermined":
            if check_status not in {"failed", "inconclusive"} or not reversibility.get("reason"):
                add_error(errors, record, "undetermined требует reason и failed/inconclusive-check")
        else:
            add_error(errors, record, f"неизвестный reversibility.claim: {claim}")

    route = data.get("full_information_route")
    if not isinstance(route, dict):
        add_error(errors, record, "full_information_route должен быть объектом")
    else:
        if route.get("starting_point") != "target_delivery_context":
            add_error(errors, record, "маршрут должен начинаться в target_delivery_context")
        if not passed_check(route.get("check")):
            add_error(errors, record, "full_information_route.check должен иметь status=passed")
        discovery = route.get("record_discovery")
        if not isinstance(discovery, dict) or not passed_check(discovery.get("check")):
            add_error(errors, record, "record_discovery должен иметь status=passed")
        elif discovery.get("method") != "sidecar":
            add_error(errors, record, "версия 1 поддерживает только проверяемый record_discovery.method=sidecar")
        else:
            validate_sidecar(discovery, data, record, root, errors)
        source_binding = route.get("source_binding")
        expected_binding = {
            "layer_ref": source.get("layer_ref"),
            "state_ref": source.get("state_ref"),
        }
        if source_binding != expected_binding:
            add_error(errors, record, "full_information_route.source_binding не совпадает с точным source")
        status = route.get("status")
        if status in {"available", "restricted"}:
            covered = string_set(route.get("covered_signal_ids"), "full_information_route.covered_signal_ids", errors, record)
            if covered != source_ids:
                add_error(errors, record, f"route не покрывает точный source-инвентарь: {sorted(source_ids - covered)}")
            if not route.get("source_refs") or not route.get("steps"):
                add_error(errors, record, f"{status} требует source_refs и steps")
            if source.get("layer_ref") not in route.get("source_refs", []):
                add_error(errors, record, "route.source_refs не содержит source.layer_ref")
            step_targets = {
                step.get("target_ref")
                for step in route.get("steps", [])
                if isinstance(step, dict)
            }
            if source.get("state_ref") not in step_targets:
                add_error(errors, record, "route.steps не закрепляют точный source.state_ref")
            if status == "restricted" and not route.get("access_constraints"):
                add_error(errors, record, "restricted требует access_constraints")
            if route.get("affected_signal_ids") is not None or route.get("reason") is not None:
                add_error(errors, record, f"{status} не допускает affected_signal_ids или reason")
        elif status == "unavailable":
            affected = string_set(route.get("affected_signal_ids"), "full_information_route.affected_signal_ids", errors, record)
            if affected - source_ids:
                add_error(errors, record, f"неизвестные affected_signal_ids: {sorted(affected - source_ids)}")
            if route.get("source_refs") or route.get("steps") or not route.get("reason"):
                add_error(errors, record, "unavailable требует пустые source_refs/steps и непустой reason")
            if route.get("covered_signal_ids") is not None:
                add_error(errors, record, "unavailable не допускает covered_signal_ids")
        else:
            add_error(errors, record, f"неизвестный full_information_route.status: {status}")

    provenance = data.get("provenance_refs")
    if not isinstance(provenance, list):
        add_error(errors, record, "provenance_refs должен быть массивом")
    else:
        if not any(isinstance(ref, str) and ref.startswith("Документация/") for ref in provenance):
            add_error(errors, record, "provenance_refs не содержит нормативный документ формата")
        if not any(isinstance(ref, str) and ref.startswith("Запросы/") for ref in provenance):
            add_error(errors, record, "provenance_refs не содержит исходное требование")

    walk_refs(data, root, errors, record)
    validate_known_fixture(data, record, root, errors)
    return errors


def discover_published_records(directory: Path, root: Path, errors: list[str]) -> list[Path]:
    records: list[Path] = []
    for path in sorted(directory.rglob("*.json")):
        resolved = path.resolve()
        try:
            resolved.relative_to(root)
        except ValueError:
            errors.append(f"{path}: JSON публикационного набора разрешается вне корня памяти FUM")
            continue
        try:
            value = json.loads(resolved.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            errors.append(f"{resolved}: не удалось разобрать JSON публикационного набора: {exc}")
            continue
        if isinstance(value, dict) and value.get("schema_version") == 1 and {
            "transformation_id",
            "source",
            "target",
        }.issubset(value):
            records.append(resolved)
    return records


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("records", nargs="*", type=Path, help="дополнительные JSON-записи преобразований")
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="корень памяти FUM",
    )
    parser.add_argument(
        "--published-root",
        type=Path,
        default=Path(__file__).resolve().parent,
        help="каталог публикационного набора версии 1, сканируемый целиком для проверки уникальности ID",
    )
    args = parser.parse_args()
    root = args.repo_root.resolve()
    published_root = args.published_root
    if not published_root.is_absolute():
        published_root = root / published_root
    published_root = published_root.resolve()
    try:
        published_root.relative_to(root)
    except ValueError:
        print(f"{published_root}: публикационный набор находится вне корня памяти FUM", file=sys.stderr)
        return 1
    all_errors: list[str] = []
    seen_ids: dict[str, Path] = {}
    checked = 0
    supplied_records = [path if path.is_absolute() else root / path for path in args.records]
    records = sorted(set(discover_published_records(published_root, root, all_errors) + [path.resolve() for path in supplied_records]))
    if not records:
        print(f"{published_root}: записи преобразований версии 1 не найдены", file=sys.stderr)
        return 1
    for record in records:
        try:
            record.relative_to(root)
        except ValueError:
            add_error(all_errors, record, "проверяемая запись находится вне корня памяти FUM")
            continue
        data = load_object(record, all_errors, record)
        if data is None:
            continue
        checked += 1
        transformation_id = data.get("transformation_id")
        if isinstance(transformation_id, str):
            previous = seen_ids.get(transformation_id)
            if previous is not None:
                add_error(all_errors, record, f"transformation_id уже использован в {previous}")
            else:
                seen_ids[transformation_id] = record
        all_errors.extend(validate_record(data, record, root))
    if all_errors:
        for error in all_errors:
            print(error, file=sys.stderr)
        return 1
    print(f"Проверка преобразований между наблюдателями FUM пройдена: записей — {checked}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
