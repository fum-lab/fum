# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-package-manager/45c31f1b35ef8599898f61c26e7518bcf14b3eb5/IntegrationTests/Package.swift>

## Содержимое

```text
// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "IntegrationTests",
    targets: [
        .testTarget(name: "IntegrationTests", dependencies: [
            .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            .product(name: "TSCTestSupport", package: "swift-tools-support-core")
        ]),
    ]
)

import class Foundation.ProcessInfo

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .branch("main")),
    ]
} else {
    package.dependencies += [
        .package(name: "swift-tools-support-core", path: "../TSC"),
    ]
}
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:867be47b437648c1ecdd1dde02910f984868e1fb7df5621d7b92b612040e9cb4 -->
<!-- FUM-MD-RECENCY:END -->
