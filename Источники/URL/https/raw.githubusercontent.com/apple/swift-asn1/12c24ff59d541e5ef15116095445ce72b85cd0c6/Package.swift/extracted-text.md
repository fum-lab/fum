# Извлечённый текст

Источник: <https://raw.githubusercontent.com/apple/swift-asn1/12c24ff59d541e5ef15116095445ce72b85cd0c6/Package.swift>

## Содержимое

```text
// swift-tools-version:5.7
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2023 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
    name: "swift-asn1",
    products: [
        .library(name: "SwiftASN1", targets: ["SwiftASN1"]),
    ],
    targets: [
        .target(
            name: "SwiftASN1",
            exclude: ["CMakeLists.txt"]
        ),
        .testTarget(name: "SwiftASN1Tests", dependencies: ["SwiftASN1"]),
    ]
)

// If the `SWIFTCI_USE_LOCAL_DEPS` environment variable is set,
// we're building in the Swift.org CI system alongside other projects in the Swift toolchain and
// we can depend on local versions of our dependencies instead of fetching them remotely.
if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ]
}
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:fe6c00ebe55f8f1467a72760bb8f0a287c8e20ab855c1813288e49b38805319a -->
<!-- FUM-MD-RECENCY:END -->
