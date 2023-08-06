// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FSM",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "FSM", targets: ["FSM"]),
        .executable(name: "fsmconvert", targets: ["fsmconvert"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .target(name: "FSM"),
        .executableTarget(name: "fsmconvert", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            "FSM"
        ]),
        .testTarget(name: "FSMTests", dependencies: ["FSM"]),
    ]
)
