# Извлечённый текст

Источник: <https://raw.githubusercontent.com/apple/swift-numerics/0a5bc04095a675662cf24757cc0640aa2204253b/Package.swift>

## Содержимое

```text
// swift-tools-version:5.0
//===--- Package.swift ----------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Numerics open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift Numerics project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(

  name: "swift-numerics",
  products: [
    .library(name: "ComplexModule", targets: ["ComplexModule"]),
    .library(name: "Numerics", targets: ["Numerics"]),
    .library(name: "RealModule", targets: ["RealModule"]),
  ],

  targets: [
    // User-facing modules
    .target(name: "ComplexModule", dependencies: ["RealModule"]),
    .target(name: "Numerics", dependencies: ["ComplexModule", "RealModule"]),
    .target(name: "RealModule", dependencies: ["_NumericsShims"]),

    // Implementation details
    .target(name: "_NumericsShims", dependencies: []),
    .target(name: "_TestSupport", dependencies: ["Numerics"]),

    // Unit test bundles
    .testTarget(name: "ComplexTests", dependencies: ["_TestSupport"]),
    .testTarget(name: "RealTests", dependencies: ["_TestSupport"]),

    // Test executables
    .target(name: "ComplexLog", dependencies: ["Numerics", "_TestSupport"], path: "Tests/Executable/ComplexLog"),
    .target(name: "ComplexLog1p", dependencies: ["Numerics", "_TestSupport"], path: "Tests/Executable/ComplexLog1p")
  ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:f01d72a26a8f241d85786075a517a4aa50ab04ef57907aa93c0a99404381fe4d -->
<!-- FUM-MD-RECENCY:END -->
