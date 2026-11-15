// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FUM",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "FUMProcessProtocol", targets: ["FUMProcessProtocol"]),
        .executable(name: "fum-process-supervisor", targets: ["FUMProcessSupervisor"]),
        .executable(name: "fum-process-anchor", targets: ["FUMProcessAnchor"]),
        .executable(name: "fum-anchor-witness", targets: ["FUMAnchorWitness"]),
        .executable(name: "фум-проверка-начальной-среды", targets: ["ФУМПроверкаНачальнойСреды"]),
        .executable(name: "фум-проверка-ограниченной-среды", targets: ["ФУМПроверкаОграниченнойСреды"]),
        .executable(name: "фум-проверка-связанного-дерева", targets: ["ФУМПроверкаСвязанногоДерева"]),
    ],
    targets: [
        .executableTarget(
            name: "ФУМПроверкаСвязанногоДерева",
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/исследования/ограниченная-среда-linked",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])]
        ),
        .executableTarget(
            name: "ФУМПроверкаОграниченнойСреды",
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/исследования/ограниченная-среда",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])]
        ),
        .systemLibrary(
            name: "СистемныеВызовы",
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/native-supervisor/Sources/СистемныеВызовы"
        ),
        .target(
            name: "FUMProcessProtocol",
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/native-supervisor/Sources/FUMProcessProtocol",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])]
        ),
        .executableTarget(
            name: "FUMProcessSupervisor",
            dependencies: ["FUMProcessProtocol", "СистемныеВызовы"],
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/native-supervisor/Sources/FUMProcessSupervisor",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])],
            linkerSettings: [.linkedLibrary("swiftDarwin", .when(platforms: [.macOS]))]
        ),
        .executableTarget(
            name: "FUMProcessAnchor",
            dependencies: ["FUMProcessProtocol", "СистемныеВызовы"],
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/native-supervisor/Sources/FUMProcessAnchor",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])],
            linkerSettings: [.linkedLibrary("swiftDarwin", .when(platforms: [.macOS]))]
        ),
        .executableTarget(
            name: "FUMAnchorWitness",
            dependencies: ["FUMProcessProtocol", "СистемныеВызовы"],
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/native-supervisor/Sources/FUMAnchorWitness",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])],
            linkerSettings: [.linkedLibrary("swiftDarwin", .when(platforms: [.macOS]))]
        ),
        .executableTarget(
            name: "ФУМПроверкаНачальнойСреды",
            dependencies: ["СистемныеВызовы"],
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/native-supervisor/Tests/ПроверкаНачальнойСреды",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-parse-as-library"])]
        ),
        .testTarget(
            name: "FUMProcessProtocolTests",
            dependencies: ["FUMProcessProtocol"],
            path: "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/native-supervisor/Tests/FUMProcessProtocolTests",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])]
        ),
    ]
)
