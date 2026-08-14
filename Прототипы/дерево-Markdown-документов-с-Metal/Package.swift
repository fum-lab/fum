// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ДеревоДокументов",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "ДеревоДокументовЯдро",
      targets: ["ДеревоДокументовЯдро"]
    ),
    .executable(
      name: "ДеревоДокументов",
      targets: ["ДеревоДокументовПриложение"]
    ),
  ],
  targets: [
    .target(
      name: "ДеревоДокументовЯдро",
      path: "Sources/ДеревоДокументовЯдро"
    ),
    .executableTarget(
      name: "ДеревоДокументовПриложение",
      dependencies: ["ДеревоДокументовЯдро"],
      path: "Sources/ДеревоДокументовПриложение"
    ),
    .testTarget(
      name: "ДеревоДокументовТесты",
      dependencies: ["ДеревоДокументовЯдро"],
      path: "Tests/ДеревоДокументовТесты"
    ),
  ]
)
