// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "СценарийRuntime",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "СценарийRuntime", targets: ["СценарийRuntime"]),
        .executable(name: "сценарий-runtime", targets: ["КомандаRuntime"])
    ],
    dependencies: [
        .package(path: "../../../../Прототипы/память-структурирующих-операторов"),
        .package(path: "../КонтейнерНаблюдений")
    ],
    targets: [
        .target(name: "СценарийRuntime", dependencies: [
            .product(name: "FUMStructuringOperatorMemory", package: "память-структурирующих-операторов"),
            "КонтейнерНаблюдений"
        ]),
        .executableTarget(name: "КомандаRuntime", dependencies: ["СценарийRuntime"]),
        .testTarget(name: "СценарийRuntimeTests", dependencies: ["СценарийRuntime"])
    ]
)
