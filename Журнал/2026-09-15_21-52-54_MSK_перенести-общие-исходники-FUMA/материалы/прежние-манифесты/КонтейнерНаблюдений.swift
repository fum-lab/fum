// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "КонтейнерНаблюдений",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "КонтейнерНаблюдений", targets: ["КонтейнерНаблюдений"]),
        .executable(name: "писатель-контейнера", targets: ["ПисательКонтейнера"]),
        .executable(name: "читатель-контейнера", targets: ["ЧитательКонтейнера"]),
        .executable(name: "восстановитель-контейнера", targets: ["ВосстановительКонтейнера"]),
        .executable(name: "профиль-контейнера", targets: ["ПрофильКонтейнера"])
    ],
    dependencies: [.package(path: "../../../../Зависимости/swift-crypto")],
    targets: [
        .target(name: "КонтейнерНаблюдений", dependencies: [.product(name: "Crypto", package: "swift-crypto")]),
        .executableTarget(name: "ПисательКонтейнера", dependencies: ["КонтейнерНаблюдений"]),
        .executableTarget(name: "ЧитательКонтейнера", dependencies: ["КонтейнерНаблюдений"]),
        .executableTarget(name: "ВосстановительКонтейнера", dependencies: ["КонтейнерНаблюдений"]),
        .executableTarget(name: "ПрофильКонтейнера", dependencies: ["КонтейнерНаблюдений"]),
        .testTarget(name: "КонтейнерНаблюденийTests", dependencies: ["КонтейнерНаблюдений"])
    ],
    swiftLanguageModes: [.v6]
)
