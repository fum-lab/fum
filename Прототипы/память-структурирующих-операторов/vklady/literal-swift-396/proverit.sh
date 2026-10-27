#!/usr/bin/env bash
set -euo pipefail
umask 077
bundle=$(cd "$(dirname "$0")" && pwd -P)
if [ "$#" -eq 1 ] && [ "$1" = --check-package ]; then
  mode=--check-package
elif [ "$#" -eq 3 ]; then
  mode=$1
else
  echo 'Использование: bash proverit.sh --repo КЛОН НОВЫЙ_КАТАЛОГ' >&2
  echo '          или: bash proverit.sh --snapshot СНИМОК НОВЫЙ_КАТАЛОГ' >&2
  echo '          или: bash proverit.sh --check-package' >&2
  exit 2
fi
case "$mode" in --repo|--snapshot|--check-package) ;; *) echo 'Неизвестный режим' >&2; exit 2 ;; esac
for command in swift swiftc git shasum awk sed cmp mktemp; do
  command -v "$command" >/dev/null || { echo "Не найден инструмент: $command" >&2; exit 2; }
done
# Проверяющий исходник также входит в манифест. Это сверка целостности,
# а не аутентификация автора: доверенный commit пакета выбирается отдельно.
checker_dir=$(mktemp -d "${TMPDIR:-/tmp}/fuma-426.XXXXXXXX")
trap 'rm -rf -- "$checker_dir"' EXIT
swiftc -parse-as-library -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  "$bundle/proverka-postavki.swift" -o "$checker_dir/checker"
"$checker_dir/checker" манифест "$bundle"
"$checker_dir/checker" самопроверка
if [ "$mode" = --check-package ]; then exit 0; fi
origin=$(cd "$2" && pwd -P)
# Выход не должен находиться внутри читаемых входов.
parent=$(cd "$(dirname "$3")" && pwd -P)
case "$parent/$(basename "$3")" in
  "$origin"|"$origin"/*|"$bundle"|"$bundle"/*)
    echo 'Выходной каталог пересекается с входом' >&2; exit 2 ;;
esac
# Каталог должен быть новым: существующие файлы никогда не перезаписываются.
mkdir -m 700 "$3"
out=$(cd "$3" && pwd -P)
base=01186131ab4fa0622279ddcabedf90525267f130
join=e41906c6e71f6b1418f226cd838f8c111220a976
path='Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory'
src="$out/validation/Sources/FUMStructuringOperatorMemory"
tests="$out/validation/Tests/LiteralTests"
mkdir -p "$src" "$tests" "$out/combined" "$out/logs"

pin() {
  local scope=$1 rev=$2 name=$3 expected=$4 target=$5
  if [ "$mode" = --repo ]; then
    git -C "$origin" show "$rev:$path/$name" > "$target"
  else
    cat "$origin/$scope/$name" > "$target"
  fi
  local actual
  actual=$(git hash-object --no-filters "$target")
  [ "$actual" = "$expected" ] || { echo "Ошибка Git blob: $name" >&2; exit 1; }
}
pin base "$base" ГрафJSON.swift 7a61e921b78ade581049f447ff488f84a553b14c "$src/ГрафJSON.swift"
pin base "$base" ВычислениеГрафаJSON.swift 1c1124f670ca2654b7d35f29eb2ed982fe5f6a41 "$src/ВычислениеГрафаJSON.swift"
pin base "$base" ЗакрытыйРазбор.swift b9f4f248698254d1f28cc8d888a6abeb74f39440 "$src/ЗакрытыйРазбор.swift"
if [ "$mode" = --repo ]; then
  pin base "$base" ИсполнениеОператоров.swift 151e10136e3f8207c9d91a20bb8aa1d5212c1d2e "$out/error-full.tmp"
  { printf 'import Foundation\n\n'; sed -n '3,18p' "$out/error-full.tmp"; } > "$src/error-extracted.swift"
else
  cat "$origin/error-extracted.swift" > "$src/error-extracted.swift"
fi
actual=$(shasum -a 256 "$src/error-extracted.swift" | awk '{print $1}')
[ "$actual" = 2031f4a1154ef2e0254f341c823f2e570a527f30f4435732eef33ff9dcd07c63 ] || exit 1
cat > "$out/validation/Package.swift" <<'PACKAGE'
// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "FUMAExternalValidation", targets: [
  .target(name: "FUMStructuringOperatorMemory"),
  .testTarget(name: "LiteralTests", dependencies: ["FUMStructuringOperatorMemory"])
], swiftLanguageModes: [.v6])
PACKAGE
swift --version > "$out/logs/toolchain.log"
cp "$bundle/proverka-red.swift" "$tests/proverki.swift"
set +e
(cd "$out/validation" && swift test --jobs 2 --scratch-path "$out/scratch-red" --disable-xctest --enable-swift-testing -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors) > "$out/logs/red.log" 2>&1
red=$?
set -e
if [ "$red" -ne 1 ] || ! grep -q 'Неизвестная операция или неверная арность' "$out/logs/red.log"; then
  echo 'Не подтверждён ожидаемый исход RED' >&2
  exit 1
fi
echo PASS_BASELINE_RED=1
(cd "$src" && git apply --check -p5 "$bundle/podklyuchenie.patch" && git apply -p5 "$bundle/podklyuchenie.patch")
cp "$bundle/literal-swift.swift" "$src/literal-swift.swift"
cp "$bundle/proverki-literala-swift.swift" "$tests/proverki.swift"
(cd "$out/validation" && swift test --jobs 2 --scratch-path "$out/scratch-green" --disable-xctest --enable-swift-testing \
  --event-stream-version 0 --event-stream-output-path "$out/logs/tests.events.jsonl" \
  -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors) > "$out/logs/green.log" 2>&1
"$checker_dir/checker" события "$out/logs/tests.events.jsonl" \
  "$bundle/ozhidaemye-proverki.json" "$out/logs/tests.result.json"
swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors -O "$src"/*.swift "$bundle/proverka-skalyarov.swift" -o "$out/scalars" > "$out/logs/build-scalars.log" 2>&1
"$out/scalars" | tee "$out/logs/scalars.log"
grep -Fxq 'PASS scalar_encoding_and_budgets=1112064' "$out/logs/scalars.log"

# Только для сквозного опыта: отдельная копия непринятого JOIN из PR 398.
c="$out/combined"
pin join "$join" ГрафJSON.swift 6f0659de06334b41cd8cbe08d8b15c3c8f1baa88 "$c/ГрафJSON.swift"
pin join "$join" ВычислениеГрафаJSON.swift d3c294dd1bef8b8b1d149e528e880d6d52df0ac5 "$c/ВычислениеГрафаJSON.swift"
pin join "$join" РазмерСоединенияСтрок.swift 1789fa20fb8ad7c7cc3231c545549c0425acb21b "$c/РазмерСоединенияСтрок.swift"
cp "$src/ЗакрытыйРазбор.swift" "$src/error-extracted.swift" "$src/literal-swift.swift" "$c/"
(cd "$c" && git apply --check -p5 "$bundle/podklyuchenie-na-398.patch" && git apply -p5 "$bundle/podklyuchenie-na-398.patch")
swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors -parse-as-library "$bundle/sozdat-korpus.swift" -o "$out/corpus" > "$out/logs/build-corpus.log" 2>&1
"$out/corpus" > "$out/corpus.json"
swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors -O "$c"/*.swift "$bundle/proverka-skvozhnogo-prohoda.swift" -o "$out/emitter" > "$out/logs/build-emitter.log" 2>&1
"$out/emitter" "$bundle/programma-fuma.json" "$out/corpus.json" "$out/generated.swift" "$out/expected.bin" | tee "$out/logs/emitter.log"
swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors "$out/generated.swift" -o "$out/generated" > "$out/logs/build-generated.log" 2>&1
"$out/generated" > "$out/actual.bin"
cmp "$out/expected.bin" "$out/actual.bin"
shasum -a 256 "$out/expected.bin" "$out/actual.bin" > "$out/logs/output-hashes.log"
actual=$(shasum -a 256 "$out/actual.bin" | awk '{print $1}')
[ "$actual" = 0b59e66ccfdfd7076ed28b71de822b2b37214e37dbf9f6f3374a8e7f4240dc12 ] || {
  echo 'Сквозной результат не совпал с закреплённым эталоном' >&2; exit 1;
}
echo PASS_SEPARATE_COMPILE_AND_BYTES=1
printf 'Результаты: %s\n' "$out"
