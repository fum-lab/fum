// swift-tools-version: 6.0
import PackageDescription

let пакет = Package(
    name: "Мост",
    platforms: [.macOS(.v14)],
    products: [.library(name: "МостЛибторрента", targets: ["МостЛибторрента"]),
               .library(name: "ПробыМоста", targets: ["ПробыМоста"])],
    targets: [
        .target(name: "МостЛибторрента", publicHeadersPath: "include"),
        .target(name: "ПробыМоста", dependencies: ["МостЛибторрента"],
                path: "Tests/ПробыМоста", publicHeadersPath: "."),
        .testTarget(name: "Тесты", dependencies: ["МостЛибторрента", "ПробыМоста"])
    ],
    cxxLanguageStandard: .cxx17
)
