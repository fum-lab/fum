#!/usr/bin/env bash
printf "%s\n" "Неприменённый шаблон: установка и системные разрешения требуют отдельной проверенной подготовки." >&2
exit 2
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="fum.attention-loop"
PLIST_SOURCE="$ROOT/launchd/$LABEL.plist"
PLIST_TARGET="${FUM_LAUNCH_AGENTS_DIR:?Задайте каталог LaunchAgents}/$LABEL.plist"
DIST="${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}/dist"
RUN_DIR="${FUM_RUNTIME_ROOT:?Задайте внешний runtime-каталог}/realtime/attention"

mkdir -p "$DIST" "$RUN_DIR"

cd "$ROOT"
swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" -c release --product fum-attention-loop
cp "$FUM_BUILD_ROOT/release/fum-attention-loop" "$DIST/fum-attention-loop"

mkdir -p "${FUM_LAUNCH_AGENTS_DIR:?Задайте каталог LaunchAgents}"
cp "$PLIST_SOURCE" "$PLIST_TARGET"

launchctl bootout "gui/$(id -u)" "$PLIST_TARGET" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_TARGET"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "Installed and started $LABEL"
echo "Status: $RUN_DIR/latest.json"
echo "Events: ${FUM_MEMORY_ROOT:?Задайте внешний каталог памяти}/realtime/attention-loop/events.jsonl"
