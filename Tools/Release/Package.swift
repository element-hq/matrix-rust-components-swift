// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Release",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "release", targets: ["Release"])],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/element-hq/swift-command-line-tools.git", revision: "c8e3448595363a3948f6260053fc78d3accb2ebc")
        // .package(path: "../../../swift-command-line-tools")
    ],
    targets: [
        .executableTarget(name: "Release", 
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "CommandLineTools", package: "swift-command-line-tools")
                          ])
    ]
)
