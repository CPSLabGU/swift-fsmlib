// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "FSM",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v16),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "FSM", targets: ["FSM"]),
        .executable(name: "fsmconvert", targets: ["fsmconvert"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(name: "FSM", dependencies: [
            .product(name: "SystemPackage", package: "swift-system"),
        ]),
        .executableTarget(name: "fsmconvert", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            "FSM"
        ]),
        .testTarget(name: "FSMTests", dependencies: ["FSM"], resources: [.copy("Resources")]),
    ]
)
