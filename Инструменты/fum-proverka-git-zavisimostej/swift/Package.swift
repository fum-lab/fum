// swift-tools-version: 6.0
import PackageDescription

let настройки: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags([
        "-strict-concurrency=complete",
        "-warnings-as-errors",
        "-enable-actor-data-race-checks",
    ]),
]

let package = Package(
    name: "FUMBootstrapGitDependencies",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "bootstrap-zavisimosti", targets: ["КомандаBootstrapЗависимости"]),
    ],
    targets: [
        .target(
            name: "BootstrapЗависимости",
            path: ".",
            exclude: [
                "komanda-bootstrap-zavisimosti.swift",
                "proverki-bootstrap-zavisimosti.swift",
            ],
            sources: [
                "bootstrap-zavisimosti.swift",
                "bezopasnaya-granica-bootstrap.swift",
            ],
            swiftSettings: настройки),
        .executableTarget(
            name: "КомандаBootstrapЗависимости",
            dependencies: ["BootstrapЗависимости"],
            path: ".",
            exclude: [
                "bootstrap-zavisimosti.swift",
                "bezopasnaya-granica-bootstrap.swift",
                "proverki-bootstrap-zavisimosti.swift",
            ],
            sources: ["komanda-bootstrap-zavisimosti.swift"],
            swiftSettings: настройки),
        .testTarget(
            name: "proverki-bootstrap-zavisimosti",
            dependencies: ["BootstrapЗависимости"],
            path: ".",
            exclude: [
                "bootstrap-zavisimosti.swift",
                "bezopasnaya-granica-bootstrap.swift",
                "komanda-bootstrap-zavisimosti.swift",
            ],
            sources: ["proverki-bootstrap-zavisimosti.swift"],
            swiftSettings: настройки),
    ],
    swiftLanguageModes: [.v6])
