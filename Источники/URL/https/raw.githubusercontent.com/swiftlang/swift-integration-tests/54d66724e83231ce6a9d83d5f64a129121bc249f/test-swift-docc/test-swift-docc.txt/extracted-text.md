# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-integration-tests/54d66724e83231ce6a9d83d5f64a129121bc249f/test-swift-docc/test-swift-docc.txt>

## Содержимое

```text
// Check that Swift-DocC can compile documentation.
//
// Clear any existing state:
// RUN: rm -rf %t.dir
// RUN: mkdir -p %t.dir
//
// Build symbol graphs for the test package:
// RUN: mkdir %t.dir/symbol-graph-directory
// RUN: mkdir %t.dir/swiftpm-build-directory
// RUN: %{swift} build --target DocCTest --package-path %S/DocCTest --build-path %t.dir/swiftpm-build-directory -Xswiftc -emit-symbol-graph -Xswiftc -emit-symbol-graph-dir -Xswiftc %t.dir/symbol-graph-directory
//
// Convert the documentation
// RUN: %{docc} convert %S/DocCTest/Sources/DocCTest/DocCTest.docc --output-path %t.dir/DocCTest.doccarchive --additional-symbol-graph-dir %t.dir/symbol-graph-directory
//
// Assert that the produced documentation archive has a 'data' subdirectory as expected
// RUN: ls %t.dir/DocCTest.doccarchive/data
// RUN: ls %t.dir/DocCTest.doccarchive/data/documentation/docctest
// RUN: ls %t.dir/DocCTest.doccarchive/data/documentation/docctest/docctest/variable.json
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:3dbf0e651d756b0b24e643552e5ac3ad24c5afb25a17d69298b0e866045aceed -->
<!-- FUM-MD-RECENCY:END -->
