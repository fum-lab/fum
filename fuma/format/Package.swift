// swift-tools-version: 6.0
import PackageDescription

let настройки: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "FUMAPathFormatter",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "fuma-format", targets: ["FUMAPathFormatter"])],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "FUMAPathFormatter",
            dependencies: [.product(name: "АктуализацияПутей", package: "fum")],
            path: ".",
            exclude: ["Package.swift", "run.sh", "Tests"],
            sources: ["main.swift"],
            swiftSettings: настройки
        ),
        .testTarget(
            name: "FUMAPathFormatterTests",
            dependencies: [.product(name: "АктуализацияПутей", package: "fum")],
            path: "Tests/ФорматированиеПутейFUMATests",
            swiftSettings: настройки
        )
    ]
)
