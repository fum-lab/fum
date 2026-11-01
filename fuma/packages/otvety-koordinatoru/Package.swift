// swift-tools-version: 6.0
import PackageDescription

let строгиеПараметры: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "ОтветыКоординатору",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ОтветыКоординатору", targets: ["ОтветыКоординатору"])],
    dependencies: [.package(path: "../setj-agentov")],
    targets: [
        .target(name: "ОтветыКоординатору", dependencies: [
            .product(name: "СетьАгентов", package: "setj-agentov")
        ], path: "Sources/ОтветыКоординатору", swiftSettings: строгиеПараметры),
        .testTarget(name: "ПроверкиОтветовКоординатору", dependencies: [
            "ОтветыКоординатору",
            .product(name: "СетьАгентов", package: "setj-agentov")
        ],
            path: "Tests/ПроверкиОтветовКоординатору", swiftSettings: строгиеПараметры)
    ],
    swiftLanguageModes: [.v6]
)
