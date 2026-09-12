# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-lmdb/c42582487fe84f72a4d417dd2d8493757bd4d072/Package.swift>

## Содержимое

```text
// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CLMDB",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CLMDB",
            targets: ["CLMDB"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CLMDB",
            dependencies: []),
    ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:e3c853085bb6101c9e1cde52c851214922b6e3245f9ce411d539a2b9fd775b8e -->
<!-- FUM-MD-RECENCY:END -->
