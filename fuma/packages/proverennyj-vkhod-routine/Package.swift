// swift-tools-version: 6.0
import PackageDescription

let строгиеПараметры: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "ПроверенныйВходRoutine",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ПроверенныйВходRoutine", targets: ["ПроверенныйВходRoutine"])],
    dependencies: [.package(path: "../otvety-koordinatoru")],
    targets: [
        .target(name: "ПроверенныйВходRoutine", dependencies: [
            .product(name: "ОтветыКоординатору", package: "otvety-koordinatoru")
        ], path: "Sources/ПроверенныйВходRoutine", swiftSettings: строгиеПараметры),
        .testTarget(name: "ПроверкиВходаRoutine", dependencies: [
            "ПроверенныйВходRoutine",
            .product(name: "ОтветыКоординатору", package: "otvety-koordinatoru")
        ], path: "Tests/ПроверкиВходаRoutine", swiftSettings: строгиеПараметры)
    ],
    swiftLanguageModes: [.v6]
)
