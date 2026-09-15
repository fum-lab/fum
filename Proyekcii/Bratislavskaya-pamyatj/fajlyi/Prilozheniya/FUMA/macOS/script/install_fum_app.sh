#!/usr/bin/env bash
printf "%s\n" "Неприменённый шаблон: установка и системные разрешения требуют отдельной проверенной подготовки." >&2
exit 2
set -euo pipefail

LABEL="fum.app"
PRODUCT_NAME="fum"
MCP_PRODUCT_NAME="fum-mcp"
APP_NAME="FUM"
BUNDLE_ID="fum.app"
MIN_SYSTEM_VERSION="14.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_ROOT="${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}/dist"
STAGING_APP_BUNDLE="$DIST_ROOT/$APP_NAME.app"
APPLICATIONS_DIR="${FUM_APPLICATIONS_DIR:?Задайте каталог установки}"
APP_BUNDLE="$APPLICATIONS_DIR/$APP_NAME.app"
STAGING_APP_CONTENTS="$STAGING_APP_BUNDLE/Contents"
STAGING_APP_MACOS="$STAGING_APP_CONTENTS/MacOS"
STAGING_APP_HELPERS="$STAGING_APP_CONTENTS/Helpers"
STAGING_APP_BINARY="$STAGING_APP_MACOS/$APP_NAME"
STAGING_MCP_BINARY="$STAGING_APP_HELPERS/$MCP_PRODUCT_NAME"
INFO_PLIST="$STAGING_APP_CONTENTS/Info.plist"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
RUN_DIR="${FUM_RUNTIME_ROOT:?Задайте внешний runtime-каталог}"
PLIST_SOURCE="$ROOT_DIR/launchd/$LABEL.plist"
PLIST_TARGET="${FUM_LAUNCH_AGENTS_DIR:?Задайте каталог LaunchAgents}/$LABEL.plist"
DOMAIN="gui/$(id -u)"
SKIP_PERMISSIONS=0
SIGN_IDENTITY="${FUM_CODESIGN_IDENTITY:-FUM Local Code Signing}"

for argument in "$@"; do
  case "$argument" in
    --skip-permissions)
      SKIP_PERMISSIONS=1
      ;;
    --help|-h)
      cat <<'EOF'
Usage: script/install_fum_app.sh [--skip-permissions]

Builds and signs FUM.app with its fum-mcp helper, installs it into
FUM_APPLICATIONS_DIR, starts it, then runs the mandatory permission onboarding stage
unless --skip-permissions is passed.

Environment:
  FUM_APPLICATIONS_DIR    Override the application install directory.
  FUM_CODESIGN_IDENTITY   Override the local code signing identity.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $argument" >&2
      exit 2
      ;;
  esac
done

run_permission_onboarding() {
  local status_file="$RUN_DIR/permission-status.json"
  echo
  echo "FUM permission onboarding"
  echo "App bundle: $APP_BUNDLE"
  echo
  echo "The next step runs FUM.app itself with --request-permissions."
  echo "macOS may require Touch ID, password, or manual toggles in System Settings."
  echo

  request_permission_status "$status_file" --request-permissions

  while true; do
    echo
    echo "Current FUM.app permission status:"
    request_permission_status "$status_file" --permission-status
    cat "$status_file"
    echo
    read -r -p "Grant missing permissions in System Settings, then press Enter to recheck (or type skip): " answer
    if [[ "$answer" == "skip" ]]; then
      echo "Permission onboarding skipped by user."
      break
    fi

    request_permission_status "$status_file" --permission-status
    status_json="$(cat "$status_file")"
    echo "$status_json"
    if python3 - "$status_json" <<'PY'
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    sys.exit(1)

ok = (
    payload.get("accessibility") is True
    and payload.get("inputMonitoring") is True
    and payload.get("documents") is True
)
sys.exit(0 if ok else 1)
PY
    then
      echo "FUM.app permissions are ready."
      break
    fi
  done
}

request_permission_status() {
  local status_file="$1"
  local mode="$2"
  rm -f "$status_file"
  open -na "$APP_BUNDLE" --args "$mode" --permission-status-output "$status_file"

  local attempt
  for attempt in {1..60}; do
    if [[ -s "$status_file" ]]; then
      return
    fi
    sleep 0.5
  done

  echo "FUM.app did not write permission status for $mode." >&2
  exit 1
}

ensure_local_signing_identity() {
  if security find-identity -v -p codesigning | grep -Fq "\"$SIGN_IDENTITY\""; then
    return
  fi

  if [[ "$SIGN_IDENTITY" != "FUM Local Code Signing" ]]; then
    echo "Code signing identity not found: $SIGN_IDENTITY" >&2
    exit 1
  fi

  echo "Creating local code signing identity: $SIGN_IDENTITY"
  local temp_dir
  temp_dir="$(mktemp -d)"
  local key_path="$temp_dir/fum-local-code-signing.key"
  local cert_path="$temp_dir/fum-local-code-signing.crt"
  local p12_path="$temp_dir/fum-local-code-signing.p12"
  local p12_password="fum-local-code-signing"

  openssl req \
    -newkey rsa:2048 \
    -nodes \
    -keyout "$key_path" \
    -x509 \
    -days 3650 \
    -out "$cert_path" \
    -subj "${FUM_CERT_SUBJECT:?Задайте субъект сертификата}" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1

  openssl pkcs12 \
    -export \
    -legacy \
    -inkey "$key_path" \
    -in "$cert_path" \
    -name "$SIGN_IDENTITY" \
    -out "$p12_path" \
    -passout "pass:$p12_password" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1

  security import "$p12_path" \
    -k "${FUM_KEYCHAIN_PATH:?Задайте путь Keychain}" \
    -P "$p12_password" \
    -T "$(command -v codesign)" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}"

  security add-trusted-cert \
    -d \
    -r trustRoot \
    -p codeSign \
    -k "${FUM_KEYCHAIN_PATH:?Задайте путь Keychain}" \
    "$cert_path" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true

  rm -rf "$temp_dir"

  if ! security find-identity -v -p codesigning | grep -Fq "\"$SIGN_IDENTITY\""; then
    echo "Failed to create code signing identity: $SIGN_IDENTITY" >&2
    exit 1
  fi
}

replace_installed_app() {
  local source_bundle="$1"
  local target_bundle="$2"
  local target_dir
  target_dir="$(dirname "$target_bundle")"

  mkdir -p "$target_dir" 2>"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" || true

  if [[ -w "$target_dir" ]]; then
    rm -rf "$target_bundle"
    ditto "$source_bundle" "$target_bundle"
    return
  fi

  echo "Installing $APP_NAME.app into $target_dir requires administrator access."
  sudo rm -rf "$target_bundle"
  sudo ditto "$source_bundle" "$target_bundle"
  sudo chown -R root:wheel "$target_bundle"
}

bootstrap_agent() {
  launchctl bootout "$DOMAIN/$LABEL" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true
  launchctl bootout "$DOMAIN" "$PLIST_TARGET" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true

  if launchctl bootstrap "$DOMAIN" "$PLIST_TARGET"; then
    return
  fi

  echo "Retrying launchd bootstrap after a short settle interval."
  sleep 1
  launchctl bootout "$DOMAIN/$LABEL" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true
  launchctl bootout "$DOMAIN" "$PLIST_TARGET" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true
  launchctl bootstrap "$DOMAIN" "$PLIST_TARGET"
}

cd "$ROOT_DIR"

mkdir -p "$STAGING_APP_MACOS" "$STAGING_APP_HELPERS" "$RUN_DIR" "${FUM_LAUNCH_AGENTS_DIR:?Задайте каталог LaunchAgents}"
ensure_local_signing_identity

if pgrep -x "$APP_NAME" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1; then
  pkill -TERM -x "$APP_NAME" >"${FUM_NULL_DEVICE:?Задайте системный приёмник пустого вывода}" 2>&1 || true
fi

swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" -c release --product "$PRODUCT_NAME"
swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" -c release --product "$MCP_PRODUCT_NAME"
BUILD_BINARY="$(swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" -c release --show-bin-path)/$PRODUCT_NAME"
BUILD_MCP_BINARY="$(swift build --scratch-path "${FUM_BUILD_ROOT:?Задайте внешний каталог сборки}" -c release --show-bin-path)/$MCP_PRODUCT_NAME"

rm -rf "$STAGING_APP_BUNDLE"
mkdir -p "$STAGING_APP_MACOS" "$STAGING_APP_HELPERS"
cp "$BUILD_BINARY" "$STAGING_APP_BINARY"
cp "$BUILD_MCP_BINARY" "$STAGING_MCP_BINARY"
chmod 755 "$STAGING_APP_BINARY"
chmod 755 "$STAGING_MCP_BINARY"

plutil -create xml1 "$INFO_PLIST"
plutil -insert CFBundleExecutable -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
plutil -insert CFBundleName -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundleDisplayName -string "FUM" "$INFO_PLIST"
plutil -insert CFBundleVersion -string "1" "$INFO_PLIST"
plutil -insert CFBundleShortVersionString -string "0.1" "$INFO_PLIST"
plutil -insert CFBundlePackageType -string "APPL" "$INFO_PLIST"
plutil -insert LSMinimumSystemVersion -string "$MIN_SYSTEM_VERSION" "$INFO_PLIST"
plutil -insert NSPrincipalClass -string "NSApplication" "$INFO_PLIST"
plutil -insert NSDocumentsFolderUsageDescription -string "FUM reads Documents as local memory and project knowledge." "$INFO_PLIST"

codesign --force --deep --sign "$SIGN_IDENTITY" "$STAGING_APP_BUNDLE"
replace_installed_app "$STAGING_APP_BUNDLE" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

cp "$PLIST_SOURCE" "$PLIST_TARGET"
"${FUM_PLIST_BUDDY:?Задайте исполняемый файл PlistBuddy}" \
  -c "Delete :ProgramArguments" \
  -c "Add :ProgramArguments array" \
  -c "Add :ProgramArguments:0 string $APP_BINARY" \
  "$PLIST_TARGET"
chmod 644 "$PLIST_TARGET"

bootstrap_agent
launchctl enable "$DOMAIN/$LABEL"
launchctl kickstart -k "$DOMAIN/$LABEL"

if [[ "$SKIP_PERMISSIONS" != "1" ]]; then
  run_permission_onboarding
  launchctl kickstart -k "$DOMAIN/$LABEL"
fi

echo "Installed and started $LABEL"
echo "App: $APP_BUNDLE"
echo "Logs: $RUN_DIR"
