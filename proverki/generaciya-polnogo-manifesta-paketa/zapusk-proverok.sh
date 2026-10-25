#!/bin/zsh
set -eu
[[ "$1" == /* && -d "$1" && "$(/bin/realpath "$1")" == "$1" ]]
if git -C "$1" rev-parse --git-dir >/dev/null 2>&1; then exit 2; fi
cd "$2"
mkdir -p "$1/modules" "$1/fixtures"
if [[ "${3:-}" == "поставка" ]]; then
  mkdir -p "$1/кандидат" "$1/кэш" "$1/настройки" "$1/доверие"
  xcrun swiftc -O -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
    -enable-actor-data-race-checks -parse-as-library -module-name ГенерацияМанифеста \
    -D ФУМ_КОМАНДА_МАНИФЕСТА -module-cache-path "$1/modules" \
    iskhodniki/generaciya-polnogo-manifesta-paketa/*.swift -o "$1/manifest"
  "$1/manifest" породить --корень "$2" --описание iskhodniki/generaciya-polnogo-manifesta-paketa/modelj-manifesta.json > "$1/кандидат/Package.swift"
  "$1/manifest" diff --корень "$2" --описание iskhodniki/generaciya-polnogo-manifesta-paketa/modelj-manifesta.json > "$1/manifest.diff"
  env "CLANG_MODULE_CACHE_PATH=$1/modules" "SWIFTPM_MODULECACHE_OVERRIDE=$1/modules" \
    xcrun swift package --package-path "$1/кандидат" --scratch-path "$1/scratch" \
      --cache-path "$1/кэш" --config-path "$1/настройки" --security-path "$1/доверие" \
      --disable-sandbox dump-package > "$1/dump.json"
  "$1/manifest" профиль --корень "$2" --описание iskhodniki/generaciya-polnogo-manifesta-paketa/modelj-manifesta.json > "$1/profile.json"
  exit 0
fi
xcrun swiftc --version
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -enable-actor-data-race-checks -parse-as-library -module-name ГенерацияМанифеста \
  -module-cache-path "$1/modules" \
  -F "$(xcode-select -p)/Platforms/MacOSX.platform/Developer/Library/Frameworks" \
  -framework Testing -Xlinker -rpath -Xlinker "$(xcode-select -p)/Platforms/MacOSX.platform/Developer/Library/Frameworks" \
  -plugin-path "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing" \
  iskhodniki/generaciya-polnogo-manifesta-paketa/*.swift \
  proverki/generaciya-polnogo-manifesta-paketa/*.swift -o "$1/runner"
env "ФУМ_КАТАЛОГ_ФИКСТУР=$1/fixtures" "$1/runner" "${@:3}"
