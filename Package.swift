// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let checksum = "dd0b1e82622bd6acbaff406ffcf70ed4ffc0e0ead2f35213ce329b1f6be60f89"
let version = "v1.0.31"
let url = "https://github.com/element-hq/matrix-rust-components-swift/releases/download/\(version)/MatrixSDKFFI.xcframework.zip"
let package = Package(
    name: "MatrixRustSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "MatrixRustSDK", targets: ["MatrixRustSDK"]),
    ],
    targets: [
        .binaryTarget(name: "MatrixSDKFFI", url: url, checksum: checksum),
        .target(name: "MatrixRustSDK", dependencies: [.target(name: "MatrixSDKFFI")])
    ]
)
