# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-syntax/cbd0366a54a9f8fdaa33834652fb2e80f2948573/SwiftSyntaxDevUtils/Package.swift>

## Содержимое

```text
// swift-tools-version:5.7

import Foundation
import PackageDescription

let package = Package(
  name: "swift-syntax-dev-utils",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "swift-syntax-dev-utils", targets: ["swift-syntax-dev-utils"])
  ],
  targets: [
    .executableTarget(
      name: "swift-syntax-dev-utils",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]
    )
  ]
)

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
  // Building standalone.
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2")
  ]
} else {
  package.dependencies += [
    .package(path: "../../swift-argument-parser")
  ]
}
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:54bc945e25a04ec9a2b6251803d98b2f6fe128cb3e9e2d1e50a644bdec90ca31 -->
<!-- FUM-MD-RECENCY:END -->
