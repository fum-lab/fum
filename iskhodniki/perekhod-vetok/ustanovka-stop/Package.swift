// swift-tools-version: 6.0
import PackageDescription
let строгие: [SwiftSetting] = [.swiftLanguageMode(.v6), .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])]
let package = Package(name: "UstanovkaStop", platforms: [.macOS(.v14)], products: [
    .library(name: "УстановкаStop", targets: ["УстановкаStop"]),
    .executable(name: "ustanovitj-stop", targets: ["КомандаУстановкиStop"])
], targets: [
    .target(name: "УстановкаStop", path: ".", exclude: ["komanda", "proverki", "kontrakt-ustanovki-stop.json"], sources: ["ustanovitj-stop.swift"], swiftSettings: строгие),
    .executableTarget(name: "КомандаУстановкиStop", dependencies: ["УстановкаStop"], path: "komanda", sources: ["main.swift"], swiftSettings: строгие),
    .testTarget(name: "ПроверкиУстановкиStop", dependencies: ["УстановкаStop"], path: "proverki", sources: ["proverki-ustanovki-stop.swift"], swiftSettings: строгие)
], swiftLanguageModes: [.v6])
