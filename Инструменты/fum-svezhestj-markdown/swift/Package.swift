// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ОбновительСвежестиMarkdown",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ОбновительСвежести", targets: ["ОбновительСвежести"]),
        .executable(name: "обновить-свежесть-md", targets: ["ОбновитьСвежесть"])
    ],
    targets: [
        .target(name: "ОбновительСвежести"),
        .executableTarget(name: "ОбновитьСвежесть", dependencies: ["ОбновительСвежести"]),
        .testTarget(name: "ОбновительСвежестиTests", dependencies: ["ОбновительСвежести"])
    ],
    swiftLanguageModes: [.v6]
)
