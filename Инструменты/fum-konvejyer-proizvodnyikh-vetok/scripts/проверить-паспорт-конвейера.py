#!/usr/bin/env python3
"""CLI-обёртка над паспортом конвейера."""

from __future__ import annotations

from pathlib import Path
import runpy


ПУТЬ_МОДУЛЯ = Path(__file__).with_name("паспорт_конвейера.py")


if __name__ == "__main__":
    runpy.run_path(str(ПУТЬ_МОДУЛЯ), run_name="__main__")
