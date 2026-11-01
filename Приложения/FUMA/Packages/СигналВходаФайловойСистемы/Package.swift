// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "СигналВходаФайловойСистемы",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "СигналВходаФайловойСистемы", targets: ["СигналВходаФайловойСистемы"])
    ],
    dependencies: [
        .package(path: "../КонтейнерНаблюдений")
    ],
    targets: [
        .target(
            name: "СигналВходаФайловойСистемы",
            dependencies: [
                .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
            ]),
        .testTarget(
            name: "СигналВходаФайловойСистемыTests",
            dependencies: [
                "СигналВходаФайловойСистемы",
                .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
            ],
            path: "Tests/СигналВходаФайловойСистемыTests")
    ],
    swiftLanguageModes: [.v6])
