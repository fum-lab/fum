// swift-tools-version: 6.0
import PackageDescription

let strict: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "СетьАгентов",
    platforms: [.macOS(.v14)],
    products: [.library(name: "СетьАгентов", targets: ["СетьАгентов"])],
    targets: [
        .target(name: "СетьАгентов", path: "Sources/СетьАгентов", swiftSettings: strict),
        .testTarget(name: "ПроверкиСетиАгентов", dependencies: ["СетьАгентов"],
            path: "Tests/ПроверкиСетиАгентов", swiftSettings: strict)
    ],
    swiftLanguageModes: [.v6]
)
