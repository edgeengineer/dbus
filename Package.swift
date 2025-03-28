// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DBusSwift",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "DBusSwift",
            targets: ["DBusSwift"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DBusSwift",
            dependencies: ["CDBus"]),
        .systemLibrary(
            name: "CDBus",
            pkgConfig: "dbus-1",
            providers: [
                .apt(["libdbus-1-dev"]),
                .brew(["dbus"])
            ]),
        .testTarget(
            name: "DBusSwiftTests",
            dependencies: ["DBusSwift"]),
    ]
)