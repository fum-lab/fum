#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED_HELPER="${FUM_MCP_APP_HELPER:-}"
if [[ -x "$INSTALLED_HELPER" ]]; then
  exec "$INSTALLED_HELPER"
fi

BUILD_ROOT="${FUM_BUILD_ROOT:?Задайте абсолютный каталог сборки вне Git}"
PROJECT_HELPER="$BUILD_ROOT/release/fum-mcp"
swift build --package-path "$ROOT_DIR" --scratch-path "$BUILD_ROOT" -c release --product fum-mcp >&2

exec "$PROJECT_HELPER"
