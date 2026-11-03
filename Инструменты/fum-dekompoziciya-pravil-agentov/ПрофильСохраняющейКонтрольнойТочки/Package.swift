// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ПрофильСохраняющейКонтрольнойТочки",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ПрофильСохраняющейКонтрольнойТочки", targets: ["ПрофильСохраняющейКонтрольнойТочки"]),
        .executable(name: "проверить-сохраняющую-контрольную-точку", targets: ["ПроверитьПрофиль"])
    ],
    targets: [
        .target(name: "ПрофильСохраняющейКонтрольнойТочки"),
        .executableTarget(name: "ПроверитьПрофиль", dependencies: ["ПрофильСохраняющейКонтрольнойТочки"]),
        .testTarget(name: "ПрофильСохраняющейКонтрольнойТочкиTests", dependencies: ["ПрофильСохраняющейКонтрольнойТочки"])
    ],
    swiftLanguageModes: [.v6]
)
