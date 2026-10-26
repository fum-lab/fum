// swift-tools-version: 6.0
import PackageDescription

let строгиеНастройки: [SwiftSetting] = [
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "АрхивныйСнимокЗадачи", platforms: [.macOS(.v14)],
    products: [.library(name: "АрхивныйСнимокЗадачи", targets: ["АрхивныйСнимокЗадачи"]),
               .executable(name: "архивный-снимок", targets: ["КомандаАрхива"]),
               .executable(name: "профиль-архивного-снимка", targets: ["ПрофильАрхивногоСнимка"])],
    dependencies: [.package(path: "../СнимокАгентскойЗадачи"), .package(path: "../КонтейнерНаблюдений")],
    targets: [
        .target(name: "АрхивныйСнимокЗадачи", dependencies: [
            .product(name: "СнимокАгентскойЗадачи", package: "СнимокАгентскойЗадачи"),
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")],
            swiftSettings: строгиеНастройки),
        .executableTarget(name: "КомандаАрхива", dependencies: ["АрхивныйСнимокЗадачи",
            .product(name: "СнимокАгентскойЗадачи", package: "СнимокАгентскойЗадачи")]),
        .executableTarget(name: "АварийнаяФикстура", dependencies: ["АрхивныйСнимокЗадачи",
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")]),
        .executableTarget(name: "ПрофильАрхивногоСнимка", dependencies: ["АрхивныйСнимокЗадачи",
            .product(name: "СнимокАгентскойЗадачи", package: "СнимокАгентскойЗадачи")]),
        .testTarget(name: "АрхивныйСнимокЗадачиTests", dependencies: ["АрхивныйСнимокЗадачи", "КомандаАрхива", "АварийнаяФикстура", "ПрофильАрхивногоСнимка",
            .product(name: "СнимокАгентскойЗадачи", package: "СнимокАгентскойЗадачи"),
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")]),
        .testTarget(name: "ПроверкиПоследовательныхРамок", dependencies: ["АрхивныйСнимокЗадачи"],
            path: "proverki", swiftSettings: строгиеНастройки)
    ], swiftLanguageModes: [.v6])
