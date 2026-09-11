// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "СнимокАгентскойЗадачи",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "СнимокАгентскойЗадачи", targets: ["СнимокАгентскойЗадачи"]),
        .executable(name: "снимок-задачи", targets: ["КомандаСнимка"])
    ],
    dependencies: [.package(path: "../КонтейнерНаблюдений")],
    targets: [
        .target(name: "СнимокАгентскойЗадачи", dependencies: [
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
        ]),
        .executableTarget(name: "КомандаСнимка", dependencies: ["СнимокАгентскойЗадачи"]),
        .testTarget(name: "СнимокАгентскойЗадачиTests", dependencies: ["СнимокАгентскойЗадачи"])
    ],
    swiftLanguageModes: [.v6]
)
