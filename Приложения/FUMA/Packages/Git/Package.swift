// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Git",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "НаблюдательРепозитория", targets: ["НаблюдательРепозитория"])
    ],
    targets: [
        .target(name: "НаблюдательРепозитория")
    ],
    swiftLanguageModes: [.v6]
)
