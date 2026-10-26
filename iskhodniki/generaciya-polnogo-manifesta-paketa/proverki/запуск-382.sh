#!/bin/zsh
set -eu
сборка="$1"
корень="$2"
режим="$3"
[[ "$сборка" == /* && -d "$сборка" && "$(/bin/realpath "$сборка")" == "$сборка" ]]
if git -C "$сборка" rev-parse --git-dir >/dev/null 2>&1; then exit 2; fi
cd "$корень"
mkdir -p "$сборка/modules" "$сборка/fixtures"
основа=(iskhodniki/generaciya-polnogo-manifesta-paketa/*.swift)
прежние=proverki/generaciya-polnogo-manifesta-paketa
свои=iskhodniki/generaciya-polnogo-manifesta-paketa/proverki
if [[ "$режим" == "новые" ]]; then
  проверки=("$свои/проверки-имён-целей.swift")
elif [[ "$режим" == "прежние" ]]; then
  проверки=("$прежние/proverki-manifesta.swift" "$прежние/proverki-budusjhikh-iskhodnikov.swift")
elif [[ "$режим" == "фасад" || "$режим" == "профиль" ]]; then
  проверки=()
else
  exit 2
fi
набор="$(xcode-select -p)"
связи=()
имяМодуля=ГенерацияМанифеста
if [[ "$режим" == "фасад" || "$режим" == "профиль" ]]; then
  xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
    -enable-actor-data-race-checks -parse-as-library -module-name ГенерацияМанифеста \
    -module-cache-path "$сборка/modules" -emit-library -emit-module \
    -emit-module-path "$сборка/ГенерацияМанифеста.swiftmodule" \
    "${основа[@]}" -o "$сборка/libГенерацияМанифеста.dylib"
  основа=()
  if [[ "$режим" == "фасад" ]]; then
    проверки=("$свои/проверки-фасада.swift")
    связи=(-lГенерацияМанифеста)
    имяМодуля=ПроверкиФасада382
  else
    xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
      -enable-actor-data-race-checks -parse-as-library -module-cache-path "$сборка/modules" \
      -I "$сборка" -L "$сборка" -lГенерацияМанифеста -Xlinker -rpath -Xlinker "$сборка" \
      "$свои/профиль-382.swift" -o "$сборка/runner"
  fi
fi
if [[ "$режим" != "профиль" ]]; then
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -enable-actor-data-race-checks -parse-as-library -module-name "$имяМодуля" \
  -module-cache-path "$сборка/modules" \
  -F "$набор/Platforms/MacOSX.platform/Developer/Library/Frameworks" \
  -framework Testing -Xlinker -rpath -Xlinker "$набор/Platforms/MacOSX.platform/Developer/Library/Frameworks" \
  -plugin-path "$набор/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing" \
  -I "$сборка" -L "$сборка" -Xlinker -rpath -Xlinker "$сборка" \
  "${связи[@]}" \
  "${основа[@]}" "${проверки[@]}" "$прежние/zapusk-proverok.swift" -o "$сборка/runner"
fi
env "ФУМ_КАТАЛОГ_ФИКСТУР=$сборка/fixtures" \
  "ФУМ_АРТЕФАКТЫ_382=$сборка" \
  "ФУМ_ОПИСАНИЕ_382=$корень/iskhodniki/generaciya-polnogo-manifesta-paketa/dannyiye/382/описание-фикстуры.json" \
  "$сборка/runner" "${@:4}"
