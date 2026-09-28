#!/usr/bin/env python3
"""CLI entry point for the request-folder layout automation."""

import hashlib
from pathlib import Path

КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()

from request_folder_layout import main


if __name__ == "__main__":
    raise SystemExit(main())
