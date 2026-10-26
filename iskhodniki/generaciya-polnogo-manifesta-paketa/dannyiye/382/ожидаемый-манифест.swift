// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ФикстураИмени382",
    platforms: [.macOS("14.0")],
    products: [
    ],
    dependencies: [
    ],
    targets: [
        .testTarget(name: "proverki-aktualizaciya-putej",
            dependencies: [],
            path: "src",
            exclude: [],
            sources: ["a.swift"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
            ]),
    ],
    swiftLanguageModes: [.v6]
)
