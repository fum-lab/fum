# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-llbuild/4fc005bfb0849f17e6a79ad02ba27f4f539ca6b9/products/llbuild-analyze/Package.swift>

## Содержимое

```text
// swift-tools-version:5.0

// This file defines Swift package manager support for llbuild-analyze. See:
//  https://github.com/swiftlang/swift-package-manager/tree/master/Documentation

import PackageDescription

let package = Package(
    name: "llbuild-analyze",
    platforms: [
        .macOS(.v10_10), .iOS(.v9),
    ],
    products: [
        .executable(
            name: "llbuild-analyze",
            targets: ["llbuildAnalyzeTool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.4.3"),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .branch("main")),
        .package(path: "../../"),
    ],
    targets: [
        .target(
            name: "llbuildAnalyzeTool",
            dependencies: ["SwiftToolsSupport-auto", "llbuildAnalysis", "ArgumentParser"],
            path: "Sources"),
    ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:b2ca435d5bbea0e3075fa0620d20a1b2e85328c92d3313ff051d2e110aafe47e -->
<!-- FUM-MD-RECENCY:END -->
