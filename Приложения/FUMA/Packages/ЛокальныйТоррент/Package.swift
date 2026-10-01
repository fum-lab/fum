// swift-tools-version: 6.0

import PackageDescription

let пакет = Package(
    name: "ЛокальныйТоррент",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ЛокальныйТоррент", targets: ["ЛокальныйТоррент"])
    ],
    dependencies: [.package(name: "Мост", path: "Мост")],
    targets: [
        .target(name: "ЛокальныйТоррент", dependencies: [.product(name: "МостЛибторрента", package: "Мост")]),
        .testTarget(name: "Тесты", dependencies: ["ЛокальныйТоррент", .product(name: "ПробыМоста", package: "Мост")], path: "Tests/ЛокальныйТоррентТесты")
    ]
)
