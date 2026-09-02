#!/usr/bin/env python3
"""Узкий независимый verifier байтового профиля памяти FUM v1."""

from __future__ import annotations

import argparse
import base64
import binascii
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PROFILE_ID = "fum.memory.canonical-json.v1"
MAXIMUM_SAFE_INTEGER = 9_007_199_254_740_991
MAXIMUM_DEPTH = 128
MEMBER_NAME = re.compile(r"[a-z][a-z0-9_]*\Z", re.ASCII)
HEX = frozenset("0123456789abcdefABCDEF")


class ProfileError(ValueError):
    pass


@dataclass
class Parser:
    text: str
    index: int = 0

    def parse(self) -> dict[str, Any]:
        self._skip_whitespace()
        value = self._value(0)
        self._skip_whitespace()
        if self.index != len(self.text):
            raise ProfileError("лишние данные после JSON")
        if not isinstance(value, dict):
            raise ProfileError("верхний уровень не является объектом")
        return value

    def _value(self, depth: int) -> Any:
        if depth > MAXIMUM_DEPTH:
            raise ProfileError("превышена глубина JSON")
        current = self._peek()
        if current == "{":
            return self._object(depth + 1)
        if current == "[":
            return self._array(depth + 1)
        if current == '"':
            return self._string()
        if self.text.startswith("true", self.index):
            self.index += 4
            return True
        if self.text.startswith("false", self.index):
            self.index += 5
            return False
        if self.text.startswith("null", self.index):
            raise ProfileError("null запрещён")
        if current == "-" or (current is not None and current.isascii() and current.isdigit()):
            return self._integer()
        raise ProfileError("недопустимое JSON-значение")

    def _object(self, depth: int) -> dict[str, Any]:
        self._expect("{")
        self._skip_whitespace()
        result: dict[str, Any] = {}
        if self._take("}"):
            return result
        while True:
            if self._peek() != '"':
                raise ProfileError("имя поля не является строкой")
            key = self._string()
            if MEMBER_NAME.fullmatch(key) is None:
                raise ProfileError("имя поля не соответствует ASCII-схеме")
            if key in result:
                raise ProfileError("повторное имя поля")
            self._skip_whitespace()
            self._expect(":")
            self._skip_whitespace()
            result[key] = self._value(depth)
            self._skip_whitespace()
            if self._take("}"):
                return result
            self._expect(",")
            self._skip_whitespace()

    def _array(self, depth: int) -> list[Any]:
        self._expect("[")
        self._skip_whitespace()
        result: list[Any] = []
        if self._take("]"):
            return result
        while True:
            result.append(self._value(depth))
            self._skip_whitespace()
            if self._take("]"):
                return result
            self._expect(",")
            self._skip_whitespace()

    def _string(self) -> str:
        self._expect('"')
        result: list[str] = []
        while True:
            current = self._peek()
            if current is None:
                raise ProfileError("незакрытая строка")
            self.index += 1
            if current == '"':
                value = "".join(result)
                _validate_unicode(value)
                return value
            if current == "\\":
                result.append(self._escape())
            elif ord(current) <= 0x1F:
                raise ProfileError("неэкранированный управляющий символ")
            else:
                result.append(current)

    def _escape(self) -> str:
        current = self._peek()
        if current is None:
            raise ProfileError("незавершённый escape")
        self.index += 1
        short = {'"': '"', "\\": "\\", "/": "/", "b": "\b", "f": "\f", "n": "\n", "r": "\r", "t": "\t"}
        if current in short:
            return short[current]
        if current != "u":
            raise ProfileError("неизвестный escape")
        first = self._hex_scalar()
        if 0xD800 <= first <= 0xDBFF:
            self._expect("\\")
            self._expect("u")
            second = self._hex_scalar()
            if not 0xDC00 <= second <= 0xDFFF:
                raise ProfileError("нарушенная пара суррогатов")
            scalar = 0x10000 + ((first - 0xD800) << 10) + second - 0xDC00
        elif 0xDC00 <= first <= 0xDFFF:
            raise ProfileError("одиночный младший суррогат")
        else:
            scalar = first
        value = chr(scalar)
        _validate_unicode(value)
        return value

    def _hex_scalar(self) -> int:
        end = self.index + 4
        digits = self.text[self.index:end]
        if len(digits) != 4 or any(character not in HEX for character in digits):
            raise ProfileError("Unicode escape не содержит четыре hex-цифры")
        self.index = end
        return int(digits, 16)

    def _integer(self) -> int:
        start = self.index
        if self._take("-"):
            raise ProfileError("отрицательные числа запрещены")
        first = self._peek()
        if first == "0":
            self.index += 1
            next_character = self._peek()
            if next_character is not None and next_character.isascii() and next_character.isdigit():
                raise ProfileError("ведущий ноль")
        elif first is not None and first.isascii() and "1" <= first <= "9":
            while True:
                current = self._peek()
                if current is None or not current.isascii() or not current.isdigit():
                    break
                self.index += 1
        else:
            raise ProfileError("недопустимая целая часть")
        current = self._peek()
        if current in (".", "e", "E"):
            raise ProfileError("дробное число или экспонента")
        value = int(self.text[start:self.index])
        if value > MAXIMUM_SAFE_INTEGER:
            raise ProfileError("целое число вне safe-integer диапазона")
        return value

    def _skip_whitespace(self) -> None:
        while self._peek() in (" ", "\t", "\n", "\r"):
            self.index += 1

    def _peek(self) -> str | None:
        return self.text[self.index] if self.index < len(self.text) else None

    def _take(self, expected: str) -> bool:
        if self._peek() != expected:
            return False
        self.index += 1
        return True

    def _expect(self, expected: str) -> None:
        if not self._take(expected):
            raise ProfileError("неожиданный JSON-символ")


def _validate_unicode(value: str) -> None:
    for character in value:
        scalar = ord(character)
        if 0xD800 <= scalar <= 0xDFFF or 0xFDD0 <= scalar <= 0xFDEF or scalar & 0xFFFF in (0xFFFE, 0xFFFF):
            raise ProfileError("запрещённый Unicode scalar")


def _write_string(value: str) -> bytes:
    _validate_unicode(value)
    result = bytearray(b'"')
    short = {0x08: b"\\b", 0x09: b"\\t", 0x0A: b"\\n", 0x0C: b"\\f", 0x0D: b"\\r"}
    for character in value:
        scalar = ord(character)
        if scalar in short:
            result.extend(short[scalar])
        elif scalar <= 0x1F:
            result.extend(f"\\u{scalar:04x}".encode("ascii"))
        elif character == '"':
            result.extend(b'\\"')
        elif character == "\\":
            result.extend(b"\\\\")
        else:
            result.extend(character.encode("utf-8"))
    result.extend(b'"')
    return bytes(result)


def _serialize(value: Any, depth: int = 0) -> bytes:
    if depth > MAXIMUM_DEPTH:
        raise ProfileError("превышена глубина JSON")
    if isinstance(value, dict):
        fields = []
        for key in sorted(value, key=lambda item: item.encode("ascii")):
            fields.append(_write_string(key) + b":" + _serialize(value[key], depth + 1))
        return b"{" + b",".join(fields) + b"}"
    if isinstance(value, list):
        return b"[" + b",".join(_serialize(item, depth + 1) for item in value) + b"]"
    if isinstance(value, str):
        return _write_string(value)
    if value is True:
        return b"true"
    if value is False:
        return b"false"
    if type(value) is int and 0 <= value <= MAXIMUM_SAFE_INTEGER:
        return str(value).encode("ascii")
    raise ProfileError("запрещённый тип значения")


def canonicalize(data: bytes) -> bytes:
    try:
        text = data.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise ProfileError("недопустимый UTF-8") from error
    return _serialize(Parser(text).parse())


def _decode_base64(value: str) -> bytes:
    try:
        return base64.b64decode(value, validate=True)
    except (binascii.Error, ValueError) as error:
        raise ProfileError("недопустимый Base64 в manifest") from error


def _payload(vector: dict[str, Any], field: str, directory: Path) -> bytes:
    inline = vector.get(field)
    if inline is not None:
        return _decode_base64(inline)
    filename = vector.get(f"{field}_file")
    if not isinstance(filename, str) or Path(filename).name != filename:
        raise ProfileError("недопустимая ссылка на payload")
    return _decode_base64((directory / filename).read_text(encoding="ascii").strip())


def _sha256(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def verify_manifest(path: Path) -> dict[str, Any]:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("profile") != PROFILE_ID or manifest.get("schema_version") != 1:
        raise ProfileError("неподдерживаемый manifest")
    accepted = manifest.get("accepted")
    rejected = manifest.get("rejected")
    hashes = manifest.get("hashes")
    if not all(isinstance(group, list) for group in (accepted, rejected, hashes)):
        raise ProfileError("manifest не содержит три массива векторов")
    vectors = [*accepted, *rejected, *hashes]
    identifiers = [vector.get("id") for vector in vectors]
    if any(not isinstance(identifier, str) or not identifier for identifier in identifiers):
        raise ProfileError("вектор не содержит непустой id")
    if len(set(identifiers)) != len(identifiers):
        raise ProfileError("id векторов должны быть уникальны")
    allowed_carriers = {"json_object", "event", "program", "generation", "current_pointer"}
    if any(vector.get("carrier") not in allowed_carriers for vector in [*accepted, *rejected]):
        raise ProfileError("неизвестный carrier")
    if any(vector.get("mode") not in {"invalid", "noncanonical"} for vector in rejected):
        raise ProfileError("неизвестный mode отказа")
    checked: list[dict[str, str]] = []
    for vector in accepted:
        expected = _payload(vector, "canonical_base64", path.parent)
        source = (
            _payload(vector, "input_base64", path.parent)
            if "input_base64" in vector or "input_base64_file" in vector
            else expected
        )
        actual = canonicalize(source)
        if actual != expected or canonicalize(expected) != expected:
            raise ProfileError(f"несовпадение байтов: {vector['id']}")
        actual_hash = _sha256(actual)
        if actual_hash != vector["canonical_sha256"]:
            raise ProfileError(f"несовпадение SHA-256: {vector['id']}")
        checked.append({"id": vector["id"], "verdict": "accepted", "sha256": actual_hash})
    for vector in rejected:
        source = _decode_base64(vector["input_base64"])
        mode = vector["mode"]
        try:
            canonical = canonicalize(source)
        except ProfileError:
            if mode != "invalid":
                raise ProfileError(f"неверный класс отказа: {vector['id']}")
        else:
            if mode != "noncanonical" or canonical == source:
                raise ProfileError(f"вектор не отклонён: {vector['id']}")
        checked.append({"id": vector["id"], "verdict": "rejected", "sha256": ""})
    for vector in hashes:
        if _sha256(_decode_base64(vector["input_base64"])) != vector["sha256"]:
            raise ProfileError(f"несовпадение отдельного SHA-256: {vector['id']}")
        checked.append({"id": vector["id"], "verdict": "hash", "sha256": vector["sha256"]})
    return {"profile": PROFILE_ID, "checked": checked}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--json", action="store_true")
    arguments = parser.parse_args()
    try:
        result = verify_manifest(arguments.manifest)
    except (OSError, KeyError, TypeError, json.JSONDecodeError, ProfileError) as error:
        print(f"Ошибка conformance: {error}", file=sys.stderr)
        return 1
    if arguments.json:
        print(json.dumps(result, ensure_ascii=False, sort_keys=True, separators=(",", ":")))
    else:
        print(f"Проверено векторов: {len(result['checked'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
