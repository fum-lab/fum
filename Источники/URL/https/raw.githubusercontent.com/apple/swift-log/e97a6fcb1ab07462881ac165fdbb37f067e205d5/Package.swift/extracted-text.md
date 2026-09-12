# Извлечённый текст

Источник: <https://raw.githubusercontent.com/apple/swift-log/e97a6fcb1ab07462881ac165fdbb37f067e205d5/Package.swift>

## Содержимое

```text
// swift-tools-version:5.6
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "swift-log",
    products: [
        .library(name: "Logging", targets: ["Logging"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Logging",
            dependencies: []
        ),
        .testTarget(
            name: "LoggingTests",
            dependencies: ["Logging"]
        ),
    ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:192398986092102b4af140fae9ffdabb592905834fa5f8fcf7b526daec7f5143 -->
<!-- FUM-MD-RECENCY:END -->
