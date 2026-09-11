// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ВиртуальнаяМашина",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "машина", targets: ["Машина"])],
    targets: [
        .target(name: "ЯдроМашины"),
        .executableTarget(name: "Машина", dependencies: ["ЯдроМашины"]),
        .testTarget(name: "ПроверкиМашины", dependencies: ["ЯдроМашины"]),
    ]
)
