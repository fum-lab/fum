# Извлечённый текст

Источник: <https://raw.githubusercontent.com/apple/swift-system/f9266c85189c2751589a50ea5aec72799797e471/Package.swift>

## Содержимое

```text
// swift-tools-version:5.8

/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020-2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import PackageDescription

let DarwinPlatforms: [Platform]
#if swift(<5.9)
DarwinPlatforms = [.macOS, .iOS, .watchOS, .tvOS]
#else
DarwinPlatforms = [.macOS, .iOS, .watchOS, .tvOS, .visionOS]
#endif

let package = Package(
    name: "swift-system",
    products: [
        .library(name: "SystemPackage", targets: ["SystemPackage"]),
    ],
    dependencies: [],
    targets: [
      .target(
        name: "CSystem",
        dependencies: []),
      .target(
        name: "SystemPackage",
        dependencies: ["CSystem"],
        path: "Sources/System",
        cSettings: [
          .define("_CRT_SECURE_NO_WARNINGS")
        ],
        swiftSettings: [
          .define("SYSTEM_PACKAGE"),
          .define("SYSTEM_PACKAGE_DARWIN", .when(platforms: DarwinPlatforms)),
          .define("ENABLE_MOCKING", .when(configuration: .debug))
        ]),
      .testTarget(
        name: "SystemTests",
        dependencies: ["SystemPackage"],
        swiftSettings: [
          .define("SYSTEM_PACKAGE"),
          .define("SYSTEM_PACKAGE_DARWIN", .when(platforms: DarwinPlatforms)),
        ]),
    ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:20576c3814c6062c3640e2d9f713fc91918635a78ad4babc269fc043b3c1b69c -->
<!-- FUM-MD-RECENCY:END -->
