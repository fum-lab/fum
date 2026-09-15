// swift-tools-version: 6.0
import PackageDescription

// Переходный общий граф: исходники ещё в прежних каталогах до штатного переноса.
let package = Package(
    name: "FUMA",
    platforms: [.macOS(.v14)],
    products: [
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
        .package(path: "../../Зависимости/swift-crypto"),
        .package(path: "../../Прототипы/память-структурирующих-операторов")
    ],
    targets: [
.target(name: "АрхивныйСнимокЗадачи", dependencies: [
            "СнимокАгентскойЗадачи",
            "КонтейнерНаблюдений"], path: "Packages/АрхивныйСнимокЗадачи/Sources/АрхивныйСнимокЗадачи"),
        .executableTarget(name: "КомандаАрхива", dependencies: ["АрхивныйСнимокЗадачи",
            "СнимокАгентскойЗадачи"], path: "Packages/АрхивныйСнимокЗадачи/Sources/КомандаАрхива"),
        .executableTarget(name: "АварийнаяФикстура", dependencies: ["АрхивныйСнимокЗадачи",
            "КонтейнерНаблюдений"], path: "Packages/АрхивныйСнимокЗадачи/Sources/АварийнаяФикстура"),
        .executableTarget(name: "ПрофильАрхивногоСнимка", dependencies: ["АрхивныйСнимокЗадачи",
            "СнимокАгентскойЗадачи"], path: "Packages/АрхивныйСнимокЗадачи/Sources/ПрофильАрхивногоСнимка"),
        .testTarget(name: "АрхивныйСнимокЗадачиTests", dependencies: ["АрхивныйСнимокЗадачи", "КомандаАрхива", "АварийнаяФикстура", "ПрофильАрхивногоСнимка",
            "СнимокАгентскойЗадачи",
            "КонтейнерНаблюдений"], path: "Packages/АрхивныйСнимокЗадачи/Tests/АрхивныйСнимокЗадачиTests"),
.target(name: "КонтейнерНаблюдений", dependencies: [.product(name: "Crypto", package: "swift-crypto")], path: "Packages/КонтейнерНаблюдений/Sources/КонтейнерНаблюдений"),
        .executableTarget(name: "ПисательКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Packages/КонтейнерНаблюдений/Sources/ПисательКонтейнера"),
        .executableTarget(name: "ЧитательКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Packages/КонтейнерНаблюдений/Sources/ЧитательКонтейнера"),
        .executableTarget(name: "ВосстановительКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Packages/КонтейнерНаблюдений/Sources/ВосстановительКонтейнера"),
        .executableTarget(name: "ПрофильКонтейнера", dependencies: ["КонтейнерНаблюдений"], path: "Packages/КонтейнерНаблюдений/Sources/ПрофильКонтейнера"),
        .testTarget(name: "КонтейнерНаблюденийTests", dependencies: ["КонтейнерНаблюдений"], path: "Packages/КонтейнерНаблюдений/Tests/КонтейнерНаблюденийTests"),
.target(name: "СнимокАгентскойЗадачи", dependencies: [
            "КонтейнерНаблюдений"
        ], path: "Packages/СнимокАгентскойЗадачи/Sources/СнимокАгентскойЗадачи"),
        .executableTarget(name: "КомандаСнимка", dependencies: ["СнимокАгентскойЗадачи"], path: "Packages/СнимокАгентскойЗадачи/Sources/КомандаСнимка"),
        .testTarget(name: "СнимокАгентскойЗадачиTests", dependencies: ["СнимокАгентскойЗадачи"], path: "Packages/СнимокАгентскойЗадачи/Tests/СнимокАгентскойЗадачиTests"),
.target(name: "СтатистикаВызовов", dependencies: [
            "КонтейнерНаблюдений"
        ], path: "Packages/СтатистикаВызовов/Sources/СтатистикаВызовов"),
        .executableTarget(name: "КомандаСтатистики", dependencies: ["СтатистикаВызовов"], path: "Packages/СтатистикаВызовов/Sources/КомандаСтатистики"),
        .testTarget(name: "СтатистикаВызововTests", dependencies: ["СтатистикаВызовов"], path: "Packages/СтатистикаВызовов/Tests/СтатистикаВызововTests"),
.target(name: "СценарийRuntime", dependencies: [
            .product(name: "FUMStructuringOperatorMemory", package: "память-структурирующих-операторов"),
            "КонтейнерНаблюдений"
        ], path: "Packages/СценарийRuntime/Sources/СценарийRuntime"),
        .executableTarget(name: "КомандаRuntime", dependencies: ["СценарийRuntime"], path: "Packages/СценарийRuntime/Sources/КомандаRuntime"),
        .testTarget(name: "СценарийRuntimeTests", dependencies: ["СценарийRuntime"], path: "Packages/СценарийRuntime/Tests/СценарийRuntimeTests")
    ],
    swiftLanguageModes: [.v6]
)
