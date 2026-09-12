# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-corelibs-xctest/7f2b2e286c984fb2f25aa36187f963bbdabf1b13/Package.swift>

## Содержимое

```text
// swift-tools-version:4.0
//
// To build with auto-linking of the .swiftmodule use:
// $ swift build -Xswiftc -module-link-name -Xswiftc XCTest
//

import PackageDescription

let package = Package(
    name: "XCTest",
    products: [
        .library(
            name: "XCTest",
            type: .dynamic,
            targets: ["XCTest"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "XCTest", dependencies: [], path: "Sources"),
    ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:e410d9014e0ba23ef8cfd291545a6eeda5b6cf41c620fd8d9d2b5e8fc55f8b3a -->
<!-- FUM-MD-RECENCY:END -->
