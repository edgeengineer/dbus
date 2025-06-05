// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "DBUS",
  products: [
    .library(
      name: "DBUS",
      targets: ["DBUS"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.70.0"),
    .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.26.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
  ],
  targets: [
    .target(
      name: "DBUS",
      dependencies: [
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "NIOExtras", package: "swift-nio-extras"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .executableTarget(name: "ExampleApp", dependencies: ["DBUS"]),
    .testTarget(
      name: "DBUSTests",
      dependencies: ["DBUS"]),
  ]
)
