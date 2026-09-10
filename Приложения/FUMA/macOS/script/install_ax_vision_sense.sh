#!/usr/bin/env bash
printf "%s\n" "Неприменённый шаблон: установка и системные разрешения требуют отдельной проверенной подготовки." >&2
exit 2
set -euo pipefail

LABEL="fum.sense.ax-vision"
PRODUCT_NAME="fum-ax-vision-sense"
APP_NAME="FUMAXVisionSense"
BUNDLE_ID="fum.sense.ax-vision"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_ROOT="${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}/dist"
APP_BUNDLE="$DIST_ROOT/$APP_NAME.app"
APP_MACOS="$APP_BUNDLE/Contents/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
RUN_DIR="${FUM_RUNTIME_ROOT:?Задайте внешний runtime-каталог}/senses/ax-vision"
PLIST_TARGET="${FUM_LAUNCH_AGENTS_DIR:?Задайте каталог LaunchAgents}/$LABEL.plist"
DOMAIN="gui/$(id -u)"

cd "$ROOT_DIR"
mkdir -p "$APP_MACOS" "$RUN_DIR" "${FUM_LAUNCH_AGENTS_DIR:?Задайте каталог LaunchAgents}"
swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" -c release --product "$PRODUCT_NAME"
cp "$(swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" -c release --show-bin-path)/$PRODUCT_NAME" "$APP_BINARY"
chmod 755 "$APP_BINARY"

plutil -create xml1 "$INFO_PLIST"
plutil -insert CFBundleExecutable -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
plutil -insert CFBundleName -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundleDisplayName -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundlePackageType -string "APPL" "$INFO_PLIST"
plutil -insert NSPrincipalClass -string "NSApplication" "$INFO_PLIST"
plutil -insert LSUIElement -bool true "$INFO_PLIST"

if launchctl print "$DOMAIN/$LABEL" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1; then
  launchctl bootout "$DOMAIN/$LABEL" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true
fi
cp "$ROOT_DIR/launchd/$LABEL.plist" "$PLIST_TARGET"
chmod 644 "$PLIST_TARGET"
launchctl bootstrap "$DOMAIN" "$PLIST_TARGET"
launchctl enable "$DOMAIN/$LABEL"
launchctl kickstart -k "$DOMAIN/$LABEL"
echo "Installed and started $LABEL"
