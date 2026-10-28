// swift-tools-version: 6.0
import PackageDescription

let строгиеФлаги: [SwiftSetting] = [
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])
]

let package = Package(
    name: "АудиторИсторииКоммитов",
    products: [
        .library(name: "АудиторИсторииКоммитов", targets: ["АудиторИсторииКоммитов"]),
        .executable(name: "аудитор-истории-коммитов", targets: ["КомандаАудита"])
    ],
    targets: [
        .target(name: "АудиторИсторииКоммитов", swiftSettings: строгиеФлаги),
        .executableTarget(name: "КомандаАудита", dependencies: ["АудиторИсторииКоммитов"],
            swiftSettings: строгиеФлаги),
        .testTarget(name: "АудиторИсторииКоммитовTests",
            dependencies: ["АудиторИсторииКоммитов"], swiftSettings: строгиеФлаги)
    ],
    swiftLanguageModes: [.v6]
)
