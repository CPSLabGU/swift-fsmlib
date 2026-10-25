// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FSM",
    platforms: [
        .macOS(.v15),
        .macCatalyst(.v18),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "FSM", targets: ["FSM"]),
        .library(name: "FSMEcore", targets: ["FSMEcore"]),
        .executable(name: "fsmconvert", targets: ["fsmconvert"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/mipalgu/swift-ecore.git", branch: "development"),
        .package(url: "https://github.com/mipalgu/swift-mtl.git", branch: "development"),
        .package(url: "https://github.com/mipalgu/swift-atl.git", branch: "development"),
        .package(url: "https://github.com/mipalgu/swift-aql.git", branch: "development"),
        .package(url: "https://github.com/mipalgu/swift-modelling.git", branch: "development"),
    ],
    targets: [
        .target(
            name: "FSM",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "FSMEcore",
            dependencies: [
                "FSM",
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "EMFBase", package: "swift-ecore"),
                .product(name: "MTL", package: "swift-mtl"),
                .product(name: "ATL", package: "swift-atl"),
                .product(name: "AQL", package: "swift-aql"),
                .product(name: "ModellingGenerators", package: "swift-modelling"),
                .product(name: "ModellingPipeline", package: "swift-modelling"),
            ],
            resources: [.copy("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "fsmconvert",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ECore", package: "swift-ecore"),
                .product(name: "ModellingCommandLine", package: "swift-modelling"),
                .product(name: "ModellingGenerators", package: "swift-modelling"),
                "FSM",
                "FSMEcore",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "FSMTests",
            dependencies: ["FSM", "FSMEcore"],
            resources: [.copy("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "FSMEcoreTests",
            dependencies: [
                "FSMEcore",
                "FSM",
                .product(name: "ModellingGenerators", package: "swift-modelling"),
            ],
            resources: [.copy("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
