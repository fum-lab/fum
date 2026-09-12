# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-docc-symbolkit/b7412ac35f1da94254d6b9c889b25e67f2c6b2f3/Package.swift>

## Содержимое

```text
// swift-tools-version:5.5
/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageDescription

let package = Package(
    name: "SymbolKit",
    products: [
        .library(
            name: "SymbolKit",
            targets: ["SymbolKit"]),
    ],
    targets: [
        .target(
            name: "SymbolKit",
            dependencies: []),
        .testTarget(
            name: "SymbolKitTests",
            dependencies: ["SymbolKit"]),
    ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:34b93d9c00472f6045b2229a8340e0ed6ba030379f3d355205037694dd549cb6 -->
<!-- FUM-MD-RECENCY:END -->
