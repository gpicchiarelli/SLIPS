// swift-tools-version: 6.0
// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License

import PackageDescription

let package = Package(
    name: "SLIPS",
    platforms: [
        .macOS(.v14),
        .linux
    ],
    products: [
        .library(name: "SLIPS", targets: ["SLIPS"]),
        .executable(name: "slips-cli", targets: ["slips-cli"])
    ],
    targets: [
        .target(name: "SLIPS", path: "Sources/SLIPS"),
        .executableTarget(name: "slips-cli", dependencies: ["SLIPS"], path: "Sources/slips-cli"),
        .testTarget(name: "SLIPSTests", dependencies: ["SLIPS"], path: "Tests/SLIPSTests", resources: [.copy("Assets")])
    ]
)
