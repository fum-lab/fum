// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "КаналыМАКС",
    products: [.library(name: "КаналыМАКС", targets: ["КаналыМАКС"])],
    targets: [
        .target(name: "КаналыМАКС"),
        .testTarget(name: "ПроверкиКаналов", dependencies: ["КаналыМАКС"])
    ],
    swiftLanguageModes: [.v6]
)
