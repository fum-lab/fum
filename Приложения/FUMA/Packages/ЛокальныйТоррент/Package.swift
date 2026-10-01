// swift-tools-version: 6.0

import PackageDescription

let пакет = Package(
    name: "ЛокальныйТоррент",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ЛокальныйТоррент", targets: ["ЛокальныйТоррент"])
    ],
    targets: [
        .target(name: "ЛокальныйТоррент"),
        .testTarget(name: "Тесты", dependencies: ["ЛокальныйТоррент"], path: "Tests/ЛокальныйТоррентТесты")
    ]
)
