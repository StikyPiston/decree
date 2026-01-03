// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "decree",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.0")
    ],
    targets: [
        .executableTarget(
            name: "decree",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Yams"
            ]
        )
    ]
)
