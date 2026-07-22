#!/usr/bin/env python3
"""Print a canonical FUM working-session timestamp in Moscow time."""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo


MSK = ZoneInfo("Europe/Moscow")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--at",
        metavar="ISO-8601",
        help=(
            "Convert a specific instant instead of the current time. "
            "The value must contain Z or an explicit UTC offset."
        ),
    )
    parser.add_argument(
        "--format",
        choices=("prefix", "label", "both"),
        default="prefix",
        help="Select the filename prefix, heading label, or both forms.",
    )
    return parser.parse_args()


def parse_instant(value: str) -> datetime:
    normalized = value[:-1] + "+00:00" if value.endswith(("Z", "z")) else value
    try:
        instant = datetime.fromisoformat(normalized)
    except ValueError as exc:
        raise ValueError(f"invalid ISO-8601 instant: {value}") from exc
    if instant.tzinfo is None or instant.utcoffset() is None:
        raise ValueError("--at must contain Z or an explicit UTC offset")
    return instant


def session_time(value: str | None) -> datetime:
    instant = datetime.now(timezone.utc) if value is None else parse_instant(value)
    return instant.astimezone(MSK)


def format_prefix(value: datetime) -> str:
    return value.strftime("%Y-%m-%d_%H-%M-%S_MSK")


def format_label(value: datetime) -> str:
    return value.strftime("%Y-%m-%d %H:%M:%S MSK")


def main() -> int:
    args = parse_args()
    try:
        value = session_time(args.at)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.format == "prefix":
        print(format_prefix(value))
    elif args.format == "label":
        print(format_label(value))
    else:
        print(f"prefix={format_prefix(value)}")
        print(f"label={format_label(value)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
