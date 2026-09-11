// swift-tools-version: 6.0
import PackageDescription

let пакет = Package(
    name: "КлиентTelegram",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "КлиентTelegram", targets: ["КлиентTelegram"]),
        .executable(name: "проверить-telegram", targets: ["ПроверкаTelegram"])
    ],
    dependencies: [.package(path: "../КонтейнерНаблюдений")],
    targets: [
        .target(name: "КлиентTelegram", dependencies: [
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
        ]),
        .executableTarget(name: "ПроверкаTelegram", dependencies: ["КлиентTelegram"]),
        .testTarget(name: "ПроверкиTelegram", dependencies: ["КлиентTelegram"])
    ],
    swiftLanguageModes: [.v6]
)
