// swift-tools-version: 6.0
import PackageDescription

let строгиеНастройки: [SwiftSetting] = [
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "КомпозицияНаблюдений",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "КомпозицияНаблюдений", targets: ["КомпозицияНаблюдений"])
    ],
    dependencies: [
        .package(path: "../КонтейнерНаблюдений"),
        .package(path: "../Git"),
        .package(path: "../АрхивныйСнимокЗадачи")
    ],
    targets: [
        .target(
            name: "КомпозицияНаблюдений",
            dependencies: [
                .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений"),
                .product(name: "НаблюдательРепозитория", package: "Git"),
                .product(name: "АрхивныйСнимокЗадачи", package: "АрхивныйСнимокЗадачи")
            ],
            swiftSettings: строгиеНастройки),
        .testTarget(
            name: "FUMAObservationCompositionTests",
            dependencies: ["КомпозицияНаблюдений"],
            path: "Tests/КомпозицияНаблюденийTests",
            swiftSettings: строгиеНастройки)
    ],
    swiftLanguageModes: [.v6])
