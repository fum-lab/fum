// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "СтатистикаВызовов",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "СтатистикаВызовов", targets: ["СтатистикаВызовов"]),
        .executable(name: "статистика-вызовов", targets: ["КомандаСтатистики"])
    ],
    dependencies: [.package(path: "../КонтейнерНаблюдений")],
    targets: [
        .target(name: "СтатистикаВызовов", dependencies: [
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
        ]),
        .executableTarget(name: "КомандаСтатистики", dependencies: ["СтатистикаВызовов"]),
        .testTarget(name: "СтатистикаВызововTests", dependencies: ["СтатистикаВызовов"])
    ],
    swiftLanguageModes: [.v6]
)
