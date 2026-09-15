// swift-tools-version: 6.0
import PackageDescription

// Общие компоненты используют единственные исходники Sources и Tests.
let package = Package(
    name: "FUMA",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "fum", targets: ["FUMApp"]),
        .executable(name: "fum-mcp", targets: ["FUMMCPServer"]),
        .executable(name: "fum-ax-vision-sense", targets: ["FUMAXVisionSense"]),
        .executable(name: "fum-attention-loop", targets: ["FUMAttentionLoop"]),
        .executable(name: "профиль-путей", targets: ["ПрофильПутей"]),
        .library(name: "FUMStructuringOperatorMemory", targets: ["FUMStructuringOperatorMemory"]),
        .executable(name: "FUMStructuringOperatorMemoryProbe", targets: ["FUMStructuringOperatorMemoryProbe"]),
.library(name: "АрхивныйСнимокЗадачи", targets: ["АрхивныйСнимокЗадачи"]),
               .executable(name: "архивный-снимок", targets: ["КомандаАрхива"]),
               .executable(name: "профиль-архивного-снимка", targets: ["ПрофильАрхивногоСнимка"]),
.library(name: "КонтейнерНаблюдений", targets: ["КонтейнерНаблюдений"]),
        .executable(name: "писатель-контейнера", targets: ["ПисательКонтейнера"]),
        .executable(name: "читатель-контейнера", targets: ["ЧитательКонтейнера"]),
        .executable(name: "восстановитель-контейнера", targets: ["ВосстановительКонтейнера"]),
        .executable(name: "профиль-контейнера", targets: ["ПрофильКонтейнера"]),
.library(name: "СнимокАгентскойЗадачи", targets: ["СнимокАгентскойЗадачи"]),
        .executable(name: "снимок-задачи", targets: ["КомандаСнимка"]),
.library(name: "СтатистикаВызовов", targets: ["СтатистикаВызовов"]),
        .executable(name: "статистика-вызовов", targets: ["КомандаСтатистики"]),
.library(name: "СценарийRuntime", targets: ["СценарийRuntime"]),
        .executable(name: "сценарий-runtime", targets: ["КомандаRuntime"])
    ],
    dependencies: [
        .package(path: "../../Зависимости/swift-crypto")
    ],
    targets: [
        .executableTarget(name: "FUMApp", dependencies: [
            .target(name: "CMpvShim", condition: .when(platforms: [.macOS])),
            .target(name: "ПутиИсполнения", condition: .when(platforms: [.macOS])),
            .target(name: "ИсполнениеОператора", condition: .when(platforms: [.macOS]))
        ], linkerSettings: [.linkedFramework("OpenGL", .when(platforms: [.macOS])),
                            .linkedLibrary("mpv", .when(platforms: [.macOS]))]),
        .target(name: "CMpvShim", dependencies: [
            .target(name: "CMpvSystem", condition: .when(platforms: [.macOS]))
        ], publicHeadersPath: "include", linkerSettings: [
            .linkedFramework("OpenGL", .when(platforms: [.macOS])),
            .linkedLibrary("mpv", .when(platforms: [.macOS]))]),
        .systemLibrary(name: "CMpvSystem", pkgConfig: "mpv", providers: [.brew(["mpv"])]),
        .target(name: "ПутиИсполнения"),
        .target(name: "ИсполнениеОператора", dependencies: ["ПутиИсполнения", "FUMStructuringOperatorMemory", "КонтейнерНаблюдений"]),
        .testTarget(name: "ИсполнениеОператораTests", dependencies: ["ИсполнениеОператора"]),
        .testTarget(name: "ПутиИсполненияTests", dependencies: ["ПутиИсполнения"]),
        .executableTarget(name: "FUMMCPServer", dependencies: [.target(name: "ПутиИсполнения", condition: .when(platforms: [.macOS]))]),
        .executableTarget(name: "FUMAXVisionSense", dependencies: [.target(name: "ПутиИсполнения", condition: .when(platforms: [.macOS]))]),
        .executableTarget(name: "FUMAttentionLoop", dependencies: [.target(name: "ПутиИсполнения", condition: .when(platforms: [.macOS]))]),
        .executableTarget(name: "ПрофильПутей", dependencies: ["ПутиИсполнения"]),
        .target(name: "FUMStructuringOperatorMemory", dependencies: [.product(name: "Crypto", package: "swift-crypto")], resources: [.copy("Фикстуры"), .copy("Определения")]),
        .executableTarget(name: "FUMStructuringOperatorMemoryProbe", dependencies: ["FUMStructuringOperatorMemory"]),
        .testTarget(name: "FUMStructuringOperatorMemoryTests", dependencies: ["FUMStructuringOperatorMemory"]),
.target(name: "АрхивныйСнимокЗадачи", dependencies: [
            "СнимокАгентскойЗадачи",
            "КонтейнерНаблюдений"], path: "Sources/АрхивныйСнимокЗадачи"),
        .executableTarget(name: "КомандаАрхива", dependencies: ["АрхивныйСнимокЗадачи",
            "СнимокАгентскойЗадачи"], path: "Sources/КомандаАрхива"),
        .executableTarget(name: "АварийнаяФикстура", dependencies: ["АрхивныйСнимокЗадачи",
            "КонтейнерНаблюдений"], path: "Sources/АварийнаяФикстура"),
        .executableTarget(name: "ПрофильАрхивногоСнимка", dependencies: ["АрхивныйСнимокЗадачи",
            "СнимокАгентскойЗадачи"], path: "Sources/ПрофильАрхивногоСнимка"),
        .testTarget(name: "АрхивныйСнимокЗадачиTests", dependencies: ["АрхивныйСнимокЗадачи", "КомандаАрхива", "АварийнаяФикстура", "ПрофильАрхивногоСнимка",
            "СнимокАгентскойЗадачи",
            "КонтейнерНаблюдений"], path: "Tests/АрхивныйСнимокЗадачиTests"),
.target(name: "КонтейнерНаблюдений", dependencies: [.product(name: "Crypto", package: "swift-crypto")], path: "Sources/КонтейнерНаблюдений"),
        .executableTarget(name: "ПисательКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Sources/ПисательКонтейнера"),
        .executableTarget(name: "ЧитательКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Sources/ЧитательКонтейнера"),
        .executableTarget(name: "ВосстановительКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Sources/ВосстановительКонтейнера"),
        .executableTarget(name: "ПрофильКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Sources/ПрофильКонтейнера"),
        .testTarget(name: "КонтейнерНаблюденийTests", dependencies: ["КонтейнерНаблюдений"], path: "Tests/КонтейнерНаблюденийTests"),
.target(name: "СнимокАгентскойЗадачи", dependencies: [
            "КонтейнерНаблюдений"
        ], path: "Sources/СнимокАгентскойЗадачи"),
        .executableTarget(name: "КомандаСнимка", dependencies: ["СнимокАгентскойЗадачи"], path: "Sources/КомандаСнимка"),
        .testTarget(name: "СнимокАгентскойЗадачиTests", dependencies: ["СнимокАгентскойЗадачи"], path: "Tests/СнимокАгентскойЗадачиTests", resources: [.copy("Примеры")]),
.target(name: "СтатистикаВызовов", dependencies: [
            "КонтейнерНаблюдений"
        ], path: "Sources/СтатистикаВызовов"),
        .executableTarget(name: "КомандаСтатистики", dependencies: ["СтатистикаВызовов"], path: "Sources/КомандаСтатистики"),
        .testTarget(name: "СтатистикаВызововTests", dependencies: ["СтатистикаВызовов"], path: "Tests/СтатистикаВызововTests"),
.target(name: "СценарийRuntime", dependencies: [
            "FUMStructuringOperatorMemory",
            "КонтейнерНаблюдений"
        ], path: "Sources/СценарийRuntime"),
        .executableTarget(name: "КомандаRuntime", dependencies: ["СценарийRuntime"], path: "Sources/КомандаRuntime"),
        .testTarget(name: "СценарийRuntimeTests", dependencies: ["СценарийRuntime"], path: "Tests/СценарийRuntimeTests")
    ],
    swiftLanguageModes: [.v6]
)
