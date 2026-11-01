// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "МинимальныйИнтерфейс",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ЦиклОператора", targets: ["ЦиклОператора"]),
        .executable(name: "интерфейс-фума", targets: ["ПриложениеИнтерфейса"])
    ],
    dependencies: [
        .package(
            name: "FUMStructuringOperatorMemory",
            path: "../../../../Прототипы/память-структурирующих-операторов"
        )
    ],
    targets: [
        .target(
            name: "ЦиклОператора",
            dependencies: [
                .product(name: "FUMStructuringOperatorMemory", package: "FUMStructuringOperatorMemory")
            ],
            path: "Sources/FUMACycleModel",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .unsafeFlags(["-strict-concurrency=complete", "-enable-actor-data-race-checks", "-warnings-as-errors"])
            ]
        ),
        .executableTarget(
            name: "ПриложениеИнтерфейса",
            dependencies: ["ЦиклОператора"],
            path: "Sources/FUMACycleUI",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .unsafeFlags(["-strict-concurrency=complete", "-enable-actor-data-race-checks", "-warnings-as-errors"])
            ]
        ),
        .testTarget(
            name: "ПроверкиЦиклаОператора",
            dependencies: ["ЦиклОператора"],
            path: "Tests/FUMACycleModelTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .unsafeFlags(["-strict-concurrency=complete", "-enable-actor-data-race-checks", "-warnings-as-errors"])
            ]
        )
    ]
)
