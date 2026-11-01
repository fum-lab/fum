// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "НаблюдениеДоступности",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "НаблюдениеДоступности", targets: ["НаблюдениеДоступности"]),
        .executable(name: "наблюдать-доступность", targets: ["КомандаДоступности"])
    ],
    dependencies: [.package(path: "../КонтейнерНаблюдений")],
    targets: [
        .target(name: "НаблюдениеДоступности", dependencies: [
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
        ]),
        .executableTarget(name: "КомандаДоступности", dependencies: [
            "НаблюдениеДоступности", .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
        ]),
        .testTarget(name: "ТестыНаблюденияДоступности", dependencies: [
            "НаблюдениеДоступности", .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
        ], path: "Tests/НаблюдениеДоступностиTests")
    ],
    swiftLanguageModes: [.v6]
)
